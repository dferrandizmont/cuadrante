import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/features/calendar/presentation/holiday_label.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/l10n/app_localizations_es.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/text_lines.dart';
import 'harness.dart';

/// The day sheet on the widths and text sizes of the QA campaign (T03): a
/// stable height, a header that closes it when dragged, chips that bleed to
/// the edges with whole names, arrows that look disabled when they are.
Finder get sheet => find.byType(BottomSheet);

void main() {
  setUpAll(initializeLocale);

  const oct21 = CivilDate(2026, 10, 21); // Mañana + Tarde
  const oct24 = CivilDate(2026, 10, 24); // Libre
  const widths = [320.0, 360.0, 412.0];
  const scales = [1.0, 1.3, 2.0];

  Size sizeFor(double width) => Size(width, width < 400 ? 640 : 892);

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> open(WidgetTester tester, CivilDate date) async {
    await revealCell(tester, date);
    await tester.tap(cell(date));
    await tester.pumpAndSettle();
    expect(sheet, findsOneWidget);
  }

  List<String> paletteIds(WidgetTester tester) => [
    for (final s in containerOf(
      tester,
    ).read(scheduleControllerProvider).palette)
      s.id,
  ];

  group('H-T03-1: disabled arrows look disabled', () {
    for (final brightness in Brightness.values) {
      testWidgets('${brightness.name}: first up and last down are dimmed', (
        tester,
      ) async {
        await pumpCalendar(tester, brightness: brightness);
        await open(tester, oct21);

        Color? colorOf(String k) {
          final icon = find.descendant(of: key(k), matching: find.byType(Icon));
          return IconTheme.of(tester.element(icon)).color;
        }

        final tokens = tester.element(sheet).colors;
        // Two shifts: up of the first and down of the last do nothing.
        expect(tester.widget<IconButton>(key('day-up-0')).onPressed, isNull);
        expect(tester.widget<IconButton>(key('day-down-1')).onPressed, isNull);
        expect(colorOf('day-up-0'), tokens.disabledContent);
        expect(colorOf('day-down-1'), tokens.disabledContent);
        expect(colorOf('day-down-0'), tokens.textPrimary);
        expect(colorOf('day-up-1'), tokens.textPrimary);
        expect(tokens.disabledContent, isNot(tokens.textPrimary));
      });
    }
  });

  group('H-T03-2: the header closes the sheet', () {
    testWidgets('dragging the date down closes it', (tester) async {
      await pumpCalendar(tester);
      await open(tester, oct21);
      await tester.fling(
        find.text('Miércoles, 21 de octubre'),
        const Offset(0, 500),
        1500,
      );
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
    });

    testWidgets('the body still scrolls without closing it', (tester) async {
      await pumpCalendar(tester, size: const Size(320, 640));
      await open(tester, oct21);
      final scrollable = find.descendant(
        of: sheet,
        matching: find.byType(Scrollable),
      );
      final vertical = scrollable.evaluate().firstWhere(
        (e) => (e.widget as Scrollable).axis == Axis.vertical,
      );
      final position = tester
          .state<ScrollableState>(find.byWidget(vertical.widget))
          .position;
      expect(position.pixels, 0);
      // Dragging up on the first shift scrolls the body, down brings it back; the
      // sheet stays open the whole time.
      await tester.drag(key('day-shift-0'), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(sheet, findsOneWidget);
      await tester.dragFrom(
        tester.getBottomLeft(sheet) + const Offset(160, -100),
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();
      expect(position.pixels, 0);
      expect(sheet, findsOneWidget);
    });
  });

  group('H-T03-3: the holiday line does not repeat the word', () {
    final l10n = AppLocalizationsEs();

    test('a name that already says "festivo" stands alone', () {
      expect(holidayLine(l10n, 'Festivo propio'), 'Festivo propio');
      expect(holidayLine(l10n, 'festivo local'), 'festivo local');
      expect(holidaySpoken(l10n, 'Festivo propio'), 'Festivo propio');
    });

    test('any other name keeps the word', () {
      expect(
        holidayLine(l10n, 'Fiesta Nacional de España'),
        'Festivo: Fiesta Nacional de España',
      );
      expect(holidayLine(l10n, 'Cumple de Ana'), 'Festivo: Cumple de Ana');
      expect(holidaySpoken(l10n, 'Cumple de Ana'), 'festivo: Cumple de Ana');
    });

    testWidgets('a cell reads it once', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCalendar(tester);
      await open(tester, oct24);
      await tester.ensureVisible(key('day-holiday-switch'));
      await tester.pumpAndSettle();
      await tester.tap(key('day-holiday-switch'));
      await tester.pumpAndSettle();
      await Navigator.of(tester.element(sheet)).maybePop();
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp(r'festivo: Festivo propio')),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(r'sábado 24 de octubre.*, Festivo propio'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('H-T03-4 and H-T03-5: the chips', () {
    for (final width in widths) {
      for (final scale in scales) {
        testWidgets('at $width dp, text $scale: wrapped, whole names', (
          tester,
        ) async {
          await pumpCalendar(tester, size: sizeFor(width), textScale: scale);
          await open(tester, oct21);

          final ids = paletteIds(tester);
          final first = key('day-add-${ids.first}');
          await tester.ensureVisible(first);
          await tester.pumpAndSettle();

          // The chips wrap (H-T17-3): no sideways scroll, every chip inside
          // the sheet...
          final row = key('day-add-wrap');
          expect(
            find.descendant(
              of: row,
              matching: find.byType(SingleChildScrollView),
            ),
            findsNothing,
          );
          final sheetRect = tester.getRect(sheet);
          for (final id in ids) {
            await tester.ensureVisible(key('day-add-$id'));
            await tester.pumpAndSettle();
            final chip = tester.getRect(key('day-add-$id'));
            expect(chip.left, greaterThanOrEqualTo(sheetRect.left));
            expect(chip.right, lessThanOrEqualTo(sheetRect.right));
          }
          await tester.ensureVisible(first);
          await tester.pumpAndSettle();
          // ... and its first chip lines up with the text above it.
          final title = tester.getRect(find.text('Miércoles, 21 de octubre'));
          expect(tester.getRect(first).left + Sp.m, closeTo(title.left, 0.5));

          // Every name is whole: no ellipsis, no word split.
          for (final id in ids) {
            final label = find.descendant(
              of: key('day-add-$id'),
              matching: find.byType(Text),
            );
            final paragraph = tester.renderObject<RenderParagraph>(label.last);
            expect(paragraph.didExceedMaxLines, isFalse, reason: '$id is cut');
            expect(
              wrapsOnlyBetweenWords(paragraph),
              isTrue,
              reason: '$id breaks a word',
            );
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('H-T03-7: the height does not move', () {
    // A tall screen too: there the content used to be shorter than the room,
    // so the sheet grew and shrank with it.
    for (final (width, height, scale) in [
      for (final width in widths)
        for (final scale in scales) (width, sizeFor(width).height, scale),
      (412.0, 1600.0, 1.0),
      (360.0, 1400.0, 1.3),
    ]) {
      testWidgets('at ${width}x$height dp, text $scale: same sheet '
          'whatever happens', (tester) async {
        await pumpCalendar(tester, size: Size(width, height), textScale: scale);
        await open(tester, oct24);
        final start = tester.getRect(sheet);

        void expectStable(String after) {
          final now = tester.getRect(sheet);
          expect(now.top, closeTo(start.top, 0.01), reason: after);
          expect(now.height, closeTo(start.height, 0.01), reason: after);
        }

        // The own-holiday name field appears (first frame and settled).
        await tester.ensureVisible(key('day-holiday-switch'));
        await tester.pumpAndSettle();
        await tester.tap(key('day-holiday-switch'));
        await tester.pump();
        expectStable('holiday switch, first frame');
        await tester.pumpAndSettle();
        expectStable('holiday switch');

        // A long note.
        await tester.ensureVisible(key('day-note'));
        await tester.pumpAndSettle();
        await tester.enterText(
          key('day-note'),
          'una nota\nmuy larga\nque ocupa\nvarias líneas\ny sigue\ny sigue',
        );
        await tester.pump();
        expectStable('typing');

        // The day goes from one shift to two and to none.
        final ids = paletteIds(tester);
        await tester.ensureVisible(key('day-add-${ids.first}'));
        await tester.pumpAndSettle();
        await tester.tap(key('day-add-${ids.first}'));
        await tester.pump();
        expectStable('shift added, first frame');
        await tester.pumpAndSettle();
        expectStable('shift added');
        await tester.ensureVisible(key('day-remove-0'));
        await tester.pumpAndSettle();
        await tester.tap(key('day-remove-0'));
        await tester.pumpAndSettle();
        expectStable('shift removed');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
