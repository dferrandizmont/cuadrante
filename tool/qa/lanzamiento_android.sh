#!/usr/bin/env bash
# Guided pre-launch run on the Android emulator (docs/plan-pruebas-lanzamiento.md,
# phase F1). Run it YOURSELF in a terminal (it asks questions), from the repo root:
#
#   bash tool/qa/lanzamiento_android.sh
#
# 1. Checks the tools, boots Cuadrante_QA on port 5580 WITH a window.
# 2. Asks what you want to do by hand (Google sign-in, Play closed test) and
#    walks you through it, step by step.
# 3. From then on it runs alone: the release check (release APK and R8, the whole
#    battery and the real upgrade U02), the widgets (W01-W05) and the
#    single-activity check, one after the other on the same emulator.
# 4. If you asked for it, at the end it walks you through installing the closed
#    test from Google Play. Then it stops the emulator it started.
#
# Variables: QA_ANSWERS=sn (answers in order, for an unattended run: Google
# sign-in, Play at the end), QA_STAGES=battery,widgets,activity (which
# automatic stages), plus those of tool/qa/run_android.sh.
# Output (git-ignored): build/qa/lanzamiento-<date>/<stage>/ and resumen.md.
# Never asks for a password: you type it in the emulator window yourself.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M)"
RUN_OUT="$(cd "$HERE/../.." && pwd)/build/qa/lanzamiento-$STAMP"
export QA_OUT="$RUN_OUT/arranque"
QA_WINDOW=1
source "$HERE/common.sh"
trap qa_cleanup EXIT
trap 'exit 130' INT TERM
mkdir -p "$RUN_OUT"
SUMMARY="$RUN_OUT/resumen.md"
STAGES="${QA_STAGES:-battery,widgets,activity}"
ANSWERS="${QA_ANSWERS:-}"
HEAVY="$HOME/.agents/scripts/heavy.sh"

paso() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
# ask "question" -> 0 for yes. Takes the next letter of QA_ANSWERS when given.
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
espera() {
  [ -n "${QA_ANSWERS:-}" ] && return 0
  printf '    %s\n    Pulsa Enter cuando esté hecho. ' "$*"
  read -r _ || true
}
google_accounts() {
  qa_adb shell dumpsys account 2>/dev/null | tr -d '\r' |
    grep -c 'Account {name=.*type=com.google}' || true
}

{
  echo "# Lanzamiento en Android · $STAMP"
  echo
  echo "| Etapa | Resultado | Minutos | Detalle |"
  echo "|---|---|---|---|"
} >"$SUMMARY"

paso "Comprobando herramientas"
for tool in "$ADB" "$EMULATOR"; do
  [ -x "$tool" ] || { info "No encuentro $tool (ANDROID_HOME=$ANDROID_HOME)."; exit 2; }
done
command -v flutter >/dev/null || { info "No encuentro flutter en el PATH."; exit 2; }
"$EMULATOR" -list-avds 2>/dev/null | tr -d '\r' | grep -qx "$QA_AVD" ||
  { info "No existe el AVD $QA_AVD."; exit 2; }
[ -f "$HEAVY" ] && info "Las compilaciones irán por la cola compartida (heavy.sh)." || HEAVY=""
info "Resultados en $RUN_OUT"

paso "Arrancando emulador $QA_AVD (puerto $QA_EMULATOR_PORT, con ventana)"
info "Tarda uno o dos minutos la primera vez."
qa_device_select || exit 2
info "Emulador listo: $QA_SERIAL"

paso "Preguntas antes de empezar (solo ahora; después va solo)"
WANT_GOOGLE=0
WANT_PLAY=0
info "La app no tiene cuentas. Una cuenta de Google solo hace falta para instalar"
info "la prueba cerrada desde Play, Google Calendar sincronizado, Drive y la copia"
info "en la nube. Usa una cuenta de PRUEBAS, no la principal."
ask "¿Inicias sesión con una cuenta de Google en el emulador?" && WANT_GOOGLE=1
if [ "$WANT_GOOGLE" = 1 ]; then
  ask "¿Quieres instalar al final la prueba cerrada desde Google Play (tienes que estar delante)?" && WANT_PLAY=1
fi

if [ "$WANT_GOOGLE" = 1 ]; then
  if [ "$(google_accounts)" -gt 0 ]; then
    info "Ya hay una cuenta de Google en el emulador: la uso."
  else
    paso "Inicia sesión con Google"
    qa_adb shell am start -a android.settings.ADD_ACCOUNT_SETTINGS >/dev/null 2>&1 || true
    info "En la ventana del emulador se ha abierto «Añadir cuenta»: elige Google e"
    info "inicia sesión tú. Nadie más ve la contraseña."
    espera "Cuando veas la cuenta añadida,"
    if [ "$(google_accounts)" -gt 0 ]; then
      info "Cuenta de Google detectada."
    else
      info "No veo ninguna cuenta de Google: sigo sin ella."
      WANT_GOOGLE=0
      WANT_PLAY=0
    fi
  fi
fi
if [ "$WANT_PLAY" = 1 ]; then
  paso "Apúntate a la prueba cerrada (una sola vez por cuenta)"
  qa_adb shell am start -a android.intent.action.VIEW \
    -d "https://play.google.com/apps/testing/es.cuadrante.app" >/dev/null 2>&1 || true
  info "En el emulador se ha abierto la página de la prueba: pulsa «Convertirse en"
  info "tester». La cuenta tiene que estar en el grupo cuadrante-testers."
  espera "Cuando diga que ya eres tester,"
fi

paso "A partir de aquí va solo"
info "Etapas: $STAGES. Puedes dejarlo; tardará entre 30 y 60 minutos."
DEVICE="$QA_SERIAL"
FAILED=0
stage() {
  local id="$1" title="$2" script="$3"
  case ",$STAGES," in *",$id,"*) ;; *) return 0 ;; esac
  paso "$title"
  local out="$RUN_OUT/$id" start rc minutes
  mkdir -p "$out"
  start="$(date +%s)"
  # Each stage reuses this emulator (QA_DEVICE: never stopped by the stage).
  if [ -n "$HEAVY" ]; then
    QA_DEVICE="$DEVICE" QA_OUT="$out" sh "$HEAVY" bash "$HERE/$script" >"$out/salida.log" 2>&1
  else
    QA_DEVICE="$DEVICE" QA_OUT="$out" bash "$HERE/$script" >"$out/salida.log" 2>&1
  fi
  rc=$?
  minutes=$(( ($(date +%s) - start + 59) / 60 ))
  if [ "$rc" = 0 ]; then
    info "Bien ($minutes min)."
    echo "| $title | Bien | $minutes | \`$id/\` |" >>"$SUMMARY"
  else
    FAILED=1
    info "FALLA (código $rc, $minutes min). Detalle: $out/salida.log"
    tail -n 5 "$out/salida.log" | sed 's/^/      /'
    echo "| $title | **Falla ($rc)** | $minutes | \`$id/salida.log\` |" >>"$SUMMARY"
  fi
}
# The Play build (another signature) cannot be overwritten by the test builds.
qa_adb uninstall "$QA_PACKAGE" >/dev/null 2>&1 || true
stage battery "APK de release, batería completa y actualización real (U02)" release_check.sh
stage widgets "Widgets de Android (W01-W05)" widget_android.sh
stage activity "Una sola actividad" single_activity_check.sh

if [ "$WANT_PLAY" = 1 ]; then
  paso "Instala la prueba cerrada desde Google Play"
  qa_adb uninstall "$QA_PACKAGE" >/dev/null 2>&1 || true
  qa_adb shell am start -a android.intent.action.VIEW \
    -d "market://details?id=$QA_PACKAGE" >/dev/null 2>&1 || true
  info "En el emulador está abierta la ficha de Cuadrante en Play: pulsa «Instalar»"
  info "y ábrela. Comprueba que arranca, que el mes se ve y que Ajustes › Ayuda abre"
  info "la política de privacidad (GP-12 del plan)."
  espera "Cuando lo hayas comprobado,"
  if ask "¿Ha funcionado bien la app instalada desde Play?"; then
    echo "| Instalación desde Google Play (GP-12) | Bien (manual) | — | — |" >>"$SUMMARY"
  else
    FAILED=1
    echo "| Instalación desde Google Play (GP-12) | **Falla (manual)** | — | anótalo en docs/qa-hallazgos |" >>"$SUMMARY"
  fi
fi

{
  echo
  [ "$FAILED" = 0 ] && echo "**Todo en verde.**" || echo "**Hay etapas que fallan**: mira su \`salida.log\` y el \`report.md\` de cada carpeta."
  echo
  echo "Cuenta de Google en el emulador: $([ "$WANT_GOOGLE" = 1 ] && echo sí || echo no)."
  echo "Se borra al cerrar el emulador (arranca sin guardar estado)."
} >>"$SUMMARY"
paso "Terminado"
cat "$SUMMARY" | sed 's/^/    /'
info "Resumen: $SUMMARY"
exit "$FAILED"
