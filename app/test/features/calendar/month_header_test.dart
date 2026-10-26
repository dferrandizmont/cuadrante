import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/features/calendar/presentation/today_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

/// The date line of the month screen: date on the left, then the calendar
/// switcher (only with two or more calendars) and the share, agenda and
/// settings buttons pinned to the trailing edge. On a real phone they floated
/// in the middle: the date was `Expanded` and the switcher `Flexible`, so the
/// free space was split in two even when the switcher was hidden.
void main() {
  setUpAll(initializeLocale);

  /// Right edge of the glyph of the button with [tooltip].
  double glyphRight(WidgetTester tester, String tooltip) => tester
      .getRect(
        find.descendant(
          of: find.byTooltip(tooltip),
          matching: find.byType(Icon),
        ),
      )
      .right;

  for (final width in [320.0, 412.0]) {
    for (final two in [false, true]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets(
          'at $width dp, ${two ? 'two calendars' : 'one calendar'}, text '
          'scale $scale: the buttons are flush right',
          (tester) async {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            await AppUnderTest.pump(
              tester,
              size: Size(width, 844),
              prepare: two ? (db) async => addSecondCalendar(db) : null,
            );

            // The settings glyph ends where the "today" card does, which is
            // the page padding from the screen edge.
            final card = tester.getRect(
              find
                  .descendant(
                    of: find.byType(TodayCard),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            );
            expect(card.right, closeTo(width - Sp.l, 0.5));
            expect(
              glyphRight(tester, 'Abrir ajustes'),
              closeTo(width - Sp.l, 1),
            );

            // Share, agenda and settings sit side by side, in that order.
            final share = glyphRight(tester, 'Compartir el mes como imagen');
            final agenda = glyphRight(tester, 'Agenda de notas');
            final settings = glyphRight(tester, 'Abrir ajustes');
            expect(settings - agenda, closeTo(48, 1));
            expect(agenda - share, closeTo(48, 1));

            // The date is still on the left, under no one's feet.
            final date = tester.getRect(
              find.byKey(const ValueKey('month-date')),
            );
            expect(date.left, closeTo(Sp.l, 0.5));
            expect(date.right, lessThanOrEqualTo(share));
            if (two) {
              final pill = tester.getRect(
                find.byKey(const ValueKey('calendar-switcher')),
              );
              expect(pill.right, lessThanOrEqualTo(share));
              expect(pill.left, greaterThanOrEqualTo(date.right - 0.5));
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
