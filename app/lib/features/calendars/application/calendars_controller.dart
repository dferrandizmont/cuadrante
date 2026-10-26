import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../alarms/application/alarm_providers.dart';
import '../../calendar/application/schedule_controller.dart';
import '../domain/calendar.dart';
import 'calendars_providers.dart';

/// The calendars the user can pick from and which one the widget and the
/// alarms follow. Which one is on screen is `ScheduleState.calendarId`.
class CalendarsState {
  const CalendarsState({
    required this.calendars,
    required this.primaryId,
    this.archived = const [],
  });

  /// Non-archived calendars in order.
  final List<Calendar> calendars;

  /// The archived ones, in order: the screen offers to recover them.
  final List<Calendar> archived;

  /// `calendars.primary`: followed by the widget and the alarms.
  final String primaryId;
}

/// Creates, renames, recolors and archives calendars and chooses the primary
/// one. Switching the calendar on screen is
/// `ScheduleController.switchCalendar`; this controller only calls it when a
/// calendar is archived while it is on screen.
///
/// Refusals are the typed [CalendarException]s of the repository (last
/// calendar, unknown calendar): they propagate to the caller.
class CalendarsController extends AsyncNotifier<CalendarsState> {
  @override
  Future<CalendarsState> build() => _read();

  Future<CalendarsState> _read() async {
    final repository = ref.read(calendarsRepositoryProvider);
    final all = await repository.list(includeArchived: true);
    return CalendarsState(
      calendars: [
        for (final c in all)
          if (!c.archived) c,
      ],
      archived: [
        for (final c in all)
          if (c.archived) c,
      ],
      primaryId: await repository.primaryId(),
    );
  }

  Future<void> _refresh() async {
    state = AsyncData(await _read());
  }

  /// Adds a calendar.
  Future<Calendar> create({
    required String name,
    required int colorValue,
  }) async {
    final calendar = await ref
        .read(calendarsRepositoryProvider)
        .create(name: name, colorValue: colorValue);
    await _refresh();
    return calendar;
  }

  Future<void> rename(String id, String name) async {
    await ref.read(calendarsRepositoryProvider).rename(id, name);
    await _refresh();
  }

  Future<void> recolor(String id, int colorValue) async {
    await ref.read(calendarsRepositoryProvider).recolor(id, colorValue);
    await _refresh();
  }

  /// Archives a calendar (its data stays stored). Refuses the last one. If it
  /// was on screen the calendar switches to the one that takes its place; if
  /// it was the primary one the alarms are planned again for the new primary.
  Future<void> archive(String id) async {
    final repository = ref.read(calendarsRepositoryProvider);
    final wasPrimary = await repository.primaryId() == id;
    await repository.archive(id);
    final schedule = ref.read(scheduleControllerProvider.notifier);
    if (ref.read(scheduleControllerProvider).calendarId == id) {
      await schedule.switchCalendar(await repository.activeId());
    }
    await _refresh();
    if (wasPrimary) await ref.read(alarmSyncProvider).resync();
  }

  /// Brings the archived calendar [id] back (H-T07-1).
  Future<void> restore(String id) async {
    await ref.read(calendarsRepositoryProvider).unarchive(id);
    await _refresh();
  }

  /// Makes [id] the calendar the widget and the alarms follow.
  Future<void> setPrimary(String id) async {
    await ref.read(calendarsRepositoryProvider).setPrimary(id);
    await _refresh();
    await ref.read(alarmSyncProvider).resync();
  }
}

final calendarsControllerProvider =
    AsyncNotifierProvider<CalendarsController, CalendarsState>(
      CalendarsController.new,
    );
