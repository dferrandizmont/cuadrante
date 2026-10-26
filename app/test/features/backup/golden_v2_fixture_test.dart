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
import 'golden_dataset_v2.dart';
import 'v2_format.dart';

/// Format back-compat for version 2 (release 0.3.0): `golden_v2.cuadrante`
/// was written once by version 2 of the format and is checked in. Every
/// future build must keep reading it, with the same checksum and the same
/// 730 resolved days **in every calendar**, and restore it exactly.
///
/// To regenerate it (only when the dataset or the format is deliberately
/// versioned; never to make a failing test pass):
/// `flutter test test/features/backup/golden_v2_fixture_test.dart
///  --dart-define=REGENERATE_GOLDEN=true`
const _regenerate = bool.fromEnvironment('REGENERATE_GOLDEN');

const _dir = 'test/fixtures/golden_backup';
final _fixture = File('$_dir/golden_v2.cuadrante');
final _expected = File('$_dir/golden_v2.expected.json');

const _appVersion = '0.3.0';

void main() {
  const codec = BackupCodec();

  if (_regenerate) {
    test('regenerate the golden v2 fixture', () {
      final data = buildGoldenBackupDataV2();
      // The version 2 writer no longer exists: the file is built in its form.
      final bytes = v2File(
        data,
        appVersion: _appVersion,
        exportedAt: '2026-12-01T10:30:00Z',
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
          'schemaVersion': 2,
          'appVersion': _appVersion,
          'exportedAt': '2026-12-01T10:30:00Z',
          'checksum': v2Checksum(data),
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
    test('has what version 2 adds', () {
      final data = buildGoldenBackupDataV2();
      expect(data.calendars, hasLength(3));
      expect(data.calendars.where((c) => c.archived), hasLength(1));
      expect(data.patternRuns.map((r) => r.calendarId).toSet(), {
        'main',
        'cal-pareja',
        'cal-old',
      });
      expect(data.dayEntries.map((e) => e.calendarId).toSet(), {
        'main',
        'cal-pareja',
      });
      expect(
        data.shiftTypes.where((t) => t.hourlyRateCents != null),
        hasLength(3),
      );
      // The same date in two calendars: the key is (calendar, date).
      final byDate = <Object, Set<String>>{};
      for (final e in data.dayEntries) {
        byDate.putIfAbsent(e.date, () => {}).add(e.calendarId);
      }
      expect(byDate.values.any((calendars) => calendars.length == 2), isTrue);
      expect(data.settings['calendars.active'], '"cal-pareja"');
      expect(() => data.validate(), returnsNormally);
    });

    test('is the same on every call', () {
      expect(buildGoldenBackupDataV2(), buildGoldenBackupDataV2());
    });
  });

  group('golden_v2.cuadrante', () {
    test('is read by this build and matches its recorded checksum', () {
      final file = codec.decode(bytes);
      expect(file.schemaVersion, 2);
      expect(file.appVersion, expected['appVersion']);
      expect(file.exportedAt, goldenV2ExportedAt);
      expect(file.checksum, expected['checksum']);
      expect(BackupCodec.checksumOf(file.data), expected['checksum']);
    });

    test('holds the dataset the generator builds', () {
      expect(codec.decode(bytes).data, buildGoldenBackupDataV2());
    });

    test('keeps the same canonical bytes', () {
      // Rewritten in the form version 2 had: the version 3 writer would say
      // `schemaVersion: 3`, but the data is byte for byte the same.
      expect(
        Uint8List.fromList(gzip.decode(bytes)),
        v2JsonBytes(
          buildGoldenBackupDataV2(),
          appVersion: _appVersion,
          exportedAt: '2026-12-01T10:30:00Z',
        ),
      );
    });

    test('the version 3 writer gives the same data JSON (nothing is added '
        'for data that never used the new fields)', () {
      final data = buildGoldenBackupDataV2();
      expect(data.toJson(), v2DataJson(data));
      expect(BackupCodec.checksumOf(data), expected['checksum']);
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
      expect(fingerprint.calendarIds, hasLength(3));
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
      final dir = makeTempDir('golden-v2');
      final db = openMemoryDatabase();
      addTearDown(db.close);
      final repository = makeRepository(db, dir);

      await repository.restore(codec.decode(bytes).data);

      final restored = await repository.readAll();
      expect(restored, buildGoldenBackupDataV2());
      final recorded = expected['fingerprint']! as Map<String, Object?>;
      expect(
        scheduleFingerprint(restored, from: goldenFrom, to: goldenTo).digest,
        recorded['digest'],
      );

      final reference = openMemoryDatabase();
      addTearDown(reference.close);
      await seedDatabase(reference, buildGoldenBackupDataV2());
      expect(await dumpAllTables(db), await dumpAllTables(reference));
    });
  });
}
