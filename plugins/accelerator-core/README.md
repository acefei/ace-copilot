# accelerator-core

Core plugin for the **agent-accelerator** marketplace. Bundles two skills.

| Skill | What it does |
|-------|--------------|
| `speak-aloud` | Read Claude's responses aloud via TTS — macOS / Linux / Windows / Docker (bridged to host). Ships a `Stop` hook + `scripts/speak.sh` + `scripts/tts-host-server.py`. |
| `remote-ssh-ops` | Safe remote work over SSH: key auth, login-shell command execution, pull/edit/verify/push file editing. |

## Install

```bash
claude marketplace add agent-accelerator acefei/agent-accelerator
claude plugin install accelerator-core@agent-accelerator
```

## Layout

```
accelerator-core/
├── .claude-plugin/plugin.json
├── hooks/hooks.json                  # speak-aloud Stop hook → scripts/speak.sh
├── scripts/
│   ├── speak.sh                      # universal speaker (host vs container)
│   └── tts-host-server.py            # host TTS server for the Docker bridge
└── skills/
    ├── speak-aloud/SKILL.md
    └── remote-ssh-ops/SKILL.md
```

See each skill's `SKILL.md` for setup, configuration, and usage.
