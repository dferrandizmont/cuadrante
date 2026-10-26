import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../calendar/application/visible_month.dart';

/// The year shown by the annual view: the one of the month on screen when it
/// is opened, then wherever the arrows take it.
class VisibleYear extends Notifier<int> {
  @override
  int build() => ref.read(visibleMonthProvider).year;

  void next() => state = state + 1;

  void previous() => state = state - 1;
}

final visibleYearProvider = NotifierProvider.autoDispose<VisibleYear, int>(
  VisibleYear.new,
);

/// Hands a PNG to the system share sheet. Tests override it.
typedef YearImageSharer = Future<void> Function(
  Uint8List png,
  String fileName,
  String subject,
);

/// Writes the image to the cache folder and opens the share sheet
/// (`share_plus`): WhatsApp, mail, save... Nothing leaves the phone unless
/// the user picks where it goes.
Future<void> shareYearImage(
  Uint8List png,
  String fileName,
  String subject,
) async {
  final dir = await getTemporaryDirectory();
  await deleteStaleSharedImages(dir);
  final file = File(p.join(dir.path, fileName));
  await file.writeAsBytes(png, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'image/png')],
      subject: subject,
    ),
  );
}

final RegExp _sharedImageName = RegExp(r'^cuadrante-\d{4}(-\d{2})?\.png$');

/// Deletes the images this app shared (`cuadrante-2026.png`,
/// `cuadrante-2026-10.png`) that are older than [maxAge] from [dir]. The
/// share sheet has long finished with them; they would only pile up in the
/// cache. Nothing else in [dir] is touched, and a failure is ignored.
Future<void> deleteStaleSharedImages(
  Directory dir, {
  DateTime? now,
  Duration maxAge = const Duration(days: 1),
}) async {
  try {
    final limit = (now ?? DateTime.now()).subtract(maxAge);
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      if (!_sharedImageName.hasMatch(p.basename(entity.path))) continue;
      try {
        if ((await entity.lastModified()).isBefore(limit)) {
          await entity.delete();
        }
      } catch (_) {
        // Already gone, or in use: leave it.
      }
    }
  } catch (_) {
    // The cache folder could not be listed.
  }
}

final yearImageSharerProvider = Provider<YearImageSharer>(
  (ref) => shareYearImage,
);
