# Consolidate MEMORY.md

Reference for the index-consolidation step of `/memory-doctor`. Read this file when SKILL.md routes you to it.

## Target file

`<memory-dir>/MEMORY.md`. The memory directory is resolved during preflight: `autoMemoryDirectory` from `~/.claude/settings.json` if set, otherwise `~/.claude/projects/<encoded-cwd>/memory/`.

## Why this scope

Claude Code preloads `MEMORY.md` into the system prompt at session start. Lines after 200 are truncated by the harness. Every byte in this file is paid on every session, in every project where auto-memory is active. Individual memory files are out of scope here; they are handled by `references/trim-bodies.md`.

## Inputs

1. The full content of `MEMORY.md` (line count and section structure).
2. The frontmatter `description` field of every linked memory file. Do not read file bodies during this step. Keeps audit cost bounded.
3. The list of files actually present in the memory directory (to detect orphans and stale links).

## Pre-check: 200-line truncation cliff

Before evaluating per-entry rules, count total lines in `MEMORY.md`. The harness silently truncates anything past line 200, so the index has a hard ceiling.

- `total_lines <= 180`: no warning. Proceed.
- `181 <= total_lines <= 200`: emit a `WARN_NEAR_TRUNCATION` flag for the run summary. Detection still proceeds normally; aggressive MERGE is preferred but not forced.
- `total_lines > 200`: emit a `WARN_TRUNCATED` flag with `lines_lost = total_lines - 200`. Lines past 200 are already invisible to Claude. Detection proceeds; the user must be told what is currently being dropped so they can prioritise consolidation.

Both flags are surfaced in the run summary as a banner row above the headline (see `references/run-summary.md`).

## Detection rules

For each entry in the index, evaluate against these six checks:

**1. Duplicates.** Two or more entries whose hooks (the text after the leading bullet) are identical or near-identical after lowercasing and stripping punctuation. Action: `MERGE` with `confidence: high`.

**2. Merge candidates (semantic overlap).** Entries whose linked-file `description` fields describe overlapping concerns (same topic, same initiative, same person, same system). Action: `MERGE` with `confidence: high|medium|low` based on overlap strength.

**3. Stale references.** Entries pointing to files that no longer exist on disk. Action: `DELETE`.

**4. Orphan files.** Files in the memory directory not referenced from `MEMORY.md`. Action: `LINK` with a suggested section and hook drawn from the file's frontmatter `description`.

**5. Verbose hooks.** One-line hooks longer than ~150 characters (the system prompt's stated soft limit). Action: `RENAME` with a tightened version.

**6. Generic / non-disambiguating hooks.** Hooks that fail to differentiate the file from siblings ("notes about the project", "user preferences", etc.). The hook is the only signal Claude uses to decide whether to load the file, so generic hooks defeat the index. Action: `RENAME`.

## Apply rules

Detect and apply in one pass. There are no per-operation confirmations. The snapshot taken at run start is the safety net; the end-of-run keep/undo decision is the user's review point.

Auto-apply (all operations):

- All `RENAME` actions.
- All `DELETE` actions.
- All `LINK` actions.
- All `MERGE` actions regardless of confidence (`high`, `medium`, `low`). Confidence tags are kept as metadata so the user can spot risky merges in the run summary.

## Run log

Append a JSON line per applied action to `<active-snapshot>/log.jsonl` containing: timestamp, action type, MERGE confidence (when applicable), before/after line counts. The log lives inside the active snapshot directory and is deleted with the snapshot at end of run.

## Output

This step does not render output to the user directly. It returns structured `ActionResult` data that feeds the unified run summary (see `references/run-summary.md`).

## Hard rules for this step

- **Snapshot before any write.** Do not run before the orchestration layer's snapshot step succeeded.
- **Frontmatter only during detection.** Do not read memory file bodies. The `description` field is sufficient.
- **Confidence tagged on MERGE.** Every merge is tagged `high`, `medium`, or `low`. All apply automatically; the tag is surfaced in the run summary for user review.
- **Preserve section taxonomy.** Section headers (User / Feedback / Project / Reference) are part of the contract Claude Code expects. Do not propose removing or renaming them.
- **Refuse on parse failure of MEMORY.md.** Abort the run and roll back from snapshot. Frontmatter parse failures on individual memory files only skip that file.

## Algorithm sketch

```
1. resolve_index_path() -> path
2. parse_index(path) -> {sections, total_lines}
3. truncation_flag = check_truncation(total_lines)   # none | WARN_NEAR_TRUNCATION | WARN_TRUNCATED
4. list_dir(path.parent) -> files_on_disk
5. for each entry: read_frontmatter(entry.file) -> {description}
6. actions = []
   actions += detect_duplicates(entries)             # MERGE high
   actions += detect_semantic_overlap(descriptions)  # MERGE high|medium|low
   actions += detect_stale(entries, files_on_disk)   # DELETE
   actions += detect_orphans(entries, files_on_disk) # LINK
   actions += detect_verbose_hooks(entries)          # RENAME
   actions += detect_generic_hooks(entries)          # RENAME
7. for action in actions:
     apply(action) -> updates new_index
8. write_atomic(path, new_index)
9. append_log(applied_actions, before_lines, after_lines)
10. return ActionResult(applied, before_bytes, after_bytes, truncation_flag, lines_lost)
```
