import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../domain/holiday_entry.dart';
import 'holiday_bundle_format.dart';

/// The holidays of a bundle, ready to store.
class LoadedHolidayBundle {
  const LoadedHolidayBundle({required this.manifest, required this.entries});

  final HolidayManifest manifest;
  final List<HolidayEntry> entries;
}

/// Reads the holiday bundle that ships inside the app (`assets/holidays/`)
/// and checks every file against the SHA-256 and size of `manifest.json`:
/// a truncated or altered file is rejected, never half-loaded.
class HolidayBundleLoader {
  HolidayBundleLoader({AssetBundle? bundle, this.root = 'assets/holidays'})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String root;

  /// `manifest.json` alone: a few hundred bytes, enough to know whether the
  /// stored holidays are up to date.
  Future<HolidayManifest> readManifest() async {
    final bytes = await _read('manifest.json');
    return HolidayManifest.fromJson(_decode(bytes, 'manifest.json'));
  }

  /// Every `es.json` and `municipal/*.json` of the bundle as rows.
  Future<LoadedHolidayBundle> load({HolidayManifest? manifest}) async {
    final m = manifest ?? await readManifest();
    final entries = <HolidayEntry>[];
    for (final file in m.files) {
      switch (file.kind) {
        case HolidayFileKind.es:
          entries.addAll(parseEsFile(await _readJson(file)));
        case HolidayFileKind.municipal:
          entries.addAll(parseMunicipalFile(await _readJson(file)));
        case HolidayFileKind.municipalities:
          break;
      }
    }
    return LoadedHolidayBundle(manifest: m, entries: entries);
  }

  /// The municipalities for the picker; `null` when the bundle has no index.
  Future<MunicipalityIndex?> loadMunicipalities({
    HolidayManifest? manifest,
  }) async {
    final m = manifest ?? await readManifest();
    for (final file in m.files) {
      if (file.kind == HolidayFileKind.municipalities) {
        return MunicipalityIndex.fromJson(await _readJson(file));
      }
    }
    return null;
  }

  Future<Map<String, Object?>> _readJson(HolidayManifestFile file) async {
    final bytes = await _read(file.path);
    if (bytes.length != file.bytes) {
      throw HolidayBundleException(
        '${file.path}: ${bytes.length} bytes, the manifest says ${file.bytes}',
      );
    }
    if (sha256.convert(bytes).toString() != file.sha256) {
      throw HolidayBundleException('${file.path}: SHA-256 does not match');
    }
    return _decode(bytes, file.path);
  }

  Future<Uint8List> _read(String path) async {
    final ByteData data;
    try {
      data = await _bundle.load('$root/$path');
    } catch (_) {
      throw HolidayBundleException('$path: cannot be read from the app');
    }
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Map<String, Object?> _decode(Uint8List bytes, String path) {
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is Map) return json.cast<String, Object?>();
    } on FormatException catch (e) {
      throw HolidayBundleException('$path: ${e.message}');
    }
    throw HolidayBundleException('$path: not a JSON object');
  }
}
