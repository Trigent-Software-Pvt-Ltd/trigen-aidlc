# GitLab Backend Reference

This document defines GitLab-specific operations for the AIDLC workflow using local `.md` files in the `ai-dlc-docs` repository.

## Repository Setup

**Repository URL:** `<GITLAB_DOCS_REPO_URL>` (from `aidlc.config.yaml`; run `/aidlc-init`)

**SSH URL:** `<GITLAB_DOCS_REPO_SSH>`

### Local Clone Location

The AIDLC docs repository location can be configured in two ways:

1. **Environment Variable** (recommended): Set `AIDLC_DOCS_PATH` to your local clone path
   ```bash
   export AIDLC_DOCS_PATH="$HOME/Projects/ai-dlc-docs"
   # Add to ~/.bashrc, ~/.zshrc, or equivalent for persistence
   ```

2. **Runtime Prompt**: If `AIDLC_DOCS_PATH` is not set, ask the user:
   > "Where is the ai-dlc-docs repository cloned on your machine? (e.g., ~/Projects/ai-dlc-docs)"

**Default suggestion**: `~/Projects/ai-dlc-docs`

### Prerequisites Check

Before starting any GitLab-based workflow:

```bash
# 1. Verify glab CLI is installed
glab --version

# 2. Check if AIDLC_DOCS_PATH is set, otherwise prompt user
if [ -z "$AIDLC_DOCS_PATH" ]; then
  echo "AIDLC_DOCS_PATH not set. Please provide the path to ai-dlc-docs repository:"
  read -r AIDLC_DOCS_PATH
fi

# 3. Verify git repo is cloned and accessible
cd "$AIDLC_DOCS_PATH" && git status

# 4. Ensure on main branch and up to date
git checkout main && git pull origin main
```

## Directory Structure

```
ai-dlc-docs/
└── Projects/
    └── <Project Name>/
        └── Feature <N> - <Title>/
            ├── intent.md
            ├── sprint-plan.md
            ├── design/
            │   ├── domain-model.md
            │   └── architecture.md
            └── epics/
                └── <Epic Name>/
                    ├── epic.md
                    ├── tasks/
                    │   ├── task-1.md
                    │   └── task-2.md
                    └── adrs/
                        └── adr-001.md
```

## Branch Naming Convention

```
intent/<project-slug>/<intent-slug>
```

Examples:
- `intent/my-project/auth-overhaul`
- `intent/platform-services/api-versioning`
- `intent/mobile-app/offline-sync`

## Workflow: New Feature

### Step 1: Create Branch

```bash
cd ~/Projects/ai-dlc-docs
git checkout main
git pull origin main
git checkout -b "intent/<project-slug>/<intent-slug>"
```

### Step 2: Create Directory Structure

```bash
mkdir -p "Projects/<Project Name>/Feature <N> - <Title>"
mkdir -p "Projects/<Project Name>/Feature <N> - <Title>/epics"
mkdir -p "Projects/<Project Name>/Feature <N> - <Title>/design"
```

Note: Task and ADR directories are created per-epic during elaboration.

### Step 3: Write intent.md

Use the Write tool to create the intent.md file (the Feature document) with YAML frontmatter.

### Step 4: Commit and Push

```bash
git add .
git commit -m "feat(intent): Create Feature <N> - <Title>"
git push -u origin "intent/<project-slug>/<intent-slug>"
```

### Step 5: Create Draft MR

```bash
glab mr create \
  --draft \
  --title "[Feature <N>] <Title>" \
  --description "## Feature Overview

<Brief description>

## Status
- [ ] Feature documented
- [ ] Elaboration complete
- [ ] Design complete
- [ ] Verification passed
- [ ] Ready for implementation" \
  --source-branch "intent/<project-slug>/<intent-slug>" \
  --target-branch main
```

### Step 6: Get MR URL

```bash
glab mr view --web  # Opens in browser
# or
glab mr list --source-branch "intent/<project-slug>/<intent-slug>"
```

## Workflow: Elaborate

Elaborate creates epic files only. Task files are created during the design phase.

### Step 1: Checkout Branch

```bash
cd ~/Projects/ai-dlc-docs
git checkout "intent/<project-slug>/<intent-slug>"
git pull origin "intent/<project-slug>/<intent-slug>"
```

### Step 2: Create Epic Directories and Files

For each epic, create a directory structure:

```bash
mkdir -p "Projects/<Project Name>/Feature <N> - <Title>/epics/<Epic Name>/tasks"
mkdir -p "Projects/<Project Name>/Feature <N> - <Title>/epics/<Epic Name>/adrs"
```

Use the Write tool to create:
- `epics/<Epic Name>/epic.md` - Epic overview with not-in-scope and open questions
- `epics/<Epic Name>/adrs/adr-NNN.md` - ADRs specific to this epic (if needed)

Do NOT create task files during elaborate — they are created during design.

### Step 3: Commit and Push

```bash
git add .
git commit -m "feat(elaborate): Add Epics for Feature <N>"
git push
```

## Workflow: Design

Design creates task files (Task Specification format) within each epic's tasks/ directory.

### Step 1: Checkout Branch

```bash
cd ~/Projects/ai-dlc-docs
git checkout "intent/<project-slug>/<intent-slug>"
git pull origin "intent/<project-slug>/<intent-slug>"
```

### Step 2: Create Task Spec Files

For each Task Specification, use the Write tool to create:
- `epics/<Epic Name>/tasks/task-UNN-TNN-<slug>.md` - Task Spec file

Use the Task Spec frontmatter format (see Templates section).

### Step 3: Commit and Push

```bash
git add .
git commit -m "feat(design): Add Task Specifications for Feature <N>"
git push
```

### Step 5: Fetch MR Comments for Review

```bash
# Get MR ID
MR_ID=$(glab mr list --source-branch "intent/<project-slug>/<intent-slug>" --json id -q '.[0].iid')

# View comments
glab mr view $MR_ID --comments
```

## Workflow: Verify

### Step 1: Read All Files

Use the Read tool to read all `.md` files in the Feature directory for verification.

### Step 2: Run doc-verifier

Spawn the doc-verifier subagent with GitLab-sourced content.

### Step 3: Transfer to Jira

After verification passes, use the task-creator subagent to create Jira artifacts.

### Step 4: Update Frontmatter with Jira Keys

Update each `.md` file's frontmatter with the corresponding Jira key.

### Step 5: Mark MR Ready

```bash
MR_ID=$(glab mr list --source-branch "intent/<project-slug>/<intent-slug>" --json id -q '.[0].iid')
glab mr update $MR_ID --ready
```

### Step 6: Final Commit

```bash
git add .
git commit -m "feat(verify): Add Jira keys and mark ready for merge"
git push
```

## Templates

### intent.md

```yaml
---
backend: gitlab
type: feature
project: "<Project Name>"
feature_number: 1
title: "<Feature Title>"
status: draft
created: YYYY-MM-DD
jira_project_key: null
mr_url: "<MR URL>"
---

# Feature <N> - <Title>

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

## Workflow Status

| Phase | Status | Date | Notes |
|-------|--------|------|-------|
| Feature | Draft | <date> | MR !<ID> |
| Elaborate | Pending | - | - |
| Design | Pending | - | - |
| Verify | Pending | - | - |
```

### epics/<Epic Name>/epic.md

```yaml
---
backend: gitlab
type: epic
epic_number: 1
title: "<Epic Title>"
status: draft
jira_key: null
---

# Epic NN: <Title>

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
```

### epics/<Epic Name>/tasks/task-UNN-TNN-slug.md

Task files use Task Specification format: YAML frontmatter for structured fields, markdown body for natural language sections.

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
    - tests/path/to/Tests.cs
  reference:
    - src/path/to/pattern.cs
dependencies:
  - on: "<what this depends on>"
    type: blocking
    environment: deploy
    rationale: "<why>"
backend: gitlab
type: task
epic_number: 1
status: draft
jira_key: null
---

## Behaviour

- <Observable outcome 1>
- <Observable outcome 2>

## Rules

- <Hard constraint>

## Risks

- <Risk> — mitigate: <mitigation>

## Not in Scope

- <Explicit boundary>
```

Omit `files`, `dependencies` frontmatter keys and `## Rules`, `## Risks`, `## Not in Scope` body sections when they have no content.

### sprint-plan.md

```yaml
---
backend: gitlab
type: sprint_plan
feature_number: 1
---

# Sprint Plan - Feature <N>

## Overview

Implementation plan organized into rapid iteration cycles (Sprints). Each Sprint represents a cohesive set of work that can be completed in 1-3 days.

## Sprint Sequence

### Sprint 1: <Sprint Name>

**Goal:** <High-level objective>

**Epics/Tasks:**
- Epic: <Epic Name>
  - task-1: <Task description>
  - task-2: <Task description>

**Acceptance Criteria:**
- [ ] <Criterion 1>
- [ ] <Criterion 2>

**Dependencies:** None / Sprint <N>

**Risk Mitigation:** <Any specific risks for this sprint>

### Sprint 2: <Sprint Name>

**Goal:** <High-level objective>

**Epics/Tasks:**
- Epic: <Epic Name>
  - task-1: <Task description>

**Acceptance Criteria:**
- [ ] <Criterion 1>

**Dependencies:** Sprint 1

**Risk Mitigation:** <Any specific risks for this sprint>

## Dependencies Graph

```
Sprint 1 ──► Sprint 2 ──► Sprint 4
            │
            ▼
           Sprint 3
```
```

### domain-model.md

```yaml
---
backend: gitlab
type: design
design_type: domain_model
feature_number: 1
---

# Domain Model - Feature <N>

## Entities

### <Entity Name>

| Attribute | Type | Description |
|-----------|------|-------------|
| id | UUID | Unique identifier |
| <attr> | <type> | <description> |

## Relationships

<Entity A> ──1:N──► <Entity B>
```

### epics/<Epic Name>/adrs/adr-NNN.md

```yaml
---
backend: gitlab
type: adr
adr_number: 1
title: "<ADR Title>"
status: proposed
date: YYYY-MM-DD
deciders: ["<Person 1>", "<Person 2>"]
---

# ADR 001: <Title>

## Status

Proposed

## Context

<What is the issue that we're seeing that motivates this decision?>

## Decision

<What is the change that we're proposing and/or doing?>

## Consequences

### Positive

- <Good outcome 1>

### Negative

- <Trade-off 1>

### Neutral

- <Observation 1>
```

## glab CLI Reference

| Command | Purpose |
|---------|---------|
| `glab mr create --draft` | Create draft MR |
| `glab mr view <ID> --comments` | View MR with comments |
| `glab mr update <ID> --ready` | Mark MR ready for review |
| `glab mr list --source-branch <branch>` | Find MR by branch |
| `glab mr merge <ID>` | Merge MR |
| `glab mr note <ID> -m "<comment>"` | Add comment to MR |

## Reading Files for Verification

When reading GitLab backend files for doc-verifier:

```typescript
interface VerificationInput {
  type: 'feature' | 'epic' | 'story' | 'task' | 'design' | 'adr';
  backend: 'gitlab';
  id: string;              // File path relative to Feature directory
  title: string;           // From frontmatter
  bodyMarkdown: string;    // File content after frontmatter
  metadata: {
    frontmatter: object;   // Parsed YAML frontmatter
    filePath: string;      // Full file path
    gitBranch: string;     // Current branch
  };
}
```
