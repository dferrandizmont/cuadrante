import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cuadrante/features/backup/application/backup_providers.dart';
import 'package:cuadrante/features/backup/application/backup_service.dart';
import 'package:cuadrante/features/backup/data/backup_repository.dart';
import 'package:cuadrante/features/backup/data/local_file_backup_store.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'backup_test_support.dart';

class _ProcessingProbe extends BackupCodec {
  const _ProcessingProbe(this.port);

  final SendPort port;

  @override
  Uint8List encode(
    BackupData data, {
    required String appVersion,
    required DateTime exportedAt,
  }) {
    port.send(('encode', Isolate.current.controlPort));
    return super.encode(data, appVersion: appVersion, exportedAt: exportedAt);
  }

  @override
  BackupFile decode(Uint8List bytes) {
    port.send(('decode', Isolate.current.controlPort));
    return super.decode(bytes);
  }
}

void main() {
  test(
    'export, automatic backup and safety copy process away from the UI isolate',
    () async {
      final dir = makeTempDir('backup-processing');
      final db = openMemoryDatabase();
      addTearDown(db.close);
      final port = ReceivePort();
      addTearDown(port.close);
      final events = <(String, SendPort)>[];
      final completed = Completer<void>();
      final subscription = port.listen((event) {
        events.add(event as (String, SendPort));
        if (events.length == 5) completed.complete();
      });
      addTearDown(subscription.cancel);
      final codec = _ProcessingProbe(port.sendPort);
      final repository = BackupRepository(
        db,
        safetyDirectory: Directory(p.join(dir.path, 'safety')),
        appVersion: testAppVersion,
        codec: codec,
      );
      final store = LocalFileBackupStore(
        Directory(p.join(dir.path, 'auto')),
        pruneOnSave: false,
      );
      final service = BackupService(
        repository: repository,
        store: store,
        appVersion: testAppVersion,
        codec: codec,
      );
      final tools = BackupTools(
        directory: dir,
        service: service,
        autoStore: store,
        safetyStore: LocalFileBackupStore(
          repository.safetyDirectory,
          prefix: 'pre-restore',
        ),
        codec: codec,
      );
      await service.exportBytes();
      await tools.backupAndVerify();
      await repository.restore(BackupData());
      await completed.future.timeout(const Duration(seconds: 10));
      expect(events.where((e) => e.$1 == 'encode'), hasLength(3));
      expect(events.where((e) => e.$1 == 'decode'), hasLength(2));
      for (final event in events) {
        expect(event.$2, isNot(Isolate.current.controlPort), reason: event.$1);
      }
    },
  );
}
