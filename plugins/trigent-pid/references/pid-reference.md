# PID Reference — Templates and Interview Guides

This file contains the interview guides and full Confluence page templates for the Trigent Project Initiation Document (PID). Reference this from SKILL.md during both the drafting and comment resolution workflows.

---

## Business Case Interview Guide

Ask questions conversationally across multiple turns. **Never present all rounds at once.** After each round, summarise what was captured and confirm before continuing. Adapt questions based on context already provided by the user.

### Round 1 — Project Basics
- What is the project name? (Will appear in the document title.)
- Does it have an informal nickname or shorthand? (Optional.)
- Describe the idea or feature in 2–3 sentences.
- What problem or opportunity does this address?
- Why now? What has changed that makes this the right moment?
- What evidence supports the need for this? Include any that apply: customer requests or feedback, support ticket volume, user research findings, NPS/CSAT data, win/loss analysis. *(If no formal validation exists, note how the need was identified and whether research is planned.)*

### Round 2 — Scope
- What high-level outcomes or capabilities are in scope? (Bullet list — don't over-specify at this stage.)
- What is explicitly out of scope? (Prevents misunderstandings during delivery.)

### Round 3 — Investment and Market
- What is the estimated investment required? (Rough order of magnitude is fine — e.g., "small/medium/large" or a ballpark figure.)
- Is this a one-time build cost, or does it carry ongoing operational costs? (e.g., third-party licences, infrastructure, support overhead.)
- Can the investment be phased? If so, what would Phase 1 deliver vs. later phases?
- Have you evaluated a build vs. buy option? What did you find?
- What is the expected ROI?
- Is there an addressable market size worth noting? (Optional — relevant for new product lines.)

### Round 4 — Strategic Alignment, Risks, and Success Metrics
- How does this initiative align with current company OKRs or strategic pillars? Does it tie to a specific roadmap theme or programme of work?
- What are the key business risks? For each: What is the risk? What is the potential impact? What's the mitigation? Who owns it?
- How will success be measured? What KPIs, OKRs, or outcomes define a successful outcome?

### Round 5 — Positioning
- How will this be positioned internally and/or externally?
- Does it affect the company's competitive position (SWOT)? If so, how?
- How might key competitors respond to this launch?
- What is the go-to-market or launch sequence? (Who hears about it first — existing customers, new prospects, internal teams, partners?)

### Round 6 — Alternatives Considered
- What other approaches did you evaluate before settling on this direction? (e.g., build vs. buy, different scope options, extending an existing feature, third-party solutions.)
- For each alternative: what made you consider it, and why was it ultimately rejected?
- Was a "do nothing" baseline considered? What are the consequences of not proceeding with this initiative?

### Round 7 — Logistics
- Is there a related Jira project or JPD issue to link?
- Any existing Confluence pages or prior research to reference in the document?
- Confirm the target Confluence space (default: `<CONFLUENCE_SPACE_KEY>`).

---

## Solution Design Interview Guide

Ask questions conversationally across multiple turns. **Never present all rounds at once.** This phase typically involves the Three Amigos — encourage the user to loop in Product, Engineering, and Design leads before completing this section.

### Round 1 — Team and Scale
- Who are the Three Amigos?
  - **Product Lead** (PM or PO): [name]
  - **Engineering Lead** (Tech Lead, Architect, or QA Lead): [name]
  - **Design Lead** (UX/UI Designer): [name]
- What is the scale of this project? Choose the best description:
  - Quick win aimed at [specific outcome]
  - MVP targeting [audience] with [core capabilities]
  - Full rewrite/refactor of [system or component]
  - Part of a larger programme: [programme name]
- Is this part of a larger programme of work? If so, what is the programme?

### Round 2 — Requirements and Solution Outline
- Expand on the business case: what specific problem are we solving, and what outcomes are expected from the engineering team?
- Describe the proposed solution approach at a high level.
- Is there a Figma file or wireframes to link?
- Are there flow diagrams, journey maps, or architecture diagrams already available?
- What is in scope for the solution? (May differ from the Business Case scope — clarify if so.)
- What is out of scope for the solution?

### Round 3 — Architecture, Technical Approach, and Data
- Describe the architecture in plain language (suitable for both technical and non-technical stakeholders).
- Is there a system architecture diagram to link?
- What are the key components? For each: component name, description, owner team.
- What are the integration points with other systems? For each: system name, purpose of the integration, integration method (API, event stream, DB, etc.), and any important notes.
- What is the proposed tech stack and tooling?
- **Data model:** What data does this feature create, read, modify, or delete? Describe the key entities and their relationships at a high level. Is there an existing schema this extends, or is this net-new?
- **Data retention / deletion:** Are there retention requirements or PII deletion obligations for the data this feature handles?
- **Migration (if applicable):** Does this feature touch existing data? If so, what's the approach — migration script, dual-write period, phased cut-over? Is the migration reversible?
- **Backwards compatibility:** Are existing API consumers or integrations affected? What's the compatibility period?

### Round 4 — Delivery Approach
- What are the key milestones or delivery vertical slices?
  - Note: slices should be defined so that informed scope decisions can be made if cost or time estimates are too high.
- What team roles are required? What is the recommended team size? Are there SME dependencies?
- What is the rollout plan? (Phased rollout, dark launch, feature flags, immediate GA, etc.)

### Round 5 — Testing Strategy
- What testing will be manual, and what will be automated?
- Is performance testing required? If yes, what is the rationale?
- Who owns testing for each area?

### Round 6 — Non-Functional Requirements
- **Security**: Any specific security requirements, compliance needs, or threat vectors to address?
- **Audit**: Do user or system actions need to be logged or traceable for compliance or debugging?
- **Alerting and Monitoring**: What needs to be monitored? What alerting thresholds or escalation paths are expected?
- **Performance**: Any specific performance targets, SLAs, or throughput expectations? What is the expected scale — concurrent users, record volume, requests per day?
- **Accessibility**: What WCAG compliance level is expected? Are there keyboard navigation or screen reader requirements? Are there specific user groups (e.g., students with disabilities, assistive technology users) whose needs must be accommodated?

### Round 7 — Risks, Dependencies, and Coordination
- What dependencies exist? (Other teams, backlog items, third-party systems or licenses, external APIs.)
- What risks, open issues, or assumptions need to be documented? For each: type (Risk/Issue/Assumption), description, owner, current resolution/status.
- How will progress be reported? (Weekly updates, dashboards, stand-up cadence, etc.)
- How will teams stay coordinated during delivery? (Slack channels, shared Confluence space, weekly syncs, etc.)
- Are there any known open questions that cannot be resolved before the SD is published? If so, capture them for the Open Questions section.

### Round 8 — Estimate and Enablement
- What is the revised delivery estimate? (After the team has reviewed scope and approach.)
- Which enablement activities are expected to be required?
  - Marketing materials
  - Sales enablement
  - Support documentation (KBAs)
  - Training materials
  - Customer communications

---

## Business Case Template (Section 1)

Use this template when generating the Business Case portion of the PID. Replace all `[placeholder]` values. Use `TBD — [what's needed]` for unknown fields — never omit a section.

```markdown
> ⚠️ **STATUS: DRAFT — Under Review.** This document has not yet been through the approval process. Do not distribute externally.

**Project Name:** [From document title]
**Project Nickname (Optional):** [Insert or remove this line]
**Related Jira Project:** [Insert link, or "TBD"]
**Related Initiatives:** [Links to related PIDs or EPD pages identified during cross-reference scan, or "None"]

---

# SECTION 1 — BUSINESS CASE

## 1. Description

[Provide a brief summary of the idea or feature — 2–4 sentences. What is it, and who does it serve?]

---

## 2. Objectives

[What problem or opportunity does this address? Why now? What change will this drive?]

- [Objective 1]
- [Objective 2]

---

## 3. Customer & User Validation

[What evidence supports the need for this initiative? Include any that apply.]

- **Customer feedback / requests:** [e.g., "17 enterprise customers have requested this feature in the last 6 months — tracked in JPD"]
- **Support ticket volume:** [e.g., "~40 tickets/month related to this pain point — see Jira filter [link]"]
- **User research findings:** [e.g., "Usability study (Nov 2024) identified check-in friction as the top admin complaint"]
- **NPS / CSAT data:** [e.g., "Low scores correlated with absence of this capability in quarterly exit surveys"]
- **Win / loss analysis:** [e.g., "3 deals lost in Q4 where Competitor X's equivalent feature was cited as a differentiator"]

_If no formal validation exists, note: "Validated informally through [channel]. Formal research planned for [timeframe]."_

---

## 4. Strategic Alignment

[How does this initiative connect to Trigent's current strategic priorities?]

- **OKR / Strategic Pillar:** [e.g., "Supports OKR: Increase district-level retention rate by 15% in FY26"]
- **Roadmap theme:** [e.g., "Aligns with 2025 roadmap theme: Operational Safety & Compliance"]
- **Programme context (if applicable):** [e.g., "Part of the Visitor Management modernisation programme" — or remove this line]

---

## 5. Scope

[List the high-level outcomes or capabilities in scope. Keep these at a capability level — not implementation detail.]

- [Scope item 1]
- [Scope item 2]

---

## 6. Out of Scope

[Clarify what is explicitly excluded. This section prevents misunderstandings and scope creep.]

- [Out-of-scope item 1]
- [Out-of-scope item 2]

---

## 7. Alternatives Considered

[What other approaches were evaluated before selecting this direction?]

| Alternative | Why Considered | Why Rejected |
| --- | --- | --- |
| [e.g., "Buy third-party solution"] | [e.g., "Faster time to market"] | [e.g., "Doesn't support our data model; cost prohibitive at scale"] |
| [e.g., "Extend existing feature"] | [e.g., "Lower investment"] | [e.g., "Technical debt makes this unviable without a full rewrite"] |
| [e.g., "Do nothing"] | [e.g., "Baseline comparison"] | [e.g., "Status quo creates ongoing churn risk and competitive disadvantage"] |

---

## 8. Investment Analysis

- **Estimated investment:** [Insert rough estimate — e.g., "Medium (3–6 months, 2–3 engineers)"]
- **Investment type:** [One-time build / Ongoing / Mixed — note any recurring costs such as licences, infrastructure, or support overhead]
- **Phased breakdown (if applicable):**
  - Phase 1: [e.g., "Core capability — 8 weeks"]
  - Phase 2: [e.g., "Advanced features — 6 weeks — can be deferred if needed"]
- **Build vs Buy:** [e.g., "Build — no suitable off-the-shelf solution identified" or "Buy evaluated and rejected — see Alternatives Considered above"]
- **ROI:** [Insert expected return — quantify where possible]
- **Addressable market (optional):** [Insert or remove]

---

## 9. Business Risks

| Risk | Impact | Mitigation | Owner |
| --- | --- | --- | --- |
| [Insert risk] | [High / Medium / Low] | [Insert mitigation approach] | [Insert owner name or team] |

---

## 10. Success Metrics

[How will success be measured? Include KPIs, OKRs, or qualitative outcomes.]

- [Success Metric 1 — e.g., "Reduce visitor check-in time by 50% within 3 months of launch"]
- [Success Metric 2]

---

## 11. Marketing Positioning

[How will this be positioned internally and externally? How does it affect Trigent's competitive position (SWOT)? How might competitors respond?]

[Insert narrative — 1–3 paragraphs.]
```

---

## Solution Design Template (Section 2)

Use this template when generating the Solution Design portion of the PID. Append this section after the Business Case content when updating the Confluence page.

```markdown
---

# SECTION 2 — SOLUTION DESIGN

## 1. Overview

### Assigned Amigos

| Role | Name |
| --- | --- |
| **Product Lead** (PM / PO) | [Insert] |
| **Engineering Lead** (Tech Lead / Architect / QA) | [Insert] |
| **Design Lead** (UX / UI) | [Insert] |

### Scale Statement

[Describe the size, complexity, and constraints of this effort. Examples:]
- _"Quick win aimed at [specific outcome]. Estimated 2 weeks."_
- _"MVP targeting [audience] with [core features]. Full feature set to follow in Phase 2."_
- _"Full rewrite of [system]. Part of the [programme name] programme."_

[Clarify if this is part of a larger programme of work.]

---

## 2. Solution Outline

### Requirements

[Expand on the Business Case — what specific problem is the engineering team solving, and what outcomes are expected?]

- [Requirement 1]
- [Expected outcome 1]

### Solution Overview

[High-level description of the approach — accessible to both technical and non-technical stakeholders. 2–4 paragraphs.]

### Designs (if applicable)

- Link to Figma / wireframes: [Insert link, or "Not yet available"]

### Flow Diagrams (if applicable)

- Link to diagrams: [Insert link, or "Not yet available"]

### In Scope (Solution)

[List what is in scope for the engineering solution. May differ from the Business Case scope — note any differences.]

- [In-scope item 1]

### Out of Scope (Solution)

- [Out-of-scope item 1]

---

## 3. Technical Approach

### Architecture Overview

[Describe the architecture in plain language. What are the major moving parts, and how do they fit together?]

**System Architecture Diagram:** [Insert link, or "TBD"]

### Key Components

| Component | Description | Owner |
| --- | --- | --- |
| [Insert] | [Insert] | [Insert team or person] |

### Integration Points

| System | Purpose | Method | Notes |
| --- | --- | --- | --- |
| [Insert] | [Insert] | [API / Event / DB / etc.] | [Insert] |

### Data Model

[Describe the key data entities this feature introduces or modifies.]

| Entity | Description | Key Fields | Data Owner |
| --- | --- | --- | --- |
| [e.g., "VisitorSession"] | [e.g., "A single visitor check-in event"] | [e.g., "id, visitor_id, location_id, checked_in_at, checked_out_at"] | [e.g., "Visitor Management team"] |

**Data diagram:** [Insert link to ER diagram or data model, or "TBD"]

**Data retention / deletion:** [e.g., "Session records retained for 7 years per compliance requirement; PII purged on customer request"]

_If this feature creates no new data and modifies no existing schema, note: "No data model changes — feature operates entirely on existing entities."_

### Data Migration & Backwards Compatibility

_If this is a net-new feature with no impact on existing data or APIs, note that and skip the rest of this section._

- **Existing data affected:** [e.g., "~2.4M visitor records in legacy format require migration"]
- **Migration approach:** [e.g., "Background migration script; dual-read during transition period"]
- **Backwards compatibility:** [e.g., "API v1 endpoints maintained for 90 days post-launch; deprecated with advance notice"]
- **Rollback plan:** [e.g., "Migration script is reversible; feature is flag-gated until stable"]
- **Zero-downtime required:** ☐ Yes  ☐ No — **Rationale:** [Insert]

### Tech Stack / Tools

- [Technology 1 — e.g., "Ruby on Rails (backend)"]
- [Technology 2 — e.g., "React (frontend)"]
- [Tool — e.g., "Sidekiq (async jobs)"]

---

## 4. Delivery Approach

### Milestones / Delivery Breakdown

[Define key delivery milestones or vertical slices of work. Each slice should be scoped so that informed decisions about reducing scope can be made if estimates are too high.]

| Milestone | Description | Target |
| --- | --- | --- |
| [Insert] | [Insert] | [Date or sprint] |

### Delivery Teams

[What roles are required? Recommended team size? Call out any SME dependencies.]

[Insert narrative — e.g., "2 backend engineers, 1 frontend engineer, 1 QA engineer. Dependency on the Platform team for [X]."]

### Rollout Plan

[Describe how the solution will be released — phased rollout, dark launch, feature flags, immediate GA, etc.]

[Insert]

---

## 5. Test Approach

### Manual vs Automated Testing

- **Manual:** [Insert — e.g., "Exploratory testing of edge cases, accessibility checks"]
- **Automated:** [Insert — e.g., "Unit tests, integration tests, E2E regression suite"]

### Performance Testing Required?

☐ Yes  ☐ No

**Rationale:** [Insert]

### Testing Ownership

| Area | Responsible Team |
| --- | --- |
| [Insert — e.g., "Unit tests"] | [Insert team] |
| [Insert — e.g., "QA / regression"] | [Insert team] |

---

## 6. Non-Functional Requirements

### Security

[Insert — e.g., "All API endpoints must require authenticated sessions. PII is not stored in this feature."]

### Audit

[Insert — e.g., "All check-in events must be logged with timestamp, operator ID, and visitor ID for compliance."]

### Alerting & Monitoring

[Insert — e.g., "Error rate alerts on the check-in endpoint. PagerDuty escalation for P1 alerts."]

### Performance

[Insert — e.g., "Check-in response time < 500ms at p95 under normal load."]

**Scale context:** [e.g., "Normal load defined as ~500 concurrent users across ~2,000 active districts."]

### Accessibility

- **WCAG compliance target:** [e.g., "WCAG 2.1 Level AA"]
- **Keyboard navigation required:** ☐ Yes  ☐ No
- **Screen reader support:** [e.g., "Must be compatible with JAWS and NVDA for all admin-facing flows"]
- **Colour contrast:** [e.g., "All text meets minimum 4.5:1 contrast ratio"]
- **Notes:** [e.g., "Student-facing flows require full a11y compliance; internal admin-only flows require keyboard navigation as a minimum"]

---

## 7. Dependencies

| Dependency | Type | Notes |
| --- | --- | --- |
| [Insert — e.g., "Platform team API changes"] | [Team / Backlog / External] | [Insert] |

---

## 8. Risks / Issues / Assumptions

| Type | Description | Owner | Resolution / Status |
| --- | --- | --- | --- |
| Risk | [Insert] | [Insert] | [Insert] |
| Issue | [Insert] | [Insert] | [Insert] |
| Assumption | [Insert] | [Insert] | [Insert] |

---

## 9. Communication Plan

### Progress Reporting

- [Insert — e.g., "Weekly written update in the #[project-channel] Slack channel"]

### Inter-team Comms

- [Insert — e.g., "Bi-weekly sync with Platform team for dependency coordination"]

---

## 10. Estimate

### Revised Estimate

[Insert — e.g., "12 weeks, team of 4 (2 BE, 1 FE, 1 QA). Assumes dependencies resolved by Week 2."]

---

## 11. Enablement Checklist

☐ Marketing materials
☐ Sales enablement
☐ Support documentation (KBAs)
☐ Training materials
☐ Customer communications

[Add notes against each item if scope is known — e.g., "KBAs: 2 articles needed covering new check-in flow for admins."]

---

## 12. Open Questions

_Track known unknowns that cannot be resolved before publication. Each question should have an owner and a target resolution date. Resolve before delivery begins where possible._

| Question | Owner | Target Resolution | Status |
| --- | --- | --- | --- |
| [e.g., "Do we need SOC 2 evidence for this integration point?"] | [e.g., "Security team"] | [e.g., "2025-03-15"] | [Open / In Progress / Resolved] |
```

---

## Confluence Storage Reference

| Location | Purpose | Parent Page ID |
|----------|---------|----------------|
| Business Cases — In Review | New draft PIDs and Business Cases pending ELT approval | `<PID_PARENT_PAGE_ID>` |
| Approved Projects | Business Cases and full PIDs approved by ELT | `1401716737` |
| Rejected | Rejected Business Cases | `1685389313` |

**Space key**: `<CONFLUENCE_SPACE_KEY>`
**Space ID**: `<CONFLUENCE_SPACE_ID>`
**Cloud ID**: Retrieve at runtime via `getAccessibleAtlassianResources()`
**PID template page** (reference only, do not create child pages under it): `2147942594`

### Page Title Convention

`[Project Name] — Project Initiation Document`

Example: `Visitor Management Rewrite — Project Initiation Document`

### Page Moves

Confluence folder moves must be performed in the Confluence UI (drag-and-drop in the page tree, or via page settings → Move). Inform the user:
- **After BC approval**: Move from In Review (`<PID_PARENT_PAGE_ID>`) → Approved Projects (`1401716737`)
- **After rejection**: Move to Rejected (`1685389313`)
- **If further info needed**: Page remains in In Review until re-submitted

### Linking to JPD

Projects with a PID are typically also tracked in Jira Product Discovery (JPD). Remind the user to link the Confluence page to the relevant JPD issue after publishing.
