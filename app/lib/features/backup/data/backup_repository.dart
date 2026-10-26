import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../../core/database/app_database.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../settings/domain/preferences.dart' show PreferenceKeys;
import '../domain/backup_codec.dart';
import '../domain/backup_data.dart';
import '../domain/backup_errors.dart';
import '../domain/backup_task_runner.dart';
import '../domain/restore_summary.dart';
import '../domain/schedule_fingerprint.dart';
import 'backup_files.dart';
import 'backup_settings_repository.dart' show cloudBackupKey;

/// Number of pre-restore safety exports kept.
const int safetyCopiesToKeep = 3;

const String _safetyPrefix = 'pre-restore';

/// `holidays.source` of the rows the user created; the only holidays a
/// backup carries (bundled and remote ones are derived again).
const String userHolidaySource = 'user';

/// Settings that describe the life of this device with the app, not the
/// person's schedule (`onboarding.done`, `onboarding.profile`,
/// `onboarding.tipPending`), the "Copia en iCloud" switch ([cloudBackupKey])
/// and the app's language ([PreferenceKeys.language]): they never go into a
/// backup file, a file that has them (an older version wrote everything, or
/// somebody crafted it) does not bring them back, and a restore leaves the
/// device's own untouched. The iCloud switch must be a consent given on this
/// device, never one that arrives in a file; the language is how this phone
/// is set up, and restoring a copy made on another one must not change it.
const String deviceSettingPrefix = 'onboarding.';

bool isDeviceSetting(String key) =>
    key.startsWith(deviceSettingPrefix) ||
    key == cloudBackupKey ||
    key == PreferenceKeys.language;

/// Reads the whole user database for a backup, and replaces it from one
/// (docs/copia-de-seguridad.md).
class BackupRepository {
  BackupRepository(
    this._db, {
    required this.safetyDirectory,
    required this.appVersion,
    this._codec = const BackupCodec(),
    DateTime Function()? now,
    AppDatabase Function()? openScratchDatabase,
    Future<Uint8List> Function(File)? readSafetyCopy,
    this._runner = runInBackgroundIsolate,
    this.keepSafetyCopies = safetyCopiesToKeep,
  }) : _now = now ?? DateTime.now,
       _openScratchDatabase = openScratchDatabase ?? _openMemoryDatabase,
       _readSafetyCopy = readSafetyCopy ?? _readSafetyFile;

  final AppDatabase _db;
  final BackupCodec _codec;
  final DateTime Function() _now;
  final AppDatabase Function() _openScratchDatabase;
  final Future<Uint8List> Function(File) _readSafetyCopy;
  final BackupTaskRunner _runner;

  static Future<Uint8List> _readSafetyFile(File file) => file.readAsBytes();

  /// Where `pre-restore-<stamp>.cuadrante` safety exports go (Application
  /// Support / backups).
  final Directory safetyDirectory;

  /// Written into the safety exports.
  final String appVersion;

  final int keepSafetyCopies;

  /// Everything the user owns, read in **one** transaction so the parts agree
  /// with each other.
  Future<BackupData> readAll() => _readAll(_db);

  /// What restoring [data] would do: counts of the file against the current
  /// database and the range of dates it covers. Writes nothing. Throws
  /// [CorruptBackup] if [data] is inconsistent.
  Future<RestoreSummary> preview(BackupData data) async {
    data.validate();
    final current = await readAll();
    return summarizeRestore(
      data,
      BackupCounts.of(current),
      currentSettings: current.settings,
    );
  }

  /// Replaces **every** user table with [data] in one transaction: all or
  /// nothing. Before touching anything it writes the current data to
  /// `pre-restore-<stamp>.cuadrante` in [safetyDirectory] and keeps the
  /// newest [keepSafetyCopies]; if that copy cannot be written the restore
  /// does not start.
  ///
  /// Bundled and remote holidays are left alone (they are derived data of
  /// this device); the holidays feature recalculates them from the restored
  /// settings.
  Future<void> restore(BackupData data) async {
    data.validate();
    final safe = _withoutForeignSounds(data);
    await _writeSafetyCopy();
    await _replaceAll(_db, safe);
  }

  /// [data] without the alarm sounds that are not the system's
  /// ([BackupData.sanitized]); the log says how many, never which.
  static BackupData _withoutForeignSounds(BackupData data) {
    final dropped = data.foreignAlarmSoundCount;
    if (dropped > 0) {
      debugPrint(
        'Backup: dropped $dropped alarm sound(s) of an unknown source',
      );
    }
    return data.sanitized();
  }

  /// "Probar restauración": a dry run of [bytes] (a `.cuadrante` file) that
  /// touches nothing. It decodes the file, rebuilds it in a scratch in-memory
  /// database, and compares fingerprints over the 730 days around [today]:
  /// the rebuilt data must equal the file ([VerificationPassed]; otherwise
  /// [VerificationMismatch] with the first differing day), and the result
  /// says whether it also equals what the phone holds now.
  Future<RestoreVerification> verifyRestore(
    Uint8List bytes, {
    required CivilDate today,
  }) async {
    final BackupFile file;
    try {
      file = _codec.decode(bytes);
    } on BackupException catch (e) {
      return VerificationFailed(e);
    }
    try {
      final window = defaultFingerprintWindow(today);
      ScheduleFingerprint fingerprint(BackupData data) =>
          scheduleFingerprint(data, from: window.from, to: window.to);

      final data = file.data.sanitized();
      final expected = fingerprint(data);
      final scratch = _openScratchDatabase();
      final BackupData rebuilt;
      try {
        await _replaceAll(scratch, data);
        rebuilt = await _readAll(scratch);
      } finally {
        await scratch.close();
      }
      final actual = fingerprint(rebuilt);
      if (actual != expected) {
        return VerificationMismatch(
          expected: expected,
          actual: actual,
          firstDifferingDay: expected.firstDayDifferingFrom(actual),
        );
      }

      final live = fingerprint(await readAll());
      final matches = live == expected;
      return VerificationPassed(
        fingerprint: expected,
        matchesLive: matches,
        firstDayDifferingFromLive: matches
            ? null
            : expected.firstDayDifferingFrom(live),
      );
    } catch (e) {
      return VerificationFailed(e);
    }
  }

  Future<void> _writeSafetyCopy() async {
    final now = _now();
    final data = await readAll();
    final codec = _codec;
    final version = appVersion;
    final bytes = await _runner(
      () => codec.encode(data, appVersion: version, exportedAt: now),
    );
    final file = await newBackupFile(safetyDirectory, _safetyPrefix, now);
    await writeFileAtomically(file, bytes);
    // Verify the file actually persisted, not the in-memory buffer. Neither
    // the live database nor older recovery copies may change on failure.
    final persisted = await _readSafetyCopy(file);
    await _runner(() {
      final verified = codec.decode(persisted);
      if (verified.data != data) {
        throw const CorruptBackup('Safety copy differs from current data');
      }
    });
    await pruneBackupFiles(
      safetyDirectory,
      backupNamePattern(_safetyPrefix),
      keepSafetyCopies,
    );
  }

  static AppDatabase _openMemoryDatabase() {
    // A scratch database next to the real one is on purpose.
    final previous = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    try {
      return AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
    } finally {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = previous;
    }
  }

  static Future<BackupData> _readAll(AppDatabase db) =>
      db.transaction(() async {
        final calendars = await db.select(db.calendars).get();
        final types =
            await (db.select(db.shiftTypes)..orderBy([
                  (t) => OrderingTerm.asc(t.sortOrder),
                  (t) => OrderingTerm.asc(t.id),
                ]))
                .get();
        // Insertion order (rowid): patterns have no sort column and the app
        // shows them in this order.
        final patterns =
            await (db.select(db.patterns)..orderBy([
                  (_) => OrderingTerm.asc(const CustomExpression<int>('rowid')),
                ]))
                .get();
        final runs = await db.select(db.patternRuns).get();
        final entries = await db.select(db.dayEntries).get();
        final holidays = await (db.select(
          db.holidays,
        )..where((h) => h.source.equals(userHolidaySource))).get();
        final balances = await db.select(db.absenceBalances).get();
        final settings = await db.select(db.settings).get();

        return BackupData(
          calendars: [
            for (final c in calendars)
              BackupCalendar(
                id: c.id,
                name: c.name,
                colorValue: c.colorValue,
                sortOrder: c.sortOrder,
                archived: c.archived,
                createdAt: c.createdAt,
                updatedAt: c.updatedAt,
              ),
          ],
          shiftTypes: [
            for (final t in types)
              BackupShiftType(
                id: t.id,
                code: t.code,
                name: t.name,
                colorValue: t.colorValue,
                category: t.category,
                startMinute: t.startMinute,
                endMinute: t.endMinute,
                paidMinutes: t.paidMinutes,
                nightOverride: t.nightOverride,
                hourlyRateCents: t.hourlyRateCents,
                fixedPlusCents: t.fixedPlusCents,
                icon: ShiftIcon.fromKey(t.icon),
                alarmSound: t.alarmSound,
                segment2StartMinute: t.segment2StartMinute,
                segment2DurationMinutes: t.segment2DurationMinutes,
                sortOrder: t.sortOrder,
                archived: t.archived,
                createdAt: t.createdAt,
                updatedAt: t.updatedAt,
              ),
          ],
          patterns: [
            for (final r in patterns)
              BackupPattern(
                id: r.id,
                name: r.name,
                steps: r.steps,
                createdAt: r.createdAt,
                updatedAt: r.updatedAt,
              ),
          ],
          patternRuns: [
            for (final r in runs)
              BackupPatternRun(
                id: r.id,
                calendarId: r.calendarId,
                patternId: r.patternId,
                startDate: r.startDate,
                endDate: r.endDate,
                stepOffset: r.stepOffset,
                seq: r.seq,
                createdAt: r.createdAt,
              ),
          ],
          dayEntries: [
            for (final e in entries)
              BackupDayEntry(
                calendarId: e.calendarId,
                date: e.date,
                shiftTypeIds: e.shiftTypeIds,
                note: e.note,
                noteReminderMinute: e.noteReminderMinute,
                overtimeMinutes: e.overtimeMinutes,
                earlyLeaveMinutes: e.earlyLeaveMinutes,
                updatedAt: e.updatedAt,
              ),
          ],
          holidays: [
            for (final h in holidays)
              BackupHoliday(
                date: CivilDate.parse(h.date),
                scope: h.scope,
                name: h.name,
                regionCode: h.regionCode,
                municipalityCode: h.municipalityCode,
              ),
          ],
          absenceBalances: [
            for (final b in balances)
              BackupAbsenceBalance(
                year: b.year,
                type: b.type,
                allowedDays: b.allowedDays,
              ),
          ],
          settings: {
            for (final s in settings)
              if (!isDeviceSetting(s.key)) s.key: s.value,
          },
        );
      });

  /// Deletes the user tables and writes [data], in one transaction on [db].
  /// Children before parents when deleting, parents before children when
  /// inserting (foreign keys are on).
  static Future<void> _replaceAll(AppDatabase db, BackupData data) =>
      db.transaction(() async {
        // Device settings survive: read before the table is emptied.
        final device = [
          for (final row in await db.select(db.settings).get())
            if (isDeviceSetting(row.key)) row,
        ];
        await db.delete(db.patternRuns).go();
        await db.delete(db.dayEntries).go();
        await db.delete(db.calendars).go();
        await db.delete(db.patterns).go();
        await db.delete(db.shiftTypes).go();
        await (db.delete(
          db.holidays,
        )..where((h) => h.source.equals(userHolidaySource))).go();
        await db.delete(db.absenceBalances).go();
        await db.delete(db.settings).go();

        await db.batch((b) {
          b.insertAll(db.calendars, [
            for (final c in data.calendars)
              CalendarsCompanion.insert(
                id: c.id,
                name: c.name,
                colorValue: c.colorValue,
                sortOrder: c.sortOrder,
                archived: Value(c.archived),
                createdAt: c.createdAt,
                updatedAt: c.updatedAt,
              ),
          ]);
          b.insertAll(db.shiftTypes, [
            for (final t in data.shiftTypes)
              ShiftTypesCompanion.insert(
                id: t.id,
                code: t.code,
                name: t.name,
                colorValue: t.colorValue,
                category: t.category,
                startMinute: Value(t.startMinute),
                endMinute: Value(t.endMinute),
                paidMinutes: Value(t.paidMinutes),
                nightOverride: Value(t.nightOverride),
                hourlyRateCents: Value(t.hourlyRateCents),
                fixedPlusCents: Value(t.fixedPlusCents),
                icon: Value(t.icon?.key),
                alarmSound: Value(t.alarmSound),
                segment2StartMinute: Value(t.segment2StartMinute),
                segment2DurationMinutes: Value(t.segment2DurationMinutes),
                sortOrder: t.sortOrder,
                archived: Value(t.archived),
                createdAt: t.createdAt,
                updatedAt: t.updatedAt,
              ),
          ]);
          // In the order given: it is the insertion (rowid) order.
          b.insertAll(db.patterns, [
            for (final p in data.patterns)
              PatternsCompanion.insert(
                id: p.id,
                name: p.name,
                steps: p.steps,
                createdAt: p.createdAt,
                updatedAt: p.updatedAt,
              ),
          ]);
          b.insertAll(db.patternRuns, [
            for (final r in data.patternRuns)
              PatternRunsCompanion.insert(
                id: r.id,
                calendarId: r.calendarId,
                patternId: r.patternId,
                startDate: r.startDate,
                endDate: Value(r.endDate),
                stepOffset: Value(r.stepOffset),
                seq: r.seq,
                createdAt: r.createdAt,
              ),
          ]);
          b.insertAll(db.dayEntries, [
            for (final e in data.dayEntries)
              DayEntriesCompanion.insert(
                calendarId: e.calendarId,
                date: e.date,
                shiftTypeIds: Value(e.shiftTypeIds),
                note: Value(e.note),
                noteReminderMinute: Value(e.noteReminderMinute),
                overtimeMinutes: Value(e.overtimeMinutes),
                earlyLeaveMinutes: Value(e.earlyLeaveMinutes),
                updatedAt: e.updatedAt,
              ),
          ]);
          b.insertAll(db.holidays, [
            for (final h in data.holidays)
              HolidaysCompanion.insert(
                date: h.date.toIso(),
                scope: h.scope,
                name: h.name,
                regionCode: Value(h.regionCode),
                municipalityCode: Value(h.municipalityCode),
                source: userHolidaySource,
              ),
          ]);
          b.insertAll(db.absenceBalances, [
            for (final a in data.absenceBalances)
              AbsenceBalancesCompanion.insert(
                year: a.year,
                type: a.type,
                allowedDays: a.allowedDays,
              ),
          ]);
          b.insertAll(db.settings, [
            for (final s in data.settings.entries)
              if (!isDeviceSetting(s.key))
                SettingsCompanion.insert(key: s.key, value: s.value),
            for (final row in device)
              SettingsCompanion.insert(key: row.key, value: row.value),
          ]);
        });
      });
}
