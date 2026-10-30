# Changelog

What changes in each version of Turnly (called Cuadrante until 0.6.14), newest first. The "Unreleased" section fills up as changes land and becomes
the next version on the day it ships.

Numbering: the last number goes up with fixes (0.6.12 → 0.6.13), the middle one with new features (→ 0.7.0), and 1.0.0
will be the production launch in the stores. Every version ships on
[GitHub](https://github.com/dferrandizmont/turnly/releases) and TestFlight; Google Play and the App Store get several
at once, so they can skip numbers.

## Unreleased

## 0.6.17 · 2026-10-30

Internal test build (private prerelease). It updates 0.6.16 without losing anything.

- Turnly has its own website, [turnly.mainshai.com](https://turnly.mainshai.com), in the app's five languages, with
  downloads, screenshots, FAQ and the full privacy policy.
- The privacy policy link in Settings opens the policy on the new website (`turnly.mainshai.com/privacy/`) instead of
  GitHub Pages.
- The support email is now `turnly@mainshai.com` (in Help and contact, the privacy policy and the READMEs).

## 0.6.16 · 2026-10-30

Google Play closed test (with the 0.6.13 to 0.6.15 changes).

- The privacy policy link in Settings opens its new address, `dferrandizmont.github.io/turnly`, after the GitHub
  repository was renamed to `turnly`.

## 0.6.15 · 2026-10-30

Internal test build (private prerelease). It updates 0.6.14 without losing anything.

- The app is now called **Turnly** (formerly Cuadrante): app name, widgets and texts in all five languages. Backups are
  saved as `.turnly`, and older `.cuadrante` backups still open. Calendar exports are marked "Creado con Turnly", and
  events exported before are still recognised.
- The READMEs follow the common template: English is now the main `README.md`, with Spanish, Catalan, Galician and Basque versions, and the build and test instructions move to `CONTRIBUTING.md` and `CONTRIBUTING.es.md`.

## 0.6.14 · 2026-10-29

Google Play closed test (with the 0.6.13 changes) and APK on GitHub.

- Android: shift alarms are now system alarm clocks, so battery saver and phone makers can no longer delay them;
  the next one shows as the next alarm (status bar icon and lock screen).

## 0.6.13 · 2026-10-28

Internal test build (private prerelease). The app ID is now `es.cuadrante.app`, so it installs as a new app next
to 0.6.12 test builds: export a `.cuadrante` backup from the old one and restore it in the new one.

- iPhone: texts no longer point to Android settings or to Drive (backup, calendar permission, alarm permissions), and
  "Snooze" on a shift alarm works with the app closed.
- The month's Grid / List switch is now a single segmented control with an icon and a label. When the list reads
  better (large text, or shifts that do not fit in the day cell), a dot next to "List" says so.
- Switching to the list now centres the day instead of leaving it under the "Paint" button.
- iPhone: the app name and the calendar permission texts in all five languages.

## 0.6.12 · 2026-10-27

First public release: Google Play closed test and APK on GitHub.

- Shift calendar with colour, code and time for every shift; paint mode and rotation patterns.
- Several shifts per day, several calendars and side-by-side comparison.
- Home screen widgets, alarms and reminders.
- National, regional and local public holidays, offline.
- Hours summary with night and holiday hours, overtime and hourly rate.
- Backups with "Test restore"; import from LRHSoft, the phone's calendar, `.ics` and CSV.
- In Spanish, Catalan, Galician, Basque and English; light and dark mode.
- Completely free and open source: no account, no ads, no purchases.
