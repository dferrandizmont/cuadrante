# Security notices

If you find a vulnerability, write to **dev@mainshai.com**.

Include the affected version, the steps to reproduce the problem and its
possible impact. Send the details by email before opening a public issue, so
the problem can be reviewed and a fix prepared.

## Do not attach real data

A real `.cuadrante` backup, a screenshot of the calendar or the widget, or a
real `.ics`, CSV or `.Shifter` file carries your shifts, your notes and your
absences, and among them there may be sick leave or other health data. None of
that is needed to fix a bug:

- Reproduce the problem with made-up data (the app starts with demo data in
  development) and attach that backup, not yours.
- If you must send a real file, first remove the notes, the absences and the
  calendar and shift-type names that identify you. A `.cuadrante` backup is
  gzip-compressed JSON and can be edited.
- In screenshots, cover dates, notes and shift codes that are not test data.
- Never send keys, keystores or `.env` files.

The same applies to public issues and pull requests.

Spanish version (authoritative): [SECURITY.md](SECURITY.md).
