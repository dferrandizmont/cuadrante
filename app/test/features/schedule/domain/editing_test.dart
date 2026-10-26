import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

CivilDate _day(int n) => jan1.addDays(n - 1);

/// 24x72 from 1-Jan-2026: guards on days 1, 5, 9...; the rest are L.
Schedule _base({
  Map<CivilDate, DayEntry> entries = const {},
  List<PatternRun>? runs,
}) => Schedule(
  shiftTypes: allTypes,
  patterns: [
    presetPattern('24x72'),
    presetPattern('5x2'),
    presetPattern('6x4'),
  ],
  runs:
      runs ??
      [PatternRun(id: 'r1', patternId: '24x72', startDate: jan1, seq: 1)],
  entries: entries,
);

DayEntry _e(CivilDate d, [List<String>? ids, String? note]) =>
    DayEntry(date: d, shiftTypeIds: ids, note: note);

void main() {
  group('PaintTool', () {
    test('apply', () {
      expect(const PaintTool.replace('a').apply(['x', 'y']), ['a']);
      expect(const PaintTool.add('a').apply(['x']), ['x', 'a']);
      expect(const PaintTool.add('a').apply(['a', 'x']), ['a', 'x']);
      expect(const PaintTool.add('a').apply([]), ['a']);
      expect(const PaintTool.erase().apply(['x']), isEmpty);
    });
  });

  group('paint', () {
    test(
      'replace creates an override on a day that differs from the pattern',
      () {
        final s = _base();
        final patch = s.paint(const PaintTool.replace('morning'), [_day(1)]);
        expect(patch.changes, {
          _day(1): EntryChange(null, _e(_day(1), ['morning'])),
        });
        expect(
          s.apply(ScheduleChange(patch: patch)).resolve(_day(1)).shiftIds,
          ['morning'],
        );
      },
    );

    test('replace with what the pattern gives changes nothing', () {
      final s = _base();
      expect(
        s.paint(const PaintTool.replace('guard24'), [_day(1), _day(5)]).isEmpty,
        isTrue,
      );
      expect(
        s.paint(const PaintTool.replace('rest'), [_day(2)]).isEmpty,
        isTrue,
      );
    });

    test('add doubles up from the effective shifts', () {
      final s = _base();
      final patch = s.paint(const PaintTool.add('morning'), [_day(1), _day(2)]);
      expect(patch.changes[_day(1)]!.after!.shiftTypeIds, [
        'guard24',
        'morning',
      ]);
      expect(patch.changes[_day(2)]!.after!.shiftTypeIds, ['rest', 'morning']);
      // Already present: no change.
      expect(
        s.paint(const PaintTool.add('guard24'), [_day(1)]).isEmpty,
        isTrue,
      );
    });

    test('add starts from an existing override, not from the pattern', () {
      final s = _base(
        entries: {
          _day(1): _e(_day(1), ['night']),
        },
      );
      final patch = s.paint(const PaintTool.add('morning'), [_day(1)]);
      expect(patch.changes[_day(1)]!.after!.shiftTypeIds, ['night', 'morning']);
    });

    test('erase empties a day with pattern and is a no-op on an empty one', () {
      final s = _base();
      final patch = s.paint(const PaintTool.erase(), [_day(1)]);
      expect(patch.changes[_day(1)]!.after!.shiftTypeIds, isEmpty);
      expect(
        s.apply(ScheduleChange(patch: patch)).resolve(_day(1)).shifts,
        isEmpty,
      );
      expect(
        s.paint(const PaintTool.erase(), [jan1.addDays(-5)]).isEmpty,
        isTrue,
      );
    });

    test('normalizes: painting back to the pattern removes the override', () {
      var s = _base(
        entries: {
          _day(1): _e(_day(1), ['morning']),
        },
      );
      final patch = s.paint(const PaintTool.replace('guard24'), [_day(1)]);
      expect(patch.changes[_day(1)]!.after, isNull);
      s = s.apply(ScheduleChange(patch: patch));
      expect(s.entries, isEmpty);
    });

    test(
      'normalizes: erase over a day with empty pattern drops the override',
      () {
        final out = jan1.addDays(-3);
        final s = _base(
          entries: {
            out: _e(out, ['morning']),
          },
        );
        final patch = s.paint(const PaintTool.erase(), [out]);
        expect(patch.changes[out]!.after, isNull);
      },
    );

    test(
      'normalizes: an empty override that matches an empty pattern step',
      () {
        final s = Schedule(
          shiftTypes: allTypes,
          patterns: const [
            Pattern(
              id: 'p',
              name: 'p',
              steps: [
                ['morning'],
                [],
              ],
            ),
          ],
          runs: [PatternRun(id: 'r', patternId: 'p', startDate: jan1, seq: 1)],
          entries: {
            _day(2): _e(_day(2), ['night']),
          },
        );
        final patch = s.paint(const PaintTool.erase(), [_day(2)]);
        expect(patch.changes[_day(2)]!.after, isNull);
      },
    );

    test('the note survives painting, also when the override is dropped', () {
      final s = _base(
        entries: {
          _day(1): _e(_day(1), ['morning'], 'swap'),
        },
      );
      final back = s.paint(const PaintTool.replace('guard24'), [_day(1)]);
      expect(back.changes[_day(1)]!.after, _e(_day(1), null, 'swap'));
      final other = s.paint(const PaintTool.replace('night'), [_day(1)]);
      expect(other.changes[_day(1)]!.after, _e(_day(1), ['night'], 'swap'));
      final noted = _base(entries: {_day(2): _e(_day(2), null, 'note')});
      final erased = noted.paint(const PaintTool.erase(), [_day(2)]);
      expect(erased.changes[_day(2)]!.after, _e(_day(2), [], 'note'));
    });

    test('unchanged and duplicated days are handled', () {
      final s = _base();
      final patch = s.paint(const PaintTool.replace('morning'), [
        _day(1),
        _day(1),
        _day(2),
      ]);
      expect(patch.changes.keys, [_day(1), _day(2)]);
      expect(patch.changes.length, 2);
      expect(s.paint(const PaintTool.erase(), const []).isEmpty, isTrue);
    });

    test('applyTo does not mutate the source map', () {
      final s = _base();
      final before = {...s.entries};
      final patch = s.paint(const PaintTool.replace('morning'), [_day(1)]);
      final applied = patch.applyTo(s.entries);
      expect(s.entries, before);
      expect(applied, isNot(before));
    });

    test('inverse() restores the exact map after a sequence of strokes', () {
      var s = _base(
        entries: {
          _day(1): _e(_day(1), ['night'], 'a'),
          _day(3): _e(_day(3), null, 'only note'),
          _day(7): _e(_day(7), []),
        },
      );
      final original = {...s.entries};
      final strokes = [
        (
          const PaintTool.replace('morning'),
          [for (var i = 1; i <= 6; i++) _day(i)],
        ),
        (const PaintTool.add('afternoon'), [_day(2), _day(7), _day(8)]),
        (const PaintTool.erase(), [_day(1), _day(5), _day(9)]),
        (const PaintTool.replace('guard24'), [_day(1), _day(9), _day(13)]),
      ];
      final patches = <EntriesPatch>[];
      for (final (tool, days) in strokes) {
        final p = s.paint(tool, days);
        patches.add(p);
        s = s.apply(ScheduleChange(patch: p));
      }
      expect(s.entries, isNot(original));
      for (final p in patches.reversed) {
        s = s.apply(ScheduleChange(patch: p.inverse()));
      }
      expect(s.entries, original);
      expect(patches.first.inverse().inverse(), patches.first);
    });
  });

  group('UndoStack', () {
    ScheduleChange change(int n) => ScheduleChange(
      patch: EntriesPatch({
        _day(n): EntryChange(null, _e(_day(n), ['morning'])),
      }),
    );

    test('undo returns the inverse, redo the original', () {
      final stack = UndoStack();
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isFalse);
      expect(stack.undo(), isNull);
      expect(stack.redo(), isNull);

      final c = change(1);
      stack.push(c);
      expect(stack.canUndo, isTrue);
      final undone = stack.undo()!;
      expect(
        undone.patch.changes[_day(1)],
        EntryChange(_e(_day(1), ['morning']), null),
      );
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isTrue);
      expect(identical(stack.redo(), c), isTrue);
      expect(stack.canUndo, isTrue);
      expect(stack.canRedo, isFalse);
    });

    test('push clears the redo history', () {
      final stack = UndoStack()
        ..push(change(1))
        ..push(change(2));
      stack.undo();
      expect(stack.canRedo, isTrue);
      stack.push(change(3));
      expect(stack.canRedo, isFalse);
    });

    test('discardRedo preserves the other redo steps and the undo history', () {
      final first = change(1);
      final removed = change(2);
      final last = change(3);
      final stack = UndoStack()
        ..push(first)
        ..push(removed)
        ..push(last);
      stack.undo();
      stack.undo();
      stack.discardRedo(removed);
      stack.discardRedo(change(3)); // Not the same instance.
      expect(stack.last, same(first));
      expect(stack.redo(), same(last));
      expect(stack.redo(), isNull);
      expect(stack.undo()!.patch, last.patch.inverse());
      expect(stack.undo()!.patch, first.patch.inverse());
      expect(stack.undo(), isNull);
    });

    test('limit of 100 drops the oldest step', () {
      final stack = UndoStack();
      expect(stack.limit, 100);
      for (var i = 0; i < 105; i++) {
        stack.push(change(1 + i));
      }
      var undone = 0;
      while (stack.undo() != null) {
        undone++;
      }
      expect(undone, 100);
      final small = UndoStack(limit: 2)
        ..push(change(1))
        ..push(change(2))
        ..push(change(3));
      expect(small.undo()!.patch.changes.keys.single, _day(3));
      expect(small.undo()!.patch.changes.keys.single, _day(2));
      expect(small.undo(), isNull);
    });

    test('empty changes are ignored; a drag is a single undo step', () {
      final stack = UndoStack()..push(const ScheduleChange());
      expect(stack.canUndo, isFalse);

      var s = _base();
      final drag = s.paint(const PaintTool.replace('morning'), [
        _day(1),
        _day(2),
        _day(3),
        _day(4),
      ]);
      stack.push(ScheduleChange(patch: drag));
      s = s.apply(ScheduleChange(patch: drag));
      expect(s.entries.length, 4);
      s = s.apply(stack.undo()!);
      expect(s.entries, isEmpty);
      expect(stack.canUndo, isFalse);
    });

    test('clear', () {
      final stack = UndoStack()..push(change(1));
      stack.undo();
      stack.clear();
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isFalse);
    });
  });

  group('applyPattern', () {
    final from = _day(11);

    test(
      'cuts active runs at from - 1 and adds the new run with seq max + 1',
      () {
        final s = _base();
        final change = s.applyPattern('5x2', from, runId: 'new');
        final next = s.apply(change);
        expect(next.runs.length, 2);
        expect(next.runs[0], s.runs[0].copyWith(endDate: _day(10)));
        expect(
          next.runs[1],
          PatternRun(id: 'new', patternId: '5x2', startDate: from, seq: 2),
        );
        expect(next.resolve(_day(10)).source, DaySource.pattern);
        expect(next.resolve(_day(10)).runId, 'r1');
        expect(next.resolve(from).runId, 'new');
        expect(next.resolve(from).shiftIds, ['morning']);
        // Original untouched, change undoable.
        expect(s.runs.single.endDate, isNull);
        expect(change.runsBefore, s.runs);
        expect(s.apply(change).apply(change.inverse()).runs, s.runs);
      },
    );

    test(
      'deletes runs that start on or after from, keeps earlier finished ones',
      () {
        final s = _base(
          runs: [
            PatternRun(
              id: 'old',
              patternId: '6x4',
              startDate: _day(-30),
              endDate: _day(-1),
              seq: 1,
            ),
            PatternRun(id: 'a', patternId: '24x72', startDate: jan1, seq: 2),
            PatternRun(
              id: 'b',
              patternId: '5x2',
              startDate: from,
              endDate: _day(20),
              seq: 3,
            ),
            PatternRun(id: 'c', patternId: '6x4', startDate: _day(40), seq: 4),
          ],
        );
        final next = s.apply(
          s.applyPattern(
            '6x4',
            from,
            until: _day(30),
            stepOffset: 3,
            runId: 'n',
          ),
        );
        // Bounded: 'b' lies inside [from, 30] and goes; the rest stay as-is.
        expect(next.runs.map((r) => r.id), ['old', 'a', 'c', 'n']);
        expect(next.runs[0].endDate, _day(-1));
        expect(next.runs[1].endDate, isNull);
        expect(next.runs[3].seq, 5);
        expect(next.runs[3].endDate, _day(30));
        expect(next.runs[3].stepOffset, 3);
        // stepOffset 3 of 6x4 at `from` is M (index 3).
        expect(next.resolve(from).stepIndex, 3);
        expect(next.resolve(_day(30)).runId, 'n');
        // The previous rotation resumes after `until`.
        expect(next.resolve(_day(31)).runId, 'a');
        expect(next.resolve(_day(40)).runId, 'c');
      },
    );

    test('a run ending before from is not touched', () {
      final s = _base(
        runs: [
          PatternRun(
            id: 'a',
            patternId: '24x72',
            startDate: jan1,
            endDate: _day(5),
            seq: 1,
          ),
        ],
      );
      final next = s.apply(s.applyPattern('5x2', from));
      expect(next.runs.first, s.runs.first);
      expect(next.runs.last.id, 'run-2');
    });

    test('first run of an empty schedule gets seq 1', () {
      final s = Schedule(
        shiftTypes: allTypes,
        patterns: [presetPattern('5x2')],
      );
      final next = s.apply(s.applyPattern('5x2', jan1));
      expect(next.runs.single.seq, 1);
      expect(next.resolve(jan1).shiftIds, ['morning']);
    });

    test(
      'keeps overrides by default and removes only shift overrides when asked',
      () {
        final inRange = _day(12);
        final noteOnly = _day(13);
        final outside = _day(5);
        final past = _day(60);
        final s = _base(
          entries: {
            inRange: _e(inRange, ['night'], 'keep me'),
            _day(14): _e(_day(14), ['night']),
            noteOnly: _e(noteOnly, null, 'only note'),
            outside: _e(outside, ['night']),
            past: _e(past, ['night']),
          },
        );

        final kept = s.applyPattern('5x2', from, until: _day(30));
        expect(kept.patch.isEmpty, isTrue);
        expect(s.apply(kept).entries, s.entries);

        final change = s.applyPattern(
          '5x2',
          from,
          until: _day(30),
          clearOverrides: true,
        );
        final next = s.apply(change);
        expect(next.entries[inRange], _e(inRange, null, 'keep me'));
        expect(next.entries.containsKey(_day(14)), isFalse);
        expect(next.entries[noteOnly], _e(noteOnly, null, 'only note'));
        expect(next.entries[outside], s.entries[outside]);
        expect(next.entries[past], s.entries[past]);

        // Open-ended range reaches the later override too.
        final open = s.apply(s.applyPattern('5x2', from, clearOverrides: true));
        expect(open.entries.containsKey(past), isFalse);

        // Fully undoable.
        final undone = next.apply(change.inverse());
        expect(undone.entries, s.entries);
        expect(undone.runs, s.runs);
      },
    );

    test('rejects unknown patterns and inverted ranges', () {
      final s = _base();
      expect(() => s.applyPattern('nope', from), throwsArgumentError);
      expect(
        () => s.applyPattern('5x2', from, until: _day(1)),
        throwsArgumentError,
      );
    });
  });
}
