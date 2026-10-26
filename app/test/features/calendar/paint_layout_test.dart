import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/application/visible_month.dart';
import 'package:cuadrante/features/calendar/presentation/month_grid.dart';
import 'package:cuadrante/features/calendar/presentation/day_cell.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/text_lines.dart';
import '../../support/real_font.dart';
import 'harness.dart';
import 'rendered_cell_text.dart';

/// Paint mode on the widths and text sizes of the QA campaign (T02): a header
/// that never moves the month, a label that never breaks, tool names that are
/// never cut.
void main() {
  setUpAll(initializeLocale);

  const widths = [320.0, 360.0, 412.0];
  const scales = [1.0, 1.3, 2.0];

  Size sizeFor(double width) => Size(width, 900);

  List<String> toolIds(WidgetTester tester) => [
    for (final s in containerOf(
      tester,
    ).read(scheduleControllerProvider).palette)
      s.id,
  ];

  Future<void> pick(WidgetTester tester, String toolKey) async {
    final finder = find.byKey(ValueKey(toolKey));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  bool fullyVisible(WidgetTester tester, Finder target) {
    if (target.hitTestable().evaluate().isEmpty) return false;
    final viewport = tester.getRect(find.byKey(const ValueKey('month-scroll')));
    final bounds = tester.getRect(target);
    return bounds.top >= viewport.top - 0.01 &&
        bounds.bottom <= viewport.bottom + 0.01;
  }

  Future<void> scrollPaintTo(WidgetTester tester, CivilDate date) async {
    final target = cell(date);
    for (var i = 0; i < 20 && !fullyVisible(tester, target); i++) {
      await tester.tap(find.byKey(const ValueKey('paint-scroll-down')));
      await tester.pumpAndSettle();
    }
    expect(
      fullyVisible(tester, target),
      isTrue,
      reason:
          '$date is fully visible while painting; viewport: '
          '${tester.getRect(find.byKey(const ValueKey("month-scroll")))}; '
          'day: ${tester.getRect(target)}',
    );
  }

  testWidgets('320x640 text x2: painting keeps an unscaled code and start '
      'inside a row tall enough for both', (tester) async {
    // Reading the font files is real I/O: inside a widget test (fake time) it
    // has to run outside it, or it never finishes.
    expect(await tester.runAsync(loadRoboto), isTrue);
    addTearDown(() => AppTypography.debugFamily = null);
    const day = CivilDate(2026, 10, 21);
    await pumpCalendar(
      tester,
      size: const Size(320, 640),
      textScale: 2,
      prepare: (ScheduleRepository repository) => repository.apply(
        'main',
        ScheduleChange(
          patch: EntriesPatch({
            day: EntryChange(
              null,
              const DayEntry(date: day, shiftTypeIds: ['morning']),
            ),
          }),
        ),
      ),
    );
    await enterPaintMode(tester);
    final before = scheduleOf(tester);
    await scrollPaintTo(tester, day);
    expect(
      scheduleOf(tester),
      same(before),
      reason: 'the navigation controls never paint days',
    );
    final bounds = tester.getRect(cell(day));
    final code = find.descendant(of: cell(day), matching: find.text('M'));
    expect(
      renderedTextRect(tester, code).height,
      greaterThanOrEqualTo(tester.element(code).type.cellCode.fontSize!),
    );
    expect(
      bounds.height,
      greaterThanOrEqualTo(dayCellHeightWithTime(tester.element(cell(day)))),
    );
    for (final finder in [
      find.descendant(of: cell(day), matching: find.text('M')),
      find.descendant(
        of: cell(day),
        matching: find.textContaining(RegExp(r'^06(?:–14)?$')),
      ),
    ]) {
      expectUnscaledCellText(tester, finder);
      final rect = renderedTextRect(tester, finder);
      expect(bounds.contains(rect.topLeft), isTrue);
      expect(bounds.contains(rect.bottomRight), isTrue);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('915x412 text x2: all six October 2025 rows are reachable '
      'through paint navigation without modifying the schedule', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpCalendar(tester, size: const Size(915, 412), textScale: 2);
    containerOf(tester)
        .read(visibleMonthProvider.notifier)
        .goTo(const CivilDate(2025, 10, 1));
    await tester.pumpAndSettle();
    await enterPaintMode(tester);
    final before = scheduleOf(tester);
    final down = find.byKey(const ValueKey('paint-scroll-down'));
    final up = find.byKey(const ValueKey('paint-scroll-up'));
    // The two buttons say what they do: in Flutter the tooltip of a button is
    // its accessible name (the semantics tooltip, not a label).
    expect(tester.getSemantics(down).tooltip, 'Desplazar el mes hacia abajo');
    expect(tester.getSemantics(up).tooltip, 'Desplazar el mes hacia arriba');
    for (final monday in [
      const CivilDate(2025, 9, 29),
      const CivilDate(2025, 10, 6),
      const CivilDate(2025, 10, 13),
      const CivilDate(2025, 10, 20),
      const CivilDate(2025, 10, 27),
      const CivilDate(2025, 11, 3),
    ]) {
      await scrollPaintTo(tester, monday);
      for (var day = 0; day < 7; day++) {
        expect(fullyVisible(tester, cell(monday.addDays(day))), isTrue);
      }
      expect(scheduleOf(tester), same(before));
    }
    for (
      var i = 0;
      i < 20 && !fullyVisible(tester, cell(const CivilDate(2025, 10, 1)));
      i++
    ) {
      await tester.tap(up);
      await tester.pumpAndSettle();
    }
    expect(fullyVisible(tester, cell(const CivilDate(2025, 10, 1))), isTrue);
    expect(scheduleOf(tester), same(before));
    await tester.tap(cell(const CivilDate(2025, 10, 1)));
    await tester.pumpAndSettle();
    expect(idsOn(scheduleOf(tester), const CivilDate(2025, 10, 1)), 'morning');
    expect(idsOn(scheduleOf(tester), const CivilDate(2025, 9, 30)), '');
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  group('H-T02-4 and H-T02-5: the header', () {
    for (final width in widths) {
      for (final scale in scales) {
        for (final brightness in Brightness.values) {
          testWidgets(
            'at $width dp, text $scale, ${brightness.name}: the month does '
            'not move when the tool changes',
            (tester) async {
              await pumpCalendar(
                tester,
                size: sizeFor(width),
                textScale: scale,
                brightness: brightness,
              );
              await enterPaintMode(tester);
              final tools = [
                'tool-eraser',
                for (final id in toolIds(tester)) 'tool-$id',
              ];

              double gridTop() => tester.getTopLeft(find.byType(MonthGrid)).dy;
              double headerHeight() => tester
                  .getSize(find.byKey(const ValueKey('paint-title')))
                  .height;

              final top = gridTop();
              final height = headerHeight();
              for (final tool in tools) {
                await pick(tester, tool);
                expect(gridTop(), closeTo(top, 0.01), reason: 'after $tool');
                expect(
                  headerHeight(),
                  closeTo(height, 0.01),
                  reason: 'after $tool',
                );
                // PINTANDO is one line and never broken.
                final label = tester.renderObject<RenderParagraph>(
                  find.byKey(const ValueKey('paint-label')),
                );
                expect(paragraphLines(label), hasLength(1));
                expect(label.didExceedMaxLines, isFalse);
                // The title is one line; hours are not cut.
                final title = find.descendant(
                  of: find.byKey(const ValueKey('paint-title')),
                  matching: find.byType(Text),
                );
                for (final element in title.evaluate()) {
                  final text = element.widget as Text;
                  final data = text.data!;
                  final paragraph = element.renderObject as RenderParagraph;
                  expect(paragraphLines(paragraph), hasLength(1));
                  if (data.contains('–') && tool != 'tool-eraser') {
                    // Hours: whole (no ellipsis in the text that holds them).
                    expect(text.overflow, isNot(TextOverflow.ellipsis));
                  }
                }
                expect(tester.takeException(), isNull);
              }
            },
          );
        }
      }
    }

    testWidgets('the name is cut with an ellipsis, the hours stay whole', (
      tester,
    ) async {
      await pumpCalendar(tester, size: const Size(360, 900), textScale: 1.3);
      await enterPaintMode(tester);
      containerOf(tester)
          .read(scheduleControllerProvider.notifier)
          .saveShiftType(_longName);
      await tester.pumpAndSettle();
      await pick(tester, 'tool-longname');
      final texts = find.descendant(
        of: find.byKey(const ValueKey('paint-title')),
        matching: find.byType(Text),
      );
      // Name and hours are two Texts; the hours never ellipsize.
      final hours = [
        for (final e in texts.evaluate())
          if ((e.widget as Text).data!.contains('08:00–15:00'))
            e.widget as Text,
      ];
      expect(hours, isNotEmpty);
      for (final t in hours) {
        expect(t.overflow, isNot(TextOverflow.ellipsis));
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('H-T02-6 and H-T02-7: the tool names', () {
    for (final width in widths) {
      for (final scale in scales) {
        testWidgets('at $width dp, text $scale: whole words, apart', (
          tester,
        ) async {
          await pumpCalendar(tester, size: sizeFor(width), textScale: scale);
          await enterPaintMode(tester);
          containerOf(tester)
              .read(scheduleControllerProvider.notifier)
              .saveShiftType(_longName);
          await tester.pumpAndSettle();

          final keys = [
            'tool-eraser',
            for (final id in toolIds(tester)) 'tool-$id',
            'tool-edit-types',
          ];
          final rects = <Rect>[];
          for (final key in keys) {
            final label = find.descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(Text),
            );
            final paragraph = tester.renderObject<RenderParagraph>(label.last);
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: '$key is cut with an ellipsis',
            );
            expect(
              wrapsOnlyBetweenWords(paragraph),
              isTrue,
              reason: '$key breaks a word',
            );
            rects.add(tester.getRect(label.last));
          }
          // The tools wrap onto lines (no sideways scroll): the names of one
          // line are apart from each other.
          rects.sort((a, b) {
            final byRow = a.top.compareTo(b.top);
            return byRow != 0 ? byRow : a.left.compareTo(b.left);
          });
          for (var i = 1; i < rects.length; i++) {
            final sameRow = (rects[i].top - rects[i - 1].top).abs() < 40;
            if (!sameRow) continue;
            expect(
              rects[i].left - rects[i - 1].right,
              greaterThanOrEqualTo(2),
              reason: 'names $i and ${i - 1} are stuck together',
            );
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

const _longName = ShiftType(
  id: 'longname',
  name: 'Libre disposición',
  code: 'LD',
  colorValue: 0xFF30A46C,
  category: ShiftCategory.work,
  startMinute: 8 * 60,
  endMinute: 15 * 60,
);
