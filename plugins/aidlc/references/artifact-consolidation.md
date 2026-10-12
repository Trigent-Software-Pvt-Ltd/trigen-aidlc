# Artifact Consolidation & Readability

> **Why this exists.** AI-DLC's value is the *thinking* (intent → elaborate → design → verify),
> not the *volume of pages* it emits. Left unchecked, the lifecycle fans out into many
> machine-dump pages — a page per ADR, a separate Design / Decisions / Test-Scope / Acceptance-Criteria
> page, status tables buried inside huge pages — that a human can't comfortably read or maintain.
> This reference is the **default artifact shape** every skill follows: **one requirement, one
> document**, written the way a BA/PO would write it, plus two small side pages that must stay
> separate for a mechanical reason. Scale *up* only when the work genuinely demands it.

This doctrine applies at **every gear**. `ceremony-scaling.md` decides how much *analysis* each step
does; this file decides how that analysis is laid out as pages.

## The default page set (per Feature)

A Feature produces **one of each** of these, and nothing more unless a fan-out trigger fires:

| Artifact | What it is | Why it is where it is | Updated by |
|----------|-----------|-----------------------|-----------|
| **Functional Specification** | The whole requirement as **one BA/PO-authored document** — overview, problem, goals, scope, stakeholders, functional requirements, the FR→sprint map, *how it works* (the solution narrative + the one diagram), a decision log (ADRs as short sections), data sources & lineage, the **acceptance criteria** (EARS, by stable id), the **test scope** + bidirectional coverage matrix, NFRs, business rules, risks, open items, version history | One document a reader can understand end to end without hopping pages. Each phase **appends/updates its own section** of this one page; it does not spawn a new page. | **every** phase (intent → design) |
| **Governed Values** | The **versioned numbers** the criteria depend on — thresholds, gates, simulation parameters, retention periods, the business-time calendar — published as immutable versions (v1, v2…) | Kept **separate on purpose**: it changes on its own cadence (a PO publishes a new threshold version) and must be versionable without republishing the whole spec. The spec's acceptance-criteria section references it by name/id. | `/aidlc-design`, PO |
| **Status** | The phase-status table (Intent / Elaborate / Design / Verify / Sprint + Jira links) | Kept **separate on purpose**: it flips constantly and must not force a republish of the large spec (Confluence has no partial-update API). | **every** phase |
| **Task Specs** *(optional)* | Granular build units, only if a feature needs per-task pages | Default is **sprint-grain Stories in the tracker** (Jira/Linear); create Confluence task pages only when the team wants them. | `/aidlc-design` / `/aidlc-verify` |

> **The shift from earlier versions:** Design, Decisions (ADRs), Source-Model/Data-Lineage, the
> Acceptance-Criteria catalogue and the Test Scope are **no longer separate pages** — they are
> **sections of the one Functional Specification**. Only **Governed Values** and **Status** remain
> separate, each for the mechanical reason above. See `functional-spec-template.md` for the section order.

### The acceptance criteria are a required section and must never be dropped

Consolidating into one document must **never drop the acceptance criteria**. The spec keeps a single,
authoritative **Acceptance Criteria** section with **stable ids** (e.g. `AC-RHI-01`), written in
**EARS**, that the solution narrative, the decision log, the test scope, and the metric/verdict logic
all trace back to by id. The **governed numbers** those criteria depend on live on the Governed Values
page and are cited by name, so the spec explains behaviour while the numbers are versioned once,
elsewhere. The Test Scope section's coverage matrix maps AC ids to test cases in **both directions**
(every criterion has a case; every case names a criterion). Prose explains; the criteria are what gets
verified. Dropping them breaks traceability and makes "every AC has a test" unprovable (a real defect
caught in review).

### Completeness is preserved by *single-home-per-fact*, not by *many pages*

One document and single-source-of-truth are **not** in tension. The rule is: **every fact has exactly
one canonical home**, and everything else references it. A threshold is stated once (Governed Values)
and referenced by name; an AC is stated once (the Acceptance Criteria section) and referenced by id; a
decision is stated once (the Decision log). The failure mode is **duplication** (a number in prose
*and* in a table), not consolidation. Keep stable ids and one home per fact and nothing is lost.

### The Status page and Governed Values page (the cheap-to-flip pattern)

Because there is no partial-update API, editing a page re-publishes its whole body. The Functional
Spec is large, so the two things that change most often — **phase status** and **governed numbers** —
are kept on their own small pages. A status flip or a new threshold version then touches little
content and never risks the big document.

## One Epic by default — fan-out is opt-in

A Feature is realised as **one Epic** (in the tracker) named for the area, organised as sprints. Add
more epics **only** when a fan-out trigger is met (record the one-line reason):

**Fan-out triggers (all three should hold):** (1) genuinely independent sub-areas that ship value on
their own and share little code; (2) large — the whole clearly exceeds one epic (several sprints each);
(3) parallelisable by different people/teams. If the work is big but cohesive, prefer **one Epic with
multiple Sprints**. Multiple genuinely-independent features each get their **own Functional Spec**;
within one feature it is always one spec.

> **Even at Deep gear**, consolidation is the default. Deep buys deeper *analysis* (domain model, ADRs,
> verification rigor) — not more *pages*.

## Decision log (ADRs as sections)

Record architecture/product decisions as **short sections of the Decision-log part of the spec**
(`## ADR-01: <title>` — Context / Decision / Consequences / Alternatives). Give an ADR its **own page
only** when it is a cross-feature / shared-contract decision other features must link to independently.

## Readability rules (human-written, not machine-dumped)

- **Prose first.** Lead each section with 1–3 sentences a BA/PO can validate, then the detail. The
  overview/scope/solution sections stay code-identifier-free.
- **Tables and diagrams earn their place** — contracts, data models, decision logs, coverage matrices;
  don't turn narrative into a wall of bullets.
- **No duplication.** State a fact once in its canonical section; elsewhere reference it by id/name.
- **Scannable** — clear section headings; a reader can navigate the one doc by its table of contents.

## Confluence update mechanics (so edits stay cheap and safe)

- The Functional Spec is large and section-structured; **edit it with `contentFormat: html`** (a
  markdown full-replace is rejected once the page contains a task-list or macro — e.g. a Mermaid
  diagram). Call `getContentFormatGuide` first.
- **Code/diagrams in HTML use `<pre><code class="language-…">`** (e.g. `language-mermaid`), not
  `<ac:structured-macro>`. Escape `-->` as `--&gt;` inside Mermaid.
- **Creating a new page** may use `contentFormat: markdown`.
- Keep **Status** and **Governed Values** separate so routine flips don't republish the spec.

## The consolidated Confluence hierarchy

```
<Project/Space home>
└── Functional Specification: <Title>     ← the one BA/PO document (the requirement, end to end)
    ├── Status — <Title>                   ← phase-status table (cheap to flip)
    └── Governed Values — <Title>          ← versioned thresholds/numbers (independent cadence)
```

The **Epic and its Stories live in the tracker** (Jira/Linear); Confluence no longer needs a separate
Epic / Design / Decisions / Test-Scope / Acceptance-Criteria page. Multiple Functional Specs appear
only when the fan-out triggers fire (genuinely independent features).

## What each skill does differently under this doctrine

- **`/aidlc-intent`** — create the **Functional Specification** (Overview, Problem, Goals, Scope,
  Stakeholders, Functional Requirements) **and** the Status page. Put the status table on the Status
  page, not in the spec.
- **`/aidlc-elaborate`** — default to **one Epic**; add the **Decomposition / FR→sprint map** section
  to the spec; fan out only on the triggers.
- **`/aidlc-design`** — **append sections to the same Functional Spec**: *How it works* (solution +
  diagram), the **Decision log** (ADRs), **Data sources & lineage**, **Acceptance Criteria** (EARS, by
  id), and **Test Scope** (+ coverage matrix). Create/update the **Governed Values** page for the
  numbers. Flip the **Status** page — never embed status in the spec.
- **`/aidlc-verify`** — read the one spec; check the AC section ↔ Test Scope matrix close; transfer to
  Jira from the single Epic; update the **Status** page.
