import 'package:cuadrante/features/alarms/data/local_alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/domain/alarm_payload.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('with the exact-alarm permission a shift alarm is an alarm clock', () {
    expect(
      androidScheduleModeFor(AlarmKind.shift, exact: true),
      AndroidScheduleMode.alarmClock,
    );
  });

  test('the other kinds stay exact, never alarm clocks', () {
    for (final kind in AlarmKind.values.where((k) => k != AlarmKind.shift)) {
      expect(
        androidScheduleModeFor(kind, exact: true),
        AndroidScheduleMode.exactAllowWhileIdle,
        reason: '$kind',
      );
    }
  });

  test('without the permission every kind is inexact', () {
    for (final kind in AlarmKind.values) {
      expect(
        androidScheduleModeFor(kind, exact: false),
        AndroidScheduleMode.inexactAllowWhileIdle,
        reason: '$kind',
      );
    }
  });
}
