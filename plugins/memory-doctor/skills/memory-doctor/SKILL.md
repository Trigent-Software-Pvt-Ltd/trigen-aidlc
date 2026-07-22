---
name: memory-doctor
description: Consolidate Claude Code auto-memory storage in one pass. Shrinks the preloaded MEMORY.md index (paid every session), trims individual memory file bodies (paid when loaded on demand), and reports token savings with a single end-of-run keep/undo decision. Use whenever the user mentions memory consolidation, MEMORY.md cleanup, auto-memory bloat, "compact my memory", "audit my memory", "clean up MEMORY.md", "trim memory files", or asks why their session context feels heavy or why memory files are noisy. Also use when they say /memory-doctor, "run memory-doctor", or "doctor my memory" even without explicit naming.
---

# memory-doctor

Single-command skill that audits and consolidates Claude Code auto-memory storage to lower per-session token cost.

## What this skill does

Claude Code maintains an auto-memory system. `MEMORY.md` is preloaded into the system prompt at session start, so every byte costs tokens on every session in every project where auto-memory is active. Individual memory files (`user_*.md`, `feedback_*.md`, `project_*.md`, `reference_*.md`) load on demand via the `Read` tool when their index hook looks relevant; their bodies cost tokens only when pulled, but noise dilutes the signal Claude actually uses to decide whether to load them.

This skill runs three execution phases in one pass, with one snapshot taken before any write:

1. **Consolidate `MEMORY.md`.** Detection rules and apply rules live in `{{SKILL_DIR}}/../../references/consolidate-index.md`.
2. **Trim memory file bodies.** Detection rules and apply rules live in `{{SKILL_DIR}}/../../references/trim-bodies.md`.
3. **Render run summary and prompt the keep/undo decision.** Output template, conditional rendering, and hard rules live in `{{SKILL_DIR}}/../../references/run-summary.md`.

The snapshot is ephemeral: it is deleted at end of run regardless of decision (after restoring on undo, after no-op on keep).

## Command surface

`/memory-doctor` is the only command. No sub-commands. No flags.

## When the skill triggers

The user typed `/memory-doctor`, or asked for memory cleanup, MEMORY.md consolidation, auto-memory audit, or token bloat investigation. If the user asks an exploratory question ("what's in my memory?", "should I clean this up?"), explain what `/memory-doctor` does and offer to run it; do not run automatically without an instruction.

## End-to-end flow

Execute these steps in order. Do not parallelise.

### Step 0: Cleanup any abandoned snapshot

If `~/.claude/backups/memory-doctor/<timestamp>/` exists from a previous run that ended without a keep/undo decision, delete it. Snapshots are ephemeral and never persist across runs.

### Step 1: Preflight

Resolve the memory directory:
- If `~/.claude/settings.json` has `autoMemoryDirectory` set, use that path.
- Otherwise use `~/.claude/projects/<encoded-cwd>/memory/`, where `<encoded-cwd>` is the cwd path with each `/` replaced by `-`. The path retains its leading `-` because cwd starts with `/`, and any other characters (including `.`) pass through unchanged. Example: cwd `/Users/alice/projects/foo` becomes `-Users-alice-projects-foo`. A dotfile cwd `/Users/alice/.config` becomes `-Users-alice-.config`.

Verify the directory exists and contains at least one `*.md` file.

If preflight fails, exit cleanly with this exact message (substituting the resolved path and reason):

```
/memory-doctor cannot run.

Reason: <one of>
- No memory directory found at <resolved path>
- Memory directory is empty (no .md files)
- autoMemoryDirectory points to <path> which does not exist

Auto-memory may not be enabled, or no memories have been written yet.

To enable auto-memory:
  1. In ~/.claude/settings.json, set "autoMemoryEnabled": true
  2. Optionally set "autoMemoryDirectory" to a custom path
  3. Restart Claude Code; memories accumulate as you work
```

No further work after a failed preflight.

### Step 2: Snapshot

Copy the entire memory directory to:

```
~/.claude/backups/memory-doctor/<ISO-timestamp>/    (e.g., 2026-05-06T103000Z — basic ISO-8601, no colons)
```

If snapshot creation fails, abort the run with a diagnostic. No further work attempted. One snapshot covers all subsequent writes.

### Step 3: Consolidate MEMORY.md

Read `{{SKILL_DIR}}/../../references/consolidate-index.md` and execute it. All operations auto-apply.

### Step 4: Trim memory file bodies

Read `{{SKILL_DIR}}/../../references/trim-bodies.md` and execute it. All operations auto-apply.

### Step 5: Render run summary and prompt

Read `{{SKILL_DIR}}/../../references/run-summary.md` and render the output template. Present the keep/undo decision (unless zero changes were applied; see zero-change short-circuit below).

### Step 6: Decision handling

Wait for the user's reply.

- If reply is **'undo'** (case-insensitive, leading/trailing whitespace ignored): restore the memory directory from the snapshot, then delete the snapshot. Confirm with: `Reverted. Snapshot removed.`
- If reply is **'confirm'** (case-insensitive, whitespace ignored): delete the snapshot. Confirm with: `Confirmed. Snapshot removed.`
- Any other reply, including questions, partial answers, or anything ambiguous: do not modify state. Re-render the Decision section verbatim and wait again. The snapshot stays intact so the user can ask follow-up questions before deciding.
- No reply (session ends without response): the snapshot persists until the next run, which deletes it in Step 0.

### Zero-change short-circuit

If both Step 3 and Step 4 produce zero applied actions, skip the Decision prompt. Render the summary with zeros and delete the snapshot automatically with one line: `No changes detected. Snapshot removed.`

## Snapshot lifecycle

| Phase                                     | Snapshot state                                                 |
|-------------------------------------------|----------------------------------------------------------------|
| Run start (after Step 0 cleanup)          | Created                                                        |
| Steps 3 and 4 (writes)                    | Active, rollback target on write failure                       |
| Step 5 prompt rendered                    | Active, awaiting decision                                      |
| User replies 'undo'                       | Restore from snapshot, then delete snapshot                    |
| User replies 'confirm'                    | Delete snapshot                                                |
| User replies anything else (questions, ambiguous answers) | No state change; re-render Decision and wait again |
| User abandons (no reply, session ends)    | Persists until next run                                        |
| Next run starts                           | Step 0 deletes prior snapshot before snapshotting again        |
| Zero changes detected                     | Auto-deleted by orchestration, no prompt                       |

The snapshot is never kept long-term. There is no historical backup. If long-term recoverability is needed, the user should rely on git or a separate backup tool.

## Shared concerns

### Atomic writes

Every file modification goes through tempfile + Bash `mv` (atomic on POSIX filesystems): write the new content to `<target>.tmp.<pid>` via the Write tool, then `mv` over the target via Bash. Partial writes never appear on disk because the rename is atomic. The Write tool is not used directly against the target file; doing so would not preserve atomicity if the runtime is interrupted mid-write.

### Run log location

A single `log.jsonl` lives inside the active snapshot directory at `<snapshot>/log.jsonl`. Both consolidation and body trimming append per-action entries. Deleted with the snapshot at run end.

### Error handling

- **Parse error in an individual memory file:** log to `log.jsonl`, skip the file, continue. Counted as `Skipped (parse error)` in the summary.
- **Parse error in MEMORY.md:** abort the run, roll back from snapshot, surface the error to the user.
- **Write failure during consolidation or body trimming:** abort the run, restore the memory directory from snapshot automatically, surface the error to the user. Snapshot is then deleted.
- **Snapshot creation failure:** abort before any modification. Surface the error.
- **Tokenizer unavailable:** use the bytes/4 heuristic and label outputs "estimated tokens". See `{{SKILL_DIR}}/../../references/run-summary.md` for the contract.

## Hard rules (skill-wide)

- **One command, one flow.** No sub-commands, no flags.
- **No per-operation confirmations.** The user's review point is the end-of-run keep/undo decision.
- **Snapshot before any write to the memory directory.** No exceptions.
- **Snapshot ephemeral.** Created at run start, deleted at run end (or restored-and-deleted on undo). Persists across abandoned runs only until the next run starts.
- **Atomic writes.** Every file write goes through tempfile + rename.
- **Refuse on parse failure of MEMORY.md.** Abort the run and roll back. Frontmatter parse failures on individual memory files only skip that file.
- **Honour `autoMemoryDirectory`.** Always read this from `~/.claude/settings.json` first. Fall back to the default encoded-cwd path only if unset.
