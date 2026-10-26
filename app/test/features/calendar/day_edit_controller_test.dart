import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/probes.dart';
import '../../support/test_storage.dart';

final _now = DateTime(2026, 10, 19, 12);
const _today = CivilDate(2026, 10, 19);

// Demo data (docs: schedule_demo): rotation "correturnos" from 13 Jul.
//   19-23 Oct Noche, 24-25 Libre, 26-30 Mañana, 31 Oct-1 Nov Libre.
// Overrides: 20 note only ("Cambio con Marta si sale el turno"),
// 21 Mañana + Tarde, 22 empty, 27 and 28 Vacaciones.
const _noteOnly = CivilDate(2026, 10, 20);
const _doubled = CivilDate(2026, 10, 21);
const _emptied = CivilDate(2026, 10, 22);
const _rest = CivilDate(2026, 10, 24);
const _morning = CivilDate(2026, 10, 26);
const _beforeRotation = CivilDate(2026, 6, 10);
const _demoNote = 'Cambio con Marta si sale el turno';

void main() {
  late TestStorage storage;
  late ProviderContainer container;

  Future<ProviderContainer> makeContainer({
    ScheduleRepository? repository,
  }) async {
    final c = ProviderContainer(
      overrides: [
        ...storage.overrides,
        clockProvider.overrideWithValue(() => _now),
        if (repository != null)
          scheduleRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      await c.read(scheduleControllerProvider.notifier).pendingWrites;
      c.dispose();
    });
    return c;
  }

  ScheduleController controller() =>
      container.read(scheduleControllerProvider.notifier);
  ScheduleState state() => container.read(scheduleControllerProvider);
  Schedule schedule() => state().schedule;
  DayEntry? entry(CivilDate d) => schedule().entries[d];

  /// What is stored right now, as the app would load it.
  Future<Schedule> stored() async {
    await controller().pendingWrites;
    return (await storage.repository.load(mainCalendarId)).schedule;
  }

  Future<void> expectStoredEqualsMemory() async {
    expectSameSchedule(await stored(), schedule());
  }

  setUp(() async {
    storage = await TestStorage.open(now: _now);
    addTearDown(storage.close);
    container = await makeContainer();
  });

  group('setNote continuing a typing session', () {
    const day = CivilDate(2026, 10, 24);

    test(
      'the saves of one session are one undo step, all of them written',
      () async {
        expect(entry(day), isNull);
        controller().setNote(day, 'a');
        controller().setNote(day, 'ab', continuesTyping: true);
        expect(state().canUndo, isTrue);
        controller().setNote(day, 'abc', continuesTyping: true);
        expect(entry(day)?.note, 'abc');
        await expectStoredEqualsMemory();

        controller().undo();
        expect(entry(day), isNull);
        expect(state().canUndo, isFalse);
        await expectStoredEqualsMemory();

        controller().redo();
        expect(entry(day)?.note, 'abc');
        await expectStoredEqualsMemory();
      },
    );

    test('without continuesTyping every save is its own step', () async {
      controller().setNote(day, 'a');
      controller().setNote(day, 'ab');
      controller().undo();
      expect(entry(day)?.note, 'a');
      expect(state().canUndo, isTrue);
    });

    test('another edit in between ends the session', () async {
      controller().setNote(day, 'a');
      controller().setDayShifts(day, ['morning']);
      controller().setNote(day, 'ab', continuesTyping: true);
      controller().undo();
      expect(entry(day)?.note, 'a');
      expect(entry(day)?.shiftTypeIds, ['morning']);
    });

    test('a session on another day does not join', () async {
      const other = CivilDate(2026, 10, 25);
      controller().setNote(day, 'a');
      controller().setNote(other, 'b', continuesTyping: true);
      controller().undo();
      expect(entry(other), isNull);
      expect(entry(day)?.note, 'a');
    });

    test('text back to how it was leaves no step', () async {
      controller().setNote(day, 'a');
      controller().setNote(day, null, continuesTyping: true);
      expect(entry(day), isNull);
      expect(state().canUndo, isFalse);
      await expectStoredEqualsMemory();
    });
  });

  group('setDayShifts', () {
    test('replaces the shifts, keeps the note, undo gives back the exact '
        'entry', () async {
      final before = entry(_noteOnly);
      expect(before, DayEntry(date: _noteOnly, note: _demoNote));

      controller().setDayShifts(_noteOnly, ['morning', 'afternoon']);
      expect(
        entry(_noteOnly),
        DayEntry(
          date: _noteOnly,
          shiftTypeIds: const ['morning', 'afternoon'],
          note: _demoNote,
        ),
      );
      expect(schedule().resolve(_noteOnly).shiftIds, ['morning', 'afternoon']);
      expect(state().canUndo, isTrue);
      await expectStoredEqualsMemory();

      controller().undo();
      expect(entry(_noteOnly), before);
      await expectStoredEqualsMemory();
      expect(state().canUndo, isFalse);

      controller().redo();
      expect(entry(_noteOnly)?.shiftTypeIds, ['morning', 'afternoon']);
      await expectStoredEqualsMemory();
    });

    test(
      'an override equal to the rotation is not stored (the note stays)',
      () async {
        // The rotation gives Noche on the 20th: asking for it is no override.
        controller().setDayShifts(_noteOnly, ['night']);
        expect(entry(_noteOnly), DayEntry(date: _noteOnly, note: _demoNote));
        expect(state().canUndo, isFalse, reason: 'nothing changed');

        // A manual day that goes back to what the rotation gives is dropped.
        expect(entry(_doubled)?.shiftTypeIds, ['morning', 'afternoon']);
        controller().setDayShifts(_doubled, ['night']);
        expect(entry(_doubled), isNull);
        expect(schedule().resolve(_doubled).source, DaySource.pattern);
        await expectStoredEqualsMemory();

        controller().undo();
        expect(entry(_doubled)?.shiftTypeIds, ['morning', 'afternoon']);
        await expectStoredEqualsMemory();
      },
    );

    test('order matters: the same shifts reversed are an override', () async {
      controller().setDayShifts(_doubled, ['afternoon', 'morning']);
      expect(schedule().resolve(_doubled).shiftIds, ['afternoon', 'morning']);
      await expectStoredEqualsMemory();
    });

    test('duplicates and unknown ids are dropped', () async {
      controller().setDayShifts(_rest, ['guard24', 'ghost', 'guard24']);
      expect(entry(_rest)?.shiftTypeIds, ['guard24']);
      await expectStoredEqualsMemory();
    });

    test('empty list: an empty override on a rotation day, nothing before '
        'the rotation', () async {
      controller().clearDay(_morning);
      expect(entry(_morning)?.shiftTypeIds, isEmpty);
      expect(schedule().resolve(_morning).isEmpty, isTrue);

      controller().clearDay(_beforeRotation); // already empty
      expect(entry(_beforeRotation), isNull);
      await expectStoredEqualsMemory();

      controller().undo();
      expect(entry(_morning), isNull);
      expect(schedule().resolve(_morning).shiftIds, ['morning']);
      await expectStoredEqualsMemory();
    });

    test('one call is one undo step, also after painting', () async {
      controller()
        ..beginStroke(const PaintTool.replace('guard24'))
        ..paintDay(_rest)
        ..endStroke();
      controller().setDayShifts(_rest, ['vacation']);
      controller().setNote(_rest, 'Playa');
      expect(schedule().resolve(_rest).shiftIds, ['vacation']);
      expect(schedule().resolve(_rest).note, 'Playa');

      controller().undo(); // the note
      expect(schedule().resolve(_rest).note, isNull);
      expect(schedule().resolve(_rest).shiftIds, ['vacation']);
      controller().undo(); // the shifts
      expect(schedule().resolve(_rest).shiftIds, ['guard24']);
      controller().undo(); // the stroke
      expect(schedule().resolve(_rest).shiftIds, ['rest']);
      expect(state().canUndo, isFalse);
      await expectStoredEqualsMemory();
    });

    test('closes a stroke left open instead of losing it', () async {
      controller()
        ..beginStroke(const PaintTool.replace('guard24'))
        ..paintDay(_rest);
      controller().setDayShifts(_morning, ['vacation']);
      expect(controller().strokeActive, isFalse);
      expect(schedule().resolve(_rest).shiftIds, ['guard24']);
      expect(schedule().resolve(_morning).shiftIds, ['vacation']);
      controller().undo();
      controller().undo();
      expect(schedule().resolve(_rest).shiftIds, ['rest']);
      expect(schedule().resolve(_morning).shiftIds, ['morning']);
    });
  });

  group('setNote', () {
    test(
      'adds a note to a day without entry; undo removes the entry',
      () async {
        expect(entry(_rest), isNull);
        controller().setNote(_rest, 'Cumple de Ana \u{1F382}\nllevar tarta');
        expect(
          entry(_rest),
          DayEntry(date: _rest, note: 'Cumple de Ana \u{1F382}\nllevar tarta'),
        );
        expect(
          entry(_rest)?.shiftTypeIds,
          isNull,
          reason: 'rotation untouched',
        );
        expect(schedule().resolve(_rest).shiftIds, ['rest']);
        await expectStoredEqualsMemory();

        controller().undo();
        expect(entry(_rest), isNull);
        await expectStoredEqualsMemory();
      },
    );

    test('keeps the shifts of an override', () async {
      controller().setNote(_doubled, 'Doble turno');
      expect(entry(_doubled)?.shiftTypeIds, ['morning', 'afternoon']);
      expect(entry(_doubled)?.note, 'Doble turno');
      await expectStoredEqualsMemory();
    });

    test('a blank note removes it; an entry left empty disappears', () async {
      controller().setNote(_noteOnly, '   \n ');
      expect(entry(_noteOnly), isNull);
      expect(schedule().resolve(_noteOnly).note, isNull);
      await expectStoredEqualsMemory();

      controller().undo();
      expect(entry(_noteOnly)?.note, _demoNote);
      await expectStoredEqualsMemory();
    });

    test('a blank note keeps the override of the day', () async {
      controller().setNote(_doubled, 'x');
      controller().setNote(_doubled, null);
      expect(
        entry(_doubled),
        DayEntry(date: _doubled, shiftTypeIds: const ['morning', 'afternoon']),
      );
    });

    test('the note is trimmed and an unchanged note is not a step', () async {
      controller().setNote(_rest, '  hola  ');
      expect(entry(_rest)?.note, 'hola');
      controller().undo();
      controller().redo();
      controller().setNote(_rest, 'hola'); // same
      controller().setNote(_rest, ' hola\n'); // same once trimmed
      controller().undo(); // the one and only step
      expect(entry(_rest), isNull);
      expect(state().canUndo, isFalse);
    });

    test(
      'painting a day keeps its note (the editor and the brush agree)',
      () async {
        controller().setNote(_rest, 'nota');
        controller()
          ..beginStroke(const PaintTool.replace('guard24'))
          ..paintDay(_rest)
          ..endStroke();
        expect(entry(_rest)?.note, 'nota');
        expect(entry(_rest)?.shiftTypeIds, ['guard24']);
      },
    );
  });

  group('resetToPattern', () {
    test('drops the override, keeps the note, undo brings it back', () async {
      controller().setNote(_doubled, 'con nota');
      controller().resetToPattern(_doubled);
      expect(entry(_doubled), DayEntry(date: _doubled, note: 'con nota'));
      expect(schedule().resolve(_doubled).shiftIds, ['night']);
      await expectStoredEqualsMemory();

      controller().undo();
      expect(entry(_doubled)?.shiftTypeIds, ['morning', 'afternoon']);
      expect(entry(_doubled)?.note, 'con nota');
      await expectStoredEqualsMemory();
    });

    test('removes the whole entry when there was no note', () async {
      controller().resetToPattern(_emptied); // an empty override
      expect(entry(_emptied), isNull);
      expect(schedule().resolve(_emptied).shiftIds, ['night']);
      await expectStoredEqualsMemory();
    });

    test('does nothing without an override', () async {
      controller().resetToPattern(_rest);
      controller().resetToPattern(_noteOnly); // note only
      expect(state().canUndo, isFalse);
      expect(entry(_noteOnly)?.note, _demoNote);
    });
  });

  group('copyDay', () {
    test('copies the effective shifts and the note, normalized against the '
        'target rotation', () async {
      // The 21st shows Mañana + Tarde (override), the 24th is Libre.
      controller().setNote(_doubled, 'Doble');
      controller().copyDay(_doubled, _rest);
      expect(schedule().resolve(_rest).shiftIds, ['morning', 'afternoon']);
      expect(schedule().resolve(_rest).note, 'Doble');
      await expectStoredEqualsMemory();

      controller().undo();
      expect(entry(_rest), isNull);
      await expectStoredEqualsMemory();
    });

    test('copying a rotation day onto a day with the same rotation shift '
        'stores no override', () async {
      // 19th and 23rd are both Noche by the rotation.
      controller().copyDay(_today, const CivilDate(2026, 10, 23));
      expect(entry(const CivilDate(2026, 10, 23)), isNull);
      expect(state().canUndo, isFalse);
    });

    test('a source without note leaves the note of the target', () async {
      controller().copyDay(_morning, _noteOnly);
      expect(schedule().resolve(_noteOnly).shiftIds, ['morning']);
      expect(schedule().resolve(_noteOnly).note, _demoNote);
      await expectStoredEqualsMemory();
    });

    test('copying a day onto itself does nothing', () async {
      controller().copyDay(_doubled, _doubled);
      expect(state().canUndo, isFalse);
    });

    test('returns the step it pushed, or null when nothing changed', () {
      expect(controller().copyDay(_doubled, _doubled), isNull);
      // 19th and 23rd are both Noche by the rotation: nothing to store.
      expect(
        controller().copyDay(_today, const CivilDate(2026, 10, 23)),
        isNull,
      );
      final step = controller().copyDay(_doubled, _rest);
      expect(step, isNotNull);
      expect(step!.patch.changes.keys, [_rest]);
    });

    test('undoIfLast only undoes that exact step, while it is the last', () {
      final copy = controller().copyDay(_doubled, _rest)!;
      controller().setDayShifts(_morning, ['guard24']); // a later step

      expect(controller().undoIfLast(copy), isFalse);
      expect(schedule().resolve(_morning).shiftIds, ['guard24']);
      expect(schedule().resolve(_rest).shiftIds, ['morning', 'afternoon']);

      controller().undo(); // the later step goes
      expect(controller().undoIfLast(copy), isTrue);
      expect(entry(_rest), isNull);
      expect(state().canUndo, isFalse);

      // Already undone: a second tap does nothing.
      expect(controller().undoIfLast(copy), isFalse);
    });

    test('an empty source empties the target', () async {
      controller().copyDay(_emptied, _morning);
      expect(entry(_morning)?.shiftTypeIds, isEmpty);
      await expectStoredEqualsMemory();
    });
  });

  group('write queue', () {
    test('one write per edit, in order, one at a time', () async {
      final probe = ProbeRepository(
        storage.database,
        now: () => _now,
        delay: (call) => Duration(milliseconds: call == 0 ? 50 : 5),
      );
      container = await makeContainer(repository: probe);

      controller().setDayShifts(_rest, ['guard24']);
      controller().setNote(_rest, 'a');
      controller().resetToPattern(_rest);
      controller().copyDay(_doubled, _rest);
      controller().undo();
      await controller().pendingWrites;

      expect(probe.calls, hasLength(5));
      expect(probe.finished, [0, 1, 2, 3, 4]);
      expect(probe.maxActive, 1);
      await expectStoredEqualsMemory();
    });

    test('edits that change nothing write nothing', () async {
      final probe = ProbeRepository(storage.database, now: () => _now);
      container = await makeContainer(repository: probe);
      controller().setNote(_rest, null);
      controller().setDayShifts(_rest, ['rest']);
      controller().resetToPattern(_rest);
      await controller().pendingWrites;
      expect(probe.calls, isEmpty);
    });

    test(
      'a failed write reloads what is stored and drops the history',
      () async {
        final probe = ProbeRepository(
          storage.database,
          now: () => _now,
          failCalls: {0},
        );
        container = await makeContainer(repository: probe);
        final before = schedule();

        controller().setDayShifts(_rest, ['guard24']);
        expect(schedule().resolve(_rest).shiftIds, ['guard24']);
        await controller().pendingWrites;

        expect(state().saveErrors, 1);
        expect(state().canUndo, isFalse);
        expectSameSchedule(schedule(), before);
      },
    );

    test('the edits survive reopening the database', () async {
      controller().setDayShifts(_rest, ['guard24']);
      controller().setNote(_rest, 'Guardia con Lucía');
      controller().copyDay(_rest, _morning);
      await controller().pendingWrites;
      final inMemory = schedule();

      final reopened = await storage.withReloadedSnapshot();
      expectSameSchedule(reopened.snapshot.schedule, inMemory);
    });
  });

  group('shift types', () {
    ShiftType newType({String id = 'extra', String code = 'X'}) => ShiftType(
      id: id,
      code: code,
      name: 'Extra',
      colorValue: 0xFF1C7ED6,
      category: ShiftCategory.work,
      startMinute: 9 * 60,
      endMinute: 13 * 60,
      hourlyRateCents: 1250,
    );

    test('a new shift type goes last in the palette and is stored', () async {
      final count = state().palette.length;
      controller().saveShiftType(newType());
      expect(state().palette.length, count + 1);
      expect(state().palette.last.id, 'extra');
      expect(schedule().shiftTypeById('extra')?.hourlyRateCents, 1250);
      await expectStoredEqualsMemory();
      final snapshot = await storage.repository.load(mainCalendarId);
      expect(
        [for (final t in snapshot.palette) t.id],
        [for (final t in state().palette) t.id],
      );
    });

    test('editing keeps its place and the days that use it follow', () async {
      final index = state().palette.indexWhere((t) => t.id == 'afternoon');
      final edited = schedule()
          .shiftTypeById('afternoon')!
          .copyWith(
            name: 'Tarde larga',
            colorValue: 0xFFD6336C,
            hourlyRateCents: 900,
          );
      controller().saveShiftType(edited);
      expect(state().palette[index], edited);
      expect(schedule().resolve(_doubled).shifts.last, edited);
      await expectStoredEqualsMemory();
    });

    test('editing does not touch the undo history', () async {
      controller().setDayShifts(_rest, ['guard24']);
      controller().saveShiftType(
        schedule().shiftTypeById('guard24')!.copyWith(name: 'Guardia'),
      );
      expect(state().canUndo, isTrue);
      controller().undo();
      expect(schedule().resolve(_rest).shiftIds, ['rest']);
      await expectStoredEqualsMemory();
    });

    test('archiving leaves the palette but days keep showing it', () async {
      controller().archiveShiftType('vacation');
      expect(state().palette.any((t) => t.id == 'vacation'), isFalse);
      expect(schedule().shiftTypeById('vacation'), isNotNull);
      expect(schedule().resolve(const CivilDate(2026, 10, 27)).shiftIds, [
        'vacation',
      ]);
      await expectStoredEqualsMemory();
      final snapshot = await storage.repository.load(mainCalendarId);
      expect(snapshot.palette.any((t) => t.id == 'vacation'), isFalse);
      expect(snapshot.schedule.shiftTypeById('vacation'), isNotNull);
    });

    test('an archived type can still be edited and stays archived', () async {
      controller().archiveShiftType('vacation');
      controller().saveShiftType(
        schedule().shiftTypeById('vacation')!.copyWith(name: 'Vacas'),
      );
      expect(state().palette.any((t) => t.id == 'vacation'), isFalse);
      expect(schedule().shiftTypeById('vacation')?.name, 'Vacas');
      await expectStoredEqualsMemory();
    });

    test('reorder writes the new palette order', () async {
      final ids = [for (final t in state().palette) t.id];
      final reordered = [ids.last, ...ids.take(ids.length - 1)];
      controller().reorderShiftTypes(reordered);
      expect([for (final t in state().palette) t.id], reordered);
      await expectStoredEqualsMemory();
      final snapshot = await storage.repository.load(mainCalendarId);
      expect([for (final t in snapshot.palette) t.id], reordered);
    });

    test('reorder ignores a list that is not the palette', () async {
      final before = [for (final t in state().palette) t.id];
      controller().reorderShiftTypes(before.take(2).toList());
      controller().reorderShiftTypes([...before.skip(1), 'ghost']);
      controller().reorderShiftTypes([...before.skip(1), before[1]]);
      controller().reorderShiftTypes(before); // same order: nothing to do
      expect([for (final t in state().palette) t.id], before);
    });

    test(
      'shift type edits and day edits keep their order in the queue',
      () async {
        final probe = ProbeRepository(
          storage.database,
          now: () => _now,
          delay: (call) => Duration(milliseconds: call == 0 ? 40 : 1),
        );
        container = await makeContainer(repository: probe);
        controller().saveShiftType(newType());
        controller().setDayShifts(_rest, ['extra']);
        controller().archiveShiftType('extra');
        await controller().pendingWrites;

        expect(probe.finished, [0], reason: 'the day edit is the only apply');
        expect(schedule().resolve(_rest).shiftIds, ['extra']);
        await expectStoredEqualsMemory();
        final snapshot = await storage.repository.load(mainCalendarId);
        expect(snapshot.palette.any((t) => t.id == 'extra'), isFalse);
      },
    );
  });
}
