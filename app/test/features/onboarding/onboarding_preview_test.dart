import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/config.dart';
import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/onboarding/domain/profession.dart';
import 'package:cuadrante/features/patterns/domain/pattern_catalog.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';
import 'onboarding_support.dart';

Future<Schedule> _seeded() async {
  final db = openMemoryDatabase();
  addTearDown(db.close);
  await bootstrapApp(
    config: const AppConfig(useDemoData: false),
    database: db,
    now: () => onboardingNow,
  );
  return (await ScheduleRepository(
    db,
    now: () => onboardingNow,
  ).load(mainCalendarId)).schedule;
}

/// H-T17-4: the hours step 4 shows for «that day» are the ones the calendar
/// gets when the wizard finishes.
void main() {
  setUpAll(initializeLocale);

  test('the preview shows the shift types that finishing will create, for '
      'every job and every rotation', () async {
    final seeded = await _seeded();

    for (final profession in Profession.values) {
      // What `finish` writes into the calendar.
      final written = {
        for (final t in seeded.shiftTypes) t.id: t,
        for (final t in professionShiftTypes(seeded, profession)) t.id: t,
      };
      final preview = scheduleWithProfession(seeded, profession);
      for (final preset in patternPresets) {
        final pattern = presetPattern(seeded, preset);
        for (final step in pattern.steps) {
          for (final id in step) {
            final shown = shiftTypeForDisplay(preview, id)!;
            final created = written[id]!;
            final reason = '${profession.name} / ${preset.id} / $id';
            expect(shown.startMinute, created.startMinute, reason: reason);
            expect(shown.endMinute, created.endMinute, reason: reason);
            expect(shown.name, created.name, reason: reason);
          }
        }
      }
    }
  });

  test('no job: the preview is the schedule as it is', () async {
    final seeded = await _seeded();
    expect(scheduleWithProfession(seeded, null), same(seeded));
    expect(scheduleWithProfession(seeded, Profession.other), same(seeded));
  });

  testWidgets('step 4 shows the hours the calendar ends up with', (
    tester,
  ) async {
    final app = await FirstLaunch.open(tester);
    await app.tap(key('onboarding-profession-nursing'));
    await app.tap(key('onboarding-next'));
    await app.tap(key('onboarding-skip'));
    await app.tap(key('onboarding-pattern-continental'));
    await app.tap(key('onboarding-next'));
    expect(app.title, '¿Cuándo empiezas?');
    // Day 1 of the cycle is a Mañana: 08:00-15:00 for a nurse, not 06:00-14:00.
    expect(find.text('Ese día te toca: Mañana 08:00–15:00'), findsOneWidget);

    await app.tap(key('onboarding-next'));
    await app.tap(key('onboarding-next'));
    await app.flushWrites();
    await app.tap(key('onboarding-next'));
    expect(find.byType(MonthScreen), findsOneWidget);
    final morning = app.schedule.shiftTypeById('morning')!;
    expect((morning.startMinute, morning.endMinute), (8 * 60, 15 * 60));
    expect(idsOn(app.schedule, onboardingToday), 'morning');
  });
}
