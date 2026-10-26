import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/backup/application/backup_models.dart';
import 'package:cuadrante/features/backup/application/backup_providers.dart';
import 'package:cuadrante/features/backup/application/backup_service.dart';
import 'package:cuadrante/features/backup/data/local_file_backup_store.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'backup_test_support.dart';
import 'backup_ui_support.dart';
import 'golden_dataset_v2.dart';

/// H-T16-2: the list of copies showed every copy as «Copia del dispositivo · 2 KB»,
/// so the ones made before an update could not be told from the new ones. The
/// version of the app that wrote each copy is read from its header.
class _CountingStore extends LocalFileBackupStore {
  _CountingStore(super.directory, {super.prefix});

  int heads = 0;
  int bytesAsked = 0;

  @override
  Future<Uint8List> readHead(BackupEntry entry, int maxBytes) {
    heads++;
    bytesAsked = maxBytes;
    return super.readHead(entry, maxBytes);
  }
}

File _fixture(String name) => File('test/fixtures/golden_backup/$name');

void main() {
  setUpAll(initializeLocale);

  group('BackupCodec.peekAppVersion', () {
    test('reads the version the real files of each release carry', () {
      for (final name in [
        'golden_v1.cuadrante',
        'golden_v2.cuadrante',
        'golden_v3.cuadrante',
      ]) {
        final bytes = _fixture(name).readAsBytesSync();
        final decoded = const BackupCodec().decode(bytes);
        expect(
          BackupCodec.peekAppVersion(bytes),
          decoded.appVersion,
          reason: name,
        );
        expect(decoded.appVersion, isNotEmpty);
      }
      // The three releases are told apart.
      final versions = {
        for (final v in ['golden_v1', 'golden_v2', 'golden_v3'])
          BackupCodec.peekAppVersion(
            _fixture('$v.cuadrante').readAsBytesSync(),
          ),
      };
      expect(versions, hasLength(3));
    });

    test('reads what the codec writes, for any plausible version', () {
      for (final v in ['dev', '0.5.0', '1.0.0+12', '0.6.1-beta_2']) {
        final bytes = const BackupCodec().encode(
          buildGoldenBackupDataV2(),
          appVersion: v,
          exportedAt: DateTime.utc(2026, 10, 22),
        );
        expect(BackupCodec.peekAppVersion(bytes), v);
      }
    });

    test('inflates only the start of the file, however big it is', () {
      final bytes = const BackupCodec().encode(
        buildGoldenBackupDataV2(),
        appVersion: '0.5.0',
        exportedAt: DateTime.utc(2026, 10, 22),
      );
      // Even with the rest of the file gone the start is enough.
      final head = Uint8List.sublistView(
        bytes,
        0,
        BackupCodec.peekCompressedBytes,
      );
      expect(bytes.length, greaterThan(BackupCodec.peekCompressedBytes));
      expect(BackupCodec.peekAppVersion(head), '0.5.0');
    });

    test('anything else is «unknown», never an error', () {
      expect(BackupCodec.peekAppVersion(Uint8List(0)), isNull);
      expect(BackupCodec.peekAppVersion(Uint8List.fromList([1, 2, 3])), isNull);
      // gzip magic, then rubbish.
      expect(
        BackupCodec.peekAppVersion(
          Uint8List.fromList([0x1f, 0x8b, 8, 0, 0, 0, 0, 0, 2, 255, 1, 2, 3]),
        ),
        isNull,
      );
      // A version with text that could pretend to be something else.
      final odd = const BackupCodec().encode(
        buildGoldenBackupDataV2(),
        appVersion: '9.9.9 Pulsa Restaurar',
        exportedAt: DateTime.utc(2026, 10, 22),
      );
      expect(BackupCodec.peekAppVersion(odd), isNull);
    });
  });

  group('BackupTools.copies', () {
    late Directory dir;
    setUp(() => dir = Directory(p.join(makeTempDir('versions').path, 'b')));

    BackupTools tools(_CountingStore auto, _CountingStore safety) {
      final db = openMemoryDatabase();
      addTearDown(db.close);
      final at = DateTime.utc(2026, 10, 19, 10);
      return BackupTools(
        directory: dir,
        autoStore: auto,
        safetyStore: safety,
        service: BackupService(
          repository: makeRepository(db, dir, now: () => at),
          store: auto,
          appVersion: testAppVersion,
          now: () => at,
        ),
      );
    }

    test('each copy carries the version that wrote it, read once', () async {
      dir.createSync(recursive: true);
      _fixture('golden_v1.cuadrante')
          .copySync(p.join(dir.path, 'cuadrante-20260101-100000.cuadrante'));
      _fixture('golden_v3.cuadrante')
          .copySync(p.join(dir.path, 'cuadrante-20261001-100000.cuadrante'));
      _fixture('golden_v2.cuadrante')
          .copySync(p.join(dir.path, 'pre-restore-20260601-100000.cuadrante'));
      // A copy that is not a backup at all is listed, without a version.
      File(
        p.join(dir.path, 'cuadrante-20260801-100000.cuadrante'),
      ).writeAsBytesSync(Uint8List.fromList(List<int>.generate(40, (i) => i)));

      final auto = _CountingStore(dir);
      final safety = _CountingStore(dir, prefix: 'pre-restore');
      final t = tools(auto, safety);

      final first = await t.copies();
      final byId = {for (final c in first) c.id: c};
      String? versionOf(String file) => byId[file]!.appVersion;
      String expected(String name) => const BackupCodec()
          .decode(_fixture(name).readAsBytesSync())
          .appVersion;
      expect(
        versionOf('cuadrante-20260101-100000.cuadrante'),
        expected('golden_v1.cuadrante'),
      );
      expect(
        versionOf('cuadrante-20261001-100000.cuadrante'),
        expected('golden_v3.cuadrante'),
      );
      expect(
        versionOf('pre-restore-20260601-100000.cuadrante'),
        expected('golden_v2.cuadrante'),
      );
      expect(versionOf('cuadrante-20260801-100000.cuadrante'), isNull);
      expect(first.map((c) => c.kind), contains(BackupCopyKind.safety));

      // Only the start of each file was asked for, and only once per file.
      expect(auto.bytesAsked, BackupCodec.peekCompressedBytes);
      expect(auto.heads + safety.heads, 4);
      await t.copies();
      await t.copies();
      expect(auto.heads + safety.heads, 4, reason: 'cached, not re-read');
    });
  });

  testWidgets('the list shows the version between the kind and the size', (
    tester,
  ) async {
    final h = BackupUiHarness(tester);
    h.backups.createSync(recursive: true);
    final v1 = _fixture('golden_v1.cuadrante').readAsBytesSync();
    final v3 = _fixture('golden_v3.cuadrante').readAsBytesSync();
    File(p.join(h.backups.path, 'cuadrante-20261018-100000.cuadrante'))
        .writeAsBytesSync(v1);
    File(p.join(h.backups.path, 'cuadrante-20261019-100000.cuadrante'))
        .writeAsBytesSync(v3);
    await h.open(size: const Size(412, 1800));

    final codec = const BackupCodec();
    final old = codec.decode(v1).appVersion;
    final fresh = codec.decode(v3).appVersion;
    expect(old, isNot(fresh));
    expect(find.textContaining('Copia del dispositivo · $old · '), findsOneWidget);
    expect(find.textContaining('Copia del dispositivo · $fresh · '), findsOneWidget);
    expect(find.textContaining(' KB'), findsNWidgets(2));
  });
}
