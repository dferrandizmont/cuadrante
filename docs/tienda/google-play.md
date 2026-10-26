# Google Play · borrador de ficha

> **Borrador · 26-oct-2026. La app es totalmente gratuita y de código abierto** (decisión del usuario): sin compras, sin suscripciones, sin anuncios y sin cuentas. No hay ningún precio que insertar ni condiciones de compra que redactar. Nombre pendiente de confirmación (pregunta 5): «Cuadrante» y sus títulos localizados son provisionales; disponibilidad en tiendas, dominio y marcas: verificar.

Los bloques de texto son los campos para copiar; los títulos, recuentos y notas son internos. Recuento en caracteres Unicode normalizados NFC, incluidos espacios, signos y saltos de línea LF; sin el salto final del bloque. Idiomas en orden: es, ca, gl, eu, en. Inglés neutro con grafía US. Revisión nativa de ca/gl/eu pendiente según el glosario.

Fuentes leídas: [especificación §7](../../turnos-spec.md), [mercado](../analisis-mercado.md), [paridad](../paridad.md) (prima la actualización del 23-oct), [publicación](../plan-publicacion.md), [preguntas](../preguntas.md) (respuestas del 25-oct y decisión del 26-oct-2026) y [glosario](../glosario-idiomas.md).

## Alcance antes de publicar

La ficha describe el objetivo de v1; no certifica que el build esté listo. Verificar el candidato de cada plataforma, la matriz de restauración, los siete días del widget y los idiomas. iOS nativo sigue pendiente del bloque del Mac. No anunciar copia automática en iCloud, sincronización entre dispositivos, enlaces compartidos, reloj ni iPad en v1. La réplica iCloud está desactivada (`kICloudReplica = false`).

**Todo es gratuito (decisión del 26-oct-2026):** no hay plan Pro, ni compras, ni suscripciones, ni anuncios, ni cuentas. En los textos públicos no se dice «gratis» de una función: se dice que la app entera es gratuita, y se anuncia solo lo que existe. En la v1 hay: pintar, patrones, varios turnos por día, varios calendarios y su comparación, todos los widgets previstos, copias y restauración, festivos, alarmas, importación (LRHSoft, calendario del móvil, `.ics` y CSV), exportación puntual al calendario (repetible, sin cupo de usos), imágenes del mes y del año y resumen de horas (con nocturnas y festivas, extras, salidas anticipadas, precio por hora y plus fijo por turno).

Los calendarios no tienen límite comercial y la sección «Cuadrante Pro» ya está retirada de Ajustes. Pendientes y **sin anunciar** hasta que existan: la jornada anual y el saldo contra convenio; los pluses por hora nocturna o festiva; los saldos de ausencias; el libro de cambios; el PDF; los temas de la app; la exportación continua al calendario; y compartir por enlace o `.ics` (P1, fuera del MVP).

Política de privacidad y URL pública: **(la redacta el usuario)**. No hay condiciones de compra ni de suscripción que adjuntar: la app no vende nada. Soporte y URL: verificar con el usuario (preguntas 3 y 6).

## Textos públicos localizados

## es · Español

### Título · 28/30 caracteres

```text
Cuadrante: Turnos de Trabajo
```

### Descripción breve · 76/80 caracteres

```text
Tus turnos, widget al día y copias comprobables. Gratis y de código abierto.
```

### Descripción completa · 1714/4000 caracteres

```text
Tus turnos, de un vistazo. Cuadrante te ayuda a organizar mañanas, tardes, noches, guardias, salientes y días libres, sin cuenta, sin anuncios, sin compras y sin conexión.

Pinta los días o aplica un patrón de correturnos, 24/72, 4x4 o tu propia rotación. Añade varios turnos en un día y consulta cada uno con color, código y horario. Mira el mes o el año y apunta tus notas.

UN WIDGET QUE CAMBIA DE DÍA SOLO
Consulta hoy, la semana o el mes sin abrir la app. El cambio de día depende de los permisos y las restricciones del sistema.

COPIAS QUE PUEDES COMPROBAR
Crea copias locales y usa «Probar restauración» para comprobar que se pueden recuperar. Revisa el contenido antes de restaurar. Para cambiar de móvil, guarda un archivo .cuadrante fuera de la app y llévalo al nuevo dispositivo: la copia local se pierde al desinstalar.

TRAE TUS TURNOS
Importa tu copia .Shifter de LRHSoft (Calendario de Turnos) y revisa la vista previa antes de guardar. También puedes importar desde el calendario del móvil, .ics o CSV.

FESTIVOS Y HORAS
Consulta los festivos nacionales y autonómicos de España incluidos en la app sin conexión. Usa los locales disponibles para tu municipio o añade los tuyos a mano. Revisa el resumen de horas trabajadas, nocturnas y festivas, horas extra y salidas anticipadas. El precio por hora y el plus fijo por turno te ayudan a estimar el mes.

EN TU IDIOMA
Español, català, galego, euskara y English, con selector de idioma. Para sanidad, policía, bomberos, industria y cualquier trabajo a turnos.

GRATUITA Y DE CÓDIGO ABIERTO
Todo lo que hay en la app es gratis, y el código es abierto: puedes revisarlo y compilarlo tú mismo. Sin cuentas, sin anuncios, sin compras y sin suscripciones.
```

### Novedades · primera publicación · 242/500 caracteres

```text
Primera versión de Cuadrante: calendario de turnos, patrones, widgets, copia de seguridad con «Probar restauración», importación de LRHSoft y resumen de horas. Totalmente gratuita y de código abierto, en cinco idiomas, sin cuenta ni anuncios.
```

## ca · Català

### Título · 27/30 caracteres

```text
Cuadrante: Torns de treball
```

### Descripción breve · 77/80 caracteres

```text
Els teus torns, widget al dia i còpies comprovables. Gratuït i de codi obert.
```

### Descripción completa · 1705/4000 caracteres

```text
Els teus torns, d’un cop d’ull. Cuadrante t’ajuda a organitzar matins, tardes, nits, guàrdies, sortints i dies lliures, sense compte, sense anuncis, sense compres i sense connexió.

Pinta els dies o aplica un patró de torns rotatius, 24/72, 4x4 o la teva pròpia rotació. Afegeix diversos torns en un dia i consulta’ls amb color, codi i horari. Mira el mes o l’any i apunta les teves notes.

UN WIDGET QUE CANVIA DE DIA SOL
Consulta avui, la setmana o el mes sense obrir l’app. El canvi de dia depèn dels permisos i les restriccions del sistema.

CÒPIES QUE POTS COMPROVAR
Crea còpies locals i fes servir «Prova la restauració» per comprovar que es poden recuperar. Revisa’n el contingut abans de restaurar. Per canviar de mòbil, desa un fitxer .cuadrante fora de l’app i porta’l al nou dispositiu: la còpia local es perd en desinstal·lar.

PORTA ELS TEUS TORNS
Importa la còpia .Shifter de LRHSoft (Calendario de Turnos) i revisa la vista prèvia abans de desar. També pots importar des del calendari del mòbil, .ics o CSV.

FESTIUS I HORES
Consulta sense connexió els festius nacionals i autonòmics d’Espanya inclosos a l’app. Fes servir els locals disponibles per al teu municipi o afegeix els teus a mà. Revisa el resum d’hores treballades, nocturnes i festives, hores extra i sortides anticipades. El preu per hora i el plus fix per torn t’ajuden a estimar el mes.

EN EL TEU IDIOMA
Español, català, galego, euskara i English, amb selector d’idioma. Per a sanitat, policia, bombers, indústria i qualsevol feina a torns.

GRATUÏTA I DE CODI OBERT
Tot el que hi ha a l’app és gratuït, i el codi és obert: el pots revisar i compilar tu mateix. Sense comptes, sense anuncis, sense compres ni subscripcions.
```

### Novedades · primera publicación · 230/500 caracteres

```text
Primera versió de Cuadrante: calendari de torns, patrons, widgets, còpia de seguretat amb «Prova la restauració», importació de LRHSoft i resum d’hores. Totalment gratuïta i de codi obert, en cinc idiomes, sense compte ni anuncis.
```

## gl · Galego

### Título · 30/30 caracteres

```text
Cuadrante: Quendas de traballo
```

### Descripción breve · 75/80 caracteres

```text
As túas quendas, widget e copias comprobables. De balde e de código aberto.
```

### Descripción completa · 1675/4000 caracteres

```text
As túas quendas, dunha ollada. Cuadrante axúdache a organizar mañás, tardes, noites, gardas, saíntes e días libres, sen conta, sen anuncios, sen compras e sen conexión.

Pinta os días ou aplica un patrón de quendas rotativas, 24/72, 4x4 ou a túa propia rotación. Engade varias quendas nun día e consulta cada unha con cor, código e horario. Mira o mes ou o ano e apunta as túas notas.

UN WIDGET QUE CAMBIA DE DÍA SÓ
Consulta hoxe, a semana ou o mes sen abrir a app. O cambio de día depende dos permisos e das restricións do sistema.

COPIAS QUE PODES COMPROBAR
Crea copias locais e usa «Probar restauración» para comprobar que se poden recuperar. Revisa o contido antes de restaurar. Para cambiar de móbil, garda un ficheiro .cuadrante fóra da app e lévao ao novo dispositivo: a copia local pérdese ao desinstalar.

TRAE AS TÚAS QUENDAS
Importa a copia .Shifter de LRHSoft (Calendario de Turnos) e revisa a vista previa antes de gardar. Tamén podes importar desde o calendario do móbil, .ics ou CSV.

FESTIVOS E HORAS
Consulta sen conexión os festivos nacionais e autonómicos de España incluídos na app. Usa os locais dispoñibles para o teu municipio ou engade os teus á man. Revisa o resumo de horas traballadas, nocturnas e festivas, horas extra e saídas anticipadas. O prezo por hora e o plus fixo por quenda axúdanche a estimar o mes.

NO TEU IDIOMA
Español, català, galego, euskara e English, con selector de idioma. Para sanidade, policía, bombeiros, industria e calquera traballo a quendas.

DE BALDE E DE CÓDIGO ABERTO
Todo o que hai na app é de balde, e o código é aberto: podes revisalo e compilalo ti mesmo. Sen contas, sen anuncios, sen compras nin subscricións.
```

### Novedades · primera publicación · 241/500 caracteres

```text
Primeira versión de Cuadrante: calendario de quendas, patróns, widgets, copia de seguranza con «Probar restauración», importación de LRHSoft e resumo de horas. Totalmente de balde e de código aberto, en cinco idiomas, sen conta nin anuncios.
```

## eu · Euskara

### Título · 22/30 caracteres

```text
Cuadrante: Lan-txandak
```

### Descripción breve · 77/80 caracteres

```text
Zure txandak, widget eta babeskopia egiaztagarriak. Doakoa eta kode irekikoa.
```

### Descripción completa · 1907/4000 caracteres

```text
Zure txandak, begirada batean. Cuadrante aplikazioarekin goizeko, arratsaldeko eta gaueko txandak, guardiak, gau-ondokoak eta egun libreak antola ditzakezu, konturik, iragarkirik, erosketarik eta Interneteko konexiorik gabe.

Margotu egunak edo aplikatu txanda birakarien eredua, 24/72, 4x4 edo zure txandaketa. Gehitu hainbat txanda egun berean, bakoitza kolorearekin, kodearekin eta ordutegiarekin. Ikusi hilabetea edo urtea eta idatzi oharrak.

EGUNA BEREZ ALDATZEN DUEN WIDGETA
Ikusi gaurko txandak, astea edo hilabetea aplikazioa ireki gabe. Egun aldaketa sistemaren baimenen eta murrizketen araberakoa da.

EGIAZTA DITZAKEZUN BABESKOPIAK
Sortu tokiko kopiak eta erabili «Probatu leheneratzea» berreskura daitezkeela egiaztatzeko. Berrikusi edukia leheneratu aurretik. Mugikorra aldatzeko, gorde .cuadrante fitxategia aplikaziotik kanpo eta eraman gailu berrira: aplikazioa desinstalatzean tokiko kopia galtzen da.

EKARRI ZURE TXANDAK
Inportatu LRHSoft kopia (Calendario de Turnos), .Shifter fitxategia, eta berrikusi aurrebista gorde aurretik. Mugikorreko egutegitik, .ics edo CSV fitxategietatik ere inporta dezakezu.

JAIEGUNAK ETA ORDUAK
Kontsultatu aplikazioak dakartzan Espainiako estatuko eta erkidegoko jaiegunak konexiorik gabe. Erabili zure udalerrirako dauden tokiko jaiegunak edo gehitu zureak eskuz. Berrikusi laburpena: lan egindako orduak, gauekoak, jaiegunetakoak, aparteko orduak eta irteera aurreratuak. Orduko prezioarekin eta txandako osagarri finkoarekin hileko zenbatekoa kalkula dezakezu.

ZURE HIZKUNTZAN
Español, català, galego, euskara eta English, hizkuntza hautatzeko aukerarekin. Osasungintzarako, poliziarako, suhiltzaileentzat, industriarako eta txandaka lan egiten duen edonorentzat.

DOAKOA ETA KODE IREKIKOA
Aplikazioan dagoen guztia doakoa da, eta kodea irekia da: berrikusi eta konpilatu dezakezu zeuk ere. Konturik, iragarkirik, erosketarik eta harpidetzerik gabe.
```

### Novedades · primera publicación · 233/500 caracteres

```text
Cuadrante aplikazioaren lehen bertsioa: txanden egutegia, ereduak, widgetak, babeskopia eta «Probatu leheneratzea», LRHSoft inportazioa eta orduen laburpena. Doakoa eta kode irekikoa, bost hizkuntzatan, konturik eta iragarkirik gabe.
```

## en · English

### Título · 30/30 caracteres

```text
Cuadrante: Work Shift Calendar
```

### Descripción breve · 69/80 caracteres

```text
Your shifts, widgets and backups you can check. Free and open source.
```

### Descripción completa · 1687/4000 caracteres

```text
Your shifts at a glance. Cuadrante helps you plan mornings, afternoons, nights, 24-hour shifts, post-night days and days off, without an account, ads, purchases or an internet connection.

Paint days or apply a rotating shift pattern, 24/72, 4x4 or your own rotation. Add several shifts to a day and see each one with a color, code and times. View the month or year and add your notes.

A WIDGET THAT CHANGES DAY ON ITS OWN
Check today, the week or the month without opening the app. Day changes depend on system permissions and restrictions.

BACKUPS YOU CAN CHECK
Create local backups and use Test restore to check that they can be recovered. Review the contents before restoring. To change phones, save a .cuadrante file outside the app and take it to your new device: local backups are lost when you uninstall.

BRING YOUR SHIFTS
Import your .Shifter backup from LRHSoft (Calendario de Turnos) and review the preview before saving. You can also import from your phone’s calendar, .ics or CSV.

PUBLIC HOLIDAYS AND HOURS
Check the included national and regional public holidays for Spain offline. Use the local holidays available for your municipality or add your own manually. Check the summary of worked hours, night and public holiday hours, overtime and early leave. An hourly rate and a fixed allowance per shift help you estimate the month.

IN YOUR LANGUAGE
Español, català, galego, euskara and English, with a language selector. For healthcare, police, firefighters, industry and anyone who works shifts.

FREE AND OPEN SOURCE
Everything in the app is free, and the code is open: you can review it and build it yourself. No accounts, no ads, no purchases and no subscriptions.
```

### Novedades · primera publicación · 209/500 caracteres

```text
The first release of Cuadrante: shift calendar, patterns, widgets, backups with Test restore, LRHSoft import and an hours summary. Completely free and open source, in five languages, without an account or ads.
```


## Categoría, etiquetas y términos de búsqueda

- Tipo: aplicación; categoría propuesta: **Productividad / Productivity**. No es un juego.
- Etiquetas de consola candidatas: **Calendario / Calendar**, **Productividad / Productivity**, **Planificador personal / Personal planner**. Verificar los nombres disponibles en Play Console; seleccionar solo los que existan y describan la app, hasta el máximo que permita la consola.
- Google Play no tiene un campo independiente de keywords. La tabla siguiente es para investigación ASO; no pegarla como bloque de palabras en la descripción.

| Idioma | Términos de búsqueda internos |
|---|---|
| es | calendario de turnos, cuadrante, correturnos, guardias, saliente, moscosos, horas nocturnas, festivos locales |
| ca | calendari de torns, quadrant, torns rotatius, guàrdies, sortint, lliure disposició, hores nocturnes, festius locals |
| gl | calendario de quendas, cadro de quendas, quendas rotativas, gardas, saínte, libre disposición, horas nocturnas, festivos locais |
| eu | txanden egutegia, txandaketa, txanda birakariak, guardia, gau-ondokoa, norberaren egunak, gaueko orduak, tokiko jaiegunak |
| en | shift calendar, shift schedule, roster, rota, rotating shifts, post-night, personal days, night hours, local holidays |

## Clasificación de contenido · respuestas de consola

Respuestas administrativas comunes a las cinco fichas; no se traducen ni se pegan en la descripción. Verificar el cuestionario IARC vigente en la consola: las preguntas y el resultado exacto los determina Google.

| Pregunta o grupo | Respuesta propuesta para el código actual |
|---|---|
| Categoría del cuestionario | Todas las demás aplicaciones; utilidad de calendario/productividad |
| Violencia, sangre, lesiones, miedo u horror | No / ninguno |
| Sexualidad, desnudos o contenido sugerente | No / ninguno |
| Lenguaje ofensivo o humor vulgar | No / ninguno |
| Drogas, alcohol o tabaco | No / ninguno |
| Apuestas, casino, apuestas simuladas, premios en dinero o activos negociables | No |
| Odio o discriminación | No |
| Contenido médico o consejos de salud | No; anotar una ausencia no ofrece información clínica |
| Comunicación entre usuarios, chat, citas o intercambio público de contenido | No; notas y archivos son locales, no hay comunidad ni feed |
| Contenido de usuarios accesible por otros dentro de la app | No |
| Ubicación precisa o compartir la ubicación | No; municipio elegido a mano, sin GPS |
| Acceso sin restricciones a Internet, navegador o buscador web | No |
| Publicidad | No |
| Compras digitales | **No.** La app es totalmente gratuita (decisión del 26-oct-2026): no hay compras digitales, ni suscripción, ni contenido bloqueado |
| Audiencia infantil / Families | No está diseñada específicamente para niños; público previsto: personas que trabajan a turnos. Selección de audiencia de Play propuesta: 18 años o más; verificar con el usuario. No confundir con la clasificación de contenido |
| Clasificación esperable en España | **PEGI 3**, provisional; aceptar solo el resultado emitido por IARC |

## Seguridad de los datos · Data safety

Borrador técnico basado en el árbol de código revisado el 25-oct-2026, no solo en la arquitectura prevista. Se responde por el comportamiento de la versión que se suba. **No hay cuentas, anuncios, analítica ni telemetría remota en el código actual.** Leer datos del calendario o guardar notas en el dispositivo no equivale a recopilarlos fuera del dispositivo.

### Respuestas al formulario

| Campo | Respuesta propuesta | Alcance / verificar |
|---|---|---|
| ¿La app recopila o comparte alguno de los tipos de datos exigidos? | **No** para el código actual | Verificar de nuevo el AAB final y sus SDK. No usar esta respuesta si se incorpora telemetría, descargas con registros identificables u otro envío. No hay RevenueCat ni compras: la app es totalmente gratuita (decisión del 26-oct-2026) |
| Datos recopilados | **Ninguno** | No seleccionar calendario, salud, información financiera ni notas solo por su tratamiento local |
| Datos compartidos | **Ninguno por la app de forma automática** | La exportación elegida por el usuario pasa a Archivos, compartir del sistema o un calendario del dispositivo. Verificar que encaje en las excepciones vigentes de transferencias iniciadas por el usuario |
| ¿Todos los datos recopilados se cifran en tránsito? | **No aplica: no hay recopilación** | Si la consola omite la pregunta tras responder No, no rellenarla. No marcar Sí como garantía de cifrado de archivos locales |
| Métodos de creación de cuentas | **La app no permite crear cuentas** | Una cuenta Apple/Google del sistema no es una cuenta de Cuadrante |
| URL para pedir eliminación de cuenta | **No aplica** | No inventar una web ni un flujo de cuentas |
| Solicitud de eliminación de datos recopilados sin eliminar cuenta | **No aplica: no se recopilan datos** | Verificar el nombre exacto del campo y su visibilidad en la consola |
| Finalidades, tratamiento efímero, obligatoriedad y vinculación por tipo de dato | **No aplica** | No hay tipos recopilados que detallar en este build |
| Revisión de seguridad independiente / acreditaciones | **No** | No se ha aportado ninguna certificación |
| Política de privacidad · contenido y URL | **(la redacta el usuario)** | URL pública pendiente; que no haya recopilación no elimina este requisito |

### Evidencias y límites de la declaración

| Comprobación | Evidencia del repositorio |
|---|---|
| Dependencias sin SDK de cuentas, anuncios, analítica o compras remotas | `app/pubspec.yaml` y `app/pubspec.lock`; la especificación ya no contempla RevenueCat ni compras (decisión del 26-oct-2026); las preguntas 7, 8 y 9 actualizan el alcance |
| Informes de errores sin envío | `app/lib/main.dart`, `app/lib/core/providers.dart` y `app/lib/core/diagnostics/crash_reporting.dart` usan `NoopCrashReporter`; que exista una interfaz de informes no significa que haya telemetría remota |
| Persistencia del cuadrante | Drift/SQLite local en `app/lib/core/database/` y repositorios de `app/lib/features/` |
| Copia local y prueba de recuperación | `app/lib/features/backup/`, especialmente `application/backup_providers.dart` y `presentation/backup_screen.dart`; réplica iCloud desactivada con `kICloudReplica = false` |
| Importación de LRHSoft local | `app/lib/features/import/data/lrhsoft_reader.dart`: copia temporal privada y SQLite `OpenMode.readOnly`; no sube el archivo |
| Calendario: importación solo lectura | `app/lib/features/import/`: consulta calendarios y eventos. **No modifica el calendario de origen al importar** |
| Calendario: permiso de escritura también declarado | `app/android/app/src/main/AndroidManifest.xml` declara `READ_CALENDAR` y `WRITE_CALENDAR`; `app/lib/features/calendar_export/data/plugin_device_calendar_api.dart` y `calendar_exporter.dart` permiten exportar a petición del usuario. No declarar que todo el permiso es solo lectura |
| Festivos sin conexión | `app/lib/features/holidays/data/holiday_bundle_loader.dart` y `app/assets/holidays/`; comunidad y municipio se eligen localmente |
| Idiomas y textos | `app/lib/l10n/app_es.arb`, `app_ca.arb`, `app_gl.arb`, `app_eu.arb`, `app_en.arb` |

**Copia y exportación no son una nube propia.** El archivo local puede contener turnos, notas, importes y ausencias; no prometer que está cifrado. La copia dentro de la app se pierde al desinstalar. Si el usuario guarda o comparte el archivo con otro servicio, o exporta a un calendario sincronizado, ese destino puede enviarlo a su proveedor.

**Auto Backup de Android sí está habilitado actualmente**: `AndroidManifest.xml` tiene `allowBackup="true"`; `app/android/app/src/main/res/xml/backup_rules.xml` y `data_extraction_rules.xml` incluyen todo el dominio `file` (`path="."`), donde están la base de datos y las copias. Puede haber copia de Google y transferencia entre dispositivos gestionadas por el sistema. No afirmar que todas las copias permanecen únicamente en el teléfono. **Verificar** su encaje en las excepciones de Data safety y la exclusión efectiva de salud exigida por la pregunta 13: estas reglas no muestran un almacén separado excluido. La decisión de producto no demuestra que esa exclusión esté implementada.

Antes de enviar: verificar el manifiesto fusionado de release, los SDK empaquetados y cualquier cambio de red o copia del sistema. Las respuestas anteriores no cubren una réplica iCloud activada ni servicios aún previstos.
