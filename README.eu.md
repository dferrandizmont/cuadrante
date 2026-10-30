[English](README.md) · [Español](README.es.md) · [Català](README.ca.md) · [Galego](README.gl.md) · **Euskara**

<p align="center">
  <img src="docs/readme/eu/header.png" alt="Turnly — Zure txandak, begi-kolpe batean. Doan, iragarkirik gabe eta konexiorik gabe." width="1024">
</p>

# Turnly

Lehen Cuadrante zuen izena.

[![Kodea: MIT](https://img.shields.io/badge/Kodea-MIT-4B4FD1)](LICENSE)
[![Edukia: CC BY-SA 4.0](https://img.shields.io/badge/Edukia-CC_BY--SA_4.0-4B4FD1)](LICENSE-CONTENT.md)
[![Azken bertsioa](https://img.shields.io/github/v/release/dferrandizmont/turnly?include_prereleases&label=bertsioa&color=4B4FD1)](https://github.com/dferrandizmont/turnly/releases)
[![Deskargak](https://img.shields.io/github/downloads/dferrandizmont/turnly/total?label=deskargak&color=4B4FD1)](https://github.com/dferrandizmont/turnly/releases)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Lagundu_proiektua-FF5E5B?logo=kofi&logoColor=white)](https://ko-fi.com/danielmfdev)

Txanden egutegia Espainian txandaka lan egiten dutenentzat: osasungintza, polizia,
suhiltzaileak, industria, ostalaritza edo beste edozein sektore. Antolatu goizak,
arratsaldeak, gauak, guardiak eta egun libreak, eta ikusi hurrengo txanda begi-kolpe
batean. Bost hizkuntza: español, català, galego, euskara eta English.

**Doakoa · Iragarkirik gabe · Konturik gabe · Konexiorik gabe · Kode irekia**

Eskuragarri dauden funtzio guztiak irekita daude, Pro bertsiorik eta aplikazio
barneko erosketarik gabe.

## Deskargak

<p>
  <a href="https://play.google.com/apps/testing/es.cuadrante.app"><img src="https://img.shields.io/badge/Google_Play-Beta-414141?logo=googleplay&amp;style=for-the-badge" alt="Google Play-ko beta"></a>
  <a href="https://github.com/dferrandizmont/turnly/releases/latest"><img src="https://img.shields.io/badge/Deskargatu-GitHub-181717?logo=github&amp;style=for-the-badge" alt="Deskargatu GitHub-etik"></a>
  <!--
  <a href="[ENLACE_APP_STORE]"><img src="https://img.shields.io/badge/App_Store-Deskargatu-0D96F6?logo=appstore&amp;style=for-the-badge" alt="App Store-n eskuragarri"></a>
  -->
</p>

Android probetan; iPhone, laster. Modu argia eta iluna.

<details>
<summary>Sartu Google Play-ko betan</summary>

Aplikazioa proba itxian dago Google Play-n, eta edonor sar daiteke:

1. Sartu testerren taldean: [turnly-testers](https://groups.google.com/g/turnly-testers). Zure Google kontuarekin, sakatu taldean sartzeko botoia.
2. Onartu proba mugikorretik edo ordenagailutik: [play.google.com/apps/testing/es.cuadrante.app](https://play.google.com/apps/testing/es.cuadrante.app).
3. Instalatu aplikazioa Google Play-tik. Bere kabuz eguneratuko da.

Ahal baduzu, egon proban gutxienez 14 egunez eta erabili noizean behin (adibidez, begiratu biharko txanda edo jarri widgeta): Google-k 12 tester eskatzen ditu 14 egunez, aplikazioa guztientzat argitaratzeko. Iruzkinak, turnly@mainshai.com helbidera.

</details>

<details>
<summary>Instalatu APKa GitHub-etik</summary>

[Azken bertsioaren](https://github.com/dferrandizmont/turnly/releases/latest) APKa ere deskarga dezakezu eta eskuz instalatu (jatorri ezezaguneko aplikazioak instalatzea baimendu behar da). Google Play-ko bertsioaren beste gako batekin dago sinatuta; beraz, batak ez du bestea eguneratzen: aldatzeko, esportatu lehenago kopia bat aplikaziotik (`.turnly`; aurreko bertsioek `.cuadrante` gisa gordetzen dute).

</details>

## Pantaila-argazkiak

<p>
  <a href="docs/readme/eu/01-mes.png"><img src="docs/readme/eu/01-mes.png" width="19%" alt="Margotutako hilabetea eta hurrengo txandaren txartela"></a>
  <a href="docs/readme/eu/02-lista.png"><img src="docs/readme/eu/02-lista.png" width="19%" alt="Hilabete bera Zerrenda ikuspegian, kode eta ordutegi osoekin"></a>
  <a href="docs/readme/eu/03-pintar.png"><img src="docs/readme/eu/03-pintar.png" width="19%" alt="Margotze modua, txanden paletarekin"></a>
  <a href="docs/readme/eu/04-rotaciones.png"><img src="docs/readme/eu/04-rotaciones.png" width="19%" alt="Txandaketen laguntzailea, aplikatu aurreko aurrebistarekin"></a>
  <a href="docs/readme/eu/05-horas.png"><img src="docs/readme/eu/05-horas.png" width="19%" alt="Lan egindako orduen, gaueko orduen eta jaiegunetako orduen hileko laburpena"></a>
</p>

<details>
<summary>Pantaila-argazki gehiago</summary>

<p>
  <a href="docs/readme/eu/06-festivos.png"><img src="docs/readme/eu/06-festivos.png" width="19%" alt="Madrilgo Erkidegoko eta Madril udalerriko jaiegunak"></a>
  <a href="docs/readme/eu/07-mes-oscuro.png"><img src="docs/readme/eu/07-mes-oscuro.png" width="19%" alt="Hilabete bera gai ilunarekin"></a>
</p>

</details>

Sakatu pantaila-argazki bat handitzeko. Benetako pantailak dira, datu asmatuekin, eta
[Flutter-en testek](app/test/store/) sortzen dituzte; [gaztelaniaz](README.es.md#capturas) ere badaude.

## Funtzioak

- **Hilabetea Sareta edo Zerrenda gisa.** Urteko ikuspegia, agenda eta eguneko
  oharrak. Txanda bakoitzak kolorea, kodea eta ordutegia ditu; Zerrendan ordutegi
  osoak irakur daitezke. Noizbehinka esportatzea mugikorreko egutegira, eta
  hilabetearen eta urtearen irudiak.
- **Txandak margotzea eta txandaketak.** Ukituz edo arrastatuz, hainbat egun
  hautatu, bikoiztu, kopiatu eta itsatsi, desegin eta berregin; txandaketen
  laguntzailea aurrebistarekin: txanda birakariak, 24/72, 4×4, 6×4, 5×2, 2-2-3
  eta eredu propioak. Txanda motak, koloreak, ikonoak eta ordutegiak editagarriak
  dira.
- **Espainiako jaiegunak.** Estatukoak eta erkidegokoak konexiorik gabe datoz; tokikoak,
  eskuragarri dauden udalerrietarako, eta zureak gehitzeko aukera.
- **Alarmak eta widgetak.** Alarmak txanda motaren arabera, oharren gogorarazpenak
  eta Androiderako widgetak zure txandak hasierako pantailatik ikusteko.
  Puntualtasuna sistemaren baimenen eta murrizketen araberakoa da. iPhoneko
  widgeta (WidgetKit) Mac-ean garatzeko dago oraindik.
- **Babeskopia lokala eta inportatzea.** Tokiko babeskopia automatikoak,
  `.turnly` fitxategira esportatzea (`.cuadrante` kopia zaharrak ere irekitzen dira), leheneratu aurreko aurrebista eta «Probatu
  leheneratzea». LRHSoft-en `.Shifter` kopiak, `.ics` edo CSV fitxategiak eta
  mugikorreko egutegiko gertaerak inportatzea, txandak gorde aurretik berrikusita.
- **Orduen laburpena.** Lan egindako orduak, gaueko orduak, jaiegunetako orduak,
  aparteko orduak eta irteera aurreratuak; diru-sarreren estimazioa, orduko
  prezioarekin eta txandako osagarri finkoarekin.

<details>
<summary>Funtzio gehiago</summary>

- **Hainbat egutegi.** Ordaindu beharreko mugarik gabe, eta bi egutegi alderatzeko
  aukera.
- **Irisgarritasuna.** Hizkuntza-hautatzailea, pantaila-irakurgailua eta testu
  handigarria; txandak ez daude inoiz kolorearen mende bakarrik.

</details>

## Pribatutasuna

Txandak eta ezarpenak mugikorrean gordetzen dira. Ez dago zerbitzari propiorik,
analitikarik, jarraipenik ezta errore-txostenen bidalketarik ere. Aplikazioak
**egutegirako** baimena eskatzen du inportatzean edo esportatzean, eta
**jakinarazpenetarako eta alarmetarako** baimena abisuak aktibatzean.

<details>
<summary>Baimenak eta kopiak</summary>

Ez du kokapenik, kontakturik, kamerarik ezta mikrofonorik eskatzen.

Google-ren edo Apple-ren sistemako kopiek zure datuak izan ditzakete, absentziak
barne. Sinkronizatutako egutegi batera esportatzen baduzu edo kopia bat partekatzen
baduzu, datuak zuk aukeratutako helmugara joaten dira. `.turnly` kopia-fitxategia ez
dago zifratuta.

</details>

[Webgunea](https://turnly.mainshai.com/eu/) · [Pribatutasun-politika](https://turnly.mainshai.com/eu/privacy/) ·
[Xehetasun teknikoak](docs/privacy.md) (gaztelaniaz) · Laguntza: **turnly@mainshai.com**.

## Berriak

Zer aldatu den bertsio bakoitzean [CHANGELOG.md](CHANGELOG.md) eta
[argitalpenetan](https://github.com/dferrandizmont/turnly/releases) dago.

## Lagundu

Akatsen berriak, ideiak eta itzulpenak onartzen ditugu. Nola konpilatu, probatu
eta lagundu: [CONTRIBUTING.es.md](CONTRIBUTING.es.md).

## Lizentziak

Kodea: [MIT](LICENSE), Copyright (c) 2026 Daniel Mont Ferrandiz. Eduki propioa:
[CC BY-SA 4.0](LICENSE-CONTENT.md). Jaiegunen iturri ofizialek eta hirugarrenen
materialek beren baldintzak dituzte, lizentzia horietan zehaztuta.

Ahultasun baten berri emateko: [SECURITY.md](SECURITY.md).
