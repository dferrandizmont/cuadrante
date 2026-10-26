import 'shift_icon.dart';

const _minutesPerDay = 1440;

/// Longest id of an alarm sound (it is an opaque platform identifier, such as
/// a ringtone URI); anything longer is not an id.
const int maxAlarmSoundLength = 512;

/// The most overtime or early leave a single day can hold: 24 h. The editor
/// cuts to it, the backup refuses more and the database mapper clamps to it,
/// so a sum of days can never overflow into absurd hours or euros.
const int maxDayExtraMinutes = 1440;

/// Largest hourly rate the editor accepts, in cents (9 999,99 EUR/h); the
/// backup refuses more.
const int maxHourlyRateCents = 999999;

/// Largest fixed payment per worked shift (9 999,99 EUR), in cents.
const int maxFixedPlusCents = 999999;

/// Whether [uri] is a sound of the system itself: the media store (ringtones,
/// the ones the user added included) or the settings provider (the default
/// entries). Anything else (the app's own FileProvider, another app's
/// provider) is not a sound to restore from a file; the Android side
/// (`AlarmSoundPolicy.isAcceptable`) applies the same allow-list.
bool isSystemAlarmSound(String uri) =>
    uri.startsWith('content://media/') || uri.startsWith('content://settings/');

/// What is wrong with the second segment of a split shift (turno partido).
enum Segment2Problem {
  /// Only one of start and duration is set.
  incomplete,

  /// The shift has no times, so there is nothing for the second segment to
  /// follow.
  noTimes,

  /// The start is not a minute of the day (0-1439).
  startOutOfRange,

  /// The duration is not between 1 minute and 24 h.
  durationOutOfRange,

  /// The second segment does not start strictly after the first one ends.
  notAfterFirst,

  /// First segment, gap and second segment do not fit in 24 h.
  tooLong,
}

/// Checks the second segment of a split shift against the first one.
///
/// The second segment starts at the clock minute [segment2StartMinute],
/// which is read as the **next time that minute comes after the first
/// segment ends** (possibly past midnight). It is valid when it does not
/// start at the very minute the first one ends (that would be one segment)
/// and first segment + gap + second segment fit in 24 h. `null` = valid
/// (also when there is no second segment).
Segment2Problem? checkSegment2({
  required int? startMinute,
  required int? endMinute,
  required int? segment2StartMinute,
  required int? segment2DurationMinutes,
}) {
  if (segment2StartMinute == null && segment2DurationMinutes == null) {
    return null;
  }
  if (segment2StartMinute == null || segment2DurationMinutes == null) {
    return Segment2Problem.incomplete;
  }
  if (startMinute == null || endMinute == null) return Segment2Problem.noTimes;
  if (segment2StartMinute < 0 || segment2StartMinute >= _minutesPerDay) {
    return Segment2Problem.startOutOfRange;
  }
  if (segment2DurationMinutes < 1 || segment2DurationMinutes > _minutesPerDay) {
    return Segment2Problem.durationOutOfRange;
  }
  final first = _durationBetween(startMinute, endMinute);
  final gap = (segment2StartMinute - endMinute) % _minutesPerDay;
  if (gap == 0) return Segment2Problem.notAfterFirst;
  if (first + gap + segment2DurationMinutes > _minutesPerDay) {
    return Segment2Problem.tooLong;
  }
  return null;
}

/// `(end - start) mod 1440`, where 0 means 24 h.
int _durationBetween(int start, int end) {
  final d = (end - start) % _minutesPerDay;
  return d == 0 ? _minutesPerDay : d;
}

enum ShiftCategory {
  /// Counts worked hours.
  work,

  /// Day off or post-night rest; no hours.
  rest,

  /// Vacation, personal day, sick leave...; no worked hours.
  absence,
}

class ShiftType {
  const ShiftType({
    required this.id,
    required this.code,
    required this.name,
    required this.colorValue,
    required this.category,
    this.startMinute,
    this.endMinute,
    this.paidMinutes,
    this.nightOverride,
    this.hourlyRateCents,
    this.fixedPlusCents,
    this.icon,
    this.alarmSound,
    this.segment2StartMinute,
    this.segment2DurationMinutes,
  }) : assert(code.length >= 1 && code.length <= 3),
       assert((startMinute == null) == (endMinute == null)),
       assert(
         (segment2StartMinute == null) == (segment2DurationMinutes == null),
       ),
       assert(
         segment2StartMinute == null || startMinute != null,
         'A second segment needs the shift to have times',
       ),
       assert(
         segment2StartMinute == null ||
             (segment2StartMinute >= 0 && segment2StartMinute < _minutesPerDay),
       ),
       assert(
         segment2DurationMinutes == null ||
             (segment2DurationMinutes >= 1 &&
                 segment2DurationMinutes <= _minutesPerDay),
       ),
       assert(alarmSound != '');

  final String id;

  /// 1-3 characters shown in the calendar cell.
  final String code;
  final String name;

  /// ARGB, e.g. `0xFFF5A524`.
  final int colorValue;
  final ShiftCategory category;

  /// Minutes since 00:00. Both set or both null (shifts without schedule).
  final int? startMinute;
  final int? endMinute;

  /// Paid minutes; defaults to [durationMinutes].
  final int? paidMinutes;

  /// `null` = automatic according to the night window.
  final bool? nightOverride;

  /// Pay per hour in cents (no floating point), for the income summary.
  /// `null` = no rate set.
  final int? hourlyRateCents;

  /// Fixed payment for each worked shift, including one without times.
  /// `null` = none; a split shift earns it once for both segments.
  final int? fixedPlusCents;

  /// Icon drawn next to the code (docs/paridad.md, A8). `null` = none.
  final ShiftIcon? icon;

  /// Opaque id of the system sound or ringtone this type's alarm uses
  /// (A3). `null` = the default sound of the alarm channel.
  final String? alarmSound;

  /// Second segment of a split shift («turno partido», A12): the clock
  /// minute (0-1439) where it starts and how long it lasts. Both set or both
  /// null; see [checkSegment2] for how it relates to the first segment.
  ///
  /// [durationMinutes], [startMinute] and [endMinute] describe the **first**
  /// segment only; the second one is [segment2StartMinute] for
  /// [segment2DurationMinutes]. The engine places each one as its own
  /// occurrence (`ShiftOccurrence.allOf`); the hours of the shift are the sum
  /// of both ([scheduledMinutes]), the gap between them is not worked.
  final int? segment2StartMinute;
  final int? segment2DurationMinutes;

  bool get hasTimes => startMinute != null;

  /// `(end - start) mod 1440`, where **0 means 24 h** (08:00-08:00 is a 24 h
  /// guard). 0 for shifts without schedule.
  int get durationMinutes {
    if (!hasTimes) return 0;
    final d = (endMinute! - startMinute!) % _minutesPerDay;
    return d == 0 ? _minutesPerDay : d;
  }

  bool get hasSegment2 => segment2StartMinute != null;

  /// Clock minute (0-1439) where the second segment ends; `null` without one.
  int? get segment2EndMinute => hasSegment2
      ? (segment2StartMinute! + segment2DurationMinutes!) % _minutesPerDay
      : null;

  /// What is wrong with the second segment, or `null` when it is valid (or
  /// there is none). Stored and imported shift types must have none.
  Segment2Problem? get segment2Problem => checkSegment2(
    startMinute: startMinute,
    endMinute: endMinute,
    segment2StartMinute: segment2StartMinute,
    segment2DurationMinutes: segment2DurationMinutes,
  );

  /// Minutes between the end of the first segment and the start of the
  /// second one; 0 without a valid second segment.
  int get segment2GapMinutes => hasSegment2 && hasTimes
      ? (segment2StartMinute! - endMinute!) % _minutesPerDay
      : 0;

  /// From the start of the first segment to the end of the second one (the
  /// gap included); [durationMinutes] when the shift is not split.
  int get spanMinutes => hasSegment2 && hasTimes
      ? durationMinutes + segment2GapMinutes + segment2DurationMinutes!
      : durationMinutes;

  /// Minutes the shift is scheduled to work: both segments, without the gap
  /// between them. [durationMinutes] when the shift is not split.
  int get scheduledMinutes => hasSegment2 && hasTimes
      ? durationMinutes + segment2DurationMinutes!
      : durationMinutes;

  /// Clock minute (0-1439) where the shift ends for good: the end of the
  /// second segment, or [endMinute] when it is not split. `null` without
  /// times.
  int? get lastEndMinute => segment2EndMinute ?? endMinute;

  /// Whether the shift (the second segment included) reaches midnight: it
  /// ends at 00:00 or later on the next day. For a shift that is not split
  /// this is `endMinute <= startMinute`.
  bool get crossesMidnight =>
      hasTimes && startMinute! + spanMinutes >= _minutesPerDay;

  int get effectivePaidMinutes => paidMinutes ?? scheduledMinutes;

  ShiftType copyWith({
    String? id,
    String? code,
    String? name,
    int? colorValue,
    ShiftCategory? category,
    int? startMinute,
    int? endMinute,
    int? paidMinutes,
    bool? nightOverride,
    int? hourlyRateCents,
    int? fixedPlusCents,
    ShiftIcon? icon,
    String? alarmSound,
    int? segment2StartMinute,
    int? segment2DurationMinutes,
    bool clearTimes = false,
    bool clearPaidMinutes = false,
    bool clearNightOverride = false,
    bool clearHourlyRate = false,
    bool clearFixedPlus = false,
    bool clearIcon = false,
    bool clearAlarmSound = false,
    bool clearSegment2 = false,
  }) => ShiftType(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    category: category ?? this.category,
    startMinute: clearTimes ? null : startMinute ?? this.startMinute,
    endMinute: clearTimes ? null : endMinute ?? this.endMinute,
    paidMinutes: clearPaidMinutes ? null : paidMinutes ?? this.paidMinutes,
    nightOverride: clearNightOverride
        ? null
        : nightOverride ?? this.nightOverride,
    hourlyRateCents: clearHourlyRate
        ? null
        : hourlyRateCents ?? this.hourlyRateCents,
    fixedPlusCents: clearFixedPlus ? null : fixedPlusCents ?? this.fixedPlusCents,
    icon: clearIcon ? null : icon ?? this.icon,
    alarmSound: clearAlarmSound ? null : alarmSound ?? this.alarmSound,
    // A second segment follows the first one: without times it goes too.
    segment2StartMinute: clearSegment2 || clearTimes
        ? null
        : segment2StartMinute ?? this.segment2StartMinute,
    segment2DurationMinutes: clearSegment2 || clearTimes
        ? null
        : segment2DurationMinutes ?? this.segment2DurationMinutes,
  );

  @override
  bool operator ==(Object other) =>
      other is ShiftType &&
      other.id == id &&
      other.code == code &&
      other.name == name &&
      other.colorValue == colorValue &&
      other.category == category &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute &&
      other.paidMinutes == paidMinutes &&
      other.nightOverride == nightOverride &&
      other.hourlyRateCents == hourlyRateCents &&
      other.fixedPlusCents == fixedPlusCents &&
      other.icon == icon &&
      other.alarmSound == alarmSound &&
      other.segment2StartMinute == segment2StartMinute &&
      other.segment2DurationMinutes == segment2DurationMinutes;

  @override
  int get hashCode => Object.hash(
    id,
    code,
    name,
    colorValue,
    category,
    startMinute,
    endMinute,
    paidMinutes,
    nightOverride,
    hourlyRateCents,
    fixedPlusCents,
    icon,
    alarmSound,
    segment2StartMinute,
    segment2DurationMinutes,
  );

  @override
  String toString() => 'ShiftType($id, $code)';
}
