import '../../schedule/domain/schedule_domain.dart';

/// Free monthly summary (docs/roadmap.md, "Ingresos estimados"): shifts per
/// type, hours, night hours, estimated pay, rest days, absences and holiday
/// hours of ONE calendar month. Pure Dart on top of [Schedule]; the screens
/// only format what is computed here.
///
/// The definitions (also in the footnotes of the screen):
///
/// * **Day.** The calendar day a shift STARTS on. A night shift of the 31st
///   belongs to the month of the 31st in full, even if its last hours fall in
///   the next month; the one of the previous month's last day is not here.
/// * **Occurrence ("turno").** Each shift of a day counts once: a day with
///   Mañana + Tarde is two shifts and one worked day. Shifts without a
///   schedule count as shifts but add no hours.
/// * **Hours.** Paid minutes ([ShiftType.effectivePaidMinutes]: the duration
///   unless an unpaid break is set; both segments of a split shift, without
///   the gap) of the `work` shifts with a schedule. A
///   24 h guard is 24 h. Civil clock hours: a daylight-saving night is not
///   corrected to 7 or 9 h.
/// * **Night hours.** The part of each work shift inside the night window
///   (22:00-06:00 unless told otherwise, [ShiftType.nightOverride] wins),
///   never more than the paid minutes of that shift.
/// * **Pay.** Paid hours x the hourly rate of the shift type, per type
///   rounded to the cent. A work type without rate adds no hourly amount and
///   is listed in [MonthSummary.unpricedTypes]. Fixed pluses add once per work shift,
///   including shifts without hours or an hourly rate. A split shift adds
///   one plus; rest and absence types add none.
/// * **Holiday hours.** Minutes of work shifts that fall on a holiday date
///   (the shift split by calendar day, [ShiftOccurrence.splitByCivilDay]), so
///   a night shift that crosses into a holiday counts the part after
///   midnight; prorated by paid/total minutes. They are a subset of the
///   hours of the shift's start month.
/// * **Rest days / absences.** A day is "worked" when it has a work shift;
///   [absenceDays] counts days with any absence type; [restDays] counts days
///   with a rest shift and neither a work shift nor an absence.
/// * **Overtime and early leave** (docs/paridad.md, A6). The minutes the user
///   noted on a day ([ResolvedDay.overtimeMinutes], [ResolvedDay.earlyLeaveMinutes])
///   belong to the DAY, whatever its shifts are, and go into the month of that
///   day. Per day, with `paid` = paid minutes of its work shifts with a
///   schedule: overtime always adds, even on a day with no shift, a rest day
///   or an absence (the user said they worked); early leave subtracts at most
///   `paid + overtime` (the day never goes below 0 h) and that applied amount
///   is what [earlyLeaveMinutes] reports, so `shiftMinutes + overtime -
///   earlyLeave == workedMinutes` always holds. [workedMinutes] is therefore
///   the TOTAL; it does not change the days, shifts or night hours (the extras
///   are not placed on the clock, so they count as day hours).
/// * **Pay of the extras.** Both are valued at the hourly rate of the FIRST
///   work shift of that day, in the order of the day, that has a schedule
///   and a rate; the extras of a day with no such shift are not valued (the
///   euros stay as they are) and are counted in [extrasWithoutRateMinutes] so
///   the screen can say so. The deduction of a day never exceeds what its
///   priced shifts and overtime pay. Unrounded per day (cent-minutes), rounded
///   once per month: [overtimeCents] and [earlyLeaveCents]; the total is the
///   types' hourly pay + [overtimeCents] - [earlyLeaveCents], never below 0,
///   plus the fixed pluses (early leave never reduces a fixed plus).

/// What one shift type adds up to in a month.
class ShiftTypeMonth {
  const ShiftTypeMonth({
    required this.type,
    required this.days,
    required this.count,
    this.paidMinutes = 0,
    this.nightMinutes = 0,
    this.earningsCents,
  });

  final ShiftType type;

  /// Different days of the month the type appears on.
  final int days;

  /// Times it appears (a day with it twice counts twice).
  final int count;

  /// Paid minutes (work types with a schedule only).
  final int paidMinutes;
  final int nightMinutes;

  /// Estimated pay in cents; `null` without a rate or without hours.
  final int? earningsCents;

  bool get isWork => type.category == ShiftCategory.work;

  /// A work type that has hours but no hourly rate.
  bool get missingRate =>
      isWork && paidMinutes > 0 && type.hourlyRateCents == null;
}

/// The summary of one month.
class MonthSummary {
  const MonthSummary({
    required this.month,
    required this.types,
    required this.shiftsWorked,
    required this.workedDays,
    required this.workedMinutes,
    required this.nightMinutes,
    required this.restDays,
    required this.absenceDays,
    required this.holidayShifts,
    required this.holidayMinutes,
    required this.earningsCents,
    required this.shiftsWithoutTimes,
    this.overtimeMinutes = 0,
    this.earlyLeaveMinutes = 0,
    this.overtimeCents = 0,
    this.earlyLeaveCents = 0,
    this.extrasWithoutRateMinutes = 0,
    this.fixedPlusCount = 0,
    this.fixedPlusCents = 0,
  });

  /// First day of the month.
  final CivilDate month;

  /// The types that appear in the month, in the order of the schedule's
  /// types.
  final List<ShiftTypeMonth> types;

  /// Work shifts (a double day counts two).
  final int shiftsWorked;

  /// Days with at least one work shift.
  final int workedDays;

  /// Total minutes worked: the shifts' paid minutes + [overtimeMinutes] -
  /// [earlyLeaveMinutes].
  final int workedMinutes;
  final int nightMinutes;

  /// Extra minutes noted on the days of the month (A6).
  final int overtimeMinutes;

  /// Minutes of early leave applied (never more than the day had), A6.
  final int earlyLeaveMinutes;

  /// Pay of [overtimeMinutes] / [earlyLeaveMinutes] in cents, included in
  /// [earningsCents] (the second one subtracted).
  final int overtimeCents;
  final int earlyLeaveCents;

  /// Extra and early-leave minutes of days with no priced work shift: not
  /// in the euros.
  final int extrasWithoutRateMinutes;

  /// Work shifts with a configured fixed plus (including an explicit zero).
  final int fixedPlusCount;

  /// Fixed pluses of the work shifts, included in [earningsCents].
  /// Neither unpaid breaks nor early leave reduce them.
  final int fixedPlusCents;

  /// Days with a rest shift and nothing worked or absent.
  final int restDays;

  /// Days with at least one absence type.
  final int absenceDays;

  /// Work shifts with some minutes on a holiday date.
  final int holidayShifts;
  final int holidayMinutes;

  /// Total estimated pay in cents; `null` without an hourly amount or a
  /// configured fixed plus on any work shift in the period.
  final int? earningsCents;

  /// Work shifts without a schedule (they add no hours).
  final int shiftsWithoutTimes;

  /// Minutes the shifts alone add up to, without the extras.
  int get shiftMinutes => workedMinutes - overtimeMinutes + earlyLeaveMinutes;

  /// The month has overtime or early leave to show.
  bool get hasExtras => overtimeMinutes > 0 || earlyLeaveMinutes > 0;

  int get dayMinutes =>
      workedMinutes > nightMinutes ? workedMinutes - nightMinutes : 0;

  /// No shift of any kind this month and no overtime either.
  bool get isEmpty => types.isEmpty && overtimeMinutes == 0;

  List<ShiftTypeMonth> get workTypes => [
    for (final t in types)
      if (t.isWork) t,
  ];

  List<ShiftTypeMonth> get restTypes => [
    for (final t in types)
      if (t.type.category == ShiftCategory.rest) t,
  ];

  List<ShiftTypeMonth> get absenceTypes => [
    for (final t in types)
      if (t.type.category == ShiftCategory.absence) t,
  ];

  /// Work types with hours but no rate: their pay is not in the total.
  List<ShiftType> get unpricedTypes => [
    for (final t in types)
      if (t.missingRate) t.type,
  ];

  /// Whether the total pay has something to show.
  bool get hasEarnings => earningsCents != null;
}

/// Mutable tally of one type while walking the days.
class _Tally {
  _Tally(this.type);

  final ShiftType type;
  int days = 0;
  int count = 0;
  int paidMinutes = 0;
  int nightMinutes = 0;
}

/// Summarizes the days `[first, last]` (both included) for [schedule], with
/// the same definitions as a month: it is the one aggregate behind the month
/// summary ([summarizeMonth]) and the free date range of the summary screen,
/// so `summarizeRange(first of month, last of month)` equals the month.
/// [MonthSummary.month] is [first]. Shifts count on the day they START: a
/// night shift of [last] belongs to the range in full.
///
/// [holidays] are the holiday dates of the user's place (the neighbouring
/// months' too: the day after the last one may be a holiday a night shift
/// runs into). [window] is the night window.
MonthSummary summarizeRange(
  Schedule schedule,
  CivilDate first,
  CivilDate last, {
  Set<CivilDate> holidays = const {},
  NightWindow window = const NightWindow(),
}) {
  final days = schedule.resolveRange(first, last);

  final tallies = <String, _Tally>{};
  var shiftsWorked = 0;
  var shiftsWithoutTimes = 0;
  var workedDays = 0;
  var restDays = 0;
  var absenceDays = 0;
  var workedMinutes = 0;
  var nightMinutes = 0;
  var holidayShifts = 0;
  var holidayMinutes = 0;
  var overtimeMinutes = 0;
  var earlyLeaveMinutes = 0;
  var overtimeCentMinutes = 0;
  var earlyLeaveCentMinutes = 0;
  var extrasWithoutRate = 0;
  var fixedPlusCount = 0;
  var fixedPlusCents = 0;

  for (final day in days) {
    var dayPaid = 0;
    var dayPricedCentMinutes = 0;
    int? dayRate;
    final seen = <String>{};
    var hasWork = false;
    var hasRest = false;
    var hasAbsence = false;
    for (final shift in day.shifts) {
      final tally = tallies.putIfAbsent(shift.id, () => _Tally(shift));
      tally.count++;
      if (seen.add(shift.id)) tally.days++;
      switch (shift.category) {
        case ShiftCategory.rest:
          hasRest = true;
        case ShiftCategory.absence:
          hasAbsence = true;
        case ShiftCategory.work:
          hasWork = true;
          shiftsWorked++;
          if (shift.fixedPlusCents case final plus?) {
            fixedPlusCount++;
            fixedPlusCents += plus;
          }
          if (!shift.hasTimes) {
            // No hours: nothing to add to the holiday hours, so it is not
            // counted as a holiday shift either («0 h · 1 turno»).
            shiftsWithoutTimes++;
            break;
          }
          // A split shift (A12) has two segments; the gap between them is
          // not worked. The night hours and the holiday split are computed
          // per segment and added up per shift.
          final occurrences = ShiftOccurrence.allOf(day.date, shift);
          final paid = shift.effectivePaidMinutes;
          var segmentsNight = 0;
          var total = 0;
          for (final occurrence in occurrences) {
            segmentsNight += window.nightMinutes(occurrence);
            total += occurrence.durationMinutes;
          }
          final night = _min(segmentsNight, paid);
          tally.paidMinutes += paid;
          tally.nightMinutes += night;
          workedMinutes += paid;
          nightMinutes += night;
          dayPaid += paid;
          final rate = shift.hourlyRateCents;
          if (rate != null) {
            dayRate ??= rate;
            dayPricedCentMinutes += paid * rate;
          }

          var onHoliday = 0;
          for (final occurrence in occurrences) {
            for (final part in occurrence.splitByCivilDay().entries) {
              if (holidays.contains(part.key)) onHoliday += part.value;
            }
          }
          if (onHoliday > 0) {
            holidayShifts++;
            // Prorated when an unpaid break makes paid < total.
            holidayMinutes += (onHoliday * paid + total ~/ 2) ~/ total;
          }
      }
    }
    if (hasWork) workedDays++;
    if (hasAbsence) absenceDays++;
    if (hasRest && !hasWork && !hasAbsence) restDays++;

    // Overtime and early leave of the day (A6).
    final overtime = day.overtimeMinutes;
    final early = _min(day.earlyLeaveMinutes, dayPaid + overtime);
    if (overtime > 0 || early > 0) {
      overtimeMinutes += overtime;
      earlyLeaveMinutes += early;
      workedMinutes += overtime - early;
      if (dayRate == null) {
        extrasWithoutRate += overtime + early;
      } else {
        final overtimePay = overtime * dayRate;
        overtimeCentMinutes += overtimePay;
        earlyLeaveCentMinutes += _min(
          early * dayRate,
          dayPricedCentMinutes + overtimePay,
        );
      }
    }
  }

  final types = <ShiftTypeMonth>[
    for (final type in schedule.shiftTypes)
      if (tallies[type.id] case final t?)
        ShiftTypeMonth(
          type: type,
          days: t.days,
          count: t.count,
          paidMinutes: t.paidMinutes,
          nightMinutes: t.nightMinutes,
          earningsCents: _earnings(type, t.paidMinutes),
        ),
  ];
  int? earnings;
  for (final t in types) {
    if (t.earningsCents != null) earnings = (earnings ?? 0) + t.earningsCents!;
  }
  final overtimeCents = (overtimeCentMinutes + 30) ~/ 60;
  final earlyLeaveCents = (earlyLeaveCentMinutes + 30) ~/ 60;
  if (overtimeCents != 0 || earlyLeaveCents != 0) {
    earnings = _max(0, (earnings ?? 0) + overtimeCents - earlyLeaveCents);
  }
  if (fixedPlusCount > 0) earnings = (earnings ?? 0) + fixedPlusCents;

  return MonthSummary(
    month: first,
    types: types,
    shiftsWorked: shiftsWorked,
    workedDays: workedDays,
    workedMinutes: workedMinutes,
    nightMinutes: nightMinutes,
    restDays: restDays,
    absenceDays: absenceDays,
    holidayShifts: holidayShifts,
    holidayMinutes: holidayMinutes,
    earningsCents: earnings,
    shiftsWithoutTimes: shiftsWithoutTimes,
    overtimeMinutes: overtimeMinutes,
    earlyLeaveMinutes: earlyLeaveMinutes,
    overtimeCents: overtimeCents,
    earlyLeaveCents: earlyLeaveCents,
    extrasWithoutRateMinutes: extrasWithoutRate,
    fixedPlusCount: fixedPlusCount,
    fixedPlusCents: fixedPlusCents,
  );
}

/// Summarizes the month that contains [anyDay] for [schedule]
/// ([summarizeRange] over its first to its last day).
MonthSummary summarizeMonth(
  Schedule schedule,
  CivilDate anyDay, {
  Set<CivilDate> holidays = const {},
  NightWindow window = const NightWindow(),
}) {
  final first = anyDay.firstDayOfMonth;
  return summarizeRange(
    schedule,
    first,
    first.lastDayOfMonth,
    holidays: holidays,
    window: window,
  );
}

int _min(int a, int b) => a < b ? a : b;
int _max(int a, int b) => a > b ? a : b;

/// Paid minutes x rate per hour, in whole cents (half a cent rounds up).
int? _earnings(ShiftType type, int paidMinutes) {
  final rate = type.hourlyRateCents;
  if (type.category != ShiftCategory.work || rate == null || paidMinutes <= 0) {
    return null;
  }
  return (paidMinutes * rate + 30) ~/ 60;
}

/// The twelve months of a year and their sums.
class YearTotals {
  const YearTotals({required this.year, required this.months});

  final int year;

  /// January to December.
  final List<MonthSummary> months;

  int get shiftsWorked => _sum((m) => m.shiftsWorked);
  int get workedMinutes => _sum((m) => m.workedMinutes);
  int get nightMinutes => _sum((m) => m.nightMinutes);
  int get restDays => _sum((m) => m.restDays);
  int get absenceDays => _sum((m) => m.absenceDays);
  int get holidayMinutes => _sum((m) => m.holidayMinutes);
  int get overtimeMinutes => _sum((m) => m.overtimeMinutes);
  int get earlyLeaveMinutes => _sum((m) => m.earlyLeaveMinutes);
  bool get hasExtras => overtimeMinutes > 0 || earlyLeaveMinutes > 0;

  /// `null` when no month has pay to show.
  int? get earningsCents {
    int? total;
    for (final m in months) {
      if (m.earningsCents != null) total = (total ?? 0) + m.earningsCents!;
    }
    return total;
  }

  bool get isEmpty => months.every((m) => m.isEmpty);

  int _sum(int Function(MonthSummary m) pick) =>
      months.fold(0, (sum, m) => sum + pick(m));
}

/// The twelve [summarizeMonth]s of [year].
YearTotals summarizeYearTotals(
  Schedule schedule,
  int year, {
  Set<CivilDate> holidays = const {},
  NightWindow window = const NightWindow(),
}) => YearTotals(
  year: year,
  months: [
    for (var m = 1; m <= 12; m++)
      summarizeMonth(
        schedule,
        CivilDate(year, m, 1),
        holidays: holidays,
        window: window,
      ),
  ],
);
