import '../../calendars/domain/calendar.dart';
import '../domain/schedule_domain.dart';

/// What the app loads from the database for one calendar: the whole
/// [Schedule] (archived shift types included, so past days still resolve)
/// plus the [palette], the shift types the paint bar offers.
class ScheduleSnapshot {
  const ScheduleSnapshot({
    required this.schedule,
    required this.palette,
    this.calendarId = mainCalendarId,
  });

  /// A snapshot where every shift type of [schedule] is paintable (tests,
  /// previews).
  ScheduleSnapshot.fromSchedule(
    Schedule schedule, {
    String calendarId = mainCalendarId,
  }) : this(
         schedule: schedule,
         palette: schedule.shiftTypes,
         calendarId: calendarId,
       );

  final Schedule schedule;

  /// Non-archived shift types in `sort_order`.
  final List<ShiftType> palette;

  /// The calendar [schedule] belongs to: its runs and days.
  final String calendarId;
}
