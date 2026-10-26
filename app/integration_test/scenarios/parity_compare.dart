import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

// Comparar calendarios (docs/paridad.md A4), Q86 y Q87.
//
// Demo data around Monday 19 Oct 2026: "Mi cuadrante" works on 19 days of
// October (Noche 1, 2, 19, 20, 23; Mañana 5-9, 21, 26, 29, 30; Tarde 12-16
// and 21); the rest (Libre, Vacaciones 27-28 and the 22nd cleared) are free
// days. "Pareja" only has a vacation day on the 19th, so the days free in
// both are the 12 days "Mi cuadrante" is free.

const _oct19 = CivilDate(2026, 10, 19); // Noche | Vacaciones
const _oct21 = CivilDate(2026, 10, 21); // Mañana + Tarde | nothing
const _oct22 = CivilDate(2026, 10, 22); // cleared by hand | nothing
const _oct24 = CivilDate(2026, 10, 24); // Libre | nothing
const _oct27 = CivilDate(2026, 10, 27); // Vacaciones | nothing

/// Scenarios of this file, listed by `parity.dart`.
final List<QaScenario> compareScenarios = [
  qaCompareFreeDays, // Q86
  qaCompareChoose, // Q87
];

Finder _k(String key) => find.byKey(ValueKey(key));

String _text(WidgetTester t, String key) => t.widget<Text>(_k(key)).data!;

Finder _inBand(String band, CivilDate date, String code) => find.descendant(
  of: _k('compare-$band-${date.toIso()}'),
  matching: find.text(code),
);

/// "Pareja", with a vacation day today, stored before the app starts.
Future<void> _prepareCouple(QaStorage storage) async {
  final calendars = CalendarsRepository(storage.database);
  final id = (await calendars.create(
    name: 'Pareja',
    colorValue: 0xFF30A46C,
  )).id;
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

Future<void> _back(WidgetTester t) =>
    t.tapAndSettle(find.byType(BackButton).last, reason: 'flecha atrás');

// ---- Q86 -------------------------------------------------------------------

/// Q86.
const qaCompareFreeDays = QaScenario(
  'Q86',
  'Comparar calendarios: días libres en común del mes',
  _compareFreeDays,
);

Future<void> _compareFreeDays(QaContext qa) async {
  final t = qa.tester;
  await QaApp.open(qa, prepare: _prepareCouple);

  // Ajustes › Calendarios › Comparar calendarios.
  await t.tapAndSettle(find.byTooltip('Abrir ajustes'));
  await t.tapAndSettle(_k('settings-calendars'));
  await t.tapAndSettle(_k('calendars-compare'));
  expect(find.text('Comparar calendarios'), findsWidgets);
  expect(
    find.descendant(
      of: _k('compare-first'),
      matching: find.text('Mi cuadrante'),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(of: _k('compare-second'), matching: find.text('Pareja')),
    findsOneWidget,
  );
  expect(_text(t, 'compare-month'), 'Octubre 2026');
  await qa.shot('mes');

  // The shifts of both calendars in every day.
  expect(_inBand('a', _oct19, 'N'), findsOneWidget);
  expect(_inBand('b', _oct19, 'V'), findsOneWidget);
  expect(_inBand('a', _oct21, 'M+T'), findsOneWidget);
  expect(_inBand('b', _oct21, '–'), findsOneWidget);
  expect(_inBand('a', _oct24, 'L'), findsOneWidget);

  // Free in both: a Libre, a day cleared by hand and a vacation day. Busy:
  // the Noche of the 19th (the vacation of the other does not help).
  for (final date in [_oct22, _oct24, _oct27]) {
    expect(_k('compare-free-${date.toIso()}'), findsOneWidget, reason: '$date');
  }
  for (final date in [_oct19, _oct21]) {
    expect(_k('compare-free-${date.toIso()}'), findsNothing, reason: '$date');
  }

  // The count and the list of dates.
  await t.ensureVisible(_k('compare-summary'));
  await t.settle();
  expect(_text(t, 'compare-count'), '12 días libres en común este mes');
  expect(_k('compare-free-date-2026-10-22'), findsOneWidget);
  expect(_k('compare-free-date-2026-10-19'), findsNothing);
  expect(find.text('jue 22 oct'), findsOneWidget);
  await qa.shot('lista');
  qa.expectNoFlutterErrors('comparar');
  await _back(t);
  await _back(t);
  await _back(t);
}

// ---- Q87 -------------------------------------------------------------------

/// Q87.
const qaCompareChoose = QaScenario(
  'Q87',
  'Comparar: elegir los calendarios, cambiar de mes y no tocar nada',
  _compareChoose,
);

Future<void> _compareChoose(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(
    qa,
    prepare: (storage) async {
      await _prepareCouple(storage);
      await CalendarsRepository(storage.database)
          .create(name: 'Hijo', colorValue: 0xFF1C7ED6);
    },
  );
  final dump = await app.dumpSchedule();

  // From the calendar pill of the month screen.
  // The calendars are loaded from disk by an AsyncNotifier; settling frames
  // does not wait for that I/O. Keep checking the real selector and route.
  await t.waitFor(_k('calendar-switcher'));
  await t.tapAndSettle(_k('calendar-switcher'));
  await t.tapAndSettle(_k('calendar-switcher-compare'));
  expect(_text(t, 'compare-month'), 'Octubre 2026');

  // The second place takes "Hijo": it has no shifts, so every free day of
  // "Mi cuadrante" is free in both.
  await t.tapAndSettle(_k('compare-second'));
  await qa.shot('elegir');
  await t.tapAndSettle(
    find.descendant(of: find.byType(BottomSheet), matching: find.text('Hijo')),
  );
  expect(
    find.descendant(of: _k('compare-second'), matching: find.text('Hijo')),
    findsOneWidget,
  );
  await t.ensureVisible(_k('compare-summary'));
  expect(_text(t, 'compare-count'), '12 días libres en común este mes');

  // Choosing the one the other place has swaps them.
  await t.tapAndSettle(_k('compare-first'));
  await t.tapAndSettle(
    find.descendant(of: find.byType(BottomSheet), matching: find.text('Hijo')),
  );
  expect(
    find.descendant(of: _k('compare-first'), matching: find.text('Hijo')),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: _k('compare-second'),
      matching: find.text('Mi cuadrante'),
    ),
    findsOneWidget,
  );
  expect(_inBand('b', _oct19, 'N'), findsOneWidget);

  // The months: arrows and a swipe.
  await t.drag(find.byType(ListView).first, const Offset(0, 1500));
  await t.settle();
  await t.tapAndSettle(_k('compare-next'));
  expect(_text(t, 'compare-month'), 'Noviembre 2026');
  await t.tapAndSettle(_k('compare-previous'));
  await t.tapAndSettle(_k('compare-previous'));
  expect(_text(t, 'compare-month'), 'Septiembre 2026');
  await t.fling(
    _k('compare-grid'),
    const Offset(-400, 0),
    1500,
    warnIfMissed: false,
  );
  await t.settle();
  expect(_text(t, 'compare-month'), 'Octubre 2026');
  await qa.shot('mes_cambiado');

  // Read-only: the stored schedule is exactly as it was, and the calendar on
  // screen did not change.
  await app.flushWrites();
  expect(await app.dumpSchedule(), dump);
  expect(app.scheduleState.calendarId, 'main');
  expect(app.scheduleState.canUndo, isFalse);
  qa.expectNoFlutterErrors('comparar');
}
