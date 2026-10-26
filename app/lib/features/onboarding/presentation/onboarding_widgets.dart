import 'package:flutter/material.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/format/text_wrap.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/profession.dart';

/// Title and one line of help at the top of a step.
class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.title,
    required this.help,
    this.titleKey,
  });

  final String title;
  final String help;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, key: titleKey, style: type.headline),
          ),
          const SizedBox(height: Sp.s),
          Text(
            help,
            style: type.body.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// A choice among several: the selected one gets the ring border and a check
/// (never colour alone).
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return AppCard(
      onTap: onTap,
      borderColor: selected ? colors.todayRing : null,
      semanticLabel: subtitle == null ? title : '$title. $subtitle',
      selected: selected,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: type.bodyStrong),
                if (subtitle != null) ...[
                  const SizedBox(height: Sp.hair),
                  Text(subtitle!, style: type.meta),
                ],
              ],
            ),
          ),
          if (selected) ...[
            const SizedBox(width: Sp.s),
            Icon(AppIcons.check, color: colors.textPrimary),
          ],
        ],
      ),
    );
  }
}

/// A field that opens a picker: label, value (or [placeholder]) and a
/// chevron; [onClear] adds a close button when there is a value.
class ValueTile extends StatelessWidget {
  const ValueTile({
    super.key,
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.value,
    this.onClear,
    this.clearTooltip,
    this.clearKey,
  });

  final String label;
  final String placeholder;
  final String? value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final String? clearTooltip;
  final Key? clearKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final enabled = onTap != null;
    return AppCard(
      onTap: onTap,
      semanticLabel: '$label: ${value ?? placeholder}',
      padding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.m),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: type.meta),
                Text(
                  value ?? placeholder,
                  style: value == null
                      ? type.body.copyWith(color: colors.textMuted)
                      : type.bodyStrong,
                ),
              ],
            ),
          ),
          if (value != null && onClear != null)
            IconButton(
              key: clearKey,
              tooltip: clearTooltip,
              icon: Icon(AppIcons.close, color: colors.textSecondary),
              onPressed: onClear,
            )
          else if (enabled)
            Icon(AppIcons.chevronRight, color: colors.textMuted),
        ],
      ),
    );
  }
}

/// Small section label above a group of cards.
class GroupLabel extends StatelessWidget {
  const GroupLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Sp.section, bottom: Sp.s),
    child: Semantics(
      header: true,
      child: Text(
        label.toUpperCase(),
        style: context.type.label.copyWith(color: context.colors.textMuted),
      ),
    ),
  );
}

/// The names of a [Profession] in the app's language.
extension ProfessionText on Profession {
  String label(AppLocalizations l10n) => switch (this) {
    Profession.nursing => l10n.onboardingProfessionNursing,
    Profession.medicine => l10n.onboardingProfessionMedicine,
    Profession.police => l10n.onboardingProfessionPolice,
    Profession.firefighters => l10n.onboardingProfessionFirefighters,
    Profession.industry => l10n.onboardingProfessionIndustry,
    Profession.security => l10n.onboardingProfessionSecurity,
    Profession.hospitality => l10n.onboardingProfessionHospitality,
    Profession.other => l10n.onboardingProfessionOther,
  };

  /// The line under the name, with its time ranges unbreakable.
  String hint(AppLocalizations l10n) => keepTimeRangesTogether(_hint(l10n));

  String _hint(AppLocalizations l10n) => switch (this) {
    Profession.nursing => l10n.onboardingProfessionNursingHint,
    Profession.medicine => l10n.onboardingProfessionMedicineHint,
    Profession.police => l10n.onboardingProfessionPoliceHint,
    Profession.firefighters => l10n.onboardingProfessionFirefightersHint,
    Profession.industry => l10n.onboardingProfessionIndustryHint,
    Profession.security => l10n.onboardingProfessionSecurityHint,
    Profession.hospitality => l10n.onboardingProfessionHospitalityHint,
    Profession.other => l10n.onboardingProfessionOtherHint,
  };
}
