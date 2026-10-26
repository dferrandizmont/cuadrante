import 'package:collection/collection.dart';

import 'civil_date.dart';
import 'pattern.dart';
import 'shift_type.dart';

enum DaySource { override, pattern, none }

class ResolvedDay {
  const ResolvedDay({
    required this.date,
    this.shifts = const [],
    this.source = DaySource.none,
    this.runId,
    this.stepIndex,
    this.note,
    this.overtimeMinutes = 0,
    this.earlyLeaveMinutes = 0,
  });

  final CivilDate date;
  final List<ShiftType> shifts;
  final DaySource source;

  /// Run and cycle step that produced [shifts]; only when [source] is
  /// [DaySource.pattern].
  final String? runId;
  final int? stepIndex;
  final String? note;

  /// Extra minutes worked this day (docs/paridad.md, A6); 0 = none. They
  /// belong to the day, not to a shift, and are kept whatever the shifts are.
  final int overtimeMinutes;

  /// Minutes the user left before the end of the day's shifts (A6); 0 = none.
  final int earlyLeaveMinutes;

  /// The day carries extra or missing minutes (the small «+» of the cell).
  bool get hasExtras => overtimeMinutes > 0 || earlyLeaveMinutes > 0;

  bool get isEmpty => shifts.isEmpty;

  List<String> get shiftIds => [for (final s in shifts) s.id];
}

/// Immutable rules + exceptions model. Never stores one row per day.
class Schedule {
  Schedule({
    Iterable<ShiftType> shiftTypes = const [],
    Iterable<Pattern> patterns = const [],
    Iterable<PatternRun> runs = const [],
    Map<CivilDate, DayEntry> entries = const {},
  }) : shiftTypes = List.unmodifiable(shiftTypes),
       patterns = List.unmodifiable(patterns),
       runs = List.unmodifiable(runs),
       entries = Map.unmodifiable(entries);

  final List<ShiftType> shiftTypes;
  final List<Pattern> patterns;
  final List<PatternRun> runs;
  final Map<CivilDate, DayEntry> entries;

  late final Map<String, ShiftType> _typeById = {
    for (final t in shiftTypes) t.id: t,
  };

  late final Map<String, Pattern> _patternById = {
    for (final p in patterns) p.id: p,
  };

  /// Runs with a known pattern, highest `seq` first (ties: last listed first).
  late final List<(PatternRun, Pattern)> _activeRuns = () {
    final list = <(PatternRun, Pattern)>[
      for (final r in runs.reversed)
        if (_patternById[r.patternId] case final p? when p.steps.isNotEmpty)
          (r, p),
    ];
    mergeSort(list, compare: (a, b) => b.$1.seq.compareTo(a.$1.seq));
    return list;
  }();

  ShiftType? shiftTypeById(String id) => _typeById[id];

  Pattern? patternById(String id) => _patternById[id];

  /// Effective shifts of [d]: override > highest-seq run > empty.
  ResolvedDay resolve(CivilDate d) {
    final entry = entries[d];
    final ids = entry?.shiftTypeIds;
    if (ids == null) return _fromPattern(d, entry);
    return ResolvedDay(
      date: d,
      shifts: _lookup(ids),
      source: DaySource.override,
      note: entry!.note,
      overtimeMinutes: entry.overtimeMinutes ?? 0,
      earlyLeaveMinutes: entry.earlyLeaveMinutes ?? 0,
    );
  }

  /// What [d] would be without its manual override (the note and the extra
  /// or missing minutes are kept).
  ResolvedDay resolvePattern(CivilDate d) => _fromPattern(d, entries[d]);

  /// One [ResolvedDay] per day in `[from, to]`, both included.
  List<ResolvedDay> resolveRange(CivilDate from, CivilDate to) {
    final n = to.differenceInDays(from) + 1;
    if (n <= 0) return const [];
    return [for (var i = 0; i < n; i++) resolve(from.addDays(i))];
  }

  Schedule copyWith({
    Iterable<ShiftType>? shiftTypes,
    Iterable<Pattern>? patterns,
    Iterable<PatternRun>? runs,
    Map<CivilDate, DayEntry>? entries,
  }) => Schedule(
    shiftTypes: shiftTypes ?? this.shiftTypes,
    patterns: patterns ?? this.patterns,
    runs: runs ?? this.runs,
    entries: entries ?? this.entries,
  );

  ResolvedDay _fromPattern(CivilDate d, DayEntry? entry) {
    final note = entry?.note;
    final overtime = entry?.overtimeMinutes ?? 0;
    final earlyLeave = entry?.earlyLeaveMinutes ?? 0;
    for (final (run, pattern) in _activeRuns) {
      if (!run.covers(d)) continue;
      final step = run.stepIndexOn(d, pattern.lengthDays);
      return ResolvedDay(
        date: d,
        shifts: _lookup(pattern.steps[step]),
        source: DaySource.pattern,
        runId: run.id,
        stepIndex: step,
        note: note,
        overtimeMinutes: overtime,
        earlyLeaveMinutes: earlyLeave,
      );
    }
    return ResolvedDay(
      date: d,
      note: note,
      overtimeMinutes: overtime,
      earlyLeaveMinutes: earlyLeave,
    );
  }

  /// Unknown ids (deleted types) are skipped.
  List<ShiftType> _lookup(List<String> ids) => [
    for (final id in ids) ?_typeById[id],
  ];
}
