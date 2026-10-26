import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/summary/domain/month_summary.dart';
import 'package:flutter_test/flutter_test.dart';

const _first = CivilDate(2026, 10, 1);

ShiftType _type(
  String id, {
  int? plus,
  int? rate,
  ShiftCategory category = ShiftCategory.work,
  bool times = true,
}) => ShiftType(
  id: id,
  code: id,
  name: id,
  colorValue: 0xFF4B4FD1,
  category: category,
  startMinute: times ? 8 * 60 : null,
  endMinute: times ? 16 * 60 : null,
  hourlyRateCents: rate,
  fixedPlusCents: plus,
);

Schedule _schedule(List<ShiftType> types, List<DayEntry> entries) => Schedule(
  shiftTypes: types,
  entries: {for (final entry in entries) entry.date: entry},
);

DayEntry _day(int day, List<String> ids, {int? early, int? overtime}) =>
    DayEntry(
      date: CivilDate(2026, 10, day),
      shiftTypeIds: ids,
      earlyLeaveMinutes: early,
      overtimeMinutes: overtime,
    );

void main() {
  test('each work shift adds its plus, including two on the same day', () {
    final schedule = _schedule(
      [_type('M', rate: 1000, plus: 1234), _type('N', rate: 1000, plus: 3000)],
      [
        _day(1, ['M', 'N']),
        _day(2, ['N']),
      ],
    );
    final summary = summarizeMonth(schedule, _first);
    expect(summary.workedDays, 2);
    expect(summary.shiftsWorked, 3);
    expect(summary.fixedPlusCount, 3);
    expect(summary.fixedPlusCents, 7234);
    expect(summary.earningsCents, 3 * 8000 + 7234);
    // The hourly breakdown remains separate from the fixed-plus line.
    expect(summary.types.map((t) => t.earningsCents), [8000, 16000]);
    final range = summarizeRange(schedule, _first, _first.addDays(1));
    expect(range.fixedPlusCount, summary.fixedPlusCount);
    expect(range.fixedPlusCents, summary.fixedPlusCents);
    expect(range.earningsCents, summary.earningsCents);
    expect(
      summarizeYearTotals(schedule, 2026).earningsCents,
      summary.earningsCents,
    );
  });

  test('rest, absence and overtime on an empty day earn no fixed plus', () {
    final summary = summarizeMonth(
      _schedule(
        [
          _type('M', plus: 3000),
          _type('L', plus: 9900, category: ShiftCategory.rest),
          _type('V', plus: 9900, category: ShiftCategory.absence),
        ],
        [
          _day(1, ['L']),
          _day(2, ['V']),
          _day(3, [], overtime: 60),
        ],
      ),
      _first,
    );
    expect(summary.restDays, 1);
    expect(summary.absenceDays, 1);
    expect(summary.fixedPlusCount, 0);
    expect(summary.fixedPlusCents, 0);
    expect(summary.earningsCents, isNull);
  });

  test('no configured plus preserves hourly earnings and absent earnings', () {
    for (final rate in [null, 1000]) {
      final summary = summarizeMonth(
        _schedule(
          [_type('M', rate: rate)],
          [
            _day(1, ['M']),
          ],
        ),
        _first,
      );
      expect(summary.fixedPlusCount, 0);
      expect(summary.fixedPlusCents, 0);
      expect(summary.earningsCents, rate == null ? null : 8000);
    }
  });

  test('plus needs neither hours nor hourly rate; zero is configured', () {
    for (final times in [false, true]) {
      for (final plus in [0, 3000]) {
        final summary = summarizeMonth(
          _schedule(
            [_type('M', plus: plus, times: times)],
            [
              _day(1, ['M']),
            ],
          ),
          _first,
        );
        expect(summary.fixedPlusCount, 1);
        expect(summary.fixedPlusCents, plus);
        expect(summary.earningsCents, plus);
        expect(summary.hasEarnings, isTrue);
      }
    }
  });

  test('a split shift gets one plus, on the day its first segment starts', () {
    final shift = _type('P', plus: 3000, rate: 1000).copyWith(
      startMinute: 20 * 60,
      endMinute: 23 * 60,
      segment2StartMinute: 60,
      segment2DurationMinutes: 120,
    );
    final schedule = _schedule(
      [shift],
      [
        _day(31, ['P']),
      ],
    );
    final october = summarizeMonth(schedule, _first);
    expect(october.workedMinutes, 300);
    expect(october.fixedPlusCount, 1);
    expect(october.fixedPlusCents, 3000);
    expect(october.earningsCents, 5000 + 3000);
    final november = summarizeMonth(schedule, const CivilDate(2026, 11, 1));
    expect(november.fixedPlusCount, 0);
    expect(november.earningsCents, isNull);
  });

  test('unpaid breaks and early leave never deduct a fixed plus', () {
    final summary = summarizeMonth(
      _schedule(
        [_type('M', rate: 1000, plus: 3000).copyWith(paidMinutes: 7 * 60)],
        [
          _day(1, ['M'], early: 8 * 60, overtime: 60),
        ],
      ),
      _first,
    );
    expect(summary.workedMinutes, 0);
    expect(summary.overtimeCents, 1000);
    expect(summary.earlyLeaveCents, 8000);
    expect(summary.fixedPlusCount, 1);
    expect(summary.fixedPlusCents, 3000);
    expect(summary.earningsCents, 3000);
  });
}
