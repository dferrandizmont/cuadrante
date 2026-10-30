# Datos locales (Drift)

Contrato de la base de datos del móvil. Es la pieza que decide si se pierden datos: cualquier cambio de esquema pasa
por una migración con prueba (ver «Migraciones»). La especificación (§6) manda: **reglas y excepciones, nunca una
fila por día**.

## Dónde vive
- Archivo `cuadrante.sqlite` en **Application Support** (`getApplicationSupportDirectory`), no en Documents ni en
  caché. En iOS entra en la copia del dispositivo (iCloud/Inicio rápido, R2 de la matriz) y no se ve en Archivos; en
  Android entra en Auto Backup (A1–A4).
- Clase `AppDatabase` en `app/lib/core/database/`. Se abre una vez en el arranque (`bootstrapApp`) y se inyecta con
  `appDatabaseProvider`. Las pruebas usan `NativeDatabase.memory()`.

## Esquema v1 (releases 0.1.0 y 0.2.0; la v2 de más abajo lo amplía)

Fechas de calendario como texto ISO `YYYY-MM-DD` (`CivilDate`, con `TypeConverter`): se leen bien al depurar, se
ordenan bien como texto y no dependen de la zona horaria. Marcas de tiempo (`created_at`, `updated_at`) en
milisegundos UTC. Listas de ids como JSON en texto.

| Tabla | Columnas | Notas |
|---|---|---|
| `shift_types` | `id` TEXT PK, `code` TEXT, `name` TEXT, `color_value` INT, `category` TEXT (`work`/`rest`/`absence`), `start_minute` INT?, `end_minute` INT?, `paid_minutes` INT?, `night_override` BOOL?, `sort_order` INT, `archived` BOOL = false, `created_at`, `updated_at` | Borrar un tipo lo **archiva**: los días pasados lo siguen mostrando. Los archivados no salen en la paleta. CHECK: `start_minute` y `end_minute`, los dos o ninguno, entre 0 y 1439. |
| `patterns` | `id` TEXT PK, `name` TEXT, `steps` TEXT (JSON `[[id, …], …]`, ≥ 1 paso), `created_at`, `updated_at` | |
| `pattern_runs` | `id` TEXT PK, `pattern_id` TEXT → `patterns.id`, `start_date` TEXT, `end_date` TEXT?, `step_offset` INT = 0, `seq` INT UNIQUE, `created_at` | CHECK `end_date IS NULL OR end_date >= start_date`. |
| `day_entries` | `date` TEXT PK, `shift_type_ids` TEXT? (JSON; **NULL = no sustituye al patrón**, `[]` = día vacío), `note` TEXT?, `updated_at` | Una fila solo si hay override o nota (el motor normaliza; el repositorio borra la fila si queda vacía). Desde la v3 también cuenta un recordatorio, horas extra o salida anticipada (`DayEntry.isEmpty`; ver «Esquema v3»). |
| `holidays` | `id` INT PK auto, `date` TEXT, `scope` TEXT (`national`/`regional`/`local`), `name` TEXT, `region_code` TEXT?, `municipality_code` TEXT?, `source` TEXT (`bundled`/`remote`/`user`) | Índice por `date`. Se llena en la semana 3. |
| `absence_balances` | `year` INT, `type` TEXT, `allowed_days` REAL, PK (`year`, `type`) | Lo usado se calcula de los días; aquí solo lo permitido. P1. |
| `settings` | `key` TEXT PK, `value` TEXT (JSON) | Preferencias sueltas (comunidad, municipio, franja nocturna…). |

Los campos de la especificación que todavía no se usan (adjuntos y «cambio con…» de `DayEntry`) **no** se crean
ahora: llegarán con su migración, que además estrena el arnés con un caso real.

## Repositorio

`ScheduleRepository` (en `features/schedule/data/`), sobre `AppDatabase`:
- `Future<ScheduleSnapshot> load(String calendarId)`: tipos (incluidos los archivados, para resolver el pasado) y
  patrones, que son comunes, más las rotaciones y entradas **de ese calendario**, en una sola transacción de
  lectura.
- `Future<void> apply(String calendarId, ScheduleChange change)`: en **una transacción**: para cada día del parche,
  borra la fila (`calendar_id`, `date`) si `after == null` o la escribe (upsert) si no; si `runsAfter != null`, deja
  las rotaciones **de ese calendario** iguales a `runsAfter` (borra las que sobran, inserta o actualiza el resto).
  Nunca toca otro calendario: un calendario que no existe falla por la clave foránea y un id de rotación que ya es
  de otro calendario se rechaza (`StateError`), todo sin escribir nada. Deshacer es
  `apply(calendarId, change.inverse())`: no hay otra vía de escritura de días y rotaciones.
  Antes de escribir, comprueba en esa misma transacción que todos los tipos referenciados por las entradas nuevas
  existen (también valen los archivados). Si falta alguno, rechaza el cambio completo con `StateError`, sin perder
  las entradas anteriores ni guardar referencias huérfanas.
- `nextRunSeq()`: el `seq` que debe tomar una rotación nueva (máximo de **todos** los calendarios + 1), porque
  `seq` es único en toda la tabla. `Schedule.applyPattern(..., seq: await repo.nextRunSeq())`; sin pasarlo,
  calcula el máximo de las rotaciones de su calendario y dos calendarios podrían chocar (la base de datos lo
  rechaza y el controlador recarga: no se corrompe nada, pero el cambio no se guarda).
- `saveShiftType` (con `hourlyRateCents`), `archiveShiftType`, `savePattern` (el editor llega en la semana 2; aquí
  basta con lo que usa la siembra).
- Conversión fila ↔ modelo del motor en un único sitio (`schedule_mappers.dart`), con pruebas de ida y vuelta.

## Arranque y siembra

1. `bootstrapApp()` abre la base de datos (con la copia previa a la migración, abajo) y carga el `Schedule` inicial
   del calendario activo (`calendars.active`; `main` la primera vez) **antes del primer frame**: el calendario aparece con datos, sin parpadeo (objetivo de la especificación: ver el
   turno de mañana en menos de 1 s). Se inyecta con `initialScheduleProvider`.
2. Si la base de datos está vacía (sin tipos de turno): siembra los tipos de `shiftTemplates` (id = clave de la
   plantilla, `sort_order` en el orden de la tabla) y los patrones de `patternPresets`. Sin rotaciones ni días: el
   primer uso (semana 3) los crea.
3. Con `USE_DEMO_DATA=true` (por defecto en desarrollo), la siembra añade además la rotación y los días de prueba de
   `buildDemoSchedule`. Solo en una base de datos vacía: nunca pisa datos.

## Escritura desde la UI
- El controlador cambia el estado en memoria al instante y manda el cambio al repositorio en una **cola en serie**
  (las escrituras se aplican en orden aunque se encadenen deprisa).
- Durante un trazo no se escribe nada; al cerrarlo (`endStroke`) se escribe el cambio completo. Deshacer y rehacer
  escriben su cambio igual.
- Si una escritura falla: se informa a `CrashReporter`, se recarga el `Schedule` desde la base de datos (la verdad
  es lo guardado) y se avisa al usuario («No se ha podido guardar el cambio»). Nunca se queda la UI mostrando algo
  que no está guardado sin decirlo.

## Esquema v2 (release 0.3.0): varios calendarios y precio por hora — hecho

Motivo: paridad (LRHSoft permite 10 calendarios; segundo trabajo, pareja) y resumen de ingresos gratis
(`docs/roadmap.md`). Hay usuarios con la v1 instalada (APK 0.1.0 y 0.2.0): **la migración no puede perder nada**.

| Cambio | Detalle |
|---|---|
| Tabla nueva `calendars` | `id` TEXT PK, `name` TEXT, `color_value` INT, `sort_order` INT, `archived` BOOL = false, `created_at`, `updated_at`. La migración crea `main` («Mi cuadrante», color índigo, orden 0) |
| `pattern_runs.calendar_id` | TEXT NOT NULL → `calendars.id`; las filas existentes pasan a `main`. `seq` sigue siendo único global |
| `day_entries` | PK pasa de (`date`) a (`calendar_id`, `date`) y `calendar_id` TEXT NOT NULL → `calendars.id`: la tabla se recrea (`TableMigration` de Drift) copiando las filas con `calendar_id = 'main'` |
| `shift_types.hourly_rate_cents` | INT NULL (precio por hora para el resumen gratis; céntimos, sin coma flotante) |
| Ajustes | `calendars.active` (el que se ve) y `calendars.primary` (el que usan el widget y las alarmas), por defecto `main` |

**Estado: hecho** (`schemaVersion` 2; volcado `app/drift_schemas/app_database/drift_schema_v2.json`). Una base de
datos nueva (`onCreate`) y la migración dejan el mismo `main`; `bootstrapApp` llama además a
`CalendarsRepository.ensureMain()`, una red de seguridad para que la app no arranque sin calendario. Una base de
datos nunca se queda sin calendarios: no se puede archivar el último y una copia sin ninguno activo se rechaza.

Los tipos de turno y los patrones son **comunes** a todos los calendarios; las rotaciones y los días son de cada uno.

**Comparar calendarios** (gratis, `/comparar`; `calendars/domain/calendar_comparison.dart`): solo lectura. Lee el
`Schedule` de cada calendario (el activo desde el editor en memoria; los demás con `ScheduleRepository.load`, sin
cambiar el calendario activo ni escribir nada). Un día es **libre** si no tiene ningún turno de categoría `work`
(vacío, descanso, ausencia o descanso + ausencia); un turno cuenta en el día en que empieza.
El motor no cambia: un `Schedule` es el de un calendario. `ScheduleRepository.load(calendarId)` y
`apply(calendarId, change)` (ver «Repositorio»).

### Calendarios (`features/calendars/`)
- `Calendar` (`domain/calendar.dart`) y las constantes de `main` (`mainCalendarId`, `mainCalendarName`,
  `mainCalendarColor`). `CalendarsRepository` (`data/`): `list`, `create`, `rename`, `recolor`, `archive`,
  `activeId`, `primaryId`, `setActive`, `setPrimary`, `ensureMain`.
- **Archivar** no borra: las rotaciones y los días se quedan guardados. Se rechaza archivar el último calendario
  (`LastCalendarCannotBeArchived`) o uno que no existe (`CalendarNotFound`). Si el archivado era el activo o el
  primario, esos ajustes pasan al primer calendario que queda.
- **Sin límite de calendarios.** Ya no existe `CalendarLimits` (ni `free`, ni `pro`, ni `calendarLimitsProvider`): con la
  gratuidad total (decisión del 26-oct-2026) el tope de 10 **se retiró del código** y no hay nivel «pro». `create` no
  comprueba ningún tope ni lanza `CalendarLimitReached`; los archivados tampoco influyen. Se pueden crear todos los
  calendarios que hagan falta, y recuperar un archivado nunca falla por el número.
- **Ajuste** `postNight.auto`: `true` / `false` en JSON (Saliente automático; apagado si no existe). Lo lee y escribe
  `PostNightSettingsRepository` (`features/patterns/data/`) y lo expone `postNightAutoProvider`.
- **Ajustes** `calendars.active` y `calendars.primary`: texto JSON con el id (`"main"`), en la tabla `settings`.
  Sin valor valen `main`. Un id que no existe o está archivado (una copia restaurada, por ejemplo) se resuelve a un
  calendario que sí existe, nunca rompe el arranque.
- `ScheduleController` trabaja sobre el calendario activo (`ScheduleState.calendarId`; cada escritura en cola lleva
  el calendario en que se hizo). `switchCalendar(id)` guarda `calendars.active`, carga el calendario y vacía
  deshacer y el trazo abierto; las escrituras ya hechas siguen yendo a su calendario. `reload()` (tras restaurar)
  vuelve a leer el activo guardado.
- Alarmas y widget usan el calendario **primario**: `readPrimarySchedule(ref)`
  (`calendars/application/primary_schedule.dart`) devuelve el `Schedule` en memoria si el primario es el que se ve
  y, si no, lo lee de la base de datos. `AlarmSync.readSchedule` acepta `FutureOr<Schedule>`. El widget, cuando se
  conecte su sincronización, lee por la misma función.
- `CalendarsController` (`application/`) envuelve el repositorio para la interfaz (lista de calendarios y
  primario). Archivar el calendario que se ve cambia a otro; cambiar o archivar el primario recalcula las alarmas.

### El paso v1 → v2 (código real)
`app/lib/core/database/migration_v1_to_v2.dart`, enchufado en `AppDatabase.migration`:

```dart
onUpgrade: stepByStep(from1To2: migrateFrom1To2),

Future<void> migrateFrom1To2(Migrator m, Schema2 schema, {...}) async {
  final db = m.database;
  await db.transaction(() async {            // todo o nada: si algo falla, el archivo sigue en v1
    final types = await count('shift_types');
    final runs = await count('pattern_runs');
    final entries = await count('day_entries');

    await m.createTable(schema.calendars);
    await db.customStatement(
      'INSERT INTO calendars (id, name, color_value, sort_order, archived, created_at, updated_at) '
      'VALUES (?, ?, ?, 0, 0, ?, ?)',
      ['main', 'Mi cuadrante', 0xFF4B4FD1, stamp, stamp],
    );
    await m.addColumn(schema.shiftTypes, schema.shiftTypes.hourlyRateCents);
    await m.alterTable(TableMigration(schema.patternRuns,
        columnTransformer: {schema.patternRuns.calendarId: const Constant<String>('main')},
        newColumns: [schema.patternRuns.calendarId]));
    await m.alterTable(TableMigration(schema.dayEntries,
        columnTransformer: {schema.dayEntries.calendarId: const Constant<String>('main')},
        newColumns: [schema.dayEntries.calendarId]));

    // Sin perder filas y todo en `main`: si no, lanza y la transacción se deshace.
    ...
  });
}
```

Los valores de `main` son literales a propósito (una migración que ya se publicó no debe cambiar si cambia una
constante); una prueba los compara con las constantes que usa la app. Las pruebas del paso están en
`test/drift/app_database/migration_v1_to_v2_test.dart` (datos reales, comparación fila a fila de todas las columnas
de v1, huella de los 730 días de `main` antes y después, el paso que falla deja el archivo en v1 y el siguiente
arranque lo migra) y `test/core/database/upgrade_from_v1_test.dart` (archivo real en disco por `openAppDatabase`:
copia previa, abrir dos veces, instalación nueva).

**Copia de seguridad:** el formato `.cuadrante` (hoy `.turnly`) pasa a `schemaVersion` 2 (incluye `calendars`, `calendarId` en
rotaciones y días y `hourlyRateCents` en los tipos de turno). El lector acepta v1 (todo a `main`) y v2
(`docs/copia-de-seguridad.md`); el archivo dorado v1 sigue restaurándose igual y hay un dorado v2. La huella
cubre todos los calendarios.

**Pruebas obligatorias (hechas):** paso v1→v2 con datos reales (tipos, patrones, 3 rotaciones con una recortada,
excepciones con varios turnos, `[]`, solo nota, festivos propios, ajustes) y comparación de la huella de 730 días
antes y después; la copia previa a la migración existe y abre como v1 con los mismos datos; abrir dos veces no
repite nada; una instalación nueva tiene `main`; un `.cuadrante` v1 restaura en v2.

### Preferencias de la pantalla Ajustes (`features/settings/`)
Texto JSON en `settings`, leídas por `PreferencesRepository` (valor ausente o no válido = valor por defecto) y
cargadas en `bootstrapApp` antes del primer frame (`initialPreferencesProvider`):

| Clave | Valores | Por defecto |
|---|---|---|
| `appearance.themeMode` | `"system"`, `"light"`, `"dark"` | `"system"` |
| `calendar.weekStart` | `1` (lunes), `7` (domingo) | `1` |
| `calendar.weekNumbers` | `true` / `false` (columna con el número de semana ISO) | `false` |
| `appearance.language` | `"system"`, `"es"`, `"ca"`, `"gl"`, `"eu"`, `"en"` (Ajustes › Apariencia › Idioma) | `"system"` |

`appearance.language` = `"system"` sigue los idiomas preferidos del móvil, en orden, y se queda con el primero que
tenga la app; si no hay ninguno, español. Un valor desconocido o un idioma cuyo ARB ya no exista se lee como
`"system"`. El cambio se aplica al momento (`MaterialApp.locale`) y vuelve a publicar los textos que van a lo nativo
(avisos de las alarmas y del widget).

Con domingo como primer día, cada fila (domingo a sábado) muestra la semana ISO de su jueves. Viajan en la copia de
seguridad (tabla `settings`) y se releen tras restaurar.

### Primer uso (`features/onboarding/`)
Texto JSON en `settings`, leído por `OnboardingRepository`. `bootstrapApp` decide **antes del primer frame** si se
abre `/bienvenida` en lugar del mes (`initialOnboardingProvider`):

| Clave | Valores | Significado |
|---|---|---|
| `onboarding.done` | `true` | El primer uso se hizo, se saltó o no hacía falta. Una vez a `true`, no vuelve. |
| `onboarding.profile` | `"nursing"`, `"medicine"`, `"police"`, `"firefighters"`, `"industry"`, `"security"`, `"hospitality"`, `"other"` | La profesión elegida en el paso 1 (ausente si se saltó). |
| `onboarding.tipPending` | `true` / `false` | El consejo del mes («Pinta tu mes en un momento») espera a que lo cierren. |
| `onboarding.factoryCatalog` | Instantánea JSON de los tipos, patrones y calendario de fábrica | Procedencia provisional, solo al crear una base nueva sin demo. No viaja en las copias. |

Se muestra solo si no hay `onboarding.done` y, además: no hay datos (ni una fila de `pattern_runs` ni de
`day_entries` en ningún calendario; quien actualiza con datos queda marcado como hecho al arrancar) y no es una
compilación con datos de demostración (salvo `--dart-define=FORCE_ONBOARDING=true`, que ignora la demo y los datos
pero no la marca `onboarding.done`). El lugar se guarda en `holidays.region` / `holidays.municipality` por el
camino de siempre (`HolidayController.setPlace`).

El idioma se guarda al elegirlo en el primer paso. Los nombres y códigos de fábrica se fijan en ese idioma antes de abrir el importador o al terminar, solo si la instantánea provisional sigue intacta y no hay datos propios. Se consume entonces la marca: una edición, importación, restauración o un cambio posterior de idioma nunca renombra datos existentes. Una base anterior nunca recibe esta procedencia, aunque sus nombres coincidan con los de fábrica.

Las demás elecciones viven en memoria hasta el final del paso 4 (se puede volver atrás o salir sin
dejar medio calendario hecho). Al terminar, por los controladores de siempre: las horas de la profesión sobre los
tipos de turno que ya existen (solo los que conservan las horas de la paleta estándar; nunca se crea un tipo
repetido) y su orden en la barra de pintar, el lugar, y la rotación como **un solo** `applyPatternRun`.

## Esquema v3 (release 0.6.0 «Paridad»): recordatorio, horas extra, icono, sonido y turno partido — hecho

Motivo: los huecos de paridad con las apps líderes (`docs/paridad.md`): recordatorio en la nota (A1), sonido de alarma
por tipo (A3), horas extra y salida anticipada (A6), icono por turno (A8) y turno partido (A12). Solo es la capa de
datos: sin pantallas nuevas, el motor no cambia. Hay usuarios con la v2 instalada (0.3.0 a 0.5.0): **la migración no
puede perder nada** y todo lo nuevo es `NULL` en lo que ya existe.

| Tabla | Columna nueva | Detalle |
|---|---|---|
| `day_entries` | `note_reminder_minute` | INT NULL, CHECK entre 0 y 1439: minuto de **ese día civil** en que suena la nota (A1) |
| `day_entries` | `overtime_minutes` | INT NULL, CHECK ≥ 0: minutos extra trabajados ese día (A6) |
| `day_entries` | `early_leave_minutes` | INT NULL, CHECK ≥ 0: minutos que se salió antes (A6) |
| `shift_types` | `icon` | TEXT NULL: clave de `ShiftIcon` (texto plano a propósito: una clave desconocida se lee como «sin icono», nunca falla) (A8) |
| `shift_types` | `alarm_sound` | TEXT NULL, CHECK no vacío: id opaco del sonido o tono del sistema elegido para el tipo; `NULL` = el del canal (A3) |
| `shift_types` | `segment2_start_minute`, `segment2_duration_minutes` | INT NULL: segundo tramo de un turno partido (A12). CHECK de tabla: los dos o ninguno; inicio entre 0 y 1439; duración entre 1 y 1440; solo en un tipo que tiene horas |

**Límites que aún no son CHECK.** `overtime_minutes` y `early_leave_minutes` solo llevan CHECK ≥ 0; el tope de
1440 (`maxDayExtraMinutes`) lo hacen cumplir el editor, `BackupData.validate` (rechaza un archivo con más) y
`DayEntryRowMapper.toEntry` (acota al leer). No se sube el esquema solo por un CHECK: **`isBetweenValues(0, 1440)` en el
próximo cambio de esquema** (en una reconstrucción de `day_entries`, con prueba de migración). Lo mismo para
`shift_types.hourly_rate_cents` (0 a 999 999, `maxHourlyRateCents`, hoy solo en el editor y en la validación de la
copia).

**Estado: hecho** (`schemaVersion` 3; volcado `app/drift_schemas/app_database/drift_schema_v3.json`). Lo que no se puede
expresar en SQL (que el segundo tramo quepa después del primero dentro de 24 h) lo comprueba el dominio, y lo hacen
cumplir `ScheduleRepository.saveShiftType` (`ArgumentError` antes de escribir) y `BackupData.validate`. Al leer una
fila, un segundo tramo que el dominio no acepta se lee como «sin segundo tramo», un recordatorio fuera del día o unos
minutos negativos como «ninguno» y un icono desconocido como «sin icono»: una fila mala nunca rompe la app.

### Dominio
- `ShiftIcon` (`schedule/domain/shift_icon.dart`): lista cerrada de 30 claves (`sun`, `moon`, `sunrise`, `hospital`,
  `ambulance`, `police`, `fire`, `factory`, `truck`, `plane`, `school`, `home`, `beach`, `bed`, `star`, `heart`,
  `coffee`, `book`, `money`, `alert`, `phone`, `car`, `train`, `bus`, `shop`, `tool`, `baby`, `sport`, `party`,
  `medical`). **Nunca emojis.** La clave es lo que se guarda (base de datos y archivo); cada plataforma la dibuja con
  su juego de símbolos (`AppIcons`, en la capa de presentación). Las claves que salieron no se renombran ni se quitan;
  las nuevas van al final. `ShiftIcon.fromKey` devuelve `null` para lo desconocido.
- `ShiftType` lleva `icon`, `alarmSound`, `segment2StartMinute` y `segment2DurationMinutes` (inmutable, `==`,
  `copyWith` con `clearIcon` / `clearAlarmSound` / `clearSegment2`; quitar las horas quita también el segundo tramo).
- **Segundo tramo** (`checkSegment2`, devuelve un `Segment2Problem` o `null`): el inicio es una **hora del reloj**
  que se lee como «la próxima vez que llega ese minuto después de que acabe el primer tramo» (puede pasar de
  medianoche). Es válido si no empieza justo cuando acaba el primero (sería un solo tramo) y primer tramo + hueco +
  segundo tramo caben en 24 h (`ShiftType.spanMinutes`). Ejemplo: 08:00-12:00 y 16:00 durante 4 h es un turno de 12 h
  de principio a fin con 4 h de hueco. **El motor lo usa desde la 0.6.0** (`docs/motor-de-turnos.md`, «Turno partido»):
  `durationMinutes` sigue siendo el primer tramo, las horas son `scheduledMinutes` (los dos tramos sin el hueco) y las
  ocurrencias son dos (con `null` todo se comporta igual que antes). El editor ya no descarta en silencio un segundo
  tramo que no encaja: lo señala y no guarda.
- `DayEntry` lleva `noteReminderMinute`, `overtimeMinutes` y `earlyLeaveMinutes` (con `assert` de rango,
  `copyWith` con un `clear…` por campo y `withShiftTypeIds`). **Una entrada cuyo único contenido es un recordatorio,
  horas extra o salida anticipada no está vacía** (`DayEntry.isEmpty`); 0 minutos de extra o de salida equivale a
  nada. El recordatorio no depende de que haya texto en la nota: borrar la nota no borra el recordatorio (decisión
  tomada para que la pantalla futura pueda ofrecerlos por separado).
- **Edición por rangos:** el recordatorio, las horas extra y la salida anticipada siguen **exactamente** las reglas de
  la nota. Pintar, «Poner turno», «Doblar», «Borrar», «Volver al patrón», «Aplicar rotación» (con o sin quitar
  excepciones) y la importación conservan los tres campos del día (solo se tocan los turnos). Copiar, pegar, repetir y
  «Duplicar en otro día» los llevan en el portapapeles junto a la nota (`ClipDay`): se pegan solo con «Incluir notas»
  (`includeNotes`), un valor copiado sustituye al del destino y uno que el día copiado no tiene deja en paz al del
  destino, cada campo por separado. `withAnnotationsOf` es el único sitio que lo decide.
- La huella de la matriz (`resolvedDayLines`) añade un último elemento a la línea de un día que tiene recordatorio,
  horas extra o salida anticipada; los días que no tienen ninguno dan la misma línea que siempre (las huellas de los
  datos anteriores no cambian).

### El paso v2 → v3 (código real)
`app/lib/core/database/migration_v2_to_v3.dart`, enchufado en `AppDatabase.migration`:

```dart
onUpgrade: stepByStep(from1To2: migrateFrom1To2, from2To3: migrateFrom2To3),

Future<void> migrateFrom2To3(Migrator m, Schema3 schema, {...}) async {
  await db.transaction(() async {            // todo o nada: si algo falla, el archivo sigue en v2
    final before = await dump();             // todas las columnas de v2 de todas las tablas
    await m.addColumn(schema.dayEntries, schema.dayEntries.noteReminderMinute);
    await m.addColumn(schema.dayEntries, schema.dayEntries.overtimeMinutes);
    await m.addColumn(schema.dayEntries, schema.dayEntries.earlyLeaveMinutes);
    await m.alterTable(TableMigration(schema.shiftTypes, newColumns: [icon, alarmSound, segment2…]));
    // Cada fila de v2 igual, valor a valor, y las columnas nuevas vacías: si no, lanza y se deshace.
  });
}
```

`shift_types` se **reconstruye** (`TableMigration`) en vez de añadir columnas porque las reglas del segundo tramo son
CHECK de tabla, que `ALTER TABLE ADD COLUMN` no puede añadir; `day_entries` solo necesita CHECK de columna y se
amplía en el sitio. La copia previa (`pre-v2-a-v3-<fecha>.sqlite`, o `pre-v1-a-v3-…` si se salta desde la 1: **una
sola copia para toda la cadena**) se hace antes de abrir, como siempre. Cada paso de una cadena confirma por su
cuenta: si v2 → v3 falla en un archivo v1, el archivo se queda en v2 con todos los datos y el siguiente arranque
termina.

**Pruebas obligatorias (hechas)**, en `test/drift/app_database/migration_v2_to_v3_test.dart` (datos reales de tres
calendarios, fixture en `test/support/v2_database.dart`) y `test/core/database/upgrade_from_v2_test.dart` (archivo
real en disco por `openAppDatabase`): v2 → v3 fila a fila (todas las columnas de v2, ids de festivos incluidos) y
huella de 730 días de **cada** calendario antes y después; las columnas nuevas vacías; `testWithDataIntegrity` con las
clases generadas; v1 → v3 encadenado con datos reales; base v2 vacía; el paso que falla deja el archivo v2 exacto
(sin tablas temporales ni columnas nuevas) y el siguiente arranque migra; cadena v1 que falla en el último paso; los
CHECK del archivo migrado; escribir y leer los campos nuevos tras migrar (incluida la misma fecha en dos calendarios y
el rechazo de un segundo tramo inválido); copia previa legible como v2 y sin segunda copia al reabrir; **diario
caliente real** recuperado antes de copiar y migrar (solo sobrevive lo confirmado); un archivo sin copia posible no
se migra; los archivos de las migraciones anteriores se conservan (3 últimas). Los pasos v1 → v2 se prueban ahora
hasta v3, que es lo que hace la app.

**Copia de seguridad:** el formato `.cuadrante` pasa a `schemaVersion` 3 con los campos nuevos
(`docs/copia-de-seguridad.md`); el lector v2 no cambia y hay un dorado v3.

## Esquema v4: plus fijo por tipo de turno — hecho

El plus fijo por tipo de turno es gratis, igual que el precio por hora (especificación §7). Se guarda como
`shift_types.fixed_plus_cents`: INT NULL, CHECK entre 0 y 999 999. Son céntimos enteros; `NULL` significa que no
hay plus y 0 es un importe válido. No depende de las horas ni del segundo tramo: cada turno trabajado suma una
vez el importe de su tipo. Descansos y ausencias no lo suman. Los pluses por hora nocturna o festiva no están
implementados y no forman parte de este cambio; cuando se hagan serán gratuitos (decisión del 26-oct-2026).

`migration_v3_to_v4.dart` añade la columna en el sitio, dentro de una transacción. Conserva todas las columnas
anteriores y comprueba que la nueva empieza vacía. No reconstruye tablas ni endurece CHECK anteriores: los datos
históricos se conservan tal como estaban. El volcado es `app/drift_schemas/app_database/drift_schema_v4.json` y
los pasos se generan con `dart run drift_dev make-migrations`.

La copia automática previa sigue siendo obligatoria y cubre toda la cadena: `pre-v3-a-v4-<fecha>.sqlite` al
actualizar desde v3, o `pre-v1-a-v4-…` / `pre-v2-a-v4-…` desde versiones anteriores. Se crea antes de abrir con
Drift; si no puede hacerse, no se migra. Reabrir no repite la copia ni la migración.

Pruebas: `test/drift/app_database/migration_v3_to_v4_test.dart` compara cada columna de v3 en todas las tablas y
730 días de cada uno de tres calendarios, con tipos archivados, precio por hora, turno partido, icono, sonido y
anotaciones. Comprueba los nulos iniciales, escritura y lectura del plus, los límites SQL y el rollback y reintento
tras un fallo. `test/core/database/upgrade_from_v3_test.dart` usa un archivo real, verifica la copia legible como v3,
la apertura repetida conservando el plus y el bloqueo de la migración cuando falla la copia.

El formato de copia (`.turnly`, antes `.cuadrante`) sigue en **versión 3**: `fixedPlusCents` es opcional y se omite cuando vale `NULL`.
Las copias anteriores restauran sin plus. Una app anterior que lee v3 ignora esta clave desconocida y valida su
suma de control normalmente; no conserva ese importe al volver a exportar. Véase `docs/copia-de-seguridad.md`.

## Migraciones
- `schemaVersion` es 4 (la 1 fue la de las versiones 0.1.0 y 0.2.0; la 2, la de 0.3.0 a 0.5.0; la 3 añadió los
  campos de paridad de la 0.6.0). Esquemas guardados con
  `dart run drift_dev make-migrations` (configurado en `build.yaml`, carpeta `app/drift_schemas/`), que también
  genera las pruebas de migración y los pasos (`stepByStep`). Cada versión nueva: subir `schemaVersion`, ejecutar
  `make-migrations`, escribir el paso (en su propio archivo, como `migration_v1_to_v2.dart`, dentro de una
  transacción y con sus comprobaciones) y pasar sus pruebas con datos (no solo el esquema). `make-migrations`
  regenera también `test/drift/app_database/generated/` (se sube con el cambio).
- **Copia previa a la migración:** antes de abrir con Drift, se lee `PRAGMA user_version` del archivo; si es menor
  que `schemaVersion` (y mayor que 0), se copia el archivo a `backups/pre-v{origen}-a-v{destino}-{fecha}.sqlite`
  dentro de Application Support. Se guardan las 3 últimas. **Una sola copia por destino:** si ya existe un
  `pre-v*-a-v{destino}-*`, no se hace otra. Si v1 → v2 confirma y v2 → v3 falla en cada arranque, la copia buena es
  la primera (`pre-v1-a-v3-*`, los datos antes de tocar nada); una copia por arranque la habría borrado a la tercera
  pasada. Además, al podar nunca se borra la copia más antigua del destino actual. Con pruebas
  (`migration_backup_test.dart`, `upgrade_from_v2_test.dart`).
- **Esa copia no se ve en la interfaz** (decidido tras la campaña de QA, H-T16-1): «Copias en este móvil» solo lista
  las `.turnly` (o `.cuadrante` antiguas), no los `pre-v*.sqlite`. Es una red de seguridad interna, no una función para el usuario:
  el usuario recupera con las copias `.turnly` de Ajustes › Copia de seguridad. En una compilación de
  lanzamiento no se puede comprobar con `run-as` ni con `adb backup` (apps con `targetSdk` 36); se comprueba con la
  prueba automática o con una compilación de depuración.
- Prueba de humo en CI: el esquema que genera el código coincide con el último volcado de `drift_schemas/`
  (si alguien cambia una tabla sin migración, falla).
