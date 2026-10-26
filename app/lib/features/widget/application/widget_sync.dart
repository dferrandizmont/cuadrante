import '../../schedule/domain/civil_date.dart';
import '../data/widget_publisher.dart';
import '../domain/widget_snapshot.dart';
import '../domain/widget_sync_planner.dart';

/// Runs one sync step for [trigger]: builds the current snapshot with
/// [build], compares it with what [publisher] holds, and republishes and/or
/// reloads the timelines as [WidgetSyncPlanner.plan] says. Returns the plan.
///
/// Debouncing ([WidgetSyncTrigger.debounce]) and the lifecycle wiring belong
/// to the caller; this function does the work once the trigger has fired.
Future<WidgetSyncPlan> syncWidget({
  required WidgetPublisher publisher,
  required WidgetSyncTrigger trigger,
  required WidgetSnapshot Function() build,
}) async {
  final fresh = build();
  final published = WidgetSnapshotHeader.tryParse(
    await publisher.readPublished(),
  );
  final plan = WidgetSyncPlanner.plan(
    trigger: trigger,
    published: published,
    today: CivilDate.parse(fresh.firstDate),
    timeZone: fresh.timeZone,
    contentHash: fresh.contentHash,
  );
  if (plan.republish) {
    await publisher.publish(fresh.encode());
  } else if (plan.reloadTimelines) {
    await publisher.reloadTimelines();
  }
  return plan;
}
