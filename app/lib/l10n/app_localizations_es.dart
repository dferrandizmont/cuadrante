// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Cuadrante';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Cerrar';

  @override
  String get delete => 'Borrar';

  @override
  String get save => 'Guardar';

  @override
  String get undo => 'Deshacer';

  @override
  String get redo => 'Rehacer';

  @override
  String get retry => 'Reintentar';

  @override
  String get back => 'Atrás';

  @override
  String get loadingLabel => 'Cargando';

  @override
  String get errorGeneric => 'Algo no ha ido bien. Prueba otra vez.';

  @override
  String get calendarToday => 'Hoy';

  @override
  String calendarPickMonth(String month) {
    return '$month, elegir mes';
  }

  @override
  String get calendarPreviousMonth => 'Mes anterior';

  @override
  String get calendarNextMonth => 'Mes siguiente';

  @override
  String calendarHeaderTomorrow(String date, String shifts) {
    return 'Mañana ($date): turno de $shifts';
  }

  @override
  String calendarHeaderTomorrowNone(String date) {
    return 'Mañana ($date): sin turno';
  }

  @override
  String get todayLabelNow => 'Ahora';

  @override
  String get todayLabelTonight => 'Esta noche';

  @override
  String get todayLabelToday => 'Hoy';

  @override
  String get todayLabelFree => 'Hoy libre';

  @override
  String get todayLabelDone => 'Hoy terminado';

  @override
  String todayFinishedAt(String time) {
    return 'Terminó a las $time';
  }

  @override
  String get todayLabelGap => 'Descanso';

  @override
  String todayBackAt(String time) {
    return 'Vuelves a las $time';
  }

  @override
  String todayBackIn(String duration) {
    return 'Vuelves en $duration';
  }

  @override
  String get todayFreeTitle => 'Libre';

  @override
  String todayUntil(String time) {
    return 'Hasta las $time';
  }

  @override
  String todayStartsIn(String duration) {
    return 'Empieza en $duration';
  }

  @override
  String todayEndsIn(String duration) {
    return 'Termina en $duration';
  }

  @override
  String todayNext(String name, String weekday, String time) {
    return 'Próximo: $name, $weekday $time';
  }

  @override
  String get todayNoNext => 'Sin turnos a la vista';

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
  String get calendarNoShift => 'Sin turno';

  @override
  String calendarShiftWithTimes(String name, String times) {
    return '$name $times';
  }

  @override
  String get calendarWeekdayMon => 'L';

  @override
  String get calendarWeekdayTue => 'M';

  @override
  String get calendarWeekdayWed => 'X';

  @override
  String get calendarWeekdayThu => 'J';

  @override
  String get calendarWeekdayFri => 'V';

  @override
  String get calendarWeekdaySat => 'S';

  @override
  String get calendarWeekdaySun => 'D';

  @override
  String get daySemanticsToday => 'hoy';

  @override
  String get daySemanticsNoShift => 'sin turno';

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
    return '$name de $start a $end y de $start2 a $end2';
  }

  @override
  String daySemanticsAnd(String first, String second) {
    return '$first y $second';
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
    return 'salida anticipada: $duration';
  }

  @override
  String daySheetHoliday(String name) {
    return 'Festivo: $name';
  }

  @override
  String get daySheetNote => 'Nota';

  @override
  String get daySheetEmpty => 'Este día no tiene turno.';

  @override
  String get dayPaneClose => 'Cerrar el día';

  @override
  String get upcomingTitle => 'Próximos días';

  @override
  String get dayDetailSourcePattern => 'Según tu patrón';

  @override
  String get dayDetailSourceOverride => 'Cambiado a mano';

  @override
  String get dayDetailAdd => 'Añadir turno';

  @override
  String get dayDetailDouble => 'Doblar con otro turno';

  @override
  String get dayDetailReset => 'Volver al patrón';

  @override
  String dayDetailPatternGives(String shifts) {
    return 'El patrón da: $shifts';
  }

  @override
  String get dayDetailNoteHint => 'Escribe una nota para este día';

  @override
  String get dayDetailUserHoliday => 'Festivo propio';

  @override
  String get dayDetailUserHolidayDefault => 'Festivo propio';

  @override
  String get dayDetailUserHolidayNameHint => 'Nombre del festivo';

  @override
  String get dayDetailDuplicate => 'Duplicar en otro día';

  @override
  String get dayDetailDuplicateHelp => 'Copiar a este día';

  @override
  String dayDetailDuplicated(String date) {
    return 'Copiado en $date';
  }

  @override
  String get dayDetailClear => 'Borrar día';

  @override
  String get dayDetailCleared => 'Día borrado';

  @override
  String get dayDetailMoveUp => 'Subir';

  @override
  String get dayDetailMoveDown => 'Bajar';

  @override
  String dayDetailRemove(String name) {
    return 'Quitar $name';
  }

  @override
  String get dayExtrasTitle => 'Horas extra / Salí antes';

  @override
  String get dayExtrasOvertime => 'Horas extra';

  @override
  String get dayExtrasEarlyLeave => 'Salí antes';

  @override
  String get dayExtrasNone => 'Ninguna';

  @override
  String get dayExtrasHelper =>
      'Suman o restan en las horas del mes y en el estimado. Con 0 se quita.';

  @override
  String dayExtrasMore(String label) {
    return 'Más $label';
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
  String get shiftTypesTitle => 'Mis turnos';

  @override
  String get shiftTypesEditEntry => 'Editar turnos';

  @override
  String get shiftTypesEmptyTitle => 'No tienes turnos';

  @override
  String get shiftTypesEmptyMessage =>
      'Crea el primero para poder pintarlo en el calendario.';

  @override
  String get shiftTypesNew => 'Nuevo turno';

  @override
  String get shiftTypesNewTitle => 'Nuevo turno';

  @override
  String get shiftTypesEditTitle => 'Editar turno';

  @override
  String get shiftTypesNotFound => 'No encontramos este turno';

  @override
  String get shiftTypesNotFoundMessage =>
      'Puede que lo hayas archivado. Vuelve a la lista de turnos.';

  @override
  String get shiftTypesArchive => 'Archivar';

  @override
  String shiftTypesArchiveTitle(String name) {
    return '¿Archivar «$name»?';
  }

  @override
  String get shiftTypesArchiveBody =>
      'Dejará de salir al pintar. Los días que ya lo usan lo seguirán mostrando.';

  @override
  String get shiftTypesArchiveConfirm => 'Archivar';

  @override
  String get shiftTypesDragHandle => 'Arrastrar para reordenar';

  @override
  String shiftTypesArchivedSection(int count) {
    return 'Archivados ($count)';
  }

  @override
  String get shiftTypesArchivedHelp =>
      'Dejaron de salir al pintar. Recupéralos y vuelven a la paleta.';

  @override
  String get shiftTypesRestore => 'Recuperar';

  @override
  String shiftTypesRestoreSemantic(String name) {
    return 'Recuperar «$name»';
  }

  @override
  String shiftTypesRestored(String name) {
    return '«$name» recuperado';
  }

  @override
  String get shiftTypesDiscardTitle => '¿Descartar los cambios?';

  @override
  String get shiftTypesDiscardBody =>
      'Lo que has cambiado en este turno no se guardará.';

  @override
  String get shiftTypesDiscardKeep => 'Seguir editando';

  @override
  String get shiftTypesDiscardConfirm => 'Descartar';

  @override
  String get shiftTypesNoTimes => 'Sin horario';

  @override
  String shiftTypesRatePerHour(String rate) {
    return '$rate/h';
  }

  @override
  String shiftTypesFixedPlusPerShift(String amount) {
    return '+$amount por turno';
  }

  @override
  String get shiftTypesCategoryWork => 'Trabajo';

  @override
  String get shiftTypesCategoryRest => 'Descanso';

  @override
  String get shiftTypesCategoryAbsence => 'Ausencia';

  @override
  String get shiftTypesNameLabel => 'Nombre';

  @override
  String get shiftTypesCodeLabel => 'Código';

  @override
  String get shiftTypesCodeHelper =>
      'De 1 a 3 caracteres. Es lo que se ve en cada casilla del mes.';

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
  String get shiftColorNameOrange => 'Naranja';

  @override
  String get shiftColorNameCoral => 'Coral';

  @override
  String get shiftColorNameIndigo => 'Índigo';

  @override
  String get shiftColorNameLightGrey => 'Gris claro';

  @override
  String get shiftColorNameRed => 'Rojo';

  @override
  String get shiftColorNameLilac => 'Lila';

  @override
  String get shiftColorNameGreen => 'Verde';

  @override
  String get shiftColorNameTeal => 'Turquesa';

  @override
  String get shiftColorNameRaspberry => 'Frambuesa';

  @override
  String get shiftColorNamePink => 'Rosa';

  @override
  String get shiftColorNameTangerine => 'Mandarina';

  @override
  String get shiftColorNameYellow => 'Amarillo';

  @override
  String get shiftColorNameLime => 'Lima';

  @override
  String get shiftColorNameForest => 'Verde bosque';

  @override
  String get shiftColorNameMint => 'Menta';

  @override
  String get shiftColorNameCyan => 'Cian';

  @override
  String get shiftColorNameSkyBlue => 'Azul cielo';

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
  String get shiftTypesColorCurrent => 'Color actual';

  @override
  String get shiftTypesIconLabel => 'Icono';

  @override
  String get shiftTypesIconHelper =>
      'Opcional. Se ve junto al código cuando hay sitio; el código y el color siempre están.';

  @override
  String get shiftTypesIconNone => 'Sin icono';

  @override
  String get shiftTypesIconChoose => 'Elegir icono';

  @override
  String shiftTypesIconCurrent(String name) {
    return 'Icono: $name';
  }

  @override
  String get shiftIconNameSun => 'Sol';

  @override
  String get shiftIconNameMoon => 'Luna';

  @override
  String get shiftIconNameSunrise => 'Amanecer';

  @override
  String get shiftIconNameHospital => 'Hospital';

  @override
  String get shiftIconNameAmbulance => 'Ambulancia';

  @override
  String get shiftIconNamePolice => 'Policía';

  @override
  String get shiftIconNameFire => 'Bomberos';

  @override
  String get shiftIconNameFactory => 'Fábrica';

  @override
  String get shiftIconNameTruck => 'Camión';

  @override
  String get shiftIconNamePlane => 'Avión';

  @override
  String get shiftIconNameSchool => 'Colegio';

  @override
  String get shiftIconNameHome => 'Casa';

  @override
  String get shiftIconNameBeach => 'Playa';

  @override
  String get shiftIconNameBed => 'Cama';

  @override
  String get shiftIconNameStar => 'Estrella';

  @override
  String get shiftIconNameHeart => 'Corazón';

  @override
  String get shiftIconNameCoffee => 'Café';

  @override
  String get shiftIconNameBook => 'Libro';

  @override
  String get shiftIconNameMoney => 'Dinero';

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
  String get shiftIconNameShop => 'Tienda';

  @override
  String get shiftIconNameTool => 'Herramientas';

  @override
  String get shiftIconNameBaby => 'Bebé';

  @override
  String get shiftIconNameSport => 'Deporte';

  @override
  String get shiftIconNameParty => 'Fiesta';

  @override
  String get shiftIconNameMedical => 'Médico';

  @override
  String get shiftTypesColorMore => 'Más colores…';

  @override
  String get shiftTypesColorPickerTitle => 'Elige tu color';

  @override
  String get shiftTypesColorPickerHelp =>
      'Mira cómo queda la casilla en claro y en oscuro. El texto se ajusta solo para que se lea bien.';

  @override
  String get shiftTypesColorHue => 'Tono';

  @override
  String get shiftTypesColorSaturation => 'Intensidad';

  @override
  String get shiftTypesColorLightness => 'Luminosidad';

  @override
  String shiftTypesColorHueSpoken(int degrees) {
    return '$degrees grados';
  }

  @override
  String shiftTypesColorPercentSpoken(int percent) {
    return '$percent por ciento';
  }

  @override
  String get shiftTypesColorHexLabel => 'Código hexadecimal';

  @override
  String get shiftTypesColorHexError =>
      'Escribe 6 cifras o letras de la A a la F, por ejemplo #1C7ED6.';

  @override
  String get shiftTypesColorUse => 'Usar este color';

  @override
  String get shiftTypesCategoryLabel => 'Categoría';

  @override
  String get shiftTypesTimesLabel => 'Horario';

  @override
  String shiftTypesStarts(String time) {
    return 'Empieza $time';
  }

  @override
  String shiftTypesEnds(String time) {
    return 'Termina $time';
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
    return 'Termina al día siguiente · dura $duration';
  }

  @override
  String get shiftTypesTwentyFourHours =>
      'Dura 24 h: termina al día siguiente a la misma hora';

  @override
  String get shiftTypesSplitLabel => 'Turno partido';

  @override
  String get shiftTypesSplitHelper =>
      'Dos tramos el mismo día, con un descanso en medio que no cuenta como trabajado.';

  @override
  String get shiftTypesSplitTemplate => 'Usar «Partido 09–13 / 17–21»';

  @override
  String get shiftTypesSplitSecondTitle => 'Segundo tramo';

  @override
  String get shiftTypesPickSecondStart => 'Inicio tramo 2';

  @override
  String get shiftTypesPickSecondEnd => 'Fin tramo 2';

  @override
  String shiftTypesSplitSummary(String first, String second, String total) {
    return 'Trabajas $first y $second: $total en total';
  }

  @override
  String get shiftTypesErrorSplitIncomplete =>
      'Pon cuándo empieza y cuándo acaba el segundo tramo, o apaga el turno partido.';

  @override
  String get shiftTypesErrorSplitStart =>
      'La hora de inicio del segundo tramo no es válida.';

  @override
  String get shiftTypesErrorSplitDuration =>
      'El segundo tramo tiene que durar entre 1 minuto y 24 h.';

  @override
  String get shiftTypesErrorSplitNotAfter =>
      'El segundo tramo no puede empezar justo cuando acaba el primero: sería un solo tramo. Deja un descanso entre los dos.';

  @override
  String get shiftTypesErrorSplitTooLong =>
      'Los dos tramos y el descanso entre ellos no caben en 24 h. Comprueba que el segundo empieza después de que acabe el primero.';

  @override
  String get shiftTypesBreakLabel => 'Descanso no pagado';

  @override
  String get shiftTypesBreakUnit => 'min';

  @override
  String get shiftTypesBreakHint => '0 min';

  @override
  String get shiftTypesRateHint => 'Sin precio';

  @override
  String get shiftTypesBreakHelper =>
      'Minutos del turno que no se pagan. Déjalo vacío si se paga todo.';

  @override
  String shiftTypesPaidHelper(String duration) {
    return 'Se pagan $duration';
  }

  @override
  String get shiftTypesNightLabel => 'Turno nocturno';

  @override
  String get shiftTypesNightHelper =>
      'Automático cuenta como noche las horas entre las 22:00 y las 06:00.';

  @override
  String get shiftTypesNightAuto => 'Automático';

  @override
  String get shiftTypesNightAlways => 'Siempre nocturno';

  @override
  String get shiftTypesNightNever => 'Nunca nocturno';

  @override
  String get shiftTypesFixedPlusLabel => 'Plus por turno (opcional)';

  @override
  String get shiftTypesFixedPlusHelper =>
      'Se suma una vez por cada turno trabajado.';

  @override
  String get shiftTypesFixedPlusHint => 'Sin plus';

  @override
  String get shiftTypesFixedPlusUnit => '€';

  @override
  String get shiftTypesRateLabel => 'Precio por hora (opcional)';

  @override
  String get shiftTypesRateHelper =>
      'Para calcular cuánto ganas en el resumen del mes.';

  @override
  String get shiftTypesRateUnit => '€/h';

  @override
  String get shiftTypesPreviewLabel => 'Así se verá en el mes';

  @override
  String get shiftTypesPreviewLight => 'Claro';

  @override
  String get shiftTypesPreviewDark => 'Oscuro';

  @override
  String shiftTypesPreviewContrast(String ratio) {
    return 'Contraste $ratio:1';
  }

  @override
  String get shiftTypesErrorCodeEmpty =>
      'Escribe un código de 1 a 3 caracteres';

  @override
  String get shiftTypesErrorCodeTooLong =>
      'El código admite hasta 3 caracteres, sin emojis ni espacios';

  @override
  String shiftTypesErrorCodeTaken(String name) {
    return 'Este código ya lo usa «$name»';
  }

  @override
  String get shiftTypesErrorNameEmpty => 'Pon un nombre al turno';

  @override
  String get shiftTypesErrorBreak =>
      'El descanso tiene que ser menor que la duración del turno';

  @override
  String get shiftTypesErrorRate =>
      'Escribe un importe válido, por ejemplo 12,50';

  @override
  String get paintFab => 'Pintar';

  @override
  String get paintHeader => 'Pintando';

  @override
  String paintHeaderShift(String name, String times) {
    return '$name · $times';
  }

  @override
  String get paintDone => 'Listo';

  @override
  String get paintDouble => 'Doblar';

  @override
  String get paintEraser => 'Borrar';

  @override
  String get paintToolsLabel => 'Herramientas para pintar';

  @override
  String get selectionHeader => 'Selección';

  @override
  String get selectionHint =>
      'Toca los días o mantén pulsado y arrastra para elegir varios';

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
  String get selectionBarLabel => 'Acciones para los días elegidos';

  @override
  String get selectionSetShift => 'Poner turno…';

  @override
  String get selectionDouble => 'Doblar con…';

  @override
  String get selectionClear => 'Borrar';

  @override
  String get selectionReset => 'Volver al patrón';

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
  String get selectionCellSelected => 'elegido';

  @override
  String get selectionSetShiftTitle => 'Poner turno';

  @override
  String get selectionSetShiftHelp =>
      'Sustituye los turnos de los días elegidos.';

  @override
  String get selectionDoubleTitle => 'Doblar con otro turno';

  @override
  String get selectionDoubleHelp =>
      'Añade el turno a los que ya tengan los días elegidos.';

  @override
  String get selectionNoteTitle => 'Nota para los días elegidos';

  @override
  String get selectionNoteHint => 'La misma nota en todos los días';

  @override
  String get selectionNoteSave => 'Guardar nota';

  @override
  String get selectionNoteRemove => 'Quitar notas';

  @override
  String get selectionPasteTitle => 'Pegar días';

  @override
  String selectionPasteSummary(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se pegan $count días',
      one: 'Se pega 1 día',
    );
    return '$_temp0 a partir del $date.';
  }

  @override
  String selectionPasteReach(String from, String to) {
    return 'Se pegará del $from al $to.';
  }

  @override
  String get selectionPasteReplaces =>
      'Los turnos de esos días se sustituyen. Podrás deshacerlo.';

  @override
  String get selectionIncludeNotes => 'Incluir notas';

  @override
  String get selectionIncludeNotesHelp =>
      'Las notas de los días copiados sustituyen a las que haya en el destino.';

  @override
  String get selectionCutNotesMove =>
      'Al cortar, las notas se mueven con los días.';

  @override
  String get selectionPasteConfirm => 'Pegar';

  @override
  String get selectionRepeatTitle => 'Repetir los días elegidos';

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
  String get selectionRepeatLess => 'Una vez menos';

  @override
  String get selectionRepeatMore => 'Una vez más';

  @override
  String selectionRepeatPreview(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cambia $count días más, hasta el $date.',
      one: 'Cambia 1 día más, hasta el $date.',
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
  String get selectionNothingChanged => 'Esos días ya estaban así';

  @override
  String selectionCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días copiados',
      one: '1 día copiado',
    );
    return '$_temp0. Elige el día de inicio y pulsa Pegar.';
  }

  @override
  String selectionCutDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días cortados',
      one: '1 día cortado',
    );
    return '$_temp0. Elige el día de inicio y pulsa Pegar.';
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
  String get selectionRunsTitle => 'Mis rotaciones';

  @override
  String get selectionRunsSubtitle => 'Termina o quita un patrón de una vez';

  @override
  String get selectionRunsEmptyTitle => 'Sin rotaciones';

  @override
  String get selectionRunsEmptyMessage =>
      'Cuando apliques un patrón desde Pintar, aparecerá aquí.';

  @override
  String selectionRunsRange(String from, String to) {
    return 'Del $from al $to';
  }

  @override
  String selectionRunsOpenEnded(String from) {
    return 'Desde el $from, sin fecha de fin';
  }

  @override
  String selectionRunsStep(int day) {
    return 'Empieza en el día $day del ciclo';
  }

  @override
  String get selectionRunsActive => 'En curso';

  @override
  String get selectionRunsFuture => 'Aún no ha empezado';

  @override
  String get selectionRunsEnded => 'Terminada';

  @override
  String get selectionRunsEnd => 'Terminar aquí';

  @override
  String get selectionRunsEndHelp => 'Primer día sin la rotación';

  @override
  String selectionRunsEndDone(String date) {
    return 'La rotación acaba el $date';
  }

  @override
  String get selectionRunsDelete => 'Eliminar';

  @override
  String selectionRunsDeleteTitle(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get selectionRunsDeleteBody =>
      'Se quita del calendario entero. Los días que cambiaste a mano y las notas se quedan como están. Podrás deshacerlo.';

  @override
  String get selectionRunsDeleted => 'Rotación eliminada';

  @override
  String get agendaTitle => 'Agenda';

  @override
  String get agendaOpenTooltip => 'Agenda de notas';

  @override
  String get agendaSearchHint => 'Buscar en notas y turnos';

  @override
  String get agendaSearchHintShort => 'Buscar';

  @override
  String get agendaModeNotes => 'Notas';

  @override
  String get agendaModeShifts => 'Turnos';

  @override
  String get agendaSearchScope =>
      'Busca en todas tus notas y festivos propios, y en los turnos desde hace un año hasta dentro de un año. También entiende fechas: 15/10 o 15 oct.';

  @override
  String get agendaSearchClear => 'Borrar búsqueda';

  @override
  String get agendaEmptyTitle => 'Sin notas próximas';

  @override
  String get agendaEmptyMessage =>
      'Las notas y los festivos propios de los próximos días aparecerán aquí.';

  @override
  String get agendaNoResultsTitle => 'Nada encontrado';

  @override
  String agendaNoResultsMessage(String query) {
    return 'No hay notas ni turnos que coincidan con «$query».';
  }

  @override
  String agendaHoliday(String name) {
    return 'Festivo: $name';
  }

  @override
  String agendaTruncated(int count) {
    return 'Se muestran los primeros $count resultados. Escribe algo más para afinar.';
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
  String get patternStepChoose => 'Elige un patrón';

  @override
  String get patternStepStart => '¿Cuándo empiezas?';

  @override
  String get patternStepEnd => '¿Hasta cuándo?';

  @override
  String get patternNext => 'Siguiente';

  @override
  String get patternBack => 'Atrás';

  @override
  String get patternApply => 'Aplicar';

  @override
  String get patternApplied => 'Patrón aplicado';

  @override
  String get patternApplyFailed => 'No se ha podido aplicar el patrón';

  @override
  String patternFromDay(String date) {
    return 'Desde el $date';
  }

  @override
  String get patternGroupHealth => 'Sanidad';

  @override
  String get patternGroupPolice => 'Policía y Guardia Civil';

  @override
  String get patternGroupFirefighters => 'Bomberos';

  @override
  String get patternGroupIndustry => 'Industria';

  @override
  String get patternGroupSecurity => 'Seguridad';

  @override
  String get patternGroupOther => 'Otro';

  @override
  String get patternGroupMine => 'Mis patrones';

  @override
  String patternGroupTypical(String shift) {
    return 'Empiezan por $shift';
  }

  @override
  String patternGroupIncluding(String shift) {
    return 'Incluyen $shift';
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
  String get patternCreateOwn => 'Crear el mío';

  @override
  String get patternCreateOwnHint => 'Monta tu secuencia día a día';

  @override
  String get patternBuilderBack => 'Elegir un patrón de la lista';

  @override
  String get patternBuilderName => 'Nombre del patrón';

  @override
  String get patternBuilderDefaultName => 'Mi patrón';

  @override
  String get patternBuilderSequence => 'Tu secuencia';

  @override
  String get patternBuilderEmpty =>
      'Toca los turnos de abajo para ir añadiendo días.';

  @override
  String get patternBuilderSameDay => 'Varios turnos en un día';

  @override
  String get patternBuilderSameDayHint =>
      'Activado: cada turno que toques se suma al último día de la secuencia, en vez de crear un día nuevo.';

  @override
  String get patternBuilderRemoveLast => 'Quitar el último';

  @override
  String get patternBuilderClear => 'Vaciar la secuencia';

  @override
  String patternBuilderAdd(String name) {
    return 'Añadir $name';
  }

  @override
  String get patternStartLabel => 'Día de inicio';

  @override
  String patternSuggestedStart(String weekday) {
    return 'Este patrón suele empezar en $weekday.';
  }

  @override
  String get patternWeekdayMonday => 'lunes';

  @override
  String get patternWeekdayTuesday => 'martes';

  @override
  String get patternWeekdayWednesday => 'miércoles';

  @override
  String get patternWeekdayThursday => 'jueves';

  @override
  String get patternWeekdayFriday => 'viernes';

  @override
  String get patternWeekdaySaturday => 'sábado';

  @override
  String get patternWeekdaySunday => 'domingo';

  @override
  String get patternOffsetTitle => '¿En qué día del ciclo estás ese día?';

  @override
  String patternOffsetHelp(String date) {
    return 'Toca el día del patrón que te toca el $date.';
  }

  @override
  String patternOffsetThatDay(String shifts) {
    return 'Ese día te toca: $shifts';
  }

  @override
  String patternChipDay(int day, String shifts) {
    return 'Día $day: $shifts';
  }

  @override
  String get patternEndNever => 'Sin fin';

  @override
  String get patternEndNeverHint => 'Se repite hasta que lo cambies.';

  @override
  String get patternEndUntil => 'Hasta una fecha';

  @override
  String get patternEndUntilHint =>
      'Después de esa fecha vuelve lo que tenías.';

  @override
  String get patternUntilLabel => 'Último día';

  @override
  String get patternOverridesTitle => 'Días que ya has cambiado a mano';

  @override
  String get patternOverridesKeep =>
      'Respetar los días que ya he cambiado a mano';

  @override
  String get patternOverridesKeepHint =>
      'Tus cambios se quedan; el patrón rellena el resto.';

  @override
  String get patternOverridesReplace => 'Sustituirlos por el patrón';

  @override
  String get patternOverridesReplaceHint =>
      'Se borran tus cambios a mano de esas fechas. Las notas se quedan.';

  @override
  String get patternPreviewTitle => 'Así quedará';

  @override
  String get patternPreviewNone => 'Elige un patrón para ver cómo queda.';

  @override
  String patternPreviewPostNight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saliente automático: $count días después de una noche.',
      one: 'Saliente automático: 1 día después de una noche.',
    );
    return '$_temp0';
  }

  @override
  String get patternPickBanner => 'Toca el día en que empieza el patrón';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String onboardingProgress(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get onboardingProfessionTitle => '¿A qué te dedicas?';

  @override
  String get onboardingProfessionHelp =>
      'Así te dejamos los turnos y las rotaciones de tu trabajo. Lo cambias cuando quieras.';

  @override
  String get onboardingProfessionNursing => 'Enfermería, TCAE y celadores';

  @override
  String get onboardingProfessionNursingHint =>
      'M 08–15, T 15–22, N 22–08 y saliente';

  @override
  String get onboardingProfessionMedicine => 'Medicina (guardias)';

  @override
  String get onboardingProfessionMedicineHint =>
      'Mañana, guardia de 24 h y saliente';

  @override
  String get onboardingProfessionPolice => 'Policía y Guardia Civil';

  @override
  String get onboardingProfessionPoliceHint => 'M 07–15, T 15–23 y N 23–07';

  @override
  String get onboardingProfessionFirefighters => 'Bomberos';

  @override
  String get onboardingProfessionFirefightersHint =>
      'Guardia de 24 h y descansos largos';

  @override
  String get onboardingProfessionIndustry => 'Industria';

  @override
  String get onboardingProfessionIndustryHint =>
      'Correturnos: M 06–14, T 14–22 y N 22–06';

  @override
  String get onboardingProfessionSecurity => 'Seguridad privada';

  @override
  String get onboardingProfessionSecurityHint =>
      'Turnos de 12 h, de día y de noche';

  @override
  String get onboardingProfessionHospitality => 'Hostelería y comercio';

  @override
  String get onboardingProfessionHospitalityHint => 'M 08–16 y T 16–00';

  @override
  String get onboardingProfessionOther => 'Otro';

  @override
  String get onboardingProfessionOtherHint =>
      'Empiezas con los turnos de siempre';

  @override
  String get onboardingPlaceTitle => '¿Dónde trabajas?';

  @override
  String get onboardingPlaceHelp =>
      'Para marcarte en el calendario los festivos de tu comunidad y de tu municipio.';

  @override
  String get onboardingRegionLabel => 'Comunidad';

  @override
  String get onboardingRegionPick => 'Elegir comunidad';

  @override
  String get onboardingRegionSheetTitle => 'Tu comunidad';

  @override
  String get onboardingMunicipalityLabel => 'Municipio (opcional)';

  @override
  String get onboardingMunicipalityPick => 'Buscar municipio';

  @override
  String get onboardingMunicipalityNeedsRegion => 'Elige antes la comunidad';

  @override
  String get onboardingMunicipalitySheetTitle => 'Tu municipio';

  @override
  String get onboardingMunicipalitySearch => 'Escribe el nombre';

  @override
  String get onboardingMunicipalityNone => 'Ningún municipio se llama así';

  @override
  String get onboardingMunicipalityClear => 'Quitar municipio';

  @override
  String get onboardingLocalHolidaysMissing =>
      'Los festivos locales de tu municipio los puedes añadir tú en dos toques.';

  @override
  String get onboardingRotationTitle => '¿Cómo es tu rotación?';

  @override
  String get onboardingRotationHelp =>
      'Elige la que más se parezca. Luego dices cuándo empiezas.';

  @override
  String get onboardingRotationTypical => 'Lo habitual en tu trabajo';

  @override
  String get onboardingRotationOthers => 'Otras rotaciones';

  @override
  String get onboardingRotationAll => 'Rotaciones';

  @override
  String get onboardingByHand => 'Lo pinto a mano';

  @override
  String get onboardingByHandHint =>
      'Sin rotación: pintas tú los días en el calendario.';

  @override
  String get onboardingStartTitle => '¿Cuándo empiezas?';

  @override
  String get onboardingStartHelp =>
      'Di desde qué día cuenta y en qué punto del ciclo estás ese día.';

  @override
  String get onboardingImportTitle => '¿Vienes de otra app?';

  @override
  String get onboardingImportBody =>
      'Si ya llevabas tus turnos en LRHSoft (Shifter), Supershift u otra app, tráelos desde su copia, el calendario del móvil o un archivo. También puedes hacerlo más tarde, en Ajustes.';

  @override
  String get onboardingReadyTitle => 'Listo';

  @override
  String get onboardingReadyBody =>
      'Tu calendario está preparado. Todo esto lo puedes cambiar cuando quieras en Ajustes.';

  @override
  String onboardingReadyProfession(String name) {
    return 'Trabajo: $name';
  }

  @override
  String onboardingReadyPlace(String place) {
    return 'Festivos: $place';
  }

  @override
  String onboardingReadyRotation(String name, String date) {
    return 'Rotación: $name, desde el $date';
  }

  @override
  String onboardingReadyOffset(int day, String shifts) {
    return 'Empiezas en el día $day del ciclo ($shifts)';
  }

  @override
  String get onboardingReadyByHand => 'Rotación: la pintas tú a mano';

  @override
  String get onboardingReadyNothing =>
      'No has elegido nada, así que empiezas con el calendario en blanco.';

  @override
  String get onboardingReadySaveFailed =>
      'No se ha podido guardar todo. Revisa tus turnos y festivos en Ajustes.';

  @override
  String get onboardingOpenCalendar => 'Ver mi calendario';

  @override
  String get onboardingTipTitle => 'Pinta tu mes en un momento';

  @override
  String get onboardingTipBody =>
      'Toca Pintar, elige un turno y arrastra por los días. Con el botón Patrón repites una rotación entera de una vez.';

  @override
  String get onboardingTipDismiss => 'Entendido';

  @override
  String get onboardingTipClose => 'Cerrar el consejo';

  @override
  String get paintScrollUp => 'Desplazar el mes hacia arriba';

  @override
  String get paintScrollDown => 'Desplazar el mes hacia abajo';

  @override
  String get monthTipPaint => 'Elige un turno y arrastra.';

  @override
  String get postNightAutoTitle => 'Saliente automático';

  @override
  String get postNightAutoHelp =>
      'Después de una noche, el día siguiente pasa a Saliente si estaba vacío o libre.';

  @override
  String get yearTitle => 'Vista anual';

  @override
  String get yearOpenTooltip => 'Ver el año';

  @override
  String get yearPrevious => 'Año anterior';

  @override
  String get yearNext => 'Año siguiente';

  @override
  String get yearShare => 'Compartir como imagen';

  @override
  String yearShareSubject(int year) {
    return 'Mis turnos de $year';
  }

  @override
  String get yearShareFailed => 'No se ha podido compartir la imagen';

  @override
  String yearImageTitle(int year) {
    return 'Mis turnos $year';
  }

  @override
  String get yearMonthEmpty => 'sin turnos';

  @override
  String get yearLegendTitle => 'Turnos del año';

  @override
  String get yearLegendEmpty => 'Este año no tiene turnos.';

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
  String get summaryTitle => 'Resumen';

  @override
  String get summaryOpenTooltip => 'Resumen del mes';

  @override
  String get summaryModeMonth => 'Mes';

  @override
  String get summaryModeYear => 'Año';

  @override
  String get summaryModeRange => 'Fechas…';

  @override
  String get summaryRangeFrom => 'Desde';

  @override
  String get summaryRangeTo => 'Hasta';

  @override
  String get summaryRangePrevious => 'Periodo anterior';

  @override
  String get summaryRangeNext => 'Periodo siguiente';

  @override
  String summaryRangeDays(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días en total',
      one: '1 día en total',
    );
    return '$_temp0. Puedes elegir hasta $max.';
  }

  @override
  String summaryRangeClamped(int max) {
    return 'El máximo son $max días: hemos acortado la fecha final.';
  }

  @override
  String summaryRangePreviousName(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'los $days días anteriores',
      one: 'el día anterior',
    );
    return '$_temp0';
  }

  @override
  String get summaryRangeEmptyTitle => 'Sin turnos en estas fechas';

  @override
  String get summaryRangeEmptyBody =>
      'Elige otras fechas o pinta turnos en el calendario.';

  @override
  String get summaryRangeNoteMidnight =>
      'Las horas de un turno que cruza la medianoche se cuentan en el día en que empieza, también si es el último día de las fechas.';

  @override
  String get summaryEmptyTitle => 'Sin turnos este mes';

  @override
  String get summaryEmptyBody =>
      'Pinta turnos en el calendario y aquí verás las horas y el estimado.';

  @override
  String get summaryHoursWorked => 'Horas trabajadas';

  @override
  String get summaryShiftsWorked => 'Turnos trabajados';

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
      other: '$count turnos en festivo',
      one: '1 turno en festivo',
    );
    return '$_temp0';
  }

  @override
  String get summaryOvertime => 'Horas extra';

  @override
  String get summaryEarlyLeave => 'Salidas anticipadas';

  @override
  String summaryExtrasPay(String amount) {
    return '$amount en el estimado';
  }

  @override
  String get summaryExtrasNoRate =>
      'Hay horas extra o salidas en días sin turno con precio por hora: no están en el estimado.';

  @override
  String get summaryNoteExtras =>
      'Horas extra y salidas anticipadas: las que anotas en cada día. Las extra suman y las salidas restan de las horas trabajadas (un día no baja de 0 h). Se valoran al precio por hora del primer turno con precio de ese día.';

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
      other: '$count turnos',
      one: '1 turno',
    );
    return '$_temp0';
  }

  @override
  String summaryNightOf(String hours) {
    return '$hours nocturnas';
  }

  @override
  String get summaryNoTimes => 'sin horario';

  @override
  String get summaryNoRate => 'sin precio';

  @override
  String get summaryGroupWork => 'Turnos de trabajo';

  @override
  String get summaryGroupRest => 'Descansos';

  @override
  String get summaryEstimateTitle => 'Ingresos estimados';

  @override
  String get summaryFixedPluses => 'Pluses';

  @override
  String summaryFixedPlusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turnos',
      one: '1 turno',
    );
    return '$_temp0';
  }

  @override
  String get summaryEstimateNote => 'Estimado, antes de impuestos';

  @override
  String get summaryEstimateNone =>
      'Pon el precio por hora o el plus por turno en Mis turnos para ver el estimado.';

  @override
  String summaryEstimateMissing(String types) {
    return 'No incluye el pago por hora de $types: sin precio.';
  }

  @override
  String get summaryRateAction => 'Poner precios en Mis turnos';

  @override
  String summaryDelta(String delta, String month) {
    return '$delta respecto a $month';
  }

  @override
  String summaryDeltaSame(String month) {
    return 'Las mismas horas que en $month';
  }

  @override
  String summaryDeltaNone(String month) {
    return 'Sin turnos en $month para comparar';
  }

  @override
  String get summaryNotesTitle => 'Cómo se cuenta';

  @override
  String get summaryNoteMidnight =>
      'Las horas de un turno que cruza la medianoche se cuentan en el día y el mes en que empieza.';

  @override
  String get summaryNoteNight =>
      'Nocturnas: de 22:00 a 06:00, salvo que marques otra cosa en el turno.';

  @override
  String get summaryNoteDst =>
      'Son horas de reloj: en la noche del cambio de hora no se ajusta a 7 o 9 horas.';

  @override
  String get summaryNoteNoTimes =>
      'Los turnos sin horario cuentan como turno, pero no suman horas.';

  @override
  String get summaryNoteHoliday =>
      'Horas en festivo: las que caen en un día festivo de tu comunidad y municipio, también si el turno cruza la medianoche.';

  @override
  String get summaryYearEmpty => 'Este año no tiene turnos.';

  @override
  String get summaryYearHint => 'Toca un mes para ver su detalle.';

  @override
  String get summaryYearHeaderMonth => 'Mes';

  @override
  String get summaryYearHeaderShifts => 'Turnos';

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
  String get summaryYearMonthEmpty => 'Sin turnos';

  @override
  String get summaryYearRowTitle => 'Horas y estimado';

  @override
  String get summaryYearRowBody => 'Turnos, horas y euros de cada mes';

  @override
  String summaryYearMonthSemantics(String month, String shifts, String hours) {
    return '$month: $shifts, $hours';
  }

  @override
  String get shareMonthTooltip => 'Compartir el mes como imagen';

  @override
  String shareMonthSubject(String month) {
    return 'Mis turnos de $month';
  }

  @override
  String get shareMonthFailed => 'No se ha podido compartir la imagen';

  @override
  String get shareMonthLegendTitle => 'Turnos del mes';

  @override
  String get shareMonthLegendEmpty => 'Este mes no tiene turnos.';

  @override
  String get saveFailed => 'No se ha podido guardar el cambio';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsOpenTooltip => 'Abrir ajustes';

  @override
  String get settingsSectionSchedule => 'Tu cuadrante';

  @override
  String get settingsShiftsTitle => 'Mis turnos';

  @override
  String get settingsShiftsSubtitle => 'Colores, códigos y horas';

  @override
  String get settingsCalendarsTitle => 'Calendarios';

  @override
  String get settingsSectionAppearance => 'Apariencia';

  @override
  String get settingsThemeTitle => 'Tema';

  @override
  String get settingsThemeSystemLight => 'Sistema (claro)';

  @override
  String get settingsThemeSystemDark => 'Sistema (oscuro)';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsWeekStartTitle => 'Primer día de la semana';

  @override
  String get settingsWeekStartMonday => 'Lunes';

  @override
  String get settingsWeekStartSunday => 'Domingo';

  @override
  String get settingsWeekNumbersTitle => 'Mostrar número de semana';

  @override
  String get settingsWeekNumbersSubtitle =>
      'Una columna a la izquierda del mes';

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
      'No se ha podido guardar el ajuste. Prueba otra vez.';

  @override
  String get settingsSectionMore => 'Avisos y datos';

  @override
  String get settingsHolidaysTitle => 'Festivos';

  @override
  String get settingsAlarmsTitle => 'Alarmas';

  @override
  String get settingsBackupTitle => 'Copia de seguridad';

  @override
  String get settingsPrivacyTitle => 'Política de privacidad';

  @override
  String get settingsPrivacySubtitle => 'Se abre en tu navegador';

  @override
  String get settingsPrivacyOpenFailed =>
      'No se ha podido abrir la política de privacidad. Prueba otra vez.';

  @override
  String get faqAlarmsQIos =>
      '¿Cómo configuro las alarmas y qué es el permiso de notificaciones?';

  @override
  String get faqAlarmsAIos =>
      'En Ajustes › Alarmas activa «Avisar antes de cada turno», elige cuánto antes y, si quieres, un aviso el día anterior a una hora fija. En el detalle de un día puedes quitar su alarma con «Sin alarma este día».\n\nSin el permiso de notificaciones, Cuadrante no puede avisarte. Si no te sale la ventana para permitirlas, actívalas en los ajustes del sistema.';

  @override
  String get faqWidgetAIos =>
      'En Ajustes › Añadir widget ves los tamaños (pequeño: hoy y mañana; mediano: los próximos 7 días; grande: el mes entero) y cómo colocarlo. Mantén pulsada la pantalla de inicio, toca el + de arriba y busca Cuadrante.\n\nEl widget guarda tus próximos días. El sistema decide cuándo lo actualiza y puede retrasar el cambio de día. Si se queda sin datos, abre Cuadrante para ponerlo al día.';

  @override
  String get faqBackupAIos =>
      'Ajustes › Copia de seguridad guarda copias automáticas en este dispositivo después de cada cambio, pero se pierden si lo pierdes o desinstalas la app. Exporta un archivo con «Exportar archivo» y guárdalo en iCloud Drive o envíatelo por WhatsApp o correo.\n\nPara cambiar de dispositivo: exporta el archivo, instala Cuadrante en el nuevo, abre el archivo con la app (o usa «Importar archivo» en la copia de seguridad) y revisa la vista previa antes de restaurar. «Probar restauración» comprueba que tu última copia se puede recuperar entera.';

  @override
  String get calExportPermissionDeniedBodyIos =>
      'Actívalo en los ajustes del sistema (Cuadrante › Calendarios) y vuelve aquí.';

  @override
  String get backupUiWarningIos =>
      'Estas copias se guardan en este dispositivo. Si desinstalas la app sin otra copia, se pierde. Exporta un archivo y guárdalo en iCloud Drive o envíalo por WhatsApp o correo.';

  @override
  String get backupUiExportSubtitleIos =>
      'Para guardarlo en iCloud Drive o mandarlo por WhatsApp o correo';

  @override
  String get settingsSectionHelp => 'Ayuda';

  @override
  String get settingsHelpTitle => 'Ayuda y contacto';

  @override
  String get settingsHelpSubtitle => 'Escríbenos si algo no va bien';

  @override
  String get settingsHelpBody =>
      '¿Dudas o algo no va bien? Cuéntanos qué te pasa y qué versión usas.';

  @override
  String get settingsHelpSubtitleSoon =>
      'Estamos preparando el correo de soporte';

  @override
  String get settingsHelpBodySoon =>
      'Todavía no tenemos correo de soporte. Mientras tanto, mira las preguntas frecuentes y, si algo no va bien, ten a mano la versión que usas.';

  @override
  String get settingsHelpNoEmail =>
      'El correo de soporte llegará con la versión de la tienda.';

  @override
  String get settingsHelpCopyEmail => 'Copiar correo';

  @override
  String get settingsHelpCopyVersion => 'Copiar versión';

  @override
  String get settingsFaqTitle => 'Preguntas frecuentes';

  @override
  String get settingsFaqSubtitle => 'Pintar, rotaciones, alarmas, widget y más';

  @override
  String get faqIntro =>
      'Respuestas rápidas sobre cómo funciona Cuadrante. Todo está en este dispositivo: no hace falta cuenta ni conexión.';

  @override
  String get faqNotFound => '¿No encuentras lo que buscas?';

  @override
  String get faqContact => 'Ayuda y contacto';

  @override
  String get faqPaintQ => '¿Cómo pinto el mes?';

  @override
  String get faqPaintA =>
      'Pulsa «Pintar» en el calendario, elige un turno abajo y toca los días o pasa el dedo por ellos. Para vaciar un día usa «Borrar». Cada trazo se puede deshacer y rehacer con las flechas de la barra. Pulsa «Listo» cuando termines.\n\nSi tocas un día sin estar pintando se abre su detalle: ahí cambias el turno, añades una nota o vuelves al patrón. Si mantienes pulsado un día empiezas a elegir varios a la vez: puedes ponerles turno, copiarlos, cortarlos y pegarlos, o repetir una semana.';

  @override
  String get faqPatternQ => '¿Cómo aplico una rotación y qué es el desfase?';

  @override
  String get faqPatternA =>
      'En modo pintar pulsa el botón «Patrón» y sigue los pasos: elige tu rotación (o crea la tuya), el día en que empiezas y hasta cuándo se repite.\n\nEl desfase es el punto del ciclo en el que estás el día de inicio. Si ese día te toca la noche, en el paso «¿En qué día del ciclo estás ese día?» tocas la noche y el resto se ajusta solo. Los días que ya cambiaste a mano se respetan o se sustituyen, como prefieras. Para terminar o quitar una rotación ve a Ajustes › Mis rotaciones.';

  @override
  String get faqDoubleQ => '¿Cómo doblo un turno?';

  @override
  String get faqDoubleA =>
      'Doblar es hacer dos turnos el mismo día. Toca el día y, en su detalle, usa «Doblar con otro turno». Si estás pintando, activa «Doblar» y toca los días. Con varios días elegidos, «Doblar con…» añade el turno a todos.\n\nUn día puede llevar los turnos que necesites y cada uno suma sus horas por separado.';

  @override
  String get faqPostNightQ => '¿Qué es el saliente automático?';

  @override
  String get faqPostNightA =>
      'Es el descanso del día siguiente a una noche. Si lo activas en Ajustes › Saliente automático, al pintar o aplicar una noche el día siguiente pasa a Saliente cuando estaba vacío o libre. Los días que ya tenían otro turno no se tocan. Viene apagado.';

  @override
  String get faqNotesQ => '¿Cómo uso las notas y la agenda?';

  @override
  String get faqNotesA =>
      'Toca un día y escribe en el campo de la nota; los días con nota se marcan en el calendario. Abre la agenda desde arriba del calendario: «Notas» reúne tus notas y festivos propios; «Turnos» muestra los turnos próximos.\n\nBusca por texto, sin importar mayúsculas ni tildes, o por fecha: por ejemplo, 15/10 o 15 oct. La búsqueda incluye todas tus notas y festivos propios, y los turnos desde hace un año hasta dentro de un año.';

  @override
  String get faqAlarmsQ =>
      '¿Cómo configuro las alarmas y qué es el permiso de alarmas exactas?';

  @override
  String get faqAlarmsA =>
      'En Ajustes › Alarmas activa «Avisar antes de cada turno», elige cuánto antes y, si quieres, un aviso el día anterior a una hora fija. En el detalle de un día puedes quitar su alarma con «Sin alarma este día».\n\nEn Android hacen falta las notificaciones y el permiso «Alarmas y recordatorios» de los ajustes del sistema: sin él, Android puede retrasar el aviso unos minutos. La pantalla de alarmas te dice qué falta y te lleva a los ajustes. Si tu móvil ahorra batería de forma agresiva, deja Cuadrante sin restricciones para que no pare los avisos.';

  @override
  String get faqHolidaysQ => '¿Cómo añado un festivo local?';

  @override
  String get faqHolidaysA =>
      'En Ajustes › Festivos elige tu comunidad y tu municipio y verás los festivos que te tocan. Si falta el de tu pueblo, toca ese día en el calendario y activa «Festivo propio»: le pones nombre y desde ese momento cuenta como festivo.\n\nTambién puedes usar «Traer festivos del calendario del móvil» en Ajustes › Festivos. Elige los calendarios y las fechas y revisa la vista previa: solo se leen eventos de día completo, se omiten los festivos que ya tienes y puedes deshacer. No se cambian los eventos del calendario.';

  @override
  String get faqWidgetQ => '¿Cómo añado el widget y por qué cambia solo?';

  @override
  String get faqWidgetA =>
      'En Ajustes › Añadir widget ves los tamaños (pequeño: hoy y mañana; mediano: los próximos 7 días; grande: el mes entero) y cómo colocarlo. En Android, mantén pulsada una zona vacía de la pantalla de inicio, elige Widgets y busca Cuadrante.\n\nEl widget siempre enseña el día de hoy: cambia de día a medianoche aunque no abras la app, porque lleva guardados tus próximos días. Si pasa mucho tiempo sin abrir Cuadrante se queda sin datos y te pide abrir la app para ponerse al día.';

  @override
  String get faqBackupQ => '¿Cómo hago una copia y cambio de dispositivo?';

  @override
  String get faqBackupA =>
      'Ajustes › Copia de seguridad guarda copias automáticas en este dispositivo después de cada cambio, pero se pierden si lo pierdes o desinstalas la app. Exporta un archivo con «Exportar archivo» y guárdalo en Drive o envíatelo por WhatsApp o correo.\n\nPara cambiar de dispositivo: exporta el archivo, instala Cuadrante en el nuevo, abre el archivo con la app (o usa «Importar archivo» en la copia de seguridad) y revisa la vista previa antes de restaurar. «Probar restauración» comprueba que tu última copia se puede recuperar entera.';

  @override
  String get faqImportQ =>
      '¿Puedo importar o exportar mis turnos al calendario?';

  @override
  String get faqImportA =>
      'Sí. En Ajustes › Importar turnos puedes traer una copia «.Shifter» de LRHSoft, turnos del calendario del móvil, un archivo .ics o un CSV. Para LRHSoft, crea una copia en Menú › Copia de seguridad › Copia local y elige el archivo de Documents › ShifterBackups. Revisa las fechas, los tipos de turno y la vista previa antes de importar.\n\n«Exportar al calendario del móvil» copia tus turnos una vez a un calendario del teléfono. Si exportas otra vez no se duplican: solo se tocan los eventos que creó Cuadrante.';

  @override
  String get faqCalendarsQ => '¿Puedo llevar varios calendarios y compararlos?';

  @override
  String get faqCalendarsA =>
      'Sí. En Ajustes › Calendarios creas uno para tu pareja, un segundo trabajo o un hijo: cada uno tiene sus rotaciones y sus días, y los tipos de turno son los mismos. Con dos o más, el nombre del calendario sobre el mes te deja cambiar de uno a otro. El widget y las alarmas siguen el calendario marcado como «Widget y alarmas».\n\nPara ver cuándo coincidís libres, pulsa «Comparar calendarios» en esa misma hoja: eliges dos y ves sus turnos juntos y los días libres en común del mes.';

  @override
  String get faqSummaryQ => '¿Cómo se calculan las horas y los euros?';

  @override
  String get faqSummaryA =>
      'El icono de resumen del calendario enseña los turnos, las horas, las nocturnas y las de festivo del mes, de un año entero o de las fechas que elijas en «Fechas…» (hasta 366 días). Un turno cuenta en el día en que empieza, aunque cruce la medianoche.\n\nPara ver euros, pon el precio por hora y, si lo tienes, el plus fijo por tipo de turno en Ajustes › Mis turnos. La estimación incluye esos pluses fijos, antes de impuestos. No incluye pluses por hora nocturna o festiva ni retenciones.\n\nEl «Plus por turno» se suma una vez por cada turno trabajado de ese tipo, también si es partido; no depende de las horas. Los descansos y las ausencias no lo suman.';

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
  String get settingsAboutVersionDev => 'Versión de desarrollo';

  @override
  String get settingsAboutTagline =>
      'Cuadrante funciona sin conexión y sin cuenta: tus turnos se quedan en tu móvil.';

  @override
  String get settingsAboutLicenses => 'Licencias de código abierto';

  @override
  String calendarWeekNumberSemantics(int number) {
    return 'Semana $number';
  }

  @override
  String get importSectionTitle => 'Importar y exportar';

  @override
  String get importRowTitle => 'Importar turnos';

  @override
  String get importRowSubtitle =>
      'Copia de LRHSoft, calendario del móvil, .ics o CSV';

  @override
  String get calExportRowTitle => 'Exportar turnos';

  @override
  String get calExportRowSubtitle => 'Al calendario del móvil, sin duplicados';

  @override
  String get importTitle => 'Importar turnos';

  @override
  String importStepOf(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get importNext => 'Siguiente';

  @override
  String get importReading => 'Leyendo…';

  @override
  String get importSourceTitle => '¿De dónde vienen tus turnos?';

  @override
  String get importSourceHelp =>
      'Cuadrante lee los eventos aquí mismo, en tu móvil, y no los envía a ningún sitio. Tú decides qué se importa.';

  @override
  String get importSourceDevice => 'Calendario del móvil';

  @override
  String get importSourceDeviceHelp =>
      'Google, iCloud, Outlook… lo que tengas en la app de calendario.';

  @override
  String get importSourceIcs => 'Archivo .ics';

  @override
  String get importSourceIcsHelp =>
      'Un calendario exportado, con un turno por evento.';

  @override
  String get importSourceCsv => 'Archivo CSV';

  @override
  String get importSourceCsvHelp =>
      'Una hoja con una fecha y un turno en cada fila.';

  @override
  String get importSourceLrhsoft => 'Copia de LRHSoft (Calendario de Turnos)';

  @override
  String get importSourceLrhsoftHelp => 'El archivo .Shifter de tu copia local';

  @override
  String get importFileLrhsoft => 'Copia de LRHSoft';

  @override
  String get importHowToTitle => '¿Vienes de LRHSoft o Supershift?';

  @override
  String get importHowToBody =>
      'LRHSoft o Shifter: en la app, Menú › Copia de seguridad › Copia local. Después elige aquí ese archivo .Shifter: está en la memoria del móvil, en Documents › ShifterBackups.\nSupershift: exporta tus turnos al calendario del móvil y elige «Calendario del móvil».';

  @override
  String get calExportPermissionTitle => 'Falta el permiso del calendario';

  @override
  String get calExportPermissionReadBody =>
      'Para importar, Cuadrante necesita leer los eventos de tus calendarios. Solo lo hace ahora, mientras importas, y no guarda nada fuera del móvil.';

  @override
  String get calExportPermissionWriteBody =>
      'Para añadir tus turnos, Cuadrante necesita acceso a tus calendarios. Solo añade o cambia sus propios eventos, y solo cuando tú exportas. Si el calendario que elijas se sincroniza con una cuenta (Google, iCloud...), esa cuenta también recibirá los turnos.';

  @override
  String get calExportPermissionAgainBody =>
      'No has dado el permiso. Sin él no podemos usar tus calendarios, pero puedes permitirlo ahora. Si lo rechazas otra vez, tendrás que activarlo en los ajustes del sistema.';

  @override
  String get calExportPermissionAllow => 'Permitir acceso';

  @override
  String get calExportPermissionDeniedTitle =>
      'El acceso al calendario está desactivado';

  @override
  String get calExportPermissionDeniedBody =>
      'Actívalo en los ajustes del sistema (Permisos › Calendario) y vuelve aquí.';

  @override
  String get calExportPermissionSettings => 'Abrir ajustes';

  @override
  String get calExportPermissionRecheck => 'Comprobar de nuevo';

  @override
  String get calExportPermissionRestrictedTitle =>
      'Este móvil no deja usar el calendario';

  @override
  String get calExportPermissionRestrictedBody =>
      'Puede ser un control parental o un perfil de trabajo. Si importas, prueba con un archivo .ics.';

  @override
  String get calExportPermissionWriteOnlyBody =>
      'El sistema solo ha dado permiso para añadir eventos. Cuadrante necesita acceso completo para leer los calendarios o para sustituir los eventos de una exportación anterior.';

  @override
  String get importCalendarsTitle => 'Elige los calendarios';

  @override
  String get importCalendarsHelp =>
      'Marca de dónde vienen tus turnos. Los demás no se tocan.';

  @override
  String get importCalendarsEmpty => 'No hay calendarios en este móvil.';

  @override
  String get importCalendarsNoAccount => 'Sin cuenta';

  @override
  String get importCalendarsReadOnly => 'Solo lectura';

  @override
  String importCalendarSemantics(String name, String account) {
    return '$name, $account';
  }

  @override
  String get importRangeTitle => '¿De qué fechas?';

  @override
  String get importRangeHelp => 'Solo se miran los eventos de estos días.';

  @override
  String get importRangeFrom => 'Desde';

  @override
  String get importRangeTo => 'Hasta';

  @override
  String get importRangeDefault => 'Últimos 12 meses y próximos 6';

  @override
  String get importRangeInvalid =>
      'La fecha final no puede ser anterior a la inicial.';

  @override
  String get importRangeClamped =>
      'El máximo son 5 años: se ha recortado el principio.';

  @override
  String importRangeFile(String name) {
    return 'Archivo: $name';
  }

  @override
  String importRangeFileEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'El archivo trae $count eventos.',
      one: 'El archivo trae 1 evento.',
    );
    return '$_temp0';
  }

  @override
  String importRangeFileSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos no tienen una fecha válida y no se leerán.',
      one: '1 evento no tiene una fecha válida y no se leerá.',
    );
    return '$_temp0';
  }

  @override
  String importRangeFileRules(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count eventos tienen una repetición que no entendemos y cuentan una sola vez.',
      one: '1 evento tiene una repetición que no entendemos y cuenta una sola vez.',
    );
    return '$_temp0';
  }

  @override
  String get importColumnsTitle => '¿Qué es cada columna?';

  @override
  String get importColumnsHelp =>
      'Mira las primeras filas y confirma cuál es la fecha y cuál el turno.';

  @override
  String get importColumnsHeader => 'La primera fila son los títulos';

  @override
  String get importColumnDate => 'Fecha';

  @override
  String get importColumnTitle => 'Turno o código';

  @override
  String get importColumnStart => 'Hora de inicio (opcional)';

  @override
  String get importColumnEnd => 'Hora de fin (opcional)';

  @override
  String get importColumnNone => 'Ninguna';

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
      'Desliza hacia los lados para ver todas las columnas.';

  @override
  String get importColumnsPreview => 'Primeras filas';

  @override
  String get importMappingTitle => '¿A qué turno corresponde cada título?';

  @override
  String get importMappingHelp =>
      'Agrupamos los eventos por título. Elige uno de tus turnos, crea uno nuevo o ignóralos.';

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
    return 'Hay más de $limit eventos: solo se han leído los primeros. Acorta las fechas para ver el resto.';
  }

  @override
  String importMappingSkippedRows(int count, int line) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count filas se han saltado por no tener una fecha o un turno válidos (por ejemplo, la línea $line).',
      one:
          '1 fila se ha saltado por no tener una fecha o un turno válidos (por ejemplo, la línea $line).',
    );
    return '$_temp0';
  }

  @override
  String get importMappingNothing => 'Elige al menos un título para importar.';

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
  String get importGroupAllDay => 'Todo el día';

  @override
  String importGroupExamples(String dates) {
    return 'p. ej. $dates';
  }

  @override
  String get importGroupUntitled => 'Sin título';

  @override
  String get importMapIgnore => 'Ignorar';

  @override
  String get importMapCreate => 'Crear tipo nuevo';

  @override
  String get importMapChoose => 'Elegir turno';

  @override
  String get importMapSuggested => 'Sugerido';

  @override
  String importMapNew(String name) {
    return 'Nuevo: $name';
  }

  @override
  String importMapPickTitle(String title) {
    return '¿Qué turno es «$title»?';
  }

  @override
  String importMapSemantics(String title, String choice) {
    return '$title: $choice';
  }

  @override
  String get importNewTypeTitle => 'Tipo de turno nuevo';

  @override
  String get importNewTypeUse => 'Usar este tipo';

  @override
  String get importPreviewTitle => 'Así quedará';

  @override
  String get importPreviewHelp =>
      'Revisa los meses. No se guarda nada hasta que pulses Importar.';

  @override
  String importPreviewTarget(String name) {
    return 'Se importa en «$name».';
  }

  @override
  String importPreviewDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se escribirán $count días.',
      one: 'Se escribirá 1 día.',
    );
    return '$_temp0';
  }

  @override
  String importPreviewUnchanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días ya estaban igual.',
      one: '1 día ya estaba igual.',
    );
    return '$_temp0';
  }

  @override
  String importPreviewNewTypes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se crearán $count tipos de turno nuevos.',
      one: 'Se creará 1 tipo de turno nuevo.',
    );
    return '$_temp0';
  }

  @override
  String get importPreviewEmpty => 'Con estas elecciones no cambia ningún día.';

  @override
  String importPreviewMoreMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Y $count meses más sin mostrar.',
      one: 'Y 1 mes más sin mostrar.',
    );
    return '$_temp0';
  }

  @override
  String importConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días ya tienen turno',
      one: '1 día ya tiene turno',
    );
    return '$_temp0';
  }

  @override
  String get importConflictsHelp => '¿Qué hacemos con ellos?';

  @override
  String get importConflictReplace => 'Sustituir';

  @override
  String get importConflictKeep => 'Mantener lo mío';

  @override
  String importConflictsExamples(String dates) {
    return 'Por ejemplo: $dates';
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
      other: 'Se han importado $count días.',
      one: 'Se ha importado 1 día.',
    );
    return '$_temp0';
  }

  @override
  String importAppliedWithTypes(int days, int types) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Se han importado $days días',
      one: 'Se ha importado 1 día',
    );
    String _temp1 = intl.Intl.pluralLogic(
      types,
      locale: localeName,
      other: '$types tipos de turno nuevos',
      one: '1 tipo de turno nuevo',
    );
    return '$_temp0 y $_temp1.';
  }

  @override
  String get importUndoDone => 'Se ha deshecho la importación.';

  @override
  String importUndoKeptTypes(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se quedan los tipos «$names»: algo los usa.',
      one: 'Se queda el tipo «$names»: algo lo usa.',
    );
    return '$_temp0';
  }

  @override
  String get importApplyFailed => 'No se ha podido importar. Prueba otra vez.';

  @override
  String get importProblemPermissionDenied =>
      'Sin el permiso no podemos leer tus calendarios.';

  @override
  String get importProblemPermissionRestricted =>
      'Este móvil no deja a Cuadrante usar el calendario. Prueba con un archivo.';

  @override
  String get importProblemCalendarUnavailable =>
      'Este móvil no tiene calendarios disponibles.';

  @override
  String get importProblemReadFailed =>
      'No se han podido leer los eventos. Prueba otra vez.';

  @override
  String get importProblemFileTooLarge =>
      'El archivo pesa más de 5 MB. Al exportarlo, elige menos fechas.';

  @override
  String get importProblemFileUnreadable =>
      'No hemos podido abrir ese archivo. Aceptamos .csv, .ics y la copia .Shifter de LRHSoft.';

  @override
  String get importProblemNotCalendar =>
      'Ese archivo no parece un calendario .ics.';

  @override
  String get importProblemNotCsv =>
      'No hemos encontrado una columna de fechas en ese CSV.';

  @override
  String get importProblemNoEvents => 'No hay eventos en esas fechas.';

  @override
  String get importProblemTooComplex =>
      'Ese archivo es demasiado grande o complicado y tarda demasiado. Al exportarlo, elige menos fechas.';

  @override
  String get importProblemUnknown =>
      'Algo no ha ido bien al leer el archivo. Prueba con otro.';

  @override
  String get importProblemNotLrhsoft =>
      'Ese archivo no parece una copia de LRHSoft (.Shifter). Prueba a crear otra copia local.';

  @override
  String importRangeLrhsoftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'La copia trae $count días.',
      one: 'La copia trae 1 día.',
    );
    return '$_temp0';
  }

  @override
  String importMappingInvalidRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas no válidas ignoradas.',
      one: '1 fila no válida ignorada.',
    );
    return '$_temp0';
  }

  @override
  String get importLrhsoftNotImported =>
      'No se traen las alarmas, los dibujos, las fotos ni las horas extra.';

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
      other: 'Se han importado $count notas.',
      one: 'Se ha importado 1 nota.',
    );
    return '$_temp0';
  }

  @override
  String importPreviewNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se añadirán $count notas.',
      one: 'Se añadirá 1 nota.',
    );
    return '$_temp0';
  }

  @override
  String get calExportTitle => 'Exportar turnos';

  @override
  String get calExportHelp =>
      'Añade tus turnos como eventos a un calendario del móvil, una sola vez. Si lo repites, Cuadrante sustituye sus eventos anteriores en esas fechas en vez de duplicarlos.';

  @override
  String calExportSource(String name) {
    return 'Se exportan los turnos de «$name».';
  }

  @override
  String get calExportCalendarLabel => 'Calendario';

  @override
  String get calExportNewCalendar => 'Crear el calendario «Cuadrante»';

  @override
  String get calExportNewCalendarHelp =>
      'Así puedes ocultarlo o borrarlo entero cuando quieras.';

  @override
  String get calExportRangeLabel => 'Fechas';

  @override
  String get calExportFrom => 'Desde';

  @override
  String get calExportTo => 'Hasta';

  @override
  String get calExportIncludeRest => 'Incluir los días libres';

  @override
  String get calExportIncludeRestHelp =>
      'Libre y Saliente también se añaden, como eventos de todo el día.';

  @override
  String get calExportIncludeAbsences => 'Incluir ausencias';

  @override
  String get calExportIncludeAbsencesHelp =>
      'Vacaciones, bajas y otras ausencias. Se añadirían a ese calendario y a la cuenta con la que se sincronice.';

  @override
  String calExportSynced(String account) {
    return 'Este calendario se sincroniza con $account: tus turnos se verán allí.';
  }

  @override
  String get calExportSyncedUnnamed =>
      'Este calendario se sincroniza con una cuenta: tus turnos se verán allí.';

  @override
  String calExportPlanAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se añadirán $count eventos.',
      one: 'Se añadirá 1 evento.',
    );
    return '$_temp0';
  }

  @override
  String calExportPlanReplace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se sustituirán $count eventos de una exportación anterior.',
      one: 'Se sustituirá 1 evento de una exportación anterior.',
    );
    return '$_temp0';
  }

  @override
  String calExportPlanRemove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se quitarán $count eventos de una exportación anterior.',
      one: 'Se quitará 1 evento de una exportación anterior.',
    );
    return '$_temp0';
  }

  @override
  String calExportPlanSame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos ya están al día.',
      one: '1 evento ya está al día.',
    );
    return '$_temp0';
  }

  @override
  String get calExportPlanNothing =>
      'Todo está al día: no hay nada que cambiar.';

  @override
  String get calExportPlanNone => 'No hay turnos en esas fechas.';

  @override
  String get calExportButton => 'Exportar';

  @override
  String calExportRunning(int done, int total) {
    return 'Exportando… $done de $total';
  }

  @override
  String get calExportDoneTitle => 'Exportación hecha';

  @override
  String get calExportDoneCalendar => 'Se ha creado el calendario «Cuadrante».';

  @override
  String calExportDoneCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos añadidos',
      one: '1 evento añadido',
    );
    return '$_temp0';
  }

  @override
  String calExportDoneReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos anteriores sustituidos',
      one: '1 evento anterior sustituido',
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
      other: '$count eventos ya estaban al día',
      one: '1 evento ya estaba al día',
    );
    return '$_temp0';
  }

  @override
  String calExportDoneFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count eventos no se han podido escribir. Vuelve a exportar para completarlos.',
      one: '1 evento no se ha podido escribir. Vuelve a exportar para completarlo.',
    );
    return '$_temp0';
  }

  @override
  String get calExportProblemPermission =>
      'Sin el permiso no podemos escribir en tu calendario.';

  @override
  String get calExportProblemUnavailable =>
      'Este móvil no tiene calendarios disponibles.';

  @override
  String get calExportProblemFailed =>
      'No se ha podido exportar. Prueba otra vez.';

  @override
  String get calExportRangeClamped =>
      'El máximo es un año: se ha recortado el final.';

  @override
  String get onboardingImportButton => 'Importar ahora';

  @override
  String get onboardingImportLrhsoftButton => 'Importar copia de LRHSoft';

  @override
  String get backupUiRowSubtitle => 'Automática, exportar e importar';

  @override
  String get backupUiStatusNoneTitle => 'Todavía no hay ninguna copia';

  @override
  String get backupUiStatusNoneBody =>
      'Haz una ahora: tarda un segundo. Mientras no la tengas, si pierdes el dispositivo o desinstalas la app se pierde tu cuadrante.';

  @override
  String get backupUiStatusLast => 'Última copia';

  @override
  String get backupUiStatusWhere => 'En este dispositivo';

  @override
  String get backupUiStatusRunning => 'Guardando la copia…';

  @override
  String get backupUiStatusPending =>
      'Hay cambios nuevos: la copia se hará en unos segundos.';

  @override
  String backupUiStatusPendingAt(String time) {
    return 'Hay cambios nuevos: la próxima copia se hará hacia las $time. Si no quieres esperar, pulsa «Hacer copia ahora».';
  }

  @override
  String get backupUiStatusPendingLater =>
      'Hay cambios nuevos: la próxima copia se hará en unos minutos. Si no quieres esperar, pulsa «Hacer copia ahora».';

  @override
  String get backupUiStatusFailedTitle =>
      'La última copia automática ha fallado';

  @override
  String backupUiStatusFailedWithGood(String when, String good) {
    return 'Lo intentamos $when y no se pudo guardar. Tu última copia buena es de $good.';
  }

  @override
  String backupUiStatusFailedNoGood(String when) {
    return 'Lo intentamos $when y no se pudo guardar. Todavía no tienes ninguna copia buena.';
  }

  @override
  String get backupUiFailDiskFull => 'El dispositivo no tiene espacio libre.';

  @override
  String get backupUiFailGeneric =>
      'No se pudo escribir el archivo de la copia.';

  @override
  String get backupUiRetry => 'Reintentar';

  @override
  String get backupUiSystemOn => 'Copia del sistema de Android: activada';

  @override
  String get backupUiSystemOff =>
      'Copia del sistema de Android: desactivada. Actívala en los ajustes de Android para tener otra copia.';

  @override
  String get backupUiSystemUnknown =>
      'Copia del sistema de Android: no podemos comprobarla desde la app. Mira en los ajustes de Android que esté activada.';

  @override
  String get backupUiWarning =>
      'Estas copias se guardan en este dispositivo. Si desinstalas la app sin otra copia, se pierde. Exporta un archivo y guárdalo en Drive o envíalo por WhatsApp o correo.';

  @override
  String get backupUiBackupNow => 'Hacer copia ahora';

  @override
  String get backupUiBackupDone => 'Copia hecha';

  @override
  String get backupUiBackupFailed =>
      'No se ha podido hacer la copia. Tus datos siguen como estaban.';

  @override
  String get backupUiAutoTitle => 'Copias automáticas';

  @override
  String get backupUiAutoOn =>
      'Después de cambiar algo, sin que lo notes. Guardamos las 7 últimas y una por día durante 30 días.';

  @override
  String get backupUiAutoOff =>
      'Desactivadas: solo se copia cuando tú lo pides.';

  @override
  String get backupUiSectionFile => 'Archivo';

  @override
  String get backupUiSectionCheck => 'Comprobar';

  @override
  String get backupUiSectionCopies => 'Copias en este dispositivo';

  @override
  String get backupUiExport => 'Exportar archivo';

  @override
  String get backupUiExportSubtitle =>
      'Para guardarlo en Drive o mandarlo por WhatsApp o correo';

  @override
  String get backupUiExportFailed => 'No se ha podido exportar el archivo.';

  @override
  String get backupUiSave => 'Guardar en el dispositivo';

  @override
  String get backupUiSaveSubtitle => 'Elige una carpeta, por ejemplo Descargas';

  @override
  String get backupUiSaveDone => 'Archivo guardado';

  @override
  String get backupUiSaveFailed =>
      'No se ha podido guardar el archivo. Prueba con otra carpeta o usa «Exportar archivo».';

  @override
  String get backupUiImport => 'Importar archivo';

  @override
  String get backupUiImportSubtitle => 'Recupera un archivo de Cuadrante';

  @override
  String get backupUiVerify => 'Probar restauración';

  @override
  String get backupUiVerifySubtitle =>
      'Comprueba que tu última copia se puede recuperar entera';

  @override
  String get backupUiVerifyRunning => 'Comprobando la copia…';

  @override
  String get backupUiVerifyNone =>
      'Todavía no hay ninguna copia que probar. Haz una primero.';

  @override
  String backupUiVerifyOk(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'La copia está completa: $days días comprobados',
      one: 'La copia está completa: 1 día comprobado',
    );
    return '$_temp0';
  }

  @override
  String get backupUiVerifySame => 'Es idéntica a lo que tienes ahora.';

  @override
  String backupUiVerifyOlder(String day) {
    return 'Es anterior a lo que tienes ahora (el primer día que cambia es $day). Es normal si has hecho cambios después.';
  }

  @override
  String get backupUiVerifyOlderNoDay =>
      'Es anterior a lo que tienes ahora. Es normal si has hecho cambios después.';

  @override
  String backupUiVerifyMismatch(String day) {
    return 'La copia no se reconstruye igual. Primer día distinto: $day. Haz una copia nueva y avísanos.';
  }

  @override
  String get backupUiVerifyMismatchNoDay =>
      'La copia no se reconstruye igual: los datos guardados no coinciden. Haz una copia nueva y avísanos.';

  @override
  String backupUiVerifyError(String reason) {
    return 'No se ha podido probar la copia. $reason';
  }

  @override
  String get backupUiCopiesEmpty => 'Aquí aparecerán tus copias.';

  @override
  String get backupUiCopyLocal => 'Copia del dispositivo';

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
    return 'Restaurar la copia del $when';
  }

  @override
  String backupUiWhenToday(String time) {
    return 'hoy a las $time';
  }

  @override
  String backupUiWhenYesterday(String time) {
    return 'ayer a las $time';
  }

  @override
  String backupUiWhenDate(String date, String time) {
    return 'el $date a las $time';
  }

  @override
  String get backupUiPreviewTitle => 'Restaurar copia';

  @override
  String get backupUiPreviewReading => 'Leyendo el archivo…';

  @override
  String get backupUiOriginFile => 'Archivo que has elegido';

  @override
  String get backupUiOriginShared => 'Archivo recibido de otra app';

  @override
  String get backupUiOriginLocal => 'Copia de este dispositivo';

  @override
  String get backupUiOriginSafety => 'Copia de justo antes de restaurar';

  @override
  String get backupUiOriginCloud => 'Copia en iCloud';

  @override
  String backupUiPreviewSaved(String when) {
    return 'Guardada $when';
  }

  @override
  String backupUiPreviewSender(String sender) {
    return 'Enviado desde $sender';
  }

  @override
  String get backupUiPreviewSenderHint =>
      'Lo indica el dispositivo. Si no esperabas este archivo, cancela.';

  @override
  String get backupUiPreviewTurnsOffTitle =>
      'Esta copia apaga ajustes que tienes encendidos';

  @override
  String get backupUiPreviewTurnsOffAuto => 'Desactiva las copias automáticas.';

  @override
  String get backupUiPreviewTurnsOffAlarms => 'Desactiva las alarmas de turno.';

  @override
  String get backupUiPreviewContains => 'Qué trae';

  @override
  String backupUiPreviewNow(String value) {
    return 'Ahora: $value';
  }

  @override
  String get backupUiPreviewCalendars => 'Calendarios';

  @override
  String backupUiPreviewArchived(String name) {
    return '$name (archivado)';
  }

  @override
  String get backupUiPreviewDays => 'Días con turno o nota puestos a mano';

  @override
  String get backupUiPreviewRuns => 'Rotaciones';

  @override
  String get backupUiPreviewTypes => 'Tipos de turno';

  @override
  String get backupUiPreviewRange => 'Fechas';

  @override
  String backupUiPreviewRangeValue(String from, String to) {
    return 'Del $from al $to';
  }

  @override
  String backupUiPreviewRangeOpen(String from, String to) {
    return 'Del $from al $to, y una rotación sigue después';
  }

  @override
  String get backupUiPreviewRangeNone => 'Sin fechas';

  @override
  String get backupUiPreviewReplace =>
      'Esto sustituye lo que tienes ahora; antes guardamos una copia.';

  @override
  String get backupUiPreviewConfirm => 'Sustituir lo que tengo';

  @override
  String get backupUiPreviewCancel => 'Cancelar';

  @override
  String get backupUiRestoring => 'Restaurando tu cuadrante…';

  @override
  String get backupUiRestoringHint => 'No cierres la app.';

  @override
  String get backupUiDoneTitle => 'Listo, tu cuadrante está restaurado';

  @override
  String get backupUiDoneBody =>
      'Antes de cambiar nada guardamos lo que tenías. Si no era lo que esperabas, puedes volver atrás.';

  @override
  String get backupUiDoneView => 'Ver mi calendario';

  @override
  String get backupUiDoneUndo => 'Volver a como estaba';

  @override
  String get backupUiErrorNotOurs =>
      'Este archivo no es una copia de Cuadrante.';

  @override
  String get backupUiErrorNewer =>
      'Este archivo es de una versión más nueva de Cuadrante: actualiza la app.';

  @override
  String get backupUiErrorCorrupt =>
      'El archivo está dañado o incompleto y no se puede usar.';

  @override
  String get backupUiErrorTooLarge =>
      'Este archivo es demasiado grande para ser una copia de Cuadrante.';

  @override
  String get backupUiErrorUnreadable => 'No se ha podido leer el archivo.';

  @override
  String get backupUiErrorUntouched =>
      'No hemos cambiado nada: tus datos siguen como estaban.';

  @override
  String get backupUiErrorRestoreFailed =>
      'No se ha podido restaurar. Tus datos siguen como estaban.';

  @override
  String get backupUiErrorRestoreReload =>
      'Hemos restaurado tus datos, pero la pantalla no se ha podido actualizar. Cierra Cuadrante y vuelve a abrirlo.';

  @override
  String get backupUiBack => 'Volver';

  @override
  String get widgetWeekdaysShort => 'lun,mar,mié,jue,vie,sáb,dom';

  @override
  String get widgetWeekdayHeaders => 'L,M,X,J,V,S,D';

  @override
  String get widgetMonthNames =>
      'enero,febrero,marzo,abril,mayo,junio,julio,agosto,septiembre,octubre,noviembre,diciembre';

  @override
  String get widgetTomorrow => 'Mañana';

  @override
  String get widgetEmptyCircular => '–';

  @override
  String get widgetStaleTitle => 'Cuadrante';

  @override
  String get widgetStaleBody => 'Abre Cuadrante para seguir al día';

  @override
  String get widgetAddTitle => 'Añadir widget';

  @override
  String get widgetAddSubtitle => 'Tu turno de hoy en la pantalla de inicio';

  @override
  String get widgetAddBody =>
      'El widget siempre muestra el día de hoy, aunque no abras la app.';

  @override
  String get widgetAddSmall => 'Pequeño: hoy y mañana';

  @override
  String get widgetAddMedium => 'Mediano: los próximos 7 días';

  @override
  String get widgetAddLarge => 'Grande: el mes entero';

  @override
  String get widgetAddAgenda => 'Agenda: próximos turnos';

  @override
  String get widgetAddTwoWeeks => 'Dos semanas: actual y siguiente';

  @override
  String get widgetAddManualAndroid =>
      'Mantén pulsada una zona vacía de la pantalla de inicio, elige Widgets y busca Cuadrante.';

  @override
  String get widgetAddManualIos =>
      'Mantén pulsada la pantalla de inicio, toca el + de arriba y busca Cuadrante.';

  @override
  String get compareTitle => 'Comparar calendarios';

  @override
  String get compareOpen => 'Comparar calendarios';

  @override
  String get compareOpenSubtitle => 'Mira cuándo coincidís libres';

  @override
  String get compareSwap => 'Intercambiar';

  @override
  String get compareIntro =>
      'Elige dos calendarios y mira sus turnos juntos. Los días libres de los dos se marcan.';

  @override
  String get compareFirstLabel => 'Primer calendario';

  @override
  String get compareSecondLabel => 'Segundo calendario';

  @override
  String get comparePickTitle => 'Elige un calendario';

  @override
  String get compareNeedTwoTitle => 'Necesitas dos calendarios';

  @override
  String get compareNeedTwoBody =>
      'Crea otro calendario (tu pareja, un segundo trabajo) para ver cuándo coincidís libres.';

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
  String get compareLegendFree => 'Libres los dos';

  @override
  String get compareNote =>
      'Cuenta como libre un día sin turno de trabajo: vacío, libre o con una ausencia (vacaciones, baja…). Cada turno cuenta en el día en que empieza.';

  @override
  String get compareNoShiftMark => '–';

  @override
  String get compareBothFree => 'libres los dos';

  @override
  String compareCellCalendar(String calendar, String shifts) {
    return '$calendar: $shifts';
  }

  @override
  String get compareLoadFailed => 'No se han podido leer los calendarios.';

  @override
  String get calendarsTitle => 'Calendarios';

  @override
  String get calendarsIntro =>
      'Cada calendario tiene su propio cuadrante: el tuyo, el de tu pareja, un segundo trabajo. Los tipos de turno son los mismos en todos.';

  @override
  String get calendarsActiveBadge => 'Activo';

  @override
  String get calendarsPrimaryBadge => 'Widget y alarmas';

  @override
  String get calendarsAdd => 'Nuevo calendario';

  @override
  String get calendarsNewTitle => 'Nuevo calendario';

  @override
  String get calendarsEditTitle => 'Editar calendario';

  @override
  String get calendarsNameLabel => 'Nombre';

  @override
  String get calendarsNameHint => 'Pareja, segundo trabajo…';

  @override
  String get calendarsColorLabel => 'Color';

  @override
  String calendarsColorOption(int index) {
    return 'Color $index';
  }

  @override
  String get calendarsCreate => 'Crear';

  @override
  String get calendarsMakePrimary => 'Usar para widget y alarmas';

  @override
  String get calendarsPrimaryHelp =>
      'El widget y las alarmas siguen este calendario aunque estés viendo otro.';

  @override
  String get calendarsArchive => 'Archivar';

  @override
  String calendarsArchiveTitle(String name) {
    return '¿Archivar «$name»?';
  }

  @override
  String get calendarsArchiveBody =>
      'Dejará de salir en la lista, pero podrás recuperarlo desde «Archivados». Sus turnos se quedan guardados en el móvil.';

  @override
  String calendarsArchivePrimaryNote(String name) {
    return 'El widget y las alarmas pasarán a «$name».';
  }

  @override
  String calendarsArchivedSection(int count) {
    return 'Archivados ($count)';
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
      'No puedes archivar el último calendario: siempre tiene que haber uno.';

  @override
  String get calendarsNameRequired => 'Pon un nombre al calendario.';

  @override
  String get calendarsNotFoundError => 'Ese calendario ya no existe.';

  @override
  String get calendarsSaveFailed =>
      'No se ha podido guardar el calendario. Prueba otra vez.';

  @override
  String calendarsSwitcherLabel(String name) {
    return 'Calendario $name. Cambiar de calendario';
  }

  @override
  String get calendarsSwitcherTitle => 'Cambiar de calendario';

  @override
  String get calendarsSwitchFailed => 'No se ha podido cambiar de calendario.';

  @override
  String get calendarsManage => 'Gestionar calendarios';

  @override
  String get holidayImportAction => 'Traer festivos del calendario del móvil';

  @override
  String get holidayImportTitle => 'Festivos';

  @override
  String get holidayImportHelp =>
      'Solo eventos de día completo. Todo se queda en tu móvil; tu calendario no cambia.';

  @override
  String get holidayImportRangeHelp => 'De inicio, este año y el siguiente.';

  @override
  String get holidayImportSkipped => 'Ya existe · se omite';

  @override
  String get holidayImportReady => 'Se añadirá';

  @override
  String holidayImportIgnored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se omiten $count eventos con hora.',
      one: 'Se omite 1 evento con hora.',
    );
    return '$_temp0';
  }

  @override
  String holidayImportCapped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos superan 31 días: se recortan.',
      one: '1 evento supera 31 días: se recorta.',
    );
    return '$_temp0';
  }

  @override
  String holidayImportAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Añadir $count festivos',
      one: 'Añadir 1 festivo',
    );
    return '$_temp0';
  }

  @override
  String holidayImportAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count festivos añadidos',
      one: '1 festivo añadido',
    );
    return '$_temp0';
  }

  @override
  String get holidayImportEmpty => 'No hay festivos nuevos.';

  @override
  String get holidayImportPreviewHelp =>
      'Las fechas que ya tienen festivo se omiten.';

  @override
  String get holidaysSettingsRegionTitle => 'Comunidad autónoma';

  @override
  String get holidaysSettingsRegionUnset => 'Sin elegir';

  @override
  String get holidaysSettingsRegionClear => 'Sin comunidad';

  @override
  String get holidaysSettingsMunicipalityTitle => 'Municipio';

  @override
  String get holidaysSettingsMunicipalityNone => 'Ninguno';

  @override
  String get holidaysSettingsMunicipalitySearch => 'Buscar municipio';

  @override
  String holidaysSettingsMunicipalityNoMatch(String query) {
    return 'Ningún municipio coincide con «$query»';
  }

  @override
  String get holidaysSettingsMunicipalityLoadFailed =>
      'No se ha podido cargar la lista de municipios.';

  @override
  String get holidaysSettingsStatusNoRegion =>
      'Sin comunidad solo salen los festivos nacionales. Elige la tuya para ver los autonómicos.';

  @override
  String get holidaysSettingsStatusNoMunicipality =>
      'Elige tu municipio para ver sus festivos locales, o añádelos tú abajo.';

  @override
  String holidaysSettingsStatusLocalIncluded(String municipality) {
    return 'Festivos locales de $municipality: incluidos';
  }

  @override
  String holidaysSettingsStatusYearPending(String year) {
    return 'Los festivos oficiales de $year llegarán con una actualización';
  }

  @override
  String get holidaysSettingsStatusLocalMissing =>
      'Todavía no tenemos los de tu municipio: añádelos tú abajo';

  @override
  String holidaysSettingsStatusLocalMissingYear(
    String municipality,
    String year,
  ) {
    return 'Todavía no tenemos los de $municipality en $year: añádelos tú abajo';
  }

  @override
  String get holidaysSettingsStatusLocalPartial =>
      'Puede que falte alguno: compruébalos.';

  @override
  String get holidaysSettingsAdd => 'Añadir festivo local';

  @override
  String get holidaysSettingsAddName => 'Nombre';

  @override
  String get holidaysSettingsAddDefaultName => 'Fiesta local';

  @override
  String holidaysSettingsEmptyYear(String year) {
    return 'Todavía no tenemos los festivos de $year.';
  }

  @override
  String get holidaysSettingsScopeNational => 'Nacional';

  @override
  String get holidaysSettingsScopeLocal => 'Local';

  @override
  String get holidaysSettingsScopeUser => 'Tuyo';

  @override
  String holidaysSettingsNoteReplaces(String name) {
    return 'Sustituye a $name';
  }

  @override
  String holidaysSettingsNoteCovered(String name) {
    return 'En tu calendario lo tapa «$name»';
  }

  @override
  String holidaysSettingsSubstitutedTitle(String region) {
    return 'No son festivo en $region';
  }

  @override
  String get holidaysSettingsSubstitutedBody =>
      'Una comunidad puede cambiar estos festivos nacionales por otros propios.';

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
    return 'Turno de $name a las $start';
  }

  @override
  String alarmBody(String name, String start, String end) {
    return '$name: de $start a $end';
  }

  @override
  String get alarmChannelName => 'Alarmas de turno';

  @override
  String get alarmChannelDescription =>
      'Te avisa antes de que empiece cada turno.';

  @override
  String alarmsNotifDayBeforeTitle(String name, String start) {
    return 'Mañana: turno de $name a las $start';
  }

  @override
  String get alarmsNotifSnooze => 'Posponer 10 min';

  @override
  String get alarmsNotifAwake => 'Ya estoy despierto';

  @override
  String get alarmsNotifTestTitle => 'Aviso de prueba';

  @override
  String get alarmsNotifTestBody =>
      'Así te avisará Cuadrante antes de tu turno.';

  @override
  String get alarmsRowOn => 'Activadas';

  @override
  String get alarmsRowOff => 'Desactivadas';

  @override
  String get alarmsMasterTitle => 'Avisar antes de cada turno';

  @override
  String get alarmsMasterHelp =>
      'Un aviso en el móvil, sin conexión y sin cuenta.';

  @override
  String get alarmsPermOkTitle => 'Todo listo';

  @override
  String get alarmsPermOkBody =>
      'Las notificaciones y las alarmas a la hora exacta están permitidas.';

  @override
  String get alarmsPermOkBodyIos => 'Las notificaciones están permitidas.';

  @override
  String get alarmsPermNotifTitle => 'Faltan las notificaciones';

  @override
  String get alarmsPermNotifBody =>
      'Sin el permiso de notificaciones, Cuadrante no puede avisarte. Si no te sale la ventana para permitirlas, actívalas en los ajustes del sistema.';

  @override
  String get alarmsPermNotifAllow => 'Permitir';

  @override
  String get alarmsPermNotifBlockedBody =>
      'Android ya no te pregunta por las notificaciones. Actívalas en los ajustes del sistema y Cuadrante podrá avisarte.';

  @override
  String get alarmsPermNotifBlockedBodyIos =>
      'iOS ya no te pregunta por las notificaciones. Actívalas en Ajustes › Cuadrante › Notificaciones y Cuadrante podrá avisarte.';

  @override
  String get alarmsPermNotifOpenSettings => 'Abrir ajustes';

  @override
  String get alarmsPermExactTitle => 'Alarmas y recordatorios';

  @override
  String get alarmsPermExactBody =>
      'Las alarmas pueden llegar con unos minutos de retraso. Para que suenen a la hora exacta, permite «Alarmas y recordatorios» en los ajustes del sistema.';

  @override
  String get alarmsPermExactOpen => 'Abrir ajustes';

  @override
  String get alarmsSectionTypes => 'Tipos de turno';

  @override
  String get alarmsTypesEmpty =>
      'Ninguno de tus turnos tiene horario. Ponle hora en Mis turnos para que Cuadrante pueda avisarte.';

  @override
  String get alarmsBeforeTitle => 'Antes del turno';

  @override
  String get alarmsBeforeAtStart => 'Al empezar';

  @override
  String get alarmsBeforeSheetTitle => 'Cuánto antes del turno';

  @override
  String get alarmsBeforeCustom => 'Personalizado';

  @override
  String get alarmsBeforeCustomTitle => 'Antelación personalizada';

  @override
  String get alarmsBeforeCustomHelp =>
      'Horas y minutos antes de que empiece el turno.';

  @override
  String get alarmsBeforeCustomApply => 'Guardar';

  @override
  String get alarmsSecondSegmentTitle =>
      'Avisar también antes del segundo tramo';

  @override
  String get alarmsSecondSegmentHelper =>
      'Un segundo aviso, con la misma antelación, antes de volver al trabajo.';

  @override
  String get alarmsDayBeforeTitle => 'Aviso el día anterior';

  @override
  String alarmsDayBeforeAt(String time) {
    return 'A las $time';
  }

  @override
  String get alarmsDayBeforeTimeTitle => 'Hora del aviso';

  @override
  String get alarmsLabelTitle => 'Texto del aviso';

  @override
  String get alarmsLabelDefault => 'El de siempre';

  @override
  String get alarmsLabelHint => 'Por ejemplo: A trabajar';

  @override
  String get alarmsLabelApply => 'Guardar';

  @override
  String get alarmsLabelReset => 'Usar el de siempre';

  @override
  String get alarmsTestButton => 'Probar aviso';

  @override
  String get alarmsTestScheduled => 'Te avisaremos en 10 segundos.';

  @override
  String get alarmsTestDenied =>
      'Sin el permiso de notificaciones no podemos probar el aviso.';

  @override
  String alarmsNextLine(String when, String shift) {
    return 'Próximo aviso: $when · $shift';
  }

  @override
  String alarmsNextLineDayBefore(String when, String shift) {
    return 'Próximo aviso: $when · $shift, el día anterior';
  }

  @override
  String alarmsNextWhen(String weekday, int day, String month, String time) {
    return '$weekday $day de $month, $time';
  }

  @override
  String get alarmsNextNone =>
      'No hay ningún aviso previsto en los próximos días.';

  @override
  String get alarmsNextOff => 'Las alarmas están desactivadas.';

  @override
  String get alarmsSkipDay => 'Sin alarma este día';

  @override
  String get alarmsReminderTitle => 'Recordatorio';

  @override
  String get alarmsReminderEmptyBody => 'Tienes un recordatorio para hoy';

  @override
  String get alarmsReminderChannelName => 'Recordatorios de notas';

  @override
  String get alarmsReminderChannelDescription =>
      'Te avisa a la hora que elijas en la nota de un día.';

  @override
  String get dayReminderAdd => 'Avisarme';

  @override
  String dayReminderAt(String time) {
    return 'Aviso a las $time';
  }

  @override
  String get dayReminderChange => 'Cambiar la hora del aviso';

  @override
  String get dayReminderRemove => 'Quitar aviso';

  @override
  String get dayReminderRemoved => 'Aviso quitado';

  @override
  String get dayReminderPickHelp => 'Hora del aviso';

  @override
  String get dayReminderPast => 'Esa hora ya pasó: no sonará.';

  @override
  String get dayReminderNoPermission =>
      'Las notificaciones están desactivadas, así que el aviso no sonará. Actívalas en los ajustes del móvil.';

  @override
  String get dayReminderOnlyPrimary =>
      'Solo suenan los avisos del calendario principal.';

  @override
  String agendaSemanticsReminder(String time) {
    return 'aviso a las $time';
  }

  @override
  String get shiftTypesAlarmSection => 'Alarma';

  @override
  String get shiftTypesSoundLabel => 'Sonido';

  @override
  String get shiftTypesSoundHelper =>
      'Suena con el volumen de las alarmas, cuando actives la alarma de este turno en Ajustes.';

  @override
  String get shiftTypesSoundDefault => 'Predeterminado';

  @override
  String get shiftTypesSoundCustom => 'Sonido del móvil';

  @override
  String get shiftTypesSoundMissing => 'No disponible: suena el predeterminado';

  @override
  String get shiftTypesSoundReset => 'Usar el predeterminado';

  @override
  String get catalogShiftMorningName => 'Mañana';

  @override
  String get catalogShiftMorningCode => 'M';

  @override
  String get catalogShiftAfternoonName => 'Tarde';

  @override
  String get catalogShiftAfternoonCode => 'T';

  @override
  String get catalogShiftNightName => 'Noche';

  @override
  String get catalogShiftNightCode => 'N';

  @override
  String get catalogShiftRestName => 'Libre';

  @override
  String get catalogShiftRestCode => 'L';

  @override
  String get catalogShiftGuard24Name => 'Guardia 24 h';

  @override
  String get catalogShiftGuard24Code => 'G';

  @override
  String get catalogShiftPostNightName => 'Saliente';

  @override
  String get catalogShiftPostNightCode => 'S';

  @override
  String get catalogShiftVacationName => 'Vacaciones';

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
  String get catalogShiftNight12Name => 'Noche 12 h';

  @override
  String get catalogShiftNight12Code => 'N12';

  @override
  String get catalogShiftSplitName => 'Partido';

  @override
  String get catalogShiftSplitCode => 'P';

  @override
  String get catalogPatternCorreturnosName => 'Correturnos';

  @override
  String get catalogPatternCorreturnosDescription =>
      '5 mañanas, 2 libres, 5 tardes, 2 libres, 5 noches, 2 libres';

  @override
  String get catalogPattern24x72Name => '24 x 72';

  @override
  String get catalogPattern24x72Description => 'Guardia de 24 h y 72 h libres';

  @override
  String get catalogPattern12hName => '12 horas';

  @override
  String get catalogPattern12hDescription =>
      'Día 12 h, noche 12 h, saliente y libre';

  @override
  String get catalogPattern6x4Name => '6 x 4';

  @override
  String get catalogPattern6x4Description => '6 mañanas y 4 libres';

  @override
  String get catalogPattern4x4Name => '4 x 4';

  @override
  String get catalogPattern4x4Description => '4 días de 12 h y 4 libres';

  @override
  String get catalogPattern5x2Name => '5 x 2';

  @override
  String get catalogPattern5x2Description =>
      '5 mañanas y 2 libres (lunes a viernes)';

  @override
  String get catalogPattern223Name => '2-2-3';

  @override
  String get catalogPattern223Description =>
      'Dos días de 12 h, dos libres, tres de 12 h, dos libres, dos de 12 h y tres libres (también 2-2-3-2-2-3)';

  @override
  String get catalogPatternContinentalName => 'Continental';

  @override
  String get catalogPatternContinentalDescription =>
      'Turno continuo de 28 días con 4 equipos: bloques de 2 y 3 mañanas, tardes y noches, y 7 libres';

  @override
  String get catalogPatternDupontName => 'DuPont';

  @override
  String get catalogPatternDupontDescription =>
      'Ciclo de 28 días en turnos de 12 h: 4 noches, 3 libres, 3 días, 1 libre, 3 noches, 3 libres, 4 días y 7 libres';

  @override
  String get holidayNameNewYear => 'Año Nuevo';

  @override
  String get holidayNameEpiphany => 'Epifanía del Señor';

  @override
  String get holidayNameMaundyThursday => 'Jueves Santo';

  @override
  String get holidayNameGoodFriday => 'Viernes Santo';

  @override
  String get holidayNameEasterMonday => 'Lunes de Pascua';

  @override
  String get holidayNameLabourDay => 'Fiesta del Trabajo';

  @override
  String get holidayNameAssumption => 'Asunción de la Virgen';

  @override
  String get holidayNameNationalDay => 'Fiesta Nacional de España';

  @override
  String get holidayNameAllSaints => 'Todos los Santos';

  @override
  String get holidayNameConstitution => 'Día de la Constitución Española';

  @override
  String get holidayNameImmaculate => 'Inmaculada Concepción';

  @override
  String get holidayNameChristmas => 'Natividad del Señor';

  @override
  String get holidayNameStStephen => 'San Esteban';

  @override
  String get holidayNameStJoseph => 'San José';

  @override
  String get holidayNameStJames => 'Santiago Apóstol';

  @override
  String get holidayNameGaliciaDay => 'Día de Galicia';

  @override
  String get holidayNameStJamesGalicia =>
      'Santiago Apóstol / Día Nacional de Galicia';

  @override
  String get holidayNameCataloniaDay => 'Diada Nacional de Cataluña';

  @override
  String get holidayNameBasqueDay => 'Día del País Vasco';

  @override
  String get catalogCalendarMainName => 'Mi cuadrante';

  @override
  String get historyUndone => 'Cambio deshecho';

  @override
  String get historyRedone => 'Cambio rehecho';

  @override
  String get historyNothingToUndo => 'Nada que deshacer';

  @override
  String get historyNothingToRedo => 'Nada que rehacer';

  @override
  String get monthPresentationGrid => 'Cuadrícula';

  @override
  String get monthPresentationList => 'Lista';

  @override
  String get monthSelectDays => 'Seleccionar días';

  @override
  String get monthSelectDay => 'Toca para elegir este día';

  @override
  String get monthListRecommended =>
      'Lista recomendada para ver los horarios completos y el texto grande.';

  @override
  String get monthListSelected => 'Presentación de lista';

  @override
  String get monthGridSelected => 'Presentación de cuadrícula';
}
