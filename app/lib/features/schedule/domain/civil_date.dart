/// How many years around today a date named by a link (widget tap, `?mes=`)
/// may lie. A link can come from any app: `0000-01` or `9999-12` is not a
/// month anyone means.
const int maxLinkYearsFromToday = 50;

/// Whether [year] is within [maxLinkYearsFromToday] years of [today].
bool isLinkYearInRange(int year, CivilDate today) =>
    (year - today.year).abs() <= maxLinkYearsFromToday;

/// Calendar date without time or time zone. All arithmetic goes through UTC
/// epoch days so daylight-saving changes can never shift a result.
class CivilDate implements Comparable<CivilDate> {
  const CivilDate(this.year, this.month, this.day)
    : assert(month >= 1 && month <= 12),
      assert(day >= 1 && day <= 31);

  /// Uses the local fields of [dt]; the time of day is dropped.
  factory CivilDate.fromDateTime(DateTime dt) =>
      CivilDate(dt.year, dt.month, dt.day);

  factory CivilDate.fromEpochDay(int epochDay) {
    final dt = DateTime.fromMillisecondsSinceEpoch(
      epochDay * Duration.millisecondsPerDay,
      isUtc: true,
    );
    return CivilDate(dt.year, dt.month, dt.day);
  }

  /// Parses `yyyy-MM-dd`; throws [FormatException] on anything else.
  factory CivilDate.parse(String iso) {
    final m = _isoPattern.firstMatch(iso);
    if (m != null) {
      final y = int.parse(m[1]!);
      final mo = int.parse(m[2]!);
      final d = int.parse(m[3]!);
      if (mo >= 1 && mo <= 12 && d >= 1 && d <= _daysIn(y, mo)) {
        return CivilDate(y, mo, d);
      }
    }
    throw FormatException('Invalid ISO date', iso);
  }

  static final _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  int get epochDay =>
      DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  /// 1 = Monday ... 7 = Sunday, like [DateTime.weekday].
  int get weekday => DateTime.utc(year, month, day).weekday;

  CivilDate get firstDayOfMonth => CivilDate(year, month, 1);

  CivilDate get lastDayOfMonth => CivilDate(year, month, daysInMonth);

  int get daysInMonth => _daysIn(year, month);

  CivilDate addDays(int n) => CivilDate.fromEpochDay(epochDay + n);

  /// `this - other` in days (positive when this is later).
  int differenceInDays(CivilDate other) => epochDay - other.epochDay;

  bool isBefore(CivilDate other) => compareTo(other) < 0;

  bool isAfter(CivilDate other) => compareTo(other) > 0;

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  static int _daysIn(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  @override
  int compareTo(CivilDate other) {
    final c = year.compareTo(other.year);
    if (c != 0) return c;
    final m = month.compareTo(other.month);
    return m != 0 ? m : day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is CivilDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
