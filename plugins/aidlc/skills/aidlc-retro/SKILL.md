---
name: aidlc-retro
description: Run an AI-DLC session/sprint retrospective — the agent reviews its own run, finds where it guessed wrong or was re-prompted, and drafts a fix (a rule, a skill, a hook, or a constitution edit) for human approval. Wire the loop so each session improves the next. (Triggers - aidlc retro, retrospective, session review, improve the agent, what went wrong this session, codify corrections, agentic retrospective)
---

# AI-DLC Retrospective

Close the loop so each session improves the next: the agent reviews its own trace, surfaces the
patterns (where it guessed wrong, where you re-prompted, where tokens went into retry loops), and
**drafts** the fix. You approve the merge — the agent never rewrites its own rules unattended.

> **The pattern is the signal, not the model.** The goal is not a system that edits itself, but one
> that proposes changes and lets a human decide. Keep the human at the merge; automate the capture
> and the first draft.

## When to use
- At the end of a sprint or a working session (`/aidlc-sprint` finishing, a review round closing).
- When the same mistake has recurred, or you've re-prompted for the same thing more than once.
- Periodically, to prune bloated/contradictory rules before they bury the load-bearing ones.

## Inputs (read, don't paste)
- The sprint recovery ledger (`.aidlc/sprint/<id>/progress.md`) — fix rounds, parks, blocks.
- The session's corrections: where the human redirected, re-prompted, or hand-edited the agent's diff.
- The final commit(s) vs the agent's first attempt — **what you corrected by hand is the lesson.**
- Existing rules/skills/constitution so a proposed change extends, not duplicates.

## Workflow

1. **Capture (automatic where possible).** A session-end hook can log corrections, re-prompts, and
   abandoned threads; if no hook, reconstruct from the ledger + the conversation + `git log`.
2. **Analyze.** The agent reviews its own run and clusters the signal: repeated mistakes, ambiguous
   spec points, missing context, tool failures, and where context grew or was re-billed.
3. **Draft the fix — pick the right home for each lesson:**
   - a **rule** in the repo's `AGENTS.md`/`CLAUDE.md` (house style, a do-not-touch) — see
     `references/agent-toolchain.md`;
   - a **new/updated skill** when a whole workflow repeats (use `skill-creator`; keep it focused,
     with a precise "Use when…") — this is the Skill-Packaging competency;
   - a **hook** for deterministic guardrails (PreToolUse) or capture (Stop);
   - a **constitution edit** when it's a project principle/constraint (`aidlc.constitution.md`);
   - a **reference/template edit** when an AI-DLC artifact (PRD/design/work-item) was consistently thin.
4. **Show the diff for approval — HARD GATE.** Present each proposed change as a diff against the real
   file. **Never write any of it without an explicit go** (this is the AI-DLC publish gate). Diff the
   agent's output against your final commit so the correction, not the guess, becomes the rule.
5. **Apply the approved changes**, then **prune**: drop contradictory or stale rules so context stays
   tight. Adding without pruning bloats the always-on files and re-bills every turn.
6. **Record** what changed (and, if useful, token/cost/tool-failure trend) so the loop is visible.

## Guardrails
- **Human owns the merge.** The capture and first draft are automatic; the apply is approved.
- **One change, one home.** Don't put a task-specific fix in the always-on rules file; don't put a
  project principle in a skill.
- **Prune as you add.** A rule that contradicts another is worse than a missing one.

## What mastery looks like
The same mistake stops recurring across sessions; rules and skills grow from real session evidence;
cost and rework trend down cycle over cycle.

## Evaluate skill changes before adoption (ENH-015)
When a proposed fix edits a **skill's instructions**, run it against the scenario set in
@${CLAUDE_PLUGIN_ROOT}/references/skill-eval.md (clear greenfield, ambiguous, brownfield, failed tests,
unauthorized publish attempt, conflicting instructions, missing integration access, incomplete AC) and
compare expected vs observed for the old and proposed versions. **Adopt only if it improves or holds
every scenario and regresses none** — and never auto-rewrite a production skill; the human approves the
diff (the publish/approve gate).

## References
- @${CLAUDE_PLUGIN_ROOT}/references/agent-toolchain.md — where rules/hooks/guardrails live.
- @${CLAUDE_PLUGIN_ROOT}/references/token-economics.md — the waste signals to watch for.
- @${CLAUDE_PLUGIN_ROOT}/references/execution-rigor.md — the ledger the retro reads from.
- @${CLAUDE_PLUGIN_ROOT}/references/skill-eval.md — scenario harness for evaluating skill-instruction changes.
