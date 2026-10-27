import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/alarms/application/alarm_providers.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/schedule/data/demo_schedule.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

/// Q11.
const qaAlarms = QaScenario(
  'Q11',
  'Alarmas: notificaciones programadas de verdad',
  _alarms,
  timeout: Duration(minutes: 4),
);

const _night = 'night';
const _nightAlarm = AlarmSettings(
  enabled: true,
  horizonDays: 14,
  byShiftType: {_night: AlarmTypeSettings(enabled: true, minutesBefore: 90)},
);

Future<void> _alarms(QaContext qa) async {
  final t = qa.tester;
  final plugin = FlutterLocalNotificationsPlugin();

  // The plugin schedules instants on the DEVICE clock (a date in the past is
  // refused), so the app runs on the real clock here; everything else in the
  // battery runs on the fixed 19 Oct 2026, 18:20.
  final app = await QaApp.open(
    qa,
    clock: DateTime.now,
    now: DateTime.now(),
    prepare: (storage) async {
      // A Noche every day for three weeks, so the plan never depends on
      // where the demo rotation happens to be when the battery runs.
      final today = CivilDate.fromDateTime(DateTime.now());
      await storage.repository.apply(
        mainCalendarId,
        ScheduleChange(
          patch: EntriesPatch({
            for (var i = -1; i <= 21; i++)
              today.addDays(i): EntryChange(
                null,
                DayEntry(date: today.addDays(i), shiftTypeIds: const [_night]),
              ),
          }),
        ),
      );
    },
  );
  final container = app.container;
  final scheduler = container.read(alarmSchedulerProvider);
  final sync = container.read(alarmSyncProvider);
  final controller = container.read(alarmSettingsProvider.notifier);

  Future<List<PendingNotificationRequest>> ours() async {
    final all = (await t.runAsync(plugin.pendingNotificationRequests))!;
    return [
      for (final r in all)
        if (r.payload?.startsWith(alarmPayloadPrefix) ?? false) r,
    ];
  }

  // Android 13+: run_android.sh grants POST_NOTIFICATIONS with
  // `adb shell pm grant` as soon as the app is installed.
  final end = DateTime.now().add(const Duration(seconds: 45));
  var permission = AlarmPermission.denied;
  while (DateTime.now().isBefore(end)) {
    permission = (await t.runAsync(scheduler.permissionStatus))!;
    if (permission == AlarmPermission.granted) break;
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
  }
  expect(
    permission,
    AlarmPermission.granted,
    reason:
        'falta el permiso de notificaciones '
        '(adb shell pm grant es.cuadrante.app '
        'android.permission.POST_NOTIFICATIONS)',
  );

  try {
    await t.runAsync(plugin.cancelAll);
    expect(await ours(), isEmpty, reason: 'punto de partida sin alarmas');

    // Enable: Noche, 90 minutes before.
    await t.runAsync(() => controller.save(_nightAlarm));
    await t.runAsync(sync.resync);
    await t.settle();

    final schedule = app.schedule;
    final strings = sync.strings!;
    final planned = planAlarms(
      schedule: schedule,
      settings: _nightAlarm,
      now: DateTime.now(),
      strings: strings,
    );
    final pending = await ours();
    qa.metric('alarmas_pendientes', pending.length);
    expect(pending, isNotEmpty);
    expect(pending.length, lessThanOrEqualTo(maxPendingAlarms));
    expect(pending.length, planned.length, reason: 'pendientes = plan');
    expect({for (final r in pending) r.id}, {for (final a in planned) a.id});
    for (final r in pending) {
      expect(r.payload, startsWith('${alarmPayloadPrefix}night:'));
    }
    // Every alarm is 90 min before a Noche (22:00 -> 20:30 the same day).
    for (final alarm in planned) {
      expect(schedule.resolve(alarm.shiftDate).shiftIds, contains(_night));
      expect(alarm.shiftTypeId, _night);
      expect(alarm.fireDate, alarm.shiftDate);
      expect(alarm.fireMinute, 20 * 60 + 30, reason: '20:30 local');
    }
    await qa.shot('activadas');

    // The fixed day of the battery: from Mon 19 Oct 18:20 the first alarm is
    // 20:30 that very evening (a pure check, the plugin cannot show it).
    final fixed = planAlarms(
      schedule: buildDemoSchedule(qaToday),
      settings: _nightAlarm,
      now: qaNow,
      strings: strings,
    );
    expect(fixed.first.shiftDate, qaToday);
    expect(fixed.first.fireDate, qaToday);
    expect(fixed.first.fireMinute, 20 * 60 + 30);
    expect(fixed.length, lessThanOrEqualTo(maxPendingAlarms));

    // Disable: nothing of ours is left.
    await t.runAsync(
      () => controller.save(_nightAlarm.copyWith(enabled: false)),
    );
    await t.runAsync(sync.resync);
    await t.settle();
    expect(await ours(), isEmpty, reason: 'desactivadas: ninguna pendiente');
  } finally {
    await t.runAsync(plugin.cancelAll);
  }
}
