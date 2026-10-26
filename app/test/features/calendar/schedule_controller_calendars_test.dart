import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/config.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/probes.dart';
import '../../support/test_storage.dart';

final _now = DateTime(2026, 10, 19, 12);
const _today = CivilDate(2026, 10, 19);

/// The controller on the active calendar, and switching to another one.
void main() {
  late TestStorage storage;
  late ProviderContainer container;
  late CalendarsRepository calendars;
  late ScheduleRepository schedules;
  late String other; // a second calendar with its own content

  ScheduleController controller() =>
      container.read(scheduleControllerProvider.notifier);
  ScheduleState state() => container.read(scheduleControllerProvider);

  void paint(PaintTool tool, Iterable<CivilDate> days) {
    final c = controller()..beginStroke(tool);
    for (final d in days) {
      c.paintDay(d);
    }
    c.endStroke();
  }

  ProviderContainer makeContainer({List<Override> extra = const []}) {
    final c = ProviderContainer(
      overrides: [
        ...storage.overrides,
        clockProvider.overrideWithValue(() => _now),
        ...extra,
      ],
    );
    addTearDown(() async {
      await c.read(scheduleControllerProvider.notifier).pendingWrites;
      c.dispose();
    });
    return c;
  }

  setUp(() async {
    storage = await TestStorage.open(now: _now);
    addTearDown(storage.close);
    calendars = CalendarsRepository(storage.database);
    schedules = ScheduleRepository(storage.database, now: () => _now);
    other = (await calendars.create(name: 'Pareja', colorValue: 1)).id;
    // The second calendar: one rotation and two days of its own.
    await schedules.apply(
      other,
      ScheduleChange(
        patch: EntriesPatch({
          _today.addDays(1): EntryChange(
            null,
            DayEntry(date: _today.addDays(1), shiftTypeIds: const ['rest']),
          ),
          _today.addDays(2): EntryChange(
            null,
            DayEntry(date: _today.addDays(2), note: 'cena'),
          ),
        }),
        runsAfter: [
          PatternRun(
            id: 'pareja-run',
            patternId: 'correturnos',
            startDate: _today.addDays(-10),
            seq: 50,
          ),
        ],
      ),
    );
    container = makeContainer();
  });

  group('the controller starts on the stored active calendar', () {
    test('main by default', () {
      expect(state().calendarId, 'main');
      expect(state().schedule.runs.map((r) => r.id), ['run-1']);
    });

    test('bootstrapApp loads the calendar the user left on screen', () async {
      await calendars.setActive(other);
      final boot = await bootstrapApp(
        config: const AppConfig(useDemoData: false),
        database: storage.database,
        now: () => _now,
      );
      expect(boot.schedule.calendarId, other);
      expect(boot.schedule.schedule.runs.map((r) => r.id), ['pareja-run']);
    });

    test('and main when the stored one is gone', () async {
      await calendars.setActive(other);
      await calendars.archive(other);
      final boot = await bootstrapApp(
        config: const AppConfig(useDemoData: false),
        database: storage.database,
        now: () => _now,
      );
      expect(boot.schedule.calendarId, 'main');
    });
  });

  group('switchCalendar', () {
    test('shows the other calendar and remembers it', () async {
      final mainSchedule = state().schedule;
      await controller().switchCalendar(other);

      expect(state().calendarId, other);
      expect(state().schedule.runs.map((r) => r.id), ['pareja-run']);
      expect(state().schedule.entries.keys, [
        _today.addDays(1),
        _today.addDays(2),
      ]);
      // Shift types and patterns are common.
      expect(state().schedule.shiftTypes, mainSchedule.shiftTypes);
      expect(state().schedule.patterns, mainSchedule.patterns);
      expect(state().palette, isNotEmpty);
      expect(await calendars.activeId(), other);

      await controller().switchCalendar('main');
      expect(state().calendarId, 'main');
      expect(state().schedule.runs.map((r) => r.id), ['run-1']);
      expect(await calendars.activeId(), 'main');
    });

    test('clears the undo history and the open stroke', () async {
      paint(const PaintTool.replace('vacation'), [_today]);
      expect(state().canUndo, isTrue);
      controller().beginStroke(const PaintTool.replace('vacation'));
      expect(controller().strokeActive, isTrue);

      await controller().switchCalendar(other);

      expect(controller().strokeActive, isFalse);
      expect(state().canUndo, isFalse);
      expect(state().canRedo, isFalse);
      expect(state().strokeDays, isEmpty);
      // Undo has nothing to undo: it must not touch either calendar.
      final before = state().schedule;
      controller().undo();
      expect(state().schedule, same(before));
    });

    test(
      'an edit made after the switch lands in the new calendar only',
      () async {
        await controller().switchCalendar(other);
        final day = _today.addDays(4);
        paint(const PaintTool.replace('vacation'), [day]);
        await controller().pendingWrites;

        expect(
          (await schedules.load(other)).schedule.entries[day]?.shiftTypeIds,
          ['vacation'],
        );
        expect((await schedules.load('main')).schedule.entries[day], isNull);
      },
    );

    test(
      'undo and redo after the switch also stay in the new calendar',
      () async {
        await controller().switchCalendar(other);
        final day = _today.addDays(4);
        paint(const PaintTool.replace('vacation'), [day]);
        controller().undo();
        await controller().pendingWrites;
        expect((await schedules.load(other)).schedule.entries[day], isNull);
        controller().redo();
        await controller().pendingWrites;
        expect(
          (await schedules.load(other)).schedule.entries[day]?.shiftTypeIds,
          ['vacation'],
        );
        expect((await schedules.load('main')).schedule.entries[day], isNull);
      },
    );

    test('a change made just before the switch is still saved where it was made', () async {
      final day = _today.addDays(4);
      paint(const PaintTool.replace('vacation'), [day]);
      // No await in between: the write is still queued when the switch starts.
      await controller().switchCalendar(other);
      await controller().pendingWrites;

      expect(
        (await schedules.load('main')).schedule.entries[day]?.shiftTypeIds,
        ['vacation'],
        reason: 'saved in main',
      );
      expect((await schedules.load(other)).schedule.entries[day], isNull);
      expect(state().calendarId, other);
    });

    test(
      'an unknown or archived calendar is refused and nothing changes',
      () async {
        final before = state();
        await expectLater(
          controller().switchCalendar('ghost'),
          throwsA(isA<CalendarNotFound>()),
        );
        await calendars.archive(other);
        await expectLater(
          controller().switchCalendar(other),
          throwsA(isA<CalendarNotFound>()),
        );
        expect(state().calendarId, 'main');
        expect(state().schedule, same(before.schedule));
        expect(await calendars.activeId(), 'main');
      },
    );

    test('the calendar already shown is a no-op', () async {
      paint(const PaintTool.replace('vacation'), [_today]);
      final before = state();
      await controller().switchCalendar('main');
      expect(state().schedule, same(before.schedule));
      expect(state().canUndo, isTrue, reason: 'history kept');
    });

    test('with two switches in flight the last one wins', () async {
      final third = await CalendarsRepository(storage.database)
          .create(name: 'Tercero', colorValue: 3);

      final first = controller().switchCalendar(other);
      final second = controller().switchCalendar(third.id);
      await Future.wait([first, second]);

      expect(state().calendarId, third.id);
      expect(await calendars.activeId(), third.id);
    });
  });

  group('reload follows the stored active calendar', () {
    test('after a restore changed it', () async {
      // Something else (a restore) made `other` the active calendar.
      await calendars.setActive(other);
      await controller().reload();
      expect(state().calendarId, other);
      expect(state().schedule.runs.map((r) => r.id), ['pareja-run']);
    });

    test('and falls back to main when it is gone', () async {
      await controller().switchCalendar(other);
      await storage.database.customStatement(
        "UPDATE calendars SET archived = 1 WHERE id = '$other'",
      );
      await controller().reload();
      expect(state().calendarId, 'main');
    });

    test('keeps the calendar on screen when it did not change', () async {
      await controller().switchCalendar(other);
      await controller().reload();
      expect(state().calendarId, other);
    });
  });

  group('a failed write recovers the calendar on screen', () {
    test('the other calendar is reloaded, not main', () async {
      final probe = ProbeRepository(
        storage.database,
        now: () => _now,
        failCalls: {0},
      );
      container = makeContainer(
        extra: [scheduleRepositoryProvider.overrideWithValue(probe)],
      );
      await container
          .read(scheduleControllerProvider.notifier)
          .switchCalendar(other);
      paint(const PaintTool.replace('vacation'), [_today.addDays(6)]);
      await controller().pendingWrites;

      expect(state().saveErrors, 1);
      expect(state().calendarId, other);
      // What is stored is what is shown: the failed write is gone.
      expect(state().schedule.entries.keys, [
        _today.addDays(1),
        _today.addDays(2),
      ]);
      expect(probe.calls.single, isNotNull);
    });
  });
}
