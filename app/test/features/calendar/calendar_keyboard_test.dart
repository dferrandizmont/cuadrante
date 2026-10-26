import 'dart:ui' show SemanticsAction, Tristate;

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/features/calendar/application/open_day.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/application/selection_controller.dart';
import 'package:cuadrante/features/calendar/application/visible_month.dart';
import 'package:cuadrante/features/calendar/presentation/day_cell.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  setUpAll(initializeLocale);
  const first = CivilDate(2026, 9, 28);
  const day = CivilDate(2026, 10, 19);

  Future<void> open(WidgetTester tester) =>
      pumpCalendar(tester, size: const Size(1280, 1000));
  Future<void> focus(WidgetTester tester, CivilDate date) async {
    tester.widget<DayCell>(cell(date)).focusNode!.requestFocus();
    await tester.pumpAndSettle();
  }

  Future<void> key(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
  }

  void expectFocus(WidgetTester tester, CivilDate date) {
    expect(tester.widget<DayCell>(cell(date)).focusNode!.hasFocus, isTrue);
    final mark = find.byKey(ValueKey('keyboard-focus-${date.toIso()}'));
    expect(mark, findsOneWidget);
    final decoration =
        tester.widget<DecoratedBox>(mark).decoration as BoxDecoration;
    expect(decoration.borderRadius, Rad.cellRadius);
    expect(
      decoration.border!.top.color,
      tester.element(cell(date)).colors.accent,
    );
  }

  for (final navigation in ['button', 'swipe']) {
    for (final painting in [false, true]) {
      // Paint mode turns the horizontal drag into a paint stroke.
      if (navigation == 'swipe' && painting) continue;
      testWidgets(
        '$navigation month change preserves visible and semantic focus; '
        'Enter ${painting ? 'paints' : 'opens'} the new date',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await open(tester);
            if (painting) {
              await enterPaintMode(tester);
              paintOf(tester).selectShift('morning');
            }
            // Row four, Monday: the same node represents 16 November next month.
            await focus(tester, day);
            final node = tester.widget<DayCell>(cell(day)).focusNode!;
            if (navigation == 'button') {
              await tester.tap(find.byTooltip('Mes siguiente'));
            } else {
              await tester.fling(cell(day), const Offset(-300, 0), 1000);
            }
            await tester.pumpAndSettle();
            const nextDate = CivilDate(2026, 11, 16);
            expect(
              containerOf(tester).read(visibleMonthProvider),
              const CivilDate(2026, 11, 1),
            );
            expect(
              tester.widget<DayCell>(cell(nextDate)).focusNode,
              same(node),
            );
            expect(node.hasPrimaryFocus, isTrue);
            expectFocus(tester, nextDate);
            expect(
              tester
                  .getSemantics(cell(nextDate))
                  .getSemanticsData()
                  .flagsCollection
                  .isFocused,
              Tristate.isTrue,
            );
            final oldShifts = scheduleOf(tester).resolve(day).shiftIds;
            await key(tester, LogicalKeyboardKey.enter);
            if (painting) {
              expect(idsOn(scheduleOf(tester), nextDate), 'morning');
              expect(scheduleOf(tester).resolve(day).shiftIds, oldShifts);
              expect(containerOf(tester).read(openDayProvider), isNull);
            } else {
              expect(containerOf(tester).read(openDayProvider), nextDate);
            }
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  testWidgets(
    'keyboard leaves the grid, changes month and returns to new days',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await open(tester);
        await focus(tester, first);
        // Arrows stop at the edges; Shift-Tab reaches the previous control.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await key(tester, LogicalKeyboardKey.tab);
        expect(
          tester.widget<DayCell>(cell(first)).focusNode!.hasFocus,
          isFalse,
        );
        bool nextButtonFocused() => Focus.of(
          tester.element(
            find.descendant(
              of: find.byTooltip('Mes siguiente'),
              matching: find.byType(Icon),
            ),
          ),
        ).hasFocus;
        for (var i = 0; i < 20 && !nextButtonFocused(); i++) {
          await key(tester, LogicalKeyboardKey.tab);
        }
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        expect(nextButtonFocused(), isTrue);
        await key(tester, LogicalKeyboardKey.enter);
        expect(
          containerOf(tester).read(visibleMonthProvider),
          const CivilDate(2026, 11, 1),
        );
        const nextFirst = CivilDate(2026, 10, 26);
        for (
          var i = 0;
          i < 20 &&
              !tester.widget<DayCell>(cell(nextFirst)).focusNode!.hasFocus;
          i++
        ) {
          await key(tester, LogicalKeyboardKey.tab);
        }
        expectFocus(tester, nextFirst);
        expect(
          tester
              .getSemantics(cell(nextFirst))
              .getSemanticsData()
              .flagsCollection
              .isFocused,
          Tristate.isTrue,
        );
        await key(tester, LogicalKeyboardKey.arrowDown);
        const nextDay = CivilDate(2026, 11, 2);
        expectFocus(tester, nextDay);
        await key(tester, LogicalKeyboardKey.enter);
        expect(containerOf(tester).read(openDayProvider), nextDay);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('Tab visits all 42 days chronologically and Shift-Tab reverses', (
    tester,
  ) async {
    await open(tester);
    await focus(tester, first);
    for (var i = 0; i < 42; i++) {
      expectFocus(tester, first.addDays(i));
      if (i < 41) await key(tester, LogicalKeyboardKey.tab);
    }
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await key(tester, LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expectFocus(tester, first.addDays(40));
    await key(tester, LogicalKeyboardKey.tab);
    await key(tester, LogicalKeyboardKey.tab);
    expect(
      tester.widget<DayCell>(cell(first.addDays(41))).focusNode!.hasFocus,
      isFalse,
      reason: 'Tab leaves the grid; it does not trap focus',
    );
  });

  testWidgets(
    'arrows move by day/week, cross row boundaries and stop at edges',
    (tester) async {
      await open(tester);
      await focus(tester, first);
      await key(tester, LogicalKeyboardKey.arrowLeft);
      await key(tester, LogicalKeyboardKey.arrowUp);
      expectFocus(tester, first);
      await focus(tester, first.addDays(6));
      await key(tester, LogicalKeyboardKey.arrowRight);
      expectFocus(tester, first.addDays(7));
      await key(tester, LogicalKeyboardKey.arrowDown);
      expectFocus(tester, first.addDays(14));
      await key(tester, LogicalKeyboardKey.arrowLeft);
      expectFocus(tester, first.addDays(13));
      await key(tester, LogicalKeyboardKey.arrowUp);
      expectFocus(tester, first.addDays(6));
      await focus(tester, first.addDays(41));
      await key(tester, LogicalKeyboardKey.arrowRight);
      await key(tester, LogicalKeyboardKey.arrowDown);
      expectFocus(tester, first.addDays(41));
      expect(containerOf(tester).read(openDayProvider), isNull);
    },
  );

  for (final activation in [
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.space,
  ]) {
    testWidgets('${activation.keyLabel} opens the focused day', (tester) async {
      await open(tester);
      await focus(tester, day);
      await key(tester, activation);
      expect(containerOf(tester).read(openDayProvider), day);
    });

    testWidgets(
      '${activation.keyLabel} paints once and does not paint grey days',
      (tester) async {
        await open(tester);
        await enterPaintMode(tester);
        paintOf(tester).selectShift('morning');
        await focus(tester, day);
        await key(tester, activation);
        expect(idsOn(scheduleOf(tester), day), 'morning');
        containerOf(tester).read(scheduleControllerProvider.notifier).undo();
        await tester.pumpAndSettle();
        expect(idsOn(scheduleOf(tester), day), 'night');
        final before = scheduleOf(tester).resolve(first).shiftIds;
        await focus(tester, first);
        await key(tester, activation);
        expect(scheduleOf(tester).resolve(first).shiftIds, before);
      },
    );

    testWidgets(
      '${activation.keyLabel} toggles selection without opening the day',
      (tester) async {
        await open(tester);
        final selection = containerOf(tester)
            .read(selectionControllerProvider.notifier);
        selection.begin(day);
        selection.endDrag();
        await tester.pumpAndSettle();
        await focus(tester, day.addDays(1));
        await key(tester, activation);
        expect(containerOf(tester).read(selectionControllerProvider).days, {
          day,
          day.addDays(1),
        });
        await key(tester, activation);
        expect(containerOf(tester).read(selectionControllerProvider).days, {
          day,
        });
        expect(containerOf(tester).read(openDayProvider), isNull);
      },
    );
  }

  testWidgets('arrow focus scrolls the last row into view on a short screen', (
    tester,
  ) async {
    await pumpCalendar(tester, size: const Size(915, 412));
    await focus(tester, first);
    for (var row = 0; row < 5; row++) {
      await key(tester, LogicalKeyboardKey.arrowDown);
    }
    final lastRow = first.addDays(35);
    expectFocus(tester, lastRow);
    expect(cell(lastRow).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('holding activation toggles selection only once', (tester) async {
    await open(tester);
    final selection = containerOf(tester)
        .read(selectionControllerProvider.notifier);
    selection.begin(day);
    selection.endDrag();
    await tester.pumpAndSettle();
    await focus(tester, day.addDays(1));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await simulateKeyRepeatEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(selectionControllerProvider).days, {
      day,
      day.addDays(1),
    });
  });

  testWidgets('one spoken day label and the existing accessibility actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await open(tester);
      await focus(tester, day);
      final widget = tester.widget<DayCell>(cell(day));
      final label = daySemanticsLabel(
        tester.element(cell(day)),
        day: widget.day,
        holiday: widget.holiday,
        isToday: widget.isToday,
      );
      expect(find.bySemanticsLabel(label), findsOneWidget);
      final node = tester.getSemantics(cell(day));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.longPress),
        isTrue,
      );
      expect(
        node.getSemanticsData().flagsCollection.isFocused,
        Tristate.isTrue,
      );
    } finally {
      semantics.dispose();
    }
  });
}
