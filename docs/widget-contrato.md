# Contrato del widget (Dart → Swift / Android)

Este documento es el contrato entre la app Flutter y las extensiones nativas del widget. La parte Dart está hecha y
probada (`app/lib/features/widget/`, `app/test/features/widget/`); el Swift de WidgetKit se escribe en el Mac a partir
de aquí (hito 5, desde `ios/MochilaWidget` de Mochila). Origen del requisito: `turnos-spec.md` §4 «Widgets» y §6 «El
widget que nunca se queda en el día de ayer»; prueba de aceptación: `docs/plan-publicacion.md` «Prueba de 7 días».

**Regla de oro:** el Swift no calcula nada de turnos. No resuelve rotaciones, no formatea horas, no traduce textos, no
elige colores. Solo lee el JSON, escoge la entrada del día y la pinta. Todo texto llega ya localizado y todo color ya
resuelto, igual que en la app.

## 1. Dónde vive

| Dato | Valor |
|---|---|
| App Group (iOS) | `group.es.cuadrante.app` (constante Dart `kWidgetAppGroupId`) |
| Clave | `cuadrante.widget.snapshot` (`kWidgetSnapshotKey`) |
| Almacén | `UserDefaults(suiteName: "group.es.cuadrante.app")`, valor `String` con el JSON |
| `kind` del widget (iOS) | `CuadranteWidget` (`kWidgetIosKind`): un solo `kind` con las seis familias |
| Versión del JSON | `v = 2` (`kWidgetSnapshotVersion`); lectores Dart y Android compatibles con v1 |
| Escribe | solo la app (`WidgetPublisher.publish`, luego recarga las líneas de tiempo) |
| Lee | solo la extensión; nunca escribe |

Si la clave no existe, no se puede decodificar o la versión no está soportada, la extensión se comporta como en la sección 6 («caducado»);
nunca inventa datos. Una versión futura del JSON la escribe una app nueva; una extensión vieja la tratará como
caducada, lo cual es correcto (la app nueva traerá también la extensión nueva).

> **Icono del turno (0.6.0, A8): el widget no lo lleva.** Añadir un `icon` por estilo cambiaría el conjunto de claves
> del esquema base, que aquí es fijo y exacto («todas sus claves están siempre presentes», con `contentHash` y pruebas de
> tamaño y de claves) y que el Swift del Mac decodifica con esa forma; cambiar ese esquema sin subir `v` no está permitido.
> Esto se distingue de las extensiones opcionales en la raíz, como `descriptions`: los lectores antiguos ignoran
> esas extensiones y los nuevos admiten su ausencia, sin cambiar los objetos del esquema base ni exigir otra versión.
> El widget sigue enseñando color, código y hora, y sin horas extra. Si se decide enseñarlo, va con
> la siguiente versión incompatible (ahora `v = 3`) y las dos mitades (Dart y Swift) a la vez. La v2 de agenda y
> dos semanas mantiene las bandas y turnos sin iconos.

## 2. Esquema JSON v2 (con lectura de v1)

La v2 conserva sin cambios todas las claves y los 60 días de la v1 y añade `noShift` y `displayDays` en la raíz.
No añade campos por día a las familias anteriores. La extensión opcional de accesibilidad `descriptions` (26-oct) se comparte por fecha en la raíz; los lectores antiguos la ignoran y los nuevos admiten su ausencia sin subir `v`. Dart y Android leen ambas versiones; una versión desconocida
da el aviso de caducado. El planificador republica una v1 al abrir la app porque su versión ya no es la actual.
El futuro lector Swift debe aceptar 1 y 2 y puede ignorar estos dos campos nuevos para sus seis familias.
Un lector antiguo que solo admita v1 muestra el aviso hasta actualizarse; nunca interpreta la v2 como otro día.

Convenciones: claves en `camelCase`; **todas las claves del esquema base están siempre presentes** y las que pueden no tener valor
llevan `null` (no se omiten). Las fechas civiles son `yyyy-MM-dd` sin hora ni zona. Los colores son enteros ARGB
`0xAARRGGBB` sin signo (caben en `UInt32`; decodificar como `UInt32` o `Int`). El orden de las claves es fijo y la
salida es determinista.

### Raíz

| Clave | Tipo | Significado |
|---|---|---|
| `v` | int | Versión del esquema (2; también se lee 1) |
| `generatedAt` | string | Instante de generación, ISO 8601 en UTC (`2026-10-19T08:30:00.000Z`). Informativo |
| `contentHash` | string | SHA-256 hex del contenido (todo menos `generatedAt` y él mismo). Lo usa la app para saber si hay que republicar; el Swift lo ignora |
| `timeZone` | string | Id IANA (`Europe/Madrid`) de la zona cuyas medianoches abren cada día de la línea de tiempo |
| `locale` | string | Idioma de los textos (`es`) |
| `firstDate` | string | Primera fecha (= «hoy» de la app al generar) |
| `lastDate` | string | Última fecha (`firstDate` + 59 días) |
| `staleTitle`, `staleBody` | string | Textos para cuando la línea de tiempo se acaba (sección 6) |
| `weekdayHeaders` | [string] ×7 | Cabeceras de columna de la cuadrícula del mes, en el orden de sus columnas: lunes primero (`L M X J V S D`) o domingo primero (`D L M X J V S`) según «Primer día de la semana» de Ajustes |
| `styles` | [Style] | Tabla de colores compartida por tira y cuadrícula (las bandas apuntan aquí por índice) |
| `months` | [Month] | Cuadrículas de mes (1 a 3), compartidas por los días de ese mes |
| `days` | [Day] ×60 | **Exactamente 60 fechas consecutivas** desde `firstDate`. `days[i].date = firstDate + i` |
| `noShift` | string | Solo v2: texto localizado del día sin turno (`Sin turno`) |
| `displayDays` | [DisplayDay] | Solo v2: días auxiliares consecutivos desde el lunes de la semana de `firstDate` hasta `lastDate + 13`, ambos incluidos (73–79 días con la línea de tiempo de 60) |

### Extensión opcional `descriptions` (v2, compatible con snapshots anteriores)

Objeto opcional en la raíz: `{ "today": "hoy", "days": { "2026-10-19": "lunes, 19 de octubre de 2026. Noche de 22:00 a 06:00" }, "absences": {} }`.

- `today`: estado localizado que el lector antepone, separado por punto, **solo** al día que ha elegido como hoy al renderizar. No queda fijado al día de generación.
- `days`: mapa de fecha ISO a descripción completa ya localizada: fecha con día de la semana, día, mes y año; nombres y horas de **todos** los turnos (incluidos ambos tramos); «Sin turno» si está vacío; festivo con nombre y presencia de nota si corresponde. Cubre los 60 días, sus tiras, los 42 días de cada mes y los días auxiliares. La deduplicación evita repetir la frase en las 420 celdas de las tiras.
- `absences`: descripciones alternativas solo para fechas con ausencias, usadas por agenda/dos semanas. Mantienen la anonimización de `displayDays`: «Ausencia», sin nombre/código personalizado, horas ni nota. No se incluye nunca el contenido de las notas en ninguno de los mapas.

Dart incluye la extensión en `contentHash`; si falta al decodificar, no la añade al recodificar ni al calcular el hash. Android admite v1/v2 sin ella con la lectura anterior y la usa en todas las familias cuando está presente. El texto de «hoy» llega del snapshot, no de los recursos del idioma del dispositivo. `widget_root` se reinicia a descripción nula antes de cada render y cada estado añade la suya cuando corresponde; recuperar datos válidos borra así la descripción obsoleta de caducado.

### DisplayDay (v2, agenda y dos semanas)

`date`, `weekdayShort`, `dayOfMonth`, `dateLabel`, `isHoliday`, `hasNote` y `shifts` tienen la misma forma que en
`Day`; cada turno usa `Shift` con sus ocho colores y horas ya formateadas. No hay campos `small`, `medium`, `large`
ni `lock`, ni texto de notas. Los datos salen de `Schedule`, también antes de hoy y después del último día válido.
**Estos días auxiliares no amplían la vigencia:** primero se busca hoy en `days`, igual que en los widgets anteriores.
No se muestra ningún turno cuando hoy queda fuera de esa lista.

Todas las ausencias se anonimizan en estos días: `code` y `name` son el texto localizado «Ausencia», las dos horas
son `null`, los colores son los neutros de `ShiftSwatch` para `ShiftPalette.rest` y se suprime `hasNote` del día.
Así tampoco un nombre o código personalizado revela una ausencia de salud. El detalle sigue dentro de la app.
La v1 no tenía esta representación: los nuevos widgets solo reutilizan sus `days` si contienen todo el rango
necesario y ningún turno de categoría `absence`; si falta algo muestran el aviso hasta que la app publique v2.

### Day

| Clave | Tipo | Significado |
|---|---|---|
| `date` | string | Fecha civil del día |
| `weekday` | int | 1 = lunes … 7 = domingo |
| `weekdayShort` | string | `lun` |
| `dayOfMonth` | int | 19 |
| `dateLabel` | string | `lun 19` |
| `isHoliday` | bool | Festivo |
| `holidayName` | string? | Nombre del festivo, `null` si no lo es |
| `hasNote` | bool | El día tiene una nota (no vacía). El texto de la nota **no** viaja al widget |
| `shifts` | [Shift] | Turnos del día en orden de visualización; `[]` si no hay turno |
| `small` | Small | Todo lo del widget pequeño |
| `medium` | Medium | La tira de 7 días que empieza en este día |
| `large` | Large | Puntero a la cuadrícula del mes de este día |
| `lock` | Lock | Textos de pantalla de bloqueo |

### Shift (dentro de `Day.shifts`; colores propios)

| Clave | Tipo | Significado |
|---|---|---|
| `code` | string | 1–3 caracteres (`N`, `LD`) |
| `name` | string | `Noche` |
| `timeLabel` | string? | `22:00–06:00` (24 h, raya `–`), `null` si el turno no tiene horario. **Turno partido (A12):** los dos tramos en la forma compacta, `09–13 · 17–21` (dos rangos completos no caben en la línea del widget) |
| `compactTime` | string? | `22–06`; con minutos solo si no son `:00` (`07:30–15`), `null` sin horario. Turno partido: `09–13 · 17–21` (los dos tramos unidos por ` · `) |
| `category` | string | `work`, `rest` o `absence` |
| `barLight`, `tintLight`, `inkLight`, `discLight` | int | Colores del turno en modo claro: barra inferior, fondo de la celda (tinte), código y texto en el tono del turno (tinta) y fondo del distintivo (disco) |
| `barDark`, `tintDark`, `inkDark`, `discDark` | int | Los mismos cuatro en modo oscuro |

### Style (en `styles`; una por color de turno distinto)

Los mismos ocho campos de color que `Shift` (`barLight`, `tintLight`, `inkLight`, `discLight`, `barDark`, `tintDark`,
`inkDark`, `discDark`) y la variante **de otro mes** (`dim*`) para los días de los meses vecinos en la cuadrícula:
`dimBarLight`, `dimTintLight`, `dimInkLight`, `dimDiscLight`, `dimBarDark`, `dimTintDark`, `dimInkDark`, `dimDiscDark`.
Los 16 campos son siempre enteros (no hay bordes ni `null`). En la variante de otro mes el tinte y el disco son el
`surfaceMuted` del tema, la tinta es el `textMuted` y la barra ya viene mezclada al 45 % sobre ese fondo (opaca).

### Band (en tiras y cuadrículas)

`{ "code": "N", "style": 0 }`: código del turno e índice en `styles`. Un día con varios turnos tiene una banda por
turno, apiladas de arriba abajo en ese orden (como la celda de la app). `bands: []` = día sin turno.

### Small

| Clave | Significado |
|---|---|
| `big` | Texto grande: `N`, `M+T` si hay varios turnos, o `Sin turno` si `isEmpty` |
| `isEmpty` | `true` en un día sin turno (el Swift reduce la fuente de `big`) |
| `detail` | Bajo el código: `22:00–06:00`; con varios turnos, tiempos compactos unidos con ` + ` (`06–14 + 14–22`); el nombre del turno si no tiene horario (`Vacaciones`); `null` si no hay turno |
| `tomorrow` | Línea inferior: `Mañana: T 14–22`, `Mañana: M 06–14 + T 14–22`, `Mañana: Sin turno`. El día siguiente se calcula siempre con el motor, también para el día 60 (el día 61 existe como dato aunque no como entrada) |

Los colores del pequeño salen de `Day.shifts` (primer turno: `tint` de fondo, `ink` en el código, `disc` en el
distintivo y `bar` en la barra inferior; si hay varios, bandas apiladas en orden).

### Medium

`{ "cells": [StripCell ×7] }`. `cells[0]` es el propio día (`isToday = true`) y las siguientes son los 6 días
siguientes, **aunque pasen del día 60** (son datos reales del motor).

StripCell: `date`, `weekdayShort`, `dayOfMonth`, `isToday`, `isHoliday`, `hasNote`, `bands`.

### Large + Month

`Day.large = { "month": i, "todayCell": c }`: usa `months[i]` y marca la celda `c` (0–41) como hoy.

Month: `key` (`2026-10`), `title` (`Octubre 2026`), `cells` (**siempre 42**, de 6 filas × 7 columnas; la primera es el
primer día de la semana del usuario, lunes por defecto o domingo, en o antes del día 1; `weekdayHeaders` sigue el mismo
orden. El primer día de la semana es `weekStart` de `buildWidgetSnapshot` y viene de Ajustes; cambiarlo cambia el
`contentHash` y la app republica). Cada celda: `date`, `dayOfMonth`, `inMonth`, `isHoliday`, `hasNote`,
`bands`. Las celdas con `inMonth = false` (días de los meses vecinos) se pintan con los colores `dim*` de su estilo.
La cuadrícula incluye días anteriores a hoy y posteriores al día 60 con datos reales.

### Lock

| Clave | Significado |
|---|---|
| `inline` | `N · 22:00` (códigos y hora de inicio del primer turno), `N` si no tiene horario, `Sin turno` si no hay |
| `circular` | `N`; con varios turnos, el primer código y un `+` (`M+`); `–` si no hay turno |
| `rectangular` | Exactamente 2 líneas: `["N · 22:00–06:00", "Mañana: T 14–22"]` (varios turnos: `M+T · 06–14 + 14–22`; sin turno: `Sin turno`) |

### Ejemplo v1 (sigue admitido; un día; `...` marca lo recortado)

```json
{
  "v": 1,
  "generatedAt": "2026-10-19T08:30:00.000Z",
  "contentHash": "0ab5e7a2cc0aa8486b86e4ec36d79811ae21a8464729da81450eec35bc58f328",
  "timeZone": "Europe/Madrid",
  "locale": "es",
  "firstDate": "2026-10-19",
  "lastDate": "2026-12-17",
  "staleTitle": "Cuadrante",
  "staleBody": "Abre Cuadrante para seguir al día",
  "weekdayHeaders": ["L", "M", "X", "J", "V", "S", "D"],
  "styles": [
    {
      "barLight": 4283125713, "tintLight": 4293783034, "inkLight": 4283125713, "discLight": 4292861943,
      "barDark": 4284178389, "tintDark": 4280098100, "inkDark": 4287138785, "discDark": 4280558926,
      "dimBarLight": 4288980451, "dimTintLight": 4293717233, "dimInkLight": 4284111460, "dimDiscLight": 4293717233,
      "dimBarDark": 4281414506, "dimTintDark": 4279176979, "dimInkDark": 4287532697, "dimDiscDark": 4279176979
    }
  ],
  "months": [
    {
      "key": "2026-10", "title": "Octubre 2026",
      "cells": [
        { "date": "2026-09-28", "dayOfMonth": 28, "inMonth": false,
          "isHoliday": false, "hasNote": false, "bands": [] }
      ]
    }
  ],
  "days": [
    {
      "date": "2026-10-19", "weekday": 1, "weekdayShort": "lun", "dayOfMonth": 19,
      "dateLabel": "lun 19", "isHoliday": false, "holidayName": null, "hasNote": false,
      "shifts": [
        { "code": "N", "name": "Noche", "timeLabel": "22:00–06:00", "compactTime": "22–06",
          "category": "work",
          "barLight": 4283125713, "tintLight": 4293783034, "inkLight": 4283125713, "discLight": 4292861943,
          "barDark": 4284178389, "tintDark": 4280098100, "inkDark": 4287138785, "discDark": 4280558926 }
      ],
      "small": { "big": "N", "isEmpty": false, "detail": "22:00–06:00", "tomorrow": "Mañana: T 14–22" },
      "medium": {
        "cells": [
          { "date": "2026-10-19", "weekdayShort": "lun", "dayOfMonth": 19, "isToday": true,
            "isHoliday": false, "hasNote": false, "bands": [ { "code": "N", "style": 0 } ] }
        ]
      },
      "large": { "month": 0, "todayCell": 21 },
      "lock": {
        "inline": "N · 22:00",
        "circular": "N",
        "rectangular": ["N · 22:00–06:00", "Mañana: T 14–22"]
      }
    }
  ]
}
```

(En el archivo real `styles` tiene un estilo por color usado, `months` hasta 3 cuadrículas de 42 celdas, `medium.cells`
siete celdas y `days` sesenta días.)

**Tamaño medido** (60 días, JSON compacto, rotación de 4 turnos con los 16 campos de color por estilo y 8 por turno):
**116.396 bytes (~114 KB)** en v1; 126.403 bytes con un día doble con nota cada 3 días. V2 añade los días auxiliares:
**145.315 bytes** con la rotación simple y **160.892 bytes** con los días dobles y notas (medido el 25-oct).
Los días auxiliares están incluidos en la prueba de tamaño y en `contentHash`. Límite del contrato: **200 KB** (`kWidgetSnapshotMaxBytes`,
comprobado con `assert` al codificar y con una prueba).

## 3. Colores

Son **los mismos que los de la app** (`docs/diseno.md`, «Color de cada turno»): salen de `ShiftSwatch.forColor`
(`lib/core/theme/shift_swatch.dart`), una vez en claro y otra en oscuro, derivados del único color que el usuario
guarda por turno:

| Campo | Qué es |
|---|---|
| `bar` | Barra inferior (en oscuro, el color guardado aclarado si su luminancia es < 0,15) |
| `tint` | Fondo suave de la celda: mezcla del color sobre la superficie del tema (10 % claro, 14 % oscuro) |
| `disc` | Fondo del distintivo: mezcla al 18 % (claro) o 28 % (oscuro) |
| `ink` | Código y textos en el tono del turno: contraste ≥ 4,5:1 sobre `tint` **y** sobre `disc` (prueba incluida) |

«Libre» es especial: `tint` = superficie del tema, `bar` = `borderStrong`, `ink` = `textMuted`, `disc` = `surfaceRaised`.
El fondo del widget es la superficie del tema del sistema (`#FFFFFF` claro, `#15151B` oscuro). El Swift:

- Elige el grupo con `@Environment(\.colorScheme)`: `.light` → `*Light`, `.dark` → `*Dark`.
- Convierte `UInt32` ARGB a `Color(.sRGB, red:, green:, blue:, opacity:)` sin tocar nada (sin atenuar, sin aclarar,
  sin recalcular contrastes).
- Pinta la celda con `tint`, el código con `ink`, el distintivo con `disc` y una barra inferior con `bar`
  (6 pt en las celdas; 5 pt en el widget pequeño).
- Para las celdas con `inMonth = false` usa el grupo `dim*` del mismo estilo.
- **Nunca solo color:** siempre se pinta el código del turno; con espacio, también la hora.
- En los modos de renderizado acentuado/vibrante de iOS 18 (`widgetRenderingMode != .fullColor`) el sistema tiñe el
  contenido: usar solo el código y la forma, sin depender del relleno. Los widgets de pantalla de bloqueo son siempre
  texto monocromo (`lock.*`), no llevan colores.

## 4. Familias y qué lee cada una

| Familia (WidgetKit) | Lee | Contenido |
|---|---|---|
| `systemSmall` | `day.small`, `day.shifts`, `day.dateLabel`, `day.isHoliday/holidayName` | `big` sobre el color del turno, `detail` debajo, `tomorrow` abajo. Fecha (`dateLabel`) y marca de festivo como detalle |
| `systemMedium` | `day.medium.cells` | Tira de 7 días con código y color por celda (`bands` → `styles`), hoy resaltado (`isToday`), punto de festivo, marca de nota |
| `systemLarge` | `snapshot.months[day.large.month]`, `weekdayHeaders`, `day.large.todayCell` | Título del mes, cabeceras, 6×7 celdas con código y color, `inMonth = false` atenuado, hoy con anillo |
| `accessoryInline` | `day.lock.inline` | Una línea de texto |
| `accessoryCircular` | `day.lock.circular` | Texto corto centrado |
| `accessoryRectangular` | `day.lock.rectangular[0]`, `[1]` | Dos líneas |

Celda de varios turnos (tira y cuadrícula): bandas apiladas en el orden de `bands`, cada una con su código y color,
como `DayCell` en la app. Día sin turno: celda vacía de superficie, sin barra, solo el número del día.

## 5. Cuándo republica la app (lado Dart)

Disparadores (`WidgetSyncTrigger`) y comprobación (`WidgetSyncPlanner`): la app construye una instantánea nueva, la
compara con la publicada y solo escribe si hace falta.

| Disparador | Espera | Siempre recarga líneas de tiempo |
|---|---|---|
| `appStart` (arranque en frío) | no | sí |
| `appResumed` (vuelve a primer plano) | no | sí |
| `scheduleChanged` (cualquier edición de turnos/patrones/excepciones/notas) | 2 s tras la última edición | no (solo si cambia algo) |
| `holidaysChanged` | 2 s | no |
| `dayChanged` (temporizador a la medianoche local con la app abierta) | no | sí |
| `timeZoneChanged` | no | sí |
| `localeChanged` | no | no |

`needsRefresh` es verdadero (`WidgetRefreshReason`) cuando: no hay nada publicado o no se lee (`neverPublished`); la
primera fecha publicada no es hoy, ya sea porque pasó el día o porque el reloj retrocedió (`dateRolled`); la zona
horaria publicada no es la actual (`timeZoneChanged`); la versión publicada no es la actual (`versionChanged`); o el
`contentHash` de la instantánea recién calculada difiere del publicado (`contentChanged`). Una edición fuera de los
60 días (y de las cuadrículas de mes) no cambia el hash.

Publicar = guardar el JSON en la clave del App Group y pedir `WidgetCenter.shared.reloadAllTimelines()`
(`WidgetPublisher`: `HomeWidgetPublisher` sobre `home_widget`, que en Android guarda en `HomeWidgetPreferences` y
envía la actualización a los cinco proveedores; `FakeWidgetPublisher` en pruebas y en hosts sin widgets). Quien lo
dispara en la app es `WidgetHost` (montado en `app.dart`): arranque, vuelta a primer plano, cambios de turnos,
festivos, preferencias o calendario principal (con la espera de la tabla), medianoche local con la app abierta, y
cambio de fecha o de zona detectado por una mirada al reloj cada minuto. Siempre se publica el calendario
**principal** (`readPrimarySchedule`), no el que esté en pantalla.

## 6. Política del `TimelineProvider` (Swift, en el Mac)

**Una entrada por día, a las 00:00, 60 días.** El widget cambia de día solo, sin depender de que el sistema lo
refresque ni de que se abra la app.

```
getTimeline(in:completion:)
  snapshot = decode(UserDefaults(suiteName: "group.es.cuadrante.app").string(forKey: "cuadrante.widget.snapshot"))
  si falta, no decodifica o v no es 1 ni 2:
      entries = [ .stale(date: now) ]            // textos locales de la extensión
      policy  = .after(now + 1 h)
  si no:
      cal = Calendar(identifier: .gregorian) con timeZone = TimeZone(identifier: snapshot.timeZone) ?? .current
      todayISO = yyyy-MM-dd de `now` en cal
      i = índice de days con date == todayISO
      si no existe (antes de firstDate o después de lastDate):
          entries = [ .stale(date: now) ]; policy = .after(now + 1 h)
      si existe:
          entries = [ .day(days[i], date: now) ]                                  // el día actual, ya
                  + [ .day(days[k], date: cal.startOfDay(de days[k].date)) para k en i+1 ... 59 ]
                  + [ .stale(date: cal.startOfDay(de lastDate + 1 día)) ]         // entrada final de caducidad
          policy  = .after(fecha de la entrada .stale)
```

Reglas:

1. **Cada entrada lleva su `WidgetDay` dentro.** La vista pinta lo que trae la entrada; **jamás** vuelve a leer
   `Date()` para escoger el día. Así un widget nunca muestra los datos de otro día.
2. Las entradas se ordenan por fecha ascendente; la primera tiene fecha `now` (no la medianoche pasada).
3. `startOfDay` se calcula con el calendario de `timeZone`, no sumando 86.400 s: los días de cambio de hora duran 23
   o 25 h, y se cubren con fechas civiles. Las pruebas Dart fijan que 2026-10-25 y 2027-03-28 no saltan ni duplican día.
4. Total: hasta 61 entradas (60 días + la de caducidad). No hay que recortar.
5. La extensión **no escribe** en el contenedor y no calcula turnos.
6. Tras `reloadAllTimelines()` (la app lo pide al abrir, al reanudar, tras ediciones y en cambios de día o zona), el
   proveedor reconstruye las entradas desde el JSON nuevo.

### Qué muestra cuando se acaba (caducado)

La entrada `.stale` aparece cuando `now` pasa de la medianoche siguiente al día 60, o desde el primer momento si no
hay JSON válido o `now` queda fuera de `firstDate…lastDate` (reloj atrasado, JSON viejo). Muestra **solo**
`staleTitle` y `staleBody` (`Cuadrante` / `Abre Cuadrante para seguir al día`) en todas las familias; en pantalla de
bloqueo, una línea corta (`staleBody`; circular: icono o `–`). **Nunca** muestra turnos, colores de turno ni nada de
otro día: es un aviso honesto, no un dato a medias. El mes grande tampoco: sin cuadrículas en caducado. Cuando el
usuario abre la app, esta republica y las líneas de tiempo vuelven a la normalidad.

## 7. Pruebas

### Automáticas (Dart, ya en verde)

`flutter test test/features/widget` (corren con `TZ=Europe/Madrid` en CI): 60 días exactos desde hoy y consecutivos;
cruce de mes y de año; fines de semana de cambio de hora; varios turnos, día vacío, festivo y nota; colores iguales a
`ShiftSwatch.forColor` (claro, oscuro, de otro mes, «Libre» neutro y contraste de la tinta); ida y vuelta JSON y salida estable; `needsRefresh`
(día siguiente, zona, versión, edición); tamaño < 200 KB; y una simulación del protocolo: cada uno de los 60 días
encuentra su entrada y el día 61 no encuentra ninguna. Turno partido (`widget_snapshot_split_test.dart`): los dos tramos salen
en `timeLabel`/`compactTime`, en `small.detail`, en la línea de mañana y en la rectangular de bloqueo (`P · 09–13 · 17–21`),
con minutos solo si no son `:00`, y el `contentHash` cambia si cambia el segundo tramo. **No hay cambio de versión del
contrato**: son los mismos campos de texto; el Swift y el Kotlin no calculan horas, solo enseñan el texto (en el Mac,
comprobar que `09–13 · 17–21` no se corta en el widget pequeño y en el de bloqueo rectangular).

### Prueba de 7 días (Mac, `docs/plan-publicacion.md` «Prueba de 7 días del widget»)

1. Pintar 3 semanas con turnos distintos cada día, añadir las seis familias, cerrar la app (quitarla de multitarea)
   y **no abrirla en 7 días**.
2. Antes de empezar, sacar la «respuesta» esperada del propio JSON del contenedor (en simulador:
   `xcrun simctl get_app_container booted <bundle id> groups` y leer la clave `cuadrante.widget.snapshot` del
   `.plist`; en dispositivo, desde un botón de depuración que vuelque el JSON): para cada fecha, `days[i].small.big`,
   `lock.*` y la celda de hoy. Anotarlo en `docs/qa/widget-7-dias.md`.
3. Cada día: captura poco después de las 00:00 y a las 08:00 de las seis familias; comparar con la respuesta.
4. Perturbaciones: día 2 reinicio; día 3 bajo consumo; día 4 cambio de zona (Madrid → Canarias → Madrid); día 5 modo
   avión a medianoche; día 6 cambio manual de fecha y vuelta.
5. **Caducidad:** en un dispositivo de pruebas, adelantar la fecha **61 días** respecto a `firstDate` (y también 60 días
   y 1 minuto): las seis familias muestran el aviso honesto y ningún turno. Volver a la fecha real: vuelven los datos
   (con `reloadAllTimelines`) o sigue el aviso hasta abrir la app; en ningún caso aparece un día equivocado.
6. Criterio: 7 de 7 días con el día correcto en todas las familias y dispositivos (iOS 17, 18, 26).

## 8. Preguntas abiertas para el lado Swift

1. **Zona horaria.** Este contrato fija las medianoches en la zona `timeZone` del JSON (la que tenía el móvil al
   publicar). Si el móvil cambia de zona con la app cerrada (Madrid → Canarias), el widget cambia de día a las 00:00
   de Madrid (01:00 en Canarias), mientras que la app usa el reloj del móvil. Alternativa B: usar siempre
   `TimeZone.current` al generar las entradas (coincide con la app) y confiar en que iOS recargue la línea de tiempo
   al cambiar la zona. La prueba del día 4 decide cuál es mejor en un iPhone real; el contrato se cambia con una línea
   (qué calendario se usa en el pseudocódigo) y sin tocar el JSON.
2. ¿`UserDefaults` aguanta bien ~110–125 KB leídos en cada `getTimeline`? Se espera que sí; si da problemas, mover el
   JSON a un archivo del contenedor (`containerURL(forSecurityApplicationGroupIdentifier:)`) con el mismo contenido.
3. Modos acentuado/vibrante de iOS 18: ¿cómo se ven los códigos sobre fondos de color teñidos? Decidir con capturas.
4. Etiquetas de accesibilidad: las frases completas ya llegan en la extensión opcional `descriptions` (sección 2). El futuro lector Swift debe usarlas y conservar compatibilidad cuando falten.
5. Android: hecho, ver la sección 9 (mismo JSON en `SharedPreferences` vía `home_widget`, `RemoteViews`, alarma de
   medianoche y WorkManager; el contrato de contenido es idéntico y solo cambia la política de refresco).

## 9. Android

Mismo JSON, mismas reglas de oro (la parte nativa no calcula turnos, ni formatea horas, ni traduce, ni elige colores)
y mismo aviso de caducado. Código en `app/android/app/src/main/kotlin/es/cuadrante/app/widget/`.

### Qué hay

| Pieza | Función |
|---|---|
| `CuadranteSmallWidgetProvider` (2×2) | `big` sobre el `tint` del turno, `detail`, `tomorrow` y la barra `bar` (una por turno). Muestra la **hora de inicio** en vez de «Esta noche · empieza en…» (esa cuenta atrás no se puede mantener exacta sin la app). |
| `CuadranteMediumWidgetProvider` (4×2) | `day.medium.cells`: siete celdas con código, `tint`, barras y hoy con anillo; festivo con el número en rojo. |
| `WidgetDayLogic` | La lógica de día pura (sin clases de Android, con pruebas JVM): elige la entrada de hoy, calcula la próxima medianoche y, para el widget del mes, escoge la cuadrícula y la celda de hoy (`monthIndex`, `todayCell`). |
| `CuadranteLargeWidgetProvider` (4×4) | `snapshot.months[day.large.month]`, `weekdayHeaders` y `day.large.todayCell`: título del mes («Octubre 2026»), cabeceras, 6×7 celdas con el número del día, el código de hasta **2 turnos** (lado a lado), el tinte del primer turno, una barra inferior por turno (hasta 2) y hoy con anillo; los días de otros meses con los colores `dim*` del estilo. Redimensionable hasta ~3×3 celdas. |
| `CuadranteAgendaWidgetProvider` (4×2, redimensionable) | «Próximos días»: hoy y los siguientes, hasta 14 días; filas completas según el espacio y tamaño de texto del lanzador. Fecha, ficha de color, código, horario e indicador de nota; tocar una fila abre ese día. |
| `CuadranteTwoWeeksWidgetProvider` (4×2) | «Dos semanas»: 2 filas de 7 días desde el lunes de la semana actual, incluso con domingo como inicio del mes en Ajustes. Día, color, código y hora compacta cuando cabe; cada celda abre su día. |
| `WidgetModelBuilder` | Lee el JSON y devuelve lo que se pinta (o el aviso). Nunca lanza: JSON ausente, roto, versión distinta de 1 y 2 o un día incompleto dan el aviso. |
| `WidgetRenderer` | `RemoteViews` (los cinco widgets). Colores del JSON; en Android 12+ con `setColorInt(claro, oscuro)`, así que el cambio de tema no necesita redibujar; antes se elige por `uiMode` al dibujar. **Todo dibujo fija la visibilidad del
aviso «Abre Cuadrante» y del contenido** (`WidgetRenderPlan`): el lanzador reaplica el `RemoteViews` sobre las vistas que ya
tiene si el layout es el mismo, y lo que dejó el dibujo anterior (aviso visible, contenido oculto) se queda si el nuevo no lo
cambia (H-T12-2). Fondo y textos neutros de `res/values(-night)/widget_colors.xml` (tokens de `docs/diseno.md`). |
| `WidgetScheduler` | Alarma de la próxima medianoche (+2 s) y tarea periódica de WorkManager (6 h). |
| `WidgetRefreshReceiver` | Redibuja todo y rearma la alarma. |
| `WidgetRefreshWorker` | Lo mismo desde WorkManager. |

**iOS: las URLs llevan `?homeWidget`.** El plugin `home_widget` solo entrega a Dart (por `widgetClicked` e
`initiallyLaunchedFromHomeWidget`, el mismo camino que en Android) las URLs de iOS que traen el parámetro `homeWidget`
(`isWidgetUrl` en su `HomeWidgetPlugin.swift`): el Swift del widget usa
`cuadrante://widget/day/<yyyy-MM-dd>?homeWidget`, `cuadrante://widget/month/<yyyy-MM>?homeWidget` y
`cuadrante://widget?homeWidget` (aviso de caducado). `widgetLinkTarget` ignora el parámetro (prueba en
`widget_links_test.dart`). El esquema `cuadrante` y `FlutterDeepLinkingEnabled = false` ya están en el `Info.plist` de
`Runner`, así que Flutter no pasa estas URLs a go_router. Sin el parámetro el toque abriría la app pero no el día.

Los enlaces `cuadrante://` no llevan datos y no disparan acciones: cualquier app puede abrirlos. Nunca añadas una acción con efectos a estos enlaces.

Los nuevos widgets usan `cuadrante://widget/day/<yyyy-MM-dd>?homeWidget`, y el aviso
`cuadrante://widget?homeWidget`, por el mismo canal de `home_widget`.

### Agenda y dos semanas (Android, 25-oct)

Ambos se añaden desde el selector de widgets del lanzador y desde Ajustes › Añadir widget. Tienen descripción y
vista previa propias y textos en es, ca, gl, eu y en. Usan los mismos fondos, tintes, tipografía e indicadores de hoy
de los widgets anteriores, con tema claro/oscuro. Las filas y las celdas se añaden con `RemoteViews.addView`, sin
colecciones ni servicios adicionales. El plan de filas se calcula por instancia al actualizar y redimensionar;
una instancia más alta puede enseñar más días que otra del mismo proveedor.
En días con varios turnos, la agenda añade fichas con código y hora y las dos semanas apilan hasta dos bandas.
Si el primer día de agenda o una celda no admiten todos los turnos completos, el último código lleva `+N` con el
número restante; el texto de accesibilidad conserva todos los turnos saneados y sus horas. Las fechas estrechas
se ajustan al ancho; los rangos de hora de dos semanas se muestran enteros o se ocultan cuando no caben.

Los cinco proveedores están en `WidgetRenderer.providers`: alarma de medianoche, WorkManager, cambios de reloj,
zona, reinicio y republicación Dart actualizan todos juntos. No hay un segundo planificador. El anillo y la agenda
se desplazan al cambiar hoy; el lunes la cuadrícula de dos semanas avanza siete días. Se mantienen las limitaciones
de puntualidad de Android sin permiso de alarmas exactas descritas más abajo.

Pruebas Dart: rango auxiliar completo a lo largo de los 60 días, cambio de año, horas partidas, notas sin contenido,
ausencias neutras, hash, ida y vuelta v2 y lectura/recodificación de `widget_snapshot_v1.json` sin cambios.
Pruebas JVM: selección de rangos, lunes incluso con el mes en domingo, medianoche, privacidad, vigencia, filas que
caben y visibilidad al pasar de caducado a contenido. Quedan para dispositivo: medidas del lanzador, legibilidad,
redimensionado, toques en frío/caliente y el protocolo de siete días, ahora con los cinco widgets.

Un toque abre la app en ese día: `cuadrante://widget/day/<yyyy-MM-dd>` (la celda de la tira y la del mes llevan su propio
día; el aviso de caducado abre la app sin día). La cabecera del widget del mes abre ese mes: `cuadrante://widget/month/<yyyy-MM>`
(la app muestra el mes en el calendario, sin hoja de día). `WidgetHost` lo recibe por `home_widget` y abre el detalle del día
(`widget_links.dart`). Un enlace que no es nuestro se ignora; durante el primer uso no se interrumpe. Un día o un mes
a más de 50 años de hoy (`0000`, `9999`...; `maxLinkYearsFromToday`, con «hoy» de `clockProvider`) también se ignora: la app
se abre en hoy. Igual para `?mes=` de `/resumen` y `/comparar` (`parseMonthParam`).

### Widget del mes (4×4): por qué una cuadrícula fija y no una colección

El mes se pinta con un diseño fijo (`widget_month.xml`: título, 7 cabeceras y 6 filas) al que el renderizador le añade las
42 celdas con `addView`, igual que la tira del mediano. Se descartó `GridView` con `RemoteViewsService`: (1) cada
redibujado es un único `updateAppWidget` con todo dentro, así que a medianoche, con la app cerrada, es la misma operación
simple que en los otros dos widgets; una colección necesita un servicio y un `notifyAppWidgetViewDataChanged` que
también tendrían que leer el reloj y que pueden llegar tarde o no llegar, dejando ayer o el mes anterior en pantalla;
(2) los datos ya están en el JSON, sin fábricas ni adaptadores que mantener; (3) son solo 42 celdas (unos 13 `View` cada
una, profundidad 8, muy por debajo de los límites de `RemoteViews`).

El mes y la celda de hoy salen del reloj en cada dibujado (`WidgetDayLogic.monthIndex` y `todayCell`): el puntero del día
(`Day.large`) se usa si es correcto y, si no, se busca por clave `yyyy-MM` y por fecha; si el mes de hoy no está en
`months`, o la cuadrícula no tiene 42 celdas, sale el aviso «abre la app» y nunca un mes equivocado. A medianoche el
anillo de hoy se mueve y, el día 1, aparece el mes nuevo de `months` (las cuadrículas de los meses que tocan los 60 días
ya vienen en la instantánea). El aviso de caducado es el mismo que el de los otros widgets.

### Cómo se garantiza que no se queda en ayer

1. **Cada dibujado lee el reloj.** `WidgetModelBuilder.build` toma la fecha local del dispositivo *en ese momento*
   (`ZoneId.systemDefault()`), busca esa fecha en `days[].date` y pinta esa entrada; nunca «el primer día» ni un día
   recordado de otro dibujado. Si la fecha no está (antes de `firstDate`, después de `lastDate`, o falta en la lista),
   pinta `staleTitle` / `staleBody` y ningún turno. Por eso **cualquier** disparador, aunque llegue tarde, enseña el día
   correcto.
2. **Alarma de medianoche.** Tras cada dibujado se arma una alarma `RTC_WAKEUP` para la medianoche local siguiente
   más 2 s (el comienzo del día sale de las reglas de la zona, no de sumar 24 h: los días de 23 y 25 h y las zonas sin
   medianoche en el cambio de hora están cubiertos por pruebas). Exacta (`setExactAndAllowWhileIdle`) si el usuario
   concede «Alarmas y recordatorios» (`SCHEDULE_EXACT_ALARM`, ya declarado para las alarmas de turno); si no,
   `setAndAllowWhileIdle`, y el sistema la puede retrasar hasta una hora (`dumpsys alarm` muestra `window=+1h`; una
   ventana más estrecha con `setWindow` la ignora). Ver `docs/preguntas.md`, pregunta 14.
3. **Avisos del sistema**, en el manifiesto: `TIME_SET`, `TIMEZONE_CHANGED`, `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED` y
   `SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED` redibujan y rearman la alarma (que se pierde al reiniciar). Se
   declara también `DATE_CHANGED`, pero **no llega** a receptores del manifiesto en Android 16 (medido en el
   emulador: el sistema solo lo entrega a receptores registrados con el proceso vivo); no se cuenta con él.
4. **WorkManager** cada 6 h (`WidgetRefreshWorker`) y `updatePeriodMillis` de 30 min: redes de seguridad por si la
   alarma se perdió (un gestor de batería agresivo, una parada forzada que luego se deshace).
5. **La app**, al abrir, al volver a primer plano y a medianoche si está abierta, republica y pide la actualización
   (la tabla de la sección 5).

Una parada forzada desde Ajustes borra las alarmas y las tareas hasta que se abre la app o llega un aviso del
sistema: es una limitación de Android, igual que para todos los widgets.

**Zona horaria (pregunta 1 de la sección 8):** Android usa la zona *actual* del dispositivo (alternativa B). Con un
cambio de zona, `TIMEZONE_CHANGED` redibuja y el widget coincide con el reloj y con la app; `timeZone` del JSON solo
dice para qué zona se generó.

### Pruebas

- Kotlin (`./gradlew :app:testDebugUnitTest`, en `app/android`): `WidgetDayLogicTest` (medianoche, el último segundo
  del día, los 60 días hora a hora, días de 23 y 25 h, zona sin medianoche, cambio de zona, caducado antes y después;
  elección de mes y de celda de hoy), `WidgetModelBuilderTest`, que lee `src/test/resources/widget_snapshot.json`, y
  `WidgetMonthTest` (widget del mes: 42 celdas, hoy, cambio de mes el día 1, semana en domingo, colores `dim*`, hasta 2
  turnos por celda, aviso, punteros dañados), que añade `widget_snapshot_month_change.json` (cinco días a caballo del 1
  de noviembre con semana en domingo). Esos JSON los escribe el constructor de Dart y
  `test/features/widget/widget_android_fixture_test.dart` falla si dejan de coincidir
  (`UPDATE_WIDGET_FIXTURE=1 flutter test test/features/widget/widget_android_fixture_test.dart` los regenera).
- Dart: `widget_publisher_test` (capa `home_widget` simulada), `widget_sync_service_test` y `widget_host_test`
  (arranque, vuelta, cambios con espera, medianoche, fecha cambiada a mano, zona, calendario principal, toques).
- Emulador: `tool/qa/widget_android.sh` (W01–W05, `docs/qa.md`).

### Prueba de 7 días en Android (manual, antes de publicar)

Dispositivos: Android 13, 14, 15 y 16 (al menos uno Samsung y uno Xiaomi o similar, con su ahorro de batería).

1. Instala la build, añade los cinco widgets (Ajustes › Añadir widget), concede «Alarmas y recordatorios» y **sácala de
   recientes**. No abras la app en 7 días. Anota antes, de `HomeWidgetPreferences` (build de depuración, `run-as`) o de
   un botón de depuración, la etiqueta esperada de cada fecha.
2. Cada día: captura a las 00:05 y a las 08:00; deben decir el día de ese momento. Un día a las 00:00:30 también.
3. Perturbaciones: día 2 reinicio; día 3 ahorro de batería y modo ahorro extremo; día 4 cambio de zona (Madrid →
   Canarias → Madrid); día 5 modo avión a medianoche; día 6 cambio manual de fecha y vuelta; día 7 «optimización de
   batería» de la app activada.
4. **Caducidad:** adelanta la fecha 61 días (y 60 días y un minuto) respecto de `firstDate`: aviso honesto en los cinco
   widgets, ningún turno. En el del mes, además, el día 1 de un mes que cae en esos 60 días el título y la cuadrícula
   cambian solos. Vuelve a la fecha real: reaparecen los días.
5. Criterio: 7 de 7 días con el día correcto (y el mes correcto en el 4×4) en los cinco widgets en todos los dispositivos. Un widget que tarde más de 1
   minuto en cambiar sin el permiso de alarmas exactas se anota (límite conocido); con el permiso es un fallo.
