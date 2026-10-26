import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('shift templates', () {
    test('palette, schedule and category of the spec', () {
      expect(shiftTemplates.map((t) => t.key), [
        'morning',
        'afternoon',
        'night',
        'rest',
        'guard24',
        'postNight',
        'vacation',
        'personalDay',
        'day12',
        'night12',
      ]);
      ShiftType t(String key) => shiftTemplateByKey(key).toShiftType(key);
      expect(t('morning').colorValue, 0xFFF5A524);
      expect(t('morning').durationMinutes, 480);
      expect(t('afternoon').colorValue, 0xFFF06A3F);
      expect(t('night').colorValue, 0xFF4B4FD1);
      expect(t('night').crossesMidnight, isTrue);
      expect(t('rest').colorValue, 0xFFE4E4E7);
      expect(t('rest').hasTimes, isFalse);
      expect(t('guard24').durationMinutes, 1440);
      expect(t('guard24').colorValue, 0xFFE5484D);
      expect(t('postNight').category, ShiftCategory.rest);
      expect(t('vacation').category, ShiftCategory.absence);
      expect(t('personalDay').code, 'LD');
      expect(t('personalDay').name, 'Libre disposición');
      expect(t('day12').durationMinutes, 720);
      expect(t('night12').code, 'N12');
      expect(t('night12').durationMinutes, 720);
    });
  });

  group('pattern presets', () {
    test('catalogue', () {
      expect(patternPresets.map((p) => p.id), [
        'correturnos',
        '24x72',
        '12h',
        '6x4',
        '4x4',
        '5x2',
        '2-2-3',
        'continental',
        'dupont',
      ]);
      expect(patternPresetById('correturnos').suggestedStart, DateTime.monday);
      expect(patternPresetById('5x2').suggestedStart, DateTime.monday);
      expect(patternPresetById('24x72').suggestedStart, isNull);
    });

    test('materialize maps keys to ids and fails on a missing key', () {
      final p = patternPresetById('12h').materialize({
        'day12': 'a',
        'night12': 'b',
        'postNight': 'c',
        'rest': 'd',
      });
      expect(p.id, '12h');
      expect(p.steps, [
        ['a'],
        ['b'],
        ['c'],
        ['d'],
      ]);
      expect(
        () => patternPresetById('12h').materialize({'day12': 'a'}),
        throwsArgumentError,
      );
    });

    // (preset, cycle length, work days, rest days per cycle)
    const specs = [
      ('correturnos', 21, 15, 6),
      ('24x72', 4, 1, 3),
      ('12h', 4, 2, 2),
      ('6x4', 10, 6, 4),
      ('4x4', 8, 4, 4),
      ('5x2', 7, 5, 2),
      ('2-2-3', 14, 7, 7),
      ('continental', 28, 21, 7),
      ('dupont', 28, 14, 14),
    ];

    for (final (id, length, work, rest) in specs) {
      group(id, () {
        final preset = patternPresetById(id);

        test('cycle length, worked and rest days', () {
          expect(preset.lengthDays, length);
          expect(presetPattern(id).lengthDays, length);
          final s = presetSchedule(id, jan1);
          final days = s.resolveRange(jan1, jan1.addDays(length - 1));
          expect(days.every((d) => d.shifts.length == 1), isTrue);
          int count(ShiftCategory c) =>
              days.where((d) => d.shifts.single.category == c).length;
          expect(count(ShiftCategory.work), work);
          expect(count(ShiftCategory.rest), rest);
        });

        test('repeats exactly every cycle', () {
          final s = presetSchedule(id, jan1);
          final first = idsOf(s, jan1, length);
          for (final n in [1, 2, 7, 13]) {
            expect(idsOf(s, jan1.addDays(n * length), length), first);
          }
        });

        test('stepOffset shifts the cycle', () {
          final base = idsOf(presetSchedule(id, jan1), jan1, length);
          for (final off in [1, length - 1, length + 2]) {
            final s = presetSchedule(id, jan1, stepOffset: off);
            expect(s.resolve(jan1).stepIndex, off % length);
            final shifted = [
              for (var i = 0; i < length; i++) base[(i + off) % length],
            ];
            expect(idsOf(s, jan1, length), shifted);
          }
        });

        test('empty before the start and after endDate', () {
          final s = presetSchedule(id, jan1, end: jan1.addDays(2 * length - 1));
          expect(s.resolve(jan1.addDays(-1)).source, DaySource.none);
          expect(s.resolve(jan1.addDays(-30)).isEmpty, isTrue);
          expect(s.resolve(jan1.addDays(2 * length - 1)).isEmpty, isFalse);
          expect(s.resolve(jan1.addDays(2 * length)).source, DaySource.none);
          expect(s.resolve(jan1.addDays(2 * length + 40)).isEmpty, isTrue);
        });
      });
    }

    test('correturnos exact sequence from Monday 5-Jan-2026', () {
      const monday = CivilDate(2026, 1, 5);
      expect(monday.weekday, DateTime.monday);
      final s = presetSchedule('correturnos', monday);
      expect(
        codesOf(s, monday, 22),
        'M M M M M L L T T T T T L L N N N N N L L M',
      );
    });

    test('24x72 guards on 1, 5, 9 January 2026', () {
      final s = presetSchedule('24x72', jan1);
      expect(codesOf(s, jan1, 10), 'G L L L G L L L G L');
      for (final day in [1, 5, 9, 13, 17, 21, 25, 29]) {
        expect(s.resolve(CivilDate(2026, 1, day)).shifts.single.id, 'guard24');
      }
      expect(s.resolve(const CivilDate(2026, 1, 2)).shifts.single.id, 'rest');
      // Across the March DST change the cadence does not move.
      const mar = CivilDate(2026, 3, 29);
      final guards = [for (var i = 0; i < 12; i++) mar.addDays(i)]
          .where((d) => s.resolve(d).shifts.single.id == 'guard24')
          .toList();
      for (final g in guards) {
        expect(g.differenceInDays(jan1) % 4, 0);
      }
      expect(guards.length, 3);
    });

    test('24x72 with stepOffset 1 starts on a rest day', () {
      final s = presetSchedule('24x72', jan1, stepOffset: 1);
      expect(codesOf(s, jan1, 8), 'L L L G L L L G');
    });

    test('12h: day, night, post-night, rest', () {
      final s = presetSchedule('12h', jan1);
      expect(codesOf(s, jan1, 8), 'D N12 S L D N12 S L');
    });

    test('6x4', () {
      expect(
        codesOf(presetSchedule('6x4', jan1), jan1, 11),
        'M M M M M M L L L L M',
      );
    });

    test('4x4', () {
      expect(
        codesOf(presetSchedule('4x4', jan1), jan1, 9),
        'D D D D L L L L D',
      );
    });

    test('5x2 from Monday', () {
      const monday = CivilDate(2026, 1, 5);
      final s = presetSchedule('5x2', monday);
      expect(codesOf(s, monday, 8), 'M M M M M L L M');
      expect(s.resolve(const CivilDate(2026, 1, 10)).shifts.single.id, 'rest');
    });

    test('2-2-3', () {
      expect(
        codesOf(presetSchedule('2-2-3', jan1), jan1, 15),
        'D D L L D D D L L D D L L L D',
      );
    });

    test('continental exact sequence (28 days, blocks of 2 and 3)', () {
      expect(
        codesOf(presetSchedule('continental', jan1), jan1, 28),
        'M M T T N N N L L M M T T T N N L L M M M T T N N L L L',
      );
      // The cycle closes: day 29 is a morning again.
      expect(
        codesOf(presetSchedule('continental', jan1), jan1.addDays(28), 3),
        'M M T',
      );
    });

    test('continental never goes backwards: no N or T followed by M', () {
      final s = presetSchedule('continental', jan1);
      final days = s.resolveRange(jan1, jan1.addDays(56));
      for (var i = 0; i < days.length - 1; i++) {
        final a = days[i].shifts.single.id;
        final b = days[i + 1].shifts.single.id;
        if (b == 'morning') {
          expect(a, isNot(anyOf('night', 'afternoon')), reason: 'day $i');
        }
        if (b == 'afternoon') expect(a, isNot('night'), reason: 'day $i');
      }
    });

    test('continental: four crews 7 days apart cover M, T and N every day', () {
      final crews = [
        for (final offset in [0, 7, 14, 21])
          presetSchedule('continental', jan1, stepOffset: offset),
      ];
      for (var i = 0; i < 60; i++) {
        final day = jan1.addDays(i);
        final ids = [for (final c in crews) c.resolve(day).shifts.single.id]
          ..sort();
        expect(ids, ['afternoon', 'morning', 'night', 'rest'], reason: '$day');
      }
    });

    test('dupont exact sequence (12 h, 28 days)', () {
      expect(
        codesOf(presetSchedule('dupont', jan1), jan1, 28),
        'N12 N12 N12 N12 L L L D D D L N12 N12 N12 L L L D D D D '
        'L L L L L L L',
      );
      final types = {for (final t in allTypes) t.id: t};
      expect(types['day12']!.durationMinutes, 720);
      expect(types['night12']!.durationMinutes, 720);
    });

    test('dupont: four crews 7 days apart keep a day and a night shift', () {
      final crews = [
        for (final offset in [0, 7, 14, 21])
          presetSchedule('dupont', jan1, stepOffset: offset),
      ];
      for (var i = 0; i < 56; i++) {
        final day = jan1.addDays(i);
        final ids = [for (final c in crews) c.resolve(day).shifts.single.id];
        expect(ids.where((id) => id == 'day12'), hasLength(1), reason: '$day');
        expect(
          ids.where((id) => id == 'night12'),
          hasLength(1),
          reason: '$day',
        );
      }
    });

    test('2-2-3 is also the 2-2-3-2-2-3: one preset, no duplicate', () {
      expect(patternPresets.where((p) => p.steps.length == 14), hasLength(1));
      expect(patternPresetById('2-2-3').description, contains('2-2-3-2-2-3'));
      // Two weeks of 2 on, 2 off, 3 on, 2 on... as the name reads.
      expect(
        codesOf(presetSchedule('2-2-3', jan1), jan1, 14),
        'D D L L D D D L L D D L L L',
      );
    });
  });
}
