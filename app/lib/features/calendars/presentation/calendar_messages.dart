import '../../../core/l10n/l10n.dart';
import '../domain/calendar.dart';

/// The sentence for a failed calendar operation: the typed refusals of the
/// repository say what happened (the last calendar cannot go, the calendar
/// is gone); anything else is a generic save error.
String calendarErrorMessage(AppLocalizations l10n, Object error) =>
    switch (error) {
      LastCalendarCannotBeArchived() => l10n.calendarsLastError,
      CalendarNotFound() => l10n.calendarsNotFoundError,
      ArgumentError() => l10n.calendarsNameRequired,
      _ => l10n.calendarsSaveFailed,
    };
