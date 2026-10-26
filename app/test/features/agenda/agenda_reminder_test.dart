import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/agenda/domain/agenda.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../calendar/harness.dart';

// The small bell of the agenda for notes with a reminder (docs/paridad.md, A1).

const _today = CivilDate(2026, 10, 19);
const _nov3 = CivilDate(2026, 11, 3);
const _nov5 = CivilDate(2026, 11, 5);

Finder _key(String k) => find.byKey(ValueKey(k));

void main() {
  setUpAll(initializeLocale);

  test('the agenda item carries the reminder of its note', () {
    final schedule = Schedule(
      entries: {
        _nov3: DayEntry(date: _nov3, note: 'Dentista', noteReminderMinute: 570),
        _nov5: DayEntry(date: _nov5, note: 'Sin aviso'),
      },
    );
    final items = upcomingAgenda(schedule, const [], _today);
    expect(items.map((i) => (i.date, i.reminderMinute)), [
      (_nov3, 570),
      (_nov5, null),
    ]);
  });

  testWidgets('a note with a reminder shows the bell and its time; one '
      'without does not', (tester) async {
    await pumpCalendar(tester);
    final controller = containerOf(tester)
        .read(scheduleControllerProvider.notifier);
    controller.setNote(_nov3, 'Dentista');
    controller.setNoteReminder(_nov3, 9 * 60 + 30);
    controller.setNote(_nov5, 'Sin aviso');
    await tester.pumpAndSettle();

    await tester.tap(_key('open-agenda'));
    await tester.pumpAndSettle();

    final bell = find.descendant(
      of: _key('agenda-day-2026-11-03'),
      matching: _key('agenda-reminder'),
    );
    expect(bell, findsOneWidget);
    expect(
      find.descendant(of: bell, matching: find.text('09:30')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _key('agenda-day-2026-11-05'),
        matching: _key('agenda-reminder'),
      ),
      findsNothing,
    );
    // The row reads the reminder out too.
    expect(
      tester.getSemantics(_key('agenda-day-2026-11-03')).label,
      contains('aviso a las 09:30'),
    );
  });

  testWidgets('removing the reminder removes the bell', (tester) async {
    await pumpCalendar(tester);
    final controller = containerOf(tester)
        .read(scheduleControllerProvider.notifier);
    controller.setNote(_nov3, 'Dentista');
    controller.setNoteReminder(_nov3, 570);
    controller.setNoteReminder(_nov3, null);
    await tester.pumpAndSettle();
    await tester.tap(_key('open-agenda'));
    await tester.pumpAndSettle();
    expect(_key('agenda-day-2026-11-03'), findsOneWidget);
    expect(_key('agenda-reminder'), findsNothing);
  });
}
