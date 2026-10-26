import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:cuadrante/features/schedule/domain/civil_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

/// Scenarios Q55 to Q59: Ajustes › Festivos (community, municipality, the
/// year list, your own holidays, next year and large text). The registry
/// lists [holidaysScenarios].
final List<QaScenario> holidaysScenarios = [
  qaHolidaysRegion, // Q55
  qaHolidaysBarcelona, // Q56
  qaHolidaysSevilla, // Q57
  qaHolidaysOwn, // Q58
  qaHolidaysNextYear, // Q59
];

// ---- helpers ---------------------------------------------------------------

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _openSettings(WidgetTester t) =>
    t.tapAndSettle(find.byTooltip('Abrir ajustes'), reason: 'botón Ajustes');

/// Settings -> Festivos.
Future<void> _openHolidays(WidgetTester t) async {
  await _openSettings(t);
  await t.tapAndSettle(_key('settings-holidays'), reason: 'fila Festivos');
  expect(_key('holidays-region'), findsOneWidget);
}

/// Back to the month screen from wherever the test is.
Future<void> _home(WidgetTester t) async {
  for (var i = 0; i < 4 && find.byType(BackButton).evaluate().isNotEmpty; i++) {
    await t.tapAndSettle(find.byType(BackButton).last, reason: 'flecha atrás');
  }
}

/// October 2026 (the month of the fixed clock) to [months] months later.
Future<void> _monthsForward(WidgetTester t, int months) async {
  for (var i = 0; i < months; i++) {
    await t.tapAndSettle(find.byTooltip('Mes siguiente'));
  }
}

Future<void> _chooseRegion(WidgetTester t, String code) async {
  await t.tapAndSettle(_key('holidays-region'));
  await t.tapAndSettle(_key('region-option-$code'));
}

Future<void> _chooseMunicipality(
  WidgetTester t,
  String search,
  String code,
) async {
  await t.tapAndSettle(_key('holidays-municipality'));
  await t.enterText(_key('municipality-search'), search);
  await t.settle();
  await t.tapAndSettle(_key('municipality-option-$code'));
}

Future<String?> _setting(QaApp app, String key) async {
  final rows = await app.query("SELECT value FROM settings WHERE key = '$key'");
  return rows.isEmpty ? null : rows.single['value'] as String;
}

Future<List<Map<String, Object?>>> _userHolidays(QaApp app) => app.query(
  "SELECT date, name, scope FROM holidays WHERE source = 'user' ORDER BY date",
);

Finder _inRow(String row, Finder matching) =>
    find.descendant(of: _key(row), matching: matching);

// ---- Q55 -------------------------------------------------------------------

/// Q55.
const qaHolidaysRegion = QaScenario(
  'Q55',
  'Festivos: elegir comunidad desde Ajustes',
  _region,
);

Future<void> _region(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  const sanEsteban = CivilDate(2026, 12, 26);

  await _openHolidays(t);
  qa.expectNoFlutterErrors('pantalla Festivos');
  expect(_inRow('holidays-region', find.text('Sin elegir')), findsOneWidget);
  expect(find.text('San Esteban'), findsNothing);
  expect(find.text('Año Nuevo'), findsOneWidget);
  await qa.shot('sin_comunidad');

  // The picker: 19 communities, alphabetical, with the escape «Sin comunidad».
  await t.tapAndSettle(_key('holidays-region'));
  expect(_key('region-option-ES-AN'), findsOneWidget);
  expect(_key('region-option-ES-MC'), findsOneWidget);
  expect(_key('region-option-none'), findsOneWidget);
  await qa.shot('selector');
  await t.tapAndSettle(_key('region-option-ES-CT'));
  qa.expectNoFlutterErrors('tras elegir');

  expect(_inRow('holidays-region', find.text('Catalunya')), findsOneWidget);
  expect(find.text('San Esteban'), findsOneWidget);
  expect(
    _inRow('holiday-row-2026-12-26-0', find.text('Catalunya')),
    findsOneWidget,
  );
  expect(find.text('No son festivo en Catalunya'), findsOneWidget);
  expect(
    await _setting(app, 'holidays.region'),
    contains('ES-CT'),
    reason: 'la comunidad se guarda en settings',
  );
  await qa.shot('cataluna');

  // The month grid follows without any reload.
  await _home(t);
  await _monthsForward(t, 2);
  expect(find.text('Diciembre'), findsOneWidget);
  expect(_key('holiday-dot-${sanEsteban.toIso()}'), findsOneWidget);

  // Closing the app keeps it, and Settings shows it.
  await app.restart();
  expect(app.container.read(holidayPlaceProvider).regionCode, 'ES-CT');
  await _openSettings(t);
  expect(_inRow('settings-holidays', find.text('Catalunya')), findsOneWidget);
  await _home(t);

  // «Sin comunidad» goes back to the national days.
  await _openHolidays(t);
  await _chooseRegion(t, 'none');
  expect(find.text('San Esteban'), findsNothing);
  expect(app.container.read(holidayPlaceProvider).regionCode, isNull);
}

// ---- Q56 -------------------------------------------------------------------

/// Q56.
const qaHolidaysBarcelona = QaScenario(
  'Q56',
  'Festivos: municipio con locales (Barcelona)',
  _barcelona,
);

Future<void> _barcelona(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);

  await _openHolidays(t);
  expect(
    _inRow('holidays-municipality', find.text('Elige antes la comunidad')),
    findsOneWidget,
    reason: 'sin comunidad no se elige municipio',
  );
  await _chooseRegion(t, 'ES-CT');
  await _chooseMunicipality(t, 'barcelona', '08019');
  qa.expectNoFlutterErrors('tras elegir Barcelona');

  expect(
    _inRow('holidays-municipality', find.text('Barcelona')),
    findsOneWidget,
  );
  expect(find.text('Festivos locales de Barcelona: incluidos'), findsOneWidget);
  expect(
    _inRow('holiday-row-2026-05-25-0', find.text('Fiesta local')),
    findsOneWidget,
  );
  expect(
    _inRow('holiday-row-2026-05-25-0', find.text('Local')),
    findsOneWidget,
  );
  expect(_key('holiday-row-2026-09-24-0'), findsOneWidget);
  final holidays = app.container.read(holidaysProvider);
  expect(holidays[const CivilDate(2026, 5, 25)]?.scope, HolidayScope.local);
  expect(await _setting(app, 'holidays.municipality'), contains('08019'));
  await qa.shot('barcelona');

  await app.restart();
  expect(
    app.container.read(holidayPlaceProvider).municipalityCode,
    '08019',
    reason: 'el municipio sobrevive a cerrar la app',
  );

  // «Ninguno» takes the local holidays away.
  await _openHolidays(t);
  await t.tapAndSettle(_key('holidays-municipality'));
  await t.tapAndSettle(_key('municipality-option-none'));
  expect(find.text('Fiesta local'), findsNothing);
  expect(app.container.read(holidayPlaceProvider).municipalityCode, isNull);
}

// ---- Q57 -------------------------------------------------------------------

/// Q57.
const qaHolidaysSevilla = QaScenario(
  'Q57',
  'Festivos: municipio sin locales (Sevilla) y búsqueda sin acentos',
  _sevilla,
);

Future<void> _sevilla(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);

  await _openHolidays(t);
  await _chooseRegion(t, 'ES-MD');

  // «alcala» finds «Alcalá de Henares».
  await t.tapAndSettle(_key('holidays-municipality'));
  await t.enterText(_key('municipality-search'), 'alcala');
  await t.settle();
  expect(_key('municipality-option-28005'), findsOneWidget);
  expect(find.text('Alcalá de Henares'), findsOneWidget);
  await qa.shot('busqueda');
  await t.tapAndSettle(_key('municipality-option-28005'));
  expect(
    find.text('Festivos locales de Alcalá de Henares: incluidos'),
    findsOneWidget,
  );

  // Sevilla has none in the bundle: the guidance line and no local rows.
  await _chooseRegion(t, 'ES-AN');
  await _chooseMunicipality(t, 'sevilla', '41091');
  qa.expectNoFlutterErrors('tras elegir Sevilla');
  expect(
    find.text('Todavía no tenemos los de tu municipio: añádelos tú abajo'),
    findsOneWidget,
  );
  expect(find.text('Fiesta local'), findsNothing);
  expect(find.text('Día de Andalucía'), findsOneWidget);
  expect(app.container.read(holidayPlaceProvider).municipalityCode, '41091');
  await qa.shot('sevilla');
}

// ---- Q58 -------------------------------------------------------------------

/// Q58.
const qaHolidaysOwn = QaScenario(
  'Q58',
  'Festivos: añadir un festivo local, quitarlo y deshacer',
  _own,
);

Future<void> _addLocal(WidgetTester t, String day, {String? name}) async {
  await t.tapAndSettle(_key('holidays-add'));
  final field = t.widget<TextField>(_key('holiday-name-field'));
  expect(field.controller!.text, 'Fiesta local', reason: 'nombre por defecto');
  await t.tapAndSettle(
    find.descendant(
      of: find.byType(CalendarDatePicker),
      matching: find.text(day),
    ),
  );
  if (name != null) {
    await t.enterText(_key('holiday-name-field'), name);
    await t.settle();
  }
  await t.tapAndSettle(_key('holiday-save'));
}

Future<void> _own(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);

  await _openHolidays(t);
  await _addLocal(t, '22');
  await t.waitFor(_key('holiday-row-2026-10-22-0'));
  qa.expectNoFlutterErrors('tras añadir');
  expect(
    _inRow('holiday-row-2026-10-22-0', find.text('Fiesta local')),
    findsOneWidget,
  );
  expect(_inRow('holiday-row-2026-10-22-0', find.text('Tuyo')), findsOneWidget);
  await _addLocal(t, '23', name: 'San Fulano');
  // Closing the sheet finishes before the file-backed save publishes the row.
  await t.waitFor(_key('holiday-row-2026-10-23-0'));
  await t.ensureVisible(_key('holiday-row-2026-10-23-0'));
  await t.settle();
  expect(find.text('San Fulano'), findsOneWidget);
  await qa.shot('dos_propios');
  final stored = await _userHolidays(app);
  expect(stored.map((r) => r['date']), ['2026-10-22', '2026-10-23']);
  expect(stored.last['name'], 'San Fulano');

  // The month marks both at once.
  await _home(t);
  expect(_key('holiday-dot-2026-10-22'), findsOneWidget);
  expect(_key('holiday-dot-2026-10-23'), findsOneWidget);
  await _openHolidays(t);

  // Remove with the button: gone, and «Deshacer» brings back just that one.
  await t.tapAndSettle(_key('holiday-remove-2026-10-22'));
  expect(_key('holiday-row-2026-10-22-0'), findsNothing);
  expect(_key('holiday-row-2026-10-23-0'), findsOneWidget);
  expect(find.text('Festivo quitado: Fiesta local'), findsOneWidget);
  expect(
    find.descendant(
      of: find.byType(SnackBar),
      matching: find.byType(TextButton),
    ),
    findsOneWidget,
    reason: 'la barra solo ofrece Deshacer',
  );
  await qa.shot('quitado');
  await t.tapAndSettle(find.text('Deshacer'));
  expect(_key('holiday-row-2026-10-22-0'), findsOneWidget);
  expect((await _userHolidays(app)).length, 2);

  // Swipe away too.
  await t.drag(_key('holiday-dismiss-2026-10-23-0'), const Offset(-600, 0));
  await t.settle();
  expect(_key('holiday-row-2026-10-23-0'), findsNothing);
  expect((await _userHolidays(app)).length, 1);
  qa.expectNoFlutterErrors('tras deslizar');

  // What is left survives closing the app.
  await app.restart();
  expect(
    app.container.read(holidaysProvider)[const CivilDate(2026, 10, 22)]?.name,
    'Fiesta local',
  );
  expect(
    app.container.read(holidaysProvider)[const CivilDate(2026, 10, 23)],
    isNull,
  );
}

// ---- Q59 -------------------------------------------------------------------

/// Q59.
const qaHolidaysNextYear = QaScenario(
  'Q59',
  'Festivos: año siguiente y texto grande',
  _nextYear,
);

Future<void> _nextYear(QaContext qa) async {
  final t = qa.tester;
  addTearDown(t.platformDispatcher.clearAllTestValues);
  await QaApp.open(qa);

  await _openHolidays(t);
  await _chooseRegion(t, 'ES-CT');
  await _chooseMunicipality(t, 'barcelona', '08019');
  expect(_key('holidays-year-2026'), findsOneWidget);
  expect(_key('holidays-year-2027'), findsOneWidget);
  expect(_key('holiday-row-2026-05-25-0'), findsOneWidget);

  await t.tapAndSettle(_key('holidays-year-2027'));
  expect(_key('holiday-row-2026-05-25-0'), findsNothing);
  expect(
    _inRow('holiday-row-2027-03-26-0', find.text('Viernes Santo')),
    findsOneWidget,
  );
  expect(find.text('Todos los Santos'), findsOneWidget);
  expect(
    find.text('Todavía no tenemos los de Barcelona en 2027: añádelos tú abajo'),
    findsOneWidget,
    reason: 'Cataluña aún no publica los locales de 2027',
  );
  await qa.shot('2027');

  // Large text: nothing overflows or hides the chips.
  for (final scale in [1.3, 2.0]) {
    final tag = 'x${scale.toString().replaceAll('.', '')}';
    t.platformDispatcher.textScaleFactorTestValue = scale;
    await t.settle();
    qa.expectNoFlutterErrors('festivos, $tag');
    await qa.shot('lista_$tag');
    await t.tapAndSettle(_key('holidays-region'));
    qa.expectNoFlutterErrors('selector, $tag');
    await qa.shot('selector_$tag');
    // Closed by picking the community already chosen. A tap at a fixed point
    // is not a way out: at large text the sheet covers that point, and the
    // next step then found the sheet still open over the screen.
    await t.tapAndSettle(_key('region-option-ES-CT'));
    expect(
      _key('region-option-ES-CT'),
      findsNothing,
      reason: 'el selector de comunidad sigue abierto, $tag',
    );
  }
}
