# Token Economics

Every agent turn has a cost: context is re-billed, reasoning costs more, slow model choices add up.
Spend expensive tokens on **judgment** (planning, design, review); use cheaper, faster models for
routine implementation. This is basic engineering judgment applied to the agent, and it pairs with the
per-role model selection already in `execution-rigor.md` §4.

## Right model, right task

- **Plan / architect / review with frontier models** (e.g. Opus, GPT-class); **implement with
  cost-efficient models** once the plan is approved.
- Match **reasoning effort** to the task: low/medium for routine edits, high/max for hard design and
  deep reviews. Don't burn max-effort on a one-line change.
- This maps onto the **ceremony gears**: Quick leans cheap end-to-end; Deep spends on the architect,
  critic, expert perspectives, and the most-capable final review.

## Keep context lean

- Small always-on footprint: lean `AGENTS.md`, few skills, only the MCP tools in use.
- **One task per session**; compact early so stale context isn't re-billed every turn; when resuming
  an old thread, start from a **summary** (the recovery ledger is that summary for a sprint).
- **Feed pointers, not payloads** — snippets, paths, and the PRD/design *sections* that matter, not
  whole files or whole sites. Pass diffs + issue lists into review, not entire files.

## Don't churn the cache

Changing model, effort, rules, or tool set mid-task invalidates the prompt cache and re-bills context.
Settle those at the start of a task and hold them.

## Cheapest call is the one you don't make

Push repeated deterministic work down to a **script or hook** rather than an agent turn (formatting,
codegen, boilerplate checks). Index the repo into a queryable map so the agent reads pointers before
raw files.

## What mastery looks like
You pick model and effort on purpose, per task; the bill tracks task difficulty, not session count;
routine work runs cheap while architectural decisions get deeper thinking.

## Toolkit
`/compact` · `/clear` · session summary / hand-off · repo indexing · per-role model dispatch ·
scripts & hooks for deterministic work.
