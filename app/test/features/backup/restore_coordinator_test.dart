import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/backup/application/backup_service.dart';
import 'package:cuadrante/features/backup/application/restore_coordinator.dart';
import 'package:cuadrante/features/backup/data/local_file_backup_store.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendars/application/calendars_controller.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/onboarding/application/onboarding_providers.dart';
import 'package:cuadrante/features/onboarding/data/onboarding_repository.dart';
import 'package:cuadrante/features/patterns/application/post_night_provider.dart';
import 'package:cuadrante/features/patterns/data/post_night_settings.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../support/probes.dart';
import '../../support/test_storage.dart';
import 'backup_test_support.dart';
import 'golden_dataset.dart';
import 'golden_dataset_v2.dart';

final _now = DateTime(2026, 10, 19, 12);
const _today = CivilDate(2026, 10, 19);

/// A way to get a [Ref] out of a container in a test.
final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  late TestStorage storage;
  late ProbeRepository probe;
  late ProviderContainer container;
  late BackupService service;
  late Uint8List goldenBytes;
  late Map<String, List<Map<String, Object?>>> goldenDump;

  ScheduleController controller() =>
      container.read(scheduleControllerProvider.notifier);
  ScheduleState state() => container.read(scheduleControllerProvider);

  void paint(CivilDate day, String shiftId) {
    controller()
      ..beginStroke(PaintTool.replace(shiftId))
      ..paintDay(day)
      ..endStroke();
  }

  RestoreCoordinator coordinator({
    Future<void> Function(PendingRestore pending)? restore,
  }) {
    final base = RestoreCoordinator.fromRef(
      container.read(_refProvider),
      service,
    );
    return RestoreCoordinator(
      runExclusive: base.runExclusive,
      restore: restore ?? base.restore,
      reloadSchedule: base.reloadSchedule,
      reloadHolidays: base.reloadHolidays,
      reloadCalendars: base.reloadCalendars,
      resyncAlarms: base.resyncAlarms,
      reloadPostNight: base.reloadPostNight,
    );
  }

  Future<void> expectStateIsStored() async {
    final stored = await storage.repository.load(mainCalendarId);
    expectSameSchedule(state().schedule, stored.schedule);
    expect(state().palette, stored.palette);
  }

  setUp(() async {
    storage = await TestStorage.open(now: _now);
    addTearDown(storage.close);
    probe = ProbeRepository(
      storage.database,
      now: () => _now,
      // Slow enough for the restore to be asked for while a write is queued.
      delay: (call) => const Duration(milliseconds: 80),
    );
    container = ProviderContainer(
      overrides: [
        ...storage.overrides,
        clockProvider.overrideWithValue(() => _now),
        scheduleRepositoryProvider.overrideWithValue(probe),
      ],
    );
    addTearDown(() async {
      await controller().pendingWrites;
      container.dispose();
    });

    final dir = makeTempDir('restore-coordinator');
    service = BackupService(
      repository: makeRepository(
        storage.database,
        Directory(p.join(dir.path, 'safety')),
      ),
      store: LocalFileBackupStore(Directory(p.join(dir.path, 'store'))),
      appVersion: testAppVersion,
      now: () => DateTime.utc(2026, 11, 10, 9),
    );

    // What the database must look like after restoring the golden file.
    final reference = openMemoryDatabase();
    addTearDown(reference.close);
    await seedDatabase(reference, buildGoldenBackupData());
    goldenDump = await dumpAllTables(reference);
    goldenBytes = const BackupCodec().encode(
      buildGoldenBackupData(),
      appVersion: testAppVersion,
      exportedAt: DateTime.utc(2026, 11, 10, 9),
    );
  });

  test('a write still queued when the restore starts cannot land on top '
      'of the restored data', () async {
    paint(_today.addDays(5), 'guard24'); // queued, 80 ms from landing
    expect(state().canUndo, isTrue);

    final pending = await service.inspect(goldenBytes);
    await coordinator().restoreAndReload(pending);

    // The database is exactly the file...
    expect(await dumpAllTables(storage.database), goldenDump);
    // ...the controller shows it, and nothing is left to undo.
    await expectStateIsStored();
    expect(state().canUndo, isFalse);
    expect(state().canRedo, isFalse);
    expect(state().saveErrors, 0);
    // The user's write did run, before the restore.
    expect(probe.calls, hasLength(1));
  });

  test('a stroke committed while the restore runs is dropped', () async {
    final pending = await service.inspect(goldenBytes);
    final day = _today.addDays(5);
    await coordinator(
      restore: (pending) async {
        await service.restore(pending);
        // The user keeps painting on a screen that has not reloaded yet.
        paint(day, 'guard24');
      },
    ).restoreAndReload(pending);

    expect(await dumpAllTables(storage.database), goldenDump);
    expect(probe.calls, isEmpty, reason: 'it was computed against old data');
    expect(state().canUndo, isFalse);
    await expectStateIsStored();

    // The controller keeps working on the restored data.
    paint(day, 'rest');
    await controller().pendingWrites;
    expect(probe.calls, hasLength(1));
  });

  test(
    'a restore that fails changes nothing and keeps the queue going',
    () async {
      final day = _today.addDays(5);
      paint(day, 'guard24');
      final pending = await service.inspect(goldenBytes);

      await expectLater(
        coordinator(restore: (_) async => throw StateError('boom'))
            .restoreAndReload(pending),
        throwsStateError,
      );
      await controller().pendingWrites;

      // The user's write was kept: nothing was replaced.
      expect(state().schedule.resolve(day).shiftIds, ['guard24']);
      expect(state().canUndo, isTrue);
      expect(state().saveErrors, 0);
      final rows = await storage.database
          .customSelect(
            "SELECT shift_type_ids FROM day_entries WHERE date = '2026-10-24'",
          )
          .get();
      expect(rows.single.read<String>('shift_type_ids'), '["guard24"]');
      expect(probe.calls, hasLength(1));
    },
  );

  test(
    'reload adopts what the database holds and forgets the history',
    () async {
      paint(_today.addDays(5), 'guard24');
      controller()
        ..beginStroke(const PaintTool.replace('vacation')) // left open
        ..paintDay(_today.addDays(6));
      expect(controller().strokeActive, isTrue);

      // Someone else rewrites the database behind the controller's back.
      await controller().pendingWrites;
      await service.restore(await service.inspect(goldenBytes));
      await controller().reload();

      expect(controller().strokeActive, isFalse);
      expect(state().canUndo, isFalse);
      expect(state().strokeDays, isEmpty);
      await expectStateIsStored();
      // Undo has nothing left to undo and writes nothing.
      final calls = probe.calls.length;
      controller().undo();
      await controller().pendingWrites;
      expect(probe.calls, hasLength(calls));
    },
  );

  test('holidays are read again: the restored ones show up', () async {
    container.read(holidayControllerProvider); // starts its first load
    await container.read(holidayControllerProvider.notifier).reload();
    final golden = buildGoldenBackupData();
    final restoredDates = {for (final h in golden.holidays) h.date};
    expect(
      container.read(holidaysProvider).keys,
      isNot(containsAll(restoredDates)),
    );

    final pending = await service.inspect(goldenBytes);
    await coordinator().restoreAndReload(pending);

    expect(container.read(holidaysProvider).keys, containsAll(restoredDates));
    expect(container.read(holidayControllerProvider).place.regionCode, 'ES-VC');
  });

  test('a version 2 backup brings its calendars: the one that was on screen '
      'and the list', () async {
    // The calendar list was already on screen with just `main`.
    expect(
      (await container.read(calendarsControllerProvider.future)).calendars,
      hasLength(1),
    );
    final bytes = const BackupCodec().encode(
      buildGoldenBackupDataV2(),
      appVersion: testAppVersion,
      exportedAt: goldenV2ExportedAt,
    );

    await coordinator().restoreAndReload(await service.inspect(bytes));

    // `calendars.active` travelled in the settings: Pareja is on screen.
    expect(state().calendarId, 'cal-pareja');
    expect(state().schedule.runs.map((r) => r.id), ['run-4', 'run-5']);
    final calendars = await container.read(calendarsControllerProvider.future);
    expect(calendars.calendars.map((c) => c.id), ['main', 'cal-pareja']);
    expect(calendars.primaryId, 'main');
    final stored = await storage.repository.load('cal-pareja');
    expectSameSchedule(state().schedule, stored.schedule);
    expect(state().canUndo, isFalse);
  });

  test(
    'export and restore reloads more than ten calendars and their selection',
    () async {
      final repo = CalendarsRepository(storage.database);
      final created = <Calendar>[];
      for (var i = 1; i <= 12; i++) {
        created.add(await repo.create(name: 'C$i', colorValue: i));
      }
      await repo.setActive(created.last.id);
      await repo.setPrimary(created[10].id);
      final before = await repo.list();
      final bytes = await service.exportBytes();
      // Make the visible list stale, then restore through the real coordinator.
      await repo.archive(created.last.id);
      container.invalidate(calendarsControllerProvider);
      expect(
        (await container.read(calendarsControllerProvider.future)).calendars,
        hasLength(12),
      );

      await coordinator().restoreAndReload(await service.inspect(bytes));

      final restored = await container.read(calendarsControllerProvider.future);
      expect(restored.calendars, before);
      expect(restored.archived, isEmpty);
      expect(restored.primaryId, created[10].id);
      expect(state().calendarId, created.last.id);
      final added = await container
          .read(calendarsControllerProvider.notifier)
          .create(name: 'Otro', colorValue: 14);
      expect(
        (await container.read(calendarsControllerProvider.future)).calendars,
        [...before, added],
      );
    },
  );

  test('a version 1 backup over several calendars leaves only main and '
      'forgets which one was on screen', () async {
    final repo = CalendarsRepository(storage.database);
    final extra = await repo.create(name: 'Pareja', colorValue: 3);
    await repo.setActive(extra.id);
    await repo.setPrimary(extra.id);
    await controller().switchCalendar(extra.id);
    expect(state().calendarId, extra.id);

    // The real file the 0.1 / 0.2 releases wrote.
    final v1 = File('test/fixtures/golden_backup/golden_v1.cuadrante')
        .readAsBytesSync();
    await coordinator().restoreAndReload(await service.inspect(v1));

    expect(state().calendarId, 'main');
    expect(await repo.activeId(), 'main');
    expect(await repo.primaryId(), 'main');
    expect((await repo.list(includeArchived: true)).map((c) => c.id), ['main']);
    expect(await dumpAllTables(storage.database), goldenDump);
    final calendars = await container.read(calendarsControllerProvider.future);
    expect(calendars.calendars.map((c) => c.id), ['main']);
  });

  test('"Saliente automático" is read again, in both directions', () async {
    final real = RestoreCoordinator.fromRef(
      container.read(_refProvider),
      service,
    );
    await container.read(postNightAutoProvider.notifier).set(true);
    expect(container.read(postNightAutoProvider), isTrue);

    // The real version 1 file has no `postNight.auto`: back to off.
    final v1 = File('test/fixtures/golden_backup/golden_v1.cuadrante')
        .readAsBytesSync();
    await real.restoreAndReload(await service.inspect(v1));
    expect(container.read(postNightAutoProvider), isFalse);

    // A file that was exported with it on turns it on.
    final golden = buildGoldenBackupData();
    final on = BackupData(
      calendars: golden.calendars,
      shiftTypes: golden.shiftTypes,
      patterns: golden.patterns,
      patternRuns: golden.patternRuns,
      dayEntries: golden.dayEntries,
      holidays: golden.holidays,
      absenceBalances: golden.absenceBalances,
      settings: {...golden.settings, postNightAutoKey: 'true'},
    );
    final bytes = const BackupCodec().encode(
      on,
      appVersion: testAppVersion,
      exportedAt: DateTime.utc(2026, 11, 10, 9),
    );
    await real.restoreAndReload(await service.inspect(bytes));
    expect(container.read(postNightAutoProvider), isTrue);
  });

  test(
    'a restore marks the first-use flow as done and reads the tip again',
    () async {
      final onboarding = container.read(onboardingRepositoryProvider);
      // A fresh device: the flow was never done, and the file says nothing
      // about it (an older file, or one made on another phone).
      expect(await onboarding.isDone(), isFalse);
      container.read(onboardingTipProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(onboardingTipProvider), isFalse);
      // The tip is waiting in the database (the provider has not heard of it).
      await onboarding.setTipPending(true);
      expect(container.read(onboardingTipProvider), isFalse);

      final real = RestoreCoordinator.fromRef(
        container.read(_refProvider),
        service,
      );
      await real.restoreAndReload(await service.inspect(goldenBytes));

      expect(await onboarding.isDone(), isTrue);
      expect(
        await onboarding.resolve(demo: false, force: false),
        const OnboardingStatus(tipPending: true),
        reason: 'no first-use flow after a restore',
      );
      expect(container.read(onboardingTipProvider), isTrue);
    },
  );

  test('every step runs, in order, and a failing refresh does not stop '
      'the others', () async {
    final log = <String>[];
    final pending = await service.inspect(goldenBytes);
    final c = RestoreCoordinator(
      runExclusive: (action) async {
        log.add('exclusive');
        await action();
      },
      restore: (_) async => log.add('restore'),
      reloadSchedule: () async => log.add('schedule'),
      reloadHolidays: () async {
        log.add('holidays');
        throw StateError('x');
      },
      resyncAlarms: () async => log.add('alarms'),
      resyncWidget: () async => log.add('widget'),
    );
    await c.restoreAndReload(pending);
    expect(log, [
      'exclusive',
      'restore',
      'schedule',
      'holidays',
      'alarms',
      'widget',
    ]);
  });
}
