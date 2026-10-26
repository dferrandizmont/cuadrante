import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/alarms/application/alarm_providers.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

// «Avisarme» in the day detail (docs/paridad.md, A1). Demo data around Monday
// 19 Oct 2026, 12:00: the 20th has a note, the 24th (Libre) is empty and the
// 12th (Fiesta Nacional) is in the past.
const _oct12 = CivilDate(2026, 10, 12);
const _oct19 = CivilDate(2026, 10, 19);
const _oct20 = CivilDate(2026, 10, 20);
const _oct24 = CivilDate(2026, 10, 24);

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  setUpAll(initializeLocale);

  late FakeAlarmScheduler scheduler;
  setUp(() => scheduler = FakeAlarmScheduler());

  Future<AppUnderTest> pumpApp(WidgetTester tester) async {
    final app = await AppUnderTest.pump(
      tester,
      size: const Size(390, 1200),
      overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
    );
    await tester.pumpAndSettle();
    return app;
  }

  Future<void> openDay(WidgetTester tester, CivilDate date) async {
    await tester.ensureVisible(dayCell(date));
    await tester.pumpAndSettle();
    await tester.tap(dayCell(date));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  }

  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(_key(key));
    await tester.pumpAndSettle();
    await tester.tap(_key(key));
    await tester.pumpAndSettle();
  }

  /// Taps «Avisarme» and accepts the time the picker proposes.
  Future<void> addReminder(WidgetTester tester) async {
    await tapKey(tester, 'day-reminder-add');
    expect(find.text('Hora del aviso'), findsOneWidget);
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
  }

  /// Lets the debounced resync (1 s after a schedule change) run.
  Future<void> letSyncRun(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  ScheduleState scheduleOf(AppUnderTest app) => app.schedule;

  testWidgets('a day without a reminder offers «Avisarme»; the picker '
      'proposes 09:00 and the reminder is stored', (tester) async {
    final app = await pumpApp(tester);
    await openDay(tester, _oct24);
    expect(find.text('Avisarme'), findsOneWidget);
    expect(_key('day-reminder-remove'), findsNothing);

    await addReminder(tester);

    expect(scheduleOf(app).schedule.entries[_oct24]?.noteReminderMinute, 540);
    expect(find.text('Aviso a las 09:00'), findsOneWidget);
    expect(find.text('Quitar aviso'), findsOneWidget);
    expect(find.text('Avisarme'), findsNothing);
    // Written to the database through the normal queue.
    await app.real(
      () =>
          app.container.read(scheduleControllerProvider.notifier).pendingWrites,
    );
    final rows = await app.real(
      () => app.database
          .customSelect(
            'SELECT note_reminder_minute AS m FROM day_entries '
            "WHERE date = '2026-10-24'",
          )
          .get(),
    );
    expect(rows.single.data['m'], 540);
  });

  testWidgets('the reminder reaches the scheduler: a notification with the '
      'first line of the note', (tester) async {
    await pumpApp(tester);
    expect(
      scheduler.scheduled.where((a) => a.kind == AlarmKind.reminder),
      isEmpty,
    );

    await openDay(tester, _oct20); // note: «Cambio con Marta si sale el turno»
    await addReminder(tester);
    await letSyncRun(tester);

    final reminders = scheduler.scheduled.where(
      (a) => a.kind == AlarmKind.reminder,
    );
    expect(reminders, hasLength(1));
    expect(reminders.single.title, 'Recordatorio');
    expect(reminders.single.body, 'Cambio con Marta si sale el turno');
    expect(reminders.single.fireDate, _oct20);
    expect(reminders.single.fireMinute, 540);
    expect(scheduler.requestCalls, 0, reason: 'permission was already there');
  });

  testWidgets('a note without text rings with the generic body', (
    tester,
  ) async {
    await pumpApp(tester);
    await openDay(tester, _oct24);
    await addReminder(tester);
    await letSyncRun(tester);
    expect(
      scheduler.scheduled.singleWhere((a) => a.kind == AlarmKind.reminder).body,
      'Tienes un recordatorio para hoy',
    );
  });

  testWidgets('asks for the notification permission when it is missing, and '
      'says so when it stays denied', (tester) async {
    scheduler
      ..permission = AlarmPermission.denied
      ..permissionAfterRequest = AlarmPermission.denied;
    final app = await pumpApp(tester);
    await openDay(tester, _oct24);
    await addReminder(tester);

    expect(scheduler.requestCalls, 1);
    // The reminder is saved anyway; the row says it cannot ring.
    expect(scheduleOf(app).schedule.entries[_oct24]?.noteReminderMinute, 540);
    expect(_key('day-reminder-denied'), findsOneWidget);
    await letSyncRun(tester);
    expect(scheduler.scheduled, isEmpty);
  });

  testWidgets('granting the permission in the prompt rings the reminder, no '
      'warning', (tester) async {
    scheduler
      ..permission = AlarmPermission.denied
      ..permissionAfterRequest = AlarmPermission.granted;
    await pumpApp(tester);
    await openDay(tester, _oct24);
    await addReminder(tester);

    expect(scheduler.requestCalls, 1);
    expect(_key('day-reminder-denied'), findsNothing);
    await letSyncRun(tester);
    expect(scheduler.scheduled.map((a) => a.kind), [AlarmKind.reminder]);
  });

  testWidgets('tapping the time changes it: the picker starts on the current '
      'time and the old time is one undo away', (tester) async {
    final app = await pumpApp(tester);
    await openDay(tester, _oct24);
    await addReminder(tester);

    await tapKey(tester, 'day-reminder-time');
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    expect(fields, findsNWidgets(2));
    expect(tester.widget<TextField>(fields.at(0)).controller?.text, '9');
    await tester.enterText(fields.at(0), '18');
    await tester.enterText(fields.at(1), '45');
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(find.text('Aviso a las 18:45'), findsOneWidget);
    expect(
      scheduleOf(app).schedule.entries[_oct24]?.noteReminderMinute,
      18 * 60 + 45,
    );
    app.container.read(scheduleControllerProvider.notifier).undo();
    await tester.pumpAndSettle();
    expect(scheduleOf(app).schedule.entries[_oct24]?.noteReminderMinute, 540);
  });

  testWidgets('cancelling the picker changes nothing', (tester) async {
    final app = await pumpApp(tester);
    await openDay(tester, _oct24);
    await tapKey(tester, 'day-reminder-add');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(scheduleOf(app).schedule.entries[_oct24], isNull);
    expect(scheduleOf(app).canUndo, isFalse);
    expect(find.text('Avisarme'), findsOneWidget);
  });

  testWidgets('«Quitar aviso» removes it and «Deshacer» brings it back as '
      'the same step', (tester) async {
    final app = await pumpApp(tester);
    await openDay(tester, _oct20);
    await addReminder(tester);
    expect(find.text('Aviso a las 09:00'), findsOneWidget);

    await tapKey(tester, 'day-reminder-remove');
    expect(
      scheduleOf(app).schedule.entries[_oct20]?.noteReminderMinute,
      isNull,
    );
    // The note stays.
    expect(
      scheduleOf(app).schedule.entries[_oct20]?.note,
      'Cambio con Marta si sale el turno',
    );
    expect(find.text('Aviso quitado'), findsOneWidget);
    expect(find.text('Quitar aviso'), findsNothing);

    await tapKey(tester, 'day-reminder-undo');
    expect(scheduleOf(app).schedule.entries[_oct20]?.noteReminderMinute, 540);
    expect(find.text('Aviso a las 09:00'), findsOneWidget);
    expect(find.text('Aviso quitado'), findsNothing);
    await letSyncRun(tester);
    expect(
      scheduler.scheduled.where((a) => a.kind == AlarmKind.reminder),
      hasLength(1),
    );
  });

  testWidgets('after «Quitar aviso» «Avisarme» is back at once, next to '
      '«Deshacer» (H-T11-5)', (tester) async {
    final app = await pumpApp(tester);
    await openDay(tester, _oct20);
    await addReminder(tester);
    await tapKey(tester, 'day-reminder-remove');

    expect(find.text('Aviso quitado'), findsOneWidget);
    expect(_key('day-reminder-undo'), findsOneWidget);
    expect(_key('day-reminder-add'), findsOneWidget);

    // A new reminder without closing the sheet.
    await addReminder(tester);
    expect(scheduleOf(app).schedule.entries[_oct20]?.noteReminderMinute, 540);
    expect(find.text('Aviso a las 09:00'), findsOneWidget);
    expect(_key('day-reminder-undo'), findsNothing);
  });

  testWidgets('editing the note after «Quitar aviso» drops «Deshacer» but '
      'keeps «Avisarme» (H-T11-5)', (tester) async {
    final app = await pumpApp(tester);
    await openDay(tester, _oct20);
    await addReminder(tester);
    await tapKey(tester, 'day-reminder-remove');
    expect(_key('day-reminder-undo'), findsOneWidget);

    app.container
        .read(scheduleControllerProvider.notifier)
        .setNote(_oct20, 'otra nota');
    await tester.pumpAndSettle();

    expect(_key('day-reminder-undo'), findsNothing);
    expect(find.text('Aviso quitado'), findsNothing);
    expect(_key('day-reminder-add'), findsOneWidget);
  });

  testWidgets('removing it drops the notification', (tester) async {
    await pumpApp(tester);
    await openDay(tester, _oct24);
    await addReminder(tester);
    await letSyncRun(tester);
    expect(scheduler.scheduled, hasLength(1));

    await tapKey(tester, 'day-reminder-remove');
    await letSyncRun(tester);
    expect(scheduler.scheduled, isEmpty);
  });

  testWidgets('«Deshacer» does nothing once something else was done', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await openDay(tester, _oct24);
    await addReminder(tester);
    await tapKey(tester, 'day-reminder-remove');

    // Another edit of the schedule after the removal.
    app.container
        .read(scheduleControllerProvider.notifier)
        .setNote(_oct20, 'otra cosa');
    await tester.pumpAndSettle();
    await tapKey(tester, 'day-reminder-undo');

    expect(
      scheduleOf(app).schedule.entries[_oct24]?.noteReminderMinute,
      isNull,
    );
    expect(scheduleOf(app).schedule.entries[_oct20]?.note, 'otra cosa');
    // The offer is gone, «Avisarme» is back.
    expect(_key('day-reminder-undo'), findsNothing);
    expect(find.text('Avisarme'), findsOneWidget);
  });

  testWidgets('it is one step of the paint-bar undo', (tester) async {
    final app = await pumpApp(tester);
    await openDay(tester, _oct24);
    await addReminder(tester);
    await closeSheet(tester);
    expect(scheduleOf(app).canUndo, isTrue);

    await tester.tap(find.text('Pintar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('undo')));
    await tester.pumpAndSettle();
    expect(scheduleOf(app).schedule.entries[_oct24], isNull);
  });

  testWidgets('a day that has gone by offers nothing', (tester) async {
    await pumpApp(tester);
    await openDay(tester, _oct12);
    expect(_key('day-reminder-add'), findsNothing);
  });

  testWidgets('today proposes the next full hour, since 09:00 has gone by', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await openDay(tester, _oct19); // now is 12:00
    await addReminder(tester);
    expect(
      scheduleOf(app).schedule.entries[_oct19]?.noteReminderMinute,
      13 * 60,
    );
    expect(find.text('Aviso a las 13:00'), findsOneWidget);
    expect(_key('day-reminder-past'), findsNothing);
  });

  testWidgets('a reminder whose time has already gone by says it will not '
      'ring', (tester) async {
    final app = await pumpApp(tester);
    app.container
        .read(scheduleControllerProvider.notifier)
        .setNoteReminder(_oct19, 8 * 60);
    await tester.pumpAndSettle();
    await openDay(tester, _oct19);
    expect(find.text('Aviso a las 08:00'), findsOneWidget);
    expect(find.text('Esa hora ya pasó: no sonará.'), findsOneWidget);
    await letSyncRun(tester);
    expect(scheduler.scheduled, isEmpty);
  });

  testWidgets('on a calendar that is not the primary one it says only the '
      'primary one rings', (tester) async {
    await AppUnderTest.pump(
      tester,
      size: const Size(390, 1200),
      prepare: (db) async {
        await CalendarsRepository(db).setActive(await addSecondCalendar(db));
      },
      overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
    );
    await openDay(tester, _oct24);
    await addReminder(tester);
    expect(_key('day-reminder-primary-only'), findsOneWidget);
    await letSyncRun(tester);
    // Nothing reaches the scheduler: the plan reads the primary calendar.
    expect(scheduler.scheduled, isEmpty);
  });

  testWidgets('the primary calendar shows no such note', (tester) async {
    await pumpApp(tester);
    await openDay(tester, _oct24);
    await addReminder(tester);
    expect(_key('day-reminder-primary-only'), findsNothing);
  });
}
