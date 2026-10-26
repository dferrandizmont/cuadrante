import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/database/database_provider.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/probes.dart';
import 'harness.dart';

void main() {
  setUpAll(initializeLocale);

  const oct19 = CivilDate(2026, 10, 19); // today, night by rotation
  const oct24 = CivilDate(2026, 10, 24); // rest by rotation

  testWidgets('the paint bar offers only non-archived types, in order', (
    tester,
  ) async {
    await pumpCalendar(
      tester,
      prepare: (repo) async {
        await repo.archiveShiftType('night');
        await repo.archiveShiftType('personalDay');
      },
    );
    await enterPaintMode(tester);

    expect(find.byKey(const ValueKey('tool-morning')), findsOneWidget);
    expect(find.byKey(const ValueKey('tool-night')), findsNothing);
    expect(find.byKey(const ValueKey('tool-personalDay')), findsNothing);
    expect(find.byKey(const ValueKey('tool-night12')), findsOneWidget);

    final palette = containerOf(tester)
        .read(scheduleControllerProvider)
        .palette
        .map((t) => t.id);
    expect(palette.first, 'morning');
    expect(palette, isNot(contains('night')));
    // The schedule itself still knows the archived type.
    expect(scheduleOf(tester).shiftTypeById('night'), isNotNull);
  });

  testWidgets('days that use an archived type keep showing it', (tester) async {
    await pumpCalendar(
      tester,
      prepare: (repo) => repo.archiveShiftType('night'),
    );

    expect(idsOn(scheduleOf(tester), oct19), 'night');
    expect(
      find.descendant(of: cell(oct19), matching: find.text('N')),
      findsOneWidget,
    );
    // The card of today keeps the archived shift too.
    expect(find.text('ESTA NOCHE'), findsOneWidget);
    expect(find.text('22:00–06:00'), findsOneWidget);
  });

  testWidgets('a failed save shows the SnackBar and the stored schedule', (
    tester,
  ) async {
    final reporter = RecordingCrashReporter();
    await pumpCalendar(
      tester,
      overrides: [
        crashReporterProvider.overrideWithValue(reporter),
        scheduleRepositoryProvider.overrideWith(
          (ref) =>
              ProbeRepository(ref.watch(appDatabaseProvider), failCalls: {0}),
        ),
      ],
    );
    await enterPaintMode(tester);
    expect(find.text('No se ha podido guardar el cambio'), findsNothing);

    await tester.tap(cell(oct24));
    await tester.pumpAndSettle();

    expect(find.text('No se ha podido guardar el cambio'), findsOneWidget);
    // The cell shows what is stored again (the rotation's rest day).
    expect(idsOn(scheduleOf(tester), oct24), 'rest');
    expect(reporter.errors, hasLength(1));
  });

  testWidgets('a successful save shows no SnackBar', (tester) async {
    await pumpCalendar(tester);
    await enterPaintMode(tester);
    await tester.tap(cell(oct24));
    await tester.pumpAndSettle();

    expect(idsOn(scheduleOf(tester), oct24), 'morning');
    expect(find.byType(SnackBar), findsNothing);
  });
}
