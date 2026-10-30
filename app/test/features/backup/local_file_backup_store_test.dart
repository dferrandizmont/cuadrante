import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/features/backup/data/local_file_backup_store.dart';
import 'package:cuadrante/features/backup/domain/backup_retention.dart';
import 'package:cuadrante/features/backup/domain/backup_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'backup_test_support.dart';

Uint8List bytes(int seed) => Uint8List.fromList(List.filled(10, seed));

void main() {
  late Directory dir;
  late LocalFileBackupStore store;

  setUp(() {
    dir = Directory(p.join(makeTempDir('store').path, 'icloud-like'));
    store = LocalFileBackupStore(dir, keep: 3);
  });

  test('an empty (even missing) store has no backups', () async {
    expect(await store.latest(), isNull);
    expect(await store.list(), isEmpty);
  });

  test('saves, and reads back the same bytes', () async {
    final entry = await store.save(
      bytes(1),
      at: DateTime.utc(2026, 11, 10, 9, 30, 15),
    );
    expect(entry.id, 'turnly-20261110-093015.turnly');
    expect(entry.modifiedAt, DateTime.utc(2026, 11, 10, 9, 30, 15));
    expect(entry.sizeBytes, 10);
    expect(await store.read(entry), bytes(1));
    expect(await store.latest(), entry);
  });

  test('latest is the newest by time, list is newest first', () async {
    final a = await store.save(bytes(1), at: DateTime.utc(2026, 11, 10, 9));
    final c = await store.save(bytes(3), at: DateTime.utc(2026, 11, 12, 9));
    final b = await store.save(bytes(2), at: DateTime.utc(2026, 11, 11, 9));
    expect(await store.list(), [c, b, a]);
    expect(await store.latest(), c);
  });

  test('keeps only the newest [keep]', () async {
    for (var day = 1; day <= 5; day++) {
      await store.save(bytes(day), at: DateTime.utc(2026, 11, day, 9));
    }
    final entries = await store.list();
    expect(entries.map((e) => e.modifiedAt.day), [5, 4, 3]);
    expect(fileNames(dir), hasLength(3));
  });

  test('mixed names list, read and rotate together by timestamp', () async {
    dir.createSync(recursive: true);
    final names = [
      'turnly-20261101-090000.turnly',
      'cuadrante-20261102-090000.cuadrante',
      'turnly-20261103-090000.turnly',
      'cuadrante-20261104-090000.cuadrante',
    ];
    for (var i = 0; i < names.length; i++) {
      File(p.join(dir.path, names[i])).writeAsBytesSync(bytes(i));
    }
    final before = await store.list();
    expect(before.map((e) => e.id), names.reversed);
    expect(await store.read(before.first), bytes(3));
    final saved = await store.save(bytes(5), at: DateTime.utc(2026, 11, 5, 9));
    expect((await store.list()).map((e) => e.id), [
      saved.id,
      names[3],
      names[2],
    ]);
    expect(fileNames(dir).toSet(), {saved.id, names[3], names[2]});
  });

  test(
    'daily retention prunes a mixed history without touching safety copies',
    () async {
      dir.createSync(recursive: true);
      const retention = BackupRetention(newest: 2, dailyForDays: 3);
      final now = DateTime.utc(2026, 11, 10, 12);
      store = LocalFileBackupStore(
        dir,
        retain: (entries) => retention.idsToKeep(entries, now: now),
      );
      final names = [
        'cuadrante-20261106-120000.cuadrante',
        'turnly-20261107-120000.turnly',
        'cuadrante-20261108-120000.cuadrante',
        'turnly-20261109-110000.turnly',
        'cuadrante-20261109-120000.cuadrante',
        'turnly-20261110-110000.turnly',
      ];
      for (final name in names) {
        File(p.join(dir.path, name)).writeAsBytesSync(bytes(1));
      }
      const safety = 'pre-restore-20261101-120000.cuadrante';
      File(p.join(dir.path, safety)).writeAsBytesSync(bytes(9));
      final saved = await store.save(bytes(2), at: now);
      expect(fileNames(dir).toSet(), {
        saved.id,
        names[5],
        names[4],
        names[2],
        safety,
      });
    },
  );

  test(
    'a new same-second copy follows legacy counters and survives rotation',
    () async {
      dir.createSync(recursive: true);
      const old = 'cuadrante-20261110-090000-9.cuadrante';
      File(p.join(dir.path, old)).writeAsBytesSync(bytes(9));
      store = LocalFileBackupStore(dir, keep: 1);
      final saved = await store.save(
        bytes(10),
        at: DateTime.utc(2026, 11, 10, 9),
      );
      expect(saved.id, 'turnly-20261110-090000-10.turnly');
      expect(fileNames(dir), [saved.id]);
      expect(await store.read(saved), bytes(10));
    },
  );

  test('two saves in the same second both survive', () async {
    final at = DateTime.utc(2026, 11, 10, 9);
    final first = await store.save(bytes(1), at: at);
    final second = await store.save(bytes(2), at: at);
    expect(second.id, isNot(first.id));
    expect(await store.read(first), bytes(1));
    expect(await store.read(second), bytes(2));
    expect((await store.list()).first, second);
  });

  test('ignores files that are not its own and leaves them alone', () async {
    await store.save(bytes(1), at: DateTime.utc(2026, 11, 10, 9));
    File(p.join(dir.path, 'notes.txt')).writeAsStringSync('hi');
    File(p.join(dir.path, 'pre-restore-20261110-090000.turnly'))
        .writeAsBytesSync(bytes(9));
    Directory(p.join(dir.path, 'turnly-20261110-100000.turnly')).createSync();
    expect(await store.list(), hasLength(1));
    for (var day = 11; day < 17; day++) {
      await store.save(bytes(day), at: DateTime.utc(2026, 11, day));
    }
    expect(fileNames(dir), contains('notes.txt'));
    expect(fileNames(dir), contains('pre-restore-20261110-090000.turnly'));
  });

  test('leaves no temporary file behind', () async {
    await store.save(bytes(1), at: DateTime.utc(2026, 11, 10, 9));
    expect(fileNames(dir).where((n) => n.endsWith('.tmp')), isEmpty);
  });

  test('only reads its own files', () async {
    await store.save(bytes(1), at: DateTime.utc(2026, 11, 10, 9));
    final outside = File(p.join(dir.parent.path, 'secret.turnly'))
      ..writeAsBytesSync(bytes(5));
    for (final id in [
      '../secret.turnly',
      outside.path,
      'notes.txt',
      'turnly-20261110-090000.cuadrante/../../x',
    ]) {
      expect(
        () => store.read(
          BackupEntry(id: id, modifiedAt: DateTime.utc(2026), sizeBytes: 0),
        ),
        throwsArgumentError,
        reason: id,
      );
    }
  });

  test('reading a backup that was deleted fails', () async {
    final entry = await store.save(bytes(1), at: DateTime.utc(2026, 11, 10, 9));
    File(p.join(dir.path, entry.id)).deleteSync();
    await expectLater(store.read(entry), throwsA(isA<FileSystemException>()));
  });
}
