import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_body.dart';
import '../application/onboarding_controller.dart';
import 'import_ready_steps.dart';
import 'place_step.dart';
import 'profession_step.dart';
import 'rotation_step.dart';

/// First use (turnos-spec.md section 4, «Primer uso»): six full-screen steps
/// (the rotation and its start day are two), each skippable ("Saltar") and
/// reversible, ending on the month already painted. Nothing is written until
/// the import step is left.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  /// Below this height (landscape on a phone) the top bar scrolls with the
  /// step instead of staying fixed.
  static const double compactHeight = 480;

  /// From this text scale the top bar and «Siguiente» scroll with the step.
  static const double compactTextScale = 1.5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final stage = state.stage;
    final ready = stage == OnboardingStage.ready;

    final label = switch (stage) {
      OnboardingStage.importCalendar => l10n.onboardingContinue,
      OnboardingStage.ready => l10n.onboardingOpenCalendar,
      _ => l10n.onboardingNext,
    };

    // With big text or a short screen (landscape) the bar and the title
    // would take most of the screen and leave a card and a half of the list
    // (H-T01-6): the bar then scrolls away with the list. With big text
    // «Siguiente» goes with them, to the end of the content: fixed under the
    // list it would leave two bars and little else on a 320 dp phone.
    final media = MediaQuery.of(context);
    final bigText = media.textScaler.scale(14) / 14 >= compactTextScale - 0.001;
    final compact = media.size.height < compactHeight || bigText;

    final header = _Header(stage: stage, busy: state.finishing);
    final step = switch (stage) {
      OnboardingStage.profession => const ProfessionStep(),
      OnboardingStage.place => const PlaceStep(),
      OnboardingStage.rotation => const RotationStep(),
      OnboardingStage.start => const StartStep(),
      OnboardingStage.importCalendar => const ImportStep(),
      OnboardingStage.ready => const ReadyStep(),
    };
    const buttonPadding = EdgeInsets.fromLTRB(Sp.page, Sp.s, Sp.page, Sp.m);

    final next = Padding(
      padding: buttonPadding,
      child: PrimaryButton(
        key: const ValueKey('onboarding-next'),
        label: label,
        loading: state.finishing,
        onPressed: !controller.canAdvance
            ? null
            : ready
            ? () => context.go(AppRoutes.home)
            : controller.next,
      ),
    );

    return PopScope(
      // The first step leaves the app; "Listo" is already saved and ends.
      canPop: stage == OnboardingStage.profession,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (ready) {
          context.go(AppRoutes.home);
        } else {
          controller.back();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: PageBody(
            child: compact
                ? _compactBody(header, step, next, stage, nextInside: bigText)
                : _fixedBody(header, step, next, stage),
          ),
        ),
      ),
    );
  }

  /// The bar and the step scroll; «Siguiente» is under them, fixed.
  static Widget _fixedBody(
    Widget header,
    Widget step,
    Widget next,
    OnboardingStage stage, {
    bool barScrolls = false,
  }) => Column(
    children: [
      if (!barScrolls) header,
      Expanded(
        child: SingleChildScrollView(
          key: ValueKey('onboarding-${stage.name}'),
          padding: barScrolls ? EdgeInsets.zero : _stepPadding,
          child: barScrolls
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    Padding(padding: _stepPadding, child: step),
                  ],
                )
              : step,
        ),
      ),
      next,
    ],
  );

  static const EdgeInsets _stepPadding = EdgeInsets.fromLTRB(
    Sp.page,
    Sp.l,
    Sp.page,
    Sp.section,
  );

  /// The bar scrolls away with the step; with [nextInside] «Siguiente» does
  /// too, at the end of the content (or at the bottom of the screen when the
  /// step is short).
  static Widget _compactBody(
    Widget header,
    Widget step,
    Widget next,
    OnboardingStage stage, {
    required bool nextInside,
  }) {
    if (!nextInside) {
      return _fixedBody(header, step, next, stage, barScrolls: true);
    }
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        key: ValueKey('onboarding-${stage.name}'),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  Padding(padding: _stepPadding, child: step),
                ],
              ),
              next,
            ],
          ),
        ),
      ),
    );
  }
}

/// Back arrow, progress dots and «Saltar».
class _Header extends ConsumerWidget {
  const _Header({required this.stage, required this.busy});

  final OnboardingStage stage;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final canGoBack =
        stage != OnboardingStage.profession && stage != OnboardingStage.ready;
    final ready = stage == OnboardingStage.ready;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.xs, Sp.xs, Sp.xs, 0),
      child: Row(
        children: [
          SizedBox(
            width: Sp.touch + Sp.s,
            child: canGoBack
                ? IconButton(
                    key: const ValueKey('onboarding-back'),
                    tooltip: l10n.back,
                    icon: Icon(AppIcons.back),
                    onPressed: busy ? null : controller.back,
                  )
                : null,
          ),
          // The dots yield space (they scale down) before «Saltar» does.
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Semantics(
                label: l10n.onboardingProgress(
                  stage.dot + 1,
                  OnboardingStage.dots,
                ),
                excludeSemantics: true,
                child: Row(
                  key: const ValueKey('onboarding-dots'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < OnboardingStage.dots; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
                        // The current step is a longer dash, so it is not
                        // told by colour alone.
                        child: AnimatedContainer(
                          duration: Motion.of(context, Motion.state),
                          width: i == stage.dot ? Sp.xl : Sp.s,
                          height: Sp.s,
                          decoration: BoxDecoration(
                            color: i <= stage.dot
                                ? colors.accent
                                : colors.borderStrong,
                            borderRadius: Rad.pill,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Its own width, never squeezed: one line at any width and scale.
          ready
              ? const SizedBox(width: Sp.touch + Sp.s)
              : ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: Sp.touch + Sp.s),
                  child: TextButton(
                    key: const ValueKey('onboarding-skip'),
                    onPressed: busy ? null : controller.skip,
                    child: Text(
                      l10n.onboardingSkip,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
