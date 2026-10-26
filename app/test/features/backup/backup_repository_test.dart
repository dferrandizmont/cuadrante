import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/backup/data/backup_repository.dart';
import 'package:cuadrante/features/backup/data/backup_settings_repository.dart';
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

/// A small dataset, different from the golden one in everything.
BackupData smallData() => BackupData(
  shiftTypes: const [
    BackupShiftType(
      id: 'a',
      code: 'A',
      name: 'Solo uno',
      colorValue: 0xFF112233,
      category: ShiftCategory.work,
      startMinute: 60,
      endMinute: 120,
      sortOrder: 0,
      createdAt: 1000,
      updatedAt: 2000,
    ),
  ],
  patterns: const [
    BackupPattern(
      id: 'pa',
      name: 'Cada dia',
      steps: [
        ['a'],
      ],
      createdAt: 1000,
      updatedAt: 2000,
    ),
  ],
  patternRuns: [
    BackupPatternRun(
      id: 'ra',
      patternId: 'pa',
      startDate: const CivilDate(2026, 5, 1),
      seq: 1,
      createdAt: 3000,
    ),
  ],
  dayEntries: const [
    BackupDayEntry(
      date: CivilDate(2026, 5, 2),
      shiftTypeIds: [],
      note: 'libre',
      updatedAt: 4000,
    ),
  ],
  settings: const {'k': '"v"'},
);

void main() {
  late Directory dir;
  late Directory safety;
  late AppDatabase db;
  late BackupRepository repository;
  var clock = DateTime.utc(2026, 11, 10, 9);

  const today = CivilDate(2026, 11, 10);

  setUp(() {
    clock = DateTime.utc(2026, 11, 10, 9);
    dir = makeTempDir('backup-repo');
    safety = Directory(p.join(dir.path, 'backups'));
    db = openMemoryDatabase();
    repository = makeRepository(db, safety, now: () => clock);
  });
  tearDown(() => db.close());

  group('readAll', () {
    test('an empty database reads as empty data', () async {
      final data = await repository.readAll();
      // Only the calendar every database has.
      expect(data.calendars.map((c) => c.id), ['main']);
      expect(data, BackupData(calendars: data.calendars));
    });

    test('reads every table, and only user holidays', () async {
      await seedDatabase(
        db,
        buildGoldenBackupData(),
        withDerivedHolidays: true,
      );
      final data = await repository.readAll();
      expect(data, buildGoldenBackupData());
      expect(data.holidays.map((h) => h.name), ['Fiesta del barrio 🎆']);
    });

    test('keeps the patterns in the order they were stored', () async {
      await seedDatabase(db, buildGoldenBackupData());
      final ids = (await repository.readAll()).patterns.map((p) => p.id);
      expect(ids, ['p-turnicidad', 'p-mananas', 'p-noches']);
    });
  });

  group('round trip (R4)', () {
    test(
      'DB -> file -> fresh DB: same fingerprint, same tables, same bytes',
      () async {
        await seedDatabase(
          db,
          buildGoldenBackupData(),
          withDerivedHolidays: true,
        );
        const codec = BackupCodec();
        final bytes = codec.encode(
          await repository.readAll(),
          appVersion: testAppVersion,
          exportedAt: goldenExportedAt,
        );

        final other = openMemoryDatabase();
        addTearDown(other.close);
        final otherRepository = makeRepository(
          other,
          Directory(p.join(dir.path, 'other')),
        );
        await otherRepository.restore(codec.decode(bytes).data);

        // Identical contents of every table (derived holidays are not carried).
        final before = await dumpAllTables(db);
        final after = await dumpAllTables(other);
        expect({...after}..remove('holidays'), {...before}..remove('holidays'));
        expect(after['holidays'], [
          isA<Map<String, Object?>>().having(
            (r) => r['source'],
            'source',
            'user',
          ),
        ]);

        // Identical fingerprint over the 730 days.
        final fingerprintBefore = scheduleFingerprint(
          await repository.readAll(),
          from: goldenFrom,
          to: goldenTo,
        );
        final fingerprintAfter = scheduleFingerprint(
          await otherRepository.readAll(),
          from: goldenFrom,
          to: goldenTo,
        );
        expect(fingerprintAfter, fingerprintBefore);
        expect(fingerprintAfter.dayCount, 730);

        // And exporting the restored database gives the very same file.
        final again = codec.encode(
          await otherRepository.readAll(),
          appVersion: testAppVersion,
          exportedAt: goldenExportedAt,
        );
        expect(again, bytes);
      },
    );

    group('the flags of the first-use flow belong to the device', () {
      Future<Map<String, String>> stored() async => {
        for (final row in await db.select(db.settings).get())
          row.key: row.value,
      };

      test('are not exported', () async {
        await seedDatabase(db, smallData());
        await db.customStatement(
          "INSERT INTO settings (key, value) VALUES ('onboarding.done', 'true'), "
          "('onboarding.profile', '\"nursing\"'), ('onboarding.tipPending', 'true')",
        );
        final data = await repository.readAll();
        expect(
          data.settings.keys.where((k) => k.startsWith('onboarding.')),
          isEmpty,
        );
      });

      test('survive a restore of a file that has none', () async {
        await seedDatabase(db, smallData());
        await db.customStatement(
          "INSERT INTO settings (key, value) VALUES ('onboarding.done', 'true'), "
          "('onboarding.tipPending', 'true')",
        );
        await repository.restore(buildGoldenBackupData());
        final after = await stored();
        expect(after['onboarding.done'], 'true');
        expect(after['onboarding.tipPending'], 'true');
      });

      test('a file that carries them (older versions) does not bring them '
          'back', () async {
        await seedDatabase(db, smallData());
        await db.customStatement(
          "INSERT INTO settings (key, value) VALUES ('onboarding.done', 'true')",
        );
        final golden = buildGoldenBackupData();
        final withFlags = BackupData(
          calendars: golden.calendars,
          shiftTypes: golden.shiftTypes,
          patterns: golden.patterns,
          patternRuns: golden.patternRuns,
          dayEntries: golden.dayEntries,
          holidays: golden.holidays,
          absenceBalances: golden.absenceBalances,
          settings: {
            ...golden.settings,
            'onboarding.done': 'false',
            'onboarding.profile': '"police"',
          },
        );
        await repository.restore(withFlags);
        final after = await stored();
        expect(after['onboarding.done'], 'true', reason: 'the device wins');
        expect(after.containsKey('onboarding.profile'), isFalse);
      });
    });

    group('the "Copia en iCloud" switch belongs to the device (H1)', () {
      Future<Map<String, String>> stored() async => {
        for (final row in await db.select(db.settings).get())
          row.key: row.value,
      };

      test('is not exported', () async {
        await seedDatabase(db, smallData());
        await BackupSettingsRepository(db).saveCloud(true);
        final data = await repository.readAll();
        expect(data.settings.containsKey(cloudBackupKey), isFalse);
      });

      test('survives a restore of a file that has none', () async {
        await seedDatabase(db, smallData());
        await BackupSettingsRepository(db).saveCloud(true);
        await repository.restore(buildGoldenBackupData());
        expect(await BackupSettingsRepository(db).loadCloud(), isTrue);
      });

      test('a file cannot turn it on', () async {
        await seedDatabase(db, smallData());
        final golden = buildGoldenBackupData();
        final crafted = BackupData(
          calendars: golden.calendars,
          shiftTypes: golden.shiftTypes,
          patterns: golden.patterns,
          patternRuns: golden.patternRuns,
          dayEntries: golden.dayEntries,
          holidays: golden.holidays,
          absenceBalances: golden.absenceBalances,
          settings: {...golden.settings, cloudBackupKey: 'true'},
        );
        await repository.restore(crafted);
        expect((await stored()).containsKey(cloudBackupKey), isFalse);
        expect(await BackupSettingsRepository(db).loadCloud(), isFalse);
      });

      test('a file cannot turn it off either', () async {
        await seedDatabase(db, smallData());
        await BackupSettingsRepository(db).saveCloud(true);
        final golden = buildGoldenBackupData();
        final crafted = BackupData(
          calendars: golden.calendars,
          shiftTypes: golden.shiftTypes,
          patterns: golden.patterns,
          patternRuns: golden.patternRuns,
          dayEntries: golden.dayEntries,
          holidays: golden.holidays,
          absenceBalances: golden.absenceBalances,
          settings: {...golden.settings, cloudBackupKey: 'false'},
        );
        await repository.restore(crafted);
        expect(await BackupSettingsRepository(db).loadCloud(), isTrue);
      });
    });

    group('the app language belongs to the device (security review)', () {
      const key = 'appearance.language';

      Future<void> setLanguage(String value) => db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: key, value: value),
          );

      Future<Map<String, String>> stored() async => {
        for (final row in await db.select(db.settings).get())
          row.key: row.value,
      };

      BackupData crafted(String value) {
        final golden = buildGoldenBackupData();
        return BackupData(
          calendars: golden.calendars,
          shiftTypes: golden.shiftTypes,
          patterns: golden.patterns,
          patternRuns: golden.patternRuns,
          dayEntries: golden.dayEntries,
          holidays: golden.holidays,
          absenceBalances: golden.absenceBalances,
          settings: {...golden.settings, key: value},
        );
      }

      test('is a device setting', () {
        expect(isDeviceSetting(key), isTrue);
      });

      test('is not exported', () async {
        await seedDatabase(db, smallData());
        await setLanguage('"ca"');
        final data = await repository.readAll();
        expect(data.settings.containsKey(key), isFalse);
      });

      test('survives a restore of a file that has none', () async {
        await seedDatabase(db, smallData());
        await setLanguage('"eu"');
        await repository.restore(buildGoldenBackupData());
        expect((await stored())[key], '"eu"');
      });

      test('a file cannot change it', () async {
        await seedDatabase(db, smallData());
        await setLanguage('"gl"');
        await repository.restore(crafted('"en"'));
        expect((await stored())[key], '"gl"');
      });

      test('a file cannot set it on a phone that follows the system', () async {
        await seedDatabase(db, smallData());
        await repository.restore(crafted('"en"'));
        expect((await stored()).containsKey(key), isFalse);
      });
    });

    test('replaces everything that was there, not merging', () async {
      await seedDatabase(
        db,
        buildGoldenBackupData(),
        withDerivedHolidays: true,
      );
      await repository.restore(smallData());

      expect(await repository.readAll(), smallData());
      final tables = await dumpAllTables(db);
      expect(tables['shift_types'], hasLength(1));
      expect(tables['pattern_runs'], hasLength(1));
      expect(tables['day_entries'], hasLength(1));
      expect(tables['absence_balances'], isEmpty);
      expect(tables['settings'], hasLength(1));
      // The user holiday is gone; the derived ones are not ours to touch.
      expect(
        [for (final h in tables['holidays']!) h['source']],
        ['bundled', 'remote'],
      );
    });

    test('restores into a brand new database', () async {
      await repository.restore(buildGoldenBackupData());
      expect(await repository.readAll(), buildGoldenBackupData());
    });

    test('an empty backup empties the database', () async {
      await seedDatabase(db, buildGoldenBackupData());
      await repository.restore(BackupData());
      expect(await repository.readAll(), BackupData());
    });

    test('the restored data resolves the same days', () async {
      await repository.restore(buildGoldenBackupData());
      final schedule = (await repository.readAll()).toSchedule();
      final expected = buildGoldenBackupData().toSchedule();
      for (var d = goldenFrom; !d.isAfter(goldenTo); d = d.addDays(1)) {
        expect(
          schedule.resolve(d).shiftIds,
          expected.resolve(d).shiftIds,
          reason: '$d',
        );
        expect(
          schedule.resolve(d).note,
          expected.resolve(d).note,
          reason: '$d',
        );
      }
    });
  });

  group('preview', () {
    test('counts what is coming and what is there, and the dates', () async {
      await seedDatabase(db, smallData());
      final summary = await repository.preview(buildGoldenBackupData());

      expect(summary.incoming, BackupCounts.of(buildGoldenBackupData()));
      expect(summary.incoming.dayEntries, 40);
      expect(summary.incoming.patternRuns, 3);
      expect(summary.current, BackupCounts.of(smallData()));
      expect(summary.firstDate, const CivilDate(2026, 1, 1));
      // The last entry is 39 * 17 days after 2026-01-01.
      expect(summary.lastDate, goldenFrom.addDays(39 * 17));
      expect(summary.hasOpenEndedRun, isTrue);
    });

    test('has no dates for data without days or runs', () async {
      final summary = await repository.preview(BackupData());
      expect(summary.firstDate, isNull);
      expect(summary.lastDate, isNull);
      expect(summary.hasOpenEndedRun, isFalse);
    });

    test('writes nothing', () async {
      await seedDatabase(db, smallData());
      final before = await dumpAllTables(db);
      await repository.preview(buildGoldenBackupData());
      expect(await dumpAllTables(db), before);
      expect(fileNames(safety), isEmpty);
    });

    test('refuses inconsistent data', () {
      final broken = BackupData(
        patternRuns: [
          BackupPatternRun(
            id: 'r',
            patternId: 'nope',
            startDate: const CivilDate(2026, 1, 1),
            seq: 1,
            createdAt: 0,
          ),
        ],
      );
      expect(() => repository.preview(broken), throwsA(isA<CorruptBackup>()));
    });
  });

  group('restore is all or nothing', () {
    test('a failure in the middle leaves the original data intact', () async {
      await seedDatabase(
        db,
        buildGoldenBackupData(),
        withDerivedHolidays: true,
      );
      final before = await dumpAllTables(db);

      // The settings are the last thing written: by then every other table
      // has been emptied and refilled.
      await db.customStatement(
        'CREATE TRIGGER boom BEFORE INSERT ON settings '
        "WHEN NEW.key = 'boom' "
        "BEGIN SELECT RAISE(ABORT, 'boom'); END",
      );
      final poisoned = BackupData(
        shiftTypes: smallData().shiftTypes,
        patterns: smallData().patterns,
        patternRuns: smallData().patternRuns,
        dayEntries: smallData().dayEntries,
        settings: const {'boom': '1'},
      );

      await expectLater(
        repository.restore(poisoned),
        throwsA(predicate((e) => e.toString().contains('boom'))),
      );

      expect(await dumpAllTables(db), before);
      expect(await repository.readAll(), buildGoldenBackupData());
    });

    test('a failure while deleting leaves the original data intact', () async {
      await seedDatabase(db, buildGoldenBackupData());
      final before = await dumpAllTables(db);
      await db.customStatement(
        'CREATE TRIGGER nodelete BEFORE DELETE ON absence_balances '
        "BEGIN SELECT RAISE(ABORT, 'no'); END",
      );
      await expectLater(repository.restore(smallData()), throwsA(anything));
      expect(await dumpAllTables(db), before);
    });

    test('inconsistent data is refused before anything is written', () async {
      await seedDatabase(db, smallData());
      final before = await dumpAllTables(db);
      final broken = BackupData(
        shiftTypes: buildGoldenBackupData().shiftTypes,
        patternRuns: buildGoldenBackupData().patternRuns, // no patterns
      );
      await expectLater(
        repository.restore(broken),
        throwsA(isA<CorruptBackup>()),
      );
      expect(await dumpAllTables(db), before);
      expect(fileNames(safety), isEmpty, reason: 'nothing was started');
    });

    test(
      'two own holidays on one date are refused, restore untouched',
      () async {
        await seedDatabase(db, smallData());
        final before = await dumpAllTables(db);
        final twice = BackupData(
          holidays: [
            BackupHoliday(
              date: const CivilDate(2026, 10, 22),
              scope: 'local',
              name: 'Una',
            ),
            BackupHoliday(
              date: const CivilDate(2026, 10, 22),
              scope: 'local',
              name: 'Otra',
            ),
          ],
        );
        expect(() => twice.validate(), throwsA(isA<CorruptBackup>()));
        await expectLater(
          repository.restore(twice),
          throwsA(isA<CorruptBackup>()),
        );
        expect(await dumpAllTables(db), before);
        expect(fileNames(safety), isEmpty, reason: 'nothing was started');
      },
    );

    test('data the engine rejects: verify and restore agree', () async {
      await seedDatabase(db, smallData());
      final before = await dumpAllTables(db);
      final good = smallData();
      final type = good.shiftTypes.single;
      final broken = BackupData(
        shiftTypes: [
          BackupShiftType(
            id: type.id,
            code: 'ABCD', // the engine allows 1 to 3 characters
            name: type.name,
            colorValue: type.colorValue,
            category: type.category,
            startMinute: type.startMinute,
            endMinute: type.endMinute,
            sortOrder: type.sortOrder,
            createdAt: type.createdAt,
            updatedAt: type.updatedAt,
          ),
        ],
        patterns: good.patterns,
        patternRuns: good.patternRuns,
        dayEntries: good.dayEntries,
      );

      // What a file holding it would look like (the codec refuses to write
      // it, so the envelope is built by hand).
      final json = broken.toJson();
      final bytes = gzipEnvelope({
        'format': 'cuadrante',
        'schemaVersion': 2,
        'appVersion': testAppVersion,
        'exportedAt': '2026-11-10T09:00:00Z',
        'data': json,
        'checksum': BackupCodec.checksumOfJson(json),
      });
      final verdict = await repository.verifyRestore(bytes, today: today);
      expect((verdict as VerificationFailed).error, isA<CorruptBackup>());

      await expectLater(
        repository.restore(broken),
        throwsA(isA<CorruptBackup>()),
      );
      expect(await dumpAllTables(db), before);
      expect(fileNames(safety), isEmpty, reason: 'nothing was started');
    });

    test('without a safety copy there is no restore', () async {
      await seedDatabase(db, smallData());
      final before = await dumpAllTables(db);
      // A folder cannot be created under a file.
      final blocker = File(p.join(dir.path, 'blocker'))..writeAsStringSync('x');
      final blocked = makeRepository(
        db,
        Directory(p.join(blocker.path, 'backups')),
      );
      await expectLater(
        blocked.restore(buildGoldenBackupData()),
        throwsA(isA<FileSystemException>()),
      );
      expect(await dumpAllTables(db), before);
    });
  });

  group('safety copy before a restore', () {
    test(
      'a note above the old 4 MiB limit can recover replaced data',
      () async {
        final large = BackupData(
          dayEntries: [
            BackupDayEntry(
              date: today,
              note: 'a' * (5 * 1024 * 1024),
              noteReminderMinute: 480,
              overtimeMinutes: 30,
              updatedAt: 4000,
            ),
          ],
        );
        await seedDatabase(db, large);
        final before = await repository.readAll();
        await repository.restore(smallData());
        final copy = File(p.join(safety.path, fileNames(safety).single));
        final decoded = const BackupCodec().decode(await copy.readAsBytes());
        expect(decoded.data, before);
        await repository.restore(decoded.data);
        expect(await repository.readAll(), before);
      },
    );

    test(
      'failed read-back leaves live data and old safety copies intact',
      () async {
        await seedDatabase(db, smallData());
        safety.createSync(recursive: true);
        final old = File(
          p.join(safety.path, 'pre-restore-20260101-000000.cuadrante'),
        );
        old.writeAsBytesSync([1, 2, 3]);
        final before = await dumpAllTables(db);
        final broken = BackupRepository(
          db,
          safetyDirectory: safety,
          appVersion: testAppVersion,
          keepSafetyCopies: 1,
          readSafetyCopy: (file) async {
            await file.writeAsBytes([0x1f, 0x8b]);
            return file.readAsBytes();
          },
        );
        await expectLater(
          broken.restore(buildGoldenBackupData()),
          throwsA(isA<CorruptBackup>()),
        );
        expect(await dumpAllTables(db), before);
        expect(await old.readAsBytes(), [1, 2, 3]);
      },
    );

    test('holds the data that was replaced', () async {
      await seedDatabase(db, buildGoldenBackupData());
      await repository.restore(smallData());

      expect(fileNames(safety), ['pre-restore-20261110-090000.cuadrante']);
      final bytes = File(
        p.join(safety.path, 'pre-restore-20261110-090000.cuadrante'),
      ).readAsBytesSync();
      final file = const BackupCodec().decode(bytes);
      expect(file.data, buildGoldenBackupData());
      expect(file.appVersion, testAppVersion);
      expect(file.exportedAt, DateTime.utc(2026, 11, 10, 9));
    });

    test('can be restored to undo the restore', () async {
      await seedDatabase(db, buildGoldenBackupData());
      await repository.restore(smallData());
      final copy = File(p.join(safety.path, fileNames(safety).single));
      await repository.restore(
        const BackupCodec().decode(copy.readAsBytesSync()).data,
      );
      expect(await repository.readAll(), buildGoldenBackupData());
    });

    test('keeps the 3 newest', () async {
      for (var i = 0; i < 5; i++) {
        clock = DateTime.utc(2026, 11, 10, 9, i);
        await repository.restore(
          i.isEven ? smallData() : buildGoldenBackupData(),
        );
      }
      expect(fileNames(safety), [
        'pre-restore-20261110-090200.cuadrante',
        'pre-restore-20261110-090300.cuadrante',
        'pre-restore-20261110-090400.cuadrante',
      ]);
    });

    test(
      'two restores in the same second do not overwrite each other',
      () async {
        await repository.restore(smallData());
        await repository.restore(buildGoldenBackupData());
        await repository.restore(smallData());
        expect(fileNames(safety), [
          'pre-restore-20261110-090000-2.cuadrante',
          'pre-restore-20261110-090000-3.cuadrante',
          'pre-restore-20261110-090000.cuadrante',
        ]);
        // The oldest of them is the first (empty database) and the newest the
        // one before the last restore.
        Uint8List read(String name) =>
            File(p.join(safety.path, name)).readAsBytesSync();
        expect(
          const BackupCodec()
              .decode(read('pre-restore-20261110-090000-3.cuadrante'))
              .data,
          buildGoldenBackupData(),
        );
        expect(
          const BackupCodec()
              .decode(read('pre-restore-20261110-090000-2.cuadrante'))
              .data,
          smallData(),
        );
      },
    );

    test(
      'leaves other files in the folder alone and leaves no temp file',
      () async {
        safety.createSync(recursive: true);
        File(p.join(safety.path, 'pre-v1-a-v2-20260101-000000.sqlite'))
            .writeAsStringSync('db');
        File(p.join(safety.path, 'notes.txt')).writeAsStringSync('hi');
        for (var i = 0; i < 5; i++) {
          clock = DateTime.utc(2026, 11, 10, 9, i);
          await repository.restore(smallData());
        }
        final names = fileNames(safety);
        expect(names, contains('pre-v1-a-v2-20260101-000000.sqlite'));
        expect(names, contains('notes.txt'));
        expect(names.where((n) => n.endsWith('.tmp')), isEmpty);
        expect(names.where((n) => n.startsWith('pre-restore-')), hasLength(3));
      },
    );
  });

  group('verifyRestore ("Probar restauración")', () {
    Future<Uint8List> exportLive() async => const BackupCodec().encode(
      await repository.readAll(),
      appVersion: testAppVersion,
      exportedAt: clock,
    );

    test('passes, and equals the live data, for a fresh copy', () async {
      await seedDatabase(db, buildGoldenBackupData());
      final result = await repository.verifyRestore(
        await exportLive(),
        today: today,
      );

      expect(result, isA<VerificationPassed>());
      final passed = result as VerificationPassed;
      expect(passed.matchesLive, isTrue);
      expect(passed.firstDayDifferingFromLive, isNull);
      expect(passed.fingerprint.dayCount, fingerprintWindowDays);
    });

    test('touches nothing: not the live data, not the safety folder', () async {
      await seedDatabase(db, buildGoldenBackupData());
      final bytes = await exportLive();
      final before = await dumpAllTables(db);
      await repository.verifyRestore(bytes, today: today);
      expect(await dumpAllTables(db), before);
      expect(fileNames(safety), isEmpty);
    });

    test(
      'passes for an older copy and says where it differs from now',
      () async {
        await seedDatabase(db, buildGoldenBackupData());
        final bytes = await exportLive();
        // Changed after the copy was made: 2026-01-01 was a night.
        await db.customStatement(
          "UPDATE day_entries SET shift_type_ids = '[]' WHERE date = '2026-01-01'",
        );

        final result = await repository.verifyRestore(bytes, today: today);
        final passed = result as VerificationPassed;
        expect(passed.matchesLive, isFalse);
        final window = defaultFingerprintWindow(today);
        expect(window.from, const CivilDate(2025, 11, 10));
        expect(passed.firstDayDifferingFromLive, const CivilDate(2026, 1, 1));
      },
    );

    test('a change outside the window is still seen, without a day', () async {
      await seedDatabase(db, buildGoldenBackupData());
      final bytes = await exportLive();
      await db.customStatement(
        "UPDATE settings SET value = '\"x\"' WHERE key = 'alarms'",
      );
      final passed = await repository.verifyRestore(
        bytes,
        today: today,
      ) as VerificationPassed;
      expect(passed.matchesLive, isFalse);
      expect(passed.firstDayDifferingFromLive, isNull);
    });

    test('reports the first differing day when the rebuild is wrong', () async {
      await seedDatabase(db, buildGoldenBackupData());
      final bytes = await exportLive();
      final tampered = goldenFrom.addDays(5 * 17); // an exception day
      final faulty = makeRepository(
        db,
        safety,
        openScratchDatabase: () {
          final scratch = openMemoryDatabase();
          // A restore that corrupts one day on its way in.
          scratch.customStatement(
            'CREATE TRIGGER corrupt AFTER INSERT ON day_entries '
            "WHEN NEW.date = '${tampered.toIso()}' "
            "BEGIN UPDATE day_entries SET note = 'mangled' WHERE date = NEW.date; END",
          );
          return scratch;
        },
      );

      final result = await faulty.verifyRestore(bytes, today: today);
      expect(result, isA<VerificationMismatch>());
      final mismatch = result as VerificationMismatch;
      expect(mismatch.firstDifferingDay, tampered);
      expect(mismatch.expected, isNot(mismatch.actual));
    });

    test('reports a fault outside the calendar days with no day', () async {
      await seedDatabase(db, buildGoldenBackupData());
      final bytes = await exportLive();
      final faulty = makeRepository(
        db,
        safety,
        openScratchDatabase: () {
          final scratch = openMemoryDatabase();
          scratch.customStatement(
            'CREATE TRIGGER corrupt AFTER INSERT ON settings '
            'BEGIN UPDATE settings SET value = \'"mangled"\' WHERE key = NEW.key; END',
          );
          return scratch;
        },
      );
      final result = await faulty.verifyRestore(bytes, today: today);
      expect((result as VerificationMismatch).firstDifferingDay, isNull);
    });

    test('says why a file cannot be used', () async {
      final garbage = Uint8List.fromList(List.filled(64, 7));
      final r1 = await repository.verifyRestore(garbage, today: today);
      expect((r1 as VerificationFailed).error, isA<NotACuadranteFile>());

      final good = const BackupCodec().encode(
        buildGoldenBackupData(),
        appVersion: testAppVersion,
        exportedAt: clock,
      );
      final r2 = await repository.verifyRestore(
        Uint8List.sublistView(good, 0, good.length ~/ 2),
        today: today,
      );
      expect((r2 as VerificationFailed).error, isA<CorruptBackup>());

      final newer = gzipEnvelope({
        'format': 'cuadrante',
        'schemaVersion': 4,
        'data': <String, Object?>{},
        'checksum': 'x',
      });
      final r3 = await repository.verifyRestore(newer, today: today);
      expect((r3 as VerificationFailed).error, isA<NewerFormatVersion>());
    });

    test('works on an empty database and an empty file', () async {
      final bytes = await exportLive();
      final passed = await repository.verifyRestore(
        bytes,
        today: today,
      ) as VerificationPassed;
      expect(passed.matchesLive, isTrue);
    });
  });
}
