import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';

import 'golden_dataset_v2.dart';

final _created = DateTime.utc(2026, 1, 1, 8).millisecondsSinceEpoch;
final _updated = DateTime.utc(2026, 6, 15, 18, 30, 5).millisecondsSinceEpoch;

/// Exported by the build that wrote `golden_v3.cuadrante`.
final goldenV3ExportedAt = DateTime.utc(2027, 1, 20, 8, 15);

/// The reference dataset of format version 3 (`golden_v3.cuadrante`): the
/// version 2 data of `buildGoldenBackupDataV2` plus
/// - icons on two shift types and an alarm sound on one,
/// - a split shift («turno partido») with its second segment,
/// - days with only a note reminder, only overtime or only early leave
///   (never an empty row), a day with all of them, and the same date holding
///   different values in two calendars.
///
/// Fixed like the other ones: no clock, no randomness.
BackupData buildGoldenBackupDataV3() {
  final base = buildGoldenBackupDataV2();

  BackupShiftType decorated(BackupShiftType t) => BackupShiftType(
    id: t.id,
    code: t.code,
    name: t.name,
    colorValue: t.colorValue,
    category: t.category,
    startMinute: t.startMinute,
    endMinute: t.endMinute,
    paidMinutes: t.paidMinutes,
    nightOverride: t.nightOverride,
    hourlyRateCents: t.hourlyRateCents,
    icon: switch (t.id) {
      'morning' => ShiftIcon.sunrise,
      'night' => ShiftIcon.moon,
      _ => null,
    },
    alarmSound: t.id == 'night'
        ? 'content://media/internal/audio/media/42'
        : null,
    sortOrder: t.sortOrder,
    archived: t.archived,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
  );

  final nextOrder =
      base.shiftTypes.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b) +
      1;
  final split = BackupShiftType(
    id: 'split',
    code: 'P',
    name: 'Partido',
    colorValue: 0xFF0EA5E9,
    category: ShiftCategory.work,
    // 08:00-12:00, then 16:00-20:00.
    startMinute: 8 * 60,
    endMinute: 12 * 60,
    segment2StartMinute: 16 * 60,
    segment2DurationMinutes: 4 * 60,
    icon: ShiftIcon.coffee,
    sortOrder: nextOrder,
    createdAt: _created + 9000,
    updatedAt: _updated + 9000,
  );

  // Days that only the version 3 can hold. None of these dates has an
  // exception in the version 2 data (the dataset test checks it).
  final extra = <BackupDayEntry>[
    BackupDayEntry(
      date: const CivilDate(2026, 3, 15),
      note: 'Llamar al banco 📞',
      noteReminderMinute: 9 * 60 + 30,
      updatedAt: _updated + 2000000,
    ),
    // Only a reminder: no note, no override.
    BackupDayEntry(
      date: const CivilDate(2026, 3, 11),
      noteReminderMinute: 7 * 60,
      updatedAt: _updated + 2060000,
    ),
    // Only overtime.
    BackupDayEntry(
      date: const CivilDate(2026, 3, 12),
      overtimeMinutes: 90,
      updatedAt: _updated + 2120000,
    ),
    // Only early leave.
    BackupDayEntry(
      date: const CivilDate(2026, 3, 13),
      earlyLeaveMinutes: 45,
      updatedAt: _updated + 2180000,
    ),
    // Everything on one day, with an override.
    BackupDayEntry(
      date: const CivilDate(2026, 3, 14),
      shiftTypeIds: const ['split'],
      note: 'Cambio con Marta\nTraer la llave 🔑',
      noteReminderMinute: 23 * 60 + 59,
      overtimeMinutes: 30,
      earlyLeaveMinutes: 15,
      updatedAt: _updated + 2240000,
    ),
    // Midnight is a valid reminder minute.
    BackupDayEntry(
      date: const CivilDate(2027, 2, 3),
      note: 'Medianoche',
      noteReminderMinute: 0,
      updatedAt: _updated + 2300000,
    ),
    // The same date, other values, in the second calendar.
    BackupDayEntry(
      calendarId: 'cal-pareja',
      date: const CivilDate(2026, 3, 12),
      overtimeMinutes: 15,
      earlyLeaveMinutes: 5,
      updatedAt: _updated + 2360000,
    ),
  ];

  return BackupData(
    calendars: base.calendars,
    shiftTypes: [for (final t in base.shiftTypes) decorated(t), split],
    patterns: base.patterns,
    patternRuns: base.patternRuns,
    dayEntries: [...base.dayEntries, ...extra],
    holidays: base.holidays,
    absenceBalances: base.absenceBalances,
    settings: base.settings,
  );
}
