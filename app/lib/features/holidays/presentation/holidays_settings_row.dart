import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/settings_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/holidays_provider.dart';
import '../domain/spanish_regions.dart';

/// The «Festivos» row of Settings: the chosen community at the right, opens
/// `/ajustes/festivos`.
class HolidaysSettingsRow extends ConsumerWidget {
  const HolidaysSettingsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final region = regionByCode(ref.watch(holidayPlaceProvider).regionCode);
    return SettingsRow(
      key: const ValueKey('settings-holidays'),
      icon: SettingsIcons.holidays,
      title: l10n.settingsHolidaysTitle,
      value: region?.name ?? l10n.holidaysSettingsRegionUnset,
      onTap: () => context.push(AppRoutes.settingsHolidays),
    );
  }
}
