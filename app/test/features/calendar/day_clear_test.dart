import 'package:cuadrante/core/widgets/buttons.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'day_detail_test.dart'
    show
        closeDay,
        enterNote,
        expectStoredIsShown,
        oct22,
        oct26,
        openDay,
        schedule,
        tapInSheet;
import 'harness.dart';

// QA campaign, T09 (H-T09-2): «Borrar día» was off on a day that only had a
// note, so the note could not be cleared with it. It is on whenever the day
// has anything: a shift, the note, its reminder, extra or missing minutes or
// an own holiday of the person, and it clears all of it in one undoable step.

Finder _key(String key) => find.byKey(ValueKey(key));

bool _clearEnabled(WidgetTester tester) =>
    tester.widget<SecondaryButton>(_key('day-clear')).onPressed != null;

ScheduleController _controller(WidgetTester tester) =>
    containerOf(tester).read(scheduleControllerProvider.notifier);

void main() {
  testWidgets('a day with only a note: «Borrar día» is on, clears the note and '
      'undo brings it back', (tester) async {
    await pumpCalendar(tester);
    // 22 October is empty (an empty override): give it a note and nothing else.
    _controller(tester).setNote(oct22, 'Cita en el banco');
    await tester.pumpAndSettle();
    expect(schedule(tester).resolve(oct22).shifts, isEmpty);

    await openDay(tester, oct22);
    expect(_clearEnabled(tester), isTrue);
    await tapInSheet(tester, 'day-clear');
    expect(schedule(tester).entries[oct22]?.note, isNull);
    await expectStoredIsShown(tester);
    expect(find.text('Día borrado'), findsOneWidget);

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(schedule(tester).entries[oct22]?.note, 'Cita en el banco');
    await expectStoredIsShown(tester);
  });

  testWidgets('a note typed but not saved yet also turns it on', (
    tester,
  ) async {
    await pumpCalendar(tester);
    await openDay(tester, oct22);
    expect(_clearEnabled(tester), isFalse);
    await enterNote(tester, 'Algo');
    expect(_clearEnabled(tester), isTrue);
    await tester.enterText(_key('day-note'), '  ');
    await tester.pump();
    expect(_clearEnabled(tester), isFalse);
  });

  testWidgets('a day with only a reminder or only extra minutes is not empty '
      'either', (tester) async {
    await pumpCalendar(tester);
    _controller(tester).setDayExtras(oct22, overtimeMinutes: 30);
    await tester.pumpAndSettle();
    await openDay(tester, oct22);
    expect(_clearEnabled(tester), isTrue);
    await tapInSheet(tester, 'day-clear');
    expect(schedule(tester).entries[oct22]?.overtimeMinutes, isNull);
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(schedule(tester).entries[oct22]?.overtimeMinutes, 30);
  });

  testWidgets('everything at once: shifts, note, reminder, extras and the '
      'own holiday go, and one undo restores them all', (tester) async {
    await pumpCalendar(tester);
    final controller = _controller(tester);
    controller
      ..setNote(oct26, 'Llevar el uniforme')
      ..setNoteReminder(oct26, 8 * 60)
      ..setDayExtras(oct26, overtimeMinutes: 60, earlyLeaveMinutes: 15);
    await containerOf(tester)
        .read(holidayControllerProvider.notifier)
        .addUserHoliday(date: oct26, name: 'Cumple de Ana');
    await tester.pumpAndSettle();
    final before = schedule(tester).entries[oct26];
    expect(before?.note, 'Llevar el uniforme');
    expect(before?.noteReminderMinute, 8 * 60);

    await openDay(tester, oct26);
    await tapInSheet(tester, 'day-clear');
    final cleared = schedule(tester);
    expect(cleared.resolve(oct26).shifts, isEmpty);
    expect(cleared.entries[oct26]?.note, isNull);
    expect(cleared.entries[oct26]?.noteReminderMinute, isNull);
    expect(cleared.entries[oct26]?.overtimeMinutes, isNull);
    expect(cleared.entries[oct26]?.earlyLeaveMinutes, isNull);
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(holidaysProvider)[oct26], isNull);
    await expectStoredIsShown(tester);

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    final back = schedule(tester);
    expect(back.entries[oct26], before);
    expect(back.resolve(oct26).shiftIds, ['morning']);
    final holiday = containerOf(tester).read(holidaysProvider)[oct26];
    expect(holiday?.name, 'Cumple de Ana');
    expect(holiday?.isUserAdded, isTrue);
    await expectStoredIsShown(tester);
  });

  testWidgets('a day whose only content is an own holiday: on, clears it, '
      'undo gives it back', (tester) async {
    await pumpCalendar(tester);
    await containerOf(tester)
        .read(holidayControllerProvider.notifier)
        .addUserHoliday(date: oct22, name: 'Fiesta del barrio');
    await tester.pumpAndSettle();

    await openDay(tester, oct22);
    expect(_clearEnabled(tester), isTrue);
    await tapInSheet(tester, 'day-clear');
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(holidaysProvider)[oct22], isNull);
    expect(find.text('Deshacer'), findsOneWidget);

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(
      containerOf(tester).read(holidaysProvider)[oct22]?.name,
      'Fiesta del barrio',
    );
  });

  testWidgets('a day with nothing at all keeps it off', (tester) async {
    await pumpCalendar(tester);
    await openDay(tester, oct22);
    expect(_clearEnabled(tester), isFalse);
    await closeDay(tester);
  });
}
