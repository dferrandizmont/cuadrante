import 'dart:convert';

import '../../alarms/data/alarm_settings_repository.dart' show alarmSettingsKey;
import '../../alarms/domain/alarm_settings.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../data/backup_settings_repository.dart' show autoBackupKey;
import 'backup_data.dart';
import 'schedule_fingerprint.dart';

/// How much of each kind a backup (or the database) holds.
class BackupCounts {
  const BackupCounts({
    required this.calendars,
    required this.shiftTypes,
    required this.patterns,
    required this.patternRuns,
    required this.dayEntries,
    required this.holidays,
    required this.absenceBalances,
    required this.settings,
  });

  factory BackupCounts.of(BackupData data) => BackupCounts(
    calendars: data.calendars.length,
    shiftTypes: data.shiftTypes.length,
    patterns: data.patterns.length,
    patternRuns: data.patternRuns.length,
    dayEntries: data.dayEntries.length,
    holidays: data.holidays.length,
    absenceBalances: data.absenceBalances.length,
    settings: data.settings.length,
  );

  final int calendars;
  final int shiftTypes;
  final int patterns;
  final int patternRuns;
  final int dayEntries;

  /// User holidays only.
  final int holidays;
  final int absenceBalances;
  final int settings;

  @override
  bool operator ==(Object other) =>
      other is BackupCounts &&
      other.calendars == calendars &&
      other.shiftTypes == shiftTypes &&
      other.patterns == patterns &&
      other.patternRuns == patternRuns &&
      other.dayEntries == dayEntries &&
      other.holidays == holidays &&
      other.absenceBalances == absenceBalances &&
      other.settings == settings;

  @override
  int get hashCode => Object.hash(
    calendars,
    shiftTypes,
    patterns,
    patternRuns,
    dayEntries,
    holidays,
    absenceBalances,
    settings,
  );

  @override
  String toString() =>
      'BackupCounts(calendars $calendars, types $shiftTypes, patterns $patterns, runs $patternRuns, '
      'entries $dayEntries, holidays $holidays, balances $absenceBalances, '
      'settings $settings)';
}

/// What restoring a backup would do, for the confirmation screen.
class RestoreSummary {
  const RestoreSummary({
    required this.incoming,
    required this.current,
    this.firstDate,
    this.lastDate,
    this.hasOpenEndedRun = false,
    this.turnsOffAutoBackup = false,
    this.turnsOffAlarms = false,
  });

  /// What the file holds.
  final BackupCounts incoming;

  /// What the database holds now (and the restore replaces).
  final BackupCounts current;

  /// Earliest and latest calendar day the file mentions (entries, and run
  /// starts and ends), or `null` when it has none. Open-ended runs do not
  /// move [lastDate]; see [hasOpenEndedRun].
  final CivilDate? firstDate;
  final CivilDate? lastDate;

  /// A rotation without end date goes on after [lastDate].
  final bool hasOpenEndedRun;

  /// Restoring would switch OFF the automatic copies, which are on now. A
  /// file is user-supplied data: one that quietly turns off the safety net
  /// (or the alarms that wake the user for a shift) is said so before the
  /// user confirms.
  final bool turnsOffAutoBackup;

  /// Restoring would switch OFF the alarms, which are on now (no `alarms`
  /// setting in the file counts as off, as restoring deletes the current one).
  final bool turnsOffAlarms;
}

/// Whether the settings say the automatic copies are on: on unless stored as
/// `false` (the default of `BackupSettingsRepository`).
bool autoBackupIsOn(Map<String, String> settings) {
  final raw = settings[autoBackupKey];
  if (raw == null) return true;
  try {
    return jsonDecode(raw) != false;
  } catch (_) {
    return true;
  }
}

/// Whether the settings say the alarms are on (the global switch). Missing or
/// unreadable is off, like `AlarmSettingsRepository.load`.
bool alarmsAreOn(Map<String, String> settings) {
  final raw = settings[alarmSettingsKey];
  if (raw == null) return false;
  try {
    final json = jsonDecode(raw);
    if (json is Map) {
      return AlarmSettings.fromJson(json.cast<String, Object?>()).enabled;
    }
  } catch (_) {
    // Unreadable: off.
  }
  return false;
}

/// The summary of [data] against the current database counts.
///
/// [currentSettings] is the `settings` table now (raw JSON texts, as in a
/// backup): the summary says which protections the file would turn off.
RestoreSummary summarizeRestore(
  BackupData data,
  BackupCounts current, {
  Map<String, String> currentSettings = const {},
}) {
  final dates = <CivilDate>[
    for (final e in data.dayEntries) e.date,
    for (final r in data.patternRuns) ...[r.startDate, ?r.endDate],
  ]..sort();
  return RestoreSummary(
    incoming: BackupCounts.of(data),
    current: current,
    firstDate: dates.isEmpty ? null : dates.first,
    lastDate: dates.isEmpty ? null : dates.last,
    hasOpenEndedRun: data.patternRuns.any((r) => r.endDate == null),
    turnsOffAutoBackup:
        autoBackupIsOn(currentSettings) && !autoBackupIsOn(data.settings),
    turnsOffAlarms: alarmsAreOn(currentSettings) && !alarmsAreOn(data.settings),
  );
}

/// Outcome of the dry run behind "Probar restauración".
sealed class RestoreVerification {
  const RestoreVerification();
}

/// The dry restore of the file reproduced it exactly (same entities, same
/// days). [matchesLive] says whether it also equals what the phone holds now;
/// when it does not, the copy is older than the current data and
/// [firstDayDifferingFromLive] is the first calendar day that differs
/// (`null` when only non-calendar data differs).
class VerificationPassed extends RestoreVerification {
  const VerificationPassed({
    required this.fingerprint,
    required this.matchesLive,
    this.firstDayDifferingFromLive,
  });

  final ScheduleFingerprint fingerprint;
  final bool matchesLive;
  final CivilDate? firstDayDifferingFromLive;
}

/// The file decoded but rebuilding it did **not** give the same data: a
/// real fault in the restore. [firstDifferingDay] is `null` when the
/// resolved days agree and only stored entities differ.
class VerificationMismatch extends RestoreVerification {
  const VerificationMismatch({
    required this.expected,
    required this.actual,
    this.firstDifferingDay,
  });

  final ScheduleFingerprint expected;
  final ScheduleFingerprint actual;
  final CivilDate? firstDifferingDay;
}

/// The file could not be read or the dry run failed.
class VerificationFailed extends RestoreVerification {
  const VerificationFailed(this.error);

  /// A `BackupException` for an unusable file; anything else for a failure
  /// of the dry run itself.
  final Object error;
}
