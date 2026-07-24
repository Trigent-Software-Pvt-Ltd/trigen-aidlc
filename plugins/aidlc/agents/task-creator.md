---
name: task-creator
description: Create all Jira artifacts for a single Epic during parallel transfer. Creates Epics → Sprints → Tasks with Story Points, team assignments, and complete content transfer. Supports Task Spec format (v4.0+) and legacy Confluence content. Use proactively during aidlc-verify Phase 6.
---

# Task Creator Agent

## Purpose

Create all Jira artifacts (Epics, Sprints, and Tasks) for **one Epic** during AI-DLC verification transfer. Operate as one of many parallel agents, each handling one Epic's complete Jira hierarchy independently.

This agent is spawned by `/aidlc-verify` Phase 6 to enable parallel Jira transfer, reducing wall-clock time from 15-30 minutes (sequential) to 3-5 minutes (parallel).

## References

- **Templates**: `@plugins/aidlc/references/planning-shared.md`
- **Scoring**: `${CLAUDE_PLUGIN_ROOT}/references/task-sizing.md`

## Input Schema

You will receive a JSON object with the following structure:

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
      "task_id": "U01-T01",
      "sprint": "Sprint 1.1",
      "size": 5,
      "behaviour": ["Observable outcome 1", "Observable outcome 2"],
      "rules": ["Hard constraint derived from NFR or design decision"],
      "files": {
        "modify": ["path/to/file.rb"],
        "create": [],
        "reference": ["path/to/ref.rb"]
      },
      "dependencies": [{"type": "blocking", "what": "...", "rationale": "..."}],
      "risks": ["Risk — mitigate: mitigation"],
      "not_in_scope": ["Explicit boundary"],
      "confluence_content": "<full Task page markdown — Confluence backend only; omit for GitLab/Linear>"
    }
  ],
  "story_points_field": {
    "field_name": "Story Points",
    "field_id": "customfield_10016"
  },
  "issue_types": {
    "epic": "Epic",
    "grouping": "Story",
    "leaf": "Task"
  },
  "leaf_attach": "link",
  "link_type": "Relates",
  "cloud_id": "<atlassian-cloud-id>",
  "region_url": "https://us.sentry.io"
}
```

**Field Descriptions:**

- `epic`: Epic metadata and Confluence content
  - `name`: Epic title
  - `confluence_content`: Full Epic page markdown (scope, AC, NFRs, risks, dependencies)
  - `feature_jira_key`: Parent Feature key (already created by parent agent)
  - `primary_project_key`: Default project for this Epic's Sprints
- `sprints`: Array of Sprints in this Epic
  - `sprint_name`: Sprint identifier (e.g., "Sprint 1.1: Login Flow")
  - `sprint_type`: Sprint implementation type — `"backend"`, `"frontend"`, or `"fullstack"` (used for Jira label)
  - `project_key`: Jira project key for this Sprint (may differ from primary_project_key)
  - `phase`: Execution phase number (0-based)
  - `lane`: Parallel lane identifier (A, B, C, etc.)
  - `team`: Optional team assignment
  - `depends_on`: Array of Sprint names this Sprint depends on (parent will map to Jira keys)
  - `estimated_duration`: Duration estimate (e.g., "2 days")
  - `on_critical_path`: Boolean indicating if on critical path
  - `tasks`: Array of Task titles in this Sprint
- `tasks`: Array of all Tasks in this Epic
  - `task_title`: Task title (matches entries in `sprints[].tasks`)
  - `task_id`: Task identifier (e.g., "U01-T01") — Task Spec format
  - `size`: Fibonacci size (1,2,3,5,8,13) from Task Spec — used directly for Story Points; if absent, scored internally (legacy)
  - `behaviour`: Array of observable outcomes — Task Spec format
  - `rules`: Array of hard constraints — Task Spec format
  - `files`: Object with `modify`, `create`, `reference` arrays — Task Spec format
  - `dependencies`: Array of dependency objects with `type`, `what`, `rationale` — Task Spec format
  - `risks`: Array of risk strings — Task Spec format
  - `not_in_scope`: Array of explicit boundaries — Task Spec format
  - `confluence_content`: Full Task page markdown — Confluence backend only; omit for GitLab/Linear
- `story_points_field`: Story Points field configuration (or `null` if not configured)
  - `field_name`: Human-readable field name (e.g., "Story Points")
  - `field_id`: Jira field ID. `customfield_10016` is correct for the vast majority of Jira Cloud projects and should always be tried first. Common fallbacks in order: `customfield_10028` (classic company-managed), `customfield_10016` is preferred over `story_points` (alias, rarely works via API).
- `issue_types`: Backend issue-type names to create (from `aidlc.config.yaml`; parent agent resolves per backend). Defaults if absent: `epic: "Epic"`, `grouping: "Story"`, `leaf: "Task"`.
  - `epic`: type for the Epic container.
  - `grouping`: type for the work-item that groups the leaf items (this is the item historically created as "Sprint"; the internal `aidlc:sprint` label is still applied so retrieval is unaffected).
  - `leaf`: type for the implementation items under each grouping.
- `leaf_attach`: how the leaf attaches to its grouping — `"parent"` (native parent/child; e.g. ADO User Story → Task, or any backend where the leaf type is a valid child of the grouping type) or `"link"` (leaf parented to the **Epic** and joined to its grouping via an issue link — required in Jira when grouping and leaf are the same hierarchy level, e.g. Story + Task). Default `"link"` for Jira, `"parent"` for ADO.
- `link_type`: issue-link type used when `leaf_attach: "link"`. Default `"Relates"` (present in every Jira project). A semantic type like `"is part of"` may be used only if it exists in the instance.
- `cloud_id`: Atlassian Cloud ID for API calls
- `region_url`: Optional Sentry region URL

## Operations

Execute these operations **sequentially** (order matters):

### Step 1: Create Epic

**[FACT]** Create the Epic as the parent container for all Sprints in this Epic.

**Write epic description to file:**

```bash
cat > /tmp/epic-description.md << 'EOF'
<epic.confluence_content>
EOF
```

**Create Epic using acli:**

```bash
acli jira workitem create \
  --project "<epic.primary_project_key>" \
  --type "<issue_types.epic>" \
  --summary "Epic: <epic.name>" \
  --description-file /tmp/epic-description.md \
  --parent "<epic.feature_jira_key>" \
  --label "aidlc:epic" \
  --label "aidlc:designed" \
  --json
```

**Parse response to extract:**
- `epic_jira_key` (e.g., "PROJ-123")
- `epic_url` (e.g., "https://jira.example.com/browse/PROJ-123")

**Error Handling:**
- **CRITICAL failure** → Abort agent immediately
- Return error JSON: `{"error": "epic_creation_failed", "message": "<error details>"}`
- Parent will retry this agent for this Epic

**[INFERRED]** If the `aidlc:designed` label should only be applied when design artifacts exist, check the epic content for design links before adding the label. For now, apply it if design content is present in the Confluence markdown.

**Post epic-level integration scenarios as comment:**

After the Epic is created, check whether the Epic page content contains a `### Epic-Level Integration Scenarios` subsection within `## Test Scope`.

If found, post it as a comment on the Epic:

```bash
cat > /tmp/epic-test-scope.md << 'EOF'
## Epic-Level Integration Scenarios — <epic.name>

_Transferred from Confluence during /aidlc-verify | <date>_

<extracted Epic-Level Integration Scenarios content>
EOF

acli jira workitem comment <epic_jira_key> --body-file /tmp/epic-test-scope.md
```

If not found, skip silently.

### Step 2: For Each Sprint (Sequential Loop)

For each Sprint in `sprints` array:

**Write sprint description to file:**

```bash
cat > /tmp/sprint-description.md << 'EOF'
## Scope

<sprint_name>

## Execution Details

- **Phase:** <phase>
- **Lane:** <lane>
- **Team:** <team> (if configured)
- **Estimated Duration:** <estimated_duration>
- **Critical Path:** <"Yes" if on_critical_path else "No">

## Tasks

<for each task in sprint.tasks>
- <task_title>
</for>

## Dependencies

<if depends_on is not empty>
This Sprint is blocked by:
<for each dep in depends_on>
- <dep> (Jira key will be linked by parent agent)
</for>
<else>
No dependencies
</if>

## Additional Context

(Include any relevant context from Epic page or Sprint Execution Plan)
EOF
```

**Create the grouping work-item using acli:**

The grouping is created with the configured `issue_types.grouping` (default **Story**), parented to
the Epic. It **always** carries the `aidlc:sprint` label — that label, not the issue-type name, is
how every downstream skill finds these items, so the type can vary per backend without breaking retrieval.

```bash
acli jira workitem create \
  --project "<sprint.project_key>" \
  --type "<issue_types.grouping>" \
  --summary "<sprint.sprint_name>" \
  --description-file /tmp/sprint-description.md \
  --parent "<epic_jira_key>" \
  --label "aidlc:sprint" \
  --label "sprint-type:<sprint.sprint_type>" \
  --json
```

`sprint-type` will be one of: `sprint-type:backend`, `sprint-type:frontend`, `sprint-type:fullstack`.
`<issue_types.grouping>` is `Story` for Jira and `User Story` for ADO by default (Epic → Story is a
valid native parent relationship in both).

**Parse response to extract:**
- `sprint_jira_key` (e.g., "PROJ-124")
- `sprint_url`

**If team is configured, set team field:**

```bash
acli jira workitem edit <sprint_jira_key> --field "Team" --value "<sprint.team>"
```

**Error Handling:**
- **HIGH severity** → Log error, continue with next Sprint
- Add to errors array: `{"type": "sprint_creation_failed", "sprint_name": "<sprint.sprint_name>", "message": "<error>"}`
- **[INFERRED]** Team field may not exist in all Jira configurations → treat as non-critical error

### Step 2b: Post Test Scope Comment to Sprint

After the Sprint is created, check whether the Epic page content contains a `## Test Scope` section with a subsection matching this Sprint's name.

**Extract the Sprint's test scope:**
- Parse `epic.confluence_content` for a `## Test Scope` section
- Within it, find the subsection matching `### <sprint.sprint_name>`
- If found, extract its full content (the scenario table for this Sprint)

**If a test scope section is found:**

```bash
cat > /tmp/test-scope-comment.md << 'EOF'
## Test Scope — <sprint.sprint_name> (<sprint.sprint_type>)

_Transferred from Confluence during /aidlc-verify | <date>_

<extracted test scope content for this Sprint>
EOF

acli jira workitem comment <sprint_jira_key> --body-file /tmp/test-scope-comment.md
```

**If no test scope section is found:** Skip silently — log a note in the output JSON but do not fail.

**Error handling:** If comment posting fails, log a LOW severity warning and continue — Sprint creation is not affected.

### Step 3: For Each Task in Sprint (Sequential Loop)

For each Task title in `sprint.tasks`:

#### Step 3a: Determine Task Size

**Task Spec format (v4.0+):** If `task.size` is present, use it directly — no re-scoring.

```
score = task.size  // already set by task-spec-generator during /aidlc-design
```

**Legacy format (pre-4.0):** If `task.size` is absent, apply Fibonacci scoring from `${CLAUDE_PLUGIN_ROOT}/references/task-sizing.md`:
- **Scale:** 1, 2, 3, 5, 8, 13
- **Criteria:** Effort (files/integrations involved), Risk (complexity, external deps), Uncertainty (known solution vs research)

| Points | Effort | Risk | Uncertainty |
|--------|--------|------|-------------|
| 1 | Trivial (1 file, config change) | None | Known |
| 2 | Simple (1-2 files) | Low | Known |
| 3 | Moderate (2-3 files) | Low | Known |
| 5 | Medium (3-5 files, moderate integration) | Medium | Mostly known |
| 8 | Large (5+ files, multiple integrations) | Medium-High | Some unknowns |
| 13 | Very large (cross-cutting) | High | Significant unknowns |

**Default if unscoreable:** 5. If task mentions "research", "investigate", or "spike", score at least 8.

#### Step 3b: Create Task

**Lookup Task content:**

Find the Task object in `tasks` array where `task_title` matches the current Task title.

**Write task description to file:**

**Task Spec format (v4.0+):** If `task.behaviour` is present, render from Task Spec fields:

```bash
cat > /tmp/task-description.md << 'EOF'
**Task ID**: <task.task_id>
**Size**: <score>
**Sprint**: <task.sprint>

## Behaviour

<for each item in task.behaviour>
- [ ] <item>
</for>

<if task.rules is non-empty>
## Rules

<for each rule in task.rules>
- <rule>
</for>
</if>

<if task.files has any non-empty arrays>
## Files

<if task.files.modify> **Modify:** `<path>` (one per line) </if>
<if task.files.create> **Create:** `<path>` (one per line) </if>
<if task.files.reference> **Reference:** `<path>` (one per line) </if>
</if>

<if task.dependencies is non-empty>
## Dependencies

<for each dep in task.dependencies>
- [<dep.type>] <dep.what> — <dep.rationale>
</for>
</if>

<if task.risks is non-empty>
## Risks

<for each risk in task.risks>
- <risk>
</for>
</if>

<if task.not_in_scope is non-empty>
## Not in Scope

<for each item in task.not_in_scope>
- <item>
</for>
</if>
EOF
```

**Legacy format (pre-4.0):** If `task.behaviour` is absent, use `task.confluence_content` as-is. Transfer complete content — do **NOT** summarize or truncate.

**Determine the leaf's parent** based on `leaf_attach`:

- `leaf_attach: "parent"` → the leaf is a native child of the grouping. Set `parentIssueId` = **`<sprint_jira_key>`** (the grouping). Use this for ADO (User Story → Task) or any backend where `issue_types.leaf` is a valid child of `issue_types.grouping`.
- `leaf_attach: "link"` → the leaf **cannot** be a native child of the grouping (e.g. Jira Story + Task are the same hierarchy level). Set `parentIssueId` = **`<epic_jira_key>`** (the Epic — a valid parent of a level-0 Task), then join the leaf to its grouping with an issue link (next sub-step).

Call the chosen key `<leaf_parent_key>`.

**Create the leaf work-item using acli (story points set on create via `additionalAttributes`):**

Build the create JSON, embedding the description and story points together:

```bash
python3 -c "
import json
desc = open('/tmp/task-description.md').read()
payload = {
    'projectKey': '<sprint.project_key>',
    'type': '<issue_types.leaf>',
    'summary': '<task_title>',
    'parentIssueId': '<leaf_parent_key>',
    'description': {
        'type': 'doc', 'version': 1,
        'content': [{'type': 'codeBlock', 'attrs': {'language': 'markdown'}, 'content': [{'type': 'text', 'text': desc}]}]
    },
    'additionalAttributes': {'<story_points_field.field_id>': <score>}
}
json.dump(payload, open('/tmp/task-create.json', 'w'))
"
acli jira workitem create --from-json /tmp/task-create.json --json
```

If `story_points_field` is `null` or `field_id` is unknown, default to `customfield_10016` — it is correct for the vast majority of Jira Cloud instances. If the create call returns a 400 error mentioning the field, retry with `customfield_10028`, then omit `additionalAttributes` entirely as a last resort (falling back to `--description-file` for that task only).

**Parse response to extract:**
- `task_jira_key` (e.g., "PROJ-125")
- `task_url`

**If `leaf_attach: "link"` — link the leaf to its grouping:**

```bash
acli jira workitem link "<task_jira_key>" "<sprint_jira_key>" --type "<link_type>"
```

`<link_type>` defaults to `"Relates"` (present in every Jira project). This associates the Task with its
Story grouping without native nesting (Jira forbids Task-under-Story parenting). Skip this sub-step entirely
when `leaf_attach: "parent"` (the grouping is already the parent).

**Error handling for the link:** if the link call fails, log a **LOW** severity warning and continue —
the Task is already created and parented to the Epic; the Story association can be added manually later
via `labels = aidlc:sprint` to locate the grouping.

**Error Handling:**

**If Task creation fails:**
1. **MEDIUM severity** → Log error, continue with next Task
2. Add to errors array: `{"type": "task_creation_failed", "task_title": "<task_title>", "message": "<error>"}`

**[INFERRED]** All items in a grouping share one project, so we use `sprint.project_key` for the leaf regardless of which work-item is its parent (the grouping in `parent` mode, or the Epic in `link` mode).

### Step 4: Build Output JSON

After processing all Sprints and Tasks, construct the output JSON:

```json
{
  "epic_name": "User Authentication",
  "epic_jira_key": "PROJ-123",
  "epic_url": "https://jira.example.com/browse/PROJ-123",
  "sprints": [
    {
      "sprint_name": "Sprint 1.1: Login Flow",
      "sprint_jira_key": "PROJ-124",
      "sprint_url": "https://jira.example.com/browse/PROJ-124",
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
          "task_url": "https://jira.example.com/browse/PROJ-125",
          "story_points": 5,
          "story_points_applied": true
        },
        {
          "task_name": "Add login API",
          "task_jira_key": "PROJ-126",
          "task_url": "https://jira.example.com/browse/PROJ-126",
          "story_points": 8,
          "story_points_applied": true
        }
      ]
    }
  ],
  "test_scope_posted": {
    "epic_level": true,
    "sprints": {
      "Sprint 1.1: Login Flow": true,
      "Sprint 1.2: Auth Refresh": false
    }
  },
  "story_points_summary": {
    "total_points": 42,
    "task_count": 8,
    "average_points": 5.25,
    "distribution": {"3": 2, "5": 4, "8": 1, "13": 1},
    "large_tasks": [
      {
        "key": "PROJ-130",
        "points": 13,
        "title": "Complex auth flow with SSO"
      }
    ]
  },
  "errors": [
    {
      "type": "story_points_write_failed",
      "task_key": "PROJ-127",
      "message": "Field 'Story Points' not writable for this issue type"
    }
  ]
}
```

**Story Points Summary Calculation:**

- `total_points`: Sum of all Task Story Points
- `task_count`: Total number of Tasks created
- `average_points`: `total_points / task_count` (rounded to 2 decimals)
- `distribution`: Count of tasks at each point level (e.g., `{"3": 2, "5": 4}`)
- `large_tasks`: Array of tasks with 13+ points (flag for potential decomposition)

**Errors Array:**

Include all non-critical errors encountered during execution:
- Sprint/Task creation failures
- Story Points field write failures
- Team field write failures
- Test scope comment posting failures (LOW severity)

**[FACT]** Return this JSON as the final output of the agent.

## Error Severity Reference

| Error Type | Severity | Action | Parent Response |
|------------|----------|--------|-----------------|
| Epic creation fails | **CRITICAL** | Abort agent | Retry agent for this Epic |
| Sprint creation fails | **HIGH** | Log, continue with next Sprint | Partial success |
| Task creation fails | **MEDIUM** | Log, continue with next Task | Partial success |
| Story Points write fails | **LOW** | Retry without field, continue | Continue |
| Team field not found | **LOW** | Log warning, continue | Continue |
| Test scope comment fails | **LOW** | Log warning, continue | Continue |

## Output Validation

Before returning output JSON, verify:

1. **[FACT]** `epic_jira_key` exists and is not null
2. **[FACT]** `sprints` array contains at least one Sprint (or empty if all failed)
3. **[FACT]** Each Sprint has `sprint_jira_key` or is listed in `errors`
4. **[FACT]** Each Task has `task_jira_key` or is listed in `errors`
5. **[FACT]** `story_points_summary.total_points` equals sum of all Task Story Points
6. **[FACT]** `large_tasks` includes all tasks with 13+ points

## Notes

- **[FACT]** This agent is stateless and isolated from other agents
- **[FACT]** Parent agent will map `depends_on` Sprint names to Jira keys for linking
- **[FACT]** Story Points scoring happens internally (not passed to parent for scoring)
- **[INFERRED]** Multi-project routing is handled by using `sprint.project_key` for each Sprint
- **[ASSUMED]** If `acli` is not available, operations will fail → parent should check `acli` availability before spawning agents

## Performance Expectations

- **[FACT]** Each agent processes one Epic independently
- **[FACT]** 5 agents running in parallel should complete in 3-5 minutes (same as 1 agent)
- **[INFERRED]** Token usage per agent: 5,000-8,000 tokens (depends on Epic size)
- **[INFERRED]** Agents can be retried individually without affecting other Epics
