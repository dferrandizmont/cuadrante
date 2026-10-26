import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

/// Scenarios Q40 to Q49: Settings, calendars, the calendar switcher, the
/// theme and the week layout (release 0.3.0). The registry lists
/// [settingsScenarios].
final List<QaScenario> settingsScenarios = [
  qaSettingsScreen, // Q40
  qaSecondCalendar, // Q41
  qaSwitchAndPaint, // Q42
  qaActiveCalendarPersists, // Q43
  qaEditCalendar, // Q44
  qaArchiveCalendar, // Q45
  qaThemeFromSettings, // Q46
  qaSundayStart, // Q47
  qaWeekNumbers, // Q48
  qaSettingsLargeText, // Q49
];

const _oct18 = CivilDate(2026, 10, 18); // Sunday
const _oct19 = CivilDate(2026, 10, 19); // Monday, "today" of the battery
const _oct21 = CivilDate(2026, 10, 21);
const _oct22 = CivilDate(2026, 10, 22);
const _oct24 = CivilDate(2026, 10, 24); // Saturday
const _oct25 = CivilDate(2026, 10, 25); // Sunday

// ---- helpers ---------------------------------------------------------------

final _pill = find.byKey(const ValueKey('calendar-switcher'));

Future<void> _openSettings(WidgetTester t) =>
    t.tapAndSettle(find.byTooltip('Abrir ajustes'), reason: 'botón Ajustes');

Future<void> _openCalendars(WidgetTester t) async {
  await _openSettings(t);
  await t.tapAndSettle(find.byKey(const ValueKey('settings-calendars')));
}

Future<void> _back(WidgetTester t) async {
  await t.tapAndSettle(find.byType(BackButton).last, reason: 'flecha atrás');
}

/// Back to the month screen from wherever the test is.
Future<void> _home(WidgetTester t) async {
  for (var i = 0; i < 4 && find.byType(BackButton).evaluate().isNotEmpty; i++) {
    await _back(t);
  }
}

Future<void> _createCalendar(
  WidgetTester t,
  String name, {
  int colorIndex = 0,
}) async {
  await t.tapAndSettle(find.byKey(const ValueKey('calendars-add')));
  await t.enterText(find.byKey(const ValueKey('calendar-name-field')), name);
  await t.pump();
  await t.tapAndSettle(find.byKey(ValueKey('calendar-color-$colorIndex')));
  await t.tapAndSettle(find.byKey(const ValueKey('calendar-save')));
}

/// A second calendar called [name] with a vacation day today, stored before
/// the app starts.
Future<void> _prepareSecondCalendar(
  QaStorage storage, {
  String name = 'Pareja',
}) async {
  final calendars = CalendarsRepository(storage.database);
  final id = (await calendars.create(name: name, colorValue: 0xFF30A46C)).id;
  await storage.repository.apply(
    id,
    ScheduleChange(
      patch: EntriesPatch({
        qaToday: EntryChange(
          null,
          DayEntry(date: qaToday, shiftTypeIds: const ['vacation']),
        ),
      }),
    ),
  );
}

/// The calendar on screen, read from the top screen (the month screen is
/// hidden behind Settings, so [QaApp.scheduleState] cannot find it there).
String _calendarId(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(Scaffold).first))
        .read(scheduleControllerProvider)
        .calendarId;

Brightness _brightness(WidgetTester t) =>
    Theme.of(t.element(find.byType(Scaffold).first)).brightness;

Future<String?> _setting(QaApp app, String key) async {
  final rows = await app.query("SELECT value FROM settings WHERE key = '$key'");
  return rows.isEmpty ? null : rows.single['value'] as String;
}

Future<List<Map<String, Object?>>> _calendarDays(
  QaApp app,
  String calendarId,
) => app.query(
  'SELECT date, shift_type_ids, note FROM day_entries '
  "WHERE calendar_id = '$calendarId' ORDER BY date",
);

Future<List<Map<String, Object?>>> _calendars(QaApp app) => app.query(
  'SELECT id, name, color_value, archived FROM calendars ORDER BY sort_order',
);

Future<void> _pickFromChoiceSheet(
  WidgetTester t,
  String rowKey,
  String label,
) async {
  await t.tapAndSettle(find.byKey(ValueKey(rowKey)));
  await t.tapAndSettle(
    find.descendant(of: find.byType(BottomSheet), matching: find.text(label)),
  );
}

/// Weekdays of the header row, left to right.
List<int> _headerOrder(WidgetTester t) {
  final found = <MapEntry<double, int>>[
    for (var weekday = 1; weekday <= 7; weekday++)
      MapEntry(
        t.getCenter(find.byKey(ValueKey('weekday-$weekday'))).dx,
        weekday,
      ),
  ]..sort((a, b) => a.key.compareTo(b.key));
  return [for (final e in found) e.value];
}

// ---- Q40 -------------------------------------------------------------------

/// Q40.
const qaSettingsScreen = QaScenario(
  'Q40',
  'Ajustes: secciones y filas',
  _settingsScreen,
);

Future<void> _settingsScreen(QaContext qa) async {
  final t = qa.tester;
  await QaApp.open(qa);
  expect(_pill, findsNothing, reason: 'un solo calendario: sin selector');

  await _openSettings(t);
  qa.expectNoFlutterErrors('al abrir Ajustes');
  expect(find.text('Ajustes'), findsOneWidget);
  for (final heading in ['TU CUADRANTE', 'APARIENCIA']) {
    expect(find.text(heading), findsOneWidget, reason: heading);
  }
  for (final title in [
    'Mis turnos',
    'Calendarios',
    'Tema',
    'Primer día de la semana',
    'Mostrar número de semana',
  ]) {
    expect(find.text(title), findsOneWidget, reason: title);
  }
  await qa.shot('arriba');

  // The rest is reached by scrolling.
  await t.ensureVisible(find.byKey(const ValueKey('settings-about')));
  await t.settle();
  expect(find.text('Ayuda y contacto'), findsOneWidget);
  expect(find.text('Acerca de'), findsOneWidget);
  qa.expectNoFlutterErrors('Ajustes completo');
  await qa.shot('abajo');

  // About opens its sheet and the licences page.
  await t.tapAndSettle(find.byKey(const ValueKey('settings-about')));
  expect(find.textContaining('sin conexión y sin cuenta'), findsOneWidget);
  await t.tapAndSettle(find.byKey(const ValueKey('about-licenses')));
  expect(find.byType(LicensePage), findsOneWidget);
  await _back(t);
  await _back(t);
  expect(find.byType(MonthScreen), findsOneWidget);
}

// ---- Q41 -------------------------------------------------------------------

/// Q41.
const qaSecondCalendar = QaScenario(
  'Q41',
  'Crear un segundo calendario',
  _secondCalendar,
);

Future<void> _secondCalendar(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);

  await _openCalendars(t);
  expect(find.text('Mi cuadrante'), findsOneWidget);
  expect(find.text('Activo'), findsOneWidget);
  expect(find.text('Widget y alarmas'), findsOneWidget);

  await _createCalendar(t, 'Pareja', colorIndex: 5);
  expect(find.text('Pareja'), findsOneWidget);
  final calendars = await _calendars(app);
  expect(calendars.map((c) => c['name']), ['Mi cuadrante', 'Pareja']);
  await qa.shot('lista');

  // A third calendar is also offered.
  final add = t.widget<OutlinedButton>(
    find.descendant(
      of: find.byKey(const ValueKey('calendars-add')),
      matching: find.byType(OutlinedButton),
    ),
  );
  expect(add.onPressed, isNotNull, reason: 'se pueden crear más calendarios');

  await _home(t);
  expect(_pill, findsOneWidget, reason: 'con dos calendarios sale el selector');
  expect(
    find.descendant(of: _pill, matching: find.text('Mi cuadrante')),
    findsOneWidget,
  );
  await qa.shot('mes_con_selector');
}

// ---- Q42 -------------------------------------------------------------------

/// Q42.
const qaSwitchAndPaint = QaScenario(
  'Q42',
  'Cambiar de calendario, pintar en él y el principal intacto',
  _switchAndPaint,
);

Future<void> _switchAndPaint(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa, prepare: _prepareSecondCalendar);
  final mainBefore = await _calendarDays(app, 'main');
  expect(mainBefore, isNotEmpty);
  expect(inCell(_oct19, find.text('N')), findsOneWidget);
  expect(find.text('ESTA NOCHE'), findsOneWidget);

  await t.waitFor(_pill, reason: 'selector de calendario');
  await t.tapAndSettle(_pill);
  await qa.shot('hoja');
  final second = (await _calendars(app)).last['id']! as String;
  await t.tapAndSettle(find.byKey(ValueKey('switch-calendar-$second')));

  expect(_calendarId(t), second);
  expect(
    find.descendant(of: _pill, matching: find.text('Pareja')),
    findsOneWidget,
  );
  expect(inCell(_oct19, find.text('V')), findsOneWidget);
  expect(inCell(_oct19, find.text('N')), findsNothing);
  expect(find.text('ESTA NOCHE'), findsNothing);
  await qa.shot('pareja');

  // Paint in it.
  await enterPaintMode(t);
  await t.tapAndSettle(tool('afternoon'));
  await t.tapAndSettle(cell(_oct22));
  await t.dragAcross([cell(_oct21), cell(_oct22)]);
  await exitPaintMode(t);
  expect(inCell(_oct22, find.text('T')), findsOneWidget);
  await app.flushWrites();

  final secondDays = await _calendarDays(app, second);
  expect(
    secondDays.map((r) => r['date']),
    containsAll([_oct21.toIso(), _oct22.toIso(), _oct19.toIso()]),
  );
  expect(
    await _calendarDays(app, 'main'),
    mainBefore,
    reason: 'el calendario principal no se toca',
  );

  // Back on the main one: its own content, without the new paint.
  await t.waitFor(_pill, reason: 'selector de calendario');
  await t.tapAndSettle(_pill);
  await t.tapAndSettle(find.byKey(const ValueKey('switch-calendar-main')));
  expect(_calendarId(t), 'main');
  expect(inCell(_oct19, find.text('N')), findsOneWidget);
  expect(inCell(_oct22, find.text('T')), findsNothing);
  await qa.shot('principal');
}

// ---- Q43 -------------------------------------------------------------------

/// Q43.
const qaActiveCalendarPersists = QaScenario(
  'Q43',
  'El calendario que ves sobrevive a cerrar la app',
  _activeCalendarPersists,
);

Future<void> _activeCalendarPersists(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa, prepare: _prepareSecondCalendar);
  await t.waitFor(_pill, reason: 'selector de calendario');
  await t.tapAndSettle(_pill);
  final second = (await _calendars(app)).last['id']! as String;
  await t.tapAndSettle(find.byKey(ValueKey('switch-calendar-$second')));
  expect(await _setting(app, 'calendars.active'), '"$second"');

  await app.restart();
  expect(_calendarId(t), second);
  // The list of calendars loads after the month itself.
  await t.waitFor(
    find.descendant(of: _pill, matching: find.text('Pareja')),
    reason: 'selector con «Pareja» tras reabrir',
  );
  expect(
    find.descendant(of: _pill, matching: find.text('Pareja')),
    findsOneWidget,
  );
  expect(inCell(_oct19, find.text('V')), findsOneWidget);
  await qa.shot('reabierto');

  // The primary one (widget and alarms) did not move.
  expect(await _setting(app, 'calendars.primary'), isNull);
  await _openCalendars(t);
  expect(
    find.descendant(
      of: find.byKey(const ValueKey('calendar-row-main')),
      matching: find.text('Widget y alarmas'),
    ),
    findsOneWidget,
  );
}

// ---- Q44 -------------------------------------------------------------------

/// Q44.
const qaEditCalendar = QaScenario(
  'Q44',
  'Renombrar, cambiar el color y elegir el principal',
  _editCalendar,
);

Future<void> _editCalendar(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa, prepare: _prepareSecondCalendar);
  final second = (await _calendars(app)).last['id']! as String;
  await _openCalendars(t);

  await t.tapAndSettle(find.byKey(ValueKey('calendar-row-$second')));
  await t.enterText(
    find.byKey(const ValueKey('calendar-name-field')),
    'Mi pareja',
  );
  await t.pump();
  await t.tapAndSettle(find.byKey(const ValueKey('calendar-color-1')));
  await qa.shot('editor');
  await t.tapAndSettle(find.byKey(const ValueKey('calendar-save')));
  expect(find.text('Mi pareja'), findsOneWidget);
  final row = (await _calendars(app)).last;
  expect(row['name'], 'Mi pareja');
  expect(row['color_value'], isNot(0xFF30A46C));

  // Make it the one the widget and the alarms follow.
  await t.tapAndSettle(find.byKey(ValueKey('calendar-row-$second')));
  await t.tapAndSettle(find.byKey(const ValueKey('calendar-make-primary')));
  expect(await _setting(app, 'calendars.primary'), '"$second"');
  expect(
    find.descendant(
      of: find.byKey(ValueKey('calendar-row-$second')),
      matching: find.text('Widget y alarmas'),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byKey(const ValueKey('calendar-row-main')),
      matching: find.text('Widget y alarmas'),
    ),
    findsNothing,
  );
  // What is on screen stays `main`.
  expect(_calendarId(t), 'main');
  await qa.shot('principal_cambiado');
}

// ---- Q45 -------------------------------------------------------------------

/// Q45.
const qaArchiveCalendar = QaScenario(
  'Q45',
  'Archivar con confirmación; el último no se puede',
  _archiveCalendar,
);

Future<void> _archiveCalendar(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa, prepare: _prepareSecondCalendar);
  final second = (await _calendars(app)).last['id']! as String;
  await _openCalendars(t);

  // Cancel: nothing happens.
  await t.tapAndSettle(find.byKey(ValueKey('calendar-row-$second')));
  await t.tapAndSettle(find.byKey(const ValueKey('calendar-archive')));
  expect(find.text('¿Archivar «Pareja»?'), findsOneWidget);
  await qa.shot('confirmar');
  await t.tapAndSettle(find.byKey(const ValueKey('confirm-cancel')));
  expect((await _calendars(app)).every((c) => c['archived'] == 0), isTrue);

  // Confirm: archived, data kept.
  await t.tapAndSettle(find.byKey(const ValueKey('calendar-archive')));
  await t.tapAndSettle(find.byKey(const ValueKey('calendar-archive-confirm')));
  expect(find.text('Pareja'), findsNothing);
  expect((await _calendars(app)).last['archived'], 1);
  expect(await _calendarDays(app, second), isNotEmpty);

  // The last one is refused.
  await t.tapAndSettle(find.byKey(const ValueKey('calendar-row-main')));
  await t.tapAndSettle(find.byKey(const ValueKey('calendar-archive')));
  expect(
    find.text(
      'No puedes archivar el último calendario: siempre tiene que haber uno.',
    ),
    findsOneWidget,
  );
  expect((await _calendars(app)).first['archived'], 0);
  await qa.shot('ultimo');
  await t.tapAt(const Offset(10, 60));
  await t.settle();
  await _home(t);
  expect(_pill, findsNothing, reason: 'otra vez un solo calendario');
}

// ---- Q46 -------------------------------------------------------------------

/// Q46.
const qaThemeFromSettings = QaScenario(
  'Q46',
  'Tema oscuro desde Ajustes, también al reabrir',
  _themeFromSettings,
);

Future<void> _themeFromSettings(QaContext qa) async {
  final t = qa.tester;
  addTearDown(t.platformDispatcher.clearAllTestValues);
  t.platformDispatcher.platformBrightnessTestValue = Brightness.light;
  final app = await QaApp.open(qa);
  expect(_brightness(t), Brightness.light);

  await _openSettings(t);
  await _pickFromChoiceSheet(t, 'settings-theme', 'Oscuro');
  expect(_brightness(t), Brightness.dark, reason: 'el sistema sigue en claro');
  expect(await _setting(app, 'appearance.themeMode'), '"dark"');
  qa.expectNoFlutterErrors('tema oscuro');
  await qa.shot('ajustes_oscuro');

  await _home(t);
  await qa.shot('mes_oscuro');

  await app.restart();
  expect(_brightness(t), Brightness.dark, reason: 'persiste al reabrir');

  // The system choice names the phone's current brightness.
  await _openSettings(t);
  await _pickFromChoiceSheet(t, 'settings-theme', 'Sistema (claro)');
  expect(_brightness(t), Brightness.light);
  expect(await _setting(app, 'appearance.themeMode'), '"system"');
  t.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
  await t.settle();
  expect(_brightness(t), Brightness.dark, reason: 'sigue al sistema');
  expect(find.text('Sistema (oscuro)'), findsOneWidget);
  await _pickFromChoiceSheet(t, 'settings-theme', 'Claro');
  expect(_brightness(t), Brightness.light);
  expect(await _setting(app, 'appearance.themeMode'), '"light"');
}

// ---- Q47 -------------------------------------------------------------------

/// Q47.
const qaSundayStart = QaScenario(
  'Q47',
  'La semana empieza en domingo',
  _sundayStart,
);

Future<void> _sundayStart(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  expect(_headerOrder(t), [1, 2, 3, 4, 5, 6, 7]);
  final mondayLeft = t.getCenter(cell(_oct19)).dx;

  await _openSettings(t);
  await _pickFromChoiceSheet(t, 'settings-week-start', 'Domingo');
  expect(await _setting(app, 'calendar.weekStart'), '7');
  await _home(t);

  expect(_headerOrder(t), [7, 1, 2, 3, 4, 5, 6]);
  expect(allCells, findsNWidgets(42));
  expect(
    t.getCenter(cell(_oct18)).dx,
    lessThan(t.getCenter(cell(_oct19)).dx),
    reason: 'el domingo 18 abre la fila',
  );
  expect(t.getCenter(cell(_oct19)).dx, isNot(closeTo(mondayLeft, 1)));
  expect(inCell(_oct19, find.text('N')), findsOneWidget);
  await qa.shot('domingo');

  // Painting hits the date under the finger in the new layout.
  await enterPaintMode(t);
  await t.tapAndSettle(tool('afternoon'));
  await t.tapAndSettle(cell(_oct18));
  await t.dragAcross([cell(_oct21), cell(_oct22)]);
  await t.tapAndSettle(cell(_oct24));
  await exitPaintMode(t);
  await app.flushWrites();
  for (final day in [_oct18, _oct21, _oct22, _oct24]) {
    expect(idsOn(app.schedule, day), 'afternoon', reason: '$day');
  }
  expect(idsOn(app.schedule, _oct25), isNot('afternoon'));
  expect((await app.storedDay(_oct25)), isNull);
  expect((await app.storedDay(_oct18))?.shiftTypeIds, ['afternoon']);

  await app.restart();
  expect(_headerOrder(t), [7, 1, 2, 3, 4, 5, 6], reason: 'persiste');
  expect(inCell(_oct18, find.text('T')), findsOneWidget);
}

// ---- Q48 -------------------------------------------------------------------

/// Q48.
const qaWeekNumbers = QaScenario('Q48', 'Número de semana', _weekNumbers);

Future<void> _weekNumbers(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  expect(find.byKey(const ValueKey('week-2026-09-28')), findsNothing);

  await _openSettings(t);
  await t.tapAndSettle(find.byKey(const ValueKey('settings-week-numbers')));
  expect(await _setting(app, 'calendar.weekNumbers'), 'true');
  await _home(t);

  const weeks = {
    '2026-09-28': '40',
    '2026-10-05': '41',
    '2026-10-12': '42',
    '2026-10-19': '43',
    '2026-10-26': '44',
    '2026-11-02': '45',
  };
  weeks.forEach((iso, number) {
    expect(
      find.descendant(
        of: find.byKey(ValueKey('week-$iso')),
        matching: find.text(number),
      ),
      findsOneWidget,
      reason: 'semana de $iso',
    );
  });
  await qa.shot('lunes');

  // With Sunday first the rows keep the week of their Monday.
  await _openSettings(t);
  await _pickFromChoiceSheet(t, 'settings-week-start', 'Domingo');
  await _home(t);
  expect(
    find.descendant(
      of: find.byKey(const ValueKey('week-2026-10-18')),
      matching: find.text('43'),
    ),
    findsOneWidget,
  );

  // The column does not move the cells under the finger.
  await enterPaintMode(t);
  await t.tapAndSettle(tool('afternoon'));
  await t.tapAndSettle(cell(_oct18));
  await t.tapAndSettle(cell(_oct25));
  await exitPaintMode(t);
  await app.flushWrites();
  expect(idsOn(app.schedule, _oct18), 'afternoon');
  expect(idsOn(app.schedule, _oct25), 'afternoon');
  expect((await app.storedDay(const CivilDate(2026, 10, 17))), isNull);
  expect(
    (await app.storedDay(const CivilDate(2026, 10, 26)))?.shiftTypeIds,
    isNot(['afternoon']),
  );
  await qa.shot('domingo');
}

// ---- Q49 -------------------------------------------------------------------

/// Q49.
const qaSettingsLargeText = QaScenario(
  'Q49',
  'Ajustes y calendarios en oscuro con texto grande',
  _settingsLargeText,
);

Future<void> _settingsLargeText(QaContext qa) async {
  final t = qa.tester;
  addTearDown(t.platformDispatcher.clearAllTestValues);
  final app = await QaApp.open(qa, prepare: _prepareSecondCalendar);

  for (final scale in [1.3, 2.0]) {
    final tag = 'x${scale.toString().replaceAll('.', '')}';
    t.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    t.platformDispatcher.textScaleFactorTestValue = scale;
    await t.settle();
    qa.expectNoFlutterErrors('mes, $tag');

    // The pill stays in the date line and is cut, not overflowing.
    expect(_pill, findsOneWidget, reason: tag);
    await qa.shot('mes_$tag');

    await t.waitFor(_pill, reason: 'selector de calendario');
    await t.tapAndSettle(_pill);
    qa.expectNoFlutterErrors('selector, $tag');
    await qa.shot('selector_$tag');
    await t.tapAt(const Offset(20, 60));
    await t.settle();

    await _openSettings(t);
    qa.expectNoFlutterErrors('ajustes, $tag');
    await qa.shot('ajustes_$tag');
    await t.ensureVisible(find.byKey(const ValueKey('settings-about')));
    await t.settle();
    qa.expectNoFlutterErrors('ajustes abajo, $tag');

    await t.ensureVisible(find.byKey(const ValueKey('settings-calendars')));
    await t.tapAndSettle(find.byKey(const ValueKey('settings-calendars')));
    qa.expectNoFlutterErrors('calendarios, $tag');
    await qa.shot('calendarios_$tag');

    final second = (await _calendars(app)).last['id']! as String;
    await t.tapAndSettle(find.byKey(ValueKey('calendar-row-$second')));
    qa.expectNoFlutterErrors('editor, $tag');
    await qa.shot('editor_$tag');
    await t.tapAt(const Offset(20, 60));
    await t.settle();
    await _home(t);
  }
}
