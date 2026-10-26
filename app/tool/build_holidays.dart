// Builds Cuadrante's holiday bundle (assets/holidays/) from Mochila's calendar
// data. Read-only on the Mochila side.
//
//   dart run tool/build_holidays.dart                 # writes assets/holidays
//   dart run tool/build_holidays.dart --check         # fails if it is stale
//   dart run tool/build_holidays.dart --mochila <path to mochila-app/backend>
//
// Reads (all under backend/src/calendars/): manifest.json, national/{año}.json,
// regional/ES-XX/{año}.json, municipal/ES-XX/{año}.json and the Murcia school
// file ES-MC/municipal-non-teaching-*.json (its `local_holidays` are local
// holidays; `official.ts` serves them too). Only files the manifest marks
// `verified: true` and `status: complete` go in. The INE names come from
// backend/scripts/calendars/sources/ine-municipios-es.json.
//
// The output is deterministic: same inputs, same bytes. `bundleVersion` is the
// latest `retrieved` date of the included sources plus 8 hex digits of the
// content hash, so it changes whenever any file does.
//
// Format: docs/festivos.md and lib/features/holidays/data/holiday_bundle_format.dart.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cuadrante/features/holidays/data/holiday_bundle_format.dart';
import 'package:cuadrante/features/holidays/domain/spanish_regions.dart';
import 'package:cuadrante/features/schedule/domain/civil_date.dart';

/// Result of [buildHolidayBundle]: the files to write and what was left out.
class HolidayBundleBuild {
  HolidayBundleBuild({
    required this.files,
    required this.manifest,
    required this.skipped,
    required this.notes,
  });

  /// Bundle-relative path -> bytes, `manifest.json` included.
  final Map<String, List<int>> files;
  final HolidayManifest manifest;

  /// Calendar files of the source that did not make it, with the reason.
  final List<String> skipped;
  final List<String> notes;
}

/// Reads Mochila's calendars and produces the bundle in memory.
///
/// [calendarsDir] is `backend/src/calendars`; [ineMunicipalities] the INE
/// code -> name JSON (skipped when null or missing).
HolidayBundleBuild buildHolidayBundle({
  required Directory calendarsDir,
  File? ineMunicipalities,
  String? bundleVersion,
}) {
  final skipped = <String>[];
  final notes = <String>[];
  final files = <String, List<int>>{};
  final entries = <HolidayManifestFile>[];
  final retrieved = <String>[];

  Object? readJson(String relative) =>
      jsonDecode(File('${calendarsDir.path}/$relative').readAsStringSync());

  final sourceManifest = (readJson('manifest.json') as List)
      .cast<Map<String, Object?>>();
  final byFile = {for (final e in sourceManifest) e['file']! as String: e};

  /// Whether [file] may be bundled; otherwise records why not.
  bool usable(String file) {
    final e = byFile[file];
    if (e == null) {
      skipped.add('$file: not in the Mochila manifest');
      return false;
    }
    if (e['verified'] != true || e['status'] != 'complete') {
      skipped.add('$file: ${e['status']}, verified=${e['verified']}');
      return false;
    }
    if (!File('${calendarsDir.path}/$file').existsSync()) {
      skipped.add('$file: listed but missing on disk');
      return false;
    }
    return true;
  }

  Map<String, Object?>? sourceOf(String file) {
    final s = byFile[file]?['source'];
    if (s is! Map) return null;
    final retrievedOn = s['retrieved'];
    if (retrievedOn is String) retrieved.add(retrievedOn);
    return {'url': s['url'], 'ref': s['ref'], 'published': s['published']};
  }

  void add(
    String path,
    Object json, {
    required HolidayFileKind kind,
    int? year,
    String? region,
    Map<String, Object?>? source,
    int lineDepth = 2,
  }) {
    final bytes = utf8.encode(encodeBundleJson(json, lineDepth: lineDepth));
    files[path] = bytes;
    entries.add(
      HolidayManifestFile(
        path: path,
        kind: kind,
        year: year,
        region: region,
        sha256: sha256.convert(bytes).toString(),
        bytes: bytes.length,
        source: source,
      ),
    );
  }

  // 1. Years: those with a usable national file.
  final nationalByYear = <int, Map<String, Object?>>{};
  final nationalFile = RegExp(r'^national/(\d{4})\.json$');
  for (final file in byFile.keys.toList()..sort()) {
    final m = nationalFile.firstMatch(file);
    if (m == null || !usable(file)) continue;
    nationalByYear[int.parse(m[1]!)] = readJson(file)! as Map<String, Object?>;
  }
  final years = nationalByYear.keys.toList()..sort();

  // 2. {year}/es.json: national + regional.
  for (final year in years) {
    final national = _rows(nationalByYear[year]!, year, 'national/$year.json');
    final regional = <String, Object?>{};
    for (final region in spanishRegions.map((r) => r.code).toList()..sort()) {
      final file = 'regional/$region/$year.json';
      if (!usable(file)) continue;
      final json = readJson(file)! as Map<String, Object?>;
      sourceOf(file); // registers its retrieval date for the bundle version
      regional[region] = _rows(json, year, file, withOrigin: true);
    }
    add(
      '$year/es.json',
      {
        'schema': holidayBundleSchema,
        'year': year,
        'national': national,
        'regional': regional,
      },
      kind: HolidayFileKind.es,
      year: year,
      source: sourceOf('national/$year.json'),
    );
  }

  // 3. {year}/municipal/ES-XX.json.
  // (region, year) -> INE code -> days.
  final municipal = <(String, int), Map<String, Set<(String, String?)>>>{};
  final municipalSources = <(String, int), Map<String, Object?>?>{};
  final municipalFile = RegExp(r'^municipal/(ES-[A-Z]{2})/(\d{4})\.json$');
  final schoolFile = RegExp(
    r'^(ES-[A-Z]{2})/municipal-non-teaching-\d{4}-\d{2}\.json$',
  );
  for (final file in byFile.keys.toList()..sort()) {
    final m = municipalFile.firstMatch(file);
    if (m != null) {
      if (!usable(file)) continue;
      final region = m[1]!;
      final year = int.parse(m[2]!);
      final json = readJson(file)! as Map<String, Object?>;
      final target = municipal.putIfAbsent((
        region,
        year,
      ), () => <String, Set<(String, String?)>>{});
      municipalSources.putIfAbsent((region, year), () => sourceOf(file));
      for (final MapEntry(key: code, value: value) in json.entries) {
        final days = (value! as Map)['days']! as List;
        for (final d in days.cast<Map<String, Object?>>()) {
          final date = d['date']! as String;
          _checkDate(date, year, file);
          target.putIfAbsent(code, () => {}).add((
            date,
            _localName(d['label']! as String),
          ));
        }
      }
      continue;
    }
    final s = schoolFile.firstMatch(file);
    if (s != null) {
      if (!usable(file)) continue;
      final region = s[1]!;
      final json = readJson(file)! as Map<String, Object?>;
      final src = sourceOf(file);
      final municipalities = json['municipalities']! as Map;
      for (final MapEntry(key: code, value: value) in municipalities.entries) {
        for (final date
            in ((value as Map)['local_holidays'] as List? ?? const [])
                .cast<String>()) {
          final year = CivilDate.parse(date).year;
          municipal
              .putIfAbsent((
                region,
                year,
              ), () => <String, Set<(String, String?)>>{})
              .putIfAbsent(code as String, () => {})
              .add((date, null));
          municipalSources.putIfAbsent((region, year), () => src);
        }
      }
    }
  }
  final municipalKeys = municipal.keys.toList()
    ..sort((a, b) {
      final y = a.$2.compareTo(b.$2);
      return y != 0 ? y : a.$1.compareTo(b.$1);
    });
  for (final key in municipalKeys) {
    final (region, year) = key;
    if (!years.contains(year)) {
      notes.add(
        'municipal $region $year: no national file for $year, left out',
      );
      continue;
    }
    final codes = municipal[key]!.keys.toList()..sort();
    add(
      '$year/municipal/$region.json',
      {
        'schema': holidayBundleSchema,
        'year': year,
        'region': region,
        'municipalities': {
          for (final code in codes)
            code: [
              for (final (date, name)
                  in (municipal[key]![code]!.toList()..sort((a, b) {
                    final d = a.$1.compareTo(b.$1);
                    return d != 0 ? d : (a.$2 ?? '').compareTo(b.$2 ?? '');
                  })))
                {'date': date, 'name': ?name},
            ],
        },
      },
      kind: HolidayFileKind.municipal,
      year: year,
      region: region,
      source: municipalSources[key],
    );
  }

  // 4. municipalities.json.
  if (ineMunicipalities != null && ineMunicipalities.existsSync()) {
    final ine = (jsonDecode(ineMunicipalities.readAsStringSync()) as Map)
        .cast<String, String>();
    final byRegion = <String, Map<String, String>>{};
    for (final code in ine.keys.toList()..sort()) {
      final region = regionOfMunicipality(code);
      if (region == null) {
        notes.add('INE $code (${ine[code]}): unknown province, left out');
        continue;
      }
      byRegion.putIfAbsent(region.code, () => {})[code] = ine[code]!;
    }
    add('municipalities.json', {
      'schema': holidayBundleSchema,
      'regions': {
        for (final code in byRegion.keys.toList()..sort()) code: byRegion[code],
      },
    }, kind: HolidayFileKind.municipalities);
  } else {
    notes.add('municipalities.json: INE source not found, not generated');
  }

  entries.sort((a, b) => a.path.compareTo(b.path));
  retrieved.sort();
  final digest = sha256
      .convert(
        utf8.encode(entries.map((e) => '${e.path}:${e.sha256}\n').join()),
      )
      .toString();
  final version =
      bundleVersion ??
      '${retrieved.isEmpty ? '0000-00-00' : retrieved.last}.${digest.substring(0, 8)}';
  final manifest = HolidayManifest(bundleVersion: version, files: entries);
  files['manifest.json'] = utf8.encode(
    encodeBundleJson(manifest.toJson(), lineDepth: 2),
  );
  return HolidayBundleBuild(
    files: Map.fromEntries(
      files.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    ),
    manifest: manifest,
    skipped: skipped..sort(),
    notes: notes,
  );
}

/// `[{date, name[, origin]}]` sorted by date then name, Spanish labels only.
List<Map<String, Object?>> _rows(
  Map<String, Object?> json,
  int year,
  String file, {
  bool withOrigin = false,
}) {
  final rows = <Map<String, Object?>>[];
  for (final h in (json['holidays']! as List).cast<Map<String, Object?>>()) {
    final date = h['date']! as String;
    _checkDate(date, year, file);
    final name = (h['label']! as Map)['es']! as String;
    if (withOrigin) {
      final origin = h['origin'];
      if (origin != 'regional' && origin != 'national-optional') {
        throw FormatException('$file: unknown origin $origin on $date');
      }
      rows.add({'date': date, 'name': name, 'origin': origin});
    } else {
      rows.add({'date': date, 'name': name});
    }
  }
  rows.sort((a, b) {
    final d = (a['date']! as String).compareTo(b['date']! as String);
    return d != 0 ? d : (a['name']! as String).compareTo(b['name']! as String);
  });
  return rows;
}

void _checkDate(String date, int year, String file) {
  final parsed = CivilDate.parse(date);
  if (parsed.year != year) {
    throw FormatException('$file: $date is not in $year');
  }
}

/// `null` for a plain local holiday (the format's default name).
String? _localName(String raw) {
  if (raw == 'Festa local' || raw == 'Fiesta local') return null;
  final m = RegExp(r'^(?:Fiesta local|Festa local) (\(.+\))$').firstMatch(raw);
  return m != null ? 'Fiesta local ${m[1]}' : raw;
}

/// JSON with the first [lineDepth] levels of objects (and lists) one entry per
/// line, everything deeper compact. Keys keep their insertion order, so the
/// output is as deterministic as the data fed in. Ends with a newline.
String encodeBundleJson(Object? value, {int lineDepth = 1}) =>
    '${_encode(value, 0, lineDepth)}\n';

String _encode(Object? value, int depth, int lineDepth) {
  if (depth < lineDepth && value is Map) {
    final lines = [
      for (final MapEntry(key: k, value: v) in value.entries)
        '${jsonEncode(k)}:${_encode(v, depth + 1, lineDepth)}',
    ];
    return lines.isEmpty ? '{}' : '{\n${lines.join(',\n')}\n}';
  }
  if (depth < lineDepth && value is List) {
    final lines = [for (final v in value) _encode(v, depth + 1, lineDepth)];
    return lines.isEmpty ? '[]' : '[\n${lines.join(',\n')}\n]';
  }
  return jsonEncode(value);
}

/// Writes [build] into [out], removing stale `.json` files of an older bundle.
/// Returns the paths that changed.
List<String> writeHolidayBundle(Directory out, HolidayBundleBuild build) {
  final changed = <String>[];
  out.createSync(recursive: true);
  for (final entity in out.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final relative = _relative(out, entity);
    if (!build.files.containsKey(relative)) {
      entity.deleteSync();
      changed.add('$relative (removed)');
    }
  }
  for (final MapEntry(key: path, value: bytes) in build.files.entries) {
    final file = File('${out.path}/$path');
    if (file.existsSync() && _same(file.readAsBytesSync(), bytes)) continue;
    file.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    changed.add(path);
  }
  // Drop folders left empty (a year that is gone).
  for (final entity in out.listSync(recursive: true).reversed) {
    if (entity is Directory && entity.listSync().isEmpty) entity.deleteSync();
  }
  return changed;
}

String _relative(Directory root, File file) {
  final r = root.absolute.path.replaceAll('\\', '/');
  final f = file.absolute.path.replaceAll('\\', '/');
  return f.substring(r.endsWith('/') ? r.length : r.length + 1);
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The asset folders `pubspec.yaml` has to declare for [build] (Flutter does
/// not scan sub-folders).
List<String> requiredAssetFolders(HolidayBundleBuild build) {
  final folders = <String>{};
  for (final path in build.files.keys) {
    final slash = path.lastIndexOf('/');
    folders.add(
      slash < 0
          ? 'assets/holidays/'
          : 'assets/holidays/${path.substring(0, slash)}/',
    );
  }
  return folders.toList()..sort();
}

Future<void> main(List<String> args) async {
  exitCode = await _run(args);
}

Future<int> _run(List<String> args) async {
  var mochila = '../../mochila-app/backend';
  var out = 'assets/holidays';
  var check = false;
  String? version;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--mochila':
        mochila = args[++i];
      case '--out':
        out = args[++i];
      case '--bundle-version':
        version = args[++i];
      case '--check':
        check = true;
      default:
        stdout.writeln(
          'Uso: dart run tool/build_holidays.dart [--mochila <backend>] '
          '[--out <carpeta>] [--bundle-version <v>] [--check]',
        );
        return args[i] == '--help' ? 0 : 64;
    }
  }
  final calendars = Directory('$mochila/src/calendars');
  if (!calendars.existsSync()) {
    stderr.writeln('No encuentro ${calendars.path} (usa --mochila).');
    return 66;
  }
  final build = buildHolidayBundle(
    calendarsDir: calendars,
    ineMunicipalities: File(
      '$mochila/scripts/calendars/sources/ine-municipios-es.json',
    ),
    bundleVersion: version,
  );

  final outDir = Directory(out);
  if (check) {
    final stale = <String>[
      for (final MapEntry(key: path, value: bytes) in build.files.entries)
        if (!File('$out/$path').existsSync() ||
            !_same(File('$out/$path').readAsBytesSync(), bytes))
          path,
    ];
    if (stale.isNotEmpty) {
      stderr.writeln('El paquete está desactualizado: ${stale.join(', ')}');
      return 1;
    }
    stdout.writeln('El paquete está al día (${build.manifest.bundleVersion}).');
    return 0;
  }

  final changed = writeHolidayBundle(outDir, build);
  stdout.writeln('bundleVersion ${build.manifest.bundleVersion}');
  for (final f in build.manifest.files) {
    stdout.writeln(
      '  ${f.path.padRight(34)} ${f.bytes.toString().padLeft(7)} B',
    );
  }
  final total = build.files.values.fold<int>(0, (n, b) => n + b.length);
  stdout.writeln(
    '${build.files.length} archivos, $total B; '
    '${changed.isEmpty ? 'sin cambios' : '${changed.length} escritos'}',
  );
  if (build.skipped.isNotEmpty) {
    stdout.writeln('Omitidos (no verificados o sin publicar):');
    for (final s in build.skipped) {
      stdout.writeln('  $s');
    }
  }
  for (final n in build.notes) {
    stdout.writeln('Nota: $n');
  }
  final pubspec = File('pubspec.yaml');
  if (pubspec.existsSync()) {
    final text = pubspec.readAsStringSync();
    final missing = [
      for (final folder in requiredAssetFolders(build))
        if (!text.contains('- $folder')) folder,
    ];
    if (missing.isNotEmpty) {
      stdout.writeln('AVISO: faltan en pubspec.yaml (flutter: assets:):');
      for (final m in missing) {
        stdout.writeln('    - $m');
      }
    }
  }
  return 0;
}
