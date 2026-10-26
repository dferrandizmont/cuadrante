import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/core/theme/shift_palette.dart';
import 'package:cuadrante/core/theme/shift_swatch.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

// Editor de tipos de turno (Ajustes > Mis turnos), Q20-Q23.
//
// Demo data around Monday 19 Oct 2026: Noche 19-23, Libre 24-25, Mañana
// 26-30. The palette starts as M, T, N, L, G, S, V, LD, D, N12 (the order of
// `shiftTemplates`).

const _oct24 = CivilDate(2026, 10, 24); // Libre by the rotation
const _oct30 = CivilDate(2026, 10, 30); // Mañana by the rotation

/// Scenarios Q20-Q23, registered in `registry.dart`.
final List<QaScenario> shiftTypesScenarios = [
  qaShiftTypesOrder,
  qaShiftTypesCreate,
  qaShiftTypesEdit,
  qaShiftTypesArchive,
];

Finder _k(String key) => find.byKey(ValueKey(key));

// The month screen is offstage once a route covers it: the container is found
// from the app itself.
ProviderContainer _container(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(MaterialApp)));

ScheduleState _state(WidgetTester t) =>
    _container(t).read(scheduleControllerProvider);

/// Waits for the writes of the editor (the month screen may be covered by a
/// route, so `QaApp.flushWrites` cannot find its container).
Future<void> _flush(WidgetTester t) => t.runAsync(
  () => _container(t).read(scheduleControllerProvider.notifier).pendingWrites,
);

List<String> _paletteIds(WidgetTester t) => [
  for (final s in _state(t).palette) s.id,
];

Future<void> _openList(QaContext qa) async {
  final t = qa.tester;
  await t.tapAndSettle(find.byTooltip('Abrir ajustes'));
  await t.tapAndSettle(_k('settings-shifts'), reason: 'Mis turnos');
  expect(_k('shift-list'), findsOneWidget);
}

/// Back to the month screen from the list (two routes up).
Future<void> _backToMonth(WidgetTester t) async {
  final router = _container(t).read(routerProvider);
  while (router.canPop()) {
    router.pop();
    await t.settle();
  }
  expect(
    find.text('Pintar').evaluate().isNotEmpty ||
        _k('paint-done').evaluate().isNotEmpty,
    isTrue,
    reason: 'de vuelta en el mes',
  );
}

Future<void> _type(WidgetTester t, String key, String text) async {
  await t.ensureVisible(_k(key));
  await t.pump();
  await t.enterText(_k(key), text);
  await t.pump();
}

Future<void> _tap(WidgetTester t, String key) => t.tapAndSettle(_k(key));

/// Sets a time in the 24 h picker through its text entry mode.
Future<void> _setTime(
  WidgetTester t,
  String button,
  int hour,
  int minute,
) async {
  await _tap(t, button);
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

Future<List<Map<String, Object?>>> _storedTypes(
  QaApp app, {
  String where = '1 = 1',
}) => app.query(
  'SELECT id, code, name, color_value, category, start_minute, end_minute, '
  'paid_minutes, night_override, hourly_rate_cents, sort_order, archived '
  'FROM shift_types WHERE $where ORDER BY sort_order, id',
);

/// Q20.
const qaShiftTypesOrder = QaScenario(
  'Q20',
  'Mis turnos: lista y orden de la paleta',
  _order,
);

Future<void> _order(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final original = _paletteIds(t);
  expect(original.length, greaterThanOrEqualTo(8));

  await _openList(qa);
  // The rows on screen are the palette, in order.
  final tops = [
    for (final id in original)
      if (_k('shift-row-$id').evaluate().isNotEmpty)
        t.getTopLeft(_k('shift-row-$id')).dy,
  ];
  expect(tops.length, greaterThan(5));
  expect(tops, orderedEquals([...tops]..sort()));
  await qa.shot('lista');

  // Drag the first shift two places down.
  final gesture = await t.startGesture(
    t.getCenter(_k('shift-handle-${original.first}')),
  );
  await t.pump();
  for (var i = 0; i < 14; i++) {
    await gesture.moveBy(const Offset(0, 14));
    await t.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await t.settle();

  final reordered = _paletteIds(t);
  expect(reordered, isNot(original));
  expect(reordered.toSet(), original.toSet());
  expect(reordered.indexOf(original.first), greaterThan(0));
  await _flush(t);
  final stored = await _storedTypes(app, where: 'archived = 0');
  expect([for (final r in stored) r['id']], reordered, reason: 'sort_order');
  await qa.shot('reordenada');

  // The paint palette follows in reading order, wrapping onto more rows as
  // needed. Check both the rendered tools and their positions, not just the
  // controller's palette (x alone is not ordered once a new row starts).
  await _backToMonth(t);
  await enterPaintMode(t);
  final wrap = t.widget<Wrap>(_k('paint-tools-wrap'));
  expect(
    [for (final child in wrap.children) child.key],
    [
      const ValueKey('tool-eraser'),
      for (final id in reordered) ValueKey('tool-$id'),
      const ValueKey('tool-edit-types'),
    ],
    reason: 'todas las fichas en el nuevo orden del Wrap',
  );
  final positions = [for (final id in reordered) t.getTopLeft(tool(id))];
  for (var i = 1; i < positions.length; i++) {
    final previous = positions[i - 1];
    final current = positions[i];
    if ((current.dy - previous.dy).abs() < 0.5) {
      expect(
        current.dx,
        greaterThan(previous.dx),
        reason: '${reordered[i]} después de ${reordered[i - 1]} en su fila',
      );
    } else {
      expect(
        current.dy,
        greaterThan(previous.dy),
        reason: '${reordered[i]} en la siguiente fila de la paleta',
      );
    }
  }
  await exitPaintMode(t);

  // And so does the next start.
  await app.restart();
  expect(_paletteIds(t), reordered);
}

/// Q21.
const qaShiftTypesCreate = QaScenario(
  'Q21',
  'Mis turnos: crear un turno con horario y precio por hora',
  _create,
);

Future<void> _create(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final count = _paletteIds(t).length;

  await _openList(qa);
  await t.tapAndSettle(_k('shift-new'));

  // Empty form: Spanish messages, nothing saved.
  await _tap(t, 'shift-save');
  expect(find.text('Pon un nombre al turno'), findsOneWidget);
  expect(find.text('Escribe un código de 1 a 3 caracteres'), findsOneWidget);
  expect(_paletteIds(t).length, count);

  // The code follows the name; a taken code is refused.
  await _type(t, 'shift-name', 'Refuerzo');
  expect(t.widget<TextField>(_k('shift-code')).controller?.text, 'R');
  await _type(t, 'shift-code', 'm');
  await _tap(t, 'shift-save');
  expect(find.text('Este código ya lo usa «Mañana»'), findsOneWidget);
  await _type(t, 'shift-code', 'RF');

  // A colour of the grid, the times, an unpaid break and the hourly rate.
  const pink = 0xFFD6336C;
  await _tap(t, 'shift-color-${pink.toRadixString(16)}');
  await _setTime(t, 'shift-start', 7, 30);
  await _setTime(t, 'shift-end', 15, 30);
  expect(find.text('Empieza 07:30'), findsOneWidget);
  expect(find.text('Termina 15:30'), findsOneWidget);
  expect(find.text('Dura 8 h'), findsOneWidget);
  await _type(t, 'shift-break', '30');
  expect(find.text('Se pagan 7 h 30 min'), findsOneWidget);
  await _type(t, 'shift-rate', '12,50');
  await qa.shot('formulario');
  await _tap(t, 'shift-save');

  expect(_k('shift-list'), findsOneWidget, reason: 'vuelve a la lista');
  final created = _state(t).palette.last;
  expect(created.name, 'Refuerzo');
  expect(_paletteIds(t).length, count + 1);
  await _flush(t);
  final rows = await _storedTypes(app, where: "name = 'Refuerzo'");
  expect(rows, hasLength(1));
  final row = rows.single;
  expect(row['code'], 'RF');
  expect(row['color_value'], pink);
  expect(row['start_minute'], 7 * 60 + 30);
  expect(row['end_minute'], 15 * 60 + 30);
  expect(row['paid_minutes'], 450);
  expect(row['hourly_rate_cents'], 1250, reason: '12,50 € = 1250 céntimos');
  expect(row['archived'], 0);

  // It can be painted right away.
  await _backToMonth(t);
  await enterPaintMode(t);
  await t.tapAndSettle(tool(created.id));
  await t.tapAndSettle(cell(_oct30));
  expect(inCell(_oct30, find.text('RF')), findsOneWidget);
  await exitPaintMode(t);
  await _flush(t);
  expect((await app.storedDay(_oct30))?.shiftTypeIds, [created.id]);
  await qa.shot('pintado');

  await app.restart();
  expect(_state(t).palette.last.name, 'Refuerzo');
  expect(inCell(_oct30, find.text('RF')), findsOneWidget);
}

/// Q22.
const qaShiftTypesEdit = QaScenario(
  'Q22',
  'Mis turnos: editar color, vista previa claro/oscuro y turno de 24 h',
  _edit,
  // 24 colours, each with a settle: slow on the emulator.
  timeout: Duration(minutes: 6),
);

Future<void> _edit(QaContext qa) async {
  final t = qa.tester;
  addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
  final app = await QaApp.open(qa);

  await _openList(qa);
  await t.tapAndSettle(_k('shift-row-night'));
  expect(t.widget<TextField>(_k('shift-name')).controller?.text, 'Noche');
  expect(find.text('Termina al día siguiente · dura 8 h'), findsOneWidget);

  // The preview shows the cell in both themes, with a legible contrast, for
  // every colour of the grid.
  for (final color in ShiftPalette.editorChoices) {
    final value = color.toARGB32();
    await _tap(t, 'shift-color-${value.toRadixString(16)}');
    for (final (key, brightness) in [
      ('preview-light', Brightness.light),
      ('preview-dark', Brightness.dark),
    ]) {
      final shown = find.descendant(
        of: _k(key),
        matching: find.textContaining('Contraste '),
      );
      expect(shown, findsOneWidget);
      final text = t.widget<Text>(shown).data!;
      final ratio = double.parse(
        text
            .replaceFirst('Contraste ', '')
            .replaceFirst(':1', '')
            .replaceAll(',', '.'),
      );
      expect(
        ratio,
        greaterThanOrEqualTo(kTextContrast),
        reason: '${value.toRadixString(16)} ${brightness.name}: $text',
      );
    }
  }
  const violet = 0xFF7950F2;
  await _tap(t, 'shift-color-${violet.toRadixString(16)}');
  await qa.shot('vista_previa_claro');
  t.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
  await t.settle();
  await qa.shot('vista_previa_oscuro');
  // Keep the harness's Spanish locale override: clearing every platform
  // value here changes the native Material picker labels on an English phone.
  t.platformDispatcher.clearPlatformBrightnessTestValue();
  await t.settle();

  // 08:00-08:00 is a 24 h shift; 22:00-06:00 ends the next day.
  await _setTime(t, 'shift-start', 8, 0);
  await _setTime(t, 'shift-end', 8, 0);
  expect(
    find.text('Dura 24 h: termina al día siguiente a la misma hora'),
    findsOneWidget,
  );
  await _setTime(t, 'shift-start', 22, 0);
  await _setTime(t, 'shift-end', 6, 0);
  expect(find.text('Termina al día siguiente · dura 8 h'), findsOneWidget);
  await _setTime(t, 'shift-start', 8, 0);
  await _setTime(t, 'shift-end', 8, 0);
  await _type(t, 'shift-name', 'Noche larga');
  await _tap(t, 'shift-save');

  await _flush(t);
  final row = (await _storedTypes(app, where: "id = 'night'")).single;
  expect(row['name'], 'Noche larga');
  expect(row['color_value'], violet);
  expect(row['start_minute'], 480);
  expect(row['end_minute'], 480);

  // The days that use it follow at once: 19 Oct is a "Noche".
  await _backToMonth(t);
  final today = app.schedule.resolve(qaToday).shifts.single;
  expect(today.name, 'Noche larga');
  expect(today.durationMinutes, 1440);
  expect(inCell(qaToday, find.text('N')), findsOneWidget);
  await qa.shot('mes');
}

/// Q23.
const qaShiftTypesArchive = QaScenario(
  'Q23',
  'Mis turnos: archivar sin perder los días ni el deshacer',
  _archive,
);

Future<void> _archive(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);

  // Paint something first: it must still be undoable after the editor.
  await enterPaintMode(t);
  await t.tapAndSettle(tool('afternoon'));
  await t.tapAndSettle(cell(_oct30));
  expect(inCell(_oct30, find.text('T')), findsOneWidget);
  await t.tapAndSettle(_k('tool-edit-types'));
  expect(
    _k('shift-list'),
    findsOneWidget,
    reason: '«Editar turnos» abre la lista',
  );

  // Asks first; cancelling changes nothing.
  await t.tapAndSettle(_k('shift-archive-rest'));
  expect(find.text('¿Archivar «Libre»?'), findsOneWidget);
  await qa.shot('confirmar');
  await t.tapAndSettle(_k('confirm-cancel'));
  expect(_k('shift-row-rest'), findsOneWidget);

  await t.tapAndSettle(_k('shift-archive-rest'));
  await t.tapAndSettle(_k('confirm-ok'));
  expect(_k('shift-row-rest'), findsNothing);
  await _flush(t);
  expect((await _storedTypes(app, where: "id = 'rest'")).single['archived'], 1);

  // Out of the palette, still on the days that used it.
  await _backToMonth(t);
  expect(tool('rest'), findsNothing);
  expect(tool('morning'), findsOneWidget);
  expect(inCell(_oct24, find.text('L')), findsOneWidget);

  // The painting made before the editor is still one undo away.
  expect(_state(t).canUndo, isTrue);
  await t.tapAndSettle(find.byKey(const ValueKey('undo')));
  expect(inCell(_oct30, find.text('T')), findsNothing);
  expect(inCell(_oct30, find.text('M')), findsOneWidget);
  await exitPaintMode(t);

  await app.restart();
  expect(inCell(_oct24, find.text('L')), findsOneWidget);
  await enterPaintMode(t);
  expect(tool('rest'), findsNothing);
}
