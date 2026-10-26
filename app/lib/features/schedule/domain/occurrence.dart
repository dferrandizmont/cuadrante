import 'civil_date.dart';
import 'schedule.dart';
import 'shift_type.dart';

const _minutesPerDay = 1440;

/// A shift (or one segment of a split shift) placed on the calendar. Hours
/// are imputed to [date], the day it **starts** (usual payroll convention);
/// both segments of a split shift (A12) belong to the day the **first** one
/// starts, even when the second one begins after midnight.
class ShiftOccurrence {
  const ShiftOccurrence({
    required this.date,
    required this.shiftType,
    required this.startMinuteAbs,
    required this.endMinuteAbs,
    this.segment = 0,
  });

  /// The occurrence of [shiftType] on [date]: its first (or only) segment.
  /// [shiftType] must have a schedule. Use [ShiftOccurrence.allOf] to get
  /// the second segment of a split shift too.
  factory ShiftOccurrence.of(CivilDate date, ShiftType shiftType) {
    if (!shiftType.hasTimes) {
      throw ArgumentError.value(shiftType, 'shiftType', 'has no schedule');
    }
    final start = shiftType.startMinute!;
    return ShiftOccurrence(
      date: date,
      shiftType: shiftType,
      startMinuteAbs: start,
      endMinuteAbs: start + shiftType.durationMinutes,
    );
  }

  /// All the segments of [shiftType] on [date], in time order: one for a
  /// normal shift, two for a split one. [shiftType] must have a schedule.
  static List<ShiftOccurrence> allOf(CivilDate date, ShiftType shiftType) {
    final first = ShiftOccurrence.of(date, shiftType);
    if (!shiftType.hasSegment2) return [first];
    // The second segment starts the next time its clock minute comes after
    // the first one ends (checkSegment2): end of the first + the gap.
    final start = first.endMinuteAbs + shiftType.segment2GapMinutes;
    return [
      first,
      ShiftOccurrence(
        date: date,
        shiftType: shiftType,
        startMinuteAbs: start,
        endMinuteAbs: start + shiftType.segment2DurationMinutes!,
        segment: 1,
      ),
    ];
  }

  final CivilDate date;
  final ShiftType shiftType;

  /// Minutes since 00:00 of [date]; the end can exceed 1440 when crossing
  /// midnight.
  final int startMinuteAbs;
  final int endMinuteAbs;

  /// 0 for the shift (or the first segment of a split shift), 1 for the
  /// second segment of a split shift.
  final int segment;

  bool get isSecondSegment => segment == 1;

  int get durationMinutes => endMinuteAbs - startMinuteAbs;

  /// Paid minutes of this segment. For a shift that is not split, those of
  /// the shift ([ShiftType.effectivePaidMinutes]); for a split one, its share
  /// of them: each segment is paid in full, and an unpaid break (the shift's
  /// paid minutes below the sum of both segments) comes off the first one.
  /// Both shares add up to the paid minutes of the shift.
  int get paidMinutes {
    final total = shiftType.effectivePaidMinutes;
    if (!shiftType.hasSegment2) return total;
    final second = shiftType.segment2DurationMinutes!;
    final secondPaid = total < second ? total : second;
    return isSecondSegment ? secondPaid : total - secondPaid;
  }

  /// Minutes per calendar day, in order (22:00-06:00 -> 120 + 360).
  Map<CivilDate, int> splitByCivilDay() {
    final result = <CivilDate, int>{};
    for (var k = startMinuteAbs ~/ _minutesPerDay; ; k++) {
      final from = k * _minutesPerDay;
      if (from >= endMinuteAbs) break;
      final lo = startMinuteAbs > from ? startMinuteAbs : from;
      final hi = endMinuteAbs < from + _minutesPerDay
          ? endMinuteAbs
          : from + _minutesPerDay;
      result[date.addDays(k)] = hi - lo;
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is ShiftOccurrence &&
      other.date == date &&
      other.shiftType == shiftType &&
      other.startMinuteAbs == startMinuteAbs &&
      other.endMinuteAbs == endMinuteAbs &&
      other.segment == segment;

  @override
  int get hashCode =>
      Object.hash(date, shiftType, startMinuteAbs, endMinuteAbs, segment);

  @override
  String toString() =>
      'ShiftOccurrence($date ${shiftType.code} $startMinuteAbs-$endMinuteAbs'
      '${segment == 0 ? '' : ' #2'})';
}

/// Night window, 22:00-06:00 by default (ET art. 36). Like shifts, an end that
/// is not after the start wraps past midnight.
class NightWindow {
  const NightWindow({this.startMinute = 22 * 60, this.endMinute = 6 * 60});

  final int startMinute;
  final int endMinute;

  /// Night minutes of [o], including the window that began the night before.
  /// `nightOverride == true` makes the whole shift night, `false` none.
  int nightMinutes(ShiftOccurrence o) {
    switch (o.shiftType.nightOverride) {
      case true:
        return o.durationMinutes;
      case false:
        return 0;
      case null:
        break;
    }
    final len = (endMinute - startMinute) % _minutesPerDay;
    final windowLen = len == 0 ? _minutesPerDay : len;
    var total = 0;
    for (var k = -1; k <= o.endMinuteAbs ~/ _minutesPerDay; k++) {
      final lo = k * _minutesPerDay + startMinute;
      final hi = lo + windowLen;
      final from = o.startMinuteAbs > lo ? o.startMinuteAbs : lo;
      final to = o.endMinuteAbs < hi ? o.endMinuteAbs : hi;
      if (to > from) total += to - from;
    }
    return total;
  }

  @override
  bool operator ==(Object other) =>
      other is NightWindow &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute;

  @override
  int get hashCode => Object.hash(startMinute, endMinute);
}

class HoursSummary {
  const HoursSummary({
    required this.workedMinutes,
    required this.nightMinutes,
    required this.dayMinutes,
  });

  /// Totals over the `work` occurrences: worked minutes (`paidMinutes` when
  /// defined), the part of their duration inside the night window and the
  /// remainder ([workedMinutes] - [nightMinutes], never negative).
  factory HoursSummary.of(
    Iterable<ShiftOccurrence> occurrences, [
    NightWindow window = const NightWindow(),
  ]) {
    var worked = 0;
    var night = 0;
    for (final o in occurrences) {
      if (o.shiftType.category != ShiftCategory.work) continue;
      worked += o.paidMinutes;
      night += window.nightMinutes(o);
    }
    return HoursSummary(
      workedMinutes: worked,
      nightMinutes: night,
      dayMinutes: worked > night ? worked - night : 0,
    );
  }

  final int workedMinutes;
  final int nightMinutes;
  final int dayMinutes;

  @override
  bool operator ==(Object other) =>
      other is HoursSummary &&
      other.workedMinutes == workedMinutes &&
      other.nightMinutes == nightMinutes &&
      other.dayMinutes == dayMinutes;

  @override
  int get hashCode => Object.hash(workedMinutes, nightMinutes, dayMinutes);

  @override
  String toString() =>
      'HoursSummary(worked: $workedMinutes, night: $nightMinutes, day: $dayMinutes)';
}

extension ScheduleOccurrences on Schedule {
  /// Occurrences that **start** in `[from, to]` (a night shift of `to` ends the
  /// day after, a shift of `from - 1` is not included). A split shift gives
  /// two (both belong to its start day, so the second one of `to` is
  /// included even if it begins on the next day), one after the other.
  List<ShiftOccurrence> occurrences(CivilDate from, CivilDate to) => [
    for (final day in resolveRange(from, to))
      for (final s in day.shifts)
        if (s.hasTimes) ...ShiftOccurrence.allOf(day.date, s),
  ];
}
