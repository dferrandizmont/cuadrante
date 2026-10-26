import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/application/selection_controller.dart';
import 'package:cuadrante/features/calendar/domain/range_editing.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/patterns/application/post_night_provider.dart';
import 'package:cuadrante/features/patterns/domain/post_night.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';

final _now = DateTime(2026, 10, 19, 12);

// Demo data around Monday 19 Oct 2026 (see day_edit_controller_test.dart):
// rotation "correturnos" (21-day cycle) from Mon 13 Jul, so every 21 days it
// repeats: 19-23 Oct Noche, 24-25 Libre, 26-30 Mañana, 31 Oct-1 Nov Libre,
// 2-6 Nov Tarde... and 9 Nov is a Noche Monday again. Manual days: 20 note
// only, 21 Mañana + Tarde, 22 empty, 27-28 Vacaciones.
const _oct19 = CivilDate(2026, 10, 19);
const _oct20 = CivilDate(2026, 10, 20); // note only
const _oct21 = CivilDate(2026, 10, 21); // Mañana + Tarde
const _oct22 = CivilDate(2026, 10, 22); // empty override
const _oct23 = CivilDate(2026, 10, 23);
const _oct24 = CivilDate(2026, 10, 24); // Libre
const _oct25 = CivilDate(2026, 10, 25); // Libre (clocks go back at night)
const _oct26 = CivilDate(2026, 10, 26);
const _oct27 = CivilDate(2026, 10, 27); // Vacaciones
const _nov9 = CivilDate(2026, 11, 9); // Noche Monday: 21 days after the 19th
const _demoNote = 'Cambio con Marta si sale el turno';

List<CivilDate> _days(CivilDate from, int count) => [
  for (var i = 0; i < count; i++) from.addDays(i),
];

void main() {
  late TestStorage storage;
  late ProviderContainer container;

  ScheduleController controller() =>
      container.read(scheduleControllerProvider.notifier);
  ScheduleState state() => container.read(scheduleControllerProvider);
  Schedule schedule() => state().schedule;
  DayEntry? entry(CivilDate d) => schedule().entries[d];
  String ids(CivilDate d) => schedule().resolve(d).shiftIds.join('+');

  Future<Schedule> stored() async {
    await controller().pendingWrites;
    return (await storage.repository.load(mainCalendarId)).schedule;
  }

  Future<void> expectStoredEqualsMemory() async =>
      expectSameSchedule(await stored(), schedule());

  setUp(() async {
    storage = await TestStorage.open(now: _now);
    addTearDown(storage.close);
    container = ProviderContainer(
      overrides: [
        ...storage.overrides,
        clockProvider.overrideWithValue(() => _now),
      ],
    );
    addTearDown(() async {
      await controller().pendingWrites;
      container.dispose();
    });
  });

  /// Runs [action] and checks it was ONE undo step: one undo gives back the
  /// exact schedule (in memory and stored) and nothing more can be undone.
  Future<void> expectOneUndoStep(
    ScheduleChange? Function() action, {
    required void Function() afterwards,
  }) async {
    final hadHistory = state().canUndo;
    final before = schedule();
    final step = action();
    expect(step, isNotNull, reason: 'it must change something');
    afterwards();
    await expectStoredEqualsMemory();
    expect(state().canUndo, isTrue);

    controller().undo();
    expectSameSchedule(schedule(), before);
    await expectStoredEqualsMemory();
    expect(
      state().canUndo,
      hadHistory,
      reason: 'ONE step for the whole action',
    );
    expect(state().canRedo, isTrue);

    controller().redo();
    afterwards();
    await expectStoredEqualsMemory();
  }

  group('setShiftOnDays', () {
    test('one week, one undo step; notes kept; normalized', () async {
      final week = _days(_oct19, 7); // 19-25 Oct
      await expectOneUndoStep(
        () => controller().setShiftOnDays(week, 'afternoon'),
        afterwards: () {
          for (final d in week) {
            expect(ids(d), 'afternoon', reason: '$d');
          }
          // The note of the 20th is still there.
          expect(entry(_oct20)?.note, _demoNote);
          expect(entry(_oct20)?.shiftTypeIds, ['afternoon']);
        },
      );
    });

    test('days that already match the rotation store no override', () async {
      // 19, 20, 23 are Noche by the rotation; 21 and 22 are overridden.
      controller().setShiftOnDays([_oct19, _oct20, _oct21, _oct22], 'night');
      expect(entry(_oct19), isNull);
      expect(entry(_oct20), DayEntry(date: _oct20, note: _demoNote));
      expect(entry(_oct21), isNull, reason: 'back to the rotation');
      expect(entry(_oct22), isNull);
      await expectStoredEqualsMemory();
    });

    test('nothing to change leaves no step', () {
      expect(controller().setShiftOnDays([_oct19, _oct23], 'night'), isNull);
      expect(controller().setShiftOnDays(const [], 'night'), isNull);
      expect(state().canUndo, isFalse);
    });

    test(
      'with Saliente automático, the saliente is in the same step',
      () async {
        await container.read(postNightAutoProvider.notifier).set(true);
        // Libre 24 and 25: a night on the 24th turns the 25th into Saliente.
        await expectOneUndoStep(
          () => controller().setShiftOnDays([_oct24], 'night'),
          afterwards: () {
            expect(ids(_oct24), 'night');
            expect(ids(_oct25), postNightTypeId);
          },
        );
      },
    );
  });

  group('doubleShiftOnDays', () {
    test('adds the shift after the day\'s own; a day that has it is left '
        'alone', () async {
      await expectOneUndoStep(
        () => controller().doubleShiftOnDays([
          _oct21,
          _oct23,
          _oct24,
        ], 'afternoon'),
        afterwards: () {
          // 21 already had it.
          expect(entry(_oct21)?.shiftTypeIds, ['morning', 'afternoon']);
          expect(ids(_oct23), 'night+afternoon');
          expect(ids(_oct24), 'rest+afternoon');
        },
      );
    });
  });

  group('clearDays and resetDaysToPattern', () {
    test('clearDays: empty overrides, notes kept, one step', () async {
      await expectOneUndoStep(
        () => controller().clearDays([_oct19, _oct20, _oct21]),
        afterwards: () {
          for (final d in [_oct19, _oct20, _oct21]) {
            expect(schedule().resolve(d).isEmpty, isTrue, reason: '$d');
            expect(entry(d)?.shiftTypeIds, isEmpty, reason: '$d');
          }
          expect(entry(_oct20)?.note, _demoNote);
        },
      );
    });

    test('resetDaysToPattern drops overrides and keeps notes', () async {
      controller().setNoteOnDays([_oct21], 'Revisión');
      await expectOneUndoStep(
        () => controller().resetDaysToPattern([
          _oct20, // note only: nothing to reset
          _oct21, // M + T with a note
          _oct22, // empty override
          _oct27, // Vacaciones
        ]),
        afterwards: () {
          expect(entry(_oct20), DayEntry(date: _oct20, note: _demoNote));
          expect(entry(_oct21), DayEntry(date: _oct21, note: 'Revisión'));
          expect(entry(_oct22), isNull);
          expect(ids(_oct22), 'night');
          expect(entry(_oct27), isNull);
          expect(ids(_oct27), 'morning');
        },
      );
    });

    test('nothing to reset leaves no step', () {
      expect(controller().resetDaysToPattern([_oct19, _oct20]), isNull);
      expect(state().canUndo, isFalse);
    });
  });

  group('cut', () {
    SelectionController selection() =>
        container.read(selectionControllerProvider.notifier);

    DayClipboard? clipboard() => container.read(dayClipboardProvider);

    test('copies the days and clears them as ONE undo step; the clipboard '
        'survives the undo', () async {
      final week = _days(_oct19, 7);
      final before = schedule();
      selection().select(week);

      final result = selection().cut();
      expect(result, isNotNull);
      expect(result!.step, isNotNull);
      expect(result.clip.length, 7);
      // The clipboard holds what the days were BEFORE clearing.
      expect(clipboard(), same(result.clip));
      expect(
        [for (final d in result.clip.days) d.shiftIds.join('+')],
        [for (final d in week) before.resolve(d).shiftIds.join('+')],
      );
      expect(result.clip.days[1].note, _demoNote);
      for (final d in week) {
        expect(schedule().resolve(d).isEmpty, isTrue, reason: '$d');
      }
      expect(
        entry(_oct20)?.note,
        isNull,
        reason: 'the note moved with the cut',
      );
      expect(container.read(selectionControllerProvider).isEmpty, isTrue);
      expect(container.read(selectionControllerProvider).active, isTrue);
      await expectStoredEqualsMemory();

      // Exactly one step to undo, and the clipboard keeps its content.
      expect(controller().undoIfLast(result.step!), isTrue);
      expectSameSchedule(schedule(), before);
      expect(state().canUndo, isFalse);
      expect(clipboard(), same(result.clip));
      await expectStoredEqualsMemory();
    });

    test('pasting what was cut gives the days back elsewhere', () async {
      final week = _days(_oct19, 7);
      final before = schedule();
      selection().select(week);
      final result = selection().cut()!;
      controller().pasteDays(result.clip, _nov9, includeNotes: false);
      for (var i = 0; i < 7; i++) {
        expect(
          schedule().resolve(_nov9.addDays(i)).shiftIds,
          before.resolve(_oct19.addDays(i)).shiftIds,
          reason: 'offset $i',
        );
      }
    });

    test(
      'days that are already empty: no step, but the copy is made',
      () async {
        controller().clearDays([_oct22]);
        selection().select([_oct22]);
        final result = selection().cut()!;
        expect(result.step, isNull);
        expect(clipboard()?.length, 1);
      },
    );

    test('nothing chosen: nothing happens', () {
      selection().enter();
      expect(selection().cut(), isNull);
      expect(clipboard(), isNull);
      expect(state().canUndo, isFalse);
    });
  });

  group('setNoteOnDays', () {
    test('the same note on every day, shifts kept; blank removes', () async {
      final days = [_oct19, _oct21, _oct24];
      await expectOneUndoStep(
        () => controller().setNoteOnDays(days, '  Dentista  '),
        afterwards: () {
          for (final d in days) {
            expect(entry(d)?.note, 'Dentista', reason: '$d');
          }
          expect(entry(_oct21)?.shiftTypeIds, ['morning', 'afternoon']);
          expect(entry(_oct19)?.shiftTypeIds, isNull);
        },
      );

      controller().setNoteOnDays([_oct20, _oct19], '');
      expect(entry(_oct20), isNull, reason: 'a note-only entry disappears');
      expect(entry(_oct19), isNull);
      await expectStoredEqualsMemory();
    });
  });

  group('copy and paste', () {
    test('capture keeps the relative offsets and what the days show', () {
      final clip = DayClipboard.capture(schedule(), [_oct21, _oct19, _oct23]);
      expect(clip.origin, _oct19);
      expect([for (final d in clip.days) d.offset], [0, 2, 4]);
      expect(clip.days[0].shiftIds, ['night']);
      expect(clip.days[1].shiftIds, ['morning', 'afternoon']);
      expect(clip.span, 5);
      expect(clip.hasNotes, isFalse);
      expect(
        DayClipboard.capture(schedule(), [_oct20]).days.single.note,
        _demoNote,
      );
    });

    test('a week pasted on another Monday, across months, one step', () async {
      final clip = DayClipboard.capture(schedule(), _days(_oct19, 7));
      // 9 Nov: same rotation step as 19 Oct (one 21-day cycle later).
      await expectOneUndoStep(
        () => controller().pasteDays(clip, _nov9),
        afterwards: () {
          for (var i = 0; i < 7; i++) {
            expect(
              ids(_nov9.addDays(i)),
              ids(_oct19.addDays(i)),
              reason: 'offset $i',
            );
          }
          // Days that follow the rotation there are not stored.
          expect(entry(_nov9), isNull);
          expect(entry(_nov9.addDays(2))?.shiftTypeIds, [
            'morning',
            'afternoon',
          ]);
          // The note of the 20th did not travel (shifts only by default).
          expect(entry(_nov9.addDays(1)), isNull);
        },
      );
    });

    test('the same block lands on the same weekdays when it crosses the '
        'daylight-saving change', () async {
      // 19-25 Oct 2026 contains the night the clocks go back (25 Oct). Paste
      // it on a Wednesday: every day keeps its distance from the first.
      final clip = DayClipboard.capture(schedule(), _days(_oct19, 7));
      final start = _nov9.addDays(2); // Wednesday
      controller().pasteDays(clip, start);
      for (var i = 0; i < 7; i++) {
        final target = start.addDays(i);
        expect(
          schedule().resolve(target).shiftIds,
          clip.days[i].shiftIds,
          reason: 'offset $i on $target',
        );
        expect(target.differenceInDays(start), i);
      }
      await expectStoredEqualsMemory();

      // And forwards over the March change (29 Mar 2026), before any
      // rotation: only explicit shifts exist there.
      const mar23 = CivilDate(2026, 3, 23);
      final week = _days(mar23, 7); // 23-29 Mar
      controller().setShiftOnDays(week, 'morning');
      controller().setShiftOnDays([mar23.addDays(6)], 'night');
      final marClip = DayClipboard.capture(schedule(), week);
      const apr6 = CivilDate(2026, 4, 6);
      controller().pasteDays(marClip, apr6);
      expect(ids(apr6), 'morning');
      expect(ids(apr6.addDays(5)), 'morning');
      expect(
        ids(apr6.addDays(6)),
        'night',
        reason: 'the 29th lands on a Sunday',
      );
      expect(apr6.addDays(6).weekday, DateTime.sunday);
      await expectStoredEqualsMemory();
    });

    test('Incluir notas: copied notes replace the destination\'s; without '
        'it the destination notes are untouched', () async {
      final clip = DayClipboard.capture(schedule(), _days(_oct19, 7));
      expect(clip.hasNotes, isTrue);
      final nov10 = _nov9.addDays(1);
      controller().setNoteOnDays([nov10, _nov9.addDays(3)], 'Mío');

      // Without notes: the destination keeps its own.
      controller().pasteDays(clip, _nov9);
      expect(entry(nov10)?.note, 'Mío');
      expect(entry(_nov9.addDays(3))?.note, 'Mío');

      // With notes: the 20th's note arrives; a copied day without note
      // leaves the destination's alone.
      controller().pasteDays(clip, _nov9, includeNotes: true);
      expect(entry(nov10)?.note, _demoNote);
      expect(entry(_nov9.addDays(3))?.note, 'Mío');
      await expectStoredEqualsMemory();
    });

    test('an empty clipboard pastes nothing', () {
      expect(
        controller().pasteDays(
          DayClipboard.capture(schedule(), const []),
          _nov9,
        ),
        isNull,
      );
      expect(state().canUndo, isFalse);
    });
  });

  group('repeatDays', () {
    test('a week repeated 4 times is ONE undo step', () async {
      final week = _days(_oct19, 7);
      final source = DayClipboard.capture(schedule(), week);
      await expectOneUndoStep(
        () => controller().repeatDays(week, 4),
        afterwards: () {
          for (var k = 1; k <= 4; k++) {
            for (var i = 0; i < 7; i++) {
              final target = _oct19.addDays(7 * k + i);
              expect(
                schedule().resolve(target).shiftIds,
                source.days[i].shiftIds,
                reason: 'copy $k, offset $i',
              );
            }
          }
          // Nothing after the last copy.
          expect(entry(_oct19.addDays(7 * 5)), isNull);
        },
      );
    });

    test('the block is the span first-to-last, gaps included', () async {
      // 19th and 21st: a 3-day block. Two repeats: 22/24 and 25/27.
      controller().repeatDays([_oct21, _oct19], 2);
      expect(ids(_oct22), 'night', reason: 'the 22nd is the copy of the 19th');
      expect(ids(_oct24), 'morning+afternoon');
      expect(ids(_oct25), 'night');
      expect(ids(_oct27), 'morning+afternoon');
      // The gap day of the block (20th -> 23rd, 26th) was not copied.
      expect(entry(_oct23), isNull);
      expect(entry(_oct26), isNull);
      await expectStoredEqualsMemory();
    });

    test('preview helpers', () {
      final clip = DayClipboard.capture(schedule(), _days(_oct19, 7));
      expect(clip.repeatEnd(1), _oct19.addDays(13));
      expect(clip.repeatEnd(4), _oct19.addDays(34));
      expect(clip.length * 4, 28);
    });

    test('1 to 52 times; anything else is ignored', () {
      final week = _days(_oct19, 7);
      expect(controller().repeatDays(week, 0), isNull);
      expect(controller().repeatDays(week, 53), isNull);
      expect(state().canUndo, isFalse);
      expect(controller().repeatDays(week, 52), isNotNull);
      expect(state().canUndo, isTrue);
    });

    test('notes travel only when asked', () {
      controller().repeatDays([_oct20], 1);
      expect(entry(_oct21)?.note, isNull);
      controller().undo();
      controller().repeatDays([_oct20], 1, includeNotes: true);
      expect(entry(_oct21)?.note, _demoNote);
    });
  });

  group('rotations', () {
    test(
      'endRun cuts the run the day before; manual days stay; undo',
      () async {
        const nov2 = CivilDate(2026, 11, 2);
        final entriesBefore = schedule().entries;
        await expectOneUndoStep(
          () => controller().endRun('run-1', nov2),
          afterwards: () {
            expect(
              schedule().runs.single.endDate,
              const CivilDate(2026, 11, 1),
            );
            expect(ids(const CivilDate(2026, 11, 1)), 'rest');
            expect(schedule().resolve(nov2).isEmpty, isTrue);
            expect(schedule().entries, entriesBefore);
          },
        );
      },
    );

    test('endRun refuses a date that would not shorten it', () {
      // Not after its start: use deleteRun instead.
      expect(
        controller().endRun('run-1', const CivilDate(2026, 7, 13)),
        isNull,
      );
      expect(controller().endRun('ghost', _oct26), isNull);
      controller().endRun('run-1', _oct26);
      // Already ends the day before: a later date would extend it.
      expect(
        controller().endRun('run-1', const CivilDate(2026, 11, 2)),
        isNull,
      );
      // An earlier one shortens it again.
      expect(controller().endRun('run-1', _oct24), isNotNull);
      expect(schedule().runs.single.endDate, _oct23);
    });

    test('deleteRun removes the run, overrides stay, one undo brings it '
        'back with its seq', () async {
      final runBefore = schedule().runs.single;
      final entriesBefore = schedule().entries;
      await expectOneUndoStep(
        () => controller().deleteRun('run-1'),
        afterwards: () {
          expect(schedule().runs, isEmpty);
          expect(schedule().resolve(_oct24).isEmpty, isTrue);
          expect(schedule().entries, entriesBefore);
          expect(ids(_oct21), 'morning+afternoon');
        },
      );
      controller().undo();
      expect(schedule().runs.single, runBefore);
      expect(controller().deleteRun('ghost'), isNull);
    });

    test('undoIfLast takes back only the latest step', () {
      final end = controller().endRun('run-1', _oct26)!;
      controller().clearDays([_oct19]);
      expect(controller().undoIfLast(end), isFalse);
      expect(schedule().runs.single.endDate, _oct25);
    });
  });
}
