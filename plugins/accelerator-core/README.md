# accelerator-core

Core plugin for the **agent-accelerator** marketplace.

| Component | What it does |
|-----------|--------------|
| `/speak-aloud` (command) | Toggle & diagnose reading Claude's replies aloud via TTS — macOS / Linux / Windows / Docker (bridged to host). **Off by default**; `/speak-aloud on` enables (instant, no restart). Speaks only the visible reply; latest-wins, barge-in, and only the session you're driving. Backed by `Stop` / `UserPromptSubmit` / `SessionEnd` hooks + `scripts/speak.sh` + `scripts/tts-host-server.py`. |
| `remote-ssh-ops` (skill) | Safe remote work over SSH: key auth, login-shell command execution, pull/edit/verify/push file editing. |

## Install

```bash
claude marketplace add agent-accelerator acefei/agent-accelerator
claude plugin install accelerator-core@agent-accelerator
```

Then (one-time) restart Claude Code so the hooks load, and turn speech on with
`/speak-aloud on`. In a container, also start the host TTS server (see `/speak-aloud setup`).

## Layout

```
accelerator-core/
├── .claude-plugin/plugin.json
├── hooks/hooks.json                  # Stop / UserPromptSubmit / SessionEnd → speak.sh
├── commands/
│   └── speak-aloud.md                # /speak-aloud on|off|status|check|setup
├── scripts/
│   ├── speak.sh                      # speaker + on/off/status/--active/--cancel/--check
│   └── tts-host-server.py            # stateful host TTS server (latest-wins + active session)
└── skills/
    └── remote-ssh-ops/SKILL.md
```

Run `/speak-aloud` (or `/speak-aloud check`) anytime to see status and what to fix.
