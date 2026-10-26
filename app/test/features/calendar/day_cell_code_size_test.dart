import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import 'harness.dart';
import 'rendered_cell_text.dart';

/// H-T18-5 (design item 2): with the text at 200 % the code of the shift
/// used to shrink to a speck (about 9 sp, smaller than with the normal
/// text). Now the code grows with the text, up to what fits the cell, and
/// the time is always there: the rows of the grid grow with the text and
/// the screen scrolls when they do not fit.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  // A day with a shift (M, 06–14).
  const day = CivilDate(2026, 10, 21);

  Future<void> prepare(ScheduleRepository repository) => repository.apply(
    'main',
    ScheduleChange(
      patch: EntriesPatch({
        day: EntryChange(
          null,
          const DayEntry(date: day, shiftTypeIds: ['morning']),
        ),
      }),
    ),
  );

  Finder codeOf() => find.descendant(of: cell(day), matching: find.text('M'));
  Finder timeOf() =>
      find.descendant(of: cell(day), matching: find.textContaining('06'));

  /// The height of the code as it is drawn on screen.
  double codeHeight(WidgetTester tester) =>
      renderedTextRect(tester, codeOf()).height;

  Future<void> open(
    WidgetTester tester, {
    required Size size,
    required double scale,
  }) async {
    await pumpCalendar(tester, size: size, textScale: scale, prepare: prepare);
    await revealCell(tester, day);
  }

  group('the code of the cell', () {
    for (final size in [
      const Size(320, 640),
      const Size(915, 412),
      const Size(1280, 800),
    ]) {
      testWidgets(
        '${size.width.toInt()}x${size.height.toInt()}: with text x2.0 the code '
        'grows and is never smaller than with the normal text',
        (tester) async {
          await open(tester, size: size, scale: 1.0);
          final normal = codeHeight(tester);
          expect(normal, greaterThan(0));

          await open(tester, size: size, scale: 2.0);
          expectUnscaledCellText(tester, codeOf());
          expectUnscaledCellText(tester, timeOf());
          final big = codeHeight(tester);

          // It grows with the text...
          expect(
            big,
            greaterThan(normal),
            reason: 'the code grows with the text: $normal -> $big',
          );
          // ...and it never reads smaller than with the normal text.
          expect(
            big,
            greaterThanOrEqualTo(normal),
            reason: 'the code of a cell is never smaller than usual',
          );
          // The time is there too: the cell is never only a code.
          expect(timeOf(), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  testWidgets('a wide three-letter code fits independently without clipping '
      'or shrinking its time', (tester) async {
    const wide = ShiftType(
      id: 'wide',
      code: 'WWW',
      name: 'Amplio',
      colorValue: 0xFFF5A524,
      category: ShiftCategory.work,
      startMinute: 6 * 60,
      endMinute: 14 * 60,
    );
    double? normalHeight;
    for (final scale in [1.0, 2.0]) {
      await pumpCalendar(
        tester,
        size: const Size(320, 640),
        textScale: scale,
        prepare: (repository) async {
          await repository.saveShiftType(wide);
          await repository.apply(
            'main',
            ScheduleChange(
              patch: EntriesPatch({
                day: EntryChange(
                  null,
                  const DayEntry(date: day, shiftTypeIds: ['wide']),
                ),
              }),
            ),
          );
        },
      );
      await revealCell(tester, day);
      final code = find.descendant(of: cell(day), matching: find.text('WWW'));
      expect(code, findsOneWidget);
      expectUnscaledCellText(tester, timeOf());
      final bounds = tester.getRect(cell(day));
      for (final text in [code, timeOf()]) {
        final rect = renderedTextRect(tester, text);
        expect(bounds.contains(rect.topLeft), isTrue);
        expect(bounds.contains(rect.bottomRight), isTrue);
      }
      final height = renderedTextRect(tester, code).height;
      if (normalHeight != null) {
        expect(height, greaterThanOrEqualTo(normalHeight * 0.95));
      }
      normalHeight = height;
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the rows of the grid grow with the text, and the time is '
      'always there', (tester) async {
    await open(tester, size: const Size(320, 640), scale: 1.0);
    final normalRow = tester.getRect(cell(day)).height;

    await open(tester, size: const Size(320, 640), scale: 2.0);
    final bigRow = tester.getRect(cell(day)).height;
    expect(bigRow, greaterThan(normalRow));

    // The code and the time are inside the cell, and the cell shows them
    // whole.
    final box = tester.getRect(cell(day));
    for (final finder in [codeOf(), timeOf()]) {
      expectUnscaledCellText(tester, finder);
      final rect = renderedTextRect(tester, finder);
      expect(rect.left, greaterThanOrEqualTo(box.left));
      expect(rect.right, lessThanOrEqualTo(box.right));
      expect(rect.top, greaterThanOrEqualTo(box.top));
      expect(rect.bottom, lessThanOrEqualTo(box.bottom));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the code of the cell reads at least as big as with the normal '
      'text', (tester) async {
    await open(tester, size: const Size(320, 640), scale: 2.0);
    final context = tester.element(cell(day));
    final normal = context.type.cellCode.fontSize!;
    expect(
      codeHeight(tester),
      greaterThanOrEqualTo(normal),
      reason: 'the code reads at least as big as with the normal text',
    );
  });
}
