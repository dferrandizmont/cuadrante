# Legal documents

Not legal advice; have a professional review them before launch. Spanish version (authoritative):
[LEEME.md](LEEME.md).

| File | What it is | Status |
|---|---|---|
| `politica-privacidad.md` | Privacy policy to publish (GDPR and Spanish LOPDGDD), informal register. Mirrors [`docs/privacy.md`](../privacy.md), the technical source of truth. | No placeholders: holder, email and date are filled in. Review the "Notas para el titular" at the end, which the HTML generator **omits**. |
| `politica-privacidad.en.md` | Courtesy English translation. The Spanish one applies. | Keep in step with the Spanish one. |
| `../privacy.md` and `../privacy.en.md` | Technical inventory of data, permissions, backups and exports, checked against the code. | Review whenever the data flow changes. |
| `../../SECURITY.md` and `SECURITY.en.md` | How to report a vulnerability without sending real data. | — |
| `../../LICENSE` and `../../LICENSE-CONTENT.md` (`.en.md`) | MIT for the code; CC BY-SA 4.0 for own content; official holidays, Mochila and third parties set apart. | — |

Convention: the Spanish text is the one that applies; each document has its English version in `*.en.md` next to it.

## How they are kept in sync with the website
The policy is published as a static page generated **from this markdown**, never hand-edited HTML, with the same
scheme as Ley al Blanco (`web/legal/`, task T08 of the publication plan):

1. The source is `docs/legal/politica-privacidad.md`. The generator (`web/legal/md2html.py`) turns the markdown into
   `web/legal/privacidad/index.html` and **omits** the "Notas para el titular" section. The English version is
   generated the same way from `politica-privacidad.en.md` to `web/legal/privacidad/en/index.html`.
2. A test (`web/legal/test_legal.py`) compares the generated HTML with the markdown and fails when they differ, so
   nobody edits the HTML by hand or forgets to regenerate.
3. The page is pushed to the `gh-pages` branch of the public repository and served by GitHub Pages
   (`https://dferrandizmont.github.io/turnly/privacidad/`, to confirm once the repository exists).
4. That same URL goes into both store listings and the implemented "Privacy policy" row in Settings › Help, which
   opens the external browser only when tapped. The build uses `PRIVACY_URL` for the Spanish policy and
   `PRIVACY_URL_EN` for English (the URLs above by default; override them with `--dart-define`).
5. **If the data flow changes**, update together, in the same commit: `docs/privacy.md`, this policy (and both
   English versions), the "Last updated" date and the store declarations (`docs/tienda/google-play.md`, "Seguridad
   de los datos"; `docs/tienda/app-store.md`, "App Privacy"). Then regenerate the HTML and push `gh-pages` again.

## Checklist to publish
1. Review the "Notas para el titular" and, if needed, change the email retention period or the date.
2. Check the support email in the build: `kSupportEmail` (`app/lib/core/config.dart`) already contains
   `dev@mainshai.com`; `SUPPORT_EMAIL` can override it.
3. Generate the HTML, run the test and push `gh-pages`.
4. Put the URL in both store listings and check it matches "Data safety" (Play) and "App Privacy" (Apple): no data
   collected.
