[Español](README.md) · [Català](README.ca.md) · [Galego](README.gl.md) · [Euskara](README.eu.md) · [English](README.en.md)

<p align="center">
  <img src="docs/readme/eu/header.png" alt="Cuadrante — Zure txandak, begi-kolpe batean. Doan, iragarkirik gabe eta konexiorik gabe." width="1024">
</p>

# Cuadrante

[![Kodea: MIT](https://img.shields.io/badge/Kodea-MIT-4B4FD1)](LICENSE)
[![Edukia: CC BY-SA 4.0](https://img.shields.io/badge/Edukia-CC_BY--SA_4.0-4B4FD1)](LICENSE-CONTENT.md)
[![Azken bertsioa](https://img.shields.io/github/v/release/dferrandizmont/cuadrante?include_prereleases&label=bertsioa)](https://github.com/dferrandizmont/cuadrante/releases)

Txanden egutegia Espainian txandaka lan egiten dutenentzat: osasungintza, polizia,
suhiltzaileak, industria, ostalaritza edo beste edozein sektore. Antolatu goizak,
arratsaldeak, gauak, guardiak eta egun libreak, eta ikusi hurrengo txanda begi-kolpe batean.

**Guztiz doakoa, iragarkirik, konturik eta konexiorik gabe. Kode irekia.**
Eskuragarri dauden funtzio guztiak irekita daude, Pro bertsiorik eta aplikazio barneko
erosketarik gabe. Android probetan; iPhone, laster. Modu argia eta iluna.

## Deskargak

<p>
  <a href="https://play.google.com/apps/testing/es.cuadrante.app"><img src="https://img.shields.io/badge/Google_Play-Beta-414141?logo=googleplay&amp;style=for-the-badge" alt="Google Play-ko beta"></a>
  <a href="https://github.com/dferrandizmont/cuadrante/releases/latest"><img src="https://img.shields.io/badge/Deskargatu-GitHub-181717?logo=github&amp;style=for-the-badge" alt="Deskargatu GitHub-etik"></a>
  <!--
  <a href="[ENLACE_APP_STORE]"><img src="https://img.shields.io/badge/App_Store-Deskargatu-0D96F6?logo=appstore&amp;style=for-the-badge" alt="App Store-n eskuragarri"></a>
  -->
</p>

### Google Play-ko beta

Aplikazioa proba itxian dago Google Play-n, eta edonor sar daiteke:

> **Une honetan, Google lehen bertsioa berrikusten ari da.** Taldean sar zaitezke dagoeneko (1. urratsa); 2. urratseko esteka onartu bezain laster ibiliko da, normalean egun gutxiren buruan.

1. Sartu testerren taldean: [cuadrante-testers](https://groups.google.com/g/cuadrante-testers). Zure Google kontuarekin, sakatu taldean sartzeko botoia.
2. Onartu proba mugikorretik edo ordenagailutik: [play.google.com/apps/testing/es.cuadrante.app](https://play.google.com/apps/testing/es.cuadrante.app).
3. Instalatu aplikazioa Google Play-tik. Bere kabuz eguneratuko da.

Ahal baduzu, egon proban gutxienez 14 egunez eta erabili noizean behin (adibidez, begiratu biharko txanda edo jarri widgeta): Google-k 12 tester eskatzen ditu 14 egunez, aplikazioa guztientzat argitaratzeko. Iruzkinak, dev@mainshai.com helbidera.

### APKa GitHub-en

[Azken bertsioaren](https://github.com/dferrandizmont/cuadrante/releases/latest) APKa ere deskarga dezakezu eta eskuz instalatu (jatorri ezezaguneko aplikazioak instalatzea baimendu behar da). Google Play-ko bertsioaren beste gako batekin dago sinatuta; beraz, batak ez du bestea eguneratzen: aldatzeko, esportatu lehenago `.cuadrante` kopia bat aplikaziotik.

Laster App Store-n.

## Pantaila-argazkiak

<p>
  <a href="docs/readme/eu/01-mes.png"><img src="docs/readme/eu/01-mes.png" width="160" alt="Margotutako hilabetea eta hurrengo txandaren txartela, modu ilunean"></a>
  <a href="docs/readme/eu/02-lista.png"><img src="docs/readme/eu/02-lista.png" width="160" alt="Hilabete bera Zerrenda ikuspegian, kode eta ordutegi osoekin"></a>
  <a href="docs/readme/eu/03-pintar.png"><img src="docs/readme/eu/03-pintar.png" width="160" alt="Margotze modua, txanden paletarekin"></a>
  <a href="docs/readme/eu/04-rotaciones.png"><img src="docs/readme/eu/04-rotaciones.png" width="160" alt="Txandaketen laguntzailea, aplikatu aurreko aurrebistarekin"></a>
  <a href="docs/readme/eu/05-horas.png"><img src="docs/readme/eu/05-horas.png" width="160" alt="Lan egindako orduen, gaueko orduen eta jaiegunetako orduen hileko laburpena"></a>
  <a href="docs/readme/eu/06-festivos.png"><img src="docs/readme/eu/06-festivos.png" width="160" alt="Madrilgo Erkidegoko eta Madril udalerriko jaiegunak"></a>
</p>

Sakatu pantaila-argazki bat handitzeko. Benetako pantailak dira, datu asmatuekin, eta
[Flutter-en testek](app/test/store/) sortzen dituzte; [gaztelaniaz](README.md#capturas) ere badaude.

## Funtzioak

- Hilabetea **Sareta edo Zerrenda** gisa, urteko ikuspegia, agenda eta eguneko oharrak.
  Txanda bakoitzak kolorea, kodea eta ordutegia ditu; Zerrendan ordutegi osoak irakur daitezke.
- **Txandak margotu** ukituz edo arrastatuz, hainbat egun hautatu, bikoiztu,
  kopiatu eta itsatsi, desegin eta berregin. Txanda motak, koloreak, ikonoak eta ordutegiak editagarriak dira.
- **Txandaketak** laguntzailearekin eta aurrebistarekin: txanda birakariak, 24/72, 4×4,
  6×4, 5×2, 2-2-3 eta eredu propioak.
- **Hainbat egutegi**, ordaindu beharreko mugarik gabe, eta bi egutegi alderatzeko aukera.
- **Espainiako jaiegunak**: estatukoak eta erkidegokoak konexiorik gabe datoz;
  tokikoak, eskuragarri dauden udalerrietarako, eta zureak gehitzeko aukera.
- **Alarmak txanda motaren arabera** eta oharren gogorarazpenak. Puntualtasuna
  sistemaren baimenen eta murrizketen araberakoa da.
- **Androiderako widgetak**, zure txandak hasierako pantailatik ikusteko.
  iPhoneko widgeta (WidgetKit) Mac-ean garatzeko dago oraindik.
- **Tokiko babeskopia automatikoak**, `.cuadrante` fitxategira esportatzea,
  leheneratu aurreko aurrebista eta «Probatu leheneratzea».
- LRHSoft-en `.Shifter` kopiak, `.ics` edo CSV fitxategiak eta mugikorreko egutegiko
  gertaerak **inportatzea**, txandak gorde aurretik berrikusita.
- Lan egindako orduen, gaueko orduen, jaiegunetakoen, aparteko orduen eta irteera
  aurreratuen **laburpena**; diru-sarreren estimazioa, orduko prezioarekin eta txandako osagarri finkoarekin.
- Mugikorreko egutegira noizbehinka esportatzea, eta hilabetearen eta urtearen irudiak.
- **Bost hizkuntza:** español, català, galego, euskara eta English. Hizkuntza-hautatzailea,
  pantaila-irakurgailua eta testu handigarria; txandak ez daude inoiz kolorearen mende bakarrik.

## Pribatutasuna

Txandak eta ezarpenak mugikorrean gordetzen dira. Ez dago zerbitzari propiorik,
analitikarik, jarraipenik ezta errore-txostenen bidalketarik ere. Aplikazioak **egutegirako**
baimena eskatzen du inportatzean edo esportatzean, eta **jakinarazpenetarako eta alarmetarako**
baimena abisuak aktibatzean. Ez du kokapenik, kontakturik, kamerarik ezta mikrofonorik eskatzen.

Google-ren edo Apple-ren sistemako kopiek zure datuak izan ditzakete, absentziak barne.
Sinkronizatutako egutegi batera esportatzen baduzu edo kopia bat partekatzen baduzu,
datuak zuk aukeratutako helmugara joaten dira. `.cuadrante` fitxategia ez dago zifratuta.

[Pribatutasun-politika](https://dferrandizmont.github.io/cuadrante/privacidad/) ·
[Xehetasun teknikoak](docs/privacy.md) (gaztelaniaz) · Laguntza: **dev@mainshai.com**.

## Konpilatu eta probatu

Eskakizunak: **Flutter 3.47.7**, Android SDK Androiderako, edo macOS eta Xcode
iPhonerako. Aplikazioak Riverpod, go_router eta Drift erabiltzen ditu egoerarako,
nabigaziorako eta tokiko datu-baserako.

Biltegiaren errotik:

```bash
cd app
flutter pub get
flutter gen-l10n
flutter analyze
TZ=Europe/Madrid flutter test
```

Konexiorik gabe, erabili `flutter pub get --offline`, paketeak deskargatuta badituzu.
Windows-en, erabili sistemaren Madrilgo ordu-eremua (`Get-TimeZone`) eta exekutatu
`flutter test` `TZ` definitu gabe; Linuxeko IANA identifikatzaileak orduak aldatzen
ditu Windows-eko runtimean.

Benetako biltegiratzea duen eta demostrazioko daturik gabeko APK bat konpilatzeko:

```bash
flutter build apk --release --dart-define=USE_DEMO_DATA=false
```

Hautapen publikoa [esportatzailearekin](tool/publish/LEEME.md) (gaztelaniaz) prestatzen da.
Sinadurak eta argitalpenak aparteko prestaketa eta berrikuspena behar dituzte. Sortutako
fitxategiak bertsio-kontrolean daude; Drift, freezed edo JSON aldatzen badituzu, exekutatu
`dart run build_runner build`.

[Irudiak eta pantaila-argazkiak berriro sortu](tool/store/LEEME.md) ·
[Pribatutasun-webgunea sortu](web/legal/LEEME.md) · [Diseinua](docs/diseno.md) (gaztelaniaz).

## Lizentziak eta segurtasuna

Kodea: [MIT](LICENSE), Copyright (c) 2026 Daniel Mont Ferrandiz.
Eduki propioa: [CC BY-SA 4.0](LICENSE-CONTENT.md). Jaiegunen iturri ofizialek eta
hirugarrenen materialek beren baldintzak dituzte, lizentzia horietan zehaztuta.

Ahultasun baten berri emateko: [SECURITY.md](SECURITY.md).
