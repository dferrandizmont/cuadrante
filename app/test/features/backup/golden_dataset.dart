import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';

/// The reference dataset of the restore matrix (docs/plan-publicacion.md,
/// "Matriz de restauración"): two years, three rotations (one cut), 40
/// exceptions, double-shift days, a shift that crosses midnight, custom types
/// (one archived), long notes with emojis and line breaks, a chosen
/// municipality, alarm settings and a user holiday.
///
/// Everything is fixed (no clock, no randomness): the same call always
/// returns equal data, and the checked-in `golden_v1.cuadrante` was made from
/// it. Regenerate the fixture with
/// `flutter test test/features/backup/golden_fixture_test.dart
/// --dart-define=REGENERATE_GOLDEN=true`, and only when the format is
/// deliberately versioned: old fixtures must keep being read.
const goldenAppVersion = '1.0.0';
final goldenExportedAt = DateTime.utc(2026, 11, 10, 9);

/// The 730 days the dataset spans (2026 and 2027).
const goldenFrom = CivilDate(2026, 1, 1);
const goldenTo = CivilDate(2027, 12, 31);

final _created = DateTime.utc(2026, 1, 1, 8).millisecondsSinceEpoch;
final _updated = DateTime.utc(2026, 6, 15, 18, 30, 5).millisecondsSinceEpoch;

/// A note with everything that has broken text handling somewhere: emojis
/// (also ZWJ sequences and flags), CR LF and LF, tabs, quotes, backslashes,
/// markup, U+2028, combining marks, accents and CJK.
const goldenLongNote =
    'Cambio de turno con María 🙏\n'
    'Llevar el informe 📄 y la llave 🔑\r\n'
    'Familia: 👨‍👩‍👧‍👦  Bandera: 🇪🇸\tTab\n'
    'Comillas "dobles" y \'simples\', barra \\ y </script> & <b>\n'
    'Separador de línea, é combinada, ñ, 日本語, ½ €\n'
    '\n'
    'Última línea tras un salto doble ✅';

BackupData buildGoldenBackupData() {
  BackupShiftType type(
    String id,
    String code,
    String name,
    int color,
    ShiftCategory category,
    int order, {
    int? start,
    int? end,
    int? paid,
    bool? night,
    bool archived = false,
  }) => BackupShiftType(
    id: id,
    code: code,
    name: name,
    colorValue: color,
    category: category,
    startMinute: start,
    endMinute: end,
    paidMinutes: paid,
    nightOverride: night,
    sortOrder: order,
    archived: archived,
    createdAt: _created + order * 1000,
    updatedAt: _updated + order * 1000,
  );

  const work = ShiftCategory.work;
  final types = [
    type('morning', 'M', 'Mañana', 0xFFF5A524, work, 0, start: 360, end: 840),
    type('afternoon', 'T', 'Tarde', 0xFFF06A3F, work, 1, start: 840, end: 1320),
    // Crosses midnight: 22:00 -> 06:00.
    type('night', 'N', 'Noche', 0xFF4B4FD1, work, 2, start: 1320, end: 360),
    type('rest', 'L', 'Libre', 0xFFE4E4E7, ShiftCategory.rest, 3),
    type('post-night', 'S', 'Saliente', 0xFFB8B8C2, ShiftCategory.rest, 4),
    type('vacation', 'V', 'Vacaciones', 0xFF2BB673, ShiftCategory.absence, 5),
    // Custom types.
    type(
      'custom-guard24',
      'G',
      'Guardia 24 h',
      0xFFE5484D,
      work,
      6,
      start: 480,
      end: 480,
    ),
    type(
      'custom-support',
      'R',
      'Refuerzo de tarde',
      0xFF0EA5E9,
      work,
      7,
      start: 1020,
      end: 1290,
      paid: 240,
      night: false,
    ),
    type(
      'custom-flex',
      'F',
      'Flexible',
      0xFF8B5CF6,
      work,
      8,
      paid: 420,
      night: true,
    ),
    // "Deleted" by the user: archived, past days still show it.
    type(
      'custom-old',
      'X',
      'Turno antiguo',
      0xFF64748B,
      work,
      9,
      start: 540,
      end: 1020,
      archived: true,
    ),
  ];

  // Deliberately not in id order: patterns keep their insertion order.
  final patterns = [
    BackupPattern(
      id: 'p-turnicidad',
      name: 'Turnicidad 8 días',
      steps: const [
        ['morning'],
        ['morning'],
        ['afternoon'],
        ['afternoon'],
        ['night'],
        ['night'],
        ['post-night'],
        ['rest'],
      ],
      createdAt: _created + 10000,
      updatedAt: _updated + 10000,
    ),
    BackupPattern(
      id: 'p-mananas',
      name: 'Mañanas de lunes a viernes',
      steps: const [
        ['morning'],
        ['morning'],
        ['morning'],
        ['morning'],
        ['morning'],
        [],
        [],
      ],
      createdAt: _created + 11000,
      updatedAt: _updated + 11000,
    ),
    BackupPattern(
      id: 'p-noches',
      name: 'Noches 4x3',
      steps: const [
        ['night'],
        ['night'],
        ['night'],
        ['night'],
        ['rest'],
        ['rest'],
        ['rest'],
      ],
      createdAt: _created + 12000,
      updatedAt: _updated + 12000,
    ),
  ];

  // Three rotations; the first one was cut when the second started.
  final runs = [
    BackupPatternRun(
      id: 'run-1',
      patternId: 'p-turnicidad',
      startDate: const CivilDate(2026, 1, 1),
      endDate: const CivilDate(2026, 9, 14),
      seq: 1,
      createdAt: _created + 20000,
    ),
    BackupPatternRun(
      id: 'run-2',
      patternId: 'p-mananas',
      startDate: const CivilDate(2026, 9, 15),
      stepOffset: 3,
      seq: 2,
      createdAt: _created + 21000,
    ),
    // Overlaps run-2 and wins over it (higher seq).
    BackupPatternRun(
      id: 'run-3',
      patternId: 'p-noches',
      startDate: const CivilDate(2027, 2, 1),
      endDate: const CivilDate(2027, 3, 31),
      stepOffset: 2,
      seq: 3,
      createdAt: _created + 22000,
    ),
  ];

  // 40 exceptions, one every 17 days, eight kinds in turn.
  final entries = <BackupDayEntry>[];
  for (var i = 0; i < 40; i++) {
    final date = goldenFrom.addDays(i * 17);
    final (ids, note) = switch (i % 8) {
      0 => (<String>['night'], null),
      // Double shift.
      1 => (<String>['morning', 'afternoon'], 'Doble turno 💪'),
      // Empty day over the pattern.
      2 => (<String>[], null),
      // Note only: does not replace the pattern.
      3 => (null, goldenLongNote),
      4 => (<String>['vacation'], 'Vacaciones 🏖️\nVuelta el lunes'),
      5 => (<String>['custom-guard24'], null),
      // Midnight-crossing shift with a note.
      6 => (<String>['night'], 'Noche de Reyes 👑\r\nCuidado: "hielo" ❄️'),
      _ => (<String>['custom-old', 'custom-support'], null),
    };
    entries.add(
      BackupDayEntry(
        date: date,
        shiftTypeIds: ids,
        note: note,
        updatedAt: _updated + i * 60000,
      ),
    );
  }

  return BackupData(
    // What reading a version 1 file gives: `main`, stamped with the export
    // time (`BackupData.fromJsonV1`).
    calendars: [
      BackupCalendar.defaultMain(
        createdAt: goldenExportedAt.millisecondsSinceEpoch,
        updatedAt: goldenExportedAt.millisecondsSinceEpoch,
      ),
    ],
    shiftTypes: types,
    patterns: patterns,
    patternRuns: runs,
    dayEntries: entries,
    holidays: const [
      BackupHoliday(
        date: CivilDate(2026, 9, 8),
        scope: 'local',
        name: 'Fiesta del barrio 🎆',
        regionCode: 'ES-VC',
        municipalityCode: '46250',
      ),
    ],
    absenceBalances: const [
      BackupAbsenceBalance(year: 2026, type: 'vacation', allowedDays: 22),
      BackupAbsenceBalance(year: 2026, type: 'personal', allowedDays: 6),
      BackupAbsenceBalance(year: 2027, type: 'vacation', allowedDays: 22.5),
    ],
    settings: const {
      'holidays.region': '"ES-VC"',
      'holidays.municipality': '"46250"',
      'night.window': '{"endMinute":360,"startMinute":1320}',
      'alarms':
          '{"enabled":true,"leadMinutes":45,"shifts":["morning","night"]}',
    },
  );
}
