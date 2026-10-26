import '../../schedule/domain/schedule_domain.dart';

/// Who a ready-made pattern is for: the sections of step 1 of the wizard.
enum PatternGroup { health, police, firefighters, industry, security }

/// Each preset under ONE group, so a card appears once. Order = display
/// order. (A preset not listed here still shows, under "Otros".)
const Map<PatternGroup, List<String>> patternGroupPresets = {
  PatternGroup.health: ['12h'],
  PatternGroup.police: ['6x4', '4x4'],
  PatternGroup.firefighters: ['24x72'],
  PatternGroup.industry: ['correturnos', 'continental', 'dupont', '5x2'],
  PatternGroup.security: ['2-2-3'],
};

/// Presets that belong to no group of [patternGroupPresets].
List<PatternPreset> ungroupedPresets() {
  final grouped = {for (final ids in patternGroupPresets.values) ...ids};
  return [
    for (final p in patternPresets)
      if (!grouped.contains(p.id)) p,
  ];
}

/// The shift type to draw for [id]: the stored one, or the template of the
/// same key (a pattern from the catalogue whose type is not created yet).
ShiftType? shiftTypeForDisplay(Schedule schedule, String id) {
  final stored = schedule.shiftTypeById(id);
  if (stored != null) return stored;
  for (final t in shiftTemplates) {
    if (t.key == id) return t.toShiftType(id);
  }
  return null;
}

/// Whether the first day of [steps] includes shift type [shiftTypeId].
bool startsWithShift(List<List<String>> steps, String shiftTypeId) =>
    steps.isNotEmpty && steps.first.contains(shiftTypeId);

/// Whether any day of [steps] includes shift type [shiftTypeId].
bool containsShift(List<List<String>> steps, String shiftTypeId) =>
    steps.any((step) => step.contains(shiftTypeId));

/// Pattern of the catalogue [preset], as stored when it already exists in
/// [schedule] (the same id) and built from its template keys otherwise.
Pattern presetPattern(Schedule schedule, PatternPreset preset) =>
    schedule.patternById(preset.id) ??
    preset.materialize({for (final k in preset.templateKeys) k: k});

/// Ids of the catalogue patterns (a stored pattern with one of these ids is
/// not "custom").
Set<String> get presetPatternIds => {for (final p in patternPresets) p.id};
