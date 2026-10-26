import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/application/selection_controller.dart';
import 'package:cuadrante/features/calendar/domain/range_editing.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';

final _now = DateTime(2026, 10, 19, 12);

// Demo data around Monday 19 Oct 2026 (see range_edit_controller_test.dart):
// 19-23 Oct Noche, 24-25 Libre, 26-30 Mañana by the rotation.
const _oct19 = CivilDate(2026, 10, 19); // Noche
const _oct24 = CivilDate(2026, 10, 24); // Libre
const _oct26 = CivilDate(2026, 10, 26); // Mañana
const _oct30 = CivilDate(2026, 10, 30); // Mañana

/// Reminder, overtime and early leave live in the same row as the note and
/// follow its rules in every edit (schema v3), through the real controller
/// and the real database.
void main() {
  late TestStorage storage;
  late ProviderContainer container;

  // 19th: note + reminder + overtime + early leave on a rotation day.
  // 24th: only overtime. 26th: only a reminder. 30th: its own note.
  final seeded = {
    _oct19: const DayEntry(
      date: _oct19,
      note: 'Reunión',
      noteReminderMinute: 450,
      overtimeMinutes: 60,
      earlyLeaveMinutes: 15,
    ),
    _oct24: const DayEntry(date: _oct24, overtimeMinutes: 30),
    _oct26: const DayEntry(date: _oct26, noteReminderMinute: 600),
    _oct30: const DayEntry(date: _oct30, note: 'Mía', overtimeMinutes: 5),
  };

  ScheduleController controller() =>
      container.read(scheduleControllerProvider.notifier);
  Schedule schedule() => container.read(scheduleControllerProvider).schedule;
  DayEntry? entry(CivilDate d) => schedule().entries[d];

  Future<void> expectStoredEqualsMemory() async {
    await controller().pendingWrites;
    final stored = (await storage.repository.load(mainCalendarId)).schedule;
    expectSameSchedule(stored, schedule());
  }

  setUp(() async {
    final base = await TestStorage.open(now: _now);
    addTearDown(base.close);
    await base.repository.apply(
      mainCalendarId,
      ScheduleChange(
        patch: EntriesPatch({
          for (final e in seeded.entries)
            e.key: EntryChange(base.snapshot.schedule.entries[e.key], e.value),
        }),
      ),
    );
    storage = await base.withReloadedSnapshot();
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

  test('the database hands the saved fields to the controller', () {
    expect(entry(_oct19), seeded[_oct19]);
    expect(entry(_oct24), seeded[_oct24]);
    expect(entry(_oct26), seeded[_oct26]);
  });

  test('painting keeps reminder, overtime and early leave; one undo gives '
      'everything back', () async {
    final before = schedule();
    expect(controller().setShiftOnDays([_oct19], 'afternoon'), isNotNull);
    expect(entry(_oct19)!.shiftTypeIds, ['afternoon']);
    expect(entry(_oct19)!.note, 'Reunión');
    expect(entry(_oct19)!.noteReminderMinute, 450);
    expect(entry(_oct19)!.overtimeMinutes, 60);
    expect(entry(_oct19)!.earlyLeaveMinutes, 15);
    await expectStoredEqualsMemory();

    controller().undo();
    expectSameSchedule(schedule(), before);
    await expectStoredEqualsMemory();
  });

  test(
    'painting back what the rotation gives drops only the override',
    () async {
      controller().setShiftOnDays([_oct19], 'afternoon');
      controller().setShiftOnDays([_oct19], 'night');
      expect(entry(_oct19), seeded[_oct19], reason: 'back to the seeded entry');
      await expectStoredEqualsMemory();
    },
  );

  test('Borrar keeps them as it keeps notes', () async {
    controller().clearDays([_oct19, _oct24]);
    expect(entry(_oct19)!.shiftTypeIds, isEmpty);
    expect(entry(_oct19)!.overtimeMinutes, 60);
    expect(entry(_oct24)!.overtimeMinutes, 30);
    expect(entry(_oct24)!.shiftTypeIds, isEmpty);
    await expectStoredEqualsMemory();
  });

  test('Volver al patrón keeps them', () async {
    controller().setShiftOnDays([_oct19], 'afternoon');
    controller().resetDaysToPattern([_oct19]);
    expect(entry(_oct19), seeded[_oct19]);
    await expectStoredEqualsMemory();
  });

  test('a day whose only content is overtime or a reminder survives '
      'painting what the rotation gives and a reload', () async {
    // 24th is Libre: painting Libre changes nothing and the entry stays.
    controller().setShiftOnDays([_oct24], 'rest');
    controller().setShiftOnDays([_oct26], 'morning');
    expect(entry(_oct24), seeded[_oct24]);
    expect(entry(_oct26), seeded[_oct26]);
    await controller().reload();
    expect(entry(_oct24), seeded[_oct24]);
    expect(entry(_oct26), seeded[_oct26]);
  });

  test('Duplicar en otro día copies them like the note; what the source '
      'does not have leaves the destination alone', () async {
    // Onto the 30th, which has a note and 5 minutes of overtime of its own.
    controller().copyDay(_oct19, _oct30);
    final copied = entry(_oct30)!;
    expect(copied.note, 'Reunión');
    expect(copied.noteReminderMinute, 450);
    expect(copied.overtimeMinutes, 60);
    expect(copied.earlyLeaveMinutes, 15);

    // From the 24th (only overtime) onto the 19th: its note stays.
    controller().copyDay(_oct24, _oct19);
    final kept = entry(_oct19)!;
    expect(kept.overtimeMinutes, 30);
    expect(kept.note, 'Reunión');
    expect(kept.noteReminderMinute, 450);
    expect(kept.earlyLeaveMinutes, 15);
    await expectStoredEqualsMemory();
  });

  test(
    'Pegar: only with includeNotes; then they replace the destination\'s',
    () async {
      final clip = DayClipboard.capture(schedule(), [_oct19]);
      expect(clip.hasNotes, isTrue);

      controller().pasteDays(clip, _oct30);
      expect(entry(_oct30)!.note, 'Mía', reason: 'without notes: untouched');
      expect(entry(_oct30)!.overtimeMinutes, 5);
      expect(entry(_oct30)!.noteReminderMinute, isNull);

      controller().pasteDays(clip, _oct30, includeNotes: true);
      final pasted = entry(_oct30)!;
      expect(pasted.note, 'Reunión');
      expect(pasted.noteReminderMinute, 450);
      expect(pasted.overtimeMinutes, 60);
      expect(pasted.earlyLeaveMinutes, 15);
      await expectStoredEqualsMemory();
    },
  );

  test('Repetir: each copy of the block gets them with includeNotes', () async {
    // The block is the 19th..20th (2 days): copies start on the 21st, 23rd.
    final before21 = entry(_oct19.addDays(2));
    final before23 = entry(_oct19.addDays(4));
    controller().repeatDays([_oct19, _oct19.addDays(1)], 2, includeNotes: true);
    expect(entry(_oct19.addDays(2))!.overtimeMinutes, 60);
    expect(entry(_oct19.addDays(4))!.noteReminderMinute, 450);
    await expectStoredEqualsMemory();

    controller().undo();
    expect(entry(_oct19.addDays(2)), before21);
    expect(entry(_oct19.addDays(4)), before23);
    await expectStoredEqualsMemory();
  });

  test('Repetir without notes leaves the new days without them', () async {
    controller().repeatDays([_oct19], 1);
    expect(entry(_oct19.addDays(1))?.overtimeMinutes, isNull);
    expect(entry(_oct19.addDays(1))?.noteReminderMinute, isNull);
    await expectStoredEqualsMemory();
  });

  test('setNote on a day keeps the rest of what it holds', () async {
    controller().setNote(_oct24, 'Nota nueva');
    expect(entry(_oct24)!.note, 'Nota nueva');
    expect(entry(_oct24)!.overtimeMinutes, 30);
    controller().setNote(_oct24, null);
    expect(entry(_oct24), seeded[_oct24], reason: 'overtime alone stays');
    await expectStoredEqualsMemory();
  });

  group('Cortar moves the annotations of the copy', () {
    SelectionController selection() =>
        container.read(selectionControllerProvider.notifier);

    test('cut + paste with notes is a move: note, reminder, overtime and early '
        'leave leave the source and land on the destination', () async {
      const nov9 = CivilDate(2026, 11, 9);
      selection().select([_oct19, _oct24]);
      final result = selection().cut()!;
      expect(result.step, isNotNull);

      // The source keeps nothing of what the copy carries.
      expect(entry(_oct19)!.note, isNull);
      expect(entry(_oct19)!.noteReminderMinute, isNull);
      expect(entry(_oct19)!.overtimeMinutes, isNull);
      expect(entry(_oct19)!.earlyLeaveMinutes, isNull);
      expect(entry(_oct19)!.shiftTypeIds, isEmpty, reason: 'shifts cleared');
      expect(entry(_oct24)!.overtimeMinutes, isNull);
      await expectStoredEqualsMemory();

      controller().pasteDays(result.clip, nov9, includeNotes: true);
      final moved = entry(nov9)!;
      expect(moved.note, 'Reunión');
      expect(moved.noteReminderMinute, 450);
      expect(moved.overtimeMinutes, 60);
      expect(moved.earlyLeaveMinutes, 15);
      expect(entry(nov9.addDays(5))!.overtimeMinutes, 30);
      // Nothing left twice.
      expect(
        schedule().entries.values.where((e) => e.note == 'Reunión'),
        hasLength(1),
      );
      expect(
        schedule().entries.values.where((e) => e.noteReminderMinute == 450),
        hasLength(1),
      );
      await expectStoredEqualsMemory();
    });

    test('the clipboard of a cut is marked as cut; a copy is not', () {
      selection().select([_oct19]);
      final cut = selection().cut()!;
      expect(cut.clip.isCut, isTrue);
      expect(container.read(dayClipboardProvider)!.isCut, isTrue);

      selection().select([_oct24]);
      expect(
        DayClipboard.capture(schedule(), [_oct24]).isCut,
        isFalse,
        reason: 'a plain copy keeps the choice',
      );
      selection().select([_oct19]);
      final noNotes = selection().cut(withNotes: false)!;
      expect(
        noNotes.clip.isCut,
        isFalse,
        reason: 'nothing moved off the source, so it behaves as a copy',
      );
    });

    test('pasting a cut clip WITHOUT asking for notes still brings them: '
        'nothing is lost', () async {
      const nov9 = CivilDate(2026, 11, 9);
      selection().select([_oct19, _oct24]);
      final result = selection().cut()!;
      expect(entry(_oct19)!.note, isNull);

      // includeNotes defaults to false: a cut clip ignores that.
      controller().pasteDays(result.clip, nov9);
      final moved = entry(nov9)!;
      expect(moved.note, 'Reunión');
      expect(moved.noteReminderMinute, 450);
      expect(moved.overtimeMinutes, 60);
      expect(moved.earlyLeaveMinutes, 15);
      expect(entry(nov9.addDays(5))!.overtimeMinutes, 30);
      await expectStoredEqualsMemory();
    });

    test('pasting a COPY without notes still leaves them behind', () async {
      const nov9 = CivilDate(2026, 11, 9);
      final copy = DayClipboard.capture(schedule(), [_oct19]);
      controller().pasteDays(copy, nov9);
      expect(entry(nov9)?.note, isNull);
      expect(entry(nov9)?.overtimeMinutes, isNull);
      // And with notes it brings them, as before.
      controller().pasteDays(copy, nov9.addDays(1), includeNotes: true);
      expect(entry(nov9.addDays(1))!.note, 'Reunión');
      // The source of a copy keeps everything.
      expect(entry(_oct19)!.note, 'Reunión');
    });

    test('one undo gives the shifts and every annotation back', () async {
      final before = schedule();
      selection().select([_oct19, _oct24, _oct26, _oct30]);
      final result = selection().cut()!;
      expect(entry(_oct26)!.noteReminderMinute, isNull);
      expect(entry(_oct30)!.note, isNull);
      await expectStoredEqualsMemory();

      expect(controller().undoIfLast(result.step!), isTrue);
      expectSameSchedule(schedule(), before);
      expect(controller().state.canUndo, isFalse);
      await expectStoredEqualsMemory();
    });

    test('a day with no annotations in the copy keeps what it had: only what '
        'the copy carries moves', () async {
      selection().select([_oct19]);
      // The 30th is outside the cut: untouched.
      final result = selection().cut()!;
      expect(result.clip.length, 1);
      expect(entry(_oct30), seeded[_oct30]);
      expect(entry(_oct24), seeded[_oct24]);
    });

    test(
      'withNotes: false leaves note, reminder and extras on the source',
      () async {
        selection().select([_oct19]);
        final result = selection().cut(withNotes: false)!;
        expect(entry(_oct19)!.shiftTypeIds, isEmpty);
        expect(entry(_oct19)!.note, 'Reunión');
        expect(entry(_oct19)!.noteReminderMinute, 450);
        expect(entry(_oct19)!.overtimeMinutes, 60);
        expect(entry(_oct19)!.earlyLeaveMinutes, 15);
        expect(controller().undoIfLast(result.step!), isTrue);
        expect(entry(_oct19), seeded[_oct19]);
        await expectStoredEqualsMemory();
      },
    );

    test(
      'a day that only had an annotation is dropped entirely by the cut',
      () async {
        selection().select([_oct26]);
        selection().cut();
        // Reminder gone, and no empty override left behind.
        expect(entry(_oct26)?.noteReminderMinute, isNull);
        expect(entry(_oct26)?.note, isNull);
        expect(schedule().resolve(_oct26).isEmpty, isTrue);
        await expectStoredEqualsMemory();
      },
    );

    group('cuts between calendars use operation identity', () {
      const destination = CivilDate(2026, 11, 9);

      Future<String> otherCalendar(DayEntry collision) async {
        final other = await CalendarsRepository(storage.database)
            .create(name: 'Otro', colorValue: 1);
        await storage.repository.apply(
          other.id,
          ScheduleChange(
            patch: EntriesPatch({_oct19: EntryChange(null, collision)}),
          ),
        );
        return other.id;
      }

      void expectAnnotations(DayEntry? actual) {
        expect(actual?.note, 'Reunión');
        expect(actual?.noteReminderMinute, 450);
        expect(actual?.overtimeMinutes, 60);
        expect(actual?.earlyLeaveMinutes, 15);
      }

      test('undo of a UI paste makes the next cross-calendar paste move annotations again', () async {
        final other = await otherCalendar(
          const DayEntry(date: _oct19, noteReminderMinute: 450),
        );
        selection().select([_oct19]);
        final cut = selection().cut()!.clip;
        await controller().switchCalendar(other);
        final first = controller().pasteDays(
          cut,
          destination,
          includeNotes: false,
        )!;
        container.read(dayClipboardProvider.notifier).pasted(cut);
        final copied = container.read(dayClipboardProvider)!;
        expect(copied.isCut, isFalse);
        expect(copied.cutOperation, same(cut.cutOperation));
        expect(controller().undoIfLast(first), isTrue);
        expect(entry(destination), isNull);
        expect(pasteMovesAnnotations(copied), isTrue);
        controller().redo();
        expectAnnotations(entry(destination));
        expect(pasteMovesAnnotations(copied), isFalse);
        controller().undo();
        expect(pasteMovesAnnotations(copied), isTrue);
        final third = await otherCalendar(
          const DayEntry(date: _oct19, overtimeMinutes: 60),
        );
        await controller().switchCalendar(third);
        controller().pasteDays(copied, destination, includeNotes: false);
        container.read(dayClipboardProvider.notifier).pasted(copied);
        expectAnnotations(entry(destination));
        await controller().pendingWrites;
        expectAnnotations(
          (await storage.repository.load(third)).schedule.entries[destination],
        );
      });

      for (final collision in [
        const DayEntry(date: _oct19, note: 'Reunión'),
        const DayEntry(date: _oct19, noteReminderMinute: 450),
        const DayEntry(date: _oct19, overtimeMinutes: 60),
        const DayEntry(date: _oct19, earlyLeaveMinutes: 15),
      ]) {
        test(
          'a matching field in another calendar cannot undo the cut: '
          '${collision.note}/${collision.noteReminderMinute}/'
          '${collision.overtimeMinutes}/${collision.earlyLeaveMinutes}',
          () async {
            final other = await otherCalendar(collision);
            selection().select([_oct19]);
            final result = selection().cut()!;
            expect(result.clip.sourceCalendarId, mainCalendarId);
            expect(result.clip.cutOperation!.sourceCalendarId, mainCalendarId);
            await controller().switchCalendar(other);
            expect(controller().state.canUndo, isFalse);
            expect(pasteMovesAnnotations(result.clip), isTrue);

            final step = controller().pasteDays(
              result.clip,
              destination,
              includeNotes: false,
            );
            expectAnnotations(entry(destination));
            await controller().pendingWrites;
            expectAnnotations(
              (await storage.repository.load(other))
                  .schedule
                  .entries[destination],
            );
            expect(entry(_oct19), collision, reason: 'unrelated entry stays');

            // Undo is exactly the destination paste; the cut contents remain
            // available on the clipboard, including every annotation.
            expect(controller().undoIfLast(step!), isTrue);
            expect(entry(destination), isNull);
            expect(container.read(dayClipboardProvider), same(result.clip));
            expect(result.clip.days.single.note, 'Reunión');
            expect(result.clip.days.single.noteReminderMinute, 450);
            expect(result.clip.days.single.overtimeMinutes, 60);
            expect(result.clip.days.single.earlyLeaveMinutes, 15);
            controller().redo();
            expectAnnotations(entry(destination));
            await controller().pendingWrites;
            final source = (await storage.repository.load(mainCalendarId))
                .schedule
                .entries[_oct19];
            expect(source?.note, isNull);
            expect(source?.noteReminderMinute, isNull);
            expect(source?.overtimeMinutes, isNull);
            expect(source?.earlyLeaveMinutes, isNull);
          },
        );
      }

      test('undoing the exact cut before switching restores the source and '
          'allows a paste without annotations', () async {
        final other = await otherCalendar(
          const DayEntry(date: _oct19, noteReminderMinute: 450),
        );
        selection().select([_oct19]);
        final result = selection().cut()!;
        expect(controller().undoIfLast(result.step!), isTrue);
        expectAnnotations(entry(_oct19));
        await controller().switchCalendar(other);
        expect(pasteMovesAnnotations(result.clip), isFalse);
        controller().pasteDays(result.clip, destination, includeNotes: false);
        expect(entry(destination)?.note, isNull);
        expect(entry(destination)?.noteReminderMinute, isNull);
        expect(entry(destination)?.overtimeMinutes, isNull);
        expect(entry(destination)?.earlyLeaveMinutes, isNull);
        await controller().pendingWrites;
        expectAnnotations(
          (await storage.repository.load(mainCalendarId))
              .schedule
              .entries[_oct19],
        );
      });

      test(
        'undoing another edit or restoring one field does not undo a cut',
        () {
          selection().select([_oct19]);
          final result = selection().cut()!;
          controller().setDayExtras(_oct19, overtimeMinutes: 60);
          expect(pasteMovesAnnotations(result.clip), isTrue);
          controller().setNote(_oct30, 'Otra');
          controller().undo();
          expect(pasteMovesAnnotations(result.clip), isTrue);
          controller().pasteDays(result.clip, destination, includeNotes: false);
          expectAnnotations(entry(destination));
        },
      );

      test(
        'redoing the exact cut before switching moves all annotations',
        () async {
          final other = await otherCalendar(
            const DayEntry(date: _oct19, noteReminderMinute: 450),
          );
          selection().select([_oct19]);
          final result = selection().cut()!;
          controller().undo();
          expect(pasteMovesAnnotations(result.clip), isFalse);
          controller().redo();
          await controller().switchCalendar(other);
          expect(pasteMovesAnnotations(result.clip), isTrue);
          // A clipboard from A cannot accidentally cut the same dates in B.
          expect(controller().cutDays(result.clip), isNull);
          expect(entry(_oct19)?.noteReminderMinute, 450);
          controller().pasteDays(result.clip, destination, includeNotes: false);
          expectAnnotations(entry(destination));
          await controller().pendingWrites;
          expectAnnotations(
            (await storage.repository.load(other))
                .schedule
                .entries[destination],
          );
        },
      );
    });

    group('a cut moves the annotations once', () {
      int notes() =>
          schedule().entries.values.where((e) => e.note == 'Reunión').length;
      int reminders() => schedule().entries.values
          .where((e) => e.noteReminderMinute == 450)
          .length;
      int overtime() => schedule().entries.values.fold(
        0,
        (sum, e) => sum + (e.overtimeMinutes ?? 0),
      );
      DayClipboard? clipboard() => container.read(dayClipboardProvider);

      test('cut, paste, paste elsewhere: each note, reminder and overtime '
          'exists exactly once', () async {
        const nov9 = CivilDate(2026, 11, 9);
        const nov23 = CivilDate(2026, 11, 23);
        selection().select([_oct19]);
        final clip = selection().cut()!.clip;
        expect(notes(), 0);
        final overtimeBefore = overtime();

        final first = controller().pasteDays(clip, nov9);
        expect(first, isNotNull);
        container.read(dayClipboardProvider.notifier).pasted(clip);
        expect(notes(), 1);
        expect(entry(nov9)!.note, 'Reunión');

        // The clipboard is a plain copy now: the second paste brings the
        // shifts but not the notes unless asked.
        expect(clipboard()!.isCut, isFalse);
        expect(clipboard()!.days, clip.days);
        expect(clipboard()!.origin, clip.origin);
        expect(pasteMovesAnnotations(clipboard()!), isFalse);
        controller().pasteDays(clipboard()!, nov23);
        expect(entry(nov23)?.note, isNull);
        expect(entry(nov23)?.noteReminderMinute, isNull);
        expect(entry(nov23)?.overtimeMinutes, isNull);
        expect(notes(), 1);
        expect(reminders(), 1);
        expect(overtime(), overtimeBefore + 60, reason: 'counted once');
        expect(entry(_oct19)?.note, isNull, reason: 'the source stays empty');

        // Asking for them is a copy of the annotations, by choice.
        controller().pasteDays(
          clipboard()!,
          nov23.addDays(14),
          includeNotes: true,
        );
        expect(notes(), 2);
        await expectStoredEqualsMemory();
      });

      test('pasted() leaves a copy and a replaced clipboard alone', () {
        final copy = DayClipboard.capture(schedule(), [_oct19]);
        final notifier = container.read(dayClipboardProvider.notifier);
        notifier.set(copy);
        notifier.pasted(copy);
        expect(clipboard(), same(copy));

        selection().select([_oct19]);
        final cut = selection().cut()!.clip;
        final other = DayClipboard.capture(schedule(), [_oct24]);
        notifier.set(other);
        notifier.pasted(cut);
        expect(clipboard(), same(other), reason: 'not the pasted clip');
      });

      test('cut, undo, paste without notes: the note is not duplicated, '
          'and the paste sheet may offer the switch', () async {
        const nov9 = CivilDate(2026, 11, 9);
        selection().select([_oct19]);
        final result = selection().cut()!;
        expect(pasteMovesAnnotations(result.clip), isTrue);

        controller().undoIfLast(result.step!);
        expect(entry(_oct19), seeded[_oct19]);
        expect(result.clip.cutOperation!.isApplied, isFalse);
        expect(
          pasteMovesAnnotations(result.clip),
          isFalse,
          reason: 'the sheet shows Incluir notas again',
        );

        final overtimeBefore = overtime();
        controller().pasteDays(result.clip, nov9);
        expect(entry(nov9)?.note, isNull);
        expect(entry(nov9)?.overtimeMinutes, isNull);
        expect(notes(), 1);
        expect(reminders(), 1);
        expect(overtime(), overtimeBefore);

        // Asking for the notes is still possible (a copy).
        controller().pasteDays(
          result.clip,
          nov9.addDays(7),
          includeNotes: true,
        );
        expect(notes(), 2);
      });

      test('cut, undo, redo, paste: the notes move again', () async {
        const nov9 = CivilDate(2026, 11, 9);
        selection().select([_oct19]);
        final result = selection().cut()!;
        controller().undo();
        expect(entry(_oct19), seeded[_oct19]);
        controller().redo();
        expect(entry(_oct19)!.note, isNull);
        expect(pasteMovesAnnotations(result.clip), isTrue);

        controller().pasteDays(result.clip, nov9);
        expect(entry(nov9)!.note, 'Reunión');
        expect(entry(nov9)!.noteReminderMinute, 450);
        expect(entry(nov9)!.overtimeMinutes, 60);
        expect(notes(), 1);
        await expectStoredEqualsMemory();
      });
    });
  });
}
