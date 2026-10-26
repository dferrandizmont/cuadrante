import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/choice_row.dart';
import '../data/holiday_bundle_format.dart';
import '../domain/spanish_provinces.dart';
import '../domain/spanish_regions.dart';
import '../domain/text_fold.dart';
import 'holidays_icons.dart';
import 'holidays_settings_providers.dart';

/// What a picker sheet returns: the choice, wrapped, so «nothing» (the
/// person chose «Ninguno») is told apart from the sheet being dismissed
/// (`null`).
class HolidayPick<T> {
  const HolidayPick(this.value);

  final T value;
}

/// The 19 autonomous territories in alphabetical order of their names (accents
/// ignored): the order of [RegionPicker].
final List<SpanishRegion> alphabeticalRegions = [...spanishRegions]
  ..sort((a, b) => compareSpanish(a.name, b.name));

/// Which community: the 19 regions in alphabetical order, the current one
/// marked with a check. A plain list with no scrolling of its own, so a host
/// can put it in a sheet, a page or the onboarding step; tapping a row calls
/// [onSelected] with the region code.
///
/// With [clearLabel] the list starts with that extra option, which calls
/// [onSelected] with `null` («Sin comunidad»).
///
/// Row keys: `region-option-ES-CT`, `region-option-none`.
class RegionPicker extends StatelessWidget {
  const RegionPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.clearLabel,
  });

  /// Code of the current region (`ES-CT`), or null.
  final String? selected;
  final ValueChanged<String?> onSelected;

  /// Label of the «no region» option; null leaves the option out.
  final String? clearLabel;

  @override
  Widget build(BuildContext context) {
    final current = normalizeRegionCode(selected);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (clearLabel != null)
          PickerOptionRow(
            key: const ValueKey('region-option-none'),
            label: clearLabel!,
            selected: current == null,
            onTap: () => onSelected(null),
          ),
        for (final region in alphabeticalRegions)
          PickerOptionRow(
            key: ValueKey('region-option-${region.code}'),
            label: region.name,
            selected: region.code == current,
            onTap: () => onSelected(region.code),
          ),
      ],
    );
  }
}

/// Opens [RegionPicker] in a bottom sheet. Returns the choice wrapped in a
/// [HolidayPick] (its value is null for [clearLabel]), or null if the sheet
/// was dismissed.
Future<HolidayPick<String?>?> showRegionPicker(
  BuildContext context, {
  String? selected,
  String? clearLabel,

  /// Title of the sheet; «Comunidad autónoma» when null.
  String? title,
}) {
  return showAppSheet<HolidayPick<String?>>(
    context: context,
    padded: true,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PickerSheetTitle(title ?? ctx.l10n.holidaysSettingsRegionTitle),
        RegionPicker(
          selected: selected,
          clearLabel: clearLabel,
          onSelected: (code) => Navigator.pop(ctx, HolidayPick<String?>(code)),
        ),
      ],
    ),
  );
}

/// Which municipality of [regionCode]: a search field and the municipalities
/// of that region from the bundled INE index, alphabetical. The search
/// ignores accents and case («alcala» finds «Alcalá de Henares»). When a name
/// repeats inside the region, its province is shown under it. Tapping a row
/// calls [onSelected]; with [clearLabel] a first option («Ninguno») calls it
/// with `null`.
///
/// It reads the index from [municipalityIndexProvider] and fills the height
/// its parent gives it (the list scrolls), so give it a bounded height: a
/// sheet (see [showMunicipalityPicker]) or an `Expanded`.
///
/// Keys: `municipality-search`, `municipality-option-08019`,
/// `municipality-option-none`.
class MunicipalityPicker extends ConsumerStatefulWidget {
  const MunicipalityPicker({
    super.key,
    required this.regionCode,
    required this.selectedCode,
    required this.onSelected,
    this.clearLabel,
    this.autofocus = false,
  });

  /// Region whose municipalities are listed (`ES-CT`).
  final String regionCode;

  /// INE code of the current municipality, or null.
  final String? selectedCode;
  final ValueChanged<Municipality?> onSelected;

  /// Label of the «no municipality» option; null leaves the option out.
  final String? clearLabel;
  final bool autofocus;

  @override
  ConsumerState<MunicipalityPicker> createState() => _MunicipalityPickerState();
}

class _Item {
  _Item(this.municipality, this.province)
    : folded = foldSpanish(municipality.name);

  final Municipality municipality;
  final String folded;

  /// Shown only when the name repeats in the region.
  final String? province;
}

class _MunicipalityPickerState extends ConsumerState<MunicipalityPicker> {
  final _query = TextEditingController();

  // The items of the region, built once per index and region.
  List<Municipality>? _source;
  List<_Item> _items = const [];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<_Item> _itemsFor(MunicipalityIndex index) {
    final source = index.inRegion(widget.regionCode);
    if (!identical(source, _source)) {
      final sorted = [...source]
        ..sort((a, b) => compareSpanish(a.name, b.name));
      final counts = <String, int>{};
      for (final m in sorted) {
        counts.update(foldSpanish(m.name), (n) => n + 1, ifAbsent: () => 1);
      }
      _items = [
        for (final m in sorted)
          _Item(
            m,
            counts[foldSpanish(m.name)]! > 1
                ? provinceNameOfMunicipality(m.code)
                : null,
          ),
      ];
      _source = source;
    }
    return _items;
  }

  /// Names that start with the text first, then the ones that contain it.
  List<_Item> _filter(List<_Item> items, String text) {
    final q = foldSpanish(text.trim());
    if (q.isEmpty) return items;
    return [
      ...items.where((i) => i.folded.startsWith(q)),
      ...items.where((i) => !i.folded.startsWith(q) && i.folded.contains(q)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final index = ref.watch(municipalityIndexProvider);
    return index.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          _message(l10n.holidaysSettingsMunicipalityLoadFailed),
      data: (data) {
        if (data == null) {
          return _message(l10n.holidaysSettingsMunicipalityLoadFailed);
        }
        final items = _itemsFor(data);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s),
              child: TextField(
                key: const ValueKey('municipality-search'),
                controller: _query,
                autofocus: widget.autofocus,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.holidaysSettingsMunicipalitySearch,
                  prefixIcon: Icon(
                    HolidaysIcons.search,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _query,
                builder: (context, _) {
                  final shown = _filter(items, _query.text);
                  final withClear =
                      widget.clearLabel != null && _query.text.trim().isEmpty;
                  if (shown.isEmpty) {
                    return _message(
                      l10n.holidaysSettingsMunicipalityNoMatch(
                        _query.text.trim(),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: shown.length + (withClear ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (withClear && i == 0) {
                        return PickerOptionRow(
                          key: const ValueKey('municipality-option-none'),
                          label: widget.clearLabel!,
                          selected: widget.selectedCode == null,
                          onTap: () => widget.onSelected(null),
                        );
                      }
                      final item = shown[i - (withClear ? 1 : 0)];
                      final m = item.municipality;
                      return PickerOptionRow(
                        key: ValueKey('municipality-option-${m.code}'),
                        label: m.name,
                        subtitle: item.province,
                        selected: m.code == widget.selectedCode,
                        onTap: () => widget.onSelected(m),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Sp.l),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.type.body.copyWith(color: context.colors.textMuted),
      ),
    ),
  );
}

/// Opens [MunicipalityPicker] in a tall bottom sheet with its search field
/// focused. Returns the choice wrapped in a [HolidayPick] (null value for
/// [clearLabel]), or null if the sheet was dismissed.
Future<HolidayPick<Municipality?>?> showMunicipalityPicker(
  BuildContext context, {
  required String regionCode,
  String? selectedCode,
  String? clearLabel,
}) {
  return showAppSheet<HolidayPick<Municipality?>>(
    context: context,
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      final height =
          (media.size.height - media.padding.top - media.viewInsets.bottom) *
          0.9;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          Sp.page,
          0,
          Sp.page,
          media.viewInsets.bottom,
        ),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PickerSheetTitle(ctx.l10n.holidaysSettingsMunicipalityTitle),
              Expanded(
                child: MunicipalityPicker(
                  regionCode: regionCode,
                  selectedCode: selectedCode,
                  clearLabel: clearLabel,
                  autofocus: true,
                  onSelected: (m) =>
                      Navigator.pop(ctx, HolidayPick<Municipality?>(m)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Heading of a picker sheet.
class PickerSheetTitle extends StatelessWidget {
  const PickerSheetTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Sp.m),
    child: Semantics(
      header: true,
      child: Text(title, style: context.type.headline),
    ),
  );
}

/// One row of a picker: the same [ChoiceRow] as every other single-choice
/// sheet (the onboarding's included, H-T10-3), with an optional second line.
class PickerOptionRow extends StatelessWidget {
  const PickerOptionRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceRow(
    label: label,
    subtitle: subtitle,
    selected: selected,
    onTap: onTap,
  );
}
