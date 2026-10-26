# Diseño: dirección B «Noche» (claro y oscuro)

Elegida el 19-oct-2026 tras la ronda de propuestas (lienzo «Cuadrante · propuestas de diseño», filas B y «B en modo
claro»). Esta página manda sobre cualquier valor de color, tamaño o forma de la UI; los tokens viven en
`app/lib/core/theme/` y ningún widget usa valores sueltos.

## Idea
- **El turno, sin pensar.** Arriba, una tarjeta grande con el turno que importa ahora («Esta noche · Noche
  22:00–06:00 · Empieza en 3 h 40 min · Mañana: Noche»). La cuadrícula del mes va debajo.
- **Calma.** Celdas neutras con el **código grande en el tono del turno** y una **barra de color inferior**; un
  tinte muy suave del turno en el fondo de la celda para leer las semanas de lejos. Nada de bloques saturados.
- **Oscuro de verdad.** Pensada primero para la noche: fondo casi negro, tonos apagados, ámbar como acento. El modo
  claro es la misma estructura con otra paleta.
- **Nunca solo color:** cada día lleva código, hora y barra. Todo texto ≥ 4,5:1 sobre su fondo real.

## Tokens de color

| Token | Claro | Oscuro | Uso |
|---|---|---|---|
| `background` | `#F2F2F6` | `#0A0A0D` | Fondo de pantalla |
| `surface` | `#FFFFFF` | `#15151B` | Celdas del mes, tarjetas, hojas |
| `surfaceMuted` | `#ECECF1` | `#0F0F13` | Días de otro mes |
| `surfaceRaised` | `#F4F4F7` | `#1C1C23` | Botones redondos, fichas sin seleccionar |
| `border` | `#DCDCE2` | `#23232B` | Bordes suaves |
| `borderStrong` | `#C9C9D2` | `#34343E` | Bordes de controles |
| `textPrimary` | `#15151A` | `#ECECF1` | Texto principal |
| `textSecondary` | `#3A3A44` | `#C9C9D2` | Horas en la tarjeta, números de día |
| `textMuted` | `#5A5A64` | `#8E8E99` | Días de la semana, horas pequeñas, secundario |
| `accent` | `#4B4FD1` | `#A5A8FF` | Enlaces, interruptores, etiquetas |
| `highlight` | `#F5A524` | `#F5B547` | Cuenta atrás, icono del pincel, selección en oscuro |
| `onHighlight` | `#15151A` | `#0A0A0D` | Texto sobre `highlight` |
| `todayRing` | `#15151A` | `#F5B547` | Anillo de hoy y de la ficha seleccionada |
| `holiday` | `#D93036` | `#FF6369` | Número y punto de festivo |
| `primaryButton` / `onPrimaryButton` | `#15151A` / `#FFFFFF` | `#F5B547` / `#0A0A0D` | «Listo», botón principal |
| `fab` / `onFab` / `fabBorder` | `#15151A` / `#FFFFFF` / — | `#1C1C23` / `#F5B547` / `#34343E` | Botón «Pintar» (icono en `highlight`) |

## Color de cada turno

El usuario guarda **un** color por tipo (paleta por defecto de la especificación §4). La app deriva de él, al
pintar y nunca guardado, un `ShiftSwatch` por tema:

| Campo | Claro | Oscuro |
|---|---|---|
| `bar` (barra inferior, borde del trazo) | el color guardado | el guardado; si su luminancia < 0,15, aclarado hasta ≥ 0,15 (la Noche pasa a ≈ `#6B6EF0`) |
| `tint` (fondo de la celda del día) | mezcla 10 % del color sobre `surface` | mezcla 14 % sobre `surface` |
| `disc` (fondo de la ficha del modo pintar y del distintivo de la tarjeta) | mezcla 18 % sobre `surface` | mezcla 28 % sobre `surface` |
| `ink` (código y textos en el tono del turno) | el color oscurecido (luminosidad HSL) hasta ≥ 4,5:1 sobre `tint` **y** sobre `disc` | aclarado hasta ≥ 4,5:1 sobre `tint` y `disc` |

Valores de referencia (claro → oscuro): Mañana `ink` ≈ `#8F5A00` → `#F5B547`; Tarde ≈ `#B8401A` → `#FF8A66`;
Noche `#4B4FD1` → `#A5A8FF`; Vacaciones ≈ `#1D7A4F` → `#4CC38A`. **Libre** es especial: sin tinte, `bar`
`borderStrong`, `ink` `textMuted`. Días de otro mes: fondo `surfaceMuted`, sin tinte, código en `textMuted`, barra
al 45 % de opacidad (la barra no es texto).

## Tipografía
Fuente del sistema (SF Pro en iOS, Roboto en Android), sin fuentes incluidas. **Números tabulares** en la
cuadrícula, horas y cuentas atrás.

| Estilo | Tamaño / peso | Uso |
|---|---|---|
| `display` | 36 / 800, -0,6 | Nombre del turno en la tarjeta |
| `headline` | 24 / 800 | Cabecera del modo pintar |
| `title` | 21 / 750 | Mes («Octubre») |
| `bodyStrong` | 19 / 600 | Horas en la tarjeta |
| `body` | 15 / 400–600 | Texto general |
| `label` | 13 / 700, mayúsculas, +0,6 | «ESTA NOCHE», «PINTANDO» |
| `caption` | 12 / 600–700 | Días de la semana, etiquetas de fichas |
| `cellDay` | 11 / 650 (hoy 900) | Número del día |
| `cellCode` | 20 / 800 (14 con varios turnos) | Código del turno |
| `cellTime` | 10 / 600 | Hora compacta («22–06») |

Mínimos adaptativos de la cuadrícula: `AppTypography.cellCodeMinSize` y `cellTimeMinSize` (8 dp antes del escalado
del usuario). El código se mide por separado; la línea horaria reserva los 6 dp del indicador de dos tramos
(`Sp.cellSegmentDot`) y su separación. Cuando el inicio con minutos no cabe, conserva la hora («09» para «09:30»);
la etiqueta accesible y el detalle mantienen los minutos y los dos tramos.

La altura de las líneas de la casilla se **mide**, no se estima: el motor las dibuja en píxeles enteros, así que
la celda reserva la altura real del número, del código y de la hora (con la letra al 130 %, la línea real mide
hasta 0,4 dp más de la estimada). Si una celda es más baja que la que reserva la rejilla (la imagen que se
comparte, la vista previa del asistente), el código se encoge hasta caber en vez de desbordarse.

## Componentes

**Tarjeta de hoy** (arriba del mes): `surface`, radio 24, padding 18, barra inferior de 5 px en `bar` del turno.
Etiqueta según el momento: «AHORA» (turno en curso: «Noche hasta las 06:00»), «ESTA NOCHE» (empieza a partir de
las 20:00), «HOY» (empieza antes), «HOY LIBRE» (sin turno: muestra el próximo, «Próximo: Mañana, mié 06:00»),
«HOY TERMINADO» (el último turno de hoy ya acabó: nombre del turno, «Terminó a las 22:00» y el próximo turno; no es un
día libre).
`display` con el nombre, `bodyStrong` con las horas, distintivo de 56×56 radio 18 (`disc` + `ink` con el código).
Debajo, ficha `highlight` con la cuenta atrás («Empieza en 3 h 40 min», se actualiza cada minuto) y la línea de mañana en
`textMuted`, con la fecha para que «mañana» no se lea como un turno llamado Mañana: «Mañana (mié 21): turno de Tarde» /
«Mañana (mié 21): sin turno». Varios turnos hoy: el siguiente que empieza manda; los demás en una línea «+ Tarde 14:00–22:00».
**Turno partido** (A12): entre sus dos tramos la etiqueta es «DESCANSO», con «Vuelves a las 17:00» y la ficha «Vuelves
en 2 h 45 min»; dentro de cada tramo es «AHORA» con «Hasta las 13:00» / «Termina en…». El segundo tramo no sale como
otro turno en la línea «+ …». Antes del primero, la línea de horas lleva los dos: «09:00–13:00 · 17:00–21:00».

**Márgenes de la pantalla del mes**: todo (cabecera, tarjeta de hoy, consejo, fila del mes con sus flechas y la
cuadrícula) respeta `Sp.l` (16 dp) a cada lado. La cuadrícula lo consigue con 14 dp de relleno más los 2 dp que
lleva cada casilla; los botones de 48 dp con el glifo de 24 dp van a 4 dp del borde. La fecha de la cabecera sale
entera («Martes, 20 de octubre») y, si no cabe en una línea (texto grande, 320 dp), en forma corta («Mar 20 oct»);
nunca se recorta con puntos suspensivos ni a media palabra.

**Celda del día**: `surface` + `tint`, radio 12, alto ≥ 62. Número arriba a la izquierda (`cellDay`,
`textSecondary`); código centrado abajo (`cellCode`, `ink`) y hora (`cellTime`, `textMuted`); **barra inferior de
6 px** (`bar`; con varios turnos, segmentos iguales y códigos apilados). **Turno partido:** la hora de la casilla es
«09–13/17–21» y solo se dibuja si cabe en el ancho de la casilla a su tamaño (`shiftTimeFitsInCell`, con el texto
del usuario); si no, la casilla dice la hora de inicio del primer tramo («09»), porque nunca se queda solo con el
código (los dos horarios están en el detalle del día). Festivo: número en `holiday` + punto de
6 px arriba a la derecha. Nota: clip de 11 px arriba a la derecha (si hay festivo, el clip a la izquierda del punto).
Hoy: anillo interior de 2 px `todayRing` y número en 900. Día vacío: solo `surface`, sin barra.
El contenido de la casilla (código, icono y hora) se dibuja **dentro** del borde más grueso que
dibuja la casilla (3,5 dp de margen a cada lado), de modo que el borde de un día elegido nunca
tapa el código ni la hora; el margen se reserva siempre, para que el código no cambie de tamaño
al elegir el día.
**Icono del turno** (A8): va **delante del código**, de 12 dp (escalado con el texto) en la `ink` del turno, y solo si
icono + 2 dp + código al tamaño normal caben dentro del borde de la casilla (3,5 dp a cada lado) con 1 dp de margen a
cada lado (`shiftIconFitsInCell`); si no, la casilla enseña solo el código, nunca un código más pequeño por culpa del icono. Con
varios turnos en el día nunca hay icono. En una casilla de ~42 dp (móvil de 320 dp) un código de una letra lleva
icono con el texto al 100 % y no al 130 %; los códigos de 2-3 letras solo lo llevan en pantallas anchas. **Horas extra /
salí antes** (A6): un «+» de 11 px (`AppIcons.extras`, `textMuted` del tono del turno) arriba a la derecha, en la fila
del número del día y delante del clip de la nota y del punto de festivo (esa fila no la invade nunca el código ni la
hora; en una casilla muy estrecha la fila encoge hasta el 60 % en vez de salirse); el texto leído de la casilla dice «horas extra: 1 h 30 min» / «salida anticipada: 30 min».
En el distintivo de 44 px (lista de turnos, detalle del día), en las fichas redondas de pintar y en la leyenda el
icono va encima del código (12-14 dp) o delante del nombre; el código no desaparece nunca.

**Modo pintar**: cabecera «PINTANDO» (`label` en `ink` del turno elegido) + «Tarde · 14:00–22:00» (`headline`) y
botón «Listo» (`primaryButton`). Abajo, hoja `surface` radio 26 con: fila de **fichas redondas** de 54 px (`disc` +
`ink`, etiqueta `caption` debajo; la seleccionada con anillo de 2,5 px `todayRing` separado 3 px; «Borrar» con borde
`borderStrong`), y fila con «Doblar» (chip con borde), Deshacer y Rehacer (círculos de 48 px en `surfaceRaised`).
Durante el trazo, las celdas tocadas se rellenan con `disc` y anillo de 2 px en `bar`.
La cabecera mide **siempre lo mismo** al cambiar de herramienta (el mes de debajo no se mueve): el título es una línea,
con puntos suspensivos solo en el nombre y las horas enteras; si el título más largo de la paleta no cabe junto a los
botones (texto grande, 320 dp), baja a una línea propia bajo ellos para todas las herramientas. «PINTANDO» se reduce
antes de partirse. Las fichas se ensanchan con el tamaño de texto y parten el nombre entre palabras («Libre /
disposición»), nunca lo abrevian. **Las fichas saltan de línea** (`Wrap`), nunca una fila que se desplaza de lado y
corta la última a media palabra (H-T17-3); con muchos turnos, el área de herramientas se desplaza en vertical y no pasa
del 25 % del alto de la pantalla. En el panel derecho (dos paneles) la hoja es una tarjeta con el margen `Sp.l` de las
demás y las cuatro esquinas redondeadas (H-T17-7). En ese panel ocupa toda la altura disponible entre la cabecera y las acciones: fichas en rejilla con desplazamiento vertical y Deshacer/Rehacer siempre accesibles. El límite del 25 % se conserva solo en una columna.

**Detalle del día** (hoja inferior, `surface` radio 26, **alto fijo** del 88 % del espacio: lo que no cabe se
desplaza dentro y la hoja no salta al escribir, activar el festivo o quitar un turno; la cabecera con la fecha queda
fuera del desplazamiento, así que arrastrarla hacia abajo cierra la hoja como el asa): fecha en `headline`, festivo en
`holiday` (sin repetir la palabra: «Festivo propio», «Festivo: Fiesta Nacional de España»), una fila por
turno (distintivo de 44 px con `disc` + `ink`, nombre `bodyStrong`, hora `body` en `textSecondary`, subir / bajar /
quitar a 48 px), debajo la fila de fichas redondas de 44 px (como las de pintar, con salto de línea y los nombres enteros)
para añadir o «doblar», «Volver al
patrón» (botón con borde) con lo que da la rotación en `meta`, la nota (campo `surfaceMuted`, 2 líneas mínimo), el
interruptor «Festivo propio», la sección «Horas extra / Salí antes» (dos contadores con «−» y «+» de 15 min y el valor
en `body` en negrita, «Ninguna» si es 0; el valor se escribe tras 600 ms sin tocar o al cerrar la hoja, así que una
tanda de toques es un solo paso de deshacer; con texto grande la etiqueta pasa a su propia línea) y los atajos
«Duplicar en otro día» y «Borrar día» (botones con borde; los dos cierran la hoja y avisan con una barra, «Día borrado» con
«Deshacer»). Cada cambio es un paso de deshacer. Los botones de icono desactivados (subir la primera fila, bajar la
última) usan `disabledContent`, el texto atenuado, para no parecer activos.

**Mis turnos** (Ajustes): lista de tarjetas `surface` radio 16 con el distintivo del turno, «horas · categoría ·
precio», archivar y asa para arrastrar; «Nuevo turno» fijo abajo. El formulario va de arriba abajo: nombre, código,
**vista previa** (la celda real en claro y en oscuro, con el contraste del código impreso debajo), rejilla de colores
(los 8 de la especificación y 16 más, círculos de 44 px; el elegido con anillo `todayRing` y marca de verificación),
categoría y opciones en **píldoras** (`ChoicePill`: borde `borderStrong`; la elegida con anillo de 2 px `todayRing`, marca
y negrita), horario (interruptor «Sin horario» y dos botones de hora de 24 h) y, solo en turnos de trabajo con
horario, descanso no pagado, turno nocturno y precio por hora. El campo **Icono** (opcional; debajo de la categoría)
es un botón con el icono actual o «Sin icono» que abre una hoja con una rejilla de blancos de 48 px: «Sin icono» y los
30 símbolos de la lista cerrada `ShiftIcon`; el elegido con anillo `todayRing` y marca de verificación, y cada uno
con su nombre para el lector de pantalla.

**Botón «Pintar»** (FAB extendido): ver tokens `fab`; alto 56, radio 28, icono de pincel en `highlight`.

**Widgets**: misma lógica que la tarjeta de hoy (pequeño), tira de 7 días con barras (mediano), mes en miniatura
(grande); fondo `surface` del tema del sistema; barra inferior en el pequeño.

**Icono de la app**: cuadrícula 3×3 sobre `#141418`, casillas con radio ≈ 4 % del lado; la **fila central** en
Mañana `#F5A524`, Tarde `#F06A3F` y Noche `#4B4FD1`; el resto `#2A2A31`.

**Texto grande y pantallas estrechas** (campaña de pruebas T04-T07): nunca se parte una palabra ni una cifra; se
envuelve entre palabras o se cambia de disposición. Los controles del mes (vista anual, resumen, «Hoy» y las flechas)
se reparten en dos filas, en el mismo orden de lectura, cuando no caben en una (320 dp con letra grande en inglés),
sin bajar de 48 dp de objetivo táctil. `ValueRow` apila el valor bajo el título (hasta 3 líneas,
alineado con él); `AdaptiveButtonRow` apila dos botones (el principal arriba) cuando la palabra más larga de una
etiqueta no cabe; las barras de herramientas con nombre bajo cada botón (selección de días) miden su palabra más
larga y, desde texto ×1,6, quedan solo con el icono y el nombre como tooltip. Los rangos de horas se escriben con
`keepTimeRangesTogether`. **Avisos** (`SnackBar`): siempre con `appSnackBar` (6 s; si hay acción y lector de pantalla, permanece hasta actuar o cerrarlo) y, sobre el mes, con `showTrackedSnackBar`, que reserva su alto bajo la rejilla. **Archivados**: lo que se
archiva (turnos, calendarios) se recupera desde una sección plegable «Archivados (n)» al final de su lista, con
«Recuperar». **Salir con cambios**: un formulario con datos sin guardar pregunta «¿Descartar los cambios?»
(«Seguir editando» / «Descartar»).

## Mes: Cuadrícula / Lista (decisión D, 26-oct-2026)

El mes ofrece dos presentaciones mediante etiquetas visibles **«Cuadrícula» / «Lista»**. El control está encima de
la navegación del mes en todos los modos, incluidos Pintar y Selección. Sus blancos táctiles y semánticos miden
al menos `Sp.touch` (48 dp), y el `Wrap` pasa los controles a otra línea sin reducir el texto. Permanece accesible
al desplazar los días: reserva toda su altura natural, también cuando el texto grande hace que el `Wrap`
ocupe varias líneas. Las dos opciones quedan siempre visibles y pulsables sin desplazar el selector;
solo se desplazan los días. «Seleccionar días» comparte la fila fija inferior con los botones de desplazamiento
de Pintar, para reservar sitio a ambas presentaciones y a los días. **Nunca se cambia de presentación automáticamente.**
La elección dura toda la sesión,
también al navegar a otra pantalla, cambiar de mes/calendario y girar el dispositivo; no se escribe en ajustes.

La opción Lista se destaca con fondo y borde cuando `(anchoPanel − 28 − columnaSemanas) / 7 < 48 dp`
(`columnaSemanas` = 24 dp si está activada), cuando el escalado real del estilo de código u horario alcanza
×1,5, o si medir el contenido predice reducción/omisión en la cuadrícula (incluidos varios turnos). El aviso
accesible/tooltip explica «Lista recomendada para ver los horarios completos y el texto grande». Es una
recomendación, no una afirmación de que las casillas compactas cumplan 48 dp o ampliación íntegra al 200 %.

**Lista del mismo mes:** usa `Schedule.resolve` y `CivilDate`, muestra todos sus días (también vacíos) y ningún
día gris de los meses vecinos. Agrupa por semanas con el inicio configurado; la cabecera dice las fechas del
grupo y, si está activo, el mismo número ISO que la cuadrícula. Comparte anterior/siguiente y Hoy; no es la
Agenda general ni tiene su límite de próximos días. La Agenda no cambia.

**Fila adaptable:** tarjeta `surface`, radio `Rad.row`, margen lateral `Sp.l`, relleno `Sp.m` y separación `Sp.s`.
Fecha con `bodyStrong`; Hoy como texto; selección con borde grueso y la palabra «elegido», además del fondo.
Cada turno lleva su propio bloque `tint`, barra `bar`, código `bodyStrong` y nombre/horario `body` en su `ink`.
Cada tramo ocupa una línea propia y conserva minutos y cruce de medianoche (por ejemplo, `09:30–13:00`,
`17:15–21:00`, `22:15–06:15`). No hay elipsis, `FittedBox`, tamaño mínimo impuesto ni reducción del texto.
Se muestran festivos oficiales y propios (también cuando coinciden), indicador de nota y minutos de extras o
salida anticipada; el detalle del día permite leer/editar su contenido completo.

**Mismas acciones e historial:** toque/Intro/Espacio abren el mismo detalle, pintan con `PaintController` o
alternan el día mediante `SelectionController`, según el modo. En la Lista **arrastrar solo desplaza** y cada
toque de pintura es un paso de deshacer; borrar y doblar usan las herramientas existentes. «Seleccionar días»
permite entrar sin pulsación larga en ambas presentaciones, y conserva todas las operaciones de la barra
(turno, doblar, borrar, patrón, nota, copiar/cortar/pegar y repetir), además de deshacer/rehacer.
La selección se conserva por calendario durante la sesión: al cambiar a otro no se aplica la elección del
anterior; al volver se recupera. Cambiar de presentación no escribe datos ni añade historial.

**Foco y lectura:** cambiar de presentación emite un solo anuncio («Presentación de lista/cuadrícula») y
solicita foco en el último día usado, abierto o seleccionado dentro del mes (si no, Hoy o su primer día).
Reconstruir no vuelve a anunciar. Tab recorre las filas en orden; flechas arriba/abajo e izquierda/derecha
avanzan un día en Lista; Intro/Espacio activan sin repetir por mantener la tecla. La cuadrícula conserva su
movimiento vertical de una semana y sus acciones accesibles. El foco desplaza la fila hasta hacerla visible.

Textos propuestos en los cinco ARB: Cuadrícula/Quadrícula/Cuadrícula/Sareta/Grid;
Lista/Llista/Lista/Zerrenda/List; Seleccionar días/Selecciona dies/Seleccionar días/Hautatu egunak/Select days.
Los avisos y anuncios también están localizados; no se añaden sufijos a variables en euskera.

## Pantallas anchas (horizontal y tablet)

Decidido con el usuario el 22 oct 2026 (opción A). En pantallas anchas el mes pasa a **dos paneles**: el mes a la
izquierda y, a la derecha, el detalle del día elegido o, sin día, la tarjeta de hoy y los próximos días. El móvil en
vertical no cambia en nada.

**Cuándo hay dos paneles** (`Adaptive.useSplit`, sobre el tamaño de la ventana entera, que el teclado no cambia):
ancho ≥ 840 dp (la clase «expandida» de Material), o ancho ≥ 600 dp y la ventana más ancha que alta (horizontal).

| Pantalla | Tamaño (dp) | Resultado |
|---|---|---|
| Móvil vertical (Pixel 9) | 412 × 915 | una columna, como siempre |
| Móvil horizontal | 915 × 412 | dos paneles |
| Tableta horizontal (Pixel Tablet) | 1280 × 800 | dos paneles |
| Tableta vertical | 800 × 1280 | **una columna** |

La tableta vertical se queda en una columna a propósito: 800 dp no llegan a 840, y con dos paneles el mes se quedaría
en unos 480 dp y el detalle en una tira de 320 dp, peor que la rejilla de 640 dp centrada y una hoja inferior con el
resto de la pantalla para el mes. Una ventana de 1024 × 1366 (iPad grande en vertical) sí tiene dos paneles.

**Panel izquierdo: el mes.** Cabecera del mes con sus flechas, fila de días y rejilla, igual que en el móvil, pero con
toda la altura: la fecha, los tres botones y la tarjeta de hoy se van al panel derecho. Las filas se reparten la altura
(sin pasar de 1,5 veces el ancho de la celda). Una fila nunca baja de lo que hace falta para ver el **horario bajo el
código** al tamaño de texto del usuario (`dayCellHeightWithTime`, como mucho 80 dp): en un móvil horizontal (412 dp de
alto) eso son unos 64 dp por fila y el mes se desplaza un poco en vez de quedarse en códigos sueltos. Al pintar se
conserva esa altura: arrastrar por las casillas pinta; los botones de subir y bajar, fuera de la rejilla, desplazan
el mes por páginas con una fila en común. Así siguen accesibles las seis filas aunque la cabecera ocupe dos líneas.

**Panel derecho.** Ancho = 40 % de la ventana, entre 300 y 440 dp (366 dp en un móvil de 915 dp, tan ancho como un móvil
en vertical, que es para lo que están hechos sus contenidos; 440 dp en una tableta). Un filete `border` de 1 dp lo
separa del mes. Arriba, la fecha y los botones (compartir, agenda, ajustes) y el selector de calendario. Con un día abierto, la cabecera muestra solo su fecha y «Hoy» permite volver; el detalle no repite la fecha. Debajo:
- **Sin día abierto:** la tarjeta de hoy, el consejo del primer uso y **Próximos días**: los 7 días siguientes a hoy en
  una tarjeta con filas compactas (día de la semana y número, ficha de 28 dp con el código, nombre y horario de cada
  turno, «Sin turno» si no hay, un clip si tiene nota; el número en `holiday` si es festivo). Tocar una fila abre ese
  día.
- **Con un día abierto:** el mismo contenido y las mismas acciones que la hoja inferior (turnos, nota, aviso, festivo
  propio, horas extra, saltar alarma, duplicar y borrar), en `DayDetailBody`, que usan la hoja y el panel. En vez del
  asa de la hoja, un botón de cerrar a la derecha del título; cerrar, o el botón atrás del sistema, vuelve a la
  tarjeta de hoy. «Duplicar en otro día» y «Borrar día» también cierran el día, como cerraban la hoja.
- **Modo pintar y modo selección:** su cabecera arriba y su barra de herramientas abajo, **dentro del panel derecho**
  (no a lo ancho de la pantalla): en un móvil horizontal una barra a todo lo ancho se comería media pantalla y dejaría
  el mes en dos filas. Deshacer y rehacer siguen en la barra. El botón «Pintar» flota sobre el panel derecho y el
  área visible del contenido que se desplaza termina 72 dp por encima del borde inferior (alto del botón más margen),
  para que ningún control pase por detrás. «Pintar» se oculta mientras está abierto el teclado, también en el móvil.
  La barra de selección del panel distribuye sus etiquetas visibles en dos filas; con texto grande crece hacia abajo y se desplaza, sin truncar ni reducir las zonas táctiles. Los avisos flotantes en ventanas de al menos 600 dp no superan 560 dp de ancho; con dos paneles se colocan sobre el
  mes, a la izquierda, para dejar libres las barras de selección y pintar. En el móvil vertical mantienen sus márgenes.

**Día abierto en la rejilla.** El día que se ve en el panel lleva un **anillo** de `Sp.selectionRing` (2,5 dp) en el
color de selección (acento en claro, ámbar en oscuro), sin velo ni marca de verificación (eso es de elegir varios días).
Hoy sigue con su anillo fino y su número en negrita. El día abierto se cierra al entrar en pintar o en selección y al
cambiar de calendario.

**Girar el móvil o la tableta** cambia de una columna a dos paneles y al revés (en todos los móviles y tabletas, porque
vertical es una columna y horizontal son dos). El mes visible, el modo pintar con su pincel y el día abierto están en
estado de Riverpod y sobreviven: con un día abierto, de dos paneles a una columna el día vuelve como hoja inferior, y de
una columna a dos paneles la hoja se cierra y el día pasa al panel. La nota que se está escribiendo pasa de un campo al
otro con su texto (se guarda cada vez que cambia la disposición, un paso de deshacer por cada guardado). Una hoja abierta
desde otra pantalla (la agenda) sigue siendo modal.

**Otras pantallas.** Ajustes, resumen, año, agenda, copia de seguridad, importar y exportar, turnos, alarmas, festivos,
calendarios, el asistente de patrón y el primer uso usan `PageBody`, que centra el contenido y lo limita a
`Sp.maxContentWidth` (640 dp): no se estiran de borde a borde. Las hojas (`showAppSheet`) tienen el mismo tope, y los
diálogos de Material no pasan de 560 dp. El primer uso en horizontal (menos de 480 dp de alto) desplaza la cabecera con
el paso y deja «Siguiente» fijo abajo.

## Movimiento y tacto
Cambios de estado 200 ms `easeOutCubic`; respeta «reducir movimiento». Vibración ligera (`selectionClick`) por cada
día pintado; ninguna animación infinita.

## Asistente de patrón y vista anual
- **Asistente de patrón** (`/patron`, tres pasos con una barra de tres segmentos y «Paso 1 de 3»): tarjetas `surface`
  de radio `Rad.row` con el nombre, el ciclo («28 días») y la secuencia como **fichas pequeñas** (`Disc.s`, `disc` +
  `ink` del turno, el código siempre visible). La elegida lleva el borde `todayRing` y un check, no solo color. Las
  fichas del selector de día del ciclo son `Disc.m`, con el número del día debajo. La vista previa son dos meses
  con la misma `DayCell` de la pantalla del mes.
- **Vista anual** (`/ano`): cada día es un cuadrado con la `bar` del turno (varios turnos: franjas verticales),
  `surfaceMuted` si no hay turno, un punto `holiday` en los festivos y un anillo `todayRing` en hoy; 3 columnas en
  móvil (4 desde 600 dp). Cada mes se lee en voz alta como sus recuentos («Octubre 2026: 8 Noche, 5 Libre»). La
  leyenda usa cuadrados de 14 dp (`Rad.swatch`) con código, nombre y días del año.

## Icono y pantalla de arranque
Todo sale de un solo guion, `tool/icon/make_icon.py` (Python + Pillow), con los colores y proporciones de «Icono de
la app» arriba: cuadrícula 3×3 de ≈ 60 % del lienzo, separación del 6 % de la cuadrícula, radio del 4 %. Si cambia el
diseño, se cambian las constantes del guion y se regenera; los PNG no se retocan a mano.

| Archivo (`app/assets/icon/`) | Qué es |
|---|---|
| `icon.png` | 1024 px, a sangre y **sin alfa**. Origen de los mipmaps de Android (icono clásico) y del `AppIcon` de iOS (`remove_alpha_ios`). |
| `foreground.png` | Capa frontal del icono adaptable de Android: transparente, solo la cuadrícula. `flutter_launcher_icons` la mete con un margen del 16 % por lado, así que el PNG va dibujado más grande y, ya colocada, la cuadrícula mide el 46 % de los 108 dp y cabe en la zona segura (círculo de 66 dp; el guion lo comprueba). |
| `monochrome.png` | Icono tematizado de Android 13: blanco sobre transparente, fila central opaca y el resto con menos alfa. Misma geometría que la capa frontal. |
| `splash.png` | Pantalla de arranque: solo la cuadrícula (520 px) en un lienzo transparente de 1152 px; cabe en el círculo de 192 dp de Android 12. Sin texto ni marca. |

El fondo del icono adaptable es `#141418` (en `values/colors.xml`). Las vistas previas a 48 y 96 px, con la máscara
cuadrada redondeada de iOS y la circular de Android, están en `tool/icon/preview/` (`icon_*`, `adaptive_*`,
`monochrome_*`); se regeneran con el guion.

**Pantalla de arranque**: fondo claro `#F2F2F6` y oscuro `#0A0A0D`, que son `background` del tema
(`app_colors.dart`), y la misma imagen en las dos. Así la primera imagen de Flutter (`scaffoldBackgroundColor`) tiene
el mismo fondo que el arranque nativo y no hay salto. En Android 12+ la imagen va en el círculo del sistema con el
mismo color de fondo, así que el círculo no se nota. La lectura de la base de datos y las preferencias se hace antes de
`runApp`, de modo que el arranque nativo se queda hasta que sale la pantalla real: no hay pantalla de carga de Flutter
en medio. Si la persona fuerza un tema distinto al del sistema, el arranque sigue el del sistema (una limitación de las
pantallas nativas).

**Regenerar** (desde la raíz del repositorio):
1. `python tool/icon/make_icon.py`: los cuatro PNG y las vistas previas.
2. `bash tool/icon/apply_icons.sh`: `dart run flutter_launcher_icons` y, después, deshace lo que el plugin estropea en
   iOS (reescribe `Contents.json` con tamaños de iOS 6 y toca un ajuste de compilación de Xcode).
3. `bash tool/icon/apply_splash.sh`: `dart run flutter_native_splash:create` y restaura `ios/Runner/Info.plist`, que el
   plugin reindenta entero.

Las dos herramientas están fijadas en `app/pubspec.yaml` (`flutter_launcher_icons` 0.14.4, `flutter_native_splash`
2.4.8) y su configuración son las secciones del mismo nombre de ese archivo. Lo generado va al repositorio (mipmaps,
XML del icono adaptable, `AppIcon.appiconset`, recursos de arranque de Android y `LaunchScreen` de iOS).
