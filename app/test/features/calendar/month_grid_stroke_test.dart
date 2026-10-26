import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/application/visible_month.dart';
import 'package:cuadrante/features/calendar/presentation/day_cell.dart';
import 'package:cuadrante/features/calendar/presentation/month_grid.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';
import 'harness.dart';
import 'rendered_cell_text.dart';

const _monday = CivilDate(2026, 10, 5);

Set<CivilDate> _changedDates(Schedule before, Schedule after) => {
  for (final date in {...before.entries.keys, ...after.entries.keys})
    if (before.entries[date] != after.entries[date]) date,
};

void main() {
  setUpAll(initializeLocale);
  _transitionTests();

  for (final size in [const Size(320, 844), const Size(1280, 1000)]) {
    for (final (name, tool) in [
      ('erase', const PaintTool.erase()),
      ('replace', const PaintTool.replace('afternoon')),
      ('double', const PaintTool.add('night')),
    ]) {
      for (final cancel in [false, true]) {
        testWidgets('$size $name cancel=$cancel: physical stroke keeps its '
            'rows, exact dates and one reversible save', (tester) async {
          final growing = tool == const PaintTool.add('night');
          await pumpCalendar(
            tester,
            size: size,
            prepare: (repository) async {
              final snapshot = await repository.load('main');
              await repository.apply(
                snapshot.calendarId,
                ScheduleChange(
                  patch: EntriesPatch({
                    for (var i = 0; i < 14; i++)
                      _monday.addDays(i): EntryChange(
                        snapshot.schedule.entries[_monday.addDays(i)],
                        DayEntry(
                          date: _monday.addDays(i),
                          shiftTypeIds: i == 0
                              ? growing
                                    ? ['morning', 'afternoon']
                                    : ['morning', 'afternoon', 'night']
                              : ['morning'],
                          note: 'Preservar nota $i',
                          overtimeMinutes: i + 1,
                        ),
                      ),
                  }),
                ),
              );
            },
          );
          await enterPaintMode(tester);
          final paint = paintOf(tester);
          if (growing) {
            paint.selectShift('night');
            paint.toggleDoubling();
          } else if (tool == const PaintTool.erase()) {
            paint.selectEraser();
          } else {
            paint.selectShift('afternoon');
          }
          await revealCell(tester, _monday);
          final container = containerOf(tester);
          final controller = container.read(
            scheduleControllerProvider.notifier,
          );
          final before = scheduleOf(tester);
          final expectedDays = {
            _monday,
            _monday.addDays(1),
            _monday.addDays(2),
            if (growing) ...{
              _monday.addDays(7),
              _monday.addDays(8),
              _monday.addDays(9),
            },
          };
          final expected = before.apply(
            ScheduleChange(patch: before.paint(tool, expectedDays)),
          );
          final rects = {
            for (var i = 0; i < 42; i++)
              CivilDate(2026, 9, 28).addDays(i): tester.getRect(
                cell(CivilDate(2026, 9, 28).addDays(i)),
              ),
          };
          final first = rects[_monday]!;
          // The bottom of the tall week falls inside the following week if
          // erasing/replacing its only triple-shift day shrinks it mid-drag.
          final y = first.bottom - 3;
          final start = Offset(first.center.dx, y);
          final gesture = await tester.startGesture(start);
          await gesture.moveBy(Offset(first.width * .45, 0));
          await tester.pump();
          expect(controller.strokeActive, isTrue);
          expect(_changedDates(before, scheduleOf(tester)), {_monday});
          expect(container.read(scheduleControllerProvider).canUndo, isFalse);

          void expectStableRows() {
            for (final entry in rects.entries) {
              expect(
                tester.getRect(cell(entry.key)),
                entry.value,
                reason: '${entry.key} must not move under the finger',
              );
            }
          }

          expectStableRows();
          for (var i = 1; i <= 2; i++) {
            await gesture.moveTo(
              Offset(rects[_monday.addDays(i)]!.center.dx, y),
            );
            await tester.pump();
            expectStableRows();
            expect(_changedDates(before, scheduleOf(tester)), {
              for (var d = 0; d <= i; d++) _monday.addDays(d),
            });
          }
          if (growing) {
            // A growing week must not swallow coordinates that belonged to
            // the next one. Return to Monday, cross straight down, then
            // continue horizontally using only the pre-stroke positions.
            await gesture.moveTo(start);
            await tester.pump();
            final nextY = rects[_monday.addDays(7)]!.top + 3;
            await gesture.moveTo(Offset(start.dx, nextY));
            await tester.pump();
            expect(_changedDates(before, scheduleOf(tester)), {
              _monday,
              _monday.addDays(1),
              _monday.addDays(2),
              _monday.addDays(7),
            });
            expectStableRows();
            await gesture.moveTo(
              Offset(rects[_monday.addDays(9)]!.center.dx, nextY),
            );
            await tester.pump();
            expect(_changedDates(before, scheduleOf(tester)), expectedDays);
            expectStableRows();
          }
          expectSameSchedule(scheduleOf(tester), expected);
          void expectShiftTimes({required bool unscaled}) {
            for (final date in expectedDays) {
              final context = tester.element(cell(date));
              final dayBounds = tester.getRect(cell(date));
              for (final shift in expected.resolve(date).shifts) {
                final time = cellTimeInCell(
                  shift: shift,
                  style: context.type.cellTime,
                  scaler: MediaQuery.textScalerOf(context),
                  width: dayBounds.width - Sp.cellGap,
                );
                expect(time, isNotNull);
                final text = find.descendant(
                  of: cell(date),
                  matching: find.text(time!.text),
                );
                expect(text, findsOneWidget);
                final bounds = renderedTextRect(tester, text);
                expect(dayBounds.contains(bounds.topLeft), isTrue);
                expect(dayBounds.contains(bounds.bottomRight), isTrue);
                if (unscaled) expectUnscaledCellText(tester, text);
              }
            }
          }

          expectShiftTimes(unscaled: false);
          // No intermediate preview is written to storage.
          final repository = container.read(scheduleRepositoryProvider);
          final storedBefore = (await tester.runAsync(
            () => repository.load(
              container.read(scheduleControllerProvider).calendarId,
            ),
          ))!;
          expectSameSchedule(storedBefore.schedule, before);
          if (cancel) {
            await gesture.cancel();
          } else {
            await gesture.up();
          }
          await tester.pumpAndSettle();
          expect(controller.strokeActive, isFalse);
          expectSameSchedule(scheduleOf(tester), expected);
          final afterHeight = tester.getSize(cell(_monday)).height;
          expect(
            afterHeight,
            growing ? greaterThan(first.height) : lessThan(first.height),
          );
          expect(tester.takeException(), isNull);
          expectShiftTimes(unscaled: true);

          Future<void> expectStored(Schedule expected) async {
            await tester.runAsync(() => controller.pendingWrites);
            final stored = (await tester.runAsync(
              () => repository.load(
                container.read(scheduleControllerProvider).calendarId,
              ),
            ))!;
            expectSameSchedule(stored.schedule, expected);
          }

          await expectStored(expected);
          expect(controller.undo(), isTrue);
          await tester.pumpAndSettle();
          expectSameSchedule(scheduleOf(tester), before);
          expect(
            controller.undo(),
            isFalse,
            reason: 'the whole stroke is one step',
          );
          await expectStored(before);
          expect(controller.redo(), isTrue);
          await tester.pumpAndSettle();
          expectSameSchedule(scheduleOf(tester), expected);
          expect(controller.redo(), isFalse);
          await expectStored(expected);
          expect(find.byType(MonthGrid), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}

void _transitionTests() {
  const narrow = Size(320, 844);
  const wide = Size(1280, 1000);
  for (final changeMonth in [true, false]) {
    for (final startsWide in [false, true]) {
      for (final growing in [false, true]) {
        testWidgets(
          'held finger: ${changeMonth ? 'month arrow' : 'layout change'} '
          'wide=$startsWide growing=$growing closes and saves one stroke',
          (tester) async {
            final initialSize = startsWide ? wide : narrow;
            final targetSize = changeMonth
                ? initialSize
                : startsWide
                ? narrow
                : wide;
            await pumpCalendar(
              tester,
              size: initialSize,
              prepare: (repository) async {
                final snapshot = await repository.load('main');
                await repository.apply(
                  snapshot.calendarId,
                  ScheduleChange(
                    patch: EntriesPatch({
                      for (var i = 0; i < 2; i++)
                        _monday.addDays(i): EntryChange(
                          snapshot.schedule.entries[_monday.addDays(i)],
                          DayEntry(
                            date: _monday.addDays(i),
                            shiftTypeIds: growing
                                ? ['morning', 'afternoon']
                                : ['morning', 'afternoon', 'night'],
                            note: 'Conservar nota $i',
                            overtimeMinutes: i + 1,
                          ),
                        ),
                    }),
                  ),
                );
              },
            );
            await enterPaintMode(tester);
            final paint = paintOf(tester);
            if (growing) {
              paint.selectShift('night');
              paint.toggleDoubling();
            } else {
              paint.selectEraser();
            }
            await revealCell(tester, _monday);
            // Keep both the first painted week and the month arrows visible.
            tester
                .state<ScrollableState>(
                  find
                      .descendant(
                        of: find.byKey(const ValueKey('month-scroll')),
                        matching: find.byType(Scrollable),
                      )
                      .first,
                )
                .position
                .jumpTo(0);
            await tester.pumpAndSettle();
            final container = containerOf(tester);
            final controller = container.read(
              scheduleControllerProvider.notifier,
            );
            final repository = container.read(scheduleRepositoryProvider);
            final calendarId = container
                .read(scheduleControllerProvider)
                .calendarId;
            final before = scheduleOf(tester);
            final dates = {_monday, _monday.addDays(1)};
            final tool = growing
                ? const PaintTool.add('night')
                : const PaintTool.erase();
            final expected = before.apply(
              ScheduleChange(patch: before.paint(tool, dates)),
            );
            final first = tester.getRect(cell(_monday));
            final second = tester.getCenter(cell(_monday.addDays(1)));
            final finger = await tester.startGesture(first.center, pointer: 1);
            await finger.moveTo(second);
            await tester.pump();
            expect(controller.strokeActive, isTrue);
            expect(_changedDates(before, scheduleOf(tester)), dates);
            expectSameSchedule(scheduleOf(tester), expected);
            expect(container.read(scheduleControllerProvider).canUndo, isFalse);
            final storedBefore = (await tester.runAsync(
              () => repository.load(calendarId),
            ))!;
            expectSameSchedule(storedBefore.schedule, before);

            if (changeMonth) {
              // A real second pointer taps the arrow while pointer 1 stays down.
              await tester.tap(
                find.byTooltip(startsWide ? 'Mes anterior' : 'Mes siguiente'),
                pointer: 2,
              );
            } else {
              tester.view.physicalSize = targetSize * 3;
            }
            await tester.pumpAndSettle();
            expect(controller.strokeActive, isFalse);
            expect(
              container.read(scheduleControllerProvider).strokeDays,
              isEmpty,
            );
            expect(container.read(scheduleControllerProvider).canUndo, isTrue);
            expectSameSchedule(scheduleOf(tester), expected);
            expect(
              find.byKey(const ValueKey('pane-divider')),
              (targetSize == wide) ? findsOneWidget : findsNothing,
            );
            final month = container.read(visibleMonthProvider);
            expect(
              month,
              changeMonth
                  ? CivilDate(2026, startsWide ? 9 : 11, 1)
                  : const CivilDate(2026, 10, 1),
            );

            Future<void> expectStored(Schedule value) async {
              await tester.runAsync(() => controller.pendingWrites);
              final stored = (await tester.runAsync(
                () => repository.load(calendarId),
              ))!;
              expectSameSchedule(stored.schedule, value);
            }

            await expectStored(expected);
            // Exercise the old gesture over real cells of the new grid.
            final target = changeMonth ? month.addDays(4) : _monday.addDays(7);
            await finger.moveTo(tester.getCenter(cell(target)));
            await tester.pump();
            await finger.moveBy(const Offset(30, 10));
            await tester.pump();
            expectSameSchedule(scheduleOf(tester), expected);
            expect(controller.strokeActive, isFalse);
            _expectRecalculatedHeights(tester);

            // History already works with the original finger still down.
            expect(controller.undo(), isTrue);
            await tester.pumpAndSettle();
            expectSameSchedule(scheduleOf(tester), before);
            expect(controller.undo(), isFalse, reason: 'exactly one undo step');
            await expectStored(before);
            expect(controller.redo(), isTrue);
            await tester.pumpAndSettle();
            expectSameSchedule(scheduleOf(tester), expected);
            expect(controller.redo(), isFalse);
            await expectStored(expected);
            await finger.up();
            await tester.pumpAndSettle();
            expect(controller.strokeActive, isFalse);
            expectSameSchedule(scheduleOf(tester), expected);
            await expectStored(expected);
            expect(controller.undo(), isTrue);
            await tester.pumpAndSettle();
            expectSameSchedule(scheduleOf(tester), before);
            expect(controller.undo(), isFalse, reason: 'up adds no extra step');
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}

void _expectRecalculatedHeights(WidgetTester tester) {
  final gridFinder = find.byType(MonthGrid);
  final grid = tester.widget<MonthGrid>(gridFinder);
  final context = tester.element(gridFinder);
  final days = tester.widgetList<DayCell>(find.byType(DayCell)).toList();
  expect(days, hasLength(42));
  final minima = monthGridMinimumRowHeights(
    context,
    days.map((cell) => cell.day).toList(),
    minCellHeight: grid.minCellHeight,
  );
  final scrollFinder = find.byKey(const ValueKey('month-scroll'));
  final scroll = tester.widget<CustomScrollView>(scrollFinder);
  final header = tester.renderObject<RenderSliver>(
    find.byWidget(scroll.slivers.first),
  );
  final viewport = tester
      .state<ScrollableState>(
        find
            .descendant(of: scrollFinder, matching: find.byType(Scrollable))
            .first,
      )
      .position
      .viewportDimension;
  final minimum = minima.reduce((a, b) => a + b);
  final remaining = viewport - header.geometry!.scrollExtent;
  final height = minimum > remaining ? minimum : remaining;
  expect(
    tester.getSize(gridFinder).height,
    closeTo(height, .001),
    reason: 'outer minimum must use the new layout and committed shifts',
  );
  final width = tester.getSize(gridFinder).width / 7;
  final extra = height > minimum ? (height - minimum) / 6 : 0.0;
  for (var row = 0; row < 6; row++) {
    final cap = width * 1.5 - minima[row];
    final growth = cap <= 0
        ? 0.0
        : extra < cap
        ? extra
        : cap;
    expect(
      tester.getSize(find.byWidget(days[row * 7])).height,
      closeTo(minima[row] + growth, .001),
      reason: 'row $row must release the old stroke geometry',
    );
  }
}
