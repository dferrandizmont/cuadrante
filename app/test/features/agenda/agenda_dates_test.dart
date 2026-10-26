import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/agenda/domain/agenda.dart';
import 'package:cuadrante/features/agenda/domain/agenda_dates.dart';
import 'package:cuadrante/features/schedule/data/demo_schedule.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

// Search by date (parity audit of 23-oct, item 3): «15/10», «15 oct»...
// Today is Monday 19 October 2026, so 15 Oct (no year) is next year's.

const _today = CivilDate(2026, 10, 19);

CivilDate _d(int y, int m, int d) => CivilDate(y, m, d);

/// The Basque months: the stem without the final «-a» («azaro» for
/// «azaroa») and the month it is.
const _basqueMonths = <(String stem, int month)>[
  ('urtarril', 1),
  ('otsail', 2),
  ('martxo', 3),
  ('apiril', 4),
  ('maiatz', 5),
  ('ekain', 6),
  ('uztail', 7),
  ('abuztu', 8),
  ('irail', 9),
  ('urri', 10),
  ('azaro', 11),
  ('abendu', 12),
];

/// The year the 15th of [month] comes on when no year is written: today is
/// 19 October 2026, so November and December are this year and the other
/// months are next year.
int _yearOf(int month) => month >= 11 ? 2026 : 2027;

void main() {
  setUpAll(initializeLocale);

  CivilDate? parse(String query, {String locale = 'es', CivilDate? today}) =>
      parseAgendaDate(
        query,
        today ?? _today,
        months: agendaMonthLookup(locale),
      );

  group('numbers', () {
    test('day/month without a year: the next time it comes', () {
      expect(parse('15/10'), _d(2027, 10, 15)); // passed this year
      expect(parse('15-10'), _d(2027, 10, 15));
      expect(parse('15.10'), _d(2027, 10, 15));
      expect(parse('25/10'), _d(2026, 10, 25)); // later this year
      expect(parse('1/1'), _d(2027, 1, 1));
      expect(parse('01/01'), _d(2027, 1, 1));
      expect(parse('  25 / 10  '), _d(2026, 10, 25));
    });

    test('today counts as «this year»; yesterday is next year', () {
      expect(parse('19/10'), _today);
      expect(parse('18/10'), _d(2027, 10, 18));
      expect(parse('31/12'), _d(2026, 12, 31));
    });

    test('with year: four digits, or two (20xx)', () {
      expect(parse('15/10/2026'), _d(2026, 10, 15)); // in the past, as asked
      expect(parse('15-10-2026'), _d(2026, 10, 15));
      expect(parse('15-10-26'), _d(2026, 10, 15));
      expect(parse('15/10/27'), _d(2027, 10, 15));
      expect(parse('1/2/2030'), _d(2030, 2, 1));
      expect(parse('15/10/2031'), _d(2031, 10, 15));
    });

    test('days that do not exist give nothing', () {
      expect(parse('31/02'), isNull);
      expect(parse('30/02'), isNull);
      expect(parse('31/04'), isNull);
      expect(parse('31/11/2026'), isNull);
      expect(parse('29/02/2027'), isNull);
      expect(parse('0/10'), isNull);
      expect(parse('15/0'), isNull);
      expect(parse('15/13'), isNull);
      expect(parse('32/01'), isNull);
      expect(parse('15/10/1899'), isNull);
      expect(parse('15/10/2200'), isNull);
    });

    test('29 February: the next leap year, or exactly that year', () {
      expect(parse('29/02'), _d(2028, 2, 29));
      expect(parse('29/02/2028'), _d(2028, 2, 29));
      expect(parse('29/2/24'), _d(2024, 2, 29));
      // 2100 is not a leap year: from 2096 the next 29 Feb is in 2104.
      expect(parse('29/02', today: _d(2096, 3, 1)), _d(2104, 2, 29));
    });

    test('not a date', () {
      for (final query in [
        '',
        '   ',
        '15',
        '2026',
        '15/',
        '/10',
        '15//10',
        '15/10/202',
        '15/10/2026/1',
        '1/2/3/4',
        'a/b',
        '15/10 cena',
        'cena 15/10',
        '123/10',
        '15,10',
      ]) {
        expect(parse(query), isNull, reason: query);
      }
    });
  });

  group('Spanish', () {
    test('day and month name', () {
      expect(parse('15 oct'), _d(2027, 10, 15));
      expect(parse('15 OCT'), _d(2027, 10, 15));
      expect(parse('15 oct.'), _d(2027, 10, 15));
      expect(parse('15 octubre'), _d(2027, 10, 15));
      expect(parse('15 de octubre'), _d(2027, 10, 15));
      expect(parse('15 De Octubre'), _d(2027, 10, 15));
      expect(parse('  15   de   octubre '), _d(2027, 10, 15));
      expect(parse('25 de octubre'), _d(2026, 10, 25));
      expect(parse('1 de enero'), _d(2027, 1, 1));
      expect(parse('3 sept'), _d(2027, 9, 3));
      expect(parse('3 sep'), _d(2027, 9, 3));
      expect(parse('3 septiembre'), _d(2027, 9, 3));
      expect(parse('24 dic'), _d(2026, 12, 24));
      expect(parse('24 diciembre'), _d(2026, 12, 24));
      expect(parse('7 de mayo'), _d(2027, 5, 7));
    });

    test('with year', () {
      expect(parse('15 octubre 2026'), _d(2026, 10, 15));
      expect(parse('15 de octubre de 2026'), _d(2026, 10, 15));
      expect(parse('15 oct 2026'), _d(2026, 10, 15));
      expect(parse('15 oct 26'), _d(2026, 10, 15));
      expect(parse('15 octubre, 2028'), _d(2028, 10, 15));
    });

    test('accents and typing noise', () {
      expect(parse('15 DE OCTUBRE'), _d(2027, 10, 15));
      expect(parse('1 de aGOSTO'), _d(2027, 8, 1));
    });

    test('invalid or not a date', () {
      expect(parse('31 feb'), isNull);
      expect(parse('31 febrero'), isNull);
      expect(parse('31 nov'), isNull);
      expect(parse('30 de febrero de 2028'), isNull);
      expect(parse('29 feb 2027'), isNull);
      expect(parse('0 oct'), isNull);
      expect(parse('32 oct'), isNull);
      expect(parse('octubre'), isNull);
      expect(parse('oct'), isNull);
      expect(parse('2026 octubre'), isNull);
      expect(parse('15 octubre noviembre'), isNull);
      expect(parse('15 oct 2026 2027'), isNull);
      expect(parse('15 oct 1 2 3'), isNull);
      expect(parse('15 cena'), isNull);
      expect(parse('cena 15 oct'), isNull);
      expect(parse('15 15 octubre'), isNull);
      expect(parse('15 de'), isNull);
      expect(parse('dentista'), isNull);
    });
  });

  group('Catalan', () {
    test('names, with the elided «d\'» and «de»', () {
      expect(parse('15 octubre', locale: 'ca'), _d(2027, 10, 15));
      expect(parse('15 oct', locale: 'ca'), _d(2027, 10, 15));
      expect(parse('15 de octubre', locale: 'ca'), _d(2027, 10, 15));
      expect(parse("15 d'octubre", locale: 'ca'), _d(2027, 10, 15));
      expect(parse('15 d’octubre', locale: 'ca'), _d(2027, 10, 15));
      expect(parse("15 D'OCTUBRE", locale: 'ca'), _d(2027, 10, 15));
      expect(parse('3 de juliol', locale: 'ca'), _d(2027, 7, 3));
      expect(parse('3 juliol', locale: 'ca'), _d(2027, 7, 3));
      expect(parse('3 jul', locale: 'ca'), _d(2027, 7, 3));
      expect(parse("1 d'abril", locale: 'ca'), _d(2027, 4, 1));
      expect(parse("1 d'agost", locale: 'ca'), _d(2027, 8, 1));
      expect(parse('8 de març', locale: 'ca'), _d(2027, 3, 8));
      expect(parse('8 de marc', locale: 'ca'), _d(2027, 3, 8));
      expect(parse('8 març', locale: 'ca'), _d(2027, 3, 8));
      expect(parse('8 mar', locale: 'ca'), _d(2027, 3, 8));
      expect(parse('12 de desembre', locale: 'ca'), _d(2026, 12, 12));
      expect(parse('12 des', locale: 'ca'), _d(2026, 12, 12));
      expect(parse('5 de setembre', locale: 'ca'), _d(2027, 9, 5));
      expect(parse('5 set', locale: 'ca'), _d(2027, 9, 5));
      expect(parse('20 de maig', locale: 'ca'), _d(2027, 5, 20));
      expect(parse('20 de gener', locale: 'ca'), _d(2027, 1, 20));
    });

    test('with year and numbers', () {
      expect(parse("15 d'octubre de 2026", locale: 'ca'), _d(2026, 10, 15));
      expect(parse('15 octubre 2026', locale: 'ca'), _d(2026, 10, 15));
      expect(parse('15/10/2026', locale: 'ca'), _d(2026, 10, 15));
      expect(parse('15-10-26', locale: 'ca'), _d(2026, 10, 15));
    });

    test('invalid', () {
      expect(parse('31 de juny', locale: 'ca'), isNull);
      expect(parse("31 d'abril", locale: 'ca'), isNull);
      expect(parse("d'octubre", locale: 'ca'), isNull);
    });
  });

  group('Galician', () {
    test('names', () {
      expect(parse('15 outubro', locale: 'gl'), _d(2027, 10, 15));
      expect(parse('15 de outubro', locale: 'gl'), _d(2027, 10, 15));
      expect(parse('15 out', locale: 'gl'), _d(2027, 10, 15));
      expect(parse('15 de outubro de 2026', locale: 'gl'), _d(2026, 10, 15));
      expect(parse('3 de xullo', locale: 'gl'), _d(2027, 7, 3));
      expect(parse('3 xul', locale: 'gl'), _d(2027, 7, 3));
      expect(parse('5 de xuño', locale: 'gl'), _d(2027, 6, 5));
      expect(parse('5 xuno', locale: 'gl'), _d(2027, 6, 5));
      expect(parse('1 de xaneiro', locale: 'gl'), _d(2027, 1, 1));
      expect(parse('24 de decembro', locale: 'gl'), _d(2026, 12, 24));
      expect(parse('9 de maio', locale: 'gl'), _d(2027, 5, 9));
      expect(parse('9 de setembro', locale: 'gl'), _d(2027, 9, 9));
      expect(parse('15/10', locale: 'gl'), _d(2027, 10, 15));
    });

    test('Spanish names work too', () {
      expect(parse('15 octubre', locale: 'gl'), _d(2027, 10, 15));
      expect(parse('3 julio', locale: 'gl'), _d(2027, 7, 3));
    });

    test('invalid', () {
      expect(parse('31 de febreiro', locale: 'gl'), isNull);
      expect(parse('31 de setembro', locale: 'gl'), isNull);
    });
  });

  group('Basque', () {
    test('year first, with the endings', () {
      expect(parse('2026ko urriaren 15a', locale: 'eu'), _d(2026, 10, 15));
      expect(parse('2026ko urriaren 15', locale: 'eu'), _d(2026, 10, 15));
      expect(parse('2027ko abenduaren 3a', locale: 'eu'), _d(2027, 12, 3));
      expect(parse('2028ko otsailaren 29a', locale: 'eu'), _d(2028, 2, 29));
      expect(parse('2026 urria 15', locale: 'eu'), _d(2026, 10, 15));
      expect(parse('2026 urr 15', locale: 'eu'), _d(2026, 10, 15));
    });

    test('day and month in any order', () {
      expect(parse('urriaren 15a', locale: 'eu'), _d(2027, 10, 15));
      expect(parse('urriaren 25', locale: 'eu'), _d(2026, 10, 25));
      expect(parse('urria 15', locale: 'eu'), _d(2027, 10, 15));
      expect(parse('15 urria', locale: 'eu'), _d(2027, 10, 15));
      expect(parse('15 urr', locale: 'eu'), _d(2027, 10, 15));
      expect(parse('urr 15', locale: 'eu'), _d(2027, 10, 15));
      expect(parse('15a urriaren', locale: 'eu'), _d(2027, 10, 15));
      expect(parse('15 urria 2026', locale: 'eu'), _d(2026, 10, 15));
      expect(parse('urriaren 15 2026', locale: 'eu'), _d(2026, 10, 15));
    });

    test('every month', () {
      const months = [
        'urtarrilaren',
        'otsailaren',
        'martxoaren',
        'apirilaren',
        'maiatzaren',
        'ekainaren',
        'uztailaren',
        'abuztuaren',
        'irailaren',
        'urriaren',
        'azaroaren',
        'abenduaren',
      ];
      for (var i = 0; i < months.length; i++) {
        expect(
          parse('2026ko ${months[i]} 1a', locale: 'eu'),
          _d(2026, i + 1, 1),
          reason: months[i],
        );
        expect(
          parse(
            '1 ${months[i].replaceFirst(RegExp('ren\$'), '')}',
            locale: 'eu',
          ),
          isNotNull,
          reason: months[i],
        );
      }
    });

    test('the month with the day before or after it, with or without «-a»', () {
      for (final (stem, month) in _basqueMonths) {
        final expected = _d(_yearOf(month), month, 15);
        expect(parse('15 $stem', locale: 'eu'), expected, reason: stem);
        expect(parse('$stem 15', locale: 'eu'), expected, reason: stem);
        expect(parse('15 ${stem}a', locale: 'eu'), expected, reason: stem);
        expect(parse('${stem}a 15', locale: 'eu'), expected, reason: stem);
        expect(parse('15a $stem', locale: 'eu'), expected, reason: stem);
        expect(parse('$stem 15a', locale: 'eu'), expected, reason: stem);
      }
    });

    test('the month with a year, with or without «-a»', () {
      for (final (stem, month) in _basqueMonths) {
        expect(parse('2026 $stem 15', locale: 'eu'), _d(2026, month, 15),
            reason: stem);
        expect(parse('2026 ${stem}a 15', locale: 'eu'), _d(2026, month, 15),
            reason: stem);
        expect(parse('15 $stem 2026', locale: 'eu'), _d(2026, month, 15),
            reason: stem);
        expect(parse('15 ${stem}a 2026', locale: 'eu'), _d(2026, month, 15),
            reason: stem);
        expect(parse('$stem 15 2026', locale: 'eu'), _d(2026, month, 15),
            reason: stem);
        expect(parse('${stem}a 15 2026', locale: 'eu'), _d(2026, month, 15),
            reason: stem);
        expect(parse('2026ko $stem 15a', locale: 'eu'), _d(2026, month, 15),
            reason: stem);
        expect(parse('2026ko ${stem}aren 15a', locale: 'eu'),
            _d(2026, month, 15), reason: stem);
        expect(parse('${stem}aren 15', locale: 'eu'),
            _d(_yearOf(month), month, 15), reason: stem);
      }
    });

    test('«15 azaro» and its variants (H-T21-10)', () {
      expect(parse('15 azaro', locale: 'eu'), _d(2026, 11, 15));
      expect(parse('15 azaroa', locale: 'eu'), _d(2026, 11, 15));
      expect(parse('azaro 15', locale: 'eu'), _d(2026, 11, 15));
      expect(parse('azaroa 15', locale: 'eu'), _d(2026, 11, 15));
      expect(parse('2026 azaroa 15', locale: 'eu'), _d(2026, 11, 15));
      expect(parse('15 azaroa 2026', locale: 'eu'), _d(2026, 11, 15));
      // The ones that already worked.
      expect(parse('azaroaren 15', locale: 'eu'), _d(2026, 11, 15));
      expect(parse('2026ko azaroaren 15a', locale: 'eu'), _d(2026, 11, 15));
      expect(parse('15/11', locale: 'eu'), _d(2026, 11, 15));
    });

    test('the Basque months are only Basque', () {
      for (final locale in ['es', 'ca', 'gl', 'en']) {
        for (final (stem, _) in _basqueMonths) {
          expect(parse('15 $stem', locale: locale), isNull,
              reason: '$locale $stem');
          expect(parse('15 ${stem}a', locale: locale), isNull,
              reason: '$locale ${stem}a');
          expect(parse('$stem 15', locale: locale), isNull,
              reason: '$locale $stem 15');
        }
      }
    });

    test('the other languages keep their own months', () {
      expect(parse('15 marzo', locale: 'es'), _d(2027, 3, 15));
      expect(parse('15 mar', locale: 'es'), _d(2027, 3, 15));
      expect(parse('15 març', locale: 'ca'), _d(2027, 3, 15));
      expect(parse('15 marzo', locale: 'gl'), _d(2027, 3, 15));
      expect(parse('15 March', locale: 'en'), _d(2027, 3, 15));
      expect(parse('15 abril', locale: 'es'), _d(2027, 4, 15));
      expect(parse('15 abril', locale: 'ca'), _d(2027, 4, 15));
      expect(parse('15 abril', locale: 'gl'), _d(2027, 4, 15));
    });

    test('numbers and Spanish names work too', () {
      expect(parse('15/10', locale: 'eu'), _d(2027, 10, 15));
      expect(parse('15 octubre', locale: 'eu'), _d(2027, 10, 15));
    });

    test('invalid', () {
      expect(parse('2026ko otsailaren 30a', locale: 'eu'), isNull);
      expect(parse('2027ko otsailaren 29a', locale: 'eu'), isNull);
      expect(parse('2026ko urriaren', locale: 'eu'), isNull);
      expect(parse('urriaren', locale: 'eu'), isNull);
      expect(parse('2026ko 2027ko urriaren', locale: 'eu'), isNull);
    });
  });

  group('English', () {
    test('day first and month first', () {
      expect(parse('15 Oct', locale: 'en'), _d(2027, 10, 15));
      expect(parse('15 October', locale: 'en'), _d(2027, 10, 15));
      expect(parse('Oct 15', locale: 'en'), _d(2027, 10, 15));
      expect(parse('October 15', locale: 'en'), _d(2027, 10, 15));
      expect(parse('oct. 25', locale: 'en'), _d(2026, 10, 25));
      expect(parse('15th October', locale: 'en'), _d(2027, 10, 15));
      expect(parse('15 of October', locale: 'en'), _d(2027, 10, 15));
      expect(parse('Sept 3', locale: 'en'), _d(2027, 9, 3));
      expect(parse('Sep 3', locale: 'en'), _d(2027, 9, 3));
      expect(parse('3 December', locale: 'en'), _d(2026, 12, 3));
    });

    test('with year', () {
      expect(parse('October 15, 2026', locale: 'en'), _d(2026, 10, 15));
      expect(parse('Oct 15 2026', locale: 'en'), _d(2026, 10, 15));
      expect(parse('15 October 2026', locale: 'en'), _d(2026, 10, 15));
      expect(parse('15 Oct 26', locale: 'en'), _d(2026, 10, 15));
      expect(parse('Oct 15 26', locale: 'en'), _d(2026, 10, 15));
      expect(parse('2026 October 15', locale: 'en'), _d(2026, 10, 15));
    });

    test('numbers are day/month, as in the rest of the app', () {
      expect(parse('15/10', locale: 'en'), _d(2027, 10, 15));
      expect(parse('10/15', locale: 'en'), isNull);
    });

    test('invalid', () {
      expect(parse('Feb 30', locale: 'en'), isNull);
      expect(parse('Feb 29 2027', locale: 'en'), isNull);
      expect(parse('October', locale: 'en'), isNull);
      expect(parse('shift 15', locale: 'en'), isNull);
    });
  });

  group('the month lookup', () {
    test('has every month of every language', () {
      for (final locale in ['es', 'ca', 'gl', 'eu', 'en']) {
        final lookup = agendaMonthLookup(locale);
        expect(lookup.values.toSet(), {for (var m = 1; m <= 12; m++) m});
        // Folded: no case, accents or dots.
        for (final key in lookup.keys) {
          expect(key, key.toLowerCase());
          expect(key, isNot(contains('.')));
          expect(key, isNot(matches(RegExp('[áàéèíòóúüñç]'))));
        }
      }
    });

    test('a region and an unknown language fall back to Spanish', () {
      expect(agendaMonthLookup('es_ES')['octubre'], 10);
      expect(agendaMonthLookup('ca-ES')['juliol'], 7);
      expect(agendaMonthLookup('xx')['octubre'], 10);
    });

    test('the Basque months also go without their final «-a»', () {
      final lookup = agendaMonthLookup('eu');
      for (final (stem, month) in _basqueMonths) {
        expect(lookup[stem], month, reason: stem);
        expect(lookup['${stem}a'], month, reason: '$stem a');
      }
      // The pairs the issue warns about: «urri»/«urria» and
      // «abuztu»/«abuztua».
      expect(lookup['urri'], 10);
      expect(lookup['urria'], 10);
      expect(lookup['abuztu'], 8);
      expect(lookup['abuztua'], 8);
    });

    test('the other languages do not get the Basque months', () {
      for (final locale in ['es', 'ca', 'gl', 'en']) {
        for (final (stem, _) in _basqueMonths) {
          expect(agendaMonthLookup(locale)[stem], isNull, reason: locale);
          expect(agendaMonthLookup(locale)['${stem}a'], isNull, reason: locale);
        }
      }
    });
  });

  group('searchAgenda gives the day', () {
    AgendaMonthLookup months() => agendaMonthLookup('es');
    final demo = buildDemoSchedule(_today);

    AgendaSearchResult search(
      String query, {
      Schedule? schedule,
      AgendaMonthLookup? lookup,
    }) => searchAgenda(
      schedule ?? demo,
      const [],
      query,
      _today,
      months: lookup ?? months(),
    );

    test('a day with nothing on it is still the first result', () {
      // 12 Dec 2026 is beyond the demo window with no note.
      final result = search('12/12/2026');
      expect(result.dateItem?.date, _d(2026, 12, 12));
      expect(result.dateItem?.note, isNull);
      expect(result.items, isEmpty);
    });

    test('it carries the shifts, note and own holiday of the day', () {
      // The demo has a night shift and a note on the 20th.
      final result = search('20 oct');
      expect(result.dateItem?.date, _d(2026, 10, 20));
      expect(result.dateItem?.note, 'Cambio con Marta si sale el turno');
      expect(result.dateItem?.shifts.map((s) => s.id), ['night']);
    });

    test('the text matches follow, without repeating the day', () {
      final withNote = demo.copyWith(
        entries: {
          ...demo.entries,
          _d(2026, 11, 3): const DayEntry(
            date: CivilDate(2026, 11, 3),
            note: 'Cena 3 oct con Marta',
          ),
        },
      );
      final result = search('marta', schedule: withNote);
      expect(result.dateItem, isNull);
      expect(result.items.map((i) => i.date), contains(_d(2026, 10, 20)));

      final both = search('20 oct', schedule: withNote);
      expect(both.dateItem?.date, _d(2026, 10, 20));
      expect(both.items.where((i) => i.date == _d(2026, 10, 20)), isEmpty);
    });

    test('a date in the past is found too', () {
      expect(search('3/3/2025').dateItem?.date, _d(2025, 3, 3));
    });

    test('invalid dates and plain text give no day', () {
      expect(search('31/02').dateItem, isNull);
      expect(search('31 feb').dateItem, isNull);
      expect(search('noche').dateItem, isNull);
      expect(search('   ').dateItem, isNull);
    });

    test('without a month lookup the text is all that is searched', () {
      final result = searchAgenda(demo, const [], '25/10', _today);
      expect(result.dateItem, isNull);
    });

    test('the month names follow the language', () {
      final ca = agendaMonthLookup('ca');
      expect(
        search("25 d'octubre", lookup: ca).dateItem?.date,
        _d(2026, 10, 25),
      );
      expect(
        searchAgenda(
          demo,
          const [],
          '2027ko urriaren 15a',
          _today,
          months: agendaMonthLookup('eu'),
        ).dateItem?.date,
        _d(2027, 10, 15),
      );
    });
  });
}
