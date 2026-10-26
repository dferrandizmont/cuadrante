#!/usr/bin/env bash
# Reparte app/assets/icon/*.png con flutter_launcher_icons y deshace lo que el
# plugin estropea en iOS: reescribe Contents.json con tamaños de iOS 6 (50, 57,
# 72 px) y cambia un ajuste de compilación del proyecto de Xcode.
# Uso, desde la raíz del repositorio: bash tool/icon/apply_icons.sh
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root/app"
dart run flutter_launcher_icons
git checkout -- ios/Runner.xcodeproj/project.pbxproj \
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json
rm -f ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-{50x50,57x57,72x72}@{1x,2x}.png
