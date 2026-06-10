#!/usr/bin/env bash
# speak-aloud: speak Claude's latest reply aloud, with an on/off gate, latest-wins
# cancellation, and active-session gating.
#
# Subcommands / modes (selected by $1):
#   on         Enable speaking (create the gate flag) + mark this session active.
#   off        Disable speaking (remove the gate flag) + stop any current speech.
#   status     Print ON/OFF.
#   --check    Diagnose the TTS path; prints PASS/FAIL, exits non-zero on FAIL.
#   --active   UserPromptSubmit hook: mark this session active + stop current speech.
#   --cancel   SessionEnd hook: stop current speech.
#   (none)     Stop hook: read hook JSON on stdin, extract last_assistant_message, speak.
#   echo "x" | speak.sh   Manual: speak piped text verbatim.
#
# The hook modes (speak / --active) no-op unless speaking is enabled (default OFF), so the
# plugin never talks until you run `/speak-aloud on`. Toggling is instant (no restart): the
# hooks stay loaded and just check the flag.
#
# Config via env (all optional):
#   SPEAK_ALOUD_ENABLED      1/on/true or 0/off/false — overrides the gate flag file.
#   SPEAK_ALOUD_STATE_FILE   gate flag file (default $HOME/.claude/speak-aloud-enabled)
#   SPEAK_ALOUD_URL          TTS server URL. If SET, forces remote mode even on a host.
#   SPEAK_ALOUD_FORCE_REMOTE force remote mode regardless of detection
#   SPEAK_ALOUD_VOICE / SPEAK_ALOUD_RATE   voice / words-per-minute (macOS `say`)
#   SPEAK_ALOUD_MAXCHARS     truncate spoken text (default 2000)
#   SPEAK_ALOUD_MARKER       breadcrumb file when the server is unreachable
#   SPEAK_ALOUD_ACTIVE_FILE  native-mode active-session file
#
# Never blocks the session: failures are swallowed and it exits 0.
set -uo pipefail

MARKER="${SPEAK_ALOUD_MARKER:-$HOME/.claude/speak-aloud-server-down}"
ACTIVE_FILE="${SPEAK_ALOUD_ACTIVE_FILE:-$HOME/.claude/speak-aloud-active-session}"
ENABLED_FILE="${SPEAK_ALOUD_STATE_FILE:-$HOME/.claude/speak-aloud-enabled}"

detect_os() { uname -s 2>/dev/null; }
base_url() { printf '%s' "${SPEAK_ALOUD_URL:-http://host.docker.internal:8765/}"; }

in_container() {
  [ -n "${SPEAK_ALOUD_FORCE_REMOTE:-}" ] && return 0
  [ -n "${SPEAK_ALOUD_URL:-}" ] && return 0
  [ -f /.dockerenv ] && return 0
  [ "${container:-}" = "podman" ] && return 0
  grep -qaE 'docker|containerd|kubepods|podman' /proc/1/cgroup 2>/dev/null && return 0
  return 1
}

is_enabled() {
  case "${SPEAK_ALOUD_ENABLED:-}" in
    1|true|on|yes|TRUE|On|ON) return 0 ;;
    0|false|off|no|FALSE|Off|OFF) return 1 ;;
  esac
  [ -f "$ENABLED_FILE" ]
}

native_engine() {
  case "$(detect_os)" in
    Darwin) echo "say" ;;
    Linux)
      local e
      for e in spd-say espeak-ng espeak festival; do
        command -v "$e" >/dev/null 2>&1 && { echo "$e"; return; }
      done ;;
    MINGW*|MSYS*|CYGWIN*) echo "powershell" ;;
  esac
}

stop_native() {
  killall say         2>/dev/null
  pkill  -x say       2>/dev/null
  spd-say -C          2>/dev/null
  pkill  -x espeak-ng 2>/dev/null
  pkill  -x espeak    2>/dev/null
  return 0
}

speak_native() {
  local msg="$1"
  case "$(detect_os)" in
    Darwin)
      say ${SPEAK_ALOUD_VOICE:+-v "$SPEAK_ALOUD_VOICE"} ${SPEAK_ALOUD_RATE:+-r "$SPEAK_ALOUD_RATE"} "$msg" ;;
    Linux)
      if   command -v spd-say   >/dev/null 2>&1; then spd-say -w "$msg"
      elif command -v espeak-ng >/dev/null 2>&1; then espeak-ng "$msg"
      elif command -v espeak    >/dev/null 2>&1; then espeak "$msg"
      elif command -v festival  >/dev/null 2>&1; then printf '%s' "$msg" | festival --tts
      else return 1; fi ;;
    MINGW*|MSYS*|CYGWIN*)
      SPEAK_TEXT="$msg" powershell.exe -NoProfile -Command \
        "Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak(\$env:SPEAK_TEXT)" ;;
    *) return 1 ;;
  esac
}

post_signal() {  # $1 = active|cancel  (empty body, session header)
  command -v curl >/dev/null 2>&1 || return 127
  curl -s -m 5 -X POST -H "X-Session-Id: ${SID:-}" --data-binary '' "$(base_url)$1" >/dev/null 2>&1
}
post_speak() {   # $1 = text
  command -v curl >/dev/null 2>&1 || return 127
  printf '%s' "$1" | curl -s -m 5 -X POST -H "X-Session-Id: ${SID:-}" --data-binary @- "$(base_url)speak" >/dev/null 2>&1
}

mark_active() {  # claim the active slot for $SID
  if in_container; then post_signal active || true
  else mkdir -p "$(dirname "$ACTIVE_FILE")" 2>/dev/null; printf '%s' "${SID:-}" > "$ACTIVE_FILE" 2>/dev/null || true; fi
}
do_cancel() {
  if in_container; then post_signal cancel || true; else stop_native; fi
}

# ---------------------------------------------------------------------------
# User-facing subcommands (no stdin needed).
# ---------------------------------------------------------------------------
case "${1:-}" in
  on)
    SID="${CLAUDE_CODE_SESSION_ID:-}"
    mkdir -p "$(dirname "$ENABLED_FILE")" 2>/dev/null
    : > "$ENABLED_FILE" 2>/dev/null || true
    mark_active
    echo "speak-aloud: ON — this session will be spoken aloud (and is now the active one)."
    exit 0 ;;
  off)
    SID="${CLAUDE_CODE_SESSION_ID:-}"
    rm -f "$ENABLED_FILE" 2>/dev/null
    do_cancel
    echo "speak-aloud: OFF — speaking disabled and any current speech stopped."
    exit 0 ;;
  status)
    if is_enabled; then echo "speak-aloud: ON"; else echo "speak-aloud: OFF"; fi
    exit 0 ;;
esac

if [ "${1:-}" = "--check" ] || [ "${1:-}" = "check" ]; then
  os="$(detect_os)"
  echo "speak-aloud check"
  echo "  os:      $os"
  if is_enabled; then echo "  speaking: ON"; else echo "  speaking: OFF (run '/speak-aloud on' to enable)"; fi
  if in_container; then
    url="$(base_url)"
    echo "  mode:    container -> host TTS server"
    echo "  url:     $url"
    if ! command -v curl >/dev/null 2>&1; then
      echo "  RESULT:  FAIL — curl is not installed in this container (apt-get install -y curl)"
      exit 1
    fi
    if curl -s -m 5 "$url" >/dev/null 2>&1; then
      echo "  server:  reachable"
      if command -v jq >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then echo "  parser:  jq/python3 present"; else echo "  parser:  MISSING — install jq or python3"; fi
      echo "  RESULT:  PASS — host TTS server is up"
      rm -f "$MARKER" 2>/dev/null
      exit 0
    fi
    echo "  server:  UNREACHABLE"
    echo "  RESULT:  FAIL — start the host TTS server ON THE HOST, then re-check:"
    echo "           curl -fsSL https://raw.githubusercontent.com/acefei/agent-accelerator/main/plugins/accelerator-core/scripts/tts-host-server.py | python3"
    echo "           (plain Linux Docker also needs: --add-host=host.docker.internal:host-gateway)"
    exit 1
  fi
  eng="$(native_engine)"
  echo "  mode:    native host TTS"
  if [ -n "$eng" ]; then
    echo "  engine:  $eng"
    if command -v jq >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then echo "  parser:  jq/python3 present"; else echo "  parser:  MISSING — install jq or python3"; fi
    echo "  RESULT:  PASS — $eng available"
    exit 0
  fi
  echo "  engine:  none found"
  case "$os" in
    Linux) echo "  RESULT:  FAIL — install a TTS engine: sudo apt-get install -y speech-dispatcher espeak-ng" ;;
    *)     echo "  RESULT:  FAIL — no TTS engine detected for $os" ;;
  esac
  exit 1
fi

# ---------------------------------------------------------------------------
# Hook modes read the hook JSON (or piped text) from stdin.
# ---------------------------------------------------------------------------
raw=$(cat)

SID="${CLAUDE_CODE_SESSION_ID:-}"
if [ -z "$SID" ] && printf '%s' "$raw" | head -c1 | grep -q '{'; then
  if command -v jq >/dev/null 2>&1; then
    SID=$(printf '%s' "$raw" | jq -r '.session_id // empty' 2>/dev/null)
  fi
  if [ -z "$SID" ] && command -v python3 >/dev/null 2>&1; then
    SID=$(printf '%s' "$raw" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("session_id") or "")
except Exception: pass' 2>/dev/null)
  fi
fi

MODE="${1:-speak}"

# --cancel always runs (stopping speech is safe and desirable when a session ends).
if [ "$MODE" = "--cancel" ]; then
  do_cancel
  exit 0
fi

# Gate: speak / --active no-op unless speaking is enabled.
is_enabled || exit 0

# --active: become the speaking session; stop prior speech (barge-in).
if [ "$MODE" = "--active" ]; then
  mark_active
  exit 0
fi

# speak (default): extract the visible reply and speak it.
text=""
if printf '%s' "$raw" | head -c1 | grep -q '{'; then
  if command -v jq >/dev/null 2>&1; then
    text=$(printf '%s' "$raw" | jq -r '.last_assistant_message // empty' 2>/dev/null)
  fi
  if [ -z "$text" ] && command -v python3 >/dev/null 2>&1; then
    text=$(printf '%s' "$raw" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("last_assistant_message") or "")
except Exception: pass' 2>/dev/null)
  fi
  if [ -z "$text" ]; then
    transcript=$(printf '%s' "$raw" \
      | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    if [ -n "${transcript:-}" ] && [ -f "$transcript" ] && command -v jq >/dev/null 2>&1; then
      text=$(tail -n 80 "$transcript" \
        | jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' 2>/dev/null \
        | tail -n 1)
    fi
  fi
fi
[ -z "$text" ] && text="$raw"

clean=$(printf '%s\n' "$text" \
  | awk '/^[[:space:]]*```/{f=!f;next} f{next} /^[[:space:]]*\|/{next} {print}' \
  | sed -E -e 's/`[^`]*`//g' \
           -e 's#https?://[^[:space:])]*##g' \
           -e 's/^[[:space:]]*[-*+][[:space:]]+//' \
           -e 's/^[[:space:]]*#+[[:space:]]*//' \
           -e 's/[*_`>#|]//g' \
  | tr '\n' ' ' | tr -s ' ')
maxchars=${SPEAK_ALOUD_MAXCHARS:-2000}
clean=$(printf '%s' "$clean" | cut -c1-"$maxchars")
[ -z "${clean// /}" ] && exit 0

if in_container; then
  if post_speak "$clean"; then
    rm -f "$MARKER" 2>/dev/null
  elif [ ! -f "$MARKER" ]; then
    mkdir -p "$(dirname "$MARKER")" 2>/dev/null
    printf 'speak-aloud: host TTS server unreachable at %s\nStart it on the host, or run: speak.sh --check\n' \
      "$(base_url)" > "$MARKER" 2>/dev/null || true
  fi
else
  active=""; [ -f "$ACTIVE_FILE" ] && active=$(cat "$ACTIVE_FILE" 2>/dev/null)
  if [ -z "$active" ] || [ -z "$SID" ] || [ "$active" = "$SID" ]; then
    stop_native
    speak_native "$clean" >/dev/null 2>&1 &
  fi
fi
exit 0
