# <Loop Name>

## Goal

<One paragraph: what this loop is for and why it exists.>

## Expected Output

Each run should produce or update:

- `outputs/<report>.md`
- `PROGRESS.md`

## Scope

Claude may inspect files in this workspace and write reports to the `outputs/` folder.

Claude must **not** modify source files, delete files, rename files, or move files in this
version of the loop.

## Permission Level

**Level 1 (read-only analysis)** — see the ladder in `../README.md`.

Raise only after several clean, reviewed runs.

## Stop Condition

<When is a run finished? When should the loop stop entirely rather than iterate?>
