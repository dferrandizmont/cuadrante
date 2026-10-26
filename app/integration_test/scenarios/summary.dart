import 'dart:typed_data';

import 'package:cuadrante/features/calendar/application/visible_month.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/settings/application/preferences_controller.dart';
import 'package:cuadrante/features/summary/domain/month_summary.dart';
import 'package:cuadrante/features/summary/presentation/month_image.dart';
import 'package:cuadrante/features/summary/presentation/month_share_card.dart';
import 'package:cuadrante/features/summary/presentation/month_sharing.dart';
import 'package:cuadrante/features/summary/presentation/summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

// Resumen del mes (gratis) y compartir el mes como imagen, Q75-Q79.
//
// Demo data around Monday 19 Oct 2026 (the rotation is the open correturnos
// that began on 13 July): October has Noche on 1, 2, 19, 20 and 23, Mañana on
// 5-9, 26, 29, 30 and 21 (with Tarde), Tarde on 12-16 and 21, Libre on nine
// days, Vacaciones on 27-28 and the 22nd cleared: 20 shifts of 8 h = 160 h
// (72 h Mañana, 48 h Tarde, 40 h Noche, all of it night), against 176 h in
// September and 168 h in November. 12 October is a holiday (a Tarde).

const _oct = CivilDate(2026, 10, 1);
const _oct24 = CivilDate(2026, 10, 24); // Libre; the Noche of the 23rd runs in
const _nbsp = ' ';
const _minus = '−';

/// Scenarios Q75-Q79, registered in `registry.dart`.
final List<QaScenario> summaryScenarios = [
  qaSummaryMonthWithRates, // Q75
  qaSummaryMonthsAndYear, // Q76
  qaSummaryHolidaysAndAbsences, // Q77
  qaSummaryShareMonth, // Q78
  qaSummaryRateFromEditor, // Q79
];

Finder _k(String key) => find.byKey(ValueKey(key));

String _text(WidgetTester t, String key) => t.widget<Text>(_k(key)).data!;

/// Mañana 10,00 EUR/h and Tarde 11,00 EUR/h (Noche has no rate).
Future<void> _rates(QaStorage storage) async {
  for (final (key, rate) in [('morning', 1000), ('afternoon', 1100)]) {
    await storage.repository.saveShiftType(
      shiftTemplates
          .firstWhere((t) => t.key == key)
          .toShiftType(key)
          .copyWith(hourlyRateCents: rate),
    );
  }
}

Future<void> _openSummary(WidgetTester t) async {
  await t.tapAndSettle(_k('open-summary'), reason: 'icono Resumen del mes');
  expect(find.byType(SummaryScreen), findsOneWidget);
}

Future<void> _back(WidgetTester t) =>
    t.tapAndSettle(find.byType(BackButton).last, reason: 'flecha atrás');

/// PNG size from its IHDR chunk.
({int width, int height}) _pngSize(Uint8List png) {
  final data = ByteData.sublistView(png);
  return (width: data.getUint32(16), height: data.getUint32(20));
}

// ---- Q75 -------------------------------------------------------------------

const qaSummaryMonthWithRates = QaScenario(
  'Q75',
  'Resumen del mes: horas, turnos y estimado con precios',
  _monthWithRates,
);

Future<void> _monthWithRates(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa, prepare: _rates);
  await _openSummary(t);
  expect(_text(t, 'summary-period'), 'Octubre 2026');

  expect(_text(t, 'summary-hours'), '160 h');
  expect(_text(t, 'summary-shifts-value'), '20');
  expect(_text(t, 'summary-night-value'), '40 h');
  expect(_text(t, 'summary-rest-value'), '9');
  expect(_text(t, 'summary-absences-value'), '2');
  // 72 h x 10 + 48 h x 11; Noche has no rate and says so.
  expect(_text(t, 'summary-earnings'), '1.248,00$_nbsp€');
  expect(find.text('Estimado, antes de impuestos'), findsOneWidget);
  expect(_text(t, 'summary-type-hours-morning'), '72 h');
  expect(_text(t, 'summary-type-pay-morning'), '720,00$_nbsp€');
  expect(_text(t, 'summary-type-pay-afternoon'), '528,00$_nbsp€');
  expect(_text(t, 'summary-type-norate-night'), 'sin precio');
  expect(
    _text(t, 'summary-earnings-missing'),
    'No incluye el pago por hora de Noche: sin precio.',
  );
  await qa.shot('mes');

  // The screen shows what the engine computes.
  final summary = summarizeMonth(app.schedule, _oct);
  expect(summary.workedMinutes, 160 * 60);
  expect(summary.earningsCents, 124800);
  expect(summary.shiftsWorked, 20);
  qa.expectNoFlutterErrors('resumen');
}

// ---- Q76 -------------------------------------------------------------------

const qaSummaryMonthsAndYear = QaScenario(
  'Q76',
  'Resumen: cambiar de mes, comparar con el anterior y tabla del año',
  _monthsAndYear,
);

Future<void> _monthsAndYear(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa, prepare: _rates);
  await _openSummary(t);

  expect(_text(t, 'summary-delta'), '${_minus}16 h respecto a septiembre');
  await t.tapAndSettle(_k('summary-next'));
  expect(_text(t, 'summary-period'), 'Noviembre 2026');
  expect(_text(t, 'summary-hours'), '168 h');
  expect(_text(t, 'summary-delta'), '+8 h respecto a octubre');
  await t.tapAndSettle(_k('summary-previous'));
  await t.tapAndSettle(_k('summary-previous'));
  expect(_text(t, 'summary-period'), 'Septiembre 2026');
  expect(_text(t, 'summary-hours'), '176 h');

  // Before the rotation: an empty month, with a way forward.
  for (var i = 0; i < 3; i++) {
    await t.tapAndSettle(_k('summary-previous'));
  }
  expect(_text(t, 'summary-period'), 'Junio 2026');
  expect(_k('summary-empty'), findsOneWidget);
  expect(find.text('Sin turnos este mes'), findsOneWidget);
  await qa.shot('mes_vacio');

  // The year as a table; a tap on a month opens it.
  await t.tapAndSettle(_k('summary-mode-year'));
  expect(_text(t, 'summary-period'), '2026');
  for (var m = 1; m <= 12; m++) {
    expect(_k('summary-year-row-$m'), findsOneWidget, reason: 'mes $m');
  }
  final october = find.descendant(
    of: _k('summary-year-row-10'),
    matching: find.byType(Text),
  );
  expect(t.widgetList<Text>(october).map((w) => w.data), [
    'Oct',
    '20',
    '160 h',
    '40 h',
    '1.248,00$_nbsp€',
  ]);
  await qa.shot('anio');
  await t.tapAndSettle(_k('summary-year-row-11'));
  expect(_text(t, 'summary-period'), 'Noviembre 2026');
  expect(_text(t, 'summary-hours'), '168 h');

  // Looking at other months does not move the calendar.
  await _back(t);
  expect(app.container.read(visibleMonthProvider), _oct);
}

// ---- Q77 -------------------------------------------------------------------

const qaSummaryHolidaysAndAbsences = QaScenario(
  'Q77',
  'Resumen: horas en festivo (también tras la medianoche) y ausencias',
  _holidaysAndAbsences,
);

Future<void> _holidaysAndAbsences(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  await _openSummary(t);

  // 12 October is a Tarde on a national holiday; two days of Vacaciones.
  expect(_text(t, 'summary-holiday-value'), '8 h');
  expect(find.text('1 turno en festivo'), findsOneWidget);
  expect(_text(t, 'summary-absences-value'), '2');
  expect(
    find.descendant(
      of: _k('summary-type-vacation'),
      matching: find.text('2 días'),
    ),
    findsOneWidget,
  );
  await _back(t);

  // 24 October (a Libre) becomes a holiday of the user: the Noche of the 23rd
  // runs 6 h into it.
  await t.runAsync(
    () => app.holidayController.addUserHoliday(
      date: _oct24,
      name: 'Fiesta local de prueba',
    ),
  );
  await t.settle();
  await _openSummary(t);
  expect(_text(t, 'summary-holiday-value'), '14 h');
  expect(find.text('2 turnos en festivo'), findsOneWidget);
  // Hours worked do not change: the part after midnight is still October's.
  expect(_text(t, 'summary-hours'), '160 h');
  await qa.shot('festivos');
  qa.expectNoFlutterErrors('festivos');
}

// ---- Q78 -------------------------------------------------------------------

const qaSummaryShareMonth = QaScenario(
  'Q78',
  'Compartir el mes como imagen: PNG entregado, 1200 px y primer día de la '
      'semana',
  _shareMonth,
  timeout: Duration(minutes: 4),
);

Future<void> _shareMonth(QaContext qa) async {
  final t = qa.tester;
  final shared = <({Uint8List png, String name, String subject})>[];
  final app = await QaApp.open(
    qa,
    overrides: [
      monthImageSharerProvider.overrideWithValue((png, name, subject) async {
        shared.add((png: png, name: name, subject: subject));
      }),
    ],
  );

  Future<void> waitForShare(int count) async {
    for (var i = 0; i < 100 && shared.length < count; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await t.pump();
    }
    expect(shared.length, count, reason: 'la imagen no llegó a compartir');
  }

  // From the month screen.
  await t.tap(_k('share-month'));
  await waitForShare(1);
  final october = shared.single;
  expect(october.name, 'cuadrante-2026-10.png');
  expect(october.subject, 'Mis turnos de octubre 2026');
  expect(october.png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  expect(october.png.length, greaterThan(20000), reason: 'dibuja algo');
  expect(_pngSize(october.png).width, 1200, reason: '400 dp a 3x');
  await t.settle();
  expect(find.text('No se ha podido compartir la imagen'), findsNothing);
  qa.metric('png_octubre_bytes', october.png.length);

  // From the summary, for the month it shows: February 2026 starts on a
  // Sunday, so it has one row more from Monday than from Sunday.
  await _openSummary(t);
  for (var i = 0; i < 8; i++) {
    await t.tapAndSettle(_k('summary-previous'));
  }
  expect(_text(t, 'summary-period'), 'Febrero 2026');
  await t.tap(_k('summary-share'));
  await waitForShare(2);
  expect(shared.last.name, 'cuadrante-2026-02.png');
  final mondayFirst = _pngSize(shared.last.png);
  expect(mondayFirst.width, 1200);

  await t.runAsync(
    () => app.container.read(preferencesProvider.notifier).setWeekStart(7),
  );
  await t.settle();
  await t.tap(_k('summary-share'));
  await waitForShare(3);
  final sundayFirst = _pngSize(shared.last.png);
  expect(sundayFirst.width, 1200);
  // The card's own row height (it draws with the normal text size), rather
  // than duplicating it in this scenario. The picture is not in the tree, so
  // it is measured from a context at the normal text size too.
  final context = t.element(_k('summary-share'));
  expect(MediaQuery.textScalerOf(context).scale(10), 10,
      reason: 'la batería corre con el texto normal');
  final rowHeight = MonthShareCard.cellHeightOf(context);
  expect(
    mondayFirst.height - sundayFirst.height,
    rowHeight * monthImagePixelRatio,
    reason: 'una fila menos con la semana desde el domingo',
  );
  qa.note(
    'PNG de febrero 2026: ${mondayFirst.width}x${mondayFirst.height} desde '
    'lunes, ${sundayFirst.width}x${sundayFirst.height} desde domingo',
  );
  qa.expectNoFlutterErrors('compartir');
}

// ---- Q79 -------------------------------------------------------------------

const qaSummaryRateFromEditor = QaScenario(
  'Q79',
  'Resumen: poner el precio por hora de Noche desde Mis turnos y ver el '
      'estimado completo',
  _rateFromEditor,
);

Future<void> _rateFromEditor(QaContext qa) async {
  final t = qa.tester;
  await QaApp.open(qa, prepare: _rates);
  await _openSummary(t);
  expect(_text(t, 'summary-earnings'), '1.248,00$_nbsp€');
  expect(_k('summary-type-norate-night'), findsOneWidget);

  // The hint leads to Mis turnos; Noche gets 13,00 EUR/h.
  await t.tapAndSettle(_k('summary-rate-action'));
  expect(_k('shift-list'), findsOneWidget);
  await t.tapAndSettle(_k('shift-row-night'));
  await t.ensureVisible(_k('shift-rate'));
  await t.pump();
  await t.enterText(_k('shift-rate'), '13,00');
  await t.pump();
  await t.tapAndSettle(_k('shift-save'));
  expect(_k('shift-list'), findsOneWidget, reason: 'vuelve a la lista');
  await _back(t);
  expect(find.byType(SummaryScreen), findsOneWidget);

  // 72 h x 10 + 48 h x 11 + 40 h x 13 = 1.768,00: nothing is missing now.
  expect(_text(t, 'summary-earnings'), '1.768,00$_nbsp€');
  expect(_k('summary-earnings-missing'), findsNothing);
  expect(_k('summary-rate-action'), findsNothing);
  expect(_text(t, 'summary-type-pay-night'), '520,00$_nbsp€');
  await qa.shot('estimado_completo');
  qa.expectNoFlutterErrors('precio');
}
