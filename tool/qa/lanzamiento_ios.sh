#!/usr/bin/env bash
# Guided pre-launch run on the iOS simulator, on the Mac (docs/plan-pruebas-lanzamiento.md,
# phase F2). Run it YOURSELF in Terminal (it asks questions), from the repo root:
#
#   bash tool/qa/lanzamiento_ios.sh
#
# 1. Checks Xcode and Flutter, boots an iPhone simulator WITH its window.
# 2. Asks what you want to check by hand at the end (none needs an Apple ID:
#    the simulator's calendar and «Archivos › En mi iPhone» work without one).
# 3. From then on it runs alone: analyze and unit tests, the integration tests on
#    the simulator, the App Store screenshots (6.3" and 6.9") and a simulator
#    build installed and opened in light/dark mode and at the largest text size.
# 4. If you asked for it, it walks you through the visual checks, one by one,
#    and writes down your answers. It shuts down the simulator only if it booted it.
#
# Variables: QA_IOS_DEVICE="iPhone 17 Pro" (simulator name), QA_ANSWERS=sn,
# QA_STAGES=unit,integration,shots,build. Output (git-ignored):
# build/qa/lanzamiento-ios-<date>/ and resumen.md.
# Untested on the Mac when written (27-oct-2026): if a command fails, the stage
# is marked as failing and the run goes on.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP="$ROOT/app"
STAMP="$(date +%Y%m%d-%H%M)"
OUT="$ROOT/build/qa/lanzamiento-ios-$STAMP"
SUMMARY="$OUT/resumen.md"
STAGES="${QA_STAGES:-unit,integration,shots,build}"
ANSWERS="${QA_ANSWERS:-}"
DEVICE_NAME="${QA_IOS_DEVICE:-}"
BUNDLE="es.cuadrante.app"
BOOTED_BY_US=0
UDID=""
FAILED=0
mkdir -p "$OUT"

paso() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
ask() {
  local reply
  if [ -n "$ANSWERS" ]; then
    reply="${ANSWERS:0:1}"
    ANSWERS="${ANSWERS:1}"
    printf '    %s [s/N] %s (QA_ANSWERS)\n' "$1" "$reply"
  else
    printf '    %s [s/N] ' "$1"
    read -r reply || reply=n
  fi
  case "$reply" in s | S | si | sí | y | Y) return 0 ;; *) return 1 ;; esac
}
row() { echo "| $1 | $2 | $3 | $4 |" >>"$SUMMARY"; }
cleanup() {
  local rc=$?
  trap - EXIT INT TERM
  if [ "$BOOTED_BY_US" = 1 ] && [ -n "$UDID" ]; then
    info "Apagando el simulador que arrancó este guion ($DEVICE_NAME)."
    xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
  fi
  exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

{
  echo "# Lanzamiento en iOS (simulador) · $STAMP"
  echo
  echo "| Etapa | Resultado | Minutos | Detalle |"
  echo "|---|---|---|---|"
} >"$SUMMARY"

paso "Comprobando herramientas"
command -v xcrun >/dev/null || { info "No encuentro xcrun: instala Xcode."; exit 2; }
command -v flutter >/dev/null || { info "No encuentro flutter en el PATH."; exit 2; }
info "$(xcodebuild -version 2>/dev/null | head -n 1)"
info "Resultados en $OUT"

paso "Eligiendo el simulador"
LIST="$(xcrun simctl list devices available)"
if [ -z "$DEVICE_NAME" ]; then
  # The 6.3" iPhone is the screenshot size Apple requires (docs/lanzamiento-app-store.md).
  DEVICE_NAME="$(printf '%s\n' "$LIST" | sed -n 's/^ *\(iPhone [0-9]* Pro\) (.*/\1/p' | tail -n 1)"
fi
UDID="$(printf '%s\n' "$LIST" | grep -m 1 "^ *$DEVICE_NAME (" | sed 's/.*(\([0-9A-F-]\{36\}\)).*/\1/')"
[ -n "$UDID" ] || { info "No encuentro el simulador «$DEVICE_NAME». Pon QA_IOS_DEVICE=\"<nombre>\"."; exit 2; }
info "$DEVICE_NAME ($UDID)"

paso "Arrancando simulador"
if printf '%s\n' "$LIST" | grep "$UDID" | grep -q Booted; then
  info "Ya estaba encendido: lo uso y no lo apago al final."
else
  xcrun simctl boot "$UDID" || { info "No arranca el simulador."; exit 2; }
  BOOTED_BY_US=1
fi
open -a Simulator --args -CurrentDeviceUDID "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
xcrun simctl ui "$UDID" appearance light >/dev/null 2>&1 || true
info "Simulador listo."

paso "Preguntas antes de empezar (solo ahora; después va solo)"
info "No hace falta iniciar sesión con un Apple ID en el simulador."
WANT_MANUAL=0
ask "¿Quieres hacer al final las comprobaciones visuales guiadas (tienes que estar delante)?" && WANT_MANUAL=1

paso "A partir de aquí va solo"
info "Etapas: $STAGES. Puedes dejarlo; tardará entre 20 y 45 minutos."
stage() {
  local id="$1" title="$2"
  shift 2
  case ",$STAGES," in *",$id,"*) ;; *) return 0 ;; esac
  paso "$title"
  local log="$OUT/$id.log" start rc minutes
  start="$(date +%s)"
  (cd "$APP" && "$@") >"$log" 2>&1
  rc=$?
  minutes=$(( ($(date +%s) - start + 59) / 60 ))
  if [ "$rc" = 0 ]; then
    info "Bien ($minutes min)."
    row "$title" "Bien" "$minutes" "\`$id.log\`"
  else
    FAILED=1
    info "FALLA (código $rc, $minutes min). Detalle: $log"
    tail -n 5 "$log" | sed 's/^/      /'
    row "$title" "**Falla ($rc)**" "$minutes" "\`$id.log\`"
  fi
}
unit() { flutter pub get && flutter analyze && TZ=Europe/Madrid flutter test; }
integration() { flutter test integration_test/app_test.dart -d "$UDID"; }
shots() {
  flutter test --dart-define=GENERATE_STORE=true --dart-define=STORE_TARGET=ios63 test/store/store_screenshots_test.dart &&
    flutter test --dart-define=GENERATE_STORE=true --dart-define=STORE_TARGET=ios69 test/store/store_screenshots_test.dart
}
build() {
  flutter build ios --simulator --debug --dart-define=USE_DEMO_DATA=true || return 1
  xcrun simctl uninstall "$UDID" "$BUNDLE" >/dev/null 2>&1
  xcrun simctl install "$UDID" build/ios/iphonesimulator/Runner.app &&
    xcrun simctl launch "$UDID" "$BUNDLE"
}
stage unit "Análisis y pruebas unitarias" unit
stage integration "Pruebas de integración en el simulador" integration
stage shots "Capturas de la App Store (6,3″ y 6,9″)" shots
stage build "Compilar, instalar y abrir en el simulador" build

if [ "$WANT_MANUAL" = 1 ]; then
  paso "Comprobaciones visuales guiadas"
  check() {
    local id="$1" what="$2"
    shift 2
    [ "$#" -gt 0 ] && "$@" >/dev/null 2>&1
    info "$id · $what"
    if ask "¿Está bien?"; then row "$id (manual)" "Bien" "—" "$what"; else FAILED=1; row "$id (manual)" "**Falla**" "—" "$what"; fi
  }
  xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  check M1 "El mes se ve completo, con color, código y hora en cada turno, y el selector Cuadrícula / Lista"
  check M2 "Modo oscuro: todo se lee y la opción elegida del selector se distingue" xcrun simctl ui "$UDID" appearance dark
  check M3 "Texto al máximo: nada se corta ni se solapa, y el botón «Pintar» no tapa el día" xcrun simctl ui "$UDID" content_size accessibility-extra-extra-extra-large
  xcrun simctl ui "$UDID" content_size large >/dev/null 2>&1 || true
  xcrun simctl ui "$UDID" appearance light >/dev/null 2>&1 || true
  check M4 "Ajustes › Idioma: cambia a català, galego, euskara e inglés y vuelve; no queda ningún texto en otro idioma"
  check M5 "Ajustes › Ayuda: las preguntas frecuentes no mencionan Android y «Política de privacidad» abre la web"
  check M6 "Copia de seguridad › Exportar: la hoja de compartir aparece y se puede guardar en Archivos"
  check M7 "Importar del calendario del móvil: pide permiso con el texto de iOS en tu idioma"
  check M8 "Pinta tres días, cierra la app desde el selector de apps y vuelve a abrirla: los turnos siguen"
fi

{
  echo
  [ "$FAILED" = 0 ] && echo "**Todo en verde.**" || echo "**Hay etapas que fallan**: mira su \`.log\`."
  echo
  echo "Lo que el simulador no prueba (iPhone XR o cuenta de pago): widget, alarmas con el móvil"
  echo "bloqueado, TestFlight y la prueba de 7 días (docs/plan-pruebas-lanzamiento.md, fase F4)."
} >>"$SUMMARY"
paso "Terminado"
sed 's/^/    /' "$SUMMARY"
info "Resumen: $SUMMARY"
exit "$FAILED"
