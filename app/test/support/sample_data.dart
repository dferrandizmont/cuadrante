import 'package:cuadrante/features/schedule/data/schedule_mappers.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';

/// Shift types that exercise every column: all categories, with and without
/// times, `paidMinutes`, `nightOverride` true / false / null, `hourlyRateCents`
/// set and not, an overnight and a 24 h shift, and an archived one.
const sampleShiftTypes = <ShiftTypeRecord>[
  ShiftTypeRecord(
    type: ShiftType(
      id: 'morning',
      code: 'M',
      name: 'Mañana',
      colorValue: 0xFFF5A524,
      category: ShiftCategory.work,
      startMinute: 360,
      endMinute: 840,
      hourlyRateCents: 1250,
    ),
    sortOrder: 0,
  ),
  ShiftTypeRecord(
    type: ShiftType(
      id: 'night',
      code: 'N',
      name: 'Noche',
      colorValue: 0xFF4B4FD1,
      category: ShiftCategory.work,
      startMinute: 1320,
      endMinute: 360,
      paidMinutes: 450,
      nightOverride: true,
    ),
    sortOrder: 1,
  ),
  ShiftTypeRecord(
    type: ShiftType(
      id: 'guard',
      code: 'G',
      name: 'Guardia 24 h',
      colorValue: 0xFFE5484D,
      category: ShiftCategory.work,
      startMinute: 480,
      endMinute: 480,
      nightOverride: false,
      hourlyRateCents: 2210,
    ),
    sortOrder: 2,
  ),
  ShiftTypeRecord(
    type: ShiftType(
      id: 'rest',
      code: 'L',
      name: 'Libre',
      colorValue: 0xFFE4E4E7,
      category: ShiftCategory.rest,
    ),
    sortOrder: 3,
  ),
  ShiftTypeRecord(
    type: ShiftType(
      id: 'vacation',
      code: 'V',
      name: 'Vacaciones',
      colorValue: 0xFF30A46C,
      category: ShiftCategory.absence,
    ),
    sortOrder: 4,
  ),
  ShiftTypeRecord(
    type: ShiftType(
      id: 'old',
      code: 'X',
      name: 'Turno antiguo',
      colorValue: 0xFF8E7CC3,
      category: ShiftCategory.work,
      startMinute: 0,
      endMinute: 1439,
    ),
    sortOrder: 5,
    archived: true,
  ),
];

/// Steps with several shifts in one day and an empty day.
const samplePatterns = <Pattern>[
  Pattern(
    id: 'cycle',
    name: 'Ciclo de prueba',
    steps: [
      ['morning'],
      ['morning', 'night'],
      [],
      ['rest'],
    ],
  ),
  Pattern(
    id: 'single',
    name: 'Un solo paso',
    steps: [
      ['guard'],
    ],
  ),
];

const _d = CivilDate(2026, 10, 19);

/// An open run, a bounded run and a bounded run with `stepOffset`.
final sampleRuns = <PatternRun>[
  PatternRun(
    id: 'run-1',
    patternId: 'cycle',
    startDate: _d.addDays(-30),
    seq: 1,
  ),
  PatternRun(
    id: 'run-2',
    patternId: 'single',
    startDate: _d.addDays(2),
    endDate: _d.addDays(9),
    seq: 2,
  ),
  PatternRun(
    id: 'run-3',
    patternId: 'cycle',
    startDate: _d.addDays(20),
    endDate: _d.addDays(34),
    stepOffset: 3,
    seq: 3,
  ),
];

/// Multi-shift day, `[]` (empty override), `null` + note (note only), override
/// with note, and an archived type in the past.
final sampleEntries = <CivilDate, DayEntry>{
  _d: DayEntry(date: _d, shiftTypeIds: const ['morning', 'night']),
  _d.addDays(1): DayEntry(date: _d.addDays(1), shiftTypeIds: const []),
  _d.addDays(2): DayEntry(date: _d.addDays(2), note: 'Cambio con Marta'),
  _d.addDays(3): DayEntry(
    date: _d.addDays(3),
    shiftTypeIds: const ['vacation'],
    note: 'Viaje a Cádiz',
  ),
  _d.addDays(-40): DayEntry(date: _d.addDays(-40), shiftTypeIds: const ['old']),
};
