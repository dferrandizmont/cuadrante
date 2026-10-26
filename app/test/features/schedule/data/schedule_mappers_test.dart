import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/data/schedule_mappers.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/sample_data.dart';
import '../../../support/test_storage.dart';

/// Model -> companion -> database -> row -> model must give back the same
/// value for every column, including nulls.
void main() {
  late AppDatabase db;

  setUp(() => db = openMemoryDatabase());
  tearDown(() => db.close());

  const created = 1700000000000;
  const updated = 1700000005000;

  group('shift types', () {
    test('round trip, field by field', () async {
      for (final record in sampleShiftTypes) {
        await db
            .into(db.shiftTypes)
            .insert(record.toCompanion(createdAt: created, updatedAt: updated));
      }
      final rows = await db.select(db.shiftTypes).get();
      final back = {for (final r in rows) r.id: r.toRecord()};
      expect(back.length, sampleShiftTypes.length);
      for (final record in sampleShiftTypes) {
        expect(back[record.type.id], record, reason: record.type.id);
      }
    });

    test('keeps the timestamps and the null flags apart', () async {
      final night = sampleShiftTypes[1];
      await db
          .into(db.shiftTypes)
          .insert(night.toCompanion(createdAt: created, updatedAt: updated));
      final row = await db.select(db.shiftTypes).getSingle();
      expect(row.createdAt, created);
      expect(row.updatedAt, updated);
      expect(row.nightOverride, isTrue);
      expect(row.archived, isFalse);
      expect(row.category, ShiftCategory.work);
    });

    test('the hourly rate is whole cents, and optional', () async {
      for (final record in sampleShiftTypes) {
        await db
            .into(db.shiftTypes)
            .insert(record.toCompanion(createdAt: created, updatedAt: updated));
      }
      final rows = await db
          .customSelect('SELECT id, hourly_rate_cents AS r FROM shift_types')
          .get();
      final stored = {
        for (final r in rows) r.read<String>('id'): r.read<int?>('r'),
      };
      expect(stored['morning'], 1250);
      expect(stored['guard'], 2210);
      expect(stored['night'], isNull);
      expect(stored.values.where((v) => v != null), hasLength(2));
      final back = await (db.select(
        db.shiftTypes,
      )..where((t) => t.id.equals('morning'))).getSingle();
      expect(back.toRecord().type.hourlyRateCents, 1250);
    });

    test('category is stored as work / rest / absence text', () async {
      for (final record in sampleShiftTypes) {
        await db
            .into(db.shiftTypes)
            .insert(record.toCompanion(createdAt: created, updatedAt: updated));
      }
      final rows = await db
          .customSelect('SELECT DISTINCT category AS c FROM shift_types')
          .get();
      expect(
        {for (final r in rows) r.read<String>('c')},
        {'work', 'rest', 'absence'},
      );
    });
  });

  group('patterns', () {
    test('round trip keeps multi-shift and empty steps', () async {
      for (final p in samplePatterns) {
        await db
            .into(db.patterns)
            .insert(p.toCompanion(createdAt: created, updatedAt: updated));
      }
      final rows = await db.select(db.patterns).get();
      expect([for (final r in rows) r.toPattern()], samplePatterns);
    });

    test('steps are JSON text', () async {
      await db
          .into(db.patterns)
          .insert(
            samplePatterns.first.toCompanion(
              createdAt: created,
              updatedAt: updated,
            ),
          );
      final row = await db
          .customSelect('SELECT steps FROM patterns')
          .getSingle();
      expect(
        row.read<String>('steps'),
        '[["morning"],["morning","night"],[],["rest"]]',
      );
    });
  });

  group('runs', () {
    test('round trip with endDate, stepOffset and open runs', () async {
      for (final p in samplePatterns) {
        await db
            .into(db.patterns)
            .insert(p.toCompanion(createdAt: created, updatedAt: updated));
      }
      for (final r in sampleRuns) {
        await db
            .into(db.patternRuns)
            .insert(
              r.toCompanion(calendarId: mainCalendarId, createdAt: created),
            );
      }
      final rows = await (db.select(
        db.patternRuns,
      )..orderBy([(r) => OrderingTerm.asc(r.seq)])).get();
      final back = [for (final r in rows) r.toRun()];
      expect(back, sampleRuns);
      expect(back[0].endDate, isNull);
      expect(back[2].endDate, isNotNull);
      expect(back[2].stepOffset, 3);
    });

    test('dates are ISO text', () async {
      await db
          .into(db.patterns)
          .insert(
            samplePatterns.first.toCompanion(
              createdAt: created,
              updatedAt: updated,
            ),
          );
      await db
          .into(db.patternRuns)
          .insert(
            const PatternRun(
              id: 'r',
              patternId: 'cycle',
              startDate: CivilDate(2026, 3, 1),
              endDate: CivilDate(2026, 3, 31),
              seq: 1,
            ).toCompanion(calendarId: mainCalendarId, createdAt: created),
          );
      final row = await db
          .customSelect(
            'SELECT start_date AS s, end_date AS e FROM pattern_runs',
          )
          .getSingle();
      expect(row.read<String>('s'), '2026-03-01');
      expect(row.read<String>('e'), '2026-03-31');
    });
  });

  group('day entries', () {
    test('round trip: multi-shift, [] vs null override, notes', () async {
      for (final e in sampleEntries.values) {
        await db
            .into(db.dayEntries)
            .insert(
              e.toCompanion(calendarId: mainCalendarId, updatedAt: updated),
            );
      }
      final rows = await db.select(db.dayEntries).get();
      final back = {for (final r in rows) r.date: r.toEntry()};
      expect(back, sampleEntries);
    });

    test('NULL override and [] are different rows in the database', () async {
      final noteOnly = DayEntry(
        date: const CivilDate(2026, 10, 21),
        note: 'solo nota',
      );
      final empty = DayEntry(
        date: const CivilDate(2026, 10, 22),
        shiftTypeIds: const [],
      );
      for (final e in [noteOnly, empty]) {
        await db
            .into(db.dayEntries)
            .insert(
              e.toCompanion(calendarId: mainCalendarId, updatedAt: updated),
            );
      }
      final raw = await db
          .customSelect(
            'SELECT date, shift_type_ids FROM day_entries ORDER BY date',
          )
          .get();
      expect(raw[0].read<String?>('shift_type_ids'), isNull);
      expect(raw[1].read<String?>('shift_type_ids'), '[]');

      final rows = await (db.select(
        db.dayEntries,
      )..orderBy([(e) => OrderingTerm.asc(e.date)])).get();
      expect(rows[0].toEntry().shiftTypeIds, isNull);
      expect(rows[1].toEntry().shiftTypeIds, isEmpty);
      expect(rows[1].toEntry().shiftTypeIds, isNotNull);
    });

    test('overtime and early leave above 24 h read clamped to it, negatives '
        'as none', () {
      DayEntryRow row({int? overtime, int? early}) => DayEntryRow(
        calendarId: mainCalendarId,
        date: const CivilDate(2026, 10, 21),
        updatedAt: updated,
        overtimeMinutes: overtime,
        earlyLeaveMinutes: early,
      );
      final huge = row(
        overtime: 4611686018427387904,
        early: maxDayExtraMinutes + 1,
      ).toEntry();
      expect(huge.overtimeMinutes, maxDayExtraMinutes);
      expect(huge.earlyLeaveMinutes, maxDayExtraMinutes);
      final ok = row(overtime: 90, early: maxDayExtraMinutes).toEntry();
      expect(ok.overtimeMinutes, 90);
      expect(ok.earlyLeaveMinutes, maxDayExtraMinutes);
      final negative = row(overtime: -5, early: -1).toEntry();
      expect(negative.overtimeMinutes, isNull);
      expect(negative.earlyLeaveMinutes, isNull);
    });
  });
}
