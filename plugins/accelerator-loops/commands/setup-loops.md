---
description: Initialize a claude-loops/ workspace in this project from the bundled template
argument-hint: "[example]  (add 'example' to also drop the branch-sync sample loop)"
---

Initialize a **Claude Loops** workspace in the current project.

This plugin bundles the loop template under `${CLAUDE_PLUGIN_ROOT}/templates/`. This command
copies it into `./claude-loops/` so the `/accelerator-loops:loop-*` commands have something to
work with. It is **idempotent** — it never overwrites an existing template or loop.

## Validate first — stop if a problem is found

- Confirm `${CLAUDE_PLUGIN_ROOT}/templates/_template/` exists (the bundled template).
- Target the project root's `./claude-loops/`. If the user keeps loops elsewhere, use that
  absolute path throughout instead.

## Then

1. Create `./claude-loops/` if it does not exist.
2. Copy `${CLAUDE_PLUGIN_ROOT}/templates/_template/` → `./claude-loops/_template/`, including
   `outputs/`. **If `./claude-loops/_template/` already exists, leave it untouched** and report
   that it was kept.
3. Only if the argument is `example`: copy `${CLAUDE_PLUGIN_ROOT}/templates/branch-sync/` →
   `./claude-loops/branch-sync/`, and **only if `./claude-loops/branch-sync/` does not already
   exist** — a self-contained sample loop the user can read, run, or delete.
4. Do not modify anything outside `./claude-loops/`.

## Report

- What was created vs. kept (template, and the example if requested).
- Then the next steps:
  1. `/accelerator-loops:loop-create <name> "<goal>"` — scaffold a loop from the template
  2. Edit its `TASK.md` (goal, output, scope, stop condition) and `LOOP_INSTRUCTIONS.md`
     (steps, allowed paths, verification checklist)
  3. `/accelerator-loops:loop-run <name>` — run it by hand 3–5 times and review the output
  4. `/accelerator-loops:loop-status` — check each loop's state
  5. Only once a loop is proven, schedule it: `/loop 1h /accelerator-loops:loop-run <name>`

Commit `./claude-loops/` to git so each loop's `PROGRESS.md` and `outputs/` are durable.
