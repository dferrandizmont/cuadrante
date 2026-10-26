import 'package:cuadrante/app.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/onboarding/application/onboarding_providers.dart';
import 'package:cuadrante/features/onboarding/data/onboarding_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';
import '../../support/spanish_phone.dart';

/// Monday 19 October 2026, midday: the fixed "now" of these tests.
final DateTime onboardingNow = DateTime(2026, 10, 19, 12);
const CivilDate onboardingToday = CivilDate(2026, 10, 19);

/// The app opened on a first launch: an empty database (the shift types and
/// the catalogue seeded, no days), the first-use flow as the first screen.
class FirstLaunch {
  FirstLaunch._(this.tester, this.storage);

  final WidgetTester tester;
  final TestStorage storage;

  /// Taps made through [tap] (the "toques" of the happy path).
  int taps = 0;

  AppDatabase get database => storage.database;

  ProviderContainer get container =>
      ProviderScope.containerOf(tester.element(find.byType(CuadranteApp)));

  Schedule get schedule => container.read(scheduleControllerProvider).schedule;

  static Future<FirstLaunch> open(
    WidgetTester tester, {
    OnboardingStatus status = const OnboardingStatus(needed: true),
    Size size = const Size(390, 844),
    double textScale = 1.0,
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    useSpanishPhone(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearAllTestValues();
    });
    final storage = await openTestStorage(
      tester,
      now: onboardingNow,
      demo: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storage.overrides,
          clockProvider.overrideWithValue(() => onboardingNow),
          initialOnboardingProvider.overrideWithValue(status),
          ...overrides,
        ],
        child: const CuadranteApp(),
      ),
    );
    await tester.pumpAndSettle();
    return FirstLaunch._(tester, storage);
  }

  /// Waits for the writes of the editor to reach the database.
  Future<void> flushWrites() => tester.runAsync(
    () => container.read(scheduleControllerProvider.notifier).pendingWrites,
  );

  /// Runs [action] outside fake time (database work).
  Future<T> real<T>(Future<T> Function() action) async =>
      (await tester.runAsync(action)) as T;

  /// One tap on [finder] (scrolled into view first), counted.
  Future<void> tap(Finder finder) async {
    taps++;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// The title of the step on screen.
  String get title => (tester.widget(
    find.byKey(const ValueKey('onboarding-title')),
  ) as Text).data!;
}

Finder key(String value) => find.byKey(ValueKey(value));

/// Shift ids of [date] joined with `+` (`''` when empty).
String idsOn(Schedule schedule, CivilDate date) =>
    schedule.resolve(date).shiftIds.join('+');
