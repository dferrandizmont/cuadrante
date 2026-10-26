import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  setUpAll(initializeLocale);

  testWidgets(
    'opening a route while the keyboard retreats has no duplicate heroes',
    (tester) async {
      await pumpCalendar(tester);
      addTearDown(tester.view.resetViewInsets);

      // Android may open and close the keyboard before the FAB's exit
      // animation finishes (for example when saving a form above the month).
      tester.view.viewInsets = const FakeViewPadding(bottom: 280 * 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      tester.view.resetViewInsets();
      await tester.pump();

      // A route transition collects the Heroes of the underlying month too.
      await tester.tap(find.byTooltip('Abrir ajustes'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Ajustes'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Pintar'), findsOneWidget);
      await tester.tap(find.text('Pintar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('paint-done')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
