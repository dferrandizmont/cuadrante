import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/diagnostics/debug_log.dart';
import 'package:cuadrante/features/onboarding/data/onboarding_repository.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/data/schedule_seeding.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/backup/backup_test_support.dart';

/// What reaches the developer console (and logcat, since `debugPrint` also
/// prints in release builds) must never quote user data.
void main() {
  final lines = <String>[];

  setUp(() {
    lines.clear();
    debugLogSink = lines.add;
  });
  tearDown(() => debugLogSink = null);

  test('debugLogFailure keeps the type and drops the message', () {
    debugLogFailure(
      'Ajustes: no se pudieron leer',
      const FormatException('Nota: baja por ansiedad'),
    );
    expect(lines, ['Ajustes: no se pudieron leer (FormatException)']);
  });

  test('repairing a shift code logs a count, not the code or its id', () async {
    final AppDatabase db = openMemoryDatabase();
    addTearDown(db.close);
    final repo = ScheduleRepository(db, now: () => DateTime(2026, 10, 19, 12));
    await seedIfEmpty(repo, demo: false, today: const CivilDate(2026, 10, 19));
    await db.customStatement(
      "UPDATE shift_types SET code = 'SECRETO' WHERE id = 'morning'",
    );

    expect(await repo.repairShiftTypeCodes(), 1);

    expect(lines, hasLength(1));
    expect(lines.single, isNot(contains('SECRETO')));
    expect(lines.single, isNot(contains('morning')));
    expect(lines.single, contains('7'));
  });

  test('the first-use check logs only the error type when it fails', () async {
    final AppDatabase db = openMemoryDatabase();
    addTearDown(db.close);
    await db.customStatement('DROP TABLE settings');

    final status = await OnboardingRepository(db)
        .resolve(demo: false, force: false);

    expect(status, OnboardingStatus.none);
    expect(lines, hasLength(1));
    expect(lines.single, startsWith('Primer uso: no se pudo comprobar ('));
    // Only "(<Type>)" follows: no message text.
    expect(lines.single, matches(RegExp(r'\(\w+\)$')));
  });
}
