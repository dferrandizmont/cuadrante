import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../holidays/domain/holiday.dart';
import '../../schedule/domain/schedule_domain.dart';
import 'month_share_card.dart';
import '../application/offscreen_image.dart';

/// Pixels per logical pixel of the shared picture: [MonthShareCard.width] x 3
/// = 1200 px wide, sharp enough for a full-screen chat preview.
const double monthImagePixelRatio = 3;

/// The month card on its own tree: light theme whatever the app shows, the
/// system text size ignored, texts in [locale] (the app's language). What [renderMonthImage] draws.
Widget monthImageTree({
  required CivilDate month,
  required Schedule schedule,
  required Map<CivilDate, Holiday> holidays,
  required int weekStart,
  Locale locale = const Locale('es'),
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(
        size: Size(MonthShareCard.width, 800),
        devicePixelRatio: monthImagePixelRatio,
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
              width: MonthShareCard.width,
              child: MonthShareCard(
                month: month,
                schedule: schedule,
                holidays: holidays,
                weekStart: weekStart,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The PNG of [month] (see [MonthShareCard]), 1200 px wide. [weekStart] is
/// 1 (Monday) or 7 (Sunday), like the month screen.
Future<Uint8List> renderMonthImage({
  required CivilDate month,
  required Schedule schedule,
  required Map<CivilDate, Holiday> holidays,
  required int weekStart,
  Locale locale = const Locale('es'),
}) => renderWidgetToPng(
  monthImageTree(
    month: month,
    schedule: schedule,
    holidays: holidays,
    weekStart: weekStart,
    locale: locale,
  ),
  width: MonthShareCard.width,
  pixelRatio: monthImagePixelRatio,
);
