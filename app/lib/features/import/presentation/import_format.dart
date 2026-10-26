import 'package:flutter/widgets.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/import_wizard.dart';
import '../domain/event_grouping.dart';
import '../domain/import_models.dart';

/// The Spanish message of an import problem. No text of the source ever goes
/// into it.
String importProblemText(
  AppLocalizations l10n,
  ImportProblem problem,
) => switch (problem) {
  ImportProblem.permissionDenied => l10n.importProblemPermissionDenied,
  ImportProblem.permissionRestricted => l10n.importProblemPermissionRestricted,
  ImportProblem.calendarUnavailable => l10n.importProblemCalendarUnavailable,
  ImportProblem.readFailed => l10n.importProblemReadFailed,
  ImportProblem.fileTooLarge => l10n.importProblemFileTooLarge,
  ImportProblem.fileUnreadable => l10n.importProblemFileUnreadable,
  ImportProblem.notCalendarFile => l10n.importProblemNotCalendar,
  ImportProblem.notCsv => l10n.importProblemNotCsv,
  ImportProblem.notLrhsoftFile => l10n.importProblemNotLrhsoft,
  ImportProblem.noEvents => l10n.importProblemNoEvents,
  ImportProblem.tooComplex => l10n.importProblemTooComplex,
  ImportProblem.unknown => l10n.importProblemUnknown,
};

/// The line that says which file is being imported: the name the user
/// recognises, or the kind of file when the system made the name up (Android
/// calls every file whose type it does not know «.bin») (H-T22-10).
String? importFileLine(AppLocalizations l10n, ImportWizardState wizard) {
  final name = wizard.fileName;
  if (name != null && name.isNotEmpty) return l10n.importRangeFile(name);
  return switch (wizard.source) {
    ImportSourceKind.lrhsoftFile => l10n.importFileLrhsoft,
    ImportSourceKind.csvFile => l10n.importSourceCsv,
    ImportSourceKind.icsFile => l10n.importSourceIcs,
    ImportSourceKind.deviceCalendar || null => null,
  };
}

DateTime _dateTime(CivilDate d) => DateTime(d.year, d.month, d.day);

/// «19 oct 2026».
String importDateText(BuildContext context, CivilDate date) =>
    AppDateFormat.of(context).dayMonthYear(_dateTime(date));

/// «19 oct», without the year (the examples of a group).
String importShortDateText(BuildContext context, CivilDate date) =>
    AppDateFormat.of(context).shortDate(_dateTime(date));

/// The example dates of a group or of the conflicts, separated so that a
/// date that carries a comma of its own (Basque: «urr 11, ig») is not
/// confused with the next one (H-T22-15).
String importDateListText(BuildContext context, Iterable<CivilDate> dates) {
  final format = AppDateFormat.of(context);
  return dates
      .map((d) => format.shortDate(_dateTime(d)))
      .join(format.dateListSeparator);
}

/// «06:00–14:00» for a minute range, «06:00» when there is no end.
String importTimesText(BuildContext context, int start, int? end) {
  final format = AppDateFormat.of(context);
  DateTime at(int minute) => DateTime(2000, 1, 1, minute ~/ 60, minute % 60);
  return format.timeRange(at(start), end == null ? null : at(end));
}

/// The title to show for a group («Sin título» for an empty one).
String importGroupTitle(BuildContext context, EventGroup group) =>
    group.title.isEmpty ? context.l10n.importGroupUntitled : group.title;

/// «5 000» for [maxImportEvents].
String importLimitText(int limit) {
  final digits = limit.toString();
  if (digits.length <= 4) return digits;
  return '${digits.substring(0, digits.length - 3)} '
      '${digits.substring(digits.length - 3)}';
}
