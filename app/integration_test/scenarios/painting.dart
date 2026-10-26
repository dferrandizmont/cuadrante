import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

// Demo rotation (correturnos, 21-day cycle) around Monday 19 Oct 2026:
//   19-23 Noche, 24-25 Libre, 26-30 Mañana, 31 Oct-1 Nov Libre, 2-6 Tarde...
// Demo overrides: 20 note only, 21 Mañana+Tarde, 22 empty, 27-28 Vacaciones.
const _oct20 = CivilDate(2026, 10, 20);
const _oct21 = CivilDate(2026, 10, 21);
const _oct22 = CivilDate(2026, 10, 22);
const _oct23 = CivilDate(2026, 10, 23);
const _oct24 = CivilDate(2026, 10, 24);
const _oct29 = CivilDate(2026, 10, 29);
const _oct30 = CivilDate(2026, 10, 30);

/// Q02.
const qaPaintTap = QaScenario('Q02', 'Pintar con un toque', _paintTap);

Future<void> _paintTap(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);

  expect(idsOn(app.schedule, _oct30), 'morning');
  expect(inCell(_oct30, find.text('M')), findsOneWidget);
  expect(await app.storedDay(_oct30), isNull, reason: 'antes: sin fila');

  await enterPaintMode(t);
  await t.tapAndSettle(tool('afternoon'));
  expect(app.paint.shiftTypeId, 'afternoon');
  await t.tapAndSettle(cell(_oct30));

  expect(inCell(_oct30, find.text('T')), findsOneWidget);
  expect(inCell(_oct30, find.text('M')), findsNothing);
  expect(idsOn(app.schedule, _oct30), 'afternoon');
  await app.flushWrites();
  final row = await app.storedDay(_oct30);
  expect(row, isNotNull, reason: 'el toque debe guardar una fila');
  expect(row!.shiftTypeIds, ['afternoon']);
  await qa.shot('pintado');
}

/// Q03.
const qaDrag = QaScenario(
  'Q03',
  'Arrastrar: un trazo, un solo deshacer',
  _drag,
);

Future<void> _drag(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final days = [_oct20, _oct21, _oct22, _oct23];
  final originalIds = {for (final d in days) d: idsOn(app.schedule, d)};
  expect(originalIds.values.toSet().length, greaterThan(1));
  final originalDump = await app.dumpSchedule();

  await enterPaintMode(t);
  await t.tapAndSettle(tool('afternoon'));
  await t.dragAcross([for (final d in days) cell(d)]);

  for (final d in days) {
    expect(inCell(d, find.text('T')), findsOneWidget, reason: 'T en $d');
    expect(inCell(d, find.text('M')), findsNothing, reason: 'sin M en $d');
    expect(inCell(d, find.text('N')), findsNothing, reason: 'sin N en $d');
  }
  await qa.shot('arrastrado');
  await app.flushWrites();
  for (final d in days) {
    expect((await app.storedDay(d))?.shiftTypeIds, ['afternoon'], reason: '$d');
  }
  final paintedDump = await app.dumpSchedule();
  expect(app.scheduleState.canUndo, isTrue);

  // ONE undo gives the four days back, in the UI and in the database.
  await t.tapAndSettle(find.byKey(const ValueKey('undo')));
  for (final d in days) {
    expect(
      idsOn(app.schedule, d),
      originalIds[d],
      reason: 'UI tras deshacer $d',
    );
  }
  expect(inCell(_oct21, find.text('M')), findsOneWidget);
  expect(inCell(_oct23, find.text('N')), findsOneWidget);
  expect(app.scheduleState.canUndo, isFalse, reason: 'un trazo = un paso');
  expect(app.scheduleState.canRedo, isTrue);
  await app.flushWrites();
  expect(await app.dumpSchedule(), originalDump, reason: 'BD tras deshacer');
  await qa.shot('deshecho');

  // Redo applies the same four days again.
  await t.tapAndSettle(find.byKey(const ValueKey('redo')));
  for (final d in days) {
    expect(inCell(d, find.text('T')), findsOneWidget, reason: 'rehacer $d');
  }
  expect(app.scheduleState.canRedo, isFalse);
  await app.flushWrites();
  expect(await app.dumpSchedule(), paintedDump, reason: 'BD tras rehacer');
}

/// Q04.
const qaDouble = QaScenario('Q04', 'Doblar: dos turnos en un día', _double);

Future<void> _double(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);

  // A rest day in the rotation.
  expect(idsOn(app.schedule, _oct24), 'rest');
  await enterPaintMode(t);
  await t.tapAndSettle(tool('morning'));
  await t.tapAndSettle(cell(_oct24));
  expect(inCell(_oct24, find.text('M')), findsOneWidget);
  expect(inCell(_oct24, find.text('L')), findsNothing);

  await t.tapAndSettle(find.byKey(const ValueKey('tool-double')));
  expect(app.paint.doubling, isTrue);
  await t.tapAndSettle(tool('afternoon'));
  await t.tapAndSettle(cell(_oct24));

  expect(inCell(_oct24, find.text('M')), findsOneWidget);
  expect(inCell(_oct24, find.text('T')), findsOneWidget);
  expect(idsOn(app.schedule, _oct24), 'morning+afternoon');
  await app.flushWrites();
  expect((await app.storedDay(_oct24))?.shiftTypeIds, [
    'morning',
    'afternoon',
  ], reason: 'la fila guarda los dos ids, en orden');
  await qa.shot('doblado');
}

/// Q05.
const qaErase = QaScenario(
  'Q05',
  'Borrar: excepción vacía solo si hace falta',
  _erase,
);

Future<void> _erase(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);

  // On a day the rotation fills: an EMPTY override is stored.
  expect(idsOn(app.schedule, _oct29), 'morning');
  expect(await app.storedDay(_oct29), isNull);
  await enterPaintMode(t);
  await t.tapAndSettle(find.byKey(const ValueKey('tool-eraser')));
  expect(app.paint.erasing, isTrue);
  await t.tapAndSettle(cell(_oct29));
  expect(inCell(_oct29, find.text('M')), findsNothing);
  expect(idsOn(app.schedule, _oct29), '');
  await app.flushWrites();
  final row = await app.storedDay(_oct29);
  expect(row, isNotNull, reason: 'borrar un día de la rotación guarda []');
  expect(row!.shiftTypeIds, isEmpty);
  await qa.shot('borrado');

  // Undo puts the rotation back and removes the row.
  await t.tapAndSettle(find.byKey(const ValueKey('undo')));
  expect(inCell(_oct29, find.text('M')), findsOneWidget);
  await app.flushWrites();
  expect(await app.storedDay(_oct29), isNull);

  // On a day that is already empty (before the rotation starts): no row.
  for (var i = 0; i < 4; i++) {
    await tapMonthArrow(t, next: false);
  }
  expect(find.text('Junio'), findsOneWidget);
  const june = CivilDate(2026, 6, 10);
  expect(idsOn(app.schedule, june), '');
  final rowsBefore = await app.storedDayCount();
  await t.tapAndSettle(cell(june));
  await app.flushWrites();
  expect(await app.storedDay(june), isNull, reason: 'día vacío: sin fila');
  expect(await app.storedDayCount(), rowsBefore, reason: 'nada escrito');
  expect(idsOn(app.schedule, june), '');
}
