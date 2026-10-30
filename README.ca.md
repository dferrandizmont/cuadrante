[English](README.md) · [Español](README.es.md) · **Català** · [Galego](README.gl.md) · [Euskara](README.eu.md)

<p align="center">
  <img src="docs/readme/ca/header.png" alt="Turnly — Els teus torns, d’un cop d’ull. Gratis, sense anuncis i sense connexió." width="1024">
</p>

# Turnly

Abans es deia Cuadrante.

[![Codi: MIT](https://img.shields.io/badge/Codi-MIT-4B4FD1)](LICENSE)
[![Contingut: CC BY-SA 4.0](https://img.shields.io/badge/Contingut-CC_BY--SA_4.0-4B4FD1)](LICENSE-CONTENT.md)
[![Darrera versió](https://img.shields.io/github/v/release/dferrandizmont/turnly?include_prereleases&label=versi%C3%B3&color=4B4FD1)](https://github.com/dferrandizmont/turnly/releases)
[![Baixades](https://img.shields.io/github/downloads/dferrandizmont/turnly/total?label=baixades&color=4B4FD1)](https://github.com/dferrandizmont/turnly/releases)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Convida%27m_a_un_caf%C3%A8-FF5E5B?logo=kofi&logoColor=white)](https://ko-fi.com/danielmfdev)

Calendari de torns per a qui treballa a torns a Espanya: sanitat, policia,
bombers, indústria, hostaleria o qualsevol altre sector. Organitza matins, tardes,
nits, guàrdies i dies lliures, i consulta el proper torn d’un cop d’ull. Cinc
idiomes: español, català, galego, euskara i English.

**Gratis · Sense anuncis · Sense compte · Sense connexió · Codi obert**

Totes les funcions disponibles són obertes, sense Pro ni compres dins de l’app.

## Baixades

<p>
  <a href="https://play.google.com/apps/testing/es.cuadrante.app"><img src="https://img.shields.io/badge/Google_Play-Beta-414141?logo=googleplay&amp;style=for-the-badge" alt="Beta a Google Play"></a>
  <a href="https://github.com/dferrandizmont/turnly/releases/latest"><img src="https://img.shields.io/badge/Disponible_a-GitHub-181717?logo=github&amp;style=for-the-badge" alt="Disponible a GitHub"></a>
  <!--
  <a href="[ENLACE_APP_STORE]"><img src="https://img.shields.io/badge/App_Store-Baixa-0D96F6?logo=appstore&amp;style=for-the-badge" alt="Disponible a l’App Store"></a>
  -->
</p>

Android en proves; iPhone, aviat. Mode clar i fosc.

<details>
<summary>Uneix-te a la beta de Google Play</summary>

L’app és en prova tancada a Google Play i s’hi pot apuntar qualsevol persona:

> **Ara mateix Google està revisant la primera versió.** Ja et pots unir al grup (pas 1); l’enllaç del pas 2 funcionarà quan l’aprovin, normalment en pocs dies.

1. Uneix-te al grup de testers: [turnly-testers](https://groups.google.com/g/turnly-testers). Amb el teu compte de Google, prem «Uneix-te al grup».
2. Accepta la prova des del mòbil o l’ordinador: [play.google.com/apps/testing/es.cuadrante.app](https://play.google.com/apps/testing/es.cuadrante.app).
3. Instal·la l’app des de Google Play. S’actualitzarà sola.

Si pots, queda’t a la prova almenys 14 dies i fes-la servir de tant en tant (per exemple, mira el torn de demà o posa el widget): Google exigeix 12 testers durant 14 dies per publicar-la per a tothom. Els comentaris, a dev@mainshai.com.

</details>

<details>
<summary>Instal·la l’APK des de GitHub</summary>

També pots baixar l’APK de la [darrera versió](https://github.com/dferrandizmont/turnly/releases/latest) i instal·lar-lo a mà (cal permetre «instal·lar aplicacions d’origen desconegut»). Està signat amb una clau diferent de la de la versió de Google Play, així que l’una no actualitza l’altra: per canviar, exporta abans una còpia des de l’app (`.turnly`; les versions anteriors la desen com a `.cuadrante`).

Aviat a l’App Store.

</details>

## Captures

<p>
  <a href="docs/readme/ca/01-mes.png"><img src="docs/readme/ca/01-mes.png" width="19%" alt="Mes pintat i targeta del proper torn"></a>
  <a href="docs/readme/ca/02-lista.png"><img src="docs/readme/ca/02-lista.png" width="19%" alt="El mateix mes en vista Llista, amb codis i horaris complets"></a>
  <a href="docs/readme/ca/03-pintar.png"><img src="docs/readme/ca/03-pintar.png" width="19%" alt="Mode pintar amb la paleta de torns"></a>
  <a href="docs/readme/ca/04-rotaciones.png"><img src="docs/readme/ca/04-rotaciones.png" width="19%" alt="Assistent de rotacions amb vista prèvia abans d’aplicar"></a>
  <a href="docs/readme/ca/05-horas.png"><img src="docs/readme/ca/05-horas.png" width="19%" alt="Resum mensual d’hores treballades, nocturnes i festives"></a>
</p>

<details>
<summary>Més captures</summary>

<p>
  <a href="docs/readme/ca/06-festivos.png"><img src="docs/readme/ca/06-festivos.png" width="19%" alt="Festius de la Comunitat de Madrid i del municipi de Madrid"></a>
  <a href="docs/readme/ca/07-mes-oscuro.png"><img src="docs/readme/ca/07-mes-oscuro.png" width="19%" alt="El mateix mes amb el tema fosc"></a>
</p>

</details>

Prem una captura per ampliar-la. Pantalles reals amb dades fictícies, generades
per [tests de Flutter](app/test/store/), també [en castellà](README.es.md#capturas).

## Funcions

- **Mes en Quadrícula o Llista.** Vista anual, agenda i notes per dia. Cada torn
  porta color, codi i horari; la Llista permet llegir els horaris complets.
  Exportació puntual al calendari del mòbil i imatges del mes i de l’any.
- **Pintar torns i rotacions.** Toca o arrossega per seleccionar diversos dies,
  doblar, copiar i enganxar, desfer i refer; assistent de rotacions amb vista
  prèvia: torns rotatius, 24/72, 4×4, 6×4, 5×2, 2-2-3 i patrons propis. Tipus de
  torn, colors, icones i horaris editables.
- **Festius d’Espanya.** Nacionals i autonòmics inclosos sense connexió; locals
  per als municipis disponibles i opció d’afegir-hi els teus.
- **Alarmes i widgets.** Alarma per tipus de torn, recordatoris de notes i widgets
  d’Android per consultar els teus torns des de la pantalla d’inici. La seva
  puntualitat depèn dels permisos i les restriccions del sistema. El widget d’iPhone
  (WidgetKit) està pendent de desenvolupar al Mac.
- **Còpies de seguretat i importació.** Còpies de seguretat locals automàtiques,
  exportació a `.turnly` (les còpies antigues `.cuadrante` encara s’obren), vista prèvia en restaurar i «Prova la restauració».
  Importar còpies `.Shifter` de LRHSoft, fitxers `.ics` o CSV i esdeveniments del
  calendari del mòbil, revisant els torns abans de desar-los.
- **Resum d’hores.** Treballades, nocturnes, festives, extra i sortides
  anticipades; estimació d’ingressos amb preu per hora i plus fix per torn.

<details>
<summary>Més funcions</summary>

- **Diversos calendaris.** Sense límit de pagament, i comparació entre dos quadrants.
- **Accessibilitat.** Selector d’idioma, lector de pantalla, text ampliable i
  torns que mai no depenen només del color.

</details>

## Privacitat

Els torns i la configuració es desen al mòbil. Sense servidor propi, analítica,
seguiment ni enviament d’informes d’errors. L’app demana permís de **calendari** en
importar o exportar, i de **notificacions i alarmes** en activar els avisos.

<details>
<summary>Permisos i còpies</summary>

No demana ubicació, contactes, càmera ni micròfon.

Les còpies del sistema de Google o Apple poden incloure les teves dades, també les
absències. Si exportes a un calendari sincronitzat o comparteixes una còpia, les
dades van a la destinació que triïs. El fitxer de còpia `.turnly` no està xifrat.

</details>

[Política de privacitat](https://dferrandizmont.github.io/turnly/privacidad/) ·
[Detall tècnic](docs/privacy.md) (en castellà) · Suport: **dev@mainshai.com**.

## Novetats

Els canvis de cada versió són al [CHANGELOG.md](CHANGELOG.md) i a les
[versions publicades](https://github.com/dferrandizmont/turnly/releases).

## Contribuir

Els informes d’errors, les idees i les traduccions són benvinguts. Com compilar,
provar i col·laborar: [CONTRIBUTING.es.md](CONTRIBUTING.es.md).

## Llicència

Codi [MIT](LICENSE), Copyright (c) 2026 Daniel Mont Ferrandiz. Contingut propi
[CC BY-SA 4.0](LICENSE-CONTENT.md). Les fonts oficials de festius i els materials
de tercers conserven les seves condicions, detallades en aquestes llicències.

Per comunicar una vulnerabilitat: [SECURITY.md](SECURITY.md).
