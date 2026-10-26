import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/diagnostics/debug_log.dart';
import '../../schedule/domain/presets.dart';
import '../domain/profession.dart';

/// Keys of the `settings` table (JSON values) of the first-use flow.
abstract final class OnboardingSettings {
  /// `true` once the first-use flow has been done, skipped or is not needed
  /// (an existing user with data). Never shown again.
  static const done = 'onboarding.done';

  /// The profession chosen in step 1 (`"nursing"`, `"police"`...), see
  /// [Profession.stored].
  static const profile = 'onboarding.profile';

  /// `true` from the end of the flow until the user closes the tip about
  /// painting on the month screen.
  static const tipPending = 'onboarding.tipPending';
}

/// Whether the first-use flow has to be shown, and whether its tip is
/// waiting on the month screen. What `bootstrapApp` works out before the
/// first frame.
class OnboardingStatus {
  const OnboardingStatus({this.needed = false, this.tipPending = false});

  /// Nothing to show (tests, the QA harness, existing users).
  static const OnboardingStatus none = OnboardingStatus();

  final bool needed;
  final bool tipPending;

  @override
  bool operator ==(Object other) =>
      other is OnboardingStatus &&
      other.needed == needed &&
      other.tipPending == tipPending;

  @override
  int get hashCode => Object.hash(needed, tipPending);

  @override
  String toString() => 'OnboardingStatus(needed $needed, tip $tipPending)';
}

/// Reads and writes the first-use settings.
class OnboardingRepository {
  OnboardingRepository(this._db);

  final AppDatabase _db;

  static const _factoryCatalogKey = 'onboarding.factoryCatalog';

  /// Called only by bootstrap after seeding a database this connection
  /// actually created. The complete rows prove these are still provisional
  /// factory values, rather than old or imported data resembling defaults.
  Future<void> rememberFactoryCatalog() async {
    await _write(_factoryCatalogKey, await _factorySnapshot());
  }

  Future<Object> _factorySnapshot() async => {
    for (final table in ['shift_types', 'patterns', 'calendars'])
      table: [
        for (final row
            in await _db.customSelect('SELECT * FROM $table ORDER BY id').get())
          row.data,
      ],
  };

  /// Finalizes a newly created, untouched factory catalogue in the chosen
  /// onboarding language. Any edit/import/restore invalidates the snapshot:
  /// consume the marker and leave every stored value alone. After this one
  /// finalization, language changes never rename the person's data.
  Future<bool> finalizeFactoryCatalog(CatalogTexts texts) =>
      _db.transaction(() async {
        final expected = await _read(_factoryCatalogKey);
        if (expected == null) return false;
        final pristine =
            !await isDone() &&
            !await hasUserData() &&
            jsonEncode(expected) == jsonEncode(await _factorySnapshot());
        await (_db.delete(
          _db.settings,
        )..where((s) => s.key.equals(_factoryCatalogKey))).go();
        if (!pristine) return false;
        for (final template in shiftTemplates) {
          final text = texts.templates[template.key];
          await _db.customStatement(
            'UPDATE shift_types SET name = ?, code = ? WHERE id = ?',
            [
              text?.name ?? template.spanishName,
              text?.code ?? template.spanishCode,
              template.key,
            ],
          );
        }
        for (final preset in patternPresets) {
          await _db.customStatement(
            'UPDATE patterns SET name = ? WHERE id = ?',
            [texts.presets[preset.id]?.name ?? preset.spanishName, preset.id],
          );
        }
        if (texts.mainCalendarName != null) {
          await _db.customStatement(
            'UPDATE calendars SET name = ? WHERE id = ?',
            [texts.mainCalendarName!, 'main'],
          );
        }
        return true;
      });

  /// Whether to show the flow on this launch (see [OnboardingStatus]).
  ///
  /// - Done before: no.
  /// - [force] (`FORCE_ONBOARDING=true`): yes, whatever the data.
  /// - A build with demo data ([demo]): no.
  /// - Any rotation (`pattern_runs`) or edited day (`day_entries`) in any
  ///   calendar, i.e. someone who upgrades with data: no, and it is marked
  ///   done so it never comes up later (if they delete everything).
  /// - Otherwise: yes.
  ///
  /// Never throws: a database that cannot be read means "do not show".
  Future<OnboardingStatus> resolve({
    required bool demo,
    required bool force,
  }) async {
    try {
      final tip = await _readBool(OnboardingSettings.tipPending);
      if (await _readBool(OnboardingSettings.done)) {
        return OnboardingStatus(tipPending: tip);
      }
      if (force) return OnboardingStatus(needed: true, tipPending: tip);
      if (demo) return OnboardingStatus(tipPending: tip);
      if (await hasUserData()) {
        await markDone();
        return OnboardingStatus(tipPending: tip);
      }
      return OnboardingStatus(needed: true, tipPending: tip);
    } catch (error) {
      debugLogFailure('Primer uso: no se pudo comprobar', error);
      return OnboardingStatus.none;
    }
  }

  /// Whether the person has already set the app up: any calendar with a
  /// rotation or a day edited by hand, or, for versions that did not need
  /// either, a shift type edited after it was created, a place chosen for the
  /// holidays, alarms switched on, or more than one calendar. The seeded
  /// defaults of a first launch are none of those.
  Future<bool> hasUserData() async {
    Future<bool> any(String sql) async =>
        (await _db.customSelect(sql).get()).isNotEmpty;

    if (await any('SELECT 1 AS x FROM pattern_runs LIMIT 1')) return true;
    if (await any('SELECT 1 AS x FROM day_entries LIMIT 1')) return true;
    if (await any(
      'SELECT 1 AS x FROM shift_types WHERE updated_at != created_at LIMIT 1',
    )) {
      return true;
    }
    if (await any('SELECT 1 AS x FROM calendars LIMIT 1 OFFSET 1')) {
      return true;
    }
    final region = await _read(_holidayRegionKey);
    if (region is String && region.isNotEmpty) return true;
    final alarms = await _read(_alarmSettingsKey);
    return alarms is Map && alarms['enabled'] == true;
  }

  // Keys written by other features (`HolidaySettings.region`,
  // `alarmSettingsKey`); read as plain settings so this file keeps no
  // dependency on them.
  static const _holidayRegionKey = 'holidays.region';
  static const _alarmSettingsKey = 'alarms';

  Future<bool> isDone() => _readBool(OnboardingSettings.done);

  Future<bool> isTipPending() => _readBool(OnboardingSettings.tipPending);

  /// Marks the flow as finished; with [tip] the month screen shows its tip.
  Future<void> markDone({bool tip = false}) => _db.transaction(() async {
    await _write(OnboardingSettings.done, true);
    await (_db.delete(
      _db.settings,
    )..where((s) => s.key.equals(_factoryCatalogKey))).go();
    if (tip) await _write(OnboardingSettings.tipPending, true);
  });

  Future<void> setTipPending(bool value) =>
      _write(OnboardingSettings.tipPending, value);

  Future<void> saveProfile(Profession profession) =>
      _write(OnboardingSettings.profile, profession.stored);

  /// The profession chosen in the flow, or `null`.
  Future<Profession?> loadProfile() async =>
      Profession.fromStored(await _read(OnboardingSettings.profile));

  Future<bool> _readBool(String key) async => await _read(key) == true;

  Future<Object?> _read(String key) async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    if (row == null) return null;
    try {
      return jsonDecode(row.value);
    } on FormatException {
      return null;
    }
  }

  Future<void> _write(String key, Object value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: jsonEncode(value)),
      );
}
