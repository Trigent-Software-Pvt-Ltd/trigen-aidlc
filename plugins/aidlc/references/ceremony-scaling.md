# Ceremony Scaling — the whole AI-DLC lifecycle, right-sized

The value of AI-DLC is the **thinking steps** (intent → elaborate → design → verify → build →
review), not the *volume* of documents each produces. This reference lets every phase **scale its
output to the size of the work** while keeping the step — so you keep traceability, design rigor and
verification, and drop only the bloat.

Every skill in the lifecycle reads one **gear** and sizes its artifact accordingly.

## The three gears

| Gear | Use for | Shape |
|------|---------|-------|
| **Quick** | Trivial / internal / solo work, a single obvious task, a throwaway | Brief → build. Elaborate, Design and Verify are folded into the brief; go straight to `/aidlc-sprint`. |
| **Standard** (default) | An everyday feature, one or two at a time, end-to-end (FE+BE+DB) | **All six steps run, each producing a compact single-feature output.** This is the light lane that keeps governance without the tower. |
| **Deep** | Cross-cutting / regulated / multi-team, an architectural decision, high blast radius | The full governed flow: §0–§9 Intent, Epics, domain model + ADRs, full verification. |

**Resolve the gear** from `ceremony.default` in `aidlc.config.yaml` (default `standard`), or the
user's answer at the start of a feature. **One-way ratchet:** if hidden complexity or a cross-cutting
decision surfaces mid-feature, **upgrade the gear** (Quick→Standard, Standard→Deep) — never downgrade
— and re-do the affected step at the higher gear. A Standard feature can also escalate **one
decision** to Deep (raise a single ADR) without turning the whole feature into a tower.

## What each phase produces, per gear

| Phase (skill) | Quick | Standard (light) | Deep (governed) |
|---|---|---|---|
| **Intent** (`/aidlc-intent`) | One-page **Feature Brief** (prose; see `feature-brief.md`) | Same **Feature Brief** — this *is* the light intent | Full §0–§9 source-derived Intent (`intent-doc-standard.md`) + validation record |
| **Elaborate** (`/aidlc-elaborate`) | *folded into the brief* | **1–2 tasks**, a few lines each, in the brief or a short list — no Epics/Overviews | Full Epic decomposition + Sprint groupings + Epics Overview |
| **Design** (`/aidlc-design`) | *folded into the brief's "What we build"* | A **short design note** (the contract/approach in a paragraph or two) **+ only the ADR(s) the feature actually forces** (usually none) | Full domain model, logical design, ADR set, detail-sufficiency gate |
| **Verify** (`/aidlc-verify`) | *skipped — build straight from the brief* | **Quick readiness check + create the one or two tickets** with the rich work-item template (labels, estimate) | Full verification rubric + confidence score + fan-out transfer |
| **Sprint** (`/aidlc-sprint`) | Quick ceremony (skip consensus review) | Standard ceremony (one consensus pass) | Deep ceremony (architect+critic+experts, most-capable final review) — see `execution-rigor.md` §1 |
| **Review** (`/aidlc-review`) | Two-stage verdict, light | Two-stage verdict | Two-stage verdict + whole-branch final review |

## Invariants (every gear, never scaled away)

- **A human approval per feature** (Standard collapses the per-phase approvals into a small number of
  quick sign-offs, not zero).
- **A traceability link** — each artifact points back to the one it came from (brief → tasks →
  tickets → PR), even when the artifact is a paragraph.
- **TDD** in the build.
- **At least one code review** before merge.
- **The `aidlc:*` labels** on created tickets, so work stays findable regardless of gear.

## The point

Standard is not "AI-DLC with steps removed" — it's **AI-DLC with each step right-sized**. You still
elaborate, design and verify; each just fits on part of a page and covers one feature. Reserve Deep
for the genuinely cross-cutting decisions; reach for Quick only when the work is truly trivial.
