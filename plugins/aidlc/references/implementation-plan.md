# Implementation Plan (per story / cohesive unit)

Before substantial implementation, produce a short execution plan so the build is deliberate and
verifiable — not a sequence of hopeful edits. One plan per **story or small cohesive unit**, not per
epic. Keep it proportionate: a few lines for a small story, more for a risky one. It does **not** add a
new approval gate for trivial changes (the sprint plan already carries human approval).

## Required contents

1. **References** — the story/ticket key and its acceptance-criteria ids (`FR-*`, `AC-*`), plus the
   design/ADR it implements.
2. **Files & modules** — the specific files to create/modify and the key symbols involved.
3. **Expected changes** — a short description of what each change does (the "what to build" checklist).
4. **Tests** — which tests to create or modify, including **negative and permission** cases, mapped to
   the ACs they prove (see `test-reliability.md`).
5. **Dependencies & sequencing** — what must land first; backend before the frontend that consumes it.
6. **Risk classification** — LOW / MED / HIGH, flagging authz, PII, financial/regulated, production
   infra, destructive changes, external integrations, and AI-generated-code/dependency risk. HIGH-risk
   work gets proportionate review (see `execution-rigor.md` §6).
7. **Verification commands** — the exact commands a reviewer can run (build, the covering tests, lint,
   scans) — reproducible, with seed/fixture where relevant.
8. **Completion criteria** — what "done" means for this unit, pointing at `aidlc-verify-completion`.

## How it fits

- `/aidlc-sprint` produces this plan as part of its TDD-focused plan (architect + critic review it);
  this reference defines the fields it must contain.
- The plan's **verification commands** and **completion criteria** are consumed by
  `aidlc-verify-completion` before anything is called done.
- Keep the plan in a working file (plan.md / the recovery ledger area) so it survives compaction —
  see `token-economics.md` and `task-handoff.md`.
