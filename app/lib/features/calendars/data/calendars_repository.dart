import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/calendar.dart';

/// Keys of the `settings` table (JSON text values) that say which calendar is
/// which.
abstract final class CalendarSettings {
  /// The calendar on screen.
  static const active = 'calendars.active';

  /// The calendar the widget and the alarms follow, whichever is on screen.
  static const primary = 'calendars.primary';
}

/// The calendars of the user and the two settings that point at them
/// (docs/datos.md, "Esquema v2").
///
/// Both settings default to `main` when absent, and a stored id that is
/// unknown or archived (a restored backup, a calendar archived elsewhere)
/// resolves to a calendar that exists, so the app never starts on a calendar
/// it cannot show.
class CalendarsRepository {
  CalendarsRepository(
    this._db, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? (() => 'cal-${const Uuid().v4()}');

  final AppDatabase _db;
  final DateTime Function() _now;
  final String Function() _newId;

  int get _nowMillis => _now().toUtc().millisecondsSinceEpoch;

  /// Calendars in `sort_order`; archived ones only with [includeArchived].
  Future<List<Calendar>> list({bool includeArchived = false}) async {
    final query = _db.select(_db.calendars)
      ..orderBy([
        (c) => OrderingTerm.asc(c.sortOrder),
        (c) => OrderingTerm.asc(c.id),
      ]);
    if (!includeArchived) query.where((c) => c.archived.equals(false));
    return [for (final row in await query.get()) row.toCalendar()];
  }

  Future<Calendar?> get(String id) async {
    final row = await (_db.select(
      _db.calendars,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row?.toCalendar();
  }

  /// Creates a calendar at the end of the list.
  ///
  /// Throws [ArgumentError] for a blank [name].
  Future<Calendar> create({
    required String name,
    required int colorValue,
  }) async {
    final trimmed = _validName(name);
    return _db.transaction(() async {
      final order = await _nextSortOrder();
      final now = _nowMillis;
      final calendar = Calendar(
        id: _newId(),
        name: trimmed,
        colorValue: colorValue,
        sortOrder: order,
      );
      await _db
          .into(_db.calendars)
          .insert(
            CalendarsCompanion.insert(
              id: calendar.id,
              name: calendar.name,
              colorValue: calendar.colorValue,
              sortOrder: calendar.sortOrder,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return calendar;
    });
  }

  /// Renames a calendar. Throws [CalendarNotFound] for an unknown id.
  Future<void> rename(String id, String name) async {
    await _update(id, CalendarsCompanion(name: Value(_validName(name))));
  }

  /// Changes the colour of a calendar. Throws [CalendarNotFound] for an
  /// unknown id.
  Future<void> recolor(String id, int colorValue) =>
      _update(id, CalendarsCompanion(colorValue: Value(colorValue)));

  /// "Deleting" a calendar: it leaves the lists but its rotations and days
  /// stay stored. If it was the active or the primary one, those settings
  /// move to the first calendar left.
  ///
  /// Throws [LastCalendarCannotBeArchived] when it is the only one that is
  /// not archived (the app always has a calendar) and [CalendarNotFound] for
  /// an unknown or already archived id.
  Future<void> archive(String id) => _db.transaction(() async {
    final target = await get(id);
    if (target == null || target.archived) throw CalendarNotFound(id);
    final remaining = [
      for (final c in await list())
        if (c.id != id) c,
    ];
    if (remaining.isEmpty) throw const LastCalendarCannotBeArchived();

    await (_db.update(_db.calendars)..where((c) => c.id.equals(id))).write(
      CalendarsCompanion(
        archived: const Value(true),
        updatedAt: Value(_nowMillis),
      ),
    );
    for (final key in [CalendarSettings.active, CalendarSettings.primary]) {
      if (await _readSetting(key) == id) {
        await _writeSetting(key, remaining.first.id);
      }
    }
  });

  /// The way back from [archive] (H-T07-1): the calendar is listed again,
  /// where its `sort_order` puts it, with all its rotations and days. The
  /// widget and alarms stay with the calendar that took them over.
  ///
  /// Throws [CalendarNotFound] for an unknown id. A calendar that is not
  /// archived is left as it is.
  Future<void> unarchive(String id) => _db.transaction(() async {
    final target = await get(id);
    if (target == null) throw CalendarNotFound(id);
    if (!target.archived) return;
    await (_db.update(_db.calendars)..where((c) => c.id.equals(id))).write(
      CalendarsCompanion(
        archived: const Value(false),
        updatedAt: Value(_nowMillis),
      ),
    );
  });

  /// The calendar on screen: `calendars.active` if it is a calendar that can
  /// be shown, else the primary one. Never throws for a bad stored value.
  Future<String> activeId() => _db.transaction(() async {
    final stored = await _readSetting(CalendarSettings.active);
    if (stored != null && await _isShowable(stored)) return stored;
    return primaryId();
  });

  /// The calendar the widget and the alarms follow: `calendars.primary` if
  /// it can be shown, else `main`, else the first calendar there is (a new
  /// `main` if the table is somehow empty).
  Future<String> primaryId() => _db.transaction(() async {
    final stored = await _readSetting(CalendarSettings.primary);
    if (stored != null && await _isShowable(stored)) return stored;
    if (await _isShowable(mainCalendarId)) return mainCalendarId;
    final all = await list();
    if (all.isNotEmpty) return all.first.id;
    await ensureMain();
    return mainCalendarId;
  });

  /// Makes [id] the calendar on screen. Throws [CalendarNotFound] if it does
  /// not exist or is archived.
  Future<void> setActive(String id) => _setSetting(CalendarSettings.active, id);

  /// Makes [id] the calendar the widget and the alarms follow. Throws
  /// [CalendarNotFound] if it does not exist or is archived.
  Future<void> setPrimary(String id) =>
      _setSetting(CalendarSettings.primary, id);

  /// Creates `main` when the table is empty (it never is after a normal
  /// open: the file is created, migrated or restored with a calendar). A
  /// safety net so the app cannot start without one.
  Future<void> ensureMain() => _db.transaction(() async {
    final count = _db.calendars.id.count();
    final row = await (_db.selectOnly(
      _db.calendars,
    )..addColumns([count])).getSingle();
    if (row.read(count) != 0) return;
    final now = _nowMillis;
    await _db
        .into(_db.calendars)
        .insert(
          CalendarsCompanion.insert(
            id: mainCalendarId,
            name: newMainCalendarName(),
            colorValue: mainCalendarColor,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );
  });

  // ---- internals ----------------------------------------------------------

  String _validName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'a calendar needs a name');
    }
    return trimmed;
  }

  Future<void> _update(String id, CalendarsCompanion fields) async {
    final changed =
        await (_db.update(_db.calendars)..where((c) => c.id.equals(id))).write(
          fields.copyWith(updatedAt: Value(_nowMillis)),
        );
    if (changed == 0) throw CalendarNotFound(id);
  }

  Future<int> _nextSortOrder() async {
    final max = _db.calendars.sortOrder.max();
    final row = await (_db.selectOnly(
      _db.calendars,
    )..addColumns([max])).getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  Future<bool> _isShowable(String id) async {
    final calendar = await get(id);
    return calendar != null && !calendar.archived;
  }

  Future<void> _setSetting(String key, String id) => _db.transaction(() async {
    if (!await _isShowable(id)) throw CalendarNotFound(id);
    await _writeSetting(key, id);
  });

  /// The stored id, or `null` when absent or not a JSON string.
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

  Future<void> _writeSetting(String key, String id) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: jsonEncode(id)),
      );
}

extension CalendarRowMapper on CalendarRow {
  Calendar toCalendar() => Calendar(
    id: id,
    name: name,
    colorValue: colorValue,
    sortOrder: sortOrder,
    archived: archived,
  );
}
