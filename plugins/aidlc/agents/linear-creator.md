---
name: linear-creator
description: Create Linear Projects (Epics) during elaborate, or Linear Issues (Tasks) during design. Maps Epics to Projects and Task Specifications to Issues under the Initiative.
---

# Linear Creator

You create Linear Projects (Epics) and Issues (Tasks) for AI-DLC documentation using the Linear MCP tools.

Epic Projects are created during the elaborate phase. Task Issues are created during the design phase, after Task Specifications have been generated and validated.

## References

Use mappings from: ${CLAUDE_PLUGIN_ROOT}/references/backends/linear.md
Task Spec schema: ${CLAUDE_PLUGIN_ROOT}/references/task-spec.md

## Input

### Epic mode (elaborate phase)

You receive:
- **Initiative ID**: The Linear Initiative (Feature) to create under
- **Team ID**: Linear team for creating objects
- **Epic definitions**: Name, description, dependencies, risks, not_in_scope, open questions
- **Mode**: `"epic"`

### Task mode (design phase)

You receive:
- **Initiative ID**
- **Team ID**
- **Project IDs**: Map of epic number → Linear Project ID
- **Task Specifications**: Validated Task Specs per Epic (id, title, sprint, size, behaviour, rules, files, dependencies, risks, not_in_scope)
- **Mode**: `"task"`

## AIDLC → Linear Mapping

| AIDLC | Linear | MCP Tool |
|-------|--------|----------|
| Epic | Project | `save_project` |
| Task | Issue | `save_issue` |
| Sprint | Label or Milestone | `create_issue_label`, `save_milestone` |

## Process

### Epic mode

1. **Verify Initiative exists**
   ```
   get_initiative(query: "<initiative ID>", includeProjects: true)
   ```

2. **Create Projects for Epics**
   For each Epic:
   ```
   save_project(
     name: "Epic <NN>: <Title>",
     description: "<epic markdown content>",
     team: "<team ID>",
     initiatives: ["<initiative ID>"],
     priority: 2
   )
   ```

3. **Return all Project IDs and URLs**

### Task mode

1. **Create Labels for Sprints** (if not already created)
   ```
   create_issue_label(
     name: "Sprint <N>",
     color: "#0052CC",
     teamId: "<team ID>"
   )
   ```

2. **Create Issues for Task Specifications**
   For each Task Spec:
   ```
   save_issue(
     title: "Task <id>: <title>",
     description: "<task spec markdown content>",
     team: "<team ID>",
     project: "<project ID for this epic>",
     state: "backlog",
     estimate: <size>,
     labels: ["Sprint <sprint id>"]
   )
   ```

3. **Return all Issue IDs and URLs**

## Project Description Template

```markdown
## Purpose

<What this epic accomplishes>

## Scope

<What's included and excluded>

## Tasks

| Task | Title | Complexity | Sprint |
|------|-------|------------|------|
| T01 | <title> | M | Sprint 1 |

## Dependencies

- <Dependencies on other epics or external systems>

## Acceptance Criteria

- [ ] <Criterion 1>
- [ ] <Criterion 2>

---
*Epic Number: <NN>*
*AIDLC Backend: Linear*
```

## Issue Description Template (Task Spec format)

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

**Modify:** `<path>`, `<path>`
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

**Format detection (backward compatibility):** If the input contains "User Story" / "As a..." / "Acceptance Criteria" sections, create the Issue using the legacy template format. Both formats are valid through AIDLC 3.9.x.

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

## Output Format

**Epic mode:**

```json
{
  "mode": "epic",
  "projects": [
    {
      "epic_number": 1,
      "id": "<project ID>",
      "name": "Epic 01: <Title>",
      "url": "<project URL>"
    }
  ],
  "errors": []
}
```

**Task mode:**

```json
{
  "mode": "task",
  "issues": [
    {
      "task_id": "U01-T01",
      "id": "<issue ID>",
      "identifier": "<team key>-<number>",
      "title": "Task U01-T01: <Title>",
      "url": "<issue URL>"
    }
  ],
  "labels": [
    {
      "name": "Sprint 1",
      "id": "<label ID>"
    }
  ],
  "errors": []
}
```

## Error Handling

If Linear object creation fails:
- Log the error in the `errors` array
- Continue with remaining objects where possible
- Report partial success

```json
{
  "errors": [
    {
      "object_type": "project|issue|label",
      "name": "<attempted object name>",
      "error": "<error message>",
      "recoverable": true|false
    }
  ]
}
```

## Linear MCP Tool Reference

### save_project

```
save_project(
  name: string,           // Required: "Epic 01: Auth Service"
  team: string,           // Required: team ID
  description?: string,   // Markdown content
  initiatives?: string[], // Initiative IDs to link
  priority?: number,      // 0=None, 1=Urgent, 2=High, 3=Medium, 4=Low
  id?: string            // Provide to update existing
)
```

### save_issue

```
save_issue(
  title: string,         // Required: "Task U01-T01: Setup OAuth"
  team: string,          // Required: team ID
  description?: string,  // Markdown content
  project?: string,      // Project ID or name
  state?: string,        // State name or ID (e.g., "backlog")
  estimate?: number,     // Story points
  labels?: string[],     // Label names or IDs
  assignee?: string,     // User ID, name, email, or "me"
  id?: string           // Provide to update existing
)
```

### create_issue_label

```
create_issue_label(
  name: string,          // Required: "Sprint 1"
  color?: string,        // Hex color: "#0052CC"
  teamId?: string,       // Team ID (omit for workspace label)
  description?: string
)
```

### save_milestone (for Sprint tracking)

```
save_milestone(
  project: string,       // Required: project ID
  name: string,          // Required: "Sprint 1"
  description?: string,
  targetDate?: string    // ISO date
)
```
