import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/theme/app_colors.dart';
import 'package:cuadrante/features/calendars/application/calendars_controller.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/calendars/presentation/calendar_editor_sheet.dart';
import 'package:cuadrante/features/calendars/presentation/calendar_messages.dart';
import 'package:cuadrante/features/calendars/presentation/calendars_screen.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

void main() {
  setUpAll(initializeLocale);

  // The colours of picker options 3 and 4 (zero-based).
  final option3 = kCalendarColors[3].toARGB32();
  final option5 = kCalendarColors[4].toARGB32();

  Future<List<Calendar>> storedCalendars(AppUnderTest app) => app.real(
    () => CalendarsRepository(app.database).list(includeArchived: true),
  );

  Future<String> storedPrimary(AppUnderTest app) =>
      app.real(() => CalendarsRepository(app.database).primaryId());

  /// Seeds ten calendars; the main and second calendars already exist.
  Future<void> seedTenCalendars(AppDatabase db) async {
    final repo = CalendarsRepository(db);
    for (var i = 0; i < 8; i++) {
      await repo.create(name: 'Extra $i', colorValue: 0xFF000000 + i);
    }
  }

  Finder row(String id) => find.byKey(ValueKey('calendar-row-$id'));

  Finder badge(String id, String text) =>
      find.descendant(of: row(id), matching: find.text(text));

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> createCalendar(
    WidgetTester tester,
    String name, {
    int colorIndex = 3,
  }) async {
    await tapKey(tester, 'calendars-add');
    await tester.enterText(
      find.byKey(const ValueKey('calendar-name-field')),
      name,
    );
    await tapKey(tester, 'calendar-color-$colorIndex');
    await tapKey(tester, 'calendar-save');
  }

  group('the list', () {
    testWidgets('one calendar: name, both badges, and room for another', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester);
      await app.openCalendars();

      expect(find.byType(CalendarsScreen), findsOneWidget);
      expect(find.text('Calendarios'), findsWidgets);
      expect(
        find.textContaining('Cada calendario tiene su propio'),
        findsOneWidget,
      );
      expect(find.text('Mi cuadrante'), findsOneWidget);
      expect(badge('main', 'Activo'), findsOneWidget);
      expect(badge('main', 'Widget y alarmas'), findsOneWidget);
      expect(find.byKey(const ValueKey('calendars-limit')), findsNothing);
      final add = tester.widget<OutlinedButton>(
        find.descendant(
          of: find.byKey(const ValueKey('calendars-add')),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(add.onPressed, isNotNull);
    });

    testWidgets('badges follow the active and the primary calendar', (
      tester,
    ) async {
      late String second;
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async => second = await addSecondCalendar(db),
      );
      await app.openCalendars();

      expect(find.text('Pareja'), findsOneWidget);
      expect(badge('main', 'Activo'), findsOneWidget);
      expect(badge('main', 'Widget y alarmas'), findsOneWidget);
      expect(badge(second, 'Activo'), findsNothing);
      expect(badge(second, 'Widget y alarmas'), findsNothing);
    });

    testWidgets('active and primary can be different calendars', (
      tester,
    ) async {
      late String second;
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async {
          second = await addSecondCalendar(db);
          await CalendarsRepository(db).setActive(second);
        },
      );
      await app.openCalendars();
      expect(badge(second, 'Activo'), findsOneWidget);
      expect(badge(second, 'Widget y alarmas'), findsNothing);
      expect(badge('main', 'Activo'), findsNothing);
      expect(badge('main', 'Widget y alarmas'), findsOneWidget);
    });
  });

  group('create', () {
    testWidgets('a name and a colour make a new calendar', (tester) async {
      final app = await AppUnderTest.pump(tester);
      await app.openCalendars();
      await createCalendar(tester, '  Pareja ');

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Pareja'), findsOneWidget);
      final calendars = await storedCalendars(app);
      expect(calendars.map((c) => c.name), ['Mi cuadrante', 'Pareja']);
      expect(calendars.last.colorValue, option3);
      expect(calendars.last.archived, isFalse);
      // The one on screen and the primary one do not change.
      expect(app.schedule.calendarId, 'main');
      expect(await storedPrimary(app), 'main');
      expect(badge('main', 'Activo'), findsOneWidget);
    });

    testWidgets('a new calendar starts on a colour nobody uses', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester);
      await app.openCalendars();
      await tapKey(tester, 'calendars-add');
      await tester.enterText(
        find.byKey(const ValueKey('calendar-name-field')),
        'Otro',
      );
      await tapKey(tester, 'calendar-save');
      final created = (await storedCalendars(app)).last;
      // `main` is the indigo Noche: the new one is the first other hue.
      expect(created.colorValue, kCalendarColors.first.toARGB32());
      expect(created.colorValue, isNot(0xFF4B4FD1));
    });

    testWidgets('an empty name is refused with a message', (tester) async {
      final app = await AppUnderTest.pump(tester);
      await app.openCalendars();
      await tapKey(tester, 'calendars-add');
      await tapKey(tester, 'calendar-save');

      expect(find.text('Pon un nombre al calendario.'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(await storedCalendars(app), hasLength(1));

      // Typing clears the message.
      await tester.enterText(
        find.byKey(const ValueKey('calendar-name-field')),
        'Pareja',
      );
      await tester.pump();
      expect(find.text('Pon un nombre al calendario.'), findsNothing);
    });

    testWidgets('the third calendar can be added', (tester) async {
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async {
          await addSecondCalendar(db);
        },
      );
      await app.openCalendars();

      expect(find.byKey(const ValueKey('calendars-limit')), findsNothing);
      final add = tester.widget<OutlinedButton>(
        find.descendant(
          of: find.byKey(const ValueKey('calendars-add')),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(add.onPressed, isNotNull);
    });

    testWidgets('creates the eleventh and twelfth calendars', (tester) async {
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async {
          await addSecondCalendar(db);
          await seedTenCalendars(db);
        },
      );
      await app.openCalendars();
      await createCalendar(tester, 'Undécimo', colorIndex: 4);
      await createCalendar(tester, 'Duodécimo', colorIndex: 4);
      expect(await storedCalendars(app), hasLength(12));
      expect(find.text('Undécimo'), findsOneWidget);
      expect(find.text('Duodécimo'), findsOneWidget);
      final add = tester.widget<OutlinedButton>(
        find.descendant(
          of: find.byKey(const ValueKey('calendars-add')),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(add.onPressed, isNotNull);
      expect(find.byKey(const ValueKey('calendars-limit')), findsNothing);
    });

    testWidgets('can add another calendar after archiving', (tester) async {
      late String second;
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async {
          second = await addSecondCalendar(db);
          await seedTenCalendars(db);
        },
      );
      await app.openCalendars();
      expect(find.byKey(const ValueKey('calendars-limit')), findsNothing);

      await tester.tap(row(second));
      await tester.pumpAndSettle();
      await tapKey(tester, 'calendar-archive');
      await tapKey(tester, 'calendar-archive-confirm');

      expect(find.byKey(const ValueKey('calendars-limit')), findsNothing);
      await createCalendar(tester, 'Nueva');
      expect(find.text('Nueva'), findsOneWidget);
    });
  });

  group('edit', () {
    testWidgets('rename', (tester) async {
      final app = await AppUnderTest.pump(tester);
      await app.openCalendars();
      await tester.tap(row('main'));
      await tester.pumpAndSettle();

      expect(find.text('Editar calendario'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('calendar-name-field')),
            )
            .controller!
            .text,
        'Mi cuadrante',
      );
      await tester.enterText(
        find.byKey(const ValueKey('calendar-name-field')),
        'Hospital',
      );
      await tapKey(tester, 'calendar-save');

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Hospital'), findsOneWidget);
      expect(find.text('Mi cuadrante'), findsNothing);
      expect((await storedCalendars(app)).single.name, 'Hospital');
      // The settings screen behind shows the new name too.
      await app.back();
      expect(find.text('Hospital'), findsWidgets);
    });

    testWidgets('recolor', (tester) async {
      final app = await AppUnderTest.pump(tester);
      await app.openCalendars();
      await tester.tap(row('main'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'calendar-color-4');
      await tapKey(tester, 'calendar-save');

      final calendar = (await storedCalendars(app)).single;
      expect(calendar.colorValue, option5);
      expect(calendar.name, 'Mi cuadrante');
    });

    testWidgets('saving without changes writes nothing and closes', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester);
      await app.openCalendars();
      await tester.tap(row('main'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'calendar-save');
      expect(find.byType(BottomSheet), findsNothing);
      final calendar = (await storedCalendars(app)).single;
      expect(calendar.name, 'Mi cuadrante');
      expect(calendar.colorValue, mainCalendarColor);
    });

    testWidgets('the picker offers the shift hues and marks the chosen one', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester);
      await app.openCalendars();
      await tester.tap(row('main'));
      await tester.pumpAndSettle();
      for (var i = 0; i < kCalendarColors.length; i++) {
        expect(find.byKey(ValueKey('calendar-color-$i')), findsOneWidget);
      }
      expect(
        find.byKey(ValueKey('calendar-color-${kCalendarColors.length}')),
        findsNothing,
      );
      // `main` is indigo, the third hue: it is the selected one.
      Color ring(int i) {
        final box = tester.widget<Container>(
          find.descendant(
            of: find.byKey(ValueKey('calendar-color-$i')),
            matching: find.byType(Container),
          ),
        );
        return ((box.decoration! as BoxDecoration).border! as Border).top.color;
      }

      final ringColor = Theme.of(
        tester.element(find.byKey(const ValueKey('calendar-color-0'))),
      ).extension<AppColors>()!.todayRing;
      expect(ring(2), ringColor);
      expect(ring(0), Colors.transparent);
      expect(ring(4), Colors.transparent);
      // And a tap moves the ring.
      await tester.tap(find.byKey(const ValueKey('calendar-color-4')));
      await tester.pump();
      expect(ring(4), ringColor);
      expect(ring(2), Colors.transparent);
      expect(app.schedule.calendarId, 'main');
    });

    testWidgets('a colour from outside the palette stays pickable', (
      tester,
    ) async {
      late String odd;
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async {
          odd = (await CalendarsRepository(
            db,
          ).create(name: 'Importado', colorValue: 0xFF123456)).id;
        },
      );
      await app.openCalendars();
      await tester.tap(row(odd));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('calendar-color-${kCalendarColors.length}')),
        findsOneWidget,
      );
      await tapKey(tester, 'calendar-save');
      expect(
        (await storedCalendars(app)).firstWhere((c) => c.id == odd).colorValue,
        0xFF123456,
      );
    });
  });

  group('primary', () {
    testWidgets('"Usar para widget y alarmas" moves the primary badge', (
      tester,
    ) async {
      late String second;
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async => second = await addSecondCalendar(db),
      );
      await app.openCalendars();

      // The primary one does not offer the button.
      await tester.tap(row('main'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-make-primary')), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(row(second));
      await tester.pumpAndSettle();
      expect(find.textContaining('aunque estés viendo otro'), findsOneWidget);
      await tapKey(tester, 'calendar-make-primary');

      expect(find.byType(BottomSheet), findsNothing);
      expect(badge(second, 'Widget y alarmas'), findsOneWidget);
      expect(badge('main', 'Widget y alarmas'), findsNothing);
      expect(await storedPrimary(app), second);
      // What is on screen does not change.
      expect(app.schedule.calendarId, 'main');
      expect(badge('main', 'Activo'), findsOneWidget);
    });
  });

  group('archive', () {
    testWidgets('asks first, and cancelling keeps the calendar', (
      tester,
    ) async {
      late String second;
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async => second = await addSecondCalendar(db),
      );
      await app.openCalendars();
      await tester.tap(row(second));
      await tester.pumpAndSettle();
      await tapKey(tester, 'calendar-archive');

      expect(find.text('¿Archivar «Pareja»?'), findsOneWidget);
      expect(
        find.textContaining('Sus turnos se quedan guardados'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('confirm-cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect((await storedCalendars(app)).where((c) => c.archived), isEmpty);
    });

    testWidgets('confirming archives it and keeps its data', (tester) async {
      late String second;
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async => second = await addSecondCalendar(db),
      );
      await app.openCalendars();
      await tester.tap(row(second));
      await tester.pumpAndSettle();
      await tapKey(tester, 'calendar-archive');
      await tapKey(tester, 'calendar-archive-confirm');

      expect(find.byType(BottomSheet), findsNothing);
      expect(row(second), findsNothing);
      expect(find.text('Pareja'), findsNothing);
      final calendars = await storedCalendars(app);
      expect(calendars.firstWhere((c) => c.id == second).archived, isTrue);
      // Its days are still stored.
      final entries = await app.real(
        () => app.database
            .customSelect(
              'SELECT COUNT(*) AS n FROM day_entries WHERE calendar_id = ?',
              variables: [Variable.withString(second)],
            )
            .getSingle(),
      );
      expect(entries.read<int>('n'), 1);
    });

    testWidgets('the calendar on screen is replaced by the one that is left', (
      tester,
    ) async {
      late String second;
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async {
          second = await addSecondCalendar(db);
          await CalendarsRepository(db).setActive(second);
        },
      );
      expect(app.schedule.calendarId, second);
      await app.openCalendars();
      await tester.tap(row(second));
      await tester.pumpAndSettle();
      await tapKey(tester, 'calendar-archive');
      await tapKey(tester, 'calendar-archive-confirm');

      expect(app.schedule.calendarId, 'main');
      expect(badge('main', 'Activo'), findsOneWidget);
      await app.back();
      await app.back();
      // The month shows `main` again: Noche on Monday 19.
      expect(inDayCell(harnessToday, find.text('N')), findsOneWidget);
    });

    testWidgets('archiving the primary one hands the primary to the other', (
      tester,
    ) async {
      late String second;
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async => second = await addSecondCalendar(db),
      );
      await app.openCalendars();
      await tester.tap(row('main'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'calendar-archive');
      await tapKey(tester, 'calendar-archive-confirm');

      expect(await storedPrimary(app), second);
      expect(app.schedule.calendarId, second);
      expect(badge(second, 'Widget y alarmas'), findsOneWidget);
    });

    testWidgets('the last calendar is refused with its own message', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester);
      await app.openCalendars();
      await tester.tap(row('main'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'calendar-archive');

      // No confirmation for something that cannot happen.
      expect(
        find.byKey(const ValueKey('calendar-archive-confirm')),
        findsNothing,
      );
      expect(
        find.text(
          'No puedes archivar el último calendario: siempre tiene que haber uno.',
        ),
        findsOneWidget,
      );
      expect(find.byType(BottomSheet), findsOneWidget);
      final calendars = await storedCalendars(app);
      expect(calendars.single.archived, isFalse);
      expect(find.text('Mi cuadrante'), findsWidgets);
    });

    testWidgets('after archiving down to one, that one cannot go', (
      tester,
    ) async {
      late String second;
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async => second = await addSecondCalendar(db),
      );
      await app.openCalendars();
      await tester.tap(row(second));
      await tester.pumpAndSettle();
      await tapKey(tester, 'calendar-archive');
      await tapKey(tester, 'calendar-archive-confirm');

      await tester.tap(row('main'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'calendar-archive');
      expect(
        find.textContaining('No puedes archivar el último'),
        findsOneWidget,
      );
    });
  });

  group('calendarErrorMessage', () {
    test('every typed refusal has its own sentence', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('es'));
      expect(
        calendarErrorMessage(l10n, const LastCalendarCannotBeArchived()),
        'No puedes archivar el último calendario: siempre tiene que haber uno.',
      );
      expect(
        calendarErrorMessage(l10n, const CalendarNotFound('x')),
        'Ese calendario ya no existe.',
      );
      expect(
        calendarErrorMessage(l10n, ArgumentError('blank')),
        'Pon un nombre al calendario.',
      );
      expect(
        calendarErrorMessage(l10n, StateError('disk')),
        'No se ha podido guardar el calendario. Prueba otra vez.',
      );
    });
  });

  testWidgets('a restored backup refreshes the list', (tester) async {
    final app = await AppUnderTest.pump(tester);
    await app.openCalendars();
    expect(find.text('Pareja'), findsNothing);
    await app.real(() => addSecondCalendar(app.database));
    app.container.invalidate(calendarsControllerProvider);
    await tester.pumpAndSettle();
    expect(find.text('Pareja'), findsOneWidget);
  });
}
