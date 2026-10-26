import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/application/schedule_controller.dart';
import '../../schedule/application/schedule_providers.dart';
import '../../schedule/domain/schedule_domain.dart';

/// The schedule of calendar [calendarId], read-only, for comparing
/// (`docs/paridad.md` A4). The calendar on screen is read from the editor
/// (its in-memory schedule is the freshest); any other is read from the
/// database after the writes already queued have finished. It never switches
/// the calendar on screen and never writes.
final compareScheduleProvider = FutureProvider.autoDispose
    .family<Schedule, String>((ref, calendarId) async {
      final current = ref.watch(scheduleControllerProvider);
      if (current.calendarId == calendarId) return current.schedule;
      await ref.read(scheduleControllerProvider.notifier).pendingWrites;
      final stored = await ref
          .read(scheduleRepositoryProvider)
          .load(calendarId);
      return stored.schedule;
    });
