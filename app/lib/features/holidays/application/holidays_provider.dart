import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/diagnostics/crash_reporting.dart' show redactError;
import '../../../core/providers.dart';
import '../../schedule/domain/civil_date.dart';
import '../data/holiday_bundle_loader.dart';
import '../data/holiday_repository.dart';
import '../data/holiday_snapshot.dart';
import '../domain/holiday.dart';
import '../domain/holiday_import.dart';
import '../domain/holiday_place.dart';

/// The only door to the stored holidays.
final holidayRepositoryProvider = Provider<HolidayRepository>(
  (ref) => HolidayRepository(ref.watch(appDatabaseProvider)),
);

/// The holiday bundle inside the app (`assets/holidays/`).
final holidayBundleLoaderProvider = Provider<HolidayBundleLoader>(
  (ref) => HolidayBundleLoader(),
);

/// The snapshot `bootstrapApp` loaded before the first frame, so the first
/// frame already marks the holidays. `main` overrides it; without it
/// [holidayControllerProvider] loads from the database right after it is
/// first read (tests, previews).
final initialHolidaysProvider = Provider<HolidaySnapshot?>((ref) => null);

/// The chosen place and its stored holidays. Writing through it keeps the
/// month grid in step: every change reloads from the database (the truth is
/// what is stored).
final holidayControllerProvider =
    NotifierProvider<HolidayController, HolidaySnapshot>(HolidayController.new);

class HolidayController extends Notifier<HolidaySnapshot> {
  int _generation = 0;

  HolidayRepository get _repository => ref.read(holidayRepositoryProvider);

  @override
  HolidaySnapshot build() {
    final initial = ref.watch(initialHolidaysProvider);
    if (initial != null) return initial;
    reload();
    return HolidaySnapshot.empty;
  }

  /// Reads the place and its rows again. Never throws: holidays are not worth
  /// breaking the calendar for; the last good state stays.
  Future<void> reload() async {
    final generation = ++_generation;
    try {
      final snapshot = await _repository.loadSnapshot();
      if (ref.mounted && generation == _generation) state = snapshot;
    } catch (error, stack) {
      if (ref.mounted) {
        await ref
            .read(crashReporterProvider)
            .record(redactError(error), stack, fatal: false);
      }
    }
  }

  /// Chooses the region and municipality (null clears them) and reloads.
  Future<void> setPlace({String? regionCode, String? municipalityCode}) async {
    await _repository.savePlace(
      regionCode: regionCode,
      municipalityCode: municipalityCode,
    );
    await reload();
  }

  Future<void> addUserHoliday({
    required CivilDate date,
    required String name,
    HolidayScope scope = HolidayScope.local,
  }) async {
    await _repository.addUserHoliday(date: date, name: name, scope: scope);
    await reload();
  }

  /// Whether the person has an own holiday on [date] right now.
  bool hasUserHoliday(CivilDate date) => state.entries.any(
    (e) => e.source == HolidaySource.user && e.date == date,
  );

  Future<HolidayImportReceipt> importUserHolidays(
    Iterable<HolidayImportRow> rows,
  ) async {
    final receipt = await _repository.importUserHolidays(rows);
    await reload();
    return receipt;
  }

  Future<void> undoImportedHolidays(HolidayImportReceipt receipt) async {
    await _repository.undoImportedHolidays(receipt);
    await reload();
  }

  Future<void> removeUserHoliday(CivilDate date) async {
    await _repository.removeUserHoliday(date);
    await reload();
  }
}

/// The place currently chosen.
final holidayPlaceProvider = Provider<HolidayPlace>(
  (ref) => ref.watch(holidayControllerProvider.select((s) => s.place)),
);

/// Holidays by day for the chosen region and municipality (national only when
/// none is chosen), the user's own on top. What the month screen reads.
final holidaysProvider = Provider<Map<CivilDate, Holiday>>(
  (ref) => ref.watch(holidayControllerProvider.select((s) => s.byDay)),
);
