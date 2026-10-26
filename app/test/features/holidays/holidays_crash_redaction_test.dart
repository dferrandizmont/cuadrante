import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/diagnostics/crash_reporting.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/holidays/data/holiday_repository.dart';
import 'package:cuadrante/features/holidays/data/holiday_snapshot.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/probes.dart';

/// A repository whose read fails with a message that quotes user data.
class _FailingHolidayRepository extends HolidayRepository {
  _FailingHolidayRepository(super.db);

  @override
  Future<HolidaySnapshot> loadSnapshot() =>
      throw const FormatException('festivo propio: cumple de Lucia');
}

void main() {
  test('a failing holiday load is reported as its type only', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final reporter = RecordingCrashReporter();
    final container = ProviderContainer(
      overrides: [
        crashReporterProvider.overrideWithValue(reporter),
        holidayRepositoryProvider.overrideWithValue(
          _FailingHolidayRepository(db),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(holidayControllerProvider, (_, _) {});

    await container.read(holidayControllerProvider.notifier).reload();

    expect(reporter.errors, isNotEmpty);
    expect(reporter.errors.every((e) => e is RedactedError), isTrue);
    expect(reporter.errors.join(' '), isNot(contains('Lucia')));
  });
}
