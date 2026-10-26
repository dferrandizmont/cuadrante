import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../alarms/application/alarm_providers.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendars/application/calendars_controller.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../onboarding/application/onboarding_providers.dart';
import '../../patterns/application/post_night_provider.dart';
import '../../settings/application/preferences_controller.dart';
import '../../widget/application/widget_providers.dart';
import '../../widget/domain/widget_sync_planner.dart';
import 'backup_service.dart';

/// Restores a backup and brings everything that holds a copy of the data in
/// memory back in step with the database. The screens call [restoreAndReload],
/// never `BackupService.restore` on its own.
///
/// The order is what makes it safe:
/// 1. The restore runs **inside the schedule write queue**, so every change
///    the user already made is written first (and ends up in the safety copy
///    the restore takes), and none can land on top of the restored data.
///    Changes queued while it runs are dropped.
/// 2. The schedule controller reloads from the database (undo history, open
///    stroke and palette included) and goes back to the stored active
///    calendar, which the restore may have replaced.
/// 3. The calendar list, "Saliente automático", holidays, alarm settings,
///    alarms (of the primary calendar) and the widget are refreshed. These
///    steps never keep each other from running.
/// 4. The first-use flow is marked as done (a phone that has just had a
///    schedule restored is not a first launch, whatever the file brought: the
///    flags of the first-use flow are device settings and never travel in a
///    backup) and the tip of the month screen is read again.
///
/// The UI should still block editing while this runs.
class RestoreCoordinator {
  RestoreCoordinator({
    required this.runExclusive,
    required this.restore,
    required this.reloadSchedule,
    required this.reloadHolidays,
    this.reloadCalendars,
    this.reloadPostNight,
    this.resyncAlarms,
    this.resyncWidget,
    this.markOnboardingDone,
    this.reloadOnboardingTip,
  });

  /// Wires the app's providers: [service] does the restore.
  factory RestoreCoordinator.fromRef(Ref ref, BackupService service) {
    final schedule = ref.read(scheduleControllerProvider.notifier);
    return RestoreCoordinator(
      runExclusive: schedule.runExclusive,
      restore: service.restore,
      reloadSchedule: schedule.reload,
      reloadHolidays: ref.read(holidayControllerProvider.notifier).reload,
      reloadCalendars: () async {
        ref.invalidate(calendarsControllerProvider);
        // The appearance preferences travel in the backup too.
        await ref.read(preferencesProvider.notifier).reload();
      },
      // "Saliente automático" travels in the settings too.
      reloadPostNight: ref.read(postNightAutoProvider.notifier).reload,
      resyncAlarms: () {
        // The alarm settings travel in the backup: read them again.
        ref.invalidate(alarmSettingsProvider);
        return ref.read(alarmSyncProvider).resync();
      },
      // The widget follows the schedule listener of `WidgetHost` too; asking
      // here covers a restore that leaves the same schedule object in place.
      resyncWidget: () => ref
          .read(widgetSyncProvider)
          .request(WidgetSyncTrigger.scheduleChanged),
      markOnboardingDone: () =>
          ref.read(onboardingRepositoryProvider).markDone(),
      reloadOnboardingTip: ref.read(onboardingTipProvider.notifier).reload,
    );
  }

  /// Runs an action in order with the schedule writes
  /// (`ScheduleController.runExclusive`).
  final Future<void> Function(Future<void> Function() action) runExclusive;
  final Future<void> Function(PendingRestore pending) restore;
  final Future<void> Function() reloadSchedule;
  final Future<void> Function() reloadHolidays;
  final Future<void> Function()? reloadCalendars;
  final Future<void> Function()? reloadPostNight;
  final Future<void> Function()? resyncAlarms;
  final Future<void> Function()? resyncWidget;
  final Future<void> Function()? markOnboardingDone;
  final Future<void> Function()? reloadOnboardingTip;

  /// Restores [pending]. If the restore fails nothing has changed (it is all
  /// or nothing) and the error is rethrown. If it works but the schedule
  /// cannot be read back, that error is rethrown after the other refreshes
  /// ran.
  Future<void> restoreAndReload(PendingRestore pending) async {
    await runExclusive(() => restore(pending));
    try {
      await reloadSchedule();
    } finally {
      await _bestEffort(reloadCalendars);
      await _bestEffort(reloadPostNight);
      await _bestEffort(reloadHolidays);
      await _bestEffort(resyncAlarms);
      await _bestEffort(resyncWidget);
      await _bestEffort(markOnboardingDone);
      await _bestEffort(reloadOnboardingTip);
    }
  }

  static Future<void> _bestEffort(Future<void> Function()? step) async {
    if (step == null) return;
    try {
      await step();
    } catch (_) {
      // The data is restored; a refresh that fails is retried by the next
      // resume or change.
    }
  }
}
