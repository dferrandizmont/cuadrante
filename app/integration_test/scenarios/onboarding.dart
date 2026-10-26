import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/onboarding/application/onboarding_providers.dart';
import 'package:cuadrante/features/onboarding/data/onboarding_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

/// Scenarios Q50 to Q54: the first-use flow (release 0.4.0). The registry
/// lists [onboardingScenarios].
final List<QaScenario> onboardingScenarios = [
  qaOnboardingNurse, // Q50
  qaOnboardingSkip, // Q51
  qaOnboardingPlace, // Q52
  qaOnboardingExistingUser, // Q53
  qaOnboardingTip, // Q54
];

const _nov9 = CivilDate(2026, 11, 9); // Madrid city: Virgen de la Almudena
const _oct12 = CivilDate(2026, 10, 12); // national

Finder _key(String key) => find.byKey(ValueKey(key));

/// The app on a first launch: an empty calendar and the flow as the first
/// screen, as `bootstrapApp` decides it on a clean install. [overrides] is
/// returned so a scenario can empty it before [QaApp.restart] (the second
/// start of a real install asks the database instead).
Future<(QaApp, List<Override>)> _firstLaunch(QaContext qa) async {
  final overrides = <Override>[
    initialOnboardingProvider.overrideWithValue(
      const OnboardingStatus(needed: true),
    ),
  ];
  final app = await QaApp.open(qa, demo: false, overrides: overrides);
  expect(find.byType(MonthScreen), findsNothing);
  expect(_key('onboarding-profession-nursing'), findsOneWidget);
  return (app, overrides);
}

String _title(WidgetTester t) =>
    (t.widget(_key('onboarding-title')) as Text).data!;

/// Counts the taps of a flow.
class _Taps {
  _Taps(this.t);
  final WidgetTester t;
  int count = 0;

  Future<void> call(Finder finder, {String? reason}) async {
    count++;
    await t.tapAndSettle(finder, reason: reason);
  }
}

Future<void> _pickMunicipality(
  WidgetTester t,
  String search,
  String code,
) async {
  await t.tapAndSettle(_key('onboarding-municipality'));
  await t.enterText(_key('onboarding-municipality-search'), search);
  await t.settle();
  await t.tapAndSettle(_key('municipality-$code'));
}

/// Q50.
const qaOnboardingNurse = QaScenario(
  'Q50',
  'Enfermería completa el primer uso en menos de 60 s',
  _nurse,
);

Future<void> _nurse(QaContext qa) async {
  final t = qa.tester;
  final (app, _) = await _firstLaunch(qa);

  final watch = Stopwatch()..start();
  final tap = _Taps(t);
  await tap(_key('onboarding-profession-nursing'), reason: 'Enfermería');
  await tap(_key('onboarding-next'));
  expect(_title(t), '¿Dónde trabajas?');
  await tap(_key('onboarding-region'));
  await tap(find.text('Comunidad de Madrid'));
  await tap(_key('onboarding-next'));
  expect(_title(t), '¿Cómo es tu rotación?');
  await tap(_key('onboarding-pattern-12h'));
  await tap(_key('onboarding-next'));
  expect(_title(t), '¿Cuándo empiezas?');
  await tap(_key('onboarding-offset-1'), reason: 'día 2 del ciclo');
  await tap(_key('onboarding-next'));
  expect(_title(t), '¿Vienes de otra app?');
  await tap(_key('onboarding-next'));
  expect(_title(t), 'Listo');
  await tap(_key('onboarding-next'), reason: 'Ver mi calendario');
  watch.stop();

  qa.metric('primer_uso_ms', watch.elapsedMilliseconds);
  qa.metric('primer_uso_toques', tap.count);
  expect(find.byType(MonthScreen), findsOneWidget);
  await app.flushWrites();

  // The month is painted: a 12 h rotation from today, on the night day.
  expect(idsOn(app.schedule, qaToday), 'night12');
  expect(idsOn(app.schedule, qaToday.addDays(1)), 'postNight');
  expect(idsOn(app.schedule, qaToday.addDays(3)), 'day12');
  // The shift types took the hours of nursing without duplicating anything.
  final morning = app.schedule.shiftTypeById('morning')!;
  expect([morning.startMinute, morning.endMinute], [8 * 60, 15 * 60]);
  final types = await app.query('SELECT id FROM shift_types');
  expect(
    types.map((r) => r['id']).toSet(),
    hasLength(types.length),
    reason: 'sin tipos de turno duplicados',
  );
  final profile = await app.query(
    "SELECT value FROM settings WHERE key = 'onboarding.profile'",
  );
  expect(profile.single['value'], '"nursing"');
  expect(
    watch.elapsedMilliseconds,
    lessThan(60000),
    reason: 'objetivo de la especificación: el primer uso en menos de 60 s',
  );
  expect(tap.count, lessThanOrEqualTo(12));
  await qa.shot('mes_pintado');
}

/// Q51.
const qaOnboardingSkip = QaScenario(
  'Q51',
  'Cada paso se puede saltar y el calendario queda en blanco',
  _skip,
);

Future<void> _skip(QaContext qa) async {
  final t = qa.tester;
  final (app, overrides) = await _firstLaunch(qa);

  // Back works too: forward two steps, back one, then skip from there.
  await t.tapAndSettle(_key('onboarding-profession-police'));
  await t.tapAndSettle(_key('onboarding-next'));
  expect(_title(t), '¿Dónde trabajas?');
  await t.tapAndSettle(_key('onboarding-back'));
  expect(_title(t), '¿A qué te dedicas?');

  for (final title in [
    '¿A qué te dedicas?',
    '¿Dónde trabajas?',
    '¿Cómo es tu rotación?',
    '¿Vienes de otra app?',
  ]) {
    expect(_title(t), title);
    await t.tapAndSettle(_key('onboarding-skip'), reason: 'Saltar: $title');
  }
  expect(_title(t), 'Listo');
  expect(_key('onboarding-skip'), findsNothing);
  await qa.shot('listo_sin_nada');
  await t.tapAndSettle(_key('onboarding-next'));
  expect(find.byType(MonthScreen), findsOneWidget);

  await app.flushWrites();
  expect(app.schedule.runs, isEmpty);
  expect(await app.storedDayCount(), 0);
  final done = await app.query(
    "SELECT value FROM settings WHERE key = 'onboarding.done'",
  );
  expect(done.single['value'], 'true');
  expect(
    await app.query(
      "SELECT 1 FROM settings WHERE key IN ('onboarding.profile', "
      "'holidays.region')",
    ),
    isEmpty,
    reason: 'saltar no guarda profesión ni lugar',
  );

  // Closing and opening again: the flow does not come back.
  overrides.clear();
  await app.restart();
  expect(find.byType(MonthScreen), findsOneWidget);
  expect(_key('onboarding-next'), findsNothing);
}

/// Q52.
const qaOnboardingPlace = QaScenario(
  'Q52',
  'Comunidad y municipio: festivos en el mes y aviso de los locales',
  _place,
);

Future<void> _place(QaContext qa) async {
  final t = qa.tester;
  final (app, overrides) = await _firstLaunch(qa);

  await t.tapAndSettle(_key('onboarding-skip'));
  expect(_title(t), '¿Dónde trabajas?');

  // Andalucía has no local holidays in the bundle: the note says so.
  await t.tapAndSettle(_key('onboarding-region'));
  await t.tapAndSettle(find.text('Andalucía'));
  await _pickMunicipality(t, 'sevilla', '41091');
  expect(_key('onboarding-local-missing'), findsOneWidget);
  expect(
    find.text(
      'Los festivos locales de tu municipio los puedes añadir tú en dos '
      'toques.',
    ),
    findsOneWidget,
  );
  await qa.shot('sin_locales');

  // Another community forgets the municipality; Madrid city has its own.
  await t.tapAndSettle(_key('onboarding-region'));
  await t.tapAndSettle(find.text('Comunidad de Madrid'));
  expect(_key('onboarding-local-missing'), findsNothing);
  expect(find.text('Sevilla'), findsNothing);
  await _pickMunicipality(t, 'madrid', '28079');
  expect(_key('onboarding-local-missing'), findsNothing);

  await t.tapAndSettle(_key('onboarding-next'));
  await t.tapAndSettle(_key('onboarding-skip')); // rotation
  await t.tapAndSettle(_key('onboarding-next')); // import
  await t.tapAndSettle(_key('onboarding-next')); // listo
  expect(find.byType(MonthScreen), findsOneWidget);

  final place = app.container.read(holidayPlaceProvider);
  expect(place.regionCode, 'ES-MD');
  expect(place.municipalityCode, '28079');
  expect(_key('holiday-dot-${_oct12.toIso()}'), findsOneWidget);
  await t.tapAndSettle(find.byTooltip('Mes siguiente'));
  expect(
    _key('holiday-dot-${_nov9.toIso()}'),
    findsOneWidget,
    reason: '9 nov es fiesta local de Madrid capital',
  );
  await qa.shot('festivo_local');

  // The choice survives closing the app.
  overrides.clear();
  await app.restart();
  expect(app.container.read(holidayPlaceProvider).municipalityCode, '28079');
}

/// Q53.
const qaOnboardingExistingUser = QaScenario(
  'Q53',
  'Quien actualiza con datos no ve el primer uso',
  _existingUser,
);

Future<void> _existingUser(QaContext qa) async {
  final t = qa.tester;
  // A database with a rotation and days (what 0.3.0 leaves): the app opens
  // on the month and the flow is marked as done for good.
  final app = await QaApp.open(qa);
  expect(app.schedule.runs, isNotEmpty);
  expect(find.byType(MonthScreen), findsOneWidget);
  expect(_key('onboarding-next'), findsNothing);

  final repository = OnboardingRepository(app.database);
  final status = await t.runAsync(
    () => repository.resolve(demo: false, force: false),
  );
  expect(status, OnboardingStatus.none, reason: 'hay datos: nunca el flujo');
  final done = await app.query(
    "SELECT value FROM settings WHERE key = 'onboarding.done'",
  );
  expect(done.single['value'], 'true', reason: 'queda marcado como hecho');

  // Even if they delete everything later.
  await t.runAsync(() => app.database.delete(app.database.patternRuns).go());
  await t.runAsync(() => app.database.delete(app.database.dayEntries).go());
  final again = await t.runAsync(
    () => repository.resolve(demo: false, force: false),
  );
  expect(again, OnboardingStatus.none);
}

/// Q54.
const qaOnboardingTip = QaScenario(
  'Q54',
  'El consejo del mes se cierra y no vuelve',
  _tip,
);

Future<void> _tip(QaContext qa) async {
  final t = qa.tester;
  final (app, overrides) = await _firstLaunch(qa);
  for (var i = 0; i < 4; i++) {
    await t.tapAndSettle(_key('onboarding-skip'));
  }
  await t.tapAndSettle(_key('onboarding-next'));
  expect(find.byType(MonthScreen), findsOneWidget);
  expect(_key('onboarding-tip'), findsOneWidget);
  expect(find.text('Elige un turno y arrastra.'), findsOneWidget);
  await qa.shot('consejo');

  // Not closed: it is still there after closing and opening the app.
  overrides.clear();
  await app.restart();
  // The tip is read from the database a moment after the first frame.
  await t.waitFor(_key('onboarding-tip'), reason: 'el consejo sin cerrar');

  await t.tapAndSettle(_key('onboarding-tip-close'));
  expect(_key('onboarding-tip'), findsNothing);
  await app.restart();
  expect(find.byType(MonthScreen), findsOneWidget);
  // Give the database read time to (not) bring it back.
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 400)),
  );
  await t.settle();
  expect(_key('onboarding-tip'), findsNothing);
  final stored = await app.query(
    "SELECT value FROM settings WHERE key = 'onboarding.tipPending'",
  );
  expect(stored.single['value'], 'false');
}
