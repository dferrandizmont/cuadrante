import 'package:cuadrante/app.dart';
import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/format/money.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/settings/application/preferences_controller.dart';
import 'package:cuadrante/features/settings/domain/preferences.dart';
import 'package:cuadrante/features/summary/presentation/summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import '../calendar/harness.dart';

// QA campaign, T08: the figures of the month floated mid-card (H-T08-1), the
// table of the year did not fit (H-T08-2), «Sept» (H-T08-3), «Vacacion…» in
// the legend (H-T08-4) and a holiday line with nothing to say (H-T08-6).
// Every layout is checked at 320 / 360 / 412 dp and text 1.0 / 1.3 / 2.0 with
// the real font.

Finder _key(String key) => find.byKey(ValueKey(key));

const _widths = [320.0, 360.0, 412.0];
const _scales = [1.0, 1.3, 2.0];

Future<void> _rates(ScheduleRepository repository) async {
  for (final (key, rate) in [('morning', 1000), ('afternoon', 1100)]) {
    await repository.saveShiftType(
      shiftTemplates
          .firstWhere((t) => t.key == key)
          .toShiftType(key)
          .copyWith(hourlyRateCents: rate),
    );
  }
}

Future<void> _go(WidgetTester tester, String location) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(CuadranteApp)),
  );
  container.read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

Size _phone(double width) => Size(width, 760);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  for (final (language, label, count) in [
    (AppLanguage.es, 'Pluses', '5 turnos'),
    (AppLanguage.ca, 'Plusos', '5 torns'),
    (AppLanguage.gl, 'Complementos', '5 quendas'),
    (AppLanguage.eu, 'Osagarriak', '5 txanda'),
    (AppLanguage.en, 'Allowances', '5 shifts'),
  ]) {
    testWidgets('fixed plus line at 320 dp, text 2.0, ${language.name}', (
      tester,
    ) async {
      await pumpCalendar(
        tester,
        size: _phone(320),
        textScale: 2.0,
        overrides: [
          initialPreferencesProvider.overrideWithValue(
            Preferences(language: language),
          ),
        ],
        prepare: (repository) async {
          await _rates(repository);
          await repository.saveShiftType(
            shiftTemplates
                .firstWhere((t) => t.key == 'night')
                .toShiftType('night')
                .copyWith(fixedPlusCents: 3000),
          );
        },
      );
      await _go(tester, '/resumen?mes=2026-10');
      final row = _key('summary-fixed-plus');
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget);
      final context = tester.element(find.byType(SummaryScreen));
      expect(
        tester.widget<Text>(_key('summary-fixed-plus-value')).data,
        formatEuroCents(context, 15000),
      );
      expect(
        tester.widget<Text>(_key('summary-fixed-plus-detail')).data,
        count,
      );
      expect(
        tester.widget<Text>(_key('summary-earnings')).data,
        formatEuroCents(context, 139800),
      );
      final rect = tester.getRect(row);
      for (final element
          in find
              .descendant(of: row, matching: find.byType(RichText))
              .evaluate()) {
        final paragraph = element.renderObject! as RenderParagraph;
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(wrapsOnlyBetweenWords(paragraph), isTrue);
        final textRect = tester.getRect(find.byWidget(element.widget));
        expect(textRect.left, greaterThanOrEqualTo(rect.left - 0.5));
        expect(textRect.right, lessThanOrEqualTo(rect.right + 0.5));
      }
      expect(tester.takeException(), isNull);
    });
  }

  group('H-T08-1: the figures are flush right or under their label', () {
    const ids = [
      'summary-shifts',
      'summary-overtime',
      'summary-early-leave',
      'summary-night',
      'summary-rest',
      'summary-absences',
    ];

    for (final width in _widths) {
      for (final scale in _scales) {
        testWidgets('at $width dp, text $scale', (tester) async {
          await pumpCalendar(
            tester,
            size: _phone(width),
            textScale: scale,
            prepare: _rates,
          );
          final controller = containerOf(tester)
              .read(scheduleControllerProvider.notifier);
          controller.setDayExtras(
            const CivilDate(2026, 10, 26),
            overtimeMinutes: 90,
          );
          controller.setDayExtras(
            const CivilDate(2026, 10, 29),
            earlyLeaveMinutes: 60,
          );
          await tester.pumpAndSettle();
          await _go(tester, '/resumen?mes=2026-10');

          for (final id in ids) {
            await tester.ensureVisible(_key(id));
            await tester.pump();
            final row = tester.getRect(_key(id));
            final label = tester.getRect(
              find.descendant(of: _key(id), matching: find.byType(Text)).first,
            );
            final value = tester.getRect(_key('$id-value'));
            final detailFinder = _key('$id-detail');
            final detail = detailFinder.evaluate().isEmpty
                ? null
                : tester.getRect(detailFinder);

            final inline =
                value.left >= label.right - 0.5 &&
                (value.center.dy - label.center.dy).abs() < label.height;
            if (inline) {
              expect(value.right, closeTo(row.right, 0.6), reason: id);
              if (detail != null) {
                expect(detail.right, closeTo(row.right, 0.6), reason: id);
                expect(detail.top, greaterThanOrEqualTo(value.bottom - 0.5));
              }
            } else {
              // Stacked: under the label, starting where it does; the detail
              // under the figure.
              expect(value.left, closeTo(label.left, 0.6), reason: id);
              expect(value.top, greaterThanOrEqualTo(label.bottom - 0.5));
              if (detail != null) {
                expect(detail.left, closeTo(label.left, 0.6), reason: id);
                expect(detail.top, greaterThanOrEqualTo(value.bottom - 0.5));
              }
            }
            expect(value.right, lessThanOrEqualTo(row.right + 0.5));
            for (final element
                in find
                    .descendant(of: _key(id), matching: find.byType(RichText))
                    .evaluate()) {
              expect(
                wrapsOnlyBetweenWords(element.renderObject! as RenderParagraph),
                isTrue,
                reason: '$id breaks a word',
              );
            }
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('H-T08-2 and H-T08-3: the year', () {
    for (final width in _widths) {
      for (final scale in _scales) {
        testWidgets('at $width dp, text $scale: every month and its euros '
            'are visible without scrolling sideways', (tester) async {
          await pumpCalendar(
            tester,
            size: _phone(width),
            textScale: scale,
            prepare: _rates,
          );
          await _go(tester, '/resumen?mes=2026-10&vista=ano');

          // Nothing scrolls sideways, whatever the text size.
          final horizontal = find.byWidgetPredicate(
            (w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.horizontal,
          );
          expect(horizontal, findsNothing);

          // September is «Sep» (3 letters) wherever the table shows it.
          expect(find.text('Sept'), findsNothing);
          final large = scale >= 1.3;
          if (large) {
            // Cards: the name of the month and its euros in the same card.
            final card = _key('summary-year-card-11');
            await tester.ensureVisible(card);
            await tester.pump();
            final rect = tester.getRect(card);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(width));
            final texts = find.descendant(
              of: card,
              matching: find.byType(Text),
            );
            final shown = [
              for (final e in texts.evaluate()) (e.widget as Text).data!,
            ];
            expect(shown.first, 'Noviembre');
            expect(shown.join(' '), contains('€'));
            for (final e in texts.evaluate()) {
              final r = tester.getRect(find.byWidget(e.widget));
              expect(r.left, greaterThanOrEqualTo(rect.left));
              expect(r.right, lessThanOrEqualTo(rect.right + 0.5));
            }
            expect(
              brokenParagraphs(tester),
              isEmpty,
              reason: 'a word is split across lines',
            );
            // Tapping a card opens that month.
            await tester.tap(card);
            await tester.pumpAndSettle();
            expect(
              tester.widget<Text>(_key('summary-period')).data,
              'Noviembre 2026',
            );
          } else {
            await tester.ensureVisible(_key('summary-year-row-9'));
            await tester.pump();
            expect(find.text('Sep'), findsOneWidget);
            // The table fits the screen and the five headers are drawn at
            // the same size: «Turnos» used to shrink below the others.
            final scales = <double>{};
            for (final header in [
              'Mes',
              'Turnos',
              'Horas',
              'Noct.',
              'Estimado',
            ]) {
              final laidOut = tester.getSize(find.text(header));
              final drawn = tester.getRect(find.text(header));
              scales.add(
                double.parse((drawn.width / laidOut.width).toStringAsFixed(2)),
              );
              expect(drawn.right, lessThanOrEqualTo(width));
            }
            expect(scales, {1.0}, reason: 'headers shrunk: $scales');
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('H-T08-4: the legend of the annual view', () {
    for (final width in _widths) {
      for (final scale in _scales) {
        testWidgets('at $width dp, text $scale: «Vacaciones» is whole, '
            'its count beside or under it', (tester) async {
          await pumpCalendar(tester, size: _phone(width), textScale: scale);
          await tester.ensureVisible(_key('open-year'));
          await tester.pumpAndSettle();
          await tester.tap(_key('open-year'));
          await tester.pumpAndSettle();
          final legend = _key('year-legend-vacation');
          await tester.scrollUntilVisible(
            legend,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          final name = find.descendant(
            of: legend,
            matching: find.text('Vacaciones'),
          );
          expect(name, findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(name);
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(wrapsOnlyBetweenWords(paragraph), isTrue);
          // The whole word is laid out in one line: no ellipsis.
          expect(paragraphLines(paragraph), ['Vacaciones']);
          final count = find.descendant(
            of: legend,
            matching: find.textContaining('día'),
          );
          final nameBox = tester.getRect(name);
          final countBox = tester.getRect(count);
          final row = tester.getRect(legend);
          expect(countBox.right, lessThanOrEqualTo(row.right + 0.5));
          expect(nameBox.right, lessThanOrEqualTo(row.right + 0.5));
          final sideBySide = countBox.left >= nameBox.right;
          if (!sideBySide) {
            expect(countBox.top, greaterThanOrEqualTo(nameBox.bottom - 0.5));
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('H-T08-6 / H-T10-4: the holiday line', () {
    testWidgets('a month with a holiday shows it; one without does not', (
      tester,
    ) async {
      await pumpCalendar(tester, prepare: _rates);
      // 12 October is a national holiday.
      await _go(tester, '/resumen?mes=2026-10');
      expect(_key('summary-holiday'), findsOneWidget);
      expect(find.text('Horas en festivo'), findsOneWidget);

      // September 2026 has shifts and no national holiday.
      await _go(tester, '/resumen?mes=2026-09');
      expect(_key('summary-hours'), findsOneWidget);
      expect(_key('summary-holiday'), findsNothing);
      expect(find.text('Horas en festivo'), findsNothing);
      expect(find.textContaining('turnos en festivo'), findsNothing);
      // Nor the note that explains it.
      expect(find.textContaining('Horas en festivo:'), findsNothing);
    });

    testWidgets('a month with a holiday nobody works on has no line either', (
      tester,
    ) async {
      await pumpCalendar(tester, prepare: _rates);
      // 12 October is a holiday in the month, but make it a day off: 0 h and
      // 0 shifts on holidays.
      containerOf(tester)
          .read(scheduleControllerProvider.notifier)
          .clearDay(const CivilDate(2026, 10, 12));
      await tester.pumpAndSettle();
      await _go(tester, '/resumen?mes=2026-10');
      expect(_key('summary-hours'), findsOneWidget);
      expect(_key('summary-holiday'), findsNothing);
      expect(find.text('Horas en festivo'), findsNothing);
      expect(find.textContaining('turnos en festivo'), findsNothing);
      expect(find.textContaining('Horas en festivo:'), findsNothing);
    });

    testWidgets('«Fechas…» follows the same rule', (tester) async {
      await pumpCalendar(tester, prepare: _rates);
      await _go(tester, '/resumen?mes=2026-09');
      await tester.ensureVisible(_key('summary-mode-range'));
      await tester.tap(_key('summary-mode-range'));
      await tester.pumpAndSettle();
      expect(_key('summary-holiday'), findsNothing);
    });
  });
}
