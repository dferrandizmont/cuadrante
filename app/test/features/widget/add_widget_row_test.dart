import 'package:cuadrante/features/widget/application/widget_providers.dart';
import 'package:cuadrante/features/widget/data/widget_publisher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

Future<void> _openRow(WidgetTester tester) async {
  final row = find.byKey(const ValueKey('settings-widget'));
  await tester.scrollUntilVisible(
    row,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(row);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Ajustes has the row; without pinning it explains the steps', (
    tester,
  ) async {
    final publisher = FakeWidgetPublisher();
    final app = await AppUnderTest.pump(
      tester,
      overrides: [widgetPublisherProvider.overrideWithValue(publisher)],
    );
    await app.openSettings();
    expect(find.text('Añadir widget'), findsOneWidget);
    await _openRow(tester);
    expect(find.byKey(const ValueKey('widget-add-manual')), findsOneWidget);
    expect(find.textContaining('Mantén pulsada'), findsOneWidget);
    expect(find.byKey(const ValueKey('widget-pin-small')), findsNothing);
    expect(publisher.pinRequests, isEmpty);
  });

  testWidgets(
    'where the launcher can pin, all five layouts ask for their widget',
    (tester) async {
      final publisher = FakeWidgetPublisher()..pinSupported = true;
      final app = await AppUnderTest.pump(
        tester,
        overrides: [widgetPublisherProvider.overrideWithValue(publisher)],
      );
      await app.openSettings();
      await _openRow(tester);
      expect(find.byKey(const ValueKey('widget-add-manual')), findsNothing);
      expect(find.text('Agenda: próximos turnos'), findsOneWidget);
      expect(find.text('Dos semanas: actual y siguiente'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('widget-pin-medium')));
      await tester.pumpAndSettle();
      expect(publisher.pinRequests, [WidgetSize.medium]);

      await _openRow(tester);
      await tester.tap(find.byKey(const ValueKey('widget-pin-small')));
      await tester.pumpAndSettle();
      expect(publisher.pinRequests, [WidgetSize.medium, WidgetSize.small]);

      await _openRow(tester);
      expect(find.text('Grande: el mes entero'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('widget-pin-large')));
      await tester.pumpAndSettle();
      expect(publisher.pinRequests, [
        WidgetSize.medium,
        WidgetSize.small,
        WidgetSize.large,
      ]);

      await _openRow(tester);
      final agenda = find.byKey(const ValueKey('widget-pin-agenda'));
      await tester.ensureVisible(agenda);
      await tester.tap(agenda);
      await tester.pumpAndSettle();

      await _openRow(tester);
      final twoWeeks = find.byKey(const ValueKey('widget-pin-two-weeks'));
      await tester.ensureVisible(twoWeeks);
      await tester.tap(twoWeeks);
      await tester.pumpAndSettle();
      expect(publisher.pinRequests, [
        WidgetSize.medium,
        WidgetSize.small,
        WidgetSize.large,
        WidgetSize.agenda,
        WidgetSize.twoWeeks,
      ]);
    },
  );
}
