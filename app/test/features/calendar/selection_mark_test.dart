import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/icons/app_icons.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';
import 'rendered_cell_text.dart';

/// H-T04-4 (design item 1): the mark of a chosen day used to be a badge with
/// a check over the code and the time ("06–1✓"). Now the chosen day has a
/// thick border in the selection colour and a slightly darker background: the
/// shape tells it apart from the ring of today and from the open day, and
/// nothing is drawn over the code or the time.
void main() {
  setUpAll(initializeLocale);

  // A day of the demo month with a shift (M, 06–14) and one without.
  const withShift = CivilDate(2026, 10, 21);
  const today = CivilDate(2026, 10, 19);

  // A day with a wide code (WWW): the worst case for the border of a chosen
  // day, because the code is fitted to the width of the cell.
  const wideDay = CivilDate(2026, 10, 22);
  const wide = ShiftType(
    id: 'wide',
    code: 'WWW',
    name: 'Amplio',
    colorValue: 0xFFF5A524,
    category: ShiftCategory.work,
    startMinute: 6 * 60,
    endMinute: 14 * 60,
  );

  Future<void> prepare(ScheduleRepository repository) => repository.apply(
    'main',
    ScheduleChange(
      patch: EntriesPatch({
        withShift: EntryChange(
          null,
          const DayEntry(date: withShift, shiftTypeIds: ['morning']),
        ),
      }),
    ),
  );

  Future<void> prepareWide(ScheduleRepository repository) async {
    await repository.saveShiftType(wide);
    await repository.apply(
      'main',
      ScheduleChange(
        patch: EntriesPatch({
          wideDay: EntryChange(
            null,
            const DayEntry(date: wideDay, shiftTypeIds: ['wide']),
          ),
        }),
      ),
    );
  }

  /// The border of the cell of [date] (the ring of today, the ring of the
  /// open day or the thick border of a chosen day).
  Border? borderOf(WidgetTester tester, CivilDate date) {
    final finder = find.descendant(
      of: cell(date),
      matching: find.byType(DecoratedBox),
    );
    if (finder.evaluate().isEmpty) return null;
    final decoration =
        tester.widget<DecoratedBox>(finder.first).decoration as BoxDecoration;
    return decoration.border as Border?;
  }

  /// The colour the cell of [date] is painted on.
  Color backgroundOf(WidgetTester tester, CivilDate date) {
    final finder = find.descendant(
      of: cell(date),
      matching: find.byType(ColoredBox),
    );
    return tester.widget<ColoredBox>(finder.first).color;
  }

  Finder codeOf(CivilDate date) =>
      find.descendant(of: cell(date), matching: find.text('M'));
  Finder timeOf(CivilDate date) => find.descendant(
    of: cell(date),
    matching: find.textContaining(RegExp(r'^06(?:–14)?$')),
  );

  group('the chosen day', () {
    for (final size in [
      const Size(320, 640),
      const Size(915, 412),
      const Size(1280, 800),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '${size.width.toInt()}x${size.height.toInt()}, text $scale: a thick '
          'border, and the code and the time are not covered',
          (tester) async {
            await pumpCalendar(
              tester,
              size: size,
              textScale: scale,
              prepare: prepare,
            );
            await revealCell(tester, withShift);
            final before = backgroundOf(tester, withShift);

            await tester.longPress(cell(withShift));
            await tester.pumpAndSettle();

            // The mark is the border of the cell, not a badge over it.
            final mark = find.byKey(
              ValueKey('selected-mark-${withShift.toIso()}'),
            );
            expect(mark, findsOneWidget);
            expect(
              find.descendant(
                of: cell(withShift),
                matching: find.byIcon(AppIcons.check),
              ),
              findsNothing,
              reason: 'the check badge is gone',
            );

            // The code and the time are whole and inside the cell.
            expect(codeOf(withShift), findsOneWidget);
            final box = tester.getRect(cell(withShift));
            expect(
              timeOf(withShift),
              findsOneWidget,
              reason: 'selection preserves the range or at least its start',
            );
            final texts = <Finder>[codeOf(withShift), timeOf(withShift)];
            for (final finder in texts) {
              expectUnscaledCellText(tester, finder);
              final rect = renderedTextRect(tester, finder);
              expect(rect.left, greaterThanOrEqualTo(box.left));
              expect(rect.right, lessThanOrEqualTo(box.right));
              expect(rect.top, greaterThanOrEqualTo(box.top));
              expect(rect.bottom, lessThanOrEqualTo(box.bottom));
            }

            // The background is a bit darker than the same day unchosen.
            final after = backgroundOf(tester, withShift);
            expect(after, isNot(before));
            expect(
              after.computeLuminance(),
              lessThan(before.computeLuminance()),
              reason: 'the chosen day is darker: $after vs $before',
            );

            // The border is thicker than the ring of today.
            final chosen = borderOf(tester, withShift);
            expect(chosen, isNotNull);
            expect(chosen!.top.width, Sp.selectedBorder);
            final ring = borderOf(tester, today);
            expect(ring, isNotNull);
            expect(
              chosen.top.width,
              greaterThan(ring!.top.width),
              reason: 'the chosen day is told apart by its shape',
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });

  group('the border of a chosen day', () {
    // The border of a chosen day is painted over the content of the cell:
    // the code, the icon and the time are laid out inside it, so the border
    // never covers them (H-T04-4). A wide code (WWW) is the worst case: it
    // is fitted to the width of the cell.
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('a wide code is drawn inside the border, text $scale', (
        tester,
      ) async {
        await pumpCalendar(
          tester,
          size: const Size(320, 640),
          textScale: scale,
          prepare: prepareWide,
        );
        await revealCell(tester, wideDay);
        await tester.longPress(cell(wideDay));
        await tester.pumpAndSettle();

        // The border of the chosen day, and the room left inside it.
        final mark = find.byKey(ValueKey('selected-mark-${wideDay.toIso()}'));
        expect(mark, findsOneWidget);
        final inside = tester.getRect(mark).deflate(Sp.selectedBorder);

        // The code is whole, and it is inside the border: not only inside
        // the cell.
        final code = find.descendant(
          of: cell(wideDay),
          matching: find.text('WWW'),
        );
        expect(code, findsOneWidget);
        final rect = renderedTextRect(tester, code);
        expect(
          rect.left,
          greaterThanOrEqualTo(inside.left - 0.05),
          reason: 'the code does not go under the border: $rect in $inside',
        );
        expect(
          rect.right,
          lessThanOrEqualTo(inside.right + 0.05),
          reason: 'the code does not go under the border: $rect in $inside',
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('the open day keeps its thin ring and its background', (
    tester,
  ) async {
    await pumpCalendar(tester, size: const Size(1280, 800), prepare: prepare);
    await revealCell(tester, withShift);
    await tester.tap(cell(withShift));
    await tester.pumpAndSettle();

    final ring = borderOf(tester, withShift);
    expect(ring, isNotNull);
    expect(ring!.top.width, Sp.selectionRing);
    expect(
      find.byKey(ValueKey('selected-mark-${withShift.toIso()}')),
      findsNothing,
      reason: 'the open day is not a chosen day',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the label of a chosen day still says it is chosen', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpCalendar(tester, prepare: prepare);
    await revealCell(tester, withShift);
    await tester.longPress(cell(withShift));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp('21 de octubre, elegido')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
