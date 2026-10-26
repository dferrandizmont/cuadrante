import 'dart:io';

import 'package:cuadrante/core/theme/app_typography.dart';
import 'package:flutter/services.dart';

/// Loads Roboto (the font of the app on Android) from the Flutter SDK.
///
/// The test font (Ahem) is about twice as wide as a real one, so a layout
/// test of long lines (a settings row at 360 dp and text 2.0) needs the real
/// font to say anything about a phone. Weights 400, 500 and 700 are loaded;
/// the others fall back to the nearest.
///
/// Returns false when the SDK files cannot be found (the caller decides
/// whether that skips the test).
Future<bool> loadRoboto() async {
  final dir = _materialFonts();
  if (dir == null) return false;
  Future<ByteData> bytes(String name) async {
    final data = await File('${dir.path}/$name').readAsBytes();
    return ByteData.sublistView(data);
  }

  final loader = FontLoader('Roboto')
    ..addFont(bytes('roboto-regular.ttf'))
    ..addFont(bytes('roboto-medium.ttf'))
    ..addFont(bytes('roboto-bold.ttf'));
  await loader.load();
  // The app's text styles name no family (they use the phone's system font),
  // and the test engine renders those in Ahem wherever a widget sets its own
  // default style (list tiles, buttons): point them at Roboto.
  AppTypography.debugFamily = 'Roboto';
  return true;
}

/// `<flutter>/bin/cache/artifacts/material_fonts`, from FLUTTER_ROOT or from
/// the path of the test runner.
Directory? _materialFonts() {
  final candidates = <String>[
    if (Platform.environment['FLUTTER_ROOT'] case final root?)
      '$root/bin/cache/artifacts/material_fonts',
  ];
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    candidates.add('${dir.path}/material_fonts');
    candidates.add('${dir.path}/artifacts/material_fonts');
    dir = dir.parent;
  }
  for (final path in candidates) {
    final found = Directory(path);
    if (File('${found.path}/roboto-regular.ttf').existsSync()) return found;
  }
  return null;
}
