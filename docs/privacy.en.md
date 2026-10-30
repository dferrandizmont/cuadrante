# Privacy and compliance

Not legal advice. Summarises what the app does with data, checked against the code on 26 Oct 2026; review with a
professional before launch. The user-facing policy is
[`docs/legal/politica-privacidad.md`](legal/politica-privacidad.md) (English:
[`politica-privacidad.en.md`](legal/politica-privacidad.en.md)) and must say the same as this document.
Spanish version (authoritative): [`privacy.md`](privacy.md).

## Data flow (owner's decision, 26 Oct 2026)
- **The app talks to no server.** No accounts, own server, analytics, telemetry, ads, purchases or install
  identifiers. The Android release manifest does not declare `INTERNET` (only the `debug` and `profile` ones, for
  Flutter); the Dart code has no HTTP client. Holidays ship inside the app (`app/assets/holidays/`); the remote
  download described in `docs/festivos.md` does not exist.
- **Crash reports:** the only `CrashReporter` installed is `NoopCrashReporter` (`app/lib/main.dart`), wrapped in
  `RedactingCrashReporter`: nothing leaves the phone. Should a backend ever be added, the interface
  (`app/lib/core/diagnostics/crash_reporting.dart`) only lets the error type and stack through, never the message.
- **100 % free and open-source app**: MIT code, own content CC BY-SA 4.0 (`LICENSE`, `LICENSE-CONTENT.md`). The
  configuration **no longer has** RevenueCat fields (the `rcApiKey*` ones were removed from
  `app/lib/core/config.dart`); there is no purchases SDK in `app/pubspec.yaml`.
- Everything works offline and without asking for name, email, phone or age.

## What is stored on the phone
Drift database `cuadrante.sqlite` in Application Support (`docs/datos.md`): calendars, shift types, rotations,
per-day exceptions, **notes**, reminders, overtime, **absences** (holidays, personal days, leave and **sick leave**,
category `absence`), own public holidays, region and municipality, hourly rate and settings. No device or user
identifiers.

**Health data.** Sick leave is an absence type like any other and lives in the same database. No shared feed or
analytics; it is included in the backups described below, per decision 13 resolved by the user on 26 Oct 2026.
Where it does and does not appear, per the current code:

| Where | What happens with absences (sick leave included) |
|---|---|
| Alarms | Never ring (`alarm_planner.dart`; `docs/alarmas.md`): a "sick leave" notice on the lock screen would expose health data. A note reminder on an absence day uses the neutral body "You have a reminder for today". |
| Today, week and month widgets | Show the day's shifts as the calendar does, absences included (type code and colour), and their accessibility descriptions name every shift of the day (`docs/widget-contrato.md`, `descriptions` extension; `widget_snapshot_builder.dart`). On the phone only, but visible to whoever holds it. |
| Agenda and two-week widgets | Anonymised: "Absence", with no code, name, hours or note mark. |
| Notes | Only whether the day has a note travels to the widget, never the text. |
| `.cuadrante` backup | Included (next section). |
| Android system backup | Included, with the database ("System backups"). |
| Export to the phone calendar | Not exported unless the user turns on "Include absences" (off by default). |

Decision 13 in `docs/preguntas.md` **was resolved by the user on 26 Oct 2026: keep the current behaviour**. Health
absences remain in the same database and travel in `.cuadrante` and system backups, as the policy explains.
No separate store is created. Enabling the iCloud replica is a separate decision, pending for the Mac;
`kICloudReplica` remains `false`.

## Permissions
All are requested when the user touches the feature, never at launch.

| Permission | Purpose | Where |
|---|---|---|
| Notifications (`POST_NOTIFICATIONS`, Android 13+; notification permission on iOS) | Shift alarms and note reminders. Requested when enabling them or testing an alarm (`alarm_providers.dart`, `ensureNotificationPermission`). | `AndroidManifest.xml` |
| Exact alarms (`SCHEDULE_EXACT_ALARM`) | So the alarm rings on time and the widget changes day at midnight. Without it, inexact alarms. `USE_EXACT_ALARM` is not used. | `AndroidManifest.xml` |
| `RECEIVE_BOOT_COMPLETED`, `VIBRATE` | Re-arm the alarms after a reboot or an update; vibrate. | `AndroidManifest.xml` |
| `HIDE_OVERLAY_WINDOWS` (normal, no dialog) | Keep the restore preview from being covered by another app (tapjacking). | `AndroidManifest.xml`, `MainActivity` |
| Calendar (`READ_CALENDAR`, `WRITE_CALENDAR`; `NSCalendars*UsageDescription` on iOS) | Read events when importing from the phone calendar; write on a one-off export. Only during that action, never in the background. | `AndroidManifest.xml`, `app/ios/Runner/Info.plist`, `docs/importar.md` |

No location, contacts, photos, camera, microphone, general storage or network permissions. Files are chosen with the
system picker (`file_selector`) and shared with the system share sheet (`share_plus`).

## Backups (`docs/copia-de-seguridad.md`)
- **`.cuadrante`:** canonical JSON, gzip-compressed, with a checksum; **not encrypted**. Contains everything the user
  created (absences and notes included), with no accounts or identifiers. First-use settings and the language are
  left out.
- **Automatic local copies:** after each burst of changes, in `<Application Support>/backups`: the 7 newest plus the
  last of each day of the past 30; pre-restore and pre-migration copies, the last 3 of each. All on the phone;
  nothing is sent.
- **Export and restore:** the user saves or shares the file with the system sheet (`_shareWithSystem`,
  `backup_providers.dart`) and opens it from Files, Drive or WhatsApp; nothing is restored without confirmation in
  the preview. Where that file ends up is their choice.
- **iCloud replica: off.** `kICloudReplica = false` in `backup_providers.dart`; the Swift channel does not exist
  and, even if it did, the Settings switch would be needed. Enabling it requires a separate decision on the Mac,
  per the user's 26 Oct 2026 response to decision 13.

## System backups
- **Android (Auto Backup):** `allowBackup="true"` with explicit rules (`res/xml/backup_rules.xml`,
  `data_extraction_rules.xml`): `files/` (the database and `backups/`) goes in, nothing else. The system uploads it
  to the user's Google account and transfers it phone to phone; end-to-end encrypted with the screen lock on Android
  9 or later **if the user has a lock**. We never see it, but the data **does leave the phone** that way, absences
  included. Do not say "never leaves the phone".
- **iOS:** the database is part of the iPhone backup (iCloud or computer), managed by the user with their Apple ID.

## Import and export (`docs/importar.md`)
- **Import** from the phone calendar, from `.ics` or CSV files, or from an LRHSoft backup (`.Shifter`): read on the
  phone, grouped on the phone, and only what the user accepts is saved. Error messages never carry text from the
  file. Other apps' files are treated as hostile input (read-only, size limits, temporary copy that is deleted).
- **Export to the phone calendar** (one-off, by user action): writes title ("Mañana · M"), hours and an own tag;
  never notes or amounts. If that calendar syncs with an account (Google, iCloud, Exchange), **the system uploads it
  to that account**, outside the app's control; the screen says so. Absences and days off only with their
  switches, off by default.
- There is no export to `.ics`, CSV, PDF or share by link: the only data outputs are the `.cuadrante` file and the
  phone calendar.

## Widgets (`docs/widget-contrato.md`)
The app writes a JSON with the next 60 days (plus the auxiliary agenda and two-week days) to the store shared with
the widgets: `UserDefaults` of the App Group `group.es.cuadrante.app` on iOS and `home_widget` preferences on Android,
which are not part of the system backup. Only this app's widgets read it.

## Support and links
"Help and contact" (Settings) shows the support address to **copy**; the app does not open mail.
The address is **dev@mainshai.com**, defined in `kSupportEmail`
(`app/lib/core/config.dart`); the build can override it with `--dart-define=SUPPORT_EMAIL=...`.
"Open-source licences" opens Flutter's licence page, offline.
"Privacy policy" (Settings › Help) opens the website in the **external browser**, only when tapped, through the
official `url_launcher` plugin. It sends no roster data and adds no `INTERNET` permission to the app: the browser
makes the connection. `PRIVACY_URL` defaults to `https://dferrandizmont.github.io/turnly/privacidad/`;
English uses `PRIVACY_URL_EN` (`https://dferrandizmont.github.io/turnly/privacidad/en/`). Both URLs can be
overridden with `--dart-define`. Other languages use the authoritative Spanish policy.

## Store declarations
- App Store, App Privacy: **no data collected**, no tracking, no in-app purchases (`docs/tienda/app-store.md`).
- Google Play, Data safety: **no data collected or shared** by the app; no ads or purchases. Reading the calendar or
  saving notes on the phone is not collection (`docs/tienda/google-play.md`, "Seguridad de los datos"). Declare the
  calendar and exact-alarm permissions with their justification.
- No accounts to delete; data is removed by uninstalling the app or clearing its data from the system (and, where
  relevant, from the user's Google or iCloud backups).
- Review the forms against the final AAB/IPA and publish a policy URL consistent with these facts.

## Pending before launch
- [x] Decision 13 resolved (user, 26 Oct 2026): keep the current behaviour, with health absences in the same database
      and in backups, as the policy explains.
- [ ] Check the "Help and contact" screen in the release build; `kSupportEmail` already contains `dev@mainshai.com`.
- [ ] Publish the privacy policy (URL), link it from both stores and check both URLs using the implemented
      Settings row (`docs/legal/LEEME.md`).
- [ ] Fill in App Privacy (Apple) and Data safety (Play) with the final binary.
- [ ] Keep `kICloudReplica = false` until the separate decision on enabling the replica on the Mac.
- [ ] Review this document whenever the data flow changes (permissions, backups, exports, support).
