import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/backup/application/backup_service.dart';
import 'package:cuadrante/features/backup/data/local_file_backup_store.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'backup_test_support.dart';

/// Thrown by [_WhereAmI] to tell the test which isolate ran the decoding.
class _RanOn implements Exception {
  const _RanOn(this.controlPort);

  final SendPort controlPort;
}

/// A codec that does not decode: it reports the isolate it runs on.
class _WhereAmI extends BackupCodec {
  const _WhereAmI();

  @override
  BackupFile decode(Uint8List bytes) =>
      throw _RanOn(Isolate.current.controlPort);
}

/// A codec that counts how it is called and whether inside the runner.
class _Spy extends BackupCodec {
  _Spy(this.state);

  final _SpyState state;

  @override
  BackupFile decode(Uint8List bytes) {
    state.decodedInsideRunner.add(state.depth > 0);
    return super.decode(bytes);
  }
}

class _SpyState {
  int depth = 0;
  final List<bool> decodedInsideRunner = [];
}

/// ~16 MB of tiny JSON objects in about 16 KB of gzip: what freezes a phone
/// when it is inflated and parsed on the UI isolate.
Uint8List _bomb({int objects = 5300000}) {
  final json = StringBuffer('{"format":"cuadrante","schemaVersion":2,"j":[');
  final unit = '{},';
  // Built in big blocks: a StringBuffer of 5 million writes is slow.
  final block = unit * 1000;
  for (var i = 0; i < objects ~/ 1000; i++) {
    json.write(block);
  }
  json.write('0]}');
  return Uint8List.fromList(
    GZipCodec(level: 9).encode(utf8.encode(json.toString())),
  );
}

void main() {
  late Directory dir;
  late AppDatabase db;

  BackupService serviceWith({
    BackupCodec codec = const BackupCodec(),
    BackupTaskRunner? runner,
  }) => BackupService(
    repository: makeRepository(db, Directory(p.join(dir.path, 'backups'))),
    store: LocalFileBackupStore(Directory(p.join(dir.path, 'store'))),
    appVersion: testAppVersion,
    codec: codec,
    runner: runner,
  );

  setUp(() {
    dir = makeTempDir('backup-inspect-isolate');
    db = openMemoryDatabase();
    addTearDown(db.close);
  });

  group('the decompression bomb (a few KB of gzip, ~16 MB of JSON)', () {
    final bomb = _bomb();

    test('is small as a file and huge once inflated', () {
      expect(bomb.length, lessThan(BackupCodec.maxFileBytes));
      expect(
        gzip.decode(bomb).length,
        greaterThan(bomb.length * BackupCodec.maxInflateRatio),
      );
    });

    test('is refused by the codec early, by the inflate ratio', () {
      final watch = Stopwatch()..start();
      expect(
        () => const BackupCodec().decode(bomb),
        throwsA(
          isA<CorruptBackup>().having(
            (e) => e.message,
            'message',
            contains('ratio'),
          ),
        ),
      );
      // It stops at about 100x the file size: no seconds of work.
      expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('is refused by inspect without blocking the UI isolate', () async {
      // A ticker on the UI isolate: if inspect froze it, ticks would stop.
      var ticks = 0;
      final ticker = Stream<void>.periodic(const Duration(milliseconds: 5))
          .listen((_) => ticks++);
      addTearDown(ticker.cancel);

      final watch = Stopwatch()..start();
      await expectLater(
        serviceWith().inspect(bomb),
        throwsA(isA<CorruptBackup>()),
      );
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      await ticker.cancel();
      expect(ticks, greaterThan(0), reason: 'the UI isolate kept running');
    });

    test('a bomb under the old 16 MB cap is refused too', () {
      // Old limit: inflates fully (1.8 s of JSON parsing on a phone's UI).
      final under = _bomb(objects: 4800000); // ~14.4 MB
      expect(gzip.decode(under).length, lessThan(16 * 1024 * 1024));
      expect(
        () => const BackupCodec().decode(under),
        throwsA(isA<CorruptBackup>()),
      );
    });
  });

  group('limits', () {
    test(
      'the decoded cap allows large notes while retaining ratio protection',
      () {
        expect(BackupCodec.defaultMaxDecodedBytes, 32 * 1024 * 1024);
        expect(BackupCodec.maxInflateRatio, 100);
      },
    );

    test('a real backup is nowhere near them', () {
      // The reference 2-year dataset inflates about 5:1 and weighs KB.
      final file = File('test/fixtures/golden_backup/golden_v2.cuadrante')
          .readAsBytesSync();
      final inflated = gzip.decode(file).length;
      expect(inflated, lessThan(BackupCodec.defaultMaxDecodedBytes ~/ 100));
      expect(inflated / file.length, lessThan(BackupCodec.maxInflateRatio / 5));
      expect(() => const BackupCodec().decode(file), returnsNormally);
    });
  });

  group('BackupService.inspect decodes through the runner', () {
    final golden = File('test/fixtures/golden_backup/golden_v2.cuadrante')
        .readAsBytesSync();

    test('and nothing else touches the bytes on the calling isolate', () async {
      final state = _SpyState();
      var runs = 0;
      final service = serviceWith(
        codec: _Spy(state),
        runner: <R>(R Function() task) async {
          runs++;
          state.depth++;
          try {
            return task();
          } finally {
            state.depth--;
          }
        },
      );

      final pending = await service.inspect(golden);

      expect(runs, 1);
      expect(state.decodedInsideRunner, [true]);
      expect(pending.summary.incoming.dayEntries, greaterThan(0));
    });

    test('with the real runner the decoding is on another isolate', () async {
      final service = serviceWith(codec: const _WhereAmI());
      try {
        await service.inspect(golden);
        fail('the spy codec always throws');
      } on _RanOn catch (where) {
        expect(
          where.controlPort,
          isNot(Isolate.current.controlPort),
          reason: 'decode ran on the UI isolate',
        );
      }
    });

    test('with the real runner a valid file comes back whole', () async {
      final viaIsolate = await serviceWith().inspect(golden);
      final inline = await serviceWith(runner: runOnThisIsolate)
          .inspect(golden);
      expect(viaIsolate.file.checksum, inline.file.checksum);
      expect(viaIsolate.file.data.toJson(), inline.file.data.toJson());
      expect(viaIsolate.summary.incoming, inline.summary.incoming);
    });

    test(
      'with the real runner each kind of bad file keeps its error',
      () async {
        final service = serviceWith();
        await expectLater(
          service.inspect(Uint8List.fromList([1, 2, 3, 4])),
          throwsA(isA<NotACuadranteFile>()),
        );
        await expectLater(
          service.inspect(Uint8List.sublistView(golden, 0, golden.length ~/ 2)),
          throwsA(isA<CorruptBackup>()),
        );
        final newer = Uint8List.fromList(
          GZipCodec().encode(
            utf8.encode(
              jsonEncode({
                'format': 'cuadrante',
                'schemaVersion': 99,
                'appVersion': 'x',
                'exportedAt': '2030-01-01T00:00:00Z',
                'data': <String, Object?>{},
                'checksum': 'sha256:0',
              }),
            ),
          ),
        );
        await expectLater(
          service.inspect(newer),
          throwsA(
            isA<NewerFormatVersion>().having((e) => e.found, 'found', 99),
          ),
        );
      },
    );
  });
}
