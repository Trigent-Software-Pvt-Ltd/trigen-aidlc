# Trim memory file bodies

Reference for the body-trimming step of `/memory-doctor`. Read this file when SKILL.md routes you to it.

## Target files

Every `*.md` file in `<memory-dir>` except `MEMORY.md`. The memory directory is resolved during preflight: `autoMemoryDirectory` from `~/.claude/settings.json` if set, otherwise `~/.claude/projects/<encoded-cwd>/memory/`.

## Why this scope

Index consolidation operates on `MEMORY.md` (preloaded into every session). This step operates on the individual memory files referenced by `MEMORY.md`. These files are loaded on demand via the `Read` tool when their index hook looks relevant.

Savings here are second-order: they only reduce tokens when a file is actually pulled. But across many sessions across many files, the aggregate is real, and the noise also dilutes the signal Claude actually uses.

The goal: keep what drives Claude's behavior (the rule, the principle behind it, the operational triggers) and strip what does not (dated provenance, session IDs, redundant restated names).

## Inputs

1. The full content of every memory file (frontmatter and body). This step explicitly reads bodies, unlike index consolidation.
2. The documented frontmatter contract: `name`, `description`, `type`. Any field outside this contract can be flagged.

## Detection rules

**1. Forensics-only frontmatter fields.** Frontmatter fields outside the documented contract that have no behavioral use, only forensic value.

Hard list (always strip):
- `originSessionId`

Soft list (strip if present and unused):
- `sessionId`, `conversationId`, `runId`
- `createdAt`, `updatedAt`, `timestamp`

Action: `STRIP_FIELD <fieldname>`.

**2. Redundant `name` field.** The `name` frontmatter field when it conveys the same information as `description`.

Classification:
- **Exact match** after normalisation (lowercase, punctuation stripped, whitespace collapsed): clearly redundant.
- **Paraphrase** (substring, near-restatement, same nouns and verbs in different order): probably redundant.
- **Distinct** (different framing or content): keep both.

Action: `STRIP_FIELD name` on both exact match and paraphrase. Distinct: no action.

**3. Provenance noise in `**Why:**`.** Patterns inside the `**Why:**` body line that are pure provenance and do not aid edge-case judgment:

- Date references: "on 2026-05-01", "yesterday", "last week", "during session <id>".
- Person attribution: "Michael said", "Michael explicitly corrected", "Michael told me".
- Reinforcement counts: "hooks have surfaced repeatedly", "this came up N times".
- Quoted transcripts: direct quotations of past user turns.

The principle that supports edge-case judgment must be preserved. If after stripping provenance the remaining text states a useful principle, keep that. If only provenance was present, the Why becomes empty and falls to rule 4.

Action: `TRIM_WHY`.

**4. Trivial `**Why:**`.** After `TRIM_WHY`, the Why line:
- Is empty, or
- Is fewer than 10 words and trivially restates the rule, or
- Adds no information beyond the rule itself.

Action: `DROP_WHY` (remove the entire `**Why:**` line).

## Apply rules

Detect and apply in one pass. There are no per-operation confirmations. The snapshot is the safety net; the end-of-run keep/undo decision is the user's review point.

Auto-apply (all operations):
- All `STRIP_FIELD` actions (hard list, soft list, and `name` regardless of match strength).
- All `TRIM_WHY` actions.
- All `DROP_WHY` actions.

## Run log

Append a JSON line per file processed to `<active-snapshot>/log.jsonl` containing: timestamp, file path, applied actions, before/after byte counts. The log lives inside the active snapshot directory and is deleted with the snapshot at end of run.

## Output

This step does not render output to the user directly. It returns structured `ActionResult` data that feeds the unified run summary (see `references/run-summary.md`).

## Hard rules for this step

- **Snapshot before any write.** Do not run before the orchestration layer's snapshot step succeeded.
- **Never alter the rule line.** The first body line under the frontmatter is the rule itself. Verbatim, always.
- **Never strip `description` or `type`.** Both are part of the documented contract. `description` drives the index load decision; `type` drives interpretation.
- **Never alter `**How to apply:**` content.** Out of scope.
- **Refuse on parse failure of an individual file.** Log it and skip the file. Do not partially apply changes to that file. Continue with remaining files.

## Algorithm sketch

```
1. resolve_memory_dir() -> dir
2. files = list(dir, exclude=MEMORY.md)
3. for each file in files:
     content = read(file)
     try:
         fm, body = split_frontmatter(content)
     except ParseError:
         log_skip(file, "parse_error")
         continue
     actions = []
     actions += detect_forensics_fields(fm)         # STRIP_FIELD
     actions += detect_redundant_name(fm)           # STRIP_FIELD name
     actions += detect_why_provenance(body)         # TRIM_WHY
     actions += detect_trivial_why(body, actions)   # DROP_WHY (depends on TRIM result)
     for action in actions:
         apply(action) -> update fm/body
     new_content = recompose(fm, body)
     if new_content != content:
         write_atomic(file, new_content)
         log_applied(file, actions, before_bytes, after_bytes)
4. return ActionResult(files_modified, before_bytes_total, after_bytes_total)
```
