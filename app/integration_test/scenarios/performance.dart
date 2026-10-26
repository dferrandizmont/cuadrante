import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

/// Target of the roadmap (0.7.0: "arranque < 1 s") and the limit above which
/// the scenario fails.
const int _targetMs = 1000;
const int _failMs = 2000;

/// Q13.
const qaPerformance = QaScenario(
  'Q13',
  'Rendimiento: arranque con 2 años de turnos',
  _performance,
);

Future<void> _performance(QaContext qa) async {
  final t = qa.tester;
  const start = CivilDate(2025, 10, 20); // a Monday, a year before "today"
  final last = start.addDays(729);
  final cycle = ['morning', 'afternoon', 'night', 'rest', 'rest'];

  final app = await QaApp.open(
    qa,
    demo: false,
    prepare: (storage) async {
      // Two years: an open rotation plus an override every 2nd day, a double
      // shift every 7th and a note every 10th.
      final entries = <CivilDate, EntryChange>{};
      for (var i = 0; i < 730; i++) {
        final date = start.addDays(i);
        final note = i % 10 == 0 ? 'Nota $i' : null;
        final ids = i % 7 == 0
            ? const ['morning', 'afternoon']
            : i.isEven
            ? [cycle[i % cycle.length]]
            : null;
        if (ids == null && note == null) continue;
        entries[date] = EntryChange(
          null,
          DayEntry(date: date, shiftTypeIds: ids, note: note),
        );
      }
      await storage.repository.apply(
        mainCalendarId,
        ScheduleChange(
          patch: EntriesPatch(entries),
          runsAfter: [
            PatternRun(
              id: 'qa-run',
              patternId: 'correturnos',
              startDate: start,
              seq: 1,
            ),
          ],
        ),
      );
    },
  );
  final rows = await app.storedDayCount();
  expect(rows, greaterThan(400), reason: 'la BD debe tener 2 años de días');
  expect(app.schedule.resolve(last).source, isNot(DaySource.none));

  // Cold start, several times: file connection, pre-migration check, seed
  // check, holidays refresh, schedule load, first frame with the 42 cells.
  final times = <int>[];
  for (var i = 0; i < 3; i++) {
    await app.unmount();
    await app.closeDatabase();
    final watch = Stopwatch()..start();
    await app.reopenDatabase();
    await app.mount(settle: false);
    watch.stop();
    expect(allCells, findsNWidgets(42), reason: 'primer fotograma con el mes');
    await t.settle();
    times.add(watch.elapsedMilliseconds);
    qa.metric('arranque_ms_${i + 1}', watch.elapsedMilliseconds);
  }
  final cold = times.first;
  final best = times.reduce((a, b) => a < b ? a : b);
  qa.metric('arranque_frio_ms', cold);
  qa.metric('arranque_mejor_ms', best);
  qa.metric('objetivo_ms', _targetMs);
  qa.metric('limite_ms', _failMs);
  qa.metric('dias_guardados', rows);
  if (cold > _targetMs) {
    qa.note(
      'Arranque en frío $cold ms: por encima del objetivo de $_targetMs ms '
      '(build de depuración en el emulador; el límite que falla es $_failMs ms).',
    );
  }
  await qa.shot('mes');
  expect(
    cold,
    lessThanOrEqualTo(_failMs),
    reason:
        'arranque en frío $cold ms (límite $_failMs ms, objetivo $_targetMs ms)',
  );
}
