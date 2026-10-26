import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/alarms/application/alarm_providers.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/data/alarm_system.dart';
import 'package:cuadrante/features/alarms/data/alarm_settings_repository.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/schedule/domain/civil_date.dart';
import 'package:cuadrante/features/alarms/presentation/alarms_settings_screen.dart';
import 'package:flutter/cupertino.dart' show CupertinoTimerPicker;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

// Demo data around Monday 19 Oct 2026, 12:00 (the harness clock): a Noche
// tonight at 22:00, so the first alarm of Noche is today at 20:30.

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  setUpAll(initializeLocale);

  const tall = Size(390, 1800);
  late FakeAlarmScheduler scheduler;

  setUp(() => scheduler = FakeAlarmScheduler());

  Future<AppUnderTest> openAlarms(WidgetTester tester) async {
    final app = await AppUnderTest.pump(
      tester,
      size: tall,
      overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
    );
    await app.openSettings();
    await tester.ensureVisible(_key('settings-alarms'));
    await tester.tap(_key('settings-alarms'));
    await tester.pumpAndSettle();
    expect(find.byType(AlarmsSettingsScreen), findsOneWidget);
    return app;
  }

  Future<AlarmSettings> stored(AppUnderTest app) =>
      app.real(() => AlarmSettingsRepository(app.database).load());

  Future<void> tapAndSettle(WidgetTester tester, String key) async {
    await tester.ensureVisible(_key(key));
    await tester.pumpAndSettle();
    await tester.tap(_key(key));
    await tester.pumpAndSettle();
  }

  String footer(WidgetTester tester) =>
      tester.widget<Text>(_key('alarms-next')).data!;

  Future<void> enableNight(WidgetTester tester) async {
    await tapAndSettle(tester, 'alarms-master-switch');
    await tapAndSettle(tester, 'alarms-type-switch-night');
  }

  testWidgets('the Settings row says Desactivadas and opens the screen', (
    tester,
  ) async {
    final app = await AppUnderTest.pump(
      tester,
      size: tall,
      overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
    );
    await app.openSettings();
    expect(
      find.descendant(
        of: _key('settings-alarms'),
        matching: find.text('Desactivadas'),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(_key('settings-alarms'));
    await tester.tap(_key('settings-alarms'));
    await tester.pumpAndSettle();
    expect(find.byType(AlarmsSettingsScreen), findsOneWidget);
    expect(find.text('Alarmas'), findsOneWidget);
    // Off: only the master switch and a line saying so.
    expect(tester.widget<Switch>(_key('alarms-master-switch')).value, isFalse);
    expect(_key('alarms-type-night'), findsNothing);
    expect(_key('alarms-test'), findsNothing);
    expect(footer(tester), 'Las alarmas están desactivadas.');
    expect(scheduler.requestCalls, 0, reason: 'nothing asked at open');
  });

  testWidgets('the master switch is stored, lists the shifts with times and '
      'asks for the permission', (tester) async {
    scheduler.permission = AlarmPermission.denied;
    scheduler.permissionAfterRequest = AlarmPermission.granted;
    final app = await openAlarms(tester);

    await tapAndSettle(tester, 'alarms-master-switch');
    expect((await stored(app)).enabled, isTrue);
    expect(scheduler.requestCalls, 1);
    expect(_key('alarms-permission-ok'), findsOneWidget);

    // Work shifts with times, in the order of the palette; no Libre,
    // Vacaciones, Saliente...
    for (final id in ['morning', 'afternoon', 'night', 'guard24', 'day12']) {
      expect(_key('alarms-type-$id'), findsOneWidget, reason: id);
    }
    for (final id in ['rest', 'vacation', 'postNight', 'personalDay']) {
      expect(_key('alarms-type-$id'), findsNothing, reason: id);
    }
    expect(find.text('TIPOS DE TURNO'), findsOneWidget);
    expect(
      footer(tester),
      'No hay ningún aviso previsto en los próximos días.',
    );
  });

  testWidgets('absences are not listed even when they have times', (
    tester,
  ) async {
    scheduler.permission = AlarmPermission.granted;
    final app = await AppUnderTest.pump(
      tester,
      size: tall,
      overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
      // Someone gave Vacaciones (an absence) a time range.
      prepare: (db) => db.customStatement(
        'UPDATE shift_types SET start_minute = 480, end_minute = 900 '
        "WHERE id IN ('vacation', 'personalDay')",
      ),
    );
    await app.openSettings();
    await tester.ensureVisible(_key('settings-alarms'));
    await tester.tap(_key('settings-alarms'));
    await tester.pumpAndSettle();
    await tapAndSettle(tester, 'alarms-master-switch');

    expect(_key('alarms-type-night'), findsOneWidget);
    expect(_key('alarms-type-vacation'), findsNothing);
    expect(_key('alarms-type-personalDay'), findsNothing);
  });

  testWidgets('the Settings row says Desactivadas when the only switch left '
      'on is a type that cannot ring', (tester) async {
    final app = await AppUnderTest.pump(
      tester,
      size: tall,
      overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
      prepare: (db) async {
        await AlarmSettingsRepository(db).save(
          const AlarmSettings(
            enabled: true,
            byShiftType: {'night': AlarmTypeSettings(enabled: true)},
          ),
        );
        await db.customStatement(
          "UPDATE shift_types SET category = 'absence' WHERE id = 'night'",
        );
      },
    );
    await app.openSettings();
    expect(
      find.descendant(
        of: _key('settings-alarms'),
        matching: find.text('Desactivadas'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a type switch shows its choices and the next alarm', (
    tester,
  ) async {
    final app = await openAlarms(tester);
    await tapAndSettle(tester, 'alarms-master-switch');
    expect(_key('alarms-before-night'), findsNothing);

    await tapAndSettle(tester, 'alarms-type-switch-night');
    final night = (await stored(app)).forShiftType('night');
    expect(night.enabled, isTrue);
    expect(night.minutesBefore, 90);
    expect(
      find.descendant(
        of: _key('alarms-before-night'),
        matching: find.text('1 h 30 min'),
      ),
      findsOneWidget,
    );
    // Planner: the Noche of tonight, 22:00 minus 90 min.
    expect(footer(tester), 'Próximo aviso: lun 19 de octubre, 20:30 · Noche');
    // The real sync scheduled the same plan.
    expect(scheduler.scheduled, isNotEmpty);
    expect(scheduler.scheduled.every((a) => a.shiftTypeId == 'night'), isTrue);
    expect(scheduler.scheduled.first.fireMinute, 20 * 60 + 30);

    // Off again: nothing left, and the type keeps its other choices.
    await tapAndSettle(tester, 'alarms-type-switch-night');
    expect((await stored(app)).forShiftType('night').enabled, isFalse);
    expect(scheduler.scheduled, isEmpty);
    expect(_key('alarms-before-night'), findsNothing);
  });

  group('"Próximo aviso" does not keep an alarm that already rang '
      '(H-T11-7)', () {
    // Monday 19 at 20:29:30 in the harness: Noche alarm at 20:30 is next.
    var now = DateTime(2026, 10, 19, 20, 29, 30);

    Future<void> openWithClock(
      WidgetTester tester, {
      DateTime? at,
    }) async {
      now = at ?? DateTime(2026, 10, 19, 20, 29, 30);
      await AppUnderTest.pump(
        tester,
        size: tall,
        overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
        clock: () => now,
      );
      // The harness opens on the month screen; go to Alarmas.
      await tester.tap(find.byTooltip('Abrir ajustes'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('settings-alarms'));
      await tester.tap(_key('settings-alarms'));
      await tester.pumpAndSettle();
      await enableNight(tester);
      expect(footer(tester), 'Próximo aviso: lun 19 de octubre, 20:30 · Noche');
    }

    testWidgets('it moves on by itself once the alarm time has passed', (
      tester,
    ) async {
      await openWithClock(tester);
      now = DateTime(2026, 10, 19, 20, 30, 44);
      // The provider armed a timer for one second after 20:30.
      await tester.pump(const Duration(seconds: 40));
      await tester.pumpAndSettle();
      expect(footer(tester), 'Próximo aviso: mar 20 de octubre, 20:30 · Noche');
    });

    testWidgets('it moves on within a minute when the clock jumps past the '
        'alarm (the wall clock was changed, a timer set hours ago would '
        'never fire)', (tester) async {
      // Opened at midday: the exact timer is armed for the next 24 h at most.
      await openWithClock(tester, at: DateTime(2026, 10, 19, 12));
      // The wall clock moves on (the QA moved it with `adb`; a time zone or a
      // manual change does the same) and the app stays on screen. Monotonic
      // timers do not notice: only a minute tick looks at the clock again.
      now = DateTime(2026, 10, 19, 20, 30, 44);
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
      expect(footer(tester), 'Próximo aviso: mar 20 de octubre, 20:30 · Noche');
    });

    testWidgets('it is recomputed when the app comes back', (tester) async {
      await openWithClock(tester);
      // Frozen process: no timer fires; the clock jumps and the app resumes.
      now = DateTime(2026, 10, 19, 20, 30, 44);
      final binding = tester.binding;
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(footer(tester), 'Próximo aviso: mar 20 de octubre, 20:30 · Noche');
    });
  });

  testWidgets('"Antes del turno": presets and a custom duration', (
    tester,
  ) async {
    final app = await openAlarms(tester);
    await enableNight(tester);

    await tapAndSettle(tester, 'alarms-before-night');
    for (final label in [
      '30 min',
      '1 h',
      '1 h 30 min',
      '2 h',
      'Personalizado',
    ]) {
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: label,
      );
    }
    await tester.tap(
      find.descendant(of: find.byType(BottomSheet), matching: find.text('2 h')),
    );
    await tester.pumpAndSettle();
    expect((await stored(app)).forShiftType('night').minutesBefore, 120);
    expect(footer(tester), 'Próximo aviso: lun 19 de octubre, 20:00 · Noche');
    expect(scheduler.scheduled.first.fireMinute, 20 * 60);

    // Personalizado: the duration picker.
    await tapAndSettle(tester, 'alarms-before-night');
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Personalizado'),
      ),
    );
    await tester.pumpAndSettle();
    expect(_key('alarms-lead-picker'), findsOneWidget);
    tester
        .widget<CupertinoTimerPicker>(_key('alarms-lead-picker'))
        .onTimerDurationChanged(const Duration(minutes: 45));
    await tester.tap(_key('alarms-lead-apply'));
    await tester.pumpAndSettle();
    expect((await stored(app)).forShiftType('night').minutesBefore, 45);
    expect(
      find.descendant(
        of: _key('alarms-before-night'),
        matching: find.text('45 min'),
      ),
      findsOneWidget,
    );
    expect(footer(tester), 'Próximo aviso: lun 19 de octubre, 21:15 · Noche');

    // The custom value shows in the list, selected.
    await tapAndSettle(tester, 'alarms-before-night');
    expect(find.textContaining('Personalizado · 45 min'), findsOneWidget);
  });

  testWidgets('the reminder the evening before: switch, stored, planned', (
    tester,
  ) async {
    final app = await openAlarms(tester);
    await enableNight(tester);
    expect(_key('alarms-daybefore-time-night'), findsNothing);

    await tapAndSettle(tester, 'alarms-daybefore-switch-night');
    final night = (await stored(app)).forShiftType('night');
    expect(night.dayBefore, isTrue);
    expect(night.dayBeforeMinute, 20 * 60);
    expect(find.text('A las 20:00'), findsOneWidget);
    expect(
      find.descendant(
        of: _key('alarms-daybefore-time-night'),
        matching: find.text('20:00'),
      ),
      findsOneWidget,
    );
    // The first reminder is tonight at 20:00 (for tomorrow's Noche), before
    // the 20:30 alarm of tonight's.
    expect(
      footer(tester),
      'Próximo aviso: lun 19 de octubre, 20:00 · Noche, el día anterior',
    );
    final kinds = scheduler.scheduled.map((a) => a.kind).toSet();
    expect(kinds, {AlarmKind.shift, AlarmKind.dayBefore});

    await tapAndSettle(tester, 'alarms-daybefore-switch-night');
    expect((await stored(app)).forShiftType('night').dayBefore, isFalse);
    expect(scheduler.scheduled.map((a) => a.kind).toSet(), {AlarmKind.shift});
  });

  testWidgets('the own text of the notification', (tester) async {
    final app = await openAlarms(tester);
    await enableNight(tester);
    expect(
      find.descendant(
        of: _key('alarms-label-night'),
        matching: find.text('El de siempre'),
      ),
      findsOneWidget,
    );

    await tapAndSettle(tester, 'alarms-label-night');
    await tester.enterText(_key('alarms-label-field'), '  A trabajar ');
    await tester.tap(_key('alarms-label-apply'));
    await tester.pumpAndSettle();
    expect((await stored(app)).forShiftType('night').label, 'A trabajar');
    expect(scheduler.scheduled.first.title, 'A trabajar');
    expect(
      find.descendant(
        of: _key('alarms-label-night'),
        matching: find.text('A trabajar'),
      ),
      findsOneWidget,
    );

    await tapAndSettle(tester, 'alarms-label-night');
    await tester.tap(_key('alarms-label-reset'));
    await tester.pumpAndSettle();
    expect((await stored(app)).forShiftType('night').label, isNull);
    expect(scheduler.scheduled.first.title, 'Turno de Noche a las 22:00');
  });

  group('permissions', () {
    testWidgets('all granted: a green "Todo listo" card', (tester) async {
      await openAlarms(tester);
      await tapAndSettle(tester, 'alarms-master-switch');
      expect(_key('alarms-permission-ok'), findsOneWidget);
      expect(find.text('Todo listo'), findsOneWidget);
      expect(_key('alarms-permission-notifications'), findsNothing);
      expect(_key('alarms-permission-exact'), findsNothing);
      expect(scheduler.requestCalls, 0, reason: 'already granted: no prompt');
    });

    testWidgets('notifications denied: explains and offers "Permitir"', (
      tester,
    ) async {
      scheduler
        ..permission = AlarmPermission.denied
        ..permissionAfterRequest = AlarmPermission.denied;
      await openAlarms(tester);
      await tapAndSettle(tester, 'alarms-master-switch');
      // Turning the alarms on asked once; the system said no.
      expect(scheduler.requestCalls, 1);
      expect(find.text('Faltan las notificaciones'), findsOneWidget);
      expect(
        find.textContaining('actívalas en los ajustes del sistema'),
        findsOneWidget,
      );

      scheduler.permissionAfterRequest = AlarmPermission.granted;
      await tapAndSettle(tester, 'alarms-permission-allow');
      expect(scheduler.requestCalls, 2);
      expect(_key('alarms-permission-ok'), findsOneWidget);
      expect(find.text('Faltan las notificaciones'), findsNothing);
    });

    testWidgets('notifications denied for good: «Abrir ajustes» instead of a '
        '«Permitir» that does nothing (H-T11-1)', (tester) async {
      final system = FakeAlarmSystem()..blocked = true;
      scheduler
        ..permission = AlarmPermission.denied
        ..permissionAfterRequest = AlarmPermission.denied;
      final app = await AppUnderTest.pump(
        tester,
        size: tall,
        overrides: [
          alarmSchedulerProvider.overrideWithValue(scheduler),
          alarmSystemProvider.overrideWithValue(system),
        ],
      );
      await app.openSettings();
      await tester.ensureVisible(_key('settings-alarms'));
      await tester.tap(_key('settings-alarms'));
      await tester.pumpAndSettle();
      await tapAndSettle(tester, 'alarms-master-switch');

      expect(find.text('Faltan las notificaciones'), findsOneWidget);
      expect(_key('alarms-permission-allow'), findsNothing);
      expect(find.text('Permitir'), findsNothing);
      expect(_key('alarms-permission-notifications-settings'), findsOneWidget);
      expect(find.textContaining('Android ya no te pregunta'), findsOneWidget);

      final asked = scheduler.requestCalls;
      await tapAndSettle(tester, 'alarms-permission-notifications-settings');
      expect(system.openedSettings, 1);
      expect(scheduler.requestCalls, asked, reason: 'no new prompt');

      // Back from the system settings with the notifications on: the card
      // is re-read on resume and turns into «Todo listo».
      scheduler.permission = AlarmPermission.granted;
      system.blocked = false;
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(_key('alarms-permission-ok'), findsOneWidget);
      expect(_key('alarms-permission-notifications-settings'), findsNothing);
    });

    testWidgets('exact alarms not allowed: warns about the delay and opens the '
        'system screen', (tester) async {
      scheduler.exactAllowed = false;
      await openAlarms(tester);
      await tapAndSettle(tester, 'alarms-master-switch');
      expect(find.text('Alarmas y recordatorios'), findsOneWidget);
      expect(
        find.textContaining(
          'Las alarmas pueden llegar con unos minutos de retraso',
        ),
        findsOneWidget,
      );
      expect(_key('alarms-permission-ok'), findsNothing);

      await tapAndSettle(tester, 'alarms-permission-open');
      expect(scheduler.exactRequestCalls, 1);

      // Back from the system screen with the access granted.
      scheduler.exactAllowed = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(_key('alarms-permission-ok'), findsOneWidget);
    });

    testWidgets('turning a type on asks again if the permission is missing', (
      tester,
    ) async {
      await openAlarms(tester);
      await tapAndSettle(tester, 'alarms-master-switch');
      expect(scheduler.requestCalls, 0);
      scheduler
        ..permission = AlarmPermission.denied
        ..permissionAfterRequest = AlarmPermission.granted;
      await tapAndSettle(tester, 'alarms-type-switch-night');
      expect(scheduler.requestCalls, 1);
    });

    testWidgets('without permission nothing is scheduled', (tester) async {
      scheduler
        ..permission = AlarmPermission.denied
        ..permissionAfterRequest = AlarmPermission.denied;
      await openAlarms(tester);
      await enableNight(tester);
      expect(scheduler.scheduled, isEmpty);
      // The footer still tells what the plan would ring.
      expect(footer(tester), startsWith('Próximo aviso:'));
    });
  });

  group('probar aviso', () {
    testWidgets('schedules a test notification in 10 seconds', (tester) async {
      await openAlarms(tester);
      await tapAndSettle(tester, 'alarms-master-switch');
      await tapAndSettle(tester, 'alarms-test');
      final test = scheduler.oneOffs.single;
      expect(test.kind, OneOffKind.test);
      expect(test.fireAt, harnessNow.add(const Duration(seconds: 10)));
      expect(test.title, 'Aviso de prueba');
      expect(test.payload.startsWith(alarmPayloadPrefix), isFalse);
      expect(find.text('Te avisaremos en 10 segundos.'), findsOneWidget);
      expect(scheduler.strings?.channelName, 'Alarmas de turno');
    });

    testWidgets('without the permission it asks, and says so if refused', (
      tester,
    ) async {
      await openAlarms(tester);
      await tapAndSettle(tester, 'alarms-master-switch');
      scheduler
        ..permission = AlarmPermission.denied
        ..permissionAfterRequest = AlarmPermission.denied;
      await tapAndSettle(tester, 'alarms-test');
      expect(scheduler.requestCalls, 1);
      expect(scheduler.oneOffs, isEmpty);
      expect(
        find.text(
          'Sin el permiso de notificaciones no podemos probar el aviso.',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('turning everything off leaves nothing scheduled', (
    tester,
  ) async {
    final app = await openAlarms(tester);
    await enableNight(tester);
    await tapAndSettle(tester, 'alarms-daybefore-switch-night');
    expect(scheduler.scheduled, isNotEmpty);

    await tapAndSettle(tester, 'alarms-master-switch');
    expect((await stored(app)).enabled, isFalse);
    expect(scheduler.scheduled, isEmpty);
    expect(footer(tester), 'Las alarmas están desactivadas.');
    // The choices are kept for when the user comes back.
    expect((await stored(app)).forShiftType('night').dayBefore, isTrue);
    await app.back();
    expect(
      find.descendant(
        of: _key('settings-alarms'),
        matching: find.text('Desactivadas'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('layout survives a narrow screen and text x2', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    final app = await AppUnderTest.pump(
      tester,
      size: const Size(320, 640),
      overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
    );
    await app.openSettings();
    await tester.ensureVisible(_key('settings-alarms'));
    await tester.tap(_key('settings-alarms'));
    await tester.pumpAndSettle();
    await enableNight(tester);
    await tapAndSettle(tester, 'alarms-daybefore-switch-night');
    await tapAndSettle(tester, 'alarms-label-night');
    await tester.enterText(
      _key('alarms-label-field'),
      'Un texto de aviso bastante largo para probar',
    );
    await tester.tap(_key('alarms-label-apply'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('H-T11-6: a long custom «Texto del aviso» wraps under its title '
      '(up to three lines, aligned with it), not cut or pushed right', (
    tester,
  ) async {
    const label = 'Preparar la mochila y llevar el uniforme de refuerzo';
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    final app = await AppUnderTest.pump(
      tester,
      size: const Size(320, 900),
      overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
    );
    await app.openSettings();
    await tester.ensureVisible(_key('settings-alarms'));
    await tester.tap(_key('settings-alarms'));
    await tester.pumpAndSettle();
    await enableNight(tester);
    await tapAndSettle(tester, 'alarms-label-night');
    await tester.enterText(_key('alarms-label-field'), label);
    await tester.tap(_key('alarms-label-apply'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final row = _key('alarms-label-night');
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    final value = find.descendant(of: row, matching: find.text(label));
    final title = find.descendant(
      of: row,
      matching: find.text('Texto del aviso'),
    );
    expect(value, findsOneWidget);
    final valueBox = tester.getRect(value);
    final titleBox = tester.getRect(title);
    expect(valueBox.top, greaterThanOrEqualTo(titleBox.bottom));
    expect(valueBox.left, closeTo(titleBox.left, 0.01));
    final paragraph = tester.renderObject<RenderParagraph>(value);
    final lines = paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: label.length),
        )
        .map((b) => b.top.round())
        .toSet();
    expect(lines.length, inInclusiveRange(2, 3));
  });

  testWidgets('skipped days older than today are pruned on the next edit', (
    tester,
  ) async {
    final app = await AppUnderTest.pump(
      tester,
      size: tall,
      prepare: (db) => AlarmSettingsRepository(db).save(
        AlarmSettings(
          enabled: true,
          skippedDates: {CivilDate(2026, 10, 1), CivilDate(2026, 10, 25)},
        ),
      ),
      overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
    );
    final controller = app.container.read(alarmSettingsProvider.notifier);
    await app.real(
      () => controller.setSkipped(const CivilDate(2026, 11, 2), skipped: true),
    );
    // Let the resync the edit triggered finish before the test ends.
    await app.real(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    // Today is 19 Oct: the 1st is gone, the 25th and the new one stay.
    expect((await stored(app)).skippedDates, {
      const CivilDate(2026, 10, 25),
      const CivilDate(2026, 11, 2),
    });
  });

  testWidgets('the Settings row says Activadas when a type is on', (
    tester,
  ) async {
    final app = await openAlarms(tester);
    await enableNight(tester);
    await app.back();
    expect(
      find.descendant(
        of: _key('settings-alarms'),
        matching: find.text('Activadas'),
      ),
      findsOneWidget,
    );
  });
}
