# Ceremony Scaling — the whole AI-DLC lifecycle, right-sized

The value of AI-DLC is the **thinking steps** (intent → elaborate → design → verify → build →
review), not the *volume* of documents each produces. This reference lets every phase **scale its
output to the size of the work** while keeping the step — so you keep traceability, design rigor and
verification, and drop only the bloat.

Every skill in the lifecycle reads one **gear** and sizes its artifact accordingly.

## The three gears

| Gear | Use for | Shape |
|------|---------|-------|
| **Quick** | Trivial / internal / solo work, a single obvious task, a throwaway | Brief → build. Elaborate, Design and Verify are folded into the brief; go straight to `/aidlc-sprint`. Still landed under an Epic + Sprint if a ticket is created. |
| **Standard** (default) | An everyday feature sized to **~one two-week sprint**, one or two at a time, end-to-end (FE+BE+DB) | **All six steps run AND the full hierarchy is kept — Feature → Epic → Sprint → Story/Task — just with compact content.** One Epic, one Sprint, a handful of Stories/Tasks. This is the light lane: **structure and governance kept, tower dropped.** |
| **Deep** | Cross-cutting / regulated / multi-team, an architectural decision, high blast radius | The full governed flow: §0–§9 Intent, **multiple** Epics, domain model + ADRs, full verification, multi-sprint planning. |

**Sizing rule (Standard):** a **feature** is sized to roughly one **two-week sprint** and becomes one
**Sprint's** worth of Stories/Tasks. An **Epic is the container for one _or more related_ features** —
so the first feature in an area *creates* the Epic, and later **related** features **attach under the
same Epic** as additional Sprints rather than spawning a new Epic. Only an *unrelated* capability gets
a new Epic. Work that clearly exceeds one sprint is either several features (a small backlog of
briefs) or Deep (upgrade the gear). Light means **less content per artifact and fewer artifacts —
never a flatter hierarchy.** Every Story/Task still hangs off an Epic and is scheduled in a Sprint, so
related work accumulates under one Epic and stays traceable and ready to scale up.

**Attach-or-create the Epic (every gear, in `/aidlc-elaborate`).** Before creating an Epic, work out
whether this feature *belongs to an existing one*:
1. Read the feature's parent initiative / brief references and **search the tracker + docs for an
   existing Epic** covering the same area (e.g. an initiative page, a same-named or sibling Epic).
2. If a related Epic exists, **propose attaching** this feature under it as a **new Sprint** (its
   Stories/Tasks grouped in a fresh `aidlc:sprint` grouping under that Epic) — confirm with the user.
3. If none fits, **create a new Epic** named for the *area/initiative* (not the single feature), so
   later related features can attach to it too.
Either way the result is: one Epic (new or reused) → one Sprint for *this* feature → its Stories/Tasks.

**Resolve the gear** from `ceremony.default` in `aidlc.config.yaml` (default `standard`), or the
user's answer at the start of a feature. **One-way ratchet:** if hidden complexity or a cross-cutting
decision surfaces mid-feature, **upgrade the gear** (Quick→Standard, Standard→Deep) — never downgrade
— and re-do the affected step at the higher gear. A Standard feature can also escalate **one
decision** to Deep (raise a single ADR) without turning the whole feature into a tower.

## What each phase produces, per gear

| Phase (skill) | Quick | Standard (light) | Deep (governed) |
|---|---|---|---|
| **Intent** (`/aidlc-intent`) | One-page **Feature Brief** (prose; see `feature-brief.md`) | Same **Feature Brief** — this *is* the light intent; the feature is sized to ~one Epic / one sprint | Full §0–§9 source-derived Intent (`intent-doc-standard.md`) + validation record |
| **Elaborate** (`/aidlc-elaborate`) | *folded into the brief* (still lands under an Epic + Sprint if ticketed) | **Attach to a related Epic or create one** (named for the area, not the single feature), add **this feature as one Sprint** of a handful of **Stories/Tasks** — the full hierarchy, compact. Skip the multi-epic mob ritual and the separate Epics Overview | **Multiple** Epics via full Mob Elaboration + Sprint groupings + Epics Overview |
| **Design** (`/aidlc-design`) | *folded into the brief's "What we build"* | A **short design note** (contract/approach in a paragraph or two) **+ only the ADR(s) the feature actually forces** (usually none), then **Task Specs under each Story** at build depth | Full domain model, logical design, ADR set, detail-sufficiency gate |
| **Verify** (`/aidlc-verify`) | *skipped — build straight from the brief* | **Quick readiness check**, then create the **full Feature → Epic → Sprint → Story/Task hierarchy** with the rich work-item template (labels, estimate) — just fewer items | Full verification rubric + confidence score + fan-out transfer across many Epics |
| **Sprint** (`/aidlc-sprint`) | Quick ceremony (skip consensus review) | Standard ceremony (one consensus pass) | Deep ceremony (architect+critic+experts, most-capable final review) — see `execution-rigor.md` §1 |
| **Review** (`/aidlc-review`) | Two-stage verdict, light | Two-stage verdict | Two-stage verdict + whole-branch final review |

## Invariants (every gear, never scaled away)

- **A human approval per feature** (Standard collapses the per-phase approvals into a small number of
  quick sign-offs, not zero).
- **Show draft → get approval → publish, in that order — at every gear.** No phase writes to a shared
  system of record (Confluence page, GitLab MR/commit, Linear issue, Jira ticket) until the human has
  seen the drafted content *in chat* and said go. "Run the phase" is **not** consent to publish its
  output. Quick's single brief-approval still precedes any write; Standard's quick per-phase sign-off
  still precedes that phase's write. When unsure whether you have approval, you do not — ask.
- **A traceability link** — each artifact points back to the one it came from (brief → tasks →
  tickets → PR), even when the artifact is a paragraph.
- **TDD** in the build.
- **At least one code review** before merge.
- **The `aidlc:*` labels** on created tickets, so work stays findable regardless of gear.

## The point

Standard is not "AI-DLC with steps removed" and not "AI-DLC with the hierarchy flattened" — it's
**AI-DLC with each step right-sized and the full structure intact**. You still elaborate, design and
verify; the work still hangs off an **Epic** and is scheduled in a **Sprint**; each artifact just
fits on part of a page and covers one sprint-sized feature. Because the scaffolding is already there,
scaling a feature up (more Stories, a second sprint, a real domain model) is just adding to it — not
rebuilding it. Reserve Deep for genuinely cross-cutting decisions; reach for Quick only when the work
is truly trivial.
