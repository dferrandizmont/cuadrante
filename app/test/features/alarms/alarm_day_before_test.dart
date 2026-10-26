import 'package:cuadrante/features/alarms/data/wall_clock.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/alarms/domain/alarm_strings.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const _strings = AlarmStrings(
  title: _title,
  body: _body,
  channelName: 'Alarmas de turno',
  channelDescription: 'Descripción',
  dayBeforeTitle: _dayBefore,
  snoozeAction: 'Posponer 10 min',
  awakeAction: 'Ya estoy despierto',
  testTitle: 'Prueba',
  testBody: 'Cuerpo de prueba',
  reminderTitle: 'Recordatorio',
  reminderEmptyBody: 'Tienes un recordatorio para hoy',
  reminderChannelName: 'Recordatorios de notas',
  reminderChannelDescription: 'Descripción',
);

String _title(String name, String start) => 'Turno de $name a las $start';
String _dayBefore(String name, String start) =>
    'Mañana: turno de $name a las $start';
String _body(String name, String start, String end) =>
    '$name: de $start a $end';

ShiftType _type(String id, String name, int startH, int endH) => ShiftType(
  id: id,
  code: id.substring(0, 1).toUpperCase(),
  name: name,
  colorValue: 0xFF336699,
  category: ShiftCategory.work,
  startMinute: startH * 60,
  endMinute: endH * 60,
);

final _night = _type('night', 'Noche', 22, 6);
final _morning = _type('morning', 'Mañana', 6, 14);
final _afternoon = _type('afternoon', 'Tarde', 14, 22);

Schedule _schedule(Map<CivilDate, List<String>> days) => Schedule(
  shiftTypes: [_night, _morning, _afternoon],
  entries: {
    for (final e in days.entries)
      e.key: DayEntry(date: e.key, shiftTypeIds: e.value),
  },
);

const _today = CivilDate(2026, 10, 19);

AlarmSettings _on(
  Map<String, AlarmTypeSettings> types, {
  int horizon = 14,
  Set<CivilDate> skipped = const {},
}) => AlarmSettings(
  enabled: true,
  horizonDays: horizon,
  byShiftType: types,
  skippedDates: skipped,
);

const _nightWithDayBefore = AlarmTypeSettings(
  enabled: true,
  minutesBefore: 90,
  dayBefore: true,
  dayBeforeMinute: 20 * 60,
);

List<PlannedAlarm> _plan(
  Schedule schedule,
  AlarmSettings settings, {
  DateTime? now,
}) => planAlarms(
  schedule: schedule,
  settings: settings,
  now: now ?? DateTime(2026, 10, 19, 12),
  strings: _strings,
);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('day-before reminders', () {
    test('ring at the fixed time of the previous day, besides the alarm', () {
      final alarms = _plan(
        _schedule({
          _today.addDays(3): ['night'],
        }),
        _on({'night': _nightWithDayBefore}),
      );
      expect(alarms.map((a) => a.kind), [AlarmKind.dayBefore, AlarmKind.shift]);
      final dayBefore = alarms.first;
      expect(dayBefore.fireDate, _today.addDays(2));
      expect(dayBefore.fireMinute, 20 * 60);
      expect(dayBefore.shiftDate, _today.addDays(3));
      expect(dayBefore.title, 'Mañana: turno de Noche a las 22:00');
      expect(dayBefore.body, 'Noche: de 22:00 a 06:00');
      expect(dayBefore.shiftName, 'Noche');
      // The alarm before the shift is the one of always.
      final shift = alarms.last;
      expect(shift.fireDate, _today.addDays(3));
      expect(shift.fireMinute, 20 * 60 + 30);
      expect(shift.title, 'Turno de Noche a las 22:00');
    });

    test('off by default: one alarm per shift, as before', () {
      final alarms = _plan(
        _schedule({
          _today.addDays(3): ['night'],
        }),
        _on({'night': const AlarmTypeSettings(enabled: true)}),
      );
      expect(alarms.map((a) => a.kind), [AlarmKind.shift]);
    });

    test('adds exactly one alarm per night of the schedule', () {
      final days = {
        for (var i = 1; i <= 5; i++) _today.addDays(i): ['night'],
      };
      final without = _plan(
        _schedule(days),
        _on({'night': const AlarmTypeSettings(enabled: true)}),
      );
      final withIt = _plan(
        _schedule(days),
        _on({'night': _nightWithDayBefore}),
      );
      expect(without, hasLength(5));
      expect(withIt, hasLength(10));
      expect(withIt.where((a) => a.kind == AlarmKind.dayBefore), hasLength(5));
    });

    test('a day-before time already past is dropped, the alarm stays', () {
      // Tomorrow's shift, reminder at 20:00 today; it is 21:00 already.
      final alarms = _plan(
        _schedule({
          _today.addDays(1): ['night'],
        }),
        _on({'night': _nightWithDayBefore}),
        now: DateTime(2026, 10, 19, 21),
      );
      expect(alarms.map((a) => a.kind), [AlarmKind.shift]);
    });

    test('the label replaces the title of the alarm, not that of the '
        'reminder', () {
      final alarms = _plan(
        _schedule({
          _today.addDays(3): ['night'],
        }),
        _on({'night': _nightWithDayBefore.copyWith(label: 'A trabajar')}),
      );
      expect(alarms.first.title, 'Mañana: turno de Noche a las 22:00');
      expect(alarms.last.title, 'A trabajar');
    });

    test('only the alarm before the shift has notification buttons', () {
      final alarms = _plan(
        _schedule({
          _today.addDays(3): ['night'],
        }),
        _on({'night': _nightWithDayBefore}),
      );
      final dayBefore = alarms.firstWhere((a) => a.kind == AlarmKind.dayBefore);
      final shift = alarms.firstWhere((a) => a.kind == AlarmKind.shift);
      expect(dayBefore.snoozeLabel, isNull);
      expect(dayBefore.awakeLabel, isNull);
      expect(shift.snoozeLabel, 'Posponer 10 min');
      expect(shift.awakeLabel, 'Ya estoy despierto');
    });

    test('the reminder of a shift just beyond the horizon rings inside it', () {
      // Horizon 3 days from 12:00 of day 0 ends at 12:00 of day 3. The
      // shift of day 4 has its reminder at 20:00 of day 3: outside. The one
      // of day 3 rings at 20:00 of day 2: inside.
      final alarms = _plan(
        _schedule({
          _today.addDays(3): ['night'],
          _today.addDays(4): ['night'],
        }),
        _on({
          'night': const AlarmTypeSettings(
            enabled: true,
            minutesBefore: 1440,
            dayBefore: true,
            dayBeforeMinute: 20 * 60,
          ),
        }, horizon: 3),
      );
      expect(
        alarms
            .where((a) => a.kind == AlarmKind.dayBefore)
            .map((a) => a.shiftDate),
        [_today.addDays(3)],
      );
    });
  });

  group('daylight saving (Europe/Madrid)', () {
    late tz.Location madrid;
    setUpAll(() => madrid = tz.getLocation('Europe/Madrid'));

    test('a 20:00 reminder keeps its local hour the night of 28/29 March', () {
      // Shifts on 29 and 30 March (Sunday and Monday): reminders on the 28th
      // (CET) and on the 29th (CEST, the day the clocks go forward).
      final alarms = planAlarms(
        schedule: _schedule({
          const CivilDate(2026, 3, 29): ['night'],
          const CivilDate(2026, 3, 30): ['night'],
        }),
        settings: _on({'night': _nightWithDayBefore}, horizon: 30),
        now: DateTime(2026, 3, 27, 12),
        strings: _strings,
      ).where((a) => a.kind == AlarmKind.dayBefore).toList();
      expect(alarms.map((a) => a.fireDate), [
        const CivilDate(2026, 3, 28),
        const CivilDate(2026, 3, 29),
      ]);
      expect(alarms.every((a) => a.fireMinute == 20 * 60), isTrue);
      final first = resolveAlarmInstant(alarms[0], madrid);
      final second = resolveAlarmInstant(alarms[1], madrid);
      expect(first.toUtc(), DateTime.utc(2026, 3, 28, 19)); // 20:00 CET
      expect(second.toUtc(), DateTime.utc(2026, 3, 29, 18)); // 20:00 CEST
      // 23 real hours between them: the day the clocks skip an hour.
      expect(second.difference(first), const Duration(hours: 23));
    });

    test('a reminder inside the skipped hour moves forward, never earlier', () {
      // 02:30 on 29 March does not exist: 03:30 CEST.
      final alarm = planAlarms(
        schedule: _schedule({
          const CivilDate(2026, 3, 30): ['night'],
        }),
        settings: _on({
          'night': _nightWithDayBefore.copyWith(dayBeforeMinute: 2 * 60 + 30),
        }, horizon: 30),
        now: DateTime(2026, 3, 27, 12),
        strings: _strings,
      ).firstWhere((a) => a.kind == AlarmKind.dayBefore);
      expect(alarm.fireDate, const CivilDate(2026, 3, 29));
      expect(alarm.fireMinute, 2 * 60 + 30);
      expect(
        resolveAlarmInstant(alarm, madrid).toUtc(),
        DateTime.utc(2026, 3, 29, 1, 30), // 03:30 CEST
      );
    });

    test(
      'a 20:00 reminder keeps its local hour the night of 24/25 October',
      () {
        final alarms = planAlarms(
          schedule: _schedule({
            const CivilDate(2026, 10, 25): ['night'],
            const CivilDate(2026, 10, 26): ['night'],
          }),
          settings: _on({'night': _nightWithDayBefore}, horizon: 30),
          now: DateTime(2026, 10, 23, 12),
          strings: _strings,
        ).where((a) => a.kind == AlarmKind.dayBefore).toList();
        expect(alarms.map((a) => a.fireDate), [
          const CivilDate(2026, 10, 24),
          const CivilDate(2026, 10, 25),
        ]);
        final first = resolveAlarmInstant(alarms[0], madrid);
        final second = resolveAlarmInstant(alarms[1], madrid);
        expect(first.toUtc(), DateTime.utc(2026, 10, 24, 18)); // 20:00 CEST
        expect(second.toUtc(), DateTime.utc(2026, 10, 25, 19)); // 20:00 CET
        expect(second.difference(first), const Duration(hours: 25));
      },
    );

    test('a reminder inside the repeated hour uses the first occurrence', () {
      // 02:30 on 25 October happens twice: the first one, 02:30 CEST.
      final alarm = planAlarms(
        schedule: _schedule({
          const CivilDate(2026, 10, 26): ['night'],
        }),
        settings: _on({
          'night': _nightWithDayBefore.copyWith(dayBeforeMinute: 2 * 60 + 30),
        }, horizon: 30),
        now: DateTime(2026, 10, 23, 12),
        strings: _strings,
      ).firstWhere((a) => a.kind == AlarmKind.dayBefore);
      expect(alarm.fireDate, const CivilDate(2026, 10, 25));
      expect(
        resolveAlarmInstant(alarm, madrid).toUtc(),
        DateTime.utc(2026, 10, 25, 0, 30), // 02:30 CEST
      );
    });

    test('the alarm before a night shift keeps 20:30 on 24 and 25 October', () {
      final alarms = planAlarms(
        schedule: _schedule({
          const CivilDate(2026, 10, 24): ['night'],
          const CivilDate(2026, 10, 25): ['night'],
        }),
        settings: _on({'night': _nightWithDayBefore}, horizon: 30),
        now: DateTime(2026, 10, 23, 12),
        strings: _strings,
      ).where((a) => a.kind == AlarmKind.shift).toList();
      expect(alarms.every((a) => a.fireMinute == 20 * 60 + 30), isTrue);
      expect(
        resolveAlarmInstant(alarms[0], madrid).toUtc(),
        DateTime.utc(2026, 10, 24, 18, 30),
      );
      expect(
        resolveAlarmInstant(alarms[1], madrid).toUtc(),
        DateTime.utc(2026, 10, 25, 19, 30),
      );
    });
  });

  group('skipped days', () {
    final schedule = _schedule({
      for (var i = 1; i <= 4; i++) _today.addDays(i): ['night'],
    });

    test('a skipped day makes no alarm of any kind', () {
      final settings = _on(
        {'night': _nightWithDayBefore},
        skipped: {_today.addDays(2)},
      );
      final alarms = _plan(schedule, settings);
      expect(alarms.map((a) => a.shiftDate).toSet(), {
        _today.addDays(1),
        _today.addDays(3),
        _today.addDays(4),
      });
      // 3 days x (alarm + reminder): nothing of the skipped one, neither the
      // alarm of its own day nor the reminder of the evening before.
      expect(alarms, hasLength(6));
    });

    test('un-skipping brings the alarms back, the rest is untouched', () {
      final skipped = _on(
        {'night': _nightWithDayBefore},
        skipped: {_today.addDays(2)},
      );
      final before = _plan(schedule, skipped);
      final after = _plan(
        schedule,
        skipped.withSkipped(_today.addDays(2), skipped: false),
      );
      expect(after, hasLength(8));
      expect(after.where((a) => !before.contains(a)).map((a) => a.shiftDate), [
        _today.addDays(2),
        _today.addDays(2),
      ]);
      expect(before.every(after.contains), isTrue);
    });

    test('skipping a day only removes the alarms of its shifts', () {
      final alarms = _plan(
        _schedule({
          _today.addDays(1): ['night'],
          _today.addDays(2): ['morning'],
        }),
        _on(
          {
            'night': const AlarmTypeSettings(enabled: true),
            'morning': const AlarmTypeSettings(enabled: true),
          },
          skipped: {_today.addDays(1)},
        ),
      );
      expect(alarms.map((a) => a.shiftTypeId), ['morning']);
    });

    test('skipping a day with no shift (or an old day) changes nothing', () {
      final plain = _plan(
        schedule,
        _on({'night': const AlarmTypeSettings(enabled: true)}),
      );
      final skipped = _plan(
        schedule,
        _on(
          {'night': const AlarmTypeSettings(enabled: true)},
          skipped: {_today.addDays(10), _today.addDays(-5)},
        ),
      );
      expect(skipped, plain);
    });
  });

  group('ids', () {
    test('are unique across kinds, days, shifts and types', () {
      final days = {
        for (var i = 0; i < 30; i++)
          _today.addDays(i): ['night', 'morning', 'afternoon'],
      };
      const everything = AlarmTypeSettings(
        enabled: true,
        minutesBefore: 60,
        dayBefore: true,
      );
      final alarms = planAlarms(
        schedule: _schedule(days),
        settings: _on({
          'night': everything,
          'morning': everything,
          'afternoon': everything,
        }, horizon: 30),
        now: DateTime(2026, 10, 19, 12),
        strings: _strings,
      );
      expect(alarms.map((a) => a.id).toSet(), hasLength(alarms.length));
    });

    test('the same shift gets different ids per kind, each deterministic', () {
      const day = CivilDate(2026, 10, 20);
      final shift = alarmIdFor(day, 'night', 0);
      final dayBefore = alarmIdFor(day, 'night', 0, AlarmKind.dayBefore);
      expect(dayBefore, isNot(shift));
      expect(alarmIdFor(day, 'night', 0, AlarmKind.dayBefore), dayBefore);
      // Pinned: the ids of the alarms before a shift are the ones of always.
      expect(shift, 159376750);
      expect(dayBefore, inInclusiveRange(0, 0x7FFFFFFF));
    });

    test('planning twice gives the same ids', () {
      final schedule = _schedule({
        _today.addDays(2): ['night'],
        _today.addDays(3): ['night'],
      });
      final settings = _on({'night': _nightWithDayBefore});
      expect(
        _plan(schedule, settings).map((a) => a.id),
        _plan(schedule, settings).map((a) => a.id),
      );
    });
  });

  group('cap', () {
    test('60 at most with both kinds, soonest first', () {
      final days = {
        for (var i = 0; i < 30; i++) _today.addDays(i): ['night', 'afternoon'],
      };
      const both = AlarmTypeSettings(
        enabled: true,
        minutesBefore: 60,
        dayBefore: true,
      );
      final alarms = _plan(
        _schedule(days),
        _on({'night': both, 'afternoon': both}, horizon: 30),
      );
      expect(alarms, hasLength(maxPendingAlarms));
      final walls = alarms.map((a) => a.wallMinutes).toList();
      expect(walls, [...walls]..sort());
      // Whatever was cut is later than everything that stayed.
      final all = planAlarms(
        schedule: _schedule(days),
        settings: _on({'night': both, 'afternoon': both}, horizon: 30),
        now: DateTime(2026, 10, 19, 12),
        strings: _strings,
      );
      expect(all, alarms);
    });
  });

  group('next alarm', () {
    test('is the first of the plan, day-before included', () {
      final schedule = _schedule({
        _today.addDays(2): ['night'],
        _today.addDays(3): ['night'],
      });
      final settings = _on({'night': _nightWithDayBefore});
      final next = nextAlarm(
        schedule: schedule,
        settings: settings,
        now: DateTime(2026, 10, 19, 12),
      )!;
      expect(next.kind, AlarmKind.dayBefore);
      expect(next.fireDate, _today.addDays(1));
      expect(next.fireMinute, 20 * 60);
      expect(next.shiftName, 'Noche');
    });

    test('is null when nothing will ring', () {
      expect(
        nextAlarm(
          schedule: _schedule({}),
          settings: _on({'night': _nightWithDayBefore}),
          now: DateTime(2026, 10, 19, 12),
        ),
        isNull,
      );
      expect(
        nextAlarm(
          schedule: _schedule({
            _today.addDays(2): ['night'],
          }),
          settings: AlarmSettings.disabled,
          now: DateTime(2026, 10, 19, 12),
        ),
        isNull,
      );
    });
  });
}
