# agent-accelerator — agent guide

This repo is a **Claude Code plugin marketplace**: plugins under `plugins/<plugin>/` ship
skills, agents, commands, hooks, and MCP servers. `README.md` advertises every plugin and
its skills; each plugin has its own `README.md`, and each skill documents itself in
`skills/<skill>/SKILL.md`.

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for the per-component *how to add* mechanics.
This file covers the rule those mechanics forget: **keep the docs in sync with the code,
in the same change.**

## Keep docs aligned with components (do this whenever a component changes)

When you **add, rename, remove, or materially change** any component — a skill, agent,
command, hook, MCP server, script, or a whole plugin — update its advertising surface in
the **same** change. A component that exists in code but not in the README (or vice-versa)
is a bug.

1. **Root `README.md`**
   - Update the **Plugins** table (plugin · skills · description).
   - Update the **Layout** tree if files were added or removed.
   - Keep the install commands correct for every installable plugin.
2. **`plugins/<plugin>/README.md`** — update the plugin's own skill table / layout to match.
3. **`skills/<skill>/SKILL.md`** — the `description` frontmatter is what makes Claude
   invoke the skill; keep it accurate and trigger-oriented.
4. **`.claude-plugin/marketplace.json`** — register/unregister plugins; keep the
   marketplace entry `description` in step with the plugin's `plugin.json`.
5. **Bump the version** — edit the `"version"` field by hand in **both**
   `plugins/<plugin>/.claude-plugin/plugin.json` **and** the marketplace `metadata.version`
   in `.claude-plugin/marketplace.json` when releasing. Default to a patch bump; minor for
   a user-visible feature, major for a breaking change.
6. **Validate** — run `claude plugin validate .` before finishing (CI also runs it).

## Manifest rules (validation gotchas)

- `version` is effectively **required** in `plugin.json` and each marketplace entry.
- If you declare `skills`/`commands` in `plugin.json`, they must be **arrays**. You may
  omit them entirely and rely on auto-discovery from `skills/` and `commands/`.
- Do **not** declare `agents` or `hooks` in `plugin.json` — auto-discovered from `agents/`
  and `hooks/hooks.json`; declaring them triggers errors.
- Reference bundled files via `${CLAUDE_PLUGIN_ROOT}` — never hard-code absolute paths.

## Definition of done for a feature change

- [ ] component file(s) created/edited (per CONTRIBUTING)
- [ ] root README Plugins table + Layout tree updated
- [ ] affected `plugins/<plugin>/README.md` updated
- [ ] `marketplace.json` entry consistent with the plugin's `plugin.json`
- [ ] `claude plugin validate .` passes

## Don't

- **Don't** land a component without updating the README surface — silent drift.
- **Don't** commit secrets in `.mcp.json` or hooks — use `${ENV_VAR}` expansion.
- **Don't** invent component types: scripts are payload invoked by a skill/command/hook,
  not a component — they don't get their own README row.
