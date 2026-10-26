import 'package:cuadrante/core/theme/shift_palette.dart' show contrastRatio;
import 'package:cuadrante/core/theme/shift_swatch.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/presentation/day_cell.dart'
    show shiftIconFitsInCell;
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import 'harness.dart';

// The icon of a shift type in the month cell (A8, rule in
// docs/motor-de-turnos.md / diseno.md): before the code, only when it fits
// beside it without shrinking the code; never on a double day; the code and
// the colour bar are always there.
//
// The cell keeps the width of its own border free (the thickest one, of a
// chosen day), so the icon needs that room too: the test uses the real font
// (Roboto), the one of a phone, because the test font is about twice as wide
// and no icon would ever fit in a 320 dp phone with it.
//
// Demo data: Noche (code N) 19-23 October. A 3 character shift ZZZ is put on
// the 24th.
const _noche = CivilDate(2026, 10, 20);
const _long = CivilDate(2026, 10, 24);
const _double = CivilDate(2026, 10, 21); // Mañana + Tarde

const _zzz = ShiftType(
  id: 'zzz',
  code: 'ZZZ',
  name: 'Largo',
  colorValue: 0xFF336699,
  category: ShiftCategory.work,
  startMinute: 8 * 60,
  endMinute: 16 * 60,
  icon: ShiftIcon.star,
);

Future<void> _prepare(ScheduleRepository repository) async {
  final night = shiftTemplates
      .firstWhere((t) => t.key == 'night')
      .toShiftType('night')
      .copyWith(icon: ShiftIcon.moon);
  await repository.saveShiftType(night);
  // The morning of the doubled day also has an icon.
  await repository.saveShiftType(
    shiftTemplates
        .firstWhere((t) => t.key == 'morning')
        .toShiftType('morning')
        .copyWith(icon: ShiftIcon.sun),
  );
  await repository.saveShiftType(_zzz);
  await repository.apply(
    'main',
    ScheduleChange(
      patch: EntriesPatch({
        _long: const EntryChange(
          null,
          DayEntry(date: _long, shiftTypeIds: ['zzz']),
        ),
      }),
    ),
  );
}

Finder _inCell(CivilDate date, Finder what) =>
    find.descendant(of: cell(date), matching: what);

Finder _icon(CivilDate date) =>
    _inCell(date, find.byKey(const ValueKey('cell-icon')));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  group('phone, 320 dp wide', () {
    testWidgets('normal text: a one letter code gets its icon before it', (
      tester,
    ) async {
      await pumpCalendar(tester, size: const Size(320, 640), prepare: _prepare);
      expect(_icon(_noche), findsOneWidget);
      expect(_inCell(_noche, find.text('N')), findsOneWidget);
      // The icon is to the left of the code.
      expect(
        tester.getCenter(_icon(_noche)).dx,
        lessThan(tester.getCenter(_inCell(_noche, find.text('N'))).dx),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 3 character code keeps the code alone', (tester) async {
      await pumpCalendar(tester, size: const Size(320, 640), prepare: _prepare);
      expect(_icon(_long), findsNothing);
      expect(_inCell(_long, find.text('ZZZ')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('text x1.3: no room, so the code alone; no overflow', (
      tester,
    ) async {
      await pumpCalendar(
        tester,
        size: const Size(320, 640),
        textScale: 1.3,
        prepare: _prepare,
      );
      expect(_icon(_noche), findsNothing);
      expect(_inCell(_noche, find.text('N')), findsOneWidget);
      expect(_icon(_long), findsNothing);
      expect(_inCell(_long, find.text('ZZZ')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('x$scale: the code is never smaller than without the icon, '
          'every cell has its code', (tester) async {
        await pumpCalendar(
          tester,
          size: const Size(320, 640),
          textScale: scale,
          prepare: _prepare,
        );
        expect(tester.takeException(), isNull);
        // What is drawn (FittedBox included) is as tall as the code of a
        // shift without icon that has the same kind of time line.
        double drawn(CivilDate date, String code) {
          final finder = _inCell(date, find.text(code));
          return tester.getBottomRight(finder).dy -
              tester.getTopLeft(finder).dy;
        }

        final plain = drawn(const CivilDate(2026, 10, 13), 'T');
        expect(drawn(_noche, 'N'), closeTo(plain, 0.5));
      });
    }

    testWidgets('a day with two shifts never carries icons', (tester) async {
      await pumpCalendar(tester, size: const Size(390, 844), prepare: _prepare);
      expect(_icon(_double), findsNothing);
      expect(_inCell(_double, find.text('M')), findsOneWidget);
      expect(_inCell(_double, find.text('T')), findsOneWidget);
    });
  });

  group('wider screens', () {
    testWidgets('a tablet-wide cell has room for the icon of a 3 character '
        'code', (tester) async {
      await pumpCalendar(
        tester,
        size: const Size(1024, 900),
        prepare: _prepare,
      );
      expect(_icon(_long), findsOneWidget);
      expect(_inCell(_long, find.text('ZZZ')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the rule', () {
    const style = TextStyle(fontSize: 20, fontWeight: FontWeight.w800);

    // The cell keeps the width of its own border free (the thickest one, of
    // a chosen day) and the icon keeps a margin of a hairline at each side:
    // icon (12) + gap (2) + code (20) + 7 + 2 = 43 dp of cell.
    const cell = 44.0;

    test('fits when icon + gap + code are narrower than the cell', () {
      expect(
        shiftIconFitsInCell(
          code: 'N',
          codeStyle: style,
          scaler: TextScaler.noScaling,
          width: cell,
        ),
        isTrue,
      );
      expect(
        shiftIconFitsInCell(
          code: 'NNN',
          codeStyle: style,
          scaler: TextScaler.noScaling,
          width: cell,
        ),
        isFalse,
      );
    });

    test('grows with the text scale', () {
      bool fits(double scale) => shiftIconFitsInCell(
        code: 'N',
        codeStyle: style,
        scaler: TextScaler.linear(scale),
        width: cell,
      );
      expect(fits(1.0), isTrue);
      expect(fits(1.3), isFalse);
      expect(fits(2.0), isFalse);
    });
  });

  group('contrast is untouched', () {
    // The icon is drawn in the same ink as the code (checked below), and the
    // ink of every swatch already reaches 4.5:1 on its tint and its disc
    // (test/core/theme/calendar_contrast_test.dart).
    testWidgets('the icon wears the ink of the shift', (tester) async {
      await pumpCalendar(tester, size: const Size(320, 640), prepare: _prepare);
      final icon = tester.widget<Icon>(
        find.descendant(of: _icon(_noche), matching: find.byType(Icon)),
      );
      final night = containerOf(tester)
          .read(scheduleControllerProvider)
          .schedule
          .shiftTypeById('night')!;
      final swatch = ShiftSwatch.forColor(night.colorValue, Brightness.light);
      final code = tester.widget<Text>(_inCell(_noche, find.text('N')));
      expect(icon.color, swatch.ink);
      expect(code.style!.color, swatch.ink);
      expect(contrastRatio(swatch.ink, swatch.tint), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(swatch.ink, swatch.disc), greaterThanOrEqualTo(4.5));
    });
  });

  testWidgets('painting with an icon shift shows the icon in the puck', (
    tester,
  ) async {
    await pumpCalendar(tester, size: const Size(390, 844), prepare: _prepare);
    await enterPaintMode(tester);
    final puck = find.descendant(
      of: find.byKey(const ValueKey('tool-night')),
      matching: find.byKey(const ValueKey('puck-icon')),
    );
    expect(puck, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tool-afternoon')),
        matching: find.byKey(const ValueKey('puck-icon')),
      ),
      findsNothing,
    );
  });
}
