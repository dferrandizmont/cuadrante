import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_device_calendar.dart';
import '../../support/real_font.dart';
import 'import_ui_support.dart';

/// H-T14-5: the table of the first rows of a CSV cut the 4th column
/// («Hora de fin», 3 px wide) with no sign that it scrolls sideways. It shows
/// a scrollbar and a line that says so while there is more to the right, and
/// the last column can be brought fully into view.
const _csv = '''Fecha;Turno;Inicio;Fin
09/11/2026;Mañana;06:00;14:00
10/11/2026;Mañana;06:00;14:00
11/11/2026;Tarde;14:00;22:00
14/11/2026;Libre;;
''';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('four columns at $width dp, text $scale', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final picker = FakePicker()..next = fileOf('turnos.csv', _csv);
        final app = await AppUnderTest.pump(
          tester,
          size: Size(width, 1600),
          overrides: importOverrides(
            phone: FakeDeviceCalendar(),
            picker: picker,
          ),
        );
        await app.openSettings();
        await tester.ensureVisible(byKey('settings-import'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('settings-import'));
        await tester.pumpAndSettle();
        await tapKey(tester, 'import-source-csv');

        final card = byKey('import-csv-preview');
        expect(card, findsOneWidget);
        final cardRect = tester.getRect(card);
        final scroller = find.descendant(
          of: card,
          matching: find.byType(SingleChildScrollView),
        );
        final position = tester
            .state<ScrollableState>(
              find.descendant(of: scroller, matching: find.byType(Scrollable)),
            )
            .position;
        final overflows = position.maxScrollExtent > 0;

        // The 4 columns do not fit these widths: a hint says it, and a
        // scrollbar is on screen. (At 412 dp with normal text they fit.)
        if (width <= 360 || scale > 1.0) {
          expect(overflows, isTrue, reason: 'the table is wider than the card');
        }
        expect(
          byKey('import-csv-more').evaluate().isNotEmpty,
          overflows,
          reason: 'the hint shows exactly while there is more to the right',
        );
        if (overflows) {
          expect(
            find.textContaining('Desliza hacia los lados'),
            findsOneWidget,
          );
          expect(byKey('import-csv-scrollbar'), findsOneWidget);
        }

        // Scrolled to the end, the last column is whole and inside the card,
        // and the hint is gone.
        if (overflows) {
          await tester.drag(scroller, const Offset(-3000, 0));
          await tester.pumpAndSettle();
        }
        final last = find.descendant(
          of: card,
          matching: find.text('Hora de fin (opcional)'),
        );
        expect(last, findsOneWidget);
        final lastRect = tester.getRect(last);
        expect(lastRect.left, greaterThanOrEqualTo(cardRect.left));
        expect(lastRect.right, lessThanOrEqualTo(cardRect.right));
        expect(byKey('import-csv-more'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
