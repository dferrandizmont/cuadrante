# Batería QA en el emulador

Escenarios que manejan la **app real** en un emulador Android (después, en el simulador de iOS) como lo haría una
persona: tocar, arrastrar, cerrar y abrir, y comprobar tanto lo que se ve como lo que queda guardado. Cazan lo que
las pruebas de widgets no ven: la base de datos en un archivo de verdad, el plugin de notificaciones, el gesto
sobre la cuadrícula, el texto grande en una pantalla real.

> **Regla: cada release pasa la batería completa y su informe se adjunta o se cita en las notas.** Una ejecución
> parcial (`QA_ONLY`, `QA_SKIP`) sirve para trabajar, no para publicar: el informe lo avisa. Una función nueva
> trae su escenario en el mismo cambio (`docs/roadmap.md`).
>
> **Lista de comprobación de release: Q01–Q13 en verde, U01 y U02 en verde.** Todo junto es
> `tool/qa/release_check.sh` (batería + U02; ver «Escenarios de actualización»).

## Cómo se ejecuta

Desde la raíz del repositorio, en Git Bash (Windows):

```bash
tool/qa/run_android.sh                    # la batería completa
QA_ONLY=Q02,Q03 tool/qa/run_android.sh    # solo esos escenarios
QA_SKIP=Q13 tool/qa/run_android.sh        # todos menos esos
tool/qa/upgrade_android.sh                # solo U02 (actualización real desde la 0.2.0; necesita red)
tool/qa/release_check.sh                  # lo de antes de publicar: batería + U02
```

Qué hace el script:

1. Si no hay un emulador suyo en marcha, arranca el AVD `Cuadrante_QA` (solo de esta app) en el puerto 5580 (sin ventana) y espera a
   que termine de arrancar. Recuerda si lo arrancó él.
2. Concede `POST_NOTIFICATIONS` a la app en cuanto se instala (Android 13+; lo necesita Q11).
3. Ejecuta `flutter test integration_test/app_test.dart -d <dispositivo>` desde `app/` (la primera vez compila
   durante varios minutos). Incluye U01.
4. Recoge las capturas de pantalla en `build/qa/shots/` y escribe `build/qa/report.md` (tabla id · título ·
   ✔/✘ · duración · captura, mediciones y el detalle de cada fallo) junto con `build/qa/integration.log`.
5. Con `QA_UPGRADE=1` (lo que hace `release_check.sh`) ejecuta después U02 en el mismo emulador y añade su fila
   al informe.
6. **Siempre**, también si falla o se interrumpe: apaga el emulador solo si lo arrancó este script. No hace
   `gradlew --stop` (pararía los daemons de otras sesiones): compila sin daemon (`GRADLE_OPTS`) y no queda ninguno.

El código de salida es 0 solo si pasan todos los escenarios (la batería **y**, con `QA_UPGRADE=1`, U02); la última
línea del script dice `RESULT: PASSED/FAILED` con los tres códigos. `tool/qa/selftest.sh` comprueba esa lógica sin
emulador, sin Flutter y sin red (falsos `adb`, `flutter` y U02, todas las combinaciones de pasa/falla): córrelo si
tocas algo de `tool/qa/*.sh`. `build/qa/` se ignora en git (el script crea
`build/.gitignore`).

| Variable | Efecto |
|---|---|
| `QA_ONLY=Q02,Q03` | Solo esos ids (el informe lo marca como parcial). |
| `QA_SKIP=Q13` | Deja fuera esos ids. |
| `QA_AVD=<avd>` | Otro AVD (por defecto `Cuadrante_QA`, el emulador propio de Cuadrante; los demás AVD son de otros proyectos). |
| `QA_DEVICE=emulator-5556` | Usa un dispositivo que ya está encendido, tal cual. Nunca se apaga. |
| `QA_EMULATOR_PORT=5580` | Puerto de consola del emulador propio (par). |
| `QA_WINDOW=1` | Muestra la ventana del emulador (por defecto, sin ventana). |
| `QA_TIMEOUT=2400` | Segundos máximos de `flutter test`. |
| `QA_FLUTTER_ARGS=...` | Argumentos extra para `flutter test`. |
| `QA_UPGRADE=1` | Después de la batería, ejecuta U02 (necesita red, 5–10 min más). |
| `QA_OLD_TAG=v0.2.0` | La release desde la que se actualiza en U02. |
| `QA_CURRENT_APK=ruta.apk` | U02 usa ese APK en lugar de compilar el de release actual. |

**Reglas de seguridad del script.** Nunca toca un emulador que no ha arrancado él: si otra sesión usa
`emulator-5554` u otro, se queda como está. Si el AVD pedido ya corre en otro puerto, el script se niega y dice
cómo usarlo a propósito (`QA_DEVICE`). Un emulador que ya estaba en el puerto 5580 con el mismo AVD se reutiliza y
tampoco se apaga.

## Cómo está montado

| Ruta | Qué es |
|---|---|
| `app/integration_test/app_test.dart` | Punto de entrada: registra los escenarios. |
| `app/integration_test/scenarios/registry.dart` | La lista `qaScenarios`: id, título en español y cuerpo de cada escenario. |
| `app/integration_test/scenarios/*.dart` | Los escenarios, por tema (`upgrade.dart`: U01, exporta `upgradeScenarios`). |
| `app/integration_test/support/qa_core.dart` | `QaScenario`, `QaContext` (capturas, mediciones, captura de `FlutterError`) y el ejecutor que imprime `QA_START/QA_RESULT`. |
| `app/integration_test/support/qa_harness.dart` | `QaApp`: la app sobre una base de datos **archivo** en un directorio temporal, arrancada con `bootstrapApp` y los mismos `ProviderScope` overrides que `main.dart`; consultas a la BD; gestos. |
| `tool/qa/run_android.sh`, `common.sh` | Emulador, permisos, ejecución, capturas y limpieza. |
| `tool/qa/report.dart` | Convierte el registro en `report.md` (y añade la fila de U02 a un informe existente). |
| `tool/qa/upgrade_android.sh`, `ui.dart` | U02: APK de la release anterior, APK actual, `adb install -r` y lectura de la pantalla con `uiautomator dump` (`ui.dart` busca botones y días por su etiqueta; nunca hay coordenadas fijas). |
| `tool/qa/release_check.sh` | Primero `release_apk_check.sh` (el APK de release conserva los recursos de `res/raw/keep.xml`), luego la batería completa + U02: la comprobación de release. |
| `tool/qa/release_apk_check.sh` | Compila el APK de release (`--target-platform android-x64`) y falla si falta algún recurso listado en `android/app/src/main/res/raw/keep.xml` (`aapt2 dump resources`). `QA_RELEASE_APK=ruta.apk` se salta la compilación. |
| `tool/qa/single_activity_check.sh` | Un `VIEW` con la app en segundo plano deja una sola `MainActivity` (ver «Una sola actividad»). |
| `tool/qa/selftest.sh` | Autocomprobación del código de salida de los scripts (sin emulador). |

Ningún escenario toca `app/lib`: el arnés construye la app desde fuera, como `main.dart` pero con un reloj fijo
(lunes **19 oct 2026, 18:20**, Europe/Madrid), una base de datos propia en el directorio temporal de la app y los
datos de demostración (`USE_DEMO_DATA`; las builds de release los rechazan, por eso la batería corre en debug). Q11
usa el reloj real porque el plugin de notificaciones rechaza fechas pasadas del dispositivo.

Todo se busca con las claves y la semántica de la UI (`day-<iso>`, `tool-<id>`, `undo`, `redo`, `paint-done`,
`tool-double`, `tool-eraser`, `holiday-dot-<iso>`), nunca con coordenadas. Una captura es
`QaContext.shot('nombre')` → `build/qa/shots/<id>_<nombre>.png`; el ejecutor añade una captura `<id>_FALLO.png` si
el escenario falla. Cualquier `FlutterError` durante el escenario (desbordamientos de layout incluidos) lo hace
fallar.

## Catálogo

Datos de demostración: rotación «correturnos» (5 mañanas, 2 libres, 5 tardes, 2 libres, 5 noches, 2 libres) desde
hace tres meses; 19–23 oct Noche, 24–25 Libre, 26–30 Mañana; excepciones: 20 solo nota, 21 Mañana+Tarde, 22 vacío a
propósito, 27–28 Vacaciones.

| Id | Qué demuestra |
|---|---|
| Q01 Arranque | Con una base de datos nueva se siembran los tipos de turno (códigos y orden de `shiftTemplates`: M, T, N, L…) y los patrones; salen la fecha, el mes, la tarjeta «Esta noche · Noche 22:00–06:00 · Empieza en 3 h 40 min», las 42 celdas y la paleta del modo pintar. Sin excepciones. |
| Q02 Pintar con un toque | Modo pintar → Tarde → un toque en un día de Mañana: la celda pasa a T y la BD tiene la fila `["afternoon"]`. |
| Q03 Arrastrar | Un arrastre sobre 4 días pinta los 4; **un** deshacer los devuelve (UI y BD idéntica a la inicial, y ya no queda nada que deshacer); rehacer los pinta otra vez. |
| Q04 Doblar | Mañana y después «Doblar» + Tarde en el mismo día: la celda muestra M y T y la fila guarda `["morning","afternoon"]` en ese orden. |
| Q05 Borrar | La goma sobre un día de la rotación guarda una excepción vacía `[]` (y deshacer borra la fila); sobre un día que ya está vacío no se escribe nada. |
| Q06 Persistencia | Pintar con toque, arrastre y goma; destruir el árbol de widgets y la conexión; abrir el mismo archivo con `bootstrapApp`: 60 días resueltos idénticos y volcado de la BD idéntico. |
| Q07 Navegación | Mes siguiente/anterior, «Hoy» solo fuera del mes actual, deslizar cambia de mes fuera del modo pintar y no lo cambia pintando. |
| Q08 Detalle del día | La hoja de un festivo muestra el nombre del festivo, los turnos (nombre y código) y la nota; un día con nota sin festivo; un día doblado; un día vacío. |
| Q09 Tema oscuro y texto grande | Tema oscuro con texto ×1,3 y ×2,0: mes, modo pintar (con un trazo) y hoja del día sin ningún `FlutterError`; capturas de cada uno. |
| Q10 Festivos por comunidad | Solo nacionales: el 26 dic no es festivo; con `ES-CT` sí («San Esteban»); se guarda en `settings`, sobrevive a cerrar la app y se quita al borrar la comunidad. |
| Q11 Alarmas | Con la alarma de Noche 90 min antes, el plugin real de notificaciones lista las pendientes con nuestro prefijo de payload (≤ 60, las del plan, todas a las 20:30 locales de un día de Noche); al desactivar no queda ninguna. Con el reloj fijo, la primera es el 19 oct a las 20:30. El plugin no expone la hora de disparo: la hora se comprueba en el plan. |
| Q12 Copia de seguridad | Exportar con `BackupService` → alterar y vaciar los datos → restaurar: la huella (`scheduleFingerprint`, 730 días) coincide con la original y queda la copia previa `pre-restore`; archivos dañados (byte cambiado, truncado, no es un `.cuadrante`) se rechazan sin tocar los datos. |
| Q13 Rendimiento | Arranque en frío (abrir el archivo, `bootstrapApp`, primer fotograma con las 42 celdas) con 2 años de turnos en la BD: objetivo < 1 s, **falla por encima de 2 s**. Se miden tres arranques seguidos; el primero es el que cuenta. La cifra sale del build de depuración en el emulador (JIT), así que es una cota alta del rendimiento real. Medido el 19-oct-2026 en `Mochila_Phone` (API 36, 417 días guardados): 237 / 228 / 237 ms. |
| Q20 Mis turnos: orden | Ajustes › Mis turnos lista la paleta en su orden; arrastrar el asa de un turno cambia el orden, la BD guarda `sort_order` en ese orden, la barra de pintar lo sigue y sobrevive a reiniciar. (`scenarios/shift_types.dart`) |
| Q21 Mis turnos: crear | Formulario vacío → mensajes en español y nada guardado; el código se sugiere desde el nombre y uno repetido se rechaza; color de la cuadrícula, 07:30–15:30, descanso de 30 min («Se pagan 7 h 30 min») y 12,50 €/h: la BD guarda `paid_minutes` 450 y `hourly_rate_cents` 1250; se pinta de inmediato y sobrevive a reiniciar. |
| Q22 Mis turnos: editar | La vista previa (celda real en claro y en oscuro) imprime un contraste ≥ 4,5:1 con los 24 colores de la cuadrícula; capturas en ambos temas; 08:00–08:00 se explica como 24 h y 22:00–06:00 como «termina al día siguiente»; los días que usan el turno cambian al guardar. |
| Q23 Mis turnos: archivar | Pintar un día, «Editar turnos» desde la barra de pintar, archivar Libre (confirmación; cancelar no cambia nada): sale de la paleta, `archived = 1`, los días siguen mostrando «L» y el deshacer del pintado sigue funcionando. |
| Q24 Detalle: turnos | En un día libre: doblar con una Guardia, subirla, quitar el Libre; cada paso deja su fila en la BD y se deshace/rehace desde el modo pintar hasta dejar la BD idéntica. (`scenarios/day_detail.dart`) |
| Q25 Detalle: volver al patrón | Un día con excepción muestra «El patrón da: …»; «Volver al patrón» borra la fila y la celda recupera el turno de la rotación; deshacer devuelve la excepción. |
| Q26 Detalle: nota | Nota multilínea con emoji: se guarda al cerrar la hoja (sin pulsar nada más), no crea excepción de turno, sobrevive a reiniciar; vaciar el texto borra la nota y la fila. |
| Q27 Detalle: festivo propio | «Festivo propio» añade el festivo con nombre editable, sale el punto en la cuadrícula y la fila `source = user` en `holidays`; sobrevive a reiniciar; apagarlo lo borra. |
| Q28 Detalle: duplicar y borrar | «Duplicar en otro día» copia turnos y nota al día elegido (BD incluida) y el aviso «Deshacer» lo revierte; «Borrar día» deja una excepción vacía (y se desactiva en un día vacío); deshacer desde el mes. |
| Q29 Deshacer en cadena | Pintar, editar un día en el detalle y renombrar un tipo de turno: el historial de deshacer no se pierde al editar turnos, deshacer/rehacer recorre pintado y detalle y la BD coincide en cada paso. |
| Q30 Pintar un mes con un preset | Calendario vacío → Pintar → Patrón → Correturnos → Siguiente ×2 → Aplicar: **6 toques**, el mes entero con turno; mide `pintar_mes_ms` y **falla por encima de 30 s** (objetivo de la especificación). |
| Q31 Vista previa = resultado | 24x72 desde el 26 oct con «día 2 del ciclo»: lo que dibuja la vista previa, celda a celda, es lo que el motor da después de aplicar. |
| Q32 Un solo deshacer | Aplicar un patrón y deshacer: rotaciones y volcado de la BD idénticos a los de antes (un solo paso); `seq` únicos; rehacer lo vuelve a aplicar. |
| Q33 Secuencia propia | Constructor con varios turnos en un día, nombre propio; queda en la tabla `patterns` y en `pattern_runs`; tras reiniciar sigue y el asistente lo lista. |
| Q34 Desde este día | Pulsación larga en la ficha Guardia → aviso → toque en el 24 oct: abre el asistente con «Desde el sábado 24 de octubre» y «Empiezan por Guardia 24 h»; el toque no pinta; el patrón empieza ese día. |
| Q35 Días cambiados a mano | Con «Respetar» (por defecto) se queda el Mañana+Tarde del 21 oct; con «Sustituirlos» desaparece la excepción de la BD; deshacer la devuelve. |
| Q36 Saliente automático | Apagado: la noche no toca el día siguiente. Encendido: el día vacío pasa a Saliente en el mismo paso de deshacer (celda S, fila `["postNight"]`); el ajuste sobrevive a reiniciar. |
| Q37 Continental y DuPont | Con los tipos de 12 h y el patrón DuPont borrados: aplicar DuPont los crea (28 días exactos). Continental: 7 mañanas, 7 tardes, 7 noches y 7 libres por ciclo, que se repite. |
| Q38 Vista anual | 12 meses, colores distintos para Noche, Libre y día vacío, leyenda con los días por turno, flechas de año y un mes que abre la pantalla del mes. |
| Q39 Compartir el año | «Compartir como imagen» entrega un PNG válido (`cuadrante-2026.png`) a la hoja de compartir (sustituida por una función de prueba). |
| Q50 Enfermería, primer uso en < 60 s | Primer arranque (`scenarios/onboarding.dart`, `onboardingScenarios`): Enfermería → Madrid → 12 horas, día 2 del ciclo → Continuar → Ver mi calendario: **11 toques**; mide `primer_uso_ms` y `primer_uso_toques` y **falla por encima de 60 s o de 12 toques**. Tipos con las horas de enfermería, sin duplicados, `onboarding.profile` guardado y el mes pintado. |
| Q51 Saltar cada paso | «Saltar» en los cuatro pasos (y «atrás» en medio): calendario en blanco, nada guardado salvo `onboarding.done`; al reiniciar no vuelve. |
| Q52 Comunidad y municipio | Sevilla avisa de que los locales se añaden a mano; cambiar de comunidad olvida el municipio; Madrid capital marca el 9 nov en el mes y la elección sobrevive a reiniciar. |
| Q53 Quien actualiza no lo ve | Base con rotación y días (como la que deja la 0.3.0): abre en el mes, `onboarding.done` queda a `true` y borrar todos los datos después no lo hace volver. |
| Q54 Consejo del mes | Aparece tras el primer uso, sigue tras reiniciar si no se cierra, y «Entendido» lo quita para siempre (`onboarding.tipPending`). |
| Q60 Alarmas: activar desde la pantalla | Ajustes › Alarmas: interruptor general y Noche (90 min) desde la interfaz → el plugin real lista las pendientes con el prefijo de payload (= plan, ≤ 60, todas a las 20:30) y la línea «Próximo aviso» acaba en «20:30 · Noche». Reloj del dispositivo. (`scenarios/alarms_settings.dart`) |
| Q61 Alarmas: día anterior | Activar «Aviso el día anterior» añade exactamente un aviso por noche con la víspera por delante (a las 20:00 del día anterior) y deja intactas las alarmas de antes del turno; apagarlo devuelve el conjunto inicial. |
| Q62 Alarmas: saltar un día | «Sin alarma este día» en el detalle de una noche quita **exactamente** la alarma de ese día (las demás siguen, mismos ids); quitar el interruptor la devuelve. |
| Q63 Alarmas: probar aviso | «Probar aviso» deja una notificación pendiente (payload de prueba) y a los 10 s aparece entre las activas con el título «Aviso de prueba». Sin alarmas exactas concedidas puede tardar minutos (se anota). |
| Q64 Alarmas: apagar todo | Con Noche, día anterior y una prueba programada, apagar el interruptor general no deja ninguna alarma nuestra pendiente; al volver a encenderlo las elecciones siguen y las alarmas vuelven. |

### Copia de seguridad: pantallas (Q65 a Q69)

`integration_test/scenarios/backup_ui.dart` (`backupUiScenarios`; hay que añadirlo al registro). Usa el sistema de
archivos real, la base de datos en archivo y el canal real de la plataforma; solo la hoja de compartir y el selector de
archivos son de mentira (abren pantallas del sistema que una prueba no puede manejar). Las copias van a una carpeta
temporal, nunca a la de la app.

| Id | Qué demuestra |
|---|---|
| Q65 Exportar, vaciar e importar (R4) | Ajustes › Copia de seguridad › Exportar archivo entrega un `.cuadrante` llamado `cuadrante-2026-10-19.cuadrante`; se vacían los días y las rotaciones; Importar archivo → vista previa («Esto sustituye lo que tienes ahora; antes guardamos una copia.») → confirmar: la huella de 730 días es idéntica a la original, queda una copia `pre-restore` y el calendario vuelve a mostrar la noche de hoy. En Android, la línea de la copia del sistema está en pantalla. |
| Q66 Versión más nueva (R6) | Un archivo con `schemaVersion` mayor se rechaza en la vista previa con «Este archivo es de una versión más nueva de Cuadrante: actualiza la app.» y «No hemos cambiado nada»; sin botón de confirmar, huella y BD intactas, sin copia previa. |
| Q67 Archivo dañado (R7) | Cortado, con un byte cambiado y que no es un `.cuadrante`: cada uno se rechaza con su mensaje, sin tocar la BD ni crear copia previa; el archivo bueno sigue importándose después. |
| Q68 Volver a como estaba | «Hacer copia ahora», pintar dos noches, «Restaurar esta» (vuelve a la copia) y «Volver a como estaba» desde la copia previa: la huella de las noches pintadas se recupera y el calendario las muestra. |
| Q69 Copia automática | Sin ninguna copia al empezar; pintar un día; sin pulsar nada aparece `cuadrante-*.cuadrante` con ese día dentro (retraso de 2 s en la batería en lugar de 10 s) y la pantalla dice «Hoy a las 18:20 · En este móvil», sin aviso de fallo. |

| Q70 Importar un .ics | Ajustes › Importar › archivo `.ics` con 3 eventos («El archivo trae 3 eventos.»): Mañana, Noche y Libre se reconocen por el título y la alarma del evento no se toma por un turno; tras importar se ve noviembre con M, M, M, N en sus días, el día anterior y el Libre de la rotación quedan igual, se guardan 4 días y todo se deshace con un solo «Deshacer». (`scenarios/import.dart`) |
| Q71 Importar un CSV | Columnas de fecha, título y horas, títulos agrupados y días pintados como en el archivo. |
| Q72 Exportar dos veces | Exportar el mes a un calendario de prueba del móvil y volver a exportar: los eventos no se duplican y solo se tocan los que llevan nuestra etiqueta. |
| Q73 Desde el calendario del móvil | Elegir un calendario del móvil y un rango; los eventos se agrupan por título y se pintan con el tipo elegido. |
| Q74 Archivo estropeado y conflictos | Un archivo que no es un calendario y uno binario dan su mensaje sin tocar nada; un archivo bueno sobre días con turno pregunta si mantener o sustituir y respeta la elección. |
| Q75 Resumen del mes con precios | Correturnos con precios por hora: 160 h, 20 turnos y 1.248,00 € estimados, por tipo y en total. (`scenarios/summary.dart`) |
| Q76 Cambio de mes y año | Flechas de mes, comparación con el anterior y tabla del año; tocar una fila abre ese mes. |
| Q77 Festivos y ausencias | Horas en festivo (también la parte de una noche tras la medianoche) y días de ausencia por tipo. |
| Q78 Compartir el mes | Entrega un PNG de 1200 px con el mes, que respeta el primer día de la semana. |
| Q79 Precio desde Mis turnos | Poner precio a la Noche en el editor cambia el estimado del resumen. |

| Q80 Selección: poner turno | Mantener pulsado un día y arrastrar una semana → «Poner turno…» → Tarde: los 7 días en la BD; un solo deshacer los devuelve. (`scenarios/selection.dart`) |
| Q81 Copiar y pegar una semana | Copiar una semana y pegarla en otro lunes: mismos turnos con el mismo desfase, notas solo si se piden. |
| Q82 Repetir | Repetir un bloque 4 veces: días y fechas finales correctos; un solo deshacer. |
| Q83 Mis rotaciones | «Terminar aquí» y «Eliminar» una rotación, con deshacer exacto. |
| Q84 Agenda y búsqueda | La agenda lista las notas próximas y la búsqueda sin acentos encuentra una nota pasada. |

### Paridad gratis: más de diez calendarios, comparar, rangos, color libre, cortar y preguntas frecuentes (Q85 a Q92)

`integration_test/scenarios/parity.dart` (`parityScenarios`, en el registro). Datos de demostración alrededor del lunes
19 de octubre de 2026.

| Id | Qué demuestra |
|---|---|
| Q85 Crear más de diez calendarios | Con 9 calendarios extra se crean el décimo, el undécimo y el siguiente: **ya no hay tope** (con la gratuidad total del 26-oct-2026 se retiró el límite de 10 y su mensaje). Archivar uno lo deja guardado y recuperarlo vuelve a dejarlo activo. |
| Q86 Comparar: días libres en común | Ajustes › Calendarios › «Comparar calendarios» con «Mi cuadrante» y «Pareja»: cada día enseña los turnos de los dos (N / V, M+T / –), los días libres en los dos (Libre, vacío, vacaciones) llevan marca con check, el contador dice «12 días libres en común este mes» y la lista trae sus fechas. (`scenarios/parity_compare.dart`) |
| Q87 Comparar: elegir y cambiar de mes | Desde la etiqueta del calendario del mes: elegir «Hijo» como segundo, elegir el que ya está en el otro hueco los intercambia, flechas y deslizar cambian de mes, y la BD queda idéntica (solo lectura, el calendario activo no cambia). |
| Q88 Resumen por fechas | En el resumen, «Fechas…» arranca con el mes en pantalla y las mismas cifras (160 h); Desde 19 y Hasta 25 de octubre dan 5 turnos, 40 h y 24 h nocturnas (como calcula el motor); las flechas mueven el periodo su propia longitud; en un rango no hay botón de compartir imagen. (`scenarios/parity_summary.dart`) |
| Q89 Color libre | Mis turnos › Nuevo › «Más colores…»: la hoja enseña la casilla en claro y en oscuro con el contraste; un hex mueve los deslizadores y un deslizador reescribe el hex; un hex incompleto bloquea «Usar este color»; el color se guarda en la BD y el turno lo lleva en la paleta. (`scenarios/parity_color.dart`) |
| Q90 Cortar una semana | Seleccionar una semana y «Cortar»: los 7 días quedan vacíos en pantalla y en la BD, el aviso dice «7 días cortados» y un solo deshacer lo devuelve todo; el portapapeles conserva los días. Cortar mueve también nota, aviso y horas extra de la copia (prueba de controlador `range_edit_annotations_controller_test.dart`). (`scenarios/parity_cut.dart`) |
| Q91 Preguntas frecuentes | Ajustes › Ayuda tiene «Preguntas frecuentes», «Ayuda y contacto» y «Acerca de»; la pantalla lista las 12 preguntas cerradas, se abren varias a la vez, todas enseñan su respuesta sin errores y «Ayuda y contacto» abre la hoja con la versión. (`scenarios/parity_help.dart`) |
| Q92 Cortar y pegar en otro mes | Cortar una semana, pegarla un lunes del mes siguiente (mismos turnos en los mismos días de la semana) y deshacer pegado y corte: un paso cada uno, la BD como al principio. |

### Paridad: avisos en notas y sonido de alarma (Q93 a Q95)

`integration_test/scenarios/reminders_sounds.dart` (`reminderSoundScenarios`).

| Id | Qué demuestra |
|---|---|
| Q93 Recordatorio de una nota | En el detalle de un día de mañana, «Avisarme» (el selector propone 09:00) deja la fila `note_reminder_minute = 540` y **exactamente una** notificación pendiente en el plugin real: id `alarmIdFor(día, "", 0, reminder)`, título «Recordatorio», cuerpo = primera línea de la nota, canal `note_reminders` creado. Es lo que dice el planificador con todos los interruptores de alarmas apagados, y la agenda enseña la campana con «09:00». Reloj del dispositivo. (`scenarios/reminders_sounds.dart`) |
| Q94 Sonido por tipo de turno | En Mis turnos › Noche, la fila «Sonido» (Predeterminado) abre el selector (aquí simulado con un URI real del sistema, `content://settings/system/alarm_alert`); guardar deja `shift_types.alarm_sound`; al activar las alarmas de Noche los avisos pendientes llevan ese sonido en el payload y existe el canal `shift_alarm_<hash>` junto al `shift_alarms`; tras reiniciar la app la fila sigue mostrando el sonido; «Usar el predeterminado» borra el valor y el canal sobrante desaparece. El selector nativo de Android no se puede manejar desde la batería: queda para la prueba manual. |
| Q95 Quitar aviso y deshacer | «Quitar aviso» quita la fila, la notificación pendiente y deja la nota; «Deshacer» en el sitio la devuelve (BD y plugin, mismo id); quitarlo otra vez y deshacer desde el modo pintar es un solo paso. |

### Paridad: horas extra, salidas anticipadas e iconos (Q96 a Q98)

`integration_test/scenarios/parity_a6_a8.dart` (`parityA6A8Scenarios`).

| Id | Qué demuestra |
|---|---|
| Q96 Horas extra y salí antes | Detalle del 26 de octubre: seis toques en «+» de horas extra (1 h 30 min) y dos en «Salí antes» (30 min) se escriben juntos tras una pausa: la BD guarda 90 y 30 minutos sin tocar el turno del patrón, la casilla muestra el «+» y un solo «Deshacer» lo quita todo; con «−» hasta 0 la fila desaparece. (`scenarios/parity_a6_a8.dart`) |
| Q97 Resumen con horas extra | Con precios: 160 h + 2 h de extra − 1 h de salida = 161 h, líneas «Horas extra» (+2 h, +15,00 €) y «Salidas anticipadas» (−1 h, −10,00 €), estimado 1.253,00 € y aviso por la extra de la Noche, que no tiene precio. |
| Q98 Icono del turno | Mis turnos › Mañana › Icono: la rejilla trae «Sin icono» y los 30 símbolos; elegir «Sol» lo guarda (`icon = sun`), se ve en la fila de la lista, en la casilla del mes antes del código (cabe: código de una letra) y en el detalle del día; «Sin icono» lo quita en todos sitios. |

### Paridad: turno partido (Q99)

`integration_test/scenarios/parity_split.dart` (`paritySplitScenarios`).

| Id | Qué demuestra |
|---|---|
| Q99 Turno partido | Mis turnos › Nuevo turno «Partido» 09:00–13:00; con «Turno partido» y el segundo tramo empezando a las 13:00 el formulario dice que sería un solo tramo y no guarda; con 17:00–21:00 enseña «Trabajas 4 h y 4 h: 8 h en total» y guarda las cuatro columnas (`start/end_minute`, `segment2_start_minute`, `segment2_duration_minutes`). Pintado en los dos días libres del 24 y el 25, la casilla muestra el código, el detalle del día los dos horarios («09:00–13:00 · 17:00–21:00») y el resumen del mes pasa de 160 h a 176 h (el descanso no se trabaja) con 22 turnos. |

### Actualización (U01 y U02)

| Id | Qué demuestra |
|---|---|
| U01 Migración v1 → v4 en el dispositivo | Un archivo v1 real con datos se migra a v4 (pasando por v2 y v3) con el SQLite de Android: todo en `main`, huella de 730 días idéntica, copia previa legible, sin segunda copia al reabrir y el mes muestra los turnos. Corre dentro de la batería. |
| U02 Actualización real desde la 0.2.0 | Con los APK de release: se pinta una semana en la 0.2.0, se instala la versión actual encima y siguen los mismos días en «Tarde»; sin crash. Script aparte (`upgrade_android.sh`), con red. |

Detalle en «Escenarios de actualización».

## Cómo añadir un escenario

1. Elige el siguiente id libre (`Q14`…). Los ids no se reutilizan ni se renumeran: los citan las notas de release.
2. Escribe el cuerpo en el archivo de su tema de `app/integration_test/scenarios/` (o uno nuevo):

   ```dart
   const qaMiEscenario = QaScenario('Q14', 'Título en español', _cuerpo);

   Future<void> _cuerpo(QaContext qa) async {
     final t = qa.tester;
     final app = await QaApp.open(qa);        // BD archivo + reloj fijo + datos de demostración
     await enterPaintMode(t);
     await t.tapAndSettle(tool('afternoon'));
     await t.tapAndSettle(cell(const CivilDate(2026, 10, 30)));
     expect(inCell(const CivilDate(2026, 10, 30), find.text('T')), findsOneWidget);
     await app.flushWrites();
     expect((await app.storedDay(const CivilDate(2026, 10, 30)))?.shiftTypeIds, ['afternoon']);
     await qa.shot('pintado');
   }
   ```

3. Añádelo a `qaScenarios` en `scenarios/registry.dart`.
4. Comprueba **resultados reales** (lo que se ve *y* lo que queda en la BD), con claves y semántica, sin
   coordenadas. Con `QaApp.open(prepare: ...)` puedes dejar datos preparados antes de que la app los cargue, y con
   `QaApp.restart()` cerrar y abrir la app.
5. Pruébalo solo: `QA_ONLY=Q14 tool/qa/run_android.sh`; después la batería completa.
6. Añade su fila a la tabla de arriba y, si cambia el contrato, a `docs/roadmap.md`.

Trucos del arnés: `tester.tapAndSettle` revela el objetivo, comprueba que se puede pulsar y **falla** si no (en un
dispositivo real el campo con foco vuelve a desplazar su cursor a la vista y puede dejar un «Guardar» fuera de
pantalla; un toque ciego no guardaba nada); `app.container` se busca desde `CuadranteApp`, así que vale con
cualquier pantalla encima del mes; todo acceso a la BD o al plugin va dentro de `tester.runAsync` (los métodos de `QaApp` ya lo
hacen); `tester.settle()` en lugar de `pumpAndSettle` sin límite; `qa.metric(...)` y `qa.note(...)` salen en
«Mediciones» del informe.

Para las flechas del mes usa `tapMonthArrow(tester, next: true/false)`. En Pintar,
revelar una fila baja puede dejar la navegación fuera del árbol visible (Q05 tras
borrar el 29 de octubre y deshacer, desde el selector Cuadrícula/Lista). El helper
pulsa «Desplazar el mes hacia arriba» hasta recuperar la flecha y exige que se
pueda tocar; no sale del modo pintar ni modifica el controlador para navegar.
`month_paint_navigation_test.dart` reproduce ese estado en 412×915 y 320×915 dp
con Roboto y áreas seguras, y comprueba navegación, objetivos de 48 dp y los datos
de Q05. Q02–Q07, Q24, Q29 y Q30 revisados: solo Q05 y Q07 usan flechas del mes;
ambos comparten el helper, igual que Q36. Los demás mantienen sus comprobaciones
de pintado, trazos, persistencia, historial y aplicación de patrones.

## Escenarios de actualización

Lo que la batería de arriba no puede hacer por sí sola: probar que una app **ya instalada con datos** sigue
entera cuando llega la versión nueva. Cada release los pasa; lo que más duele perder es el cuadrante de la gente.
Se prueban de dos formas complementarias.

### U01 — Migración v1 → v4 en el dispositivo (`scenarios/upgrade.dart`)

Va en la batería normal (`QA_ONLY=U01 tool/qa/run_android.sh` para correrlo solo). Qué hace, con el SQLite de
Android de verdad:

1. Deja en el directorio de la app un archivo `cuadrante.sqlite` **v1 real**, escrito con el esquema v1 generado
   de la 0.2.0 (`test/drift/app_database/generated/schema_v1.dart`) y el mismo fixture que usan las pruebas del
   anfitrión (`test/support/v1_database.dart`): tipos de turno (con uno archivado), patrones, 3 rotaciones (una
   cortada), días con varios turnos, con `[]` a propósito, solo nota y nota con emojis, festivo propio, saldos de
   ausencias y ajustes. Calcula la **huella de 730 días** con esos datos v1.
2. Lo abre con `openAppDatabase` (el camino real de la app) y comprueba: esquema 4, un solo calendario `main`,
   **todas** las filas de `pattern_runs` y `day_entries` en `main`, cada columna de v1 idéntica y la huella de
   `main` idéntica a la de v1.
3. La copia previa `backups/pre-v1-a-v4-*.sqlite` existe, es v1, se abre con el esquema v1 con los mismos datos y
   abrirla no cambia un byte.
4. Arranca la app sobre ella: el mes muestra los turnos migrados (por el texto de las celdas: M + N el 19, vacío el
   20, V el 22; la hoja del día trae «Viaje a Cádiz» y «Cambio con Marta») y los festivos propios y los ajustes
   del usuario siguen ahí.
5. Cierra y abre otra vez: **no hay una segunda copia**, la copia no cambia y el volcado de todas las tablas es
   idéntico (sin filas duplicadas).

### U02 — Actualización real desde la 0.2.0 (`tool/qa/upgrade_android.sh`)

Es lo único que usa los **APK de release de verdad**, firmados como los que se instalan en el móvil, sin
`run-as` (no son depurables): la app se maneja desde fuera, como una persona, con `adb input`, y se lee con
`adb shell uiautomator dump`. Los botones y los días se buscan por su etiqueta de accesibilidad («Pintar»,
«Tarde», «jueves 22 de octubre, …»), nunca por píxeles.

1. `gh release download v0.2.0 -p '*.apk'` → `build/qa/cuadrante-0.2.0.apk` (se conserva entre ejecuciones).
2. Compila el APK de release actual (`flutter build apk --release --dart-define=USE_DEMO_DATA=false`, firma de
   desarrollo de esta máquina, número de compilación = nº de commits, para que sea una actualización y no una
   bajada de versión).
3. Desinstala, instala la 0.2.0, la abre, entra en modo pintar, elige «Tarde» y pinta **una semana con un solo
   arrastre**; sale del modo pintar. Las builds de release no traen datos de demostración: el calendario empieza
   vacío y lo pintado es lo único que hay.
4. Cierra la app a la fuerza, la abre y guarda las etiquetas de todos los días del mes (las pintadas llevan el
   nombre y la hora de «Tarde»). Captura `U02_antes_0.2.0.png`.
5. `adb install -r` del APK actual **sin desinstalar**; comprueba que `firstInstallTime` no cambia (se actualizó,
   no se reinstaló), abre la app y vuelve a leer la pantalla: los mismos 7 días siguen en «Tarde» y **todo el mes
   es idéntico**. Captura `U02_despues_actual.png`. Sin `FATAL EXCEPTION` ni señal fatal en `logcat` y con la app
   en marcha.
6. Elige un día vacío **del mes visible** (las casillas grises no se pintan), pinta con la versión nueva y
   comprueba que ya dice «Mañana» **antes** de cerrar. Cierra y abre: sigue ahí y los siete días de Tarde
   siguen intactos (la base migrada admite escrituras). Un toque fallido se distingue de un fallo de persistencia.

Cómo se ejecuta: `tool/qa/upgrade_android.sh` (arranca `Cuadrante_QA` en el 5580 si hace falta y solo apaga lo
que arrancó) o, junto con la batería, `QA_UPGRADE=1 tool/qa/run_android.sh` / `tool/qa/release_check.sh`.
**Idioma:** U02 requiere Android 13 o posterior y fija español solo para la app de QA antes de abrir ambos APK; al salir restablece esa preferencia al idioma del sistema. No cambia el idioma global del dispositivo.

**Necesita red** (`gh` baja el APK la primera vez; sin sesión de `gh` o sin conexión falla diciéndolo) y tarda
**entre 5 y 10 minutos**, casi todo compilando el APK de release (`QA_CURRENT_APK=ruta.apk` se salta la compilación).
Deja `build/qa/u02.log`, `u02_dias_antes.txt` / `u02_dias_despues.txt`, los volcados `ui_*.xml`, el `logcat` y
las capturas `shots/U02_*.png`, y añade su fila al `report.md` (al de la batería si lo hay).

Qué **no** prueba U02: la base de datos y la copia previa por dentro (sin `run-as` no se pueden abrir; eso es U01)
ni una versión de origen que no esté publicada (`QA_OLD_TAG=v0.1.0` prueba esa).

## Una sola actividad (`tool/qa/single_activity_check.sh`)

`MainActivity` es `launchMode="singleTask"` (`docs/copia-de-seguridad.md`, apartado 9). Con `singleTop` y
`taskAffinity=""`, un `VIEW` de un `.cuadrante` desde Archivos o WhatsApp con la app en segundo plano arrancaba una
segunda `MainActivity` y un segundo motor. Comprobación manual, o con el script:

```bash
QA_DEVICE=emulator-5580 tool/qa/single_activity_check.sh   # app ya instalada; sin QA_DEVICE no hace nada
```

A mano: abre Cuadrante, pulsa Inicio, abre un `.cuadrante` desde Archivos (o `adb shell am start -a
android.intent.action.VIEW -n es.cuadrante.app/.MainActivity -t application/octet-stream -d content://...`) y
mira `adb shell dumpsys activity activities`: **una** sola `ActivityRecord` de `es.cuadrante.app/.MainActivity`
(antes del cambio salían dos). Aparte, con la app en segundo plano: tocar un día del widget abre ese día
(`cuadrante://widget/day/<fecha>`) y tocar una notificación de alarma abre la app, siempre en la misma actividad.
El script lo escribió y revisó quien hizo el cambio **sin ejecutarlo** (no hay emulador en esa sesión): la primera
vez que se use, comprueba que cuenta dos antes del cambio (`git stash` del manifest) y una después.

## Widgets de Android (W01–W05)

`tool/qa/widget_android.sh` prueba los widgets de pantalla de inicio (`docs/widget-contrato.md`, «Android») en un
emulador de verdad, sin abrir la app cuando lo que se comprueba es el cambio de día. Aparte de la batería: no usa
`flutter test`, sino la app de depuración instalada, el launcher y `uiautomator`.

```bash
tool/qa/widget_android.sh                          # arranca el AVD Cuadrante_QA en el 5580
QA_WIDGET_APK=ruta.apk tool/qa/widget_android.sh   # sin compilar
QA_WIDGET_EXACT=0 tool/qa/widget_android.sh        # sin el permiso de alarmas exactas (la alarma puede llegar tarde)
```

El AVD se crea con la imagen `google_apis_playstore` (API 36) ya instalada; no se descarga nada. Esa imagen **no se
puede rootear** (`adb root` falla y `cmd time_detector` rechaza al shell), pero `adb shell service call alarm 2 i64
<ms>` sí cambia la hora y `service call alarm 3 s16 <zona>` la zona: con eso se simula el paso del tiempo de verdad,
con el sistema enviando `TIME_SET`/`TIMEZONE_CHANGED` y la alarma de medianoche disparándose sola. La instantánea que
leen los widgets se lee con `run-as` y es el oráculo de las etiquetas esperadas (`lun 19`). Siempre al final: hora,
zona y ahorro de batería de vuelta a lo normal, emulador apagado solo si lo arrancó el script (sin `gradlew --stop`: compila sin daemon).

| Id | Qué demuestra |
|---|---|
| W01 Publicar y añadir | La app (datos de demostración) publica la instantánea en `HomeWidgetPreferences` con `firstDate` = hoy; desde Ajustes › Añadir widget se fijan los dos primeros widgets (2×2 y 4×2) aceptando el diálogo del launcher; la pantalla de inicio muestra la etiqueta de hoy. |
| W02 Cambio de día sin la app | Con la app cerrada (proceso matado) y el ahorro de batería activo, la hora pasa a las 23:58:30; el widget enseña hoy, y tras medianoche, mañana: la alarma exacta llega a las 00:00:02 (falla si tarda más de 10 s; con `QA_WIDGET_EXACT=0` solo se anota la hora). Después, cambio de zona a Pacific/Honolulu (el widget sigue el reloj de allí) y vuelta. |
| W03 Aviso honesto | Último día publicado a las 23:58:30 y su medianoche: pasa a «Abre Cuadrante para seguir al día» sin ningún turno; 40 días después y con el reloj antes del primer día, lo mismo; de vuelta dentro del rango reaparece el día correcto. |
| W05 Widget del mes (4×4) | Desde Ajustes › Añadir widget › «Grande: el mes entero» se fija el widget 4×4: muestra el título del mes de hoy (de la instantánea, p. ej. «Octubre 2026») y una celda con descripción «<día> … hoy». Con la app matada y el ahorro de batería activo, la hora pasa a las 23:58:30 de la víspera del primer día del segundo mes de la instantánea; tras la medianoche (alarma) el título cambia al mes nuevo, desaparece el anterior y la celda «1 … hoy» es la de hoy. Tocar la cabecera abre la app (`cuadrante://widget/month/<aaaa-mm>`). Lo que **no** mira el script (a ojo, con las capturas `W05_*.png`): el anillo de hoy, las barras de color, los días atenuados de otros meses y que con 3×3 celdas se lea (ver el protocolo manual). Va antes de W04 porque necesita el widget colocado. |
| W04 Reinicio | Tras reiniciar el emulador llega `BOOT_COMPLETED`, la alarma de medianoche vuelve a estar armada (`dumpsys alarm`) y la siguiente medianoche dispara el refresco. Va la última: el launcher de esta imagen olvida los widgets colocados al reiniciar, así que no se mira la pantalla después. |

Deja `build/qa/widget/widget.log` (líneas `QA_*`), `shots/W0*_*.png`, `ui_*.xml`, `logcat.txt` y `build.log`. Código
de salida 0 solo si W01–W05 pasan; la última línea dice `RESULT: PASSED/FAILED`. No cambia el resultado de la batería
ni de `release_check.sh`; es parte de la comprobación de los widgets antes de publicar (`docs/widget-contrato.md`,
«Prueba de 7 días en Android»).

Qué **no** prueba: lanzadores de Samsung o Xiaomi (ahorro de batería agresivo, ver el protocolo manual), Android
anterior a 12 (los colores en oscuro de los widgets dependen de `RemoteViews.setColorInt`) ni que el usuario conceda la
alarma exacta (se concede por `appops`).

## Límites conocidos

- El plugin de notificaciones no enseña la hora de disparo de una pendiente: Q11 comprueba lo que *planifica* la app
  (20:30) y lo que *programa* el sistema (ids, payloads y número).
- Las capturas salen de `IntegrationTestWidgetsFlutterBinding.takeScreenshot`; sin ventana del emulador siguen
  funcionando, pero no incluyen barras del sistema ni notificaciones.
- Las capturas se guardan en la caché de la app y el script las baja con `run-as` (solo builds de debug); el test espera a que el script la haya bajado antes de seguir.
- La app se instala y desinstala en el emulador en cada ejecución (`flutter test`): la batería no comprueba datos
  que sobreviven a una actualización con el APK real (eso es U02; U01 lo hace con un archivo v1 colocado a mano).
- El primer arranque del emulador y la primera compilación son lentos; el informe muestra la duración total.

Q30–Q39 están en `scenarios/patterns.dart`, que exporta `patternScenarios` (`registry.dart` las suma a
`qaScenarios`: `...patternScenarios`). Con otra pantalla encima del mes (el asistente de patrón, la vista anual),
`app.container`, `app.schedule`, `app.paint` y `app.flushWrites()` siguen funcionando (el contenedor se busca
desde `CuadranteApp`, no desde el `MonthScreen`). Un `SnackBar` con acción flota sobre Deshacer/Rehacer del modo
pintar unos segundos (`pump(5 s)` antes de deshacer).
