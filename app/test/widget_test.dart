import 'package:cuadrante/app.dart';
import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';
import 'support/spanish_phone.dart';

void main() {
  setUpAll(initializeLocale);

  testWidgets('shows the date, the card of today and the month calendar', (
    tester,
  ) async {
    useSpanishPhone(tester);
    // Portrait, one column: the default 800 x 600 test window is landscape and
    // wide, which has two panes (the date is in the right one, shorter).
    tester.view.physicalSize = const Size(640, 892) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final now = DateTime(2026, 10, 23, 9);
    final storage = await openTestStorage(tester, now: now);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storage.overrides,
          clockProvider.overrideWithValue(() => now),
        ],
        child: const CuadranteApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Viernes, 23 de octubre'), findsOneWidget);
    expect(find.text('HOY'), findsOneWidget);
    expect(find.text('Empieza en 5 h'), findsOneWidget);
    expect(find.text('Octubre'), findsOneWidget);
  });

  testWidgets('opens settings', (tester) async {
    useSpanishPhone(tester);
    final storage = await openTestStorage(
      tester,
      now: DateTime(2026, 10, 23, 9),
    );
    await tester.pumpWidget(
      ProviderScope(overrides: storage.overrides, child: const CuadranteApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abrir ajustes'));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsWidgets);
  });
}
