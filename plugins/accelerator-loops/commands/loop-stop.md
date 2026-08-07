---
description: Unschedule a Claude Loop — cancels its /loop job, keeps the loop folder
argument-hint: '<loop-name>'
---

Stop the **$1** loop from running on a schedule.

> If you keep `claude-loops/` somewhere other than the project root, use the absolute path
> to your own `claude-loops` directory throughout.

This cancels the scheduled `/loop` job(s) that fire this loop. **It does not delete
anything.** `claude-loops/$1/` — its `TASK.md`, `LOOP_INSTRUCTIONS.md`, `PROGRESS.md` and
everything in `outputs/` — is left exactly as it is, so the loop can be re-scheduled later
and pick up from its recorded state. To delete a loop outright, use
`/accelerator-loops:loop-remove` instead.

## Refuse outright if

- `$1` is empty — ask which loop, and stop.
- `$1` is `_template` — the template is not a loop and is never scheduled.

**Do not refuse if the loop directory is missing.** A job firing at a loop that no longer
exists is precisely the case worth stopping. Note that the directory is gone, skip the
`PROGRESS.md` step, and cancel the job anyway.

## 1. Find the scheduled job(s)

Run `CronList`. It lists both durable and session-only jobs, each as
`<job-id> — <schedule> (recurring): <prompt>`.

A job belongs to this loop when its prompt invokes the loop by name — typically
`/loop-run $1` or `/accelerator-loops:loop-run $1`, but it may be an inline prompt that
names `claude-loops/$1` instead. Match on the **whole** name:

- `$1` must appear as a complete token, not as a substring. Stopping `sync` must **not**
  match a job for `branch-sync`. Check the character before and after the match is a
  boundary (space, `/`, quote, end of line) — not a letter, digit, `-` or `_`.

## 2. Report what you found, then act

**No matching job** — say so plainly: the loop is not scheduled, so there is nothing to
stop, and no change was made. Point out that the loop can still be run by hand with
`/accelerator-loops:loop-run $1`. Do not treat this as an error, and do not edit anything.

**Exactly one matching job** — show it (`<job-id>`, schedule, prompt), cancel it with
`CronDelete <job-id>`, and confirm.

**More than one matching job, or a match you are not certain about** — do **not** cancel
anything yet. List every candidate with its id, schedule and full prompt, and ask which to
stop (or `all`). An over-eager match silently disables automation the user is relying on.

## 3. Record the stop in `PROGRESS.md`

Only if `claude-loops/$1/PROGRESS.md` exists, and only after a job was actually cancelled.
This matters: `/accelerator-loops:loop-status` reads `PROGRESS.md`, so without this a
stopped loop keeps reporting itself healthy while nothing runs it — the exact trap that
command warns about.

Make two minimal edits, and nothing else:

- Under `## Current State`, set `- Status:` to note it is unscheduled, preserving the
  existing wording — e.g. `unscheduled 2026-01-15 (was: healthy, steady)`.
- Under `## Open Items`, add one line recording the cancelled job id and schedule, so
  re-scheduling later is a copy-paste.

Do not touch `## Last Run`, `## Needs Human Review`, or any other section — the loop did
not run, and stopping it is not a review request.

## 4. Confirm

Report: the job id(s) cancelled, the schedule they were on, that the loop directory was
**not** touched, and how to start it again:

```
/loop <interval> /accelerator-loops:loop-run $1
```

Finally, note that `CronList` will now show one fewer job, and that any **session-only**
job in another live session is not affected by this — it only disappears when that session
ends.
