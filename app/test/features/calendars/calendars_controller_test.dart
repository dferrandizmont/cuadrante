import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/alarms/application/alarm_providers.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/alarms/domain/alarm_strings.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendars/application/calendars_controller.dart';
import 'package:cuadrante/features/calendars/application/primary_schedule.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';

final _now = DateTime(2026, 10, 19, 12);
const _today = CivilDate(2026, 10, 19);

const _strings = AlarmStrings(
  title: _title,
  body: _body,
  channelName: 'Alarmas',
  channelDescription: 'Descripcion',
  dayBeforeTitle: _dayBeforeTitle,
  snoozeAction: 'Posponer',
  awakeAction: 'Despierto',
  testTitle: 'Prueba',
  testBody: 'Cuerpo de prueba',
  reminderTitle: 'Recordatorio',
  reminderEmptyBody: 'Tienes un recordatorio para hoy',
  reminderChannelName: 'Recordatorios de notas',
  reminderChannelDescription: 'Descripción',
);
String _title(String name, String start) => '$name $start';
String _dayBeforeTitle(String name, String start) => 'Mañana $name $start';
String _body(String name, String start, String end) => '$name $start-$end';

const _alarmSettings = AlarmSettings(
  enabled: true,
  byShiftType: {
    'night': AlarmTypeSettings(enabled: true),
    'morning': AlarmTypeSettings(enabled: true),
  },
);

/// Creating, archiving and choosing calendars through the controller, and the
/// parts of the app that follow the **primary** calendar (alarms, widget).
void main() {
  late TestStorage storage;
  late ProviderContainer container;
  late FakeAlarmScheduler scheduler;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        ...storage.overrides,
        clockProvider.overrideWithValue(() => _now),
        alarmSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    addTearDown(() async {
      await c.read(scheduleControllerProvider.notifier).pendingWrites;
      c.dispose();
    });
    return c;
  }

  CalendarsController calendars() =>
      container.read(calendarsControllerProvider.notifier);
  ScheduleController schedule() =>
      container.read(scheduleControllerProvider.notifier);
  ScheduleState scheduleState() => container.read(scheduleControllerProvider);

  Future<CalendarsState> calendarsState() =>
      container.read(calendarsControllerProvider.future);

  setUp(() async {
    storage = await TestStorage.open(now: _now);
    addTearDown(storage.close);
    scheduler = FakeAlarmScheduler();
    container = makeContainer();
  });

  group('CalendarsController', () {
    test('starts with main, which is also the primary', () async {
      final s = await calendarsState();
      expect(s.calendars.map((c) => c.id), ['main']);
      expect(s.primaryId, 'main');
    });

    test('creates and recovers more than ten calendars', () async {
      final created = <Calendar>[];
      for (var i = 1; i <= 12; i++) {
        created.add(await calendars().create(name: 'C$i', colorValue: i));
      }
      expect((await calendarsState()).calendars, hasLength(13));

      for (final calendar in created) {
        await calendars().archive(calendar.id);
      }
      expect((await calendarsState()).calendars, hasLength(1));
      expect((await calendarsState()).archived, hasLength(12));

      for (final calendar in created) {
        await calendars().restore(calendar.id);
      }
      expect((await calendarsState()).calendars.map((c) => c.id), [
        'main',
        ...created.map((c) => c.id),
      ]);
      expect((await calendarsState()).archived, isEmpty);
    });

    test('rename and recolor show up in the list', () async {
      final c = await calendars().create(name: 'Pareja', colorValue: 7);
      await calendars().rename(c.id, 'Marta');
      await calendars().recolor(c.id, 0xFF00FF00);
      final listed = (await calendarsState()).calendars.last;
      expect(listed.name, 'Marta');
      expect(listed.colorValue, 0xFF00FF00);
    });

    test('archiving the calendar on screen switches to the one left', () async {
      final c = await calendars().create(name: 'Pareja', colorValue: 7);
      await schedule().switchCalendar(c.id);
      expect(scheduleState().calendarId, c.id);

      await calendars().archive(c.id);

      expect(scheduleState().calendarId, 'main');
      expect((await calendarsState()).calendars.map((x) => x.id), ['main']);
    });

    test('archiving another calendar leaves the screen alone', () async {
      final c = await calendars().create(name: 'Pareja', colorValue: 7);
      final before = scheduleState().schedule;
      await calendars().archive(c.id);
      expect(scheduleState().calendarId, 'main');
      expect(scheduleState().schedule, same(before));
    });

    test('the last calendar cannot be archived', () async {
      await expectLater(
        calendars().archive('main'),
        throwsA(isA<LastCalendarCannotBeArchived>()),
      );
      expect((await calendarsState()).calendars.map((c) => c.id), ['main']);
      expect(scheduleState().calendarId, 'main');
    });

    test(
      'setPrimary changes which calendar the widget and alarms follow',
      () async {
        final c = await calendars().create(name: 'Pareja', colorValue: 7);
        await calendars().setPrimary(c.id);
        expect((await calendarsState()).primaryId, c.id);
        // The one on screen is a different thing.
        expect(scheduleState().calendarId, 'main');
      },
    );
  });

  group('readPrimarySchedule (alarms and widget)', () {
    late String other;
    late Provider<Future<Schedule>> primary;

    setUp(() async {
      other = (await calendars().create(name: 'Pareja', colorValue: 7)).id;
      primary = Provider<Future<Schedule>>(readPrimarySchedule);
    });

    Future<Schedule> readPrimary() => container.read(primary);

    test(
      'the one on screen when it is the primary: the in-memory schedule',
      () async {
        expect(await readPrimary(), same(scheduleState().schedule));
      },
    );

    test('another calendar when the primary is not on screen', () async {
      await calendars().setPrimary(other);
      final stored = await container
          .read(scheduleRepositoryProvider)
          .load(other);
      container.invalidate(primary);
      final read = await readPrimary();
      expect(read.entries, stored.schedule.entries);
      expect(read.runs, stored.schedule.runs);
      expect(read.runs, isEmpty, reason: 'not the main calendar');
    });

    test(
      'edits on the calendar on screen do not change what it reads',
      () async {
        await calendars().setPrimary(other);
        final before = (await readPrimary()).entries;

        final c = schedule()..beginStroke(const PaintTool.replace('vacation'));
        c.paintDay(_today);
        c.endStroke();
        await c.pendingWrites;
        container.invalidate(primary);

        expect((await readPrimary()).entries, before);
      },
    );

    test('when the primary is on screen its unsaved edits count', () async {
      await schedule().switchCalendar(other);
      await calendars().setPrimary(other);
      final c = schedule()..beginStroke(const PaintTool.replace('vacation'));
      c.paintDay(_today);
      c.endStroke();
      // Not awaited: the write may still be queued.
      container.invalidate(primary);
      expect((await readPrimary()).entries[_today]?.shiftTypeIds, ['vacation']);
    });
  });

  group('alarms follow the primary calendar', () {
    late String other;

    setUp(() async {
      other = (await calendars().create(name: 'Pareja', colorValue: 7)).id;
      // The second calendar works nights on its own days.
      final repo = container.read(scheduleRepositoryProvider);
      await repo.apply(
        other,
        ScheduleChange(
          patch: EntriesPatch({
            for (final i in [1, 2, 3])
              _today.addDays(i): EntryChange(
                null,
                DayEntry(
                  date: _today.addDays(i),
                  shiftTypeIds: const ['night'],
                ),
              ),
          }),
        ),
      );
      await container
          .read(alarmSettingsRepositoryProvider)
          .save(_alarmSettings);
      container.read(alarmSyncProvider).strings = _strings;
    });

    Future<List<PlannedAlarm>> expectedFor(String calendarId) async {
      final stored = await container
          .read(scheduleRepositoryProvider)
          .load(calendarId);
      return planAlarms(
        schedule: stored.schedule,
        settings: _alarmSettings,
        now: _now,
        strings: _strings,
      );
    }

    test('main is planned while another calendar is on screen', () async {
      await schedule().switchCalendar(other);
      await container.read(alarmSyncProvider).resync();

      final main = await expectedFor('main');
      final partner = await expectedFor(other);
      expect(main, isNotEmpty);
      expect(partner, isNotEmpty);
      expect(main, isNot(partner), reason: 'the calendars differ');
      expect(scheduler.scheduled, main);
    });

    test('choosing another primary plans that one', () async {
      await schedule().switchCalendar(other);
      await calendars().setPrimary(other);
      await container.read(alarmSyncProvider).resync();
      expect(scheduler.scheduled, await expectedFor(other));
    });

    test('the primary is planned even when it is not on screen', () async {
      await calendars().setPrimary(other);
      // main is on screen.
      expect(scheduleState().calendarId, 'main');
      await container.read(alarmSyncProvider).resync();
      expect(scheduler.scheduled, await expectedFor(other));
    });

    test(
      'archiving the primary moves the alarms to the calendar left',
      () async {
        await calendars().setPrimary(other);
        await container.read(alarmSyncProvider).resync();
        expect(scheduler.scheduled, await expectedFor(other));

        await calendars().archive(other);
        await container.read(alarmSyncProvider).resync();

        expect((await calendarsState()).primaryId, 'main');
        expect(scheduler.scheduled, await expectedFor('main'));
      },
    );
  });
}
