import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/core/widgets/app_snack_bar.dart';
import 'package:cuadrante/core/widgets/buttons.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

// Detalle del día editable, Q24-Q29.
//
// Demo data around Monday 19 Oct 2026: rotation Noche 19-23, Libre 24-25,
// Mañana 26-30; overrides: 20 note only, 21 Mañana + Tarde, 22 emptied,
// 27-28 Vacaciones.

const _oct21 = CivilDate(2026, 10, 21); // Mañana + Tarde (rotation: Noche)
const _oct24 = CivilDate(2026, 10, 24); // Libre by the rotation
const _oct26 = CivilDate(2026, 10, 26); // Mañana by the rotation
const _oct30 = CivilDate(2026, 10, 30); // Mañana by the rotation

/// Scenarios Q24-Q29, registered in `registry.dart`.
final List<QaScenario> dayDetailScenarios = [
  qaDayShifts,
  qaDayReset,
  qaDayNote,
  qaDayHoliday,
  qaDayDuplicate,
  qaDayUndoChain,
];

Finder _k(String key) => find.byKey(ValueKey(key));

ProviderContainer _container(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(MaterialApp)));

ScheduleState _state(WidgetTester t) =>
    _container(t).read(scheduleControllerProvider);

Future<void> _open(WidgetTester t, CivilDate date) async {
  await t.tapAndSettle(cell(date));
  expect(find.byType(BottomSheet), findsOneWidget, reason: 'detalle de $date');
}

/// Closes the sheet like a user: tap on the dimmed area, or back when the
/// sheet fills the screen.
Future<void> _close(WidgetTester t) async {
  final sheet = find.byType(BottomSheet);
  if (t.getTopLeft(sheet).dy > 100) {
    await t.tapAt(const Offset(20, 60));
  } else {
    await Navigator.of(t.element(sheet)).maybePop();
  }
  await t.settle();
  expect(sheet, findsNothing, reason: 'la hoja debe cerrarse');
}

Future<void> _tap(WidgetTester t, String key) => t.tapAndSettle(_k(key));

Future<void> _undoFromMonth(WidgetTester t, {int times = 1}) async {
  await enterPaintMode(t);
  for (var i = 0; i < times; i++) {
    await t.tapAndSettle(find.byKey(const ValueKey('undo')));
  }
  await exitPaintMode(t);
}

Future<void> _redoFromMonth(WidgetTester t, {int times = 1}) async {
  await enterPaintMode(t);
  for (var i = 0; i < times; i++) {
    await t.tapAndSettle(find.byKey(const ValueKey('redo')));
  }
  await exitPaintMode(t);
}

/// Q24.
const qaDayShifts = QaScenario(
  'Q24',
  'Detalle: doblar, reordenar y quitar turnos (y deshacer desde el mes)',
  _shifts,
);

Future<void> _shifts(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final original = await app.dumpSchedule();
  expect(idsOn(app.schedule, _oct24), 'rest');

  await _open(t, _oct24);
  // Add a second shift from the palette.
  await _tap(t, 'day-add-guard24');
  expect(idsOn(_state(t).schedule, _oct24), 'rest+guard24');
  await app.flushWrites();
  expect((await app.storedDay(_oct24))?.shiftTypeIds, ['rest', 'guard24']);
  await qa.shot('doblado');

  // Move it first, then drop the Libre.
  await _tap(t, 'day-up-1');
  expect(idsOn(_state(t).schedule, _oct24), 'guard24+rest');
  await app.flushWrites();
  expect((await app.storedDay(_oct24))?.shiftTypeIds, ['guard24', 'rest']);
  await _tap(t, 'day-remove-1');
  expect(idsOn(_state(t).schedule, _oct24), 'guard24');
  await app.flushWrites();
  expect((await app.storedDay(_oct24))?.shiftTypeIds, ['guard24']);
  await _close(t);
  expect(inCell(_oct24, find.text('G')), findsOneWidget);
  expect(inCell(_oct24, find.text('L')), findsNothing);
  final edited = await app.dumpSchedule();

  // Three edits are three undo steps, and the database follows each one.
  await _undoFromMonth(t, times: 2);
  expect(idsOn(app.schedule, _oct24), 'rest+guard24');
  await app.flushWrites();
  expect((await app.storedDay(_oct24))?.shiftTypeIds, ['rest', 'guard24']);
  await _undoFromMonth(t);
  expect(idsOn(app.schedule, _oct24), 'rest');
  await app.flushWrites();
  expect(await app.dumpSchedule(), original, reason: 'BD como al principio');
  expect(await app.storedDay(_oct24), isNull);

  await _redoFromMonth(t, times: 3);
  expect(idsOn(app.schedule, _oct24), 'guard24');
  await app.flushWrites();
  expect(await app.dumpSchedule(), edited, reason: 'rehacer vuelve al final');
}

/// Q25.
const qaDayReset = QaScenario('Q25', 'Detalle: volver al patrón', _reset);

Future<void> _reset(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  expect(idsOn(app.schedule, _oct21), 'morning+afternoon');
  expect(await app.storedDay(_oct21), isNotNull);

  await _open(t, _oct21);
  expect(find.text('Cambiado a mano'), findsOneWidget);
  expect(find.text('El patrón da: Noche 22:00–06:00'), findsOneWidget);
  await qa.shot('con_excepcion');
  await _tap(t, 'day-reset');
  expect(_k('day-reset'), findsNothing);
  expect(find.text('Según tu patrón'), findsOneWidget);
  await _close(t);

  expect(idsOn(app.schedule, _oct21), 'night');
  expect(inCell(_oct21, find.text('N')), findsOneWidget);
  expect(inCell(_oct21, find.text('M')), findsNothing);
  await app.flushWrites();
  expect(
    await app.storedDay(_oct21),
    isNull,
    reason: 'sin excepción, sin fila',
  );

  await _undoFromMonth(t);
  expect(inCell(_oct21, find.text('M')), findsOneWidget);
  expect(inCell(_oct21, find.text('T')), findsOneWidget);
  await app.flushWrites();
  expect((await app.storedDay(_oct21))?.shiftTypeIds, ['morning', 'afternoon']);
}

/// Q26.
const qaDayNote = QaScenario(
  'Q26',
  'Detalle: nota con emoji que se guarda al cerrar',
  _note,
);

const _noteText = 'Cumple de Ana \u{1F382}\nllevar tarta';

Future<void> _note(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  expect(await app.storedDay(_oct24), isNull);

  await _open(t, _oct24);
  await t.ensureVisible(_k('day-note'));
  await t.pump();
  await t.enterText(_k('day-note'), _noteText);
  await t.pump();
  await qa.shot('escribiendo');
  await _close(t);

  expect(app.schedule.resolve(_oct24).note, _noteText);
  expect(idsOn(app.schedule, _oct24), 'rest', reason: 'turnos intactos');
  await app.flushWrites();
  final row = await app.storedDay(_oct24);
  expect(row?.note, _noteText);
  expect(row?.shiftTypeIds, isNull, reason: 'una nota no es una excepción');

  // Closing and opening the app keeps it, and the sheet shows it again.
  await app.restart();
  await _open(t, _oct24);
  expect(t.widget<TextField>(_k('day-note')).controller?.text, _noteText);
  await qa.shot('reabierta');

  // Emptying the text removes the note (and the row).
  await t.ensureVisible(_k('day-note'));
  await t.pump();
  await t.enterText(_k('day-note'), '');
  await t.pump();
  await _close(t);
  await app.flushWrites();
  expect(await app.storedDay(_oct24), isNull);
  expect(app.schedule.resolve(_oct24).note, isNull);
}

/// Q27.
const qaDayHoliday = QaScenario('Q27', 'Detalle: festivo propio', _holiday);

Future<void> _holiday(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  Finder dot() => find.byKey(ValueKey('holiday-dot-${_oct24.toIso()}'));
  Future<List<Map<String, Object?>>> userRows() => app.query(
    "SELECT name, source FROM holidays WHERE date = '${_oct24.toIso()}' "
    "AND source = 'user'",
  );
  expect(dot(), findsNothing);

  await _open(t, _oct24);
  expect(_k('day-holiday-name'), findsNothing);
  await _tap(t, 'day-holiday-switch');
  expect(t.widget<Text>(_k('day-holiday-line')).data, 'Festivo propio');
  await t.enterText(_k('day-holiday-name'), 'Cumple de Ana');
  await t.testTextInput.receiveAction(TextInputAction.done);
  await t.settle();
  expect(find.text('Festivo: Cumple de Ana'), findsOneWidget);
  await qa.shot('festivo_propio');
  await _close(t);

  expect(dot(), findsOneWidget, reason: 'el festivo sale en la cuadrícula');
  expect((await userRows()).single['name'], 'Cumple de Ana');

  await app.restart();
  expect(dot(), findsOneWidget);
  await _open(t, _oct24);
  expect(
    t.widget<TextField>(_k('day-holiday-name')).controller?.text,
    'Cumple de Ana',
  );
  await _tap(t, 'day-holiday-switch');
  expect(_k('day-holiday-name'), findsNothing);
  await _close(t);
  expect(dot(), findsNothing);
  expect(await userRows(), isEmpty);
}

/// Q28.
const qaDayDuplicate = QaScenario(
  'Q28',
  'Detalle: duplicar en otro día y borrar el día',
  _duplicate,
);

Future<void> _duplicate(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  expect(idsOn(app.schedule, _oct30), 'morning');

  // Copy the doubled day (with a note) onto the 30th.
  await _open(t, _oct21);
  await t.ensureVisible(_k('day-note'));
  await t.pump();
  await t.enterText(_k('day-note'), 'Doble turno');
  await t.pump();
  await _tap(t, 'day-duplicate');
  expect(find.byType(DatePickerDialog), findsOneWidget);
  await t.tapAndSettle(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.text('30'),
    ),
  );
  await t.tapAndSettle(
    find.byWidgetPredicate(
      (w) => w is Text && w.data?.toLowerCase() == 'aceptar',
    ),
  );
  expect(find.byType(BottomSheet), findsNothing, reason: 'la hoja se cierra');
  expect(idsOn(app.schedule, _oct30), 'morning+afternoon');
  expect(app.schedule.resolve(_oct30).note, 'Doble turno');
  expect(inCell(_oct30, find.text('T')), findsOneWidget);
  await app.flushWrites();
  final copied = await app.storedDay(_oct30);
  expect(copied?.shiftTypeIds, ['morning', 'afternoon']);
  expect(copied?.note, 'Doble turno');
  expect(find.text('Copiado en viernes, 30 de octubre'), findsOneWidget);
  await qa.shot('copiado');

  // The snack bar undoes it.
  await t.tapAndSettle(find.text('Deshacer'));
  expect(idsOn(app.schedule, _oct30), 'morning');
  expect(inCell(_oct30, find.text('T')), findsNothing);
  await app.flushWrites();
  expect(await app.storedDay(_oct30), isNull);
  // The source kept its note.
  expect(app.schedule.resolve(_oct21).note, 'Doble turno');

  // "Borrar día" empties the day and closes the sheet to show its notice.
  // Reopening the empty day shows the disabled button.
  await _open(t, _oct26);
  await _tap(t, 'day-clear');
  expect(find.byType(BottomSheet), findsNothing);
  expect(find.text('Día borrado'), findsOneWidget);
  expect(idsOn(app.schedule, _oct26), isEmpty);
  expect(inCell(_oct26, find.text('M')), findsNothing);
  await app.flushWrites();
  expect((await app.storedDay(_oct26))?.shiftTypeIds, isEmpty);

  await _open(t, _oct26);
  expect(find.text('Este día no tiene turno.'), findsOneWidget);
  expect(t.widget<SecondaryButton>(_k('day-clear')).onPressed, isNull);
  await _close(t);
  // Let the notice clear the paint toolbar before using its undo button.
  await t.pump(kSnackBarDuration);
  await t.settle();
  await _undoFromMonth(t);
  expect(inCell(_oct26, find.text('M')), findsOneWidget);
  await app.flushWrites();
  expect(await app.storedDay(_oct26), isNull);
}

/// Q29.
const qaDayUndoChain = QaScenario(
  'Q29',
  'Detalle, pintura y turnos: deshacer y rehacer en cadena',
  _undoChain,
);

Future<void> _undoChain(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final dumps = <String>[await app.dumpSchedule()];

  // 1. Paint the 30th with a Tarde.
  await enterPaintMode(t);
  await t.tapAndSettle(tool('afternoon'));
  await t.tapAndSettle(cell(_oct30));
  await exitPaintMode(t);
  await app.flushWrites();
  dumps.add(await app.dumpSchedule());

  // 2. Detail of the 24th: add a guard and write a note.
  await _open(t, _oct24);
  await _tap(t, 'day-add-guard24');
  await t.ensureVisible(_k('day-note'));
  await t.pump();
  await t.enterText(_k('day-note'), 'Guardia');
  await t.pump();
  await _close(t);
  await app.flushWrites();
  dumps.add(await app.dumpSchedule());
  expect(idsOn(app.schedule, _oct24), 'rest+guard24');
  expect(app.schedule.resolve(_oct24).note, 'Guardia');

  // 3. Rename a shift type in the middle of the history.
  await t.tapAndSettle(find.byTooltip('Abrir ajustes'));
  await t.tapAndSettle(_k('settings-shifts'));
  await t.tapAndSettle(_k('shift-row-afternoon'));
  await t.ensureVisible(_k('shift-name'));
  await t.pump();
  await t.enterText(_k('shift-name'), 'Tarde larga');
  await t.pump();
  await _tap(t, 'shift-save');
  final router = _container(t).read(routerProvider);
  while (router.canPop()) {
    router.pop();
    await t.settle();
  }
  expect(app.schedule.shiftTypeById('afternoon')?.name, 'Tarde larga');
  expect(
    app.scheduleState.canUndo,
    isTrue,
    reason: 'editar turnos no borra el historial',
  );

  // Undo: note, then the shift added, then the painting. The shift type keeps
  // its new name: it is not part of the day history.
  await enterPaintMode(t);
  final undo = find.byKey(const ValueKey('undo'));
  await t.tapAndSettle(undo);
  expect(app.schedule.resolve(_oct24).note, isNull);
  expect(idsOn(app.schedule, _oct24), 'rest+guard24');
  await t.tapAndSettle(undo);
  expect(idsOn(app.schedule, _oct24), 'rest');
  await app.flushWrites();
  // The dumps taken before the rename show the old name of the shift type.
  String renamed(String dump) => dump.replaceAll('"Tarde"', '"Tarde larga"');
  expect(await app.dumpSchedule(), renamed(dumps[1]));
  await t.tapAndSettle(undo);
  expect(idsOn(app.schedule, _oct30), 'morning');
  expect(app.scheduleState.canUndo, isFalse);
  await app.flushWrites();
  expect(await app.dumpSchedule(), renamed(dumps[0]));
  final name = await app.query(
    "SELECT name FROM shift_types WHERE id = 'afternoon'",
  );
  expect(name.single['name'], 'Tarde larga');

  // Redo all three.
  final redo = find.byKey(const ValueKey('redo'));
  for (var i = 0; i < 3; i++) {
    await t.tapAndSettle(redo);
  }
  await exitPaintMode(t);
  expect(idsOn(app.schedule, _oct24), 'rest+guard24');
  expect(idsOn(app.schedule, _oct30), 'afternoon');
  await app.flushWrites();
  expect(await app.dumpSchedule(), renamed(dumps.last));
}
