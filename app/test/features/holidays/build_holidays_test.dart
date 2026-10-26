import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cuadrante/features/holidays/data/holiday_bundle_format.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/build_holidays.dart';
import '../../support/test_storage.dart' show makeTempDir;
import 'bundle_support.dart';

Map<String, Object?> _holiday(String date, String es, {String? origin}) => {
  'date': date,
  'label': {'ca': '$es ca', 'es': es, 'en': '$es en'},
  'origin': ?origin,
};

Map<String, Object?> _source(String name, String retrieved) => {
  'url': 'https://example.org/$name',
  'ref': 'Ref $name',
  'published': '2026-01-01',
  'retrieved': retrieved,
};

/// A small Mochila `src/calendars` tree: a verified year, one region, a
/// pending file, an unverified one and a Murcia school file.
Directory _fixture() {
  final dir = makeTempDir('calendars');
  void write(String path, Object json) {
    final file = File('${dir.path}/$path')..createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(json));
  }

  write('manifest.json', [
    {
      'file': 'national/2026.json',
      'verified': true,
      'status': 'complete',
      'source': _source('national', '2026-10-01'),
    },
    {
      'file': 'regional/ES-CT/2026.json',
      'verified': true,
      'status': 'complete',
      'source': _source('ct', '2026-10-05'),
    },
    {
      'file': 'regional/ES-MD/2026.json',
      'verified': false,
      'status': 'partial',
      'source': null,
    },
    {
      'file': 'municipal/ES-CT/2026.json',
      'verified': true,
      'status': 'complete',
      'source': _source('ct-local', '2026-10-07'),
    },
    {
      'file': 'municipal/ES-CT/2027.json',
      'verified': false,
      'status': 'pending',
      'source': null,
    },
    {
      'file': 'ES-MC/municipal-non-teaching-2026-27.json',
      'verified': true,
      'status': 'complete',
      'source': _source('mc', '2026-10-03'),
    },
  ]);
  write('national/2026.json', {
    'holidays': [
      _holiday('2026-12-25', 'Natividad del Señor'),
      _holiday('2026-01-01', 'Año Nuevo'),
    ],
  });
  write('regional/ES-CT/2026.json', {
    'holidays': [
      _holiday('2026-12-26', 'San Esteban', origin: 'regional'),
      _holiday('2026-01-06', 'Epifanía del Señor', origin: 'national-optional'),
    ],
  });
  write('municipal/ES-CT/2026.json', {
    '08019': {
      'name': 'Barcelona',
      'days': [
        {'date': '2026-09-24', 'label': 'Festa local'},
        {'date': '2026-05-25', 'label': 'Festa local'},
      ],
    },
    '08002': {
      'name': 'Aguilar',
      'days': [
        {'date': '2026-05-04', 'label': 'Fiesta local (El Pueblo)'},
      ],
    },
  });
  write('ES-MC/municipal-non-teaching-2026-27.json', {
    'municipalities': {
      '30001': {
        'name': 'Abanilla',
        'local_holidays': ['2026-09-14', '2027-05-03'],
        'other_non_teaching': ['2027-03-30'],
      },
    },
  });
  final ine = File('${dir.path}/ine.json')
    ..writeAsStringSync(jsonEncode({'08019': 'Barcelona', '99999': 'Nowhere'}));
  expect(ine.existsSync(), isTrue);
  return dir;
}

HolidayBundleBuild _build(Directory dir) => buildHolidayBundle(
  calendarsDir: dir,
  ineMunicipalities: File('${dir.path}/ine.json'),
);

void main() {
  group('tool/build_holidays.dart', () {
    test('only verified and complete files go in; the rest is listed', () {
      final build = _build(_fixture());

      expect(build.files.keys, [
        '2026/es.json',
        '2026/municipal/ES-CT.json',
        '2026/municipal/ES-MC.json',
        'manifest.json',
        'municipalities.json',
      ]);
      expect(
        build.skipped,
        containsAll([
          contains('regional/ES-MD/2026.json'),
          contains('municipal/ES-CT/2027.json: pending'),
        ]),
      );
      // 2027 has no national file: the Murcia 2027 day is left out, said so.
      expect(build.notes, contains(contains('ES-MC 2027')));
      expect(build.notes, contains(contains('99999')));
    });

    test('rows are sorted, in Spanish, and read back with the app parser', () {
      final build = _build(_fixture());
      Map<String, Object?> json(String path) =>
          jsonDecode(utf8.decode(build.files[path]!)) as Map<String, Object?>;

      final es = parseEsFile(json('2026/es.json'));
      expect(
        [
          for (final e in es)
            '${e.date} ${e.scope.name} ${e.regionCode} ${e.name}',
        ],
        [
          '2026-01-01 national null Año Nuevo',
          '2026-12-25 national null Natividad del Señor',
          '2026-01-06 national ES-CT Epifanía del Señor',
          '2026-12-26 regional ES-CT San Esteban',
        ],
      );

      final local = parseMunicipalFile(json('2026/municipal/ES-CT.json'));
      expect(
        [for (final e in local) '${e.municipalityCode} ${e.date} ${e.name}'],
        [
          '08002 2026-05-04 Fiesta local (El Pueblo)',
          '08019 2026-05-25 Fiesta local',
          '08019 2026-09-24 Fiesta local',
        ],
      );

      final murcia = parseMunicipalFile(json('2026/municipal/ES-MC.json'));
      expect([for (final e in murcia) e.date.toIso()], ['2026-09-14']);

      final index = MunicipalityIndex.fromJson(json('municipalities.json'));
      expect(index.byCode('08019')?.name, 'Barcelona');
      expect(index.length, 1);
    });

    test('the manifest lists every file with its real sha256 and size', () {
      final build = _build(_fixture());
      expect([
        for (final f in build.manifest.files) f.path,
      ], build.files.keys.where((p) => p != 'manifest.json'));
      for (final f in build.manifest.files) {
        final bytes = build.files[f.path]!;
        expect(f.sha256, sha256.convert(bytes).toString(), reason: f.path);
        expect(f.bytes, bytes.length, reason: f.path);
      }
      // The version is the latest retrieval date plus a content hash.
      expect(build.manifest.bundleVersion, startsWith('2026-10-07.'));
      expect(
        HolidayManifest.fromJson(
          jsonDecode(utf8.decode(build.files['manifest.json']!))
              as Map<String, Object?>,
        ).bundleVersion,
        build.manifest.bundleVersion,
      );
    });

    test('same input, same bytes; writing twice changes nothing', () {
      final dir = _fixture();
      final a = _build(dir);
      final b = _build(dir);
      expect(a.files.keys, b.files.keys);
      for (final path in a.files.keys) {
        expect(a.files[path], b.files[path], reason: path);
      }

      final out = makeTempDir('bundle');
      expect(writeHolidayBundle(out, a), hasLength(a.files.length));
      expect(writeHolidayBundle(out, b), isEmpty);
    });

    test('the version changes when the content does', () {
      final dir = _fixture();
      final before = _build(dir).manifest.bundleVersion;
      File('${dir.path}/national/2026.json').writeAsStringSync(
        jsonEncode({
          'holidays': [_holiday('2026-01-01', 'Año Nuevo!')],
        }),
      );
      expect(_build(dir).manifest.bundleVersion, isNot(before));
    });

    test('stale files and empty folders of an older bundle are removed', () {
      final out = makeTempDir('bundle');
      File('${out.path}/2024/es.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');
      final changed = writeHolidayBundle(out, _build(_fixture()));
      expect(changed, contains('2024/es.json (removed)'));
      expect(Directory('${out.path}/2024').existsSync(), isFalse);
    });

    test('a date outside its year is an error, not silently bundled', () {
      final dir = _fixture();
      File('${dir.path}/national/2026.json').writeAsStringSync(
        jsonEncode({
          'holidays': [_holiday('2027-01-01', 'Año Nuevo')],
        }),
      );
      expect(() => _build(dir), throwsFormatException);
    });

    test('the JSON encoder puts one entry per line, only that deep', () {
      expect(
        encodeBundleJson({
          'a': 1,
          'b': {
            'x': [1, 2],
            'y': {'z': 3},
          },
        }, lineDepth: 2),
        '{\n"a":1,\n"b":{\n"x":[1,2],\n"y":{"z":3}\n}\n}\n',
      );
    });

    test('the pubspec folders are derived from the file paths', () {
      expect(requiredAssetFolders(_build(_fixture())), [
        'assets/holidays/',
        'assets/holidays/2026/',
        'assets/holidays/2026/municipal/',
      ]);
    });
  });

  group('shipped bundle (assets/holidays)', () {
    test('every file matches the manifest hash and size', () {
      final files = shippedBundleFiles();
      final manifest = HolidayManifest.fromJson(
        jsonDecode(utf8.decode(files['assets/holidays/manifest.json']!))
            as Map<String, Object?>,
      );
      expect(manifest.files, isNotEmpty);
      for (final f in manifest.files) {
        final bytes = files['assets/holidays/${f.path}'];
        expect(bytes, isNotNull, reason: '${f.path} is missing');
        expect(bytes!.length, f.bytes, reason: f.path);
        expect(sha256.convert(bytes).toString(), f.sha256, reason: f.path);
      }
      // Nothing in the folder that the manifest does not list.
      expect(
        files.keys.map((k) => k.replaceFirst('assets/holidays/', '')).toSet(),
        {'manifest.json', ...manifest.files.map((f) => f.path)},
      );
    });

    test('every asset folder is declared in the pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final folders = {
        for (final key in shippedBundleFiles().keys)
          key.substring(0, key.lastIndexOf('/') + 1),
      };
      for (final folder in folders) {
        expect(pubspec, contains('- $folder'), reason: folder);
      }
    });

    test('is small and covers 2026 and 2027', () {
      final files = shippedBundleFiles();
      final total = files.values.fold<int>(0, (n, b) => n + b.length);
      expect(total, lessThan(400 * 1024));
      expect(
        files['assets/holidays/municipalities.json']!.length,
        lessThan(300 * 1024),
      );
      expect(
        files.keys,
        containsAll([
          'assets/holidays/2026/es.json',
          'assets/holidays/2027/es.json',
        ]),
      );
    });

    test('building from the real Mochila data twice gives the same bytes', () {
      const backend = '../../mochila-app/backend';
      final calendars = Directory('$backend/src/calendars');
      if (!calendars.existsSync()) {
        markTestSkipped('Mochila is not next to this repository');
        return;
      }
      HolidayBundleBuild build() => buildHolidayBundle(
        calendarsDir: calendars,
        ineMunicipalities: File(
          '$backend/scripts/calendars/sources/ine-municipios-es.json',
        ),
      );
      final a = build();
      final b = build();
      expect(a.manifest.bundleVersion, b.manifest.bundleVersion);
      for (final path in a.files.keys) {
        expect(a.files[path], b.files[path], reason: path);
      }
    });
  });
}
