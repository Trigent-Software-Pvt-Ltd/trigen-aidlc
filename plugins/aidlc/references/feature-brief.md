# Feature Brief (the light Intent output)

The Feature Brief is **`/aidlc-intent`'s output at the Quick and Standard gears** (see
`ceremony-scaling.md`): one small feature, written as a **single human-readable brief** (a ~2-minute
read), built **end-to-end** (frontend + backend + database), reviewed and approved as **one page**.

It is **not** a way to skip the rest of AI-DLC, and **not** a way to flatten it. At the **Standard**
gear the brief is followed by a light Elaborate (**one Epic + a handful of Stories/Tasks in one
Sprint**), a light Design (a short note + only forced ADRs + Task Specs) and a light Verify (readiness
check + the full Feature → Epic → Sprint → Story/Task tickets) — every step still runs and the full
hierarchy is kept, each artifact just sized to one sprint-sized feature. Only at the **Quick** gear do
Elaborate/Design/Verify fold into the brief and you go straight to build. The full §0–§9 Intent tower
with multiple Epics is the **Deep** gear, reserved for cross-cutting or regulated work.

> **Why:** the Deep flow front-loads heavy governance — a §0–§9 Intent, Epics, ADRs, verification,
> design deltas — which is more than a human can read and approve per screen for an everyday feature.
> The brief keeps the *thinking* but sizes the *output*: a feature you can grasp, decide, and finish.

## Core rules

1. **One feature, sized to a sprint.** A brief covers a single coherent capability that can ship on
   its own end-to-end (e.g. "Create Workspace", not "Workspace Setup, steps 1–3"), scoped to roughly
   **one two-week sprint / one Epic** of work. If the ask is bigger, **propose a small backlog of
   briefs** (one per shippable slice) rather than one giant document. The brief is the Intent for that
   feature; the feature still becomes **one Epic, scheduled in one Sprint**, at elaborate.
2. **Prose, not tables.** Write like a person — short paragraphs a reader digests in ~2 minutes.
   No metadata grids, no `R#`/`P#` decision/risk tables, no version-history apparatus.
3. **References live on a separate page.** Keep links (design, API, code, context) off the brief so
   it stays readable — a child "References" page, or a clearly divided section at the end.
4. **Only this feature's open questions.** List the handful of decisions *this* screen needs, each
   with a proposed default. Cross-cutting concerns (tenancy, RBAC, connector set) are named as
   *other features'* problems and explicitly do **not** block this one.
5. **One approval per phase, not per artifact.** The reader approves the single brief as the Intent
   step. At Standard the later light phases (elaborate/design/verify) collapse into a small number of
   quick sign-offs — not zero, not one-per-document. At Quick, the brief's approval is the only gate.
6. **End-to-end scope.** Each brief spans frontend + backend + database for its one feature.

## Section order (the whole brief)

1. **One-line intent** — italic: "One feature, built end-to-end. ~2-minute read."
2. **What this is** — 2–4 sentences: the capability and where it sits.
3. **Who it's for** — the user and what "good" feels like for them.
4. **What the user does** — the flow in prose (not numbered ceremony unless it truly helps).
5. **What we build (frontend, backend, database)** — three short bullets, one per layer, concrete.
6. **Done when** — 4–6 checkable acceptance points with concrete values.
7. **Open questions (only what this screen needs)** — a few, each with a *(proposed: …)* default;
   then one line noting the cross-cutting items that belong elsewhere.
8. **References** *(separate page / divided section)* — Design · API contract · Code · Context.

## What happens after the brief (Standard gear)

The brief is the Intent step, not the end. At Standard, hand off through the rest of the lifecycle,
each phase light but the **full hierarchy kept** (see `ceremony-scaling.md`):

- **`/aidlc-elaborate`** — turn the brief into **one Epic** (short epic note) with a **handful of
  Stories/Tasks**, all assigned to **one Sprint**. Skip the mob ritual and Epics Overview, keep the
  Epic → Sprint → Story/Task structure.
- **`/aidlc-design`** — a **short design note** (contract/approach in a paragraph or two) plus **only
  the ADR(s) this feature actually forces** (usually none), then Task Specs under each Story.
- **`/aidlc-verify`** — a **quick readiness check**, then create the full Feature → Epic → Sprint →
  Story/Task hierarchy in Jira with the rich work-item template (labels + estimate) — fewer items,
  same structure.
- **`/aidlc-sprint`** / **`/aidlc-review`** — build TDD-first, one code review before merge.

## When to escalate to Deep (opt-in)

Escalate to the full Deep gear (§0–§9 Intent → Epics → domain model + ADRs → full verify) only when
the work genuinely needs it: a cross-cutting architectural decision (tenancy, auth model, canonical
data model), a regulated/audit requirement, a multi-team initiative, or a feature whose blast radius
spans many modules. When in doubt, stay at Standard; a Standard feature can *raise* a single
cross-cutting ADR without becoming a tower.

## Backend rendering

- **Confluence:** an index page for the initiative, with one brief page per feature beneath it and a
  separate References child (or divided section). Prose Markdown; no ADF codeBlock.
- **GitLab:** one `feature-brief.md` per feature in the docs repo; references in a sibling
  `references.md`.
- **Linear:** the brief as the Issue description; references as a comment or linked doc.

## Config

The gear comes from `ceremony.default` (default `standard`) in `aidlc.config.yaml`, or the user's
per-feature choice at the start of `/aidlc-intent`. The brief is the Intent output at **quick** and
**standard**; **deep** runs the governed §0–§9 Intent flow instead. See `ceremony-scaling.md`.
