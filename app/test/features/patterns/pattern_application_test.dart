import 'package:cuadrante/features/patterns/domain/pattern_application.dart';
import 'package:cuadrante/features/patterns/domain/pattern_catalog.dart';
import 'package:cuadrante/features/patterns/domain/post_night.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

ShiftType t(String key) => shiftTemplateByKey(key).toShiftType(key);

Schedule emptySchedule({
  Iterable<String> keys = const [
    'morning',
    'afternoon',
    'night',
    'rest',
    'guard24',
    'postNight',
    'vacation',
    'day12',
    'night12',
  ],
  Iterable<PatternRun> runs = const [],
  Map<CivilDate, DayEntry> entries = const {},
}) => Schedule(
  shiftTypes: [for (final k in keys) t(k)],
  runs: runs,
  entries: entries,
);

Pattern preset(String id) =>
    patternPresetById(id)
        .materialize({for (final k in shiftTemplates) k.key: k.key});

const d = CivilDate(2026, 6, 1);

void main() {
  group('postNight rules', () {
    test('what ends next morning', () {
      expect(endsNextMorning(t('night')), isTrue);
      expect(endsNextMorning(t('night12')), isTrue);
      expect(endsNextMorning(t('guard24')), isTrue);
      expect(endsNextMorning(t('afternoon')), isFalse);
      expect(endsNextMorning(t('morning')), isFalse);
      expect(endsNextMorning(t('postNight')), isFalse);
      // Crosses midnight but ends in the afternoon: not a "saliente" case.
      expect(
        endsNextMorning(
          const ShiftType(
            id: 'x',
            code: 'X',
            name: 'X',
            colorValue: 0xFF000000,
            category: ShiftCategory.work,
            startMinute: 20 * 60,
            endMinute: 14 * 60,
          ),
        ),
        isFalse,
      );
    });

    test('Libre is the plain rest day only', () {
      expect(isLibre(t('rest')), isTrue);
      expect(isLibre(t('postNight')), isFalse);
      expect(isLibre(t('vacation')), isFalse);
      expect(isLibre(t('morning')), isFalse);
    });

    test('custom grey rest survives automatic saliente; recoloured Libre is still Libre', () {
      final libre = t('rest');
      final compensation = libre.copyWith(
        id: 'holiday-compensation',
        code: 'CF',
        name: 'Compensación de festivo',
      );
      expect(isLibre(compensation), isFalse);
      expect(
        isLibre(libre.copyWith(colorValue: 0xFF123456, name: 'Descanso')),
        isTrue,
      );
      final next = d.addDays(1);
      final schedule = Schedule(
        shiftTypes: [t('night'), libre, compensation, t('postNight')],
        entries: {
          d: DayEntry(date: d, shiftTypeIds: const ['night']),
          next: DayEntry(
            date: next,
            shiftTypeIds: [compensation.id],
            note: 'Conservar',
          ),
        },
      );
      expect(postNightDays(schedule, [d]), isEmpty);
      expect(postNightPatch(schedule, [d]).isEmpty, isTrue);
      expect(schedule.resolve(next).shiftIds, [compensation.id]);
      expect(schedule.resolve(next).note, 'Conservar');
    });

    test('empty and Libre next days are taken, nothing else', () {
      final s = emptySchedule(
        entries: {
          d: DayEntry(date: d, shiftTypeIds: const ['night']),
          d.addDays(2): DayEntry(
            date: d.addDays(2),
            shiftTypeIds: const ['night'],
          ),
          d.addDays(3): DayEntry(
            date: d.addDays(3),
            shiftTypeIds: const ['rest'],
          ),
          d.addDays(4): DayEntry(
            date: d.addDays(4),
            shiftTypeIds: const ['night'],
          ),
          d.addDays(5): DayEntry(
            date: d.addDays(5),
            shiftTypeIds: const ['vacation'],
          ),
          d.addDays(6): DayEntry(
            date: d.addDays(6),
            shiftTypeIds: const ['night'],
          ),
          d.addDays(7): DayEntry(
            date: d.addDays(7),
            shiftTypeIds: const ['morning'],
          ),
        },
      );
      final days = postNightDays(s, [for (var i = 0; i < 7; i++) d.addDays(i)]);
      // d+1 is empty; d+3 is Libre; d+5 is a vacation; d+7 a morning.
      expect(days, {d.addDays(1), d.addDays(3)});
    });

    test('combinePatches keeps the first "before" and the last "after"', () {
      final a = DayEntry(date: d, shiftTypeIds: const ['night']);
      final b = DayEntry(date: d, shiftTypeIds: const ['morning']);
      final first = EntriesPatch({
        d: EntryChange(null, a),
        d.addDays(1): EntryChange(null, a.copyWith()),
      });
      final second = EntriesPatch({
        d: EntryChange(a, b),
        d.addDays(2): const EntryChange(null, null),
      });
      final both = combinePatches(first, second);
      expect(both.changes[d], EntryChange(null, b));
      expect(both.changes.containsKey(d.addDays(2)), isFalse);
      expect(both.changes.containsKey(d.addDays(1)), isTrue);
      // A change that comes back to the start disappears.
      final undone = combinePatches(
        first,
        EntriesPatch({d: EntryChange(a, null)}),
      );
      expect(undone.changes.containsKey(d), isFalse);
    });
  });

  group('planPatternApplication', () {
    test('plain: the new run and nothing else', () {
      final s = emptySchedule().copyWith(patterns: [preset('6x4')]);
      final plan = planPatternApplication(
        s,
        PatternRequest(pattern: preset('6x4'), from: d),
        seq: 7,
      );
      expect(plan.newTypes, isEmpty);
      expect(plan.newPattern, isNull);
      expect(plan.change.runsAfter!.single.seq, 7);
      expect(plan.change.patch.isEmpty, isTrue);
      expect(plan.schedule.resolve(d).shiftIds, ['morning']);
      expect(plan.schedule.resolve(d.addDays(6)).shiftIds, ['rest']);
    });

    test('missing template types and an unknown pattern are planned', () {
      final s = emptySchedule(keys: const ['rest']);
      final plan = planPatternApplication(
        s,
        PatternRequest(pattern: preset('dupont'), from: d, stepOffset: 4),
        seq: 1,
      );
      expect(plan.newTypes.map((x) => x.id), ['night12', 'day12']);
      expect(plan.newPattern?.id, 'dupont');
      expect(plan.schedule.shiftTypeById('night12')?.code, 'N12');
      // stepOffset 4 on a 28-day cycle starts on the third rest day.
      expect(plan.schedule.resolve(d).shiftIds, ['rest']);
      expect(plan.schedule.resolve(d.addDays(3)).shiftIds, ['day12']);
    });

    test('unknown ids that are no template are left to the engine', () {
      final s = emptySchedule();
      final plan = planPatternApplication(
        s,
        const PatternRequest(
          pattern: Pattern(
            id: 'p',
            name: 'P',
            steps: [
              ['ghost'],
              ['morning'],
            ],
          ),
          from: d,
        ),
        seq: 1,
      );
      expect(plan.newTypes, isEmpty);
      expect(plan.schedule.resolve(d).isEmpty, isTrue);
      expect(plan.schedule.resolve(d.addDays(1)).shiftIds, ['morning']);
    });

    test('with the saliente on, G L L L from d gives G S L L', () {
      final s = emptySchedule();
      final plan = planPatternApplication(
        s,
        PatternRequest(pattern: preset('24x72'), from: d, until: d.addDays(11)),
        seq: 1,
        postNightAuto: true,
      );
      final codes = [
        for (var i = 0; i < 12; i++)
          plan.schedule.resolve(d.addDays(i)).shifts.map((x) => x.code).join(),
      ];
      expect(codes.join(' '), 'G S L L G S L L G S L L');
      expect(plan.postNightDays, {d.addDays(1), d.addDays(5), d.addDays(9)});
      // One change, exactly invertible.
      final back = plan.schedule.apply(plan.change.inverse());
      expect(back.runs, s.runs);
      expect(back.entries, s.entries);
    });

    test('with the saliente off nothing is added', () {
      final plan = planPatternApplication(
        emptySchedule(),
        PatternRequest(pattern: preset('24x72'), from: d, until: d.addDays(11)),
        seq: 1,
      );
      expect(plan.postNightDays, isEmpty);
      expect(plan.change.patch.isEmpty, isTrue);
    });

    test('a pattern that already has its saliente (12h) adds none', () {
      final plan = planPatternApplication(
        emptySchedule(),
        PatternRequest(pattern: preset('12h'), from: d, until: d.addDays(7)),
        seq: 1,
        postNightAuto: true,
      );
      expect(plan.postNightDays, isEmpty);
    });

    test('the saliente type is created, or respected when archived', () {
      final noSaliente = emptySchedule(
        keys: const ['night', 'rest', 'morning', 'afternoon', 'guard24'],
      );
      final created = planPatternApplication(
        noSaliente,
        PatternRequest(pattern: preset('24x72'), from: d, until: d.addDays(7)),
        seq: 1,
        postNightAuto: true,
      );
      expect(created.newTypes.map((x) => x.id), contains('postNight'));
      expect(created.postNightDays, isNotEmpty);

      final archived = planPatternApplication(
        emptySchedule(),
        PatternRequest(pattern: preset('24x72'), from: d, until: d.addDays(7)),
        seq: 1,
        postNightAuto: true,
        palette: [t('guard24'), t('rest')],
      );
      expect(archived.postNightDays, isEmpty);
    });

    test('the saliente type is not created when no saliente is produced', () {
      final noSaliente = emptySchedule(
        keys: const ['morning', 'afternoon', 'rest'],
      );
      final plan = planPatternApplication(
        noSaliente,
        PatternRequest(pattern: preset('5x2'), from: d, until: d.addDays(13)),
        seq: 1,
        postNightAuto: true,
      );
      expect(plan.postNightDays, isEmpty);
      expect(plan.newTypes.map((x) => x.id), isNot(contains('postNight')));
      expect(plan.schedule.shiftTypeById('postNight'), isNull);
    });

    test('open end: the saliente is only looked for a year ahead', () {
      final plan = planPatternApplication(
        emptySchedule(),
        PatternRequest(pattern: preset('24x72'), from: d),
        seq: 1,
        postNightAuto: true,
      );
      expect(plan.postNightDays.length, inInclusiveRange(90, 92));
      expect(
        plan.postNightDays.last.differenceInDays(d),
        lessThanOrEqualTo(366),
      );
    });

    test('hand-made days are respected, replaced when asked', () {
      final day = d.addDays(2);
      final s = emptySchedule(
        entries: {
          day: DayEntry(date: day, shiftTypeIds: const ['vacation']),
        },
      );
      PatternApplication plan(bool clear) => planPatternApplication(
        s,
        PatternRequest(
          pattern: preset('6x4'),
          from: d,
          until: d.addDays(9),
          clearOverrides: clear,
        ),
        seq: 1,
      );
      expect(plan(false).schedule.resolve(day).shiftIds, ['vacation']);
      expect(plan(true).schedule.resolve(day).shiftIds, ['morning']);
    });
  });

  group('catalogue', () {
    test('every preset is in exactly one group', () {
      final all = [for (final ids in patternGroupPresets.values) ...ids];
      expect(all.toSet(), hasLength(all.length));
      expect(ungroupedPresets(), isEmpty, reason: 'every preset is grouped');
      expect(all.toSet(), {for (final p in patternPresets) p.id});
    });

    test('typical patterns by first shift', () {
      List<String> startingWith(String id) => [
        for (final p in patternPresets)
          if (startsWithShift(p.steps, id)) p.id,
      ];
      // No preset begins with the plain Noche; two include it.
      expect(startingWith('night'), isEmpty);
      expect(
        [
          for (final p in patternPresets)
            if (containsShift(p.steps, 'night')) p.id,
        ],
        ['correturnos', 'continental'],
      );
      expect(startingWith('guard24'), ['24x72']);
      expect(startingWith('night12'), ['dupont']);
      expect(
        startingWith('morning'),
        containsAll(['6x4', '5x2', 'continental']),
      );
    });
  });
}
