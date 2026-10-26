import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';

// ScheduleController.setNoteReminder (docs/paridad.md, A1): the reminder of a
// day's note is ONE undo step through the normal write queue.

final _now = DateTime(2026, 10, 19, 12);

// Demo data: 20 Oct has only a note ("Cambio con Marta si sale el turno"),
// 21 Oct is a hand-made Mañana + Tarde, 24 Oct (Libre by rotation) has
// nothing stored.
const _noteOnly = CivilDate(2026, 10, 20);
const _doubled = CivilDate(2026, 10, 21);
const _rest = CivilDate(2026, 10, 24);
const _demoNote = 'Cambio con Marta si sale el turno';

void main() {
  late TestStorage storage;
  late ProviderContainer container;

  ScheduleController controller() =>
      container.read(scheduleControllerProvider.notifier);
  ScheduleState state() => container.read(scheduleControllerProvider);
  DayEntry? entry(CivilDate d) => state().schedule.entries[d];

  Future<void> expectStoredEqualsMemory() async {
    await controller().pendingWrites;
    final stored = (await storage.repository.load(mainCalendarId)).schedule;
    expectSameSchedule(stored, state().schedule);
  }

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
      await container.read(scheduleControllerProvider.notifier).pendingWrites;
      container.dispose();
    });
  });

  test('sets a reminder on a note; undo and redo give back the exact entry '
      'and the database follows', () async {
    final before = entry(_noteOnly);
    expect(before, DayEntry(date: _noteOnly, note: _demoNote));

    final step = controller().setNoteReminder(_noteOnly, 9 * 60 + 30);
    expect(step, isNotNull);
    expect(
      entry(_noteOnly),
      DayEntry(date: _noteOnly, note: _demoNote, noteReminderMinute: 570),
    );
    expect(state().canUndo, isTrue);
    await expectStoredEqualsMemory();

    controller().undo();
    expect(entry(_noteOnly), before);
    await expectStoredEqualsMemory();
    expect(state().canUndo, isFalse);

    controller().redo();
    expect(entry(_noteOnly)?.noteReminderMinute, 570);
    await expectStoredEqualsMemory();
  });

  test('a reminder on a day with nothing stored creates an entry with only '
      'the reminder; undo removes it', () async {
    expect(entry(_rest), isNull);
    controller().setNoteReminder(_rest, 0);
    expect(entry(_rest), DayEntry(date: _rest, noteReminderMinute: 0));
    // The rotation is untouched.
    expect(entry(_rest)?.shiftTypeIds, isNull);
    expect(state().schedule.resolve(_rest).shiftIds, ['rest']);
    await expectStoredEqualsMemory();

    controller().undo();
    expect(entry(_rest), isNull);
    await expectStoredEqualsMemory();
  });

  test('keeps the shifts of an override and the first and last minutes of '
      'the day are valid', () async {
    controller().setNoteReminder(_doubled, 1439);
    expect(entry(_doubled)?.shiftTypeIds, ['morning', 'afternoon']);
    expect(entry(_doubled)?.noteReminderMinute, 1439);
    controller().setNoteReminder(_doubled, 0);
    expect(entry(_doubled)?.noteReminderMinute, 0);
    await expectStoredEqualsMemory();
  });

  test('changing the time is one step that undoes to the old time', () async {
    controller().setNoteReminder(_noteOnly, 600);
    controller().setNoteReminder(_noteOnly, 1080);
    expect(entry(_noteOnly)?.noteReminderMinute, 1080);
    controller().undo();
    expect(entry(_noteOnly)?.noteReminderMinute, 600);
    await expectStoredEqualsMemory();
  });

  test('removing the reminder keeps the note; undo brings it back', () async {
    controller().setNoteReminder(_noteOnly, 600);
    final removal = controller().setNoteReminder(_noteOnly, null);
    expect(removal, isNotNull);
    expect(entry(_noteOnly), DayEntry(date: _noteOnly, note: _demoNote));
    await expectStoredEqualsMemory();

    controller().undo();
    expect(entry(_noteOnly)?.noteReminderMinute, 600);
    await expectStoredEqualsMemory();
  });

  test('removing the only content of an entry deletes the entry', () async {
    controller().setNoteReminder(_rest, 600);
    controller().setNoteReminder(_rest, null);
    expect(entry(_rest), isNull);
    await expectStoredEqualsMemory();
  });

  test('nothing to change is not a step', () {
    expect(controller().setNoteReminder(_rest, null), isNull);
    expect(state().canUndo, isFalse);

    controller().setNoteReminder(_noteOnly, 600);
    controller().undo();
    controller().redo();
    final again = controller().setNoteReminder(_noteOnly, 600);
    expect(again, isNull, reason: 'same time');
  });

  test('a minute outside the day is refused', () {
    for (final bad in [-1, 1440, 5000]) {
      expect(
        () => controller().setNoteReminder(_noteOnly, bad),
        throwsArgumentError,
      );
    }
    expect(entry(_noteOnly), DayEntry(date: _noteOnly, note: _demoNote));
  });

  test('the reminder is independent of the text of the note', () async {
    controller().setNoteReminder(_noteOnly, 600);
    // Rewriting the note keeps the reminder...
    controller().setNote(_noteOnly, 'Otra cosa');
    expect(entry(_noteOnly)?.noteReminderMinute, 600);
    expect(entry(_noteOnly)?.note, 'Otra cosa');
    // ...and so does clearing it: a reminder alone is a valid entry.
    controller().setNote(_noteOnly, '  ');
    expect(
      entry(_noteOnly),
      DayEntry(date: _noteOnly, noteReminderMinute: 600),
    );
    await expectStoredEqualsMemory();
  });

  test(
    'undoIfLast undoes the reminder only while it is the latest step',
    () async {
      final step = controller().setNoteReminder(_rest, 600)!;
      expect(controller().undoIfLast(step), isTrue);
      expect(entry(_rest), isNull);

      final second = controller().setNoteReminder(_rest, 700)!;
      controller().setNote(_doubled, 'otra edición');
      expect(controller().undoIfLast(second), isFalse);
      expect(entry(_rest)?.noteReminderMinute, 700);
      await expectStoredEqualsMemory();
    },
  );

  test('copying a day brings the reminder along', () async {
    controller().setNoteReminder(_noteOnly, 600);
    controller().copyDay(_noteOnly, _rest);
    expect(entry(_rest)?.note, _demoNote);
    expect(entry(_rest)?.noteReminderMinute, 600);
    await expectStoredEqualsMemory();
  });
}
