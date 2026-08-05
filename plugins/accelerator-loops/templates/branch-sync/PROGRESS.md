# Loop Progress — branch-sync

> **Worked example.** The state below is illustrative sample data, showing the shape a
> real `PROGRESS.md` takes after a few dozen runs. Reset it before using this loop.

## Current State
- Status: healthy, steady (no-op for many consecutive runs)
- Main objective: keep `feature/example` level with `integration/example`; report `main` drift
- Current focus: watch for new merges into the integration branch
- Last updated: 2026-01-15

## Last Run
- Date: 2026-01-15
- Trigger: `/loop` (job `<job-id>`, every 10 min, session-only, 7-day expiry)
- Summary: branches already level — no action taken (~24th consecutive no-op run)
- SHAs: `main=9d8c7b6` · `feature=a1b2c3d` · `integration=a1b2c3d`
- Action: no-op (`feature == integration`)
- Cadence note: no branch has moved since the last fast-forward. A 10-minute interval is
  far tighter than the change rate — widening to hourly is recommended.
- Output produced: `outputs/branch-sync-report.md`

## Known Good Baseline
- `feature/example` was fast-forwarded `4c5d6e7 → a1b2c3d` on 2026-01-15, propagating the
  five most recently merged PRs.
- `main` has been 29 commits behind the feature line since then, and fully contained in it
  (no `main` → feature-line merge needed).

## Open Items
- `main` is 29 commits behind `integration/example`. Advancing trunk is a deliberate
  release decision — out of scope for this loop, tracked here for visibility.

## Blockers
- None.

## Needs Human Review
- None currently. Escalate here if `feature/example` ever diverges (gains its own
  commits) — the loop will refuse to force-push and will stop.

## Next Run Should
- Fetch and compare the three SHAs.
- Fast-forward `feature` if the integration branch has advanced (e.g. after a new PR merge).
- Keep the report to a one-line no-op if nothing changed.

## Decisions Made
- 2026-01-15: FF-only propagation, never force-push.
- 2026-01-15: never auto-advance `main`; report drift only.
- 2026-01-15: never mutate the primary checkout — concurrent sessions may share this repo.

## Do Not Repeat
- Do not attempt to "fix" divergence by force-pushing `feature/example`.
- Do not merge `main` automatically; conflicts require human judgement.
