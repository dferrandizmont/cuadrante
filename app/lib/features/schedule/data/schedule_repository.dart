import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/diagnostics/debug_log.dart';
import '../../shift_types/domain/shift_type_draft.dart';
import '../domain/schedule_domain.dart';
import 'schedule_mappers.dart';
import 'schedule_snapshot.dart';

/// The only way the app reads and writes the schedule (docs/datos.md).
///
/// Days and runs are only ever written by [apply]; undo is
/// `apply(change.inverse())`.
class ScheduleRepository {
  ScheduleRepository(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  int get _nowMillis => _now().toUtc().millisecondsSinceEpoch;

  /// Runs [action] in one database transaction (nested calls join it).
  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  /// Whether no shift type has ever been stored (a brand new database).
  Future<bool> isEmpty() async {
    final count = _db.shiftTypes.id.count();
    final row = await (_db.selectOnly(
      _db.shiftTypes,
    )..addColumns([count])).getSingle();
    return row.read(count) == 0;
  }

  /// Everything the app needs to show calendar [calendarId], read in one
  /// transaction: shift types and patterns (common to all calendars; the
  /// archived types too, in `sort_order`), and that calendar's runs by `seq`
  /// and day entries. An unknown calendar loads as empty.
  Future<ScheduleSnapshot> load(String calendarId) => _db.transaction(() async {
    final typeRows =
        await (_db.select(_db.shiftTypes)..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.id),
            ]))
            .get();
    // Insertion order (rowid): patterns have no sort column.
    final patternRows =
        await (_db.select(_db.patterns)..orderBy([
              (_) => OrderingTerm.asc(const CustomExpression<int>('rowid')),
            ]))
            .get();
    final runRows =
        await (_db.select(_db.patternRuns)
              ..where((r) => r.calendarId.equals(calendarId))
              ..orderBy([(r) => OrderingTerm.asc(r.seq)]))
            .get();
    final entryRows = await (_db.select(
      _db.dayEntries,
    )..where((e) => e.calendarId.equals(calendarId))).get();

    final records = [for (final row in typeRows) row.toRecord()];
    final schedule = Schedule(
      shiftTypes: [for (final r in records) r.type],
      patterns: [for (final row in patternRows) row.toPattern()],
      runs: [for (final row in runRows) row.toRun()],
      entries: {for (final row in entryRows) row.date: row.toEntry()},
    );
    return ScheduleSnapshot(
      schedule: schedule,
      palette: [
        for (final r in records)
          if (!r.archived) r.type,
      ],
      calendarId: calendarId,
    );
  });

  /// The `seq` a new run should take: one above the highest of **any**
  /// calendar (`seq` is unique across the whole table, docs/datos.md), so
  /// two calendars never collide.
  Future<int> nextRunSeq() async {
    final max = _db.patternRuns.seq.max();
    final row = await (_db.selectOnly(
      _db.patternRuns,
    )..addColumns([max])).getSingle();
    return (row.read(max) ?? 0) + 1;
  }

  /// Applies [change] to calendar [calendarId] in **one transaction**. For
  /// each day of the patch the row is deleted when `after` is null (or has
  /// nothing to store) and upserted otherwise; when `runsAfter` is set, the
  /// runs **of that calendar** end up equal to it. Nothing outside
  /// [calendarId] is ever touched, and nothing is written if anything fails
  /// (an unknown calendar fails on the foreign key; a run id that already
  /// belongs to another calendar is refused).
  Future<void> apply(
    String calendarId,
    ScheduleChange change,
  ) => _db.transaction(() async {
    final now = _nowMillis;
    // Only the ids a change ADDS to a day must exist: a day that already
    // carried an unknown id (old data, which the engine ignores) can still be
    // edited, while a change that would bring a deleted type back is refused.
    final referencedIds = {
      for (final entry in change.patch.changes.values)
        ...?entry.after?.shiftTypeIds?.where(
          (id) => !(entry.before?.shiftTypeIds?.contains(id) ?? false),
        ),
    };
    if (referencedIds.isNotEmpty) {
      final storedIds =
          await (_db.selectOnly(_db.shiftTypes)
                ..addColumns([_db.shiftTypes.id])
                ..where(_db.shiftTypes.id.isIn(referencedIds)))
              .map((row) => row.read(_db.shiftTypes.id)!)
              .get();
      if (!storedIds.toSet().containsAll(referencedIds)) {
        throw StateError('Day entries reference an unknown shift type');
      }
    }

    for (final MapEntry(key: date, value: entryChange)
        in change.patch.changes.entries) {
      final after = entryChange.after;
      if (after == null || after.isEmpty) {
        await (_db.delete(_db.dayEntries)..where(
              (e) => e.calendarId.equals(calendarId) & e.date.equalsValue(date),
            ))
            .go();
      } else {
        await _db
            .into(_db.dayEntries)
            .insertOnConflictUpdate(
              after.toCompanion(calendarId: calendarId, updatedAt: now),
            );
      }
    }

    final runs = change.runsAfter;
    if (runs != null) {
      final keep = [for (final r in runs) r.id];
      await (_db.delete(_db.patternRuns)..where(
            (r) =>
                r.calendarId.equals(calendarId) &
                (keep.isEmpty ? const Constant(true) : r.id.isNotIn(keep)),
          ))
          .go();
      for (final run in runs) {
        final owner =
            await (_db.selectOnly(_db.patternRuns)
                  ..addColumns([_db.patternRuns.calendarId])
                  ..where(_db.patternRuns.id.equals(run.id)))
                .map((row) => row.read(_db.patternRuns.calendarId))
                .getSingleOrNull();
        if (owner != null && owner != calendarId) {
          throw StateError(
            'Run "${run.id}" belongs to calendar "$owner", not '
            '"$calendarId"',
          );
        }
        final insert = run.toCompanion(calendarId: calendarId, createdAt: now);
        await _db
            .into(_db.patternRuns)
            .insert(
              insert,
              // Keep the original creation time of an existing run.
              onConflict: DoUpdate(
                (_) => insert.copyWith(createdAt: const Value.absent()),
              ),
            );
      }
    }
  });

  /// Creates or updates a shift type. A new one goes last in the palette
  /// unless [sortOrder] says otherwise; an existing one keeps its position,
  /// its archived flag and its creation time. A second segment that does not
  /// fit after the first one in 24 h (`checkSegment2`) is refused with an
  /// [ArgumentError] before anything is written.
  Future<void> saveShiftType(ShiftType type, {int? sortOrder}) =>
      _db.transaction(() async {
        final problem = type.segment2Problem;
        if (problem != null) {
          throw ArgumentError.value(
            type,
            'type',
            'invalid second segment: ${problem.name}',
          );
        }
        final now = _nowMillis;
        final existing = await (_db.select(
          _db.shiftTypes,
        )..where((t) => t.id.equals(type.id))).getSingleOrNull();
        if (existing == null) {
          final order = sortOrder ?? await _nextSortOrder();
          await _db
              .into(_db.shiftTypes)
              .insert(
                ShiftTypeRecord(
                  type: type,
                  sortOrder: order,
                ).toCompanion(createdAt: now, updatedAt: now),
              );
          return;
        }
        final fields = ShiftTypeRecord(
          type: type,
          sortOrder: sortOrder ?? existing.sortOrder,
          archived: existing.archived,
        ).toCompanion(createdAt: existing.createdAt, updatedAt: now);
        await (_db.update(
          _db.shiftTypes,
        )..where((t) => t.id.equals(type.id))).write(fields);
      });

  /// One-time repair at start-up: a build before the code limit counted
  /// UTF-16 units let codes such as two emojis (4 units) into the database,
  /// and the backup export (and the safety copy of every restore) refuses
  /// them for ever. Any stored code that is empty or longer than
  /// [maxShiftCodeLength] units is cut to its first whole characters that
  /// fit (`'?'` when none does) and logged. Valid codes are not touched, and
  /// neither is `updated_at`. Returns how many rows it repaired.
  Future<int> repairShiftTypeCodes() => _db.transaction(() async {
    final rows = await _db.select(_db.shiftTypes).get();
    var repaired = 0;
    for (final row in rows) {
      if (row.code.isNotEmpty && row.code.length <= maxShiftCodeLength) {
        continue;
      }
      final fixed = fitShiftCode(row.code);
      // Never the code or the id: user text must not reach logcat.
      debugLog(
        'Tipos de turno: un código de ${row.code.length} unidades no es '
        'válido; reparado',
      );
      await (_db.update(_db.shiftTypes)..where((t) => t.id.equals(row.id)))
          .write(ShiftTypesCompanion(code: Value(fixed)));
      repaired++;
    }
    return repaired;
  });

  /// "Deleting" a shift type: it leaves the palette but past days still show
  /// it. Unknown ids are ignored.
  Future<void> archiveShiftType(String id) =>
      (_db.update(_db.shiftTypes)..where((t) => t.id.equals(id))).write(
        ShiftTypesCompanion(
          archived: const Value(true),
          updatedAt: Value(_nowMillis),
        ),
      );

  /// The way back from [archiveShiftType] (H-T05-3): the shift type returns
  /// to the palette, at the position its `sort_order` still holds. Unknown
  /// ids are ignored.
  Future<void> unarchiveShiftType(String id) =>
      (_db.update(_db.shiftTypes)..where((t) => t.id.equals(id))).write(
        ShiftTypesCompanion(
          archived: const Value(false),
          updatedAt: Value(_nowMillis),
        ),
      );

  /// Deletes the shift type [id] when nothing uses it: no day of **any**
  /// calendar and no rotation. Returns whether it was deleted (`false` when
  /// something still uses it, or when there is no such type).
  ///
  /// The shift types are shared by every calendar, so a day of another
  /// calendar can use one; the check looks at every day, not only at the
  /// calendar being edited.
  Future<bool> deleteShiftTypeIfUnused(String id) => _db.transaction(() async {
    final entries = await _db.select(_db.dayEntries).get();
    for (final entry in entries) {
      if (entry.shiftTypeIds?.contains(id) ?? false) return false;
    }
    final patterns = await _db.select(_db.patterns).get();
    for (final pattern in patterns) {
      if (pattern.steps.any((step) => step.contains(id))) return false;
    }
    final deleted = await (_db.delete(
      _db.shiftTypes,
    )..where((t) => t.id.equals(id))).go();
    return deleted > 0;
  });

  /// Creates or updates a pattern (keeps its creation time and position).
  Future<void> savePattern(Pattern pattern) async {
    if (pattern.steps.isEmpty) {
      throw ArgumentError.value(pattern, 'pattern', 'needs at least one step');
    }
    final now = _nowMillis;
    final insert = pattern.toCompanion(createdAt: now, updatedAt: now);
    await _db
        .into(_db.patterns)
        .insert(
          insert,
          onConflict: DoUpdate(
            (_) => insert.copyWith(createdAt: const Value.absent()),
          ),
        );
  }

  Future<int> _nextSortOrder() async {
    final max = _db.shiftTypes.sortOrder.max();
    final row = await (_db.selectOnly(
      _db.shiftTypes,
    )..addColumns([max])).getSingle();
    return (row.read(max) ?? -1) + 1;
  }
}
