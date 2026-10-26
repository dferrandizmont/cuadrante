import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// "12,00 €" in the active locale.
String formatEuro(BuildContext context, double amount) {
  final lang = Localizations.localeOf(context).languageCode;
  return NumberFormat.currency(locale: lang, symbol: '€').format(amount);
}

/// An amount kept in whole cents (no floating point in the sums), as
/// "1.234,56 €" in the active locale.
String formatEuroCents(BuildContext context, int cents) =>
    formatEuroCentsFor(Localizations.localeOf(context).languageCode, cents);

/// [formatEuroCents] without a [BuildContext]; [locale] is a language code.
String formatEuroCentsFor(String locale, int cents) {
  final format = NumberFormat.currency(locale: locale, symbol: '€');
  return format.format(cents / 100);
}
