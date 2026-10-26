import 'dart:convert';

import 'package:cuadrante/features/backup/domain/schedule_fingerprint.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:drift/drift.dart';

/// "Today" of the version 1 fixtures: the 730-day window is one year back and
/// the rest ahead, like the restore matrix's.
const v1Today = CivilDate(2026, 10, 19);

/// What the 0.1.0 / 0.2.0 releases could have stored, as plain SQL against
/// the version 1 schema (so it does not depend on any code that changed):
/// shift types (all categories, a night that crosses midnight, a 24 h guard,
/// no-times, paid minutes, an archived one), two patterns (a double-shift step
/// and an empty one), **3 runs (one cut, one with a step offset)**, day
/// overrides (two shifts, `[]`, note only, override + note, an archived type
/// in the past, emoji and line breaks), user and derived holidays, absence
/// balances and settings.
final List<(String, List<Object?>)> v1SeedStatements = [
  for (final t in [
    // id, code, name, color, category, start, end, paid, night, order, archived
    ['morning', 'M', 'Mañana', 0xFFF5A524, 'work', 360, 840, null, null, 0, 0],
    [
      'afternoon',
      'T',
      'Tarde',
      0xFFF06A3F,
      'work',
      840,
      1320,
      null,
      null,
      1,
      0,
    ],
    ['night', 'N', 'Noche', 0xFF4B4FD1, 'work', 1320, 360, 450, 1, 2, 0],
    ['rest', 'L', 'Libre', 0xFFE4E4E7, 'rest', null, null, null, null, 3, 0],
    [
      'vacation',
      'V',
      'Vacaciones',
      0xFF2BB673,
      'absence',
      null,
      null,
      null,
      null,
      4,
      0,
    ],
    ['guard', 'G', 'Guardia 24 h', 0xFFE5484D, 'work', 480, 480, null, 0, 5, 0],
    ['flex', 'F', 'Flexible', 0xFF8B5CF6, 'work', null, null, 420, 1, 6, 0],
    [
      'old',
      'X',
      'Turno antiguo',
      0xFF64748B,
      'work',
      540,
      1020,
      null,
      null,
      7,
      1,
    ],
  ])
    (
      'INSERT INTO shift_types (id, code, name, color_value, category, '
          'start_minute, end_minute, paid_minutes, night_override, sort_order, '
          'archived, created_at, updated_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [...t, 1760000000000 + (t[9]! as int), 1760000500000 + (t[9]! as int)],
    ),
  // Deliberately not in id order: patterns keep their insertion order.
  (
    'INSERT INTO patterns (id, name, steps, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?)',
    [
      'p-turni',
      'Turnicidad',
      '[["morning"],["morning","afternoon"],["afternoon"],["night"],["night"],'
          '[],["rest"],["rest"]]',
      1760001000000,
      1760001500000,
    ],
  ),
  (
    'INSERT INTO patterns (id, name, steps, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?)',
    [
      'p-mananas',
      'Mañanas',
      '[["morning"],["morning"],["morning"],["morning"],["morning"],[],[]]',
      1760002000000,
      1760002500000,
    ],
  ),
  for (final r in [
    // id, pattern, start, end, offset, seq, created: the first one was cut.
    ['run-1', 'p-turni', '2025-11-03', '2026-09-13', 0, 1, 1760003000000],
    ['run-2', 'p-mananas', '2026-09-14', null, 3, 2, 1760003100000],
    ['run-3', 'p-turni', '2027-02-01', '2027-03-31', 2, 3, 1760003200000],
  ])
    (
      'INSERT INTO pattern_runs (id, pattern_id, start_date, end_date, '
          'step_offset, seq, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      r,
    ),
  for (final e in [
    // date, shift_type_ids (JSON or null), note, updated_at
    ['2026-10-19', '["morning","night"]', null, 1760004000000],
    ['2026-10-20', '[]', null, 1760004100000],
    ['2026-10-21', null, 'Cambio con Marta', 1760004200000],
    ['2026-10-22', '["vacation"]', 'Viaje a Cádiz', 1760004300000],
    ['2026-01-05', '["old"]', null, 1760004400000],
    [
      '2026-12-24',
      '["night"]',
      'Nochebuena 🎄\nLlevar el turrón 🙏\r\n"comillas" y \\ barra',
      1760004500000,
    ],
    ['2027-02-14', '["guard","flex"]', null, 1760004600000],
    ['2025-12-31', '["rest"]', 'Fin de año', 1760004700000],
  ])
    (
      'INSERT INTO day_entries (date, shift_type_ids, note, updated_at) '
          'VALUES (?, ?, ?, ?)',
      e,
    ),
  for (final h in [
    ['2026-12-25', 'national', 'Navidad', null, null, 'bundled'],
    [
      '2026-10-09',
      'regional',
      'Día de la Comunidad Valenciana',
      'ES-VC',
      null,
      'remote',
    ],
    ['2026-09-08', 'local', 'Fiesta del barrio 🎆', 'ES-VC', '46250', 'user'],
    ['2027-05-15', 'local', 'San Isidro', 'ES-MD', '28079', 'user'],
  ])
    (
      'INSERT INTO holidays (date, scope, name, region_code, '
          'municipality_code, source) VALUES (?, ?, ?, ?, ?, ?)',
      h,
    ),
  for (final b in [
    [2026, 'vacation', 22.0],
    [2026, 'personal', 6.5],
  ])
    (
      'INSERT INTO absence_balances (year, type, allowed_days) '
          'VALUES (?, ?, ?)',
      b,
    ),
  for (final s in [
    ['holidays.region', '"ES-VC"'],
    ['holidays.municipality', '"46250"'],
    [
      'alarms',
      '{"enabled":true,"leadMinutes":45,"shifts":["morning","night"]}',
    ],
    ['holidays.bundleVersion', '"2026.2"'],
  ])
    ('INSERT INTO settings (key, value) VALUES (?, ?)', s),
];

/// Writes the version 1 fixture into [db] (any database on the version 1
/// schema).
Future<void> seedV1(GeneratedDatabase db) async {
  for (final (sql, args) in v1SeedStatements) {
    await db.customStatement(sql, args);
  }
}

/// The same fixture as a batch (for `testWithDataIntegrity`).
void seedV1InBatch(Batch batch) {
  for (final (sql, args) in v1SeedStatements) {
    batch.customStatement(sql, args);
  }
}

/// Every column the version 1 schema has, of every table, as raw rows in a
/// stable order. Works on a version 1 **and** on a later database (which
/// has more columns and tables, left out here), so what was stored before a
/// migration can be compared with what is there after it.
Future<Map<String, List<Map<String, Object?>>>> dumpV1Columns(
  GeneratedDatabase db,
) async {
  Future<List<Map<String, Object?>>> rows(String sql) async => [
    for (final row in await db.customSelect(sql).get()) row.data,
  ];
  return {
    'shift_types': await rows(
      'SELECT id, code, name, color_value, category, start_minute, '
      'end_minute, paid_minutes, night_override, sort_order, archived, '
      'created_at, updated_at FROM shift_types ORDER BY id',
    ),
    'patterns': await rows(
      'SELECT id, name, steps, created_at, updated_at FROM patterns '
      'ORDER BY rowid',
    ),
    'pattern_runs': await rows(
      'SELECT id, pattern_id, start_date, end_date, step_offset, seq, '
      'created_at FROM pattern_runs ORDER BY seq',
    ),
    'day_entries': await rows(
      'SELECT date, shift_type_ids, note, updated_at FROM day_entries '
      'ORDER BY date',
    ),
    'holidays': await rows(
      'SELECT id, date, scope, name, region_code, municipality_code, source '
      'FROM holidays ORDER BY id',
    ),
    'absence_balances': await rows(
      'SELECT year, type, allowed_days FROM absence_balances '
      'ORDER BY year, type',
    ),
    'settings': await rows('SELECT key, value FROM settings ORDER BY key'),
  };
}

/// The engine's view of the version 1 rows in [dump] (a result of
/// [dumpV1Columns]), built by hand from the raw rows so it knows nothing of
/// the code that reads the database: what the app showed before the upgrade.
Schedule scheduleFromV1Rows(Map<String, List<Map<String, Object?>>> dump) {
  int? intOrNull(Object? v) => v as int?;
  return Schedule(
    shiftTypes: [
      for (final r in dump['shift_types']!)
        ShiftType(
          id: r['id']! as String,
          code: r['code']! as String,
          name: r['name']! as String,
          colorValue: r['color_value']! as int,
          category: ShiftCategory.values.byName(r['category']! as String),
          startMinute: intOrNull(r['start_minute']),
          endMinute: intOrNull(r['end_minute']),
          paidMinutes: intOrNull(r['paid_minutes']),
          nightOverride: r['night_override'] == null
              ? null
              : r['night_override'] == 1,
        ),
    ],
    patterns: [
      for (final r in dump['patterns']!)
        Pattern(
          id: r['id']! as String,
          name: r['name']! as String,
          steps: [
            for (final step in jsonDecode(r['steps']! as String) as List)
              (step as List).cast<String>(),
          ],
        ),
    ],
    runs: [
      for (final r in dump['pattern_runs']!)
        PatternRun(
          id: r['id']! as String,
          patternId: r['pattern_id']! as String,
          startDate: CivilDate.parse(r['start_date']! as String),
          endDate: r['end_date'] == null
              ? null
              : CivilDate.parse(r['end_date']! as String),
          stepOffset: r['step_offset']! as int,
          seq: r['seq']! as int,
        ),
    ],
    entries: {
      for (final r in dump['day_entries']!)
        CivilDate.parse(r['date']! as String): DayEntry(
          date: CivilDate.parse(r['date']! as String),
          shiftTypeIds: r['shift_type_ids'] == null
              ? null
              : (jsonDecode(r['shift_type_ids']! as String) as List)
                    .cast<String>(),
          note: r['note'] as String?,
        ),
    },
  );
}

/// The 730 resolved days of [schedule] around [v1Today], one canonical line
/// per day: what a version 1 fingerprint compared.
List<String> v1ResolvedDays(Schedule schedule) {
  final window = defaultFingerprintWindow(v1Today);
  return resolvedDayLines(schedule, from: window.from, to: window.to);
}
