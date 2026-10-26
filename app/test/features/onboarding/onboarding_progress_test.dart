import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'onboarding_support.dart';

/// H-T01-9: «¿Cómo es tu rotación?» and «¿Cuándo empiezas?» both said
/// «Paso 3 de 5», so pressing «Siguiente» looked like nothing had happened.
void main() {
  setUpAll(initializeLocale);

  String progress(WidgetTester tester) {
    final semantics = tester.getSemantics(key('onboarding-dots'));
    return semantics.label;
  }

  int dashes(WidgetTester tester) => find
      .descendant(
        of: key('onboarding-dots'),
        matching: find.byType(AnimatedContainer),
      )
      .evaluate()
      .length;

  testWidgets('every screen of the flow has its own «Paso N de M»', (
    tester,
  ) async {
    final app = await FirstLaunch.open(tester);
    final seen = <String, String>{};

    Future<void> record() async => seen[app.title] = progress(tester);

    await record(); // ¿A qué te dedicas?
    await app.tap(key('onboarding-profession-nursing'));
    await app.tap(key('onboarding-next'));
    await record(); // ¿Dónde trabajas?
    await app.tap(key('onboarding-next'));
    await record(); // ¿Cómo es tu rotación?
    await app.tap(key('onboarding-pattern-12h'));
    await app.tap(key('onboarding-next'));
    await record(); // ¿Cuándo empiezas?
    await app.tap(key('onboarding-next'));
    await record(); // ¿Vienes de otra app?
    await app.tap(key('onboarding-next'));
    await record(); // Listo

    expect(seen.keys, [
      '¿A qué te dedicas?',
      '¿Dónde trabajas?',
      '¿Cómo es tu rotación?',
      '¿Cuándo empiezas?',
      '¿Vienes de otra app?',
      'Listo',
    ]);
    expect(seen.values, [
      'Paso 1 de 6',
      'Paso 2 de 6',
      'Paso 3 de 6',
      'Paso 4 de 6',
      'Paso 5 de 6',
      'Paso 6 de 6',
    ]);
    expect(dashes(tester), 6);
  });
}
