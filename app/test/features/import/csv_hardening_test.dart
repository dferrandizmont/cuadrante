import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/features/import/data/import_file_picker.dart';
import 'package:cuadrante/features/import/domain/csv_parser.dart';
import 'package:cuadrante/features/import/domain/import_files.dart';
import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('limits of the table', () {
    test('rows wider than the cap are cut to the first columns', () {
      final row = [for (var i = 0; i < 400; i++) 'c$i'].join(',');
      final table = parseCsv('$row\n$row\n');
      expect(table.columnCount, maxCsvColumns);
      expect(table.rows.first.last, 'c${maxCsvColumns - 1}');
    });

    test('every cell is cut to 120 characters', () {
      final long = 'x' * 5000;
      final table = parseCsv('09/11/2026,"$long",$long\n10/11/2026,M,N\n');
      expect(table.rows.first[1].length, maxImportTitleLength);
      expect(table.rows.first[2].length, maxImportTitleLength);
      expect(table.rows[1][1], 'M');
    });

    test('a cell is not cut inside a surrogate pair', () {
      final text = '${'a' * (maxImportTitleLength - 1)}😀😀';
      final table = parseCsv('09/11/2026,$text\n10/11/2026,M\n');
      final cell = table.rows.first[1];
      expect(cell.length, lessThanOrEqualTo(maxImportTitleLength));
      expect(cell.codeUnits.last, isNot(inInclusiveRange(0xD800, 0xDBFF)));
    });

    test('guessing columns on a capped table is bounded', () {
      final head = [for (var i = 0; i < 300; i++) 'col$i'].join(';');
      final rows = [
        for (var d = 1; d <= 20; d++)
          '${d.toString().padLeft(2, '0')}/11/2026;M;${'x;' * 300}',
      ];
      final table = parseCsv('$head\n${rows.join('\n')}\n');
      expect(table.columnCount, maxCsvColumns);
      final columns = guessColumns(table)!;
      expect(columns.date, 0);
      expect(columns.title, 1);
    });
  });

  group('start column', () {
    test('a blank start cell uses the time written in the date cell', () {
      final table = parseCsv(
        'Fecha;Turno;Inicio;Fin\n'
        '09/11/2026 06:00;Mañana;;\n'
        '10/11/2026 14:00;Tarde;15:00;\n'
        '11/11/2026;Libre;;\n',
      );
      final columns = guessColumns(table)!;
      expect(columns.start, 2);
      final reading = readCsv(table, columns);
      final byDay = {for (final o in reading.occurrences) o.date.day: o};
      // Blank start: the 06:00 of the date cell.
      expect(byDay[9]!.startMinute, 6 * 60);
      expect(byDay[9]!.allDay, isFalse);
      // A start cell wins over the date cell.
      expect(byDay[10]!.startMinute, 15 * 60);
      // Nothing anywhere: all-day.
      expect(byDay[11]!.allDay, isTrue);
    });
  });

  group('one role per column', () {
    const columns = CsvColumns(date: 0, title: 1, start: 2, end: 3);

    test('an optional role that is taken loses it', () {
      final next = columns.assign(CsvRole.end, 2);
      expect(next.end, 2);
      expect(next.start, isNull);
    });

    test('a required role swaps with the one that had the column', () {
      final next = columns.assign(CsvRole.date, 1);
      expect(next.date, 1);
      expect(next.title, 0);
    });

    test('an optional role takes the column of a required one: a swap', () {
      final next = columns.assign(CsvRole.start, 0);
      expect(next.start, 0);
      expect(next.date, 2);
    });

    test('with no column to hand over, nothing changes', () {
      const bare = CsvColumns(date: 0, title: 1);
      expect(bare.assign(CsvRole.start, 0), same(bare));
    });

    test('a free column is simply assigned; none clears', () {
      expect(columns.assign(CsvRole.start, 5).start, 5);
      final cleared = columns.assign(CsvRole.start, null);
      expect(cleared.start, isNull);
      expect(cleared.end, isNull);
    });
  });

  group('Windows-1252', () {
    test('invalid UTF-8 is read as Windows-1252, not Latin-1', () {
      // «Mañana» «€» and curly quotes, as Excel writes them.
      final bytes = Uint8List.fromList([
        0x4D, 0x61, 0xF1, 0x61, 0x6E, 0x61, // Mañana
        0x20, 0x80, // euro
        0x20, 0x93, 0x78, 0x94, // “x”
        0x20, 0x96, // en dash
      ]);
      expect(decodeImportBytes(bytes), 'Mañana € “x” –');
    });

    test('bytes Windows-1252 leaves undefined stay as they are', () {
      final bytes = Uint8List.fromList([0x41, 0x81, 0xE9]);
      expect(decodeImportBytes(bytes).codeUnits, [0x41, 0x81, 0xE9]);
    });
  });

  group('copy left by the picker', () {
    late Directory root;
    late Directory cache;
    late Directory elsewhere;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('picker_test');
      cache = await Directory(p.join(root.path, 'cache')).create();
      elsewhere = await Directory(p.join(root.path, 'docs')).create();
    });

    tearDown(() async {
      await root.delete(recursive: true);
    });

    Future<File> write(Directory dir, String name, List<int> bytes) async {
      final file = File(p.join(dir.path, name));
      await file.writeAsBytes(bytes);
      return file;
    }

    test('a file read from the cache is deleted afterwards', () async {
      final file = await write(cache, 'turnos.ics', [65, 66]);
      final picked = await readPickedFile(
        XFile(file.path),
        cacheDir: () async => cache,
      );
      expect(picked.bytes, [65, 66]);
      expect(file.existsSync(), isFalse);
    });

    test('a file that is too big is declined and its copy deleted', () async {
      final file = await write(cache, 'grande.ics', [
        ...List.filled(maxImportFileBytes + 1, 65),
      ]);
      final picked = await readPickedFile(
        XFile(file.path),
        cacheDir: () async => cache,
      );
      expect(picked.problem, ImportProblem.fileTooLarge);
      expect(file.existsSync(), isFalse);
    });

    test('a file outside the cache is never deleted', () async {
      final file = await write(elsewhere, 'mio.ics', [65, 66]);
      final picked = await readPickedFile(
        XFile(file.path),
        cacheDir: () async => cache,
      );
      expect(picked.bytes, [65, 66]);
      expect(file.existsSync(), isTrue);
    });

    test('a path that climbs out of the cache is not deleted', () async {
      final file = await write(elsewhere, 'mio.ics', [65]);
      final sneaky = p.join(cache.path, '..', 'docs', 'mio.ics');
      await deleteIfCached(sneaky, () async => cache);
      expect(file.existsSync(), isTrue);
      // The cache folder itself is not a file inside it either.
      await deleteIfCached(cache.path, () async => cache);
      expect(cache.existsSync(), isTrue);
    });

    test('a sibling folder with the same prefix is not the cache', () async {
      final sibling = await Directory(p.join(root.path, 'cache2')).create();
      final file = await write(sibling, 'x.ics', [65]);
      await deleteIfCached(file.path, () async => cache);
      expect(file.existsSync(), isTrue);
    });

    test('a cache folder that cannot be found deletes nothing', () async {
      final file = await write(cache, 'x.ics', [65]);
      await deleteIfCached(file.path, () async => throw StateError('no'));
      expect(file.existsSync(), isTrue);
    });
  });
}
