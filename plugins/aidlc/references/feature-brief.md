# Feature Brief (lightweight lane)

The **default** way `/aidlc-intent` captures a feature: one small feature, written as a **single
human-readable brief** (a ~2-minute read), built **end-to-end** (frontend + backend + database),
reviewed and approved as **one page**, then handed to build. It is the opposite of the full
Intent → Elaborate → Design → Verify document tower, which stays available as an explicit opt-in for
genuinely cross-cutting or regulated work.

> **Why:** the full flow front-loads heavy governance — a §0–§9 Intent, Epics, ADRs, verification,
> design deltas — which is more than a human can read and approve per screen. The brief trades some
> up-front ceremony for **readability and momentum**: a feature you can grasp, decide, and finish.

## Core rules

1. **One feature, sliced small.** A brief covers a single coherent capability that can ship on its
   own end-to-end (e.g. "Create Workspace", not "Workspace Setup, steps 1–3"). If the ask is bigger,
   **propose a small backlog of briefs** (one per shippable slice) rather than one giant document.
2. **Prose, not tables.** Write like a person — short paragraphs a reader digests in ~2 minutes.
   No metadata grids, no `R#`/`P#` decision/risk tables, no version-history apparatus.
3. **References live on a separate page.** Keep links (design, API, code, context) off the brief so
   it stays readable — a child "References" page, or a clearly divided section at the end.
4. **Only this feature's open questions.** List the handful of decisions *this* screen needs, each
   with a proposed default. Cross-cutting concerns (tenancy, RBAC, connector set) are named as
   *other features'* problems and explicitly do **not** block this one.
5. **One approval.** The reader approves the single brief; it goes to build. No separate
   Intent/Elaborate/Design sign-offs.
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

## When to use the heavy lane instead (opt-in)

Escalate to the full Intent → Elaborate → Design → Verify flow only when the work genuinely needs it:
a cross-cutting architectural decision (tenancy, auth model, canonical data model), a regulated/
audit requirement, a multi-team initiative, or a feature whose blast radius spans many modules.
When in doubt, start with a brief; a brief can *raise* a cross-cutting ADR without becoming a tower.

## Backend rendering

- **Confluence:** an index page for the initiative, with one brief page per feature beneath it and a
  separate References child (or divided section). Prose Markdown; no ADF codeBlock.
- **GitLab:** one `feature-brief.md` per feature in the docs repo; references in a sibling
  `references.md`.
- **Linear:** the brief as the Issue description; references as a comment or linked doc.

## Config

`featureBrief.enabled: true` (default) makes this the standard `/aidlc-intent` output. Set it to
`false`, or answer the mode prompt with "full", to run the governed Intent flow for that feature.
