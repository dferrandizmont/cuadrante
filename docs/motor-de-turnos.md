# Motor de turnos (diseño)

Dart puro, sin Flutter ni zona horaria: `app/lib/features/schedule/domain/`. Es la única fuente de verdad de
«qué turno toca tal día» y la usan el calendario, el widget (línea de tiempo de 60 días), las alarmas, la
importación y el cálculo de horas. Pruebas en `app/test/features/schedule/domain/`.

Modelo de la especificación (§6): se guardan **reglas y excepciones**, nunca una fila por día.

## Tipos

### `CivilDate`
Fecha sin hora ni zona (año, mes, día). Inmutable, `==`/`hashCode`/`Comparable`.
- `epochDay` (días desde 1970-01-01, calculado en UTC para no depender del horario de verano) y `CivilDate.fromEpochDay`.
- `addDays(n)`, `differenceInDays(other)`, `weekday` (1 = lunes … 7 = domingo, como `DateTime`).
- `CivilDate.fromDateTime(dt)` usa los campos locales de `dt`; `toIso()` → `2026-10-19`; `CivilDate.parse(iso)`.
- `firstDayOfMonth`, `daysInMonth`.

### `ShiftCategory { work, rest, absence }`
- `work`: cuenta horas (M, T, N, G, D…).
- `rest`: libre o saliente; no cuenta horas.
- `absence`: vacaciones, moscoso, libre disposición, baja…; no cuenta horas trabajadas (los contadores van en P1).

### `ShiftType`
`id`, `code` (1–3 caracteres, lo que se ve en la celda), `name`, `colorValue` (ARGB `int`),
`category`, `startMinute` y `endMinute` (minutos desde las 00:00, `null` en los tipos sin horario, como Libre o
Vacaciones; o los dos o ninguno), `paidMinutes` (opcional; por defecto la duración), `nightOverride` (`bool?`:
`null` = automático según la franja nocturna).
- `hasTimes`.
- `durationMinutes`: `(end - start) mod 1440`, y **0 significa 24 h** (08:00–08:00 es una guardia de 24 h). Sin
  horario → 0. Es la duración del **primer tramo** (ver «Turno partido»).
- `crossesMidnight`: el turno, con su segundo tramo si lo tiene, llega a la medianoche (`start + spanMinutes >= 1440`;
  para un turno sin partir es igual que `endMinute <= startMinute`).
- `copyWith`.

#### Turno partido (0.6.0, hueco A12)
Un tipo puede tener un **segundo tramo** (`segment2StartMinute`, `segment2DurationMinutes`; los dos o ninguno, esquema
v3 en `docs/datos.md`). El inicio es una hora del reloj: el segundo tramo empieza **la siguiente vez que llega esa
hora después de que acabe el primero** (puede ser pasada la medianoche) y el primero y el segundo, con el descanso
entre medias, caben en 24 h (`checkSegment2`). Sobre el tipo:
- `scheduledMinutes`: lo que se trabaja = primer tramo + segundo (sin el descanso). Es `durationMinutes` si no es
  partido. `effectivePaidMinutes = paidMinutes ?? scheduledMinutes`.
- `spanMinutes`: del inicio del primer tramo al fin del segundo, el descanso incluido. `lastEndMinute`: la hora del reloj
  en que acaba del todo (`segment2EndMinute ?? endMinute`). `segment2GapMinutes`: el descanso entre tramos.
- Un tipo partido **no es dos turnos**: en el día cuenta como un turno (`M + P` son dos), un día trabajado y un solo
  chip/código; lo que se parte es el tiempo.
- **Editor** (`ShiftTypeDraft`, Ajustes › Mis turnos): en la sección de horas, el interruptor «Turno partido» enseña
  «Segundo tramo» con inicio y fin (el fin se guarda como duración; mismo inicio y fin = 24 h, que no cabe). Cada
  `Segment2Problem` tiene su mensaje (`ShiftTypeIssue.segment2*`, en tú): incompleto, inicio fuera de rango, duración
  fuera de rango, empieza justo al acabar el primero («sería un solo tramo») y no cabe en 24 h (cubre también el
  solape con el primero). Mientras haya un problema el formulario no guarda: **ya no se descarta en silencio** un
  segundo tramo que no encaja (antes `toShiftType` lo quitaba). El descanso no pagado se resta del total de los dos
  tramos. Sin horario no hay sección ni segundo tramo. Para un turno nuevo, el botón «Usar “Partido 09–13 / 17–21”»
  (`splitShiftTemplate`) rellena horas y, si el nombre está vacío, nombre y código. Esa plantilla **no** está en
  `shiftTemplates` (la paleta con la que empieza cada calendario sigue siendo de 10 tipos).

### `Pattern`
`id`, `name`, `steps: List<List<String>>`: un paso por día del ciclo, cada paso con 0..n ids de `ShiftType`
(lista vacía = día sin turno). `lengthDays == steps.length` (≥ 1). Se admiten varios turnos en un paso.

### `PatternRun` (rotación aplicada)
`id`, `patternId`, `startDate`, `endDate?` (incluida; `null` = sin fin), `stepOffset` (paso del ciclo que cae en
`startDate`, por defecto 0), `seq` (`int`, orden de creación; gana el mayor).
- Paso del día `d` (si `startDate <= d` y (`endDate == null` o `d <= endDate`)):
  `(stepOffset + d.differenceInDays(startDate)) mod lengthDays`, siempre no negativo.

### `DayEntry` (excepción manual de un día)
`date`, `shiftTypeIds: List<String>?`, `note: String?`.
- `shiftTypeIds == null`: **no** sustituye al patrón (p. ej. un día con solo una nota).
- `[]`: el día queda vacío aunque el patrón diga otra cosa.
- `[a, b]`: sustituye al patrón con esos turnos, en ese orden.
- `isEmpty`: sin override y sin nota (no hace falta guardarla).

## Turno efectivo

`Schedule` (inmutable) recibe `shiftTypes`, `patterns`, `runs` y `entries` (`Map<CivilDate, DayEntry>`).

`resolve(CivilDate d) → ResolvedDay` con `date`, `shifts: List<ShiftType>`, `source` (`override` | `pattern` |
`none`), `runId?`, `stepIndex?`, `note?`:
1. Si hay `DayEntry` con `shiftTypeIds != null` → esos turnos (`override`).
2. Si no, la `PatternRun` que cubre `d` con mayor `seq` → los turnos de su paso (`pattern`).
3. Si no, vacío (`none`).

Los ids que no existan en `shiftTypes` (tipo borrado) se ignoran sin fallar. Varios turnos se devuelven en el orden
guardado. `resolveRange(from, to)` (ambos incluidos) devuelve un `ResolvedDay` por día; debe ser rápido
(pre-indexa las rotaciones; 400 días en microsegundos).

## Ocurrencias y horas

`ShiftOccurrence`: `date` (día de **inicio**), `shiftType`, `startMinuteAbs` y `endMinuteAbs` (minutos desde
`date` 00:00; el fin puede pasar de 1440 si cruza la medianoche), `durationMinutes`.
- Solo los tipos con horario generan ocurrencias.
- `schedule.occurrences(from, to)`: las que **empiezan** entre `from` y `to`.
- Las horas de un turno se imputan al día en que empieza (convención de nómina habitual); `splitByCivilDay()`
  reparte los minutos por día natural, para las horas festivas (P1).
- **Turno partido:** `ShiftOccurrence.allOf(fecha, tipo)` da **dos** ocurrencias (`segment` 0 y 1; `isSecondSegment`)
  y `ShiftOccurrence.of` solo la primera. Las dos llevan el día en que empieza el **primer** tramo, aunque el segundo
  empiece pasada la medianoche (20–23 y 01–03: las dos del día 20); `schedule.occurrences` devuelve las dos.
  `occurrence.paidMinutes` reparte los minutos pagados del tipo entre los tramos (cada uno entero, y un descanso no
  pagado sale del primero; la suma es siempre `effectivePaidMinutes`). Un turno sin partir sigue dando una sola
  ocurrencia idéntica a la de antes.

`NightWindow` (por defecto 22:00–06:00, ET art. 36; configurable): `nightMinutes(occurrence)` suma el solapamiento
con la franja de cada día que toque el turno, incluida la franja que empezó la noche anterior (un turno 04:00–12:00
tiene 2 h nocturnas). Si el tipo tiene `nightOverride == true`, toda la duración es nocturna; si es `false`, 0.

`HoursSummary.of(occurrences, window)`: `workedMinutes` (solo `work`; `paidMinutes` si está definido),
`nightMinutes`, `dayMinutes`. Con un turno partido, la franja nocturna se mide **contra cada tramo** (18–22 y 23–03:
0 + 4 h) y el descanso entre tramos no es tiempo trabajado ni nocturno; `nightOverride` manda sobre los dos.

**Horario de verano:** el motor cuenta en hora civil (la noche del cambio de marzo, un 22–06 cuenta 8 h). La
corrección a horas reales se hará en la capa de horas (P1) con `timezone`; queda anotada aquí a propósito.

## Edición (modo pintar) y deshacer

Funciones puras sobre `Map<CivilDate, DayEntry>`; nada de estado oculto.
- `PaintTool`: `replace(shiftTypeId)` (el día queda `[id]`), `add(shiftTypeId)` («doblar»: añade si no está; parte
  de los turnos efectivos del día) y `erase` (el día queda vacío).
- `schedule.paint(tool, Iterable<CivilDate> days) → EntriesPatch`: para cada día, el `DayEntry` anterior (o
  `null`) y el nuevo (o `null` si queda vacío). **Normaliza**: si el override resultante coincide con lo que daría
  el patrón, se quita el override (conservando la nota); si el día queda vacío y el patrón también daría vacío, no
  se guarda override. Los días que no cambian no aparecen en el parche.
- `patch.applyTo(entries)` y `patch.inverse()` (deshacer exacto). `UndoStack` con `push`, `undo`, `redo`, `canUndo`
  y límite (100). Un arrastre completo es **un** paso de deshacer.
- `applyPattern(patternId, from, {until, stepOffset, clearOverrides = false}) → ScheduleChange` (nuevas runs +
  parche). Sin fin: recorta a `from - 1` las runs que siguen activas en `from` y borra las que empiezan en `from` o
  después. Con fin: no recorta nada (la nueva tapa a las demás dentro del rango y la rotación anterior sigue después
  de `until`) y solo borra las runs que quedan enteras dentro de `[from, until]`. La nueva lleva `seq` = máximo + 1. Con `clearOverrides`, quita los overrides de turnos (no las notas) en el
  rango.

### Edición desde el detalle del día

`ScheduleController` (capa de aplicación) edita un día con los mismos parches normalizados que pintar; **cada
llamada es un único paso de deshacer** y pasa por la misma cola de escrituras:
- `setDayShifts(fecha, ids)`: los turnos del día, en ese orden (sin repetidos ni ids desconocidos). Si coinciden con
  lo que da la rotación no se guarda override; la nota se conserva. `clearDay(fecha)` = `setDayShifts(fecha, [])`
  (override vacío, o nada si la rotación también está vacía).
- `clearDayCompletely(fecha)` («Borrar día» del detalle del día): deja el día sin nada propio: override vacío (o nada si
  la rotación también está vacía) y fuera la nota, su aviso y las horas extra y de salida anticipada, en UN paso de
  deshacer. El festivo propio no es del horario: la hoja lo quita aparte y «Deshacer» lo devuelve junto con el resto.
  El botón está activo si el día tiene cualquier cosa de eso (turno, nota, aviso, extras, festivo propio).
- `setNote(fecha, texto)`: nota recortada; vacía la borra. No toca los turnos; una entrada sin override ni nota
  desaparece.
- `resetToPattern(fecha)`: quita el override (conserva la nota). Sin override no hace nada.
- `copyDay(origen, destino)`: turnos efectivos y nota del origen sobre el destino (normalizado contra la rotación del
  destino); si el origen no tiene nota, el destino conserva la suya.
- Tipos de turno: `saveShiftType`, `archiveShiftType` y `reorderShiftTypes` actualizan paleta y calendario al
  instante y escriben por la cola; **no tocan el historial de deshacer** (este solo habla de días, y los ids no
  cambian). Archivar saca el tipo de la paleta, pero los días que lo usan lo siguen mostrando.

### Edición por rangos (modo selección)

Bloque final de `ScheduleController`; igual que arriba, **cada llamada es un único paso de deshacer** (devuelve el
paso o `null` si nada cambia) y todo se normaliza contra la rotación, conservando las notas. La planificación pura
vive en `features/calendar/domain/range_editing.dart`.
- `setShiftOnDays`, `doubleShiftOnDays`, `clearDays`: los mismos parches que pintar (con «Saliente automático» si
  está activo); `resetDaysToPattern`; `setNoteOnDays` (blanco la quita).
- `DayClipboard.capture` copia lo que los días **muestran** (turnos efectivos y nota) con su distancia al primero.
  `pasteDays(clip, inicio, includeNotes)` los pone a partir de `inicio`; por defecto solo turnos, y con
  `includeNotes` la nota copiada sustituye a la del destino (un día copiado sin nota deja la del destino). Los
  festivos no se copian nunca. **Cortar** (`SelectionController.cut`) deja el portapapeles marcado `isCut`: la nota, su
  aviso y las horas extra / salida anticipada salen del origen con el corte, así que **pegar un corte las trae siempre**
  (`pasteDays` ignora `includeNotes` mientras el corte siga aplicado; el cuadro de Pegar no ofrece «Incluir notas»
  y dice «Al cortar, las notas se mueven con los días»). El portapapeles conserva el calendario de origen y la
  identidad de la operación: solo deshacer ese paso exacto devuelve la elección de notas; rehacerlo vuelve a
  trasladarlas. Las coincidencias de contenido, en el mismo calendario o en otro, nunca se interpretan como
  deshacer. Cambiar de calendario conserva este estado aunque borre el historial local de deshacer. Un corte sin
  notas (`withNotes: false`) o una copia conservan la elección.
    Tras pegar se conserva la identidad del corte, aunque el portapapeles se comporte como una copia:
    deshacer ese pegado exacto vuelve a exigir el traslado de todas las anotaciones y rehacerlo lo da por completado.
- `repeatDays(días, n)` (1–52): el bloque es el tramo del primer al último día elegido (huecos incluidos) y la copia
  `k` empieza `k` bloques después del primero. Las copias salen del estado anterior a la acción.
- `endRun(runId, primerDíaSinElla)` acorta la rotación hasta el día anterior (`null` si no la acorta; para
  dejarla sin días, `deleteRun`); `deleteRun(runId)` la quita entera. Los overrides y las notas no se tocan. No crean
  rotaciones nuevas, así que no usan `nextRunSeq`; deshacer repone la run con su `seq`.

## Presets (`presets.dart`)

Plantillas de tipo (`ShiftTemplate`, con clave estable) con la paleta de la especificación §4:

| clave | código | nombre | color | horario | categoría |
|---|---|---|---|---|---|
| morning | M | Mañana | `#F5A524` | 06:00–14:00 | work |
| afternoon | T | Tarde | `#F06A3F` | 14:00–22:00 | work |
| night | N | Noche | `#4B4FD1` | 22:00–06:00 | work |
| rest | L | Libre | gris claro con borde (`#E4E4E7`) | — | rest |
| guard24 | G | Guardia 24 h | `#E5484D` | 08:00–08:00 | work |
| postNight | S | Saliente | `#8E7CC3` | — | rest |
| vacation | V | Vacaciones | `#30A46C` | — | absence |
| personalDay | LD | Libre disposición | `#12A594` | — | absence |
| day12 | D | Día 12 h | `#F5A524` | 08:00–20:00 | work |
| night12 | N12 | Noche 12 h | `#4B4FD1` | 20:00–08:00 | work |

Presets de patrón (`PatternPreset`: `id`, `name`, `description`, `steps` en claves de plantilla, `suggestedStart`
opcional como «empieza en lunes»), y `preset.materialize(Map<String clave, String shiftTypeId>) → Pattern`:

| id | ciclo | pasos |
|---|---|---|
| correturnos | 21 | M×5 L×2, T×5 L×2, N×5 L×2 (empieza en lunes) |
| 24x72 | 4 | G L L L |
| 12h | 4 | D N12 S L |
| 6x4 | 10 | M×6 L×4 |
| 4x4 | 8 | D×4 L×4 |
| 5x2 | 7 | M×5 L×2 (empieza en lunes) |
| 2-2-3 | 14 | D D L L D D D L L D D L L L |
| continental | 28 | M M T T N N N L L, M M T T T N N L L, M M M T T N N L L L |
| dupont | 28 | N12×4 L×3 D×3 L N12×3 L×3 D×4 L×7 |

**2-2-3 y «2-2-3-2-2-3» son el mismo preset.** Los 14 días son las dos semanas del 2-2-3 escritas una tras otra
(2 trabajo, 2 libres, 3 trabajo | 2 libres, 2 trabajo, 3 libres); también se conoce como Pitman o Panamá. No hay un
segundo preset: la descripción lo nombra con los dos nombres para que se encuentre buscando cualquiera.

**Continental** (turno continuo con 3 turnos de 8 h y 4 equipos): ciclo de 28 días en el que cada equipo hace 7
mañanas, 7 tardes, 7 noches y descansa 7 días, con bloques de 2 y 3 días y siempre hacia delante (M → T → N → libre),
de modo que nadie pasa de noche o tarde a mañana al día siguiente. Los cuatro equipos entran con 7 días de
diferencia (`stepOffset` 0, 7, 14 y 21) y cada día hay exactamente un equipo en mañana, uno en tarde, uno en noche y
uno libre (prueba en `presets_test.dart`). Se eligió así, y no otro reparto, porque es el único ciclo de 28 días con
bloques de 2-3 días y sin retrocesos de turno (se comprobó por búsqueda exhaustiva: las demás soluciones son este
mismo ciclo girado). Un «continental de 5 equipos» tendría un ciclo de 35 días; no hay un estándar documentado y no
se incluye.

**DuPont** (4 equipos, turnos de 12 h, 28 días): 4 noches, 3 libres, 3 días, 1 libre, 3 noches, 3 libres, 4 días y
7 libres. Usa los tipos `day12` (D, 08–20) y `night12` (N12, 20–08).

Los turnos Libre de los presets son el tipo L explícito (así se pinta el gris), no un paso vacío.

## Asistente de patrón y saliente automático

`app/lib/features/patterns/`. El asistente (`/patron`) no toca el motor: construye una `PatternRequest` (patrón,
`from`, `until`, `stepOffset`, `clearOverrides`) y `planPatternApplication` la convierte en **un** `ScheduleChange`
con `Schedule.applyPattern` (la misma función que pinta la vista previa y que se aplica; así lo que se ve es lo que
se guarda). `ScheduleController.applyPatternRun` lo aplica: espera a las escrituras en cola, pide
`ScheduleRepository.nextRunSeq()` (único entre calendarios), crea los tipos de turno que falten (plantillas
`shiftTemplates` con el id = clave) y el patrón si es nuevo, y mete todo en un solo paso de deshacer.

**Saliente automático** (ajuste `postNight.auto`, apagado por defecto): tras pintar o aplicar un patrón, un turno de
trabajo que cruza la medianoche y acaba por la mañana (`endsNextMorning`: noche, noche de 12 h, guardia de 24 h)
convierte el día siguiente en Saliente (`postNight`) **solo si ese día quedaría vacío o Libre** (`isLibre`: el tipo de
descanso sin horario). Nunca pisa un turno, una ausencia ni un Saliente. Va en el mismo paso de deshacer que la
pintura o el patrón (`combinePatches`: el `before` del primero y el `after` del segundo, de modo que deshacer
restaura el original exacto). En un patrón sin fin solo se miran los siguientes 366 días (cada Saliente es una
excepción y se guarda una a una). Si el tipo Saliente no existe se crea desde la plantilla; si el usuario lo
archivó, se respeta y no se añade nada.

## Resumen del mes (gratis, `app/lib/features/summary/`)

`summarizeMonth(schedule, mes, holidays:, window:)` (Dart puro, `domain/month_summary.dart`) cuenta un mes natural del
calendario activo; `summarizeYearTotals` junta los doce. Definiciones exactas:
- **Día de un turno:** el día en que **empieza**. La noche del 31 es de ese mes entera; la del último día del mes
  anterior no entra. Cada turno de un día cuenta una vez (M + T = 2 turnos, 1 día trabajado).
- **Turnos trabajados:** turnos de categoría `work` (los de sin horario cuentan como turno, no suman horas).
- **Horas:** `paidMinutes` (por defecto la duración; en un turno partido, la suma de los dos tramos sin el descanso entre
  ellos) de los turnos `work` con horario; la guardia de 24 h son 24 h. Un turno partido cuenta como un turno y un día
  trabajado.
  Horas de reloj (hora civil): el cambio de hora no corrige la noche a 7 o 9 h.
- **Nocturnas:** solape con la franja 22:00-06:00 (`NightWindow`; en un turno partido, de cada tramo y sumado),
  `nightOverride` manda, y nunca más que los minutos
  pagados de ese turno.
- **Estimado:** minutos pagados de cada tipo x `hourlyRateCents` / 60, redondeado al céntimo (medio hacia arriba) **por
  tipo**, más los pluses fijos por turno (`fixedPlusCents`). Cada turno de trabajo suma su plus una vez, también sin
  horario o sin precio por hora; un día con dos turnos suma los dos y un turno partido suma uno. Descansos y ausencias
  no suman plus. La tarjeta muestra «Pluses» con el número de turnos con plus y su importe, incluido en el total.
  Un tipo de trabajo con horas y sin precio por hora no suma pago por horas y se avisa («sin precio»), pero conserva
  su plus. Sin ningún precio por hora ni plus configurado en los turnos del periodo no hay total (`null`); un plus
  configurado de 0 € sí da un total de 0 €. Todo es gratis; los pluses por hora nocturna o festiva no están
  implementados y, cuando lo estén, serán gratuitos (decisión del 26-oct-2026).
- **Horas en festivo:** minutos del turno que caen en una fecha festiva (`splitByCivilDay`, así la noche que entra en un
  festivo cuenta la parte de después de medianoche; en un turno partido, de cada tramo, sin contar el descanso entre
  ellos), proporcionales a pagado/total si hay descanso no pagado. Se
  imputan al mes en que **empieza** el turno, de modo que son un subconjunto de sus horas.
- **Días libres:** días con un turno `rest` y sin turno `work` ni ausencia. **Ausencias:** días con algún tipo
  `absence` (y los días de cada tipo por separado).
- **Horas extra y salidas anticipadas (A6):** los minutos que el usuario anota en un día (`DayEntry.overtimeMinutes`,
  `earlyLeaveMinutes`, que `Schedule.resolve` expone en `ResolvedDay`) son **del día**, no de un turno, y van al mes de
  ese día. Por día, con `pagado` = minutos pagados de sus turnos `work` con horario:
  - La **extra suma siempre**, también en un día sin turno, libre o de ausencia (el usuario dice que trabajó). No
    cambia los días trabajados, los turnos ni las nocturnas (no se sabe a qué hora fue: cuenta como hora diurna).
  - La **salida resta como mucho `pagado + extra`**: un día nunca baja de 0 h. Lo que se informa en
    `earlyLeaveMinutes` es lo **aplicado** (no lo escrito), de modo que `shiftMinutes + overtimeMinutes -
    earlyLeaveMinutes == workedMinutes` siempre. En un día sin turno de trabajo y sin extra, la salida no resta nada.
  - `workedMinutes` es el **total** (turnos + extra − salida); `shiftMinutes` son solo los turnos. Las horas por tipo
    (`ShiftTypeMonth.paidMinutes`) no incluyen los extras. La comparación con el mes anterior y la tabla del año usan
    el total. Las horas en festivo siguen siendo solo las de los turnos. Un mes con solo horas extra no está vacío.
  - **Euros:** la extra y la salida se valoran al precio por hora del **primer turno de trabajo del día, en el orden
    del día, que tenga horario y precio**. Sin ese turno (día libre, ausencia, turnos sin precio) los euros no se
    tocan y los minutos van a `extrasWithoutRateMinutes` (el resumen avisa: «no están en el estimado»). La deducción
    de un día nunca pasa de lo que pagan sus turnos con precio más su extra. Se acumula sin redondear por día
    (céntimo-minutos) y se redondea **una vez por mes** (medio hacia arriba): `overtimeCents`, `earlyLeaveCents`. El
    estimado es la suma de los tipos + `overtimeCents` − `earlyLeaveCents`, nunca menor que 0, **más los pluses fijos**:
    ni la salida anticipada ni el descanso no pagado reducen el plus. Ejemplo: 3 días con 1 min
    de extra a 10 €/h son 50 céntimos (no 3 x 17).
  - Pantalla: en la tarjeta de horas, las líneas «Horas extra» (`+2 h`, con su importe en el estimado) y «Salidas
    anticipadas» (`−1 h`) solo si el mes las tiene; la tabla del año las suma en su total y lo explica en sus notas.
- Comparación con el mes anterior: diferencia de horas trabajadas.
- **Por fechas (gratis, hasta 366 días):** `summarizeRange(schedule, primero, último, ...)` es el único agregado;
  `summarizeMonth` es el rango del primer al último día del mes (hay una prueba que lo exige para varios meses y
  calendarios). Las mismas definiciones: un turno cuenta en el día en que empieza, así que la noche del último día
  entra entera. `SummaryRange` (`domain/summary_range.dart`) valida de 1 a 366 días, recorta el final al límite y
  compara con los mismos días inmediatamente anteriores. En la pantalla (`/resumen` › «Fechas…») no hay imagen para
  compartir.
La imagen del mes (`presentation/month_share_card.dart`, `month_image.dart`) se dibuja fuera de pantalla con tema
claro a 400 dp x 3 (1200 px de ancho) y no lleva notas, horas, importes ni la marca de horas extra (es privado); sí
lleva el icono del turno cuando cabe, con la misma regla que la casilla del mes.

## Pruebas mínimas
- `CivilDate`: aritmética a través de los cambios de hora de marzo y octubre, años bisiestos, `weekday`.
- Cada preset: longitud del ciclo, días trabajados y libres por ciclo, repetición exacta a los N ciclos, fechas
  concretas (p. ej. 24/72 desde el 1-ene-2026: guardias el 1, 5, 9…), `stepOffset`, fechas anteriores al inicio y
  posteriores a `endDate` vacías.
- Resolución: override > patrón > vacío; `[]` vacía un día con patrón; nota sin override no tapa el patrón; la run
  de mayor `seq` gana; ids desconocidos se ignoran; varios turnos por día en orden.
- Horas: 22–06 → 480 min nocturnos; 22–07 → 480 de 540; 15–22 → 0; 04–12 → 120; guardia 08–08 → 480 de 1440;
  20–08 → 480; `nightOverride`; `splitByCivilDay` de un 22–06 → 120 + 360; ocurrencia de un día imputada al día de
  inicio.
- Turno partido (`split_shift_test.dart`): dos ocurrencias con el día de inicio (también 20–23 + 01–03), reparto de
  minutos pagados, nocturnas de 18–22 + 23–03 (0 + 4 h), 20–23 + 01–03 (1 h + 2 h) y de una franja propia, resumen
  (horas, euros = pagados x precio, festivo por día civil y por tramo, mes de inicio, horas extra), días de cambio de
  hora (29 de marzo y 25 de octubre) y la tarjeta de hoy en cada momento (antes, tramo 1, descanso, tramo 2, después,
  descanso pasada la medianoche, cuenta atrás en hora real).
- Pintar: replace/add/erase, normalización contra el patrón, la nota se conserva, `inverse()` deja el mapa
  idéntico, `UndoStack` (undo/redo/límite), `applyPattern` recorta y respeta `clearOverrides`.
