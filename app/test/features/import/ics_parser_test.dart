import 'dart:typed_data';

import 'package:cuadrante/features/import/application/import_wizard.dart'
    show defaultFileRange;
import 'package:cuadrante/features/import/domain/ics_expansion.dart';
import 'package:cuadrante/features/import/domain/ics_parser.dart';
import 'package:cuadrante/features/import/domain/import_files.dart';
import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// A calendar around [events] (each a block of `BEGIN:VEVENT ... END:VEVENT`
/// lines), with CRLF line ends like real files.
String ics(List<String> events, {String extra = ''}) => [
  'BEGIN:VCALENDAR',
  'VERSION:2.0',
  'PRODID:-//test//ES',
  if (extra.isNotEmpty) extra,
  ...events,
  'END:VCALENDAR',
  '',
].join('\r\n');

String event(List<String> lines) =>
    ['BEGIN:VEVENT', ...lines, 'END:VEVENT'].join('\r\n');

const _wide = ImportRange(CivilDate(2026, 1, 1), CivilDate(2027, 12, 31));

List<String> days(Expansion e) => [
  for (final o in e.occurrences)
    '${o.date.toIso()} ${o.title} '
        '${o.allDay ? 'todo el día' : '${_hm(o.startMinute)}-${_hm(o.endMinute)}'}',
];

String _hm(int? m) => m == null
    ? '??'
    : '${(m ~/ 60).toString().padLeft(2, '0')}:'
          '${(m % 60).toString().padLeft(2, '0')}';

Expansion expand(String text, {ImportRange range = _wide}) =>
    expandIcs(parseIcs(text), range, targetZone: 'Europe/Madrid');

void main() {
  group('lines', () {
    test('unfolds long lines (CRLF, LF and tab)', () {
      final doc = parseIcs(
        'BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nDTSTART;VALUE=DATE:20261019\r\n'
        'SUMMARY:Turno de ma\r\n \xF1ana muy\r\n\t largo\nEND:VEVENT\nEND:VCALENDAR',
      );
      expect(doc.events.single.summary, 'Turno de mañana muy largo');
    });

    test('unescapes \\n \\, \\; and \\\\', () {
      expect(unescapeIcsText(r'a\, b\; c\\d\nE\Nf'), 'a, b; c\\d\nE\nf');
      expect(unescapeIcsText(r'sin escape \x'), r'sin escape \x');
      final doc = parseIcs(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261019',
            r'SUMMARY:Noche\, 22h\; guardia',
          ]),
        ]),
      );
      expect(doc.events.single.summary, 'Noche, 22h; guardia');
    });

    test('quoted parameter values may contain : and ;', () {
      final doc = parseIcs(
        ics([
          event([
            'DTSTART;TZID="Europe/Madrid";X-FOO="a:b;c":20261019T080000',
            'SUMMARY:M',
          ]),
        ]),
      );
      final start = doc.events.single.start;
      expect(start.zone, 'Europe/Madrid');
      expect(start.minute, 480);
    });

    test('names are case-insensitive and a BOM is ignored', () {
      final doc = parseIcs(
        '﻿begin:vcalendar\r\nbegin:vevent\r\ndtstart;value=date:20261019\r\n'
        'summary:M\r\nend:vevent\r\nend:vcalendar\r\n',
      );
      expect(doc.events, hasLength(1));
      expect(doc.events.single.start.allDay, isTrue);
    });
  });

  group('dates and times', () {
    test('DATE is all day and the end is exclusive', () {
      final e = expand(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261019',
            'DTEND;VALUE=DATE:20261022',
            'SUMMARY:Vacaciones',
          ]),
        ]),
      );
      expect(days(e), [
        '2026-10-19 Vacaciones todo el día',
        '2026-10-20 Vacaciones todo el día',
        '2026-10-21 Vacaciones todo el día',
      ]);
    });

    test('an all-day event with no end is one day', () {
      final e = expand(
        ics([
          event(['DTSTART;VALUE=DATE:20261019', 'SUMMARY:Libre']),
        ]),
      );
      expect(days(e), ['2026-10-19 Libre todo el día']);
    });

    test('TZID Europe/Madrid keeps the wall clock', () {
      final e = expand(
        ics([
          event([
            'DTSTART;TZID=Europe/Madrid:20261019T060000',
            'DTEND;TZID=Europe/Madrid:20261019T140000',
            'SUMMARY:Mañana',
          ]),
        ]),
      );
      expect(days(e), ['2026-10-19 Mañana 06:00-14:00']);
    });

    test('UTC (Z) goes to Madrid time, summer and winter', () {
      final e = expand(
        ics([
          event([
            // 20 Oct 2026: CEST (UTC+2). 06:00Z -> 08:00.
            'DTSTART:20261020T060000Z',
            'DTEND:20261020T140000Z',
            'SUMMARY:Verano',
          ]),
          event([
            // 20 Dec 2026: CET (UTC+1). 06:00Z -> 07:00.
            'DTSTART:20261220T060000Z',
            'DTEND:20261220T140000Z',
            'SUMMARY:Invierno',
          ]),
        ]),
      );
      expect(days(e), [
        '2026-10-20 Verano 08:00-16:00',
        '2026-12-20 Invierno 07:00-15:00',
      ]);
    });

    test('a UTC time can change the day', () {
      final e = expand(
        ics([
          event(['DTSTART:20261019T230000Z', 'SUMMARY:Noche']),
        ]),
      );
      // 23:00Z = 01:00 of the 20th in Madrid (CEST).
      expect(days(e), ['2026-10-20 Noche 01:00-??']);
    });

    test('another TZID is converted to Madrid', () {
      final e = expand(
        ics([
          event([
            'DTSTART;TZID=America/New_York:20261019T090000',
            'DTEND;TZID=America/New_York:20261019T170000',
            'SUMMARY:NY',
          ]),
        ]),
      );
      // 09:00 EDT = 13:00Z = 15:00 CEST.
      expect(days(e), ['2026-10-19 NY 15:00-23:00']);
    });

    test('Windows zone names are understood', () {
      final e = expand(
        ics([
          event([
            'DTSTART;TZID=Romance Standard Time:20261019T060000',
            'SUMMARY:M',
          ]),
        ]),
      );
      expect(days(e), ['2026-10-19 M 06:00-??']);
    });

    test('an unknown zone is read as the phone clock', () {
      final e = expand(
        ics([
          event(['DTSTART;TZID=Mars/Olympus:20261019T060000', 'SUMMARY:M']),
        ]),
      );
      expect(days(e), ['2026-10-19 M 06:00-??']);
    });

    test('floating times are the phone clock', () {
      final e = expand(
        ics([
          event([
            'DTSTART:20261019T220000',
            'DTEND:20261020T060000',
            'SUMMARY:Noche',
          ]),
        ]),
      );
      expect(days(e), ['2026-10-19 Noche 22:00-06:00']);
    });

    test('a night shift belongs to the day it starts', () {
      final doc = parseIcs(
        ics([
          event([
            'DTSTART;TZID=Europe/Madrid:20261019T220000',
            'DURATION:PT8H',
            'SUMMARY:Noche',
          ]),
        ]),
      );
      final o = expandIcs(doc, _wide).occurrences.single;
      expect(o.date, const CivilDate(2026, 10, 19));
      expect(o.startMinute, 22 * 60);
      expect(o.endMinute, 6 * 60);
    });

    test('invalid dates and times drop only that event', () {
      final doc = parseIcs(
        ics([
          event(['DTSTART;VALUE=DATE:20260231', 'SUMMARY:Mal']),
          event(['DTSTART:20261019T250000', 'SUMMARY:Mal hora']),
          event(['SUMMARY:Sin inicio']),
          event(['DTSTART;VALUE=DATE:20261020', 'SUMMARY:Bien']),
        ]),
      );
      expect(doc.skippedEvents, 3);
      expect(doc.events.map((e) => e.summary), ['Bien']);
    });
  });

  group('what is ignored', () {
    test('VTODO, VALARM and VTIMEZONE never become events or titles', () {
      final text = ics([
        'BEGIN:VTIMEZONE',
        'TZID:Europe/Madrid',
        'BEGIN:STANDARD',
        'DTSTART:19701025T030000',
        'END:STANDARD',
        'END:VTIMEZONE',
        'BEGIN:VTODO',
        'DTSTART;VALUE=DATE:20261019',
        'SUMMARY:Tarea',
        'END:VTODO',
        'BEGIN:VEVENT',
        'DTSTART;VALUE=DATE:20261020',
        'SUMMARY:Noche',
        'BEGIN:VALARM',
        'ACTION:DISPLAY',
        'SUMMARY:Alarma',
        'DESCRIPTION:Alarma',
        'TRIGGER:-PT1H',
        'END:VALARM',
        'END:VEVENT',
      ]);
      final doc = parseIcs(text);
      expect(doc.events.map((e) => e.summary), ['Noche']);
    });

    test('cancelled events are not imported', () {
      final e = expand(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261019',
            'SUMMARY:Cancelado',
            'STATUS:CANCELLED',
          ]),
        ]),
      );
      expect(e.occurrences, isEmpty);
    });

    test('events outside the range are left out', () {
      final e = expand(
        ics([
          event(['DTSTART;VALUE=DATE:20251231', 'SUMMARY:Antes']),
          event(['DTSTART;VALUE=DATE:20261019', 'SUMMARY:Dentro']),
        ]),
        range: const ImportRange(
          CivilDate(2026, 1, 1),
          CivilDate(2026, 12, 31),
        ),
      );
      expect(days(e), ['2026-10-19 Dentro todo el día']);
    });
  });

  group('RRULE', () {
    String weekly(String rule, {String exdate = ''}) => ics([
      event([
        'DTSTART;TZID=Europe/Madrid:20261019T060000', // a Monday
        'DTEND;TZID=Europe/Madrid:20261019T140000',
        'RRULE:$rule',
        if (exdate.isNotEmpty) exdate,
        'SUMMARY:M',
      ]),
    ]);

    test('WEEKLY BYDAY with COUNT', () {
      final e = expand(weekly('FREQ=WEEKLY;BYDAY=MO,WE,FR;COUNT=5'));
      expect(days(e), [
        '2026-10-19 M 06:00-14:00',
        '2026-10-21 M 06:00-14:00',
        '2026-10-23 M 06:00-14:00',
        '2026-10-26 M 06:00-14:00',
        '2026-10-28 M 06:00-14:00',
      ]);
    });

    test('WEEKLY with UNTIL (date and Z) is inclusive', () {
      expect(days(expand(weekly('FREQ=WEEKLY;BYDAY=MO;UNTIL=20261102'))), [
        '2026-10-19 M 06:00-14:00',
        '2026-10-26 M 06:00-14:00',
        '2026-11-02 M 06:00-14:00',
      ]);
      expect(
        days(expand(weekly('FREQ=WEEKLY;BYDAY=MO;UNTIL=20261101T225959Z'))),
        ['2026-10-19 M 06:00-14:00', '2026-10-26 M 06:00-14:00'],
      );
    });

    test('INTERVAL=2 skips alternate weeks', () {
      expect(days(expand(weekly('FREQ=WEEKLY;INTERVAL=2;COUNT=3'))), [
        '2026-10-19 M 06:00-14:00',
        '2026-11-02 M 06:00-14:00',
        '2026-11-16 M 06:00-14:00',
      ]);
    });

    test('EXDATE removes one occurrence (timed and date forms)', () {
      final timed = expand(
        weekly(
          'FREQ=WEEKLY;COUNT=4',
          exdate: 'EXDATE;TZID=Europe/Madrid:20261026T060000',
        ),
      );
      expect(days(timed), [
        '2026-10-19 M 06:00-14:00',
        '2026-11-02 M 06:00-14:00',
        '2026-11-09 M 06:00-14:00',
      ]);
      final dateForm = expand(
        weekly(
          'FREQ=WEEKLY;COUNT=3',
          exdate: 'EXDATE;VALUE=DATE:20261102,20261026',
        ),
      );
      expect(days(dateForm), ['2026-10-19 M 06:00-14:00']);
    });

    test('DAILY with COUNT and INTERVAL', () {
      final e = expand(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261019',
            'RRULE:FREQ=DAILY;INTERVAL=3;COUNT=3',
            'SUMMARY:Cada 3',
          ]),
        ]),
      );
      expect(days(e), [
        '2026-10-19 Cada 3 todo el día',
        '2026-10-22 Cada 3 todo el día',
        '2026-10-25 Cada 3 todo el día',
      ]);
    });

    test(
      'a long series is cut to the range, COUNT still counts from the start',
      () {
        final text = ics([
          event([
            'DTSTART;VALUE=DATE:20200101',
            'RRULE:FREQ=DAILY;COUNT=2000',
            'SUMMARY:Diario',
          ]),
        ]);
        // 2000 days from 1 Jan 2020 end on 22 Jun 2025: none in 2026.
        expect(expand(text).occurrences, isEmpty);
        final open = ics([
          event([
            'DTSTART;VALUE=DATE:20200101',
            'RRULE:FREQ=DAILY',
            'SUMMARY:Diario',
          ]),
        ]);
        final jan = expand(
          open,
          range: const ImportRange(
            CivilDate(2026, 1, 1),
            CivilDate(2026, 1, 31),
          ),
        );
        expect(jan.occurrences, hasLength(31));
        expect(jan.occurrences.first.date, const CivilDate(2026, 1, 1));
      },
    );

    test('MONTHLY by month day, by ordinal weekday and by last day', () {
      final byDay = expand(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261001',
            'RRULE:FREQ=MONTHLY;BYDAY=1MO;COUNT=3',
            'SUMMARY:Primer lunes',
          ]),
        ]),
      );
      expect(byDay.occurrences.map((o) => o.date.toIso()), [
        '2026-10-05',
        '2026-11-02',
        '2026-12-07',
      ]);
      final last = expand(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261031',
            'RRULE:FREQ=MONTHLY;BYMONTHDAY=-1;COUNT=3',
            'SUMMARY:Fin de mes',
          ]),
        ]),
      );
      expect(last.occurrences.map((o) => o.date.toIso()), [
        '2026-10-31',
        '2026-11-30',
        '2026-12-31',
      ]);
      final lastFriday = expand(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261030',
            'RRULE:FREQ=MONTHLY;BYDAY=-1FR;COUNT=2',
            'SUMMARY:Último viernes',
          ]),
        ]),
      );
      expect(lastFriday.occurrences.map((o) => o.date.toIso()), [
        '2026-10-30',
        '2026-11-27',
      ]);
    });

    test('MONTHLY on the 31st skips short months', () {
      final e = expand(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261031',
            'RRULE:FREQ=MONTHLY;COUNT=3',
            'SUMMARY:31',
          ]),
        ]),
      );
      expect(e.occurrences.map((o) => o.date.toIso()), [
        '2026-10-31',
        '2026-12-31',
        '2027-01-31',
      ]);
    });

    test('RECURRENCE-ID replaces one occurrence of the series', () {
      final e = expand(
        ics([
          event([
            'UID:serie',
            'DTSTART;TZID=Europe/Madrid:20261019T060000',
            'DTEND;TZID=Europe/Madrid:20261019T140000',
            'RRULE:FREQ=WEEKLY;COUNT=3',
            'SUMMARY:M',
          ]),
          event([
            'UID:serie',
            'RECURRENCE-ID;TZID=Europe/Madrid:20261026T060000',
            'DTSTART;TZID=Europe/Madrid:20261026T140000',
            'DTEND;TZID=Europe/Madrid:20261026T220000',
            'SUMMARY:T',
          ]),
        ]),
      );
      expect(days(e), [
        '2026-10-19 M 06:00-14:00',
        '2026-10-26 T 14:00-22:00',
        '2026-11-02 M 06:00-14:00',
      ]);
    });

    test('an unsupported rule counts the event once and is reported', () {
      final doc = parseIcs(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261019',
            'RRULE:FREQ=YEARLY;COUNT=5',
            'SUMMARY:Cumple',
          ]),
          event([
            'DTSTART;VALUE=DATE:20261019',
            'RRULE:FREQ=MONTHLY;BYSETPOS=1;BYDAY=MO',
            'SUMMARY:Setpos',
          ]),
          event([
            'DTSTART;VALUE=DATE:20261019',
            'RRULE:FREQ=DAILY;INTERVAL=0',
            'SUMMARY:Cero',
          ]),
        ]),
      );
      expect(doc.unsupportedRules, 3);
      expect(expandIcs(doc, _wide).occurrences, hasLength(3));
    });

    test('a hostile rule does not hang or overflow', () {
      final text = ics([
        event([
          'DTSTART;VALUE=DATE:20261019',
          'RRULE:FREQ=DAILY;INTERVAL=999999999;COUNT=999999999',
          'SUMMARY:X',
        ]),
        event([
          'DTSTART;VALUE=DATE:20261019',
          'RRULE:FREQ=WEEKLY;BYDAY=XX,ZZ',
          'SUMMARY:Y',
        ]),
        event([
          'DTSTART;VALUE=DATE:20261019',
          'RRULE:FREQ=DAILY;COUNT=999999999',
          'SUMMARY:Z',
        ]),
      ]);
      final stopwatch = Stopwatch()..start();
      final e = expand(text);
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      expect(e.occurrences.length, lessThanOrEqualTo(maxImportOccurrences));
    });
  });

  group('span of a file', () {
    test('first and last day, all-day ends are exclusive', () {
      final doc = parseIcs(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261109',
            'DTEND;VALUE=DATE:20261112',
            'SUMMARY:A',
          ]),
          event([
            'DTSTART:20261105T220000',
            'DTEND:20261106T060000',
            'SUMMARY:B',
          ]),
        ]),
      );
      expect(doc.firstDate, const CivilDate(2026, 11, 5));
      expect(doc.lastDate, const CivilDate(2026, 11, 11));
      expect(doc.hasOpenEndedRules, isFalse);
    });

    test('a series with COUNT or UNTIL ends where it says', () {
      final doc = parseIcs(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261102',
            'RRULE:FREQ=WEEKLY;COUNT=3',
            'SUMMARY:A',
          ]),
          event([
            'DTSTART;VALUE=DATE:20261102',
            'RRULE:FREQ=DAILY;UNTIL=20261110',
            'SUMMARY:B',
          ]),
        ]),
      );
      expect(doc.lastDate, const CivilDate(2026, 11, 16));
      expect(doc.hasOpenEndedRules, isFalse);
    });

    test('an open series is flagged', () {
      final doc = parseIcs(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261102',
            'RRULE:FREQ=DAILY',
            'SUMMARY:A',
          ]),
        ]),
      );
      expect(doc.hasOpenEndedRules, isTrue);
    });

    test('the default range of a file', () {
      const today = CivilDate(2026, 10, 19);
      final closed = parseIcs(
        ics([
          event(['DTSTART;VALUE=DATE:20261109', 'SUMMARY:A']),
        ]),
      );
      expect(
        defaultFileRange(closed, today),
        const ImportRange(CivilDate(2026, 11, 9), CivilDate(2026, 11, 9)),
      );
      final open = parseIcs(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261109',
            'RRULE:FREQ=DAILY',
            'SUMMARY:A',
          ]),
        ]),
      );
      expect(defaultFileRange(open, today).to, const CivilDate(2027, 4, 18));
      final old = parseIcs(
        ics([
          event([
            'DTSTART;VALUE=DATE:20100109',
            'RRULE:FREQ=DAILY',
            'SUMMARY:A',
          ]),
        ]),
      );
      expect(defaultFileRange(old, today).days, maxImportRangeDays);
      expect(
        defaultFileRange(parseIcs(ics([])), today),
        ImportRange.around(today),
      );
    });
  });

  group('limits', () {
    test('more than 5 000 events are cut and reported', () {
      final events = [
        for (var i = 0; i < 5200; i++)
          event(['DTSTART:20261001T080000', 'SUMMARY:E$i']),
      ];
      final e = expand(ics(events));
      expect(e.occurrences, hasLength(maxImportEvents));
      expect(e.truncated, isTrue);
    });

    test('a 366-day cap on one all-day event', () {
      final e = expand(
        ics([
          event([
            'DTSTART;VALUE=DATE:20260101',
            'DTEND;VALUE=DATE:20300101',
            'SUMMARY:Excedencia',
          ]),
        ]),
      );
      expect(e.occurrences, hasLength(maxAllDaySpanDays));
    });
  });

  group('malformed input', () {
    test('text that is not a calendar is a typed error', () {
      expect(
        () => parseIcs('hola,esto,es,un,csv\n1,2,3'),
        throwsA(
          isA<ImportException>().having(
            (e) => e.problem,
            'problem',
            ImportProblem.notCalendarFile,
          ),
        ),
      );
    });

    test('a calendar with no events is an empty document', () {
      final doc = parseIcs('BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n');
      expect(doc.events, isEmpty);
    });

    test('truncated, unbalanced and garbage lines never throw', () {
      final garbage = [
        'BEGIN:VCALENDAR',
        'BEGIN:VEVENT',
        'DTSTART;VALUE=DATE:20261019',
        'SUMMARY:Sin cerrar',
        '::::',
        ';;;;=',
        'END:VALARM',
        'BEGIN:VEVENT',
        'DTSTART;VALUE=DATE:20261020',
        'SUMMARY:Segundo',
        'END:VEVENT',
        'END:VEVENT',
        'END:VEVENT',
        'RRULE:FREQ=',
        'BEGIN:',
        '',
      ].join('\n');
      final doc = parseIcs(garbage);
      expect(doc.events.map((e) => e.summary), contains('Segundo'));
    });

    test('random bytes never crash the file reader', () {
      final random = <int>[
        for (var i = 0; i < 4000; i++) (i * 7919 + 13) % 256,
      ];
      expect(
        () => readIcsFile(Uint8List.fromList(random)),
        throwsA(isA<ImportException>()),
      );
      // Printable noise with a calendar header.
      final noise =
          'BEGIN:VCALENDAR\n${'\u0001\u0002;:=,\\'.padRight(2000, 'x')}';
      expect(
        readIcsFile(
          Uint8List.fromList(noise.codeUnits.map((c) => c % 128).toList()),
        ),
        isA<IcsDocument>(),
      );
    });

    test('a file over 5 MB is refused before it is read', () {
      expect(
        () => readIcsFile(Uint8List(maxImportFileBytes + 1)),
        throwsA(
          isA<ImportException>().having(
            (e) => e.problem,
            'problem',
            ImportProblem.fileTooLarge,
          ),
        ),
      );
    });

    test('UTF-8, UTF-8 with BOM, UTF-16 and Latin-1 are all read', () {
      const body =
          'BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nDTSTART;VALUE=DATE:20261019\r\n'
          'SUMMARY:Mañana\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n';
      Uint8List utf16(bool le) {
        final out = <int>[le ? 0xFF : 0xFE, le ? 0xFE : 0xFF];
        for (final u in body.codeUnits) {
          out.addAll(le ? [u & 0xFF, u >> 8] : [u >> 8, u & 0xFF]);
        }
        return Uint8List.fromList(out);
      }

      final variants = <Uint8List>[
        Uint8List.fromList(_utf8(body)),
        Uint8List.fromList([0xEF, 0xBB, 0xBF, ..._utf8(body)]),
        utf16(true),
        utf16(false),
        Uint8List.fromList(
          body.codeUnits.map((c) => c > 255 ? 63 : c).toList(),
        ),
      ];
      for (final bytes in variants) {
        expect(readIcsFile(bytes).events.single.summary, 'Mañana');
      }
    });
  });
}

List<int> _utf8(String s) => s.runes.expand((r) {
  if (r < 0x80) return [r];
  if (r < 0x800) return [0xC0 | (r >> 6), 0x80 | (r & 0x3F)];
  return [0xE0 | (r >> 12), 0x80 | ((r >> 6) & 0x3F), 0x80 | (r & 0x3F)];
}).toList();
