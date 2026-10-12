# Artifact Consolidation & Readability

> **Why this exists.** AI-DLC's value is the *thinking* (intent → elaborate → design → verify),
> not the *volume of pages* it emits. Left unchecked, the lifecycle fans out into many
> machine-dump pages — a page per ADR, status tables buried inside huge pages, several epics for
> a small feature — that a human can't comfortably read or maintain. This reference is the
> **default artifact shape** every skill follows: **few, focused, human-readable pages**, each
> cheap to update. Scale *up* only when the work genuinely demands it.

This doctrine applies at **every gear**. Ceremony-scaling says keep the *thinking steps*; this
says keep the *output lean and readable*. The two work together: `ceremony-scaling.md` decides how
much analysis each step does; this file decides how that analysis is laid out as pages.

## The default page set (per Feature)

A Feature produces **one of each** of these, and nothing more unless a fan-out trigger (below) fires:

| Artifact | What it is | Lives | Updated by |
|----------|-----------|-------|-----------|
| **Feature doc** | The PRD/Intent — a well-written, prose-first document a BA/PO can read end to end | one page | `/aidlc-intent` |
| **Status page** | The single workflow-status table (Feature / Elaborate / Design / Verify / Sprint + Jira links) | one small child page of the Feature | **every** phase |
| **Epic** | The area/initiative container — **one by default** | one page (child of Feature) | `/aidlc-elaborate` |
| **Design doc** | The HOW — a readable solution document (prose + the tables/diagram that earn their place) | one page per epic | `/aidlc-design` |
| **Decisions (ADRs)** | **One consolidated page**, each decision a `## ADR-NN` section | one page per epic | `/aidlc-design` |
| **Test Scope** | Layered scenarios per sprint + epic integration | one page per epic | `/aidlc-design` |
| **Task Specs** | The build units — one per task is fine, kept tight | child pages of the epic | `/aidlc-design` |

### The acceptance-criteria catalogue is required and must never be dropped

Consolidation reduces the number of pages, but it must **never drop the acceptance-criteria
catalogue**. Every feature keeps a single, authoritative list of acceptance criteria with **stable
ids** (for example `AC-RHI-01`), written in **EARS** and carrying the governed values the criteria
depend on (thresholds, gate percentages, retention periods, simulation parameters). It lives on the
Feature doc or on a dedicated **"Acceptance Criteria" page** under the Epic, and it is the thing the
Design, the Test Scope, and the verdict/metric logic all trace back to by id. The Test Scope's
coverage matrix maps those ids to test cases in **both directions** (every criterion has a case;
every case names a criterion). If you move behaviour into prose during consolidation, you still
publish the AC catalogue — prose explains, the catalogue is what gets verified. Dropping it breaks
traceability and makes "every AC has a test" an unprovable claim (a real defect caught in review).

**Do NOT** create: a page per ADR; a separate "Epics Overview" page when there is one epic;
status tables embedded inside the Feature/Epic/Design pages (they belong on the Status page);
"Service Context" pages for green-field work.

### The Status page (the cheap-to-flip pattern)

Every phase flips a status (Draft → In Review → Approved). If that status lives inside a large
page, each flip forces re-publishing the whole page — expensive and error-prone (see Confluence
mechanics below). Instead, keep a **small dedicated Status page** as the single source of phase
state. Phases update *this* page only; the big documents never carry a status table.

Minimum Status-page content:

```markdown
# Status — <Feature name>
| Phase | Status | Date | Link |
|-------|--------|------|------|
| Feature   | ✅ Approved    | <date> | <feature page> |
| Elaborate | ✅ Complete    | <date> | <epic page> |
| Design    | 🟡 In Review   | <date> | <design page> |
| Verify    | ⬜ Not started | -      | - |
| Sprint    | ⬜ Not started | -      | - |
| Work tracking | Jira <KEY> | <date> | <project/board> |
```

## One Epic by default — fan-out is opt-in

A Feature decomposes into **one Epic** named for the area. Add more epics **only** when a
fan-out trigger is met, and record the one-line justification on the Epic/Status page:

**Fan-out triggers (all three should hold):**
1. **Genuinely independent** — the sub-areas deliver value on their own and share little code.
2. **Large** — the whole clearly exceeds one epic's worth of work (several sprints each).
3. **Parallelisable by different people/teams** — splitting actually buys parallelism.

If the work is big but cohesive, prefer **one Epic with multiple Sprints** over multiple epics.
A small feature (e.g. a few UI cards) is **one Epic, one or two Sprints** — never a tower of
epics. When in doubt, consolidate; the one-way ratchet (`ceremony-scaling.md`) lets you split
later if a real boundary emerges.

> **Even at Deep gear**, consolidation is the default. Deep buys deeper *analysis* (domain model,
> ADRs, verification rigor) — not automatically more *pages*. Fan out epics/ADR pages at Deep only
> when the triggers above fire.

## One consolidated ADR page

Record architecture decisions as **sections of a single "Decisions (ADRs)" page** for the epic:

```markdown
# Decisions (ADRs) — <Epic>
## ADR-01: <title>
**Status / Context / Decision / Consequences / Alternatives**
## ADR-02: <title>
...
```

Give an ADR its **own page only** when it is a cross-feature / shared-contract decision that other
features must link to independently. Otherwise keep it as a section — one page the reviewer reads
top to bottom.

## Readability rules (human-written, not machine-dumped)

- **Prose first.** Lead each section with 1–3 sentences of plain explanation a BA/PO can validate,
  then the detail. Sections 1/2/6/7/9 of the design doc stay code-identifier-free (see
  `design-doc-template.md`).
- **Tables and diagrams earn their place** — use them for contracts, data models, decision logs;
  don't turn narrative into a wall of bullets.
- **One page, one job.** A reader should know what a page is for from its title and first line.
- **No duplication.** Link, don't copy. The design links the PRD; it doesn't restate it.
- **Keep each page scannable** — headings, short paragraphs; a page a person can read in a sitting.

## Confluence update mechanics (so edits stay cheap and safe)

- **Small pages flip cheaply.** Because there is no partial-update API, editing a page re-publishes
  its whole body. Keeping status on its own small page (and ADRs/test-scope on their own pages)
  means routine flips touch little content.
- **Edit published pages with `contentFormat: html`.** A markdown full-replace is **rejected** when
  the page already contains a task-list or macro ("content contains elements that cannot be
  represented in markdown"). Call `getContentFormatGuide` first when editing.
- **Code and diagrams in HTML use `<pre><code class="language-…">`** — not `<ac:structured-macro>`
  (which is rejected by the HTML validator). Mermaid: `<pre><code class="language-mermaid">…`.
- **Creating a new page** may use `contentFormat: markdown` (checkbox lists become task-lists
  cleanly on create); the markdown limitation only bites on *updates* to pages that already contain
  those elements.

## The consolidated Confluence hierarchy

```
<Project/Space home>
└── Feature: <Title>                     ← the PRD/Intent (prose)
    ├── Status — <Title>                 ← the one status table (cheap to flip)
    └── Epic: <Area>                     ← one by default
        ├── Design — <Area>              ← readable HOW document
        ├── Decisions (ADRs) — <Area>    ← one page, ADRs as sections
        ├── Test Scope — <Area>          ← layered scenarios
        └── Task U0N-T0N: <title>        ← tight build units
```

Multiple epics appear **only** when the fan-out triggers fire; then an `Epics Overview` page is
warranted, and each epic keeps its own Design / Decisions / Test Scope trio.

## What each skill does differently under this doctrine

- **`/aidlc-intent`** — create the Feature doc **and** the Status page; put the workflow-status
  table on the Status page, not inside the Feature doc.
- **`/aidlc-elaborate`** — default to **one Epic**; skip the separate Epics Overview and Service
  Context pages for the single-epic case; fan out only on the triggers (record the reason).
- **`/aidlc-design`** — one readable Design page, one consolidated Decisions (ADRs) page, one Test
  Scope page per epic; update the **Status page** (not embedded tables) when flipping In Review /
  Approved.
- **`/aidlc-verify`** — read the consolidated structure; update the **Status page**; transfer to
  Jira from the single Epic + its Task Specs.
