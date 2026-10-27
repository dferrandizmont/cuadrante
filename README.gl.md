[Español](README.md) · [Català](README.ca.md) · [Galego](README.gl.md) · [Euskara](README.eu.md) · [English](README.en.md)

<p align="center">
  <img src="docs/readme/gl/header.png" alt="Cuadrante — As túas quendas, dunha ollada. Gratis, sen anuncios e sen conexión." width="1024">
</p>

# Cuadrante

[![Código: MIT](https://img.shields.io/badge/C%C3%B3digo-MIT-4B4FD1)](LICENSE)
[![Contido: CC BY-SA 4.0](https://img.shields.io/badge/Contido-CC_BY--SA_4.0-4B4FD1)](LICENSE-CONTENT.md)
[![Última versión](https://img.shields.io/github/v/release/dferrandizmont/cuadrante?include_prereleases&label=versi%C3%B3n)](https://github.com/dferrandizmont/cuadrante/releases)

Calendario de quendas para quen traballa a quendas en España: sanidade, policía,
bombeiros, industria, hostalaría ou calquera outro sector. Organiza mañás, tardes,
noites, gardas e días libres, e consulta a próxima quenda dunha ollada.

**Totalmente de balde, sen anuncios, sen contas e sen conexión. Código aberto.**
Todas as funcións dispoñibles están abertas, sen Pro nin compras dentro da app.
Android en probas; iPhone, proximamente. Modo claro e escuro.

## Descargas

<p>
  <a href="https://play.google.com/apps/testing/es.cuadrante.app"><img src="https://img.shields.io/badge/Google_Play-Beta-414141?logo=googleplay&amp;style=for-the-badge" alt="Beta en Google Play"></a>
  <a href="https://github.com/dferrandizmont/cuadrante/releases/latest"><img src="https://img.shields.io/badge/Dispo%C3%B1ible_en-GitHub-181717?logo=github&amp;style=for-the-badge" alt="Dispoñible en GitHub"></a>
  <!--
  <a href="[ENLACE_APP_STORE]"><img src="https://img.shields.io/badge/App_Store-Descargar-0D96F6?logo=appstore&amp;style=for-the-badge" alt="Dispoñible na App Store"></a>
  -->
</p>

### Beta en Google Play

A app está en proba pechada en Google Play e calquera pode apuntarse:

> **Agora mesmo Google está a revisar a primeira versión.** Xa podes unirte ao grupo (paso 1); a ligazón do paso 2 funcionará en canto a aproben, normalmente en poucos días.

1. Únete ao grupo de testers: [cuadrante-testers](https://groups.google.com/g/cuadrante-testers). Coa túa conta de Google, preme «Unirse ao grupo».
2. Acepta a proba desde o móbil ou o ordenador: [play.google.com/apps/testing/es.cuadrante.app](https://play.google.com/apps/testing/es.cuadrante.app).
3. Instala a app desde Google Play. Actualizarase soa.

Se podes, quédate na proba polo menos 14 días e úsaa de cando en vez (por exemplo, mira a túa quenda de mañá ou pon o widget): Google esixe 12 testers durante 14 días para publicala para todo o mundo. Os comentarios, a dev@mainshai.com.

### APK en GitHub

Tamén podes descargar o APK da [última versión](https://github.com/dferrandizmont/cuadrante/releases/latest) e instalalo á man (hai que permitir «instalar aplicacións de orixe descoñecida»). Vai asinado cunha clave distinta da versión de Google Play, así que unha non actualiza a outra: para cambiar, exporta antes unha copia `.cuadrante` desde a app.

Proximamente na App Store.

## Capturas

<p>
  <a href="docs/readme/gl/01-mes.png"><img src="docs/readme/gl/01-mes.png" width="160" alt="Mes pintado e tarxeta da próxima quenda, en modo escuro"></a>
  <a href="docs/readme/gl/02-lista.png"><img src="docs/readme/gl/02-lista.png" width="160" alt="O mesmo mes en vista Lista, con códigos e horarios completos"></a>
  <a href="docs/readme/gl/03-pintar.png"><img src="docs/readme/gl/03-pintar.png" width="160" alt="Modo pintar coa paleta de quendas"></a>
  <a href="docs/readme/gl/04-rotaciones.png"><img src="docs/readme/gl/04-rotaciones.png" width="160" alt="Asistente de rotacións con vista previa antes de aplicar"></a>
  <a href="docs/readme/gl/05-horas.png"><img src="docs/readme/gl/05-horas.png" width="160" alt="Resumo mensual de horas traballadas, nocturnas e festivas"></a>
  <a href="docs/readme/gl/06-festivos.png"><img src="docs/readme/gl/06-festivos.png" width="160" alt="Festivos da Comunidade de Madrid e do concello de Madrid"></a>
</p>

Preme unha captura para ampliala. Pantallas reais con datos ficticios, xeradas
por [tests de Flutter](app/test/store/), tamén [en castelán](README.md#capturas).

## Funcións

- Mes en **Cuadrícula ou Lista**, vista anual, axenda e notas por día. Cada quenda
  leva cor, código e horario; a Lista permite ler os horarios completos.
- **Pintar quendas** tocando ou arrastrando, seleccionar varios días, dobrar,
  copiar e pegar, desfacer e refacer. Tipos de quenda, cores, iconas e horarios editables.
- **Rotacións** con asistente e vista previa: quendas rotativas, 24/72, 4×4,
  6×4, 5×2, 2-2-3 e patróns propios.
- **Varios calendarios**, sen límite de pagamento, e comparación entre dous cadros de quendas.
- **Festivos de España**, nacionais e autonómicos incluídos sen conexión;
  locais para os municipios dispoñibles e opción de engadir os teus.
- **Alarmas por tipo de quenda** e recordatorios de notas. A súa puntualidade depende
  dos permisos e das restricións do sistema.
- **Widgets de Android** para consultar as túas quendas desde a pantalla de inicio.
  O widget de iPhone (WidgetKit) está pendente de desenvolver no Mac.
- **Copias de seguranza locais automáticas**, exportación a `.cuadrante`,
  vista previa ao restaurar e «Probar restauración».
- **Importar** copias `.Shifter` de LRHSoft, ficheiros `.ics` ou CSV e eventos do
  calendario do móbil, revisando as quendas antes de gardalas.
- **Resumo de horas** traballadas, nocturnas, festivas, extra e saídas anticipadas;
  estimación de ingresos con prezo por hora e plus fixo por quenda.
- Exportación puntual ao calendario do móbil e imaxes do mes e do ano.
- **Cinco idiomas:** español, català, galego, euskara e English. Selector de idioma,
  lector de pantalla, texto ampliable e quendas que nunca dependen só da cor.

## Privacidade

As quendas e a configuración gárdanse no móbil. Sen servidor propio, analítica,
rastrexo nin envío de informes de erros. A app pide permiso de **calendario** ao
importar ou exportar, e de **notificacións e alarmas** ao activar os avisos.
Non pide localización, contactos, cámara nin micrófono.

As copias do sistema de Google ou Apple poden incluír os teus datos, tamén as
ausencias. Se exportas a un calendario sincronizado ou compartes unha copia,
os datos van ao destino que escollas. O ficheiro `.cuadrante` non está cifrado.

[Política de privacidade](https://dferrandizmont.github.io/cuadrante/privacidad/) ·
[Detalle técnico](docs/privacy.md) (en castelán) · Soporte: **dev@mainshai.com**.

## Compilar e probar

Requisitos: **Flutter 3.47.7**, Android SDK para Android ou macOS con Xcode para
iPhone. A app usa Riverpod, go_router e Drift para o estado, a navegación e
a base de datos local.

Desde a raíz:

```bash
cd app
flutter pub get
flutter gen-l10n
flutter analyze
TZ=Europe/Madrid flutter test
```

Sen conexión, usa `flutter pub get --offline` cos paquetes xa descargados.
En Windows, usa a zona de Madrid do sistema (`Get-TimeZone`) e executa
`flutter test` sen definir `TZ`; o identificador IANA de Linux altera as horas
no runtime de Windows.

Para compilar un APK con almacenamento real, sen os datos de demostración:

```bash
flutter build apk --release --dart-define=USE_DEMO_DATA=false
```

A selección pública prepárase co [exportador](tool/publish/LEEME.md) (en castelán).
A sinatura e a publicación requiren unha preparación e unha revisión á parte. Os ficheiros xerados
versiónanse; se cambias Drift, freezed ou JSON, executa `dart run build_runner build`.

[Rexenerar imaxes e capturas](tool/store/LEEME.md) ·
[Xerar a web de privacidade](web/legal/LEEME.md) · [Deseño](docs/diseno.md) (en castelán).

## Licenzas e seguridade

Código [MIT](LICENSE), Copyright (c) 2026 Daniel Mont Ferrandiz.
Contido propio [CC BY-SA 4.0](LICENSE-CONTENT.md). As fontes oficiais de
festivos e os materiais de terceiros conservan as súas condicións, detalladas
nesas licenzas.

Para comunicar unha vulnerabilidade: [SECURITY.md](SECURITY.md).
