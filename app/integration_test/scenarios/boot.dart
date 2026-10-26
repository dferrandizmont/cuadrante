import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

/// Q01: first start on an empty database.
const qaBoot = QaScenario('Q01', 'Arranque en una base de datos nueva', _boot);

Future<void> _boot(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);

  // The seed: every template is a shift type in the DB, in the table's order.
  final rows = await app.query(
    'SELECT id, code FROM shift_types ORDER BY sort_order',
  );
  expect(
    [for (final r in rows) r['code']],
    [for (final template in shiftTemplates) template.code],
    reason: 'tipos de turno sembrados (código y orden)',
  );
  for (final code in ['M', 'T', 'N', 'L']) {
    expect(
      rows.any((r) => r['code'] == code),
      isTrue,
      reason: 'falta el tipo $code en la base de datos',
    );
  }
  final presets = await app.query('SELECT COUNT(*) AS n FROM patterns');
  expect(
    presets.single['n'],
    patternPresets.length,
    reason: 'patrones sembrados',
  );

  // The calendar: header, month, Today card and 6 x 7 cells.
  expect(find.text('Lunes, 19 de octubre'), findsOneWidget);
  expect(find.text('Octubre'), findsOneWidget);
  expect(allCells, findsNWidgets(42));
  expect(cell(const CivilDate(2026, 9, 28)), findsOneWidget);
  expect(cell(const CivilDate(2026, 11, 8)), findsOneWidget);
  expect(find.text('ESTA NOCHE'), findsOneWidget);
  expect(find.text('22:00–06:00'), findsOneWidget);
  expect(find.textContaining('Empieza en 3 h 40'), findsOneWidget);
  expect(find.text('Mañana (mar 20): turno de Noche'), findsOneWidget);
  // Today's cell: code and time, not only colour.
  expect(inCell(qaToday, find.text('N')), findsOneWidget);
  expect(inCell(qaToday, find.text('22–06')), findsOneWidget);

  // The palette of paint mode offers every non-archived type, by id.
  expect([
    for (final type in app.scheduleState.palette) type.code,
  ], containsAll(['M', 'T', 'N', 'L']));
  await enterPaintMode(t);
  expect(find.byKey(const ValueKey('tool-eraser')), findsOneWidget);
  for (final template in shiftTemplates) {
    expect(tool(template.key), findsOneWidget, reason: 'ficha ${template.key}');
  }
  await qa.shot('pintar');
  await exitPaintMode(t);
  await qa.shot('mes');
}
