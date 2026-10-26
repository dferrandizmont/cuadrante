import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../settings/application/preferences_controller.dart';
import '../../settings/domain/preferences.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/onboarding_controller.dart';
import '../domain/profession.dart';
import 'onboarding_widgets.dart';

/// Step 1, «¿A qué te dedicas?».
class ProfessionStep extends ConsumerWidget {
  const ProfessionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(
      onboardingControllerProvider.select((s) => s.profession),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LanguagePicker(),
        const SizedBox(height: Sp.l),
        StepHeader(
          title: l10n.onboardingProfessionTitle,
          titleKey: const ValueKey('onboarding-title'),
          help: l10n.onboardingProfessionHelp,
        ),
        for (final profession in Profession.values)
          Padding(
            padding: const EdgeInsets.only(bottom: Sp.card),
            child: ChoiceTile(
              key: ValueKey('onboarding-profession-${profession.name}'),
              title: profession.label(l10n),
              subtitle: profession.hint(l10n),
              selected: selected == profession,
              onTap: () => controller.selectProfession(profession),
            ),
          ),
      ],
    );
  }
}

/// The app language is chosen before the provisional factory catalogue is
/// finalized. It is also the same persisted preference as in Settings.
class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(preferencesProvider.select((p) => p.language));
    String endonym(String code) => switch (code) {
      'ca' => l10n.languageNameCa,
      'gl' => l10n.languageNameGl,
      'eu' => l10n.languageNameEu,
      'en' => l10n.languageNameEn,
      _ => l10n.languageNameEs,
    };
    final system = resolveAppLocale(
      WidgetsBinding.instance.platformDispatcher.locales,
    );
    String name(AppLanguage language) => language == AppLanguage.system
        ? l10n.settingsLanguageSystem(endonym(system.languageCode))
        : endonym(language.name);
    return ValueTile(
      key: const ValueKey('onboarding-language'),
      label: l10n.settingsLanguageTitle,
      placeholder: l10n.settingsLanguageTitle,
      value: name(selected),
      onTap: () async {
        final picked = await showChoiceSheet<AppLanguage>(
          context: context,
          title: l10n.settingsLanguageTitle,
          selected: selected,
          options: [
            for (final language in AppLanguage.values)
              if (language == AppLanguage.system ||
                  appSupportedLocales.any(
                    (l) => l.languageCode == language.name,
                  ))
                ChoiceOption(language, name(language)),
          ],
        );
        if (picked != null && context.mounted) {
          await saveSetting(
            context,
            () => ref.read(preferencesProvider.notifier).setLanguage(picked),
          );
        }
      },
    );
  }
}
