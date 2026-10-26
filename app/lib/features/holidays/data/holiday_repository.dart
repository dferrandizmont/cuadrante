import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../schedule/domain/civil_date.dart';
import '../domain/holiday.dart';
import '../domain/holiday_entry.dart';
import '../domain/holiday_import.dart';
import '../domain/holiday_place.dart';
import '../domain/spanish_regions.dart';
import 'holiday_bundle_format.dart';
import 'holiday_bundle_loader.dart';
import 'holiday_snapshot.dart';

/// Settings keys (table `settings`, JSON values) of the holidays feature.
abstract final class HolidaySettings {
  static const region = 'holidays.region';
  static const municipality = 'holidays.municipality';
  static const bundleVersion = 'holidays.bundleVersion';
}

/// Exact rows written by one import. Only the repository can issue a receipt;
/// the opaque ids keep undo from deleting a later manual replacement.
class HolidayImportReceipt {
  HolidayImportReceipt._(this._database, Iterable<int> ids)
    : _ids = List.unmodifiable(ids);

  final AppDatabase _database;
  final List<int> _ids;

  int get count => _ids.length;
}

/// The holidays stored in the `holidays` table (docs/datos.md, festivos.md).
///
/// Rows come from three places: `bundled` (the copy shipped with the app,
/// replaced as a whole when `bundleVersion` changes), `remote` (the future
/// download) and `user` (added by hand; nothing else ever touches them).
class HolidayRepository {
  HolidayRepository(this._db);

  final AppDatabase _db;

  // ---- bundled rows -------------------------------------------------------

  /// Makes the bundled rows match [loader]'s bundle. Cheap when nothing
  /// changed: it reads only `manifest.json`, compares its `bundleVersion` with
  /// the stored one (setting `holidays.bundleVersion`) and stops. Otherwise it
  /// replaces every `bundled` row in one transaction; `user` and `remote`
  /// rows are never touched. Returns whether it refreshed.
  ///
  /// Throws [HolidayBundleException] (and writes nothing) if any file of the
  /// bundle fails its checksum.
  Future<bool> refreshBundled(
    HolidayBundleLoader loader, {
    bool force = false,
  }) async {
    final manifest = await loader.readManifest();
    if (!force &&
        await _readSetting(HolidaySettings.bundleVersion) ==
            manifest.bundleVersion &&
        await _hasBundledRows()) {
      return false;
    }
    final bundle = await loader.load(manifest: manifest);
    await _db.transaction(() async {
      await (_db.delete(
        _db.holidays,
      )..where((h) => h.source.equals(HolidaySource.bundled.name))).go();
      await _db.batch((batch) {
        batch.insertAll(_db.holidays, [
          for (final e in bundle.entries) _companion(e),
        ]);
      });
      await _writeSetting(
        HolidaySettings.bundleVersion,
        manifest.bundleVersion,
      );
    });
    return true;
  }

  Future<bool> _hasBundledRows() async {
    final count = _db.holidays.id.count();
    final row =
        await (_db.selectOnly(_db.holidays)
              ..addColumns([count])
              ..where(_db.holidays.source.equals(HolidaySource.bundled.name)))
            .getSingle();
    return row.read(count)! > 0;
  }

  HolidaysCompanion _companion(HolidayEntry e) => HolidaysCompanion.insert(
    date: e.date.toIso(),
    scope: e.scope.name,
    name: e.name,
    regionCode: Value(e.regionCode),
    municipalityCode: Value(e.municipalityCode),
    source: e.source.name,
  );

  // ---- place --------------------------------------------------------------

  Future<HolidayPlace> loadPlace() async {
    final region = normalizeRegionCode(
      await _readSetting(HolidaySettings.region),
    );
    final municipality = await _readSetting(HolidaySettings.municipality);
    return HolidayPlace(
      regionCode: region,
      municipalityCode: isMunicipalityCode(municipality) ? municipality : null,
    );
  }

  /// Stores the chosen region and municipality (null clears them). A
  /// municipality alone implies its region. Throws [ArgumentError] for codes
  /// that do not exist or a municipality outside the region.
  Future<HolidayPlace> savePlace({
    String? regionCode,
    String? municipalityCode,
  }) async {
    var region = normalizeRegionCode(regionCode);
    if (regionCode != null && region == null) {
      throw ArgumentError.value(regionCode, 'regionCode', 'unknown region');
    }
    if (municipalityCode != null) {
      final owner = regionOfMunicipality(municipalityCode);
      if (owner == null) {
        throw ArgumentError.value(
          municipalityCode,
          'municipalityCode',
          'not an INE municipality code',
        );
      }
      if (region != null && region != owner.code) {
        throw ArgumentError.value(
          municipalityCode,
          'municipalityCode',
          'is not in $region',
        );
      }
      region = owner.code;
    }
    await _db.transaction(() async {
      await _writeSetting(HolidaySettings.region, region);
      await _writeSetting(HolidaySettings.municipality, municipalityCode);
    });
    return HolidayPlace(regionCode: region, municipalityCode: municipalityCode);
  }

  // ---- reading ------------------------------------------------------------

  /// The rows that can apply to [place]: national, the region's national and
  /// regional ones, the municipality's local ones, and every user holiday.
  /// (`HolidayCalendar` applies the exact rules; this keeps the read small.)
  Future<List<HolidayEntry>> entriesFor(HolidayPlace place) async {
    final region = place.regionCode;
    final municipality = place.municipalityCode;
    final rows =
        await (_db.select(_db.holidays)
              ..where((h) {
                Expression<bool> any =
                    h.source.equals(HolidaySource.user.name) |
                    (h.scope.equals(HolidayScope.national.name) &
                        h.regionCode.isNull());
                if (region != null) {
                  any =
                      any |
                      (h.regionCode.equals(region) &
                          (h.scope.isIn([
                                HolidayScope.national.name,
                                HolidayScope.regional.name,
                              ]) |
                              (municipality == null
                                  ? const Constant(false)
                                  : h.scope.equals(HolidayScope.local.name) &
                                        h.municipalityCode.equals(
                                          municipality,
                                        ))));
                }
                return any;
              })
              ..orderBy([
                (h) => OrderingTerm.asc(h.date),
                (h) => OrderingTerm.asc(h.id),
              ]))
            .get();
    return [for (final row in rows) ?_entry(row)];
  }

  /// Every national holiday that some region keeps (`origin:
  /// national-optional` in the files), for all regions: what the holidays
  /// screen needs to say which replaceable national days the chosen region
  /// does not apply.
  Future<List<HolidayEntry>> regionalNationalEntries() async {
    final rows =
        await (_db.select(_db.holidays)
              ..where(
                (h) =>
                    h.scope.equals(HolidayScope.national.name) &
                    h.regionCode.isNotNull() &
                    h.source.equals(HolidaySource.user.name).not(),
              )
              ..orderBy([(h) => OrderingTerm.asc(h.date)]))
            .get();
    return [for (final row in rows) ?_entry(row)];
  }

  /// The place and its rows, read in one transaction.
  Future<HolidaySnapshot> loadSnapshot() => _db.transaction(() async {
    final place = await loadPlace();
    return HolidaySnapshot(place: place, entries: await entriesFor(place));
  });

  HolidayEntry? _entry(HolidayRow row) {
    final scope = HolidayScope.values.where((s) => s.name == row.scope);
    final source = HolidaySource.values.where((s) => s.name == row.source);
    if (scope.isEmpty || source.isEmpty) return null;
    try {
      return HolidayEntry(
        date: CivilDate.parse(row.date),
        scope: scope.first,
        name: row.name,
        regionCode: row.regionCode,
        municipalityCode: row.municipalityCode,
        source: source.first,
      );
    } on FormatException {
      return null;
    }
  }

  // ---- user holidays ------------------------------------------------------

  /// Adds the preview's new days without replacing anything. A fresh snapshot
  /// inside the transaction rechecks the current place and holidays, since
  /// either may have changed after the preview was built.
  Future<HolidayImportReceipt> importUserHolidays(
    Iterable<HolidayImportRow> rows,
  ) => _db.transaction(() async {
    final place = await loadPlace();
    final snapshot = HolidaySnapshot(
      place: place,
      entries: await entriesFor(place),
    );
    final occupied = snapshot.byDay.keys.toSet();
    final inserted = <int>[];
    for (final row in rows) {
      if (row.skipped || !occupied.add(row.date)) continue;
      final name = clipHolidayImportName(row.name);
      if (name.isEmpty) {
        throw ArgumentError.value(row.name, 'name', 'must not be empty');
      }
      inserted.add(
        await _db
            .into(_db.holidays)
            .insert(
              _companion(
                HolidayEntry(
                  date: row.date,
                  scope: HolidayScope.local,
                  name: name,
                  source: HolidaySource.user,
                ),
              ),
            ),
      );
    }
    return HolidayImportReceipt._(_db, inserted);
  });

  /// Removes only the rows this import inserted, never a replacement on the
  /// same date or an official row. Repeating undo is harmless.
  Future<void> undoImportedHolidays(HolidayImportReceipt receipt) async {
    if (!identical(receipt._database, _db)) {
      throw ArgumentError('Receipt belongs to another database');
    }
    await _db.transaction(() async {
      for (final id in receipt._ids) {
        await (_db.delete(_db.holidays)..where(
              (h) => h.id.equals(id) & h.source.equals(HolidaySource.user.name),
            ))
            .go();
      }
    });
  }

  /// A holiday the user adds by hand. It shows whatever region or
  /// municipality is chosen and wins over any official holiday of that day.
  /// One per day: adding on a day that has one replaces it.
  Future<void> addUserHoliday({
    required CivilDate date,
    required String name,
    HolidayScope scope = HolidayScope.local,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    await _db.transaction(() async {
      await _deleteUser(date);
      await _db
          .into(_db.holidays)
          .insert(
            _companion(
              HolidayEntry(
                date: date,
                scope: scope,
                name: trimmed,
                source: HolidaySource.user,
              ),
            ),
          );
    });
  }

  /// Removes the user's holiday of [date]; official ones stay.
  Future<void> removeUserHoliday(CivilDate date) => _deleteUser(date);

  Future<void> _deleteUser(CivilDate date) =>
      (_db.delete(_db.holidays)..where(
            (h) =>
                h.source.equals(HolidaySource.user.name) &
                h.date.equals(date.toIso()),
          ))
          .go();

  Future<List<HolidayEntry>> userHolidays() async {
    final rows =
        await (_db.select(_db.holidays)
              ..where((h) => h.source.equals(HolidaySource.user.name))
              ..orderBy([(h) => OrderingTerm.asc(h.date)]))
            .get();
    return [for (final row in rows) ?_entry(row)];
  }

  // ---- settings -----------------------------------------------------------

  Future<String?> _readSetting(String key) async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    if (row == null) return null;
    try {
      final value = jsonDecode(row.value);
      return value is String ? value : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> _writeSetting(String key, String? value) async {
    if (value == null) {
      await (_db.delete(_db.settings)..where((s) => s.key.equals(key))).go();
    } else {
      await _db
          .into(_db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: key, value: jsonEncode(value)),
          );
    }
  }
}
