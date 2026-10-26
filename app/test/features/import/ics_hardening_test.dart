import 'package:cuadrante/features/import/application/import_wizard.dart'
    show defaultFileRange;
import 'package:cuadrante/features/import/domain/ics_expansion.dart';
import 'package:cuadrante/features/import/domain/ics_parser.dart';
import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:cuadrante/features/import/domain/recurrence.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hostile and odd `.ics` input: the reader and the expansion stay bounded,
/// and one bad event never ends the import.

String ics(List<String> events) => [
  'BEGIN:VCALENDAR',
  'VERSION:2.0',
  ...events,
  'END:VCALENDAR',
  '',
].join('\r\n');

String event(List<String> lines) =>
    ['BEGIN:VEVENT', ...lines, 'END:VEVENT'].join('\r\n');

const _wide = ImportRange(CivilDate(2026, 1, 1), CivilDate(2027, 12, 31));

void main() {
  group('nesting', () {
    test('thousands of unknown END lines stay linear', () {
      final lines = [
        'BEGIN:VCALENDAR',
        for (var i = 0; i < 30; i++) 'BEGIN:X',
        for (var i = 0; i < 80000; i++) 'END:NOPE',
        'END:VCALENDAR',
      ];
      final watch = Stopwatch()..start();
      parseIcs(lines.join('\n'));
      expect(watch.elapsedMilliseconds, lessThan(1500));
    });

    test('BEGINs deeper than the cap are ignored', () {
      final deep = [
        for (var i = 0; i < maxIcsNesting + 5; i++) 'BEGIN:X$i',
        event(['DTSTART;VALUE=DATE:20261019', 'SUMMARY:Dentro']),
        for (var i = maxIcsNesting + 4; i >= 0; i--) 'END:X$i',
      ];
      final watch = Stopwatch()..start();
      final doc = parseIcs(ics(deep));
      // The event sits under X0..X31 and a VCALENDAR: too deep to be read.
      expect(doc.events, isEmpty);
      expect(watch.elapsedMilliseconds, lessThan(1500));
    });

    test('an event at a normal depth is still read', () {
      final doc = parseIcs(
        ics([
          event(['DTSTART;VALUE=DATE:20261019', 'SUMMARY:Normal']),
        ]),
      );
      expect(doc.events, hasLength(1));
    });
  });

  group('work budget of a file', () {
    test('many costly rules stop at the budget and say truncated', () {
      // Daily from 2000 up to a range in 2026 that holds no June: ~9 500
      // steps per event and not one occurrence.
      final events = [
        for (var i = 0; i < 1000; i++)
          event([
            'DTSTART;VALUE=DATE:20000103',
            'RRULE:FREQ=DAILY;BYDAY=MO;BYMONTH=6;COUNT=99999',
            'SUMMARY:E$i',
          ]),
      ];
      final doc = parseIcs(ics(events));
      const range = ImportRange(CivilDate(2026, 1, 1), CivilDate(2026, 3, 31));
      final watch = Stopwatch()..start();
      final result = expandIcs(doc, range);
      expect(result.truncated, isTrue);
      expect(result.occurrences, isEmpty);
      expect(watch.elapsedMilliseconds, lessThan(5000));
    });

    test('the span of the file (first and last day) is a plain field', () {
      final events = [
        for (var i = 0; i < 2000; i++)
          event([
            'DTSTART:20261001T080000',
            'RRULE:FREQ=DAILY;COUNT=99999',
            'SUMMARY:E$i',
          ]),
      ];
      final watch = Stopwatch()..start();
      final doc = parseIcs(ics(events));
      // Worked out while reading (in the isolate), under the budget.
      expect(doc.firstDate, const CivilDate(2026, 10, 1));
      expect(doc.lastDate, isNotNull);
      expect(watch.elapsedMilliseconds, lessThan(5000));
    });
  });

  group('one-off events out of the range', () {
    test('20 000 old events do not use the room of the one that matters', () {
      final events = [
        for (var i = 0; i < 20000; i++)
          event(['DTSTART:20100105T080000', 'SUMMARY:Viejo']),
        event(['DTSTART:20260105T080000', 'SUMMARY:Nuevo']),
      ];
      const range = ImportRange(CivilDate(2026, 1, 1), CivilDate(2026, 12, 31));
      final result = expandIcs(parseIcs(ics(events)), range);
      expect(result.truncated, isFalse);
      expect(result.occurrences.map((o) => o.title), ['Nuevo']);
    });
  });

  group('DURATION', () {
    test('an absurd duration skips the event and is counted', () {
      final doc = parseIcs(
        ics([
          event([
            'DTSTART:20261019T080000',
            'DURATION:P900000000000000W',
            'SUMMARY:Absurdo',
          ]),
          event([
            'DTSTART:20261019T080000',
            'DURATION:P367D',
            'SUMMARY:Un poco largo',
          ]),
          event(['DTSTART:20261019T080000', 'DURATION:PT8H', 'SUMMARY:Bien']),
        ]),
      );
      expect(doc.events.map((e) => e.summary), ['Bien']);
      expect(doc.skippedEvents, 2);
      expect(expandIcs(doc, _wide).occurrences, hasLength(1));
    });

    test('366 days is still accepted', () {
      final doc = parseIcs(
        ics([
          event(['DTSTART:20261019T080000', 'DURATION:P366D', 'SUMMARY:A']),
        ]),
      );
      expect(doc.events, hasLength(1));
    });

    test('an event that cannot be expanded does not abort the import', () {
      final bad = IcsEvent(
        uid: 'x',
        summary: 'Roto',
        start: const IcsTime(CivilDate(2026, 10, 19), minute: 480),
        duration: 1 << 60,
      );
      final good = IcsEvent(
        uid: 'y',
        summary: 'Bueno',
        start: const IcsTime(CivilDate(2026, 10, 20), minute: 480),
        duration: 480,
      );
      final result = expandIcs(IcsDocument(events: [bad, good]), _wide);
      expect(result.occurrences.map((o) => o.title), contains('Bueno'));
    });

    test('an all-day event with DURATION covers its days', () {
      final doc = parseIcs(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261019',
            'DURATION:P3D',
            'SUMMARY:Vacaciones',
          ]),
        ]),
      );
      final result = expandIcs(doc, _wide);
      expect(
        [for (final o in result.occurrences) o.date.toIso()],
        ['2026-10-19', '2026-10-20', '2026-10-21'],
      );
      expect(doc.lastDate, const CivilDate(2026, 10, 21));
    });

    test('a weekly all-day series with DURATION: the last day counts it', () {
      final doc = parseIcs(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261019',
            'DURATION:P2D',
            'RRULE:FREQ=WEEKLY;COUNT=2',
            'SUMMARY:Guardia',
          ]),
        ]),
      );
      // 19-20 Oct and 26-27 Oct.
      expect(doc.lastDate, const CivilDate(2026, 10, 27));
    });
  });

  group('BY lists', () {
    test('repeated entries are one', () {
      final rule = RecurrenceRule.parse(
        'FREQ=MONTHLY;BYDAY=${List.filled(500, '1MO').join(',')};'
        'BYMONTHDAY=${List.filled(500, '15').join(',')};'
        'BYMONTH=${List.filled(500, '3').join(',')}',
      )!;
      expect(rule.byDay, hasLength(1));
      expect(rule.byMonthDay, [15]);
      expect(rule.byMonth, [3]);
    });

    test('lists far over any real calendar make the rule invalid', () {
      final many = [
        for (var i = 1; i <= 53; i++) ...['${i}MO', '-${i}MO'],
      ].join(',');
      expect(RecurrenceRule.parse('FREQ=MONTHLY;BYDAY=$many'), isNull);
      final huge = List.filled(5000, 'MO').join(',');
      expect(RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=$huge'), isNull);
    });

    test('an invalid list counts the event once and is reported', () {
      final many = [
        for (var i = 1; i <= 53; i++) ...['${i}MO', '-${i}MO'],
      ].join(',');
      final doc = parseIcs(
        ics([
          event([
            'DTSTART;VALUE=DATE:20261019',
            'RRULE:FREQ=MONTHLY;BYDAY=$many',
            'SUMMARY:X',
          ]),
        ]),
      );
      expect(doc.unsupportedRules, 1);
      expect(expandIcs(doc, _wide).occurrences, hasLength(1));
    });

    test('ordinals still pick the right day after the rewrite', () {
      final rule = RecurrenceRule.parse('FREQ=MONTHLY;BYDAY=1MO,-1FR')!;
      final days = rule
          .datesBetween(
            const CivilDate(2026, 10, 1),
            const CivilDate(2026, 10, 1),
            const CivilDate(2026, 11, 30),
          )
          .map((d) => d.toIso())
          .toList();
      expect(days, ['2026-10-05', '2026-10-30', '2026-11-02', '2026-11-27']);
    });
  });

  group('default range of a file', () {
    const today = CivilDate(2026, 10, 20);

    test('a series with a far UNTIL stops at the usual horizon', () {
      final doc = parseIcs(
        ics([
          event([
            'DTSTART;VALUE=DATE:20260105',
            'RRULE:FREQ=WEEKLY;UNTIL=20991231',
            'SUMMARY:A',
          ]),
        ]),
      );
      final range = defaultFileRange(doc, today);
      expect(range.from, const CivilDate(2026, 1, 5));
      expect(range.to, ImportRange.around(today).to);
    });

    test('a long COUNT stops at the usual horizon', () {
      final doc = parseIcs(
        ics([
          event([
            'DTSTART;VALUE=DATE:20260105',
            'RRULE:FREQ=WEEKLY;COUNT=500',
            'SUMMARY:A',
          ]),
        ]),
      );
      final range = defaultFileRange(doc, today);
      expect(range.from, const CivilDate(2026, 1, 5));
      expect(range.to, ImportRange.around(today).to);
    });

    test('a file that starts after the horizon keeps its own dates', () {
      final doc = parseIcs(
        ics([
          event(['DTSTART;VALUE=DATE:20290105', 'SUMMARY:A']),
        ]),
      );
      final range = defaultFileRange(doc, today);
      expect(range.from, const CivilDate(2029, 1, 5));
      expect(range.to, const CivilDate(2029, 1, 5));
    });
  });
}
