import '../../schedule/domain/schedule_domain.dart';

/// Longest period the summary accepts between two dates (a leap year).
const int maxSummaryRangeDays = 366;

/// A free period of the summary: [from] to [to], both included, at most
/// [maxSummaryRangeDays] days. The summary of it is `summarizeRange` (the same
/// aggregate as a month). Equal ranges are equal values, so it can key a
/// provider.
class SummaryRange {
  const SummaryRange(this.from, this.to);

  /// The whole month that contains [anyDay].
  factory SummaryRange.month(CivilDate anyDay) =>
      SummaryRange(anyDay.firstDayOfMonth, anyDay.lastDayOfMonth);

  final CivilDate from;
  final CivilDate to;

  /// Days it spans, both ends included (0 or less when [to] is before
  /// [from]).
  int get days => to.differenceInDays(from) + 1;

  bool get isValid => days >= 1 && days <= maxSummaryRangeDays;

  /// The same number of days immediately before [from] (what the summary
  /// compares the hours with).
  SummaryRange get previous =>
      SummaryRange(from.addDays(-days), from.addDays(-1));

  /// This range moved by [periods] times its own length (negative = back).
  SummaryRange shifted(int periods) =>
      SummaryRange(from.addDays(periods * days), to.addDays(periods * days));

  /// The range with a new first day. A first day after [to] drags [to] with
  /// it (a single day); one that leaves more than [maxSummaryRangeDays]
  /// shortens [to] to the limit. `clamped` says whether [to] was moved
  /// because of the limit.
  ({SummaryRange range, bool clamped}) withFrom(CivilDate day) {
    if (day.isAfter(to)) return (range: SummaryRange(day, day), clamped: false);
    return _limited(day, to);
  }

  /// The range with a new last day. One before [from] makes a single day
  /// (the new date); one that leaves more than [maxSummaryRangeDays] shortens
  /// it to the limit.
  ({SummaryRange range, bool clamped}) withTo(CivilDate day) {
    if (day.isBefore(from)) {
      return (range: SummaryRange(day, day), clamped: false);
    }
    return _limited(from, day);
  }

  static ({SummaryRange range, bool clamped}) _limited(
    CivilDate from,
    CivilDate to,
  ) {
    final last = from.addDays(maxSummaryRangeDays - 1);
    return to.isAfter(last)
        ? (range: SummaryRange(from, last), clamped: true)
        : (range: SummaryRange(from, to), clamped: false);
  }

  @override
  bool operator ==(Object other) =>
      other is SummaryRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'SummaryRange(${from.toIso()} .. ${to.toIso()})';
}
