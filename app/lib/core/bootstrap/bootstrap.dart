import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../features/calendars/data/calendars_repository.dart';
import '../../features/holidays/data/holiday_bundle_loader.dart';
import '../../features/holidays/data/holiday_repository.dart';
import '../../features/holidays/data/holiday_snapshot.dart';
import '../../features/onboarding/data/onboarding_repository.dart';
import '../../features/schedule/data/schedule_repository.dart';
import '../../features/schedule/data/schedule_seeding.dart';
import '../../features/schedule/data/schedule_snapshot.dart';
import '../../features/schedule/domain/civil_date.dart';
import '../../features/settings/data/preferences_repository.dart';
import '../../features/settings/domain/preferences.dart';
import '../config.dart';
import '../database/app_database.dart';
import '../database/database_opener.dart';
import '../diagnostics/debug_log.dart';
import '../../features/schedule/domain/presets.dart';
import '../../l10n/app_localizations.dart';
import '../l10n/app_locales.dart';
import '../l10n/catalog_texts.dart';

/// What start-up produces for `main` to inject (`appDatabaseProvider`,
/// `initialScheduleProvider`, `initialHolidaysProvider`).
class BootstrapResult {
  BootstrapResult({
    required this.database,
    required this.schedule,
    HolidaySnapshot? holidays,
    this.preferences = Preferences.defaults,
    this.onboarding = OnboardingStatus.none,
  }) : holidays = holidays ?? HolidaySnapshot.empty;

  final AppDatabase database;

  /// The stored schedule, loaded before the first frame.
  final ScheduleSnapshot schedule;

  /// The chosen place and its holidays, loaded before the first frame.
  final HolidaySnapshot holidays;

  /// The stored appearance and calendar-layout preferences, so the first
  /// frame already has the right theme and week start.
  final Preferences preferences;

  /// Whether the first-use flow opens first (and whether its tip waits on
  /// the month screen).
  final OnboardingStatus onboarding;
}

/// Date formatting data for every app language (Ajustes › Idioma switches
/// them live, without a restart). Cheap, and the only part of start-up
/// widget tests need. The default locale stays Spanish: every formatter of
/// the app names its locale.
Future<void> initializeLocale() async {
  for (final locale in appSupportedLocales) {
    await initializeDateFormatting(locale.languageCode);
  }
  Intl.defaultLocale = 'es';
}

/// The phone's languages as [bootstrapApp] sees them when it seeds a new
/// database in the app's language; tests fix them (the host machine's
/// languages would make the seeded names change from one computer to
/// another). `null`: the phone's.
@visibleForTesting
List<Locale>? debugPhoneLocales;

/// Start-up work that must finish before the first frame, in order: locale,
/// database (with the pre-migration backup), seeding of an empty database,
/// the bundled holidays and the initial schedule. Adding a step is one more
/// line.
///
/// [database] replaces the on-disk one (tests); [now] fixes "today" for the
/// demo data; [holidayLoader] replaces the bundle inside the app (tests).
Future<BootstrapResult> bootstrapApp({
  AppConfig config = AppConfig.current,
  AppDatabase? database,
  DateTime Function()? now,
  HolidayBundleLoader? holidayLoader,
}) async {
  await initializeLocale();
  final clock = now ?? DateTime.now;
  // A database that does not exist yet is created in the phone's language
  // (its first calendar gets the name in that language): the language the
  // person chose is stored in the database, so a new one has none yet.
  catalogTexts = catalogTextsFrom(
    lookupAppLocalizations(
      resolveAppLocale(
        debugPhoneLocales ?? ui.PlatformDispatcher.instance.locales,
      ),
    ),
  );
  final db = database ?? await openAppDatabase();
  final repository = ScheduleRepository(db, now: clock);
  final preferences = await _loadPreferences(db);
  // A new database is seeded with the palette and the patterns in the app's
  // language (the stored one, else the phone's); a stored one is never
  // renamed (see `CatalogTexts`).
  catalogTexts = catalogTextsFrom(
    lookupAppLocalizations(
      preferences.language.locale ??
          resolveAppLocale(
            debugPhoneLocales ?? ui.PlatformDispatcher.instance.locales,
          ),
    ),
  );
  final seeded = await seedIfEmpty(
    repository,
    demo: config.useDemoData,
    today: CivilDate.fromDateTime(clock()),
  );
  await _repairShiftCodes(repository);
  final calendars = CalendarsRepository(db, now: clock);
  await calendars.ensureMain();
  if (seeded && db.createdThisOpen && !config.useDemoData) {
    await OnboardingRepository(db).rememberFactoryCatalog();
  }
  final holidays = await _loadHolidays(db, holidayLoader);
  return BootstrapResult(
    database: db,
    // The calendar the user left on screen (`main` the first time).
    schedule: await repository.load(await calendars.activeId()),
    holidays: holidays,
    preferences: preferences,
    // After the seeding: a demo database has runs and days by now.
    onboarding: await OnboardingRepository(db)
        .resolve(demo: config.useDemoData, force: config.forceOnboarding),
  );
}

/// Fixes shift type codes an older build let through (too long for the
/// engine and the backup). Never blocks start-up.
Future<void> _repairShiftCodes(ScheduleRepository repository) async {
  try {
    await repository.repairShiftTypeCodes();
  } catch (error) {
    debugLogFailure(
      'Tipos de turno: no se pudieron revisar los códigos',
      error,
    );
  }
}

/// The stored preferences; they never block start-up (unreadable = defaults).
Future<Preferences> _loadPreferences(AppDatabase db) async {
  try {
    return await PreferencesRepository(db).load();
  } catch (error) {
    debugLogFailure('Ajustes: no se pudieron leer las preferencias', error);
    return Preferences.defaults;
  }
}

/// Brings the bundled holidays up to date (a manifest read and nothing else
/// when the stored `bundleVersion` is current) and loads the chosen place's
/// holidays. Holidays never block start-up: if the bundle cannot be read the
/// app starts with what is already stored.
Future<HolidaySnapshot> _loadHolidays(
  AppDatabase db,
  HolidayBundleLoader? loader,
) async {
  final repository = HolidayRepository(db);
  try {
    await repository.refreshBundled(loader ?? HolidayBundleLoader());
  } catch (error) {
    debugLogFailure(
      'Festivos: no se pudo actualizar el paquete incluido',
      error,
    );
  }
  try {
    return await repository.loadSnapshot();
  } catch (error) {
    debugLogFailure('Festivos: no se pudieron leer', error);
    return HolidaySnapshot.empty;
  }
}
