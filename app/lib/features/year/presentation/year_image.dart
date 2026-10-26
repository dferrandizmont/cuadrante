import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../holidays/domain/holiday.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../summary/application/offscreen_image.dart';
import '../application/year_summary.dart';
import 'year_legend.dart';
import 'year_month.dart';

/// The picture of the year: the title, the twelve months as a heat map of
/// shifts (3 x 4 on a phone) and the legend with the days of each shift.
/// Nothing private goes in: no notes, no hours, no pay.
///
/// It is what the annual view draws on screen and what "Compartir como
/// imagen" sends, from there and from Resumen › Año ([renderYearImage]), so
/// the two images are the same. No `LayoutBuilder` (it is also laid out
/// off-screen in one pass): the width comes from the parent as [width].
class YearImageBody extends StatelessWidget {
  const YearImageBody({
    super.key,
    required this.width,
    required this.year,
    required this.schedule,
    required this.holidays,
    required this.today,
    required this.weekStart,
    this.onOpenMonth,
  });

  /// Width the picture is drawn at, margins included.
  final double width;
  final int year;
  final Schedule schedule;
  final Map<CivilDate, Holiday> holidays;
  final CivilDate today;

  /// 1 (Monday) or 7 (Sunday).
  final int weekStart;

  /// Opens a month (the screen); null in the shared picture.
  final ValueChanged<CivilDate>? onOpenMonth;

  /// Content width from which the grid uses 4 columns instead of 3.
  static const double wideFrom = 600;

  /// Width of the shared picture in logical pixels (1200 px at 3x).
  static const double shareWidth = 400;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final summary = summarizeYear(schedule, year);
    final inner = width - 2 * Sp.page;
    final columns = inner >= wideFrom ? 4 : 3;
    const gap = Sp.l;
    final tile = (inner - gap * (columns - 1)) / columns;
    return ColoredBox(
      color: colors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.page, Sp.s, Sp.page, Sp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.yearImageTitle(year), style: type.headline),
            const SizedBox(height: Sp.l),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var m = 1; m <= 12; m++)
                  SizedBox(
                    width: tile,
                    child: YearMonth(
                      key: ValueKey('year-month-$m'),
                      width: tile,
                      month: CivilDate(year, m, 1),
                      schedule: schedule,
                      holidays: holidays,
                      today: today,
                      weekStart: weekStart,
                      onTap: onOpenMonth,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Sp.section),
            YearLegend(schedule: schedule, summary: summary),
          ],
        ),
      ),
    );
  }
}

/// Pixels per logical pixel of the shared picture.
const double yearImagePixelRatio = 3;

/// The year picture on its own tree: light theme whatever the app shows, the
/// system text size ignored, texts in [locale] (the app's language). What [renderYearImage] draws.
Widget yearImageTree({
  required int year,
  required Schedule schedule,
  required Map<CivilDate, Holiday> holidays,
  required CivilDate today,
  required int weekStart,
  Locale locale = const Locale('es'),
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(
        size: Size(YearImageBody.shareWidth, 800),
        devicePixelRatio: yearImagePixelRatio,
        textScaler: TextScaler.noScaling,
      ),
      child: Localizations(
        locale: locale,
        delegates: const [
          AppLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Theme(
          data: AppTheme.light(),
          child: Material(
            type: MaterialType.canvas,
            child: SizedBox(
              width: YearImageBody.shareWidth,
              child: YearImageBody(
                width: YearImageBody.shareWidth,
                year: year,
                schedule: schedule,
                holidays: holidays,
                today: today,
                weekStart: weekStart,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The PNG of [year], 1200 px wide (the same picture as the annual view's).
Future<Uint8List> renderYearImage({
  required int year,
  required Schedule schedule,
  required Map<CivilDate, Holiday> holidays,
  required CivilDate today,
  required int weekStart,
  Locale locale = const Locale('es'),
}) => renderWidgetToPng(
  yearImageTree(
    year: year,
    schedule: schedule,
    holidays: holidays,
    today: today,
    weekStart: weekStart,
    locale: locale,
  ),
  width: YearImageBody.shareWidth,
  pixelRatio: yearImagePixelRatio,
);
