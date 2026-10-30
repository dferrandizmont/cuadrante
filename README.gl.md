[English](README.md) · [Español](README.es.md) · [Català](README.ca.md) · **Galego** · [Euskara](README.eu.md)

<p align="center">
  <img src="docs/readme/gl/header.png" alt="Turnly — As túas quendas, dunha ollada. Gratis, sen anuncios e sen conexión." width="1024">
</p>

# Turnly

Antes chamábase Cuadrante.

[![Código: MIT](https://img.shields.io/badge/C%C3%B3digo-MIT-4B4FD1)](LICENSE)
[![Contido: CC BY-SA 4.0](https://img.shields.io/badge/Contido-CC_BY--SA_4.0-4B4FD1)](LICENSE-CONTENT.md)
[![Última versión](https://img.shields.io/github/v/release/dferrandizmont/turnly?include_prereleases&label=versi%C3%B3n&color=4B4FD1)](https://github.com/dferrandizmont/turnly/releases)
[![Descargas](https://img.shields.io/github/downloads/dferrandizmont/turnly/total?label=descargas&color=4B4FD1)](https://github.com/dferrandizmont/turnly/releases)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Conv%C3%ADdame_a_un_caf%C3%A9-FF5E5B?logo=kofi&logoColor=white)](https://ko-fi.com/danielmfdev)

Calendario de quendas para quen traballa a quendas en España: sanidade, policía,
bombeiros, industria, hostalaría ou calquera outro sector. Organiza mañás, tardes,
noites, gardas e días libres, e consulta a próxima quenda dunha ollada. Cinco
idiomas: español, català, galego, euskara e English.

**Gratis · Sen anuncios · Sen contas · Sen conexión · Código aberto**

Todas as funcións dispoñibles están abertas, sen Pro nin compras dentro da app.

## Descargas

<p>
  <a href="https://play.google.com/apps/testing/es.cuadrante.app"><img src="https://img.shields.io/badge/Google_Play-Beta-414141?logo=googleplay&amp;style=for-the-badge" alt="Beta en Google Play"></a>
  <a href="https://github.com/dferrandizmont/turnly/releases/latest"><img src="https://img.shields.io/badge/Dispo%C3%B1ible_en-GitHub-181717?logo=github&amp;style=for-the-badge" alt="Dispoñible en GitHub"></a>
  <!--
  <a href="[ENLACE_APP_STORE]"><img src="https://img.shields.io/badge/App_Store-Descargar-0D96F6?logo=appstore&amp;style=for-the-badge" alt="Dispoñible na App Store"></a>
  -->
</p>

Android en probas; iPhone, proximamente. Modo claro e escuro.

<details>
<summary>Únete á beta de Google Play</summary>

A app está en proba pechada en Google Play e calquera pode apuntarse:

1. Únete ao grupo de testers: [turnly-testers](https://groups.google.com/g/turnly-testers). Coa túa conta de Google, preme «Unirse ao grupo».
2. Acepta a proba desde o móbil ou o ordenador: [play.google.com/apps/testing/es.cuadrante.app](https://play.google.com/apps/testing/es.cuadrante.app).
3. Instala a app desde Google Play. Actualizarase soa.

Se podes, quédate na proba polo menos 14 días e úsaa de cando en vez (por exemplo, mira a túa quenda de mañá ou pon o widget): Google esixe 12 testers durante 14 días para publicala para todo o mundo. Os comentarios, a turnly@mainshai.com.

</details>

<details>
<summary>Instala o APK desde GitHub</summary>

Tamén podes descargar o APK da [última versión](https://github.com/dferrandizmont/turnly/releases/latest) e instalalo á man (hai que permitir «instalar aplicacións de orixe descoñecida»). Vai asinado cunha clave distinta da versión de Google Play, así que unha non actualiza a outra: para cambiar, exporta antes unha copia desde a app (`.turnly`; as versións anteriores gárdana como `.cuadrante`).

Proximamente na App Store.

</details>

## Capturas

<p>
  <a href="docs/readme/gl/01-mes.png"><img src="docs/readme/gl/01-mes.png" width="19%" alt="Mes pintado e tarxeta da próxima quenda"></a>
  <a href="docs/readme/gl/02-lista.png"><img src="docs/readme/gl/02-lista.png" width="19%" alt="O mesmo mes en vista Lista, con códigos e horarios completos"></a>
  <a href="docs/readme/gl/03-pintar.png"><img src="docs/readme/gl/03-pintar.png" width="19%" alt="Modo pintar coa paleta de quendas"></a>
  <a href="docs/readme/gl/04-rotaciones.png"><img src="docs/readme/gl/04-rotaciones.png" width="19%" alt="Asistente de rotacións con vista previa antes de aplicar"></a>
  <a href="docs/readme/gl/05-horas.png"><img src="docs/readme/gl/05-horas.png" width="19%" alt="Resumo mensual de horas traballadas, nocturnas e festivas"></a>
</p>

<details>
<summary>Máis capturas</summary>

<p>
  <a href="docs/readme/gl/06-festivos.png"><img src="docs/readme/gl/06-festivos.png" width="19%" alt="Festivos da Comunidade de Madrid e do concello de Madrid"></a>
  <a href="docs/readme/gl/07-mes-oscuro.png"><img src="docs/readme/gl/07-mes-oscuro.png" width="19%" alt="O mesmo mes co tema escuro"></a>
</p>

</details>

Preme unha captura para ampliala. Pantallas reais con datos ficticios, xeradas
por [tests de Flutter](app/test/store/), tamén [en castelán](README.es.md#capturas).

## Funcións

- **Mes en Cuadrícula ou Lista.** Vista anual, axenda e notas por día. Cada quenda
  leva cor, código e horario; a Lista permite ler os horarios completos. Exportación
  puntual ao calendario do móbil e imaxes do mes e do ano.
- **Pintar quendas e rotacións.** Toca ou arrasta para seleccionar varios días,
  dobrar, copiar e pegar, desfacer e refacer; asistente de rotacións con vista
  previa antes de aplicar: quendas rotativas, 24/72, 4×4, 6×4, 5×2, 2-2-3 e
  patróns propios. Tipos de quenda, cores, iconas e horarios editables.
- **Festivos de España.** Nacionais e autonómicos incluídos sen conexión; locais
  para os municipios dispoñibles e opción de engadir os teus.
- **Alarmas e widgets.** Alarma por tipo de quenda, recordatorios de notas e widgets
  de Android para consultar as túas quendas desde a pantalla de inicio. A súa
  puntualidade depende dos permisos e das restricións do sistema. O widget de
  iPhone (WidgetKit) está pendente de desenvolver no Mac.
- **Copias de seguranza e importación.** Copias de seguranza locais automáticas,
  exportación a `.turnly` (as copias antigas `.cuadrante` seguen abríndose), vista previa ao restaurar e «Probar restauración».
  Importar copias `.Shifter` de LRHSoft, ficheiros `.ics` ou CSV e eventos do
  calendario do móbil, revisando as quendas antes de gardalas.
- **Resumo de horas.** Traballadas, nocturnas, festivas, extra e saídas anticipadas;
  estimación de ingresos con prezo por hora e plus fixo por quenda.

<details>
<summary>Máis funcións</summary>

- **Varios calendarios.** Sen límite de pagamento, e comparación entre dous cadros
  de quendas.
- **Accesibilidade.** Selector de idioma, lector de pantalla, texto ampliable e
  quendas que nunca dependen só da cor.

</details>

## Privacidade

As quendas e a configuración gárdanse no móbil. Sen servidor propio, analítica,
rastrexo nin envío de informes de erros. A app pide permiso de **calendario** ao
importar ou exportar, e de **notificacións e alarmas** ao activar os avisos.

<details>
<summary>Permisos e copias</summary>

Non pide localización, contactos, cámara nin micrófono.

As copias do sistema de Google ou Apple poden incluír os teus datos, tamén as
ausencias. Se exportas a un calendario sincronizado ou compartes unha copia, os
datos van ao destino que escollas. O ficheiro de copia `.turnly` non está cifrado.

</details>

[Web](https://turnly.mainshai.com/gl/) · [Política de privacidade](https://turnly.mainshai.com/gl/privacy/) ·
[Detalle técnico](docs/privacy.md) (en castelán) · Soporte: **turnly@mainshai.com**.

## Novidades

O que cambia en cada versión está no [CHANGELOG.md](CHANGELOG.md) e nas
[versións publicadas](https://github.com/dferrandizmont/turnly/releases).

## Contribuír

Os informes de erros, as ideas e as traducións son benvidos. Como compilar,
probar e colaborar: [CONTRIBUTING.es.md](CONTRIBUTING.es.md).

## Licenzas

Código [MIT](LICENSE), Copyright (c) 2026 Daniel Mont Ferrandiz. Contido propio
[CC BY-SA 4.0](LICENSE-CONTENT.md). As fontes oficiais de festivos e os materiais
de terceiros conservan as súas condicións, detalladas nesas licenzas.

Para comunicar unha vulnerabilidade: [SECURITY.md](SECURITY.md).
