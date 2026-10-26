# Capturas de tienda · plan de v1

> **Borrador · 26-oct-2026. La app es totalmente gratuita y de código abierto** (decisión del usuario): sin compras, sin suscripciones, sin anuncios y sin cuentas. No hay ningún precio que incluir en las imágenes. «Cuadrante» es provisional (pregunta 5).

Plan de **8 capturas para App Store y 8 para Google Play**, en es, ca, gl, eu y en. Solo planificación: no se han generado imágenes ni ejecutado emuladores. V1 de iOS solo para iPhone; **iPad no entra en v1** (pregunta 17). Política de privacidad o texto legal que se necesite en una superficie enlazada: **(la redacta el usuario)**.

Todas las capturas muestran funciones que deberán estar disponibles y verificadas en el candidato de cada plataforma: la app es totalmente gratuita y de código abierto, sin compras y sin anuncios. Los pies hablan de funciones; el mensaje de gratuidad y código abierto va en la ficha (descripción y texto promocional), no en las imágenes.

Fuentes: [especificación](../../turnos-spec.md), [mercado](../analisis-mercado.md), [paridad actualizada del 23-oct](../paridad.md), [plan de publicación](../plan-publicacion.md), [preguntas](../preguntas.md), [glosario](../glosario-idiomas.md) y [diseño B «Noche»](../diseno.md). Los textos de botones se toman del ARB del idioma: no se dibujan botones ficticios.

## Tamaños y entregables

| Código | Tienda / dispositivo | Lienzo vertical de entrega | Aplicación |
|---|---|---|---|
| I69 | App Store · iPhone 6,9″ | 1320 × 2868 px | AS01–AS08, cinco idiomas |
| I65 | App Store · iPhone 6,5″ | 1242 × 2688 px | AS01–AS08, cinco idiomas |
| A | Google Play · teléfono Android | 1080 × 1920 px (9:16) | GP01–GP08, cinco idiomas |

**80 imágenes de iPhone** (8 × 2 tamaños × 5 idiomas) y **40 de Android** (8 × 1 × 5): **120 entregables previstos**. Son ocho mensajes por tienda, no dieciséis capturas en una misma galería de iPhone. Verificar las dimensiones admitidas y los grupos de dispositivos en las consolas al producirlas.

Para Android, 1080 × 1920 mantiene el lado largo por debajo del doble del corto y supera los mínimos de resolución. Si el dispositivo de captura tiene otra relación de aspecto, colocar su captura real completa en este lienzo con un margen de diseño; no estirar ni cortar contenido funcional para simular otra pantalla. En iPhone, componer cada tamaño desde su captura correspondiente, respetando áreas seguras; no reescalar una imagen hasta deformarla.

Nombres de entrega: `app-store/{es,ca,gl,eu,en}/{I69,I65}/01.png` a `08.png`; `google-play/{es,ca,gl,eu,en}/A/01.png` a `08.png`. Son rutas de entrega futuras; esta tarea no las crea.

Las versiones ca/gl/eu se preparan aunque haya que **verificar** su disponibilidad como localización de metadatos en App Store Connect; no asignar un idioma a la ficha de otro.

## Datos ficticios comunes

- Zona **Europe/Madrid**, formato de 24 h. Mes principal: **diciembre de 2026**. Fijar «hoy» con el reloj de pruebas, no alterar el reloj del ordenador.
- Calendario principal «Demo» y otro vacío «Industria» para la vista previa de un patrón. Los nombres son ficticios y no identifican a nadie.
- Turnos: Mañana 06:00–14:00, Tarde 14:00–22:00, Noche 22:00–06:00 del día siguiente; Saliente y Libre son descanso. Traducir los nombres y códigos con las plantillas del idioma.
- Asignaciones de «Demo»: Mañana el 1, 2, 3 y 4; Tarde el 10 y 11; Noche el 23, 24 y 25; Saliente el 26. El resto, libre o sin turno. No activar saliente automático para no sustituir las noches consecutivas de esta muestra.
- Resultado de referencia del mes: **9 turnos de trabajo, 72 h totales, 24 h nocturnas y 8 h en el festivo del 25 de diciembre**. Seis horas festivas vienen de la noche que empieza el 24 y dos de la que empieza el 25. No hay extras ni salidas anticipadas. Las horas nocturnas y festivas pueden coincidir; no sumarlas como categorías excluyentes.
- Elegir Comunidad de Madrid y municipio Madrid. Para los locales de otra captura, usar el paquete verificado de 2026: 15 de mayo y 9 de noviembre **solo si están efectivamente incluidos para ese municipio**; si no lo están, añadirlos manualmente tras contrastarlos en la fuente oficial del paquete. No simular cobertura automática que no exista.
- Sin precio por hora ni plus fijo en esta muestra: mostrar el desglose de horas, sin importes inventados. No incluir jornada anual, saldo contra convenio ni plus por hora nocturna/festiva.
- Nota ficticia opcional: «Formación» y equivalente localizado. Sin nombres de compañeros, datos de salud, correos, teléfonos, calendarios personales, fotos ni archivos reales de usuarios.
- Crear una copia local verificada de esta muestra y conservar una exportación fuera de la app para reponer el estado. Para LRHSoft, usar una copia `.Shifter` sintética compatible que contenga esos turnos; no usar la copia real de investigación.
- Restablecer el estado antes de cada composición. El ensayo de pintar y el de importación no deben duplicar ni modificar las horas que se enseñan en el resumen.

## Orden de ambas galerías

| Mensaje | App Store | Google Play | Pantalla / contenido | Tamaños |
|---|---|---|---|---|
| 1 | AS01 | GP01 | Inicio · mes y tarjeta de hoy | I69, I65 / A |
| 2 | AS02 | GP02 | Modo pintar · patrón con vista previa | I69, I65 / A |
| 3 | AS03 | GP03 | Escritorio del sistema · widget nativo | I69, I65 / A |
| 4 | AS04 | GP04 | Ajustes › Copia de seguridad · prueba de restauración | I69, I65 / A |
| 5 | AS05 | GP05 | Ajustes › Importar turnos · copia de LRHSoft | I69, I65 / A |
| 6 | AS06 | GP06 | Ajustes › Festivos · comunidad y municipio | I69, I65 / A |
| 7 | AS07 | GP07 | Resumen del mes · horas nocturnas y festivas | I69, I65 / A |
| 8 | AS08 | GP08 | Ajustes › Apariencia › Idioma | I69, I65 / A |

Todas las capturas muestran funciones que deberán estar disponibles y verificadas en el candidato de cada plataforma. No poner marcas de plan, de pago ni de suscripción sobre widgets, copias, importación ni horas nocturnas/festivas. No enseñar pantallas futuras como si ya existieran.

## Composiciones y pies localizados

Los números entre paréntesis son recuentos de caracteres Unicode NFC del pie, incluidos espacios y signos, sin comillas ni salto final. No son texto de la imagen. Objetivo editorial: **45 caracteres como máximo**, una o dos líneas según idioma, sin reducir el tamaño de letra para encajar.

### 1. El mes que vas a trabajar · AS01 / GP01

- **Pantalla:** Inicio, calendario de diciembre de 2026 y tarjeta de hoy.
- **Datos de demostración:** Estado «Demo» común; hoy 24-dic a las 18:00. Destacar Noche 22:00–06:00 y mañana Noche, con color, código y hora. Tema oscuro B «Noche»; el mes queda legible completo.
- **Variante por tienda:** AS01: captura de la app iOS real. GP01: la misma vista Flutter con los controles Android reales. Sin iPad ni panel de tablet.
- **Tamaños:** App Store I69 e I65; Google Play A, según la tabla de dimensiones.

| Idioma | Pie | Caracteres |
|---|---|---:|
| es | Tus turnos, de un vistazo | 25 |
| ca | Els teus torns, d’un cop d’ull | 30 |
| gl | As túas quendas, dunha ollada | 29 |
| eu | Zure txandak, begirada batean | 29 |
| en | Your shifts at a glance | 23 |

### 2. Pintar y aplicar una rotación · AS02 / GP02

- **Pantalla:** Modo pintar y asistente de patrón, con la vista previa mensual visible.
- **Datos de demostración:** Usar «Industria», inicialmente vacío: patrón M M T T N N L L L L, inicio 1-dic-2026. Mostrar el paso real de vista previa antes de aplicar; no cambiar el calendario «Demo». Nombres y códigos localizados (eu: Goi/Arr/Gau, sin confundir Goiza con Gaua).
- **Variante por tienda:** AS02/GP02: enseñar la pantalla de vista previa que exista en cada build. Una captura por tienda, sin inventar un montaje de controles de pasos distintos. El botón de pintar o las fichas deben ser reconocibles.
- **Tamaños:** App Store I69 e I65; Google Play A, según la tabla de dimensiones.

| Idioma | Pie | Caracteres |
|---|---|---:|
| es | Pinta días o aplica tu patrón | 29 |
| ca | Pinta dies o aplica el teu patró | 32 |
| gl | Pinta días ou aplica o teu patrón | 33 |
| eu | Margotu egunak edo aplikatu eredua | 34 |
| en | Paint days or apply your pattern | 32 |

### 3. El widget cambia de fecha · AS03 / GP03

- **Pantalla:** Escritorio con el widget nativo de hoy/mañana y, si cabe de forma legible, el semanal.
- **Datos de demostración:** Calendario «Demo». Capturar dos estados reales, 24-dic 23:59 y 25-dic 00:01, para comprobar el cambio; elegir la captura del día 25 para la entrega. La noche iniciada el 24 aún puede aparecer como turno en curso: respetar el comportamiento real, sin retocar fechas ni textos.
- **Variante por tienda:** AS03: WidgetKit en iPhone, pendiente de implementación y prueba de siete días en el Mac. GP03: widget Android 2×2 o 4×2 real. Permisos de alarmas/recordatorios concedidos donde proceda; comprobar restricciones del sistema. No prometer actualización exacta a las 00:00 ni duración ilimitada sin abrir la app.
- **Tamaños:** App Store I69 e I65; Google Play A, según la tabla de dimensiones.

| Idioma | Pie | Caracteres |
|---|---|---:|
| es | El widget cambia de día solo | 28 |
| ca | El widget canvia de dia sol | 27 |
| gl | O widget cambia de día só | 25 |
| eu | Widgetak eguna berez aldatzen du | 32 |
| en | A widget that changes day on its own | 36 |

### 4. Una copia que puedes poner a prueba · AS04 / GP04

- **Pantalla:** Ajustes › Copia de seguridad, con la tarjeta real del resultado de «Probar restauración».
- **Datos de demostración:** Copia local del estado «Demo», recién creada. Ejecutar la comprobación y mostrar su resultado correcto, la fecha real de prueba y el botón con su nombre localizado. No dibujar un éxito ni un contador que no haya producido la app.
- **Variante por tienda:** AS04/GP04: mismo recorrido en cada plataforma. Solo copia local y archivo exportable; sin logotipo iCloud/Drive ni promesa de nube automática. Mantener visible cualquier aviso pertinente de la pantalla.
- **Tamaños:** App Store I69 e I65; Google Play A, según la tabla de dimensiones.

| Idioma | Pie | Caracteres |
|---|---|---:|
| es | Comprueba tu copia antes de restaurar | 37 |
| ca | Comprova la còpia abans de restaurar | 36 |
| gl | Comproba a copia antes de restaurar | 35 |
| eu | Egiaztatu kopia leheneratu aurretik | 35 |
| en | Check your backup before restoring | 34 |

### 5. Migrar desde LRHSoft · AS05 / GP05

- **Pantalla:** Asistente de importación › Copia de LRHSoft, en la asociación de turnos o en su vista previa.
- **Datos de demostración:** Archivo .Shifter sintético; usar un calendario de destino vacío para evitar conflictos. Mostrar Mañana/Tarde/Noche y sus correspondencias con código y hora. Elegir la vista previa antes de guardar y descartar después de capturar, para no duplicar el resumen.
- **Variante por tienda:** AS05/GP05: pantalla de Cuadrante real, sin reproducir la interfaz ni los logotipos de LRHSoft. El nombre de LRHSoft identifica el origen compatible; no insinuar colaboración oficial. Verificar que el selector y lector .Shifter funcionen en el candidato de cada plataforma.
- **Tamaños:** App Store I69 e I65; Google Play A, según la tabla de dimensiones.

| Idioma | Pie | Caracteres |
|---|---|---:|
| es | Trae tu copia de LRHSoft | 24 |
| ca | Porta la teva còpia de LRHSoft | 30 |
| gl | Trae a túa copia de LRHSoft | 27 |
| eu | Ekarri LRHSoft kopia | 20 |
| en | Bring your LRHSoft backup | 25 |

### 6. Festivos locales sin buscar en Internet · AS06 / GP06

- **Pantalla:** Ajustes › Festivos con comunidad, municipio y los festivos locales de la muestra visibles.
- **Datos de demostración:** Madrid, año 2026, con los locales comprobados o añadidos a mano según el estado común. Activar modo avión después de cargar los datos, para verificar que siguen accesibles. Sin icono GPS ni ubicación real.
- **Variante por tienda:** AS06/GP06: mostrar la cobertura existente del municipio seleccionado. Si el nombre de un festivo aún no está traducido en el paquete, conservar lo que realmente presenta la app; no retocarlo ni prometer todos los municipios.
- **Tamaños:** App Store I69 e I65; Google Play A, según la tabla de dimensiones.

| Idioma | Pie | Caracteres |
|---|---|---:|
| es | Tus festivos locales, sin conexión | 34 |
| ca | Els teus festius locals, sense connexió | 39 |
| gl | Os teus festivos locais, sen conexión | 37 |
| eu | Tokiko jaiegunak, konexiorik gabe | 33 |
| en | Your local holidays, offline | 28 |

### 7. Separar horas nocturnas y festivas · AS07 / GP07

- **Pantalla:** Resumen › diciembre de 2026, líneas de horas trabajadas, nocturnas y festivas.
- **Datos de demostración:** Estado común «Demo»: 72 h totales, 24 h nocturnas y 8 h festivas. Comparar las cifras con el motor del candidato antes de capturar. Ajustar el encuadre para leer las etiquetas y las tres cifras; sin euros ni datos salariales.
- **Variante por tienda:** AS07/GP07: resumen de horas (trabajadas, nocturnas y festivas). No mostrar jornada anual, saldo contra convenio, plus por hora, PDF ni pantallas futuras de funciones avanzadas. Si las cifras difieren, resolver la muestra o el cálculo antes de producir la imagen; no editar la cifra en una captura.
- **Tamaños:** App Store I69 e I65; Google Play A, según la tabla de dimensiones.

| Idioma | Pie | Caracteres |
|---|---|---:|
| es | Noches y festivos, por separado | 31 |
| ca | Nits i festius, per separat | 27 |
| gl | Noites e festivos, por separado | 31 |
| eu | Gaueko eta jaiegunetako orduak bereiz | 37 |
| en | Night and public holiday hours | 30 |

### 8. Tu idioma, sin registro ni anuncios · AS08 / GP08

- **Pantalla:** Selector real de idioma en Ajustes › Apariencia.
- **Datos de demostración:** Lista con Español, Català, Galego, Euskara y English; marcar el idioma de la imagen. No elegir «Sistema» si impide comprobar qué idioma se está capturando. El resto de la interfaz también debe estar en ese idioma.
- **Variante por tienda:** AS08/GP08: selector nativo de la app correspondiente. Sin pantallas de registro inventadas ni comparativas con anuncios de otras apps. Verificar que el diálogo muestra las cinco opciones sin recortes.
- **Tamaños:** App Store I69 e I65; Google Play A, según la tabla de dimensiones.

| Idioma | Pie | Caracteres |
|---|---|---:|
| es | 5 idiomas, sin cuenta ni anuncios | 33 |
| ca | 5 idiomes, sense compte ni anuncis | 34 |
| gl | 5 idiomas, sen conta nin anuncios | 33 |
| eu | 5 hizkuntza, konturik eta iragarkirik gabe | 42 |
| en | 5 languages, no account or ads | 30 |

## Producción y revisión

Mantener los tokens del proyecto: `context.colors`, `context.type`, `Sp`, `Rad` y `AppIcons`, usando la dirección B de `docs/diseno.md`. Los márgenes y el tamaño de los pies se deciden al componer cada lienzo, con el mismo criterio visual en la serie. Nunca comunicar un turno solo por el color: conservar código y horario legibles. Alternar claro/oscuro solo si las capturas siguen pareciendo una misma colección; aquí se propone oscuro como base.

Producir imágenes desde la app y los widgets reales de cada plataforma, con un dispositivo de demostración limpio y sin otras apps, cuentas o notificaciones personales. Mantener el mismo tamaño tipográfico de pie entre idiomas; permitir dos líneas. Revisar con una persona nativa ca/gl/eu, especialmente los términos propuestos del glosario. Sin emojis, estrellas, premios, precios ni etiquetas de plan, ni frases como «nunca falla» o «sin perder nada».

Antes de entregar, cotejar los 40 pies y sus recuentos, las ocho posiciones por tienda, los tamaños, el idioma de toda la UI y los datos del resumen. Confirmar restauración e importación en el candidato y la prueba de siete días del widget. La falta de una función nativa bloquea la captura correspondiente: no sustituirla por una maqueta presentada como producto.

Este documento no autoriza producción, publicación ni uso de emuladores en esta tarea. Las capturas se encargan al flujo de QA autorizado cuando exista el candidato; aquí solo se entrega el plan.
