import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/features/calendar/presentation/day_cell.dart'
    show cellTimeInCell;
import 'package:cuadrante/features/calendar/presentation/shift_format.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import 'harness.dart';
import 'rendered_cell_text.dart';

// Turno partido (A12) on screen. Demo data around Monday 19 October 2026
// (Noche 19-23, Libre 24-25, Mañana 26-30). The 19th (today) and the 24th
// become «Partido»: 09:00-13:00 and 17:00-21:00; the 20th stays a Noche.
const _today = CivilDate(2026, 10, 19);
const _night = CivilDate(2026, 10, 20);
const _sat = CivilDate(2026, 10, 24);

const _partido = ShiftType(
  id: 'partido',
  code: 'P',
  name: 'Partido',
  colorValue: 0xFF15AABF,
  category: ShiftCategory.work,
  startMinute: 9 * 60,
  endMinute: 13 * 60,
  segment2StartMinute: 17 * 60,
  segment2DurationMinutes: 4 * 60,
);

Future<void> _prepare(ScheduleRepository repository) async {
  await repository.saveShiftType(_partido);
  await repository.apply(
    'main',
    ScheduleChange(
      patch: EntriesPatch({
        for (final d in [_today, _sat])
          d: EntryChange(
            null,
            DayEntry(date: d, shiftTypeIds: const ['partido']),
          ),
      }),
    ),
  );
}

Finder _inCell(CivilDate date, Finder what) =>
    find.descendant(of: cell(date), matching: what);

DateTime _at(int hour, [int minute = 0]) =>
    DateTime(2026, 10, 19, hour, minute);

void main() {
  setUpAll(initializeLocale);

  group('the day cell', () {
    testWidgets('the split shift says when it starts when its two ranges do '
        'not fit', (tester) async {
      // 390 dp: cells of 53 dp. "22–06" is shown (it may shrink a little, as
      // always); the two full ranges of the split shift ("09–13/17–21")
      // would have to shrink a lot, so the cell says when each range starts
      // ("09/17", H-T23-1): never the code alone.
      await pumpCalendar(tester, prepare: _prepare);
      expect(_inCell(_night, find.text('22–06')), findsOneWidget);
      expect(_inCell(_sat, find.text('P')), findsOneWidget);
      expect(_inCell(_sat, find.text('09/17')), findsOneWidget);
      expect(_inCell(_sat, find.text('09–13/17–21')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('and with bigger text the cell keeps the code', (tester) async {
      // With big text there is no room for a time line in a cell of the
      // month (not even for a normal shift): the code stays and nothing
      // spills.
      await pumpCalendar(tester, textScale: 1.3, prepare: _prepare);
      expect(_inCell(_sat, find.text('P')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320 dp: the code, no overflow, text x1.0 and x1.3', (
      tester,
    ) async {
      for (final scale in [1.0, 1.3]) {
        await pumpCalendar(
          tester,
          size: const Size(320, 844),
          textScale: scale,
          prepare: _prepare,
        );
        expect(tester.takeException(), isNull, reason: 'x$scale');
        expect(
          _inCell(_sat, find.text('P')),
          findsOneWidget,
          reason: 'x$scale',
        );
        // The whole range of the split shift does not fit in a cell that
        // narrow: the cell says when it starts (H-T18-6), and the code is
        // there with it.
        expect(
          _inCell(_sat, find.text('09')),
          findsOneWidget,
          reason: 'x$scale',
        );
        expect(
          _inCell(_sat, find.textContaining('09–13/17–21')),
          findsNothing,
          reason: 'x$scale',
        );
        // Even the two starts do not fit: the dot says the shift has two
        // segments (H-T23-1).
        expect(
          _inCell(_sat, find.byKey(const ValueKey('cell-two-segments'))),
          findsOneWidget,
          reason: 'x$scale',
        );
      }
    });

    testWidgets('320 dp with text x2.0: the code is there and nothing spills', (
      tester,
    ) async {
      await pumpCalendar(
        tester,
        size: const Size(320, 844),
        textScale: 2.0,
        prepare: _prepare,
      );
      await revealCell(tester, _sat);
      expect(tester.takeException(), isNull);
      expect(_inCell(_sat, find.text('P')), findsOneWidget);
      final start = _inCell(_sat, find.text('09'));
      expect(start, findsOneWidget);
      final startRect = renderedTextRect(tester, start);
      final bounds = tester.getRect(cell(_sat));
      expect(bounds.contains(startRect.topLeft), isTrue);
      expect(bounds.contains(startRect.bottomRight), isTrue);
      expectUnscaledCellText(tester, _inCell(_sat, find.text('P')));
      expect(
        _inCell(_sat, find.byKey(const ValueKey('cell-two-segments'))),
        findsOneWidget,
      );
      expect(_inCell(_sat, find.textContaining('09–13/17–21')), findsNothing);
    });

    testWidgets('when it fits the cell shows both ranges: 09–13/17–21', (
      tester,
    ) async {
      // The test font is far wider than a real one, so small text stands in
      // for a roomy cell: 700 dp wide, text x0.5.
      await pumpCalendar(
        tester,
        size: const Size(700, 1400),
        textScale: 0.5,
        prepare: _prepare,
      );
      expect(tester.takeException(), isNull);
      expect(_inCell(_sat, find.text('P')), findsOneWidget);
      expect(_inCell(_sat, find.text('09–13/17–21')), findsOneWidget);
      expect(_inCell(_night, find.text('22–06')), findsOneWidget);
    });

    testWidgets('the rule measures the text with the user\'s scale', (
      tester,
    ) async {
      await pumpCalendar(tester, size: const Size(320, 640), prepare: _prepare);
      final context = tester.element(cell(_sat));
      final style = context.type.cellTime;
      // The two full ranges fit in a cell of 100 dp with the normal text,
      // and not once the text is 30 % bigger.
      const width = 100.0;
      final atOne = cellTimeInCell(
        shift: _partido,
        style: style,
        scaler: TextScaler.noScaling,
        width: width,
      );
      expect(atOne!.text, '09–13/17–21');
      final atOneThree = cellTimeInCell(
        shift: _partido,
        style: style,
        scaler: const TextScaler.linear(1.3),
        width: width,
      );
      expect(atOneThree!.text, '09/17');
    });

    testWidgets('the spoken label gives both ranges', (tester) async {
      await pumpCalendar(tester, prepare: _prepare);
      final semantics = tester.getSemantics(cell(_sat));
      expect(
        semantics.label,
        contains('Partido de 09:00 a 13:00 y de 17:00 a 21:00'),
      );
    });
  });

  group('the split shift in the cell (H-T23-1)', () {
    testWidgets('says when each range starts: 09/17', (tester) async {
      await pumpCalendar(tester, prepare: _prepare);
      expect(_inCell(_sat, find.text('09/17')), findsOneWidget);
      // The two full ranges do not fit in a cell of the month: the code is
      // not shrunk to make them fit.
      expect(_inCell(_sat, find.text('09–13/17–21')), findsNothing);
      expect(_inCell(_sat, find.text('P')), findsOneWidget);
      // The dot is only for the cells that cannot say both starts.
      expect(
        _inCell(_sat, find.byKey(const ValueKey('cell-two-segments'))),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('when even the two starts do not fit: the start and a dot', (
      tester,
    ) async {
      await pumpCalendar(tester, size: const Size(320, 844), prepare: _prepare);
      await revealCell(tester, _sat);
      expect(_inCell(_sat, find.text('09')), findsOneWidget);
      expect(_inCell(_sat, find.text('09/17')), findsNothing);
      expect(
        _inCell(_sat, find.byKey(const ValueKey('cell-two-segments'))),
        findsOneWidget,
      );
      // The code is whole: the split shift does not shrink it.
      expect(_inCell(_sat, find.text('P')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the code is as big as the code of a normal shift', (
      tester,
    ) async {
      await pumpCalendar(tester, prepare: _prepare);
      final split = tester.widget<Text>(_inCell(_sat, find.text('P'))).style!;
      final night = tester.widget<Text>(_inCell(_night, find.text('N'))).style!;
      expect(split.fontSize, night.fontSize);
      expectUnscaledCellText(tester, _inCell(_sat, find.text('P')));
      expectUnscaledCellText(tester, _inCell(_night, find.text('N')));
      expect(
        renderedTextRect(tester, _inCell(_sat, find.text('P'))).height,
        closeTo(
          renderedTextRect(tester, _inCell(_night, find.text('N'))).height,
          0.01,
        ),
      );
    });

    testWidgets('320x640 text x2: minute starts retain an hour and the split '
        'marker without shrinking the code', (tester) async {
      // Reading the font files is real I/O: inside a widget test (fake time)
      // it has to run outside it, or it never finishes.
      expect(await tester.runAsync(loadRoboto), isTrue);
      addTearDown(() => AppTypography.debugFamily = null);
      final semantics = tester.ensureSemantics();
      final minuteShift = _partido.copyWith(
        startMinute: 9 * 60 + 30,
        segment2StartMinute: 17 * 60 + 45,
      );
      await pumpCalendar(
        tester,
        size: const Size(320, 640),
        textScale: 2,
        prepare: (repository) async {
          await _prepare(repository);
          await repository.saveShiftType(minuteShift);
        },
      );
      await revealCell(tester, _sat);
      final code = _inCell(_sat, find.text('P'));
      final start = _inCell(_sat, find.text('09'));
      final marker = _inCell(
        _sat,
        find.byKey(const ValueKey('cell-two-segments')),
      );
      expect(marker, findsOneWidget);
      final bounds = tester.getRect(cell(_sat));
      expect(
        renderedTextRect(tester, code).height,
        greaterThanOrEqualTo(tester.element(code).type.cellCode.fontSize!),
      );
      for (final text in [code, start]) {
        expectUnscaledCellText(tester, text);
        final rect = renderedTextRect(tester, text);
        expect(bounds.contains(rect.topLeft), isTrue);
        expect(bounds.contains(rect.bottomRight), isTrue);
      }
      final markerRect = tester.getRect(marker);
      expect(bounds.contains(markerRect.topLeft), isTrue);
      expect(bounds.contains(markerRect.bottomRight), isTrue);
      expect(
        markerRect.left,
        greaterThanOrEqualTo(renderedTextRect(tester, start).right),
      );
      expect(
        tester.getSemantics(cell(_sat)).label,
        contains('09:30 a 13:00 y de 17:45 a 21:45'),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  });

  group('the day detail', () {
    testWidgets('shows both ranges of the split shift', (tester) async {
      await pumpCalendar(tester, prepare: _prepare);
      await tester.ensureVisible(cell(_sat));
      await tester.pumpAndSettle();
      await tester.tap(cell(_sat));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('09:00–13:00 · 17:00–21:00'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('at 320 dp and text x1.3 the line fits', (tester) async {
      await pumpCalendar(
        tester,
        size: const Size(320, 844),
        textScale: 1.3,
        prepare: _prepare,
      );
      await tester.ensureVisible(cell(_sat));
      await tester.pumpAndSettle();
      await tester.tap(cell(_sat));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.textContaining('09:00–13:00'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('the card of today', () {
    testWidgets('before the first segment: HOY, both ranges, countdown', (
      tester,
    ) async {
      await pumpCalendar(tester, clock: () => _at(8), prepare: _prepare);
      expect(find.text('HOY'), findsOneWidget);
      expect(find.text('Partido'), findsWidgets);
      expect(find.text('09:00–13:00 · 17:00–21:00'), findsOneWidget);
      expect(find.text('Empieza en 1 h'), findsOneWidget);
    });

    testWidgets('inside the first segment: it ends at 13:00', (tester) async {
      await pumpCalendar(tester, clock: () => _at(11, 30), prepare: _prepare);
      expect(find.text('AHORA'), findsOneWidget);
      expect(find.text('Hasta las 13:00'), findsOneWidget);
      expect(find.text('Termina en 1 h 30 min'), findsOneWidget);
    });

    testWidgets('in the gap: back at 17:00', (tester) async {
      await pumpCalendar(tester, clock: () => _at(14, 15), prepare: _prepare);
      expect(find.text('DESCANSO'), findsOneWidget);
      expect(find.text('Vuelves a las 17:00'), findsOneWidget);
      expect(find.text('Vuelves en 2 h 45 min'), findsOneWidget);
      expect(find.text('AHORA'), findsNothing);
      // The second segment is not listed as another shift.
      expect(find.textContaining('+ Partido'), findsNothing);
    });

    testWidgets('inside the second segment: it ends at 21:00', (tester) async {
      await pumpCalendar(tester, clock: () => _at(19), prepare: _prepare);
      expect(find.text('AHORA'), findsOneWidget);
      expect(find.text('Hasta las 21:00'), findsOneWidget);
      expect(find.text('Termina en 2 h'), findsOneWidget);
    });

    testWidgets('320 dp, text x1.3: the gap card fits', (tester) async {
      await pumpCalendar(
        tester,
        size: const Size(320, 844),
        textScale: 1.3,
        clock: () => _at(14, 15),
        prepare: _prepare,
      );
      expect(find.text('DESCANSO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('shift_format', () {
    test('compact forms of one and two ranges', () {
      const plain = ShiftType(
        id: 'p',
        code: 'M',
        name: 'M',
        colorValue: 0,
        category: ShiftCategory.work,
        startMinute: 7 * 60 + 30,
        endMinute: 15 * 60,
      );
      expect(plain.compactTimeRange, '07:30–15');
      expect(plain.compactTimeLabel, '07:30–15');
      expect(plain.compactStart, '07:30');
      expect(_partido.compactTimeRange, '09–13/17–21');
      expect(_partido.compactTimeLabel, '09–13 · 17–21');
      expect(_partido.compactStart, '09');
      expect(
        _partido
            .copyWith(
              startMinute: 7 * 60 + 30,
              segment2StartMinute: 16 * 60 + 30,
              segment2DurationMinutes: 3 * 60 + 30,
            )
            .compactTimeRange,
        '07:30–13/16:30–20',
      );
      const rest = ShiftType(
        id: 'l',
        code: 'L',
        name: 'Libre',
        colorValue: 0,
        category: ShiftCategory.rest,
      );
      expect(rest.compactTimeRange, isNull);
      expect(rest.compactTimeLabel, isNull);
      expect(rest.compactStart, isNull);
    });
  });
}
