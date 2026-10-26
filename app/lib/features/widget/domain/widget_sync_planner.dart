import '../../schedule/domain/civil_date.dart';
import 'widget_snapshot.dart';

/// What can make the app republish the widget snapshot. Each one is raised by
/// the app (lifecycle observer, schedule/holiday providers, a timer at local
/// midnight while the app is open, time-zone change notifications).
enum WidgetSyncTrigger {
  /// Cold start, once the schedule is loaded.
  appStart,

  /// The app returns to the foreground.
  appResumed,

  /// Any edit of shifts, rotations, overrides or notes.
  scheduleChanged,

  /// The holiday set changed (region or municipality, new yearly package).
  holidaysChanged,

  /// The civil date rolled over while the app was alive.
  dayChanged,

  /// The device time zone changed.
  timeZoneChanged,

  /// The app language changed (the snapshot's texts are localized).
  localeChanged;

  /// Quiet period to wait before acting. Editing triggers come in bursts
  /// (painting a month fires one change per cell), so they wait for the burst
  /// to end; the rest act at once.
  Duration get debounce => switch (this) {
    scheduleChanged || holidaysChanged => WidgetSyncPlanner.editDebounce,
    _ => Duration.zero,
  };

  /// Whether the timelines are reloaded even if the snapshot is unchanged:
  /// opening the app is the cheap moment to give WidgetKit a fresh timeline.
  bool get alwaysReloadsTimelines => switch (this) {
    appStart || appResumed || dayChanged || timeZoneChanged => true,
    _ => false,
  };
}

/// Why a republish is needed.
enum WidgetRefreshReason {
  /// Nothing published yet, or what is stored cannot be read.
  neverPublished,

  /// The first day of the published timeline is not today (the date rolled,
  /// or the clock went back).
  dateRolled,

  /// Published for another time zone.
  timeZoneChanged,

  /// Published with another snapshot version.
  versionChanged,

  /// Schedule, holidays or texts differ from what is published.
  contentChanged,
}

/// Outcome of comparing the published snapshot with the current state.
class WidgetRefreshDecision {
  const WidgetRefreshDecision(this.reasons);

  final Set<WidgetRefreshReason> reasons;

  bool get needsRefresh => reasons.isNotEmpty;
}

/// What to do after a trigger.
class WidgetSyncPlan {
  const WidgetSyncPlan({
    required this.republish,
    required this.reloadTimelines,
    required this.reasons,
  });

  /// Build and write a new snapshot.
  final bool republish;

  /// Ask the OS to reload the widgets' timelines (always true after a
  /// republish).
  final bool reloadTimelines;
  final Set<WidgetRefreshReason> reasons;
}

/// Pure decisions about when the widget snapshot must be republished.
///
/// Rules (see `docs/widget-contrato.md`): the published timeline starts
/// today, in the current zone, with the current version and the current
/// content; if any of those is false, republish.
abstract final class WidgetSyncPlanner {
  /// Wait after the last edit before republishing.
  static const Duration editDebounce = Duration(seconds: 2);

  /// Compares what is [published] (null: nothing) with the current [today],
  /// [timeZone] and [contentHash] (`WidgetSnapshot.contentHash` of a snapshot
  /// freshly built for them). A null [contentHash] skips the content check.
  static WidgetRefreshDecision evaluate({
    required WidgetSnapshotHeader? published,
    required CivilDate today,
    required String timeZone,
    String? contentHash,
    int version = kWidgetSnapshotVersion,
  }) {
    if (published == null) {
      return const WidgetRefreshDecision({WidgetRefreshReason.neverPublished});
    }
    return WidgetRefreshDecision({
      if (published.version != version) WidgetRefreshReason.versionChanged,
      if (published.firstDate != today.toIso()) WidgetRefreshReason.dateRolled,
      if (published.timeZone != timeZone) WidgetRefreshReason.timeZoneChanged,
      if (contentHash != null && published.contentHash != contentHash)
        WidgetRefreshReason.contentChanged,
    });
  }

  /// True when the published snapshot is out of date (see [evaluate]).
  static bool needsRefresh({
    required WidgetSnapshotHeader? published,
    required CivilDate today,
    required String timeZone,
    String? contentHash,
    int version = kWidgetSnapshotVersion,
  }) => evaluate(
    published: published,
    today: today,
    timeZone: timeZone,
    contentHash: contentHash,
    version: version,
  ).needsRefresh;

  /// [evaluate] plus the trigger: a republish when needed, and a timeline
  /// reload when republishing or when the trigger asks for it.
  static WidgetSyncPlan plan({
    required WidgetSyncTrigger trigger,
    required WidgetSnapshotHeader? published,
    required CivilDate today,
    required String timeZone,
    String? contentHash,
    int version = kWidgetSnapshotVersion,
  }) {
    final decision = evaluate(
      published: published,
      today: today,
      timeZone: timeZone,
      contentHash: contentHash,
      version: version,
    );
    return WidgetSyncPlan(
      republish: decision.needsRefresh,
      reloadTimelines: decision.needsRefresh || trigger.alwaysReloadsTimelines,
      reasons: decision.reasons,
    );
  }

  /// Time left until the next local midnight, for the in-app timer that
  /// raises [WidgetSyncTrigger.dayChanged]. [nowLocal] is the device's local
  /// time; the next midnight is built from its calendar fields, so a
  /// 23 h or 25 h day is handled by the platform.
  static Duration untilNextDay(DateTime nowLocal) {
    final next = DateTime(nowLocal.year, nowLocal.month, nowLocal.day + 1);
    return next.difference(nowLocal);
  }

  /// True when the published timeline has no entry for [today] any more (the
  /// widget is showing its "open the app" message).
  static bool isStale(WidgetSnapshotHeader? published, CivilDate today) {
    if (published == null) return true;
    final CivilDate first;
    final CivilDate last;
    try {
      first = CivilDate.parse(published.firstDate);
      last = CivilDate.parse(published.lastDate);
    } on FormatException {
      return true; // a damaged snapshot shows nothing useful
    }
    return today.isBefore(first) || today.isAfter(last);
  }
}
