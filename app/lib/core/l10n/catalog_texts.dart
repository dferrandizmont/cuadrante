import 'package:flutter/widgets.dart';

import '../../features/schedule/domain/presets.dart';
import 'l10n.dart';

/// The texts of the shift templates and the pattern catalogue in the
/// language of [l10n] (`catalog*` keys of the ARB files).
CatalogTexts catalogTextsFrom(AppLocalizations l10n) => CatalogTexts(
  mainCalendarName: l10n.catalogCalendarMainName,
  templates: {
    'morning': (
      name: l10n.catalogShiftMorningName,
      code: l10n.catalogShiftMorningCode,
    ),
    'afternoon': (
      name: l10n.catalogShiftAfternoonName,
      code: l10n.catalogShiftAfternoonCode,
    ),
    'night': (
      name: l10n.catalogShiftNightName,
      code: l10n.catalogShiftNightCode,
    ),
    'rest': (name: l10n.catalogShiftRestName, code: l10n.catalogShiftRestCode),
    'guard24': (
      name: l10n.catalogShiftGuard24Name,
      code: l10n.catalogShiftGuard24Code,
    ),
    'postNight': (
      name: l10n.catalogShiftPostNightName,
      code: l10n.catalogShiftPostNightCode,
    ),
    'vacation': (
      name: l10n.catalogShiftVacationName,
      code: l10n.catalogShiftVacationCode,
    ),
    'personalDay': (
      name: l10n.catalogShiftPersonalDayName,
      code: l10n.catalogShiftPersonalDayCode,
    ),
    'day12': (
      name: l10n.catalogShiftDay12Name,
      code: l10n.catalogShiftDay12Code,
    ),
    'night12': (
      name: l10n.catalogShiftNight12Name,
      code: l10n.catalogShiftNight12Code,
    ),
    'split': (
      name: l10n.catalogShiftSplitName,
      code: l10n.catalogShiftSplitCode,
    ),
  },
  presets: {
    'correturnos': (
      name: l10n.catalogPatternCorreturnosName,
      description: l10n.catalogPatternCorreturnosDescription,
    ),
    '24x72': (
      name: l10n.catalogPattern24x72Name,
      description: l10n.catalogPattern24x72Description,
    ),
    '12h': (
      name: l10n.catalogPattern12hName,
      description: l10n.catalogPattern12hDescription,
    ),
    '6x4': (
      name: l10n.catalogPattern6x4Name,
      description: l10n.catalogPattern6x4Description,
    ),
    '4x4': (
      name: l10n.catalogPattern4x4Name,
      description: l10n.catalogPattern4x4Description,
    ),
    '5x2': (
      name: l10n.catalogPattern5x2Name,
      description: l10n.catalogPattern5x2Description,
    ),
    '2-2-3': (
      name: l10n.catalogPattern223Name,
      description: l10n.catalogPattern223Description,
    ),
    'continental': (
      name: l10n.catalogPatternContinentalName,
      description: l10n.catalogPatternContinentalDescription,
    ),
    'dupont': (
      name: l10n.catalogPatternDupontName,
      description: l10n.catalogPatternDupontDescription,
    ),
  },
);

/// Keeps [catalogTexts] in the app's language: set when the localizations
/// first resolve and again on every language change. Shows nothing.
class CatalogTextsHost extends StatefulWidget {
  const CatalogTextsHost({required this.child, super.key});

  final Widget child;

  @override
  State<CatalogTextsHost> createState() => _CatalogTextsHostState();
}

class _CatalogTextsHostState extends State<CatalogTextsHost> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    catalogTexts = catalogTextsFrom(context.l10n);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
