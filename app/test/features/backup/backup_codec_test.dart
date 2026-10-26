import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:cuadrante/features/backup/domain/backup_errors.dart';
import 'package:cuadrante/features/backup/domain/canonical_json.dart';
import 'package:cuadrante/features/backup/domain/schedule_fingerprint.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backup_test_support.dart';
import 'golden_dataset.dart';
import 'v1_format.dart';

void main() {
  const codec = BackupCodec();
  final data = buildGoldenBackupData();
  final at = DateTime.utc(2026, 11, 10, 9, 30, 15);

  Uint8List encode([BackupData? d]) =>
      codec.encode(d ?? data, appVersion: '1.2.3', exportedAt: at);

  /// A well-formed v3 file around a hand-edited `data` object (checksum
  /// recomputed), to reach the checks below the checksum.
  Uint8List fileWithData(Map<String, Object?> dataJson) => gzipEnvelope({
    'format': 'cuadrante',
    'schemaVersion': 3,
    'appVersion': '1.2.3',
    'exportedAt': '2026-11-10T09:30:15Z',
    'data': dataJson,
    'checksum': BackupCodec.checksumOfJson(dataJson),
  });

  Map<String, Object?> dataJson() =>
      jsonDecode(jsonEncode(data.toJson())) as Map<String, Object?>;

  T thrown<T extends BackupException>(void Function() body) {
    try {
      body();
    } on BackupException catch (e) {
      expect(e, isA<T>());
      return e as T;
    }
    fail('expected a ${T.toString()}');
  }

  group('format', () {
    test('writes the documented envelope', () {
      final env = readEnvelope(encode());
      expect(env.keys.toSet(), {
        'format',
        'schemaVersion',
        'appVersion',
        'exportedAt',
        'data',
        'checksum',
      });
      expect(env['format'], 'cuadrante');
      expect(env['schemaVersion'], 3);
      expect(env['appVersion'], '1.2.3');
      expect(env['exportedAt'], '2026-11-10T09:30:15Z');
      expect(env['checksum'], BackupCodec.checksumOf(data));
      expect((env['data']! as Map<String, Object?>).keys.toSet(), {
        'calendars',
        'shiftTypes',
        'patterns',
        'patternRuns',
        'dayEntries',
        'holidays',
        'absenceBalances',
        'settings',
      });
    });

    test('the checksum is the sha256 of the canonical data', () {
      final env = readEnvelope(encode());
      final expected = sha256Hex(canonicalJsonBytes(env['data']));
      expect(env['checksum'], 'sha256:$expected');
    });

    test('is gzip with a platform-independent header', () {
      final bytes = encode();
      expect(bytes.sublist(0, 10), [
        0x1f, 0x8b, 0x08, 0x00, 0, 0, 0, 0, 0x02, 0xff, //
      ]);
    });

    test('decodes what it encodes', () {
      final file = codec.decode(encode());
      expect(file.data, data);
      expect(file.schemaVersion, 3);
      expect(file.appVersion, '1.2.3');
      expect(file.exportedAt, at);
      expect(file.exportedAt.isUtc, isTrue);
      expect(file.checksum, BackupCodec.checksumOf(data));
    });

    test('exportedAt is written in UTC with second precision', () {
      final local = DateTime.parse('2026-11-10T10:30:15.789+01:00');
      final env = readEnvelope(
        codec.encode(data, appVersion: 'x', exportedAt: local),
      );
      expect(env['exportedAt'], '2026-11-10T09:30:15Z');
    });

    test('suggests a dated file name', () {
      expect(
        BackupCodec.suggestedFileName(DateTime.utc(2026, 11, 3, 23)),
        'Cuadrante-2026-11-03.cuadrante',
      );
    });

    test('an empty database makes a valid file', () {
      final empty = BackupData();
      final file = codec.decode(encode(empty));
      expect(file.data, empty);
    });
  });

  group('canonical bytes', () {
    test('the same data gives the same bytes, run after run', () {
      expect(encode(), encode());
      expect(encode(), encode(buildGoldenBackupData()));
    });

    test('decode then encode gives the same bytes again', () {
      final bytes = encode();
      final again = codec.encode(
        codec.decode(bytes).data,
        appVersion: '1.2.3',
        exportedAt: at,
      );
      expect(again, bytes);
    });

    test('does not depend on the order the lists or settings come in', () {
      final shuffled = BackupData(
        calendars: data.calendars.reversed,
        shiftTypes: data.shiftTypes.reversed,
        patterns: data.patterns,
        patternRuns: data.patternRuns.reversed,
        dayEntries: (List.of(data.dayEntries)..shuffle(Random(7))),
        holidays: data.holidays,
        absenceBalances: data.absenceBalances.reversed,
        settings: {
          for (final k in data.settings.keys.toList().reversed)
            k: data.settings[k]!,
        },
      );
      expect(shuffled, data);
      expect(encode(shuffled), encode());
    });

    test(
      'the pattern order is data: a different order is a different file',
      () {
        final swapped = BackupData(
          shiftTypes: data.shiftTypes,
          patterns: data.patterns.reversed,
          patternRuns: data.patternRuns,
          dayEntries: data.dayEntries,
          holidays: data.holidays,
          absenceBalances: data.absenceBalances,
          settings: data.settings,
        );
        expect(swapped, isNot(data));
        expect(
          codec.decode(encode(swapped)).data.patterns.first.id,
          'p-noches',
        );
      },
    );

    test('only exportedAt and appVersion change when the clock does', () {
      final a = readEnvelope(encode());
      final b = readEnvelope(
        codec.encode(
          data,
          appVersion: '1.2.3',
          exportedAt: at.add(const Duration(days: 1)),
        ),
      );
      expect(b['data'], a['data']);
      expect(b['checksum'], a['checksum']);
      expect(b['exportedAt'], isNot(a['exportedAt']));
    });

    test('the uncompressed form is canonical JSON', () {
      final raw = codec.encodeJsonBytes(
        data,
        appVersion: '1.2.3',
        exportedAt: at,
      );
      final text = utf8.decode(raw);
      expect(canonicalJson(jsonDecode(text)), text);
      expect(raw, Uint8List.fromList(gzip.decode(encode())));
    });
  });

  group('NotACuadranteFile', () {
    test('an empty file', () {
      thrown<NotACuadranteFile>(() => codec.decode(Uint8List(0)));
      thrown<NotACuadranteFile>(() => codec.decode(Uint8List.fromList([0x1f])));
    });

    test('random bytes', () {
      final random = Random(42);
      for (var i = 0; i < 20; i++) {
        final bytes = Uint8List.fromList([
          // Never the gzip magic.
          0x00,
          for (var j = 0; j < 200; j++) random.nextInt(256),
        ]);
        thrown<NotACuadranteFile>(() => codec.decode(bytes));
      }
    });

    test('plain text and plain JSON (not compressed)', () {
      thrown<NotACuadranteFile>(
        () => codec.decode(Uint8List.fromList(utf8.encode('hola'))),
      );
      thrown<NotACuadranteFile>(
        () => codec.decode(
          Uint8List.fromList(utf8.encode('{"format":"cuadrante"}')),
        ),
      );
    });

    test('a valid gzip of something else', () {
      Uint8List gz(String text) =>
          Uint8List.fromList(gzip.encode(utf8.encode(text)));
      thrown<NotACuadranteFile>(() => codec.decode(gz('just some text')));
      thrown<NotACuadranteFile>(() => codec.decode(gz('[1,2,3]')));
      thrown<NotACuadranteFile>(() => codec.decode(gz('{"format":"other"}')));
      thrown<NotACuadranteFile>(() => codec.decode(gz('{"schemaVersion":1}')));
      thrown<NotACuadranteFile>(() => codec.decode(gz('"cuadrante"')));
    });
  });

  group('NewerFormatVersion (R6)', () {
    Uint8List future(int version, {Object? data}) => gzipEnvelope({
      'format': 'cuadrante',
      'schemaVersion': version,
      'appVersion': '9.9.9',
      'exportedAt': '2030-01-01T00:00:00Z',
      // A future layout and checksum scheme: must not be looked at.
      'data': data ?? {'calendars': <Object?>[]},
      'checksum': 'blake3:nothing',
    });

    test('is rejected with the versions involved', () {
      final e = thrown<NewerFormatVersion>(() => codec.decode(future(4)));
      expect(e.found, 4);
      expect(e.supported, BackupCodec.supportedSchemaVersion);
      expect(e.message, contains('v4'));
    });

    test('is rejected before the content is checked', () {
      thrown<NewerFormatVersion>(() => codec.decode(future(7, data: 'junk')));
      thrown<NewerFormatVersion>(() => codec.decode(future(1000)));
    });
  });

  group('CorruptBackup (R7)', () {
    test('a truncated file, wherever it is cut', () {
      final bytes = encode();
      final cuts = {
        2,
        3,
        9,
        10,
        11,
        18,
        bytes.length ~/ 4,
        bytes.length ~/ 2,
        bytes.length - 40,
        bytes.length - 9,
        bytes.length - 8,
        bytes.length - 5,
        bytes.length - 1,
      };
      for (final cut in cuts) {
        final e = thrown<BackupException>(
          () => codec.decode(Uint8List.sublistView(bytes, 0, cut)),
        );
        // Still starts like a gzip file, so it is damaged, not foreign.
        expect(e, isA<CorruptBackup>(), reason: 'cut at $cut');
      }
    });

    test('a flipped bit, anywhere after the header', () {
      final bytes = encode();
      for (var i = 10; i < bytes.length; i += 3) {
        final damaged = Uint8List.fromList(bytes)..[i] ^= 0x04;
        thrown<CorruptBackup>(() => codec.decode(damaged));
      }
    });

    test('a flipped bit in the last bytes of the trailer', () {
      final bytes = encode();
      for (var i = bytes.length - 8; i < bytes.length; i++) {
        final damaged = Uint8List.fromList(bytes)..[i] ^= 0x01;
        thrown<CorruptBackup>(() => codec.decode(damaged));
      }
    });

    test('bytes appended after the end', () {
      final longer = Uint8List.fromList([...encode(), 1, 2, 3, 4]);
      thrown<CorruptBackup>(() => codec.decode(longer));
    });

    test('data edited without fixing the checksum', () {
      final env = readEnvelope(encode());
      final edited = jsonDecode(jsonEncode(env)) as Map<String, Object?>;
      final entries =
          (edited['data']! as Map<String, Object?>)['dayEntries']!
              as List<Object?>;
      (entries.first! as Map<String, Object?>)['note'] = 'tampered';
      final e = thrown<CorruptBackup>(() => codec.decode(gzipEnvelope(edited)));
      expect(e.message, contains('Checksum'));
    });

    test('a checksum that is missing or from another algorithm', () {
      final env = readEnvelope(encode());
      thrown<CorruptBackup>(
        () => codec.decode(gzipEnvelope({...env}..remove('checksum'))),
      );
      thrown<CorruptBackup>(
        () => codec.decode(gzipEnvelope({...env, 'checksum': 'md5:abc'})),
      );
      thrown<CorruptBackup>(
        () => codec.decode(gzipEnvelope({...env, 'checksum': 42})),
      );
    });

    test('a schemaVersion that is not a version', () {
      final env = readEnvelope(encode());
      for (final bad in <Object?>[0, -1, '1', 1.5, null]) {
        thrown<CorruptBackup>(
          () => codec.decode(gzipEnvelope({...env, 'schemaVersion': bad})),
        );
      }
    });

    test('content that is too big once inflated', () {
      final small = const BackupCodec(maxDecodedBytes: 1000);
      thrown<CorruptBackup>(() => small.decode(encode()));
      // The real limit is far above any real backup.
      expect(encode().length, lessThan(BackupCodec.maxFileBytes));
    });

    test('the writer enforces the same decoded limit as the reader', () {
      const small = BackupCodec(maxDecodedBytes: 1000);
      thrown<CorruptBackup>(
        () => small.encode(data, appVersion: 'test', exportedAt: at),
      );
    });

    test(
      'a bomb that inflates past 32 MiB is stopped by the default limit',
      () {
        expect(BackupCodec.defaultMaxDecodedBytes, 32 * 1024 * 1024);
        expect(BackupCodec.maxFileBytes, 8 * 1024 * 1024);
        // With the ratio check out of the way (a file big enough that 100x its
        // size is above the cap), the absolute cap still stops it.
        final noisy = Uint8List(200 * 1024);
        for (var i = 0; i < noisy.length; i++) {
          noisy[i] = (i * 2654435761) >> 8 & 0xff;
        }
        // Noise followed by more than the absolute limit of zeros.
        final bomb = Uint8List.fromList(
          GZipCodec(level: 9)
              .encode([...noisy, ...Uint8List(33 * 1024 * 1024)]),
        );
        expect(bomb.length, lessThan(BackupCodec.maxFileBytes));
        final watch = Stopwatch()..start();
        final e = thrown<CorruptBackup>(() => codec.decode(bomb));
        expect(e.message, anyOf(contains('too large'), contains('ratio')));
        expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
      },
    );

    test('a plain run of zeros is refused by the inflate ratio', () {
      // 20 MB of zeros squeeze into a few KB of gzip.
      final bomb = Uint8List.fromList(
        GZipCodec(level: 9).encode(Uint8List(20 * 1024 * 1024)),
      );
      final e = thrown<CorruptBackup>(() => codec.decode(bomb));
      expect(e.message, contains('ratio'));
    });

    test('a file over the input limit is refused unread', () {
      final big = Uint8List(BackupCodec.maxFileBytes + 1)
        ..[0] = 0x1f
        ..[1] = 0x8b;
      final e = thrown<CorruptBackup>(() => codec.decode(big));
      expect(e.message, contains('too large'));
    });

    test('wrong types and values inside the data', () {
      Map<String, Object?> edit(void Function(Map<String, Object?>) change) {
        final d = dataJson();
        change(d);
        return d;
      }

      Map<String, Object?> first(Map<String, Object?> d, String key) =>
          (d[key]! as List<Object?>).first! as Map<String, Object?>;

      final cases = <String, Map<String, Object?>>{
        'missing list': edit((d) => d.remove('patterns')),
        'list is a string': edit((d) => d['dayEntries'] = 'x'),
        'settings not an object': edit((d) => d['settings'] = <Object?>[]),
        'setting value not a string': edit(
          (d) => (d['settings']! as Map<String, Object?>)['alarms'] = 5,
        ),
        'unknown category': edit(
          (d) => first(d, 'shiftTypes')['category'] = 'holiday',
        ),
        'code is a number': edit((d) => first(d, 'shiftTypes')['code'] = 7),
        'bad date': edit((d) => first(d, 'dayEntries')['date'] = '2026-02-30'),
        'shift ids not strings': edit(
          (d) => first(d, 'dayEntries')['shiftTypeIds'] = [1, 2],
        ),
        'steps not a matrix': edit((d) => first(d, 'patterns')['steps'] = [1]),
        'fractional minute': edit(
          (d) => first(d, 'shiftTypes')['sortOrder'] = 1.5,
        ),
      };
      for (final MapEntry(key: name, value: bad) in cases.entries) {
        expect(
          () => codec.decode(fileWithData(bad)),
          throwsA(isA<CorruptBackup>()),
          reason: name,
        );
      }
    });
  });

  group('referential integrity', () {
    Map<String, Object?> firstOf(Map<String, Object?> d, String key) =>
        (d[key]! as List<Object?>).first! as Map<String, Object?>;

    test('a run that points at a missing pattern', () {
      final d = dataJson();
      firstOf(d, 'patternRuns')['patternId'] = 'p-gone';
      final e = thrown<CorruptBackup>(() => codec.decode(fileWithData(d)));
      expect(e.message, contains('missing pattern'));
    });

    test('duplicate ids, seq and dates', () {
      final cases = <String, void Function(Map<String, Object?>)>{
        'shift type id': (d) => (d['shiftTypes']! as List<Object?>).add(
          Map<String, Object?>.of(firstOf(d, 'shiftTypes')),
        ),
        'pattern id': (d) => (d['patterns']! as List<Object?>).add(
          Map<String, Object?>.of(firstOf(d, 'patterns')),
        ),
        'run seq': (d) => (d['patternRuns']! as List<Object?>).add({
          ...firstOf(d, 'patternRuns'),
          'id': 'run-dup',
        }),
        'day': (d) => (d['dayEntries']! as List<Object?>).add(
          Map<String, Object?>.of(firstOf(d, 'dayEntries')),
        ),
        'balance': (d) => (d['absenceBalances']! as List<Object?>).add(
          Map<String, Object?>.of(firstOf(d, 'absenceBalances')),
        ),
      };
      for (final MapEntry(key: name, value: change) in cases.entries) {
        final d = dataJson();
        change(d);
        expect(
          () => codec.decode(fileWithData(d)),
          throwsA(isA<CorruptBackup>()),
          reason: name,
        );
      }
    });

    test('what the database would refuse', () {
      final cases = <String, void Function(Map<String, Object?>)>{
        'run ends before it starts': (d) {
          final run = firstOf(d, 'patternRuns');
          run['endDate'] = '2025-01-01';
        },
        'only a start minute': (d) {
          final t = firstOf(d, 'shiftTypes');
          t['startMinute'] = 60;
          t['endMinute'] = null;
        },
        'minute out of range': (d) {
          final t = firstOf(d, 'shiftTypes');
          t['startMinute'] = 1440;
          t['endMinute'] = 10;
        },
        'pattern without steps': (d) => firstOf(d, 'patterns')['steps'] = [],
        'unknown holiday scope': (d) =>
            firstOf(d, 'holidays')['scope'] = 'galactic',
      };
      for (final MapEntry(key: name, value: change) in cases.entries) {
        final d = dataJson();
        change(d);
        expect(
          () => codec.decode(fileWithData(d)),
          throwsA(isA<CorruptBackup>()),
          reason: name,
        );
      }
    });

    test('what the engine would refuse', () {
      final cases = <String, void Function(Map<String, Object?>)>{
        'code too long': (d) => firstOf(d, 'shiftTypes')['code'] = 'ABCD',
        'empty code': (d) => firstOf(d, 'shiftTypes')['code'] = '',
        'empty shift type id': (d) => firstOf(d, 'shiftTypes')['id'] = '',
        'empty shift type name': (d) => firstOf(d, 'shiftTypes')['name'] = '',
        'negative color': (d) => firstOf(d, 'shiftTypes')['colorValue'] = -1,
        'color beyond 32 bits': (d) =>
            firstOf(d, 'shiftTypes')['colorValue'] = 0x100000000,
        'empty pattern id': (d) => firstOf(d, 'patterns')['id'] = '',
        'empty pattern name': (d) => firstOf(d, 'patterns')['name'] = '',
        'empty run id': (d) => firstOf(d, 'patternRuns')['id'] = '',
        'blank holiday name': (d) => firstOf(d, 'holidays')['name'] = '  ',
      };
      for (final MapEntry(key: name, value: change) in cases.entries) {
        final d = dataJson();
        change(d);
        expect(
          () => codec.decode(fileWithData(d)),
          throwsA(isA<CorruptBackup>()),
          reason: name,
        );
      }
    });

    test('the limits of the engine are accepted', () {
      final d = dataJson();
      final type = firstOf(d, 'shiftTypes');
      type['code'] = 'ABC';
      type['colorValue'] = 0xFFFFFFFF;
      firstOf(d, 'patterns')['name'] = 'x';
      type['startMinute'] = 0;
      type['endMinute'] = 1439;
      expect(() => codec.decode(fileWithData(d)), returnsNormally);
      type['code'] = 'A';
      type['colorValue'] = 0;
      expect(() => codec.decode(fileWithData(d)), returnsNormally);
    });

    test('ids the engine skips are not an error', () {
      final d = dataJson();
      firstOf(d, 'dayEntries')['shiftTypeIds'] = ['gone-type'];
      ((firstOf(d, 'patterns')['steps']! as List<Object?>).first!
              as List<Object?>)
          .add('another-gone-type');
      final file = codec.decode(fileWithData(d));
      expect(file.data.dayEntries.first.shiftTypeIds, ['gone-type']);
      // ...and the engine just leaves them out.
      final schedule = file.data.toSchedule();
      expect(schedule.resolve(file.data.dayEntries.first.date).shifts, isEmpty);
    });
  });

  group('forward compatibility inside v2', () {
    test('unknown fields are ignored but still covered by the checksum', () {
      final d = dataJson();
      d['someNewTable'] = [
        {'a': 1},
      ];
      (d['shiftTypes']! as List<Object?>)
              .cast<Map<String, Object?>>()
              .first['icon'] =
          'bolt';
      final extended = gzipEnvelope({
        'format': 'cuadrante',
        'schemaVersion': 2,
        'appVersion': '1.9.0',
        'exportedAt': '2026-11-10T09:30:15Z',
        'extraEnvelopeField': true,
        'data': d,
        'checksum': BackupCodec.checksumOfJson(d),
      });
      final file = codec.decode(extended);
      expect(file.data, data);

      // Same file with an unknown field edited afterwards: caught.
      final tampered = gzipEnvelope({
        'format': 'cuadrante',
        'schemaVersion': 2,
        'appVersion': '1.9.0',
        'exportedAt': '2026-11-10T09:30:15Z',
        'data': {
          ...d,
          'someNewTable': [
            {'a': 2},
          ],
        },
        'checksum': BackupCodec.checksumOfJson(d),
      });
      thrown<CorruptBackup>(() => codec.decode(tampered));
    });

    test('numbers another writer prints as 3.0 are still integers', () {
      final d = dataJson();
      (d['shiftTypes']! as List<Object?>)
              .cast<Map<String, Object?>>()
              .first['sortOrder'] =
          3.0;
      final file = codec.decode(fileWithData(d));
      expect(file.data.shiftTypes.map((t) => t.sortOrder), contains(3));
    });
  });

  group('version 1 files (releases 0.1 and 0.2)', () {
    // The golden dataset is a version 1 dataset: `main` stamped with the
    // time of its export (what reading version 1 gives).
    final exportedText = '2026-11-10T09:00:00Z';

    test('read into the version 2 model: everything in main', () {
      final file = codec.decode(v1File(data, exportedAt: exportedText));
      expect(file.schemaVersion, 1);
      expect(file.data, data);
      expect(file.data.calendars.map((c) => c.id), ['main']);
      expect(file.data.calendars.single.name, 'Mi cuadrante');
      expect(
        file.data.calendars.single.createdAt,
        goldenExportedAt.millisecondsSinceEpoch,
      );
      expect(file.data.patternRuns.map((r) => r.calendarId).toSet(), {'main'});
      expect(file.data.dayEntries.map((e) => e.calendarId).toSet(), {'main'});
      expect(file.data.shiftTypes.map((t) => t.hourlyRateCents).toSet(), {
        null,
      });
      expect(file.checksum, v1Checksum(data));
    });

    test('the same days as version 1 showed', () {
      final file = codec.decode(v1File(data, exportedAt: exportedText));
      final from = const CivilDate(2026, 1, 1);
      final to = const CivilDate(2027, 12, 31);
      expect(
        resolvedDayLines(file.data.toSchedule(), from: from, to: to),
        resolvedDayLines(data.toSchedule(), from: from, to: to),
      );
    });

    test('a version 1 file is exported again as version 3', () {
      final file = codec.decode(v1File(data, exportedAt: exportedText));
      final again = codec.decode(
        codec.encode(file.data, appVersion: '0.3.0', exportedAt: at),
      );
      expect(again.schemaVersion, 3);
      expect(again.data, file.data);
    });

    test('the checksum is checked on the file as version 1 wrote it', () {
      final bytes = v1File(data, exportedAt: exportedText);
      final env = readEnvelope(bytes);
      // Version 2 fields in a version 1 file are not part of version 1: the
      // checksum no longer matches the edited data.
      final edited = (env['data']! as Map<String, Object?>)
        ..['calendars'] = <Object?>[];
      thrown<CorruptBackup>(
        () => codec.decode(gzipEnvelope({...env, 'data': edited})),
      );
    });

    test('version 2 fields in a version 1 file are ignored', () {
      final d =
          jsonDecode(jsonEncode(v1DataJson(data))) as Map<String, Object?>;
      d['calendars'] = [
        {
          'id': 'sneaky',
          'name': 'x',
          'colorValue': 1,
          'sortOrder': 0,
          'archived': false,
          'createdAt': 0,
          'updatedAt': 0,
        },
      ];
      (d['patternRuns']! as List)
              .cast<Map<String, Object?>>()
              .first['calendarId'] =
          'sneaky';
      (d['shiftTypes']! as List)
              .cast<Map<String, Object?>>()
              .first['hourlyRateCents'] =
          999;
      final file = codec.decode(
        gzipEnvelope({
          'format': 'cuadrante',
          'schemaVersion': 1,
          'appVersion': '0.2.0',
          'exportedAt': exportedText,
          'data': d,
          'checksum': BackupCodec.checksumOfJson(d),
        }),
      );
      expect(file.data, data);
    });

    test('a damaged version 1 file is still corrupt', () {
      final d =
          jsonDecode(jsonEncode(v1DataJson(data))) as Map<String, Object?>;
      (d['patternRuns']! as List)
              .cast<Map<String, Object?>>()
              .first['patternId'] =
          'no-such-pattern';
      thrown<CorruptBackup>(
        () => codec.decode(
          gzipEnvelope({
            'format': 'cuadrante',
            'schemaVersion': 1,
            'appVersion': '0.2.0',
            'exportedAt': exportedText,
            'data': d,
            'checksum': BackupCodec.checksumOfJson(d),
          }),
        ),
      );
    });
  });

  group('calendars (version 2)', () {
    Map<String, Object?> firstRun(Map<String, Object?> d) =>
        (d['patternRuns']! as List).cast<Map<String, Object?>>().first;

    test('a run without calendarId is corrupt', () {
      final d = dataJson();
      firstRun(d).remove('calendarId');
      thrown<CorruptBackup>(() => codec.decode(fileWithData(d)));
    });

    test('a run or a day in a calendar that does not exist is corrupt', () {
      final run = dataJson();
      firstRun(run)['calendarId'] = 'ghost';
      thrown<CorruptBackup>(() => codec.decode(fileWithData(run)));

      final day = dataJson();
      (day['dayEntries']! as List)
              .cast<Map<String, Object?>>()
              .first['calendarId'] =
          'ghost';
      thrown<CorruptBackup>(() => codec.decode(fileWithData(day)));
    });

    test(
      'a file without calendars, or with all of them archived, is corrupt',
      () {
        final none = dataJson();
        none['calendars'] = <Object?>[];
        thrown<CorruptBackup>(() => codec.decode(fileWithData(none)));

        final archived = dataJson();
        (archived['calendars']! as List)
                .cast<Map<String, Object?>>()
                .single['archived'] =
            true;
        thrown<CorruptBackup>(() => codec.decode(fileWithData(archived)));
      },
    );

    test('duplicate calendar ids, blank names and bad colours are corrupt', () {
      final dup = dataJson();
      final calendars = (dup['calendars']! as List)
          .cast<Map<String, Object?>>();
      calendars.add({...calendars.single});
      thrown<CorruptBackup>(() => codec.decode(fileWithData(dup)));

      final blank = dataJson();
      (blank['calendars']! as List)
              .cast<Map<String, Object?>>()
              .single['name'] =
          '  ';
      thrown<CorruptBackup>(() => codec.decode(fileWithData(blank)));

      final color = dataJson();
      (color['calendars']! as List)
              .cast<Map<String, Object?>>()
              .single['colorValue'] =
          -1;
      thrown<CorruptBackup>(() => codec.decode(fileWithData(color)));
    });

    test('the same date in two calendars is fine, twice in one is not', () {
      final twoCalendars = BackupData(
        calendars: [
          ...data.calendars,
          const BackupCalendar(
            id: 'other',
            name: 'Otro',
            colorValue: 0xFF123456,
            sortOrder: 1,
            createdAt: 0,
            updatedAt: 0,
          ),
        ],
        shiftTypes: data.shiftTypes,
        patterns: data.patterns,
        dayEntries: [
          BackupDayEntry(
            date: const CivilDate(2026, 5, 1),
            shiftTypeIds: const ['morning'],
            updatedAt: 1,
          ),
          BackupDayEntry(
            calendarId: 'other',
            date: const CivilDate(2026, 5, 1),
            shiftTypeIds: const ['night'],
            updatedAt: 2,
          ),
        ],
      );
      expect(codec.decode(encode(twoCalendars)).data, twoCalendars);

      final twice = BackupData(
        dayEntries: [
          BackupDayEntry(
            date: const CivilDate(2026, 5, 1),
            shiftTypeIds: const ['morning'],
            updatedAt: 1,
          ),
          BackupDayEntry(
            date: const CivilDate(2026, 5, 1),
            note: 'otra',
            updatedAt: 2,
          ),
        ],
      );
      expect(() => twice.validate(), throwsA(isA<CorruptBackup>()));
    });

    test('hourlyRateCents travels and is optional', () {
      final rated = BackupData(
        shiftTypes: [
          BackupShiftType(
            id: 'a',
            code: 'A',
            name: 'A',
            colorValue: 1,
            category: ShiftCategory.work,
            hourlyRateCents: 1275,
            sortOrder: 0,
            createdAt: 1,
            updatedAt: 1,
          ),
          BackupShiftType(
            id: 'b',
            code: 'B',
            name: 'B',
            colorValue: 1,
            category: ShiftCategory.work,
            sortOrder: 1,
            createdAt: 1,
            updatedAt: 1,
          ),
        ],
      );
      final back = codec.decode(encode(rated)).data;
      expect(back.shiftTypes.map((t) => t.hourlyRateCents), [1275, null]);
      expect(back.shiftTypes.first.toShiftType().hourlyRateCents, 1275);

      // A file that leaves the field out reads as "no rate".
      final d = jsonDecode(jsonEncode(rated.toJson())) as Map<String, Object?>;
      for (final t in (d['shiftTypes']! as List).cast<Map<String, Object?>>()) {
        t.remove('hourlyRateCents');
      }
      expect(
        codec
            .decode(fileWithData(d))
            .data
            .shiftTypes
            .map((t) => t.hourlyRateCents),
        [null, null],
      );
    });

    test('the writer is version 3 and a version 4 file is "newer"', () {
      expect(BackupCodec.supportedSchemaVersion, 3);
    });
  });

  group('model', () {
    test('toSchedule gives what the engine would show', () {
      final schedule = data.toSchedule();
      // Rotation 1 starts on step 0 (morning) on 2026-01-01...
      final first = schedule.resolve(const CivilDate(2026, 1, 2));
      expect(first.source, DaySource.pattern);
      expect(first.shiftIds, ['morning']);
      // ...and an exception of 2026-01-01 (a night) wins over it.
      final override = schedule.resolve(const CivilDate(2026, 1, 1));
      expect(override.source, DaySource.override);
      expect(override.shiftIds, ['night']);
    });
  });
}
