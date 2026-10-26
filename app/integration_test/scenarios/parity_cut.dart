import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

// «Cortar» en la barra de selección (docs/paridad.md A11), Q90 y Q92.
//
// Demo data around Monday 19 Oct 2026 (see `selection.dart`).

const _oct19 = CivilDate(2026, 10, 19);
const _nov16 = CivilDate(2026, 11, 16); // Monday; the rotation does not match

// `qaCutDays` (Q90) and `qaCutAndPaste` (Q92) are listed by `parity.dart`.

Finder _k(String key) => find.byKey(ValueKey(key));

Set<CivilDate> _range(CivilDate from, int days) => {
  for (var i = 0; i < days; i++) from.addDays(i),
};

/// Long press on [from] and, with the finger still down, drag to [to].
Future<void> _longPressDrag(
  WidgetTester t,
  CivilDate from,
  CivilDate to,
) async {
  final start = t.getCenter(cell(from));
  final end = t.getCenter(cell(to));
  final gesture = await t.startGesture(start);
  await t.pump(kLongPressTimeout + const Duration(milliseconds: 100));
  const steps = 8;
  for (var s = 1; s <= steps; s++) {
    await gesture.moveTo(Offset.lerp(start, end, s / steps)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await t.settle();
}

/// The days drawn with the check of a chosen day.
Set<CivilDate> _selected(WidgetTester t) {
  const prefix = 'selected-mark-';
  return {
    for (final element
        in find
            .byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith(prefix),
            )
            .evaluate())
      CivilDate.parse(
        (element.widget.key! as ValueKey<String>).value.substring(
          prefix.length,
        ),
      ),
  };
}

// ---- Q90 -------------------------------------------------------------------

/// Q90.
const qaCutDays = QaScenario(
  'Q90',
  'Cortar una semana: se vacía y un solo deshacer la devuelve',
  _cutDays,
);

Future<void> _cutDays(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final originalDump = await app.dumpSchedule();
  final week = _range(_oct19, 7);

  await _longPressDrag(t, _oct19, _oct19.addDays(6));
  expect(_selected(t), week);
  expect(find.text('7 días'), findsOneWidget);
  await qa.shot('semana');

  await t.tapAndSettle(_k('selection-cut'));
  expect(find.textContaining('7 días cortados'), findsOneWidget);
  for (final d in week) {
    expect(idsOn(app.schedule, d), '', reason: 'vacío el $d');
  }
  expect(_selected(t), isEmpty, reason: 'listo para elegir dónde pegar');
  await app.flushWrites();
  expect(await app.dumpSchedule(), isNot(originalDump));
  await qa.shot('cortada');

  // One undo step brings the whole week back, on screen and stored.
  await t.tapAndSettle(_k('undo'));
  expect(app.scheduleState.canUndo, isFalse, reason: 'una acción = un paso');
  await app.flushWrites();
  expect(await app.dumpSchedule(), originalDump);

  // The clipboard kept the cut days: Pegar is available on a new pick.
  await t.tapAndSettle(cell(_oct19.addDays(10)));
  final paste = t.widget<InkWell>(_k('selection-paste'));
  expect(paste.onTap, isNotNull, reason: 'el portapapeles sigue ahí');
}

// ---- Q92 -------------------------------------------------------------------

/// Q92.
const qaCutAndPaste = QaScenario(
  'Q92',
  'Cortar una semana y pegarla en otro mes',
  _cutAndPaste,
);

Future<void> _cutAndPaste(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final source = app.resolved(_oct19, 7);
  final originalDump = await app.dumpSchedule();

  await _longPressDrag(t, _oct19, _oct19.addDays(6));
  await t.tapAndSettle(_k('selection-cut'));

  await t.tapAndSettle(find.byTooltip('Mes siguiente'));
  await t.tapAndSettle(cell(_nov16));
  await t.tapAndSettle(_k('selection-paste'));
  await t.tapAndSettle(_k('paste-confirm'));

  final pasted = app.resolved(_nov16, 7);
  for (var i = 0; i < 7; i++) {
    expect(
      pasted[i].split('|')[1],
      source[i].split('|')[1],
      reason: 'día $i pegado',
    );
  }
  for (var i = 0; i < 7; i++) {
    expect(idsOn(app.schedule, _oct19.addDays(i)), '', reason: 'origen $i');
  }
  await app.flushWrites();
  await qa.shot('pegada');

  // Undo the paste and the cut: ONE step each; everything is back.
  await t.tapAndSettle(_k('undo'));
  await t.tapAndSettle(_k('undo'));
  await app.flushWrites();
  expect(await app.dumpSchedule(), originalDump);
  expect(app.scheduleState.canUndo, isFalse);
}
