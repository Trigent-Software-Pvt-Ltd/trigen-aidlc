# Intent Validation Workflow

> **Purpose:** Defines how `/aidlc-intent` validates a Feature Intent that derives from a
> source requirement, and how the validation is **recorded** in the document so the review
> is auditable. This is what turns an Intent from "a summary of the BRD" into "a validated
> delivery contract."

## Why this exists

A common, valid criticism of Intent docs: *"this is just another copy of the requirements —
was any additional validation actually performed?"* This workflow answers that by making the
validation **visible and dated** inside the document (§9.1/§9.2) and by capturing every
decision and open item (§8).

## The workflow

### 1. Ingest the source requirement
- Ask for the **source doc link** (BRD/PRD/Confluence page).
- Read it (fetch the page or read the file). Extract: actors, phases, in/out scope,
  NFRs, data/PII, integrations.
- Record the source **version** and date in the metadata header.

### 2. Draft against the standard
- Draft the Intent using `intent-doc-standard.md` section order.
- Populate **§9.3 source traceability** as you go: every source area gets a row with a
  coverage verdict (Covered / Deferred to Design / Out of scope). This makes silent drops
  impossible.

### 3. Propose the MVP slice
- Fill **§9.4**: what is in build 1 vs deferred, with a one-line rationale (usually
  "source surface area too large for one MVP"). Mark it **proposal — requires validation**.

### 4. Review round(s) — the validation gate
Share the full draft. Then run a review round:
- Collect feedback (workshop Q&A, Confluence inline comments, stakeholder notes).
- For each item, decide: **Confirmed** → add to **§8.1** as `R#`; **Pending** → add to
  **§8.2** as `P#` with an owner and next step; **Partial** → note both.
- Update the affected sections (scope, NFRs, edge cases) to reflect confirmed decisions.
- Record the round in **§9.1** (Date | Activity | Participants | Outcome) and bump the
  document **Version** with a "last updated" note.
- Resolve the corresponding source/inline comment threads once merged.

Repeat review rounds until no **blocking** `P#` items remain. Non-blocking items may carry
into Design/Verify.

### 5. Validation checklist sign-off
Complete **§9.2** (`V1`–`Vn`): source version confirmed; traceability done; stakeholder +
engineering review done; MVP slice reviewed; out-of-scope explicit; open questions have
owners; Intent-phase AC distinct from source; feedback addressed. Each item needs
evidence/owner.

### 6. Approval
Only mark **Status: Approved** when the checklist is complete (or remaining items are
explicitly non-blocking and dated). Approval is a **hard human gate** — answering clarifying
questions is not approval.

## Guardrails
- Never auto-close a `P#` item; require an owner decision.
- Never delete an out-of-scope item — record it as deferred/blocked with rationale so the
  decision is auditable.
- Keep §4 at summary depth; if you find yourself copying field-level rules from the source,
  stop and link to the source instead.

## Reviewer-concern response pattern
When a reviewer says "this is just the requirements again," respond in **§9.1** with:
(a) agree the source remains authoritative; (b) state what the FI adds (MVP cut, validation
trail, delivery AC, traceability); (c) point to the checklist showing what was and was not
validated.
