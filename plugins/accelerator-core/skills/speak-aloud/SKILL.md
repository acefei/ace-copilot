---
name: speak-aloud
description: Use when the user wants Claude to read or speak its responses aloud (text-to-speech, spoken output, audio) in Claude Code — on macOS, Linux, Windows, or from inside a Docker container where audio must be bridged to the host. Use to enable, configure, or troubleshoot spoken output.
---

# Speak Aloud

Make Claude Code read its responses aloud. A `Stop` hook fires after each response and
pipes the latest assistant message into a text-to-speech (TTS) engine.

`scripts/speak.sh` auto-detects the environment at runtime:

- **macOS host** → `say`
- **Linux host** → `spd-say` / `espeak-ng` / `festival`
- **Windows host** → PowerShell SAPI
- **Inside a container** → POSTs the text to a TTS server on the host (audio can't cross
  the container boundary), which speaks it with the host's engine.

The hook never blocks the session: any TTS failure is swallowed and it exits 0.

## Verify setup (run this first)

The Stop hook is intentionally silent — it cannot pop a message into the chat — so it
will **not** warn the user if, e.g., the host TTS server isn't running. When this skill is
invoked, run the check and **report the result to the user**; that is how they learn the
audio path is (or isn't) ready:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh" --check
```

It prints a PASS/FAIL report — detected OS, host-vs-container, and (in a container)
whether the host TTS server is reachable. On FAIL it states exactly what to fix (start the
host server, install an engine, add `--add-host`, …). Surface a FAIL to the user before
relying on spoken output.

As a fallback, when the Stop hook runs in a container and the server is unreachable it
drops a one-time breadcrumb at `$HOME/.claude/speak-aloud-server-down` (auto-cleared once
the server responds again).

## Enabling it

Installing the plugin auto-loads the `Stop` hook (`hooks/hooks.json` →
`${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh`). Then make sure the environment can produce audio.

### macOS / Windows host
Works out of the box (`say` / PowerShell SAPI are built in). Transcript parsing needs
`jq` — install if missing (`brew install jq`).

### Linux host
```bash
sudo apt-get install -y jq speech-dispatcher espeak-ng   # Debian/Ubuntu
```

### Docker container (audio bridged to the host)
1. **On the host**, start the TTS server (it owns the speakers):
   ```bash
   python3 "$CLAUDE_PLUGIN_ROOT/scripts/tts-host-server.py"   # listens on 0.0.0.0:8765
   ```
   Outside Claude, use the repo path to the script. Keep it running across reboots with
   launchd (macOS), systemd (Linux), or Task Scheduler (Windows).
2. Ensure the **container** can reach the host. Docker Desktop (macOS/Windows) provides
   `host.docker.internal` automatically. On plain Linux Docker, run the container with
   `--add-host=host.docker.internal:host-gateway`.
3. Install `jq` and `curl` in the container (`apt-get install -y jq curl`).
4. Test from inside the container:
   ```bash
   curl -m 3 http://host.docker.internal:8765/ -d "hello from the container"
   ```
   The host should speak. If the URL/port differs, set `SPEAK_ALOUD_URL` in the container.

## Configuration (env vars, all optional)

| Var | Meaning | Default |
|-----|---------|---------|
| `SPEAK_ALOUD_URL` | TTS server URL. **If set, forces remote mode** (POST) even on a host. | `http://host.docker.internal:8765/` |
| `SPEAK_ALOUD_VOICE` | Voice name (macOS `say` / host server) | engine default |
| `SPEAK_ALOUD_RATE` | Speech rate, wpm (macOS `say` / host server) | engine default |
| `SPEAK_ALOUD_MAXCHARS` | Truncate spoken text | `1000` |
| `SPEAK_ALOUD_FORCE_REMOTE` | Force the host-server path even if not detected as a container | unset |
| `SPEAK_ALOUD_MARKER` | Breadcrumb file written once when the server is unreachable | `$HOME/.claude/speak-aloud-server-down` |
| `PORT` | Listen port for `tts-host-server.py` | `8765` |

Container detection: an explicit `SPEAK_ALOUD_URL` or `SPEAK_ALOUD_FORCE_REMOTE`, then
`/.dockerenv`, `$container=podman`, or a `docker`/`containerd`/`kubepods`/`podman` entry in
`/proc/1/cgroup`. Otherwise it's treated as a host and uses native TTS.

## Manual test
```bash
"$CLAUDE_PLUGIN_ROOT/scripts/speak.sh" --check       # diagnose the TTS path (PASS/FAIL)
echo "this is a test" | "$CLAUDE_PLUGIN_ROOT/scripts/speak.sh"   # actually speak
```
`--check` reports whether audio will work; the second line speaks using whichever path
applies to the current environment.

## Troubleshooting

- **First step**: run `speak.sh --check` — it pinpoints the broken link (no engine, missing
  `jq`/`curl`, or unreachable host server) and prints the fix.
- **Silent on a host**: confirm the engine exists (`say` / `espeak-ng` / PowerShell) and
  `jq` is installed.
- **Silent in a container**: confirm the host server is running and reachable —
  `curl http://host.docker.internal:8765/` should return `OK`. On plain Linux Docker,
  verify the `--add-host` gateway flag. A `$HOME/.claude/speak-aloud-server-down` file means
  the hook tried and failed to reach the server.
- **Speaks too much**: lower `SPEAK_ALOUD_MAXCHARS`, or edit `speak.sh` to skip
  code-heavy messages.
- **No/wrong voice on Linux**: list voices with `spd-say -L` or `espeak-ng --voices`.

## Security note
`tts-host-server.py` binds `0.0.0.0` so the container can reach it. Text is passed to the
engine as argv (no shell) — no command injection, worst case a caller makes the host
speak. On untrusted networks, firewall the port to the Docker subnet.
