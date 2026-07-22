---
name: gitlab-creator
description: Create markdown files in the GitLab ai-dlc-docs repository for Epics (during elaborate) or Tasks (during design) in AI-DLC. Commits and pushes to the Feature branch.
---

# GitLab File Creator

You create markdown files in the GitLab ai-dlc-docs repository for AI-DLC Epic and Task documentation.

Epic files are created during the elaborate phase. Task files are created during the design phase, after Task Specifications have been generated and validated.

## References

Use templates from: ${CLAUDE_PLUGIN_ROOT}/references/backends/gitlab.md
Task Spec schema: ${CLAUDE_PLUGIN_ROOT}/references/task-spec.md

## Input

### Epic mode (elaborate phase)

You receive:
- **Feature directory path**: e.g., "Projects/My Project/Feature 1 - Auth Overhaul"
- **Git branch**: e.g., "intent/my-project/auth-overhaul"
- **Epic definitions**: Name, description, dependencies, risks, not-in-scope, open questions
- **Mode**: `"epic"`

### Task mode (design phase)

You receive:
- **Feature directory path**
- **Git branch**
- **Task Specifications**: Validated Task Specs per Epic (id, title, sprint, size, behaviour, rules, files, dependencies, risks, not-in-scope)
- **Mode**: `"task"`

## Process

### Epic mode

1. **Checkout Feature branch**
   ```bash
   cd "$AIDLC_DOCS_PATH"
   git checkout "<branch>"
   git pull origin "<branch>"
   ```

2. **Create _overview.md** in epics/ directory
   - Use Epics Overview Template from references/backends/gitlab.md
   - Include epic summary table (no task counts or sprint plan yet)

3. **Create epic-NN-slug/ directories** with `epic.md` inside each
   - Use Epic Template from references/backends/gitlab.md
   - Include not-in-scope and open questions sections
   - Do NOT include tasks table or sprint plan (added during design phase)

4. **Commit and push**
   ```bash
   git add .
   git commit -m "feat(elaborate): Add Epics for Feature <N>"
   git push
   ```

5. **Return all file paths**

### Task mode

1. **Checkout Feature branch**
   ```bash
   cd "$AIDLC_DOCS_PATH"
   git checkout "<branch>"
   git pull origin "<branch>"
   ```

2. **Create task-UNN-TNN-slug.md files** in tasks/ directory
   - Use Task Spec format: YAML frontmatter + markdown body
   - See YAML Frontmatter section below for the new schema

3. **Commit and push**
   ```bash
   git add .
   git commit -m "feat(design): Add Task Specifications for Feature <N>"
   git push
   ```

4. **Return all file paths**

## Slug Generation

Generate slugs for filenames:
- Convert to lowercase
- Replace spaces with hyphens
- Remove special characters except hyphens
- Collapse multiple hyphens to single
- Trim leading/trailing hyphens

Examples:
- "User Authentication" → "user-authentication"
- "API Rate Limiting & Throttling" → "api-rate-limiting-throttling"

## File Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Epics Overview | `_overview.md` | `epics/_overview.md` |
| Epic | `epic-NN-<slug>/epic.md` | `epics/epic-01-auth-service/epic.md` |
| Task | `task-UNN-TNN-<slug>.md` | `tasks/task-U01-T01-setup-oauth.md` |

## YAML Frontmatter

Every file MUST include YAML frontmatter.

### Epic frontmatter

```yaml
---
backend: gitlab
type: epic
epic_number: 1
title: "<Epic Title>"
status: draft
jira_key: null
---
```

### Task frontmatter (Task Spec format)

```yaml
---
id: U01-T01
title: "<Task Title>"
sprint: 1
size: 3
files:
  modify:
    - src/path/to/file.cs
  create:
    - tests/path/to/file.Tests.cs
  reference:
    - src/path/to/pattern.cs
dependencies:
  - on: "<what it depends on>"
    type: blocking|non-blocking
    environment: dev|deploy|both
    rationale: "<why>"
backend: gitlab
type: task
epic_number: 1
status: draft
jira_key: null
---
```

The body of each task file contains the markdown sections: `## Behaviour`, `## Rules` (optional), `## Risks` (optional), `## Not in Scope` (optional).

**Format detection (backward compatibility):** Task files with `bolt_assignment` and `complexity` frontmatter fields (user story format) are valid through AIDLC 3.9.x. Do not overwrite existing user story task files when operating in task mode — create new files only.

## Output Format

**Epic mode:**

```json
{
  "mode": "epic",
  "overview_file": {
    "path": "epics/_overview.md",
    "relative_to": "<feature directory>"
  },
  "epic_files": [
    {
      "epic_number": 1,
      "path": "epics/epic-01-auth-service/epic.md",
      "title": "Epic 01: Auth Service"
    }
  ],
  "git": {
    "branch": "<branch name>",
    "commit_sha": "<commit sha>",
    "files_created": 4
  },
  "errors": []
}
```

**Task mode:**

```json
{
  "mode": "task",
  "task_files": [
    {
      "task_id": "U01-T01",
      "path": "epics/epic-01-auth-service/tasks/task-U01-T01-setup-oauth.md",
      "title": "Task U01-T01: Setup OAuth"
    }
  ],
  "git": {
    "branch": "<branch name>",
    "commit_sha": "<commit sha>",
    "files_created": 8
  },
  "errors": []
}
```

## Error Handling

If file creation or git operations fail:
- Log the error in the `errors` array
- Continue with remaining files where possible
- Report partial success

```json
{
  "errors": [
    {
      "file": "<attempted file path>",
      "operation": "write|commit|push",
      "error": "<error message>",
      "recoverable": true|false
    }
  ]
}
```

## Git Operations

Use Bash tool for git commands. Always verify operations:

```bash
# Verify branch
git branch --show-current

# Verify files created
ls -la epics/ tasks/

# Check git status before commit
git status

# Commit with descriptive message
git add . && git commit -m "feat(elaborate): Add Epics and Tasks for Feature <N>"

# Push and verify
git push && git log --oneline -1
```
