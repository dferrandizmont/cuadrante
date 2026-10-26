import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// H-T24-12 (design item 6): dragging from the first row of the month also
/// painted the grey days of the neighbouring months. Now the stroke stays
/// inside the month that is being edited: the grey days are skipped.
void main() {
  setUpAll(initializeLocale);

  // October 2026 starts on a Thursday: the grid opens on Mon 28 Sep and ends
  // on Sun 8 Nov. The grey days are the three first (September) and the eight
  // last (November).
  const greyFirst = CivilDate(2026, 9, 30);
  const greyLast = CivilDate(2026, 11, 1);
  const firstOfMonth = CivilDate(2026, 10, 4);
  const lastOfMonth = CivilDate(2026, 10, 31);

  Future<void> paintMode(WidgetTester tester) async {
    await enterPaintMode(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('tool-morning')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tool-morning')));
    await tester.pumpAndSettle();
  }

  String ids(WidgetTester tester, CivilDate date) =>
      containerOf(tester)
          .read(scheduleControllerProvider)
          .schedule
          .resolve(date)
          .shiftIds
          .join('+');

  /// Drags one finger through the centres of [days], as a stroke.
  Future<void> dragAcross(WidgetTester tester, List<CivilDate> days) async {
    final points = [for (final d in days) tester.getCenter(cell(d))];
    final gesture = await tester.startGesture(points.first);
    await tester.pump(const Duration(milliseconds: 20));
    for (final point in points.skip(1)) {
      await gesture.moveTo(point);
      await tester.pump(const Duration(milliseconds: 20));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('a tap on a grey day paints nothing', (tester) async {
    await pumpCalendar(tester);
    await paintMode(tester);
    await revealCell(tester, greyFirst);

    await tester.tap(cell(greyFirst));
    await tester.pumpAndSettle();

    expect(ids(tester, greyFirst), isNot('morning'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a drag from the grey days paints only the month', (
    tester,
  ) async {
    await pumpCalendar(tester);
    await paintMode(tester);
    await revealCell(tester, greyFirst);

    // The first row: from the last grey day of September to the fourth of
    // October.
    await dragAcross(tester, [greyFirst, firstOfMonth]);
    expect(ids(tester, firstOfMonth), 'morning');
    expect(ids(tester, greyFirst), isNot('morning'));

    // The last row: from the thirty-first of October to the first of
    // November, which is grey.
    await revealCell(tester, lastOfMonth);
    await dragAcross(tester, [lastOfMonth, greyLast]);
    expect(ids(tester, lastOfMonth), 'morning');
    expect(ids(tester, greyLast), isNot('morning'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the days of the month are still painted', (tester) async {
    await pumpCalendar(tester);
    await paintMode(tester);
    await revealCell(tester, firstOfMonth);

    await tester.tap(cell(firstOfMonth));
    await tester.pumpAndSettle();

    expect(ids(tester, firstOfMonth), 'morning');
    expect(tester.takeException(), isNull);
  });

  testWidgets('grey days preserve complete entries and history through a '
      'cross-month stroke, undo and redo', (tester) async {
    Future<void> prepare(ScheduleRepository repository) => repository.apply(
      'main',
      ScheduleChange(
        patch: EntriesPatch({
          for (final date in [greyFirst, greyLast, firstOfMonth, lastOfMonth])
            date: EntryChange(
              null,
              DayEntry(
                date: date,
                shiftTypeIds: const ['afternoon'],
                note: 'Conservar ${date.toIso()}',
                noteReminderMinute: 8 * 60 + 15,
                overtimeMinutes: 45,
                earlyLeaveMinutes: 20,
              ),
            ),
        }),
      ),
    );
    await pumpCalendar(tester, prepare: prepare);
    final before = scheduleOf(tester);
    await paintMode(tester);
    await revealCell(tester, greyFirst);
    await tester.tap(cell(greyFirst));
    await tester.pumpAndSettle();
    expect(scheduleOf(tester).entries, before.entries);
    expect(
      containerOf(tester).read(scheduleControllerProvider).canUndo,
      isFalse,
    );

    await dragAcross(tester, [greyFirst, firstOfMonth]);
    final painted = scheduleOf(tester);
    expect(idsOn(painted, firstOfMonth), 'morning');
    for (final date in [greyFirst, greyLast, lastOfMonth]) {
      expect(painted.entries[date], before.entries[date]);
    }
    expect(
      painted.entries[firstOfMonth],
      before.entries[firstOfMonth]!.withShiftTypeIds(['morning']),
    );
    expect(painted.runs, before.runs);
    expect(painted.patterns, before.patterns);
    expect(painted.shiftTypes, before.shiftTypes);

    await tester.tap(find.byTooltip('Deshacer'));
    await tester.pumpAndSettle();
    expect(scheduleOf(tester).entries, before.entries);
    expect(scheduleOf(tester).runs, before.runs);
    await tester.tap(find.byTooltip('Rehacer'));
    await tester.pumpAndSettle();
    expect(scheduleOf(tester).entries, painted.entries);
    expect(scheduleOf(tester).runs, painted.runs);
    expect(tester.takeException(), isNull);
  });
}
