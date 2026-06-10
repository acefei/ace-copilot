#!/usr/bin/env bash
# speak-aloud: speak Claude's latest response aloud.
#
# Modes:
#   speak.sh                 Stop-hook mode — reads hook JSON on stdin, speaks the
#                            latest assistant message.
#   echo "text" | speak.sh   Manual mode — speaks the piped text verbatim.
#   speak.sh --check         Diagnose the current environment and TTS path; prints a
#                            PASS/FAIL report and exits non-zero on FAIL. Use this to
#                            tell whether audio will actually work (e.g. host server up).
#
# Environment detection (see in_container):
#   - Inside a container -> POST text to a host TTS server (SPEAK_ALOUD_URL).
#   - macOS host         -> `say`
#   - Linux host         -> spd-say | espeak-ng | espeak | festival
#   - Windows host       -> PowerShell SAPI
#
# Config via env (all optional):
#   SPEAK_ALOUD_URL          TTS server URL. If SET, forces remote mode even on a host.
#                            (default when containerized: http://host.docker.internal:8765/)
#   SPEAK_ALOUD_FORCE_REMOTE force remote mode regardless of detection
#   SPEAK_ALOUD_VOICE        voice name (macOS `say` only)
#   SPEAK_ALOUD_RATE         words-per-minute (macOS `say` only)
#   SPEAK_ALOUD_MAXCHARS     truncate spoken text (default 1000)
#   SPEAK_ALOUD_MARKER       breadcrumb file written once when the server is unreachable
#                            (default $HOME/.claude/speak-aloud-server-down)
#
# Never blocks the session: all TTS failures are swallowed and the hook exits 0.
set -uo pipefail

MARKER="${SPEAK_ALOUD_MARKER:-$HOME/.claude/speak-aloud-server-down}"

detect_os() { uname -s 2>/dev/null; }

tts_url() { printf '%s' "${SPEAK_ALOUD_URL:-http://host.docker.internal:8765/}"; }

in_container() {
  [ -n "${SPEAK_ALOUD_FORCE_REMOTE:-}" ] && return 0
  [ -n "${SPEAK_ALOUD_URL:-}" ] && return 0                 # explicit URL -> remote mode
  [ -f /.dockerenv ] && return 0
  [ "${container:-}" = "podman" ] && return 0               # podman sets $container
  grep -qaE 'docker|containerd|kubepods|podman' /proc/1/cgroup 2>/dev/null && return 0
  return 1
}

# Echo the native engine that would be used, or nothing if none is available.
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

post_remote() {  # $1 = text; returns curl's exit status
  command -v curl >/dev/null 2>&1 || return 127
  printf '%s' "$1" | curl -s -m 5 -X POST --data-binary @- "$(tts_url)" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# --check: diagnose and report. Exits 0 (PASS) or 1 (FAIL).
# ---------------------------------------------------------------------------
if [ "${1:-}" = "--check" ]; then
  os="$(detect_os)"
  echo "speak-aloud check"
  echo "  os:     $os"
  if in_container; then
    url="$(tts_url)"
    echo "  mode:   container -> host TTS server"
    echo "  url:    $url"
    if ! command -v curl >/dev/null 2>&1; then
      echo "  RESULT: FAIL — curl is not installed in this container (apt-get install -y curl)"
      exit 1
    fi
    if curl -s -m 5 "$url" >/dev/null 2>&1; then
      echo "  server: reachable"
      echo "  RESULT: PASS — host TTS server is up"
      rm -f "$MARKER" 2>/dev/null
      exit 0
    fi
    echo "  server: UNREACHABLE"
    echo "  RESULT: FAIL — start the host TTS server ON THE HOST, then re-check:"
    echo "          curl -fsSL https://raw.githubusercontent.com/acefei/agent-accelerator/main/plugins/accelerator-core/scripts/tts-host-server.py | python3"
    echo "          (plain Linux Docker also needs: --add-host=host.docker.internal:host-gateway)"
    exit 1
  fi
  eng="$(native_engine)"
  echo "  mode:   native host TTS"
  if [ -n "$eng" ]; then
    echo "  engine: $eng"
    if command -v jq >/dev/null 2>&1; then echo "  jq:     present"; else echo "  jq:     MISSING — install jq to parse the transcript"; fi
    echo "  RESULT: PASS — $eng available"
    exit 0
  fi
  echo "  engine: none found"
  case "$os" in
    Linux) echo "  RESULT: FAIL — install a TTS engine: sudo apt-get install -y speech-dispatcher espeak-ng" ;;
    *)     echo "  RESULT: FAIL — no TTS engine detected for $os" ;;
  esac
  exit 1
fi

# ---------------------------------------------------------------------------
# Speak mode (Stop hook or manual stdin).
# ---------------------------------------------------------------------------
raw=$(cat)

# If stdin looks like Stop-hook JSON, pull the last assistant text from the transcript.
text=""
if printf '%s' "$raw" | head -c1 | grep -q '{'; then
  transcript=$(printf '%s' "$raw" \
    | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  if [ -n "${transcript:-}" ] && [ -f "$transcript" ] && command -v jq >/dev/null 2>&1; then
    text=$(tail -n 80 "$transcript" \
      | jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' 2>/dev/null \
      | tail -n 1)
  fi
fi
# Fallback: treat stdin as raw text (manual use, or no jq/transcript available).
[ -z "$text" ] && text="$raw"

# Strip code fences/inline code and common markdown punctuation; collapse whitespace.
clean=$(printf '%s' "$text" \
  | sed -e 's/```[^`]*```//g' -e 's/`[^`]*`//g' -e 's/[#*_>`|]//g' \
  | tr '\n' ' ' | tr -s ' ')
maxchars=${SPEAK_ALOUD_MAXCHARS:-1000}
clean=$(printf '%s' "$clean" | cut -c1-"$maxchars")
[ -z "${clean// /}" ] && exit 0

if in_container; then
  if post_remote "$clean"; then
    rm -f "$MARKER" 2>/dev/null                    # success clears the breadcrumb
  elif [ ! -f "$MARKER" ]; then                    # one-time breadcrumb, don't nag
    mkdir -p "$(dirname "$MARKER")" 2>/dev/null
    printf 'speak-aloud: host TTS server unreachable at %s\nStart it on the host, or run: speak.sh --check\n' \
      "$(tts_url)" > "$MARKER" 2>/dev/null || true
  fi
else
  speak_native "$clean" >/dev/null 2>&1 || true
fi
exit 0
