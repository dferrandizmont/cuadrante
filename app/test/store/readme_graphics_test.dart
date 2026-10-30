@Tags(['store'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:cuadrante/core/theme/app_colors.dart';
import 'package:cuadrante/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'readme_render_support.dart';

const _readme = {'es', 'ca', 'gl', 'eu', 'en'};
const _subtitle = {
  'es': 'Tus turnos, de un vistazo',
  'ca': "Els teus torns, d'un cop d'ull",
  'gl': 'As túas quendas, dunha ollada',
  'eu': 'Zure txandak, begi-kolpe batean',
  'en': 'Your shifts at a glance',
};
const _tagline = {
  'es': 'Gratis · Sin anuncios · Sin conexión',
  'ca': 'Gratis · Sense anuncis · Sense connexió',
  'gl': 'Gratis · Sen anuncios · Sen conexión',
  'eu': 'Doan · Iragarkirik gabe · Konexiorik gabe',
  'en': 'Free · No ads · Offline',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (generateStore) await loadStoreFonts();
  });
  tearDownAll(() => AppTypography.debugFamily = null);

  for (final language in _subtitle.keys) {
    test('Gráficos $language: cabecera 1024×500 e icono 512×512', () async {
      final bytes = File('assets/icon/icon.png').readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final icon = frame.image;
      const colors = AppColors.dark;
      final type = AppTypography.from(colors);
      try {
        for (final isHeader in [true, false]) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          final size = isHeader ? const Size(1024, 500) : const Size(512, 512);
          canvas.drawRect(
            Offset.zero & size,
            Paint()..color = colors.background,
          );
          final iconRect = isHeader
              ? const Rect.fromLTWH(48, 122, 256, 256)
              : const Rect.fromLTWH(0, 0, 512, 512);
          canvas.drawImageRect(
            icon,
            Rect.fromLTWH(0, 0, icon.width.toDouble(), icon.height.toDouble()),
            iconRect,
            Paint()..filterQuality = FilterQuality.high,
          );
          if (isHeader) {
            paintCaption(
              canvas,
              'Turnly',
              const Rect.fromLTWH(344, 125, 632, 90),
              type.display.copyWith(fontSize: 72),
            );
            paintCaption(
              canvas,
              _subtitle[language]!,
              const Rect.fromLTWH(348, 237, 628, 90),
              type.bodyStrong.copyWith(fontSize: 32),
            );
            paintCaption(
              canvas,
              _tagline[language]!,
              const Rect.fromLTWH(348, 325, 628, 60),
              type.body.copyWith(fontSize: 25, color: colors.highlight),
            );
          }
          final picture = recorder.endRecording();
          final image = await picture.toImage(
            size.width.toInt(),
            size.height.toInt(),
          );
          try {
            await writeStorePng(
              image,
              // The README is published in every app language.
              '${_readme.contains(language) ? '../docs/readme' : 'build/store/play'}'
              '/$language/${isHeader ? 'header' : 'icon-512'}.png',
            );
          } finally {
            image.dispose();
            picture.dispose();
          }
        }
      } finally {
        icon.dispose();
        codec.dispose();
      }
    }, skip: !generateStore);
  }
}
