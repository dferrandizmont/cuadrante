import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/holidays_provider.dart';
import '../data/holiday_bundle_format.dart';
import '../domain/holiday_entry.dart';

/// The bundled index of municipalities by region (`municipalities.json`),
/// read once and kept: both pickers (settings and onboarding) share it.
/// `null` when the bundle has no index.
final municipalityIndexProvider = FutureProvider<MunicipalityIndex?>(
  (ref) => ref.watch(holidayBundleLoaderProvider).loadMunicipalities(),
);

/// The national days that some region keeps, for the «No son festivo en…»
/// note of the holidays screen.
final regionalNationalEntriesProvider =
    FutureProvider.autoDispose<List<HolidayEntry>>(
      (ref) => ref.watch(holidayRepositoryProvider).regionalNationalEntries(),
    );
