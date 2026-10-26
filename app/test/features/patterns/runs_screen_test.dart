import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/widgets/buttons.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../calendar/harness.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

// The month screen stays under the pushed routes (offstage).
ProviderContainer _container(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(MonthScreen, skipOffstage: false)),
);

Schedule _schedule(WidgetTester tester) =>
    _container(tester).read(scheduleControllerProvider).schedule;

void main() {
  setUpAll(initializeLocale);

  Future<void> openRuns(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Abrir ajustes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_key('settings-runs'));
    await tester.pumpAndSettle();
    await tester.tap(_key('settings-runs'));
    await tester.pumpAndSettle();
    expect(find.text('Mis rotaciones'), findsWidgets);
  }

  /// What the database holds right now.
  Future<Schedule> stored(WidgetTester tester) async {
    final container = _container(tester);
    final repository = container.read(scheduleRepositoryProvider);
    return (await tester.runAsync(() async {
      await container.read(scheduleControllerProvider.notifier).pendingWrites;
      return (await repository.load(mainCalendarId)).schedule;
    }))!;
  }

  PatternRun run(WidgetTester tester) =>
      _schedule(tester).runs.singleWhere((r) => r.id == 'run-1');

  testWidgets('lists the rotations of the calendar with their dates', (
    tester,
  ) async {
    await pumpCalendar(tester);
    await openRuns(tester);

    final card = _key('run-run-1');
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('Correturnos')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.textContaining('Desde el lunes, 13 de julio'),
      ),
      findsOneWidget,
    );
    expect(_key('run-status-run-1'), findsOneWidget);
    expect(find.text('En curso'), findsOneWidget);
    // H-T06-2: where in the cycle it starts tells two runs of one pattern
    // apart.
    expect(
      tester.widget<Text>(_key('run-step-run-1')).data,
      'Empieza en el día ${_schedule(tester).runs.single.stepOffset + 1} '
      'del ciclo',
    );
  });

  testWidgets('Terminar aquí ends the run the day before the chosen day, '
      'in one undo step', (tester) async {
    await pumpCalendar(tester);
    final before = _schedule(tester);
    await openRuns(tester);

    await tester.tap(_key('run-end-run-1'));
    await tester.pumpAndSettle();
    // The picker opens on today (19 Oct): pick the 28th, the first day
    // without the rotation.
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('28'),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is Text && w.data?.toLowerCase() == 'aceptar',
      ),
    );
    await tester.pumpAndSettle();

    expect(run(tester).endDate, const CivilDate(2026, 10, 27));
    expect(
      _schedule(tester).resolve(const CivilDate(2026, 10, 28)).source,
      isNot(DaySource.pattern),
    );
    // The overrides did not move.
    expect(_schedule(tester).entries, before.entries);
    // H-T06-1: the notice names the LAST day of the rotation (endDate is
    // inclusive), the same one the card shows, not the day that was picked.
    expect(
      find.text('La rotación acaba el martes, 27 de octubre'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _key('run-run-1'),
        matching: find.textContaining('al martes, 27 de octubre'),
      ),
      findsOneWidget,
      reason: 'the card says the same day as the notice',
    );
    expect((await stored(tester)).runs.single.endDate, run(tester).endDate);

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(run(tester).endDate, isNull);
    expect(
      _container(tester).read(scheduleControllerProvider).canUndo,
      isFalse,
      reason: 'ONE step',
    );
    expect((await stored(tester)).runs.single.endDate, isNull);
  });

  testWidgets('Eliminar asks, removes the run and keeps the manual days; '
      'undo brings it back', (tester) async {
    await pumpCalendar(tester);
    final before = _schedule(tester);
    await openRuns(tester);

    await tester.tap(_key('run-delete-run-1'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar Correturnos?'), findsOneWidget);
    // Cancelling changes nothing.
    await tester.tap(_key('confirm-cancel'));
    await tester.pumpAndSettle();
    expect(_schedule(tester).runs, isNotEmpty);

    await tester.tap(_key('run-delete-run-1'));
    await tester.pumpAndSettle();
    await tester.tap(_key('confirm-ok'));
    await tester.pumpAndSettle();

    expect(_schedule(tester).runs, isEmpty);
    expect(_schedule(tester).entries, before.entries);
    expect(find.text('Sin rotaciones'), findsOneWidget);
    expect(find.text('Rotación eliminada'), findsOneWidget);
    expect((await stored(tester)).runs, isEmpty);

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(_schedule(tester).runs, before.runs);
    expect(find.text('Correturnos'), findsOneWidget);
    expect((await stored(tester)).runs, before.runs);
  });

  testWidgets('a rotation that already ended cannot be ended again', (
    tester,
  ) async {
    await pumpCalendar(tester);
    _container(tester)
        .read(scheduleControllerProvider.notifier)
        .endRun('run-1', const CivilDate(2026, 10, 10));
    await tester.pumpAndSettle();
    await openRuns(tester);

    expect(find.text('Terminada'), findsOneWidget);
    expect(
      tester.widget<SecondaryButton>(_key('run-end-run-1')).onPressed,
      isNull,
    );
    expect(
      tester.widget<SecondaryButton>(_key('run-delete-run-1')).onPressed,
      isNotNull,
    );
  });

  testWidgets('survives large text and the dark theme', (tester) async {
    await pumpCalendar(
      tester,
      textScale: 1.6,
      brightness: Brightness.dark,
      size: const Size(320, 568),
    );
    await openRuns(tester);
    expect(tester.takeException(), isNull);
    expect(_key('run-end-run-1'), findsOneWidget);
  });
}
