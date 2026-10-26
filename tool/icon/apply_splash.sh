#!/usr/bin/env bash
# Genera la pantalla de arranque (flutter_native_splash) y deshace lo que el plugin
# estropea: reindenta todo ios/Runner/Info.plist y le añade UIStatusBarHidden.
# Uso, desde la raíz del repositorio: bash tool/icon/apply_splash.sh
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root/app"
dart run flutter_native_splash:create
git checkout -- ios/Runner/Info.plist
