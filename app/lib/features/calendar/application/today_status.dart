import '../../schedule/domain/schedule_domain.dart';

/// Which of the four moments of the "today" card applies.
enum TodayPhase {
  /// A shift is in progress ("AHORA").
  now,

  /// The next shift of today starts at 20:00 or later ("ESTA NOCHE").
  tonight,

  /// The next shift of today starts before 20:00 ("HOY"), or today has a
  /// shift without hours (vacation...).
  today,

  /// Nothing (more) to work today ("HOY LIBRE"): the card shows the next
  /// shift instead.
  free,

  /// Today had shifts with hours and the last one is over ("HOY TERMINADO"):
  /// the card says which one ended and when, and shows the next shift. It is
  /// not a free day: the day was worked.
  done,

  /// Between the two segments of a split shift (A12): the first one is over
  /// and the second one has not started («Vuelves a las 17:00»).
  gap,
}

/// Start time from which a shift counts as "tonight".
const int kTonightFromMinute = 20 * 60;

/// How far ahead the next shift is looked for when today is free.
const int kNextShiftLookAheadDays = 60;

/// A shift placed in time, for the card.
class ScheduledShift {
  const ScheduledShift({
    required this.shift,
    required this.date,
    required this.start,
    required this.end,
    this.segment = 0,
  });

  final ShiftType shift;

  /// Day the shift starts (both segments of a split shift belong to it).
  final CivilDate date;
  final DateTime start;
  final DateTime end;

  /// 0, or 1 for the second segment of a split shift.
  final int segment;

  bool get isSecondSegment => segment == 1;
}

/// What the "today" card shows at one instant. Pure: the same schedule and
/// instant always give the same status; "now" comes from the app clock.
class TodayStatus {
  const TodayStatus({
    required this.phase,
    required this.tomorrow,
    this.main,
    this.timed,
    this.minutes,
    this.others = const [],
    this.restShift,
    this.finished,
  });

  final TodayPhase phase;

  /// The featured shift: the one in progress, the next one to start today, or
  /// the shift without hours of today. `null` when [phase] is
  /// [TodayPhase.free].
  final ShiftType? main;

  /// [main] placed in time (the in-progress or next occurrence), or, when
  /// [phase] is [TodayPhase.free], the next shift of the schedule. `null`
  /// for a shift without hours or when there is no next shift.
  final ScheduledShift? timed;

  /// Minutes to the end of the shift in progress ([TodayPhase.now]) or to the
  /// start of [timed] (otherwise); `null` when there is nothing to count.
  final int? minutes;

  /// Other shifts still to come today, after [main] ("+ Tarde 14:00-22:00").
  final List<ShiftType> others;

  /// Free day: its rest shift ("Libre"), if the schedule has one.
  final ShiftType? restShift;

  /// [TodayPhase.done]: the last shift of today to end (the one that ended
  /// latest; for a split shift, its second segment). [main] is its shift and
  /// [timed] the next shift of the schedule.
  final ScheduledShift? finished;

  /// Shifts of tomorrow, in order.
  final List<ShiftType> tomorrow;
}

/// Status of the "today" card at [now] (only minute precision is used).
TodayStatus todayStatus(Schedule schedule, DateTime now) {
  // Keep the instant (and UTC offset) when the local hour occurs twice.
  final minute = now.subtract(
    Duration(
      seconds: now.second,
      milliseconds: now.millisecond,
      microseconds: now.microsecond,
    ),
  );
  final today = CivilDate.fromDateTime(minute);
  final tomorrow = schedule.resolve(today.addDays(1)).shifts;

  // Yesterday's overnight shift can still be running; the look-ahead finds
  // the next one when today is free.
  final occurrences = [
    for (final o in schedule.occurrences(
      today.addDays(-1),
      today.addDays(kNextShiftLookAheadDays),
    ))
      _place(o),
  ]..sort((a, b) => a.start.compareTo(b.start));

  ScheduledShift? current;
  for (final o in occurrences) {
    if (!o.start.isAfter(minute) && o.end.isAfter(minute)) current = o;
  }
  final laterToday = [
    for (final o in occurrences)
      if (o.date == today && o.start.isAfter(minute)) o,
  ];

  if (current != null) {
    return TodayStatus(
      phase: TodayPhase.now,
      main: current.shift,
      timed: current,
      minutes: current.end.difference(minute).inMinutes,
      others: _others(laterToday, current),
      tomorrow: tomorrow,
    );
  }

  // Between the two segments of a split shift: the first one is over (it is
  // not in progress and not ahead) and the next thing to start is the second.
  final upcoming = occurrences.where((o) => o.start.isAfter(minute));
  final resume = upcoming.firstOrNull;
  if (resume != null && resume.isSecondSegment) {
    return TodayStatus(
      phase: TodayPhase.gap,
      main: resume.shift,
      timed: resume,
      minutes: resume.start.difference(minute).inMinutes,
      others: _others(laterToday.where((o) => o != resume), resume),
      tomorrow: tomorrow,
    );
  }

  if (laterToday.isNotEmpty) {
    final next = laterToday.first;
    final startMinute = next.start.hour * 60 + next.start.minute;
    return TodayStatus(
      phase: startMinute >= kTonightFromMinute
          ? TodayPhase.tonight
          : TodayPhase.today,
      main: next.shift,
      timed: next,
      minutes: next.start.difference(minute).inMinutes,
      others: _others(laterToday.skip(1), next),
      tomorrow: tomorrow,
    );
  }

  final todayShifts = schedule.resolve(today).shifts;
  final withoutHours = [
    for (final s in todayShifts)
      if (!s.hasTimes && s.category != ShiftCategory.rest) s,
  ];
  if (withoutHours.isNotEmpty) {
    return TodayStatus(
      phase: TodayPhase.today,
      main: withoutHours.first,
      others: withoutHours.skip(1).toList(),
      tomorrow: tomorrow,
    );
  }

  final next = resume;

  // Shifts that start today and are already over (a night shift that began
  // yesterday belongs to yesterday): the day was worked, it is not free.
  final over = _lastEndedToday(occurrences, today, minute);
  if (over != null) {
    return TodayStatus(
      phase: TodayPhase.done,
      main: over.shift,
      finished: over,
      timed: next,
      minutes: next?.start.difference(minute).inMinutes,
      tomorrow: tomorrow,
    );
  }

  return TodayStatus(
    phase: TodayPhase.free,
    timed: next,
    minutes: next?.start.difference(minute).inMinutes,
    restShift: todayShifts
        .where((s) => s.category == ShiftCategory.rest)
        .firstOrNull,
    tomorrow: tomorrow,
  );
}

/// The shift of [today] that ended last, if any of them has ended by [minute].
ScheduledShift? _lastEndedToday(
  List<ScheduledShift> occurrences,
  CivilDate today,
  DateTime minute,
) {
  ScheduledShift? last;
  for (final o in occurrences) {
    if (o.date != today || o.end.isAfter(minute)) continue;
    if (o.shift.category == ShiftCategory.rest) continue;
    if (last == null || o.end.isAfter(last.end)) last = o;
  }
  return last;
}

/// The shifts of [later] to list as "also today" after [main]: the second
/// segment of a split shift is not a shift of its own, so it is left out when
/// the card already shows that shift ([main] or an earlier entry of [later]).
List<ShiftType> _others(Iterable<ScheduledShift> later, ScheduledShift main) {
  bool sameShift(ScheduledShift a, ScheduledShift b) =>
      a.date == b.date && a.shift.id == b.shift.id;
  final list = later.toList();
  return [
    for (final o in list)
      if (!(o.isSecondSegment &&
          (sameShift(o, main) ||
              list.any((x) => !x.isSecondSegment && sameShift(x, o)))))
        o.shift,
  ];
}

/// Wall-clock start and end of [o] (daylight saving included).
ScheduledShift _place(ShiftOccurrence o) {
  DateTime at(int minuteOfDate) =>
      DateTime(o.date.year, o.date.month, o.date.day, 0, minuteOfDate);
  return ScheduledShift(
    shift: o.shiftType,
    date: o.date,
    start: at(o.startMinuteAbs),
    end: at(o.endMinuteAbs),
    segment: o.segment,
  );
}
