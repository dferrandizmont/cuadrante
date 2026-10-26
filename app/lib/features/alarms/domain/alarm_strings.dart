import '../../../l10n/app_localizations.dart';

/// Every user-visible text of the alarms, resolved before planning so the
/// planner and the scheduler stay free of `BuildContext` and of the
/// generated localizations class (tests build their own).
class AlarmStrings {
  const AlarmStrings({
    required this.title,
    required this.body,
    required this.channelName,
    required this.channelDescription,
    required this.dayBeforeTitle,
    required this.snoozeAction,
    required this.awakeAction,
    required this.testTitle,
    required this.testBody,
    required this.reminderTitle,
    required this.reminderEmptyBody,
    required this.reminderChannelName,
    required this.reminderChannelDescription,
  });

  /// Filled from the ARB file of the current locale.
  factory AlarmStrings.fromL10n(AppLocalizations l10n) => AlarmStrings(
    title: l10n.alarmTitle,
    body: l10n.alarmBody,
    channelName: l10n.alarmChannelName,
    channelDescription: l10n.alarmChannelDescription,
    dayBeforeTitle: l10n.alarmsNotifDayBeforeTitle,
    snoozeAction: l10n.alarmsNotifSnooze,
    awakeAction: l10n.alarmsNotifAwake,
    testTitle: l10n.alarmsNotifTestTitle,
    testBody: l10n.alarmsNotifTestBody,
    reminderTitle: l10n.alarmsReminderTitle,
    reminderEmptyBody: l10n.alarmsReminderEmptyBody,
    reminderChannelName: l10n.alarmsReminderChannelName,
    reminderChannelDescription: l10n.alarmsReminderChannelDescription,
  );

  /// Empty texts, for computing a plan only to read its times (the "next
  /// alarm" line of the settings screen shows its own text).
  static const AlarmStrings blank = AlarmStrings(
    title: _blank2,
    body: _blank3,
    channelName: '',
    channelDescription: '',
    dayBeforeTitle: _blank2,
    snoozeAction: '',
    awakeAction: '',
    testTitle: '',
    testBody: '',
    reminderTitle: '',
    reminderEmptyBody: '',
    reminderChannelName: '',
    reminderChannelDescription: '',
  );

  /// "Turno de Noche a las 22:00": shift name and start time ("HH:mm").
  final String Function(String name, String start) title;

  /// Shift name and the two times ("22:00", "06:00").
  final String Function(String name, String start, String end) body;

  /// Title of the day-before reminder: "Mañana: turno de Noche a las 22:00".
  /// Its body is [body].
  final String Function(String name, String start) dayBeforeTitle;

  /// Android notification channel.
  final String channelName;
  final String channelDescription;

  /// Labels of the notification buttons: "Posponer 10 min" and "Ya estoy
  /// despierto".
  final String snoozeAction;
  final String awakeAction;

  /// The "Probar aviso" notification.
  final String testTitle;
  final String testBody;

  /// Reminder of a day's note: the title ("Recordatorio") and the body when
  /// the note has no text ("Tienes un recordatorio para hoy"); the body of a
  /// reminder is otherwise the first line of the note.
  final String reminderTitle;
  final String reminderEmptyBody;

  /// Android channel of the note reminders.
  final String reminderChannelName;
  final String reminderChannelDescription;
}

String _blank2(String a, String b) => '';
String _blank3(String a, String b, String c) => '';
