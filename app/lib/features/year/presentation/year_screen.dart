import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/router.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/page_body.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendar/application/visible_month.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/year_providers.dart';
import '../../settings/application/preferences_controller.dart';
import 'year_image.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// Vista anual (turnos-spec.md section 4, screen 5): the 12 months as a heat
/// map of shifts (3 x 4 on a phone), the shifts of the year with their day
/// counts, and the whole thing shareable as an image. Tapping a month opens
/// it in the month screen.
class YearScreen extends ConsumerStatefulWidget {
  const YearScreen({super.key});

  @override
  ConsumerState<YearScreen> createState() => _YearScreenState();
}

class _YearScreenState extends ConsumerState<YearScreen> {
  final _imageKey = GlobalKey();
  bool _sharing = false;

  void _openMonth(CivilDate month) {
    ref.read(visibleMonthProvider.notifier).goTo(month);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _share(int year) async {
    if (_sharing) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final share = ref.read(yearImageSharerProvider);
    setState(() => _sharing = true);
    try {
      final boundary =
          _imageKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await share(
        data!.buffer.asUint8List(),
        'cuadrante-$year.png',
        l10n.yearShareSubject(year),
      );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(appSnackBar(content: Text(l10n.yearShareFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final year = ref.watch(visibleYearProvider);
    final visibleMonth = ref.watch(visibleMonthProvider);
    final yearController = ref.read(visibleYearProvider.notifier);
    final schedule = ref.watch(
      scheduleControllerProvider.select((s) => s.schedule),
    );
    final holidays = ref.watch(holidaysProvider);
    final today = CivilDate.fromDateTime(ref.watch(minuteClockProvider));
    final weekStart = ref.watch(preferencesProvider.select((p) => p.weekStart));

    return Scaffold(
      appBar: ContentAppBar.adaptive(
        context,
        title: Text(l10n.yearTitle),
        actions: [
          IconButton(
            key: const ValueKey('year-share'),
            tooltip: l10n.yearShare,
            icon: Icon(AppIcons.share),
            onPressed: _sharing ? null : () => _share(year),
          ),
        ],
      ),
      body: PageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: Sp.section),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Sp.s),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('year-previous'),
                      tooltip: l10n.yearPrevious,
                      icon: Icon(AppIcons.chevronLeft),
                      onPressed: yearController.previous,
                    ),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          '$year',
                          key: const ValueKey('year-label'),
                          textAlign: TextAlign.center,
                          style: AppTypography.tabular(type.title),
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('year-next'),
                      tooltip: l10n.yearNext,
                      icon: Icon(AppIcons.chevronRight),
                      onPressed: yearController.next,
                    ),
                  ],
                ),
              ),
              // Everything inside is what "Compartir como imagen" draws.
              RepaintBoundary(
                key: _imageKey,
                child: LayoutBuilder(
                  builder: (context, box) => YearImageBody(
                    width: box.maxWidth,
                    year: year,
                    schedule: schedule,
                    holidays: holidays,
                    today: today,
                    weekStart: weekStart,
                    onOpenMonth: _openMonth,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Sp.page),
                child: AppCard(
                  key: const ValueKey('year-open-summary'),
                  padding: EdgeInsets.zero,
                  semanticLabel:
                      '${l10n.summaryYearRowTitle}. ${l10n.summaryYearRowBody}',
                  onTap: () => context.push(
                    AppRoutes.summaryFor(
                      visibleMonth.year == year
                          ? visibleMonth
                          : CivilDate(year, 1, 1),
                      year: true,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: Sp.touch),
                    child: Padding(
                      padding: const EdgeInsets.all(Sp.l),
                      child: Row(
                        children: [
                          Icon(AppIcons.summary, color: colors.textSecondary),
                          const SizedBox(width: Sp.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.summaryYearRowTitle,
                                  style: type.bodyStrong,
                                ),
                                Text(
                                  l10n.summaryYearRowBody,
                                  style: type.meta.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(AppIcons.chevronRight, color: colors.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
