---
description: Delete a Claude Loop directory (asks for confirmation first)
argument-hint: '<loop-name>'
---

Delete the **$1** loop from `claude-loops/`.

> If you keep `claude-loops/` somewhere other than the project root, use the absolute path
> to your own `claude-loops` directory throughout.

Deleting a loop destroys its `PROGRESS.md` — the only durable record of what it has done —
and everything in `outputs/`. This is not recoverable unless the loop is committed to git.

## Refuse outright if

- `$1` is empty — ask which loop, and stop.
- `$1` is `_template` — the template is not a loop and must never be deleted.
- `claude-loops/$1/` does not exist, or has no `PROGRESS.md` — report it and stop rather
  than deleting an unrelated directory.

## Before deleting — show the user what will be lost

1. The loop's **Current State** and **Last Run** from `PROGRESS.md`.
2. The number of files in `outputs/`, and their names.
3. Whether the loop is tracked in git. If it is, say so — the history is recoverable.
   If it is **not** tracked, say plainly that deletion is permanent.
4. Whether anything still points at this loop: check for a scheduled job with `CronList`,
   and warn if one exists — it will keep firing against a loop that no longer exists.

Then ask: *"Delete `$1`? Reply `y` to proceed."*

**Do not delete anything until the user replies `y`.** If they ask for changes or say
anything else, stop.

## On `y`

Delete `claude-loops/$1/` and nothing else. Confirm what was removed, and remind the user
to delete any scheduled job you found with `CronDelete <job-id>`.
