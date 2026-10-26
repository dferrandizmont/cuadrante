import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../../schedule/domain/schedule_domain.dart';
import '../domain/import_models.dart';
import '../domain/lrhsoft_backup.dart';

/// First bytes of every SQLite 3 file.
const String sqliteHeader = 'SQLite format 3\u0000';

/// Whether [bytes] start like a SQLite database (what an LRHSoft `.Shifter`
/// is).
bool looksLikeSqlite(List<int> bytes) {
  if (bytes.length < sqliteHeader.length) return false;
  for (var i = 0; i < sqliteHeader.length; i++) {
    if (bytes[i] != sqliteHeader.codeUnitAt(i)) return false;
  }
  return true;
}

/// Reads an LRHSoft «Calendario de Turnos» backup (`*.Shifter`).
///
/// The file is **untrusted**: it is a SQLite database somebody else made, so
/// nothing in it is trusted to be what it says.
///
/// - Bigger than [maxLrhsoftFileBytes] is refused before anything is written.
/// - The bytes go to a private temp copy (in [tempDirectory], the system temp
///   folder by default), opened **read-only** with `query_only` on and
///   `trusted_schema` off. The copy is always closed and deleted, on success
///   and on failure.
/// - `dias` and `tablaTurnos` must be real tables in `sqlite_master`: a view,
///   a virtual table or a missing table refuses the file.
/// - Only explicit, known columns are selected (never `*`, never the photo
///   BLOB). Optional columns are read only if `PRAGMA table_info` lists them,
///   so older versions with fewer columns still open.
/// - More than [maxLrhsoftDays] days or [maxLrhsoftShiftTypes] shift types
///   refuses the file as too complex.
/// - Every date and time is validated; an invalid row is skipped and counted
///   in [LrhsoftBackup.invalidRows].
///
/// Throws [ImportException] and nothing else. Synchronous: the wizard runs it
/// in a background isolate.
LrhsoftBackup readLrhsoftBackup(Uint8List bytes, {Directory? tempDirectory}) {
  if (bytes.length > maxLrhsoftFileBytes) {
    throw const ImportException(ImportProblem.tooComplex);
  }
  if (!looksLikeSqlite(bytes)) {
    throw const ImportException(ImportProblem.notLrhsoftFile);
  }
  Directory? folder;
  Database? db;
  try {
    folder = (tempDirectory ?? Directory.systemTemp).createTempSync(
      'cuadrante_lrhsoft_',
    );
    final copy = File(p.join(folder.path, 'copia.sqlite'))
      ..writeAsBytesSync(bytes, flush: true);
    db = sqlite3.open(copy.path, mode: OpenMode.readOnly);
    db.execute('PRAGMA query_only = ON');
    db.execute('PRAGMA trusted_schema = OFF');
    db.execute('PRAGMA cell_size_check = ON');
    return _read(db);
  } on ImportException {
    rethrow;
  } on SqliteException {
    // Damaged, encrypted or not a database at all.
    throw const ImportException(ImportProblem.notLrhsoftFile);
  } on FileSystemException {
    throw const ImportException(ImportProblem.fileUnreadable);
  } catch (_) {
    throw const ImportException(ImportProblem.unknown);
  } finally {
    try {
      db?.close();
    } catch (_) {}
    try {
      folder?.deleteSync(recursive: true);
    } catch (_) {
      // A copy that stays in the temp folder is harmless; the system clears it.
    }
  }
}

LrhsoftBackup _read(Database db) {
  // Real tables only: a view called `dias` could run any query when read.
  final tables = <String, String>{};
  for (final row in db.select(
    'SELECT name, type, sql FROM sqlite_master '
    "WHERE name IN ('dias', 'tablaTurnos')",
  )) {
    tables[row['name'] as String] =
        '${row['type']}|${(row['sql'] ?? '').toString().toUpperCase()}';
  }
  for (final name in const ['dias', 'tablaTurnos']) {
    final entry = tables[name];
    if (entry == null ||
        !entry.startsWith('table|') ||
        entry.contains('VIRTUAL')) {
      throw const ImportException(ImportProblem.notLrhsoftFile);
    }
  }

  final typeColumns = _columns(db, 'tablaTurnos');
  final dayColumns = _columns(db, 'dias');
  for (final required in const ['_id']) {
    if (!typeColumns.contains(required)) {
      throw const ImportException(ImportProblem.notLrhsoftFile);
    }
  }
  if (!dayColumns.contains('fecha')) {
    throw const ImportException(ImportProblem.notLrhsoftFile);
  }

  var invalid = 0;

  // ---- shift types ---------------------------------------------------------
  final typeCount =
      db.select('SELECT COUNT(*) AS n FROM tablaTurnos').first['n'] as int;
  if (typeCount > maxLrhsoftShiftTypes) {
    throw const ImportException(ImportProblem.tooComplex);
  }
  String col(Set<String> have, String name) =>
      have.contains(name) ? name : 'NULL';
  final typeRows = db.select(
    'SELECT _id AS id, '
    // Clipped in SQL: a name of megabytes never reaches Dart.
    "substr(${col(typeColumns, 'texto')}, 1, 200) AS texto, "
    "substr(${col(typeColumns, 'abreviatura')}, 1, 64) AS abreviatura, "
    "${col(typeColumns, 'color')} AS color, "
    "${col(typeColumns, 'horaInicio1')} AS ini1, "
    "${col(typeColumns, 'horaFinal1')} AS fin1, "
    "${col(typeColumns, 'horaInicio2')} AS ini2, "
    "${col(typeColumns, 'horaFinal2')} AS fin2, "
    "${col(typeColumns, 'turnoPartido')} AS partido "
    'FROM tablaTurnos ORDER BY _id LIMIT ${maxLrhsoftShiftTypes + 1}',
  );
  final types = <LrhsoftShiftType>[];
  final knownIds = <int>{};
  for (final row in typeRows) {
    final id = row['id'];
    if (id is! int || !knownIds.add(id)) {
      invalid++;
      continue;
    }
    final text = row['texto'];
    final abbreviation = row['abreviatura'];

    // First segment. Absent or 00:00-00:00 = a shift with no times.
    int? start;
    int? end;
    final rawStart = row['ini1'];
    final rawEnd = row['fin1'];
    if (rawStart != null || rawEnd != null) {
      final s = parseLrhsoftTime(rawStart);
      final e = parseLrhsoftTime(rawEnd);
      if (s == null || e == null) {
        invalid++; // The shift stays, without times.
      } else if (!(s == 0 && e == 0)) {
        start = s;
        end = e;
      }
    }

    // Second segment: only when the shift is marked as split.
    int? start2;
    int? end2;
    if (start != null && _truthy(row['partido'])) {
      final s = parseLrhsoftTime(row['ini2']);
      final e = parseLrhsoftTime(row['fin2']);
      final duration = s == null || e == null ? null : _duration(s, e);
      if (s == null ||
          e == null ||
          checkSegment2(
                startMinute: start,
                endMinute: end,
                segment2StartMinute: s,
                segment2DurationMinutes: duration,
              ) !=
              null) {
        invalid++; // The shift stays as a single segment.
      } else {
        start2 = s;
        end2 = e;
      }
    }

    types.add(
      LrhsoftShiftType(
        id: id,
        name: text is String ? text.trim() : '',
        abbreviation: abbreviation is String ? abbreviation.trim() : null,
        colorValue: decodeLrhsoftColor(row['color']),
        startMinute: start,
        endMinute: end,
        segment2StartMinute: start2,
        segment2EndMinute: end2,
      ),
    );
  }

  // ---- days ----------------------------------------------------------------
  final dayCount =
      db.select('SELECT COUNT(*) AS n FROM dias').first['n'] as int;
  if (dayCount > maxLrhsoftDays) {
    throw const ImportException(ImportProblem.tooComplex);
  }
  final dayRows = db.select(
    'SELECT fecha, '
    "${col(dayColumns, 'turno1')} AS turno1, "
    "${col(dayColumns, 'turno2')} AS turno2, "
    "substr(${col(dayColumns, 'notas')}, 1, ${maxImportNoteLength * 8}) AS notas "
    'FROM dias LIMIT ${maxLrhsoftDays + 1}',
  );
  final days = <CivilDate, LrhsoftDay>{};
  for (final row in dayRows) {
    final date = decodeLrhsoftDate(row['fecha']);
    if (date == null) {
      invalid++;
      continue;
    }
    final ids = <int>[];
    var rowInvalid = false;
    for (final field in const ['turno1', 'turno2']) {
      final raw = row[field];
      if (raw == null) continue;
      if (raw is int && knownIds.contains(raw)) {
        ids.add(raw);
      } else {
        rowInvalid = true; // Points at a shift that does not exist.
      }
    }
    if (rowInvalid) invalid++;
    final note = lrhsoftNoteText(row['notas']);
    if (ids.isEmpty && note == null) continue; // An erased day.
    days[date] = LrhsoftDay(date: date, shiftIds: ids, note: note);
  }

  return LrhsoftBackup(
    shiftTypes: types,
    days: (days.values.toList()..sort((a, b) => a.date.compareTo(b.date))),
    invalidRows: invalid,
  );
}

/// Names of the columns of [table] (`PRAGMA table_info`).
Set<String> _columns(Database db, String table) => {
  for (final row in db.select('PRAGMA table_info($table)'))
    row['name'] as String,
};

bool _truthy(Object? value) => value is int && value != 0;

int _duration(int start, int end) {
  final d = (end - start) % 1440;
  return d == 0 ? 1440 : d;
}
