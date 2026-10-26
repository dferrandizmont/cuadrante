import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/presentation/day_extras_section.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

// «Horas extra / Salí antes» in the day detail and the small «+» of the cell
// (A6). Demo data: Mañana 26-30 October, Libre 24-25.
const _oct24 = CivilDate(2026, 10, 24);
const _oct26 = CivilDate(2026, 10, 26);
const _oct27 = CivilDate(2026, 10, 27);

Finder _key(String key) => find.byKey(ValueKey(key));

Finder get _sheet => find.byType(BottomSheet);

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(_key(key)).data!;

DayEntry? _entry(WidgetTester tester, CivilDate date) =>
    containerOf(tester).read(scheduleControllerProvider).schedule.entries[date];

ScheduleState _state(WidgetTester tester) =>
    containerOf(tester).read(scheduleControllerProvider);

Future<void> _open(WidgetTester tester, CivilDate date) async {
  await revealCell(tester, date);
  await tester.tap(cell(date));
  await tester.pumpAndSettle();
  expect(_sheet, findsOneWidget);
}

Future<void> _close(WidgetTester tester) async {
  Navigator.of(tester.element(_sheet)).pop();
  await tester.pumpAndSettle();
  expect(_sheet, findsNothing);
}

Future<void> _tap(WidgetTester tester, String key, {int times = 1}) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  for (var i = 0; i < times; i++) {
    await tester.tap(_key(key));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Lets the quiet time pass so the value is written.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(DayExtrasSection.settle + const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

void main() {
  group('the section', () {
    testWidgets('is in the day detail with both counters at «Ninguna»', (
      tester,
    ) async {
      await pumpCalendar(tester, size: const Size(390, 1400));
      await _open(tester, _oct26);
      await tester.ensureVisible(_key('day-extras'));
      expect(find.text('HORAS EXTRA / SALÍ ANTES'), findsOneWidget);
      expect(_text(tester, 'day-overtime-value'), 'Ninguna');
      expect(_text(tester, 'day-early-value'), 'Ninguna');
      // Nothing to take away yet.
      expect(
        tester.widget<IconButton>(_key('day-overtime-less')).onPressed,
        isNull,
      );
      expect(
        tester.widget<IconButton>(_key('day-early-less')).onPressed,
        isNull,
      );
    });

    testWidgets('also on a rest day and on a day with no shift', (
      tester,
    ) async {
      await pumpCalendar(tester, size: const Size(390, 1400));
      await _open(tester, _oct24);
      expect(_key('day-overtime-more'), findsOneWidget);
    });

    testWidgets('opens with the values the day already has', (tester) async {
      await pumpCalendar(
        tester,
        size: const Size(390, 1400),
        prepare: (repository) async {
          await repository.apply(
            'main',
            ScheduleChange(
              patch: EntriesPatch({
                _oct27: EntryChange(
                  null,
                  const DayEntry(
                    date: _oct27,
                    overtimeMinutes: 90,
                    earlyLeaveMinutes: 45,
                  ),
                ),
              }),
            ),
          );
        },
      );
      await _open(tester, _oct27);
      expect(_text(tester, 'day-overtime-value'), '1 h 30 min');
      expect(_text(tester, 'day-early-value'), '45 min');
    });
  });

  group('editing', () {
    testWidgets(
      'clear during debounce stays clear and undo restores the draft',
      (tester) async {
        await pumpCalendar(tester, size: const Size(390, 1400));
        await _open(tester, _oct26);
        await tester.ensureVisible(_key('day-overtime-more'));
        await tester.tap(_key('day-overtime-more'));
        await tester.pump();
        expect(_entry(tester, _oct26), isNull);
        await tester.ensureVisible(_key('day-clear'));
        await tester.tap(_key('day-clear'));
        await tester.pumpAndSettle();
        await _settle(tester);
        expect(_entry(tester, _oct26)?.overtimeMinutes, isNull);
        expect(_state(tester).schedule.resolve(_oct26).shifts, isEmpty);
        await tester.tap(find.text('Deshacer').last);
        await tester.pumpAndSettle();
        expect(_entry(tester, _oct26)!.overtimeMinutes, 15);
        expect(_state(tester).schedule.resolve(_oct26).shifts, isNotEmpty);
      },
    );

    testWidgets('three taps on «+» are 45 min, written ONCE after a pause: '
        'one undo step', (tester) async {
      await pumpCalendar(tester, size: const Size(390, 1400));
      await _open(tester, _oct26);
      await _tap(tester, 'day-overtime-more', times: 3);
      expect(_text(tester, 'day-overtime-value'), '45 min');
      // Not written yet: the user may still be tapping.
      expect(_entry(tester, _oct26), isNull);

      await _settle(tester);
      expect(_entry(tester, _oct26)!.overtimeMinutes, 45);
      expect(_text(tester, 'day-overtime-value'), '45 min');

      // ONE undo step takes all three taps back.
      containerOf(tester).read(scheduleControllerProvider.notifier).undo();
      await tester.pumpAndSettle();
      expect(_entry(tester, _oct26), isNull);
      expect(_state(tester).canUndo, isFalse);
    });

    testWidgets('«Salí antes» goes up and down, and 0 clears it', (
      tester,
    ) async {
      await pumpCalendar(tester, size: const Size(390, 1400));
      await _open(tester, _oct26);
      await _tap(tester, 'day-early-more', times: 4);
      await _settle(tester);
      expect(_entry(tester, _oct26)!.earlyLeaveMinutes, 60);
      expect(_text(tester, 'day-early-value'), '1 h');

      await _tap(tester, 'day-early-less', times: 4);
      expect(_text(tester, 'day-early-value'), 'Ninguna');
      await _settle(tester);
      expect(_entry(tester, _oct26), isNull);
    });

    testWidgets('both counters are independent', (tester) async {
      await pumpCalendar(tester, size: const Size(390, 1400));
      await _open(tester, _oct26);
      await _tap(tester, 'day-overtime-more', times: 2);
      await _tap(tester, 'day-early-more');
      await _settle(tester);
      final entry = _entry(tester, _oct26)!;
      expect(entry.overtimeMinutes, 30);
      expect(entry.earlyLeaveMinutes, 15);
    });

    testWidgets('closing the sheet before the pause still saves', (
      tester,
    ) async {
      await pumpCalendar(tester, size: const Size(390, 1400));
      await _open(tester, _oct26);
      await _tap(tester, 'day-overtime-more', times: 2);
      await _close(tester);
      await tester.pumpAndSettle();
      expect(_entry(tester, _oct26)!.overtimeMinutes, 30);
    });

    testWidgets('is stored: the database has the minutes', (tester) async {
      await pumpCalendar(tester, size: const Size(390, 1400));
      await _open(tester, _oct26);
      await _tap(tester, 'day-overtime-more', times: 5);
      await _settle(tester);
      final container = containerOf(tester);
      final snapshot = (await tester.runAsync(() async {
        await container.read(scheduleControllerProvider.notifier).pendingWrites;
        return container.read(scheduleRepositoryProvider).load(mainCalendarId);
      }))!;
      expect(
        snapshot.schedule.entries[_oct26],
        const DayEntry(date: _oct26, overtimeMinutes: 75),
      );
    });

    testWidgets('can not go past 24 h', (tester) async {
      await pumpCalendar(tester, size: const Size(390, 1400));
      containerOf(tester)
          .read(scheduleControllerProvider.notifier)
          .setDayExtras(_oct26, overtimeMinutes: maxDayExtraMinutes - 15);
      await tester.pumpAndSettle();
      await _open(tester, _oct26);
      await _tap(tester, 'day-overtime-more');
      expect(_text(tester, 'day-overtime-value'), '24 h');
      expect(
        tester.widget<IconButton>(_key('day-overtime-more')).onPressed,
        isNull,
      );
      await _settle(tester);
    });
  });

  group('the cell', () {
    testWidgets('a day with extras carries the small «+», with its spoken '
        'minutes; a plain day does not', (tester) async {
      await pumpCalendar(tester);
      expect(_key('extras-mark-2026-10-26'), findsNothing);

      containerOf(tester)
          .read(scheduleControllerProvider.notifier)
          .setDayExtras(_oct26, overtimeMinutes: 90, earlyLeaveMinutes: 30);
      await tester.pumpAndSettle();

      expect(_key('extras-mark-2026-10-26'), findsOneWidget);
      expect(_key('extras-mark-2026-10-27'), findsNothing);
      final label = tester.getSemantics(cell(_oct26)).label;
      expect(label, contains('horas extra: 1 h 30 min'));
      expect(label, contains('salida anticipada: 30 min'));
      // The shift is still its normal self.
      expect(label, contains('Mañana'));
    });

    testWidgets('the mark follows the day after the sheet changes it', (
      tester,
    ) async {
      await pumpCalendar(tester, size: const Size(390, 1400));
      await _open(tester, _oct26);
      await _tap(tester, 'day-early-more');
      await _close(tester);
      await tester.pumpAndSettle();
      expect(_key('extras-mark-2026-10-26'), findsOneWidget);
    });
  });

  group('small screens', () {
    for (final scale in [1.0, 1.3, 1.6]) {
      testWidgets('320 dp wide, text x$scale: no overflow', (tester) async {
        await pumpCalendar(
          tester,
          size: const Size(320, 700),
          textScale: scale,
        );
        containerOf(tester)
            .read(scheduleControllerProvider.notifier)
            .setDayExtras(
              _oct26,
              overtimeMinutes: 14 * 60 + 45,
              earlyLeaveMinutes: 13 * 60 + 30,
            );
        await tester.pumpAndSettle();
        await _open(tester, _oct26);
        await tester.ensureVisible(_key('day-extras'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(_text(tester, 'day-overtime-value'), '14 h 45 min');
      });
    }
  });
}
