import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'onboarding_support.dart';
import '../../support/real_font.dart';

/// H-T01-5: «Listo» said «Rotación: Correturnos, desde el martes...» but not
/// the point of the cycle the person chose for that day.
void main() {
  setUpAll(initializeLocale);
  setUpAll(() async => expect(await loadRoboto(), isTrue));

  Future<FirstLaunch> toReady(
    WidgetTester tester, {
    required int cycleDay,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    final app = await FirstLaunch.open(
      tester,
      size: size,
      textScale: textScale,
    );
    await app.tap(key('onboarding-profession-nursing'));
    await app.tap(key('onboarding-next'));
    await app.tap(key('onboarding-next'));
    await app.tap(key('onboarding-pattern-correturnos'));
    await app.tap(key('onboarding-next'));
    await app.tap(key('onboarding-offset-${cycleDay - 1}'));
    await app.tap(key('onboarding-next'));
    await app.tap(key('onboarding-next'));
    expect(app.title, 'Listo');
    return app;
  }

  String summary(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: key('onboarding-summary'),
          matching: find.byType(Text),
        ),
      )
      .map((t) => t.data)
      .join('\n');

  testWidgets('the summary says the day of the cycle chosen and its shift', (
    tester,
  ) async {
    await toReady(tester, cycleDay: 8);
    expect(summary(tester), contains('Rotación: Correturnos, desde el'));
    expect(summary(tester), contains('Empiezas en el día 8 del ciclo (Tarde)'));
  });

  testWidgets('the default is the first day of the cycle', (tester) async {
    await toReady(tester, cycleDay: 1);
    expect(
      summary(tester),
      contains('Empiezas en el día 1 del ciclo (Mañana)'),
    );
  });

  testWidgets('a rotation painted by hand has no cycle line', (tester) async {
    final app = await FirstLaunch.open(tester);
    await app.tap(key('onboarding-profession-nursing'));
    await app.tap(key('onboarding-next'));
    await app.tap(key('onboarding-next'));
    await app.tap(key('onboarding-by-hand'));
    if (app.title != 'Listo') await app.tap(key('onboarding-next'));
    if (app.title != 'Listo') await app.tap(key('onboarding-next'));
    expect(app.title, 'Listo');
    expect(summary(tester), contains('la pintas tú a mano'));
    expect(summary(tester), isNot(contains('del ciclo')));
  });

  for (final scenario in [
    (size: const Size(320, 640), scale: 2.0),
    (size: const Size(1280, 800), scale: 1.0),
    (size: const Size(915, 412), scale: 1.0),
  ]) {
    testWidgets('ready card fills its column at $scenario', (tester) async {
      final app = await toReady(
        tester,
        cycleDay: 8,
        size: scenario.size,
        textScale: scenario.scale,
      );
      await tester.ensureVisible(key('onboarding-summary'));
      await tester.pumpAndSettle();
      final card = tester.getRect(key('onboarding-summary'));
      final columnWidth = scenario.size.width.clamp(0, Sp.maxContentWidth);
      expect(card.width, closeTo(columnWidth - 2 * Sp.page, 0.01));
      expect(
        card.left,
        closeTo((scenario.size.width - columnWidth) / 2 + Sp.page, 0.01),
      );
      expect(tester.takeException(), isNull);
      await app.tap(key('onboarding-next'));
      expect(key('onboarding-summary'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
