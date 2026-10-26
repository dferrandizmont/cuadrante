import 'package:cuadrante/features/calendar/application/visible_month.dart';
import 'package:cuadrante/features/patterns/application/post_night_provider.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/year/application/year_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

// Demo rotation (correturnos, 21-day cycle) around Monday 19 Oct 2026:
//   19-23 Noche, 24-25 Libre, 26-30 Mañana, 31 Oct-1 Nov Libre, 2-6 Tarde...
// Demo overrides: 20 note only, 21 Mañana+Tarde, 22 empty, 27-28 Vacaciones.
const _oct21 = CivilDate(2026, 10, 21);
const _oct24 = CivilDate(2026, 10, 24);
const _oct26 = CivilDate(2026, 10, 26);

/// The pattern wizard, "aplicar patrón desde este día", the automatic
/// saliente and the annual view (roadmap 0.3.0). Registered by
/// `registry.dart`, which this file does not edit.
final List<QaScenario> patternScenarios = [
  qaPaintMonthWithPreset, // Q30
  qaPatternPreview, // Q31
  qaPatternUndo, // Q32
  qaOwnSequence, // Q33
  qaPatternFromDay, // Q34
  qaPatternOverrides, // Q35
  qaPostNightAuto, // Q36
  qaNewPresets, // Q37
  qaYearView, // Q38
  qaYearShare, // Q39
];

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _longPress(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder);
  await t.pump(const Duration(milliseconds: 100));
  await t.longPress(finder);
  await t.settle();
}

/// The "Patrón aplicado" snack bar floats over the undo / redo buttons for a
/// few seconds: let it go, as a user would.
Future<void> _snackBarGone(WidgetTester t) async {
  await t.pump(const Duration(seconds: 5));
  await t.settle();
}

/// Paint mode, the "Patrón" button and a preset card, up to step 2.
Future<void> _openWizardOn(WidgetTester t, String presetId) async {
  await enterPaintMode(t);
  await t.tapAndSettle(_key('paint-pattern'), reason: 'botón Patrón');
  expect(find.text('Aplicar patrón'), findsOneWidget);
  await t.tapAndSettle(_key('pattern-card-$presetId'));
  await t.tapAndSettle(_key('pattern-next'));
}

/// Q30.
const qaPaintMonthWithPreset = QaScenario(
  'Q30',
  'Pintar un mes en menos de 30 s con un preset',
  _paintMonth,
);

Future<void> _paintMonth(QaContext qa) async {
  final t = qa.tester;
  // An empty calendar: the month to paint is blank.
  final app = await QaApp.open(qa, demo: false);
  expect(app.schedule.runs, isEmpty);
  expect(idsOn(app.schedule, qaToday), '');

  final watch = Stopwatch()..start();
  var taps = 0;
  Future<void> tap(Finder f) async {
    taps++;
    await t.tapAndSettle(f);
  }

  await tap(find.text('Pintar'));
  await tap(_key('paint-pattern'));
  await tap(_key('pattern-card-correturnos'));
  await tap(_key('pattern-next')); // step 2: today, first day of the cycle
  await tap(_key('pattern-next')); // step 3: no end, respect my days
  await tap(_key('pattern-apply'));
  watch.stop();

  qa.metric('pintar_mes_ms', watch.elapsedMilliseconds);
  qa.metric('pintar_mes_toques', taps);
  expect(find.text('Patrón aplicado'), findsOneWidget);

  // The month on screen is full: a shift on every one of its days.
  await app.flushWrites();
  final november = app.resolved(const CivilDate(2026, 11, 1), 30);
  expect(november.where((d) => d.endsWith('||')), isEmpty);
  expect(idsOn(app.schedule, qaToday), 'morning', reason: 'día 1 del ciclo');
  expect(
    watch.elapsedMilliseconds,
    lessThan(30000),
    reason: 'objetivo de la especificación: un mes en menos de 30 s',
  );
  await qa.shot('mes_pintado');
}

/// Q31.
const qaPatternPreview = QaScenario(
  'Q31',
  'Asistente: la vista previa es lo que se aplica',
  _preview,
);

Future<void> _preview(QaContext qa) async {
  final t = qa.tester;
  // No hand-made days, so the cells are only what the pattern says.
  final app = await QaApp.open(qa, demo: false);

  await _openWizardOn(t, '24x72');
  await t.tapAndSettle(_key('pattern-start-date'));
  await t.tap(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.text('26'),
    ),
  );
  await t.settle();
  await t.tap(
    find
        .descendant(
          of: find.byType(DatePickerDialog),
          matching: find.byType(TextButton),
        )
        .last,
  );
  await t.settle();
  await t.tapAndSettle(_key('offset-1'));
  expect(find.text('Ese día te toca: Libre'), findsOneWidget);

  // What the preview draws, cell by cell, for the 12 days from the start.
  Future<List<String>> previewCodes() async {
    final out = <String>[];
    for (var i = 0; i < 12; i++) {
      final date = _oct26.addDays(i);
      final cell = _key('preview-${date.toIso()}');
      await t.ensureVisible(cell);
      out.add(
        find
            .descendant(of: cell, matching: find.byType(Text))
            .evaluate()
            .map((e) => (e.widget as Text).data!)
            .where((s) => int.tryParse(s) == null && !s.contains('–'))
            .join('+'),
      );
    }
    return out;
  }

  final previewed = await previewCodes();
  qa.note('Vista previa: ${previewed.join(' ')}');
  expect(previewed.take(3), ['L', 'L', 'L']);
  expect(previewed[3], 'G');

  await t.tapAndSettle(_key('pattern-next'));
  await t.tapAndSettle(_key('pattern-apply'));
  await app.flushWrites();

  // After applying, the same days read the same in the month and the engine.
  final applied = [
    for (var i = 0; i < 12; i++)
      app.schedule
          .resolve(_oct26.addDays(i))
          .shifts
          .map((s) => s.code)
          .join('+'),
  ];
  expect(applied, previewed, reason: 'la vista previa = el resultado');
  await qa.shot('aplicado');
}

/// Q32.
const qaPatternUndo = QaScenario(
  'Q32',
  'Asistente: un solo deshacer devuelve las rotaciones exactas',
  _patternUndo,
);

Future<void> _patternUndo(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final original = await app.dumpSchedule();
  final runsBefore = app.schedule.runs;

  await _openWizardOn(t, '6x4');
  await t.tapAndSettle(_key('pattern-next'));
  await t.tapAndSettle(_key('pattern-apply'));
  await app.flushWrites();
  expect(app.schedule.runs.length, runsBefore.length + 1);
  expect(await app.dumpSchedule(), isNot(original));
  await _snackBarGone(t);
  final seqs = (await app.query('SELECT seq FROM pattern_runs ORDER BY seq'))
      .map((r) => r['seq'])
      .toList();
  expect(seqs.toSet().length, seqs.length, reason: 'seq únicos');

  await t.tapAndSettle(_key('undo'));
  expect(app.schedule.runs, runsBefore);
  expect(app.scheduleState.canUndo, isFalse, reason: 'un solo paso');
  await app.flushWrites();
  expect(await app.dumpSchedule(), original, reason: 'BD tras deshacer');

  // And "Rehacer" applies it again, identical.
  await t.tapAndSettle(_key('redo'));
  await app.flushWrites();
  expect(app.schedule.runs.length, runsBefore.length + 1);
  await qa.shot('rehecho');
}

/// Q33.
const qaOwnSequence = QaScenario(
  'Q33',
  'Secuencia propia: se crea, se guarda y sigue tras reiniciar',
  _ownSequence,
);

Future<void> _ownSequence(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa, demo: false);

  await enterPaintMode(t);
  await t.tapAndSettle(_key('paint-pattern'));
  await t.tapAndSettle(_key('pattern-create-own'));
  await t.tapAndSettle(_key('builder-add-morning'));
  await t.tapAndSettle(_key('builder-add-morning'));
  await t.tapAndSettle(_key('builder-add-night'));
  // Two shifts on the last day.
  await t.tapAndSettle(_key('builder-same-day'));
  await t.tapAndSettle(_key('builder-add-afternoon'));
  await t.tapAndSettle(_key('builder-same-day'));
  await t.tapAndSettle(_key('builder-add-rest'));
  expect(find.text('4 días'), findsOneWidget);
  await t.enterText(_key('builder-name'), 'Mi cuadrante');
  await t.settle();
  await qa.shot('constructor');

  await t.tapAndSettle(_key('pattern-next'));
  await t.tapAndSettle(_key('pattern-next'));
  await t.tapAndSettle(_key('pattern-apply'));
  await app.flushWrites();

  final stored = await app.query(
    "SELECT id, name, steps FROM patterns WHERE name = 'Mi cuadrante'",
  );
  expect(stored, hasLength(1), reason: 'guardado en la tabla patterns');
  expect(stored.single['id'] as String, startsWith('custom-'));
  expect(idsOn(app.schedule, qaToday), 'morning');
  expect(idsOn(app.schedule, qaToday.addDays(2)), 'night+afternoon');

  // After a restart the pattern and its run are still there, and the
  // wizard lists it (first, as it starts with the Mañana of the brush).
  await app.restart();
  expect(idsOn(app.schedule, qaToday.addDays(2)), 'night+afternoon');
  await enterPaintMode(t);
  await t.tapAndSettle(_key('paint-pattern'));
  final card = _key('pattern-card-${stored.single['id']}');
  await t.ensureVisible(card);
  expect(find.text('Mi cuadrante'), findsOneWidget);
}

/// Q34.
const qaPatternFromDay = QaScenario(
  'Q34',
  'Aplicar patrón desde este día (pulsación larga en una ficha)',
  _fromDay,
);

Future<void> _fromDay(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final before = await app.dumpSchedule();

  await enterPaintMode(t);
  await _longPress(t, tool('guard24'));
  expect(_key('pattern-pick-banner'), findsOneWidget);
  await qa.shot('elige_dia');
  await t.tapAndSettle(cell(_oct24));

  expect(find.text('Aplicar patrón'), findsOneWidget);
  expect(find.text('Desde el sábado 24 de octubre'), findsOneWidget);
  expect(find.text('EMPIEZAN POR GUARDIA 24 H'), findsOneWidget);
  // (The month screen is under the wizard: read the database directly.)
  expect(await app.dumpSchedule(), before, reason: 'el toque no pinta');

  await t.tapAndSettle(_key('pattern-card-24x72'));
  await t.tapAndSettle(_key('pattern-next'));
  expect(find.text('Sábado 24 de octubre 2026'), findsOneWidget);
  await t.tapAndSettle(_key('pattern-next'));
  await t.tapAndSettle(_key('pattern-apply'));

  expect(idsOn(app.schedule, _oct24), 'guard24');
  expect(idsOn(app.schedule, _oct24.addDays(1)), 'rest');
  expect(idsOn(app.schedule, _oct24.addDays(8)), 'guard24');
  expect(_key('pattern-pick-banner'), findsNothing);
  await qa.shot('desde_el_24');
}

/// Q35.
const qaPatternOverrides = QaScenario(
  'Q35',
  'Asistente: respetar o sustituir los días cambiados a mano',
  _overrides,
);

Future<void> _overrides(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  expect(idsOn(app.schedule, _oct21), 'morning+afternoon');

  // Respect (the default): the double shift stays.
  await _openWizardOn(t, '5x2');
  await t.tapAndSettle(_key('pattern-next'));
  await t.tapAndSettle(_key('pattern-apply'));
  expect(idsOn(app.schedule, _oct21), 'morning+afternoon');
  await _snackBarGone(t);
  await t.tapAndSettle(_key('undo'));

  // Replace: the pattern wins over what I changed by hand.
  await t.tapAndSettle(_key('paint-pattern'));
  await t.tapAndSettle(_key('pattern-card-5x2'));
  await t.tapAndSettle(_key('pattern-next'));
  await t.tapAndSettle(_key('pattern-next'));
  await t.tapAndSettle(_key('pattern-replace-overrides'));
  await t.tapAndSettle(_key('pattern-apply'));
  expect(idsOn(app.schedule, _oct21), 'morning');
  expect(app.schedule.entries[_oct21], isNull);
  await app.flushWrites();
  expect(await app.storedDay(_oct21), isNull);
  await _snackBarGone(t);

  // Undo gives my change back, in the screen and in the database.
  await t.tapAndSettle(_key('undo'));
  expect(idsOn(app.schedule, _oct21), 'morning+afternoon');
  await app.flushWrites();
  expect((await app.storedDay(_oct21))?.shiftTypeIds, ['morning', 'afternoon']);
}

/// Q36.
const qaPostNightAuto = QaScenario(
  'Q36',
  'Saliente automático tras una noche',
  _postNight,
);

Future<void> _postNight(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  const june10 = CivilDate(2026, 6, 10); // before the rotation: empty
  expect(idsOn(app.schedule, june10), '');

  Future<void> goToJune() async {
    for (var i = 0; i < 4; i++) {
      await tapMonthArrow(t, next: false);
    }
  }

  // Off by default: a night leaves the next day alone.
  await goToJune();
  await enterPaintMode(t);
  await t.tapAndSettle(tool('night'));
  await t.tapAndSettle(cell(june10));
  expect(idsOn(app.schedule, june10), 'night');
  expect(idsOn(app.schedule, june10.addDays(1)), '');
  await t.tapAndSettle(_key('undo'));

  // On: the empty next day becomes Saliente, in the same undo step.
  await t.runAsync(
    () => app.container.read(postNightAutoProvider.notifier).set(true),
  );
  await t.tapAndSettle(cell(june10));
  expect(idsOn(app.schedule, june10.addDays(1)), 'postNight');
  expect(inCell(june10.addDays(1), find.text('S')), findsOneWidget);
  await app.flushWrites();
  expect((await app.storedDay(june10.addDays(1)))?.shiftTypeIds, ['postNight']);
  await qa.shot('saliente');
  await t.tapAndSettle(_key('undo'));
  expect(idsOn(app.schedule, june10), '');
  expect(idsOn(app.schedule, june10.addDays(1)), '');
  expect(
    app.scheduleState.canUndo,
    isFalse,
    reason: 'noche + saliente = 1 paso',
  );
  await app.flushWrites();
  expect(await app.storedDay(june10.addDays(1)), isNull);

  // The setting survives a restart.
  await app.restart();
  expect(app.container.read(postNightAutoProvider), isTrue);
}

/// Q37.
const qaNewPresets = QaScenario(
  'Q37',
  'Presets Continental y DuPont (con los turnos de 12 h borrados)',
  _newPresets,
  timeout: Duration(minutes: 4),
);

Future<void> _newPresets(QaContext qa) async {
  final t = qa.tester;
  // The user once deleted the 12 h types and the DuPont pattern.
  final app = await QaApp.open(
    qa,
    demo: false,
    prepare: (storage) async {
      await storage.database.customStatement(
        "DELETE FROM shift_types WHERE id IN ('day12', 'night12')",
      );
      await storage.database.customStatement(
        "DELETE FROM patterns WHERE id = 'dupont'",
      );
    },
  );
  expect(app.schedule.shiftTypeById('night12'), isNull);

  await _openWizardOn(t, 'dupont');
  await t.tapAndSettle(_key('pattern-next'));
  await t.tapAndSettle(_key('pattern-apply'));
  await app.flushWrites();

  // 4 nights, 3 off, 3 days, 1 off, 3 nights, 3 off, 4 days, 7 off.
  final codes = [
    for (var i = 0; i < 28; i++)
      app.schedule.resolve(qaToday.addDays(i)).shifts.map((s) => s.code).join(),
  ].join(' ');
  expect(
    codes,
    'N12 N12 N12 N12 L L L D D D L N12 N12 N12 L L L D D D D '
    'L L L L L L L',
  );
  final types = await app.query(
    "SELECT id FROM shift_types WHERE id IN ('day12', 'night12')",
  );
  expect(types, hasLength(2), reason: 'los tipos de 12 h se han creado');
  expect(
    await app.query("SELECT id FROM patterns WHERE id = 'dupont'"),
    hasLength(1),
  );
  await _snackBarGone(t);
  await t.tapAndSettle(_key('undo'));

  // Continental: 28 days, 7 mornings, 7 afternoons, 7 nights, 7 off.
  await t.tapAndSettle(_key('paint-pattern'));
  await t.tapAndSettle(_key('pattern-card-continental'));
  await t.tapAndSettle(_key('pattern-next'));
  await t.tapAndSettle(_key('pattern-next'));
  await t.tapAndSettle(_key('pattern-apply'));
  final cycle = app.schedule.resolveRange(qaToday, qaToday.addDays(27));
  int count(String id) => cycle.where((d) => d.shiftIds.single == id).length;
  expect(count('morning'), 7);
  expect(count('afternoon'), 7);
  expect(count('night'), 7);
  expect(count('rest'), 7);
  expect(
    app.schedule.resolve(qaToday.addDays(28)).shiftIds,
    app.schedule.resolve(qaToday).shiftIds,
    reason: 'el ciclo se repite',
  );
  await qa.shot('continental');
}

/// Q38.
const qaYearView = QaScenario(
  'Q38',
  'Vista anual: 12 meses, colores, leyenda y navegación',
  _yearView,
);

Future<void> _yearView(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  // The month screen is under the annual view: read what is needed now.
  final schedule = app.schedule;

  await t.tapAndSettle(_key('month-title'));
  expect(find.text('Vista anual'), findsOneWidget);
  for (var m = 1; m <= 12; m++) {
    expect(_key('year-month-$m'), findsOneWidget, reason: 'mes $m');
  }
  expect(find.text('2026'), findsOneWidget);

  // Heat map: 19 Oct is a Noche, 24 Oct a Libre, 22 Oct has no shift.
  Color fill(CivilDate d) {
    final w = t.widget(_key('year-day-${d.toIso()}'));
    if (w is ColoredBox) return w.color;
    return (((w as Row).children.first as Expanded).child as ColoredBox).color;
  }

  await t.ensureVisible(_key('year-day-2026-10-19'));
  final night = fill(qaToday);
  final libre = fill(_oct24);
  final empty = fill(const CivilDate(2026, 10, 22));
  expect({night, libre, empty}.length, 3, reason: 'tres colores distintos');
  expect(fill(const CivilDate(2026, 10, 20)), night);

  // The legend counts the days of each shift of the year.
  await t.scrollUntilVisible(
    _key('year-legend-night'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  final nights = schedule
      .resolveRange(const CivilDate(2026, 1, 1), const CivilDate(2026, 12, 31))
      .expand((d) => d.shifts)
      .where((s) => s.id == 'night')
      .length;
  expect(
    find.descendant(
      of: _key('year-legend-night'),
      matching: find.text('$nights días'),
    ),
    findsOneWidget,
  );
  await qa.shot('anual');

  // Year arrows, then a month opens in the month screen.
  await t.tapAndSettle(_key('year-next'));
  expect(find.text('2027'), findsOneWidget);
  await t.tapAndSettle(_key('year-month-3'));
  expect(find.text('Marzo 2027'), findsOneWidget);
  expect(app.container.read(visibleMonthProvider), const CivilDate(2027, 3, 1));
}

/// Q39.
const qaYearShare = QaScenario(
  'Q39',
  'Vista anual: compartir como imagen',
  _yearShare,
);

Future<void> _yearShare(QaContext qa) async {
  final t = qa.tester;
  final shared = <Uint8List>[];
  final names = <String>[];
  await QaApp.open(
    qa,
    overrides: [
      yearImageSharerProvider.overrideWithValue((png, name, subject) async {
        shared.add(png);
        names.add(name);
      }),
    ],
  );
  await t.tapAndSettle(_key('open-year'));
  await t.tap(_key('year-share'));
  // Rendering the image takes REAL time, in two native hops (`toImage`, then
  // `toByteData`), and each continuation only runs when the test pumps the
  // fake-async zone again: one wait is not enough on a device. Alternate real
  // waits and pumps until the share function is called (or time runs out).
  for (var i = 0; i < 40 && shared.isEmpty; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await t.pump(const Duration(milliseconds: 50));
  }
  await t.settle();

  expect(shared, hasLength(1), reason: 'se ha llamado a compartir una vez');
  final png = shared.single;
  qa.metric('png_bytes', png.length);
  expect(png.length, greaterThan(5000));
  expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47], reason: 'cabecera PNG');
  expect(names.single, 'cuadrante-2026.png');
  expect(find.text('No se ha podido compartir la imagen'), findsNothing);
  // The controller is untouched by sharing.
}
