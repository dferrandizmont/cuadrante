// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Cuadrante';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get retry => 'Try again';

  @override
  String get back => 'Back';

  @override
  String get loadingLabel => 'Loading';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get calendarToday => 'Today';

  @override
  String calendarPickMonth(String month) {
    return '$month, choose month';
  }

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String calendarHeaderTomorrow(String date, String shifts) {
    return 'Tomorrow ($date): $shifts shift';
  }

  @override
  String calendarHeaderTomorrowNone(String date) {
    return 'Tomorrow ($date): no shift';
  }

  @override
  String get todayLabelNow => 'Now';

  @override
  String get todayLabelTonight => 'Tonight';

  @override
  String get todayLabelToday => 'Today';

  @override
  String get todayLabelFree => 'Off today';

  @override
  String get todayLabelDone => 'Done for today';

  @override
  String todayFinishedAt(String time) {
    return 'Finished at $time';
  }

  @override
  String get todayLabelGap => 'Break';

  @override
  String todayBackAt(String time) {
    return 'Back at $time';
  }

  @override
  String todayBackIn(String duration) {
    return 'Back in $duration';
  }

  @override
  String get todayFreeTitle => 'Off';

  @override
  String todayUntil(String time) {
    return 'Until $time';
  }

  @override
  String todayStartsIn(String duration) {
    return 'Starts in $duration';
  }

  @override
  String todayEndsIn(String duration) {
    return 'Ends in $duration';
  }

  @override
  String todayNext(String name, String weekday, String time) {
    return 'Next: $name, $weekday $time';
  }

  @override
  String get todayNoNext => 'No shifts coming up';

  @override
  String todayAlso(String shift) {
    return '+ $shift';
  }

  @override
  String durationDaysHours(int days, int hours) {
    return '$days d $hours h';
  }

  @override
  String durationDays(int days) {
    return '$days d';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get calendarNoShift => 'No shift';

  @override
  String calendarShiftWithTimes(String name, String times) {
    return '$name $times';
  }

  @override
  String get calendarWeekdayMon => 'M';

  @override
  String get calendarWeekdayTue => 'T';

  @override
  String get calendarWeekdayWed => 'W';

  @override
  String get calendarWeekdayThu => 'T';

  @override
  String get calendarWeekdayFri => 'F';

  @override
  String get calendarWeekdaySat => 'S';

  @override
  String get calendarWeekdaySun => 'S';

  @override
  String get daySemanticsToday => 'today';

  @override
  String get daySemanticsNoShift => 'no shift';

  @override
  String daySemanticsShift(String name, String start, String end) {
    return '$name from $start to $end';
  }

  @override
  String daySemanticsShiftSplit(
    String name,
    String start,
    String end,
    String start2,
    String end2,
  ) {
    return '$name from $start to $end and from $start2 to $end2';
  }

  @override
  String daySemanticsAnd(String first, String second) {
    return '$first and $second';
  }

  @override
  String daySemanticsHoliday(String name) {
    return 'public holiday: $name';
  }

  @override
  String get daySemanticsNote => 'with a note';

  @override
  String daySemanticsOvertime(String duration) {
    return 'overtime: $duration';
  }

  @override
  String daySemanticsEarlyLeave(String duration) {
    return 'left early: $duration';
  }

  @override
  String daySheetHoliday(String name) {
    return 'Public holiday: $name';
  }

  @override
  String get daySheetNote => 'Note';

  @override
  String get daySheetEmpty => 'No shift on this day.';

  @override
  String get dayPaneClose => 'Close day';

  @override
  String get upcomingTitle => 'Upcoming days';

  @override
  String get dayDetailSourcePattern => 'From your pattern';

  @override
  String get dayDetailSourceOverride => 'Changed by hand';

  @override
  String get dayDetailAdd => 'Add shift';

  @override
  String get dayDetailDouble => 'Add a second shift';

  @override
  String get dayDetailReset => 'Back to the pattern';

  @override
  String dayDetailPatternGives(String shifts) {
    return 'The pattern gives: $shifts';
  }

  @override
  String get dayDetailNoteHint => 'Write a note for this day';

  @override
  String get dayDetailUserHoliday => 'Custom holiday';

  @override
  String get dayDetailUserHolidayDefault => 'Custom holiday';

  @override
  String get dayDetailUserHolidayNameHint => 'Holiday name';

  @override
  String get dayDetailDuplicate => 'Copy to another day';

  @override
  String get dayDetailDuplicateHelp => 'Copy to this day';

  @override
  String dayDetailDuplicated(String date) {
    return 'Copied to $date';
  }

  @override
  String get dayDetailClear => 'Clear day';

  @override
  String get dayDetailCleared => 'Day cleared';

  @override
  String get dayDetailMoveUp => 'Move up';

  @override
  String get dayDetailMoveDown => 'Move down';

  @override
  String dayDetailRemove(String name) {
    return 'Remove $name';
  }

  @override
  String get dayExtrasTitle => 'Overtime / Left early';

  @override
  String get dayExtrasOvertime => 'Overtime';

  @override
  String get dayExtrasEarlyLeave => 'Left early';

  @override
  String get dayExtrasNone => 'None';

  @override
  String get dayExtrasHelper =>
      'Added to or taken from the month’s hours and the estimate. Set it to 0 to remove it.';

  @override
  String dayExtrasMore(String label) {
    return 'More $label';
  }

  @override
  String dayExtrasLess(String label) {
    return 'Less $label';
  }

  @override
  String dayExtrasValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get shiftTypesTitle => 'My shifts';

  @override
  String get shiftTypesEditEntry => 'Edit shifts';

  @override
  String get shiftTypesEmptyTitle => 'You have no shifts';

  @override
  String get shiftTypesEmptyMessage =>
      'Create the first one so you can paint it on the calendar.';

  @override
  String get shiftTypesNew => 'New shift';

  @override
  String get shiftTypesNewTitle => 'New shift';

  @override
  String get shiftTypesEditTitle => 'Edit shift';

  @override
  String get shiftTypesNotFound => 'We can’t find this shift';

  @override
  String get shiftTypesNotFoundMessage =>
      'You may have archived it. Go back to the list of shifts.';

  @override
  String get shiftTypesArchive => 'Archive';

  @override
  String shiftTypesArchiveTitle(String name) {
    return 'Archive “$name”?';
  }

  @override
  String get shiftTypesArchiveBody =>
      'It won’t show up when you paint anymore. Days that already use it will keep showing it.';

  @override
  String get shiftTypesArchiveConfirm => 'Archive';

  @override
  String get shiftTypesDragHandle => 'Drag to reorder';

  @override
  String shiftTypesArchivedSection(int count) {
    return 'Archived ($count)';
  }

  @override
  String get shiftTypesArchivedHelp =>
      'They no longer show up when you paint. Restore them to put them back in the palette.';

  @override
  String get shiftTypesRestore => 'Restore';

  @override
  String shiftTypesRestoreSemantic(String name) {
    return 'Restore “$name”';
  }

  @override
  String shiftTypesRestored(String name) {
    return '“$name” restored';
  }

  @override
  String get shiftTypesDiscardTitle => 'Discard your changes?';

  @override
  String get shiftTypesDiscardBody =>
      'What you changed in this shift won’t be saved.';

  @override
  String get shiftTypesDiscardKeep => 'Keep editing';

  @override
  String get shiftTypesDiscardConfirm => 'Discard';

  @override
  String get shiftTypesNoTimes => 'No times';

  @override
  String shiftTypesRatePerHour(String rate) {
    return '$rate/h';
  }

  @override
  String shiftTypesFixedPlusPerShift(String amount) {
    return '+$amount per shift';
  }

  @override
  String get shiftTypesCategoryWork => 'Work';

  @override
  String get shiftTypesCategoryRest => 'Rest';

  @override
  String get shiftTypesCategoryAbsence => 'Absence';

  @override
  String get shiftTypesNameLabel => 'Name';

  @override
  String get shiftTypesCodeLabel => 'Code';

  @override
  String get shiftTypesCodeHelper =>
      '1 to 3 characters. It’s what you see in each box of the month.';

  @override
  String get shiftTypesColorLabel => 'Color';

  @override
  String shiftTypesColorOption(int number, int total) {
    return 'Color $number of $total';
  }

  @override
  String shiftTypesColorOptionNamed(String name, int number, int total) {
    return '$name, $number of $total';
  }

  @override
  String get shiftColorNameOrange => 'Orange';

  @override
  String get shiftColorNameCoral => 'Coral';

  @override
  String get shiftColorNameIndigo => 'Indigo';

  @override
  String get shiftColorNameLightGrey => 'Light gray';

  @override
  String get shiftColorNameRed => 'Red';

  @override
  String get shiftColorNameLilac => 'Lilac';

  @override
  String get shiftColorNameGreen => 'Green';

  @override
  String get shiftColorNameTeal => 'Teal';

  @override
  String get shiftColorNameRaspberry => 'Raspberry';

  @override
  String get shiftColorNamePink => 'Pink';

  @override
  String get shiftColorNameTangerine => 'Tangerine';

  @override
  String get shiftColorNameYellow => 'Yellow';

  @override
  String get shiftColorNameLime => 'Lime';

  @override
  String get shiftColorNameForest => 'Forest green';

  @override
  String get shiftColorNameMint => 'Mint';

  @override
  String get shiftColorNameCyan => 'Cyan';

  @override
  String get shiftColorNameSkyBlue => 'Sky blue';

  @override
  String get shiftColorNameBlue => 'Blue';

  @override
  String get shiftColorNameCobalt => 'Cobalt';

  @override
  String get shiftColorNameViolet => 'Violet';

  @override
  String get shiftColorNamePurple => 'Purple';

  @override
  String get shiftColorNameBrown => 'Brown';

  @override
  String get shiftColorNameGrey => 'Gray';

  @override
  String get shiftColorNameGraphite => 'Graphite';

  @override
  String get shiftTypesColorCurrent => 'Current color';

  @override
  String get shiftTypesIconLabel => 'Icon';

  @override
  String get shiftTypesIconHelper =>
      'Optional. It shows next to the code when there’s room; the code and the color are always there.';

  @override
  String get shiftTypesIconNone => 'No icon';

  @override
  String get shiftTypesIconChoose => 'Choose icon';

  @override
  String shiftTypesIconCurrent(String name) {
    return 'Icon: $name';
  }

  @override
  String get shiftIconNameSun => 'Sun';

  @override
  String get shiftIconNameMoon => 'Moon';

  @override
  String get shiftIconNameSunrise => 'Sunrise';

  @override
  String get shiftIconNameHospital => 'Hospital';

  @override
  String get shiftIconNameAmbulance => 'Ambulance';

  @override
  String get shiftIconNamePolice => 'Police';

  @override
  String get shiftIconNameFire => 'Firefighters';

  @override
  String get shiftIconNameFactory => 'Factory';

  @override
  String get shiftIconNameTruck => 'Truck';

  @override
  String get shiftIconNamePlane => 'Plane';

  @override
  String get shiftIconNameSchool => 'School';

  @override
  String get shiftIconNameHome => 'Home';

  @override
  String get shiftIconNameBeach => 'Beach';

  @override
  String get shiftIconNameBed => 'Bed';

  @override
  String get shiftIconNameStar => 'Star';

  @override
  String get shiftIconNameHeart => 'Heart';

  @override
  String get shiftIconNameCoffee => 'Coffee';

  @override
  String get shiftIconNameBook => 'Book';

  @override
  String get shiftIconNameMoney => 'Money';

  @override
  String get shiftIconNameAlert => 'Alert';

  @override
  String get shiftIconNamePhone => 'Phone';

  @override
  String get shiftIconNameCar => 'Car';

  @override
  String get shiftIconNameTrain => 'Train';

  @override
  String get shiftIconNameBus => 'Bus';

  @override
  String get shiftIconNameShop => 'Shop';

  @override
  String get shiftIconNameTool => 'Tools';

  @override
  String get shiftIconNameBaby => 'Baby';

  @override
  String get shiftIconNameSport => 'Sport';

  @override
  String get shiftIconNameParty => 'Party';

  @override
  String get shiftIconNameMedical => 'Medical';

  @override
  String get shiftTypesColorMore => 'More colors…';

  @override
  String get shiftTypesColorPickerTitle => 'Pick your color';

  @override
  String get shiftTypesColorPickerHelp =>
      'See how the box looks in light and dark mode. The text adjusts itself so it’s easy to read.';

  @override
  String get shiftTypesColorHue => 'Hue';

  @override
  String get shiftTypesColorSaturation => 'Saturation';

  @override
  String get shiftTypesColorLightness => 'Lightness';

  @override
  String shiftTypesColorHueSpoken(int degrees) {
    return '$degrees degrees';
  }

  @override
  String shiftTypesColorPercentSpoken(int percent) {
    return '$percent percent';
  }

  @override
  String get shiftTypesColorHexLabel => 'Hex code';

  @override
  String get shiftTypesColorHexError =>
      'Type 6 digits or letters from A to F, for example #1C7ED6.';

  @override
  String get shiftTypesColorUse => 'Use this color';

  @override
  String get shiftTypesCategoryLabel => 'Category';

  @override
  String get shiftTypesTimesLabel => 'Times';

  @override
  String shiftTypesStarts(String time) {
    return 'Starts $time';
  }

  @override
  String shiftTypesEnds(String time) {
    return 'Ends $time';
  }

  @override
  String get shiftTypesPickStart => 'Start time';

  @override
  String get shiftTypesPickEnd => 'End time';

  @override
  String shiftTypesDuration(String duration) {
    return 'Lasts $duration';
  }

  @override
  String shiftTypesEndsNextDay(String duration) {
    return 'Ends the next day · lasts $duration';
  }

  @override
  String get shiftTypesTwentyFourHours =>
      'Lasts 24 h: ends the next day at the same time';

  @override
  String get shiftTypesSplitLabel => 'Split shift';

  @override
  String get shiftTypesSplitHelper =>
      'Two parts on the same day, with an unpaid break in between that doesn’t count as worked.';

  @override
  String get shiftTypesSplitTemplate => 'Use “Split 09–13 / 17–21”';

  @override
  String get shiftTypesSplitSecondTitle => 'Second part';

  @override
  String get shiftTypesPickSecondStart => 'Part 2 start';

  @override
  String get shiftTypesPickSecondEnd => 'Part 2 end';

  @override
  String shiftTypesSplitSummary(String first, String second, String total) {
    return 'You work $first and $second: $total in total';
  }

  @override
  String get shiftTypesErrorSplitIncomplete =>
      'Set when the second part starts and ends, or turn off the split shift.';

  @override
  String get shiftTypesErrorSplitStart =>
      'The start time of the second part isn’t valid.';

  @override
  String get shiftTypesErrorSplitDuration =>
      'The second part has to last between 1 minute and 24 h.';

  @override
  String get shiftTypesErrorSplitNotAfter =>
      'The second part can’t start right when the first one ends: that would be a single part. Leave a break between them.';

  @override
  String get shiftTypesErrorSplitTooLong =>
      'The two parts and the break between them don’t fit in 24 h. Check that the second one starts after the first one ends.';

  @override
  String get shiftTypesBreakLabel => 'Unpaid break';

  @override
  String get shiftTypesBreakUnit => 'min';

  @override
  String get shiftTypesBreakHint => '0 min';

  @override
  String get shiftTypesRateHint => 'No rate';

  @override
  String get shiftTypesBreakHelper =>
      'Minutes of the shift that aren’t paid. Leave it empty if all of it is paid.';

  @override
  String shiftTypesPaidHelper(String duration) {
    return '$duration paid';
  }

  @override
  String get shiftTypesNightLabel => 'Night shift';

  @override
  String get shiftTypesNightHelper =>
      'Automatic counts the hours between 22:00 and 06:00 as night hours.';

  @override
  String get shiftTypesNightAuto => 'Automatic';

  @override
  String get shiftTypesNightAlways => 'Always night';

  @override
  String get shiftTypesNightNever => 'Never night';

  @override
  String get shiftTypesFixedPlusLabel => 'Shift allowance (optional)';

  @override
  String get shiftTypesFixedPlusHelper => 'Added once for each shift worked.';

  @override
  String get shiftTypesFixedPlusHint => 'No allowance';

  @override
  String get shiftTypesFixedPlusUnit => '€';

  @override
  String get shiftTypesRateLabel => 'Hourly rate (optional)';

  @override
  String get shiftTypesRateHelper =>
      'To work out how much you earn in the monthly summary.';

  @override
  String get shiftTypesRateUnit => '€/h';

  @override
  String get shiftTypesPreviewLabel => 'How it will look in the month';

  @override
  String get shiftTypesPreviewLight => 'Light';

  @override
  String get shiftTypesPreviewDark => 'Dark';

  @override
  String shiftTypesPreviewContrast(String ratio) {
    return 'Contrast $ratio:1';
  }

  @override
  String get shiftTypesErrorCodeEmpty => 'Type a code of 1 to 3 characters';

  @override
  String get shiftTypesErrorCodeTooLong =>
      'The code takes up to 3 characters, with no emojis or spaces';

  @override
  String shiftTypesErrorCodeTaken(String name) {
    return '“$name” already uses this code';
  }

  @override
  String get shiftTypesErrorNameEmpty => 'Give the shift a name';

  @override
  String get shiftTypesErrorBreak =>
      'The break has to be shorter than the shift';

  @override
  String get shiftTypesErrorRate => 'Type a valid amount, for example 12.50';

  @override
  String get paintFab => 'Paint';

  @override
  String get paintHeader => 'Painting';

  @override
  String paintHeaderShift(String name, String times) {
    return '$name · $times';
  }

  @override
  String get paintDone => 'Done';

  @override
  String get paintDouble => 'Double';

  @override
  String get paintEraser => 'Erase';

  @override
  String get paintToolsLabel => 'Painting tools';

  @override
  String get selectionHeader => 'Selection';

  @override
  String get selectionHint =>
      'Tap days, or touch and hold and drag to pick several';

  @override
  String selectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'No days',
    );
    return '$_temp0';
  }

  @override
  String get selectionBarLabel => 'Actions for the selected days';

  @override
  String get selectionSetShift => 'Set shift…';

  @override
  String get selectionDouble => 'Double with…';

  @override
  String get selectionClear => 'Clear';

  @override
  String get selectionReset => 'Back to the pattern';

  @override
  String get selectionCopy => 'Copy';

  @override
  String get selectionCut => 'Cut';

  @override
  String get selectionPaste => 'Paste';

  @override
  String get selectionRepeat => 'Repeat…';

  @override
  String get selectionNote => 'Note…';

  @override
  String get selectionCancel => 'Cancel';

  @override
  String get selectionCellSelected => 'selected';

  @override
  String get selectionSetShiftTitle => 'Set shift';

  @override
  String get selectionSetShiftHelp =>
      'Replaces the shifts of the selected days.';

  @override
  String get selectionDoubleTitle => 'Add a second shift';

  @override
  String get selectionDoubleHelp =>
      'Adds the shift to whatever the selected days already have.';

  @override
  String get selectionNoteTitle => 'Note for the selected days';

  @override
  String get selectionNoteHint => 'The same note on every day';

  @override
  String get selectionNoteSave => 'Save note';

  @override
  String get selectionNoteRemove => 'Remove notes';

  @override
  String get selectionPasteTitle => 'Paste days';

  @override
  String selectionPasteSummary(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days are pasted',
      one: '1 day is pasted',
    );
    return '$_temp0 starting $date.';
  }

  @override
  String selectionPasteReach(String from, String to) {
    return 'It will be pasted from $from to $to.';
  }

  @override
  String get selectionPasteReplaces =>
      'The shifts on those days are replaced. You can undo it.';

  @override
  String get selectionIncludeNotes => 'Include notes';

  @override
  String get selectionIncludeNotesHelp =>
      'The notes of the copied days replace the ones on the target days.';

  @override
  String get selectionCutNotesMove => 'When you cut, notes move with the days.';

  @override
  String get selectionPasteConfirm => 'Paste';

  @override
  String get selectionRepeatTitle => 'Repeat the selected days';

  @override
  String selectionRepeatTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get selectionRepeatLess => 'One time less';

  @override
  String get selectionRepeatMore => 'One time more';

  @override
  String selectionRepeatPreview(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Changes $count more days, until $date.',
      one: 'Changes 1 more day, until $date.',
    );
    return '$_temp0';
  }

  @override
  String get selectionRepeatConfirm => 'Repeat';

  @override
  String selectionChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days changed',
      one: '1 day changed',
    );
    return '$_temp0';
  }

  @override
  String get selectionNothingChanged => 'Those days were already like that';

  @override
  String selectionCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days copied',
      one: '1 day copied',
    );
    return '$_temp0. Pick the start day and tap Paste.';
  }

  @override
  String selectionCutDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days cut',
      one: '1 day cut',
    );
    return '$_temp0. Pick the start day and tap Paste.';
  }

  @override
  String selectionPasted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days pasted',
      one: '1 day pasted',
    );
    return '$_temp0';
  }

  @override
  String selectionRepeated(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: '$times times',
      one: 'once',
    );
    return 'Repeated $_temp0';
  }

  @override
  String get selectionRunsTitle => 'My rotations';

  @override
  String get selectionRunsSubtitle => 'End or remove a pattern in one go';

  @override
  String get selectionRunsEmptyTitle => 'No rotations';

  @override
  String get selectionRunsEmptyMessage =>
      'When you apply a pattern from Paint, it will show up here.';

  @override
  String selectionRunsRange(String from, String to) {
    return 'From $from to $to';
  }

  @override
  String selectionRunsOpenEnded(String from) {
    return 'From $from, no end date';
  }

  @override
  String selectionRunsStep(int day) {
    return 'Starts on day $day of the cycle';
  }

  @override
  String get selectionRunsActive => 'Running';

  @override
  String get selectionRunsFuture => 'Hasn’t started yet';

  @override
  String get selectionRunsEnded => 'Ended';

  @override
  String get selectionRunsEnd => 'End here';

  @override
  String get selectionRunsEndHelp => 'First day without the rotation';

  @override
  String selectionRunsEndDone(String date) {
    return 'The rotation ends on $date';
  }

  @override
  String get selectionRunsDelete => 'Delete';

  @override
  String selectionRunsDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get selectionRunsDeleteBody =>
      'It’s removed from the whole calendar. Days you changed by hand and notes stay as they are. You can undo it.';

  @override
  String get selectionRunsDeleted => 'Rotation deleted';

  @override
  String get agendaTitle => 'Agenda';

  @override
  String get agendaOpenTooltip => 'Notes agenda';

  @override
  String get agendaSearchHint => 'Search notes and shifts';

  @override
  String get agendaSearchHintShort => 'Search';

  @override
  String get agendaModeNotes => 'Notes';

  @override
  String get agendaModeShifts => 'Shifts';

  @override
  String get agendaSearchScope =>
      'Searches all your notes and custom holidays, and your shifts from a year ago to a year from now. Dates work too: 15/10 or 15 Oct.';

  @override
  String get agendaSearchClear => 'Clear search';

  @override
  String get agendaEmptyTitle => 'No upcoming notes';

  @override
  String get agendaEmptyMessage =>
      'Notes and custom holidays for the coming days will show up here.';

  @override
  String get agendaNoResultsTitle => 'Nothing found';

  @override
  String agendaNoResultsMessage(String query) {
    return 'No notes or shifts match “$query”.';
  }

  @override
  String agendaHoliday(String name) {
    return 'Public holiday: $name';
  }

  @override
  String agendaTruncated(int count) {
    return 'Showing the first $count results. Type a bit more to narrow it down.';
  }

  @override
  String agendaResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String agendaSemanticsNote(String note) {
    return 'note: $note';
  }

  @override
  String get patternButton => 'Pattern';

  @override
  String get patternTitle => 'Apply pattern';

  @override
  String patternStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get patternStepChoose => 'Choose a pattern';

  @override
  String get patternStepStart => 'When do you start?';

  @override
  String get patternStepEnd => 'Until when?';

  @override
  String get patternNext => 'Next';

  @override
  String get patternBack => 'Back';

  @override
  String get patternApply => 'Apply';

  @override
  String get patternApplied => 'Pattern applied';

  @override
  String get patternApplyFailed => 'Couldn’t apply the pattern';

  @override
  String patternFromDay(String date) {
    return 'From $date';
  }

  @override
  String get patternGroupHealth => 'Healthcare';

  @override
  String get patternGroupPolice => 'Police and Guardia Civil';

  @override
  String get patternGroupFirefighters => 'Firefighters';

  @override
  String get patternGroupIndustry => 'Industry';

  @override
  String get patternGroupSecurity => 'Security';

  @override
  String get patternGroupOther => 'Other';

  @override
  String get patternGroupMine => 'My patterns';

  @override
  String patternGroupTypical(String shift) {
    return 'Starting with $shift';
  }

  @override
  String patternGroupIncluding(String shift) {
    return 'Including $shift';
  }

  @override
  String patternCycleDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get patternCreateOwn => 'Create my own';

  @override
  String get patternCreateOwnHint => 'Build your sequence day by day';

  @override
  String get patternBuilderBack => 'Choose a pattern from the list';

  @override
  String get patternBuilderName => 'Pattern name';

  @override
  String get patternBuilderDefaultName => 'My pattern';

  @override
  String get patternBuilderSequence => 'Your sequence';

  @override
  String get patternBuilderEmpty => 'Tap the shifts below to add days.';

  @override
  String get patternBuilderSameDay => 'Several shifts in one day';

  @override
  String get patternBuilderSameDayHint =>
      'On: each shift you tap is added to the last day of the sequence instead of making a new day.';

  @override
  String get patternBuilderRemoveLast => 'Remove the last one';

  @override
  String get patternBuilderClear => 'Clear the sequence';

  @override
  String patternBuilderAdd(String name) {
    return 'Add $name';
  }

  @override
  String get patternStartLabel => 'Start day';

  @override
  String patternSuggestedStart(String weekday) {
    return 'This pattern usually starts on a $weekday.';
  }

  @override
  String get patternWeekdayMonday => 'Monday';

  @override
  String get patternWeekdayTuesday => 'Tuesday';

  @override
  String get patternWeekdayWednesday => 'Wednesday';

  @override
  String get patternWeekdayThursday => 'Thursday';

  @override
  String get patternWeekdayFriday => 'Friday';

  @override
  String get patternWeekdaySaturday => 'Saturday';

  @override
  String get patternWeekdaySunday => 'Sunday';

  @override
  String get patternOffsetTitle =>
      'Which day of the cycle are you on that day?';

  @override
  String patternOffsetHelp(String date) {
    return 'Tap the day of the pattern you’re on on $date.';
  }

  @override
  String patternOffsetThatDay(String shifts) {
    return 'That day you’re on: $shifts';
  }

  @override
  String patternChipDay(int day, String shifts) {
    return 'Day $day: $shifts';
  }

  @override
  String get patternEndNever => 'No end';

  @override
  String get patternEndNeverHint => 'It repeats until you change it.';

  @override
  String get patternEndUntil => 'Until a date';

  @override
  String get patternEndUntilHint =>
      'After that date, what you had before comes back.';

  @override
  String get patternUntilLabel => 'Last day';

  @override
  String get patternOverridesTitle => 'Days you’ve already changed by hand';

  @override
  String get patternOverridesKeep => 'Keep the days I’ve changed by hand';

  @override
  String get patternOverridesKeepHint =>
      'Your changes stay; the pattern fills in the rest.';

  @override
  String get patternOverridesReplace => 'Replace them with the pattern';

  @override
  String get patternOverridesReplaceHint =>
      'Your manual changes on those dates are deleted. Notes stay.';

  @override
  String get patternPreviewTitle => 'How it will look';

  @override
  String get patternPreviewNone => 'Choose a pattern to see how it looks.';

  @override
  String patternPreviewPostNight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Automatic post-night: $count days after a night.',
      one: 'Automatic post-night: 1 day after a night.',
    );
    return '$_temp0';
  }

  @override
  String get patternPickBanner => 'Tap the day the pattern starts';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String onboardingProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingProfessionTitle => 'What do you do?';

  @override
  String get onboardingProfessionHelp =>
      'We’ll set up the shifts and rotations of your job. You can change it whenever you like.';

  @override
  String get onboardingProfessionNursing =>
      'Nursing, nursing assistants and porters';

  @override
  String get onboardingProfessionNursingHint =>
      'M 08–15, A 15–22, N 22–08 and post-night';

  @override
  String get onboardingProfessionMedicine => 'Medicine (24-hour shifts)';

  @override
  String get onboardingProfessionMedicineHint =>
      'Morning, 24-hour shift and post-call';

  @override
  String get onboardingProfessionPolice => 'Police and Guardia Civil';

  @override
  String get onboardingProfessionPoliceHint => 'M 07–15, A 15–23 and N 23–07';

  @override
  String get onboardingProfessionFirefighters => 'Firefighters';

  @override
  String get onboardingProfessionFirefightersHint =>
      '24-hour shifts and long rest periods';

  @override
  String get onboardingProfessionIndustry => 'Industry';

  @override
  String get onboardingProfessionIndustryHint =>
      'Rotating shifts: M 06–14, A 14–22 and N 22–06';

  @override
  String get onboardingProfessionSecurity => 'Private security';

  @override
  String get onboardingProfessionSecurityHint => '12-hour day and night shifts';

  @override
  String get onboardingProfessionHospitality => 'Hospitality and retail';

  @override
  String get onboardingProfessionHospitalityHint => 'M 08–16 and A 16–00';

  @override
  String get onboardingProfessionOther => 'Other';

  @override
  String get onboardingProfessionOtherHint => 'You start with the usual shifts';

  @override
  String get onboardingPlaceTitle => 'Where do you work?';

  @override
  String get onboardingPlaceHelp =>
      'So we can mark the public holidays of your region and your town on the calendar.';

  @override
  String get onboardingRegionLabel => 'Region';

  @override
  String get onboardingRegionPick => 'Choose region';

  @override
  String get onboardingRegionSheetTitle => 'Your region';

  @override
  String get onboardingMunicipalityLabel => 'Town (optional)';

  @override
  String get onboardingMunicipalityPick => 'Search town';

  @override
  String get onboardingMunicipalityNeedsRegion => 'Choose the region first';

  @override
  String get onboardingMunicipalitySheetTitle => 'Your town';

  @override
  String get onboardingMunicipalitySearch => 'Type the name';

  @override
  String get onboardingMunicipalityNone => 'No town has that name';

  @override
  String get onboardingMunicipalityClear => 'Remove town';

  @override
  String get onboardingLocalHolidaysMissing =>
      'You can add your town’s local holidays yourself in two taps.';

  @override
  String get onboardingRotationTitle => 'What’s your rotation like?';

  @override
  String get onboardingRotationHelp =>
      'Choose the closest one. Then you say when you start.';

  @override
  String get onboardingRotationTypical => 'Usual in your job';

  @override
  String get onboardingRotationOthers => 'Other rotations';

  @override
  String get onboardingRotationAll => 'Rotations';

  @override
  String get onboardingByHand => 'I’ll paint it by hand';

  @override
  String get onboardingByHandHint =>
      'No rotation: you paint the days on the calendar yourself.';

  @override
  String get onboardingStartTitle => 'When do you start?';

  @override
  String get onboardingStartHelp =>
      'Say which day it counts from and where in the cycle you are on that day.';

  @override
  String get onboardingImportTitle => 'Coming from another app?';

  @override
  String get onboardingImportBody =>
      'If you kept your shifts in LRHSoft (Shifter), Supershift or another app, bring them over from its backup, your phone’s calendar or a file. You can also do it later, in Settings.';

  @override
  String get onboardingReadyTitle => 'All set';

  @override
  String get onboardingReadyBody =>
      'Your calendar is ready. You can change all of this whenever you like in Settings.';

  @override
  String onboardingReadyProfession(String name) {
    return 'Job: $name';
  }

  @override
  String onboardingReadyPlace(String place) {
    return 'Public holidays: $place';
  }

  @override
  String onboardingReadyRotation(String name, String date) {
    return 'Rotation: $name, from $date';
  }

  @override
  String onboardingReadyOffset(int day, String shifts) {
    return 'You start on day $day of the cycle ($shifts)';
  }

  @override
  String get onboardingReadyByHand => 'Rotation: you paint it by hand';

  @override
  String get onboardingReadyNothing =>
      'You didn’t choose anything, so you start with a blank calendar.';

  @override
  String get onboardingReadySaveFailed =>
      'Not everything could be saved. Check your shifts and public holidays in Settings.';

  @override
  String get onboardingOpenCalendar => 'See my calendar';

  @override
  String get onboardingTipTitle => 'Paint your month in no time';

  @override
  String get onboardingTipBody =>
      'Tap Paint, choose a shift and drag across the days. With the Pattern button you repeat a whole rotation in one go.';

  @override
  String get onboardingTipDismiss => 'Got it';

  @override
  String get onboardingTipClose => 'Close the tip';

  @override
  String get paintScrollUp => 'Scroll month up';

  @override
  String get paintScrollDown => 'Scroll month down';

  @override
  String get monthTipPaint => 'Pick a shift and drag.';

  @override
  String get postNightAutoTitle => 'Automatic post-night';

  @override
  String get postNightAutoHelp =>
      'After a night, the next day becomes Post-night if it was empty or off.';

  @override
  String get yearTitle => 'Year view';

  @override
  String get yearOpenTooltip => 'See the year';

  @override
  String get yearPrevious => 'Previous year';

  @override
  String get yearNext => 'Next year';

  @override
  String get yearShare => 'Share as image';

  @override
  String yearShareSubject(int year) {
    return 'My shifts in $year';
  }

  @override
  String get yearShareFailed => 'Couldn’t share the image';

  @override
  String yearImageTitle(int year) {
    return 'My shifts $year';
  }

  @override
  String get yearMonthEmpty => 'no shifts';

  @override
  String get yearLegendTitle => 'Shifts of the year';

  @override
  String get yearLegendEmpty => 'This year has no shifts.';

  @override
  String yearLegendDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get yearLegendHoliday => 'Public holiday';

  @override
  String get summaryTitle => 'Summary';

  @override
  String get summaryOpenTooltip => 'Monthly summary';

  @override
  String get summaryModeMonth => 'Month';

  @override
  String get summaryModeYear => 'Year';

  @override
  String get summaryModeRange => 'Dates…';

  @override
  String get summaryRangeFrom => 'From';

  @override
  String get summaryRangeTo => 'To';

  @override
  String get summaryRangePrevious => 'Previous period';

  @override
  String get summaryRangeNext => 'Next period';

  @override
  String summaryRangeDays(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days in total',
      one: '1 day in total',
    );
    return '$_temp0. You can choose up to $max.';
  }

  @override
  String summaryRangeClamped(int max) {
    return 'The maximum is $max days: we’ve moved the end date earlier.';
  }

  @override
  String summaryRangePreviousName(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'the previous $days days',
      one: 'the previous day',
    );
    return '$_temp0';
  }

  @override
  String get summaryRangeEmptyTitle => 'No shifts on these dates';

  @override
  String get summaryRangeEmptyBody =>
      'Choose other dates or paint shifts on the calendar.';

  @override
  String get summaryRangeNoteMidnight =>
      'The hours of a shift that crosses midnight count on the day it starts, even if it’s the last day of the dates.';

  @override
  String get summaryEmptyTitle => 'No shifts this month';

  @override
  String get summaryEmptyBody =>
      'Paint shifts on the calendar and you’ll see the hours and the estimate here.';

  @override
  String get summaryHoursWorked => 'Hours worked';

  @override
  String get summaryShiftsWorked => 'Shifts worked';

  @override
  String get summaryNightHours => 'Night hours';

  @override
  String get summaryRestDays => 'Days off';

  @override
  String get summaryAbsences => 'Absences';

  @override
  String get summaryHolidayHours => 'Hours on public holidays';

  @override
  String summaryHolidayDetail(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts on public holidays',
      one: '1 shift on a public holiday',
    );
    return '$_temp0';
  }

  @override
  String get summaryOvertime => 'Overtime';

  @override
  String get summaryEarlyLeave => 'Early leaves';

  @override
  String summaryExtrasPay(String amount) {
    return '$amount in the estimate';
  }

  @override
  String get summaryExtrasNoRate =>
      'There’s overtime or early leave on days without a shift with an hourly rate: it isn’t in the estimate.';

  @override
  String get summaryNoteExtras =>
      'Overtime and early leave: what you log on each day. Overtime adds to and early leave takes from the hours worked (a day never goes below 0 h). They’re valued at the hourly rate of the first shift with a rate that day.';

  @override
  String summaryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String summaryShifts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts',
      one: '1 shift',
    );
    return '$_temp0';
  }

  @override
  String summaryNightOf(String hours) {
    return '$hours at night';
  }

  @override
  String get summaryNoTimes => 'no times';

  @override
  String get summaryNoRate => 'no rate';

  @override
  String get summaryGroupWork => 'Work shifts';

  @override
  String get summaryGroupRest => 'Rest days';

  @override
  String get summaryEstimateTitle => 'Estimated earnings';

  @override
  String get summaryFixedPluses => 'Allowances';

  @override
  String summaryFixedPlusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts',
      one: '1 shift',
    );
    return '$_temp0';
  }

  @override
  String get summaryEstimateNote => 'Estimate, before tax';

  @override
  String get summaryEstimateNone =>
      'Set an hourly rate or a fixed allowance in My shifts to see the estimate.';

  @override
  String summaryEstimateMissing(String types) {
    return 'Excludes hourly pay for $types: no rate.';
  }

  @override
  String get summaryRateAction => 'Set rates in My shifts';

  @override
  String summaryDelta(String delta, String month) {
    return '$delta compared with $month';
  }

  @override
  String summaryDeltaSame(String month) {
    return 'Same hours as in $month';
  }

  @override
  String summaryDeltaNone(String month) {
    return 'No shifts in $month to compare';
  }

  @override
  String get summaryNotesTitle => 'How it’s counted';

  @override
  String get summaryNoteMidnight =>
      'The hours of a shift that crosses midnight count on the day and in the month it starts.';

  @override
  String get summaryNoteNight =>
      'Night hours: from 22:00 to 06:00, unless you set something else in the shift.';

  @override
  String get summaryNoteDst =>
      'These are clock hours: on the night the clocks change, it isn’t adjusted to 7 or 9 hours.';

  @override
  String get summaryNoteNoTimes =>
      'Shifts without times count as a shift, but add no hours.';

  @override
  String get summaryNoteHoliday =>
      'Hours on public holidays: those that fall on a public holiday of your region and town, even if the shift crosses midnight.';

  @override
  String get summaryYearEmpty => 'This year has no shifts.';

  @override
  String get summaryYearHint => 'Tap a month to see its details.';

  @override
  String get summaryYearHeaderMonth => 'Month';

  @override
  String get summaryYearHeaderShifts => 'Shifts';

  @override
  String get summaryYearHeaderHours => 'Hours';

  @override
  String get summaryYearHeaderNight => 'Night';

  @override
  String get summaryYearHeaderEstimate => 'Estimate';

  @override
  String get summaryYearTotal => 'Total';

  @override
  String summaryYearEstimated(String amount) {
    return '$amount estimated';
  }

  @override
  String get summaryYearMonthEmpty => 'No shifts';

  @override
  String get summaryYearRowTitle => 'Hours and estimate';

  @override
  String get summaryYearRowBody => 'Shifts, hours and euros for each month';

  @override
  String summaryYearMonthSemantics(String month, String shifts, String hours) {
    return '$month: $shifts, $hours';
  }

  @override
  String get shareMonthTooltip => 'Share the month as an image';

  @override
  String shareMonthSubject(String month) {
    return 'My shifts in $month';
  }

  @override
  String get shareMonthFailed => 'Couldn’t share the image';

  @override
  String get shareMonthLegendTitle => 'Shifts of the month';

  @override
  String get shareMonthLegendEmpty => 'This month has no shifts.';

  @override
  String get saveFailed => 'Couldn’t save the change';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsOpenTooltip => 'Open settings';

  @override
  String get settingsSectionSchedule => 'Your schedule';

  @override
  String get settingsShiftsTitle => 'My shifts';

  @override
  String get settingsShiftsSubtitle => 'Colors, codes and times';

  @override
  String get settingsCalendarsTitle => 'Calendars';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsThemeTitle => 'Theme';

  @override
  String get settingsThemeSystemLight => 'System (light)';

  @override
  String get settingsThemeSystemDark => 'System (dark)';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsWeekStartTitle => 'First day of the week';

  @override
  String get settingsWeekStartMonday => 'Monday';

  @override
  String get settingsWeekStartSunday => 'Sunday';

  @override
  String get settingsWeekNumbersTitle => 'Show week numbers';

  @override
  String get settingsWeekNumbersSubtitle => 'A column on the left of the month';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String settingsLanguageSystem(String language) {
    return 'System ($language)';
  }

  @override
  String get languageNameEs => 'Español';

  @override
  String get languageNameCa => 'Català';

  @override
  String get languageNameGl => 'Galego';

  @override
  String get languageNameEu => 'Euskara';

  @override
  String get languageNameEn => 'English';

  @override
  String get settingsSaveFailed => 'Couldn’t save the setting. Try again.';

  @override
  String get settingsSectionMore => 'Alerts and data';

  @override
  String get settingsHolidaysTitle => 'Public holidays';

  @override
  String get settingsAlarmsTitle => 'Alarms';

  @override
  String get settingsBackupTitle => 'Backup';

  @override
  String get settingsPrivacyTitle => 'Privacy policy';

  @override
  String get settingsPrivacySubtitle => 'Opens in your browser';

  @override
  String get settingsPrivacyOpenFailed =>
      'Couldn’t open the privacy policy. Try again.';

  @override
  String get faqAlarmsQIos =>
      'How do I set up alarms, and what’s the notification permission?';

  @override
  String get faqAlarmsAIos =>
      'In Settings › Alarms, turn on “Alert before each shift”, choose how long before and, if you like, an alert the day before at a set time. In a day’s details you can remove its alarm with “No alarm this day”.\n\nWithout notification permission, Cuadrante can’t alert you. If the window to allow them doesn’t appear, turn them on in the system settings.';

  @override
  String get faqWidgetAIos =>
      'In Settings › Add widget you’ll see the sizes (small: today and tomorrow; medium: the next 7 days; large: the whole month) and how to place it. Touch and hold the home screen, tap the + at the top and look for Cuadrante.\n\nThe widget stores your upcoming days. The system decides when to update it and may delay the change of day. If it runs out of data, open Cuadrante to bring it up to date.';

  @override
  String get faqBackupAIos =>
      'Settings › Backup saves automatic backups on this device after each change, but they are lost if you lose it or uninstall the app. Export a file with “Export file” and save it to iCloud Drive or send it to yourself by WhatsApp or email.\n\nTo change devices: export the file, install Cuadrante on the new device, open the file with the app (or use “Import file” in Backup), and review the preview before restoring. “Test restore” checks that your latest backup can be fully recovered.';

  @override
  String get calExportPermissionDeniedBodyIos =>
      'Turn it on in the system settings (Cuadrante › Calendars) and come back here.';

  @override
  String get backupUiWarningIos =>
      'These backups are kept on this device. If you uninstall the app without another copy, it’s lost. Export a file and save it to iCloud Drive or send it by WhatsApp or email.';

  @override
  String get backupUiExportSubtitleIos =>
      'To save it to iCloud Drive or send it by WhatsApp or email';

  @override
  String get settingsSectionHelp => 'Help';

  @override
  String get settingsHelpTitle => 'Help and contact';

  @override
  String get settingsHelpSubtitle => 'Write to us if something isn’t working';

  @override
  String get settingsHelpBody =>
      'Questions, or something isn’t working? Tell us what’s happening and which version you use.';

  @override
  String get settingsHelpSubtitleSoon => 'We’re setting up the support email';

  @override
  String get settingsHelpBodySoon =>
      'We don’t have a support email yet. In the meantime, check the FAQ and, if something isn’t working, keep the version you use at hand.';

  @override
  String get settingsHelpNoEmail =>
      'The support email will arrive with the store version.';

  @override
  String get settingsHelpCopyEmail => 'Copy email';

  @override
  String get settingsHelpCopyVersion => 'Copy version';

  @override
  String get settingsFaqTitle => 'FAQ';

  @override
  String get settingsFaqSubtitle =>
      'Painting, rotations, alarms, widget and more';

  @override
  String get faqIntro =>
      'Quick answers about how Cuadrante works. Everything is on this device: no account or connection needed.';

  @override
  String get faqNotFound => 'Can’t find what you’re looking for?';

  @override
  String get faqContact => 'Help and contact';

  @override
  String get faqPaintQ => 'How do I paint the month?';

  @override
  String get faqPaintA =>
      'Tap “Paint” on the calendar, choose a shift at the bottom and tap the days or swipe across them. To empty a day, use “Erase”. Every stroke can be undone and redone with the arrows on the bar. Tap “Done” when you finish.\n\nIf you tap a day while you’re not painting, its details open: there you change the shift, add a note or go back to the pattern. If you touch and hold a day you start selecting several at once: you can set their shift, copy, cut and paste them, or repeat a week.';

  @override
  String get faqPatternQ => 'How do I apply a rotation, and what’s the offset?';

  @override
  String get faqPatternA =>
      'In paint mode, tap the “Pattern” button and follow the steps: choose your rotation (or create your own), the day you start and until when it repeats.\n\nThe offset is where in the cycle you are on the start day. If you’re on nights that day, in the step “Which day of the cycle are you on that day?” you tap the night and the rest adjusts itself. Days you’ve already changed by hand are kept or replaced, as you prefer. To end or remove a rotation, go to Settings › My rotations.';

  @override
  String get faqDoubleQ => 'How do I work a double shift?';

  @override
  String get faqDoubleA =>
      'A double is working two shifts on the same day. Tap the day and, in its details, use “Add a second shift”. If you’re painting, turn on “Double” and tap the days. With several days selected, “Double with…” adds the shift to all of them.\n\nA day can have as many shifts as you need, and each one adds its own hours.';

  @override
  String get faqPostNightQ => 'What’s the automatic post-night?';

  @override
  String get faqPostNightA =>
      'It’s the rest on the day after a night. If you turn it on in Settings › Automatic post-night, when you paint or apply a night, the next day becomes Post-night if it was empty or off. Days that already had another shift aren’t touched. It’s off by default.';

  @override
  String get faqNotesQ => 'How do I use notes and the agenda?';

  @override
  String get faqNotesA =>
      'Tap a day and write in the note field; days with notes are marked on the calendar. Open the agenda at the top of the calendar: “Notes” lists your notes and custom holidays; “Shifts” shows upcoming shifts.\n\nSearch by text, regardless of case or accents, or by date: for example, 15/10 or Oct 15. Search covers all your notes and custom holidays, and shifts from one year ago to one year ahead.';

  @override
  String get faqAlarmsQ =>
      'How do I set up alarms, and what’s the exact alarms permission?';

  @override
  String get faqAlarmsA =>
      'In Settings › Alarms, turn on “Alert before each shift”, choose how long before and, if you like, an alert the day before at a set time. In a day’s details you can remove its alarm with “No alarm this day”.\n\nOn Android you need notifications and the “Alarms & reminders” permission in the system settings: without it, Android may delay the alert by a few minutes. The alarms screen tells you what’s missing and takes you to the settings. If your phone saves battery aggressively, set Cuadrante to unrestricted so it doesn’t stop the alerts.';

  @override
  String get faqHolidaysQ => 'How do I add a local holiday?';

  @override
  String get faqHolidaysA =>
      'In Settings › Holidays, choose your region and town to see the holidays that apply to you. If a local holiday is missing, tap that day on the calendar and turn on “Custom holiday”: give it a name and it counts as a holiday from then on.\n\nYou can also bring in holidays from your phone calendar in Settings › Holidays. Choose calendars and dates and review the preview: only all-day events are read, holidays you already have are skipped, and you can undo. Calendar events are never changed.';

  @override
  String get faqWidgetQ =>
      'How do I add the widget, and why does it change by itself?';

  @override
  String get faqWidgetA =>
      'In Settings › Add widget you’ll see the sizes (small: today and tomorrow; medium: the next 7 days; large: the whole month) and how to place it. On Android, touch and hold an empty area of the home screen, choose Widgets and look for Cuadrante.\n\nThe widget always shows today: it moves to the next day at midnight even if you don’t open the app, because it keeps your upcoming days stored. If you go a long time without opening Cuadrante, it runs out of data and asks you to open the app to catch up.';

  @override
  String get faqBackupQ => 'How do I back up and change devices?';

  @override
  String get faqBackupA =>
      'Settings › Backup saves automatic backups on this device after each change, but they are lost if you lose it or uninstall the app. Export a file with “Export file” and save it to Drive or send it to yourself by WhatsApp or email.\n\nTo change devices: export the file, install Cuadrante on the new device, open the file with the app (or use “Import file” in Backup), and review the preview before restoring. “Test restore” checks that your latest backup can be fully recovered.';

  @override
  String get faqImportQ =>
      'Can I import my shifts or export them to the calendar?';

  @override
  String get faqImportA =>
      'Yes. In Settings › Import shifts, you can bring in an LRHSoft «.Shifter» backup, shifts from your phone calendar, an .ics file or a CSV. In LRHSoft, create a backup in Menu › Backup › Local backup, then choose the file from Documents › ShifterBackups. Check the dates, shift types and preview before importing.\n\n“Export to phone calendar” copies your shifts once to a phone calendar. Exporting again does not duplicate them: only events created by Cuadrante are changed.';

  @override
  String get faqCalendarsQ => 'Can I keep several calendars and compare them?';

  @override
  String get faqCalendarsA =>
      'Yes. In Settings › Calendars you create one for your partner, a second job or a child: each one has its own rotations and days, and the shift types are shared. With two or more, the calendar name above the month lets you switch between them. The widget and the alarms follow the calendar marked “Widget and alarms”.\n\nTo see when you’re both off, tap “Compare calendars” on that same sheet: you choose two and see their shifts together and the days off you share in the month.';

  @override
  String get faqSummaryQ => 'How are hours and earnings calculated?';

  @override
  String get faqSummaryA =>
      'The summary icon on the calendar shows the shifts, hours, night hours and public holiday hours of the month, a whole year or the dates you choose in “Dates…” (up to 366 days). A shift counts on the day it starts, even if it crosses midnight.\n\nTo see euros, set each shift type’s hourly rate and, if you have one, fixed allowance in Settings › My shifts. The estimate includes those fixed allowances, before tax. It excludes allowances per night or public holiday hour and deductions.\n\n“Shift allowance” is added once for each worked shift of that type, including split shifts; it does not depend on the hours. Rest days and absences do not add it.';

  @override
  String get settingsVersionCopied => 'Version copied';

  @override
  String get settingsEmailCopied => 'Email copied';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String settingsAboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsAboutVersionDev => 'Development version';

  @override
  String get settingsAboutTagline =>
      'Cuadrante works offline and without an account: your shifts stay on your phone.';

  @override
  String get settingsAboutLicenses => 'Open source licenses';

  @override
  String calendarWeekNumberSemantics(int number) {
    return 'Week $number';
  }

  @override
  String get importSectionTitle => 'Import and export';

  @override
  String get importRowTitle => 'Import shifts';

  @override
  String get importRowSubtitle => 'LRHSoft backup, phone calendar, .ics or CSV';

  @override
  String get calExportRowTitle => 'Export shifts';

  @override
  String get calExportRowSubtitle => 'To the phone calendar, no duplicates';

  @override
  String get importTitle => 'Import shifts';

  @override
  String importStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get importNext => 'Next';

  @override
  String get importReading => 'Reading…';

  @override
  String get importSourceTitle => 'Where are your shifts coming from?';

  @override
  String get importSourceHelp =>
      'Cuadrante reads the events right here, on your phone, and doesn’t send them anywhere. You decide what gets imported.';

  @override
  String get importSourceDevice => 'Phone calendar';

  @override
  String get importSourceDeviceHelp =>
      'Google, iCloud, Outlook… whatever you have in your calendar app.';

  @override
  String get importSourceIcs => '.ics file';

  @override
  String get importSourceIcsHelp =>
      'An exported calendar, with one shift per event.';

  @override
  String get importSourceCsv => 'CSV file';

  @override
  String get importSourceCsvHelp =>
      'A sheet with a date and a shift on each row.';

  @override
  String get importSourceLrhsoft => 'LRHSoft backup (Work Shift Calendar)';

  @override
  String get importSourceLrhsoftHelp =>
      'The .Shifter file from your local backup';

  @override
  String get importFileLrhsoft => 'LRHSoft backup';

  @override
  String get importHowToTitle => 'Coming from LRHSoft or Supershift?';

  @override
  String get importHowToBody =>
      'LRHSoft or Shifter: in the app, Menu › Calendar backup › Local backup. Then choose that .Shifter file here: it is in your phone’s storage, under Documents › ShifterBackups.\nSupershift: export your shifts to your phone’s calendar and choose “Phone calendar”.';

  @override
  String get calExportPermissionTitle => 'Calendar permission needed';

  @override
  String get calExportPermissionReadBody =>
      'To import, Cuadrante needs to read the events in your calendars. It only does so now, while you import, and doesn’t keep anything outside your phone.';

  @override
  String get calExportPermissionWriteBody =>
      'To add your shifts, Cuadrante needs access to your calendars. It only adds or changes its own events, and only when you export. If the calendar you choose syncs with an account (Google, iCloud...), that account will also get the shifts.';

  @override
  String get calExportPermissionAgainBody =>
      'You haven’t granted permission. Without it we can’t use your calendars, but you can allow it now. If you decline again, you’ll have to turn it on in the system settings.';

  @override
  String get calExportPermissionAllow => 'Allow access';

  @override
  String get calExportPermissionDeniedTitle => 'Calendar access is turned off';

  @override
  String get calExportPermissionDeniedBody =>
      'Turn it on in the system settings (Permissions › Calendar) and come back here.';

  @override
  String get calExportPermissionSettings => 'Open settings';

  @override
  String get calExportPermissionRecheck => 'Check again';

  @override
  String get calExportPermissionRestrictedTitle =>
      'This phone doesn’t allow using the calendar';

  @override
  String get calExportPermissionRestrictedBody =>
      'It may be parental controls or a work profile. If you’re importing, try an .ics file.';

  @override
  String get calExportPermissionWriteOnlyBody =>
      'The system only gave permission to add events. Cuadrante needs full access to read calendars or to replace the events of an earlier export.';

  @override
  String get importCalendarsTitle => 'Choose the calendars';

  @override
  String get importCalendarsHelp =>
      'Mark where your shifts come from. The others aren’t touched.';

  @override
  String get importCalendarsEmpty => 'There are no calendars on this phone.';

  @override
  String get importCalendarsNoAccount => 'No account';

  @override
  String get importCalendarsReadOnly => 'Read-only';

  @override
  String importCalendarSemantics(String name, String account) {
    return '$name, $account';
  }

  @override
  String get importRangeTitle => 'Which dates?';

  @override
  String get importRangeHelp => 'Only events on these days are looked at.';

  @override
  String get importRangeFrom => 'From';

  @override
  String get importRangeTo => 'To';

  @override
  String get importRangeDefault => 'Last 12 months and next 6';

  @override
  String get importRangeInvalid =>
      'The end date can’t be before the start date.';

  @override
  String get importRangeClamped =>
      'The maximum is 5 years: the start has been cut.';

  @override
  String importRangeFile(String name) {
    return 'File: $name';
  }

  @override
  String importRangeFileEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The file has $count events.',
      one: 'The file has 1 event.',
    );
    return '$_temp0';
  }

  @override
  String importRangeFileSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events don’t have a valid date and won’t be read.',
      one: '1 event doesn’t have a valid date and won’t be read.',
    );
    return '$_temp0';
  }

  @override
  String importRangeFileRules(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count events have a repeat we don’t understand and count only once.',
      one: '1 event has a repeat we don’t understand and counts only once.',
    );
    return '$_temp0';
  }

  @override
  String get importColumnsTitle => 'What’s in each column?';

  @override
  String get importColumnsHelp =>
      'Look at the first rows and confirm which one is the date and which one the shift.';

  @override
  String get importColumnsHeader => 'The first row has the headings';

  @override
  String get importColumnDate => 'Date';

  @override
  String get importColumnTitle => 'Shift or code';

  @override
  String get importColumnStart => 'Start time (optional)';

  @override
  String get importColumnEnd => 'End time (optional)';

  @override
  String get importColumnNone => 'None';

  @override
  String importColumnNumber(int number) {
    return 'Column $number';
  }

  @override
  String importColumnNamed(int number, String name) {
    return '$number: $name';
  }

  @override
  String get importColumnsScrollHint =>
      'Swipe sideways to see all the columns.';

  @override
  String get importColumnsPreview => 'First rows';

  @override
  String get importMappingTitle => 'Which shift does each title match?';

  @override
  String get importMappingHelp =>
      'We group the events by title. Choose one of your shifts, create a new one or ignore them.';

  @override
  String importMappingSummary(int days, int groups) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    String _temp1 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups titles',
      one: '1 title',
    );
    return '$_temp0 in $_temp1';
  }

  @override
  String importMappingTruncated(String limit) {
    return 'There are more than $limit events: only the first ones have been read. Shorten the dates to see the rest.';
  }

  @override
  String importMappingSkippedRows(int count, int line) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count rows were skipped because they have no valid date or shift (for example, line $line).',
      one:
          '1 row was skipped because it has no valid date or shift (for example, line $line).',
    );
    return '$_temp0';
  }

  @override
  String get importMappingNothing => 'Choose at least one title to import.';

  @override
  String importGroupDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get importGroupAllDay => 'All day';

  @override
  String importGroupExamples(String dates) {
    return 'e.g. $dates';
  }

  @override
  String get importGroupUntitled => 'Untitled';

  @override
  String get importMapIgnore => 'Ignore';

  @override
  String get importMapCreate => 'Create new type';

  @override
  String get importMapChoose => 'Choose shift';

  @override
  String get importMapSuggested => 'Suggested';

  @override
  String importMapNew(String name) {
    return 'New: $name';
  }

  @override
  String importMapPickTitle(String title) {
    return 'Which shift is “$title”?';
  }

  @override
  String importMapSemantics(String title, String choice) {
    return '$title: $choice';
  }

  @override
  String get importNewTypeTitle => 'New shift type';

  @override
  String get importNewTypeUse => 'Use this type';

  @override
  String get importPreviewTitle => 'How it will look';

  @override
  String get importPreviewHelp =>
      'Check the months. Nothing is saved until you tap Import.';

  @override
  String importPreviewTarget(String name) {
    return 'Importing into “$name”.';
  }

  @override
  String importPreviewDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days will be written.',
      one: '1 day will be written.',
    );
    return '$_temp0';
  }

  @override
  String importPreviewUnchanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days were already the same.',
      one: '1 day was already the same.',
    );
    return '$_temp0';
  }

  @override
  String importPreviewNewTypes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new shift types will be created.',
      one: '1 new shift type will be created.',
    );
    return '$_temp0';
  }

  @override
  String get importPreviewEmpty => 'With these choices, no day changes.';

  @override
  String importPreviewMoreMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'And $count more months not shown.',
      one: 'And 1 more month not shown.',
    );
    return '$_temp0';
  }

  @override
  String importConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days already have a shift',
      one: '1 day already has a shift',
    );
    return '$_temp0';
  }

  @override
  String get importConflictsHelp => 'What should we do with them?';

  @override
  String get importConflictReplace => 'Replace';

  @override
  String get importConflictKeep => 'Keep mine';

  @override
  String importConflictsExamples(String dates) {
    return 'For example: $dates';
  }

  @override
  String importApply(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count days',
      one: 'Import 1 day',
    );
    return '$_temp0';
  }

  @override
  String importApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days imported.',
      one: '1 day imported.',
    );
    return '$_temp0';
  }

  @override
  String importAppliedWithTypes(int days, int types) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days imported',
      one: '1 day imported',
    );
    String _temp1 = intl.Intl.pluralLogic(
      types,
      locale: localeName,
      other: '$types new shift types',
      one: '1 new shift type',
    );
    return '$_temp0 and $_temp1.';
  }

  @override
  String get importUndoDone => 'The import has been undone.';

  @override
  String importUndoKeptTypes(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The types “$names” stay: something uses them.',
      one: 'The type “$names” stays: something uses it.',
    );
    return '$_temp0';
  }

  @override
  String get importApplyFailed => 'Couldn’t import. Try again.';

  @override
  String get importProblemPermissionDenied =>
      'Without the permission we can’t read your calendars.';

  @override
  String get importProblemPermissionRestricted =>
      'This phone doesn’t let Cuadrante use the calendar. Try a file.';

  @override
  String get importProblemCalendarUnavailable =>
      'This phone has no calendars available.';

  @override
  String get importProblemReadFailed => 'Couldn’t read the events. Try again.';

  @override
  String get importProblemFileTooLarge =>
      'The file is larger than 5 MB. When you export it, choose fewer dates.';

  @override
  String get importProblemFileUnreadable =>
      'We couldn’t open that file. We accept .csv, .ics and the .Shifter backup from LRHSoft.';

  @override
  String get importProblemNotCalendar =>
      'That file doesn’t look like an .ics calendar.';

  @override
  String get importProblemNotCsv =>
      'We couldn’t find a date column in that CSV.';

  @override
  String get importProblemNoEvents => 'There are no events on those dates.';

  @override
  String get importProblemTooComplex =>
      'That file is too large or complex and takes too long. When you export it, choose fewer dates.';

  @override
  String get importProblemUnknown =>
      'Something went wrong reading the file. Try another one.';

  @override
  String get importProblemNotLrhsoft =>
      'That file doesn’t look like an LRHSoft backup (.Shifter). Try making another local backup.';

  @override
  String importRangeLrhsoftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The backup has $count days.',
      one: 'The backup has 1 day.',
    );
    return '$_temp0';
  }

  @override
  String importMappingInvalidRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invalid rows ignored.',
      one: '1 invalid row ignored.',
    );
    return '$_temp0';
  }

  @override
  String get importLrhsoftNotImported =>
      'Alarms, drawings, photos and overtime aren’t brought over.';

  @override
  String importNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String importApplyNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count notes',
      one: 'Import 1 note',
    );
    return '$_temp0';
  }

  @override
  String importAppliedNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes imported.',
      one: '1 note imported.',
    );
    return '$_temp0';
  }

  @override
  String importPreviewNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes will be added.',
      one: '1 note will be added.',
    );
    return '$_temp0';
  }

  @override
  String get calExportTitle => 'Export shifts';

  @override
  String get calExportHelp =>
      'Adds your shifts as events to a calendar on your phone, once. If you do it again, Cuadrante replaces its earlier events on those dates instead of duplicating them.';

  @override
  String calExportSource(String name) {
    return 'Exporting the shifts of “$name”.';
  }

  @override
  String get calExportCalendarLabel => 'Calendar';

  @override
  String get calExportNewCalendar => 'Create the “Cuadrante” calendar';

  @override
  String get calExportNewCalendarHelp =>
      'That way you can hide it or delete it entirely whenever you like.';

  @override
  String get calExportRangeLabel => 'Dates';

  @override
  String get calExportFrom => 'From';

  @override
  String get calExportTo => 'To';

  @override
  String get calExportIncludeRest => 'Include days off';

  @override
  String get calExportIncludeRestHelp =>
      'Off and Post-night are added too, as all-day events.';

  @override
  String get calExportIncludeAbsences => 'Include absences';

  @override
  String get calExportIncludeAbsencesHelp =>
      'Vacation, sick leave and other absences. They’d be added to that calendar and to the account it syncs with.';

  @override
  String calExportSynced(String account) {
    return 'This calendar syncs with $account: your shifts will show up there.';
  }

  @override
  String get calExportSyncedUnnamed =>
      'This calendar syncs with an account: your shifts will show up there.';

  @override
  String calExportPlanAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events will be added.',
      one: '1 event will be added.',
    );
    return '$_temp0';
  }

  @override
  String calExportPlanReplace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events from an earlier export will be replaced.',
      one: '1 event from an earlier export will be replaced.',
    );
    return '$_temp0';
  }

  @override
  String calExportPlanRemove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events from an earlier export will be removed.',
      one: '1 event from an earlier export will be removed.',
    );
    return '$_temp0';
  }

  @override
  String calExportPlanSame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events are already up to date.',
      one: '1 event is already up to date.',
    );
    return '$_temp0';
  }

  @override
  String get calExportPlanNothing =>
      'Everything is up to date: nothing to change.';

  @override
  String get calExportPlanNone => 'There are no shifts on those dates.';

  @override
  String get calExportButton => 'Export';

  @override
  String calExportRunning(int done, int total) {
    return 'Exporting… $done of $total';
  }

  @override
  String get calExportDoneTitle => 'Export done';

  @override
  String get calExportDoneCalendar =>
      'The “Cuadrante” calendar has been created.';

  @override
  String calExportDoneCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events added',
      one: '1 event added',
    );
    return '$_temp0';
  }

  @override
  String calExportDoneReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count earlier events replaced',
      one: '1 earlier event replaced',
    );
    return '$_temp0';
  }

  @override
  String calExportDoneRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events removed',
      one: '1 event removed',
    );
    return '$_temp0';
  }

  @override
  String calExportDoneSame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events were already up to date',
      one: '1 event was already up to date',
    );
    return '$_temp0';
  }

  @override
  String calExportDoneFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count events couldn’t be written. Export again to complete them.',
      one: '1 event couldn’t be written. Export again to complete it.',
    );
    return '$_temp0';
  }

  @override
  String get calExportProblemPermission =>
      'Without the permission we can’t write to your calendar.';

  @override
  String get calExportProblemUnavailable =>
      'This phone has no calendars available.';

  @override
  String get calExportProblemFailed => 'Couldn’t export. Try again.';

  @override
  String get calExportRangeClamped =>
      'The maximum is one year: the end has been cut.';

  @override
  String get onboardingImportButton => 'Import now';

  @override
  String get onboardingImportLrhsoftButton => 'Import LRHSoft backup';

  @override
  String get backupUiRowSubtitle => 'Automatic, export and import';

  @override
  String get backupUiStatusNoneTitle => 'There’s no backup yet';

  @override
  String get backupUiStatusNoneBody =>
      'Make one now: it takes a second. Until you have one, if you lose this device or uninstall the app, your schedule is lost.';

  @override
  String get backupUiStatusLast => 'Last backup';

  @override
  String get backupUiStatusWhere => 'On this device';

  @override
  String get backupUiStatusRunning => 'Saving the backup…';

  @override
  String get backupUiStatusPending =>
      'There are new changes: the backup will run in a few seconds.';

  @override
  String backupUiStatusPendingAt(String time) {
    return 'There are new changes: the next backup will be made around $time. If you don’t want to wait, tap “Back up now”.';
  }

  @override
  String get backupUiStatusPendingLater =>
      'There are new changes: the next backup will be made in a few minutes. If you don’t want to wait, tap “Back up now”.';

  @override
  String get backupUiStatusFailedTitle => 'The last automatic backup failed';

  @override
  String backupUiStatusFailedWithGood(String when, String good) {
    return 'We tried $when and it couldn’t be saved. Your last good backup is from $good.';
  }

  @override
  String backupUiStatusFailedNoGood(String when) {
    return 'We tried $when and it couldn’t be saved. You don’t have a good backup yet.';
  }

  @override
  String get backupUiFailDiskFull => 'The device has no free space.';

  @override
  String get backupUiFailGeneric => 'The backup file couldn’t be written.';

  @override
  String get backupUiRetry => 'Try again';

  @override
  String get backupUiSystemOn => 'Android system backup: on';

  @override
  String get backupUiSystemOff =>
      'Android system backup: off. Turn it on in the Android settings to have another copy.';

  @override
  String get backupUiSystemUnknown =>
      'Android system backup: we can’t check it from the app. Make sure it’s on in the Android settings.';

  @override
  String get backupUiWarning =>
      'These backups are kept on this device. If you uninstall the app without another copy, it’s lost. Export a file and save it to Drive or send it by WhatsApp or email.';

  @override
  String get backupUiBackupNow => 'Back up now';

  @override
  String get backupUiBackupDone => 'Backup done';

  @override
  String get backupUiBackupFailed =>
      'Couldn’t make the backup. Your data is as it was.';

  @override
  String get backupUiAutoTitle => 'Automatic backups';

  @override
  String get backupUiAutoOn =>
      'After you change something, without you noticing. We keep the last 7 and one per day for 30 days.';

  @override
  String get backupUiAutoOff =>
      'Off: a backup is only made when you ask for it.';

  @override
  String get backupUiSectionFile => 'File';

  @override
  String get backupUiSectionCheck => 'Check';

  @override
  String get backupUiSectionCopies => 'Backups on this device';

  @override
  String get backupUiExport => 'Export file';

  @override
  String get backupUiExportSubtitle =>
      'To save it to Drive or send it by WhatsApp or email';

  @override
  String get backupUiExportFailed => 'Couldn’t export the file.';

  @override
  String get backupUiSave => 'Save to device';

  @override
  String get backupUiSaveSubtitle => 'Choose a folder, for example Downloads';

  @override
  String get backupUiSaveDone => 'File saved';

  @override
  String get backupUiSaveFailed =>
      'The file couldn’t be saved. Try another folder or use “Export file”.';

  @override
  String get backupUiImport => 'Import file';

  @override
  String get backupUiImportSubtitle => 'Recover a Cuadrante file';

  @override
  String get backupUiVerify => 'Test restore';

  @override
  String get backupUiVerifySubtitle =>
      'Checks that your latest backup can be fully recovered';

  @override
  String get backupUiVerifyRunning => 'Checking the backup…';

  @override
  String get backupUiVerifyNone =>
      'There’s no backup to test yet. Make one first.';

  @override
  String backupUiVerifyOk(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'The backup is complete: $days days checked',
      one: 'The backup is complete: 1 day checked',
    );
    return '$_temp0';
  }

  @override
  String get backupUiVerifySame => 'It’s identical to what you have now.';

  @override
  String backupUiVerifyOlder(String day) {
    return 'It’s older than what you have now (the first day that differs is $day). That’s normal if you’ve made changes since.';
  }

  @override
  String get backupUiVerifyOlderNoDay =>
      'It’s older than what you have now. That’s normal if you’ve made changes since.';

  @override
  String backupUiVerifyMismatch(String day) {
    return 'The backup doesn’t rebuild the same. First day that differs: $day. Make a new backup and let us know.';
  }

  @override
  String get backupUiVerifyMismatchNoDay =>
      'The backup doesn’t rebuild the same: the saved data doesn’t match. Make a new backup and let us know.';

  @override
  String backupUiVerifyError(String reason) {
    return 'Couldn’t test the backup. $reason';
  }

  @override
  String get backupUiCopiesEmpty => 'Your backups will show up here.';

  @override
  String get backupUiCopyLocal => 'Device backup';

  @override
  String get backupUiCopySafety => 'Before restoring';

  @override
  String backupUiCopyMeta(String kind, String size) {
    return '$kind · $size';
  }

  @override
  String backupUiCopyMetaVersion(String kind, String version, String size) {
    return '$kind · $version · $size';
  }

  @override
  String get backupUiCopyRestore => 'Restore this one';

  @override
  String backupUiCopyRestoreLabel(String when) {
    return 'Restore the backup from $when';
  }

  @override
  String backupUiWhenToday(String time) {
    return 'today at $time';
  }

  @override
  String backupUiWhenYesterday(String time) {
    return 'yesterday at $time';
  }

  @override
  String backupUiWhenDate(String date, String time) {
    return '$date at $time';
  }

  @override
  String get backupUiPreviewTitle => 'Restore backup';

  @override
  String get backupUiPreviewReading => 'Reading the file…';

  @override
  String get backupUiOriginFile => 'File you chose';

  @override
  String get backupUiOriginShared => 'File received from another app';

  @override
  String get backupUiOriginLocal => 'Backup on this device';

  @override
  String get backupUiOriginSafety => 'Backup from just before restoring';

  @override
  String get backupUiOriginCloud => 'iCloud backup';

  @override
  String backupUiPreviewSaved(String when) {
    return 'Saved $when';
  }

  @override
  String backupUiPreviewSender(String sender) {
    return 'Sent from $sender';
  }

  @override
  String get backupUiPreviewSenderHint =>
      'Your device says so. If you weren’t expecting this file, cancel.';

  @override
  String get backupUiPreviewTurnsOffTitle =>
      'This backup turns off settings you have on';

  @override
  String get backupUiPreviewTurnsOffAuto => 'Turns off automatic backups.';

  @override
  String get backupUiPreviewTurnsOffAlarms => 'Turns off shift alarms.';

  @override
  String get backupUiPreviewContains => 'What’s inside';

  @override
  String backupUiPreviewNow(String value) {
    return 'Now: $value';
  }

  @override
  String get backupUiPreviewCalendars => 'Calendars';

  @override
  String backupUiPreviewArchived(String name) {
    return '$name (archived)';
  }

  @override
  String get backupUiPreviewDays => 'Days with a shift or note set by hand';

  @override
  String get backupUiPreviewRuns => 'Rotations';

  @override
  String get backupUiPreviewTypes => 'Shift types';

  @override
  String get backupUiPreviewRange => 'Dates';

  @override
  String backupUiPreviewRangeValue(String from, String to) {
    return 'From $from to $to';
  }

  @override
  String backupUiPreviewRangeOpen(String from, String to) {
    return 'From $from to $to, and a rotation goes on after that';
  }

  @override
  String get backupUiPreviewRangeNone => 'No dates';

  @override
  String get backupUiPreviewReplace =>
      'This replaces what you have now; we save a backup first.';

  @override
  String get backupUiPreviewConfirm => 'Replace what I have';

  @override
  String get backupUiPreviewCancel => 'Cancel';

  @override
  String get backupUiRestoring => 'Restoring your schedule…';

  @override
  String get backupUiRestoringHint => 'Don’t close the app.';

  @override
  String get backupUiDoneTitle => 'Done, your schedule is restored';

  @override
  String get backupUiDoneBody =>
      'Before changing anything, we saved what you had. If it wasn’t what you expected, you can go back.';

  @override
  String get backupUiDoneView => 'See my calendar';

  @override
  String get backupUiDoneUndo => 'Put it back as it was';

  @override
  String get backupUiErrorNotOurs => 'This file isn’t a Cuadrante backup.';

  @override
  String get backupUiErrorNewer =>
      'This file is from a newer version of Cuadrante: update the app.';

  @override
  String get backupUiErrorCorrupt =>
      'The file is damaged or incomplete and can’t be used.';

  @override
  String get backupUiErrorTooLarge =>
      'This file is too large to be a Cuadrante backup.';

  @override
  String get backupUiErrorUnreadable => 'Couldn’t read the file.';

  @override
  String get backupUiErrorUntouched =>
      'We haven’t changed anything: your data is as it was.';

  @override
  String get backupUiErrorRestoreFailed =>
      'Couldn’t restore. Your data is as it was.';

  @override
  String get backupUiErrorRestoreReload =>
      'We restored your data, but the screen couldn’t be updated. Close Cuadrante and open it again.';

  @override
  String get backupUiBack => 'Back';

  @override
  String get widgetWeekdaysShort => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get widgetWeekdayHeaders => 'M,T,W,T,F,S,S';

  @override
  String get widgetMonthNames =>
      'January,February,March,April,May,June,July,August,September,October,November,December';

  @override
  String get widgetTomorrow => 'Tomorrow';

  @override
  String get widgetEmptyCircular => '–';

  @override
  String get widgetStaleTitle => 'Cuadrante';

  @override
  String get widgetStaleBody => 'Open Cuadrante to stay up to date';

  @override
  String get widgetAddTitle => 'Add widget';

  @override
  String get widgetAddSubtitle => 'Today’s shift on your home screen';

  @override
  String get widgetAddBody =>
      'The widget always shows today, even if you don’t open the app.';

  @override
  String get widgetAddSmall => 'Small: today and tomorrow';

  @override
  String get widgetAddMedium => 'Medium: the next 7 days';

  @override
  String get widgetAddLarge => 'Large: the whole month';

  @override
  String get widgetAddAgenda => 'Agenda: upcoming shifts';

  @override
  String get widgetAddTwoWeeks => 'Two weeks: current and next';

  @override
  String get widgetAddManualAndroid =>
      'Touch and hold an empty area of the home screen, choose Widgets and look for Cuadrante.';

  @override
  String get widgetAddManualIos =>
      'Touch and hold the home screen, tap the + at the top and look for Cuadrante.';

  @override
  String get compareTitle => 'Compare calendars';

  @override
  String get compareOpen => 'Compare calendars';

  @override
  String get compareOpenSubtitle => 'See when you’re both off';

  @override
  String get compareSwap => 'Swap';

  @override
  String get compareIntro =>
      'Choose two calendars and see their shifts together. Days when both are off are marked.';

  @override
  String get compareFirstLabel => 'First calendar';

  @override
  String get compareSecondLabel => 'Second calendar';

  @override
  String get comparePickTitle => 'Choose a calendar';

  @override
  String get compareNeedTwoTitle => 'You need two calendars';

  @override
  String get compareNeedTwoBody =>
      'Create another calendar (your partner, a second job) to see when you’re both off.';

  @override
  String compareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shared days off this month',
      one: '1 shared day off this month',
      zero: 'No shared days off this month',
    );
    return '$_temp0';
  }

  @override
  String get compareFreeListTitle => 'Shared days off';

  @override
  String get compareLegendFree => 'Both off';

  @override
  String get compareNote =>
      'A day counts as off when it has no work shift: empty, off, or an absence (vacation, sick leave…). Each shift counts on the day it starts.';

  @override
  String get compareNoShiftMark => '–';

  @override
  String get compareBothFree => 'both off';

  @override
  String compareCellCalendar(String calendar, String shifts) {
    return '$calendar: $shifts';
  }

  @override
  String get compareLoadFailed => 'Couldn’t read the calendars.';

  @override
  String get calendarsTitle => 'Calendars';

  @override
  String get calendarsIntro =>
      'Each calendar has its own schedule: yours, your partner’s, a second job. Shift types are the same in all of them.';

  @override
  String get calendarsActiveBadge => 'Active';

  @override
  String get calendarsPrimaryBadge => 'Widget and alarms';

  @override
  String get calendarsAdd => 'New calendar';

  @override
  String get calendarsNewTitle => 'New calendar';

  @override
  String get calendarsEditTitle => 'Edit calendar';

  @override
  String get calendarsNameLabel => 'Name';

  @override
  String get calendarsNameHint => 'Partner, second job…';

  @override
  String get calendarsColorLabel => 'Color';

  @override
  String calendarsColorOption(int index) {
    return 'Color $index';
  }

  @override
  String get calendarsCreate => 'Create';

  @override
  String get calendarsMakePrimary => 'Use for widget and alarms';

  @override
  String get calendarsPrimaryHelp =>
      'The widget and the alarms follow this calendar even when you’re looking at another one.';

  @override
  String get calendarsArchive => 'Archive';

  @override
  String calendarsArchiveTitle(String name) {
    return 'Archive “$name”?';
  }

  @override
  String get calendarsArchiveBody =>
      'It won’t show up in the list anymore, but you can restore it from “Archived”. Its shifts stay saved on your phone.';

  @override
  String calendarsArchivePrimaryNote(String name) {
    return 'The widget and the alarms will switch to “$name”.';
  }

  @override
  String calendarsArchivedSection(int count) {
    return 'Archived ($count)';
  }

  @override
  String get calendarsRestore => 'Restore';

  @override
  String calendarsRestoreSemantic(String name) {
    return 'Restore “$name”';
  }

  @override
  String calendarsRestored(String name) {
    return '“$name” restored';
  }

  @override
  String get calendarsLastError =>
      'You can’t archive the last calendar: there always has to be one.';

  @override
  String get calendarsNameRequired => 'Give the calendar a name.';

  @override
  String get calendarsNotFoundError => 'That calendar no longer exists.';

  @override
  String get calendarsSaveFailed => 'Couldn’t save the calendar. Try again.';

  @override
  String calendarsSwitcherLabel(String name) {
    return 'Calendar $name. Switch calendar';
  }

  @override
  String get calendarsSwitcherTitle => 'Switch calendar';

  @override
  String get calendarsSwitchFailed => 'Couldn’t switch calendar.';

  @override
  String get calendarsManage => 'Manage calendars';

  @override
  String get holidayImportAction =>
      'Bring public holidays from your phone’s calendar';

  @override
  String get holidayImportTitle => 'Public holidays';

  @override
  String get holidayImportHelp =>
      'All-day events only. Everything stays on your phone; your calendar stays as it is.';

  @override
  String get holidayImportRangeHelp => 'Starts with this year and next year.';

  @override
  String get holidayImportSkipped => 'Already exists · skipped';

  @override
  String get holidayImportReady => 'Will be added';

  @override
  String holidayImportIgnored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count timed events are skipped.',
      one: '1 timed event is skipped.',
    );
    return '$_temp0';
  }

  @override
  String holidayImportCapped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events exceed 31 days: they are shortened.',
      one: '1 event exceeds 31 days: it is shortened.',
    );
    return '$_temp0';
  }

  @override
  String holidayImportAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count public holidays',
      one: 'Add 1 public holiday',
    );
    return '$_temp0';
  }

  @override
  String holidayImportAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count public holidays added',
      one: '1 public holiday added',
    );
    return '$_temp0';
  }

  @override
  String get holidayImportEmpty => 'No new public holidays.';

  @override
  String get holidayImportPreviewHelp =>
      'Dates that already have a public holiday are skipped.';

  @override
  String get holidaysSettingsRegionTitle => 'Region';

  @override
  String get holidaysSettingsRegionUnset => 'Not chosen';

  @override
  String get holidaysSettingsRegionClear => 'No region';

  @override
  String get holidaysSettingsMunicipalityTitle => 'Town';

  @override
  String get holidaysSettingsMunicipalityNone => 'None';

  @override
  String get holidaysSettingsMunicipalitySearch => 'Search town';

  @override
  String holidaysSettingsMunicipalityNoMatch(String query) {
    return 'No town matches “$query”';
  }

  @override
  String get holidaysSettingsMunicipalityLoadFailed =>
      'Couldn’t load the list of towns.';

  @override
  String get holidaysSettingsStatusNoRegion =>
      'Without a region, only national public holidays show. Choose yours to see the regional ones.';

  @override
  String get holidaysSettingsStatusNoMunicipality =>
      'Choose your town to see its local holidays, or add them yourself below.';

  @override
  String holidaysSettingsStatusLocalIncluded(String municipality) {
    return 'Local holidays of $municipality: included';
  }

  @override
  String holidaysSettingsStatusYearPending(String year) {
    return 'The official public holidays for $year will come with an update';
  }

  @override
  String get holidaysSettingsStatusLocalMissing =>
      'We don’t have your town’s yet: add them yourself below';

  @override
  String holidaysSettingsStatusLocalMissingYear(
    String municipality,
    String year,
  ) {
    return 'We don’t have $municipality’s for $year yet: add them yourself below';
  }

  @override
  String get holidaysSettingsStatusLocalPartial =>
      'Some may be missing: check them.';

  @override
  String get holidaysSettingsAdd => 'Add local holiday';

  @override
  String get holidaysSettingsAddName => 'Name';

  @override
  String get holidaysSettingsAddDefaultName => 'Local holiday';

  @override
  String holidaysSettingsEmptyYear(String year) {
    return 'We don’t have the public holidays for $year yet.';
  }

  @override
  String get holidaysSettingsScopeNational => 'National';

  @override
  String get holidaysSettingsScopeLocal => 'Local';

  @override
  String get holidaysSettingsScopeUser => 'Yours';

  @override
  String holidaysSettingsNoteReplaces(String name) {
    return 'Replaces $name';
  }

  @override
  String holidaysSettingsNoteCovered(String name) {
    return 'In your calendar, “$name” covers it';
  }

  @override
  String holidaysSettingsSubstitutedTitle(String region) {
    return 'Not public holidays in $region';
  }

  @override
  String get holidaysSettingsSubstitutedBody =>
      'A region can swap these national public holidays for its own.';

  @override
  String get holidaysSettingsRemove => 'Remove public holiday';

  @override
  String holidaysSettingsRemoved(String name) {
    return 'Public holiday removed: $name';
  }

  @override
  String holidaysSettingsRowSemantics(String date, String name, String scope) {
    return '$date. $name. $scope';
  }

  @override
  String alarmTitle(String name, String start) {
    return '$name shift at $start';
  }

  @override
  String alarmBody(String name, String start, String end) {
    return '$name: from $start to $end';
  }

  @override
  String get alarmChannelName => 'Shift alarms';

  @override
  String get alarmChannelDescription => 'Alerts you before each shift starts.';

  @override
  String alarmsNotifDayBeforeTitle(String name, String start) {
    return 'Tomorrow: $name shift at $start';
  }

  @override
  String get alarmsNotifSnooze => 'Snooze 10 min';

  @override
  String get alarmsNotifAwake => 'I’m awake';

  @override
  String get alarmsNotifTestTitle => 'Test alert';

  @override
  String get alarmsNotifTestBody =>
      'This is how Cuadrante will alert you before your shift.';

  @override
  String get alarmsRowOn => 'On';

  @override
  String get alarmsRowOff => 'Off';

  @override
  String get alarmsMasterTitle => 'Alert before each shift';

  @override
  String get alarmsMasterHelp =>
      'An alert on your phone, offline and without an account.';

  @override
  String get alarmsPermOkTitle => 'All set';

  @override
  String get alarmsPermOkBody =>
      'Notifications and exact-time alarms are allowed.';

  @override
  String get alarmsPermOkBodyIos => 'Notifications are allowed.';

  @override
  String get alarmsPermNotifTitle => 'Notifications are off';

  @override
  String get alarmsPermNotifBody =>
      'Without notification permission, Cuadrante can’t alert you. If the window to allow them doesn’t appear, turn them on in the system settings.';

  @override
  String get alarmsPermNotifAllow => 'Allow';

  @override
  String get alarmsPermNotifBlockedBody =>
      'Android no longer asks you about notifications. Turn them on in the system settings and Cuadrante will be able to alert you.';

  @override
  String get alarmsPermNotifBlockedBodyIos =>
      'iOS no longer asks you about notifications. Turn them on in Settings › Cuadrante › Notifications and Cuadrante will be able to alert you.';

  @override
  String get alarmsPermNotifOpenSettings => 'Open settings';

  @override
  String get alarmsPermExactTitle => 'Alarms & reminders';

  @override
  String get alarmsPermExactBody =>
      'Alarms may arrive a few minutes late. For them to ring at the exact time, allow “Alarms & reminders” in the system settings.';

  @override
  String get alarmsPermExactOpen => 'Open settings';

  @override
  String get alarmsSectionTypes => 'Shift types';

  @override
  String get alarmsTypesEmpty =>
      'None of your shifts has times. Set a time in My shifts so Cuadrante can alert you.';

  @override
  String get alarmsBeforeTitle => 'Before the shift';

  @override
  String get alarmsBeforeAtStart => 'When it starts';

  @override
  String get alarmsBeforeSheetTitle => 'How long before the shift';

  @override
  String get alarmsBeforeCustom => 'Custom';

  @override
  String get alarmsBeforeCustomTitle => 'Custom lead time';

  @override
  String get alarmsBeforeCustomHelp =>
      'Hours and minutes before the shift starts.';

  @override
  String get alarmsBeforeCustomApply => 'Save';

  @override
  String get alarmsSecondSegmentTitle => 'Also alert before the second part';

  @override
  String get alarmsSecondSegmentHelper =>
      'A second alert, with the same lead time, before going back to work.';

  @override
  String get alarmsDayBeforeTitle => 'Alert the day before';

  @override
  String alarmsDayBeforeAt(String time) {
    return 'At $time';
  }

  @override
  String get alarmsDayBeforeTimeTitle => 'Alert time';

  @override
  String get alarmsLabelTitle => 'Alert text';

  @override
  String get alarmsLabelDefault => 'The usual one';

  @override
  String get alarmsLabelHint => 'For example: Time for work';

  @override
  String get alarmsLabelApply => 'Save';

  @override
  String get alarmsLabelReset => 'Use the usual one';

  @override
  String get alarmsTestButton => 'Test alert';

  @override
  String get alarmsTestScheduled => 'We’ll alert you in 10 seconds.';

  @override
  String get alarmsTestDenied =>
      'Without notification permission we can’t test the alert.';

  @override
  String alarmsNextLine(String when, String shift) {
    return 'Next alert: $when · $shift';
  }

  @override
  String alarmsNextLineDayBefore(String when, String shift) {
    return 'Next alert: $when · $shift, the day before';
  }

  @override
  String alarmsNextWhen(String weekday, int day, String month, String time) {
    return '$weekday, $month $day, $time';
  }

  @override
  String get alarmsNextNone => 'No alerts coming up in the next few days.';

  @override
  String get alarmsNextOff => 'Alarms are off.';

  @override
  String get alarmsSkipDay => 'No alarm this day';

  @override
  String get alarmsReminderTitle => 'Reminder';

  @override
  String get alarmsReminderEmptyBody => 'You have a reminder for today';

  @override
  String get alarmsReminderChannelName => 'Note reminders';

  @override
  String get alarmsReminderChannelDescription =>
      'Alerts you at the time you choose in a day’s note.';

  @override
  String get dayReminderAdd => 'Remind me';

  @override
  String dayReminderAt(String time) {
    return 'Alert at $time';
  }

  @override
  String get dayReminderChange => 'Change the alert time';

  @override
  String get dayReminderRemove => 'Remove alert';

  @override
  String get dayReminderRemoved => 'Alert removed';

  @override
  String get dayReminderPickHelp => 'Alert time';

  @override
  String get dayReminderPast => 'That time has passed: it won’t ring.';

  @override
  String get dayReminderNoPermission =>
      'Notifications are off, so the alert won’t ring. Turn them on in your phone’s settings.';

  @override
  String get dayReminderOnlyPrimary =>
      'Only alerts from the main calendar ring.';

  @override
  String agendaSemanticsReminder(String time) {
    return 'alert at $time';
  }

  @override
  String get shiftTypesAlarmSection => 'Alarm';

  @override
  String get shiftTypesSoundLabel => 'Sound';

  @override
  String get shiftTypesSoundHelper =>
      'Rings at alarm volume, once you turn on this shift’s alarm in Settings.';

  @override
  String get shiftTypesSoundDefault => 'Default';

  @override
  String get shiftTypesSoundCustom => 'Phone sound';

  @override
  String get shiftTypesSoundMissing => 'Not available: the default rings';

  @override
  String get shiftTypesSoundReset => 'Use the default';

  @override
  String get catalogShiftMorningName => 'Morning';

  @override
  String get catalogShiftMorningCode => 'M';

  @override
  String get catalogShiftAfternoonName => 'Afternoon';

  @override
  String get catalogShiftAfternoonCode => 'A';

  @override
  String get catalogShiftNightName => 'Night';

  @override
  String get catalogShiftNightCode => 'N';

  @override
  String get catalogShiftRestName => 'Off';

  @override
  String get catalogShiftRestCode => 'O';

  @override
  String get catalogShiftGuard24Name => '24-hour shift';

  @override
  String get catalogShiftGuard24Code => '24';

  @override
  String get catalogShiftPostNightName => 'Post-night';

  @override
  String get catalogShiftPostNightCode => 'PN';

  @override
  String get catalogShiftVacationName => 'Vacation';

  @override
  String get catalogShiftVacationCode => 'V';

  @override
  String get catalogShiftPersonalDayName => 'Personal day';

  @override
  String get catalogShiftPersonalDayCode => 'PD';

  @override
  String get catalogShiftDay12Name => 'Day 12 h';

  @override
  String get catalogShiftDay12Code => 'D';

  @override
  String get catalogShiftNight12Name => 'Night 12 h';

  @override
  String get catalogShiftNight12Code => 'N12';

  @override
  String get catalogShiftSplitName => 'Split';

  @override
  String get catalogShiftSplitCode => 'S';

  @override
  String get catalogPatternCorreturnosName => 'Rotating shifts';

  @override
  String get catalogPatternCorreturnosDescription =>
      '5 mornings, 2 off, 5 afternoons, 2 off, 5 nights, 2 off';

  @override
  String get catalogPattern24x72Name => '24 x 72';

  @override
  String get catalogPattern24x72Description => '24-hour shift and 72 hours off';

  @override
  String get catalogPattern12hName => '12 hours';

  @override
  String get catalogPattern12hDescription =>
      'Day 12 h, night 12 h, post-night and off';

  @override
  String get catalogPattern6x4Name => '6 x 4';

  @override
  String get catalogPattern6x4Description => '6 mornings and 4 off';

  @override
  String get catalogPattern4x4Name => '4 x 4';

  @override
  String get catalogPattern4x4Description => '4 12-hour days and 4 off';

  @override
  String get catalogPattern5x2Name => '5 x 2';

  @override
  String get catalogPattern5x2Description =>
      '5 mornings and 2 off (Monday to Friday)';

  @override
  String get catalogPattern223Name => '2-2-3';

  @override
  String get catalogPattern223Description =>
      'Two 12-hour days, two off, three 12-hour days, two off, two 12-hour days and three off (also 2-2-3-2-2-3)';

  @override
  String get catalogPatternContinentalName => 'Continental';

  @override
  String get catalogPatternContinentalDescription =>
      '28-day continuous rotation with 4 crews: blocks of 2 and 3 mornings, afternoons and nights, and 7 off';

  @override
  String get catalogPatternDupontName => 'DuPont';

  @override
  String get catalogPatternDupontDescription =>
      '28-day cycle of 12-hour shifts: 4 nights, 3 off, 3 days, 1 off, 3 nights, 3 off, 4 days and 7 off';

  @override
  String get holidayNameNewYear => 'New Year’s Day';

  @override
  String get holidayNameEpiphany => 'Epiphany';

  @override
  String get holidayNameMaundyThursday => 'Maundy Thursday';

  @override
  String get holidayNameGoodFriday => 'Good Friday';

  @override
  String get holidayNameEasterMonday => 'Easter Monday';

  @override
  String get holidayNameLabourDay => 'Labour Day';

  @override
  String get holidayNameAssumption => 'Assumption Day';

  @override
  String get holidayNameNationalDay => 'National Day of Spain';

  @override
  String get holidayNameAllSaints => 'All Saints’ Day';

  @override
  String get holidayNameConstitution => 'Constitution Day';

  @override
  String get holidayNameImmaculate => 'Immaculate Conception';

  @override
  String get holidayNameChristmas => 'Christmas Day';

  @override
  String get holidayNameStStephen => 'St Stephen’s Day';

  @override
  String get holidayNameStJoseph => 'St Joseph’s Day';

  @override
  String get holidayNameStJames => 'St James’ Day';

  @override
  String get holidayNameGaliciaDay => 'Galicia Day';

  @override
  String get holidayNameStJamesGalicia => 'St James’ Day / Galicia Day';

  @override
  String get holidayNameCataloniaDay => 'Catalonia National Day';

  @override
  String get holidayNameBasqueDay => 'Basque Country Day';

  @override
  String get catalogCalendarMainName => 'My roster';

  @override
  String get historyUndone => 'Change undone';

  @override
  String get historyRedone => 'Change redone';

  @override
  String get historyNothingToUndo => 'Nothing to undo';

  @override
  String get historyNothingToRedo => 'Nothing to redo';

  @override
  String get monthPresentationGrid => 'Grid';

  @override
  String get monthPresentationList => 'List';

  @override
  String get monthSelectDays => 'Select days';

  @override
  String get monthSelectDay => 'Tap to select this day';

  @override
  String get monthListRecommended =>
      'List recommended for full times and large text.';

  @override
  String get monthListSelected => 'List view';

  @override
  String get monthGridSelected => 'Grid view';
}
