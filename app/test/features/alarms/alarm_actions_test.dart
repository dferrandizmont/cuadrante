import 'package:cuadrante/features/alarms/application/alarm_sync.dart';
import 'package:cuadrante/features/alarms/data/alarm_actions.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/alarms/domain/alarm_strings.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

const _strings = AlarmStrings(
  title: _title,
  body: _body,
  channelName: 'Alarmas',
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
String _dayBefore(String name, String start) => 'Mañana: $name a las $start';
String _body(String name, String start, String end) =>
    '$name: de $start a $end';

const _night = ShiftType(
  id: 'night',
  code: 'N',
  name: 'Noche',
  colorValue: 0xFF336699,
  category: ShiftCategory.work,
  startMinute: 22 * 60,
  endMinute: 6 * 60,
);
const _today = CivilDate(2026, 10, 19);

Schedule _schedule() => Schedule(
  shiftTypes: const [_night],
  entries: {
    for (var i = 1; i <= 3; i++)
      _today.addDays(i): DayEntry(
        date: _today.addDays(i),
        shiftTypeIds: const ['night'],
      ),
  },
);

const _settings = AlarmSettings(
  enabled: true,
  byShiftType: {'night': AlarmTypeSettings(enabled: true, dayBefore: true)},
);

PlannedAlarm _planned(AlarmKind kind) => planAlarms(
  schedule: _schedule(),
  settings: _settings,
  now: DateTime(2026, 10, 19, 12),
  strings: _strings,
).firstWhere((a) => a.kind == kind);

final _now = DateTime(2026, 10, 20, 20, 30, 15);

void main() {
  group('payload', () {
    test('a planned alarm carries what the buttons need', () {
      final alarm = _planned(AlarmKind.shift);
      expect(alarm.payload, startsWith('cuadrante.alarm:night:2026-10-20:'));
      final decoded = AlarmPayload.decode(alarm.payload)!;
      expect(decoded.shiftTypeId, 'night');
      expect(decoded.shiftDate, const CivilDate(2026, 10, 20));
      expect(decoded.kind, AlarmKind.shift);
      expect(decoded.title, 'Turno de Noche a las 22:00');
      expect(decoded.body, 'Noche: de 22:00 a 06:00');
      expect(decoded.snoozeLabel, 'Posponer 10 min');
      expect(decoded.awakeLabel, 'Ya estoy despierto');
    });

    test('round trip with colons and quotes in ids and texts', () {
      const payload = AlarmPayload(
        shiftTypeId: 'a:b/ñ',
        shiftDate: CivilDate(2026, 3, 29),
        kind: AlarmKind.dayBefore,
        title: 'Hoy: "turno": 22:00',
        body: 'x:y:z',
      );
      final back = AlarmPayload.decode(payload.encode())!;
      expect(back.shiftTypeId, 'a:b/ñ');
      expect(back.shiftDate, const CivilDate(2026, 3, 29));
      expect(back.kind, AlarmKind.dayBefore);
      expect(back.title, 'Hoy: "turno": 22:00');
      expect(back.body, 'x:y:z');
      expect(back.snoozeLabel, isNull);
      expect(AlarmPayload.decode(payload.encodeAsSnooze()), isNotNull);
    });

    test('only ours decode, garbage does not throw', () {
      expect(AlarmPayload.decode(null), isNull);
      expect(AlarmPayload.decode(''), isNull);
      expect(AlarmPayload.decode('other:night:2026-10-20:shift:{}'), isNull);
      expect(AlarmPayload.decode('cuadrante.alarm:night'), isNull);
      expect(
        AlarmPayload.decode('cuadrante.alarm:night:2026-10-20:shift'),
        isNull,
      );
      expect(
        AlarmPayload.decode('cuadrante.alarm:night:nope:shift:{}'),
        isNull,
      );
      expect(
        AlarmPayload.decode('cuadrante.alarm:night:2026-10-20:later:{}'),
        isNull,
      );
      expect(
        AlarmPayload.decode('cuadrante.alarm:night:2026-10-20:shift:{'),
        isNull,
      );
      expect(
        AlarmPayload.decode('cuadrante.alarm:night:2026-10-20:shift:[1]'),
        isNull,
      );
      expect(AlarmPayload.decode('${alarmTestPayloadPrefix}test'), isNull);
    });

    test('a snooze is not a planned alarm for the scheduler to cancel', () {
      final payload = _planned(AlarmKind.shift).payload;
      final snooze = AlarmPayload.decode(payload)!.encodeAsSnooze();
      expect(payload.startsWith(alarmPayloadPrefix), isTrue);
      expect(snooze.startsWith(alarmPayloadPrefix), isFalse);
      expect(snooze.startsWith(alarmSnoozePayloadPrefix), isTrue);
    });
  });

  group('handleAlarmAction', () {
    late FakeAlarmScheduler scheduler;
    setUp(() => scheduler = FakeAlarmScheduler());

    test('"Posponer 10 min" schedules one copy ten minutes later', () async {
      final alarm = _planned(AlarmKind.shift);
      final result = await handleAlarmAction(
        scheduler: scheduler,
        actionId: snoozeActionId,
        payload: alarm.payload,
        now: _now,
      );
      expect(result, AlarmActionResult.snoozed);
      final snooze = scheduler.oneOffs.single;
      expect(snooze.kind, OneOffKind.snooze);
      expect(snooze.fireAt, _now.add(const Duration(minutes: 10)));
      expect(snooze.title, alarm.title);
      expect(snooze.body, alarm.body);
      expect(snooze.snoozeLabel, 'Posponer 10 min');
      expect(snooze.awakeLabel, 'Ya estoy despierto');
      expect(snooze.payload.startsWith(alarmPayloadPrefix), isFalse);
      expect(snooze.payload.startsWith(alarmSnoozePayloadPrefix), isTrue);
      expect(snooze.id, isNot(alarm.id));
      expect(snooze.id, inInclusiveRange(0, 0x7FFFFFFF));
    });

    test('snoozing again replaces the snooze instead of piling up', () async {
      final alarm = _planned(AlarmKind.shift);
      await handleAlarmAction(
        scheduler: scheduler,
        actionId: snoozeActionId,
        payload: alarm.payload,
        now: _now,
      );
      // The snoozed notification rings; the user snoozes it once more.
      final first = scheduler.oneOffs.single;
      await handleAlarmAction(
        scheduler: scheduler,
        actionId: snoozeActionId,
        payload: first.payload,
        now: _now.add(const Duration(minutes: 10)),
      );
      final second = scheduler.oneOffs.single;
      expect(second.id, first.id);
      expect(second.fireAt, _now.add(const Duration(minutes: 20)));
      expect(second.title, alarm.title);
    });

    test('"Ya estoy despierto" schedules nothing', () async {
      final result = await handleAlarmAction(
        scheduler: scheduler,
        actionId: awakeActionId,
        payload: _planned(AlarmKind.shift).payload,
        now: _now,
      );
      expect(result, AlarmActionResult.dismissed);
      expect(scheduler.oneOffs, isEmpty);
    });

    test('the day-before reminder has no snooze', () async {
      final result = await handleAlarmAction(
        scheduler: scheduler,
        actionId: snoozeActionId,
        payload: _planned(AlarmKind.dayBefore).payload,
        now: _now,
      );
      expect(result, AlarmActionResult.ignored);
      expect(scheduler.oneOffs, isEmpty);
    });

    test(
      'a tap on the body, a foreign payload or a bad one: ignored',
      () async {
        final payload = _planned(AlarmKind.shift).payload;
        for (final (actionId, p) in <(String?, String?)>[
          (null, payload),
          ('', payload),
          ('other', payload),
          (snoozeActionId, null),
          (snoozeActionId, 'not ours'),
          (snoozeActionId, 'cuadrante.alarm:night:2026-10-20:shift:{'),
          (snoozeActionId, '${alarmTestPayloadPrefix}test'),
        ]) {
          expect(
            await handleAlarmAction(
              scheduler: scheduler,
              actionId: actionId,
              payload: p,
              now: _now,
            ),
            AlarmActionResult.ignored,
            reason: '$actionId $p',
          );
        }
        expect(scheduler.oneOffs, isEmpty);
      },
    );

    test('a different delay can be asked for', () async {
      await handleAlarmAction(
        scheduler: scheduler,
        actionId: snoozeActionId,
        payload: _planned(AlarmKind.shift).payload,
        now: _now,
        snooze: const Duration(minutes: 5),
      );
      expect(
        scheduler.oneOffs.single.fireAt,
        _now.add(const Duration(minutes: 5)),
      );
    });
  });

  group('AlarmSync and snoozes', () {
    late FakeAlarmScheduler scheduler;
    late AlarmSettings settings;

    AlarmSync makeSync() => AlarmSync(
      scheduler: scheduler,
      loadSettings: () async => settings,
      readSchedule: _schedule,
      now: () => DateTime(2026, 10, 19, 12),
      debounce: Duration.zero,
    )..strings = _strings;

    Future<void> snooze() => handleAlarmAction(
      scheduler: scheduler,
      actionId: snoozeActionId,
      payload: _planned(AlarmKind.shift).payload,
      now: DateTime(2026, 10, 19, 12),
    );

    setUp(() {
      scheduler = FakeAlarmScheduler();
      settings = _settings;
    });

    test('a resync leaves a pending snooze alone', () async {
      await snooze();
      await makeSync().resync();
      expect(scheduler.oneOffs, hasLength(1));
      expect(scheduler.cancelSnoozeCalls, 0);
      expect(scheduler.scheduled, isNotEmpty);
    });

    test('turning the alarms off cancels the snoozes', () async {
      await snooze();
      settings = settings.copyWith(enabled: false);
      await makeSync().resync();
      expect(scheduler.oneOffs, isEmpty);
      expect(scheduler.scheduled, isEmpty);
    });

    test('so does losing the notification permission', () async {
      await snooze();
      scheduler.permission = AlarmPermission.denied;
      await makeSync().resync();
      expect(scheduler.oneOffs, isEmpty);
    });

    test('the test notification is not a snooze: it survives', () async {
      await scheduler.scheduleOneOff(
        OneOffAlarm(
          id: 1,
          fireAt: DateTime(2026, 10, 19, 12, 0, 10),
          kind: OneOffKind.test,
          title: 'Prueba',
          body: 'Cuerpo',
          payload: '${alarmTestPayloadPrefix}test',
        ),
      );
      settings = settings.copyWith(enabled: false);
      await makeSync().resync();
      expect(scheduler.oneOffs.single.kind, OneOffKind.test);
    });
  });
}
