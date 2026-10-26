import 'package:cuadrante/features/calendar/domain/range_editing.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../schedule/domain/fixtures.dart';

CivilDate _day(int n) => jan1.addDays(n - 1);

/// 5x2 from 1-Jan-2026 (a Thursday): M M M M M L L ...
Schedule _base(Map<CivilDate, DayEntry> entries) => Schedule(
  shiftTypes: allTypes,
  patterns: [presetPattern('5x2')],
  runs: [PatternRun(id: 'r1', patternId: '5x2', startDate: jan1, seq: 1)],
  entries: entries,
);

/// The reminder of the note, the overtime and the early leave travel with the
/// note: copied, pasted and repeated exactly when the notes are (schema v3).
void main() {
  final source = _base({
    _day(1): DayEntry(
      date: _day(1),
      note: 'Dentista',
      noteReminderMinute: 8 * 60,
      overtimeMinutes: 45,
      earlyLeaveMinutes: 10,
    ),
    _day(2): DayEntry(date: _day(2), overtimeMinutes: 30),
    _day(3): DayEntry(date: _day(3), noteReminderMinute: 9 * 60),
    _day(4): DayEntry(date: _day(4), overtimeMinutes: 0, note: '  '),
  });

  group('capture', () {
    test('keeps the reminder, overtime and early leave of each day', () {
      final clip = DayClipboard.capture(source, [_day(1), _day(2), _day(3)]);
      expect(clip.days[0].note, 'Dentista');
      expect(clip.days[0].noteReminderMinute, 480);
      expect(clip.days[0].overtimeMinutes, 45);
      expect(clip.days[0].earlyLeaveMinutes, 10);
      expect(clip.days[1].overtimeMinutes, 30);
      expect(clip.days[1].note, isNull);
      expect(clip.days[2].noteReminderMinute, 540);
    });

    test('0 minutes and a blank note count as nothing', () {
      final clip = DayClipboard.capture(source, [_day(4)]);
      expect(clip.days.single.note, isNull);
      expect(clip.days.single.overtimeMinutes, isNull);
      expect(clip.days.single.hasAnnotations, isFalse);
      expect(clip.hasNotes, isFalse);
    });

    test('hasNotes is true for a day with only overtime', () {
      expect(DayClipboard.capture(source, [_day(2)]).hasNotes, isTrue);
      expect(DayClipboard.capture(source, [_day(3)]).hasNotes, isTrue);
    });

    test('ClipDay compares every field', () {
      const a = ClipDay(offset: 0, shiftIds: ['x'], overtimeMinutes: 5);
      expect(a, const ClipDay(offset: 0, shiftIds: ['x'], overtimeMinutes: 5));
      expect(
        a,
        isNot(const ClipDay(offset: 0, shiftIds: ['x'], overtimeMinutes: 6)),
      );
      expect(
        a,
        isNot(const ClipDay(offset: 0, shiftIds: ['x'], earlyLeaveMinutes: 5)),
      );
      expect(
        a,
        isNot(const ClipDay(offset: 0, shiftIds: ['x'], noteReminderMinute: 5)),
      );
    });
  });

  group('planPlacements', () {
    final clip = DayClipboard.capture(source, [_day(1), _day(2), _day(3)]);
    final destination = _base({
      _day(11): DayEntry(
        date: _day(11),
        note: 'Mía',
        noteReminderMinute: 600,
        overtimeMinutes: 5,
        earlyLeaveMinutes: 6,
      ),
      _day(12): DayEntry(date: _day(12), note: 'Otra', overtimeMinutes: 99),
    });

    test('without includeNotes the destination is never touched', () {
      final placed = planPlacements(destination, clip, [_day(11)]);
      final kept = placed[_day(11)]!;
      expect(kept.note, 'Mía');
      expect(kept.noteReminderMinute, 600);
      expect(kept.overtimeMinutes, 5);
      expect(kept.earlyLeaveMinutes, 6);
      // A day that had none gets none.
      expect(placed[_day(13)]!.noteReminderMinute, isNull);
      expect(placed[_day(13)]!.overtimeMinutes, isNull);
      expect(placed[_day(13)]!.note, isNull);
    });

    test('with includeNotes, copied values replace and missing ones leave '
        'the destination alone', () {
      final placed = planPlacements(destination, clip, [
        _day(11),
      ], includeNotes: true);
      // Copied day 1 has all four: they replace the destination's.
      final first = placed[_day(11)]!;
      expect(first.note, 'Dentista');
      expect(first.noteReminderMinute, 480);
      expect(first.overtimeMinutes, 45);
      expect(first.earlyLeaveMinutes, 10);
      // Copied day 2 has only overtime: the destination's note stays.
      final second = placed[_day(12)]!;
      expect(second.overtimeMinutes, 30);
      expect(second.note, 'Otra');
      expect(second.noteReminderMinute, isNull);
      // Copied day 3 has only a reminder, onto a day with nothing: the entry
      // exists (not empty) with just the reminder.
      final third = placed[_day(13)]!;
      expect(third.noteReminderMinute, 540);
      expect(third.note, isNull);
      expect(third.isEmpty, isFalse);
    });

    test('shifts are replaced either way and the annotations of the '
        'destination survive', () {
      final placed = planPlacements(destination, clip, [_day(11)]);
      expect(
        placed[_day(11)]!.shiftTypeIds,
        isNull,
        reason: 'same as rotation',
      );
      final shifted = planPlacements(
        _base({
          _day(11): DayEntry(
            date: _day(11),
            shiftTypeIds: const ['guard24'],
            overtimeMinutes: 20,
          ),
        }),
        clip,
        [_day(11)],
      );
      expect(shifted[_day(11)]!.overtimeMinutes, 20);
    });

    test('several starts (Repetir) copy to each block', () {
      final placed = planPlacements(destination, clip, [
        _day(11),
        _day(21),
      ], includeNotes: true);
      expect(placed[_day(21)]!.noteReminderMinute, 480);
      expect(placed[_day(22)]!.overtimeMinutes, 30);
      expect(placed[_day(23)]!.noteReminderMinute, 540);
    });
  });

  test('entryWithShifts keeps every annotation of the day', () {
    final entry = entryWithShifts(source, _day(1), const ['afternoon']);
    expect(entry.shiftTypeIds, ['afternoon']);
    expect(entry.note, 'Dentista');
    expect(entry.noteReminderMinute, 480);
    expect(entry.overtimeMinutes, 45);
    expect(entry.earlyLeaveMinutes, 10);
  });
}
