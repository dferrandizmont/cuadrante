import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

/// The Spanish Material strings of Flutter with the few the app words
/// differently.
///
/// Flutter's `es` bundle writes the OK button of the date and time pickers in
/// capitals («ACEPTAR») next to a sentence-case «Cancelar». The app writes
/// every button in sentence case (H-T01-2), so the pickers take this bundle
/// instead. Everything else comes from Flutter unchanged.
class AppMaterialLocalizations extends MaterialLocalizationEs {
  const AppMaterialLocalizations({
    required super.fullYearFormat,
    required super.compactDateFormat,
    required super.shortDateFormat,
    required super.mediumDateFormat,
    required super.longDateFormat,
    required super.yearMonthFormat,
    required super.shortMonthDayFormat,
    required super.decimalFormat,
    required super.twoDigitZeroPaddedFormat,
  });

  /// Registered before [GlobalMaterialLocalizations.delegate], which it
  /// shadows for Spanish.
  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _AppMaterialLocalizationsDelegate();

  @override
  String get okButtonLabel => 'Aceptar';
}

class _AppMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _AppMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'es';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    const name = 'es';
    final known = intl.DateFormat.localeExists(name);
    final numbers = intl.NumberFormat.localeExists(name);
    intl.DateFormat date(String pattern) =>
        known ? intl.DateFormat(pattern, name) : intl.DateFormat(pattern);
    return SynchronousFuture<MaterialLocalizations>(
      AppMaterialLocalizations(
        fullYearFormat: date('y'),
        compactDateFormat: date('yMd'),
        shortDateFormat: date('yMMMd'),
        mediumDateFormat: date('MMMEd'),
        longDateFormat: date('yMMMMEEEEd'),
        yearMonthFormat: date('yMMMM'),
        shortMonthDayFormat: date('MMMd'),
        decimalFormat: numbers
            ? intl.NumberFormat.decimalPattern(name)
            : intl.NumberFormat.decimalPattern(),
        twoDigitZeroPaddedFormat: numbers
            ? intl.NumberFormat('00', name)
            : intl.NumberFormat('00'),
      ),
    );
  }

  @override
  bool shouldReload(_AppMaterialLocalizationsDelegate old) => false;
}
