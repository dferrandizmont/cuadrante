import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/summary/domain/month_summary.dart';
import 'package:cuadrante/features/summary/domain/summary_range.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../schedule/domain/fixtures.dart';

const _h = 60;

ShiftType _shift(
  String id,
  ShiftCategory category, {
  int? start,
  int? end,
  int? rate,
}) => ShiftType(
  id: id,
  code: id.substring(0, 1).toUpperCase(),
  name: id,
  colorValue: 0xFF336699,
  category: category,
  startMinute: start,
  endMinute: end,
  hourlyRateCents: rate,
);

/// Every number of a summary, as a map: two equal maps = the same summary.
Map<String, Object?> _numbers(MonthSummary s) => {
  'month': s.month,
  'shifts': s.shiftsWorked,
  'days': s.workedDays,
  'minutes': s.workedMinutes,
  'night': s.nightMinutes,
  'rest': s.restDays,
  'absence': s.absenceDays,
  'holidayShifts': s.holidayShifts,
  'holidayMinutes': s.holidayMinutes,
  'earnings': s.earningsCents,
  'noTimes': s.shiftsWithoutTimes,
  'types': [
    for (final t in s.types)
      [
        t.type.id,
        t.days,
        t.count,
        t.paidMinutes,
        t.nightMinutes,
        t.earningsCents,
      ],
  ],
};

void main() {
  group('SummaryRange', () {
    const a = CivilDate(2026, 10, 19);

    test('counts its days, both ends included', () {
      expect(SummaryRange(a, a).days, 1);
      expect(SummaryRange(a, a.addDays(6)).days, 7);
      expect(SummaryRange.month(a).days, 31);
      expect(SummaryRange.month(a).from, const CivilDate(2026, 10, 1));
      expect(SummaryRange.month(a).to, const CivilDate(2026, 10, 31));
    });

    test('valid from 1 to 366 days', () {
      expect(SummaryRange(a, a).isValid, isTrue);
      expect(SummaryRange(a, a.addDays(365)).isValid, isTrue);
      expect(SummaryRange(a, a.addDays(366)).isValid, isFalse);
      expect(SummaryRange(a, a.addDays(-1)).isValid, isFalse);
    });

    test('previous is the same number of days right before', () {
      final range = SummaryRange(a, a.addDays(6));
      expect(range.previous, SummaryRange(a.addDays(-7), a.addDays(-1)));
      expect(range.previous.days, 7);
      expect(range.shifted(1), SummaryRange(a.addDays(7), a.addDays(13)));
      expect(range.shifted(-2), SummaryRange(a.addDays(-14), a.addDays(-8)));
    });

    test('a new first day after the end makes a single day', () {
      final range = SummaryRange(a, a.addDays(6));
      final result = range.withFrom(a.addDays(10));
      expect(result.range, SummaryRange(a.addDays(10), a.addDays(10)));
      expect(result.clamped, isFalse);
    });

    test('a new last day before the start makes a single day', () {
      final range = SummaryRange(a, a.addDays(6));
      final result = range.withTo(a.addDays(-3));
      expect(result.range, SummaryRange(a.addDays(-3), a.addDays(-3)));
    });

    test('more than 366 days is cut at the limit and says so', () {
      final range = SummaryRange(a, a.addDays(6));
      final far = range.withTo(a.addDays(1000));
      expect(far.range, SummaryRange(a, a.addDays(365)));
      expect(far.range.days, maxSummaryRangeDays);
      expect(far.clamped, isTrue);
      // An earlier start that leaves the end too far also cuts the end.
      final earlier = range.withFrom(a.addDays(-400));
      expect(earlier.range.from, a.addDays(-400));
      expect(earlier.range.days, maxSummaryRangeDays);
      expect(earlier.clamped, isTrue);
      // Exactly 366 days is fine.
      final exact = range.withTo(a.addDays(365));
      expect(exact.range.days, 366);
      expect(exact.clamped, isFalse);
    });

    test('equal ranges are equal keys', () {
      expect(SummaryRange(a, a), SummaryRange(a, a));
      expect(SummaryRange(a, a).hashCode, SummaryRange(a, a).hashCode);
      expect(SummaryRange(a, a), isNot(SummaryRange(a, a.addDays(1))));
    });
  });

  group('summarizeRange', () {
    Schedule rotation() {
      final base = presetSchedule('correturnos', const CivilDate(2026, 10, 5));
      return base.copyWith(
        shiftTypes: [
          for (final t in base.shiftTypes)
            switch (t.id) {
              'morning' => t.copyWith(hourlyRateCents: 1000),
              'afternoon' => t.copyWith(hourlyRateCents: 1100),
              _ => t,
            },
        ],
      );
    }

    // A hand-made schedule with the awkward cases: a night that crosses the
    // end of the month, an absence, a rest, a shift without schedule and a
    // double day.
    Schedule awkward() => Schedule(
      shiftTypes: [
        _shift(
          'night',
          ShiftCategory.work,
          start: 22 * _h,
          end: 6 * _h,
          rate: 1300,
        ),
        _shift(
          'morning',
          ShiftCategory.work,
          start: 6 * _h,
          end: 14 * _h,
          rate: 1000,
        ),
        _shift('open', ShiftCategory.work),
        _shift('rest', ShiftCategory.rest),
        _shift('vacation', ShiftCategory.absence),
      ],
      entries: {
        for (final e in {
          const CivilDate(2026, 9, 30): ['night'],
          const CivilDate(2026, 10, 1): ['rest'],
          const CivilDate(2026, 10, 5): ['morning', 'night'],
          const CivilDate(2026, 10, 6): ['vacation'],
          const CivilDate(2026, 10, 7): ['open'],
          const CivilDate(2026, 10, 12): ['morning'],
          const CivilDate(2026, 10, 30): ['morning'],
          const CivilDate(2026, 10, 31): ['night'],
          const CivilDate(2026, 11, 1): ['morning'],
        }.entries)
          e.key: DayEntry(date: e.key, shiftTypeIds: e.value),
      },
    );

    final holidays = {
      const CivilDate(2026, 10, 12),
      const CivilDate(2026, 11, 1),
    };

    for (final (name, schedule) in [
      ('rotation', rotation()),
      ('awkward', awkward()),
    ]) {
      for (final month in [
        const CivilDate(2026, 9, 1),
        const CivilDate(2026, 10, 1),
        const CivilDate(2026, 11, 1),
        const CivilDate(2026, 12, 1),
        const CivilDate(2028, 2, 1), // leap February
      ]) {
        test('$name: a month is the range of its first to its last day '
            '(${month.year}-${month.month})', () {
          final byMonth = summarizeMonth(
            schedule,
            month.addDays(9),
            holidays: holidays,
          );
          final byRange = summarizeRange(
            schedule,
            month,
            month.lastDayOfMonth,
            holidays: holidays,
          );
          expect(_numbers(byRange), _numbers(byMonth));
          // And with the night window of another kind.
          final other = const NightWindow(startMinute: 21 * _h);
          expect(
            _numbers(
              summarizeRange(
                schedule,
                month,
                month.lastDayOfMonth,
                holidays: holidays,
                window: other,
              ),
            ),
            _numbers(
              summarizeMonth(
                schedule,
                month,
                holidays: holidays,
                window: other,
              ),
            ),
          );
        });
      }
    }

    test('a single day: one Mañana of 8 h with its pay', () {
      final s = summarizeRange(
        rotation(),
        const CivilDate(2026, 10, 5),
        const CivilDate(2026, 10, 5),
      );
      expect(s.month, const CivilDate(2026, 10, 5));
      expect(s.shiftsWorked, 1);
      expect(s.workedMinutes, 8 * _h);
      expect(s.earningsCents, 8000);
    });

    test('two ranges that touch add up to the range of both', () {
      final schedule = rotation();
      const from = CivilDate(2026, 10, 3);
      const middle = CivilDate(2026, 10, 20);
      const to = CivilDate(2026, 11, 14);
      final left = summarizeRange(schedule, from, middle);
      final right = summarizeRange(schedule, middle.addDays(1), to);
      final whole = summarizeRange(schedule, from, to);
      expect(left.shiftsWorked + right.shiftsWorked, whole.shiftsWorked);
      expect(left.workedMinutes + right.workedMinutes, whole.workedMinutes);
      expect(left.nightMinutes + right.nightMinutes, whole.nightMinutes);
      expect(left.restDays + right.restDays, whole.restDays);
      expect(left.workedDays + right.workedDays, whole.workedDays);
      expect(
        (left.earningsCents ?? 0) + (right.earningsCents ?? 0),
        whole.earningsCents,
      );
    });

    test('a range of a whole year (366 days) adds up the twelve months', () {
      final schedule = rotation();
      const year = 2028; // leap year
      final range = summarizeRange(
        schedule,
        const CivilDate(year, 1, 1),
        const CivilDate(year, 12, 31),
      );
      final totals = summarizeYearTotals(schedule, year);
      expect(range.shiftsWorked, totals.shiftsWorked);
      expect(range.workedMinutes, totals.workedMinutes);
      expect(range.nightMinutes, totals.nightMinutes);
      expect(range.restDays, totals.restDays);
      expect(range.earningsCents, totals.earningsCents);
      expect(
        SummaryRange(
          const CivilDate(year, 1, 1),
          const CivilDate(year, 12, 31),
        ).days,
        maxSummaryRangeDays,
      );
    });

    test('a night of the last day belongs to the range in full', () {
      final s = summarizeRange(
        awkward(),
        const CivilDate(2026, 10, 31),
        const CivilDate(2026, 10, 31),
      );
      expect(s.shiftsWorked, 1);
      expect(s.workedMinutes, 8 * _h);
      expect(s.nightMinutes, 8 * _h);
    });

    test('before the rotation or with no shifts the range is empty', () {
      final s = summarizeRange(
        rotation(),
        const CivilDate(2026, 8, 1),
        const CivilDate(2026, 8, 20),
      );
      expect(s.isEmpty, isTrue);
      expect(s.workedMinutes, 0);
      expect(s.earningsCents, isNull);
    });

    test(
      'absences, rests and days without schedule are counted like a month',
      () {
        final s = summarizeRange(
          awkward(),
          const CivilDate(2026, 10, 1),
          const CivilDate(2026, 10, 7),
        );
        expect(s.restDays, 1);
        expect(s.absenceDays, 1);
        expect(
          s.shiftsWorked,
          3,
        ); // morning + night on the 5th, open on the 7th
        expect(s.shiftsWithoutTimes, 1);
        expect(s.workedDays, 2);
      },
    );
  });
}
