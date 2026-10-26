[English](README.en.md)

<p align="center">
  <img src="docs/readme/es/header.png" alt="Cuadrante — Tus turnos, de un vistazo. Gratis, sin anuncios y sin conexión." width="1024">
</p>

# Cuadrante

[![Código: MIT](https://img.shields.io/badge/C%C3%B3digo-MIT-4B4FD1)](LICENSE)
[![Contenido: CC BY-SA 4.0](https://img.shields.io/badge/Contenido-CC_BY--SA_4.0-4B4FD1)](LICENSE-CONTENT.md)
[![Última versión](https://img.shields.io/github/v/release/dferrandizmont/cuadrante?include_prereleases&label=versi%C3%B3n)](https://github.com/dferrandizmont/cuadrante/releases)

Calendario de turnos para quienes trabajan a turnos en España: sanidad, policía,
bomberos, industria, hostelería o cualquier otro sector. Organiza mañanas, tardes,
noches, guardias y días libres, y consulta el próximo turno de un vistazo.

**Totalmente gratis, sin anuncios, sin cuentas y sin conexión. Código abierto.**
Todas las funciones disponibles están abiertas, sin Pro ni compras dentro de la app.
Android en pruebas; iPhone, próximamente. Modo claro y oscuro.

## Descargas

- **Android: grupo de pruebas de Google Play** — Próximamente.
  <!-- PENDIENTE: enlace del grupo de pruebas de Google Play -->
- **iPhone: App Store (próximamente).**
- **APK de prueba: [GitHub Releases](https://github.com/dferrandizmont/cuadrante/releases).**

## Capturas

<p>
  <a href="docs/readme/es/01-mes.png"><img src="docs/readme/es/01-mes.png" width="160" alt="Mes pintado y tarjeta del próximo turno, en modo oscuro"></a>
  <a href="docs/readme/es/02-lista.png"><img src="docs/readme/es/02-lista.png" width="160" alt="El mismo mes en vista Lista, con códigos y horarios completos"></a>
  <a href="docs/readme/es/03-pintar.png"><img src="docs/readme/es/03-pintar.png" width="160" alt="Modo pintar con la paleta de turnos"></a>
  <a href="docs/readme/es/04-rotaciones.png"><img src="docs/readme/es/04-rotaciones.png" width="160" alt="Asistente de rotaciones con vista previa antes de aplicar"></a>
  <a href="docs/readme/es/05-horas.png"><img src="docs/readme/es/05-horas.png" width="160" alt="Resumen mensual de horas trabajadas, nocturnas y festivas"></a>
  <a href="docs/readme/es/06-festivos.png"><img src="docs/readme/es/06-festivos.png" width="160" alt="Festivos de la Comunidad de Madrid y del municipio Madrid"></a>
</p>

Pulsa una captura para ampliarla. Pantallas reales con datos ficticios, generadas
por [tests de Flutter](app/test/store/), también [en inglés](README.en.md#screenshots).

## Funciones

- Mes en **Cuadrícula o Lista**, vista anual, agenda y notas por día. Cada turno
  lleva color, código y horario; la Lista permite leer los horarios completos.
- **Pintar turnos** tocando o arrastrando, seleccionar varios días, doblar,
  copiar y pegar, deshacer y rehacer. Tipos de turno, colores, iconos y horarios editables.
- **Rotaciones** con asistente y vista previa: correturnos, 24/72, 4×4,
  6×4, 5×2, 2-2-3 y patrones propios.
- **Varios calendarios**, sin límite de pago, y comparación entre dos cuadrantes.
- **Festivos de España**, nacionales y autonómicos incluidos sin conexión;
  locales para los municipios disponibles y opción de añadir los tuyos.
- **Alarmas por tipo de turno** y recordatorios de notas. Su puntualidad depende
  de los permisos y las restricciones del sistema.
- **Widgets de Android** para consultar tus turnos desde la pantalla de inicio.
  El widget de iPhone (WidgetKit) está pendiente de desarrollo en el Mac.
- **Copias de seguridad locales automáticas**, exportación a `.cuadrante`,
  vista previa al restaurar y «Probar restauración».
- **Importar** copias `.Shifter` de LRHSoft, archivos `.ics` o CSV y eventos del
  calendario del móvil, revisando los turnos antes de guardarlos.
- **Resumen de horas** trabajadas, nocturnas, festivas, extras y salidas anticipadas;
  estimación de ingresos con precio por hora y plus fijo por turno.
- Exportación puntual al calendario del móvil e imágenes del mes y del año.
- **Cinco idiomas:** español, català, galego, euskara y English. Selector de idioma,
  lector de pantalla, texto ampliable y turnos que nunca dependen solo del color.

## Privacidad

Los turnos y ajustes se guardan en el móvil. Sin servidor propio, analítica,
rastreo ni envío de informes de errores. La app pide permiso de **calendario** al
importar o exportar, y de **notificaciones y alarmas** al activar los avisos.
No pide ubicación, contactos, cámara ni micrófono.

Las copias del sistema de Google o Apple pueden incluir tus datos, también las
ausencias. Si exportas a un calendario sincronizado o compartes una copia,
los datos van al destino que elijas. El archivo `.cuadrante` no está cifrado.

[Política de privacidad](https://dferrandizmont.github.io/cuadrante/privacidad/) ·
[Detalle técnico](docs/privacy.md) · Soporte: **dev@mainshai.com**.

## Compilar y probar

Requisitos: **Flutter 3.47.7**, Android SDK para Android o macOS con Xcode para
iPhone. La app usa Riverpod, go_router y Drift para el estado, la navegación y
la base de datos local.

Desde la raíz:

```bash
cd app
flutter pub get
flutter gen-l10n
flutter analyze
TZ=Europe/Madrid flutter test
```

Sin conexión, usa `flutter pub get --offline` con los paquetes ya descargados.
En Windows, usa la zona de Madrid del sistema (`Get-TimeZone`) y ejecuta
`flutter test` sin definir `TZ`; el identificador IANA de Linux altera las horas
en el runtime de Windows.

Para compilar un APK con almacenamiento real, sin los datos de demostración:

```bash
flutter build apk --release --dart-define=USE_DEMO_DATA=false
```

La selección pública se prepara con el [exportador](tool/publish/LEEME.md).
La firma y la publicación requieren una preparación y revisión separadas. Los archivos generados se
versionan; si cambias Drift, freezed o JSON, ejecuta `dart run build_runner build`.

[Regenerar imágenes y capturas](tool/store/LEEME.md) ·
[Generar la web de privacidad](web/legal/LEEME.md) · [Diseño](docs/diseno.md).

## Licencias y seguridad

Código [MIT](LICENSE), Copyright (c) 2026 Daniel Mont Ferrandiz.
Contenido propio [CC BY-SA 4.0](LICENSE-CONTENT.md). Las fuentes oficiales de
festivos y los materiales de terceros conservan sus condiciones, detalladas en
esas licencias.

Para comunicar una vulnerabilidad: [SECURITY.md](SECURITY.md).
