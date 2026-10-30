# Copia de seguridad: formato `.turnly` y restauración

Contrato del archivo de copia y de la restauración. Lo que decide si alguien pierde su cuadrante: cualquier cambio
aquí lleva prueba (`app/test/features/backup/`) y **nunca rompe la lectura de archivos antiguos**. La matriz de
restauración (R4, R6, R7) está en `docs/plan-publicacion.md`; la base de datos, en `docs/datos.md`.

Código: `app/lib/features/backup/`. Las pantallas (Ajustes › Copia de seguridad, vista previa de restauración) están en
`presentation/` y se describen en el apartado 7; las copias automáticas, en el 8; abrir un archivo desde otra app, en
el 9; y la copia del sistema de Android, en el 10.

| Pieza | Fichero | Qué hace |
|---|---|---|
| Datos | `domain/backup_data.dart` | `BackupData` (una clase por tabla), normalización, `validate()`, `toSchedule()` |
| Formato | `domain/backup_codec.dart` | `BackupCodec.encode/decode`, gzip, suma de control, versiones |
| Errores | `domain/backup_errors.dart` | `NotACuadranteFile`, `NewerFormatVersion`, `CorruptBackup` |
| JSON canónico | `domain/canonical_json.dart` | claves ordenadas, sin espacios, sha256 |
| Huella | `domain/schedule_fingerprint.dart` | `scheduleFingerprint` (entidades + 730 días resueltos) |
| Resúmenes | `domain/restore_summary.dart` | `RestoreSummary`, `RestoreVerification` |
| Almacén | `domain/backup_store.dart`, `data/local_file_backup_store.dart` | interfaz `BackupStore` + implementación en archivos |
| Base de datos | `data/backup_repository.dart` | `readAll`, `preview`, `restore`, `verifyRestore` |
| Servicio | `application/backup_service.dart` | lo que llaman las pantallas |
| Restaurar | `application/restore_coordinator.dart` | `restoreAndReload`: **la única vía** para restaurar |
| Acciones | `application/backup_actions.dart` | exportar, probar, inspeccionar y restaurar, para las pantallas |
| Copias automáticas | `domain/auto_backup_policy.dart`, `domain/backup_retention.dart`, `application/auto_backup_runner.dart` | cuándo se hace una copia y cuáles se conservan (puro, con reloj falso en las pruebas) |
| Proveedores | `application/backup_providers.dart` | carpeta, almacenes, interruptor, `autoBackupRunnerProvider`, compartir y selector de archivo |
| Plataforma | `data/platform_backup_channel.dart` + `MainActivity.kt` | archivo recibido de otra app y estado de la copia del sistema |
| Pantallas | `presentation/` | `backup_screen.dart`, `restore_preview_screen.dart`, `backup_host.dart` |

## 1. El archivo

Desde el cambio de nombre a Turnly (30-oct-2026), todos los archivos nuevos usan `.turnly`.
Los archivos `.cuadrante` antiguos siguen aceptándose al importar, abrir desde otra app y listar o restaurar
copias locales o de iCloud. Solo cambian el nombre y la extensión: el formato interno, `format: "cuadrante"`,
la cabecera gzip, la versión, el esquema y los datos permanecen iguales. Renombrar la extensión permite leer
una copia nueva con una app antigua que soporte su versión de formato, y viceversa.

Un `.turnly` es **JSON UTF-8 comprimido con gzip**. El JSON, ya descomprimido, es siempre canónico (claves
ordenadas en todos los niveles, sin espacios ni saltos de línea), de modo que los mismos datos dan los mismos bytes.

```json
{
  "appVersion": "1.0.0",
  "checksum": "sha256:5e70fb5f…",
  "data": { "calendars": [], "shiftTypes": [], "patterns": [], "patternRuns": [], "dayEntries": [],
            "holidays": [], "absenceBalances": [], "settings": {} },
  "exportedAt": "2026-11-10T09:00:00Z",
  "format": "cuadrante",
  "schemaVersion": 3
}
```

La app escribe siempre la versión 3 (desde la 0.6.0). Los archivos de las versiones 0.1.0 y 0.2.0 son de la
versión 1, los de la 0.3.0 a la 0.5.0 de la versión 2, y se siguen leyendo (ver «Versiones»).

| Campo | Tipo | Significado |
|---|---|---|
| `format` | texto | Siempre `"cuadrante"`. Si no, el archivo no es nuestro. |
| `schemaVersion` | entero ≥ 1 | Versión del **formato** (no de la app). Ver «Versiones». |
| `appVersion` | texto | Versión de la app que lo escribió. Informativo. |
| `exportedAt` | texto | Fecha y hora UTC, a segundos: `2026-11-10T09:00:00Z`. |
| `data` | objeto | Los datos del usuario (abajo). |
| `checksum` | texto | `sha256:` + hex del sha256 del JSON canónico de `data` (UTF-8). |

### `data` (versión 3)

Reflejo de las tablas de `docs/datos.md` (esquema v4), con nombres en camelCase. Fechas de calendario como `YYYY-MM-DD`; marcas de
tiempo (`createdAt`, `updatedAt`) en milisegundos UTC; los campos vacíos se escriben como `null`, **salvo los de la
versión 3 (marcados abajo), que solo se escriben si tienen valor** (ver «Por qué se escriben solo si tienen valor»).

| Clave | Contenido | Orden |
|---|---|---|
| `calendars` | `id, name, colorValue, sortOrder, archived, createdAt, updatedAt`. Incluye los archivados; al menos uno no archivado | por `id` |
| `shiftTypes` | `id, code, name, colorValue, category (work/rest/absence), startMinute, endMinute, paidMinutes, nightOverride, hourlyRateCents (céntimos; null = sin precio), fixedPlusCents (opcional), icon (v3), alarmSound (v3), segment2StartMinute (v3), segment2DurationMinutes (v3), sortOrder, archived, createdAt, updatedAt`. Incluye los archivados. Comunes a todos los calendarios | por `id` |
| `patterns` | `id, name, steps ([[id,…],…]), createdAt, updatedAt` | **el orden en que se guardaron** |
| `patternRuns` | `id, calendarId, patternId, startDate, endDate, stepOffset, seq, createdAt` | por `seq` (único en todos los calendarios) |
| `dayEntries` | `calendarId, date, shiftTypeIds (null = no sustituye al patrón, [] = día vacío), note, noteReminderMinute (v3), overtimeMinutes (v3), earlyLeaveMinutes (v3), updatedAt` | por (`calendarId`, `date`) |
| `holidays` | solo `source = 'user'`: `date, scope, name, regionCode, municipalityCode` (sin `id`) | por (fecha, ámbito, nombre…) |
| `absenceBalances` | `year, type, allowedDays` | por (`year`, `type`) |
| `settings` | objeto `clave → valor`, donde el valor es **el texto JSON tal cual está en la base de datos** | por clave |

Los patrones son la única lista que no va ordenada por `id`: la tabla no tiene columna de orden y la app los muestra
en el orden en que se crearon, así que ese orden es dato. Al restaurar se insertan en ese orden.

**Campos de la versión 3:**

| Campo | Tipo | Significado y límites |
|---|---|---|
| `shiftTypes[].hourlyRateCents` | entero | (v2) Céntimos por hora; de 0 a 999 999 (`maxHourlyRateCents`, lo máximo que acepta el editor). Fuera de eso, `CorruptBackup`. |
| `shiftTypes[].fixedPlusCents` | entero | Extensión opcional del formato v3 (base de datos v4). Plus fijo por turno trabajado, en céntimos, de 0 a 999 999. Ausente o `null` = sin plus; 0 es un importe explícito. Solo se escribe si tiene valor; fuera de rango o con tipo distinto se rechaza antes de restaurar. |
| `shiftTypes[].icon` | texto | Clave de `ShiftIcon` (30 claves cerradas; nunca emojis). Una clave que esta versión no conoce se **lee como «sin icono»**, no es un error. |
| `shiftTypes[].alarmSound` | texto | URI del sonido del sistema. No vacío y de hasta 512 caracteres (`maxAlarmSoundLength`). Al restaurar solo se conserva si empieza por `content://media/` o `content://settings/` (`isSystemAlarmSound`); cualquier otra (por ejemplo la del `FileProvider` de la propia app) **se descarta a `null`** (suena el sonido por defecto) sin rechazar el archivo: `BackupData.sanitized`, en `restore` y en `verifyRestore`. El aviso de depuración dice cuántos, nunca cuáles. |
| `shiftTypes[].segment2StartMinute`, `segment2DurationMinutes` | entero | Segundo tramo de un turno partido: los dos o ninguno; inicio 0–1439; duración 1–1440; el tipo tiene horas; empieza después de que acabe el primer tramo y el turno entero cabe en 24 h (`checkSegment2`, `docs/datos.md`). Si no, `CorruptBackup`. |
| `dayEntries[].noteReminderMinute` | entero | Minuto del día civil (0–1439) en que suena la nota. |
| `dayEntries[].overtimeMinutes`, `earlyLeaveMinutes` | entero | Minutos extra trabajados y minutos que se salió antes; de 0 a 1440 (`maxDayExtraMinutes`, un día entero: lo mismo que deja el editor). Un valor mayor es `CorruptBackup`: sumado en el resumen desbordaría y daría horas negativas y euros absurdos. Al leer una fila de la base de datos, `DayEntryRowMapper.toEntry` también los acota a 0..1440. |

Un día cuyo único contenido es uno de estos campos es un día legítimo (no una fila vacía).

**Por qué se escriben solo si tienen valor.** Los campos de la versión 3 no se escriben cuando son `null` (en el
resto del formato, sí). Así, unos datos que nunca los usaron dan **los mismos bytes canónicos, la misma suma de
control y la misma huella** que daban en la versión 2: los archivos dorados v1 y v2 siguen cumpliendo «mismos bytes» y
«misma huella» con el escritor actual (más allá del número de versión del sobre), y un archivo v3 sin nada nuevo
solo se distingue de uno v2 por el `schemaVersion`. El lector trata una clave ausente y un `null` igual.

**Por qué se sube la versión aunque los campos sean opcionales** (la regla de la sección 2 lo permitiría sin subirla):
una app que solo conoce la versión 2 leería el archivo, ignoraría las claves nuevas y, al restaurar o volver a
exportar, **perdería los recordatorios, las horas extra, los iconos y los turnos partidos del usuario sin avisar**.
Con `schemaVersion` 3, esa app ve `NewerFormatVersion` (R6), no toca nada y propone actualizar.

**Plus fijo por tipo (24-oct).** La base de datos sube a v4, pero el archivo sigue en formato v3:
`fixedPlusCents` es un campo opcional y no cambia el significado de los existentes ni la suma de control.
Las copias v3 antiguas sin él restauran sin plus y conservan sus bytes canónicos y su huella.
Una app anterior que conoce el formato v3 comprueba la suma sobre el JSON recibido e ignora este campo
sin fallar; si restaura o vuelve a exportar desde esa app, **el plus no se conserva**. Es la compatibilidad
solicitada para este campo; no se añade ningún plus por hora ni dato de pago. Los lectores v1 y v2 siguen
ignorando las claves que no definían. Pruebas: `fixed_plus_backup_test.dart` (codec, restauración real,
copia previa, huella, límites y dorado antiguo).

### Qué entra y qué no (y por qué)

- **Entra todo lo que el usuario ha creado o configurado**, con sus marcas de tiempo: se restaura la base de datos tal
  cual estaba, no una reconstrucción parecida. La baja médica y demás ausencias de salud son días como los demás
  (`dayEntries` con un tipo de la categoría `absence`): viajan **dentro del archivo `.turnly` que controla el
  usuario** y, mientras la copia del sistema de Android esté activada, **también en la copia de Google** (la base de
  datos y `backups/` están en `files/`, que Auto Backup sube a la cuenta de Google del usuario: apartado 10). Ni feed,
  ni analítica, ni servidor nuestro. Qué hacer con los datos de salud en la copia de Google es una decisión pendiente
  (`docs/preguntas.md`, pregunta 13).
- **Los ajustes `onboarding.*` no entran** (`onboarding.done`, `onboarding.profile`, `onboarding.tipPending`):
  describen la vida de ese móvil con la app, no el cuadrante. No se exportan, un archivo que los trae (versiones
  anteriores exportaban todo `settings`) no los devuelve al restaurar, y restaurar deja intactos los del móvil. Al
  terminar un restore con éxito el primer uso se marca como hecho (`RestoreCoordinator`): un móvil al que se le acaba
  de restaurar un cuadrante no es un primer arranque. Un `.turnly` abierto durante el primer uso espera a que
  termine (`BackupHost`).
- **`appearance.language` tampoco entra**: el idioma de la app es de ese móvil, como `backup.cloud`. No se exporta,
  un archivo que lo trae no lo cambia y restaurar deja el idioma como estaba (`isDeviceSetting`).
- **Festivos `bundled` y `remote` no entran**: salen del paquete de la app o del paquete firmado de festivos y se
  vuelven a derivar de la comunidad y el municipio, que sí van en `settings`. Al restaurar no se tocan los que ya
  hay en el móvil; la función de festivos los recalcula desde los ajustes restaurados.
- **Nada que no esté en la base de datos**: ni compras ni suscripciones (no existen: la app es totalmente gratuita,
  decisión del 26-oct-2026, y R9 sale de la matriz), ni permisos, ni el estado de iCloud, ni las notificaciones
  programadas (se reprograman desde los datos), ni el widget.
- **Sin cuentas ni identificadores del dispositivo** en el archivo.

### Compresión

`gzip` estándar (RFC 1952), nivel 9, con cabecera fija: `1f 8b 08 00 00000000 02 ff` (sin fecha ni nombre, sistema
operativo «desconocido»), así que la cabecera es igual en todas las plataformas. El contenido comprimido puede variar
entre versiones de zlib; **lo estable es el JSON canónico y su suma de control**, no los bytes comprimidos. Se rechaza
lo que supere los **8 MiB comprimidos** (`BackupCodec.maxFileBytes`), los **32 MiB descomprimidos**
(`BackupCodec.defaultMaxDecodedBytes`) o la relación de **100:1** por encima de 64 KiB. El escritor aplica
los mismos límites: nunca guarda un archivo que el lector normal rechazaría por tamaño o relación. Si unas notas
repetitivas superan 100:1, escribe gzip sin compresión; ese archivo también debe caber en 8 MiB. Si no cabe,
la copia falla y una restauración no sustituye datos ni poda copias antiguas.

La copia previa a restaurar se vuelve a leer **desde el archivo escrito** con `BackupCodec.decode` y se compara
con los datos actuales antes de reemplazar la base o podar copias. Un fallo de lectura, validación o comparación
aborta con el error existente. Las copias anteriores siguen disponibles. La regresión incluye una nota de 5 MiB,
superior al antiguo límite de 4 MiB y con una compresión que superaría 100:1, y recupera íntegramente los datos.
### Lectura (`BackupCodec.decode`), en este orden

1. No empieza por `1f 8b` → `NotACuadranteFile`.
2. Descomprime. Flujo roto, cortado o con el CRC-32 o la longitud del final (*trailer*) que no cuadran →
   `CorruptBackup`. (El descompresor de `dart:io` entrega en silencio el trozo leído de un archivo cortado, por eso se
   comprueban a mano.)
3. El resultado no es JSON, o no es un objeto con `format == "cuadrante"` → `NotACuadranteFile`.
4. `schemaVersion` no es un entero ≥ 1 → `CorruptBackup`. **Mayor que la soportada → `NewerFormatVersion(found,
   supported)`** (R6), **antes de mirar nada más**: un archivo futuro puede tener otra forma de `data` y otra suma.
5. La suma de control no coincide con la recalculada sobre el JSON leído → `CorruptBackup` (R7). Se calcula sobre lo
   leído, así que un campo desconocido también queda protegido.
6. Tipos incorrectos o campos que faltan → `CorruptBackup`.
7. Integridad (`BackupData.validate`): ids (no vacíos), `seq` y fechas (por calendario) únicos; **al menos un
   calendario no archivado, sin ids repetidos, con nombre y color válido; cada rotación y cada día apuntan a un
   calendario que existe**; cada rotación apunta a un patrón que existe; fin ≥ inicio; los dos minutos o ninguno, entre 0 y 1439; patrones con al menos un paso; ámbito de festivo
   válido; **(v3) recordatorio entre 0 y 1439, horas extra y salida anticipada entre 0 y 1440, precio por hora entre 0 y
   999 999 céntimos, sonido de alarma no
   vacío (≤ 512) y segundo tramo completo, en rango, después del primero y dentro de 24 h**; y **un solo festivo propio por fecha** (como `addUserHoliday`: la tabla no tiene restricción única, y dos en
   la misma fecha rompían la lista de Ajustes › Festivos; el archivo se rechaza como `CorruptBackup`); y lo que exige el motor: código de turno de 1 a 3 caracteres, nombres no vacíos (el del festivo, no en
   blanco) y `colorValue` entre 0 y 0xFFFFFFFF. Es lo que haría cumplir la base de datos y el motor, comprobado
   **antes** de escribir (así `verifyRestore` y `restore` aceptan y rechazan lo mismo). Las referencias a tipos de turno desde
   pasos de patrón y días **no** se exigen: el motor ignora los ids que no existen y una base de datos legítima puede
   tenerlos; rechazarlos haría irrestaurable una copia buena.

Cualquier otro fallo (incluso un desbordamiento de pila con un JSON absurdo) sale como `CorruptBackup`. De `decode`
no sale nada que no sea un `BackupException`.

### Código de turno: se cuenta en unidades UTF-16

El «1 a 3 caracteres» del código de turno son **unidades UTF-16** (`String.length`), que es lo que cuenta el motor
(`ShiftType`) y lo que comprueba `validate`. Dos emojis son 4 unidades y no caben, aunque parezcan dos caracteres.
Por eso el formulario de tipos de turno solo deja escribir letras, cifras y símbolos simples (`+ / - . * #`), sin
emojis ni espacios, y corta a 3 unidades (`ShiftCodeFormatter`, `sanitizeShiftCode`); además
`ShiftTypeDraft.validate` devuelve `codeTooLong` si el código recortado pasa de 3 unidades.

**Reparación de una sola vez al arrancar** (`ScheduleRepository.repairShiftTypeCodes`, llamada desde `bootstrapApp`
antes de leer nada): una versión anterior dejó guardar códigos más largos (p. ej. «🙂🙂») y, con una sola fila así,
la copia de seguridad, la copia previa a restaurar y la carga en modo depuración fallaban para siempre. Al arrancar,
todo código vacío o de más de 3 unidades se recorta a sus primeros caracteres enteros que quepan en 3 unidades (nunca
parte un par subrogado: «🙂🙂» queda «🙂», «ABCDE» queda «ABC») o, si no cabe ninguno o estaba vacío, pasa a «?».
Se escribe una línea en el registro de depuración por cada fila y no se toca nada más (ni `updated_at`). Es
idempotente y nunca bloquea el arranque: si falla, se registra y la app sigue. Prueba:
`test/features/schedule/data/shift_code_repair_test.dart`.

## 2. Versiones: reglas que no se rompen

`schemaVersion` cuenta cambios **incompatibles** del formato. Dentro de una misma versión se puede:

- **Añadir** campos opcionales o claves nuevas en `data` y en el sobre. Quien lee ignora lo que no conoce; la suma de
  control sigue cubriéndolo. No hace falta subir la versión.

Se sube la versión (v3, v4…) si hay que **quitar, renombrar o cambiar el significado** de algo, cambiar el cálculo de
la suma, o hacer imprescindible un campo nuevo. La versión 2 (release 0.3.0) lo hizo porque `calendarId` es
imprescindible en rotaciones y días: añadió `calendars`, `calendarId` y `hourlyRateCents`. La versión 3 (release 0.6.0)
lo hizo sin que los campos fueran imprescindibles, **para que una app que solo conoce la 2 rechace el archivo en vez
de perder datos en silencio** (apartado 1, «Por qué se sube la versión»). Entonces:

1. **Todo lector nuevo sigue leyendo todas las versiones anteriores.** `BackupCodec.decode` despacha por
   `schemaVersion` (`_decodeV1`, `_decodeV2`…); cada lector conserva su forma de leer y **no se edita** cuando sale el
   siguiente. Un lector v2 convierte lo leído de un v1 a su modelo (campos que faltan con su valor por defecto), nunca
   pide al usuario que «vuelva a exportar».
   - **Leer un v1 (`_decodeV1`):** la suma de control se comprueba sobre el archivo tal como se escribió; los datos
     pasan al modelo v2 con **todo en el calendario `main`** («Mi cuadrante», índigo, orden 0, `createdAt` y
     `updatedAt` = la hora de exportación del archivo, para que leerlo dos veces dé lo mismo), todas las rotaciones y
     días con `calendarId = 'main'` y ningún tipo con precio. `calendars`, `calendarId` y `hourlyRateCents` que
     aparecieran en un archivo v1 se ignoran (v1 no los define). Sin `calendars.active` ni `calendars.primary`: valen
     `main`. Restaurar un v1 deja la base de datos exactamente como lo dejaba antes (mismos días, mismas tablas) más
     el calendario `main`.
   - **Leer un v2 (`_decodeV2`, `BackupData.fromJsonV2`):** todo lo anterior viene en el archivo; `hourlyRateCents` es
     opcional (falta = sin precio). No define ningún campo de la v3: `icon`, `alarmSound`, `segment2*`,
     `noteReminderMinute`, `overtimeMinutes` y `earlyLeaveMinutes` salen `null` aunque el archivo los trajera (la
     suma de control ya cubrió el archivo tal como se escribió). Restaurar un v2 deja la base de datos como la
     dejaba antes, con las columnas nuevas vacías.
   - **Leer un v3 (`_decodeV3`, `BackupData.fromJson`):** lo de la v2 más los campos de la v3, todos opcionales
     (clave ausente = `null`).
2. El escritor escribe solo la versión más reciente (`supportedSchemaVersion` = 3). Nada vuelve a escribir un v1 ni
   un v2. (Las pruebas reconstruyen esas formas a mano: `test/features/backup/v1_format.dart` y `v2_format.dart`.)
3. Una app vieja ante un archivo de **versión de formato superior** dice que el archivo viene de una versión más reciente (`NewerFormatVersion`) y
   no toca nada. La pantalla debe proponer actualizar la app.
4. El archivo de referencia `app/test/fixtures/golden_backup/golden_v1.cuadrante` se queda para siempre y se añade
   uno por versión (`golden_v2.cuadrante`, `golden_v3.cuadrante`, y así). Su prueba exige: se lee, la suma de control es la anotada, los
   bytes del JSON canónico son los mismos y los 730 días resueltos dan la misma huella. Si esa prueba falla, se ha
   roto la compatibilidad: **se arregla el código, no el archivo**. Los archivos dorados de versiones anteriores
   **no se regeneran nunca**.
5. Un cambio de esquema de Drift (`docs/datos.md`, «Migraciones») no implica cambio de formato si los datos que
   viajan son los mismos; si añade una tabla o columna del usuario, se añade a `data` como campo opcional (misma
   versión) y se documenta aquí.

## 3. Restaurar

`BackupRepository` (sobre `AppDatabase`):

- `readAll()`: todas las tablas del usuario en **una** transacción de lectura.
- `preview(data)`: recuentos de lo que llega y de lo que hay, y el rango de fechas (días con excepción y
  rotaciones; indica si hay una rotación sin fecha de fin). No escribe.
- `restore(data)`: **reemplaza** todas las tablas del usuario, calendarios incluidos (primero se borran rotaciones y
  días, luego los calendarios; al insertar, los calendarios van antes), en **una** transacción (todo o nada). Los
  ajustes `calendars.active` y `calendars.primary` viajan en `settings`, así que lo que la copia traiga sustituye lo
  que hubiera (un v1 no los trae: vuelven a valer `main`). Antes escribe una
  exportación de seguridad de lo actual en `<Application Support>/backups/pre-restore-<fecha>.turnly` (UTC,
  `yyyyMMdd-HHmmss`, con `-2`, `-3`… si coinciden en el mismo segundo) y se queda con las 3 últimas. Si esa copia no
  se puede escribir, no se restaura. Un archivo o dato inconsistente se rechaza antes de escribir nada. Un fallo a
  mitad deja los datos como estaban.
- Tras restaurar hay que recargar el `Schedule` en memoria y volver a calcular el widget y las alarmas, y el orden
  importa: las pantallas llaman a `RestoreCoordinator.restoreAndReload` (`features/backup/application`), nunca a
  `BackupService.restore` solo. Hace el restore **dentro de la cola de escrituras** de `ScheduleController`
  (`runExclusive`: primero se escribe lo ya encolado, y lo que se encole mientras tanto se descarta), después
  `ScheduleController.reload()` (vacía deshacer/rehacer y el trazo abierto, y vuelve a elegir el calendario activo
  guardado: puede ser otro que antes de restaurar), y por último la lista de calendarios, festivos, ajustes y
  sincronización de alarmas (con el calendario primario) y del widget; al final se marca el primer uso como hecho y se vuelve a leer el aviso del mes.
- `verifyRestore(bytes, today:)`: «Probar restauración», ver abajo.

`BackupService` junta repositorio, códec y almacén: `exportBytes()` (para compartir), `backupNow()`,
`inspect(bytes)` (lee y resume, sin escribir; es lo que se hace al importar. **Decodifica en un isolate aparte**
—`BackupService(runner:)`, por defecto `Isolate.run`; las pruebas de pantalla inyectan `runOnThisIsolate`—, así que un
archivo hostil no bloquea la interfaz; solo el resumen contra la base de datos, que es barato, corre en el principal), `restore(pending)` y `verifyLatest()`.
El nombre de archivo que propone la interfaz al exportar es `turnly-AAAA-MM-DD-HHmmss.turnly` con la fecha y
hora **locales** (la hora hace único cada archivo: el borrado diferido de una exportación no puede alcanzar a una
posterior; `exportFileName`, en `application/backup_models.dart`; `BackupCodec.suggestedFileName` ya no se usa en la interfaz).

### La huella de la matriz (`scheduleFingerprint`)

`sha256` de: la ventana (`from`, `to`), el hash del JSON canónico de las entidades (calendarios y marcas de tiempo
incluidos) y, **para cada calendario** (también los archivados) y cada día de la ventana, lo que resuelve el motor
(`Schedule.resolveRange` sobre las rotaciones y días de ese calendario): fecha, origen (excepción, rotación o nada),
ids de turno en orden, rotación, paso del ciclo y nota (y, desde la v3, el recordatorio, las horas extra y la salida
anticipada del día **si los tiene**: un día sin ellos da la misma línea que siempre). Cualquier diferencia entre dos bases de datos, en un dato
guardado o en lo que se vería en el calendario de cualquiera de ellos, cambia la huella. (En la versión 1 de la app
la huella era la de un solo calendario; `golden_v1.expected.json` conserva ese resumen y su prueba lo recalcula con
la forma v1, véase abajo.) La ventana estándar son **730 días**: un año
antes de hoy y el resto hacia delante (`defaultFingerprintWindow`). Con huella distinta, `firstDayDifferingFrom` da el
primer día que no coincide.

### «Probar restauración» (`verifyRestore`)

Restauración en seco, sin tocar los datos del usuario ni la carpeta de copias de seguridad:

1. Lee el archivo (`VerificationFailed` con el `BackupException` si no se puede).
2. Reconstruye los datos en una base de datos en memoria con **el mismo código que `restore`** y los vuelve a leer.
3. Compara la huella del archivo con la de la reconstrucción. Distinta → `VerificationMismatch` (fallo real de la
   restauración) con el primer día distinto (o ninguno si solo difieren datos guardados).
4. Igual → `VerificationPassed`, que además dice si coincide con los datos actuales (`matchesLive`). Una copia buena y
   más vieja que lo último que se ha editado da `matchesLive = false` y `firstDayDifferingFromLive`: es lo esperable,
   no un error.

## 4. Dónde se guarda: `BackupStore`

`domain/backup_store.dart` define el contrato; los bytes son siempre un `.turnly` hecho por `BackupCodec`, el
almacén solo los guarda:

```dart
abstract interface class BackupStore {
  Future<BackupEntry> save(Uint8List bytes, {required DateTime at});
  Future<BackupEntry?> latest();
  Future<List<BackupEntry>> list();       // la más nueva primero
  Future<Uint8List> read(BackupEntry entry);
}
```

`save` tira la copia más antigua que el almacén no conserve y **lanza** si no pudo guardar (una copia fallida no puede
parecer buena: la interfaz muestra el error y la fecha de la última buena, R8). `BackupEntry` lleva `id` (opaco),
`modifiedAt` (UTC) y `sizeBytes`.

- **Ahora (Android y pruebas): `LocalFileBackupStore(directory, {keep = 5, prefix = 'turnly', retain})`**, una carpeta
  con `<prefijo>-<fecha>.turnly`. Las copias antiguas `cuadrante-<fecha>.cuadrante` siguen en el almacén
  automático, y `pre-restore-<fecha>.cuadrante` en el de seguridad: dentro de cada almacén se ordenan junto a las
  nuevas por fecha y contador, y comparten la misma poda. El contador de un archivo nuevo sigue al mayor de ambos
  nombres en ese segundo. Escritura atómica (archivo temporal + renombrar), sin pisar dos copias del mismo segundo,
  ignora lo que no es suyo y solo lee (y borra) nombres que son suyos. Con `retain` (la política del apartado
  8) en lugar de `keep`; la copia recién guardada nunca se borra y un archivo que no se puede borrar se deja para la
  próxima vez en vez de hacer fallar el guardado. Dos almacenes sobre la misma carpeta no se ven: `turnly` (copias
  de la app) y `pre-restore` (copias previas a restaurar, que escribe `BackupRepository.restore`).
- **iOS: `ICloudBackupStore`** (`data/icloud_backup_store.dart`), que implementa la misma interfaz llamando por un
  `MethodChannel` al código Swift (~150 líneas, ver `turnos-spec.md` §6) que escribe en el contenedor de iCloud de
  la app. **El Dart está hecho y probado con un canal falso** (`icloud_backup_store_test.dart`); el Swift se escribe
  en el Mac con el contrato de abajo («Copia en iCloud»). Los errores de iCloud desactivado o lleno (R8) llegan
  como excepciones tipadas (`domain/icloud_errors.dart`). Nada más cambia: el códec, `BackupService` y las pantallas
  ya trabajan contra `BackupStore`.
- **Dónde va iCloud (y dónde no).** La copia de la app **siempre se hace primero en el móvil** (`autoStore`,
  `LocalFileBackupStore`). En iOS, y **solo con la réplica encendida (abajo)**, `BackupTools.backupAndVerify` replica
  en iCloud cada copia local que ya ha pasado la verificación, con el mismo nombre y la misma política de retención
  (`iCloudBackupStoreProvider`; en Android el proveedor es `null`). Si iCloud falla (apagado, lleno, lento, o aún sin Swift) **la copia no falla**:
  el motivo queda en `BackupTools.cloudError` para que Ajustes lo enseñe junto a la fecha de la última copia buena
  (R8). Las copias previas a restaurar (`pre-restore`) **no** van a iCloud. `BackupTools.cloudCopies()` y
  `readCloud()` son el gancho para «Restaurar desde iCloud» (R1: iPhone nuevo, app recién instalada, sin copias
  locales); **la pantalla que lo enseña (y el interruptor propio de iCloud) falta y es trabajo del bloque del Mac**,
  con la decisión de la pregunta 13 (la baja médica viajaría en esta copia). Ojo con R1: con el interruptor apagado
  (el valor de un iPhone nuevo) el proveedor no da almacén y `cloudCopies()` sale vacío; la pantalla «Restaurar desde
  iCloud» necesitará un almacén **solo de lectura** que no dependa del interruptor (leer no envía nada).
- **La réplica en iCloud está apagada por defecto (revisión de seguridad H1).** Dos cierres, y los dos tienen que estar
  abiertos para que una copia salga del móvil:
  1. `kICloudReplica` (`backup_providers.dart`), una constante del código, hoy `false`: con ella apagada
     `iCloudBackupStoreProvider` da `null` **diga lo que diga el interruptor**, así que registrar el canal de Swift
     no activa nada. Pasa a `true` solo cuando se responda la pregunta 13 de `docs/preguntas.md`; si la respuesta es la
     opción (a), los bytes que se repliquen deben ser un recodificado de `BackupData` **sin las ausencias de salud**
     (otro fichero), nunca los bytes de la copia local.
  2. El interruptor «Copia en iCloud» de Ajustes (`BackupSettingsRepository.loadCloud()` / `saveCloud()`, clave
     `backup.cloud`, **apagado por defecto**; solo un `true` explícito lo enciende). Es un ajuste **del dispositivo**
     (`isDeviceSetting`): no entra en ningún `.turnly`, un archivo importado no lo puede encender ni apagar y una
     restauración lo deja como está. `BackupTools._mirrorToCloud` lo vuelve a leer **antes de cada copia**: apagarlo
     detiene la siguiente de inmediato (y un valor ilegible cuenta como apagado).

  La réplica en iCloud está apagada por defecto y solo se activa con el interruptor «Copia en iCloud» de Ajustes, cuyo texto dice que la copia va a iCloud Drive (carpeta Turnly, visible en Archivos y en todos los dispositivos de tu Apple ID), que incluye todos los turnos y ausencias (bajas incluidas), y que no está cifrada de extremo a extremo salvo que tengas Protección de datos avanzada. Registrar el canal de Swift no la activa; además `kICloudReplica` debe pasar a true solo cuando se responda la pregunta 13.

  **Interruptor «Copia en iCloud» (pendiente: sin pantalla todavía).** Debe vivir en Ajustes › Copia de seguridad,
  apagado de fábrica, y su texto debe decir, sin suavizar, lo de arriba: que la copia va a iCloud Drive (carpeta
  Turnly, visible en Archivos y en todos los dispositivos de tu Apple ID), que incluye todos los turnos y ausencias
  (bajas incluidas) y que no está cifrada de extremo a extremo salvo que tengas Protección de datos avanzada. Textos por
  ARB; se hace con el diseño cerrado y el provider ya existe: `cloudBackupEnabledProvider`.
- Auto Backup de Android (A1–A4) copia la base de datos del sistema y es independiente de esto; el `.turnly` es el
  seguro adicional y lo que viaja entre plataformas.

### Copia en iCloud: contrato del canal `app.cuadrante/icloud`

Lo que `ICloudBackupStore` espera del Swift (`AppDelegate.didInitializeImplicitFlutterEngine`, patrón
`registerPathsChannel` de Mochila). Todo en **la carpeta `Documents/` del contenedor ubicuo**
`iCloud.es.cuadrante.app` (`FileManager.default.url(forUbiquityContainerIdentifier: nil)`), que es la que
aparece en Archivos › iCloud Drive › Turnly cuando `Info.plist` declara `NSUbiquitousContainers`.

| Método | Argumentos | Respuesta |
|---|---|---|
| `status` | — | `{available: bool, reason: String?}`. `available` = `ubiquityIdentityToken != nil` **y** el contenedor existe. `reason` si no: `signed_out` (sin sesión de iCloud), `disabled` (iCloud Drive apagado para la app), `no_container`. **Nunca lanza**: responde `available: false` |
| `list` | — | `[{id, name, sizeBytes, modifiedAtMs}]`, los ficheros normales de `Documents/`, **también los que aún no se han descargado** (un marcador `.nombre.icloud` se cuenta con su nombre real). `id == name` (el nombre del fichero). El Dart descarta lo que no case con `turnly-yyyyMMdd-HHmmss[-n].turnly` o el nombre antiguo `cuadrante-yyyyMMdd-HHmmss[-n].cuadrante` y **toma la fecha del nombre**, no de `modifiedAtMs` (que es solo informativo) |
| `save` | `{name: String, bytes: Uint8List}` | `{id, name, sizeBytes, modifiedAtMs}`. Crea `Documents/` si falta y escribe con `NSFileCoordinator` (`.forReplacing`) **de forma atómica** (fichero temporal en el contenedor y `replaceItemAt`). El Dart ya ha elegido un nombre libre (añade `-2`, `-3`... si hay otra copia del mismo segundo); si aun así existe, se sustituye. Hasta 8 MB (`BackupCodec.maxFileBytes`) |
| `read` | `{id: String}` | `bytes` (`FlutterStandardTypedData`). Antes de descargar o leer, comprobar el tamaño; si pasa de 8 MB responder `too_large` sin descargar. `sizeBytes` de `list` es el tamaño real también para ficheros no descargados. Si el fichero está en la nube, `startDownloadingUbiquitousItem` y espera a que esté `current`, con **plazo de 60 s** (`icloud_timeout`) |
| `delete` | `{id: String}` | `null`. Coordinado (`.forDeleting`). Un fichero que ya no está cuenta como borrado |

- **Errores** (`FlutterError(code:)`, que llega como `PlatformException.code`): `icloud_unavailable` (en `list`,
  `save`, `read` y `delete` cuando `status` diría que no), `icloud_full` (sin espacio: `NSFileWriteOutOfSpaceError`),
  `icloud_timeout`, `too_large` (`read` de un fichero de más de 8 MB, sin descargarlo; el Dart lo tipa como
  `ICloudFailed('read: too large')`, y además lo comprueba él antes de llamar, con el `sizeBytes` del listado, y después,
  con los bytes recibidos). Cualquier otro código se trata como fallo genérico (`ICloudFailed`). `id` con `/` o `..`:
  código `bad_id`. El Dart también lo comprueba, pero el Swift **no se fía** (como el Kotlin no se fía de la URI).
- **Restaurar desde iCloud (M3):** trata cada fichero como un archivo externo: `BackupCodec.decode` en un isolate, vista previa con origen propio («Copia en iCloud», `BackupImportOrigin.cloudCopy`, `BackupActions.requestForCloud`), copia previa `pre-restore` y confirmación del usuario; nunca `restore` directo. La fecha que enseña sale del nombre y puede ser falsa. (Los nombres con una fecha imposible o a más de un día en el futuro ya los descarta `ICloudBackupStore`.)
- **Hilos:** las llamadas de iCloud bloquean; todas fuera del hilo principal y la respuesta de vuelta a él.
- **Plazo del lado Dart:** 2 minutos por llamada (`callTimeout`), por si el Swift no contesta; sale como
  `ICloudTimeout`.
- **Qué hace el Dart sin el Swift** (Android, iOS antes de escribirlo, pruebas): `MissingPluginException` →
  «iCloud no disponible». `status`/`isAvailable()` dan `false`, `list()` da `[]`, `latest()` da `null`, y
  `save`/`read`/`delete` lanzan `ICloudUnavailable` (texto `iCloud no disponible`). Nunca una excepción sin tipar ni
  un cierre. `BackupTools.backupAndVerify` lo recoge y la copia local queda hecha.
- **Retención:** la misma que la local (`BackupRetention`: las 7 últimas más la última de cada día de 30 días); la
  copia recién guardada y la más nueva nunca se borran; un fichero que no se puede borrar se deja para la próxima.
  Un fichero ajeno de la carpeta (el usuario la ve en Archivos) **no se lee ni se borra**.
- **Pruebas en el Mac:** matriz R1, R3, R8 de `docs/mac-ios.md` §5.2. Una vez escrita la copia, mira en Archivos ›
  iCloud Drive › Turnly.

## 5. Archivo de referencia (golden)

`app/test/fixtures/golden_backup/`:

- `golden_v1.cuadrante`: la copia de referencia de la matriz (2 años, 3 rotaciones con una recortada, 40
  excepciones, días con dos turnos, un turno que cruza la medianoche, tipos propios con uno archivado, notas largas
  con emojis y saltos de línea, municipio, alarmas en los ajustes y un festivo propio).
- `golden_v1.expected.json`: versión, suma de control, huella de los 730 días y recuentos esperados. **Congelado**:
  el escritor v1 ya no existe en la app, así que no se puede regenerar, y no hace falta. Su prueba
  (`golden_fixture_test.dart`) lee el archivo con el lector actual, comprueba que todo está en `main`, y vuelve a
  escribir los datos con la forma v1 (`test/features/backup/v1_format.dart`: quita `calendars`, `calendarId` y
  `hourlyRateCents`) para comprobar la suma de control, los bytes canónicos y el resumen de la huella (formulado
  como lo era en v1) contra lo anotado en 0.2.0, y que restaura exactamente.
- El generador es `test/features/backup/golden_dataset.dart` (`buildGoldenBackupData()`), sin reloj ni azar.
- `golden_v2.cuadrante` + `golden_v2.expected.json` (release 0.3.0): los datos de v1 más un segundo calendario
  «Pareja» con rotaciones y días propios (el primer día cae en una fecha en que `main` también tiene excepción),
  un tercero archivado que conserva una rotación, precio por hora en tres tipos y los ajustes `calendars.active` /
  `calendars.primary`. Generador: `test/features/backup/golden_dataset_v2.dart` (`buildGoldenBackupDataV2()`).
  Regenerar (solo si se versiona el formato a propósito, nunca para que pase una prueba):
  `flutter test test/features/backup/golden_v2_fixture_test.dart --dart-define=REGENERATE_GOLDEN=true`.
  **Congelado desde la 0.6.0**: el escritor v2 ya no existe; su prueba reescribe los datos con la forma v2
  (`test/features/backup/v2_format.dart`) para comprobar los bytes canónicos y la suma de control, y comprueba que el
  escritor actual da el mismo JSON de `data`.
- `golden_v3.cuadrante` + `golden_v3.expected.json` (release 0.6.0): los datos de v2 más iconos en tres tipos y un
  sonido de alarma, un turno partido con segundo tramo y siete días con recordatorio, horas extra o salida
  anticipada (cuatro de ellos con solo eso, sin turno ni nota, y la misma fecha con valores distintos en dos
  calendarios). Generador: `test/features/backup/golden_dataset_v3.dart` (`buildGoldenBackupDataV3()`). Regenerar
  (solo si se versiona el formato a propósito):
  `flutter test test/features/backup/golden_v3_fixture_test.dart --dart-define=REGENERATE_GOLDEN=true`.

El estado de pago no es un dato de la base de datos y queda fuera del conjunto (no hay compras: R9 sale de la
matriz); las alarmas configuradas están representadas por su clave en `settings`.

## 6. Pruebas

`flutter test test/features/backup`: formato y JSON canónico (bytes estables, independientes del orden de entrada),
R6 (versión nueva, base intacta), R7 (cortado en muchos puntos, bits alterados, basura, vacío, datos editados a mano,
bytes añadidos, bomba de descompresión; base intacta y sin copia de seguridad previa), integridad referencial,
ida y vuelta base de datos → archivo → base de datos nueva (huella, contenido de todas las tablas y mismos bytes al
volver a exportar), atomicidad (fallo a mitad de restauración con un *trigger*, base intacta), copia previa a
restaurar (contenido, poda a 3, mismo segundo, sin copia no hay restauración), «Probar restauración» (correcta,
más antigua que lo actual, reconstrucción defectuosa con el primer día distinto, archivos inservibles), almacén local
y servicio, y los archivos de referencia v1 y v2.

Versión 2 (`backup_v2_test.dart`, y los grupos «version 1 files» y «calendars (version 2)» de `backup_codec_test.dart`):
un v1 se lee entero en `main` y se vuelve a exportar como v2; `calendars` / `calendarId` / `hourlyRateCents` dentro de un
v1 se ignoran; rotaciones o días con calendario ausente, sin calendarios o con todos archivados son archivo
dañado; ida y vuelta con varios calendarios (archivado incluido, la misma fecha en dos calendarios, precios);
restaurar un v1 sobre una base con varios calendarios deja solo `main`; ajustes que apuntan a un calendario que
no existe se resuelven a `main`; la huella cambia con cualquier día de cualquier calendario; la copia previa guarda
todos los calendarios.

Versión 3 (`backup_v3_test.dart` y `golden_v3_fixture_test.dart`): el escritor dice versión 3 con el mismo sobre y
las claves nuevas solo si hay valor; los datos que nunca las usaron dan el mismo JSON, suma y huella que en v2; un v3
sin las claves nuevas, con `null`, o con un icono desconocido se lee sin error (sin icono); un v2 que trajera claves
v3 las ignora; restaurar un v2 vacía las columnas nuevas; validación (recordatorio fuera del día, minutos negativos,
sonido vacío o larguísimo, segundo tramo incompleto, fuera de rango, que empieza antes de acabar el primero o que no
cabe en 24 h, tipo sin horas); ida y vuelta base de datos → archivo → base de datos con todos los campos (tablas,
huella, volver a exportar da lo mismo); la copia previa a restaurar los guarda; **«Probar restauración» pasa y detecta**
una reconstrucción que pierde horas extra (con el día), el recordatorio de un día que solo tiene eso, el segundo tramo
o el icono; la huella cambia con cualquiera de los campos nuevos de cualquier día de cualquier calendario y da el
primer día que difiere; los límites (8 MB, 4 MB, ratio 100) no cambian. Un archivo v3 en una app que solo conoce la
v2 lo rechaza el control de siempre (`NewerFormatVersion`, R6: `backup_codec_test.dart`, `backup_service_test.dart`,
`backup_restore_ui_test.dart`, ahora con una versión 4 como «la más nueva»).

Pantallas (`test/features/backup/`): `backup_status_test.dart` (la tarjeta de estado: sin copia, copia reciente,
copia de ayer, copia automática fallida con y sin última copia buena, línea de la copia del sistema),
`backup_restore_ui_test.dart` (vista previa, confirmar, bloqueo mientras restaura, resultado, copia previa listada y
restaurable, «Volver a como estaba», archivo recibido de otra app, y R6/R7: versión nueva, cortado, un byte cambiado, no
es un archivo nuestro y vacío, sin tocar los datos ni crear copia previa), `backup_actions_ui_test.dart` (exportar,
«Probar restauración» en sus cuatro resultados, copia automática tras un cambio, ráfaga, interruptor),
`auto_backup_policy_test.dart`, `auto_backup_runner_test.dart` (retraso, ráfagas, separación de 15 min, fallos y
reintento, con reloj y temporizador falsos), `backup_retention_test.dart` y `local_file_backup_store_retention_test.dart`
(las 7 más nuevas + una por día durante 30), `backup_tools_test.dart` (una copia que no se lee de vuelta se borra y se
da por fallida). Escenarios del emulador Q65–Q69 en `integration_test/scenarios/backup_ui.dart`.

Seguridad de la importación (`backup_inspect_isolate_test.dart`, `backup_host_test.dart`,
`backup_restore_safety_test.dart`, `export_cache_test.dart`, `platform_backup_channel_test.dart`, y en Kotlin
`FileReadingTest` / `LaunchPolicyTest`): una bomba de descompresión (unos KB de gzip, ~16 MB de JSON) se rechaza al
instante y por el ratio, `inspect` decodifica en otro isolate (se comprueba con el puerto de control del isolate), la
vista previa se abre con el cargador mientras la lectura sigue y se puede salir, nunca hay dos vistas previas aunque
lleguen archivos en ráfaga, un archivo recibido durante una restauración se descarta, el remitente y lo que el archivo
apaga se muestran, la protección contra *tapjacking* se activa y desactiva con la pantalla, la carpeta de exportación se
vacía, y en Kotlin un flujo colgado acaba como `unreadable` al plazo sin bloquear el siguiente archivo.

## 7. Pantallas

**Ajustes › Copia de seguridad** (`/ajustes/copia`, `BackupScreen`). De arriba abajo:

- **Tarjeta de estado.** «Última copia: hoy a las 18:20 · En este móvil» (fecha del almacén, no del reloj de la
  sesión). Sin ninguna copia: «Todavía no hay ninguna copia» y qué se pierde si el móvil se pierde. Siempre, la
  advertencia honesta: *«Estas copias se guardan en tu móvil. Si desinstalas la app sin otra copia, se pierde.»* y
  cómo tener otra (exportar el archivo a Drive, WhatsApp o correo). En Android, una línea con el estado de la copia
  del sistema (activada, desactivada o «no podemos comprobarla desde la app»: ver apartado 10; nunca se afirma lo que
  no se sabe).
- **Copia automática fallida.** Un aviso rojo aparte: «La última copia automática ha fallado», cuándo se intentó, la
  fecha de la última copia **buena** (o que no hay ninguna) y el motivo (sin espacio, o genérico), con «Reintentar».
  El fallo se anota en la sesión (no se guarda en la base de datos) y se manda a `CrashReporter` (solo el tipo y la
  traza, como todo lo demás). Una copia posterior buena lo quita.
- **Hacer copia ahora.** Copia en el momento, sin esperar a la política (cuenta como intento para la separación de 15
  min). Si falla, lo dice y muestra el aviso anterior.
- **Copias automáticas** (interruptor, **activado por defecto**; se guarda en `settings` como `backup.auto`; si
  falta o no se entiende, vale «activado»). Desactivarlas no borra nada. Activarlas pide una copia pronto.
- **Exportar archivo.** Genera el `.turnly` de lo que hay ahora, lo **lee de vuelta** (`BackupCodec.decode`) antes
  de entregarlo —un archivo que no se puede volver a leer no sale— y abre la hoja de compartir del sistema
  (`share_plus`: WhatsApp, Drive, correo) con el nombre `turnly-AAAA-MM-DD-HHmmss.turnly`. El archivo temporal va a la
  caché, que la copia del sistema no incluye. Va a `<caché>/export/` (`ExportCache`): antes de cada exportación se
  vacía esa carpeta, el archivo se borra a los 2 minutos de que la hoja de compartir haya vuelto (la app receptora puede
  seguir leyéndolo un momento) y al arrancar se vacía (`BackupHost`), así que no quedan copias de todo el cuadrante en
  la caché.
- **Guardar en el móvil** (solo Android; H-T13-3). Mismo archivo que «Exportar archivo» (mismos bytes, mismo
  nombre, leído de vuelta antes de salir), pero lo escribe donde el usuario elija en el diálogo de guardar del sistema
  (`ACTION_CREATE_DOCUMENT`, Storage Access Framework: Descargas, una tarjeta, una app en la nube), sin pedir ningún
  permiso de almacenamiento. `file_selector` no ofrece `getSaveLocation` en Android ni en iOS, así que va por el canal
  `app.cuadrante/backup`, método `saveDocument({fileName, bytes})` (`DocumentSaver.kt`): responde `saved`,
  `cancelled` (cerrar el diálogo no hace nada) o un `PlatformException` (`busy`, `unavailable`, `unwritable`), que la
  pantalla cuenta con «No se ha podido guardar el archivo…». Tipo MIME `application/octet-stream`. En iOS el botón no
  se muestra (`backupSaveSupportedProvider`): la hoja de compartir ya ofrece «Guardar en Archivos»; ver
  `docs/mac-ios.md`, 4.3.
- **Importar archivo.** Selector de archivos (`file_selector`; en Android sin filtro de tipo, porque las extensiones
  `.turnly` y `.cuadrante` no tienen tipo MIME y un filtro podría esconder justo el archivo; el contenido se valida
  igual). Un archivo de más de 8 MB se rechaza sin leerlo entero. En escritorio el filtro «Turnly» acepta ambas extensiones;
  en iOS se mantiene `public.data` para que también se puedan seleccionar los archivos antiguos.
- **Probar restauración.** `BackupService.verifyLatest` sobre la copia más nueva de la app. Resultados:
  «La copia está completa: 730 días comprobados» (y si es idéntica a lo que hay ahora, o anterior —con el primer día que
  cambia—, que es normal si se ha editado después), «La copia no se reconstruye igual. Primer día distinto: …» (un fallo
  real de la restauración), «No se ha podido probar la copia. …» (archivo ilegible) o «Todavía no hay ninguna copia que
  probar».
- **Copias en este móvil.** Las automáticas (y las de «Hacer copia ahora») y las **copias previas a restaurar**
  (`pre-restore-*`), la más nueva primero, con su fecha, tipo, **versión de la app que la escribió** y tamaño
  («Copia del móvil · 0.5.0 · 2 KB») y el botón **Restaurar esta**, que sigue el mismo
  camino que importar un archivo. Así una restauración equivocada se deshace. La versión sale de `appVersion`, que
  va el primero del sobre canónico: `BackupCodec.peekAppVersion` infla solo los primeros 512 bytes del archivo, sin
  decodificarlo ni validarlo (informativo: nada se decide con ella), y `BackupTools` la guarda en memoria por
  archivo, así que cada copia se lee una vez. Si no se puede leer, la copia sale sin versión. «Restaurar esta» va
  en la misma fila, como acción final alineada con el chevron de las demás filas; si no cabe junto al texto
  (texto grande o móvil estrecho), todas las filas lo ponen debajo, con su texto en la x del título
  (`BackupCopyList`).

**Vista previa** (`/ajustes/copia/importar`, `RestorePreviewScreen`; se le pasa un `BackupImportRequest` como `extra`,
sin él vuelve a la pantalla de copias). Siempre pasa por aquí un archivo elegido, uno recibido de otra app o una copia de
la lista:

1. *Leyendo el archivo…* (`BackupService.inspect`: no escribe nada). La pantalla se abre **al instante**, con el
   cargador y con «Atrás» disponible mientras el móvil entrega los bytes (un archivo de Drive puede tardar o no
   llegar nunca). Nunca hay dos vistas previas: si llega otro archivo con una abierta, la sustituye
   (`pushReplacement`); si ya se está restaurando, el archivo nuevo se descarta (`discardPending`).
2. Si el archivo no sirve, **se queda aquí** con el mensaje y «No hemos cambiado nada: tus datos siguen como estaban.»,
   sin botón de confirmar, sin copia previa y sin tocar la base de datos:

   | Error | Mensaje |
   |---|---|
   | `NewerFormatVersion` (R6) | «Este archivo es de una versión más nueva de Turnly: actualiza la app.» |
   | `CorruptBackup` (R7) | «El archivo está dañado o incompleto y no se puede usar.» |
   | `NotACuadranteFile` | «Este archivo no es una copia de Turnly.» |
   | más de 8 MB | «Este archivo es demasiado grande para ser una copia de Turnly.» |
   | no se pudo leer | «No se ha podido leer el archivo.» |

3. Si sirve: de dónde viene (y, si el móvil lo dice, **qué app lo ha enviado**: «Enviado desde WhatsApp
   (com.whatsapp)», orientativo, no prueba nada), cuándo se guardó, calendarios (los archivados al final y marcados), días con turno o nota
   puestos a mano, rotaciones, tipos de turno y rango de fechas, cada cifra con «Ahora: …» al lado, y la frase
   *«Esto sustituye lo que tienes ahora; antes guardamos una copia.»* con **Sustituir lo que tengo** y **Cancelar**.
   Si el archivo **apaga** las copias automáticas o las alarmas que ahora están encendidas
   (`RestoreSummary.turnsOffAutoBackup` / `turnsOffAlarms`, comparando los `settings` del archivo con los actuales), un
   aviso aparte lo dice antes de confirmar: un archivo recibido de fuera no puede quitar la red de seguridad en silencio.
   Mientras la vista previa está en pantalla, Android la protege del *tapjacking* (ver apartado 9).
4. Al confirmar: un velo que bloquea la pantalla (y el gesto de atrás) con «Restaurando tu cuadrante… No cierres la
   app.» mientras corre `RestoreCoordinator.restoreAndReload`. Es la única vía de restauración; las pantallas nunca
   llaman a `BackupService.restore` solas.
5. Resultado: *«Listo, tu cuadrante está restaurado»* con **Ver mi calendario** y **Volver a como estaba**
   (abre la vista previa de la copia previa que acaba de escribir la restauración; hay que confirmar otra vez). Si falla
   la restauración: «No se ha podido restaurar. Tus datos siguen como estaban.» (es todo o nada). Si los datos se
   reemplazaron pero las pantallas no se pudieron recargar (muy raro): «Hemos restaurado tus datos, pero la pantalla no
   se ha podido actualizar. Cierra Turnly y vuelve a abrirlo.»

La restauración vuelve a elegir el calendario que tenía la copia en pantalla (`calendars.active`), que puede ser otro
que antes. El interruptor de copias automáticas viaja en `settings`: restaurar un archivo que lo tenía desactivado lo
deja desactivado (un archivo sin esa clave lo deja activado).

## 8. Copias automáticas

`BackupHost` (envuelve la app en `app.dart`) mantiene vivo `autoBackupRunnerProvider`, que escucha los cambios de todas
las tablas del usuario (`AppDatabase.tableUpdates`: lo que escriba cualquier pantalla, también una restauración) y,
pasado el tiempo que marca `AutoBackupPolicy`, hace una copia con `BackupService.backupNow` en la carpeta
`<Application Support>/backups`. La lectura de la base sigue en su conexión; la serialización, suma de control,
compresión y validación de los bytes persistidos pasan por `BackupTaskRunner` (`Isolate.run` en la app).
Exportar, guardar en el móvil y crear/verificar la copia previa a restaurar usan el mismo aislamiento.
Solo se envían datos planos al isolate, nunca la base de datos ni los providers. La prueba
`backup_processing_isolate_test.dart` comprueba los puertos de control de las tres codificaciones y las dos
lecturas de copia automática y previa; las pruebas de pantalla pueden inyectar `runOnThisIsolate`.

| Regla | Valor |
|---|---|
| Retraso (*debounce*) | 10 s desde el **último** cambio de una ráfaga |
| Tope de espera | 2 min desde el **primer** cambio (quien nunca para de editar también tiene copia) |
| Separación | ≥ 15 min desde el intento anterior (con éxito o no); un intento «en el futuro» (reloj atrasado) se ignora |
| Fallo | se anota, se manda a `CrashReporter`, se reintenta a los 15 min mientras haya cambios sin copiar |
| Cambios durante una copia | forman una ráfaga nueva |
| Interruptor desactivado | no se programa nada; «Hacer copia ahora» sigue funcionando |
| Al activarlo | pide una copia pronto |

No se hace copia al arrancar si no ha habido cambios (los datos de demostración y la carga inicial no cuentan).

**Qué se conserva** (`BackupRetention`, una vez guardada la copia nueva **y comprobado que se lee de vuelta**: una copia mala no hace perder una buena): las **7 más nuevas** y, además, **la última copia de
cada día natural local** de los **últimos 30 días** (hoy y los 29 anteriores). Como máximo ~37 archivos. La copia
recién guardada nunca se borra aunque la política no la nombre. La política es pura: recibe «ahora» y las entradas.
Las copias previas a restaurar (`pre-restore-*`, las 3 últimas) y las copias previas a una migración (`pre-v*-a-v*.sqlite`,
las 3 últimas) tienen su propia poda y no se tocan.

**Cada copia se lee de vuelta** (`BackupTools.backupAndVerify`): si el archivo recién escrito no se puede decodificar,
se borra y la copia se da por fallida, y solo entonces se podan las viejas. Una copia mala nunca parece buena.

## 9. Abrir un `.turnly` desde otra app (Android)

`AndroidManifest.xml` declara en `MainActivity` (`launchMode="singleTask"`):

- `VIEW` + esquema `content` + MIME `application/octet-stream`, `application/gzip` o `application/x-gzip`
  (WhatsApp, Drive y los gestores mandan el archivo como binario opaco: el nombre no va en la URI);
- `VIEW` + esquema `content` + cualquier MIME (`*/*`) + `pathPattern` que acaba en `.turnly` o `.cuadrante` (hay una entrada por
  número de puntos de la ruta, porque `pathPattern` no tiene un «cualquier cosa» que incluya el punto);
- `SEND` (Compartir › Turnly) con los tres MIME de arriba. **No** `*/*`: Turnly no debe salir al compartir cada
  foto o texto.

**`singleTask`, no `singleTop`.** Con `singleTop` y `taskAffinity=""`, abrir un `.turnly` desde Archivos o
WhatsApp con Turnly en segundo plano arrancaba una **segunda** `MainActivity` (y un segundo motor de Flutter, con
dos conexiones a la misma base de datos). Con `singleTask` el sistema lleva la tarea existente al frente y entrega el
`Intent` a `onNewIntent`, que ya hacía `setIntent` y avisaba con `incomingAvailable` (`LaunchPolicy` no cambia).
Lo demás sigue entrando por el mismo sitio: los toques en el widget (`cuadrante://widget/day/<fecha>`, por
`HomeWidgetLaunchIntent`: el plugin `home_widget` los recibe en `onNewIntent` o en el arranque, igual que antes) y los
de las notificaciones de alarma (`flutter_local_notifications`, que lanza la actividad con su `Intent` de
lanzamiento). Se comprueba con `tool/qa/single_activity_check.sh` (`docs/qa.md`, «Una sola actividad»).

Sin categoría `BROWSABLE` (una web no puede lanzarlo) y con `flutter_deeplinking_enabled=false` (la URL de un `VIEW` no
se interpreta como ruta de la app). A cambio, Turnly aparece en «Abrir con» de cualquier binario genérico; el
archivo que no es nuestro acaba en «Este archivo no es una copia de Turnly» sin tocar nada.

**Cómo llega al Dart** (sin plugin extra): `MainActivity` registra el `MethodChannel` `app.cuadrante/backup`.

- Al llegar un `VIEW`/`SEND` (en el arranque o en `onNewIntent`) **solo recuerda la URI**; si la app ya estaba abierta
  avisa con `incomingAvailable`.
- `BackupHost` pregunta `hasPending` (instantáneo, no lee) al arrancar y cuando recibe el aviso y, si hay archivo,
  abre **de inmediato** `/ajustes/copia/importar`. Es la pantalla la que llama a `readPending`: Android lee la URI
  **una vez**, en un hilo propio por archivo, con `ContentResolver.openInputStream`, y devuelve
  `{bytes, sender}` o `{error: tooLarge | unreadable}`. `discardPending` olvida el archivo sin leerlo.
- **Plazo de 60 s** (`DeadlineReader`): pasado ese tiempo se cierra el flujo y se contesta `unreadable`, así que un
  proveedor colgado no deja la pantalla esperando para siempre, y como cada lectura tiene su hilo, un archivo atascado
  no frena el siguiente.
- **Intención de arranque que no se repite** (`LaunchPolicy`): no se recuerda el archivo si la actividad se recrea
  (`savedInstanceState != null`) o se reabre desde recientes (`FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY`); tras
  consumirlo se hace `setIntent(Intent(ACTION_MAIN))`, y en `onNewIntent` `setIntent(intent)`. Antes, un archivo ya
  tratado volvía a abrir la vista previa en cada rotación o reapertura.
- **Remitente** (`Activity.getReferrer()`): se quitan antes los extras `EXTRA_REFERRER*` (con los que un `Intent` puede
  decir que viene de otro) y se lee lo que registró el sistema. Se muestra «Etiqueta (paquete)» o solo el paquete (sin
  `QUERY_ALL_PACKAGES` casi nunca se puede resolver la etiqueta). Es **orientativo**: no autoriza nada.
- Dart abre `/ajustes/copia/importar` con esos bytes. **Nunca se restaura sin que el usuario confirme** en la vista
  previa.
- **Tapjacking.** Mientras la vista previa está abierta, Dart llama a `setPreviewProtection(true)` (y `false` al
  salir; con **cuenta de referencias**, `PreviewProtectionGuard`: cuando una vista previa sustituye a otra —un archivo
  nuevo, «Volver a como estaba»— la nueva se monta antes de que la vieja se desmonte, y sin la cuenta el `false` de la
  vieja apagaba la protección bajo la nueva; el canal solo oye `true` en la primera y `false` en la última): `MainActivity` pone `filterTouchesWhenObscured` en la vista raíz (se descartan los toques que llegan con la
  ventana tapada por la de otra app, en todas las versiones) y, en Android 12+, `Window.setHideOverlayWindows(true)`
  (permiso normal `HIDE_OVERLAY_WINDOWS` en el manifest). Solo mientras dura la vista previa: dejarlo siempre
  encendido rompería filtros de pantalla y burbujas de otras apps.

**Límites de seguridad**: solo `content://` (un `file://` dejaría que otra app nos apunte a nuestros archivos privados);
lectura con el permiso temporal que concede el que envía, en trozos de 64 KB y **tope de 8 MB** (el mismo que
`BackupCodec.maxFileBytes`: más grande se rechaza sin leer el resto); un hilo de lectura; todo fallo (permiso, proveedor
caído, sin red para un archivo de Drive) sale como «No se ha podido leer el archivo»; lo que se lee se valida igual que
cualquier archivo (`BackupCodec.decode`: gzip, tope descomprimido de 4 MB y de 100:1, versión, suma de control,
integridad) y **en un isolate aparte**. El canal solo devuelve bytes y el estado de la copia del sistema; no hay nada
que escriba. La lógica pura de Kotlin (`FileReading.kt`, `LaunchPolicy.kt`) tiene pruebas en
`android/app/src/test` (`./gradlew :app:testDebugUnitTest`).

### Abrir un `.turnly` desde otra app (iOS)

**Dart (hecho):** `defaultPlatformBackupChannel()` devuelve `MethodChannelBackupChannel` también en iOS, con el
**mismo nombre de canal (`app.cuadrante/backup`) y los mismos métodos** que Android. Hasta que exista el Swift,
todas las llamadas dan `MissingPluginException` y se tratan como «no ha llegado nada». En iOS el canal **no pregunta**
`systemBackupState` (siempre `notApplicable`: la línea de Ajustes dice «Copia del sistema de Android»; el estado de
iCloud lo da `ICloudBackupStore.status`). El selector de «Importar archivo» pide el identificador de tipo
`public.data` (file_selector_ios lanza un error si solo recibe extensiones).

**`Info.plist` (hecho):** las descripciones visibles (`CFBundleTypeName`, `UTTypeDescription`) son
«Copia de seguridad de Turnly». Se conserva el identificador interno del tipo: `app.cuadrante.backup`
(extensiones `turnly` y `cuadrante`, conforme a `public.data`, exportado con `UTExportedTypeDeclarations`), `CFBundleDocumentTypes` con `LSHandlerRank = Owner` y rol `Viewer` (solo se lee;
nunca se escribe en el original), y `LSSupportsOpeningDocumentsInPlace = true`. **Por qué «en el sitio»:** con `false`
iOS copia cada archivo a `Documents/Inbox` de la app, y esa copia queda ahí (y entra en la copia del dispositivo de
iCloud) con lo que lleve dentro, bajas incluidas. Con `true`, los archivos que vienen de Archivos o iCloud Drive se
leen del original con acceso de ámbito de seguridad, sin dejar copia. AirDrop, Correo y otras apps pueden seguir
entregando una copia en `Inbox`: el Swift la borra al leer o descartar (abajo).

**Swift (falta, en el Mac):** el `SceneDelegate` (`FlutterSceneDelegate`) o un `FlutterSceneLifeCycleDelegate`
registrado con el registrador (como hace `home_widget`) recibe la URL en `scene(_:willConnectTo:options:)`
(`connectionOptions.urlContexts`, arranque en frío) y en `scene(_:openURLContexts:)` (app abierta). **Comprobar en el
Mac** que `home_widget` y este delegado conviven: `home_widget` solo devuelve `true` para URLs con el parámetro
`homeWidget`; este solo debe atender URLs de archivo (`url.isFileURL`), nunca el esquema `cuadrante://`.

| Método (Dart → Swift) | Respuesta |
|---|---|
| `hasPending` | `Bool`: hay una URL recordada que nadie ha tomado. Instantáneo, **no lee nada** |
| `readPending` | `nil` si no hay; `{bytes: FlutterStandardTypedData}` (sin `sender`: iOS no dice quién lo envió); `{error: "tooLarge"}` si pasa de 8 MB (`BackupCodec.maxFileBytes`, se mira el tamaño **antes** de leer); `{error: "unreadable"}` en cualquier otro fallo o pasados **60 s**. Se lee **una sola vez**: después ya no hay pendiente |
| `discardPending` | olvida la URL sin leerla |
| `setPreviewProtection`, `systemBackupState` | **no se implementan**: devolver `FlutterMethodNotImplemented` (llega como `MissingPluginException`, que el Dart ya trata como «nada que hacer») |

| Método (Swift → Dart) | Cuándo |
|---|---|
| `incomingAvailable` | llega una URL con la app ya en marcha y el motor escuchando. En el arranque en frío no hace falta: `BackupHost` pregunta `hasPending` al arrancar |

Reglas de seguridad, las mismas que en Android: al llegar la URL **solo se recuerda** (más
`startAccessingSecurityScopedResource()`, que se mantiene hasta leer o descartar; una URL nueva sustituye a la
anterior y suelta el acceso de la vieja, **salvo si la vieja se está leyendo**: ver abajo); solo URLs que entrega el sistema en esas funciones, **nunca una ruta que
mande el Dart**; la lectura va en una cola propia, con `NSFileCoordinator` (lectura) y el plazo de 60 s; tope de 8 MB;
al terminar (o descartar) se suelta el acceso y, si la URL está dentro de `Documents/Inbox` del sandbox, se borra el
fichero. Lo leído se valida como cualquier archivo en Dart (`BackupCodec.decode`, en un isolate) y **nunca se restaura
sin que el usuario confirme** en la vista previa. Prueba: matriz R4 de `docs/mac-ios.md` (AirDrop, WhatsApp, Correo,
Archivos), con la app cerrada y abierta.

- **`Documents/Inbox` (M2).** Al arrancar, y cada vez que se olvida o lee una URL, el Swift vacía `Documents/Inbox` entera (la app no la usa para nada más). Comprueba la ruta con `standardizedFileURL.resolvingSymlinksInPath()` y borra solo si el prefijo es exactamente `<sandbox>/Documents/Inbox/`; nunca borra fuera de ahí (con apertura en el sitio, la URL es el original del usuario).
- **Una URL nueva mientras `readPending` lee (L3).** La lectura en curso termina (o falla con `unreadable`) con su propio `stopAccessing` al acabar; la nueva se recuerda aparte. Nunca se suelta el acceso de una URL que se está leyendo.
- **Tope de 8 MB, también en Dart (M1).** `MethodChannelBackupChannel.takeIncomingFile` convierte unos bytes de más de `BackupCodec.maxFileBytes` en `IncomingFileProblem.tooLarge` aunque el Swift los haya dejado pasar: el Swift no es la única barrera.

## 10. Copia del sistema de Android (Auto Backup)

> **Importante: la copia del sistema SÍ sube los datos a la cuenta de Google del usuario.** Con Auto Backup activado,
> Android sube periódicamente `files/` (la base de datos y las copias `.turnly`) a la cuenta de Google del usuario.
> Va **cifrada de extremo a extremo con el bloqueo de pantalla** (PIN, patrón o contraseña) en Android 9 o superior
> **si el usuario tiene un bloqueo puesto**; sin bloqueo de pantalla, esa clave del usuario no existe. Nosotros no la
> vemos, pero los datos **sí salen del móvil**: no es cierto que «nunca salgan» de él. Esto incluye las ausencias de
> salud (baja médica) cuando existan; la **decisión pendiente** sobre cómo tratarlas está en `docs/preguntas.md`
> (pregunta 13).

Application Support en Android es `files/` (`getFilesDir()`, dominio `file` de Auto Backup): ahí están
`cuadrante.sqlite` (la base de datos), `backups/` (copias `.turnly`, copias previas a restaurar y a migrar). La caché
(`getTemporaryDirectory()`: los archivos que se entregan a la hoja de compartir) no se copia nunca.

`AndroidManifest.xml`: `android:allowBackup="true"` explícito, y reglas explícitas para los dos mecanismos:

| Atributo | Fichero | Android | Cubre |
|---|---|---|---|
| `android:fullBackupContent` | `res/xml/backup_rules.xml` | ≤ 11 | copia en la nube de Google |
| `android:dataExtractionRules` | `res/xml/data_extraction_rules.xml` | 12+ | `<cloud-backup>` y `<device-transfer>` (móvil a móvil) |

Las tres reglas hacen lo mismo: `<include domain="file" path="."/>`. En cuanto hay un `<include>`, solo entra lo
incluido: **se excluyen** las preferencias compartidas (las alarmas programadas de `flutter_local_notifications`, que se
vuelven a calcular de los datos al arrancar, no deben viajar a otro móvil), la caché, `code_cache` y `no_backup/`. Se
incluyen a propósito también las copias `.turnly` de `backups/`: si la base de datos se copiara a medio escribir, la
última copia entera sigue ahí. Mantener los dos XML iguales.

Límites y comportamiento del sistema (no son nuestros): la copia completa de una app no puede pasar de **25 MB** (con
~37 copias de unos pocos cientos de KB y una base de datos pequeña hay margen; si algún día no lo hubiera, bajar
`BackupRetention`); Android no restaura datos de una versión más nueva de la app sobre una más antigua (no se declara
`restoreAnyVersion`); una base de datos restaurada con un esquema anterior se migra al abrir, con su copia previa; la
copia en la nube se hace en reposo, con la pantalla apagada, cargando y con wifi, y tras la restauración la app abre
con los datos y vuelve a programar las alarmas.

**Estado en la pantalla.** `MainActivity.systemBackupState` devuelve `on` / `off` / `unknown`. Lee el ajuste del
sistema `backup_enabled`, que no es API pública: si el teléfono no lo da (Samsung, Xiaomi y otras capas pueden no tenerlo)
es `unknown` y la pantalla lo dice tal cual en vez de adivinar. Un `unknown` no es un error.

### Cómo probarlo (filas A de la matriz)

Con un móvil o emulador con servicios de Google y la copia activada (Ajustes › Sistema › Copia de seguridad):

```
adb shell bmgr enabled                              # Backup Manager is currently enabled
adb shell bmgr list transports                      # el actual lleva * (com.google.android.gms/.backup.BackupTransportService)
adb shell bmgr backupnow es.cuadrante.app    # fuerza la copia de la app ahora
adb shell dumpsys backup | grep -A3 app.cuadrante   # (PowerShell: | Select-String -Context 0,3 cuadrante) última copia
```

Restaurar (mismo móvil o uno nuevo con el mismo Google):

```
adb uninstall es.cuadrante.app               # o pm clear; el dato en la nube se queda
adb install app-release.apk
adb shell bmgr list sets                            # token del conjunto de datos
adb shell bmgr restore <token> es.cuadrante.app
```

(En versiones recientes basta `adb shell bmgr restore es.cuadrante.app`; con la restauración automática del
sistema activada, al instalar desde Play se restaura sola.) Después, abrir la app y comprobar: el calendario es el de
antes, y **Ajustes › Copia de seguridad › Probar restauración** sobre la copia recuperada da «completa» (la matriz compara
la huella de los 730 días: `scheduleFingerprint`).

Sin cuenta de Google (emulador sin Play), con el transporte local:

```
adb shell bmgr enable true
adb shell bmgr transport com.android.localtransport/.LocalTransport
adb shell bmgr backupnow es.cuadrante.app
```

y se restaura igual que arriba. Para comprobar que las reglas XML se leen y qué se incluye:
`adb shell setprop log.tag.BackupXmlParserLogging VERBOSE` y `adb logcat -s BackupXmlParserLogging` durante el
`backupnow`. Móvil a móvil (`<device-transfer>`): se prueba con el asistente de configuración de un móvil nuevo (cable
o wifi); `bmgr` no lo ejercita. Probar en Pixel → Samsung y Samsung → Xiaomi como pide la matriz (A1–A4), y que el
archivo `.turnly` exportado se importa en todos.
