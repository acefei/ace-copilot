---
description: Toggle and diagnose spoken audio of Claude's replies (text-to-speech)
argument-hint: "[on | off | status | check | setup]"
---

# /speak-aloud

Controls the **speak-aloud** feature: read Claude's replies aloud via TTS. Speaking is
**off by default** and gated at runtime — toggling is instant (no restart), because the
hooks stay loaded and just check a flag.

Run the script with the user's argument (default to `status` if none given) and report the
output verbatim. The script is at `${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh`.

Map `$ARGUMENTS` to the action:

- **on** → `${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh on`
  Enables speaking and marks this session active. Then run `check` and report whether the
  audio path is actually ready (PASS/FAIL).
- **off** → `${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh off`
  Disables speaking and stops any audio in progress.
- **status** → `${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh status`
- **check** → `${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh --check`
  Diagnoses OS, container-vs-host, server reachability, and engine/parser availability.
- **setup** (or when `check` FAILs) → walk the user through enabling audio:
  - **macOS/Windows host**: works out of the box (`say` / PowerShell SAPI).
  - **Linux host**: `sudo apt-get install -y jq speech-dispatcher espeak-ng`.
  - **Docker container** (this is the common case — audio must be produced on the host):
    1. On the **host**, start the TTS server (no checkout needed):
       ```bash
       curl -fsSL https://raw.githubusercontent.com/acefei/agent-accelerator/main/plugins/accelerator-core/scripts/tts-host-server.py | python3
       ```
       Restart this server after a plugin upgrade — the latest-wins/active-session logic
       lives in it.
    2. Ensure the container can reach the host: Docker Desktop provides
       `host.docker.internal` automatically; plain Linux Docker needs
       `--add-host=host.docker.internal:host-gateway`.
    3. Install `jq` and `curl` in the container if missing (`apt-get install -y jq curl`).

## Behavior (for reference)

- Speaks only the **last assistant message** (the visible reply), stripping code/tables/
  URLs/markers, capped at 2000 chars.
- **Latest wins**: a new reply cancels the one still playing.
- **Active-session gating**: only the session you last typed in speaks; switch and type
  elsewhere and the old one goes silent. Background/agent-view sessions you aren't driving
  stay silent.
- **Barge-in**: the moment you submit a prompt, in-progress speech stops.

## Notes

- First-time only: after installing/upgrading the plugin, **restart Claude Code** once so
  the hooks load. After that, `on`/`off` are instant.
- Env overrides: `SPEAK_ALOUD_ENABLED=1|0` forces the gate; `SPEAK_ALOUD_VOICE`,
  `SPEAK_ALOUD_RATE`, `SPEAK_ALOUD_MAXCHARS`, `SPEAK_ALOUD_URL`, `PORT` tune behavior.
