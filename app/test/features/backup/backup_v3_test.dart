import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/backup/application/backup_service.dart';
import 'package:cuadrante/features/backup/data/backup_repository.dart';
import 'package:cuadrante/features/backup/data/local_file_backup_store.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:cuadrante/features/backup/domain/backup_errors.dart';
import 'package:cuadrante/features/backup/domain/restore_summary.dart';
import 'package:cuadrante/features/backup/domain/schedule_fingerprint.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'backup_test_support.dart';
import 'golden_dataset.dart';
import 'golden_dataset_v2.dart';
import 'golden_dataset_v3.dart';
import 'v2_format.dart';

/// Format version 3 end to end (docs/copia-de-seguridad.md): icon, alarm
/// sound and second segment of shift types; note reminder, overtime and early
/// leave of days; and the version 2 files that must keep restoring.
void main() {
  const codec = BackupCodec();
  late AppDatabase db;
  late Directory dir;
  late BackupRepository repo;

  setUp(() {
    db = openMemoryDatabase();
    addTearDown(db.close);
    dir = makeTempDir('backup-v3');
    repo = makeRepository(db, Directory(p.join(dir.path, 'safety')));
  });

  BackupData v3() => buildGoldenBackupDataV3();

  ScheduleFingerprint fingerprint(BackupData data) =>
      scheduleFingerprint(data, from: goldenFrom, to: goldenTo);

  BackupService serviceFor(BackupRepository repository, String store) =>
      BackupService(
        repository: repository,
        store: LocalFileBackupStore(Directory(p.join(dir.path, store))),
        appVersion: testAppVersion,
        now: () => DateTime.utc(2027, 1, 20, 8, 15),
      );

  /// [data] with the day [date] of calendar [calendarId] replaced by [change].
  BackupData withDay(
    BackupData data,
    CivilDate date,
    BackupDayEntry Function(BackupDayEntry) change, {
    String calendarId = 'main',
  }) => BackupData(
    calendars: data.calendars,
    shiftTypes: data.shiftTypes,
    patterns: data.patterns,
    patternRuns: data.patternRuns,
    dayEntries: [
      for (final e in data.dayEntries)
        if (e.calendarId == calendarId && e.date == date) change(e) else e,
    ],
    holidays: data.holidays,
    absenceBalances: data.absenceBalances,
    settings: data.settings,
  );

  BackupDayEntry copyEntry(
    BackupDayEntry e, {
    int? noteReminderMinute,
    int? overtimeMinutes,
    int? earlyLeaveMinutes,
  }) => BackupDayEntry(
    calendarId: e.calendarId,
    date: e.date,
    shiftTypeIds: e.shiftTypeIds,
    note: e.note,
    noteReminderMinute: noteReminderMinute ?? e.noteReminderMinute,
    overtimeMinutes: overtimeMinutes ?? e.overtimeMinutes,
    earlyLeaveMinutes: earlyLeaveMinutes ?? e.earlyLeaveMinutes,
    updatedAt: e.updatedAt,
  );

  group('the format', () {
    test('the writer says version 3 and keeps the v2 envelope', () {
      final bytes = codec.encode(
        v3(),
        appVersion: '0.6.0',
        exportedAt: goldenV3ExportedAt,
      );
      final env = readEnvelope(bytes);
      expect(env['schemaVersion'], 3);
      expect(env.keys.toSet(), {
        'format',
        'schemaVersion',
        'appVersion',
        'exportedAt',
        'data',
        'checksum',
      });
      expect(env['checksum'], BackupCodec.checksumOf(v3()));
      expect((env['data']! as Map<String, Object?>).keys.toSet(), {
        'calendars',
        'shiftTypes',
        'patterns',
        'patternRuns',
        'dayEntries',
        'holidays',
        'absenceBalances',
        'settings',
      });
    });

    test('the new fields are written under their names, and only when set', () {
      final env = readEnvelope(
        codec.encode(v3(), appVersion: 'x', exportedAt: goldenV3ExportedAt),
      );
      final data = env['data']! as Map<String, Object?>;
      final types = (data['shiftTypes']! as List).cast<Map<String, Object?>>();
      final split = types.singleWhere((t) => t['id'] == 'split');
      expect(split['icon'], 'coffee');
      expect(split['segment2StartMinute'], 960);
      expect(split['segment2DurationMinutes'], 240);
      expect(split.containsKey('alarmSound'), isFalse);
      final night = types.singleWhere((t) => t['id'] == 'night');
      expect(night['icon'], 'moon');
      expect(night['alarmSound'], 'content://media/internal/audio/media/42');
      // A type that uses none of them looks like it did in version 2.
      final afternoon = types.singleWhere((t) => t['id'] == 'afternoon');
      for (final key in [
        'icon',
        'alarmSound',
        'segment2StartMinute',
        'segment2DurationMinutes',
      ]) {
        expect(afternoon.containsKey(key), isFalse, reason: key);
      }

      final days = (data['dayEntries']! as List).cast<Map<String, Object?>>();
      final all = days.singleWhere((d) => d['date'] == '2026-03-14');
      expect(all['noteReminderMinute'], 23 * 60 + 59);
      expect(all['overtimeMinutes'], 30);
      expect(all['earlyLeaveMinutes'], 15);
      final plain = days.firstWhere((d) => d['date'] == '2026-01-18');
      expect(plain.keys, isNot(contains('overtimeMinutes')));
    });

    test('the canonical bytes do not depend on the order of the input', () {
      final shuffled = BackupData(
        calendars: v3().calendars.reversed,
        shiftTypes: v3().shiftTypes.reversed,
        patterns: v3().patterns,
        patternRuns: v3().patternRuns.reversed,
        dayEntries: v3().dayEntries.reversed,
        holidays: v3().holidays,
        absenceBalances: v3().absenceBalances,
        settings: v3().settings,
      );
      expect(
        codec.encodeJsonBytes(
          shuffled,
          appVersion: 'x',
          exportedAt: goldenV3ExportedAt,
        ),
        codec.encodeJsonBytes(
          v3(),
          appVersion: 'x',
          exportedAt: goldenV3ExportedAt,
        ),
      );
    });

    test('the reader and writer share size and inflation caps', () {
      expect(BackupCodec.maxFileBytes, 8 * 1024 * 1024);
      expect(BackupCodec.defaultMaxDecodedBytes, 32 * 1024 * 1024);
      expect(BackupCodec.maxInflateRatio, 100);
      expect(BackupCodec.inflateRatioFloorBytes, 64 * 1024);
    });

    test('data that never used the new fields has the JSON, the checksum and '
        'the fingerprint it had in version 2', () {
      final data = buildGoldenBackupDataV2();
      expect(data.toJson(), v2DataJson(data));
      expect(BackupCodec.checksumOf(data), v2Checksum(data));
    });

    test('encode then decode gives the same data', () {
      final file = codec.decode(
        codec.encode(v3(), appVersion: 'x', exportedAt: goldenV3ExportedAt),
      );
      expect(file.schemaVersion, 3);
      expect(file.data, v3());
      final split = file.data.shiftTypes
          .singleWhere((t) => t.id == 'split')
          .toShiftType();
      expect(split.icon, ShiftIcon.coffee);
      expect(split.segment2StartMinute, 960);
      expect(split.segment2Problem, isNull);
      final day = file.data.toSchedule().entries[const CivilDate(2026, 3, 14)]!;
      expect(day.noteReminderMinute, 1439);
      expect(day.overtimeMinutes, 30);
      expect(day.earlyLeaveMinutes, 15);
    });
  });

  group('reading', () {
    Map<String, Object?> dataJson(BackupData data) =>
        jsonDecode(jsonEncode(data.toJson())) as Map<String, Object?>;

    Uint8List file(int version, Map<String, Object?> data) => gzipEnvelope({
      'format': 'cuadrante',
      'schemaVersion': version,
      'appVersion': 'x',
      'exportedAt': '2027-01-20T08:15:00Z',
      'data': data,
      'checksum': BackupCodec.checksumOfJson(data),
    });

    test('a version 3 file without the new keys reads them as none', () {
      final data = dataJson(v3());
      for (final t
          in (data['shiftTypes']! as List).cast<Map<String, Object?>>()) {
        for (final k in [
          'icon',
          'alarmSound',
          'segment2StartMinute',
          'segment2DurationMinutes',
        ]) {
          t.remove(k);
        }
      }
      for (final e
          in (data['dayEntries']! as List).cast<Map<String, Object?>>()) {
        for (final k in [
          'noteReminderMinute',
          'overtimeMinutes',
          'earlyLeaveMinutes',
        ]) {
          e.remove(k);
        }
      }
      final read = codec.decode(file(3, data)).data;
      expect(read.shiftTypes.every((t) => t.icon == null), isTrue);
      expect(
        read.shiftTypes.every((t) => t.segment2StartMinute == null),
        isTrue,
      );
      expect(read.dayEntries.every((e) => e.overtimeMinutes == null), isTrue);
    });

    test('explicit nulls read the same as absent keys', () {
      final data = dataJson(v3());
      for (final e
          in (data['dayEntries']! as List).cast<Map<String, Object?>>()) {
        e['overtimeMinutes'] = null;
      }
      final read = codec.decode(file(3, data)).data;
      expect(read.dayEntries.every((e) => e.overtimeMinutes == null), isTrue);
    });

    test('an icon key this build does not know is no icon, not an error', () {
      final data = dataJson(v3());
      final types = (data['shiftTypes']! as List).cast<Map<String, Object?>>();
      types.firstWhere((t) => t['id'] == 'night')['icon'] = 'rocket';
      types.firstWhere((t) => t['id'] == 'morning')['icon'] = '☀️';
      final read = codec.decode(file(3, data)).data;
      expect(read.shiftTypes.singleWhere((t) => t.id == 'night').icon, isNull);
      expect(
        read.shiftTypes.singleWhere((t) => t.id == 'morning').icon,
        isNull,
      );
      expect(
        read.shiftTypes.singleWhere((t) => t.id == 'split').icon,
        ShiftIcon.coffee,
      );
    });

    test(
      'a version 2 file that somehow carries version 3 keys ignores them',
      () {
        // The checksum covers the file as written, so it is valid; the v2
        // reader simply does not define those fields.
        final read = codec.decode(file(2, dataJson(v3())));
        expect(read.schemaVersion, 2);
        expect(read.data.shiftTypes.every((t) => t.icon == null), isTrue);
        expect(read.data.shiftTypes.every((t) => t.alarmSound == null), isTrue);
        expect(
          read.data.shiftTypes.every((t) => t.segment2StartMinute == null),
          isTrue,
        );
        expect(
          read.data.dayEntries.every(
            (e) =>
                e.noteReminderMinute == null &&
                e.overtimeMinutes == null &&
                e.earlyLeaveMinutes == null,
          ),
          isTrue,
        );
      },
    );

    test('the version 2 golden file reads as before, with the new fields '
        'empty', () {
      final bytes = File('test/fixtures/golden_backup/golden_v2.cuadrante')
          .readAsBytesSync();
      final read = codec.decode(bytes);
      expect(read.schemaVersion, 2);
      expect(read.data, buildGoldenBackupDataV2());
    });

    test('a version 2 file restores into a version 3 database: the new '
        'columns are empty', () async {
      final bytes = v2File(buildGoldenBackupDataV2());
      await repo.restore(codec.decode(bytes).data);
      final types = await db.select(db.shiftTypes).get();
      expect(
        types.every((t) => t.icon == null && t.alarmSound == null),
        isTrue,
      );
      expect(types.every((t) => t.segment2StartMinute == null), isTrue);
      final days = await db.select(db.dayEntries).get();
      expect(
        days.every(
          (d) =>
              d.noteReminderMinute == null &&
              d.overtimeMinutes == null &&
              d.earlyLeaveMinutes == null,
        ),
        isTrue,
      );
      expect(await repo.readAll(), buildGoldenBackupDataV2());
    });

    test('restoring a version 2 file over annotated data clears them: the '
        'file is the truth', () async {
      await repo.restore(v3());
      expect(
        (await repo.readAll()).dayEntries.any((e) => e.overtimeMinutes != null),
        isTrue,
      );
      await repo.restore(codec.decode(v2File(buildGoldenBackupDataV2())).data);
      final after = await repo.readAll();
      expect(after.dayEntries.any((e) => e.overtimeMinutes != null), isFalse);
      expect(after.shiftTypes.any((t) => t.icon != null), isFalse);
    });
  });

  group('integrity (BackupData.validate)', () {
    BackupShiftType type({
      int? start = 480,
      int? end = 720,
      String? alarmSound,
      int? seg2Start,
      int? seg2Duration,
    }) => BackupShiftType(
      id: 't',
      code: 'P',
      name: 'Partido',
      colorValue: 1,
      category: ShiftCategory.work,
      startMinute: start,
      endMinute: end,
      alarmSound: alarmSound,
      segment2StartMinute: seg2Start,
      segment2DurationMinutes: seg2Duration,
      sortOrder: 0,
      createdAt: 0,
      updatedAt: 0,
    );

    BackupData withType(BackupShiftType t) => BackupData(
      shiftTypes: [t],
      patterns: [
        const BackupPattern(
          id: 'p',
          name: 'P',
          steps: [
            ['t'],
          ],
          createdAt: 0,
          updatedAt: 0,
        ),
      ],
    );

    BackupData withDayEntry(BackupDayEntry e) => BackupData(dayEntries: [e]);

    void rejects(BackupData data) =>
        expect(data.validate, throwsA(isA<CorruptBackup>()));

    test('a valid split shift and valid days pass', () {
      expect(
        withType(type(seg2Start: 960, seg2Duration: 240)).validate,
        returnsNormally,
      );
      expect(
        withDayEntry(
          BackupDayEntry(
            date: const CivilDate(2026, 1, 1),
            noteReminderMinute: 1439,
            overtimeMinutes: 0,
            earlyLeaveMinutes: 600,
            updatedAt: 0,
          ),
        ).validate,
        returnsNormally,
      );
    });

    test('a second segment must be complete, in range, after the first and '
        'inside 24 h', () {
      rejects(withType(type(seg2Start: 960)));
      rejects(withType(type(seg2Duration: 60)));
      rejects(withType(type(seg2Start: 1440, seg2Duration: 60)));
      rejects(withType(type(seg2Start: -1, seg2Duration: 60)));
      rejects(withType(type(seg2Start: 960, seg2Duration: 0)));
      rejects(withType(type(seg2Start: 960, seg2Duration: 1441)));
      rejects(withType(type(seg2Start: 720, seg2Duration: 60)));
      rejects(withType(type(seg2Start: 7 * 60, seg2Duration: 4 * 60)));
      rejects(
        withType(
          type(start: null, end: null, seg2Start: 960, seg2Duration: 60),
        ),
      );
    });

    test('an alarm sound is never empty nor absurdly long', () {
      rejects(withType(type(alarmSound: '')));
      rejects(withType(type(alarmSound: 'x' * (maxAlarmSoundLength + 1))));
      expect(
        withType(type(alarmSound: 'x' * maxAlarmSoundLength)).validate,
        returnsNormally,
      );
    });

    test('a reminder is a minute of the day; minutes are not negative', () {
      BackupDayEntry day({int? r, int? o, int? e}) => BackupDayEntry(
        date: const CivilDate(2026, 1, 1),
        noteReminderMinute: r,
        overtimeMinutes: o,
        earlyLeaveMinutes: e,
        updatedAt: 0,
      );
      rejects(withDayEntry(day(r: 1440)));
      rejects(withDayEntry(day(r: -1)));
      rejects(withDayEntry(day(o: -1)));
      rejects(withDayEntry(day(e: -1)));
    });

    test('a damaged file is a CorruptBackup, and the writer refuses it', () {
      final bad = withType(type(seg2Start: 720, seg2Duration: 60));
      expect(
        () =>
            codec.encode(bad, appVersion: 'x', exportedAt: goldenV3ExportedAt),
        throwsA(isA<CorruptBackup>()),
      );
      final data =
          jsonDecode(jsonEncode(v3().toJson())) as Map<String, Object?>;
      final days = (data['dayEntries']! as List).cast<Map<String, Object?>>();
      days.first['noteReminderMinute'] = 5000;
      expect(
        () => codec.decode(
          gzipEnvelope({
            'format': 'cuadrante',
            'schemaVersion': 3,
            'appVersion': 'x',
            'exportedAt': '2027-01-20T08:15:00Z',
            'data': data,
            'checksum': BackupCodec.checksumOfJson(data),
          }),
        ),
        throwsA(isA<CorruptBackup>()),
      );
    });

    test('wrong types are a CorruptBackup', () {
      final data =
          jsonDecode(jsonEncode(v3().toJson())) as Map<String, Object?>;
      (data['shiftTypes']! as List).cast<Map<String, Object?>>().first['icon'] =
          7;
      expect(
        () => codec.decode(
          gzipEnvelope({
            'format': 'cuadrante',
            'schemaVersion': 3,
            'appVersion': 'x',
            'exportedAt': '2027-01-20T08:15:00Z',
            'data': data,
            'checksum': BackupCodec.checksumOfJson(data),
          }),
        ),
        throwsA(isA<CorruptBackup>()),
      );
    });
  });

  group('round trip through the database', () {
    test('database -> file -> database keeps every new field', () async {
      await seedDatabase(db, v3());
      final bytes = await serviceFor(repo, 'store').exportBytes();
      expect(readEnvelope(bytes)['schemaVersion'], 3);

      final other = openMemoryDatabase();
      addTearDown(other.close);
      final otherRepo = makeRepository(
        other,
        Directory(p.join(dir.path, 'safety-other')),
      );
      await otherRepo.restore(codec.decode(bytes).data);

      expect(await otherRepo.readAll(), v3());
      expect(await dumpAllTables(other), await dumpAllTables(db));
      expect(
        fingerprint(await otherRepo.readAll()),
        fingerprint(await repo.readAll()),
      );
      // Re-exporting what was restored gives the same data again.
      expect(
        codec.decode(await serviceFor(otherRepo, 'store2').exportBytes()).data,
        v3(),
      );
    });

    test('the stored columns hold the new values', () async {
      await repo.restore(v3());
      final night = await (db.select(
        db.shiftTypes,
      )..where((t) => t.id.equals('night'))).getSingle();
      expect(night.icon, 'moon');
      expect(night.alarmSound, 'content://media/internal/audio/media/42');
      final split = await (db.select(
        db.shiftTypes,
      )..where((t) => t.id.equals('split'))).getSingle();
      expect(
        (split.segment2StartMinute, split.segment2DurationMinutes),
        (960, 240),
      );
      final day =
          await (db.select(db.dayEntries)
                ..where((d) => d.calendarId.equals('main'))
                ..where(
                  (d) => d.date.equalsValue(const CivilDate(2026, 3, 14)),
                ))
              .getSingle();
      expect(
        (day.noteReminderMinute, day.overtimeMinutes, day.earlyLeaveMinutes),
        (1439, 30, 15),
      );
    });

    test(
      'the safety copy taken before a restore holds the new fields',
      () async {
        await seedDatabase(db, v3());
        final before = await repo.readAll();
        await repo.restore(buildGoldenBackupData());

        final safety = Directory(p.join(dir.path, 'safety'));
        final copy = safety.listSync().whereType<File>().single;
        final decoded = codec.decode(copy.readAsBytesSync());
        expect(decoded.schemaVersion, 3);
        expect(decoded.data, before);
        expect(
          decoded.data.dayEntries.where((e) => e.overtimeMinutes != null),
          isNotEmpty,
        );
      },
    );

    test('restoring twice gives the same database', () async {
      await repo.restore(v3());
      final once = await dumpAllTables(db);
      await repo.restore(v3());
      expect(await dumpAllTables(db), once);
    });

    test('the preview counts the new data like the old', () async {
      final summary = await repo.preview(v3());
      expect(summary.incoming.shiftTypes, 11);
      expect(summary.incoming.dayEntries, 59);
    });
  });

  group('"Probar restauración" covers the new fields', () {
    test(
      'passes on data with every new field and matches what is stored',
      () async {
        await repo.restore(v3());
        final bytes = codec.encode(
          await repo.readAll(),
          appVersion: testAppVersion,
          exportedAt: goldenV3ExportedAt,
        );
        final verdict = await repo.verifyRestore(
          bytes,
          today: goldenFrom.addDays(365),
        );
        expect(verdict, isA<VerificationPassed>());
        expect((verdict as VerificationPassed).matchesLive, isTrue);
        expect(verdict.fingerprint.calendarIds, [
          'cal-old',
          'cal-pareja',
          'main',
        ]);
      },
    );

    test('a copy older than the live data is told apart by a changed '
        'overtime, on the right day', () async {
      await repo.restore(v3());
      final older = withDay(
        v3(),
        const CivilDate(2026, 3, 12),
        (e) => copyEntry(e, overtimeMinutes: 91),
      );
      final verdict = await repo.verifyRestore(
        codec.encode(
          older,
          appVersion: testAppVersion,
          exportedAt: goldenV3ExportedAt,
        ),
        today: goldenFrom.addDays(365),
      );
      expect(verdict, isA<VerificationPassed>());
      final passed = verdict as VerificationPassed;
      expect(passed.matchesLive, isFalse);
      expect(passed.firstDayDifferingFromLive, const CivilDate(2026, 3, 12));
    });

    group('a faulty rebuild that loses a new field is caught', () {
      Future<RestoreVerification> verifyWithTrigger(String sql) async {
        await seedDatabase(db, v3());
        final bytes = codec.encode(
          await repo.readAll(),
          appVersion: testAppVersion,
          exportedAt: goldenV3ExportedAt,
        );
        final faulty = makeRepository(
          db,
          Directory(p.join(dir.path, 'safety-faulty')),
          openScratchDatabase: () {
            final scratch = openMemoryDatabase();
            scratch.customStatement(sql);
            return scratch;
          },
        );
        return faulty.verifyRestore(bytes, today: goldenFrom.addDays(365));
      }

      test('overtime', () async {
        final result = await verifyWithTrigger(
          'CREATE TRIGGER lose AFTER INSERT ON day_entries '
          "WHEN NEW.date = '2026-03-12' AND NEW.calendar_id = 'main' "
          'BEGIN UPDATE day_entries SET overtime_minutes = NULL '
          'WHERE date = NEW.date AND calendar_id = NEW.calendar_id; END',
        );
        expect(result, isA<VerificationMismatch>());
        expect(
          (result as VerificationMismatch).firstDifferingDay,
          const CivilDate(2026, 3, 12),
        );
      });

      test('the reminder of a day that has nothing else', () async {
        final result = await verifyWithTrigger(
          'CREATE TRIGGER lose AFTER INSERT ON day_entries '
          "WHEN NEW.date = '2026-03-11' AND NEW.calendar_id = 'main' "
          'BEGIN UPDATE day_entries SET note_reminder_minute = 0 '
          'WHERE date = NEW.date AND calendar_id = NEW.calendar_id; END',
        );
        expect(
          (result as VerificationMismatch).firstDifferingDay,
          const CivilDate(2026, 3, 11),
        );
      });

      test('the second segment of a shift type', () async {
        final result = await verifyWithTrigger(
          'CREATE TRIGGER lose AFTER INSERT ON shift_types '
          "WHEN NEW.id = 'split' BEGIN UPDATE shift_types SET "
          'segment2_start_minute = NULL, segment2_duration_minutes = NULL '
          'WHERE id = NEW.id; END',
        );
        expect(result, isA<VerificationMismatch>());
        expect((result as VerificationMismatch).firstDifferingDay, isNull);
      });

      test('the icon', () async {
        final result = await verifyWithTrigger(
          'CREATE TRIGGER lose AFTER INSERT ON shift_types '
          "WHEN NEW.id = 'night' BEGIN UPDATE shift_types SET icon = NULL "
          'WHERE id = NEW.id; END',
        );
        expect(result, isA<VerificationMismatch>());
      });
    });

    test('the fingerprint changes with any new field of any day, and names '
        'the day', () {
      final base = fingerprint(v3());
      const day = CivilDate(2026, 3, 12);
      final changes = <String, BackupData>{
        'overtime': withDay(
          v3(),
          day,
          (e) => copyEntry(e, overtimeMinutes: 91),
        ),
        'early leave': withDay(
          v3(),
          day,
          (e) => copyEntry(e, earlyLeaveMinutes: 1),
        ),
        'reminder': withDay(
          v3(),
          const CivilDate(2026, 3, 11),
          (e) => copyEntry(e, noteReminderMinute: 7 * 60 + 1),
        ),
        'the same date in another calendar': withDay(
          v3(),
          day,
          (e) => copyEntry(e, overtimeMinutes: 16),
          calendarId: 'cal-pareja',
        ),
      };
      for (final MapEntry(key: what, value: data) in changes.entries) {
        final other = fingerprint(data);
        expect(other.digest, isNot(base.digest), reason: what);
        expect(base.firstDayDifferingFrom(other), isNotNull, reason: what);
      }
      expect(
        base.firstDayDifferingFrom(fingerprint(changes['overtime']!)),
        day,
      );
      expect(
        base.firstDayDifferingFrom(fingerprint(changes['reminder']!)),
        const CivilDate(2026, 3, 11),
      );
    });

    test(
      'a changed icon, sound or segment changes the digest (stored data)',
      () {
        final base = fingerprint(v3());
        BackupData retyped(BackupShiftType Function(BackupShiftType) change) =>
            BackupData(
              calendars: v3().calendars,
              shiftTypes: [
                for (final t in v3().shiftTypes)
                  if (t.id == 'split') change(t) else t,
              ],
              patterns: v3().patterns,
              patternRuns: v3().patternRuns,
              dayEntries: v3().dayEntries,
              holidays: v3().holidays,
              absenceBalances: v3().absenceBalances,
              settings: v3().settings,
            );
        BackupShiftType copy(
          BackupShiftType t, {
          ShiftIcon? icon,
          String? alarmSound,
          int? seg2Start,
        }) => BackupShiftType(
          id: t.id,
          code: t.code,
          name: t.name,
          colorValue: t.colorValue,
          category: t.category,
          startMinute: t.startMinute,
          endMinute: t.endMinute,
          icon: icon ?? t.icon,
          alarmSound: alarmSound ?? t.alarmSound,
          segment2StartMinute: seg2Start ?? t.segment2StartMinute,
          segment2DurationMinutes: t.segment2DurationMinutes,
          sortOrder: t.sortOrder,
          createdAt: t.createdAt,
          updatedAt: t.updatedAt,
        );
        for (final data in [
          retyped((t) => copy(t, icon: ShiftIcon.bed)),
          retyped((t) => copy(t, alarmSound: 'x')),
          retyped((t) => copy(t, seg2Start: 17 * 60)),
        ]) {
          expect(fingerprint(data).digest, isNot(base.digest));
          expect(fingerprint(data).entitiesDigest, isNot(base.entitiesDigest));
        }
      },
    );
  });
}
