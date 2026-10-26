import 'dart:convert';

import 'package:cuadrante/features/backup/domain/canonical_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canonicalJson', () {
    test('sorts keys at every level and writes no whitespace', () {
      expect(
        canonicalJson({
          'b': 1,
          'a': {'z': null, 'y': true},
          'c': [
            {'q': 1, 'p': 2},
          ],
        }),
        '{"a":{"y":true,"z":null},"b":1,"c":[{"p":2,"q":1}]}',
      );
    });

    test('is independent of insertion order', () {
      final one = {'x': 1, 'y': 2, 'z': 3};
      final two = {'z': 3, 'x': 1, 'y': 2};
      expect(canonicalJson(one), canonicalJson(two));
      expect(canonicalJsonBytes(one), canonicalJsonBytes(two));
    });

    test('keeps the order of lists', () {
      expect(canonicalJson([3, 1, 2]), '[3,1,2]');
    });

    test('writes ints and doubles so they read back as the same type', () {
      final text = canonicalJson({'i': 22, 'd': 22.0, 'f': 22.5, 'n': -0.25});
      expect(text, '{"d":22.0,"f":22.5,"i":22,"n":-0.25}');
      final back = jsonDecode(text) as Map<String, Object?>;
      expect(back['i'], isA<int>());
      expect(back['d'], isA<double>());
    });

    test('keeps emojis, accents and line breaks exact', () {
      const note = 'Hola María 👨‍👩‍👧‍👦 🇪🇸\r\nlínea\t2 "q" \\   日本語';
      final text = canonicalJson({'note': note});
      expect(jsonDecode(text), {'note': note});
      // Control characters are escaped; everything else is written as is.
      expect(text, contains('👨‍👩‍👧‍👦'));
      expect(text, contains(r'\r\n'));
      expect(text, isNot(contains('\n')));
    });

    test('rejects what JSON cannot hold', () {
      expect(() => canonicalJson(double.nan), throwsArgumentError);
      expect(() => canonicalJson(double.infinity), throwsArgumentError);
      expect(() => canonicalJson(DateTime(2026)), throwsArgumentError);
      expect(() => canonicalJson({1: 'a'}), throwsA(anything));
    });

    test('sha256Hex matches the published test vector', () {
      expect(
        sha256Hex(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });
  });
}
