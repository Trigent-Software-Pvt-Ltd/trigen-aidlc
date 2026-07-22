# Intent Document Standard (Feature Intent)

> **Purpose of this file:** Defines the full structure and rigor of an AI-DLC Feature
> Intent document when it is **derived from an existing source requirement** (e.g. a BRD,
> PRD, or discovery brief) and must serve as an auditable **delivery contract** — not a
> second copy of the requirements.
>
> Use this standard in `/aidlc-intent` whenever a source requirement document exists.
> For pure green-field ideation with no source doc, the lightweight template in
> `planning-shared.md` is sufficient; the source-traceability and validation sections
> below become optional.

## Core principle

The Intent document is **NOT a re-write of the source requirement**. The source doc
(BRD/PRD) remains authoritative for business and UI detail. The Intent adds what the
source does not contain:

- the **MVP / first-delivery slice** (what we build first),
- **engineering scope boundaries** and out-of-scope decisions,
- **lifecycle acceptance criteria** (Intent-phase gates, not feature UAT),
- **risks, assumptions, dependencies** framed for delivery,
- a **recorded validation trail** and **traceability** back to the source.

If a section would merely restate the source doc, summarize it and link out instead.

## Required section order

Number the sections; reviewers reference them by number in comments.

### Metadata header (table)

| Field | Notes |
|-------|-------|
| Document ID | e.g. `FI-000N` |
| Status | Draft / In Review / Approved |
| AI-DLC Stage | Stage 1 — Intent |
| Version | Semantic doc version (1.0, 1.1, …) |
| Date / Last updated | Last-updated line notes what changed |
| Author(s) | Human + "AI-DLC Assistant" |
| Related Tickets | Jira/GitLab links |
| Related ADRs | "None at Intent stage" is a valid answer |
| Related QA Intent | Produced later in Verify |
| Source requirement | **Link to the BRD/PRD** this Intent derives from |
| Confluence / Repo target | Where this doc lives |

### §0 — Document purpose & relationship to the source
Short table answering: what is authoritative for business/UI detail; what this FI is for;
why it is shorter than the source (detail deferred to Design, not removed); who reads which
doc. Include an **honest assessment** note if a prior version was criticized (what was fixed).

### §1 — Problem & Context
Background, pain/opportunity, and a **source-phase table** if the BRD sequences delivery in
phases. Then **In scope** (initiative level) and **Out of scope** with explicit dispositions
(deferred / blocked-for-MVP / phased) — each tied to a decision in §8 where relevant.

### §2 — Goals & Non-Goals
Primary goals, secondary goals, non-goals for this Intent.

### §3 — Stakeholders & Users
Persona → needs table; technical owners.

### §4 — Functional Requirements (summary)
Organized by the source doc's phases/actors. **Summary depth only** — field-level specs
stay in the source. Include **representative edge cases** and **failure/session handling**
where they carry delivery risk (these are often not in the source and must be surfaced).

### §5 — Non-Functional Requirements
NFR table (security, compliance, performance, reliability, mobile, accessibility, …) plus a
**Data requirements** subsection (PII, storage, retention policy, import formats).

### §6 — Risks, Assumptions, Dependencies
Risk table (Risk | Likelihood | Impact | Mitigation); assumptions; dependencies.

### §7 — Acceptance Criteria & Success Metrics
Two distinct groups:
- **Intent-phase acceptance criteria** — lifecycle gates that prove the Intent phase is
  complete (checkbox list). NOT feature UAT.
- **Success metrics** — programme-level metric | target | measurement table.

### §8 — Review outcomes
- **§8.1 Confirmed decisions** — numbered decision log (`R1`, `R2`, …): Topic | Decision |
  FI impact. This is the durable record of what was agreed during review.
- **Comment disposition** — each source/inline comment → Confirmed / Partial / Deferred.
- **§8.2 Open / pending** — numbered (`P1`, `P2`, …): Topic | Status | Owner / next step.

### §9 — Validation & source traceability
- **§9.1 Validation record** — dated log: Date | Activity | Participants | Outcome. Include a
  direct response to any reviewer concern.
- **§9.2 Validation checklist** — `V1`–`Vn`: Item | Status | Evidence/owner.
- **§9.3 Source traceability** — Source area | FI section | Coverage (Covered / Deferred to
  Design / Out of scope) | Notes. Prove nothing was dropped silently.
- **§9.4 MVP / first delivery slice** — Build | In scope | Excluded, plus rationale. Marked
  "proposal — requires validation" until signed off.
- **§9.5 Value-add** — what this FI adds beyond the source (phased delivery, lifecycle AC,
  engineering risks, traceability/validation).

### Version history
Append-only table: Version | Date | Summary of changes.

## Backend notes
- **Confluence:** render the numbered sections as H2/H3; use panels for the honest-assessment
  and pending-items callouts; resolve inline comment threads as you merge them into §8.
- **GitLab:** same body in `intent.md`; put Document ID/Version/Source in YAML frontmatter.
- **Linear:** same body in the Initiative description; track pending items (`P#`) as sub-issues.
