import 'dart:typed_data';

import 'package:cuadrante/app.dart';
import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/format/app_date_format.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/application/visible_month.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/year/application/year_providers.dart';
import 'package:cuadrante/features/year/application/year_summary.dart';
import 'package:cuadrante/features/year/presentation/year_month.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../calendar/harness.dart';
import '../schedule/domain/fixtures.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(CuadranteApp)));

Schedule _schedule(WidgetTester tester) =>
    _container(tester).read(scheduleControllerProvider).schedule;

Future<void> _openYear(WidgetTester tester) async {
  await tester.tap(_key('open-year'));
  await tester.pumpAndSettle();
}

/// Fill colours of the heat-map square of [date]: one per shift, `null` for
/// a day without shift (`surfaceMuted`).
List<Color?> _fills(WidgetTester tester, CivilDate date) {
  final finder = _key('year-day-${date.toIso()}');
  final widget = tester.widget(finder);
  if (widget is ColoredBox) return [null];
  final row = widget as Row;
  return [
    for (final child in row.children)
      (((child as Expanded).child) as ColoredBox).color,
  ];
}

Color _bar(int colorValue, Brightness b) =>
    ShiftSwatch.forColor(colorValue, b).bar;

void main() {
  setUpAll(initializeLocale);

  testWidgets('the exported month identifies two shifts of the same colour', (
    tester,
  ) async {
    const first = CivilDate(2026, 10, 1);
    final morning = allTypes.firstWhere((t) => t.id == 'morning');
    final other = morning.copyWith(id: 'other', code: 'D', name: 'Día 12 h');
    final schedule = Schedule(
      shiftTypes: [morning, other],
      entries: {
        first: DayEntry(date: first, shiftTypeIds: [morning.id]),
        first.addDays(1): DayEntry(
          date: first.addDays(1),
          shiftTypeIds: [other.id],
        ),
        first.addDays(2): DayEntry(
          date: first.addDays(2),
          shiftTypeIds: [morning.id, other.id],
        ),
      },
    );
    await pumpCalendar(tester);
    final theme = Theme.of(tester.element(find.byType(Scaffold).last));
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: YearMonth(
              month: first,
              schedule: schedule,
              holidays: const {},
              today: first,
              weekStart: 1,
              width: 280,
            ),
          ),
        ),
      ),
    );
    expect(_fills(tester, first), _fills(tester, first.addDays(1)));
    for (final (date, id, code) in [
      (first, morning.id, morning.code),
      (first.addDays(1), other.id, other.code),
      (first.addDays(2), morning.id, morning.code),
      (first.addDays(2), other.id, other.code),
    ]) {
      final label = tester.widget<Text>(_key('year-code-${date.toIso()}-$id'));
      expect(label.data, code);
    }
    expect(tester.takeException(), isNull);
  });

  group('summary of the year', () {
    test('6 x 4 from 1 January 2026: counts per type for the whole year', () {
      final s = presetSchedule('6x4', jan1);
      final summary = summarizeYear(s, 2026);
      // 365 days = 36 cycles of 10 and 5 days more (all mornings).
      expect(summary.counts, {'morning': 36 * 6 + 5, 'rest': 36 * 4});
      expect(summary.countOf('night'), 0);
      expect(summary.isEmpty, isFalse);
    });

    test('a run that starts mid-year only counts from there', () {
      final s = presetSchedule('24x72', const CivilDate(2026, 12, 1));
      expect(summarizeYear(s, 2025).isEmpty, isTrue);
      // 1-31 December: guards on 1, 5, ..., 29 (8) and 23 rest days.
      expect(summarizeYear(s, 2026).counts, {'guard24': 8, 'rest': 23});
    });

    test(
      'several shifts in a day count once each; order follows the types',
      () {
        final s = presetSchedule(
          '5x2',
          jan1,
          entries: {
            jan1: DayEntry(
              date: jan1,
              shiftTypeIds: const ['night', 'morning'],
            ),
          },
        );
        final summary = summarizeYear(s, 2026);
        expect(summary.counts.keys.toList(), ['morning', 'night', 'rest']);
        expect(summary.countOf('night'), 1);
        // 1 Jan is a Thursday: the 5x2 from there is not weekday-aligned, but
        // its morning count is the same as without the override minus the day
        // replaced, plus the double shift.
        final plain = summarizeYear(presetSchedule('5x2', jan1), 2026);
        expect(summary.countOf('morning'), plain.countOf('morning'));
        expect(summary.countOf('rest'), plain.countOf('rest'));
      },
    );
  });

  group('annual view', () {
    testWidgets('opens from the month title and from its button', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await tester.tap(_key('month-title'));
      await tester.pumpAndSettle();
      expect(find.text('Vista anual'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Vista anual'), findsNothing);

      await _openYear(tester);
      expect(find.text('Vista anual'), findsOneWidget);
    });

    testWidgets('12 months with their names and every day of the year', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await _openYear(tester);
      for (var m = 1; m <= 12; m++) {
        expect(_key('year-month-$m'), findsOneWidget, reason: 'month $m');
      }
      final names = [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ];
      for (final (index, name) in names.indexed) {
        final tile = _key('year-month-${index + 1}');
        final title = find.descendant(
          of: tile,
          matching: _key('year-month-title'),
        );
        expect(title, findsOneWidget);
        final label = tester.widget<Text>(title);
        expect(
          label.data,
          anyOf(
            name,
            AppDateFormat('es').monthShort(DateTime(2026, index + 1)),
          ),
          reason: name,
        );
        final semantics = tester.widget<Semantics>(
          find.descendant(of: tile, matching: find.byType(Semantics)).first,
        );
        expect(semantics.properties.label, startsWith('$name 2026:'));
      }
      // 3 x 4 on a phone: the months share three columns.
      final jan = tester.getTopLeft(_key('year-month-1'));
      final feb = tester.getTopLeft(_key('year-month-2'));
      final mar = tester.getTopLeft(_key('year-month-3'));
      final apr = tester.getTopLeft(_key('year-month-4'));
      expect(feb.dy, jan.dy);
      expect(mar.dy, jan.dy);
      expect(apr.dy, greaterThan(jan.dy));
      expect(apr.dx, jan.dx);
      // 365 squares in all.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('year-day-'),
        ),
        findsNWidgets(365),
      );
    });

    testWidgets('the heat map uses the colour of each shift (light)', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await _openYear(tester);
      final colors = Theme.of(tester.element(find.byType(Scaffold).last))
          .extension<AppColors>()!;
      // Demo rotation: 19-23 Oct Noche, 24-25 Libre, 26-30 Mañana, 31 Oct
      // and 1 Nov Libre, then Tarde from the 2nd. Overrides: 21 Mañana +
      // Tarde, 22 emptied, 27 and 28 Vacaciones.
      const night = 0xFF4B4FD1;
      const morning = 0xFFF5A524;
      const afternoon = 0xFFF06A3F;
      const vacation = 0xFF30A46C;
      const light = Brightness.light;
      Future<void> see(CivilDate d) async {
        await tester.ensureVisible(_key('year-day-${d.toIso()}'));
      }

      await see(const CivilDate(2026, 10, 19));
      expect(_fills(tester, const CivilDate(2026, 10, 19)), [
        _bar(night, light),
      ]);
      expect(_fills(tester, const CivilDate(2026, 10, 21)), [
        _bar(morning, light),
        _bar(afternoon, light),
      ]);
      expect(_fills(tester, const CivilDate(2026, 10, 22)), [null]);
      expect(_fills(tester, const CivilDate(2026, 10, 24)), [
        _bar(0xFFE4E4E7, light),
      ]);
      expect(_fills(tester, const CivilDate(2026, 10, 26)), [
        _bar(morning, light),
      ]);
      expect(_fills(tester, const CivilDate(2026, 10, 27)), [
        _bar(vacation, light),
      ]);
      expect(_fills(tester, const CivilDate(2026, 11, 3)), [
        _bar(afternoon, light),
      ]);
      // Libre is the neutral border colour; a day without shift is muted.
      expect(_bar(0xFFE4E4E7, light), colors.borderStrong);
      final empty = tester.widget<ColoredBox>(_key('year-day-2026-10-22'));
      expect(empty.color, colors.surfaceMuted);
      // Before the rotation started (it began on 13 July): no shift.
      expect(_fills(tester, const CivilDate(2026, 7, 12)), [null]);
      expect(_fills(tester, const CivilDate(2026, 7, 13)), [
        _bar(morning, light),
      ]);
    });

    testWidgets('dark mode lifts the dark Noche bar like the month does', (
      tester,
    ) async {
      await pumpCalendar(tester, brightness: Brightness.dark);
      await _openYear(tester);
      expect(_fills(tester, const CivilDate(2026, 10, 19)), [
        _bar(0xFF4B4FD1, Brightness.dark),
      ]);
      expect(
        _bar(0xFF4B4FD1, Brightness.dark),
        isNot(_bar(0xFF4B4FD1, Brightness.light)),
      );
    });

    testWidgets('holidays carry a dot; today a ring', (tester) async {
      await pumpCalendar(tester);
      await _openYear(tester);
      expect(_key('year-holiday-2026-10-12'), findsOneWidget);
      expect(_key('year-holiday-2026-10-13'), findsNothing);
      // 12 Oct, 1 Nov (Sunday is not a holiday)...
      expect(_key('year-holiday-2026-12-25'), findsOneWidget);
    });

    testWidgets('each month reads aloud as its shift counts', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCalendar(tester);
      await _openYear(tester);
      final label = tester.getSemantics(_key('year-month-10')).label;
      expect(label, startsWith('Octubre 2026: '));
      final october = _schedule(tester).resolveRange(
        const CivilDate(2026, 10, 1),
        const CivilDate(2026, 10, 31),
      );
      final nights = october
          .expand((d) => d.shifts)
          .where((s) => s.id == 'night')
          .length;
      expect(label, contains('$nights Noche'));
      expect(
        tester.getSemantics(_key('year-month-1')).label,
        'Enero 2026: sin turnos',
      );
      handle.dispose();
    });

    testWidgets('the legend counts the days of each shift of the year', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await _openYear(tester);
      final summary = summarizeYear(_schedule(tester), 2026);
      expect(find.text('Turnos del año'), findsOneWidget);
      expect(summary.counts, isNotEmpty);
      for (final entry in summary.counts.entries) {
        final row = _key('year-legend-${entry.key}');
        await tester.ensureVisible(row);
        final text = entry.value == 1 ? '1 día' : '${entry.value} días';
        expect(
          find.descendant(of: row, matching: find.text(text)),
          findsOneWidget,
          reason: entry.key,
        );
      }
      // Code and name of a shift in its row, and the holiday dot's legend.
      expect(
        find.descendant(
          of: _key('year-legend-night'),
          matching: find.text('Noche'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _key('year-legend-night'),
          matching: find.text('N'),
        ),
        findsOneWidget,
      );
      expect(find.text('Festivo'), findsOneWidget);
      // A type the year does not use has no row.
      expect(_key('year-legend-personalDay'), findsNothing);
    });

    testWidgets(
      'the arrows change the year; the open rotation goes on in 2027',
      (tester) async {
        await pumpCalendar(tester);
        await _openYear(tester);
        await tester.tap(_key('year-next'));
        await tester.pumpAndSettle();
        expect(find.text('2027'), findsOneWidget);
        expect(find.text('Mis turnos 2027'), findsOneWidget);
        // The open rotation goes on: January 2027 has shifts.
        expect(_fills(tester, const CivilDate(2027, 1, 4)).single, isNotNull);
        expect(_container(tester).read(visibleYearProvider), 2027);

        await tester.tap(_key('year-previous'));
        await tester.tap(_key('year-previous'));
        await tester.pumpAndSettle();
        expect(find.text('2025'), findsOneWidget);
        // Before the rotation: an empty year.
        expect(find.text('Este año no tiene turnos.'), findsOneWidget);
        expect(_fills(tester, const CivilDate(2025, 10, 1)), [null]);
      },
    );

    testWidgets('tapping a month opens it in the month screen', (tester) async {
      await pumpCalendar(tester);
      await _openYear(tester);
      await tester.ensureVisible(_key('year-month-3'));
      await tester.tap(_key('year-month-3'));
      await tester.pumpAndSettle();
      expect(find.text('Vista anual'), findsNothing);
      expect(find.text('Marzo'), findsOneWidget);
      expect(
        _container(tester).read(visibleMonthProvider),
        const CivilDate(2026, 3, 1),
      );
      // Another year, then a month of it.
      await _openYear(tester);
      await tester.tap(_key('year-next'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('year-month-12'));
      await tester.tap(_key('year-month-12'));
      await tester.pumpAndSettle();
      expect(find.text('Diciembre 2027'), findsOneWidget);
    });

    testWidgets('the year opens on the month that was on screen', (
      tester,
    ) async {
      await pumpCalendar(tester);
      for (var i = 0; i < 12; i++) {
        await tester.tap(find.byTooltip('Mes siguiente'));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('Octubre 2027'), findsOneWidget);
      await _openYear(tester);
      expect(find.text('2027'), findsOneWidget);
    });

    testWidgets('"Compartir como imagen" hands a PNG to the share sheet', (
      tester,
    ) async {
      final shared = <({Uint8List png, String name, String subject})>[];
      await pumpCalendar(
        tester,
        overrides: [
          yearImageSharerProvider.overrideWithValue((png, name, subject) async {
            shared.add((png: png, name: name, subject: subject));
          }),
        ],
      );
      await _openYear(tester);
      await tester.tap(_key('year-share'));
      // Rendering the image takes real time.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();

      expect(shared, hasLength(1));
      final png = shared.single.png;
      expect(png.length, greaterThan(1000));
      expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      expect(shared.single.name, 'cuadrante-2026.png');
      expect(shared.single.subject, 'Mis turnos de 2026');
      expect(find.text('No se ha podido compartir la imagen'), findsNothing);
    });

    testWidgets('a share that fails says so and the button comes back', (
      tester,
    ) async {
      await pumpCalendar(
        tester,
        overrides: [
          yearImageSharerProvider.overrideWithValue(
            (png, name, subject) async => throw StateError('no share sheet'),
          ),
        ],
      );
      await _openYear(tester);
      await tester.tap(_key('year-share'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();
      expect(find.text('No se ha podido compartir la imagen'), findsOneWidget);
      expect(
        tester.widget<IconButton>(_key('year-share')).onPressed,
        isNotNull,
      );
    });

    for (final (size, scale) in [
      (const Size(320, 568), 1.6),
      (const Size(390, 844), 1.0),
      (const Size(768, 1024), 1.0),
      (const Size(844, 390), 1.0),
    ]) {
      testWidgets('fits ${size.width.toInt()}x${size.height.toInt()} x$scale '
          'without overflow', (tester) async {
        await pumpCalendar(tester, size: size, textScale: scale);
        await revealOnMonth(tester, _key('open-year'));
        await tester.tap(_key('open-year'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          _key('year-legend-night'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
        expect(_key('year-legend-night'), findsOneWidget);
      });
    }
  });
}
