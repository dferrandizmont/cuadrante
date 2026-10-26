import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/agenda/domain/agenda.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import '../calendar/harness.dart';

// QA campaign, T09: the hint of the search field was cut at 320 dp / x1.3 and
// x2.0 (H-T09-1) and nothing said how far the search reaches (H-T09-4).

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('at $width dp, text $scale: the hint is whole and the '
          'search says what it covers', (tester) async {
        await pumpCalendar(tester, size: Size(width, 760), textScale: scale);
        await tester.tap(_key('open-agenda'));
        await tester.pumpAndSettle();

        // The hint is one line, with no ellipsis, whatever the size.
        final field = find.descendant(
          of: _key('agenda-search'),
          matching: find.byType(Text),
        );
        final hints = [
          for (final e in field.evaluate())
            if ((e.widget as Text).data?.startsWith('Buscar') ?? false) e,
        ];
        expect(hints, hasLength(1));
        final paragraph = hints.single.renderObject! as RenderParagraph;
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(paragraphLines(paragraph), hasLength(1));
        expect(
          paragraph.size.width,
          lessThanOrEqualTo(tester.getSize(_key('agenda-search')).width),
        );

        // Searching: the scope is said under the results...
        await tester.enterText(_key('agenda-search'), 'marta');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          _key('agenda-scope'),
          300,
          scrollable: find.descendant(
            of: _key('agenda-list'),
            matching: find.byType(Scrollable),
          ),
        );
        expect(
          tester.widget<Text>(_key('agenda-scope')).data,
          contains('un año'),
        );
        expect(agendaSearchWindowDays, 366, reason: 'the text says «un año»');

        // ...and under «Nada encontrado».
        await tester.enterText(_key('agenda-search'), 'zzzz');
        await tester.pumpAndSettle();
        expect(find.text('Nada encontrado'), findsOneWidget);
        expect(_key('agenda-scope'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  // Agenda with shifts and search by date: the two options, the shift chips
  // with their hours and the «Libre» line fit at the smallest phone with the
  // largest text.
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('at $width dp, text $scale: «Notas»/«Turnos» and the shifts '
          'list fit', (tester) async {
        await pumpCalendar(tester, size: Size(width, 760), textScale: scale);
        await tester.tap(_key('open-agenda'));
        await tester.pumpAndSettle();

        // Both options in whole words, inside the screen (they share a row
        // when they fit and stack when they do not).
        for (final k in ['agenda-mode-notes', 'agenda-mode-shifts']) {
          final text = find.descendant(
            of: _key(k),
            matching: find.byType(Text),
          );
          final paragraph = tester.renderObject<RenderParagraph>(text);
          expect(paragraphLines(paragraph), hasLength(1), reason: k);
          expect(paragraph.didExceedMaxLines, isFalse, reason: k);
          final box = tester.getRect(_key(k));
          expect(box.left, greaterThanOrEqualTo(0), reason: k);
          expect(box.right, lessThanOrEqualTo(width), reason: k);
        }

        // The list of shifts: chips with the hours, a day off, the doubled
        // day; nothing overflows.
        await tester.tap(_key('agenda-mode-shifts'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final list = find.descendant(
          of: _key('agenda-list'),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          _key('agenda-day-2026-10-22'),
          200,
          scrollable: list,
        );
        expect(
          find.descendant(
            of: _key('agenda-day-2026-10-22'),
            matching: find.text('Libre'),
          ),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          _key('agenda-day-2026-11-20'),
          400,
          scrollable: list,
        );
        expect(tester.takeException(), isNull);

        // A date typed in the search: the day shows, with «Libre».
        await tester.enterText(_key('agenda-search'), '22 de octubre');
        await tester.pumpAndSettle();
        expect(_key('agenda-day-2026-10-22'), findsOneWidget);
        expect(
          find.descendant(
            of: _key('agenda-day-2026-10-22'),
            matching: find.text('Libre'),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('without a search there is no scope line', (tester) async {
    await pumpCalendar(tester);
    await tester.tap(_key('open-agenda'));
    await tester.pumpAndSettle();
    expect(_key('agenda-scope'), findsNothing);
  });
}
