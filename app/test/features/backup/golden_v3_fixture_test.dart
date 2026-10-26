import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/restore_summary.dart';
import 'package:cuadrante/features/backup/domain/schedule_fingerprint.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backup_test_support.dart';
import 'golden_dataset.dart';
import 'golden_dataset_v3.dart';

/// Format back-compat for version 3 (release 0.6.0): `golden_v3.cuadrante`
/// was written once by version 3 of the format and is checked in. Every
/// future build must keep reading it, with the same checksum and the same
/// 730 resolved days **in every calendar**, and restore it exactly.
///
/// To regenerate it (only when the dataset or the format is deliberately
/// versioned; never to make a failing test pass):
/// `flutter test test/features/backup/golden_v3_fixture_test.dart
///  --dart-define=REGENERATE_GOLDEN=true`
const _regenerate = bool.fromEnvironment('REGENERATE_GOLDEN');

const _dir = 'test/fixtures/golden_backup';
final _fixture = File('$_dir/golden_v3.cuadrante');
final _expected = File('$_dir/golden_v3.expected.json');

const _appVersion = '0.6.0';

void main() {
  const codec = BackupCodec();

  if (_regenerate) {
    test('regenerate the golden v3 fixture', () {
      final data = buildGoldenBackupDataV3();
      final bytes = codec.encode(
        data,
        appVersion: _appVersion,
        exportedAt: goldenV3ExportedAt,
      );
      final fingerprint = scheduleFingerprint(
        data,
        from: goldenFrom,
        to: goldenTo,
      );
      _fixture.parent.createSync(recursive: true);
      _fixture.writeAsBytesSync(bytes);
      _expected.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({
          'schemaVersion': 3,
          'appVersion': _appVersion,
          'exportedAt': '2027-01-20T08:15:00Z',
          'checksum': BackupCodec.checksumOf(data),
          'fingerprint': {'from': goldenFrom.toIso(), 'to': goldenTo.toIso(), 'days': fingerprint.dayCount, 'calendars': fingerprint.calendarIds, 'digest': fingerprint.digest},
          'counts': {'calendars': data.calendars.length, 'shiftTypes': data.shiftTypes.length, 'patterns': data.patterns.length, 'patternRuns': data.patternRuns.length, 'dayEntries': data.dayEntries.length, 'holidays': data.holidays.length, 'absenceBalances': data.absenceBalances.length, 'settings': data.settings.length},
        })}\n',
      );
    });
    return;
  }

  late Uint8List bytes;
  late Map<String, Object?> expected;

  setUpAll(() {
    bytes = _fixture.readAsBytesSync();
    expected = jsonDecode(_expected.readAsStringSync()) as Map<String, Object?>;
  });

  group('the dataset', () {
    test('has what version 3 adds', () {
      final data = buildGoldenBackupDataV3();
      expect(data.shiftTypes.where((t) => t.icon != null), hasLength(3));
      expect(data.shiftTypes.where((t) => t.alarmSound != null), hasLength(1));
      final split = data.shiftTypes.singleWhere(
        (t) => t.segment2StartMinute != null,
      );
      expect(split.id, 'split');
      expect(split.toShiftType().segment2Problem, isNull);
      expect(
        data.dayEntries.where((e) => e.noteReminderMinute != null),
        hasLength(4),
      );
      expect(
        data.dayEntries.where((e) => e.overtimeMinutes != null),
        hasLength(3),
      );
      expect(
        data.dayEntries.where((e) => e.earlyLeaveMinutes != null),
        hasLength(3),
      );
      // Days whose only content is one of the new fields.
      expect(
        data.dayEntries.where(
          (e) =>
              e.shiftTypeIds == null &&
              e.note == null &&
              (e.noteReminderMinute != null ||
                  e.overtimeMinutes != null ||
                  e.earlyLeaveMinutes != null),
        ),
        hasLength(4),
      );
      expect(() => data.validate(), returnsNormally);
    });

    test('is the same on every call', () {
      expect(buildGoldenBackupDataV3(), buildGoldenBackupDataV3());
    });
  });

  group('golden_v3.cuadrante', () {
    test('is read by this build and matches its recorded checksum', () {
      final file = codec.decode(bytes);
      expect(file.schemaVersion, 3);
      expect(file.appVersion, expected['appVersion']);
      expect(file.exportedAt, goldenV3ExportedAt);
      expect(file.checksum, expected['checksum']);
      expect(BackupCodec.checksumOf(file.data), expected['checksum']);
    });

    test('holds the dataset the generator builds', () {
      expect(codec.decode(bytes).data, buildGoldenBackupDataV3());
    });

    test('keeps the same canonical bytes', () {
      expect(
        Uint8List.fromList(gzip.decode(bytes)),
        codec.encodeJsonBytes(
          buildGoldenBackupDataV3(),
          appVersion: _appVersion,
          exportedAt: goldenV3ExportedAt,
        ),
      );
    });

    test('resolves to the same 730 days in every calendar', () {
      final recorded = expected['fingerprint']! as Map<String, Object?>;
      final fingerprint = scheduleFingerprint(
        codec.decode(bytes).data,
        from: CivilDate.parse(recorded['from']! as String),
        to: CivilDate.parse(recorded['to']! as String),
      );
      expect(fingerprint.dayCount, 730);
      expect(fingerprint.calendarIds, recorded['calendars']);
      expect(fingerprint.digest, recorded['digest']);
    });

    test('counts are as recorded', () {
      final counts = BackupCounts.of(codec.decode(bytes).data);
      final recorded = expected['counts']! as Map<String, Object?>;
      expect(counts.calendars, recorded['calendars']);
      expect(counts.shiftTypes, recorded['shiftTypes']);
      expect(counts.patterns, recorded['patterns']);
      expect(counts.patternRuns, recorded['patternRuns']);
      expect(counts.dayEntries, recorded['dayEntries']);
      expect(counts.holidays, recorded['holidays']);
      expect(counts.absenceBalances, recorded['absenceBalances']);
      expect(counts.settings, recorded['settings']);
    });

    test('restores exactly: same fingerprint, same tables', () async {
      final dir = makeTempDir('golden-v3');
      final db = openMemoryDatabase();
      addTearDown(db.close);
      final repository = makeRepository(db, dir);

      await repository.restore(codec.decode(bytes).data);

      final restored = await repository.readAll();
      expect(restored, buildGoldenBackupDataV3());
      final recorded = expected['fingerprint']! as Map<String, Object?>;
      expect(
        scheduleFingerprint(restored, from: goldenFrom, to: goldenTo).digest,
        recorded['digest'],
      );

      final reference = openMemoryDatabase();
      addTearDown(reference.close);
      await seedDatabase(reference, buildGoldenBackupDataV3());
      expect(await dumpAllTables(db), await dumpAllTables(reference));
    });
  });
}
