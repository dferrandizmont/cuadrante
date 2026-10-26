import 'package:cuadrante/features/import/domain/event_grouping.dart';
import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:cuadrante/features/import/domain/mapping_suggestions.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/shift_types/domain/shift_type_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import 'import_support.dart';

const _d = CivilDate(2026, 10, 19);

EventGroup groupOf(List<EventOccurrence> items, String key) =>
    groupEvents(items).firstWhere((g) => g.key == key);

void main() {
  group('normalizeTitle', () {
    test('case, accents, blanks and decoration do not matter', () {
      for (final title in [
        'Mañana',
        'mañana',
        'MAÑANA',
        '  Mañana  ',
        'Manana',
        'Mañana ☀',
        '🌞 Mañana!',
        'mañana ',
      ]) {
        expect(normalizeTitle(title), 'manana', reason: title);
      }
    });

    test('inner blanks collapse and the words stay', () {
      expect(normalizeTitle('  Turno   de  Mañana '), 'turno de manana');
      expect(normalizeTitle('Libre disposición'), 'libre disposicion');
    });

    test('symbols alone are kept, empty stays empty', () {
      expect(normalizeTitle('+'), '+');
      expect(normalizeTitle('   '), '');
      expect(normalizeTitle(''), '');
    });
  });

  group('groupEvents', () {
    final items = [
      for (final d in daysFrom(_d, 5)) timed('Mañana', d, 6, 14),
      timed('mañana', _d.addDays(6), 6, 14),
      timed(' MAÑANA ', _d.addDays(7), 7, 15),
      for (final d in daysFrom(_d.addDays(10), 3)) timed('Noche', d, 22, 6),
      allDay('Libre', _d.addDays(20)),
      allDay('Libre', _d.addDays(21)),
      timed('M', _d.addDays(30), 6, 14),
    ];
    final groups = groupEvents(items);

    test('one group per normalized title, biggest first', () {
      expect(groups.map((g) => g.key), ['manana', 'noche', 'libre', 'm']);
      expect(groups.map((g) => g.count), [7, 3, 2, 1]);
    });

    test('shows the most common spelling', () {
      expect(groups.first.title, 'Mañana');
    });

    test('typical times are the most common start and end', () {
      final morning = groups.first;
      expect(morning.startMinute, 6 * 60);
      expect(morning.endMinute, 14 * 60);
      expect(morning.timedCount, 7);
      expect(morning.hasTimes, isTrue);
      final nightGroup = groups[1];
      expect(nightGroup.startMinute, 22 * 60);
      expect(nightGroup.endMinute, 6 * 60);
    });

    test('an all-day group has no times', () {
      final libre = groupOf(items, 'libre');
      expect(libre.hasTimes, isFalse);
      expect(libre.allDayCount, 2);
    });

    test('sample dates: first, middle and last', () {
      expect(groups.first.sampleDates.first, _d);
      expect(groups.first.sampleDates.last, _d.addDays(7));
      expect(groups.first.sampleDates, hasLength(3));
      expect(groupOf(items, 'm').sampleDates, [_d.addDays(30)]);
    });

    test('the result does not depend on the order of the events', () {
      final reversed = groupEvents(items.reversed);
      expect(reversed.map((g) => g.key), groups.map((g) => g.key));
      expect(reversed.first.title, groups.first.title);
      expect(reversed.first.startMinute, groups.first.startMinute);
    });

    test('no events, no groups', () {
      expect(groupEvents(const []), isEmpty);
    });

    test('a day with two shifts of the same title counts once', () {
      final group = groupOf([
        timed('Mañana', _d, 6, 14),
        timed('Mañana', _d, 15, 23),
        timed('Mañana', _d.addDays(1), 6, 14),
      ], 'manana');
      expect(group.count, 2);
      expect(group.timedCount, 3);
    });
  });

  group('suggestMapping', () {
    EventGroup group(String title, {int n = 5, int start = 6, int end = 14}) =>
        groupOf([
          for (final d in daysFrom(_d, n)) timed(title, d, start, end),
        ], normalizeTitle(title));

    test('by name', () {
      final s = suggestMapping(group('Mañana'), baseTypes)!;
      expect(s.type.id, 'morning');
      expect(s.reason, SuggestionReason.name);
    });

    test('by code', () {
      final s = suggestMapping(group('M'), baseTypes)!;
      expect(s.type.id, 'morning');
      expect(s.reason, SuggestionReason.code);
    });

    test('a title that contains the name or the code', () {
      expect(
        suggestMapping(group('Turno mañana'), baseTypes)!.type.id,
        'morning',
      );
      expect(suggestMapping(group('Turno T'), baseTypes)!.type.id, 'afternoon');
    });

    test('a short title inside a longer name', () {
      const guard = ShiftType(
        id: 'guard',
        code: 'G',
        name: 'Guardia 24 h',
        colorValue: 0xFFE5484D,
        category: ShiftCategory.work,
        startMinute: 480,
        endMinute: 480,
      );
      final s = suggestMapping(
        groupOf([timed('Guardia', _d, 8, 8)], 'guardia'),
        [...baseTypes, guard],
      )!;
      expect(s.type.id, 'guard');
      expect(s.reason, SuggestionReason.similar);
    });

    test('by hours only, for a recurring group', () {
      final s = suggestMapping(group('Currar'), baseTypes)!;
      expect(s.type.id, 'morning');
      expect(s.reason, SuggestionReason.times);
    });

    test('hours within half an hour still match', () {
      final s = suggestMapping(group('Currar', start: 6, end: 14), [
        morning.copyWith(startMinute: 6 * 60 + 15, endMinute: 14 * 60 + 15),
      ])!;
      expect(s.reason, SuggestionReason.times);
    });

    test('a few days at the right hours are not enough', () {
      expect(suggestMapping(group('Dentista', n: 2), baseTypes), isNull);
    });

    test('different hours and an unknown title give nothing', () {
      expect(
        suggestMapping(group('Currar', start: 9, end: 17), baseTypes),
        isNull,
      );
    });

    test('an all-day title matches a type without times by name', () {
      final libre = groupOf([allDay('Libre', _d)], 'libre');
      expect(suggestMapping(libre, baseTypes)!.type.id, 'rest');
    });

    test('the name beats the hours', () {
      final s = suggestMapping(group('Tarde', start: 6, end: 14), baseTypes)!;
      expect(s.type.id, 'afternoon');
    });

    test('nothing to choose from', () {
      expect(suggestMapping(group('Mañana'), const []), isNull);
    });
  });

  group('draftFromGroup', () {
    test('name, hours, a free code and a free colour', () {
      final draft = draftFromGroup(
        groupOf([
          for (final d in daysFrom(_d, 3)) timed('Refuerzo', d, 9, 17),
        ], 'refuerzo'),
        existing: baseTypes,
        palette: [0xFFF5A524, 0xFF111111, 0xFF222222],
      );
      expect(draft.name, 'Refuerzo');
      expect(draft.code, 'R');
      expect(draft.hasTimes, isTrue);
      expect(draft.startMinute, 9 * 60);
      expect(draft.endMinute, 17 * 60);
      expect(draft.category, ShiftCategory.work);
      // 0xFFF5A524 is Mañana's.
      expect(draft.colorValue, 0xFF111111);
    });

    test('a short title is the code', () {
      final draft = draftFromGroup(
        groupOf([timed('ld', _d, 8, 16)], 'ld'),
        existing: baseTypes,
      );
      expect(draft.code, 'LD');
    });

    test('a code already taken moves on', () {
      final draft = draftFromGroup(
        groupOf([timed('Mixto', _d, 8, 16)], 'mixto'),
        existing: baseTypes,
      );
      expect(draft.code, 'MI');
    });

    test('two drafts of one import do not share a code or a colour', () {
      final first = draftFromGroup(
        groupOf([timed('Refuerzo', _d, 8, 16)], 'refuerzo'),
        existing: baseTypes,
        palette: [1, 2, 3],
      );
      final second = draftFromGroup(
        groupOf([timed('Relevo', _d, 8, 16)], 'relevo'),
        existing: baseTypes,
        alsoTaken: [first],
        palette: [1, 2, 3],
      );
      expect(second.code, isNot(first.code));
      expect(second.colorValue, isNot(first.colorValue));
    });

    test('the colour of the events is used when it is free', () {
      final draft = draftFromGroup(
        groupOf([
          timed('Refuerzo', _d, 8, 16, colorValue: 0xFF123456),
        ], 'refuerzo'),
        existing: baseTypes,
        palette: [1],
      );
      expect(draft.colorValue, 0xFF123456);
    });

    test('an all-day group becomes a shift without hours; rest and absence words are recognised', () {
      ShiftTypeDraft of(String title) => draftFromGroup(
        groupOf([allDay(title, _d)], normalizeTitle(title)),
        existing: const [],
      );
      expect(of('Descanso').hasTimes, isFalse);
      expect(of('Descanso').category, ShiftCategory.rest);
      expect(of('Vacaciones').category, ShiftCategory.absence);
      expect(of('Baja médica').category, ShiftCategory.absence);
      expect(of('Refuerzo').category, ShiftCategory.work);
    });

    test('long names are cut and an empty title gets the fallback', () {
      final long = draftFromGroup(
        groupEvents([
          allDay('Un nombre larguísimo que no cabe en veinticuatro', _d),
        ]).single,
        existing: const [],
      );
      expect(long.name.length, lessThanOrEqualTo(maxShiftNameLength));
      final empty = draftFromGroup(
        groupEvents([allDay('', _d)]).single,
        existing: const [],
        fallbackName: 'Turno',
      );
      expect(empty.name, 'Turno');
      expect(empty.code, isNotEmpty);
      expect(empty.validate(), isEmpty);
    });
  });
}
