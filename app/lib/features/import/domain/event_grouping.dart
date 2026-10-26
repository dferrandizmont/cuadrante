import '../../holidays/domain/text_fold.dart';
import '../../schedule/domain/schedule_domain.dart';
import 'import_models.dart';

final RegExp _spaces = RegExp(r'[\s ]+');
final RegExp _edgePunctuation = RegExp(
  r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$',
  unicode: true,
);

/// The key two titles share when they only differ in case, accents,
/// surrounding blanks or decoration: «Mañana», « MAÑANA », «mañana ☀» all give
/// `manana`. Titles made only of symbols keep them («+», «-»).
String normalizeTitle(String title) {
  final folded = foldSpanish(title).replaceAll(_spaces, ' ').trim();
  final stripped = folded.replaceAll(_edgePunctuation, '').trim();
  return stripped.isEmpty ? folded : stripped;
}

/// The events of an import that share one normalized title.
class EventGroup {
  const EventGroup({
    required this.key,
    required this.title,
    required this.count,
    required this.timedCount,
    required this.allDayCount,
    required this.sampleDates,
    this.startMinute,
    this.endMinute,
    this.colorValue,
    this.segment2StartMinute,
    this.segment2EndMinute,
    this.codeHint,
  });

  /// [normalizeTitle] of the titles; unique among the groups of an import.
  final String key;

  /// The spelling to show (the most common one; may be empty).
  final String title;

  /// Days the group covers: a day with two shifts of the same title counts
  /// once (the days, not the shifts).
  final int count;
  final int timedCount;
  final int allDayCount;

  /// The most common start and end (minutes) among the timed occurrences,
  /// `null` when the group is (mostly) all-day. [endMinute] is `null` when the
  /// events have no end.
  final int? startMinute;
  final int? endMinute;

  /// The most common colour the source gives these events.
  final int? colorValue;

  /// The second segment of a split shift (clock minutes) and the short code
  /// the source uses, when it knows them (an LRHSoft backup).
  final int? segment2StartMinute;
  final int? segment2EndMinute;
  final String? codeHint;

  /// A few dates to recognise the group by (first, middle and last).
  final List<CivilDate> sampleDates;

  bool get hasTimes => startMinute != null;
}

/// Groups [occurrences] by [normalizeTitle], biggest group first (ties by
/// title).
List<EventGroup> groupEvents(Iterable<EventOccurrence> occurrences) {
  final byKey = <String, List<EventOccurrence>>{};
  for (final o in occurrences) {
    byKey.putIfAbsent(normalizeTitle(o.title), () => []).add(o);
  }
  final groups = [
    for (final MapEntry(:key, :value) in byKey.entries) _buildGroup(key, value),
  ];
  groups.sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    return byCount != 0 ? byCount : a.key.compareTo(b.key);
  });
  return groups;
}

EventGroup _buildGroup(String key, List<EventOccurrence> items) {
  final spellings = <String, int>{};
  final times = <(int, int?), int>{};
  final colors = <int, int>{};
  final segments2 = <(int, int), int>{};
  final hints = <String, int>{};
  var timed = 0;
  var allDay = 0;
  for (final o in items) {
    final title = o.title.trim();
    spellings[title] = (spellings[title] ?? 0) + 1;
    if (o.hasTimes) {
      timed++;
      final pair = (o.startMinute!, o.endMinute);
      times[pair] = (times[pair] ?? 0) + 1;
    } else {
      allDay++;
    }
    final color = o.colorValue;
    if (color != null) colors[color] = (colors[color] ?? 0) + 1;
    final s2Start = o.segment2StartMinute;
    final s2End = o.segment2EndMinute;
    if (o.hasTimes && s2Start != null && s2End != null) {
      final pair = (s2Start, s2End);
      segments2[pair] = (segments2[pair] ?? 0) + 1;
    }
    final hint = o.codeHint;
    if (hint != null) hints[hint] = (hints[hint] ?? 0) + 1;
  }
  final dates = [for (final o in items) o.date]..sort();
  final samples = <CivilDate>[
    dates.first,
    if (dates.length > 2) dates[dates.length ~/ 2],
    if (dates.length > 1) dates.last,
  ];
  // Mostly timed: the typical times are shown; otherwise the group is an
  // all-day one.
  final typical = timed > 0 && timed >= allDay ? _mostCommon(times) : null;
  return EventGroup(
    key: key,
    title: _mostCommon(spellings)!,
    count: dates.toSet().length,
    timedCount: timed,
    allDayCount: allDay,
    sampleDates: samples,
    startMinute: typical?.$1,
    endMinute: typical?.$2,
    colorValue: _mostCommon(colors),
    segment2StartMinute: typical == null ? null : _mostCommon(segments2)?.$1,
    segment2EndMinute: typical == null ? null : _mostCommon(segments2)?.$2,
    codeHint: _mostCommon(hints),
  );
}

/// The key with the highest count; the smallest key among ties, so the answer
/// never depends on the order of the events.
K? _mostCommon<K extends Object>(Map<K, int> counts) {
  K? best;
  var bestCount = 0;
  for (final MapEntry(:key, :value) in counts.entries) {
    if (value > bestCount || (value == bestCount && _less(key, best))) {
      best = key;
      bestCount = value;
    }
  }
  return best;
}

bool _less(Object a, Object? b) {
  if (b == null) return true;
  if (a is String && b is String) return a.compareTo(b) < 0;
  if (a is int && b is int) return a < b;
  if (a is (int, int?) && b is (int, int?)) {
    final byStart = a.$1.compareTo(b.$1);
    return byStart != 0 ? byStart < 0 : (a.$2 ?? -1) < (b.$2 ?? -1);
  }
  return false;
}
