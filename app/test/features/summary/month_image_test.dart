import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cuadrante/core/icons/app_icons.dart';
import 'package:cuadrante/core/theme/app_colors.dart';
import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:cuadrante/features/schedule/data/demo_schedule.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/summary/presentation/month_image.dart';
import 'package:cuadrante/features/summary/presentation/month_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../schedule/domain/fixtures.dart';

const _oct = CivilDate(2026, 10, 1);
const _feb = CivilDate(2026, 2, 1);

({int width, int height}) _size(Uint8List png) {
  final data = ByteData.sublistView(png);
  return (width: data.getUint32(16), height: data.getUint32(20));
}

final _demo = buildDemoSchedule(const CivilDate(2026, 10, 19));
final _holidays = <CivilDate, Holiday>{
  const CivilDate(2026, 10, 12): const Holiday(
    date: CivilDate(2026, 10, 12),
    name: 'Fiesta Nacional de España',
    scope: HolidayScope.national,
  ),
};

/// Pixel (x, y) of a PNG as 0xRRGGBB.
Future<int> _pixel(Uint8List png, int x, int y) async {
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  final data = (await frame.image.toByteData())!;
  final at = (y * frame.image.width + x) * 4;
  final value =
      (data.getUint8(at) << 16) |
      (data.getUint8(at + 1) << 8) |
      data.getUint8(at + 2);
  frame.image.dispose();
  codec.dispose();
  return value;
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  // The card, drawn off screen: the same tree the PNG is made of.
  Future<void> pump(
    WidgetTester tester, {
    CivilDate month = _oct,
    int weekStart = 1,
  }) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: monthImageTree(
          month: month,
          schedule: _demo,
          holidays: _holidays,
          weekStart: weekStart,
        ),
      ),
    );
  }

  Finder key(String k) => find.byKey(ValueKey(k));

  group('the PNG', () {
    testWidgets('is a 1200 px wide PNG with something drawn in it', (
      tester,
    ) async {
      final png = (await tester.runAsync(
        () => renderMonthImage(
          month: _oct,
          schedule: _demo,
          holidays: _holidays,
          weekStart: 1,
        ),
      ))!;
      expect(png.sublist(0, 8), [
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);
      expect(png.length, greaterThan(5000));
      final size = _size(png);
      expect(size.width, 1200);
      // Title + weekdays + 5 rows of 56 + legend + footer, at 3x.
      expect(size.height, greaterThan(3 * 56 * 5));
      expect(size.height, lessThan(4000 * 3));
    });

    testWidgets('February 2026: five rows from Monday, four from Sunday', (
      tester,
    ) async {
      Future<Uint8List> render(int weekStart) => tester
          .runAsync(
            () => renderMonthImage(
              month: _feb,
              schedule: _demo,
              holidays: const {},
              weekStart: weekStart,
            ),
          )
          .then((png) => png!);
      final monday = _size(await render(1));
      final sunday = _size(await render(7));
      expect(monday.width, sunday.width);
      // 1 February 2026 is a Sunday: Monday-first needs 6 + 28 = 34 cells
      // (5 rows), Sunday-first 28 (4 rows). One row is 64 dp = 192 px at 3x.
      await pump(tester, month: _feb);
      final row = tester.getSize(key('share-day-2026-02-01')).height;
      expect(row, MonthShareCard.minCellHeight);
      expect(monday.height - sunday.height, row * monthImagePixelRatio);
    });

    testWidgets('always the light theme, whatever the platform shows', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final png = (await tester.runAsync(
        () => renderMonthImage(
          month: _oct,
          schedule: _demo,
          holidays: _holidays,
          weekStart: 1,
        ),
      ))!;
      final corner = (await tester.runAsync(() => _pixel(png, 4, 4)))!;
      final light = AppColors.light.background;
      expect(corner, light.toARGB32() & 0xFFFFFF);
      expect(corner, isNot(AppColors.dark.background.toARGB32() & 0xFFFFFF));
    });

    testWidgets('an empty month still renders', (tester) async {
      final png = (await tester.runAsync(
        () => renderMonthImage(
          month: const CivilDate(2024, 2, 1),
          schedule: presetSchedule('6x4', const CivilDate(2026, 1, 1)),
          holidays: const {},
          weekStart: 1,
        ),
      ))!;
      expect(_size(png).width, 1200);
    });
  });

  group('the card', () {
    testWidgets('title, grid of the month, legend with counts and footer', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Octubre 2026'), findsOneWidget);
      expect(find.text('Turnly'), findsOneWidget);
      expect(find.text('Turnos del mes'), findsOneWidget);
      // Every day of the month, none of the neighbouring ones.
      for (var d = 1; d <= 31; d++) {
        expect(
          key('share-day-2026-10-${d.toString().padLeft(2, '0')}'),
          findsOneWidget,
          reason: 'day $d',
        );
      }
      expect(key('share-day-2026-09-30'), findsNothing);
      expect(key('share-day-2026-11-01'), findsNothing);
      // Legend: Noche 5 days (1, 2, 19, 20, 23), Vacaciones 2.
      expect(
        find.descendant(
          of: key('year-legend-night'),
          matching: find.text('5 días'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: key('year-legend-vacation'),
          matching: find.text('2 días'),
        ),
        findsOneWidget,
      );
      expect(key('year-legend-personalDay'), findsNothing);
      // The month has a holiday: its dot and its legend row.
      expect(key('holiday-dot-2026-10-12'), findsOneWidget);
      expect(find.text('Festivo'), findsOneWidget);
    });

    testWidgets('no holiday, no holiday row', (tester) async {
      await pump(tester, month: const CivilDate(2026, 11, 1));
      expect(find.text('Festivo'), findsNothing);
    });

    testWidgets('a short code keeps its normal size in the picture', (
      tester,
    ) async {
      await pump(tester);
      // 19 October is a Noche: a one letter code.
      final code = find.descendant(
        of: key('share-day-2026-10-19'),
        matching: find.text('N'),
      );
      expect(code, findsOneWidget);
      // The row of days is tall enough for the code and its time: the code is
      // drawn at its own size (20 dp), not shrunk.
      expect(
        tester.widget<Text>(code).style!.fontSize,
        20,
        reason: 'the code of the picture keeps its size',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('private things stay out: notes, today\'s ring', (
      tester,
    ) async {
      await pump(tester);
      // 20 October has a note in the demo data.
      expect(_demo.resolve(const CivilDate(2026, 10, 20)).note, isNotNull);
      expect(find.byIcon(AppIcons.note), findsNothing);
      expect(find.textContaining('Marta'), findsNothing);
    });

    testWidgets('the week starts where the preference says', (tester) async {
      await pump(tester);
      double x(String k) => tester.getTopLeft(key(k)).dx;
      // Monday first: L ... D.
      expect(x('share-weekday-1'), lessThan(x('share-weekday-2')));
      expect(x('share-weekday-7'), greaterThan(x('share-weekday-6')));
      // 1 October 2026 is a Thursday: fourth column.
      expect(
        tester.getTopLeft(key('share-day-2026-10-01')).dx,
        closeTo(x('share-weekday-4'), 1),
      );

      await pump(tester, weekStart: 7);
      // Sunday first: D L M ...
      expect(x('share-weekday-7'), lessThan(x('share-weekday-1')));
      expect(x('share-weekday-1'), lessThan(x('share-weekday-2')));
      // Thursday is now the fifth column.
      expect(
        tester.getTopLeft(key('share-day-2026-10-01')).dx,
        closeTo(x('share-weekday-4'), 1),
      );
      expect(
        x('share-weekday-4') - x('share-weekday-7'),
        closeTo(4 * (x('share-weekday-1') - x('share-weekday-7')), 1),
      );
    });
  });
}
