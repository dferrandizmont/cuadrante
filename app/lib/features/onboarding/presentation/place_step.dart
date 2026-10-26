import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/text_fold.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/choice_row.dart';
import '../../holidays/data/holiday_bundle_format.dart';
import '../../holidays/domain/spanish_regions.dart';
import '../../holidays/presentation/holiday_pickers.dart';
import '../application/onboarding_controller.dart';
import '../application/onboarding_providers.dart';
import 'onboarding_widgets.dart';

/// Step 2, «¿Dónde trabajas?»: the community (a list of 19) and, optionally,
/// the municipality (a search over the bundled index, filtered by region).
class PlaceStep extends ConsumerWidget {
  const PlaceStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final type = context.type;
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final region = regionByCode(state.regionCode);
    final municipality = state.municipalityCode;
    final missingLocal = municipality == null
        ? false
        : ref.watch(localHolidaysAvailableProvider(municipality)).value ==
              false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          title: l10n.onboardingPlaceTitle,
          titleKey: const ValueKey('onboarding-title'),
          help: l10n.onboardingPlaceHelp,
        ),
        ValueTile(
          key: const ValueKey('onboarding-region'),
          label: l10n.onboardingRegionLabel,
          placeholder: l10n.onboardingRegionPick,
          value: region?.name,
          onTap: () async {
            // The same sheet and list as Ajustes › Festivos (H-T10-3): the 19
            // in alphabetical order, the current one marked.
            final picked = await showRegionPicker(
              context,
              title: l10n.onboardingRegionSheetTitle,
              selected: region?.code,
            );
            final code = picked?.value;
            if (code != null) controller.selectRegion(code);
          },
        ),
        const SizedBox(height: Sp.card),
        ValueTile(
          key: const ValueKey('onboarding-municipality'),
          label: l10n.onboardingMunicipalityLabel,
          placeholder: region == null
              ? l10n.onboardingMunicipalityNeedsRegion
              : l10n.onboardingMunicipalityPick,
          value: state.municipalityName,
          onTap: region == null
              ? null
              : () async {
                  final picked = await showAppSheet<Municipality>(
                    context: context,
                    builder: (_) => MunicipalitySheet(regionCode: region.code),
                  );
                  if (picked != null) {
                    controller.selectMunicipality(
                      picked.code,
                      name: picked.name,
                    );
                  }
                },
          onClear: () => controller.selectMunicipality(null),
          clearTooltip: l10n.onboardingMunicipalityClear,
          clearKey: const ValueKey('onboarding-municipality-clear'),
        ),
        if (missingLocal)
          Padding(
            padding: const EdgeInsets.only(top: Sp.m),
            child: Text(
              l10n.onboardingLocalHolidaysMissing,
              key: const ValueKey('onboarding-local-missing'),
              style: type.body.copyWith(color: context.colors.textSecondary),
            ),
          ),
      ],
    );
  }
}

/// The search sheet over the municipalities of one region.
class MunicipalitySheet extends ConsumerStatefulWidget {
  const MunicipalitySheet({super.key, required this.regionCode});

  final String regionCode;

  @override
  ConsumerState<MunicipalitySheet> createState() => _MunicipalitySheetState();
}

class _MunicipalitySheetState extends ConsumerState<MunicipalitySheet> {
  final _controller = TextEditingController();
  List<(String, Municipality)>? _all;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<(String, Municipality)> _folded(MunicipalityIndex index) => _all ??= [
    for (final m in index.inRegionByName(widget.regionCode))
      (foldSpanish(m.name), m),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final media = MediaQuery.of(context);
    final index = ref.watch(municipalityIndexProvider).value;
    final height = math.max(
      280.0,
      media.size.height * 0.85 - media.viewInsets.bottom,
    );

    final folded = index == null
        ? const <(String, Municipality)>[]
        : _folded(index);
    final needle = foldSpanish(_query.trim());
    final matches = needle.isEmpty
        ? [for (final e in folded) e.$2]
        : [
            for (final e in folded)
              if (e.$1.startsWith(needle)) e.$2,
            for (final e in folded)
              if (!e.$1.startsWith(needle) && e.$1.contains(needle)) e.$2,
          ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.page, 0, Sp.page, Sp.m),
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.onboardingMunicipalitySheetTitle,
                    style: type.headline,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.page, 0, Sp.page, Sp.s),
                child: TextField(
                  key: const ValueKey('onboarding-municipality-search'),
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.onboardingMunicipalitySearch,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Expanded(
                child: matches.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(Sp.page),
                        child: Text(
                          index == null ? '' : l10n.onboardingMunicipalityNone,
                          style: type.body.copyWith(color: colors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (context, i) {
                          final m = matches[i];
                          // Same row as the community sheet, at the same x.
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Sp.page,
                            ),
                            child: ChoiceRow(
                              key: ValueKey('municipality-${m.code}'),
                              label: m.name,
                              onTap: () => Navigator.pop(context, m),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
