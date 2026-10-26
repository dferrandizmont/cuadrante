import 'dart:io';

import 'package:cuadrante/core/database/migration_backup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../../support/test_storage.dart';

/// A SQLite file with `user_version = [version]` and one row, so a copy can be
/// told apart from an empty file.
File makeDatabase(Directory dir, int version, {String marker = 'hello'}) {
  final file = File(p.join(dir.path, 'cuadrante.sqlite'));
  if (file.existsSync()) file.deleteSync();
  final db = sqlite3.open(file.path);
  db.execute('CREATE TABLE t (v TEXT)');
  db.execute('INSERT INTO t VALUES (?)', [marker]);
  db.execute('PRAGMA user_version = $version');
  db.close();
  return file;
}

String readMarker(File file) {
  final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
  try {
    return db.select('SELECT v FROM t').single['v'] as String;
  } finally {
    db.close();
  }
}

void main() {
  late Directory dir;
  late Directory backups;

  setUp(() {
    dir = makeTempDir('backup');
    backups = Directory(p.join(dir.path, 'backups'));
  });

  List<String> names() => backups.existsSync()
      ? ([for (final f in backups.listSync()) p.basename(f.path)]..sort())
      : <String>[];

  group('readUserVersion', () {
    test('null for a missing or empty file', () {
      expect(readUserVersion(File(p.join(dir.path, 'nope.sqlite'))), isNull);
      final empty = File(p.join(dir.path, 'empty.sqlite'))..createSync();
      expect(readUserVersion(empty), isNull);
    });

    test('reads PRAGMA user_version', () {
      expect(readUserVersion(makeDatabase(dir, 3)), 3);
      expect(readUserVersion(makeDatabase(dir, 0)), 0);
    });
  });

  group('backupBeforeMigration', () {
    final now = DateTime.utc(2026, 11, 2, 8, 30, 15);

    Future<File?> run(File file, int target, {DateTime? at, int keep = 3}) =>
        backupBeforeMigration(
          databaseFile: file,
          targetVersion: target,
          backupsDirectory: backups,
          now: () => at ?? now,
          keep: keep,
        );

    test('copies the file when user_version < target', () async {
      final file = makeDatabase(dir, 1, marker: 'before');
      final copy = await run(file, 2);

      expect(copy, isNotNull);
      expect(p.basename(copy!.path), 'pre-v1-a-v2-20261102-083015.sqlite');
      expect(names(), ['pre-v1-a-v2-20261102-083015.sqlite']);
      expect(readUserVersion(copy), 1);
      expect(readMarker(copy), 'before');
      // The original is untouched.
      expect(readMarker(file), 'before');
      expect(readUserVersion(file), 1);
    });

    test('a v2 file going to v3 is copied as pre-v2-a-v3', () async {
      final file = makeDatabase(dir, 2, marker: 'v2 data');
      final copy = await run(file, 3);
      expect(p.basename(copy!.path), 'pre-v2-a-v3-20261102-083015.sqlite');
      expect(readUserVersion(copy), 2);
      expect(readMarker(copy), 'v2 data');
    });

    test(
      'a v1 file going straight to v3 makes ONE copy for the whole chain',
      () async {
        final file = makeDatabase(dir, 1, marker: 'v1 data');
        final copy = await run(file, 3);
        expect(names(), ['pre-v1-a-v3-20261102-083015.sqlite']);
        expect(readMarker(copy!), 'v1 data');
      },
    );

    test('no copy when user_version equals the target', () async {
      expect(await run(makeDatabase(dir, 2), 2), isNull);
      expect(names(), isEmpty);
      expect(backups.existsSync(), isFalse);
    });

    test('no copy when the file is newer than the code', () async {
      expect(await run(makeDatabase(dir, 5), 2), isNull);
      expect(names(), isEmpty);
    });

    test('no copy for user_version 0 (a brand new file)', () async {
      expect(await run(makeDatabase(dir, 0), 2), isNull);
      expect(names(), isEmpty);
    });

    test('no copy when there is no file yet', () async {
      expect(await run(File(p.join(dir.path, 'x.sqlite')), 1), isNull);
      expect(names(), isEmpty);
    });

    test('a journal left by a crash does not block start-up', () async {
      final file = makeDatabase(dir, 1, marker: 'before');
      File('${file.path}-journal').writeAsStringSync('leftover');
      final copy = await run(file, 2);
      expect(copy, isNotNull);
      expect(readMarker(copy!), 'before');
      expect(readMarker(file), 'before');
    });

    test('recovers a real hot journal before copying', () async {
      final file = makeDatabase(dir, 1, marker: 'committed');
      // Simulate a crash mid-transaction: keep the rollback journal of an
      // uncommitted write by copying it out while the transaction is open.
      final db = sqlite3.open(file.path);
      db.execute('PRAGMA journal_mode = DELETE');
      db.execute('BEGIN EXCLUSIVE');
      db.execute("UPDATE t SET v = 'uncommitted'");
      db.execute('PRAGMA cache_spill = 1');
      db.execute(
        'INSERT INTO t SELECT hex(randomblob(500)) FROM '
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

      final copy = await run(file, 2);
      expect(readMarker(copy!), 'committed');
      expect(readMarker(file), 'committed');
    });

    test('keeps only the 3 newest', () async {
      // One file, five different targets (one copy per target).
      final file = makeDatabase(dir, 1);
      for (var i = 0; i < 5; i++) {
        await run(file, 2 + i, at: now.add(Duration(days: i)));
      }
      expect(names(), [
        'pre-v1-a-v4-20261104-083015.sqlite',
        'pre-v1-a-v5-20261105-083015.sqlite',
        'pre-v1-a-v6-20261106-083015.sqlite',
      ]);
    });

    test('a migration that keeps failing midway makes no new copy and keeps '
        'the pre-v1 one', () async {
      // First launch: v1 -> v3 copies the file once; v1 -> v2 commits, v2 ->
      // v3 fails (the file is now at v2).
      final v1 = makeDatabase(dir, 1, marker: 'original v1');
      final first = await run(v1, 3);
      expect(p.basename(first!.path), 'pre-v1-a-v3-20261102-083015.sqlite');

      // Launches 2 to 6: the file is at v2, the target is still v3.
      for (var launch = 2; launch <= 6; launch++) {
        final v2 = makeDatabase(dir, 2, marker: 'half migrated $launch');
        final copy = await run(
          v2,
          3,
          at: now.add(Duration(days: launch)),
          keep: 3,
        );
        expect(copy, isNull, reason: 'launch $launch');
        expect(names(), ['pre-v1-a-v3-20261102-083015.sqlite']);
      }
      expect(readMarker(first), 'original v1');
    });

    test('a copy for another target does not stop the next one', () async {
      await run(makeDatabase(dir, 1), 2);
      final copy = await run(
        makeDatabase(dir, 2),
        3,
        at: now.add(const Duration(days: 1)),
      );
      expect(copy, isNotNull);
      expect(names(), [
        'pre-v1-a-v2-20261102-083015.sqlite',
        'pre-v2-a-v3-20261103-083015.sqlite',
      ]);
    });

    test('pruning never deletes the oldest copy of the target, whatever its '
        'age', () async {
      backups.createSync(recursive: true);
      for (final name in [
        'pre-v1-a-v3-20260101-000000.sqlite', // the original: oldest
        'pre-v2-a-v3-20260201-000000.sqlite',
        'pre-v2-a-v3-20260202-000000.sqlite',
        'pre-v2-a-v3-20260203-000000.sqlite',
        'pre-v2-a-v3-20260204-000000.sqlite',
      ]) {
        File(p.join(backups.path, name)).writeAsStringSync('x');
      }
      await pruneMigrationBackups(backups, 3, protectOldestOfTarget: 3);
      expect(names(), [
        'pre-v1-a-v3-20260101-000000.sqlite',
        'pre-v2-a-v3-20260202-000000.sqlite',
        'pre-v2-a-v3-20260203-000000.sqlite',
        'pre-v2-a-v3-20260204-000000.sqlite',
      ]);
    });

    test(
      'newest is by date, across versions; other files are left alone',
      () async {
        backups.createSync(recursive: true);
        File(p.join(backups.path, 'notes.txt')).writeAsStringSync('mine');
        for (final name in [
          'pre-v2-a-v3-20270101-000000.sqlite',
          'pre-v1-a-v2-20261201-000000.sqlite',
          'pre-v1-a-v2-20261101-000000.sqlite',
        ]) {
          File(p.join(backups.path, name)).writeAsStringSync('old');
        }
        await run(makeDatabase(dir, 3), 4, at: DateTime.utc(2027, 6, 1));
        expect(names(), [
          'notes.txt',
          'pre-v1-a-v2-20261201-000000.sqlite',
          'pre-v2-a-v3-20270101-000000.sqlite',
          'pre-v3-a-v4-20270601-000000.sqlite',
        ]);
      },
    );

    test(
      'a failing copy throws instead of letting the migration run',
      () async {
        final file = makeDatabase(dir, 1);
        // A file where the backups directory should be.
        File(backups.path).writeAsStringSync('in the way');
        await expectLater(run(file, 2), throwsA(isA<FileSystemException>()));
      },
    );
  });
}
