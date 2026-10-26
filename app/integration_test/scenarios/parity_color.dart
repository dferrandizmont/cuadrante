import 'package:cuadrante/core/theme/shift_palette.dart';
import 'package:cuadrante/core/theme/shift_swatch.dart';
import 'package:cuadrante/features/calendar/presentation/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

// Color libre de un tipo de turno (docs/paridad.md A10), Q89.

/// Scenarios of this file, listed by `parity.dart`.
final List<QaScenario> freeColorScenarios = [
  qaFreeColor, // Q89
];

Finder _k(String key) => find.byKey(ValueKey(key));

/// Q89.
const qaFreeColor = QaScenario(
  'Q89',
  'Color libre: tono, hex y vista previa en claro y oscuro',
  _freeColor,
);

Future<void> _freeColor(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);

  await t.tapAndSettle(find.byTooltip('Abrir ajustes'));
  await t.tapAndSettle(_k('settings-shifts'), reason: 'Mis turnos');
  await t.tapAndSettle(_k('shift-new'));
  await t.enterText(_k('shift-name'), 'Refuerzo');
  await t.pump();

  // «Más colores…» opens the picker with the cell in light and in dark.
  await t.tapAndSettle(_k('shift-color-more'));
  expect(find.text('Elige tu color'), findsOneWidget);
  await qa.shot('selector');

  // A typed colour moves the sliders and the preview; the ink is derived.
  const teal = 0xFF1C9AB5;
  await t.enterText(_k('color-hex'), '#1C9AB5');
  await t.pump();
  expect(t.widget<Slider>(_k('color-hue')).value, closeTo(190, 3));
  for (final brightness in Brightness.values) {
    final swatch = ShiftSwatch.forColor(teal, brightness);
    expect(contrastRatio(swatch.ink, swatch.tint), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(swatch.ink, swatch.disc), greaterThanOrEqualTo(4.5));
  }
  expect(find.textContaining('Contraste '), findsWidgets);
  await qa.shot('hex');

  // A slider rewrites the hex; a bad hex blocks «Usar este color».
  final before = t.widget<TextField>(_k('color-hex')).controller!.text;
  await t.drag(_k('color-hue'), const Offset(80, 0));
  await t.pump();
  expect(t.widget<TextField>(_k('color-hex')).controller!.text, isNot(before));
  await t.enterText(_k('color-hex'), '#12');
  await t.pump();
  expect(find.textContaining('Escribe 6 cifras'), findsOneWidget);

  // Use the teal one and save the shift.
  await t.enterText(_k('color-hex'), '#1C9AB5');
  await t.pump();
  await t.tapAndSettle(_k('color-use'));
  expect(_k('shift-color-current'), findsOneWidget);
  await t.tapAndSettle(_k('shift-save'));
  await app.flushWrites();

  final rows = await app.query(
    "SELECT color_value FROM shift_types WHERE name = 'Refuerzo'",
  );
  expect(rows, hasLength(1));
  expect(rows.single['color_value'], teal);

  // The shift wears that colour in the paint palette of the month.
  for (var i = 0; i < 4 && find.byType(BackButton).evaluate().isNotEmpty; i++) {
    await t.tapAndSettle(find.byType(BackButton).last, reason: 'atrás');
  }
  await enterPaintMode(t);
  final id = app.scheduleState.palette.last.id;
  expect(app.schedule.shiftTypeById(id)!.colorValue, teal);
  expect(find.byType(DayCell), findsWidgets);
  await qa.shot('paleta');
  await exitPaintMode(t);
}
