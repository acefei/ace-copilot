---
description: Show the state of Claude Loops (reads each loop's PROGRESS.md)
argument-hint: '[loop-name]   (omit for a table of every loop)'
---

Report the state of the loops in `claude-loops/`.

> If you keep `claude-loops/` somewhere other than the project root, use the absolute path
> to your own `claude-loops` directory throughout.

A loop is any directory in `claude-loops/` that contains a `PROGRESS.md`. Skip
`_template/`. This is read-only — do not modify any file.

## If a name was given ($1 is not empty)

Read `claude-loops/$1/PROGRESS.md` and show, in this order:

- **Current State** and **Last Run** sections, verbatim
- **Needs Human Review** — call it out clearly if it is anything other than "none"
- **Next Run Should**
- **Outputs** — the files in `claude-loops/$1/outputs/`, newest first, with modified times

If the directory or its `PROGRESS.md` is missing, say so and stop — do not invent state.

## If no name was given

One row per loop:

| Loop | Status | Last run | Review? |
| --- | --- | --- | --- |

- **Status** — the `- Status:` line under `## Current State`
- **Last run** — the `- Date:` line under `## Last Run`, or `—` if never run
- **Review?** — `no` if **Needs Human Review** is empty or says "none", otherwise **YES**

Sort loops that need review to the top. If there are no loops yet, say so and suggest
`/accelerator-loops:loop-create <name>`.

## Always finish with

- A one-line read of the overall picture — which loops are healthy, which are stale
  (an old `Last run`), which need a human.
- A reminder that this only covers the loops' own state. The **scheduler** is separate:
  run `CronList` to see which `/loop` jobs are actually queued. A loop can look healthy
  here while nothing is scheduled to run it.
