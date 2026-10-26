import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/features/onboarding/application/onboarding_providers.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/text_lines.dart';
import 'harness.dart';

/// Layout of the month screen on the three widths and three text scales of
/// the QA campaign (T02): the date line, the shared page padding and the room
/// under the grid.
void main() {
  setUpAll(initializeLocale);

  const widths = [320.0, 360.0, 412.0];
  const scales = [1.0, 1.3, 2.0];

  Size sizeFor(double width) => Size(width, width < 400 ? 640 : 892);

  // Wednesday 21 October: the longest date of the week ("Miércoles, 21 de
  // octubre").
  DateTime wednesday() => DateTime(2026, 10, 21, 12);

  group('H-T02-1: the date of the header', () {
    for (final width in widths) {
      for (final scale in scales) {
        testWidgets('at $width dp, text $scale: whole words, no ellipsis', (
          tester,
        ) async {
          await pumpCalendar(
            tester,
            size: sizeFor(width),
            textScale: scale,
            clock: wednesday,
          );
          final finder = find.byKey(const ValueKey('month-date'));
          final text = tester.widget<Text>(finder).data!;
          // Either the long form or the short one, never a cut of them.
          expect(text, anyOf('Miércoles, 21 de octubre', 'Mié 21 oct'));
          final paragraph = tester.renderObject<RenderParagraph>(finder);
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(wrapsOnlyBetweenWords(paragraph), isTrue);
          // Left of the share button, in the header.
          final share = tester.getRect(
            find.byTooltip('Compartir el mes como imagen'),
          );
          expect(tester.getRect(finder).right, lessThanOrEqualTo(share.left));
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('the long form is kept when it fits', (tester) async {
      // The test font is as wide as it is tall (Ahem), so "fits" needs room.
      await pumpCalendar(tester, size: const Size(640, 892), clock: wednesday);
      expect(find.text('Miércoles, 21 de octubre'), findsOneWidget);
    });

    testWidgets('large text on a narrow phone uses the short form', (
      tester,
    ) async {
      await pumpCalendar(
        tester,
        size: const Size(320, 640),
        textScale: 2,
        clock: wednesday,
      );
      expect(find.text('Mié 21 oct'), findsOneWidget);
    });
  });

  group('H-T02-2: one page padding', () {
    for (final width in widths) {
      testWidgets('at $width dp the arrows, the grid and the cards line up', (
        tester,
      ) async {
        await pumpCalendar(tester, size: sizeFor(width));
        containerOf(tester).read(onboardingTipProvider.notifier).show();
        await tester.pumpAndSettle();

        double glyphRight(String tooltip) => tester
            .getRect(
              find.descendant(
                of: find.byTooltip(tooltip),
                matching: find.byType(Icon),
              ),
            )
            .right;

        final gear = glyphRight('Abrir ajustes');
        final next = glyphRight('Mes siguiente');
        expect(gear, closeTo(width - Sp.l, 1));
        expect(next, closeTo(gear, 0.5));

        final tip = tester.getRect(
          find.byKey(const ValueKey('onboarding-tip')),
        );
        expect(tip.left, closeTo(Sp.l, 0.5));
        expect(tip.right, closeTo(width - Sp.l, 0.5));

        final title = tester.getRect(find.byKey(const ValueKey('month-title')));
        expect(title.left, closeTo(Sp.l, 0.5));

        // The visible edge of the cells (the cell keeps Sp.cellGap / 2 of its
        // own) is where the cards end.
        await tester.scrollUntilVisible(
          cell(const CivilDate(2026, 10, 25)),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        final monday = tester.getRect(cell(const CivilDate(2026, 10, 19)));
        final sunday = tester.getRect(cell(const CivilDate(2026, 10, 25)));
        expect(monday.left + Sp.cellGap / 2, closeTo(Sp.l, 0.5));
        expect(sunday.right - Sp.cellGap / 2, closeTo(width - Sp.l, 0.5));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('H-T02-10: the last row is always reachable', () {
    for (final width in widths) {
      for (final scale in scales) {
        testWidgets('at $width dp, text $scale, with the tip on', (
          tester,
        ) async {
          await pumpCalendar(tester, size: sizeFor(width), textScale: scale);
          containerOf(tester).read(onboardingTipProvider.notifier).show();
          await tester.pumpAndSettle();

          final last = cell(const CivilDate(2026, 11, 8));
          await tester.scrollUntilVisible(
            last,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -2000),
          );
          await tester.pumpAndSettle();

          final fab = tester.getRect(find.byType(FloatingActionButton));
          // Every day of the last row is clear of the floating button and
          // on screen.
          for (var d = 2; d <= 8; d++) {
            final rect = tester.getRect(cell(CivilDate(2026, 11, d)));
            expect(rect.bottom, lessThanOrEqualTo(fab.top + 0.01));
          }
          final rect = tester.getRect(last);
          expect(rect.bottom, lessThanOrEqualTo(fab.top + 0.01));
          expect(rect.top, greaterThanOrEqualTo(0));
        });
      }
    }
  });
}
