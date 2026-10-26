import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

// Turno partido (docs/paridad.md A12), Q99.
//
// Demo data around Monday 19 Oct 2026: rotation Noche 19-23, Libre 24-25,
// Mañana 26-30. October has 20 shifts of 8 h = 160 h (see `summary.dart`).

const _oct24 = CivilDate(2026, 10, 24); // Libre by the rotation
const _oct25 = CivilDate(2026, 10, 25); // Libre by the rotation

/// Scenarios of this file, listed by `registry.dart`.
final List<QaScenario> paritySplitScenarios = [
  qaSplitShift, // Q99
];

Finder _k(String key) => find.byKey(ValueKey(key));

// The month screen is offstage once a route covers it: the container is found
// from the app itself.
ProviderContainer _container(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(MaterialApp)));

ScheduleState _state(WidgetTester t) =>
    _container(t).read(scheduleControllerProvider);

Future<void> _flush(WidgetTester t) => t.runAsync(
  () => _container(t).read(scheduleControllerProvider.notifier).pendingWrites,
);

Future<void> _type(WidgetTester t, String key, String text) async {
  await t.ensureVisible(_k(key));
  await t.pump();
  await t.enterText(_k(key), text);
  await t.pump();
}

/// Sets a time in the 24 h picker through its text entry mode.
Future<void> _setTime(
  WidgetTester t,
  String button,
  int hour,
  int minute,
) async {
  await t.ensureVisible(_k(button));
  await t.pump();
  await t.tapAndSettle(_k(button));
  await t.tapAndSettle(find.byIcon(Icons.keyboard_outlined));
  final fields = find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(TextField),
  );
  expect(fields, findsNWidgets(2), reason: 'horas y minutos');
  await t.enterText(fields.at(0), '$hour');
  await t.enterText(fields.at(1), '$minute');
  await t.tapAndSettle(
    find.byWidgetPredicate(
      (w) => w is Text && w.data?.toLowerCase() == 'aceptar',
    ),
  );
}

// ---- Q99 -------------------------------------------------------------------

/// Q99.
const qaSplitShift = QaScenario(
  'Q99',
  'Turno partido: crearlo, pintarlo, ver los dos tramos y las horas',
  _splitShift,
);

Future<void> _splitShift(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);

  // Mis turnos › Nuevo turno.
  await t.tapAndSettle(find.byTooltip('Abrir ajustes'));
  await t.tapAndSettle(_k('settings-shifts'), reason: 'Mis turnos');
  await t.tapAndSettle(_k('shift-new'));
  await _type(t, 'shift-name', 'Partido');
  await _setTime(t, 'shift-start', 9, 0);
  await _setTime(t, 'shift-end', 13, 0);

  // «Turno partido»: the second segment, first wrong, then right.
  await t.ensureVisible(_k('shift-split'));
  await t.pump();
  await t.tapAndSettle(_k('shift-split'));
  expect(_k('shift-start2'), findsOneWidget);
  await _setTime(t, 'shift-start2', 13, 0);
  expect(
    find.textContaining('sería un solo tramo'),
    findsOneWidget,
    reason: 'empieza justo cuando acaba el primero',
  );
  await t.ensureVisible(_k('shift-save'));
  await t.pump();
  final palette = _state(t).palette.length;
  await t.tapAndSettle(_k('shift-save'));
  expect(_k('shift-save'), findsOneWidget, reason: 'sigue en el formulario');
  expect(_state(t).palette.length, palette, reason: 'no se guarda');

  await _setTime(t, 'shift-start2', 17, 0);
  await _setTime(t, 'shift-end2', 21, 0);
  expect(_k('shift-split-error'), findsNothing);
  expect(find.text('Trabajas 4 h y 4 h: 8 h en total'), findsOneWidget);
  await qa.shot('formulario');
  await t.tapAndSettle(_k('shift-save'));

  expect(_k('shift-list'), findsOneWidget, reason: 'vuelve a la lista');
  final created = _state(t).palette.last;
  expect(created.name, 'Partido');
  await _flush(t);
  final rows = await app.query(
    'SELECT start_minute, end_minute, segment2_start_minute, '
    'segment2_duration_minutes FROM shift_types WHERE id = '
    "'${created.id}'",
  );
  expect(rows, hasLength(1));
  expect(rows.single['start_minute'], 9 * 60);
  expect(rows.single['end_minute'], 13 * 60);
  expect(rows.single['segment2_start_minute'], 17 * 60);
  expect(rows.single['segment2_duration_minutes'], 4 * 60);
  // The new type is the last one of a lazy list: bring its keyed row into
  // view, using this list's scrollable. Displayed ranges contain word joiners
  // to keep each range together; ignore only those layout characters.
  final createdRow = _k('shift-row-${created.id}');
  await t.scrollUntilVisible(
    createdRow,
    300,
    scrollable: find.descendant(
      of: _k('shift-list'),
      matching: find.byType(Scrollable),
    ),
  );
  expect(
    find.descendant(
      of: createdRow,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data
                    ?.replaceAll('\u2060', '')
                    .contains('09:00–13:00 · 17:00–21:00') ??
                false),
      ),
    ),
    findsOneWidget,
    reason: 'la fila enseña los dos tramos',
  );

  // Back to the month and paint the two Libre days.
  final router = _container(t).read(routerProvider);
  while (router.canPop()) {
    router.pop();
    await t.settle();
  }
  await enterPaintMode(t);
  await t.tapAndSettle(tool(created.id));
  await t.tapAndSettle(cell(_oct24));
  await t.tapAndSettle(cell(_oct25));
  await exitPaintMode(t);
  expect(idsOn(app.schedule, _oct24), created.id);
  expect(idsOn(app.schedule, _oct25), created.id);
  expect(inCell(_oct24, find.text('P')), findsOneWidget);
  await app.flushWrites();
  expect((await app.storedDay(_oct24))?.shiftTypeIds, [created.id]);
  expect((await app.storedDay(_oct25))?.shiftTypeIds, [created.id]);
  await qa.shot('pintado');

  // The day detail shows both ranges.
  await t.tapAndSettle(cell(_oct24));
  expect(find.byType(BottomSheet), findsOneWidget);
  expect(
    find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('09:00–13:00 · 17:00–21:00'),
    ),
    findsOneWidget,
  );
  await qa.shot('detalle');
  await t.binding.handlePopRoute();
  await t.settle();
  expect(find.byType(BottomSheet), findsNothing);

  // The summary counts both segments, not the gap: 160 h + 2 x 8 h.
  await t.tapAndSettle(_k('open-summary'), reason: 'Resumen del mes');
  expect(t.widget<Text>(_k('summary-hours')).data, '176 h');
  expect(t.widget<Text>(_k('summary-shifts-value')).data, '22');
  await qa.shot('resumen');
  qa.expectNoFlutterErrors('turno partido');
}
