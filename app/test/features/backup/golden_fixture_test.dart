import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/restore_summary.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backup_test_support.dart';
import 'golden_dataset.dart';
import 'v1_format.dart';

/// Format back-compat: `golden_v1.cuadrante` was written once by version 1 of
/// the format (releases 0.1 and 0.2) and is checked in. **It is never
/// regenerated**: every future build must keep reading it, with the same
/// checksum and the same 730 resolved days, and must restore it exactly.
/// Since version 2 the codec reads it into the version 2 model (everything in
/// the calendar `main`); `v1_format.dart` writes the version 1 shape again so
/// the checksum, the canonical bytes and the fingerprint digest recorded in
/// `golden_v1.expected.json` keep being checked as they were recorded.
///
/// `golden_v2_fixture_test.dart` holds the version 2 counterpart.
const _dir = 'test/fixtures/golden_backup';
final _fixture = File('$_dir/golden_v1.cuadrante');
final _expected = File('$_dir/golden_v1.expected.json');

void main() {
  const codec = BackupCodec();

  late Uint8List bytes;
  late Map<String, Object?> expected;

  setUpAll(() {
    bytes = _fixture.readAsBytesSync();
    expected = jsonDecode(_expected.readAsStringSync()) as Map<String, Object?>;
  });

  group('the dataset', () {
    test('has what the restore matrix asks for', () {
      final data = buildGoldenBackupData();
      expect(goldenTo.differenceInDays(goldenFrom) + 1, 730);
      expect(data.patternRuns, hasLength(3));
      expect(
        data.patternRuns.where((r) => r.endDate != null),
        isNotEmpty,
        reason: 'a cut rotation',
      );
      expect(data.dayEntries, hasLength(40));
      expect(
        data.dayEntries.where((e) => (e.shiftTypeIds?.length ?? 0) >= 2),
        isNotEmpty,
        reason: 'a day with two shifts',
      );
      expect(
        data.shiftTypes.where((t) => t.toShiftType().crossesMidnight),
        isNotEmpty,
        reason: 'a shift that crosses midnight',
      );
      expect(
        data.shiftTypes.where((t) => t.id.startsWith('custom-')).length,
        greaterThan(2),
      );
      expect(data.shiftTypes.where((t) => t.archived), isNotEmpty);
      expect(
        data.dayEntries.where(
          (e) =>
              (e.note ?? '').length > 200 &&
              e.note!.contains('🙏') &&
              e.note!.contains('\n'),
        ),
        isNotEmpty,
      );
      expect(data.settings['holidays.municipality'], isNotNull);
      expect(data.holidays, hasLength(1));
      expect(() => data.validate(), returnsNormally);
    });

    test('is the same on every call', () {
      expect(buildGoldenBackupData(), buildGoldenBackupData());
    });

    test('is a version 1 dataset: one calendar, no rates', () {
      final data = buildGoldenBackupData();
      expect(data.calendars.map((c) => c.id), ['main']);
      expect(data.shiftTypes.every((t) => t.hourlyRateCents == null), isTrue);
    });
  });

  group('golden_v1.cuadrante', () {
    test('is read by this build and matches its recorded checksum', () {
      final file = codec.decode(bytes);
      expect(file.schemaVersion, 1);
      expect(file.appVersion, expected['appVersion']);
      expect(file.exportedAt, goldenExportedAt);
      // The file as written by version 1 ...
      expect(file.checksum, expected['checksum']);
      // ... and the data it gives, written back the version 1 way.
      expect(v1Checksum(file.data), expected['checksum']);
    });

    test('holds the dataset the generator builds', () {
      expect(codec.decode(bytes).data, buildGoldenBackupData());
    });

    test('everything lands in the calendar main', () {
      final data = codec.decode(bytes).data;
      expect(data.calendars.map((c) => c.id), ['main']);
      expect(data.calendars.single.name, 'Mi cuadrante');
      expect(data.patternRuns.map((r) => r.calendarId).toSet(), {'main'});
      expect(data.dayEntries.map((e) => e.calendarId).toSet(), {'main'});
      expect(data.shiftTypes.every((t) => t.hourlyRateCents == null), isTrue);
    });

    test('keeps the same canonical bytes', () {
      // The inflated file is exactly what version 1 wrote for the dataset:
      // the canonical form of the data has not drifted.
      expect(
        gzipDecode(bytes),
        v1JsonBytes(
          buildGoldenBackupData(),
          appVersion: goldenAppVersion,
          exportedAt: expected['exportedAt']! as String,
        ),
      );
    });

    test('resolves to the same 730 days', () {
      final fingerprintJson = expected['fingerprint']! as Map<String, Object?>;
      final from = CivilDate.parse(fingerprintJson['from']! as String);
      final to = CivilDate.parse(fingerprintJson['to']! as String);
      final data = codec.decode(bytes).data;
      expect(to.differenceInDays(from) + 1, 730);
      expect(
        v1FingerprintDigest(data, from: from, to: to),
        fingerprintJson['digest'],
      );
    });

    test('counts are as recorded', () {
      final counts = BackupCounts.of(codec.decode(bytes).data);
      final recorded = expected['counts']! as Map<String, Object?>;
      expect(counts.shiftTypes, recorded['shiftTypes']);
      expect(counts.patterns, recorded['patterns']);
      expect(counts.patternRuns, recorded['patternRuns']);
      expect(counts.dayEntries, recorded['dayEntries']);
      expect(counts.holidays, recorded['holidays']);
      expect(counts.absenceBalances, recorded['absenceBalances']);
      expect(counts.settings, recorded['settings']);
      expect(counts.calendars, 1);
    });

    test('restores exactly (R4): same fingerprint, same tables', () async {
      final dir = makeTempDir('golden');
      final db = openMemoryDatabase();
      addTearDown(db.close);
      final repository = makeRepository(db, dir);

      await repository.restore(codec.decode(bytes).data);

      final restored = await repository.readAll();
      expect(restored, buildGoldenBackupData());
      final fingerprintJson = expected['fingerprint']! as Map<String, Object?>;
      expect(
        v1FingerprintDigest(restored, from: goldenFrom, to: goldenTo),
        fingerprintJson['digest'],
      );

      final reference = openMemoryDatabase();
      addTearDown(reference.close);
      await seedDatabase(reference, buildGoldenBackupData());
      expect(await dumpAllTables(db), await dumpAllTables(reference));
    });

    test('restoring it twice gives the same database', () async {
      final dir = makeTempDir('golden-twice');
      final db = openMemoryDatabase();
      addTearDown(db.close);
      final repository = makeRepository(db, dir);
      final data = codec.decode(bytes).data;

      await repository.restore(data);
      final once = await dumpAllTables(db);
      await repository.restore(data);

      expect(await dumpAllTables(db), once);
    });
  });
}

Uint8List gzipDecode(Uint8List bytes) => Uint8List.fromList(gzip.decode(bytes));
