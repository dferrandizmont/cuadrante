import '../../../core/l10n/l10n.dart';
import '../data/calendar_exporter.dart';
import '../domain/export_events.dart';

/// One line of the card that says what an export will do, or did.
class ExportLine {
  const ExportLine(this.key, this.text, {this.strong = false});

  /// Name of the line (tests, widget keys).
  final String key;
  final String text;

  /// The main line of the card (bold).
  final bool strong;

  @override
  String toString() => '$key: $text';
}

/// What the card before the «Exportar» button says about [plan].
///
/// The wording follows what the export really does to the events of a
/// previous export: «sustituirán» only for those it writes again (a shift
/// that changed) and «quitarán» for those that nothing replaces (the days off
/// or the absences were switched off), each with its own count, so
/// switching the days off never says «sustituirán» (H-T14-3).
List<ExportLine> exportPlanLines(AppLocalizations l10n, ExportPlan plan) {
  if (plan.toCreate.isEmpty && plan.toDelete.isEmpty && plan.unchanged == 0) {
    return [ExportLine('none', l10n.calExportPlanNone, strong: true)];
  }
  if (plan.isNoop) {
    return [ExportLine('nothing', l10n.calExportPlanNothing, strong: true)];
  }
  final replaced = plan.replaced;
  final removed = plan.removed;
  return [
    if (plan.toCreate.isNotEmpty)
      ExportLine(
        'add',
        l10n.calExportPlanAdd(plan.toCreate.length),
        strong: true,
      ),
    if (replaced > 0)
      ExportLine('replace', l10n.calExportPlanReplace(replaced)),
    if (removed > 0) ExportLine('remove', l10n.calExportPlanRemove(removed)),
    if (plan.unchanged > 0)
      ExportLine('same', l10n.calExportPlanSame(plan.unchanged)),
  ];
}

/// What the card after the export says about [result]: the same distinction
/// as [exportPlanLines] («sustituidos» for events written again, «quitados»
/// for events only removed).
List<ExportLine> exportResultLines(AppLocalizations l10n, ExportResult result) {
  final replaced = result.replaced;
  final removed = result.removed - replaced;
  return [
    if (result.calendarCreated)
      ExportLine('calendar', l10n.calExportDoneCalendar),
    // «0 eventos añadidos» only when nothing else happened to say.
    if (result.created > 0 || result.removed == 0)
      ExportLine('created', l10n.calExportDoneCreated(result.created)),
    if (replaced > 0)
      ExportLine('replaced', l10n.calExportDoneReplaced(replaced)),
    if (removed > 0) ExportLine('removed', l10n.calExportDoneRemoved(removed)),
    if (result.unchanged > 0)
      ExportLine('same', l10n.calExportDoneSame(result.unchanged)),
    if (result.failed > 0)
      ExportLine('failed', l10n.calExportDoneFailed(result.failed)),
  ];
}
