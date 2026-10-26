import 'package:cuadrante/features/alarms/data/alarm_actions.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/data/local_alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/alarms/domain/alarm_strings.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

class _Call {
  _Call(this.id, this.date, this.details, this.payload);
  final int id;
  final DateTime date;
  final NotificationDetails details;
  final String? payload;
}

/// Records what reaches the plugin; pending notifications are scripted.
class _Plugin implements FlutterLocalNotificationsPlugin {
  final scheduled = <_Call>[];
  final cancelled = <int>[];
  final pending = <PendingNotificationRequest>[];
  int initCalls = 0;
  DidReceiveNotificationResponseCallback? onResponse;
  DidReceiveBackgroundNotificationResponseCallback? onBackgroundResponse;
  InitializationSettings? settings;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #initialize:
        initCalls++;
        settings =
            invocation.namedArguments[#settings] as InitializationSettings;
        onResponse =
            invocation.namedArguments[#onDidReceiveNotificationResponse]
                as DidReceiveNotificationResponseCallback?;
        onBackgroundResponse =
            invocation
                    .namedArguments[#onDidReceiveBackgroundNotificationResponse]
                as DidReceiveBackgroundNotificationResponseCallback?;
        return Future<bool?>.value(true);
      case #zonedSchedule:
        scheduled.add(
          _Call(
            invocation.namedArguments[#id] as int,
            invocation.namedArguments[#scheduledDate] as DateTime,
            invocation.namedArguments[#notificationDetails]
                as NotificationDetails,
            invocation.namedArguments[#payload] as String?,
          ),
        );
        return Future<void>.value();
      case #pendingNotificationRequests:
        return Future<List<PendingNotificationRequest>>.value([...pending]);
      case #cancel:
        cancelled.add(invocation.namedArguments[#id] as int);
        return Future<void>.value();
      case #resolvePlatformSpecificImplementation:
        return null;
    }
    return super.noSuchMethod(invocation);
  }
}

const _strings = AlarmStrings(
  title: _t2,
  body: _t3,
  channelName: 'Alarmas de turno',
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

const _alarm = PlannedAlarm(
  id: 7,
  fireDate: CivilDate(2026, 10, 20),
  fireMinute: 20 * 60 + 30,
  shiftDate: CivilDate(2026, 10, 20),
  shiftTypeId: 'night',
  title: 'Turno',
  body: 'Cuerpo',
  snoozeLabel: 'Posponer 10 min',
  awakeLabel: 'Ya estoy despierto',
);

void main() {
  test(
    'consecutive locale configurations refresh Darwin action titles',
    () async {
      final plugin = _Plugin();
      final scheduler = LocalAlarmScheduler(plugin: plugin);
      for (final language in ['es', 'en']) {
        final l10n = await AppLocalizations.delegate.load(Locale(language));
        final strings = AlarmStrings.fromL10n(l10n);
        await scheduler.configure(strings);
        final settings = plugin.settings!.iOS!;
        expect(
          settings.notificationCategories.single.actions.map((a) => a.title),
          [strings.snoozeAction, strings.awakeAction],
        );
        expect(settings.requestAlertPermission, isFalse);
        expect(settings.requestBadgePermission, isFalse);
        expect(settings.requestSoundPermission, isFalse);
      }
      expect(plugin.initCalls, 2);
      final english = AlarmStrings.fromL10n(
        await AppLocalizations.delegate.load(const Locale('en')),
      );
      await scheduler.configure(english);
      expect(plugin.initCalls, 2, reason: 'unchanged labels keep cached setup');
      expect(plugin.onResponse, isNotNull);
      expect(
        plugin.onBackgroundResponse,
        same(alarmNotificationBackgroundHandler),
      );
    },
  );

  test(
    'configure adds categories after an earlier initialize without texts',
    () async {
      final plugin = _Plugin();
      final scheduler = LocalAlarmScheduler(plugin: plugin);
      await scheduler.initialize();
      expect(plugin.settings!.iOS!.notificationCategories, isEmpty);
      await scheduler.configure(_strings);
      expect(plugin.initCalls, 2);
      expect(
        plugin.settings!.iOS!.notificationCategories.single.actions.map(
          (a) => a.title,
        ),
        [_strings.snoozeAction, _strings.awakeAction],
      );
    },
  );

  test('a one-off is scheduled at that instant, whatever the zone', () async {
    final plugin = _Plugin();
    final scheduler = LocalAlarmScheduler(
      plugin: plugin,
      localZone: () async => 'Europe/Madrid',
    );
    final at = DateTime.utc(2026, 10, 20, 18, 40, 5);
    await scheduler.scheduleOneOff(
      OneOffAlarm(
        id: 99,
        fireAt: at,
        kind: OneOffKind.snooze,
        title: 'T',
        body: 'B',
        payload: '${alarmSnoozePayloadPrefix}x',
        snoozeLabel: 'Posponer',
        awakeLabel: 'Despierto',
      ),
    );
    final call = plugin.scheduled.single;
    expect(call.id, 99);
    expect(call.date.toUtc(), at);
    expect(call.payload, '${alarmSnoozePayloadPrefix}x');
    // It works without initializing the plugin: the snooze isolate has none.
    expect(plugin.initCalls, 0);
    final actions = call.details.android!.actions!;
    expect(actions.map((a) => a.id), [snoozeActionId, awakeActionId]);
    expect(actions.map((a) => a.title), ['Posponer', 'Despierto']);
  });

  test('a one-off without labels has no buttons (the test one)', () async {
    final plugin = _Plugin();
    final scheduler = LocalAlarmScheduler(plugin: plugin);
    await scheduler.scheduleOneOff(
      OneOffAlarm(
        id: 1,
        fireAt: DateTime.utc(2026, 10, 20, 18),
        kind: OneOffKind.test,
        title: 'T',
        body: 'B',
        payload: '${alarmTestPayloadPrefix}test',
      ),
    );
    expect(plugin.scheduled.single.details.android!.actions, isNull);
    expect(plugin.scheduled.single.details.iOS!.categoryIdentifier, isNull);
  });

  test('planned alarms get the buttons, the day-before one does not', () async {
    final plugin = _Plugin();
    final scheduler = LocalAlarmScheduler(
      plugin: plugin,
      localZone: () async => 'Europe/Madrid',
    );
    await scheduler.configure(_strings);
    await scheduler.replaceAll([
      _alarm,
      const PlannedAlarm(
        id: 8,
        fireDate: CivilDate(2026, 10, 19),
        fireMinute: 20 * 60,
        shiftDate: CivilDate(2026, 10, 20),
        shiftTypeId: 'night',
        title: 'Mañana',
        body: 'Cuerpo',
        kind: AlarmKind.dayBefore,
      ),
    ]);
    final withButtons = plugin.scheduled.firstWhere((c) => c.id == 7);
    final without = plugin.scheduled.firstWhere((c) => c.id == 8);
    expect(withButtons.details.android!.actions!.map((a) => a.id), [
      snoozeActionId,
      awakeActionId,
    ]);
    expect(withButtons.details.iOS!.categoryIdentifier, alarmIosCategory);
    expect(without.details.android!.actions, isNull);
    expect(without.details.iOS!.categoryIdentifier, isNull);
    expect(without.payload, contains(':dayBefore:'));
  });

  test(
    'the plugin is initialized with the actions and both handlers',
    () async {
      final plugin = _Plugin();
      final scheduler = LocalAlarmScheduler(
        plugin: plugin,
        localZone: () async => 'Europe/Madrid',
      );
      await scheduler.configure(_strings);
      expect(plugin.onResponse, isNotNull);
      expect(
        plugin.onBackgroundResponse,
        same(alarmNotificationBackgroundHandler),
      );
      final categories = plugin.settings!.iOS!.notificationCategories;
      expect(categories.single.identifier, alarmIosCategory);
      expect(categories.single.actions.map((a) => a.identifier), [
        snoozeActionId,
        awakeActionId,
      ]);
      expect(categories.single.actions.map((a) => a.title), [
        'Posponer 10 min',
        'Ya estoy despierto',
      ]);
    },
  );

  test(
    'a button tapped while the app runs snoozes through the plugin',
    () async {
      final plugin = _Plugin();
      final scheduler = LocalAlarmScheduler(
        plugin: plugin,
        localZone: () async => 'Europe/Madrid',
      );
      await scheduler.configure(_strings);
      plugin.onResponse!(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          id: 7,
          actionId: snoozeActionId,
          payload: _alarm.payload,
        ),
      );
      await pumpEventQueue();
      final snooze = plugin.scheduled.single;
      expect(snooze.payload, startsWith(alarmSnoozePayloadPrefix));
      final delay = snooze.date.toUtc().difference(DateTime.now().toUtc());
      expect(delay, lessThan(const Duration(minutes: 10, seconds: 5)));
      expect(delay, greaterThan(const Duration(minutes: 9, seconds: 50)));
    },
  );

  test('replaceAll leaves snoozes and the test alone, cancelSnoozes drops '
      'only the snoozes', () async {
    final plugin = _Plugin()
      ..pending.addAll([
        PendingNotificationRequest(1, 't', 'b', _alarm.payload),
        PendingNotificationRequest(2, 't', 'b', '${alarmSnoozePayloadPrefix}x'),
        PendingNotificationRequest(3, 't', 'b', '${alarmTestPayloadPrefix}x'),
        const PendingNotificationRequest(4, 't', 'b', 'not ours'),
      ]);
    final scheduler = LocalAlarmScheduler(
      plugin: plugin,
      localZone: () async => 'Europe/Madrid',
    );
    await scheduler.replaceAll(const []);
    expect(plugin.cancelled, [1], reason: 'only the planned alarm is stale');

    plugin.cancelled.clear();
    await scheduler.cancelSnoozes();
    expect(plugin.cancelled, [2]);
  });
}
