import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/features/backup/application/backup_models.dart';
import 'package:cuadrante/features/backup/application/backup_providers.dart';
import 'package:cuadrante/features/backup/application/backup_service.dart';
import 'package:cuadrante/features/backup/data/local_file_backup_store.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_errors.dart';
import 'package:cuadrante/features/backup/domain/backup_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'backup_test_support.dart';

/// A store whose files read back as rubbish.
class _CorruptingStore extends LocalFileBackupStore {
  _CorruptingStore(super.directory, {super.retain, super.pruneOnSave});

  @override
  Future<Uint8List> read(BackupEntry entry) async =>
      Uint8List.fromList([1, 2, 3]);
}

void main() {
  late Directory dir;
  final at = DateTime.utc(2026, 10, 19, 10);

  BackupTools tools(LocalFileBackupStore autoStore) {
    final db = openMemoryDatabase();
    addTearDown(db.close);
    return BackupTools(
      directory: dir,
      autoStore: autoStore,
      safetyStore: LocalFileBackupStore(dir, prefix: 'pre-restore'),
      service: BackupService(
        repository: makeRepository(db, dir, now: () => at),
        store: autoStore,
        appVersion: testAppVersion,
        now: () => at,
      ),
    );
  }

  setUp(() => dir = Directory(p.join(makeTempDir('tools').path, 'backups')));

  test('a copy is written, read back and kept', () async {
    final t = tools(LocalFileBackupStore(dir));
    final entry = await t.backupAndVerify();
    expect(fileNames(dir), [entry.id]);
    const BackupCodec().decode(await t.autoStore.read(entry));
  });

  test(
    'a copy that cannot be read back is deleted and reported as a failure',
    () async {
      final t = tools(_CorruptingStore(dir));
      await expectLater(t.backupAndVerify(), throwsA(isA<BackupException>()));
      expect(fileNames(dir), isEmpty, reason: 'a bad copy must not stay');
    },
  );

  test('old copies go only after the new one has been read back', () async {
    // A policy that keeps nothing but the newest copy.
    LocalFileBackupStore store(
      LocalFileBackupStore Function(
        Directory dir,
        Set<String> Function(List<BackupEntry>) retain,
      )
      make,
    ) => make(dir, (entries) => <String>{});

    // Good copy: the old one is dropped afterwards.
    final good = tools(
      store(
        (dir, retain) =>
            LocalFileBackupStore(dir, retain: retain, pruneOnSave: false),
      ),
    );
    final old = await good.autoStore.save(
      Uint8List.fromList([9]),
      at: DateTime.utc(2026, 10, 1, 9),
    );
    final fresh = await good.backupAndVerify();
    expect(fileNames(dir), [fresh.id], reason: '${old.id} was dropped');

    // Bad copy: the new file is deleted and the old one is still there.
    dir.deleteSync(recursive: true);
    final bad = tools(
      _CorruptingStore(
        dir,
        retain: (entries) => <String>{},
        pruneOnSave: false,
      ),
    );
    final kept = await bad.autoStore.save(
      Uint8List.fromList([9]),
      at: DateTime.utc(2026, 10, 1, 9),
    );
    await expectLater(bad.backupAndVerify(), throwsA(isA<BackupException>()));
    expect(fileNames(dir), [kept.id], reason: 'the good old copy is kept');
  });

  test('the list merges the copies of the app and the safety copies, '
      'newest first', () async {
    final t = tools(LocalFileBackupStore(dir));
    final first = await t.autoStore.save(
      Uint8List.fromList([1]),
      at: DateTime.utc(2026, 10, 18, 9),
    );
    final safety = await t.safetyStore.save(
      Uint8List.fromList([2]),
      at: DateTime.utc(2026, 10, 19, 9),
    );
    final last = await t.autoStore.save(
      Uint8List.fromList([3]),
      at: DateTime.utc(2026, 10, 19, 10),
    );

    final copies = await t.copies();
    expect([for (final c in copies) c.id], [last.id, safety.id, first.id]);
    expect(
      [for (final c in copies) c.kind],
      [BackupCopyKind.local, BackupCopyKind.safety, BackupCopyKind.local],
    );
    // Each is read from its own store.
    expect(await t.read(copies[1]), Uint8List.fromList([2]));
    expect(await t.read(copies[2]), Uint8List.fromList([1]));
  });

  test('no folder yet means no copies', () async {
    expect(await tools(LocalFileBackupStore(dir)).copies(), isEmpty);
  });
}
