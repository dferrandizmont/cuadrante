import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/summary/domain/month_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../schedule/domain/fixtures.dart';

// Overtime and early leave in the monthly summary (docs/paridad.md, A6;
// definitions in docs/motor-de-turnos.md, «Resumen del mes»).

const _oct = CivilDate(2026, 10, 1);
const _nov = CivilDate(2026, 11, 1);
const _h = 60;

ShiftType _shift(
  String id, {
  int start = 8 * 60,
  int end = 16 * 60,
  int? rate,
  ShiftCategory category = ShiftCategory.work,
  bool times = true,
}) => ShiftType(
  id: id,
  code: id.substring(0, 1).toUpperCase(),
  name: id,
  colorValue: 0xFF336699,
  category: category,
  startMinute: times ? start : null,
  endMinute: times ? end : null,
  hourlyRateCents: rate,
);

// 8 h at 10 EUR/h, 8 h without rate, a 1 h shift at 10 EUR/h.
final _priced = _shift('priced', rate: 1000);
final _free = _shift('free');
final _short = _shift('short', start: 17 * 60, end: 18 * 60, rate: 1000);
final _rest = _shift('rest', category: ShiftCategory.rest, times: false);
final _vacation = _shift(
  'vacation',
  category: ShiftCategory.absence,
  times: false,
);
final _night = _shift('night', start: 22 * 60, end: 6 * 60, rate: 1000);
final _types = [_priced, _free, _short, _rest, _vacation, _night];

CivilDate _d(int day) => CivilDate(2026, 10, day);

DayEntry _entry(
  int day, {
  List<String>? shifts,
  int? overtime,
  int? earlyLeave,
}) => DayEntry(
  date: _d(day),
  shiftTypeIds: shifts,
  overtimeMinutes: overtime,
  earlyLeaveMinutes: earlyLeave,
);

Schedule _schedule(List<DayEntry> entries) =>
    Schedule(shiftTypes: _types, entries: {for (final e in entries) e.date: e});

MonthSummary _sum(List<DayEntry> entries, {CivilDate month = _oct}) =>
    summarizeMonth(_schedule(entries), month);

void main() {
  group('no extras: nothing changes', () {
    test('the new figures are zero and the total is the shifts', () {
      final s = _sum([
        _entry(5, shifts: ['priced']),
      ]);
      expect(s.workedMinutes, 8 * _h);
      expect(s.shiftMinutes, 8 * _h);
      expect(s.overtimeMinutes, 0);
      expect(s.earlyLeaveMinutes, 0);
      expect(s.hasExtras, isFalse);
      expect(s.overtimeCents, 0);
      expect(s.earlyLeaveCents, 0);
      expect(s.extrasWithoutRateMinutes, 0);
      expect(s.earningsCents, 8000);
    });
  });

  group('overtime', () {
    test('adds to the hours and is paid at the rate of the shift', () {
      final s = _sum([
        _entry(5, shifts: ['priced'], overtime: 90),
      ]);
      expect(s.workedMinutes, 8 * _h + 90);
      expect(s.shiftMinutes, 8 * _h);
      expect(s.overtimeMinutes, 90);
      // 8 h x 10 + 1 h 30 x 10.
      expect(s.overtimeCents, 1500);
      expect(s.earningsCents, 9500);
      // The day itself is unchanged: one shift, one worked day.
      expect(s.shiftsWorked, 1);
      expect(s.workedDays, 1);
    });

    test('does not touch the night hours (counted as day hours)', () {
      final s = _sum([
        _entry(5, shifts: ['night'], overtime: 60),
      ]);
      expect(s.workedMinutes, 9 * _h);
      expect(s.nightMinutes, 8 * _h);
      expect(s.dayMinutes, 1 * _h);
    });

    test('on a day with no shift at all counts as hours, not as a shift', () {
      final s = _sum([_entry(7, overtime: 120)]);
      expect(s.workedMinutes, 2 * _h);
      expect(s.overtimeMinutes, 2 * _h);
      expect(s.shiftsWorked, 0);
      expect(s.workedDays, 0);
      // The month is not empty: there are hours to show.
      expect(s.types, isEmpty);
      expect(s.isEmpty, isFalse);
      // No priced shift that day: the euros are left alone and it is said.
      expect(s.earningsCents, isNull);
      expect(s.extrasWithoutRateMinutes, 2 * _h);
    });

    test('on a rest day and on an absence day counts too', () {
      final s = _sum([
        _entry(7, shifts: ['rest'], overtime: 60),
        _entry(8, shifts: ['vacation'], overtime: 30),
      ]);
      expect(s.workedMinutes, 90);
      expect(s.overtimeMinutes, 90);
      // They keep being a rest day and an absence day.
      expect(s.restDays, 1);
      expect(s.absenceDays, 1);
      expect(s.workedDays, 0);
      expect(s.shiftsWorked, 0);
    });

    test('a month with nothing but empty days stays empty', () {
      expect(_sum([]).isEmpty, isTrue);
      expect(_sum([_entry(5, shifts: [])]).isEmpty, isTrue);
    });

    test('is valued at the first PRICED work shift of the day, in the order '
        'of the day', () {
      // Free first, priced second: the rate of the second one.
      final a = _sum([
        _entry(5, shifts: ['free', 'priced'], overtime: 60),
      ]);
      expect(a.overtimeCents, 1000);
      expect(a.extrasWithoutRateMinutes, 0);
      // Two priced ones: the first rate wins.
      final other = _shift('other', rate: 2000);
      final b = summarizeMonth(
        Schedule(
          shiftTypes: [..._types, other],
          entries: {
            _d(5): _entry(5, shifts: ['other', 'priced'], overtime: 60),
          },
        ),
        _oct,
      );
      expect(b.overtimeCents, 2000);
    });

    test('with only unpriced shifts the euros stay and it is flagged', () {
      final s = _sum([
        _entry(5, shifts: ['free'], overtime: 60),
      ]);
      expect(s.workedMinutes, 9 * _h);
      expect(s.overtimeCents, 0);
      expect(s.earningsCents, isNull);
      expect(s.extrasWithoutRateMinutes, 60);
    });

    test('a priced rest/absence day does not give a rate to the extras', () {
      final s = _sum([
        _entry(5, shifts: ['priced'], overtime: 60),
        _entry(6, shifts: ['vacation'], overtime: 60),
      ]);
      expect(s.overtimeCents, 1000);
      expect(s.extrasWithoutRateMinutes, 60);
    });

    test('is rounded once per month, not per day', () {
      // 1 min at 10 EUR/h is 16.67 cents: 3 days = 50 cents, not 3 x 17.
      final s = _sum([
        for (final day in [5, 6, 7])
          _entry(day, shifts: ['priced'], overtime: 1),
      ]);
      expect(s.overtimeMinutes, 3);
      expect(s.overtimeCents, 50);
      expect(s.earningsCents, 3 * 8000 + 50);
    });
  });

  group('early leave', () {
    test('subtracts from the hours and from the pay', () {
      final s = _sum([
        _entry(5, shifts: ['priced'], earlyLeave: 30),
      ]);
      expect(s.workedMinutes, 8 * _h - 30);
      expect(s.shiftMinutes, 8 * _h);
      expect(s.earlyLeaveMinutes, 30);
      expect(s.earlyLeaveCents, 500);
      expect(s.earningsCents, 8000 - 500);
    });

    test('never takes a day below 0 h: only what the day had is applied', () {
      final s = _sum([
        _entry(5, shifts: ['priced'], earlyLeave: 10 * _h),
      ]);
      expect(s.earlyLeaveMinutes, 8 * _h);
      expect(s.workedMinutes, 0);
      expect(s.earningsCents, 0);
    });

    test('on a day with no work shift there is nothing to subtract', () {
      final s = _sum([
        _entry(5, earlyLeave: 60),
        _entry(6, shifts: ['rest'], earlyLeave: 60),
        _entry(7, shifts: ['vacation'], earlyLeave: 60),
      ]);
      expect(s.earlyLeaveMinutes, 0);
      expect(s.workedMinutes, 0);
      expect(s.hasExtras, isFalse);
      expect(s.extrasWithoutRateMinutes, 0);
    });

    test('the same day\'s overtime can be left early too', () {
      // 8 h + 1 h of overtime, left 2 h before: 7 h.
      final s = _sum([
        _entry(5, shifts: ['priced'], overtime: 60, earlyLeave: 120),
      ]);
      expect(s.workedMinutes, 7 * _h);
      expect(s.overtimeMinutes, 60);
      expect(s.earlyLeaveMinutes, 120);
      expect(s.earningsCents, 8000 + 1000 - 2000);
    });

    test('with no priced shift the euros do not move', () {
      final s = _sum([
        _entry(5, shifts: ['free'], earlyLeave: 60),
      ]);
      expect(s.workedMinutes, 7 * _h);
      expect(s.earningsCents, isNull);
      expect(s.extrasWithoutRateMinutes, 60);
    });

    test('the euros deducted never exceed what the priced shifts pay', () {
      // 8 h unpriced + 1 h priced; left 9 h early. The hours go to 0 but the
      // deduction is capped at the 10 EUR the priced hour pays.
      final s = _sum([
        _entry(5, shifts: ['free', 'short'], earlyLeave: 9 * _h),
      ]);
      expect(s.workedMinutes, 0);
      expect(s.earlyLeaveMinutes, 9 * _h);
      expect(s.earlyLeaveCents, 1000);
      expect(s.earningsCents, 0);
    });

    test('the total pay is never negative', () {
      final s = _sum([
        _entry(5, shifts: ['short'], earlyLeave: 60),
        _entry(6, shifts: ['short'], earlyLeave: 60),
      ]);
      expect(s.earningsCents, 0);
    });
  });

  group('multi-shift days', () {
    test('overtime and early leave belong to the day, not to a shift', () {
      final s = _sum([
        _entry(5, shifts: ['priced', 'short'], overtime: 30, earlyLeave: 90),
      ]);
      // 9 h of shifts + 30 min - 1 h 30 min.
      expect(s.shiftMinutes, 9 * _h);
      expect(s.workedMinutes, 8 * _h);
      expect(s.shiftsWorked, 2);
      expect(s.workedDays, 1);
      // Per type nothing moves: the extras are not in a shift's hours.
      final priced = s.types.firstWhere((t) => t.type.id == 'priced');
      expect(priced.paidMinutes, 8 * _h);
      // 8 h + 1 h + 30 min - 1 h 30 at 10 EUR/h.
      expect(s.earningsCents, 9000 + 500 - 1500);
    });

    test('the invariant shifts + overtime - early = total always holds', () {
      final s = _sum([
        _entry(5, shifts: ['priced'], overtime: 45, earlyLeave: 15),
        _entry(6, shifts: ['short'], earlyLeave: 600),
        _entry(7, overtime: 20, earlyLeave: 99),
        _entry(8, shifts: ['night', 'free'], overtime: 5),
      ]);
      expect(
        s.shiftMinutes + s.overtimeMinutes - s.earlyLeaveMinutes,
        s.workedMinutes,
      );
      expect(s.shiftMinutes, 8 * _h + 1 * _h + 8 * _h + 8 * _h);
    });
  });

  group('which month an extra belongs to', () {
    test('the month of the day it is noted on', () {
      final schedule = _schedule([
        _entry(31, shifts: ['priced'], overtime: 60),
        DayEntry(
          date: const CivilDate(2026, 11, 1),
          shiftTypeIds: const ['priced'],
          earlyLeaveMinutes: 30,
        ),
      ]);
      final oct = summarizeMonth(schedule, _oct);
      final nov = summarizeMonth(schedule, _nov);
      expect(oct.overtimeMinutes, 60);
      expect(oct.earlyLeaveMinutes, 0);
      expect(nov.overtimeMinutes, 0);
      expect(nov.earlyLeaveMinutes, 30);
    });

    test('on a day whose shifts come from the rotation', () {
      final base = presetSchedule('correturnos', const CivilDate(2026, 10, 5));
      // 5 October is a Mañana of the rotation; the entry only has overtime.
      final schedule = base.copyWith(
        entries: {
          _d(5): DayEntry(date: _d(5), overtimeMinutes: 45),
          _d(6): DayEntry(date: _d(6), earlyLeaveMinutes: 30),
        },
      );
      final plain = summarizeMonth(base, _oct);
      final s = summarizeMonth(schedule, _oct);
      expect(s.shiftsWorked, plain.shiftsWorked);
      expect(s.shiftMinutes, plain.workedMinutes);
      expect(s.workedMinutes, plain.workedMinutes + 45 - 30);
    });
  });

  group('date range («Fechas…»)', () {
    final entries = [
      _entry(5, shifts: ['priced'], overtime: 90),
      _entry(7, shifts: ['priced'], earlyLeave: 60),
      _entry(12, overtime: 120), // no shift at all
      _entry(15, shifts: ['short'], overtime: 30, earlyLeave: 15),
      _entry(26, shifts: ['priced'], overtime: 60),
    ];
    final schedule = _schedule(entries);

    Map<String, Object?> extras(MonthSummary s) => {
      'worked': s.workedMinutes,
      'shift': s.shiftMinutes,
      'overtime': s.overtimeMinutes,
      'early': s.earlyLeaveMinutes,
      'overtimeCents': s.overtimeCents,
      'earlyCents': s.earlyLeaveCents,
      'earnings': s.earningsCents,
      'noRate': s.extrasWithoutRateMinutes,
      'shifts': s.shiftsWorked,
      'days': s.workedDays,
      'empty': s.isEmpty,
    };

    test('the whole month as a range equals the month, extras included', () {
      final month = summarizeMonth(schedule, _oct);
      final range = summarizeRange(schedule, _oct, _oct.lastDayOfMonth);
      expect(month.overtimeMinutes, 90 + 120 + 30 + 60);
      expect(month.earlyLeaveMinutes, 60 + 15);
      expect(extras(range), extras(month));
      expect(range.month, _oct);
    });

    test('only the extras of the days inside the range count', () {
      final range = summarizeRange(schedule, _d(6), _d(15));
      // 7th: early leave 60; 12th: overtime 120, no rate; 15th: 30 / 15 at 10.
      expect(range.overtimeMinutes, 120 + 30);
      expect(range.earlyLeaveMinutes, 60 + 15);
      expect(range.shiftMinutes, 8 * _h + 1 * _h);
      expect(range.workedMinutes, 9 * _h + 150 - 75);
      expect(range.extrasWithoutRateMinutes, 120);
      expect(range.overtimeCents, 500);
      expect(range.earlyLeaveCents, 1000 + 250);
      expect(range.shiftsWorked, 2);
    });

    test('a range of only an extras day is not empty and has no shifts', () {
      final range = summarizeRange(schedule, _d(12), _d(12));
      expect(range.overtimeMinutes, 2 * _h);
      expect(range.workedMinutes, 2 * _h);
      expect(range.shiftsWorked, 0);
      expect(range.isEmpty, isFalse);
      expect(range.hasExtras, isTrue);
    });

    test('a range without extras days has none', () {
      final range = summarizeRange(schedule, _d(16), _d(25));
      expect(range.hasExtras, isFalse);
      expect(range.overtimeMinutes, 0);
      expect(range.earlyLeaveMinutes, 0);
    });

    test('adjacent ranges add up to the whole range, extras included', () {
      final left = summarizeRange(schedule, _d(1), _d(14));
      final right = summarizeRange(schedule, _d(15), _d(31));
      final whole = summarizeRange(schedule, _d(1), _d(31));
      expect(
        left.overtimeMinutes + right.overtimeMinutes,
        whole.overtimeMinutes,
      );
      expect(
        left.earlyLeaveMinutes + right.earlyLeaveMinutes,
        whole.earlyLeaveMinutes,
      );
      expect(left.workedMinutes + right.workedMinutes, whole.workedMinutes);
      expect(left.overtimeCents + right.overtimeCents, whole.overtimeCents);
    });

    test('a range across two months sums the extras of both', () {
      final all = _schedule([
        ...entries,
        DayEntry(
          date: const CivilDate(2026, 11, 3),
          shiftTypeIds: const ['priced'],
          overtimeMinutes: 45,
        ),
      ]);
      final range = summarizeRange(all, _d(20), const CivilDate(2026, 11, 5));
      expect(range.overtimeMinutes, 60 + 45);
      expect(range.shiftsWorked, 2);
    });
  });

  group('year totals', () {
    test('add the twelve months, extras included', () {
      final schedule = Schedule(
        shiftTypes: _types,
        entries: {
          const CivilDate(2026, 3, 2): const DayEntry(
            date: CivilDate(2026, 3, 2),
            shiftTypeIds: ['priced'],
            overtimeMinutes: 60,
          ),
          const CivilDate(2026, 9, 14): const DayEntry(
            date: CivilDate(2026, 9, 14),
            shiftTypeIds: ['priced'],
            earlyLeaveMinutes: 30,
          ),
          const CivilDate(2026, 12, 24): const DayEntry(
            date: CivilDate(2026, 12, 24),
            overtimeMinutes: 90,
          ),
        },
      );
      final year = summarizeYearTotals(schedule, 2026);
      expect(year.overtimeMinutes, 150);
      expect(year.earlyLeaveMinutes, 30);
      expect(year.hasExtras, isTrue);
      expect(year.workedMinutes, 16 * _h + 150 - 30);
      expect(year.shiftsWorked, 2);
      // 2 shifts of 80 + 10 (March overtime) - 5 (September early leave).
      expect(year.earningsCents, 16000 + 1000 - 500);
      expect(year.isEmpty, isFalse);
    });

    test('a year with only overtime is not empty', () {
      final schedule = Schedule(
        shiftTypes: _types,
        entries: {
          const CivilDate(2026, 5, 5): const DayEntry(
            date: CivilDate(2026, 5, 5),
            overtimeMinutes: 30,
          ),
        },
      );
      final year = summarizeYearTotals(schedule, 2026);
      expect(year.isEmpty, isFalse);
      expect(year.workedMinutes, 30);
    });
  });

  group('ResolvedDay carries the extras', () {
    test('from the override and from the rotation, and 0 when absent', () {
      final base = presetSchedule('correturnos', const CivilDate(2026, 10, 5));
      final schedule = base.copyWith(
        entries: {
          _d(5): DayEntry(
            date: _d(5),
            overtimeMinutes: 45,
            earlyLeaveMinutes: 10,
          ),
          _d(6): DayEntry(
            date: _d(6),
            shiftTypeIds: const ['afternoon'],
            overtimeMinutes: 20,
          ),
        },
      );
      final fromRotation = schedule.resolve(_d(5));
      expect(fromRotation.source, DaySource.pattern);
      expect(fromRotation.overtimeMinutes, 45);
      expect(fromRotation.earlyLeaveMinutes, 10);
      expect(fromRotation.hasExtras, isTrue);
      final overridden = schedule.resolve(_d(6));
      expect(overridden.source, DaySource.override);
      expect(overridden.overtimeMinutes, 20);
      expect(overridden.earlyLeaveMinutes, 0);
      // resolvePattern keeps them too (they are not part of the override).
      expect(schedule.resolvePattern(_d(6)).overtimeMinutes, 20);
      final plain = schedule.resolve(_d(7));
      expect(plain.hasExtras, isFalse);
      expect(plain.overtimeMinutes, 0);
    });
  });
}
