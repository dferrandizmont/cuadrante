import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_eu.dart';
import 'app_localizations_gl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ca'),
    Locale('en'),
    Locale('es'),
    Locale('eu'),
    Locale('gl'),
  ];

  /// Nombre de la app (título de ventana y cabeceras).
  ///
  /// In es, this message translates to:
  /// **'Cuadrante'**
  String get appName;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @undo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In es, this message translates to:
  /// **'Rehacer'**
  String get redo;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get back;

  /// No description provided for @loadingLabel.
  ///
  /// In es, this message translates to:
  /// **'Cargando'**
  String get loadingLabel;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Algo no ha ido bien. Prueba otra vez.'**
  String get errorGeneric;

  /// No description provided for @calendarToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get calendarToday;

  /// Lectura del título del mes en la pantalla del mes, que es un botón: abre la vista del año para elegir otro.
  ///
  /// In es, this message translates to:
  /// **'{month}, elegir mes'**
  String calendarPickMonth(String month);

  /// No description provided for @calendarPreviousMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes anterior'**
  String get calendarPreviousMonth;

  /// No description provided for @calendarNextMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes siguiente'**
  String get calendarNextMonth;

  /// Última línea de la tarjeta de hoy, con la fecha del día siguiente para no confundir «mañana» con un turno llamado Mañana, p. ej. «Mañana (mié 21 oct): turno de Noche».
  ///
  /// In es, this message translates to:
  /// **'Mañana ({date}): turno de {shifts}'**
  String calendarHeaderTomorrow(String date, String shifts);

  /// Última línea de la tarjeta de hoy cuando el día siguiente no tiene turno.
  ///
  /// In es, this message translates to:
  /// **'Mañana ({date}): sin turno'**
  String calendarHeaderTomorrowNone(String date);

  /// Etiqueta de la tarjeta de hoy con un turno en curso (se muestra en mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'Ahora'**
  String get todayLabelNow;

  /// Etiqueta cuando el próximo turno de hoy empieza a partir de las 20:00.
  ///
  /// In es, this message translates to:
  /// **'Esta noche'**
  String get todayLabelTonight;

  /// Etiqueta cuando el próximo turno de hoy empieza antes de las 20:00.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get todayLabelToday;

  /// Etiqueta cuando hoy no queda turno.
  ///
  /// In es, this message translates to:
  /// **'Hoy libre'**
  String get todayLabelFree;

  /// Etiqueta de la tarjeta de hoy cuando el turno de hoy ya ha terminado y no queda otro hoy (se muestra en mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'Hoy terminado'**
  String get todayLabelDone;

  /// Hora a la que terminó el último turno de hoy, p. ej. «Terminó a las 22:00».
  ///
  /// In es, this message translates to:
  /// **'Terminó a las {time}'**
  String todayFinishedAt(String time);

  /// Etiqueta de la tarjeta de hoy entre los dos tramos de un turno partido (se muestra en mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get todayLabelGap;

  /// Entre los dos tramos de un turno partido: hora a la que empieza el segundo, p. ej. «Vuelves a las 17:00».
  ///
  /// In es, this message translates to:
  /// **'Vuelves a las {time}'**
  String todayBackAt(String time);

  /// Cuenta atrás hasta el segundo tramo de un turno partido, p. ej. «Vuelves en 2 h 10 min».
  ///
  /// In es, this message translates to:
  /// **'Vuelves en {duration}'**
  String todayBackIn(String duration);

  /// No description provided for @todayFreeTitle.
  ///
  /// In es, this message translates to:
  /// **'Libre'**
  String get todayFreeTitle;

  /// Fin del turno en curso, p. ej. «Hasta las 06:00».
  ///
  /// In es, this message translates to:
  /// **'Hasta las {time}'**
  String todayUntil(String time);

  /// Cuenta atrás hasta el inicio del turno, p. ej. «Empieza en 3 h 40 min».
  ///
  /// In es, this message translates to:
  /// **'Empieza en {duration}'**
  String todayStartsIn(String duration);

  /// Cuenta atrás hasta el final del turno en curso.
  ///
  /// In es, this message translates to:
  /// **'Termina en {duration}'**
  String todayEndsIn(String duration);

  /// Próximo turno cuando hoy es libre, p. ej. «Próximo: Mañana, mié 06:00».
  ///
  /// In es, this message translates to:
  /// **'Próximo: {name}, {weekday} {time}'**
  String todayNext(String name, String weekday, String time);

  /// No description provided for @todayNoNext.
  ///
  /// In es, this message translates to:
  /// **'Sin turnos a la vista'**
  String get todayNoNext;

  /// Otro turno de hoy, p. ej. «+ Tarde 14:00–22:00».
  ///
  /// In es, this message translates to:
  /// **'+ {shift}'**
  String todayAlso(String shift);

  /// No description provided for @durationDaysHours.
  ///
  /// In es, this message translates to:
  /// **'{days} d {hours} h'**
  String durationDaysHours(int days, int hours);

  /// No description provided for @durationDays.
  ///
  /// In es, this message translates to:
  /// **'{days} d'**
  String durationDays(int days);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In es, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationHours.
  ///
  /// In es, this message translates to:
  /// **'{hours} h'**
  String durationHours(int hours);

  /// No description provided for @durationMinutes.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @calendarNoShift.
  ///
  /// In es, this message translates to:
  /// **'Sin turno'**
  String get calendarNoShift;

  /// Turno con su horario, p. ej. «Noche 22:00–06:00».
  ///
  /// In es, this message translates to:
  /// **'{name} {times}'**
  String calendarShiftWithTimes(String name, String times);

  /// No description provided for @calendarWeekdayMon.
  ///
  /// In es, this message translates to:
  /// **'L'**
  String get calendarWeekdayMon;

  /// No description provided for @calendarWeekdayTue.
  ///
  /// In es, this message translates to:
  /// **'M'**
  String get calendarWeekdayTue;

  /// No description provided for @calendarWeekdayWed.
  ///
  /// In es, this message translates to:
  /// **'X'**
  String get calendarWeekdayWed;

  /// No description provided for @calendarWeekdayThu.
  ///
  /// In es, this message translates to:
  /// **'J'**
  String get calendarWeekdayThu;

  /// No description provided for @calendarWeekdayFri.
  ///
  /// In es, this message translates to:
  /// **'V'**
  String get calendarWeekdayFri;

  /// No description provided for @calendarWeekdaySat.
  ///
  /// In es, this message translates to:
  /// **'S'**
  String get calendarWeekdaySat;

  /// No description provided for @calendarWeekdaySun.
  ///
  /// In es, this message translates to:
  /// **'D'**
  String get calendarWeekdaySun;

  /// No description provided for @daySemanticsToday.
  ///
  /// In es, this message translates to:
  /// **'hoy'**
  String get daySemanticsToday;

  /// No description provided for @daySemanticsNoShift.
  ///
  /// In es, this message translates to:
  /// **'sin turno'**
  String get daySemanticsNoShift;

  /// Lectura en voz alta de un turno con horario.
  ///
  /// In es, this message translates to:
  /// **'{name} de {start} a {end}'**
  String daySemanticsShift(String name, String start, String end);

  /// Lectura en voz alta de un turno partido (dos tramos).
  ///
  /// In es, this message translates to:
  /// **'{name} de {start} a {end} y de {start2} a {end2}'**
  String daySemanticsShiftSplit(
    String name,
    String start,
    String end,
    String start2,
    String end2,
  );

  /// No description provided for @daySemanticsAnd.
  ///
  /// In es, this message translates to:
  /// **'{first} y {second}'**
  String daySemanticsAnd(String first, String second);

  /// No description provided for @daySemanticsHoliday.
  ///
  /// In es, this message translates to:
  /// **'festivo: {name}'**
  String daySemanticsHoliday(String name);

  /// No description provided for @daySemanticsNote.
  ///
  /// In es, this message translates to:
  /// **'con nota'**
  String get daySemanticsNote;

  /// No description provided for @daySemanticsOvertime.
  ///
  /// In es, this message translates to:
  /// **'horas extra: {duration}'**
  String daySemanticsOvertime(String duration);

  /// No description provided for @daySemanticsEarlyLeave.
  ///
  /// In es, this message translates to:
  /// **'salida anticipada: {duration}'**
  String daySemanticsEarlyLeave(String duration);

  /// No description provided for @daySheetHoliday.
  ///
  /// In es, this message translates to:
  /// **'Festivo: {name}'**
  String daySheetHoliday(String name);

  /// No description provided for @daySheetNote.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get daySheetNote;

  /// No description provided for @daySheetEmpty.
  ///
  /// In es, this message translates to:
  /// **'Este día no tiene turno.'**
  String get daySheetEmpty;

  /// Botón de la cabecera del detalle de un día en el panel derecho (pantallas anchas): vuelve a la tarjeta de hoy y los próximos días.
  ///
  /// In es, this message translates to:
  /// **'Cerrar el día'**
  String get dayPaneClose;

  /// Título de la lista de los siguientes 7 días bajo la tarjeta de hoy, en el panel derecho de las pantallas anchas.
  ///
  /// In es, this message translates to:
  /// **'Próximos días'**
  String get upcomingTitle;

  /// No description provided for @dayDetailSourcePattern.
  ///
  /// In es, this message translates to:
  /// **'Según tu patrón'**
  String get dayDetailSourcePattern;

  /// No description provided for @dayDetailSourceOverride.
  ///
  /// In es, this message translates to:
  /// **'Cambiado a mano'**
  String get dayDetailSourceOverride;

  /// Etiqueta (se muestra en mayúsculas) de las fichas para añadir un turno a un día sin turno.
  ///
  /// In es, this message translates to:
  /// **'Añadir turno'**
  String get dayDetailAdd;

  /// Etiqueta (se muestra en mayúsculas) de las fichas para añadir un segundo turno a un día que ya tiene uno.
  ///
  /// In es, this message translates to:
  /// **'Doblar con otro turno'**
  String get dayDetailDouble;

  /// No description provided for @dayDetailReset.
  ///
  /// In es, this message translates to:
  /// **'Volver al patrón'**
  String get dayDetailReset;

  /// Lo que daría la rotación ese día, bajo «Volver al patrón», p. ej. «El patrón da: Noche 22:00–06:00».
  ///
  /// In es, this message translates to:
  /// **'El patrón da: {shifts}'**
  String dayDetailPatternGives(String shifts);

  /// No description provided for @dayDetailNoteHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe una nota para este día'**
  String get dayDetailNoteHint;

  /// No description provided for @dayDetailUserHoliday.
  ///
  /// In es, this message translates to:
  /// **'Festivo propio'**
  String get dayDetailUserHoliday;

  /// No description provided for @dayDetailUserHolidayDefault.
  ///
  /// In es, this message translates to:
  /// **'Festivo propio'**
  String get dayDetailUserHolidayDefault;

  /// No description provided for @dayDetailUserHolidayNameHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre del festivo'**
  String get dayDetailUserHolidayNameHint;

  /// No description provided for @dayDetailDuplicate.
  ///
  /// In es, this message translates to:
  /// **'Duplicar en otro día'**
  String get dayDetailDuplicate;

  /// No description provided for @dayDetailDuplicateHelp.
  ///
  /// In es, this message translates to:
  /// **'Copiar a este día'**
  String get dayDetailDuplicateHelp;

  /// Aviso tras duplicar un día, p. ej. «Copiado en jueves, 22 de octubre».
  ///
  /// In es, this message translates to:
  /// **'Copiado en {date}'**
  String dayDetailDuplicated(String date);

  /// No description provided for @dayDetailClear.
  ///
  /// In es, this message translates to:
  /// **'Borrar día'**
  String get dayDetailClear;

  /// Aviso tras «Borrar día», con la acción de deshacer.
  ///
  /// In es, this message translates to:
  /// **'Día borrado'**
  String get dayDetailCleared;

  /// No description provided for @dayDetailMoveUp.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get dayDetailMoveUp;

  /// No description provided for @dayDetailMoveDown.
  ///
  /// In es, this message translates to:
  /// **'Bajar'**
  String get dayDetailMoveDown;

  /// No description provided for @dayDetailRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar {name}'**
  String dayDetailRemove(String name);

  /// No description provided for @dayExtrasTitle.
  ///
  /// In es, this message translates to:
  /// **'Horas extra / Salí antes'**
  String get dayExtrasTitle;

  /// No description provided for @dayExtrasOvertime.
  ///
  /// In es, this message translates to:
  /// **'Horas extra'**
  String get dayExtrasOvertime;

  /// No description provided for @dayExtrasEarlyLeave.
  ///
  /// In es, this message translates to:
  /// **'Salí antes'**
  String get dayExtrasEarlyLeave;

  /// No description provided for @dayExtrasNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguna'**
  String get dayExtrasNone;

  /// No description provided for @dayExtrasHelper.
  ///
  /// In es, this message translates to:
  /// **'Suman o restan en las horas del mes y en el estimado. Con 0 se quita.'**
  String get dayExtrasHelper;

  /// No description provided for @dayExtrasMore.
  ///
  /// In es, this message translates to:
  /// **'Más {label}'**
  String dayExtrasMore(String label);

  /// No description provided for @dayExtrasLess.
  ///
  /// In es, this message translates to:
  /// **'Menos {label}'**
  String dayExtrasLess(String label);

  /// Lectura en voz alta de un contador de la sección de horas extra, p. ej. «Horas extra: 1 h 30 min».
  ///
  /// In es, this message translates to:
  /// **'{label}: {value}'**
  String dayExtrasValue(String label, String value);

  /// No description provided for @shiftTypesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis turnos'**
  String get shiftTypesTitle;

  /// No description provided for @shiftTypesEditEntry.
  ///
  /// In es, this message translates to:
  /// **'Editar turnos'**
  String get shiftTypesEditEntry;

  /// No description provided for @shiftTypesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No tienes turnos'**
  String get shiftTypesEmptyTitle;

  /// No description provided for @shiftTypesEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Crea el primero para poder pintarlo en el calendario.'**
  String get shiftTypesEmptyMessage;

  /// No description provided for @shiftTypesNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo turno'**
  String get shiftTypesNew;

  /// No description provided for @shiftTypesNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo turno'**
  String get shiftTypesNewTitle;

  /// No description provided for @shiftTypesEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar turno'**
  String get shiftTypesEditTitle;

  /// No description provided for @shiftTypesNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos este turno'**
  String get shiftTypesNotFound;

  /// No description provided for @shiftTypesNotFoundMessage.
  ///
  /// In es, this message translates to:
  /// **'Puede que lo hayas archivado. Vuelve a la lista de turnos.'**
  String get shiftTypesNotFoundMessage;

  /// No description provided for @shiftTypesArchive.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get shiftTypesArchive;

  /// No description provided for @shiftTypesArchiveTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Archivar «{name}»?'**
  String shiftTypesArchiveTitle(String name);

  /// No description provided for @shiftTypesArchiveBody.
  ///
  /// In es, this message translates to:
  /// **'Dejará de salir al pintar. Los días que ya lo usan lo seguirán mostrando.'**
  String get shiftTypesArchiveBody;

  /// No description provided for @shiftTypesArchiveConfirm.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get shiftTypesArchiveConfirm;

  /// No description provided for @shiftTypesDragHandle.
  ///
  /// In es, this message translates to:
  /// **'Arrastrar para reordenar'**
  String get shiftTypesDragHandle;

  /// Cabecera plegable, al final de Mis turnos, con los turnos archivados.
  ///
  /// In es, this message translates to:
  /// **'Archivados ({count})'**
  String shiftTypesArchivedSection(int count);

  /// No description provided for @shiftTypesArchivedHelp.
  ///
  /// In es, this message translates to:
  /// **'Dejaron de salir al pintar. Recupéralos y vuelven a la paleta.'**
  String get shiftTypesArchivedHelp;

  /// No description provided for @shiftTypesRestore.
  ///
  /// In es, this message translates to:
  /// **'Recuperar'**
  String get shiftTypesRestore;

  /// No description provided for @shiftTypesRestoreSemantic.
  ///
  /// In es, this message translates to:
  /// **'Recuperar «{name}»'**
  String shiftTypesRestoreSemantic(String name);

  /// No description provided for @shiftTypesRestored.
  ///
  /// In es, this message translates to:
  /// **'«{name}» recuperado'**
  String shiftTypesRestored(String name);

  /// No description provided for @shiftTypesDiscardTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar los cambios?'**
  String get shiftTypesDiscardTitle;

  /// No description provided for @shiftTypesDiscardBody.
  ///
  /// In es, this message translates to:
  /// **'Lo que has cambiado en este turno no se guardará.'**
  String get shiftTypesDiscardBody;

  /// No description provided for @shiftTypesDiscardKeep.
  ///
  /// In es, this message translates to:
  /// **'Seguir editando'**
  String get shiftTypesDiscardKeep;

  /// No description provided for @shiftTypesDiscardConfirm.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get shiftTypesDiscardConfirm;

  /// No description provided for @shiftTypesNoTimes.
  ///
  /// In es, this message translates to:
  /// **'Sin horario'**
  String get shiftTypesNoTimes;

  /// Precio por hora de un turno en la lista, p. ej. «12,50 €/h».
  ///
  /// In es, this message translates to:
  /// **'{rate}/h'**
  String shiftTypesRatePerHour(String rate);

  /// Plus fijo en la lista de turnos, p. ej. «+30,00 € por turno».
  ///
  /// In es, this message translates to:
  /// **'+{amount} por turno'**
  String shiftTypesFixedPlusPerShift(String amount);

  /// No description provided for @shiftTypesCategoryWork.
  ///
  /// In es, this message translates to:
  /// **'Trabajo'**
  String get shiftTypesCategoryWork;

  /// No description provided for @shiftTypesCategoryRest.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get shiftTypesCategoryRest;

  /// No description provided for @shiftTypesCategoryAbsence.
  ///
  /// In es, this message translates to:
  /// **'Ausencia'**
  String get shiftTypesCategoryAbsence;

  /// No description provided for @shiftTypesNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get shiftTypesNameLabel;

  /// No description provided for @shiftTypesCodeLabel.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get shiftTypesCodeLabel;

  /// No description provided for @shiftTypesCodeHelper.
  ///
  /// In es, this message translates to:
  /// **'De 1 a 3 caracteres. Es lo que se ve en cada casilla del mes.'**
  String get shiftTypesCodeHelper;

  /// No description provided for @shiftTypesColorLabel.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get shiftTypesColorLabel;

  /// No description provided for @shiftTypesColorOption.
  ///
  /// In es, this message translates to:
  /// **'Color {number} de {total}'**
  String shiftTypesColorOption(int number, int total);

  /// Etiqueta de lectura de un color de la rejilla: su nombre y su puesto.
  ///
  /// In es, this message translates to:
  /// **'{name}, {number} de {total}'**
  String shiftTypesColorOptionNamed(String name, int number, int total);

  /// No description provided for @shiftColorNameOrange.
  ///
  /// In es, this message translates to:
  /// **'Naranja'**
  String get shiftColorNameOrange;

  /// No description provided for @shiftColorNameCoral.
  ///
  /// In es, this message translates to:
  /// **'Coral'**
  String get shiftColorNameCoral;

  /// No description provided for @shiftColorNameIndigo.
  ///
  /// In es, this message translates to:
  /// **'Índigo'**
  String get shiftColorNameIndigo;

  /// No description provided for @shiftColorNameLightGrey.
  ///
  /// In es, this message translates to:
  /// **'Gris claro'**
  String get shiftColorNameLightGrey;

  /// No description provided for @shiftColorNameRed.
  ///
  /// In es, this message translates to:
  /// **'Rojo'**
  String get shiftColorNameRed;

  /// No description provided for @shiftColorNameLilac.
  ///
  /// In es, this message translates to:
  /// **'Lila'**
  String get shiftColorNameLilac;

  /// No description provided for @shiftColorNameGreen.
  ///
  /// In es, this message translates to:
  /// **'Verde'**
  String get shiftColorNameGreen;

  /// No description provided for @shiftColorNameTeal.
  ///
  /// In es, this message translates to:
  /// **'Turquesa'**
  String get shiftColorNameTeal;

  /// No description provided for @shiftColorNameRaspberry.
  ///
  /// In es, this message translates to:
  /// **'Frambuesa'**
  String get shiftColorNameRaspberry;

  /// No description provided for @shiftColorNamePink.
  ///
  /// In es, this message translates to:
  /// **'Rosa'**
  String get shiftColorNamePink;

  /// No description provided for @shiftColorNameTangerine.
  ///
  /// In es, this message translates to:
  /// **'Mandarina'**
  String get shiftColorNameTangerine;

  /// No description provided for @shiftColorNameYellow.
  ///
  /// In es, this message translates to:
  /// **'Amarillo'**
  String get shiftColorNameYellow;

  /// No description provided for @shiftColorNameLime.
  ///
  /// In es, this message translates to:
  /// **'Lima'**
  String get shiftColorNameLime;

  /// No description provided for @shiftColorNameForest.
  ///
  /// In es, this message translates to:
  /// **'Verde bosque'**
  String get shiftColorNameForest;

  /// No description provided for @shiftColorNameMint.
  ///
  /// In es, this message translates to:
  /// **'Menta'**
  String get shiftColorNameMint;

  /// No description provided for @shiftColorNameCyan.
  ///
  /// In es, this message translates to:
  /// **'Cian'**
  String get shiftColorNameCyan;

  /// No description provided for @shiftColorNameSkyBlue.
  ///
  /// In es, this message translates to:
  /// **'Azul cielo'**
  String get shiftColorNameSkyBlue;

  /// No description provided for @shiftColorNameBlue.
  ///
  /// In es, this message translates to:
  /// **'Azul'**
  String get shiftColorNameBlue;

  /// No description provided for @shiftColorNameCobalt.
  ///
  /// In es, this message translates to:
  /// **'Cobalto'**
  String get shiftColorNameCobalt;

  /// No description provided for @shiftColorNameViolet.
  ///
  /// In es, this message translates to:
  /// **'Violeta'**
  String get shiftColorNameViolet;

  /// No description provided for @shiftColorNamePurple.
  ///
  /// In es, this message translates to:
  /// **'Morado'**
  String get shiftColorNamePurple;

  /// No description provided for @shiftColorNameBrown.
  ///
  /// In es, this message translates to:
  /// **'Marrón'**
  String get shiftColorNameBrown;

  /// No description provided for @shiftColorNameGrey.
  ///
  /// In es, this message translates to:
  /// **'Gris'**
  String get shiftColorNameGrey;

  /// No description provided for @shiftColorNameGraphite.
  ///
  /// In es, this message translates to:
  /// **'Grafito'**
  String get shiftColorNameGraphite;

  /// No description provided for @shiftTypesColorCurrent.
  ///
  /// In es, this message translates to:
  /// **'Color actual'**
  String get shiftTypesColorCurrent;

  /// No description provided for @shiftTypesIconLabel.
  ///
  /// In es, this message translates to:
  /// **'Icono'**
  String get shiftTypesIconLabel;

  /// No description provided for @shiftTypesIconHelper.
  ///
  /// In es, this message translates to:
  /// **'Opcional. Se ve junto al código cuando hay sitio; el código y el color siempre están.'**
  String get shiftTypesIconHelper;

  /// No description provided for @shiftTypesIconNone.
  ///
  /// In es, this message translates to:
  /// **'Sin icono'**
  String get shiftTypesIconNone;

  /// No description provided for @shiftTypesIconChoose.
  ///
  /// In es, this message translates to:
  /// **'Elegir icono'**
  String get shiftTypesIconChoose;

  /// No description provided for @shiftTypesIconCurrent.
  ///
  /// In es, this message translates to:
  /// **'Icono: {name}'**
  String shiftTypesIconCurrent(String name);

  /// No description provided for @shiftIconNameSun.
  ///
  /// In es, this message translates to:
  /// **'Sol'**
  String get shiftIconNameSun;

  /// No description provided for @shiftIconNameMoon.
  ///
  /// In es, this message translates to:
  /// **'Luna'**
  String get shiftIconNameMoon;

  /// No description provided for @shiftIconNameSunrise.
  ///
  /// In es, this message translates to:
  /// **'Amanecer'**
  String get shiftIconNameSunrise;

  /// No description provided for @shiftIconNameHospital.
  ///
  /// In es, this message translates to:
  /// **'Hospital'**
  String get shiftIconNameHospital;

  /// No description provided for @shiftIconNameAmbulance.
  ///
  /// In es, this message translates to:
  /// **'Ambulancia'**
  String get shiftIconNameAmbulance;

  /// No description provided for @shiftIconNamePolice.
  ///
  /// In es, this message translates to:
  /// **'Policía'**
  String get shiftIconNamePolice;

  /// No description provided for @shiftIconNameFire.
  ///
  /// In es, this message translates to:
  /// **'Bomberos'**
  String get shiftIconNameFire;

  /// No description provided for @shiftIconNameFactory.
  ///
  /// In es, this message translates to:
  /// **'Fábrica'**
  String get shiftIconNameFactory;

  /// No description provided for @shiftIconNameTruck.
  ///
  /// In es, this message translates to:
  /// **'Camión'**
  String get shiftIconNameTruck;

  /// No description provided for @shiftIconNamePlane.
  ///
  /// In es, this message translates to:
  /// **'Avión'**
  String get shiftIconNamePlane;

  /// No description provided for @shiftIconNameSchool.
  ///
  /// In es, this message translates to:
  /// **'Colegio'**
  String get shiftIconNameSchool;

  /// No description provided for @shiftIconNameHome.
  ///
  /// In es, this message translates to:
  /// **'Casa'**
  String get shiftIconNameHome;

  /// No description provided for @shiftIconNameBeach.
  ///
  /// In es, this message translates to:
  /// **'Playa'**
  String get shiftIconNameBeach;

  /// No description provided for @shiftIconNameBed.
  ///
  /// In es, this message translates to:
  /// **'Cama'**
  String get shiftIconNameBed;

  /// No description provided for @shiftIconNameStar.
  ///
  /// In es, this message translates to:
  /// **'Estrella'**
  String get shiftIconNameStar;

  /// No description provided for @shiftIconNameHeart.
  ///
  /// In es, this message translates to:
  /// **'Corazón'**
  String get shiftIconNameHeart;

  /// No description provided for @shiftIconNameCoffee.
  ///
  /// In es, this message translates to:
  /// **'Café'**
  String get shiftIconNameCoffee;

  /// No description provided for @shiftIconNameBook.
  ///
  /// In es, this message translates to:
  /// **'Libro'**
  String get shiftIconNameBook;

  /// No description provided for @shiftIconNameMoney.
  ///
  /// In es, this message translates to:
  /// **'Dinero'**
  String get shiftIconNameMoney;

  /// No description provided for @shiftIconNameAlert.
  ///
  /// In es, this message translates to:
  /// **'Aviso'**
  String get shiftIconNameAlert;

  /// No description provided for @shiftIconNamePhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get shiftIconNamePhone;

  /// No description provided for @shiftIconNameCar.
  ///
  /// In es, this message translates to:
  /// **'Coche'**
  String get shiftIconNameCar;

  /// No description provided for @shiftIconNameTrain.
  ///
  /// In es, this message translates to:
  /// **'Tren'**
  String get shiftIconNameTrain;

  /// No description provided for @shiftIconNameBus.
  ///
  /// In es, this message translates to:
  /// **'Autobús'**
  String get shiftIconNameBus;

  /// No description provided for @shiftIconNameShop.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get shiftIconNameShop;

  /// No description provided for @shiftIconNameTool.
  ///
  /// In es, this message translates to:
  /// **'Herramientas'**
  String get shiftIconNameTool;

  /// No description provided for @shiftIconNameBaby.
  ///
  /// In es, this message translates to:
  /// **'Bebé'**
  String get shiftIconNameBaby;

  /// No description provided for @shiftIconNameSport.
  ///
  /// In es, this message translates to:
  /// **'Deporte'**
  String get shiftIconNameSport;

  /// No description provided for @shiftIconNameParty.
  ///
  /// In es, this message translates to:
  /// **'Fiesta'**
  String get shiftIconNameParty;

  /// No description provided for @shiftIconNameMedical.
  ///
  /// In es, this message translates to:
  /// **'Médico'**
  String get shiftIconNameMedical;

  /// No description provided for @shiftTypesColorMore.
  ///
  /// In es, this message translates to:
  /// **'Más colores…'**
  String get shiftTypesColorMore;

  /// No description provided for @shiftTypesColorPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige tu color'**
  String get shiftTypesColorPickerTitle;

  /// No description provided for @shiftTypesColorPickerHelp.
  ///
  /// In es, this message translates to:
  /// **'Mira cómo queda la casilla en claro y en oscuro. El texto se ajusta solo para que se lea bien.'**
  String get shiftTypesColorPickerHelp;

  /// No description provided for @shiftTypesColorHue.
  ///
  /// In es, this message translates to:
  /// **'Tono'**
  String get shiftTypesColorHue;

  /// No description provided for @shiftTypesColorSaturation.
  ///
  /// In es, this message translates to:
  /// **'Intensidad'**
  String get shiftTypesColorSaturation;

  /// No description provided for @shiftTypesColorLightness.
  ///
  /// In es, this message translates to:
  /// **'Luminosidad'**
  String get shiftTypesColorLightness;

  /// No description provided for @shiftTypesColorHueSpoken.
  ///
  /// In es, this message translates to:
  /// **'{degrees} grados'**
  String shiftTypesColorHueSpoken(int degrees);

  /// No description provided for @shiftTypesColorPercentSpoken.
  ///
  /// In es, this message translates to:
  /// **'{percent} por ciento'**
  String shiftTypesColorPercentSpoken(int percent);

  /// No description provided for @shiftTypesColorHexLabel.
  ///
  /// In es, this message translates to:
  /// **'Código hexadecimal'**
  String get shiftTypesColorHexLabel;

  /// No description provided for @shiftTypesColorHexError.
  ///
  /// In es, this message translates to:
  /// **'Escribe 6 cifras o letras de la A a la F, por ejemplo #1C7ED6.'**
  String get shiftTypesColorHexError;

  /// No description provided for @shiftTypesColorUse.
  ///
  /// In es, this message translates to:
  /// **'Usar este color'**
  String get shiftTypesColorUse;

  /// No description provided for @shiftTypesCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get shiftTypesCategoryLabel;

  /// No description provided for @shiftTypesTimesLabel.
  ///
  /// In es, this message translates to:
  /// **'Horario'**
  String get shiftTypesTimesLabel;

  /// No description provided for @shiftTypesStarts.
  ///
  /// In es, this message translates to:
  /// **'Empieza {time}'**
  String shiftTypesStarts(String time);

  /// No description provided for @shiftTypesEnds.
  ///
  /// In es, this message translates to:
  /// **'Termina {time}'**
  String shiftTypesEnds(String time);

  /// No description provided for @shiftTypesPickStart.
  ///
  /// In es, this message translates to:
  /// **'Hora de inicio'**
  String get shiftTypesPickStart;

  /// No description provided for @shiftTypesPickEnd.
  ///
  /// In es, this message translates to:
  /// **'Hora de fin'**
  String get shiftTypesPickEnd;

  /// No description provided for @shiftTypesDuration.
  ///
  /// In es, this message translates to:
  /// **'Dura {duration}'**
  String shiftTypesDuration(String duration);

  /// No description provided for @shiftTypesEndsNextDay.
  ///
  /// In es, this message translates to:
  /// **'Termina al día siguiente · dura {duration}'**
  String shiftTypesEndsNextDay(String duration);

  /// No description provided for @shiftTypesTwentyFourHours.
  ///
  /// In es, this message translates to:
  /// **'Dura 24 h: termina al día siguiente a la misma hora'**
  String get shiftTypesTwentyFourHours;

  /// No description provided for @shiftTypesSplitLabel.
  ///
  /// In es, this message translates to:
  /// **'Turno partido'**
  String get shiftTypesSplitLabel;

  /// No description provided for @shiftTypesSplitHelper.
  ///
  /// In es, this message translates to:
  /// **'Dos tramos el mismo día, con un descanso en medio que no cuenta como trabajado.'**
  String get shiftTypesSplitHelper;

  /// No description provided for @shiftTypesSplitTemplate.
  ///
  /// In es, this message translates to:
  /// **'Usar «Partido 09–13 / 17–21»'**
  String get shiftTypesSplitTemplate;

  /// No description provided for @shiftTypesSplitSecondTitle.
  ///
  /// In es, this message translates to:
  /// **'Segundo tramo'**
  String get shiftTypesSplitSecondTitle;

  /// No description provided for @shiftTypesPickSecondStart.
  ///
  /// In es, this message translates to:
  /// **'Inicio tramo 2'**
  String get shiftTypesPickSecondStart;

  /// No description provided for @shiftTypesPickSecondEnd.
  ///
  /// In es, this message translates to:
  /// **'Fin tramo 2'**
  String get shiftTypesPickSecondEnd;

  /// Resumen de un turno partido bajo las horas, p. ej. «Trabajas 4 h y 4 h: 8 h en total».
  ///
  /// In es, this message translates to:
  /// **'Trabajas {first} y {second}: {total} en total'**
  String shiftTypesSplitSummary(String first, String second, String total);

  /// No description provided for @shiftTypesErrorSplitIncomplete.
  ///
  /// In es, this message translates to:
  /// **'Pon cuándo empieza y cuándo acaba el segundo tramo, o apaga el turno partido.'**
  String get shiftTypesErrorSplitIncomplete;

  /// No description provided for @shiftTypesErrorSplitStart.
  ///
  /// In es, this message translates to:
  /// **'La hora de inicio del segundo tramo no es válida.'**
  String get shiftTypesErrorSplitStart;

  /// No description provided for @shiftTypesErrorSplitDuration.
  ///
  /// In es, this message translates to:
  /// **'El segundo tramo tiene que durar entre 1 minuto y 24 h.'**
  String get shiftTypesErrorSplitDuration;

  /// No description provided for @shiftTypesErrorSplitNotAfter.
  ///
  /// In es, this message translates to:
  /// **'El segundo tramo no puede empezar justo cuando acaba el primero: sería un solo tramo. Deja un descanso entre los dos.'**
  String get shiftTypesErrorSplitNotAfter;

  /// No description provided for @shiftTypesErrorSplitTooLong.
  ///
  /// In es, this message translates to:
  /// **'Los dos tramos y el descanso entre ellos no caben en 24 h. Comprueba que el segundo empieza después de que acabe el primero.'**
  String get shiftTypesErrorSplitTooLong;

  /// No description provided for @shiftTypesBreakLabel.
  ///
  /// In es, this message translates to:
  /// **'Descanso no pagado'**
  String get shiftTypesBreakLabel;

  /// No description provided for @shiftTypesBreakUnit.
  ///
  /// In es, this message translates to:
  /// **'min'**
  String get shiftTypesBreakUnit;

  /// No description provided for @shiftTypesBreakHint.
  ///
  /// In es, this message translates to:
  /// **'0 min'**
  String get shiftTypesBreakHint;

  /// No description provided for @shiftTypesRateHint.
  ///
  /// In es, this message translates to:
  /// **'Sin precio'**
  String get shiftTypesRateHint;

  /// No description provided for @shiftTypesBreakHelper.
  ///
  /// In es, this message translates to:
  /// **'Minutos del turno que no se pagan. Déjalo vacío si se paga todo.'**
  String get shiftTypesBreakHelper;

  /// No description provided for @shiftTypesPaidHelper.
  ///
  /// In es, this message translates to:
  /// **'Se pagan {duration}'**
  String shiftTypesPaidHelper(String duration);

  /// No description provided for @shiftTypesNightLabel.
  ///
  /// In es, this message translates to:
  /// **'Turno nocturno'**
  String get shiftTypesNightLabel;

  /// No description provided for @shiftTypesNightHelper.
  ///
  /// In es, this message translates to:
  /// **'Automático cuenta como noche las horas entre las 22:00 y las 06:00.'**
  String get shiftTypesNightHelper;

  /// No description provided for @shiftTypesNightAuto.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get shiftTypesNightAuto;

  /// No description provided for @shiftTypesNightAlways.
  ///
  /// In es, this message translates to:
  /// **'Siempre nocturno'**
  String get shiftTypesNightAlways;

  /// No description provided for @shiftTypesNightNever.
  ///
  /// In es, this message translates to:
  /// **'Nunca nocturno'**
  String get shiftTypesNightNever;

  /// No description provided for @shiftTypesFixedPlusLabel.
  ///
  /// In es, this message translates to:
  /// **'Plus por turno (opcional)'**
  String get shiftTypesFixedPlusLabel;

  /// No description provided for @shiftTypesFixedPlusHelper.
  ///
  /// In es, this message translates to:
  /// **'Se suma una vez por cada turno trabajado.'**
  String get shiftTypesFixedPlusHelper;

  /// No description provided for @shiftTypesFixedPlusHint.
  ///
  /// In es, this message translates to:
  /// **'Sin plus'**
  String get shiftTypesFixedPlusHint;

  /// No description provided for @shiftTypesFixedPlusUnit.
  ///
  /// In es, this message translates to:
  /// **'€'**
  String get shiftTypesFixedPlusUnit;

  /// No description provided for @shiftTypesRateLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio por hora (opcional)'**
  String get shiftTypesRateLabel;

  /// No description provided for @shiftTypesRateHelper.
  ///
  /// In es, this message translates to:
  /// **'Para calcular cuánto ganas en el resumen del mes.'**
  String get shiftTypesRateHelper;

  /// No description provided for @shiftTypesRateUnit.
  ///
  /// In es, this message translates to:
  /// **'€/h'**
  String get shiftTypesRateUnit;

  /// No description provided for @shiftTypesPreviewLabel.
  ///
  /// In es, this message translates to:
  /// **'Así se verá en el mes'**
  String get shiftTypesPreviewLabel;

  /// No description provided for @shiftTypesPreviewLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get shiftTypesPreviewLight;

  /// No description provided for @shiftTypesPreviewDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get shiftTypesPreviewDark;

  /// Contraste del código del turno sobre su casilla, bajo la vista previa, p. ej. «Contraste 7,2:1».
  ///
  /// In es, this message translates to:
  /// **'Contraste {ratio}:1'**
  String shiftTypesPreviewContrast(String ratio);

  /// No description provided for @shiftTypesErrorCodeEmpty.
  ///
  /// In es, this message translates to:
  /// **'Escribe un código de 1 a 3 caracteres'**
  String get shiftTypesErrorCodeEmpty;

  /// No description provided for @shiftTypesErrorCodeTooLong.
  ///
  /// In es, this message translates to:
  /// **'El código admite hasta 3 caracteres, sin emojis ni espacios'**
  String get shiftTypesErrorCodeTooLong;

  /// No description provided for @shiftTypesErrorCodeTaken.
  ///
  /// In es, this message translates to:
  /// **'Este código ya lo usa «{name}»'**
  String shiftTypesErrorCodeTaken(String name);

  /// No description provided for @shiftTypesErrorNameEmpty.
  ///
  /// In es, this message translates to:
  /// **'Pon un nombre al turno'**
  String get shiftTypesErrorNameEmpty;

  /// No description provided for @shiftTypesErrorBreak.
  ///
  /// In es, this message translates to:
  /// **'El descanso tiene que ser menor que la duración del turno'**
  String get shiftTypesErrorBreak;

  /// No description provided for @shiftTypesErrorRate.
  ///
  /// In es, this message translates to:
  /// **'Escribe un importe válido, por ejemplo 12,50'**
  String get shiftTypesErrorRate;

  /// No description provided for @paintFab.
  ///
  /// In es, this message translates to:
  /// **'Pintar'**
  String get paintFab;

  /// Etiqueta de la cabecera del modo pintar (se muestra en mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'Pintando'**
  String get paintHeader;

  /// Turno elegido y su horario en la cabecera del modo pintar, p. ej. «Tarde · 14:00–22:00».
  ///
  /// In es, this message translates to:
  /// **'{name} · {times}'**
  String paintHeaderShift(String name, String times);

  /// No description provided for @paintDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get paintDone;

  /// No description provided for @paintDouble.
  ///
  /// In es, this message translates to:
  /// **'Doblar'**
  String get paintDouble;

  /// No description provided for @paintEraser.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get paintEraser;

  /// No description provided for @paintToolsLabel.
  ///
  /// In es, this message translates to:
  /// **'Herramientas para pintar'**
  String get paintToolsLabel;

  /// Etiqueta de la cabecera del modo selección de días (se muestra en mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'Selección'**
  String get selectionHeader;

  /// No description provided for @selectionHint.
  ///
  /// In es, this message translates to:
  /// **'Toca los días o mantén pulsado y arrastra para elegir varios'**
  String get selectionHint;

  /// Cuántos días hay elegidos en la barra de selección.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Ningún día} =1{1 día} other{{count} días}}'**
  String selectionCount(int count);

  /// No description provided for @selectionBarLabel.
  ///
  /// In es, this message translates to:
  /// **'Acciones para los días elegidos'**
  String get selectionBarLabel;

  /// No description provided for @selectionSetShift.
  ///
  /// In es, this message translates to:
  /// **'Poner turno…'**
  String get selectionSetShift;

  /// No description provided for @selectionDouble.
  ///
  /// In es, this message translates to:
  /// **'Doblar con…'**
  String get selectionDouble;

  /// No description provided for @selectionClear.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get selectionClear;

  /// No description provided for @selectionReset.
  ///
  /// In es, this message translates to:
  /// **'Volver al patrón'**
  String get selectionReset;

  /// No description provided for @selectionCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get selectionCopy;

  /// No description provided for @selectionCut.
  ///
  /// In es, this message translates to:
  /// **'Cortar'**
  String get selectionCut;

  /// No description provided for @selectionPaste.
  ///
  /// In es, this message translates to:
  /// **'Pegar'**
  String get selectionPaste;

  /// No description provided for @selectionRepeat.
  ///
  /// In es, this message translates to:
  /// **'Repetir…'**
  String get selectionRepeat;

  /// No description provided for @selectionNote.
  ///
  /// In es, this message translates to:
  /// **'Nota…'**
  String get selectionNote;

  /// No description provided for @selectionCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get selectionCancel;

  /// No description provided for @selectionCellSelected.
  ///
  /// In es, this message translates to:
  /// **'elegido'**
  String get selectionCellSelected;

  /// No description provided for @selectionSetShiftTitle.
  ///
  /// In es, this message translates to:
  /// **'Poner turno'**
  String get selectionSetShiftTitle;

  /// No description provided for @selectionSetShiftHelp.
  ///
  /// In es, this message translates to:
  /// **'Sustituye los turnos de los días elegidos.'**
  String get selectionSetShiftHelp;

  /// No description provided for @selectionDoubleTitle.
  ///
  /// In es, this message translates to:
  /// **'Doblar con otro turno'**
  String get selectionDoubleTitle;

  /// No description provided for @selectionDoubleHelp.
  ///
  /// In es, this message translates to:
  /// **'Añade el turno a los que ya tengan los días elegidos.'**
  String get selectionDoubleHelp;

  /// No description provided for @selectionNoteTitle.
  ///
  /// In es, this message translates to:
  /// **'Nota para los días elegidos'**
  String get selectionNoteTitle;

  /// No description provided for @selectionNoteHint.
  ///
  /// In es, this message translates to:
  /// **'La misma nota en todos los días'**
  String get selectionNoteHint;

  /// No description provided for @selectionNoteSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar nota'**
  String get selectionNoteSave;

  /// No description provided for @selectionNoteRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar notas'**
  String get selectionNoteRemove;

  /// No description provided for @selectionPasteTitle.
  ///
  /// In es, this message translates to:
  /// **'Pegar días'**
  String get selectionPasteTitle;

  /// No description provided for @selectionPasteSummary.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se pega 1 día} other{Se pegan {count} días}} a partir del {date}.'**
  String selectionPasteSummary(int count, String date);

  /// Hasta qué día llega el bloque pegado (con sus huecos); {from} y {to} son «lun 3» y «dom 9 de noviembre», o con el mes en los dos extremos si cruza de mes.
  ///
  /// In es, this message translates to:
  /// **'Se pegará del {from} al {to}.'**
  String selectionPasteReach(String from, String to);

  /// No description provided for @selectionPasteReplaces.
  ///
  /// In es, this message translates to:
  /// **'Los turnos de esos días se sustituyen. Podrás deshacerlo.'**
  String get selectionPasteReplaces;

  /// No description provided for @selectionIncludeNotes.
  ///
  /// In es, this message translates to:
  /// **'Incluir notas'**
  String get selectionIncludeNotes;

  /// No description provided for @selectionIncludeNotesHelp.
  ///
  /// In es, this message translates to:
  /// **'Las notas de los días copiados sustituyen a las que haya en el destino.'**
  String get selectionIncludeNotesHelp;

  /// Línea del cuadro de Pegar tras Cortar, en lugar del interruptor «Incluir notas»: las notas, avisos y horas extra viajan siempre con los días cortados.
  ///
  /// In es, this message translates to:
  /// **'Al cortar, las notas se mueven con los días.'**
  String get selectionCutNotesMove;

  /// No description provided for @selectionPasteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Pegar'**
  String get selectionPasteConfirm;

  /// No description provided for @selectionRepeatTitle.
  ///
  /// In es, this message translates to:
  /// **'Repetir los días elegidos'**
  String get selectionRepeatTitle;

  /// No description provided for @selectionRepeatTimes.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 vez} other{{count} veces}}'**
  String selectionRepeatTimes(int count);

  /// No description provided for @selectionRepeatLess.
  ///
  /// In es, this message translates to:
  /// **'Una vez menos'**
  String get selectionRepeatLess;

  /// No description provided for @selectionRepeatMore.
  ///
  /// In es, this message translates to:
  /// **'Una vez más'**
  String get selectionRepeatMore;

  /// No description provided for @selectionRepeatPreview.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Cambia 1 día más, hasta el {date}.} other{Cambia {count} días más, hasta el {date}.}}'**
  String selectionRepeatPreview(int count, String date);

  /// No description provided for @selectionRepeatConfirm.
  ///
  /// In es, this message translates to:
  /// **'Repetir'**
  String get selectionRepeatConfirm;

  /// No description provided for @selectionChanged.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día cambiado} other{{count} días cambiados}}'**
  String selectionChanged(int count);

  /// No description provided for @selectionNothingChanged.
  ///
  /// In es, this message translates to:
  /// **'Esos días ya estaban así'**
  String get selectionNothingChanged;

  /// No description provided for @selectionCopied.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día copiado} other{{count} días copiados}}. Elige el día de inicio y pulsa Pegar.'**
  String selectionCopied(int count);

  /// No description provided for @selectionCutDone.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día cortado} other{{count} días cortados}}. Elige el día de inicio y pulsa Pegar.'**
  String selectionCutDone(int count);

  /// No description provided for @selectionPasted.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día pegado} other{{count} días pegados}}'**
  String selectionPasted(int count);

  /// No description provided for @selectionRepeated.
  ///
  /// In es, this message translates to:
  /// **'Repetido {times, plural, =1{1 vez} other{{times} veces}}'**
  String selectionRepeated(int times);

  /// No description provided for @selectionRunsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis rotaciones'**
  String get selectionRunsTitle;

  /// No description provided for @selectionRunsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Termina o quita un patrón de una vez'**
  String get selectionRunsSubtitle;

  /// No description provided for @selectionRunsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin rotaciones'**
  String get selectionRunsEmptyTitle;

  /// No description provided for @selectionRunsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuando apliques un patrón desde Pintar, aparecerá aquí.'**
  String get selectionRunsEmptyMessage;

  /// No description provided for @selectionRunsRange.
  ///
  /// In es, this message translates to:
  /// **'Del {from} al {to}'**
  String selectionRunsRange(String from, String to);

  /// No description provided for @selectionRunsOpenEnded.
  ///
  /// In es, this message translates to:
  /// **'Desde el {from}, sin fecha de fin'**
  String selectionRunsOpenEnded(String from);

  /// No description provided for @selectionRunsStep.
  ///
  /// In es, this message translates to:
  /// **'Empieza en el día {day} del ciclo'**
  String selectionRunsStep(int day);

  /// No description provided for @selectionRunsActive.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get selectionRunsActive;

  /// No description provided for @selectionRunsFuture.
  ///
  /// In es, this message translates to:
  /// **'Aún no ha empezado'**
  String get selectionRunsFuture;

  /// No description provided for @selectionRunsEnded.
  ///
  /// In es, this message translates to:
  /// **'Terminada'**
  String get selectionRunsEnded;

  /// No description provided for @selectionRunsEnd.
  ///
  /// In es, this message translates to:
  /// **'Terminar aquí'**
  String get selectionRunsEnd;

  /// No description provided for @selectionRunsEndHelp.
  ///
  /// In es, this message translates to:
  /// **'Primer día sin la rotación'**
  String get selectionRunsEndHelp;

  /// No description provided for @selectionRunsEndDone.
  ///
  /// In es, this message translates to:
  /// **'La rotación acaba el {date}'**
  String selectionRunsEndDone(String date);

  /// No description provided for @selectionRunsDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get selectionRunsDelete;

  /// No description provided for @selectionRunsDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar {name}?'**
  String selectionRunsDeleteTitle(String name);

  /// No description provided for @selectionRunsDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Se quita del calendario entero. Los días que cambiaste a mano y las notas se quedan como están. Podrás deshacerlo.'**
  String get selectionRunsDeleteBody;

  /// No description provided for @selectionRunsDeleted.
  ///
  /// In es, this message translates to:
  /// **'Rotación eliminada'**
  String get selectionRunsDeleted;

  /// No description provided for @agendaTitle.
  ///
  /// In es, this message translates to:
  /// **'Agenda'**
  String get agendaTitle;

  /// No description provided for @agendaOpenTooltip.
  ///
  /// In es, this message translates to:
  /// **'Agenda de notas'**
  String get agendaOpenTooltip;

  /// No description provided for @agendaSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en notas y turnos'**
  String get agendaSearchHint;

  /// No description provided for @agendaSearchHintShort.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get agendaSearchHintShort;

  /// Opción de la agenda que lista las notas y los festivos propios (por defecto).
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get agendaModeNotes;

  /// Opción de la agenda que lista cada uno de los próximos 60 días con sus turnos.
  ///
  /// In es, this message translates to:
  /// **'Turnos'**
  String get agendaModeShifts;

  /// No description provided for @agendaSearchScope.
  ///
  /// In es, this message translates to:
  /// **'Busca en todas tus notas y festivos propios, y en los turnos desde hace un año hasta dentro de un año. También entiende fechas: 15/10 o 15 oct.'**
  String get agendaSearchScope;

  /// No description provided for @agendaSearchClear.
  ///
  /// In es, this message translates to:
  /// **'Borrar búsqueda'**
  String get agendaSearchClear;

  /// No description provided for @agendaEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin notas próximas'**
  String get agendaEmptyTitle;

  /// No description provided for @agendaEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Las notas y los festivos propios de los próximos días aparecerán aquí.'**
  String get agendaEmptyMessage;

  /// No description provided for @agendaNoResultsTitle.
  ///
  /// In es, this message translates to:
  /// **'Nada encontrado'**
  String get agendaNoResultsTitle;

  /// No description provided for @agendaNoResultsMessage.
  ///
  /// In es, this message translates to:
  /// **'No hay notas ni turnos que coincidan con «{query}».'**
  String agendaNoResultsMessage(String query);

  /// No description provided for @agendaHoliday.
  ///
  /// In es, this message translates to:
  /// **'Festivo: {name}'**
  String agendaHoliday(String name);

  /// No description provided for @agendaTruncated.
  ///
  /// In es, this message translates to:
  /// **'Se muestran los primeros {count} resultados. Escribe algo más para afinar.'**
  String agendaTruncated(int count);

  /// No description provided for @agendaResults.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 resultado} other{{count} resultados}}'**
  String agendaResults(int count);

  /// No description provided for @agendaSemanticsNote.
  ///
  /// In es, this message translates to:
  /// **'nota: {note}'**
  String agendaSemanticsNote(String note);

  /// Botón de la cabecera del modo pintar que abre el asistente de patrón.
  ///
  /// In es, this message translates to:
  /// **'Patrón'**
  String get patternButton;

  /// No description provided for @patternTitle.
  ///
  /// In es, this message translates to:
  /// **'Aplicar patrón'**
  String get patternTitle;

  /// No description provided for @patternStepOf.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String patternStepOf(int current, int total);

  /// No description provided for @patternStepChoose.
  ///
  /// In es, this message translates to:
  /// **'Elige un patrón'**
  String get patternStepChoose;

  /// No description provided for @patternStepStart.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo empiezas?'**
  String get patternStepStart;

  /// No description provided for @patternStepEnd.
  ///
  /// In es, this message translates to:
  /// **'¿Hasta cuándo?'**
  String get patternStepEnd;

  /// No description provided for @patternNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get patternNext;

  /// No description provided for @patternBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get patternBack;

  /// No description provided for @patternApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get patternApply;

  /// No description provided for @patternApplied.
  ///
  /// In es, this message translates to:
  /// **'Patrón aplicado'**
  String get patternApplied;

  /// No description provided for @patternApplyFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido aplicar el patrón'**
  String get patternApplyFailed;

  /// Día en el que empieza el patrón tras la pulsación larga, p. ej. «Desde el sábado 24 de octubre».
  ///
  /// In es, this message translates to:
  /// **'Desde el {date}'**
  String patternFromDay(String date);

  /// No description provided for @patternGroupHealth.
  ///
  /// In es, this message translates to:
  /// **'Sanidad'**
  String get patternGroupHealth;

  /// No description provided for @patternGroupPolice.
  ///
  /// In es, this message translates to:
  /// **'Policía y Guardia Civil'**
  String get patternGroupPolice;

  /// No description provided for @patternGroupFirefighters.
  ///
  /// In es, this message translates to:
  /// **'Bomberos'**
  String get patternGroupFirefighters;

  /// No description provided for @patternGroupIndustry.
  ///
  /// In es, this message translates to:
  /// **'Industria'**
  String get patternGroupIndustry;

  /// No description provided for @patternGroupSecurity.
  ///
  /// In es, this message translates to:
  /// **'Seguridad'**
  String get patternGroupSecurity;

  /// No description provided for @patternGroupOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get patternGroupOther;

  /// No description provided for @patternGroupMine.
  ///
  /// In es, this message translates to:
  /// **'Mis patrones'**
  String get patternGroupMine;

  /// Sección con los patrones cuyo primer día es el turno de la ficha pulsada, p. ej. «Empiezan por Noche».
  ///
  /// In es, this message translates to:
  /// **'Empiezan por {shift}'**
  String patternGroupTypical(String shift);

  /// Sección con los patrones que contienen el turno de la ficha pulsada, cuando ninguno empieza por él.
  ///
  /// In es, this message translates to:
  /// **'Incluyen {shift}'**
  String patternGroupIncluding(String shift);

  /// Longitud del ciclo de un patrón.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día} other{{count} días}}'**
  String patternCycleDays(int count);

  /// No description provided for @patternCreateOwn.
  ///
  /// In es, this message translates to:
  /// **'Crear el mío'**
  String get patternCreateOwn;

  /// No description provided for @patternCreateOwnHint.
  ///
  /// In es, this message translates to:
  /// **'Monta tu secuencia día a día'**
  String get patternCreateOwnHint;

  /// No description provided for @patternBuilderBack.
  ///
  /// In es, this message translates to:
  /// **'Elegir un patrón de la lista'**
  String get patternBuilderBack;

  /// No description provided for @patternBuilderName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del patrón'**
  String get patternBuilderName;

  /// No description provided for @patternBuilderDefaultName.
  ///
  /// In es, this message translates to:
  /// **'Mi patrón'**
  String get patternBuilderDefaultName;

  /// No description provided for @patternBuilderSequence.
  ///
  /// In es, this message translates to:
  /// **'Tu secuencia'**
  String get patternBuilderSequence;

  /// No description provided for @patternBuilderEmpty.
  ///
  /// In es, this message translates to:
  /// **'Toca los turnos de abajo para ir añadiendo días.'**
  String get patternBuilderEmpty;

  /// No description provided for @patternBuilderSameDay.
  ///
  /// In es, this message translates to:
  /// **'Varios turnos en un día'**
  String get patternBuilderSameDay;

  /// No description provided for @patternBuilderSameDayHint.
  ///
  /// In es, this message translates to:
  /// **'Activado: cada turno que toques se suma al último día de la secuencia, en vez de crear un día nuevo.'**
  String get patternBuilderSameDayHint;

  /// No description provided for @patternBuilderRemoveLast.
  ///
  /// In es, this message translates to:
  /// **'Quitar el último'**
  String get patternBuilderRemoveLast;

  /// No description provided for @patternBuilderClear.
  ///
  /// In es, this message translates to:
  /// **'Vaciar la secuencia'**
  String get patternBuilderClear;

  /// No description provided for @patternBuilderAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir {name}'**
  String patternBuilderAdd(String name);

  /// No description provided for @patternStartLabel.
  ///
  /// In es, this message translates to:
  /// **'Día de inicio'**
  String get patternStartLabel;

  /// No description provided for @patternSuggestedStart.
  ///
  /// In es, this message translates to:
  /// **'Este patrón suele empezar en {weekday}.'**
  String patternSuggestedStart(String weekday);

  /// No description provided for @patternWeekdayMonday.
  ///
  /// In es, this message translates to:
  /// **'lunes'**
  String get patternWeekdayMonday;

  /// No description provided for @patternWeekdayTuesday.
  ///
  /// In es, this message translates to:
  /// **'martes'**
  String get patternWeekdayTuesday;

  /// No description provided for @patternWeekdayWednesday.
  ///
  /// In es, this message translates to:
  /// **'miércoles'**
  String get patternWeekdayWednesday;

  /// No description provided for @patternWeekdayThursday.
  ///
  /// In es, this message translates to:
  /// **'jueves'**
  String get patternWeekdayThursday;

  /// No description provided for @patternWeekdayFriday.
  ///
  /// In es, this message translates to:
  /// **'viernes'**
  String get patternWeekdayFriday;

  /// No description provided for @patternWeekdaySaturday.
  ///
  /// In es, this message translates to:
  /// **'sábado'**
  String get patternWeekdaySaturday;

  /// No description provided for @patternWeekdaySunday.
  ///
  /// In es, this message translates to:
  /// **'domingo'**
  String get patternWeekdaySunday;

  /// No description provided for @patternOffsetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿En qué día del ciclo estás ese día?'**
  String get patternOffsetTitle;

  /// No description provided for @patternOffsetHelp.
  ///
  /// In es, this message translates to:
  /// **'Toca el día del patrón que te toca el {date}.'**
  String patternOffsetHelp(String date);

  /// No description provided for @patternOffsetThatDay.
  ///
  /// In es, this message translates to:
  /// **'Ese día te toca: {shifts}'**
  String patternOffsetThatDay(String shifts);

  /// No description provided for @patternChipDay.
  ///
  /// In es, this message translates to:
  /// **'Día {day}: {shifts}'**
  String patternChipDay(int day, String shifts);

  /// No description provided for @patternEndNever.
  ///
  /// In es, this message translates to:
  /// **'Sin fin'**
  String get patternEndNever;

  /// No description provided for @patternEndNeverHint.
  ///
  /// In es, this message translates to:
  /// **'Se repite hasta que lo cambies.'**
  String get patternEndNeverHint;

  /// No description provided for @patternEndUntil.
  ///
  /// In es, this message translates to:
  /// **'Hasta una fecha'**
  String get patternEndUntil;

  /// No description provided for @patternEndUntilHint.
  ///
  /// In es, this message translates to:
  /// **'Después de esa fecha vuelve lo que tenías.'**
  String get patternEndUntilHint;

  /// No description provided for @patternUntilLabel.
  ///
  /// In es, this message translates to:
  /// **'Último día'**
  String get patternUntilLabel;

  /// No description provided for @patternOverridesTitle.
  ///
  /// In es, this message translates to:
  /// **'Días que ya has cambiado a mano'**
  String get patternOverridesTitle;

  /// No description provided for @patternOverridesKeep.
  ///
  /// In es, this message translates to:
  /// **'Respetar los días que ya he cambiado a mano'**
  String get patternOverridesKeep;

  /// No description provided for @patternOverridesKeepHint.
  ///
  /// In es, this message translates to:
  /// **'Tus cambios se quedan; el patrón rellena el resto.'**
  String get patternOverridesKeepHint;

  /// No description provided for @patternOverridesReplace.
  ///
  /// In es, this message translates to:
  /// **'Sustituirlos por el patrón'**
  String get patternOverridesReplace;

  /// No description provided for @patternOverridesReplaceHint.
  ///
  /// In es, this message translates to:
  /// **'Se borran tus cambios a mano de esas fechas. Las notas se quedan.'**
  String get patternOverridesReplaceHint;

  /// No description provided for @patternPreviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Así quedará'**
  String get patternPreviewTitle;

  /// No description provided for @patternPreviewNone.
  ///
  /// In es, this message translates to:
  /// **'Elige un patrón para ver cómo queda.'**
  String get patternPreviewNone;

  /// No description provided for @patternPreviewPostNight.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Saliente automático: 1 día después de una noche.} other{Saliente automático: {count} días después de una noche.}}'**
  String patternPreviewPostNight(int count);

  /// No description provided for @patternPickBanner.
  ///
  /// In es, this message translates to:
  /// **'Toca el día en que empieza el patrón'**
  String get patternPickBanner;

  /// No description provided for @onboardingSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get onboardingNext;

  /// No description provided for @onboardingContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get onboardingContinue;

  /// No description provided for @onboardingProgress.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String onboardingProgress(int current, int total);

  /// No description provided for @onboardingProfessionTitle.
  ///
  /// In es, this message translates to:
  /// **'¿A qué te dedicas?'**
  String get onboardingProfessionTitle;

  /// No description provided for @onboardingProfessionHelp.
  ///
  /// In es, this message translates to:
  /// **'Así te dejamos los turnos y las rotaciones de tu trabajo. Lo cambias cuando quieras.'**
  String get onboardingProfessionHelp;

  /// No description provided for @onboardingProfessionNursing.
  ///
  /// In es, this message translates to:
  /// **'Enfermería, TCAE y celadores'**
  String get onboardingProfessionNursing;

  /// No description provided for @onboardingProfessionNursingHint.
  ///
  /// In es, this message translates to:
  /// **'M 08–15, T 15–22, N 22–08 y saliente'**
  String get onboardingProfessionNursingHint;

  /// No description provided for @onboardingProfessionMedicine.
  ///
  /// In es, this message translates to:
  /// **'Medicina (guardias)'**
  String get onboardingProfessionMedicine;

  /// No description provided for @onboardingProfessionMedicineHint.
  ///
  /// In es, this message translates to:
  /// **'Mañana, guardia de 24 h y saliente'**
  String get onboardingProfessionMedicineHint;

  /// No description provided for @onboardingProfessionPolice.
  ///
  /// In es, this message translates to:
  /// **'Policía y Guardia Civil'**
  String get onboardingProfessionPolice;

  /// No description provided for @onboardingProfessionPoliceHint.
  ///
  /// In es, this message translates to:
  /// **'M 07–15, T 15–23 y N 23–07'**
  String get onboardingProfessionPoliceHint;

  /// No description provided for @onboardingProfessionFirefighters.
  ///
  /// In es, this message translates to:
  /// **'Bomberos'**
  String get onboardingProfessionFirefighters;

  /// No description provided for @onboardingProfessionFirefightersHint.
  ///
  /// In es, this message translates to:
  /// **'Guardia de 24 h y descansos largos'**
  String get onboardingProfessionFirefightersHint;

  /// No description provided for @onboardingProfessionIndustry.
  ///
  /// In es, this message translates to:
  /// **'Industria'**
  String get onboardingProfessionIndustry;

  /// No description provided for @onboardingProfessionIndustryHint.
  ///
  /// In es, this message translates to:
  /// **'Correturnos: M 06–14, T 14–22 y N 22–06'**
  String get onboardingProfessionIndustryHint;

  /// No description provided for @onboardingProfessionSecurity.
  ///
  /// In es, this message translates to:
  /// **'Seguridad privada'**
  String get onboardingProfessionSecurity;

  /// No description provided for @onboardingProfessionSecurityHint.
  ///
  /// In es, this message translates to:
  /// **'Turnos de 12 h, de día y de noche'**
  String get onboardingProfessionSecurityHint;

  /// No description provided for @onboardingProfessionHospitality.
  ///
  /// In es, this message translates to:
  /// **'Hostelería y comercio'**
  String get onboardingProfessionHospitality;

  /// No description provided for @onboardingProfessionHospitalityHint.
  ///
  /// In es, this message translates to:
  /// **'M 08–16 y T 16–00'**
  String get onboardingProfessionHospitalityHint;

  /// No description provided for @onboardingProfessionOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get onboardingProfessionOther;

  /// No description provided for @onboardingProfessionOtherHint.
  ///
  /// In es, this message translates to:
  /// **'Empiezas con los turnos de siempre'**
  String get onboardingProfessionOtherHint;

  /// No description provided for @onboardingPlaceTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Dónde trabajas?'**
  String get onboardingPlaceTitle;

  /// No description provided for @onboardingPlaceHelp.
  ///
  /// In es, this message translates to:
  /// **'Para marcarte en el calendario los festivos de tu comunidad y de tu municipio.'**
  String get onboardingPlaceHelp;

  /// No description provided for @onboardingRegionLabel.
  ///
  /// In es, this message translates to:
  /// **'Comunidad'**
  String get onboardingRegionLabel;

  /// No description provided for @onboardingRegionPick.
  ///
  /// In es, this message translates to:
  /// **'Elegir comunidad'**
  String get onboardingRegionPick;

  /// No description provided for @onboardingRegionSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu comunidad'**
  String get onboardingRegionSheetTitle;

  /// No description provided for @onboardingMunicipalityLabel.
  ///
  /// In es, this message translates to:
  /// **'Municipio (opcional)'**
  String get onboardingMunicipalityLabel;

  /// No description provided for @onboardingMunicipalityPick.
  ///
  /// In es, this message translates to:
  /// **'Buscar municipio'**
  String get onboardingMunicipalityPick;

  /// No description provided for @onboardingMunicipalityNeedsRegion.
  ///
  /// In es, this message translates to:
  /// **'Elige antes la comunidad'**
  String get onboardingMunicipalityNeedsRegion;

  /// No description provided for @onboardingMunicipalitySheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu municipio'**
  String get onboardingMunicipalitySheetTitle;

  /// No description provided for @onboardingMunicipalitySearch.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre'**
  String get onboardingMunicipalitySearch;

  /// No description provided for @onboardingMunicipalityNone.
  ///
  /// In es, this message translates to:
  /// **'Ningún municipio se llama así'**
  String get onboardingMunicipalityNone;

  /// No description provided for @onboardingMunicipalityClear.
  ///
  /// In es, this message translates to:
  /// **'Quitar municipio'**
  String get onboardingMunicipalityClear;

  /// No description provided for @onboardingLocalHolidaysMissing.
  ///
  /// In es, this message translates to:
  /// **'Los festivos locales de tu municipio los puedes añadir tú en dos toques.'**
  String get onboardingLocalHolidaysMissing;

  /// No description provided for @onboardingRotationTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo es tu rotación?'**
  String get onboardingRotationTitle;

  /// No description provided for @onboardingRotationHelp.
  ///
  /// In es, this message translates to:
  /// **'Elige la que más se parezca. Luego dices cuándo empiezas.'**
  String get onboardingRotationHelp;

  /// No description provided for @onboardingRotationTypical.
  ///
  /// In es, this message translates to:
  /// **'Lo habitual en tu trabajo'**
  String get onboardingRotationTypical;

  /// No description provided for @onboardingRotationOthers.
  ///
  /// In es, this message translates to:
  /// **'Otras rotaciones'**
  String get onboardingRotationOthers;

  /// No description provided for @onboardingRotationAll.
  ///
  /// In es, this message translates to:
  /// **'Rotaciones'**
  String get onboardingRotationAll;

  /// No description provided for @onboardingByHand.
  ///
  /// In es, this message translates to:
  /// **'Lo pinto a mano'**
  String get onboardingByHand;

  /// No description provided for @onboardingByHandHint.
  ///
  /// In es, this message translates to:
  /// **'Sin rotación: pintas tú los días en el calendario.'**
  String get onboardingByHandHint;

  /// No description provided for @onboardingStartTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo empiezas?'**
  String get onboardingStartTitle;

  /// No description provided for @onboardingStartHelp.
  ///
  /// In es, this message translates to:
  /// **'Di desde qué día cuenta y en qué punto del ciclo estás ese día.'**
  String get onboardingStartHelp;

  /// No description provided for @onboardingImportTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Vienes de otra app?'**
  String get onboardingImportTitle;

  /// No description provided for @onboardingImportBody.
  ///
  /// In es, this message translates to:
  /// **'Si ya llevabas tus turnos en LRHSoft (Shifter), Supershift u otra app, tráelos desde su copia, el calendario del móvil o un archivo. También puedes hacerlo más tarde, en Ajustes.'**
  String get onboardingImportBody;

  /// No description provided for @onboardingReadyTitle.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get onboardingReadyTitle;

  /// No description provided for @onboardingReadyBody.
  ///
  /// In es, this message translates to:
  /// **'Tu calendario está preparado. Todo esto lo puedes cambiar cuando quieras en Ajustes.'**
  String get onboardingReadyBody;

  /// No description provided for @onboardingReadyProfession.
  ///
  /// In es, this message translates to:
  /// **'Trabajo: {name}'**
  String onboardingReadyProfession(String name);

  /// No description provided for @onboardingReadyPlace.
  ///
  /// In es, this message translates to:
  /// **'Festivos: {place}'**
  String onboardingReadyPlace(String place);

  /// No description provided for @onboardingReadyRotation.
  ///
  /// In es, this message translates to:
  /// **'Rotación: {name}, desde el {date}'**
  String onboardingReadyRotation(String name, String date);

  /// No description provided for @onboardingReadyOffset.
  ///
  /// In es, this message translates to:
  /// **'Empiezas en el día {day} del ciclo ({shifts})'**
  String onboardingReadyOffset(int day, String shifts);

  /// No description provided for @onboardingReadyByHand.
  ///
  /// In es, this message translates to:
  /// **'Rotación: la pintas tú a mano'**
  String get onboardingReadyByHand;

  /// No description provided for @onboardingReadyNothing.
  ///
  /// In es, this message translates to:
  /// **'No has elegido nada, así que empiezas con el calendario en blanco.'**
  String get onboardingReadyNothing;

  /// No description provided for @onboardingReadySaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido guardar todo. Revisa tus turnos y festivos en Ajustes.'**
  String get onboardingReadySaveFailed;

  /// No description provided for @onboardingOpenCalendar.
  ///
  /// In es, this message translates to:
  /// **'Ver mi calendario'**
  String get onboardingOpenCalendar;

  /// No description provided for @onboardingTipTitle.
  ///
  /// In es, this message translates to:
  /// **'Pinta tu mes en un momento'**
  String get onboardingTipTitle;

  /// No description provided for @onboardingTipBody.
  ///
  /// In es, this message translates to:
  /// **'Toca Pintar, elige un turno y arrastra por los días. Con el botón Patrón repites una rotación entera de una vez.'**
  String get onboardingTipBody;

  /// No description provided for @onboardingTipDismiss.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get onboardingTipDismiss;

  /// No description provided for @onboardingTipClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar el consejo'**
  String get onboardingTipClose;

  /// No description provided for @paintScrollUp.
  ///
  /// In es, this message translates to:
  /// **'Desplazar el mes hacia arriba'**
  String get paintScrollUp;

  /// No description provided for @paintScrollDown.
  ///
  /// In es, this message translates to:
  /// **'Desplazar el mes hacia abajo'**
  String get paintScrollDown;

  /// Texto del consejo compacto de la pantalla del mes: una linea que explica como pintar el mes arrastrando por los dias.
  ///
  /// In es, this message translates to:
  /// **'Elige un turno y arrastra.'**
  String get monthTipPaint;

  /// No description provided for @postNightAutoTitle.
  ///
  /// In es, this message translates to:
  /// **'Saliente automático'**
  String get postNightAutoTitle;

  /// No description provided for @postNightAutoHelp.
  ///
  /// In es, this message translates to:
  /// **'Después de una noche, el día siguiente pasa a Saliente si estaba vacío o libre.'**
  String get postNightAutoHelp;

  /// No description provided for @yearTitle.
  ///
  /// In es, this message translates to:
  /// **'Vista anual'**
  String get yearTitle;

  /// No description provided for @yearOpenTooltip.
  ///
  /// In es, this message translates to:
  /// **'Ver el año'**
  String get yearOpenTooltip;

  /// No description provided for @yearPrevious.
  ///
  /// In es, this message translates to:
  /// **'Año anterior'**
  String get yearPrevious;

  /// No description provided for @yearNext.
  ///
  /// In es, this message translates to:
  /// **'Año siguiente'**
  String get yearNext;

  /// No description provided for @yearShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir como imagen'**
  String get yearShare;

  /// No description provided for @yearShareSubject.
  ///
  /// In es, this message translates to:
  /// **'Mis turnos de {year}'**
  String yearShareSubject(int year);

  /// No description provided for @yearShareFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido compartir la imagen'**
  String get yearShareFailed;

  /// No description provided for @yearImageTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis turnos {year}'**
  String yearImageTitle(int year);

  /// No description provided for @yearMonthEmpty.
  ///
  /// In es, this message translates to:
  /// **'sin turnos'**
  String get yearMonthEmpty;

  /// No description provided for @yearLegendTitle.
  ///
  /// In es, this message translates to:
  /// **'Turnos del año'**
  String get yearLegendTitle;

  /// No description provided for @yearLegendEmpty.
  ///
  /// In es, this message translates to:
  /// **'Este año no tiene turnos.'**
  String get yearLegendEmpty;

  /// No description provided for @yearLegendDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día} other{{count} días}}'**
  String yearLegendDays(int count);

  /// No description provided for @yearLegendHoliday.
  ///
  /// In es, this message translates to:
  /// **'Festivo'**
  String get yearLegendHoliday;

  /// No description provided for @summaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get summaryTitle;

  /// No description provided for @summaryOpenTooltip.
  ///
  /// In es, this message translates to:
  /// **'Resumen del mes'**
  String get summaryOpenTooltip;

  /// No description provided for @summaryModeMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get summaryModeMonth;

  /// No description provided for @summaryModeYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get summaryModeYear;

  /// No description provided for @summaryModeRange.
  ///
  /// In es, this message translates to:
  /// **'Fechas…'**
  String get summaryModeRange;

  /// No description provided for @summaryRangeFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get summaryRangeFrom;

  /// No description provided for @summaryRangeTo.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get summaryRangeTo;

  /// No description provided for @summaryRangePrevious.
  ///
  /// In es, this message translates to:
  /// **'Periodo anterior'**
  String get summaryRangePrevious;

  /// No description provided for @summaryRangeNext.
  ///
  /// In es, this message translates to:
  /// **'Periodo siguiente'**
  String get summaryRangeNext;

  /// No description provided for @summaryRangeDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día en total} other{{count} días en total}}. Puedes elegir hasta {max}.'**
  String summaryRangeDays(int count, int max);

  /// No description provided for @summaryRangeClamped.
  ///
  /// In es, this message translates to:
  /// **'El máximo son {max} días: hemos acortado la fecha final.'**
  String summaryRangeClamped(int max);

  /// No description provided for @summaryRangePreviousName.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, =1{el día anterior} other{los {days} días anteriores}}'**
  String summaryRangePreviousName(int days);

  /// No description provided for @summaryRangeEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin turnos en estas fechas'**
  String get summaryRangeEmptyTitle;

  /// No description provided for @summaryRangeEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Elige otras fechas o pinta turnos en el calendario.'**
  String get summaryRangeEmptyBody;

  /// No description provided for @summaryRangeNoteMidnight.
  ///
  /// In es, this message translates to:
  /// **'Las horas de un turno que cruza la medianoche se cuentan en el día en que empieza, también si es el último día de las fechas.'**
  String get summaryRangeNoteMidnight;

  /// No description provided for @summaryEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin turnos este mes'**
  String get summaryEmptyTitle;

  /// No description provided for @summaryEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Pinta turnos en el calendario y aquí verás las horas y el estimado.'**
  String get summaryEmptyBody;

  /// No description provided for @summaryHoursWorked.
  ///
  /// In es, this message translates to:
  /// **'Horas trabajadas'**
  String get summaryHoursWorked;

  /// No description provided for @summaryShiftsWorked.
  ///
  /// In es, this message translates to:
  /// **'Turnos trabajados'**
  String get summaryShiftsWorked;

  /// No description provided for @summaryNightHours.
  ///
  /// In es, this message translates to:
  /// **'Horas nocturnas'**
  String get summaryNightHours;

  /// No description provided for @summaryRestDays.
  ///
  /// In es, this message translates to:
  /// **'Días libres'**
  String get summaryRestDays;

  /// No description provided for @summaryAbsences.
  ///
  /// In es, this message translates to:
  /// **'Ausencias'**
  String get summaryAbsences;

  /// No description provided for @summaryHolidayHours.
  ///
  /// In es, this message translates to:
  /// **'Horas en festivo'**
  String get summaryHolidayHours;

  /// No description provided for @summaryHolidayDetail.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 turno en festivo} other{{count} turnos en festivo}}'**
  String summaryHolidayDetail(int count);

  /// No description provided for @summaryOvertime.
  ///
  /// In es, this message translates to:
  /// **'Horas extra'**
  String get summaryOvertime;

  /// No description provided for @summaryEarlyLeave.
  ///
  /// In es, this message translates to:
  /// **'Salidas anticipadas'**
  String get summaryEarlyLeave;

  /// No description provided for @summaryExtrasPay.
  ///
  /// In es, this message translates to:
  /// **'{amount} en el estimado'**
  String summaryExtrasPay(String amount);

  /// No description provided for @summaryExtrasNoRate.
  ///
  /// In es, this message translates to:
  /// **'Hay horas extra o salidas en días sin turno con precio por hora: no están en el estimado.'**
  String get summaryExtrasNoRate;

  /// No description provided for @summaryNoteExtras.
  ///
  /// In es, this message translates to:
  /// **'Horas extra y salidas anticipadas: las que anotas en cada día. Las extra suman y las salidas restan de las horas trabajadas (un día no baja de 0 h). Se valoran al precio por hora del primer turno con precio de ese día.'**
  String get summaryNoteExtras;

  /// No description provided for @summaryDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día} other{{count} días}}'**
  String summaryDays(int count);

  /// No description provided for @summaryShifts.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 turno} other{{count} turnos}}'**
  String summaryShifts(int count);

  /// No description provided for @summaryNightOf.
  ///
  /// In es, this message translates to:
  /// **'{hours} nocturnas'**
  String summaryNightOf(String hours);

  /// No description provided for @summaryNoTimes.
  ///
  /// In es, this message translates to:
  /// **'sin horario'**
  String get summaryNoTimes;

  /// No description provided for @summaryNoRate.
  ///
  /// In es, this message translates to:
  /// **'sin precio'**
  String get summaryNoRate;

  /// No description provided for @summaryGroupWork.
  ///
  /// In es, this message translates to:
  /// **'Turnos de trabajo'**
  String get summaryGroupWork;

  /// No description provided for @summaryGroupRest.
  ///
  /// In es, this message translates to:
  /// **'Descansos'**
  String get summaryGroupRest;

  /// No description provided for @summaryEstimateTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresos estimados'**
  String get summaryEstimateTitle;

  /// No description provided for @summaryFixedPluses.
  ///
  /// In es, this message translates to:
  /// **'Pluses'**
  String get summaryFixedPluses;

  /// No description provided for @summaryFixedPlusCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 turno} other{{count} turnos}}'**
  String summaryFixedPlusCount(int count);

  /// No description provided for @summaryEstimateNote.
  ///
  /// In es, this message translates to:
  /// **'Estimado, antes de impuestos'**
  String get summaryEstimateNote;

  /// No description provided for @summaryEstimateNone.
  ///
  /// In es, this message translates to:
  /// **'Pon el precio por hora o el plus por turno en Mis turnos para ver el estimado.'**
  String get summaryEstimateNone;

  /// No description provided for @summaryEstimateMissing.
  ///
  /// In es, this message translates to:
  /// **'No incluye el pago por hora de {types}: sin precio.'**
  String summaryEstimateMissing(String types);

  /// No description provided for @summaryRateAction.
  ///
  /// In es, this message translates to:
  /// **'Poner precios en Mis turnos'**
  String get summaryRateAction;

  /// No description provided for @summaryDelta.
  ///
  /// In es, this message translates to:
  /// **'{delta} respecto a {month}'**
  String summaryDelta(String delta, String month);

  /// No description provided for @summaryDeltaSame.
  ///
  /// In es, this message translates to:
  /// **'Las mismas horas que en {month}'**
  String summaryDeltaSame(String month);

  /// No description provided for @summaryDeltaNone.
  ///
  /// In es, this message translates to:
  /// **'Sin turnos en {month} para comparar'**
  String summaryDeltaNone(String month);

  /// No description provided for @summaryNotesTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo se cuenta'**
  String get summaryNotesTitle;

  /// No description provided for @summaryNoteMidnight.
  ///
  /// In es, this message translates to:
  /// **'Las horas de un turno que cruza la medianoche se cuentan en el día y el mes en que empieza.'**
  String get summaryNoteMidnight;

  /// No description provided for @summaryNoteNight.
  ///
  /// In es, this message translates to:
  /// **'Nocturnas: de 22:00 a 06:00, salvo que marques otra cosa en el turno.'**
  String get summaryNoteNight;

  /// No description provided for @summaryNoteDst.
  ///
  /// In es, this message translates to:
  /// **'Son horas de reloj: en la noche del cambio de hora no se ajusta a 7 o 9 horas.'**
  String get summaryNoteDst;

  /// No description provided for @summaryNoteNoTimes.
  ///
  /// In es, this message translates to:
  /// **'Los turnos sin horario cuentan como turno, pero no suman horas.'**
  String get summaryNoteNoTimes;

  /// No description provided for @summaryNoteHoliday.
  ///
  /// In es, this message translates to:
  /// **'Horas en festivo: las que caen en un día festivo de tu comunidad y municipio, también si el turno cruza la medianoche.'**
  String get summaryNoteHoliday;

  /// No description provided for @summaryYearEmpty.
  ///
  /// In es, this message translates to:
  /// **'Este año no tiene turnos.'**
  String get summaryYearEmpty;

  /// No description provided for @summaryYearHint.
  ///
  /// In es, this message translates to:
  /// **'Toca un mes para ver su detalle.'**
  String get summaryYearHint;

  /// No description provided for @summaryYearHeaderMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get summaryYearHeaderMonth;

  /// No description provided for @summaryYearHeaderShifts.
  ///
  /// In es, this message translates to:
  /// **'Turnos'**
  String get summaryYearHeaderShifts;

  /// No description provided for @summaryYearHeaderHours.
  ///
  /// In es, this message translates to:
  /// **'Horas'**
  String get summaryYearHeaderHours;

  /// No description provided for @summaryYearHeaderNight.
  ///
  /// In es, this message translates to:
  /// **'Noct.'**
  String get summaryYearHeaderNight;

  /// No description provided for @summaryYearHeaderEstimate.
  ///
  /// In es, this message translates to:
  /// **'Estimado'**
  String get summaryYearHeaderEstimate;

  /// No description provided for @summaryYearTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get summaryYearTotal;

  /// Importe de un mes en la lista del año con texto grande.
  ///
  /// In es, this message translates to:
  /// **'{amount} estimado'**
  String summaryYearEstimated(String amount);

  /// No description provided for @summaryYearMonthEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin turnos'**
  String get summaryYearMonthEmpty;

  /// No description provided for @summaryYearRowTitle.
  ///
  /// In es, this message translates to:
  /// **'Horas y estimado'**
  String get summaryYearRowTitle;

  /// No description provided for @summaryYearRowBody.
  ///
  /// In es, this message translates to:
  /// **'Turnos, horas y euros de cada mes'**
  String get summaryYearRowBody;

  /// No description provided for @summaryYearMonthSemantics.
  ///
  /// In es, this message translates to:
  /// **'{month}: {shifts}, {hours}'**
  String summaryYearMonthSemantics(String month, String shifts, String hours);

  /// No description provided for @shareMonthTooltip.
  ///
  /// In es, this message translates to:
  /// **'Compartir el mes como imagen'**
  String get shareMonthTooltip;

  /// No description provided for @shareMonthSubject.
  ///
  /// In es, this message translates to:
  /// **'Mis turnos de {month}'**
  String shareMonthSubject(String month);

  /// No description provided for @shareMonthFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido compartir la imagen'**
  String get shareMonthFailed;

  /// No description provided for @shareMonthLegendTitle.
  ///
  /// In es, this message translates to:
  /// **'Turnos del mes'**
  String get shareMonthLegendTitle;

  /// No description provided for @shareMonthLegendEmpty.
  ///
  /// In es, this message translates to:
  /// **'Este mes no tiene turnos.'**
  String get shareMonthLegendEmpty;

  /// Aviso (SnackBar) cuando falla escribir un cambio en la base de datos; el calendario ya muestra lo que hay guardado.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido guardar el cambio'**
  String get saveFailed;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsOpenTooltip.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get settingsOpenTooltip;

  /// No description provided for @settingsSectionSchedule.
  ///
  /// In es, this message translates to:
  /// **'Tu cuadrante'**
  String get settingsSectionSchedule;

  /// No description provided for @settingsShiftsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis turnos'**
  String get settingsShiftsTitle;

  /// No description provided for @settingsShiftsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Colores, códigos y horas'**
  String get settingsShiftsSubtitle;

  /// No description provided for @settingsCalendarsTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendarios'**
  String get settingsCalendarsTitle;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeSystemLight.
  ///
  /// In es, this message translates to:
  /// **'Sistema (claro)'**
  String get settingsThemeSystemLight;

  /// No description provided for @settingsThemeSystemDark.
  ///
  /// In es, this message translates to:
  /// **'Sistema (oscuro)'**
  String get settingsThemeSystemDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get settingsThemeDark;

  /// No description provided for @settingsWeekStartTitle.
  ///
  /// In es, this message translates to:
  /// **'Primer día de la semana'**
  String get settingsWeekStartTitle;

  /// No description provided for @settingsWeekStartMonday.
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get settingsWeekStartMonday;

  /// No description provided for @settingsWeekStartSunday.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get settingsWeekStartSunday;

  /// No description provided for @settingsWeekNumbersTitle.
  ///
  /// In es, this message translates to:
  /// **'Mostrar número de semana'**
  String get settingsWeekNumbersTitle;

  /// No description provided for @settingsWeekNumbersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Una columna a la izquierda del mes'**
  String get settingsWeekNumbersSubtitle;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguageTitle;

  /// Opción «seguir el idioma del móvil», con el idioma que da ahora, p. ej. «Sistema (Español)».
  ///
  /// In es, this message translates to:
  /// **'Sistema ({language})'**
  String settingsLanguageSystem(String language);

  /// Nombre del idioma en su propia lengua: igual en todos los idiomas de la app.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageNameEs;

  /// Nombre del idioma en su propia lengua: igual en todos los idiomas de la app.
  ///
  /// In es, this message translates to:
  /// **'Català'**
  String get languageNameCa;

  /// Nombre del idioma en su propia lengua: igual en todos los idiomas de la app.
  ///
  /// In es, this message translates to:
  /// **'Galego'**
  String get languageNameGl;

  /// Nombre del idioma en su propia lengua: igual en todos los idiomas de la app.
  ///
  /// In es, this message translates to:
  /// **'Euskara'**
  String get languageNameEu;

  /// Nombre del idioma en su propia lengua: igual en todos los idiomas de la app.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido guardar el ajuste. Prueba otra vez.'**
  String get settingsSaveFailed;

  /// No description provided for @settingsSectionMore.
  ///
  /// In es, this message translates to:
  /// **'Avisos y datos'**
  String get settingsSectionMore;

  /// No description provided for @settingsHolidaysTitle.
  ///
  /// In es, this message translates to:
  /// **'Festivos'**
  String get settingsHolidaysTitle;

  /// No description provided for @settingsAlarmsTitle.
  ///
  /// In es, this message translates to:
  /// **'Alarmas'**
  String get settingsAlarmsTitle;

  /// No description provided for @settingsBackupTitle.
  ///
  /// In es, this message translates to:
  /// **'Copia de seguridad'**
  String get settingsBackupTitle;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se abre en tu navegador'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsPrivacyOpenFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido abrir la política de privacidad. Prueba otra vez.'**
  String get settingsPrivacyOpenFailed;

  /// No description provided for @faqAlarmsQIos.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo configuro las alarmas y qué es el permiso de notificaciones?'**
  String get faqAlarmsQIos;

  /// No description provided for @faqAlarmsAIos.
  ///
  /// In es, this message translates to:
  /// **'En Ajustes › Alarmas activa «Avisar antes de cada turno», elige cuánto antes y, si quieres, un aviso el día anterior a una hora fija. En el detalle de un día puedes quitar su alarma con «Sin alarma este día».\n\nSin el permiso de notificaciones, Cuadrante no puede avisarte. Si no te sale la ventana para permitirlas, actívalas en los ajustes del sistema.'**
  String get faqAlarmsAIos;

  /// No description provided for @faqWidgetAIos.
  ///
  /// In es, this message translates to:
  /// **'En Ajustes › Añadir widget ves los tamaños (pequeño: hoy y mañana; mediano: los próximos 7 días; grande: el mes entero) y cómo colocarlo. Mantén pulsada la pantalla de inicio, toca el + de arriba y busca Cuadrante.\n\nEl widget guarda tus próximos días. El sistema decide cuándo lo actualiza y puede retrasar el cambio de día. Si se queda sin datos, abre Cuadrante para ponerlo al día.'**
  String get faqWidgetAIos;

  /// No description provided for @settingsSectionHelp.
  ///
  /// In es, this message translates to:
  /// **'Ayuda'**
  String get settingsSectionHelp;

  /// No description provided for @settingsHelpTitle.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y contacto'**
  String get settingsHelpTitle;

  /// No description provided for @settingsHelpSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Escríbenos si algo no va bien'**
  String get settingsHelpSubtitle;

  /// No description provided for @settingsHelpBody.
  ///
  /// In es, this message translates to:
  /// **'¿Dudas o algo no va bien? Cuéntanos qué te pasa y qué versión usas.'**
  String get settingsHelpBody;

  /// No description provided for @settingsHelpSubtitleSoon.
  ///
  /// In es, this message translates to:
  /// **'Estamos preparando el correo de soporte'**
  String get settingsHelpSubtitleSoon;

  /// No description provided for @settingsHelpBodySoon.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tenemos correo de soporte. Mientras tanto, mira las preguntas frecuentes y, si algo no va bien, ten a mano la versión que usas.'**
  String get settingsHelpBodySoon;

  /// No description provided for @settingsHelpNoEmail.
  ///
  /// In es, this message translates to:
  /// **'El correo de soporte llegará con la versión de la tienda.'**
  String get settingsHelpNoEmail;

  /// No description provided for @settingsHelpCopyEmail.
  ///
  /// In es, this message translates to:
  /// **'Copiar correo'**
  String get settingsHelpCopyEmail;

  /// No description provided for @settingsHelpCopyVersion.
  ///
  /// In es, this message translates to:
  /// **'Copiar versión'**
  String get settingsHelpCopyVersion;

  /// No description provided for @settingsFaqTitle.
  ///
  /// In es, this message translates to:
  /// **'Preguntas frecuentes'**
  String get settingsFaqTitle;

  /// No description provided for @settingsFaqSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pintar, rotaciones, alarmas, widget y más'**
  String get settingsFaqSubtitle;

  /// No description provided for @faqIntro.
  ///
  /// In es, this message translates to:
  /// **'Respuestas rápidas sobre cómo funciona Cuadrante. Todo está en este dispositivo: no hace falta cuenta ni conexión.'**
  String get faqIntro;

  /// No description provided for @faqNotFound.
  ///
  /// In es, this message translates to:
  /// **'¿No encuentras lo que buscas?'**
  String get faqNotFound;

  /// No description provided for @faqContact.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y contacto'**
  String get faqContact;

  /// No description provided for @faqPaintQ.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo pinto el mes?'**
  String get faqPaintQ;

  /// No description provided for @faqPaintA.
  ///
  /// In es, this message translates to:
  /// **'Pulsa «Pintar» en el calendario, elige un turno abajo y toca los días o pasa el dedo por ellos. Para vaciar un día usa «Borrar». Cada trazo se puede deshacer y rehacer con las flechas de la barra. Pulsa «Listo» cuando termines.\n\nSi tocas un día sin estar pintando se abre su detalle: ahí cambias el turno, añades una nota o vuelves al patrón. Si mantienes pulsado un día empiezas a elegir varios a la vez: puedes ponerles turno, copiarlos, cortarlos y pegarlos, o repetir una semana.'**
  String get faqPaintA;

  /// No description provided for @faqPatternQ.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo aplico una rotación y qué es el desfase?'**
  String get faqPatternQ;

  /// No description provided for @faqPatternA.
  ///
  /// In es, this message translates to:
  /// **'En modo pintar pulsa el botón «Patrón» y sigue los pasos: elige tu rotación (o crea la tuya), el día en que empiezas y hasta cuándo se repite.\n\nEl desfase es el punto del ciclo en el que estás el día de inicio. Si ese día te toca la noche, en el paso «¿En qué día del ciclo estás ese día?» tocas la noche y el resto se ajusta solo. Los días que ya cambiaste a mano se respetan o se sustituyen, como prefieras. Para terminar o quitar una rotación ve a Ajustes › Mis rotaciones.'**
  String get faqPatternA;

  /// No description provided for @faqDoubleQ.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo doblo un turno?'**
  String get faqDoubleQ;

  /// No description provided for @faqDoubleA.
  ///
  /// In es, this message translates to:
  /// **'Doblar es hacer dos turnos el mismo día. Toca el día y, en su detalle, usa «Doblar con otro turno». Si estás pintando, activa «Doblar» y toca los días. Con varios días elegidos, «Doblar con…» añade el turno a todos.\n\nUn día puede llevar los turnos que necesites y cada uno suma sus horas por separado.'**
  String get faqDoubleA;

  /// No description provided for @faqPostNightQ.
  ///
  /// In es, this message translates to:
  /// **'¿Qué es el saliente automático?'**
  String get faqPostNightQ;

  /// No description provided for @faqPostNightA.
  ///
  /// In es, this message translates to:
  /// **'Es el descanso del día siguiente a una noche. Si lo activas en Ajustes › Saliente automático, al pintar o aplicar una noche el día siguiente pasa a Saliente cuando estaba vacío o libre. Los días que ya tenían otro turno no se tocan. Viene apagado.'**
  String get faqPostNightA;

  /// No description provided for @faqNotesQ.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo uso las notas y la agenda?'**
  String get faqNotesQ;

  /// No description provided for @faqNotesA.
  ///
  /// In es, this message translates to:
  /// **'Toca un día y escribe en el campo de la nota; los días con nota se marcan en el calendario. Abre la agenda desde arriba del calendario: «Notas» reúne tus notas y festivos propios; «Turnos» muestra los turnos próximos.\n\nBusca por texto, sin importar mayúsculas ni tildes, o por fecha: por ejemplo, 15/10 o 15 oct. La búsqueda incluye todas tus notas y festivos propios, y los turnos desde hace un año hasta dentro de un año.'**
  String get faqNotesA;

  /// No description provided for @faqAlarmsQ.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo configuro las alarmas y qué es el permiso de alarmas exactas?'**
  String get faqAlarmsQ;

  /// No description provided for @faqAlarmsA.
  ///
  /// In es, this message translates to:
  /// **'En Ajustes › Alarmas activa «Avisar antes de cada turno», elige cuánto antes y, si quieres, un aviso el día anterior a una hora fija. En el detalle de un día puedes quitar su alarma con «Sin alarma este día».\n\nEn Android hacen falta las notificaciones y el permiso «Alarmas y recordatorios» de los ajustes del sistema: sin él, Android puede retrasar el aviso unos minutos. La pantalla de alarmas te dice qué falta y te lleva a los ajustes. Si tu móvil ahorra batería de forma agresiva, deja Cuadrante sin restricciones para que no pare los avisos.'**
  String get faqAlarmsA;

  /// No description provided for @faqHolidaysQ.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo añado un festivo local?'**
  String get faqHolidaysQ;

  /// No description provided for @faqHolidaysA.
  ///
  /// In es, this message translates to:
  /// **'En Ajustes › Festivos elige tu comunidad y tu municipio y verás los festivos que te tocan. Si falta el de tu pueblo, toca ese día en el calendario y activa «Festivo propio»: le pones nombre y desde ese momento cuenta como festivo.\n\nTambién puedes usar «Traer festivos del calendario del móvil» en Ajustes › Festivos. Elige los calendarios y las fechas y revisa la vista previa: solo se leen eventos de día completo, se omiten los festivos que ya tienes y puedes deshacer. No se cambian los eventos del calendario.'**
  String get faqHolidaysA;

  /// No description provided for @faqWidgetQ.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo añado el widget y por qué cambia solo?'**
  String get faqWidgetQ;

  /// No description provided for @faqWidgetA.
  ///
  /// In es, this message translates to:
  /// **'En Ajustes › Añadir widget ves los tamaños (pequeño: hoy y mañana; mediano: los próximos 7 días; grande: el mes entero) y cómo colocarlo. En Android, mantén pulsada una zona vacía de la pantalla de inicio, elige Widgets y busca Cuadrante.\n\nEl widget siempre enseña el día de hoy: cambia de día a medianoche aunque no abras la app, porque lleva guardados tus próximos días. Si pasa mucho tiempo sin abrir Cuadrante se queda sin datos y te pide abrir la app para ponerse al día.'**
  String get faqWidgetA;

  /// No description provided for @faqBackupQ.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo hago una copia y cambio de dispositivo?'**
  String get faqBackupQ;

  /// No description provided for @faqBackupA.
  ///
  /// In es, this message translates to:
  /// **'Ajustes › Copia de seguridad guarda copias automáticas en este dispositivo después de cada cambio, pero se pierden si lo pierdes o desinstalas la app. Exporta un archivo con «Exportar archivo» y guárdalo en Drive o envíatelo por WhatsApp o correo.\n\nPara cambiar de dispositivo: exporta el archivo, instala Cuadrante en el nuevo, abre el archivo con la app (o usa «Importar archivo» en la copia de seguridad) y revisa la vista previa antes de restaurar. «Probar restauración» comprueba que tu última copia se puede recuperar entera.'**
  String get faqBackupA;

  /// No description provided for @faqImportQ.
  ///
  /// In es, this message translates to:
  /// **'¿Puedo importar o exportar mis turnos al calendario?'**
  String get faqImportQ;

  /// No description provided for @faqImportA.
  ///
  /// In es, this message translates to:
  /// **'Sí. En Ajustes › Importar turnos puedes traer una copia «.Shifter» de LRHSoft, turnos del calendario del móvil, un archivo .ics o un CSV. Para LRHSoft, crea una copia en Menú › Copia de seguridad › Copia local y elige el archivo de Documents › ShifterBackups. Revisa las fechas, los tipos de turno y la vista previa antes de importar.\n\n«Exportar al calendario del móvil» copia tus turnos una vez a un calendario del teléfono. Si exportas otra vez no se duplican: solo se tocan los eventos que creó Cuadrante.'**
  String get faqImportA;

  /// No description provided for @faqCalendarsQ.
  ///
  /// In es, this message translates to:
  /// **'¿Puedo llevar varios calendarios y compararlos?'**
  String get faqCalendarsQ;

  /// No description provided for @faqCalendarsA.
  ///
  /// In es, this message translates to:
  /// **'Sí. En Ajustes › Calendarios creas uno para tu pareja, un segundo trabajo o un hijo: cada uno tiene sus rotaciones y sus días, y los tipos de turno son los mismos. Con dos o más, el nombre del calendario sobre el mes te deja cambiar de uno a otro. El widget y las alarmas siguen el calendario marcado como «Widget y alarmas».\n\nPara ver cuándo coincidís libres, pulsa «Comparar calendarios» en esa misma hoja: eliges dos y ves sus turnos juntos y los días libres en común del mes.'**
  String get faqCalendarsA;

  /// No description provided for @faqSummaryQ.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo se calculan las horas y los euros?'**
  String get faqSummaryQ;

  /// No description provided for @faqSummaryA.
  ///
  /// In es, this message translates to:
  /// **'El icono de resumen del calendario enseña los turnos, las horas, las nocturnas y las de festivo del mes, de un año entero o de las fechas que elijas en «Fechas…» (hasta 366 días). Un turno cuenta en el día en que empieza, aunque cruce la medianoche.\n\nPara ver euros, pon el precio por hora y, si lo tienes, el plus fijo por tipo de turno en Ajustes › Mis turnos. La estimación incluye esos pluses fijos, antes de impuestos. No incluye pluses por hora nocturna o festiva ni retenciones.\n\nEl «Plus por turno» se suma una vez por cada turno trabajado de ese tipo, también si es partido; no depende de las horas. Los descansos y las ausencias no lo suman.'**
  String get faqSummaryA;

  /// No description provided for @settingsVersionCopied.
  ///
  /// In es, this message translates to:
  /// **'Versión copiada'**
  String get settingsVersionCopied;

  /// No description provided for @settingsEmailCopied.
  ///
  /// In es, this message translates to:
  /// **'Correo copiado'**
  String get settingsEmailCopied;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String settingsAboutVersion(String version);

  /// No description provided for @settingsAboutVersionDev.
  ///
  /// In es, this message translates to:
  /// **'Versión de desarrollo'**
  String get settingsAboutVersionDev;

  /// No description provided for @settingsAboutTagline.
  ///
  /// In es, this message translates to:
  /// **'Cuadrante funciona sin conexión y sin cuenta: tus turnos se quedan en tu móvil.'**
  String get settingsAboutTagline;

  /// No description provided for @settingsAboutLicenses.
  ///
  /// In es, this message translates to:
  /// **'Licencias de código abierto'**
  String get settingsAboutLicenses;

  /// Lectura en voz alta del número de semana ISO de una fila del mes.
  ///
  /// In es, this message translates to:
  /// **'Semana {number}'**
  String calendarWeekNumberSemantics(int number);

  /// No description provided for @importSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar y exportar'**
  String get importSectionTitle;

  /// No description provided for @importRowTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar turnos'**
  String get importRowTitle;

  /// No description provided for @importRowSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Copia de LRHSoft, calendario del móvil, .ics o CSV'**
  String get importRowSubtitle;

  /// No description provided for @calExportRowTitle.
  ///
  /// In es, this message translates to:
  /// **'Exportar turnos'**
  String get calExportRowTitle;

  /// No description provided for @calExportRowSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Al calendario del móvil, sin duplicados'**
  String get calExportRowSubtitle;

  /// No description provided for @importTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar turnos'**
  String get importTitle;

  /// No description provided for @importStepOf.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String importStepOf(int current, int total);

  /// No description provided for @importNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get importNext;

  /// No description provided for @importReading.
  ///
  /// In es, this message translates to:
  /// **'Leyendo…'**
  String get importReading;

  /// No description provided for @importSourceTitle.
  ///
  /// In es, this message translates to:
  /// **'¿De dónde vienen tus turnos?'**
  String get importSourceTitle;

  /// No description provided for @importSourceHelp.
  ///
  /// In es, this message translates to:
  /// **'Cuadrante lee los eventos aquí mismo, en tu móvil, y no los envía a ningún sitio. Tú decides qué se importa.'**
  String get importSourceHelp;

  /// No description provided for @importSourceDevice.
  ///
  /// In es, this message translates to:
  /// **'Calendario del móvil'**
  String get importSourceDevice;

  /// No description provided for @importSourceDeviceHelp.
  ///
  /// In es, this message translates to:
  /// **'Google, iCloud, Outlook… lo que tengas en la app de calendario.'**
  String get importSourceDeviceHelp;

  /// No description provided for @importSourceIcs.
  ///
  /// In es, this message translates to:
  /// **'Archivo .ics'**
  String get importSourceIcs;

  /// No description provided for @importSourceIcsHelp.
  ///
  /// In es, this message translates to:
  /// **'Un calendario exportado, con un turno por evento.'**
  String get importSourceIcsHelp;

  /// No description provided for @importSourceCsv.
  ///
  /// In es, this message translates to:
  /// **'Archivo CSV'**
  String get importSourceCsv;

  /// No description provided for @importSourceCsvHelp.
  ///
  /// In es, this message translates to:
  /// **'Una hoja con una fecha y un turno en cada fila.'**
  String get importSourceCsvHelp;

  /// No description provided for @importSourceLrhsoft.
  ///
  /// In es, this message translates to:
  /// **'Copia de LRHSoft (Calendario de Turnos)'**
  String get importSourceLrhsoft;

  /// No description provided for @importSourceLrhsoftHelp.
  ///
  /// In es, this message translates to:
  /// **'El archivo .Shifter de tu copia local'**
  String get importSourceLrhsoftHelp;

  /// No description provided for @importFileLrhsoft.
  ///
  /// In es, this message translates to:
  /// **'Copia de LRHSoft'**
  String get importFileLrhsoft;

  /// No description provided for @importHowToTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Vienes de LRHSoft o Supershift?'**
  String get importHowToTitle;

  /// No description provided for @importHowToBody.
  ///
  /// In es, this message translates to:
  /// **'LRHSoft o Shifter: en la app, Menú › Copia de seguridad › Copia local. Después elige aquí ese archivo .Shifter: está en la memoria del móvil, en Documents › ShifterBackups.\nSupershift: exporta tus turnos al calendario del móvil y elige «Calendario del móvil».'**
  String get importHowToBody;

  /// No description provided for @calExportPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Falta el permiso del calendario'**
  String get calExportPermissionTitle;

  /// No description provided for @calExportPermissionReadBody.
  ///
  /// In es, this message translates to:
  /// **'Para importar, Cuadrante necesita leer los eventos de tus calendarios. Solo lo hace ahora, mientras importas, y no guarda nada fuera del móvil.'**
  String get calExportPermissionReadBody;

  /// No description provided for @calExportPermissionWriteBody.
  ///
  /// In es, this message translates to:
  /// **'Para añadir tus turnos, Cuadrante necesita acceso a tus calendarios. Solo añade o cambia sus propios eventos, y solo cuando tú exportas. Si el calendario que elijas se sincroniza con una cuenta (Google, iCloud...), esa cuenta también recibirá los turnos.'**
  String get calExportPermissionWriteBody;

  /// No description provided for @calExportPermissionAgainBody.
  ///
  /// In es, this message translates to:
  /// **'No has dado el permiso. Sin él no podemos usar tus calendarios, pero puedes permitirlo ahora. Si lo rechazas otra vez, tendrás que activarlo en los ajustes del sistema.'**
  String get calExportPermissionAgainBody;

  /// No description provided for @calExportPermissionAllow.
  ///
  /// In es, this message translates to:
  /// **'Permitir acceso'**
  String get calExportPermissionAllow;

  /// No description provided for @calExportPermissionDeniedTitle.
  ///
  /// In es, this message translates to:
  /// **'El acceso al calendario está desactivado'**
  String get calExportPermissionDeniedTitle;

  /// No description provided for @calExportPermissionDeniedBody.
  ///
  /// In es, this message translates to:
  /// **'Actívalo en los ajustes del sistema (Permisos › Calendario) y vuelve aquí.'**
  String get calExportPermissionDeniedBody;

  /// No description provided for @calExportPermissionSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get calExportPermissionSettings;

  /// No description provided for @calExportPermissionRecheck.
  ///
  /// In es, this message translates to:
  /// **'Comprobar de nuevo'**
  String get calExportPermissionRecheck;

  /// No description provided for @calExportPermissionRestrictedTitle.
  ///
  /// In es, this message translates to:
  /// **'Este móvil no deja usar el calendario'**
  String get calExportPermissionRestrictedTitle;

  /// No description provided for @calExportPermissionRestrictedBody.
  ///
  /// In es, this message translates to:
  /// **'Puede ser un control parental o un perfil de trabajo. Si importas, prueba con un archivo .ics.'**
  String get calExportPermissionRestrictedBody;

  /// No description provided for @calExportPermissionWriteOnlyBody.
  ///
  /// In es, this message translates to:
  /// **'El sistema solo ha dado permiso para añadir eventos. Cuadrante necesita acceso completo para leer los calendarios o para sustituir los eventos de una exportación anterior.'**
  String get calExportPermissionWriteOnlyBody;

  /// No description provided for @importCalendarsTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige los calendarios'**
  String get importCalendarsTitle;

  /// No description provided for @importCalendarsHelp.
  ///
  /// In es, this message translates to:
  /// **'Marca de dónde vienen tus turnos. Los demás no se tocan.'**
  String get importCalendarsHelp;

  /// No description provided for @importCalendarsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay calendarios en este móvil.'**
  String get importCalendarsEmpty;

  /// No description provided for @importCalendarsNoAccount.
  ///
  /// In es, this message translates to:
  /// **'Sin cuenta'**
  String get importCalendarsNoAccount;

  /// No description provided for @importCalendarsReadOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo lectura'**
  String get importCalendarsReadOnly;

  /// No description provided for @importCalendarSemantics.
  ///
  /// In es, this message translates to:
  /// **'{name}, {account}'**
  String importCalendarSemantics(String name, String account);

  /// No description provided for @importRangeTitle.
  ///
  /// In es, this message translates to:
  /// **'¿De qué fechas?'**
  String get importRangeTitle;

  /// No description provided for @importRangeHelp.
  ///
  /// In es, this message translates to:
  /// **'Solo se miran los eventos de estos días.'**
  String get importRangeHelp;

  /// No description provided for @importRangeFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get importRangeFrom;

  /// No description provided for @importRangeTo.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get importRangeTo;

  /// No description provided for @importRangeDefault.
  ///
  /// In es, this message translates to:
  /// **'Últimos 12 meses y próximos 6'**
  String get importRangeDefault;

  /// No description provided for @importRangeInvalid.
  ///
  /// In es, this message translates to:
  /// **'La fecha final no puede ser anterior a la inicial.'**
  String get importRangeInvalid;

  /// No description provided for @importRangeClamped.
  ///
  /// In es, this message translates to:
  /// **'El máximo son 5 años: se ha recortado el principio.'**
  String get importRangeClamped;

  /// No description provided for @importRangeFile.
  ///
  /// In es, this message translates to:
  /// **'Archivo: {name}'**
  String importRangeFile(String name);

  /// No description provided for @importRangeFileEvents.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{El archivo trae 1 evento.} other{El archivo trae {count} eventos.}}'**
  String importRangeFileEvents(int count);

  /// No description provided for @importRangeFileSkipped.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 evento no tiene una fecha válida y no se leerá.} other{{count} eventos no tienen una fecha válida y no se leerán.}}'**
  String importRangeFileSkipped(int count);

  /// No description provided for @importRangeFileRules.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 evento tiene una repetición que no entendemos y cuenta una sola vez.} other{{count} eventos tienen una repetición que no entendemos y cuentan una sola vez.}}'**
  String importRangeFileRules(int count);

  /// No description provided for @importColumnsTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué es cada columna?'**
  String get importColumnsTitle;

  /// No description provided for @importColumnsHelp.
  ///
  /// In es, this message translates to:
  /// **'Mira las primeras filas y confirma cuál es la fecha y cuál el turno.'**
  String get importColumnsHelp;

  /// No description provided for @importColumnsHeader.
  ///
  /// In es, this message translates to:
  /// **'La primera fila son los títulos'**
  String get importColumnsHeader;

  /// No description provided for @importColumnDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get importColumnDate;

  /// No description provided for @importColumnTitle.
  ///
  /// In es, this message translates to:
  /// **'Turno o código'**
  String get importColumnTitle;

  /// No description provided for @importColumnStart.
  ///
  /// In es, this message translates to:
  /// **'Hora de inicio (opcional)'**
  String get importColumnStart;

  /// No description provided for @importColumnEnd.
  ///
  /// In es, this message translates to:
  /// **'Hora de fin (opcional)'**
  String get importColumnEnd;

  /// No description provided for @importColumnNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguna'**
  String get importColumnNone;

  /// No description provided for @importColumnNumber.
  ///
  /// In es, this message translates to:
  /// **'Columna {number}'**
  String importColumnNumber(int number);

  /// No description provided for @importColumnNamed.
  ///
  /// In es, this message translates to:
  /// **'{number}: {name}'**
  String importColumnNamed(int number, String name);

  /// No description provided for @importColumnsScrollHint.
  ///
  /// In es, this message translates to:
  /// **'Desliza hacia los lados para ver todas las columnas.'**
  String get importColumnsScrollHint;

  /// No description provided for @importColumnsPreview.
  ///
  /// In es, this message translates to:
  /// **'Primeras filas'**
  String get importColumnsPreview;

  /// No description provided for @importMappingTitle.
  ///
  /// In es, this message translates to:
  /// **'¿A qué turno corresponde cada título?'**
  String get importMappingTitle;

  /// No description provided for @importMappingHelp.
  ///
  /// In es, this message translates to:
  /// **'Agrupamos los eventos por título. Elige uno de tus turnos, crea uno nuevo o ignóralos.'**
  String get importMappingHelp;

  /// No description provided for @importMappingSummary.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, =1{1 día} other{{days} días}} en {groups, plural, =1{1 título} other{{groups} títulos}}'**
  String importMappingSummary(int days, int groups);

  /// No description provided for @importMappingTruncated.
  ///
  /// In es, this message translates to:
  /// **'Hay más de {limit} eventos: solo se han leído los primeros. Acorta las fechas para ver el resto.'**
  String importMappingTruncated(String limit);

  /// No description provided for @importMappingSkippedRows.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 fila se ha saltado por no tener una fecha o un turno válidos (por ejemplo, la línea {line}).} other{{count} filas se han saltado por no tener una fecha o un turno válidos (por ejemplo, la línea {line}).}}'**
  String importMappingSkippedRows(int count, int line);

  /// No description provided for @importMappingNothing.
  ///
  /// In es, this message translates to:
  /// **'Elige al menos un título para importar.'**
  String get importMappingNothing;

  /// No description provided for @importGroupDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día} other{{count} días}}'**
  String importGroupDays(int count);

  /// No description provided for @importGroupAllDay.
  ///
  /// In es, this message translates to:
  /// **'Todo el día'**
  String get importGroupAllDay;

  /// No description provided for @importGroupExamples.
  ///
  /// In es, this message translates to:
  /// **'p. ej. {dates}'**
  String importGroupExamples(String dates);

  /// No description provided for @importGroupUntitled.
  ///
  /// In es, this message translates to:
  /// **'Sin título'**
  String get importGroupUntitled;

  /// No description provided for @importMapIgnore.
  ///
  /// In es, this message translates to:
  /// **'Ignorar'**
  String get importMapIgnore;

  /// No description provided for @importMapCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear tipo nuevo'**
  String get importMapCreate;

  /// No description provided for @importMapChoose.
  ///
  /// In es, this message translates to:
  /// **'Elegir turno'**
  String get importMapChoose;

  /// No description provided for @importMapSuggested.
  ///
  /// In es, this message translates to:
  /// **'Sugerido'**
  String get importMapSuggested;

  /// No description provided for @importMapNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo: {name}'**
  String importMapNew(String name);

  /// No description provided for @importMapPickTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué turno es «{title}»?'**
  String importMapPickTitle(String title);

  /// No description provided for @importMapSemantics.
  ///
  /// In es, this message translates to:
  /// **'{title}: {choice}'**
  String importMapSemantics(String title, String choice);

  /// No description provided for @importNewTypeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tipo de turno nuevo'**
  String get importNewTypeTitle;

  /// No description provided for @importNewTypeUse.
  ///
  /// In es, this message translates to:
  /// **'Usar este tipo'**
  String get importNewTypeUse;

  /// No description provided for @importPreviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Así quedará'**
  String get importPreviewTitle;

  /// No description provided for @importPreviewHelp.
  ///
  /// In es, this message translates to:
  /// **'Revisa los meses. No se guarda nada hasta que pulses Importar.'**
  String get importPreviewHelp;

  /// No description provided for @importPreviewTarget.
  ///
  /// In es, this message translates to:
  /// **'Se importa en «{name}».'**
  String importPreviewTarget(String name);

  /// No description provided for @importPreviewDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se escribirá 1 día.} other{Se escribirán {count} días.}}'**
  String importPreviewDays(int count);

  /// No description provided for @importPreviewUnchanged.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día ya estaba igual.} other{{count} días ya estaban igual.}}'**
  String importPreviewUnchanged(int count);

  /// No description provided for @importPreviewNewTypes.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se creará 1 tipo de turno nuevo.} other{Se crearán {count} tipos de turno nuevos.}}'**
  String importPreviewNewTypes(int count);

  /// No description provided for @importPreviewEmpty.
  ///
  /// In es, this message translates to:
  /// **'Con estas elecciones no cambia ningún día.'**
  String get importPreviewEmpty;

  /// No description provided for @importPreviewMoreMonths.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Y 1 mes más sin mostrar.} other{Y {count} meses más sin mostrar.}}'**
  String importPreviewMoreMonths(int count);

  /// No description provided for @importConflictsTitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día ya tiene turno} other{{count} días ya tienen turno}}'**
  String importConflictsTitle(int count);

  /// No description provided for @importConflictsHelp.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hacemos con ellos?'**
  String get importConflictsHelp;

  /// No description provided for @importConflictReplace.
  ///
  /// In es, this message translates to:
  /// **'Sustituir'**
  String get importConflictReplace;

  /// No description provided for @importConflictKeep.
  ///
  /// In es, this message translates to:
  /// **'Mantener lo mío'**
  String get importConflictKeep;

  /// No description provided for @importConflictsExamples.
  ///
  /// In es, this message translates to:
  /// **'Por ejemplo: {dates}'**
  String importConflictsExamples(String dates);

  /// No description provided for @importApply.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Importar 1 día} other{Importar {count} días}}'**
  String importApply(int count);

  /// No description provided for @importApplied.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se ha importado 1 día.} other{Se han importado {count} días.}}'**
  String importApplied(int count);

  /// No description provided for @importAppliedWithTypes.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, =1{Se ha importado 1 día} other{Se han importado {days} días}} y {types, plural, =1{1 tipo de turno nuevo} other{{types} tipos de turno nuevos}}.'**
  String importAppliedWithTypes(int days, int types);

  /// No description provided for @importUndoDone.
  ///
  /// In es, this message translates to:
  /// **'Se ha deshecho la importación.'**
  String get importUndoDone;

  /// No description provided for @importUndoKeptTypes.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se queda el tipo «{names}»: algo lo usa.} other{Se quedan los tipos «{names}»: algo los usa.}}'**
  String importUndoKeptTypes(int count, String names);

  /// No description provided for @importApplyFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido importar. Prueba otra vez.'**
  String get importApplyFailed;

  /// No description provided for @importProblemPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'Sin el permiso no podemos leer tus calendarios.'**
  String get importProblemPermissionDenied;

  /// No description provided for @importProblemPermissionRestricted.
  ///
  /// In es, this message translates to:
  /// **'Este móvil no deja a Cuadrante usar el calendario. Prueba con un archivo.'**
  String get importProblemPermissionRestricted;

  /// No description provided for @importProblemCalendarUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Este móvil no tiene calendarios disponibles.'**
  String get importProblemCalendarUnavailable;

  /// No description provided for @importProblemReadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se han podido leer los eventos. Prueba otra vez.'**
  String get importProblemReadFailed;

  /// No description provided for @importProblemFileTooLarge.
  ///
  /// In es, this message translates to:
  /// **'El archivo pesa más de 5 MB. Al exportarlo, elige menos fechas.'**
  String get importProblemFileTooLarge;

  /// No description provided for @importProblemFileUnreadable.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido abrir ese archivo. Aceptamos .csv, .ics y la copia .Shifter de LRHSoft.'**
  String get importProblemFileUnreadable;

  /// No description provided for @importProblemNotCalendar.
  ///
  /// In es, this message translates to:
  /// **'Ese archivo no parece un calendario .ics.'**
  String get importProblemNotCalendar;

  /// No description provided for @importProblemNotCsv.
  ///
  /// In es, this message translates to:
  /// **'No hemos encontrado una columna de fechas en ese CSV.'**
  String get importProblemNotCsv;

  /// No description provided for @importProblemNoEvents.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos en esas fechas.'**
  String get importProblemNoEvents;

  /// No description provided for @importProblemTooComplex.
  ///
  /// In es, this message translates to:
  /// **'Ese archivo es demasiado grande o complicado y tarda demasiado. Al exportarlo, elige menos fechas.'**
  String get importProblemTooComplex;

  /// No description provided for @importProblemUnknown.
  ///
  /// In es, this message translates to:
  /// **'Algo no ha ido bien al leer el archivo. Prueba con otro.'**
  String get importProblemUnknown;

  /// No description provided for @importProblemNotLrhsoft.
  ///
  /// In es, this message translates to:
  /// **'Ese archivo no parece una copia de LRHSoft (.Shifter). Prueba a crear otra copia local.'**
  String get importProblemNotLrhsoft;

  /// No description provided for @importRangeLrhsoftDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{La copia trae 1 día.} other{La copia trae {count} días.}}'**
  String importRangeLrhsoftDays(int count);

  /// No description provided for @importMappingInvalidRows.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 fila no válida ignorada.} other{{count} filas no válidas ignoradas.}}'**
  String importMappingInvalidRows(int count);

  /// No description provided for @importLrhsoftNotImported.
  ///
  /// In es, this message translates to:
  /// **'No se traen las alarmas, los dibujos, las fotos ni las horas extra.'**
  String get importLrhsoftNotImported;

  /// No description provided for @importNoteCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 nota} other{{count} notas}}'**
  String importNoteCount(int count);

  /// No description provided for @importApplyNotes.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Importar 1 nota} other{Importar {count} notas}}'**
  String importApplyNotes(int count);

  /// No description provided for @importAppliedNotes.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se ha importado 1 nota.} other{Se han importado {count} notas.}}'**
  String importAppliedNotes(int count);

  /// No description provided for @importPreviewNotes.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se añadirá 1 nota.} other{Se añadirán {count} notas.}}'**
  String importPreviewNotes(int count);

  /// No description provided for @calExportTitle.
  ///
  /// In es, this message translates to:
  /// **'Exportar turnos'**
  String get calExportTitle;

  /// No description provided for @calExportHelp.
  ///
  /// In es, this message translates to:
  /// **'Añade tus turnos como eventos a un calendario del móvil, una sola vez. Si lo repites, Cuadrante sustituye sus eventos anteriores en esas fechas en vez de duplicarlos.'**
  String get calExportHelp;

  /// No description provided for @calExportSource.
  ///
  /// In es, this message translates to:
  /// **'Se exportan los turnos de «{name}».'**
  String calExportSource(String name);

  /// No description provided for @calExportCalendarLabel.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get calExportCalendarLabel;

  /// No description provided for @calExportNewCalendar.
  ///
  /// In es, this message translates to:
  /// **'Crear el calendario «Cuadrante»'**
  String get calExportNewCalendar;

  /// No description provided for @calExportNewCalendarHelp.
  ///
  /// In es, this message translates to:
  /// **'Así puedes ocultarlo o borrarlo entero cuando quieras.'**
  String get calExportNewCalendarHelp;

  /// No description provided for @calExportRangeLabel.
  ///
  /// In es, this message translates to:
  /// **'Fechas'**
  String get calExportRangeLabel;

  /// No description provided for @calExportFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get calExportFrom;

  /// No description provided for @calExportTo.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get calExportTo;

  /// No description provided for @calExportIncludeRest.
  ///
  /// In es, this message translates to:
  /// **'Incluir los días libres'**
  String get calExportIncludeRest;

  /// No description provided for @calExportIncludeRestHelp.
  ///
  /// In es, this message translates to:
  /// **'Libre y Saliente también se añaden, como eventos de todo el día.'**
  String get calExportIncludeRestHelp;

  /// No description provided for @calExportIncludeAbsences.
  ///
  /// In es, this message translates to:
  /// **'Incluir ausencias'**
  String get calExportIncludeAbsences;

  /// No description provided for @calExportIncludeAbsencesHelp.
  ///
  /// In es, this message translates to:
  /// **'Vacaciones, bajas y otras ausencias. Se añadirían a ese calendario y a la cuenta con la que se sincronice.'**
  String get calExportIncludeAbsencesHelp;

  /// No description provided for @calExportSynced.
  ///
  /// In es, this message translates to:
  /// **'Este calendario se sincroniza con {account}: tus turnos se verán allí.'**
  String calExportSynced(String account);

  /// No description provided for @calExportSyncedUnnamed.
  ///
  /// In es, this message translates to:
  /// **'Este calendario se sincroniza con una cuenta: tus turnos se verán allí.'**
  String get calExportSyncedUnnamed;

  /// No description provided for @calExportPlanAdd.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se añadirá 1 evento.} other{Se añadirán {count} eventos.}}'**
  String calExportPlanAdd(int count);

  /// No description provided for @calExportPlanReplace.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se sustituirá 1 evento de una exportación anterior.} other{Se sustituirán {count} eventos de una exportación anterior.}}'**
  String calExportPlanReplace(int count);

  /// No description provided for @calExportPlanRemove.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se quitará 1 evento de una exportación anterior.} other{Se quitarán {count} eventos de una exportación anterior.}}'**
  String calExportPlanRemove(int count);

  /// No description provided for @calExportPlanSame.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 evento ya está al día.} other{{count} eventos ya están al día.}}'**
  String calExportPlanSame(int count);

  /// No description provided for @calExportPlanNothing.
  ///
  /// In es, this message translates to:
  /// **'Todo está al día: no hay nada que cambiar.'**
  String get calExportPlanNothing;

  /// No description provided for @calExportPlanNone.
  ///
  /// In es, this message translates to:
  /// **'No hay turnos en esas fechas.'**
  String get calExportPlanNone;

  /// No description provided for @calExportButton.
  ///
  /// In es, this message translates to:
  /// **'Exportar'**
  String get calExportButton;

  /// No description provided for @calExportRunning.
  ///
  /// In es, this message translates to:
  /// **'Exportando… {done} de {total}'**
  String calExportRunning(int done, int total);

  /// No description provided for @calExportDoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Exportación hecha'**
  String get calExportDoneTitle;

  /// No description provided for @calExportDoneCalendar.
  ///
  /// In es, this message translates to:
  /// **'Se ha creado el calendario «Cuadrante».'**
  String get calExportDoneCalendar;

  /// No description provided for @calExportDoneCreated.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 evento añadido} other{{count} eventos añadidos}}'**
  String calExportDoneCreated(int count);

  /// No description provided for @calExportDoneReplaced.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 evento anterior sustituido} other{{count} eventos anteriores sustituidos}}'**
  String calExportDoneReplaced(int count);

  /// No description provided for @calExportDoneRemoved.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 evento quitado} other{{count} eventos quitados}}'**
  String calExportDoneRemoved(int count);

  /// No description provided for @calExportDoneSame.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 evento ya estaba al día} other{{count} eventos ya estaban al día}}'**
  String calExportDoneSame(int count);

  /// No description provided for @calExportDoneFailed.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 evento no se ha podido escribir. Vuelve a exportar para completarlo.} other{{count} eventos no se han podido escribir. Vuelve a exportar para completarlos.}}'**
  String calExportDoneFailed(int count);

  /// No description provided for @calExportProblemPermission.
  ///
  /// In es, this message translates to:
  /// **'Sin el permiso no podemos escribir en tu calendario.'**
  String get calExportProblemPermission;

  /// No description provided for @calExportProblemUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Este móvil no tiene calendarios disponibles.'**
  String get calExportProblemUnavailable;

  /// No description provided for @calExportProblemFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido exportar. Prueba otra vez.'**
  String get calExportProblemFailed;

  /// No description provided for @calExportRangeClamped.
  ///
  /// In es, this message translates to:
  /// **'El máximo es un año: se ha recortado el final.'**
  String get calExportRangeClamped;

  /// No description provided for @onboardingImportButton.
  ///
  /// In es, this message translates to:
  /// **'Importar ahora'**
  String get onboardingImportButton;

  /// No description provided for @onboardingImportLrhsoftButton.
  ///
  /// In es, this message translates to:
  /// **'Importar copia de LRHSoft'**
  String get onboardingImportLrhsoftButton;

  /// No description provided for @backupUiRowSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Automática, exportar e importar'**
  String get backupUiRowSubtitle;

  /// No description provided for @backupUiStatusNoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay ninguna copia'**
  String get backupUiStatusNoneTitle;

  /// No description provided for @backupUiStatusNoneBody.
  ///
  /// In es, this message translates to:
  /// **'Haz una ahora: tarda un segundo. Mientras no la tengas, si pierdes el dispositivo o desinstalas la app se pierde tu cuadrante.'**
  String get backupUiStatusNoneBody;

  /// No description provided for @backupUiStatusLast.
  ///
  /// In es, this message translates to:
  /// **'Última copia'**
  String get backupUiStatusLast;

  /// No description provided for @backupUiStatusWhere.
  ///
  /// In es, this message translates to:
  /// **'En este dispositivo'**
  String get backupUiStatusWhere;

  /// No description provided for @backupUiStatusRunning.
  ///
  /// In es, this message translates to:
  /// **'Guardando la copia…'**
  String get backupUiStatusRunning;

  /// No description provided for @backupUiStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Hay cambios nuevos: la copia se hará en unos segundos.'**
  String get backupUiStatusPending;

  /// No description provided for @backupUiStatusPendingAt.
  ///
  /// In es, this message translates to:
  /// **'Hay cambios nuevos: la próxima copia se hará hacia las {time}. Si no quieres esperar, pulsa «Hacer copia ahora».'**
  String backupUiStatusPendingAt(String time);

  /// No description provided for @backupUiStatusPendingLater.
  ///
  /// In es, this message translates to:
  /// **'Hay cambios nuevos: la próxima copia se hará en unos minutos. Si no quieres esperar, pulsa «Hacer copia ahora».'**
  String get backupUiStatusPendingLater;

  /// No description provided for @backupUiStatusFailedTitle.
  ///
  /// In es, this message translates to:
  /// **'La última copia automática ha fallado'**
  String get backupUiStatusFailedTitle;

  /// No description provided for @backupUiStatusFailedWithGood.
  ///
  /// In es, this message translates to:
  /// **'Lo intentamos {when} y no se pudo guardar. Tu última copia buena es de {good}.'**
  String backupUiStatusFailedWithGood(String when, String good);

  /// No description provided for @backupUiStatusFailedNoGood.
  ///
  /// In es, this message translates to:
  /// **'Lo intentamos {when} y no se pudo guardar. Todavía no tienes ninguna copia buena.'**
  String backupUiStatusFailedNoGood(String when);

  /// No description provided for @backupUiFailDiskFull.
  ///
  /// In es, this message translates to:
  /// **'El dispositivo no tiene espacio libre.'**
  String get backupUiFailDiskFull;

  /// No description provided for @backupUiFailGeneric.
  ///
  /// In es, this message translates to:
  /// **'No se pudo escribir el archivo de la copia.'**
  String get backupUiFailGeneric;

  /// No description provided for @backupUiRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get backupUiRetry;

  /// No description provided for @backupUiSystemOn.
  ///
  /// In es, this message translates to:
  /// **'Copia del sistema de Android: activada'**
  String get backupUiSystemOn;

  /// No description provided for @backupUiSystemOff.
  ///
  /// In es, this message translates to:
  /// **'Copia del sistema de Android: desactivada. Actívala en los ajustes de Android para tener otra copia.'**
  String get backupUiSystemOff;

  /// No description provided for @backupUiSystemUnknown.
  ///
  /// In es, this message translates to:
  /// **'Copia del sistema de Android: no podemos comprobarla desde la app. Mira en los ajustes de Android que esté activada.'**
  String get backupUiSystemUnknown;

  /// No description provided for @backupUiWarning.
  ///
  /// In es, this message translates to:
  /// **'Estas copias se guardan en este dispositivo. Si desinstalas la app sin otra copia, se pierde. Exporta un archivo y guárdalo en Drive o envíalo por WhatsApp o correo.'**
  String get backupUiWarning;

  /// No description provided for @backupUiBackupNow.
  ///
  /// In es, this message translates to:
  /// **'Hacer copia ahora'**
  String get backupUiBackupNow;

  /// No description provided for @backupUiBackupDone.
  ///
  /// In es, this message translates to:
  /// **'Copia hecha'**
  String get backupUiBackupDone;

  /// No description provided for @backupUiBackupFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido hacer la copia. Tus datos siguen como estaban.'**
  String get backupUiBackupFailed;

  /// No description provided for @backupUiAutoTitle.
  ///
  /// In es, this message translates to:
  /// **'Copias automáticas'**
  String get backupUiAutoTitle;

  /// No description provided for @backupUiAutoOn.
  ///
  /// In es, this message translates to:
  /// **'Después de cambiar algo, sin que lo notes. Guardamos las 7 últimas y una por día durante 30 días.'**
  String get backupUiAutoOn;

  /// No description provided for @backupUiAutoOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivadas: solo se copia cuando tú lo pides.'**
  String get backupUiAutoOff;

  /// No description provided for @backupUiSectionFile.
  ///
  /// In es, this message translates to:
  /// **'Archivo'**
  String get backupUiSectionFile;

  /// No description provided for @backupUiSectionCheck.
  ///
  /// In es, this message translates to:
  /// **'Comprobar'**
  String get backupUiSectionCheck;

  /// No description provided for @backupUiSectionCopies.
  ///
  /// In es, this message translates to:
  /// **'Copias en este dispositivo'**
  String get backupUiSectionCopies;

  /// No description provided for @backupUiExport.
  ///
  /// In es, this message translates to:
  /// **'Exportar archivo'**
  String get backupUiExport;

  /// No description provided for @backupUiExportSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Para guardarlo en Drive o mandarlo por WhatsApp o correo'**
  String get backupUiExportSubtitle;

  /// No description provided for @backupUiExportFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido exportar el archivo.'**
  String get backupUiExportFailed;

  /// No description provided for @backupUiSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar en el dispositivo'**
  String get backupUiSave;

  /// No description provided for @backupUiSaveSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige una carpeta, por ejemplo Descargas'**
  String get backupUiSaveSubtitle;

  /// No description provided for @backupUiSaveDone.
  ///
  /// In es, this message translates to:
  /// **'Archivo guardado'**
  String get backupUiSaveDone;

  /// No description provided for @backupUiSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido guardar el archivo. Prueba con otra carpeta o usa «Exportar archivo».'**
  String get backupUiSaveFailed;

  /// No description provided for @backupUiImport.
  ///
  /// In es, this message translates to:
  /// **'Importar archivo'**
  String get backupUiImport;

  /// No description provided for @backupUiImportSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recupera un archivo de Cuadrante'**
  String get backupUiImportSubtitle;

  /// No description provided for @backupUiVerify.
  ///
  /// In es, this message translates to:
  /// **'Probar restauración'**
  String get backupUiVerify;

  /// No description provided for @backupUiVerifySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Comprueba que tu última copia se puede recuperar entera'**
  String get backupUiVerifySubtitle;

  /// No description provided for @backupUiVerifyRunning.
  ///
  /// In es, this message translates to:
  /// **'Comprobando la copia…'**
  String get backupUiVerifyRunning;

  /// No description provided for @backupUiVerifyNone.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay ninguna copia que probar. Haz una primero.'**
  String get backupUiVerifyNone;

  /// No description provided for @backupUiVerifyOk.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, =1{La copia está completa: 1 día comprobado} other{La copia está completa: {days} días comprobados}}'**
  String backupUiVerifyOk(int days);

  /// No description provided for @backupUiVerifySame.
  ///
  /// In es, this message translates to:
  /// **'Es idéntica a lo que tienes ahora.'**
  String get backupUiVerifySame;

  /// No description provided for @backupUiVerifyOlder.
  ///
  /// In es, this message translates to:
  /// **'Es anterior a lo que tienes ahora (el primer día que cambia es {day}). Es normal si has hecho cambios después.'**
  String backupUiVerifyOlder(String day);

  /// No description provided for @backupUiVerifyOlderNoDay.
  ///
  /// In es, this message translates to:
  /// **'Es anterior a lo que tienes ahora. Es normal si has hecho cambios después.'**
  String get backupUiVerifyOlderNoDay;

  /// No description provided for @backupUiVerifyMismatch.
  ///
  /// In es, this message translates to:
  /// **'La copia no se reconstruye igual. Primer día distinto: {day}. Haz una copia nueva y avísanos.'**
  String backupUiVerifyMismatch(String day);

  /// No description provided for @backupUiVerifyMismatchNoDay.
  ///
  /// In es, this message translates to:
  /// **'La copia no se reconstruye igual: los datos guardados no coinciden. Haz una copia nueva y avísanos.'**
  String get backupUiVerifyMismatchNoDay;

  /// No description provided for @backupUiVerifyError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido probar la copia. {reason}'**
  String backupUiVerifyError(String reason);

  /// No description provided for @backupUiCopiesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aquí aparecerán tus copias.'**
  String get backupUiCopiesEmpty;

  /// No description provided for @backupUiCopyLocal.
  ///
  /// In es, this message translates to:
  /// **'Copia del dispositivo'**
  String get backupUiCopyLocal;

  /// No description provided for @backupUiCopySafety.
  ///
  /// In es, this message translates to:
  /// **'Antes de restaurar'**
  String get backupUiCopySafety;

  /// No description provided for @backupUiCopyMeta.
  ///
  /// In es, this message translates to:
  /// **'{kind} · {size}'**
  String backupUiCopyMeta(String kind, String size);

  /// No description provided for @backupUiCopyMetaVersion.
  ///
  /// In es, this message translates to:
  /// **'{kind} · {version} · {size}'**
  String backupUiCopyMetaVersion(String kind, String version, String size);

  /// No description provided for @backupUiCopyRestore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar esta'**
  String get backupUiCopyRestore;

  /// No description provided for @backupUiCopyRestoreLabel.
  ///
  /// In es, this message translates to:
  /// **'Restaurar la copia del {when}'**
  String backupUiCopyRestoreLabel(String when);

  /// No description provided for @backupUiWhenToday.
  ///
  /// In es, this message translates to:
  /// **'hoy a las {time}'**
  String backupUiWhenToday(String time);

  /// No description provided for @backupUiWhenYesterday.
  ///
  /// In es, this message translates to:
  /// **'ayer a las {time}'**
  String backupUiWhenYesterday(String time);

  /// No description provided for @backupUiWhenDate.
  ///
  /// In es, this message translates to:
  /// **'el {date} a las {time}'**
  String backupUiWhenDate(String date, String time);

  /// No description provided for @backupUiPreviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Restaurar copia'**
  String get backupUiPreviewTitle;

  /// No description provided for @backupUiPreviewReading.
  ///
  /// In es, this message translates to:
  /// **'Leyendo el archivo…'**
  String get backupUiPreviewReading;

  /// No description provided for @backupUiOriginFile.
  ///
  /// In es, this message translates to:
  /// **'Archivo que has elegido'**
  String get backupUiOriginFile;

  /// No description provided for @backupUiOriginShared.
  ///
  /// In es, this message translates to:
  /// **'Archivo recibido de otra app'**
  String get backupUiOriginShared;

  /// No description provided for @backupUiOriginLocal.
  ///
  /// In es, this message translates to:
  /// **'Copia de este dispositivo'**
  String get backupUiOriginLocal;

  /// No description provided for @backupUiOriginSafety.
  ///
  /// In es, this message translates to:
  /// **'Copia de justo antes de restaurar'**
  String get backupUiOriginSafety;

  /// No description provided for @backupUiOriginCloud.
  ///
  /// In es, this message translates to:
  /// **'Copia en iCloud'**
  String get backupUiOriginCloud;

  /// No description provided for @backupUiPreviewSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardada {when}'**
  String backupUiPreviewSaved(String when);

  /// No description provided for @backupUiPreviewSender.
  ///
  /// In es, this message translates to:
  /// **'Enviado desde {sender}'**
  String backupUiPreviewSender(String sender);

  /// No description provided for @backupUiPreviewSenderHint.
  ///
  /// In es, this message translates to:
  /// **'Lo indica el dispositivo. Si no esperabas este archivo, cancela.'**
  String get backupUiPreviewSenderHint;

  /// No description provided for @backupUiPreviewTurnsOffTitle.
  ///
  /// In es, this message translates to:
  /// **'Esta copia apaga ajustes que tienes encendidos'**
  String get backupUiPreviewTurnsOffTitle;

  /// No description provided for @backupUiPreviewTurnsOffAuto.
  ///
  /// In es, this message translates to:
  /// **'Desactiva las copias automáticas.'**
  String get backupUiPreviewTurnsOffAuto;

  /// No description provided for @backupUiPreviewTurnsOffAlarms.
  ///
  /// In es, this message translates to:
  /// **'Desactiva las alarmas de turno.'**
  String get backupUiPreviewTurnsOffAlarms;

  /// No description provided for @backupUiPreviewContains.
  ///
  /// In es, this message translates to:
  /// **'Qué trae'**
  String get backupUiPreviewContains;

  /// No description provided for @backupUiPreviewNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora: {value}'**
  String backupUiPreviewNow(String value);

  /// No description provided for @backupUiPreviewCalendars.
  ///
  /// In es, this message translates to:
  /// **'Calendarios'**
  String get backupUiPreviewCalendars;

  /// No description provided for @backupUiPreviewArchived.
  ///
  /// In es, this message translates to:
  /// **'{name} (archivado)'**
  String backupUiPreviewArchived(String name);

  /// No description provided for @backupUiPreviewDays.
  ///
  /// In es, this message translates to:
  /// **'Días con turno o nota puestos a mano'**
  String get backupUiPreviewDays;

  /// No description provided for @backupUiPreviewRuns.
  ///
  /// In es, this message translates to:
  /// **'Rotaciones'**
  String get backupUiPreviewRuns;

  /// No description provided for @backupUiPreviewTypes.
  ///
  /// In es, this message translates to:
  /// **'Tipos de turno'**
  String get backupUiPreviewTypes;

  /// No description provided for @backupUiPreviewRange.
  ///
  /// In es, this message translates to:
  /// **'Fechas'**
  String get backupUiPreviewRange;

  /// No description provided for @backupUiPreviewRangeValue.
  ///
  /// In es, this message translates to:
  /// **'Del {from} al {to}'**
  String backupUiPreviewRangeValue(String from, String to);

  /// No description provided for @backupUiPreviewRangeOpen.
  ///
  /// In es, this message translates to:
  /// **'Del {from} al {to}, y una rotación sigue después'**
  String backupUiPreviewRangeOpen(String from, String to);

  /// No description provided for @backupUiPreviewRangeNone.
  ///
  /// In es, this message translates to:
  /// **'Sin fechas'**
  String get backupUiPreviewRangeNone;

  /// No description provided for @backupUiPreviewReplace.
  ///
  /// In es, this message translates to:
  /// **'Esto sustituye lo que tienes ahora; antes guardamos una copia.'**
  String get backupUiPreviewReplace;

  /// No description provided for @backupUiPreviewConfirm.
  ///
  /// In es, this message translates to:
  /// **'Sustituir lo que tengo'**
  String get backupUiPreviewConfirm;

  /// No description provided for @backupUiPreviewCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get backupUiPreviewCancel;

  /// No description provided for @backupUiRestoring.
  ///
  /// In es, this message translates to:
  /// **'Restaurando tu cuadrante…'**
  String get backupUiRestoring;

  /// No description provided for @backupUiRestoringHint.
  ///
  /// In es, this message translates to:
  /// **'No cierres la app.'**
  String get backupUiRestoringHint;

  /// No description provided for @backupUiDoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Listo, tu cuadrante está restaurado'**
  String get backupUiDoneTitle;

  /// No description provided for @backupUiDoneBody.
  ///
  /// In es, this message translates to:
  /// **'Antes de cambiar nada guardamos lo que tenías. Si no era lo que esperabas, puedes volver atrás.'**
  String get backupUiDoneBody;

  /// No description provided for @backupUiDoneView.
  ///
  /// In es, this message translates to:
  /// **'Ver mi calendario'**
  String get backupUiDoneView;

  /// No description provided for @backupUiDoneUndo.
  ///
  /// In es, this message translates to:
  /// **'Volver a como estaba'**
  String get backupUiDoneUndo;

  /// No description provided for @backupUiErrorNotOurs.
  ///
  /// In es, this message translates to:
  /// **'Este archivo no es una copia de Cuadrante.'**
  String get backupUiErrorNotOurs;

  /// No description provided for @backupUiErrorNewer.
  ///
  /// In es, this message translates to:
  /// **'Este archivo es de una versión más nueva de Cuadrante: actualiza la app.'**
  String get backupUiErrorNewer;

  /// No description provided for @backupUiErrorCorrupt.
  ///
  /// In es, this message translates to:
  /// **'El archivo está dañado o incompleto y no se puede usar.'**
  String get backupUiErrorCorrupt;

  /// No description provided for @backupUiErrorTooLarge.
  ///
  /// In es, this message translates to:
  /// **'Este archivo es demasiado grande para ser una copia de Cuadrante.'**
  String get backupUiErrorTooLarge;

  /// No description provided for @backupUiErrorUnreadable.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido leer el archivo.'**
  String get backupUiErrorUnreadable;

  /// No description provided for @backupUiErrorUntouched.
  ///
  /// In es, this message translates to:
  /// **'No hemos cambiado nada: tus datos siguen como estaban.'**
  String get backupUiErrorUntouched;

  /// No description provided for @backupUiErrorRestoreFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido restaurar. Tus datos siguen como estaban.'**
  String get backupUiErrorRestoreFailed;

  /// No description provided for @backupUiErrorRestoreReload.
  ///
  /// In es, this message translates to:
  /// **'Hemos restaurado tus datos, pero la pantalla no se ha podido actualizar. Cierra Cuadrante y vuelve a abrirlo.'**
  String get backupUiErrorRestoreReload;

  /// No description provided for @backupUiBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get backupUiBack;

  /// Widget: los siete días de la semana abreviados, de lunes a domingo, separados por comas (sin espacios).
  ///
  /// In es, this message translates to:
  /// **'lun,mar,mié,jue,vie,sáb,dom'**
  String get widgetWeekdaysShort;

  /// Widget: inicial de cada día de la semana, de lunes a domingo, separadas por comas.
  ///
  /// In es, this message translates to:
  /// **'L,M,X,J,V,S,D'**
  String get widgetWeekdayHeaders;

  /// Widget: los doce meses en minúsculas, separados por comas (sin espacios).
  ///
  /// In es, this message translates to:
  /// **'enero,febrero,marzo,abril,mayo,junio,julio,agosto,septiembre,octubre,noviembre,diciembre'**
  String get widgetMonthNames;

  /// Widget: prefijo de la línea del día siguiente («Mañana: T 14–22»).
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get widgetTomorrow;

  /// No description provided for @widgetEmptyCircular.
  ///
  /// In es, this message translates to:
  /// **'–'**
  String get widgetEmptyCircular;

  /// No description provided for @widgetStaleTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuadrante'**
  String get widgetStaleTitle;

  /// Widget: aviso cuando los datos publicados ya no cubren el día de hoy.
  ///
  /// In es, this message translates to:
  /// **'Abre Cuadrante para seguir al día'**
  String get widgetStaleBody;

  /// No description provided for @widgetAddTitle.
  ///
  /// In es, this message translates to:
  /// **'Añadir widget'**
  String get widgetAddTitle;

  /// No description provided for @widgetAddSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu turno de hoy en la pantalla de inicio'**
  String get widgetAddSubtitle;

  /// No description provided for @widgetAddBody.
  ///
  /// In es, this message translates to:
  /// **'El widget siempre muestra el día de hoy, aunque no abras la app.'**
  String get widgetAddBody;

  /// No description provided for @widgetAddSmall.
  ///
  /// In es, this message translates to:
  /// **'Pequeño: hoy y mañana'**
  String get widgetAddSmall;

  /// No description provided for @widgetAddMedium.
  ///
  /// In es, this message translates to:
  /// **'Mediano: los próximos 7 días'**
  String get widgetAddMedium;

  /// No description provided for @widgetAddLarge.
  ///
  /// In es, this message translates to:
  /// **'Grande: el mes entero'**
  String get widgetAddLarge;

  /// No description provided for @widgetAddAgenda.
  ///
  /// In es, this message translates to:
  /// **'Agenda: próximos turnos'**
  String get widgetAddAgenda;

  /// No description provided for @widgetAddTwoWeeks.
  ///
  /// In es, this message translates to:
  /// **'Dos semanas: actual y siguiente'**
  String get widgetAddTwoWeeks;

  /// No description provided for @widgetAddManualAndroid.
  ///
  /// In es, this message translates to:
  /// **'Mantén pulsada una zona vacía de la pantalla de inicio, elige Widgets y busca Cuadrante.'**
  String get widgetAddManualAndroid;

  /// No description provided for @widgetAddManualIos.
  ///
  /// In es, this message translates to:
  /// **'Mantén pulsada la pantalla de inicio, toca el + de arriba y busca Cuadrante.'**
  String get widgetAddManualIos;

  /// No description provided for @compareTitle.
  ///
  /// In es, this message translates to:
  /// **'Comparar calendarios'**
  String get compareTitle;

  /// No description provided for @compareOpen.
  ///
  /// In es, this message translates to:
  /// **'Comparar calendarios'**
  String get compareOpen;

  /// No description provided for @compareOpenSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Mira cuándo coincidís libres'**
  String get compareOpenSubtitle;

  /// No description provided for @compareSwap.
  ///
  /// In es, this message translates to:
  /// **'Intercambiar'**
  String get compareSwap;

  /// No description provided for @compareIntro.
  ///
  /// In es, this message translates to:
  /// **'Elige dos calendarios y mira sus turnos juntos. Los días libres de los dos se marcan.'**
  String get compareIntro;

  /// No description provided for @compareFirstLabel.
  ///
  /// In es, this message translates to:
  /// **'Primer calendario'**
  String get compareFirstLabel;

  /// No description provided for @compareSecondLabel.
  ///
  /// In es, this message translates to:
  /// **'Segundo calendario'**
  String get compareSecondLabel;

  /// No description provided for @comparePickTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige un calendario'**
  String get comparePickTitle;

  /// No description provided for @compareNeedTwoTitle.
  ///
  /// In es, this message translates to:
  /// **'Necesitas dos calendarios'**
  String get compareNeedTwoTitle;

  /// No description provided for @compareNeedTwoBody.
  ///
  /// In es, this message translates to:
  /// **'Crea otro calendario (tu pareja, un segundo trabajo) para ver cuándo coincidís libres.'**
  String get compareNeedTwoBody;

  /// No description provided for @compareCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Ningún día libre en común este mes} =1{1 día libre en común este mes} other{{count} días libres en común este mes}}'**
  String compareCount(int count);

  /// No description provided for @compareFreeListTitle.
  ///
  /// In es, this message translates to:
  /// **'Días libres en común'**
  String get compareFreeListTitle;

  /// No description provided for @compareLegendFree.
  ///
  /// In es, this message translates to:
  /// **'Libres los dos'**
  String get compareLegendFree;

  /// No description provided for @compareNote.
  ///
  /// In es, this message translates to:
  /// **'Cuenta como libre un día sin turno de trabajo: vacío, libre o con una ausencia (vacaciones, baja…). Cada turno cuenta en el día en que empieza.'**
  String get compareNote;

  /// No description provided for @compareNoShiftMark.
  ///
  /// In es, this message translates to:
  /// **'–'**
  String get compareNoShiftMark;

  /// No description provided for @compareBothFree.
  ///
  /// In es, this message translates to:
  /// **'libres los dos'**
  String get compareBothFree;

  /// No description provided for @compareCellCalendar.
  ///
  /// In es, this message translates to:
  /// **'{calendar}: {shifts}'**
  String compareCellCalendar(String calendar, String shifts);

  /// No description provided for @compareLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se han podido leer los calendarios.'**
  String get compareLoadFailed;

  /// No description provided for @calendarsTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendarios'**
  String get calendarsTitle;

  /// No description provided for @calendarsIntro.
  ///
  /// In es, this message translates to:
  /// **'Cada calendario tiene su propio cuadrante: el tuyo, el de tu pareja, un segundo trabajo. Los tipos de turno son los mismos en todos.'**
  String get calendarsIntro;

  /// No description provided for @calendarsActiveBadge.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get calendarsActiveBadge;

  /// No description provided for @calendarsPrimaryBadge.
  ///
  /// In es, this message translates to:
  /// **'Widget y alarmas'**
  String get calendarsPrimaryBadge;

  /// No description provided for @calendarsAdd.
  ///
  /// In es, this message translates to:
  /// **'Nuevo calendario'**
  String get calendarsAdd;

  /// No description provided for @calendarsNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo calendario'**
  String get calendarsNewTitle;

  /// No description provided for @calendarsEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar calendario'**
  String get calendarsEditTitle;

  /// No description provided for @calendarsNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get calendarsNameLabel;

  /// No description provided for @calendarsNameHint.
  ///
  /// In es, this message translates to:
  /// **'Pareja, segundo trabajo…'**
  String get calendarsNameHint;

  /// No description provided for @calendarsColorLabel.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get calendarsColorLabel;

  /// No description provided for @calendarsColorOption.
  ///
  /// In es, this message translates to:
  /// **'Color {index}'**
  String calendarsColorOption(int index);

  /// No description provided for @calendarsCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get calendarsCreate;

  /// No description provided for @calendarsMakePrimary.
  ///
  /// In es, this message translates to:
  /// **'Usar para widget y alarmas'**
  String get calendarsMakePrimary;

  /// No description provided for @calendarsPrimaryHelp.
  ///
  /// In es, this message translates to:
  /// **'El widget y las alarmas siguen este calendario aunque estés viendo otro.'**
  String get calendarsPrimaryHelp;

  /// No description provided for @calendarsArchive.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get calendarsArchive;

  /// No description provided for @calendarsArchiveTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Archivar «{name}»?'**
  String calendarsArchiveTitle(String name);

  /// No description provided for @calendarsArchiveBody.
  ///
  /// In es, this message translates to:
  /// **'Dejará de salir en la lista, pero podrás recuperarlo desde «Archivados». Sus turnos se quedan guardados en el móvil.'**
  String get calendarsArchiveBody;

  /// No description provided for @calendarsArchivePrimaryNote.
  ///
  /// In es, this message translates to:
  /// **'El widget y las alarmas pasarán a «{name}».'**
  String calendarsArchivePrimaryNote(String name);

  /// No description provided for @calendarsArchivedSection.
  ///
  /// In es, this message translates to:
  /// **'Archivados ({count})'**
  String calendarsArchivedSection(int count);

  /// No description provided for @calendarsRestore.
  ///
  /// In es, this message translates to:
  /// **'Recuperar'**
  String get calendarsRestore;

  /// No description provided for @calendarsRestoreSemantic.
  ///
  /// In es, this message translates to:
  /// **'Recuperar «{name}»'**
  String calendarsRestoreSemantic(String name);

  /// No description provided for @calendarsRestored.
  ///
  /// In es, this message translates to:
  /// **'«{name}» recuperado'**
  String calendarsRestored(String name);

  /// No description provided for @calendarsLastError.
  ///
  /// In es, this message translates to:
  /// **'No puedes archivar el último calendario: siempre tiene que haber uno.'**
  String get calendarsLastError;

  /// No description provided for @calendarsNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Pon un nombre al calendario.'**
  String get calendarsNameRequired;

  /// No description provided for @calendarsNotFoundError.
  ///
  /// In es, this message translates to:
  /// **'Ese calendario ya no existe.'**
  String get calendarsNotFoundError;

  /// No description provided for @calendarsSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido guardar el calendario. Prueba otra vez.'**
  String get calendarsSaveFailed;

  /// No description provided for @calendarsSwitcherLabel.
  ///
  /// In es, this message translates to:
  /// **'Calendario {name}. Cambiar de calendario'**
  String calendarsSwitcherLabel(String name);

  /// No description provided for @calendarsSwitcherTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar de calendario'**
  String get calendarsSwitcherTitle;

  /// No description provided for @calendarsSwitchFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cambiar de calendario.'**
  String get calendarsSwitchFailed;

  /// No description provided for @calendarsManage.
  ///
  /// In es, this message translates to:
  /// **'Gestionar calendarios'**
  String get calendarsManage;

  /// No description provided for @holidayImportAction.
  ///
  /// In es, this message translates to:
  /// **'Traer festivos del calendario del móvil'**
  String get holidayImportAction;

  /// No description provided for @holidayImportTitle.
  ///
  /// In es, this message translates to:
  /// **'Festivos'**
  String get holidayImportTitle;

  /// No description provided for @holidayImportHelp.
  ///
  /// In es, this message translates to:
  /// **'Solo eventos de día completo. Todo se queda en tu móvil; tu calendario no cambia.'**
  String get holidayImportHelp;

  /// No description provided for @holidayImportRangeHelp.
  ///
  /// In es, this message translates to:
  /// **'De inicio, este año y el siguiente.'**
  String get holidayImportRangeHelp;

  /// No description provided for @holidayImportSkipped.
  ///
  /// In es, this message translates to:
  /// **'Ya existe · se omite'**
  String get holidayImportSkipped;

  /// No description provided for @holidayImportReady.
  ///
  /// In es, this message translates to:
  /// **'Se añadirá'**
  String get holidayImportReady;

  /// No description provided for @holidayImportIgnored.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se omite 1 evento con hora.} other{Se omiten {count} eventos con hora.}}'**
  String holidayImportIgnored(int count);

  /// No description provided for @holidayImportCapped.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 evento supera 31 días: se recorta.} other{{count} eventos superan 31 días: se recortan.}}'**
  String holidayImportCapped(int count);

  /// No description provided for @holidayImportAdd.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Añadir 1 festivo} other{Añadir {count} festivos}}'**
  String holidayImportAdd(int count);

  /// No description provided for @holidayImportAdded.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 festivo añadido} other{{count} festivos añadidos}}'**
  String holidayImportAdded(int count);

  /// No description provided for @holidayImportEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay festivos nuevos.'**
  String get holidayImportEmpty;

  /// No description provided for @holidayImportPreviewHelp.
  ///
  /// In es, this message translates to:
  /// **'Las fechas que ya tienen festivo se omiten.'**
  String get holidayImportPreviewHelp;

  /// No description provided for @holidaysSettingsRegionTitle.
  ///
  /// In es, this message translates to:
  /// **'Comunidad autónoma'**
  String get holidaysSettingsRegionTitle;

  /// No description provided for @holidaysSettingsRegionUnset.
  ///
  /// In es, this message translates to:
  /// **'Sin elegir'**
  String get holidaysSettingsRegionUnset;

  /// No description provided for @holidaysSettingsRegionClear.
  ///
  /// In es, this message translates to:
  /// **'Sin comunidad'**
  String get holidaysSettingsRegionClear;

  /// No description provided for @holidaysSettingsMunicipalityTitle.
  ///
  /// In es, this message translates to:
  /// **'Municipio'**
  String get holidaysSettingsMunicipalityTitle;

  /// No description provided for @holidaysSettingsMunicipalityNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguno'**
  String get holidaysSettingsMunicipalityNone;

  /// No description provided for @holidaysSettingsMunicipalitySearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar municipio'**
  String get holidaysSettingsMunicipalitySearch;

  /// No description provided for @holidaysSettingsMunicipalityNoMatch.
  ///
  /// In es, this message translates to:
  /// **'Ningún municipio coincide con «{query}»'**
  String holidaysSettingsMunicipalityNoMatch(String query);

  /// No description provided for @holidaysSettingsMunicipalityLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cargar la lista de municipios.'**
  String get holidaysSettingsMunicipalityLoadFailed;

  /// No description provided for @holidaysSettingsStatusNoRegion.
  ///
  /// In es, this message translates to:
  /// **'Sin comunidad solo salen los festivos nacionales. Elige la tuya para ver los autonómicos.'**
  String get holidaysSettingsStatusNoRegion;

  /// No description provided for @holidaysSettingsStatusNoMunicipality.
  ///
  /// In es, this message translates to:
  /// **'Elige tu municipio para ver sus festivos locales, o añádelos tú abajo.'**
  String get holidaysSettingsStatusNoMunicipality;

  /// No description provided for @holidaysSettingsStatusLocalIncluded.
  ///
  /// In es, this message translates to:
  /// **'Festivos locales de {municipality}: incluidos'**
  String holidaysSettingsStatusLocalIncluded(String municipality);

  /// No description provided for @holidaysSettingsStatusYearPending.
  ///
  /// In es, this message translates to:
  /// **'Los festivos oficiales de {year} llegarán con una actualización'**
  String holidaysSettingsStatusYearPending(String year);

  /// No description provided for @holidaysSettingsStatusLocalMissing.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tenemos los de tu municipio: añádelos tú abajo'**
  String get holidaysSettingsStatusLocalMissing;

  /// No description provided for @holidaysSettingsStatusLocalMissingYear.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tenemos los de {municipality} en {year}: añádelos tú abajo'**
  String holidaysSettingsStatusLocalMissingYear(
    String municipality,
    String year,
  );

  /// No description provided for @holidaysSettingsStatusLocalPartial.
  ///
  /// In es, this message translates to:
  /// **'Puede que falte alguno: compruébalos.'**
  String get holidaysSettingsStatusLocalPartial;

  /// No description provided for @holidaysSettingsAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir festivo local'**
  String get holidaysSettingsAdd;

  /// No description provided for @holidaysSettingsAddName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get holidaysSettingsAddName;

  /// No description provided for @holidaysSettingsAddDefaultName.
  ///
  /// In es, this message translates to:
  /// **'Fiesta local'**
  String get holidaysSettingsAddDefaultName;

  /// No description provided for @holidaysSettingsEmptyYear.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tenemos los festivos de {year}.'**
  String holidaysSettingsEmptyYear(String year);

  /// No description provided for @holidaysSettingsScopeNational.
  ///
  /// In es, this message translates to:
  /// **'Nacional'**
  String get holidaysSettingsScopeNational;

  /// No description provided for @holidaysSettingsScopeLocal.
  ///
  /// In es, this message translates to:
  /// **'Local'**
  String get holidaysSettingsScopeLocal;

  /// No description provided for @holidaysSettingsScopeUser.
  ///
  /// In es, this message translates to:
  /// **'Tuyo'**
  String get holidaysSettingsScopeUser;

  /// No description provided for @holidaysSettingsNoteReplaces.
  ///
  /// In es, this message translates to:
  /// **'Sustituye a {name}'**
  String holidaysSettingsNoteReplaces(String name);

  /// No description provided for @holidaysSettingsNoteCovered.
  ///
  /// In es, this message translates to:
  /// **'En tu calendario lo tapa «{name}»'**
  String holidaysSettingsNoteCovered(String name);

  /// No description provided for @holidaysSettingsSubstitutedTitle.
  ///
  /// In es, this message translates to:
  /// **'No son festivo en {region}'**
  String holidaysSettingsSubstitutedTitle(String region);

  /// No description provided for @holidaysSettingsSubstitutedBody.
  ///
  /// In es, this message translates to:
  /// **'Una comunidad puede cambiar estos festivos nacionales por otros propios.'**
  String get holidaysSettingsSubstitutedBody;

  /// No description provided for @holidaysSettingsRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar festivo'**
  String get holidaysSettingsRemove;

  /// No description provided for @holidaysSettingsRemoved.
  ///
  /// In es, this message translates to:
  /// **'Festivo quitado: {name}'**
  String holidaysSettingsRemoved(String name);

  /// No description provided for @holidaysSettingsRowSemantics.
  ///
  /// In es, this message translates to:
  /// **'{date}. {name}. {scope}'**
  String holidaysSettingsRowSemantics(String date, String name, String scope);

  /// Título del aviso de turno, p. ej. «Turno de Noche a las 22:00».
  ///
  /// In es, this message translates to:
  /// **'Turno de {name} a las {start}'**
  String alarmTitle(String name, String start);

  /// Cuerpo del aviso de turno, p. ej. «Noche: de 22:00 a 06:00».
  ///
  /// In es, this message translates to:
  /// **'{name}: de {start} a {end}'**
  String alarmBody(String name, String start, String end);

  /// Nombre del canal de notificaciones de Android para las alarmas de turno.
  ///
  /// In es, this message translates to:
  /// **'Alarmas de turno'**
  String get alarmChannelName;

  /// Descripción del canal de Android de las alarmas de turno.
  ///
  /// In es, this message translates to:
  /// **'Te avisa antes de que empiece cada turno.'**
  String get alarmChannelDescription;

  /// Título del aviso del día anterior, p. ej. «Mañana: turno de Noche a las 22:00».
  ///
  /// In es, this message translates to:
  /// **'Mañana: turno de {name} a las {start}'**
  String alarmsNotifDayBeforeTitle(String name, String start);

  /// Botón del aviso de turno: vuelve a sonar dentro de 10 minutos.
  ///
  /// In es, this message translates to:
  /// **'Posponer 10 min'**
  String get alarmsNotifSnooze;

  /// Botón del aviso de turno: lo descarta.
  ///
  /// In es, this message translates to:
  /// **'Ya estoy despierto'**
  String get alarmsNotifAwake;

  /// No description provided for @alarmsNotifTestTitle.
  ///
  /// In es, this message translates to:
  /// **'Aviso de prueba'**
  String get alarmsNotifTestTitle;

  /// No description provided for @alarmsNotifTestBody.
  ///
  /// In es, this message translates to:
  /// **'Así te avisará Cuadrante antes de tu turno.'**
  String get alarmsNotifTestBody;

  /// No description provided for @alarmsRowOn.
  ///
  /// In es, this message translates to:
  /// **'Activadas'**
  String get alarmsRowOn;

  /// No description provided for @alarmsRowOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivadas'**
  String get alarmsRowOff;

  /// No description provided for @alarmsMasterTitle.
  ///
  /// In es, this message translates to:
  /// **'Avisar antes de cada turno'**
  String get alarmsMasterTitle;

  /// No description provided for @alarmsMasterHelp.
  ///
  /// In es, this message translates to:
  /// **'Un aviso en el móvil, sin conexión y sin cuenta.'**
  String get alarmsMasterHelp;

  /// No description provided for @alarmsPermOkTitle.
  ///
  /// In es, this message translates to:
  /// **'Todo listo'**
  String get alarmsPermOkTitle;

  /// No description provided for @alarmsPermOkBody.
  ///
  /// In es, this message translates to:
  /// **'Las notificaciones y las alarmas a la hora exacta están permitidas.'**
  String get alarmsPermOkBody;

  /// No description provided for @alarmsPermNotifTitle.
  ///
  /// In es, this message translates to:
  /// **'Faltan las notificaciones'**
  String get alarmsPermNotifTitle;

  /// No description provided for @alarmsPermNotifBody.
  ///
  /// In es, this message translates to:
  /// **'Sin el permiso de notificaciones, Cuadrante no puede avisarte. Si no te sale la ventana para permitirlas, actívalas en los ajustes del sistema.'**
  String get alarmsPermNotifBody;

  /// No description provided for @alarmsPermNotifAllow.
  ///
  /// In es, this message translates to:
  /// **'Permitir'**
  String get alarmsPermNotifAllow;

  /// No description provided for @alarmsPermNotifBlockedBody.
  ///
  /// In es, this message translates to:
  /// **'Android ya no te pregunta por las notificaciones. Actívalas en los ajustes del sistema y Cuadrante podrá avisarte.'**
  String get alarmsPermNotifBlockedBody;

  /// No description provided for @alarmsPermNotifOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get alarmsPermNotifOpenSettings;

  /// No description provided for @alarmsPermExactTitle.
  ///
  /// In es, this message translates to:
  /// **'Alarmas y recordatorios'**
  String get alarmsPermExactTitle;

  /// No description provided for @alarmsPermExactBody.
  ///
  /// In es, this message translates to:
  /// **'Las alarmas pueden llegar con unos minutos de retraso. Para que suenen a la hora exacta, permite «Alarmas y recordatorios» en los ajustes del sistema.'**
  String get alarmsPermExactBody;

  /// No description provided for @alarmsPermExactOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get alarmsPermExactOpen;

  /// No description provided for @alarmsSectionTypes.
  ///
  /// In es, this message translates to:
  /// **'Tipos de turno'**
  String get alarmsSectionTypes;

  /// No description provided for @alarmsTypesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Ninguno de tus turnos tiene horario. Ponle hora en Mis turnos para que Cuadrante pueda avisarte.'**
  String get alarmsTypesEmpty;

  /// No description provided for @alarmsBeforeTitle.
  ///
  /// In es, this message translates to:
  /// **'Antes del turno'**
  String get alarmsBeforeTitle;

  /// No description provided for @alarmsBeforeAtStart.
  ///
  /// In es, this message translates to:
  /// **'Al empezar'**
  String get alarmsBeforeAtStart;

  /// No description provided for @alarmsBeforeSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuánto antes del turno'**
  String get alarmsBeforeSheetTitle;

  /// No description provided for @alarmsBeforeCustom.
  ///
  /// In es, this message translates to:
  /// **'Personalizado'**
  String get alarmsBeforeCustom;

  /// No description provided for @alarmsBeforeCustomTitle.
  ///
  /// In es, this message translates to:
  /// **'Antelación personalizada'**
  String get alarmsBeforeCustomTitle;

  /// No description provided for @alarmsBeforeCustomHelp.
  ///
  /// In es, this message translates to:
  /// **'Horas y minutos antes de que empiece el turno.'**
  String get alarmsBeforeCustomHelp;

  /// No description provided for @alarmsBeforeCustomApply.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get alarmsBeforeCustomApply;

  /// No description provided for @alarmsSecondSegmentTitle.
  ///
  /// In es, this message translates to:
  /// **'Avisar también antes del segundo tramo'**
  String get alarmsSecondSegmentTitle;

  /// No description provided for @alarmsSecondSegmentHelper.
  ///
  /// In es, this message translates to:
  /// **'Un segundo aviso, con la misma antelación, antes de volver al trabajo.'**
  String get alarmsSecondSegmentHelper;

  /// No description provided for @alarmsDayBeforeTitle.
  ///
  /// In es, this message translates to:
  /// **'Aviso el día anterior'**
  String get alarmsDayBeforeTitle;

  /// No description provided for @alarmsDayBeforeAt.
  ///
  /// In es, this message translates to:
  /// **'A las {time}'**
  String alarmsDayBeforeAt(String time);

  /// No description provided for @alarmsDayBeforeTimeTitle.
  ///
  /// In es, this message translates to:
  /// **'Hora del aviso'**
  String get alarmsDayBeforeTimeTitle;

  /// No description provided for @alarmsLabelTitle.
  ///
  /// In es, this message translates to:
  /// **'Texto del aviso'**
  String get alarmsLabelTitle;

  /// No description provided for @alarmsLabelDefault.
  ///
  /// In es, this message translates to:
  /// **'El de siempre'**
  String get alarmsLabelDefault;

  /// No description provided for @alarmsLabelHint.
  ///
  /// In es, this message translates to:
  /// **'Por ejemplo: A trabajar'**
  String get alarmsLabelHint;

  /// No description provided for @alarmsLabelApply.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get alarmsLabelApply;

  /// No description provided for @alarmsLabelReset.
  ///
  /// In es, this message translates to:
  /// **'Usar el de siempre'**
  String get alarmsLabelReset;

  /// No description provided for @alarmsTestButton.
  ///
  /// In es, this message translates to:
  /// **'Probar aviso'**
  String get alarmsTestButton;

  /// No description provided for @alarmsTestScheduled.
  ///
  /// In es, this message translates to:
  /// **'Te avisaremos en 10 segundos.'**
  String get alarmsTestScheduled;

  /// No description provided for @alarmsTestDenied.
  ///
  /// In es, this message translates to:
  /// **'Sin el permiso de notificaciones no podemos probar el aviso.'**
  String get alarmsTestDenied;

  /// No description provided for @alarmsNextLine.
  ///
  /// In es, this message translates to:
  /// **'Próximo aviso: {when} · {shift}'**
  String alarmsNextLine(String when, String shift);

  /// No description provided for @alarmsNextLineDayBefore.
  ///
  /// In es, this message translates to:
  /// **'Próximo aviso: {when} · {shift}, el día anterior'**
  String alarmsNextLineDayBefore(String when, String shift);

  /// Cuándo suena el próximo aviso, p. ej. «mié 21 de octubre, 20:30».
  ///
  /// In es, this message translates to:
  /// **'{weekday} {day} de {month}, {time}'**
  String alarmsNextWhen(String weekday, int day, String month, String time);

  /// No description provided for @alarmsNextNone.
  ///
  /// In es, this message translates to:
  /// **'No hay ningún aviso previsto en los próximos días.'**
  String get alarmsNextNone;

  /// No description provided for @alarmsNextOff.
  ///
  /// In es, this message translates to:
  /// **'Las alarmas están desactivadas.'**
  String get alarmsNextOff;

  /// No description provided for @alarmsSkipDay.
  ///
  /// In es, this message translates to:
  /// **'Sin alarma este día'**
  String get alarmsSkipDay;

  /// Título de la notificación del recordatorio de una nota.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio'**
  String get alarmsReminderTitle;

  /// Texto de la notificación del recordatorio cuando la nota no tiene texto.
  ///
  /// In es, this message translates to:
  /// **'Tienes un recordatorio para hoy'**
  String get alarmsReminderEmptyBody;

  /// Nombre del canal de notificaciones de Android para los recordatorios de las notas.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios de notas'**
  String get alarmsReminderChannelName;

  /// Descripción del canal de Android de los recordatorios de notas.
  ///
  /// In es, this message translates to:
  /// **'Te avisa a la hora que elijas en la nota de un día.'**
  String get alarmsReminderChannelDescription;

  /// Botón del detalle del día, bajo la nota: pide una hora y programa un aviso.
  ///
  /// In es, this message translates to:
  /// **'Avisarme'**
  String get dayReminderAdd;

  /// No description provided for @dayReminderAt.
  ///
  /// In es, this message translates to:
  /// **'Aviso a las {time}'**
  String dayReminderAt(String time);

  /// Descripción accesible de la fila del aviso: tocarla cambia la hora.
  ///
  /// In es, this message translates to:
  /// **'Cambiar la hora del aviso'**
  String get dayReminderChange;

  /// No description provided for @dayReminderRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar aviso'**
  String get dayReminderRemove;

  /// No description provided for @dayReminderRemoved.
  ///
  /// In es, this message translates to:
  /// **'Aviso quitado'**
  String get dayReminderRemoved;

  /// No description provided for @dayReminderPickHelp.
  ///
  /// In es, this message translates to:
  /// **'Hora del aviso'**
  String get dayReminderPickHelp;

  /// No description provided for @dayReminderPast.
  ///
  /// In es, this message translates to:
  /// **'Esa hora ya pasó: no sonará.'**
  String get dayReminderPast;

  /// No description provided for @dayReminderNoPermission.
  ///
  /// In es, this message translates to:
  /// **'Las notificaciones están desactivadas, así que el aviso no sonará. Actívalas en los ajustes del móvil.'**
  String get dayReminderNoPermission;

  /// No description provided for @dayReminderOnlyPrimary.
  ///
  /// In es, this message translates to:
  /// **'Solo suenan los avisos del calendario principal.'**
  String get dayReminderOnlyPrimary;

  /// No description provided for @agendaSemanticsReminder.
  ///
  /// In es, this message translates to:
  /// **'aviso a las {time}'**
  String agendaSemanticsReminder(String time);

  /// Cabecera de la sección de alarma del editor de un tipo de turno.
  ///
  /// In es, this message translates to:
  /// **'Alarma'**
  String get shiftTypesAlarmSection;

  /// No description provided for @shiftTypesSoundLabel.
  ///
  /// In es, this message translates to:
  /// **'Sonido'**
  String get shiftTypesSoundLabel;

  /// No description provided for @shiftTypesSoundHelper.
  ///
  /// In es, this message translates to:
  /// **'Suena con el volumen de las alarmas, cuando actives la alarma de este turno en Ajustes.'**
  String get shiftTypesSoundHelper;

  /// No description provided for @shiftTypesSoundDefault.
  ///
  /// In es, this message translates to:
  /// **'Predeterminado'**
  String get shiftTypesSoundDefault;

  /// Valor de la fila Sonido cuando hay un sonido elegido pero el móvil no ha dado su nombre.
  ///
  /// In es, this message translates to:
  /// **'Sonido del móvil'**
  String get shiftTypesSoundCustom;

  /// No description provided for @shiftTypesSoundMissing.
  ///
  /// In es, this message translates to:
  /// **'No disponible: suena el predeterminado'**
  String get shiftTypesSoundMissing;

  /// No description provided for @shiftTypesSoundReset.
  ///
  /// In es, this message translates to:
  /// **'Usar el predeterminado'**
  String get shiftTypesSoundReset;

  /// Plantillas de tipo de turno: nombre y código (1 a 3 caracteres, sin espacios, distinto en cada plantilla). Solo se usan al crear el tipo (instalación nueva, saliente automático…); los tipos ya guardados no se renombran.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get catalogShiftMorningName;

  /// No description provided for @catalogShiftMorningCode.
  ///
  /// In es, this message translates to:
  /// **'M'**
  String get catalogShiftMorningCode;

  /// No description provided for @catalogShiftAfternoonName.
  ///
  /// In es, this message translates to:
  /// **'Tarde'**
  String get catalogShiftAfternoonName;

  /// No description provided for @catalogShiftAfternoonCode.
  ///
  /// In es, this message translates to:
  /// **'T'**
  String get catalogShiftAfternoonCode;

  /// No description provided for @catalogShiftNightName.
  ///
  /// In es, this message translates to:
  /// **'Noche'**
  String get catalogShiftNightName;

  /// No description provided for @catalogShiftNightCode.
  ///
  /// In es, this message translates to:
  /// **'N'**
  String get catalogShiftNightCode;

  /// No description provided for @catalogShiftRestName.
  ///
  /// In es, this message translates to:
  /// **'Libre'**
  String get catalogShiftRestName;

  /// No description provided for @catalogShiftRestCode.
  ///
  /// In es, this message translates to:
  /// **'L'**
  String get catalogShiftRestCode;

  /// No description provided for @catalogShiftGuard24Name.
  ///
  /// In es, this message translates to:
  /// **'Guardia 24 h'**
  String get catalogShiftGuard24Name;

  /// No description provided for @catalogShiftGuard24Code.
  ///
  /// In es, this message translates to:
  /// **'G'**
  String get catalogShiftGuard24Code;

  /// No description provided for @catalogShiftPostNightName.
  ///
  /// In es, this message translates to:
  /// **'Saliente'**
  String get catalogShiftPostNightName;

  /// No description provided for @catalogShiftPostNightCode.
  ///
  /// In es, this message translates to:
  /// **'S'**
  String get catalogShiftPostNightCode;

  /// No description provided for @catalogShiftVacationName.
  ///
  /// In es, this message translates to:
  /// **'Vacaciones'**
  String get catalogShiftVacationName;

  /// No description provided for @catalogShiftVacationCode.
  ///
  /// In es, this message translates to:
  /// **'V'**
  String get catalogShiftVacationCode;

  /// No description provided for @catalogShiftPersonalDayName.
  ///
  /// In es, this message translates to:
  /// **'Libre disposición'**
  String get catalogShiftPersonalDayName;

  /// No description provided for @catalogShiftPersonalDayCode.
  ///
  /// In es, this message translates to:
  /// **'LD'**
  String get catalogShiftPersonalDayCode;

  /// No description provided for @catalogShiftDay12Name.
  ///
  /// In es, this message translates to:
  /// **'Día 12 h'**
  String get catalogShiftDay12Name;

  /// No description provided for @catalogShiftDay12Code.
  ///
  /// In es, this message translates to:
  /// **'D'**
  String get catalogShiftDay12Code;

  /// No description provided for @catalogShiftNight12Name.
  ///
  /// In es, this message translates to:
  /// **'Noche 12 h'**
  String get catalogShiftNight12Name;

  /// No description provided for @catalogShiftNight12Code.
  ///
  /// In es, this message translates to:
  /// **'N12'**
  String get catalogShiftNight12Code;

  /// Nombre que propone «Usar «Partido 09–13 / 17–21»» en el editor de turnos.
  ///
  /// In es, this message translates to:
  /// **'Partido'**
  String get catalogShiftSplitName;

  /// No description provided for @catalogShiftSplitCode.
  ///
  /// In es, this message translates to:
  /// **'P'**
  String get catalogShiftSplitCode;

  /// Catálogo de rotaciones: nombre y descripción de cada patrón (asistente de patrón y primer uso).
  ///
  /// In es, this message translates to:
  /// **'Correturnos'**
  String get catalogPatternCorreturnosName;

  /// No description provided for @catalogPatternCorreturnosDescription.
  ///
  /// In es, this message translates to:
  /// **'5 mañanas, 2 libres, 5 tardes, 2 libres, 5 noches, 2 libres'**
  String get catalogPatternCorreturnosDescription;

  /// No description provided for @catalogPattern24x72Name.
  ///
  /// In es, this message translates to:
  /// **'24 x 72'**
  String get catalogPattern24x72Name;

  /// No description provided for @catalogPattern24x72Description.
  ///
  /// In es, this message translates to:
  /// **'Guardia de 24 h y 72 h libres'**
  String get catalogPattern24x72Description;

  /// No description provided for @catalogPattern12hName.
  ///
  /// In es, this message translates to:
  /// **'12 horas'**
  String get catalogPattern12hName;

  /// No description provided for @catalogPattern12hDescription.
  ///
  /// In es, this message translates to:
  /// **'Día 12 h, noche 12 h, saliente y libre'**
  String get catalogPattern12hDescription;

  /// No description provided for @catalogPattern6x4Name.
  ///
  /// In es, this message translates to:
  /// **'6 x 4'**
  String get catalogPattern6x4Name;

  /// No description provided for @catalogPattern6x4Description.
  ///
  /// In es, this message translates to:
  /// **'6 mañanas y 4 libres'**
  String get catalogPattern6x4Description;

  /// No description provided for @catalogPattern4x4Name.
  ///
  /// In es, this message translates to:
  /// **'4 x 4'**
  String get catalogPattern4x4Name;

  /// No description provided for @catalogPattern4x4Description.
  ///
  /// In es, this message translates to:
  /// **'4 días de 12 h y 4 libres'**
  String get catalogPattern4x4Description;

  /// No description provided for @catalogPattern5x2Name.
  ///
  /// In es, this message translates to:
  /// **'5 x 2'**
  String get catalogPattern5x2Name;

  /// No description provided for @catalogPattern5x2Description.
  ///
  /// In es, this message translates to:
  /// **'5 mañanas y 2 libres (lunes a viernes)'**
  String get catalogPattern5x2Description;

  /// No description provided for @catalogPattern223Name.
  ///
  /// In es, this message translates to:
  /// **'2-2-3'**
  String get catalogPattern223Name;

  /// No description provided for @catalogPattern223Description.
  ///
  /// In es, this message translates to:
  /// **'Dos días de 12 h, dos libres, tres de 12 h, dos libres, dos de 12 h y tres libres (también 2-2-3-2-2-3)'**
  String get catalogPattern223Description;

  /// No description provided for @catalogPatternContinentalName.
  ///
  /// In es, this message translates to:
  /// **'Continental'**
  String get catalogPatternContinentalName;

  /// No description provided for @catalogPatternContinentalDescription.
  ///
  /// In es, this message translates to:
  /// **'Turno continuo de 28 días con 4 equipos: bloques de 2 y 3 mañanas, tardes y noches, y 7 libres'**
  String get catalogPatternContinentalDescription;

  /// No description provided for @catalogPatternDupontName.
  ///
  /// In es, this message translates to:
  /// **'DuPont'**
  String get catalogPatternDupontName;

  /// No description provided for @catalogPatternDupontDescription.
  ///
  /// In es, this message translates to:
  /// **'Ciclo de 28 días en turnos de 12 h: 4 noches, 3 libres, 3 días, 1 libre, 3 noches, 3 libres, 4 días y 7 libres'**
  String get catalogPatternDupontDescription;

  /// No description provided for @holidayNameNewYear.
  ///
  /// In es, this message translates to:
  /// **'Año Nuevo'**
  String get holidayNameNewYear;

  /// No description provided for @holidayNameEpiphany.
  ///
  /// In es, this message translates to:
  /// **'Epifanía del Señor'**
  String get holidayNameEpiphany;

  /// No description provided for @holidayNameMaundyThursday.
  ///
  /// In es, this message translates to:
  /// **'Jueves Santo'**
  String get holidayNameMaundyThursday;

  /// No description provided for @holidayNameGoodFriday.
  ///
  /// In es, this message translates to:
  /// **'Viernes Santo'**
  String get holidayNameGoodFriday;

  /// No description provided for @holidayNameEasterMonday.
  ///
  /// In es, this message translates to:
  /// **'Lunes de Pascua'**
  String get holidayNameEasterMonday;

  /// No description provided for @holidayNameLabourDay.
  ///
  /// In es, this message translates to:
  /// **'Fiesta del Trabajo'**
  String get holidayNameLabourDay;

  /// No description provided for @holidayNameAssumption.
  ///
  /// In es, this message translates to:
  /// **'Asunción de la Virgen'**
  String get holidayNameAssumption;

  /// No description provided for @holidayNameNationalDay.
  ///
  /// In es, this message translates to:
  /// **'Fiesta Nacional de España'**
  String get holidayNameNationalDay;

  /// No description provided for @holidayNameAllSaints.
  ///
  /// In es, this message translates to:
  /// **'Todos los Santos'**
  String get holidayNameAllSaints;

  /// No description provided for @holidayNameConstitution.
  ///
  /// In es, this message translates to:
  /// **'Día de la Constitución Española'**
  String get holidayNameConstitution;

  /// No description provided for @holidayNameImmaculate.
  ///
  /// In es, this message translates to:
  /// **'Inmaculada Concepción'**
  String get holidayNameImmaculate;

  /// No description provided for @holidayNameChristmas.
  ///
  /// In es, this message translates to:
  /// **'Natividad del Señor'**
  String get holidayNameChristmas;

  /// No description provided for @holidayNameStStephen.
  ///
  /// In es, this message translates to:
  /// **'San Esteban'**
  String get holidayNameStStephen;

  /// No description provided for @holidayNameStJoseph.
  ///
  /// In es, this message translates to:
  /// **'San José'**
  String get holidayNameStJoseph;

  /// No description provided for @holidayNameStJames.
  ///
  /// In es, this message translates to:
  /// **'Santiago Apóstol'**
  String get holidayNameStJames;

  /// No description provided for @holidayNameGaliciaDay.
  ///
  /// In es, this message translates to:
  /// **'Día de Galicia'**
  String get holidayNameGaliciaDay;

  /// No description provided for @holidayNameStJamesGalicia.
  ///
  /// In es, this message translates to:
  /// **'Santiago Apóstol / Día Nacional de Galicia'**
  String get holidayNameStJamesGalicia;

  /// No description provided for @holidayNameCataloniaDay.
  ///
  /// In es, this message translates to:
  /// **'Diada Nacional de Cataluña'**
  String get holidayNameCataloniaDay;

  /// No description provided for @holidayNameBasqueDay.
  ///
  /// In es, this message translates to:
  /// **'Día del País Vasco'**
  String get holidayNameBasqueDay;

  /// No description provided for @catalogCalendarMainName.
  ///
  /// In es, this message translates to:
  /// **'Mi cuadrante'**
  String get catalogCalendarMainName;

  /// No description provided for @historyUndone.
  ///
  /// In es, this message translates to:
  /// **'Cambio deshecho'**
  String get historyUndone;

  /// No description provided for @historyRedone.
  ///
  /// In es, this message translates to:
  /// **'Cambio rehecho'**
  String get historyRedone;

  /// No description provided for @historyNothingToUndo.
  ///
  /// In es, this message translates to:
  /// **'Nada que deshacer'**
  String get historyNothingToUndo;

  /// No description provided for @historyNothingToRedo.
  ///
  /// In es, this message translates to:
  /// **'Nada que rehacer'**
  String get historyNothingToRedo;

  /// Presentación alternativa del mes, decisión D de accesibilidad.
  ///
  /// In es, this message translates to:
  /// **'Cuadrícula'**
  String get monthPresentationGrid;

  /// Presentación alternativa del mes, decisión D de accesibilidad.
  ///
  /// In es, this message translates to:
  /// **'Lista'**
  String get monthPresentationList;

  /// Presentación alternativa del mes, decisión D de accesibilidad.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar días'**
  String get monthSelectDays;

  /// Presentación alternativa del mes, decisión D de accesibilidad.
  ///
  /// In es, this message translates to:
  /// **'Toca para elegir este día'**
  String get monthSelectDay;

  /// Presentación alternativa del mes, decisión D de accesibilidad.
  ///
  /// In es, this message translates to:
  /// **'Lista recomendada para ver los horarios completos y el texto grande.'**
  String get monthListRecommended;

  /// Presentación alternativa del mes, decisión D de accesibilidad.
  ///
  /// In es, this message translates to:
  /// **'Presentación de lista'**
  String get monthListSelected;

  /// Presentación alternativa del mes, decisión D de accesibilidad.
  ///
  /// In es, this message translates to:
  /// **'Presentación de cuadrícula'**
  String get monthGridSelected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ca', 'en', 'es', 'eu', 'gl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return AppLocalizationsCa();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'eu':
      return AppLocalizationsEu();
    case 'gl':
      return AppLocalizationsGl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
