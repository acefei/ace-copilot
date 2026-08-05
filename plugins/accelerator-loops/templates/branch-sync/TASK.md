# Branch Sync Loop — example

> **Worked example.** The repository path and the three branch names below are
> placeholders. Point them at your own repo and branches before running this loop.

## Goal

Keep a branch line consistent: propagate merged work from the integration branch
`integration/example` to the shared `feature/example`, and report (never silently change)
how far `main` has drifted.

Repo: `~/workspace/example-app` (remote `origin` → `your-org/example-app`).

## Branch roles

| Branch | Role |
| --- | --- |
| `integration/example` | **Integration branch.** PRs merge here first. Source of truth for the feature line. |
| `feature/example` | **Shared feature branch.** Should track the integration branch. |
| `main` | **Trunk.** Advanced only by a deliberate, human-decided release. |

## Expected Output

Each run should produce or update:

- `outputs/branch-sync-report.md`
- `PROGRESS.md`

## Scope

Allowed:

- `git fetch` the three branches (read-only)
- **Fast-forward only** push of `integration/example` → `feature/example`
- Write the report and progress files

Forbidden:

- Any push to `main`
- Any force-push (`--force`, `--force-with-lease`) to any branch
- Any mutation of the primary checkout (no `stash`, `rebase`, `checkout`, `reset`,
  `branch -f`) — concurrent sessions may share this repo
- Merging PRs, editing source files

## Permission Level

**Level 3, deliberately narrow** — one specific fast-forward push, nothing else.
Everything about `main` is Level 1 (report only).

## Stop Condition

A run ends once the branches are level (or the FF has been applied) and the report plus
`PROGRESS.md` are written. The loop escalates instead of acting when `feature/example`
has diverged.
