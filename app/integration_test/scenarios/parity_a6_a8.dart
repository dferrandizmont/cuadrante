import 'package:cuadrante/features/calendar/presentation/day_extras_section.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/summary/domain/month_summary.dart';
import 'package:cuadrante/features/summary/presentation/summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

// Paridad 0.6.0: horas extra y salidas anticipadas (A6) e icono por turno
// (A8), Q96-Q98.
//
// Demo data around Monday 19 Oct 2026: rotation Noche 19-23, Libre 24-25,
// Mañana 26-30 (27 and 28 are Vacaciones). October has 160 h.

const _oct26 = CivilDate(2026, 10, 26); // Mañana by the rotation
const _oct29 = CivilDate(2026, 10, 29); // Mañana by the rotation
const _nbsp = ' ';
const _minus = '−';

/// Scenarios Q96-Q98, registered in `registry.dart`.
final List<QaScenario> parityA6A8Scenarios = [
  qaDayExtras, // Q96
  qaSummaryExtras, // Q97
  qaShiftIcon, // Q98
];

Finder _k(String key) => find.byKey(ValueKey(key));

String _text(WidgetTester t, String key) => t.widget<Text>(_k(key)).data!;

Future<void> _openDay(WidgetTester t, CivilDate date) async {
  await t.tapAndSettle(cell(date), reason: 'casilla de $date');
  expect(find.byType(BottomSheet), findsOneWidget, reason: 'detalle de $date');
}

/// Closes the sheet like a user: the dimmed area, or back when the sheet fills
/// the screen.
Future<void> _closeDay(WidgetTester t) async {
  final sheet = find.byType(BottomSheet);
  if (t.getTopLeft(sheet).dy > 100) {
    await t.tapAt(const Offset(20, 60));
  } else {
    await Navigator.of(t.element(sheet)).maybePop();
  }
  await t.settle();
  expect(sheet, findsNothing, reason: 'la hoja debe cerrarse');
}

/// Taps a stepper button [times] times.
Future<void> _steps(WidgetTester t, String key, int times) async {
  for (var i = 0; i < times; i++) {
    await t.ensureVisible(_k(key));
    await t.tap(_k(key));
    await t.pump(const Duration(milliseconds: 80));
  }
}

/// The quiet time after which the stepper writes the value.
Future<void> _quiet(WidgetTester t) async {
  await t.pump(DayExtrasSection.settle + const Duration(milliseconds: 300));
  await t.settle();
}

Future<List<Map<String, Object?>>> _storedExtras(QaApp app, CivilDate d) =>
    app.query(
      'SELECT date, shift_type_ids, overtime_minutes, early_leave_minutes '
      "FROM day_entries WHERE date = '${d.toIso()}'",
    );

// ---- Q96 -------------------------------------------------------------------

const qaDayExtras = QaScenario(
  'Q96',
  'Detalle: horas extra y salí antes (un paso de deshacer y marca en la casilla)',
  _dayExtras,
);

Future<void> _dayExtras(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  expect(await _storedExtras(app, _oct26), isEmpty);
  expect(_k('extras-mark-2026-10-26'), findsNothing);

  await _openDay(t, _oct26);
  await t.ensureVisible(_k('day-extras'));
  expect(find.text('HORAS EXTRA / SALÍ ANTES'), findsOneWidget);
  expect(_text(t, 'day-overtime-value'), 'Ninguna');

  // 6 taps of 15 min = 1 h 30; 2 taps = 30 min.
  await _steps(t, 'day-overtime-more', 6);
  await _steps(t, 'day-early-more', 2);
  expect(_text(t, 'day-overtime-value'), '1 h 30 min');
  expect(_text(t, 'day-early-value'), '30 min');
  await _quiet(t);
  await qa.shot('seccion');

  await app.flushWrites();
  final rows = await _storedExtras(app, _oct26);
  expect(rows, hasLength(1));
  expect(rows.single['overtime_minutes'], 90);
  expect(rows.single['early_leave_minutes'], 30);
  expect(
    rows.single['shift_type_ids'],
    isNull,
    reason: 'el turno sigue siendo el del patrón',
  );
  expect(idsOn(app.schedule, _oct26), 'morning');

  await _closeDay(t);
  expect(_k('extras-mark-2026-10-26'), findsOneWidget, reason: 'marca «+»');
  await qa.shot('mes');

  // Everything was ONE undo step.
  await enterPaintMode(t);
  await t.tapAndSettle(_k('undo'), reason: 'deshacer');
  await exitPaintMode(t);
  await app.flushWrites();
  expect(await _storedExtras(app, _oct26), isEmpty);
  expect(_k('extras-mark-2026-10-26'), findsNothing);

  // Taking the values away again with «-» removes the row.
  await _openDay(t, _oct26);
  await _steps(t, 'day-early-more', 4);
  await _quiet(t);
  await app.flushWrites();
  expect((await _storedExtras(app, _oct26)).single['early_leave_minutes'], 60);
  await _steps(t, 'day-early-less', 4);
  await _quiet(t);
  await app.flushWrites();
  expect(await _storedExtras(app, _oct26), isEmpty);
  await _closeDay(t);
  qa.expectNoFlutterErrors('horas extra');
}

// ---- Q97 -------------------------------------------------------------------

const qaSummaryExtras = QaScenario(
  'Q97',
  'Resumen: las horas extra suman y las salidas restan, también en el estimado',
  _summaryExtras,
);

Future<void> _summaryExtras(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(
    qa,
    prepare: (storage) async {
      // Mañana 10,00 EUR/h and Tarde 11,00 EUR/h (Noche has no rate).
      for (final (key, rate) in [('morning', 1000), ('afternoon', 1100)]) {
        await storage.repository.saveShiftType(
          shiftTemplates
              .firstWhere((s) => s.key == key)
              .toShiftType(key)
              .copyWith(hourlyRateCents: rate),
        );
      }
    },
  );
  // Through the same controller the day detail uses.
  app.scheduleController
    ..setDayExtras(_oct26, overtimeMinutes: 90)
    ..setDayExtras(_oct29, earlyLeaveMinutes: 60)
    // A Noche (no rate) with overtime: hours yes, euros no.
    ..setDayExtras(const CivilDate(2026, 10, 19), overtimeMinutes: 30);
  await t.settle();

  await t.tapAndSettle(_k('open-summary'), reason: 'icono Resumen del mes');
  expect(find.byType(SummaryScreen), findsOneWidget);
  // 160 h + 2 h of overtime - 1 h of early leave.
  expect(_text(t, 'summary-hours'), '161 h');
  expect(_text(t, 'summary-overtime-value'), '+2 h');
  expect(_text(t, 'summary-early-leave-value'), '${_minus}1 h');
  expect(find.text('+15,00$_nbsp€ en el estimado'), findsOneWidget);
  expect(find.text('${_minus}10,00$_nbsp€ en el estimado'), findsOneWidget);
  await t.ensureVisible(_k('summary-earnings'));
  await t.pump();
  // 1.248,00 + 15,00 - 10,00.
  expect(_text(t, 'summary-earnings'), '1.253,00$_nbsp€');
  expect(_k('summary-extras-no-rate'), findsOneWidget);
  await qa.shot('mes');

  // The screen shows what the engine computes.
  final summary = summarizeMonth(app.schedule, const CivilDate(2026, 10, 1));
  expect(summary.workedMinutes, 161 * 60);
  expect(summary.overtimeMinutes, 120);
  expect(summary.earlyLeaveMinutes, 60);
  expect(summary.earningsCents, 125300);
  qa.expectNoFlutterErrors('resumen con extras');
}

// ---- Q98 -------------------------------------------------------------------

const qaShiftIcon = QaScenario(
  'Q98',
  'Mis turnos: elegir icono, verlo en el mes y en el detalle, y quitarlo',
  _shiftIcon,
);

Future<void> _shiftIcon(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  Future<String?> storedIcon() async =>
      (await app.query("SELECT icon FROM shift_types WHERE id = 'morning'"))
              .single['icon']
          as String?;
  expect(await storedIcon(), isNull);

  await t.tapAndSettle(find.byTooltip('Abrir ajustes'));
  await t.tapAndSettle(_k('settings-shifts'), reason: 'Mis turnos');
  await t.tapAndSettle(_k('shift-row-morning'), reason: 'fila Mañana');
  expect(find.text('Sin icono'), findsWidgets);
  await t.tapAndSettle(_k('shift-icon'), reason: 'Icono');
  expect(_k('shift-icon-grid'), findsOneWidget);
  expect(_k('shift-icon-none'), findsOneWidget);
  for (final icon in ShiftIcon.values) {
    expect(_k('shift-icon-${icon.key}'), findsOneWidget, reason: icon.key);
  }
  await qa.shot('rejilla');
  await t.tapAndSettle(_k('shift-icon-sun'), reason: 'Sol');
  expect(find.text('Icono: Sol'), findsOneWidget);
  await t.tapAndSettle(_k('shift-save'), reason: 'Guardar');
  await app.flushWrites();
  expect(await storedIcon(), 'sun');

  // The list row shows it above the code.
  expect(
    find.descendant(of: _k('shift-row-morning'), matching: _k('badge-icon')),
    findsOneWidget,
  );
  await _backToMonth(t);

  // The month cell: before the code when it fits (a phone has room for a
  // one letter code), and the code is always there.
  expect(inCell(_oct26, find.text('M')), findsOneWidget);
  expect(inCell(_oct26, _k('cell-icon')), findsOneWidget);
  await qa.shot('mes');

  // The day detail row too.
  await _openDay(t, _oct26);
  expect(
    find.descendant(of: _k('day-shift-0'), matching: _k('badge-icon')),
    findsOneWidget,
  );
  await _closeDay(t);

  // «Sin icono» takes it away everywhere.
  await t.tapAndSettle(find.byTooltip('Abrir ajustes'));
  await t.tapAndSettle(_k('settings-shifts'), reason: 'Mis turnos');
  await t.tapAndSettle(_k('shift-row-morning'), reason: 'fila Mañana');
  expect(find.text('Icono: Sol'), findsOneWidget);
  await t.tapAndSettle(_k('shift-icon'), reason: 'Icono');
  await t.tapAndSettle(_k('shift-icon-none'), reason: 'Sin icono');
  await t.tapAndSettle(_k('shift-save'), reason: 'Guardar');
  await app.flushWrites();
  expect(await storedIcon(), isNull);
  await _backToMonth(t);
  expect(inCell(_oct26, _k('cell-icon')), findsNothing);
  expect(inCell(_oct26, find.text('M')), findsOneWidget);
  qa.expectNoFlutterErrors('icono del turno');
}

/// Back to the month screen from the list of shifts.
Future<void> _backToMonth(WidgetTester t) async {
  while (find.byType(BackButton).evaluate().isNotEmpty) {
    await t.tapAndSettle(find.byType(BackButton).last, reason: 'flecha atrás');
  }
  expect(find.text('Pintar'), findsOneWidget, reason: 'de vuelta en el mes');
}
