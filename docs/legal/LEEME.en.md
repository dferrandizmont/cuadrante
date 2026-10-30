# Legal documents

Not legal advice; have a professional review them before launch. Spanish version (authoritative):
[LEEME.md](LEEME.md).

| File | What it is | Status |
|---|---|---|
| `politica-privacidad.md` | Privacy policy to publish (GDPR and Spanish LOPDGDD), informal register. Mirrors [`docs/privacy.md`](../privacy.md), the technical source of truth. | No placeholders: holder, email and date are filled in. The internal notes are at the end of this document. |
| `politica-privacidad.en.md` | Courtesy English translation. The Spanish one applies. | Keep in step with the Spanish one. |
| `../privacy.md` and `../privacy.en.md` | Technical inventory of data, permissions, backups and exports, checked against the code. | Review whenever the data flow changes. |
| `../../SECURITY.md` and `SECURITY.en.md` | How to report a vulnerability without sending real data. | — |
| `../../LICENSE` and `../../LICENSE-CONTENT.md` (`.en.md`) | MIT for the code; CC BY-SA 4.0 for own content; official holidays, Mochila and third parties set apart. | — |

Convention: the Spanish text is the one that applies; each document has its English version in `*.en.md` next to it.

## How they are kept in sync with the website
The policy is published on the app's website, `https://turnly.mainshai.com/privacy/` (English at `/en/privacy/`;
Catalan, Galician and Basque show the Spanish one with a notice), generated **from this markdown** without
summarising it:

1. The sources are `docs/legal/politica-privacidad.md` and its translation `politica-privacidad.en.md`. The shared
   website generator (`mainshai-web`, `sitegen`) reads them as set in `web/site.toml` and checks that the published
   text matches the markdown and that `privacy_date` in `web/content/<language>.json` is the "Last updated" date.
2. The same URL goes in both store listings and in the "Privacy policy" row of Settings › Help, already implemented:
   it opens the external browser only when tapped. The build uses `PRIVACY_URL` for the Spanish policy and
   `PRIVACY_URL_EN` for the English one (the URLs above by default; `--dart-define` can override them).
3. **If the data flow changes**, update together and in the same commit: `docs/privacy.md`, this policy (and both
   English versions), the "Last updated" date, `privacy_date` in `web/content/*.json` and the store declarations
   (`docs/tienda/google-play.md`, "Data safety"; `docs/tienda/app-store.md`, "App Privacy"). Then rebuild and deploy
   the website (`web-app` skill).

Until 30-Oct-2026 it was published on GitHub Pages (`web/legal/`, `gh-pages` branch); those pages are retired with a
redirect to the new website.

## Checklist to publish
1. Review the notes for the holder below and, if needed, change the email retention period or the date.
2. Check the support email in the build: `kSupportEmail` (`app/lib/core/config.dart`) already contains
   `turnly@mainshai.com`; `SUPPORT_EMAIL` can override it.
3. Build, check and deploy the app's website.
4. Put the URL in both store listings and check it matches "Data safety" (Play) and "App Privacy" (Apple): no data
   collected.

## Notes for the holder
They used to sit at the end of the Spanish policy and moved here on 30-Oct-2026, when the policy went to the new
website. See the Spanish [LEEME.md](LEEME.md#notas-para-el-titular): support email `turnly@mainshai.com` (formerly
`dev@mainshai.com`), email retention of one year after the last reply, no tax ID published, and decision 13 of
`docs/preguntas.md` still pending.
