import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/format/text_measure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/page_body.dart';
import '../../schedule/domain/civil_date.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/holidays_provider.dart';
import '../data/holiday_snapshot.dart';
import '../data/holiday_repository.dart';
import '../domain/holiday.dart';
import '../domain/holiday_entry.dart';
import '../domain/holiday_place.dart';
import '../domain/spanish_regions.dart';
import '../domain/substituted_holidays.dart';
import 'add_holiday_sheet.dart';
import 'holiday_month_list.dart';
import 'holiday_import_screen.dart';
import 'holiday_pickers.dart';
import 'holidays_icons.dart';
import 'holidays_settings_providers.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// Ajustes › Festivos (`/ajustes/festivos`): the community and municipality
/// the person works in, a line saying whether the local holidays of that
/// municipality are included, «Añadir festivo local», and the year's holidays
/// by month (this year and the next). Every change goes through
/// [HolidayController], so the month, the day sheet and the year view update
/// at once.
class HolidaysSettingsScreen extends ConsumerStatefulWidget {
  const HolidaysSettingsScreen({super.key});

  @override
  ConsumerState<HolidaysSettingsScreen> createState() =>
      _HolidaysSettingsScreenState();
}

class _HolidaysSettingsScreenState
    extends ConsumerState<HolidaysSettingsScreen> {
  late final CivilDate _today = CivilDate.fromDateTime(
    ref.read(clockProvider)(),
  );
  late int _year = _today.year;

  // Holidays of the person removed a moment ago: hidden at once, before the
  // write finishes (a swiped row must leave the tree in the same frame).
  final Set<CivilDate> _hidden = {};

  /// The years that can be looked at: the ones with official data (what the
  /// bundle brought), the ones where the person added their own, and the
  /// current one. A year with no official data yet says so in the status line.
  List<int> _yearsOf(HolidaySnapshot snapshot) => ({
    _today.year,
    _year,
    for (final e in snapshot.entries) e.date.year,
  }.toList()..sort());

  /// Whether the bundle has official holidays for [year] (the person's own
  /// do not count).
  bool _hasOfficial(HolidaySnapshot snapshot, int year) => snapshot.entries.any(
    (e) => e.source != HolidaySource.user && e.date.year == year,
  );

  HolidayController get _controller =>
      ref.read(holidayControllerProvider.notifier);

  // ---- actions ------------------------------------------------------------

  Future<void> _pickRegion(HolidayPlace place) async {
    final pick = await showRegionPicker(
      context,
      selected: place.regionCode,
      clearLabel: context.l10n.holidaysSettingsRegionClear,
    );
    if (pick == null || !mounted || pick.value == place.regionCode) return;
    // A new community drops the municipality (it belonged to the old one).
    await saveSetting(
      context,
      () => _controller.setPlace(regionCode: pick.value),
    );
  }

  Future<void> _pickMunicipality(HolidayPlace place) async {
    final region = place.regionCode;
    if (region == null) return;
    final pick = await showMunicipalityPicker(
      context,
      regionCode: region,
      selectedCode: place.municipalityCode,
      clearLabel: context.l10n.holidaysSettingsMunicipalityNone,
    );
    if (pick == null || !mounted) return;
    final code = pick.value?.code;
    if (code == place.municipalityCode) return;
    await saveSetting(
      context,
      () => _controller.setPlace(regionCode: region, municipalityCode: code),
    );
  }

  Future<void> _add() async {
    final years = _yearsOf(ref.read(holidayControllerProvider));
    final added = await showAddHolidaySheet(
      context,
      initial: _year == _today.year ? _today : CivilDate(_year, 1, 1),
      first: CivilDate(years.first, 1, 1),
      last: CivilDate(
        years.last > _today.year + 1 ? years.last : _today.year + 1,
        12,
        31,
      ),
    );
    if (added == null || !mounted) return;
    setState(() => _year = added.date.year);
    // The «Deshacer» of an earlier removal no longer applies (a failure shows
    // its own message in its place).
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await saveSetting(
      context,
      () => _controller.addUserHoliday(date: added.date, name: added.name),
    );
  }

  Future<void> _remove(Holiday holiday) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final controller = _controller;
    final removed = l10n.holidaysSettingsRemoved(holiday.name);
    final undo = l10n.undo;
    final failed = l10n.saveFailed;
    void tell(SnackBar bar) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(bar);

    setState(() => _hidden.add(holiday.date));
    try {
      await controller.removeUserHoliday(holiday.date);
    } catch (_) {
      if (mounted) setState(() => _hidden.remove(holiday.date));
      tell(appSnackBar(content: Text(failed)));
      return;
    }
    if (mounted) setState(() => _hidden.remove(holiday.date));
    if (!messenger.mounted) return;
    tell(
      appSnackBar(
        context: messenger.context,
        content: Text(removed),
        // Puts back only the holiday that was just removed.
        action: SnackBarAction(
          label: undo,
          onPressed: () async {
            // «Deshacer» is delete-by-date + insert: it must not overwrite a
            // holiday the person added on that day in the meantime.
            if (controller.hasUserHoliday(holiday.date)) return;
            try {
              await controller.addUserHoliday(
                date: holiday.date,
                name: holiday.name,
              );
            } catch (_) {
              tell(appSnackBar(content: Text(failed)));
            }
          },
        ),
      ),
    );
  }

  Future<void> _importFromPhone() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final receipt = await Navigator.of(context).push<HolidayImportReceipt>(
      MaterialPageRoute(
        builder: (_) => const HolidayImportScreen(),
        settings: const RouteSettings(name: '/ajustes/festivos/importar'),
      ),
    );
    if (receipt == null || !mounted) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final controller = _controller;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        appSnackBar(
          context: messenger.context,
          content: Text(l10n.holidayImportAdded(receipt.count)),
          action: receipt.count == 0
              ? null
              : SnackBarAction(
                  label: l10n.undo,
                  onPressed: () async {
                    try {
                      await controller.undoImportedHolidays(receipt);
                    } catch (_) {
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          appSnackBar(content: Text(l10n.saveFailed)),
                        );
                    }
                  },
                ),
        ),
      );
  }

  // ---- status line --------------------------------------------------------

  /// What to say under the pickers, or null while the municipality's name is
  /// still loading.
  ({String text, bool good})? _status(
    HolidaySnapshot snapshot,
    String? municipalityName,
  ) {
    final l10n = context.l10n;
    final place = snapshot.place;
    // Nothing official for this year yet (the app is newer than its data, or
    // the person looks ahead): the place does not matter until it arrives.
    if (snapshot.entries.isNotEmpty && !_hasOfficial(snapshot, _year)) {
      return (
        text: l10n.holidaysSettingsStatusYearPending('$_year'),
        good: false,
      );
    }
    if (place.regionCode == null) {
      return (text: l10n.holidaysSettingsStatusNoRegion, good: false);
    }
    final code = place.municipalityCode;
    if (code == null) {
      return (text: l10n.holidaysSettingsStatusNoMunicipality, good: false);
    }
    if (municipalityName == null) return null;
    bool bundledLocal(HolidayEntry e) =>
        e.scope == HolidayScope.local &&
        e.source != HolidaySource.user &&
        e.municipalityCode == code;
    final local = snapshot.entries.where(bundledLocal);
    if (local.any((e) => e.date.year == _year)) {
      final partial = place.regionCode == 'ES-MC';
      return (
        text:
            l10n.holidaysSettingsStatusLocalIncluded(municipalityName) +
            (partial ? '. ${l10n.holidaysSettingsStatusLocalPartial}' : ''),
        good: true,
      );
    }
    if (local.isNotEmpty) {
      return (
        text: l10n.holidaysSettingsStatusLocalMissingYear(
          municipalityName,
          '$_year',
        ),
        good: false,
      );
    }
    return (text: l10n.holidaysSettingsStatusLocalMissing, good: false);
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snapshot = ref.watch(holidayControllerProvider);
    final place = snapshot.place;
    final region = regionByCode(place.regionCode);
    final index = ref.watch(municipalityIndexProvider).value;
    final municipalityCode = place.municipalityCode;
    final municipalityName = municipalityCode == null
        ? null
        : index?.byCode(municipalityCode)?.name;

    final yearHolidays = snapshot.calendar
        .list(CivilDate(_year, 1, 1), CivilDate(_year, 12, 31))
        .where((h) => !(h.isUserAdded && _hidden.contains(h.date)));
    final rows = holidayRows(context, yearHolidays);
    final substituted = substitutedNationalDays(
      regionalNational:
          ref.watch(regionalNationalEntriesProvider).value ?? const [],
      regionCode: place.regionCode,
      year: _year,
    );
    final status = _status(snapshot, municipalityName);

    // With large text the two rows show their value the same way: both under
    // the title (the community used to stack and the municipality not).
    final stackPlace = textScaleOf(context) >= 1.3 - 0.001;
    return Scaffold(
      appBar: ContentAppBar.adaptive(
        context,
        title: Text(l10n.settingsHolidaysTitle),
      ),
      body: PageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Sp.page, Sp.s, Sp.page, Sp.x3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsSection(
                children: [
                  SettingsRow(
                    key: const ValueKey('holidays-region'),
                    icon: HolidaysIcons.region,
                    title: l10n.holidaysSettingsRegionTitle,
                    value: region?.name ?? l10n.holidaysSettingsRegionUnset,
                    forceStacked: stackPlace,
                    onTap: () => _pickRegion(place),
                  ),
                  SettingsRow(
                    key: const ValueKey('holidays-municipality'),
                    icon: HolidaysIcons.municipality,
                    title: l10n.holidaysSettingsMunicipalityTitle,
                    forceStacked: stackPlace,
                    subtitle: region == null
                        ? l10n.onboardingMunicipalityNeedsRegion
                        : null,
                    value: region == null
                        ? null
                        : municipalityCode == null
                        ? l10n.holidaysSettingsMunicipalityNone
                        : (municipalityName ?? ''),
                    onTap: region == null
                        ? null
                        : () => _pickMunicipality(place),
                  ),
                ],
              ),
              if (status != null) ...[
                const SizedBox(height: Sp.m),
                _StatusLine(
                  key: const ValueKey('holidays-status'),
                  text: status.text,
                  good: status.good,
                ),
              ],
              const SizedBox(height: Sp.l),
              SecondaryButton(
                key: const ValueKey('holidays-add'),
                label: l10n.holidaysSettingsAdd,
                icon: AppIcons.add,
                onPressed: _add,
              ),
              const SizedBox(height: Sp.s),
              SecondaryButton(
                key: const ValueKey('holidays-import'),
                label: l10n.holidayImportAction,
                icon: AppIcons.calendar,
                onPressed: _importFromPhone,
              ),
              const SizedBox(height: Sp.section),
              Wrap(
                spacing: Sp.s,
                runSpacing: Sp.s,
                children: [
                  for (final year in _yearsOf(snapshot))
                    ChoicePill(
                      key: ValueKey('holidays-year-$year'),
                      label: '$year',
                      selected: year == _year,
                      onTap: () => setState(() => _year = year),
                    ),
                ],
              ),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(Sp.xxl),
                  child: Text(
                    l10n.holidaysSettingsEmptyYear('$_year'),
                    key: const ValueKey('holidays-empty'),
                    textAlign: TextAlign.center,
                    style: context.type.body.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                )
              else
                HolidayMonthList(
                  rows: rows,
                  regionName: region?.name,
                  onRemove: _remove,
                ),
              if (region != null && substituted.isNotEmpty) ...[
                const SizedBox(height: Sp.section),
                SubstitutedHolidaysNote(
                  key: const ValueKey('holidays-substituted'),
                  regionName: region.name,
                  days: substituted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A line under the pickers: a check when the municipality's holidays are
/// included, an info mark when something is still to do.
class _StatusLine extends StatelessWidget {
  const _StatusLine({super.key, required this.text, required this.good});

  final String text;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: Sp.hair),
              child: Icon(
                good ? AppIcons.check : HolidaysIcons.info,
                size: IconSize.inline,
                color: good ? colors.success : colors.textMuted,
              ),
            ),
            const SizedBox(width: Sp.s),
            Expanded(
              child: Text(
                text,
                style: context.type.meta.copyWith(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
