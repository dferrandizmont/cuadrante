import '../../schedule/domain/schedule_domain.dart';
import 'backup_data.dart';
import 'canonical_json.dart';

/// Days resolved by the standard check: two years.
const int fingerprintWindowDays = 730;

/// The first and last day of the standard 730-day window around [today]
/// (one year back, the rest ahead).
({CivilDate from, CivilDate to}) defaultFingerprintWindow(CivilDate today) {
  final from = today.addDays(-365);
  return (from: from, to: from.addDays(fingerprintWindowDays - 1));
}

/// One canonical JSON line per day of `[from, to]` as [schedule] resolves it:
/// date, source, shift ids, run, cycle step and note. What a fingerprint
/// compares, and what a test compares across a migration.
///
/// A day with a note reminder, overtime or early leave (format version 3)
/// adds a last element with them; days without any keep the exact line they
/// always had, so the fingerprints of older data do not change.
List<String> resolvedDayLines(
  Schedule schedule, {
  required CivilDate from,
  required CivilDate to,
}) => [
  for (final d in schedule.resolveRange(from, to))
    canonicalJson([
      d.date.toIso(),
      d.source.name,
      d.shiftIds,
      d.runId,
      d.stepIndex,
      d.note,
      ?_annotations(schedule.entries[d.date]),
    ]),
];

/// The reminder, overtime and early leave of [entry], or `null` when it has
/// none of them.
Map<String, Object?>? _annotations(DayEntry? entry) {
  if (entry == null) return null;
  final overtime = entry.overtimeMinutes ?? 0;
  final early = entry.earlyLeaveMinutes ?? 0;
  if (entry.noteReminderMinute == null && overtime == 0 && early == 0) {
    return null;
  }
  return {
    'noteReminderMinute': entry.noteReminderMinute,
    'overtimeMinutes': entry.overtimeMinutes,
    'earlyLeaveMinutes': entry.earlyLeaveMinutes,
  };
}

/// The comparison of the restore matrix (docs/plan-publicacion.md): a hash of
/// the canonical entities **and** of the days the engine resolves from them,
/// **for every calendar**. Two databases with the same fingerprint show the
/// same calendars and hold the same data; any difference is a failure.
class ScheduleFingerprint {
  ScheduleFingerprint._({
    required this.digest,
    required this.entitiesDigest,
    required this.from,
    required this.to,
    required this._days,
  });

  /// `sha256` hex of window + entities + resolved days of every calendar.
  final String digest;

  /// `sha256` hex of the canonical entities alone.
  final String entitiesDigest;

  final CivilDate from;
  final CivilDate to;

  /// Calendar id -> one canonical JSON line per day of the window.
  final Map<String, List<String>> _days;

  /// Days of the window (per calendar).
  int get dayCount => to.differenceInDays(from) + 1;

  /// The calendars covered, sorted.
  List<String> get calendarIds => _days.keys.toList()..sort();

  /// The first day of the window whose resolved content differs from
  /// [other]'s in **any** calendar (same window required), or `null` when
  /// every day of every calendar is equal. A calendar only one of them has
  /// differs on the first day.
  CivilDate? firstDayDifferingFrom(ScheduleFingerprint other) {
    if (from != other.from || to != other.to) {
      throw ArgumentError('Fingerprints cover different windows');
    }
    int? first;
    for (final id in {..._days.keys, ...other._days.keys}) {
      final mine = _days[id];
      final theirs = other._days[id];
      if (mine == null || theirs == null) return from;
      for (var i = 0; i < mine.length; i++) {
        if (mine[i] != theirs[i]) {
          if (first == null || i < first) first = i;
          break;
        }
      }
    }
    return first == null ? null : from.addDays(first);
  }

  @override
  bool operator ==(Object other) =>
      other is ScheduleFingerprint && other.digest == digest;

  @override
  int get hashCode => digest.hashCode;

  @override
  String toString() => 'ScheduleFingerprint($digest, $from..$to)';
}

/// Fingerprint of [data] over the days `[from, to]` (both included).
///
/// Entities go in as their canonical JSON (calendars and timestamps
/// included, so a restore that rewrote them would show). The days come from
/// the engine (`Schedule.resolveRange`) for each calendar: date, source,
/// shift ids, run, cycle step and note of each one.
ScheduleFingerprint scheduleFingerprint(
  BackupData data, {
  required CivilDate from,
  required CivilDate to,
}) {
  final entitiesDigest = sha256Hex(canonicalJsonBytes(data.toJson()));
  final days = {
    for (final calendar in data.calendars)
      calendar.id: resolvedDayLines(
        data.toSchedule(calendar.id),
        from: from,
        to: to,
      ),
  };
  final digest = sha256Hex(
    canonicalJsonBytes({
      'from': from.toIso(),
      'to': to.toIso(),
      'entities': entitiesDigest,
      'days': days,
    }),
  );
  return ScheduleFingerprint._(
    digest: digest,
    entitiesDigest: entitiesDigest,
    from: from,
    to: to,
    days: days,
  );
}
