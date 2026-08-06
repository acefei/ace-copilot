# accelerator-loops

**Claude Loops** — repeatable, verified workflows around the model, driven by slash commands.

An LLM is feed-forward: prompt in → tokens out, with no built-in "steer toward the goal" across
turns. A *loop* wraps a feedback cycle around it so a repeating task (review→report,
sync→verify, audit→fix) runs to a **machine-checkable** done-condition instead of drifting.

> The better abstraction for repetitive work isn't a better prompt — it's a loop.
> A prompt answers once; a loop defines the operating structure: **what triggers a run, what
> Claude reads, what it may do, how the output is verified, where state lives, and when it
> stops, repeats, or escalates to a human.**

## Commands

| Command | Does |
|---------|------|
| `/accelerator-loops:setup-loops` | Initialize `claude-loops/` in this project from the bundled template (idempotent; `setup-loops example` also drops a sample loop). |
| `/accelerator-loops:loop-create [name] ["goal"]` | **Interviews you step by step** — gate, goal, trigger, context, action, verification, state, stop condition, permission level — then scaffolds a loop from `claude-loops/_template/` with every file filled in. |
| `/accelerator-loops:loop-run <name>` | Run exactly one iteration: read the loop's `TASK`/`PROGRESS`/`LOOP_INSTRUCTIONS`, act, verify (PASS/FAIL per item), update progress. |
| `/accelerator-loops:loop-status [name]` | Report each loop's state from its `PROGRESS.md` (read-only). |
| `/accelerator-loops:loop-remove <name>` | Delete a loop directory (shows what will be lost, then asks to confirm). |

## Quickstart

```text
/accelerator-loops:setup-loops                       # create claude-loops/ from the template
/accelerator-loops:loop-create sync "keep forks in sync with upstream"
# answer the interview; review claude-loops/sync/TASK.md + LOOP_INSTRUCTIONS.md
/accelerator-loops:loop-run sync                     # run by hand a few times, read every report
/accelerator-loops:loop-status                       # check state
/loop 1h /accelerator-loops:loop-run sync            # schedule only once it is proven
```

---

# Tutorial: building your first loop

## 1. The six parts of a loop

Every loop — however simple — has these six. If you can't name all six, you don't have a loop
yet, you have a prompt on a timer.

| Part | What it is |
|------|------------|
| **Trigger** | What starts a run: a manual command, a schedule, a file change, a CI failure. |
| **Context** | What Claude reads first: the task definition, the relevant files, prior progress. |
| **Action** | What one iteration actually does: write a report, draft a fix, classify failures. |
| **Verification** | The check that decides whether the run is acceptable: a checklist, a test suite, a linter, a schema. |
| **State update** | What happened, what changed, what failed, what the next run should do. |
| **Decision** | Stop, ask a human, or run again. |

**Claude sessions are ephemeral.** If a loop is to continue across runs it needs durable state
outside the conversation — here, `PROGRESS.md`.

## 2. Should this be a loop at all?

Ask five questions before building anything. `loop-create` asks them for you, and refuses to
scaffold if one fails.

1. **Does the task repeat?** If it isn't recurring, the setup cost isn't worth it.
2. **Can the result be verified?** You need a way to *reject* a bad run.
3. **Will Claude have enough context?** Files, logs, tickets, docs must be reachable.
4. **Is there a clear stop condition?** "Keep going until it looks good" is not one.
5. **Is there a safe review point?** Anything that can modify files needs a human checkpoint.

**Good first loops** — daily project review; extracting action items from meeting notes;
drafting a cleanup plan for a messy folder (*planning* the moves, not making them).

**Bad first loops** — "rewrite the backend architecture"; "improve the product direction each
week"; "keep editing auth and payment code until the issues are gone"; "deploy to production
when Claude thinks it's ready".

## 3. Start low on the permission ladder

Don't begin at full autonomy. Each loop declares a level in its `TASK.md`.

| Level | Claude may |
|-------|------------|
| **1** | read files and write a summary |
| **2** | draft reports, plans, or suggested changes into `outputs/` |
| **3** | edit files inside a sandbox or a draft branch |
| **4** | draft external actions (draft PR, draft message, draft ticket) |
| **5** | apply changes only after explicit approval |
| **6** | act automatically on low-risk tasks, with logging, limits, and rollback |

**A first loop belongs at Level 1 or 2.** Raise it only after several clean, reviewed runs.

## 4. Anatomy of a loop

Four roles kept in separate files — that separation is what makes a loop resumable.

```
claude-loops/
├── _template/                 # copied by setup-loops; loop-create clones it
└── <your-loop>/
    ├── TASK.md                # WHAT it's for — goal, expected output, scope, permission, stop condition
    ├── LOOP_INSTRUCTIONS.md   # HOW one iteration runs — steps, boundaries, checklist, failure policy
    ├── PROGRESS.md            # STATE between runs — last run, open items, next run, review flag
    └── outputs/               # WHAT it produced — reports and drafts, never source edits
```

## 5. Verification: separate the worker from the checker

This is the step that decides whether a loop is useful or just expensive. Run verification as a
**separate pass** after the work, and score it PASS/FAIL per item — no partial credit.

| Weak done-criterion | Strong done-criterion |
|---|---|
| the report looks fine | `outputs/<report>.md` exists |
| the task seems complete | every required section is present |
| Claude says it's fixed | `PROGRESS.md` was updated |
| output is probably ready | no forbidden file was modified |

A checklist a machine can settle looks like this:

```markdown
## Verification Checklist
### Required files
- [ ] `outputs/daily-review.md` exists
- [ ] `PROGRESS.md` exists
### Required report sections
- [ ] Summary   - [ ] Reviewed   - [ ] Meaningful changes
- [ ] Blockers  - [ ] Recommended next actions
### State update
- [ ] `PROGRESS.md` records date, what happened, output produced, next run, human-review flag
### Safety boundary
- [ ] No files modified outside `outputs/…` and `PROGRESS.md`
```

Two rules that keep this honest: **the checker must not grade its own work loosely** (deterministic
rules, never "looks right"), and **the loop may not weaken its own acceptance criteria to pass**.

## 6. When verification fails

| Strategy | Use when |
|---|---|
| **Retry** | the failure is small, clear, and safely fixable |
| **Escalate** | the failure needs human judgement or touches a risky area |
| **Stop** | an iteration cap, a permission boundary, or a budget limit is hit |

Write it down as an explicit policy — e.g. *fix a missing report section once; stop immediately
if a forbidden path was touched; if the same check fails twice, stop and flag for review.*

## 7. Walkthrough

```text
/accelerator-loops:setup-loops
```

Creates `claude-loops/` with the template. Then:

```text
/accelerator-loops:loop-create daily-review "summarize what changed in this project each day"
```

Answer the interview — the gate questions, then trigger, context, action and output filename,
verification checks and write boundary, state, stop conditions, and permission level. Confirm,
and the command writes `TASK.md`, `LOOP_INSTRUCTIONS.md` and `PROGRESS.md` **already filled in**.

Run it by hand and read the output — every time, for the first few runs:

```text
/accelerator-loops:loop-run daily-review
/accelerator-loops:loop-status
```

## 8. Scheduling

`/loop` re-enqueues a **prompt** on an interval, so the prompt is what points at the loop:

```text
/accelerator-loops:loop-run daily-review          # once, by hand
/loop 1d /accelerator-loops:loop-run daily-review # daily
```

Because each tick re-invokes `loop-run`, which re-reads the loop's Markdown, editing the loop
takes effect on the next run — no rescheduling needed.

Use `/loop <interval> <prompt>` when the next run should happen **because time passed**, and
`/goal <condition>` when work should continue **because a condition isn't met yet**.

**Ramp deliberately:** run by hand → a short interval while you watch → the real cadence,
reading every output for the first week. A scheduled loop needs a stop policy: no meaningful
change gives a short note, the same blocker twice escalates, two failed verifications stop it.

## 9. Keep judgement with the human

The loop is the worker, not the acceptance officer. Acceptance, sign-off, and anything whose
failure you can't afford — merging, publishing, spending — stay with a person. Counter-intuitively,
the more self-directed a loop is, the **stricter** the review it needs, and that review has to sit
*before* the action, not as a post-hoc patch.

Commit `claude-loops/` to git — a loop's `PROGRESS.md` is the only durable record of what it has
done, and `loop-remove` warns when a loop is untracked.

---

## Layout

```
accelerator-loops/
├── .claude-plugin/plugin.json
├── commands/                  # setup-loops, loop-create, loop-run, loop-status, loop-remove
├── templates/                 # bundled scaffolding copied by setup-loops (${CLAUDE_PLUGIN_ROOT})
│   ├── _template/
│   └── branch-sync/           # sample loop (installed by `setup-loops example`)
└── README.md
```
