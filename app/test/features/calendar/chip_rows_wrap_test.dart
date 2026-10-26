import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/spacing.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/presentation/paint_bar.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import 'harness.dart';

/// H-T17-3, H-T21-9 and H-T17-7 (QA campaigns T17 and T21): the rows of shift
/// chips of the day sheet and of the paint tools wrap onto more lines instead
/// of being cut mid-word in one scrolling row (large text on a narrow phone,
/// landscape, Basque), and the tools card of the right pane keeps the margin
/// of the other cards. Measured with Roboto: the test font is twice as wide.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });
  tearDown(() => debugPhoneLocales = const [Locale('es', 'ES')]);

  const oct21 = CivilDate(2026, 10, 21);

  Finder key(String k) => find.byKey(ValueKey(k));

  List<String> paletteIds(WidgetTester tester) => [
    for (final s in containerOf(
      tester,
    ).read(scheduleControllerProvider).palette)
      s.id,
  ];

  /// Every chip of [keys] shows its whole name (no ellipsis, no word split)
  /// and lies inside [bounds] horizontally, once scrolled into view
  /// vertically; nothing in [row] scrolls sideways.
  Future<void> expectWhole(
    WidgetTester tester, {
    required List<String> keys,
    required Finder row,
    required Rect bounds,
  }) async {
    final sideways = find.descendant(
      of: row,
      matching: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axis == Axis.horizontal,
      ),
    );
    expect(sideways, findsNothing, reason: 'the row scrolls sideways');
    for (final k in keys) {
      await tester.ensureVisible(key(k));
      await tester.pumpAndSettle();
      final chip = tester.getRect(key(k));
      expect(chip.left, greaterThanOrEqualTo(bounds.left - 0.5), reason: k);
      expect(chip.right, lessThanOrEqualTo(bounds.right + 0.5), reason: k);
      final label = find.descendant(of: key(k), matching: find.byType(Text));
      final paragraph = tester.renderObject<RenderParagraph>(label.last);
      expect(paragraph.didExceedMaxLines, isFalse, reason: '$k is cut');
      expect(wrapsOnlyBetweenWords(paragraph), isTrue, reason: '$k breaks');
      final text = tester.getRect(label.last);
      expect(text.left, greaterThanOrEqualTo(bounds.left - 0.5), reason: k);
      expect(text.right, lessThanOrEqualTo(bounds.right + 0.5), reason: k);
    }
    expect(tester.takeException(), isNull);
  }

  Future<void> openDay(WidgetTester tester) async {
    await revealCell(tester, oct21);
    await tester.tap(cell(oct21));
    await tester.pumpAndSettle();
  }

  Rect screen(WidgetTester tester) =>
      Offset.zero & (tester.view.physicalSize / tester.view.devicePixelRatio);

  group('the day sheet', () {
    for (final (name, size, scale) in [
      ('320 dp, text 2.0', const Size(320, 640), 2.0),
      ('landscape phone 560 x 360', const Size(560, 360), 1.0),
      ('landscape phone 560 x 360, text 1.3', const Size(560, 360), 1.3),
    ]) {
      testWidgets('$name: «Doblar con otro turno» wraps, whole names', (
        tester,
      ) async {
        await pumpCalendar(tester, size: size, textScale: scale);
        await openDay(tester);
        expect(find.text('DOBLAR CON OTRO TURNO'), findsOneWidget);
        await expectWhole(
          tester,
          keys: [for (final id in paletteIds(tester)) 'day-add-$id'],
          row: key('day-add-wrap'),
          bounds: tester.getRect(find.byType(BottomSheet)),
        );
        // More than one line: the row does not fit in one at this size.
        final tops = {
          for (final id in paletteIds(tester))
            (tester.getTopLeft(key('day-add-$id')).dy -
                    tester.getTopLeft(key('day-add-wrap')).dy)
                .round(),
        };
        expect(tops.length, greaterThan(1), reason: 'it wrapped');
      });
    }

    testWidgets('landscape with two panes: the chips of the pane', (
      tester,
    ) async {
      const size = Size(915, 412);
      await pumpCalendar(tester, size: size, textScale: 1.3);
      await openDay(tester);
      await expectWhole(
        tester,
        keys: [for (final id in paletteIds(tester)) 'day-add-$id'],
        row: key('day-add-wrap'),
        bounds: screen(tester),
      );
    });

    testWidgets('Basque at 320 dp, text 2.0: «Gehitu txanda» wraps', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      debugPhoneLocales = const [Locale('eu')];
      await AppUnderTest.pump(tester, size: const Size(320, 640));
      tester.platformDispatcher.localesTestValue = const [Locale('eu')];
      await tester.pumpAndSettle();
      await revealCell(tester, harnessToday);
      await tester.tap(cell(harnessToday));
      await tester.pumpAndSettle();
      final ids = paletteIds(tester);
      await expectWhole(
        tester,
        keys: [for (final id in ids) 'day-add-$id'],
        row: key('day-add-wrap'),
        bounds: tester.getRect(find.byType(BottomSheet)),
      );
    });
  });

  group('the paint tools', () {
    for (final (name, size, scale) in [
      ('320 dp, text 2.0', const Size(320, 640), 2.0),
      ('landscape phone 560 x 360', const Size(560, 360), 1.0),
    ]) {
      testWidgets('$name: the tools wrap and scroll vertically', (
        tester,
      ) async {
        await pumpCalendar(tester, size: size, textScale: scale);
        await enterPaintMode(tester);
        await expectWhole(
          tester,
          keys: [
            'tool-eraser',
            for (final id in paletteIds(tester)) 'tool-$id',
            'tool-edit-types',
          ],
          row: key('paint-tools-wrap'),
          bounds: screen(tester),
        );
        // It never takes more than a share of the screen: the rest scrolls.
        expect(
          tester.getSize(key('paint-tools-scroll')).height,
          lessThanOrEqualTo(size.height * 0.25 + 0.5),
        );
      });
    }
  });

  group('H-T17-7: the tools card of the right pane', () {
    testWidgets('keeps the margin of the other cards, rounded all around', (
      tester,
    ) async {
      const size = Size(915, 412);
      await pumpCalendar(tester, size: size);
      final other = tester.getRect(key('upcoming-days'));
      expect(other.right, closeTo(size.width - Sp.l, 0.5));

      await enterPaintMode(tester);
      final card = tester.getRect(find.byType(PaintBar));
      expect(card.right, closeTo(size.width - Sp.l, 0.5));
      expect(card.left, greaterThanOrEqualTo(Sp.l));
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(PaintBar),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final radius = (box.decoration as BoxDecoration).borderRadius!.resolve(
        TextDirection.ltr,
      );
      expect(radius.bottomRight, isNot(Radius.zero));
      expect(radius.bottomLeft, isNot(Radius.zero));
    });
  });
}
