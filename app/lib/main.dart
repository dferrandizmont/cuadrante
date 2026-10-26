import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/bootstrap/bootstrap.dart';
import 'core/config.dart';
import 'core/database/database_provider.dart';
import 'core/diagnostics/crash_reporting.dart';
import 'core/providers.dart';
import 'features/holidays/application/holidays_provider.dart';
import 'features/onboarding/application/onboarding_providers.dart';
import 'features/schedule/application/schedule_providers.dart';
import 'features/settings/application/preferences_controller.dart';

Future<void> main() async {
  // A release build with demo data never starts: fail loudly with the reason.
  if (kReleaseMode) {
    final problem = AppConfig.current.releaseProblem;
    if (problem != null) {
      throw StateError('Misconfigured release build: $problem');
    }
  }
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge: transparent bars, styled per theme in CuadranteApp.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final boot = await bootstrapApp();
  // Every record() goes through the redacting decorator, whoever calls it.
  const CrashReporter crashReporter = RedactingCrashReporter(
    NoopCrashReporter(),
  );
  await installCrashReporting(crashReporter, enabled: true);
  runApp(
    ProviderScope(
      // Failed providers surface their error instead of silently retrying.
      retry: (retryCount, error) => null,
      overrides: [
        crashReporterProvider.overrideWithValue(crashReporter),
        appDatabaseProvider.overrideWithValue(boot.database),
        initialScheduleProvider.overrideWithValue(boot.schedule),
        initialHolidaysProvider.overrideWithValue(boot.holidays),
        initialPreferencesProvider.overrideWithValue(boot.preferences),
        initialOnboardingProvider.overrideWithValue(boot.onboarding),
      ],
      child: const CuadranteApp(),
    ),
  );
}
