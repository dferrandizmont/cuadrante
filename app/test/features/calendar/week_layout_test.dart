import 'package:cuadrante/features/calendar/application/week_layout.dart';
import 'package:cuadrante/features/schedule/domain/civil_date.dart';
import 'package:cuadrante/features/calendar/presentation/grid_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('monthGridStart', () {
    test('Monday first: the Monday on or before the 1st', () {
      // 1 Oct 2026 is a Thursday.
      expect(
        monthGridStart(const CivilDate(2026, 10, 1), 1),
        const CivilDate(2026, 9, 28),
      );
      // 1 Jun 2026 is a Monday: the grid starts on it.
      expect(
        monthGridStart(const CivilDate(2026, 6, 1), 1),
        const CivilDate(2026, 6, 1),
      );
    });

    test('Sunday first: the Sunday on or before the 1st', () {
      expect(
        monthGridStart(const CivilDate(2026, 10, 1), 7),
        const CivilDate(2026, 9, 27),
      );
      // 1 Feb 2026 is a Sunday.
      expect(
        monthGridStart(const CivilDate(2026, 2, 1), 7),
        const CivilDate(2026, 2, 1),
      );
      // 1 Jun 2026 is a Monday: the Sunday before.
      expect(
        monthGridStart(const CivilDate(2026, 6, 1), 7),
        const CivilDate(2026, 5, 31),
      );
    });

    test('always starts on the chosen weekday and covers the month', () {
      for (final weekStart in [1, 7]) {
        for (var month = 1; month <= 12; month++) {
          final first = CivilDate(2026, month, 1);
          final start = monthGridStart(first, weekStart);
          expect(start.weekday, weekStart, reason: '$first / $weekStart');
          expect(start.differenceInDays(first), lessThanOrEqualTo(0));
          expect(first.differenceInDays(start), lessThan(7));
          // 6 rows always reach past the end of the month.
          final last = start.addDays(41);
          expect(
            last.isBefore(first.lastDayOfMonth),
            isFalse,
            reason: '$first / $weekStart',
          );
        }
      }
    });
  });

  test('weekdayOrder follows the first day', () {
    expect(weekdayOrder(1), [1, 2, 3, 4, 5, 6, 7]);
    expect(weekdayOrder(7), [7, 1, 2, 3, 4, 5, 6]);
  });

  group('isoWeekNumber', () {
    final cases = <CivilDate, int>{
      const CivilDate(2026, 1, 1): 1, // Thursday
      const CivilDate(2025, 12, 29): 1, // Monday of week 1 of 2026
      const CivilDate(2026, 10, 19): 43,
      const CivilDate(2026, 10, 25): 43, // Sunday
      const CivilDate(2026, 10, 26): 44,
      const CivilDate(2021, 1, 3): 53, // Sunday of 2020's week 53
      const CivilDate(2021, 1, 4): 1,
      const CivilDate(2020, 12, 31): 53,
      const CivilDate(2024, 12, 30): 1, // belongs to 2025
      const CivilDate(2026, 12, 31): 53, // 2026 has 53 weeks
      const CivilDate(2027, 1, 3): 53,
      const CivilDate(2027, 1, 4): 1,
      const CivilDate(2024, 2, 29): 9,
    };
    cases.forEach((date, week) {
      test('$date is week $week', () => expect(isoWeekNumber(date), week));
    });
  });

  group('rowWeekNumber', () {
    test('a Monday-first row is the ISO week of the row', () {
      expect(rowWeekNumber(const CivilDate(2026, 10, 19)), 43);
      expect(rowWeekNumber(const CivilDate(2026, 9, 28)), 40);
      expect(rowWeekNumber(const CivilDate(2025, 12, 29)), 1);
    });

    test('a Sunday-first row shows the week of its Monday to Saturday', () {
      // Sunday 18 Oct - Saturday 24 Oct: Monday 19 is in week 43.
      expect(rowWeekNumber(const CivilDate(2026, 10, 18)), 43);
      // Sunday 27 Sep - Saturday 3 Oct: 28 Sep is week 40.
      expect(rowWeekNumber(const CivilDate(2026, 9, 27)), 40);
      // Sunday 28 Dec 2025 - Saturday 3 Jan 2026: the new year's week 1.
      expect(rowWeekNumber(const CivilDate(2025, 12, 28)), 1);
    });

    test('the six rows of a month count up', () {
      for (final weekStart in [1, 7]) {
        final start = monthGridStart(const CivilDate(2026, 10, 1), weekStart);
        final numbers = [
          for (var r = 0; r < 6; r++) rowWeekNumber(start.addDays(r * 7)),
        ];
        expect(numbers, [40, 41, 42, 43, 44, 45], reason: 'start $weekStart');
      }
    });
  });

  group('GridGeometry with a gutter for the week numbers', () {
    // 24 dp of gutter, then 7 x 6 cells of 50 x 100.
    const g = GridGeometry(width: 374, height: 600, gutter: 24);

    test('cells are measured after the gutter', () {
      expect(g.cellWidth, 50);
      expect(g.cellAt(const Offset(24, 0)), 0);
      expect(g.cellAt(const Offset(73.9, 99.9)), 0);
      expect(g.cellAt(const Offset(74, 0)), 1);
      expect(g.cellAt(const Offset(373.9, 0)), 6);
      expect(g.cellAt(const Offset(373.9, 599.9)), 41);
      expect(g.cellAt(const Offset(24, 100)), 7);
    });

    test('the gutter and the outside hit nothing', () {
      expect(g.cellAt(const Offset(0, 10)), isNull);
      expect(g.cellAt(const Offset(23.9, 10)), isNull);
      expect(g.cellAt(const Offset(374, 10)), isNull);
      expect(g.cellAt(const Offset(100, 600)), isNull);
    });

    test('a drag from the gutter into the grid starts at the first cell', () {
      expect(g.cellsAlong(const Offset(5, 50), const Offset(120, 50)), [0, 1]);
    });

    test('no gutter behaves as before', () {
      const plain = GridGeometry(width: 350, height: 600);
      expect(plain.gutter, 0);
      expect(plain.cellAt(const Offset(0, 0)), 0);
      expect(plain.cellAt(const Offset(349.9, 599.9)), 41);
    });
  });
}
