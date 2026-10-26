import 'dart:io';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/core/config.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/database_provider.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/data/schedule_snapshot.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// A fresh in-memory database. sqlite comes from `package:sqlite3` (3.x), which
/// compiles/bundles it through its build hook on `flutter test`: nothing to
/// install on Windows, macOS or Linux.
AppDatabase openMemoryDatabase() {
  // Tests open several databases on purpose (reopening a file, a second
  // database next to the in-memory one).
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      // Recommended by Drift for widget tests: no timers left after close.
      closeStreamsSynchronously: true,
    ),
  );
}

/// A database opened and seeded like `bootstrapApp` does, plus what providers
/// need to run the app against it.
class TestStorage {
  TestStorage._(this.database, this.repository, this.snapshot);

  /// Runs the real [bootstrapApp] on an in-memory database (or on [database]).
  /// With [demo] the demo rotation and days around [now] are seeded.
  static Future<TestStorage> open({
    required DateTime now,
    bool demo = true,
    AppDatabase? database,
  }) async {
    final db = database ?? openMemoryDatabase();
    final boot = await bootstrapApp(
      config: AppConfig(useDemoData: demo),
      database: db,
      now: () => now,
    );
    return TestStorage._(
      db,
      ScheduleRepository(db, now: () => now),
      boot.schedule,
    );
  }

  final AppDatabase database;
  final ScheduleRepository repository;
  final ScheduleSnapshot snapshot;

  /// The same database with the snapshot read again (after the test changed
  /// what is stored).
  Future<TestStorage> withReloadedSnapshot() async => TestStorage._(
    database,
    repository,
    await repository.load(mainCalendarId),
  );

  List<Override> get overrides => [
    appDatabaseProvider.overrideWithValue(database),
    initialScheduleProvider.overrideWithValue(snapshot),
  ];

  Future<void> close() => database.close();
}

/// Opens [TestStorage] inside a widget test (real async, outside fake time)
/// and closes it when the test ends.
Future<TestStorage> openTestStorage(
  WidgetTester tester, {
  required DateTime now,
  bool demo = true,
}) async {
  final storage = await tester.runAsync(
    () => TestStorage.open(now: now, demo: demo),
  );
  addTearDown(() async {
    await tester.runAsync(storage!.close);
  });
  return storage!;
}

/// Two schedules hold exactly the same data.
void expectSameSchedule(Schedule actual, Schedule expected) {
  expect(actual.shiftTypes, expected.shiftTypes, reason: 'shift types');
  expect(actual.patterns, expected.patterns, reason: 'patterns');
  expect(actual.runs, expected.runs, reason: 'runs');
  expect(actual.entries, expected.entries, reason: 'entries');
}

/// Scratch directory removed when the test ends.
Directory makeTempDir(String name) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final dir = Directory.systemTemp.createTempSync('cuadrante-$name-');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  return dir;
}

/// Raw content of the tables the editor writes, in a stable order and
/// without `updated_at` (which legitimately changes when a row is rewritten).
Future<Map<String, List<Map<String, Object?>>>> dumpTables(
  AppDatabase db,
) async {
  Future<List<Map<String, Object?>>> rows(String sql) async => [
    for (final row in await db.customSelect(sql).get()) row.data,
  ];
  return {
    'day_entries': await rows(
      'SELECT date, shift_type_ids, note FROM day_entries ORDER BY date',
    ),
    'pattern_runs': await rows('SELECT * FROM pattern_runs ORDER BY seq'),
    'patterns': await rows('SELECT * FROM patterns ORDER BY rowid'),
    'shift_types': await rows('SELECT * FROM shift_types ORDER BY sort_order'),
  };
}
