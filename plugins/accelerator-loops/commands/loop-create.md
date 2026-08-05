---
description: Scaffold a new Claude Loop from _template/
argument-hint: '<loop-name> ["One-sentence goal"]'
---

Create a new loop named **$1** in the `claude-loops/` directory.

> If you keep `claude-loops/` somewhere other than the project root, use the absolute path
> to your own `claude-loops` directory throughout.

## Validate first — stop if any of these fail

- A name was given. If `$1` is empty, ask for one and stop.
- The name is a simple directory name: no `/`, and it does not start with `.` or `_`.
- `claude-loops/$1/` does **not** already exist. Never overwrite an existing loop —
  report it and stop.
- `claude-loops/_template/` exists.

## Then

1. Copy `claude-loops/_template/` to `claude-loops/$1/`, including `outputs/`.
2. In every `.md` file in the new directory, replace the template placeholders:
   - `<Loop Name>` and `<loop name>` → `$1`
   - `<report>` → `$1` lowercased, with `-report` appended
3. If a goal was given as the second argument, replace the placeholder line
   `<One paragraph: what this loop is for and why it exists.>` in `TASK.md` with it.
4. Create `claude-loops/$1/outputs/<report>.md` containing a title and the line
   `No loop run has been completed yet.`
5. Confirm no placeholder text (`<Loop Name>`, `<loop name>`, `<report>`) survives
   anywhere in the new directory.

## Report

List the files created, then the next steps:

1. Edit `$1/TASK.md` — goal, expected output, scope, stop condition
2. Edit `$1/LOOP_INSTRUCTIONS.md` — steps, allowed paths, verification checklist
3. `/accelerator-loops:loop-run $1` — run it by hand 3–5 times and review the output
4. Only then schedule: `/loop 1h /accelerator-loops:loop-run $1`

Do not run the loop as part of creating it, and do not edit anything outside
`claude-loops/$1/`.
