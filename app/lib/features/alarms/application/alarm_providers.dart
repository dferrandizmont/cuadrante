import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/diagnostics/crash_reporting.dart';
import '../../../core/providers.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendars/application/primary_schedule.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../data/alarm_scheduler.dart';
import '../data/alarm_settings_repository.dart';
import '../data/alarm_sounds.dart';
import '../data/alarm_system.dart';
import '../data/local_alarm_scheduler.dart';
import '../domain/alarm_planner.dart';
import '../domain/alarm_settings.dart';
import '../domain/alarm_strings.dart';
import '../domain/wall_clock.dart';
import 'alarm_sync.dart';

/// The plugin on a phone; an in-memory fake on the host (tests, desktop).
/// Tests override it with their own [FakeAlarmScheduler].
final alarmSchedulerProvider = Provider<AlarmScheduler>(
  (ref) => Platform.isAndroid || Platform.isIOS
      ? LocalAlarmScheduler(
          sounds: ref.watch(alarmSoundsProvider),
          system: ref.watch(alarmSystemProvider),
        )
      : FakeAlarmScheduler(),
);

/// The Android system screens and clock notices the alarms use. Tests
/// override it with a `FakeAlarmSystem`.
final alarmSystemProvider = Provider<AlarmSystem>(
  (ref) => Platform.isAndroid ? PlatformAlarmSystem() : const NoAlarmSystem(),
);

/// The phone's alarm sounds: the Android picker; nothing to choose
/// elsewhere. Tests override it with a [FakeAlarmSounds].
final alarmSoundsProvider = Provider<AlarmSounds>(
  (ref) =>
      Platform.isAndroid ? const PlatformAlarmSounds() : const NoAlarmSounds(),
);

final alarmSettingsRepositoryProvider = Provider<AlarmSettingsRepository>(
  (ref) => AlarmSettingsRepository(ref.watch(appDatabaseProvider)),
);

/// Delay of the "Probar aviso" notification.
const Duration alarmTestDelay = Duration(seconds: 10);

/// Id of the test notification: there is only ever one.
final int alarmTestId = fnv31('test');

/// The stored alarm settings. [save] persists them; the host reschedules
/// when they change.
class AlarmSettingsController extends AsyncNotifier<AlarmSettings> {
  // Edits are read-modify-write: one at a time, or two quick taps would both
  // start from the same stored value and the second would undo the first.
  final AsyncMutex _edits = AsyncMutex();

  @override
  Future<AlarmSettings> build() async =>
      (await ref.watch(alarmSettingsRepositoryProvider).load()).pruneSkipped(
        _today(),
      );

  CivilDate _today() => CivilDate.fromDateTime(ref.read(clockProvider)());

  Future<void> save(AlarmSettings settings) async {
    await ref.read(alarmSettingsRepositoryProvider).save(settings);
    state = AsyncData(settings);
  }

  /// Applies [change] to the latest settings and saves the result. Old
  /// skipped days are pruned on the way.
  Future<void> edit(AlarmSettings Function(AlarmSettings current) change) =>
      _edits.run(() async {
        final current = state.value ?? await future;
        final next = change(current).pruneSkipped(_today());
        if (next != current) await save(next);
      });

  /// The global switch.
  Future<void> setEnabled(bool enabled) =>
      edit((s) => s.copyWith(enabled: enabled));

  /// Replaces the choices of one shift type.
  Future<void> setShiftType(String shiftTypeId, AlarmTypeSettings settings) =>
      edit((s) => s.withShiftType(shiftTypeId, settings));

  /// "Sin alarma este día": no alarm rings for the shifts of [date].
  Future<void> setSkipped(CivilDate date, {required bool skipped}) =>
      edit((s) => s.withSkipped(date, skipped: skipped));

  /// Asks the OS for notification permission. The settings screen calls it
  /// the first time the user turns an alarm on, never at launch.
  Future<AlarmPermission> requestPermission() =>
      ref.read(alarmSchedulerProvider).requestPermission();

  /// Makes sure the app may post notifications, asking the OS when it does
  /// not yet (the reminder of a note needs it even when the alarms are off).
  /// Never prompts if the permission is already there. The caller asks it
  /// when the user does something that needs it, never at launch.
  Future<AlarmPermission> ensureNotificationPermission() async {
    final scheduler = ref.read(alarmSchedulerProvider);
    var permission = await scheduler.permissionStatus();
    if (permission != AlarmPermission.granted) {
      permission = await scheduler.requestPermission();
    }
    ref.invalidate(alarmPermissionsProvider);
    return permission;
  }

  /// Fires a test notification in [alarmTestDelay]. Asks for the permission
  /// first when it is missing. Returns false when it cannot ring (denied).
  Future<bool> scheduleTest(AlarmStrings strings) async {
    final scheduler = ref.read(alarmSchedulerProvider);
    await scheduler.configure(strings);
    await scheduler.initialize();
    var permission = await scheduler.permissionStatus();
    if (permission != AlarmPermission.granted) {
      permission = await scheduler.requestPermission();
    }
    if (permission != AlarmPermission.granted) return false;
    await scheduler.scheduleOneOff(
      OneOffAlarm(
        id: alarmTestId,
        fireAt: ref.read(clockProvider)().add(alarmTestDelay),
        kind: OneOffKind.test,
        title: strings.testTitle,
        body: strings.testBody,
        payload: '${alarmTestPayloadPrefix}test',
      ),
    );
    return true;
  }
}

final alarmSettingsProvider =
    AsyncNotifierProvider<AlarmSettingsController, AlarmSettings>(
      AlarmSettingsController.new,
    );

/// What the OS lets the alarms do right now.
class AlarmPermissions {
  const AlarmPermissions({
    required this.notifications,
    required this.exact,
    this.notificationsBlocked = false,
  });

  /// Notification permission (Android 13+ runtime permission, iOS prompt).
  final AlarmPermission notifications;

  /// The notifications are off and the system will not ask again (denied
  /// for good, or switched off in the settings): «Permitir» would do
  /// nothing, only the system settings can turn them on (H-T11-1).
  final bool notificationsBlocked;

  /// Android "Alarmas y recordatorios": alarms at the exact minute. Always
  /// true on iOS and before Android 12.
  final bool exact;

  bool get notificationsGranted => notifications == AlarmPermission.granted;
}

/// The permission state shown by the settings screen. Never prompts; the
/// screen invalidates it when the app comes back from the system settings.
final alarmPermissionsProvider = FutureProvider.autoDispose<AlarmPermissions>((
  ref,
) async {
  final scheduler = ref.watch(alarmSchedulerProvider);
  await scheduler.initialize();
  final notifications = await scheduler.permissionStatus();
  return AlarmPermissions(
    notifications: notifications,
    exact: await scheduler.canScheduleExactAlarms(),
    notificationsBlocked: notifications == AlarmPermission.denied
        ? await ref.read(alarmSystemProvider).notificationsBlocked()
        : false,
  );
});

/// The alarm that will ring next, from the **primary** calendar and the
/// current settings, computed by the same planner the scheduler uses. Null
/// when nothing is going to ring.
final nextAlarmProvider = FutureProvider.autoDispose<PlannedAlarm?>((
  ref,
) async {
  final settings = await ref.watch(alarmSettingsProvider.future);
  // Painting shifts changes the plan: recompute.
  ref.watch(scheduleControllerProvider.select((s) => s.schedule));
  // And look at the clock again every minute: the exact timer below counts
  // monotonic time, so when the wall clock jumps (a time zone, a manual
  // change, the QA's `adb`) a timer armed hours ago never notices that the
  // alarm time has passed (H-T11-7 reserve).
  ref.watch(minuteClockProvider);
  final schedule = await readPrimarySchedule(ref);
  final now = ref.read(clockProvider)();
  final location = await ref.read(alarmSchedulerProvider).planningZone();
  final next = nextAlarm(
    schedule: schedule,
    settings: settings,
    now: now,
    location: location,
  );
  // H-T11-7: the value used to stay on screen after that alarm had rung.
  // Recompute a second after it is due (the screen also invalidates this on
  // resume, for the minutes the process was frozen).
  if (next != null) {
    final due = resolveAlarmInstant(next, location);
    var wait = due.difference(now) + const Duration(seconds: 1);
    // Timers far in the future add nothing: look again at least daily.
    if (wait > const Duration(days: 1)) wait = const Duration(days: 1);
    if (wait < const Duration(seconds: 1)) wait = const Duration(seconds: 1);
    final timer = Timer(wait, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return next;
});

/// The coalescing rescheduler. Reads the schedule and the settings fresh on
/// every run, so it never plans from a stale copy.
final alarmSyncProvider = Provider<AlarmSync>((ref) {
  final sync = AlarmSync(
    scheduler: ref.watch(alarmSchedulerProvider),
    loadSettings: () => ref.read(alarmSettingsRepositoryProvider).load(),
    readSchedule: () => readPrimarySchedule(ref),
    now: ref.watch(clockProvider),
    onError: (error, stack) {
      if (!ref.mounted) return;
      final reporter = ref.read(crashReporterProvider);
      unawaited(
        reporter
            .record(redactError(error), stack, fatal: false)
            .catchError((Object _) {}),
      );
    },
  );
  ref.onDispose(sync.dispose);
  return sync;
});
