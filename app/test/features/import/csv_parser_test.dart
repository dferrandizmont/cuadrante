import 'dart:typed_data';

import 'package:cuadrante/features/import/domain/csv_parser.dart';
import 'package:cuadrante/features/import/domain/import_files.dart';
import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('delimiters', () {
    for (final (name, delimiter) in [
      ('comma', ','),
      ('semicolon', ';'),
      ('tab', '\t'),
    ]) {
      test('$name is detected', () {
        final table = parseCsv(
          [
            ['Fecha', 'Turno'].join(delimiter),
            ['19/10/2026', 'M'].join(delimiter),
            ['20/10/2026', 'T'].join(delimiter),
          ].join('\n'),
        );
        expect(table.delimiter, delimiter);
        expect(table.rows, hasLength(3));
        expect(table.rows[1], ['19/10/2026', 'M']);
      });
    }

    test('a quoted cell may hold the delimiter, quotes and a line break', () {
      final table = parseCsv(
        'fecha;turno;nota\r\n'
        '19/10/2026;M;"a;b ""c""\nsegunda línea"\r\n'
        '20/10/2026;T;\r\n',
      );
      expect(table.rows[1][2], 'a;b "c"\nsegunda línea');
      expect(table.rows[2], ['20/10/2026', 'T', '']);
    });

    test('blank lines are skipped, any line ending works, BOM is ignored', () {
      final table = parseCsv('﻿fecha,turno\r\r19/10/2026,M\n\n20/10/2026,T');
      expect(table.rows, hasLength(3));
      expect(table.rows.first, ['fecha', 'turno']);
    });

    test('one column is not a CSV', () {
      expect(
        () => parseCsv('hola\nadiós\n'),
        throwsA(
          isA<ImportException>().having(
            (e) => e.problem,
            'problem',
            ImportProblem.notCsv,
          ),
        ),
      );
      expect(() => parseCsv(''), throwsA(isA<ImportException>()));
    });
  });

  group('header', () {
    test('the first row is a header when it holds no date', () {
      final table = parseCsv('Fecha;Turno\n19/10/2026;M');
      expect(table.hasHeader, isTrue);
      expect(table.dataRows, [
        ['19/10/2026', 'M'],
      ]);
    });

    test('a first row with a date is data', () {
      final table = parseCsv('19/10/2026;M\n20/10/2026;T');
      expect(table.hasHeader, isFalse);
      expect(table.dataRows, hasLength(2));
    });

    test('withHeader flips the reading', () {
      final table = parseCsv('19/10/2026;M\n20/10/2026;T').withHeader(true);
      expect(table.dataRows, hasLength(1));
    });
  });

  group('dates', () {
    test('day first, ISO and compact', () {
      expect(parseCsvDate('19/10/2026'), const CivilDate(2026, 10, 19));
      expect(parseCsvDate('9/3/2026'), const CivilDate(2026, 3, 9));
      expect(parseCsvDate('19-10-2026'), const CivilDate(2026, 10, 19));
      expect(parseCsvDate('19.10.2026'), const CivilDate(2026, 10, 19));
      expect(parseCsvDate('19/10/26'), const CivilDate(2026, 10, 19));
      expect(parseCsvDate('2026-10-19'), const CivilDate(2026, 10, 19));
      expect(parseCsvDate('2026/10/19'), const CivilDate(2026, 10, 19));
      expect(parseCsvDate('20261019'), const CivilDate(2026, 10, 19));
      expect(
        parseCsvDate(' 2026-10-19T08:00:00 '),
        const CivilDate(2026, 10, 19),
      );
      expect(parseCsvDate('19/10/2026 08:30'), const CivilDate(2026, 10, 19));
    });

    test('a time inside the date cell is kept', () {
      expect(parseCsvDateTime('2026-10-19T08:30')?.minute, 8 * 60 + 30);
      expect(parseCsvDateTime('19/10/2026')?.minute, isNull);
    });

    test('impossible dates are nothing', () {
      for (final bad in [
        '31/02/2026',
        '32/01/2026',
        '10/13/2026-x',
        '00/10/2026',
        '2026-13-01',
        '19/10/1800',
        'ayer',
        '',
        '12345',
      ]) {
        expect(parseCsvDate(bad), isNull, reason: bad);
      }
    });

    test('times', () {
      expect(parseCsvTime('8:00'), 480);
      expect(parseCsvTime('08:30'), 510);
      expect(parseCsvTime('22.15'), 22 * 60 + 15);
      expect(parseCsvTime('8h'), 480);
      expect(parseCsvTime('8h30'), 510);
      expect(parseCsvTime('06:00:00'), 360);
      expect(parseCsvTime('24:00'), isNull);
      expect(parseCsvTime('8:75'), isNull);
      expect(parseCsvTime('M'), isNull);
      expect(parseCsvTime('19/10/2026'), isNull);
    });
  });

  group('columns', () {
    test('date, code and times from the content and the header', () {
      final table = parseCsv(
        'Turno;Fecha;Inicio;Fin\n'
        'M;19/10/2026;06:00;14:00\n'
        'T;20/10/2026;14:00;22:00\n'
        'N;21/10/2026;22:00;06:00\n',
      );
      final columns = guessColumns(table)!;
      expect(columns.date, 1);
      expect(columns.title, 0);
      expect(columns.start, 2);
      expect(columns.end, 3);
    });

    test('without header and without times', () {
      final table = parseCsv('19/10/2026,Mañana\n20/10/2026,Tarde\n');
      final columns = guessColumns(table)!;
      expect(columns.date, 0);
      expect(columns.title, 1);
      expect(columns.start, isNull);
    });

    test('nothing that looks like dates gives no guess', () {
      final table = parseCsv('a,b\nc,d\ne,f\n');
      expect(guessColumns(table), isNull);
    });
  });

  group('reading rows', () {
    test('all-day rows and timed rows', () {
      final table = parseCsv(
        'fecha,turno,inicio,fin\n'
        '19/10/2026,Mañana,06:00,14:00\n'
        '20/10/2026,Libre,,\n',
      );
      final reading = readCsv(table, guessColumns(table)!);
      expect(reading.skippedRows, 0);
      final first = reading.occurrences.first;
      expect(first.title, 'Mañana');
      expect(first.startMinute, 360);
      expect(first.endMinute, 840);
      expect(first.allDay, isFalse);
      final second = reading.occurrences.last;
      expect(second.allDay, isTrue);
      expect(second.startMinute, isNull);
    });

    test('bad rows are skipped, counted and located', () {
      final table = parseCsv(
        'fecha,turno\n'
        '19/10/2026,M\n'
        'xx/yy/zzzz,M\n'
        '20/10/2026,\n'
        '31/02/2026,T\n'
        '21/10/2026,T\n',
      );
      final reading = readCsv(table, guessColumns(table)!);
      expect(reading.occurrences.map((o) => o.date.toIso()), [
        '2026-10-19',
        '2026-10-21',
      ]);
      expect(reading.skippedRows, 3);
      expect(reading.skippedExamples, [3, 4, 5]);
    });

    test('a row shorter than the header does not crash', () {
      final table = parseCsv('fecha,turno,inicio\n19/10/2026,M\n20/10/2026\n');
      final reading = readCsv(
        table,
        const CsvColumns(date: 0, title: 1, start: 2),
      );
      expect(reading.occurrences, hasLength(1));
      expect(reading.skippedRows, 1);
    });

    test('more rows than the cap are cut and reported', () {
      final rows = StringBuffer('fecha,turno\n');
      for (var i = 0; i < 5100; i++) {
        final d = const CivilDate(2020, 1, 1).addDays(i);
        rows.writeln('${d.toIso()},M');
      }
      final table = parseCsv(rows.toString());
      final reading = readCsv(table, guessColumns(table)!);
      expect(reading.occurrences, hasLength(maxImportEvents));
      expect(reading.truncated, isTrue);
    });

    test('a date-time cell gives the start when there is no time column', () {
      final table = parseCsv(
        'inicio,turno\n2026-10-19T22:00,N\n2026-10-20T06:00,M\n',
      );
      final reading = readCsv(table, guessColumns(table)!);
      expect(reading.occurrences.first.startMinute, 22 * 60);
    });
  });

  group('files', () {
    test('Windows-1252 bytes (Excel) are read', () {
      final bytes = Uint8List.fromList([
        ...'fecha;turno\n19/10/2026;Ma'.codeUnits,
        0xF1, // ñ in Latin-1
        ...'ana\n'.codeUnits,
      ]);
      final table = readCsvFile(bytes);
      expect(table.rows[1][1], 'Mañana');
    });

    test('binary data is a typed error, not a crash', () {
      expect(
        () =>
            readCsvFile(Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 0, 0, 0])),
        throwsA(isA<ImportException>()),
      );
    });
  });
}
