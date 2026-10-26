# Importar y exportar turnos

Estado: asistente de importación (calendario del móvil, `.ics`, CSV y la copia `.Shifter` de LRHSoft) y exportación única al calendario del móvil
hechos y probados en Dart (`app/lib/features/import/`, `app/lib/features/calendar_export/`). Falta la prueba en
dispositivos reales (ver el final). Referencias: `turnos-spec.md` §3 P0.6 y §6 («Importar desde calendario»),
`docs/paridad.md` y `docs/roadmap.md` (exportar **una vez** al calendario del móvil es gratis; la sincronización
continua, más adelante, también será gratuita), `docs/motor-de-turnos.md` (una escritura es **un** paso de deshacer),
`docs/alarmas.md` (patrón de permisos).

## Qué hace

- **Importar** trae turnos ya hechos a un calendario de Cuadrante: desde la copia de seguridad `.Shifter` de LRHSoft
  (la vía completa y gratis para quien viene de ahí), desde el calendario del móvil (el historial de Supershift, por
  ejemplo), desde un archivo `.ics` o desde un CSV.
- **Exportar** copia los turnos de Cuadrante a un calendario del móvil, una sola vez. Si se repite, **sustituye** lo
  que Cuadrante escribió antes en esas fechas en vez de duplicarlo.

Está en Ajustes › «Importar y exportar» (`/ajustes/importar` y `/ajustes/exportar`) y, para importar, también en el
paso 4 del primer uso («¿Vienes de otra app?»).

## Privacidad

**Importar** no envía nada a ningún sitio. No hay servidor, ni cuenta, ni analítica de lo que se importa. Los eventos
se leen en el móvil, se agrupan en el móvil y solo se guarda lo que el usuario acepta en la vista previa. Los
mensajes de error nunca llevan texto del archivo ni títulos de eventos.

**Exportar sí escribe en un calendario del móvil, y ese calendario puede estar sincronizado con una cuenta** (Google,
iCloud, Exchange...): lo que se escribe ahí lo sube el propio sistema a esa cuenta, fuera del control de Cuadrante.
Por eso:

- **Las ausencias no se exportan por defecto** (`ShiftCategory.absence`: vacaciones, asuntos propios y, sobre todo,
  la **baja médica**, que según las reglas del producto se queda en el móvil). Solo salen si el usuario activa
  **«Incluir ausencias»** (apagado de serie; el texto avisa de que irían a ese calendario y a su cuenta). Los días
  libres siguen su propio interruptor.
- Si el calendario elegido es de una cuenta que sincroniza (`DeviceCalendarInfo.isSynced`: el tipo de cuenta no es
  `local`), la pantalla dice «Este calendario se sincroniza con {cuenta}: tus turnos se verán allí.». Con uno local no
  dice nada. «Crear el calendario Cuadrante» es local en Android; en iOS puede acabar en iCloud (no se puede saber
  antes de crearlo) y el aviso de permiso ya lo menciona.
- Qué se escribe: título («Mañana · M»), horario y una descripción con la marca y la etiqueta. Nunca notas del día,
  cantidades de dinero ni nada más.
- Los textos de permiso (tarjeta, `NSCalendarsFullAccessUsageDescription` y `NSCalendarsUsageDescription`) ya no
  dicen que nada sale del móvil: explican que se leen turnos al importar y, si el usuario lo pide, se añaden turnos
  al calendario que elija (y a su cuenta, si la tiene).

**Permisos del calendario** (solo cuando el usuario empieza a importar desde el calendario o a exportar; nunca al
arrancar, ni para importar un archivo):

| Plataforma | Permiso | Declaración |
|---|---|---|
| Android | `READ_CALENDAR` y `WRITE_CALENDAR` (un solo grupo, un solo cuadro del sistema) | `AndroidManifest.xml`. En Play Console, «Seguridad de los datos»: calendario, uso local; Cuadrante no lo envía a ningún servidor propio, pero lo que se exporta a un calendario sincronizado lo sube el sistema a esa cuenta (decirlo en la ficha) |
| iOS | Acceso completo al calendario (`NSCalendarsFullAccessUsageDescription`, y `NSCalendarsUsageDescription` para iOS 16 o anterior) | `Info.plist`: «Para leer turnos de tu calendario al importar y, si tú lo pides, añadir tus turnos al calendario que elijas. Si ese calendario se sincroniza con una cuenta, esa cuenta también los recibirá.» |

El texto de la tarjeta de permiso explica el motivo **antes** de pedirlo; el botón «Permitir acceso» es lo único que
muestra el cuadro del sistema. **Solo se da por bloqueado cuando volver a preguntar no serviría** (H-T14-6, la misma
regla que `NotificationPermissionPolicy` para las notificaciones): en Android la primera negativa se puede volver a
preguntar (el plugin la devuelve como «denied» al responder el cuadro, pero al leer el permiso después dice
«notDetermined»), así que la tarjeta sigue ofreciendo «Permitir acceso» con una línea que dice que no se ha dado
(`askForAccess`, `CalendarPromptOutcome`). Solo cuando el sistema ya no muestra la pregunta (segunda negativa, y en iOS la
primera, que es definitiva) la tarjeta explica cómo activarlo (Ajustes › Permisos › Calendario) y
ofrece «Abrir ajustes» y «Comprobar de nuevo». Con un permiso restringido por el sistema (control parental, perfil de
trabajo) lo dice y sugiere un archivo. En iOS 17 el permiso de «solo añadir» no basta (no deja leer ni sustituir):
se vuelve a pedir el acceso completo.

## El asistente de importación

Un asistente de pasos (`/ajustes/importar`); según el origen son 4 o 5:

1. **Origen**: copia de LRHSoft (`.Shifter`), calendario del móvil, archivo `.ics`, archivo CSV.
2. **Calendarios** (solo calendario del móvil): cuenta, nombre y color de cada uno; se marcan los que traen turnos.
   Los ocultos no salen.
   **Columnas** (solo CSV): ver más abajo.
3. **Fechas**: por defecto los últimos 12 meses y los próximos 6. Para un archivo, las fechas que menciona, **sin pasar
   nunca de los próximos 6 meses** (una serie con `UNTIL=2099` o `COUNT=500` abre en torno a hoy, no en 2099; las
   series que no terminan llegan justo hasta ahí). Un archivo que empieza después de ese horizonte conserva sus
   fechas. Máximo 5 años (si el archivo abarca más, se queda lo más reciente).
4. **Títulos a turnos**: los eventos se **agrupan por título normalizado** (mayúsculas, tildes, espacios y adornos no
   cuentan: «Mañana», «MAÑANA », «mañana ☀» son un grupo). Cada grupo enseña cuántos días cubre, su horario más
   habitual y unos días de ejemplo, y se asocia a:
   - un tipo de turno que ya existe,
   - **«Crear tipo nuevo»**, con nombre, código libre, horario y color sacados de los eventos (editable),
   - o **«Ignorar»**.

   Los recuentos de este paso (el resumen y el de cada grupo) cuentan **días, no turnos**: un día con dos turnos
   cuenta una vez, y el número coincide con el de los días que dice el paso anterior (H-T22-14).
5. **Vista previa**: los meses afectados con la misma celda que el calendario, el recuento y, si hay días que ya
   tienen turno, **«Sustituir»** o **«Mantener lo mío»**.

Al pulsar «Importar» se aplica **un solo paso de deshacer** en el calendario que se está viendo (con los tipos nuevos
guardados en la misma transacción). Después la app **va al calendario, en el primer mes importado** (H-T14-7), con el
aviso «Se han importado N días · Deshacer» encima, que solo actúa mientras la importación siga siendo lo último que se
hizo. Ese «Deshacer» **borra también los tipos de turno que creó la importación**, siempre que nada los use (ningún
día de ningún calendario y ninguna rotación); si algo los usa, el tipo se queda y el aviso lo dice (H-T22-8). La barra
de abajo («Atrás» y «Siguiente»/«Importar N días») usa `AdaptiveButtonRow`: con texto grande los botones pasan uno
bajo el otro y nunca se parte una palabra (H-T14-1).

### Sugerencias

Cada grupo se asocia solo cuando hay una coincidencia clara, por este orden:

1. el título es el nombre del tipo («Mañana») o su código («M»);
2. el título contiene el nombre o el código («Turno mañana», «Turno M»), o el nombre contiene el título («Guardia»
   para «Guardia 24 h»);
3. el horario coincide (mismo inicio y fin, o a menos de 30 min) **y** el grupo cubre al menos 4 días (un «Dentista»
   suelto de 8:00 a 14:00 no es una Mañana).

Un grupo sin coincidencia empieza en «Ignorar»: nunca se crean tipos sin que el usuario lo decida. Lo sugerido lleva la
marca «Sugerido» hasta que se cambia.

### Cómo se traducen los eventos a días

- Los eventos **de todo el día** funcionan como los que tienen horas. Los de varios días se reparten **un día cada
  uno** (como mucho 366 por evento). El fin de un evento de todo el día es exclusivo (el 19 al 22 son tres días); si
  la plataforma da el fin dentro del último día (iOS) también se cubre.
- Un evento que **cruza la medianoche** (22:00–06:00) pertenece al **día en que empieza**, como en el motor.
- Un día con varios eventos recibe varios turnos, en orden de hora (los de todo el día primero), sin repetir.
- Como al pintar, si el resultado coincide con lo que da la rotación no se guarda excepción, y la nota del día se
  conserva. Si los turnos del día ya eran esos, no cuenta como conflicto ni se escribe.
- **Conflicto** = el día ya tiene turnos (de la rotación o pintados) y son otros. «Sustituir» los cambia;
  «Mantener lo mío» los deja y solo rellena los vacíos.
- Un tipo nuevo solo se crea si algún día que se escribe lo usa.

## Archivos `.ics` (RFC 5545)

Lector propio, mínimo y tolerante (`domain/ics_parser.dart`, `recurrence.dart`, `ics_expansion.dart`). Nunca lanza
una excepción por contenido raro: lo que no entiende lo salta; solo un texto que no es un calendario da un error
tipado («Ese archivo no parece un calendario .ics»).

Entiende:

- Líneas plegadas (espacio o tabulador), finales de línea CRLF, LF o CR, BOM; UTF-8, UTF-16 con BOM y, si no es UTF-8
  válido, **Windows-1252** (con el euro, las comillas curvas y las rayas del rango 0x80–0x9F; no Latin-1).
- `VEVENT` con `DTSTART` y `DTEND` o `DURATION` (también en eventos de todo el día: `DURATION:P3D` cubre tres días);
  `SUMMARY`, `UID`, `STATUS:CANCELLED` (no se importa). Una `DURATION` de más de 366 días se rechaza: el evento se
  salta y se cuenta.
- Fechas `VALUE=DATE` (todo el día), fecha y hora **flotantes** (hora del móvil), con **`Z`** (UTC) y con **`TZID`**
  (Europe/Madrid y cualquier zona de la base de datos de zonas, más los nombres de Windows habituales como
  «Romance Standard Time»). Las horas se pasan a la zona del móvil; una zona desconocida se lee como hora del móvil.
- Escapes `\n`, `\,`, `\;`, `\\`.
- **`RRULE`** con `FREQ=DAILY|WEEKLY|MONTHLY`, `INTERVAL`, `COUNT`, `UNTIL`, `BYDAY` (con ordinales en mensual:
  `1MO`, `-1FR`), `BYMONTHDAY` (también negativos), `BYMONTH` y `WKST`; `EXDATE` (con hora o de todo el día) y
  `RECURRENCE-ID` (la ocurrencia sustituida deja paso a la que la reemplaza). Se expande **solo dentro del rango
  elegido**.
- Se **ignoran** `VTODO`, `VJOURNAL`, `VALARM` (su `SUMMARY` no se confunde con el del evento), `VTIMEZONE` y todo lo
  demás.

No entiende (el evento cuenta una sola vez, el primer día, y el asistente lo avisa): `FREQ=YEARLY` y las demás,
`BYSETPOS`, `BYWEEKNO`, `BYYEARDAY`, intervalos fuera de 1 a 1000, y listas `BYDAY` / `BYMONTHDAY` / `BYMONTH` más
largas de lo razonable (ver abajo). `RDATE` se ignora. `UNTIL` se compara por su fecha. En las listas `BY...` lo
repetido cuenta una vez.

### Límites

| Límite | Valor | Qué pasa |
|---|---|---|
| Tamaño del archivo | 5 MB | «El archivo pesa más de 5 MB». Se comprueba antes de **leer los bytes** en la app; en Android el selector ya lo ha copiado entero a la caché (ver «Pendiente») |
| Eventos leídos | 5 000 (los más antiguos del rango) | Mensaje «Hay más de 5000 eventos» en el paso de títulos |
| Días resultantes | 20 000 | igual |
| `VEVENT` en un archivo | 50 000 | el resto se salta y se cuenta |
| Rango | 5 años | se recorta el principio |
| Evento de todo el día | 366 días | se corta |
| `DURATION` | 366 días | el evento se salta y se cuenta |
| Anidamiento de `BEGIN` | 32 niveles | los más profundos se ignoran como desconocidos; un `END` sin su `BEGIN` se descarta en tiempo constante |
| `BYDAY` / `BYMONTHDAY` / `BYMONTH` | 77 / 62 / 12 entradas distintas (tras quitar repetidas; más de 1 000 sin quitar) | la regla no es válida: el evento cuenta una vez y se avisa |
| Pasos de una regla | 200 000 | la regla se detiene (nunca cuelga) |
| Pasos de todas las reglas del archivo | 2 000 000 (expansión) y 2 000 000 (cálculo de fechas del archivo) | se detiene y se marca como recortado |
| Eventos de un solo día fuera del rango | no cuentan | un archivo con 20 000 eventos de 2010 no gasta el presupuesto de los de este año |
| Tiempo de un trabajo en segundo plano | 30 s | «Ese archivo es demasiado grande o complicado y tarda demasiado» (`ImportProblem.tooComplex`) |

Todo el trabajo pesado va en un **aislado** aparte (`Isolate.run`) y la interfaz solo lee campos ya calculados:
leer el `.ics`, **primera y última fecha del archivo** y si hay series abiertas (campos de `IcsDocument`, calculados
al leer), expandir series, leer el CSV y adivinar sus columnas, leer sus filas, expandir los eventos del calendario
del móvil y agruparlos. Cada trabajo espera como mucho 30 s (`importTimeoutProvider`): un aislado no se puede matar
desde fuera, así que pasado el tiempo el asistente deja de esperar y muestra el error (el trabajo puede seguir un
rato en segundo plano y su resultado se descarta). Un evento que falla al expandirse (una fecha que el calendario no
puede representar) se salta; nunca aborta la importación.

## Archivos CSV

- **Separador** detectado (`,`, `;` o tabulador), comillas `"` con `""` y saltos de línea dentro de comillas.
- **Cabecera** detectada (la primera fila sin ninguna fecha); un interruptor permite corregirla.
- **Fechas**: `dd/mm/aaaa` (también con `-` o `.`, día y mes de una cifra, año de dos cifras), `aaaa-mm-dd`,
  `aaaammdd`, con hora opcional detrás. Siempre **día primero**, nunca mes primero.
- **Columnas**: fecha, turno o código, y opcionalmente hora de inicio y de fin (`8:00`, `08:30`, `8.30`, `8h`, `8h30`).
  Se adivinan por el contenido y por los nombres de la cabecera; el paso «¿Qué es cada columna?» enseña las primeras 5
  filas y deja cambiarlas.
- Sin hora, la fila es de todo el día. Una fecha con hora dentro de la celda da el inicio si no hay columna de hora, y
  también cuando la hay pero la celda de esa fila está vacía.
- Una columna no puede tener dos funciones: si eliges para una función la columna de otra, la otra la suelta (las
  obligatorias, fecha y título, intercambian columnas).
- **Límites**: 50 columnas (lo que sobra de cada fila se descarta) y 120 caracteres por celda, al leer. La vista previa
  muestra cada celda en una línea con puntos suspensivos y el selector de columnas tiene como mucho 50 entradas.
- La lectura, la adivinación de columnas y el cambio de cabecera van en el aislado, con el mismo tiempo máximo.
- Las filas sin fecha válida o sin título se **saltan y se cuentan** («3 filas se han saltado… por ejemplo, la
  línea 5»).
- Mismos límites de tamaño y de 5 000 filas.

## Exportar una vez al calendario del móvil

`/ajustes/exportar`. Gratis; la sincronización continua no forma parte de esto (más adelante, y también gratuita).

- **Calendario**: uno que ya exista y se pueda escribir (los de solo lectura y los ocultos no salen) o **«Crear el
  calendario "Cuadrante"»** (en Android, una cuenta local «Cuadrante»; en iOS, iCloud o local). Si ya hay uno que se
  llama «Cuadrante» viene elegido.
- **Fechas**: por defecto los próximos 3 meses desde hoy; como mucho un año (366 días). El aviso «se ha recortado el
  final» solo sale si el rango pedido pasaba de eso.
- Cada turno es un evento: título **«Mañana · M»** (nombre · código), con su horario (un turno de noche acaba al día
  siguiente; una guardia de 24 h, a la misma hora del día siguiente) o **de todo el día** si el tipo no tiene horario.
- **Turno partido** (A12): un tipo con segundo tramo se exporta como **dos eventos** con el mismo título, uno por
  tramo («Partido · P» 09:00–13:00 y 17:00–21:00; un tramo que acaba o empieza pasada la medianoche cae en el día
  siguiente). Las dos etiquetas llevan el día en que empieza el primer tramo y se distinguen por la `<n>`: el primer
  tramo usa la posición del turno en el día, como siempre, y el segundo `<n> + 100`
  (`exportSecondSegmentIndexOffset`; `…:partido:1` y `…:partido:101`). Así las exportaciones hechas antes de existir el
  turno partido siguen reconociéndose, la expresión de la etiqueta (`(\d+)`) no cambia, y volver a exportar sustituye
  los dos eventos sin duplicar (si el tramo cambia solo se rehace ese; si el día deja de ser partido se borran los
  dos). El resumen cuenta eventos, no turnos.
- **Días libres**: los turnos de categoría «descanso» (Libre, Saliente) no se exportan salvo que se active «Incluir
  los días libres».
- **Ausencias** (vacaciones, asuntos propios, baja médica): **no se exportan** salvo que se active «Incluir
  ausencias» (ver «Privacidad»). Si se apaga después, la siguiente exportación borra del calendario las que había
  escrito.
- **Sin duplicados**: cada evento lleva en la descripción una primera línea «Creado con Cuadrante» y, en otra línea
  suya, una etiqueta `cuadrante:v1:<calendario>:<fecha>:<tipo>:<n>`. El calendario y el tipo se escriben con
  `Uri.encodeComponent` (un id con `:` o espacios, de una copia editada a mano, sigue dando una etiqueta que se lee
  de vuelta; los ids normales quedan igual). Al volver a exportar, Cuadrante compara con lo que hay: lo que ya
  está bien se deja, lo que ha cambiado se borra y se crea de nuevo, lo repetido se borra.
- **Qué es «suyo»** (estricto, porque lo suyo se puede borrar): el evento está en el calendario del móvil elegido, su
  descripción **empieza exactamente por «Creado con Cuadrante»**, la etiqueta es **una línea entera** que cumple
  `^cuadrante:v1:([^:\s]+):(\d{4}-\d{2}-\d{2}):([^:\s]+):(\d+)$`, el calendario de Cuadrante coincide y el **día de la
  etiqueta** cae dentro de las fechas elegidas. Una etiqueta citada en mitad de otro texto, con otra primera línea o
  en un evento de otro calendario del móvil no se toca. No se exige que el tipo siga existiendo (los eventos de un
  tipo borrado se limpian igual). Los eventos del usuario, los de otra exportación y los de días fuera del rango no
  se tocan.
- **Eventos movidos**: la búsqueda mira ±366 días alrededor de las fechas, no solo dentro: un evento que el usuario
  arrastró a otra fecha sigue teniendo su etiqueta y se sustituye en vez de dejar una segunda copia. El único
  criterio para borrar es el día de la etiqueta.
- Orden: primero se borra y luego se crea. Si borrar un evento falla, **no se crea su sustitución** (el mismo turno
  con la misma etiqueta): se cuentan las dos como fallidas y la siguiente exportación las repite. Si algo falla a
  medias queda un hueco (nunca una copia de más) que la siguiente exportación rellena.
- El resumen cuenta eventos añadidos, sustituidos, quitados, sin cambios y los que no se han podido escribir. Antes de
  pulsar el botón ya se ve qué va a hacer («Se añadirán 12 eventos», «Todo está al día»). **Sustituir y quitar son cosas
  distintas** (H-T14-3, `exportPlanLines` / `exportResultLines`): un evento anterior se *sustituye* si ese día se
  escribe algo (el turno cambió) y se *quita* si no se escribe nada en su lugar (se apagaron «Incluir los días libres»
  o las ausencias): «Se quitarán 14 eventos de una exportación anterior», «14 eventos quitados». Con las dos cosas a
  la vez salen las dos líneas. Al terminar, la tarjeta del resultado se desplaza sola hasta quedar a la vista
  (H-T14-4). El título de la pantalla es «Exportar turnos» (el largo no cabía a 320 dp, H-T14-2).

## Cómo traer el historial de LRHSoft (Shifter) o Supershift

**LRHSoft «Calendario de Turnos» / Shifter** (Android): su «Subir a Google Calendar» es una función **de pago**, y no
genera CSV, Excel ni `.ics`. Lo gratis y completo es su copia de seguridad local, un archivo `.Shifter`:

1. En LRHSoft: Menú › Copia de seguridad › Copia local. Queda un `*.Shifter` (en Android, en
   `Documentos/ShifterBackups/`).
2. En Cuadrante: Ajustes › Importar turnos › **Copia de LRHSoft (Calendario de Turnos)** (o, en el primer uso, el botón
   «Importar copia de LRHSoft» del paso 4). Elige el `.Shifter`; el selector deja elegir cualquier archivo. El selector
   de Android llama «.bin» a los archivos cuyo tipo no conoce (una copia `.Shifter` llega como
   `application/octet-stream`): la app **no repite** ese nombre inventado y dice «Copia de LRHSoft» (H-T22-10).
3. Elige las fechas (por defecto, de su primer a su último día con datos, como mucho 5 años).
4. Revisa a qué turno de Cuadrante corresponde cada turno de LRHSoft. «Mañana», «Tarde», «Noche» y «Libre»
   (también «Descanso», «Free», «Day off»…) se asocian solos a los tuyos; **los que no coinciden empiezan como «Crear
   tipo nuevo»** con su nombre, código, color y horario (también el segundo tramo de un turno partido), editables o
   «Ignorar». Es la única fuente en la que lo que no coincide no empieza en «Ignorar»: los tipos vienen de otra app de
   turnos, no son eventos sueltos de un calendario.
5. Revisa la vista previa y pulsa «Importar». Si no es lo que esperabas, «Deshacer».

Si repites la importación con el mismo archivo no se duplica nada: los turnos nuevos ya son tuyos y se asocian por
nombre, los días iguales no se escriben y las notas ya traídas no se repiten. Las notas se comparan como bloques
completos, también multilínea: una coincidencia dentro de otra línea no descarta una nota distinta.

Un rango con solo notas, o con todos los grupos de turnos en «Ignorar», también puede importarse. La vista previa,
el botón y el resultado cuentan notas en ese caso, y los turnos existentes se conservan. Al deshacer, si se elimina
alguno de los tipos creados por la importación, ese paso deja de poder rehacerse; los demás pasos del historial se
conservan. Si todos los tipos se quedan porque siguen en uso, la importación puede rehacerse como antes.

**Supershift** (y cualquier app que escriba en el calendario del móvil): exporta tus turnos al calendario del móvil
(Google Calendar, iCloud…) y usa Ajustes › Importar turnos › **Calendario del móvil**. Marca el calendario donde
están, elige las fechas, asocia cada título a tus turnos y revisa la vista previa.

Si prefieres no dar acceso al calendario, exporta un `.ics` desde la web de tu calendario y usa «Archivo .ics».

El cuadro «¿Vienes de LRHSoft o Supershift?» de la primera pantalla del asistente cuenta esto en dos líneas (H-T22-1 y
H-T22-4: antes mandaba a todos a la subida de pago). Un archivo que no se puede leer ya no dice solo «No hemos podido
abrir ese archivo»: añade qué aceptamos (H-T22-3), y un `.Shifter` elegido por la vía del CSV o del `.ics` se lee como
lo que es.

## Copia de LRHSoft (`.Shifter`)

Código: `data/lrhsoft_reader.dart` (lectura del archivo) y `domain/lrhsoft_backup.dart` (decodificación y paso al
asistente); pruebas en `test/features/import/lrhsoft_*_test.dart`.

### El formato

Una base **SQLite 3** (`user_version` 7 en LRHSoft 2.0.7.8). Las tablas que se leen:

```
tablaTurnos(_id, texto, abreviatura, color, colorTexto, horaInicio1, horaFinal1, horaInicio2, horaFinal2,
            turnoPartido, ...)
dias(fecha PK, turno1, turno2, notas, horasExtraT1, horasExtraT2, salidaAnticipadaT1, salidaAnticipadaT2,
     foto BLOB, instruccionesDibujo, alarma..., ...)
festivos(_id, fecha, fiesta, oculto)
```

`patrones` y `contenidoPatron` (rotaciones largas), `nombreCalendario` y `android_metadata` existen pero no hacen
falta: LRHSoft ya escribe cada día resultante en `dias`.

**Trampas** (H-T22-5):

1. **El mes de `fecha` va de 0 a 11**: `fecha = año × 10000 + mes0 × 100 + día`. `20260909` es el **9 de octubre**
   de 2026 y `20260931` el 31 de octubre. El nombre del archivo también está desplazado (`…_20260923_…` es del 23 de
   octubre). Una fecha que no existe con esa regla (`20261331`: mes 13; `20260130`: 30 de febrero) es una fila no
   válida. Ojo: `20260230` **sí** existe (30 de marzo).
2. `turno1` y `turno2` son `tablaTurnos._id` (o `NULL`); como mucho dos turnos por día. Un id que no está en
   `tablaTurnos` es una referencia rota: se descarta ese turno y se cuenta una fila no válida.
3. `notas` es **HTML de Android**: `<p dir="ltr">Revisi&#243;n m&#233;dica</p>`. Los saltos de línea del código no
   cuentan; sí `<br>`, `</p>` y `</div>`. Se quitan las etiquetas, se decodifican las entidades (numéricas, hex y las
   nombradas habituales) y se recorta; vacío = sin nota. Como mucho 2 000 caracteres.
4. `color` es un **entero ARGB con signo de 32 bits** (`-2407` es `0xFFFFF699`). Se pasa a sin signo y se usa tal
   cual (los colores libres existen desde 0.6.0), solo moviéndolo un paso si cae justo en el gris especial de
   «Libre».
5. Las horas son texto `HH:mm`. `00:00`–`00:00` significa **sin horario** (Libre, Holiday, Birthday); un fin menor
   que el inicio cruza la medianoche (Noche 23:00–07:00 pertenece al día en que empieza). `horaInicio2`/`horaFinal2`
   solo valen con `turnoPartido = 1`: en «Guardia Médica» de la muestra traen `15:00`–`15:00` y no son un tramo.
6. `abreviatura` es texto libre, a veces más largo que nuestro código (máximo 3) o con puntos: `Mor.`,
   `Mor./Aft.`. El código de un tipo nuevo sale de ella (una palabra de hasta 3 letras se queda tal cual, `Mor.` →
   `Mor`; varias palabras dan sus iniciales, `Mor./Aft.` → `MA`; si choca con otro código, las primeras letras del
   nombre) y, si no hay, del nombre.
7. El texto es UTF-8 correcto; las columnas son opcionales según la versión de la app (una copia antigua tiene
   menos).
8. `dias` tiene una fila por día **con datos**; un día borrado puede quedar como fila vacía (sin turno ni nota): se
   ignora sin contarse como no válido.

### El archivo no es de fiar

Es una base de datos hecha por otro, así que `readLrhsoftBackup` la trata como entrada hostil:

- Más de **50 MB** se rechaza sin escribir nada (cabe más que los 5 MB de `.ics` y CSV porque guarda fotos y dibujos;
  el selector solo deja pasar de 5 MB a un archivo que empieza por la cabecera de SQLite).
- Los bytes van a una **copia temporal privada**, que se abre **solo lectura** (`OpenMode.readOnly`) con
  `PRAGMA query_only = ON`, `trusted_schema = OFF` y `cell_size_check = ON`, y se **cierra y borra siempre**, con
  éxito o con error. Todo corre en el aislado de siempre, con los 30 s máximos.
- `dias` y `tablaTurnos` tienen que ser **tablas** de verdad en `sqlite_master`: una vista (o una tabla virtual, o la
  falta de una) rechaza el archivo («Ese archivo no parece una copia de LRHSoft»).
- Solo se hacen `SELECT` de **columnas explícitas** (nunca `*`, nunca el BLOB de la foto); las opcionales se leen solo
  si `PRAGMA table_info` las lista.
- Máximo **20 000 días** y **500 tipos**; más se rechaza como demasiado grande o complicado.
- Cada fecha y cada hora se valida: una fila no válida se salta y se cuenta (una hora imposible deja el tipo sin
  horario; un segundo tramo que no cabe lo deja de un solo tramo; ambos cuentan como fila no válida).
- Un archivo roto, cifrado o que no es SQLite da `ImportProblem.notLrhsoftFile`; nunca se muestra texto del archivo.

### Qué se trae y qué no

| Se trae | No se trae |
|---|---|
| Tipos de turno que se usan en el rango: nombre, código, color, horario, **segundo tramo** del turno partido | Alarmas y avisos (`alarma…`, `notificacion…`, `sonido…`, `hora…`) |
| Hasta dos turnos por día (`turno1`, `turno2`); un turno sin horas es de todo el día | Dibujos (`instruccionesDibujo`) y fotos (`foto`) |
| Notas del día, como texto (si el día ya tiene otra nota tuya, se conserva y la importada va debajo; con «Mantener lo mío» no se toca) | Horas extra (`horasExtraT1/T2`) y salida anticipada (`salidaAnticipadaT1/T2`): la copia de muestra no las trae y no se pudo confirmar su unidad, así que no se adivinan |
| | `festivos` (ver abajo), `patrones`, `contenidoPatron`, ingresos y tarifas |

El orden de los dos turnos de un día es el del horario (los de todo el día primero), como en cualquier importación.
Los tipos de LRHSoft que ningún día del rango usa no se crean.

**Festivos**: no se importan. En la copia de muestra la tabla `festivos(_id, fecha, fiesta, oculto)` está vacía y no se
pudo comprobar si su `fecha` lleva también el mes de 0 a 11; adivinarlo daría festivos en el día equivocado. Cuando
haya una copia con festivos propios se confirma el formato y se importan como festivos propios del calendario.

### Resumen al terminar

La vista previa dice cuántos días se escriben, cuántos tipos nuevos y cuántas notas, cuántas **filas no válidas** se
ignoraron (si las hubo) y, siempre, que **no se traen las alarmas, los dibujos, las fotos ni las horas extra**. El
aviso de después de importar («Se han importado N días… · Deshacer») repite esas dos últimas cosas.

## Decisiones y lo que queda fuera

- **Un archivo `.ics` que llega desde otra app** (compartir desde WhatsApp o el correo) entra por la misma ruta:
  `/ajustes/importar` acepta un `PickedImportFile` como `extra` y empieza a leerlo. Falta enchufar el aviso nativo de
  Android (filtro de intents) y el de iOS, que ya existen para `.cuadrante` (`docs/copia-de-seguridad.md`) y se
  amplían en la fase del Mac.
- Un grupo con el mismo título pero horarios distintos (un «Turno» de 6 a 14 y otro de 14 a 22) se asocia a **un**
  solo tipo; se ve en el horario más habitual del grupo. Si importa, separarlos en el calendario de origen.
- El formato de exportación (título, línea «Creado con Cuadrante» y etiqueta) es parte del contrato: la etiqueta
  `cuadrante:v1` y la primera línea no se cambian. Las exportaciones hechas antes de codificar los ids siguen
  reconociéndose (un id normal se escribe igual).
- No se importan ausencias con contador ni adjuntos. Las notas del día solo vienen de la copia de LRHSoft (ver
  «Copia de LRHSoft»).

## Pendiente

- **Límite de 5 MB en Android, sin comprobar antes de leer.** `file_selector_android` lee el archivo entero en
  memoria y lo copia a la caché de la app antes de que podamos mirar su tamaño; un archivo enorme puede agotar la
  memoria o llenar la caché antes de que digamos «pesa más de 5 MB». Por ahora se acepta: tras leerlo (o rechazarlo)
  se borra la copia de la caché si su ruta está dentro de la carpeta de caché de la app (`readPickedFile`,
  `deleteIfCached`; nunca se borra nada fuera). La solución de verdad es un `ACTION_OPEN_DOCUMENT` nativo que lea
  primero `OpenableColumns.SIZE` y solo abra el flujo si cabe.
- Probar en dispositivo: la búsqueda de ±366 días al reexportar con calendarios grandes (rendimiento de
  `CalendarContract.Instances` y de EventKit, que limita a unos 4 años por consulta; el rango más largo es 366 + 2 ×
  366 días).

## Pruebas

- `lrhsoft_reader_test.dart` (fechas con el mes de 0 a 11 incluidas las inexistentes, horas, colores con signo,
  notas HTML, tipos con turno partido, noche que cruza la medianoche, Libre sin horas, dos turnos, columnas que faltan,
  filas no válidas, rechazo de una vista, de un archivo que no es SQLite, de uno dañado, de tablas que faltan, de
  más de 50 MB, 20 000 días y 500 tipos, copia temporal borrada; y una prueba contra la copia real de la muestra, que
  se salta si el archivo no está), `lrhsoft_pipeline_test.dart` (del archivo a ocurrencias, borrador del tipo nuevo,
  códigos, sugerencias de «Libre/Descanso/Free», notas en el plan, límites del selector) y `lrhsoft_flow_test.dart`
  (todo el asistente con un `.Shifter` hecho en la prueba con `sqlite3`: asociación, vista previa, importar,
  deshacer, repetir sin duplicados, archivos que no son lo que dice el botón, 320 dp con texto x2.0 en claro y oscuro).
  No se guardan archivos binarios: las bases de prueba se construyen al vuelo.
- `test/features/import/`: lector de `.ics` (plegado, escapes, `Z`, `TZID`, `DATE`, varios días, `RRULE` semanal con
  `UNTIL`, `COUNT` y `EXDATE`, mensual, entrada mal formada, aleatoria y de más de 5 MB), CSV (separadores,
  cabeceras, fechas, filas malas), agrupación, sugerencias, borrador de tipo nuevo, plan de importación (normalización
  frente a la rotación, conflictos, deshacer), aplicación con `ScheduleController` contra la base de datos (un solo
  paso, tipos nuevos, deshacer/rehacer, escritura que falla), aislados de verdad, y los pasos del asistente como
  pruebas de widget (permisos concedido, pendiente, rechazado, restringido y de solo añadir; textos grandes en claro y
  oscuro).
- Endurecimiento de la entrada no fiable: `ics_hardening_test.dart` (anidamiento, presupuesto global de pasos,
  eventos fuera del rango, `DURATION`, listas `BY...`, rango por defecto), `csv_hardening_test.dart` (50 columnas,
  120 caracteres, hora vacía, una función por columna, Windows-1252, borrado de la copia de la caché),
  `import_hardening_flow_test.dart` (todo el trabajo pesado pasa por el ejecutor, tiempo máximo, pantallas acotadas).
- `test/features/calendar_export/`: construcción de eventos, reexportación sin duplicados, solo se tocan los
  eventos propios, fallos a medias, permisos, y la pantalla. `export_hardening_test.dart` y
  `export_screen_hardening_test.dart`: ausencias fuera por defecto, etiqueta estricta (a mitad de línea, otra primera
  línea, otro calendario), ids con `:`, evento movido, borrado fallido sin duplicado, aviso de calendario
  sincronizado. Un calendario falso en memoria
  (`test/support/fake_device_calendar.dart`) sustituye al plugin. `export_split_shift_test.dart` (turno partido): dos
  eventos con etiquetas `…:0` y `…:100`, pasada la medianoche, reexportar no duplica, cambiar un tramo rehace solo ese,
  pasar de partido a normal (y al revés) y copias repetidas o arrastradas de un tramo. La importación no crea turnos
  partidos: cada evento sigue siendo un turno.
- `integration_test/scenarios/import.dart`: **Q70** importar un `.ics` (el mes pintado coincide, un solo deshacer),
  **Q71** CSV, **Q72** exportar dos veces al calendario real del emulador (mismo número de eventos),
  **Q73** importar desde un calendario local creado en el emulador, **Q74** archivo estropeado y conflictos.
  `tool/qa/common.sh` concede `READ_CALENDAR` y `WRITE_CALENDAR` a la app junto a `POST_NOTIFICATIONS`. Falta
  añadir `importScenarios` al registro (`registry.dart`).

## Sin probar en dispositivo (a fecha de este documento)

El plugin `device_calendar_plus` sobre CalendarContract y EventKit reales: fin de los eventos de todo el día en iOS,
calendarios de cuentas de Google sincronizadas, el comportamiento con permiso de «solo añadir» en iOS 17, la creación
del calendario «Cuadrante» en iCloud, y los escenarios Q72 y Q73 en el emulador (necesitan el calendario del sistema).

La importación de la copia de LRHSoft (`.Shifter`) está probada con bases hechas en las pruebas y con la copia real de la muestra, pero **no en el emulador**: falta elegir el archivo con el selector de Android (`application/octet-stream`, sin extensión conocida), `sqlite3` dentro del aislado en el móvil, y repetir T22 (H-T22-1 a H-T22-5) con la app.
