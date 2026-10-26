import 'package:cuadrante/features/calendar/application/today_status.dart';
import 'package:cuadrante/features/summary/domain/month_summary.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

const _h = 60;

/// Turno partido (docs/paridad.md, A12): the engine gives two occurrences per
/// day, both attributed to the day the first one starts.
ShiftType _split(
  String id, {
  required int start,
  required int end,
  required int start2,
  required int duration2,
  int? paid,
  bool? night,
  int? rate,
  ShiftCategory category = ShiftCategory.work,
}) => ShiftType(
  id: id,
  code: 'P',
  name: id,
  colorValue: 0xFF336699,
  category: category,
  startMinute: start,
  endMinute: end,
  segment2StartMinute: start2,
  segment2DurationMinutes: duration2,
  paidMinutes: paid,
  nightOverride: night,
  hourlyRateCents: rate,
);

/// 09:00-13:00 and 17:00-21:00.
final _partido = _split(
  'partido',
  start: 9 * _h,
  end: 13 * _h,
  start2: 17 * _h,
  duration2: 4 * _h,
);

/// 18:00-22:00 and 23:00-03:00 (the second one crosses midnight).
final _tardeNoche = _split(
  'tn',
  start: 18 * _h,
  end: 22 * _h,
  start2: 23 * _h,
  duration2: 4 * _h,
);

/// 20:00-23:00 and 01:00-03:00 of the next day.
final _lateEarly = _split(
  'le',
  start: 20 * _h,
  end: 23 * _h,
  start2: 1 * _h,
  duration2: 2 * _h,
);

const _plain = ShiftType(
  id: 'plain',
  code: 'M',
  name: 'Mañana',
  colorValue: 0xFFF5A524,
  category: ShiftCategory.work,
  startMinute: 6 * _h,
  endMinute: 14 * _h,
);

const _d = CivilDate(2026, 10, 7);

Schedule _days(List<ShiftType> types, Map<CivilDate, List<String>> days) =>
    Schedule(
      shiftTypes: types,
      entries: {
        for (final e in days.entries)
          e.key: DayEntry(date: e.key, shiftTypeIds: e.value),
      },
    );

void main() {
  group('ShiftType', () {
    test('scheduled minutes are both segments, span includes the gap', () {
      expect(_partido.durationMinutes, 4 * _h);
      expect(_partido.scheduledMinutes, 8 * _h);
      expect(_partido.spanMinutes, 12 * _h);
      expect(_partido.effectivePaidMinutes, 8 * _h);
      expect(_plain.scheduledMinutes, 8 * _h);
      expect(_plain.spanMinutes, 8 * _h);
    });

    test('an explicit paid value wins over the sum', () {
      final t = _partido.copyWith(paidMinutes: 7 * _h);
      expect(t.effectivePaidMinutes, 7 * _h);
    });

    test('crossesMidnight looks at the end of the second segment', () {
      expect(_partido.crossesMidnight, isFalse);
      expect(_tardeNoche.crossesMidnight, isTrue);
      expect(_lateEarly.crossesMidnight, isTrue);
      expect(_partido.lastEndMinute, 21 * _h);
      expect(_tardeNoche.lastEndMinute, 3 * _h);
      expect(_plain.lastEndMinute, 14 * _h);
      // Unchanged for shifts that are not split.
      expect(_plain.crossesMidnight, isFalse);
      const night = ShiftType(
        id: 'n',
        code: 'N',
        name: 'Noche',
        colorValue: 0,
        category: ShiftCategory.work,
        startMinute: 22 * _h,
        endMinute: 6 * _h,
      );
      expect(night.crossesMidnight, isTrue);
      const guard = ShiftType(
        id: 'g',
        code: 'G',
        name: 'Guardia',
        colorValue: 0,
        category: ShiftCategory.work,
        startMinute: 8 * _h,
        endMinute: 8 * _h,
      );
      expect(guard.crossesMidnight, isTrue);
      const toMidnight = ShiftType(
        id: 'm',
        code: 'T',
        name: 'Hasta medianoche',
        colorValue: 0,
        category: ShiftCategory.work,
        startMinute: 16 * _h,
        endMinute: 0,
      );
      expect(toMidnight.crossesMidnight, isTrue);
      const early = ShiftType(
        id: 'e',
        code: 'E',
        name: 'Madrugada',
        colorValue: 0,
        category: ShiftCategory.work,
        startMinute: 0,
        endMinute: 8 * _h,
      );
      expect(early.crossesMidnight, isFalse);
    });
  });

  group('occurrences', () {
    test('a split shift is two occurrences of its start day', () {
      final all = ShiftOccurrence.allOf(_d, _partido);
      expect(all, hasLength(2));
      expect(all[0].segment, 0);
      expect(all[0].startMinuteAbs, 9 * _h);
      expect(all[0].endMinuteAbs, 13 * _h);
      expect(all[1].segment, 1);
      expect(all[1].isSecondSegment, isTrue);
      expect(all[1].startMinuteAbs, 17 * _h);
      expect(all[1].endMinuteAbs, 21 * _h);
      expect(all.map((o) => o.date), [_d, _d]);
      expect(all[0], isNot(all[1]));
      expect(ShiftOccurrence.of(_d, _partido), all[0]);
    });

    test('a segment after midnight keeps the start day', () {
      final all = ShiftOccurrence.allOf(_d, _tardeNoche);
      expect(all[1].startMinuteAbs, 23 * _h);
      expect(all[1].endMinuteAbs, 27 * _h);
      expect(all[1].date, _d);
      expect(all[1].splitByCivilDay(), {_d: 1 * _h, _d.addDays(1): 3 * _h});

      final late = ShiftOccurrence.allOf(_d, _lateEarly);
      expect(late[0].endMinuteAbs, 23 * _h);
      expect(late[1].startMinuteAbs, 25 * _h);
      expect(late[1].endMinuteAbs, 27 * _h);
      expect(late[1].splitByCivilDay(), {_d.addDays(1): 2 * _h});
    });

    test('a shift that is not split is one occurrence, as before', () {
      expect(ShiftOccurrence.allOf(_d, _plain), [
        ShiftOccurrence.of(_d, _plain),
      ]);
    });

    test('schedule.occurrences lists both, in the order of the day', () {
      final s = _days(
        [_partido, _plain],
        {
          _d: ['plain', 'partido'],
          _d.addDays(1): ['partido'],
        },
      );
      final list = s.occurrences(_d, _d.addDays(1));
      expect(
        [for (final o in list) '${o.date.day}${o.shiftType.id}${o.segment}'],
        ['7plain0', '7partido0', '7partido1', '8partido0', '8partido1'],
      );
    });

    test('the second segment of the last day is included', () {
      final s = _days(
        [_lateEarly],
        {
          _d: ['le'],
        },
      );
      expect(s.occurrences(_d, _d), hasLength(2));
      // The day before does not see it.
      expect(s.occurrences(_d.addDays(-1), _d.addDays(-1)), isEmpty);
    });

    test('paid minutes are shared between the segments', () {
      final all = ShiftOccurrence.allOf(_d, _partido);
      expect(all.map((o) => o.paidMinutes), [4 * _h, 4 * _h]);
      // An unpaid break of 30 min comes off the first segment.
      final broken = ShiftOccurrence.allOf(
        _d,
        _partido.copyWith(paidMinutes: 7 * _h + 30),
      );
      expect(broken.map((o) => o.paidMinutes), [3 * _h + 30, 4 * _h]);
      expect(broken.fold<int>(0, (a, o) => a + o.paidMinutes), 7 * _h + 30);
      // A break larger than the first segment leaves it at zero.
      final big = ShiftOccurrence.allOf(
        _d,
        _partido.copyWith(paidMinutes: 3 * _h),
      );
      expect(big.map((o) => o.paidMinutes), [0, 3 * _h]);
      // A shift that is not split keeps its paid minutes.
      expect(ShiftOccurrence.of(_d, _plain).paidMinutes, 8 * _h);
    });
  });

  group('night minutes (each segment against the 22-06 window)', () {
    int night(ShiftType t, {NightWindow w = const NightWindow()}) =>
        ShiftOccurrence.allOf(_d, t).fold(0, (a, o) => a + w.nightMinutes(o));

    test('daytime split shift has none', () {
      expect(night(_partido), 0);
    });

    test('18-22 / 23-03: only the second segment is night', () {
      final parts = [
        for (final o in ShiftOccurrence.allOf(_d, _tardeNoche))
          const NightWindow().nightMinutes(o),
      ];
      expect(parts, [0, 4 * _h]);
      expect(night(_tardeNoche), 4 * _h);
    });

    test('20-23 / 01-03: 1 h in the first and 2 h in the second', () {
      final parts = [
        for (final o in ShiftOccurrence.allOf(_d, _lateEarly))
          const NightWindow().nightMinutes(o),
      ];
      expect(parts, [1 * _h, 2 * _h]);
    });

    test('a second segment that ends in the morning counts the window', () {
      // 20-23 and 04-10: 22-23 in the first, 04-06 in the second.
      final t = _split(
        'x',
        start: 20 * _h,
        end: 23 * _h,
        start2: 4 * _h,
        duration2: 6 * _h,
      );
      expect(night(t), 1 * _h + 2 * _h);
    });

    test('the override applies to every segment', () {
      expect(night(_partido.copyWith(nightOverride: true)), 8 * _h);
      expect(night(_tardeNoche.copyWith(nightOverride: false)), 0);
    });

    test('a custom window is used by both segments', () {
      const w = NightWindow(startMinute: 21 * _h, endMinute: 2 * _h);
      // 18-22: 21-22 = 1 h; 23-03: 23-02 = 3 h.
      expect(night(_tardeNoche, w: w), 4 * _h);
    });
  });

  group('HoursSummary', () {
    test('worked time is the two segments; the gap is not worked', () {
      final h = HoursSummary.of(ShiftOccurrence.allOf(_d, _partido));
      expect(h.workedMinutes, 8 * _h);
      expect(h.nightMinutes, 0);
      expect(h.dayMinutes, 8 * _h);
    });

    test('night and day add up per segment', () {
      final h = HoursSummary.of(ShiftOccurrence.allOf(_d, _tardeNoche));
      expect(h.workedMinutes, 8 * _h);
      expect(h.nightMinutes, 4 * _h);
      expect(h.dayMinutes, 4 * _h);
    });

    test('a shift that is not split is counted as before', () {
      final h = HoursSummary.of([ShiftOccurrence.of(_d, _plain)]);
      expect(h.workedMinutes, 8 * _h);
    });

    test('an unpaid break lowers the paid total', () {
      final h = HoursSummary.of(
        ShiftOccurrence.allOf(_d, _partido.copyWith(paidMinutes: 7 * _h)),
      );
      expect(h.workedMinutes, 7 * _h);
    });
  });

  group('month summary', () {
    const oct = CivilDate(2026, 10, 1);

    test('hours, pay and shifts of split days', () {
      final type = _partido.copyWith(hourlyRateCents: 1000);
      final s = summarizeMonth(
        _days(
          [type, _plain],
          {
            _d: ['partido'],
            _d.addDays(1): ['partido'],
            _d.addDays(2): ['plain', 'partido'],
          },
        ),
        oct,
      );
      expect(s.shiftsWorked, 4);
      expect(s.workedDays, 3);
      // 3 split days x 8 h + one plain shift of 8 h.
      expect(s.workedMinutes, 32 * _h);
      expect(s.nightMinutes, 0);
      final row = s.types.firstWhere((t) => t.type.id == 'partido');
      expect(row.count, 3);
      expect(row.days, 3);
      expect(row.paidMinutes, 24 * _h);
      // 24 h x 10 EUR/h, paid minutes (not the 12 h span) x rate.
      expect(row.earningsCents, 24000);
      expect(s.earningsCents, 24000);
    });

    test('night hours of 18-22 / 23-03 and the cap at the paid minutes', () {
      final s = summarizeMonth(
        _days(
          [_tardeNoche],
          {
            _d: ['tn'],
          },
        ),
        oct,
      );
      expect(s.workedMinutes, 8 * _h);
      expect(s.nightMinutes, 4 * _h);
      // The night part never exceeds what the shift pays.
      final capped = summarizeMonth(
        _days(
          [_tardeNoche.copyWith(nightOverride: true, paidMinutes: _h)],
          {
            _d: ['tn'],
          },
        ),
        oct,
      );
      expect(capped.workedMinutes, _h);
      expect(capped.nightMinutes, _h);
    });

    test('holiday hours are split by civil day, per segment', () {
      // 23-03 of the 7th runs 3 h into the 8th.
      final onNext = summarizeMonth(
        _days(
          [_tardeNoche],
          {
            _d: ['tn'],
          },
        ),
        oct,
        holidays: {_d.addDays(1)},
      );
      expect(onNext.holidayShifts, 1);
      expect(onNext.holidayMinutes, 3 * _h);
      // On the 7th itself: 18-22 (4 h) + 23-24 (1 h).
      final onDay = summarizeMonth(
        _days(
          [_tardeNoche],
          {
            _d: ['tn'],
          },
        ),
        oct,
        holidays: {_d},
      );
      expect(onDay.holidayShifts, 1);
      expect(onDay.holidayMinutes, 5 * _h);
      // Daytime split shift on a holiday: all 8 h, once.
      final partido = summarizeMonth(
        _days(
          [_partido],
          {
            _d: ['partido'],
          },
        ),
        oct,
        holidays: {_d},
      );
      expect(partido.holidayShifts, 1);
      expect(partido.holidayMinutes, 8 * _h);
      // The gap is never a holiday hour: a holiday on the day after is 0.
      final none = summarizeMonth(
        _days(
          [_partido],
          {
            _d: ['partido'],
          },
        ),
        oct,
        holidays: {_d.addDays(1)},
      );
      expect(none.holidayShifts, 0);
      expect(none.holidayMinutes, 0);
    });

    test('holiday hours are prorated when a break makes paid < total', () {
      final s = summarizeMonth(
        _days(
          [_partido.copyWith(paidMinutes: 7 * _h)],
          {
            _d: ['partido'],
          },
        ),
        oct,
        holidays: {_d},
      );
      // 8 h on the holiday x 7/8 = 7 h.
      expect(s.holidayMinutes, 7 * _h);
    });

    test('both segments belong to the month where the shift starts', () {
      const last = CivilDate(2026, 10, 31);
      final schedule = _days(
        [_lateEarly],
        {
          last: ['le'],
        },
      );
      final october = summarizeMonth(schedule, oct);
      expect(october.workedMinutes, 5 * _h);
      expect(october.shiftsWorked, 1);
      final november = summarizeMonth(schedule, const CivilDate(2026, 11, 1));
      expect(november.workedMinutes, 0);
      expect(november.shiftsWorked, 0);
    });

    test('overtime and early leave work as before on a split day', () {
      final type = _partido.copyWith(hourlyRateCents: 1200);
      final s = summarizeMonth(
        Schedule(
          shiftTypes: [type],
          entries: {
            _d: DayEntry(
              date: _d,
              shiftTypeIds: const ['partido'],
              overtimeMinutes: 90,
              earlyLeaveMinutes: 30,
            ),
          },
        ),
        oct,
      );
      expect(s.shiftsWorked, 1);
      expect(s.overtimeMinutes, 90);
      expect(s.earlyLeaveMinutes, 30);
      // 8 h + 1 h 30 - 30 min = 9 h.
      expect(s.workedMinutes, 9 * _h);
      // 8 h x 12 = 96,00 + 18,00 - 6,00.
      expect(s.earningsCents, 10800);
    });

    test('month and range agree for split shifts', () {
      final schedule = _days(
        [_partido, _tardeNoche],
        {
          for (var i = 0; i < 10; i++)
            oct.addDays(i * 3): [i.isEven ? 'partido' : 'tn'],
        },
      );
      expect(
        summarizeRange(schedule, oct, oct.lastDayOfMonth).workedMinutes,
        summarizeMonth(schedule, oct).workedMinutes,
      );
    });
  });

  group('daylight saving (civil clock hours, as for every shift)', () {
    test('the hours of a split shift on 25 October are not corrected', () {
      const sun = CivilDate(2026, 10, 25);
      final s = summarizeRange(
        _days(
          [_tardeNoche],
          {
            sun.addDays(-1): ['tn'],
            sun: ['tn'],
          },
        ),
        sun.addDays(-1),
        sun,
      );
      expect(s.workedMinutes, 16 * _h);
      expect(s.nightMinutes, 8 * _h);
    });

    test('the same on 29 March', () {
      const sun = CivilDate(2026, 3, 29);
      final s = summarizeRange(
        _days(
          [_tardeNoche],
          {
            sun.addDays(-1): ['tn'],
          },
        ),
        sun.addDays(-1),
        sun.addDays(-1),
      );
      expect(s.workedMinutes, 8 * _h);
      expect(s.nightMinutes, 4 * _h);
    });
  });

  group('"Hoy" card', () {
    final schedule = _days(
      [_partido, _plain, _lateEarly],
      {
        _d: ['partido'],
        _d.addDays(1): ['partido'],
        _d.addDays(3): ['le'],
      },
    );

    TodayStatus at(int hour, [int minute = 0, CivilDate day = _d]) =>
        todayStatus(
          schedule,
          DateTime(day.year, day.month, day.day, hour, minute),
        );

    test('before the first segment it counts down to it', () {
      final status = at(8);
      expect(status.phase, TodayPhase.today);
      expect(status.main!.id, 'partido');
      expect(status.timed!.segment, 0);
      expect(status.minutes, 60);
      // The second segment is not "another shift".
      expect(status.others, isEmpty);
    });

    test('inside the first segment: it ends at 13:00', () {
      final status = at(11, 30);
      expect(status.phase, TodayPhase.now);
      expect(status.timed!.end, DateTime(2026, 10, 7, 13));
      expect(status.minutes, 90);
      expect(status.others, isEmpty);
    });

    test('in the gap: back at 17:00', () {
      final status = at(14, 15);
      expect(status.phase, TodayPhase.gap);
      expect(status.main!.id, 'partido');
      expect(status.timed!.isSecondSegment, isTrue);
      expect(status.timed!.start, DateTime(2026, 10, 7, 17));
      expect(status.minutes, 2 * _h + 45);
      expect(status.others, isEmpty);
    });

    test('13:00 sharp is already the gap and 17:00 sharp is now', () {
      expect(at(13).phase, TodayPhase.gap);
      final back = at(17);
      expect(back.phase, TodayPhase.now);
      expect(back.timed!.isSecondSegment, isTrue);
      expect(back.minutes, 4 * _h);
    });

    test('inside the second segment: it ends at 21:00', () {
      final status = at(19);
      expect(status.phase, TodayPhase.now);
      expect(status.timed!.end, DateTime(2026, 10, 7, 21));
      expect(status.minutes, 2 * _h);
    });

    test('after the last segment today is over; tomorrow comes next', () {
      final status = at(22);
      expect(status.phase, TodayPhase.done);
      // The shift that ended is the split one, by its second segment.
      expect(status.main!.id, 'partido');
      expect(status.finished!.isSecondSegment, isTrue);
      expect(status.finished!.end, DateTime(2026, 10, 7, 21));
      expect(status.timed!.date, _d.addDays(1));
      expect(status.timed!.segment, 0);
      expect(status.tomorrow.map((t) => t.id), ['partido']);
    });

    test('another shift later today is listed once', () {
      final s = _days(
        [_partido, _plain],
        {
          _d: ['plain', 'partido'],
        },
      );
      final status = todayStatus(s, DateTime(2026, 10, 7, 5));
      expect(status.main!.id, 'plain');
      expect(status.others.map((t) => t.id), ['partido']);
      // In the gap of the split shift nothing else is pending.
      final gap = todayStatus(s, DateTime(2026, 10, 7, 15));
      expect(gap.phase, TodayPhase.gap);
      expect(gap.others, isEmpty);
    });

    test('a gap that spans midnight is found from the day after', () {
      // 20-23 on the 10th and 01-03 of the 11th.
      final inGap = todayStatus(schedule, DateTime(2026, 10, 10, 23, 30));
      expect(inGap.phase, TodayPhase.gap);
      expect(inGap.timed!.start, DateTime(2026, 10, 11, 1));
      expect(inGap.minutes, 90);
      // After midnight it is still the gap of yesterday's shift...
      final after = todayStatus(schedule, DateTime(2026, 10, 11, 0, 30));
      expect(after.phase, TodayPhase.gap);
      expect(after.minutes, 30);
      // ...and then the second segment is in progress.
      final inside = todayStatus(schedule, DateTime(2026, 10, 11, 2));
      expect(inside.phase, TodayPhase.now);
      expect(inside.timed!.end, DateTime(2026, 10, 11, 3));
    });

    test(
      'the countdown is real time when the gap crosses the clock change',
      () {
        // 2026-10-25 (Europe/Madrid, as CI runs): clocks go back at 03:00, so
        // 01:30 to the 03:00 end of the second segment (20-23 on the 24th and
        // 01-03 of the 25th) is 2 h 30 min, not 1 h 30.
        const sat = CivilDate(2026, 10, 24);
        final s = _days(
          [_lateEarly],
          {
            sat: ['le'],
          },
        );
        final inGap = todayStatus(s, DateTime(2026, 10, 24, 23, 30));
        expect(inGap.phase, TodayPhase.gap);
        expect(inGap.minutes, 90);
        final inside = todayStatus(s, DateTime(2026, 10, 25, 1, 30));
        expect(inside.phase, TodayPhase.now);
        expect(inside.minutes, 150);
      },
    );
  });
}
