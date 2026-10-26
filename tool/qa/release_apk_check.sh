#!/usr/bin/env bash
# Release APK resource check (docs/qa.md). R8 / shrinkResources removes every
# resource that only Dart references (the alarm notification small icon,
# `ic_stat_alarm`), which made every alarm fail with "no valid small icon" in
# release builds. android/app/src/main/res/raw/keep.xml lists what must survive
# (tools:keep); this script FAILS if any of it is missing from the release APK.
#
#   tool/qa/release_apk_check.sh [path/to/app-release.apk]
#
# Without an argument (or QA_RELEASE_APK) it builds one:
#   flutter build apk --release --dart-define=USE_DEMO_DATA=false --target-platform android-x64
# Called first thing by tool/qa/release_check.sh.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
APP="$ROOT/app"
KEEP="$APP/android/app/src/main/res/raw/keep.xml"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/AppData/Local/Android/Sdk}"

fail() { echo "[apk-check] FAIL: $*" >&2; exit 1; }

[ -f "$KEEP" ] || fail "no existe $KEEP"

# tools:keep="@drawable/a,@raw/b" -> "drawable/a" "raw/b"
KEEP_LIST="$(sed -n 's/.*tools:keep="\([^"]*\)".*/\1/p' "$KEEP" | tr ',' '\n' | sed 's/^ *@//; s/ *$//' | grep -v '^$')"
[ -n "$KEEP_LIST" ] || fail "keep.xml no lista ningún recurso (tools:keep)"

APK="${1:-${QA_RELEASE_APK:-}}"
if [ -z "$APK" ]; then
  echo "[apk-check] compilando el APK de release (varios minutos)"
  (
    cd "$APP" &&
      flutter build apk --release --dart-define=USE_DEMO_DATA=false --target-platform android-x64
  ) || fail "flutter build apk --release falló"
  APK="$APP/build/app/outputs/flutter-apk/app-release.apk"
fi
[ -s "$APK" ] || fail "no hay APK en $APK"

# aapt2 from the newest build-tools installed.
AAPT2=""
for dir in $(ls -d "$ANDROID_HOME"/build-tools/* 2>/dev/null | sort -V -r); do
  for name in aapt2 aapt2.exe; do
    if [ -x "$dir/$name" ]; then AAPT2="$dir/$name"; break 2; fi
  done
done
[ -n "$AAPT2" ] || fail "no encuentro aapt2 en $ANDROID_HOME/build-tools"

# The resource table lists "resource 0x7f08xxxx drawable/ic_stat_alarm" for each
# resource that is really in the APK (file names inside the APK are obfuscated).
TABLE="$("$AAPT2" dump resources "$APK" 2>&1 | tr -d '\r')" || fail "aapt2 dump resources falló sobre $APK"

missing=0
while IFS= read -r res; do
  if printf '%s\n' "$TABLE" | grep -Eq "^ *resource 0x[0-9a-f]+ ${res}\$"; then
    echo "[apk-check] ok: $res está en el APK"
  else
    echo "[apk-check] FALTA: $res no está en el APK (lo quitó el shrinker; revisa res/raw/keep.xml)" >&2
    missing=$((missing + 1))
  fi
done <<<"$KEEP_LIST"

[ "$missing" -eq 0 ] || fail "$missing recurso(s) de keep.xml faltan en $APK"
echo "[apk-check] PASSED"
