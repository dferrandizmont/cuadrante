import '../domain/alarm_planner.dart';
import 'alarm_scheduler.dart';

/// Id of the "Posponer 10 min" button of the notification.
const String snoozeActionId = 'cuadrante.snooze';

/// Id of the "Ya estoy despierto" button.
const String awakeActionId = 'cuadrante.awake';

/// How long "Posponer" pushes an alarm back.
const Duration alarmSnoozeDelay = Duration(minutes: 10);

/// What a notification action did.
enum AlarmActionResult {
  /// Rings again after [alarmSnoozeDelay].
  snoozed,

  /// "Ya estoy despierto": the notification is already gone, nothing else.
  dismissed,

  /// Not one of ours, not a button, or unreadable.
  ignored,
}

/// Id of the snoozed copy of an alarm. Derived from the shift (not from the
/// notification id), so snoozing the snooze again replaces it instead of
/// piling up copies.
int snoozeIdFor(AlarmPayload payload) => fnv31(
  'snooze|${payload.shiftDate.toIso()}|${payload.shiftTypeId}|'
  '${payload.kind.name}'
  // The second segment of a split shift has its own snooze; the first keeps
  // the id it always had.
  '${payload.segment == 0 ? '' : '|s${payload.segment + 1}'}',
);

/// Acts on a tap on a button of an alarm notification.
///
/// - [snoozeActionId]: schedules a one-off copy of the alarm [snooze] after
///   [now]. The copy rings with the same texts and buttons, taken from the
///   payload (this runs in a background isolate on Android, where there is no
///   database and no localizations), and does not start with
///   `alarmPayloadPrefix`, so a resync does not drop it.
/// - [awakeActionId]: nothing to do; the plugin cancels the notification
///   itself (`cancelNotification`).
/// - Anything else, or a payload that is not ours: ignored.
///
/// Only alarms before a shift can be snoozed (the day-before reminder has no
/// buttons).
Future<AlarmActionResult> handleAlarmAction({
  required AlarmScheduler scheduler,
  required String? actionId,
  required String? payload,
  required DateTime now,
  Duration snooze = alarmSnoozeDelay,
}) async {
  final data = AlarmPayload.decode(payload);
  if (data == null) return AlarmActionResult.ignored;
  switch (actionId) {
    case awakeActionId:
      return AlarmActionResult.dismissed;
    case snoozeActionId:
      if (data.kind != AlarmKind.shift) return AlarmActionResult.ignored;
      await scheduler.scheduleOneOff(
        OneOffAlarm(
          id: snoozeIdFor(data),
          fireAt: now.add(snooze),
          kind: OneOffKind.snooze,
          title: data.title,
          body: data.body,
          payload: data.encodeAsSnooze(),
          snoozeLabel: data.snoozeLabel,
          awakeLabel: data.awakeLabel,
          sound: data.sound,
        ),
      );
      return AlarmActionResult.snoozed;
  }
  return AlarmActionResult.ignored;
}
