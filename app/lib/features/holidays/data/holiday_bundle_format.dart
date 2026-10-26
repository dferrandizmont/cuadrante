// The holiday bundle format (docs/festivos.md). Pure Dart, no Flutter: the
// bundle tool (tool/build_holidays.dart) and the app share it, so what the
// tool writes is exactly what the loader reads.
//
// assets/holidays/
//   manifest.json                  {schema, bundleVersion, files[...]}
//   municipalities.json            INE code -> name, per region (the picker)
//   {year}/es.json                 national + the 19 regions
//   {year}/municipal/ES-XX.json    local holidays per municipality (INE code)

import '../../../core/format/text_fold.dart';
import '../../schedule/domain/civil_date.dart';
import '../domain/holiday.dart';
import '../domain/holiday_entry.dart';
import '../domain/spanish_regions.dart';

/// Current format version. A file with another `schema` is rejected.
const int holidayBundleSchema = 1;

/// Name of a local holiday that has no own name.
const String defaultLocalHolidayName = 'Fiesta local';

/// Raised when a bundle (or a piece of it) is damaged or not understood.
class HolidayBundleException implements Exception {
  const HolidayBundleException(this.message);

  final String message;

  @override
  String toString() => 'HolidayBundleException: $message';
}

enum HolidayFileKind {
  /// `{year}/es.json`: national plus regional holidays of the 19 regions.
  es,

  /// `{year}/municipal/ES-XX.json`: local holidays of one region.
  municipal,

  /// `municipalities.json`: INE code -> name (the picker).
  municipalities,
}

/// One line of `manifest.json -> files`.
class HolidayManifestFile {
  const HolidayManifestFile({
    required this.path,
    required this.kind,
    required this.sha256,
    required this.bytes,
    this.year,
    this.region,
    this.source,
  });

  factory HolidayManifestFile.fromJson(Map<String, Object?> json) {
    final scope = _string(json, 'scope');
    final kind = HolidayFileKind.values.where((k) => k.name == scope);
    if (kind.isEmpty) {
      throw HolidayBundleException('manifest: unknown scope "$scope"');
    }
    final source = json['source'];
    return HolidayManifestFile(
      path: _string(json, 'path'),
      kind: kind.first,
      year: json['year'] as int?,
      region: json['region'] as String?,
      sha256: _string(json, 'sha256'),
      bytes: json['bytes'] as int? ?? -1,
      source: source is Map<String, Object?> ? source : null,
    );
  }

  /// Relative to the bundle root, `/`-separated.
  final String path;
  final HolidayFileKind kind;
  final int? year;
  final String? region;

  /// Lower-case hex SHA-256 of the file bytes.
  final String sha256;
  final int bytes;

  /// Where the data comes from (`url`, `ref`, `published`), for attribution.
  final Map<String, Object?>? source;

  Map<String, Object?> toJson() => {
    'path': path,
    'year': year,
    'scope': kind.name,
    if (region != null) 'region': region,
    'sha256': sha256,
    'bytes': bytes,
    if (source != null) 'source': source,
  };
}

/// `manifest.json`.
class HolidayManifest {
  const HolidayManifest({required this.bundleVersion, required this.files});

  factory HolidayManifest.fromJson(Map<String, Object?> json) {
    final schema = json['schema'];
    if (schema != holidayBundleSchema) {
      throw HolidayBundleException('manifest: unsupported schema $schema');
    }
    final files = json['files'];
    if (files is! List) {
      throw const HolidayBundleException('manifest: no files');
    }
    return HolidayManifest(
      bundleVersion: _string(json, 'bundleVersion'),
      files: [
        for (final f in files)
          HolidayManifestFile.fromJson((f as Map).cast<String, Object?>()),
      ],
    );
  }

  /// Changes whenever any file of the bundle changes.
  final String bundleVersion;
  final List<HolidayManifestFile> files;

  Map<String, Object?> toJson() => {
    'schema': holidayBundleSchema,
    'bundleVersion': bundleVersion,
    'files': [for (final f in files) f.toJson()],
  };

  /// Distinct years that have an `es.json`, ascending.
  List<int> get years => ([
    for (final f in files)
      if (f.kind == HolidayFileKind.es && f.year != null) f.year!,
  ]..sort());
}

/// Rows of `{year}/es.json`.
///
/// ```json
/// {"schema":1,"year":2026,
///  "national":[{"date":"2026-01-01","name":"Año Nuevo"}],
///  "regional":{"ES-CT":[{"date":"2026-01-06","name":"...","origin":"national-optional"}]}}
/// ```
/// `origin` is `regional` or `national-optional` (a national day that region
/// keeps; becomes a national row tied to the region).
List<HolidayEntry> parseEsFile(
  Map<String, Object?> json, {
  HolidaySource source = HolidaySource.bundled,
}) {
  _checkSchema(json, 'es.json');
  final year = json['year'] as int;
  final out = <HolidayEntry>[];
  for (final h in _list(json, 'national')) {
    out.add(
      HolidayEntry(
        date: _date(h, year),
        scope: HolidayScope.national,
        name: _string(h, 'name'),
        source: source,
      ),
    );
  }
  final regional = json['regional'];
  if (regional is! Map) {
    throw const HolidayBundleException('es.json: no regional');
  }
  for (final MapEntry(key: code, value: rows) in regional.entries) {
    final region = normalizeRegionCode(code as String);
    if (region == null) {
      throw HolidayBundleException('es.json: unknown region $code');
    }
    for (final h in (rows as List).cast<Map<String, Object?>>()) {
      final origin = h['origin'];
      if (origin != 'regional' && origin != 'national-optional') {
        throw HolidayBundleException('es.json: unknown origin $origin');
      }
      out.add(
        HolidayEntry(
          date: _date(h, year),
          scope: origin == 'regional'
              ? HolidayScope.regional
              : HolidayScope.national,
          name: _string(h, 'name'),
          regionCode: region,
          source: source,
        ),
      );
    }
  }
  return out;
}

/// Rows of `{year}/municipal/ES-XX.json`.
///
/// ```json
/// {"schema":1,"year":2026,"region":"ES-CT",
///  "municipalities":{"08019":[{"date":"2026-05-25"},{"date":"2026-09-24"}]}}
/// ```
/// A day without `name` is a plain "Fiesta local".
List<HolidayEntry> parseMunicipalFile(
  Map<String, Object?> json, {
  HolidaySource source = HolidaySource.bundled,
}) {
  _checkSchema(json, 'municipal file');
  final year = json['year'] as int;
  final region = normalizeRegionCode(json['region'] as String?);
  if (region == null) {
    throw HolidayBundleException(
      'municipal file: bad region ${json['region']}',
    );
  }
  final municipalities = json['municipalities'];
  if (municipalities is! Map) {
    throw const HolidayBundleException('municipal file: no municipalities');
  }
  final out = <HolidayEntry>[];
  for (final MapEntry(key: code, value: days) in municipalities.entries) {
    if (!isMunicipalityCode(code as String)) {
      throw HolidayBundleException('municipal file: bad INE code $code');
    }
    for (final d in (days as List).cast<Map<String, Object?>>()) {
      out.add(
        HolidayEntry(
          date: _date(d, year),
          scope: HolidayScope.local,
          name: d['name'] as String? ?? defaultLocalHolidayName,
          regionCode: region,
          municipalityCode: code,
          source: source,
        ),
      );
    }
  }
  return out;
}

/// A municipality of the picker.
class Municipality {
  const Municipality(this.code, this.name, this.regionCode);

  /// INE, five digits.
  final String code;
  final String name;
  final String regionCode;
}

/// `municipalities.json`: `{"schema":1,"regions":{"ES-CT":{"08019":"Barcelona"}}}`.
class MunicipalityIndex {
  const MunicipalityIndex(this._byRegion);

  factory MunicipalityIndex.fromJson(Map<String, Object?> json) {
    _checkSchema(json, 'municipalities.json');
    final regions = json['regions'];
    if (regions is! Map) {
      throw const HolidayBundleException('municipalities.json: no regions');
    }
    return MunicipalityIndex({
      for (final MapEntry(key: region, value: names) in regions.entries)
        region as String: [
          for (final MapEntry(key: code, value: name) in (names as Map).entries)
            Municipality(code as String, name as String, region),
        ]..sort((a, b) => a.code.compareTo(b.code)),
    });
  }

  final Map<String, List<Municipality>> _byRegion;

  /// Municipalities of [regionCode], by INE code.
  List<Municipality> inRegion(String regionCode) =>
      _byRegion[normalizeRegionCode(regionCode)] ?? const [];

  /// Municipalities of [regionCode] in alphabetical order of their names,
  /// accents ignored («Àger» next to «Agramunt», «Aiguafreda» before
  /// «Avinyó»). By INE code they come province by province, so a region of
  /// several provinces (Catalunya) restarts at «A» in each of them
  /// (H-T01-3). Displayed names are untouched.
  List<Municipality> inRegionByName(String regionCode) =>
      [...inRegion(regionCode)]..sort((a, b) => compareSpanish(a.name, b.name));

  int get length => _byRegion.values.fold(0, (n, l) => n + l.length);

  Municipality? byCode(String code) {
    final region = regionOfMunicipality(code);
    if (region == null) return null;
    for (final m in inRegion(region.code)) {
      if (m.code == code) return m;
    }
    return null;
  }
}

void _checkSchema(Map<String, Object?> json, String what) {
  if (json['schema'] != holidayBundleSchema) {
    throw HolidayBundleException('$what: unsupported schema ${json['schema']}');
  }
}

String _string(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is String && v.isNotEmpty) return v;
  throw HolidayBundleException('missing "$key"');
}

List<Map<String, Object?>> _list(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is! List) throw HolidayBundleException('missing "$key"');
  return v.cast<Map<String, Object?>>();
}

CivilDate _date(Map<String, Object?> row, int year) {
  final raw = _string(row, 'date');
  final CivilDate date;
  try {
    date = CivilDate.parse(raw);
  } on FormatException {
    throw HolidayBundleException('bad date "$raw"');
  }
  if (date.year != year) {
    throw HolidayBundleException('date $raw is not in $year');
  }
  return date;
}
