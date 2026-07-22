---
name: aidlc-verify
description: Verify documentation completeness and assess AI-execution confidence. Supports GitLab (markdown), Linear (native), or Confluence backends. Refines Sprint groupings. GitLab/Confluence transfer to Jira; Linear updates natively. (Triggers - verify docs, check readiness, transfer to jira, aidlc verify, ready for implementation, confidence check)
---

# AI-DLC Verify

Verify that all documentation (Feature, Epics, Tasks, Design) is complete and provides sufficient context for AI tooling to execute successfully. Refine Sprint groupings. Backend-specific handling: GitLab/Confluence transfer to Jira; Linear updates Initiative status natively (no Jira transfer).

## Completion Checklist

> **IMPORTANT**: Create tasks for each step at the start using `TodoWrite`. Mark tasks complete as you go using `TodoWrite`. Each task description should reference the corresponding Workflow step.

### Verification Phase

| # | Task | Depends On | Workflow Reference | Exit Criteria |
|---|------|------------|-------------------|---------------|
| 1 | Validate prerequisites | — | Prerequisites section | Epics exist, decomposition complete |
| 2 | Fetch all documentation | 1 | Phase 1 > Step 2 | Feature, Epics, Tasks, Design docs fetched |
| 3 | Spawn verification subagents | 2 | Phase 2 | One subagent per Epic launched |
| 4 | Consolidate results | 3 | Phase 3 | All scores calculated, gaps merged and ranked |
| 5 | Present assessment report | 4 | Phase 4 | Confidence score and gaps shown to user |
| 6 | Get decision from user | 5 | Phase 5 | User chooses: proceed / address gaps / cancel |

### Jira Transfer Phase (if approved)

| # | Task | Depends On | Workflow Reference | Exit Criteria |
|---|------|------------|-------------------|---------------|
| 7 | Confirm Jira transfer | 6 | Phase 6 > Step 1 | User confirms; Story Points field detected |
| 8 | Spawn task-creator agents | 7 | Phase 6 > Step 2b | N agents launched in parallel |
| 9 | Consolidate agent results | 8 | Phase 6 > Step 2c | Sprint map built, Story Points aggregated, sprint-type labels applied |
| 10 | Link Sprint dependencies | 9 | Phase 6 > Step 3 | Cross-Epic links created |
| 11 | Update Confluence | 10 | Phase 6 > Step 4 | Sprint Execution Plan backfilled |
| 12 | Update workflow status | 11 | Phase 6 > Step 5 | Status shows "Verification: ✅" |
| 13 | Delete Confluence pages | 12 | Phase 6 > Step 6 | Overview, Epics, Tasks deleted |
| 14 | Report final results | 13 | Phase 6 > Step 7 | Aggregate results reported |

## Task Tracking

When this skill is invoked:

1. **Create tasks** for the Verification Phase checklist items using `TodoWrite`
   - Include a reference to the workflow step in the task description (content field)
   - Set activeForm appropriately (e.g., "Validating prerequisites" for content "Validate prerequisites")
   - Example: `"Validate prerequisites (See Prerequisites section)"`
2. **Mark task as in_progress** when starting each step using `TodoWrite` (update status)
3. **Mark task complete** when the exit criteria are met using `TodoWrite` (update status)
4. **If user approves transfer**, create tasks for the Jira Transfer Phase
5. **Verify all tasks complete** before finishing the skill

This ensures visibility into progress and prevents incomplete execution.

## AI-Drives-Conversation Pattern

This skill follows the AI-DLC principle where AI initiates and directs the conversation:

1. **AI assesses** — Review all documentation and score confidence
2. **AI reports** — Present gaps and remediation suggestions
3. **Human decides** — Address gaps or approve transfer
4. **AI transfers** — Create Jira artifacts when confidence is sufficient

## Example Invocations

- "Verify the documentation is ready for implementation"
- "Check if we're ready to transfer to Jira"
- "Assess the confidence level for the authentication feature"
- "Are the epics ready for AI execution?"

## References

- @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md - Templates, Jira tool names, operational guidance
- @${CLAUDE_PLUGIN_ROOT}/references/review-criteria.md - Scoring rubrics, quality checklists, confidence thresholds
- @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md - Backend detection patterns
- @${CLAUDE_PLUGIN_ROOT}/references/backends/gitlab.md - GitLab-specific operations
- @${CLAUDE_PLUGIN_ROOT}/references/backends/linear.md - Linear-specific operations
- @${CLAUDE_PLUGIN_ROOT}/references/backends/confluence.md - Confluence-specific operations

## Prerequisites

Before starting, validate backend-specific artifacts exist:

### GitLab Backend

1. **Required artifacts**
   - Feature branch with `intent.md` (ask for branch name or MR URL)
   - Epic directories in `epics/` subdirectory, each containing `epic.md`
   - Task markdown files in `epics/<epic-name>/tasks/` subdirectories
   - Proposed Sprint groupings (in `sprint-plan.md`)
   - Design docs (optional): `domain-model.md`, ADRs in `epics/<epic-name>/adrs/` directories

2. **Required status**
   - Check frontmatter in `intent.md`: `status: elaborated`, `designed`, or `approved`
   - Verify Epics directory exists with at least one Epic file
   - **Note:** Task files are created during the design phase. If task files are absent, offer `/aidlc-design` rather than `/aidlc-elaborate`.

3. **If incomplete**: Offer `/aidlc-design` (if missing) or `/aidlc-elaborate` (if Epics missing)

### Linear Backend

1. **Required artifacts**
   - Initiative ID or URL (Feature)
   - Projects under this Initiative (Epics)
   - Issues under Projects (Tasks)
   - Proposed Sprint groupings (in Initiative description or separate doc)
   - Design docs (optional): Domain model in description, ADR documents

2. **Required status**
   - Initiative status should be "Planned" or "Active"
   - At least one Project should exist under the Initiative

3. **If incomplete**: Use Linear MCP to check hierarchy, offer `/aidlc-elaborate` if Projects/Issues missing

### Confluence Backend (Legacy)

1. **Required artifacts**
   - Confluence Feature document (ask for link)
   - Epics Overview page with Epic and Task child pages
   - Proposed Sprint groupings (in Epics Overview)
   - Design documentation (Domain model, ADRs) - optional but improves confidence
   - Fetch all using Atlassian MCP to confirm they exist

2. **Required status**
   - Check the Workflow Status table in the Confluence doc
   - Verify "Epic Decomposition" row shows "✅ Complete"
   - Check if "Domain Design" is complete (improves confidence score)

3. **If incomplete**: Offer `/aidlc-design` (if missing) or `/aidlc-elaborate` (if Epics missing)

### Override Pattern

If prerequisites incomplete, allow override with explicit confirmation (see Override Pattern in @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md)

## Confidence Assessment Framework

### Scoring Categories

| Category | Weight | Summary |
|----------|--------|---------|
| **Feature Clarity** | 20% | Problem/scope/outcomes clearly defined |
| **Task Completeness** | 25% | All Tasks have testable acceptance criteria |
| **Design Readiness** | 25% | Domain model documented, patterns chosen |
| **NFR Coverage** | 15% | Measurable targets with baselines |
| **Dependency Mapping** | 15% | Integration points identified, sequencing clear |

Full rubric definitions, sub-agent scoring dimensions, and gap categories: review-criteria.md **Part 3.3**

### Confidence Thresholds

Thresholds are defined in review-criteria.md **Part 1.2**. In summary:

- **High (80-100%)**: Proceed to Jira transfer
- **Medium (60-79%)**: List gaps, ask targeted questions, allow override
- **Low (<60%)**: STOP — must gather more context before continuing

## Workflow

### Phase 1: Detect Backend and Gather Artifacts

**Step 1: Detect Backend**

Use the guidance in @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md to detect which backend is in use:

1. **Ask user for Feature reference** (one of):
   - GitLab MR URL or branch name (e.g., `intent/auth/user-login`)
   - Linear Initiative ID or URL (e.g., `INI-123` or full URL)
   - Confluence page URL or page title

2. **Detect backend automatically**:
   - **GitLab**: User provides branch name, MR URL, or mentions "merge request"
   - **Linear**: User provides Initiative ID (INI-*), Linear URL, or mentions "initiative"
   - **Confluence**: User provides Confluence URL or page title

3. **Store backend context** for all subsequent operations

**Step 2: Collect Work Tracking Configuration**

**GitLab / Confluence** - Ask for Jira configuration:
- **Project routing**: Confirm primary Jira project key. Ask if multi-project routing needed (e.g., PROJ for backend, FRONT for frontend). Tasks inherit parent Sprint's project.
- **Team assignment**: Ask which team(s) will work on this. Single team = apply to all. Multiple teams = map to Epics or Sprints.

**Linear** - Skip Jira configuration:
- Work tracking is native in Linear (no Jira transfer)
- Team assignment can be configured if desired (optional)

**Step 3: Fetch All Documentation (backend-specific)**

**GitLab** (see @${CLAUDE_PLUGIN_ROOT}/references/backends/gitlab.md):

1. **Checkout Feature branch**:
   ```bash
   cd "$AIDLC_DOCS_PATH"
   git fetch origin
   git checkout <intent-branch-name>
   git pull origin <intent-branch-name>
   ```

2. **Read markdown files**:
   - Feature: `Projects/<Project>/Feature <N> - <Title>/intent.md`
   - Sprint Plan: `Projects/<Project>/Feature <N> - <Title>/sprint-plan.md`
   - Epics: `Projects/<Project>/Feature <N> - <Title>/epics/<epic-name>/epic.md`
   - Tasks: `Projects/<Project>/Feature <N> - <Title>/epics/<epic-name>/tasks/*.md`
   - Design docs (optional): `design/domain-model.md`, `epics/<epic-name>/adrs/*.md`

3. **Parse frontmatter** from `intent.md` to extract metadata (status, project key, etc.)

4. **Check for test scope**: Each epic file should contain a `## Test Scope` section (generated by `/aidlc-design`). If absent, offer to regenerate it now:

   > **Test scope missing from `epic.md`**
   >
   > This can happen on projects that ran `/aidlc-design` before v4.1.0. Test scenarios can be regenerated from the existing Task Specs without re-running the full design phase.
   >
   > Regenerate test scopes for all Epics now and write them to `epic.md`? (Recommended — required for Jira transfer to post test scenarios to Sprint and Epic tickets)
   >
   > Reply **yes** to regenerate and continue, or **no** to flag as a confidence gap and proceed.

   If the user confirms: run the equivalent of `/aidlc-design` Steps 14–14b — spawn sub-agents (one per sprint using Task Spec content, one per epic for integration scenarios), validate no-gap and no-overlap, present summary for approval, then write the complete `## Test Scope` to each `epics/<epic-name>/epic.md` with `### <Sprint Name>` subsections and `### Epic-Level Integration Scenarios`. Commit and push before continuing.

   If the user declines: flag as a confidence gap.

**Linear** (see @${CLAUDE_PLUGIN_ROOT}/references/backends/linear.md):

1. **Fetch Initiative** using Linear MCP `get_initiative`:
   - Initiative description contains Feature markdown
   - Store Initiative ID and URL

2. **Fetch Projects** (Epics) under Initiative:
   - Use `list_projects` filtered by `initiativeId`
   - Each Project represents an Epic
   - Project description contains Epic markdown

3. **Fetch Issues** (Tasks) under each Project:
   - Use `list_issues` filtered by `projectId`
   - Each Issue represents a Task
   - Issue description contains Task markdown

4. **Extract Sprint groupings**:
   - Check Initiative description for Sprint Execution Plan
   - Or check for separate "Execution Plan" document

5. **Fetch Design docs** (optional):
   - Check Initiative description for domain model section
   - Look for ADR documents (may be in separate Linear docs or embedded)

6. **Check for test scope**: Each Project (Epic) should have a test scope comment (generated by `/aidlc-design`). If absent, check whether sprint-level test scopes exist in the sprint plan (Initiative description or separate doc). If sprint scopes are present, offer to synthesise the missing epic-level scope and post it as a comment on each Project now (same recovery logic as GitLab above). If sprint scopes are also absent, or the user declines, flag as a confidence gap.

**Confluence (Legacy)** (see @${CLAUDE_PLUGIN_ROOT}/references/backends/confluence.md):

1. **Fetch pages** using Atlassian MCP:
   - Feature document (root page)
   - Epics Overview page (child of Feature)
   - Epic pages (children of Epics Overview)
   - Task pages (children of each Epic page)
   - Design docs (optional): Domain model, ADRs

2. **Check for test scope**: Each Epic page should contain a `## Test Scope` section (generated by `/aidlc-design`). If absent, check whether sprint-level test scopes exist in the Sprint Plan table on the Epics Overview page. If sprint scopes are present, offer to synthesise the missing epic-level scope and add it to each Epic page now (same recovery logic as GitLab above). If sprint scopes are also absent, or the user declines, flag as a confidence gap.

3. **Parse Workflow Status table** from Feature page to check completion status

### Phase 2: Spawn Verification Sub-agents

Spawn parallel sub-agents (one per Epic) to assess documentation quality.

Use `subagent_type: "doc-verifier"` (aidlc plugin agent) for each Epic.

**Convert backend-specific content to normalized format:**

All backends must convert their content to the `VerificationInput` format expected by doc-verifier:

```typescript
interface VerificationInput {
  type: 'feature' | 'epic' | 'task' | 'design' | 'adr';
  backend: 'gitlab' | 'linear' | 'confluence';
  id: string;           // File path, Linear ID, or Confluence page ID
  title: string;
  bodyMarkdown: string; // Content in markdown format
  metadata: GitLabMeta | LinearMeta | ConfluenceMeta;
}
```

**Pass to each sub-agent:**

- Epic content (normalized to `VerificationInput` format)
- Task content for this Epic (normalized array of `VerificationInput`)
- Design documents if available (normalized): Domain model, ADRs
- Feature context: Relevant sections from Level 1 Feature (normalized)

**Detect task format before passing to doc-verifier:**

For each Task, inspect `bodyMarkdown` to classify the format:
- **Task Spec** (AIDLC 3.9+): contains a `## Behaviour` section → set `metadata.taskFormat = "task-spec"`
- **User story** (legacy): contains "As a..." or "Given/When/Then" → set `metadata.taskFormat = "user-story"`
- **Unknown**: neither pattern detected → flag as a documentation gap

Pass `metadata.taskFormat` to doc-verifier so it applies the appropriate quality checklist per format. Both formats are valid through AIDLC 3.9.x.

The `doc-verifier` agent will score each criterion and return JSON with scores, gaps, strengths, and overall confidence.

### Phase 3: Consolidate Results

After all sub-agents return:

1. **Parse JSON results** from each sub-agent
2. **Calculate weighted score** using the category weights
3. **Merge gap lists** across all Epics
4. **Identify cross-cutting gaps** that affect multiple Epics
5. **Rank gaps by impact** (blocking issues first)
6. **Generate Sprint Execution Plan**:
   1. Collect all sprint groupings across all Epics (from sub-agent results and Epics Overview)
   2. Identify sprint-to-sprint dependencies (data, interface, infrastructure) using sub-agent `sprint_dependencies` data
   3. Assign **Phases** (sequential stages): Phase 0 = foundation/setup, then increasing phases for dependent work
   4. Assign **Lanes** within each phase (parallel slots): independent sprints in same phase get different lanes
   5. Identify **Critical Path** (longest dependency chain by estimated duration)
   6. Calculate **Parallelism Opportunities** (max parallel sprints per phase, teams needed)
   7. Generate the **Visual Summary** (ASCII phase/lane diagram)
   8. Flag circular dependencies as blocking gaps
   9. Assess sprint sizing (flag < 2 hours or > 3 days)

   Output: Full Sprint Execution Plan using the template from @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md

### Phase 4: Present Assessment

Present the confidence assessment to the user:

```markdown
## Confidence Assessment Report

### Overall Confidence: XX%

| Epic | Scope | Tasks | Technical | NFRs | Dependencies | Sprints | Score |
|------|-------|-------|-----------|------|--------------|-------|-------|
| Epic 1 | 85 | 90 | 70 | 60 | 80 | 75 | 77% |
| Epic 2 | 90 | 85 | 85 | 75 | 90 | 85 | 85% |
| **Weighted Average** | | | | | | | **81%** |

### Gaps Identified

**High Priority (blocking):**
1. [Epic 1] Task "User Login" missing acceptance criteria
   - Suggestion: Add testable conditions for success/failure

**Medium Priority:**
2. [Epic 1] NFR "performance" lacks specific target
   - Suggestion: Define response time target (e.g., <200ms p95)

### Sprint Execution Plan

#### Phase 0: Foundation
| Lane | Sprint | Epic | Summary | Depends On |
|------|------|------|---------|------------|
| A | Sprint 1.1 | Epic 1 | ... | — |
| B | Sprint 2.1 | Epic 2 | ... | — |

#### Phase 1: Core Domain
| Lane | Sprint | Epic | Summary | Depends On |
|------|------|------|---------|------------|
| A | Sprint 1.2 | Epic 1 | ... | Sprint 1.1 |

#### Critical Path
`Sprint 1.1 → Sprint 1.2 → ...` (X days)

#### Parallelism Opportunities
| Phase | Max Parallel Sprints | Teams Needed |
|-------|-------------------|--------------|
| Phase 0 | 2 | 2 |
| Phase 1 | 1 | 1 |

#### Visual Summary
Phase 0:  [Sprint 1.1]  [Sprint 2.1]
              ↓
Phase 1:  [Sprint 1.2]
              ...

#### Recommendations
1. Start with Phase 0 — foundation sprints unblock everything
2. Critical path bottleneck: [specific sprint]

### Sprint Refinements Needed

1. [Epic 1] Sprint "Auth Flow" contains unrelated Tasks
   - Suggestion: Move Task 3 to a separate Sprint

### Strengths
- Clear scope boundaries across all Epics
- Dependencies well-documented
- Tasks follow proper format

### Recommendation

[Based on score: proceed / address gaps / gather more context]
```

### Phase 5: Decision Gate

Based on confidence level:

**If High (≥80%):**
```
Confidence is HIGH (XX%). Ready to proceed with Jira transfer.

Sprint Execution Plan: X phases, critical path = X days
Project routing: PROJ (+ FRONT if multi-project)
Team assignment: [Team Name(s)]
Sprint dependencies to link: X

Do you want to:
1. Proceed with Jira transfer
2. Address gaps first anyway
3. Adjust project/team routing
4. Cancel
```

**If Medium (60-79%):**
```
Confidence is MEDIUM (XX%). Some gaps identified.

Sprint Execution Plan: X phases, critical path = X days
Project routing: PROJ (+ FRONT if multi-project)
Team assignment: [Team Name(s)]
Sprint dependencies to link: X

Gaps to address:
- [List top 3 gaps]

Do you want to:
1. Address gaps first (recommended)
2. Proceed anyway (override)
3. Adjust project/team routing
4. Cancel
```

**If Low (<60%):**
```
Confidence is LOW (XX%). Significant gaps prevent reliable AI execution.

Critical gaps:
- [List blocking gaps]

Recommended actions:
1. Run `/aidlc-design` if design is missing
2. Update Tasks with missing acceptance criteria
3. Define measurable NFRs
4. Refine Sprint groupings if needed

Cannot proceed to Jira transfer until confidence reaches 60%.
```

### Phase 5.5: Propagate Sprint Rebalancing (if changes made)

If the Sprint Execution Plan generated in Phase 3 differs from the sprint assignments in the source documents (tasks moved between sprints, sprints merged or split), propagate the changes before the Jira transfer.

**Step 1: Generate diff**

If the refined sprint plan differs from the source, show the user a change summary:

```
## Sprint Rebalancing Changes

| Task | From Sprint | To Sprint | Reason |
|------|-----------|---------|--------|
| Task U01-T03 | Sprint 1 | Sprint 2 | Dependency on Sprint 2 foundation |
| Task U02-T01 | Sprint 2 | Sprint 1 | No blocking dependency |

Do you want to propagate these changes to the source documents? (y/n)
```

If no changes: skip this phase.
If user declines: proceed with the updated Sprint Execution Plan only; source documents retain original sprint assignments.

**Step 2: Propagate to backend artifacts (if confirmed)**

**GitLab:**
- Update `sprint:` frontmatter field in each affected task `.md` file
- Update `sprint-plan.md` with the revised sprint groupings
- Commit: `feat(verify): Rebalance sprint assignments`

**Linear:**
- Update `labels` on each affected Issue to reflect the new sprint label
- Create or remove sprint labels if sprints were added or merged

**Confluence:**
- Update the Sprint Plan table on each affected Epic page
- Update each Task page with the new sprint assignment

---

### Backend Branching Point

Based on the backend detected in Phase 1, proceed to the appropriate workflow:

**Linear Backend** → Skip to **Phase 6-Linear: Update Initiative Status** (see below)
- Linear IS the work tracker (no Jira transfer needed)
- Updates happen natively in Linear

**GitLab / Confluence Backends** → Proceed to **Phase 6: Jira Transfer** (see below)
- Transfer documentation to Jira hierarchy
- Create Feature → Epic → Sprint → Task artifacts

---

### Phase 6-Linear: Update Initiative Status (Linear only)

For Linear backend, update the Initiative and Project hierarchy directly (no Jira transfer):

**Step 1: Update Initiative Status**

Update the Initiative (Feature) status to mark it as ready for execution:

```typescript
save_initiative({
  id: "<initiative-id>",
  status: "Active"
})
```

**Step 2: Add Status Update** (optional)

Create a status update on the Initiative documenting the verification results:

```typescript
save_status_update({
  type: "initiative",
  initiative: "<initiative-id>",
  body: "# Verification Complete\n\n**Overall Confidence:** XX%\n\n**Sprint Execution Plan:** X phases, critical path = X days\n\n**Key Findings:**\n- [List top strengths]\n- [List addressed gaps]\n\nReady for implementation via `/aidlc-sprint`.",
  health: "onTrack"  // or "atRisk" / "offTrack" based on confidence
})
```

**Step 3: Update Project and Issue Labels** (optional)

Add verification metadata to Projects (Epics) and Issues (Tasks):

```typescript
// For each Project (Epic):
save_project({
  id: "<project-id>",
  labels: ["verified", "confidence-XX"]
})

// For high-priority or flagged Issues (Tasks):
save_issue({
  id: "<issue-id>",
  labels: ["large-task"]  // if 13+ Story Points
})
```

**Step 4: Report Completion**

Provide summary to user:

```markdown
## Verification Complete (Linear)

**Initiative:** [<Initiative Name>](<linear-url>)
- Status updated to: Active
- Verification status: Posted

**Confidence:** XX%

**Projects (Epics):** X Projects verified
- Project 1: [<name>](<url>) — Confidence XX%
- Project 2: [<name>](<url>) — Confidence XX%

**Issues (Tasks):** X Issues across Y Projects
- **Average Story Points:** X.X points per Issue
- **Large Issues (13+):** [List if any]

**Sprint Execution Plan:**
- **Phases:** X phases
- **Critical path:** Project X → Project Y (estimated XX days)
- **Parallelism:** Up to Y teams can work in parallel

**Next Steps:**
1. Review Initiative and Projects in Linear
2. Assign Issues to team members
3. Begin implementation with Phase 0 Projects
4. Use `/aidlc-sprint` to guide implementation
```

**No Confluence cleanup needed** — Linear is the single source of truth.

---

### Phase 6: Jira Transfer (GitLab/Confluence only)

This phase creates Jira artifacts from verified GitLab or Confluence documentation using the AI-DLC hierarchy:

```
Project (optional) ← Created in /aidlc-intent
└── Feature
    ├── Epic
    │   ├── Story
    │   │   ├── Task
    │   │   ├── Task
    │   └── Story
    │       └── Task
    └── Epic
        └── Story
            └── Task
```

**Sprint** groups Stories/Tasks for scheduling (it is not a hierarchy level).

#### Step 1: Confirm Jira Transfer

**Check team size estimate variance:**

Compare the design-phase team size estimate against the elaborate-phase preliminary estimate (from the Epics Overview or feature document). If the estimates differ by >30% in person-weeks:

```
⚠ Team size estimate has changed significantly:
- Elaborate estimate: X person-weeks
- Design estimate: Y person-weeks
- Variance: Z% (threshold: 30%)

This may affect sprint planning and resourcing. Proceed with the updated estimate? (y/n)
```

If the user declines: pause the Jira transfer and ask them to reconcile the estimates with their team before continuing.

Confirm the user is ready:
- Check if a Project exists (created in `/aidlc-intent`)
  - If exists: Feature will be linked as child of Project
  - If not exists: Ask "No Project exists. Create one now? (optional, recommended for portfolio visibility)"
- Remind them of the Jira hierarchy: Project (optional) → Feature → Epic → Sprint → Task
- Confirm the Sprint Execution Plan (phases, lanes, critical path)
- Confirm project keys and multi-project routing (if applicable)
- Confirm team assignments
- Show the number of dependency links that will be created
- Confirm the refined Sprint groupings are final

#### Step 1a: Detect Story Points Field

Attempt to find the Story Points field for Tasks in the target Jira project:

**Primary approach (acli):**
```bash
# Get any existing issue to discover fields
acli jira workitem search --project "PROJ" --limit 1 --json
# Extract issue key from results
acli jira workitem fields PROJ-123 --json
```

Parse JSON output for fields matching:
- Name patterns: `/story[\s_-]*point/i`, `/estimate/i`
- Field type: numeric
- Common field IDs: `customfield_10016`, `customfield_10026`, `customfield_10000`

**Fallback approach (Atlassian MCP):**
```javascript
// If acli unavailable
getJiraProjectIssueTypesMetadata({
  cloudId: "<cloud-id>",
  projectIdOrKey: "PROJ"
})
// Find Task issue type ID

getJiraIssueTypeMetaWithFields({
  cloudId: "<cloud-id>",
  projectIdOrKey: "PROJ",
  issueTypeId: "<task-type-id>"
})
// Filter for schema.type === "number" and name matching patterns
```

**Outcomes:**
- ✅ Field found: Store field name/ID for Task creation
  - Inform user: "✓ Story Points field detected: [field-name]"
- ⚠️ Field not found: Continue without Story Points
  - Inform user: "⚠️ Story Points field not configured in project"
  - Note in final report under recommendations

**Store for session:** Field name or ID (e.g., `"Story Points"` or `"customfield_10016"`)

#### Step 2: Create Jira Artifacts

**Preferred: Use `acli` CLI** (lower token usage than Atlassian MCP):

```bash
# First check acli is installed
which acli || echo "acli not installed - see: https://developer.atlassian.com/cloud/acli/"
```

**Step 2a: Check for Project and Create Feature**

First, check if a Project exists from `/aidlc-intent`:

1. **Check for Project key:**
   - **GitLab**: Check `intent.md` frontmatter for `jira_project_key` field
   - **Confluence**: Check Workflow Status table for Project key
2. **If Project exists:**
   - Use the Project Jira key as parent for the Feature
3. **If Project doesn't exist:**
   - Ask: "No Project exists. Create one now? (optional, recommended for portfolio visibility)"
   - If yes: Create Project with `aidlc:project` label, store key
   - If no: Proceed without Project (Feature becomes top-level)

Create the Feature (with optional Project parent):

```bash
# Create Feature (with optional parent Project)
acli jira workitem create --project "PROJ" --type "Feature" \
  --summary "<Feature Name>" \
  --description-file intent.md \
  --label "aidlc:feature" \
  --parent "PROJ-50" \  # Optional: Project key if exists
  --json
```

The Feature description should include:
- Feature Summary (from feature document)
- Problem/Opportunity (condensed)
- Target Users
- Outcomes (business + user)
- Scope Summary
- NFRs table
- Top risks
- Measurement criteria
- **Link to full Feature document:**
  - **GitLab**: Link to MR or file in repo
  - **Confluence**: Link to Confluence page

Use the Jira Feature Template from @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md

Save the Feature key (e.g., PROJ-100) for linking Epics.

**Step 2b: Spawn Task-Creator Agents (PARALLEL)**

For each Epic, spawn a task-creator agent to create all Jira artifacts (Epic → Sprint → Task) for that Epic in parallel.

**Prepare input for each agent:**

1. **Fetch Epic content:**
   - **GitLab**: Read Epic markdown file from `epics/<epic-name>/epic.md`
   - **Confluence**: Read the Epic's Confluence page
   - Store full markdown content

2. **Fetch all Task pages for this Epic:**
   - **GitLab**: Read all Task markdown files from `epics/<epic-name>/tasks/*.md`
   - **Confluence**: Query Confluence for all Task pages under this Epic
   - Store each Task's title and full markdown content

3. **Extract Sprint metadata from Sprint Execution Plan:**
   - Filter Sprints for current Epic: `WHERE epic == current_epic_name`
   - For each Sprint, collect:
     - `sprint_name` (e.g., "Sprint 1.1: Login Flow")
     - `sprint_type` (e.g., `"backend"` / `"frontend"` / `"fullstack"`) — derive from Sprint task content if not explicitly stated; used for the `sprint-type:<type>` Jira label
     - `project_key` (from multi-project routing if configured, else primary project)
     - `phase` (execution phase number)
     - `lane` (parallel lane identifier)
     - `team` (optional team assignment)
     - `depends_on` (array of Sprint names this Sprint depends on)
     - `estimated_duration` (e.g., "2 days")
     - `on_critical_path` (boolean)
     - `tasks` (array of Task titles in this Sprint)

4. **Pass Story Points field config:**
   - Field name and ID from Step 1a (or `null` if not detected)

5. **Pass Feature Jira key:**
   - Feature key created in Step 2a

6. **Pass Atlassian credentials:**
   - `cloud_id` and optional `region_url`

**Spawn all agents in parallel:**

```
Use Task tool with subagent_type="task-creator" (AIDLC plugin agent) for each Epic.

Spawn ALL agents in a single Task tool call with multiple agents (parallel execution).
```

**Agent input schema:**

```json
{
  "epic": {
    "name": "User Authentication",
    "confluence_content": "<full Epic page markdown>",
    "feature_jira_key": "PROJ-100",
    "primary_project_key": "PROJ"
  },
  "sprints": [
    {
      "sprint_name": "Sprint 1.1: Login Flow",
      "sprint_type": "backend",
      "project_key": "PROJ",
      "phase": 0,
      "lane": "A",
      "team": "Backend Team",
      "depends_on": [],
      "estimated_duration": "2 days",
      "on_critical_path": true,
      "tasks": ["Implement password validation", "Add login API"]
    }
  ],
  "tasks": [
    {
      "task_title": "Implement password validation",
      "confluence_content": "<full Task page markdown>"
    }
  ],
  "story_points_field": {
    "field_name": "Story Points",
    "field_id": "customfield_10016"
  },
  "cloud_id": "<atlassian-cloud-id>",
  "region_url": "https://us.sentry.io"
}
```

**Wait for all agents to complete** before proceeding to Step 2c.

**Step 2c: Consolidate Agent Results**

After all task-creator agents return, consolidate their results:

1. **Parse JSON results** from each agent

   Each agent returns:
   ```json
   {
     "epic_name": "User Authentication",
     "epic_jira_key": "PROJ-123",
     "epic_url": "https://jira.../PROJ-123",
     "sprints": [
       {
         "sprint_name": "Sprint 1.1: Login Flow",
         "sprint_jira_key": "PROJ-124",
         "sprint_url": "https://jira.../PROJ-124",
         "project_key": "PROJ",
         "phase": 0,
         "lane": "A",
         "team": "Backend Team",
         "depends_on": ["Sprint 1.2"],
         "on_critical_path": true,
         "tasks": [
           {
             "task_name": "Implement password validation",
             "task_jira_key": "PROJ-125",
             "task_url": "https://jira.../PROJ-125",
             "story_points": 5,
             "story_points_applied": true
           }
         ]
       }
     ],
     "story_points_summary": {
       "total_points": 42,
       "task_count": 8,
       "average_points": 5.25,
       "distribution": {"3": 2, "5": 4, "8": 1, "13": 1},
       "large_tasks": [
         {"key": "PROJ-130", "points": 13, "title": "Complex auth flow"}
       ]
     },
     "test_scope_posted": {
       "epic_level": true,
       "sprints": {"Sprint 1.1: Login Flow": true}
     },
     "errors": []
   }
   ```

   > **Test scope transfer**: Each task-creator agent reads the `## Test Scope` section from the Epic page content and posts per-Sprint scenarios as comments on each Sprint in Jira. The agent also posts epic-level integration scenarios as a comment on the Epic. No separate step needed — it is handled automatically by the agent.

2. **Build sprint_name → sprint_key map** for dependency linking:

   Iterate through all agents' results and collect:
   ```json
   {
     "Sprint 1.1": {
       "sprint_key": "PROJ-124",
       "depends_on": []
     },
     "Sprint 1.2": {
       "sprint_key": "PROJ-128",
       "depends_on": ["Sprint 1.1"]
     },
     "Sprint 2.1": {
       "sprint_key": "PROJ-135",
       "depends_on": ["Sprint 1.1", "Sprint 1.2"]
     }
   }
   ```

3. **Aggregate Story Points** across all Epics:

   - `total_points`: Sum of all Epics' `story_points_summary.total_points`
   - `task_count`: Sum of all Epics' `story_points_summary.task_count`
   - `average_points`: `total_points / task_count`
   - `distribution`: Merge all Epics' distributions
   - `large_tasks`: Concatenate all Epics' `large_tasks` arrays

4. **Collect errors** from all agents:

   Group by error type:
   - Epic-level failures (agent aborted)
   - Sprint creation failures
   - Task creation failures
   - Story Points write failures

5. **Report partial success** if any agents failed:

   Example:
   ```
   ✅ Successfully created artifacts for Epics: 1, 2, 4, 5
   ❌ Failed for Epic: 3 (error: API timeout)

   Retry Epic 3? (y/n)
   ```

**Validation:**
- Verify all Epics have `epic_jira_key` (or are in errors)
- Verify sprint_name → sprint_key map is complete
- Check for duplicate Sprint names (should not happen)

**Store for Step 3:** sprint_name → sprint_key map
**Store for Step 4:** Aggregated Sprint metadata with Jira keys
**Store for Step 7:** Aggregate Story Points summary and errors

#### Step 3: Link Sprint Dependencies

Use the sprint_name → sprint_key map from Step 2c to create dependency links between Sprints:

1. **Iterate through sprint_name → sprint_key map**

   For each Sprint with non-empty `depends_on` array:

2. **Lookup Jira keys:**
   - Current Sprint: `sprint_name → sprint_key` (e.g., "Sprint 1.2" → "PROJ-456")
   - Each dependency: `depends_on[i] → sprint_key` (e.g., "Sprint 1.1" → "PROJ-455")

3. **Create link for each dependency:**

   ```bash
   # Sprint 1.2 (PROJ-456) is blocked by Sprint 1.1 (PROJ-455):
   acli jira workitem link PROJ-456 PROJ-455 --link-type "blocks"
   ```

   **Link type:** "blocks" (the dependency blocks the current Sprint)

4. **Verify links were created:**

   Optional verification:
   ```bash
   acli jira workitem view PROJ-456 --fields "issuelinks" --json
   ```

5. **Handle cross-project dependencies:**

   Links work across projects (no special handling needed)

**Fallback:** If `acli` is not available or linking fails, dependencies are already documented in each Sprint's description by the task-creator agents:
```
**Blocked by:** Sprint 1.1 (Jira key will be linked by parent agent)
```

Update these descriptions with actual Jira keys:
```
**Blocked by:** PROJ-455 (Sprint 1.1)
```

#### Step 4: Update Sprint Execution Plan in Confluence

Backfill the Sprint Execution Plan on the Epics Overview page with created Jira Sprint keys from Step 2c:

1. **Read the Epics Overview page** (contains Sprint Execution Plan table)

2. **Parse existing plan table** to locate each Sprint row

3. **Lookup Jira Sprint keys** from consolidated results (sprint_name → sprint_key map)

4. **Update table** with Jira keys:

   | Lane | Sprint | Epic | Summary | Depends On | Jira Sprint |
   |------|------|------|---------|------------|------------|
   | A | Sprint 1.1 | Epic 1 | ... | — | [PROJ-455](https://jira.../PROJ-455) |
   | B | Sprint 2.1 | Epic 2 | ... | Sprint 1.1 | [PROJ-458](https://jira.../PROJ-458) |

5. **Update Confluence page** using `updateConfluencePage` tool

**Result:** Sprint Execution Plan becomes a live reference with clickable links to Jira Sprints.

#### Step 5: Update Workflow Status (backend-specific)

**GitLab Backend:**

1. **Update `intent.md` frontmatter** with Jira artifact keys:
   ```yaml
   ---
   status: verified
   jira_project_key: PROJ
   jira_intent_key: PROJ-100
   jira_epics:
     - unit: 1
       key: PROJ-123
     - unit: 2
       key: PROJ-135
   verified_date: YYYY-MM-DD
   confidence_score: XX
   ---
   ```
2. **Update Workflow Status table** in `intent.md`:
   - Set "Verify" row to "✅ Complete" with today's date
3. **Update Sprint Execution Plan** in `intent.md` with Jira Sprint keys
4. **Commit and push** verification results:
   ```bash
   cd "$AIDLC_DOCS_PATH"
   git add .
   git commit -m "feat(verify): Add Jira artifact keys and verification results"
   git push origin "<intent-branch>"
   ```
5. **Mark MR ready for merge** (removes draft status):
   ```bash
   glab mr update <MR_ID> --ready
   ```
6. **Add MR comment** with Jira artifact links summary

**Confluence Backend:**

1. Update the Confluence Feature page status table:
   - Set "Verification" row to "✅ Complete" with today's date
   - Add links to created Epics in the Artifact column

#### Step 6: Cleanup (backend-specific)

**GitLab Backend:**
- No cleanup needed — all files remain in the Feature branch and MR
- The MR is now ready for final review and merge

**Confluence Backend:**

After successful Jira creation, delete the Confluence pages to avoid confusion:
- Delete all Task pages
- Delete all Epic pages
- Delete the Epics Overview page

**Important**: Keep the Feature document and Design documents — only delete the decomposition pages.

#### Step 7: Report Back

Provide aggregate results from all task-creator agents:

**Created Jira Artifacts:**
- **Project:** [PROJ-50](https://jira.../PROJ-50) (if created)
- **Feature:** [PROJ-100](https://jira.../PROJ-100) "<Feature Name>"
- **Epics:** X Epics created
  - Epic 1: [PROJ-123](https://jira.../PROJ-123)
  - Epic 2: [PROJ-135](https://jira.../PROJ-135)
  - ...
- **Sprints:** X Sprints created across Y projects
  - Example: [PROJ-124](https://jira.../PROJ-124) "Sprint 1.1: Login Flow"
- **Tasks:** X Tasks created

**Aggregate Story Points Summary (if field detected):**
- **Total points:** XX points across YY Tasks (all Epics)
- **Average per Task:** X.X points
- **Distribution:** X tasks @ 3pts, X @ 5pts, X @ 8pts, X @ 13pts
- **⚠️ Large tasks (13+ points):** [PROJ-789 (13pts), PROJ-790 (21pts)]
  - Recommendation: Consider splitting these tasks in future iterations or during implementation

**If Story Points field not detected:**
- ⚠️ Story Points field not configured in project PROJ
- Recommendation: Configure Story Points field in Jira project settings → Issue Types → Task → Fields

**Errors (if any):**

- **Epic-level errors (agent failures):**
  - Epic 3 (User Authentication): API timeout during Epic creation
  - Action: Retry agent for Epic 3, or create manually

- **Sprint/Task creation failures:**
  - X Sprints failed to create (see errors array)
  - Y Tasks failed to create (see errors array)

- **Story Points write failures:**
  - Z Tasks created without Story Points (field not writable)
  - Recommendation: Check Jira field permissions

**Sprint Execution Plan:**
- **Phases:** X phases identified
- **Critical path:** Sprints X.X → Y.Y → Z.Z (estimated XX days)
- **Parallelism:** Up to Y teams can work in parallel during Phase Z
- **Updated in Confluence:** Sprint Execution Plan table backfilled with Jira Sprint keys

**Dependency Links:**
- **Created:** X dependency links between Sprints
- **Examples:**
  - PROJ-456 (Sprint 1.2) blocked by PROJ-455 (Sprint 1.1)
  - PROJ-460 (Sprint 2.2) blocked by PROJ-458 (Sprint 2.1)

**Team/Project Routing:**
- **Projects:** Artifacts created in X projects (PROJ, FRONT, API, etc.)
- **Teams:** Y teams assigned to Sprints (Backend Team, Frontend Team, etc.)

**Execution Order Recommendation:**
- Start with Phase 0 Sprints (no dependencies)
- Lanes A, B, C can execute in parallel
- Phase 1 begins after all Phase 0 Sprints complete
- Follow critical path to minimize overall duration

**Backend-Specific Updates:**

*GitLab:*
- ✅ `intent.md` frontmatter updated with Jira keys and verification results
- ✅ Sprint Execution Plan table updated with Jira Sprint keys
- ✅ Verification results committed and pushed to Feature branch
- ✅ MR marked ready for merge (draft status removed)
- ✅ MR comment posted with Jira artifact links summary

*Confluence:*
- ✅ Epics Overview page deleted
- ✅ All Epic pages deleted (X pages)
- ✅ All Task pages deleted (Y pages)
- ✅ Feature page status table updated to "Verification: ✅ Complete"

**Final Confidence Score:** X.XX / 5.00 (for reference)

**Next Steps:**
1. Review Jira Feature and Epics to verify completeness
2. Assign Sprints to teams based on Lane assignments
3. Begin implementation starting with Phase 0
4. Use `/aidlc-sprint` to guide TDD implementation of each Sprint

## Workflow Chain

- **Previous**: `/aidlc-design` (Domain and Logical Design)
- **Next**: Implementation

## Definition of Done

### Verification Complete
- All Epics assessed by verification sub-agents
- Confidence score calculated with weighted average
- Gaps identified and categorized
- Sprint groupings reviewed and refined
- Sprint Execution Plan generated with phases, lanes, critical path
- Parallelism opportunities documented (teams per phase)
- Sprint sizing validated (2h-3d range)
- Circular dependencies flagged
- Assessment report presented to user

### GitLab Backend Complete (if approved)
- Feature `intent.md` frontmatter updated: `status: verified`
- Jira Project created with `aidlc:project` label (optional)
- Jira Feature created with `aidlc:feature` label (linked to Project if exists)
- Feature description includes link to GitLab MR or file in repo
- One task-creator agent spawned per Epic (parallel execution)
- Epics created in Jira and linked to Feature with `aidlc:epic` label
- Sprints created under their respective Epics with `aidlc:sprint` label
- Tasks created under their respective Sprints
- Story Points field detected (or gracefully handled if missing)
- Tasks scored using Fibonacci scale (1, 2, 3, 5, 8, 13, 21+)
- Story Points applied to Tasks (if field configured)
- Large tasks (13+) flagged in aggregate report
- Story Points aggregated across all Epics in final report
- All Task Spec behaviour/rules or user story acceptance criteria transferred to Tasks (format detected automatically)
- Sprint-to-sprint dependency links created across Epics ("blocks"/"is blocked by")
- Team assignments applied (if configured)
- Multi-project routing applied (if configured)
- ADR and design doc links included in Epic descriptions
- Design label added if design exists (`aidlc:designed`)
- Sprint Execution Plan updated with Jira Sprint keys (document in GitLab)
- Agent errors collected and reported
- Partial success handled (some Epics succeed, some fail)
- GitLab commit created with verification results
- GitLab MR updated with Jira artifact links

### Linear Backend Complete (if approved)
- Initiative (Feature) status updated to "Active"
- Status update posted to Initiative with verification results summary
- Projects (Epics) labeled with `verified` and `confidence-XX` tags
- Issues (Tasks) labeled with `large-task` if 13+ Story Points
- Story Points estimated using Fibonacci scale (1, 2, 3, 5, 8, 13, 21+)
- Story Points applied to Issues
- Large Issues (13+) flagged in aggregate report
- All acceptance criteria transferred to Issue descriptions
- Sprint groupings documented in Project descriptions
- Sprint Execution Plan documented in Initiative status update
- Agent errors collected and reported (if any)
- No Jira transfer (Linear is the work tracker)
- No Confluence cleanup (Linear is single source of truth)

### Confluence Backend Complete (Jira Transfer, if approved)
- Jira Project created with `aidlc:project` label (optional)
- Feature created with `aidlc:feature` label (linked to Project if exists)
- Feature description includes link to Confluence page
- One task-creator agent spawned per Epic (parallel execution)
- Epics created and linked to the Feature with `aidlc:epic` label
- Sprints created under their respective Epics with `aidlc:sprint` label
- Tasks created under their respective Sprints
- Story Points field detected (or gracefully handled if missing)
- Tasks scored using Fibonacci scale (1, 2, 3, 5, 8, 13, 21+)
- Story Points applied to Tasks (if field configured)
- Large tasks (13+) flagged in aggregate report
- Story Points aggregated across all Epics in final report
- All Task Spec behaviour/rules or user story acceptance criteria transferred to Tasks (format detected automatically)
- Sprint-to-sprint dependency links created across Epics ("blocks"/"is blocked by")
- Team assignments applied (if configured)
- Multi-project routing applied (if configured)
- ADR and design doc links included in Epic descriptions
- Design label added if design exists (`aidlc:designed`)
- Sprint Execution Plan updated with Jira Sprint keys in Confluence
- Agent errors collected and reported
- Partial success handled (some Epics succeed, some fail)
- Confluence decomposition pages deleted (Overview, Epics, Tasks)
- Feature page status table updated to "Verification: ✅ Complete"

## Troubleshooting

### Backend Detection Issues
- **Backend not detected**: Ensure Feature artifact has proper metadata (GitLab: frontmatter with `backend: gitlab`, Linear: `linear_initiative_id`, Confluence: page with status table)
- **Wrong backend detected**: Verify Feature metadata matches actual backend used
- **Multiple backends detected**: Choose one as source of truth; migrate artifacts if needed

### GitLab-Specific Issues
- **Git repo not found**: Verify `"$AIDLC_DOCS_PATH"` exists and is up to date (`git pull`)
- **Branch not found**: Check branch naming convention `intent/<project-slug>/<intent-slug>`
- **Frontmatter missing fields**: Ensure `intent.md` has `backend`, `status`, and optional `jira_project_key`
- **Epic/Task files not found**: Verify file structure: `epics/<epic-name>/epic.md` and `epics/<epic-name>/tasks/<task-name>.md`
- **Git push fails**: Check authentication with `glab auth status` or `git config --list`
- **MR update fails**: Verify `glab` CLI is installed and authenticated

### Linear-Specific Issues
- **Initiative not found**: Verify Initiative ID from `/aidlc-intent` output
- **Linear MCP not responding**: Check Linear authentication and API token
- **Status update fails**: Ensure Initiative exists and user has write permissions
- **Projects not created**: Linear Projects may not have been created in `/aidlc-elaborate`; verify with `list_projects`
- **Issues not created**: Check Project ID and ensure parent hierarchy is correct
- **Labels not applied**: Verify label names are valid (no spaces, lowercase preferred)

### Confluence/Jira Issues (legacy)
- **Project not supported**: Some Jira projects may not have Advanced Roadmaps. Skip Project level and use Feature as top-level artifact.
- **Epic issue type not supported**: If Jira project lacks Epic type, use alternative type + issue links or parent field; ask for preferred structure.
- **Sprint issue type not available**: Some projects may use different names; use `getJiraProjectIssueTypesMetadata` to find the right type for Sprints.
- **Task issue type not supported**: If Jira project lacks Task type, use alternative type with parent link or issue links instead.
- **Missing issue types**: Use `getJiraProjectIssueTypesMetadata` and confirm available types.
- **Low confidence score**: Guide user to address specific gaps; offer to re-run verification after updates.
- **Sub-agent failure**: Report which Epic verification failed and offer to retry or assess manually.
- **Confluence page deletion fails**: Verify permissions; may need admin to delete pages.
- **Design missing**: Confidence will be lower; recommend running `/aidlc-design` first but allow override.
- **User wants to skip verification**: Allow with explicit confirmation, but warn that AI execution quality may suffer.
- **Sprint groupings unclear**: Review proposed Sprints in Epics Overview; may need to regroup Tasks before transfer.
- **Tasks span multiple Sprints**: Each Task should belong to exactly one Sprint; resolve before Jira transfer.
- **`acli` not installed for linking**: Document dependencies in Sprint descriptions instead; instruct user to manually create links later.
- **Team field not found in Jira**: Use `acli jira workitem fields PROJ-123` to discover the correct field name for team assignment.
- **Cross-project Tasks**: Jira constraint — Tasks must be in the same project as their parent Sprint. Route at the Sprint level, not Task level.
- **Circular sprint dependencies detected**: Flag as blocking gap. Must restructure into a DAG (directed acyclic graph) before transfer.
- **Too many phases in execution plan**: Consolidate phases where sprints have no actual inter-phase dependencies.
- **Single lane per phase (no parallelism)**: Flag for team to consider splitting sprints or adjusting dependencies to enable parallel work.
- **Story Points field not found**: Cause: Jira project doesn't have Story Points field configured. Resolution: Workflow continues without Story Points. Recommend team enable Story Points field in project settings. Check: Use Jira admin interface → Project Settings → Issue Types → Task → Fields
- **Story Points field is read-only**: Cause: Jira permissions or field configuration. Resolution: Tasks created without Story Points. Recommend manual addition or permission update.
- **Story Points value rejected**: Cause: Jira field validation rules (e.g., only allows 0.5, 1, 2, 3, 5, 8, 13). Resolution: Use default value 5 or skip Story Points for that task. Check: Verify field configuration allows Fibonacci values (1, 2, 3, 5, 8, 13, 21)
- **Epic-creator agent fails entirely**: Cause: Critical error (Epic creation failed). Resolution: Retry agent for that Epic only. Other Epics' artifacts are preserved. Check agent error output for specific failure reason (API timeout, permissions, invalid parent Feature key).
- **Partial Epic success**: Cause: Some Sprints/Tasks created, others failed during agent execution. Resolution: Partial Jira artifacts exist for this Epic. Manual creation needed for failed items. Check `errors` array in agent output to identify failed Sprints/Tasks. Query Jira: `labels = aidlc:epic AND parent = PROJ-100` to see what was created.
- **Agent timeout**: Cause: Large Epic with 50+ Tasks, network latency, or Jira API rate limiting. Resolution: Retry agent with same Feature key. Duplicate detection: Check for existing Epic with `aidlc:epic` label and matching Feature parent before creating. If Epic exists, skip creation and resume at Sprint creation.
- **Sprint dependency linking fails**: Cause: `acli` not installed, network issue, or invalid Sprint keys in sprint map. Resolution: Dependencies already documented in Sprint descriptions by agents ("Blocked by: Sprint 1.1"). Manually create links later using Jira Query: `labels = aidlc:sprint` to find all Sprints, then use UI or `acli jira workitem link` to create links.
