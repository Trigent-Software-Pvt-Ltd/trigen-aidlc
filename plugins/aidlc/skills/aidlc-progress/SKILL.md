---
name: aidlc-progress
description: Generate confidence, risk, and progress assessment for a Project/Feature. Two modes - Full Assessment (documentation quality, team readiness, execution evidence, code health) and Execution Assessment (epic/sprint focused with complexity and coverage analysis). Supports GitLab, Linear, or Confluence backends. Works at any phase from Feature through implementation. (Triggers - check progress, project status, how are we doing, project health, aidlc progress, execution check, sprint progress)
---

# AI-DLC Progress

Generate a progress report for a Project/Feature, showing confidence, risk, and progress metrics with actionable recommendations. Supports multiple documentation backends: **GitLab** (markdown files), **Linear** (Initiatives/Projects/Issues), or **Confluence** (pages). Can be run at any phase of the AI-DLC workflow.

## Assessment Modes

This skill offers two assessment modes:

1. **Full Assessment** — End-to-end check covering documentation quality, work tracking health, and code health. Best for understanding overall project readiness.
2. **Execution Assessment** — Focused on epics and sprints only. Analyses completed work (complexity vs. coverage) and pending work (estimation confidence, unknowns). Best for tracking delivery confidence and risk during implementation.

## AI-Drives-Conversation Pattern

This skill follows the AI-DLC principle where AI initiates and directs the conversation:

1. **AI gathers** — Collect Project/Feature reference (GitLab branch, Linear Initiative URL, Confluence URL, or Jira key)
2. **AI selects mode** — Prompt user to choose Full or Execution assessment
3. **AI detects backend and phase** — Determine backend from artifacts, then current workflow phase
4. **AI spawns assessors** — Parallel sub-agents assess dimensions appropriate to the chosen mode
5. **AI consolidates** — Merge results into headline metrics and detailed breakdown
6. **AI reports** — Present visual dashboard with recommendations and machine-readable JSON

## Example Invocations

- "Check the progress of the authentication project"
- "How are we doing on PROJ-123?"
- "Show me the project health dashboard"
- "What's the risk level for this project?"
- "How is execution going on the auth project?"
- "/aidlc-progress intent/my-project/auth-overhaul" (GitLab branch)
- "/aidlc-progress https://linear.app/team/initiative/abc123" (Linear)
- "/aidlc-progress https://confluence.example.com/wiki/spaces/PROJ/pages/12345" (Confluence)
- "/aidlc-progress PROJ-123" (Jira key)

## Completion Checklist

> **IMPORTANT**: Create tasks for each step at the start using `TodoWrite`. Mark tasks complete as you go using `TodoWrite`. Each task description should reference the corresponding Workflow step.

| # | Task | Depends On | Workflow Reference | Exit Criteria |
|---|------|------------|-------------------|---------------|
| 1 | Gather Project/Feature reference | — | Phase 1 | GitLab branch, Linear URL, Confluence URL, or Jira key collected |
| 2 | Select assessment mode | 1 | Phase 1.5 | User has chosen Full or Execution mode |
| 3 | Detect backend and current workflow phase | 2 | Phase 2 | Backend + phase detected and reported to user |
| 4 | Spawn assessment sub-agents | 3 | Phase 3 | Assessors launched (parallel), appropriate to chosen mode |
| 5 | Consolidate results | 4 | Phase 4 | Confidence/Risk/Progress metrics calculated |
| 6 | Present dashboard with JSON output | 5 | Phase 5 + 6 | Report displayed with recommendations, and machine-readable JSON block appended |

## Task Tracking

When this skill is invoked:
1. **Create tasks** for all 6 phases using `TodoWrite`
2. **Mark task as in_progress** when starting each phase
3. **Mark task complete** when phase exit criteria met
4. **Verify all tasks complete** before finishing

This ensures visibility into progress and prevents incomplete execution.

## Backend Detection

This skill detects the backend automatically from existing artifacts (it does NOT prompt for backend selection). Use @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md for detection logic.

## References

- @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md - Jira/Confluence tool guidance and templates
- @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md - Backend detection logic
- @${CLAUDE_PLUGIN_ROOT}/references/review-criteria.md - Shared quality checklists and scoring foundations
- @${CLAUDE_PLUGIN_ROOT}/references/sprint-conventions.md - Sprint naming, sizing, and sequencing conventions
- @${CLAUDE_PLUGIN_ROOT}/references/dependency-analysis.md - Dependency mapping and risk assessment
- @${CLAUDE_PLUGIN_ROOT}/references/backends/gitlab.md - GitLab operations (if GitLab backend)
- @${CLAUDE_PLUGIN_ROOT}/references/backends/linear.md - Linear operations (if Linear backend)
- @${CLAUDE_PLUGIN_ROOT}/references/backends/confluence.md - Confluence operations (if Confluence backend)
- @${CLAUDE_PLUGIN_ROOT}/references/vcs-detection.md - VCS provider detection and PR/MR commands

## Tool Preference

- **CLI-first**: Prefer `acli` (Atlassian CLI), `glab` (GitLab CLI), and `gh` (GitHub CLI) as they use fewer tokens.
- **MCP fallback**: Use Atlassian, GitLab, and Linear MCP servers when CLI is unavailable or insufficient.

---

## Workflow

### Phase 1: Gather Project/Feature Reference

Ask for the Project/Feature identifier:

```
Please provide the Project or Feature to assess:

- GitLab: Feature branch name (e.g., "intent/my-project/auth-overhaul"), OR
- Linear: Initiative URL or ID, OR
- Confluence: Feature page URL, OR
- Jira: Project key (e.g., PROJ-123) or Feature key (e.g., PROJ-456)

I'll detect the backend, fetch all related artifacts, and generate a progress report.
```

### Phase 1.5: Select Assessment Mode

After gathering the reference, prompt the user using `AskUserQuestion`:

```
Which assessment would you like?

1. **Full Assessment** — End-to-end check covering documentation quality, work tracking, and code health. Best for understanding overall project readiness across all dimensions.

2. **Execution Assessment** — Focused on epics and sprints. Analyses completed work (complexity vs. coverage) and pending work (estimation confidence, unknowns). Best for tracking delivery risk during implementation.
```

Store the chosen mode. This determines which sub-agents spawn in Phase 3 and which scoring model applies in Phase 4.

### Phase 2: Detect Backend and Current Workflow Phase

First detect the backend using @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md, then determine the current phase based on artifacts present:

| Phase | Artifacts Present | Metrics Available |
|-------|------------------|-------------------|
| **Planning** | Feature doc only | Documentation quality, Ambiguity |
| **Elaboration** | Feature + Epics/Tasks | Above + Task completeness |
| **Design** | Above + Design docs/ADRs | Above + Technical readiness |
| **Verification** | Above + Work tracking items (Jira/Linear) | Above + Team readiness, Progress |
| **Implementation** | Above + Code/PRs/MRs | All metrics including Code health |

**Detection logic by backend:**

**GitLab:**
1. Read `intent.md` frontmatter for workflow status
2. Check for `epics/` directory with epic `.md` files
3. Check for `design/` and `adrs/` directories
4. Check frontmatter for `jira_project_key` (verification done)
5. Check for linked MRs: detect VCS provider (see @${CLAUDE_PLUGIN_ROOT}/references/vcs-detection.md)
   - GitLab VCS: `glab mr list --source-branch "<intent-branch>"`
   - GitHub VCS: `gh pr list --head "<intent-branch>"`

**Linear:**
1. Fetch Initiative details via `get_initiative`
2. Check for Projects (Epics) under the Initiative
3. Check for Issues (Tasks) under Projects
4. Check for "Design Doc" labeled Issues
5. Check Initiative status ("Planned" vs "Active")

**Confluence:**
1. Check for Jira Project (with `aidlc:project` label)
2. Fetch Feature document (Confluence)
3. Check for Epics Overview and Epic child pages
4. Check for Design documents (Domain model, ADRs)
5. Check Workflow Status table in Feature
6. Search for linked Jira Feature, Epics, Sprints
7. If Jira exists, check for linked PRs/MRs

Report the detected backend and phase to the user:
```
Backend: [GitLab/Linear/Confluence]
Detected phase: [Implementation]
Artifacts found: Feature, 3 Epics, 8 Tasks, Design docs, 5 linked MRs
Assessment mode: [Full/Execution]
```

---

### Phase 3: Spawn Assessment Sub-agents

Spawn parallel sub-agents based on the **chosen assessment mode** and the detected phase. Use the Task tool with `subagent_type: "general-purpose"`.

**Spawn all applicable sub-agents in a single message for parallel execution.**

---

## Full Assessment Mode — Sub-agents

### Sub-agent A: Documentation Assessor

**Always spawn in Full mode** — assesses documentation quality (GitLab `.md` files, Linear artifacts, or Confluence pages).

```markdown
You are assessing AI-DLC documentation quality for a progress report.

## Initiative Context

**Feature Document:**
<feature content>

**Epics (if present):**
<epic pages content>

**Tasks (if present):**
<task pages content>

**Design Documents (if present):**
<design doc content>

## Scoring Dimensions

Rate each dimension 0-100 using the calibration bands below.

### 1. Documentation Completeness

All required sections present for the current phase.

| Score Range | Criteria |
|-------------|----------|
| 90-100 | All required sections present, thorough coverage, no gaps |
| 70-89 | Most sections present, minor gaps that don't block understanding |
| 50-69 | Several sections missing or incomplete |
| 0-49 | Major sections missing, document is a skeleton |

**Required sections by document type:**

Feature: Summary, Problem/Opportunity, Target Users, Amigos, Feature Profile, Outcomes, Scope (in/out), Technical Considerations, NFRs, Measurement Criteria, Dependencies, Risks, Assumptions, Testing Strategy, Open Questions.

Epic: Description/scope, Tasks table, Sprint Plan table, Dependencies, Risks table.

Task: Summary, and either: Behaviour items (Task Spec format, AIDLC 3.9+) or User story + Acceptance criteria (legacy format). Context, Dependencies, Risks, Test Notes. Optional metric: % of tasks with `files` field populated (Task Spec format only).

Design: Domain model, Bounded context boundaries, Context map, ADRs, Integration points.

### 2. Content Quality

Clear, specific, actionable content throughout.

| Score Range | Criteria |
|-------------|----------|
| 90-100 | Clear, specific, actionable content throughout. No vague language. |
| 70-89 | Mostly clear with occasional vague statements |
| 50-69 | Multiple vague or untestable statements |
| 0-49 | Predominantly vague, unclear, or boilerplate content |

**Flag and deduct points for these vague language patterns:**
- Open-ended scope: "and more features", "etc.", "various improvements"
- Untestable criteria: "should be fast", "user-friendly", "secure"
- Missing specifics: "connects to backend" without naming APIs/services
- Boilerplate content: sections copied without customisation
- Undefined scope: "the system should handle X" without specifying which system
- Unclear referents: pronouns with unclear referents in technical context

### 3. NFR Measurability

Performance, security, and availability targets are specific and measurable.

| Score Range | Criteria |
|-------------|----------|
| 90-100 | All NFRs have specific, measurable targets with baselines |
| 70-89 | Most NFRs measurable, one or two vague |
| 50-69 | Mixed — some measurable, several vague |
| 0-49 | NFRs are predominantly unmeasurable ("fast", "secure", "reliable") |

**Measurability test — Bad vs. Good:**
- Performance: "should be fast" vs. "API response <200ms p95"
- Availability: "high availability" vs. "99.9% uptime, <5min recovery"
- Security: "must be secure" vs. "OWASP Top 10 mitigated, encrypted at rest with AES-256"
- Scalability: "should scale" vs. "Support 10k concurrent users with <10% latency increase"

### 4. Ambiguity Level

Lower ambiguity = higher score. Boundaries and terms are clear.

| Score Range | Criteria |
|-------------|----------|
| 90-100 | Unambiguous throughout, boundaries crystal clear |
| 70-89 | Minor ambiguities that can be resolved from context |
| 50-69 | Several statements open to interpretation |
| 0-49 | Pervasive ambiguity, multiple valid interpretations |

**Check for:** statements with multiple valid interpretations, undefined technical terms or acronyms, unclear boundaries, implicit unstated assumptions, pronouns with unclear referents.

## Return Format

Return as JSON:

{
  "phase_detected": "<planning|elaboration|design|verification|implementation>",
  "scores": {
    "documentation_completeness": <0-100>,
    "content_quality": <0-100>,
    "nfr_measurability": <0-100>,
    "ambiguity_level": <0-100>
  },
  "gaps": [
    {
      "severity": "<high|medium|low>",
      "area": "<section or document>",
      "issue": "<description>",
      "suggestion": "<remediation>"
    }
  ],
  "open_questions": [
    "<question from the documentation>"
  ],
  "strengths": [
    "<well-documented aspect>"
  ],
  "overall_confidence": <0-100>
}
```

---

### Sub-agent B: Work Tracking Assessor

**Spawn in Full mode if work tracking items exist** (Jira issues for GitLab/Confluence backends, or Linear Issues for Linear backend) — assesses team readiness and progress.

> **Note for Linear backend:** Fetch Issues via Linear MCP tools instead of Jira. Map Linear states (Backlog, Todo, In Progress, Done, Cancelled) to equivalent Jira statuses for scoring.

```markdown
You are assessing work tracking health for a Project progress report.

## Work Tracking Artifacts

> **Backend note:** For GitLab/Confluence backends, these are Jira issues.
> For Linear backend, these are Linear Issues. Map Linear states
> (Backlog, Todo, In Progress, Done, Cancelled) to equivalent statuses.

**Project:**
<project details if exists>

**Feature:**
<feature details>

**Epics:**
<epic details>

**Sprints:**
<sprint details with status, assignee, points>

**Tasks:**
<task details with status, assignee>

## Scoring Dimensions

Rate each dimension 0-100:

1. **Progress (Task Completion)** — Done items / Total items as percentage
2. **Progress (Story Points)** — Completed points / Total points as percentage
3. **Team Readiness** — Items assigned, no blockers, dependencies mapped
4. **Blocker Count** — Fewer blockers = higher score (100 = no blockers)

## Return Format

Return as JSON:

{
  "progress": {
    "task_completion": {
      "done": <count>,
      "total": <count>,
      "percentage": <0-100>
    },
    "story_points": {
      "completed": <points>,
      "total": <points>,
      "percentage": <0-100>
    }
  },
  "team_readiness": {
    "score": <0-100>,
    "unassigned_count": <count>,
    "blocker_count": <count>,
    "blocked_items": ["<issue keys or Linear IDs>"]
  },
  "status_breakdown": {
    "to_do": <count>,
    "in_progress": <count>,
    "done": <count>,
    "blocked": <count>
  },
  "epic_progress": [
    {
      "epic": "<epic name>",
      "tasks_done": <count>,
      "tasks_total": <count>,
      "points_done": <points>,
      "points_total": <points>,
      "status": "<not_started|in_progress|done>"
    }
  ],
  "risks": [
    {
      "severity": "<high|medium|low>",
      "issue": "<description>",
      "suggestion": "<remediation>"
    }
  ]
}
```

---

### Sub-agent C: Code Assessor

**Spawn in Full mode if PRs/MRs are linked** — assesses code health and risk.

For each linked MR/PR, fetch the diff and assess. Discovery by backend:
- **GitLab**: Detect VCS (see @${CLAUDE_PLUGIN_ROOT}/references/vcs-detection.md):
  - GitLab VCS: `glab mr list --source-branch "<branch>"` or check `intent.md` frontmatter for MR URLs
  - GitHub VCS: `gh pr list --head "<branch>"`
- **Linear**: Check Issue attachments/links for PR URLs; then detect VCS from repo remote to fetch diff
- **Confluence**: Check Jira issue links for PR/MR references; then detect VCS from repo remote

```markdown
You are assessing code health for a Project progress report.

## Linked MRs/PRs

<list of MRs with status, file changes>

## MR Diffs (summarised)

<key changes from each MR>

## Project Context

<CLAUDE.md, linter configs, test directory structure>

## Scoring Dimensions

Rate each dimension 0-100:

1. **Test Coverage Estimate** — Based on test files present, test-to-code ratio
2. **Code Complexity** — Large files, deep nesting, high method counts = lower score
3. **MR Health** — Merged vs open, CI status, review status

## Return Format

Return as JSON:

{
  "mr_summary": {
    "total": <count>,
    "merged": <count>,
    "open": <count>,
    "ci_passing": <count>,
    "ci_failing": <count>
  },
  "scores": {
    "test_coverage_estimate": <0-100>,
    "code_complexity": <0-100>,
    "mr_health": <0-100>
  },
  "risk_factors": [
    {
      "severity": "<high|medium|low>",
      "area": "<file or component>",
      "issue": "<description>",
      "suggestion": "<remediation>"
    }
  ],
  "strengths": [
    "<positive code health aspect>"
  ]
}
```

---

## Execution Assessment Mode — Sub-agents

### Sub-agent X: Completed Work Assessor

**Spawn in Execution mode if any sprints are Done or In Progress with linked MRs/PRs.**

Analyses complexity and coverage of completed work to determine whether delivered code is well-tested relative to its complexity.

For each completed/in-progress sprint with linked MRs:
1. Fetch MR diffs
2. Measure complexity and coverage signals
3. Flag files for source deep-dive if high-complexity indicators are found

**MR discovery by backend:**
- **GitLab**: `glab mr list` for the Feature branch, cross-reference with sprint Jira keys in MR descriptions
- **Linear**: Check Issue attachments/links for PR URLs
- **Confluence**: Check Jira sprint issue links for PR/MR references

```markdown
You are assessing completed work health for an Execution Assessment.

## Completed/In-Progress Sprints

<for each sprint: name, status, linked MRs, epic membership>

## MR Diffs

<diffs for each linked MR>

## Project Context

<CLAUDE.md, linter configs, test directory structure, language/framework>

## Assessment Instructions

For each sprint's linked MRs, assess two dimensions:

### Complexity Score (0-100, higher = more complex)

Measure these signals from the diffs:
- **Files changed**: count of files modified, added, or deleted
- **Services touched**: how many distinct services, projects, or bounded contexts are affected
- **Migration presence**: any database migrations, schema changes, or data transformations
- **API surface changes**: new or modified public endpoints, message contracts, or event schemas
- **Shared/core code changes**: modifications to shared libraries, base classes, middleware, or infrastructure code (higher risk than leaf code changes)
- **Nesting and method size**: if a file has 500+ lines changed or appears to introduce deep nesting, read the source file and assess method lengths and nesting depth

Scoring guide:
| Score | Interpretation |
|-------|---------------|
| 0-30 | Low complexity — small, isolated changes in leaf code |
| 31-60 | Moderate complexity — multiple files, some integration points |
| 61-80 | High complexity — cross-service, migrations, or shared code changes |
| 81-100 | Very high complexity — large-scale changes across multiple services with migrations and API changes |

### Coverage Score (0-100, higher = better covered)

Measure these signals from the diffs:
- **Test files present**: are there new or modified test files in the diff?
- **Test-to-code ratio**: lines of test code vs. lines of production code in the diff
- **CI status**: are CI pipelines passing for merged MRs?
- **Test type breadth**: evidence of unit tests, integration tests, or end-to-end tests
- **Coverage of complex areas**: do the most complex files (identified above) have corresponding test changes?

Scoring guide:
| Score | Interpretation |
|-------|---------------|
| 0-30 | Poor coverage — few or no tests, complex code untested |
| 31-60 | Partial coverage — some tests but gaps in complex areas |
| 61-80 | Good coverage — most changes tested, CI passing |
| 81-100 | Excellent coverage — thorough tests including edge cases, all CI green |

### Source Deep-dive Triggers

If any of these conditions are met, read the actual source file (not just the diff) and factor findings into the complexity score:
- File has 500+ lines changed
- File is in a shared/core/infrastructure directory
- File contains a database migration
- Diff shows deeply nested control flow (3+ levels)

## Return Format

Return as JSON:

{
  "sprints": [
    {
      "sprint": "<sprint name or key>",
      "epic": "<parent epic name>",
      "status": "<done|in_progress>",
      "mr_count": <count>,
      "complexity_score": <0-100>,
      "coverage_score": <0-100>,
      "complexity_signals": {
        "files_changed": <count>,
        "services_touched": <count>,
        "has_migrations": <boolean>,
        "api_surface_changes": <boolean>,
        "shared_code_changes": <boolean>,
        "source_deepdive_triggered": <boolean>
      },
      "unmitigated_complexity_score": <0-100>,
      "coverage_signals": {
        "test_files_present": <boolean>,
        "test_to_code_ratio": <float>,
        "ci_passing": <boolean>,
        "complex_areas_tested": <boolean>
      },
      "risk_factors": [
        {
          "severity": "<high|medium|low>",
          "area": "<file or component>",
          "issue": "<description>",
          "suggestion": "<remediation>"
        }
      ],
      "strengths": ["<positive aspect>"]
    }
  ],
  "epic_rollup": [
    {
      "epic": "<epic name>",
      "sprints_assessed": <count>,
      "avg_complexity": <0-100>,
      "avg_coverage": <0-100>,
      "complexity_weighted_coverage": <0-100>,
      "unmitigated_complexity_score": <0-100>,
      "risk_factors": ["<summary of key risks>"],
      "strengths": ["<summary of strengths>"]
    }
  ]
}

**Important calculations:**
- Per-sprint `unmitigated_complexity_score`: max(0, complexity_score - coverage_score). A sprint with complexity 80 and coverage 85 has unmitigated complexity of 0 (well-mitigated). A sprint with complexity 80 and coverage 30 has unmitigated complexity of 50 (high risk).
- Epic rollup `complexity_weighted_coverage`: weighted average of sprint coverage scores where each sprint's weight is its complexity_score / sum(all complexity_scores). This ensures high-complexity sprints have more influence on the epic's coverage assessment.
- Epic rollup `unmitigated_complexity_score`: average of per-sprint unmitigated_complexity_scores.
```

---

### Sub-agent Y: Pending Work Assessor

**Spawn in Execution mode if any sprints are in To Do or Backlog state.**

Analyses pending sprints to assess estimation confidence and identify unknowns that represent risk. This sub-agent does NOT assess documentation quality — it assesses how confident we can be in the *remaining work*.

```markdown
You are assessing pending work for an Execution Assessment.

## Pending Sprints

<for each sprint: name, status, tasks with AC, dependencies, epic membership>

## Sprint Execution Plan (if available)

<phases, lanes, critical path, dependency graph>

## Assessment Instructions

For each pending sprint, assess two dimensions:

### Estimation Confidence (0-100, higher = more confident in the estimate)

This is NOT a complexity prediction. It measures how well-defined the remaining work is.

Assess these signals:
- **Acceptance criteria clarity**: are all tasks' AC specific and testable? (Apply the vague language patterns check: flag "should be fast", "user-friendly", "etc.", "and more", "connects to backend" without naming specifics)
- **Technical approach defined**: is it clear HOW this will be built, not just WHAT?
- **Integration points identified**: are external APIs, services, databases, and message contracts named?
- **Scope bounded**: are there explicit "out of scope" statements, or is the scope open-ended?
- **Dependencies resolved**: are upstream dependencies done or in progress, or still pending/unknown?
- **Precedent exists**: is this similar to completed sprints (familiar patterns), or is it novel/exploratory?

Scoring guide:
| Score | Interpretation |
|-------|---------------|
| 80-100 | High confidence — well-defined AC, clear technical approach, bounded scope, dependencies resolved |
| 60-79 | Moderate confidence — mostly defined but some gaps in technical approach or dependencies |
| 40-59 | Low confidence — vague AC, unclear integration points, open-ended scope |
| 0-39 | Very low confidence — poorly defined work, significant unknowns, cannot reliably estimate |

### Unknowns and Ambiguity Score (0-100, higher = MORE unknowns, i.e. higher risk)

Identify and count unresolved unknowns. These are first-class risk factors.

Categories of unknowns:
- **Vague acceptance criteria**: AC that use untestable language or lack specifics
- **Undefined integrations**: references to external systems without naming specific APIs or contracts
- **Open questions**: explicitly listed questions that remain unanswered
- **Missing technical detail**: tasks that describe WHAT but not HOW
- **Unresolved dependencies**: dependencies on work or decisions that haven't been completed
- **Scope ambiguity**: unclear boundaries, open-ended statements, "etc." or "and more"
- **Novel/unfamiliar work**: no precedent in completed sprints, team hasn't done this before

Scoring guide:
| Score | Interpretation |
|-------|---------------|
| 0-20 | Very few unknowns — work is well-understood |
| 21-40 | Some unknowns — minor gaps that are manageable |
| 41-60 | Notable unknowns — several unresolved items that could affect delivery |
| 61-80 | Many unknowns — significant gaps in definition, high estimation uncertainty |
| 81-100 | Pervasive unknowns — work is poorly understood, estimation is unreliable |

### Work Type Classification

Classify each sprint into one of these categories to help contextualise risk:
- **CRUD/Standard** — new endpoints, standard data access, familiar patterns
- **Integration** — third-party API integration, message contract changes
- **Migration** — data migration, schema evolution, backward compatibility
- **Refactor** — restructuring existing code without changing behaviour
- **Infrastructure** — CI/CD, deployment, monitoring, platform changes
- **Exploratory** — spike, proof of concept, novel technical approach

### Dependency Graph Position

For each sprint, note:
- Is it on the **critical path**? (blocking downstream sprints)
- How many **downstream dependents** does it have?
- Are its **upstream dependencies** resolved?

## Return Format

Return as JSON:

{
  "sprints": [
    {
      "sprint": "<sprint name or key>",
      "epic": "<parent epic name>",
      "work_type": "<crud_standard|integration|migration|refactor|infrastructure|exploratory>",
      "estimation_confidence": <0-100>,
      "unknowns_score": <0-100>,
      "unknowns": [
        {
          "category": "<vague_ac|undefined_integration|open_question|missing_technical_detail|unresolved_dependency|scope_ambiguity|novel_work>",
          "description": "<specific description of the unknown>",
          "severity": "<high|medium|low>"
        }
      ],
      "dependency_position": {
        "on_critical_path": <boolean>,
        "downstream_dependents": <count>,
        "upstream_resolved": <boolean>
      }
    }
  ],
  "epic_rollup": [
    {
      "epic": "<epic name>",
      "sprints_pending": <count>,
      "avg_estimation_confidence": <0-100>,
      "avg_unknowns_score": <0-100>,
      "critical_path_sprints": <count>,
      "high_severity_unknowns": <count>,
      "dominant_work_types": ["<most common types>"],
      "key_risks": ["<summary of highest-impact unknowns>"]
    }
  ]
}
```

---

### Sub-agent Z: Execution Work Tracking Assessor

**Spawn in Execution mode if work tracking items exist** — provides the task completion and blocker data needed for the execution scoring model.

> This is a lightweight variant of Sub-agent B (Full mode). It focuses on progress metrics and blockers without assessing documentation-related readiness.

```markdown
You are gathering work tracking metrics for an Execution Assessment.

## Work Tracking Artifacts

> **Backend note:** For GitLab/Confluence backends, these are Jira issues.
> For Linear backend, these are Linear Issues. Map Linear states
> (Backlog, Todo, In Progress, Done, Cancelled) to equivalent statuses.

**Sprints:**
<sprint details with status, assignee, points>

**Tasks:**
<task details with status>

## Scoring Dimensions

1. **Task Completion** — Done items / Total items as percentage
2. **Story Points Progress** — Completed points / Total points as percentage
3. **Blocker Count** — Number of blocked items (100 = no blockers, deduct per blocker)

## Return Format

Return as JSON:

{
  "progress": {
    "task_completion": {
      "done": <count>,
      "total": <count>,
      "percentage": <0-100>
    },
    "story_points": {
      "completed": <points>,
      "total": <points>,
      "percentage": <0-100>
    }
  },
  "blocker_count": <count>,
  "blocked_items": ["<issue keys or Linear IDs>"],
  "status_breakdown": {
    "to_do": <count>,
    "in_progress": <count>,
    "done": <count>,
    "blocked": <count>
  },
  "epic_progress": [
    {
      "epic": "<epic name>",
      "sprints_done": <count>,
      "sprints_in_progress": <count>,
      "sprints_pending": <count>,
      "sprints_blocked": <count>,
      "tasks_done": <count>,
      "tasks_total": <count>,
      "points_done": <points>,
      "points_total": <points>
    }
  ]
}
```

---

### Phase 4: Consolidate Results

After all sub-agents return:

1. **Parse JSON results** from each sub-agent
2. **Calculate headline metrics** using the scoring model for the chosen mode

---

#### Full Assessment Scoring Model

**Confidence Score** (weighted composite):
| Component | Weight | Source |
|-----------|--------|--------|
| Documentation Completeness | 25% | Doc Assessor |
| Content Quality | 20% | Doc Assessor |
| Team Readiness | 25% | Work Tracking Assessor (or N/A) |
| Execution Evidence (MR Health) | 20% | Code Assessor `mr_health` score (or N/A) |
| Ambiguity (inverted) | 10% | Doc Assessor |

**Risk Score** (weighted composite):
| Component | Weight | Source |
|-----------|--------|--------|
| Test Coverage (inverted) | 35% | Code Assessor (or N/A) |
| Code Complexity | 25% | Code Assessor (or N/A) |
| Blocker Count | 25% | Work Tracking Assessor (or N/A) |
| Dependency Issues | 15% | Doc + Work Tracking Assessors |

**Progress Score:**
- If story points available: weighted average of (60% points + 40% task completion)
- If no points: task completion percentage
- If no work tracking (no Jira/Linear): N/A

**Handling N/A components:** When a component source is unavailable (e.g. no code assessor in Planning phase), redistribute its weight proportionally across the remaining components. For example, if Code Assessor is N/A for Confidence, redistribute the 20% Execution Evidence weight: Documentation Completeness becomes 31%, Content Quality becomes 25%, Team Readiness becomes 31%, Ambiguity becomes 13%.

3. **Merge recommendations** from all assessors, ranked by severity
4. **Identify phase-appropriate actions**

---

#### Execution Assessment Scoring Model

**Confidence Score** (weighted composite):
| Component | Weight | Source |
|-----------|--------|--------|
| Completed work coverage | 30% | Completed Work Assessor — `complexity_weighted_coverage` from epic rollup (coverage scores weighted so higher-complexity sprints count more) |
| Estimation confidence (pending) | 25% | Pending Work Assessor — average estimation confidence across pending sprints |
| Task completion progress | 20% | Work Tracking Assessor — task/points completion percentage |
| Unknowns/ambiguity (inverted) | 25% | Pending Work Assessor — inverted average unknowns score (100 - unknowns_score) |

**Risk Score** (weighted composite):
| Component | Weight | Source |
|-----------|--------|--------|
| Unmitigated complexity | 30% | Completed Work Assessor — average unmitigated_complexity_score across sprints |
| Unknowns and ambiguity | 30% | Pending Work Assessor — average unknowns_score across pending sprints |
| Blocker count | 20% | Work Tracking Assessor — inverted blocker score (100 = no blockers) |
| Critical path exposure | 20% | Pending Work Assessor — proportion of pending sprints on the critical path with unresolved upstream dependencies |

**Progress Score:**
- If story points available: weighted average of (60% points + 40% task completion)
- If no points: task completion percentage
- If no work tracking: N/A

**Key scoring interaction — complexity vs. coverage:**

| Complexity | Coverage | Effect on Risk | Effect on Confidence |
|-----------|----------|---------------|---------------------|
| High | High | Decreases (well-mitigated) | Increases (complex work delivered safely) |
| High | Low | **Increases** (unmitigated risk) | **Decreases** (complex work inadequately tested) |
| Low | High | Decreases | Increases |
| Low | Low | Neutral | Neutral |

**Handling missing data:** If no completed sprints exist (all pending), Completed Work coverage defaults to N/A and its 30% weight redistributes to Estimation Confidence (40%) and Unknowns (35%), Task Completion stays at 20%, and the remaining 5% goes to Task Completion (25% total). If no pending sprints exist (all done), Pending Work components default to N/A and weight redistributes to Completed Work (55%) and Task Completion (45%).

3. **Merge recommendations** from all assessors, ranked by severity
4. **Identify execution-specific actions** (e.g. "add tests for high-complexity sprint X", "resolve unknowns in sprint Y before starting")

---

### Phase 5: Present Dashboard

Present the progress report appropriate to the chosen mode.

---

#### Full Assessment Dashboard

```markdown
## Project Progress Report — Full Assessment

### [Project/Feature Name]

**Phase:** [Implementation] | **Assessed:** [YYYY-MM-DD HH:MM]

---

### Summary

| Metric | Score | Interpretation |
|--------|-------|----------------|
| **Confidence** | XX% | [High/Medium/Low] — [one-line summary] |
| **Risk** | XX% | [High/Medium/Low] — [one-line summary] |
| **Progress** | XX% | [ahead/on track/behind] — [one-line summary] |

---

### Confidence Breakdown

| Dimension | Score | Notes |
|-----------|-------|-------|
| Documentation Completeness | XX% | [brief note] |
| Content Quality | XX% | [brief note] |
| Team Readiness | XX% | [brief note or N/A] |
| Execution Evidence (MR Health) | XX% | [brief note or N/A] |
| Ambiguity Level | XX% | [brief note] |

---

### Risk Breakdown

| Dimension | Score | Notes |
|-----------|-------|-------|
| Test Coverage | XX% | [brief note or N/A] |
| Code Complexity | XX% | [brief note or N/A] |
| Active Blockers | XX% | [count or N/A] |
| Dependency Issues | XX% | [brief note] |

---

### Progress by Epic

| Epic | Tasks | Points | Status |
|------|-------|--------|--------|
| Epic 1: [Name] | X/Y (XX%) | X/Y (XX%) | [status emoji] [In Progress] |
| Epic 2: [Name] | X/Y (XX%) | X/Y (XX%) | [status emoji] [Not Started] |
| Epic 3: [Name] | X/Y (XX%) | X/Y (XX%) | [status emoji] [Done] |
| **Total** | **X/Y (XX%)** | **X/Y (XX%)** | — |

Status indicators: ✅ Done | 🔄 In Progress | ⏳ Not Started | ❌ Blocked

---

### Recommendations

**High Priority:**
1. [Action] — [why it matters]

**Medium Priority:**
2. [Action] — [why it matters]

**Low Priority:**
3. [Action] — [why it matters]

---

### Open Questions

1. [Question from Feature or docs]
2. [Question identified during assessment]

---

### Strengths

- [Positive aspect 1]
- [Positive aspect 2]
```

---

#### Execution Assessment Dashboard

```markdown
## Project Progress Report — Execution Assessment

### [Project/Feature Name]

**Phase:** [Implementation] | **Assessed:** [YYYY-MM-DD HH:MM]

---

### Summary

| Metric | Score | Interpretation |
|--------|-------|----------------|
| **Confidence** | XX% | [High/Medium/Low] — [one-line summary] |
| **Risk** | XX% | [High/Medium/Low] — [one-line summary] |
| **Progress** | XX% | [ahead/on track/behind] — [one-line summary] |

---

### Confidence Breakdown

| Dimension | Score | Notes |
|-----------|-------|-------|
| Completed Work Coverage | XX% | [brief note — complexity vs. test coverage] |
| Estimation Confidence | XX% | [brief note — how well-defined is remaining work] |
| Task Completion | XX% | [X/Y tasks, X/Y points] |
| Unknowns (inverted) | XX% | [count of unresolved unknowns] |

---

### Risk Breakdown

| Dimension | Score | Notes |
|-----------|-------|-------|
| Unmitigated Complexity | XX% | [sprints with high complexity + low coverage] |
| Unknowns & Ambiguity | XX% | [count and severity of unknowns] |
| Active Blockers | XX% | [count] |
| Critical Path Exposure | XX% | [pending sprints on critical path with unresolved deps] |

---

### Completed Work by Epic

| Epic | Sprints | Avg Complexity | Avg Coverage | Unmitigated | Assessment |
|------|-------|---------------|-------------|-------------|------------|
| [Name] | X done | XX | XX | XX | [Well-covered / At risk / Needs tests] |
| [Name] | X done | XX | XX | XX | [Well-covered / At risk / Needs tests] |

---

### Pending Work by Epic

| Epic | Sprints | Est. Confidence | Unknowns | Critical Path | Dominant Type |
|------|-------|----------------|----------|---------------|--------------|
| [Name] | X pending | XX% | X high, Y med | X sprints | [Integration] |
| [Name] | X pending | XX% | X high, Y med | X sprints | [CRUD/Standard] |

---

### Unknowns & Ambiguity Register

Items below are unresolved unknowns that directly increase risk. Resolving these will improve both confidence and risk scores.

| # | Sprint | Category | Description | Severity |
|---|------|----------|-------------|----------|
| 1 | [Sprint name] | [Undefined integration] | [Description] | High |
| 2 | [Sprint name] | [Vague AC] | [Description] | High |
| 3 | [Sprint name] | [Open question] | [Description] | Medium |

---

### Recommendations

**High Priority:**
1. [Action] — [why it matters]

**Medium Priority:**
2. [Action] — [why it matters]

**Low Priority:**
3. [Action] — [why it matters]

---

### Strengths

- [Positive aspect 1]
- [Positive aspect 2]
```

---

### Phase 6: JSON Output

After the human-readable dashboard, always output a machine-readable JSON block. This enables future trend tracking — confidence should grow and risk should decrease over time.

````markdown
<details>
<summary>Machine-readable assessment (JSON)</summary>

```json
<JSON block>
```

</details>
````

#### JSON Schema

```json
{
  "schema_version": "1.0",
  "assessment_type": "<full|execution>",
  "project": "<project or feature name>",
  "project_ref": "<GitLab branch / Linear URL / Confluence URL / Jira key>",
  "backend": "<gitlab|linear|confluence>",
  "phase": "<planning|elaboration|design|verification|implementation>",
  "assessed_at": "<ISO 8601 timestamp>",
  "scores": {
    "confidence": <0-100>,
    "risk": <0-100>,
    "progress": <0-100 or null>
  },
  "confidence_dimensions": {
    "<dimension_name>": {
      "score": <0-100 or null>,
      "weight": <0.0-1.0>,
      "weighted_contribution": <0-100 or null>
    }
  },
  "risk_dimensions": {
    "<dimension_name>": {
      "score": <0-100 or null>,
      "weight": <0.0-1.0>,
      "weighted_contribution": <0-100 or null>
    }
  },

  // Full Assessment dimension names:
  //   confidence: documentation_completeness, content_quality, team_readiness, execution_evidence, ambiguity_level
  //   risk: test_coverage, code_complexity, blocker_count, dependency_issues
  //
  // Execution Assessment dimension names:
  //   confidence: completed_work_coverage, estimation_confidence, task_completion, unknowns_inverted
  //   risk: unmitigated_complexity, unknowns_and_ambiguity, blocker_count, critical_path_exposure
  //
  // Null scores indicate the dimension was not applicable (e.g. no code assessor in planning phase)
  "epics": [
    {
      "name": "<epic name>",
      "sprints_done": <count>,
      "sprints_in_progress": <count>,
      "sprints_pending": <count>,
      "tasks_done": <count>,
      "tasks_total": <count>,
      "points_done": <points or null>,
      "points_total": <points or null>,
      "avg_complexity": <0-100 or null>,
      "avg_coverage": <0-100 or null>,
      "unmitigated_complexity": <0-100 or null>,
      "estimation_confidence": <0-100 or null>,
      "unknowns_count": <count or null>
    }
  ],
  "unknowns": [
    {
      "sprint": "<sprint name or key>",
      "epic": "<epic name>",
      "category": "<category>",
      "description": "<description>",
      "severity": "<high|medium|low>"
    }
  ],
  "recommendations_count": {
    "high": <count>,
    "medium": <count>,
    "low": <count>
  }
}
```

**Notes on JSON output:**
- `schema_version` allows future format changes without breaking consumers
- `null` values indicate the dimension was not applicable (e.g. no code in planning phase)
- `weighted_contribution` shows the actual points each dimension contributed to the headline score, making the calculation transparent
- **Mode-specific fields (null in the other mode):**
  - Execution mode only: `unknowns` array, `avg_complexity`, `avg_coverage`, `unmitigated_complexity`, `estimation_confidence`, `unknowns_count` on epics
  - Full mode only: all epic fields are populated where data exists; `unknowns` array is empty

---

## Score Interpretation

### Confidence Thresholds

| Level | Score | Meaning |
|-------|-------|---------|
| **High** | 80-100% | Project is well-defined and execution is on track |
| **Medium** | 60-79% | Some concerns to address but manageable |
| **Low** | <60% | Significant gaps; recommend addressing before continuing |

### Risk Thresholds

| Level | Score | Meaning |
|-------|-------|---------|
| **Low** | 0-30% | Risk well-managed |
| **Medium** | 31-60% | Notable risks to monitor |
| **High** | >60% | High risk; recommend mitigation actions |

### Progress Interpretation

| Status | Criteria |
|--------|----------|
| **Ahead** | Progress > expected for elapsed time |
| **On Track** | Progress within 10% of expected |
| **Behind** | Progress > 10% below expected |

---

## Handling Missing Data (Staged Assessment)

### Full Assessment Mode

When data is unavailable for the current phase:

| Situation | Handling |
|-----------|----------|
| No work tracking items (no Jira/Linear) | Progress = N/A, Team Readiness = N/A; redistribute weights to documentation metrics |
| No linked MRs/PRs | Code health = N/A, Risk focuses on documentation/work tracking only; redistribute weights |
| No design docs | Technical readiness scores lower; flag as recommendation |
| No story points/estimates | Use task completion only for progress |
| Feature only | Show documentation metrics only; note early phase |

### Execution Assessment Mode

| Situation | Handling |
|-----------|----------|
| No completed sprints (all pending) | Completed Work = N/A; redistribute to Estimation Confidence and Unknowns |
| No pending sprints (all done) | Pending Work = N/A; redistribute to Completed Work and Task Completion |
| No linked MRs on completed sprints | Cannot assess complexity/coverage; note as a gap and flag as recommendation |
| No sprint execution plan | Cannot assess critical path; Critical Path Exposure = N/A; redistribute weight to other risk components |
| No story points/estimates | Use task completion only for progress |

Display N/A clearly in the dashboard:
```
| Unmitigated Complexity | N/A | No completed sprints with linked MRs |
```

---

## Workflow Chain

- **Previous**: Any AI-DLC skill (can be invoked at any phase)
- **Next**: Address recommendations, continue with implementation

## Definition of Done

- Project/Feature reference collected (GitLab branch, Linear Initiative URL, Confluence URL, or Jira key)
- Assessment mode selected (Full or Execution)
- Backend detected from existing artifacts
- Current phase detected and reported
- All applicable sub-agents spawned and returned
- Headline metrics calculated (Confidence, Risk, Progress) using the appropriate scoring model
- Detailed breakdown tables rendered
- Recommendations prioritised and listed
- Dashboard presented to user
- Machine-readable JSON block included

## Troubleshooting

- **No `acli` available**: Fall back to Atlassian MCP tools.
- **No `glab` available**: Fall back to GitLab MCP tools.
- **No `gh` available**: Fall back to GitHub MCP tools if configured, or ask user to provide PR URLs manually.
- **Cannot detect backend**: Ask user to specify which backend (GitLab, Linear, or Confluence) was used.
- **Cannot detect phase**: Ask user to confirm which artifacts exist.
- **Jira access denied**: Show documentation metrics only; note Jira was inaccessible.
- **Linear access denied**: Show documentation metrics only; note Linear was inaccessible.
- **GitLab repo not cloned**: Ask user for repo URL and clone, or ask for branch name to fetch remotely via `glab`.
- **MR/PR links not found**: Check Jira/Linear issue links; ask user to provide MR/PR URLs manually.
- **Sub-agent timeout**: Report which assessor failed and offer to retry or skip that dimension.
- **Conflicting data**: Report the conflict in recommendations (e.g., work tracking says done but no MR merged).
- **Very early phase**: If only Feature exists, show limited dashboard with phase-appropriate metrics.
- **Execution mode in early phase**: If no sprints or work tracking exist, suggest using Full Assessment mode instead.
