# agent-accelerator

A [Claude Code](https://docs.claude.com/en/docs/claude-code) **plugin marketplace**.

A marketplace is a git repo with a `.claude-plugin/marketplace.json` manifest that lists
one or more plugins. Each plugin bundles slash commands, subagents, skills, hooks, and/or
MCP servers that users can install into Claude Code.

## Plugins

| Plugin | Skills | Description |
|--------|--------|-------------|
| [`accelerator-core`](plugins/accelerator-core) | `speak-aloud`, `remote-ssh-ops` | Read Claude's output aloud via TTS (incl. Docker→host bridge), and a primitive for safe remote work over SSH. |

## Install (for users)

```bash
# Add this marketplace
claude marketplace add agent-accelerator acefei/agent-accelerator

# Install the plugin
claude plugin install accelerator-core@agent-accelerator

# Verify
claude plugin list
```

Or use the `/plugin` command from inside Claude Code.

## Layout

```
agent-accelerator/
├── .claude-plugin/
│   └── marketplace.json            # marketplace manifest (lists plugins)
└── plugins/
    └── accelerator-core/           # a plugin (bundles multiple skills)
        ├── .claude-plugin/
        │   └── plugin.json         # plugin manifest
        ├── hooks/hooks.json        # hooks (auto-discovered)
        ├── scripts/                # files referenced via ${CLAUDE_PLUGIN_ROOT}
        ├── skills/                 # one dir per skill, each with SKILL.md
        └── README.md
```

A plugin may also contain `commands/` (slash commands), `agents/` (subagents), and a root
`.mcp.json` (MCP servers).

## Add a new plugin

1. Copy an existing plugin dir, e.g. `cp -r plugins/accelerator-core plugins/<your-plugin>`.
2. Edit `plugins/<your-plugin>/.claude-plugin/plugin.json` (`name`, `description`, `version`).
3. Replace its skills/hooks/scripts with your own.
4. Add an entry to the `plugins` array in `.claude-plugin/marketplace.json`.
5. Validate: `claude plugin validate plugins/<your-plugin>/.claude-plugin/plugin.json`.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full contribution guide.

## Manifest gotchas

- `version` is effectively **required** for reliable validation.
- In `plugin.json`, `skills` and `commands` must be **arrays** (e.g. `["./skills/"]`).
- Do **not** declare `agents` or `hooks` in `plugin.json` — they are auto-discovered from
  the `agents/` directory and `hooks/hooks.json`. Declaring them triggers validation errors.
- A root `.mcp.json` is auto-discovered and will try to start its servers on install.
