# Run Summary

Reference for the user-facing summary at the end of a `/memory-doctor` run. Read this file when SKILL.md routes you to it.

## Purpose

Render the user-facing summary, then prompt the keep/undo decision. Aggregates results from the index consolidation and body trimming steps into one tabular report.

## Why this scope

The per-step `ActionResult` records produced by the earlier steps are useful for the run log, but they are not user-facing. This step is the single concise output that:

- Surfaces the headline numbers (files changed, entries consolidated, entries merged, tokens saved).
- Uses tables for scannability.
- Hides per-file noise (which lives in `log.jsonl` inside the snapshot).
- Drives the end-of-run keep/undo decision.

## Inputs

1. `ActionResult` records from index consolidation and body trimming.
2. Snapshot directory path.
3. Total wall-clock duration of the run.

## Token estimation

Bytes divided by 4 is the rough approximation used for English text. Output labels these values as "estimated tokens" and never as exact counts. If a more accurate tokenizer is available in the runtime, prefer that. The bytes/4 heuristic is the fallback when no tokenizer is reachable.

## Output template

Render exactly this structure (substituting actual values):

```
# /memory-doctor - Run Summary

Memory dir:  <absolute path>
Snapshot:    <absolute snapshot path>
Duration:    <seconds>

<optional truncation banner — see Conditional rendering>

## Headline

| Metric                       | Count |
|------------------------------|------:|
| Files changed                |   <n> |
| Index entries consolidated   |   <n> |
| Entries merged               |   <n> |
| Tokens saved (estimated)     |   <n> |

## Index Consolidation (MEMORY.md)

| Operation       | Count |
|-----------------|------:|
| MERGE (high)    |   <n> |
| MERGE (medium)  |   <n> |
| MERGE (low)     |   <n> |
| RENAME          |   <n> |
| DELETE          |   <n> |
| LINK            |   <n> |

## Body Trimming (memory files)

| Operation                | Count |
|--------------------------|------:|
| STRIP_FIELD (forensics)  |   <n> |
| STRIP_FIELD name         |   <n> |
| TRIM_WHY                 |   <n> |
| DROP_WHY                 |   <n> |

## Files

| Status                | Count |
|-----------------------|------:|
| Scanned               |   <n> |
| Modified              |   <n> |
| Unchanged             |   <n> |
| Skipped (parse error) |   <n> |

## Token Savings

| Surface                       | Before | After  | Saved  |
|-------------------------------|-------:|-------:|-------:|
| MEMORY.md (preloaded)         |  <n>   |  <n>   |  <n>   |
| Memory bodies (on-demand)     |  <n>   |  <n>   |  <n>   |
| TOTAL                         |  <n>   |  <n>   |  <n>   |

## Per-Session Impact

- Preloaded saving:  ~<n> tokens per session (every session pays this cost)
- On-demand saving:  ~<n> tokens total (only realised when files load)

## Decision

Reply 'confirm' to commit the changes (snapshot is deleted).
Reply 'undo' to revert all changes (snapshot is restored, then deleted).

Anything else - including questions, partial answers, or "wait, which files were merged?" - leaves the state untouched and re-displays this prompt. The snapshot is only removed after an explicit 'confirm' or 'undo'.

## Footer

Detailed per-file log: <log path inside snapshot>
```

## Conditional rendering

- The Index Consolidation table and the Body Trimming table are always present. Show zero counts explicitly; visibility builds trust.
- **Truncation banner.** If the index consolidation step returned a truncation flag, render a banner immediately below the header and above the Headline table. Two forms:
  - `WARN_NEAR_TRUNCATION` (181-200 lines): `> Note: MEMORY.md is at <N> lines. The harness truncates anything past line 200; you are within <200 - N> lines of the cliff.`
  - `WARN_TRUNCATED` (>200 lines): `> CRITICAL: MEMORY.md is at <N> lines. <N - 200> lines past line 200 are already truncated by the harness and are not visible to Claude. Consolidate aggressively.`
- If preflight failed: this report does not render. The preflight message is the entire output.
- If zero changes were applied across both write steps: render the headline and tables (with zeros), omit the Decision section, and replace the Footer with `No changes detected. Snapshot removed.` (parallel with `Reverted. Snapshot removed.` and `Confirmed. Snapshot removed.` from the confirm/undo path). The orchestration layer deletes the snapshot without prompting.

## Hard rules for this step

- **All counts visible.** Show zero counts explicitly.
- **TOTAL row** in Token Savings is mandatory.
- **No per-file enumeration.** Per-file detail lives in `log.jsonl` inside the snapshot.
- **Estimated tokens are labelled.** Never present an estimate as an exact count.
- **Headline always renders.** A run with no changes still gets a summary so the user knows the run completed.
- **Decision prompt only when changes exist.** Zero-change runs skip the prompt.

## Algorithm sketch

```
1. collect_results() -> {step1, step2, snapshot_path, duration}
2. compute_headline(step1, step2):
     files_changed        = step1.files_modified + step2.files_modified
     entries_consolidated = sum(step1.applied across all ops)
     entries_merged       = step1.applied[MERGE].total
     tokens_saved         = estimate(before_total - after_total)
3. estimate_tokens(byte_count) -> byte_count / 4 (or real tokenizer if available)
4. render_header(memory_dir, snapshot_path, duration)
5. render_headline_table(headline_metrics)
6. render_index_table(step1.actions)
7. render_body_table(step2.actions)
8. render_files_table(step1.files + step2.files)
9. render_tokens_table(step1.surface, step2.surface)
10. render_per_session_impact(preloaded_saved, on_demand_saved)
11. if total_changes > 0:
      render_decision_prompt(snapshot_path)
    else:
      render_zero_change_footer()
12. render_footer(snapshot_path / "log.jsonl")
```
