import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';

import 'golden_dataset.dart';

final _created = DateTime.utc(2026, 1, 1, 8).millisecondsSinceEpoch;
final _updated = DateTime.utc(2026, 6, 15, 18, 30, 5).millisecondsSinceEpoch;

/// Exported by the build that wrote `golden_v2.cuadrante`.
final goldenV2ExportedAt = DateTime.utc(2026, 12, 1, 10, 30);

/// The reference dataset of format version 2 (`golden_v2.cuadrante`): the
/// version 1 data of `buildGoldenBackupData` plus
/// - a second calendar "Pareja" with its own rotations and days (its first
///   day falls on a date `main` also has an exception on),
/// - a third calendar, archived, that still holds a rotation,
/// - hourly rates on three shift types,
/// - the two calendar settings.
///
/// Fixed like the other one: no clock, no randomness.
BackupData buildGoldenBackupDataV2() {
  final base = buildGoldenBackupData();
  const rates = {'morning': 1250, 'night': 1575, 'custom-guard24': 2210};

  BackupShiftType rated(BackupShiftType t) => BackupShiftType(
    id: t.id,
    code: t.code,
    name: t.name,
    colorValue: t.colorValue,
    category: t.category,
    startMinute: t.startMinute,
    endMinute: t.endMinute,
    paidMinutes: t.paidMinutes,
    nightOverride: t.nightOverride,
    hourlyRateCents: rates[t.id],
    sortOrder: t.sortOrder,
    archived: t.archived,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
  );

  final calendars = [
    BackupCalendar(
      id: mainCalendarId,
      name: 'Hospital',
      colorValue: mainCalendarColor,
      sortOrder: 0,
      createdAt: _created,
      updatedAt: _updated,
    ),
    BackupCalendar(
      id: 'cal-pareja',
      name: 'Pareja',
      colorValue: 0xFFE5484D,
      sortOrder: 1,
      createdAt: _created + 5000,
      updatedAt: _updated + 5000,
    ),
    BackupCalendar(
      id: 'cal-old',
      name: 'Segundo trabajo (antiguo)',
      colorValue: 0xFF64748B,
      sortOrder: 2,
      archived: true,
      createdAt: _created + 6000,
      updatedAt: _updated + 6000,
    ),
  ];

  final runs = [
    ...base.patternRuns,
    BackupPatternRun(
      id: 'run-4',
      calendarId: 'cal-pareja',
      patternId: 'p-noches',
      startDate: const CivilDate(2026, 3, 2),
      stepOffset: 1,
      seq: 4,
      createdAt: _created + 23000,
    ),
    BackupPatternRun(
      id: 'run-5',
      calendarId: 'cal-pareja',
      patternId: 'p-mananas',
      startDate: const CivilDate(2027, 1, 4),
      endDate: const CivilDate(2027, 6, 30),
      seq: 5,
      createdAt: _created + 24000,
    ),
    BackupPatternRun(
      id: 'run-6',
      calendarId: 'cal-old',
      patternId: 'p-turnicidad',
      startDate: const CivilDate(2026, 2, 1),
      endDate: const CivilDate(2026, 4, 30),
      seq: 6,
      createdAt: _created + 25000,
    ),
  ];

  // 12 days of the second calendar, one every 23 days from 1 January 2026:
  // the first falls on a date `main` also has an exception on.
  final partnerEntries = <BackupDayEntry>[
    for (var i = 0; i < 12; i++)
      BackupDayEntry(
        calendarId: 'cal-pareja',
        date: goldenFrom.addDays(i * 23),
        shiftTypeIds: switch (i % 4) {
          0 => const ['rest'],
          1 => const ['morning', 'afternoon'],
          2 => const <String>[],
          _ => null,
        },
        // Every day has an override or a note (never an empty row).
        note: i % 3 == 0 || i % 4 == 3 ? 'Cena con la familia 🍝' : null,
        updatedAt: _updated + 900000 + i * 60000,
      ),
  ];

  return BackupData(
    calendars: calendars,
    shiftTypes: [for (final t in base.shiftTypes) rated(t)],
    patterns: base.patterns,
    patternRuns: runs,
    dayEntries: [...base.dayEntries, ...partnerEntries],
    holidays: base.holidays,
    absenceBalances: base.absenceBalances,
    settings: {
      ...base.settings,
      'calendars.active': '"cal-pareja"',
      'calendars.primary': '"main"',
    },
  );
}
