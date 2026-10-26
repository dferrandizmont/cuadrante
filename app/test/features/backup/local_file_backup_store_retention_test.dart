import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/features/backup/data/local_file_backup_store.dart';
import 'package:cuadrante/features/backup/domain/backup_retention.dart';
import 'package:cuadrante/features/backup/domain/backup_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'backup_test_support.dart';

Uint8List bytes(int seed) => Uint8List.fromList(List.filled(10, seed));

/// The store with the retention policy of the app (7 newest + one a day for
/// 30 days) on real files, and the store of the safety copies next to it.
void main() {
  late Directory dir;
  // Noon UTC: the same calendar day in every time zone.
  final now = DateTime.utc(2026, 10, 19, 12);
  const retention = BackupRetention();

  LocalFileBackupStore autoStore() => LocalFileBackupStore(
    dir,
    retain: (entries) => retention.idsToKeep(entries, now: now),
  );

  setUp(
    () => dir = Directory(p.join(makeTempDir('retention').path, 'backups')),
  );

  test('copies of one busy day are cut to the 7 newest', () async {
    final store = autoStore();
    for (var n = 0; n < 12; n++) {
      await store.save(bytes(n), at: now.subtract(Duration(minutes: 12 - n)));
    }
    final entries = await store.list();
    expect(entries, hasLength(7));
    expect(entries.first.modifiedAt, now.subtract(const Duration(minutes: 1)));
    expect(fileNames(dir), hasLength(7));
  });

  test('one a day for 30 days is kept, older days go', () async {
    final store = autoStore();
    // Oldest first, as the app would have taken them: 40 days, 2 a day.
    for (var d = 39; d >= 0; d--) {
      for (final hour in [9, 11]) {
        await store.save(
          bytes(d),
          at: DateTime.utc(2026, 10, 19, hour).subtract(Duration(days: d)),
        );
      }
    }
    final entries = await store.list();
    // Today's two (both among the newest 7), the 6 other days' latest copy
    // that are among the 7 newest are the same as their day's, and so on:
    // one per day for days 0-29 + the extra copies among the 7 newest.
    final days = entries
        .map(
          (e) => DateTime.utc(
            e.modifiedAt.year,
            e.modifiedAt.month,
            e.modifiedAt.day,
          ),
        )
        .toSet();
    expect(days, hasLength(30));
    expect(entries.length, greaterThanOrEqualTo(30));
    expect(entries.length, lessThanOrEqualTo(37));
    // The oldest survivor is from day 29, never older.
    expect(
      entries.last.modifiedAt.isAfter(now.subtract(const Duration(days: 30))),
      isTrue,
    );
  });

  test(
    'the copy just saved always survives, even if the policy forgets it',
    () async {
      final store = LocalFileBackupStore(dir, retain: (entries) => <String>{});
      final entry = await store.save(bytes(1), at: now);
      expect(await store.list(), [entry]);
      final second = await store.save(
        bytes(2),
        at: now.add(const Duration(minutes: 1)),
      );
      expect(await store.list(), [second]);
    },
  );

  test('with pruneOnSave off nothing goes until prune() says so', () async {
    final store = LocalFileBackupStore(
      dir,
      retain: (entries) => retention.idsToKeep(entries, now: now),
      pruneOnSave: false,
    );
    for (var n = 0; n < 12; n++) {
      await store.save(bytes(n), at: now.subtract(Duration(minutes: 12 - n)));
    }
    expect(await store.list(), hasLength(12));

    await store.prune();
    final left = await store.list();
    expect(left, hasLength(7));
    expect(left.first.modifiedAt, now.subtract(const Duration(minutes: 1)));
  });

  test(
    'prune() never drops the newest copy and works on an empty folder',
    () async {
      final store = LocalFileBackupStore(dir, retain: (entries) => <String>{});
      await store.prune(); // no folder yet
      final entry = await store.save(bytes(1), at: now);
      await store.prune();
      expect(await store.list(), [entry]);
    },
  );

  test('without retain, prune() keeps the newest [keep]', () async {
    final store = LocalFileBackupStore(dir, keep: 2, pruneOnSave: false);
    for (var n = 0; n < 4; n++) {
      await store.save(bytes(n), at: now.add(Duration(minutes: n)));
    }
    await store.prune();
    expect(await store.list(), hasLength(2));
  });

  test('delete removes a copy, and only the store\'s own', () async {
    final store = autoStore();
    final entry = await store.save(bytes(1), at: now);
    await store.delete(entry);
    expect(await store.list(), isEmpty);
    // Deleting again is not an error.
    await store.delete(entry);

    final other = File(p.join(dir.path, 'notes.txt'))..writeAsStringSync('x');
    await expectLater(
      store.delete(BackupEntry(id: 'notes.txt', modifiedAt: now, sizeBytes: 1)),
      throwsArgumentError,
    );
    expect(other.existsSync(), isTrue);
  });

  group('the safety copies share the folder', () {
    test('each store sees only its own files', () async {
      final auto = autoStore();
      final safety = LocalFileBackupStore(dir, prefix: 'pre-restore');
      final a = await auto.save(bytes(1), at: now);
      final s = await safety.save(
        bytes(2),
        at: now.add(const Duration(minutes: 1)),
      );

      expect((await auto.list()).map((e) => e.id), [a.id]);
      expect((await safety.list()).map((e) => e.id), [s.id]);
      expect(s.id, startsWith('pre-restore-'));
      expect(await safety.read(s), bytes(2));
      // A store never reads or deletes the other's files.
      expect(() => auto.read(s), throwsArgumentError);
      await expectLater(safety.delete(a), throwsArgumentError);
    });

    test('the retention of the automatic copies leaves the safety copies '
        'and the migration copies alone', () async {
      final auto = autoStore();
      final safety = LocalFileBackupStore(dir, prefix: 'pre-restore');
      dir.createSync(recursive: true);
      File(p.join(dir.path, 'pre-v1-a-v2-20260101-000000.sqlite'))
          .writeAsStringSync('db');
      for (var n = 0; n < 4; n++) {
        await safety.save(bytes(n), at: now.subtract(Duration(days: 60 + n)));
      }
      for (var n = 0; n < 12; n++) {
        await auto.save(bytes(n), at: now.subtract(Duration(minutes: 12 - n)));
      }
      expect(await safety.list(), hasLength(4));
      expect(await auto.list(), hasLength(7));
      expect(fileNames(dir).where((n) => n.endsWith('.sqlite')), [
        'pre-v1-a-v2-20260101-000000.sqlite',
      ]);
    });
  });
}
