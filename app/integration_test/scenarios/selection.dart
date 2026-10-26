import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

// Edición por rangos y agenda, Q80-Q84.
//
// Demo data around Monday 19 Oct 2026 (the 21-day rotation repeats every
// three weeks): Noche 19-23, Libre 24-25, Mañana 26-30, Libre 31 Oct-1 Nov,
// Tarde 2-6 Nov. Manual days: 20 note only, 21 Mañana + Tarde, 22 emptied,
// 27-28 Vacaciones.

const _oct19 = CivilDate(2026, 10, 19);
const _oct24 = CivilDate(2026, 10, 24); // Sábado
const _oct25 = CivilDate(2026, 10, 25);
const _oct30 = CivilDate(2026, 10, 30);
const _nov16 = CivilDate(2026, 11, 16); // Lunes; la rotación no coincide

/// Scenarios Q80-Q84, registered in `registry.dart`.
final List<QaScenario> selectionScenarios = [
  qaSelectionSetShift,
  qaSelectionCopyPaste,
  qaSelectionRepeat,
  qaAgendaSearch,
  qaRotationsEnd,
];

Finder _k(String key) => find.byKey(ValueKey(key));

Set<CivilDate> _range(CivilDate from, int days) => {
  for (var i = 0; i < days; i++) from.addDays(i),
};

/// Long press on [from] and, with the finger still down, drag to [to]: the
/// selection takes every day between them. Nothing moves on screen until the
/// finger comes up, so the target can be computed first.
Future<void> _longPressDrag(
  WidgetTester t,
  CivilDate from,
  CivilDate to,
) async {
  final start = t.getCenter(cell(from));
  final end = t.getCenter(cell(to));
  final gesture = await t.startGesture(start);
  await t.pump(kLongPressTimeout + const Duration(milliseconds: 100));
  const steps = 8;
  for (var s = 1; s <= steps; s++) {
    await gesture.moveTo(Offset.lerp(start, end, s / steps)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await t.settle();
}

/// The days drawn with the check of a chosen day (the grid shows 42).
Set<CivilDate> _selected(WidgetTester t) {
  const prefix = 'selected-mark-';
  return {
    for (final element
        in find
            .byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith(prefix),
            )
            .evaluate())
      CivilDate.parse(
        (element.widget.key! as ValueKey<String>).value.substring(
          prefix.length,
        ),
      ),
  };
}

Future<void> _tool(WidgetTester t, String key) => t.tapAndSettle(_k(key));

Future<void> _selectWeek(WidgetTester t, CivilDate monday) async {
  await _longPressDrag(t, monday, monday.addDays(6));
  expect(_selected(t), _range(monday, 7), reason: 'la semana de $monday');
  expect(find.text('7 días'), findsOneWidget);
}

/// Q80.
const qaSelectionSetShift = QaScenario(
  'Q80',
  'Seleccionar una semana, poner turno y deshacer',
  _setShift,
);

Future<void> _setShift(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final originalDump = await app.dumpSchedule();
  final week = _range(_oct24, 7); // 24-30 Oct

  // Mantener pulsado el sábado y arrastrar hasta el viernes.
  await _longPressDrag(t, _oct24, _oct30);
  expect(_selected(t), week);
  expect(find.text('7 días'), findsOneWidget);
  expect(_k('selection-bar'), findsOneWidget);
  await qa.shot('semana');

  await _tool(t, 'selection-set');
  await t.tapAndSettle(_k('pick-shift-afternoon'));
  for (final d in week) {
    expect(idsOn(app.schedule, d), 'afternoon', reason: '$d');
    expect(inCell(d, find.text('T')), findsOneWidget, reason: 'T en $d');
  }
  await app.flushWrites();
  expect((await app.storedDay(_oct25))?.shiftTypeIds, ['afternoon']);
  await qa.shot('turno_puesto');

  // Un solo deshacer devuelve toda la semana, en pantalla y en la base.
  await _tool(t, 'undo');
  expect(app.scheduleState.canUndo, isFalse, reason: 'una acción = un paso');
  await app.flushWrites();
  expect(await app.dumpSchedule(), originalDump);
  expect(idsOn(app.schedule, _oct24), 'rest');

  // Rehacer y salir del modo.
  await _tool(t, 'redo');
  expect(idsOn(app.schedule, _oct30), 'afternoon');
  await _tool(t, 'selection-cancel');
  expect(_k('selection-bar'), findsNothing);
  expect(find.text('Pintar'), findsOneWidget);
}

/// Q81.
const qaSelectionCopyPaste = QaScenario(
  'Q81',
  'Copiar una semana y pegarla en otra',
  _copyPaste,
);

Future<void> _copyPaste(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final source = app.resolved(_oct19, 7);
  final originalDump = await app.dumpSchedule();

  await _selectWeek(t, _oct19);
  await _tool(t, 'selection-copy');
  expect(find.textContaining('7 días copiados'), findsOneWidget);
  expect(find.text('Ningún día'), findsOneWidget);

  // Another Monday, in the next month.
  await t.tapAndSettle(find.byTooltip('Mes siguiente'));
  await t.tapAndSettle(cell(_nov16));
  expect(find.text('1 día'), findsOneWidget);
  await _tool(t, 'selection-paste');
  expect(_k('paste-summary'), findsOneWidget);
  await qa.shot('confirmar_pegado');
  await t.tapAndSettle(_k('paste-confirm'));

  // The same shifts on the same weekdays (the notes did not travel).
  final pasted = app.resolved(_nov16, 7);
  for (var i = 0; i < 7; i++) {
    final sourceShifts = source[i].split('|')[1];
    expect(pasted[i].split('|')[1], sourceShifts, reason: 'día $i');
    expect(pasted[i].split('|')[2], '', reason: 'sin notas en el día $i');
  }
  await app.flushWrites();
  expect(await app.dumpSchedule(), isNot(originalDump));
  await qa.shot('pegado');

  await _tool(t, 'undo');
  await app.flushWrites();
  expect(await app.dumpSchedule(), originalDump);
  expect(app.scheduleState.canUndo, isFalse);
}

/// Q82.
const qaSelectionRepeat = QaScenario(
  'Q82',
  'Repetir una semana 4 veces',
  _repeat,
);

Future<void> _repeat(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final source = app.resolved(_oct19, 7);
  final originalDump = await app.dumpSchedule();

  await _selectWeek(t, _oct19);
  await _tool(t, 'selection-repeat');
  for (var i = 0; i < 3; i++) {
    await t.tapAndSettle(_k('repeat-more'));
  }
  expect(find.text('4 veces'), findsOneWidget);
  expect(
    t.widget<Text>(_k('repeat-preview')).data,
    'Cambia 28 días más, hasta el domingo, 22 de noviembre.',
  );
  await qa.shot('repetir');
  await t.tapAndSettle(_k('repeat-confirm'));

  for (var k = 1; k <= 4; k++) {
    final copy = app.resolved(_oct19.addDays(7 * k), 7);
    for (var i = 0; i < 7; i++) {
      expect(
        copy[i].split('|')[1],
        source[i].split('|')[1],
        reason: 'copia $k, día $i',
      );
    }
  }
  await app.flushWrites();
  final repeatedDump = await app.dumpSchedule();
  expect(repeatedDump, isNot(originalDump));

  // Un solo paso: deshacer deja la base como estaba; rehacer, como quedó.
  await _tool(t, 'undo');
  await app.flushWrites();
  expect(await app.dumpSchedule(), originalDump);
  expect(app.scheduleState.canUndo, isFalse);
  await _tool(t, 'redo');
  await app.flushWrites();
  expect(await app.dumpSchedule(), repeatedDump);
}

/// Q83.
const qaAgendaSearch = QaScenario(
  'Q83',
  'La agenda lista las notas y la búsqueda encuentra una',
  _agenda,
);

Future<void> _agenda(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  app.scheduleController.setNote(
    const CivilDate(2026, 11, 3),
    'Revisión médica',
  );
  app.scheduleController.setNote(
    const CivilDate(2026, 3, 2),
    'Médico de cabecera',
  );
  await t.settle();

  await t.tapAndSettle(_k('open-agenda'));
  expect(find.text('Agenda'), findsWidgets);
  // Upcoming notes from today on, grouped by month.
  expect(find.text('Cambio con Marta si sale el turno'), findsOneWidget);
  expect(find.text('Revisión médica'), findsOneWidget);
  expect(find.text('Médico de cabecera'), findsNothing, reason: 'es pasada');
  await qa.shot('agenda');

  // Without accents and in capitals: finds the past note too.
  await t.enterText(_k('agenda-search'), 'MEDICA');
  await t.settle();
  expect(find.text('1 resultado'), findsOneWidget);
  expect(find.text('Revisión médica'), findsOneWidget);
  await t.enterText(_k('agenda-search'), 'medico');
  await t.settle();
  expect(find.text('Médico de cabecera'), findsOneWidget);
  await qa.shot('busqueda');

  await t.enterText(_k('agenda-search'), 'revision');
  await t.settle();
  await t.tapAndSettle(_k('agenda-day-2026-11-03'));
  expect(find.byType(BottomSheet), findsOneWidget);
  expect(find.text('Martes, 3 de noviembre'), findsOneWidget);
  expect(find.text('Revisión médica'), findsWidgets);
}

/// Q84.
const qaRotationsEnd = QaScenario(
  'Q84',
  'Mis rotaciones: terminar y eliminar, cada uno con un solo deshacer',
  _rotations,
);

Future<void> _rotations(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final originalDump = await app.dumpSchedule();

  await t.tapAndSettle(find.byTooltip('Abrir ajustes'));
  await t.tapAndSettle(_k('settings-runs'));
  expect(find.text('Mis rotaciones'), findsWidgets);
  expect(find.text('Correturnos'), findsOneWidget);
  expect(find.text('En curso'), findsOneWidget);
  await qa.shot('rotaciones');

  // Terminar aquí: the picker opens on today; pick the 28th.
  await t.tapAndSettle(_k('run-end-run-1'));
  await t.tapAndSettle(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.text('28'),
    ),
  );
  await t.tapAndSettle(
    find.byWidgetPredicate(
      (w) => w is Text && w.data?.toLowerCase() == 'aceptar',
    ),
  );
  expect(app.schedule.runs.single.endDate, const CivilDate(2026, 10, 27));
  await app.flushWrites();
  expect(await app.dumpSchedule(), isNot(originalDump));
  await t.tapAndSettle(find.text('Deshacer'));
  await app.flushWrites();
  expect(await app.dumpSchedule(), originalDump);
  expect(app.scheduleState.canUndo, isFalse);

  // Eliminar: asks first; the manual days stay.
  await t.tapAndSettle(_k('run-delete-run-1'));
  await t.tapAndSettle(_k('confirm-ok'));
  expect(app.schedule.runs, isEmpty);
  expect(find.text('Sin rotaciones'), findsOneWidget);
  expect(app.schedule.resolve(const CivilDate(2026, 10, 21)).shiftIds, [
    'morning',
    'afternoon',
  ]);
  await app.flushWrites();
  expect(await app.query('SELECT COUNT(*) AS n FROM pattern_runs'), [
    {'n': 0},
  ]);
  await qa.shot('eliminada');
  await t.tapAndSettle(find.text('Deshacer'));
  await app.flushWrites();
  expect(await app.dumpSchedule(), originalDump);
}
