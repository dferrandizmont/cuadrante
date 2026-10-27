[Español](README.md) · [Català](README.ca.md) · [Galego](README.gl.md) · [Euskara](README.eu.md) · [English](README.en.md)

<p align="center">
  <img src="docs/readme/ca/header.png" alt="Cuadrante — Els teus torns, d’un cop d’ull. Gratis, sense anuncis i sense connexió." width="1024">
</p>

# Cuadrante

[![Codi: MIT](https://img.shields.io/badge/Codi-MIT-4B4FD1)](LICENSE)
[![Contingut: CC BY-SA 4.0](https://img.shields.io/badge/Contingut-CC_BY--SA_4.0-4B4FD1)](LICENSE-CONTENT.md)
[![Darrera versió](https://img.shields.io/github/v/release/dferrandizmont/cuadrante?include_prereleases&label=versi%C3%B3)](https://github.com/dferrandizmont/cuadrante/releases)

Calendari de torns per a qui treballa a torns a Espanya: sanitat, policia,
bombers, indústria, hostaleria o qualsevol altre sector. Organitza matins, tardes,
nits, guàrdies i dies lliures, i consulta el proper torn d’un cop d’ull.

**Totalment gratis, sense anuncis, sense comptes i sense connexió. Codi obert.**
Totes les funcions disponibles són obertes, sense Pro ni compres dins de l’app.
Android en proves; iPhone, aviat. Mode clar i fosc.

## Baixades

<p>
  <a href="https://play.google.com/apps/testing/es.cuadrante.app"><img src="https://img.shields.io/badge/Google_Play-Beta-414141?logo=googleplay&amp;style=for-the-badge" alt="Beta a Google Play"></a>
  <a href="https://github.com/dferrandizmont/cuadrante/releases/latest"><img src="https://img.shields.io/badge/Disponible_a-GitHub-181717?logo=github&amp;style=for-the-badge" alt="Disponible a GitHub"></a>
  <!--
  <a href="[ENLACE_APP_STORE]"><img src="https://img.shields.io/badge/App_Store-Baixa-0D96F6?logo=appstore&amp;style=for-the-badge" alt="Disponible a l’App Store"></a>
  -->
</p>

### Beta a Google Play

L’app és en prova tancada a Google Play i s’hi pot apuntar qualsevol persona:

> **Ara mateix Google està revisant la primera versió.** Ja et pots unir al grup (pas 1); l’enllaç del pas 2 funcionarà quan l’aprovin, normalment en pocs dies.

1. Uneix-te al grup de testers: [cuadrante-testers](https://groups.google.com/g/cuadrante-testers). Amb el teu compte de Google, prem «Uneix-te al grup».
2. Accepta la prova des del mòbil o l’ordinador: [play.google.com/apps/testing/es.cuadrante.app](https://play.google.com/apps/testing/es.cuadrante.app).
3. Instal·la l’app des de Google Play. S’actualitzarà sola.

Si pots, queda’t a la prova almenys 14 dies i fes-la servir de tant en tant (per exemple, mira el torn de demà o posa el widget): Google exigeix 12 testers durant 14 dies per publicar-la per a tothom. Els comentaris, a dev@mainshai.com.

### APK a GitHub

També pots baixar l’APK de la [darrera versió](https://github.com/dferrandizmont/cuadrante/releases/latest) i instal·lar-lo a mà (cal permetre «instal·lar aplicacions d’origen desconegut»). Està signat amb una clau diferent de la de la versió de Google Play, així que l’una no actualitza l’altra: per canviar, exporta abans una còpia `.cuadrante` des de l’app.

Aviat a l’App Store.

## Captures

<p>
  <a href="docs/readme/ca/01-mes.png"><img src="docs/readme/ca/01-mes.png" width="160" alt="Mes pintat i targeta del proper torn, en mode fosc"></a>
  <a href="docs/readme/ca/02-lista.png"><img src="docs/readme/ca/02-lista.png" width="160" alt="El mateix mes en vista Llista, amb codis i horaris complets"></a>
  <a href="docs/readme/ca/03-pintar.png"><img src="docs/readme/ca/03-pintar.png" width="160" alt="Mode pintar amb la paleta de torns"></a>
  <a href="docs/readme/ca/04-rotaciones.png"><img src="docs/readme/ca/04-rotaciones.png" width="160" alt="Assistent de rotacions amb vista prèvia abans d’aplicar"></a>
  <a href="docs/readme/ca/05-horas.png"><img src="docs/readme/ca/05-horas.png" width="160" alt="Resum mensual d’hores treballades, nocturnes i festives"></a>
  <a href="docs/readme/ca/06-festivos.png"><img src="docs/readme/ca/06-festivos.png" width="160" alt="Festius de la Comunitat de Madrid i del municipi de Madrid"></a>
</p>

Prem una captura per ampliar-la. Pantalles reals amb dades fictícies, generades
per [tests de Flutter](app/test/store/), també [en castellà](README.md#capturas).

## Funcions

- Mes en **Quadrícula o Llista**, vista anual, agenda i notes per dia. Cada torn
  porta color, codi i horari; la Llista permet llegir els horaris complets.
- **Pintar torns** tocant o arrossegant, seleccionar diversos dies, doblar,
  copiar i enganxar, desfer i refer. Tipus de torn, colors, icones i horaris editables.
- **Rotacions** amb assistent i vista prèvia: torns rotatius, 24/72, 4×4,
  6×4, 5×2, 2-2-3 i patrons propis.
- **Diversos calendaris**, sense límit de pagament, i comparació entre dos quadrants.
- **Festius d’Espanya**, nacionals i autonòmics inclosos sense connexió;
  locals per als municipis disponibles i opció d’afegir-hi els teus.
- **Alarmes per tipus de torn** i recordatoris de notes. La seva puntualitat depèn
  dels permisos i les restriccions del sistema.
- **Widgets d’Android** per consultar els teus torns des de la pantalla d’inici.
  El widget d’iPhone (WidgetKit) està pendent de desenvolupar al Mac.
- **Còpies de seguretat locals automàtiques**, exportació a `.cuadrante`,
  vista prèvia en restaurar i «Prova la restauració».
- **Importar** còpies `.Shifter` de LRHSoft, fitxers `.ics` o CSV i esdeveniments del
  calendari del mòbil, revisant els torns abans de desar-los.
- **Resum d’hores** treballades, nocturnes, festives, extra i sortides anticipades;
  estimació d’ingressos amb preu per hora i plus fix per torn.
- Exportació puntual al calendari del mòbil i imatges del mes i de l’any.
- **Cinc idiomes:** español, català, galego, euskara i English. Selector d’idioma,
  lector de pantalla, text ampliable i torns que mai no depenen només del color.

## Privacitat

Els torns i la configuració es desen al mòbil. Sense servidor propi, analítica,
seguiment ni enviament d’informes d’errors. L’app demana permís de **calendari** en
importar o exportar, i de **notificacions i alarmes** en activar els avisos.
No demana ubicació, contactes, càmera ni micròfon.

Les còpies del sistema de Google o Apple poden incloure les teves dades, també les
absències. Si exportes a un calendari sincronitzat o comparteixes una còpia,
les dades van a la destinació que triïs. El fitxer `.cuadrante` no està xifrat.

[Política de privacitat](https://dferrandizmont.github.io/cuadrante/privacidad/) ·
[Detall tècnic](docs/privacy.md) (en castellà) · Suport: **dev@mainshai.com**.

## Compilar i provar

Requisits: **Flutter 3.47.7**, Android SDK per a Android o macOS amb Xcode per a
iPhone. L’app fa servir Riverpod, go_router i Drift per a l’estat, la navegació i
la base de dades local.

Des de l’arrel:

```bash
cd app
flutter pub get
flutter gen-l10n
flutter analyze
TZ=Europe/Madrid flutter test
```

Sense connexió, fes servir `flutter pub get --offline` amb els paquets ja baixats.
A Windows, fes servir la zona de Madrid del sistema (`Get-TimeZone`) i executa
`flutter test` sense definir `TZ`; l’identificador IANA de Linux altera les hores
al runtime de Windows.

Per compilar un APK amb emmagatzematge real, sense les dades de demostració:

```bash
flutter build apk --release --dart-define=USE_DEMO_DATA=false
```

La selecció pública es prepara amb l’[exportador](tool/publish/LEEME.md) (en castellà).
La signatura i la publicació requereixen una preparació i una revisió a part. Els fitxers generats es
versionen; si canvies Drift, freezed o JSON, executa `dart run build_runner build`.

[Regenerar imatges i captures](tool/store/LEEME.md) ·
[Generar la web de privacitat](web/legal/LEEME.md) · [Disseny](docs/diseno.md) (en castellà).

## Llicències i seguretat

Codi [MIT](LICENSE), Copyright (c) 2026 Daniel Mont Ferrandiz.
Contingut propi [CC BY-SA 4.0](LICENSE-CONTENT.md). Les fonts oficials de
festius i els materials de tercers conserven les seves condicions, detallades en
aquestes llicències.

Per comunicar una vulnerabilitat: [SECURITY.md](SECURITY.md).
