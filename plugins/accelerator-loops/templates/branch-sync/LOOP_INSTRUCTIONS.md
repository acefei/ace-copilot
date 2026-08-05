# Loop Instructions — branch-sync

You are running one iteration of the **branch-sync** loop for `~/workspace/example-app`.

> **Worked example.** Replace the repository path and the three branch names with your own
> before running this loop.

## Before You Start

1. Read `TASK.md` (branch roles and boundaries).
2. Read `PROGRESS.md` (last known SHAs, open items).
3. Fetch the three branches — read-only:

```sh
cd ~/workspace/example-app
git fetch origin main feature/example integration/example
M=$(git rev-parse origin/main)
F=$(git rev-parse origin/feature/example)
P=$(git rev-parse origin/integration/example)
```

## Action — decide from the ancestry, never from a guess

**feature ← integration**

| Condition | Action |
| --- | --- |
| `F == P` | No-op. Already level. |
| `F` is an ancestor of `P` | **Fast-forward:** `git push origin "$P:refs/heads/feature/example"` |
| Diverged (`F` not an ancestor of `P`) | **Do not force.** Report the divergence and escalate to human review. |

**main** — report only:

| Condition | Action |
| --- | --- |
| `M` is an ancestor of `P` | Report how many commits `main` is behind. Leave it alone. |
| `M` has commits not in `P` | Report that a `main` → feature-line merge is needed. Do **not** merge automatically; conflicts need judgement. |

Never push to `main`. Advancing trunk is a release decision.

## What You Should Write

`outputs/branch-sync-report.md` — overwrite each run with:

- Run timestamp and trigger
- The three SHAs (short) and their relationships
- Action taken (fast-forwarded / no-op / escalated)
- `main` drift (commits behind, or commits needing merge)
- Anything requiring human review

Then update `PROGRESS.md` with the run date, the three SHAs, action taken, and what the
next run should watch for.

## Safety Rules

- **Fast-forward only.** Never `--force` / `--force-with-lease`.
- **Never push to `main`.**
- **Never mutate the primary checkout** — no `stash`, `rebase`, `checkout`, `reset`,
  `branch -f`. Only `fetch`, read-only rev queries, and the one FF `push <sha>:<ref>`.
  If a working tree is genuinely needed, use `git worktree add --detach` and remove it after.
- Only write `outputs/branch-sync-report.md` and `PROGRESS.md`.
- Never read or echo secrets. Redact if encountered.

## Verification Checklist

Return **PASS** or **FAIL** per item. No partial credit.

- [ ] All three SHAs were resolved after a successful `fetch`
- [ ] The feature-branch decision matched the ancestry table (no force push occurred)
- [ ] `main` was not pushed to
- [ ] `outputs/branch-sync-report.md` exists and contains: SHAs, action taken, main drift
- [ ] `PROGRESS.md` updated with date, SHAs, action, next-run note
- [ ] No files modified outside those two
- [ ] If `feature` had diverged, the run escalated instead of forcing

If any item fails, the run is **NOT ACCEPTED**.

## Failure Policy

1. `git fetch` fails (network/auth) → report it, make no changes, do not retry more than once.
2. FF push rejected (branch moved mid-run) → re-read SHAs and retry **once**; if it fails
   again, escalate.
3. Divergence detected → **stop and escalate**. Never resolve by forcing.
4. Same blocker in two consecutive runs → stop, mark for human review.

## Scheduled Run Policy

- Level already → one-line "no-op" note; keep the report short.
- Fast-forward applied → record the old and new SHAs.
- Divergence or `main` needing a merge → mark clearly in `PROGRESS.md` under
  **Needs Human Review**.
