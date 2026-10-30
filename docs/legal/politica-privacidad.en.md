# Turnly privacy policy

Last updated: 30 October 2026

Courtesy translation. The Spanish version ([politica-privacidad.md](politica-privacidad.md)) is the one that
applies.

Turnly is a shift-work calendar app for shift workers in Spain. It is an independent app: not created, reviewed
or endorsed by any company, public body or union.

Summary: **you have no account, there is no server of ours and your shifts stay on your phone.** The app is entirely
free and open source, and sends no data or crash reports to anyone. The only things that can take your data off the
phone are the backups of your Google or Apple account and the files or calendars you choose to export, and you
control those.

## 1. Data controller

- Holder: Daniel Mont Ferrandiz
- Contact email: turnly@mainshai.com

## 2. What data is processed

### Data that stays on your phone (we never receive it)
Your calendars, shift types, rotations, day changes, notes, reminders, overtime, absences (holidays, personal days,
leave and sick leave), public holidays, region and municipality, hourly rate and settings are stored only in a local
database on the device. Official holidays ship inside the app and everything works offline. There is no sync and no
copy on any server of ours.

**Your sick leave is health data.** We never receive it: there is no server, no analytics and no shared calendar.
Alarms do not ring on absence days, and a note reminder on an absence day does not show the note's text, so none of
that reaches the lock screen. Bear in mind, though, that:

- the today, week and month widgets show the day's shifts on your home screen, including an absence with the code
  and colour you gave it, and their screen-reader description names them. The agenda and two-week widgets only say
  "Absence". The text of your notes never goes to the widget;
- absences, sick leave included, are part of your backups (see below), like the rest of your shifts.

### Backups
The app makes **automatic backups on your own phone** and lets you **export a backup to a `.turnly` file**
(Settings › Backup; older `.cuadrante` backups can also be opened) to keep wherever you like or move to another phone, and restore it later. That file contains your
shifts, notes and absences, carries no identifier and is not encrypted; you keep and control it: the app only hands
it to the app you pick in the system share sheet. What you do with it afterwards (upload it to your cloud, send it by
WhatsApp or email...) is outside the app. When you open a `.turnly` or `.cuadrante` file, nothing is restored until you confirm.

**System backup.** On Android, if Google backup is on, the system periodically uploads the app's database and
backups to your Google account and moves them to your new phone; on Android 9 or later it is end-to-end encrypted
with your screen lock, if you have one. On iPhone, the database is part of the device backup (iCloud or computer).
You manage those backups with your Google or Apple account and can turn them off in the system settings; the app
sends nothing on its own and keeps no backup of its own in iCloud.

### Phone calendar
Only if you ask, and only at that moment:

- **Import** reads the events of the calendar you choose (or of an `.ics` or CSV file, or a backup from another
  shift app) to suggest shifts. They are read and grouped on your phone, and only what you accept is saved.
- **Export** writes your shifts (name, code and hours; never notes or amounts) to the phone calendar you choose.
  **If that calendar syncs with an account** (Google, iCloud, Exchange...), your shifts will also appear in that
  account: the system uploads them, outside the app's control. The screen warns you. Absences and days off are not
  exported unless you turn on their switches.

The calendar permission is requested when you start importing or exporting, never at launch, and the app does not
read or write the calendar in the background.

### Permissions
Besides the calendar, the app asks for **notifications** and **alarms and reminders** permission when you enable
shift alarms or a note reminder, so they ring on time and the widget changes day at midnight. If you decline, alarms
may ring late. It does not ask for location, contacts, photos, camera, microphone or general storage access, and the
published Android version has no network permission.

### Communications
The app transmits no shifts, identifiers or crash reports. It uses no purchases, ads, analytics or third-party
services. Errors are handled on the device only.

If you tap "Privacy policy" in Settings › Help, this page opens in your external browser. The browser connects to
the website; Turnly sends it none of your shifts, notes or absences.

### Data NOT processed
- We do not ask for or store your name, email, phone, ID number, date of birth or employer details.
- No analytics, no ads, no personalised advertising, no cross-app tracking.
- We do not access your location, contacts, photos, camera or microphone.
- We do not receive your shifts, notes, absences or hours.

### If you write to us
"Help and contact" (Settings) shows you the support address to copy so you can write from your own mail app, with
the app version if you want to attach it. The app opens no mail client and sends nothing by itself. If you write to
us, we process your email address and what you tell us only to reply. Do not send us `.turnly` or `.cuadrante` backups or
screenshots with real shifts, notes or absences: made-up data is enough to fix a bug.

## 3. Purposes and legal basis

| Processing | Purpose | Legal basis (GDPR) |
|---|---|---|
| Shifts, notes, absences and settings on your phone | Keeping your roster, hours and alarms | We do not receive them: they stay on your device, under your control |
| Backups and exports | Not losing your data and changing phones | You make them; the services you use (Google, Apple, your cloud) have their own terms |
| Support emails | Answering your query | Your request and our legitimate interest in handling it (art. 6(1)(f)) |

We make no automated decisions and build no profiles about you.

## 4. Who receives the data
The app transmits no data to third parties. If you send a support email, the holder receives it at turnly@mainshai.com
through the mail service you choose. If you export to a synced calendar or have system backup on, the recipient of
that data is your account provider (Google, Apple or another), on your behalf and under its terms.

## 5. International transfers
The app makes no data transfers. External services you decide to use (mail, cloud, synced calendar or the destination
of an export) are governed by their own terms.

## 6. Retention

- **Data on your phone:** until you uninstall the app or clear its data from the system settings (and, where
  relevant, from your account's backups and the files you exported).
- **Support emails:** as long as needed to handle your query and at most one year after the last reply.

## 7. Your rights

You can exercise your rights of **access, rectification, erasure, objection, restriction of processing and
portability** by writing to turnly@mainshai.com. We will reply within one month.

We do not receive the data stored on your phone, so we cannot see or delete it for you. You can delete it by
uninstalling the app or clearing its data from the system settings, and take it with you using "Export backup".

If you believe we have not handled your data properly, you can complain to the Spanish Data Protection Agency:
https://www.aepd.es

## 8. Minors

The app is meant for working people. It does not ask for age or collect personal data from anyone, minors included:
shifts and settings stay on the device.

## 9. Security
There is no server and no data transmission from the app. Automatic backups are kept in the app's private folder.
You control exported files and the backups of your Google or Apple account; if your phone has a screen lock, the
Google backup is encrypted with it. The code is public and anyone can check what it does.

## 10. Changes to this policy

If what the app does with data changes, we will update this page and the date above. If the change is significant
(for example, if an iCloud backup or any feature that sends data were ever added, which would only be enabled with
your consent), we will also tell you inside the app.

## 11. Contact

turnly@mainshai.com
