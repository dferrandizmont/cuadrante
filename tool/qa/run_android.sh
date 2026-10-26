#!/usr/bin/env bash
# QA battery on an Android emulator (docs/qa.md). Run it from the repo root, in
# Git Bash on Windows:
#
#   tool/qa/run_android.sh                  # the whole battery (before EVERY release)
#   QA_ONLY=Q02,Q03 tool/qa/run_android.sh  # some scenarios
#   QA_SKIP=Q13 tool/qa/run_android.sh      # all but some
#   QA_AVD=<avd> tool/qa/run_android.sh              # another AVD (default Cuadrante_QA)
#   QA_DEVICE=emulator-5556 tool/qa/run_android.sh   # a device that is already up (never stopped)
#   QA_WINDOW=1 tool/qa/run_android.sh      # show the emulator window (default: headless)
#   QA_UPGRADE=1 tool/qa/run_android.sh     # after the battery, U02 (real upgrade from 0.2.0, ~10 min,
#                                           # needs network): see tool/qa/upgrade_android.sh. The release
#                                           # check is tool/qa/release_check.sh (this, with QA_UPGRADE=1).
#
# Output (git-ignored): build/qa/report.md, integration.log, shots/<id>[_<name>].png
# Exit code: 0 only if every scenario passed (the battery AND, with QA_UPGRADE=1, U02). Check it
# without an emulator with tool/qa/selftest.sh.
# Always at the end: stops the emulator ONLY if this run started it, and runs
# builds without a Gradle daemon.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
trap qa_cleanup EXIT
trap 'exit 130' INT TERM

START="$(date +%s)"
# Clean the output but keep the downloaded APK of the old release (U02).
if [ -d "$QA_OUT" ]; then
  find "$QA_OUT" -mindepth 1 -maxdepth 1 ! -name 'cuadrante-[0-9]*.apk' -exec rm -rf {} +
fi
mkdir -p "$QA_OUT/shots"
# build/ is not in the repo .gitignore: make the output folder ignore itself.
[ -f "$QA_ROOT/build/.gitignore" ] || echo '*' >"$QA_ROOT/build/.gitignore"

qa_device_select || exit 2
DEVICE_MODEL="$(qa_adb shell getprop ro.product.model | tr -d '\r')"
DEVICE_API="$(qa_adb shell getprop ro.build.version.sdk | tr -d '\r')"
qa_log "device $QA_SERIAL: $DEVICE_MODEL, API $DEVICE_API"

LOG="$QA_OUT/integration.log"
: >"$LOG"
qa_grant_notifications_start
qa_shots_start "$LOG"

DEFINES=()
[ -n "${QA_ONLY:-}" ] && DEFINES+=("--dart-define=QA_ONLY=$QA_ONLY")
[ -n "${QA_SKIP:-}" ] && DEFINES+=("--dart-define=QA_SKIP=$QA_SKIP")

qa_adb logcat -c >/dev/null 2>&1 || true
qa_log "running integration_test/app_test.dart (the first build takes several minutes)"
(
  cd "$QA_APP" &&
    timeout "${QA_TIMEOUT:-2400}" flutter test integration_test/app_test.dart -d "$QA_SERIAL" \
      "${DEFINES[@]}" ${QA_FLUTTER_ARGS:-}
) >"$LOG" 2>&1
FLUTTER_RC=$?
sleep 3
qa_shots_sweep
# Warnings and errors of the device plus the app's own output, for diagnosing crashes.
qa_adb logcat -d -v time '*:W' flutter:V DartVM:V AndroidRuntime:V >"$QA_OUT/logcat.txt" 2>&1 || true

END="$(date +%s)"
DURATION=$((END - START))
dart "$QA_ROOT/tool/qa/report.dart" \
  --log "$LOG" --out "$QA_OUT" --flutter-exit "$FLUTTER_RC" --duration "$DURATION" \
  --device "$QA_SERIAL ($DEVICE_MODEL, API $DEVICE_API)" --avd "$QA_AVD" \
  --started-emulator "$QA_EMULATOR_STARTED" --only "${QA_ONLY:-}" --skip "${QA_SKIP:-}"
REPORT_RC=$?

qa_log "done in ${DURATION}s. Report: $QA_OUT/report.md (flutter exit $FLUTTER_RC)"
UPGRADE_RC=0
if [ "${QA_UPGRADE:-0}" = 1 ]; then
  # U02 on the emulator this run already has (QA_DEVICE: it is never stopped by the
  # child; this script's trap stops it if it started it). Adds its row to report.md.
  qa_log "QA_UPGRADE=1: running U02 (tool/qa/upgrade_android.sh)"
  QA_DEVICE="$QA_SERIAL" "$QA_ROOT/tool/qa/upgrade_android.sh"
  UPGRADE_RC=$?
fi
# The verdict is explicit and printed, so a log (or a person reading it) can see why the run
# is red: ANY failing part fails the run (battery, report, U02), whatever order they ran in.
# tool/qa/selftest.sh checks this logic with fakes.
if [ "$FLUTTER_RC" -ne 0 ] || [ "$REPORT_RC" -ne 0 ] || [ "$UPGRADE_RC" -ne 0 ]; then
  qa_log "RESULT: FAILED (battery: flutter exit $FLUTTER_RC, report exit $REPORT_RC; U02 exit $UPGRADE_RC)"
  exit 1
fi
qa_log "RESULT: PASSED (battery: flutter exit $FLUTTER_RC, report exit $REPORT_RC; U02 exit $UPGRADE_RC)"
exit 0
