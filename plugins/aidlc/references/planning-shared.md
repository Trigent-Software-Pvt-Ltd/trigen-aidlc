# AI-DLC Planning Shared Guidance

Use this reference for the AI-DLC Feature → Epic planning flow. Supports three backends: **GitLab** (markdown files with MR review), **Linear** (native Initiatives/Projects/Issues), and **Confluence** (pages with Jira). See @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md for backend selection and detection logic.

## Human-in-the-loop Gates

- Confirm understanding before drafting.
- Get explicit approval before creating artifacts (GitLab files, Linear Initiatives, or Confluence pages).
- Get explicit approval before creating work tracking items (Jira issues or Linear Issues).
- Do not create Bugs unless explicitly requested by a human.

## Confluence Feature Template

- Feature Summary
- Document Metadata (table) — Document ID | Status | AI-DLC Stage | Version | Last updated | Author(s); Source requirement (link to BRD/PRD, when source-derived); Related ADRs | Related QA Intent | Confluence/Repo target
- Relationship to Source Document (§0, only when a source doc exists) — what is authoritative for business/UI detail (the source); what this Intent is for (delivery contract, not a second BRD); honest assessment if a prior version was revised. See `intent-doc-standard.md`.
- Problem / Opportunity
- Target Users
- Assigned Amigos
  - Product Owner
  - Tech Lead
  - Design Lead
- Initiative Profile
  - Pathway (green-field | brown-field | modernization | defect fix)
  - Scale (quick win | bounded delivery | strategic initiative)
  - Constraints (timeboxed, budget-limited, MVP-only, etc.)
  - Programme context (standalone | part of <programme name>)
- Project Type
  - Auto-detected from codebase markers (see `references/technical-guidance/`)
  - Supported: .NET, Rails, Vue (more stacks planned)
  - Override if auto-detection is wrong
- Outcomes (Business + User)
- Scope
  - In scope
  - Out of scope
- Technical Considerations
  - Known technical constraints
  - Integration points (high-level)
- Service Inventory
  | Service | Pathway | Repo Link |
  |---------|---------|-----------|
  | <name> | Green-field / Brown-field | <path, URL, or "(new)"> |
- Technical Guidance (project-level overrides and constraints)
  - Approved technologies (required or prohibited)
  - Architectural patterns (patterns to use or avoid)
  - Security requirements (beyond global standards)
  - Integration standards (APIs, protocols, data formats)
  - Performance targets (specific to this project)
  - Deviations from standards (with rationale)
- Designs & Diagrams (if available)
  - UI mockups / wireframes / prototypes
  - Flow diagrams (system or process)
- Non-Functional Requirements (NFRs)
- Measurement Criteria (OKR/KPI/SLI)
- Dependencies
- Risks (use Organizational Risk Taxonomy below; prioritize Data & Privacy and Security Posture)
- Assumptions
- Testing Strategy (see Testing Strategy Guidance below)
- Communication Plans
  - Progress Reporting Plan (how progress is tracked/reported)
  - Inter-team Comms Plan (shared channels, joint stand-ups, scrum of scrums)
- Enablement Checklist
  - [ ] Marketing materials needed?
  - [ ] Sales enablement needed?
  - [ ] Support flows / KBAs needed?
  - [ ] Training materials needed?
  - [ ] Customer comms needed?
- Open Questions
- Review Outcomes (§8, when reviewed) — Confirmed Decisions log (# | Topic | Decision | FI impact, R1…); Comment disposition (Confirmed/Partial/Deferred); Open/Pending (# | Topic | Status | Owner/next step, P1…)
- Validation & Source Traceability (§9, when source-derived) — Validation record (Date | Activity | Participants | Outcome); Validation checklist (V# | Item | Status | Evidence/owner); Source traceability (Source area | FI section | Coverage | Notes); MVP / first delivery slice (Build | In scope | Excluded | Rationale); Value-add vs source. See `intent-doc-standard.md` and `intent-validation-workflow.md`.
- Proposed Epics (hypotheses only)
- Version History (Version | Date | Summary of changes)
- Workflow Status (see Workflow Status Tracking below)

## GitLab Feature Template

When using the GitLab backend, the Feature is stored as `intent.md` with YAML frontmatter. Use this template:

```yaml
---
type: feature
backend: gitlab
project: "<Project Name>"
feature_number: 1
title: "<Feature Title>"
status: draft
created: YYYY-MM-DD
jira_project_key: null
mr_url: "<MR URL>"
---
```

The body content follows the same structure as the Confluence Feature Template above (Summary, Problem/Opportunity, Target Users, etc.) but in markdown format.

See @${CLAUDE_PLUGIN_ROOT}/references/backends/gitlab.md for full file templates including epics, tasks, design docs, and ADRs.

## Linear Feature Template

When using the Linear backend, the Feature is stored as a Linear Initiative. Create via `save_initiative`:

- **name**: "Feature: \<Title\>"
- **description**: Feature markdown content (same sections as Confluence template)
- **status**: "Planned" (then "Active" when approved)
- **owner**: Current user or "me"

See @${CLAUDE_PLUGIN_ROOT}/references/backends/linear.md for full Linear object mapping and MCP tool usage.

## Source Traceability Matrix (Feature)

Use when the Feature Intent derives from a source requirement document (BRD/PRD). Prove every source area has an explicit disposition — nothing dropped silently.

| Source area (from BRD/PRD) | FI section | Coverage | Notes |
|----------------------------|-----------|----------|-------|
| <e.g. Executive summary & actors> | §1–§3 | Covered (summary) | Detail in source |
| <e.g. Phase 1 — Create/Edit job>  | §4     | Deferred to Design | Field rules in source |
| <e.g. Integrations (SSO, WhatsApp)> | §1 out of scope / §6 | Out of MVP / phased | — |

Coverage vocabulary: **Covered** | **Deferred to Design** | **Out of scope**.

## Review Outcomes (Feature)

### Confirmed decisions
| # | Topic | Decision | FI impact |
|---|-------|----------|-----------|
| R1 | <topic> | <what was agreed> | <sections changed> |

### Comment disposition
| Comment topic | Status |
|---------------|--------|
| <inline comment> | Confirmed → R# / Partial / Deferred |

### Open / pending
| # | Topic | Status | Owner / next step |
|---|-------|--------|-------------------|
| P1 | <topic> | Pending / Partial | <owner> |

## Validation Record (Feature)

| Date | Activity | Participants | Outcome |
|------|----------|--------------|---------|
| YYYY-MM-DD | <review / workshop / remediation> | <names> | <result> |

### Validation checklist
| ID | Item | Status | Evidence / owner |
|----|------|--------|------------------|
| V1 | Source version confirmed | Done/Pending | <link> |
| V2 | Source traceability complete | Done/Pending | <ref> |
| V3 | Stakeholder + engineering review | Done/Pending | <ref> |
| V4 | MVP slice reviewed | Done/Pending | <ref> |
| V5 | Out-of-scope explicit | Done/Pending | <ref> |
| V6 | Open questions have owners | Done/Pending | <ref> |
| V7 | Intent-phase AC distinct from source | Done/Pending | <ref> |
| V8 | Review feedback addressed | Done/Pending | <ref> |

## MVP / First Delivery Slice (Feature)

| Build | In scope | Excluded from this build |
|-------|----------|--------------------------|
| MVP-A | <core slice> | <deferred capabilities> |
| Rationale | <why this cut> | |

Mark "proposal — requires validation" until signed off at the validation session.

## Workflow Status Tracking

Track progress through the AI-DLC workflow. The method depends on the backend:

- **GitLab**: YAML frontmatter `status` field + Workflow Status table in `intent.md`
- **Linear**: Initiative/Project/Issue status fields
- **Confluence**: Status table in the Confluence doc + labels on Jira artifacts

### GitLab Status Tracking

In `intent.md` frontmatter, update the `status` field:
- `draft` → `approved` (after Feature approval)

Include a Workflow Status table in the markdown body:

| Phase | Status | Date | Notes |
|-------|--------|------|-------|
| Feature | Draft | \<date\> | MR !\<ID\> |
| Elaborate | Pending | - | - |
| Design | Pending | - | - |
| Verify | Pending | - | - |

### Linear Status Tracking

Use native Linear status fields:
- **Initiative**: "Planned" → "Active" → "Completed"
- **Project**: "Planned" → "Started" → "Completed"
- **Issue**: "Backlog" → "Todo" → "In Progress" → "Done"

### Confluence Status Table

Include this table in the Level 1 Feature document:

| Phase | Status | Date | Artifact |
|-------|--------|------|----------|
| Project | ⏳ Pending | - | - |
| Feature | ⏳ Draft | - | - |
| Epic Decomposition | ⏳ Pending | - | - |
| Domain Design | ⏳ Pending | - | - |
| Verification | ⏳ Pending | - | - |

**Status values:**
- ⏳ Draft / Pending — Not started or in progress
- ✅ Approved / Complete — Phase finished
- 🔄 In Progress — Actively being worked
- ❌ Blocked — Waiting on dependency or decision

### Jira Labels

Add labels to Jira artifacts to identify their AIDLC type:
- `aidlc:project` — Project
- `aidlc:feature` — Feature
- `aidlc:epic` — Epic
- `aidlc:story` — Story
- `aidlc:sprint` — Sprint (scheduling grouping)
- `aidlc:designed` — Domain design complete for this Epic

### Skill Responsibilities

Each skill updates the workflow status for the relevant backend:

**GitLab:**
- `/aidlc-intent`: Update frontmatter `status: approved`, status table "Feature: ✅ Approved"
- `/aidlc-elaborate`: Update status table "Epic Decomposition: ✅ Complete", commit epic/task files
- `/aidlc-design`: Update status table "Domain Design: ✅ Complete", commit design files
- `/aidlc-verify`: Update status table "Verification: ✅ Complete", update frontmatter with Jira keys

**Linear:**
- `/aidlc-intent`: Update Initiative status to "Active"
- `/aidlc-elaborate`: Create Projects (Epics) and Issues (Tasks) under Initiative
- `/aidlc-design`: Create "Design Doc" labeled Issues
- `/aidlc-verify`: Update Initiative/Project statuses (no Jira transfer needed)

**Confluence:**
- `/aidlc-intent`: Set "Feature: ✅ Approved"
- `/aidlc-elaborate`: Set "Epic Decomposition: ✅ Complete" (Epics remain in Confluence)
- `/aidlc-design`: Set "Domain Design: ✅ Complete"
- `/aidlc-verify`: Set "Verification: ✅ Complete", create Jira artifacts with appropriate labels

## Prerequisite Validation

Before proceeding with any skill (except `/aidlc-intent`), validate that prerequisites are met. The validation method depends on the detected backend.

### Validation Steps

1. **Check for required artifacts** (backend-specific)
   - **GitLab**: Check Feature branch exists, read `intent.md` frontmatter
   - **Linear**: Fetch Initiative via `get_initiative`, check status
   - **Confluence**: Fetch page via Atlassian MCP, check status table

2. **Check workflow status**
   - **GitLab**: Read frontmatter `status` field and Workflow Status table
   - **Linear**: Check Initiative/Project status fields
   - **Confluence**: Verify prior phases show "✅ Approved" or "✅ Complete"

3. **Handle missing prerequisites**
   - If artifacts don't exist: Offer to run the prior skill first
   - If status shows incomplete: Warn and ask for explicit confirmation to proceed
   - Allow override for recovery scenarios (e.g., resuming after interruption)

### Prerequisite Matrix

| Skill | GitLab Artifacts | Linear Artifacts | Confluence Artifacts | Required Status |
|-------|-----------------|------------------|---------------------|-----------------|
| `/aidlc-intent` | None (first step) | None | None | — |
| `/aidlc-elaborate` | `intent.md` on branch | Initiative exists | Confluence Feature doc | Feature approved |
| `/aidlc-design` | Epic `.md` files | Projects (Epics) | Epics Overview + Epic pages | Elaboration complete (Epics) |
| `/aidlc-verify` | Design docs in `design/` | Design Doc Issues | Design pages | Design complete (recommended) |

### Override Pattern

When prerequisites are incomplete but user wants to proceed:

```
⚠️ Prerequisites incomplete:
- [Missing artifact or status]

This may indicate a skipped step. Options:
1. Run [prior skill] first (recommended)
2. Proceed anyway (I have the artifacts elsewhere)
3. Cancel

Select an option to continue.
```

## Jira Artifact Hierarchy

When transferring from Confluence to Jira, use this hierarchy:

```
Project ← Optional top-level container
└── Feature
    └── Epic
        └── Story
            └── Task / Sub-task
```

**Sprint** is a scheduling grouping of Stories/Tasks within an Epic — it is not a hierarchy level. Sprints group related Stories/Tasks for scheduling and are tracked separately from the parent hierarchy.

### Jira Issue Types and Labels

| Jira Issue Type | Label |
|-----------------|-------|
| Project | `aidlc:project` |
| Feature | `aidlc:feature` |
| Epic | `aidlc:epic` |
| Story | `aidlc:story` |
| Task / Sub-task | — |
| Sprint (scheduling grouping) | `aidlc:sprint` |

## Jira Project (Initiative) Template

- Summary: "<Project Name>"
- Description:
  - Project overview
  - Related Features (links to child Features)
  - Link to programme or portfolio context (if applicable)
- Label: `aidlc:project`
- Issue Type: Initiative (Advanced Roadmaps)

**Note:** Project creation is optional. Features can exist as standalone Jira Features or be grouped under a Project for portfolio-level tracking.

## Jira Feature Template

- Summary: "<Feature Name>"
- Description:
  - Feature Summary (brief overview)
  - Problem / Opportunity (condensed)
  - Target Users
  - Outcomes (business + user outcomes)
  - Scope Summary (in scope / out of scope)
  - NFRs (table format)
  - Key Risks (top 3-5, table format)
  - Measurement Criteria (OKR/KPI)
  - Link to full Feature Confluence doc
- Label: `aidlc:feature`
- Parent: Project (Initiative) if exists

**Template for Feature description:**

```markdown
## Feature Summary

<1-2 paragraph summary>

## Problem / Opportunity

<Brief description of the problem being solved>

## Target Users

<User personas>

## Outcomes

**Business:** <business outcomes>
**User:** <user outcomes>

## Scope

**In scope:** <bullet list>
**Out of scope:** <bullet list>

## NFRs

| Category | Requirement | Target |
|----------|-------------|--------|
| Performance | ... | ... |

## Key Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| ... | ... | ... |

## Measurement Criteria

<OKRs/KPIs>

---

📄 **Full Feature Document:** [Confluence Link]
```

## Jira Epic Template

- Summary: "Epic: <Epic Name>"
- Description:
  - Scope summary
  - Acceptance criteria (use checkbox format: `- [ ] Criterion`)
  - NFRs specific to the Epic (use table: Category | Requirement | Target)
  - Risks (use table: Risk | Impact | Likelihood | Mitigation)
  - Dependencies (use bulleted list with references)
  - Testing approach (which test types apply, test environment needs)
  - ADR links/references (if design documentation exists)
  - Design document links (domain model, context maps)
  - Link to Feature Confluence doc
- Label: `aidlc:epic`
- Parent: The Feature

See **Template Standardization** section for format details.

## Jira Sprint Template

- Summary: "Sprint: <Sprint Description>"
- Description:
  - Scope summary (what this Sprint delivers)
  - Phase and Lane assignment (e.g., "Phase 1, Lane A")
  - Tasks included (list of child Tasks)
  - Dependencies (other Sprints — blocks/blocked by with Jira keys)
  - Whether on the critical path (yes/no)
  - Team assignment (if specified)
  - Estimated duration
- Parent: The Epic
- Label: `aidlc:sprint`

## Jira Task Template

- Summary: "<Verb> <Outcome>" (from `title` field)
- Description:
  - Task ID and size: `<id> · Size: <size>`
  - Behaviour (checkbox format: `- [ ] <behaviour item>`)
  - Rules (if present — hard constraints as bulleted list)
  - Files: modify/create/reference lists (if present)
  - Dependencies (if present — bulleted list: `[<type>] <what> — <rationale>`)
  - Risks (if present — bulleted list with mitigation)
  - Not in Scope (if present — bulleted list)
- Parent: The Sprint

**Format detection (backward compatibility):** If a task was created in user story format (contains "As a..." or "Given/When/Then"), map it as: user story → Summary context; acceptance criteria → description checklist. Supported through AIDLC 3.9.x.

See **Template Standardization** section for format details.

## Task Page Template (Confluence)

Use this template when creating Task pages in Confluence. Each Task is a child page under its Epic page. Tasks are created during the design phase, not the elaborate phase.

**Page Title**: `<Task Title>` (this becomes the Jira task summary when transferred)

**Page Content**:

```markdown
**Status**: Draft | Approved | Transferred
**Task ID**: <id, e.g. U01-T03>
**Size**: <size> (Fibonacci)
**Sprint**: <sprint id>

## Behaviour

- [ ] <Observable outcome 1>
- [ ] <Observable outcome 2>
- [ ] <Observable outcome 3>

## Rules

- <Hard constraint derived from NFR or design decision>
- <Hard constraint>

## Files

**Modify:**
- `<path to existing file>`

**Create:**
- `<path to new file>`

**Reference:**
- `<path to pattern/context file>`

## Dependencies

- [<blocking|non-blocking>] <what this depends on> — <rationale>

## Risks

- <Risk description> — mitigate: <mitigation approach>

## Not in Scope

- <Explicit boundary item>
```

**Note**: `Rules`, `Files`, `Dependencies`, `Risks`, and `Not in Scope` sections are omitted when empty. When transferred to Jira, the page title becomes the Task summary and the body becomes the description.

**Format detection (backward compatibility):** Task pages in user story format (containing "As a..." or "Given/When/Then") are valid through AIDLC 3.9.x. Process them using the legacy Jira Task Template mapping.

## Epics Overview Page Template (Confluence)

Use this template for the Epics Overview page in Confluence. This page is a child of the Feature document.

**Page Title**: `Epics Overview`

**Page Content**:

```markdown
**Feature**: <Feature Name>
**Date**: <Creation date>
**Status**: Draft | In Review | Approved | Transferred

## Epic Summary

| Epic | Dependencies | Open Questions |
|------|--------------|----------------|
| <Epic 1 Name> | <list> | <count> |
| <Epic 2 Name> | <list> | <count> |

*(Task counts and sprint plan are produced during `/aidlc-design` and added to this page after that phase completes)*

---

## Proposed Sprints

*(Populated during `/aidlc-design` — not available at elaborate time)*

### Sprint Summary

| Sprint | Epic | Phase | Lane | Dependencies | Tasks | Est. Duration |
|------|------|-------|------|--------------|-------|---------------|
| Sprint 1.1 | Epic 1 | 0 | A | — | T01, T02, T03 | X hours/days |
| Sprint 2.1 | Epic 2 | 0 | B | — | T01, T02 | X hours/days |
| Sprint 1.2 | Epic 1 | 1 | A | Sprint 1.1 | T04, T05 | X hours/days |

### Sprint Execution Plan

*Initial proposal — phases, lanes, and critical path refined during `/aidlc-verify`.*

#### Phase 0: Foundation
*Setup, scaffolding, and shared infrastructure that all other Sprints depend on.*

| Lane | Sprint | Epic | Summary | Depends On |
|------|------|------|---------|------------|
| A | Sprint 1.1 | Epic 1 | <Scope description> | — |
| B | Sprint 2.1 | Epic 2 | <Scope description> | — |

**Tasks:** <List of Tasks in this phase>

---

#### Phase 1: Core Domain
*Primary domain logic and data models.*

| Lane | Sprint | Epic | Summary | Depends On |
|------|------|------|---------|------------|
| A | Sprint 1.2 | Epic 1 | <Scope description> | Sprint 1.1 |

**Tasks:** <List of Tasks in this phase>

---

#### Critical Path

`Sprint 1.1 → Sprint 1.2 → ...`

#### Parallelism Opportunities

| Phase | Max Parallel Sprints | Teams Needed |
|-------|-------------------|--------------|
| Phase 0 | 2 | 2 |
| Phase 1 | 1 | 1 |

---

## Team Size Recommendation (Preliminary)

*This estimate is produced at elaborate time based on Epic count and inter-epic coupling. It is refined during `/aidlc-design` once the sprint plan exists with actual lane/phase data, and validated during `/aidlc-verify`. If the design estimate differs by more than 30% in person-weeks, the user is asked to confirm before Jira transfer.*

| Metric | Value |
|--------|-------|
| Epic count | <count> |
| Inter-epic coupling | Low / Medium / High |
| Pathway complexity | Simple / Moderate / Complex |
| Total work estimate (rough) | <N> person-weeks |

### Preliminary Recommendation: <N> engineers

**Rationale:**
- Peak parallelism is <N> (Phase <X>), but weighted average across all phases is <N.N>
- <Coupling level> coupling discount (×<factor>) → <N.N> effective parallelism
- Phase 0 capped at 2 engineers → weighted average recalculates to <N.N>
- Rounded up: <N> engineers
- Specialist floor (<list specialisms>): <N> — satisfied

### Scaling Options

| Engineers | Est. Duration | Utilisation | Trade-off |
|-----------|--------------|-------------|-----------|
| 1 | <N> days | ~<N>% | No coordination overhead, but serial |
| 2 | <N> days | ~<N>% | Good for small experienced teams |
| **<recommended>** | **<N> days** | **~<N>%** | **Recommended — good parallelism, manageable coordination** |
| <max> | <N> days | ~<N>% | Full parallelism, idle time in most phases |

*Utilisation ≈ total_work / (engineers × duration). Lower = more idle time per engineer.*

### Phase Staffing Guide

| Phase | Lanes | Recommended | Notes |
|-------|-------|-------------|-------|
| Phase 0 | <N> | <N> | Foundation — establish patterns with small group |
| Phase 1 | <N> | <N> | <Notes> |

*See Team Size Recommendation Rubric in planning-shared.md for calculation details.*

---

## Dependency Graph

```
Epic 1: <Name>
    │
    ├──► Epic 2: <Name>
    │        │
    │        └──► Epic 3: <Name>
    │
    └──► Epic 4: <Name>
```

---

## Key Technical Decisions

- <Decision 1>
- <Decision 2>

---

## Decomposition Notes

Decisions made during elaboration where the structural scan contradicted the service inventory:

| Finding | Decision | Feature Updated? |
|---------|----------|-----------------|
| <what was found vs. what was expected from inventory> | <what was decided> | Yes / No |

*This section may be empty if no inventory contradictions were found during elaboration.*

---

## Cross-Cutting Acceptance Criteria

- [ ] <Criterion that applies to all Epics>
- [ ] <Criterion that applies to all Epics>

---

## Links

- [Feature](<Confluence link>)
```

## Epic Page Template (Confluence)

Use this template for Epic pages in Confluence. Each Epic page is a child of the Epics Overview page.

**Page Title**: `Epic <N>: <Epic Name>`

**Page Content**:

```markdown
**Status**: Draft | In Review | Approved | Transferred

## Problem Statement

<What specific aspect of the Feature's problem does this epic address?>

## Target Users

<Who benefits from this epic's output?>

## Scope

### In Scope

- ...

### Out of Scope

- ...

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|-------------|

## Acceptance Criteria

- [ ] <Criterion 1>
- [ ] <Criterion 2>

## Indicative Tasks

Suggested breakdown for sizing and planning purposes. Refined during `/aidlc-design`.

| # | Description | Size | Sprint |
|---|-------------|------|------|
| 1 | ... | M | 1 |

> Sizes: XS / S / M / L / XL / XXL — rough effort estimate, not a commitment.

*(Task Specification child pages created during `/aidlc-design`)*

## Dependencies

- **Depends on:** [Epic: <Name>] <reason>
- **External:** <third-party or team dependency>

## Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| <Risk specific to this Epic> | High/Medium/Low | High/Medium/Low | <Mitigation> |

## Open Questions

- ...
```

## Organizational Risk Taxonomy

Surface risks aligned to these categories. Prioritize **Data & Privacy** and **Security Posture** — these are critical for our organization.

### Data & Privacy (Critical)
- **Sensitive data exposure** — unintended access to PII, PHI, credentials, or business-critical data
- **Data residency violations** — data leaving approved regions or jurisdictions
- **Retention policy violations** — keeping data longer than permitted
- **PII/PHI in logs or errors** — sensitive data leaking into observability systems
- **Non-prod data masking gaps** — production data in dev/test without adequate masking

### Security Posture (Critical)
- **3rd party library introduction** — new dependencies increase supply chain attack surface; require security review
- **CVE exposure** — changes that introduce or fail to remediate known vulnerabilities
- **RBAC/permission changes** — new permissions, roles, or access patterns require explicit review
- **Secrets exposure** — API keys, credentials, tokens in code, config, or logs
- **Auth bypass paths** — changes that could allow authentication or authorization circumvention
- **Injection vectors** — SQL, command, XSS, SSRF, or other injection vulnerabilities
- **Audit logging gaps** — missing audit trail for sensitive operations (compliance/forensics)

### Compliance
- **Regulatory control gaps** — SOC2, HIPAA, GDPR, or other framework control failures
- **Consent mechanism changes** — modifications to user consent or opt-out flows
- **Audit trail completeness** — changes affecting compliance evidence collection

### Operational
- **Rollback capability** — can the change be quickly reverted if issues arise?
- **Observability blind spots** — can we detect and diagnose issues post-deployment?
- **Availability/SLA impact** — risk of service degradation or downtime
- **Backward compatibility** — breaking changes to APIs, schemas, or contracts
- **Infrastructure cost** — unexpected cost increases from resource consumption

### Delivery
- **External dependency risk** — reliance on external services, vendors, or deprecated APIs
- **Knowledge concentration** — single point of failure on team (bus factor)
- **Integration complexity** — underestimated effort for cross-system changes
- **Scope uncertainty** — unclear requirements leading to rework

## Risk Surfacing Prompts

Use these prompts to elicit risks during Feature and Epic planning:

- Does this change introduce or modify access to sensitive data?
- Are new 3rd party libraries or services being introduced?
- Does this change RBAC, permissions, or authentication flows?
- Are there known CVEs in dependencies this change touches?
- What could cause unintended data exposure?
- What could materially delay delivery?
- What could cause rework or scope churn?
- What operational risks apply (availability, cost, observability)?
- What dependencies are least certain?
- Can this change be rolled back quickly if needed?

## Technical Guidance Hierarchy

The `/aidlc-design` skill incorporates technical guidance from up to three tiers:

### Tier 1: Global Guidance (Baseline)

**Source:** `references/technical-guidance/global.md`
**Owner:** Architecture Guild
**Applies to:** All projects

Universal standards:
- Security (authentication, secrets, OWASP)
- Observability (logging, metrics, tracing)
- API design (REST conventions, error formats)
- Data governance (classification, PII handling)
- Testing (pyramid, coverage targets)
- Resilience (timeouts, retries, circuit breakers)

### Tier 2: Stack-Specific Guidance

**Source:** `references/technical-guidance/<stack>.md`
**Owner:** Respective technology chapter
**Applies to:** Projects matching the stack's detection markers

Each guidance file defines `detection-markers` in its frontmatter. The `aidlc-design` skill
scans the repository for these markers to determine which stack guidance to load.

| Stack | File | Detection Markers |
|-------|------|-------------------|
| .NET | `dotnet.md` | *.csproj, *.sln, *.slnx, *.cs, global.json |
| Rails | `rails.md` | Gemfile, config/routes.rb, bin/rails, config/application.rb |
| Vue | `vue.md` | package.json with "vue" dependency, vite.config.ts, *.vue files |

Stack-specific guidance extends (never replaces) global guidance. Examples of what
stack files cover: package management, framework conventions, testing tools, project
structure, and preferred libraries.

### Tier 3: Project-Level Guidance (Feature-Specific)

**Source:** Confluence Feature doc "Technical Guidance" section
**Owner:** Project tech lead
**Applies to:** This project only

Project-specific constraints and overrides:
- Approved/prohibited technologies
- Required architectural patterns
- Integration standards
- Performance targets
- Explicit deviations from standards

### Precedence Rules

| Conflict Scenario | Resolution |
|-------------------|------------|
| Project-level vs Stack-specific | Project-level wins |
| Project-level vs Global | Project-level wins |
| Stack-specific vs Global | Stack-specific wins |

**All deviations require an ADR documenting:**
- The standard being deviated from
- The project-level decision
- Rationale for the deviation
- Risks of deviating

### Project Type Detection

The `aidlc-design` skill detects the project type by scanning the repository for
markers defined in each `references/technical-guidance/<stack>.md` file's
`detection-markers` frontmatter.

If multiple stacks are detected (e.g., a Rails app with a Vue frontend), load all
matching guidance files. If no stack matches, use Global guidance only.

The detection is presented to the user for confirmation during the design workflow.

## NFR Checklist (prompt as needed)

- Performance/latency targets (see Trigent Performance Standards below)
- Availability/SLA
- Security and privacy
- Compliance (SOC2, HIPAA, GDPR, etc.)
- Reliability/recovery objectives
- Observability requirements
- Cost constraints

### Trigent Performance Standards

Reference: [Performance Standards](<PERFORMANCE_STANDARDS_URL>) (from `aidlc.config.yaml`; run `/aidlc-init`)

When defining performance NFRs, apply these standards where applicable:

| Category | Standard |
|----------|----------|
| Browser (Core Web Vitals) | LCP ≤2.5s, INP ≤200ms, CLS ≤0.1 (75th percentile) |
| Mobile Apps | Screen Transition ≤100ms (good), Crash Rate ≤1% |
| Traditional APIs | Response Time <100ms (75th percentile) |
| Feature Specific | Team-defined (track in addition to standards) |
| Background Jobs | Team-defined (queue depth, custom metrics) |

Performance is monitored via New Relic Service Levels. Trend performance is measured over 7 days at 75th percentile.

## Measurement Criteria Prompts

- Primary business outcome metric
- User impact metric
- Baseline and target timeframe
- Leading indicators

## Testing Strategy Guidance

Include a testing strategy appropriate to the pathway type and scope:

- **Automated tests**: Unit, integration, and contract tests in CI/CD pipelines
- **Manual/exploratory QA**: For user-facing flows and edge cases
- **E2E tests**: Only when user-facing flows are in scope; prefer contract tests for service boundaries
- **Performance/load tests**: When NFRs include latency or throughput targets
- **Security testing**: When security or compliance NFRs apply

For each Epic, specify:
- Which test types apply
- Acceptance criteria that are testable
- Any test environment or data dependencies

## Repo Context Gathering

When the Feature involves code changes, gather repo context to inform the documentation:

1. **Local repo available**: Read README, docs, and relevant source files to understand architecture
2. **GitLab/GitHub MCP available**: Fetch README and docs from the remote repository
3. **CLI fallback**: Use `glab` or `gh` to fetch repo information if MCP is unavailable

Include in the Feature documentation:
- Service inventory table (service name, pathway, repo link)
- Key architectural patterns or constraints discovered
- Existing testing infrastructure

## PRFAQ Template (Optional)

Generate a PRFAQ when requested to communicate the Feature's value proposition.

### Press Release
- **Headline**: One-line value proposition
- **Subheadline**: Who benefits and how
- **Problem**: What pain point is being addressed
- **Solution**: How this Feature solves it
- **Quote**: Stakeholder perspective on the value
- **Call to Action**: What success looks like

### FAQ
- Q: Who is the target user?
- Q: What are the key success metrics?
- Q: What are the main risks?
- Q: What is out of scope?
- Q: What dependencies exist?

## Sprint Planning Guidance

Sprints are rapid iteration cycles (hours to days) for implementing Epics.

When planning Sprints:
- Each Sprint should deliver a testable increment
- Sprints within an Epic can run sequentially or in parallel
- Suggest Sprint boundaries based on:
  - Natural breakpoints in functionality
  - Integration points requiring validation
  - Risk areas needing early feedback

Example Sprint structure for an Epic:
- Sprint 1: Core domain logic + unit tests (4-8 hours)
- Sprint 2: API/integration layer (4-8 hours)
- Sprint 3: Security hardening + compliance checks (2-4 hours)

### Sprint Execution Plan Structure

The Sprint Execution Plan uses a **Phase/Lane** model to express sequencing and parallelism:

- **Phase**: A sequential stage. All sprints in Phase N should generally complete before Phase N+1 starts (unless a sprint in N+1 only depends on specific sprints in N that are already complete).
- **Lane**: A parallel execution slot within a phase. Sprints in different lanes of the same phase can run concurrently.
- **Critical Path**: The longest chain of dependent sprints — determines minimum project duration.

Create a new phase when sprints have dependencies on sprints from the previous phase. Create a new lane when sprints within the same phase are independent of each other.

### Phase Assignment Rules

| Phase | Purpose | Typical Content |
|-------|---------|-----------------|
| Phase 0: Foundation | Setup, scaffolding, shared infrastructure | Database schemas, project scaffolding, shared libraries, config |
| Phase 1: Core Domain | Primary domain logic and data models | Business logic, entity models, core services |
| Phase 2: Integration | API layers, external service integration | Controllers, API endpoints, message handlers |
| Phase 3+: Extension | Additional features, polish, deployment | UI components, reporting, monitoring, deployment scripts |

Phases are not rigid categories — assign based on actual dependency chains. A project may have 2 phases or 6+.

### Lane Assignment Rules

- Independent sprints in the same phase get different lanes (A, B, C...)
- Maximum lanes per phase = number of available teams/developers
- If two sprints in the same phase share no dependencies, they should be in different lanes
- If all sprints in a phase are independent, maximize parallelism

### Critical Path Analysis

To identify the critical path:
1. Trace all dependency chains from start to finish
2. The longest chain (by estimated duration) is the critical path
3. Sprints on the critical path should be prioritized — any delay extends the project
4. Sprints NOT on the critical path have slack (can be delayed without affecting total duration)

### Sprint Sizing

| Size | Duration | Guidance |
|------|----------|----------|
| Too small | < 2 hours | Overhead of setup/context switching dominates. Merge with a related Sprint. |
| Ideal | 2 hours – 3 days | A session's worth of deep work. Single engineer can complete with focus. |
| Too large | > 3 days | Risk of delayed feedback and hidden complexity. Split into smaller Sprints. |

## Team Size Recommendation Rubric

After proposing Sprint groupings and the initial execution plan, use this rubric to suggest an optimal team size.

### Core Principle

**Start from peak parallelism, discount for real-world friction.**

Max parallel lanes is the theoretical ceiling, but you almost never staff to 100% because:
- Communication overhead scales quadratically (n×(n-1)/2 channels)
- Peak parallelism may only exist in one phase — other phases leave engineers idle
- Parallel sprints in the same codebase create merge conflicts and review bottlenecks
- Foundation work (Phase 0) benefits from fewer people establishing patterns

### Input Signals

| Signal | Source | How to Measure |
|--------|--------|----------------|
| **Peak parallel lanes** | Sprint Execution Plan | Max lanes in any single phase |
| **Weighted average lanes** | Sprint Execution Plan | Σ(lanes × phase_duration) / Σ(phase_duration) |
| **Cross-epic coupling** | Dependency graph | Low / Medium / High (see criteria below) |
| **Specialist diversity** | Sprint technical requirements | Count of distinct skill sets needed concurrently |
| **Total sprint count** | Sprint Execution Plan | Raw count |
| **Phase count** | Sprint Execution Plan | Number of sequential phases |

### Calculation

```
Step 1: Start with weighted average lanes (not peak)
        — This reflects actual sustained parallelism, not a momentary spike

Step 2: Apply coupling discount
        — Low coupling:    ×1.0  (independent services/repos)
        — Medium coupling: ×0.85 (shared codebase, different areas)
        — High coupling:   ×0.70 (same files, shared state, frequent integration)

Step 3: Apply foundation cap
        — Phase 0 lanes capped at 2 regardless of actual lanes
        — Recalculate weighted average with capped Phase 0

Step 4: Round up to nearest integer

Step 5: Apply bounds
        — Floor: max(1, specialist_count)
        — Ceiling: peak_lanes
```

### Coupling Assessment Criteria

| Level | Indicators |
|-------|-----------|
| **Low** | Sprints touch different repos or independently deployable services; no shared database tables; different tech stacks |
| **Medium** | Same monorepo but different modules/packages; shared database with different tables; shared API contracts |
| **High** | Same files modified by multiple sprints; shared mutable state; database schema changes that affect multiple sprints |

### Common-Sense Caps

| Rule | Rationale |
|------|-----------|
| **Phase 0: max 2 engineers** | Establishing patterns and scaffolding benefits from a small aligned group. More people = inconsistent foundations. |
| **Never exceed peak lanes** | Can't usefully employ more engineers than the max concurrent work. |
| **Diminishing returns above 5** | Communication channels explode (5 people = 10 channels, 6 = 15). Above 5, recommend splitting into sub-teams with clear interfaces. |
| **Sequential same-epic sprints: don't double-count** | If Sprint 1.1 → Sprint 1.2 are in the same Epic, one engineer doing both sequentially is often faster than two with handoff. Don't treat each as needing a separate person. |

### Duration Estimation Logic

```
For each phase:
  phase_duration = max(sprint_durations_in_phase) when fully staffed
                 = sum(sprint_durations) / min(engineers, lanes) when understaffed

Total duration = Σ(phase_durations)
Total work = Σ(all sprint durations)
Utilisation = total_work / (engineers × total_duration)
```

### Quick Reference Table (for simple projects)

For teams that want a fast answer without the full calculation:

| Total Sprints | Phases | Peak Lanes | Suggested Engineers |
|-------------|--------|------------|-------------------|
| 3-5 | 2-3 | 2 | **1-2** |
| 6-10 | 3-4 | 3 | **2-3** |
| 10-15 | 4-5 | 4-5 | **3-4** |
| 15+ | 5+ | 5+ | **4-5** (consider sub-teams) |

*These assume medium coupling. Adjust down for high coupling, up for low coupling.*

## Dependency Analysis & Decoupling

See @${CLAUDE_PLUGIN_ROOT}/references/dependency-analysis.md for:
- Blocking vs non-blocking dependency classification
- Environment-specific dependencies (cloud vs local dev)
- Dependency analysis questions
- Two-pass decoupling (Epic-level interactive, Task-level easy wins batch)

## Task Sizing Guidance

See @${CLAUDE_PLUGIN_ROOT}/references/task-sizing.md for internal Fibonacci-based sizing to right-size Tasks (combine trivial 1s, split 13+).

## Mob Elaboration Guidance

Mob Elaboration is a collaborative ritual for requirements elaboration.

**Setup:**
- Single room (physical or virtual) with shared screen
- Participants: Product Owner, Developers, QA, relevant stakeholders
- AI as central participant proposing and refining

**Flow:**
1. Present the Feature and gather clarifying questions
2. AI proposes initial Tasks and Acceptance Criteria
3. Mob reviews, challenges, and refines
4. AI groups Tasks into cohesive Epics
5. Mob validates Epic boundaries and dependencies
6. Capture NFRs, Risks, and Measurement Criteria
7. Approve final structure before Jira creation

**Duration:** 2-4 hours for a typical Feature

## Artifact Traceability

Maintain bidirectional links between artifacts. The traceability structure depends on the backend:

### GitLab Traceability

```
Git Branch: intent/<project>/<slug>
└── intent.md (frontmatter: jira_project_key, mr_url)
    ├── sprint-plan.md
    ├── design/
    │   ├── domain-model.md
    │   └── architecture.md
    └── epics/
        ├── _overview.md
        └── epic-01-<slug>/
            ├── epic.md
            ├── tasks/task-U01-T01-<slug>.md
            └── adrs/adr-001-<slug>.md
```

After `/aidlc-verify`, frontmatter fields link to Jira artifacts (jira_project_key, jira_key).

### Linear Traceability

```
Initiative (Feature)
├── Project (Epic)
│   ├── Issue (Task/Sprint)
│   ├── Issue (Task/Sprint)
│   └── Issue (Design Doc, labeled "Design Doc")
└── Project (Epic)
    └── Issue (Task/Sprint)
```

Linear provides native parent-child relationships. No separate Jira transfer needed.

### Confluence/Jira Traceability

```
Jira Project ← Optional
    ↓ parent link
Confluence Feature Document
    ↓ linked in description
Jira Feature
    ↓ parent link
Jira Epic
    ↓ parent link
Jira Story
    ↓ parent link
Jira Task
    ↓ referenced in design docs
Domain Design / ADRs
```

**Sprint** groups Stories/Tasks for scheduling; it is not part of the parent hierarchy above.

**Confluence to Jira Mapping:**
```
(Optional) Project context → Jira Project (aidlc:project label)
Confluence Feature Document → Jira Feature (aidlc:feature label, child of Project if exists)
Confluence Epic Page → Jira Epic (aidlc:epic label, child of Feature)
Proposed Sprints (Epics Overview) → Jira Sprint (aidlc:sprint label, grouping Tasks)
Confluence Task Page → Jira Task (child of Sprint)
Sprint Execution Plan → Jira issue links ("blocks"/"is blocked by") + phase/lane metadata in Sprint descriptions
```

### General Principles

Each artifact should reference:
- **Forward**: What it decomposes into
- **Backward**: What it derives from

**Multi-project routing (Jira only):** Sprints can be created in different Jira projects (e.g., frontend/backend split). Tasks must be in the same project as their parent Sprint.

This enables:
- Impact analysis when requirements change
- Audit trail for compliance
- Context retrieval for AI assistance

## Domain-Driven Design Guidance

When creating Domain Designs, apply these DDD principles:

### Strategic Design
- **Bounded Context**: Define clear boundaries for the Epic's domain
- **Context Map**: Identify relationships with other Epics (upstream/downstream)
- **Ubiquitous Language**: Use consistent terminology from the Feature

### Tactical Design
- **Aggregate**: Cluster of entities with a root; transaction boundary
- **Entity**: Object with identity that persists over time
- **Value Object**: Immutable object defined by attributes, not identity
- **Domain Event**: Something significant that happened in the domain
- **Repository**: Abstraction for aggregate persistence
- **Factory**: Encapsulates complex object creation

### Anti-Corruption Layer
For brown-field scenarios, design an ACL to:
- Translate between legacy and new domain models
- Isolate the new domain from legacy system quirks
- Enable gradual migration

## ADR Template

Use this template for Architecture Decision Records. Storage location depends on backend:
- **GitLab**: `epics/<epic-name>/adrs/adr-NNN-<slug>.md` with YAML frontmatter
- **Linear**: Issue titled "ADR-NNN: \<Title\>" with "Design Doc" label
- **Confluence**: Child page under the design section

### ADR-NNN: <Decision Title>

**Status:** Proposed | Accepted | Deprecated | Superseded

**Context:**
What is the issue or question that motivated this decision?

**Decision:**
What is the decision that was made?

**Consequences:**
What are the trade-offs and implications?
- Positive:
- Negative:
- Risks:

**Alternatives Considered:**
What other options were evaluated?

**Related:**
- Feature: <link>
- Epic: <link>
- Related ADRs: <links>

## Atlassian MCP Operational Guidance

**Atlassian Domain:** `<ATLASSIAN_CLOUD_ID>`
**Atlassian Cloud ID:** `<ATLASSIAN_CLOUD_ID>`

When using Atlassian MCP tools, follow this sequence:

**For Confluence operations:**
1. Use the Cloud ID above for all Atlassian MCP tool calls
2. Find the target space using `getConfluenceSpaces` or user-provided space key
3. Locate the parent page using `searchConfluenceUsingCql` or `getPagesInConfluenceSpace`
4. Create or update the page using `createConfluencePage` or `updateConfluencePage`
5. If the page already exists, ask whether to update or create a new version

**When reviewing a Confluence page:**
Before reading, prompt the user:
> "Would you like me to include comments (inline and footer) and their replies, or just the page content?"

- **Page content only**: Use `getConfluencePage`
- **With comments**: Also fetch `getConfluencePageInlineComments` and `getConfluencePageFooterComments`

**For Jira operations (prefer `acli` CLI - lower token usage):**

First, check if `acli` is installed:
```bash
which acli || echo "acli not installed - see: https://developer.atlassian.com/cloud/acli/"
```

If `acli` is available, use it for Jira operations:
1. Confirm the Jira project key (never assume a default)
2. View issues: `acli jira workitem view PROJ-123 --json`
3. Create issues: `acli jira workitem create --project "PROJ" --type "Sprint" --summary "Title" --description-file desc.md`
4. Edit issues: `acli jira workitem edit PROJ-123 --label "aidlc:epic"`
5. Search issues: `acli jira workitem search --project "PROJ" --jql "type = Sprint"`

If `acli` is not available, fall back to Atlassian MCP:
1. Verify issue types using `getJiraProjectIssueTypesMetadata`
2. Get field metadata using `getJiraIssueTypeMetaWithFields` if custom fields are needed
3. Create issues using `createJiraIssue`
4. Link issues to Confluence pages in the description field

**Common issues:**
- Space/project not found: Verify key spelling and permissions
- Missing issue type: Check project configuration; some issue types may not be available
- Permission denied: User may lack write access; suggest admin contact

## Comment Resolution Guidance

When resolving comments during the decomposition review phase, follow this process:

### Fetching Comments

For each page in the decomposition hierarchy (Overview, Epics, Tasks):

1. **Inline comments**: `getConfluencePageInlineComments`
   - These are attached to specific text selections
   - Check `resolutionStatus` field: `open`, `resolved`, `reopened`, `dangling`
   - Dangling means the highlighted text was modified/deleted

2. **Footer comments**: `getConfluencePageFooterComments`
   - These are general page-level comments
   - No resolution status - resolved by discussion in reply thread

3. **Replies**: Both inline and footer comments can have threaded replies
   - Always read the full thread to understand the discussion
   - Later replies may supersede earlier feedback

### Addressing Feedback

For each comment thread:

| Feedback Type | Action |
|---------------|--------|
| Valid correction | Update page content, reply confirming change |
| Clarification needed | Reply with clarification, update content if needed |
| Disagreement | Reply explaining rationale, may need escalation |
| Question | Reply with answer, update content if answer reveals gap |
| Out of scope | Reply acknowledging, note for future consideration |

### Reply Templates

**Feedback addressed:**
> ✅ Updated. Changed [specific text] to [new text] based on this feedback.

**Clarification provided:**
> The intent here is [explanation]. I've updated the wording to make this clearer.

**Escalation needed:**
> This requires a decision from [role/person]. Flagging for discussion.

**Out of scope:**
> Good point, but this is out of scope for this Feature. Added to Open Questions for future consideration.

### Marking Resolved

- **Inline comments**: Confluence has a "Resolve" action - mention this to the user
- **Footer comments**: Considered resolved when the reply thread indicates agreement

### Best Practices

- Address comments in order: Overview → Epics → Tasks (top-down)
- Group related comments that can be addressed with a single content update
- If multiple comments conflict, surface the conflict and ask for resolution
- Keep replies concise but informative
- Always update content before replying (so the reply can reference the change)

## GitLab CLI (`glab`) Commands

**Why use `glab`?** The GitLab CLI is the primary tool for GitLab backend operations. It's efficient and supports all needed operations (branches, MRs, comments).

**Installation check:**
```bash
which glab || echo "Not installed - see: https://gitlab.com/gitlab-org/cli"
```

**Authentication:**
```bash
glab auth login  # Interactive login (one-time setup)
glab auth status  # Check authentication
```

### Common GitLab Commands

| Operation | Command |
|-----------|---------|
| Clone repo | `git clone <GITLAB_DOCS_REPO_SSH> "$AIDLC_DOCS_PATH"` (set AIDLC_DOCS_PATH env var first) |
| Create branch | `git checkout -b "intent/<project>/<slug>"` |
| Create draft MR | `glab mr create --draft --title "[Feature N] Title" --source-branch "<branch>"` |
| View MR | `glab mr view <ID>` |
| View MR comments | `glab mr view <ID> --comments` |
| List MRs | `glab mr list --source-branch "<branch>"` |
| Mark MR ready | `glab mr update <ID> --ready` |
| Add MR note | `glab mr note <ID> --message "Comment text"` |

### GitLab Branch Naming Convention

```
intent/<project-slug>/<intent-slug>
```

**Slugging rules** (see @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md for full details):
- Lowercase
- Spaces and special chars → hyphens
- Collapse multiple hyphens
- Trim leading/trailing hyphens

### GitLab File Templates

See @${CLAUDE_PLUGIN_ROOT}/references/backends/gitlab.md for complete file templates:
- `intent.md` — Feature document with YAML frontmatter
- `epics/_overview.md` — Epics Overview
- `epics/epic-NN-<slug>/epic.md` — Individual Epic documents
- `epics/epic-NN-<slug>/tasks/task-UNN-TNN-<slug>.md` — Task documents
- `epics/epic-NN-<slug>/adrs/adr-NNN-<slug>.md` — Architecture Decision Records
- `design/domain-model.md` — Domain model
- `design/architecture.md` — Logical design

## GitHub CLI (`gh`) Commands

**Why use `gh`?** When the source code repository is hosted on GitHub, use the GitHub CLI for PR operations. Detected automatically from git remote URL — see @${CLAUDE_PLUGIN_ROOT}/references/vcs-detection.md.

**Installation check:**
```bash
which gh || echo "Not installed - see: https://cli.github.com/"
```

**Authentication:**
```bash
gh auth login   # Interactive login (one-time setup)
gh auth status  # Check authentication
```

### Common GitHub Commands

| Operation | Command |
|-----------|---------|
| Create draft PR | `gh pr create --draft --title "[Feature N] Title" --head "<branch>"` |
| View PR | `gh pr view <NUMBER>` |
| View PR comments | `gh pr view <NUMBER> --comments` |
| View PR diff | `gh pr diff <NUMBER>` |
| List PRs by branch | `gh pr list --head "<branch>"` |
| Mark PR ready | `gh pr ready <NUMBER>` |
| Add PR comment | `gh pr comment <NUMBER> --body "Comment text"` |
| Post review | `gh pr review <NUMBER> --comment --body "Review text"` |
| Merge PR | `gh pr merge <NUMBER>` |

For inline review comments on specific lines, use the GitHub API via `gh api` — see @${CLAUDE_PLUGIN_ROOT}/references/vcs-detection.md.

## Linear MCP Tools Reference

When using the Linear backend, use these MCP tools:

| Operation | Tool | Key Parameters |
|-----------|------|----------------|
| List teams | `list_teams` | `query` |
| Create Initiative | `save_initiative` | `name`, `description`, `status`, `owner` |
| Get Initiative | `get_initiative` | `query` (ID or name), `includeProjects` |
| Create Project | `save_project` | `name`, `description`, `team`, `initiatives` |
| Get Project | `get_project` | `query` (ID, name, or slug), `includeMilestones` |
| Create Issue | `save_issue` | `title`, `description`, `team`, `project`, `state` |
| List Issues | `list_issues` | `project`, `state`, `assignee` |
| Add Comment | `create_comment` | `issueId`, `body` |
| Add status update | `save_status_update` | `initiativeId`, `health`, `body` |

### Linear Object Mapping

| AIDLC Concept | Linear Object | Notes |
|---------------|---------------|-------|
| Project | Workspace/Team | Select team at Feature creation |
| Feature | Initiative | Status: Planned → Active → Completed |
| Epic | Project | Linked to parent Initiative |
| Task/Sprint | Issue | Linked to parent Project |
| Design Doc | Issue (labeled "Design Doc") | Under Epic's Project |
| ADR | Issue (titled "ADR-NNN: ...") | Under Epic's Project |

See @${CLAUDE_PLUGIN_ROOT}/references/backends/linear.md for full Linear operations reference.

## Atlassian MCP Tool Names (Rovo)

In Claude Code, tools are namespaced with the `mcp__plugin_atlassian_atlassian__` prefix.

| Base Tool Name | Claude Code Namespaced Name |
|----------------|----------------------------|
| `search` | `mcp__plugin_atlassian_atlassian__search` |
| `searchConfluenceUsingCql` | `mcp__plugin_atlassian_atlassian__searchConfluenceUsingCql` |
| `searchJiraIssuesUsingJql` | `mcp__plugin_atlassian_atlassian__searchJiraIssuesUsingJql` |
| `getConfluenceSpaces` | `mcp__plugin_atlassian_atlassian__getConfluenceSpaces` |
| `getConfluencePage` | `mcp__plugin_atlassian_atlassian__getConfluencePage` |
| `getPagesInConfluenceSpace` | `mcp__plugin_atlassian_atlassian__getPagesInConfluenceSpace` |
| `createConfluencePage` | `mcp__plugin_atlassian_atlassian__createConfluencePage` |
| `updateConfluencePage` | `mcp__plugin_atlassian_atlassian__updateConfluencePage` |
| `getVisibleJiraProjects` | `mcp__plugin_atlassian_atlassian__getVisibleJiraProjects` |
| `getJiraProjectIssueTypesMetadata` | `mcp__plugin_atlassian_atlassian__getJiraProjectIssueTypesMetadata` |
| `getJiraIssueTypeMetaWithFields` | `mcp__plugin_atlassian_atlassian__getJiraIssueTypeMetaWithFields` |
| `createJiraIssue` | `mcp__plugin_atlassian_atlassian__createJiraIssue` |
| `editJiraIssue` | `mcp__plugin_atlassian_atlassian__editJiraIssue` |
| `addCommentToJiraIssue` | `mcp__plugin_atlassian_atlassian__addCommentToJiraIssue` |
| `lookupJiraAccountId` | `mcp__plugin_atlassian_atlassian__lookupJiraAccountId` |

## Atlassian CLI (`acli`) Commands (Preferred for Jira)

**Why prefer `acli` for Jira?** The Atlassian CLI uses significantly fewer tokens than the MCP tools, making it more efficient for Jira operations. Use MCP for Confluence (richer tooling) and `acli` for Jira.

**Installation check:**
```bash
which acli || echo "Not installed - see: https://developer.atlassian.com/cloud/acli/"
```

**Authentication:**
```bash
acli auth login  # Interactive login (one-time setup)
```

### Common Jira Commands

| Operation | Command |
|-----------|---------|
| View issue | `acli jira workitem view PROJ-123 --json` |
| View with fields | `acli jira workitem view PROJ-123 --fields summary,description,status,issuetype --json` |
| Search issues | `acli jira workitem search --project "PROJ" --jql "type = Sprint AND status = Open"` |
| Create issue | `acli jira workitem create --project "PROJ" --type "Sprint" --summary "Title" --description "Body"` |
| Create from file | `acli jira workitem create --project "PROJ" --type "Sprint" --summary "Title" --description-file desc.md` |
| Create with parent | `acli jira workitem create --project "PROJ" --type "Sprint" --summary "Title" --parent "PROJ-100"` |
| Edit issue | `acli jira workitem edit PROJ-123 --summary "New Title"` |
| Add label | `acli jira workitem edit PROJ-123 --label "aidlc:epic"` |
| Add comment | `acli jira workitem comment add PROJ-123 --body "Comment text"` |
| Transition | `acli jira workitem transition PROJ-123 --transition "In Progress"` |
| Link issues | `acli jira workitem link PROJ-456 PROJ-789 --link-type "blocks"` |
| Set team field | `acli jira workitem edit PROJ-123 --field "Team" --value "Team Name"` |
| List fields | `acli jira workitem fields PROJ-123` |
| List projects | `acli jira project list` |

### Status Transitions with Fallback

**Pattern: `transition_jira_status(issue_key, target_status, issue_type)`**

Utility pattern for transitioning Jira statuses with automatic fallback from acli to MCP tools:

**Implementation Strategy:**

```bash
# 1. Try acli first (preferred - lower token usage)
if which acli &> /dev/null; then
  acli jira workitem transition PROJ-123 --transition "In Progress"
else
  # 2. Fall back to MCP tools
  # - Call getTransitionsForJiraIssue(PROJ-123)
  # - Find transition ID matching target status name
  # - Call transitionJiraIssue(PROJ-123, {id: "21"})
fi
```

**Error Handling:**

| Condition | Action |
|-----------|--------|
| Status already set | Log info, treat as success |
| Invalid transition | Log warning, ask user to verify manually |
| Network/auth failure | Log error, continue workflow (non-blocking) |
| acli not installed | Silent fallback to MCP tools |

**Return Format:**

```json
{
  "success": true,
  "method": "acli",
  "message": "Transitioned SPRINT-123 to In Progress",
  "previous_status": "To Do",
  "new_status": "In Progress"
}
```

**Display Indicators:**
- ✓ Success
- ⚠ Warning (already in target state)
- ✗ Failed (manual intervention needed)

**Example Usage (acli):**

```bash
# Check current status first
acli jira workitem view PROJ-123 --fields status --json | jq '.status.name'

# Transition to In Progress
acli jira workitem transition PROJ-123 --transition "In Progress"

# Verify transition
acli jira workitem view PROJ-123 --fields status --json | jq '.status.name'
```

**Example Usage (MCP Fallback):**

```javascript
// 1. Get available transitions
const transitions = await getTransitionsForJiraIssue({
  cloudId: "your-cloud-id",
  issueIdOrKey: "PROJ-123"
});

// 2. Find the transition ID for "In Progress"
const inProgressTransition = transitions.find(t => t.name === "In Progress");

// 3. Execute transition
await transitionJiraIssue({
  cloudId: "your-cloud-id",
  issueIdOrKey: "PROJ-123",
  transition: { id: inProgressTransition.id }
});
```

**Parent-Child Synchronization Rules:**

| Scenario | Action |
|----------|--------|
| All Tasks "To Do" | Sprint must be "To Do" or "In Progress" |
| Any Task "In Progress" | Sprint must be "In Progress" |
| All Tasks "Done" | Sprint should transition to "In Review" |
| Sprint "In Review" | All Tasks must be "Done" (verify at transition) |

**Smart Sync Behavior (resuming work):**
- Check each item's current status before transitioning
- Only transition items in "To Do"
- Log items already "In Progress" or "Done" (no change needed)
- Warn if Sprint is "To Do" but Tasks are "In Progress" (inconsistency)

### Example: Create Project with Feature

```bash
# Create Project - optional
acli jira workitem create \
  --project "PROJ" \
  --type "Project" \
  --summary "Project: Authentication Modernization" \
  --description "Portfolio-level tracking for auth initiative" \
  --label "aidlc:project" \
  --json

# Create Feature, optionally as child of Project
acli jira workitem create \
  --project "PROJ" \
  --type "Feature" \
  --summary "SSO Integration" \
  --description-file intent-sso.md \
  --label "aidlc:feature" \
  --parent "PROJ-100" \
  --json
```

### Example: Create Epic with Sprints

```bash
# Create Epic
acli jira workitem create \
  --project "PROJ" \
  --type "Epic" \
  --summary "Epic: Authentication" \
  --description-file epic-auth.md \
  --label "aidlc:epic" \
  --json

# Parse the key from JSON output, then create child Sprints
acli jira workitem create \
  --project "PROJ" \
  --type "Sprint" \
  --summary "Sprint: Implement login form" \
  --description-file sprint-login.md \
  --label "aidlc:sprint" \
  --parent "PROJ-123"
```

### Example: Link Dependent Sprints

```bash
# Sprint 1.2 (PROJ-456) is blocked by Sprint 1.1 (PROJ-455)
acli jira workitem link PROJ-456 PROJ-455 --link-type "blocks"

# Sprint 2.2 (PROJ-460) is blocked by Sprint 2.1 (PROJ-458)
acli jira workitem link PROJ-460 PROJ-458 --link-type "blocks"
```

### Example: Set Team on Jira Artifacts

```bash
# Set team field on an Epic
acli jira workitem edit PROJ-123 --field "Team" --value "Platform Team"

# Set team field on a Sprint
acli jira workitem edit PROJ-456 --field "Team" --value "Platform Team"

# Discover the team field name if "Team" doesn't work
acli jira workitem fields PROJ-123
```

## Task Specification Subagent

The `/aidlc-design` skill uses parallel subagents to generate Task Specifications by Epic. This section defines the prompt template and expected return format.

**Note:** Task generation moved from `/aidlc-elaborate` to `/aidlc-design` in AIDLC 3.9.0. Tasks are generated after ADRs and domain/logical design are complete, giving them accurate file references and behavioural detail from the outset.

### Task Spec Generator Agent

Use `subagent_type: "task-spec-generator"` when spawning Task Specification subagents.

**Pass to agent:**
- Epic definition (name, description, scope, acceptance criteria, dependencies, risks)
- Domain model (aggregates, entities, value objects, events for this Epic)
- Logical design (patterns selected, NFR solutions, integration approach)
- ADRs (decisions affecting task scope or implementation)
- NFRs specific to the Epic
- Feature context (scope, out-of-scope items)
- Existing Task Specs from other Epics (for cross-reference and id sequencing)
- Project context (repository structure and naming conventions, if available)

The agent returns structured JSON with Task Specifications validated against `references/task-spec.md`. See the `task-spec-generator` agent definition for full output format.

### Subagent Return Format

Each subagent returns structured JSON with these fields:

| Field | Type | Description |
|-------|------|-------------|
| `epic` | string | Epic id (e.g. `U01`) |
| `epic_name` | string | Epic name |
| `tasks` | array | Array of Task Specifications |
| `tasks[].id` | string | Task id in `U\d{2}-T\d{2}` format |
| `tasks[].title` | string | Task title (max 80 chars) |
| `tasks[].sprint` | integer | Preliminary sprint assignment |
| `tasks[].size` | integer | Fibonacci size (1, 2, 3, 5, 8, 13) |
| `tasks[].files` | object | `modify`, `create`, `reference` lists |
| `tasks[].dependencies` | array | Each has `on`, `type`, `environment`, `rationale` |
| `tasks[].behaviour` | array | Observable outcomes (at least one required) |
| `tasks[].rules` | array | Hard constraints (optional) |
| `tasks[].risks` | array | Task-level risks with mitigation (optional) |
| `tasks[].not_in_scope` | array | Explicit scope boundaries (optional) |
| `cross_epic_concerns` | array | Concerns that span multiple Epics |

### Consolidation Logic (in `/aidlc-design`)

After collecting results from all subagents, the parent agent:

1. **Validate schemas**: Check all Task Specs against `references/task-spec.md` validation rules
2. **Confirm sprint ids**: Review preliminary sprint assignments and produce the final sprint plan
3. **Build dependency graph**: Map `cross_epic_concerns` to actual Tasks across Epics
4. **Identify conflicts**: Flag Tasks with conflicting assumptions or overlapping scope
5. **Assign final sprint ids**: Update `sprint` field on each task to match the confirmed sprint plan
6. **Generate test scopes**: Spawn sub-agents (one per sprint + one per epic) to generate layered scenarios from `behaviour`+`rules` (Step 14); validate no-gap and no-overlap rules and get user approval (Step 14a); write the complete `## Test Scope` to each `epic.md` with `### <Sprint Name>` subsections and `### Epic-Level Integration Scenarios` (Step 14b)

## Theme Clustering Guidance (for `/aidlc-elaborate`)

When identifying theme clusters from a Feature during elaboration (Epics only — no tasks):
- Aim for 3-5 clusters (fewer for small features, more for complex ones)
- Group by functional area, capability, or technical domain
- Each cluster should have low coupling to other clusters
- Example themes: Authentication, API Layer, Data Migration, UI Components, Reporting

## Artifact Creation Agents

Both `/aidlc-elaborate` and `/aidlc-design` use parallel subagents to create artifacts efficiently. The agent type depends on the backend. **Epic creation happens during elaborate; Task creation happens during design.**

| Backend | Agent Type | Elaborate creates | Design creates |
|---------|-----------|-------------------|----------------|
| **GitLab** | `gitlab-creator` | Epic `.md` files | Task `.md` files (Task Spec format) |
| **Linear** | `linear-creator` | Projects (Epics) | Issues (Tasks, Task Spec format) |
| **Confluence** | `confluence-creator` | Epic pages | Task pages (Task Spec format) |

### Confluence Page Creation Agent

Use `subagent_type: "confluence-creator"` when spawning page creation subagents.

**Pass to each sub-agent during elaborate (Epics):**

- Parent page ID (Epics Overview page)
- Epic definition (name, description, dependencies, risks, not_in_scope, open questions)
- Space key

**Pass to each sub-agent during design (Tasks):**

- Parent page ID (Epic page)
- Task Specifications (id, title, sprint, size, behaviour, rules, files, dependencies, risks, not_in_scope)
- Space key

The agent returns JSON with Epic page or Task page IDs/URLs. See the `confluence-creator` agent definition for full output format.

### GitLab File Creation Agent

Use `subagent_type: "gitlab-creator"` when spawning file creation subagents. See @${CLAUDE_PLUGIN_ROOT}/agents/gitlab-creator.md for full agent definition.

### Linear Artifact Creation Agent

Use `subagent_type: "linear-creator"` when spawning Linear creation subagents. See @${CLAUDE_PLUGIN_ROOT}/agents/linear-creator.md for full agent definition.

### Subagent Return Format

Each subagent returns structured JSON with these fields:

| Field | Type | Description |
|-------|------|-------------|
| `epic.name` | string | The Epic name |
| `epic.pageId` | string | Confluence page ID for the Epic |
| `epic.pageUrl` | string | URL to the Epic page |
| `tasks` | array | Array of created Task pages |
| `tasks[].title` | string | Task title |
| `tasks[].pageId` | string | Confluence page ID for the Task |
| `tasks[].pageUrl` | string | URL to the Task page |

### Consolidation After Page Creation

After collecting results from all page creation subagents:

1. **Verify all pages created**: Check that each subagent returned valid page IDs
2. **Handle failures**: If any subagent failed, report which Epic/Tasks failed and offer to retry
3. **Compile page links**: Build a summary of all created pages for the user
4. **Update Epics Overview**: Add links to Epic pages in the summary table

## Sprint Implementation Subagents

The `/aidlc-sprint` skill uses parallel subagents for efficient, accurate implementation of multi-Task Sprints. Sub-agents operate per-Task when a Sprint contains multiple Tasks.

### Task Context Subagent (Phase 1)

Use this template when spawning Task Context Agents to explore the codebase for each Task in parallel:

```markdown
You are gathering implementation context for a single Task within a Sprint.

## Task: <Task Title>

<Task content: user story, acceptance criteria>

## Repository Context

**Repo Path:** <path>
**Tech Stack:** <languages, frameworks>
**Key Directories:** <src/, tests/, etc.>

## Instructions

1. Search for existing code related to this Task's domain
2. Identify relevant files, modules, and patterns
3. Find existing tests that cover related functionality
4. Note any integration points or dependencies

## Return Format

Return your results as JSON in this exact structure:

{
  "task": "<task title>",
  "relevant_files": [
    { "path": "<file path>", "relevance": "<why this file is relevant>" }
  ],
  "existing_patterns": [
    "<pattern description>"
  ],
  "related_tests": [
    { "path": "<test file path>", "coverage": "<what it tests>" }
  ],
  "integration_points": [
    "<service/API/database>"
  ],
  "technical_notes": "<observations about implementation approach>"
}
```

### Task Test Planning Subagent (Phase 2)

Use this template when spawning Task Test Planning Agents to design test cases for each Task:

```markdown
You are planning TDD test cases for a single Task.

## Task: <Task Title>

<Task content: user story, acceptance criteria>

## Context from Phase 1

**Relevant Files:** <list>
**Existing Patterns:** <list>
**Related Tests:** <list>

## Instructions

1. Design unit tests for each acceptance criterion
2. Identify edge cases and error scenarios
3. Design integration tests if applicable
4. Suggest mocks/stubs needed
5. Plan Red-Green-Refactor cycles

## Return Format

Return your results as JSON in this exact structure:

{
  "task": "<task title>",
  "unit_tests": [
    { "name": "<test name>", "verifies": "<what it verifies>", "approach": "<how to test>" }
  ],
  "edge_cases": [
    "<edge case description>"
  ],
  "integration_tests": [
    { "name": "<test name>", "verifies": "<what it verifies>" }
  ],
  "mocks_needed": [
    "<mock/stub description>"
  ],
  "tdd_cycles": [
    { "cycle": 1, "red": "<failing test>", "green": "<implementation>", "refactor": "<improvements>" }
  ]
}
```

### Expert Perspective Subagents (Phase 2)

For high-risk Tasks, spawn Expert Perspective Agents to catch blind spots:

| Expert | Focus | Adds |
|--------|-------|------|
| Security | OWASP, auth, input validation | Security-focused test cases |
| Performance | Latency, memory, scalability | Performance test scenarios |
| Domain | Business rules, edge cases | Domain-specific scenarios |

**Security Expert Prompt:**
```markdown
You are reviewing test coverage from a security perspective.

## Task: <Task Title>
## Proposed Tests: <test plan from Tier 1>

Identify missing security test cases for:
- Input validation and sanitization
- Authentication/authorization boundaries
- Injection vulnerabilities (SQL, XSS, command)
- Sensitive data handling

Return additional test cases in the same JSON format as Task Test Planning.
```

**Performance Expert Prompt:**
```markdown
You are reviewing test coverage from a performance perspective.

## Task: <Task Title>
## Proposed Tests: <test plan from Tier 1>

Identify missing performance test cases for:
- Response time targets
- Memory usage
- Concurrent access
- Data volume edge cases

Return additional test cases in the same JSON format as Task Test Planning.
```

### Task Implementation Subagent (Phase 7)

Use this template when spawning Task Implementation Agents to execute TDD for independent Tasks in parallel:

```markdown
You are implementing a single Task using TDD.

## Task: <Task Title>

<Task content: user story, acceptance criteria>

## Test Plan from Phase 2

**TDD Cycles:**
<cycle details>

**Test Cases:**
<test case list>

## Implementation Context

**Relevant Files:** <list>
**Patterns to Follow:** <list>

## Instructions

1. For each TDD cycle:
   - RED: Write failing test, verify it fails
   - GREEN: Write minimal code to pass
   - REFACTOR: Improve code quality
2. Commit after each cycle with meaningful message
3. Update progress tracking
4. Do NOT run CodeRabbit reviews — the orchestrating agent handles consolidated review after all parallel agents complete

## Return Format

Return your results as JSON in this exact structure:

{
  "task": "<task title>",
  "status": "complete|blocked|partial",
  "cycles_completed": [
    { "cycle": 1, "test_file": "<path>", "impl_file": "<path>", "commit": "<commit hash or message>" }
  ],
  "files_modified": [
    "<file path>"
  ],
  "blockers": [
    "<blocker description>"
  ],
  "notes": "<implementation notes>"
}
```

### Subagent Consolidation Logic

After collecting results from all subagents:

**Phase 1 (Context) Consolidation:**
1. Parse JSON results from each agent
2. Merge relevant files lists (dedupe by path)
3. Combine existing patterns discovered
4. Surface any conflicting approaches
5. Present unified context summary

**Phase 2 (Planning) Consolidation:**
1. Merge test plans into unified structure
2. Identify shared test fixtures/utilities
3. Resolve any conflicting approaches
4. Integrate expert recommendations
5. Present combined test plan for approval

**Phase 7 (Implementation) Consolidation:**
1. Verify no file conflicts between agents
2. Merge any overlapping changes
3. Run full test suite to verify integration
4. Update plan file with combined progress
5. Report completion status for all Tasks

## Template Standardization

All templates must use consistent formatting for common sections.

### Section Format Reference

| Section | Required Format | Example |
|---------|-----------------|---------|
| **Acceptance Criteria** | Checkbox list (`- [ ]`) | `- [ ] User can log in with SSO` |
| **Risks** | Table with columns: Risk, Impact, Likelihood, Mitigation | See Risks Table Format |
| **Dependencies** | Bulleted list with link/reference | `- [AUTH-123] SSO provider setup` |
| **Status** | Bold label + current value | `**Status:** Draft` |
| **Task** | "As a... I want... So that..." format | Standard user story format |
| **NFRs** | Table with columns: Category, Requirement, Target | See NFRs Table Format |
| **Test Notes** | Bulleted list of test scenarios | `- Verify login with valid credentials` |
| **Context** | Prose paragraph(s) | Free-form text |

### Risks Table Format

Always use this table format for risks:

```markdown
| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| <Risk description> | High/Medium/Low | High/Medium/Low | <Mitigation strategy> |
```

### NFRs Table Format

Always use this table format for non-functional requirements:

```markdown
| Category | Requirement | Target |
|----------|-------------|--------|
| Performance | Response time | < 200ms |
| Security | Authentication | OAuth 2.0 |
| Availability | Uptime | 99.9% |
```

### Acceptance Criteria Format

Always use checkbox format for acceptance criteria:

```markdown
## Acceptance Criteria

- [ ] Criterion 1: Specific, testable requirement
- [ ] Criterion 2: Another testable requirement
- [ ] Criterion 3: Edge case handling
```

### Dependencies Format

Always use bulleted list with references:

```markdown
## Dependencies

- [PROJ-123] Prerequisite work item
- [Epic: Authentication] Must complete first
- External: Third-party API availability
```
