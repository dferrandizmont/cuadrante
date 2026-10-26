import 'dart:io';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/database_opener.dart';
import 'package:cuadrante/core/database/migration_backup.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as raw;

import '../../drift/app_database/generated/schema_v2.dart' as v2;
import '../../support/test_storage.dart';
import '../../support/v2_database.dart';

/// What a user of 0.3.0 – 0.5.0 goes through when 0.6.0 starts: the real
/// opener, a real file on disk, the pre-migration copy (made from the user
/// version `PRAGMA` of the file, hot journal included) and the migration.
void main() {
  late Directory dir;
  late File file;
  late Directory backups;
  late Map<String, List<Map<String, Object?>>> before;
  final stamp = DateTime.utc(2026, 11, 2, 8, 30, 15);

  Future<void> writeV2File() async {
    if (file.existsSync()) file.deleteSync();
    final old = v2.DatabaseAtV2(NativeDatabase(file));
    await seedV2(old);
    before = await dumpV2Columns(old);
    await old.close();
  }

  setUp(() async {
    dir = makeTempDir('upgrade2');
    file = File(p.join(dir.path, databaseFileName));
    backups = Directory(p.join(dir.path, backupsDirectoryName));
    await writeV2File();
  });

  List<String> backupNames() => backups.existsSync()
      ? ([for (final f in backups.listSync()) p.basename(f.path)]..sort())
      : <String>[];

  Future<AppDatabase> open() async {
    final db = await openAppDatabase(directory: dir, now: () => stamp);
    await db.customSelect('SELECT 1').get(); // forces the open and migration
    return db;
  }

  Future<void> expectEveryCalendarAsBefore(AppDatabase db) async {
    final repository = ScheduleRepository(db);
    for (final id in ['main', 'pareja', 'viejo']) {
      expect(
        v2ResolvedDays((await repository.load(id)).schedule),
        v2ResolvedDays(scheduleFromV2Rows(before, id)),
        reason: id,
      );
    }
  }

  test('the file starts as version 2', () {
    expect(readUserVersion(file), 2);
    expect(backups.existsSync(), isFalse);
  });

  test(
    'opening it migrates to v4 and keeps the copy made just before',
    () async {
      final db = await open();

      expect(readUserVersion(file), 4);
      expect(await dumpV2Columns(db), before);
      await expectEveryCalendarAsBefore(db);
      final types = await db.select(db.shiftTypes).get();
      expect(types, hasLength(8));
      expect(
        types.every((t) => t.icon == null && t.alarmSound == null),
        isTrue,
      );
      await db.close();

      // The copy: pre-v2-a-v4-<stamp>.sqlite, made before the migration.
      expect(backupNames(), ['pre-v2-a-v4-20261102-083015.sqlite']);
      final copy = File(p.join(backups.path, backupNames().single));
      expect(readUserVersion(copy), 2);

      // It opens as the v2 database it was, with every row, and has none of
      // what v3 adds.
      final asV2 = v2.DatabaseAtV2(NativeDatabase(copy));
      expect(await dumpV2Columns(asV2), before);
      final columns = [
        for (final r
            in await asV2
                .customSelect("PRAGMA table_info('day_entries')")
                .get())
          r.data['name'],
      ];
      expect(columns, isNot(contains('overtime_minutes')));
      await asV2.close();

      // Putting that file back (a user restoring the copy), the migration runs
      // again and keeps everything.
      final restored = File(p.join(dir.path, 'restored.sqlite'))
        ..writeAsBytesSync(copy.readAsBytesSync());
      final again = AppDatabase(NativeDatabase(restored));
      expect(await dumpV2Columns(again), before);
      await again.close();
      expect(readUserVersion(restored), 4);
    },
  );

  test('opening twice does not migrate twice', () async {
    final first = await open();
    final afterFirst = await dumpV2Columns(first);
    await first.close();

    final second = await openAppDatabase(
      directory: dir,
      now: () => stamp.add(const Duration(days: 1)),
    );
    await second.customSelect('SELECT 1').get();

    // No second copy, nothing recreated, nothing changed.
    expect(backupNames(), ['pre-v2-a-v4-20261102-083015.sqlite']);
    expect(await dumpV2Columns(second), afterFirst);
    expect(afterFirst, before);
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
    expect(readUserVersion(file), 2);
    final untouched = v2.DatabaseAtV2(NativeDatabase(file));
    expect(await dumpV2Columns(untouched), before);
    await untouched.close();
  });

  test('a journal left by a crash does not block the start', () async {
    File('${file.path}-journal').writeAsStringSync('leftover');
    final db = await open();
    expect(readUserVersion(file), 4);
    expect(await dumpV2Columns(db), before);
    await db.close();
    expect(backupNames(), ['pre-v2-a-v4-20261102-083015.sqlite']);
  });

  test('a REAL hot journal is recovered before the copy and the migration: '
      'only committed data survives', () async {
    // Crash in the middle of a transaction: the main file holds dirty pages
    // and the rollback journal says how to undo them.
    final db = raw.sqlite3.open(file.path);
    db.execute('PRAGMA journal_mode = DELETE');
    db.execute('BEGIN EXCLUSIVE');
    db.execute("UPDATE settings SET value = '\"uncommitted\"'");
    db.execute("DELETE FROM day_entries WHERE calendar_id = 'main'");
    db.execute('PRAGMA cache_spill = 1');
    db.execute(
      "INSERT INTO settings SELECT 'junk' || x, hex(randomblob(500)) FROM "
      '(WITH RECURSIVE c(x) AS (SELECT 1 UNION ALL SELECT x + 1 FROM c '
      'WHERE x < 2000) SELECT x FROM c)',
    );
    final journal = File('${file.path}-journal');
    final hot = journal.existsSync() ? journal.readAsBytesSync() : null;
    final dirtyMain = file.readAsBytesSync();
    db.execute('ROLLBACK');
    db.close();
    if (hot == null) {
      markTestSkipped('SQLite did not spill the transaction to disk');
      return;
    }
    file.writeAsBytesSync(dirtyMain);
    journal.writeAsBytesSync(hot);

    final opened = await open();
    expect(readUserVersion(file), 4);
    // What was committed before the "crash", all of it, and none of the rest.
    expect(await dumpV2Columns(opened), before);
    await expectEveryCalendarAsBefore(opened);
    await opened.close();

    // The copy is the recovered v2 file, not the dirty one.
    final copy = File(p.join(backups.path, backupNames().single));
    expect(readUserVersion(copy), 2);
    final asV2 = v2.DatabaseAtV2(NativeDatabase(copy));
    expect(await dumpV2Columns(asV2), before);
    await asV2.close();
  });

  test('the copies from earlier migrations stay; only the 3 newest are '
      'kept', () async {
    backups.createSync(recursive: true);
    for (final name in [
      'pre-v1-a-v2-20260101-000000.sqlite',
      'pre-v1-a-v2-20260201-000000.sqlite',
      'pre-v1-a-v2-20260301-000000.sqlite',
    ]) {
      File(p.join(backups.path, name)).writeAsStringSync('old');
    }
    final db = await open();
    await db.close();
    expect(backupNames(), [
      'pre-v1-a-v2-20260201-000000.sqlite',
      'pre-v1-a-v2-20260301-000000.sqlite',
      'pre-v2-a-v4-20261102-083015.sqlite',
    ]);
  });

  test('with the copy of the whole chain already there (an earlier launch '
      'that failed midway) no new copy is made', () async {
    backups.createSync(recursive: true);
    File(p.join(backups.path, 'pre-v1-a-v4-20261101-000000.sqlite'))
        .writeAsStringSync('the original v1');
    final db = await open();
    await db.close();
    expect(backupNames(), ['pre-v1-a-v4-20261101-000000.sqlite']);
    expect(
      File(p.join(backups.path, 'pre-v1-a-v4-20261101-000000.sqlite'))
          .readAsStringSync(),
      'the original v1',
    );
  });

  test('a file already on v4 makes no copy', () async {
    final first = await open();
    await first.close();
    for (final f in backups.listSync()) {
      (f as File).deleteSync();
    }
    final second = await open();
    await second.close();
    expect(backupNames(), isEmpty);
    expect(readUserVersion(file), AppDatabase.latestSchemaVersion);
  });
}
