import 'package:collection/collection.dart';

import '../../schedule/domain/schedule_domain.dart';
import 'post_night.dart';

/// What the wizard asks for: apply [pattern] from [from] (to [until]
/// inclusive; `null` = no end), starting at cycle step [stepOffset]. With
/// [clearOverrides] the days changed by hand in the range are replaced.
class PatternRequest {
  const PatternRequest({
    required this.pattern,
    required this.from,
    this.until,
    this.stepOffset = 0,
    this.clearOverrides = false,
  });

  final Pattern pattern;
  final CivilDate from;
  final CivilDate? until;
  final int stepOffset;
  final bool clearOverrides;
}

/// The result of applying a [PatternRequest] to a schedule: the single
/// undoable [change] (new run, runs cut, overrides cleared, automatic
/// saliente) plus what has to exist for it to make sense.
class PatternApplication {
  const PatternApplication({
    required this.schedule,
    required this.change,
    required this.newTypes,
    required this.newPattern,
    required this.postNightDays,
  });

  /// The schedule after the change (with [newTypes] and [newPattern]).
  final Schedule schedule;
  final ScheduleChange change;

  /// Shift types that did not exist (a template type the user deleted, or
  /// the Saliente) and must be created for the change to make sense.
  final List<ShiftType> newTypes;

  /// The pattern, when it was not stored yet.
  final Pattern? newPattern;

  /// Days that became Saliente because of the night before.
  final Set<CivilDate> postNightDays;
}

/// Plans [request] on [schedule]. Pure: the preview of the wizard and the
/// controller use this same function, so what is shown is what is applied.
///
/// [seq] is the sequence of the new run (`ScheduleRepository.nextRunSeq()`
/// when it will be saved). With [postNightAuto] a work shift that ends the
/// next morning turns the next day into Saliente if it would be empty or
/// Libre ([palette] says whether the Saliente type is still offered; a
/// missing one is created, an archived one is respected).
PatternApplication planPatternApplication(
  Schedule schedule,
  PatternRequest request, {
  required int seq,
  bool postNightAuto = false,
  Iterable<ShiftType>? palette,
}) {
  final pattern = request.pattern;
  final newTypes = <ShiftType>[];
  final knownIds = {for (final t in schedule.shiftTypes) t.id};
  void ensureType(String id) {
    if (knownIds.contains(id)) return;
    final template = shiftTemplates.firstWhereOrNull((t) => t.key == id);
    if (template == null) return; // unknown id: the engine ignores it
    knownIds.add(id);
    newTypes.add(template.toShiftType(id));
  }

  for (final step in pattern.steps) {
    step.forEach(ensureType);
  }

  var autoSaliente = false;
  var createdSaliente = false;
  if (postNightAuto) {
    if (knownIds.contains(postNightTypeId)) {
      autoSaliente = palette?.any((t) => t.id == postNightTypeId) ?? true;
    } else {
      ensureType(postNightTypeId);
      createdSaliente = newTypes.any((t) => t.id == postNightTypeId);
      autoSaliente = true;
    }
  }

  final newPattern = schedule.patternById(pattern.id) == null ? pattern : null;
  final base = schedule.copyWith(
    shiftTypes: [...schedule.shiftTypes, ...newTypes],
    patterns: newPattern == null
        ? schedule.patterns
        : [...schedule.patterns, newPattern],
  );

  final applied = base.applyPattern(
    pattern.id,
    request.from,
    until: request.until,
    stepOffset: request.stepOffset,
    clearOverrides: request.clearOverrides,
    seq: seq,
  );
  var change = applied;
  var result = base.apply(applied);
  var saliente = <CivilDate>{};

  if (autoSaliente) {
    final last =
        request.until ?? request.from.addDays(postNightHorizonDays - 1);
    final sources = [
      for (var d = request.from; !d.isAfter(last); d = d.addDays(1)) d,
    ];
    saliente = postNightDays(result, sources);
    final extra = postNightPatch(result, sources);
    if (!extra.isEmpty) {
      change = ScheduleChange(
        patch: combinePatches(applied.patch, extra),
        runsBefore: applied.runsBefore,
        runsAfter: applied.runsAfter,
      );
      result = result.apply(ScheduleChange(patch: extra));
    } else if (createdSaliente) {
      // No saliente came out of it (a pattern without nights): do not add
      // the type to the palette for nothing.
      newTypes.removeWhere((t) => t.id == postNightTypeId);
      result = result.copyWith(
        shiftTypes: [
          for (final t in result.shiftTypes)
            if (t.id != postNightTypeId) t,
        ],
      );
    }
  }

  return PatternApplication(
    schedule: result,
    change: change,
    newTypes: newTypes,
    newPattern: newPattern,
    postNightDays: saliente,
  );
}
