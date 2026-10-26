import 'package:cuadrante/features/shift_types/domain/free_color.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseHex', () {
    test('accepts #RRGGBB, RRGGBB and the short forms, in any case', () {
      expect(FreeColor.parseHex('#1C7ED6'), 0xFF1C7ED6);
      expect(FreeColor.parseHex('1c7ed6'), 0xFF1C7ED6);
      expect(FreeColor.parseHex('  #1c7ED6 '), 0xFF1C7ED6);
      expect(FreeColor.parseHex('#fa0'), 0xFFFFAA00);
      expect(FreeColor.parseHex('0F0'), 0xFF00FF00);
      expect(FreeColor.parseHex('#000000'), 0xFF000000);
    });

    test('rejects anything else', () {
      for (final bad in [
        '',
        '#',
        '#12',
        '#12345',
        '#1234567',
        'GG0000',
        '#ñ',
      ]) {
        expect(FreeColor.parseHex(bad), isNull, reason: bad);
      }
    });
  });

  group('toHex', () {
    test('is #RRGGBB in upper case, without the alpha', () {
      expect(FreeColor.toHex(0xFF1C7ED6), '#1C7ED6');
      expect(FreeColor.toHex(0xFF000A0F), '#000A0F');
      expect(FreeColor.toHex(0x801C7ED6), '#1C7ED6');
    });

    test('round-trips with parseHex', () {
      for (final value in [0xFF000000, 0xFFFFFFFF, 0xFF12ABEF, 0xFFD6336C]) {
        expect(FreeColor.parseHex(FreeColor.toHex(value)), value);
      }
    });
  });

  group('normalize', () {
    test('makes the colour opaque', () {
      expect(FreeColor.normalize(0x331C7ED6), 0xFF1C7ED6);
    });

    test('moves the exact grey of Libre one step away', () {
      expect(FreeColor.normalize(0xFFE4E4E7), 0xFFE4E4E8);
      expect(FreeColor.normalize(0xFFE4E4E8), 0xFFE4E4E8);
    });
  });

  group('fromHsl', () {
    test('known colours', () {
      expect(FreeColor.fromHsl(0, 1, 0.5), 0xFFFF0000);
      expect(FreeColor.fromHsl(120, 1, 0.5), 0xFF00FF00);
      expect(FreeColor.fromHsl(240, 1, 0.5), 0xFF0000FF);
      expect(FreeColor.fromHsl(0, 0, 0), 0xFF000000);
      expect(FreeColor.fromHsl(0, 0, 1), 0xFFFFFFFF);
    });

    test('clamps out-of-range values', () {
      expect(FreeColor.fromHsl(-10, 2, 0.5), FreeColor.fromHsl(0, 1, 0.5));
      expect(FreeColor.fromHsl(400, 1, 2), 0xFFFFFFFF);
    });

    test('toHsl gives back (about) what fromHsl was given', () {
      final hsl = FreeColor.toHsl(FreeColor.fromHsl(200, 0.6, 0.4));
      expect(hsl.hue, closeTo(200, 1));
      expect(hsl.saturation, closeTo(0.6, 0.02));
      expect(hsl.lightness, closeTo(0.4, 0.02));
    });
  });
}
