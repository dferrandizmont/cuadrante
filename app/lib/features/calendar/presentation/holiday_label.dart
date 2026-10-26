import '../../../l10n/app_localizations.dart';

/// Whether [name] already says "festivo" ("Festivo propio"): then putting the
/// word before it, "Festivo: Festivo propio", would only repeat it.
bool _namesItselfHoliday(String name) =>
    name.trimLeft().toLowerCase().startsWith('festivo');

/// The holiday line of the day sheet: "Festivo: Fiesta Nacional de España",
/// or just "Festivo propio" when the name already carries the word.
String holidayLine(AppLocalizations l10n, String name) =>
    _namesItselfHoliday(name) ? name : l10n.daySheetHoliday(name);

/// The holiday part of a day read aloud: "festivo: Cumple de Ana", or just
/// "Festivo propio".
String holidaySpoken(AppLocalizations l10n, String name) =>
    _namesItselfHoliday(name) ? name : l10n.daySemanticsHoliday(name);
