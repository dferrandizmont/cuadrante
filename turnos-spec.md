# Cuadrante: calendario de turnos (especificación de producto)

18 oct 2026 · Basada en el análisis de ~6.100 reseñas de 12 apps de Google Play y 5 del App Store de España ([docs/analisis-mercado.md](docs/analisis-mercado.md)).

> **Nombre provisional:** «Cuadrante». Antes de decidir, comprobar que el nombre y el dominio estén libres en las dos tiendas. Alternativas: «Turnero», «MiCuadrante», «Turnos Claros».

---

## 1. Resumen

App de calendario de turnos para trabajadores en España (sanidad, policía y Guardia Civil, bomberos, industria, seguridad, hostelería). Funciona sin cuenta y sin conexión, y su promesa se resume en tres frases:

> **Tus turnos nunca se pierden. El widget nunca se queda en el día de ayer. Las horas cuadran con tu convenio.**

**Por qué ahora:**
- En iOS, la líder (Shifter, 32.000 valoraciones) no se actualiza desde mayo de 2024 y acumula quejas: no tiene widget, pierde datos al cambiar de móvil, no sincroniza con el iPad y el soporte no contesta.
- En Android hay líderes fuertes, pero todas comparten los mismos fallos de fondo: copias de seguridad que no se restauran, anuncios incluso pagando y widgets que no cambian de día.

**Plataforma:** iOS primero y Android 2–3 meses después, con el mismo código en Flutter.

**Objetivo de lanzamiento:** publicar en el App Store **antes del 15 de diciembre de 2026**, para captar el pico de cuadrantes nuevos de enero.

---

## 2. Usuarios y trabajos por resolver

| Perfil | Lo que necesita | Detalles propios |
|---|---|---|
| **Enfermería, TCAE, celadores, médicos** | Saber qué turno tiene hoy y mañana, contar noches y festivos, apuntar cambios con compañeros | Turnos de mañana, tarde y noche, día saliente tras la noche, guardias de 12 o 24 h, días de libre disposición, moscosos, «doblar» |
| **Policía, Guardia Civil, bomberos** | Cuadrantes de ciclo largo, guardias | 24/72, 6x4, 4x4, servicios especiales |
| **Industria («correturnos»)** | Ciclos fijos de 3 turnos | Rotación semanal M/T/N, 6-2, 5-2, 2-2-3 |
| **Seguridad privada, hostelería, comercio, transporte** | Turnos irregulares semana a semana | Turnos de 12 h, partidos, cuadros de varias semanas |
| **Pareja o familia del trabajador** | Ver los turnos sin instalar nada | Suscribirse al calendario del trabajador (enlace de solo lectura; P1 y gratuito) |

**Por qué cambian de app** (por orden de peso en las reseñas):
1. Pierden datos al cambiar de móvil.
2. La app se rompe tras una actualización.
3. Anuncios y avisos de cookies.
4. El widget no existe o se queda en el día anterior.
5. Les hacen pagar otra vez.
6. El soporte no contesta.

---

## 3. Alcance

### P0: MVP, sin esto no hay motivo para cambiar
1. **Pintar turnos en segundos:**
   - Modo pintar: eliges un turno de la paleta y tocas o arrastras sobre los días.
   - Selección múltiple de días.
   - Patrones listos para usar (correturnos M/T/N, 24/72, 12h día/noche, 6x4, 4x4, 5x2, 2-2-3) y patrones propios.
   - **Varios turnos por día.**
   - Horas de inicio y fin libres, incluidos turnos que cruzan la medianoche.
2. **Copia de seguridad gratis que funcione:** automática (iCloud en iOS, copia del sistema en Android), más exportar e importar un archivo propio. **Restaurar en un toque** en el móvil nuevo.
3. **Widgets fiables:** pantalla de inicio (pequeño, mediano y grande) y pantalla de bloqueo. El día siempre es el correcto sin abrir la app.
4. **Festivos:** nacionales y autonómicos ya cargados, y elección del municipio para los 2 locales (o añadirlos a mano con 2 toques).
5. **Alarma por tipo de turno**, fiable.
6. **Importar desde el calendario** del móvil, para traer el historial de Shifter o Supershift, y desde archivos .ics o CSV.
7. **Vista mensual y anual**, notas por día y modo oscuro.

### P1: diferenciadores (todo gratuito, sin planes ni compras)
8. **Horas contra convenio:** introduces la jornada anual (p. ej. 1.642 h) y ves el saldo. Horas nocturnas (22–06) y festivas separadas solas. Pluses en € por tipo de hora. Resumen «cómo va mi mes» para vigilar la nómina.
9. **Ausencias con contadores:** vacaciones, moscosos, libre disposición, compensación de festivos, permisos y baja (guardada solo en el móvil).
10. **Libro de cambios:** con quién has cambiado y quién debe un turno a quién.
11. **Compartir:** enlace de solo lectura y suscripción al calendario (.ics / webcal) para la pareja o la familia.
12. Exportar a PDF o imagen y al calendario del móvil, temas de color e iconos.

> Todas estas funciones serán gratuitas. Las que aún no estén hechas siguen **pendientes**: la gratuidad total se decidió
> el 26-oct-2026, no significa que estén implementadas.

### P2: más adelante
- Apple Watch y Wear OS, actividades en vivo en la pantalla de bloqueo.
- Calendario común entre compañeros.
- Festivos de Latinoamérica.
- Cuadrante de equipo para encargados. Es otro producto (B2B); no entrar en él en el año 1.

### Fuera de alcance
Cuentas de usuario en el MVP, anuncios y avisos de cookies, y cualquier forma de pago: compras, suscripciones o un plan Pro (decisión del 26-oct-2026).

---

## 4. Diseño

### Principios (lo que más valoran los usuarios de 5★)
1. **Rápida y sencilla** (33 % de los elogios): de abrir la app a ver el turno de mañana en menos de 1 segundo. Pintar un mes entero en menos de 30 segundos.
2. **Bonita y personalizable** (11 %): colores vivos por turno, cuadrícula limpia, buena tipografía.
3. **Nunca solo color:** cada turno lleva su color, **una letra o código** (M, T, N, L, G, S…) y la hora. Por accesibilidad y para quien no distingue colores.
4. **Pensada para quien trabaja de noche:** modo oscuro de verdad (no solo gris), brillo bajo y avisos silenciosos.

### Sistema visual
- **Paleta de turnos por defecto** (editable):
  - Mañana: ámbar `#F5A524`
  - Tarde: naranja coral `#F06A3F`
  - Noche: índigo `#4B4FD1`
  - Libre: gris claro con borde
  - Guardia: rojo `#E5484D`
  - Saliente: violeta suave `#8E7CC3`
  - Vacaciones: verde `#30A46C`
  - Moscoso o libre disposición: turquesa `#12A594`
  
  Contraste mínimo AA en el texto sobre cada color, en modo claro y oscuro.
- **Tipografía:** SF Pro en iOS y Roboto Flex en Android (las del sistema, para que se sienta nativa). Números tabulares en la cuadrícula.
- **Iconos:** SF Symbols en iOS y Material Symbols en Android, con trazo redondeado.
- **Icono de la app:** cuadrícula de 3×3 con tres casillas en los colores de mañana, tarde y noche sobre un fondo oscuro. Se reconoce en pequeño y no imita a nadie.

### Pantallas principales

**1. Hoy / Mes (pantalla de inicio)**
- Cabecera con **«Hoy: Noche 22:00–06:00 · Mañana: Saliente»**.
- Debajo, la cuadrícula del mes: celdas grandes con el color de fondo, el código del turno y la hora pequeña.
- Festivos con el número en rojo y un punto. Las notas, con un icono de clip.
- Botón flotante **Pintar**.

**2. Modo pintar**
- Abajo, una barra con los turnos como fichas de color.
- Tocar o arrastrar sobre los días pinta el turno, con respuesta háptica.
- Pulsación larga en una ficha: «aplicar patrón desde este día».
- Botón Deshacer siempre visible.

**3. Asistente de patrón**
1. Eliges un preset o creas el tuyo con una secuencia de fichas (M M T T N N L L L L).
2. Eliges el día de inicio.
3. Ves el resultado en vivo y lo aplicas hasta una fecha o sin fin.

**4. Detalle del día** (hoja inferior)
- Turnos del día (pueden ser varios), horas, nota y adjunto.
- Opción «Cambio con…» y ausencia.
- Atajos: duplicar en otro día, borrar.

**5. Vista anual**
- Mapa de calor de los 12 meses, para ver vacaciones y noches de un vistazo.
- Compartible como imagen.

**6. Horas**
- Barra de progreso de horas hechas frente a la jornada anual.
- Desglose por tipo: diurnas, nocturnas, festivas, extra.
- Euros estimados de pluses.
- Gráfico mensual sencillo.

**7. Ajustes**
- Mis turnos (editar colores, códigos y horas), festivos (comunidad y municipio), alarmas, copia de seguridad (estado y fecha de la última copia, con **«Probar restauración»**), licencias y código abierto, ayuda y contacto. Sin sección Pro: la app no cobra nada (decisión del 26-oct-2026).

### Widgets
| Tamaño | Contenido |
|---|---|
| iOS pequeño / Android 2×2 | El código del turno de hoy en grande sobre su color y la hora; debajo, «Mañana: T 15–22» |
| Mediano / 4×2 | Tira de 7 días con códigos y colores; hoy resaltado |
| Grande / 4×4 | El mes en miniatura |
| Pantalla de bloqueo iOS | «N · 22:00» en formato pequeño en línea o circular |

**Requisito técnico clave:** el widget **cambia de día solo**. Ver la sección 6.

### Primer uso (menos de 60 segundos)
1. «¿A qué te dedicas?» Enfermería / Policía o GC / Bomberos / Industria / Seguridad / Hostelería / Otro. Precarga los turnos y patrones típicos.
2. «¿Dónde trabajas?» Comunidad y municipio, para los festivos.
3. «¿Cómo es tu rotación?» Eliges un patrón y el día de inicio, o «lo pinto a mano».
4. «¿Vienes de otra app?» Importar desde el calendario.
5. Listo: el mes ya pintado. Sugerencia para añadir el widget, con una animación de cómo se hace.

### Tono y textos
Cercano, en tú, con vocabulario del sector (saliente, moscoso, libre disposición, correturnos). Nada de jerga técnica: «copia de seguridad», nunca «sync».

---

## 5. Datos: de dónde salen

| Dato | Fuente | Cómo se usa |
|---|---|---|
| **Festivos nacionales** | Resolución anual de la Dirección General de Trabajo en el BOE (la de 2026 es BOE-A-2025-21667, publicada el 28-oct-2025). La de 2027 saldrá previsiblemente en octubre de 2026. | JSON propio versionado por año |
| **Festivos autonómicos** | La misma resolución y los boletines autonómicos. Comprobación cruzada con la API pública **Nager.Date** (`date.nager.at/api/v3/PublicHolidays/{año}/ES`), que da los nacionales y autonómicos pero **no los locales**. | Incluidos en el paquete anual |
| **Festivos locales** (2 por municipio) | No existe un conjunto nacional abierto. Cada comunidad los publica en su boletín (DOGV, BOCM, DOGC…) y algunas en datos abiertos (p. ej. Euskadi y Baleares en datos.gob.es). | v1: listas para los ~200 municipios más poblados + entrada manual guiada. Después: correcciones de los usuarios con moderación mínima. |
| **Normativa de horas** | Estatuto de los Trabajadores, art. 34 (jornada y descanso de 12 h) y art. 36 (nocturno de 22:00 a 06:00) | Reglas por defecto del cálculo de horas; la jornada anual y los pluses los pone el usuario según su convenio |
| **Patrones típicos** | Conocimiento del sector y peticiones de las reseñas | Presets editables |

**Distribución de festivos:** un paquete JSON firmado en un alojamiento estático (Cloudflare R2 o GitHub Releases) que la app descarga al abrirse. Si no hay conexión, usa la copia incluida en la app. Así se actualiza cada octubre y diciembre **sin publicar una versión nueva**.

**Mantenimiento anual:** en octubre (BOE nacional), de noviembre a diciembre (autonómicos y locales) y correcciones en enero.

---

## 6. Arquitectura técnica (Flutter)

**Base:** la plantilla de Mochila (Riverpod, go_router, freezed e idiomas en ARB). Sin RevenueCat ni ningún SDK de compras: la app es gratuita (decisión del 26-oct-2026).

| Capa | Elección | Notas |
|---|---|---|
| Datos locales | **Drift (SQLite)** | Se guardan reglas y excepciones, no una fila por día |
| Widgets | **`home_widget`** como puente + **extensión WidgetKit en SwiftUI** (iOS) + **Glance o RemoteViews** (Android) | Grupo de app compartido con Flutter |
| Copia de seguridad iOS | Archivo JSON en el contenedor de iCloud mediante un canal nativo en Swift | Plugins existentes viejos o con licencia GPL: mejor un canal propio (~150 líneas) |
| Copia de seguridad Android | **Auto Backup** del sistema (incluye la base de datos) + exportar a Google Drive (carpeta de la app) como opción | Probar a fondo la restauración en Samsung y Xiaomi |
| Exportar e importar | Archivo `.cuadrante` (JSON comprimido y versionado) | Se comparte por AirDrop, WhatsApp o correo |
| Importar desde calendario | `device_calendar` (EventKit / Calendar Provider) | Asistente para asociar títulos de eventos con tipos de turno |
| Alarmas | Android: alarmas exactas y reprogramar tras reiniciar. iOS: notificaciones locales (máximo 64 pendientes: programar 2 semanas por delante) | Valorar AlarmKit (iOS 26) en la v1.1; comprobar que hay soporte desde Flutter |
| Compras | **No hay** | Sin SDK de pagos, sin paywall y sin «Restaurar compras» (decisión del 26-oct-2026) |
| Compartir (P1, gratuito) | Cloudflare Workers + KV: publica un feed `.ics` de solo lectura (sin datos de ausencias de salud) | Es lo único que necesita servidor; coste casi nulo |
| Errores | **Sin telemetría remota** en el MVP (pregunta 9 ya respondida): ni Crashlytics, ni analítica, ni envío del cuadrante | Se mantiene el diagnóstico local |

### Modelo de datos
```
ShiftType(id, code, name, colorHex, start, end, crossesMidnight, paidMinutes,
          category: work|rest|absence, countsAsNight:auto)
Pattern(id, name, steps: [shiftTypeId|null], lengthDays)
PatternRun(id, patternId, startDate, endDate?)        // rotación aplicada
DayEntry(date, shiftTypeIds[], note, attachments[], swap: {with, owedBy}?)  // excepción manual
Holiday(date, scope: national|regional|local, name, regionCode, municipalityCode)
AbsenceBalance(year, type, allowed, used)
Settings(key, value)
```
**Turno efectivo de un día** = lo que diga `DayEntry` si existe; si no, el patrón activo; si no, vacío. Es un cálculo predecible y con pruebas.

### El widget que nunca se queda en el día de ayer
- **iOS:** como el calendario es predecible, cada vez que cambia algo la app calcula los **próximos 60 días** y los escribe en el contenedor compartido. El `TimelineProvider` crea **una entrada por día a las 00:00**, de modo que el widget cambia de día sin depender de que el sistema lo refresque. Además, se recarga la línea de tiempo al abrir la app y cuando cambian el día o la zona horaria.
- **Android:** al cambiar el día, una alarma o tarea programada (WorkManager) actualiza el widget, que también responde a los avisos del sistema de cambio de fecha y zona horaria. Probar con ahorro de batería en Samsung y Xiaomi.

### Criterios de calidad para publicar (no negociables)
1. **Matriz de restauración:** iPhone a iPhone nuevo (iCloud); Android a Android nuevo (Auto Backup); archivo exportado e importado; actualización de la v1.0 a la v1.1 con migración de base de datos. **Cero pérdidas.**
2. **Widgets:** 7 días seguidos sin abrir la app y con el día siempre correcto, en iOS 17, 18 y 26 y en Android 13–16.
3. **Alarmas:** suenan 10 de 10 veces con ahorro de batería activado.
4. Pruebas unitarias de patrones, del cálculo de horas nocturnas (cruce de medianoche) y de festivos.

---

## 7. Gratuidad y licencias

> **Decisión del usuario del 26-oct-2026:** Cuadrante es **totalmente gratuita y de código abierto**. No hay Pro, ni
> compras, ni suscripciones, ni anuncios. Sustituye a todas las decisiones anteriores de monetización: la tabla
> gratis/Pro, los precios y los ingresos previstos quedan derogados.

- **Sin niveles de pago.** No existe un plan Pro: ninguna función se cobra, se reserva ni se desbloquea con dinero.
- **Gratis no significa hecho.** Lo que todavía no existe sigue **pendiente** hasta que exista, y cuando exista será
  gratuito. La gratuidad decide el precio, no la fecha.
- **Sin anuncios, sin cuentas y sin avisos de cookies**, siempre. Sin servidor propio en el MVP; la única excepción
  prevista es compartir por `.ics` (P1).
- **Código abierto.** Código bajo licencia **MIT** y contenidos propios bajo **CC BY-SA 4.0**, como Ley al Blanco.
  `LICENSE` y `LICENSE-CONTENT.md` **ya están en la raíz** del repositorio. Pendiente: publicar el repositorio público y
  los avisos de terceros.
- **Formas de pago retiradas:** RevenueCat y cualquier SDK de compras, el paywall, «Restaurar compras», el sandbox de
  compras y los productos `cuadrante_pro` y `cuadrante_pro_year` no se traen de Mochila.
- **El mantenimiento no se traslada a quien usa la app:** no hay nada que comprar ni compras que restaurar (la
  restauración de copias de seguridad sigue disponible).

| Función | Estado |
|---|---|
| Pintar, patrones, varios turnos por día, **widgets en Android**, copias y restauración, festivos, alarmas, importación, exportación puntual al calendario, imágenes del mes y del año, resumen de horas | **Hecho** |
| WidgetKit de iOS (el widget de Android ya está hecho) | **Pendiente**: se hace en el Mac (S5) |
| Varios calendarios sin límite comercial | **Hecho**: el límite de 10 ya está retirado del código (decisión del 26-oct-2026) |
| Jornada anual y saldo contra convenio, pluses por hora nocturna o festiva, saldos de ausencias, libro de cambios, PDF, temas de la app, exportación continua, compartir por enlace o `.ics` | **Pendiente**, y gratuita |

> **Lo que queda derogado:** el widget grande como Pro, los precios de 6,99 €, 9,99 € y 3,99 € y la conversión a Pro como
> objetivo comercial. No se vuelve a plantear: nada de lo que hoy es gratis pasa a de pago, porque no hay pago.

---

## 8. ASO y lanzamiento

**Título (iOS, 30 caracteres):** «Cuadrante: Turnos de Trabajo»
**Subtítulo:** «Calendario de turnos y widget»

**Palabras clave:** calendario turnos, cuadrante, turnos trabajo, correturnos, enfermería, guardias, horario rotativo, moscosos, saliente, 24/72, festivos, horas, nocturnidad

**Capturas** (mensaje en cada una):
1. «Tus turnos, de un vistazo», con el mes pintado.
2. «Pinta un mes en 10 segundos», con el modo pintar.
3. «El widget que nunca se queda en ayer.»
4. «Cambia de móvil sin perder nada.»
5. «Tus horas y pluses, según tu convenio».
6. «¿Vienes de otra app? Importa en 1 minuto.»

**Canales sin coste:**
- Grupos y cuentas de enfermería en Instagram y TikTok.
- Foros de opositores a policía y Guardia Civil.
- Subreddits españoles.
- Responder a todas las reseñas en menos de 48 h.
- Pedir valoración **solo** después de una restauración correcta o de un mes completo de uso, nunca con avisos constantes.

**Página web sencilla:** «Calendario de turnos para enfermería», «para Guardia Civil», «para bomberos»… Una página por colectivo para el posicionamiento en buscadores.

---

## 9. Calendario (de hoy a mediados de diciembre)

| Semana | Entregable |
|---|---|
| 1 (20–26 oct) | Modelo de datos, motor de patrones con pruebas, cuadrícula mensual, modo pintar |
| 2 | Tipos de turno, asistente de patrón, detalle del día, vista anual |
| 3 | Festivos (JSON 2026–2027, nacionales y autonómicos + 200 municipios), primer uso |
| 4 | Widget iOS (WidgetKit + línea de tiempo de 60 días), widget de pantalla de bloqueo |
| 5 | Copia de seguridad en iCloud + exportar e importar + importar desde calendario + alarmas |
| 6 | Horas contra convenio, pluses y ausencias con contadores (todo gratuito); matriz de restauración |
| 7 (1–7 dic) | TestFlight con 20–30 trabajadores a turnos reales; corrección de fallos |
| 8 (8–14 dic) | Capturas, ficha, envío a revisión → **publicación antes del 15 de diciembre** |
| Ene–feb 2027 | Android (Glance, Auto Backup), compartir por .ics, libro de cambios |

---

## 10. Métricas

- **Activación:** % de usuarios con el mes pintado en el primer día (objetivo > 70 %).
- **Widget:** % que lo añade (objetivo > 40 %).
- **Confianza:** % con copia de seguridad activa (objetivo > 90 %) y restauraciones correctas (objetivo 100 %).
- **Retención:** a 7 y a 30 días.
- **Comunidad:** nota media mayor de 4,7, respuesta a todas las reseñas en menos de 48 h y traducción de los idiomas pendientes.

## 11. Riesgos principales

| Riesgo | Cómo mitigarlo |
|---|---|
| Que Shifter vuelva a actualizarse | Ir rápido y diferenciarse en copia de seguridad, horas e importación |
| Muchas apps nuevas en 2026 (Turnify, Shiftool…) que cobran por lo que aquí es gratis | Gratuidad total y código abierto, calidad, nada de anuncios, soporte rápido, contenido por colectivo |
| Un fallo de migración que borre datos | Matriz de restauración como requisito para publicar; copia automática antes de cada migración |
| Mantener los festivos cada año | Paquete de datos remoto y calendario de mantenimiento |
| Datos de salud (baja médica) | Solo en el móvil; nunca en el feed compartido |

## 12. Decisiones pendientes

- [ ] Nombre definitivo (comprobar en las tiendas y en marcas registradas).
- [ ] Qué funciones avanzadas entran en la primera versión gratuita (jornada anual, saldos de ausencias, libro de cambios, PDF, temas, exportación continua): todas serán gratuitas, falta decidir el orden.
- [ ] Repositorio público y web de soporte: decididos el 26-oct-2026, falta ejecutarlos. `LICENSE` (MIT) y `LICENSE-CONTENT.md` (CC BY-SA 4.0) **ya están en la raíz**: antes de publicar las fichas, el repositorio público tiene que ser accesible y las licencias, visibles desde él.
- [ ] ¿Lista inicial de municipios con festivos locales: 200 o solo las capitales de provincia?
- [ ] ¿Publicar por tu cuenta de desarrollador actual o por una nueva?
