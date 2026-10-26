import 'dart:io';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/database_opener.dart';
import 'package:cuadrante/core/database/migration_backup.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../drift/app_database/generated/schema_v1.dart' as v1;
import '../../support/test_storage.dart';
import '../../support/v1_database.dart';

/// What a user of 0.1.0 / 0.2.0 goes through when the app starts after the
/// updates: the real opener, a real file on disk, the pre-migration copy and
/// the whole chain of migrations (v1 -> v2 -> v3 -> v4).
void main() {
  late Directory dir;
  late File file;
  late Directory backups;
  late Map<String, List<Map<String, Object?>>> before;
  final stamp = DateTime.utc(2026, 11, 2, 8, 30, 15);

  setUp(() async {
    dir = makeTempDir('upgrade');
    file = File(p.join(dir.path, databaseFileName));
    backups = Directory(p.join(dir.path, backupsDirectoryName));

    // The file 0.2.0 leaves on the phone.
    final old = v1.DatabaseAtV1(NativeDatabase(file));
    await seedV1(old);
    before = await dumpV1Columns(old);
    await old.close();
  });

  List<String> backupNames() => backups.existsSync()
      ? ([for (final f in backups.listSync()) p.basename(f.path)]..sort())
      : <String>[];

  Future<AppDatabase> open() async {
    final db = await openAppDatabase(directory: dir, now: () => stamp);
    await db.customSelect('SELECT 1').get(); // forces the open and migration
    return db;
  }

  test('the file starts as version 1', () {
    expect(readUserVersion(file), 1);
    expect(backups.existsSync(), isFalse);
  });

  test('opening it migrates to v4 (through v2) and keeps the copy made just '
      'before', () async {
    final db = await open();

    // Migrated: v4, the same data, attached to main, the same days.
    expect(readUserVersion(file), 4);
    expect(await dumpV1Columns(db), before);
    final loaded = await ScheduleRepository(db).load('main');
    expect(
      v1ResolvedDays(loaded.schedule),
      v1ResolvedDays(scheduleFromV1Rows(before)),
    );
    await db.close();

    // The copy: pre-v1-a-v4-<stamp>.sqlite, made before the migration.
    expect(backupNames(), ['pre-v1-a-v4-20261102-083015.sqlite']);
    final copy = File(p.join(backups.path, backupNames().single));
    expect(readUserVersion(copy), 1);

    // It opens as the v1 database it was, with every row.
    final asV1 = v1.DatabaseAtV1(NativeDatabase(copy));
    expect(await dumpV1Columns(asV1), before);
    final tables = [
      for (final r
          in await asV1
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type = 'table'",
              )
              .get())
        r.data['name'],
    ];
    expect(tables, isNot(contains('calendars')));
    await asV1.close();

    // And restoring it, the app (not just the schema) reads it all: a user
    // could put that file back and the migration would run again.
    final restored = File(p.join(dir.path, 'restored.sqlite'))
      ..writeAsBytesSync(copy.readAsBytesSync());
    final again = AppDatabase(NativeDatabase(restored));
    expect(await dumpV1Columns(again), before);
    await again.close();
    expect(readUserVersion(restored), 4);
  });

  test('opening twice does not migrate twice', () async {
    final first = await open();
    final afterFirst = await _everything(first);
    final calendarStamp =
        (await first.select(first.calendars).getSingle()).createdAt;
    await first.close();

    final second = await openAppDatabase(
      directory: dir,
      now: () => stamp.add(const Duration(days: 1)),
    );
    await second.customSelect('SELECT 1').get();

    // No second copy, nothing recreated, nothing changed.
    expect(backupNames(), ['pre-v1-a-v4-20261102-083015.sqlite']);
    expect(await _everything(second), afterFirst);
    expect(
      (await second.select(second.calendars).getSingle()).createdAt,
      calendarStamp,
    );
    await second.close();
    expect(readUserVersion(file), 4);
  });

  test('without the safety copy there is no migration', () async {
    // A file where the backups folder should be.
    File(backups.path).writeAsStringSync('in the way');

    await expectLater(
      openAppDatabase(directory: dir, now: () => stamp),
      throwsA(isA<FileSystemException>()),
    );

    // The user's file is exactly as it was.
    expect(readUserVersion(file), 1);
    final untouched = v1.DatabaseAtV1(NativeDatabase(file));
    expect(await dumpV1Columns(untouched), before);
    await untouched.close();
  });

  test('a new install has main and no copy', () async {
    final fresh = Directory(p.join(dir.path, 'fresh'))..createSync();
    final db = await openAppDatabase(directory: fresh);
    final calendars = await db.select(db.calendars).get();
    expect([for (final c in calendars) c.id], ['main']);
    expect(calendars.single.name, 'Mi cuadrante');
    await db.close();
    expect(readUserVersion(File(p.join(fresh.path, databaseFileName))), 4);
    expect(
      Directory(p.join(fresh.path, backupsDirectoryName)).existsSync(),
      isFalse,
    );
  });

  test('seeding a new install puts the demo days in main', () async {
    final storage = await TestStorage.open(now: DateTime(2026, 10, 19));
    addTearDown(storage.close);

    final calendars = await storage.database
        .select(storage.database.calendars)
        .get();
    expect([for (final c in calendars) c.id], ['main']);
    expect(storage.snapshot.calendarId, 'main');
    expect(storage.snapshot.schedule.runs, isNotEmpty);
    final runCalendars = await storage.database
        .customSelect('SELECT DISTINCT calendar_id AS c FROM pattern_runs')
        .get();
    expect([for (final r in runCalendars) r.data['c']], ['main']);
  });
}

/// Every table and column of the migrated database, calendars included.
Future<Map<String, List<Map<String, Object?>>>> _everything(
  AppDatabase db,
) async {
  final all = await dumpV1Columns(db);
  Future<List<Map<String, Object?>>> rows(String sql) async => [
    for (final row in await db.customSelect(sql).get()) row.data,
  ];
  return {
    ...all,
    'calendars': await rows('SELECT * FROM calendars ORDER BY id'),
    'pattern_runs_calendar': await rows(
      'SELECT id, calendar_id FROM pattern_runs ORDER BY seq',
    ),
    'day_entries_calendar': await rows(
      'SELECT calendar_id, date FROM day_entries ORDER BY date',
    ),
    'shift_type_rates': await rows(
      'SELECT id, hourly_rate_cents FROM shift_types ORDER BY id',
    ),
  };
}
