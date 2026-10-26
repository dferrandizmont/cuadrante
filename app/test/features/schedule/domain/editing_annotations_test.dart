import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

CivilDate _day(int n) => jan1.addDays(n - 1);

/// 24x72 from 1-Jan-2026: guards on days 1, 5, 9...; the rest are L.
Schedule _base({Map<CivilDate, DayEntry> entries = const {}}) => Schedule(
  shiftTypes: allTypes,
  patterns: [presetPattern('24x72')],
  runs: [PatternRun(id: 'r1', patternId: '24x72', startDate: jan1, seq: 1)],
  entries: entries,
);

DayEntry _annotated(CivilDate d, {List<String>? ids}) => DayEntry(
  date: d,
  shiftTypeIds: ids,
  note: 'Reunión',
  noteReminderMinute: 7 * 60 + 30,
  overtimeMinutes: 90,
  earlyLeaveMinutes: 15,
);

/// Reminder, overtime and early leave follow the rules of the note when the
/// calendar is edited (schema v3).
void main() {
  group('paint keeps what the day holds besides the shifts', () {
    test('painting over a day with a note, reminder and minutes', () {
      final before = _annotated(_day(2), ids: const ['morning']);
      final s = _base(entries: {_day(2): before});
      final patch = s.paint(const PaintTool.replace('afternoon'), [_day(2)]);
      final after = patch.changes[_day(2)]!.after!;
      expect(after.shiftTypeIds, ['afternoon']);
      expect(after.note, 'Reunión');
      expect(after.noteReminderMinute, 450);
      expect(after.overtimeMinutes, 90);
      expect(after.earlyLeaveMinutes, 15);
    });

    test('painting what the pattern gives drops the override but keeps the '
        'entry when it has a reminder, overtime or early leave', () {
      for (final entry in [
        DayEntry(
          date: _day(2),
          shiftTypeIds: const ['morning'],
        ).copyWith(noteReminderMinute: 60),
        DayEntry(
          date: _day(2),
          shiftTypeIds: const ['morning'],
        ).copyWith(overtimeMinutes: 30),
        DayEntry(
          date: _day(2),
          shiftTypeIds: const ['morning'],
        ).copyWith(earlyLeaveMinutes: 10),
      ]) {
        final s = _base(entries: {_day(2): entry});
        // Day 2 is L by the pattern.
        final patch = s.paint(const PaintTool.replace('rest'), [_day(2)]);
        final after = patch.changes[_day(2)]!.after;
        expect(after, isNotNull, reason: '$entry must not be dropped');
        expect(after!.shiftTypeIds, isNull);
        expect(after.isEmpty, isFalse);
      }
    });

    test(
      'painting what the pattern gives drops an entry with nothing else',
      () {
        final s = _base(
          entries: {
            _day(2): DayEntry(date: _day(2), shiftTypeIds: const ['x']),
          },
        );
        final patch = s.paint(const PaintTool.replace('rest'), [_day(2)]);
        expect(patch.changes[_day(2)]!.after, isNull);
      },
    );

    test('erase (Borrar) keeps them like it keeps the note', () {
      final s = _base(entries: {_day(1): _annotated(_day(1))});
      final patch = s.paint(const PaintTool.erase(), [_day(1)]);
      final after = patch.changes[_day(1)]!.after!;
      expect(after.shiftTypeIds, isEmpty);
      expect(after.overtimeMinutes, 90);
      expect(after.noteReminderMinute, 450);
    });
  });

  group('applyPattern with clearOverrides', () {
    test('removes the shift overrides but keeps the rest of the day', () {
      final s = _base(
        entries: {
          _day(3): _annotated(_day(3), ids: const ['morning']),
          _day(4): DayEntry(date: _day(4), shiftTypeIds: const ['night']),
        },
      );
      final change = s.applyPattern(
        '24x72',
        _day(1),
        clearOverrides: true,
        runId: 'r2',
      );
      final kept = change.patch.changes[_day(3)]!.after!;
      expect(kept.shiftTypeIds, isNull);
      expect(kept.note, 'Reunión');
      expect(kept.noteReminderMinute, 450);
      expect(kept.overtimeMinutes, 90);
      expect(kept.earlyLeaveMinutes, 15);
      expect(change.patch.changes[_day(4)]!.after, isNull);
    });

    test('an entry whose only content is overtime survives', () {
      final s = _base(
        entries: {
          _day(3): DayEntry(
            date: _day(3),
            shiftTypeIds: const ['morning'],
            overtimeMinutes: 45,
          ),
        },
      );
      final change = s.applyPattern('24x72', _day(1), clearOverrides: true);
      expect(
        change.patch.changes[_day(3)]!.after,
        DayEntry(date: _day(3), overtimeMinutes: 45),
      );
    });
  });

  test('a patch with annotated entries applies and inverts exactly', () {
    final s = _base();
    final entry = _annotated(_day(6), ids: const ['morning']);
    final patch = EntriesPatch({_day(6): EntryChange(null, entry)});
    final applied = s.apply(ScheduleChange(patch: patch));
    expect(applied.entries[_day(6)], entry);
    final undone = applied.apply(ScheduleChange(patch: patch.inverse()));
    expect(undone.entries, isEmpty);
  });
}
