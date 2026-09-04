# Execution Rigor (shared reference)

Rigor mechanisms for `/aidlc-sprint` and `/aidlc-review`, adapted from the subagent-driven
execution model. Both skills reference this file as the single source of truth for: ceremony
scaling, the recovery ledger, task briefs / context hygiene, and the fix-loop + adjudication
protocol (incl. two-stage review). Keep these consistent across the two skills.

---

## 1. Ceremony scaling (Quick / Standard / Deep)

> The **lifecycle-wide** gear model (what Quick/Standard/Deep produce at intent, elaborate, design,
> verify, sprint and review) lives in `ceremony-scaling.md`. This section is the **sprint-specific**
> detail of the same gear the feature is already running.

Scale the *amount of process* to the work, but **never scale away the human approval gate or TDD**.
The gear is normally already set for the feature (config `ceremony.default`, carried from
`/aidlc-intent`); if entering sprint cold, classify from the Task Specs (size, file count, blast
radius, risk):

| Path | When | Ceremony |
|------|------|----------|
| **Quick** | Throwaway/spike, single-file, size 1–2, no cross-module impact, config/docs | Minimal plan; **skip** the architect+critic consensus review; single self-review; still TDD + human approval + one code review |
| **Standard** (default) | Typical feature slice, size 3–5, a few files, one module | Full plan; **one** consensus pass (architect → critic) or skip only if trivial; TDD; human approval; code review |
| **Deep** | Cross-cutting, size 8–13, multiple modules, security/perf/data-critical, ambiguous design | Full plan; architect + critic consensus + optional expert perspectives; TDD; human approval; whole-branch final review on the most capable model |

**One-way ratchet:** if hidden complexity surfaces mid-sprint (a "Quick" task turns out to touch
three modules), **upgrade the path** — never downgrade. Announce the upgrade and re-plan the
remaining work at the higher ceremony.

**Invariants (all paths):** human approval before any code; TDD (write the failing test first);
at least one code review before "In Review"; the recovery ledger.

---

## 2. Recovery ledger (survives compaction)

The plan file is for humans; the **ledger is the machine recovery map**. Conversation memory does
not survive compaction — without a ledger, a resumed sprint can silently re-run completed tasks.

**Location:** `.aidlc/sprint/<sprint-id>/progress.md` (git-ignored — add `.aidlc/` to `.gitignore`).

**First line is its identity:** `# AIDLC sprint ledger — sprint: <id> — plan: <plan-file-path>`.

**Append-only entries** (one per task event):
```
Task <id>: complete (commits <base7>..<head7>, review clean)
Task <id>: fix round <R>/3 (<X> addressed, <Y> open — <one-liners>; commits <a7>..<b7>)
Task <id>: parked — <finding> — ruling: <why it stands / deferred>
Task <id>: BLOCKED — <reason>
```

**Resume protocol (run at skill entry):**
1. If `<workspace>/progress.md` exists **and** its first line names *this* sprint: tasks with a
   `complete` line are DONE — do not re-dispatch; resume at the first task without one. A task
   whose last line is a `fix round` is mid-loop — resume the loop at the next round.
2. A ledger naming a *different* sprint, or none, → start a fresh ledger.
3. **After compaction, trust the ledger and `git log` over your own recollection** — the commits
   the ledger names exist in git even when context no longer remembers creating them.

---

## 3. Task briefs & context hygiene

Everything pasted into a subagent dispatch — and everything it prints back — stays resident in the
controller's context for the rest of the session and is re-read every turn. **Hand artifacts over
as files, not as pasted text.**

- **Brief per task:** before dispatching a subagent (context-gathering, test-planning, or
  implementation), extract that task's full text to a **brief file** and pass the *path*. The brief
  is the single source of requirements; **exact values (numbers, signatures, magic strings, enum
  values) appear only in the brief.** Never make a subagent read the whole plan.
- **Report per task:** the subagent writes its full report to a **report file** and returns only:
  status, commits, a one-line test summary, and concerns. The controller reads the report file
  only when it needs detail.
- **A dispatch describes one task, not the session's history.** Do not paste accumulated
  prior-task summaries into later dispatches — pass only the task's brief, the interfaces it
  touches, and the global constraints.
- **Never dispatch multiple implementation subagents in parallel on overlapping files** (conflicts).

---

## 4. Fix-loop + adjudication (3 rounds) and two-stage review

### Two-stage review
Every review is **two explicit verdicts, both required**: (1) **spec compliance** — does it meet the
Task Spec's acceptance criteria? then (2) **code quality** — clean, tested, secure, follows repo
conventions? An implementer's self-review never replaces this. Missing either verdict = not reviewed.

### The fix loop (max 3 rounds per task)
Triggers on: spec ❌, any Critical/Important finding, or a "cannot verify from diff" item the
controller confirms as a real gap. **Minor findings never enter the loop** — record them in the
ledger as deferred and hand them to the final review.

- **Round 1–2 — resume the original implementer** with the open findings verbatim (its context is
  intact). Each round ends with a **scoped re-review** of the fix diff only.
- **Round 3 — dispatch a fresh implementer on a more capable model** ("a prior implementer tried
  this N times; you own it now — read the report file"). Fresh eyes + capability bump in one move.
- **Every round:** the implementer fixes, re-runs the covering tests, appends its fix report to the
  same report file; then run one scoped re-review. New Critical/Important breakage in the fix diff
  joins the open findings; out-of-scope observations go to the ledger as deferred minors.
- **Never fix findings in the controller session** — controller fixes skip review and pollute context.

### The breaker (at the cap)
When round 3's re-review still leaves findings open, **stop dispatching and adjudicate each one** —
the controller holds the plan and cross-task context the reviewer lacks:
- **Reviewer wrong / contestable** → park with a ruling (ledger): `parked — <finding> — ruling: <why the code stands>`.
- **Real but nothing downstream depends on it** → park with a ruling that says real-and-deferred.
- **Real and load-bearing** (a later task builds on it, or it reveals a plan defect) → **STOP**:
  ledger `BLOCKED — <reason>` and escalate to the human with the finding, the plan text it collides
  with, and the fix history.

**No silent discards** — every adjudication is a ledger entry. Adjudicate **only at the cap**;
adjudicating earlier to end a loop is pre-judging.

### Model selection (per role)
Use the least powerful model that fits the role: cheap/fast for mechanical transcription tasks and
small scoped re-reviews; standard for integration/judgment; the most capable for design tasks and
the whole-branch final review. Escalate one tier for the round-3 fix. **Always name the model
explicitly when dispatching** — an omitted model inherits the session's (often most expensive) model.
