import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/paint_controller.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/schedule/data/demo_schedule.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';

const today = CivilDate(2026, 10, 19);

String ids(Schedule s, CivilDate d) => s.resolve(d).shiftIds.join('+');

void main() {
  late ProviderContainer container;

  setUp(() async {
    final storage = await TestStorage.open(now: DateTime(2026, 10, 19));
    container = ProviderContainer(
      overrides: [
        ...storage.overrides,
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 19)),
      ],
    );
    addTearDown(() async {
      // Let queued writes finish before the database goes away.
      await container.read(scheduleControllerProvider.notifier).pendingWrites;
      container.dispose();
      await storage.close();
    });
  });

  ScheduleController controller() =>
      container.read(scheduleControllerProvider.notifier);
  ScheduleState state() => container.read(scheduleControllerProvider);
  Schedule schedule() => state().schedule;

  group('demo schedule', () {
    test('correturnos from the Monday three months back, open ended', () {
      final s = buildDemoSchedule(today);
      final run = s.runs.single;
      expect(run.patternId, 'correturnos');
      expect(run.startDate, const CivilDate(2026, 7, 13));
      expect(run.startDate.weekday, DateTime.monday);
      expect(run.endDate, isNull);
      expect(s.patterns.map((p) => p.id), contains('24x72'));
      expect(s.shiftTypes, hasLength(shiftTemplates.length));
    });

    test('rotation and overrides around today', () {
      final s = buildDemoSchedule(today);
      expect(ids(s, today), 'night');
      expect(ids(s, today.addDays(5)), 'rest');
      expect(ids(s, today.addDays(2)), 'morning+afternoon');
      expect(s.resolve(today.addDays(3)).isEmpty, isTrue);
      expect(ids(s, today.addDays(8)), 'vacation');
      expect(ids(s, today.addDays(9)), 'vacation');
      final noted = s.resolve(today.addDays(1));
      expect(noted.note, isNotNull);
      expect(noted.source, DaySource.pattern);
    });

    test('is a function of today', () {
      final a = buildDemoSchedule(const CivilDate(2027, 1, 31));
      // 31 Jan - 3 months = Sat 31 Oct, so the Monday before is 26 Oct.
      expect(a.runs.single.startDate, const CivilDate(2026, 10, 26));
    });
  });

  group('strokes', () {
    final d1 = today.addDays(5); // Saturday, rest
    final d2 = today.addDays(6); // Sunday, rest
    final d3 = today.addDays(7); // Monday, morning

    test('starts without history', () {
      expect(state().canUndo, isFalse);
      expect(state().canRedo, isFalse);
    });

    test('a stroke paints several days live, then one step', () {
      final c = controller();
      c.beginStroke(const PaintTool.replace('afternoon'));
      expect(c.paintDay(d1), isTrue);
      expect(c.paintDay(d2), isTrue);
      expect(c.paintDay(d3), isTrue);
      // Live: painted but not yet in the history.
      expect(
        [d1, d2, d3].map((d) => ids(schedule(), d)),
        everyElement('afternoon'),
      );
      expect(state().canUndo, isFalse);

      c.endStroke();
      expect(state().canUndo, isTrue);
      expect(
        [d1, d2, d3].map((d) => ids(schedule(), d)),
        everyElement('afternoon'),
      );
    });

    test('one undo reverts the whole stroke, redo reapplies it', () {
      final before = [d1, d2, d3].map((d) => ids(schedule(), d)).toList();
      final c = controller();
      c.beginStroke(const PaintTool.replace('night'));
      c.paintDay(d1);
      c.paintDay(d2);
      c.paintDay(d3);
      c.endStroke();

      c.undo();
      expect([d1, d2, d3].map((d) => ids(schedule(), d)), before);
      expect(state().canUndo, isFalse);
      expect(state().canRedo, isTrue);

      c.redo();
      expect(
        [d1, d2, d3].map((d) => ids(schedule(), d)),
        everyElement('night'),
      );
      expect(state().canUndo, isTrue);
      expect(state().canRedo, isFalse);
    });

    test('painting the same day twice in a stroke counts once', () {
      final c = controller();
      c.beginStroke(const PaintTool.replace('night'));
      expect(c.paintDay(d1), isTrue);
      expect(c.paintDay(d1), isFalse);
      c.endStroke();
      c.undo();
      expect(state().canUndo, isFalse);
    });

    test('a tap is a stroke of one day', () {
      final c = controller();
      c.beginStroke(const PaintTool.replace('guard24'));
      c.paintDay(d1);
      c.endStroke();
      expect(ids(schedule(), d1), 'guard24');
      c.undo();
      expect(ids(schedule(), d1), 'rest');
    });

    test('a new stroke after undo drops the redo history', () {
      final c = controller();
      c.beginStroke(const PaintTool.replace('night'));
      c.paintDay(d1);
      c.endStroke();
      c.undo();
      expect(state().canRedo, isTrue);

      c.beginStroke(const PaintTool.replace('morning'));
      c.paintDay(d2);
      c.endStroke();
      expect(state().canRedo, isFalse);
    });

    test('add ("Doblar") keeps the existing shifts', () {
      final c = controller();
      c.beginStroke(const PaintTool.add('morning'));
      c.paintDay(today); // night by rotation
      c.paintDay(today.addDays(2)); // already morning+afternoon
      c.endStroke();
      expect(ids(schedule(), today), 'night+morning');
      expect(ids(schedule(), today.addDays(2)), 'morning+afternoon');
      c.undo();
      expect(ids(schedule(), today), 'night');
    });

    test('replace overwrites the shifts of the day', () {
      final c = controller();
      c.beginStroke(const PaintTool.replace('vacation'));
      c.paintDay(today.addDays(2));
      c.endStroke();
      expect(ids(schedule(), today.addDays(2)), 'vacation');
    });

    test('eraser empties days, undo brings them back', () {
      final c = controller();
      c.beginStroke(const PaintTool.erase());
      c.paintDay(today);
      c.paintDay(d3);
      c.endStroke();
      expect(schedule().resolve(today).isEmpty, isTrue);
      expect(schedule().resolve(d3).isEmpty, isTrue);
      c.undo();
      expect(ids(schedule(), today), 'night');
      expect(ids(schedule(), d3), 'morning');
    });

    test('painting what the rotation already gives leaves no step', () {
      final c = controller();
      c.beginStroke(const PaintTool.replace('night'));
      c.paintDay(today);
      c.endStroke();
      expect(state().canUndo, isFalse);
    });

    test('paintDay without a stroke does nothing', () {
      expect(controller().paintDay(d1), isFalse);
      expect(ids(schedule(), d1), 'rest');
    });

    test('beginStroke closes an unfinished stroke', () {
      final c = controller();
      c.beginStroke(const PaintTool.replace('night'));
      c.paintDay(d1);
      c.beginStroke(const PaintTool.replace('morning'));
      c.paintDay(d2);
      c.endStroke();
      c.undo();
      expect(ids(schedule(), d2), 'rest');
      expect(ids(schedule(), d1), 'night');
      c.undo();
      expect(ids(schedule(), d1), 'rest');
    });
  });

  group('paint mode', () {
    PaintState paint() => container.read(paintControllerProvider);
    PaintController p() => container.read(paintControllerProvider.notifier);

    test('defaults to the first work shift, replace, off', () {
      expect(paint().active, isFalse);
      expect(paint().shiftTypeId, 'morning');
      expect(paint().doubling, isFalse);
      expect(paint().tool, const PaintTool.replace('morning'));
    });

    test('"Doblar" switches replace and add', () {
      p().selectShift('night');
      expect(paint().tool, const PaintTool.replace('night'));
      p().toggleDoubling();
      expect(paint().tool, const PaintTool.add('night'));
      p().toggleDoubling();
      expect(paint().tool, const PaintTool.replace('night'));
    });

    test('the eraser overrides doubling', () {
      p().toggleDoubling();
      p().selectEraser();
      expect(paint().erasing, isTrue);
      expect(paint().tool, const PaintTool.erase());
      p().selectShift('morning');
      expect(paint().tool, const PaintTool.add('morning'));
    });

    test('toggle enters and leaves; leaving closes the open stroke', () {
      p().toggle();
      expect(paint().active, isTrue);
      final c = controller();
      c.beginStroke(paint().tool);
      c.paintDay(today.addDays(5));
      p().toggle();
      expect(paint().active, isFalse);
      expect(c.strokeActive, isFalse);
      expect(state().canUndo, isTrue);
    });
  });
}
