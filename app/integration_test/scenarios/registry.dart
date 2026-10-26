import '../support/qa_core.dart';
import 'alarms.dart';
import 'alarms_settings.dart';
import 'appearance.dart';
import 'backup_ui.dart';
import 'boot.dart';
import 'day_detail.dart';
import 'holidays.dart';
import 'import.dart';
import 'navigation.dart';
import 'onboarding.dart';
import 'painting.dart';
import 'parity_a6_a8.dart';
import 'parity_split.dart';
import 'patterns.dart';
import 'performance.dart';
import 'parity.dart';
import 'persistence.dart';
import 'reminders_sounds.dart';
import 'selection.dart';
import 'settings.dart';
import 'shift_types.dart';
import 'summary.dart';
import 'upgrade.dart';

/// Every scenario of the battery, in report order. A new feature adds its
/// scenario here (docs/qa.md, "Cómo añadir un escenario").
final List<QaScenario> qaScenarios = [
  qaBoot, // Q01
  qaPaintTap, // Q02
  qaDrag, // Q03
  qaDouble, // Q04
  qaErase, // Q05
  qaPersistence, // Q06
  qaNavigation, // Q07
  qaDaySheet, // Q08
  qaAppearance, // Q09
  qaHolidays, // Q10
  qaAlarms, // Q11
  qaBackup, // Q12
  qaPerformance, // Q13
  ...shiftTypesScenarios, // Q20–Q23
  ...dayDetailScenarios, // Q24–Q29
  ...patternScenarios, // Q30–Q39
  ...settingsScenarios, // Q40–Q49
  ...onboardingScenarios, // Q50–Q54
  ...holidaysScenarios, // Q55–Q59
  ...alarmSettingsScenarios, // Q60–Q64
  ...backupUiScenarios, // Q65–Q69
  ...importScenarios, // Q70–Q74
  ...summaryScenarios, // Q75–Q79
  ...selectionScenarios, // Q80–Q84
  ...parityA6A8Scenarios, // Q96–Q98
  ...paritySplitScenarios, // Q99
  ...parityScenarios, // Q85–Q92
  ...reminderSoundScenarios, // Q93–Q95
  ...upgradeScenarios, // U01
];
