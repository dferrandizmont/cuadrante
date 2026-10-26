import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/summary/domain/month_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

// Resumen por fechas (docs/paridad.md A7), Q88.
//
// Demo data around Monday 19 Oct 2026 (see `summary.dart`): October has 20
// shifts of 8 h = 160 h; from the 19th to the 25th there are 5 shifts (Noche
// 19, 20 and 23, and Mañana + Tarde on the 21st) = 40 h, 24 of them night.

Finder _k(String key) => find.byKey(ValueKey(key));

String _text(WidgetTester t, String key) => t.widget<Text>(_k(key)).data!;

/// Scenarios of this file, listed by `parity.dart`.
final List<QaScenario> rangeSummaryScenarios = [
  qaSummaryRange, // Q88
];

/// Picks [day] in the open calendar dialog and accepts, then goes back to the
/// top of the summary (opening a row scrolls the list).
Future<void> _pickDay(WidgetTester t, String day) async {
  expect(find.byType(DatePickerDialog), findsOneWidget);
  await t.tapAndSettle(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.text(day),
    ),
  );
  await t.tapAndSettle(
    find.byWidgetPredicate(
      (w) => w is Text && w.data?.toLowerCase() == 'aceptar',
    ),
  );
  await t.drag(find.byType(ListView).first, const Offset(0, 1500));
  await t.settle();
}

/// Q88.
const qaSummaryRange = QaScenario(
  'Q88',
  'Resumen por fechas: Desde-Hasta, mismas cifras que el mes',
  _summaryRange,
);

Future<void> _summaryRange(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);

  await t.tapAndSettle(_k('open-summary'), reason: 'Resumen del mes');
  final monthHours = _text(t, 'summary-hours');
  expect(monthHours, '160 h');

  // «Fechas…» starts on the month on screen and gives the same figures.
  await t.tapAndSettle(_k('summary-mode-range'));
  expect(_text(t, 'summary-period'), '1 oct 2026 – 31 oct 2026');
  expect(_text(t, 'summary-hours'), monthHours);
  await qa.shot('mes_como_rango');

  // Desde el 19, hasta el 25.
  await t.tapAndSettle(_k('summary-range-from'));
  await _pickDay(t, '19');
  await t.tapAndSettle(_k('summary-range-to'));
  await _pickDay(t, '25');
  expect(_text(t, 'summary-period'), '19 oct 2026 – 25 oct 2026');
  expect(_text(t, 'summary-range-days'), startsWith('7 días'));
  expect(_text(t, 'summary-shifts-value'), '5');
  expect(_text(t, 'summary-hours'), '40 h');
  expect(_text(t, 'summary-night-value'), '24 h');
  // The screen shows what the engine computes for those days.
  final summary = summarizeRange(
    app.schedule,
    const CivilDate(2026, 10, 19),
    const CivilDate(2026, 10, 25),
  );
  expect(summary.workedMinutes, 40 * 60);
  expect(summary.shiftsWorked, 5);
  await qa.shot('semana');

  // The arrows move the dates by their length: 26 Oct - 1 Nov.
  await t.tapAndSettle(_k('summary-next'));
  expect(_text(t, 'summary-period'), '26 oct 2026 – 1 nov 2026');
  expect(_text(t, 'summary-shifts-value'), '3');

  // No share image for a range; back to the month brings it back.
  expect(_k('summary-share'), findsNothing);
  await t.tapAndSettle(_k('summary-mode-month'));
  expect(_text(t, 'summary-period'), 'Octubre 2026');
  expect(_k('summary-share'), findsOneWidget);
  qa.expectNoFlutterErrors('resumen por fechas');
}
