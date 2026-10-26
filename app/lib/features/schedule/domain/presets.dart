import 'pattern.dart';
import 'shift_type.dart';

/// The names and codes of the shift templates and the names and
/// descriptions of the catalogue patterns in the app's language, by template
/// key and preset id. Anything missing keeps the Spanish text of the table.
///
/// The app sets [catalogTexts] from its ARB file (`catalog*` keys) before
/// seeding a new database and again on every language change. Only what is
/// **created** from then on takes these texts (the palette of a new install,
/// an automatic Saliente, a catalogue type a pattern needs): shift types and
/// patterns already stored are the user's data and are never renamed.
class CatalogTexts {
  const CatalogTexts({
    this.templates = const {},
    this.presets = const {},
    this.mainCalendarName,
  });

  /// Spanish: the texts of the tables themselves.
  static const CatalogTexts spanish = CatalogTexts();

  final Map<String, ({String name, String code})> templates;
  final Map<String, ({String name, String description})> presets;

  /// Name of the calendar a NEW install starts with («My roster»); `null`:
  /// the Spanish one. A calendar already stored is never renamed.
  final String? mainCalendarName;
}

/// See [CatalogTexts].
CatalogTexts catalogTexts = CatalogTexts.spanish;

/// Stable-keyed shift type template (palette of the spec, section 4).
class ShiftTemplate {
  const ShiftTemplate({
    required this.key,
    required String code,
    required String name,
    required this.colorValue,
    required this.category,
    this.startMinute,
    this.endMinute,
    this.segment2StartMinute,
    this.segment2DurationMinutes,
  }) : spanishCode = code,
       spanishName = name;

  final String key;

  /// The texts of the table; [code] and [name] give them in the app's
  /// language ([catalogTexts]).
  final String spanishCode;
  final String spanishName;

  String get code => catalogTexts.templates[key]?.code ?? spanishCode;
  String get name => catalogTexts.templates[key]?.name ?? spanishName;
  final int colorValue;
  final ShiftCategory category;
  final int? startMinute;
  final int? endMinute;

  /// Second segment of a split shift (A12), see [ShiftType].
  final int? segment2StartMinute;
  final int? segment2DurationMinutes;

  ShiftType toShiftType(String id) => ShiftType(
    id: id,
    code: code,
    name: name,
    colorValue: colorValue,
    category: category,
    startMinute: startMinute,
    endMinute: endMinute,
    segment2StartMinute: segment2StartMinute,
    segment2DurationMinutes: segment2DurationMinutes,
  );
}

const _h = 60;

const shiftTemplates = <ShiftTemplate>[
  ShiftTemplate(
    key: 'morning',
    code: 'M',
    name: 'Mañana',
    colorValue: 0xFFF5A524,
    category: ShiftCategory.work,
    startMinute: 6 * _h,
    endMinute: 14 * _h,
  ),
  ShiftTemplate(
    key: 'afternoon',
    code: 'T',
    name: 'Tarde',
    colorValue: 0xFFF06A3F,
    category: ShiftCategory.work,
    startMinute: 14 * _h,
    endMinute: 22 * _h,
  ),
  ShiftTemplate(
    key: 'night',
    code: 'N',
    name: 'Noche',
    colorValue: 0xFF4B4FD1,
    category: ShiftCategory.work,
    startMinute: 22 * _h,
    endMinute: 6 * _h,
  ),
  ShiftTemplate(
    key: 'rest',
    code: 'L',
    name: 'Libre',
    colorValue: 0xFFE4E4E7,
    category: ShiftCategory.rest,
  ),
  ShiftTemplate(
    key: 'guard24',
    code: 'G',
    name: 'Guardia 24 h',
    colorValue: 0xFFE5484D,
    category: ShiftCategory.work,
    startMinute: 8 * _h,
    endMinute: 8 * _h,
  ),
  ShiftTemplate(
    key: 'postNight',
    code: 'S',
    name: 'Saliente',
    colorValue: 0xFF8E7CC3,
    category: ShiftCategory.rest,
  ),
  ShiftTemplate(
    key: 'vacation',
    code: 'V',
    name: 'Vacaciones',
    colorValue: 0xFF30A46C,
    category: ShiftCategory.absence,
  ),
  ShiftTemplate(
    key: 'personalDay',
    code: 'LD',
    name: 'Libre disposición',
    colorValue: 0xFF12A594,
    category: ShiftCategory.absence,
  ),
  ShiftTemplate(
    key: 'day12',
    code: 'D',
    name: 'Día 12 h',
    colorValue: 0xFFF5A524,
    category: ShiftCategory.work,
    startMinute: 8 * _h,
    endMinute: 20 * _h,
  ),
  ShiftTemplate(
    key: 'night12',
    code: 'N12',
    name: 'Noche 12 h',
    colorValue: 0xFF4B4FD1,
    category: ShiftCategory.work,
    startMinute: 20 * _h,
    endMinute: 8 * _h,
  ),
];

/// «Partido 09–13 / 17–21» (A12): a split shift to start from in the shift
/// editor. It is **not** part of [shiftTemplates] on purpose: those are the
/// palette every new calendar starts with, and a split shift is something the
/// user asks for.
const splitShiftTemplate = ShiftTemplate(
  key: 'split',
  code: 'P',
  name: 'Partido',
  colorValue: 0xFF15AABF,
  category: ShiftCategory.work,
  startMinute: 9 * _h,
  endMinute: 13 * _h,
  segment2StartMinute: 17 * _h,
  segment2DurationMinutes: 4 * _h,
);

ShiftTemplate shiftTemplateByKey(String key) => key == splitShiftTemplate.key
    ? splitShiftTemplate
    : shiftTemplates.firstWhere((t) => t.key == key);

/// Ready-made rotation expressed in [ShiftTemplate] keys.
class PatternPreset {
  const PatternPreset({
    required this.id,
    required String name,
    required String description,
    required this.steps,
    this.suggestedStart,
  }) : spanishName = name,
       spanishDescription = description;

  final String id;

  /// The texts of the table; [name] and [description] give them in the
  /// app's language ([catalogTexts]).
  final String spanishName;
  final String spanishDescription;

  String get name => catalogTexts.presets[id]?.name ?? spanishName;
  String get description =>
      catalogTexts.presets[id]?.description ?? spanishDescription;

  /// One step per day, with template keys (never empty: days off are the
  /// explicit `rest` template).
  final List<List<String>> steps;

  /// Weekday the cycle should start on (1 = Monday ... 7 = Sunday), if any.
  final int? suggestedStart;

  int get lengthDays => steps.length;

  /// Template keys used by [steps].
  Set<String> get templateKeys => {for (final s in steps) ...s};

  /// Turns the keys into real ids; every used key must be in [shiftTypeIds].
  Pattern materialize(
    Map<String, String> shiftTypeIds, {
    String? id,
    String? name,
  }) => Pattern(
    id: id ?? this.id,
    name: name ?? this.name,
    steps: [
      for (final step in steps)
        [
          for (final key in step)
            shiftTypeIds[key] ??
                (throw ArgumentError.value(key, 'shiftTypeIds', 'missing key')),
        ],
    ],
  );
}

/// Compact cycle notation: letters from [_alias] with an optional repeat
/// count, e.g. `'M5 L2'` = five mornings and two rest days.
List<List<String>> _seq(String spec) => [
  for (final token in spec.split(' '))
    for (var i = 0; i < (int.tryParse(token.substring(1)) ?? 1); i++)
      [_alias[token[0]]!],
];

const _alias = {
  'M': 'morning',
  'T': 'afternoon',
  'N': 'night',
  'L': 'rest',
  'G': 'guard24',
  'S': 'postNight',
  'D': 'day12',
  'E': 'night12',
};

final patternPresets = <PatternPreset>[
  PatternPreset(
    id: 'correturnos',
    name: 'Correturnos',
    description: '5 mañanas, 2 libres, 5 tardes, 2 libres, 5 noches, 2 libres',
    steps: _seq('M5 L2 T5 L2 N5 L2'),
    suggestedStart: DateTime.monday,
  ),
  PatternPreset(
    id: '24x72',
    name: '24 x 72',
    description: 'Guardia de 24 h y 72 h libres',
    steps: _seq('G L3'),
  ),
  PatternPreset(
    id: '12h',
    name: '12 horas',
    description: 'Día 12 h, noche 12 h, saliente y libre',
    steps: _seq('D E S L'),
  ),
  PatternPreset(
    id: '6x4',
    name: '6 x 4',
    description: '6 mañanas y 4 libres',
    steps: _seq('M6 L4'),
  ),
  PatternPreset(
    id: '4x4',
    name: '4 x 4',
    description: '4 días de 12 h y 4 libres',
    steps: _seq('D4 L4'),
  ),
  PatternPreset(
    id: '5x2',
    name: '5 x 2',
    description: '5 mañanas y 2 libres (lunes a viernes)',
    steps: _seq('M5 L2'),
    suggestedStart: DateTime.monday,
  ),
  // The 14-day "2-2-3" rotation is the same one people also call
  // "2-2-3-2-2-3" (its two weeks written out: 2-2-3 / 2-2-3 mirrored) and
  // Pitman or Panamá: one preset, found under any of those names.
  PatternPreset(
    id: '2-2-3',
    name: '2-2-3',
    description:
        'Dos días de 12 h, dos libres, tres de 12 h, dos libres, '
        'dos de 12 h y tres libres (también 2-2-3-2-2-3)',
    steps: _seq('D2 L2 D3 L2 D2 L3'),
  ),
  // Continental: continuous cover with 4 crews (equipos) on 8 h M/T/N, a
  // 28-day cycle in which every crew works 7 mornings, 7 afternoons and 7
  // nights and rests 7 days. Blocks of 2-3 days, always forward (M, T, N)
  // so no one goes from N or T to M the next day; crews are offset 7 days
  // from each other. See docs/motor-de-turnos.md.
  PatternPreset(
    id: 'continental',
    name: 'Continental',
    description:
        'Turno continuo de 28 días con 4 equipos: bloques de 2 y 3 mañanas, '
        'tardes y noches, y 7 libres',
    steps: _seq('M2 T2 N3 L2 M2 T3 N2 L2 M3 T2 N2 L3'),
  ),
  // DuPont: 4 crews on 12 h shifts, 28 days: 4 nights, 3 off, 3 days, 1 off,
  // 3 nights, 3 off, 4 days, 7 off.
  PatternPreset(
    id: 'dupont',
    name: 'DuPont',
    description:
        'Ciclo de 28 días en turnos de 12 h: 4 noches, 3 libres, 3 días, '
        '1 libre, 3 noches, 3 libres, 4 días y 7 libres',
    steps: _seq('E4 L3 D3 L1 E3 L3 D4 L7'),
  ),
];

PatternPreset patternPresetById(String id) =>
    patternPresets.firstWhere((p) => p.id == id);
