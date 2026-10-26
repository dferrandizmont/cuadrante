import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/application/schedule_controller.dart';
import '../../schedule/application/schedule_providers.dart';
import '../../schedule/domain/schedule_domain.dart';
import 'calendars_providers.dart';

/// The schedule of the **primary** calendar (`calendars.primary`): the one
/// the widget and the alarms follow, whichever calendar is on screen.
///
/// When the primary calendar is the one being edited, the in-memory schedule
/// is returned (it is the freshest); otherwise it is read from the database,
/// after the writes already queued have finished.
///
/// Anything that plans from the schedule outside the calendar screen (alarms
/// today, the widget when its sync gets wired) reads it through here.
Future<Schedule> readPrimarySchedule(Ref ref) async {
  final primaryId = await ref.read(calendarsRepositoryProvider).primaryId();
  final current = ref.read(scheduleControllerProvider);
  if (current.calendarId == primaryId) return current.schedule;
  await ref.read(scheduleControllerProvider.notifier).pendingWrites;
  final stored = await ref.read(scheduleRepositoryProvider).load(primaryId);
  return stored.schedule;
}
