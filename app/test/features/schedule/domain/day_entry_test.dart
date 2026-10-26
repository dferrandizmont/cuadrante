import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

/// The data a day can hold besides its shifts (schema v3, docs/datos.md): a
/// note with a reminder, overtime and early leave.
void main() {
  group('DayEntry.isEmpty', () {
    test('nothing at all is empty', () {
      expect(DayEntry(date: jan1).isEmpty, isTrue);
      expect(DayEntry(date: jan1, note: '').isEmpty, isTrue);
    });

    test('an override, even an empty one, is not empty', () {
      expect(DayEntry(date: jan1, shiftTypeIds: const []).isEmpty, isFalse);
      expect(DayEntry(date: jan1, shiftTypeIds: const ['a']).isEmpty, isFalse);
    });

    test('a note alone is not empty', () {
      expect(DayEntry(date: jan1, note: 'x').isEmpty, isFalse);
    });

    test('a reminder, overtime or early leave alone is NOT empty', () {
      expect(DayEntry(date: jan1, noteReminderMinute: 0).isEmpty, isFalse);
      expect(DayEntry(date: jan1, noteReminderMinute: 1439).isEmpty, isFalse);
      expect(DayEntry(date: jan1, overtimeMinutes: 30).isEmpty, isFalse);
      expect(DayEntry(date: jan1, earlyLeaveMinutes: 15).isEmpty, isFalse);
    });

    test('0 minutes of overtime or early leave is the same as none', () {
      expect(DayEntry(date: jan1, overtimeMinutes: 0).isEmpty, isTrue);
      expect(DayEntry(date: jan1, earlyLeaveMinutes: 0).isEmpty, isTrue);
      expect(
        DayEntry(date: jan1, overtimeMinutes: 0, note: 'x').isEmpty,
        isFalse,
      );
    });
  });

  group('validation', () {
    test('the reminder is a minute of the day', () {
      expect(DayEntry.isReminderMinute(0), isTrue);
      expect(DayEntry.isReminderMinute(1439), isTrue);
      expect(DayEntry.isReminderMinute(1440), isFalse);
      expect(DayEntry.isReminderMinute(-1), isFalse);
      expect(
        () => DayEntry(date: jan1, noteReminderMinute: 1440),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => DayEntry(date: jan1, noteReminderMinute: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('overtime and early leave cannot be negative', () {
      expect(
        () => DayEntry(date: jan1, overtimeMinutes: -1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => DayEntry(date: jan1, earlyLeaveMinutes: -5),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('copyWith, equality, withShiftTypeIds', () {
    final full = DayEntry(
      date: jan1,
      shiftTypeIds: const ['a'],
      note: 'n',
      noteReminderMinute: 480,
      overtimeMinutes: 60,
      earlyLeaveMinutes: 20,
    );

    test('copyWith changes one field and keeps the rest', () {
      expect(full.copyWith(overtimeMinutes: 90).overtimeMinutes, 90);
      expect(full.copyWith(overtimeMinutes: 90).earlyLeaveMinutes, 20);
      expect(full.copyWith(noteReminderMinute: 0).noteReminderMinute, 0);
      expect(full.copyWith(note: 'm').noteReminderMinute, 480);
    });

    test('each clear flag clears only its field', () {
      expect(full.copyWith(clearNoteReminder: true).noteReminderMinute, isNull);
      expect(full.copyWith(clearNoteReminder: true).overtimeMinutes, 60);
      expect(full.copyWith(clearOvertime: true).overtimeMinutes, isNull);
      expect(full.copyWith(clearOvertime: true).earlyLeaveMinutes, 20);
      expect(full.copyWith(clearEarlyLeave: true).earlyLeaveMinutes, isNull);
      expect(full.copyWith(clearNote: true).note, isNull);
      expect(full.copyWith(clearShiftTypeIds: true).shiftTypeIds, isNull);
    });

    test('every field takes part in == and hashCode', () {
      final same = DayEntry(
        date: jan1,
        shiftTypeIds: const ['a'],
        note: 'n',
        noteReminderMinute: 480,
        overtimeMinutes: 60,
        earlyLeaveMinutes: 20,
      );
      expect(full, same);
      expect(full.hashCode, same.hashCode);
      expect(full, isNot(full.copyWith(noteReminderMinute: 481)));
      expect(full, isNot(full.copyWith(overtimeMinutes: 61)));
      expect(full, isNot(full.copyWith(earlyLeaveMinutes: 21)));
      expect(full, isNot(full.copyWith(clearNoteReminder: true)));
    });

    test('withShiftTypeIds replaces only the override', () {
      final changed = full.withShiftTypeIds(const ['b', 'c']);
      expect(changed.shiftTypeIds, ['b', 'c']);
      expect(changed.note, 'n');
      expect(changed.noteReminderMinute, 480);
      expect(changed.overtimeMinutes, 60);
      expect(changed.earlyLeaveMinutes, 20);
      expect(full.withShiftTypeIds(null).shiftTypeIds, isNull);
      expect(full.withShiftTypeIds(null).overtimeMinutes, 60);
    });
  });
}
