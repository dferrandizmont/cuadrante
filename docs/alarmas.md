# Alarmas de turno

Estado: planificador, programador local, sincronización y **pantalla de ajustes** (Ajustes › Alarmas,
`/ajustes/alarmas`) hechos y probados en Dart y con el programador falso (`app/lib/features/alarms/`). Falta la
prueba en dispositivos reales (ver el final). Todo está apagado por defecto. Referencias: `turnos-spec.md` §3 P0.5
y §6, `docs/plan-publicacion.md` §3. Las alarmas son completas y gratis (`docs/roadmap.md`): aviso el día anterior,
posponer y saltar un día están hechos; en la 0.6.0 se añaden el **recordatorio dentro de una nota** y el **sonido por
tipo de turno** (secciones de más abajo).

## Qué hace

Por cada tipo de turno con alarma activada, la app programa un aviso local `minutesBefore` minutos antes de que
empiece cada turno de los próximos 14 días y, si el usuario lo pide, otro la tarde anterior. Todo en el móvil, sin
servidor ni cuenta.

- **Ajustes** (`AlarmSettings`, tabla `settings`, clave `alarms`, JSON versionado): interruptor global, horizonte en
  días (14 por defecto, máximo 30), días saltados (`skippedDates`) y, por id de tipo de turno, `enabled`,
  `minutesBefore` (90 por defecto, 0 a 1440), `label` opcional (sustituye al título del aviso de antes del turno),
  `dayBefore` (aviso el día anterior, apagado por defecto) y `dayBeforeMinute` (minutos desde las 00:00, 1200 = 20:00
  por defecto). Sin nada guardado, todo apagado. Forma del JSON (la versión sigue en 1: los campos nuevos son
  opcionales y un valor de la versión anterior se lee como «sin aviso el día anterior, ningún día saltado»):

  ```json
  {
    "version": 1,
    "enabled": true,
    "horizonDays": 14,
    "types": {
      "night": {
        "enabled": true, "minutesBefore": 90, "label": "A trabajar",
        "dayBefore": true, "dayBeforeMinute": 1200
      }
    },
    "skipped": ["2026-10-21", "2026-10-22"]
  }
  ```

  Es tolerante: tipos erróneos o fechas mal escritas se ignoran, los números se acotan (`dayBeforeMinute` 0 a 1439)
  y se leen como mucho 400 días saltados.
- **Aviso el día anterior** (`AlarmKind.dayBefore`): por cada turno de un tipo con `dayBefore`, un aviso a las
  `dayBeforeMinute` del día anterior («Mañana: turno de Noche a las 22:00»). Es hora de pared como todos los
  avisos, así que el 28/29 de marzo y el 24/25 de octubre sigue sonando a la misma hora local; si cae en la hora
  que no existe o en la repetida se aplican las reglas de abajo. Un aviso que ya pasó se omite. El texto propio
  (`label`) solo sustituye al título del aviso de antes del turno.
- **Saltar un día** (`skippedDates`): un turno que empieza un día saltado no genera **ningún** aviso, ni el de antes
  del turno ni el de la tarde anterior. Se activa con «Sin alarma este día» en el detalle del día (solo aparece con
  las alarmas activadas, en el calendario principal y si algún turno del día tiene alarma; un día ya saltado
  conserva el interruptor aunque cambie el turno). Los días anteriores a hoy se podan al guardar cualquier cambio de
  los ajustes.
- **Planificador puro** (`planAlarms`): de `Schedule` + ajustes + «ahora» saca la lista de `PlannedAlarm`.
  - Un aviso por turno (un día con dos turnos suena dos veces). Los turnos sin horario no tienen aviso.
  - **Turno partido (0.6.0, A12):** un tipo con segundo tramo suena **antes del primer tramo** (como siempre) y, si el
    tipo tiene «Avisar también antes del segundo tramo» (`secondSegment`, **activado por defecto**), otra vez antes del
    segundo, con la misma antelación (`minutesBefore`) y el texto propio del tipo si lo hay; el cuerpo es el del tramo
    («Partido: de 17:00 a 21:00»). El segundo tramo puede empezar pasada la medianoche: la hora de pared se cuenta
    desde el día del turno (20–23 y 01–03 con 90 min: 18:30 y 23:30 del mismo día). Los dos llevan «Posponer» y «Ya
    estoy despierto». Id del segundo: el del primero con `|s2` al final del texto que se codifica (los ids de siempre
    no cambian). **El aviso del día anterior sigue siendo uno por turno** (habla del inicio del primer tramo) y no
    depende del interruptor del segundo tramo. «Sin alarma este día» silencia los dos. El ajuste vive en
    `AlarmTypeSettings.secondSegment` (JSON de los ajustes, sin tocar el esquema); solo se escribe cuando se apaga y
    una clave ausente se lee como activado. En Ajustes › Alarmas, la fila solo aparece en los tipos con segundo tramo.
  - **Las ausencias nunca suenan** (`ShiftCategory.absence`: vacaciones, libre disposición, baja médica...): no son
    turnos a los que se va, y un aviso de «baja» en la pantalla de bloqueo sería un dato de salud a la vista. El
    planificador las salta aunque en los ajustes guardados haya un tipo de ausencia activado
    (`canShiftTypeRing`, compartido con la pantalla de ajustes, que tampoco las lista).
  - La hora de aviso es **hora de pared** (fecha civil + minutos), no un instante: puede caer el día anterior
    (turno de 00:30 con 90 min de antelación suena a las 23:00 de la víspera).
  - Solo avisos posteriores a «ahora» (el mismo minuto ya cuenta como pasado) y dentro del horizonte.
  - Ordenados por hora y **tope de 60** (contando todos los tipos de aviso): si hay más, se quedan los más próximos,
    salvo que los recordatorios de notas van primero (ver «Recordatorio en una nota»).
  - Id determinista de 31 bits (FNV-1a de `fecha|tipo|índice del turno en el día`, más `|dayBefore` para el aviso
    de la tarde anterior): reprogramar no duplica, los dos avisos de un turno nunca comparten id y los ids de los
    avisos de antes del turno son los de siempre (una actualización no deja avisos huérfanos).
  - `nextAlarm()` devuelve el primero del plan; es lo que enseña «Próximo aviso» en la pantalla de ajustes.
  - Los textos vienen de `AlarmStrings` (rellenado desde el ARB): «Turno de Noche a las 22:00» y «Noche: de 22:00 a 06:00».
    Un turno que cruza la medianoche solo importa por su inicio.
- **Programador** (`AlarmScheduler`): `LocalAlarmScheduler` (flutter_local_notifications) y `FakeAlarmScheduler`
  (pruebas y escritorio). `replaceAll` programa cada aviso (el mismo id lo sustituye) y después cancela los avisos
  nuestros que ya no tocan; reconoce los suyos por el prefijo `cuadrante.alarm:` del payload y **nunca toca otras
  notificaciones**. Programar primero y cancelar después evita una ventana sin alarmas si la app muere a mitad.
- **Sincronización** (`AlarmSync`, montada por `AlarmsHost` en `app.dart`): recalcula y reprograma al arrancar, al
  volver a primer plano, tras cambiar los turnos (con 1 s de espera tras el último cambio, porque pintar emite uno por
  día) y al cambiar los ajustes. Las peticiones se serializan y se agrupan: mientras hay una pasada en curso, las
  demás solo la marcan como pendiente y se hace una más. Sin permiso de notificaciones no se programa nada y se
  cancela lo nuestro; al volver de los ajustes del sistema, la siguiente reanudación lo recupera. Al apagar las
  alarmas o perder el permiso también se cancelan los avisos pospuestos.

## Pantalla de ajustes (Ajustes › Alarmas)

- **Interruptor general.** Al encenderlo se pide el permiso de notificaciones si falta (nunca al arrancar). Apagado,
  la pantalla solo enseña el interruptor y «Las alarmas están desactivadas»; las elecciones por turno se conservan.
  La fila de Ajustes dice «Activadas» si hay alguna alarma que pueda sonar y «Desactivadas» si no.
- **Tarjeta de permisos** (con el interruptor encendido; se vuelve a leer al volver a la app):
  - Notificaciones denegadas: «Faltan las notificaciones», explica que sin ellas no hay avisos y ofrece «Permitir».
    Si la denegación ya es permanente (denegado dos veces, apagadas en los ajustes de la app o Android anterior a 13:
    `AlarmSystemChannel`, canal `app.cuadrante/alarm_system`, política `NotificationPermissionPolicy`), «Permitir» no haría
    nada y la tarjeta enseña **«Abrir ajustes»**, que abre los ajustes de notificaciones de la app
    (`ACTION_APP_NOTIFICATION_SETTINGS`). Se distingue «nunca preguntado» de «denegado para siempre» porque la app
    marca que ya pidió el permiso justo antes de pedirlo (`shouldShowRequestPermissionRationale` es falso en los dos casos).
  - Alarmas exactas sin conceder (Android 12+, «Alarmas y recordatorios»): «Las alarmas pueden llegar con unos
    minutos de retraso», explica el permiso y «Abrir ajustes» lleva a la pantalla del sistema
    (`requestExactAlarmsPermission`). Las alarmas se programan igualmente, de forma inexacta.
  - Todo concedido: tarjeta verde «Todo listo».
- **Por tipo de turno con horario** (los de trabajo primero; Libre, vacaciones, baja y demás ausencias no pueden sonar
  y **no se listan**, aunque tengan horario): interruptor;
  «Antes del turno» (30 min, 1 h, 1 h 30 min, 2 h o personalizado con un selector de horas y minutos, 0 a 24 h);
  «Aviso el día anterior» con su hora; «Texto del aviso» (sustituye al título).
- **«Probar aviso»**: programa una notificación de prueba a los 10 s (pide el permiso si falta). No es una alarma
  planificada: su payload (`cuadrante.alarm.test:`) no empieza por el de las alarmas, así que una sincronización no
  la toca.
- **Pie**: «Próximo aviso: mié 21 de octubre, 20:30 · Noche», calculado por el mismo planificador con el calendario
  principal (si es el aviso de la tarde anterior lo dice).

## Posponer y «Ya estoy despierto»

Los avisos de antes del turno llevan dos botones (Android; las categorías de iOS están declaradas y se prueban en el
Mac):

- **«Posponer 10 min»** vuelve a programar un aviso de una sola vez, 10 minutos después, con los mismos textos y los
  mismos botones, y quita el actual. **Funciona sin abrir la app**: el botón no abre la interfaz, el plugin recibe el
  toque en `ActionBroadcastReceiver` (declarado en el manifest), arranca un motor de Flutter en segundo plano y
  llama a `alarmNotificationBackgroundHandler` (función de nivel superior con `@pragma('vm:entry-point')`), que
  programa el aviso con `handleAlarmAction`. Ese aislado no tiene base de datos, proveedores ni textos traducidos, así
  que **todo lo que necesita viaja en el payload** de la notificación (`AlarmPayload`: tipo, día, clase, título,
  cuerpo y etiquetas de los botones). Programa un instante absoluto (UTC), sin cargar la base de zonas horarias.
- El aviso pospuesto tiene el payload `cuadrante.alarm.snooze:`, distinto del de las alarmas, para que la
  sincronización no lo cancele. Su id sale del turno (`snoozeIdFor`): pulsar «Posponer» otra vez lo sustituye, no
  los acumula. Se cancela al apagar las alarmas o perder el permiso. Los dos avisos de un turno partido tienen su
  propio posponer: el payload lleva el tramo (`g`, solo cuando es 1, así que los payloads de siempre no cambian) y
  `snoozeIdFor` añade `|s2` para el segundo (el id del primero es el de siempre).
- **«Ya estoy despierto»** solo descarta la notificación (el plugin la cancela al pulsar).
- El aviso del día anterior no lleva botones.
- Si la app está abierta, el mismo manejador también se registra en el aislado principal
  (`onDidReceiveNotificationResponse`); sirve de red de seguridad.
- Riesgo conocido, **sin probar en dispositivo**: que Android (o un fabricante con ahorro agresivo) no deje arrancar
  el motor en segundo plano con la app cerrada. Si pasara, la alternativa es `showsUserInterface: true` en la
  acción (abre la app y se pospone desde el aislado principal).

## Recordatorio en una nota (0.6.0, hueco A1)

- **Dónde.** Detalle del día, bajo la nota: «Avisarme» abre un selector de hora de 24 h (propone las 09:00, o la
  siguiente hora en punto si es hoy y las 09:00 ya pasaron). Con aviso puesto la fila enseña «Aviso a las 09:00»
  (tocarla cambia la hora) y «Quitar aviso»; al quitarlo aparece «Deshacer» en el sitio mientras no se haga otra cosa.
  No se ofrece en días ya pasados.
- **Dato.** `DayEntry.noteReminderMinute` (esquema v3, minuto del día civil 0–1439; `docs/datos.md`). Lo escribe
  `ScheduleController.setNoteReminder(fecha, minuto?)`: un único paso de deshacer por la cola de escritura normal
  (el deshacer del modo pintar también lo revierte), `null` lo quita, y un día que se queda sin nada desaparece.
  Es independiente del texto: un día puede tener aviso sin nota. «Duplicar» y la edición por rango (con notas) lo
  copian.
- **Planificador.** `AlarmKind.reminder`: suena a las `noteReminderMinute` del día de la nota, como **hora de pared**
  (mismas reglas de horario de verano que el resto: la hora inexistente suena desplazada hacia delante lo que dura el
  salto, 02:30 del 29 de marzo → 03:30; la repetida, la primera vez). Título «Recordatorio»; cuerpo = primera línea
  no vacía de la nota (una sola línea, hasta 160 caracteres) o «Tienes un recordatorio para hoy» si no hay texto.
  **En un día de ausencia** (cualquiera de los turnos del día, por el día resuelto, sea override o rotación, es
  `ShiftCategory.absence`: baja médica, vacaciones...) el cuerpo es siempre «Tienes un recordatorio para hoy»: el
  texto de la nota podría ser de salud y las ausencias nunca salen en la pantalla de bloqueo. El recordatorio sí
  suena. Sin
  botones (no se pospone). Id determinista (`fecha||0|reminder`), payload con el mismo prefijo `cuadrante.alarm:`:
  reprogramar no duplica y un aviso quitado se cancela con los demás sobrantes.
- **Independiente de las alarmas de turno.** No necesita el interruptor general ni el del tipo de turno, y «Sin
  alarma este día» no lo silencia (es algo que el usuario pidió para ese día). Sí necesita el permiso de
  notificaciones: se pide **al poner el aviso** (nunca al arrancar) y, si se queda denegado, la fila lo dice («Las
  notificaciones están desactivadas, así que el aviso no sonará…»); el aviso se guarda igualmente. Con alarmas
  exactas sin conceder se programa de forma inexacta, como todo lo demás. No aparece en «Próximo aviso» (esa línea
  habla de turnos).
- **Un aviso cuya hora ya pasó no se programa** (el mismo minuto cuenta como pasado) y la fila lo dice: «Esa hora ya
  pasó: no sonará.»
- **Horizonte y tope.** Mismo horizonte que las alarmas (14 días por defecto, hasta 30): un aviso más lejano se
  programa al abrir la app cuando entra en la ventana. En el tope de 60, **los recordatorios van primero** (son pocos,
  del usuario y no se pueden recalcular desde la rotación), los más próximos primero; las alarmas de turno rellenan lo
  que quede, también las más próximas. El resultado se ordena por hora. Un recordatorio dentro del horizonte nunca se
  descarta por una alarma de turno; solo si hubiera más de 60 recordatorios en la ventana ganarían los más próximos.
- **Canal** `note_reminders`: importancia alta, tono y volumen de notificación (no de alarma), categoría
  `reminder`. `visibility: private`, como las alarmas: con «ocultar contenido sensible» la pantalla de bloqueo no
  enseña el texto de la nota.
- **Solo el calendario principal** (el mismo que las alarmas); en otro calendario la fila avisa de que no sonará.
- **Agenda.** Las notas con aviso llevan una campana pequeña con la hora (y la dicen en voz alta).

## Sonido por tipo de turno (0.6.0, hueco A3)

- **Dónde.** Ajustes › Mis turnos › (un tipo) › sección «Alarma» › «Sonido»: abre el selector de sonidos del sistema
  y enseña el elegido («Predeterminado» si no hay). «Usar el predeterminado» lo quita. La sección solo sale en Android
  y en tipos con horario que no sean ausencias (los únicos que pueden sonar). Se guarda al pulsar «Guardar», como el
  resto del formulario.
- **Dato.** `ShiftType.alarmSound` (esquema v3): URI `content://` del sistema, hasta 512 caracteres, `null` = el del
  canal por defecto. Va en la copia `.turnly` v3 (formato de las antiguas `.cuadrante`). La URI es de este móvil: restaurada en otro, si no existe, se cae
  al sonido por defecto sin error.
- **Selector.** `MainActivity` registra `app.cuadrante/sounds` (`AlarmSoundChannel.kt`): `pick` lanza
  `RingtoneManager.ACTION_RINGTONE_PICKER` (sonidos de alarma y de notificación, con la entrada «predeterminado» y
  sin «silencio»); `title` da el nombre limpio; `isAvailable` abre el recurso para saber si sigue existiendo.
  `AlarmSoundPolicy` (probada en JVM) solo acepta `content://` de hasta 512 caracteres **cuya autoridad sea
  exactamente `media` o `settings`** (lista cerrada, `ALLOWED_AUTHORITIES`): ni el `FileProvider` de share_plus
  (`<appId>.flutter.share_provider`) ni ningún proveedor de otra app. Trata la entrada predeterminada como `null`.
  Cada pregunta al proveedor (`title`, `isAvailable`) espera como mucho 3 s en su propio hilo
  (`AlarmSoundPolicy.runBounded`): uno atascado no bloquea a los demás. En Dart, `LocalAlarmScheduler` aplica el
  mismo límite (`soundTimeout`, 3 s): sin respuesta, el sonido cuenta como no disponible (canal por defecto) y
  el título se omite; así una resincronización nunca deja el mutex cogido. Al restaurar una copia, un sonido
  que no empiece por `content://media/` ni `content://settings/` se descarta a `null` (`docs/copia-de-seguridad.md`). En Dart: `AlarmSounds` (`PlatformAlarmSounds` en Android, `NoAlarmSounds` fuera,
  `FakeAlarmSounds` en las pruebas).
- **Un canal por sonido.** El sonido de un canal de Android no se puede cambiar una vez creado, así que cada sonido
  distinto tiene su canal `shift_alarm_<hash>` (FNV-1a de la URI en 8 hex, `alarm_channels.dart`), con el nombre
  «Alarmas de turno · <título>». `shift_alarms` sigue siendo el de `null`. `LocalAlarmScheduler.replaceAll` crea los
  canales que hacen falta **antes** de programar y, al acabar, **borra los `shift_alarm_*` que ya no usa ningún aviso**
  (solo por prefijo: nunca toca el canal por defecto, el de recordatorios ni los de otros plugins). Un canal que aún usa una notificación pendiente (un aviso pospuesto, que el plan no conoce) tampoco se borra: Android lo recrearía desde el aislado del botón con el id como nombre (`shift_alarm_1a2b3c4d`). Antes de Android 8
  el sonido va en la propia notificación.
- **Sonido que ya no existe.** En cada sincronización se pregunta por cada sonido distinto; si no se puede abrir, los
  avisos de ese tipo suenan por el canal por defecto (y su payload ya no lleva el sonido), sin crear canal ni fallar. El
  editor lo dice («No disponible: suena el predeterminado») y conserva la elección: si el recurso vuelve, vuelve a
  sonar. Si la comprobación falla, cuenta como no disponible.
- **Posponer.** El payload lleva el sonido (`c`), así que el aviso pospuesto suena por el mismo canal aunque se
  programe desde el aislado sin base de datos (ahí no se comprueba si el sonido sigue existiendo).
- **R8.** Una URI de contenido no es un recurso de la app: no hay nada que `keep.xml` deba proteger. El canal de
  plataforma lo registra el código Kotlin, que R8 conserva.
- **iOS.** El campo se guarda pero no se usa y la fila no sale. iOS usará sonidos incluidos en la app más adelante, en
  el Mac.

## Límites

- **iOS: 64 notificaciones locales pendientes por app.** Se programan como mucho 60 (`maxPendingAlarms`), 14 días
  por delante, y se renueva cada vez que se abre la app. Quien no abra la app en dos semanas se queda sin avisos
  a partir de ahí; con turnos muy densos (3 por día), el tope de 60 cubre unos 20 días. Los recordatorios de notas
  cuentan en el mismo tope y entran los primeros.
- **Android:** sin límite práctico, pero se aplica el mismo tope por coherencia.

## Horario de verano (Europe/Madrid)

La hora de aviso es hora de pared en la zona del móvil (`flutter_timezone`; si falla, Europe/Madrid). La conversión
a instante está en `data/wall_clock.dart`, con pruebas para 2026-03-29 y 2026-10-25:

- **Hora que no existe** (02:00 a 03:00 el 29 de marzo de 2026): se mueve **hacia delante** lo que dura el salto;
  02:30 suena a las 03:30. Nunca suena antes de lo pedido.
- **Hora que ocurre dos veces** (02:00 a 03:00 el 25 de octubre de 2026): se usa la **primera** aparición (verano),
  para que no llegue una hora tarde.
- Cualquier otra hora suena a esa hora local también el día del cambio (un aviso de las 20:30 sigue a las 20:30).
- Si el usuario cambia de zona horaria con la app cerrada, los avisos ya programados conservan el instante antiguo
  hasta la siguiente apertura, que reprograma con la zona nueva. Con la app viva, cada reprogramación
  (`LocalAlarmScheduler.replaceAll`) lee la zona del móvil otra vez, así que un cambio de zona se nota en la siguiente
  sincronización sin reiniciar el proceso.
- **Con la app viva y en primer plano** no hay reanudación ni edición que provoque esa sincronización, así que Android
  avisa por el canal `app.cuadrante/alarm_system` (`clockChanged`: `TIMEZONE_CHANGED` y `TIME_SET`, receptor dinámico de
  `MainActivity`, que antes reinicia la zona por defecto de la JVM). `AlarmsHost` replanifica al momento y `WidgetHost`
  republica el widget. La reanudación sigue replanificando siempre (camino en frío, app en segundo plano).
- «Próximo aviso» se recalcula solo un segundo después de la hora del aviso y al reanudar la pantalla (antes se quedaba
  con un aviso que ya había sonado).

## Android

- **Permisos** (manifest): `POST_NOTIFICATIONS` (permiso en ejecución desde Android 13, se pide al activar la primera
  alarma, nunca al arrancar), `RECEIVE_BOOT_COMPLETED` (reprogramar tras reiniciar), `VIBRATE` y
  `SCHEDULE_EXACT_ALARM`. Receptores: `ScheduledNotificationReceiver` y `ScheduledNotificationBootReceiver`
  (arranque, `MY_PACKAGE_REPLACED` y `QUICKBOOT_POWERON`), que sobreviven a reinicios y actualizaciones.
- **Alarmas exactas.** (29-oct-2026: en un OnePlus 8T con ahorro de batería, `exactAllowWhileIdle` llegó hasta 2 min tarde
  porque OxygenOS les da ventana; `setAlarmClock` no lo retrasa ningún fabricante, a cambio del icono de alarma en la barra
  y de salir como «próxima alarma» del sistema. Decisión del usuario.) Se usa `SCHEDULE_EXACT_ALARM` y **no** `USE_EXACT_ALARM`: este último está reservado por
  Google Play a apps cuya función principal es ser despertador o calendario y exige revisión. Desde Android 14 el
  permiso viene denegado en instalaciones nuevas: el usuario lo concede en «Alarmas y recordatorios». Si
  `canScheduleExactAlarms()` es verdadero, los avisos de turno (y su «Posponer» y «Probar aviso») se programan como **alarma de despertador**
  (`alarmClock`, `setAlarmClock`) y los demás (recordatorios, víspera) con `exactAllowWhileIdle`; si no, todos con `inexactAllowWhileIdle`
  (puede retrasarse unos minutos) y la UI debe avisarlo y ofrecer `requestExactAlarmPermission()`, que abre esa
  pantalla del sistema. La app lo comprueba en cada reprogramación, así que concederlo después se aplica al volver.
- **Icono pequeño (`ic_stat_alarm`).** Solo lo nombra el Dart (`AndroidInitializationSettings('ic_stat_alarm')`), así
  que R8 / `shrinkResources` lo quita del APK de **release** y todos los avisos fallan con «no valid small icon».
  `android/app/src/main/res/raw/keep.xml` (`tools:keep`) lo conserva, y `tool/qa/release_apk_check.sh` (primer paso de
  `release_check.sh`) falla si el APK de release no lo trae. Un recurso que solo se nombre desde el Dart se añade a esa
  lista.
- **Canales.** `shift_alarms` (sonido por defecto): importancia máxima, sonido y vibración, uso de audio «alarma»
  (suena con el volumen de alarmas, no el de tono) y categoría `alarm`. `shift_alarm_<hash>`: uno por sonido
  propio, igual que el anterior con ese sonido (ver «Sonido por tipo de turno»). `note_reminders`: recordatorios
  de notas, importancia alta y volumen de notificación.
- **Pantalla de bloqueo.** Cada aviso lleva `visibility: private`: si el usuario tiene «ocultar contenido sensible»
  (o no mostrar notificaciones en la pantalla de bloqueo), solo se ve el nombre de la app con el texto neutro que pone
  el propio sistema («Contenido oculto»); el detalle del turno aparece al desbloquear. `flutter_local_notifications` no
  deja adjuntar una versión pública propia (`publicVersion`, «Aviso de turno»); si hiciera falta ese texto concreto
  habría que escribir la notificación en Kotlin. Las ausencias ya no generan avisos (ver el planificador).
- **Declaración en Play Console.** Hay que declarar el uso de `SCHEDULE_EXACT_ALARM` (formulario «Alarmas y
  recordatorios exactos» en el contenido de la app). Texto propuesto: «Turnly avisa a trabajadores a turnos a una
  hora exacta antes de que empiece su turno (por ejemplo, un turno de noche a las 22:00). Un aviso con minutos de
  retraso puede hacer que lleguen tarde al trabajo. El permiso lo concede el usuario y la app sigue funcionando sin él
  con avisos aproximados.»
- Ahorro de batería y fabricantes (Samsung, Xiaomi, Huawei, OnePlus) pueden matar procesos y bloquear receptores. Un
  `setExactAndAllowWhileIdle` atraviesa Doze, pero el criterio de publicación (10 de 10 con ahorro de batería) hay que
  comprobarlo en dispositivos reales. Si falla en algún fabricante, alternativas: `AndroidScheduleMode.alarmClock`
  (`setAlarmClock`, exento de Doze y de la mayoría de ahorros, con icono de alarma en la barra) o guiar al usuario a
  excluir la app de la optimización de batería.

## iOS

- Notificaciones locales (`UNCalendarNotificationTrigger` vía `zonedSchedule`). El permiso **no se pide al arrancar**:
  `AlarmScheduler.requestPermission()` lo pide la primera vez que el usuario activa un aviso (desde
  `AlarmSettingsController.requestPermission()`).
- Nivel de interrupción `timeSensitive`. Requiere la capacidad «Time Sensitive Notifications» en Xcode (fase Mac);
  sin ella el sistema lo trata como una notificación normal. Una notificación local no atraviesa el interruptor de
  silencio ni «No molestar» como un despertador; eso solo lo da AlarmKit.
- `AppDelegate.swift` fija `UNUserNotificationCenter.current().delegate = self` (línea documentada por el plugin, como en
  Mochila) para que el aviso se vea también con la app abierta. Sin compilar en Windows.
- No compilado ni probado en Windows: todo el código de iOS está escrito contra la documentación del plugin.
- **Sonido por tipo (A3): sin función en iOS.** `ShiftType.alarmSound` se guarda y viaja en la copia, pero no se usa
  ni se muestra; iOS usará sonidos incluidos en la app (`UNNotificationSound(named:)`) en la fase del Mac. El
  recordatorio de una nota sí usa las notificaciones locales de siempre.

## Idea para la v1.1: AlarmKit (iOS 26)

AlarmKit permite alarmas reales del sistema (suenan en silencio y con Enfoque, con pantalla de bloqueo y Live
Activity), que es lo que un turnero espera de «una alarma». Pendientes antes de decidir: comprobar soporte desde
Flutter (hoy habría que escribir un canal nativo en Swift), el permiso propio de AlarmKit y su comportamiento con
muchas alarmas. Mientras tanto se mantiene la ruta de notificaciones locales como respaldo para iOS 17 y 18.

## Prueba manual 10 de 10

Criterio de publicación: las alarmas suenan 10 de 10 veces con el ahorro de batería activado, en iOS 17, 18 y 26 y en
Android 13 a 16 (incluidos Samsung y Xiaomi).

1. Instalar un build de prueba. En Ajustes › Alarmas: interruptor general, un tipo de turno con horario y «Antes del
   turno» a 30 min (o personalizado de 5 min para el ciclo de pruebas); pintar turnos de ese tipo en los próximos
   días.
2. Conceder notificaciones y, en Android, «Alarmas y recordatorios». Anotar el modelo, la versión del sistema y si
   se concedió.
3. Activar **modo de bajo consumo / ahorro de batería** y poner el móvil en **silencio** (iOS: interruptor lateral;
   Android: silencio, con volumen de alarma audible).
4. **Cerrar la app de multitarea** (quitarla del selector) y bloquear el móvil. No abrirla hasta terminar.
5. Programar 10 alarmas separadas al menos 10 minutos (o 2 al día durante 5 días). Para cada una, anotar hora
   prevista, hora real a la que sonó, y si fue con la pantalla bloqueada: `OK` solo si sonó dentro de 1 minuto (exacta)
   o dentro de 5 minutos (si no hay permiso exacto).
6. Repetir con las perturbaciones: reiniciar el móvil con alarmas pendientes (deben sonar sin abrir la app), modo
   avión, cambio de zona horaria (Madrid, Canarias, Madrid) y las noches del 29 de marzo y 25 de octubre
   (adelantando la fecha del sistema).
7. Verificar también: cambiar un turno pintando y comprobar que el aviso antiguo desaparece y el nuevo suena; que no
   hay duplicados; y que apagar el interruptor global cancela todo.
8. Resultado en `docs/qa/alarmas-10-de-10.md` (una fila por dispositivo y por intento). Criterio: **10 de 10** por
   dispositivo; un fallo bloquea la publicación hasta entenderlo.

## Pendiente de probar en dispositivo

- **Sin `READ_MEDIA_AUDIO` en Android 13+**, los tonos que el usuario ha añadido a mano
  (`content://media/external/...`) pueden fallar `canOpen` y caer al sonido por defecto. Los tonos incluidos en
  el sistema deberían funcionar.
- **Decisión de momento: no se pide `READ_MEDIA_AUDIO`.** Verificarlo en un dispositivo y, si hiciera falta, dejar
  que el editor diga «No disponible: suena el predeterminado», que ya existe.

## Sin probar en dispositivo (a fecha de este documento)

Sonido real y volumen de alarma, comportamiento con ahorro de batería y por fabricante, reprogramación tras reinicio,
`canScheduleExactNotifications` y el flujo de «Alarmas y recordatorios», iOS en general (permiso, nivel
`timeSensitive`, tope de 64) y el cambio de zona horaria con la app cerrada. De lo nuevo: el botón «Posponer 10 min»
con la app cerrada y con ahorro de batería (arranque del motor en segundo plano), «Ya estoy despierto», que el
aviso pospuesto suene a los 10 minutos, el aviso del día anterior en las noches de cambio de hora, la apertura de
«Alarmas y recordatorios» y la notificación de «Probar aviso». Las categorías de acciones de iOS no se han probado.

De la 0.6.0, **solo probado con pruebas de Dart y de JVM y con el plugin simulado** (los escenarios Q93 a Q95 de la
batería están escritos, no ejecutados): que el selector de sonidos del sistema se abra y devuelva la URI en cada
versión de Android y fabricante (Samsung, Xiaomi); que el sonido elegido suene de verdad por su canal y con el
volumen de alarmas; qué hace Android con un canal cuyo sonido se borró después de programar el aviso (la app lo
corrige en la siguiente sincronización); el borrado de canales sobrantes; que el recordatorio de una nota suene con
la app cerrada, con ahorro de batería y tras reiniciar; y el texto de la nota en la pantalla de bloqueo (debe
ocultarse con «ocultar contenido sensible»).
