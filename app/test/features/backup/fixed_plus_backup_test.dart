import 'dart:io';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:cuadrante/features/backup/domain/backup_errors.dart';
import 'package:cuadrante/features/backup/domain/restore_summary.dart';
import 'package:cuadrante/features/backup/domain/schedule_fingerprint.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backup_test_support.dart';
import 'golden_dataset_v3.dart';
import 'golden_dataset.dart';
import 'v1_format.dart';
import 'v2_format.dart';

void main() {
  const codec = BackupCodec();
  late AppDatabase db;
  late Directory dir;

  setUp(() {
    db = openMemoryDatabase();
    addTearDown(db.close);
    dir = makeTempDir('fixed-plus-backup');
  });

  BackupData withPlus(Object? plus) {
    final json = buildGoldenBackupDataV3().toJson();
    final types = json['shiftTypes']! as List;
    (types.first as Map<String, Object?>)['fixedPlusCents'] = plus;
    return BackupData.fromJson(json);
  }

  test(
    'fixed cents survive codec, database, safety copy and verification',
    () async {
      final data = withPlus(3000);
      final repo = makeRepository(db, dir);
      final bytes = codec.encode(
        data,
        appVersion: 'test',
        exportedAt: DateTime.utc(2026, 10, 24),
      );
      final file = codec.decode(bytes);
      expect(file.schemaVersion, 3);
      expect(file.data, data);
      await repo.restore(file.data);
      expect(await repo.readAll(), data);
      final restored = await ScheduleRepository(db).load('main');
      expect(
        restored.schedule.shiftTypes
            .firstWhere((t) => t.id == data.shiftTypes.first.id)
            .fixedPlusCents,
        3000,
      );
      expect(
        await repo.verifyRestore(bytes, today: const CivilDate(2026, 10, 24)),
        isA<VerificationPassed>(),
      );
      final old = codec.decode(
        File('test/fixtures/golden_backup/golden_v3.cuadrante')
            .readAsBytesSync(),
      );
      await repo.restore(old.data);
      expect(
        (await repo.readAll()).shiftTypes.every(
          (t) => t.fixedPlusCents == null,
        ),
        isTrue,
      );
      final safetyCopies = dir.listSync().whereType<File>().map(
        (f) => codec.decode(f.readAsBytesSync()).data,
      );
      expect(
        safetyCopies.any(
          (d) => d.shiftTypes.any((t) => t.fixedPlusCents == 3000),
        ),
        isTrue,
      );
    },
  );

  test(
    'old v3 golden keeps canonical bytes and restores with no plus',
    () async {
      final old = codec.decode(
        File('test/fixtures/golden_backup/golden_v3.cuadrante')
            .readAsBytesSync(),
      );
      expect(
        old.data.shiftTypes.every((t) => t.fixedPlusCents == null),
        isTrue,
      );
      expect(BackupCodec.checksumOf(old.data), old.checksum);
      await makeRepository(db, dir).restore(old.data);
      expect(await makeRepository(db, dir).readAll(), old.data);
    },
  );

  test('absent plus is omitted; explicit zero and maximum round trip', () {
    final old = buildGoldenBackupDataV3();
    expect(
      (old.toJson()['shiftTypes']! as List).every(
        (t) => !(t as Map).containsKey('fixedPlusCents'),
      ),
      isTrue,
    );
    for (final plus in [null, 0, 999999]) {
      final data = withPlus(plus);
      final decoded = codec.decode(
        codec.encode(data, appVersion: 'test', exportedAt: DateTime.utc(2026)),
      );
      expect(decoded.data.shiftTypes.first.fixedPlusCents, plus);
    }
  });

  test('plus belongs to equality, copyWith, sanitization and fingerprint', () {
    final data = withPlus(3000);
    final type = data.shiftTypes.first.toShiftType();
    expect(type.copyWith(), type);
    expect(type.copyWith(clearFixedPlus: true).fixedPlusCents, isNull);
    expect(type.copyWith(fixedPlusCents: 3100), isNot(type));
    expect(data.shiftTypes.first.withoutAlarmSound().fixedPlusCents, 3000);
    expect(
      scheduleFingerprint(
        data,
        from: const CivilDate(2026, 1, 1),
        to: const CivilDate(2027, 12, 31),
      ),
      isNot(
        scheduleFingerprint(
          withPlus(null),
          from: const CivilDate(2026, 1, 1),
          to: const CivilDate(2027, 12, 31),
        ),
      ),
    );
  });

  for (final version in [1, 2]) {
    test('reader v$version ignores the optional plus even if invalid', () {
      final bytes = version == 1
          ? v1File(buildGoldenBackupData())
          : v2File(buildGoldenBackupDataV3());
      final env = readEnvelope(bytes);
      final json = env['data']! as Map<String, Object?>;
      for (final type in json['shiftTypes']! as List) {
        (type as Map<String, Object?>)['fixedPlusCents'] =
            'unknown to this version';
      }
      env['checksum'] = BackupCodec.checksumOfJson(json);
      expect(
        codec
            .decode(gzipEnvelope(env))
            .data
            .shiftTypes
            .every((t) => t.fixedPlusCents == null),
        isTrue,
      );
    });
  }

  for (final plus in [-1, 1000000, 3.5, '30']) {
    test('invalid plus $plus rejected before restore writes', () async {
      final repo = makeRepository(db, dir);
      final data = buildGoldenBackupDataV3();
      await seedDatabase(db, data);
      final before = await dumpAllTables(db);
      final env = readEnvelope(
        codec.encode(data, appVersion: 'test', exportedAt: DateTime.utc(2026)),
      );
      final json = env['data']! as Map<String, Object?>;
      ((json['shiftTypes']! as List).first
              as Map<String, Object?>)['fixedPlusCents'] =
          plus;
      env['checksum'] = BackupCodec.checksumOfJson(json);
      expect(
        () => codec.decode(gzipEnvelope(env)),
        throwsA(isA<CorruptBackup>()),
      );
      expect(await dumpAllTables(db), before);
      expect(await repo.readAll(), data);
    });
  }
}
