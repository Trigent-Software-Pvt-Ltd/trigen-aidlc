# Confluence Backend Reference

This document defines Confluence-specific operations for the AIDLC workflow using Confluence pages with Jira integration.

## Overview

The Confluence backend stores documentation as Confluence pages and uses Jira for work tracking. This is the original AIDLC backend.

## AIDLC → Confluence/Jira Mapping

| AIDLC Concept | Confluence Object | Jira Object |
|---------------|-------------------|-------------|
| Project | Space or parent page | Jira Project |
| Feature | Confluence page | Feature |
| Epic | Child page under Feature | Epic |
| Task | Child page under Epic | Task |
| Sprint | Grouping in Epics Overview | Sprint (groups Tasks) |

## Prerequisites

### Atlassian MCP Tools

Required tools:
- `getAccessibleAtlassianResources` - Get cloud ID
- `getConfluenceSpaces` - List spaces
- `getConfluencePage` - Read page content
- `createConfluencePage` - Create new page
- `updateConfluencePage` - Update existing page
- `searchConfluenceUsingCql` - Search for pages

### Jira Tools (for `/aidlc-verify`)

- `getVisibleJiraProjects` - List projects
- `createJiraIssue` - Create issues
- `searchJiraIssuesUsingJql` - Search issues

### acli CLI (Alternative)

When MCP tools are unreliable, use the Atlassian CLI:

```bash
# Get page content
acli confluence --action getPageSource --space "<SPACE>" --title "<Title>"

# Create page
acli confluence --action addPage --space "<SPACE>" --title "<Title>" --parent "<Parent Title>" --content "<HTML content>"

# Update page
acli confluence --action storePage --space "<SPACE>" --title "<Title>" --content "<HTML content>"
```

## Page Hierarchy

```
<Space Root>
└── <Project Name>
    └── Feature 1: <Title>
        ├── Epics Overview
        │   └── Epic 01: <Title>
        │       └── Task U01-T01: <Title>
        │       └── Task U01-T02: <Title>
        │   └── Epic 02: <Title>
        │       └── Task U02-T01: <Title>
        ├── Design
        │   ├── Domain Model
        │   └── Logical Design
        └── ADRs
            └── ADR 001: <Title>
```

## Workflow: New Feature

### Step 1: Get Cloud ID

```
getAccessibleAtlassianResources()
```

### Step 2: Find or Create Space/Project Page

```
getConfluenceSpaces(cloudId: "<cloud ID>", keys: ["<CONFLUENCE_SPACE_KEY>"])
```

Or search for existing project page:

```
searchConfluenceUsingCql(
  cloudId: "<cloud ID>",
  cql: "title = '<Project Name>' AND type = page AND space = '<CONFLUENCE_SPACE_KEY>'"
)
```

### Step 3: Create Feature Page

```
createConfluencePage(
  cloudId: "<cloud ID>",
  spaceId: "<space ID>",
  parentId: "<project page ID>",
  title: "Feature <N>: <Title>",
  body: "<markdown content>",
  contentFormat: "markdown"
)
```

### Step 4: Store Page Reference

```typescript
BackendContext.featurePageId = "<returned page ID>"
```

## Workflow: Elaborate

Elaborate creates Epics Overview and Epic pages. Task pages are created during the design phase.

### Step 1: Create Epics Overview Page

```
createConfluencePage(
  cloudId: "<cloud ID>",
  spaceId: "<space ID>",
  parentId: "<feature page ID>",
  title: "Epics Overview",
  body: "<epics overview markdown>",
  contentFormat: "markdown"
)
```

### Step 2: Create Epic Pages

For each Epic:

```
createConfluencePage(
  cloudId: "<cloud ID>",
  spaceId: "<space ID>",
  parentId: "<epics overview page ID>",
  title: "Epic <NN>: <Title>",
  body: "<epic markdown — problem statement, target users, scope (in/out), success metrics, ACs, indicative tasks with t-shirt sizes, dependencies, open questions>",
  contentFormat: "markdown"
)
```

## Workflow: Design

Design creates Task pages (Task Specification format) as children of Epic pages.

### Step 1: Create Task Pages

For each Task Specification:

```
createConfluencePage(
  cloudId: "<cloud ID>",
  spaceId: "<space ID>",
  parentId: "<epic page ID>",
  title: "Task <id>: <title>",
  body: "<task spec markdown>",
  contentFormat: "markdown"
)
```

### Step 2: Update Epic Page with Sprint Plan

After all Task Specification pages are created, update the Epic page to add the confirmed Sprint Plan section:

```
updateConfluencePage(
  cloudId: "<cloud ID>",
  pageId: "<epic page ID>",
  body: "<updated epic markdown — appends confirmed Sprint Plan table from /aidlc-design; indicative tasks remain>",
  contentFormat: "markdown"
)
```

## Workflow: Verify

### Step 1: Read All Pages

Use `getConfluencePage` to read each page in the hierarchy.

### Step 2: Run doc-verifier

Spawn the doc-verifier subagent with Confluence-sourced content.

### Step 3: Transfer to Jira

Use the task-creator subagent to create Jira artifacts:

1. Create Epic for each Epic
2. Create Sprint for each Sprint
3. Create Task for each Task under the appropriate Sprint

### Step 4: Update Pages with Jira Keys

Update each Confluence page to include the Jira issue key:

```
updateConfluencePage(
  cloudId: "<cloud ID>",
  pageId: "<page ID>",
  body: "<updated markdown with Jira key>",
  contentFormat: "markdown"
)
```

## Templates

### Feature Page

```markdown
# Feature <N>: <Title>

| Field | Value |
|-------|-------|
| Status | Draft |
| Created | <date> |
| Jira Project | <KEY> |

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
| Feature | Draft | <date> | - |
| Elaborate | Pending | - | - |
| Design | Pending | - | - |
| Verify | Pending | - | - |
```

### Epics Overview Page

```markdown
# Epics Overview - Feature <N>

## Epic Summary

| Epic | Title | Tasks | Complexity | Jira Key |
|------|-------|-------|------------|----------|
| U01 | <Title> | 3 | M | - |
| U02 | <Title> | 5 | L | - |

## Sprint Assignments

| Sprint | Epics | Est. Effort | Jira Sprint |
|------|-------|-------------|------------|
| Sprint 1 | U01, U02 | 2-3 days | - |
| Sprint 2 | U03 | 1-2 days | - |

## Dependencies

```
U01 ──► U02 ──► U04
         │
         ▼
        U03
```
```

### Epic Page

```markdown
# Epic <NN>: <Title>

| Field | Value |
|-------|-------|
| Status | Draft |
| Jira Key | - |

## Purpose

<What this epic accomplishes>

## Scope

<What's included and excluded>

## Tasks

| Task | Title | Complexity | Sprint | Jira Key |
|------|-------|------------|------|----------|
| T01 | <Task title> | M | Sprint 1 | - |
| T02 | <Task title> | S | Sprint 1 | - |

## Dependencies

- <Dependencies on other epics or external systems>

## Acceptance Criteria

- [ ] <Criterion 1>
- [ ] <Criterion 2>
```

### Task Page

```markdown
# Task <id>: <Title>

| Field | Value |
|-------|-------|
| Task ID | <id, e.g. U01-T03> |
| Size | <size> (Fibonacci) |
| Sprint | <sprint id> |
| Jira Key | - |

## Behaviour

- [ ] <Observable outcome 1>
- [ ] <Observable outcome 2>

## Rules

- <Hard constraint derived from NFR or design decision>

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
```

Omit `Rules`, `Files`, `Dependencies`, `Risks`, and `Not in Scope` sections when they have no content.

## Jira Hierarchy for Transfer

When transferring to Jira via `/aidlc-verify`:

```
Jira Project
└── Epic (Epic)
    └── Task (Task)
```

> Sprint groups Stories/Tasks for scheduling; it is not a hierarchy level.

### Issue Type Mapping

| AIDLC Type | Jira Issue Type |
|------------|-----------------|
| Epic | Epic |
| Sprint | Sprint |
| Task | Task |

### Story Points Mapping

Task Spec `size` maps directly to Jira story points:

| Task Spec size | Jira Story Points |
|----------------|-------------------|
| 1 | 1 |
| 2 | 2 |
| 3 | 3 |
| 5 | 5 |
| 8 | 8 |
| 13 | 13 |

## CQL Queries

### Find Feature Page

```
title ~ "Feature" AND ancestor = "<project page ID>" AND type = page
```

### Find Epics Under Feature

```
ancestor = "<feature page ID>" AND title ~ "Epic" AND type = page
```

### Find Tasks Under Epic

```
ancestor = "<epic page ID>" AND title ~ "Task U" AND type = page
```

## Reading Content for Verification

When reading Confluence backend content for doc-verifier:

```typescript
interface VerificationInput {
  type: 'feature' | 'epic' | 'story' | 'task' | 'design' | 'adr';
  backend: 'confluence';
  id: string;              // Confluence page ID
  title: string;           // Page title
  bodyMarkdown: string;    // Page content (converted to markdown)
  metadata: {
    pageId: string;        // Confluence page ID
    spaceKey: string;      // Space key
    pageUrl: string;       // Web URL
    parentPageId?: string; // Parent page ID
    jiraKey?: string;      // Associated Jira key if any
  };
}
```

## Error Handling

### Common Atlassian MCP Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `cloud_id not found` | Missing cloud ID | Call `getAccessibleAtlassianResources` first |
| `page not found` | Invalid page ID | Search for page using CQL |
| `permission denied` | No access to space | Request access or use different space |
| `rate limited` | Too many API calls | Wait and retry with backoff |

### Fallback to acli

If MCP tools fail repeatedly, suggest using acli CLI:

```bash
# Install acli if needed
brew install acli

# Configure credentials
acli configure

# Use CLI instead of MCP
acli confluence --action getPageSource --space "<SPACE>" --title "<Title>"
```

## Comments and Review

### Add Page Comment

```
createConfluenceFooterComment(
  cloudId: "<cloud ID>",
  pageId: "<page ID>",
  body: "## Review Feedback\n\n<feedback markdown>"
)
```

### Add Inline Comment

```
createConfluenceInlineComment(
  cloudId: "<cloud ID>",
  pageId: "<page ID>",
  body: "<feedback>",
  inlineCommentProperties: {
    textSelection: "<text to highlight>",
    textSelectionMatchCount: 1,
    textSelectionMatchIndex: 0
  }
)
```

### Read Comments

```
getConfluencePageFooterComments(
  cloudId: "<cloud ID>",
  pageId: "<page ID>"
)

getConfluencePageInlineComments(
  cloudId: "<cloud ID>",
  pageId: "<page ID>"
)
```
