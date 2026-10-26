import 'package:cuadrante/features/import/domain/event_grouping.dart';
import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:cuadrante/features/import/domain/import_plan.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/shift_types/domain/shift_type_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import 'import_support.dart';

const _d = CivilDate(2026, 10, 19);

const _toMorning = {
  'manana': MapToType('morning'),
  'noche': MapToType('night'),
};

ImportPlan plan(
  Schedule schedule,
  List<EventOccurrence> events, {
  Map<String, GroupMapping> mappings = _toMorning,
  ConflictPolicy policy = ConflictPolicy.replace,
}) => buildImportPlan(
  schedule: schedule,
  occurrences: events,
  mappings: mappings,
  policy: policy,
);

String ids(Schedule s, CivilDate d) => s.resolve(d).shiftIds.join('+');

void main() {
  group('imported note blocks', () {
    test('a substring of a different note is appended', () {
      expect(
        mergeImportedNote(
          'No cambiar el turno',
          'cambiar el turno',
          ConflictPolicy.replace,
        ),
        'No cambiar el turno\ncambiar el turno',
      );
      expect(
        mergeImportedNote('Cambio largo', 'Cambio', ConflictPolicy.replace),
        'Cambio largo\nCambio',
      );
    });

    test('the same note and re-imported appended blocks stay unchanged', () {
      const imported = 'Llevar informe';
      expect(
        mergeImportedNote(imported, imported, ConflictPolicy.replace),
        imported,
      );
      final merged = mergeImportedNote(
        'Nota local',
        imported,
        ConflictPolicy.replace,
      );
      expect(merged, 'Nota local\nLlevar informe');
      expect(
        mergeImportedNote(merged, imported, ConflictPolicy.replace),
        merged,
      );
      final withAnother = mergeImportedNote(
        merged,
        'Otra nota',
        ConflictPolicy.replace,
      );
      expect(
        mergeImportedNote(withAnother, imported, ConflictPolicy.replace),
        withAnother,
      );
    });

    test('a multiline imported block stays intact and idempotent', () {
      const imported = 'Llevar informe\nHablar con Ana';
      final merged = mergeImportedNote(
        'Nota local',
        imported,
        ConflictPolicy.replace,
      );
      expect(merged, 'Nota local\nLlevar informe\nHablar con Ana');
      expect(
        mergeImportedNote(merged, imported, ConflictPolicy.replace),
        merged,
      );
      expect(
        mergeImportedNote(
          '$merged\nOtra nota',
          imported,
          ConflictPolicy.replace,
        ),
        '$merged\nOtra nota',
      );
    });

    test('both boundaries of a multiline note must be whole lines', () {
      const imported = 'Llevar informe\nHablar con Ana';
      for (final existing in [
        'No $imported',
        '$imported mañana',
      ]) {
        expect(
          mergeImportedNote(existing, imported, ConflictPolicy.replace),
          '$existing\n$imported',
        );
      }
    });
  });

  group('mapping', () {
    test('events become overrides on empty days', () {
      final p = plan(emptySchedule(), [
        timed('Mañana', _d, 6, 14),
        timed('Noche', _d.addDays(1), 22, 6),
      ]);
      expect(p.written, 2);
      expect(p.conflicts, 0);
      expect(ids(p.result, _d), 'morning');
      expect(ids(p.result, _d.addDays(1)), 'night');
      expect(p.change.runsAfter, isNull, reason: 'no runs touched');
      expect(p.change.patch.changes[_d]!.before, isNull);
      expect(p.change.patch.changes[_d]!.after!.shiftTypeIds, ['morning']);
    });

    test('titles match by normalized key, ignored groups are skipped', () {
      final p = plan(
        emptySchedule(),
        [
          timed('MAÑANA ', _d, 6, 14),
          timed('Cita médico', _d.addDays(1), 9, 10),
          timed('Sin grupo', _d.addDays(2), 9, 10),
        ],
        mappings: {
          'manana': const MapToType('morning'),
          'cita medico': const IgnoreGroup(),
        },
      );
      expect(p.written, 1);
      expect(p.ignoredEvents, 2);
      expect(ids(p.result, _d.addDays(1)), '');
    });

    test('two events on a day give two shifts in time order, no repeats', () {
      final p = plan(
        emptySchedule(),
        [
          timed('Noche', _d, 22, 6),
          timed('Mañana', _d, 6, 14),
          timed('Mañana', _d, 7, 15),
          allDay('Libre', _d),
        ],
        mappings: {..._toMorning, 'libre': const MapToType('rest')},
      );
      // All-day first, then by start time.
      expect(ids(p.result, _d), 'rest+morning+night');
    });

    test('an unknown shift type id is treated as ignored', () {
      final p = plan(
        emptySchedule(),
        [timed('Mañana', _d, 6, 14)],
        mappings: {'manana': const MapToType('does-not-exist')},
      );
      expect(p.isEmpty, isTrue);
      expect(p.ignoredEvents, 1);
    });
  });

  group('normalization against the rotation', () {
    final pattern = Pattern(
      id: 'p',
      name: 'M N',
      steps: const [
        ['morning'],
        ['night'],
      ],
    );
    final run = PatternRun(id: 'run-1', patternId: 'p', startDate: _d, seq: 1);

    test('events equal to the rotation write nothing', () {
      final schedule = emptySchedule(patterns: [pattern], runs: [run]);
      final p = plan(schedule, [
        timed('Mañana', _d, 6, 14),
        timed('Noche', _d.addDays(1), 22, 6),
      ]);
      expect(p.isEmpty, isTrue);
      expect(p.unchanged, 2);
      expect(p.conflicts, 0);
    });

    test('a day that differs from the rotation is a conflict', () {
      final schedule = emptySchedule(patterns: [pattern], runs: [run]);
      // The rotation says Mañana on the 19th and Noche on the 20th.
      final replace = plan(schedule, [timed('Noche', _d, 22, 6)]);
      expect(replace.conflicts, 1);
      expect(replace.conflictDates, [_d]);
      expect(replace.written, 1);
      expect(ids(replace.result, _d), 'night');

      final keep = plan(schedule, [
        timed('Noche', _d, 22, 6),
      ], policy: ConflictPolicy.keep);
      expect(keep.conflicts, 1);
      expect(keep.kept, 1);
      expect(keep.written, 0);
      expect(ids(keep.result, _d), 'morning');
    });

    test('an override that equals the rotation is dropped, the note stays', () {
      // The 19th has a hand-painted Noche and a note; the file says Mañana,
      // which is what the rotation gives.
      final schedule = emptySchedule(
        patterns: [pattern],
        runs: [run],
        entries: {
          _d: DayEntry(date: _d, shiftTypeIds: const ['night'], note: 'cambio'),
        },
      );
      final p = plan(schedule, [timed('Mañana', _d, 6, 14)]);
      final after = p.change.patch.changes[_d]!.after!;
      expect(after.shiftTypeIds, isNull, reason: 'back to the rotation');
      expect(after.note, 'cambio');
      expect(ids(p.result, _d), 'morning');
    });

    test('the note of an overwritten day is kept', () {
      final schedule = emptySchedule(
        entries: {_d: DayEntry(date: _d, note: 'ojo')},
      );
      final p = plan(schedule, [timed('Mañana', _d, 6, 14)]);
      expect(p.change.patch.changes[_d]!.after!.note, 'ojo');
      expect(p.result.resolve(_d).note, 'ojo');
      expect(p.conflicts, 0, reason: 'a note alone is not a shift');
    });
  });

  group('what the day holds besides its shifts', () {
    const annotated = DayEntry(
      date: _d,
      note: 'ojo',
      noteReminderMinute: 450,
      overtimeMinutes: 60,
      earlyLeaveMinutes: 15,
    );

    test(
      'the reminder, overtime and early leave of an overwritten day stay',
      () {
        final schedule = emptySchedule(entries: {_d: annotated});
        final p = plan(schedule, [timed('Mañana', _d, 6, 14)]);
        final after = p.change.patch.changes[_d]!.after!;
        expect(after.shiftTypeIds, ['morning']);
        expect(after.note, 'ojo');
        expect(after.noteReminderMinute, 450);
        expect(after.overtimeMinutes, 60);
        expect(after.earlyLeaveMinutes, 15);
      },
    );

    test('an override that equals the rotation is dropped but a day with '
        'only overtime is kept', () {
      final pattern = Pattern(
        id: 'p',
        name: 'M N',
        steps: const [
          ['morning'],
          ['night'],
        ],
      );
      final run = PatternRun(
        id: 'run-1',
        patternId: 'p',
        startDate: _d,
        seq: 1,
      );
      final schedule = emptySchedule(
        patterns: [pattern],
        runs: [run],
        entries: {
          _d: const DayEntry(
            date: _d,
            shiftTypeIds: ['night'],
            overtimeMinutes: 30,
          ),
        },
      );
      final p = plan(schedule, [timed('Mañana', _d, 6, 14)]);
      expect(
        p.change.patch.changes[_d]!.after,
        const DayEntry(date: _d, overtimeMinutes: 30),
      );
    });
  });

  group('conflicts', () {
    final schedule = emptySchedule(
      entries: {
        _d: DayEntry(date: _d, shiftTypeIds: const ['afternoon']),
        _d.addDays(1): DayEntry(date: _d.addDays(1), shiftTypeIds: const []),
        _d.addDays(2): DayEntry(
          date: _d.addDays(2),
          shiftTypeIds: const ['morning'],
        ),
      },
    );
    final events = [
      timed('Mañana', _d, 6, 14), // over Tarde
      timed('Mañana', _d.addDays(1), 6, 14), // over an empty override
      timed('Mañana', _d.addDays(2), 6, 14), // equal
      timed('Mañana', _d.addDays(3), 6, 14), // free day
    ];

    test('replace', () {
      final p = plan(schedule, events);
      expect(p.conflicts, 1, reason: 'only the day with other shifts');
      expect(p.unchanged, 1);
      expect(p.kept, 0);
      expect(p.written, 3);
      expect(p.changedDates, [_d, _d.addDays(1), _d.addDays(3)]);
      for (final i in [0, 1, 3]) {
        expect(ids(p.result, _d.addDays(i)), 'morning');
      }
    });

    test('keep leaves the busy days alone and still fills the free ones', () {
      final p = plan(schedule, events, policy: ConflictPolicy.keep);
      expect(p.conflicts, 1);
      expect(p.kept, 1);
      expect(p.written, 2);
      expect(ids(p.result, _d), 'afternoon');
      expect(ids(p.result, _d.addDays(1)), 'morning');
      expect(ids(p.result, _d.addDays(3)), 'morning');
    });
  });

  group('new shift types', () {
    ShiftTypeDraft draft(String code) => ShiftTypeDraft(
      code: code,
      name: 'Refuerzo',
      colorValue: 0xFF123456,
      startMinute: 9 * 60,
      endMinute: 17 * 60,
    );

    test('are created with the change and used by the days', () {
      final p = plan(
        emptySchedule(),
        [timed('Refuerzo', _d, 9, 17), timed('Refuerzo', _d.addDays(1), 9, 17)],
        mappings: {'refuerzo': CreateType('new-1', draft('R'))},
      );
      expect(p.newTypes, hasLength(1));
      final type = p.newTypes.single;
      expect(type.id, 'new-1');
      expect(type.code, 'R');
      expect(type.startMinute, 9 * 60);
      expect(ids(p.result, _d), 'new-1');
      expect(p.result.shiftTypeById('new-1'), type);
    });

    test('a type no written day uses is not created', () {
      final schedule = emptySchedule(
        entries: {
          _d: DayEntry(date: _d, shiftTypeIds: const ['morning']),
        },
      );
      final p = plan(
        schedule,
        [timed('Refuerzo', _d, 9, 17)],
        mappings: {'refuerzo': CreateType('new-1', draft('R'))},
        policy: ConflictPolicy.keep,
      );
      expect(p.newTypes, isEmpty);
      expect(p.isEmpty, isTrue);
    });

    test('a draft that cannot be a shift type imports nothing (no crash)', () {
      for (final bad in [
        draft(''),
        draft('ABCD'),
        draft('R').copyWith(name: ' '),
      ]) {
        final p = plan(
          emptySchedule(),
          [timed('Refuerzo', _d, 9, 17)],
          mappings: {'refuerzo': CreateType('new-1', bad)},
        );
        expect(p.isEmpty, isTrue);
        expect(p.newTypes, isEmpty);
      }
    });
  });

  group('undo', () {
    test('the inverse of the change restores the schedule exactly', () {
      final schedule = emptySchedule(
        entries: {
          _d: DayEntry(date: _d, shiftTypeIds: const ['afternoon'], note: 'x'),
        },
      );
      final p = plan(schedule, [
        timed('Mañana', _d, 6, 14),
        timed('Mañana', _d.addDays(1), 6, 14),
      ]);
      final back = p.result.apply(p.change.inverse());
      expect(back.entries, schedule.entries);
    });
  });

  test('a big import is fast', () {
    final events = [
      for (var i = 0; i < 5000; i++)
        timed('Mañana', _d.addDays(i % 800), 6, 14),
    ];
    final watch = Stopwatch()..start();
    final p = plan(emptySchedule(), events);
    expect(p.written, 800);
    expect(watch.elapsedMilliseconds, lessThan(2000));
  });

  test('normalizeTitle keys line up with grouping keys', () {
    final groups = groupEvents([timed('Mañana ', _d, 6, 14)]);
    expect(groups.single.key, 'manana');
  });
}
