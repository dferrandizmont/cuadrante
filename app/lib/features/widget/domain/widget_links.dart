import '../../schedule/domain/civil_date.dart';

/// Scheme and host of the links a widget tap opens
/// (`cuadrante://widget/day/2026-10-19`). The Kotlin side builds the same
/// strings (`WidgetLinks.kt`).
const String kWidgetLinkScheme = 'cuadrante';
const String kWidgetLinkHost = 'widget';

/// The link a widget cell for [date] opens.
Uri widgetDayLink(CivilDate date) => Uri(
  scheme: kWidgetLinkScheme,
  host: kWidgetLinkHost,
  pathSegments: ['day', date.toIso()],
);

/// The link the header of the month widget opens
/// (`cuadrante://widget/month/2026-10`): the month, with no day sheet.
Uri widgetMonthLink(CivilDate month) => Uri(
  scheme: kWidgetLinkScheme,
  host: kWidgetLinkHost,
  pathSegments: ['month', month.toIso().substring(0, 7)],
);

/// What a tap on a widget asks the app to do.
class WidgetTarget {
  const WidgetTarget(this.day, {this.month});

  /// The day to open, or null to just open the app (the "open the app"
  /// message and the cells of the stale widget carry no day).
  final CivilDate? day;

  /// The month to show (its 1st) when the link names a month and no day
  /// (the header of the month widget); null otherwise.
  final CivilDate? month;
}

/// Reads a widget link; null when [uri] is not one of ours (links can come
/// from any app, so anything else is ignored). A day or month more than
/// [maxLinkYearsFromToday] years from [today] is ignored too: the app just
/// opens, on today.
WidgetTarget? widgetLinkTarget(Uri? uri, {required CivilDate today}) {
  if (uri == null ||
      uri.scheme != kWidgetLinkScheme ||
      uri.host != kWidgetLinkHost) {
    return null;
  }
  final segments = uri.pathSegments;
  if (segments.length == 2 && segments[0] == 'day') {
    try {
      final day = CivilDate.parse(segments[1]);
      return isLinkYearInRange(day.year, today)
          ? WidgetTarget(day)
          : const WidgetTarget(null);
    } on FormatException {
      return const WidgetTarget(null);
    }
  }
  if (segments.length == 2 && segments[0] == 'month') {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(segments[1]);
    final year = int.tryParse(match?.group(1) ?? '');
    final month = int.tryParse(match?.group(2) ?? '');
    if (year != null &&
        isLinkYearInRange(year, today) &&
        month != null &&
        month >= 1 &&
        month <= 12) {
      return WidgetTarget(null, month: CivilDate(year, month, 1));
    }
  }
  return const WidgetTarget(null);
}
