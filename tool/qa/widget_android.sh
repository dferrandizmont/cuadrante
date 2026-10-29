#!/usr/bin/env bash
# W01-W05: the Android home-screen widgets on a real emulator (docs/qa.md,
# docs/widget-contrato.md "Android"). Run it from the repo root, in Git Bash:
#
#   tool/qa/widget_android.sh                       # boots Cuadrante_QA on port 5580
#   QA_DEVICE=emulator-5556 tool/qa/widget_android.sh   # a device that is up (never stopped)
#   QA_WIDGET_APK=ruta.apk tool/qa/widget_android.sh    # skips the debug build
#   QA_WIDGET_EXACT=0 ...                           # without the exact-alarm permission
#
# W01 Publish and add: the app (demo data) publishes the snapshot, both widgets
#     (2x2 and 4x2) are pinned from Ajustes > Anadir widget by accepting the
#     launcher's dialog, and they show today's date.
# W02 The day changes without the app: the app process is killed, battery saver
#     is on and the clock is set to 23:58:30; after midnight the widgets show
#     tomorrow, drawn by the midnight alarm. Then a time-zone change (to a zone
#     where it is still yesterday and back), and a reboot (the alarm is armed
#     again and the following midnight works too).
# W05 Month widget (4x4): pinned from Ajustes > Anadir widget > Grande; it shows
#     the title of today's month and a cell marked as today; at the midnight
#     that starts the next month in the snapshot, with the app killed and the
#     battery saver on, it shows the new month (title and today's cell = the 1st)
#     drawn by the midnight alarm; a tap on its header opens the app.
# W04 Reboot: BOOT_COMPLETED reaches the receiver, the midnight alarm is armed
#     again and the next midnight works too.
# W03 Honest message: the last published day ends (clock to 23:58:30 of the day
#     60, then past it): the widgets show the "open the app" text and no shift;
#     back in range they show the day again.
#
# The clock is set with `service call alarm 2` (the shell may do it on the
# google_apis_playstore image, which cannot be rooted: `cmd time_detector` is
# refused). The app is a debug build, so `run-as` can read the snapshot that
# is the oracle of the expected labels. Output in build/qa/widget/: widget.log
# (QA_* lines), shots/W0*.png, ui_*.xml, logcat. Exit code 0 only if W01-W05
# pass. Always at the end: restores the clock and battery saver, stops the
# emulator ONLY if this run started it, and builds without a Gradle daemon.
set -u
export MSYS_NO_PATHCONV=1   # device paths like /sdcard must not become Windows paths
QA_AVD="${QA_AVD:-Cuadrante_QA}"
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

WQ_OUT="$QA_OUT/widget"
WQ_LOG="$WQ_OUT/widget.log"
WQ_APK="${QA_WIDGET_APK:-$QA_APP/build/app/outputs/flutter-apk/app-debug.apk}"
WQ_EXACT="${QA_WIDGET_EXACT:-1}"
WQ_CLOCK_TOUCHED=0
WQ_CUR=""      # id of the scenario running
WQ_FAIL=""
WQ_FAILED_ANY=0
WQ_PREFS="shared_prefs/HomeWidgetPreferences.xml"
WQ_TAG="CuadranteWidget"

mkdir -p "$WQ_OUT/shots"
[ -f "$QA_ROOT/build/.gitignore" ] || echo '*' >"$QA_ROOT/build/.gitignore"
rm -f "$WQ_OUT"/shots/W0*.png "$WQ_OUT"/ui_*.xml
: >"$WQ_LOG"

w_note() { echo "QA_NOTE|$WQ_CUR|$*" >>"$WQ_LOG"; qa_log "$WQ_CUR: $*"; }
w_fail() { WQ_FAIL="$*"; qa_log "$WQ_CUR FAILED: $*"; return 1; }

# ---- Device helpers ----------------------------------------------------------

w_shot() { qa_adb exec-out screencap -p >"$WQ_OUT/shots/${WQ_CUR}_$1.png" 2>/dev/null; }

# uiautomator fails now and then (e.g. "could not get idle state" while Flutter or
# the launcher animates) and leaves nothing: retry until a hierarchy comes out.
w_ui_dump() {
  local i
  for i in 1 2 3 4 5; do
    qa_adb shell rm -f //sdcard/w_ui.xml >/dev/null 2>&1
    qa_adb shell uiautomator dump //sdcard/w_ui.xml >"$WQ_OUT/uia_err.txt" 2>&1
    qa_adb exec-out cat //sdcard/w_ui.xml >"$WQ_OUT/ui_$1.xml" 2>/dev/null
    grep -q "<hierarchy" "$WQ_OUT/ui_$1.xml" 2>/dev/null && return 0
    cp "$WQ_OUT/uia_err.txt" "$WQ_OUT/uia_err_last.txt" 2>/dev/null
    sleep 2
  done
  return 0
}

# Taps the first element whose text or content-desc matches the regex $1.
w_tap() {
  local b
  w_ui_dump tap
  b="$(sed 's/>/>\n/g' "$WQ_OUT/ui_tap.xml" | grep -E "(text|content-desc)=\"[^\"]*($1)" | head -n1 \
    | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p')"
  [ -n "$b" ] || return 1
  set -- $b
  qa_adb shell input tap $((($1 + $3) / 2)) $((($2 + $4) / 2))
}

# Waits up to $2 s (default 20) for $1 to be tappable, then taps it.
w_tap_wait() {
  local i
  for i in $(seq 1 "${2:-10}"); do
    w_tap "$1" && return 0
    sleep 2
  done
  return 1
}

# True when the current screen has text or content-desc matching $1.
w_screen_has() {
  w_ui_dump now
  sed 's/>/>\n/g' "$WQ_OUT/ui_now.xml" | grep -qE "(text|content-desc)=\"[^\"]*($1)"
}

w_home() { qa_adb shell input keyevent KEYCODE_WAKEUP; qa_adb shell input keyevent 82; qa_adb shell input keyevent KEYCODE_HOME; sleep 2; }

w_snapshot() {
  qa_adb shell "run-as $QA_PACKAGE cat $WQ_PREFS" 2>/dev/null | tr -d '\r' | sed 's/&quot;/"/g'
}

# dateLabel ("mar 20") of snapshot day $1 (yyyy-mm-dd), read from the snapshot the widgets read.
w_label() {
  w_snapshot | sed -n "s/.*\"date\":\"$1\",\"weekday\":[0-9]*,\"weekdayShort\":\"[^\"]*\",\"dayOfMonth\":[0-9]*,\"dateLabel\":\"\([^\"]*\)\".*/\1/p" | head -n1
}

w_snapshot_field() { w_snapshot | sed -n "s/.*\"$1\":\"\([^\"]*\)\".*/\1/p" | head -n1; }

# ---- Clock -------------------------------------------------------------------

w_device_date() { qa_adb shell date +%Y-%m-%d | tr -d '\r'; }

# UTC offset in seconds of the device's zone at epoch $1, by the zone's own rules (it can differ from today's).
w_offset_at() {
  local z sign
  z="$(qa_adb shell date -d "@$1" +%z | tr -d '\r')"          # +0200
  sign=1; [ "${z:0:1}" = "-" ] && sign=-1
  echo $((sign * (10#${z:1:2} * 3600 + 10#${z:3:2} * 60)))
}

# Epoch seconds of "yyyy-mm-dd HH:MM:SS" in the device's current zone, with the offset of THAT date
# (a winter date asked for on a summer day is an hour apart).
w_local_epoch() {
  local utc guess
  utc="$(date -u -d "$1" +%s)"
  guess=$((utc - $(w_offset_at "$utc")))
  echo $((utc - $(w_offset_at "$guess")))
}

w_set_clock() {   # epoch seconds
  WQ_CLOCK_TOUCHED=1
  qa_adb shell service call alarm 2 i64 $(($1 * 1000)) | grep -q "00000001"
}

w_set_zone() { qa_adb shell service call alarm 3 s16 "$1" >/dev/null; sleep 4; }

w_add_days() { date -u -d "$1 + $2 day" +%F; }

# Waits until the widgets' midnight alarm has fired after $1 (a "MM-DD HH:MM" prefix of the logcat line).
w_wait_midnight() {
  local i
  for i in $(seq 1 90); do
    qa_adb logcat -d -s "$WQ_TAG:V" | grep -q "$1.*MIDNIGHT" && return 0
    sleep 2
  done
  return 1
}

w_alarm_lateness() {   # seconds after 00:00:00 of the MIDNIGHT line that matches $1
  local t
  t="$(qa_adb logcat -d -s "$WQ_TAG:V" | tr -d '\r' | grep "$1.*MIDNIGHT" | head -n1 | sed -n 's/^[0-9-]* \([0-9]*\):\([0-9]*\):\([0-9]*\)\..*/\1 \2 \3/p')"
  set -- $t
  echo $((10#$1 * 3600 + 10#$2 * 60 + 10#$3))
}

w_restore() {
  [ "$WQ_CLOCK_TOUCHED" = 1 ] && [ -n "$QA_SERIAL" ] && qa_online "$QA_SERIAL" && {
    # Back to the host's real time, battery saver off.
    qa_adb shell service call alarm 2 i64 $(($(date -u +%s) * 1000)) >/dev/null 2>&1
    qa_adb shell service call alarm 3 s16 "${WQ_ZONE:-Europe/Madrid}" >/dev/null 2>&1
    qa_adb shell settings put global low_power 0 >/dev/null 2>&1
  }
  true
}

w_finish() {
  local rc=$?
  trap - EXIT INT TERM
  w_restore
  if [ -n "$QA_SERIAL" ] && qa_online "$QA_SERIAL"; then
    qa_adb logcat -d -v time "$WQ_TAG:V" AndroidRuntime:E '*:S' >"$WQ_OUT/logcat.txt" 2>&1 || true
  fi
  [ "$rc" -ne 0 ] && [ "$WQ_FAILED_ANY" = 0 ] && echo "QA_RESULT|${WQ_CUR:-setup}|FAIL|0|el script terminó con código $rc" >>"$WQ_LOG"
  qa_log "log: $WQ_LOG"
  if [ "$WQ_FAILED_ANY" = 0 ] && [ "$rc" -eq 0 ]; then qa_log "RESULT: PASSED"; else qa_log "RESULT: FAILED"; rc=1; fi
  qa_cleanup_with_rc "$rc"
}

# qa_cleanup reads $? itself; run it with the code we want.
qa_cleanup_with_rc() { (exit "$1"); qa_cleanup; }

scenario() {   # scenario <id> <title> <function>
  WQ_CUR="$1"; WQ_FAIL=""
  local start; start="$(date +%s)"
  echo "QA_START|$1|$2" >>"$WQ_LOG"
  qa_log "== $1 $2"
  if "$3"; then
    echo "QA_RESULT|$1|PASS|$((($(date +%s) - start) * 1000))|" >>"$WQ_LOG"
  else
    WQ_FAILED_ANY=1
    w_shot FALLO
    echo "QA_RESULT|$1|FAIL|$((($(date +%s) - start) * 1000))|${WQ_FAIL:-sin detalle}" >>"$WQ_LOG"
  fi
}

# ---- Setup -------------------------------------------------------------------

w_prepare_avd() {
  [ -n "${QA_DEVICE:-}" ] && return 0
  "$EMULATOR" -list-avds | tr -d '\r' | grep -qx "$QA_AVD" && return 0
  local avdm="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager.bat"
  [ -x "$avdm" ] || avdm="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager"
  qa_log "creating the AVD $QA_AVD from the installed google_apis_playstore image"
  echo no | "$avdm" create avd -n "$QA_AVD" -k "system-images;android-36;google_apis_playstore;x86_64" -d pixel_9 >/dev/null 2>&1
  "$EMULATOR" -list-avds | tr -d '\r' | grep -qx "$QA_AVD"
}

w_build() {
  [ -f "$WQ_APK" ] && [ -n "${QA_WIDGET_APK:-}" ] && return 0
  qa_log "flutter build apk --debug"
  (cd "$QA_APP" && flutter build apk --debug >"$WQ_OUT/build.log" 2>&1) || { qa_log "build failed (see $WQ_OUT/build.log)"; return 1; }
}

w_install() {
  qa_adb uninstall "$QA_PACKAGE" >/dev/null 2>&1
  local apk="$WQ_APK"
  command -v cygpath >/dev/null 2>&1 && apk="$(cygpath -w "$WQ_APK")"   # adb.exe wants a Windows path
  qa_adb install -r "$apk" >/dev/null || return 1
  qa_adb shell pm grant "$QA_PACKAGE" android.permission.POST_NOTIFICATIONS >/dev/null 2>&1
  # The steps look for Spanish labels: fix only this app's language (Android 13+),
  # whatever the emulator's, never the device's global language.
  qa_adb shell cmd locale set-app-locales "$QA_PACKAGE" --user current --locales es >/dev/null 2>&1
  if [ "$WQ_EXACT" = 1 ]; then
    qa_adb shell appops set "$QA_PACKAGE" SCHEDULE_EXACT_ALARM allow >/dev/null 2>&1
  fi
  WQ_ZONE="$(qa_adb shell getprop persist.sys.timezone | tr -d '\r')"
  qa_adb shell settings put global low_power 0 >/dev/null 2>&1
  qa_adb logcat -c
}

# ---- W01 ---------------------------------------------------------------------

w_pin() {   # w_pin <button regex of the sheet>
  qa_adb shell am kill "$QA_PACKAGE"
  qa_adb shell am start -n "$QA_PACKAGE/.MainActivity" >/dev/null
  sleep 3
  w_tap_wait "Abrir ajustes" 15 || { w_fail "no está el botón de Ajustes"; return 1; }
  sleep 2
  w_tap "A.{1,2}adir widget" || { qa_adb shell input swipe 540 1800 540 700 300; sleep 1; w_tap "A.{1,2}adir widget"; } \
    || { w_fail "no está la fila «Añadir widget»"; return 1; }
  sleep 2
  w_tap_wait "$1" 5 || { w_fail "la hoja no ofrece «$1» (¿el launcher no permite fijar?)"; return 1; }
  w_tap_wait "Add to home screen|A.{1,2}adir a la pantalla|A.{1,2}adir autom" 10 || { w_fail "el launcher no mostró su diálogo de fijar widget"; return 1; }
  sleep 3
}

w01() {
  qa_adb shell am start -n "$QA_PACKAGE/.MainActivity" >/dev/null
  local i
  # A first launch of a debug build (kernel extraction, JIT) can take more than
  # a minute on the emulator before the first publish: wait up to 3 minutes and
  # bring the app to the front again halfway.
  for i in $(seq 1 90); do
    [ -n "$(w_snapshot)" ] && break
    [ "$i" = 45 ] && qa_adb shell am start -n "$QA_PACKAGE/.MainActivity" >/dev/null
    sleep 2
  done
  [ -n "$(w_snapshot)" ] || { w_fail "la app no publicó la instantánea en HomeWidgetPreferences"; return 1; }
  local today first
  today="$(w_device_date)"; first="$(w_snapshot_field firstDate)"
  [ "$first" = "$today" ] || { w_fail "firstDate $first no es hoy $today"; return 1; }
  w_note "instantánea publicada: firstDate=$first, $(w_snapshot | wc -c) bytes"

  w_pin "Peque.{1,2}o" || return 1
  w_home
  w_pin "Mediano" || return 1
  w_home
  qa_adb shell am kill "$QA_PACKAGE"; sleep 2
  w_home
  local label; label="$(w_label "$today")"
  [ -n "$label" ] || { w_fail "no se pudo leer la etiqueta de hoy de la instantánea"; return 1; }
  w_screen_has "$label" || { w_fail "los widgets no muestran «$label»"; return 1; }
  w_shot widgets
  w_note "ambos widgets en la pantalla de inicio, hoy = «$label»"
}

# ---- W02 ---------------------------------------------------------------------

w02() {
  local d0 d1 l0 l1 midnight_prefix t
  d0="$(w_device_date)"; d1="$(w_add_days "$d0" 1)"
  l0="$(w_label "$d0")"; l1="$(w_label "$d1")"
  [ -n "$l0" ] && [ -n "$l1" ] || { w_fail "faltan etiquetas en la instantánea"; return 1; }
  [ "$l0" != "$l1" ] || { w_fail "etiquetas iguales"; return 1; }

  qa_adb shell am kill "$QA_PACKAGE"
  qa_adb shell settings put global low_power 1
  w_home
  qa_adb logcat -c
  w_set_clock "$(w_local_epoch "$d0 23:58:30")" || { w_fail "no se pudo cambiar la hora (service call alarm 2)"; return 1; }
  sleep 3
  w_screen_has "$l0" || { w_fail "antes de medianoche debería verse «$l0»"; return 1; }
  w_shot before_midnight
  midnight_prefix="$(date -u -d "$d1" +%m-%d) 00:0"
  w_wait_midnight "$midnight_prefix" || { w_fail "la alarma de medianoche no llegó"; return 1; }
  sleep 3
  t="$(w_alarm_lateness "$midnight_prefix")"
  w_note "alarma de medianoche recibida a las 00:00:$(printf %02d "$t") (batería: ahorro activado, app cerrada)"
  if [ "$WQ_EXACT" = 1 ] && [ "$t" -gt 10 ]; then w_fail "con alarma exacta llegó $t s tarde"; return 1; fi
  w_screen_has "$l1" || { w_fail "tras medianoche debería verse «$l1»"; return 1; }
  w_screen_has "$l0" && { w_fail "sigue viéndose «$l0» (ayer)"; return 1; }
  w_shot after_midnight
  qa_adb shell settings put global low_power 0
  w_note "tras la medianoche los widgets muestran «$l1» sin abrir la app"

  # Time-zone change: UTC-10 where it is still the evening of d0; then back.
  local back_date
  w_set_zone Pacific/Honolulu
  back_date="$(qa_adb shell date +%Y-%m-%d | tr -d '\r')"
  w_screen_has "$(w_label "$back_date")" || { w_fail "al cambiar de zona (hoy allí: $back_date) no se redibujó"; return 1; }
  w_shot zone_honolulu
  w_note "zona Pacific/Honolulu: el widget sigue el reloj local ($back_date)"
  w_set_zone "$WQ_ZONE"
  w_screen_has "$l1" || { w_fail "al volver a $WQ_ZONE debería verse «$l1»"; return 1; }
  w_note "de vuelta a $WQ_ZONE: «$l1»"
}

# ---- W03 ---------------------------------------------------------------------

w03() {
  local first last d after stale_body
  first="$(w_snapshot_field firstDate)"; last="$(w_snapshot_field lastDate)"
  stale_body="$(w_snapshot_field staleBody)"
  [ -n "$first" ] && [ -n "$last" ] && [ -n "$stale_body" ] || { w_fail "instantánea ilegible"; return 1; }
  after="$(w_add_days "$last" 1)"
  qa_adb shell am kill "$QA_PACKAGE"; w_home

  # The last day, then its midnight.
  qa_adb logcat -c
  w_set_clock "$(w_local_epoch "$last 23:58:30")" || { w_fail "no se pudo cambiar la hora"; return 1; }
  sleep 3
  w_screen_has "$(w_label "$last")" || { w_fail "el último día ($last) debería verse"; return 1; }
  w_shot last_day
  w_wait_midnight "$(date -u -d "$after" +%m-%d) 00:0" || { w_fail "la alarma de medianoche no llegó"; return 1; }
  sleep 3
  w_screen_has "$stale_body" || { w_fail "pasado el día 60 debería verse «$stale_body»"; return 1; }
  w_screen_has "$(w_label "$last")" && { w_fail "sigue viéndose el último día"; return 1; }
  w_shot stale_after_midnight
  w_note "pasada la medianoche del día 60: «$stale_body», ningún turno"

  # Far past the end, and before the start (clock gone back).
  w_set_clock "$(w_local_epoch "$(w_add_days "$last" 40) 12:00:00")" || return 1
  sleep 4
  w_screen_has "$stale_body" || { w_fail "40 días después debería verse el aviso"; return 1; }
  w_set_clock "$(w_local_epoch "$(w_add_days "$first" -3) 12:00:00")" || return 1
  sleep 4
  w_screen_has "$stale_body" || { w_fail "con el reloj antes del primer día debería verse el aviso"; return 1; }
  w_shot stale_before_first
  w_note "reloj fuera del rango (antes y después): siempre el aviso, nunca un día equivocado"

  # Back in range: the day returns by itself.
  d="$(w_add_days "$first" 5)"
  w_set_clock "$(w_local_epoch "$d 12:00:00")" || return 1
  sleep 4
  w_screen_has "$(w_label "$d")" || { w_fail "dentro del rango debería verse «$(w_label "$d")»"; return 1; }
  w_shot back_in_range
  w_note "de vuelta dentro del rango: «$(w_label "$d")»"
}

# ---- W05 ---------------------------------------------------------------------

# Title ("Noviembre 2026") of the month grid $1 (yyyy-mm) in the snapshot the widgets read.
w_month_title() {
  w_snapshot | sed -n "s/.*\"key\":\"$1\",\"title\":\"\([^\"]*\)\".*/\1/p" | head -n1
}

# Keys (yyyy-mm) of the month grids of the snapshot, in order.
w_month_keys() { w_snapshot | grep -o '"key":"[0-9]*-[0-9]*"' | sed 's/"key":"\(.*\)"/\1/'; }

# True when a cell of the month widget says "<day> ... hoy" (its content description: day number,
# codes and "hoy" for today's cell).
w_today_cell_is() {
  w_ui_dump now
  # Today's cell reads "hoy. jueves, 29 de octubre de 2026. …" (older builds: "29 … hoy").
  # The day number alone is not enough: the grid also shows the days of the
  # neighbouring months (a «29 de septiembre» before 1 October).
  sed 's/>/>\n/g' "$WQ_OUT/ui_now.xml" |
    grep -qE "content-desc=\"(hoy\. [^,\"]+, $1 de |$1( [^\" ]+)* hoy\")"
}

w05() {
  # Real time again (W03 left the clock inside the range, W02 changed zone), so the app republishes from today.
  w_set_clock "$(date -u +%s)" || { w_fail "no se pudo restaurar la hora"; return 1; }
  qa_adb shell settings put global low_power 0
  local keys m1 m2 t1 t2 day
  w_pin "Grande" || return 1
  w_home
  qa_adb shell am kill "$QA_PACKAGE"; sleep 2
  w_home
  keys="$(w_month_keys)"
  m1="$(echo "$keys" | sed -n 1p)"; m2="$(echo "$keys" | sed -n 2p)"
  [ -n "$m1" ] && [ -n "$m2" ] || { w_fail "la instantánea no trae al menos dos cuadrículas de mes"; return 1; }
  t1="$(w_month_title "$m1")"; t2="$(w_month_title "$m2")"
  [ -n "$t1" ] && [ -n "$t2" ] || { w_fail "no se pudieron leer los títulos de mes de la instantánea"; return 1; }
  today="$(w_device_date)"
  day="$(echo "$today" | sed 's/^[0-9]*-[0-9]*-0*//')"
  w_screen_has "$t1" || { w_fail "el widget del mes no muestra «$t1»"; return 1; }
  w_today_cell_is "$day" || { w_fail "la celda de hoy ($day) no está marcada «hoy»"; return 1; }
  w_shot month_today
  w_note "widget del mes: «$t1», hoy = celda $day"

  # The midnight that starts the next month of the snapshot: the new month by itself.
  local eve; eve="$(w_add_days "$m2-01" -1)"
  qa_adb shell am kill "$QA_PACKAGE"
  qa_adb shell settings put global low_power 1
  w_home
  qa_adb logcat -c
  w_set_clock "$(w_local_epoch "$eve 23:58:30")" || { w_fail "no se pudo cambiar la hora"; return 1; }
  sleep 3
  w_screen_has "$t1" || { w_fail "la víspera ($eve) debería verse «$t1»"; return 1; }
  w_shot month_eve
  w_wait_midnight "$(date -u -d "$m2-01" +%m-%d) 00:0" || { w_fail "la alarma de medianoche no llegó"; return 1; }
  sleep 3
  w_screen_has "$t2" || { w_fail "tras medianoche debería verse «$t2»"; return 1; }
  w_screen_has "$t1" && { w_fail "sigue viéndose «$t1» (el mes anterior)"; return 1; }
  w_today_cell_is 1 || { w_fail "tras medianoche la celda del día 1 debería estar marcada «hoy»"; return 1; }
  w_shot month_new
  qa_adb shell settings put global low_power 0
  w_note "tras la medianoche del $m2-01 el widget pasó de «$t1» a «$t2» sin abrir la app"

  # A tap on the header opens the app.
  w_tap "$t2" || { w_fail "no se pudo tocar la cabecera «$t2»"; return 1; }
  sleep 4
  qa_adb shell dumpsys window | tr -d '\r' | grep -i "mCurrentFocus" | grep -q "$QA_PACKAGE" \
    || { w_fail "tocar la cabecera no abrió la app"; return 1; }
  w_shot header_tap
  w_note "tocar la cabecera abre la app"
}

# ---- W04 ---------------------------------------------------------------------

# Last on purpose: the launcher of this image forgets the placed widgets after a
# reboot, so nothing on screen can be checked afterwards; the receiver, the
# alarm and the next midnight are checked from the log and `dumpsys alarm`.
w04() {
  qa_adb reboot
  sleep 20
  local waited=0
  until [ "$(qa_adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
    sleep 3; waited=$((waited + 3))
    [ "$waited" -lt 300 ] || { w_fail "el emulador no arrancó tras reiniciar"; return 1; }
  done
  sleep 20
  qa_adb logcat -d -s "$WQ_TAG:V" | grep -q "BOOT_COMPLETED" || { w_fail "el receptor no recibió BOOT_COMPLETED"; return 1; }
  qa_adb shell dumpsys alarm | grep -q "widget.action.MIDNIGHT" || { w_fail "tras reiniciar no hay alarma de medianoche"; return 1; }
  w_note "reinicio: BOOT_COMPLETED recibido y alarma de medianoche armada otra vez"
  local d2; d2="$(w_device_date)"
  qa_adb logcat -c
  w_set_clock "$(w_local_epoch "$d2 23:58:30")" || { w_fail "no se pudo cambiar la hora tras reiniciar"; return 1; }
  w_wait_midnight "$(date -u -d "$(w_add_days "$d2" 1)" +%m-%d) 00:0" || { w_fail "tras reiniciar, la alarma de medianoche no llegó"; return 1; }
  w_note "tras reiniciar, la siguiente medianoche también dispara el refresco"
}

# ---- Main --------------------------------------------------------------------

trap w_finish EXIT INT TERM
WQ_CUR="setup"
w_prepare_avd || { qa_log "no AVD $QA_AVD and it could not be created"; exit 2; }
w_build || exit 2
qa_device_select || exit 2
w_install || { qa_log "install failed"; exit 2; }

scenario W01 "Publicar y añadir los widgets (2x2 y 4x2)" w01
if [ "$WQ_FAILED_ANY" = 0 ]; then
  scenario W02 "El día cambia sin abrir la app (medianoche, zona, reinicio)" w02
  scenario W03 "Aviso honesto fuera de los 60 días" w03
  scenario W05 "Widget del mes (4x4): cambia de mes solo a medianoche" w05
  scenario W04 "Reinicio: la alarma vuelve a armarse" w04
else
  qa_log "W01 failed: W02, W03, W05 and W04 need the widgets and were skipped"
fi
exit "$WQ_FAILED_ANY"
