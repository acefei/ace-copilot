# Loop Instructions

You are running the **<loop name>** loop. Run exactly one iteration.

## Before You Start

1. Read `TASK.md`.
2. Read `PROGRESS.md` — this is the state from previous runs. Continue from it; do not
   restart from zero.
3. Inspect the workspace in scope.
4. Identify what changed, what is incomplete, and what needs human review.

## What You Should Do

Write a concise report to `outputs/<report>.md` containing:

- Summary of the current state
- What was reviewed
- Meaningful changes found since the last run
- Blockers or unresolved questions
- Recommended next actions

Then update `PROGRESS.md` (see the State Update Rule below).

## State Update Rule

Before ending **every** run, update `PROGRESS.md` with:

- Date and trigger of this run
- What happened
- What was reviewed
- Which output files changed
- Blockers or unresolved questions
- What the next run should do
- Whether human review is needed

If you cannot update `PROGRESS.md`, stop and report the reason.

Keep `PROGRESS.md` small: current state, open items, decisions, next focus. Do **not** paste
transcripts, full reports, raw logs, or large code blocks into it.

## Safety Rules

- Do not delete, rename, or move files.
- Do not modify source files.
- Only write to `outputs/<report>.md` and `PROGRESS.md`.
- Never read or echo secrets (`.env`, API keys, SSH keys, tokens). If encountered, write
  `[REDACTED]` and flag for human review.
- If unsure whether an action is allowed — stop and ask.

## Verification Checklist

Return **PASS** or **FAIL** per item. No partial credit.

### Required files
- [ ] `outputs/<report>.md` exists
- [ ] `PROGRESS.md` exists

### Required report sections
- [ ] Summary
- [ ] Reviewed
- [ ] Meaningful changes
- [ ] Blockers
- [ ] Recommended next actions

### State update
- [ ] `PROGRESS.md` records date, summary, what was checked, output produced, next run,
      human-review flag

### Safety boundary
- [ ] No files modified outside `outputs/<report>.md` and `PROGRESS.md`

If any item fails, the run is **NOT ACCEPTED**.

## Failure Policy

1. Missing report section → fix the report **once**.
2. `PROGRESS.md` not updated → update it **once**.
3. Forbidden file modified → **stop immediately** and report.
4. Same check fails twice → **stop** and mark the run as needing human review.

## Scheduled Run Policy

- Meaningful changes → concise report.
- No meaningful changes → short "No meaningful changes" note.
- Human review needed → mark clearly in `PROGRESS.md`.
- Same blocker in two consecutive runs → escalate, stop retrying.
