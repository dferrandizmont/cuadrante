import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

const _d = CivilDate(2026, 3, 28);

ShiftOccurrence _occ(
  int start,
  int end, {
  bool? nightOverride,
  ShiftCategory category = ShiftCategory.work,
  int? paid,
}) => ShiftOccurrence.of(
  _d,
  ShiftType(
    id: 'x',
    code: 'X',
    name: 'x',
    colorValue: 0,
    category: category,
    startMinute: start,
    endMinute: end,
    paidMinutes: paid,
    nightOverride: nightOverride,
  ),
);

int _night(int startH, int endH, {bool? nightOverride, NightWindow? window}) =>
    (window ?? const NightWindow()).nightMinutes(
      _occ(startH * 60, endH * 60, nightOverride: nightOverride),
    );

void main() {
  group('ShiftOccurrence', () {
    test('absolute minutes can pass 1440', () {
      final o = _occ(22 * 60, 6 * 60);
      expect(o.date, _d);
      expect(o.startMinuteAbs, 1320);
      expect(o.endMinuteAbs, 1800);
      expect(o.durationMinutes, 480);
      final g = _occ(480, 480);
      expect(g.endMinuteAbs, 480 + 1440);
      expect(g.durationMinutes, 1440);
    });

    test('shift types without schedule cannot be placed', () {
      expect(
        () =>
            ShiftOccurrence.of(_d, shiftTemplateByKey('rest').toShiftType('l')),
        throwsArgumentError,
      );
    });

    test('splitByCivilDay of a 22-06 shift gives 120 + 360', () {
      final split = _occ(22 * 60, 6 * 60).splitByCivilDay();
      expect(split, {_d: 120, _d.addDays(1): 360});
      expect(split.keys.toList(), [_d, _d.addDays(1)]);
    });

    test('splitByCivilDay of a single-day shift and of a 24 h guard', () {
      expect(_occ(6 * 60, 14 * 60).splitByCivilDay(), {_d: 480});
      expect(_occ(8 * 60, 8 * 60).splitByCivilDay(), {
        _d: 960,
        _d.addDays(1): 480,
      });
      expect(_occ(0, 0).splitByCivilDay(), {_d: 1440});
    });
  });

  group('NightWindow', () {
    test('22-06 is 480 night minutes', () => expect(_night(22, 6), 480));

    test('22-07 is 480 of 540', () {
      expect(_night(22, 7), 480);
      expect(_occ(22 * 60, 7 * 60).durationMinutes, 540);
    });

    test('15-22 has none', () => expect(_night(15, 22), 0));

    test('04-12 has 120 from the window that began the night before', () {
      expect(_night(4, 12), 120);
    });

    test('24 h guard 08-08 has 480 of 1440', () {
      expect(_night(8, 8), 480);
      expect(_occ(8 * 60, 8 * 60).durationMinutes, 1440);
    });

    test('20-08 has 480', () => expect(_night(20, 8), 480));

    test('day shifts with partial overlap', () {
      expect(_night(6, 14), 0);
      expect(_night(14, 23), 60);
      expect(_night(0, 8), 360);
    });

    test('nightOverride true = all night, false = none', () {
      expect(_night(8, 20, nightOverride: true), 720);
      expect(_night(22, 6, nightOverride: false), 0);
      expect(_night(22, 6, nightOverride: null), 480);
    });

    test('custom windows', () {
      expect(
        _night(
          21,
          5,
          window: const NightWindow(startMinute: 21 * 60, endMinute: 5 * 60),
        ),
        480,
      );
      // Window inside one day (00:00-06:00).
      const early = NightWindow(startMinute: 0, endMinute: 6 * 60);
      expect(_night(22, 6, window: early), 360);
      expect(_night(4, 12, window: early), 120);
      expect(_night(8, 16, window: early), 0);
    });
  });

  group('HoursSummary', () {
    test('only work counts; day = worked - night', () {
      final s = HoursSummary.of([
        _occ(6 * 60, 14 * 60),
        _occ(22 * 60, 6 * 60),
        _occ(8 * 60, 20 * 60, category: ShiftCategory.absence),
        _occ(8 * 60, 20 * 60, category: ShiftCategory.rest),
      ]);
      expect(s.workedMinutes, 960);
      expect(s.nightMinutes, 480);
      expect(s.dayMinutes, 480);
    });

    test('paidMinutes replaces the duration', () {
      final s = HoursSummary.of([_occ(6 * 60, 14 * 60, paid: 450)]);
      expect(s.workedMinutes, 450);
      expect(s.nightMinutes, 0);
      expect(s.dayMinutes, 450);
    });

    test('24 h guard: 1440 worked, 480 night, 960 day', () {
      expect(
        HoursSummary.of([_occ(8 * 60, 8 * 60)]),
        const HoursSummary(
          workedMinutes: 1440,
          nightMinutes: 480,
          dayMinutes: 960,
        ),
      );
    });

    test('empty input and custom window', () {
      expect(HoursSummary.of(const []).workedMinutes, 0);
      final s = HoursSummary.of([
        _occ(22 * 60, 6 * 60),
      ], const NightWindow(startMinute: 0, endMinute: 6 * 60));
      expect(s.nightMinutes, 360);
      expect(s.dayMinutes, 120);
    });

    test('a full correturnos cycle', () {
      const monday = CivilDate(2026, 1, 5);
      final s = presetSchedule('correturnos', monday);
      final summary = HoursSummary.of(
        s.occurrences(monday, monday.addDays(20)),
      );
      expect(summary.workedMinutes, 15 * 480);
      expect(summary.nightMinutes, 5 * 480);
      expect(summary.dayMinutes, 10 * 480);
    });
  });

  group('Schedule.occurrences', () {
    test('only shifts with schedule, imputed to the start day', () {
      final s = presetSchedule('correturnos', const CivilDate(2026, 3, 2));
      // Nights of 2026-03-16..20 (cycle day 14 on).
      final occ = s.occurrences(
        const CivilDate(2026, 3, 16),
        const CivilDate(2026, 3, 20),
      );
      expect(occ.length, 5);
      expect(occ.every((o) => o.shiftType.id == 'night'), isTrue);
      expect(occ.first.date, const CivilDate(2026, 3, 16));
      expect(occ.first.endMinuteAbs, 1800);
      // The Friday night ends on Saturday but belongs to Friday.
      expect(occ.last.date, const CivilDate(2026, 3, 20));
    });

    test(
      'a night that ends in the range but started before is not included',
      () {
        final s = presetSchedule('correturnos', const CivilDate(2026, 3, 2));
        // L starts the Saturday after the last night: nothing in 21-22 March.
        expect(
          s.occurrences(
            const CivilDate(2026, 3, 21),
            const CivilDate(2026, 3, 22),
          ),
          isEmpty,
        );
        // Range starting the day after a night begins: that night is excluded.
        final occ = s.occurrences(
          const CivilDate(2026, 3, 17),
          const CivilDate(2026, 3, 17),
        );
        expect(occ.single.date, const CivilDate(2026, 3, 17));
      },
    );

    test('rest and absence types without times produce nothing', () {
      final s = Schedule(
        shiftTypes: allTypes,
        entries: {
          jan1: const DayEntry(date: jan1, shiftTypeIds: ['rest', 'vacation']),
        },
      );
      expect(s.occurrences(jan1, jan1), isEmpty);
    });

    test('several shifts in one day give several occurrences in order', () {
      final s = Schedule(
        shiftTypes: allTypes,
        entries: {
          jan1: const DayEntry(
            date: jan1,
            shiftTypeIds: ['afternoon', 'morning'],
          ),
        },
      );
      expect(s.occurrences(jan1, jan1).map((o) => o.shiftType.id), [
        'afternoon',
        'morning',
      ]);
    });
  });
}
