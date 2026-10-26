import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';

// ScheduleController.setDayExtras (docs/paridad.md, A6): one undo step, one
// write, and the rest of the day untouched.

final _now = DateTime(2026, 10, 19, 12);

// Demo data: 20 Oct has only a note, 21 Oct is Mañana + Tarde (override),
// 22 Oct is empty (override []), 24 Oct is Libre from the rotation.
const _noteOnly = CivilDate(2026, 10, 20);
const _doubled = CivilDate(2026, 10, 21);
const _rest = CivilDate(2026, 10, 24);
const _morning = CivilDate(2026, 10, 26);
const _demoNote = 'Cambio con Marta si sale el turno';

void main() {
  late TestStorage storage;
  late ProviderContainer container;

  ScheduleController controller() =>
      container.read(scheduleControllerProvider.notifier);
  ScheduleState state() => container.read(scheduleControllerProvider);
  Schedule schedule() => state().schedule;
  DayEntry? entry(CivilDate d) => schedule().entries[d];

  Future<Schedule> stored() async {
    await controller().pendingWrites;
    return (await storage.repository.load(mainCalendarId)).schedule;
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

  test('overtime on a day with no entry creates one with only that', () async {
    expect(entry(_morning), isNull);
    final step = controller().setDayExtras(_morning, overtimeMinutes: 90);
    expect(step, isNotNull);
    expect(entry(_morning), DayEntry(date: _morning, overtimeMinutes: 90));
    // The shifts still come from the rotation.
    expect(schedule().resolve(_morning).source, DaySource.pattern);
    expect(schedule().resolve(_morning).overtimeMinutes, 90);
    expectSameSchedule(await stored(), schedule());
  });

  test('both values at once are ONE undo step; undo and redo give them back '
      'exactly, in memory and on disk', () async {
    final before = schedule();
    controller().setDayExtras(
      _doubled,
      overtimeMinutes: 60,
      earlyLeaveMinutes: 30,
    );
    expect(entry(_doubled)!.overtimeMinutes, 60);
    expect(entry(_doubled)!.earlyLeaveMinutes, 30);
    // The override of the day is kept.
    expect(entry(_doubled)!.shiftTypeIds, ['morning', 'afternoon']);
    expect(state().canUndo, isTrue);

    controller().undo();
    expectSameSchedule(schedule(), before);
    expect(state().canUndo, isFalse);
    expectSameSchedule(await stored(), before);

    controller().redo();
    expect(entry(_doubled)!.overtimeMinutes, 60);
    expect(entry(_doubled)!.earlyLeaveMinutes, 30);
    expectSameSchedule(await stored(), schedule());
  });

  test('null leaves the other value alone; 0 clears only its own', () async {
    controller().setDayExtras(
      _morning,
      overtimeMinutes: 60,
      earlyLeaveMinutes: 30,
    );
    controller().setDayExtras(_morning, overtimeMinutes: 45);
    expect(entry(_morning)!.overtimeMinutes, 45);
    expect(entry(_morning)!.earlyLeaveMinutes, 30);

    controller().setDayExtras(_morning, earlyLeaveMinutes: 0);
    expect(entry(_morning)!.overtimeMinutes, 45);
    expect(entry(_morning)!.earlyLeaveMinutes, isNull);
    expectSameSchedule(await stored(), schedule());
  });

  test('clearing the last value removes an entry that held only extras, '
      'one undo step', () async {
    controller().setDayExtras(_morning, overtimeMinutes: 30);
    expect(entry(_morning), isNotNull);
    controller().setDayExtras(_morning, overtimeMinutes: 0);
    expect(entry(_morning), isNull);
    expectSameSchedule(await stored(), schedule());

    // Undo brings the overtime back; one more undo, the empty day.
    controller().undo();
    expect(entry(_morning)!.overtimeMinutes, 30);
    controller().undo();
    expect(entry(_morning), isNull);
  });

  test('keeps the note, and a note-only day keeps its extras when the note '
      'goes', () async {
    controller().setDayExtras(_noteOnly, overtimeMinutes: 20);
    expect(entry(_noteOnly)!.note, _demoNote);
    expect(entry(_noteOnly)!.overtimeMinutes, 20);

    controller().setNote(_noteOnly, null);
    expect(entry(_noteOnly), DayEntry(date: _noteOnly, overtimeMinutes: 20));
    expectSameSchedule(await stored(), schedule());
  });

  test('changing the shifts of the day keeps the extras', () async {
    controller().setDayExtras(_morning, overtimeMinutes: 45);
    controller().setDayShifts(_morning, ['night']);
    expect(entry(_morning)!.overtimeMinutes, 45);
    controller().resetToPattern(_morning);
    expect(entry(_morning), DayEntry(date: _morning, overtimeMinutes: 45));
    controller().clearDay(_morning);
    expect(entry(_morning)!.overtimeMinutes, 45);
    expectSameSchedule(await stored(), schedule());
  });

  test('negative minutes clear; more than 24 h is cut to 24 h', () {
    controller().setDayExtras(_rest, overtimeMinutes: 5000);
    expect(entry(_rest)!.overtimeMinutes, maxDayExtraMinutes);
    controller().setDayExtras(_rest, overtimeMinutes: -10);
    expect(entry(_rest), isNull);
  });

  test('setting what the day already has changes nothing and adds no undo '
      'step', () {
    controller().setDayExtras(_morning, overtimeMinutes: 30);
    controller().undo();
    expect(state().canUndo, isFalse);
    final nothing = controller().setDayExtras(_morning, overtimeMinutes: 0);
    expect(nothing, isNull);
    expect(state().canUndo, isFalse);

    controller().setDayExtras(_morning, overtimeMinutes: 30);
    final same = controller().setDayExtras(_morning, overtimeMinutes: 30);
    expect(same, isNull);
  });

  test('undoIfLast works with the step it returns', () {
    final step = controller().setDayExtras(_morning, earlyLeaveMinutes: 15);
    expect(controller().undoIfLast(step!), isTrue);
    expect(entry(_morning), isNull);
  });

  test('duplicating a day carries the extras to the other day', () {
    controller().setDayExtras(
      _morning,
      overtimeMinutes: 60,
      earlyLeaveMinutes: 15,
    );
    controller().copyDay(_morning, _rest);
    expect(entry(_rest)!.overtimeMinutes, 60);
    expect(entry(_rest)!.earlyLeaveMinutes, 15);
  });
}
