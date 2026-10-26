import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/real_font.dart';
import '../../support/test_storage.dart';
import '../../support/text_lines.dart';

// QA campaign, T07: an archived calendar could not be recovered (H-T07-1),
// archiving the one the widget and alarms follow moved them without a word
// (H-T07-2), «Comparar» had no button to swap the two calendars (H-T07-4).

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  Future<List<Calendar>> stored(AppUnderTest app) => app.real(
    () => CalendarsRepository(app.database).list(includeArchived: true),
  );

  Future<String> storedPrimary(AppUnderTest app) =>
      app.real(() => CalendarsRepository(app.database).primaryId());

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = _key(key);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Opens the editor of [id] from the list and archives it, confirming.
  Future<void> archive(WidgetTester tester, String id) async {
    await tester.ensureVisible(_key('calendar-row-$id'));
    await tester.tap(_key('calendar-row-$id'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'calendar-archive');
    await tapKey(tester, 'calendar-archive-confirm');
  }

  group('repository: unarchive', () {
    late AppDatabase db;
    late CalendarsRepository repo;

    setUp(() {
      db = openMemoryDatabase();
      repo = CalendarsRepository(db);
    });
    tearDown(() => db.close());

    test('brings it back where it was, with its name and colour', () async {
      await repo.ensureMain();
      final second = await repo.create(name: 'Pareja', colorValue: 0xFF123456);
      await repo.archive(second.id);
      expect((await repo.list()).map((c) => c.id), ['main']);

      await repo.unarchive(second.id);
      final back = await repo.list();
      expect(back.map((c) => c.id), ['main', second.id]);
      expect(back.last.name, 'Pareja');
      expect(back.last.colorValue, 0xFF123456);
      expect(back.last.archived, isFalse);
    });

    test('keeps the widget and alarms where archiving moved them', () async {
      await repo.ensureMain();
      final second = await repo.create(name: 'Pareja', colorValue: 1);
      await repo.setPrimary('main');
      await repo.archive('main');
      expect(await repo.primaryId(), second.id);
      await repo.unarchive('main');
      expect(await repo.primaryId(), second.id);
    });

    test('recovers more than ten with their data and order intact', () async {
      await repo.ensureMain();
      final created = <Calendar>[];
      for (var i = 1; i <= 12; i++) {
        created.add(await repo.create(name: 'C$i', colorValue: i));
      }
      final before = await repo.list();
      for (final c in created) {
        await repo.archive(c.id);
      }
      // Keep ten active calendars before recovering the archived twelve.
      for (var i = 0; i < 9; i++) {
        await repo.create(name: 'Extra $i', colorValue: i);
      }
      for (final c in created) {
        await repo.unarchive(c.id);
      }
      final restored = await repo.list();
      expect(restored, hasLength(22));
      expect(restored.take(13), before);
      expect(
        (await repo.list(includeArchived: true)).where((c) => c.archived),
        isEmpty,
      );
    });

    test('an unknown id is refused; one not archived is left alone', () async {
      await repo.ensureMain();
      await expectLater(
        repo.unarchive('ghost'),
        throwsA(isA<CalendarNotFound>()),
      );
      await repo.unarchive('main');
      expect((await repo.get('main'))!.archived, isFalse);
    });
  });

  group('H-T07-1: «Archivados» on the Calendarios screen', () {
    testWidgets('collapsed with a count; open, «Recuperar» lists it again', (
      tester,
    ) async {
      late String second;
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async => second = await addSecondCalendar(db),
      );
      await app.openCalendars();
      expect(_key('calendars-archived'), findsNothing);

      await archive(tester, second);
      expect(_key('calendar-row-$second'), findsNothing);
      expect(find.text('Archivados (1)'), findsOneWidget);
      expect(_key('calendar-archived-$second'), findsNothing, reason: 'closed');

      await tapKey(tester, 'calendars-archived-toggle');
      expect(_key('calendar-archived-$second'), findsOneWidget);
      expect(find.text('Pareja'), findsOneWidget);

      await tapKey(tester, 'calendar-restore-$second');
      expect(_key('calendar-row-$second'), findsOneWidget);
      expect(_key('calendars-archived'), findsNothing);
      expect(find.text('«Pareja» recuperado'), findsOneWidget);
      expect((await stored(app)).where((c) => c.archived), isEmpty);
    });

    testWidgets('recovers an eleventh calendar from the archived section', (
      tester,
    ) async {
      late String second;
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async {
          second = await addSecondCalendar(db);
          final repo = CalendarsRepository(db);
          await repo.archive(second);
          for (var i = 0; i < 9; i++) {
            await repo.create(name: 'Extra $i', colorValue: 0xFF000000 + i);
          }
        },
      );
      await app.openCalendars();
      await tapKey(tester, 'calendars-archived-toggle');
      await tapKey(tester, 'calendar-restore-$second');

      expect(find.text('«Pareja» recuperado'), findsOneWidget);
      expect(_key('calendar-row-$second'), findsOneWidget);
      expect(_key('calendars-archived'), findsNothing);
      expect(
        (await stored(app)).firstWhere((c) => c.id == second).archived,
        isFalse,
      );
      expect((await stored(app)).where((c) => !c.archived), hasLength(11));
    });

    for (final width in [320.0, 412.0]) {
      testWidgets('x2.0 at $width dp: no word of the section breaks', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        late String second;
        final app = await AppUnderTest.pump(
          tester,
          size: Size(width, 900),
          prepare: (db) async {
            second = await addSecondCalendar(db, name: 'Calendario de pareja');
            await CalendarsRepository(db).archive(second);
          },
        );
        await app.openCalendars();
        await tapKey(tester, 'calendars-archived-toggle');
        expect(_key('calendar-restore-$second'), findsOneWidget);
        expect(brokenParagraphs(tester), isEmpty);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('H-T07-2: archiving the calendar of the widget and alarms warns', () {
    testWidgets('the primary one: the dialog says who takes them over', (
      tester,
    ) async {
      late String second;
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async => second = await addSecondCalendar(db),
      );
      await app.openCalendars();
      await tester.tap(_key('calendar-row-main'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'calendar-archive');

      expect(find.text('¿Archivar «Mi cuadrante»?'), findsOneWidget);
      expect(
        find.textContaining('El widget y las alarmas pasarán a «Pareja»'),
        findsOneWidget,
      );
      // Cancelling changes nothing.
      await tester.tap(_key('confirm-cancel'));
      await tester.pumpAndSettle();
      expect(await storedPrimary(app), 'main');

      await tapKey(tester, 'calendar-archive');
      await tapKey(tester, 'calendar-archive-confirm');
      // And that is what happened.
      expect(await storedPrimary(app), second);
    });

    testWidgets('another one: no such line', (tester) async {
      late String second;
      await AppUnderTest.pump(
        tester,
        prepare: (db) async => second = await addSecondCalendar(db),
      ).then((app) => app.openCalendars());
      await tester.tap(_key('calendar-row-$second'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'calendar-archive');
      expect(find.text('¿Archivar «Pareja»?'), findsOneWidget);
      expect(find.textContaining('pasarán a'), findsNothing);
    });

    testWidgets('names the first calendar left, as the repository picks it', (
      tester,
    ) async {
      late String second;
      late String third;
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async {
          second = await addSecondCalendar(db);
          third = await addSecondCalendar(db, name: 'Tercero');
        },
      );
      await app.openCalendars();
      await tester.tap(_key('calendar-row-main'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'calendar-archive');
      expect(find.textContaining('pasarán a «Pareja»'), findsOneWidget);
      await tapKey(tester, 'calendar-archive-confirm');
      expect(await storedPrimary(app), second);
      expect(third, isNotEmpty);
    });
  });

  group('H-T07-4: swapping the compared calendars', () {
    testWidgets('«Intercambiar» puts the second first and the first second', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async => addSecondCalendar(db),
      );
      app.container.read(routerProvider).go(AppRoutes.compare);
      await tester.pumpAndSettle();

      Finder name(String row, String text) =>
          find.descendant(of: _key(row), matching: find.text(text));
      expect(name('compare-first', 'Mi cuadrante'), findsOneWidget);
      expect(name('compare-second', 'Pareja'), findsOneWidget);

      await tester.tap(_key('compare-swap'));
      await tester.pumpAndSettle();
      expect(name('compare-first', 'Pareja'), findsOneWidget);
      expect(name('compare-second', 'Mi cuadrante'), findsOneWidget);

      await tester.tap(_key('compare-swap'));
      await tester.pumpAndSettle();
      expect(name('compare-first', 'Mi cuadrante'), findsOneWidget);
    });
  });
}
