import 'dart:async';

import 'package:timezone/timezone.dart' as tz;

import '../domain/alarm_planner.dart';
import '../domain/alarm_strings.dart';
import '../domain/wall_clock.dart';

/// A tiny async mutex: [run] calls execute one at a time, in order.
class AsyncMutex {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}

enum AlarmPermission { granted, denied }

/// Why a one-off notification exists.
enum OneOffKind {
  /// An alarm pushed back by the "Posponer" button.
  snooze,

  /// The "Probar aviso" button of the settings.
  test,
}

/// A single notification outside the plan: a snoozed alarm or the test one.
/// A resync leaves these alone (their payload does not start with
/// `alarmPayloadPrefix`).
class OneOffAlarm {
  const OneOffAlarm({
    required this.id,
    required this.fireAt,
    required this.kind,
    required this.title,
    required this.body,
    required this.payload,
    this.snoozeLabel,
    this.awakeLabel,
    this.sound,
  });

  final int id;

  /// An absolute instant (it does not depend on the time zone).
  final DateTime fireAt;
  final OneOffKind kind;
  final String title;
  final String body;
  final String payload;

  /// Labels of the notification buttons; null = no buttons.
  final String? snoozeLabel;
  final String? awakeLabel;

  /// Custom sound (content URI) of the alarm this one repeats; null = the
  /// default channel.
  final String? sound;
}

/// Device side of the alarms. The pure plan comes from `planAlarms`; this
/// schedules it. The plugin implementation is `LocalAlarmScheduler`; tests and
/// hosts without a notification service use [FakeAlarmScheduler].
abstract interface class AlarmScheduler {
  /// Idempotent. Sets up the time zone and the plugin.
  Future<void> initialize();

  /// Effective device zone, read before resolving/filtering the plan.
  Future<tz.Location> planningZone();

  /// Creates (or renames) the Android channel. Cheap; called on every sync.
  Future<void> configure(AlarmStrings strings);

  /// Current OS notification permission. Never prompts.
  Future<AlarmPermission> permissionStatus();

  /// Asks the OS (Android 13+ runtime permission / iOS prompt). Call it when
  /// the user turns an alarm on, never at launch.
  Future<AlarmPermission> requestPermission();

  /// Whether alarms can ring at the exact minute. Always true on iOS and on
  /// Android before 12; on 12+ it needs the "Alarms and reminders" access.
  Future<bool> canScheduleExactAlarms();

  /// Opens the Android "Alarms and reminders" screen. No-op elsewhere.
  Future<void> requestExactAlarmPermission();

  /// Makes the pending alarms exactly [alarms]: schedules each one (the same
  /// id replaces) and cancels the stale alarms of ours. Notifications that
  /// are not ours are never touched. Calls are serialised.
  Future<void> replaceAll(List<PlannedAlarm> alarms);

  /// Schedules one notification outside the plan (a snooze, the test). The
  /// same id replaces. Needs no [initialize]: the snooze action runs this in
  /// a background isolate where only the plugin is available.
  Future<void> scheduleOneOff(OneOffAlarm alarm);

  /// Cancels every pending snoozed alarm (the alarms were turned off).
  Future<void> cancelSnoozes();
}

/// In-memory scheduler for tests and for hosts without notifications.
class FakeAlarmScheduler implements AlarmScheduler {
  FakeAlarmScheduler({
    this.permission = AlarmPermission.granted,
    this.permissionAfterRequest,
    this.exactAllowed = true,
  });

  AlarmPermission permission;

  /// What [requestPermission] results in (default: granted).
  AlarmPermission? permissionAfterRequest;
  bool exactAllowed;

  List<PlannedAlarm> scheduled = const [];
  final List<List<PlannedAlarm>> history = [];
  int replaceCalls = 0;
  int requestCalls = 0;
  int exactRequestCalls = 0;
  bool initialized = false;
  AlarmStrings? strings;

  /// Holds [replaceAll] until completed: lets a test keep a run "in flight"
  /// while it triggers more requests.
  Completer<void>? gate;

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<tz.Location> planningZone() async => defaultAlarmLocation();

  @override
  Future<void> configure(AlarmStrings strings) async => this.strings = strings;

  @override
  Future<AlarmPermission> permissionStatus() async => permission;

  @override
  Future<AlarmPermission> requestPermission() async {
    requestCalls++;
    permission = permissionAfterRequest ?? AlarmPermission.granted;
    return permission;
  }

  @override
  Future<bool> canScheduleExactAlarms() async => exactAllowed;

  @override
  Future<void> requestExactAlarmPermission() async => exactRequestCalls++;

  @override
  Future<void> replaceAll(List<PlannedAlarm> alarms) async {
    replaceCalls++;
    final pending = gate;
    if (pending != null) await pending.future;
    scheduled = List.unmodifiable(alarms);
    history.add(scheduled);
  }

  /// Pending one-off notifications (snoozes and tests), by id.
  final List<OneOffAlarm> oneOffs = [];
  int cancelSnoozeCalls = 0;

  @override
  Future<void> scheduleOneOff(OneOffAlarm alarm) async {
    oneOffs
      ..removeWhere((o) => o.id == alarm.id)
      ..add(alarm);
  }

  @override
  Future<void> cancelSnoozes() async {
    cancelSnoozeCalls++;
    oneOffs.removeWhere((o) => o.kind == OneOffKind.snooze);
  }
}
