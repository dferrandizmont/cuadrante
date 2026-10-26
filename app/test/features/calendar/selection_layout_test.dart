import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import 'harness.dart';
import 'selection_mode_test.dart' show longPress, tapDay, tapTool;

// QA campaign, T04: the notice «N días cambiados · Deshacer» never went away
// and covered the last row (H-T04-1); the action bar and the header of
// selection mode broke words and ate the screen at x2.0 / 320 dp (H-T04-2,
// H-T04-3, H-T04-5); a few details of the sheets (H-T04-6, H-T04-8).

const oct21 = CivilDate(2026, 10, 21);
const oct22 = CivilDate(2026, 10, 22);
const nov3 = CivilDate(2026, 11, 3);
const dec1 = CivilDate(2026, 12, 1);

Finder _key(String key) => find.byKey(ValueKey(key));

const _toolKeys = [
  'selection-set',
  'selection-double',
  'selection-clear',
  'selection-reset',
  'selection-copy',
  'selection-cut',
  'selection-paste',
  'selection-repeat',
  'selection-note',
];

Size _phone(double width) => Size(width, width < 400 ? 640 : 892);

RenderParagraph _paragraph(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(text);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  group('H-T04-1: the notice goes away and leaves the last row reachable', () {
    testWidgets('«N días cambiados · Deshacer» is gone after a few seconds', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await longPress(tester, oct21);
      await tapTool(tester, 'selection-clear');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Deshacer'), findsWidgets);

      // Still there a moment later, gone after the six seconds.
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('the next action replaces it; Copiar goes away too', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await longPress(tester, oct21);
      await tapTool(tester, 'selection-clear');
      await tapTool(tester, 'selection-copy');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('copiado'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('text $scale: while it is up the last row of a 6-row month '
          'scrolls clear of it', (tester) async {
        await pumpCalendar(tester, size: const Size(360, 640), textScale: scale);
        await longPress(tester, oct21);
        // Back to the top: the row of the month is there, and with the tall
        // rows of the grid it is left behind when the day is revealed.
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
        await tester.pumpAndSettle();
        // November 2026 has six rows (1 Nov is a Sunday, 30 Nov a Monday).
        await tester.tap(find.byTooltip('Mes siguiente'));
        await tester.pumpAndSettle();
        await tapDay(tester, nov3);
        await tapTool(tester, 'selection-clear');
        expect(find.byType(SnackBar), findsOneWidget);

        // Scroll to the very end of the screen.
        final position = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(SnackBar), findsOneWidget, reason: 'still up');
        final notice = tester.getRect(find.byType(SnackBar));
        final last = tester.getRect(cell(const CivilDate(2026, 11, 30)));
        expect(
          last.bottom,
          lessThanOrEqualTo(notice.top),
          reason: 'the last row ($last) ends above the notice ($notice)',
        );
      });
    }

    testWidgets('once it is gone the extra room goes with it', (tester) async {
      await pumpCalendar(tester, size: const Size(360, 640));
      await longPress(tester, oct21);
      await tapTool(tester, 'selection-clear');
      final room = find.byKey(
        const ValueKey('notice-clearance'),
        skipOffstage: false,
      );
      expect(room, findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(room, findsNothing);
    });
  });

  group('H-T04-2 / H-T04-3 / H-T04-5: selection bar and header', () {
    for (final width in [320.0, 360.0, 412.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('$width dp, text $scale: whole words, one line of '
            'buttons, the calendar stays usable', (tester) async {
          final size = _phone(width);
          await pumpCalendar(tester, size: size, textScale: scale);
          await longPress(tester, oct21);
          await tapDay(tester, oct22);
          expect(tester.takeException(), isNull);

          // The count wraps only between words.
          final count = _key('selection-count');
          expect(
            wrapsOnlyBetweenWords(_paragraph(tester, count)),
            isTrue,
            reason: paragraphLines(_paragraph(tester, count)).toString(),
          );

          // The header too (its hint is dropped when the text is huge).
          final header = find.text('SELECCIÓN');
          expect(header, findsOneWidget);
          expect(wrapsOnlyBetweenWords(_paragraph(tester, header)), isTrue);
          final hint = find.textContaining('Toca los días');
          if (scale < 1.6) {
            expect(hint, findsOneWidget);
            expect(wrapsOnlyBetweenWords(_paragraph(tester, hint)), isTrue);
          } else {
            expect(hint, findsNothing, reason: 'no room for it');
          }

          // The round buttons are on one line; no label breaks a word.
          final tops = <double>{};
          for (final key in _toolKeys) {
            final tool = _key(key);
            expect(tool, findsOneWidget, reason: key);
            final icon = find.descendant(
              of: tool,
              matching: find.byType(DecoratedBox),
            );
            tops.add(tester.getTopLeft(icon.first).dy.roundToDouble());
            final texts = find.descendant(
              of: tool,
              matching: find.byType(Text),
            );
            if (scale >= 1.6) {
              expect(texts, findsNothing, reason: '$key: tooltip only');
              continue;
            }
            expect(texts, findsOneWidget, reason: key);
            final label = _paragraph(tester, texts);
            expect(
              wrapsOnlyBetweenWords(label),
              isTrue,
              reason: '$key: ${paragraphLines(label)}',
            );
          }
          expect(tops, hasLength(1), reason: 'icons on one line: $tops');

          // The bar leaves most of the screen to the calendar.
          final bar = tester.getRect(_key('selection-bar'));
          expect(
            bar.height,
            lessThanOrEqualTo(size.height * (scale >= 2 ? 0.32 : 0.35)),
            reason: 'bar $bar on $size',
          );
          // And a day of the grid can still be tapped.
          await tester.tap(cell(const CivilDate(2026, 10, 23)));
          await tester.pumpAndSettle();
          expect(find.text('3 días'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('x2.0: the tools still have their names for screen readers '
        'and as tooltip', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCalendar(tester, size: _phone(320), textScale: 2.0);
      await longPress(tester, oct21);
      expect(find.byTooltip('Doblar con…'), findsOneWidget);
      expect(find.bySemanticsLabel('Doblar con…'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Toca los días')),
        findsOneWidget,
        reason: 'the hint stays in the semantics of the header',
      );
      handle.dispose();
    });
  });

  group('H-T04-4: the label says the day is chosen', () {
    testWidgets('the semantics of a chosen day say «elegido»', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCalendar(tester);
      await longPress(tester, oct21);
      final node = tester.getSemantics(cell(oct21));
      expect(node.label, contains('elegido'));
      final other = tester.getSemantics(cell(oct22));
      expect(other.label, isNot(contains('elegido')));
      handle.dispose();
    });
  });

  group('H-T04-6: shift names in «Poner turno…»', () {
    for (final width in [320.0, 412.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$width dp, text $scale: names wrap, none is cut', (
          tester,
        ) async {
          await pumpCalendar(tester, size: _phone(width), textScale: scale);
          await longPress(tester, oct21);
          await tapTool(tester, 'selection-set');
          expect(find.byType(BottomSheet), findsOneWidget);
          final tiles = find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('pick-shift-'),
          );
          expect(tiles, findsWidgets);
          for (final tile in tiles.evaluate()) {
            final names = find.descendant(
              of: find.byWidget(tile.widget),
              matching: find.byType(Text),
            );
            for (final element in names.evaluate()) {
              final paragraph = element.renderObject! as RenderParagraph;
              expect(paragraph.didExceedMaxLines, isFalse);
              expect(paragraph.text.toPlainText(), isNotEmpty);
              expect(wrapsOnlyBetweenWords(paragraph), isTrue);
            }
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('H-T04-8: Pegar says the last day it reaches', () {
    testWidgets('a block with gaps ends well past start + length', (
      tester,
    ) async {
      await pumpCalendar(tester);
      // 21, 22 and 28 October: three days that span eight.
      await longPress(tester, oct21);
      await tapDay(tester, oct22);
      await tapDay(tester, const CivilDate(2026, 10, 28));
      await tapTool(tester, 'selection-copy');
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      await tapDay(tester, nov3);
      await tapTool(tester, 'selection-paste');

      expect(
        tester.widget<Text>(_key('paste-summary')).data,
        'Se pegan 3 días a partir del martes, 3 de noviembre.',
      );
      expect(
        tester.widget<Text>(_key('paste-reach')).data,
        'Se pegará del mar 3 al mar 10 de noviembre.',
      );
    });

    testWidgets('across a month each end carries its month', (tester) async {
      await pumpCalendar(tester);
      await longPress(tester, oct21);
      await tapDay(tester, const CivilDate(2026, 10, 25));
      await tapTool(tester, 'selection-copy');
      await tapDay(tester, const CivilDate(2026, 10, 29));
      await tapTool(tester, 'selection-paste');
      expect(
        tester.widget<Text>(_key('paste-reach')).data,
        'Se pegará del jue 29 de octubre al lun 2 de noviembre.',
      );
    });

    testWidgets('one day: nothing to add to the summary', (tester) async {
      await pumpCalendar(tester);
      await longPress(tester, oct21);
      await tapTool(tester, 'selection-copy');
      await tapDay(tester, oct22);
      await tapTool(tester, 'selection-paste');
      expect(_key('paste-summary'), findsOneWidget);
      expect(_key('paste-reach'), findsNothing);
    });
  });
}
