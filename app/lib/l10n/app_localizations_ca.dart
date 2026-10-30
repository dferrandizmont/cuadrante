// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appName => 'Turnly';

  @override
  String get cancel => 'Cancel·la';

  @override
  String get close => 'Tanca';

  @override
  String get delete => 'Esborra';

  @override
  String get save => 'Desa';

  @override
  String get undo => 'Desfés';

  @override
  String get redo => 'Refés';

  @override
  String get retry => 'Torna-ho a provar';

  @override
  String get back => 'Enrere';

  @override
  String get loadingLabel => 'S’està carregant';

  @override
  String get errorGeneric => 'Alguna cosa no ha anat bé. Torna-ho a provar.';

  @override
  String get calendarToday => 'Avui';

  @override
  String calendarPickMonth(String month) {
    return '$month, tria el mes';
  }

  @override
  String get calendarPreviousMonth => 'Mes anterior';

  @override
  String get calendarNextMonth => 'Mes següent';

  @override
  String calendarHeaderTomorrow(String date, String shifts) {
    return 'Demà ($date): $shifts';
  }

  @override
  String calendarHeaderTomorrowNone(String date) {
    return 'Demà ($date): sense torn';
  }

  @override
  String get todayLabelNow => 'Ara';

  @override
  String get todayLabelTonight => 'Aquesta nit';

  @override
  String get todayLabelToday => 'Avui';

  @override
  String get todayLabelFree => 'Avui lliure';

  @override
  String get todayLabelDone => 'Avui acabat';

  @override
  String todayFinishedAt(String time) {
    return 'Ha acabat a les $time';
  }

  @override
  String get todayLabelGap => 'Descans';

  @override
  String todayBackAt(String time) {
    return 'Tornes a les $time';
  }

  @override
  String todayBackIn(String duration) {
    return 'Tornes d’aquí a $duration';
  }

  @override
  String get todayFreeTitle => 'Lliure';

  @override
  String todayUntil(String time) {
    return 'Fins a les $time';
  }

  @override
  String todayStartsIn(String duration) {
    return 'Comença d’aquí a $duration';
  }

  @override
  String todayEndsIn(String duration) {
    return 'Acaba d’aquí a $duration';
  }

  @override
  String todayNext(String name, String weekday, String time) {
    return 'Següent: $name, $weekday $time';
  }

  @override
  String get todayNoNext => 'No hi ha torns a la vista';

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
  String get calendarNoShift => 'Sense torn';

  @override
  String calendarShiftWithTimes(String name, String times) {
    return '$name $times';
  }

  @override
  String get calendarWeekdayMon => 'dl';

  @override
  String get calendarWeekdayTue => 'dt';

  @override
  String get calendarWeekdayWed => 'dc';

  @override
  String get calendarWeekdayThu => 'dj';

  @override
  String get calendarWeekdayFri => 'dv';

  @override
  String get calendarWeekdaySat => 'ds';

  @override
  String get calendarWeekdaySun => 'dg';

  @override
  String get daySemanticsToday => 'avui';

  @override
  String get daySemanticsNoShift => 'sense torn';

  @override
  String daySemanticsShift(String name, String start, String end) {
    return '$name de $start a $end';
  }

  @override
  String daySemanticsShiftSplit(
    String name,
    String start,
    String end,
    String start2,
    String end2,
  ) {
    return '$name de $start a $end i de $start2 a $end2';
  }

  @override
  String daySemanticsAnd(String first, String second) {
    return '$first i $second';
  }

  @override
  String daySemanticsHoliday(String name) {
    return 'festiu: $name';
  }

  @override
  String get daySemanticsNote => 'amb nota';

  @override
  String daySemanticsOvertime(String duration) {
    return 'hores extra: $duration';
  }

  @override
  String daySemanticsEarlyLeave(String duration) {
    return 'sortida anticipada: $duration';
  }

  @override
  String daySheetHoliday(String name) {
    return 'Festiu: $name';
  }

  @override
  String get daySheetNote => 'Nota';

  @override
  String get daySheetEmpty => 'Aquest dia no té torn.';

  @override
  String get dayPaneClose => 'Tanca el dia';

  @override
  String get upcomingTitle => 'Pròxims dies';

  @override
  String get dayDetailSourcePattern => 'Segons el teu patró';

  @override
  String get dayDetailSourceOverride => 'Canviat a mà';

  @override
  String get dayDetailAdd => 'Afegeix torn';

  @override
  String get dayDetailDouble => 'Afegeix un segon torn';

  @override
  String get dayDetailReset => 'Torna al patró';

  @override
  String dayDetailPatternGives(String shifts) {
    return 'El patró dona: $shifts';
  }

  @override
  String get dayDetailNoteHint => 'Escriu una nota per a aquest dia';

  @override
  String get dayDetailUserHoliday => 'Festiu propi';

  @override
  String get dayDetailUserHolidayDefault => 'Festiu propi';

  @override
  String get dayDetailUserHolidayNameHint => 'Nom del festiu';

  @override
  String get dayDetailDuplicate => 'Duplica en un altre dia';

  @override
  String get dayDetailDuplicateHelp => 'Copia en aquest dia';

  @override
  String dayDetailDuplicated(String date) {
    return 'Copiat: $date';
  }

  @override
  String get dayDetailClear => 'Esborra el dia';

  @override
  String get dayDetailCleared => 'Dia esborrat';

  @override
  String get dayDetailMoveUp => 'Puja';

  @override
  String get dayDetailMoveDown => 'Baixa';

  @override
  String dayDetailRemove(String name) {
    return 'Treu $name';
  }

  @override
  String get dayExtrasTitle => 'Hores extra / He sortit abans';

  @override
  String get dayExtrasOvertime => 'Hores extra';

  @override
  String get dayExtrasEarlyLeave => 'He sortit abans';

  @override
  String get dayExtrasNone => 'Cap';

  @override
  String get dayExtrasHelper =>
      'Sumen o resten a les hores del mes i a l’estimació. Amb 0 es treu.';

  @override
  String dayExtrasMore(String label) {
    return 'Més $label';
  }

  @override
  String dayExtrasLess(String label) {
    return 'Menys $label';
  }

  @override
  String dayExtrasValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get shiftTypesTitle => 'Els meus torns';

  @override
  String get shiftTypesEditEntry => 'Edita els torns';

  @override
  String get shiftTypesEmptyTitle => 'No tens torns';

  @override
  String get shiftTypesEmptyMessage =>
      'Crea’n el primer per poder-lo pintar al calendari.';

  @override
  String get shiftTypesNew => 'Torn nou';

  @override
  String get shiftTypesNewTitle => 'Torn nou';

  @override
  String get shiftTypesEditTitle => 'Edita el torn';

  @override
  String get shiftTypesNotFound => 'No trobem aquest torn';

  @override
  String get shiftTypesNotFoundMessage =>
      'Potser l’has arxivat. Torna a la llista de torns.';

  @override
  String get shiftTypesArchive => 'Arxiva';

  @override
  String shiftTypesArchiveTitle(String name) {
    return 'Vols arxivar «$name»?';
  }

  @override
  String get shiftTypesArchiveBody =>
      'Ja no sortirà quan pintis. Els dies que ja el fan servir el continuaran mostrant.';

  @override
  String get shiftTypesArchiveConfirm => 'Arxiva';

  @override
  String get shiftTypesDragHandle => 'Arrossega per reordenar';

  @override
  String shiftTypesArchivedSection(int count) {
    return 'Arxivats ($count)';
  }

  @override
  String get shiftTypesArchivedHelp =>
      'Ja no surten quan pintes. Recupera’ls i tornaran a la paleta.';

  @override
  String get shiftTypesRestore => 'Recupera';

  @override
  String shiftTypesRestoreSemantic(String name) {
    return 'Recupera «$name»';
  }

  @override
  String shiftTypesRestored(String name) {
    return 'S’ha recuperat «$name»';
  }

  @override
  String get shiftTypesDiscardTitle => 'Vols descartar els canvis?';

  @override
  String get shiftTypesDiscardBody =>
      'El que has canviat en aquest torn no es desarà.';

  @override
  String get shiftTypesDiscardKeep => 'Continua editant';

  @override
  String get shiftTypesDiscardConfirm => 'Descarta';

  @override
  String get shiftTypesNoTimes => 'Sense horari';

  @override
  String shiftTypesRatePerHour(String rate) {
    return '$rate/h';
  }

  @override
  String shiftTypesFixedPlusPerShift(String amount) {
    return '+$amount per torn';
  }

  @override
  String get shiftTypesCategoryWork => 'Feina';

  @override
  String get shiftTypesCategoryRest => 'Descans';

  @override
  String get shiftTypesCategoryAbsence => 'Absència';

  @override
  String get shiftTypesNameLabel => 'Nom';

  @override
  String get shiftTypesCodeLabel => 'Codi';

  @override
  String get shiftTypesCodeHelper =>
      'D’1 a 3 caràcters. És el que es veu a cada casella del mes.';

  @override
  String get shiftTypesColorLabel => 'Color';

  @override
  String shiftTypesColorOption(int number, int total) {
    return 'Color $number de $total';
  }

  @override
  String shiftTypesColorOptionNamed(String name, int number, int total) {
    return '$name, $number de $total';
  }

  @override
  String get shiftColorNameOrange => 'Taronja';

  @override
  String get shiftColorNameCoral => 'Corall';

  @override
  String get shiftColorNameIndigo => 'Índigo';

  @override
  String get shiftColorNameLightGrey => 'Gris clar';

  @override
  String get shiftColorNameRed => 'Vermell';

  @override
  String get shiftColorNameLilac => 'Lila';

  @override
  String get shiftColorNameGreen => 'Verd';

  @override
  String get shiftColorNameTeal => 'Turquesa';

  @override
  String get shiftColorNameRaspberry => 'Gerd';

  @override
  String get shiftColorNamePink => 'Rosa';

  @override
  String get shiftColorNameTangerine => 'Mandarina';

  @override
  String get shiftColorNameYellow => 'Groc';

  @override
  String get shiftColorNameLime => 'Llima';

  @override
  String get shiftColorNameForest => 'Verd bosc';

  @override
  String get shiftColorNameMint => 'Menta';

  @override
  String get shiftColorNameCyan => 'Cian';

  @override
  String get shiftColorNameSkyBlue => 'Blau cel';

  @override
  String get shiftColorNameBlue => 'Blau';

  @override
  String get shiftColorNameCobalt => 'Cobalt';

  @override
  String get shiftColorNameViolet => 'Violeta';

  @override
  String get shiftColorNamePurple => 'Morat';

  @override
  String get shiftColorNameBrown => 'Marró';

  @override
  String get shiftColorNameGrey => 'Gris';

  @override
  String get shiftColorNameGraphite => 'Grafit';

  @override
  String get shiftTypesColorCurrent => 'Color actual';

  @override
  String get shiftTypesIconLabel => 'Icona';

  @override
  String get shiftTypesIconHelper =>
      'Opcional. Es veu al costat del codi quan hi ha lloc; el codi i el color sempre hi són.';

  @override
  String get shiftTypesIconNone => 'Sense icona';

  @override
  String get shiftTypesIconChoose => 'Tria una icona';

  @override
  String shiftTypesIconCurrent(String name) {
    return 'Icona: $name';
  }

  @override
  String get shiftIconNameSun => 'Sol';

  @override
  String get shiftIconNameMoon => 'Lluna';

  @override
  String get shiftIconNameSunrise => 'Alba';

  @override
  String get shiftIconNameHospital => 'Hospital';

  @override
  String get shiftIconNameAmbulance => 'Ambulància';

  @override
  String get shiftIconNamePolice => 'Policia';

  @override
  String get shiftIconNameFire => 'Bombers';

  @override
  String get shiftIconNameFactory => 'Fàbrica';

  @override
  String get shiftIconNameTruck => 'Camió';

  @override
  String get shiftIconNamePlane => 'Avió';

  @override
  String get shiftIconNameSchool => 'Escola';

  @override
  String get shiftIconNameHome => 'Casa';

  @override
  String get shiftIconNameBeach => 'Platja';

  @override
  String get shiftIconNameBed => 'Llit';

  @override
  String get shiftIconNameStar => 'Estrella';

  @override
  String get shiftIconNameHeart => 'Cor';

  @override
  String get shiftIconNameCoffee => 'Cafè';

  @override
  String get shiftIconNameBook => 'Llibre';

  @override
  String get shiftIconNameMoney => 'Diners';

  @override
  String get shiftIconNameAlert => 'Avís';

  @override
  String get shiftIconNamePhone => 'Telèfon';

  @override
  String get shiftIconNameCar => 'Cotxe';

  @override
  String get shiftIconNameTrain => 'Tren';

  @override
  String get shiftIconNameBus => 'Autobús';

  @override
  String get shiftIconNameShop => 'Botiga';

  @override
  String get shiftIconNameTool => 'Eines';

  @override
  String get shiftIconNameBaby => 'Nadó';

  @override
  String get shiftIconNameSport => 'Esport';

  @override
  String get shiftIconNameParty => 'Festa';

  @override
  String get shiftIconNameMedical => 'Metge';

  @override
  String get shiftTypesColorMore => 'Més colors…';

  @override
  String get shiftTypesColorPickerTitle => 'Tria el teu color';

  @override
  String get shiftTypesColorPickerHelp =>
      'Mira com queda la casella en clar i en fosc. El text s’ajusta sol perquè es llegeixi bé.';

  @override
  String get shiftTypesColorHue => 'To';

  @override
  String get shiftTypesColorSaturation => 'Intensitat';

  @override
  String get shiftTypesColorLightness => 'Lluminositat';

  @override
  String shiftTypesColorHueSpoken(int degrees) {
    return '$degrees graus';
  }

  @override
  String shiftTypesColorPercentSpoken(int percent) {
    return '$percent per cent';
  }

  @override
  String get shiftTypesColorHexLabel => 'Codi hexadecimal';

  @override
  String get shiftTypesColorHexError =>
      'Escriu 6 xifres o lletres de la A a la F, per exemple #1C7ED6.';

  @override
  String get shiftTypesColorUse => 'Fes servir aquest color';

  @override
  String get shiftTypesCategoryLabel => 'Categoria';

  @override
  String get shiftTypesTimesLabel => 'Horari';

  @override
  String shiftTypesStarts(String time) {
    return 'Comença $time';
  }

  @override
  String shiftTypesEnds(String time) {
    return 'Acaba $time';
  }

  @override
  String get shiftTypesPickStart => 'Hora d’inici';

  @override
  String get shiftTypesPickEnd => 'Hora de final';

  @override
  String shiftTypesDuration(String duration) {
    return 'Dura $duration';
  }

  @override
  String shiftTypesEndsNextDay(String duration) {
    return 'Acaba l’endemà · dura $duration';
  }

  @override
  String get shiftTypesTwentyFourHours =>
      'Dura 24 h: acaba l’endemà a la mateixa hora';

  @override
  String get shiftTypesSplitLabel => 'Torn partit';

  @override
  String get shiftTypesSplitHelper =>
      'Dos trams el mateix dia, amb una pausa al mig que no compta com a treballada.';

  @override
  String get shiftTypesSplitTemplate => 'Fes servir «Partit 09–13 / 17–21»';

  @override
  String get shiftTypesSplitSecondTitle => 'Segon tram';

  @override
  String get shiftTypesPickSecondStart => 'Inici del tram 2';

  @override
  String get shiftTypesPickSecondEnd => 'Final del tram 2';

  @override
  String shiftTypesSplitSummary(String first, String second, String total) {
    return 'Treballes $first i $second: $total en total';
  }

  @override
  String get shiftTypesErrorSplitIncomplete =>
      'Posa quan comença i quan acaba el segon tram, o desactiva el torn partit.';

  @override
  String get shiftTypesErrorSplitStart =>
      'L’hora d’inici del segon tram no és vàlida.';

  @override
  String get shiftTypesErrorSplitDuration =>
      'El segon tram ha de durar entre 1 minut i 24 h.';

  @override
  String get shiftTypesErrorSplitNotAfter =>
      'El segon tram no pot començar just quan acaba el primer: seria un sol tram. Deixa una pausa entre tots dos.';

  @override
  String get shiftTypesErrorSplitTooLong =>
      'Els dos trams i la pausa entre ells no caben en 24 h. Comprova que el segon comença després que acabi el primer.';

  @override
  String get shiftTypesBreakLabel => 'Pausa no pagada';

  @override
  String get shiftTypesBreakUnit => 'min';

  @override
  String get shiftTypesBreakHint => '0 min';

  @override
  String get shiftTypesRateHint => 'Sense preu';

  @override
  String get shiftTypesBreakHelper =>
      'Minuts del torn que no es paguen. Deixa-ho buit si es paga tot.';

  @override
  String shiftTypesPaidHelper(String duration) {
    return 'Es paguen $duration';
  }

  @override
  String get shiftTypesNightLabel => 'Torn de nit';

  @override
  String get shiftTypesNightHelper =>
      'Automàtic compta com a nit les hores entre les 22:00 i les 06:00.';

  @override
  String get shiftTypesNightAuto => 'Automàtic';

  @override
  String get shiftTypesNightAlways => 'Sempre de nit';

  @override
  String get shiftTypesNightNever => 'Mai de nit';

  @override
  String get shiftTypesFixedPlusLabel => 'Plus per torn (opcional)';

  @override
  String get shiftTypesFixedPlusHelper =>
      'Es suma una vegada per cada torn treballat.';

  @override
  String get shiftTypesFixedPlusHint => 'Sense plus';

  @override
  String get shiftTypesFixedPlusUnit => '€';

  @override
  String get shiftTypesRateLabel => 'Preu per hora (opcional)';

  @override
  String get shiftTypesRateHelper =>
      'Per calcular quant guanyes al resum del mes.';

  @override
  String get shiftTypesRateUnit => '€/h';

  @override
  String get shiftTypesPreviewLabel => 'Així es veurà al mes';

  @override
  String get shiftTypesPreviewLight => 'Clar';

  @override
  String get shiftTypesPreviewDark => 'Fosc';

  @override
  String shiftTypesPreviewContrast(String ratio) {
    return 'Contrast $ratio:1';
  }

  @override
  String get shiftTypesErrorCodeEmpty => 'Escriu un codi d’1 a 3 caràcters';

  @override
  String get shiftTypesErrorCodeTooLong =>
      'El codi admet fins a 3 caràcters, sense emojis ni espais';

  @override
  String shiftTypesErrorCodeTaken(String name) {
    return 'Aquest codi ja el fa servir «$name»';
  }

  @override
  String get shiftTypesErrorNameEmpty => 'Posa un nom al torn';

  @override
  String get shiftTypesErrorBreak => 'La pausa ha de ser més curta que el torn';

  @override
  String get shiftTypesErrorRate => 'Escriu un import vàlid, per exemple 12,50';

  @override
  String get paintFab => 'Pinta';

  @override
  String get paintHeader => 'Pintant';

  @override
  String paintHeaderShift(String name, String times) {
    return '$name · $times';
  }

  @override
  String get paintDone => 'Fet';

  @override
  String get paintDouble => 'Dobla';

  @override
  String get paintEraser => 'Esborra';

  @override
  String get paintToolsLabel => 'Eines per pintar';

  @override
  String get selectionHeader => 'Selecció';

  @override
  String get selectionHint =>
      'Toca els dies o mantén premut i arrossega per triar-ne diversos';

  @override
  String selectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies',
      one: '1 dia',
      zero: 'Cap dia',
    );
    return '$_temp0';
  }

  @override
  String get selectionBarLabel => 'Accions per als dies triats';

  @override
  String get selectionSetShift => 'Posa torn…';

  @override
  String get selectionDouble => 'Dobla amb…';

  @override
  String get selectionClear => 'Esborra';

  @override
  String get selectionReset => 'Torna al patró';

  @override
  String get selectionCopy => 'Copia';

  @override
  String get selectionCut => 'Retalla';

  @override
  String get selectionPaste => 'Enganxa';

  @override
  String get selectionRepeat => 'Repeteix…';

  @override
  String get selectionNote => 'Nota…';

  @override
  String get selectionCancel => 'Cancel·la';

  @override
  String get selectionCellSelected => 'triat';

  @override
  String get selectionSetShiftTitle => 'Posa torn';

  @override
  String get selectionSetShiftHelp => 'Substitueix els torns dels dies triats.';

  @override
  String get selectionDoubleTitle => 'Afegeix un segon torn';

  @override
  String get selectionDoubleHelp =>
      'Afegeix el torn als que ja tinguin els dies triats.';

  @override
  String get selectionNoteTitle => 'Nota per als dies triats';

  @override
  String get selectionNoteHint => 'La mateixa nota a tots els dies';

  @override
  String get selectionNoteSave => 'Desa la nota';

  @override
  String get selectionNoteRemove => 'Treu les notes';

  @override
  String get selectionPasteTitle => 'Enganxa dies';

  @override
  String selectionPasteSummary(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S’enganxen $count dies',
      one: 'S’enganxa 1 dia',
    );
    return '$_temp0 a partir de: $date.';
  }

  @override
  String selectionPasteReach(String from, String to) {
    return 'S’enganxarà de $from a $to.';
  }

  @override
  String get selectionPasteReplaces =>
      'Els torns d’aquests dies se substitueixen. Ho podràs desfer.';

  @override
  String get selectionIncludeNotes => 'Inclou les notes';

  @override
  String get selectionIncludeNotesHelp =>
      'Les notes dels dies copiats substitueixen les que hi hagi al destí.';

  @override
  String get selectionCutNotesMove =>
      'En retallar, les notes es mouen amb els dies.';

  @override
  String get selectionPasteConfirm => 'Enganxa';

  @override
  String get selectionRepeatTitle => 'Repeteix els dies triats';

  @override
  String selectionRepeatTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vegades',
      one: '1 vegada',
    );
    return '$_temp0';
  }

  @override
  String get selectionRepeatLess => 'Una vegada menys';

  @override
  String get selectionRepeatMore => 'Una vegada més';

  @override
  String selectionRepeatPreview(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Canvia $count dies més, fins a: $date.',
      one: 'Canvia 1 dia més, fins a: $date.',
    );
    return '$_temp0';
  }

  @override
  String get selectionRepeatConfirm => 'Repeteix';

  @override
  String selectionChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies canviats',
      one: '1 dia canviat',
    );
    return '$_temp0';
  }

  @override
  String get selectionNothingChanged => 'Aquests dies ja estaven així';

  @override
  String selectionCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies copiats',
      one: '1 dia copiat',
    );
    return '$_temp0. Tria el dia d’inici i toca Enganxa.';
  }

  @override
  String selectionCutDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies retallats',
      one: '1 dia retallat',
    );
    return '$_temp0. Tria el dia d’inici i toca Enganxa.';
  }

  @override
  String selectionPasted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies enganxats',
      one: '1 dia enganxat',
    );
    return '$_temp0';
  }

  @override
  String selectionRepeated(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: '$times vegades',
      one: '1 vegada',
    );
    return 'Repetit $_temp0';
  }

  @override
  String get selectionRunsTitle => 'Les meves rotacions';

  @override
  String get selectionRunsSubtitle => 'Acaba o treu un patró d’un cop';

  @override
  String get selectionRunsEmptyTitle => 'Sense rotacions';

  @override
  String get selectionRunsEmptyMessage =>
      'Quan apliquis un patró des de Pinta, apareixerà aquí.';

  @override
  String selectionRunsRange(String from, String to) {
    return 'De $from a $to';
  }

  @override
  String selectionRunsOpenEnded(String from) {
    return 'Des de $from, sense data de final';
  }

  @override
  String selectionRunsStep(int day) {
    return 'Comença al dia $day del cicle';
  }

  @override
  String get selectionRunsActive => 'En curs';

  @override
  String get selectionRunsFuture => 'Encara no ha començat';

  @override
  String get selectionRunsEnded => 'Acabada';

  @override
  String get selectionRunsEnd => 'Acaba aquí';

  @override
  String get selectionRunsEndHelp => 'Primer dia sense la rotació';

  @override
  String selectionRunsEndDone(String date) {
    return 'La rotació acaba: $date';
  }

  @override
  String get selectionRunsDelete => 'Elimina';

  @override
  String selectionRunsDeleteTitle(String name) {
    return 'Vols eliminar $name?';
  }

  @override
  String get selectionRunsDeleteBody =>
      'Es treu de tot el calendari. Els dies que vas canviar a mà i les notes es queden com estan. Ho podràs desfer.';

  @override
  String get selectionRunsDeleted => 'Rotació eliminada';

  @override
  String get agendaTitle => 'Agenda';

  @override
  String get agendaOpenTooltip => 'Agenda de notes';

  @override
  String get agendaSearchHint => 'Cerca en notes i torns';

  @override
  String get agendaSearchHintShort => 'Cerca';

  @override
  String get agendaModeNotes => 'Notes';

  @override
  String get agendaModeShifts => 'Torns';

  @override
  String get agendaSearchScope =>
      'Cerca en totes les teves notes i festius propis, i en els torns des de fa un any fins d’aquí a un any. També entén dates: 15/10 o 15 oct.';

  @override
  String get agendaSearchClear => 'Esborra la cerca';

  @override
  String get agendaEmptyTitle => 'Sense notes properes';

  @override
  String get agendaEmptyMessage =>
      'Les notes i els festius propis dels propers dies apareixeran aquí.';

  @override
  String get agendaNoResultsTitle => 'No s’ha trobat res';

  @override
  String agendaNoResultsMessage(String query) {
    return 'No hi ha notes ni torns que coincideixin amb «$query».';
  }

  @override
  String agendaHoliday(String name) {
    return 'Festiu: $name';
  }

  @override
  String agendaTruncated(int count) {
    return 'Es mostren els primers $count resultats. Escriu alguna cosa més per afinar.';
  }

  @override
  String agendaResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultats',
      one: '1 resultat',
    );
    return '$_temp0';
  }

  @override
  String agendaSemanticsNote(String note) {
    return 'nota: $note';
  }

  @override
  String get patternButton => 'Patró';

  @override
  String get patternTitle => 'Aplica un patró';

  @override
  String patternStepOf(int current, int total) {
    return 'Pas $current de $total';
  }

  @override
  String get patternStepChoose => 'Tria un patró';

  @override
  String get patternStepStart => 'Quan comences?';

  @override
  String get patternStepEnd => 'Fins quan?';

  @override
  String get patternNext => 'Següent';

  @override
  String get patternBack => 'Enrere';

  @override
  String get patternApply => 'Aplica';

  @override
  String get patternApplied => 'Patró aplicat';

  @override
  String get patternApplyFailed => 'No s’ha pogut aplicar el patró';

  @override
  String patternFromDay(String date) {
    return 'Des de $date';
  }

  @override
  String get patternGroupHealth => 'Sanitat';

  @override
  String get patternGroupPolice => 'Policia i Guàrdia Civil';

  @override
  String get patternGroupFirefighters => 'Bombers';

  @override
  String get patternGroupIndustry => 'Indústria';

  @override
  String get patternGroupSecurity => 'Seguretat';

  @override
  String get patternGroupOther => 'Altres';

  @override
  String get patternGroupMine => 'Els meus patrons';

  @override
  String patternGroupTypical(String shift) {
    return 'Comencen per: $shift';
  }

  @override
  String patternGroupIncluding(String shift) {
    return 'Inclouen: $shift';
  }

  @override
  String patternCycleDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get patternCreateOwn => 'Crea el meu';

  @override
  String get patternCreateOwnHint => 'Munta la teva seqüència dia a dia';

  @override
  String get patternBuilderBack => 'Tria un patró de la llista';

  @override
  String get patternBuilderName => 'Nom del patró';

  @override
  String get patternBuilderDefaultName => 'El meu patró';

  @override
  String get patternBuilderSequence => 'La teva seqüència';

  @override
  String get patternBuilderEmpty =>
      'Toca els torns de sota per anar afegint dies.';

  @override
  String get patternBuilderSameDay => 'Diversos torns en un dia';

  @override
  String get patternBuilderSameDayHint =>
      'Activat: cada torn que toquis se suma a l’últim dia de la seqüència, en lloc de crear un dia nou.';

  @override
  String get patternBuilderRemoveLast => 'Treu l’últim';

  @override
  String get patternBuilderClear => 'Buida la seqüència';

  @override
  String patternBuilderAdd(String name) {
    return 'Afegeix $name';
  }

  @override
  String get patternStartLabel => 'Dia d’inici';

  @override
  String patternSuggestedStart(String weekday) {
    return 'Aquest patró sol començar un $weekday.';
  }

  @override
  String get patternWeekdayMonday => 'dilluns';

  @override
  String get patternWeekdayTuesday => 'dimarts';

  @override
  String get patternWeekdayWednesday => 'dimecres';

  @override
  String get patternWeekdayThursday => 'dijous';

  @override
  String get patternWeekdayFriday => 'divendres';

  @override
  String get patternWeekdaySaturday => 'dissabte';

  @override
  String get patternWeekdaySunday => 'diumenge';

  @override
  String get patternOffsetTitle => 'En quin dia del cicle ets aquell dia?';

  @override
  String patternOffsetHelp(String date) {
    return 'Toca el dia del patró que et toca el $date.';
  }

  @override
  String patternOffsetThatDay(String shifts) {
    return 'Aquell dia et toca: $shifts';
  }

  @override
  String patternChipDay(int day, String shifts) {
    return 'Dia $day: $shifts';
  }

  @override
  String get patternEndNever => 'Sense final';

  @override
  String get patternEndNeverHint => 'Es repeteix fins que el canviïs.';

  @override
  String get patternEndUntil => 'Fins a una data';

  @override
  String get patternEndUntilHint =>
      'Després d’aquesta data torna el que tenies.';

  @override
  String get patternUntilLabel => 'Últim dia';

  @override
  String get patternOverridesTitle => 'Dies que ja has canviat a mà';

  @override
  String get patternOverridesKeep => 'Respecta els dies que ja he canviat a mà';

  @override
  String get patternOverridesKeepHint =>
      'Els teus canvis es queden; el patró omple la resta.';

  @override
  String get patternOverridesReplace => 'Substitueix-los pel patró';

  @override
  String get patternOverridesReplaceHint =>
      'S’esborren els teus canvis a mà d’aquestes dates. Les notes es queden.';

  @override
  String get patternPreviewTitle => 'Així quedarà';

  @override
  String get patternPreviewNone => 'Tria un patró per veure com queda.';

  @override
  String patternPreviewPostNight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sortint automàtic: $count dies després d’una nit.',
      one: 'Sortint automàtic: 1 dia després d’una nit.',
    );
    return '$_temp0';
  }

  @override
  String get patternPickBanner => 'Toca el dia en què comença el patró';

  @override
  String get onboardingSkip => 'Omet';

  @override
  String get onboardingNext => 'Següent';

  @override
  String get onboardingContinue => 'Continua';

  @override
  String onboardingProgress(int current, int total) {
    return 'Pas $current de $total';
  }

  @override
  String get onboardingProfessionTitle => 'A què et dediques?';

  @override
  String get onboardingProfessionHelp =>
      'Així et deixem preparats els torns i les rotacions de la teva feina. Ho pots canviar quan vulguis.';

  @override
  String get onboardingProfessionNursing => 'Infermeria, TCAI i zeladors';

  @override
  String get onboardingProfessionNursingHint =>
      'M 08–15, T 15–22, N 22–08 i sortint';

  @override
  String get onboardingProfessionMedicine => 'Medicina (guàrdies)';

  @override
  String get onboardingProfessionMedicineHint =>
      'Matí, guàrdia de 24 h i sortint';

  @override
  String get onboardingProfessionPolice => 'Policia i Guàrdia Civil';

  @override
  String get onboardingProfessionPoliceHint => 'M 07–15, T 15–23 i N 23–07';

  @override
  String get onboardingProfessionFirefighters => 'Bombers';

  @override
  String get onboardingProfessionFirefightersHint =>
      'Guàrdia de 24 h i descansos llargs';

  @override
  String get onboardingProfessionIndustry => 'Indústria';

  @override
  String get onboardingProfessionIndustryHint =>
      'Torns rotatius: M 06–14, T 14–22 i N 22–06';

  @override
  String get onboardingProfessionSecurity => 'Seguretat privada';

  @override
  String get onboardingProfessionSecurityHint =>
      'Torns de 12 h, de dia i de nit';

  @override
  String get onboardingProfessionHospitality => 'Hostaleria i comerç';

  @override
  String get onboardingProfessionHospitalityHint => 'M 08–16 i T 16–00';

  @override
  String get onboardingProfessionOther => 'Altres';

  @override
  String get onboardingProfessionOtherHint =>
      'Comences amb els torns de sempre';

  @override
  String get onboardingPlaceTitle => 'On treballes?';

  @override
  String get onboardingPlaceHelp =>
      'Per marcar-te al calendari els festius de la teva comunitat i del teu municipi.';

  @override
  String get onboardingRegionLabel => 'Comunitat';

  @override
  String get onboardingRegionPick => 'Tria la comunitat';

  @override
  String get onboardingRegionSheetTitle => 'La teva comunitat';

  @override
  String get onboardingMunicipalityLabel => 'Municipi (opcional)';

  @override
  String get onboardingMunicipalityPick => 'Cerca el municipi';

  @override
  String get onboardingMunicipalityNeedsRegion => 'Tria abans la comunitat';

  @override
  String get onboardingMunicipalitySheetTitle => 'El teu municipi';

  @override
  String get onboardingMunicipalitySearch => 'Escriu el nom';

  @override
  String get onboardingMunicipalityNone => 'Cap municipi no es diu així';

  @override
  String get onboardingMunicipalityClear => 'Treu el municipi';

  @override
  String get onboardingLocalHolidaysMissing =>
      'Els festius locals del teu municipi els pots afegir tu en dos tocs.';

  @override
  String get onboardingRotationTitle => 'Com és la teva rotació?';

  @override
  String get onboardingRotationHelp =>
      'Tria la que s’hi assembli més. Després dius quan comences.';

  @override
  String get onboardingRotationTypical => 'El més habitual a la teva feina';

  @override
  String get onboardingRotationOthers => 'Altres rotacions';

  @override
  String get onboardingRotationAll => 'Rotacions';

  @override
  String get onboardingByHand => 'Ho pinto a mà';

  @override
  String get onboardingByHandHint =>
      'Sense rotació: pintes tu els dies al calendari.';

  @override
  String get onboardingStartTitle => 'Quan comences?';

  @override
  String get onboardingStartHelp =>
      'Digues des de quin dia compta i en quin punt del cicle ets aquell dia.';

  @override
  String get onboardingImportTitle => 'Vens d’una altra app?';

  @override
  String get onboardingImportBody =>
      'Si ja portaves els torns a LRHSoft (Shifter), Supershift o una altra app, porta’ls des de la seva còpia, el calendari del mòbil o un fitxer. També ho pots fer més tard, a Configuració.';

  @override
  String get onboardingReadyTitle => 'Tot a punt';

  @override
  String get onboardingReadyBody =>
      'El teu calendari està preparat. Tot això ho pots canviar quan vulguis a Configuració.';

  @override
  String onboardingReadyProfession(String name) {
    return 'Feina: $name';
  }

  @override
  String onboardingReadyPlace(String place) {
    return 'Festius: $place';
  }

  @override
  String onboardingReadyRotation(String name, String date) {
    return 'Rotació: $name, des de $date';
  }

  @override
  String onboardingReadyOffset(int day, String shifts) {
    return 'Comences al dia $day del cicle ($shifts)';
  }

  @override
  String get onboardingReadyByHand => 'Rotació: la pintes tu a mà';

  @override
  String get onboardingReadyNothing =>
      'No has triat res, així que comences amb el calendari en blanc.';

  @override
  String get onboardingReadySaveFailed =>
      'No s’ha pogut desar tot. Revisa els torns i els festius a Configuració.';

  @override
  String get onboardingOpenCalendar => 'Mostra el meu calendari';

  @override
  String get onboardingTipTitle => 'Pinta el mes en un moment';

  @override
  String get onboardingTipBody =>
      'Toca Pinta, tria un torn i arrossega pels dies. Amb el botó Patró repeteixes una rotació sencera d’un cop.';

  @override
  String get onboardingTipDismiss => 'Entesos';

  @override
  String get onboardingTipClose => 'Tanca el consell';

  @override
  String get paintScrollUp => 'Pujar pel mes';

  @override
  String get paintScrollDown => 'Baixar pel mes';

  @override
  String get monthTipPaint => 'Tria un torn i arrossega.';

  @override
  String get postNightAutoTitle => 'Sortint automàtic';

  @override
  String get postNightAutoHelp =>
      'Després d’una nit, l’endemà passa a Sortint si estava buit o lliure.';

  @override
  String get yearTitle => 'Vista anual';

  @override
  String get yearOpenTooltip => 'Mostra l’any';

  @override
  String get yearPrevious => 'Any anterior';

  @override
  String get yearNext => 'Any següent';

  @override
  String get yearShare => 'Comparteix com a imatge';

  @override
  String yearShareSubject(int year) {
    return 'Els meus torns del $year';
  }

  @override
  String get yearShareFailed => 'No s’ha pogut compartir la imatge';

  @override
  String yearImageTitle(int year) {
    return 'Els meus torns $year';
  }

  @override
  String get yearMonthEmpty => 'sense torns';

  @override
  String get yearLegendTitle => 'Torns de l’any';

  @override
  String get yearLegendEmpty => 'Aquest any no té torns.';

  @override
  String yearLegendDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get yearLegendHoliday => 'Festiu';

  @override
  String get summaryTitle => 'Resum';

  @override
  String get summaryOpenTooltip => 'Resum del mes';

  @override
  String get summaryModeMonth => 'Mes';

  @override
  String get summaryModeYear => 'Any';

  @override
  String get summaryModeRange => 'Dates…';

  @override
  String get summaryRangeFrom => 'Des de';

  @override
  String get summaryRangeTo => 'Fins a';

  @override
  String get summaryRangePrevious => 'Període anterior';

  @override
  String get summaryRangeNext => 'Període següent';

  @override
  String summaryRangeDays(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies en total',
      one: '1 dia en total',
    );
    return '$_temp0. Pots triar-ne fins a $max.';
  }

  @override
  String summaryRangeClamped(int max) {
    return 'El màxim són $max dies: hem escurçat la data final.';
  }

  @override
  String summaryRangePreviousName(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'els $days dies anteriors',
      one: 'el dia anterior',
    );
    return '$_temp0';
  }

  @override
  String get summaryRangeEmptyTitle => 'Sense torns en aquestes dates';

  @override
  String get summaryRangeEmptyBody =>
      'Tria unes altres dates o pinta torns al calendari.';

  @override
  String get summaryRangeNoteMidnight =>
      'Les hores d’un torn que passa la mitjanit es compten el dia que comença, també si és l’últim dia de les dates.';

  @override
  String get summaryEmptyTitle => 'Sense torns aquest mes';

  @override
  String get summaryEmptyBody =>
      'Pinta torns al calendari i aquí veuràs les hores i l’estimació.';

  @override
  String get summaryHoursWorked => 'Hores treballades';

  @override
  String get summaryShiftsWorked => 'Torns treballats';

  @override
  String get summaryNightHours => 'Hores nocturnes';

  @override
  String get summaryRestDays => 'Dies lliures';

  @override
  String get summaryAbsences => 'Absències';

  @override
  String get summaryHolidayHours => 'Hores en festiu';

  @override
  String summaryHolidayDetail(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count torns en festiu',
      one: '1 torn en festiu',
    );
    return '$_temp0';
  }

  @override
  String get summaryOvertime => 'Hores extra';

  @override
  String get summaryEarlyLeave => 'Sortides anticipades';

  @override
  String summaryExtrasPay(String amount) {
    return '$amount a l’estimació';
  }

  @override
  String get summaryExtrasNoRate =>
      'Hi ha hores extra o sortides en dies sense un torn amb preu per hora: no són a l’estimació.';

  @override
  String get summaryNoteExtras =>
      'Hores extra i sortides anticipades: les que anotes a cada dia. Les extra sumen i les sortides resten de les hores treballades (un dia no baixa de 0 h). Es valoren al preu per hora del primer torn amb preu d’aquell dia.';

  @override
  String summaryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String summaryShifts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count torns',
      one: '1 torn',
    );
    return '$_temp0';
  }

  @override
  String summaryNightOf(String hours) {
    return '$hours nocturnes';
  }

  @override
  String get summaryNoTimes => 'sense horari';

  @override
  String get summaryNoRate => 'sense preu';

  @override
  String get summaryGroupWork => 'Torns de feina';

  @override
  String get summaryGroupRest => 'Descansos';

  @override
  String get summaryEstimateTitle => 'Ingressos estimats';

  @override
  String get summaryFixedPluses => 'Plusos';

  @override
  String summaryFixedPlusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count torns',
      one: '1 torn',
    );
    return '$_temp0';
  }

  @override
  String get summaryEstimateNote => 'Estimació, abans d’impostos';

  @override
  String get summaryEstimateNone =>
      'Posa el preu per hora o el plus per torn a Els meus torns per veure l’estimació.';

  @override
  String summaryEstimateMissing(String types) {
    return 'No inclou el pagament per hora de $types: sense preu.';
  }

  @override
  String get summaryRateAction => 'Posa preus a Els meus torns';

  @override
  String summaryDelta(String delta, String month) {
    return '$delta respecte a $month';
  }

  @override
  String summaryDeltaSame(String month) {
    return 'Les mateixes hores que a $month';
  }

  @override
  String summaryDeltaNone(String month) {
    return 'Sense torns a $month per comparar';
  }

  @override
  String get summaryNotesTitle => 'Com es compta';

  @override
  String get summaryNoteMidnight =>
      'Les hores d’un torn que passa la mitjanit es compten el dia i el mes que comença.';

  @override
  String get summaryNoteNight =>
      'Nocturnes: de 22:00 a 06:00, tret que marquis una altra cosa al torn.';

  @override
  String get summaryNoteDst =>
      'Són hores de rellotge: la nit del canvi d’hora no s’ajusta a 7 o 9 hores.';

  @override
  String get summaryNoteNoTimes =>
      'Els torns sense horari compten com a torn, però no sumen hores.';

  @override
  String get summaryNoteHoliday =>
      'Hores en festiu: les que cauen en un festiu de la teva comunitat i municipi, també si el torn passa la mitjanit.';

  @override
  String get summaryYearEmpty => 'Aquest any no té torns.';

  @override
  String get summaryYearHint => 'Toca un mes per veure’n el detall.';

  @override
  String get summaryYearHeaderMonth => 'Mes';

  @override
  String get summaryYearHeaderShifts => 'Torns';

  @override
  String get summaryYearHeaderHours => 'Hores';

  @override
  String get summaryYearHeaderNight => 'Noct.';

  @override
  String get summaryYearHeaderEstimate => 'Estimat';

  @override
  String get summaryYearTotal => 'Total';

  @override
  String summaryYearEstimated(String amount) {
    return '$amount estimat';
  }

  @override
  String get summaryYearMonthEmpty => 'Sense torns';

  @override
  String get summaryYearRowTitle => 'Hores i estimació';

  @override
  String get summaryYearRowBody => 'Torns, hores i euros de cada mes';

  @override
  String summaryYearMonthSemantics(String month, String shifts, String hours) {
    return '$month: $shifts, $hours';
  }

  @override
  String get shareMonthTooltip => 'Comparteix el mes com a imatge';

  @override
  String shareMonthSubject(String month) {
    return 'Els meus torns: $month';
  }

  @override
  String get shareMonthFailed => 'No s’ha pogut compartir la imatge';

  @override
  String get shareMonthLegendTitle => 'Torns del mes';

  @override
  String get shareMonthLegendEmpty => 'Aquest mes no té torns.';

  @override
  String get saveFailed => 'No s’ha pogut desar el canvi';

  @override
  String get settingsTitle => 'Configuració';

  @override
  String get settingsOpenTooltip => 'Obre la configuració';

  @override
  String get settingsSectionSchedule => 'El teu quadrant';

  @override
  String get settingsShiftsTitle => 'Els meus torns';

  @override
  String get settingsShiftsSubtitle => 'Colors, codis i hores';

  @override
  String get settingsCalendarsTitle => 'Calendaris';

  @override
  String get settingsSectionAppearance => 'Aparença';

  @override
  String get settingsThemeTitle => 'Tema';

  @override
  String get settingsThemeSystemLight => 'Sistema (clar)';

  @override
  String get settingsThemeSystemDark => 'Sistema (fosc)';

  @override
  String get settingsThemeLight => 'Clar';

  @override
  String get settingsThemeDark => 'Fosc';

  @override
  String get settingsWeekStartTitle => 'Primer dia de la setmana';

  @override
  String get settingsWeekStartMonday => 'Dilluns';

  @override
  String get settingsWeekStartSunday => 'Diumenge';

  @override
  String get settingsWeekNumbersTitle => 'Mostra el número de setmana';

  @override
  String get settingsWeekNumbersSubtitle => 'Una columna a l’esquerra del mes';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String settingsLanguageSystem(String language) {
    return 'Sistema ($language)';
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
  String get settingsSaveFailed =>
      'No s’ha pogut desar la configuració. Torna-ho a provar.';

  @override
  String get settingsSectionMore => 'Avisos i dades';

  @override
  String get settingsHolidaysTitle => 'Festius';

  @override
  String get settingsAlarmsTitle => 'Alarmes';

  @override
  String get settingsBackupTitle => 'Còpia de seguretat';

  @override
  String get settingsPrivacyTitle => 'Política de privacitat';

  @override
  String get settingsPrivacySubtitle => 'S’obre al teu navegador';

  @override
  String get settingsPrivacyOpenFailed =>
      'No s’ha pogut obrir la política de privacitat. Torna-ho a provar.';

  @override
  String get faqAlarmsQIos =>
      'Com configuro les alarmes i què és el permís de notificacions?';

  @override
  String get faqAlarmsAIos =>
      'A Configuració › Alarmes activa «Avisa abans de cada torn», tria quanta antelació i, si vols, un avís el dia abans a una hora fixa. Al detall d’un dia pots treure’n l’alarma amb «Sense alarma aquest dia».\n\nSense el permís de notificacions, Turnly no et pot avisar. Si no et surt la finestra per permetre-les, activa-les a la configuració del sistema.';

  @override
  String get faqWidgetAIos =>
      'A Configuració › Afegeix un widget veus les mides (petit: avui i demà; mitjà: els propers 7 dies; gran: el mes sencer) i com col·locar-lo. Mantén premuda la pantalla d’inici, toca el + de dalt i cerca Turnly.\n\nEl widget desa els teus propers dies. El sistema decideix quan l’actualitza i pot endarrerir el canvi de dia. Si es queda sense dades, obre Turnly per posar-lo al dia.';

  @override
  String get faqBackupAIos =>
      'Configuració › Còpia de seguretat desa còpies automàtiques en aquest dispositiu després de cada canvi, però es perden si el perds o desinstal·les l’app. Exporta un fitxer amb «Exporta un fitxer» i desa’l a iCloud Drive o envia-te’l per WhatsApp o correu.\n\nPer canviar de dispositiu: exporta el fitxer, instal·la Turnly al nou, obre el fitxer amb l’app (o fes servir «Importa un fitxer» a la còpia de seguretat) i revisa la previsualització abans de restaurar. «Prova la restauració» comprova que la teva última còpia es pot recuperar sencera.';

  @override
  String get calExportPermissionDeniedBodyIos =>
      'Activa’l a la configuració del sistema (Turnly › Calendaris) i torna aquí.';

  @override
  String get backupUiWarningIos =>
      'Aquestes còpies es desen en aquest dispositiu. Si desinstal·les l’app sense una altra còpia, es perd. Exporta un fitxer i desa’l a iCloud Drive o envia’l per WhatsApp o correu.';

  @override
  String get backupUiExportSubtitleIos =>
      'Per desar-lo a iCloud Drive o enviar-lo per WhatsApp o correu';

  @override
  String get settingsSectionHelp => 'Ajuda';

  @override
  String get settingsHelpTitle => 'Ajuda i contacte';

  @override
  String get settingsHelpSubtitle => 'Escriu-nos si alguna cosa no va bé';

  @override
  String get settingsHelpBody =>
      'Tens dubtes o alguna cosa no va bé? Explica’ns què et passa i quina versió fas servir.';

  @override
  String get settingsHelpSubtitleSoon => 'Estem preparant el correu de suport';

  @override
  String get settingsHelpBodySoon =>
      'Encara no tenim correu de suport. Mentrestant, mira les preguntes freqüents i, si alguna cosa no va bé, tingues a mà la versió que fas servir.';

  @override
  String get settingsHelpNoEmail =>
      'El correu de suport arribarà amb la versió de la botiga.';

  @override
  String get settingsHelpCopyEmail => 'Copia el correu';

  @override
  String get settingsHelpCopyVersion => 'Copia la versió';

  @override
  String get settingsFaqTitle => 'Preguntes freqüents';

  @override
  String get settingsFaqSubtitle => 'Pintar, rotacions, alarmes, widget i més';

  @override
  String get faqIntro =>
      'Respostes ràpides sobre com funciona Turnly. Tot és en aquest dispositiu: no cal compte ni connexió.';

  @override
  String get faqNotFound => 'No trobes el que busques?';

  @override
  String get faqContact => 'Ajuda i contacte';

  @override
  String get faqPaintQ => 'Com pinto el mes?';

  @override
  String get faqPaintA =>
      'Toca «Pinta» al calendari, tria un torn a baix i toca els dies o passa-hi el dit per sobre. Per buidar un dia fes servir «Esborra». Cada traç es pot desfer i refer amb les fletxes de la barra. Toca «Fet» quan acabis.\n\nSi toques un dia sense estar pintant, se n’obre el detall: allà canvies el torn, hi afegeixes una nota o tornes al patró. Si mantens premut un dia, comences a triar-ne diversos alhora: els pots posar torn, copiar, retallar i enganxar, o repetir una setmana.';

  @override
  String get faqPatternQ => 'Com aplico una rotació i què és el desfasament?';

  @override
  String get faqPatternA =>
      'En mode pintar toca el botó «Patró» i segueix els passos: tria la teva rotació (o crea la teva), el dia que comences i fins quan es repeteix.\n\nEl desfasament és el punt del cicle on ets el dia d’inici. Si aquell dia et toca nit, al pas «En quin dia del cicle ets aquell dia?» toques la nit i la resta s’ajusta sola. Els dies que ja vas canviar a mà es respecten o se substitueixen, com prefereixis. Per acabar o treure una rotació, ves a Configuració › Les meves rotacions.';

  @override
  String get faqDoubleQ => 'Com doblo un torn?';

  @override
  String get faqDoubleA =>
      'Doblar és fer dos torns el mateix dia. Toca el dia i, al detall, fes servir «Afegeix un segon torn». Si estàs pintant, activa «Dobla» i toca els dies. Amb diversos dies triats, «Dobla amb…» afegeix el torn a tots.\n\nUn dia pot tenir els torns que calgui i cadascun suma les seves hores per separat.';

  @override
  String get faqPostNightQ => 'Què és el sortint automàtic?';

  @override
  String get faqPostNightA =>
      'És el descans de l’endemà d’una nit. Si l’actives a Configuració › Sortint automàtic, quan pintes o apliques una nit, l’endemà passa a Sortint si estava buit o lliure. Els dies que ja tenien un altre torn no es toquen. Ve desactivat.';

  @override
  String get faqNotesQ => 'Com faig servir les notes i l’agenda?';

  @override
  String get faqNotesA =>
      'Toca un dia i escriu al camp de la nota; els dies amb nota es marquen al calendari. Obre l’agenda des de dalt del calendari: «Notes» reuneix les notes i els festius propis; «Torns» mostra els torns propers.\n\nCerca per text, sense importar majúscules ni accents, o per data: per exemple, 15/10 o 15 oct. La cerca inclou totes les notes i els festius propis, i els torns des de fa un any fins d’aquí a un any.';

  @override
  String get faqAlarmsQ =>
      'Com configuro les alarmes i què és el permís d’alarmes exactes?';

  @override
  String get faqAlarmsA =>
      'A Configuració › Alarmes activa «Avisa abans de cada torn», tria quanta antelació i, si vols, un avís el dia abans a una hora fixa. Al detall d’un dia pots treure’n l’alarma amb «Sense alarma aquest dia».\n\nA Android calen les notificacions i el permís «Alarmes i recordatoris» de la configuració del sistema: sense, Android pot endarrerir l’avís uns minuts. La pantalla d’alarmes et diu què falta i et porta a la configuració. Si el teu mòbil estalvia bateria de manera agressiva, deixa Turnly sense restriccions perquè no aturi els avisos.';

  @override
  String get faqHolidaysQ => 'Com afegeixo un festiu local?';

  @override
  String get faqHolidaysA =>
      'A Configuració › Festius tria la teva comunitat i el teu municipi i veuràs els festius que et toquen. Si hi falta el del teu poble, toca aquell dia al calendari i activa «Festiu propi»: li poses nom i a partir d’aquell moment compta com a festiu.\n\nTambé pots portar festius del calendari del mòbil des de Configuració › Festius. Tria els calendaris i les dates i revisa la previsualització: només es llegeixen esdeveniments de tot el dia, s’ometen els festius que ja tens i pots desfer l’acció. No es canvien els esdeveniments del calendari.';

  @override
  String get faqWidgetQ => 'Com afegeixo el widget i per què canvia sol?';

  @override
  String get faqWidgetA =>
      'A Configuració › Afegeix un widget veus les mides (petit: avui i demà; mitjà: els propers 7 dies; gran: el mes sencer) i com col·locar-lo. A Android, mantén premuda una zona buida de la pantalla d’inici, tria Widgets i cerca Turnly.\n\nEl widget sempre mostra el dia d’avui: canvia de dia a mitjanit encara que no obris l’app, perquè porta desats els teus propers dies. Si passa molt de temps sense obrir Turnly, es queda sense dades i et demana que obris l’app per posar-se al dia.';

  @override
  String get faqBackupQ => 'Com faig una còpia i canvio de dispositiu?';

  @override
  String get faqBackupA =>
      'Configuració › Còpia de seguretat desa còpies automàtiques en aquest dispositiu després de cada canvi, però es perden si el perds o desinstal·les l’app. Exporta un fitxer amb «Exporta un fitxer» i desa’l a Drive o envia-te’l per WhatsApp o correu.\n\nPer canviar de dispositiu: exporta el fitxer, instal·la Turnly al nou, obre el fitxer amb l’app (o fes servir «Importa un fitxer» a la còpia de seguretat) i revisa la previsualització abans de restaurar. «Prova la restauració» comprova que la teva última còpia es pot recuperar sencera.';

  @override
  String get faqImportQ =>
      'Puc importar o exportar els meus torns al calendari?';

  @override
  String get faqImportA =>
      'Sí. A Configuració › Importa torns pots portar una còpia «.Shifter» de LRHSoft, torns del calendari del mòbil, un fitxer .ics o un CSV. A LRHSoft, crea una còpia a Menú › Còpia de seguretat › Còpia local i tria el fitxer de Documents › ShifterBackups. Revisa les dates, els tipus de torn i la previsualització abans d’importar.\n\n«Exporta al calendari del mòbil» copia els teus torns una vegada a un calendari del telèfon. Si tornes a exportar no es dupliquen: només es toquen els esdeveniments que va crear Turnly.';

  @override
  String get faqCalendarsQ => 'Puc portar diversos calendaris i comparar-los?';

  @override
  String get faqCalendarsA =>
      'Sí. A Configuració › Calendaris en crees un per a la teva parella, una segona feina o un fill: cadascun té les seves rotacions i els seus dies, i els tipus de torn són els mateixos. Amb dos o més, el nom del calendari damunt del mes et permet canviar de l’un a l’altre. El widget i les alarmes segueixen el calendari marcat com a «Widget i alarmes».\n\nPer veure quan coincidiu lliures, toca «Compara calendaris» en aquesta mateixa fulla: en tries dos i en veus els torns junts i els dies lliures en comú del mes.';

  @override
  String get faqSummaryQ => 'Com es calculen les hores i els euros?';

  @override
  String get faqSummaryA =>
      'La icona de resum del calendari mostra els torns, les hores, les nocturnes i les de festiu del mes, d’un any sencer o de les dates que triïs a «Dates…» (fins a 366 dies). Un torn compta el dia que comença, encara que passi la mitjanit.\n\nPer veure euros, posa el preu per hora i, si en tens, el plus fix per tipus de torn a Configuració › Els meus torns. L’estimació inclou aquests plusos fixos, abans d’impostos. No inclou plusos per hora nocturna o festiva ni retencions.\n\nEl «Plus per torn» se suma una vegada per cada torn treballat d’aquell tipus, també si és partit; no depèn de les hores. Els descansos i les absències no el sumen.';

  @override
  String get settingsVersionCopied => 'S’ha copiat la versió';

  @override
  String get settingsEmailCopied => 'S’ha copiat el correu';

  @override
  String get settingsAboutTitle => 'Quant a';

  @override
  String settingsAboutVersion(String version) {
    return 'Versió $version';
  }

  @override
  String get settingsAboutVersionDev => 'Versió de desenvolupament';

  @override
  String get settingsAboutTagline =>
      'Turnly funciona sense connexió i sense compte: els teus torns es queden al teu mòbil.';

  @override
  String get settingsAboutLicenses => 'Llicències de codi obert';

  @override
  String calendarWeekNumberSemantics(int number) {
    return 'Setmana $number';
  }

  @override
  String get importSectionTitle => 'Importa i exporta';

  @override
  String get importRowTitle => 'Importa torns';

  @override
  String get importRowSubtitle =>
      'Còpia de LRHSoft, calendari del mòbil, .ics o CSV';

  @override
  String get calExportRowTitle => 'Exporta torns';

  @override
  String get calExportRowSubtitle => 'Al calendari del mòbil, sense duplicats';

  @override
  String get importTitle => 'Importa torns';

  @override
  String importStepOf(int current, int total) {
    return 'Pas $current de $total';
  }

  @override
  String get importNext => 'Següent';

  @override
  String get importReading => 'S’està llegint…';

  @override
  String get importSourceTitle => 'D’on vénen els teus torns?';

  @override
  String get importSourceHelp =>
      'Turnly llegeix els esdeveniments aquí mateix, al teu mòbil, i no els envia enlloc. Tu decideixes què s’importa.';

  @override
  String get importSourceDevice => 'Calendari del mòbil';

  @override
  String get importSourceDeviceHelp =>
      'Google, iCloud, Outlook… el que tinguis a l’app de calendari.';

  @override
  String get importSourceIcs => 'Fitxer .ics';

  @override
  String get importSourceIcsHelp =>
      'Un calendari exportat, amb un torn per esdeveniment.';

  @override
  String get importSourceCsv => 'Fitxer CSV';

  @override
  String get importSourceCsvHelp =>
      'Un full amb una data i un torn a cada fila.';

  @override
  String get importSourceLrhsoft => 'Còpia de LRHSoft (Calendari de Torns)';

  @override
  String get importSourceLrhsoftHelp =>
      'El fitxer .Shifter de la teva còpia local';

  @override
  String get importFileLrhsoft => 'Còpia de LRHSoft';

  @override
  String get importHowToTitle => 'Vens de LRHSoft o Supershift?';

  @override
  String get importHowToBody =>
      'LRHSoft o Shifter: a l’app, Menú › Còpia de seguretat › Còpia local. Després tria aquí aquest fitxer .Shifter: és a la memòria del mòbil, a Documents › ShifterBackups.\nSupershift: exporta els teus torns al calendari del mòbil i tria «Calendari del mòbil».';

  @override
  String get calExportPermissionTitle => 'Falta el permís del calendari';

  @override
  String get calExportPermissionReadBody =>
      'Per importar, Turnly ha de llegir els esdeveniments dels teus calendaris. Només ho fa ara, mentre importes, i no desa res fora del mòbil.';

  @override
  String get calExportPermissionWriteBody =>
      'Per afegir els teus torns, Turnly necessita accés als teus calendaris. Només afegeix o canvia els seus propis esdeveniments, i només quan tu exportes. Si el calendari que triïs se sincronitza amb un compte (Google, iCloud...), aquest compte també rebrà els torns.';

  @override
  String get calExportPermissionAgainBody =>
      'No has donat el permís. Sense ell no podem fer servir els teus calendaris, però pots permetre-ho ara. Si el tornes a rebutjar, l’hauràs d’activar a la configuració del sistema.';

  @override
  String get calExportPermissionAllow => 'Permet l’accés';

  @override
  String get calExportPermissionDeniedTitle =>
      'L’accés al calendari està desactivat';

  @override
  String get calExportPermissionDeniedBody =>
      'Activa’l a la configuració del sistema (Permisos › Calendari) i torna aquí.';

  @override
  String get calExportPermissionSettings => 'Obre la configuració';

  @override
  String get calExportPermissionRecheck => 'Torna-ho a comprovar';

  @override
  String get calExportPermissionRestrictedTitle =>
      'Aquest mòbil no deixa fer servir el calendari';

  @override
  String get calExportPermissionRestrictedBody =>
      'Pot ser un control parental o un perfil de feina. Si importes, prova amb un fitxer .ics.';

  @override
  String get calExportPermissionWriteOnlyBody =>
      'El sistema només ha donat permís per afegir esdeveniments. Turnly necessita accés complet per llegir els calendaris o per substituir els esdeveniments d’una exportació anterior.';

  @override
  String get importCalendarsTitle => 'Tria els calendaris';

  @override
  String get importCalendarsHelp =>
      'Marca d’on vénen els teus torns. Els altres no es toquen.';

  @override
  String get importCalendarsEmpty => 'No hi ha calendaris en aquest mòbil.';

  @override
  String get importCalendarsNoAccount => 'Sense compte';

  @override
  String get importCalendarsReadOnly => 'Només lectura';

  @override
  String importCalendarSemantics(String name, String account) {
    return '$name, $account';
  }

  @override
  String get importRangeTitle => 'De quines dates?';

  @override
  String get importRangeHelp =>
      'Només es miren els esdeveniments d’aquests dies.';

  @override
  String get importRangeFrom => 'Des de';

  @override
  String get importRangeTo => 'Fins a';

  @override
  String get importRangeDefault => 'Últims 12 mesos i propers 6';

  @override
  String get importRangeInvalid =>
      'La data final no pot ser anterior a la inicial.';

  @override
  String get importRangeClamped =>
      'El màxim són 5 anys: s’ha retallat el principi.';

  @override
  String importRangeFile(String name) {
    return 'Fitxer: $name';
  }

  @override
  String importRangeFileEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'El fitxer porta $count esdeveniments.',
      one: 'El fitxer porta 1 esdeveniment.',
    );
    return '$_temp0';
  }

  @override
  String importRangeFileSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esdeveniments no tenen una data vàlida i no es llegiran.',
      one: '1 esdeveniment no té una data vàlida i no es llegirà.',
    );
    return '$_temp0';
  }

  @override
  String importRangeFileRules(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count esdeveniments tenen una repetició que no entenem i compten una sola vegada.',
      one: '1 esdeveniment té una repetició que no entenem i compta una sola vegada.',
    );
    return '$_temp0';
  }

  @override
  String get importColumnsTitle => 'Què és cada columna?';

  @override
  String get importColumnsHelp =>
      'Mira les primeres files i confirma quina és la data i quina el torn.';

  @override
  String get importColumnsHeader => 'La primera fila són els títols';

  @override
  String get importColumnDate => 'Data';

  @override
  String get importColumnTitle => 'Torn o codi';

  @override
  String get importColumnStart => 'Hora d’inici (opcional)';

  @override
  String get importColumnEnd => 'Hora de final (opcional)';

  @override
  String get importColumnNone => 'Cap';

  @override
  String importColumnNumber(int number) {
    return 'Columna $number';
  }

  @override
  String importColumnNamed(int number, String name) {
    return '$number: $name';
  }

  @override
  String get importColumnsScrollHint =>
      'Llisca cap als costats per veure totes les columnes.';

  @override
  String get importColumnsPreview => 'Primeres files';

  @override
  String get importMappingTitle => 'A quin torn correspon cada títol?';

  @override
  String get importMappingHelp =>
      'Agrupem els esdeveniments per títol. Tria un dels teus torns, crea’n un de nou o ignora’ls.';

  @override
  String importMappingSummary(int days, int groups) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dies',
      one: '1 dia',
    );
    String _temp1 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups títols',
      one: '1 títol',
    );
    return '$_temp0 en $_temp1';
  }

  @override
  String importMappingTruncated(String limit) {
    return 'Hi ha més de $limit esdeveniments: només s’han llegit els primers. Escurça les dates per veure la resta.';
  }

  @override
  String importMappingSkippedRows(int count, int line) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'S’han saltat $count files perquè no tenen una data o un torn vàlids (per exemple, la línia $line).',
      one:
          'S’ha saltat 1 fila perquè no té una data o un torn vàlids (per exemple, la línia $line).',
    );
    return '$_temp0';
  }

  @override
  String get importMappingNothing => 'Tria almenys un títol per importar.';

  @override
  String importGroupDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get importGroupAllDay => 'Tot el dia';

  @override
  String importGroupExamples(String dates) {
    return 'p. ex. $dates';
  }

  @override
  String get importGroupUntitled => 'Sense títol';

  @override
  String get importMapIgnore => 'Ignora';

  @override
  String get importMapCreate => 'Crea un tipus nou';

  @override
  String get importMapChoose => 'Tria el torn';

  @override
  String get importMapSuggested => 'Suggerit';

  @override
  String importMapNew(String name) {
    return 'Nou: $name';
  }

  @override
  String importMapPickTitle(String title) {
    return 'Quin torn és «$title»?';
  }

  @override
  String importMapSemantics(String title, String choice) {
    return '$title: $choice';
  }

  @override
  String get importNewTypeTitle => 'Tipus de torn nou';

  @override
  String get importNewTypeUse => 'Fes servir aquest tipus';

  @override
  String get importPreviewTitle => 'Així quedarà';

  @override
  String get importPreviewHelp =>
      'Revisa els mesos. No es desa res fins que toquis Importa.';

  @override
  String importPreviewTarget(String name) {
    return 'S’importa a «$name».';
  }

  @override
  String importPreviewDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S’escriuran $count dies.',
      one: 'S’escriurà 1 dia.',
    );
    return '$_temp0';
  }

  @override
  String importPreviewUnchanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies ja estaven igual.',
      one: '1 dia ja estava igual.',
    );
    return '$_temp0';
  }

  @override
  String importPreviewNewTypes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Es crearan $count tipus de torn nous.',
      one: 'Es crearà 1 tipus de torn nou.',
    );
    return '$_temp0';
  }

  @override
  String get importPreviewEmpty => 'Amb aquestes tries no canvia cap dia.';

  @override
  String importPreviewMoreMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'I $count mesos més sense mostrar.',
      one: 'I 1 mes més sense mostrar.',
    );
    return '$_temp0';
  }

  @override
  String importConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies ja tenen torn',
      one: '1 dia ja té torn',
    );
    return '$_temp0';
  }

  @override
  String get importConflictsHelp => 'Què en fem?';

  @override
  String get importConflictReplace => 'Substitueix';

  @override
  String get importConflictKeep => 'Mantén el meu';

  @override
  String importConflictsExamples(String dates) {
    return 'Per exemple: $dates';
  }

  @override
  String importApply(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importa $count dies',
      one: 'Importa 1 dia',
    );
    return '$_temp0';
  }

  @override
  String importApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S’han importat $count dies.',
      one: 'S’ha importat 1 dia.',
    );
    return '$_temp0';
  }

  @override
  String importAppliedWithTypes(int days, int types) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'S’han importat $days dies',
      one: 'S’ha importat 1 dia',
    );
    String _temp1 = intl.Intl.pluralLogic(
      types,
      locale: localeName,
      other: '$types tipus de torn nous',
      one: '1 tipus de torn nou',
    );
    return '$_temp0 i $_temp1.';
  }

  @override
  String get importUndoDone => 'S’ha desfet la importació.';

  @override
  String importUndoKeptTypes(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Es queden els tipus «$names»: alguna cosa els usa.',
      one: 'Es queda el tipus «$names»: alguna cosa l’usa.',
    );
    return '$_temp0';
  }

  @override
  String get importApplyFailed => 'No s’ha pogut importar. Torna-ho a provar.';

  @override
  String get importProblemPermissionDenied =>
      'Sense el permís no podem llegir els teus calendaris.';

  @override
  String get importProblemPermissionRestricted =>
      'Aquest mòbil no deixa que Turnly faci servir el calendari. Prova amb un fitxer.';

  @override
  String get importProblemCalendarUnavailable =>
      'Aquest mòbil no té calendaris disponibles.';

  @override
  String get importProblemReadFailed =>
      'No s’han pogut llegir els esdeveniments. Torna-ho a provar.';

  @override
  String get importProblemFileTooLarge =>
      'El fitxer pesa més de 5 MB. En exportar-lo, tria menys dates.';

  @override
  String get importProblemFileUnreadable =>
      'No hem pogut obrir aquest fitxer. Acceptem .csv, .ics i la còpia .Shifter de LRHSoft.';

  @override
  String get importProblemNotCalendar =>
      'Aquest fitxer no sembla un calendari .ics.';

  @override
  String get importProblemNotCsv =>
      'No hem trobat cap columna de dates en aquest CSV.';

  @override
  String get importProblemNoEvents =>
      'No hi ha esdeveniments en aquestes dates.';

  @override
  String get importProblemTooComplex =>
      'Aquest fitxer és massa gran o complicat i tarda massa. En exportar-lo, tria menys dates.';

  @override
  String get importProblemUnknown =>
      'Alguna cosa no ha anat bé en llegir el fitxer. Prova amb un altre.';

  @override
  String get importProblemNotLrhsoft =>
      'Aquest fitxer no sembla una còpia de LRHSoft (.Shifter). Prova de crear-ne una altra de local.';

  @override
  String importRangeLrhsoftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'La còpia porta $count dies.',
      one: 'La còpia porta 1 dia.',
    );
    return '$_temp0';
  }

  @override
  String importMappingInvalidRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S’han ignorat $count files no vàlides.',
      one: 'S’ha ignorat 1 fila no vàlida.',
    );
    return '$_temp0';
  }

  @override
  String get importLrhsoftNotImported =>
      'No s’hi porten les alarmes, els dibuixos, les fotos ni les hores extra.';

  @override
  String importNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String importApplyNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importa $count notes',
      one: 'Importa 1 nota',
    );
    return '$_temp0';
  }

  @override
  String importAppliedNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S’han importat $count notes.',
      one: 'S’ha importat 1 nota.',
    );
    return '$_temp0';
  }

  @override
  String importPreviewNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S’afegiran $count notes.',
      one: 'S’afegirà 1 nota.',
    );
    return '$_temp0';
  }

  @override
  String get calExportTitle => 'Exporta torns';

  @override
  String get calExportHelp =>
      'Afegeix els teus torns com a esdeveniments a un calendari del mòbil, una sola vegada. Si ho repeteixes, Turnly substitueix els seus esdeveniments anteriors en aquestes dates en lloc de duplicar-los.';

  @override
  String calExportSource(String name) {
    return 'S’exporten els torns de «$name».';
  }

  @override
  String get calExportCalendarLabel => 'Calendari';

  @override
  String get calExportNewCalendar => 'Crea el calendari «Turnly»';

  @override
  String get calExportNewCalendarHelp =>
      'Així el pots amagar o esborrar sencer quan vulguis.';

  @override
  String get calExportRangeLabel => 'Dates';

  @override
  String get calExportFrom => 'Des de';

  @override
  String get calExportTo => 'Fins a';

  @override
  String get calExportIncludeRest => 'Inclou els dies lliures';

  @override
  String get calExportIncludeRestHelp =>
      'Lliure i Sortint també s’afegeixen, com a esdeveniments de tot el dia.';

  @override
  String get calExportIncludeAbsences => 'Inclou les absències';

  @override
  String get calExportIncludeAbsencesHelp =>
      'Vacances, baixes i altres absències. S’afegirien a aquest calendari i al compte amb què se sincronitzi.';

  @override
  String calExportSynced(String account) {
    return 'Aquest calendari se sincronitza amb $account: els teus torns s’hi veuran.';
  }

  @override
  String get calExportSyncedUnnamed =>
      'Aquest calendari se sincronitza amb un compte: els teus torns s’hi veuran.';

  @override
  String calExportPlanAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S’afegiran $count esdeveniments.',
      one: 'S’afegirà 1 esdeveniment.',
    );
    return '$_temp0';
  }

  @override
  String calExportPlanReplace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se substituiran $count esdeveniments d’una exportació anterior.',
      one: 'Se substituirà 1 esdeveniment d’una exportació anterior.',
    );
    return '$_temp0';
  }

  @override
  String calExportPlanRemove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Es trauran $count esdeveniments d’una exportació anterior.',
      one: 'Es traurà 1 esdeveniment d’una exportació anterior.',
    );
    return '$_temp0';
  }

  @override
  String calExportPlanSame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esdeveniments ja estan al dia.',
      one: '1 esdeveniment ja està al dia.',
    );
    return '$_temp0';
  }

  @override
  String get calExportPlanNothing =>
      'Tot està al dia: no hi ha res per canviar.';

  @override
  String get calExportPlanNone => 'No hi ha torns en aquestes dates.';

  @override
  String get calExportButton => 'Exporta';

  @override
  String calExportRunning(int done, int total) {
    return 'S’està exportant… $done de $total';
  }

  @override
  String get calExportDoneTitle => 'Exportació feta';

  @override
  String get calExportDoneCalendar => 'S’ha creat el calendari «Turnly».';

  @override
  String calExportDoneCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esdeveniments afegits',
      one: '1 esdeveniment afegit',
    );
    return '$_temp0';
  }

  @override
  String calExportDoneReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esdeveniments anteriors substituïts',
      one: '1 esdeveniment anterior substituït',
    );
    return '$_temp0';
  }

  @override
  String calExportDoneRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esdeveniments trets',
      one: '1 esdeveniment tret',
    );
    return '$_temp0';
  }

  @override
  String calExportDoneSame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esdeveniments ja estaven al dia',
      one: '1 esdeveniment ja estava al dia',
    );
    return '$_temp0';
  }

  @override
  String calExportDoneFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'No s’han pogut escriure $count esdeveniments. Torna a exportar per completar-los.',
      one: 'No s’ha pogut escriure 1 esdeveniment. Torna a exportar per completar-lo.',
    );
    return '$_temp0';
  }

  @override
  String get calExportProblemPermission =>
      'Sense el permís no podem escriure al teu calendari.';

  @override
  String get calExportProblemUnavailable =>
      'Aquest mòbil no té calendaris disponibles.';

  @override
  String get calExportProblemFailed =>
      'No s’ha pogut exportar. Torna-ho a provar.';

  @override
  String get calExportRangeClamped =>
      'El màxim és un any: s’ha retallat el final.';

  @override
  String get onboardingImportButton => 'Importa ara';

  @override
  String get onboardingImportLrhsoftButton => 'Importa la còpia de LRHSoft';

  @override
  String get backupUiRowSubtitle => 'Automàtica, exportar i importar';

  @override
  String get backupUiStatusNoneTitle => 'Encara no hi ha cap còpia';

  @override
  String get backupUiStatusNoneBody =>
      'Fes-ne una ara: tarda un segon. Mentre no en tinguis, si perds el dispositiu o desinstal·les l’app, es perd el teu quadrant.';

  @override
  String get backupUiStatusLast => 'Última còpia';

  @override
  String get backupUiStatusWhere => 'En aquest dispositiu';

  @override
  String get backupUiStatusRunning => 'S’està desant la còpia…';

  @override
  String get backupUiStatusPending =>
      'Hi ha canvis nous: la còpia es farà d’aquí a uns segons.';

  @override
  String backupUiStatusPendingAt(String time) {
    return 'Hi ha canvis nous: la pròxima còpia es farà cap a les $time. Si no vols esperar, toca «Fes una còpia ara».';
  }

  @override
  String get backupUiStatusPendingLater =>
      'Hi ha canvis nous: la pròxima còpia es farà d’aquí a uns minuts. Si no vols esperar, toca «Fes una còpia ara».';

  @override
  String get backupUiStatusFailedTitle => 'L’última còpia automàtica ha fallat';

  @override
  String backupUiStatusFailedWithGood(String when, String good) {
    return 'Ho hem intentat $when i no s’ha pogut desar. La teva última còpia bona és de: $good.';
  }

  @override
  String backupUiStatusFailedNoGood(String when) {
    return 'Ho hem intentat $when i no s’ha pogut desar. Encara no tens cap còpia bona.';
  }

  @override
  String get backupUiFailDiskFull => 'El dispositiu no té espai lliure.';

  @override
  String get backupUiFailGeneric =>
      'No s’ha pogut escriure el fitxer de la còpia.';

  @override
  String get backupUiRetry => 'Torna-ho a provar';

  @override
  String get backupUiSystemOn => 'Còpia del sistema d’Android: activada';

  @override
  String get backupUiSystemOff =>
      'Còpia del sistema d’Android: desactivada. Activa-la a la configuració d’Android per tenir una altra còpia.';

  @override
  String get backupUiSystemUnknown =>
      'Còpia del sistema d’Android: no la podem comprovar des de l’app. Mira a la configuració d’Android que estigui activada.';

  @override
  String get backupUiWarning =>
      'Aquestes còpies es desen en aquest dispositiu. Si desinstal·les l’app sense una altra còpia, es perd. Exporta un fitxer i desa’l a Drive o envia’l per WhatsApp o correu.';

  @override
  String get backupUiBackupNow => 'Fes una còpia ara';

  @override
  String get backupUiBackupDone => 'Còpia feta';

  @override
  String get backupUiBackupFailed =>
      'No s’ha pogut fer la còpia. Les teves dades continuen com estaven.';

  @override
  String get backupUiAutoTitle => 'Còpies automàtiques';

  @override
  String get backupUiAutoOn =>
      'Després de canviar alguna cosa, sense que te n’adonis. Desem les 7 últimes i una per dia durant 30 dies.';

  @override
  String get backupUiAutoOff =>
      'Desactivades: només es copia quan tu ho demanes.';

  @override
  String get backupUiSectionFile => 'Fitxer';

  @override
  String get backupUiSectionCheck => 'Comprova';

  @override
  String get backupUiSectionCopies => 'Còpies en aquest dispositiu';

  @override
  String get backupUiExport => 'Exporta un fitxer';

  @override
  String get backupUiExportSubtitle =>
      'Per desar-lo a Drive o enviar-lo per WhatsApp o correu';

  @override
  String get backupUiExportFailed => 'No s’ha pogut exportar el fitxer.';

  @override
  String get backupUiSave => 'Desa al dispositiu';

  @override
  String get backupUiSaveSubtitle => 'Tria una carpeta, per exemple Baixades';

  @override
  String get backupUiSaveDone => 'Fitxer desat';

  @override
  String get backupUiSaveFailed =>
      'No s’ha pogut desar el fitxer. Prova una altra carpeta o fes servir «Exporta un fitxer».';

  @override
  String get backupUiImport => 'Importa un fitxer';

  @override
  String get backupUiImportSubtitle => 'Recupera un fitxer de Turnly';

  @override
  String get backupUiVerify => 'Prova la restauració';

  @override
  String get backupUiVerifySubtitle =>
      'Comprova que la teva última còpia es pot recuperar sencera';

  @override
  String get backupUiVerifyRunning => 'S’està comprovant la còpia…';

  @override
  String get backupUiVerifyNone =>
      'Encara no hi ha cap còpia per provar. Fes-ne una primer.';

  @override
  String backupUiVerifyOk(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'La còpia és completa: $days dies comprovats',
      one: 'La còpia és completa: 1 dia comprovat',
    );
    return '$_temp0';
  }

  @override
  String get backupUiVerifySame => 'És idèntica al que tens ara.';

  @override
  String backupUiVerifyOlder(String day) {
    return 'És anterior al que tens ara (el primer dia que canvia és $day). És normal si has fet canvis després.';
  }

  @override
  String get backupUiVerifyOlderNoDay =>
      'És anterior al que tens ara. És normal si has fet canvis després.';

  @override
  String backupUiVerifyMismatch(String day) {
    return 'La còpia no es reconstrueix igual. Primer dia diferent: $day. Fes una còpia nova i avisa’ns.';
  }

  @override
  String get backupUiVerifyMismatchNoDay =>
      'La còpia no es reconstrueix igual: les dades desades no coincideixen. Fes una còpia nova i avisa’ns.';

  @override
  String backupUiVerifyError(String reason) {
    return 'No s’ha pogut provar la còpia. $reason';
  }

  @override
  String get backupUiCopiesEmpty => 'Aquí apareixeran les teves còpies.';

  @override
  String get backupUiCopyLocal => 'Còpia del dispositiu';

  @override
  String get backupUiCopySafety => 'Abans de restaurar';

  @override
  String backupUiCopyMeta(String kind, String size) {
    return '$kind · $size';
  }

  @override
  String backupUiCopyMetaVersion(String kind, String version, String size) {
    return '$kind · $version · $size';
  }

  @override
  String get backupUiCopyRestore => 'Restaura aquesta';

  @override
  String backupUiCopyRestoreLabel(String when) {
    return 'Restaura la còpia de: $when';
  }

  @override
  String backupUiWhenToday(String time) {
    return 'avui a les $time';
  }

  @override
  String backupUiWhenYesterday(String time) {
    return 'ahir a les $time';
  }

  @override
  String backupUiWhenDate(String date, String time) {
    return '$date a les $time';
  }

  @override
  String get backupUiPreviewTitle => 'Restaura una còpia';

  @override
  String get backupUiPreviewReading => 'S’està llegint el fitxer…';

  @override
  String get backupUiOriginFile => 'Fitxer que has triat';

  @override
  String get backupUiOriginShared => 'Fitxer rebut d’una altra app';

  @override
  String get backupUiOriginLocal => 'Còpia d’aquest dispositiu';

  @override
  String get backupUiOriginSafety => 'Còpia de just abans de restaurar';

  @override
  String get backupUiOriginCloud => 'Còpia a iCloud';

  @override
  String backupUiPreviewSaved(String when) {
    return 'Desada $when';
  }

  @override
  String backupUiPreviewSender(String sender) {
    return 'Enviat des de: $sender';
  }

  @override
  String get backupUiPreviewSenderHint =>
      'Ho indica el dispositiu. Si no esperaves aquest fitxer, cancel·la.';

  @override
  String get backupUiPreviewTurnsOffTitle =>
      'Aquesta còpia desactiva opcions que tens activades';

  @override
  String get backupUiPreviewTurnsOffAuto =>
      'Desactiva les còpies automàtiques.';

  @override
  String get backupUiPreviewTurnsOffAlarms => 'Desactiva les alarmes de torn.';

  @override
  String get backupUiPreviewContains => 'Què porta';

  @override
  String backupUiPreviewNow(String value) {
    return 'Ara: $value';
  }

  @override
  String get backupUiPreviewCalendars => 'Calendaris';

  @override
  String backupUiPreviewArchived(String name) {
    return '$name (arxivat)';
  }

  @override
  String get backupUiPreviewDays => 'Dies amb torn o nota posats a mà';

  @override
  String get backupUiPreviewRuns => 'Rotacions';

  @override
  String get backupUiPreviewTypes => 'Tipus de torn';

  @override
  String get backupUiPreviewRange => 'Dates';

  @override
  String backupUiPreviewRangeValue(String from, String to) {
    return 'De $from a $to';
  }

  @override
  String backupUiPreviewRangeOpen(String from, String to) {
    return 'De $from a $to, i una rotació continua després';
  }

  @override
  String get backupUiPreviewRangeNone => 'Sense dates';

  @override
  String get backupUiPreviewReplace =>
      'Això substitueix el que tens ara; abans desem una còpia.';

  @override
  String get backupUiPreviewConfirm => 'Substitueix el que tinc';

  @override
  String get backupUiPreviewCancel => 'Cancel·la';

  @override
  String get backupUiRestoring => 'S’està restaurant el teu quadrant…';

  @override
  String get backupUiRestoringHint => 'No tanquis l’app.';

  @override
  String get backupUiDoneTitle => 'Fet, el teu quadrant està restaurat';

  @override
  String get backupUiDoneBody =>
      'Abans de canviar res, hem desat el que tenies. Si no era el que esperaves, pots tornar enrere.';

  @override
  String get backupUiDoneView => 'Mostra el meu calendari';

  @override
  String get backupUiDoneUndo => 'Torna a com estava';

  @override
  String get backupUiErrorNotOurs => 'Aquest fitxer no és una còpia de Turnly.';

  @override
  String get backupUiErrorNewer =>
      'Aquest fitxer és d’una versió més nova de Turnly: actualitza l’app.';

  @override
  String get backupUiErrorCorrupt =>
      'El fitxer està malmès o incomplet i no es pot fer servir.';

  @override
  String get backupUiErrorTooLarge =>
      'Aquest fitxer és massa gran per ser una còpia de Turnly.';

  @override
  String get backupUiErrorUnreadable => 'No s’ha pogut llegir el fitxer.';

  @override
  String get backupUiErrorUntouched =>
      'No hem canviat res: les teves dades continuen com estaven.';

  @override
  String get backupUiErrorRestoreFailed =>
      'No s’ha pogut restaurar. Les teves dades continuen com estaven.';

  @override
  String get backupUiErrorRestoreReload =>
      'Hem restaurat les teves dades, però la pantalla no s’ha pogut actualitzar. Tanca Turnly i torna’l a obrir.';

  @override
  String get backupUiBack => 'Torna';

  @override
  String get widgetWeekdaysShort => 'dl,dt,dc,dj,dv,ds,dg';

  @override
  String get widgetWeekdayHeaders => 'dl,dt,dc,dj,dv,ds,dg';

  @override
  String get widgetMonthNames =>
      'gener,febrer,març,abril,maig,juny,juliol,agost,setembre,octubre,novembre,desembre';

  @override
  String get widgetTomorrow => 'Demà';

  @override
  String get widgetEmptyCircular => '–';

  @override
  String get widgetStaleTitle => 'Turnly';

  @override
  String get widgetStaleBody => 'Obre Turnly per estar al dia';

  @override
  String get widgetAddTitle => 'Afegeix un widget';

  @override
  String get widgetAddSubtitle => 'El teu torn d’avui a la pantalla d’inici';

  @override
  String get widgetAddBody =>
      'El widget sempre mostra el dia d’avui, encara que no obris l’app.';

  @override
  String get widgetAddSmall => 'Petit: avui i demà';

  @override
  String get widgetAddMedium => 'Mitjà: els propers 7 dies';

  @override
  String get widgetAddLarge => 'Gran: el mes sencer';

  @override
  String get widgetAddAgenda => 'Agenda: propers torns';

  @override
  String get widgetAddTwoWeeks => 'Dues setmanes: actual i següent';

  @override
  String get widgetAddManualAndroid =>
      'Mantén premuda una zona buida de la pantalla d’inici, tria Widgets i cerca Turnly.';

  @override
  String get widgetAddManualIos =>
      'Mantén premuda la pantalla d’inici, toca el + de dalt i cerca Turnly.';

  @override
  String get compareTitle => 'Compara calendaris';

  @override
  String get compareOpen => 'Compara calendaris';

  @override
  String get compareOpenSubtitle => 'Mira quan coincidiu lliures';

  @override
  String get compareSwap => 'Intercanvia';

  @override
  String get compareIntro =>
      'Tria dos calendaris i mira’n els torns junts. Es marquen els dies lliures de tots dos.';

  @override
  String get compareFirstLabel => 'Primer calendari';

  @override
  String get compareSecondLabel => 'Segon calendari';

  @override
  String get comparePickTitle => 'Tria un calendari';

  @override
  String get compareNeedTwoTitle => 'Necessites dos calendaris';

  @override
  String get compareNeedTwoBody =>
      'Crea un altre calendari (la teva parella, una segona feina) per veure quan coincidiu lliures.';

  @override
  String compareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies lliures en comú aquest mes',
      one: '1 dia lliure en comú aquest mes',
      zero: 'Cap dia lliure en comú aquest mes',
    );
    return '$_temp0';
  }

  @override
  String get compareFreeListTitle => 'Dies lliures en comú';

  @override
  String get compareLegendFree => 'Lliures tots dos';

  @override
  String get compareNote =>
      'Compta com a lliure un dia sense torn de feina: buit, lliure o amb una absència (vacances, baixa…). Cada torn compta el dia que comença.';

  @override
  String get compareNoShiftMark => '–';

  @override
  String get compareBothFree => 'lliures tots dos';

  @override
  String compareCellCalendar(String calendar, String shifts) {
    return '$calendar: $shifts';
  }

  @override
  String get compareLoadFailed => 'No s’han pogut llegir els calendaris.';

  @override
  String get calendarsTitle => 'Calendaris';

  @override
  String get calendarsIntro =>
      'Cada calendari té el seu propi quadrant: el teu, el de la teva parella, una segona feina. Els tipus de torn són els mateixos a tots.';

  @override
  String get calendarsActiveBadge => 'Actiu';

  @override
  String get calendarsPrimaryBadge => 'Widget i alarmes';

  @override
  String get calendarsAdd => 'Calendari nou';

  @override
  String get calendarsNewTitle => 'Calendari nou';

  @override
  String get calendarsEditTitle => 'Edita el calendari';

  @override
  String get calendarsNameLabel => 'Nom';

  @override
  String get calendarsNameHint => 'Parella, segona feina…';

  @override
  String get calendarsColorLabel => 'Color';

  @override
  String calendarsColorOption(int index) {
    return 'Color $index';
  }

  @override
  String get calendarsCreate => 'Crea';

  @override
  String get calendarsMakePrimary =>
      'Fes-lo servir per al widget i les alarmes';

  @override
  String get calendarsPrimaryHelp =>
      'El widget i les alarmes segueixen aquest calendari encara que n’estiguis mirant un altre.';

  @override
  String get calendarsArchive => 'Arxiva';

  @override
  String calendarsArchiveTitle(String name) {
    return 'Vols arxivar «$name»?';
  }

  @override
  String get calendarsArchiveBody =>
      'Ja no sortirà a la llista, però el podràs recuperar des d’«Arxivats». Els seus torns es queden desats al mòbil.';

  @override
  String calendarsArchivePrimaryNote(String name) {
    return 'El widget i les alarmes passaran a «$name».';
  }

  @override
  String calendarsArchivedSection(int count) {
    return 'Arxivats ($count)';
  }

  @override
  String get calendarsRestore => 'Recupera';

  @override
  String calendarsRestoreSemantic(String name) {
    return 'Recupera «$name»';
  }

  @override
  String calendarsRestored(String name) {
    return 'S’ha recuperat «$name»';
  }

  @override
  String get calendarsLastError =>
      'No pots arxivar l’últim calendari: sempre n’hi ha d’haver un.';

  @override
  String get calendarsNameRequired => 'Posa un nom al calendari.';

  @override
  String get calendarsNotFoundError => 'Aquest calendari ja no existeix.';

  @override
  String get calendarsSaveFailed =>
      'No s’ha pogut desar el calendari. Torna-ho a provar.';

  @override
  String calendarsSwitcherLabel(String name) {
    return 'Calendari $name. Canvia de calendari';
  }

  @override
  String get calendarsSwitcherTitle => 'Canvia de calendari';

  @override
  String get calendarsSwitchFailed => 'No s’ha pogut canviar de calendari.';

  @override
  String get calendarsManage => 'Gestiona els calendaris';

  @override
  String get holidayImportAction => 'Porta festius del calendari del mòbil';

  @override
  String get holidayImportTitle => 'Festius';

  @override
  String get holidayImportHelp =>
      'Només esdeveniments de tot el dia. Tot es queda al teu mòbil; el teu calendari no canvia.';

  @override
  String get holidayImportRangeHelp => 'D’entrada, aquest any i el següent.';

  @override
  String get holidayImportSkipped => 'Ja existeix · s’omet';

  @override
  String get holidayImportReady => 'S’afegirà';

  @override
  String holidayImportIgnored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S’ometen $count esdeveniments amb hora.',
      one: 'S’omet 1 esdeveniment amb hora.',
    );
    return '$_temp0';
  }

  @override
  String holidayImportCapped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esdeveniments superen 31 dies: es retallen.',
      one: '1 esdeveniment supera 31 dies: es retalla.',
    );
    return '$_temp0';
  }

  @override
  String holidayImportAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Afegeix $count festius',
      one: 'Afegeix 1 festiu',
    );
    return '$_temp0';
  }

  @override
  String holidayImportAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count festius afegits',
      one: '1 festiu afegit',
    );
    return '$_temp0';
  }

  @override
  String get holidayImportEmpty => 'No hi ha festius nous.';

  @override
  String get holidayImportPreviewHelp =>
      'Les dates que ja tenen festiu s’ometen.';

  @override
  String get holidaysSettingsRegionTitle => 'Comunitat autònoma';

  @override
  String get holidaysSettingsRegionUnset => 'Sense triar';

  @override
  String get holidaysSettingsRegionClear => 'Sense comunitat';

  @override
  String get holidaysSettingsMunicipalityTitle => 'Municipi';

  @override
  String get holidaysSettingsMunicipalityNone => 'Cap';

  @override
  String get holidaysSettingsMunicipalitySearch => 'Cerca el municipi';

  @override
  String holidaysSettingsMunicipalityNoMatch(String query) {
    return 'Cap municipi no coincideix amb «$query»';
  }

  @override
  String get holidaysSettingsMunicipalityLoadFailed =>
      'No s’ha pogut carregar la llista de municipis.';

  @override
  String get holidaysSettingsStatusNoRegion =>
      'Sense comunitat només surten els festius estatals. Tria la teva per veure els autonòmics.';

  @override
  String get holidaysSettingsStatusNoMunicipality =>
      'Tria el teu municipi per veure’n els festius locals, o afegeix-los tu a sota.';

  @override
  String holidaysSettingsStatusLocalIncluded(String municipality) {
    return 'Festius locals de $municipality: inclosos';
  }

  @override
  String holidaysSettingsStatusYearPending(String year) {
    return 'Els festius oficials del $year arribaran amb una actualització';
  }

  @override
  String get holidaysSettingsStatusLocalMissing =>
      'Encara no tenim els del teu municipi: afegeix-los tu a sota';

  @override
  String holidaysSettingsStatusLocalMissingYear(
    String municipality,
    String year,
  ) {
    return 'Encara no tenim els de $municipality del $year: afegeix-los tu a sota';
  }

  @override
  String get holidaysSettingsStatusLocalPartial =>
      'Potser en falta algun: comprova’ls.';

  @override
  String get holidaysSettingsAdd => 'Afegeix un festiu local';

  @override
  String get holidaysSettingsAddName => 'Nom';

  @override
  String get holidaysSettingsAddDefaultName => 'Festa local';

  @override
  String holidaysSettingsEmptyYear(String year) {
    return 'Encara no tenim els festius del $year.';
  }

  @override
  String get holidaysSettingsScopeNational => 'Estatal';

  @override
  String get holidaysSettingsScopeLocal => 'Local';

  @override
  String get holidaysSettingsScopeUser => 'Teu';

  @override
  String holidaysSettingsNoteReplaces(String name) {
    return 'Substitueix: $name';
  }

  @override
  String holidaysSettingsNoteCovered(String name) {
    return 'Al teu calendari el tapa «$name»';
  }

  @override
  String holidaysSettingsSubstitutedTitle(String region) {
    return 'No són festius a: $region';
  }

  @override
  String get holidaysSettingsSubstitutedBody =>
      'Una comunitat pot canviar aquests festius estatals per uns de propis.';

  @override
  String get holidaysSettingsRemove => 'Treu el festiu';

  @override
  String holidaysSettingsRemoved(String name) {
    return 'Festiu tret: $name';
  }

  @override
  String holidaysSettingsRowSemantics(String date, String name, String scope) {
    return '$date. $name. $scope';
  }

  @override
  String alarmTitle(String name, String start) {
    return 'Torn: $name a les $start';
  }

  @override
  String alarmBody(String name, String start, String end) {
    return '$name: de $start a $end';
  }

  @override
  String get alarmChannelName => 'Alarmes de torn';

  @override
  String get alarmChannelDescription => 'T’avisa abans que comenci cada torn.';

  @override
  String alarmsNotifDayBeforeTitle(String name, String start) {
    return 'Demà: $name a les $start';
  }

  @override
  String get alarmsNotifSnooze => 'Ajorna 10 min';

  @override
  String get alarmsNotifAwake => 'Ja estic despert';

  @override
  String get alarmsNotifTestTitle => 'Avís de prova';

  @override
  String get alarmsNotifTestBody => 'Així t’avisarà Turnly abans del teu torn.';

  @override
  String get alarmsRowOn => 'Activades';

  @override
  String get alarmsRowOff => 'Desactivades';

  @override
  String get alarmsMasterTitle => 'Avisa abans de cada torn';

  @override
  String get alarmsMasterHelp =>
      'Un avís al mòbil, sense connexió i sense compte.';

  @override
  String get alarmsPermOkTitle => 'Tot a punt';

  @override
  String get alarmsPermOkBody =>
      'Les notificacions i les alarmes a l’hora exacta estan permeses.';

  @override
  String get alarmsPermOkBodyIos => 'Les notificacions estan permeses.';

  @override
  String get alarmsPermNotifTitle => 'Falten les notificacions';

  @override
  String get alarmsPermNotifBody =>
      'Sense el permís de notificacions, Turnly no et pot avisar. Si no et surt la finestra per permetre-les, activa-les a la configuració del sistema.';

  @override
  String get alarmsPermNotifAllow => 'Permet';

  @override
  String get alarmsPermNotifBlockedBody =>
      'Android ja no et pregunta per les notificacions. Activa-les a la configuració del sistema i Turnly et podrà avisar.';

  @override
  String get alarmsPermNotifBlockedBodyIos =>
      'L’iOS ja no et pregunta per les notificacions. Activa-les a Configuració › Turnly › Notificacions i Turnly et podrà avisar.';

  @override
  String get alarmsPermNotifOpenSettings => 'Obre la configuració';

  @override
  String get alarmsPermExactTitle => 'Alarmes i recordatoris';

  @override
  String get alarmsPermExactBody =>
      'Les alarmes poden arribar amb uns minuts de retard. Perquè sonin a l’hora exacta, permet «Alarmes i recordatoris» a la configuració del sistema.';

  @override
  String get alarmsPermExactOpen => 'Obre la configuració';

  @override
  String get alarmsSectionTypes => 'Tipus de torn';

  @override
  String get alarmsTypesEmpty =>
      'Cap dels teus torns no té horari. Posa-li hora a Els meus torns perquè Turnly et pugui avisar.';

  @override
  String get alarmsBeforeTitle => 'Abans del torn';

  @override
  String get alarmsBeforeAtStart => 'En començar';

  @override
  String get alarmsBeforeSheetTitle => 'Quanta antelació';

  @override
  String get alarmsBeforeCustom => 'Personalitzat';

  @override
  String get alarmsBeforeCustomTitle => 'Antelació personalitzada';

  @override
  String get alarmsBeforeCustomHelp =>
      'Hores i minuts abans que comenci el torn.';

  @override
  String get alarmsBeforeCustomApply => 'Desa';

  @override
  String get alarmsSecondSegmentTitle => 'Avisa també abans del segon tram';

  @override
  String get alarmsSecondSegmentHelper =>
      'Un segon avís, amb la mateixa antelació, abans de tornar a la feina.';

  @override
  String get alarmsDayBeforeTitle => 'Avís el dia abans';

  @override
  String alarmsDayBeforeAt(String time) {
    return 'A les $time';
  }

  @override
  String get alarmsDayBeforeTimeTitle => 'Hora de l’avís';

  @override
  String get alarmsLabelTitle => 'Text de l’avís';

  @override
  String get alarmsLabelDefault => 'El de sempre';

  @override
  String get alarmsLabelHint => 'Per exemple: A treballar';

  @override
  String get alarmsLabelApply => 'Desa';

  @override
  String get alarmsLabelReset => 'Fes servir el de sempre';

  @override
  String get alarmsTestButton => 'Prova l’avís';

  @override
  String get alarmsTestScheduled => 'T’avisarem d’aquí a 10 segons.';

  @override
  String get alarmsTestDenied =>
      'Sense el permís de notificacions no podem provar l’avís.';

  @override
  String alarmsNextLine(String when, String shift) {
    return 'Proper avís: $when · $shift';
  }

  @override
  String alarmsNextLineDayBefore(String when, String shift) {
    return 'Proper avís: $when · $shift, el dia abans';
  }

  @override
  String alarmsNextWhen(String weekday, int day, String month, String time) {
    return '$weekday $day $month, $time';
  }

  @override
  String get alarmsNextNone => 'No hi ha cap avís previst els propers dies.';

  @override
  String get alarmsNextOff => 'Les alarmes estan desactivades.';

  @override
  String get alarmsSkipDay => 'Sense alarma aquest dia';

  @override
  String get alarmsReminderTitle => 'Recordatori';

  @override
  String get alarmsReminderEmptyBody => 'Tens un recordatori per a avui';

  @override
  String get alarmsReminderChannelName => 'Recordatoris de notes';

  @override
  String get alarmsReminderChannelDescription =>
      'T’avisa a l’hora que triïs a la nota d’un dia.';

  @override
  String get dayReminderAdd => 'Avisa’m';

  @override
  String dayReminderAt(String time) {
    return 'Avís a les $time';
  }

  @override
  String get dayReminderChange => 'Canvia l’hora de l’avís';

  @override
  String get dayReminderRemove => 'Treu l’avís';

  @override
  String get dayReminderRemoved => 'Avís tret';

  @override
  String get dayReminderPickHelp => 'Hora de l’avís';

  @override
  String get dayReminderPast => 'Aquesta hora ja ha passat: no sonarà.';

  @override
  String get dayReminderNoPermission =>
      'Les notificacions estan desactivades, així que l’avís no sonarà. Activa-les a la configuració del mòbil.';

  @override
  String get dayReminderOnlyPrimary =>
      'Només sonen els avisos del calendari principal.';

  @override
  String agendaSemanticsReminder(String time) {
    return 'avís a les $time';
  }

  @override
  String get shiftTypesAlarmSection => 'Alarma';

  @override
  String get shiftTypesSoundLabel => 'So';

  @override
  String get shiftTypesSoundHelper =>
      'Sona amb el volum de les alarmes, quan activis l’alarma d’aquest torn a Configuració.';

  @override
  String get shiftTypesSoundDefault => 'Predeterminat';

  @override
  String get shiftTypesSoundCustom => 'So del mòbil';

  @override
  String get shiftTypesSoundMissing => 'No disponible: sona el predeterminat';

  @override
  String get shiftTypesSoundReset => 'Fes servir el predeterminat';

  @override
  String get catalogShiftMorningName => 'Matí';

  @override
  String get catalogShiftMorningCode => 'M';

  @override
  String get catalogShiftAfternoonName => 'Tarda';

  @override
  String get catalogShiftAfternoonCode => 'T';

  @override
  String get catalogShiftNightName => 'Nit';

  @override
  String get catalogShiftNightCode => 'N';

  @override
  String get catalogShiftRestName => 'Lliure';

  @override
  String get catalogShiftRestCode => 'L';

  @override
  String get catalogShiftGuard24Name => 'Guàrdia 24 h';

  @override
  String get catalogShiftGuard24Code => 'G';

  @override
  String get catalogShiftPostNightName => 'Sortint';

  @override
  String get catalogShiftPostNightCode => 'S';

  @override
  String get catalogShiftVacationName => 'Vacances';

  @override
  String get catalogShiftVacationCode => 'V';

  @override
  String get catalogShiftPersonalDayName => 'Lliure disposició';

  @override
  String get catalogShiftPersonalDayCode => 'LD';

  @override
  String get catalogShiftDay12Name => 'Dia 12 h';

  @override
  String get catalogShiftDay12Code => 'D';

  @override
  String get catalogShiftNight12Name => 'Nit 12 h';

  @override
  String get catalogShiftNight12Code => 'N12';

  @override
  String get catalogShiftSplitName => 'Partit';

  @override
  String get catalogShiftSplitCode => 'P';

  @override
  String get catalogPatternCorreturnosName => 'Torns rotatius';

  @override
  String get catalogPatternCorreturnosDescription =>
      '5 matins, 2 lliures, 5 tardes, 2 lliures, 5 nits, 2 lliures';

  @override
  String get catalogPattern24x72Name => '24 x 72';

  @override
  String get catalogPattern24x72Description => 'Guàrdia de 24 h i 72 h lliures';

  @override
  String get catalogPattern12hName => '12 hores';

  @override
  String get catalogPattern12hDescription =>
      'Dia 12 h, nit 12 h, sortint i lliure';

  @override
  String get catalogPattern6x4Name => '6 x 4';

  @override
  String get catalogPattern6x4Description => '6 matins i 4 lliures';

  @override
  String get catalogPattern4x4Name => '4 x 4';

  @override
  String get catalogPattern4x4Description => '4 dies de 12 h i 4 lliures';

  @override
  String get catalogPattern5x2Name => '5 x 2';

  @override
  String get catalogPattern5x2Description =>
      '5 matins i 2 lliures (de dilluns a divendres)';

  @override
  String get catalogPattern223Name => '2-2-3';

  @override
  String get catalogPattern223Description =>
      'Dos dies de 12 h, dos lliures, tres de 12 h, dos lliures, dos de 12 h i tres lliures (també 2-2-3-2-2-3)';

  @override
  String get catalogPatternContinentalName => 'Continental';

  @override
  String get catalogPatternContinentalDescription =>
      'Torn continu de 28 dies amb 4 equips: blocs de 2 i 3 matins, tardes i nits, i 7 lliures';

  @override
  String get catalogPatternDupontName => 'DuPont';

  @override
  String get catalogPatternDupontDescription =>
      'Cicle de 28 dies en torns de 12 h: 4 nits, 3 lliures, 3 dies, 1 lliure, 3 nits, 3 lliures, 4 dies i 7 lliures';

  @override
  String get holidayNameNewYear => 'Cap d’Any';

  @override
  String get holidayNameEpiphany => 'Reis';

  @override
  String get holidayNameMaundyThursday => 'Dijous Sant';

  @override
  String get holidayNameGoodFriday => 'Divendres Sant';

  @override
  String get holidayNameEasterMonday => 'Dilluns de Pasqua';

  @override
  String get holidayNameLabourDay => 'Festa del Treball';

  @override
  String get holidayNameAssumption => 'L’Assumpció';

  @override
  String get holidayNameNationalDay => 'Festa Nacional d’Espanya';

  @override
  String get holidayNameAllSaints => 'Tots Sants';

  @override
  String get holidayNameConstitution => 'Dia de la Constitució';

  @override
  String get holidayNameImmaculate => 'La Immaculada';

  @override
  String get holidayNameChristmas => 'Nadal';

  @override
  String get holidayNameStStephen => 'Sant Esteve';

  @override
  String get holidayNameStJoseph => 'Sant Josep';

  @override
  String get holidayNameStJames => 'Sant Jaume';

  @override
  String get holidayNameGaliciaDay => 'Dia de Galícia';

  @override
  String get holidayNameStJamesGalicia => 'Sant Jaume / Dia de Galícia';

  @override
  String get holidayNameCataloniaDay => 'Diada Nacional de Catalunya';

  @override
  String get holidayNameBasqueDay => 'Dia del País Basc';

  @override
  String get catalogCalendarMainName => 'El meu quadrant';

  @override
  String get historyUndone => 'Canvi desfet';

  @override
  String get historyRedone => 'Canvi refet';

  @override
  String get historyNothingToUndo => 'Res a desfer';

  @override
  String get historyNothingToRedo => 'Res a refer';

  @override
  String get monthPresentationGrid => 'Quadrícula';

  @override
  String get monthPresentationList => 'Llista';

  @override
  String get monthSelectDays => 'Selecciona dies';

  @override
  String get monthSelectDay => 'Toca per triar aquest dia';

  @override
  String get monthListRecommended =>
      'Llista recomanada per veure els horaris complets i el text gran.';

  @override
  String get monthListSelected => 'Presentació de llista';

  @override
  String get monthGridSelected => 'Presentació de quadrícula';
}
