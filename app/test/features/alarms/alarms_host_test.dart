import 'package:cuadrante/features/alarms/application/alarm_providers.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/data/alarm_system.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';

import '../calendar/harness.dart';

void main() {
  testWidgets('a time-zone or time change with the app alive replans the '
      'alarms at once (H-T11-4)', (tester) async {
    final scheduler = FakeAlarmScheduler();
    final system = FakeAlarmSystem();
    await pumpCalendar(
      tester,
      overrides: [
        alarmSchedulerProvider.overrideWithValue(scheduler),
        alarmSystemProvider.overrideWithValue(system),
      ],
    );
    expect(scheduler.replaceCalls, 1);

    // The device zone changed under the foreground app: no resume, no
    // schedule edit, only the platform notice.
    system.emit(ClockChange.timezone);
    await tester.pump();
    await tester.pump();
    expect(scheduler.replaceCalls, 2, reason: 'zone change replanned');

    system.emit(ClockChange.time);
    await tester.pump();
    await tester.pump();
    expect(scheduler.replaceCalls, 3, reason: 'time change replanned');
  });

  testWidgets('a resume replans too (cold path of a zone change while in the '
      'background)', (tester) async {
    final scheduler = FakeAlarmScheduler();
    await pumpCalendar(
      tester,
      overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
    );
    expect(scheduler.replaceCalls, 1);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    await tester.pump();
    expect(scheduler.replaceCalls, 2);
  });

  testWidgets('syncs at start and after schedule changes (debounced)', (
    tester,
  ) async {
    final scheduler = FakeAlarmScheduler();
    await pumpCalendar(
      tester,
      overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
    );
    // The first run happens at start with the Spanish texts from the ARB.
    expect(scheduler.replaceCalls, 1);
    expect(scheduler.strings?.channelName, 'Alarmas de turno');
    // Alarms are off by default: nothing is scheduled.
    expect(scheduler.scheduled, isEmpty);

    // Turn on the demo's morning shift and add one far from the demo days.
    final container = containerOf(tester);
    await tester.runAsync(
      () => container
          .read(alarmSettingsRepositoryProvider)
          .save(
            const AlarmSettings(
              enabled: true,
              byShiftType: {'morning': AlarmTypeSettings(enabled: true)},
            ),
          ),
    );

    final day = fixedToday.addDays(11);
    final notifier = container.read(scheduleControllerProvider.notifier);
    notifier.beginStroke(const PaintTool.replace('morning'));
    notifier.paintDay(day);
    notifier.endStroke();
    await tester.pump(const Duration(milliseconds: 500));
    expect(scheduler.replaceCalls, 1, reason: 'still inside the debounce');
    await tester.pump(const Duration(seconds: 2));
    expect(scheduler.replaceCalls, 2);
    expect(scheduler.scheduled.map((a) => a.shiftDate), contains(day));
    expect(scheduler.scheduled.every((a) => a.shiftTypeId == 'morning'), true);

    await tester.runAsync(() => notifier.pendingWrites);
  });
}
