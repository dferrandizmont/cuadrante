import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cuadrante/core/database/migration_backup.dart';
import 'package:cuadrante/features/backup/domain/canonical_json.dart';
import 'package:cuadrante/features/backup/domain/schedule_fingerprint.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../test/drift/app_database/generated/schema_v1.dart' as v1;
import '../../test/support/v1_database.dart';
import '../support/qa_core.dart';
import '../support/qa_harness.dart';

const _oct19 = CivilDate(2026, 10, 19); // override: Mañana + Noche
const _oct20 = CivilDate(2026, 10, 20); // override: [] (empty on purpose)
const _oct21 = CivilDate(2026, 10, 21); // note only
const _oct22 = CivilDate(2026, 10, 22); // override: Vacaciones + note
const _oct23 = CivilDate(2026, 10, 23); // no override: run 2 (mañanas)

/// The upgrade scenarios of the battery (docs/qa.md, "Actualización"). U02 is
/// not here: it needs the real 0.2.0 APK and runs from
/// `tool/qa/upgrade_android.sh`.
final List<QaScenario> upgradeScenarios = [qaMigrationOnDevice]; // U01

/// U01.
const qaMigrationOnDevice = QaScenario(
  'U01',
  'Migración v1 → v4 en el dispositivo',
  _migration,
  timeout: Duration(minutes: 5),
);

final _backupName = RegExp(r'^pre-v1-a-v4-\d{8}-\d{6}\.sqlite$');

Future<void> _migration(QaContext qa) async {
  final t = qa.tester;

  // 1. A REAL version 1 file on the device, written with the v1 schema
  //    (generated from the 0.2.0 tables) through the Android SQLite library.
  late final Map<String, List<Map<String, Object?>>> before;
  final app = await QaApp.open(
    qa,
    demo: false,
    mount: false,
    beforeOpen: (dir) async {
      final file = File(p.join(dir.path, 'cuadrante.sqlite'));
      final old = v1.DatabaseAtV1(NativeDatabase(file));
      await seedV1(old);
      before = await dumpV1Columns(old);
      await old.close();
      if (readUserVersion(file) != 1) {
        throw TestFailure('El archivo de partida debe ser v1');
      }
    },
  );
  final file = File(p.join(app.dir.path, 'cuadrante.sqlite'));
  final backups = Directory(p.join(app.dir.path, 'backups'));
  qa.note(
    'v1: ${before['shift_types']!.length} tipos (1 archivado), '
    '${before['patterns']!.length} patrones, '
    '${before['pattern_runs']!.length} rotaciones, '
    '${before['day_entries']!.length} excepciones, '
    '${before['holidays']!.length} festivos, '
    '${before['settings']!.length} ajustes',
  );

  // The 730-day fingerprint of what the user had on v1 (0.2.0).
  final v1Days = v1ResolvedDays(scheduleFromV1Rows(before));
  final v1Digest = sha256Hex(utf8.encode(v1Days.join('\n')));
  expect(v1Days, hasLength(fingerprintWindowDays));
  expect(
    v1Days.toSet().length,
    greaterThan(60),
    reason: 'el fixture debe resolver muchos días distintos',
  );

  // 2. Opened through `openAppDatabase` (done by QaApp.open): the copy was
  //    made before anything migrated, and the first query migrates.
  List<String> backupNames() => backups.existsSync()
      ? ([for (final f in backups.listSync()) p.basename(f.path)]..sort())
      : <String>[];
  expect(backupNames(), hasLength(1), reason: 'una copia previa');
  expect(backupNames().single, matches(_backupName));
  final copy = File(p.join(backups.path, backupNames().single));
  final copyDigest = sha256.convert(copy.readAsBytesSync()).toString();
  expect(readUserVersion(copy), 1, reason: 'la copia es v1');

  final version = await app.query('PRAGMA user_version');
  expect(version.single.values.single, 4, reason: 'esquema v4 tras abrir');
  expect(readUserVersion(file), 4);
  final migratedTypes = await app.query(
    'SELECT id, fixed_plus_cents FROM shift_types ORDER BY id',
  );
  expect(migratedTypes, hasLength(before['shift_types']!.length));
  for (final row in migratedTypes) {
    expect(
      row['fixed_plus_cents'],
      isNull,
      reason: '${row['id']}: la migración no inventa un plus fijo',
    );
  }

  // 3. Everything attached to `main`, nothing lost.
  final calendars = await app.query('SELECT id, name FROM calendars');
  expect([for (final c in calendars) c['id']], ['main']);
  for (final table in ['pattern_runs', 'day_entries']) {
    final total = (await app.query('SELECT COUNT(*) AS n FROM $table')).single;
    final inMain = (await app.query(
      "SELECT COUNT(*) AS n FROM $table WHERE calendar_id = 'main'",
    )).single;
    expect(total['n'], before[table]!.length, reason: 'filas de $table');
    expect(inMain['n'], total['n'], reason: '$table: todo en main');
  }
  expect(
    await dumpV1Columns(app.database),
    before,
    reason: 'cada columna de v1 idéntica tras migrar',
  );

  // 4. The fingerprint of `main` equals the one of v1.
  final loaded = (await t.runAsync(
    () => ScheduleRepository(app.database).load('main'),
  ))!;
  final window = defaultFingerprintWindow(v1Today);
  final migratedDays = resolvedDayLines(
    loaded.schedule,
    from: window.from,
    to: window.to,
  );
  expect(migratedDays, v1Days, reason: '730 días resueltos idénticos');
  final migratedDigest = sha256Hex(utf8.encode(migratedDays.join('\n')));
  expect(migratedDigest, v1Digest);
  qa.metric('huella_730_dias', migratedDigest.substring(0, 16));

  // 5. The copy still opens as the v1 database it was, with the same data
  //    (and opening it does not change a byte of it).
  final asV1 = v1.DatabaseAtV1(NativeDatabase(copy));
  try {
    final copyDump = (await t.runAsync(() => dumpV1Columns(asV1)))!;
    expect(copyDump, before, reason: 'la copia previa tiene los datos de v1');
    final tables = (await t.runAsync(
      () => asV1
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get(),
    ))!;
    expect([
      for (final r in tables) r.data['name'],
    ], isNot(contains('calendars')));
  } finally {
    await t.runAsync(asV1.close);
  }
  expect(readUserVersion(copy), 1);
  expect(sha256.convert(copy.readAsBytesSync()).toString(), copyDigest);

  // 6. The app on it: the month shows the migrated shifts.
  await app.mount();
  expect(inCell(_oct19, find.text('M')), findsOneWidget);
  expect(inCell(_oct19, find.text('N')), findsOneWidget);
  expect(inCell(_oct20, find.text('M')), findsNothing, reason: '[] manda');
  expect(inCell(_oct22, find.text('V')), findsOneWidget);
  expect(inCell(_oct23, find.text('M')), findsOneWidget, reason: 'run 2');
  await qa.shot('mes_migrado');

  Finder inSheet(Finder matching) =>
      find.descendant(of: find.byType(BottomSheet), matching: matching);
  // The day sheet can fill the screen: close it as a user would, with Back.
  Future<void> dismiss() async {
    await t.binding.handlePopRoute();
    await t.settle();
    expect(find.byType(BottomSheet), findsNothing);
  }

  await t.tapAndSettle(cell(_oct22));
  // The palette chips of the editable sheet repeat the names: look inside the
  // day's own shift row.
  expect(
    find.descendant(
      of: find.byKey(const ValueKey('day-shift-0')),
      matching: find.text('Vacaciones'),
    ),
    findsOneWidget,
  );
  expect(find.byKey(const ValueKey('day-shift-1')), findsNothing);
  expect(inSheet(find.text('Viaje a Cádiz')), findsOneWidget);
  await qa.shot('dia_vacaciones');
  await dismiss();
  await t.tapAndSettle(cell(_oct21));
  expect(inSheet(find.text('Cambio con Marta')), findsOneWidget);
  await dismiss();
  await t.tapAndSettle(cell(_oct20));
  expect(inSheet(find.text('Este día no tiene turno.')), findsOneWidget);
  await dismiss();

  // The user's own data survived the start of the app (the bundled holidays
  // may be refreshed; the user's and the settings may not change).
  final afterBoot = await _snapshot(app);
  List<Object?> userHolidays(Map<String, List<Map<String, Object?>>> s) => [
    for (final r in s['holidays']!)
      if (r['source'] == 'user') r,
  ];
  expect(
    userHolidays(afterBoot),
    userHolidays({'holidays': before['holidays']!}),
    reason: 'festivos propios',
  );
  expect(
    afterBoot['holidays']!.where((r) => r['source'] == 'user'),
    hasLength(2),
  );
  for (final table in [
    'shift_types',
    'patterns',
    'pattern_runs',
    'day_entries',
    'absence_balances',
  ]) {
    expect(afterBoot[table], isNotEmpty);
  }
  for (final key in ['holidays.region', 'holidays.municipality', 'alarms']) {
    expect(
      afterBoot['settings']!.where((r) => r['key'] == key).toList(),
      before['settings']!.where((r) => r['key'] == key).toList(),
      reason: 'ajuste $key',
    );
  }

  // 7. Close and open again: no second copy, no duplicates, nothing changed.
  await app.restart();
  expect(backupNames(), hasLength(1), reason: 'sin una segunda copia');
  expect(
    sha256.convert(copy.readAsBytesSync()).toString(),
    copyDigest,
    reason: 'la copia previa no cambia',
  );
  expect(readUserVersion(file), 4);
  final again = await _snapshot(app);
  expect(again, afterBoot, reason: 'reabrir no duplica ni cambia filas');
  expect(
    (await app.query('SELECT COUNT(*) AS n FROM calendars')).single['n'],
    1,
  );
  expect(inCell(_oct19, find.text('M')), findsOneWidget);
  expect(inCell(_oct19, find.text('N')), findsOneWidget);
  await qa.shot('reabierto');
}

/// Every table of the database (calendars included) as raw rows, sorted, so
/// two snapshots are equal only if nothing was added, dropped or changed.
Future<Map<String, List<Map<String, Object?>>>> _snapshot(QaApp app) async {
  final tables = await app.query(
    "SELECT name FROM sqlite_master WHERE type = 'table' "
    "AND name NOT LIKE 'sqlite_%' ORDER BY name",
  );
  final out = <String, List<Map<String, Object?>>>{};
  for (final table in tables) {
    final name = table['name']! as String;
    final rows = await app.query('SELECT * FROM "$name"');
    rows.sort((a, b) => jsonEncode(_plain(a)).compareTo(jsonEncode(_plain(b))));
    out[name] = rows;
  }
  return out;
}

Map<String, Object?> _plain(Map<String, Object?> row) => {
  for (final e in row.entries)
    e.key: e.value is List<int> ? base64Encode(e.value! as List<int>) : e.value,
};
