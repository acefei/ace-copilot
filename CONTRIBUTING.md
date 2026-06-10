# Contributing to agent-accelerator

This repo is a **Claude Code plugin marketplace**. Each plugin lives under `plugins/<name>/`
and is listed in `.claude-plugin/marketplace.json`. This guide explains how to add or change
a plugin.

## Repository layout

```
agent-accelerator/
├── .claude-plugin/
│   └── marketplace.json        # marketplace manifest — lists every plugin
├── plugins/
│   └── <plugin>/
│       ├── .claude-plugin/
│       │   └── plugin.json     # plugin manifest
│       ├── commands/           # slash commands        (*.md)        — optional
│       ├── agents/             # subagents             (*.md)        — optional, auto-discovered
│       ├── skills/<skill>/SKILL.md   # skills                        — optional, auto-discovered
│       ├── hooks/hooks.json    # hooks                                — optional, auto-discovered
│       ├── scripts/            # files referenced via ${CLAUDE_PLUGIN_ROOT}
│       ├── .mcp.json           # MCP servers                          — optional, auto-discovered
│       └── README.md
├── README.md
└── CONTRIBUTING.md
```

## Add a new plugin

1. **Scaffold** by copying an existing plugin:
   ```bash
   cp -r plugins/accelerator-core plugins/<your-plugin>
   ```
2. **Edit the plugin manifest** `plugins/<your-plugin>/.claude-plugin/plugin.json`:
   set `name` (must match the directory), `description`, and `version`.
3. **Replace the components** (commands / agents / skills / hooks / scripts) with your own.
4. **Register it** in `.claude-plugin/marketplace.json` by adding an entry to `plugins`
   with `name`, `description`, `source` (`./plugins/<your-plugin>`), `version`, and
   `author`.
5. **Validate and test** (below), then open a PR.

## Manifest rules (validation gotchas)

These come from real validator behavior — getting them wrong causes install/validation errors:

- `version` is effectively **required** in both `plugin.json` and each marketplace entry.
- In `plugin.json`, `skills` and `commands` must be **arrays**, even for one entry:
  `"skills": ["./skills/"]`.
- Do **not** declare `agents` or `hooks` in `plugin.json`. They are auto-discovered from
  the `agents/` directory and `hooks/hooks.json`; declaring them triggers errors.
- A root `.mcp.json` is auto-discovered and its servers start on install. Ship it as
  `.mcp.json.example` if you don't want it active by default.
- The plugin's `name` must match its directory name and its marketplace entry `name`.

## Component conventions

| Component | Path | Notes |
|-----------|------|-------|
| Command | `commands/<name>.md` | Frontmatter: `description`, optional `argument-hint`. Invoked as `/<name>`. |
| Agent | `agents/<name>.md` | Frontmatter: `name`, `description`, `tools` (array), `model`. Auto-discovered. |
| Skill | `skills/<name>/SKILL.md` | Frontmatter: `name`, `description`. The `description` decides when Claude uses it — make it trigger-oriented. |
| Hook | `hooks/hooks.json` | Standard Claude Code hooks schema. Auto-loaded. |
| MCP | `.mcp.json` | `{ "mcpServers": { ... } }`. Auto-discovered. |

### `${CLAUDE_PLUGIN_ROOT}`

The harness sets this to the plugin's installed directory. Reference bundled scripts and
assets relative to it — e.g. a hook command of
`${CLAUDE_PLUGIN_ROOT}/scripts/foo.sh`. Never hard-code absolute paths.

## Validate and test

```bash
# Validate JSON manifests
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"
python3 -c "import json; json.load(open('plugins/<your-plugin>/.claude-plugin/plugin.json'))"

# If the Claude CLI is available:
claude plugin validate plugins/<your-plugin>/.claude-plugin/plugin.json

# Lint any scripts you add
bash -n plugins/<your-plugin>/scripts/*.sh
python3 -m py_compile plugins/<your-plugin>/scripts/*.py
```

Then install locally and exercise the plugin:

```bash
claude marketplace add agent-accelerator acefei/agent-accelerator
claude plugin install <your-plugin>@agent-accelerator
```

## Commit & PR conventions

- Use **Conventional Commits**: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`.
  Example: `feat(speak-aloud): add Windows SAPI support`.
- Keep each plugin's changes in focused commits.
- In the PR description, say what the plugin does and how you tested it (commands run,
  environments covered).
- Do not commit secrets, credentials, or machine-specific paths. `__pycache__/`, `*.pyc`,
  and `*.tgz` are git-ignored.
