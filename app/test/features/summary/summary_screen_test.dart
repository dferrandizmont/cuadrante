import 'dart:typed_data';

import 'package:cuadrante/app.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/shift_types/presentation/shift_types_screen.dart';
import 'package:cuadrante/features/summary/application/summary_providers.dart';
import 'package:cuadrante/features/year/application/year_providers.dart';
import 'package:cuadrante/features/summary/presentation/month_sharing.dart';
import 'package:cuadrante/features/summary/presentation/summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../calendar/harness.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

/// Texts of the widgets under [key].
String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(_key(key)).data!;

const _minus = '−';
const _nbsp = ' ';

/// Mañana 10,00 EUR/h and Tarde 11,00 EUR/h; Noche stays without a rate.
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

Future<void> _openSummary(WidgetTester tester) async {
  await tester.tap(_key('open-summary'));
  await tester.pumpAndSettle();
  expect(find.byType(SummaryScreen), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, String key) async {
  // Twice: the first scroll moves the lazily built list under the estimate.
  await tester.ensureVisible(_key(key));
  await tester.pump();
  await tester.ensureVisible(_key(key));
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

/// Waits (real time) until [done] holds: PNG encoding runs off the fake
/// clock.
Future<void> _until(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  expect(done(), isTrue, reason: 'the image was never shared');
}

// The demo data around Monday 19 October 2026 (see the QA scenarios): the
// open correturnos rotation puts, in October, Noche on 1, 2, 19, 20 and 23,
// Mañana on 5-9, 26, 29 and 30, Tarde on 12-16 and Libre on nine days;
// 21 October is Mañana + Tarde, 22 is cleared and 27-28 are Vacaciones.
// That is 20 shifts of 8 h = 160 h (72 h Mañana, 48 h Tarde, 40 h Noche, all
// of it night), against 176 h in September and 168 h in November.
void main() {
  group('opening the summary', () {
    testWidgets('from the month title row, on the month on screen', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await _openSummary(tester);
      expect(find.text('Resumen'), findsOneWidget);
      expect(_text(tester, 'summary-period'), 'Octubre 2026');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(MonthScreen), findsOneWidget);

      // Another month of the calendar: that one opens.
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      await _openSummary(tester);
      expect(_text(tester, 'summary-period'), 'Noviembre 2026');
    });

    testWidgets('from the annual view, on the table of the year', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await tester.tap(_key('open-year'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        _key('year-open-summary'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(_key('year-open-summary'));
      await tester.pumpAndSettle();
      expect(find.byType(SummaryScreen), findsOneWidget);
      expect(_text(tester, 'summary-period'), '2026');
      expect(_key('summary-year-total'), findsOneWidget);
    });
  });

  group('the route /resumen', () {
    Future<void> go(WidgetTester tester, String location) async {
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CuadranteApp)),
      );
      container.read(routerProvider).go(location);
      await tester.pumpAndSettle();
    }

    test('builds its location from a month', () {
      expect(
        AppRoutes.summaryFor(const CivilDate(2026, 3, 17)),
        '/resumen?mes=2026-03',
      );
      expect(
        AppRoutes.summaryFor(const CivilDate(2026, 10, 1), year: true),
        '/resumen?mes=2026-10&vista=ano',
      );
    });

    testWidgets('?mes opens that month, ?vista=ano the year table', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await go(tester, '/resumen?mes=2027-03');
      expect(_text(tester, 'summary-period'), 'Marzo 2027');
      await go(tester, '/resumen?mes=2026-11&vista=ano');
      expect(_text(tester, 'summary-period'), '2026');
      expect(_key('summary-year-total'), findsOneWidget);
    });

    testWidgets('a bad ?mes falls back to the month on the calendar', (
      tester,
    ) async {
      await pumpCalendar(tester);
      for (final bad in ['2026-13', 'octubre', '2026-1', '']) {
        await go(tester, '/resumen?mes=$bad');
        expect(_text(tester, 'summary-period'), 'Octubre 2026', reason: bad);
      }
      await go(tester, '/resumen');
      expect(_text(tester, 'summary-period'), 'Octubre 2026');
    });
  });

  group('month summary', () {
    for (final doubled in [false, true]) {
      testWidgets(
        doubled
            ? 'two shifts on one day keep the worked-days detail'
            : 'one shift per day hides the repeated worked-days detail',
        (tester) async {
          await pumpCalendar(tester);
          // June predates the demo rotation: only this day has work.
          containerOf(tester)
              .read(scheduleControllerProvider.notifier)
              .setDayShifts(
                const CivilDate(2026, 6, 21),
                doubled ? const ['morning', 'afternoon'] : const ['morning'],
              );
          await tester.pumpAndSettle();
          containerOf(tester).read(routerProvider).go('/resumen?mes=2026-06');
          await tester.pumpAndSettle();

          expect(find.byType(SummaryScreen), findsOneWidget);
          expect(_text(tester, 'summary-shifts-value'), doubled ? '2' : '1');
          if (doubled) {
            expect(_text(tester, 'summary-shifts-detail'), '1 día');
          } else {
            expect(_key('summary-shifts-detail'), findsNothing);
          }
        },
      );
    }

    testWidgets('hours, shifts, night hours, rest days, absences, holidays', (
      tester,
    ) async {
      await pumpCalendar(tester, prepare: _rates);
      await _openSummary(tester);

      expect(_text(tester, 'summary-hours'), '160 h');
      expect(_text(tester, 'summary-shifts-value'), '20');
      expect(find.text('19 días'), findsOneWidget);
      expect(_text(tester, 'summary-night-value'), '40 h');
      expect(_text(tester, 'summary-rest-value'), '9');
      expect(_text(tester, 'summary-absences-value'), '2');
      // 12 October, the national holiday, is a Tarde.
      expect(_text(tester, 'summary-holiday-value'), '8 h');
      expect(find.text('1 turno en festivo'), findsOneWidget);
    });

    testWidgets('compared with the previous month', (tester) async {
      await pumpCalendar(tester, prepare: _rates);
      await _openSummary(tester);
      expect(
        _text(tester, 'summary-delta'),
        '${_minus}16 h respecto a septiembre',
      );
      await _tap(tester, 'summary-next');
      expect(_text(tester, 'summary-period'), 'Noviembre 2026');
      expect(_text(tester, 'summary-hours'), '168 h');
      expect(_text(tester, 'summary-delta'), '+8 h respecto a octubre');
    });

    testWidgets('per shift type: days, hours, night hours and pay', (
      tester,
    ) async {
      await pumpCalendar(tester, prepare: _rates);
      await _openSummary(tester);

      Finder inRow(String id, String text) => find.descendant(
        of: _key('summary-type-$id'),
        matching: find.text(text),
      );
      // Mañana: 9 days (the 21st is Mañana + Tarde).
      expect(inRow('morning', '9 días'), findsOneWidget);
      expect(_text(tester, 'summary-type-hours-morning'), '72 h');
      expect(_text(tester, 'summary-type-pay-morning'), '720,00$_nbsp€');
      expect(inRow('afternoon', '6 días'), findsOneWidget);
      expect(_text(tester, 'summary-type-hours-afternoon'), '48 h');
      expect(_text(tester, 'summary-type-pay-afternoon'), '528,00$_nbsp€');
      // Noche has no rate: "sin precio" and night hours.
      expect(inRow('night', '5 días'), findsOneWidget);
      expect(
        _text(tester, 'summary-type-hours-night'),
        '40 h · 40 h nocturnas',
      );
      expect(_key('summary-type-pay-night'), findsNothing);
      expect(_text(tester, 'summary-type-norate-night'), 'sin precio');
      // Rest and absences.
      expect(inRow('rest', '9 días'), findsOneWidget);
      expect(inRow('vacation', '2 días'), findsOneWidget);
      expect(find.text('Turnos de trabajo'), findsOneWidget);
      expect(find.text('Descansos'), findsOneWidget);
      expect(find.text('Ausencias'), findsWidgets);
    });

    testWidgets('estimated pay: only the types with a rate, and what is '
        'missing', (tester) async {
      await pumpCalendar(tester, prepare: _rates);
      await _openSummary(tester);
      // 72 h x 10 + 48 h x 11 = 1.248,00.
      expect(_text(tester, 'summary-earnings'), '1.248,00$_nbsp€');
      expect(_key('summary-fixed-plus'), findsNothing);
      expect(find.text('Estimado, antes de impuestos'), findsOneWidget);
      expect(
        _text(tester, 'summary-earnings-missing'),
        'No incluye el pago por hora de Noche: sin precio.',
      );
      // The way to fix it: Mis turnos.
      await _tap(tester, 'summary-rate-action');
      expect(find.byType(ShiftTypesScreen), findsOneWidget);
    });

    testWidgets('without any rate there is a hint instead of a total', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await _openSummary(tester);
      expect(_key('summary-earnings'), findsNothing);
      expect(
        _text(tester, 'summary-earnings-none'),
        'Pon el precio por hora o el plus por turno en Mis turnos para ver el '
        'estimado.',
      );
      expect(_key('summary-rate-action'), findsOneWidget);
      // Every worked type says so in its row.
      for (final id in ['morning', 'afternoon', 'night']) {
        expect(_key('summary-type-norate-$id'), findsOneWidget, reason: id);
      }
    });

    testWidgets('fixed pluses alone show a total and their shift count', (
      tester,
    ) async {
      await pumpCalendar(
        tester,
        prepare: (repository) async {
          await repository.saveShiftType(
            shiftTemplates
                .firstWhere((type) => type.key == 'night')
                .toShiftType('night')
                .copyWith(fixedPlusCents: 3000),
          );
        },
      );
      await _openSummary(tester);
      expect(_text(tester, 'summary-earnings'), '150,00$_nbsp€');
      expect(_text(tester, 'summary-fixed-plus-value'), '150,00$_nbsp€');
      expect(_text(tester, 'summary-fixed-plus-detail'), '5 turnos');
      expect(find.text('Pluses'), findsOneWidget);
      expect(_key('summary-earnings-none'), findsNothing);
      expect(
        _text(tester, 'summary-earnings-missing'),
        contains('pago por hora'),
      );
    });

    for (final earlyLeave in [false, true]) {
      testWidgets(
        earlyLeave
            ? 'month and range keep the fixed plus when early leave removes all hours'
            : 'month and range show the fixed plus of a shift without times',
        (tester) async {
          await pumpCalendar(
            tester,
            prepare: (repository) async {
              await repository.saveShiftType(
                ShiftType(
                  id: 'plus-only',
                  code: 'P',
                  name: 'Plus',
                  colorValue: 0xFF4B4FD1,
                  category: ShiftCategory.work,
                  startMinute: earlyLeave ? 360 : null,
                  endMinute: earlyLeave ? 840 : null,
                  hourlyRateCents: earlyLeave ? 1000 : null,
                  fixedPlusCents: 3000,
                ),
              );
            },
          );
          final container = containerOf(tester);
          final controller = container.read(scheduleControllerProvider.notifier);
          // June is before the demo rotation: this is its only shift.
          const day = CivilDate(2026, 6, 21);
          controller.setDayShifts(day, const ['plus-only']);
          if (earlyLeave) {
            controller.setDayExtras(day, earlyLeaveMinutes: 480);
          }
          await tester.pumpAndSettle();
          container.read(routerProvider).go('/resumen?mes=2026-06');
          await tester.pumpAndSettle();

          for (final range in [false, true]) {
            if (range) await _tap(tester, 'summary-mode-range');
            expect(_text(tester, 'summary-hours'), '0 h');
            expect(_key('summary-estimate'), findsOneWidget);
            expect(_text(tester, 'summary-earnings'), '30,00$_nbsp€');
            expect(_text(tester, 'summary-fixed-plus-value'), '30,00$_nbsp€');
            expect(_text(tester, 'summary-fixed-plus-detail'), '1 turno');
            if (earlyLeave) {
              expect(_text(tester, 'summary-early-leave-value'), '${_minus}8 h');
            }
          }
        },
      );
    }

    testWidgets('the notes say how the hours are counted', (tester) async {
      await pumpCalendar(tester);
      await _openSummary(tester);
      await tester.ensureVisible(_key('summary-notes'));
      expect(
        find.textContaining('turno que cruza la medianoche'),
        findsOneWidget,
      );
      expect(find.textContaining('cambio de hora'), findsOneWidget);
    });

    testWidgets('a month without shifts says so', (tester) async {
      await pumpCalendar(tester);
      await _openSummary(tester);
      // The rotation began in July: June is empty.
      for (var i = 0; i < 4; i++) {
        await _tap(tester, 'summary-previous');
      }
      expect(_text(tester, 'summary-period'), 'Junio 2026');
      expect(_key('summary-empty'), findsOneWidget);
      expect(find.text('Sin turnos este mes'), findsOneWidget);
      expect(_key('summary-hours'), findsNothing);
      expect(_key('summary-estimate'), findsNothing);
    });

    testWidgets('painting a day is reflected when coming back', (tester) async {
      await pumpCalendar(tester);
      await _openSummary(tester);
      expect(_text(tester, 'summary-hours'), '160 h');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SummaryScreen)),
      );
      // 22 October was cleared: give it a Mañana (+8 h).
      container.read(scheduleControllerProvider.notifier).setDayShifts(
        const CivilDate(2026, 10, 22),
        const ['morning'],
      );
      await tester.pumpAndSettle();
      expect(_text(tester, 'summary-hours'), '168 h');
    });
  });

  group('dates range (Fechas…)', () {
    /// Picks [day] of the month the open calendar dialog is on.
    Future<void> pickDay(WidgetTester tester, String day) async {
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text(day),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is Text && w.data?.toLowerCase() == 'aceptar',
        ),
      );
      await tester.pumpAndSettle();
      // Opening the row scrolled the list: back to the top, where the dates
      // and the mode pills are.
      await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
      await tester.pumpAndSettle();
    }

    testWidgets('starts on the month on screen and gives the same figures', (
      tester,
    ) async {
      await pumpCalendar(tester, prepare: _rates);
      await _openSummary(tester);
      final monthHours = _text(tester, 'summary-hours');
      final monthEstimate = _text(tester, 'summary-earnings');

      await _tap(tester, 'summary-mode-range');
      expect(_text(tester, 'summary-period'), '1 oct 2026 – 31 oct 2026');
      expect(_text(tester, 'summary-range-days'), startsWith('31 días'));
      expect(_text(tester, 'summary-hours'), monthHours);
      expect(_text(tester, 'summary-earnings'), monthEstimate);
      expect(_text(tester, 'summary-hours'), '160 h');
      // No month-bound actions: the share image is only for months.
      expect(_key('summary-share'), findsNothing);
      // Back to the month.
      await _tap(tester, 'summary-mode-month');
      expect(_text(tester, 'summary-period'), 'Octubre 2026');
      expect(_key('summary-share'), findsOneWidget);
    });

    testWidgets('Desde and Hasta choose the days, the figures follow', (
      tester,
    ) async {
      await pumpCalendar(tester, prepare: _rates);
      await _openSummary(tester);
      await _tap(tester, 'summary-mode-range');

      await _tap(tester, 'summary-range-from');
      await pickDay(tester, '19');
      expect(_text(tester, 'summary-period'), '19 oct 2026 – 31 oct 2026');
      expect(_text(tester, 'summary-hours'), '64 h');

      await _tap(tester, 'summary-range-to');
      await pickDay(tester, '25');
      expect(_text(tester, 'summary-period'), '19 oct 2026 – 25 oct 2026');
      expect(_text(tester, 'summary-range-days'), startsWith('7 días'));
      // Noche 19, 20 and 23, and Mañana + Tarde on the 21st: 5 shifts.
      expect(_text(tester, 'summary-shifts-value'), '5');
      expect(_text(tester, 'summary-hours'), '40 h');
      expect(_text(tester, 'summary-night-value'), '24 h');
      // Compared with the 7 days before (12-18 October: five Tardes).
      expect(
        _text(tester, 'summary-delta'),
        'Las mismas horas que en los 7 días anteriores',
      );
      expect(find.textContaining('en el mes en que empieza'), findsNothing);
    });

    testWidgets('the arrows move the dates by their own length', (
      tester,
    ) async {
      await pumpCalendar(tester, prepare: _rates);
      await _openSummary(tester);
      await _tap(tester, 'summary-mode-range');
      await _tap(tester, 'summary-range-from');
      await pickDay(tester, '19');
      await _tap(tester, 'summary-range-to');
      await pickDay(tester, '25');

      await _tap(tester, 'summary-next');
      expect(_text(tester, 'summary-period'), '26 oct 2026 – 1 nov 2026');
      // Mañana 26, 29 and 30 (27-28 are Vacaciones).
      expect(_text(tester, 'summary-shifts-value'), '3');
      await _tap(tester, 'summary-previous');
      await _tap(tester, 'summary-previous');
      expect(_text(tester, 'summary-period'), '12 oct 2026 – 18 oct 2026');
      expect(_text(tester, 'summary-hours'), '40 h');
    });

    testWidgets('a "Hasta" before "Desde" makes a single day', (tester) async {
      await pumpCalendar(tester, prepare: _rates);
      await _openSummary(tester);
      await _tap(tester, 'summary-mode-range');
      // From the 31st: the end follows.
      await _tap(tester, 'summary-range-from');
      await pickDay(tester, '30');
      await _tap(tester, 'summary-range-from');
      await pickDay(tester, '31');
      expect(_text(tester, 'summary-period'), '31 oct 2026 – 31 oct 2026');
      expect(_text(tester, 'summary-range-days'), startsWith('1 día'));
    });

    testWidgets('dates with no shifts say so', (tester) async {
      await pumpCalendar(tester);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CuadranteApp)),
      );
      container.read(routerProvider).go('/resumen?mes=2026-05');
      await tester.pumpAndSettle();
      await _tap(tester, 'summary-mode-range');
      expect(_text(tester, 'summary-period'), '1 may 2026 – 31 may 2026');
      expect(_key('summary-empty'), findsOneWidget);
      expect(find.text('Sin turnos en estas fechas'), findsOneWidget);
    });

    testWidgets('the range keeps its dates when switching to the month and '
        'back', (tester) async {
      await pumpCalendar(tester, prepare: _rates);
      await _openSummary(tester);
      await _tap(tester, 'summary-mode-range');
      await _tap(tester, 'summary-range-from');
      await pickDay(tester, '19');
      await _tap(tester, 'summary-mode-year');
      expect(_key('summary-year-total'), findsOneWidget);
      await _tap(tester, 'summary-mode-range');
      expect(_text(tester, 'summary-period'), '19 oct 2026 – 31 oct 2026');
    });
  });

  group('year table', () {
    testWidgets('twelve months, totals and a tap to open a month', (
      tester,
    ) async {
      await pumpCalendar(tester, prepare: _rates);
      await _openSummary(tester);
      await _tap(tester, 'summary-mode-year');
      expect(_text(tester, 'summary-period'), '2026');
      for (var m = 1; m <= 12; m++) {
        expect(_key('summary-year-row-$m'), findsOneWidget, reason: '$m');
      }
      // October: 20 shifts, 160 h, 40 h at night, 1.248,00 EUR.
      final october = find.descendant(
        of: _key('summary-year-row-10'),
        matching: find.byType(Text),
      );
      expect(tester.widgetList<Text>(october).map((t) => t.data), [
        'Oct',
        '20',
        '160 h',
        '40 h',
        '1.248,00$_nbsp€',
      ]);
      // A month before the rotation: dashes.
      final january = find.descendant(
        of: _key('summary-year-row-1'),
        matching: find.byType(Text),
      );
      expect(tester.widgetList<Text>(january).map((t) => t.data), [
        'Ene',
        '–',
        '–',
        '–',
        '–',
      ]);
      // The total is the sum of the months.
      final total = find.descendant(
        of: _key('summary-year-total'),
        matching: find.byType(Text),
      );
      final cells = tester.widgetList<Text>(total).map((t) => t.data).toList();
      expect(cells.first, 'Total');
      final totals = ProviderScope.containerOf(
        tester.element(find.byType(SummaryScreen)),
      ).read(yearTotalsProvider(2026));
      expect(cells[1], '${totals.shiftsWorked}');
      expect(totals.shiftsWorked, greaterThan(20));
      expect(cells[2], endsWith(' h'));

      await _tap(tester, 'summary-year-row-10');
      expect(_text(tester, 'summary-period'), 'Octubre 2026');
      expect(_text(tester, 'summary-hours'), '160 h');
    });

    testWidgets('the arrows change the year; an empty year says so', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await _openSummary(tester);
      await _tap(tester, 'summary-mode-year');
      await _tap(tester, 'summary-previous');
      expect(_text(tester, 'summary-period'), '2025');
      expect(_key('summary-year-empty'), findsOneWidget);
      await _tap(tester, 'summary-next');
      await _tap(tester, 'summary-next');
      expect(_text(tester, 'summary-period'), '2027');
      expect(_key('summary-year-total'), findsOneWidget);
    });
  });

  group('sharing the month as an image', () {
    ({
      List<({Uint8List png, String name, String subject})> shared,
      Override override,
    })
    recorder() {
      final shared = <({Uint8List png, String name, String subject})>[];
      return (
        shared: shared,
        override: monthImageSharerProvider.overrideWithValue((
          png,
          name,
          subject,
        ) async {
          shared.add((png: png, name: name, subject: subject));
        }),
      );
    }

    testWidgets('from the month screen', (tester) async {
      final rec = recorder();
      await pumpCalendar(tester, overrides: [rec.override]);
      await tester.tap(_key('share-month'));
      await _until(tester, () => rec.shared.isNotEmpty);
      await tester.pumpAndSettle();
      expect(rec.shared, hasLength(1));
      final shared = rec.shared.single;
      expect(shared.name, 'cuadrante-2026-10.png');
      expect(shared.subject, 'Mis turnos de octubre 2026');
      expect(shared.png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      expect(find.text('No se ha podido compartir la imagen'), findsNothing);
    });

    testWidgets('from the summary, for the month it shows', (tester) async {
      final rec = recorder();
      await pumpCalendar(tester, overrides: [rec.override]);
      await _openSummary(tester);
      await _tap(tester, 'summary-next');
      await tester.tap(_key('summary-share'));
      await _until(tester, () => rec.shared.isNotEmpty);
      await tester.pumpAndSettle();
      expect(rec.shared.single.name, 'cuadrante-2026-11.png');
      expect(rec.shared.single.subject, 'Mis turnos de noviembre 2026');
    });

    testWidgets('H-T08-5: the year shares the picture of the annual view, '
        'not the range', (tester) async {
      final shared = <({Uint8List png, String name, String subject})>[];
      await pumpCalendar(
        tester,
        overrides: [
          yearImageSharerProvider.overrideWithValue((png, name, subject) async {
            shared.add((png: png, name: name, subject: subject));
          }),
        ],
      );
      await _openSummary(tester);
      await _tap(tester, 'summary-mode-year');
      expect(_key('summary-share'), findsOneWidget);
      await tester.tap(_key('summary-share'));
      await _until(tester, () => shared.isNotEmpty);
      await tester.pumpAndSettle();
      expect(shared, hasLength(1));
      expect(shared.single.name, 'cuadrante-2026.png');
      expect(shared.single.subject, 'Mis turnos de 2026');
      expect(shared.single.png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      expect(find.text('No se ha podido compartir la imagen'), findsNothing);

      // «Fechas…» has none.
      await _tap(tester, 'summary-mode-range');
      expect(_key('summary-share'), findsNothing);
    });

    testWidgets('H-T08-5: the picture of the year is the one of the annual '
        'view (same size, no hours or pay)', (tester) async {
      final fromSummary = <Uint8List>[];
      final fromYearView = <Uint8List>[];
      await pumpCalendar(
        tester,
        overrides: [
          yearImageSharerProvider.overrideWithValue((png, name, subject) async {
            (fromSummary.isEmpty ? fromSummary : fromYearView).add(png);
          }),
        ],
      );
      await _openSummary(tester);
      await _tap(tester, 'summary-mode-year');
      await tester.tap(_key('summary-share'));
      await _until(tester, () => fromSummary.isNotEmpty);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(_key('open-year'));
      await tester.pumpAndSettle();
      await tester.tap(_key('year-share'));
      await _until(tester, () => fromYearView.isNotEmpty);
      await tester.pumpAndSettle();

      int width(Uint8List png) => ByteData.sublistView(png).getUint32(16);
      // The summary draws it at 400 dp x 3; the screen at its own width x 3.
      expect(width(fromSummary.single), 1200);
      expect(width(fromYearView.single), 390 * 3);
    });

    testWidgets('the share button is not in paint mode', (tester) async {
      await pumpCalendar(tester);
      expect(_key('share-month'), findsOneWidget);
      await enterPaintMode(tester);
      expect(_key('share-month'), findsNothing);
    });

    testWidgets('a share that fails says so and can be tried again', (
      tester,
    ) async {
      var attempts = 0;
      await pumpCalendar(
        tester,
        overrides: [
          monthImageSharerProvider.overrideWithValue((
            png,
            name,
            subject,
          ) async {
            attempts++;
            throw StateError('no share sheet');
          }),
        ],
      );
      await tester.tap(_key('share-month'));
      await _until(tester, () => attempts == 1);
      await tester.pumpAndSettle();
      expect(find.text('No se ha podido compartir la imagen'), findsOneWidget);
      expect(
        tester.widget<IconButton>(_key('share-month')).onPressed,
        isNotNull,
      );
    });
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.6),
    (const Size(390, 844), 1.0),
    (const Size(768, 1024), 1.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('fits ${size.width.toInt()}x${size.height.toInt()} '
        'x$scale without overflow', (tester) async {
      await pumpCalendar(tester, size: size, textScale: scale, prepare: _rates);
      await revealOnMonth(tester, _key('open-summary'));
      await tester.tap(_key('open-summary'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        _key('summary-notes'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        _key('summary-mode-year'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      // The free range, with its dates and long label.
      await tester.tap(_key('summary-mode-range'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        _key('summary-notes'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        _key('summary-mode-year'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(_key('summary-mode-year'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        _key('summary-year-total'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
