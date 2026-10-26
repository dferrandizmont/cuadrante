#!/usr/bin/env bash
# Self-check of the exit status of the QA scripts (docs/qa.md). Needs no emulator, no Flutter and no network:
#
#   tool/qa/selftest.sh
#
# It copies tool/qa into a temporary tree, puts a fake adb / flutter / U02 script in it and runs the REAL
# run_android.sh and release_check.sh for every combination of "battery passes/fails" x "U02 passes/fails".
# The exit status must be 0 only when both pass. This is what regressed once: a failing battery followed by a
# U02 run ended with exit 0. Run it after touching anything in tool/qa/*.sh.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SB="$(mktemp -d)"
trap 'rm -rf "${SB:?}"' EXIT

mkdir -p "$SB/tool" "$SB/app/android" "$SB/sdk/platform-tools" "$SB/bin"
cp -r "$HERE" "$SB/tool/qa"
rm -f "$SB/tool/qa/selftest.sh"

# Fake adb: one device, "fake-1", always online; everything else succeeds silently.
cat >"$SB/sdk/platform-tools/adb" <<'EOF'
#!/usr/bin/env bash
args=("$@")
[ "${1:-}" = "-s" ] && args=("${@:3}")
case "${args[0]:-}" in
  devices) printf 'List of devices attached\nfake-1\tdevice\n' ;;
  shell) [ "${args[1]:-}" = "getprop" ] && echo fake ;;
esac
exit 0
EOF
# Fake flutter: prints the scenario lines of the real runner and exits with FAKE_BATTERY_RC
# (FAKE_FAIL_LINE=1: a FAIL line but exit 0; FAKE_NO_SCENARIOS=1: no lines at all).
cat >"$SB/bin/flutter" <<'EOF'
#!/usr/bin/env bash
[ "${FAKE_NO_SCENARIOS:-0}" = 1 ] && exit 0
echo "QA_START|Q01|Uno"
if [ "${FAKE_BATTERY_RC:-0}" != 0 ] || [ "${FAKE_FAIL_LINE:-0}" = 1 ]; then echo "QA_RESULT|Q01|FAIL|10|boom"; else echo "QA_RESULT|Q01|PASS|10|"; fi
exit "${FAKE_BATTERY_RC:-0}"
EOF
# Fake U02.
cat >"$SB/tool/qa/upgrade_android.sh" <<'EOF'
#!/usr/bin/env bash
exit "${FAKE_U02_RC:-0}"
EOF
# Fake release APK check.
cat >"$SB/tool/qa/release_apk_check.sh" <<'EOF'
#!/usr/bin/env bash
exit "${FAKE_APK_RC:-0}"
EOF
chmod +x "$SB/sdk/platform-tools/adb" "$SB/bin/flutter" "$SB/tool/qa/"*.sh

fails=0
# check <expected-nonzero 0|1> <script> <battery rc> <u02 rc> [extra env...]
check() {
  local want="$1" script="$2" brc="$3" urc="$4"
  shift 4
  env PATH="$SB/bin:$PATH" ANDROID_HOME="$SB/sdk" QA_DEVICE=fake-1 QA_OUT="$SB/out" \
    FAKE_BATTERY_RC="$brc" FAKE_U02_RC="$urc" "$@" \
    timeout 90 bash ${SELFTEST_TRACE:+-x} "$SB/tool/qa/$script" >"$SB/last.log" 2>&1
  local rc=$?
  local ok=0
  if [ "$want" = 0 ] && [ "$rc" -eq 0 ]; then ok=1; fi
  if [ "$want" = 1 ] && [ "$rc" -ne 0 ]; then ok=1; fi
  if [ "$ok" = 1 ]; then
    echo "ok   $script battery=$brc u02=$urc $* -> exit $rc"
  else
    echo "FAIL $script battery=$brc u02=$urc $* -> exit $rc (wanted $([ "$want" = 0 ] && echo 0 || echo non-zero))"
    sed 's/^/     | /' "$SB/last.log" | tail -n "${SELFTEST_TAIL:-15}"
    fails=$((fails + 1))
  fi
}

# run_android.sh without U02: only the battery counts.
check 0 run_android.sh 0 0
check 1 run_android.sh 1 0
# With U02 (what release_check.sh does): any failure fails the run.
check 0 run_android.sh 0 0 QA_UPGRADE=1
check 1 run_android.sh 1 0 QA_UPGRADE=1
check 1 run_android.sh 0 1 QA_UPGRADE=1
check 1 run_android.sh 1 1 QA_UPGRADE=1
check 0 release_check.sh 0 0
check 1 release_check.sh 1 0
check 1 release_check.sh 0 1
check 1 release_check.sh 1 1
# flutter test exits 0 but a scenario reported FAIL (the report must still turn the run red).
check 1 release_check.sh 0 0 FAKE_FAIL_LINE=1
# flutter test exits 0 but no scenario ran (e.g. the app never started): not green.
check 1 release_check.sh 0 0 FAKE_NO_SCENARIOS=1
# The release APK check (a keep-listed resource missing) fails the release check.
check 1 release_check.sh 0 0 FAKE_APK_RC=1

# The REAL release_apk_check.sh against a fake aapt2: present -> ok, missing -> fail.
mkdir -p "$SB/real/tool/qa" "$SB/real/app/android/app/src/main/res/raw" "$SB/real/sdk/build-tools/1.0.0"
cp "$HERE/release_apk_check.sh" "$SB/real/tool/qa/"
cp "$HERE/../../app/android/app/src/main/res/raw/keep.xml" "$SB/real/app/android/app/src/main/res/raw/"
echo apk >"$SB/real/fake.apk"
cat >"$SB/real/sdk/build-tools/1.0.0/aapt2" <<'EOF'
#!/usr/bin/env bash
echo "    resource 0x7f080001 drawable/widget_bg"
[ "${FAKE_HAS_ICON:-1}" = 1 ] && echo "    resource 0x7f080002 drawable/ic_stat_alarm"
exit 0
EOF
chmod +x "$SB/real/sdk/build-tools/1.0.0/aapt2" "$SB/real/tool/qa/release_apk_check.sh"
apk_check() {
  local want="$1"; shift
  env ANDROID_HOME="$SB/real/sdk" "$@" "$SB/real/tool/qa/release_apk_check.sh" "$SB/real/fake.apk" >"$SB/last.log" 2>&1
  local rc=$?
  if { [ "$want" = 0 ] && [ "$rc" -eq 0 ]; } || { [ "$want" = 1 ] && [ "$rc" -ne 0 ]; }; then
    echo "ok   release_apk_check.sh $* -> exit $rc"
  else
    echo "FAIL release_apk_check.sh $* -> exit $rc"; sed 's/^/     | /' "$SB/last.log"; fails=$((fails + 1))
  fi
}
apk_check 0 FAKE_HAS_ICON=1
apk_check 1 FAKE_HAS_ICON=0

if [ "$fails" -ne 0 ]; then
  echo "selftest: $fails check(s) failed"
  exit 1
fi
echo "selftest: all exit-status checks passed"
