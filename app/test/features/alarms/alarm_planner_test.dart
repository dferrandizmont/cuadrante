import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/alarms/domain/alarm_strings.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

const _strings = AlarmStrings(
  title: _title,
  body: _body,
  channelName: 'Alarmas de turno',
  channelDescription: 'Descripción',
  dayBeforeTitle: _dayBeforeTitle,
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
String _dayBeforeTitle(String name, String start) =>
    'Mañana: turno de $name a las $start';
String _body(String name, String start, String end) =>
    '$name: de $start a $end';

ShiftType _type(String id, String name, int startH, int endH, {int m = 0}) =>
    ShiftType(
      id: id,
      code: id.substring(0, 1).toUpperCase(),
      name: name,
      colorValue: 0xFF336699,
      category: ShiftCategory.work,
      startMinute: startH * 60 + m,
      endMinute: endH * 60,
    );

final _night = _type('night', 'Noche', 22, 6);
final _morning = _type('morning', 'Mañana', 6, 14);
final _afternoon = _type('afternoon', 'Tarde', 14, 22);
final _early = _type('early', 'Madrugón', 0, 8, m: 30);
const _free = ShiftType(
  id: 'free',
  code: 'L',
  name: 'Libre',
  colorValue: 0xFFCCCCCC,
  category: ShiftCategory.rest,
);

const _today = CivilDate(2026, 10, 19);

/// Every day listed gets exactly the given shift types (as overrides).
Schedule _schedule(Map<CivilDate, List<String>> days) => Schedule(
  shiftTypes: [_night, _morning, _afternoon, _early, _free],
  entries: {
    for (final e in days.entries)
      e.key: DayEntry(date: e.key, shiftTypeIds: e.value),
  },
);

AlarmSettings _on(Map<String, int> leads, {int horizon = 14, String? label}) =>
    AlarmSettings(
      enabled: true,
      horizonDays: horizon,
      byShiftType: {
        for (final e in leads.entries)
          e.key: AlarmTypeSettings(
            enabled: true,
            minutesBefore: e.value,
            label: label,
          ),
      },
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
  test('one alarm per enabled shift, with title, body and fire time', () {
    final alarms = _plan(
      _schedule({
        _today.addDays(1): ['night'],
      }),
      _on({'night': 90}),
    );
    expect(alarms, hasLength(1));
    final a = alarms.single;
    expect(a.title, 'Turno de Noche a las 22:00');
    expect(a.body, 'Noche: de 22:00 a 06:00');
    expect(a.shiftDate, _today.addDays(1));
    expect(a.fireDate, _today.addDays(1));
    expect(a.fireMinute, 20 * 60 + 30);
    expect(a.shiftTypeId, 'night');
    expect(a.payload, startsWith(alarmPayloadPrefix));
  });

  test('a custom label replaces the title only', () {
    final a = _plan(
      _schedule({
        _today.addDays(1): ['night'],
      }),
      _on({'night': 60}, label: '  A trabajar  '),
    ).single;
    expect(a.title, 'A trabajar');
    expect(a.body, 'Noche: de 22:00 a 06:00');
  });

  test('disabled: global switch off, type off, or type never configured', () {
    final schedule = _schedule({
      _today.addDays(1): ['night'],
      _today.addDays(2): ['morning'],
    });
    final on = _on({'night': 60});
    expect(_plan(schedule, on), hasLength(1));
    expect(_plan(schedule, on.copyWith(enabled: false)), isEmpty);
    expect(_plan(schedule, AlarmSettings.disabled), isEmpty);
    expect(
      _plan(
        schedule,
        on.withShiftType('night', const AlarmTypeSettings(enabled: false)),
      ),
      isEmpty,
    );
    // 'morning' has no settings at all: only 'night' rings.
    expect(_plan(schedule, on).map((a) => a.shiftTypeId), ['night']);
  });

  test('shifts without times are skipped', () {
    final alarms = _plan(
      _schedule({
        _today.addDays(1): ['free'],
      }),
      _on({'free': 60}),
    );
    expect(alarms, isEmpty);
  });

  test('past alarms are skipped, the same minute is already past', () {
    final schedule = _schedule({
      _today: ['afternoon'], // 14:00, lead 60 -> 13:00 today
      _today.addDays(1): ['afternoon'],
    });
    final settings = _on({'afternoon': 60});
    // At 12:00 the 13:00 alarm of today is still ahead...
    expect(_plan(schedule, settings), hasLength(2));
    // ...at 13:00 sharp or later it is not.
    expect(
      _plan(schedule, settings, now: DateTime(2026, 10, 19, 13)),
      hasLength(1),
    );
    expect(
      _plan(schedule, settings, now: DateTime(2026, 10, 19, 13, 0, 30)),
      hasLength(1),
    );
    expect(
      _plan(schedule, settings, now: DateTime(2026, 10, 19, 12, 59)),
      hasLength(2),
    );
  });

  test('an early shift rings the previous day', () {
    final a = _plan(
      _schedule({
        _today.addDays(1): ['early'], // 00:30, 90 min before = 23:00
      }),
      _on({'early': 90}),
    ).single;
    expect(a.shiftDate, _today.addDays(1));
    expect(a.fireDate, _today);
    expect(a.fireMinute, 23 * 60);
  });

  test('lead longer than a day crosses two midnights', () {
    final a = _plan(
      _schedule({
        _today.addDays(3): ['morning'], // 06:00 minus 24 h
      }),
      _on({'morning': 1440}),
    ).single;
    expect(a.fireDate, _today.addDays(2));
    expect(a.fireMinute, 6 * 60);
  });

  test('an early shift on the first day beyond the horizon can still ring '
      'inside it', () {
    // Horizon 3 days from 12:00 of day 0 ends at 12:00 of day 3. The 00:30
    // shift of day 4 rings at 23:00 of day 3: outside. The one of day 3
    // rings at 23:00 of day 2: inside.
    final schedule = _schedule({
      _today.addDays(3): ['early'],
      _today.addDays(4): ['early'],
    });
    final alarms = _plan(schedule, _on({'early': 90}, horizon: 3));
    expect(alarms.map((a) => a.shiftDate), [_today.addDays(3)]);
  });

  test('horizon: alarms after now + horizonDays are dropped', () {
    final schedule = _schedule({
      for (var i = 0; i <= 20; i++) _today.addDays(i): ['afternoon'],
    });
    final alarms = _plan(schedule, _on({'afternoon': 60}));
    // Alarms at 13:00 of day 0..14: the one of day 14 is 13:00 > 12:00+14d.
    expect(alarms.first.shiftDate, _today);
    expect(alarms.last.shiftDate, _today.addDays(13));
    expect(alarms, hasLength(14));
    expect(_plan(schedule, _on({'afternoon': 60}, horizon: 3)), hasLength(3));
  });

  test('multi-shift days produce one alarm per shift, in time order', () {
    final alarms = _plan(
      _schedule({
        _today.addDays(1): ['afternoon', 'morning'],
      }),
      _on({'morning': 60, 'afternoon': 60}),
    );
    expect(alarms.map((a) => a.shiftTypeId), ['morning', 'afternoon']);
    expect(alarms.map((a) => a.fireMinute), [5 * 60, 13 * 60]);
    expect(alarms.map((a) => a.id).toSet(), hasLength(2));
  });

  test('the same shift twice on a day still gets distinct ids', () {
    final alarms = _plan(
      _schedule({
        _today.addDays(1): ['morning', 'morning'],
      }),
      _on({'morning': 60}),
    );
    expect(alarms, hasLength(2));
    expect(alarms[0].id, isNot(alarms[1].id));
  });

  test('a midnight-crossing shift rings for its start only', () {
    final alarms = _plan(
      _schedule({
        _today.addDays(1): ['night'],
        _today.addDays(2): ['night'],
      }),
      _on({'night': 30}),
    );
    expect(alarms, hasLength(2));
    expect(alarms.map((a) => a.fireDate), [
      _today.addDays(1),
      _today.addDays(2),
    ]);
    expect(alarms.every((a) => a.fireMinute == 21 * 60 + 30), isTrue);
    // 24 h guard: 08:00-08:00 body shows both ends.
    final guard = ShiftType(
      id: 'g',
      code: 'G',
      name: 'Guardia',
      colorValue: 0xFF000000,
      category: ShiftCategory.work,
      startMinute: 8 * 60,
      endMinute: 8 * 60,
    );
    final g = planAlarms(
      schedule: Schedule(
        shiftTypes: [guard],
        entries: {
          _today.addDays(1): DayEntry(
            date: _today.addDays(1),
            shiftTypeIds: const ['g'],
          ),
        },
      ),
      settings: _on({'g': 60}),
      now: DateTime(2026, 10, 19, 12),
      strings: _strings,
    ).single;
    expect(g.body, 'Guardia: de 08:00 a 08:00');
  });

  test('sorted by fire time and capped at 60, keeping the soonest', () {
    final schedule = _schedule({
      for (var i = 0; i < 30; i++)
        _today.addDays(i): ['night', 'morning', 'afternoon'],
    });
    final settings = _on({
      'morning': 60,
      'afternoon': 60,
      'night': 60,
    }, horizon: 30);
    final alarms = _plan(schedule, settings);
    expect(alarms, hasLength(maxPendingAlarms));
    expect(maxPendingAlarms, 60);
    final walls = alarms.map((a) => a.wallMinutes).toList();
    expect(walls, [...walls]..sort());
    // Day 0 at 12:00: the 05:00 alarm is past, 13:00 and 21:00 are not.
    expect(alarms.first.shiftTypeId, 'afternoon');
    expect(alarms.first.shiftDate, _today);
    // 2 (day 0) + 3 x 19 (days 1-19) = 59, so the 60th is the 05:00 of day 20
    // and everything later is cut.
    expect(alarms.last.shiftDate, _today.addDays(20));
    expect(alarms.last.shiftTypeId, 'morning');
    // Fewer days than the cap: nothing is cut.
    expect(_plan(schedule, settings.copyWith(horizonDays: 5)), hasLength(15));
  });

  test('ids are stable across runs and independent of other days', () {
    final a = _plan(
      _schedule({
        _today.addDays(1): ['night'],
        _today.addDays(2): ['night'],
      }),
      _on({'night': 90}),
    );
    final b = _plan(
      _schedule({
        _today.addDays(2): ['night'],
      }),
      _on({'night': 30}),
      now: DateTime(2026, 10, 19, 18, 45),
    );
    expect(
      _plan(
        _schedule({
          _today.addDays(1): ['night'],
          _today.addDays(2): ['night'],
        }),
        _on({'night': 90}),
      ),
      a,
    );
    // Same shift (day + type + index) = same id, whatever the lead or "now".
    expect(b.single.id, a[1].id);
    expect(a[0].id, isNot(a[1].id));
    for (final alarm in a) {
      expect(alarm.id, inInclusiveRange(0, 0x7FFFFFFF));
    }
  });

  test('alarmIdFor is a fixed function of its inputs', () {
    // Pinned values: changing the hash would orphan alarms already scheduled
    // on users' phones until the next resync, so do it on purpose only.
    expect(alarmIdFor(const CivilDate(2026, 10, 20), 'night', 0), 159376750);
    expect(
      alarmIdFor(const CivilDate(2026, 10, 20), 'night', 1),
      isNot(alarmIdFor(const CivilDate(2026, 10, 20), 'night', 0)),
    );
  });

  test('settings round trip through JSON and clamp bad values', () {
    final settings = AlarmSettings(
      enabled: true,
      horizonDays: 10,
      byShiftType: {
        'night': const AlarmTypeSettings(
          enabled: true,
          minutesBefore: 45,
          label: 'Noche',
        ),
      },
    );
    expect(AlarmSettings.fromJson(settings.toJson()), settings);
    final odd = AlarmSettings.fromJson({
      'enabled': 'yes',
      'horizonDays': 9999,
      'types': {
        'a': {'enabled': true, 'minutesBefore': -5},
        'b': 'junk',
        'c': {'enabled': true, 'minutesBefore': 'x', 'label': 3},
      },
    });
    expect(odd.enabled, isFalse);
    expect(odd.horizonDays, AlarmSettings.maxHorizonDays);
    expect(odd.forShiftType('a').minutesBefore, 0);
    expect(odd.forShiftType('b'), AlarmTypeSettings.off);
    expect(
      odd.forShiftType('c').minutesBefore,
      AlarmTypeSettings.defaultMinutesBefore,
    );
    expect(odd.forShiftType('c').label, isNull);
  });

  group('absences never ring', () {
    // A sick-leave type that someone gave a time range (the form allows it).
    const sickLeave = ShiftType(
      id: 'sick',
      code: 'B',
      name: 'Baja',
      colorValue: 0xFFCC3333,
      category: ShiftCategory.absence,
      startMinute: 8 * 60,
      endMinute: 15 * 60,
    );
    final schedule = Schedule(
      shiftTypes: [_night, sickLeave],
      entries: {
        _today.addDays(1): DayEntry(
          date: _today.addDays(1),
          shiftTypeIds: const ['sick'],
        ),
        _today.addDays(2): DayEntry(
          date: _today.addDays(2),
          shiftTypeIds: const ['night'],
        ),
      },
    );
    final settings = AlarmSettings(
      enabled: true,
      byShiftType: {
        'sick': const AlarmTypeSettings(enabled: true, dayBefore: true),
        'night': const AlarmTypeSettings(enabled: true, dayBefore: true),
      },
    );

    test('an absence with times and its switch on makes no alarm at all', () {
      final alarms = _plan(schedule, settings);
      expect(alarms.where((a) => a.shiftTypeId == 'sick'), isEmpty);
      // The work shift beside it still rings (before and the evening before).
      expect(alarms.map((a) => a.shiftTypeId).toSet(), {'night'});
      expect(alarms, hasLength(2));
    });

    test('a plan with only absences is empty and has no next alarm', () {
      final onlySick = Schedule(
        shiftTypes: [sickLeave],
        entries: {
          _today.addDays(1): DayEntry(
            date: _today.addDays(1),
            shiftTypeIds: const ['sick'],
          ),
        },
      );
      expect(_plan(onlySick, settings), isEmpty);
      expect(
        nextAlarm(
          schedule: onlySick,
          settings: settings,
          now: DateTime(2026, 10, 19, 12),
        ),
        isNull,
      );
    });
  });

  group('nextAlarm is strictly after now (H-T11-7)', () {
    // Night on the 19th and 20th, 90 min before: alarms at 20:30 each day.
    final schedule = _schedule({
      _today: ['night'],
      _today.addDays(1): ['night'],
    });
    final settings = _on({'night': 90});

    PlannedAlarm? next(DateTime now) =>
        nextAlarm(schedule: schedule, settings: settings, now: now);

    test('before the alarm minute it is that alarm', () {
      final a = next(DateTime(2026, 10, 19, 20, 29, 59))!;
      expect(a.fireDate, _today);
      expect(a.fireMinute, 20 * 60 + 30);
    });

    test('in the very minute the alarm rang, it already counts as past', () {
      for (final now in [
        DateTime(2026, 10, 19, 20, 30),
        DateTime(2026, 10, 19, 20, 30, 44),
        DateTime(2026, 10, 19, 20, 30, 59, 999),
      ]) {
        final a = next(now)!;
        expect(a.fireDate, _today.addDays(1), reason: '$now');
        expect(a.fireMinute, 20 * 60 + 30, reason: '$now');
      }
    });
  });
}
