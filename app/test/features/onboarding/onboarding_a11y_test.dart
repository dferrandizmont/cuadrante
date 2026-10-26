import 'dart:ui' show Tristate;

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'onboarding_support.dart';

/// T18 (accesibilidad): what TalkBack can read and touch in the first-use
/// flow.
Future<void> _next(FirstLaunch app) => app.tap(key('onboarding-next'));

/// Whether the node that speaks [label] says «seleccionado».
bool _selected(WidgetTester tester, Pattern label) {
  final node = tester.getSemantics(find.bySemanticsLabel(label));
  return node.getSemanticsData().flagsCollection.isSelected == Tristate.isTrue;
}

void main() {
  setUpAll(initializeLocale);

  testWidgets('H-T18-2: the chosen profession and rotation say they are '
      'selected', (tester) async {
    final handle = tester.ensureSemantics();
    final app = await FirstLaunch.open(tester);

    expect(_selected(tester, RegExp('^Enfermería')), isFalse);
    await app.tap(key('onboarding-profession-nursing'));
    expect(_selected(tester, RegExp('^Enfermería')), isTrue);
    expect(_selected(tester, RegExp('^Medicina')), isFalse);

    await _next(app);
    await app.tap(key('onboarding-region'));
    await app.tap(find.text('Comunidad de Madrid'));
    await _next(app);

    final preset = RegExp('^12 horas');
    expect(_selected(tester, preset), isFalse);
    await app.tap(key('onboarding-pattern-12h'));
    expect(_selected(tester, preset), isTrue);
    handle.dispose();
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('H-T18-1: the cells «Día N» of the start step are at least '
        '48 x 48 dp (text x$scale)', (tester) async {
      final app = await FirstLaunch.open(tester, textScale: scale);
      await app.tap(key('onboarding-profession-nursing'));
      await _next(app);
      await app.tap(key('onboarding-region'));
      await app.tap(find.text('Comunidad de Madrid'));
      await _next(app);
      await app.tap(key('onboarding-pattern-12h'));
      await _next(app);
      expect(app.title, '¿Cuándo empiezas?');

      for (var i = 0; i < 4; i++) {
        final cell = find.descendant(
          of: key('onboarding-offset-$i'),
          matching: find.byType(InkWell),
        );
        final size = tester.getSize(cell);
        expect(size.width, greaterThanOrEqualTo(48), reason: 'cell $i');
        expect(size.height, greaterThanOrEqualTo(48), reason: 'cell $i');
      }
    });
  }
}
