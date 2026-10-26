import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_callout.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../holidays/domain/spanish_regions.dart';
import '../../import/data/import_file_picker.dart';
import '../../import/presentation/import_icons.dart';
import '../../patterns/domain/pattern_catalog.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/onboarding_controller.dart';
import '../domain/profession.dart';
import 'onboarding_widgets.dart';

/// A round icon on a raised disc, above the text of the last two steps.
class _HeroDisc extends StatelessWidget {
  const _HeroDisc(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.xl),
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: Disc.xl,
            child: Icon(icon, size: IconSize.hero, color: colors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Step 4, «¿Vienes de otra app?»: a button opens the import (phone calendar,
/// `.ics` or CSV); the step can also be skipped with «Continuar».
class ImportStep extends ConsumerWidget {
  const ImportStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    Future<void> openImporter([ImportFileKind? kind]) async {
      var prepared = false;
      await saveSetting(context, () async {
        await ref
            .read(onboardingControllerProvider.notifier)
            .prepareFactoryCatalog();
        prepared = true;
      });
      if (prepared && context.mounted) {
        await context.push(AppRoutes.settingsImport, extra: kind);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroDisc(AppIcons.calendar),
        StepHeader(
          title: l10n.onboardingImportTitle,
          titleKey: const ValueKey('onboarding-title'),
          help: l10n.onboardingImportBody,
        ),
        const SizedBox(height: Sp.l),
        SecondaryButton(
          key: const ValueKey('onboarding-import'),
          icon: AppIcons.calendar,
          label: l10n.onboardingImportButton,
          onPressed: openImporter,
        ),
        const SizedBox(height: Sp.s),
        // The people who leave LRHSoft cannot use its paid calendar upload:
        // their way out is the backup file.
        SecondaryButton(
          key: const ValueKey('onboarding-import-lrhsoft'),
          icon: ImportIcons.backupFile,
          label: l10n.onboardingImportLrhsoftButton,
          onPressed: () => openImporter(ImportFileKind.lrhsoft),
        ),
      ],
    );
  }
}

/// Step 5, «Listo»: what was set up. The choices are already saved.
class ReadyStep extends ConsumerWidget {
  const ReadyStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final schedule = scheduleWithProfession(
      ref.watch(scheduleControllerProvider.select((s) => s.schedule)),
      state.profession,
    );

    // The day of the cycle the start day is, and what it gives ("Noche").
    var offset = 0;
    var startShifts = '';
    if (state.hasRotation) {
      final pattern = presetPattern(
        schedule,
        patternPresetById(state.presetId!),
      );
      offset = state.stepOffset % pattern.lengthDays;
      final names = [
        for (final id in pattern.steps[offset])
          ?shiftTypeForDisplay(schedule, id)?.name,
      ];
      startShifts = names.isEmpty ? l10n.calendarNoShift : names.join(' + ');
    }

    final lines = <String>[
      if (state.profession != null)
        l10n.onboardingReadyProfession(state.profession!.label(l10n)),
      if (state.regionCode != null)
        l10n.onboardingReadyPlace(
          [
            state.municipalityName,
            regionByCode(state.regionCode)?.name,
          ].whereType<String>().join(', '),
        ),
      if (state.hasRotation) ...[
        l10n.onboardingReadyRotation(
          patternPresetById(state.presetId!).name,
          format.weekdayDayMonth(
            DateTime(state.start.year, state.start.month, state.start.day),
          ),
        ),
        // Where in the cycle the start day falls (H-T01-5).
        l10n.onboardingReadyOffset(offset + 1, startShifts),
      ] else if (state.byHand)
        l10n.onboardingReadyByHand,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroDisc(AppIcons.check),
        StepHeader(
          title: l10n.onboardingReadyTitle,
          titleKey: const ValueKey('onboarding-title'),
          help: l10n.onboardingReadyBody,
        ),
        if (lines.isEmpty)
          Text(
            l10n.onboardingReadyNothing,
            key: const ValueKey('onboarding-summary-empty'),
            style: type.body,
          )
        else
          AppCard(
            key: const ValueKey('onboarding-summary'),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, line) in lines.indexed) ...[
                    if (i > 0) const SizedBox(height: Sp.s),
                    Text(line, style: type.body),
                  ],
                ],
              ),
            ),
          ),
        if (state.saveFailed)
          Padding(
            padding: const EdgeInsets.only(top: Sp.l),
            child: AppCallout(
              key: const ValueKey('onboarding-save-failed'),
              icon: AppIcons.error,
              title: l10n.onboardingReadySaveFailed,
            ),
          ),
      ],
    );
  }
}
