#!/usr/bin/env bash
# One MainActivity after a VIEW from another app (docs/qa.md, "Una sola
# actividad"). With launchMode="singleTop" and taskAffinity="" a .cuadrante
# opened from Files / WhatsApp while Cuadrante was in the background started a
# SECOND MainActivity (and a second Flutter engine). With "singleTask" the
# running instance gets the intent in onNewIntent.
#
#   QA_DEVICE=emulator-5580 tool/qa/single_activity_check.sh
#
# Needs the app installed (debug or release) on a device or emulator that YOU
# name with QA_DEVICE: like the rest of tool/qa it never picks "the only
# device" (other sessions have theirs) and never starts or stops an emulator.
#
# What it does: starts the app, sends it to the background (HOME), fires a VIEW
# intent for a content:// URI at it the way another app would (explicit
# component, because the shell is not a share sheet; the file does not need to
# exist: the app then shows its "no se pudo leer" preview, which is fine here),
# and counts the MainActivity instances in `dumpsys activity activities`.
# Exit 0 only if there is exactly one.
set -u

export ANDROID_HOME="${ANDROID_HOME:-$HOME/AppData/Local/Android/Sdk}"
ADB="$ANDROID_HOME/platform-tools/adb"
[ -x "$ADB" ] || ADB="$ANDROID_HOME/platform-tools/adb.exe"
PACKAGE="es.cuadrante.app"
COMPONENT="$PACKAGE/.MainActivity"

fail() { echo "[single-activity] FAIL: $*" >&2; exit 1; }

SERIAL="${QA_DEVICE:-}"
[ -n "$SERIAL" ] || fail "indica el dispositivo con QA_DEVICE=<serial> (nunca se elige uno solo)"
"$ADB" -s "$SERIAL" get-state >/dev/null 2>&1 || fail "$SERIAL no está conectado"
"$ADB" -s "$SERIAL" shell pm list packages 2>/dev/null | tr -d '\r' | grep -q "^package:$PACKAGE\$" ||
  fail "$PACKAGE no está instalado en $SERIAL"

adb_() { "$ADB" -s "$SERIAL" "$@"; }

count_activities() {
  adb_ shell dumpsys activity activities | tr -d '\r' |
    grep -o "ActivityRecord{[^}]*${PACKAGE}/\.MainActivity[^}]*}" |
    sed 's/ t[0-9-]*}$/}/' | sort -u | wc -l | tr -d ' '
}

echo "[single-activity] arrancando la app en $SERIAL"
adb_ shell am force-stop "$PACKAGE"
adb_ shell am start -n "$COMPONENT" >/dev/null || fail "no se pudo arrancar la app"
sleep 5
before="$(count_activities)"
echo "[single-activity] instancias con la app abierta: $before"

echo "[single-activity] a segundo plano (HOME) y VIEW de un .cuadrante"
adb_ shell input keyevent KEYCODE_HOME
sleep 2
adb_ shell am start -a android.intent.action.VIEW \
  -n "$COMPONENT" \
  -t application/octet-stream \
  -d "content://media/external/downloads/1/qa.cuadrante" >/dev/null ||
  fail "no se pudo enviar el VIEW"
sleep 4
after="$(count_activities)"
echo "[single-activity] instancias tras el VIEW: $after"

adb_ shell am force-stop "$PACKAGE"

[ "$before" = "1" ] || fail "se esperaba 1 MainActivity al arrancar y hay $before"
[ "$after" = "1" ] || fail "se esperaba 1 MainActivity tras el VIEW y hay $after (segunda actividad / segundo motor)"
echo "[single-activity] PASSED"
