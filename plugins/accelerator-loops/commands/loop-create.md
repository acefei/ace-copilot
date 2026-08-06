---
description: Interview the user step by step, then scaffold a fully-filled loop from _template/
argument-hint: '[loop-name] ["One-sentence goal"]  (both optional — you will be asked)'
---

Create a new loop in `claude-loops/`, by **interviewing the user first**.

A loop is only as good as its definition. Do **not** dump the template and leave the user to
fill it in: walk them through the design one step at a time, then write `TASK.md`,
`LOOP_INSTRUCTIONS.md` and `PROGRESS.md` already filled in with their answers.

> If you keep `claude-loops/` somewhere other than the project root, use the absolute path to
> your own `claude-loops` directory throughout.

## Parse the arguments — do not trust positional splitting

Both forms must work, and both arguments are optional:

```
/loop-create my-loop "One-sentence goal"
/loop-create my-loop: a goal written as prose, possibly containing URLs and : colons
/loop-create
```

- **name** = the first whitespace-delimited token, with any trailing `:` stripped.
- **goal** = everything after that token, trimmed, with surrounding quotes stripped.

Echo the parsed result back as `name=<name>  goal=<goal>` before anything else. If the name
looks like an ordinary English word (`read`, `the`, `and`, `check`, `new`…) you have almost
certainly mis-parsed — say so and ask, rather than creating a nonsense directory.

## Validate before interviewing — stop if any of these fail

- `claude-loops/_template/` exists. If not, tell the user to run `/setup-loops` first, and stop.
- If a name was given: it is a simple directory name (no `/`, not starting with `.` or `_`),
  and `claude-loops/<name>/` does **not** already exist. Never overwrite an existing loop.

## The interview

Ask **one step at a time** and wait for the answer — never dump all questions at once. Propose
a concrete default for every question (drawn from the goal and what you can see in the
workspace) so the user can just say "yes". Keep your own questions short.

**Step 0 — Should this be a loop at all?** Ask these five, together, as a quick gate:

1. Does this task repeat (weekly or more often)?
2. Can the result be verified — is there a way to reject a bad run?
3. Will Claude have the context it needs (files, logs, tickets, docs)?
4. Is there a clear stop condition? ("keep going until it looks good" is not one.)
5. Is there a safe human review point?

If any answer is **no**, say plainly that a loop is probably the wrong tool, explain which
condition fails, and stop unless the user insists.

**Step 1 — Name and goal.** Confirm the parsed name. Get one paragraph: what this loop is for
and why it exists. If the goal was passed as an argument, read it back and ask only whether it
should be refined.

**Step 2 — Trigger.** What starts a run — manual only for now, a schedule (how often?), or an
event? Recommend manual first, and note that scheduling comes only after several clean runs.

**Step 3 — Context.** What must Claude read at the start of every run? Concrete paths, repos,
docs, tickets. Anything it must *not* read (secrets, private dirs)?

**Step 4 — Action.** What does one iteration actually do? Where does the output go? Settle on
the output filename under `outputs/` now — everything else references it.

**Step 5 — Verification.** This is the step that decides whether the loop works, so push here.
Turn "it looks right" into checks a machine can settle:

| Weak | Strong |
| --- | --- |
| the report looks fine | `outputs/<report>.md` exists |
| the task seems done | every required section is present |
| Claude says it is fixed | `PROGRESS.md` was updated |
| output is probably ready | no forbidden file was modified |

Collect: the required sections of the output file, and the **boundary** — the exact paths this
loop may write to, and what it must never touch. If the user gives a vague criterion, say so
and ask for one that can be checked.

**Step 6 — State.** What must survive between runs so the next one continues instead of
restarting? (Progress, open items, decisions, what the next run should do.)

**Step 7 — Stop and escalate.** When is a single run finished? When should the loop stop
entirely rather than iterate — retry cap, repeated failure, budget, a forbidden path touched?
Who accepts the result: acceptance stays with a human, not the loop.

**Step 8 — Permission level.** Read the ladder and pick one. Default to **Level 1**.

| Level | Claude may |
| --- | --- |
| 1 | read files and write a summary |
| 2 | draft reports/plans/suggestions into `outputs/` |
| 3 | edit files in a sandbox or a draft branch |
| 4 | draft external actions (draft PR, draft message, draft ticket) |
| 5 | apply changes only after explicit approval |
| 6 | act automatically on low-risk tasks, with logging, limits and rollback |

A first loop belongs at **Level 1 or 2**. If the user asks for 3 or higher, say why that is
risky and confirm before continuing.

## Then — confirm, and only then write

Show a compact summary of every answer (name, goal, trigger, context, action, output file,
verification checks, boundary, state, stop conditions, permission level) and ask
*"Create the loop with this? Reply `y`."* **Write nothing until the user replies `y`.**

On `y`:

1. Copy `claude-loops/_template/` to `claude-loops/<name>/`, including `outputs/`.
2. Replace the template placeholders in every `.md`: `<Loop Name>`/`<loop name>` → `<name>`,
   `<report>` → the output filename chosen in Step 4 (without extension).
3. Fill in the interview answers rather than leaving prompts behind:
   - `TASK.md` — Goal (Step 1), Expected Output (Step 4), Scope and the forbidden paths
     (Step 5), Permission Level (Step 8), Stop Condition (Step 7).
   - `LOOP_INSTRUCTIONS.md` — Before You Start (Step 3), What You Should Do (Step 4) with the
     required report sections, State Update Rule (Step 6), Safety Rules (the Step 5 boundary),
     Verification Checklist (Step 5, one PASS/FAIL line per check), Failure Policy (Step 7).
   - `PROGRESS.md` — status "not yet run", the objective, and what the first run should do.
4. Create `claude-loops/<name>/outputs/<report>.md` with a title and the line
   `No loop run has been completed yet.`
5. Confirm no placeholder text (`<Loop Name>`, `<loop name>`, `<report>`, or any
   `<...>` prompt line from the template) survives anywhere in the new directory.

## Report

List the files created and the verification checks the loop will enforce, then:

1. Review `<name>/TASK.md` and `<name>/LOOP_INSTRUCTIONS.md` — they are filled in, not stubs
2. `/loop-run <name>` — run it by hand 3–5 times and read every report
3. `/loop-status` — check its state
4. Only once it is proven, schedule it: `/loop <interval> /loop-run <name>`

Do not run the loop as part of creating it, and do not edit anything outside
`claude-loops/<name>/`.
