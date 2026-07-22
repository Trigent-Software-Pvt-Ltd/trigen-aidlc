# Linear Backend Reference

This document defines Linear-specific operations for the AIDLC workflow using native Linear Initiatives, Projects, and Issues.

## Key Difference: Linear Replaces BOTH Confluence AND Jira

When using the Linear backend:
- **Documentation** lives in Linear object descriptions (markdown supported)
- **Work tracking** is native Linear Issues
- **No `/aidlc-verify` Jira transfer needed** - Linear IS the work tracker

## AIDLC → Linear Mapping

| AIDLC Concept | Linear Object | Linear MCP Tool |
|---------------|---------------|-----------------|
| Project | Team | `list_teams`, `get_team` |
| Feature | Initiative | `save_initiative`, `get_initiative` |
| Epic | Project | `save_project`, `get_project` |
| Task | Issue | `save_issue`, `list_issues` |
| Sprint | Label or Milestone | `save_milestone`, `list_issue_labels` |

## Prerequisites

Before starting any Linear-based workflow:

1. **Verify Linear MCP is configured** - Check for Linear tools in available tools
2. **Identify the Team** - Use `list_teams` to find the appropriate team

```
# List available teams
list_teams(query: "<team name>")
```

## Workflow: New Feature

### Step 1: Select Team

```
list_teams(query: "engineering")
```

Response provides team ID and key needed for creating objects.

### Step 2: Create Initiative (Feature)

```
save_initiative(
  name: "Feature: <Title>",
  description: "<Full Feature markdown content>",
  status: "Planned",
  owner: "<user ID or 'me'>"
)
```

**Initiative Description Template:**

```markdown
## Overview

<High-level description of the initiative>

## Problem Statement

<What problem are we solving?>

## Goals

1. <Goal 1>
2. <Goal 2>

## Non-Goals

- <What we're explicitly NOT doing>

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| <Metric 1> | <Value> | <How measured> |

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| <Risk 1> | Medium | High | <Mitigation strategy> |

---
*AIDLC Backend: Linear*
*Created: <date>*
```

### Step 3: Store Initiative Reference

After creation, store the Initiative ID and URL for subsequent phases:

```typescript
BackendContext.initiativeId = "<returned initiative ID>"
BackendContext.initiativeUrl = "<returned initiative URL>"
```

## Workflow: Elaborate

Elaborate creates Projects (Epics) only. Task Issues are created during the design phase.

### Step 1: Fetch Initiative

```
get_initiative(
  query: "<initiative ID or name>",
  includeProjects: true
)
```

### Step 2: Create Projects (Epics)

For each Epic, create a Linear Project:

```
save_project(
  name: "Epic <N>: <Title>",
  description: "<Epic markdown content>",
  team: "<team ID>",
  initiatives: ["<initiative ID>"],
  priority: 2  # 0=None, 1=Urgent, 2=High, 3=Medium, 4=Low
)
```

**Project Description Template:**

```markdown
## Problem Statement

<What specific aspect of the Feature's problem does this epic address?>

## Target Users

<Who benefits from this epic's output?>

## Scope

**In Scope:**
- ...

**Out of Scope:**
- ...

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|-------------|

## Acceptance Criteria

- [ ] <Criterion 1>
- [ ] <Criterion 2>

## Indicative Tasks

Suggested breakdown for sizing and planning purposes. Refined during /aidlc-design.

| # | Description | Size | Sprint |
|---|-------------|------|------|
| 1 | ... | M | 1 |

> Sizes: XS / S / M / L / XL / XXL — rough effort estimate, not a commitment.

## Dependencies

- Epic NN: <reason>
- External: <third-party or team dependency>

## Open Questions

- ...

---
*Epic Number: <N>*
*AIDLC Backend: Linear*
```

## Workflow: Design

Design creates Issues (Task Specifications) under the appropriate Epic Projects.

### Step 1: Create Labels for Sprints (if not already created)

```
create_issue_label(
  name: "Sprint <N>",
  color: "#0052CC",
  teamId: "<team ID>"
)
```

### Step 2: Create Issues (Task Specifications)

For each Task Spec, create a Linear Issue:

```
save_issue(
  title: "Task <id>: <title>",
  description: "<Task Spec markdown content>",
  team: "<team ID>",
  project: "<project ID for this epic>",
  state: "backlog",
  estimate: <size>,
  labels: ["Sprint <sprint id>"]
)
```

**Issue Description Template (Task Spec format):**

```markdown
**Task ID**: <id>
**Size**: <size> (Fibonacci)
**Sprint**: <sprint>

## Behaviour

- [ ] <Observable outcome 1>
- [ ] <Observable outcome 2>

## Rules

- <Hard constraint>

## Files

**Modify:** `<path>`
**Create:** `<path>`
**Reference:** `<path>`

## Dependencies

- [<blocking|non-blocking>] <what> — <rationale>

## Risks

- <Risk> — mitigate: <mitigation>

## Not in Scope

- <Explicit boundary>

---
*AIDLC Backend: Linear*
```

Omit `Rules`, `Files`, `Dependencies`, `Risks`, and `Not in Scope` sections when they have no content.

### Step 3: Create Milestones (Sprints) - Optional

If using Milestones for Sprint tracking:

```
save_milestone(
  project: "<project ID>",
  name: "Sprint <N>",
  description: "Implementation sprint grouping related tasks",
  targetDate: "<ISO date>"
)
```

Then associate Issues with the Milestone:

```
save_issue(
  id: "<existing issue ID>",
  milestone: "<milestone ID>"
)
```

## Workflow: Verify

### Step 1: Fetch All Content

```
# Fetch Initiative with Projects
get_initiative(
  query: "<initiative ID>",
  includeProjects: true,
  includeSubInitiatives: false
)

# For each Project, fetch Issues
list_issues(
  project: "<project ID>",
  limit: 100
)
```

### Step 2: Run doc-verifier

Spawn the doc-verifier subagent with Linear-sourced content (see VerificationInput format below).

### Step 3: Update Status (NO Jira Transfer)

After verification passes, update the Initiative status:

```
save_initiative(
  id: "<initiative ID>",
  status: "Active"
)
```

### Step 4: Add Status Update (Optional)

```
save_status_update(
  type: "initiative",
  initiative: "<initiative ID>",
  body: "## Verification Complete\n\nAll documentation verified and ready for implementation.",
  health: "onTrack"
)
```

## Linear MCP Tools Reference

### Teams

| Tool | Parameters | Returns |
|------|------------|---------|
| `list_teams` | `query?` | Team list with IDs, names, keys |
| `get_team` | `query` (ID, key, or name) | Team details |

### Initiatives

| Tool | Parameters | Returns |
|------|------------|---------|
| `save_initiative` | `name`, `description?`, `status?`, `owner?`, `id?` (for update) | Initiative with ID, URL |
| `get_initiative` | `query`, `includeProjects?` | Initiative details |
| `list_initiatives` | `query?`, `owner?`, `status?` | Initiative list |

### Projects

| Tool | Parameters | Returns |
|------|------------|---------|
| `save_project` | `name`, `team`, `description?`, `initiatives?`, `priority?`, `id?` | Project with ID, URL |
| `get_project` | `query`, `includeMilestones?` | Project details |
| `list_projects` | `team?`, `initiative?`, `query?` | Project list |

### Issues

| Tool | Parameters | Returns |
|------|------------|---------|
| `save_issue` | `title`, `team`, `description?`, `project?`, `state?`, `estimate?`, `labels?`, `id?` | Issue with ID, URL |
| `list_issues` | `project?`, `state?`, `assignee?`, `label?` | Issue list |
| `get_issue` | `id`, `includeRelations?` | Issue details |

### Comments

| Tool | Parameters | Returns |
|------|------------|---------|
| `create_comment` | `issueId`, `body` | Comment |
| `list_comments` | `issueId` | Comment list |

### Milestones

| Tool | Parameters | Returns |
|------|------------|---------|
| `save_milestone` | `project`, `name`, `description?`, `targetDate?`, `id?` | Milestone |
| `list_milestones` | `project` | Milestone list |

## Status Mapping

| AIDLC Status | Linear Initiative Status | Linear Issue State |
|--------------|-------------------------|-------------------|
| Draft | Planned | Backlog |
| In Review | Planned | Backlog |
| Approved | Active | Todo |
| In Progress | Active | In Progress |
| Complete | Completed | Done |

## Size to Estimate Mapping

Task Spec `size` maps directly to Linear `estimate` (story points):

| Task Spec size | Linear estimate |
|----------------|-----------------|
| 1 | 1 |
| 2 | 2 |
| 3 | 3 |
| 5 | 5 |
| 8 | 8 |
| 13 | 13 |

## Reading Content for Verification

When reading Linear backend content for doc-verifier:

```typescript
interface VerificationInput {
  type: 'feature' | 'epic' | 'story' | 'task';
  backend: 'linear';
  id: string;              // Linear object ID
  title: string;           // Initiative/Project/Issue name
  bodyMarkdown: string;    // Description field content
  metadata: {
    linearUrl: string;     // Web URL
    status: string;        // Current status
    teamKey: string;       // Team identifier
    projectId?: string;    // Parent project (for Issues)
    initiativeId?: string; // Parent initiative (for Projects)
  };
}
```

## Review Workflow

For Linear backend, reviews happen via Linear comments:

### Adding Review Comment to Initiative

```
# First, create an Issue on the Initiative's team for the review
save_issue(
  title: "Review: Feature <N> - <Title>",
  team: "<team ID>",
  description: "## Review Findings\n\n<findings markdown>"
)

# Link it to the Initiative by adding to a Project under that Initiative
```

### Adding Comment to Issue

```
create_comment(
  issueId: "<issue ID>",
  body: "## Review Feedback\n\n<feedback markdown>"
)
```

## Labels for Sprint Assignment

Create labels for Sprint groupings:

```
create_issue_label(
  name: "Sprint 1",
  color: "#0000FF",
  teamId: "<team ID>"
)
```

Then assign Issues to Sprints via labels:

```
save_issue(
  id: "<issue ID>",
  labels: ["Sprint 1"]
)
```
