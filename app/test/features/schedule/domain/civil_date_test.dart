import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CivilDate', () {
    test('epochDay anchors and round-trip', () {
      expect(const CivilDate(1970, 1, 1).epochDay, 0);
      expect(const CivilDate(2026, 1, 1).epochDay, 20454);
      expect(const CivilDate(1969, 12, 31).epochDay, -1);
      for (final n in [-800, -1, 0, 1, 19000, 20454, 30000]) {
        expect(CivilDate.fromEpochDay(n).epochDay, n);
      }
    });

    test('addDays across the March DST change (Europe)', () {
      expect(
        const CivilDate(2026, 3, 28).addDays(1),
        const CivilDate(2026, 3, 29),
      );
      expect(
        const CivilDate(2026, 3, 28).addDays(3),
        const CivilDate(2026, 3, 31),
      );
      expect(
        const CivilDate(2026, 3, 31).addDays(-3),
        const CivilDate(2026, 3, 28),
      );
      expect(
        const CivilDate(
          2026,
          3,
          30,
        ).differenceInDays(const CivilDate(2026, 3, 28)),
        2,
      );
    });

    test('addDays across the October DST change (Europe)', () {
      expect(
        const CivilDate(2026, 10, 24).addDays(2),
        const CivilDate(2026, 10, 26),
      );
      expect(
        const CivilDate(2026, 10, 26).addDays(-2),
        const CivilDate(2026, 10, 24),
      );
      expect(
        const CivilDate(
          2026,
          10,
          26,
        ).differenceInDays(const CivilDate(2026, 10, 24)),
        2,
      );
    });

    test('differenceInDays is signed and covers a whole year', () {
      const a = CivilDate(2026, 1, 1);
      expect(const CivilDate(2027, 1, 1).differenceInDays(a), 365);
      expect(a.differenceInDays(const CivilDate(2027, 1, 1)), -365);
      expect(a.differenceInDays(a), 0);
      expect(
        const CivilDate(
          2024,
          3,
          1,
        ).differenceInDays(const CivilDate(2023, 3, 1)),
        366,
      );
    });

    test('addDays over every day of 2026 stays consistent', () {
      var d = const CivilDate(2026, 1, 1);
      for (var i = 0; i < 365; i++) {
        expect(d.differenceInDays(const CivilDate(2026, 1, 1)), i);
        d = d.addDays(1);
      }
      expect(d, const CivilDate(2027, 1, 1));
    });

    test('leap years', () {
      expect(const CivilDate(2024, 2, 1).daysInMonth, 29);
      expect(const CivilDate(2025, 2, 1).daysInMonth, 28);
      expect(const CivilDate(2000, 2, 1).daysInMonth, 29);
      expect(const CivilDate(2100, 2, 1).daysInMonth, 28);
      expect(
        const CivilDate(2024, 2, 28).addDays(1),
        const CivilDate(2024, 2, 29),
      );
      expect(
        const CivilDate(2024, 2, 29).addDays(1),
        const CivilDate(2024, 3, 1),
      );
      expect(
        const CivilDate(2025, 2, 28).addDays(1),
        const CivilDate(2025, 3, 1),
      );
    });

    test('daysInMonth and month boundaries', () {
      expect(const CivilDate(2026, 1, 15).daysInMonth, 31);
      expect(const CivilDate(2026, 4, 15).daysInMonth, 30);
      expect(const CivilDate(2026, 12, 15).daysInMonth, 31);
      expect(
        const CivilDate(2026, 4, 15).firstDayOfMonth,
        const CivilDate(2026, 4, 1),
      );
      expect(
        const CivilDate(2026, 4, 15).lastDayOfMonth,
        const CivilDate(2026, 4, 30),
      );
    });

    test('weekday: 1 = Monday ... 7 = Sunday', () {
      expect(const CivilDate(2026, 1, 1).weekday, DateTime.thursday);
      expect(const CivilDate(2026, 10, 19).weekday, DateTime.monday);
      expect(const CivilDate(2026, 3, 29).weekday, DateTime.sunday);
      expect(const CivilDate(2024, 2, 29).weekday, DateTime.thursday);
      expect(const CivilDate(2000, 1, 1).weekday, DateTime.saturday);
    });

    test('fromDateTime uses local fields and drops the time', () {
      expect(
        CivilDate.fromDateTime(DateTime(2026, 3, 29, 23, 59)),
        const CivilDate(2026, 3, 29),
      );
      expect(
        CivilDate.fromDateTime(DateTime.utc(2026, 10, 25, 0, 30)),
        const CivilDate(2026, 10, 25),
      );
    });

    test('toIso / parse', () {
      expect(const CivilDate(2026, 10, 19).toIso(), '2026-10-19');
      expect(const CivilDate(2026, 1, 5).toIso(), '2026-01-05');
      expect(CivilDate.parse('2026-10-19'), const CivilDate(2026, 10, 19));
      expect(CivilDate.parse('2024-02-29'), const CivilDate(2024, 2, 29));
      for (final bad in [
        '2026-02-30',
        '2026-13-01',
        '2026-1-1',
        'x',
        '',
        '2025-02-29',
      ]) {
        expect(() => CivilDate.parse(bad), throwsFormatException, reason: bad);
      }
    });

    test('equality, hashCode and ordering', () {
      expect(const CivilDate(2026, 1, 1), const CivilDate(2026, 1, 1));
      expect(
        const CivilDate(2026, 1, 1).hashCode,
        const CivilDate(2026, 1, 1).hashCode,
      );
      expect({const CivilDate(2026, 1, 1): 1}[const CivilDate(2026, 1, 1)], 1);
      final sorted = [
        const CivilDate(2026, 2, 1),
        const CivilDate(2025, 12, 31),
        const CivilDate(2026, 1, 31),
      ]..sort();
      expect(sorted, [
        const CivilDate(2025, 12, 31),
        const CivilDate(2026, 1, 31),
        const CivilDate(2026, 2, 1),
      ]);
      expect(
        const CivilDate(2026, 1, 1).isBefore(const CivilDate(2026, 1, 2)),
        isTrue,
      );
      expect(
        const CivilDate(2026, 1, 2).isAfter(const CivilDate(2026, 1, 1)),
        isTrue,
      );
    });
  });
}
