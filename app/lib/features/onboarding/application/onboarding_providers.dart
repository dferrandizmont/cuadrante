import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../holidays/data/holiday_bundle_format.dart';
import '../../holidays/domain/holiday.dart';
import '../../holidays/domain/holiday_place.dart';
import '../../holidays/domain/spanish_regions.dart';
import '../data/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(appDatabaseProvider)),
);

/// What `bootstrapApp` decided before the first frame (`main` overrides it).
/// Left `null` (tests, the QA harness) the first-use flow is not shown.
final initialOnboardingProvider = Provider<OnboardingStatus?>((ref) => null);

/// The municipalities of the bundle, for the picker of step 2. `null` when
/// the bundle has no index (the step then offers the community only).
final municipalityIndexProvider = FutureProvider<MunicipalityIndex?>(
  (ref) => ref.watch(holidayBundleLoaderProvider).loadMunicipalities(),
);

/// Whether the bundle has local holidays for the municipality [code] (INE),
/// so step 2 can tell the person when they have to add them themselves.
final localHolidaysAvailableProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, code) async {
      final region = regionOfMunicipality(code);
      final rows = await ref
          .watch(holidayRepositoryProvider)
          .entriesFor(
            HolidayPlace(regionCode: region?.code, municipalityCode: code),
          );
      return rows.any(
        (e) =>
            e.scope == HolidayScope.local &&
            e.source != HolidaySource.user &&
            e.municipalityCode == code,
      );
    });

/// The tip on the month screen about painting and the pattern button: waiting
/// from the end of the first-use flow until the person closes it. Remembered
/// (`onboarding.tipPending`).
class OnboardingTip extends Notifier<bool> {
  @override
  bool build() {
    final initial = ref.read(initialOnboardingProvider);
    if (initial != null) return initial.tipPending;
    unawaited(_load());
    return false;
  }

  Future<void> _load({bool sync = false}) async {
    try {
      final stored = await ref
          .read(onboardingRepositoryProvider)
          .isTipPending();
      // At start only a stored `true` matters (the initial state is false);
      // a reload follows the stored value both ways.
      if (ref.mounted && (stored || sync)) state = stored;
    } catch (_) {
      // No readable database (previews): no tip.
    }
  }

  /// Reads the stored flag again (a restore replaced the settings table; the
  /// device's own flag is kept by it).
  Future<void> reload() => _load(sync: true);

  /// The flow has just finished: show the tip.
  void show() => state = true;

  /// Closes the tip for good.
  Future<void> dismiss() async {
    state = false;
    try {
      await ref.read(onboardingRepositoryProvider).setTipPending(false);
    } catch (_) {
      // Worst case it comes back once on the next launch.
    }
  }
}

final onboardingTipProvider = NotifierProvider<OnboardingTip, bool>(
  OnboardingTip.new,
);
