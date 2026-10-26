import 'package:cuadrante/features/alarms/data/alarm_actions.dart';
import 'package:cuadrante/features/alarms/application/alarm_sync.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
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

/// 09:00-13:00 and 17:00-21:00.
const _partido = ShiftType(
  id: 'partido',
  code: 'P',
  name: 'Partido',
  colorValue: 0xFF336699,
  category: ShiftCategory.work,
  startMinute: 9 * 60,
  endMinute: 13 * 60,
  segment2StartMinute: 17 * 60,
  segment2DurationMinutes: 4 * 60,
);

/// 20:00-23:00 and 01:00-03:00 of the next day.
const _lateEarly = ShiftType(
  id: 'le',
  code: 'E',
  name: 'Nocturno partido',
  colorValue: 0xFF336699,
  category: ShiftCategory.work,
  startMinute: 20 * 60,
  endMinute: 23 * 60,
  segment2StartMinute: 60,
  segment2DurationMinutes: 2 * 60,
);

const _plain = ShiftType(
  id: 'plain',
  code: 'M',
  name: 'Mañana',
  colorValue: 0xFFF5A524,
  category: ShiftCategory.work,
  startMinute: 6 * 60,
  endMinute: 14 * 60,
);

const _today = CivilDate(2026, 10, 19);
final _tomorrow = _today.addDays(1);

Schedule _schedule(Map<CivilDate, List<String>> days) => Schedule(
  shiftTypes: [_partido, _lateEarly, _plain],
  entries: {
    for (final e in days.entries)
      e.key: DayEntry(date: e.key, shiftTypeIds: e.value),
  },
);

AlarmSettings _on(
  String id, {
  int lead = 60,
  bool secondSegment = true,
  bool dayBefore = false,
}) => AlarmSettings(
  enabled: true,
  byShiftType: {
    id: AlarmTypeSettings(
      enabled: true,
      minutesBefore: lead,
      secondSegment: secondSegment,
      dayBefore: dayBefore,
    ),
  },
);

List<PlannedAlarm> _plan(Schedule schedule, AlarmSettings settings) =>
    planAlarms(
      schedule: schedule,
      settings: settings,
      now: DateTime(2026, 10, 19, 12),
      strings: _strings,
    );

String _at(PlannedAlarm a) =>
    '${a.fireDate.toIso()} ${a.fireMinute ~/ 60}:${a.fireMinute % 60}';

void main() {
  group('AlarmTypeSettings.secondSegment', () {
    test('is on by default', () {
      expect(const AlarmTypeSettings().secondSegment, isTrue);
      expect(AlarmTypeSettings.off.secondSegment, isTrue);
    });

    test('a missing key reads as on; false is kept', () {
      expect(AlarmTypeSettings.fromJson({'enabled': true}).secondSegment, true);
      expect(
        AlarmTypeSettings.fromJson({'secondSegment': 'no'}).secondSegment,
        isTrue,
        reason: 'wrong types fall back to the default',
      );
      const off = AlarmTypeSettings(enabled: true, secondSegment: false);
      expect(off.toJson()['secondSegment'], false);
      expect(AlarmTypeSettings.fromJson(off.toJson()), off);
    });

    test('settings that never set it do not grow a new key', () {
      expect(const AlarmTypeSettings(enabled: true).toJson().keys, [
        'enabled',
        'minutesBefore',
        'dayBefore',
        'dayBeforeMinute',
      ]);
    });

    test('takes part in equality and copyWith', () {
      const a = AlarmTypeSettings();
      expect(a.copyWith(secondSegment: false), isNot(a));
      expect(a.copyWith(secondSegment: false).copyWith(secondSegment: true), a);
    });

    test('the whole settings round trip through JSON', () {
      final settings = _on('partido', secondSegment: false);
      expect(AlarmSettings.fromJson(settings.toJson()), settings);
    });
  });

  group('planner', () {
    test(
      'resync after midnight keeps yesterday second-segment alarm',
      () async {
        final scheduler = FakeAlarmScheduler();
        var now = DateTime(2026, 10, 19, 18);
        final sync = AlarmSync(
          scheduler: scheduler,
          loadSettings: () async => _on('le', lead: 30),
          readSchedule: () => _schedule({
            _today: ['le'],
          }),
          now: () => now,
          strings: _strings,
        );
        addTearDown(sync.dispose);

        await sync.resync();
        expect(scheduler.scheduled, hasLength(2));
        final second = scheduler.scheduled.singleWhere((a) => a.segment == 1);
        expect(second.fireDate, _tomorrow);
        expect(second.fireMinute, 30);

        now = DateTime(2026, 10, 20, 0, 5);
        await sync.resync();
        expect(scheduler.scheduled, [second]);

        now = DateTime(2026, 10, 20, 0, 30);
        await sync.resync();
        expect(scheduler.scheduled, isEmpty);
      },
    );

    test('a split shift rings before each segment, with the same lead', () {
      final alarms = _plan(
        _schedule({
          _tomorrow: ['partido'],
        }),
        _on('partido'),
      );
      expect(alarms, hasLength(2));
      expect(_at(alarms[0]), '2026-10-20 8:0');
      expect(alarms[0].title, 'Turno de Partido a las 09:00');
      expect(alarms[0].body, 'Partido: de 09:00 a 13:00');
      expect(_at(alarms[1]), '2026-10-20 16:0');
      expect(alarms[1].title, 'Turno de Partido a las 17:00');
      expect(alarms[1].body, 'Partido: de 17:00 a 21:00');
      // Both belong to the day the shift starts, and both can be snoozed.
      expect(alarms.map((a) => a.shiftDate), [_tomorrow, _tomorrow]);
      expect(alarms.map((a) => a.kind), [AlarmKind.shift, AlarmKind.shift]);
      expect(alarms.map((a) => a.snoozeLabel), everyElement(isNotNull));
      expect(alarms[0].id, isNot(alarms[1].id));
    });

    test('the type can opt out of the second alarm', () {
      final alarms = _plan(
        _schedule({
          _tomorrow: ['partido'],
        }),
        _on('partido', secondSegment: false),
      );
      expect(alarms, hasLength(1));
      expect(alarms.single.title, 'Turno de Partido a las 09:00');
    });

    test('the alarm of the first segment is the one of a normal shift', () {
      final split = _plan(
        _schedule({
          _tomorrow: ['partido'],
        }),
        _on('partido', secondSegment: false),
      ).single;
      expect(
        split.id,
        alarmIdFor(_tomorrow, 'partido', 0),
        reason: 'ids of the alarms before a shift do not change',
      );
    });

    test(
      'ids are stable, distinct per segment and per position in the day',
      () {
        final first = alarmIdFor(_tomorrow, 'partido', 0);
        final second = alarmIdFor(_tomorrow, 'partido', 0, AlarmKind.shift, 1);
        expect(second, isNot(first));
        expect(second, alarmIdFor(_tomorrow, 'partido', 0, AlarmKind.shift, 1));
        expect(
          alarmIdFor(_tomorrow, 'partido', 1, AlarmKind.shift, 1),
          isNot(second),
        );
        expect(
          alarmIdFor(_tomorrow, 'partido', 0, AlarmKind.dayBefore, 1),
          isNot(second),
        );
        final alarms = _plan(
          _schedule({
            _tomorrow: ['partido'],
            _today.addDays(2): ['partido'],
          }),
          _on('partido'),
        );
        expect({for (final a in alarms) a.id}, hasLength(4));
      },
    );

    test('replanning gives the same alarms (a reschedule replaces)', () {
      final schedule = _schedule({
        _tomorrow: ['partido'],
      });
      expect(_plan(schedule, _on('partido')), _plan(schedule, _on('partido')));
    });

    test('a second segment after midnight rings on the next calendar day', () {
      final alarms = _plan(
        _schedule({
          _tomorrow: ['le'],
        }),
        _on('le', lead: 90),
      );
      expect(alarms, hasLength(2));
      expect(_at(alarms[0]), '2026-10-20 18:30');
      // 01:00 of the 21st minus 90 min = 23:30 of the 20th.
      expect(_at(alarms[1]), '2026-10-20 23:30');
      expect(alarms[1].shiftDate, _tomorrow);
      expect(alarms[1].body, 'Nocturno partido: de 01:00 a 03:00');
    });

    test('a custom text replaces both titles', () {
      final settings = AlarmSettings(
        enabled: true,
        byShiftType: const {
          'partido': AlarmTypeSettings(enabled: true, label: 'A currar'),
        },
      );
      final alarms = _plan(
        _schedule({
          _tomorrow: ['partido'],
        }),
        settings,
      );
      expect(alarms.map((a) => a.title), ['A currar', 'A currar']);
    });

    test('the day-before notice stays one per shift', () {
      final alarms = _plan(
        _schedule({
          _tomorrow: ['partido'],
        }),
        _on('partido', dayBefore: true),
      );
      expect(alarms.map((a) => a.kind), [
        AlarmKind.dayBefore,
        AlarmKind.shift,
        AlarmKind.shift,
      ]);
      expect(alarms.first.title, 'Mañana: turno de Partido a las 09:00');
      expect(_at(alarms.first), '2026-10-19 20:0');
      // It does not depend on the second-segment switch.
      final off = _plan(
        _schedule({
          _tomorrow: ['partido'],
        }),
        _on('partido', dayBefore: true, secondSegment: false),
      );
      expect(off.map((a) => a.kind), [AlarmKind.dayBefore, AlarmKind.shift]);
    });

    test('a segment that already passed makes no alarm', () {
      final alarms = planAlarms(
        schedule: _schedule({
          _today: ['partido'],
        }),
        settings: _on('partido'),
        // 16:30: the 08:00 alarm is gone, the one for the 17:00 segment (at
        // 16:00) too.
        now: DateTime(2026, 10, 19, 15, 30),
        strings: _strings,
      );
      expect(_at(alarms.single), '2026-10-19 16:0');
      final later = planAlarms(
        schedule: _schedule({
          _today: ['partido'],
        }),
        settings: _on('partido'),
        now: DateTime(2026, 10, 19, 16, 30),
        strings: _strings,
      );
      expect(later, isEmpty);
    });

    test('skipping the day silences both alarms', () {
      final settings = _on('partido').copyWith(skippedDates: {_tomorrow});
      expect(
        _plan(
          _schedule({
            _tomorrow: ['partido'],
          }),
          settings,
        ),
        isEmpty,
      );
    });

    test('shifts that are not split are unchanged by the switch', () {
      final settings = AlarmSettings(
        enabled: true,
        byShiftType: const {
          'plain': AlarmTypeSettings(enabled: true, secondSegment: true),
        },
      );
      final alarms = _plan(
        _schedule({
          _tomorrow: ['plain', 'plain'],
        }),
        settings,
      );
      expect(alarms, hasLength(2), reason: 'a double shift still rings twice');
    });

    test('nextAlarm sees the second segment too', () {
      final next = nextAlarm(
        schedule: _schedule({
          _today: ['partido'],
        }),
        settings: _on('partido'),
        now: DateTime(2026, 10, 19, 10),
      );
      expect(_at(next!), '2026-10-19 16:0');
      expect(next.shiftName, 'Partido');
    });
  });

  group('snooze of a split shift', () {
    final alarms = _plan(
      _schedule({
        _tomorrow: ['partido'],
      }),
      _on('partido'),
    );

    test('the two segments carry their own segment in the payload', () {
      final first = AlarmPayload.decode(alarms[0].payload)!;
      final second = AlarmPayload.decode(alarms[1].payload)!;
      expect(alarms.map((a) => a.segment), [0, 1]);
      expect(first.segment, 0);
      expect(second.segment, 1);
      expect(second.encodeAsSnooze(), contains('"g":1'));
      expect(AlarmPayload.decode(second.encodeAsSnooze())!.segment, 1);
    });

    test('each segment snoozes under its own id', () {
      final first = AlarmPayload.decode(alarms[0].payload)!;
      final second = AlarmPayload.decode(alarms[1].payload)!;
      expect(snoozeIdFor(first), isNot(snoozeIdFor(second)));
    });

    test('the snooze id of the first segment is the one it always was', () {
      const payload = AlarmPayload(
        shiftTypeId: 'partido',
        shiftDate: CivilDate(2026, 10, 20),
        kind: AlarmKind.shift,
        title: 't',
        body: 'b',
      );
      // fnv31('snooze|2026-10-20|partido|shift'), pinned.
      expect(snoozeIdFor(payload), 455359017);
    });

    test('payloads without a segment encode and decode as before', () {
      const legacy =
          'cuadrante.alarm:night:2026-10-20:shift:'
          '{"t":"Turno","b":"Noche","s":"Posponer","a":"Despierto"}';
      final decoded = AlarmPayload.decode(legacy)!;
      expect(decoded.segment, 0);
      expect(decoded.encode(), legacy, reason: 'byte-identical');
      expect(
        AlarmPayload.decode(
          'cuadrante.alarm:night:2026-10-20:shift:{"t":"a","b":"b","g":"x"}',
        )!.segment,
        0,
        reason: 'a bad value reads as the first segment',
      );
    });
  });
}
