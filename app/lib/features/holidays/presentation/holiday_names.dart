import '../../../core/format/text_fold.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/holiday.dart';

/// The name of [holiday] in the app's language (H-T21-1).
///
/// The holiday bundle carries Spanish names only. The national holidays and
/// the common regional ones have a translation in the ARB files
/// (`holidayName*`); any other name stays as the bundle has it. A holiday the
/// person added is theirs: never translated.
String holidayDisplayName(AppLocalizations l10n, Holiday holiday) =>
    holiday.isUserAdded
    ? holiday.name
    : localizedHolidayName(l10n, holiday.name) ?? holiday.name;

/// The translation of the bundle name [bundleName], or `null` when there is
/// none. The bundle has no ids, so the stable key is the Spanish name folded
/// ([foldSpanish]: no accents, case or hyphens), which survives the small
/// spelling differences between years of the bundle.
String? localizedHolidayName(AppLocalizations l10n, String bundleName) {
  return switch (foldSpanish(bundleName.trim())) {
    'ano nuevo' => l10n.holidayNameNewYear,
    'epifania del senor' => l10n.holidayNameEpiphany,
    'jueves santo' => l10n.holidayNameMaundyThursday,
    'viernes santo' => l10n.holidayNameGoodFriday,
    'lunes de pascua' => l10n.holidayNameEasterMonday,
    'fiesta del trabajo' => l10n.holidayNameLabourDay,
    'asuncion de la virgen' => l10n.holidayNameAssumption,
    'fiesta nacional de espana' => l10n.holidayNameNationalDay,
    'todos los santos' => l10n.holidayNameAllSaints,
    'dia de la constitucion espanola' => l10n.holidayNameConstitution,
    'inmaculada concepcion' => l10n.holidayNameImmaculate,
    'natividad del senor' => l10n.holidayNameChristmas,
    'san esteban' => l10n.holidayNameStStephen,
    'san jose' => l10n.holidayNameStJoseph,
    'santiago apostol' => l10n.holidayNameStJames,
    'dia de galicia' => l10n.holidayNameGaliciaDay,
    'santiago apostol / dia nacional de galicia' =>
      l10n.holidayNameStJamesGalicia,
    'diada nacional de cataluna' ||
    'diada nacional de catalunya' => l10n.holidayNameCataloniaDay,
    'dia del pais vasco' => l10n.holidayNameBasqueDay,
    _ => null,
  };
}
