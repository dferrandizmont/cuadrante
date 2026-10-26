import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/patterns/application/post_night_provider.dart';
import 'package:cuadrante/features/patterns/domain/pattern_application.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';

final _now = DateTime(2026, 10, 19, 12);
const _today = CivilDate(2026, 10, 19);

/// `applyPatternRun` and the automatic saliente, against a real database:
/// every change is ONE undo step and the stored data always matches.
void main() {
  late TestStorage storage;
  late ProviderContainer container;

  ScheduleController controller() =>
      container.read(scheduleControllerProvider.notifier);
  ScheduleState state() => container.read(scheduleControllerProvider);
  Schedule schedule() => state().schedule;
  String ids(CivilDate d) => schedule().resolve(d).shiftIds.join('+');

  Future<void> flush() => controller().pendingWrites;

  Future<void> start({bool demo = true}) async {
    storage = await TestStorage.open(now: _now, demo: demo);
    addTearDown(storage.close);
    container = _makeContainer(storage);
  }

  /// Opens the controller again on what the database holds now.
  Future<void> restart() async {
    await flush();
    container.dispose();
    storage = await storage.withReloadedSnapshot();
    container = _makeContainer(storage);
  }

  void paint(PaintTool tool, Iterable<CivilDate> days) {
    final c = controller()..beginStroke(tool);
    for (final d in days) {
      c.paintDay(d);
    }
    c.endStroke();
  }

  Future<void> autoSaliente(bool value) async {
    await container.read(postNightAutoProvider.notifier).set(value);
  }

  PatternRequest request(
    String presetId,
    CivilDate from, {
    CivilDate? until,
    int stepOffset = 0,
    bool clearOverrides = false,
  }) => PatternRequest(
    pattern:
        schedule().patternById(presetId) ??
        patternPresetById(presetId)
            .materialize({for (final t in shiftTemplates) t.key: t.key}),
    from: from,
    until: until,
    stepOffset: stepOffset,
    clearOverrides: clearOverrides,
  );

  group('applyPatternRun', () {
    setUp(start);

    test(
      'one undo step: undo restores the runs and the database exactly',
      () async {
        await flush();
        final before = await dumpTables(storage.database);
        final runsBefore = schedule().runs;
        final from = _today.addDays(20); // Sun 8 Nov

        final step = await controller().applyPatternRun(request('24x72', from));
        expect(step, isNotNull);
        expect(step!.isEmpty, isFalse);

        // The old open run is cut the day before; the new one is open.
        expect(schedule().runs, hasLength(2));
        final cut = schedule().runs.firstWhere((r) => r.id == 'run-1');
        expect(cut.endDate, from.addDays(-1));
        final added = schedule().runs.firstWhere((r) => r.id != 'run-1');
        expect(added.patternId, '24x72');
        expect(added.startDate, from);
        expect(added.endDate, isNull);
        expect(ids(from), 'guard24');
        expect(ids(from.addDays(1)), 'rest');
        expect(ids(from.addDays(4)), 'guard24');
        expect(state().canUndo, isTrue);

        await flush();
        expect(
          (await dumpTables(storage.database))['pattern_runs'],
          hasLength(2),
        );

        controller().undo();
        expect(schedule().runs, runsBefore);
        expect(state().canUndo, isFalse, reason: 'a single step');
        await flush();
        expect(await dumpTables(storage.database), before);

        controller().redo();
        await flush();
        expect(ids(from), 'guard24');
        expect(
          (await dumpTables(storage.database))['pattern_runs'],
          hasLength(2),
        );
      },
    );

    test('the new run takes nextRunSeq: above every calendar', () async {
      final calendars = CalendarsRepository(storage.database);
      final other = (await calendars.create(name: 'Pareja', colorValue: 1)).id;
      await ScheduleRepository(storage.database, now: () => _now).apply(
        other,
        ScheduleChange(
          runsAfter: [
            PatternRun(
              id: 'pareja-run',
              patternId: 'correturnos',
              startDate: _today,
              seq: 50,
            ),
          ],
        ),
      );

      await controller().applyPatternRun(request('5x2', _today));
      await flush();

      final added = schedule().runs.firstWhere((r) => r.patternId == '5x2');
      expect(added.seq, 51, reason: 'the other calendar uses 50');
      final rows = await storage.database
          .customSelect('SELECT seq FROM pattern_runs ORDER BY seq')
          .get();
      expect([for (final r in rows) r.read<int>('seq')], [1, 50, 51]);
      // Nothing was lost: no recovery reload happened.
      expect(state().saveErrors, 0);
    });

    test('two applications in a row get two different seq', () async {
      await controller().applyPatternRun(request('6x4', _today.addDays(7)));
      await controller().applyPatternRun(
        request('4x4', _today.addDays(14), until: _today.addDays(30)),
      );
      await flush();
      expect(state().saveErrors, 0);
      final seqs = [for (final r in schedule().runs) r.seq];
      expect(seqs.toSet(), hasLength(seqs.length));
      expect(seqs.reduce((a, b) => a > b ? a : b), 3);
    });

    test('bounded: the earlier rotation comes back after the end', () async {
      final from = _today.addDays(7);
      final until = _today.addDays(13);
      await controller().applyPatternRun(request('24x72', from, until: until));
      expect(ids(from), 'guard24');
      expect(ids(until), 'rest');
      expect(
        schedule().resolve(until.addDays(1)).runId,
        'run-1',
        reason: 'the correturnos run resumes after the end',
      );
      await flush();
      expect(state().saveErrors, 0);
    });

    test('keeps the days changed by hand, or replaces them', () async {
      // The demo has a hand-made Mañana+Tarde on _today + 2 (Wed 21 Oct).
      final day = _today.addDays(2);
      expect(ids(day), 'morning+afternoon');

      await controller().applyPatternRun(request('5x2', _today));
      expect(ids(day), 'morning+afternoon', reason: 'respected');

      controller().undo();
      await controller().applyPatternRun(
        request('5x2', _today, clearOverrides: true),
      );
      expect(ids(day), isNot('morning+afternoon'));
      expect(schedule().entries[day], isNull);
      await flush();

      controller().undo();
      expect(ids(day), 'morning+afternoon', reason: 'undo gives it back');
      await flush();
      final stored = await dumpTables(storage.database);
      expect(
        (stored['day_entries']!).any((r) => r['date'] == day.toIso()),
        isTrue,
      );
    });

    test('a custom pattern is stored with its run', () async {
      const custom = Pattern(
        id: 'custom-1',
        name: 'Mi cuadrante',
        steps: [
          ['morning'],
          ['morning', 'afternoon'],
          [],
          ['rest'],
        ],
      );
      await controller().applyPatternRun(
        PatternRequest(pattern: custom, from: _today.addDays(30)),
      );
      await flush();
      expect(state().saveErrors, 0);
      expect(schedule().patternById('custom-1'), custom);
      final reloaded = await ScheduleRepository(
        storage.database,
        now: () => _now,
      ).load(state().calendarId);
      expect(reloaded.schedule.patternById('custom-1'), custom);
      expect(
        reloaded.schedule.runs.where((r) => r.patternId == 'custom-1'),
        hasLength(1),
      );
      expect(ids(_today.addDays(31)), 'morning+afternoon');
      expect(ids(_today.addDays(32)), '');
    });

    test(
      'missing shift types and pattern are created from the templates',
      () async {
        // The user deleted the 12 h types and the DuPont pattern is gone too.
        await storage.database.customStatement(
          "DELETE FROM shift_types WHERE id IN ('day12', 'night12')",
        );
        await storage.database.customStatement(
          "DELETE FROM patterns WHERE id = 'dupont'",
        );
        await restart();
        expect(schedule().shiftTypeById('night12'), isNull);
        expect(schedule().patternById('dupont'), isNull);

        await controller().applyPatternRun(
          request('dupont', _today.addDays(7)),
        );
        await flush();

        expect(state().saveErrors, 0);
        expect(schedule().shiftTypeById('night12')?.code, 'N12');
        expect(schedule().shiftTypeById('day12')?.durationMinutes, 720);
        expect(ids(_today.addDays(7)), 'night12');
        expect(
          state().palette.map((t) => t.id),
          containsAll(['day12', 'night12']),
        );

        // And they are really in the database.
        final reloaded = await ScheduleRepository(
          storage.database,
          now: () => _now,
        ).load(state().calendarId);
        expect(reloaded.palette.map((t) => t.id), contains('night12'));
        expect(reloaded.schedule.patternById('dupont')?.lengthDays, 28);
        expect(
          reloaded.schedule.runs.any((r) => r.patternId == 'dupont'),
          isTrue,
        );
      },
    );

    test('an open stroke is closed first', () async {
      controller().beginStroke(const PaintTool.replace('night'));
      controller().paintDay(_today.addDays(40));
      await controller().applyPatternRun(request('5x2', _today.addDays(7)));
      expect(controller().strokeActive, isFalse);
      expect(ids(_today.addDays(40)), isNot(''));
    });

    test('undoIfLast undoes the application only while it is the last step; '
        'a later stroke is left alone', () async {
      final runsBefore = schedule().runs;
      final step = await controller().applyPatternRun(
        request('5x2', _today.addDays(7)),
      );
      expect(step, isNotNull);
      final day = _today.addDays(3);
      paint(const PaintTool.replace('guard24'), [day]);

      expect(controller().undoIfLast(step!), isFalse);
      expect(ids(day), 'guard24');
      expect(schedule().runs, hasLength(runsBefore.length + 1));

      controller().undo(); // the stroke
      expect(controller().undoIfLast(step), isTrue);
      expect(schedule().runs, runsBefore);
    });
  });

  group('Saliente automático', () {
    // 10 Jun 2026: before the demo rotation (13 Jul), so empty.
    const empty = CivilDate(2026, 6, 10);

    setUp(start);

    test('off by default: a night leaves the next day alone', () async {
      expect(state().schedule.resolve(empty).isEmpty, isTrue);
      paint(const PaintTool.replace('night'), [empty]);
      expect(ids(empty), 'night');
      expect(ids(empty.addDays(1)), '');
      await flush();
      expect(state().saveErrors, 0);
    });

    test(
      'on: painting a night makes the empty next day Saliente, in one undo',
      () async {
        await autoSaliente(true);
        await flush();
        final before = await dumpTables(storage.database);

        paint(const PaintTool.replace('night'), [empty]);
        expect(ids(empty), 'night');
        expect(ids(empty.addDays(1)), 'postNight');
        await flush();
        expect(state().saveErrors, 0);
        final stored = await dumpTables(storage.database);
        expect([
          for (final r in stored['day_entries']!) r['date'],
        ], containsAll([empty.toIso(), empty.addDays(1).toIso()]));

        controller().undo();
        expect(ids(empty), '');
        expect(ids(empty.addDays(1)), '');
        expect(
          state().canUndo,
          isFalse,
          reason: 'night and saliente: one step',
        );
        await flush();
        expect(await dumpTables(storage.database), before);

        controller().redo();
        expect(ids(empty.addDays(1)), 'postNight');
      },
    );

    test('on: a Libre next day becomes Saliente', () async {
      await autoSaliente(true);
      // Sat 24 Oct is Libre (and so is Sun 25): a night on the 24th.
      const sat = CivilDate(2026, 10, 24);
      expect(ids(sat.addDays(1)), 'rest');
      paint(const PaintTool.replace('night'), [sat]);
      expect(ids(sat.addDays(1)), 'postNight');
    });

    test(
      'on: only empty or Libre days change, never a shift or an absence',
      () async {
        await autoSaliente(true);
        // Next day is a Mañana of the rotation (Wed 28 -> Thu 29).
        const wed = CivilDate(2026, 10, 28);
        expect(ids(wed.addDays(1)), 'morning');
        paint(const PaintTool.replace('night'), [wed]);
        expect(ids(wed.addDays(1)), 'morning');

        // Next day is a hand-made vacation (Mon 2 Nov is not; the 27th and 28th
        // are: demo vacation on today+8 and +9 = 27 and 28 Oct).
        final eve = _today.addDays(7); // Mon 26 Oct
        expect(ids(eve.addDays(1)), 'vacation');
        paint(const PaintTool.replace('night'), [eve]);
        expect(ids(eve.addDays(1)), 'vacation');
      },
    );

    test(
      'on: a shift that does not end next morning asks for nothing',
      () async {
        await autoSaliente(true);
        paint(const PaintTool.replace('afternoon'), [empty]);
        expect(ids(empty.addDays(1)), '');
        // A 24 h guard does end the next morning.
        paint(const PaintTool.replace('guard24'), [empty.addDays(5)]);
        expect(ids(empty.addDays(6)), 'postNight');
      },
    );

    test('on: a stroke of several nights only closes the last one', () async {
      await autoSaliente(true);
      paint(const PaintTool.replace('night'), [
        empty,
        empty.addDays(1),
        empty.addDays(2),
      ]);
      expect(ids(empty.addDays(1)), 'night');
      expect(ids(empty.addDays(2)), 'night');
      expect(ids(empty.addDays(3)), 'postNight');
    });

    test('on: the Saliente type is created when it does not exist', () async {
      await storage.database.customStatement(
        "DELETE FROM shift_types WHERE id = 'postNight'",
      );
      await restart();
      await autoSaliente(true);
      expect(schedule().shiftTypeById('postNight'), isNull);

      paint(const PaintTool.replace('night'), [empty]);
      expect(ids(empty.addDays(1)), 'postNight');
      expect(state().palette.map((t) => t.id), contains('postNight'));
      await flush();
      expect(state().saveErrors, 0);
      final rows = await storage.database
          .customSelect("SELECT id FROM shift_types WHERE id = 'postNight'")
          .get();
      expect(rows, hasLength(1));
    });

    test('on: a Saliente the user archived is respected', () async {
      await ScheduleRepository(
        storage.database,
        now: () => _now,
      ).archiveShiftType('postNight');
      await restart();
      await autoSaliente(true);
      paint(const PaintTool.replace('night'), [empty]);
      expect(ids(empty.addDays(1)), '');
    });

    test('the setting is stored and read back', () async {
      expect(container.read(postNightAutoProvider), isFalse);
      await autoSaliente(true);
      expect(container.read(postNightAutoProvider), isTrue);

      final fresh = ProviderContainer(
        overrides: [
          ...storage.overrides,
          clockProvider.overrideWithValue(() => _now),
        ],
      );
      addTearDown(fresh.dispose);
      fresh.read(postNightAutoProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(fresh.read(postNightAutoProvider), isTrue);
      await fresh.read(postNightAutoProvider.notifier).set(false);
      expect(
        await fresh.read(postNightSettingsRepositoryProvider).loadAuto(),
        isFalse,
      );
    });

    test(
      'on: applying a guard pattern adds the saliente days, one undo',
      () async {
        await autoSaliente(true);
        await flush();
        final before = await dumpTables(storage.database);
        // 24x72 (G L L L) from 1 Jun to 12 Jun 2026: guards on 1, 5 and 9.
        const from = CivilDate(2026, 6, 1);
        await controller().applyPatternRun(
          request('24x72', from, until: const CivilDate(2026, 6, 12)),
        );
        expect(ids(from), 'guard24');
        expect(ids(from.addDays(1)), 'postNight');
        expect(ids(from.addDays(2)), 'rest');
        expect(ids(from.addDays(5)), 'postNight');
        expect(ids(from.addDays(9)), 'postNight');
        expect(ids(from.addDays(3)), 'rest');
        await flush();
        expect(state().saveErrors, 0);

        controller().undo();
        expect(ids(from.addDays(1)), '');
        expect(schedule().entries.keys.any((d) => d.month == 6), isFalse);
        await flush();
        expect(await dumpTables(storage.database), before);
      },
    );

    test('off: applying the same pattern adds no saliente', () async {
      const from = CivilDate(2026, 6, 1);
      await controller().applyPatternRun(
        request('24x72', from, until: const CivilDate(2026, 6, 12)),
      );
      expect(ids(from.addDays(1)), 'rest');
      expect(schedule().entries.containsKey(from.addDays(1)), isFalse);
    });
  });
}

ProviderContainer _makeContainer(TestStorage storage) {
  final c = ProviderContainer(
    overrides: [
      ...storage.overrides,
      clockProvider.overrideWithValue(() => _now),
    ],
  );
  addTearDown(() async {
    try {
      await c.read(scheduleControllerProvider.notifier).pendingWrites;
    } catch (_) {
      // Already disposed by `restart`.
    }
    c.dispose();
  });
  return c;
}
