import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

const _d = CivilDate(2026, 1, 12);

ShiftType _type(String id, {String? code}) => ShiftType(
  id: id,
  code: code ?? id,
  name: id,
  colorValue: 0xFF000000,
  category: ShiftCategory.work,
);

void main() {
  final m = _type('m');
  final t = _type('t');
  final n = _type('n');

  Schedule schedule({
    List<PatternRun>? runs,
    Map<CivilDate, DayEntry> entries = const {},
    List<List<String>>? steps,
  }) => Schedule(
    shiftTypes: [m, t, n],
    patterns: [
      Pattern(
        id: 'p',
        name: 'p',
        steps:
            steps ??
            const [
              ['m'],
              ['t'],
              [],
            ],
      ),
    ],
    runs:
        runs ??
        const [
          PatternRun(
            id: 'r',
            patternId: 'p',
            startDate: CivilDate(2026, 1, 1),
            seq: 1,
          ),
        ],
    entries: entries,
  );

  group('Pattern / PatternRun', () {
    test('step index uses stepOffset and is never negative', () {
      const run = PatternRun(
        id: 'r',
        patternId: 'p',
        startDate: CivilDate(2026, 1, 10),
        stepOffset: 2,
        seq: 1,
      );
      expect(run.stepIndexOn(const CivilDate(2026, 1, 10), 5), 2);
      expect(run.stepIndexOn(const CivilDate(2026, 1, 13), 5), 0);
      expect(run.stepIndexOn(const CivilDate(2026, 1, 20), 5), 2);
      // Dates before the start still map into 0..len-1.
      expect(
        run.stepIndexOn(const CivilDate(2026, 1, 1), 5),
        isIn([0, 1, 2, 3, 4]),
      );
      expect(run.stepIndexOn(const CivilDate(2026, 1, 1), 5), 3);
    });

    test('covers honours inclusive start and end', () {
      const run = PatternRun(
        id: 'r',
        patternId: 'p',
        startDate: CivilDate(2026, 1, 10),
        endDate: CivilDate(2026, 1, 12),
        seq: 1,
      );
      expect(run.covers(const CivilDate(2026, 1, 9)), isFalse);
      expect(run.covers(const CivilDate(2026, 1, 10)), isTrue);
      expect(run.covers(const CivilDate(2026, 1, 12)), isTrue);
      expect(run.covers(const CivilDate(2026, 1, 13)), isFalse);
    });

    test('DayEntry.isEmpty and equality', () {
      expect(const DayEntry(date: _d).isEmpty, isTrue);
      expect(const DayEntry(date: _d, note: 'x').isEmpty, isFalse);
      expect(const DayEntry(date: _d, shiftTypeIds: []).isEmpty, isFalse);
      expect(
        const DayEntry(date: _d, shiftTypeIds: ['a', 'b']),
        const DayEntry(date: _d, shiftTypeIds: ['a', 'b']),
      );
      expect(
        const DayEntry(date: _d, shiftTypeIds: ['a', 'b']) ==
            const DayEntry(date: _d, shiftTypeIds: ['b', 'a']),
        isFalse,
      );
      expect(
        const DayEntry(date: _d) == const DayEntry(date: _d, shiftTypeIds: []),
        isFalse,
      );
    });
  });

  group('resolve', () {
    test('pattern gives the shift of the cycle step with run info', () {
      final s = schedule();
      final r = s.resolve(const CivilDate(2026, 1, 2));
      expect(r.source, DaySource.pattern);
      expect(r.shiftIds, ['t']);
      expect(r.runId, 'r');
      expect(r.stepIndex, 1);
      expect(s.resolve(const CivilDate(2026, 1, 3)).shifts, isEmpty);
      expect(s.resolve(const CivilDate(2026, 1, 3)).source, DaySource.pattern);
    });

    test('no run: empty with source none', () {
      final r = Schedule(shiftTypes: [m]).resolve(_d);
      expect(r.source, DaySource.none);
      expect(r.shifts, isEmpty);
      expect(r.runId, isNull);
    });

    test('override beats pattern', () {
      final s = schedule(
        entries: {
          _d: const DayEntry(date: _d, shiftTypeIds: ['n']),
        },
      );
      final r = s.resolve(_d);
      expect(r.source, DaySource.override);
      expect(r.shiftIds, ['n']);
      expect(r.runId, isNull);
      expect(s.resolvePattern(_d).source, DaySource.pattern);
    });

    test('empty override list empties a day with pattern', () {
      final s = schedule(
        entries: {_d: const DayEntry(date: _d, shiftTypeIds: [])},
      );
      expect(s.resolve(_d).source, DaySource.override);
      expect(s.resolve(_d).shifts, isEmpty);
    });

    test('note without override does not cover the pattern', () {
      final s = schedule(
        entries: {jan1: const DayEntry(date: jan1, note: 'dentist')},
      );
      final r = s.resolve(jan1);
      expect(r.source, DaySource.pattern);
      expect(r.shifts, isNotEmpty);
      expect(r.note, 'dentist');
    });

    test('note is kept with an override and on days without pattern', () {
      final s = schedule(
        entries: {
          _d: const DayEntry(date: _d, shiftTypeIds: ['n'], note: 'swap'),
          const CivilDate(2025, 1, 1): const DayEntry(
            date: CivilDate(2025, 1, 1),
            note: 'old',
          ),
        },
      );
      expect(s.resolve(_d).note, 'swap');
      final r = s.resolve(const CivilDate(2025, 1, 1));
      expect(r.source, DaySource.none);
      expect(r.note, 'old');
    });

    test('run with the highest seq wins, regardless of list order', () {
      const low = PatternRun(
        id: 'low',
        patternId: 'p',
        startDate: CivilDate(2026, 1, 1),
        seq: 1,
      );
      const high = PatternRun(
        id: 'high',
        patternId: 'q',
        startDate: CivilDate(2026, 1, 5),
        endDate: CivilDate(2026, 1, 8),
        seq: 2,
      );
      for (final runs in [
        [low, high],
        [high, low],
      ]) {
        final s = Schedule(
          shiftTypes: [m, t, n],
          patterns: const [
            Pattern(
              id: 'p',
              name: 'p',
              steps: [
                ['m'],
              ],
            ),
            Pattern(
              id: 'q',
              name: 'q',
              steps: [
                ['n'],
              ],
            ),
          ],
          runs: runs,
        );
        expect(s.resolve(const CivilDate(2026, 1, 4)).runId, 'low');
        expect(s.resolve(const CivilDate(2026, 1, 5)).runId, 'high');
        expect(s.resolve(const CivilDate(2026, 1, 8)).shiftIds, ['n']);
        expect(s.resolve(const CivilDate(2026, 1, 9)).runId, 'low');
      }
    });

    test('unknown ids are ignored in overrides and in patterns', () {
      final s = schedule(
        steps: [
          ['m', 'ghost'],
          ['ghost'],
        ],
        entries: {
          _d: const DayEntry(date: _d, shiftTypeIds: ['ghost', 't', 'zzz']),
        },
      );
      expect(s.resolve(_d).shiftIds, ['t']);
      expect(s.resolve(const CivilDate(2026, 1, 1)).shiftIds, ['m']);
      expect(s.resolve(const CivilDate(2026, 1, 2)).shifts, isEmpty);
    });

    test('a run whose pattern was deleted is skipped', () {
      final s = schedule(
        runs: const [
          PatternRun(
            id: 'a',
            patternId: 'p',
            startDate: CivilDate(2026, 1, 1),
            seq: 1,
          ),
          PatternRun(
            id: 'b',
            patternId: 'gone',
            startDate: CivilDate(2026, 1, 1),
            seq: 2,
          ),
        ],
      );
      expect(s.resolve(const CivilDate(2026, 1, 1)).runId, 'a');
    });

    test('several shifts per day keep the stored order', () {
      final s = schedule(
        steps: [
          ['n', 'm'],
        ],
        entries: {
          _d: const DayEntry(date: _d, shiftTypeIds: ['t', 'n', 'm']),
        },
      );
      expect(s.resolve(_d).shiftIds, ['t', 'n', 'm']);
      expect(s.resolve(const CivilDate(2026, 1, 1)).shiftIds, ['n', 'm']);
    });
  });

  group('resolveRange', () {
    test('one entry per day, both ends included', () {
      final s = schedule();
      final days = s.resolveRange(
        const CivilDate(2026, 1, 1),
        const CivilDate(2026, 1, 7),
      );
      expect(days.length, 7);
      expect(days.first.date, const CivilDate(2026, 1, 1));
      expect(days.last.date, const CivilDate(2026, 1, 7));
      expect(days.map((d) => d.shiftIds.join()), [
        'm',
        't',
        '',
        'm',
        't',
        '',
        'm',
      ]);
      expect(
        s.resolveRange(
          const CivilDate(2026, 1, 7),
          const CivilDate(2026, 1, 1),
        ),
        isEmpty,
      );
      expect(s.resolveRange(_d, _d).length, 1);
    });

    test('matches resolve and is fast enough for 400 days', () {
      final s = presetSchedule('correturnos', jan1);
      final to = jan1.addDays(399);
      final sw = Stopwatch()..start();
      final days = s.resolveRange(jan1, to);
      sw.stop();
      expect(days.length, 400);
      for (final d in days) {
        expect(d.shiftIds, s.resolve(d.date).shiftIds);
      }
      expect(sw.elapsedMilliseconds, lessThan(50));
    });
  });

  group('ShiftType', () {
    test('duration: 0 means 24 h, crossesMidnight and missing times', () {
      ShiftType of(int? a, int? b) => ShiftType(
        id: 'x',
        code: 'X',
        name: 'x',
        colorValue: 0,
        category: ShiftCategory.work,
        startMinute: a,
        endMinute: b,
      );
      expect(of(480, 480).durationMinutes, 1440);
      expect(of(480, 480).crossesMidnight, isTrue);
      expect(of(360, 840).durationMinutes, 480);
      expect(of(360, 840).crossesMidnight, isFalse);
      expect(of(1320, 360).durationMinutes, 480);
      expect(of(1320, 360).crossesMidnight, isTrue);
      expect(of(null, null).durationMinutes, 0);
      expect(of(null, null).hasTimes, isFalse);
      expect(of(null, null).crossesMidnight, isFalse);
    });

    test('paid minutes default to the duration; copyWith', () {
      final g = shiftTemplateByKey('guard24').toShiftType('g');
      expect(g.effectivePaidMinutes, 1440);
      final paid = g.copyWith(paidMinutes: 1380, nightOverride: true);
      expect(paid.effectivePaidMinutes, 1380);
      expect(paid.nightOverride, isTrue);
      expect(
        paid.copyWith(clearPaidMinutes: true, clearNightOverride: true),
        g,
      );
      expect(g.copyWith(clearTimes: true).hasTimes, isFalse);
      expect(g.copyWith(name: 'Otra').name, 'Otra');
      expect(g.copyWith(), g);
    });
  });
}
