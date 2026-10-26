import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/icons/app_icons.dart';
import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:cuadrante/core/database/database_provider.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/onboarding/application/onboarding_controller.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:cuadrante/features/import/application/import_providers.dart';
import 'package:cuadrante/features/import/data/import_file_picker.dart';
import 'package:cuadrante/features/holidays/domain/holiday_place.dart';
import 'package:cuadrante/features/onboarding/data/onboarding_repository.dart';
import 'package:cuadrante/features/onboarding/domain/profession.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../import/import_ui_support.dart' show FakePicker;
import 'onboarding_support.dart';

Future<void> _next(FirstLaunch app) => app.tap(key('onboarding-next'));

/// Profession (nursing) and place (Madrid) answered, on the rotation step.
Future<void> _toRotation(FirstLaunch app) async {
  await app.tap(key('onboarding-profession-nursing'));
  await _next(app);
  await app.tap(key('onboarding-region'));
  await app.tap(find.text('Comunidad de Madrid'));
  await _next(app);
}

/// Shift-type writes that take their time (and can fail), to see whether the
/// flow waits for them.
class _SlowTypes extends ScheduleRepository {
  _SlowTypes(super.db, {super.now, this.fail = false});

  final bool fail;
  final saved = <String>[];

  @override
  Future<void> saveShiftType(ShiftType type, {int? sortOrder}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (fail) throw StateError('disk full');
    await super.saveShiftType(type, sortOrder: sortOrder);
    saved.add(type.id);
  }
}

void main() {
  setUpAll(initializeLocale);

  group('step 1: ¿A qué te dedicas?', () {
    testWidgets('opens first, with its eight options and no way back', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      expect(find.byType(MonthScreen), findsNothing);
      expect(app.title, '¿A qué te dedicas?');
      for (final p in Profession.values) {
        expect(
          key('onboarding-profession-${p.name}'),
          findsOneWidget,
          reason: p.name,
        );
      }
      expect(find.text('Enfermería, TCAE y celadores'), findsOneWidget);
      expect(find.text('Policía y Guardia Civil'), findsOneWidget);
      expect(key('onboarding-back'), findsNothing);
      expect(key('onboarding-skip'), findsOneWidget);
      // "Paso 1 de 6" for screen readers, six dots on screen.
      expect(
        tester.getSemantics(key('onboarding-dots')),
        matchesSemantics(label: 'Paso 1 de 6'),
      );
    });

    testWidgets('Siguiente waits for a choice; a choice carries a check', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      FilledButton next() => tester.widget<FilledButton>(
        find.descendant(
          of: key('onboarding-next'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(next().onPressed, isNull);
      await app.tap(key('onboarding-profession-police'));
      expect(next().onPressed, isNotNull);
      expect(
        find.descendant(
          of: key('onboarding-profession-police'),
          matching: find.byIcon(AppIcons.check),
        ),
        findsOneWidget,
        reason: 'la elegida lleva marca, no solo color',
      );
    });
  });

  group('step 2: ¿Dónde trabajas?', () {
    testWidgets('the 19 communities in a list; the municipality needs one', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      await app.tap(key('onboarding-profession-nursing'));
      await _next(app);
      expect(app.title, '¿Dónde trabajas?');
      expect(find.text('Elige antes la comunidad'), findsOneWidget);

      await app.tap(key('onboarding-region'));
      // 19 rows: 17 communities, Ceuta and Melilla.
      for (final name in [
        'Andalucía',
        'Catalunya',
        'Comunidad de Madrid',
        'Ceuta',
        'Melilla',
        'País Vasco',
      ]) {
        await tester.ensureVisible(find.text(name));
        expect(find.text(name), findsOneWidget, reason: name);
      }
      await tester.tap(find.text('Catalunya'));
      await tester.pumpAndSettle();
      expect(find.text('Catalunya'), findsOneWidget);
      expect(find.text('Buscar municipio'), findsOneWidget);
    });

    testWidgets('the municipality is searched, filtered by region', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      await app.tap(key('onboarding-profession-nursing'));
      await _next(app);
      await app.tap(key('onboarding-region'));
      await app.tap(find.text('Comunidad de Madrid'));
      await app.tap(key('onboarding-municipality'));

      // Accents and capitals do not matter; only Madrid's own are offered.
      await tester.enterText(
        key('onboarding-municipality-search'),
        'alcala de h',
      );
      await tester.pumpAndSettle();
      expect(find.text('Alcalá de Henares'), findsOneWidget);
      expect(find.text('Barcelona'), findsNothing);

      await tester.enterText(key('onboarding-municipality-search'), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.text('Ningún municipio se llama así'), findsOneWidget);

      await tester.enterText(key('onboarding-municipality-search'), 'madrid');
      await tester.pumpAndSettle();
      await tester.tap(key('municipality-28079'));
      await tester.pumpAndSettle();
      expect(find.text('Madrid'), findsOneWidget);
      // Madrid's locals are in the bundle: no note.
      expect(key('onboarding-local-missing'), findsNothing);
    });

    testWidgets('a municipality without local holidays says so', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      await app.tap(key('onboarding-profession-nursing'));
      await _next(app);
      await app.tap(key('onboarding-region'));
      await app.tap(find.text('Andalucía'));
      await app.tap(key('onboarding-municipality'));
      await tester.enterText(key('onboarding-municipality-search'), 'sevilla');
      await tester.pumpAndSettle();
      await tester.tap(key('municipality-41091'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Los festivos locales de tu municipio los puedes añadir tú en dos '
          'toques.',
        ),
        findsOneWidget,
      );
      // Taking the municipality off removes the note; changing the community
      // drops the municipality.
      await app.tap(key('onboarding-municipality-clear'));
      expect(key('onboarding-local-missing'), findsNothing);
      expect(find.text('Buscar municipio'), findsOneWidget);
    });

    testWidgets('changing the community forgets the municipality', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      await app.tap(key('onboarding-profession-nursing'));
      await _next(app);
      await app.tap(key('onboarding-region'));
      await app.tap(find.text('Comunidad de Madrid'));
      await app.tap(key('onboarding-municipality'));
      await tester.enterText(key('onboarding-municipality-search'), 'getafe');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Getafe'));
      await tester.pumpAndSettle();
      expect(find.text('Getafe'), findsOneWidget);

      await app.tap(key('onboarding-region'));
      await app.tap(find.text('Catalunya'));
      expect(find.text('Getafe'), findsNothing);
      expect(find.text('Buscar municipio'), findsOneWidget);
    });
  });

  group('step 3: ¿Cómo es tu rotación?', () {
    testWidgets('the cards of the job first, then the rest; or by hand', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      await _toRotation(app);
      expect(app.title, '¿Cómo es tu rotación?');
      expect(find.text('LO HABITUAL EN TU TRABAJO'), findsOneWidget);
      expect(find.text('OTRAS ROTACIONES'), findsOneWidget);
      // Nursing: 12 h, correturnos, continental, 5x2 ... then the others.
      final order = [
        for (final id in ['12h', 'correturnos', 'continental', '5x2', '24x72'])
          tester.getTopLeft(key('onboarding-pattern-$id')).dy,
      ];
      expect(order, orderedEquals([...order]..sort()));
      expect(
        tester.getTopLeft(key('onboarding-pattern-12h')).dy,
        lessThan(tester.getTopLeft(key('onboarding-by-hand')).dy),
      );
      expect(
        tester.getTopLeft(key('onboarding-by-hand')).dy,
        lessThan(tester.getTopLeft(key('onboarding-pattern-24x72')).dy),
      );
    });

    testWidgets('a profession "Otro" gets the whole catalogue in one list', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      await app.tap(key('onboarding-profession-other'));
      await _next(app);
      await _next(app); // place, left empty
      expect(find.text('LO HABITUAL EN TU TRABAJO'), findsNothing);
      expect(find.text('ROTACIONES'), findsOneWidget);
    });

    testWidgets(
      'Siguiente needs a rotation; then the start day and cycle day',
      (tester) async {
        final app = await FirstLaunch.open(tester);
        await _toRotation(app);
        FilledButton next() => tester.widget<FilledButton>(
          find.descendant(
            of: key('onboarding-next'),
            matching: find.byType(FilledButton),
          ),
        );
        expect(next().onPressed, isNull);
        await app.tap(key('onboarding-pattern-12h'));
        expect(next().onPressed, isNotNull);
        await _next(app);

        expect(app.title, '¿Cuándo empiezas?');
        expect(find.text('Lunes 19 de octubre 2026'), findsOneWidget);
        expect(
          find.text('Ese día te toca: Día 12 h 08:00–20:00'),
          findsOneWidget,
        );
        await app.tap(key('onboarding-offset-1'));
        expect(
          find.text('Ese día te toca: Noche 12 h 20:00–08:00'),
          findsOneWidget,
        );
      },
    );

    testWidgets('"Lo pinto a mano" goes on without any rotation', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      await _toRotation(app);
      await app.tap(key('onboarding-by-hand'));
      expect(app.title, '¿Vienes de otra app?');
      await _next(app);
      expect(app.title, 'Listo');
      expect(find.text('Rotación: la pintas tú a mano'), findsOneWidget);
      await app.flushWrites();
      expect(app.schedule.runs, isEmpty);
      await app.tap(key('onboarding-next'));
      expect(find.byType(MonthScreen), findsOneWidget);
      expect(idsOn(app.schedule, onboardingToday), '');
    });
  });

  group('step 4: ¿Vienes de otra app?', () {
    testWidgets('offers the import and Continuar, no mention of 0.5.0', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      await _toRotation(app);
      await app.tap(key('onboarding-pattern-12h'));
      await _next(app);
      await _next(app);
      expect(app.title, '¿Vienes de otra app?');
      expect(find.textContaining('0.5.0'), findsNothing);
      expect(find.byKey(const ValueKey('onboarding-import')), findsOneWidget);
      expect(find.text('Importar ahora'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('LRHSoft users get their own button: the .Shifter backup', (
      tester,
    ) async {
      final picker = FakePicker();
      final app = await FirstLaunch.open(
        tester,
        overrides: [importFilePickerProvider.overrideWithValue(picker.call)],
      );
      await _toRotation(app);
      await app.tap(key('onboarding-pattern-12h'));
      await _next(app);
      await _next(app);
      expect(find.text('Importar copia de LRHSoft'), findsOneWidget);
      // It opens the import and asks for the backup file right away.
      await app.tap(key('onboarding-import-lrhsoft'));
      expect(picker.asked, [ImportFileKind.lrhsoft]);
      expect(find.text('¿De dónde vienen tus turnos?'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('import-source-lrhsoft')),
        findsOneWidget,
      );
    });

    testWidgets('the button opens the import and Atrás returns to the step', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      await _toRotation(app);
      await app.tap(key('onboarding-pattern-12h'));
      await _next(app);
      await _next(app);
      await app.tap(key('onboarding-import'));
      expect(find.text('¿De dónde vienen tus turnos?'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('import-source-device')),
        findsOneWidget,
      );

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(app.title, '¿Vienes de otra app?');
      // Nothing was written by opening the import.
      await app.flushWrites();
      expect(app.schedule.runs, isEmpty);
    });
  });

  group('navigation', () {
    testWidgets('back keeps what was chosen, step by step', (tester) async {
      final app = await FirstLaunch.open(tester);
      await _toRotation(app);
      await app.tap(key('onboarding-pattern-continental'));
      await _next(app);
      await app.tap(key('onboarding-offset-3'));
      await _next(app); // import
      expect(app.title, '¿Vienes de otra app?');

      await app.tap(key('onboarding-back'));
      expect(app.title, '¿Cuándo empiezas?');
      await app.tap(key('onboarding-back'));
      expect(app.title, '¿Cómo es tu rotación?');
      await app.tap(key('onboarding-back'));
      expect(app.title, '¿Dónde trabajas?');
      expect(find.text('Comunidad de Madrid'), findsOneWidget);
      await app.tap(key('onboarding-back'));
      expect(app.title, '¿A qué te dedicas?');
      expect(key('onboarding-back'), findsNothing);

      // Forward again: the choices are still there.
      await _next(app);
      await _next(app);
      await _next(app);
      expect(app.title, '¿Cuándo empiezas?');
      // Continental, day 4 of the cycle (M M T T N N N ...): a Tarde.
      expect(find.text('Ese día te toca: Tarde 15:00–22:00'), findsOneWidget);
    });

    testWidgets('the system back button goes back, not out of the app', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      await app.tap(key('onboarding-profession-nursing'));
      await _next(app);
      expect(app.title, '¿Dónde trabajas?');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(app.title, '¿A qué te dedicas?');
    });

    testWidgets('changing the profession clears the rotation chosen', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      await _toRotation(app);
      await app.tap(key('onboarding-pattern-12h'));
      await app.tap(key('onboarding-back'));
      await app.tap(key('onboarding-back'));
      await app.tap(key('onboarding-profession-police'));
      await _next(app);
      await _next(app);
      FilledButton next() => tester.widget<FilledButton>(
        find.descendant(
          of: key('onboarding-next'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(next().onPressed, isNull);
      // Police: 6x4 first.
      expect(
        tester.getTopLeft(key('onboarding-pattern-6x4')).dy,
        lessThan(tester.getTopLeft(key('onboarding-pattern-12h')).dy),
      );
    });
  });

  group('skipping', () {
    testWidgets('"Saltar" on every step: nothing is written but "done"', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      for (var i = 0; i < 4; i++) {
        await app.tap(key('onboarding-skip'));
      }
      expect(app.title, 'Listo');
      expect(key('onboarding-skip'), findsNothing);
      expect(key('onboarding-back'), findsNothing);
      expect(find.textContaining('calendario en blanco'), findsOneWidget);

      await app.flushWrites();
      expect(app.schedule.runs, isEmpty);
      expect(app.schedule.entries, isEmpty);
      expect(app.container.read(holidayPlaceProvider), HolidayPlace.none);
      final repository = OnboardingRepository(app.database);
      expect(await app.real(repository.isDone), isTrue);
      expect(await app.real(repository.loadProfile), isNull);

      await app.tap(key('onboarding-next'));
      expect(find.byType(MonthScreen), findsOneWidget);
    });

    testWidgets('skipping a step drops what was chosen in it', (tester) async {
      final app = await FirstLaunch.open(tester);
      await _toRotation(app);
      await app.tap(key('onboarding-pattern-12h'));
      await _next(app);
      await app.tap(key('onboarding-skip')); // the start day: no rotation
      expect(app.title, '¿Vienes de otra app?');
      await _next(app);
      await app.flushWrites();
      expect(app.schedule.runs, isEmpty);
      // The profession and the place were answered, and are kept.
      expect(
        await app.real(OnboardingRepository(app.database).loadProfile),
        Profession.nursing,
      );
      expect(app.container.read(holidayPlaceProvider).regionCode, 'ES-MD');
    });
  });

  group('the result', () {
    testWidgets('a nurse in Madrid: types, place, rotation and month', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      await app.tap(key('onboarding-profession-nursing'));
      await _next(app);
      await app.tap(key('onboarding-region'));
      await app.tap(find.text('Comunidad de Madrid'));
      await app.tap(key('onboarding-municipality'));
      await tester.enterText(key('onboarding-municipality-search'), 'madrid');
      await tester.pumpAndSettle();
      await tester.tap(key('municipality-28079'));
      await tester.pumpAndSettle();
      await _next(app);
      await app.tap(key('onboarding-pattern-12h'));
      await _next(app);
      await app.tap(key('onboarding-offset-1'));
      await _next(app);
      await _next(app);

      expect(app.title, 'Listo');
      expect(
        find.text('Trabajo: Enfermería, TCAE y celadores'),
        findsOneWidget,
      );
      expect(
        find.text('Festivos: Madrid, Comunidad de Madrid'),
        findsOneWidget,
      );
      expect(
        find.text('Rotación: 12 horas, desde el lunes 19 de octubre'),
        findsOneWidget,
      );
      await app.tap(key('onboarding-next'));
      expect(find.byType(MonthScreen), findsOneWidget);
      await app.flushWrites();

      // Day 2 of D E S L is the Noche 12 h.
      expect(idsOn(app.schedule, onboardingToday), 'night12');
      expect(idsOn(app.schedule, onboardingToday.addDays(1)), 'postNight');
      expect(idsOn(app.schedule, onboardingToday.addDays(2)), 'rest');
      expect(idsOn(app.schedule, onboardingToday.addDays(3)), 'day12');

      final place = app.container.read(holidayPlaceProvider);
      expect(place.regionCode, 'ES-MD');
      expect(place.municipalityCode, '28079');
      // Madrid's own days (Almudena, 9 November) and the community's.
      final holidays = app.container.read(holidaysProvider);
      expect(holidays[const CivilDate(2026, 11, 9)]?.scope, HolidayScope.local);
      expect(
        holidays[const CivilDate(2026, 12, 8)]?.scope,
        HolidayScope.national,
      );
      expect(holidays[const CivilDate(2026, 10, 12)], isNotNull);

      final repository = OnboardingRepository(app.database);
      expect(await app.real(repository.loadProfile), Profession.nursing);
      expect(await app.real(repository.isDone), isTrue);
    });

    testWidgets('the holidays of the place show in the month', (tester) async {
      final app = await FirstLaunch.open(tester);
      await app.tap(key('onboarding-skip')); // profession
      await app.tap(key('onboarding-region'));
      await app.tap(find.text('Comunidad de Madrid'));
      await app.tap(key('onboarding-municipality'));
      await tester.enterText(key('onboarding-municipality-search'), 'madrid');
      await tester.pumpAndSettle();
      await tester.tap(key('municipality-28079'));
      await tester.pumpAndSettle();
      await _next(app); // place
      await app.tap(key('onboarding-skip')); // rotation
      await app.tap(key('onboarding-skip')); // import
      await app.tap(key('onboarding-next'));

      expect(find.byType(MonthScreen), findsOneWidget);
      // October: the national holiday. The local one is next month.
      expect(key('holiday-dot-2026-10-12'), findsOneWidget);
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      expect(key('holiday-dot-2026-11-09'), findsOneWidget);
    });
  });

  group('finishing', () {
    // Nurse, no place, no rotation: only the shift types are written.
    Future<void> toLastStep(FirstLaunch app) async {
      await app.tap(key('onboarding-profession-nursing'));
      await _next(app);
      await app.tap(key('onboarding-skip'));
      await app.tap(key('onboarding-skip'));
      expect(app.title, '¿Vienes de otra app?');
    }

    testWidgets('«Listo» comes only after the shift types are in the '
        'database', (tester) async {
      late _SlowTypes repository;
      final app = await FirstLaunch.open(
        tester,
        overrides: [
          scheduleRepositoryProvider.overrideWith((ref) {
            repository = _SlowTypes(
              ref.watch(appDatabaseProvider),
              now: () => onboardingNow,
            );
            return repository;
          }),
        ],
      );
      await toLastStep(app);

      var savedWhenReady = -1;
      app.container.listen(onboardingControllerProvider, (previous, next) {
        if (next.stage == OnboardingStage.ready && savedWhenReady < 0) {
          savedWhenReady = repository.saved.length;
        }
      });
      await app.tap(key('onboarding-next'));
      // The writes take 50 ms each: let fake time pass until it ends.
      for (var i = 0; i < 40 && savedWhenReady < 0; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      expect(repository.saved, isNotEmpty);
      expect(
        savedWhenReady,
        repository.saved.length,
        reason: 'every queued write had landed when the flow said «Listo»',
      );
      expect(
        app.container.read(onboardingControllerProvider).saveFailed,
        isFalse,
      );
      expect(await app.real(OnboardingRepository(app.database).isDone), isTrue);
    });

    testWidgets('a shift type that cannot be saved is reported', (
      tester,
    ) async {
      final app = await FirstLaunch.open(
        tester,
        overrides: [
          scheduleRepositoryProvider.overrideWith(
            (ref) => _SlowTypes(
              ref.watch(appDatabaseProvider),
              now: () => onboardingNow,
              fail: true,
            ),
          ),
        ],
      );
      await toLastStep(app);
      await app.tap(key('onboarding-next'));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      expect(app.title, 'Listo');
      expect(
        app.container.read(onboardingControllerProvider).saveFailed,
        isTrue,
      );
    });

    testWidgets('data that appeared meanwhile (a restore) is not '
        'overwritten', (tester) async {
      final app = await FirstLaunch.open(tester);
      await _toRotation(app);
      await app.tap(key('onboarding-pattern-12h'));
      await _next(app);
      await _next(app);
      expect(app.title, '¿Vienes de otra app?');

      // A backup is restored under the flow: a rotation of its own.
      await app.real(
        () => ScheduleRepository(app.database, now: () => onboardingNow).apply(
          mainCalendarId,
          ScheduleChange(
            runsAfter: [
              PatternRun(
                id: 'restored',
                patternId: '12h',
                startDate: onboardingToday.addDays(-30),
                seq: 7,
              ),
            ],
          ),
        ),
      );
      await _next(app);
      await app.flushWrites();

      expect(app.title, 'Listo');
      expect(key('onboarding-summary-empty'), findsOneWidget);
      final runs = await app.real(
        () => app.database.select(app.database.patternRuns).get(),
      );
      expect(runs.map((r) => r.id), ['restored'], reason: 'no run added');
      expect(
        app.container.read(holidayPlaceProvider),
        HolidayPlace.none,
        reason: 'the place of the flow was not written',
      );
      expect(
        await app.real(OnboardingRepository(app.database).loadProfile),
        isNull,
      );
    });
  });

  group('the tip on the month screen', () {
    testWidgets('appears once after the flow and stays closed', (tester) async {
      final app = await FirstLaunch.open(tester);
      for (var i = 0; i < 4; i++) {
        await app.tap(key('onboarding-skip'));
      }
      await app.tap(key('onboarding-next'));
      expect(key('onboarding-tip'), findsOneWidget);
      // The month screen shows the compact tip: one line that says how to
      // paint (the whole advice is in its label, for a screen reader).
      expect(find.text('Elige un turno y arrastra.'), findsOneWidget);

      await tester.tap(key('onboarding-tip-close'));
      await tester.pumpAndSettle();
      expect(key('onboarding-tip'), findsNothing);

      // Remembered: the next start does not bring it back.
      final repository = OnboardingRepository(app.database);
      expect(await app.real(repository.isTipPending), isFalse);
      final status = await app.real(
        () => repository.resolve(demo: false, force: false),
      );
      expect(status.tipPending, isFalse);
      expect(status.needed, isFalse);
    });

    testWidgets('the cross closes it as well', (tester) async {
      final app = await FirstLaunch.open(tester);
      for (var i = 0; i < 4; i++) {
        await app.tap(key('onboarding-skip'));
      }
      await app.tap(key('onboarding-next'));
      await tester.tap(key('onboarding-tip-close'));
      await tester.pumpAndSettle();
      expect(key('onboarding-tip'), findsNothing);
    });
  });
}
