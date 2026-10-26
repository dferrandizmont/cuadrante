import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/settings/application/preferences_controller.dart';
import 'package:cuadrante/features/settings/data/preferences_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

/// October 2026 starts on a Thursday, so the grid begins on Monday 28 Sep or,
/// with Sunday first, on Sunday 27 Sep.
void main() {
  setUpAll(initializeLocale);

  const sep27 = CivilDate(2026, 9, 27); // Sunday
  const sep28 = CivilDate(2026, 9, 28); // Monday
  const oct18 = CivilDate(2026, 10, 18); // Sunday
  const oct19 = CivilDate(2026, 10, 19); // Monday, today
  const oct20 = CivilDate(2026, 10, 20);
  const oct21 = CivilDate(2026, 10, 21);
  const oct24 = CivilDate(2026, 10, 24); // Saturday
  const oct25 = CivilDate(2026, 10, 25); // Sunday

  Future<void> sundayStart(AppDatabase db) =>
      PreferencesRepository(db).setWeekStart(7);
  Future<void> sundayWithNumbers(AppDatabase db) async {
    await PreferencesRepository(db).setWeekStart(7);
    await PreferencesRepository(db).setWeekNumbers(true);
  }

  Future<void> mondayWithNumbers(AppDatabase db) =>
      PreferencesRepository(db).setWeekNumbers(true);

  /// Weekdays of the header row, left to right.
  List<int> headerOrder(WidgetTester tester) {
    final found = <MapEntry<double, int>>[];
    for (var weekday = 1; weekday <= 7; weekday++) {
      final finder = find.byKey(ValueKey('weekday-$weekday'));
      expect(finder, findsOneWidget);
      found.add(MapEntry(tester.getCenter(finder).dx, weekday));
    }
    found.sort((a, b) => a.key.compareTo(b.key));
    return [for (final e in found) e.value];
  }

  /// Weekdays of the first row of the grid, left to right.
  List<int> firstRowOrder(WidgetTester tester, CivilDate start) {
    final days = [for (var i = 0; i < 7; i++) start.addDays(i)];
    days.sort(
      (a, b) => tester
          .getCenter(dayCell(a))
          .dx
          .compareTo(tester.getCenter(dayCell(b)).dx),
    );
    return [for (final d in days) d.weekday];
  }

  Future<void> paint(WidgetTester tester, String shiftId) async {
    await tester.tap(find.text('Pintar'));
    await tester.pumpAndSettle();
    // The tools wrap and the area scrolls: bring the one wanted into view.
    await tester.ensureVisible(find.byKey(ValueKey('tool-$shiftId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('tool-$shiftId')));
    await tester.pumpAndSettle();
  }

  /// Drags one finger through the centre of each cell.
  Future<void> dragAcross(WidgetTester tester, List<CivilDate> days) async {
    final points = [for (final d in days) tester.getCenter(dayCell(d))];
    final gesture = await tester.startGesture(points.first);
    await tester.pump();
    for (var i = 1; i < points.length; i++) {
      for (var s = 1; s <= 6; s++) {
        await gesture.moveTo(Offset.lerp(points[i - 1], points[i], s / 6)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  String ids(AppUnderTest app, CivilDate d) =>
      app.schedule.schedule.resolve(d).shiftIds.join('+');

  group('Monday first (the default)', () {
    testWidgets('header L..D and the grid starts on Monday 28 Sep', (
      tester,
    ) async {
      await AppUnderTest.pump(tester);
      expect(headerOrder(tester), [1, 2, 3, 4, 5, 6, 7]);
      expect(firstRowOrder(tester, sep28), [1, 2, 3, 4, 5, 6, 7]);
      expect(tester.getTopLeft(dayCell(sep28)).dx, lessThan(20));
      expect(find.byKey(const ValueKey('week-2026-09-28')), findsNothing);
    });
  });

  group('Sunday first', () {
    testWidgets('header D..S and the grid starts on Sunday 27 Sep', (
      tester,
    ) async {
      await AppUnderTest.pump(tester, prepare: sundayStart);
      expect(headerOrder(tester), [7, 1, 2, 3, 4, 5, 6]);
      expect(firstRowOrder(tester, sep27), [7, 1, 2, 3, 4, 5, 6]);
      // Sunday 18 Oct is the first column, Monday 19 the second.
      expect(
        tester.getCenter(dayCell(oct18)).dx,
        lessThan(tester.getCenter(dayCell(oct19)).dx),
      );
      expect(
        tester.getCenter(dayCell(oct18)).dx,
        tester.getCenter(dayCell(oct25)).dx,
      );
      // The header letter of each column is the weekday of its cells.
      expect(
        tester.getCenter(find.byKey(const ValueKey('weekday-7'))).dx,
        closeTo(tester.getCenter(dayCell(oct18)).dx, 4),
      );
      // Today keeps its content: Noche on Monday 19 Oct.
      expect(inDayCell(oct19, find.text('N')), findsOneWidget);
    });

    testWidgets('a tap in paint mode paints the date under the finger', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, prepare: sundayStart);
      await paint(tester, 'afternoon');
      final before = ids(app, oct19);

      await tester.tap(dayCell(oct18)); // first column
      await tester.pumpAndSettle();
      expect(ids(app, oct18), 'afternoon');
      expect(inDayCell(oct18, find.text('T')), findsOneWidget);
      // Neither neighbour moved.
      expect(ids(app, oct19), before);
      expect(
        app.schedule.schedule.entries.containsKey(
          const CivilDate(2026, 10, 17),
        ),
        isFalse,
      );

      await tester.tap(dayCell(oct24)); // last column
      await tester.pumpAndSettle();
      expect(ids(app, oct24), 'afternoon');
      expect(
        app.schedule.schedule.entries.containsKey(oct25),
        isFalse,
        reason: 'Saturday is the last column, not Sunday',
      );
    });

    testWidgets('a drag paints exactly the days it crosses', (tester) async {
      final app = await AppUnderTest.pump(tester, prepare: sundayStart);
      await paint(tester, 'afternoon');

      await dragAcross(tester, [oct18, oct19, oct20, oct21]);
      for (final day in [oct18, oct19, oct20, oct21]) {
        expect(ids(app, day), 'afternoon', reason: '$day');
      }
      expect(ids(app, const CivilDate(2026, 10, 22)), isNot('afternoon'));
      expect(
        app.schedule.schedule.entries.containsKey(
          const CivilDate(2026, 10, 17),
        ),
        isFalse,
      );
      // One stroke, one undo step.
      app.container.read(scheduleControllerProvider.notifier).undo();
      await tester.pumpAndSettle();
      expect(ids(app, oct18), isNot('afternoon'));
    });

    testWidgets('a tap outside paint mode opens that day', (tester) async {
      await AppUnderTest.pump(tester, prepare: sundayStart);
      await tester.tap(dayCell(oct18));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Domingo, 18 de octubre'), findsOneWidget);
    });

    testWidgets('switching the preference re-lays the month live', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester);
      expect(headerOrder(tester).first, 1);
      await app.container.read(preferencesProvider.notifier).setWeekStart(7);
      await tester.pumpAndSettle();
      expect(headerOrder(tester).first, 7);
      expect(firstRowOrder(tester, sep27).first, 7);
      await app.container.read(preferencesProvider.notifier).setWeekStart(1);
      await tester.pumpAndSettle();
      expect(headerOrder(tester).first, 1);
    });
  });

  group('week numbers', () {
    testWidgets('Monday first: ISO numbers 40 to 45 in a narrow column', (
      tester,
    ) async {
      await AppUnderTest.pump(tester, prepare: mondayWithNumbers);
      const rows = {
        '2026-09-28': '40',
        '2026-10-05': '41',
        '2026-10-12': '42',
        '2026-10-19': '43',
        '2026-10-26': '44',
        '2026-11-02': '45',
      };
      rows.forEach((iso, number) {
        final cell = find.byKey(ValueKey('week-$iso'));
        expect(cell, findsOneWidget, reason: iso);
        expect(
          find.descendant(of: cell, matching: find.text(number)),
          findsOneWidget,
        );
        // On the row of its Monday, left of the first column.
        final monday = CivilDate.parse(iso);
        expect(
          tester.getCenter(cell).dy,
          closeTo(tester.getCenter(dayCell(monday)).dy, 0.5),
        );
        expect(
          tester.getCenter(cell).dx,
          lessThan(tester.getTopLeft(dayCell(monday)).dx),
        );
      });
      expect(
        tester.getSize(find.byKey(const ValueKey('week-2026-09-28'))).width,
        24,
      );
    });

    testWidgets('the weekday header leaves room for the column', (
      tester,
    ) async {
      final plain = await AppUnderTest.pump(tester);
      final plainX = tester
          .getCenter(find.byKey(const ValueKey('weekday-1')))
          .dx;
      final plainCellX = tester.getCenter(dayCell(sep28)).dx;
      expect(plain.schedule.calendarId, 'main');

      await plain.container
          .read(preferencesProvider.notifier)
          .setWeekNumbers(true);
      await tester.pumpAndSettle();
      final shiftedX = tester
          .getCenter(find.byKey(const ValueKey('weekday-1')))
          .dx;
      final shiftedCellX = tester.getCenter(dayCell(sep28)).dx;
      expect(shiftedX, greaterThan(plainX));
      expect(shiftedCellX, greaterThan(plainCellX));
      // Header letters stay centred over their column.
      expect(shiftedX, closeTo(shiftedCellX, 4));
    });

    testWidgets('Sunday first: each row shows the week of its Monday', (
      tester,
    ) async {
      await AppUnderTest.pump(tester, prepare: sundayWithNumbers);
      const rows = {
        '2026-09-27': '40',
        '2026-10-04': '41',
        '2026-10-11': '42',
        '2026-10-18': '43',
        '2026-10-25': '44',
        '2026-11-01': '45',
      };
      rows.forEach((iso, number) {
        final cell = find.byKey(ValueKey('week-$iso'));
        expect(cell, findsOneWidget, reason: iso);
        expect(
          find.descendant(of: cell, matching: find.text(number)),
          findsOneWidget,
          reason: iso,
        );
      });
    });

    testWidgets('taps and drags still hit the right dates with the column', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, prepare: sundayWithNumbers);
      await paint(tester, 'afternoon');

      await tester.tap(dayCell(oct18));
      await tester.pumpAndSettle();
      expect(ids(app, oct18), 'afternoon');
      expect(
        app.schedule.schedule.entries.containsKey(
          const CivilDate(2026, 10, 17),
        ),
        isFalse,
      );

      await dragAcross(tester, [oct19, oct20, oct21]);
      for (final day in [oct19, oct20, oct21]) {
        expect(ids(app, day), 'afternoon', reason: '$day');
      }
      expect(ids(app, const CivilDate(2026, 10, 22)), isNot('afternoon'));
    });

    testWidgets('the column itself paints nothing', (tester) async {
      final app = await AppUnderTest.pump(tester, prepare: sundayWithNumbers);
      await paint(tester, 'afternoon');
      final before = app.schedule.schedule.entries;

      await tester.tap(find.byKey(const ValueKey('week-2026-10-18')));
      await tester.pumpAndSettle();
      expect(app.schedule.schedule.entries, before);

      // A drag that starts on the numbers and ends on Sunday 18 paints that
      // day and nothing else.
      final gutter = tester.getCenter(
        find.byKey(const ValueKey('week-2026-10-18')),
      );
      final target = tester.getCenter(dayCell(oct18));
      final gesture = await tester.startGesture(gutter);
      await tester.pump();
      for (var s = 1; s <= 6; s++) {
        await gesture.moveTo(Offset.lerp(gutter, target, s / 6)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(ids(app, oct18), 'afternoon');
      expect(
        app.schedule.schedule.entries.keys.where(
          (d) =>
              app.schedule.schedule.entries[d]?.shiftTypeIds?.join() ==
              'afternoon',
        ),
        [oct18],
      );
    });

    testWidgets('a very narrow window (split screen) still lays out the grid '
        'and maps taps to cells', (tester) async {
      // 230 dp wide: the cells (about 29 dp) are narrower than the 52 dp
      // minimum row height divided by the aspect limit.
      final app = await AppUnderTest.pump(
        tester,
        size: const Size(230, 600),
        prepare: mondayWithNumbers,
      );
      expect(tester.takeException(), isNull);
      // The header of the month (the card of today, the tip and the title
      // with its buttons) takes most of a window this narrow: the grid is
      // below it and the screen scrolls to it.
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('week-2026-10-19')), findsOneWidget);

      await paint(tester, 'afternoon');
      // A day in the upper rows: the paint bar covers the lowest ones here.
      const oct5 = CivilDate(2026, 10, 5);
      const oct6 = CivilDate(2026, 10, 6);
      const oct7 = CivilDate(2026, 10, 7);
      await tester.ensureVisible(dayCell(oct6));
      await tester.pumpAndSettle();
      await tester.tap(dayCell(oct6));
      await tester.pumpAndSettle();
      expect(ids(app, oct6), 'afternoon');
      expect(ids(app, oct5), isNot('afternoon'));
      expect(ids(app, oct7), isNot('afternoon'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('large text keeps the column readable without errors', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await AppUnderTest.pump(tester, prepare: sundayWithNumbers);
      // The card and the date push the grid down at this text size.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('week-2026-09-27')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('week-2026-09-27')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('year view and pattern preview follow the week start', () {
    const oct4 = CivilDate(2026, 10, 4); // Sunday
    const oct5 = CivilDate(2026, 10, 5); // Monday
    const oct11 = CivilDate(2026, 10, 11); // Sunday

    double left(WidgetTester tester, String key) =>
        tester.getTopLeft(find.byKey(ValueKey(key))).dx;

    /// Whether Sunday 4 Oct sits in the first column of [prefix] cells (the
    /// same column as Sunday 11), left of Monday 5.
    void expectSundayFirst(WidgetTester tester, String prefix, bool sunday) {
      final d4 = left(tester, '$prefix-${oct4.toIso()}');
      final d5 = left(tester, '$prefix-${oct5.toIso()}');
      final d11 = left(tester, '$prefix-${oct11.toIso()}');
      expect(d4, closeTo(d11, 0.5), reason: 'two Sundays, one column');
      if (sunday) {
        expect(d4, lessThan(d5), reason: 'Sunday is the first column');
      } else {
        expect(d4, greaterThan(d5), reason: 'Sunday is the last column');
      }
    }

    Future<void> openYear(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('open-year')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(ValueKey('year-day-${oct4.toIso()}')),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openPreview(WidgetTester tester) async {
      await tester.tap(find.text('Pintar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('paint-pattern')));
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('pattern-card-5x2'));
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();
      final next = find.byKey(const ValueKey('pattern-next'));
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('preview-${oct4.toIso()}')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('year view: Monday first by default', (tester) async {
      await AppUnderTest.pump(tester);
      await openYear(tester);
      expectSundayFirst(tester, 'year-day', false);
    });

    testWidgets('year view: Sunday first moves the squares', (tester) async {
      await AppUnderTest.pump(tester, prepare: sundayStart);
      await openYear(tester);
      expectSundayFirst(tester, 'year-day', true);
    });

    testWidgets('pattern preview: Monday first by default', (tester) async {
      await AppUnderTest.pump(tester);
      await openPreview(tester);
      expectSundayFirst(tester, 'preview', false);
    });

    testWidgets('pattern preview: Sunday first moves the cells', (
      tester,
    ) async {
      await AppUnderTest.pump(tester, prepare: sundayStart);
      await openPreview(tester);
      expectSundayFirst(tester, 'preview', true);
    });
  });
}
