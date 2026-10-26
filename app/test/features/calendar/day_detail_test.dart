import 'package:cuadrante/core/widgets/buttons.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/data/schedule_snapshot.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

// Demo data around Monday 19 Oct 2026 (see day_edit_controller_test.dart):
// Noche 19-23, Libre 24-25, Mañana 26-30; 20 note only, 21 Mañana + Tarde,
// 22 empty override.
const oct12 = CivilDate(2026, 10, 12); // Fiesta Nacional
const oct20 = CivilDate(2026, 10, 20);
const oct21 = CivilDate(2026, 10, 21);
const oct22 = CivilDate(2026, 10, 22);
const oct24 = CivilDate(2026, 10, 24);
const oct26 = CivilDate(2026, 10, 26);

Finder _key(String key) => find.byKey(ValueKey(key));

Finder get _sheet => find.byType(BottomSheet);

String _holidayLine(WidgetTester tester) =>
    tester.widget<Text>(_key('day-holiday-line')).data!;

Future<void> openDay(WidgetTester tester, CivilDate date) async {
  await revealCell(tester, date);
  await tester.tap(cell(date));
  await tester.pumpAndSettle();
  expect(_sheet, findsOneWidget);
}

/// Closes the sheet the way a user does: tapping the dimmed area (or, when
/// the sheet fills the whole screen, going back).
Future<void> closeDay(WidgetTester tester) async {
  if (tester.getTopLeft(_sheet).dy > 20) {
    await tester.tapAt(const Offset(10, 10));
  } else {
    await Navigator.of(tester.element(_sheet)).maybePop();
  }
  await tester.pumpAndSettle();
  expect(_sheet, findsNothing);
}

Future<void> tapInSheet(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

/// The app leaves the foreground the way the system says it (resumed,
/// inactive, hidden, paused); the test comes back by itself at the end.
void goToBackground(WidgetTester tester) {
  final binding = tester.binding;
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    binding.handleAppLifecycleStateChanged(state);
  }
  addTearDown(() => comeBack(tester));
}

void comeBack(WidgetTester tester) {
  final binding = tester.binding;
  if (binding.lifecycleState == AppLifecycleState.resumed) return;
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    binding.handleAppLifecycleStateChanged(state);
  }
}

Future<void> enterNote(WidgetTester tester, String text) async {
  await tester.ensureVisible(_key('day-note'));
  await tester.pumpAndSettle();
  await tester.enterText(_key('day-note'), text);
  await tester.pump();
}

ScheduleState stateOf(WidgetTester tester) =>
    containerOf(tester).read(scheduleControllerProvider);

Schedule schedule(WidgetTester tester) => stateOf(tester).schedule;

Future<ScheduleSnapshot> stored(WidgetTester tester) async {
  final container = containerOf(tester);
  return (await tester.runAsync(() async {
    await container.read(scheduleControllerProvider.notifier).pendingWrites;
    return container.read(scheduleRepositoryProvider).load(mainCalendarId);
  }))!;
}

Future<void> expectStoredIsShown(WidgetTester tester) async {
  final snapshot = await stored(tester);
  expect(snapshot.schedule.entries, schedule(tester).entries);
}

Future<void> undoFromMonth(WidgetTester tester) async {
  await enterPaintMode(tester);
  await tester.tap(find.byKey(const ValueKey('undo')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('paint-done')));
  await tester.pumpAndSettle();
}

void main() {
  group('opening', () {
    testWidgets('shows the date, the holiday, the shifts with times and the '
        'note', (tester) async {
      await pumpCalendar(tester);
      await openDay(tester, oct12);
      expect(find.text('Lunes, 12 de octubre'), findsOneWidget);
      expect(find.text('Festivo: Fiesta Nacional de España'), findsOneWidget);
      await closeDay(tester);

      await openDay(tester, oct20);
      expect(
        find.descendant(of: _sheet, matching: find.text('22:00–06:00')),
        findsOneWidget,
      );
      expect(find.text('Cambio con Marta si sale el turno'), findsOneWidget);
      expect(find.text('Según tu patrón'), findsOneWidget);
      await closeDay(tester);

      await openDay(tester, oct22);
      expect(find.text('Este día no tiene turno.'), findsOneWidget);
    });

    testWidgets('a hand-changed day says so', (tester) async {
      await pumpCalendar(tester);
      await openDay(tester, oct21);
      expect(find.text('Cambiado a mano'), findsOneWidget);
      expect(_key('day-shift-0'), findsOneWidget);
      expect(_key('day-shift-1'), findsOneWidget);
    });
  });

  group('shifts', () {
    testWidgets('adding from the palette doubles the day, in one undo step', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openDay(tester, oct24);
      expect(find.text('Añadir turno'.toUpperCase()), findsNothing);
      expect(find.text('DOBLAR CON OTRO TURNO'), findsOneWidget);

      await tapInSheet(tester, 'day-add-guard24');
      expect(schedule(tester).resolve(oct24).shiftIds, ['rest', 'guard24']);
      expect(_key('day-shift-1'), findsOneWidget);
      // The one already in the day cannot be added again.
      await tapInSheet(tester, 'day-add-guard24');
      expect(schedule(tester).resolve(oct24).shiftIds, ['rest', 'guard24']);
      await expectStoredIsShown(tester);

      await closeDay(tester);
      expect(
        find.descendant(of: cell(oct24), matching: find.text('G')),
        findsOneWidget,
      );
      await undoFromMonth(tester);
      expect(schedule(tester).resolve(oct24).shiftIds, ['rest']);
      await expectStoredIsShown(tester);
    });

    testWidgets('an empty day offers "Añadir turno"', (tester) async {
      await pumpCalendar(tester);
      await openDay(tester, oct22);
      expect(find.text('AÑADIR TURNO'), findsOneWidget);
      await tapInSheet(tester, 'day-add-morning');
      expect(schedule(tester).resolve(oct22).shiftIds, ['morning']);
      expect(find.text('Este día no tiene turno.'), findsNothing);
    });

    testWidgets('removing a shift', (tester) async {
      await pumpCalendar(tester);
      await openDay(tester, oct21);
      await tapInSheet(tester, 'day-remove-0');
      expect(schedule(tester).resolve(oct21).shiftIds, ['afternoon']);
      expect(_key('day-shift-1'), findsNothing);
      // With a single shift there is nothing to reorder.
      expect(_key('day-up-0'), findsNothing);
      await expectStoredIsShown(tester);

      await tapInSheet(tester, 'day-remove-0');
      expect(schedule(tester).resolve(oct21).shiftIds, isEmpty);
      expect(find.text('Este día no tiene turno.'), findsOneWidget);
      await expectStoredIsShown(tester);
    });

    testWidgets('reordering with up and down', (tester) async {
      await pumpCalendar(tester);
      await openDay(tester, oct21);
      expect(schedule(tester).resolve(oct21).shiftIds, [
        'morning',
        'afternoon',
      ]);
      // The ends cannot move further.
      expect(tester.widget<IconButton>(_key('day-up-0')).onPressed, isNull);
      expect(tester.widget<IconButton>(_key('day-down-1')).onPressed, isNull);

      await tapInSheet(tester, 'day-down-0');
      expect(schedule(tester).resolve(oct21).shiftIds, [
        'afternoon',
        'morning',
      ]);
      await expectStoredIsShown(tester);
      await tapInSheet(tester, 'day-up-1');
      expect(schedule(tester).resolve(oct21).shiftIds, [
        'morning',
        'afternoon',
      ]);
    });

    testWidgets('"Borrar día" empties the day, says so and can be undone', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openDay(tester, oct26);
      await tapInSheet(tester, 'day-clear');
      expect(schedule(tester).resolve(oct26).shiftIds, isEmpty);
      await expectStoredIsShown(tester);

      // The sheet closes (a notice would hide behind it) and the notice
      // offers the undo, as «Duplicar en otro día» does.
      expect(_sheet, findsNothing);
      expect(find.text('Día borrado'), findsOneWidget);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(schedule(tester).resolve(oct26).shiftIds, ['morning']);
      await expectStoredIsShown(tester);
    });

    testWidgets('"Borrar día" is off on an empty day', (tester) async {
      await pumpCalendar(tester);
      await openDay(tester, oct22);
      expect(
        tester.widget<SecondaryButton>(_key('day-clear')).onPressed,
        isNull,
      );
    });

    testWidgets('the undo of "Borrar día" is gone once something else is '
        'done', (tester) async {
      await pumpCalendar(tester);
      await openDay(tester, oct26);
      await tapInSheet(tester, 'day-clear');
      // Something else happens before the user taps «Deshacer».
      containerOf(tester)
          .read(scheduleControllerProvider.notifier)
          .setDayShifts(oct24, const ['night']);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      // The day stays empty: the notice only undoes the latest step.
      expect(schedule(tester).resolve(oct26).shiftIds, isEmpty);
      expect(schedule(tester).resolve(oct24).shiftIds, ['night']);
    });
  });

  group('back to the rotation', () {
    testWidgets('shows what the rotation gives and goes back to it', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openDay(tester, oct21);
      expect(_key('day-reset'), findsOneWidget);
      expect(find.text('El patrón da: Noche 22:00–06:00'), findsOneWidget);

      await tapInSheet(tester, 'day-reset');
      expect(schedule(tester).resolve(oct21).shiftIds, ['night']);
      expect(schedule(tester).resolve(oct21).source, DaySource.pattern);
      expect(_key('day-reset'), findsNothing);
      expect(find.text('Según tu patrón'), findsOneWidget);
      expect(stateOf(tester).canUndo, isTrue);
      await expectStoredIsShown(tester);
      await closeDay(tester);

      await undoFromMonth(tester);
      expect(schedule(tester).resolve(oct21).shiftIds, [
        'morning',
        'afternoon',
      ]);
    });

    testWidgets('an emptied day says the rotation gives a shift', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openDay(tester, oct22);
      expect(find.text('El patrón da: Noche 22:00–06:00'), findsOneWidget);
    });

    testWidgets('a day without override has no such button', (tester) async {
      await pumpCalendar(tester);
      await openDay(tester, oct24);
      expect(_key('day-reset'), findsNothing);
    });

    testWidgets('the note survives going back to the rotation', (tester) async {
      await pumpCalendar(tester);
      await openDay(tester, oct21);
      await enterNote(tester, 'Ojo con el cambio');
      await tapInSheet(tester, 'day-reset');
      expect(schedule(tester).resolve(oct21).note, 'Ojo con el cambio');
      expect(schedule(tester).resolve(oct21).shiftIds, ['night']);
    });
  });

  testWidgets('H-T18-3: the dimmed area behind the sheet is announced '
      '«Cerrar», not «Sombreado»', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCalendar(tester);
    await openDay(tester, oct24);

    final barriers = tester
        .widgetList<ModalBarrier>(find.byType(ModalBarrier))
        .where((b) => b.semanticsLabel != null);
    expect(barriers.map((b) => b.semanticsLabel), ['Cerrar']);
    expect(find.bySemanticsLabel('Sombreado'), findsNothing);
    handle.dispose();
  });

  group('note', () {
    testWidgets('is saved when the sheet closes and is there when reopened', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openDay(tester, oct24);
      await enterNote(tester, 'Cumple de Ana \u{1F382}\nllevar tarta');
      // Nothing yet: it is saved when the field loses focus or on close.
      await closeDay(tester);
      await tester.pump();

      expect(
        schedule(tester).resolve(oct24).note,
        'Cumple de Ana \u{1F382}\nllevar tarta',
      );
      expect(schedule(tester).resolve(oct24).shiftIds, ['rest']);
      await expectStoredIsShown(tester);

      await openDay(tester, oct24);
      expect(
        tester.widget<TextField>(_key('day-note')).controller?.text,
        'Cumple de Ana \u{1F382}\nllevar tarta',
      );
    });

    testWidgets('is one undo step', (tester) async {
      await pumpCalendar(tester);
      await openDay(tester, oct24);
      await enterNote(tester, 'una');
      await enterNote(tester, 'una nota más larga');
      await closeDay(tester);
      await tester.pump();
      expect(schedule(tester).resolve(oct24).note, 'una nota más larga');

      await undoFromMonth(tester);
      expect(schedule(tester).resolve(oct24).note, isNull);
      expect(stateOf(tester).canUndo, isFalse);
    });

    // H-T19-1: a note being typed must reach the database before the system
    // can kill the app in the background.
    testWidgets('is saved when the app goes to the background', (tester) async {
      await pumpCalendar(tester);
      await openDay(tester, oct24);
      await enterNote(tester, 'llamar al banco');
      expect(schedule(tester).resolve(oct24).note, isNull);

      goToBackground(tester);
      await tester.pump();

      // The sheet is still open and the text is in the repository.
      expect(_sheet, findsOneWidget);
      expect(schedule(tester).resolve(oct24).note, 'llamar al banco');
      final snapshot = await stored(tester);
      expect(snapshot.schedule.resolve(oct24).note, 'llamar al banco');
    });

    testWidgets('is saved on its own a moment after the last keystroke', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openDay(tester, oct24);
      await enterNote(tester, 'cumple de Ana');
      await tester.pump(const Duration(milliseconds: 700));
      expect(schedule(tester).resolve(oct24).note, isNull);

      await tester.pump(const Duration(milliseconds: 150));
      expect(schedule(tester).resolve(oct24).note, 'cumple de Ana');
      final snapshot = await stored(tester);
      expect(snapshot.schedule.resolve(oct24).note, 'cumple de Ana');
    });

    testWidgets('typed over several autosaves it is still one undo step', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openDay(tester, oct24);
      await enterNote(tester, 'cumple');
      await tester.pump(const Duration(seconds: 1)); // autosave 1
      await enterNote(tester, 'cumple de Ana');
      await tester.pump(const Duration(seconds: 1)); // autosave 2
      await enterNote(tester, 'cumple de Ana, llevar tarta');
      goToBackground(tester); // autosave 3
      await tester.pump();
      expect(
        schedule(tester).resolve(oct24).note,
        'cumple de Ana, llevar tarta',
      );
      comeBack(tester);
      await closeDay(tester);
      await tester.pump();
      await expectStoredIsShown(tester);

      await undoFromMonth(tester);
      expect(schedule(tester).resolve(oct24).note, isNull);
      expect(stateOf(tester).canUndo, isFalse);
      await expectStoredIsShown(tester);
    });

    testWidgets('a later visit to the note is a new undo step', (tester) async {
      await pumpCalendar(tester);
      await openDay(tester, oct24);
      await enterNote(tester, 'uno');
      await closeDay(tester);
      await tester.pump();
      await openDay(tester, oct24);
      await enterNote(tester, 'uno y dos');
      await tester.pump(const Duration(seconds: 1));
      await closeDay(tester);
      await tester.pump();

      await undoFromMonth(tester);
      expect(schedule(tester).resolve(oct24).note, 'uno');
      expect(stateOf(tester).canUndo, isTrue);
    });

    testWidgets('clearing the text removes the note', (tester) async {
      await pumpCalendar(tester);
      await openDay(tester, oct20);
      await enterNote(tester, '');
      await closeDay(tester);
      await tester.pump();
      expect(schedule(tester).resolve(oct20).note, isNull);
      expect(schedule(tester).entries[oct20], isNull);
      await expectStoredIsShown(tester);
    });

    testWidgets('opening and closing without typing writes nothing', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openDay(tester, oct20);
      await closeDay(tester);
      await tester.pump();
      expect(stateOf(tester).canUndo, isFalse);
    });

    testWidgets('is saved when another button of the sheet is used', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openDay(tester, oct24);
      await enterNote(tester, 'antes de doblar');
      await tapInSheet(tester, 'day-add-guard24');
      expect(schedule(tester).resolve(oct24).note, 'antes de doblar');
      expect(schedule(tester).resolve(oct24).shiftIds, ['rest', 'guard24']);
    });
  });

  group('own holiday', () {
    testWidgets('the switch adds a holiday that shows in the grid', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpCalendar(tester);
      await openDay(tester, oct24);
      expect(_key('day-holiday-name'), findsNothing);

      await tapInSheet(tester, 'day-holiday-switch');
      await tester.pumpAndSettle();
      final holidays = containerOf(tester).read(holidaysProvider);
      expect(holidays[oct24]?.name, 'Festivo propio');
      expect(holidays[oct24]?.isUserAdded, isTrue);
      expect(_key('day-holiday-name'), findsOneWidget);
      // The word is not repeated: «Festivo propio», not «Festivo: Festivo
      // propio».
      expect(_holidayLine(tester), 'Festivo propio');

      // Rename it.
      await tester.enterText(_key('day-holiday-name'), 'Cumple de Ana');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        containerOf(tester).read(holidaysProvider)[oct24]?.name,
        'Cumple de Ana',
      );
      expect(find.text('Festivo: Cumple de Ana'), findsOneWidget);

      await closeDay(tester);
      expect(
        find.bySemanticsLabel(RegExp('festivo: Cumple de Ana')),
        findsOneWidget,
      );

      // Reopened, the switch is on with the name.
      await openDay(tester, oct24);
      expect(
        tester.widget<TextField>(_key('day-holiday-name')).controller?.text,
        'Cumple de Ana',
      );
      // Turning it off removes it.
      await tapInSheet(tester, 'day-holiday-switch');
      expect(containerOf(tester).read(holidaysProvider)[oct24], isNull);
      expect(_key('day-holiday-name'), findsNothing);
      await closeDay(tester);
      expect(
        find.bySemanticsLabel(RegExp('festivo: Cumple de Ana')),
        findsNothing,
      );
      semantics.dispose();
    });

    testWidgets('on an official holiday the switch starts off and the own '
        'holiday wins; turning it off brings the official one back', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openDay(tester, oct12);
      expect(
        tester.widget<SwitchListTile>(_key('day-holiday-switch')).value,
        isFalse,
      );
      await tapInSheet(tester, 'day-holiday-switch');
      expect(_holidayLine(tester), 'Festivo propio');

      await tapInSheet(tester, 'day-holiday-switch');
      expect(find.text('Festivo: Fiesta Nacional de España'), findsOneWidget);
    });

    testWidgets('an empty name goes back to the saved one', (tester) async {
      await pumpCalendar(tester);
      await openDay(tester, oct24);
      await tapInSheet(tester, 'day-holiday-switch');
      await tester.enterText(_key('day-holiday-name'), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(_key('day-holiday-name')).controller?.text,
        'Festivo propio',
      );
      expect(
        containerOf(tester).read(holidaysProvider)[oct24]?.name,
        'Festivo propio',
      );
    });
  });

  group('duplicate', () {
    testWidgets('copies the shifts and the note to the day picked, with an '
        'undo in the snack bar', (tester) async {
      await pumpCalendar(tester);
      final vacationBefore = schedule(tester)
          .entries[const CivilDate(2026, 10, 28)];
      await openDay(tester, oct21); // Mañana + Tarde
      await enterNote(tester, 'Doble turno');
      await tapInSheet(tester, 'day-duplicate');
      // The picker opens on the next day (22 Oct): pick the 28th.
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('28'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is Text && w.data?.toLowerCase() == 'aceptar',
        ),
      );
      await tester.pumpAndSettle();

      expect(_sheet, findsNothing);
      const target = CivilDate(2026, 10, 28);
      expect(vacationBefore?.shiftTypeIds, ['vacation'], reason: 'demo data');
      expect(schedule(tester).resolve(target).shiftIds, [
        'morning',
        'afternoon',
      ]);
      expect(schedule(tester).resolve(target).note, 'Doble turno');
      // The source is untouched, its note saved too.
      expect(schedule(tester).resolve(oct21).note, 'Doble turno');
      await expectStoredIsShown(tester);
      expect(find.text('Copiado en miércoles, 28 de octubre'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(schedule(tester).entries[target], vacationBefore);
      expect(schedule(tester).resolve(oct21).note, 'Doble turno');
      await expectStoredIsShown(tester);
    });

    Future<void> pickDay(WidgetTester tester, String day) async {
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text(day),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is Text && w.data?.toLowerCase() == 'aceptar',
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('onto a day that would not change: no undo is offered and '
        'nothing else is undone', (tester) async {
      await pumpCalendar(tester);
      final controller = containerOf(tester)
          .read(scheduleControllerProvider.notifier);
      controller.setDayShifts(oct26, ['guard24']); // an earlier edit
      await openDay(tester, const CivilDate(2026, 10, 19)); // Noche
      await tapInSheet(tester, 'day-duplicate');
      await pickDay(tester, '23'); // Noche by the rotation too

      expect(find.textContaining('Copiado en'), findsOneWidget);
      expect(find.text('Deshacer'), findsNothing);
      expect(schedule(tester).resolve(oct26).shiftIds, ['guard24']);
      expect(stateOf(tester).canUndo, isTrue);
    });

    testWidgets('the undo of the snack bar leaves a later edit alone', (
      tester,
    ) async {
      await pumpCalendar(tester);
      const target = CivilDate(2026, 10, 28);
      await openDay(tester, oct21); // Mañana + Tarde
      await tapInSheet(tester, 'day-duplicate');
      await pickDay(tester, '28');
      expect(schedule(tester).resolve(target).shiftIds, [
        'morning',
        'afternoon',
      ]);

      // The user keeps editing while the snack bar is still there.
      containerOf(tester)
          .read(scheduleControllerProvider.notifier)
          .setDayShifts(oct26, ['guard24']);
      await tester.pump();
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();

      expect(schedule(tester).resolve(oct26).shiftIds, ['guard24']);
      expect(schedule(tester).resolve(target).shiftIds, [
        'morning',
        'afternoon',
      ]);
    });

    testWidgets('the picker opens on the next calendar day, also when the '
        'clocks go back that night (25 Oct 2026, Europe/Madrid)', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openDay(tester, const CivilDate(2026, 10, 25)); // 25 h long
      await tapInSheet(tester, 'day-duplicate');
      expect(find.byType(DatePickerDialog), findsOneWidget);
      // Accept what the picker proposes: Libre copied onto Monday 26.
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is Text && w.data?.toLowerCase() == 'aceptar',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Copiado en lunes, 26 de octubre'), findsOneWidget);
      expect(schedule(tester).resolve(oct26).shiftIds, ['rest']);
    });

    testWidgets('cancelling the picker leaves everything as it was', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openDay(tester, oct21);
      await tapInSheet(tester, 'day-duplicate');
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is Text && w.data?.toLowerCase() == 'cancelar',
        ),
      );
      await tester.pumpAndSettle();
      expect(_sheet, findsOneWidget);
      expect(stateOf(tester).canUndo, isFalse);
    });
  });

  group('undo from the month screen', () {
    testWidgets('each edit of the sheet is one step of the paint bar undo', (
      tester,
    ) async {
      await pumpCalendar(tester);
      final before = schedule(tester).entries;

      await openDay(tester, oct24);
      await tapInSheet(tester, 'day-add-guard24');
      await tapInSheet(tester, 'day-remove-0');
      await enterNote(tester, 'nota');
      await closeDay(tester);
      await tester.pump();
      expect(schedule(tester).resolve(oct24).shiftIds, ['guard24']);
      expect(schedule(tester).resolve(oct24).note, 'nota');

      await enterPaintMode(tester);
      Future<void> undo() async {
        await tester.tap(find.byKey(const ValueKey('undo')));
        await tester.pumpAndSettle();
      }

      await undo(); // the note
      expect(schedule(tester).resolve(oct24).note, isNull);
      expect(schedule(tester).resolve(oct24).shiftIds, ['guard24']);
      await undo(); // the removal
      expect(schedule(tester).resolve(oct24).shiftIds, ['rest', 'guard24']);
      await undo(); // the addition
      expect(schedule(tester).resolve(oct24).shiftIds, ['rest']);
      expect(schedule(tester).entries, before);
      expect(stateOf(tester).canUndo, isFalse);
      await expectStoredIsShown(tester);

      // And redo brings them back.
      await tester.tap(find.byKey(const ValueKey('redo')));
      await tester.pumpAndSettle();
      expect(schedule(tester).resolve(oct24).shiftIds, ['rest', 'guard24']);
    });
  });

  group('layout', () {
    for (final (scale, brightness, size) in [
      (1.6, Brightness.dark, const Size(360, 640)),
      (1.0, Brightness.light, const Size(320, 568)),
      (2.0, Brightness.dark, const Size(390, 844)),
    ]) {
      testWidgets('survives text x$scale in ${brightness.name} at '
          '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        await pumpCalendar(
          tester,
          textScale: scale,
          brightness: brightness,
          size: size,
        );
        await openDay(tester, oct21);
        await tester.ensureVisible(_key('day-clear'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(_key('day-reset'), findsOneWidget);
        expect(_key('day-note'), findsOneWidget);
      });
    }
  });
}
