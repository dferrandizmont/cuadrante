import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

const _oct12 = CivilDate(2026, 10, 12);
const _oct30 = CivilDate(2026, 10, 30);

/// Q09.
const qaAppearance = QaScenario(
  'Q09',
  'Tema oscuro y texto grande',
  _appearance,
);

Future<void> _appearance(QaContext qa) async {
  final t = qa.tester;
  addTearDown(t.platformDispatcher.clearAllTestValues);
  final app = await QaApp.open(qa);
  qa.expectNoFlutterErrors('al arrancar');

  for (final scale in [1.3, 2.0]) {
    final label = 'oscuro x$scale';
    t.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    t.platformDispatcher.textScaleFactorTestValue = scale;
    await t.settle();

    final context = t.element(find.byType(MonthScreen));
    expect(
      Theme.of(context).brightness,
      Brightness.dark,
      reason: 'el tema debe seguir el sistema ($label)',
    );
    expect(
      MediaQuery.textScalerOf(context).scale(10),
      closeTo(10 * scale, 0.01),
    );
    qa.expectNoFlutterErrors('mes, $label');
    expect(allCells, findsNWidgets(42), reason: label);
    expect(find.text('ESTA NOCHE'), findsOneWidget, reason: label);
    expect(inCell(qaToday, find.text('N')), findsOneWidget, reason: label);
    await qa.shot('mes_${_tag(scale)}');

    // The last row is reachable (the screen scrolls instead of squeezing).
    await t.ensureVisible(cell(const CivilDate(2026, 11, 8)));
    await t.settle();
    qa.expectNoFlutterErrors('fila final, $label');

    // Paint mode: bar, header and a stroke at this size.
    await t.ensureVisible(find.text('Pintar'));
    await enterPaintMode(t);
    qa.expectNoFlutterErrors('modo pintar, $label');
    await t.tapAndSettle(tool('afternoon'));
    await t.tapAndSettle(cell(_oct30));
    expect(inCell(_oct30, find.text('T')), findsOneWidget, reason: label);
    await qa.shot('pintar_${_tag(scale)}');
    await t.tapAndSettle(find.byKey(const ValueKey('undo')));
    await exitPaintMode(t);
    qa.expectNoFlutterErrors('tras pintar, $label');

    // Day sheet.
    await t.tapAndSettle(cell(_oct12));
    expect(find.byType(BottomSheet), findsOneWidget, reason: label);
    expect(find.text('Festivo: Fiesta Nacional de España'), findsOneWidget);
    qa.expectNoFlutterErrors('detalle del día, $label');
    await qa.shot('dia_${_tag(scale)}');
    // The sheet fills the screen at large text: go back instead of tapping
    // the dimmed area that is not there.
    final sheet = find.byType(BottomSheet);
    if (t.getTopLeft(sheet).dy > 100) {
      await t.tapAt(const Offset(20, 60));
    } else {
      await Navigator.of(t.element(sheet)).maybePop();
    }
    await t.settle();
  }

  await app.flushWrites();
  expect(await app.storedDay(_oct30), isNull, reason: 'deshecho: sin fila');
}

String _tag(double scale) => 'oscuro_x${scale.toString().replaceAll('.', '')}';
