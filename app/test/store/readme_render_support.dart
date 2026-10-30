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

/// Logical size of the phone used for the raw GitHub screenshots (Pixel 7
/// class): 412 dp wide, rendered at 1080 px so the PNG is exactly 1080x2400.
const githubPhysical = Size(1080, 2400);
const githubWidthDp = 412.0;
const githubPixelRatio = 1080 / githubWidthDp;

/// Status bar height and gesture bar inset of the fake phone, in dp.
const githubStatusBarDp = 40.0;
const githubGestureDp = 24.0;

/// Draws a realistic Android status bar (10:00, wifi, 3G, signal, full
/// battery) and the gesture navigation pill over an already painted screen.
/// [canvas] is in physical pixels (1080x2400). Nothing is painted behind the
/// icons: the app's own background shows through, as on a real phone.
void paintAndroidChrome(
  Canvas canvas, {
  required Size size,
  required Color ink,
  required TextStyle textStyle,
}) {
  final dp = size.width / githubWidthDp;
  final ys = githubStatusBarDp * dp;
  final cy = ys / 2;

  // Time, left.
  final time = TextPainter(
    text: TextSpan(
      text: '10:00',
      style: textStyle.copyWith(
        color: ink,
        fontSize: 14 * dp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  time.paint(canvas, Offset(24 * dp, cy - time.height / 2));
  time.dispose();

  final fill = Paint()
    ..color = ink
    ..style = ui.PaintingStyle.fill
    ..isAntiAlias = true;

  // Right side, painted from right to left.
  var x = size.width - 20 * dp;

  // Battery, full: 8x14 dp body with a small cap.
  const bw = 8.0, bh = 14.0;
  x -= bw * dp;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x, cy - bh * dp / 2 + 1 * dp, bw * dp, (bh - 1) * dp),
      Radius.circular(1.2 * dp),
    ),
    fill,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 2.5 * dp, cy - bh * dp / 2, 3 * dp, 1.6 * dp),
      Radius.circular(.6 * dp),
    ),
    fill,
  );

  // Signal triangle (full).
  x -= 6 * dp;
  const sw = 13.0, sh = 13.0;
  x -= sw * dp;
  canvas.drawPath(
    Path()
      ..moveTo(x + sw * dp, cy - sh * dp / 2)
      ..lineTo(x + sw * dp, cy + sh * dp / 2)
      ..lineTo(x, cy + sh * dp / 2)
      ..close(),
    fill,
  );

  // "3G".
  x -= 4 * dp;
  final network = TextPainter(
    text: TextSpan(
      text: '3G',
      style: textStyle.copyWith(
        color: ink,
        fontSize: 13 * dp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  x -= network.width;
  network.paint(canvas, Offset(x, cy - network.height / 2));
  network.dispose();

  // Wifi: a filled fan with a flat bottom, as Android draws it.
  x -= 6 * dp;
  const ww = 16.0, wh = 12.0;
  x -= ww * dp;
  final wifi = Path()
    ..moveTo(x + ww * dp / 2, cy + wh * dp / 2)
    ..lineTo(x, cy - wh * dp / 2 + 3.2 * dp)
    ..arcToPoint(
      Offset(x + ww * dp, cy - wh * dp / 2 + 3.2 * dp),
      radius: Radius.circular(ww * dp * .72),
      clockwise: true,
    )
    ..close();
  canvas.drawPath(wifi, fill);

  // Gesture pill, centred; Android draws it 108x4 dp, about 12 dp from the
  // bottom edge.
  final pillW = 108 * dp, pillH = 4 * dp;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (size.width - pillW) / 2,
        size.height - 12 * dp - pillH / 2,
        pillW,
        pillH,
      ),
      Radius.circular(pillH / 2),
    ),
    Paint()
      ..color = ink.withValues(alpha: .9)
      ..isAntiAlias = true,
  );
}
