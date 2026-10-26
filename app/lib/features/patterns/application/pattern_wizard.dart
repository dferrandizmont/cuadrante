import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../domain/pattern_application.dart';
import '../domain/pattern_catalog.dart';
import 'post_night_provider.dart';

/// How the wizard is opened: the start day (the one long-pressed in paint
/// mode, else today) and the shift whose typical patterns go first.
typedef PatternWizardArgs = ({CivilDate? start, String? shiftId});

/// Steps of the wizard.
enum WizardStep { choose, start, end }

/// What the user has decided so far. The pattern is chosen in step 1 (a
/// catalogue preset, a pattern they saved before, or one built here), the
/// day in step 2 and the end in step 3.
class PatternWizardState {
  const PatternWizardState({
    required this.start,
    this.step = WizardStep.choose,
    this.presetId,
    this.customId,
    this.building = false,
    this.draft = const [],
    this.draftName = '',
    this.sameDay = false,
    this.stepOffset = 0,
    this.until,
    this.clearOverrides = false,
    this.applying = false,
  });

  final WizardStep step;
  final CivilDate start;

  /// Catalogue preset chosen.
  final String? presetId;

  /// Pattern saved earlier chosen.
  final String? customId;

  /// "Crear el mío": the sequence builder is open and [draft] is the choice.
  final bool building;

  /// The sequence being built: one list of shift type ids per day.
  final List<List<String>> draft;
  final String draftName;

  /// The builder adds the next shift to the last day instead of a new day.
  final bool sameDay;

  /// Cycle step that falls on [start].
  final int stepOffset;

  /// Last day, or `null` = no end.
  final CivilDate? until;

  /// Replace the days changed by hand in the range (off = respect them).
  final bool clearOverrides;
  final bool applying;

  bool get hasChoice =>
      building ? draft.isNotEmpty : presetId != null || customId != null;

  PatternWizardState copyWith({
    WizardStep? step,
    CivilDate? start,
    String? presetId,
    String? customId,
    bool clearChoice = false,
    bool? building,
    List<List<String>>? draft,
    String? draftName,
    bool? sameDay,
    int? stepOffset,
    CivilDate? until,
    bool clearUntil = false,
    bool? clearOverrides,
    bool? applying,
  }) => PatternWizardState(
    step: step ?? this.step,
    start: start ?? this.start,
    // With [clearChoice] the given ids replace the choice (null = none).
    presetId: clearChoice ? presetId : presetId ?? this.presetId,
    customId: clearChoice ? customId : customId ?? this.customId,
    building: building ?? this.building,
    draft: draft ?? this.draft,
    draftName: draftName ?? this.draftName,
    sameDay: sameDay ?? this.sameDay,
    stepOffset: stepOffset ?? this.stepOffset,
    until: clearUntil ? null : until ?? this.until,
    clearOverrides: clearOverrides ?? this.clearOverrides,
    applying: applying ?? this.applying,
  );
}

class PatternWizardController extends Notifier<PatternWizardState> {
  PatternWizardController(this.args);

  final PatternWizardArgs args;

  // Id the pattern gets if the user builds it here.
  final String _draftId = 'custom-${const Uuid().v4()}';

  @override
  PatternWizardState build() {
    final today = CivilDate.fromDateTime(ref.read(clockProvider)());
    return PatternWizardState(start: args.start ?? today);
  }

  // ---- step 1: the pattern ------------------------------------------------

  void selectPreset(String presetId) => state = state.copyWith(
    clearChoice: true,
    presetId: presetId,
    building: false,
    stepOffset: 0,
  );

  void selectCustom(String patternId) => state = state.copyWith(
    clearChoice: true,
    customId: patternId,
    building: false,
    stepOffset: 0,
  );

  void startBuilding() =>
      state = state.copyWith(clearChoice: true, building: true, stepOffset: 0);

  void stopBuilding() => state = state.copyWith(building: false);

  void setSameDay(bool value) => state = state.copyWith(sameDay: value);

  /// A tap on a shift of the builder: a new day, or (with [sameDay]) one
  /// more shift on the last day.
  void appendShift(String shiftTypeId) {
    final draft = [for (final s in state.draft) List<String>.of(s)];
    if (state.sameDay && draft.isNotEmpty) {
      if (!draft.last.contains(shiftTypeId)) draft.last.add(shiftTypeId);
    } else {
      draft.add([shiftTypeId]);
    }
    state = state.copyWith(draft: draft, stepOffset: 0);
  }

  /// Takes back the last tap: the last shift of the last day, and the day
  /// when it was the only one.
  void removeLast() {
    if (state.draft.isEmpty) return;
    final draft = [for (final s in state.draft) List<String>.of(s)];
    if (draft.last.length > 1) {
      draft.last.removeLast();
    } else {
      draft.removeLast();
    }
    state = state.copyWith(draft: draft, stepOffset: 0);
  }

  void clearDraft() => state = state.copyWith(draft: const [], stepOffset: 0);

  void setName(String name) => state = state.copyWith(draftName: name);

  // ---- step 2: the start --------------------------------------------------

  void setStart(CivilDate date) => state = state.copyWith(
    start: date,
    // An end before the start is no end at all.
    clearUntil: state.until != null && state.until!.isBefore(date),
  );

  void setStepOffset(int index) => state = state.copyWith(stepOffset: index);

  // ---- step 3: the end ----------------------------------------------------

  void setEndless() => state = state.copyWith(clearUntil: true);

  void setUntil(CivilDate date) => state = state.copyWith(
    until: date.isBefore(state.start) ? state.start : date,
  );

  void setClearOverrides(bool value) =>
      state = state.copyWith(clearOverrides: value);

  // ---- navigation ---------------------------------------------------------

  void next() {
    if (state.step == WizardStep.choose && !state.hasChoice) return;
    if (state.step == WizardStep.end) return;
    state = state.copyWith(step: WizardStep.values[state.step.index + 1]);
  }

  void back() {
    if (state.step == WizardStep.choose) return;
    state = state.copyWith(step: WizardStep.values[state.step.index - 1]);
  }

  void setApplying(bool value) => state = state.copyWith(applying: value);

  // ---- result -------------------------------------------------------------

  /// The chosen pattern, or `null` while there is none. A built one is named
  /// [fallbackName] when the user left the name empty.
  Pattern? chosenPattern(Schedule schedule, {String fallbackName = ''}) {
    final s = state;
    if (s.building) {
      if (s.draft.isEmpty) return null;
      final name = s.draftName.trim();
      return Pattern(
        id: _draftId,
        name: name.isEmpty ? fallbackName : name,
        steps: [for (final step in s.draft) List<String>.of(step)],
      );
    }
    if (s.presetId != null) {
      return presetPattern(schedule, patternPresetById(s.presetId!));
    }
    if (s.customId != null) return schedule.patternById(s.customId!);
    return null;
  }

  /// What the wizard would apply now, or `null` without a chosen pattern.
  PatternRequest? request(Schedule schedule, {String fallbackName = ''}) {
    final pattern = chosenPattern(schedule, fallbackName: fallbackName);
    if (pattern == null) return null;
    return PatternRequest(
      pattern: pattern,
      from: state.start,
      until: state.until,
      stepOffset: state.stepOffset % pattern.lengthDays,
      clearOverrides: state.clearOverrides,
    );
  }

  /// Applies the pattern ([ScheduleController.applyPatternRun]: one undoable
  /// step). Returns that step (for `undoIfLast`), or `null` when nothing was
  /// applied.
  Future<ScheduleChange?> apply({String fallbackName = ''}) async {
    if (state.applying) return null;
    final controller = ref.read(scheduleControllerProvider.notifier);
    final request = this.request(
      ref.read(scheduleControllerProvider).schedule,
      fallbackName: fallbackName,
    );
    if (request == null) return null;
    state = state.copyWith(applying: true);
    try {
      return await controller.applyPatternRun(request);
    } finally {
      if (ref.mounted) state = state.copyWith(applying: false);
    }
  }
}

final patternWizardProvider = NotifierProvider.autoDispose
    .family<PatternWizardController, PatternWizardState, PatternWizardArgs>(
      PatternWizardController.new,
    );

/// What applying the wizard's choices now would do (the live preview), or
/// `null` while no pattern is chosen. Same planner as the real application.
final patternPreviewProvider = Provider.autoDispose
    .family<PatternApplication?, PatternWizardArgs>((ref, args) {
      // Watched so the preview follows every choice of the wizard.
      ref.watch(patternWizardProvider(args));
      final controller = ref.read(patternWizardProvider(args).notifier);
      final schedule = ref.watch(
        scheduleControllerProvider.select((s) => s.schedule),
      );
      final palette = ref.watch(
        scheduleControllerProvider.select((s) => s.palette),
      );
      final auto = ref.watch(postNightAutoProvider);
      final request = controller.request(schedule);
      if (request == null) return null;
      return planPatternApplication(
        schedule,
        request,
        seq: schedule.runs.fold(0, (m, r) => r.seq > m ? r.seq : m) + 1,
        postNightAuto: auto,
        palette: palette,
      );
    });
