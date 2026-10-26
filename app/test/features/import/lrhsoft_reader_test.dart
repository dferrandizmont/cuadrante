import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/features/import/data/lrhsoft_reader.dart';
import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:cuadrante/features/import/domain/lrhsoft_backup.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'lrhsoft_support.dart';

LrhsoftShiftType typeOf(LrhsoftBackup b, int id) =>
    b.shiftTypes.firstWhere((t) => t.id == id);

LrhsoftDay dayOf(LrhsoftBackup b, CivilDate date) =>
    b.days.firstWhere((d) => d.date == date);

void expectProblem(void Function() read, ImportProblem problem) {
  expect(
    read,
    throwsA(
      isA<ImportException>().having((e) => e.problem, 'problem', problem),
    ),
  );
}

void main() {
  group('the date of a day (month counted from 0)', () {
    test('20260909 is 9 October and 20260931 is 31 October', () {
      expect(decodeLrhsoftDate(20260909), const CivilDate(2026, 10, 9));
      expect(decodeLrhsoftDate(20260931), const CivilDate(2026, 10, 31));
    });

    test('January is month 0, December is 11', () {
      expect(decodeLrhsoftDate(20260001), const CivilDate(2026, 1, 1));
      expect(decodeLrhsoftDate(20261131), const CivilDate(2026, 12, 31));
    });

    test('a month 12 or more is not a date', () {
      expect(decodeLrhsoftDate(20261201), isNull);
      expect(decodeLrhsoftDate(20261331), isNull);
    });

    test('a day the month does not have is not a date', () {
      // Month 1 is February: it has no 30th. Month 2 is March: it has.
      expect(decodeLrhsoftDate(20260130), isNull);
      expect(decodeLrhsoftDate(20260230), const CivilDate(2026, 3, 30));
      expect(decodeLrhsoftDate(20260531), isNull, reason: 'June has 30');
      expect(decodeLrhsoftDate(20260129), isNull, reason: '2026 is not leap');
      expect(decodeLrhsoftDate(20280129), const CivilDate(2028, 2, 29));
      expect(decodeLrhsoftDate(20260900), isNull);
    });

    test('anything that is not a plausible integer is not a date', () {
      expect(decodeLrhsoftDate(null), isNull);
      expect(decodeLrhsoftDate('20260909'), isNull);
      expect(decodeLrhsoftDate(20260909.0), isNull);
      expect(decodeLrhsoftDate(-20260909), isNull);
      expect(decodeLrhsoftDate(99999999), isNull);
      expect(decodeLrhsoftDate(0), isNull);
    });
  });

  group('times and colours', () {
    test('HH:mm is validated', () {
      expect(parseLrhsoftTime('07:00'), 420);
      expect(parseLrhsoftTime('7:05'), 425);
      expect(parseLrhsoftTime('23:59'), 1439);
      expect(parseLrhsoftTime('00:00'), 0);
      expect(parseLrhsoftTime('24:00'), isNull);
      expect(parseLrhsoftTime('12:60'), isNull);
      expect(parseLrhsoftTime('12'), isNull);
      expect(parseLrhsoftTime(null), isNull);
      expect(parseLrhsoftTime(700), isNull);
    });

    test('colours are signed 32-bit ARGB', () {
      expect(decodeLrhsoftColor(-2407), 0xFFFFF699);
      expect(decodeLrhsoftColor(-16777216), 0xFF000000);
      expect(decodeLrhsoftColor(-551046)! & 0xFF000000, 0xFF000000);
      expect(decodeLrhsoftColor(0xFF112233), 0xFF112233);
      expect(decodeLrhsoftColor('red'), isNull);
    });
  });

  group('notes (HTML)', () {
    test('hostile notes cost linear time (no regex backtracking)', () {
      final n = maxImportNoteLength * 8;
      for (final hostile in [
        '<br${' ' * n}',
        '<' * n,
        ' ' * n,
        '&${'a' * n}',
        '<br>${' \t' * (n ~/ 2)}<br>',
      ]) {
        final watch = Stopwatch()..start();
        lrhsoftNoteText(hostile);
        expect(
          watch.elapsedMilliseconds,
          lessThan(200),
          reason: hostile.substring(0, 4),
        );
      }
    });

    test('controls and bidi overrides are removed, tabs and breaks stay', () {
      expect(
        lrhsoftNoteText('a&#8238;b\u0001c\u202Ed<br>e\tf\u2028g'),
        'abcd\ne\tfg',
      );
    });

    test('tags go, entities are decoded', () {
      expect(
        lrhsoftNoteText(
          '<p dir="ltr">Revisi&#243;n m&#233;dica 9:30, llevar informe</p>',
        ),
        'Revisión médica 9:30, llevar informe',
      );
      expect(
        lrhsoftNoteText('<b>A</b> &amp; B &lt;3 &quot;x&quot;'),
        'A & B <3 "x"',
      );
      expect(lrhsoftNoteText('&#x1F600; &#X41;'), '\u{1F600} A');
      expect(lrhsoftNoteText('caf&eacute;&nbsp;con leche'), 'café con leche');
    });

    test('<br>, </p> and </div> are line breaks; source newlines are not', () {
      expect(
        lrhsoftNoteText(
          '<p>uno</p>\n<p>dos<br>tres<br/>cuatro</p><div>cinco</div>',
        ),
        'uno\ndos\ntres\ncuatro\ncinco',
      );
      expect(lrhsoftNoteText('a\nb'), 'a b');
      expect(
        lrhsoftNoteText('<p>a</p><p></p><p></p><p></p><p>b</p>'),
        'a\n\nb',
      );
    });

    test('a decoded entity is not read as a tag', () {
      expect(lrhsoftNoteText('&lt;b&gt;no&lt;/b&gt;'), '<b>no</b>');
    });

    test('empty and blank notes are no note', () {
      expect(lrhsoftNoteText(null), isNull);
      expect(lrhsoftNoteText(''), isNull);
      expect(lrhsoftNoteText('<p dir="ltr"></p>'), isNull);
      expect(lrhsoftNoteText('<p>&nbsp;</p><br>'), isNull);
      expect(lrhsoftNoteText(42), isNull);
    });

    test('a broken entity is dropped or kept, never a crash', () {
      expect(lrhsoftNoteText('a&#0;b'), 'ab');
      expect(lrhsoftNoteText('a&#99999999;b'), 'a&#99999999;b');
      expect(lrhsoftNoteText('a&unknown;b'), 'a&unknown;b');
      expect(lrhsoftNoteText('a &#xD800; b'), 'a  b');
    });

    test('a huge note is cut', () {
      final text = lrhsoftNoteText('x' * 100000)!;
      expect(text.length, maxImportNoteLength);
    });
  });

  group('reading a backup', () {
    late Directory temp;

    setUp(() => temp = Directory.systemTemp.createTempSync('lrh_reader_'));
    tearDown(() => temp.deleteSync(recursive: true));

    LrhsoftBackup read(Uint8List bytes) =>
        readLrhsoftBackup(bytes, tempDirectory: temp);

    List<String> leftovers() => [
      for (final e in temp.listSync(recursive: true)) p.basename(e.path),
    ];

    test('types: names, abbreviations, times, split shifts and colours', () {
      final backup = read(
        buildShifter(
          types: sampleTypes,
          days: [ShifterDay(shifterDate(2026, 11, 9), t1: 7)],
        ),
      );
      expect(backup.shiftTypes, hasLength(6));
      expect(backup.invalidRows, 0);

      final morning = typeOf(backup, 7);
      expect(morning.name, 'Mañana');
      expect(morning.abbreviation, 'Mor.');
      expect(morning.startMinute, 7 * 60);
      expect(morning.endMinute, 15 * 60);
      expect(morning.colorValue, 0xFFFFF699);
      expect(morning.segment2StartMinute, isNull);

      // A night that ends the next morning: the end is before the start.
      final night = typeOf(backup, 5);
      expect((night.startMinute, night.endMinute), (23 * 60, 7 * 60));

      // «Libre»: 00:00-00:00 is no time at all.
      final free = typeOf(backup, 3);
      expect(free.hasTimes, isFalse);
      expect(free.endMinute, isNull);

      // A split shift keeps both segments.
      final split = typeOf(backup, 4);
      expect(split.abbreviation, 'Mor./Aft.');
      expect((split.startMinute, split.endMinute), (10 * 60, 14 * 60));
      expect(
        (split.segment2StartMinute, split.segment2EndMinute),
        (16 * 60, 20 * 60),
      );

      // Times in the second slot without the flag are not a segment.
      final guard = typeOf(backup, 8);
      expect(guard.name, 'Guardia Médica');
      expect(guard.segment2StartMinute, isNull);
    });

    test('days: up to two shifts, notes, month 0, erased days left out', () {
      final backup = read(
        buildShifter(
          types: sampleTypes,
          days: [
            // 9 Nov, a Mañana.
            ShifterDay(shifterDate(2026, 11, 9), t1: 7),
            // 19 Nov: two shifts.
            ShifterDay(shifterDate(2026, 11, 19), t1: 7, t2: 6),
            // 31 Oct: the trap day.
            ShifterDay(20260931, t1: 3),
            // A note and no shift.
            ShifterDay(
              shifterDate(2026, 11, 7),
              note: '<p dir="ltr">Revisi&#243;n m&#233;dica</p>',
            ),
            // Nothing at all (an erased day).
            ShifterDay(shifterDate(2026, 11, 8)),
            // Only the second slot.
            ShifterDay(shifterDate(2026, 11, 10), t2: 5),
          ],
        ),
      );
      expect(backup.invalidRows, 0);
      expect(backup.days.map((d) => d.date), [
        const CivilDate(2026, 10, 31),
        const CivilDate(2026, 11, 7),
        const CivilDate(2026, 11, 9),
        const CivilDate(2026, 11, 10),
        const CivilDate(2026, 11, 19),
      ], reason: 'in date order, without the empty day');
      expect(dayOf(backup, const CivilDate(2026, 10, 31)).shiftIds, [3]);
      expect(dayOf(backup, const CivilDate(2026, 11, 19)).shiftIds, [7, 6]);
      expect(dayOf(backup, const CivilDate(2026, 11, 10)).shiftIds, [5]);
      final noteDay = dayOf(backup, const CivilDate(2026, 11, 7));
      expect(noteDay.shiftIds, isEmpty);
      expect(noteDay.note, 'Revisión médica');
      expect(backup.firstDate, const CivilDate(2026, 10, 31));
      expect(backup.lastDate, const CivilDate(2026, 11, 19));
    });

    test('invalid rows are skipped and counted', () {
      final backup = read(
        buildShifter(
          types: [
            ...sampleTypes,
            // A time that does not exist: the type stays, without times.
            const ShifterType(9, 'Rara', start: '25:00', end: '07:00'),
            // A split whose second segment does not fit: one segment.
            const ShifterType(
              10,
              'Partido raro',
              start: '08:00',
              end: '20:00',
              start2: '19:00',
              end2: '23:00',
              split: 1,
            ),
          ],
          days: [
            ShifterDay(shifterDate(2026, 11, 9), t1: 7),
            ShifterDay(20261331, t1: 7), // month 13
            ShifterDay(20260130, t1: 7), // 30 February
            ShifterDay(shifterDate(2026, 11, 11), t1: 99), // no such shift
            ShifterDay(shifterDate(2026, 11, 12), t1: 7, t2: 99), // half
          ],
        ),
      );
      // 2 dates + 1 time + 1 split + 2 dangling shifts.
      expect(backup.invalidRows, 6);
      expect(backup.days.map((d) => d.date), [
        const CivilDate(2026, 11, 9),
        const CivilDate(2026, 11, 12),
      ]);
      expect(dayOf(backup, const CivilDate(2026, 11, 12)).shiftIds, [7]);
      expect(typeOf(backup, 9).hasTimes, isFalse);
      expect(typeOf(backup, 10).segment2StartMinute, isNull);
      expect(typeOf(backup, 10).startMinute, 8 * 60);
    });

    test('a file from an older version with fewer columns still opens', () {
      final backup = read(
        buildShifter(
          typesTable:
              'CREATE TABLE tablaTurnos (_id INTEGER PRIMARY KEY, texto TEXT, '
              'color INTEGER, horaInicio1 TEXT, horaFinal1 TEXT)',
          daysTable:
              'CREATE TABLE dias (fecha INTEGER PRIMARY KEY, turno1 INTEGER)',
          types: sampleTypes,
          days: [ShifterDay(shifterDate(2026, 11, 9), t1: 7, note: 'ignorada')],
        ),
      );
      expect(backup.invalidRows, 0);
      final morning = typeOf(backup, 7);
      expect(morning.abbreviation, isNull);
      expect(morning.startMinute, 7 * 60);
      expect(morning.segment2StartMinute, isNull, reason: 'no split column');
      expect(dayOf(backup, const CivilDate(2026, 11, 9)).note, isNull);
    });

    test('the temp copy is deleted, on success and on failure', () {
      read(buildShifter(types: sampleTypes));
      expect(leftovers(), isEmpty);
      expectProblem(
        () => read(Uint8List.fromList(List.filled(100, 7))),
        ImportProblem.notLrhsoftFile,
      );
      expectProblem(
        () => read(
          buildShifter(build: (db) => db.execute('CREATE TABLE otra (a)')),
        ),
        ImportProblem.notLrhsoftFile,
      );
      expect(leftovers(), isEmpty);
    });

    test('a file that is not SQLite is refused', () {
      expectProblem(
        () => read(Uint8List.fromList('BEGIN:VCALENDAR\r\n'.codeUnits)),
        ImportProblem.notLrhsoftFile,
      );
      expectProblem(() => read(Uint8List(0)), ImportProblem.notLrhsoftFile);
    });

    test('a damaged SQLite file is refused', () {
      final good = buildShifter(types: sampleTypes);
      // The header survives, the pages do not.
      final cut = Uint8List.sublistView(good, 0, 100);
      expectProblem(() => read(cut), ImportProblem.notLrhsoftFile);
      final scrambled = Uint8List.fromList(good);
      for (var i = 100; i < scrambled.length; i++) {
        scrambled[i] = (i * 31) & 0xFF;
      }
      expectProblem(() => read(scrambled), ImportProblem.notLrhsoftFile);
    });

    test('a file without dias or tablaTurnos is refused', () {
      expectProblem(
        () => read(buildShifter(build: (db) => db.execute(shifterTypesTable))),
        ImportProblem.notLrhsoftFile,
      );
      expectProblem(
        () => read(buildShifter(build: (db) => db.execute(shifterDaysTable))),
        ImportProblem.notLrhsoftFile,
      );
      expectProblem(
        () => read(
          buildShifter(
            build: (db) {
              db.execute('CREATE TABLE dias (otra INTEGER)');
              db.execute(shifterTypesTable);
            },
          ),
        ),
        ImportProblem.notLrhsoftFile,
      );
    });

    test('a VIEW called dias (or tablaTurnos) is refused', () {
      expectProblem(
        () => read(
          buildShifter(
            build: (db) {
              db.execute(shifterTypesTable);
              db.execute(
                'CREATE TABLE real_days (fecha INTEGER, turno1 INTEGER)',
              );
              db.execute('CREATE VIEW dias AS SELECT * FROM real_days');
            },
          ),
        ),
        ImportProblem.notLrhsoftFile,
      );
      expectProblem(
        () => read(
          buildShifter(
            build: (db) {
              db.execute(shifterDaysTable);
              db.execute('CREATE TABLE real_types (_id INTEGER, texto TEXT)');
              db.execute('CREATE VIEW tablaTurnos AS SELECT * FROM real_types');
            },
          ),
        ),
        ImportProblem.notLrhsoftFile,
      );
    });

    test('a file bigger than 50 MB is refused before it is written', () {
      expectProblem(
        () => read(Uint8List(maxLrhsoftFileBytes + 1)),
        ImportProblem.tooComplex,
      );
      expect(leftovers(), isEmpty);
    });

    test('more than 20 000 days is refused, 20 000 is not', () {
      Uint8List withDays(int count) => buildShifter(
        build: (db) {
          db.execute(shifterTypesTable);
          db.execute(shifterDaysTable);
          db.execute("INSERT INTO tablaTurnos (_id, texto) VALUES (1, 'M')");
          db.execute('BEGIN');
          final insert = db.prepare(
            'INSERT INTO dias (fecha, turno1) VALUES (?, 1)',
          );
          // Unique numbers; most are not dates, which does not matter here.
          for (var i = 0; i < count; i++) {
            insert.execute([10000000 + i]);
          }
          insert.close();
          db.execute('COMMIT');
        },
      );
      expectProblem(
        () => read(withDays(maxLrhsoftDays + 1)),
        ImportProblem.tooComplex,
      );
      final ok = read(withDays(maxLrhsoftDays));
      expect(ok.days, isEmpty, reason: 'none of those numbers is a date');
      expect(ok.invalidRows, maxLrhsoftDays);
    });

    test('more than 500 shift types is refused, 500 is not', () {
      Uint8List withTypes(int count) => buildShifter(
        types: [for (var i = 1; i <= count; i++) ShifterType(i, 'T$i')],
      );
      expectProblem(
        () => read(withTypes(maxLrhsoftShiftTypes + 1)),
        ImportProblem.tooComplex,
      );
      expect(read(withTypes(maxLrhsoftShiftTypes)).shiftTypes, hasLength(500));
    });

    test('the file is opened read-only: nothing in it can write', () {
      // A trigger-laden file is just read; and the copy cannot be changed.
      final bytes = buildShifter(
        build: (db) {
          db.execute(shifterTypesTable);
          db.execute(shifterDaysTable);
          db.execute('CREATE TABLE log (x)');
          db.execute(
            'CREATE TRIGGER t AFTER INSERT ON dias '
            'BEGIN INSERT INTO log VALUES (1); END',
          );
          db.execute("INSERT INTO tablaTurnos (_id, texto) VALUES (1, 'M')");
          db.execute('INSERT INTO dias (fecha, turno1) VALUES (20261009, 1)');
        },
      );
      final backup = read(bytes);
      expect(backup.days, hasLength(1));
      expect(leftovers(), isEmpty);
    });

    test('text that is not text does not break the reader', () {
      final backup = read(
        buildShifter(
          build: (db) {
            db.execute(shifterTypesTable);
            db.execute(shifterDaysTable);
            db.execute(
              'INSERT INTO tablaTurnos (_id, texto, abreviatura, color, '
              "horaInicio1, horaFinal1) VALUES (1, x'00FF', 7, 'rojo', 5, NULL)",
            );
            db.execute(
              'INSERT INTO dias (fecha, turno1, turno2, notas) '
              "VALUES (20261009, '1', 1.5, 12)",
            );
          },
        ),
      );
      expect(backup.shiftTypes.single.name, '');
      expect(backup.shiftTypes.single.colorValue, isNull);
      // SQLite turns '1' into 1 (column affinity) and 12 into '12'; 1.5 is
      // not a shift.
      expect(backup.days.single.shiftIds, [1]);
      expect(backup.days.single.note, '12');
      expect(backup.invalidRows, greaterThan(0));
    });
  });

  group('the real sample (when it is there)', () {
    final candidates = [
      Platform.environment['LRHSOFT_SAMPLE'],
      '../build/qa/manual/LRH/LRH_backup.Shifter',
    ];
    final path = candidates
        .whereType<String>()
        .where((c) => File(c).existsSync())
        .firstOrNull;

    test(
      'LRH_backup.Shifter: 43 days, 8 types, one day with two shifts',
      () {
        final backup = readLrhsoftBackup(File(path!).readAsBytesSync());
        expect(backup.invalidRows, 0);
        expect(backup.shiftTypes, hasLength(8));
        expect(backup.days, hasLength(43));
        expect(backup.firstDate, const CivilDate(2026, 10, 9));

        final names = {for (final t in backup.shiftTypes) t.id: t.name};
        expect(names[7], 'Mañana');
        expect(names[8], 'Guardia Médica');

        // 19 November: Mañana and Tarde.
        final two = dayOf(backup, const CivilDate(2026, 11, 19));
        expect(two.shiftIds.map((id) => names[id]), ['Mañana', 'Tarde']);
        expect(backup.days.where((d) => d.shiftIds.length == 2), hasLength(1));

        // The three notes of the sample, decoded.
        final notes = {
          for (final d in backup.days)
            if (d.note != null) d.date: d.note,
        };
        expect(notes, hasLength(3));
        expect(
          notes[const CivilDate(2026, 11, 7)],
          'Revisión médica 9:30, llevar informe',
        );

        // The split shift and the night.
        final split = backup.shiftTypes.firstWhere((t) => t.name == 'Partido');
        expect(split.segment2StartMinute, 16 * 60);
        final night = backup.shiftTypes.firstWhere((t) => t.name == 'Noche');
        expect((night.startMinute, night.endMinute), (23 * 60, 7 * 60));
        final free = backup.shiftTypes.firstWhere((t) => t.name == 'Libre');
        expect(free.hasTimes, isFalse);
      },
      skip: path == null ? 'LRH_backup.Shifter is not on this machine' : false,
    );
  });

  group('looksLikeSqlite', () {
    test('the header decides', () {
      expect(looksLikeSqlite(buildShifter(types: sampleTypes)), isTrue);
      expect(looksLikeSqlite('SQLite'.codeUnits), isFalse);
      expect(looksLikeSqlite(<int>[]), isFalse);
    });
  });

  test('the fixture builder makes a database sqlite3 can open', () {
    final dir = Directory.systemTemp.createTempSync('lrh_check_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'x.Shifter'))
      ..writeAsBytesSync(buildShifter(types: sampleTypes));
    final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
    expect(db.select('SELECT COUNT(*) AS n FROM tablaTurnos').first['n'], 6);
    db.close();
  });
}
