# Política de privacidad de Cuadrante

Última actualización: 26 de octubre de 2026

Cuadrante es una app de calendario de turnos para quien trabaja a turnos en España. Es una app independiente: no
está creada, revisada ni respaldada por ninguna empresa, administración ni sindicato.

Resumen: **no tienes cuenta, no hay servidor propio y tus turnos se quedan en tu móvil.** La app es totalmente
gratuita y de código abierto, y no envía datos ni informes de errores a nadie. Lo único que puede sacar tus datos del
móvil son las copias de seguridad de tu cuenta de Google o de Apple y los archivos o calendarios que tú decidas
exportar, y eso lo controlas tú.

## 1. Responsable del tratamiento

- Titular: Daniel Mont Ferrandiz
- Correo de contacto: dev@mainshai.com

## 2. Qué datos se tratan

### Datos que se quedan en tu móvil (no los recibimos)
Tus calendarios, tipos de turno, rotaciones, cambios de día, notas, recordatorios, horas extra, ausencias (vacaciones,
moscosos, libre disposición, permisos y baja médica), festivos, comunidad y municipio, precio por hora y ajustes se
guardan solo en una base de datos local del dispositivo. Los festivos oficiales van dentro de la app y todo funciona
sin conexión. No hay sincronización ni copia en ningún servidor nuestro.

**Tu baja médica es un dato de salud.** Nosotros nunca la recibimos: no hay servidor, analítica ni calendario
compartido. Las alarmas no suenan en los días de ausencia y el recordatorio de una nota en un día de ausencia no
enseña el texto de la nota, para que nada de eso salga en la pantalla de bloqueo. Ten en cuenta, eso sí, que:

- los widgets de hoy, de la semana y del mes enseñan en la pantalla de inicio los turnos del día, también una
  ausencia con el código y el color que le hayas dado, y su descripción para el lector de pantalla los nombra. Los
  widgets de agenda y de dos semanas solo dicen «Ausencia». El texto de tus notas no va nunca al widget;
- las ausencias, baja incluida, van dentro de tus copias de seguridad (ver abajo), igual que el resto de tus turnos.

### Copias de seguridad
La app hace **copias automáticas en tu propio móvil** y te deja **exportar una copia a un archivo `.cuadrante`**
(Ajustes › Copia de seguridad) para guardarla donde quieras o pasarla a otro móvil, y restaurarla después. Ese
archivo contiene tus turnos, notas y ausencias, no lleva ningún identificador y no está cifrado; lo guardas y lo
controlas tú: la app solo lo entrega a la app que elijas en la hoja de compartir del sistema. Lo que hagas con él
después (subirlo a tu nube, mandarlo por WhatsApp o por correo...) queda fuera de la app. Al abrir un `.cuadrante`,
nada se restaura sin que lo confirmes.

**Copia del sistema.** En Android, si tienes activada la copia de seguridad de Google, el sistema sube
periódicamente la base de datos y las copias de la app a tu cuenta de Google y las pasa a tu móvil nuevo; en Android
9 o superior va cifrada de extremo a extremo con tu bloqueo de pantalla, si tienes uno. En iPhone, la base de datos
entra en la copia del dispositivo (iCloud o la del ordenador). Esas copias las gestionas tú con tu cuenta de Google o
de Apple y puedes desactivarlas en los ajustes del sistema; la app no envía nada por su cuenta y no hace ninguna
copia propia en iCloud.

### Calendario del móvil
Solo si tú lo pides, y solo en ese momento:

- **Importar** lee los eventos del calendario que elijas (o de un archivo `.ics`, CSV o una copia de otra app de
  turnos) para proponerte turnos. Se leen y se agrupan en tu móvil, y solo se guarda lo que aceptes.
- **Exportar** escribe tus turnos (nombre, código y horario; nunca notas ni cantidades) en el calendario del móvil
  que elijas. **Si ese calendario se sincroniza con una cuenta** (Google, iCloud, Exchange...), tus turnos se verán
  también en esa cuenta: lo sube el propio sistema, fuera del control de la app. La pantalla te lo avisa. Las
  ausencias y los días libres no se exportan salvo que actives sus interruptores.

El permiso de calendario se pide cuando empiezas a importar o a exportar, nunca al arrancar, y la app no lee ni
escribe el calendario en segundo plano.

### Permisos
Además del calendario, la app pide permiso de **notificaciones** y de **alarmas y recordatorios** cuando activas las
alarmas de turno o el recordatorio de una nota, para que suenen a su hora y el widget cambie de día a medianoche. Si
no lo concedes, las alarmas pueden sonar con retraso. No pide ubicación, contactos, fotos, cámara, micrófono ni acceso
general al almacenamiento, y la versión publicada de Android no tiene permiso de red.

### Comunicaciones
La app no transmite turnos, identificadores ni informes de errores. No utiliza compras, anuncios, analítica ni
servicios de terceros. Los errores se manejan solo en el dispositivo.

Si tocas «Política de privacidad» en Ajustes › Ayuda, se abre esta página en tu navegador externo. Es el navegador
el que se conecta a la web; Cuadrante no le envía tus turnos, notas ni ausencias.

### Datos que NO se tratan
- No pedimos ni guardamos nombre, correo, teléfono, DNI, fecha de nacimiento ni datos de tu empresa.
- No hay analítica, ni anuncios, ni publicidad personalizada, ni rastreo entre apps.
- No accedemos a tu ubicación, contactos, fotos, cámara ni micrófono.
- No recibimos tus turnos, tus notas, tus ausencias ni tus horas.

### Si nos escribes
«Ayuda y contacto» (Ajustes) te enseña la dirección de soporte para que la copies y nos escribas desde tu propia app
de correo, con la versión de la app si quieres adjuntarla. La app no abre el correo ni envía nada por sí misma. Si
nos escribes, trataremos tu dirección de correo y lo que nos cuentes solo para responderte. No nos mandes copias
`.cuadrante` ni capturas con turnos, notas o ausencias reales: para un fallo nos basta con datos inventados.

## 3. Para qué y con qué base jurídica

| Tratamiento | Finalidad | Base jurídica (RGPD) |
|---|---|---|
| Turnos, notas, ausencias y ajustes en tu móvil | Que lleves tu cuadrante, tus horas y tus alarmas | No los recibimos: se quedan en tu dispositivo, bajo tu control |
| Copias de seguridad y exportaciones | Que no pierdas tus datos y puedas cambiar de móvil | Las haces tú; los servicios que uses (Google, Apple, tu nube) tienen sus propias condiciones |
| Correos de soporte | Responder a tu consulta | Tu solicitud y nuestro interés legítimo en atenderla (art. 6.1.f) |

No tomamos decisiones automatizadas ni elaboramos perfiles sobre ti.

## 4. Quién recibe los datos
La app no transmite datos a terceros. Si envías un correo de soporte, lo recibe el titular en dev@mainshai.com
mediante el servicio de correo que elijas. Si exportas a un calendario sincronizado o tienes activada la copia del
sistema, quien recibe esos datos es el proveedor de tu cuenta (Google, Apple u otro), en tu nombre y según sus
condiciones.

## 5. Transferencias internacionales
La app no realiza transferencias de datos. Los servicios externos que decidas utilizar (correo, nube, calendario
sincronizado o destino de una exportación) se rigen por sus propias condiciones.

## 6. Cuánto tiempo se conservan

- **Datos en tu móvil:** hasta que desinstales la app o borres sus datos desde los ajustes del sistema (y, en su
  caso, de las copias de seguridad de tu cuenta y de los archivos que hayas exportado).
- **Correos de soporte:** el tiempo necesario para atender tu consulta y, como máximo, un año desde la última
  respuesta.

## 7. Tus derechos

Puedes ejercer tus derechos de **acceso, rectificación, supresión, oposición, limitación del tratamiento y
portabilidad** escribiendo a dev@mainshai.com. Te responderemos en el plazo de un mes.

No recibimos los datos guardados en tu móvil, así que no podemos verlos ni borrarlos por ti. Puedes borrarlos
desinstalando la app o borrando sus datos desde los ajustes del sistema, y llevártelos con «Exportar copia».

Si crees que no hemos tratado bien tus datos, puedes reclamar ante la Agencia Española de Protección de Datos:
https://www.aepd.es

## 8. Menores

La app está pensada para personas que trabajan. No pide la edad ni recoge datos personales de nadie, tampoco de
menores: los turnos y los ajustes se mantienen en el dispositivo.

## 9. Seguridad
No hay servidor ni transmisión de datos desde la app. Las copias automáticas se guardan en la carpeta privada de la
app. Tú controlas los archivos exportados y las copias de tu cuenta de Google o de Apple; si tu móvil tiene bloqueo
de pantalla, la copia de Google va cifrada con él. El código es público y cualquiera puede comprobar lo que hace.

## 10. Cambios en esta política

Si cambia lo que hace la app con los datos, actualizaremos esta página y la fecha de arriba. Si el cambio es
importante (por ejemplo, si algún día se añadiera una copia en iCloud o cualquier función que envíe datos, que solo
se activaría con tu consentimiento), te lo indicaremos también dentro de la app.

## 11. Contacto

dev@mainshai.com

---

## Notas para el titular (no publicar)
Borra esta sección antes de publicar (el generador HTML la omite). Texto redactado el 26-oct-2026 contra el código de
esa fecha (`docs/privacy.md` es la fuente de verdad): revísalo con una persona antes del lanzamiento.

Decisiones ya tomadas en este texto, por si quieres cambiarlas: titular Daniel Mont Ferrandiz y correo
`dev@mainshai.com` (los de Ley al Blanco); conservación de correos «un año desde la última respuesta»; fecha de
última actualización la de la redacción. No se publica el NIF: el RGPD pide identificar al responsable y un contacto,
y una app gratuita sin actividad económica no está obligada a darlo por la LSSI.

Pendientes: la decisión 13 de `docs/preguntas.md` (ausencias de salud fuera de toda copia automática) no está
implementada, y esta política dice la verdad actual (van en las copias); si se implementa, reescribir «Tu baja
médica» y «Copias de seguridad». El correo `dev@mainshai.com` ya está definido en `kSupportEmail`. Publicar la URL
(`docs/legal/LEEME.md`) y ponerla en las fichas de las tiendas; comprobar que coincide con «Seguridad de los datos»
(Play) y «Privacidad de la app» (Apple): no se recopilan datos. La versión inglesa (`politica-privacidad.en.md`) es
una traducción de cortesía; manda la española.
