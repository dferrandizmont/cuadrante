import 'package:cuadrante/core/database/database_opener.dart';
import 'package:cuadrante/core/diagnostics/crash_reporting.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/data/schedule_snapshot.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/probes.dart';
import '../../support/test_storage.dart';

final _now = DateTime(2026, 10, 19, 12);
const _today = CivilDate(2026, 10, 19);

/// A reporter that throws synchronously, like a broken Crashlytics bridge.
class _ThrowingCrashReporter implements CrashReporter {
  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<void> record(Object error, StackTrace? stack, {required bool fatal}) =>
      throw StateError('reporter exploded');
}

/// The first write fails and the reload after it fails too.
class _FlakyLoadRepository extends ProbeRepository {
  _FlakyLoadRepository(super.db, {super.now}) : super(failCalls: {0});

  bool _failLoad = true;

  @override
  Future<ScheduleSnapshot> load(String calendarId) async {
    if (_failLoad) {
      _failLoad = false;
      throw StateError('read failed');
    }
    return super.load(calendarId);
  }
}

void main() {
  late TestStorage storage;
  late RecordingCrashReporter reporter;
  late ProviderContainer container;

  Future<ProviderContainer> makeContainer(
    TestStorage s, {
    ScheduleRepository? repository,
    CrashReporter? crashReporter,
  }) async {
    final c = ProviderContainer(
      overrides: [
        ...s.overrides,
        clockProvider.overrideWithValue(() => _now),
        crashReporterProvider.overrideWithValue(crashReporter ?? reporter),
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

  void paint(PaintTool tool, Iterable<CivilDate> days) {
    final c = controller()..beginStroke(tool);
    for (final d in days) {
      c.paintDay(d);
    }
    c.endStroke();
  }

  setUp(() async {
    reporter = RecordingCrashReporter();
    storage = await TestStorage.open(now: _now);
    addTearDown(storage.close);
    container = await makeContainer(storage);
  });

  Future<Map<String, String?>> storedDays() async {
    final rows = await storage.database
        .customSelect('SELECT date, shift_type_ids FROM day_entries')
        .get();
    return {
      for (final r in rows)
        r.read<String>('date'): r.read<String?>('shift_type_ids'),
    };
  }

  group('saving', () {
    test(
      'a stroke writes its rows; undo removes them; redo restores them',
      () async {
        final saturday = _today.addDays(5); // rest by rotation
        final sunday = _today.addDays(6); // rest by rotation
        expect(await storedDays(), isNot(contains('2026-10-24')));

        paint(const PaintTool.replace('guard24'), [saturday, sunday]);
        await controller().pendingWrites;
        var days = await storedDays();
        expect(days['2026-10-24'], '["guard24"]');
        expect(days['2026-10-25'], '["guard24"]');

        controller().undo();
        await controller().pendingWrites;
        days = await storedDays();
        expect(days, isNot(contains('2026-10-24')));
        expect(days, isNot(contains('2026-10-25')));

        controller().redo();
        await controller().pendingWrites;
        days = await storedDays();
        expect(days['2026-10-24'], '["guard24"]');
      },
    );

    test('nothing is written while a stroke is open', () async {
      final probe = ProbeRepository(storage.database, now: () => _now);
      container = await makeContainer(storage, repository: probe);
      controller().beginStroke(const PaintTool.replace('guard24'));
      controller().paintDay(_today.addDays(5));
      controller().paintDay(_today.addDays(6));
      await controller().pendingWrites;
      expect(probe.calls, isEmpty);

      controller().endStroke();
      await controller().pendingWrites;
      expect(probe.calls, hasLength(1));
      expect(probe.calls.single.patch.changes, hasLength(2));
    });

    test('a stroke that changes nothing writes nothing', () async {
      final probe = ProbeRepository(storage.database, now: () => _now);
      container = await makeContainer(storage, repository: probe);
      paint(const PaintTool.replace('night'), [_today]); // already night
      controller().undo(); // nothing to undo
      await controller().pendingWrites;
      expect(probe.calls, isEmpty);
    });

    test('writes go in order, one at a time, even when chained fast', () async {
      final probe = ProbeRepository(
        storage.database,
        now: () => _now,
        // The first write is the slowest: order must still hold.
        delay: (call) => Duration(milliseconds: call == 0 ? 60 : 5),
      );
      container = await makeContainer(storage, repository: probe);

      paint(const PaintTool.replace('guard24'), [_today.addDays(5)]);
      paint(const PaintTool.replace('vacation'), [_today.addDays(5)]);
      controller().undo();
      controller().redo();
      controller().undo();
      await controller().pendingWrites;

      expect(probe.calls, hasLength(5));
      expect(probe.finished, [0, 1, 2, 3, 4]);
      expect(probe.maxActive, 1);
      // Last write was an undo of "vacation": the day is back to guard24.
      expect((await storedDays())['2026-10-24'], '["guard24"]');
      expect(state().schedule.resolve(_today.addDays(5)).shiftIds, ['guard24']);
    });
  });

  group('reopening', () {
    test('the same file gives back an identical schedule', () async {
      final dir = makeTempDir('reopen');
      final file = await openAppDatabase(directory: dir, now: () => _now);
      final first = await TestStorage.open(now: _now, database: file);
      container = await makeContainer(first);

      paint(const PaintTool.replace('guard24'), [
        _today.addDays(5),
        _today.addDays(6),
      ]);
      paint(const PaintTool.add('morning'), [_today, _today.addDays(2)]);
      paint(const PaintTool.erase(), [_today.addDays(8)]);
      controller().undo(); // the eraser stroke is undone
      await controller().pendingWrites;
      final inMemory = state().schedule;
      await first.close();

      final reopened = await TestStorage.open(
        now: _now.add(const Duration(days: 45)),
        database: await openAppDatabase(directory: dir),
      );
      addTearDown(reopened.close);
      expectSameSchedule(reopened.snapshot.schedule, inMemory);
      expect(reopened.snapshot.schedule.resolve(_today.addDays(5)).shiftIds, [
        'guard24',
      ]);
      // And a controller started from it has that schedule too.
      container = await makeContainer(reopened);
      expectSameSchedule(state().schedule, inMemory);
      // History is not persisted.
      expect(state().canUndo, isFalse);
    });
  });

  group('when a write fails', () {
    test('reports, reloads what is stored and tells the UI', () async {
      final probe = ProbeRepository(
        storage.database,
        now: () => _now,
        failCalls: {0},
      );
      container = await makeContainer(storage, repository: probe);
      final stored = state().schedule;
      final day = _today.addDays(5);

      paint(const PaintTool.replace('guard24'), [day]);
      // At once the UI shows the change and offers undo...
      expect(state().schedule.resolve(day).shiftIds, ['guard24']);
      expect(state().canUndo, isTrue);
      expect(state().saveErrors, 0);

      await controller().pendingWrites;
      // ...and once the write fails it shows what is really stored.
      expect(state().saveErrors, 1);
      expect(state().schedule.resolve(day).shiftIds, ['rest']);
      expectSameSchedule(state().schedule, stored);
      expect(state().canUndo, isFalse);
      expect(state().canRedo, isFalse);
      expect(await storedDays(), isNot(contains('2026-10-24')));

      // Reported by type only: the message ("secret note text") never leaves.
      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.single, isA<RedactedError>());
      expect(reporter.errors.single.toString(), 'StateError');
    });

    test(
      'changes queued behind the failed one are dropped, later ones saved',
      () async {
        final probe = ProbeRepository(
          storage.database,
          now: () => _now,
          failCalls: {0},
          delay: (call) => const Duration(milliseconds: 20),
        );
        container = await makeContainer(storage, repository: probe);
        final first = _today.addDays(5);
        final second = _today.addDays(6);
        final before = await storedDays();

        paint(const PaintTool.replace('guard24'), [first]); // will fail
        paint(const PaintTool.replace('vacation'), [
          second,
        ]); // queued behind it
        await controller().pendingWrites;

        // Neither is stored, and the screen agrees.
        expect(probe.calls, hasLength(1));
        expect(await storedDays(), before);
        expect(state().schedule.resolve(first).shiftIds, ['rest']);
        expect(state().schedule.resolve(second).shiftIds, ['rest']);
        expect(state().saveErrors, 1);

        // The app goes on working from the reloaded state.
        paint(const PaintTool.replace('vacation'), [second]);
        await controller().pendingWrites;
        expect((await storedDays())['2026-10-25'], '["vacation"]');
        expect(state().saveErrors, 1);
        expect(state().canUndo, isTrue);
      },
    );

    test('a reporter that throws does not poison the queue: later strokes are '
        'still written and saveErrors still counts', () async {
      final probe = ProbeRepository(
        storage.database,
        now: () => _now,
        failCalls: {0},
      );
      container = await makeContainer(
        storage,
        repository: probe,
        crashReporter: _ThrowingCrashReporter(),
      );
      final first = _today.addDays(5);
      final second = _today.addDays(6);

      paint(const PaintTool.replace('guard24'), [first]); // fails
      await controller().pendingWrites; // must not throw
      expect(state().saveErrors, 1);
      expect(state().schedule.resolve(first).shiftIds, ['rest']);

      paint(const PaintTool.replace('vacation'), [second]);
      await controller().pendingWrites;
      expect((await storedDays())['2026-10-25'], '["vacation"]');
      expect(probe.calls, hasLength(2));
      expect(state().saveErrors, 1);
    });

    test(
      'a failing reload still counts the error and keeps the queue alive',
      () async {
        final repo = _FlakyLoadRepository(storage.database, now: () => _now);
        container = await makeContainer(storage, repository: repo);

        paint(const PaintTool.replace('guard24'), [_today.addDays(5)]); // fails
        await controller().pendingWrites;
        expect(state().saveErrors, 1);

        paint(const PaintTool.replace('vacation'), [_today.addDays(6)]);
        await controller().pendingWrites;
        expect((await storedDays())['2026-10-25'], '["vacation"]');
      },
    );

    test('a failed undo reloads too', () async {
      final probe = ProbeRepository(
        storage.database,
        now: () => _now,
        failCalls: {1},
      );
      container = await makeContainer(storage, repository: probe);
      final day = _today.addDays(5);

      paint(const PaintTool.replace('guard24'), [day]);
      await controller().pendingWrites;
      controller().undo(); // this write fails
      expect(state().schedule.resolve(day).shiftIds, ['rest']);
      await controller().pendingWrites;

      // The undo did not reach the disk: the stored truth is "guard24".
      expect(state().saveErrors, 1);
      expect(state().schedule.resolve(day).shiftIds, ['guard24']);
      expect((await storedDays())['2026-10-24'], '["guard24"]');
    });
  });
}
