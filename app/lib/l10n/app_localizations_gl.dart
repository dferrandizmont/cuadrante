// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Galician (`gl`).
class AppLocalizationsGl extends AppLocalizations {
  AppLocalizationsGl([String locale = 'gl']) : super(locale);

  @override
  String get appName => 'Cuadrante';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Pechar';

  @override
  String get delete => 'Borrar';

  @override
  String get save => 'Gardar';

  @override
  String get undo => 'Desfacer';

  @override
  String get redo => 'Refacer';

  @override
  String get retry => 'Tentar de novo';

  @override
  String get back => 'Atrás';

  @override
  String get loadingLabel => 'Cargando';

  @override
  String get errorGeneric => 'Algo non foi ben. Proba outra vez.';

  @override
  String get calendarToday => 'Hoxe';

  @override
  String calendarPickMonth(String month) {
    return '$month, escoller mes';
  }

  @override
  String get calendarPreviousMonth => 'Mes anterior';

  @override
  String get calendarNextMonth => 'Mes seguinte';

  @override
  String calendarHeaderTomorrow(String date, String shifts) {
    return 'Mañá ($date): quenda de $shifts';
  }

  @override
  String calendarHeaderTomorrowNone(String date) {
    return 'Mañá ($date): sen quenda';
  }

  @override
  String get todayLabelNow => 'Agora';

  @override
  String get todayLabelTonight => 'Esta noite';

  @override
  String get todayLabelToday => 'Hoxe';

  @override
  String get todayLabelFree => 'Hoxe libre';

  @override
  String get todayLabelDone => 'Hoxe rematado';

  @override
  String todayFinishedAt(String time) {
    return 'Rematou ás $time';
  }

  @override
  String get todayLabelGap => 'Pausa';

  @override
  String todayBackAt(String time) {
    return 'Volves ás $time';
  }

  @override
  String todayBackIn(String duration) {
    return 'Volves en $duration';
  }

  @override
  String get todayFreeTitle => 'Libre';

  @override
  String todayUntil(String time) {
    return 'Ata as $time';
  }

  @override
  String todayStartsIn(String duration) {
    return 'Comeza en $duration';
  }

  @override
  String todayEndsIn(String duration) {
    return 'Remata en $duration';
  }

  @override
  String todayNext(String name, String weekday, String time) {
    return 'Seguinte: $name, $weekday $time';
  }

  @override
  String get todayNoNext => 'Sen quendas á vista';

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
  String get calendarNoShift => 'Sen quenda';

  @override
  String calendarShiftWithTimes(String name, String times) {
    return '$name $times';
  }

  @override
  String get calendarWeekdayMon => 'L';

  @override
  String get calendarWeekdayTue => 'M';

  @override
  String get calendarWeekdayWed => 'M';

  @override
  String get calendarWeekdayThu => 'X';

  @override
  String get calendarWeekdayFri => 'V';

  @override
  String get calendarWeekdaySat => 'S';

  @override
  String get calendarWeekdaySun => 'D';

  @override
  String get daySemanticsToday => 'hoxe';

  @override
  String get daySemanticsNoShift => 'sen quenda';

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
    return '$name de $start a $end e de $start2 a $end2';
  }

  @override
  String daySemanticsAnd(String first, String second) {
    return '$first e $second';
  }

  @override
  String daySemanticsHoliday(String name) {
    return 'festivo: $name';
  }

  @override
  String get daySemanticsNote => 'con nota';

  @override
  String daySemanticsOvertime(String duration) {
    return 'horas extra: $duration';
  }

  @override
  String daySemanticsEarlyLeave(String duration) {
    return 'saída anticipada: $duration';
  }

  @override
  String daySheetHoliday(String name) {
    return 'Festivo: $name';
  }

  @override
  String get daySheetNote => 'Nota';

  @override
  String get daySheetEmpty => 'Este día non ten quenda.';

  @override
  String get dayPaneClose => 'Pechar o día';

  @override
  String get upcomingTitle => 'Próximos días';

  @override
  String get dayDetailSourcePattern => 'Segundo o teu patrón';

  @override
  String get dayDetailSourceOverride => 'Cambiado a man';

  @override
  String get dayDetailAdd => 'Engadir quenda';

  @override
  String get dayDetailDouble => 'Engadir unha segunda quenda';

  @override
  String get dayDetailReset => 'Volver ao patrón';

  @override
  String dayDetailPatternGives(String shifts) {
    return 'O patrón dá: $shifts';
  }

  @override
  String get dayDetailNoteHint => 'Escribe unha nota para este día';

  @override
  String get dayDetailUserHoliday => 'Festivo propio';

  @override
  String get dayDetailUserHolidayDefault => 'Festivo propio';

  @override
  String get dayDetailUserHolidayNameHint => 'Nome do festivo';

  @override
  String get dayDetailDuplicate => 'Duplicar noutro día';

  @override
  String get dayDetailDuplicateHelp => 'Copiar neste día';

  @override
  String dayDetailDuplicated(String date) {
    return 'Copiado: $date';
  }

  @override
  String get dayDetailClear => 'Borrar día';

  @override
  String get dayDetailCleared => 'Día borrado';

  @override
  String get dayDetailMoveUp => 'Subir';

  @override
  String get dayDetailMoveDown => 'Baixar';

  @override
  String dayDetailRemove(String name) {
    return 'Quitar $name';
  }

  @override
  String get dayExtrasTitle => 'Horas extra / Saín antes';

  @override
  String get dayExtrasOvertime => 'Horas extra';

  @override
  String get dayExtrasEarlyLeave => 'Saín antes';

  @override
  String get dayExtrasNone => 'Ningunha';

  @override
  String get dayExtrasHelper =>
      'Suman ou restan nas horas do mes e na estimación. Con 0 quítase.';

  @override
  String dayExtrasMore(String label) {
    return 'Máis $label';
  }

  @override
  String dayExtrasLess(String label) {
    return 'Menos $label';
  }

  @override
  String dayExtrasValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get shiftTypesTitle => 'As miñas quendas';

  @override
  String get shiftTypesEditEntry => 'Editar quendas';

  @override
  String get shiftTypesEmptyTitle => 'Non tes quendas';

  @override
  String get shiftTypesEmptyMessage =>
      'Crea a primeira para poder pintala no calendario.';

  @override
  String get shiftTypesNew => 'Nova quenda';

  @override
  String get shiftTypesNewTitle => 'Nova quenda';

  @override
  String get shiftTypesEditTitle => 'Editar quenda';

  @override
  String get shiftTypesNotFound => 'Non atopamos esta quenda';

  @override
  String get shiftTypesNotFoundMessage =>
      'Pode que a arquivases. Volve á lista de quendas.';

  @override
  String get shiftTypesArchive => 'Arquivar';

  @override
  String shiftTypesArchiveTitle(String name) {
    return 'Queres arquivar «$name»?';
  }

  @override
  String get shiftTypesArchiveBody =>
      'Deixará de saír ao pintar. Os días que xa a usan seguirana amosando.';

  @override
  String get shiftTypesArchiveConfirm => 'Arquivar';

  @override
  String get shiftTypesDragHandle => 'Arrastrar para reordenar';

  @override
  String shiftTypesArchivedSection(int count) {
    return 'Arquivadas ($count)';
  }

  @override
  String get shiftTypesArchivedHelp =>
      'Deixaron de saír ao pintar. Recupéraas e volven á paleta.';

  @override
  String get shiftTypesRestore => 'Recuperar';

  @override
  String shiftTypesRestoreSemantic(String name) {
    return 'Recuperar «$name»';
  }

  @override
  String shiftTypesRestored(String name) {
    return '«$name» recuperada';
  }

  @override
  String get shiftTypesDiscardTitle => 'Queres descartar os cambios?';

  @override
  String get shiftTypesDiscardBody =>
      'O que cambiaches nesta quenda non se gardará.';

  @override
  String get shiftTypesDiscardKeep => 'Seguir editando';

  @override
  String get shiftTypesDiscardConfirm => 'Descartar';

  @override
  String get shiftTypesNoTimes => 'Sen horario';

  @override
  String shiftTypesRatePerHour(String rate) {
    return '$rate/h';
  }

  @override
  String shiftTypesFixedPlusPerShift(String amount) {
    return '+$amount por quenda';
  }

  @override
  String get shiftTypesCategoryWork => 'Traballo';

  @override
  String get shiftTypesCategoryRest => 'Descanso';

  @override
  String get shiftTypesCategoryAbsence => 'Ausencia';

  @override
  String get shiftTypesNameLabel => 'Nome';

  @override
  String get shiftTypesCodeLabel => 'Código';

  @override
  String get shiftTypesCodeHelper =>
      'De 1 a 3 caracteres. É o que se ve en cada casa do mes.';

  @override
  String get shiftTypesColorLabel => 'Cor';

  @override
  String shiftTypesColorOption(int number, int total) {
    return 'Cor $number de $total';
  }

  @override
  String shiftTypesColorOptionNamed(String name, int number, int total) {
    return '$name, $number de $total';
  }

  @override
  String get shiftColorNameOrange => 'Laranxa';

  @override
  String get shiftColorNameCoral => 'Coral';

  @override
  String get shiftColorNameIndigo => 'Índigo';

  @override
  String get shiftColorNameLightGrey => 'Gris claro';

  @override
  String get shiftColorNameRed => 'Vermello';

  @override
  String get shiftColorNameLilac => 'Lila';

  @override
  String get shiftColorNameGreen => 'Verde';

  @override
  String get shiftColorNameTeal => 'Turquesa';

  @override
  String get shiftColorNameRaspberry => 'Framboesa';

  @override
  String get shiftColorNamePink => 'Rosa';

  @override
  String get shiftColorNameTangerine => 'Mandarina';

  @override
  String get shiftColorNameYellow => 'Amarelo';

  @override
  String get shiftColorNameLime => 'Lima';

  @override
  String get shiftColorNameForest => 'Verde bosque';

  @override
  String get shiftColorNameMint => 'Menta';

  @override
  String get shiftColorNameCyan => 'Cian';

  @override
  String get shiftColorNameSkyBlue => 'Azul ceo';

  @override
  String get shiftColorNameBlue => 'Azul';

  @override
  String get shiftColorNameCobalt => 'Cobalto';

  @override
  String get shiftColorNameViolet => 'Violeta';

  @override
  String get shiftColorNamePurple => 'Morado';

  @override
  String get shiftColorNameBrown => 'Marrón';

  @override
  String get shiftColorNameGrey => 'Gris';

  @override
  String get shiftColorNameGraphite => 'Grafito';

  @override
  String get shiftTypesColorCurrent => 'Cor actual';

  @override
  String get shiftTypesIconLabel => 'Icona';

  @override
  String get shiftTypesIconHelper =>
      'Opcional. Vese xunto ao código cando hai sitio; o código e a cor sempre están.';

  @override
  String get shiftTypesIconNone => 'Sen icona';

  @override
  String get shiftTypesIconChoose => 'Escoller icona';

  @override
  String shiftTypesIconCurrent(String name) {
    return 'Icona: $name';
  }

  @override
  String get shiftIconNameSun => 'Sol';

  @override
  String get shiftIconNameMoon => 'Lúa';

  @override
  String get shiftIconNameSunrise => 'Amencer';

  @override
  String get shiftIconNameHospital => 'Hospital';

  @override
  String get shiftIconNameAmbulance => 'Ambulancia';

  @override
  String get shiftIconNamePolice => 'Policía';

  @override
  String get shiftIconNameFire => 'Bombeiros';

  @override
  String get shiftIconNameFactory => 'Fábrica';

  @override
  String get shiftIconNameTruck => 'Camión';

  @override
  String get shiftIconNamePlane => 'Avión';

  @override
  String get shiftIconNameSchool => 'Colexio';

  @override
  String get shiftIconNameHome => 'Casa';

  @override
  String get shiftIconNameBeach => 'Praia';

  @override
  String get shiftIconNameBed => 'Cama';

  @override
  String get shiftIconNameStar => 'Estrela';

  @override
  String get shiftIconNameHeart => 'Corazón';

  @override
  String get shiftIconNameCoffee => 'Café';

  @override
  String get shiftIconNameBook => 'Libro';

  @override
  String get shiftIconNameMoney => 'Diñeiro';

  @override
  String get shiftIconNameAlert => 'Aviso';

  @override
  String get shiftIconNamePhone => 'Teléfono';

  @override
  String get shiftIconNameCar => 'Coche';

  @override
  String get shiftIconNameTrain => 'Tren';

  @override
  String get shiftIconNameBus => 'Autobús';

  @override
  String get shiftIconNameShop => 'Tenda';

  @override
  String get shiftIconNameTool => 'Ferramentas';

  @override
  String get shiftIconNameBaby => 'Bebé';

  @override
  String get shiftIconNameSport => 'Deporte';

  @override
  String get shiftIconNameParty => 'Festa';

  @override
  String get shiftIconNameMedical => 'Médico';

  @override
  String get shiftTypesColorMore => 'Máis cores…';

  @override
  String get shiftTypesColorPickerTitle => 'Escolle a túa cor';

  @override
  String get shiftTypesColorPickerHelp =>
      'Mira como queda a casa en claro e en escuro. O texto axústase só para que se lea ben.';

  @override
  String get shiftTypesColorHue => 'Ton';

  @override
  String get shiftTypesColorSaturation => 'Intensidade';

  @override
  String get shiftTypesColorLightness => 'Luminosidade';

  @override
  String shiftTypesColorHueSpoken(int degrees) {
    return '$degrees graos';
  }

  @override
  String shiftTypesColorPercentSpoken(int percent) {
    return '$percent por cento';
  }

  @override
  String get shiftTypesColorHexLabel => 'Código hexadecimal';

  @override
  String get shiftTypesColorHexError =>
      'Escribe 6 cifras ou letras da A á F, por exemplo #1C7ED6.';

  @override
  String get shiftTypesColorUse => 'Usar esta cor';

  @override
  String get shiftTypesCategoryLabel => 'Categoría';

  @override
  String get shiftTypesTimesLabel => 'Horario';

  @override
  String shiftTypesStarts(String time) {
    return 'Comeza $time';
  }

  @override
  String shiftTypesEnds(String time) {
    return 'Remata $time';
  }

  @override
  String get shiftTypesPickStart => 'Hora de inicio';

  @override
  String get shiftTypesPickEnd => 'Hora de fin';

  @override
  String shiftTypesDuration(String duration) {
    return 'Dura $duration';
  }

  @override
  String shiftTypesEndsNextDay(String duration) {
    return 'Remata ao día seguinte · dura $duration';
  }

  @override
  String get shiftTypesTwentyFourHours =>
      'Dura 24 h: remata ao día seguinte á mesma hora';

  @override
  String get shiftTypesSplitLabel => 'Quenda partida';

  @override
  String get shiftTypesSplitHelper =>
      'Dous tramos o mesmo día, cunha pausa no medio que non conta como traballada.';

  @override
  String get shiftTypesSplitTemplate => 'Usar «Partida 09–13 / 17–21»';

  @override
  String get shiftTypesSplitSecondTitle => 'Segundo tramo';

  @override
  String get shiftTypesPickSecondStart => 'Inicio do tramo 2';

  @override
  String get shiftTypesPickSecondEnd => 'Fin do tramo 2';

  @override
  String shiftTypesSplitSummary(String first, String second, String total) {
    return 'Traballas $first e $second: $total en total';
  }

  @override
  String get shiftTypesErrorSplitIncomplete =>
      'Pon cando comeza e cando remata o segundo tramo, ou desactiva a quenda partida.';

  @override
  String get shiftTypesErrorSplitStart =>
      'A hora de inicio do segundo tramo non é válida.';

  @override
  String get shiftTypesErrorSplitDuration =>
      'O segundo tramo ten que durar entre 1 minuto e 24 h.';

  @override
  String get shiftTypesErrorSplitNotAfter =>
      'O segundo tramo non pode comezar xusto cando remata o primeiro: sería un só tramo. Deixa unha pausa entre os dous.';

  @override
  String get shiftTypesErrorSplitTooLong =>
      'Os dous tramos e a pausa entre eles non caben en 24 h. Comproba que o segundo comeza despois de que remate o primeiro.';

  @override
  String get shiftTypesBreakLabel => 'Pausa non pagada';

  @override
  String get shiftTypesBreakUnit => 'min';

  @override
  String get shiftTypesBreakHint => '0 min';

  @override
  String get shiftTypesRateHint => 'Sen prezo';

  @override
  String get shiftTypesBreakHelper =>
      'Minutos da quenda que non se pagan. Déixao baleiro se se paga todo.';

  @override
  String shiftTypesPaidHelper(String duration) {
    return 'Páganse $duration';
  }

  @override
  String get shiftTypesNightLabel => 'Quenda nocturna';

  @override
  String get shiftTypesNightHelper =>
      'Automático conta como noite as horas entre as 22:00 e as 06:00.';

  @override
  String get shiftTypesNightAuto => 'Automático';

  @override
  String get shiftTypesNightAlways => 'Sempre nocturna';

  @override
  String get shiftTypesNightNever => 'Nunca nocturna';

  @override
  String get shiftTypesFixedPlusLabel => 'Plus por quenda (opcional)';

  @override
  String get shiftTypesFixedPlusHelper =>
      'Súmase unha vez por cada quenda traballada.';

  @override
  String get shiftTypesFixedPlusHint => 'Sen plus';

  @override
  String get shiftTypesFixedPlusUnit => '€';

  @override
  String get shiftTypesRateLabel => 'Prezo por hora (opcional)';

  @override
  String get shiftTypesRateHelper =>
      'Para calcular canto gañas no resumo do mes.';

  @override
  String get shiftTypesRateUnit => '€/h';

  @override
  String get shiftTypesPreviewLabel => 'Así se verá no mes';

  @override
  String get shiftTypesPreviewLight => 'Claro';

  @override
  String get shiftTypesPreviewDark => 'Escuro';

  @override
  String shiftTypesPreviewContrast(String ratio) {
    return 'Contraste $ratio:1';
  }

  @override
  String get shiftTypesErrorCodeEmpty =>
      'Escribe un código de 1 a 3 caracteres';

  @override
  String get shiftTypesErrorCodeTooLong =>
      'O código admite ata 3 caracteres, sen emojis nin espazos';

  @override
  String shiftTypesErrorCodeTaken(String name) {
    return 'Este código xa o usa «$name»';
  }

  @override
  String get shiftTypesErrorNameEmpty => 'Ponlle un nome á quenda';

  @override
  String get shiftTypesErrorBreak =>
      'A pausa ten que ser menor que a duración da quenda';

  @override
  String get shiftTypesErrorRate =>
      'Escribe un importe válido, por exemplo 12,50';

  @override
  String get paintFab => 'Pintar';

  @override
  String get paintHeader => 'Pintando';

  @override
  String paintHeaderShift(String name, String times) {
    return '$name · $times';
  }

  @override
  String get paintDone => 'Feito';

  @override
  String get paintDouble => 'Dobrar';

  @override
  String get paintEraser => 'Borrar';

  @override
  String get paintToolsLabel => 'Ferramentas para pintar';

  @override
  String get selectionHeader => 'Selección';

  @override
  String get selectionHint =>
      'Toca os días ou mantén premido e arrastra para escoller varios';

  @override
  String selectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
      zero: 'Ningún día',
    );
    return '$_temp0';
  }

  @override
  String get selectionBarLabel => 'Accións para os días escollidos';

  @override
  String get selectionSetShift => 'Poñer quenda…';

  @override
  String get selectionDouble => 'Dobrar con…';

  @override
  String get selectionClear => 'Borrar';

  @override
  String get selectionReset => 'Volver ao patrón';

  @override
  String get selectionCopy => 'Copiar';

  @override
  String get selectionCut => 'Cortar';

  @override
  String get selectionPaste => 'Pegar';

  @override
  String get selectionRepeat => 'Repetir…';

  @override
  String get selectionNote => 'Nota…';

  @override
  String get selectionCancel => 'Cancelar';

  @override
  String get selectionCellSelected => 'escollido';

  @override
  String get selectionSetShiftTitle => 'Poñer quenda';

  @override
  String get selectionSetShiftHelp =>
      'Substitúe as quendas dos días escollidos.';

  @override
  String get selectionDoubleTitle => 'Engadir unha segunda quenda';

  @override
  String get selectionDoubleHelp =>
      'Engade a quenda ás que xa teñan os días escollidos.';

  @override
  String get selectionNoteTitle => 'Nota para os días escollidos';

  @override
  String get selectionNoteHint => 'A mesma nota en todos os días';

  @override
  String get selectionNoteSave => 'Gardar nota';

  @override
  String get selectionNoteRemove => 'Quitar notas';

  @override
  String get selectionPasteTitle => 'Pegar días';

  @override
  String selectionPasteSummary(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Péganse $count días',
      one: 'Pégase 1 día',
    );
    return '$_temp0 a partir do $date.';
  }

  @override
  String selectionPasteReach(String from, String to) {
    return 'Pegarase do $from ao $to.';
  }

  @override
  String get selectionPasteReplaces =>
      'As quendas deses días substitúense. Poderás desfacelo.';

  @override
  String get selectionIncludeNotes => 'Incluír notas';

  @override
  String get selectionIncludeNotesHelp =>
      'As notas dos días copiados substitúen as que haxa no destino.';

  @override
  String get selectionCutNotesMove => 'Ao cortar, as notas móvense cos días.';

  @override
  String get selectionPasteConfirm => 'Pegar';

  @override
  String get selectionRepeatTitle => 'Repetir os días escollidos';

  @override
  String selectionRepeatTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veces',
      one: '1 vez',
    );
    return '$_temp0';
  }

  @override
  String get selectionRepeatLess => 'Unha vez menos';

  @override
  String get selectionRepeatMore => 'Unha vez máis';

  @override
  String selectionRepeatPreview(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cambia $count días máis, ata o $date.',
      one: 'Cambia 1 día máis, ata o $date.',
    );
    return '$_temp0';
  }

  @override
  String get selectionRepeatConfirm => 'Repetir';

  @override
  String selectionChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días cambiados',
      one: '1 día cambiado',
    );
    return '$_temp0';
  }

  @override
  String get selectionNothingChanged => 'Eses días xa estaban así';

  @override
  String selectionCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días copiados',
      one: '1 día copiado',
    );
    return '$_temp0. Escolle o día de inicio e preme Pegar.';
  }

  @override
  String selectionCutDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días cortados',
      one: '1 día cortado',
    );
    return '$_temp0. Escolle o día de inicio e preme Pegar.';
  }

  @override
  String selectionPasted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días pegados',
      one: '1 día pegado',
    );
    return '$_temp0';
  }

  @override
  String selectionRepeated(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: '$times veces',
      one: '1 vez',
    );
    return 'Repetido $_temp0';
  }

  @override
  String get selectionRunsTitle => 'As miñas rotacións';

  @override
  String get selectionRunsSubtitle => 'Remata ou quita un patrón dunha vez';

  @override
  String get selectionRunsEmptyTitle => 'Sen rotacións';

  @override
  String get selectionRunsEmptyMessage =>
      'Cando apliques un patrón desde Pintar, aparecerá aquí.';

  @override
  String selectionRunsRange(String from, String to) {
    return 'Do $from ao $to';
  }

  @override
  String selectionRunsOpenEnded(String from) {
    return 'Desde o $from, sen data de fin';
  }

  @override
  String selectionRunsStep(int day) {
    return 'Comeza no día $day do ciclo';
  }

  @override
  String get selectionRunsActive => 'En curso';

  @override
  String get selectionRunsFuture => 'Aínda non comezou';

  @override
  String get selectionRunsEnded => 'Rematada';

  @override
  String get selectionRunsEnd => 'Rematar aquí';

  @override
  String get selectionRunsEndHelp => 'Primeiro día sen a rotación';

  @override
  String selectionRunsEndDone(String date) {
    return 'A rotación remata o $date';
  }

  @override
  String get selectionRunsDelete => 'Eliminar';

  @override
  String selectionRunsDeleteTitle(String name) {
    return 'Queres eliminar $name?';
  }

  @override
  String get selectionRunsDeleteBody =>
      'Quítase do calendario enteiro. Os días que cambiaches a man e as notas quedan como están. Poderás desfacelo.';

  @override
  String get selectionRunsDeleted => 'Rotación eliminada';

  @override
  String get agendaTitle => 'Axenda';

  @override
  String get agendaOpenTooltip => 'Axenda de notas';

  @override
  String get agendaSearchHint => 'Buscar en notas e quendas';

  @override
  String get agendaSearchHintShort => 'Buscar';

  @override
  String get agendaModeNotes => 'Notas';

  @override
  String get agendaModeShifts => 'Quendas';

  @override
  String get agendaSearchScope =>
      'Busca en todas as túas notas e festivos propios, e nas quendas desde hai un ano ata dentro dun ano. Tamén entende datas: 15/10 ou 15 out.';

  @override
  String get agendaSearchClear => 'Borrar busca';

  @override
  String get agendaEmptyTitle => 'Sen notas próximas';

  @override
  String get agendaEmptyMessage =>
      'As notas e os festivos propios dos próximos días aparecerán aquí.';

  @override
  String get agendaNoResultsTitle => 'Non se atopou nada';

  @override
  String agendaNoResultsMessage(String query) {
    return 'Non hai notas nin quendas que coincidan con «$query».';
  }

  @override
  String agendaHoliday(String name) {
    return 'Festivo: $name';
  }

  @override
  String agendaTruncated(int count) {
    return 'Amósanse os primeiros $count resultados. Escribe algo máis para afinar.';
  }

  @override
  String agendaResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    return '$_temp0';
  }

  @override
  String agendaSemanticsNote(String note) {
    return 'nota: $note';
  }

  @override
  String get patternButton => 'Patrón';

  @override
  String get patternTitle => 'Aplicar patrón';

  @override
  String patternStepOf(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get patternStepChoose => 'Escolle un patrón';

  @override
  String get patternStepStart => 'Cando comezas?';

  @override
  String get patternStepEnd => 'Ata cando?';

  @override
  String get patternNext => 'Seguinte';

  @override
  String get patternBack => 'Atrás';

  @override
  String get patternApply => 'Aplicar';

  @override
  String get patternApplied => 'Patrón aplicado';

  @override
  String get patternApplyFailed => 'Non se puido aplicar o patrón';

  @override
  String patternFromDay(String date) {
    return 'Desde o $date';
  }

  @override
  String get patternGroupHealth => 'Sanidade';

  @override
  String get patternGroupPolice => 'Policía e Garda Civil';

  @override
  String get patternGroupFirefighters => 'Bombeiros';

  @override
  String get patternGroupIndustry => 'Industria';

  @override
  String get patternGroupSecurity => 'Seguridade';

  @override
  String get patternGroupOther => 'Outro';

  @override
  String get patternGroupMine => 'Os meus patróns';

  @override
  String patternGroupTypical(String shift) {
    return 'Comezan por: $shift';
  }

  @override
  String patternGroupIncluding(String shift) {
    return 'Inclúen: $shift';
  }

  @override
  String patternCycleDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get patternCreateOwn => 'Crear o meu';

  @override
  String get patternCreateOwnHint => 'Monta a túa secuencia día a día';

  @override
  String get patternBuilderBack => 'Escoller un patrón da lista';

  @override
  String get patternBuilderName => 'Nome do patrón';

  @override
  String get patternBuilderDefaultName => 'O meu patrón';

  @override
  String get patternBuilderSequence => 'A túa secuencia';

  @override
  String get patternBuilderEmpty =>
      'Toca as quendas de abaixo para ir engadindo días.';

  @override
  String get patternBuilderSameDay => 'Varias quendas nun día';

  @override
  String get patternBuilderSameDayHint =>
      'Activado: cada quenda que toques súmase ao último día da secuencia, en vez de crear un día novo.';

  @override
  String get patternBuilderRemoveLast => 'Quitar o último';

  @override
  String get patternBuilderClear => 'Baleirar a secuencia';

  @override
  String patternBuilderAdd(String name) {
    return 'Engadir $name';
  }

  @override
  String get patternStartLabel => 'Día de inicio';

  @override
  String patternSuggestedStart(String weekday) {
    return 'Este patrón adoita comezar un $weekday.';
  }

  @override
  String get patternWeekdayMonday => 'luns';

  @override
  String get patternWeekdayTuesday => 'martes';

  @override
  String get patternWeekdayWednesday => 'mércores';

  @override
  String get patternWeekdayThursday => 'xoves';

  @override
  String get patternWeekdayFriday => 'venres';

  @override
  String get patternWeekdaySaturday => 'sábado';

  @override
  String get patternWeekdaySunday => 'domingo';

  @override
  String get patternOffsetTitle => 'En que día do ciclo estás ese día?';

  @override
  String patternOffsetHelp(String date) {
    return 'Toca o día do patrón que che toca o $date.';
  }

  @override
  String patternOffsetThatDay(String shifts) {
    return 'Ese día tócache: $shifts';
  }

  @override
  String patternChipDay(int day, String shifts) {
    return 'Día $day: $shifts';
  }

  @override
  String get patternEndNever => 'Sen fin';

  @override
  String get patternEndNeverHint => 'Repítese ata que o cambies.';

  @override
  String get patternEndUntil => 'Ata unha data';

  @override
  String get patternEndUntilHint => 'Despois desa data volve o que tiñas.';

  @override
  String get patternUntilLabel => 'Último día';

  @override
  String get patternOverridesTitle => 'Días que xa cambiaches a man';

  @override
  String get patternOverridesKeep => 'Respectar os días que xa cambiei a man';

  @override
  String get patternOverridesKeepHint =>
      'Os teus cambios quedan; o patrón enche o resto.';

  @override
  String get patternOverridesReplace => 'Substituílos polo patrón';

  @override
  String get patternOverridesReplaceHint =>
      'Bórranse os teus cambios a man desas datas. As notas quedan.';

  @override
  String get patternPreviewTitle => 'Así quedará';

  @override
  String get patternPreviewNone => 'Escolle un patrón para ver como queda.';

  @override
  String patternPreviewPostNight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saínte automático: $count días despois dunha noite.',
      one: 'Saínte automático: 1 día despois dunha noite.',
    );
    return '$_temp0';
  }

  @override
  String get patternPickBanner => 'Toca o día en que comeza o patrón';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingNext => 'Seguinte';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String onboardingProgress(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get onboardingProfessionTitle => 'A que te dedicas?';

  @override
  String get onboardingProfessionHelp =>
      'Así deixámosche as quendas e as rotacións do teu traballo. Cámbiao cando queiras.';

  @override
  String get onboardingProfessionNursing => 'Enfermaría, TCAE e celadores';

  @override
  String get onboardingProfessionNursingHint =>
      'M 08–15, T 15–22, N 22–08 e saínte';

  @override
  String get onboardingProfessionMedicine => 'Medicina (gardas)';

  @override
  String get onboardingProfessionMedicineHint => 'Mañá, garda de 24 h e saínte';

  @override
  String get onboardingProfessionPolice => 'Policía e Garda Civil';

  @override
  String get onboardingProfessionPoliceHint => 'M 07–15, T 15–23 e N 23–07';

  @override
  String get onboardingProfessionFirefighters => 'Bombeiros';

  @override
  String get onboardingProfessionFirefightersHint =>
      'Garda de 24 h e descansos longos';

  @override
  String get onboardingProfessionIndustry => 'Industria';

  @override
  String get onboardingProfessionIndustryHint =>
      'Quendas rotativas: M 06–14, T 14–22 e N 22–06';

  @override
  String get onboardingProfessionSecurity => 'Seguridade privada';

  @override
  String get onboardingProfessionSecurityHint =>
      'Quendas de 12 h, de día e de noite';

  @override
  String get onboardingProfessionHospitality => 'Hostalaría e comercio';

  @override
  String get onboardingProfessionHospitalityHint => 'M 08–16 e T 16–00';

  @override
  String get onboardingProfessionOther => 'Outro';

  @override
  String get onboardingProfessionOtherHint => 'Comezas coas quendas de sempre';

  @override
  String get onboardingPlaceTitle => 'Onde traballas?';

  @override
  String get onboardingPlaceHelp =>
      'Para marcarche no calendario os festivos da túa comunidade e do teu concello.';

  @override
  String get onboardingRegionLabel => 'Comunidade';

  @override
  String get onboardingRegionPick => 'Escoller comunidade';

  @override
  String get onboardingRegionSheetTitle => 'A túa comunidade';

  @override
  String get onboardingMunicipalityLabel => 'Concello (opcional)';

  @override
  String get onboardingMunicipalityPick => 'Buscar concello';

  @override
  String get onboardingMunicipalityNeedsRegion => 'Escolle antes a comunidade';

  @override
  String get onboardingMunicipalitySheetTitle => 'O teu concello';

  @override
  String get onboardingMunicipalitySearch => 'Escribe o nome';

  @override
  String get onboardingMunicipalityNone => 'Ningún concello se chama así';

  @override
  String get onboardingMunicipalityClear => 'Quitar concello';

  @override
  String get onboardingLocalHolidaysMissing =>
      'Os festivos locais do teu concello podes engadilos ti en dous toques.';

  @override
  String get onboardingRotationTitle => 'Como é a túa rotación?';

  @override
  String get onboardingRotationHelp =>
      'Escolle a que máis se pareza. Logo dis cando comezas.';

  @override
  String get onboardingRotationTypical => 'O habitual no teu traballo';

  @override
  String get onboardingRotationOthers => 'Outras rotacións';

  @override
  String get onboardingRotationAll => 'Rotacións';

  @override
  String get onboardingByHand => 'Píntoo a man';

  @override
  String get onboardingByHandHint =>
      'Sen rotación: pintas ti os días no calendario.';

  @override
  String get onboardingStartTitle => 'Cando comezas?';

  @override
  String get onboardingStartHelp =>
      'Di desde que día conta e en que punto do ciclo estás ese día.';

  @override
  String get onboardingImportTitle => 'Vés doutra app?';

  @override
  String get onboardingImportBody =>
      'Se xa levabas as túas quendas en LRHSoft (Shifter), Supershift ou outra app, tráeas desde a súa copia, o calendario do móbil ou un ficheiro. Tamén podes facelo máis tarde, en Configuración.';

  @override
  String get onboardingReadyTitle => 'Listo';

  @override
  String get onboardingReadyBody =>
      'O teu calendario está preparado. Todo isto podes cambialo cando queiras en Configuración.';

  @override
  String onboardingReadyProfession(String name) {
    return 'Traballo: $name';
  }

  @override
  String onboardingReadyPlace(String place) {
    return 'Festivos: $place';
  }

  @override
  String onboardingReadyRotation(String name, String date) {
    return 'Rotación: $name, desde o $date';
  }

  @override
  String onboardingReadyOffset(int day, String shifts) {
    return 'Comezas no día $day do ciclo ($shifts)';
  }

  @override
  String get onboardingReadyByHand => 'Rotación: píntala ti a man';

  @override
  String get onboardingReadyNothing =>
      'Non escolliches nada, así que comezas co calendario en branco.';

  @override
  String get onboardingReadySaveFailed =>
      'Non se puido gardar todo. Revisa as túas quendas e festivos en Configuración.';

  @override
  String get onboardingOpenCalendar => 'Ver o meu calendario';

  @override
  String get onboardingTipTitle => 'Pinta o teu mes nun momento';

  @override
  String get onboardingTipBody =>
      'Toca Pintar, escolle unha quenda e arrastra polos días. Co botón Patrón repites unha rotación enteira dunha vez.';

  @override
  String get onboardingTipDismiss => 'Entendido';

  @override
  String get onboardingTipClose => 'Pechar o consello';

  @override
  String get paintScrollUp => 'Subir polo mes';

  @override
  String get paintScrollDown => 'Baixar polo mes';

  @override
  String get monthTipPaint => 'Escolle unha quenda e arrasta.';

  @override
  String get postNightAutoTitle => 'Saínte automático';

  @override
  String get postNightAutoHelp =>
      'Despois dunha noite, o día seguinte pasa a Saínte se estaba baleiro ou libre.';

  @override
  String get yearTitle => 'Vista anual';

  @override
  String get yearOpenTooltip => 'Ver o ano';

  @override
  String get yearPrevious => 'Ano anterior';

  @override
  String get yearNext => 'Ano seguinte';

  @override
  String get yearShare => 'Compartir como imaxe';

  @override
  String yearShareSubject(int year) {
    return 'As miñas quendas de $year';
  }

  @override
  String get yearShareFailed => 'Non se puido compartir a imaxe';

  @override
  String yearImageTitle(int year) {
    return 'As miñas quendas $year';
  }

  @override
  String get yearMonthEmpty => 'sen quendas';

  @override
  String get yearLegendTitle => 'Quendas do ano';

  @override
  String get yearLegendEmpty => 'Este ano non ten quendas.';

  @override
  String yearLegendDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get yearLegendHoliday => 'Festivo';

  @override
  String get summaryTitle => 'Resumo';

  @override
  String get summaryOpenTooltip => 'Resumo do mes';

  @override
  String get summaryModeMonth => 'Mes';

  @override
  String get summaryModeYear => 'Ano';

  @override
  String get summaryModeRange => 'Datas…';

  @override
  String get summaryRangeFrom => 'Desde';

  @override
  String get summaryRangeTo => 'Ata';

  @override
  String get summaryRangePrevious => 'Período anterior';

  @override
  String get summaryRangeNext => 'Período seguinte';

  @override
  String summaryRangeDays(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días en total',
      one: '1 día en total',
    );
    return '$_temp0. Podes escoller ata $max.';
  }

  @override
  String summaryRangeClamped(int max) {
    return 'O máximo son $max días: acurtamos a data final.';
  }

  @override
  String summaryRangePreviousName(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'os $days días anteriores',
      one: 'o día anterior',
    );
    return '$_temp0';
  }

  @override
  String get summaryRangeEmptyTitle => 'Sen quendas nestas datas';

  @override
  String get summaryRangeEmptyBody =>
      'Escolle outras datas ou pinta quendas no calendario.';

  @override
  String get summaryRangeNoteMidnight =>
      'As horas dunha quenda que cruza a medianoite cóntanse no día en que comeza, tamén se é o último día das datas.';

  @override
  String get summaryEmptyTitle => 'Sen quendas este mes';

  @override
  String get summaryEmptyBody =>
      'Pinta quendas no calendario e aquí verás as horas e a estimación.';

  @override
  String get summaryHoursWorked => 'Horas traballadas';

  @override
  String get summaryShiftsWorked => 'Quendas traballadas';

  @override
  String get summaryNightHours => 'Horas nocturnas';

  @override
  String get summaryRestDays => 'Días libres';

  @override
  String get summaryAbsences => 'Ausencias';

  @override
  String get summaryHolidayHours => 'Horas en festivo';

  @override
  String summaryHolidayDetail(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quendas en festivo',
      one: '1 quenda en festivo',
    );
    return '$_temp0';
  }

  @override
  String get summaryOvertime => 'Horas extra';

  @override
  String get summaryEarlyLeave => 'Saídas anticipadas';

  @override
  String summaryExtrasPay(String amount) {
    return '$amount na estimación';
  }

  @override
  String get summaryExtrasNoRate =>
      'Hai horas extra ou saídas en días sen quenda con prezo por hora: non están na estimación.';

  @override
  String get summaryNoteExtras =>
      'Horas extra e saídas anticipadas: as que anotas en cada día. As extra suman e as saídas restan das horas traballadas (un día non baixa de 0 h). Valóranse ao prezo por hora da primeira quenda con prezo dese día.';

  @override
  String summaryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String summaryShifts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quendas',
      one: '1 quenda',
    );
    return '$_temp0';
  }

  @override
  String summaryNightOf(String hours) {
    return '$hours nocturnas';
  }

  @override
  String get summaryNoTimes => 'sen horario';

  @override
  String get summaryNoRate => 'sen prezo';

  @override
  String get summaryGroupWork => 'Quendas de traballo';

  @override
  String get summaryGroupRest => 'Descansos';

  @override
  String get summaryEstimateTitle => 'Ingresos estimados';

  @override
  String get summaryFixedPluses => 'Complementos';

  @override
  String summaryFixedPlusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quendas',
      one: '1 quenda',
    );
    return '$_temp0';
  }

  @override
  String get summaryEstimateNote => 'Estimación, antes de impostos';

  @override
  String get summaryEstimateNone =>
      'Pon o prezo por hora ou o complemento por quenda en As miñas quendas para ver a estimación.';

  @override
  String summaryEstimateMissing(String types) {
    return 'Non inclúe o pago por hora de $types: sen prezo.';
  }

  @override
  String get summaryRateAction => 'Poñer prezos en As miñas quendas';

  @override
  String summaryDelta(String delta, String month) {
    return '$delta respecto a $month';
  }

  @override
  String summaryDeltaSame(String month) {
    return 'As mesmas horas ca en $month';
  }

  @override
  String summaryDeltaNone(String month) {
    return 'Sen quendas en $month para comparar';
  }

  @override
  String get summaryNotesTitle => 'Como se conta';

  @override
  String get summaryNoteMidnight =>
      'As horas dunha quenda que cruza a medianoite cóntanse no día e no mes en que comeza.';

  @override
  String get summaryNoteNight =>
      'Nocturnas: de 22:00 a 06:00, salvo que marques outra cousa na quenda.';

  @override
  String get summaryNoteDst =>
      'Son horas de reloxo: na noite do cambio de hora non se axusta a 7 ou 9 horas.';

  @override
  String get summaryNoteNoTimes =>
      'As quendas sen horario contan como quenda, pero non suman horas.';

  @override
  String get summaryNoteHoliday =>
      'Horas en festivo: as que caen nun día festivo da túa comunidade e concello, tamén se a quenda cruza a medianoite.';

  @override
  String get summaryYearEmpty => 'Este ano non ten quendas.';

  @override
  String get summaryYearHint => 'Toca un mes para ver o seu detalle.';

  @override
  String get summaryYearHeaderMonth => 'Mes';

  @override
  String get summaryYearHeaderShifts => 'Quendas';

  @override
  String get summaryYearHeaderHours => 'Horas';

  @override
  String get summaryYearHeaderNight => 'Noct.';

  @override
  String get summaryYearHeaderEstimate => 'Estimado';

  @override
  String get summaryYearTotal => 'Total';

  @override
  String summaryYearEstimated(String amount) {
    return '$amount estimado';
  }

  @override
  String get summaryYearMonthEmpty => 'Sen quendas';

  @override
  String get summaryYearRowTitle => 'Horas e estimación';

  @override
  String get summaryYearRowBody => 'Quendas, horas e euros de cada mes';

  @override
  String summaryYearMonthSemantics(String month, String shifts, String hours) {
    return '$month: $shifts, $hours';
  }

  @override
  String get shareMonthTooltip => 'Compartir o mes como imaxe';

  @override
  String shareMonthSubject(String month) {
    return 'As miñas quendas de $month';
  }

  @override
  String get shareMonthFailed => 'Non se puido compartir a imaxe';

  @override
  String get shareMonthLegendTitle => 'Quendas do mes';

  @override
  String get shareMonthLegendEmpty => 'Este mes non ten quendas.';

  @override
  String get saveFailed => 'Non se puido gardar o cambio';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsOpenTooltip => 'Abrir configuración';

  @override
  String get settingsSectionSchedule => 'O teu cadro de quendas';

  @override
  String get settingsShiftsTitle => 'As miñas quendas';

  @override
  String get settingsShiftsSubtitle => 'Cores, códigos e horas';

  @override
  String get settingsCalendarsTitle => 'Calendarios';

  @override
  String get settingsSectionAppearance => 'Aparencia';

  @override
  String get settingsThemeTitle => 'Tema';

  @override
  String get settingsThemeSystemLight => 'Sistema (claro)';

  @override
  String get settingsThemeSystemDark => 'Sistema (escuro)';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsWeekStartTitle => 'Primeiro día da semana';

  @override
  String get settingsWeekStartMonday => 'Luns';

  @override
  String get settingsWeekStartSunday => 'Domingo';

  @override
  String get settingsWeekNumbersTitle => 'Amosar o número de semana';

  @override
  String get settingsWeekNumbersSubtitle => 'Unha columna á esquerda do mes';

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
      'Non se puido gardar o axuste. Proba outra vez.';

  @override
  String get settingsSectionMore => 'Avisos e datos';

  @override
  String get settingsHolidaysTitle => 'Festivos';

  @override
  String get settingsAlarmsTitle => 'Alarmas';

  @override
  String get settingsBackupTitle => 'Copia de seguranza';

  @override
  String get settingsPrivacyTitle => 'Política de privacidade';

  @override
  String get settingsPrivacySubtitle => 'Ábrese no teu navegador';

  @override
  String get settingsPrivacyOpenFailed =>
      'Non se puido abrir a política de privacidade. Téntao de novo.';

  @override
  String get faqAlarmsQIos =>
      'Como configuro as alarmas e que é o permiso de notificacións?';

  @override
  String get faqAlarmsAIos =>
      'En Configuración › Alarmas activa «Avisar antes de cada quenda», escolle canto antes e, se queres, un aviso o día anterior a unha hora fixa. No detalle dun día podes quitar a súa alarma con «Sen alarma este día».\n\nSen o permiso de notificacións, Cuadrante non pode avisarte. Se non che sae a xanela para permitilas, actívaas na configuración do sistema.';

  @override
  String get faqWidgetAIos =>
      'En Configuración › Engadir widget ves os tamaños (pequeno: hoxe e mañá; mediano: os próximos 7 días; grande: o mes enteiro) e como colocalo. Mantén premida a pantalla de inicio, toca o + de arriba e busca Cuadrante.\n\nO widget garda os teus próximos días. O sistema decide cando o actualiza e pode atrasar o cambio de día. Se queda sen datos, abre Cuadrante para poñelo ao día.';

  @override
  String get settingsSectionHelp => 'Axuda';

  @override
  String get settingsHelpTitle => 'Axuda e contacto';

  @override
  String get settingsHelpSubtitle => 'Escríbenos se algo non vai ben';

  @override
  String get settingsHelpBody =>
      'Tes dúbidas ou algo non vai ben? Cóntanos que che pasa e que versión usas.';

  @override
  String get settingsHelpSubtitleSoon =>
      'Estamos preparando o correo de soporte';

  @override
  String get settingsHelpBodySoon =>
      'Aínda non temos correo de soporte. Mentres tanto, mira as preguntas frecuentes e, se algo non vai ben, ten á man a versión que usas.';

  @override
  String get settingsHelpNoEmail =>
      'O correo de soporte chegará coa versión da tenda.';

  @override
  String get settingsHelpCopyEmail => 'Copiar correo';

  @override
  String get settingsHelpCopyVersion => 'Copiar versión';

  @override
  String get settingsFaqTitle => 'Preguntas frecuentes';

  @override
  String get settingsFaqSubtitle => 'Pintar, rotacións, alarmas, widget e máis';

  @override
  String get faqIntro =>
      'Respostas rápidas sobre como funciona Cuadrante. Todo está neste dispositivo: non fai falta conta nin conexión.';

  @override
  String get faqNotFound => 'Non atopas o que buscas?';

  @override
  String get faqContact => 'Axuda e contacto';

  @override
  String get faqPaintQ => 'Como pinto o mes?';

  @override
  String get faqPaintA =>
      'Preme «Pintar» no calendario, escolle unha quenda abaixo e toca os días ou pasa o dedo por eles. Para baleirar un día usa «Borrar». Cada trazo pódese desfacer e refacer coas frechas da barra. Preme «Feito» cando remates.\n\nSe tocas un día sen estar pintando ábrese o seu detalle: aí cambias a quenda, engades unha nota ou volves ao patrón. Se mantés premido un día comezas a escoller varios á vez: podes poñerlles quenda, copialos, cortalos e pegalos, ou repetir unha semana.';

  @override
  String get faqPatternQ => 'Como aplico unha rotación e que é o desfase?';

  @override
  String get faqPatternA =>
      'No modo pintar preme o botón «Patrón» e segue os pasos: escolle a túa rotación (ou crea a túa), o día en que comezas e ata cando se repite.\n\nO desfase é o punto do ciclo no que estás o día de inicio. Se ese día che toca a noite, no paso «En que día do ciclo estás ese día?» tocas a noite e o resto axústase só. Os días que xa cambiaches a man respéctanse ou substitúense, como prefiras. Para rematar ou quitar unha rotación vai a Configuración › As miñas rotacións.';

  @override
  String get faqDoubleQ => 'Como dobro unha quenda?';

  @override
  String get faqDoubleA =>
      'Dobrar é facer dúas quendas o mesmo día. Toca o día e, no seu detalle, usa «Engadir unha segunda quenda». Se estás pintando, activa «Dobrar» e toca os días. Con varios días escollidos, «Dobrar con…» engade a quenda a todos.\n\nUn día pode levar as quendas que necesites e cada unha suma as súas horas por separado.';

  @override
  String get faqPostNightQ => 'Que é o saínte automático?';

  @override
  String get faqPostNightA =>
      'É o descanso do día seguinte a unha noite. Se o activas en Configuración › Saínte automático, ao pintar ou aplicar unha noite o día seguinte pasa a Saínte cando estaba baleiro ou libre. Os días que xa tiñan outra quenda non se tocan. Vén desactivado.';

  @override
  String get faqNotesQ => 'Como uso as notas e a axenda?';

  @override
  String get faqNotesA =>
      'Toca un día e escribe no campo da nota; os días con nota márcanse no calendario. Abre a axenda desde arriba do calendario: «Notas» reúne as notas e os festivos propios; «Quendas» amosa as quendas próximas.\n\nBusca por texto, sen importar maiúsculas nin tiles, ou por data: por exemplo, 15/10 ou 15 out. A busca inclúe todas as notas e os festivos propios, e as quendas desde hai un ano ata dentro dun ano.';

  @override
  String get faqAlarmsQ =>
      'Como configuro as alarmas e que é o permiso de alarmas exactas?';

  @override
  String get faqAlarmsA =>
      'En Configuración › Alarmas activa «Avisar antes de cada quenda», escolle canto antes e, se queres, un aviso o día anterior a unha hora fixa. No detalle dun día podes quitar a súa alarma con «Sen alarma este día».\n\nEn Android fan falta as notificacións e o permiso «Alarmas e recordatorios» da configuración do sistema: sen el, Android pode atrasar o aviso uns minutos. A pantalla de alarmas diche que falta e lévate á configuración. Se o teu móbil aforra batería de forma agresiva, deixa Cuadrante sen restricións para que non pare os avisos.';

  @override
  String get faqHolidaysQ => 'Como engado un festivo local?';

  @override
  String get faqHolidaysA =>
      'En Configuración › Festivos escolle a túa comunidade e o teu concello e verás os festivos que che tocan. Se falta o da túa vila, toca ese día no calendario e activa «Festivo propio»: pónslle nome e desde ese momento conta como festivo.\n\nTamén podes traer festivos do calendario do móbil desde Configuración › Festivos. Escolle os calendarios e as datas e revisa a vista previa: só se len eventos de día completo, omítense os festivos que xa tes e podes desfacer a acción. Non se cambian os eventos do calendario.';

  @override
  String get faqWidgetQ => 'Como engado o widget e por que cambia só?';

  @override
  String get faqWidgetA =>
      'En Configuración › Engadir widget ves os tamaños (pequeno: hoxe e mañá; mediano: os próximos 7 días; grande: o mes enteiro) e como colocalo. En Android, mantén premida unha zona baleira da pantalla de inicio, escolle Widgets e busca Cuadrante.\n\nO widget sempre amosa o día de hoxe: cambia de día á medianoite aínda que non abras a app, porque leva gardados os teus próximos días. Se pasa moito tempo sen abrir Cuadrante, queda sen datos e pídeche abrir a app para poñerse ao día.';

  @override
  String get faqBackupQ => 'Como fago unha copia e cambio de dispositivo?';

  @override
  String get faqBackupA =>
      'Configuración › Copia de seguranza garda copias automáticas neste dispositivo despois de cada cambio, pero pérdense se o perdes ou desinstalas a app. Exporta un ficheiro con «Exportar ficheiro» e gárdao en Drive ou envíao a ti mesmo por WhatsApp ou correo.\n\nPara cambiar de dispositivo: exporta o ficheiro, instala Cuadrante no novo, abre o ficheiro coa app (ou usa «Importar ficheiro» na copia de seguranza) e revisa a vista previa antes de restaurar. «Probar restauración» comproba que a túa última copia se pode recuperar enteira.';

  @override
  String get faqImportQ =>
      'Podo importar ou exportar as miñas quendas ao calendario?';

  @override
  String get faqImportA =>
      'Si. En Configuración › Importar quendas podes traer unha copia «.Shifter» de LRHSoft, quendas do calendario do móbil, un ficheiro .ics ou un CSV. En LRHSoft, crea unha copia en Menú › Copia de seguranza › Copia local e escolle o ficheiro de Documents › ShifterBackups. Revisa as datas, os tipos de quenda e a vista previa antes de importar.\n\n«Exportar ao calendario do móbil» copia as túas quendas unha vez a un calendario do teléfono. Se exportas outra vez non se duplican: só se tocan os eventos que creou Cuadrante.';

  @override
  String get faqCalendarsQ => 'Podo levar varios calendarios e comparalos?';

  @override
  String get faqCalendarsA =>
      'Si. En Configuración › Calendarios creas un para a túa parella, un segundo traballo ou un fillo: cada un ten as súas rotacións e os seus días, e os tipos de quenda son os mesmos. Con dous ou máis, o nome do calendario sobre o mes déixache cambiar dun a outro. O widget e as alarmas seguen o calendario marcado como «Widget e alarmas».\n\nPara ver cando coincidides libres, preme «Comparar calendarios» nesa mesma folla: escolles dous e ves as súas quendas xuntas e os días libres en común do mes.';

  @override
  String get faqSummaryQ => 'Como se calculan as horas e os euros?';

  @override
  String get faqSummaryA =>
      'A icona de resumo do calendario amosa as quendas, as horas, as nocturnas e as de festivo do mes, dun ano enteiro ou das datas que escollas en «Datas…» (ata 366 días). Unha quenda conta no día en que comeza, aínda que cruce a medianoite.\n\nPara ver euros, pon o prezo por hora e, se o tes, o complemento fixo por tipo de quenda en Configuración › As miñas quendas. A estimación inclúe eses complementos fixos, antes de impostos. Non inclúe complementos por hora nocturna ou festiva nin retencións.\n\nO «Plus por quenda» súmase unha vez por cada quenda traballada dese tipo, tamén se é partida; non depende das horas. Os descansos e as ausencias non o suman.';

  @override
  String get settingsVersionCopied => 'Versión copiada';

  @override
  String get settingsEmailCopied => 'Correo copiado';

  @override
  String get settingsAboutTitle => 'Acerca de';

  @override
  String settingsAboutVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get settingsAboutVersionDev => 'Versión de desenvolvemento';

  @override
  String get settingsAboutTagline =>
      'Cuadrante funciona sen conexión e sen conta: as túas quendas quedan no teu móbil.';

  @override
  String get settingsAboutLicenses => 'Licenzas de código aberto';

  @override
  String calendarWeekNumberSemantics(int number) {
    return 'Semana $number';
  }

  @override
  String get importSectionTitle => 'Importar e exportar';

  @override
  String get importRowTitle => 'Importar quendas';

  @override
  String get importRowSubtitle =>
      'Copia de LRHSoft, calendario do móbil, .ics ou CSV';

  @override
  String get calExportRowTitle => 'Exportar quendas';

  @override
  String get calExportRowSubtitle => 'Ao calendario do móbil, sen duplicados';

  @override
  String get importTitle => 'Importar quendas';

  @override
  String importStepOf(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get importNext => 'Seguinte';

  @override
  String get importReading => 'Lendo…';

  @override
  String get importSourceTitle => 'De onde veñen as túas quendas?';

  @override
  String get importSourceHelp =>
      'Cuadrante le os eventos aquí mesmo, no teu móbil, e non os envía a ningún sitio. Ti decides que se importa.';

  @override
  String get importSourceDevice => 'Calendario do móbil';

  @override
  String get importSourceDeviceHelp =>
      'Google, iCloud, Outlook… o que teñas na app de calendario.';

  @override
  String get importSourceIcs => 'Ficheiro .ics';

  @override
  String get importSourceIcsHelp =>
      'Un calendario exportado, cunha quenda por evento.';

  @override
  String get importSourceCsv => 'Ficheiro CSV';

  @override
  String get importSourceCsvHelp =>
      'Unha folla cunha data e unha quenda en cada fila.';

  @override
  String get importSourceLrhsoft => 'Copia de LRHSoft (Calendario de Turnos)';

  @override
  String get importSourceLrhsoftHelp =>
      'O ficheiro .Shifter da túa copia local';

  @override
  String get importFileLrhsoft => 'Copia de LRHSoft';

  @override
  String get importHowToTitle => 'Vés de LRHSoft ou Supershift?';

  @override
  String get importHowToBody =>
      'LRHSoft ou Shifter: na app, Menú › Copia de seguranza › Copia local. Despois escolle aquí ese ficheiro .Shifter: está na memoria do móbil, en Documents › ShifterBackups.\nSupershift: exporta as túas quendas ao calendario do móbil e escolle «Calendario do móbil».';

  @override
  String get calExportPermissionTitle => 'Falta o permiso do calendario';

  @override
  String get calExportPermissionReadBody =>
      'Para importar, Cuadrante necesita ler os eventos dos teus calendarios. Só o fai agora, mentres importas, e non garda nada fóra do móbil.';

  @override
  String get calExportPermissionWriteBody =>
      'Para engadir as túas quendas, Cuadrante necesita acceso aos teus calendarios. Só engade ou cambia os seus propios eventos, e só cando ti exportas. Se o calendario que escollas se sincroniza cunha conta (Google, iCloud...), esa conta tamén recibirá as quendas.';

  @override
  String get calExportPermissionAgainBody =>
      'Non deches o permiso. Sen el non podemos usar os teus calendarios, pero podes permitilo agora. Se o rexeitas outra vez, terás que activalo nos axustes do sistema.';

  @override
  String get calExportPermissionAllow => 'Permitir acceso';

  @override
  String get calExportPermissionDeniedTitle =>
      'O acceso ao calendario está desactivado';

  @override
  String get calExportPermissionDeniedBody =>
      'Actívao na configuración do sistema (Permisos › Calendario) e volve aquí.';

  @override
  String get calExportPermissionSettings => 'Abrir configuración';

  @override
  String get calExportPermissionRecheck => 'Comprobar de novo';

  @override
  String get calExportPermissionRestrictedTitle =>
      'Este móbil non deixa usar o calendario';

  @override
  String get calExportPermissionRestrictedBody =>
      'Pode ser un control parental ou un perfil de traballo. Se importas, proba cun ficheiro .ics.';

  @override
  String get calExportPermissionWriteOnlyBody =>
      'O sistema só deu permiso para engadir eventos. Cuadrante necesita acceso completo para ler os calendarios ou para substituír os eventos dunha exportación anterior.';

  @override
  String get importCalendarsTitle => 'Escolle os calendarios';

  @override
  String get importCalendarsHelp =>
      'Marca de onde veñen as túas quendas. Os demais non se tocan.';

  @override
  String get importCalendarsEmpty => 'Non hai calendarios neste móbil.';

  @override
  String get importCalendarsNoAccount => 'Sen conta';

  @override
  String get importCalendarsReadOnly => 'Só lectura';

  @override
  String importCalendarSemantics(String name, String account) {
    return '$name, $account';
  }

  @override
  String get importRangeTitle => 'De que datas?';

  @override
  String get importRangeHelp => 'Só se miran os eventos destes días.';

  @override
  String get importRangeFrom => 'Desde';

  @override
  String get importRangeTo => 'Ata';

  @override
  String get importRangeDefault => 'Últimos 12 meses e próximos 6';

  @override
  String get importRangeInvalid =>
      'A data final non pode ser anterior á inicial.';

  @override
  String get importRangeClamped =>
      'O máximo son 5 anos: recortouse o principio.';

  @override
  String importRangeFile(String name) {
    return 'Ficheiro: $name';
  }

  @override
  String importRangeFileEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'O ficheiro trae $count eventos.',
      one: 'O ficheiro trae 1 evento.',
    );
    return '$_temp0';
  }

  @override
  String importRangeFileSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos non teñen unha data válida e non se lerán.',
      one: '1 evento non ten unha data válida e non se lerá.',
    );
    return '$_temp0';
  }

  @override
  String importRangeFileRules(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count eventos teñen unha repetición que non entendemos e contan unha soa vez.',
      one: '1 evento ten unha repetición que non entendemos e conta unha soa vez.',
    );
    return '$_temp0';
  }

  @override
  String get importColumnsTitle => 'Que é cada columna?';

  @override
  String get importColumnsHelp =>
      'Mira as primeiras filas e confirma cal é a data e cal a quenda.';

  @override
  String get importColumnsHeader => 'A primeira fila son os títulos';

  @override
  String get importColumnDate => 'Data';

  @override
  String get importColumnTitle => 'Quenda ou código';

  @override
  String get importColumnStart => 'Hora de inicio (opcional)';

  @override
  String get importColumnEnd => 'Hora de fin (opcional)';

  @override
  String get importColumnNone => 'Ningunha';

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
      'Despraza cara aos lados para ver todas as columnas.';

  @override
  String get importColumnsPreview => 'Primeiras filas';

  @override
  String get importMappingTitle => 'A que quenda corresponde cada título?';

  @override
  String get importMappingHelp =>
      'Agrupamos os eventos por título. Escolle unha das túas quendas, crea unha nova ou ignóraos.';

  @override
  String importMappingSummary(int days, int groups) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    String _temp1 = intl.Intl.pluralLogic(
      groups,
      locale: localeName,
      other: '$groups títulos',
      one: '1 título',
    );
    return '$_temp0 en $_temp1';
  }

  @override
  String importMappingTruncated(String limit) {
    return 'Hai máis de $limit eventos: só se leron os primeiros. Acurta as datas para ver o resto.';
  }

  @override
  String importMappingSkippedRows(int count, int line) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Saltáronse $count filas por non ter unha data ou unha quenda válidas (por exemplo, a liña $line).',
      one:
          'Saltouse 1 fila por non ter unha data ou unha quenda válidas (por exemplo, a liña $line).',
    );
    return '$_temp0';
  }

  @override
  String get importMappingNothing =>
      'Escolle polo menos un título para importar.';

  @override
  String importGroupDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get importGroupAllDay => 'Todo o día';

  @override
  String importGroupExamples(String dates) {
    return 'p. ex. $dates';
  }

  @override
  String get importGroupUntitled => 'Sen título';

  @override
  String get importMapIgnore => 'Ignorar';

  @override
  String get importMapCreate => 'Crear tipo novo';

  @override
  String get importMapChoose => 'Escoller quenda';

  @override
  String get importMapSuggested => 'Suxerido';

  @override
  String importMapNew(String name) {
    return 'Novo: $name';
  }

  @override
  String importMapPickTitle(String title) {
    return 'Que quenda é «$title»?';
  }

  @override
  String importMapSemantics(String title, String choice) {
    return '$title: $choice';
  }

  @override
  String get importNewTypeTitle => 'Tipo de quenda novo';

  @override
  String get importNewTypeUse => 'Usar este tipo';

  @override
  String get importPreviewTitle => 'Así quedará';

  @override
  String get importPreviewHelp =>
      'Revisa os meses. Non se garda nada ata que premas Importar.';

  @override
  String importPreviewTarget(String name) {
    return 'Impórtase en «$name».';
  }

  @override
  String importPreviewDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Escribiranse $count días.',
      one: 'Escribirase 1 día.',
    );
    return '$_temp0';
  }

  @override
  String importPreviewUnchanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días xa estaban igual.',
      one: '1 día xa estaba igual.',
    );
    return '$_temp0';
  }

  @override
  String importPreviewNewTypes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Crearanse $count tipos de quenda novos.',
      one: 'Crearase 1 tipo de quenda novo.',
    );
    return '$_temp0';
  }

  @override
  String get importPreviewEmpty => 'Con estas eleccións non cambia ningún día.';

  @override
  String importPreviewMoreMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'E $count meses máis sen amosar.',
      one: 'E 1 mes máis sen amosar.',
    );
    return '$_temp0';
  }

  @override
  String importConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días xa teñen quenda',
      one: '1 día xa ten quenda',
    );
    return '$_temp0';
  }

  @override
  String get importConflictsHelp => 'Que facemos con eles?';

  @override
  String get importConflictReplace => 'Substituír';

  @override
  String get importConflictKeep => 'Manter o meu';

  @override
  String importConflictsExamples(String dates) {
    return 'Por exemplo: $dates';
  }

  @override
  String importApply(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importar $count días',
      one: 'Importar 1 día',
    );
    return '$_temp0';
  }

  @override
  String importApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importáronse $count días.',
      one: 'Importouse 1 día.',
    );
    return '$_temp0';
  }

  @override
  String importAppliedWithTypes(int days, int types) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Importáronse $days días',
      one: 'Importouse 1 día',
    );
    String _temp1 = intl.Intl.pluralLogic(
      types,
      locale: localeName,
      other: '$types tipos de quenda novos',
      one: '1 tipo de quenda novo',
    );
    return '$_temp0 e $_temp1.';
  }

  @override
  String get importUndoDone => 'Desfízose a importación.';

  @override
  String importUndoKeptTypes(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan os tipos «$names»: algo os usa.',
      one: 'Queda o tipo «$names»: algo o usa.',
    );
    return '$_temp0';
  }

  @override
  String get importApplyFailed => 'Non se puido importar. Proba outra vez.';

  @override
  String get importProblemPermissionDenied =>
      'Sen o permiso non podemos ler os teus calendarios.';

  @override
  String get importProblemPermissionRestricted =>
      'Este móbil non deixa a Cuadrante usar o calendario. Proba cun ficheiro.';

  @override
  String get importProblemCalendarUnavailable =>
      'Este móbil non ten calendarios dispoñibles.';

  @override
  String get importProblemReadFailed =>
      'Non se puideron ler os eventos. Proba outra vez.';

  @override
  String get importProblemFileTooLarge =>
      'O ficheiro pesa máis de 5 MB. Ao exportalo, escolle menos datas.';

  @override
  String get importProblemFileUnreadable =>
      'Non puidemos abrir ese ficheiro. Aceptamos .csv, .ics e a copia .Shifter de LRHSoft.';

  @override
  String get importProblemNotCalendar =>
      'Ese ficheiro non parece un calendario .ics.';

  @override
  String get importProblemNotCsv =>
      'Non atopamos unha columna de datas nese CSV.';

  @override
  String get importProblemNoEvents => 'Non hai eventos nesas datas.';

  @override
  String get importProblemTooComplex =>
      'Ese ficheiro é demasiado grande ou complicado e tarda demasiado. Ao exportalo, escolle menos datas.';

  @override
  String get importProblemUnknown =>
      'Algo non foi ben ao ler o ficheiro. Proba con outro.';

  @override
  String get importProblemNotLrhsoft =>
      'Ese ficheiro non parece unha copia de LRHSoft (.Shifter). Proba a crear outra copia local.';

  @override
  String importRangeLrhsoftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A copia trae $count días.',
      one: 'A copia trae 1 día.',
    );
    return '$_temp0';
  }

  @override
  String importMappingInvalidRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ignoráronse $count filas non válidas.',
      one: 'Ignorouse 1 fila non válida.',
    );
    return '$_temp0';
  }

  @override
  String get importLrhsoftNotImported =>
      'Non se traen as alarmas, os debuxos, as fotos nin as horas extra.';

  @override
  String importNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String importApplyNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importar $count notas',
      one: 'Importar 1 nota',
    );
    return '$_temp0';
  }

  @override
  String importAppliedNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importáronse $count notas.',
      one: 'Importouse 1 nota.',
    );
    return '$_temp0';
  }

  @override
  String importPreviewNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Engadiranse $count notas.',
      one: 'Engadirase 1 nota.',
    );
    return '$_temp0';
  }

  @override
  String get calExportTitle => 'Exportar quendas';

  @override
  String get calExportHelp =>
      'Engade as túas quendas como eventos a un calendario do móbil, unha soa vez. Se o repites, Cuadrante substitúe os seus eventos anteriores nesas datas en vez de duplicalos.';

  @override
  String calExportSource(String name) {
    return 'Expórtanse as quendas de «$name».';
  }

  @override
  String get calExportCalendarLabel => 'Calendario';

  @override
  String get calExportNewCalendar => 'Crear o calendario «Cuadrante»';

  @override
  String get calExportNewCalendarHelp =>
      'Así podes ocultalo ou borralo enteiro cando queiras.';

  @override
  String get calExportRangeLabel => 'Datas';

  @override
  String get calExportFrom => 'Desde';

  @override
  String get calExportTo => 'Ata';

  @override
  String get calExportIncludeRest => 'Incluír os días libres';

  @override
  String get calExportIncludeRestHelp =>
      'Libre e Saínte tamén se engaden, como eventos de todo o día.';

  @override
  String get calExportIncludeAbsences => 'Incluír ausencias';

  @override
  String get calExportIncludeAbsencesHelp =>
      'Vacacións, baixas e outras ausencias. Engadiríanse a ese calendario e á conta coa que se sincronice.';

  @override
  String calExportSynced(String account) {
    return 'Este calendario sincronízase con $account: as túas quendas veranse alí.';
  }

  @override
  String get calExportSyncedUnnamed =>
      'Este calendario sincronízase cunha conta: as túas quendas veranse alí.';

  @override
  String calExportPlanAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Engadiranse $count eventos.',
      one: 'Engadirase 1 evento.',
    );
    return '$_temp0';
  }

  @override
  String calExportPlanReplace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Substituiranse $count eventos dunha exportación anterior.',
      one: 'Substituirase 1 evento dunha exportación anterior.',
    );
    return '$_temp0';
  }

  @override
  String calExportPlanRemove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quitaranse $count eventos dunha exportación anterior.',
      one: 'Quitarase 1 evento dunha exportación anterior.',
    );
    return '$_temp0';
  }

  @override
  String calExportPlanSame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos xa están ao día.',
      one: '1 evento xa está ao día.',
    );
    return '$_temp0';
  }

  @override
  String get calExportPlanNothing =>
      'Todo está ao día: non hai nada que cambiar.';

  @override
  String get calExportPlanNone => 'Non hai quendas nesas datas.';

  @override
  String get calExportButton => 'Exportar';

  @override
  String calExportRunning(int done, int total) {
    return 'Exportando… $done de $total';
  }

  @override
  String get calExportDoneTitle => 'Exportación feita';

  @override
  String get calExportDoneCalendar => 'Creouse o calendario «Cuadrante».';

  @override
  String calExportDoneCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos engadidos',
      one: '1 evento engadido',
    );
    return '$_temp0';
  }

  @override
  String calExportDoneReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos anteriores substituídos',
      one: '1 evento anterior substituído',
    );
    return '$_temp0';
  }

  @override
  String calExportDoneRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos quitados',
      one: '1 evento quitado',
    );
    return '$_temp0';
  }

  @override
  String calExportDoneSame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos xa estaban ao día',
      one: '1 evento xa estaba ao día',
    );
    return '$_temp0';
  }

  @override
  String calExportDoneFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Non se puideron escribir $count eventos. Volve exportar para completalos.',
      one: 'Non se puido escribir 1 evento. Volve exportar para completalo.',
    );
    return '$_temp0';
  }

  @override
  String get calExportProblemPermission =>
      'Sen o permiso non podemos escribir no teu calendario.';

  @override
  String get calExportProblemUnavailable =>
      'Este móbil non ten calendarios dispoñibles.';

  @override
  String get calExportProblemFailed =>
      'Non se puido exportar. Proba outra vez.';

  @override
  String get calExportRangeClamped => 'O máximo é un ano: recortouse o final.';

  @override
  String get onboardingImportButton => 'Importar agora';

  @override
  String get onboardingImportLrhsoftButton => 'Importar a copia de LRHSoft';

  @override
  String get backupUiRowSubtitle => 'Automática, exportar e importar';

  @override
  String get backupUiStatusNoneTitle => 'Aínda non hai ningunha copia';

  @override
  String get backupUiStatusNoneBody =>
      'Fai unha agora: tarda un segundo. Mentres non a teñas, se perdes o dispositivo ou desinstalas a app pérdese o teu cadro de quendas.';

  @override
  String get backupUiStatusLast => 'Última copia';

  @override
  String get backupUiStatusWhere => 'Neste dispositivo';

  @override
  String get backupUiStatusRunning => 'Gardando a copia…';

  @override
  String get backupUiStatusPending =>
      'Hai cambios novos: a copia farase nuns segundos.';

  @override
  String backupUiStatusPendingAt(String time) {
    return 'Hai cambios novos: a próxima copia farase arredor das $time. Se non queres esperar, toca «Facer copia agora».';
  }

  @override
  String get backupUiStatusPendingLater =>
      'Hai cambios novos: a próxima copia farase nuns minutos. Se non queres esperar, toca «Facer copia agora».';

  @override
  String get backupUiStatusFailedTitle => 'A última copia automática fallou';

  @override
  String backupUiStatusFailedWithGood(String when, String good) {
    return 'Tentámolo $when e non se puido gardar. A túa última copia boa é de $good.';
  }

  @override
  String backupUiStatusFailedNoGood(String when) {
    return 'Tentámolo $when e non se puido gardar. Aínda non tes ningunha copia boa.';
  }

  @override
  String get backupUiFailDiskFull => 'O dispositivo non ten espazo libre.';

  @override
  String get backupUiFailGeneric =>
      'Non se puido escribir o ficheiro da copia.';

  @override
  String get backupUiRetry => 'Tentar de novo';

  @override
  String get backupUiSystemOn => 'Copia do sistema de Android: activada';

  @override
  String get backupUiSystemOff =>
      'Copia do sistema de Android: desactivada. Actívaa na configuración de Android para ter outra copia.';

  @override
  String get backupUiSystemUnknown =>
      'Copia do sistema de Android: non podemos comprobala desde a app. Mira na configuración de Android que estea activada.';

  @override
  String get backupUiWarning =>
      'Estas copias gárdanse neste dispositivo. Se desinstalas a app sen outra copia, pérdese. Exporta un ficheiro e gárdao en Drive ou envíao por WhatsApp ou correo.';

  @override
  String get backupUiBackupNow => 'Facer copia agora';

  @override
  String get backupUiBackupDone => 'Copia feita';

  @override
  String get backupUiBackupFailed =>
      'Non se puido facer a copia. Os teus datos seguen como estaban.';

  @override
  String get backupUiAutoTitle => 'Copias automáticas';

  @override
  String get backupUiAutoOn =>
      'Despois de cambiar algo, sen que o notes. Gardamos as 7 últimas e unha por día durante 30 días.';

  @override
  String get backupUiAutoOff => 'Desactivadas: só se copia cando ti o pides.';

  @override
  String get backupUiSectionFile => 'Ficheiro';

  @override
  String get backupUiSectionCheck => 'Comprobar';

  @override
  String get backupUiSectionCopies => 'Copias neste dispositivo';

  @override
  String get backupUiExport => 'Exportar ficheiro';

  @override
  String get backupUiExportSubtitle =>
      'Para gardalo en Drive ou mandalo por WhatsApp ou correo';

  @override
  String get backupUiExportFailed => 'Non se puido exportar o ficheiro.';

  @override
  String get backupUiSave => 'Gardar no dispositivo';

  @override
  String get backupUiSaveSubtitle =>
      'Escolle un cartafol, por exemplo Descargas';

  @override
  String get backupUiSaveDone => 'Ficheiro gardado';

  @override
  String get backupUiSaveFailed =>
      'Non se puido gardar o ficheiro. Proba con outro cartafol ou usa «Exportar ficheiro».';

  @override
  String get backupUiImport => 'Importar ficheiro';

  @override
  String get backupUiImportSubtitle => 'Recupera un ficheiro de Cuadrante';

  @override
  String get backupUiVerify => 'Probar restauración';

  @override
  String get backupUiVerifySubtitle =>
      'Comproba que a túa última copia se pode recuperar enteira';

  @override
  String get backupUiVerifyRunning => 'Comprobando a copia…';

  @override
  String get backupUiVerifyNone =>
      'Aínda non hai ningunha copia que probar. Fai unha primeiro.';

  @override
  String backupUiVerifyOk(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'A copia está completa: $days días comprobados',
      one: 'A copia está completa: 1 día comprobado',
    );
    return '$_temp0';
  }

  @override
  String get backupUiVerifySame => 'É idéntica ao que tes agora.';

  @override
  String backupUiVerifyOlder(String day) {
    return 'É anterior ao que tes agora (o primeiro día que cambia é $day). É normal se fixeches cambios despois.';
  }

  @override
  String get backupUiVerifyOlderNoDay =>
      'É anterior ao que tes agora. É normal se fixeches cambios despois.';

  @override
  String backupUiVerifyMismatch(String day) {
    return 'A copia non se reconstrúe igual. Primeiro día distinto: $day. Fai unha copia nova e avísanos.';
  }

  @override
  String get backupUiVerifyMismatchNoDay =>
      'A copia non se reconstrúe igual: os datos gardados non coinciden. Fai unha copia nova e avísanos.';

  @override
  String backupUiVerifyError(String reason) {
    return 'Non se puido probar a copia. $reason';
  }

  @override
  String get backupUiCopiesEmpty => 'Aquí aparecerán as túas copias.';

  @override
  String get backupUiCopyLocal => 'Copia do dispositivo';

  @override
  String get backupUiCopySafety => 'Antes de restaurar';

  @override
  String backupUiCopyMeta(String kind, String size) {
    return '$kind · $size';
  }

  @override
  String backupUiCopyMetaVersion(String kind, String version, String size) {
    return '$kind · $version · $size';
  }

  @override
  String get backupUiCopyRestore => 'Restaurar esta';

  @override
  String backupUiCopyRestoreLabel(String when) {
    return 'Restaurar a copia do $when';
  }

  @override
  String backupUiWhenToday(String time) {
    return 'hoxe ás $time';
  }

  @override
  String backupUiWhenYesterday(String time) {
    return 'onte ás $time';
  }

  @override
  String backupUiWhenDate(String date, String time) {
    return 'o $date ás $time';
  }

  @override
  String get backupUiPreviewTitle => 'Restaurar copia';

  @override
  String get backupUiPreviewReading => 'Lendo o ficheiro…';

  @override
  String get backupUiOriginFile => 'Ficheiro que escolliches';

  @override
  String get backupUiOriginShared => 'Ficheiro recibido doutra app';

  @override
  String get backupUiOriginLocal => 'Copia deste dispositivo';

  @override
  String get backupUiOriginSafety => 'Copia de xusto antes de restaurar';

  @override
  String get backupUiOriginCloud => 'Copia en iCloud';

  @override
  String backupUiPreviewSaved(String when) {
    return 'Gardada $when';
  }

  @override
  String backupUiPreviewSender(String sender) {
    return 'Enviado desde $sender';
  }

  @override
  String get backupUiPreviewSenderHint =>
      'Indícao o dispositivo. Se non esperabas este ficheiro, cancela.';

  @override
  String get backupUiPreviewTurnsOffTitle =>
      'Esta copia apaga axustes que tes acendidos';

  @override
  String get backupUiPreviewTurnsOffAuto => 'Desactiva as copias automáticas.';

  @override
  String get backupUiPreviewTurnsOffAlarms => 'Desactiva as alarmas de quenda.';

  @override
  String get backupUiPreviewContains => 'Que trae';

  @override
  String backupUiPreviewNow(String value) {
    return 'Agora: $value';
  }

  @override
  String get backupUiPreviewCalendars => 'Calendarios';

  @override
  String backupUiPreviewArchived(String name) {
    return '$name (arquivado)';
  }

  @override
  String get backupUiPreviewDays => 'Días con quenda ou nota postos a man';

  @override
  String get backupUiPreviewRuns => 'Rotacións';

  @override
  String get backupUiPreviewTypes => 'Tipos de quenda';

  @override
  String get backupUiPreviewRange => 'Datas';

  @override
  String backupUiPreviewRangeValue(String from, String to) {
    return 'Do $from ao $to';
  }

  @override
  String backupUiPreviewRangeOpen(String from, String to) {
    return 'Do $from ao $to, e unha rotación segue despois';
  }

  @override
  String get backupUiPreviewRangeNone => 'Sen datas';

  @override
  String get backupUiPreviewReplace =>
      'Isto substitúe o que tes agora; antes gardamos unha copia.';

  @override
  String get backupUiPreviewConfirm => 'Substituír o que teño';

  @override
  String get backupUiPreviewCancel => 'Cancelar';

  @override
  String get backupUiRestoring => 'Restaurando o teu cadro de quendas…';

  @override
  String get backupUiRestoringHint => 'Non peches a app.';

  @override
  String get backupUiDoneTitle =>
      'Listo, o teu cadro de quendas está restaurado';

  @override
  String get backupUiDoneBody =>
      'Antes de cambiar nada gardamos o que tiñas. Se non era o que esperabas, podes volver atrás.';

  @override
  String get backupUiDoneView => 'Ver o meu calendario';

  @override
  String get backupUiDoneUndo => 'Volver a como estaba';

  @override
  String get backupUiErrorNotOurs =>
      'Este ficheiro non é unha copia de Cuadrante.';

  @override
  String get backupUiErrorNewer =>
      'Este ficheiro é dunha versión máis nova de Cuadrante: actualiza a app.';

  @override
  String get backupUiErrorCorrupt =>
      'O ficheiro está danado ou incompleto e non se pode usar.';

  @override
  String get backupUiErrorTooLarge =>
      'Este ficheiro é demasiado grande para ser unha copia de Cuadrante.';

  @override
  String get backupUiErrorUnreadable => 'Non se puido ler o ficheiro.';

  @override
  String get backupUiErrorUntouched =>
      'Non cambiamos nada: os teus datos seguen como estaban.';

  @override
  String get backupUiErrorRestoreFailed =>
      'Non se puido restaurar. Os teus datos seguen como estaban.';

  @override
  String get backupUiErrorRestoreReload =>
      'Restauramos os teus datos, pero a pantalla non se puido actualizar. Pecha Cuadrante e volve abrilo.';

  @override
  String get backupUiBack => 'Volver';

  @override
  String get widgetWeekdaysShort => 'luns,mar,mér,xov,ven,sáb,dom';

  @override
  String get widgetWeekdayHeaders => 'L,M,M,X,V,S,D';

  @override
  String get widgetMonthNames =>
      'xaneiro,febreiro,marzo,abril,maio,xuño,xullo,agosto,setembro,outubro,novembro,decembro';

  @override
  String get widgetTomorrow => 'Mañá';

  @override
  String get widgetEmptyCircular => '–';

  @override
  String get widgetStaleTitle => 'Cuadrante';

  @override
  String get widgetStaleBody => 'Abre Cuadrante para estar ao día';

  @override
  String get widgetAddTitle => 'Engadir widget';

  @override
  String get widgetAddSubtitle => 'A túa quenda de hoxe na pantalla de inicio';

  @override
  String get widgetAddBody =>
      'O widget sempre amosa o día de hoxe, aínda que non abras a app.';

  @override
  String get widgetAddSmall => 'Pequeno: hoxe e mañá';

  @override
  String get widgetAddMedium => 'Mediano: os próximos 7 días';

  @override
  String get widgetAddLarge => 'Grande: o mes enteiro';

  @override
  String get widgetAddAgenda => 'Axenda: próximas quendas';

  @override
  String get widgetAddTwoWeeks => 'Dúas semanas: actual e seguinte';

  @override
  String get widgetAddManualAndroid =>
      'Mantén premida unha zona baleira da pantalla de inicio, escolle Widgets e busca Cuadrante.';

  @override
  String get widgetAddManualIos =>
      'Mantén premida a pantalla de inicio, toca o + de arriba e busca Cuadrante.';

  @override
  String get compareTitle => 'Comparar calendarios';

  @override
  String get compareOpen => 'Comparar calendarios';

  @override
  String get compareOpenSubtitle => 'Mira cando coincidides libres';

  @override
  String get compareSwap => 'Intercambiar';

  @override
  String get compareIntro =>
      'Escolle dous calendarios e mira as súas quendas xuntas. Márcanse os días libres dos dous.';

  @override
  String get compareFirstLabel => 'Primeiro calendario';

  @override
  String get compareSecondLabel => 'Segundo calendario';

  @override
  String get comparePickTitle => 'Escolle un calendario';

  @override
  String get compareNeedTwoTitle => 'Necesitas dous calendarios';

  @override
  String get compareNeedTwoBody =>
      'Crea outro calendario (a túa parella, un segundo traballo) para ver cando coincidides libres.';

  @override
  String compareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días libres en común este mes',
      one: '1 día libre en común este mes',
      zero: 'Ningún día libre en común este mes',
    );
    return '$_temp0';
  }

  @override
  String get compareFreeListTitle => 'Días libres en común';

  @override
  String get compareLegendFree => 'Libres os dous';

  @override
  String get compareNote =>
      'Conta como libre un día sen quenda de traballo: baleiro, libre ou cunha ausencia (vacacións, baixa…). Cada quenda conta no día en que comeza.';

  @override
  String get compareNoShiftMark => '–';

  @override
  String get compareBothFree => 'libres os dous';

  @override
  String compareCellCalendar(String calendar, String shifts) {
    return '$calendar: $shifts';
  }

  @override
  String get compareLoadFailed => 'Non se puideron ler os calendarios.';

  @override
  String get calendarsTitle => 'Calendarios';

  @override
  String get calendarsIntro =>
      'Cada calendario ten o seu propio cadro de quendas: o teu, o da túa parella, un segundo traballo. Os tipos de quenda son os mesmos en todos.';

  @override
  String get calendarsActiveBadge => 'Activo';

  @override
  String get calendarsPrimaryBadge => 'Widget e alarmas';

  @override
  String get calendarsAdd => 'Novo calendario';

  @override
  String get calendarsNewTitle => 'Novo calendario';

  @override
  String get calendarsEditTitle => 'Editar calendario';

  @override
  String get calendarsNameLabel => 'Nome';

  @override
  String get calendarsNameHint => 'Parella, segundo traballo…';

  @override
  String get calendarsColorLabel => 'Cor';

  @override
  String calendarsColorOption(int index) {
    return 'Cor $index';
  }

  @override
  String get calendarsCreate => 'Crear';

  @override
  String get calendarsMakePrimary => 'Usar para widget e alarmas';

  @override
  String get calendarsPrimaryHelp =>
      'O widget e as alarmas seguen este calendario aínda que esteas vendo outro.';

  @override
  String get calendarsArchive => 'Arquivar';

  @override
  String calendarsArchiveTitle(String name) {
    return 'Queres arquivar «$name»?';
  }

  @override
  String get calendarsArchiveBody =>
      'Deixará de saír na lista, pero poderás recuperalo desde «Arquivados». As súas quendas quedan gardadas no móbil.';

  @override
  String calendarsArchivePrimaryNote(String name) {
    return 'O widget e as alarmas pasarán a «$name».';
  }

  @override
  String calendarsArchivedSection(int count) {
    return 'Arquivados ($count)';
  }

  @override
  String get calendarsRestore => 'Recuperar';

  @override
  String calendarsRestoreSemantic(String name) {
    return 'Recuperar «$name»';
  }

  @override
  String calendarsRestored(String name) {
    return '«$name» recuperado';
  }

  @override
  String get calendarsLastError =>
      'Non podes arquivar o último calendario: sempre ten que haber un.';

  @override
  String get calendarsNameRequired => 'Ponlle un nome ao calendario.';

  @override
  String get calendarsNotFoundError => 'Ese calendario xa non existe.';

  @override
  String get calendarsSaveFailed =>
      'Non se puido gardar o calendario. Proba outra vez.';

  @override
  String calendarsSwitcherLabel(String name) {
    return 'Calendario $name. Cambiar de calendario';
  }

  @override
  String get calendarsSwitcherTitle => 'Cambiar de calendario';

  @override
  String get calendarsSwitchFailed => 'Non se puido cambiar de calendario.';

  @override
  String get calendarsManage => 'Xestionar calendarios';

  @override
  String get holidayImportAction => 'Traer festivos do calendario do móbil';

  @override
  String get holidayImportTitle => 'Festivos';

  @override
  String get holidayImportHelp =>
      'Só eventos de día completo. Todo queda no teu móbil; o teu calendario non cambia.';

  @override
  String get holidayImportRangeHelp => 'De inicio, este ano e o seguinte.';

  @override
  String get holidayImportSkipped => 'Xa existe · omítese';

  @override
  String get holidayImportReady => 'Engadirase';

  @override
  String holidayImportIgnored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Omítense $count eventos con hora.',
      one: 'Omítese 1 evento con hora.',
    );
    return '$_temp0';
  }

  @override
  String holidayImportCapped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos superan 31 días: recórtanse.',
      one: '1 evento supera 31 días: recórtase.',
    );
    return '$_temp0';
  }

  @override
  String holidayImportAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Engadir $count festivos',
      one: 'Engadir 1 festivo',
    );
    return '$_temp0';
  }

  @override
  String holidayImportAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count festivos engadidos',
      one: '1 festivo engadido',
    );
    return '$_temp0';
  }

  @override
  String get holidayImportEmpty => 'Non hai festivos novos.';

  @override
  String get holidayImportPreviewHelp =>
      'Omítense as datas que xa teñen festivo.';

  @override
  String get holidaysSettingsRegionTitle => 'Comunidade autónoma';

  @override
  String get holidaysSettingsRegionUnset => 'Sen escoller';

  @override
  String get holidaysSettingsRegionClear => 'Sen comunidade';

  @override
  String get holidaysSettingsMunicipalityTitle => 'Concello';

  @override
  String get holidaysSettingsMunicipalityNone => 'Ningún';

  @override
  String get holidaysSettingsMunicipalitySearch => 'Buscar concello';

  @override
  String holidaysSettingsMunicipalityNoMatch(String query) {
    return 'Ningún concello coincide con «$query»';
  }

  @override
  String get holidaysSettingsMunicipalityLoadFailed =>
      'Non se puido cargar a lista de concellos.';

  @override
  String get holidaysSettingsStatusNoRegion =>
      'Sen comunidade só saen os festivos estatais. Escolle a túa para ver os autonómicos.';

  @override
  String get holidaysSettingsStatusNoMunicipality =>
      'Escolle o teu concello para ver os seus festivos locais, ou engádeos ti abaixo.';

  @override
  String holidaysSettingsStatusLocalIncluded(String municipality) {
    return 'Festivos locais de $municipality: incluídos';
  }

  @override
  String holidaysSettingsStatusYearPending(String year) {
    return 'Os festivos oficiais de $year chegarán cunha actualización';
  }

  @override
  String get holidaysSettingsStatusLocalMissing =>
      'Aínda non temos os do teu concello: engádeos ti abaixo';

  @override
  String holidaysSettingsStatusLocalMissingYear(
    String municipality,
    String year,
  ) {
    return 'Aínda non temos os de $municipality en $year: engádeos ti abaixo';
  }

  @override
  String get holidaysSettingsStatusLocalPartial =>
      'Pode que falte algún: compróbaos.';

  @override
  String get holidaysSettingsAdd => 'Engadir festivo local';

  @override
  String get holidaysSettingsAddName => 'Nome';

  @override
  String get holidaysSettingsAddDefaultName => 'Festa local';

  @override
  String holidaysSettingsEmptyYear(String year) {
    return 'Aínda non temos os festivos de $year.';
  }

  @override
  String get holidaysSettingsScopeNational => 'Estatal';

  @override
  String get holidaysSettingsScopeLocal => 'Local';

  @override
  String get holidaysSettingsScopeUser => 'Teu';

  @override
  String holidaysSettingsNoteReplaces(String name) {
    return 'Substitúe a $name';
  }

  @override
  String holidaysSettingsNoteCovered(String name) {
    return 'No teu calendario tápao «$name»';
  }

  @override
  String holidaysSettingsSubstitutedTitle(String region) {
    return 'Non son festivo en $region';
  }

  @override
  String get holidaysSettingsSubstitutedBody =>
      'Unha comunidade pode cambiar estes festivos estatais por outros propios.';

  @override
  String get holidaysSettingsRemove => 'Quitar festivo';

  @override
  String holidaysSettingsRemoved(String name) {
    return 'Festivo quitado: $name';
  }

  @override
  String holidaysSettingsRowSemantics(String date, String name, String scope) {
    return '$date. $name. $scope';
  }

  @override
  String alarmTitle(String name, String start) {
    return 'Quenda de $name ás $start';
  }

  @override
  String alarmBody(String name, String start, String end) {
    return '$name: de $start a $end';
  }

  @override
  String get alarmChannelName => 'Alarmas de quenda';

  @override
  String get alarmChannelDescription =>
      'Avísate antes de que comece cada quenda.';

  @override
  String alarmsNotifDayBeforeTitle(String name, String start) {
    return 'Mañá: quenda de $name ás $start';
  }

  @override
  String get alarmsNotifSnooze => 'Adiar 10 min';

  @override
  String get alarmsNotifAwake => 'Xa estou esperto';

  @override
  String get alarmsNotifTestTitle => 'Aviso de proba';

  @override
  String get alarmsNotifTestBody =>
      'Así te avisará Cuadrante antes da túa quenda.';

  @override
  String get alarmsRowOn => 'Activadas';

  @override
  String get alarmsRowOff => 'Desactivadas';

  @override
  String get alarmsMasterTitle => 'Avisar antes de cada quenda';

  @override
  String get alarmsMasterHelp => 'Un aviso no móbil, sen conexión e sen conta.';

  @override
  String get alarmsPermOkTitle => 'Todo listo';

  @override
  String get alarmsPermOkBody =>
      'As notificacións e as alarmas á hora exacta están permitidas.';

  @override
  String get alarmsPermNotifTitle => 'Faltan as notificacións';

  @override
  String get alarmsPermNotifBody =>
      'Sen o permiso de notificacións, Cuadrante non pode avisarte. Se non che sae a xanela para permitilas, actívaas na configuración do sistema.';

  @override
  String get alarmsPermNotifAllow => 'Permitir';

  @override
  String get alarmsPermNotifBlockedBody =>
      'Android xa non che pregunta polas notificacións. Actívaas na configuración do sistema e Cuadrante poderá avisarte.';

  @override
  String get alarmsPermNotifOpenSettings => 'Abrir configuración';

  @override
  String get alarmsPermExactTitle => 'Alarmas e recordatorios';

  @override
  String get alarmsPermExactBody =>
      'As alarmas poden chegar cuns minutos de atraso. Para que soen á hora exacta, permite «Alarmas e recordatorios» na configuración do sistema.';

  @override
  String get alarmsPermExactOpen => 'Abrir configuración';

  @override
  String get alarmsSectionTypes => 'Tipos de quenda';

  @override
  String get alarmsTypesEmpty =>
      'Ningunha das túas quendas ten horario. Ponlle hora en As miñas quendas para que Cuadrante poida avisarte.';

  @override
  String get alarmsBeforeTitle => 'Antes da quenda';

  @override
  String get alarmsBeforeAtStart => 'Ao comezar';

  @override
  String get alarmsBeforeSheetTitle => 'Canto antes da quenda';

  @override
  String get alarmsBeforeCustom => 'Personalizado';

  @override
  String get alarmsBeforeCustomTitle => 'Antelación personalizada';

  @override
  String get alarmsBeforeCustomHelp =>
      'Horas e minutos antes de que comece a quenda.';

  @override
  String get alarmsBeforeCustomApply => 'Gardar';

  @override
  String get alarmsSecondSegmentTitle => 'Avisar tamén antes do segundo tramo';

  @override
  String get alarmsSecondSegmentHelper =>
      'Un segundo aviso, coa mesma antelación, antes de volver ao traballo.';

  @override
  String get alarmsDayBeforeTitle => 'Aviso o día anterior';

  @override
  String alarmsDayBeforeAt(String time) {
    return 'Ás $time';
  }

  @override
  String get alarmsDayBeforeTimeTitle => 'Hora do aviso';

  @override
  String get alarmsLabelTitle => 'Texto do aviso';

  @override
  String get alarmsLabelDefault => 'O de sempre';

  @override
  String get alarmsLabelHint => 'Por exemplo: A traballar';

  @override
  String get alarmsLabelApply => 'Gardar';

  @override
  String get alarmsLabelReset => 'Usar o de sempre';

  @override
  String get alarmsTestButton => 'Probar aviso';

  @override
  String get alarmsTestScheduled => 'Avisarémoste en 10 segundos.';

  @override
  String get alarmsTestDenied =>
      'Sen o permiso de notificacións non podemos probar o aviso.';

  @override
  String alarmsNextLine(String when, String shift) {
    return 'Próximo aviso: $when · $shift';
  }

  @override
  String alarmsNextLineDayBefore(String when, String shift) {
    return 'Próximo aviso: $when · $shift, o día anterior';
  }

  @override
  String alarmsNextWhen(String weekday, int day, String month, String time) {
    return '$weekday $day de $month, $time';
  }

  @override
  String get alarmsNextNone =>
      'Non hai ningún aviso previsto nos próximos días.';

  @override
  String get alarmsNextOff => 'As alarmas están desactivadas.';

  @override
  String get alarmsSkipDay => 'Sen alarma este día';

  @override
  String get alarmsReminderTitle => 'Recordatorio';

  @override
  String get alarmsReminderEmptyBody => 'Tes un recordatorio para hoxe';

  @override
  String get alarmsReminderChannelName => 'Recordatorios de notas';

  @override
  String get alarmsReminderChannelDescription =>
      'Avísate á hora que escollas na nota dun día.';

  @override
  String get dayReminderAdd => 'Avisarme';

  @override
  String dayReminderAt(String time) {
    return 'Aviso ás $time';
  }

  @override
  String get dayReminderChange => 'Cambiar a hora do aviso';

  @override
  String get dayReminderRemove => 'Quitar aviso';

  @override
  String get dayReminderRemoved => 'Aviso quitado';

  @override
  String get dayReminderPickHelp => 'Hora do aviso';

  @override
  String get dayReminderPast => 'Esa hora xa pasou: non soará.';

  @override
  String get dayReminderNoPermission =>
      'As notificacións están desactivadas, así que o aviso non soará. Actívaas na configuración do móbil.';

  @override
  String get dayReminderOnlyPrimary =>
      'Só soan os avisos do calendario principal.';

  @override
  String agendaSemanticsReminder(String time) {
    return 'aviso ás $time';
  }

  @override
  String get shiftTypesAlarmSection => 'Alarma';

  @override
  String get shiftTypesSoundLabel => 'Son';

  @override
  String get shiftTypesSoundHelper =>
      'Soa co volume das alarmas, cando actives a alarma desta quenda en Configuración.';

  @override
  String get shiftTypesSoundDefault => 'Predeterminado';

  @override
  String get shiftTypesSoundCustom => 'Son do móbil';

  @override
  String get shiftTypesSoundMissing => 'Non dispoñible: soa o predeterminado';

  @override
  String get shiftTypesSoundReset => 'Usar o predeterminado';

  @override
  String get catalogShiftMorningName => 'Mañá';

  @override
  String get catalogShiftMorningCode => 'M';

  @override
  String get catalogShiftAfternoonName => 'Tarde';

  @override
  String get catalogShiftAfternoonCode => 'T';

  @override
  String get catalogShiftNightName => 'Noite';

  @override
  String get catalogShiftNightCode => 'N';

  @override
  String get catalogShiftRestName => 'Libre';

  @override
  String get catalogShiftRestCode => 'L';

  @override
  String get catalogShiftGuard24Name => 'Garda 24 h';

  @override
  String get catalogShiftGuard24Code => 'G';

  @override
  String get catalogShiftPostNightName => 'Saínte';

  @override
  String get catalogShiftPostNightCode => 'S';

  @override
  String get catalogShiftVacationName => 'Vacacións';

  @override
  String get catalogShiftVacationCode => 'V';

  @override
  String get catalogShiftPersonalDayName => 'Libre disposición';

  @override
  String get catalogShiftPersonalDayCode => 'LD';

  @override
  String get catalogShiftDay12Name => 'Día 12 h';

  @override
  String get catalogShiftDay12Code => 'D';

  @override
  String get catalogShiftNight12Name => 'Noite 12 h';

  @override
  String get catalogShiftNight12Code => 'N12';

  @override
  String get catalogShiftSplitName => 'Partida';

  @override
  String get catalogShiftSplitCode => 'P';

  @override
  String get catalogPatternCorreturnosName => 'Quendas rotativas';

  @override
  String get catalogPatternCorreturnosDescription =>
      '5 mañás, 2 libres, 5 tardes, 2 libres, 5 noites, 2 libres';

  @override
  String get catalogPattern24x72Name => '24 x 72';

  @override
  String get catalogPattern24x72Description => 'Garda de 24 h e 72 h libres';

  @override
  String get catalogPattern12hName => '12 horas';

  @override
  String get catalogPattern12hDescription =>
      'Día 12 h, noite 12 h, saínte e libre';

  @override
  String get catalogPattern6x4Name => '6 x 4';

  @override
  String get catalogPattern6x4Description => '6 mañás e 4 libres';

  @override
  String get catalogPattern4x4Name => '4 x 4';

  @override
  String get catalogPattern4x4Description => '4 días de 12 h e 4 libres';

  @override
  String get catalogPattern5x2Name => '5 x 2';

  @override
  String get catalogPattern5x2Description =>
      '5 mañás e 2 libres (de luns a venres)';

  @override
  String get catalogPattern223Name => '2-2-3';

  @override
  String get catalogPattern223Description =>
      'Dous días de 12 h, dous libres, tres de 12 h, dous libres, dous de 12 h e tres libres (tamén 2-2-3-2-2-3)';

  @override
  String get catalogPatternContinentalName => 'Continental';

  @override
  String get catalogPatternContinentalDescription =>
      'Quenda continua de 28 días con 4 equipos: bloques de 2 e 3 mañás, tardes e noites, e 7 libres';

  @override
  String get catalogPatternDupontName => 'DuPont';

  @override
  String get catalogPatternDupontDescription =>
      'Ciclo de 28 días en quendas de 12 h: 4 noites, 3 libres, 3 días, 1 libre, 3 noites, 3 libres, 4 días e 7 libres';

  @override
  String get holidayNameNewYear => 'Aninovo';

  @override
  String get holidayNameEpiphany => 'Reis';

  @override
  String get holidayNameMaundyThursday => 'Xoves Santo';

  @override
  String get holidayNameGoodFriday => 'Venres Santo';

  @override
  String get holidayNameEasterMonday => 'Luns de Pascua';

  @override
  String get holidayNameLabourDay => 'Festa do Traballo';

  @override
  String get holidayNameAssumption => 'Asunción';

  @override
  String get holidayNameNationalDay => 'Festa Nacional de España';

  @override
  String get holidayNameAllSaints => 'Santos';

  @override
  String get holidayNameConstitution => 'Día da Constitución';

  @override
  String get holidayNameImmaculate => 'Inmaculada Concepción';

  @override
  String get holidayNameChristmas => 'Nadal';

  @override
  String get holidayNameStStephen => 'Santo Estevo';

  @override
  String get holidayNameStJoseph => 'San Xosé';

  @override
  String get holidayNameStJames => 'Santiago Apóstolo';

  @override
  String get holidayNameGaliciaDay => 'Día Nacional de Galicia';

  @override
  String get holidayNameStJamesGalicia =>
      'Santiago Apóstolo / Día Nacional de Galicia';

  @override
  String get holidayNameCataloniaDay => 'Diada de Cataluña';

  @override
  String get holidayNameBasqueDay => 'Día do País Vasco';

  @override
  String get catalogCalendarMainName => 'O meu cadro de quendas';

  @override
  String get historyUndone => 'Cambio desfeito';

  @override
  String get historyRedone => 'Cambio refeito';

  @override
  String get historyNothingToUndo => 'Nada que desfacer';

  @override
  String get historyNothingToRedo => 'Nada que refacer';

  @override
  String get monthPresentationGrid => 'Cuadrícula';

  @override
  String get monthPresentationList => 'Lista';

  @override
  String get monthSelectDays => 'Seleccionar días';

  @override
  String get monthSelectDay => 'Toca para escoller este día';

  @override
  String get monthListRecommended =>
      'Lista recomendada para ver os horarios completos e o texto grande.';

  @override
  String get monthListSelected => 'Presentación de lista';

  @override
  String get monthGridSelected => 'Presentación de cuadrícula';
}
