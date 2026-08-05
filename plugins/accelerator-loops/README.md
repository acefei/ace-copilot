# accelerator-loops

**Claude Loops** — repeatable, verified workflows around the model, driven by slash commands.

An LLM is feed-forward: prompt in → tokens out, with no built-in "steer toward the goal"
across turns. A *loop* wraps a feedback cycle around it so a repeating task (write→test,
sync→report, audit→fix) runs to a **machine-checkable** done-condition instead of drifting.
Each loop is a small directory under `claude-loops/` holding its own task spec, durable
progress log, verification checklist, and outputs.

## Commands

| Command | Does |
|---------|------|
| `/accelerator-loops:setup-loops` | Initialize `claude-loops/` in this project from the bundled template (idempotent; `setup-loops example` also drops a sample loop). |
| `/accelerator-loops:loop-create <name> ["goal"]` | Scaffold a new loop from `claude-loops/_template/`. |
| `/accelerator-loops:loop-run <name>` | Run exactly one iteration: read the loop's `TASK`/`PROGRESS`/`LOOP_INSTRUCTIONS`, act, verify (PASS/FAIL per item), update progress. |
| `/accelerator-loops:loop-status [name]` | Report each loop's state from its `PROGRESS.md` (read-only). |
| `/accelerator-loops:loop-remove <name>` | Delete a loop directory (shows what will be lost, then asks to confirm). |

## Quickstart

```text
/accelerator-loops:setup-loops                       # create claude-loops/ from the template
/accelerator-loops:loop-create sync "keep forks in sync with upstream"
# edit claude-loops/sync/TASK.md and LOOP_INSTRUCTIONS.md
/accelerator-loops:loop-run sync                     # run by hand a few times, review outputs
/accelerator-loops:loop-status                       # check state
/loop 1h /accelerator-loops:loop-run sync            # schedule only once it is proven
```

Commit `claude-loops/` to git — a loop's `PROGRESS.md` is the only durable record of what it
has done, and `loop-remove` warns when a loop is untracked.

## How a loop directory is shaped

```
claude-loops/
├── _template/                 # copied by setup-loops; loop-create clones it
│   ├── TASK.md                # goal, expected output, scope, stop condition
│   ├── LOOP_INSTRUCTIONS.md   # steps, allowed paths, verification checklist, failure policy
│   ├── PROGRESS.md            # durable state carried across runs
│   └── outputs/               # where each run writes its report
└── <your-loop>/               # one dir per loop, same shape
```

## Design notes (why loops don't run away)

- **Machine-decidable done-condition.** A loop lives or dies on whether "is it done?" can be
  judged yes/no by a check — not "make it good". `LOOP_INSTRUCTIONS.md` carries a
  Verification Checklist scored PASS/FAIL per item.
- **Boundaries alongside the goal.** Each loop states what it must *not* touch; `loop-run`
  refuses to modify paths the instructions don't allow.
- **Failure policy + human review.** Fix a small gap once, escalate anything needing judgement,
  stop on a repeated failure. Acceptance and scheduling stay with the human — the loop is the
  worker, not the acceptance officer.

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
