import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';
import 'rendered_cell_text.dart';

/// Design item 5 (H-T18-7): the title of the month used to shrink (a
/// FittedBox) until it was tiny with a big text («Octubre 2026» squeezed at
/// 320 dp and 200 %). Now the title keeps the reading size: the month and
/// the year go on two lines when they do not fit next to the buttons, and
/// the buttons go below the title when even the month does not fit.
void main() {
  setUpAll(initializeLocale);

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(1280, 800),
  ]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        '${size.width.toInt()}x${size.height.toInt()}, text $scale: the title '
        'keeps its reading size',
        (tester) async {
          await pumpCalendar(tester, size: size, textScale: scale);
          final title = find.byKey(const ValueKey('month-title'));
          expect(title, findsOneWidget);

          final context = tester.element(title);
          final style = context.type.title;
          final scaler = MediaQuery.textScalerOf(context);
          final expected = scaler.scale(style.fontSize! * style.height!);

          final month = find.descendant(
            of: title,
            matching: find.text('Octubre'),
          );
          expect(month, findsOneWidget);
          expectUnscaledCellText(tester, month);
          expect(
            renderedTextRect(tester, month).height,
            greaterThanOrEqualTo(expected * 0.95),
            reason: 'the title is not shrunk: ${tester.getRect(month)}',
          );
          // The title is a button that opens the year, and it says so.
          expect(
            find.bySemanticsLabel(RegExp('Octubre')),
            findsWidgets,
            reason: 'the title announces the month',
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('with a big text the month and the year are on two lines', (
    tester,
  ) async {
    await pumpCalendar(tester, size: const Size(320, 640), textScale: 1.3);
    // Another year: the title says the month and the year.
    for (var i = 0; i < 10; i++) {
      final previous = find.byTooltip('Mes anterior');
      await tester.ensureVisible(previous);
      await tester.pumpAndSettle();
      await tester.tap(previous);
      await tester.pumpAndSettle();
    }
    final title = find.byKey(const ValueKey('month-title'));
    expect(
      find.descendant(of: title, matching: find.text('Diciembre')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: title, matching: find.text('2025')),
      findsOneWidget,
    );
    // Neither line is shrunk: both are at the reading size.
    final context = tester.element(title);
    final style = context.type.title;
    final scaler = MediaQuery.textScalerOf(context);
    final expected = scaler.scale(style.fontSize! * style.height!);
    for (final text in ['Diciembre', '2025']) {
      final line = find.descendant(of: title, matching: find.text(text));
      expectUnscaledCellText(tester, line);
      expect(
        renderedTextRect(tester, line).height,
        greaterThanOrEqualTo(expected * 0.95),
        reason: '$text is not shrunk',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the title is a button that opens the year', (tester) async {
    await pumpCalendar(tester, size: const Size(320, 640), textScale: 2.0);
    final title = find.byKey(const ValueKey('month-title'));
    final context = tester.element(title);
    final scaler = MediaQuery.textScalerOf(context);
    final style = context.type.title;
    final expected = scaler.scale(style.fontSize! * style.height!);
    expect(
      tester.getRect(title).height,
      greaterThanOrEqualTo(expected),
      reason: 'the title is as tall as its text',
    );
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    await tester.tap(title);
    await tester.pumpAndSettle();
    expect(find.text('Vista anual'), findsOneWidget);
  });
}
