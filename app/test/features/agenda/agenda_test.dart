import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:cuadrante/features/agenda/domain/agenda.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:cuadrante/features/schedule/data/demo_schedule.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../calendar/harness.dart';

const _today = CivilDate(2026, 10, 19);

/// The demo schedule plus [notes] (date -> text) as note-only entries.
Schedule _withNotes(Map<CivilDate, String> notes) {
  final demo = buildDemoSchedule(_today);
  return demo.copyWith(
    entries: {
      ...demo.entries,
      for (final e in notes.entries)
        e.key: DayEntry(
          date: e.key,
          shiftTypeIds: demo.entries[e.key]?.shiftTypeIds,
          note: e.value,
        ),
    },
  );
}

Holiday _own(CivilDate date, String name) => Holiday(
  date: date,
  name: name,
  scope: HolidayScope.local,
  source: HolidaySource.user,
);

Holiday _official(CivilDate date, String name) =>
    Holiday(date: date, name: name, scope: HolidayScope.national);

void main() {
  setUpAll(initializeLocale);

  group('upcomingAgenda', () {
    test('notes from today on, soonest first; blank and past ones out', () {
      final schedule = _withNotes({
        const CivilDate(2026, 11, 3): 'Revisión coche',
        const CivilDate(2026, 10, 19): 'Hoy cuenta',
        const CivilDate(2026, 10, 18): 'Ayer no',
        const CivilDate(2026, 12, 24): 'Cena',
        const CivilDate(2026, 10, 30): '   ',
      });
      final items = upcomingAgenda(schedule, const [], _today);
      expect(
        [for (final i in items) i.date],
        [
          _today,
          const CivilDate(2026, 10, 20), // the demo note
          const CivilDate(2026, 11, 3),
          const CivilDate(2026, 12, 24),
        ],
      );
      expect(items.first.note, 'Hoy cuenta');
      expect(items[1].note, 'Cambio con Marta si sale el turno');
      // Shifts are those of the day.
      expect(items[1].shifts.map((s) => s.id), ['night']);
    });

    test('own holidays are listed with or without a note; official ones '
        'are not', () {
      final schedule = _withNotes({const CivilDate(2026, 11, 3): 'Nota'});
      final items = upcomingAgenda(schedule, [
        _own(const CivilDate(2026, 11, 3), 'Patrón'),
        _own(const CivilDate(2026, 11, 20), 'Mi cumpleaños'),
        _own(const CivilDate(2026, 10, 1), 'Pasado'),
        _official(const CivilDate(2026, 12, 8), 'Inmaculada'),
      ], _today);
      expect(
        [for (final i in items) i.date],
        [
          const CivilDate(2026, 10, 20),
          const CivilDate(2026, 11, 3),
          const CivilDate(2026, 11, 20),
        ],
      );
      expect(items[1].ownHoliday?.name, 'Patrón');
      expect(items[1].note, 'Nota');
      expect(items[2].note, isNull);
      expect(items[2].ownHoliday?.name, 'Mi cumpleaños');
    });

    test('nothing to show gives an empty list', () {
      final demo = buildDemoSchedule(_today);
      final bare = demo.copyWith(entries: const {});
      expect(upcomingAgenda(bare, const [], _today), isEmpty);
    });

    test('groupByMonth keeps order and splits on month and year', () {
      final schedule = _withNotes({
        const CivilDate(2026, 10, 25): 'a',
        const CivilDate(2026, 11, 1): 'b',
        const CivilDate(2026, 11, 30): 'c',
        const CivilDate(2027, 11, 2): 'd',
      });
      final groups = groupByMonth(upcomingAgenda(schedule, const [], _today));
      expect(
        [for (final g in groups) (g.year, g.month, g.items.length)],
        [(2026, 10, 2), (2026, 11, 2), (2027, 11, 1)],
      );
    });
  });

  group('searchAgenda', () {
    test('H-T09-3: «festivo» finds the holidays the person added, not the '
        'official ones', () {
      final schedule = _withNotes({const CivilDate(2026, 11, 3): 'Una nota'});
      final holidays = [
        _own(const CivilDate(2026, 11, 20), 'Aniversario empresa'),
        _official(const CivilDate(2026, 12, 8), 'Inmaculada'),
      ];
      List<CivilDate> found(String query) => [
        for (final i in searchAgenda(
          schedule,
          holidays,
          query,
          _today,
          holidayKeywords: 'festivo festivos',
        ).items)
          i.date,
      ];
      expect(found('festivo'), [const CivilDate(2026, 11, 20)]);
      expect(found('FESTIVOS'), [const CivilDate(2026, 11, 20)]);
      expect(found('festivo aniversario'), [const CivilDate(2026, 11, 20)]);
      // The name still works, and a day without own holiday is not found.
      expect(found('aniversario'), [const CivilDate(2026, 11, 20)]);
      expect(found('festivo nota'), isEmpty);
    });

    for (final (locale, singular, plural) in [
      ('es', 'festivo', 'festivos'),
      ('ca', 'festiu', 'festius'),
      ('gl', 'festivo', 'festivos'),
      ('eu', 'jaieguna', 'jaiegunak'),
      ('en', 'holiday', 'holidays'),
    ]) {
      test('own holiday search uses $locale presentation terms', () {
        final l10n = lookupAppLocalizations(Locale(locale));
        const ownDay = CivilDate(2026, 11, 20);
        final holidays = [
          _own(ownDay, 'Aniversario'),
          _official(const CivilDate(2026, 12, 8), 'Inmaculada'),
        ];
        for (final query in [singular, plural.toUpperCase()]) {
          final result = searchAgenda(
            _withNotes({}),
            holidays,
            query,
            _today,
            holidayKeywords:
                '${l10n.agendaHoliday('')} ${l10n.holidayImportTitle}',
          );
          expect(result.items.map((i) => i.date), [ownDay]);
        }
      });
    }

    List<CivilDate> find(
      Schedule schedule,
      String query, {
      Iterable<Holiday> holidays = const [],
    }) => [
      for (final i in searchAgenda(schedule, holidays, query, _today).items)
        i.date,
    ];

    test('ignores accents and case, in the note and in the query', () {
      final schedule = _withNotes({
        const CivilDate(2026, 11, 3): 'Revisión médica en el Hospital',
        const CivilDate(2026, 11, 4): 'CAFÉ con Marta',
      });
      expect(find(schedule, 'revision medica'), [const CivilDate(2026, 11, 3)]);
      expect(find(schedule, 'REVISIÓN'), [const CivilDate(2026, 11, 3)]);
      expect(find(schedule, 'cafe'), [const CivilDate(2026, 11, 4)]);
      expect(find(schedule, 'café'), [const CivilDate(2026, 11, 4)]);
      // "marta" is in the demo note of the 20th as well.
      expect(find(schedule, 'MARTA'), [
        const CivilDate(2026, 10, 20),
        const CivilDate(2026, 11, 4),
      ]);
    });

    test('emojis match as they are, with other words around', () {
      final schedule = _withNotes({
        const CivilDate(2026, 11, 8): '🎂 Cumple de Ana',
        const CivilDate(2026, 11, 9): 'Tarta 🎂🎉',
        const CivilDate(2026, 11, 10): 'Sin emoji',
      });
      expect(find(schedule, '🎂'), [
        const CivilDate(2026, 11, 8),
        const CivilDate(2026, 11, 9),
      ]);
      expect(find(schedule, '🎉'), [const CivilDate(2026, 11, 9)]);
      expect(find(schedule, '🎂 cumple'), [const CivilDate(2026, 11, 8)]);
      expect(find(schedule, '🎊'), isEmpty);
    });

    test('every word has to match, in any order', () {
      final schedule = _withNotes({
        const CivilDate(2026, 11, 3): 'Dentista a primera hora',
        const CivilDate(2026, 11, 4): 'Dentista a última hora',
      });
      expect(find(schedule, 'ultima dentista'), [const CivilDate(2026, 11, 4)]);
      expect(find(schedule, '  dentista  '), [
        const CivilDate(2026, 11, 3),
        const CivilDate(2026, 11, 4),
      ]);
    });

    test('searches the shift names, also combined with the note', () {
      final schedule = _withNotes({});
      // Vacaciones only on the two manual days (27 and 28 Oct).
      expect(find(schedule, 'vacaciones'), [
        const CivilDate(2026, 10, 27),
        const CivilDate(2026, 10, 28),
      ]);
      // A shift name + a word of the note of that same day.
      expect(find(schedule, 'noche marta'), [const CivilDate(2026, 10, 20)]);
    });

    test('ALL notes: also the past ones, after the upcoming, latest first', () {
      final schedule = _withNotes({
        const CivilDate(2025, 3, 2): 'Informe anual',
        const CivilDate(2026, 10, 1): 'Informe trimestral',
        const CivilDate(2026, 12, 1): 'Informe final',
        const CivilDate(2029, 5, 5): 'Informe lejano',
      });
      expect(find(schedule, 'informe'), [
        const CivilDate(2026, 12, 1),
        const CivilDate(2029, 5, 5),
        const CivilDate(2026, 10, 1),
        const CivilDate(2025, 3, 2),
      ]);
    });

    test('the rotation is searched around today only, manual days always', () {
      final demo = buildDemoSchedule(_today);
      final farOff = demo.copyWith(
        entries: {
          ...demo.entries,
          const CivilDate(2031, 1, 7): const DayEntry(
            date: CivilDate(2031, 1, 7),
            shiftTypeIds: ['vacation'],
          ),
        },
      );
      final nights = find(farOff, 'noche');
      expect(nights, isNotEmpty);
      expect(
        nights.every((d) => d.differenceInDays(_today).abs() <= 366),
        isTrue,
      );
      expect(find(farOff, 'vacaciones'), contains(const CivilDate(2031, 1, 7)));
    });

    test(
      'own holidays by name; no query finds nothing; the limit truncates',
      () {
        final schedule = _withNotes({});
        final holidays = [_own(const CivilDate(2026, 11, 20), 'Mi cumpleaños')];
        expect(find(schedule, 'CUMPLEANOS', holidays: holidays), [
          const CivilDate(2026, 11, 20),
        ]);
        expect(find(schedule, '   '), isEmpty);
        expect(find(schedule, ''), isEmpty);

        final result = searchAgenda(
          schedule,
          const [],
          'noche',
          _today,
          limit: 5,
        );
        expect(result.items, hasLength(5));
        expect(result.truncated, isTrue);
        expect(result.items.first.date, _today, reason: 'soonest first');
        final all = searchAgenda(schedule, const [], 'vacaciones', _today);
        expect(all.truncated, isFalse);
      },
    );
  });

  group('screen', () {
    Finder key(String k) => find.byKey(ValueKey(k));

    Future<void> openAgenda(WidgetTester tester) async {
      await tester.tap(key('open-agenda'));
      await tester.pumpAndSettle();
      expect(find.text('Agenda'), findsWidgets);
    }

    testWidgets('opens from the month header and lists the upcoming notes '
        'grouped by month', (tester) async {
      await pumpCalendar(tester);
      final controller = containerOf(tester)
          .read(scheduleControllerProvider.notifier);
      controller.setNote(const CivilDate(2026, 11, 3), 'Revisión coche');
      controller.setNote(const CivilDate(2027, 1, 9), 'Examen');
      controller.setNote(const CivilDate(2026, 10, 10), 'Ya pasó');
      await tester.pumpAndSettle();

      await openAgenda(tester);

      expect(find.text('OCTUBRE'), findsOneWidget);
      expect(find.text('NOVIEMBRE'), findsOneWidget);
      expect(find.text('ENERO 2027'), findsOneWidget);
      expect(find.text('Cambio con Marta si sale el turno'), findsOneWidget);
      expect(find.text('Revisión coche'), findsOneWidget);
      expect(find.text('Examen'), findsOneWidget);
      expect(find.text('Ya pasó'), findsNothing);
      // The shifts of the day come with their code and name.
      expect(
        find.descendant(
          of: key('agenda-day-2026-10-20'),
          matching: find.text('N · Noche'),
        ),
        findsOneWidget,
      );
      // Order: the 20th, then November, then January.
      final tops = [
        for (final d in ['2026-10-20', '2026-11-03', '2027-01-09'])
          tester.getTopLeft(key('agenda-day-$d')).dy,
      ];
      expect(tops, [...tops]..sort());
    });

    testWidgets('tapping a row opens the day detail', (tester) async {
      await pumpCalendar(tester);
      await openAgenda(tester);
      await tester.tap(key('agenda-day-2026-10-20'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Martes, 20 de octubre'), findsOneWidget);
    });

    testWidgets('own holidays are listed; the empty state explains', (
      tester,
    ) async {
      await pumpCalendar(tester);
      final container = containerOf(tester);
      container
          .read(scheduleControllerProvider.notifier)
          .setNote(const CivilDate(2026, 10, 20), null);
      await tester.pumpAndSettle();
      await openAgenda(tester);
      expect(find.text('Sin notas próximas'), findsOneWidget);

      await tester.runAsync(
        () => container
            .read(holidayControllerProvider.notifier)
            .addUserHoliday(
              date: const CivilDate(2026, 11, 20),
              name: 'Patrón',
            ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sin notas próximas'), findsNothing);
      expect(find.text('Festivo: Patrón'), findsOneWidget);
    });

    testWidgets('search: accents, case, emojis, past notes and shift names', (
      tester,
    ) async {
      await pumpCalendar(tester);
      final controller = containerOf(tester)
          .read(scheduleControllerProvider.notifier);
      controller.setNote(const CivilDate(2026, 11, 3), 'Revisión médica 🩺');
      controller.setNote(const CivilDate(2026, 3, 2), 'Médico de cabecera');
      await tester.pumpAndSettle();
      await openAgenda(tester);
      // The past note is not in the upcoming list.
      expect(find.text('Médico de cabecera'), findsNothing);

      Future<void> search(String text) async {
        await tester.enterText(key('agenda-search'), text);
        await tester.pumpAndSettle();
      }

      await search('MÉDIC');
      expect(find.text('2 resultados'), findsOneWidget);
      expect(find.text('Revisión médica 🩺'), findsOneWidget);
      expect(find.text('Médico de cabecera'), findsOneWidget);
      // Upcoming first, then the past, each month with its year.
      expect(find.text('NOVIEMBRE 2026'), findsOneWidget);
      expect(find.text('MARZO 2026'), findsOneWidget);
      expect(
        tester.getTopLeft(key('agenda-day-2026-11-03')).dy,
        lessThan(tester.getTopLeft(key('agenda-day-2026-03-02')).dy),
      );

      await search('🩺');
      expect(find.text('1 resultado'), findsOneWidget);
      expect(find.text('Revisión médica 🩺'), findsOneWidget);

      await search('vacaciones');
      expect(find.text('2 resultados'), findsOneWidget);
      expect(key('agenda-day-2026-10-27'), findsOneWidget);

      await search('zzz');
      expect(find.text('Nada encontrado'), findsOneWidget);
      expect(find.textContaining('«zzz»'), findsOneWidget);

      await tester.tap(key('agenda-search-clear'));
      await tester.pumpAndSettle();
      expect(find.text('Nada encontrado'), findsNothing);
      expect(key('agenda-day-2026-10-20'), findsOneWidget);
    });

    testWidgets('«Notas» is the default; «Turnos» lists every upcoming day '
        'with its shifts, days off as «Libre», and the choice is kept', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openAgenda(tester);

      // Notas: only the day with a note.
      expect(key('agenda-mode-notes'), findsOneWidget);
      expect(key('agenda-mode-shifts'), findsOneWidget);
      expect(key('agenda-day-2026-10-20'), findsOneWidget);
      expect(key('agenda-day-2026-10-21'), findsNothing);
      expect(key('agenda-free'), findsNothing);

      await tester.tap(key('agenda-mode-shifts'));
      await tester.pumpAndSettle();

      // Turnos: today and the next days, with or without anything on them.
      expect(key('agenda-day-2026-10-19'), findsOneWidget);
      expect(key('agenda-day-2026-10-21'), findsOneWidget);
      // The 20th keeps its note and its shift.
      expect(
        find.descendant(
          of: key('agenda-day-2026-10-20'),
          matching: find.text('Cambio con Marta si sale el turno'),
        ),
        findsOneWidget,
      );
      // Two shifts in a day: both chips, each with its hours.
      final doubled = key('agenda-day-2026-10-21');
      expect(
        find.descendant(of: doubled, matching: find.textContaining(' · ')),
        findsAtLeastNWidgets(2),
      );
      expect(
        find.descendant(of: doubled, matching: find.textContaining('–')),
        findsAtLeastNWidgets(2),
      );
      // The day cleared by hand (22 Oct) is a day off.
      expect(
        find.descendant(
          of: key('agenda-day-2026-10-22'),
          matching: find.text('Libre'),
        ),
        findsOneWidget,
      );
      // A day with a shift does not say «Libre».
      expect(
        find.descendant(
          of: key('agenda-day-2026-10-21'),
          matching: find.text('Libre'),
        ),
        findsNothing,
      );
      expect(find.text('Sin notas próximas'), findsNothing);

      // Leaving the agenda and coming back keeps «Turnos» (session memory).
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(key('open-agenda'));
      await tester.pumpAndSettle();
      expect(key('agenda-day-2026-10-21'), findsOneWidget);

      // And back to Notas.
      await tester.tap(key('agenda-mode-notes'));
      await tester.pumpAndSettle();
      expect(key('agenda-day-2026-10-21'), findsNothing);
      expect(key('agenda-day-2026-10-20'), findsOneWidget);
    });

    testWidgets('«Turnos» ends 60 days after today', (tester) async {
      await pumpCalendar(tester);
      await openAgenda(tester);
      await tester.tap(key('agenda-mode-shifts'));
      await tester.pumpAndSettle();
      final list = find.descendant(
        of: key('agenda-list'),
        matching: find.byType(Scrollable),
      );
      // Today + 59 = 17 December 2026; the 18th is out.
      await tester.scrollUntilVisible(
        key('agenda-day-2026-12-17'),
        300,
        scrollable: list,
      );
      expect(key('agenda-day-2026-12-17'), findsOneWidget);
      expect(key('agenda-day-2026-12-18'), findsNothing);
    });

    testWidgets('the search works in «Turnos» too', (tester) async {
      await pumpCalendar(tester);
      await openAgenda(tester);
      await tester.tap(key('agenda-mode-shifts'));
      await tester.pumpAndSettle();
      await tester.enterText(key('agenda-search'), 'vacaciones');
      await tester.pumpAndSettle();
      expect(find.text('2 resultados'), findsOneWidget);
      // Search results are not «Libre»-filled lists.
      expect(key('agenda-free'), findsNothing);
      await tester.tap(key('agenda-search-clear'));
      await tester.pumpAndSettle();
      expect(key('agenda-day-2026-10-22'), findsOneWidget);
    });

    testWidgets('search by date: the day comes first, even with nothing on '
        'it, and opens', (tester) async {
      await pumpCalendar(tester);
      await openAgenda(tester);

      Future<void> search(String text) async {
        await tester.enterText(key('agenda-search'), text);
        await tester.pumpAndSettle();
      }

      // The 22nd is a day off with no note: found by its date.
      await search('22/10');
      expect(find.text('1 resultado'), findsOneWidget);
      expect(key('agenda-day-2026-10-22'), findsOneWidget);
      expect(
        find.descendant(
          of: key('agenda-day-2026-10-22'),
          matching: find.text('Libre'),
        ),
        findsOneWidget,
      );

      // The same day in words.
      for (final text in ['22 de octubre', '22 oct 2026', '22-10-26']) {
        await search(text);
        expect(key('agenda-day-2026-10-22'), findsOneWidget, reason: text);
      }

      // A past day, with its year.
      await search('15/09/2026');
      expect(key('agenda-day-2026-09-15'), findsOneWidget);
      expect(find.text('SEPTIEMBRE 2026'), findsOneWidget);

      // No year: next year's if it has gone by.
      await search('15 oct');
      expect(key('agenda-day-2027-10-15'), findsOneWidget);

      // Tapping it opens the day, as any other result.
      await search('22/10');
      await tester.tap(key('agenda-day-2026-10-22'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Jueves, 22 de octubre'), findsOneWidget);
    });

    testWidgets('search by date: the text matches follow the day', (
      tester,
    ) async {
      await pumpCalendar(tester);
      final controller = containerOf(tester)
          .read(scheduleControllerProvider.notifier);
      controller.setNote(const CivilDate(2026, 11, 3), 'Cena 22/10 en casa');
      controller.setNote(const CivilDate(2026, 10, 22), 'Dentista 22/10');
      await tester.pumpAndSettle();
      await openAgenda(tester);
      await tester.enterText(key('agenda-search'), '22/10');
      await tester.pumpAndSettle();
      // The day, once, then the other note that has the text.
      expect(find.text('2 resultados'), findsOneWidget);
      expect(key('agenda-day-2026-10-22'), findsOneWidget);
      expect(key('agenda-day-2026-11-03'), findsOneWidget);
      expect(
        tester.getTopLeft(key('agenda-day-2026-10-22')).dy,
        lessThan(tester.getTopLeft(key('agenda-day-2026-11-03')).dy),
      );
    });

    testWidgets('search by date: a date that does not exist finds nothing', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openAgenda(tester);
      await tester.enterText(key('agenda-search'), '31/02');
      await tester.pumpAndSettle();
      expect(find.text('Nada encontrado'), findsOneWidget);
      await tester.enterText(key('agenda-search'), '31 feb');
      await tester.pumpAndSettle();
      expect(find.text('Nada encontrado'), findsOneWidget);
    });

    testWidgets('survives large text and the dark theme', (tester) async {
      await pumpCalendar(
        tester,
        textScale: 1.6,
        brightness: Brightness.dark,
        size: const Size(320, 568),
      );
      await openAgenda(tester);
      expect(tester.takeException(), isNull);
      await tester.enterText(key('agenda-search'), 'noche');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
