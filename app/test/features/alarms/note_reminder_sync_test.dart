import 'package:cuadrante/features/alarms/application/alarm_sync.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/alarms/domain/alarm_strings.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

// The sync keeps the reminders of notes on the device (docs/paridad.md, A1):
// no alarm switch needed, the notification permission is.

const _strings = AlarmStrings(
  title: _t2,
  body: _t3,
  channelName: 'Alarmas',
  channelDescription: 'Descripción',
  dayBeforeTitle: _t2,
  snoozeAction: 'Posponer 10 min',
  awakeAction: 'Ya estoy despierto',
  testTitle: 'Prueba',
  testBody: 'Cuerpo',
  reminderTitle: 'Recordatorio',
  reminderEmptyBody: 'Tienes un recordatorio para hoy',
  reminderChannelName: 'Recordatorios de notas',
  reminderChannelDescription: 'Descripción',
);
String _t2(String a, String b) => '$a $b';
String _t3(String a, String b, String c) => '$a $b $c';

const _today = CivilDate(2026, 10, 19);

Schedule _withReminder({int? minute = 9 * 60}) => Schedule(
  entries: {
    _today.addDays(2): DayEntry(
      date: _today.addDays(2),
      note: 'Dentista\nllevar la tarjeta',
      noteReminderMinute: minute,
    ),
  },
);

void main() {
  late FakeAlarmScheduler scheduler;
  late Schedule schedule;
  late AlarmSync sync;

  setUp(() {
    scheduler = FakeAlarmScheduler();
    schedule = _withReminder();
    sync = AlarmSync(
      scheduler: scheduler,
      loadSettings: () async => AlarmSettings.disabled,
      readSchedule: () => schedule,
      now: () => DateTime(2026, 10, 19, 12),
      strings: _strings,
    );
    addTearDown(sync.dispose);
  });

  test('a reminder is scheduled with every alarm switch off', () async {
    await sync.resync();
    final alarm = scheduler.scheduled.single;
    expect(alarm.kind, AlarmKind.reminder);
    expect(alarm.title, 'Recordatorio');
    expect(alarm.body, 'Dentista');
    expect((alarm.fireDate, alarm.fireMinute), (_today.addDays(2), 9 * 60));
  });

  test('without the notification permission nothing is scheduled', () async {
    scheduler.permission = AlarmPermission.denied;
    await sync.resync();
    expect(scheduler.scheduled, isEmpty);
    expect(scheduler.replaceCalls, 1, reason: 'stale ones are cancelled');
  });

  test('removing the reminder cancels it', () async {
    await sync.resync();
    expect(scheduler.scheduled, hasLength(1));
    schedule = _withReminder(minute: null);
    await sync.resync();
    expect(scheduler.scheduled, isEmpty);
  });

  test('changing the time replaces it (same id, new minute)', () async {
    await sync.resync();
    final first = scheduler.scheduled.single;
    schedule = _withReminder(minute: 18 * 60 + 30);
    await sync.resync();
    final second = scheduler.scheduled.single;
    expect(second.id, first.id);
    expect(second.fireMinute, 18 * 60 + 30);
  });
}
