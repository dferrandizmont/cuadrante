import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/data/local_alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

/// Records what reaches the plugin. Everything else is a no-op.
class _FakePlugin implements FlutterLocalNotificationsPlugin {
  _FakePlugin({this.failInitCalls = 0});

  int failInitCalls;
  int initCalls = 0;
  final scheduled = <tz.TZDateTime>[];
  final details = <NotificationDetails?>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #initialize:
        initCalls++;
        if (failInitCalls > 0) {
          failInitCalls--;
          return Future<bool?>.error(StateError('plugin not ready'));
        }
        return Future<bool?>.value(true);
      case #zonedSchedule:
        scheduled.add(
          invocation.namedArguments[#scheduledDate] as tz.TZDateTime,
        );
        details.add(
          invocation.namedArguments[#notificationDetails]
              as NotificationDetails?,
        );
        return Future<void>.value();
      case #pendingNotificationRequests:
        return Future<List<PendingNotificationRequest>>.value(const []);
      case #resolvePlatformSpecificImplementation:
        return null;
    }
    return super.noSuchMethod(invocation);
  }
}

const _alarm = PlannedAlarm(
  id: 1,
  fireDate: CivilDate(2026, 10, 20),
  fireMinute: 8 * 60,
  shiftDate: CivilDate(2026, 10, 20),
  shiftTypeId: 'morning',
  title: 'Turno',
  body: 'Cuerpo',
);

void main() {
  test('every replaceAll reads the device zone again', () async {
    var zone = 'Europe/Madrid';
    final plugin = _FakePlugin();
    final scheduler = LocalAlarmScheduler(
      plugin: plugin,
      localZone: () async => zone,
    );

    await scheduler.replaceAll(const [_alarm]);
    zone = 'America/New_York'; // the user travels, the process lives on
    await scheduler.replaceAll(const [_alarm]);

    // 08:00 on 2026-10-20: CEST (UTC+2) in Madrid, EDT (UTC-4) in New York.
    expect(plugin.scheduled, hasLength(2));
    expect(plugin.scheduled[0].toUtc(), DateTime.utc(2026, 10, 20, 6));
    expect(plugin.scheduled[1].toUtc(), DateTime.utc(2026, 10, 20, 12));
    expect(plugin.scheduled[1].location.name, 'America/New_York');
    expect(tz.local.name, 'America/New_York');
  });

  test(
    'an unreadable zone falls back to Madrid, then keeps the last one',
    () async {
      var fail = true;
      var zone = 'Asia/Tokyo';
      final plugin = _FakePlugin();
      final scheduler = LocalAlarmScheduler(
        plugin: plugin,
        localZone: () async {
          if (fail) throw StateError('no zone');
          return zone;
        },
      );

      await scheduler.replaceAll(const [_alarm]);
      expect(plugin.scheduled.last.toUtc(), DateTime.utc(2026, 10, 20, 6));

      fail = false;
      await scheduler.replaceAll(const [_alarm]);
      expect(plugin.scheduled.last.toUtc(), DateTime.utc(2026, 10, 19, 23));

      fail = true;
      zone = 'America/New_York';
      await scheduler.replaceAll(const [_alarm]);
      expect(plugin.scheduled.last.toUtc(), DateTime.utc(2026, 10, 19, 23));
    },
  );

  test('a failed plugin initialization is retried by the next call', () async {
    final plugin = _FakePlugin(failInitCalls: 1);
    final scheduler = LocalAlarmScheduler(
      plugin: plugin,
      localZone: () async => 'Europe/Madrid',
    );

    await expectLater(scheduler.initialize(), throwsStateError);
    await scheduler.replaceAll(const [_alarm]);

    expect(plugin.initCalls, 2);
    expect(plugin.scheduled, hasLength(1));

    // Once it worked it stays cached.
    await scheduler.initialize();
    expect(plugin.initCalls, 2);
  });

  test('planned and snoozed notifications hide their content on the lock '
      'screen', () async {
    final plugin = _FakePlugin();
    final scheduler = LocalAlarmScheduler(
      plugin: plugin,
      localZone: () async => 'Europe/Madrid',
    );

    await scheduler.replaceAll(const [_alarm]);
    await scheduler.scheduleOneOff(
      OneOffAlarm(
        id: 2,
        fireAt: DateTime.utc(2026, 10, 20, 6),
        kind: OneOffKind.snooze,
        title: 'Turno',
        body: 'Cuerpo',
        payload: '$alarmSnoozePayloadPrefix{}',
      ),
    );

    expect(plugin.details, hasLength(2));
    for (final d in plugin.details) {
      expect(d!.android!.visibility, NotificationVisibility.private);
    }
  });
}
