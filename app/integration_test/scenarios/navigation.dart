import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

const _oct12 = CivilDate(2026, 10, 12); // Fiesta Nacional de España (Monday)
const _oct20 = CivilDate(2026, 10, 20); // note only
const _oct21 = CivilDate(2026, 10, 21);
const _oct22 = CivilDate(2026, 10, 22); // emptied on purpose

/// Q07.
const qaNavigation = QaScenario(
  'Q07',
  'Navegación entre meses y gesto de deslizar',
  _navigation,
);

Finder _title(String month) => find.text(month);

Future<void> _navigation(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);

  expect(_title('Octubre'), findsOneWidget);
  expect(
    find.text('Hoy'),
    findsNothing,
    reason: '«Hoy» solo fuera del mes actual',
  );

  await tapMonthArrow(t, next: true);
  expect(_title('Noviembre'), findsOneWidget);
  expect(find.text('Hoy'), findsOneWidget);
  expect(cell(const CivilDate(2026, 11, 15)), findsOneWidget);
  expect(allCells, findsNWidgets(42));
  await tapMonthArrow(t, next: true);
  expect(_title('Diciembre'), findsOneWidget);
  for (var i = 0; i < 3; i++) {
    await tapMonthArrow(t, next: false);
  }
  expect(_title('Septiembre'), findsOneWidget);

  await t.tapAndSettle(find.text('Hoy'));
  expect(_title('Octubre'), findsOneWidget);
  expect(find.text('Hoy'), findsNothing);

  // Outside paint mode a horizontal swipe changes the month.
  await t.fling(cell(_oct21), const Offset(-300, 0), 1500);
  await t.settle();
  expect(
    _title('Noviembre'),
    findsOneWidget,
    reason: 'deslizar a la izquierda',
  );
  await t.fling(
    cell(const CivilDate(2026, 11, 18)),
    const Offset(300, 0),
    1500,
  );
  await t.settle();
  expect(_title('Octubre'), findsOneWidget, reason: 'deslizar a la derecha');

  // In paint mode the same gesture paints and the month stays.
  await enterPaintMode(t);
  await t.tapAndSettle(tool('afternoon'));
  await t.fling(cell(_oct21), const Offset(-300, 0), 1500);
  await t.settle();
  expect(
    _title('Octubre'),
    findsOneWidget,
    reason: 'pintando no cambia de mes',
  );
  expect(_title('Noviembre'), findsNothing);
  expect(
    app.scheduleState.canUndo,
    isTrue,
    reason: 'el gesto debe haber pintado',
  );
  await t.tapAndSettle(find.byKey(const ValueKey('undo')));
  await exitPaintMode(t);
  await qa.shot('mes');
}

/// Q08.
const qaDaySheet = QaScenario('Q08', 'Detalle del día', _daySheet);

Future<void> _daySheet(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(
    qa,
    prepare: (storage) async {
      // A note on the holiday, so the sheet shows the three things at once.
      await storage.repository.apply(
        mainCalendarId,
        ScheduleChange(
          patch: EntriesPatch({
            _oct12: EntryChange(
              null,
              DayEntry(date: _oct12, note: 'Revisar cuadrante con Marta'),
            ),
          }),
        ),
      );
    },
  );
  final sheet = find.byType(BottomSheet);
  Finder inSheet(Finder matching) =>
      find.descendant(of: sheet, matching: matching);

  // Holiday + shift + note.
  final shifts = app.schedule.resolve(_oct12).shifts;
  expect(shifts, isNotEmpty);
  await t.tapAndSettle(cell(_oct12));
  expect(sheet, findsOneWidget);
  expect(
    inSheet(find.text('Festivo: Fiesta Nacional de España')),
    findsOneWidget,
  );
  for (final (i, shift) in shifts.indexed) {
    // The palette strip repeats the names: look inside the day's own rows.
    final row = find.byKey(ValueKey('day-shift-$i'));
    expect(
      find.descendant(of: row, matching: find.text(shift.name)),
      findsOneWidget,
      reason: shift.name,
    );
    expect(
      find.descendant(of: row, matching: find.text(shift.code)),
      findsOneWidget,
    );
  }
  expect(inSheet(find.text('Nota')), findsOneWidget);
  expect(inSheet(find.text('Revisar cuadrante con Marta')), findsOneWidget);
  await qa.shot('festivo');
  await _dismiss(t);

  // A day with a note and no holiday.
  await t.tapAndSettle(cell(_oct20));
  expect(
    inSheet(find.text('Cambio con Marta si sale el turno')),
    findsOneWidget,
  );
  // No holiday line («Festivo: <nombre>») and the «Festivo propio» switch of
  // the editable sheet is off.
  expect(inSheet(find.textContaining('Festivo:')), findsNothing);
  expect(
    t
        .widget<SwitchListTile>(
          find.byKey(const ValueKey('day-holiday-switch')),
        )
        .value,
    isFalse,
    reason: 'sin festivo, «Festivo propio» apagado',
  );
  expect(find.byKey(const ValueKey('day-holiday-name')), findsNothing);
  await _dismiss(t);

  // A doubled day and an empty one.
  await t.tapAndSettle(cell(_oct21));
  for (final (i, name) in ['Mañana', 'Tarde'].indexed) {
    expect(
      find.descendant(
        of: find.byKey(ValueKey('day-shift-$i')),
        matching: find.text(name),
      ),
      findsOneWidget,
      reason: name,
    );
  }
  await _dismiss(t);
  await t.tapAndSettle(cell(_oct22));
  expect(inSheet(find.text('Este día no tiene turno.')), findsOneWidget);
  await _dismiss(t);
}

Future<void> _dismiss(WidgetTester t) async {
  // The day sheet can fill the screen: close it as a user would, with Back.
  await t.binding.handlePopRoute();
  await t.settle();
  expect(
    find.byType(BottomSheet),
    findsNothing,
    reason: 'la hoja debe cerrarse',
  );
}

/// Q10.
const qaHolidays = QaScenario('Q10', 'Festivos por comunidad', _holidays);

Future<void> _holidays(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  const xmas = CivilDate(2026, 12, 25);
  const sanEsteban = CivilDate(2026, 12, 26);
  Finder dot(CivilDate d) => find.byKey(ValueKey('holiday-dot-${d.toIso()}'));

  await t.tapAndSettle(find.byTooltip('Mes siguiente'));
  await t.tapAndSettle(find.byTooltip('Mes siguiente'));
  expect(find.text('Diciembre'), findsOneWidget);

  // National only: Navidad yes, San Esteban no.
  expect(app.container.read(holidayPlaceProvider).regionCode, isNull);
  expect(dot(xmas), findsOneWidget);
  expect(dot(const CivilDate(2026, 12, 8)), findsOneWidget);
  expect(dot(sanEsteban), findsNothing);

  await t.runAsync(() => app.holidayController.setPlace(regionCode: 'ES-CT'));
  await t.settle();
  expect(
    dot(sanEsteban),
    findsOneWidget,
    reason: '26 dic es festivo en Cataluña',
  );
  expect(dot(xmas), findsOneWidget);
  await t.tapAndSettle(cell(sanEsteban));
  expect(find.text('Festivo: San Esteban'), findsOneWidget);
  await qa.shot('cataluna');
  await t.tapAt(const Offset(20, 80));
  await t.settle();

  final stored = await app.query(
    "SELECT value FROM settings WHERE key = 'holidays.region'",
  );
  expect(stored.single['value'], contains('ES-CT'));

  // The choice survives closing the app.
  await app.restart();
  expect(app.container.read(holidayPlaceProvider).regionCode, 'ES-CT');
  await t.tapAndSettle(find.byTooltip('Mes siguiente'));
  await t.tapAndSettle(find.byTooltip('Mes siguiente'));
  expect(dot(sanEsteban), findsOneWidget);

  // Back to national only.
  await t.runAsync(() => app.holidayController.setPlace());
  await t.settle();
  expect(dot(sanEsteban), findsNothing);
  expect(dot(xmas), findsOneWidget);
}
