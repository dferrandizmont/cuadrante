import 'dart:convert';

import 'package:cuadrante/features/holidays/data/holiday_bundle_format.dart';
import 'package:cuadrante/features/holidays/data/holiday_bundle_loader.dart';
import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bundle_support.dart';

const _es2026 = 'assets/holidays/2026/es.json';
const _manifest = 'assets/holidays/manifest.json';

Future<void> _expectRejected(MemoryAssetBundle bundle, Matcher message) async {
  await expectLater(
    HolidayBundleLoader(bundle: bundle).load(),
    throwsA(
      isA<HolidayBundleException>().having(
        (e) => e.message,
        'message',
        message,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads the shipped bundle: 2026 and 2027, national, regional, local',
    () async {
      final loader = HolidayBundleLoader(bundle: shippedBundle());
      final bundle = await loader.load();

      expect(bundle.manifest.years, [2026, 2027]);
      expect(
        bundle.manifest.bundleVersion,
        matches(RegExp(r'^\d{4}-\d{2}-\d{2}\.')),
      );
      final scopes = {for (final e in bundle.entries) e.scope};
      expect(scopes, HolidayScope.values.toSet());
      expect(
        bundle.entries.where((e) => e.source != HolidaySource.bundled),
        isEmpty,
      );
      // Barcelona's two locals are in there.
      expect(
        bundle.entries
            .where((e) => e.municipalityCode == '08019')
            .map((e) => e.date.toIso()),
        ['2026-05-25', '2026-09-24'],
      );
    },
  );

  test(
    'reads the bundle from the real asset bundle (pubspec declares it)',
    () async {
      final bundle = await HolidayBundleLoader().load();
      expect(bundle.entries, isNotEmpty);
      final index = await HolidayBundleLoader().loadMunicipalities();
      expect(index?.byCode('08019')?.name, 'Barcelona');
    },
  );

  test('the municipality index covers every province for the picker', () async {
    final index = (await HolidayBundleLoader(bundle: shippedBundle())
        .loadMunicipalities())!;
    expect(index.length, greaterThan(8000));
    expect(index.inRegion('ES-CT').length, 947);
    expect(index.inRegion('ES-MD').length, 179);
    expect(index.byCode('28079')?.name, 'Madrid');
    expect(index.byCode('00000'), isNull);
    expect(index.inRegion('ES-XX'), isEmpty);
  });

  group('integrity', () {
    test('a file changed after the manifest was made is rejected', () async {
      final bundle = shippedBundle();
      final bytes = List<int>.of(bundle.files[_es2026]!);
      // Same length, different content: only the hash can tell.
      final i = bytes.indexOf('A'.codeUnitAt(0));
      bytes[i] = 'B'.codeUnitAt(0);
      bundle.files[_es2026] = bytes;

      await _expectRejected(bundle, contains('2026/es.json: SHA-256'));
    });

    test('a truncated file is rejected', () async {
      final bundle = shippedBundle();
      final bytes = bundle.files[_es2026]!;
      bundle.files[_es2026] = bytes.sublist(0, bytes.length - 20);

      await _expectRejected(bundle, contains('bytes'));
    });

    test('a name edited by hand is rejected', () async {
      final bundle = shippedBundle();
      final text = utf8.decode(bundle.files[_es2026]!);
      bundle.files[_es2026] = utf8.encode(
        text.replaceFirst('"Año Nuevo"', '"Año Nuevu"'),
      );

      await _expectRejected(bundle, contains('SHA-256'));
    });

    test('a missing file is rejected', () async {
      final bundle = shippedBundle()..files.remove(_es2026);
      await _expectRejected(bundle, contains('cannot be read'));
    });

    test('a manifest from another schema is rejected', () async {
      final bundle = shippedBundle();
      bundle.files[_manifest] = utf8.encode(
        utf8
            .decode(bundle.files[_manifest]!)
            .replaceFirst('"schema":1', '"schema":2'),
      );
      await _expectRejected(bundle, contains('schema'));
    });

    test('a manifest that is not JSON is rejected', () async {
      final bundle = shippedBundle();
      bundle.files[_manifest] = utf8.encode('not json');
      await _expectRejected(bundle, contains('manifest.json'));
    });

    test('a file with a date outside its year is rejected even if hashed', () {
      expect(
        () => parseEsFile({
          'schema': 1,
          'year': 2026,
          'national': [
            {'date': '2027-01-01', 'name': 'x'},
          ],
          'regional': <String, Object?>{},
        }),
        throwsA(isA<HolidayBundleException>()),
      );
    });
  });
}
