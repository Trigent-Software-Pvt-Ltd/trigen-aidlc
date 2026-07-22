---
name: aidlc-elaborate
description: Decompose an approved Feature into Epics using Mob Elaboration. Proposes Epic boundaries, initial Sprint groupings, and indicative work-item scopes. Task Specifications are generated later in /aidlc-design after ADRs and domain model are complete. Supports GitLab (markdown files with MR review), Linear (native Projects), or Confluence (pages with Jira). (Triggers - decompose feature, break down feature, create epics, epic decomposition, create tasks, break into epics, split feature, aidlc decompose, mob elaboration)
---

# AI-DLC Decompose (Mob Elaboration)

Break down an approved Feature into Epics using the AI-DLC Mob Elaboration ritual. This skill uses parallel agents to analyse theme clusters and propose Epic boundaries. Supports three backends:
- **GitLab** (recommended): Markdown files in git repo with MR-based review
- **Linear**: Native Linear Projects (Epics only — Issues created in `/aidlc-design`)
- **Confluence**: Pages with Jira integration (legacy)

> **AIDLC 3.9+ flow: Epics first, Tasks second**
>
> This skill creates **Epics only**. Task Specifications are generated in `/aidlc-design` after ADRs and the domain model are complete — at that point the AI has enough implementation context to populate `files`, `behaviour`, and `rules` accurately.
>
> **Backward compatibility:** Projects created before AIDLC 3.9 may have task files, issues, or pages from the elaborate phase. Those projects continue to work — `/aidlc-design` detects and offers to regenerate existing tasks as Task Specs, and `/aidlc-verify` accepts both formats.

Do not create Bugs unless explicitly requested by a human.

> **AI-DLC Mob Elaboration**
>
> Per AI-DLC methodology: "AI plays a central role in proposing an initial breakdown
> of the Feature into Tasks, Acceptance Criteria, Epics, and Sprint groupings, leveraging
> domain knowledge, and the principles of loose coupling and high cohesion for rapid
> parallel execution downstream."
>
> Epics are cohesive, self-contained work elements (analogous to Subdomains in DDD).
> Tasks are grouped into Sprints (rapid iteration cycles) for implementation.
> Jira artifacts are created later in `/aidlc-verify` after design and verification.

> **CRITICAL: Documentation First, Work Tracking Later**
>
> This skill has FOUR phases with approval gates between them:
> - **Phase 1**: Propose Epic boundaries and create Epic documentation (GitLab: epic `.md` files / Linear: Projects only / Confluence: Epic pages only). **NO task files, issues, or pages. NO Jira creation.**
> - **Phase 2**: Team reviews (GitLab: MR comments / Linear: Linear comments / Confluence: inline/footer comments). *(Human activity)*
> - **Phase 3**: Comment resolution session - address feedback, update content, resolve comments.
> - **Phase 4**: Re-assess and refine Epic boundaries, update Sprint groupings.
>
> **Work tracking:**
> - **GitLab/Confluence**: Jira transfer happens in `/aidlc-verify` after design and verification
> - **Linear**: Projects (Epics) created here. Issues (Tasks) created in `/aidlc-design`. No Jira transfer needed.
> **DO NOT** skip phases without explicit user approval.

## Completion Checklist

> **IMPORTANT**: Create tasks for each step at the start using `TodoWrite`. Mark tasks complete as you go using `TodoWrite`. Each task description should reference the corresponding Workflow step.

### Phase 1: Epic Decomposition

| # | Task | Depends On | Workflow Reference | Exit Criteria |
|---|------|------------|-------------------|---------------|
| 1 | Validate prerequisites | — | Prerequisites section | Feature artifact exists and shows "Feature: ✅ Approved" (GitLab: intent.md / Linear: Initiative / Confluence: page) |
| 2 | Gather context | 1 | Phase 1 > Step 1 | Backend detected, Feature reference collected, work tracking key collected (if applicable) |
| 3 | Identify theme clusters | 2 | Phase 1 > Step 3 | 3-5 clusters identified, user confirms |
| 4 | Spawn theme analysis subagents | 3 | Phase 1 > Step 4 | All subagents launched (one per theme) |
| 5 | Consolidate subagent results | 4 | Phase 1 > Step 5 | Epic proposals merged, cross-cutting deps classified, epic boundaries confirmed with user |
| 6 | Confirm Epic boundaries | 5 | Phase 1 > Step 6 | Epics defined with scope, indicative work items, and inter-epic dependencies |
| 7 | Propose Sprint groupings | 6 | Phase 1 > Step 7 | Initial Sprint proposals with phase/lane assignments presented; sprint execution plan included |
| 8 | Suggest team size | 7 | Phase 1 > Step 7b | Team size recommendation generated and presented to user |
| 9 | Create Epic documentation | 7, 8 | Phase 1 > Step 8 | GitLab: epic .md files committed / Linear: Projects created / Confluence: Epic pages created |
| 10 | Request team review | 9 | Phase 1 > Step 9 | User notified to review Epics and Sprint proposals |

### Phase 3: Comment Resolution (after human review)

| # | Task | Depends On | Workflow Reference | Exit Criteria |
|---|------|------------|-------------------|---------------|
| 11 | Fetch all comments | 10 | Phase 3 > Step 10 | GitLab: MR comments / Linear: Issue comments / Confluence: Inline+footer comments fetched |
| 12 | Address feedback | 11 | Phase 3 > Step 11 | Each comment analyzed, action determined |
| 13 | Update content | 12 | Phase 3 > Step 12 | GitLab: .md files updated / Linear: descriptions updated / Confluence: pages updated |
| 14 | Reply to comments | 13 | Phase 3 > Step 13 | Replies posted explaining how feedback was addressed |
| 15 | Mark comments resolved | 14 | Phase 3 > Step 14 | User informed which comments need manual resolution |

### Phase 4: Epic Re-assessment

| # | Task | Depends On | Workflow Reference | Exit Criteria |
|---|------|------------|-------------------|---------------|
| 16 | Apply re-assessment criteria | 15 | Phase 4 > Step 15 | Each Epic evaluated against 5 criteria, findings presented |
| 17 | Regroup Epics if needed | 16 | Phase 4 > Step 16 | GitLab: epic files moved / Linear: Projects reorganised / Confluence: Epic pages moved, or user confirms no changes |
| 18 | Update Sprint Plan | 17 | Phase 4 > Step 17 | GitLab: sprint-plan.md updated / Linear: Initiative description updated / Confluence: Overview page updated |
| 19 | Update workflow status | 18 | Phase 4 > Step 18 | Status shows "Epic Decomposition: ✅ Complete" |

## Task Tracking

When this skill is invoked:

1. **Create tasks** for the current phase's checklist items using `TodoWrite`
   - Include a reference to the workflow step in the task description (content field)
   - Set activeForm appropriately (e.g., "Validating prerequisites" for content "Validate prerequisites")
   - Example: `"Validate prerequisites (See Prerequisites section)"`
2. **Mark task as in_progress** when starting each step using `TodoWrite` (update status)
3. **Mark task complete** when the exit criteria are met using `TodoWrite` (update status)
4. **At phase boundaries**, create tasks for the next phase
5. **Verify all phase tasks complete** before stopping at a gate

This ensures visibility into progress and prevents incomplete execution.

## Example Invocations

- "Break down the authentication feature into Tasks and Epics"
- "Decompose the billing feature"
- "Create Epics and Tasks for the API migration feature"
- "Split the approved feature into work items"

## References

- @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md - Templates, Sprint guidance, subagent prompts, and tool names
- @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md - Backend detection and BackendContext interface
- @${CLAUDE_PLUGIN_ROOT}/references/backends/gitlab.md - GitLab-specific operations
- @${CLAUDE_PLUGIN_ROOT}/references/backends/linear.md - Linear-specific operations
- @${CLAUDE_PLUGIN_ROOT}/references/backends/confluence.md - Confluence-specific operations

## Prerequisites

Before starting, validate:

1. **Backend Detection**
   - Determine backend from Feature artifact (see @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md):
     - **GitLab**: Look for `.md` file with `backend: gitlab` in YAML frontmatter, or check if working directory is ai-dlc-docs repo
     - **Linear**: Check for Linear Initiative ID or URL in context (`https://linear.app/team/initiative/...`)
     - **Confluence**: Check for Confluence page URL or ID (`https://xxx.atlassian.net/wiki/spaces/.../pages/...`)
   - If backend cannot be detected, prompt user to provide Feature artifact reference

2. **Required artifacts (backend-specific)**
   - **GitLab**: Feature markdown file exists, MR created, frontmatter shows `status: approved`
   - **Linear**: Initiative exists with status "Active", Initiative ID/URL provided
   - **Confluence**: Feature page exists, Workflow Status table shows "Feature: ✅ Approved"

3. **Optional artifacts** (recommended for portfolio visibility)
   - **GitLab/Confluence**: Jira Project (with `aidlc:project` label) may exist from `/aidlc-intent`
     - If no Project, note it can be created later in `/aidlc-verify`
   - **Linear**: N/A - Linear IS the work tracker (Projects and Issues are created in this skill)

4. **If prerequisites incomplete**
   - Offer to run `/aidlc-intent` first if Feature artifact is missing or not approved
   - Or allow override with explicit confirmation (see Override Pattern in @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md)

## Documentation Hierarchy

Tasks and Epics are organized differently depending on the backend:

### GitLab File Structure (after elaborate)
```
Projects/<Project>/Feature <N> - <Title>/
├── intent.md (existing)
├── sprint-plan.md           ← initial Sprint grouping proposals
└── epics/
    └── epic-NN-<slug>/
        └── epic.md            ← Problem statement, target users, scope, success metrics, ACs, indicative tasks
```

> **Note:** `tasks/task-*.md` files and `adrs/` directories are created later by `/aidlc-design`.

### Linear Object Hierarchy (after elaborate)
```
Initiative (Feature, existing)
├── Project 1: Epic <NN>: <Title> (linked to Initiative)
├── Project 2: Epic <NN>: <Title>
└── ...
```

> **Note:** Issues (Tasks) are created later by `/aidlc-design`.

### Confluence Page Hierarchy (after elaborate)
```
Feature Document (existing)
└── Epics Overview (child of Feature)
    ├── Service Context: <Service 1> (persisted structural scan)
    ├── Service Context: <Service 2> (persisted structural scan)
    ├── Epic 1: [Name] (child of Overview)
    ├── Epic 2: [Name] (child of Overview)
    └── ...
```

> **Note:** Task pages (children of Epic pages) are created later by `/aidlc-design`.

**Sprint groupings** are documented in the Epics Overview and epic files as initial proposals. They are refined in `/aidlc-verify` before Jira transfer.

**Work tracking:**
- **GitLab/Confluence**: Jira transfer happens in `/aidlc-verify` (Project → Feature → Epic → Story → Task; Sprints group Stories/Tasks for scheduling)
- **Linear**: Projects (Epics) are native. Issues (Tasks) created in `/aidlc-design`. No Jira transfer needed.

## Workflow

### Phase 1: Epic Decomposition to Documentation

**In this phase, you will:**
1. Detect backend from Feature artifact (see Prerequisites)
2. Collect backend-specific references (file path, Initiative ID, page ID, etc.)
3. Read Feature content to understand the project
4. Spawn subagents to analyse theme clusters and propose Epic scopes in parallel
5. Create Epic documentation artifacts:
   - **GitLab**: Epic directories in `epics/epic-NN-<slug>/` with `epic.md` only
   - **Linear**: Projects (Epics) only — no Issues
   - **Confluence**: Pages for Epics Overview and Epics only — no Task pages
6. Propose initial Sprint groupings
7. Discuss and refine with the user

**DO NOT in Phase 1:**
- Create task files, issues, or pages (these are created in `/aidlc-design`)
- Create Jira issues (transfer happens in `/aidlc-verify`)
- Update workflow status (happens in Phase 4)

#### Step 1: Gather Context and Detect Backend

1. **Detect backend** from Feature artifact:
   - Check for GitLab frontmatter (`backend: gitlab`), Linear Initiative ID, or Confluence page ID
   - See @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md for detection logic

2. **Collect backend-specific references**:
   - **GitLab**: Feature file path, git branch, MR URL, project name, Feature number
   - **Linear**: Initiative ID/URL, team ID, team key
   - **Confluence**: Feature page ID, space key, parent page ID

3. **Collect optional work tracking info**:
   - **GitLab/Confluence**: Jira project key (if created in `/aidlc-intent`, otherwise note for `/aidlc-verify`)
   - **Linear**: N/A - work tracking is native

4. **Ask for missing info**:
   - Any known constraints, dependencies, or sequencing needs

#### Step 3: Identify Theme Clusters

Analyze the Feature and identify 3-5 theme clusters for parallel elaboration:
- Group related functionality/capabilities together
- Each cluster should have low coupling to other clusters
- **Assign brown-field or green-field tags using the service inventory** from the Feature document:
  - Read the service inventory table to determine which services are brown-field vs. green-field
  - Map each cluster to the relevant service(s) from the inventory
  - A cluster is **brown-field** if it touches any brown-field service
  - A cluster is **green-field** only if all its services are green-field
  - If the Feature has no service inventory, fall back to checking whether code exists for each cluster's functional area (ask the user to confirm pathway for ambiguous cases)
- Present the clusters **with proposed tags** to the user for confirmation

Example output:
```
Based on the Feature, I've identified these theme clusters:
1. **Authentication & Authorization** [brown-field] - Refactor login, add SSO, update permissions (4 Tasks)
2. **API Layer** [brown-field] - New endpoints in existing API, validation, rate limiting (3 Tasks)
3. **Event Processing Service** [green-field] - New service for async event handling (3 Tasks)

I'll gather project context for each cluster, then spawn 3 subagents to elaborate in parallel.
```

#### Step 3b: Scan Repositories and Gather Context

Perform a ONE-TIME structural scan of each brown-field repository listed in the service inventory. This scan happens once per repo — not once per cluster — to avoid redundant scanning when multiple clusters touch the same codebase.

**For each brown-field repo in the service inventory**, spawn an Explore sub-agent to scan the repository and return a structured summary. **Spawn all repo sub-agents in a single message** for parallel execution.

```
Task tool call:
  subagent_type: "Explore"
  description: "Scan <repo-name> for service boundaries"
  prompt: |
    Perform a medium-depth scan of the repository at <repo-path> to map its service boundaries and contracts.

    Return a structured summary covering:
    1. **Directory layout** — Key folders (e.g., src/, Controllers/, Services/, Handlers/)
    2. **API endpoints** — HTTP method + path, grouped by resource area
    3. **Auth mechanism** — Authentication type and named authorization policies
    4. **Events published / consumed** — Event names, topics, broker
    5. **Database** — Type (SQL Server / PostgreSQL / MongoDB / etc.), one-line purpose, whether migrations are involved (yes/no)
    6. **External service calls** — Service name + base URL + what endpoints are used

    Format as a structured summary with clear headings. Do NOT return raw file listings or grep output — summarize findings into boundary and contract observations.
```

The main agent receives only the structured summary from each sub-agent — raw Glob/Grep output stays inside the sub-agent context.

> **IMPORTANT — Scope of this scan:**
> This scan is for **structural awareness** only — where things are, what exists, how the repo is organized. This is NOT implementation-pattern analysis (DI wiring, handler patterns, data access approaches) — that is Design's job in `/aidlc-design`.

**For green-field services** — ask about reference patterns:

1. **Ask for reference context**: "This service is green-field. Is there a reference project, organizational template, or starter pattern that should inform this component's structure? Examples: an existing service to use as a model, a team template repo, or architectural standards for new services."

2. **If reference provided** — spawn an Explore sub-agent for the reference project (same pattern as brown-field above). Include in the sub-agent prompt: "This is a reference project being scanned as a model for a new green-field service. Focus on patterns that would transfer to a new project: project layout, bootstrapping approach, and conventions."

3. **If no reference** — note that the service is unconstrained by existing patterns. The sub-agent will propose freely, informed only by the technical guidance hierarchy (global/stack/profile standards).

**Validate against service inventory** (after sub-agents return):

Review each sub-agent's findings against the Feature's service inventory. When findings contradict the inventory, surface them immediately as questions:

- **Green-field service has existing code** — "The inventory lists Camera Detection as green-field, but I found existing detection logic in `Dismissal.API/Controllers/DetectionController.cs`. Should this be brown-field instead?"
- **Work spans services unexpectedly** — "This cluster's tasks naturally span both the Dismissal Stack and Notification Service. Should we split the cluster or treat it as cross-service?"
- **New service needed** — "The decomposition suggests an Event Bus component not in the inventory. Should we add it?"

If the user accepts a finding that changes the inventory (e.g., green-field → brown-field, new service added) → **update the Feature's service inventory table** in Confluence immediately. If the decision doesn't change the inventory → **note the decision in the Epics Overview page** under a "Decomposition Notes" section.

**Persist structural scans to Confluence:**

After sub-agents return, persist each repo's structural findings (from the sub-agent summaries) as a child page under the Epics Overview page:
- Page title: `Service Context: <Service Name>`
- Content: boundary summary (directory layout, API endpoints, auth, events, databases, external service calls)
- These pages serve as documentation/traceability — reviewers can see what context the AI was working with
- These pages are NOT a substitute for Design's own implementation-pattern analysis in `/aidlc-design`

**Slice context per cluster:**

After all sub-agents return, produce a per-cluster context summary by extracting the relevant portions of each repo's summary:
```
Cluster Context:
- Cluster: [name] [brown-field|green-field]
- Relevant services: [list from inventory]
- Structure: [relevant folder layout from scan]
- API endpoints: [relevant endpoints by resource area]
- Auth: [mechanism and policies relevant to this cluster]
- Events: [published/consumed events relevant to this cluster]
- Database: [type, purpose, migrations]
- External calls: [service dependencies relevant to this cluster]
```

**Present to user for confirmation** — Ask: "This is the project context I'll provide to each elaboration sub-agent. Is this accurate? Anything to add or correct?"

#### Step 4: Spawn Theme Analysis Subagents

For each theme cluster, spawn a `general-purpose` subagent using the Task tool. **Spawn all subagents in a single message** (parallel execution).

Pass to each subagent:
- Cluster name and brief description
- Per-cluster context summary from Step 3b (including brown-field/green-field tag)
- Condensed Feature context (problem statement, outcomes, scope)
- Other cluster names (for cross-cluster dependency awareness)

Each subagent should return structured JSON with:

```json
{
  "epic_proposal": {
    "name": "...",
    "description": "...",
    "deliverable": "...",
    "scope_in": ["..."],
    "scope_out": ["..."]
  },
  "work_items": [
    { "title": "...", "size_estimate": 3, "sprint_hint": "Sprint 1" }
  ],
  "sprint_estimate": { "count": 2, "total_size_range": "8-13 points" },
  "dependencies": [
    { "on": "<other cluster/epic>", "type": "blocking|non-blocking", "rationale": "..." }
  ],
  "risks": ["..."],
  "open_questions": ["..."]
}
```

> **work_items are indicative only** — they exist to inform Epic scoping, Sprint estimation, and team sizing. They are NOT Task Specifications and are NOT persisted as separate artifacts. Task Specifications are generated in `/aidlc-design` after the domain model and ADRs are complete.

#### Step 5: Consolidate Subagent Results

After all subagents return:
1. Parse the JSON results from each subagent
2. Merge cross-cutting concerns into a unified risk list
3. Build a dependency graph across all Epics using @${CLAUDE_PLUGIN_ROOT}/references/dependency-analysis.md
4. **Classify each dependency as blocking or non-blocking** (critical for parallelization)
5. **Validate environment field on all dependencies**:
   - Each dependency should have `environment: "dev" | "deploy" | "both"`
   - Flag any infrastructure dependency marked as `"dev"` or `"both"` — challenge whether local alternative exists
   - Default: Cloud infrastructure should be `"deploy"` only
6. Surface any conflicts or gaps between themes

#### Step 6: Confirm Epic Boundaries

Present the proposed Epics to the user for confirmation:
- Epic name, description, and deliverable
- Indicative work items (for context and sizing)
- Inter-epic dependencies

Adjust based on feedback — may merge or split themes. Apply loose coupling, high cohesion principles. Each Epic should deliver independent value.

#### Step 7: Propose Initial Sprint Groupings

For each Epic, propose how Tasks should be grouped into Sprints:

**Grouping Criteria** (from AI-DLC methodology):
- Tasks that can be implemented in a single rapid iteration (hours to days)
- Tasks forming a cohesive, well-defined scope of work
- Tasks aligned with Epic objectives
- Consider: A Epic may have multiple Sprints running in parallel or sequentially
- Each Sprint should be sized between 2 hours and 3 days

Classify each sprint's **type** based on its indicative tasks:
- Tasks touching controllers, services, repositories, or APIs → `backend`
- Tasks touching components, views, templates, or client-side logic → `frontend`
- Tasks spanning both server-side and client-side concerns → `fullstack` (prefer this when in doubt)

This is an indicative classification — `/aidlc-design` re-classifies from the final Task Specs before generating test scopes.

**Include in Epics Overview page:**

| Sprint | Type | Phase | Lane | Tasks | Dependencies | Est. Duration |
|------|------|-------|------|-------|--------------|---------------|
| Sprint 1 | backend | 0 | A | 1, 2, 3 | — | X hours/days |
| Sprint 2 | fullstack | 1 | A | 4, 5 | Sprint 1 | X hours/days |

**Initial Sprint Execution Plan:**
- Propose initial phase assignments (Phase 0 for foundation/setup, then sequential phases for dependent work)
- Identify sprint-to-sprint dependencies and assign lanes for parallelism within each phase
- Include the initial Sprint Execution Plan in Epics Overview using the Phase/Lane template from @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md

Note: These are initial proposals — phases, lanes, and critical path are refined during `/aidlc-verify`.

See Sprint Planning Guidance in @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md

#### Step 7b: Suggest Team Size

After proposing sprint groupings and the initial execution plan, generate a team size recommendation using the **Team Size Recommendation Rubric** from @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md.

**Steps:**

1. **Count peak lanes**: Find the maximum number of parallel lanes across all phases
2. **Calculate weighted average lanes**: Σ(lanes × phase_duration) / Σ(phase_duration)
3. **Assess coupling level**: Evaluate the dependency graph against the coupling criteria (Low / Medium / High)
4. **Identify specialist requirements**: Count distinct skill sets needed concurrently from sprint content (e.g., backend, frontend, infrastructure)
5. **Apply the formula**:
   - Start with weighted average lanes
   - Apply coupling discount (Low: ×1.0, Medium: ×0.85, High: ×0.70)
   - Cap Phase 0 at 2 lanes and recalculate
   - Round up, then apply bounds (floor = specialist count, ceiling = peak lanes)
6. **Build the recommendation**: Fill in the Team Size Recommendation template (metrics table, rationale, scaling options, phase staffing guide)
7. **Present to user**: Show the recommendation with scaling options and ask if they want to adjust before creating pages

**Include the completed Team Size Recommendation section in the Epics Overview page** (Step 8) using the template from @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md.

#### Step 8: Create Documentation Artifacts (Backend-Specific)

Branch based on detected backend to create appropriate documentation artifacts.

---

**GitLab Backend:**

1. **Checkout Feature branch** and pull latest:
   ```bash
   cd "$AIDLC_DOCS_PATH"
   git checkout "<branch-from-step-1>"
   git pull origin "<branch-from-step-1>"
   ```

2. **Spawn gitlab-creator subagent** (Epic mode):
   - Use `subagent_type: "gitlab-creator"` (aidlc plugin agent)
   - Pass: Feature directory path, git branch, Epic definitions (including indicative work items and sprint proposals), mode: `"epic"`
   - Agent will create:
     - `sprint-plan.md` with initial Sprint grouping proposals
     - `epics/epic-NN-<slug>/epic.md` for each Epic (problem statement, target users, scope, success metrics, ACs, indicative tasks with t-shirt sizes + sprint hints, dependencies, open questions)
     - All files include YAML frontmatter with `backend: gitlab`
   - **Does NOT create** `tasks/task-*.md` files — these are created by `/aidlc-design`
   - Agent commits and pushes changes
   - Returns file paths and commit SHA

3. **Verify git operations**:
   ```bash
   git log --oneline -1
   ls -la epics/
   ```

---

**Linear Backend:**

1. **Verify Initiative and Team**:
   - Use `get_initiative(query: "<initiative ID>", includeProjects: true)` to confirm Initiative exists
   - Confirm Team ID from Step 1

2. **Spawn linear-creator subagent** (Epic mode):
   - Use `subagent_type: "linear-creator"` (aidlc plugin agent)
   - Pass: Initiative ID, Team ID, Epic definitions (including indicative work items and sprint proposals), mode: `"epic"`
   - Agent will create:
     - Projects (Epics) via `save_project` with Initiative link
   - **Does NOT create** Issues (Tasks) — these are created by `/aidlc-design`
   - Returns Project IDs/URLs

3. **Verify Linear objects created**:
   - Confirm all Projects appear under the Initiative

---

**Confluence Backend:**

Create the page hierarchy under the Feature document using parallel sub-agents for efficiency.

**Phase A: Create Epics Overview (sequential)**

1. **Create Epics Overview page** (child of Feature)
   - Use the Epics Overview Template from @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md
   - Include: Feature name, Epic summary table, **Proposed Sprints section**, dependency graph
   - **This must complete first** to provide the parent page ID for Epics

**Phase B: Create Epic pages (parallel, one agent per Epic)**

2. **Spawn one sub-agent per Epic** using the Task tool:
   - Use `subagent_type: "confluence-creator"` (aidlc plugin agent)
   - Pass: Epics Overview page ID as the parent, Epic definition (including indicative work items and sprint proposals), mode: `"epic"`
   - **Spawn all sub-agents in a single message** (parallel execution)

   Each sub-agent creates:
   - The Epic page (child of Epics Overview) with problem statement, target users, scope, success metrics, ACs, indicative tasks with t-shirt sizes + sprint hints, dependencies, open questions
   - **Does NOT create** Task child pages — these are created by `/aidlc-design`
   - Returns Epic page ID and URL

3. **Consolidate sub-agent results**:
   - Collect all Epic page IDs
   - Verify all pages were created successfully
   - Report any failures and offer to retry

---

#### Step 9: Request Review

Summarise the full decomposition:
- Epics and Tasks (with links to documentation)
- Proposed Sprint groupings per Epic
- Dependencies and risks

**Ask explicitly (backend-specific)**:
- **GitLab**: "The Epics are now committed to the `<branch>` branch. The MR is ready for team review. Please add comments in the MR, then return for comment resolution."
- **Linear**: "The Projects (Epics) are now created. The team can review and add comments in Linear, then return for comment resolution."
- **Confluence**: "The Epics are now in Confluence for team review. Please add inline and footer comments, then return for comment resolution."

---

### ⛔ STOP — Review Gate

**Phase 1 is complete.** The team will now review the decomposition.

**This is a human activity that happens outside of Claude.**

Team members should review and provide feedback:

**GitLab:**
- Review the MR diff showing new `epics/*.md` and `sprint-plan.md` files
- Add MR comments on specific lines or overall feedback
- Discuss and reply to comments in the MR thread

**Linear:**
- Review Projects (Epics) under the Initiative
- Add comments on Projects
- Use Linear's comment threads for discussion

**Confluence:**
- Review each Epic page
- Add inline comments on specific text that needs clarification or changes
- Add footer comments for general feedback
- Reply to existing comments to discuss
- Review the Proposed Sprints section and suggest adjustments

**Wait for the user to return and request comment resolution before continuing to Phase 2.**

---

### Phase 2: Team Review

*(Human activity - no Claude involvement)*

The team reviews the decomposition using the appropriate platform:

**GitLab:**
- Review the MR diff showing `epics/*.md` and `sprint-plan.md` files
- Add MR comments on specific lines or general feedback
- Reply to threads for discussion
- Review proposed Sprint groupings in `sprint-plan.md`

**Linear:**
- Review Projects (Epics) under the Initiative
- Add comments on Projects
- Use Linear's comment threads for discussion
- Review proposed Sprint groupings in Project descriptions

**Confluence:**
- Add **inline comments** on specific text selections
- Add **footer comments** for general page feedback
- Reply to comments for discussion
- Review proposed Sprint groupings

---

### Phase 3: Comment Resolution

**This phase is typically run in a NEW Claude session after the team has completed their review.**

Branch based on detected backend for comment fetching and resolution.

---

**GitLab Backend:**

#### Step 9: Fetch MR Comments

1. **Fetch MR discussions** for the Feature branch:
   ```bash
   glab mr view --comments
   ```
   Or use GitLab API to fetch MR notes and threads programmatically

2. **Organize comments by file**:
   - Group comments by `epics/*.md` and `sprint-plan.md` files
   - Include threaded replies
   - Identify unresolved vs. resolved discussions

3. Present a summary of all comments organized by file.

#### Step 10: Address Feedback

For each comment:
1. Analyze the feedback and any reply thread
2. Determine the appropriate action:
   - Update file content if feedback is valid
   - Clarify in MR reply if feedback is based on misunderstanding
   - Escalate if feedback requires decision beyond scope

#### Step 11: Update Files

Update markdown files to address feedback:
1. **Checkout Feature branch**:
   ```bash
   cd "$AIDLC_DOCS_PATH"
   git checkout "<branch>"
   git pull origin "<branch>"
   ```

2. **Edit files** using Edit or Write tool:
   - Update Epic markdown content
   - Update `sprint-plan.md` if Sprint groupings need adjustment
   - Ensure changes address specific feedback

3. **Commit and push changes**:
   ```bash
   git add .
   git commit -m "fix(elaborate): Address review feedback"
   git push
   ```

#### Step 12: Reply to Comments

Reply to each MR/PR comment explaining how it was addressed. Detect VCS provider (see @${CLAUDE_PLUGIN_ROOT}/references/vcs-detection.md):
- **GitLab VCS**: Use `glab mr note <MR_ID> --message "<reply>"` or GitLab API
- **GitHub VCS**: Use `gh pr comment <PR_NUMBER> --body "<reply>"`
- Reference commit SHAs where applicable
- Mark discussions as resolved in the MR/PR

---

**Linear Backend:**

#### Step 9: Fetch Linear Comments

1. **Fetch comments on Projects and Issues**:
   - Use `list_comments(issueId: "<issue ID>")` for each Issue (Task)
   - Projects may have comments in their description updates or activity
   - Include threaded replies

2. **Organize comments by Project/Issue**:
   - Group by Epic (Project)
   - List all Task (Issue) comments
   - Identify open vs. resolved comment threads

3. Present a summary of all comments organized by Project and Issue.

#### Step 10: Address Feedback

For each comment:
1. Analyze the feedback and any reply thread
2. Determine the appropriate action:
   - Update Issue/Project description if feedback is valid
   - Clarify in comment reply if feedback is based on misunderstanding
   - Escalate if feedback requires decision beyond scope

#### Step 11: Update Linear Objects

Update Projects and Issues to address feedback:
- Use `save_project(id: "<project ID>", description: "...")` to update Project descriptions
- Use `save_issue(id: "<issue ID>", description: "...")` to update Issue descriptions
- Update Sprint labels if groupings need adjustment

#### Step 12: Reply to Comments

Reply to each comment explaining how it was addressed:
- Use `create_comment(issueId: "<issue ID>", body: "...", parentId: "<comment ID>")` for threaded replies
- Reference updated fields or properties
- Linear comments are marked resolved by the reply thread

---

**Confluence Backend:**

#### Step 9: Fetch All Comments

For each page (Epics Overview, Epic pages):
1. Fetch inline comments using `getConfluencePageInlineComments`
2. Fetch footer comments using `getConfluencePageFooterComments`
3. **Include replies** - comments have threaded replies that must be read

Present a summary of all comments organized by page.

#### Step 12: Address Feedback

For each comment:
1. Analyze the feedback and any reply thread
2. Classify the feedback type and determine the appropriate action:
   - **Correction**: Factual error or missing detail — update Task content
   - **Clarification**: Feedback based on a misunderstanding — reply with explanation, update if wording is unclear
   - **Alternative approach**: Reviewer proposes a different way to solve the problem — evaluate on merit (see below)
   - **Escalation**: Decision beyond scope — flag for team discussion

**Handling alternative approach comments:**

When a reviewer proposes an alternative approach (not just a correction or clarification), do NOT default to accommodation ("great point, I'll update it"). Instead:

1. **Evaluate both approaches on merit** — produce a structured comparison:

   > **Alternative Approach Evaluation**
   >
   > | Factor | Current Approach | Proposed Alternative |
   > |--------|-----------------|---------------------|
   > | Alignment with codebase patterns | ... | ... |
   > | Complexity / effort | ... | ... |
   > | Risk profile | ... | ... |
   > | Trade-offs | ... | ... |
   >
   > **Recommendation:** [Current / Alternative / Hybrid] — [brief rationale]

2. **Present the comparison** in the comment reply and let the team decide
3. **Do not update content** until a decision is made on the alternative
4. If the team selects the alternative, update content and reply confirming the change

#### Step 13: Update Content

Update the Confluence pages to address feedback:
- Use `updateConfluencePage` to modify Task content
- Update Proposed Sprints section if groupings need adjustment
- Ensure changes address the specific feedback

#### Step 14: Reply to Comments

Reply to each comment explaining how it was addressed:
- Use `createConfluenceInlineComment` (with `parentCommentId`) for inline comment replies
- Use `createConfluenceFooterComment` (with `parentCommentId`) for footer comment replies

#### Step 15: Mark Comments Resolved

After addressing feedback, comments should be marked as resolved.
Note: Confluence inline comments have a resolution status; footer comments are resolved by the reply thread.

---

---

### ⛔ STOP — Reorganization Gate

**Phase 3 is complete.** Before proceeding to design, the team may need to reorganize Tasks into different Epics.

**Ask**: "Are you ready to proceed with the current Epic groupings, or do you need to reorganize Tasks first?"

---

### Phase 4: Epic Re-assessment and Reorganization

This phase applies domain knowledge and architectural principles to validate and refine Epic boundaries and Sprint groupings before proceeding to design.

#### Step 16: Apply Epic Re-assessment Criteria

Evaluate each Epic against these AI-DLC principles:

| Criterion | Question | Action if Failed |
|-----------|----------|------------------|
| **Domain Alignment** | Does each Epic map to a coherent subdomain? | Split or merge Epics to align with domain boundaries |
| **Loose Coupling** | Are cross-Epic dependencies minimized? | Regroup Tasks to reduce dependencies |
| **High Cohesion** | Are related Tasks grouped together? | Move Tasks between Epics |
| **Independent Value** | Can each Epic deliver value independently? | Ensure each Epic has a clear deliverable |
| **Parallel Execution** | Can Epics be built in parallel by different teams? | Resolve blocking dependencies |

Present the re-assessment findings to the user:
- Which Epics pass all criteria
- Which Epics need adjustment and why
- Proposed regrouping (if any)

Branch based on backend for reorganization operations.

---

**GitLab Backend:**

#### Step 15: Regroup into Epics

If regrouping is needed based on re-assessment:

1. **Move Epic files** if Epics are being merged, split, or renamed:
   ```bash
   cd "$AIDLC_DOCS_PATH"
   git checkout "<branch>"
   git pull origin "<branch>"

   # Rename or move epic directories
   git mv epics/epic-01-old-name epics/epic-01-new-name
   ```

   > **Old-flow projects (pre-3.9):** If task files already exist from the elaborate phase, move them to reflect the new Epic structure at the same time. Task files are in `epics/<epic-name>/tasks/`.

2. **Rename Epic files** where possible:
   - Edit `epics/epic-NN-<slug>.md` to repurpose existing Epics
   - Avoid creating duplicate Epic files unnecessarily

3. **Create new Epic files** only when necessary:
   - Use Epic Template from @${CLAUDE_PLUGIN_ROOT}/references/backends/gitlab.md
   - Follow `epic-NN-<slug>.md` naming convention

4. **Archive Epic files** that are no longer needed:
   - Move to `epics/archived/` directory or delete
   - Update references in `sprint-plan.md`

5. **Document rationale** in `sprint-plan.md`

#### Step 16: Refine Sprint Groupings

Review and refine the Proposed Sprints in `sprint-plan.md`:
1. Verify each Sprint forms a cohesive scope (2 hours to 3 days of work)
2. Check Tasks are grouped logically (related functionality)
3. Ensure no circular dependencies between Sprints
4. Verify sprint-to-sprint dependencies are explicitly identified
5. Verify phase and lane assignments reflect actual dependency chains
6. Adjust groupings based on re-assessment findings

If adjustments needed:
- Update Sprint assignments in the Epics Overview table
- Update Task-to-Sprint mapping in file frontmatter
- Update Sprint Execution Plan (Phase/Lane table format)

#### Step 17: Update Sprint Plan

Update `sprint-plan.md` to reflect new groupings:
- Update Epic summary table
- Update Proposed Sprints section with refined groupings
- Update dependency graph
- Update Task counts
- Add "Epic Boundary Rationale" section

#### Step 18: Commit and Push Changes

```bash
git add .
git commit -m "refactor(elaborate): Reorganize Epics based on domain analysis"
git push
```

#### Step 19: Update Feature Status

Update `intent.md` frontmatter to mark elaboration complete:
```yaml
elaboration_status: complete
elaboration_date: YYYY-MM-DD
```

Commit and push the change.

---

**Linear Backend:**

#### Step 15: Regroup into Projects

If regrouping is needed based on re-assessment:

1. **Move Issues** between Projects:
   - Use `save_issue(id: "<issue ID>", project: "<new project ID>")` to reassign Issues to different Projects

2. **Rename Projects** where possible:
   - Use `save_project(id: "<project ID>", name: "Epic NN: New Title")` to repurpose existing Projects
   - Avoid creating duplicate Projects unnecessarily

3. **Create new Projects** only when necessary:
   - Use `save_project(name: "Epic NN: Title", team: "<team ID>", initiatives: ["<initiative ID>"])`

4. **Archive Projects** that are no longer needed:
   - Projects can be archived in Linear if no longer relevant

5. **Document rationale** in Initiative description or status update

#### Step 16: Refine Sprint Groupings

Review and refine Sprint Labels:
1. Verify each Sprint forms a cohesive scope (2 hours to 3 days of work)
2. Check Tasks (Issues) are grouped logically (related functionality)
3. Ensure no circular dependencies between Sprints
4. Verify sprint-to-sprint dependencies are explicitly identified
5. Verify phase and lane assignments reflect actual dependency chains
6. Adjust groupings based on re-assessment findings

If adjustments needed:
- Update Issue labels via `save_issue(id: "<issue ID>", labels: ["Sprint N"])`
- Create new Sprint labels if needed via `create_issue_label`
- Update Project Milestones if using them for Sprint tracking

#### Step 17: Update Initiative Summary

Update the Initiative description to reflect new groupings:
- List Projects (Epics) with their purposes
- Document Sprint groupings per Project
- Include dependency graph
- Add "Epic Boundary Rationale" section

Use `save_initiative(id: "<initiative ID>", description: "...")`.

#### Step 18: Add Status Update

Create a status update for the Initiative:
```
save_status_update(
  type: "initiative",
  initiative: "<initiative ID>",
  health: "onTrack",
  body: "Epic reorganization complete. Projects refined based on domain analysis."
)
```

#### Step 19: Mark Elaboration Complete

Update Initiative status to indicate elaboration is complete:
- Optionally add custom status via `save_initiative(id: "<initiative ID>", status: "Active")`
- Add labels like "elaboration-complete" if desired

---

**Confluence Backend:**

#### Step 15: Regroup into Epics

If regrouping is needed based on re-assessment:
1. **Move Task pages** between Epic pages (update parent page ID)
2. **Rename/repurpose Epic pages** where possible (avoid creating new pages unnecessarily)
3. **Create new Epic pages** only when necessary
4. **Archive Epic pages** that are no longer needed
5. **Document the rationale** for Epic boundaries in the Epics Overview

#### Step 18: Refine Sprint Groupings

Review and refine the Proposed Sprints on the Epics Overview:
1. Verify each Sprint forms a cohesive scope (2 hours to 3 days of work)
2. Check Tasks are grouped logically (related functionality)
3. Ensure no circular dependencies between Sprints
4. Verify sprint-to-sprint dependencies are explicitly identified
5. Verify phase and lane assignments reflect actual dependency chains
6. Adjust groupings based on re-assessment findings

If adjustments needed:
- Move Tasks between Sprints
- Split large Sprints (>3 days of work)
- Merge small Sprints (<2 hours of work)
- Reassign phases/lanes if dependency structure changed
- Update Epics Overview with refined Sprint Execution Plan (Phase/Lane table format)

#### Step 18b: Update Epics Overview

Update the Epics Overview page to reflect the new groupings:
- Update the Epic summary table
- Update the Proposed Sprints section with refined groupings
- Update the dependency graph
- Update Task counts
- Add "Epic Boundary Rationale" section documenting why Epics are grouped this way

#### Step 19: Update Workflow Status

Update the Confluence Feature page status table:
- Set "Epic Decomposition" row to "✅ Complete" with today's date
- Add note that Epics are ready for design phase

---

#### Step 19: Chain to Design (All Backends)

Report back with:
- **GitLab**: Summary of Epics (with file paths), MR URL for review
- **Linear**: Summary of Projects/Epics (with Linear URLs), Initiative URL
- **Confluence**: Summary of Epics (with Confluence page links)
- Refined Sprint groupings per Epic
- Boundary rationale for each Epic
- Any cross-cutting concerns or dependencies

Ask whether to proceed with Domain Design for any Epic.
If yes, invoke `/aidlc-design` with the Epic context.

> **Note on Jira Transfer:**
> - **GitLab/Confluence**: Jira transfer happens later in `/aidlc-verify` after design and verification are complete. Final Sprint groupings are confirmed during verify before creating Jira artifacts.
> - **Linear**: No Jira transfer - Linear IS the work tracker (Projects and Issues already created in this skill).

## Workflow Chain

- **Previous**: `/aidlc-intent` (Feature documentation)
- **Next**: `/aidlc-design` (Domain and Logical Design)

## Definition of Done

### Phase 1 (Documentation Artifacts Created)

**Common criteria (all backends):**
- Theme clusters identified and confirmed with user
- Subagents spawned in parallel for Task elaboration
- All subagent results consolidated
- Proposed Sprint groupings documented
- User notified to begin team review

**GitLab-specific:**
- `sprint-plan.md` created with initial Sprint grouping proposals
- `epics/epic-NN-<slug>/epic.md` files created for each Epic (with YAML frontmatter `backend: gitlab`)
- Epic files include problem statement, target users, scope, success metrics, ACs, indicative tasks with t-shirt sizes + sprint hints, dependencies, open questions
- No task files created — these are created by `/aidlc-design`
- Files committed to Feature branch and pushed to remote
- MR ready for team review

**Linear-specific:**
- Projects (Epics) created via `save_project` and linked to Initiative
- Project descriptions include problem statement, target users, scope, success metrics, ACs, indicative tasks with t-shirt sizes + sprint hints, dependencies, open questions
- No Issues (Tasks) created — these are created by `/aidlc-design`
- Team notified to review Projects in Linear

**Confluence-specific:**
- Epics Overview page created as child of Feature
- Epic pages created as children of Epics Overview
- Epic pages include problem statement, target users, scope, success metrics, ACs, indicative tasks with t-shirt sizes + sprint hints, dependencies, open questions
- No Task pages created — these are created by `/aidlc-design`
- Proposed Sprint groupings documented on Epics Overview
- Team notified to begin Confluence review

### Phase 2 (Team Review)

**GitLab:**
- Team has reviewed MR diff showing `epics/*.md` and `sprint-plan.md` files
- MR comments added on specific lines or general feedback
- Comment threads include replies/discussion
- Proposed Sprint groupings reviewed in `sprint-plan.md`

**Linear:**
- Team has reviewed Projects (Epics) in Linear
- Comments added on Projects
- Comment threads include replies/discussion
- Proposed Sprint groupings reviewed in Project descriptions

**Confluence:**
- Team has reviewed all Epic pages in Confluence
- Inline and footer comments added
- Comment threads include replies/discussion
- Proposed Sprint groupings reviewed on Epics Overview

### Phase 3 (Comment Resolution)

**GitLab:**
- All MR comments fetched (discussions + replies)
- Markdown files updated to address feedback
- Changes committed and pushed to Feature branch
- Replies posted on MR explaining how feedback was addressed
- MR discussions marked as resolved

**Linear:**
- All Project/Issue comments fetched (comments + replies)
- Project/Issue descriptions updated to address feedback via `save_project`/`save_issue`
- Comment replies posted explaining how feedback was addressed
- Comment threads resolved

**Confluence:**
- All comments fetched (inline + footer + replies)
- Task content updated to address feedback
- Replies posted explaining how feedback was addressed
- Comments marked as resolved

### Phase 4 (Epic Re-assessment and Reorganization)

**Common criteria (all backends):**
- All Epics evaluated against re-assessment criteria (domain alignment, loose coupling, high cohesion, independent value, parallel execution)
- Tasks regrouped based on domain knowledge and architectural principles
- Sprint groupings refined based on re-assessment
- Boundary rationale documented
- User informed that next step is `/aidlc-design`

**GitLab-specific:**
- Epic files/directories reorganised as needed (via `git mv`); old-flow task files moved alongside if present
- Epic files renamed/repurposed (not duplicated)
- `sprint-plan.md` updated with new groupings, Sprint proposals, and boundary rationale
- `intent.md` frontmatter updated with `elaboration_status: complete`
- Changes committed and pushed to Feature branch

**Linear-specific:**
- Issues moved between Projects as needed via `save_issue`
- Projects renamed/repurposed (not duplicated)
- Initiative description updated with new groupings, Sprint proposals, and boundary rationale
- Status update created for Initiative documenting completion

**Confluence-specific:**
- Epic pages reorganised as needed (parent page updated); old-flow Task pages moved alongside if present
- Epic pages renamed/repurposed (not duplicated)
- Epics Overview updated with new groupings, Sprint proposals, and boundary rationale
- Workflow status table updated in Feature page: "Epic Decomposition: ✅ Complete"

> **Note on Jira Transfer:**
> - **GitLab/Confluence**: Jira transfer (Project → Feature → Epic → Story → Task; Sprints group Stories/Tasks for scheduling) happens later in `/aidlc-verify` after design and verification are complete.
> - **Linear**: No Jira transfer - Linear IS the work tracker (Projects and Issues already created in this skill).

## Troubleshooting

- **Too many Tasks**: Consider splitting into multiple Epics or deferring lower-priority Tasks.
- **User wants to skip Confluence phase**: Allow override but recommend Confluence for team collaboration.
- **Subagent failure**: Report which theme cluster failed and offer to retry or elaborate manually.
- **Single theme identified**: Still spawn one subagent for consistency; workflow proceeds normally.
- **Comment resolution in same session**: If user wants to resolve comments immediately (no new session), proceed with Phase 3 in the current session.
- **Moving pages between Epics**: Use `updateConfluencePage` with a new `parentId` to move Task pages.
- **Sprint grouping disagreement**: Present alternative groupings and let user decide; document rationale for chosen approach.
