import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/diagnostics/crash_reporting.dart';
import '../../../core/providers.dart';
import '../../calendars/application/calendars_controller.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendar/application/visible_month.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../patterns/domain/pattern_application.dart';
import '../../patterns/domain/pattern_catalog.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../domain/profession.dart';
import 'onboarding_providers.dart';

/// Where the person is in the first-use flow. [dot] is the dot of the
/// progress indicator: one per screen, so the number of «Paso N de M» is never
/// repeated (H-T01-9).
enum OnboardingStage {
  profession(0),
  place(1),
  rotation(2),
  start(3),
  importCalendar(4),
  ready(5);

  const OnboardingStage(this.dot);
  final int dot;

  /// Number of progress dots.
  static const int dots = 6;
}

/// What the person has chosen so far. Nothing is written until the end of
/// step 4 ([OnboardingController.finish]), so going back, changing their mind
/// or quitting half way leaves no half-made calendar behind.
class OnboardingState {
  const OnboardingState({
    required this.start,
    this.stage = OnboardingStage.profession,
    this.profession,
    this.regionCode,
    this.municipalityCode,
    this.municipalityName,
    this.presetId,
    this.byHand = false,
    this.stepOffset = 0,
    this.finishing = false,
    this.saveFailed = false,
  });

  final OnboardingStage stage;
  final Profession? profession;
  final String? regionCode;
  final String? municipalityCode;

  /// Name of [municipalityCode], to show it back.
  final String? municipalityName;

  /// Catalogue preset chosen in step 3.
  final String? presetId;

  /// "Lo pinto a mano": no rotation.
  final bool byHand;

  /// Day the rotation starts (today unless changed).
  final CivilDate start;

  /// Cycle step that falls on [start].
  final int stepOffset;

  /// The choices are being written.
  final bool finishing;

  /// Something of the writing failed (the rest was saved).
  final bool saveFailed;

  bool get hasRotation => presetId != null && !byHand;

  OnboardingState copyWith({
    OnboardingStage? stage,
    Profession? profession,
    bool clearProfession = false,
    String? regionCode,
    String? municipalityCode,
    String? municipalityName,
    bool clearPlace = false,
    bool clearMunicipality = false,
    String? presetId,
    bool? byHand,
    bool clearRotation = false,
    CivilDate? start,
    int? stepOffset,
    bool? finishing,
    bool? saveFailed,
  }) => OnboardingState(
    stage: stage ?? this.stage,
    profession: clearProfession ? null : profession ?? this.profession,
    regionCode: clearPlace ? null : regionCode ?? this.regionCode,
    municipalityCode: clearPlace || clearMunicipality
        ? null
        : municipalityCode ?? this.municipalityCode,
    municipalityName: clearPlace || clearMunicipality
        ? null
        : municipalityName ?? this.municipalityName,
    presetId: clearRotation ? null : presetId ?? this.presetId,
    byHand: clearRotation ? byHand ?? false : byHand ?? this.byHand,
    start: start ?? this.start,
    stepOffset: stepOffset ?? this.stepOffset,
    finishing: finishing ?? this.finishing,
    saveFailed: saveFailed ?? this.saveFailed,
  );
}

/// The first-use flow: profession, place, rotation, import, ready. Everything
/// it writes goes through the existing controllers and repositories
/// (`ScheduleController`, `HolidayController`, `OnboardingRepository`).
class OnboardingController extends Notifier<OnboardingState> {
  /// What the database held when the flow opened: [finish] writes nothing if
  /// the answer changed meanwhile (a backup was restored under the flow).
  Future<({bool done, bool data})>? _baseline;

  @override
  OnboardingState build() {
    final today = CivilDate.fromDateTime(ref.read(clockProvider)());
    _baseline = _probe();
    return OnboardingState(start: today);
  }

  Future<({bool done, bool data})> _probe() async {
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      return (
        done: await repository.isDone(),
        data: await repository.hasUserData(),
      );
    } catch (_) {
      // No readable database: nothing to protect.
      return (done: false, data: false);
    }
  }

  // ---- step 1: profession ---------------------------------------------------

  void selectProfession(Profession profession) {
    if (state.profession == profession) return;
    // The rotation shown depends on the profession: choose again.
    state = state.copyWith(profession: profession, clearRotation: true);
  }

  // ---- step 2: place --------------------------------------------------------

  void selectRegion(String? regionCode) {
    if (regionCode == state.regionCode) return;
    // A municipality belongs to one region.
    state = regionCode == null
        ? state.copyWith(clearPlace: true)
        : state.copyWith(regionCode: regionCode, clearMunicipality: true);
  }

  /// [name] is only for showing the choice back ("Listo").
  void selectMunicipality(String? municipalityCode, {String? name}) =>
      state = municipalityCode == null
      ? state.copyWith(clearMunicipality: true)
      : state.copyWith(
          municipalityCode: municipalityCode,
          municipalityName: name,
        );

  // ---- step 3: rotation -----------------------------------------------------

  void selectPreset(String presetId) =>
      state = state.copyWith(presetId: presetId, byHand: false, stepOffset: 0);

  /// "Lo pinto a mano": no rotation, on to the next step.
  void paintByHand() {
    state = state.copyWith(clearRotation: true, byHand: true);
    next();
  }

  void setStart(CivilDate date) => state = state.copyWith(start: date);

  void setStepOffset(int index) => state = state.copyWith(stepOffset: index);

  // ---- navigation -----------------------------------------------------------

  /// Whether the main button of the current stage has something to do.
  bool get canAdvance => switch (state.stage) {
    OnboardingStage.profession => state.profession != null,
    OnboardingStage.rotation => state.presetId != null || state.byHand,
    _ => true,
  };

  /// "Siguiente" / "Continuar". From the last question it writes the choices
  /// and lands on "Listo".
  Future<void> next() async {
    if (state.finishing || !canAdvance) return;
    switch (state.stage) {
      case OnboardingStage.profession:
        _go(OnboardingStage.place);
      case OnboardingStage.place:
        _go(OnboardingStage.rotation);
      case OnboardingStage.rotation:
        _go(
          state.hasRotation
              ? OnboardingStage.start
              : OnboardingStage.importCalendar,
        );
      case OnboardingStage.start:
        _go(OnboardingStage.importCalendar);
      case OnboardingStage.importCalendar:
        await finish();
      case OnboardingStage.ready:
        break;
    }
  }

  /// "Saltar": leaves this step without choosing anything in it.
  Future<void> skip() async {
    if (state.finishing) return;
    switch (state.stage) {
      case OnboardingStage.profession:
        state = state.copyWith(clearProfession: true, clearRotation: true);
        _go(OnboardingStage.place);
      case OnboardingStage.place:
        state = state.copyWith(clearPlace: true);
        _go(OnboardingStage.rotation);
      case OnboardingStage.rotation || OnboardingStage.start:
        state = state.copyWith(clearRotation: true);
        _go(OnboardingStage.importCalendar);
      case OnboardingStage.importCalendar:
        await finish();
      case OnboardingStage.ready:
        break;
    }
  }

  /// Back one step. Returns `false` when there is nowhere to go (the first
  /// step, or "Listo", whose choices are already saved).
  bool back() {
    if (state.finishing) return true;
    switch (state.stage) {
      case OnboardingStage.profession || OnboardingStage.ready:
        return false;
      case OnboardingStage.place:
        _go(OnboardingStage.profession);
      case OnboardingStage.rotation:
        _go(OnboardingStage.place);
      case OnboardingStage.start:
        _go(OnboardingStage.rotation);
      case OnboardingStage.importCalendar:
        _go(
          state.hasRotation ? OnboardingStage.start : OnboardingStage.rotation,
        );
    }
    return true;
  }

  void _go(OnboardingStage stage) => state = state.copyWith(stage: stage);

  // ---- result ---------------------------------------------------------------

  /// What the rotation would be: the chosen preset from [start].
  PatternRequest? request(Schedule schedule) {
    final id = state.presetId;
    if (id == null || state.byHand) return null;
    final pattern = presetPattern(schedule, patternPresetById(id));
    return PatternRequest(
      pattern: pattern,
      from: state.start,
      stepOffset: state.stepOffset % pattern.lengthDays,
    );
  }


  /// Accept provisional defaults in the chosen language before the importer
  /// can use them as the person's data. The provenance marker is consumed.
  Future<void> prepareFactoryCatalog() async {
    final schedule = ref.read(scheduleControllerProvider.notifier);
    await schedule.pendingWrites;
    if (await ref
        .read(onboardingRepositoryProvider)
        .finalizeFactoryCatalog(catalogTexts)) {
      await schedule.reload();
      ref.invalidate(calendarsControllerProvider);
    }
  }

  /// Writes the choices and goes to "Listo": the shift types of the
  /// profession (hours and order of the paint bar), the place for the
  /// holidays, the rotation as one pattern application, and the "done" flag.
  /// A part that fails is reported and does not stop the others.
  Future<void> finish() async {
    if (state.finishing) return;
    state = state.copyWith(finishing: true, saveFailed: false);
    final schedule = ref.read(scheduleControllerProvider.notifier);
    final repository = ref.read(onboardingRepositoryProvider);
    var failed = false;

    // Data that appeared while the flow was open (a restored backup) is
    // never overwritten by the choices made here: just close.
    final before = await (_baseline ?? _probe());
    final now = await _probe();
    if (!ref.mounted) return;
    final errorsBefore = ref.read(scheduleControllerProvider).saveErrors;

    Future<void> guarded(Future<void> Function() step) async {
      try {
        await step();
      } catch (error, stack) {
        failed = true;
        try {
          await ref
              .read(crashReporterProvider)
              .record(redactError(error), stack, fatal: false);
        } catch (_) {
          // A reporter that fails must not stop the flow.
        }
      }
    }

    await guarded(prepareFactoryCatalog);

    if ((now.done && !before.done) || (now.data && !before.data)) {
      state = state.copyWith(
        stage: OnboardingStage.ready,
        finishing: false,
        saveFailed: failed,
        clearProfession: true,
        clearPlace: true,
        clearRotation: true,
      );
      return;
    }

    final profession = state.profession;
    if (profession != null) {
      await guarded(() async {
        for (final type in professionShiftTypes(
          ref.read(scheduleControllerProvider).schedule,
          profession,
        )) {
          schedule.saveShiftType(type);
        }
        final palette = ref.read(scheduleControllerProvider).palette;
        final order = professionPaletteOrder(palette, profession);
        schedule.reorderShiftTypes(order);
        await repository.saveProfile(profession);
      });
    }

    if (state.regionCode != null) {
      await guarded(
        () => ref
            .read(holidayControllerProvider.notifier)
            .setPlace(
              regionCode: state.regionCode,
              municipalityCode: state.municipalityCode,
            ),
      );
    }

    final rotation = request(ref.read(scheduleControllerProvider).schedule);
    if (rotation != null) {
      await guarded(() async {
        await schedule.applyPatternRun(rotation);
        ref.read(visibleMonthProvider.notifier).goTo(rotation.from);
      });
    }

    // The shift types are queued writes: wait until they are in the database
    // (and see whether any failed) before saying the flow is done.
    await guarded(() async {
      await schedule.pendingWrites;
      if (ref.read(scheduleControllerProvider).saveErrors > errorsBefore) {
        failed = true;
      }
    });

    await guarded(() async {
      await repository.markDone(tip: true);
      ref.read(onboardingTipProvider.notifier).show();
    });
    if (!ref.mounted) return;
    state = state.copyWith(
      stage: OnboardingStage.ready,
      finishing: false,
      saveFailed: failed,
    );
  }
}

final onboardingControllerProvider =
    NotifierProvider.autoDispose<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );
