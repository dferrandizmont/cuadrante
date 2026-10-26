# Festivos

Cómo llegan los festivos a la app: paquete incluido en la app (2026–2027), importación del calendario del móvil,
base de datos local, prioridades y mantenimiento anual. Alcance en la especificación: §3 P0.4 y §5. Sin red todavía:
la descarga remota está diseñada (abajo) pero no construida.

## Visión general

```
Mochila (sus calendarios oficiales, verificados)
   │  dart run tool/build_holidays.dart        (a mano, una vez al año; determinista)
   ▼
app/assets/holidays/   ← paquete incluido en la app, con manifest.json y sha256
   │  HolidayBundleLoader  (comprueba tamaño y sha256 de cada archivo)
   ▼
tabla holidays (source = bundled)  ← HolidayRepository.refreshBundled al arrancar, solo si cambia bundleVersion
   │  + filas source = user (festivos que añade la persona; nadie más las toca)
   ▼
HolidayCalendar(región, municipio) → Map<CivilDate, Holiday>  ← holidaysProvider → pantalla del mes
```

- Arranque: `bootstrapApp` lee `manifest.json` (3 KB) y compara `bundleVersion` con el guardado en `settings`
  (`holidays.bundleVersion`). Si coincide y hay filas incluidas, termina ahí. Si no, borra las filas `bundled` y las
  vuelve a insertar en **una transacción** (2.344 filas). Un archivo con suma incorrecta cancela todo y deja lo
  anterior intacto; el arranque nunca falla por los festivos.
- Ajustes: `holidays.region` (`"ES-CT"`) y `holidays.municipality` (`"08019"`), JSON en `settings`. Un municipio sin
  región implica la suya (por provincia).
- Sin región elegida solo salen los **7–8 festivos nacionales** del año (los que ninguna comunidad puede sustituir).
  Epifanía, Jueves Santo y el lunes siguiente a Todos los Santos o a la Constitución salen al elegir comunidad: la UI
  de la semana 3 debe pedirla en el primer uso.

## Traer festivos del calendario del móvil (gratis)

Ruta: **Ajustes > Festivos > Traer festivos del calendario del móvil** (`/ajustes/festivos`). Importa los eventos
elegidos como festivos propios (`source = user`), sin depender de la cobertura del paquete incluido: también sirve
para años posteriores a 2027.

1. Usa el permiso de lectura de calendario que ya existe para importar turnos; no añade permisos. Si aún no está
   concedido, explica para qué se necesita antes de pedirlo. Puedes elegir varios calendarios del móvil, incluidos
   los de solo lectura; los ocultos no se ofrecen. Reutiliza `CalendarPermissionCard` y `askForAccess`: la primera
   negativa de Android permite reintentar; la definitiva ofrece abrir ajustes y comprobar de nuevo. El acceso de
   «solo añadir» de iOS requiere volver a pedir acceso completo, como en la importación de turnos.
2. El intervalo inicial va del **1 de enero del año actual al 31 de diciembre del siguiente**, con el año obtenido
   de `clockProvider`. Puedes cambiarlo, hasta un máximo de cinco años.
3. La vista previa incluye **solo eventos de día completo**; los eventos con hora se omiten y se cuentan en un
   aviso. Cada evento de varios días se expande por fechas civiles, con **fin exclusivo**, hasta un máximo de
   **31 días desde su inicio**; si dura más, se recorta y se avisa. El nombre se recorta a 60 grafemas (el límite del
   editor manual), con un límite previo de 120 unidades UTF-16 para acotar también los grafemas con muchos
   caracteres combinantes. No corta pares surrogate.
4. Se pliegan los duplicados normalizando sus nombres. Las fechas ya cubiertas por un festivo aplicable al lugar
   elegido (incluido o propio) aparecen como «Ya existe · se omite»; el resto, como «Se añadirá». Si no queda nada
   nuevo, se indica sin modificar los datos. Al aplicar, una transacción vuelve a comprobar los festivos existentes
   para evitar duplicarlos aunque hayan cambiado desde la vista previa.
5. El aviso final permite **Deshacer**: usa exactamente los IDs insertados por esa importación. Conserva las filas
   que se hayan cambiado después y no elimina otros festivos añadidos a continuación.

La lectura se comparte con el importador de turnos y tiene un límite de **5.000 eventos**, con aviso si hay más.
Todo se procesa y guarda localmente, sin red. El acceso al calendario es de **solo lectura**: no crea,
modifica ni borra eventos en los calendarios del móvil.

Pruebas: `holiday_import_test.dart` cubre expansión, conflictos, transacciones y deshacer;
`holiday_import_flow_test.dart` usa el calendario falso de la importación de turnos y verifica los permisos y el
flujo completo. `holiday_import_layout_test.dart` comprueba los cinco idiomas, claro/oscuro, 320 dp y texto ×2 con
Roboto real, incluida la barra superior y los nombres externos largos. No sustituye la comprobación del plugin
en dispositivos Android/iOS reales.

## Formato del paquete

```
assets/holidays/
  manifest.json                    {schema: 1, bundleVersion, files[]}
  municipalities.json              código INE → nombre, por comunidad (para el selector)
  {año}/es.json                    nacionales + las 19 comunidades
  {año}/municipal/ES-XX.json       festivos locales por municipio (código INE de 5 dígitos)
```

Mismo diseño que la propuesta de `plan-publicacion.md` (los mismos caminos servirán en la descarga remota), solo con
etiquetas en español. Cada JSON lleva `schema: 1`; un `schema` distinto se rechaza.

`manifest.json`:

```json
{"schema":1,"bundleVersion":"2026-10-17.2231f936",
 "files":[{"path":"2026/es.json","year":2026,"scope":"es","sha256":"…","bytes":8179,
           "source":{"url":"https://www.boe.es/…","ref":"BOE núm. 259, 28.10.2025 — …","published":"2025-10-28"}}]}
```

- `scope`: `es`, `municipal` o `municipalities` (el índice; `year: null`). `region` solo en los municipales.
- `bundleVersion` = fecha de la fuente más reciente + 8 hex del hash del contenido. Cambia siempre que cambia un
  archivo, así que la app refresca sin que nadie tenga que acordarse de subir un número.
- `source` es la atribución (BOE, DOGC, BOCM) de cada archivo.

`{año}/es.json`:

```json
{"schema":1,"year":2026,
 "national":[{"date":"2026-01-01","name":"Año Nuevo"}],
 "regional":{"ES-CT":[{"date":"2026-01-06","name":"Epifanía del Señor","origin":"national-optional"},
                      {"date":"2026-12-26","name":"San Esteban","origin":"regional"}]}}
```

`{año}/municipal/ES-XX.json`:

```json
{"schema":1,"year":2026,"region":"ES-CT",
 "municipalities":{"08019":[{"date":"2026-05-25"},{"date":"2026-09-24"}]}}
```

Un día sin `name` es «Fiesta local»; con nombre lleva el de la pedanía («Fiesta local (El Boalo)»).

### Filas en la tabla `holidays`

| Origen | `scope` | `region_code` | `municipality_code` | `source` |
|---|---|---|---|---|
| `national` de `es.json` | `national` | NULL | NULL | `bundled` |
| `origin: national-optional` | `national` | `ES-XX` | NULL | `bundled` |
| `origin: regional` | `regional` | `ES-XX` | NULL | `bundled` |
| municipal | `local` | `ES-XX` | INE | `bundled` |
| festivo de la persona | `local` (u otro) | NULL | NULL | `user` |
| descarga remota (futuro) | igual que arriba | | | `remote` |

## Reglas de prioridad

Copiadas de `officialCalendar` (el calendario oficial del proyecto hermano), más lo que necesita la cuadrícula
(un festivo por día). Código: `HolidayCalendar` (`features/holidays/domain/holiday_calendar.dart`).

1. **Nacionales:** todos los reciben.
2. **Región elegida:** su archivo aporta (a) los `regional`, que son festivos autonómicos, y (b) los
   `national-optional`, que son festivos nacionales **que esa comunidad mantiene**. Una comunidad «sustituye» un
   festivo nacional sustituible simplemente **no listándolo**: es el único mecanismo de `official.ts`.
3. **Municipio elegido:** solo con región **y** municipio, y solo los locales de ese municipio en esa región. Si la
   región es otra, no sale nada.
4. **Un día, un festivo** (cuadrícula del mes): festivo de la persona > local > autonómico > nacional. En un mismo
   nivel, una fila `remote` gana a una `bundled`. `HolidayCalendar.list` conserva todas las filas, en el orden de
   `official.ts` (fecha, nacional < autonómico < local, nombre).
5. El alcance (`HolidayScope`) y el origen (`HolidaySource`) viajan en `Holiday` para que la UI los distinga.

Ejemplos reales de los datos:

| Caso | Resultado |
|---|---|
| Sin región, 2026 | 1 ene, 3 abr (Viernes Santo), 1 may, 15 ago, 12 oct, 8 dic, 25 dic. Sin Epifanía. |
| **ES-CT 2026, Sant Esteve** | 26 dic, «San Esteban», `regional`. Además Lunes de Pascua (6 abr), San Juan (24 jun) y la Diada (11 sep). |
| **ES-CT, Epifanía (national-optional)** | 6 ene sale como `national`: Cataluña la mantiene. |
| ES-CT frente a ES-MD, 2 abr 2026 | En Cataluña no es festivo (la sustituyó por el Lunes de Pascua); en Madrid sí: Jueves Santo `national-optional`. |
| ES-MD 2026, 2 nov | «Día siguiente a Todos los Santos», `national-optional` (el 1 nov es domingo; nadie lo lista). |
| **ES-CT + 08019 (Barcelona)** | Añade 25 may y 24 sep, «Fiesta local», `local`. |
| ES-MD + 28079 (Madrid) | Añade 15 may y 9 nov; el 2 may sigue siendo el de la Comunidad. |
| ES-AN + 41091 (Sevilla) | Sin locales en el paquete: solo nacionales y autonómicos de Andalucía. |
| Festivo propio el 12 oct | Sustituye a la Fiesta Nacional en esa pantalla; al quitarlo vuelve el oficial. |

## Cobertura incluida (paquete `2026-10-17.2231f936`)

Solo entra lo que el manifiesto de Mochila marca `verified: true` y `status: complete`.

| Dato | 2026 | 2027 |
|---|---|---|
| Nacionales (BOE-A-2025-21667 y BOE-A-2026-21254) | 7 días | 8 días |
| Autonómicos (19: 17 comunidades, Ceuta y Melilla) | 19 de 19 | 19 de 19 |
| Locales Cataluña | 870 de 947 municipios (1.739 días) | **pendiente** (Generalitat, fin de 2026) |
| Locales Madrid | 163 de 179 municipios (331 días) | **pendiente** (BOCM, diciembre de 2026) |
| Locales Murcia (solo los del calendario escolar) | 24 municipios (31 días) | 38 municipios (59 días) |
| Resto de comunidades, locales | no hay | no hay |
| Índice de municipios (INE) | 8.132 municipios, 19 comunidades | igual |

Tamaños: `2026/es.json` 8 KB, `2027/es.json` 6,5 KB, `ES-CT` 48 KB, `ES-MD` 9 KB, Murcia 1+2 KB,
`municipalities.json` 192 KB, `manifest.json` 3 KB: **270 KB** en total (se comprime bien en el paquete de la app).

## Qué falta para la v1

- **Locales fuera de Cataluña y Madrid.** No existe un conjunto abierto. Plan (`plan-publicacion.md`, hueco de
  datos): capitales de provincia y municipios de más de 50.000 habitantes (~150, decisión pendiente §12) añadidos a
  mano en Mochila (su carpeta de calendarios manuales) con el mismo formato; para el resto, el festivo local manual
  en dos toques (`HolidayController.addUserHoliday`).
- **Cataluña:** 77 municipios sin fila (la lista, en el `note` de Mochila). Madrid: 16 sin comunicar.
- **Murcia está incompleto a propósito:** sus locales salen del calendario escolar (Anexo V), no de la resolución
  laboral, así que solo cubren fechas lectivas del curso 2026–27 (sep–jun). Mejor ofrecerlo con el aviso «puede faltar
  alguno» o dejarlo fuera hasta tener la resolución del BORM.
- **Canarias:** el archivo de Mochila trae `island_holidays` (festivos insulares), pero `official.ts` no los sirve y
  aquí tampoco entran. Falta decidir cómo elegir isla.
- **Ceuta y Melilla:** las fechas de las fiestas religiosas pueden diferir del calendario escolar; se usa el
  BOE (Mochila lo anota).
- **UI:** pantalla de comunidad y municipio (semana 3) y la entrada del festivo propio. `HolidayController`
  (`setPlace`, `addUserHoliday`, `removeUserHoliday`) y `MunicipalityIndex` (`HolidayBundleLoader.loadMunicipalities`)
  ya están listos para ella.
- **`main.dart`:** añadir `initialHolidaysProvider.overrideWithValue(boot.holidays)` a los overrides para que el
  primer fotograma ya marque festivos (sin él se cargan en cuanto arranca la app, sin parpadeo apreciable pero no
  instantáneo).
- Descarga remota (abajo).

## Mantenimiento anual

1. **Octubre:** sale el BOE nacional del año siguiente. En Mochila, el PR automático de festivos lo añade al
   manifiesto como `verified`/`complete`.
2. **Noviembre–diciembre:** autonómicos y locales (DOGC/BOCM, etc.). Cuando un `…/{año}.json` pasa de `pending` a
   `complete`, ya entra.
3. Desde `app/`:
   ```
   dart run tool/build_holidays.dart                 # --mochila <ruta al repositorio hermano> si no está al lado
   ```
   Imprime los archivos, los tamaños y lo **omitido** (no verificado o sin publicar). Si avisa de carpetas que faltan
   en `pubspec.yaml` (un año nuevo es una carpeta nueva: Flutter no baja a subcarpetas), añadir las líneas
   `- assets/holidays/{año}/` y `- assets/holidays/{año}/municipal/`. Una prueba falla si se olvida alguna.
4. `flutter analyze && flutter test`. Las pruebas comprueban que cada archivo coincide con su suma del manifiesto y
   que el paquete se carga desde los assets reales. `dart run tool/build_holidays.dart --check` dice si el paquete
   incluido está al día respecto a Mochila.
5. Revisar el `git diff` de `assets/holidays/` (los archivos son estables: una línea por municipio, orden fijo) y
   publicar versión. Al instalar la app nueva, `bundleVersion` cambia y la base de datos se refresca sola; los
   festivos propios no se tocan.
6. **Enero:** correcciones de Mochila → repetir desde el paso 3.

## Descarga remota (por construir)

Se mantiene como en `plan-publicacion.md` («Festivos: cómo consumir los de Mochila»): un paso de CI en Mochila publica
`holidays/v1/manifest.json` (+ firma Ed25519), `holidays/v1/{año}/es.json` y `…/municipal/ES-XX.json` solo con
archivos verificados; la app los baja como mucho una vez al día, comprueba firma y sumas, y guarda las filas con
`source = remote`. Nada de esto está hecho, y toca el repositorio de Mochila: **necesita el visto bueno** antes de
cambiar allí nada. Lo que ya está preparado para ello:

- El formato del paquete incluido es el mismo que el remoto (mismos caminos, mismo `manifest.json`); la descarga solo
  añade la firma y el transporte.
- `HolidaySource.remote` existe en la tabla y en `HolidayCalendar` (a igual nivel, la fila remota gana a la incluida).
- `refreshBundled` solo borra filas `bundled`: una descarga futura escribirá las suyas con `remote` sin chocar.
  Pendiente de decidir entonces: qué hacer con filas incluidas y remotas del mismo año (hoy conviven y gana la remota
  por día; lo limpio será borrar las `bundled` de los años que la descarga cubra).

## Lo de `official.ts` que no se replica

- **Idiomas:** el paquete trae solo español (`label.es`). Los nombres de los festivos estatales y de los autonómicos
  más comunes se traducen al mostrarse (ca, gl, eu, en), con claves `holidayName*` de los ARB y
  `lib/features/holidays/presentation/holiday_names.dart`; el paquete no tiene ids, así que la clave estable es el
  nombre en español plegado (`foldSpanish`). Un nombre sin traducción se muestra tal cual viene del paquete, y un
  festivo añadido por la persona nunca se traduce (H-T21-1).
- **Cobertura** (`officialCoverage`: disponible/pendiente/faltante): no se guarda en la base de datos. La UI puede
  deducir «sin datos locales para tu municipio» comprobando si hay filas `local`; «pendiente» se sabe leyendo
  `manifest.json` (un año sin `municipal/ES-XX.json`).
- **`source` y `ref` por día:** quedan por archivo en el manifiesto, no por fila.
- **`municipalNonTeaching`** (días no lectivos de Murcia) y los calendarios escolares: no son festivos y no están
  en el alcance.
- **Festivos insulares de Canarias:** ver arriba; `official.ts` tampoco los sirve.
