import 'package:cuadrante/features/alarms/application/alarm_providers.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/alarms/domain/alarm_strings.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

/// Scenarios Q60 to Q64: the alarm settings screen driving the REAL
/// notification plugin (0.4.0). Like Q11 they run on the device clock (the
/// plugin refuses dates in the past) with a Noche every day for three weeks,
/// and they read what Android really has pending. The registry lists
/// [alarmSettingsScenarios].
final List<QaScenario> alarmSettingsScenarios = [
  qaAlarmsEnableNight, // Q60
  qaAlarmsDayBefore, // Q61
  qaAlarmsSkipDay, // Q62
  qaAlarmsTestFires, // Q63
  qaAlarmsDisableAll, // Q64
];

const _night = 'night';
const _timeout = Duration(minutes: 4);

// ---- helpers ---------------------------------------------------------------

Finder _k(String key) => find.byKey(ValueKey(key));

/// Opens the app on the device clock with a Noche every day (yesterday to
/// three weeks ahead) and waits for the notification permission
/// (`run_android.sh` grants POST_NOTIFICATIONS right after installing).
Future<QaApp> _open(
  QaContext qa,
  FlutterLocalNotificationsPlugin plugin,
) async {
  final t = qa.tester;
  final app = await QaApp.open(
    qa,
    clock: DateTime.now,
    now: DateTime.now(),
    prepare: (storage) async {
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
  final scheduler = app.container.read(alarmSchedulerProvider);
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
  await t.runAsync(plugin.cancelAll);
  return app;
}

/// Our planned alarms (the `cuadrante.alarm:` payloads) that are pending.
Future<List<PendingNotificationRequest>> _ours(
  WidgetTester t,
  FlutterLocalNotificationsPlugin plugin,
) async {
  final all = (await t.runAsync(plugin.pendingNotificationRequests))!;
  return [
    for (final r in all)
      if (r.payload?.startsWith(alarmPayloadPrefix) ?? false) r,
  ];
}

/// Polls [read] (real time, up to [limit]) until [done] says yes, pumping
/// frames in between; returns the last value either way.
Future<T> _until<T>(
  WidgetTester t,
  Future<T> Function() read,
  bool Function(T value) done, {
  Duration limit = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(limit);
  var value = await read();
  while (!done(value) && DateTime.now().isBefore(end)) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await t.pump(const Duration(milliseconds: 50));
    value = await read();
  }
  return value;
}

Future<void> _openAlarmsScreen(WidgetTester t) async {
  await t.tapAndSettle(find.byTooltip('Abrir ajustes'), reason: 'Ajustes');
  await t.tapAndSettle(_k('settings-alarms'), reason: 'fila Alarmas');
  expect(_k('alarms-master-switch'), findsOneWidget);
}

Future<void> _backHome(WidgetTester t) async {
  for (var i = 0; i < 4 && find.byType(BackButton).evaluate().isNotEmpty; i++) {
    await t.tapAndSettle(find.byType(BackButton).last, reason: 'atrás');
  }
}

AlarmSettings _settings(QaApp app) =>
    app.container.read(alarmSettingsProvider).requireValue;

List<PlannedAlarm> _plan(QaApp app) => planAlarms(
  schedule: app.schedule,
  settings: _settings(app),
  now: DateTime.now(),
  strings: AlarmStrings.blank,
);

/// Master switch on and Noche on (90 minutes, the default), from the UI.
Future<void> _masterAndNight(QaApp app) async {
  final t = app.tester;
  await t.tapAndSettle(
    _k('alarms-master-switch'),
    reason: 'interruptor general',
  );
  await t.tapAndSettle(_k('alarms-type-switch-night'), reason: 'Noche');
}

// ---- Q60 -------------------------------------------------------------------

/// Q60.
const qaAlarmsEnableNight = QaScenario(
  'Q60',
  'Alarmas: activar Noche 90 min desde la pantalla',
  _enableNightBody,
  timeout: _timeout,
);

Future<void> _enableNightBody(QaContext qa) async {
  final t = qa.tester;
  final plugin = FlutterLocalNotificationsPlugin();
  final app = await _open(qa, plugin);
  try {
    expect(await _ours(t, plugin), isEmpty, reason: 'punto de partida');
    await _openAlarmsScreen(t);
    expect(t.widget<Switch>(_k('alarms-master-switch')).value, isFalse);
    await _masterAndNight(app);
    await qa.shot('noche_activada');

    expect(_settings(app).forShiftType(_night).enabled, isTrue);
    expect(_settings(app).forShiftType(_night).minutesBefore, 90);
    final pending = await _until(
      t,
      () => _ours(t, plugin),
      (p) => p.isNotEmpty,
    );
    final planned = _plan(app);
    qa.metric('alarmas_pendientes', pending.length);
    expect(pending, isNotEmpty);
    expect(pending.length, lessThanOrEqualTo(maxPendingAlarms));
    expect(pending.length, planned.length, reason: 'pendientes = plan');
    expect({for (final r in pending) r.id}, {for (final a in planned) a.id});
    for (final r in pending) {
      expect(r.payload, startsWith('${alarmPayloadPrefix}night:'));
    }
    // 90 min before 22:00, every night.
    for (final alarm in planned) {
      expect(alarm.kind, AlarmKind.shift);
      expect(alarm.fireMinute, 20 * 60 + 30);
    }
    // The next-alarm line of the screen comes from the same planner.
    final footer = t.widget<Text>(_k('alarms-next')).data!;
    expect(footer, startsWith('Próximo aviso: '));
    expect(footer, endsWith('20:30 · Noche'));
    qa.expectNoFlutterErrors('pantalla de alarmas');
  } finally {
    await _backHome(t);
    await t.runAsync(plugin.cancelAll);
  }
}

// ---- Q61 -------------------------------------------------------------------

/// Q61.
const qaAlarmsDayBefore = QaScenario(
  'Q61',
  'Alarmas: el aviso del día anterior añade uno por noche',
  _dayBeforeBody,
  timeout: _timeout,
);

Future<void> _dayBeforeBody(QaContext qa) async {
  final t = qa.tester;
  final plugin = FlutterLocalNotificationsPlugin();
  final app = await _open(qa, plugin);
  try {
    await _openAlarmsScreen(t);
    await _masterAndNight(app);
    final before = await _until(t, () => _ours(t, plugin), (p) => p.isNotEmpty);
    expect(before, isNotEmpty);

    await t.tapAndSettle(
      _k('alarms-daybefore-switch-night'),
      reason: 'aviso el día anterior',
    );
    expect(_settings(app).forShiftType(_night).dayBefore, isTrue);
    expect(_settings(app).forShiftType(_night).dayBeforeMinute, 20 * 60);
    await qa.shot('dia_anterior');

    final planned = _plan(app);
    final reminders = planned.where((a) => a.kind == AlarmKind.dayBefore);
    expect(reminders, isNotEmpty);
    final after = await _until(
      t,
      () => _ours(t, plugin),
      (p) => p.length == planned.length,
    );
    qa.metric('pendientes_antes', before.length);
    qa.metric('pendientes_despues', after.length);
    expect(after.length, planned.length, reason: 'pendientes = plan');
    // One extra alarm per night whose evening before is still ahead.
    expect(after.length - before.length, reminders.length);
    expect(
      after.where((r) => r.payload!.contains(':dayBefore:')),
      hasLength(reminders.length),
    );
    expect(
      after.where((r) => r.payload!.contains(':shift:')),
      hasLength(before.length),
      reason: 'las alarmas de antes del turno siguen igual',
    );
    for (final r in reminders) {
      expect(r.fireMinute, 20 * 60);
      expect(r.fireDate, r.shiftDate.addDays(-1));
    }

    // Off again: back to the first set.
    await t.tapAndSettle(_k('alarms-daybefore-switch-night'));
    final back = await _until(
      t,
      () => _ours(t, plugin),
      (p) => p.length == before.length,
    );
    expect({for (final r in back) r.id}, {for (final r in before) r.id});
    qa.expectNoFlutterErrors('aviso del día anterior');
  } finally {
    await _backHome(t);
    await t.runAsync(plugin.cancelAll);
  }
}

// ---- Q62 -------------------------------------------------------------------

/// Q62.
const qaAlarmsSkipDay = QaScenario(
  'Q62',
  'Alarmas: «Sin alarma este día» quita solo la alarma de ese día',
  _skipDayBody,
  timeout: _timeout,
);

Future<void> _skipDayBody(QaContext qa) async {
  final t = qa.tester;
  final plugin = FlutterLocalNotificationsPlugin();
  final app = await _open(qa, plugin);
  try {
    await _openAlarmsScreen(t);
    await _masterAndNight(app);
    final before = await _until(t, () => _ours(t, plugin), (p) => p.isNotEmpty);
    expect(before, isNotEmpty);
    await _backHome(t);

    // A night with an alarm ahead, in the month on screen when possible.
    final today = CivilDate.fromDateTime(DateTime.now());
    final target = [
      for (var i = 1; i <= 4; i++) today.addDays(i),
    ].firstWhere((d) => d.month == today.month, orElse: () => today.addDays(1));
    final targetId = alarmIdFor(target, _night, 0);
    expect(
      before.map((r) => r.id),
      contains(targetId),
      reason: 'la noche de ${target.toIso()} tiene alarma',
    );

    await t.tapAndSettle(_k('day-${target.toIso()}'), reason: 'celda del día');
    expect(find.text('Sin alarma este día'), findsOneWidget);
    await qa.shot('detalle');
    await t.tapAndSettle(_k('day-alarm-skip-switch'), reason: 'saltar el día');

    expect(_settings(app).skippedDates, {target});
    final skipped = await _until(
      t,
      () => _ours(t, plugin),
      (p) => p.length == before.length - 1,
    );
    expect(skipped.length, before.length - 1, reason: 'exactamente una menos');
    expect(skipped.map((r) => r.id), isNot(contains(targetId)));
    expect(
      {for (final r in skipped) r.id},
      {for (final r in before) r.id}..remove(targetId),
      reason: 'las demás siguen',
    );

    // Un-skipping brings it back.
    await t.tapAndSettle(_k('day-alarm-skip-switch'));
    final back = await _until(
      t,
      () => _ours(t, plugin),
      (p) => p.length == before.length,
    );
    expect({for (final r in back) r.id}, {for (final r in before) r.id});
    expect(_settings(app).skippedDates, isEmpty);
    qa.expectNoFlutterErrors('saltar un día');
  } finally {
    await t.runAsync(plugin.cancelAll);
  }
}

// ---- Q63 -------------------------------------------------------------------

/// Q63.
const qaAlarmsTestFires = QaScenario(
  'Q63',
  'Alarmas: «Probar aviso» suena a los 10 segundos',
  _testFiresBody,
  timeout: Duration(minutes: 5),
);

Future<void> _testFiresBody(QaContext qa) async {
  final t = qa.tester;
  final plugin = FlutterLocalNotificationsPlugin();
  final android = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  final app = await _open(qa, plugin);
  try {
    await _openAlarmsScreen(t);
    await t.tapAndSettle(
      _k('alarms-master-switch'),
      reason: 'interruptor general',
    );
    await t.tapAndSettle(_k('alarms-test'), reason: 'Probar aviso');
    expect(find.text('Te avisaremos en 10 segundos.'), findsOneWidget);
    await qa.shot('probar');

    Future<List<PendingNotificationRequest>> tests() async {
      final all = (await t.runAsync(plugin.pendingNotificationRequests))!;
      return [
        for (final r in all)
          if (r.payload?.startsWith(alarmTestPayloadPrefix) ?? false) r,
      ];
    }

    expect(await tests(), hasLength(1), reason: 'programada');
    expect((await tests()).single.id, alarmTestId);

    // Exact alarms ring in 10 s; without "Alarmas y recordatorios" Android may
    // delay them by minutes (docs/alarmas.md).
    final exact = (await t.runAsync(
      app.container.read(alarmSchedulerProvider).canScheduleExactAlarms,
    ))!;
    qa.note(
      exact
          ? 'alarmas exactas concedidas'
          : 'sin alarmas exactas: puede tardar minutos',
    );
    final started = DateTime.now();
    final active = await _until<List<ActiveNotification>>(
      t,
      () async =>
          (await t.runAsync(
            () async => await android?.getActiveNotifications(),
          )) ??
          const [],
      (list) => list.any((n) => n.id == alarmTestId),
      limit: exact ? const Duration(seconds: 40) : const Duration(minutes: 4),
    );
    final seconds = DateTime.now().difference(started).inSeconds;
    qa.metric('segundos_hasta_sonar', seconds);
    expect(
      active.any((n) => n.id == alarmTestId),
      isTrue,
      reason: 'el aviso de prueba no llegó',
    );
    final shown = active.firstWhere((n) => n.id == alarmTestId);
    expect(shown.title, 'Aviso de prueba');
    expect(await tests(), isEmpty, reason: 'ya no está pendiente');
    if (exact) expect(seconds, lessThan(40));
    qa.expectNoFlutterErrors('probar aviso');
  } finally {
    await _backHome(t);
    await t.runAsync(plugin.cancelAll);
  }
}

// ---- Q64 -------------------------------------------------------------------

/// Q64.
const qaAlarmsDisableAll = QaScenario(
  'Q64',
  'Alarmas: desactivar todo no deja ninguna pendiente',
  _disableAllBody,
  timeout: _timeout,
);

Future<void> _disableAllBody(QaContext qa) async {
  final t = qa.tester;
  final plugin = FlutterLocalNotificationsPlugin();
  final app = await _open(qa, plugin);
  try {
    await _openAlarmsScreen(t);
    await _masterAndNight(app);
    await t.tapAndSettle(_k('alarms-daybefore-switch-night'));
    final pending = await _until(
      t,
      () => _ours(t, plugin),
      (p) => p.length == _plan(app).length && p.isNotEmpty,
    );
    expect(pending, isNotEmpty);
    // A test notification and the planned ones, then everything off.
    await t.tapAndSettle(_k('alarms-test'));

    await t.tapAndSettle(_k('alarms-master-switch'), reason: 'apagar todo');
    expect(_settings(app).enabled, isFalse);
    final left = await _until(t, () => _ours(t, plugin), (p) => p.isEmpty);
    expect(left, isEmpty, reason: 'desactivadas: ninguna pendiente');
    expect(find.text('Las alarmas están desactivadas.'), findsOneWidget);
    await qa.shot('todo_apagado');

    // The choices are kept: switching on again brings the alarms back.
    await t.tapAndSettle(
      _k('alarms-master-switch'),
      reason: 'encender otra vez',
    );
    expect(_settings(app).forShiftType(_night).dayBefore, isTrue);
    final again = await _until(t, () => _ours(t, plugin), (p) => p.isNotEmpty);
    expect(again, isNotEmpty);
    qa.expectNoFlutterErrors('desactivar todo');
  } finally {
    await _backHome(t);
    await t.runAsync(plugin.cancelAll);
  }
}
