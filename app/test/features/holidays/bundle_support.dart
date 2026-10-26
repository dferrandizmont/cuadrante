import 'dart:convert';
import 'dart:io';

import 'package:cuadrante/features/holidays/data/holiday_bundle_loader.dart';
import 'package:cuadrante/features/holidays/domain/holiday_entry.dart';
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';

/// An [AssetBundle] over a map of path -> bytes, to feed the loader a bundle
/// in memory (tampered, older, broken...).
class MemoryAssetBundle extends AssetBundle {
  MemoryAssetBundle(this.files);

  /// Keys like `assets/holidays/manifest.json`.
  final Map<String, List<int>> files;

  @override
  Future<ByteData> load(String key) async {
    final bytes = files[key];
    if (bytes == null) throw FlutterError('Unable to load asset: "$key".');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) async => parser(utf8.decode(files[key]!));
}

/// The files of the bundle that ships in `assets/holidays/` (tests run from
/// `app/`), under their asset keys.
Map<String, List<int>> shippedBundleFiles() {
  final root = Directory('assets/holidays');
  final out = <String, List<int>>{};
  for (final f in root.listSync(recursive: true).whereType<File>()) {
    final path = f.path.replaceAll(r'\', '/');
    if (path.split('/').last.startsWith('.')) continue; // .gitkeep
    out['assets/holidays/${path.split('assets/holidays/').last}'] = f
        .readAsBytesSync();
  }
  return out;
}

/// A copy of the shipped bundle that tests can alter.
MemoryAssetBundle shippedBundle() => MemoryAssetBundle(shippedBundleFiles());

/// Every row of the shipped bundle.
Future<List<HolidayEntry>> shippedEntries() async =>
    (await HolidayBundleLoader(bundle: shippedBundle()).load()).entries;
