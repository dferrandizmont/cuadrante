import 'package:cuadrante/features/alarms/application/alarm_providers.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/data/alarm_sounds.dart';
import 'package:cuadrante/features/alarms/domain/alarm_channels.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/alarms/domain/alarm_strings.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

/// Scenarios Q93 to Q95 (0.6.0 «Paridad»): the reminder of a note (A1) and
/// the sound of a shift type's alarms (A3) against the REAL notification
/// plugin. Like Q60-Q64 they run on the device clock (the plugin refuses
/// dates in the past) and read what Android really has pending. The system
/// sound picker is native UI the test cannot drive, so Q94 replaces only
/// `alarmSoundsProvider` with a fake that answers a real system URI; the
/// channels, the planner and the database are the real ones.
/// The registry lists [reminderSoundScenarios].
final List<QaScenario> reminderSoundScenarios = [
  qaReminderPending, // Q93
  qaSoundRowPersists, // Q94
  qaReminderRemovedUndo, // Q95
];

const _night = 'night';
const _timeout = Duration(minutes: 4);

/// `Settings.System.DEFAULT_ALARM_ALERT_URI`: a content URI every Android
/// phone resolves, so the channel it makes is a real one.
const _systemSound = 'content://settings/system/alarm_alert';

// ---- helpers ---------------------------------------------------------------

Finder _k(String key) => find.byKey(ValueKey(key));

/// Opens the app on the device clock with a Noche every day (yesterday to
/// three weeks ahead) and waits for the notification permission
/// (`run_android.sh` grants POST_NOTIFICATIONS right after installing).
Future<QaApp> _open(
  QaContext qa,
  FlutterLocalNotificationsPlugin plugin, {
  List<Override> overrides = const [],
}) async {
  final t = qa.tester;
  final app = await QaApp.open(
    qa,
    clock: DateTime.now,
    now: DateTime.now(),
    overrides: overrides,
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
        '(adb shell pm grant app.cuadrante.cuadrante '
        'android.permission.POST_NOTIFICATIONS)',
  );
  await t.runAsync(plugin.cancelAll);
  return app;
}

/// Everything of ours that is pending (alarms and reminders share the
/// `cuadrante.alarm:` payload prefix).
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

Iterable<PendingNotificationRequest> _reminders(
  List<PendingNotificationRequest> pending,
) => pending.where((r) => r.payload!.contains(':reminder:'));

Future<List<String>> _channelIds(
  WidgetTester t,
  FlutterLocalNotificationsPlugin plugin,
) async {
  final channels = await t.runAsync(
    () async => plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.getNotificationChannels(),
  );
  return [
    for (final c in channels ?? const <AndroidNotificationChannel>[]) c.id,
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

Future<void> _backHome(WidgetTester t) async {
  for (var i = 0; i < 4 && find.byType(BackButton).evaluate().isNotEmpty; i++) {
    await t.tapAndSettle(find.byType(BackButton).last, reason: 'atrás');
  }
}

/// A day tomorrow or later in the month on screen, so its cell is there.
CivilDate _targetDay() {
  final today = CivilDate.fromDateTime(DateTime.now());
  return [
    for (var i = 1; i <= 4; i++) today.addDays(i),
  ].firstWhere((d) => d.month == today.month, orElse: () => today.addDays(1));
}

/// Opens the sheet of [day], writes [note] and adds a reminder at the time
/// the picker proposes (09:00 on a future day).
Future<void> _addReminder(
  QaApp app,
  CivilDate day, {
  required String note,
}) async {
  final t = app.tester;
  await t.tapAndSettle(_k('day-${day.toIso()}'), reason: 'celda del día');
  await t.ensureVisible(_k('day-note'));
  await t.pump();
  await t.enterText(_k('day-note'), note);
  await t.pump();
  await t.tapAndSettle(_k('day-reminder-add'), reason: 'Avisarme');
  expect(find.text('Hora del aviso'), findsOneWidget);
  await t.tapAndSettle(
    find.byWidgetPredicate(
      (w) => w is Text && w.data?.toLowerCase() == 'aceptar',
    ),
    reason: 'aceptar la hora',
  );
}

int? _storedReminderMinute(List<Map<String, Object?>> rows) =>
    rows.isEmpty ? null : rows.single['m'] as int?;

Future<int?> _reminderRow(QaApp app, CivilDate day) async =>
    _storedReminderMinute(
      await app.query(
        'SELECT note_reminder_minute AS m FROM day_entries '
        "WHERE date = '${day.toIso()}'",
      ),
    );

// ---- Q93 -------------------------------------------------------------------

/// Q93.
const qaReminderPending = QaScenario(
  'Q93',
  'Recordatorio: «Avisarme» deja la notificación pendiente',
  _reminderPendingBody,
  timeout: _timeout,
);

Future<void> _reminderPendingBody(QaContext qa) async {
  final t = qa.tester;
  final plugin = FlutterLocalNotificationsPlugin();
  final app = await _open(qa, plugin);
  try {
    final day = _targetDay();
    expect(
      _reminders(await _ours(t, plugin)),
      isEmpty,
      reason: 'punto de partida',
    );

    await _addReminder(app, day, note: 'Dentista\nllevar la tarjeta');
    expect(find.text('Aviso a las 09:00'), findsOneWidget);
    await qa.shot('aviso_puesto');
    // Closing the sheet commits the note.
    await t.tapAt(const Offset(10, 10));
    await t.settle();
    await app.flushWrites();

    // The database has the minute; the in-memory schedule too.
    expect(await _reminderRow(app, day), 9 * 60);
    expect(app.schedule.entries[day]?.noteReminderMinute, 9 * 60);
    expect(app.schedule.entries[day]?.note, 'Dentista\nllevar la tarjeta');

    // Android has exactly that notification pending, on the reminders channel.
    final pending = await _until(
      t,
      () => _ours(t, plugin),
      (p) => _reminders(p).isNotEmpty,
    );
    final reminders = _reminders(pending).toList();
    qa.metric('recordatorios_pendientes', reminders.length);
    expect(reminders, hasLength(1));
    final r = reminders.single;
    expect(r.id, alarmIdFor(day, '', 0, AlarmKind.reminder));
    expect(r.title, 'Recordatorio');
    expect(r.body, 'Dentista');
    expect(
      r.payload,
      startsWith('$alarmPayloadPrefix:${day.toIso()}:reminder:'),
    );
    expect(await _channelIds(t, plugin), contains(reminderChannelId));

    // It is what the planner says, and independent of the alarm switches
    // (they are off in this scenario).
    final planned = planAlarms(
      schedule: app.schedule,
      settings: app.container.read(alarmSettingsProvider).requireValue,
      now: DateTime.now(),
      strings: AlarmStrings.blank,
    );
    expect({for (final a in planned) a.id}, {for (final x in pending) x.id});
    expect(
      app.container.read(alarmSettingsProvider).requireValue.enabled,
      isFalse,
    );

    // The agenda shows the bell with the time.
    await t.tapAndSettle(_k('open-agenda'), reason: 'agenda');
    expect(
      find.descendant(
        of: _k('agenda-day-${day.toIso()}'),
        matching: _k('agenda-reminder'),
      ),
      findsOneWidget,
    );
    await qa.shot('agenda');
    qa.expectNoFlutterErrors('recordatorio');
  } finally {
    await _backHome(t);
    await t.runAsync(plugin.cancelAll);
  }
}

// ---- Q94 -------------------------------------------------------------------

/// Q94.
const qaSoundRowPersists = QaScenario(
  'Q94',
  'Sonido por tipo de turno: la fila persiste y crea su canal',
  _soundRowBody,
  timeout: _timeout,
);

Future<void> _soundRowBody(QaContext qa) async {
  final t = qa.tester;
  final plugin = FlutterLocalNotificationsPlugin();
  final sounds = FakeAlarmSounds(
    choice: const AlarmSoundChoice(
      uri: _systemSound,
      title: 'Alarma del sistema',
    ),
    titles: {_systemSound: 'Alarma del sistema'},
  );
  final app = await _open(
    qa,
    plugin,
    overrides: [alarmSoundsProvider.overrideWithValue(sounds)],
  );
  final soundChannel = alarmSoundChannelId(_systemSound);
  try {
    Future<void> openEditor() async {
      await t.tapAndSettle(find.byTooltip('Abrir ajustes'), reason: 'Ajustes');
      await t.tapAndSettle(_k('settings-shifts'), reason: 'Mis turnos');
      await t.tapAndSettle(_k('shift-row-$_night'), reason: 'Noche');
    }

    String rowText() => t
        .widget<Text>(
          find.descendant(of: _k('shift-sound'), matching: find.byType(Text)),
        )
        .data!;

    // 1. Choose the sound in the editor.
    await openEditor();
    await t.ensureVisible(_k('shift-sound'));
    await t.pump();
    expect(rowText(), 'Predeterminado');
    await t.tapAndSettle(_k('shift-sound'), reason: 'Sonido');
    expect(sounds.pickCalls, [null]);
    expect(rowText(), 'Alarma del sistema');
    await qa.shot('sonido_elegido');
    await t.tapAndSettle(_k('shift-save'), reason: 'Guardar');
    await _backHome(t);
    await app.flushWrites();
    final rows = await app.query(
      "SELECT alarm_sound AS s FROM shift_types WHERE id = '$_night'",
    );
    expect(rows.single['s'], _systemSound);
    expect(app.schedule.shiftTypeById(_night)?.alarmSound, _systemSound);

    // 2. Turn the alarm on: the Noche alarms ring on a channel of their own.
    await t.tapAndSettle(find.byTooltip('Abrir ajustes'), reason: 'Ajustes');
    await t.tapAndSettle(_k('settings-alarms'), reason: 'Alarmas');
    await t.tapAndSettle(_k('alarms-master-switch'), reason: 'interruptor');
    await t.tapAndSettle(_k('alarms-type-switch-$_night'), reason: 'Noche');
    final pending = await _until(
      t,
      () => _ours(t, plugin),
      (p) => p.isNotEmpty,
    );
    expect(pending, isNotEmpty);
    for (final r in pending) {
      expect(r.payload, contains('"c":"$_systemSound"'));
    }
    final channels = await _until(
      t,
      () => _channelIds(t, plugin),
      (ids) => ids.contains(soundChannel),
    );
    expect(channels, contains(soundChannel));
    expect(channels, contains(defaultAlarmChannelId));
    qa.metric('canales', channels.length);
    await _backHome(t);

    // 3. Close and open the app: the row still shows the sound.
    await app.restart();
    await openEditor();
    await t.ensureVisible(_k('shift-sound'));
    await t.settle();
    expect(rowText(), 'Alarma del sistema');
    await qa.shot('sonido_tras_reiniciar');

    // 4. Back to the default sound: the unused channel is deleted.
    await t.tapAndSettle(_k('shift-sound-reset'), reason: 'predeterminado');
    expect(rowText(), 'Predeterminado');
    await t.tapAndSettle(_k('shift-save'), reason: 'Guardar');
    await _backHome(t);
    await app.flushWrites();
    expect(
      (await app.query(
        "SELECT alarm_sound AS s FROM shift_types WHERE id = '$_night'",
      )).single['s'],
      isNull,
    );
    final after = await _until(
      t,
      () => _channelIds(t, plugin),
      (ids) => !ids.contains(soundChannel),
    );
    expect(after, isNot(contains(soundChannel)));
    expect(after, contains(defaultAlarmChannelId));
    final back = await _until(t, () => _ours(t, plugin), (p) => p.isNotEmpty);
    for (final r in back) {
      expect(r.payload, isNot(contains('"c":')));
    }
    qa.expectNoFlutterErrors('sonido por tipo');
  } finally {
    await _backHome(t);
    await t.runAsync(plugin.cancelAll);
  }
}

// ---- Q95 -------------------------------------------------------------------

/// Q95.
const qaReminderRemovedUndo = QaScenario(
  'Q95',
  'Recordatorio: «Quitar aviso» y deshacer',
  _reminderUndoBody,
  timeout: _timeout,
);

Future<void> _reminderUndoBody(QaContext qa) async {
  final t = qa.tester;
  final plugin = FlutterLocalNotificationsPlugin();
  final app = await _open(qa, plugin);
  try {
    final day = _targetDay();
    await _addReminder(app, day, note: 'Revisión del coche');
    final set = await _until(
      t,
      () => _ours(t, plugin),
      (p) => _reminders(p).isNotEmpty,
    );
    expect(_reminders(set), hasLength(1));
    await app.flushWrites();
    expect(await _reminderRow(app, day), 9 * 60);

    // «Quitar aviso»: gone from the sheet, the database and Android; the note
    // stays.
    await t.tapAndSettle(_k('day-reminder-remove'), reason: 'Quitar aviso');
    expect(find.text('Aviso quitado'), findsOneWidget);
    await qa.shot('aviso_quitado');
    await app.flushWrites();
    expect(await _reminderRow(app, day), isNull);
    expect(app.schedule.entries[day]?.note, 'Revisión del coche');
    final gone = await _until(
      t,
      () => _ours(t, plugin),
      (p) => _reminders(p).isEmpty,
    );
    expect(_reminders(gone), isEmpty);

    // «Deshacer» in the sheet brings it back.
    await t.tapAndSettle(_k('day-reminder-undo'), reason: 'Deshacer');
    expect(find.text('Aviso a las 09:00'), findsOneWidget);
    await app.flushWrites();
    expect(await _reminderRow(app, day), 9 * 60);
    final back = await _until(
      t,
      () => _ours(t, plugin),
      (p) => _reminders(p).isNotEmpty,
    );
    expect(_reminders(back), hasLength(1));
    expect(_reminders(back).single.id, _reminders(set).single.id);

    // Removing it once more and undoing from the paint bar (one step).
    await t.tapAndSettle(_k('day-reminder-remove'), reason: 'Quitar aviso');
    await t.tapAt(const Offset(10, 10));
    await t.settle();
    await app.flushWrites();
    expect(await _reminderRow(app, day), isNull);
    await enterPaintMode(t);
    await t.tapAndSettle(_k('undo'), reason: 'deshacer del modo pintar');
    await exitPaintMode(t);
    await app.flushWrites();
    expect(await _reminderRow(app, day), 9 * 60);
    expect(app.schedule.entries[day]?.noteReminderMinute, 9 * 60);
    final last = await _until(
      t,
      () => _ours(t, plugin),
      (p) => _reminders(p).isNotEmpty,
    );
    expect(_reminders(last), hasLength(1));
    qa.expectNoFlutterErrors('quitar aviso');
  } finally {
    await _backHome(t);
    await t.runAsync(plugin.cancelAll);
  }
}
