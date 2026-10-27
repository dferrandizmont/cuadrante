# Privacidad y cumplimiento

No es asesoramiento jurídico. Resume qué hace la app con los datos, comprobado contra el código el 26-oct-2026;
revisar con un profesional antes del lanzamiento. La política para el usuario está en
[`docs/legal/politica-privacidad.md`](legal/politica-privacidad.md) y tiene que decir lo mismo que este documento.
English version: [`privacy.en.md`](privacy.en.md).

## Flujo de datos (decisión del dueño, 26-oct-2026)
- **La app no habla con ningún servidor.** No hay cuentas, servidor propio, analítica, telemetría, anuncios,
  compras ni identificadores de instalación. El manifiesto de release de Android no declara `INTERNET` (solo los
  de `debug` y `profile`, para Flutter); el código Dart no tiene cliente HTTP. Los festivos van incluidos en la app
  (`app/assets/holidays/`); la descarga remota descrita en `docs/festivos.md` no existe.
- **Informes de errores:** el único `CrashReporter` instalado es `NoopCrashReporter` (`app/lib/main.dart`), envuelto
  en `RedactingCrashReporter`: no sale nada del móvil. Si algún día se añadiera un backend, la interfaz
  (`app/lib/core/diagnostics/crash_reporting.dart`) solo deja pasar el tipo del error y la traza, nunca el mensaje.
- **App 100 % gratuita y de código abierto**: código MIT, contenido propio CC BY-SA 4.0
  (`LICENSE`, `LICENSE-CONTENT.md`). La configuración **ya no tiene** campos de RevenueCat (`rcApiKey*` se retiraron de
  `app/lib/core/config.dart`) y no hay SDK de compras en `app/pubspec.yaml`.
- Todo funciona sin conexión y sin pedir nombre, correo, teléfono ni edad.

## Qué se guarda en el móvil
Base de datos Drift `cuadrante.sqlite` en Application Support (`docs/datos.md`): calendarios, tipos de turno,
rotaciones, excepciones por día, **notas**, recordatorios, horas extra, **ausencias** (vacaciones, moscosos, libre
disposición, permisos y **baja médica**, categoría `absence`), festivos propios, comunidad y municipio, precio por
hora y ajustes. Sin identificadores de dispositivo ni de usuario.

**Datos de salud.** La baja médica es un tipo de ausencia como los demás y vive en la misma base de datos. No hay
feed compartido ni analítica; sí se incluye en las copias descritas más abajo, según la decisión 13 resuelta por
el usuario el 26-oct-2026. Dónde aparece y dónde no, según el código actual:

| Dónde | Qué pasa con las ausencias (baja incluida) |
|---|---|
| Alarmas | Nunca suenan (`alarm_planner.dart`; `docs/alarmas.md`): un aviso de «baja» en la pantalla de bloqueo sería un dato de salud a la vista. El recordatorio de una nota en un día de ausencia lleva el cuerpo neutro «Tienes un recordatorio para hoy». |
| Widgets de hoy, semana y mes | Enseñan los turnos del día como el calendario, ausencias incluidas (código y color del tipo), y sus descripciones de accesibilidad nombran todos los turnos del día (`docs/widget-contrato.md`, extensión `descriptions`; `widget_snapshot_builder.dart`). Solo en el móvil, pero a la vista de quien tenga el teléfono en la mano. |
| Widgets de agenda y dos semanas | Anonimizadas: «Ausencia», sin código, nombre, horas ni marca de nota. |
| Notas | Al widget solo viaja si el día tiene nota, nunca el texto. |
| Copia `.cuadrante` | Van dentro (apartado siguiente). |
| Copia del sistema de Android | Van dentro, con la base de datos (apartado «Copias del sistema»). |
| Exportar al calendario del móvil | No salen salvo que el usuario active «Incluir ausencias» (apagado de serie). |

La decisión 13 de `docs/preguntas.md` **quedó resuelta por el usuario el 26-oct-2026: dejarlo como está**. Las
ausencias de salud siguen en la misma base de datos y viajan en las copias `.cuadrante` y en las del sistema,
como explica la política. No se crea un almacén aparte. Activar la réplica en iCloud es otra decisión, pendiente
para el Mac; `kICloudReplica` sigue en `false`.

## Permisos
Todos se piden cuando el usuario toca la función, nunca al arrancar.

| Permiso | Para qué | Dónde |
|---|---|---|
| Notificaciones (`POST_NOTIFICATIONS`, Android 13+; permiso de notificaciones en iOS) | Alarmas de turno y recordatorios de notas. Se pide al activarlas o al probar una alarma (`alarm_providers.dart`, `ensureNotificationPermission`). | `AndroidManifest.xml` |
| Alarmas exactas (`SCHEDULE_EXACT_ALARM`) | Que la alarma suene a su hora y el widget cambie de día a medianoche. Sin él, alarmas inexactas. No se usa `USE_EXACT_ALARM`. | `AndroidManifest.xml` |
| `RECEIVE_BOOT_COMPLETED`, `VIBRATE` | Reprogramar las alarmas tras reiniciar o actualizar; vibrar. | `AndroidManifest.xml` |
| `HIDE_OVERLAY_WINDOWS` (normal, sin diálogo) | Que la vista previa de restaurar no la tape otra app (tapjacking). | `AndroidManifest.xml`, `MainActivity` |
| Calendario (`READ_CALENDAR`, `WRITE_CALENDAR`; `NSCalendars*UsageDescription` en iOS) | Leer eventos al importar desde el calendario del móvil; escribir al exportar una vez. Solo durante esa acción, nunca en segundo plano. | `AndroidManifest.xml`, `app/ios/Runner/Info.plist`, `docs/importar.md` |

Sin permisos de ubicación, contactos, fotos, cámara, micrófono, almacenamiento general ni red. Los archivos se eligen
con el selector del sistema (`file_selector`) y se comparten con la hoja del sistema (`share_plus`).

## Copias de seguridad (`docs/copia-de-seguridad.md`)
- **`.cuadrante`:** JSON canónico comprimido con gzip y con suma de control; **no está cifrado**. Contiene todo lo
  que el usuario creó (ausencias y notas incluidas), sin cuentas ni identificadores. No entran los ajustes de primer
  uso ni el idioma.
- **Copias automáticas locales:** tras cada ráfaga de cambios, en `<Application Support>/backups`: las 7 más nuevas y
  la última de cada día de los últimos 30; copias previas a restaurar y a migrar, las 3 últimas de cada una. Todo en
  el móvil; nada se envía.
- **Exportar y restaurar:** el usuario guarda o comparte el archivo con la hoja del sistema (`_shareWithSystem`,
  `backup_providers.dart`) y lo abre desde Archivos, Drive o WhatsApp; nada se restaura sin su confirmación en la
  vista previa. Dónde acabe ese archivo es decisión suya.
- **Réplica en iCloud: apagada.** `kICloudReplica = false` en `backup_providers.dart`; el canal Swift no existe y,
  aun existiendo, haría falta el interruptor de Ajustes. Activarla requiere otra decisión en el Mac, según la
  respuesta del usuario del 26-oct-2026 a la decisión 13.

## Copias del sistema
- **Android (Auto Backup):** `allowBackup="true"` con reglas explícitas (`res/xml/backup_rules.xml`,
  `data_extraction_rules.xml`): entra `files/` (la base de datos y `backups/`), nada más. El sistema lo sube a la
  cuenta de Google del usuario y lo pasa de móvil a móvil; cifrado de extremo a extremo con el bloqueo de pantalla en
  Android 9 o superior **si el usuario tiene bloqueo**. Nosotros no lo vemos, pero los datos **sí salen del móvil**
  por esa vía, ausencias incluidas. No decir «nunca salen del móvil».
- **iOS:** la base de datos entra en la copia del iPhone (iCloud o del ordenador), que gestiona el usuario con su
  Apple ID.

## Importar y exportar (`docs/importar.md`)
- **Importar** desde el calendario del móvil, desde archivos `.ics` o CSV, o desde una copia de LRHSoft
  (`.Shifter`): se lee en el móvil, se agrupa en el móvil y solo se guarda lo que el usuario acepta. Los mensajes de
  error nunca llevan texto del archivo. Los archivos de otra app se tratan como entrada hostil (solo lectura, límites
  de tamaño, copia temporal que se borra).
- **Exportar al calendario del móvil** (una vez, por acción del usuario): escribe título («Mañana · M»), horario y una
  etiqueta propia; nunca notas ni cantidades. Si ese calendario se sincroniza con una cuenta (Google, iCloud,
  Exchange), **la sube el sistema a esa cuenta**, fuera del control de la app; la pantalla lo avisa. Ausencias y
  días libres solo con sus interruptores, apagados de serie.
- No hay exportación a `.ics`, CSV, PDF ni compartir por enlace: la única salida de datos es el `.cuadrante` y el
  calendario del móvil.

## Widgets (`docs/widget-contrato.md`)
La app escribe un JSON con los próximos 60 días (y los auxiliares de agenda y dos semanas) en el almacén compartido
con los widgets: `UserDefaults` del App Group `group.es.cuadrante.app` en iOS y las preferencias de `home_widget` en
Android, que no entran en la copia del sistema. Solo lo leen los widgets de esta app.

## Soporte y enlaces
«Ayuda y contacto» (Ajustes) enseña la dirección de soporte para **copiarla**; la app no abre el correo.
La dirección es **dev@mainshai.com**, definida en `kSupportEmail`
(`app/lib/core/config.dart`); el build puede sustituirla con `--dart-define=SUPPORT_EMAIL=...`.
«Licencias de código abierto» abre la página de licencias de Flutter, sin conexión.
«Política de privacidad» (Ajustes › Ayuda) abre la web en el **navegador externo**, solo al tocar la fila, mediante
el plugin oficial `url_launcher`. No envía datos del cuadrante ni añade permiso `INTERNET` a la app: el navegador
hace la conexión. `PRIVACY_URL` apunta por defecto a `https://dferrandizmont.github.io/cuadrante/privacidad/`;
en inglés se usa `PRIVACY_URL_EN` (`https://dferrandizmont.github.io/cuadrante/privacidad/en/`). Las dos URL pueden
cambiarse con `--dart-define`. La web española es la referencia para los demás idiomas.

## Declaraciones en tiendas
- App Store, App Privacy: **no se recogen datos**, sin seguimiento ni compras dentro de la app
  (`docs/tienda/app-store.md`).
- Google Play, Seguridad de los datos: **no se recogen ni comparten datos** desde la app; sin anuncios ni compras.
  Leer el calendario o guardar notas en el móvil no es recopilar (`docs/tienda/google-play.md`, «Seguridad de los
  datos»). Declarar los permisos de calendario y alarmas exactas con su justificación.
- No hay cuentas que borrar; los datos se eliminan desinstalando la app o borrando sus datos desde el sistema (y, si
  procede, de las copias de Google o iCloud del usuario).
- Revisar los formularios con el AAB/IPA definitivo y publicar una URL de política coherente con estos hechos.

## Pendiente antes del lanzamiento
- [x] Decisión 13 resuelta (usuario, 26-oct-2026): se mantiene el comportamiento actual, con las ausencias de salud
      en la misma base de datos y en las copias, como explica la política.
- [ ] Comprobar la pantalla «Ayuda y contacto» en el build de release; `kSupportEmail` ya contiene `dev@mainshai.com`.
- [ ] Publicar la política de privacidad (URL), enlazarla desde las dos tiendas y comprobar las dos URL desde la
      fila de Ajustes ya implementada (`docs/legal/LEEME.md`).
- [ ] Rellenar App Privacy (Apple) y Seguridad de los datos (Play) con el binario final.
- [ ] Mantener `kICloudReplica = false` hasta la decisión independiente sobre activar la réplica en el Mac.
- [ ] Revisar este documento cada vez que cambie el flujo de datos (permisos, copias, exportaciones, soporte).
