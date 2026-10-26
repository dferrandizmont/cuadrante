import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// H-T02-3: the plus of overtime / early leave used to be drawn at the bottom
/// left, over the time of the shift ("⊕15–22"). It now sits in the top row of
/// the cell, which the code and the time never enter.
void main() {
  setUpAll(initializeLocale);

  // 12 October is a national holiday (dot), the 13th has no mark but extras.
  const holiday = CivilDate(2026, 10, 12);
  const plain = CivilDate(2026, 10, 13);
  const widths = [320.0, 360.0, 412.0];
  const scales = [1.0, 1.3, 2.0];

  Future<void> prepare(ScheduleRepository repository) => repository.apply(
    'main',
    ScheduleChange(
      patch: EntriesPatch({
        holiday: EntryChange(
          null,
          const DayEntry(
            date: holiday,
            shiftTypeIds: ['morning'],
            note: 'Nota',
            overtimeMinutes: 45,
          ),
        ),
        plain: EntryChange(
          null,
          const DayEntry(
            date: plain,
            shiftTypeIds: ['afternoon'],
            earlyLeaveMinutes: 15,
          ),
        ),
      }),
    ),
  );

  for (final brightness in Brightness.values) {
    for (final width in widths) {
      for (final scale in scales) {
        testWidgets(
          'at $width dp, text $scale, ${brightness.name}: the plus never '
          'touches the code or the time',
          (tester) async {
            await pumpCalendar(
              tester,
              size: Size(width, 1000),
              textScale: scale,
              brightness: brightness,
              prepare: prepare,
            );
            await tester.scrollUntilVisible(
              cell(plain),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            var timesSeen = 0;
            for (final (date, code, time) in [
              (holiday, 'M', '06–14'),
              (plain, 'T', '14–22'),
            ]) {
              final mark = tester.getRect(
                find.byKey(ValueKey('extras-mark-${date.toIso()}')),
              );
              final codeFinder = find.descendant(
                of: cell(date),
                matching: find.text(code),
              );
              expect(codeFinder, findsOneWidget);
              expect(
                mark.overlaps(tester.getRect(codeFinder)),
                isFalse,
                reason: 'the plus of $date covers the code',
              );
              final timeFinder = find.descendant(
                of: cell(date),
                matching: find.text(time),
              );
              if (timeFinder.evaluate().isNotEmpty) {
                timesSeen++;
                expect(
                  mark.overlaps(tester.getRect(timeFinder)),
                  isFalse,
                  reason: 'the plus of $date covers the time',
                );
              }
              // And it stays inside its own cell.
              final box = tester.getRect(cell(date));
              expect(mark.left, greaterThanOrEqualTo(box.left));
              expect(mark.right, lessThanOrEqualTo(box.right));
              expect(mark.top, greaterThanOrEqualTo(box.top));
            }
            // Large text drops the time, as designed; the rest keep it, so
            // the check above really compares against it.
            if (scale == 1.0 && width == 412) expect(timesSeen, 2);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('the plus lives in the top half of the cell, by the note and '
      'the holiday dot', (tester) async {
    await pumpCalendar(tester, prepare: prepare);
    final box = tester.getRect(cell(holiday));
    final mark = tester.getRect(
      find.byKey(ValueKey('extras-mark-${holiday.toIso()}')),
    );
    final dot = tester.getRect(
      find.byKey(ValueKey('holiday-dot-${holiday.toIso()}')),
    );
    expect(mark.center.dy, lessThan(box.center.dy));
    expect(mark.right, lessThanOrEqualTo(dot.left));
    expect(mark.overlaps(dot), isFalse);
  });
}
