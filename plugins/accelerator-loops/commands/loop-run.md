---
description: Run one iteration of a Claude Loop from claude-loops/<name>
argument-hint: '<loop-name>  (e.g. branch-sync)'
---

Run exactly one iteration of the **$1** loop.

Loop directory: `claude-loops/$1/`

> If you keep `claude-loops/` somewhere other than the project root, replace the paths
> below with the absolute path to your own `claude-loops` directory.

## Before acting, read — in this order

1. `claude-loops/$1/TASK.md` — the goal, expected output, scope, permission level
2. `claude-loops/$1/PROGRESS.md` — state from previous runs; continue from it,
   do not restart from zero
3. `claude-loops/$1/LOOP_INSTRUCTIONS.md` — **follow it exactly**

If any of those files is missing, stop and report — do not improvise a loop.

## Then

- Perform the Action described in `LOOP_INSTRUCTIONS.md`.
- Write the report to the `outputs/` file that `LOOP_INSTRUCTIONS.md` names.
- Update `PROGRESS.md` per its State Update Rule (date, trigger, what happened, files
  touched, blockers, what the next run should do, whether human review is needed).
- Run the **Verification Checklist** as a separate pass: return PASS/FAIL per item, no
  partial credit, no assuming a missing section is present.
- Apply the **Failure Policy**: fix a small gap once, escalate anything needing judgement,
  stop if the same check fails twice or a forbidden path was touched.

## Hard boundaries

- Modify only the paths `LOOP_INSTRUCTIONS.md` explicitly allows.
- Respect the loop's permission level; do not climb it on your own.
- Never read or echo secrets (`.env`, keys, tokens) — emit `[REDACTED]` and flag for review.
- If the run is not accepted, say so plainly and mark it in `PROGRESS.md`.

Finish by reporting: action taken, verification result (PASS/FAIL per item), files changed,
and whether human review is required.
