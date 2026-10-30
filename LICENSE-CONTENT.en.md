# Content licences

Copyright (c) 2026 Daniel Mont Ferrandiz, for the content written by the author.

Spanish version (authoritative): [LICENSE-CONTENT.md](LICENSE-CONTENT.md).

## Own content: CC BY-SA 4.0

The documentation in `docs/` and `turnos-spec.md`, the app texts
(`app/lib/l10n/*.arb` and their translations), the icon and launch screen
(`app/assets/icon/`, generated with `tool/icon/`), the screenshots and the
store material (`docs/tienda/`) are offered under Creative Commons
Attribution-ShareAlike 4.0 International (CC BY-SA 4.0).

You may share and adapt them, including for commercial purposes, with
attribution, indicating the changes and sharing adaptations under the same
licence. The attribution must identify Daniel Mont Ferrandiz and Turnly and
include a link to this licence. The
[CC BY-SA 4.0 legal code](https://creativecommons.org/licenses/by-sa/4.0/legalcode)
governs.

This licence covers only the author's own content. The name "Turnly" (formerly "Cuadrante") and the
icon identify this app: if you publish a modified version, give it another name
and icon so nobody mistakes it for the original.

## Official public holidays

The holiday calendars in `app/assets/holidays/` are built from data published by
public administrations. Each file records its source in
`app/assets/holidays/manifest.json` (`source`: URL, reference and publication
date) and its checksum (`docs/festivos.md`, "Formato del paquete"). Sources of
the bundled package:

| Data | Source |
|---|---|
| National and regional holidays 2026 and 2027 | Boletín Oficial del Estado: BOE-A-2025-21667 and BOE-A-2026-21254 (Dirección General de Trabajo) |
| Local holidays, Community of Madrid | Boletín Oficial de la Comunidad de Madrid, BOCM no. 296, 12 Dec 2025 |
| Local holidays, Region of Murcia (school-calendar ones only) | Boletín Oficial de la Región de Murcia, BORM no. 132, 11 Jun 2026 and no. 167, 22 Jul 2026 |
| Local holidays, Catalonia | Dades Obertes de Catalunya, dataset `b4eh-r8up` (Departament d'Empresa i Treball) |
| Municipality index (code and name) | Instituto Nacional de Estadística (INE) |

Texts of official provisions published in official gazettes carry no copyright
under article 13 of the Spanish Intellectual Property Act, and administrative
data are reused under Act 37/2007 on the reuse of public sector information,
citing the source and without altering its meaning. Open-data sets (Catalonia,
INE) are reused under their portal's terms, which require attribution. **These
data are excluded from both MIT and CC BY-SA 4.0**: what is ours is the
selection, the transformation to JSON and the tests, not the official content.
No administration reviews or endorses this app.

## Other apps' formats

The import reads LRHSoft backups (`.Shifter`) and `.ics` and CSV files so you
can bring your history over (`docs/importar.md`). The reader is our own code
under MIT; the repository contains no code, data or material from LRHSoft or
any other app, and their names belong to their owners. The test files
(`app/test/fixtures/`) are synthetic.

## Code from Mochila

Part of `app/lib/core/` and of the holidays feature
(`app/lib/features/holidays/`) is copied and adapted from Mochila, another
project by the same author (Daniel Mont Ferrandiz), as the files themselves
note. Same copyright holder, so it is offered here under MIT with no additional
condition.

## Third-party code and material

The code is offered under [MIT](LICENSE). Flutter and pub.dev dependencies keep
their own licences; the app shows them under Settings › "Open-source licences"
(Flutter's licence page) and the exact list is in `app/pubspec.lock`. In
particular:

- The `cupertino_icons` icons are distributed under MIT (Copyright (c) 2016
  Vladimir Kharlampidi) and the `material_symbols_icons` icons under the Apache
  License 2.0 (Google). They keep their notices: not everything in the binary
  becomes MIT.
- `dbus` (MPL-2.0) comes in as a transitive dependency of
  `flutter_local_notifications` for Linux. It is not part of the Android or iOS
  apps; if you build for Linux its terms apply (the `dbus` code can be used
  unchanged, and modifications to it stay under MPL-2.0).
- No fonts are distributed: the app uses the system typeface. Tests load Roboto
  from the Flutter SDK.
