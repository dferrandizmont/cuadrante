#!/usr/bin/env bash
# The check before EVERY release (docs/qa.md): the whole battery (Q01-Q13 and
# U01) plus U02, the real upgrade from the previous release. Needs network (gh)
# and takes about 15 minutes. Run it from the repo root, in Git Bash:
#
#   tool/qa/release_check.sh
#
# Same variables as tool/qa/run_android.sh (QA_AVD, QA_DEVICE, ...) and
# tool/qa/upgrade_android.sh (QA_OLD_TAG, ...). Output: build/qa/report.md.
set -u
# First the cheap, release-only check: resources that only Dart references
# (the alarm small icon) must survive R8 in the release APK. It fails fast,
# before the 15-minute battery. QA_RELEASE_APK=ruta.apk skips its build.
"$(dirname "${BASH_SOURCE[0]}")/release_apk_check.sh" || exit 1
# Not `exec`: the status of run_android.sh (battery AND U02) is passed on explicitly.
QA_UPGRADE=1 "$(dirname "${BASH_SOURCE[0]}")/run_android.sh" "$@"
exit $?
