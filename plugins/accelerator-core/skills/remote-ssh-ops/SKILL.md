---
name: remote-ssh-ops
description: Canonical primitive for working on a REMOTE host over SSH — run commands and edit files on a remote server (e.g. eddie5), not the local filesystem. Use whenever a task runs a remote command or edits/creates remote files. It (1) ensures passwordless key-based SSH, (2) runs remote commands through a LOGIN shell so ~/.bash_profile loads (required for koji-flow's koji_*/af_push and other profile functions), and (3) edits remote files safely (pull -> edit -> verify -> push). Any other skill or workflow (including xs-eng-flow) that needs to run commands or change files on a remote SSH host MUST use this skill instead of ad-hoc ssh/scp/sed.
---

# Remote SSH Ops

One reusable primitive for remote work over SSH: connection, **login-shell command
execution**, and **safe file editing**. Other skills (e.g. `xs-eng-flow`) compose this
instead of re-implementing ssh/scp/profile-loading.

## When to use
- Any time a task runs a command or edits a file on a REMOTE host (eddie5, etc.).
- Before any other skill does remote command/file work — route it through here.

## Phase 1 — Ensure passwordless (key-based) SSH
1. Get the target: `user@host` (+ port). Prefer an existing `~/.ssh/config` alias, or
   the calling workflow's SSH wrapper (see "Respecting an existing wrapper").
2. Test non-interactively:
   ```bash
   ssh -o BatchMode=yes -o ConnectTimeout=5 <user@host> true && echo OK
   ```
   `OK` -> continue.
3. If it fails, set up keys (the copy step needs the remote password once -> ask the
   user to run it; suggest the `!` prefix so it runs in-session):
   ```bash
   [ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
   ssh-copy-id <user@host>
   ```
   Re-test. Key auth only — never store or echo passwords.

### Respecting an existing wrapper
If the calling workflow defines its own SSH wrapper / connection rules (e.g.
`xs-eng-flow`'s `XSFLOW_SSH` with `ControlPath=none`), **use that** — do NOT impose
ControlMaster multiplexing. This skill supplies the method; the caller's connection
settings win.

## Phase 2 — Run remote commands (LOGIN shell!)
koji-flow functions (`koji_*`, `af_push`) and team env live in `~/.bash_profile`, so
they exist only in a **login** shell. Always run remote commands through one:
```bash
ssh <host> 'bash -lc "<command>"'
# e.g.
ssh <host> 'bash -lc "koji_submit"'
```
- A plain `ssh <host> "<command>"` is NOT a login shell -> profile functions are
  missing. Use `bash -lc`.
- Capture stdout+stderr, surface non-zero exit codes, never hide failures.

## Phase 3 — Edit remote files (safe)
1. Pull: `scp <host>:<path> "$TMPDIR/remote-edit"`
2. Edit `$TMPDIR/remote-edit` with the Read/Edit tools.
3. Back up on the remote, then push:
   ```bash
   ssh <host> 'cp -a <path> <path>.bak'
   scp "$TMPDIR/remote-edit" <host>:<path>
   ```
4. Verify: `ssh <host> 'sha256sum <path>'` vs local (or diff). Quick read:
   `ssh <host> 'cat <path>'`.

**Guardrails:** confirm before overwriting/deleting, show a diff before pushing, and never edit a production host without explicit confirmation.
