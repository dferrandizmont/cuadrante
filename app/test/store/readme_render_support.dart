import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/real_font.dart';

/// Ordinary `flutter test` never writes marketing assets.
const generateStore = bool.fromEnvironment('GENERATE_STORE');

/// Widget tests do not load icon fonts automatically. Load the same manifest
/// as the app so controls are real glyphs, never missing-character squares.
Future<void> loadStoreFonts() async {
  expect(await loadRoboto(), isTrue, reason: 'Roboto is required from the SDK');
  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// RGB PNG, with no metadata or external image tools (as in Ley al Blanco).
Future<void> writeStorePng(ui.Image image, String path) async {
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  final rgba = data!.buffer.asUint8List();
  final rows = Uint8List((image.width * 3 + 1) * image.height);
  for (var y = 0; y < image.height; y++) {
    final start = y * (image.width * 3 + 1);
    rows[start] = 1; // Sub filter: compresses text and flat backgrounds well.
    for (var x = 0; x < image.width; x++) {
      final p = (y * image.width + x) * 4;
      if (rgba[p + 3] != 255) throw StateError('Store images must be opaque');
      for (var c = 0; c < 3; c++) {
        final left = x == 0 ? 0 : rgba[p - 4 + c];
        rows[start + 1 + x * 3 + c] = (rgba[p + c] - left) & 255;
      }
    }
  }
  final header = ByteData(13)
    ..setUint32(0, image.width)
    ..setUint32(4, image.height)
    ..setUint8(8, 8)
    ..setUint8(9, 2);
  final png = BytesBuilder()
    ..add([137, 80, 78, 71, 13, 10, 26, 10])
    ..add(_chunk('IHDR', header.buffer.asUint8List()))
    ..add(_chunk('IDAT', ZLibEncoder(level: 9).convert(rows)))
    ..add(_chunk('IEND', []));
  final bytes = png.takeBytes();
  // Decode the delivered file, rather than just trusting the requested size.
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  expect(frame.image.width, image.width);
  expect(frame.image.height, image.height);
  frame.image.dispose();
  codec.dispose();
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

List<int> _chunk(String type, List<int> data) {
  final payload = [...type.codeUnits, ...data];
  var crc = 0xffffffff;
  for (final byte in payload) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xedb88320 : 0);
    }
  }
  final length = ByteData(4)..setUint32(0, data.length);
  final checksum = ByteData(4)..setUint32(0, crc ^ 0xffffffff);
  return [
    ...length.buffer.asUint8List(),
    ...payload,
    ...checksum.buffer.asUint8List(),
  ];
}

/// Headline in the app's real system font, loaded by the generation tests.
void paintCaption(Canvas canvas, String text, Rect rect, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textAlign: TextAlign.left,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: rect.width);
  expect(painter.height, lessThanOrEqualTo(rect.height), reason: text);
  painter.paint(canvas, rect.topLeft);
  painter.dispose();
}
