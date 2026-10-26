import 'dart:io';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/backup/application/backup_service.dart';
import 'package:cuadrante/features/backup/data/backup_repository.dart';
import 'package:cuadrante/features/backup/data/local_file_backup_store.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:cuadrante/features/backup/domain/restore_summary.dart';
import 'package:cuadrante/features/backup/domain/schedule_fingerprint.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'backup_test_support.dart';
import 'golden_dataset.dart';
import 'golden_dataset_v2.dart';

/// Format version 2 end to end (docs/copia-de-seguridad.md): calendars,
/// `calendarId` on runs and days, `hourlyRateCents`, and the version 1
/// files that must keep restoring.
void main() {
  const codec = BackupCodec();
  late AppDatabase db;
  late Directory dir;
  late BackupRepository repo;

  setUp(() {
    db = openMemoryDatabase();
    addTearDown(db.close);
    dir = makeTempDir('backup-v2');
    repo = makeRepository(db, Directory(p.join(dir.path, 'safety')));
  });

  ScheduleFingerprint fingerprint(BackupData data) =>
      scheduleFingerprint(data, from: goldenFrom, to: goldenTo);

  BackupData v2() => buildGoldenBackupDataV2();

  group('round trip with several calendars', () {
    test('database -> file -> database, every table, every calendar', () async {
      await seedDatabase(db, v2());
      final service = BackupService(
        repository: repo,
        store: LocalFileBackupStore(Directory(p.join(dir.path, 'store'))),
        appVersion: testAppVersion,
        now: () => DateTime.utc(2026, 12, 1, 10, 30),
      );
      final bytes = await service.exportBytes();
      expect(readEnvelope(bytes)['schemaVersion'], 3);

      final other = openMemoryDatabase();
      addTearDown(other.close);
      final otherRepo = makeRepository(
        other,
        Directory(p.join(dir.path, 'safety-other')),
      );
      await otherRepo.restore(codec.decode(bytes).data);

      expect(await otherRepo.readAll(), v2());
      expect(await dumpAllTables(other), await dumpAllTables(db));
      expect(
        fingerprint(await otherRepo.readAll()),
        fingerprint(await repo.readAll()),
      );
      // Re-exporting what was restored gives the same data again.
      expect(
        codec
            .decode(
              await BackupService(
                repository: otherRepo,
                store: LocalFileBackupStore(
                  Directory(p.join(dir.path, 'store2')),
                ),
                appVersion: testAppVersion,
                now: () => DateTime.utc(2026, 12, 1, 10, 30),
              ).exportBytes(),
            )
            .data,
        v2(),
      );
    });

    test('the archived calendar and the rates come back', () async {
      await repo.restore(v2());
      final data = await repo.readAll();
      final archived = data.calendars.where((c) => c.archived);
      expect(archived.map((c) => c.id), ['cal-old']);
      expect(
        data.patternRuns.where((r) => r.calendarId == 'cal-old'),
        hasLength(1),
      );
      expect(
        {
          for (final t in data.shiftTypes)
            if (t.hourlyRateCents != null) t.id: t.hourlyRateCents,
        },
        {'morning': 1250, 'night': 1575, 'custom-guard24': 2210},
      );
    });

    test('the same date in two calendars survives', () async {
      await repo.restore(v2());
      final data = await repo.readAll();
      final onFirstDay = data.dayEntries.where((e) => e.date == goldenFrom);
      expect(onFirstDay.map((e) => e.calendarId), ['cal-pareja', 'main']);
    });

    test('"Probar restauración" passes and matches what is stored', () async {
      await repo.restore(v2());
      final bytes = codec.encode(
        await repo.readAll(),
        appVersion: testAppVersion,
        exportedAt: goldenV2ExportedAt,
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
    });

    test('the preview counts the calendars', () async {
      final summary = await repo.preview(v2());
      expect(summary.incoming.calendars, 3);
      expect(summary.current.calendars, 1, reason: 'a new database has main');
      expect(summary.incoming.patternRuns, 6);
    });

    test(
      'the safety copy taken before a restore holds every calendar',
      () async {
        await seedDatabase(db, v2());
        final before = await repo.readAll();
        await repo.restore(buildGoldenBackupData());

        final safety = Directory(p.join(dir.path, 'safety'));
        final copy = safety.listSync().whereType<File>().single;
        final decoded = codec.decode(copy.readAsBytesSync());
        expect(decoded.schemaVersion, 3);
        expect(decoded.data, before);
        expect(decoded.data.calendars, hasLength(3));
      },
    );
  });

  group('restoring replaces the calendars too', () {
    test('a version 1 file over a database with several calendars', () async {
      await seedDatabase(db, v2());
      final v1 = File('test/fixtures/golden_backup/golden_v1.cuadrante')
          .readAsBytesSync();

      // Their runs and days go first, then the calendars (foreign keys).
      await repo.restore(codec.decode(v1).data);

      final data = await repo.readAll();
      expect(data, buildGoldenBackupData());
      expect(data.calendars.map((c) => c.id), ['main']);
      expect(data.settings.keys, isNot(contains('calendars.active')));
      expect(data.settings.keys, isNot(contains('calendars.primary')));
      final calendars = CalendarsRepository(db);
      expect(await calendars.activeId(), 'main');
      expect(await calendars.primaryId(), 'main');
    });

    test(
      'a version 2 file whose settings point at a calendar that is gone',
      () async {
        final base = v2();
        final pointing = BackupData(
          calendars: base.calendars,
          shiftTypes: base.shiftTypes,
          patterns: base.patterns,
          patternRuns: base.patternRuns,
          dayEntries: base.dayEntries,
          settings: {
            'calendars.active': '"ghost"',
            'calendars.primary': '"cal-old"', // archived
          },
        );
        await repo.restore(pointing);
        final calendars = CalendarsRepository(db);
        expect(await calendars.activeId(), 'main');
        expect(await calendars.primaryId(), 'main');
      },
    );

    test('restoring twice gives the same database', () async {
      await repo.restore(v2());
      final once = await dumpAllTables(db);
      await repo.restore(v2());
      expect(await dumpAllTables(db), once);
    });

    test('a failed restore keeps every calendar', () async {
      await seedDatabase(db, v2());
      final before = await dumpAllTables(db);
      final base = v2();
      final broken = BackupData(
        calendars: base.calendars,
        shiftTypes: base.shiftTypes,
        patterns: base.patterns,
        patternRuns: [
          ...base.patternRuns,
          BackupPatternRun(
            id: 'orphan',
            calendarId: 'no-such-calendar',
            patternId: base.patterns.first.id,
            startDate: goldenFrom,
            seq: 99,
            createdAt: 1,
          ),
        ],
      );
      await expectLater(repo.restore(broken), throwsA(anything));
      expect(await dumpAllTables(db), before);
    });
  });

  group('the fingerprint covers every calendar', () {
    BackupData withEntries(BackupData base, List<BackupDayEntry> entries) =>
        BackupData(
          calendars: base.calendars,
          shiftTypes: base.shiftTypes,
          patterns: base.patterns,
          patternRuns: base.patternRuns,
          dayEntries: entries,
          holidays: base.holidays,
          absenceBalances: base.absenceBalances,
          settings: base.settings,
        );

    test('a day changed in the second calendar changes it', () {
      final base = v2();
      final pareja = base.dayEntries.firstWhere(
        (e) => e.calendarId == 'cal-pareja' && e.date == goldenFrom.addDays(23),
      );
      final changed = withEntries(base, [
        for (final e in base.dayEntries)
          if (identical(e, pareja))
            BackupDayEntry(
              calendarId: e.calendarId,
              date: e.date,
              shiftTypeIds: const ['vacation'],
              updatedAt: e.updatedAt,
            )
          else
            e,
      ]);

      final a = fingerprint(base);
      final b = fingerprint(changed);
      expect(a, isNot(b));
      expect(a.entitiesDigest, isNot(b.entitiesDigest));
      expect(a.firstDayDifferingFrom(b), pareja.date);
    });

    test('a rotation of the archived calendar counts', () {
      final base = v2();
      final without = BackupData(
        calendars: base.calendars,
        shiftTypes: base.shiftTypes,
        patterns: base.patterns,
        patternRuns: [
          for (final r in base.patternRuns)
            if (r.calendarId != 'cal-old') r,
        ],
        dayEntries: base.dayEntries,
        holidays: base.holidays,
        absenceBalances: base.absenceBalances,
        settings: base.settings,
      );
      final a = fingerprint(base);
      final b = fingerprint(without);
      expect(a, isNot(b));
      expect(a.firstDayDifferingFrom(b), const CivilDate(2026, 2, 1));
    });

    test('moving the same days from one calendar to the other changes it', () {
      final base = v2();
      final moved = withEntries(base, [
        for (final e in base.dayEntries)
          BackupDayEntry(
            calendarId: 'main',
            date: e.date,
            shiftTypeIds: e.shiftTypeIds,
            note: e.note,
            updatedAt: e.updatedAt,
          ),
      ]);
      // Two days now clash on the same date: keep the first of each.
      final seen = <CivilDate>{};
      final unique = [
        for (final e in moved.dayEntries)
          if (seen.add(e.date)) e,
      ];
      expect(fingerprint(withEntries(base, unique)), isNot(fingerprint(base)));
    });

    test('a calendar renamed changes the entities, not the days', () {
      final base = v2();
      final renamed = BackupData(
        calendars: [
          for (final c in base.calendars)
            if (c.id == 'cal-pareja')
              BackupCalendar(
                id: c.id,
                name: 'Otro nombre',
                colorValue: c.colorValue,
                sortOrder: c.sortOrder,
                createdAt: c.createdAt,
                updatedAt: c.updatedAt,
              )
            else
              c,
        ],
        shiftTypes: base.shiftTypes,
        patterns: base.patterns,
        patternRuns: base.patternRuns,
        dayEntries: base.dayEntries,
        holidays: base.holidays,
        absenceBalances: base.absenceBalances,
        settings: base.settings,
      );
      final a = fingerprint(base);
      final b = fingerprint(renamed);
      expect(a, isNot(b));
      expect(a.firstDayDifferingFrom(b), isNull);
    });

    test('the order the calendars come in does not matter', () {
      final base = v2();
      final shuffled = BackupData(
        calendars: base.calendars.reversed,
        shiftTypes: base.shiftTypes,
        patterns: base.patterns,
        patternRuns: base.patternRuns.reversed,
        dayEntries: base.dayEntries.reversed,
        holidays: base.holidays,
        absenceBalances: base.absenceBalances,
        settings: base.settings,
      );
      expect(fingerprint(shuffled), fingerprint(base));
    });

    test('it resolves each calendar with its own runs and days', () {
      final f = fingerprint(v2());
      expect(f.calendarIds, ['cal-old', 'cal-pareja', 'main']);
      expect(f.dayCount, 730);
      // The engine view of each calendar is what the fingerprint hashed.
      final data = v2();
      expect(data.toSchedule('cal-pareja').runs.map((r) => r.id), [
        'run-4',
        'run-5',
      ]);
      expect(data.toSchedule('main').runs.map((r) => r.id), [
        'run-1',
        'run-2',
        'run-3',
      ]);
      expect(data.toSchedule('cal-old').runs.map((r) => r.id), ['run-6']);
      // The same date, two calendars, two different days.
      expect(
        data.toSchedule('main').resolve(goldenFrom).shiftIds,
        isNot(data.toSchedule('cal-pareja').resolve(goldenFrom).shiftIds),
      );
    });
  });
}
