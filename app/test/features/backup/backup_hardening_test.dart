import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/backup/data/backup_repository.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:cuadrante/features/backup/domain/backup_errors.dart';
import 'package:cuadrante/features/backup/domain/restore_summary.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'backup_test_support.dart';
import 'golden_dataset_v3.dart';

/// A file is untrusted input (docs/copia-de-seguridad.md, "Valores
/// acotados"): crafted numbers must not overflow the summary sums, and an
/// alarm sound of a provider that is not the system's is dropped.
void main() {
  const codec = BackupCodec();
  late AppDatabase db;
  late Directory dir;
  late BackupRepository repo;

  setUp(() {
    db = openMemoryDatabase();
    addTearDown(db.close);
    dir = makeTempDir('backup-hardening');
    repo = makeRepository(db, Directory(p.join(dir.path, 'safety')));
  });

  Map<String, Object?> dataJson() =>
      jsonDecode(jsonEncode(buildGoldenBackupDataV3().toJson()))
          as Map<String, Object?>;

  Uint8List v3File(Map<String, Object?> data) => gzipEnvelope({
    'format': 'cuadrante',
    'schemaVersion': 3,
    'appVersion': 'x',
    'exportedAt': '2027-01-20T08:15:00Z',
    'data': data,
    'checksum': BackupCodec.checksumOfJson(data),
  });

  List<Map<String, Object?>> list(Map<String, Object?> data, String key) =>
      (data[key]! as List).cast<Map<String, Object?>>();

  group('overtime, early leave and rates are bounded', () {
    test('the golden file passes: its values are inside the limits', () {
      expect(() => codec.decode(v3File(dataJson())), returnsNormally);
    });

    test(
      'a crafted v3 file with a day of overtime beyond 24 h is rejected',
      () {
        for (final field in ['overtimeMinutes', 'earlyLeaveMinutes']) {
          for (final value in [maxDayExtraMinutes + 1, 4611686018427387904]) {
            final data = dataJson();
            list(data, 'dayEntries').first[field] = value;
            expect(
              () => codec.decode(v3File(data)),
              throwsA(isA<CorruptBackup>()),
              reason: '$field = $value',
            );
          }
        }
      },
    );

    test('24 h exactly is the last accepted value', () {
      final data = dataJson();
      final day = list(data, 'dayEntries').first;
      day['overtimeMinutes'] = maxDayExtraMinutes;
      day['earlyLeaveMinutes'] = maxDayExtraMinutes;
      final read = codec.decode(v3File(data)).data;
      expect(
        read.dayEntries.any(
          (e) =>
              e.overtimeMinutes == maxDayExtraMinutes &&
              e.earlyLeaveMinutes == maxDayExtraMinutes,
        ),
        isTrue,
      );
    });

    test('a crafted hourly rate out of what the editor allows is rejected', () {
      for (final value in [-1, maxHourlyRateCents + 1, 4611686018427387904]) {
        final data = dataJson();
        list(data, 'shiftTypes').first['hourlyRateCents'] = value;
        expect(
          () => codec.decode(v3File(data)),
          throwsA(isA<CorruptBackup>()),
          reason: 'rate = $value',
        );
      }
      final data = dataJson();
      list(data, 'shiftTypes').first['hourlyRateCents'] = maxHourlyRateCents;
      expect(() => codec.decode(v3File(data)), returnsNormally);
    });

    test('validate() refuses the same values on hand-built data', () {
      BackupData withExtra(int minutes) => BackupData(
        dayEntries: [
          BackupDayEntry(
            date: const CivilDate(2026, 1, 1),
            overtimeMinutes: minutes,
            updatedAt: 0,
          ),
        ],
      );
      expect(withExtra(maxDayExtraMinutes).validate, returnsNormally);
      expect(
        withExtra(maxDayExtraMinutes + 1).validate,
        throwsA(isA<CorruptBackup>()),
      );
    });
  });

  group('alarm sounds from outside the system are dropped, not rejected', () {
    const media = 'content://media/internal/audio/media/42';
    const settings = 'content://settings/system/notification_sound';
    const share = 'content://es.cuadrante.app.flutter.share_provider/x';

    test('isSystemAlarmSound allows media and settings only', () {
      expect(isSystemAlarmSound(media), isTrue);
      expect(isSystemAlarmSound(settings), isTrue);
      expect(isSystemAlarmSound(share), isFalse);
      expect(isSystemAlarmSound('content://media'), isFalse);
      expect(isSystemAlarmSound('content://mediastore/x'), isFalse);
      expect(isSystemAlarmSound('content://media@evil/x'), isFalse);
      expect(isSystemAlarmSound('file:///data/x'), isFalse);
      expect(isSystemAlarmSound('x'), isFalse);
    });

    test(
      'restoring a file with a foreign sound drops only that sound',
      () async {
        final data = dataJson();
        final types = list(data, 'shiftTypes');
        types.firstWhere((t) => t['id'] == 'night')['alarmSound'] = share;
        types.firstWhere((t) => t['id'] == 'morning')['alarmSound'] = settings;
        types.firstWhere((t) => t['id'] == 'split')['alarmSound'] = media;
        final read = codec.decode(v3File(data)).data;
        // The file itself is valid: nothing is rejected.
        expect(read.foreignAlarmSoundCount, 1);

        await repo.restore(read);
        final rows = {
          for (final t in await db.select(db.shiftTypes).get()) t.id: t,
        };
        expect(rows['night']!.alarmSound, isNull);
        expect(rows['morning']!.alarmSound, settings);
        expect(rows['split']!.alarmSound, media);
        // The rest of the backup came through.
        expect(
          (await repo.readAll()).dayEntries,
          buildGoldenBackupDataV3().dayEntries,
        );
      },
    );

    test('sanitized() keeps everything but the foreign sounds', () {
      final data = BackupData.fromJson(
        dataJson()
          ..['shiftTypes'] = [
            for (final t in list(dataJson(), 'shiftTypes'))
              {...t, 'alarmSound': share},
          ],
      );
      final clean = data.sanitized();
      expect(clean.foreignAlarmSoundCount, 0);
      expect(clean.shiftTypes.every((t) => t.alarmSound == null), isTrue);
      expect(clean.dayEntries, data.dayEntries);
      expect(clean.patternRuns, data.patternRuns);
      expect(clean.settings, data.settings);
      expect(identical(clean.sanitized(), clean), isTrue);
    });

    test(
      '"Probar restauración" agrees with the restore on such a file',
      () async {
        final data = dataJson();
        list(data, 'shiftTypes').first['alarmSound'] = share;
        final result = await repo.verifyRestore(
          v3File(data),
          today: const CivilDate(2026, 3, 14),
        );
        expect(result, isA<VerificationPassed>());
      },
    );
  });
}
