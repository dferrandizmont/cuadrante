import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/summary/presentation/summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../calendar/harness.dart';

// «Horas extra» and «Salidas anticipadas» in the summary screen (A6).
// Demo data of October 2026: 160 h, Mañana 10 EUR/h (72 h) and Tarde 11 EUR/h
// (48 h) with the rates below, Noche (40 h) without rate. Mañana on 26 and 29
// October, Noche on 19.

Finder _key(String key) => find.byKey(ValueKey(key));

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(_key(key)).data!;

const _nbsp = ' ';
const _minus = '−';

Future<void> _rates(ScheduleRepository repository) async {
  for (final (key, rate) in [('morning', 1000), ('afternoon', 1100)]) {
    await repository.saveShiftType(
      shiftTemplates
          .firstWhere((t) => t.key == key)
          .toShiftType(key)
          .copyWith(hourlyRateCents: rate),
    );
  }
}

Future<void> _openSummary(WidgetTester tester) async {
  await tester.tap(_key('open-summary'));
  await tester.pumpAndSettle();
  expect(find.byType(SummaryScreen), findsOneWidget);
}

void main() {
  testWidgets('without extras the month has no such lines', (tester) async {
    await pumpCalendar(tester, prepare: _rates);
    await _openSummary(tester);
    expect(_text(tester, 'summary-hours'), '160 h');
    expect(_key('summary-overtime'), findsNothing);
    expect(_key('summary-early-leave'), findsNothing);
    expect(_key('summary-extras-no-rate'), findsNothing);
  });

  testWidgets('overtime and early leave: lines, total hours and estimate', (
    tester,
  ) async {
    await pumpCalendar(tester, prepare: _rates);
    final controller = containerOf(tester)
        .read(scheduleControllerProvider.notifier);
    // Priced Mañana: +1 h 30 and -1 h. Unpriced Noche: +30 min.
    controller.setDayExtras(const CivilDate(2026, 10, 26), overtimeMinutes: 90);
    controller.setDayExtras(
      const CivilDate(2026, 10, 29),
      earlyLeaveMinutes: 60,
    );
    controller.setDayExtras(const CivilDate(2026, 10, 19), overtimeMinutes: 30);
    await tester.pumpAndSettle();

    await _openSummary(tester);
    // 160 h + 2 h of overtime - 1 h.
    expect(_text(tester, 'summary-hours'), '161 h');
    expect(_text(tester, 'summary-overtime-value'), '+2 h');
    expect(_text(tester, 'summary-early-leave-value'), '${_minus}1 h');
    expect(find.text('Horas extra'), findsOneWidget);
    expect(find.text('Salidas anticipadas'), findsOneWidget);
    // Pay of the priced day only: +15,00 and -10,00.
    expect(find.text('+15,00$_nbsp€ en el estimado'), findsOneWidget);
    expect(find.text('${_minus}10,00$_nbsp€ en el estimado'), findsOneWidget);

    await tester.ensureVisible(_key('summary-earnings'));
    await tester.pump();
    expect(_text(tester, 'summary-earnings'), '1.253,00$_nbsp€');
    // The Noche overtime has no rate: said, and not in the euros.
    expect(_key('summary-extras-no-rate'), findsOneWidget);
  });

  testWidgets('«Fechas…» shows the same extras lines and figures as the '
      'month', (tester) async {
    await pumpCalendar(tester, prepare: _rates);
    final controller = containerOf(tester)
        .read(scheduleControllerProvider.notifier);
    controller.setDayExtras(const CivilDate(2026, 10, 26), overtimeMinutes: 90);
    controller.setDayExtras(
      const CivilDate(2026, 10, 29),
      earlyLeaveMinutes: 60,
    );
    controller.setDayExtras(const CivilDate(2026, 10, 19), overtimeMinutes: 30);
    await tester.pumpAndSettle();

    await _openSummary(tester);
    final monthHours = _text(tester, 'summary-hours');
    await tester.ensureVisible(_key('summary-earnings'));
    await tester.pump();
    final monthEarnings = _text(tester, 'summary-earnings');

    await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_key('summary-mode-range'));
    await tester.tap(_key('summary-mode-range'));
    await tester.pumpAndSettle();
    expect(_text(tester, 'summary-period'), '1 oct 2026 – 31 oct 2026');
    expect(_text(tester, 'summary-hours'), monthHours);
    expect(_text(tester, 'summary-hours'), '161 h');
    expect(_text(tester, 'summary-overtime-value'), '+2 h');
    expect(_text(tester, 'summary-early-leave-value'), '${_minus}1 h');
    await tester.ensureVisible(_key('summary-earnings'));
    await tester.pump();
    expect(_text(tester, 'summary-earnings'), monthEarnings);
    expect(_key('summary-extras-no-rate'), findsOneWidget);
  });

  testWidgets('the footnotes explain how extras are counted', (tester) async {
    await pumpCalendar(tester, prepare: _rates);
    containerOf(tester)
        .read(scheduleControllerProvider.notifier)
        .setDayExtras(const CivilDate(2026, 10, 26), overtimeMinutes: 60);
    await tester.pumpAndSettle();
    await _openSummary(tester);
    await tester.ensureVisible(_key('summary-notes'));
    await tester.pump();
    expect(
      find.textContaining('Horas extra y salidas anticipadas: las que anotas'),
      findsOneWidget,
    );
  });

  testWidgets('a month with only overtime on a day with no shift still shows '
      'its hours', (tester) async {
    await pumpCalendar(tester);
    final controller = containerOf(tester)
        .read(scheduleControllerProvider.notifier);
    // March 2025 is before the rotation started: no shifts at all.
    controller.setDayExtras(const CivilDate(2025, 3, 3), overtimeMinutes: 45);
    await tester.pumpAndSettle();
    await _openSummary(tester);
    // Go back to March 2025.
    for (var i = 0; i < 19; i++) {
      await tester.tap(_key('summary-previous'));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(_text(tester, 'summary-period'), 'Marzo 2025');
    expect(_key('summary-empty'), findsNothing);
    expect(_text(tester, 'summary-hours'), '45 min');
    expect(_text(tester, 'summary-overtime-value'), '+45 min');
  });

  testWidgets('the year table totals include the extras', (tester) async {
    await pumpCalendar(tester, prepare: _rates);
    containerOf(tester)
        .read(scheduleControllerProvider.notifier)
        .setDayExtras(const CivilDate(2026, 10, 26), overtimeMinutes: 120);
    await tester.pumpAndSettle();
    await _openSummary(tester);
    await tester.tap(_key('summary-mode-year'));
    await tester.pumpAndSettle();
    final row = tester.widget<Text>(
      find.descendant(
        of: _key('summary-year-row-10'),
        matching: find.text('162 h'),
      ),
    );
    expect(row.data, '162 h');
    expect(_key('summary-year-extras-note'), findsOneWidget);
  });
}
