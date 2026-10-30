import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/backup/application/backup_service.dart';
import 'package:cuadrante/features/backup/data/local_file_backup_store.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:cuadrante/features/backup/domain/backup_errors.dart';
import 'package:cuadrante/features/backup/domain/restore_summary.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'backup_test_support.dart';
import 'golden_dataset.dart';

/// The whole import/export flow the screens will drive, against a real
/// database and a folder store, including the matrix rows that must leave the
/// data alone (R6, R7).
void main() {
  late Directory dir;
  late Directory safety;
  late AppDatabase db;
  late LocalFileBackupStore store;
  late BackupService service;
  var clock = DateTime.utc(2026, 11, 10, 9);

  setUp(() async {
    clock = DateTime.utc(2026, 11, 10, 9);
    dir = makeTempDir('backup-service');
    safety = Directory(p.join(dir.path, 'backups'));
    db = openMemoryDatabase();
    store = LocalFileBackupStore(Directory(p.join(dir.path, 'store')));
    service = BackupService(
      repository: makeRepository(db, safety, now: () => clock),
      store: store,
      appVersion: testAppVersion,
      now: () => clock,
    );
    await seedDatabase(db, buildGoldenBackupData());
  });
  tearDown(() => db.close());

  test('backupNow stores a file that reads back as the current data', () async {
    final entry = await service.backupNow();
    expect(entry.id, 'turnly-20261110-090000.turnly');
    final file = const BackupCodec().decode(await store.read(entry));
    expect(file.data, buildGoldenBackupData());
    expect(file.appVersion, testAppVersion);
    expect(file.exportedAt, clock);
  });

  test('exportBytes is the same file backupNow stores', () async {
    final entry = await service.backupNow();
    expect(await service.exportBytes(), await store.read(entry));
  });

  test(
    'a legacy .cuadrante file still imports and restores unchanged',
    () async {
      final legacy = File('test/fixtures/golden_backup/golden_v3.cuadrante');
      final original = await legacy.readAsBytes();
      final pending = await service.inspect(original);
      await service.restore(pending);
      expect(await makeRepository(db, safety).readAll(), pending.file.data);
      expect(await legacy.readAsBytes(), original);
      expect(readEnvelope(await service.exportBytes())['format'], 'cuadrante');
      expect(fileNames(safety).single, endsWith('.turnly'));
    },
  );

  test('import into another phone: inspect, then restore (R4)', () async {
    final bytes = await service.exportBytes();

    final other = openMemoryDatabase();
    addTearDown(other.close);
    final otherStore = LocalFileBackupStore(
      Directory(p.join(dir.path, 'other-store')),
    );
    final otherService = BackupService(
      repository: makeRepository(
        other,
        Directory(p.join(dir.path, 'other-safety')),
      ),
      store: otherStore,
      appVersion: testAppVersion,
      now: () => clock,
    );

    final pending = await otherService.inspect(bytes);
    expect(pending.summary.current, BackupCounts.of(BackupData()));
    expect(pending.summary.incoming.dayEntries, 40);
    expect(pending.file.exportedAt, clock);
    expect(await dumpAllTables(other), isNot(await dumpAllTables(db)));

    await otherService.restore(pending);
    expect(await dumpAllTables(other), await dumpAllTables(db));
    expect(await otherService.exportBytes(), bytes);
  });

  test(
    'exports and restores more than ten calendars on another database',
    () async {
      final calendars = CalendarsRepository(db);
      final schedules = ScheduleRepository(db);
      final created = <Calendar>[];
      const day = CivilDate(2026, 11, 11);
      for (var i = 1; i <= 15; i++) {
        final calendar = await calendars.create(name: 'C$i', colorValue: i);
        created.add(calendar);
        await schedules.apply(
          calendar.id,
          ScheduleChange(
            patch: EntriesPatch({
              day: EntryChange(null, DayEntry(date: day, note: 'Nota $i')),
            }),
          ),
        );
      }
      await calendars.archive(created.last.id);
      await calendars.setActive(created[11].id);
      await calendars.setPrimary(created[10].id);
      final expected = await calendars.list(includeArchived: true);
      final bytes = await service.exportBytes();

      final other = openMemoryDatabase();
      addTearDown(other.close);
      final otherService = BackupService(
        repository: makeRepository(
          other,
          Directory(p.join(dir.path, 'many-safety')),
        ),
        store: LocalFileBackupStore(Directory(p.join(dir.path, 'many-store'))),
        appVersion: testAppVersion,
        now: () => clock,
      );
      final pending = await otherService.inspect(bytes);
      expect(pending.summary.incoming.calendars, 16);
      await otherService.restore(pending);

      final restored = CalendarsRepository(other);
      expect(await restored.list(includeArchived: true), expected);
      expect(await restored.list(), hasLength(15));
      expect(await restored.activeId(), created[11].id);
      expect(await restored.primaryId(), created[10].id);
      expect(await dumpAllTables(other), await dumpAllTables(db));
      expect(await otherService.exportBytes(), bytes);
      // An archived calendar and its note remain recoverable beyond ten.
      await restored.unarchive(created.last.id);
      expect(await restored.list(), hasLength(16));
      expect(
        (await ScheduleRepository(other).load(created.last.id))
            .schedule
            .entries[day]
            ?.note,
        'Nota 15',
      );
      await restored.create(name: 'Otro', colorValue: 17);
      expect(await restored.list(), hasLength(17));
    },
  );

  group('files that must not change anything', () {
    late Map<String, List<Map<String, Object?>>> before;

    setUp(() async {
      before = await dumpAllTables(db);
    });

    /// What the screens do with an imported file.
    Future<void> importFile(Uint8List bytes) async =>
        service.restore(await service.inspect(bytes));

    Future<void> expectRejectedAndUntouched(
      Uint8List bytes,
      Matcher error,
    ) async {
      await expectLater(importFile(bytes), throwsA(error));
      expect(await dumpAllTables(db), before);
      expect(fileNames(safety), isEmpty, reason: 'no restore was started');
    }

    test('R6: a file from a newer version', () async {
      final newer = gzipEnvelope({
        'format': 'cuadrante',
        'schemaVersion': 4,
        'appVersion': '4.0.0',
        'exportedAt': '2027-01-01T00:00:00Z',
        'data': {'shiftTypes': 'a different shape'},
        'checksum': 'sha256:00',
      });
      await expectRejectedAndUntouched(
        newer,
        isA<NewerFormatVersion>()
            .having((e) => e.found, 'found', 4)
            .having((e) => e.supported, 'supported', 3),
      );
    });

    test('R7: a truncated file', () async {
      final good = await service.exportBytes();
      for (final cut in [good.length ~/ 3, good.length ~/ 2, good.length - 1]) {
        await expectRejectedAndUntouched(
          Uint8List.sublistView(good, 0, cut),
          isA<CorruptBackup>(),
        );
      }
    });

    test('R7: a file with altered bytes', () async {
      final good = await service.exportBytes();
      for (final at in [good.length ~/ 5, good.length ~/ 2, good.length - 20]) {
        final damaged = Uint8List.fromList(good)..[at] ^= 0xff;
        await expectRejectedAndUntouched(damaged, isA<CorruptBackup>());
      }
    });

    test('R7: data edited by hand (checksum no longer matches)', () async {
      final env = readEnvelope(await service.exportBytes());
      (env['data']! as Map<String, Object?>)['settings'] = <String, Object?>{};
      await expectRejectedAndUntouched(gzipEnvelope(env), isA<CorruptBackup>());
    });

    test('R7: garbage and an empty file', () async {
      await expectRejectedAndUntouched(Uint8List(0), isA<NotACuadranteFile>());
      await expectRejectedAndUntouched(
        Uint8List.fromList(List.generate(300, (i) => (i * 37) % 256)),
        isA<NotACuadranteFile>(),
      );
    });
  });

  group('verifyLatest', () {
    test('is null when there is no backup yet', () async {
      expect(
        await service.verifyLatest(today: const CivilDate(2026, 11, 10)),
        isNull,
      );
    });

    test('checks the newest stored backup', () async {
      await service.backupNow();
      final result = await service.verifyLatest(
        today: const CivilDate(2026, 11, 10),
      );
      expect((result! as VerificationPassed).matchesLive, isTrue);
    });
  });
}
