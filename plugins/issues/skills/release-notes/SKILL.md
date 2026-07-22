---
name: release-notes
description: Compose release notes by analyzing commits since the last tag, looking up GitLab MRs and Jira issues, and categorizing changes into features, bugfixes, and other changes. Use when preparing release notes or changelogs.
---

# Release Notes

Compose release notes by analyzing commits since the latest tag, cross-referencing with GitLab MRs and Jira issues.

## Prerequisites

- Atlassian MCP for fetching Jira ticket context
- GitLab MCP for fetching MR details
- Git access to origin/master and origin/main branches

## Instructions

### Step 1: Find the Latest Tag

Run these commands:
- git fetch --tags
- git describe --tags --abbrev=0

Store the result as LATEST_TAG.

### Step 2: Fetch Remote Branches

Run: git fetch origin master main

### Step 3: Get Commits Since Last Tag

Get merge commits from both branches:

From origin/main since the tag:
  git log LATEST_TAG..origin/main --merges --pretty=format:"%H|%s" --first-parent

From origin/master since the tag (these are hotfixes, already released):
  git log LATEST_TAG..origin/master --merges --pretty=format:"%H|%s" --first-parent

### Step 4: Exclude Already-Released Hotfixes

IMPORTANT: Commits in origin/master are hotfixes that have already been released. These must be excluded entirely from the release notes.

1. Collect all commit messages from origin/master (the hotfixes)
2. Remove any commits from origin/main that have identical messages to the hotfixes
3. Only the remaining origin/main commits should be included in release notes

This ensures we don't duplicate changes that were already released as hotfixes.

### Step 5: Extract MR Information from Merge Commits

For each merge commit, extract the MR IID from the commit message:

- GitLab merge commits typically have format: Merge branch 'branch-name' into 'main'
- Or: See merge request trigent1/trigent/cpoms/cpoms!1234

Extract the MR IID (the number after the exclamation mark).

### Step 6: Look Up GitLab MRs

For each merge commit, fetch the MR details using GitLab MCP:

  mcp__gitlab__get_merge_request with:
  - project_id: trigent1/trigent/cpoms/cpoms
  - merge_request_iid: the MR IID

This returns:
- title: MR title (often contains Jira key like AI-1234 Feature name)
- description: MR description (may contain Jira references)
- source_branch: Branch name (fallback for Jira key)

### Step 7: Extract Jira Issue Keys (Priority Order)

Extract Jira issue keys in this priority order:

1. MR Title - Look for pattern like XX-\d+ in the title (highest priority)
2. MR Description - Search for XX-\d+ patterns in the description
3. Source Branch - Extract from branch name like XX-1234-feature-name (fallback)

Use the first match found. Do NOT assume any key is invalid - always look up every key found to verify it exists.

### Step 8: Look Up Jira Issues (Use Subagent)

IMPORTANT: To avoid context bloat, use the Task tool with a subagent to look up Jira issues.

For each unique Jira issue key, spawn a subagent with subagent_type "general-purpose" and prompt:

  Look up Jira issue ISSUE_KEY using the Atlassian MCP tool.
  Use mcp__atlassian__getJiraIssue with cloudId 7c795d89-53db-46c0-896a-d6333239676d and issueIdOrKey set to the issue key.
  Return ONLY these fields in this exact format:
  KEY: issue key
  TYPE: issue type name (Story, Bug, Chore, Spike, etc.)
  TITLE: summary/title
  DESCRIPTION: first 200 chars of description, or No description

You can run multiple subagents in parallel for efficiency.

### Step 9: Categorize Changes

Group issues by their Jira issue type, but use judgement for items without Jira links:

- Features: Story issue type, OR any change that adds new functionality (e.g., new API endpoints, new UI features)
- Bugfixes: Bug issue type - Defect fixes, corrections
- Other Changes: Chore, Spike, Task, internal tooling, documentation, dev workflow improvements

### Step 10: Format Release Notes

Generate markdown with this structure, wrapped in a code block (```markdown) so it renders correctly:

```markdown
## Release Notes - VERSION/TAG

### Features
- Jira issue title here [[AI-1234](https://trigent1.atlassian.net/browse/AI-1234)]

### Bugfixes
- Jira issue title here [[AR-1236](https://trigent1.atlassian.net/browse/AR-1236)]

### Other Changes
- Jira issue title here [[AR-1237](https://trigent1.atlassian.net/browse/AR-1237)]
- MR title here [`branch-name` (!1234)]
```

## Formatting Guidelines

- **Use Jira titles directly**: Don't heavily rewrite issue names. Use the Jira title as-is or with minimal tweaks for clarity.
- **Link at end**: Put the linked issue key at the end in double brackets: `Title [[AI-1234](url)]`
- **No Jira link**: If an MR has no associated Jira issue (or the key doesn't exist), use branch name + MR number at the end (no link): `MR title [`branch-name` (!1234)]`
- **Deduplicate**: If multiple MRs reference the same Jira issue, combine them into one bullet

## Data Sources Priority

When composing the release note text for each item:

1. Jira issue title - Use directly, avoid rewriting unless unclear
2. MR title - Use as fallback if no Jira issue, or to clarify if Jira title is vague
3. Jira issue type - Use for categorization (Story → Features, Bug → Bugfixes, etc.)

## Tips

- Run Jira lookups in parallel (up to 5 at a time) to speed up the process
- Always verify Jira keys exist - never assume a key is invalid based on prefix
- Skip automated/bot commits (version bumps, CI updates) unless significant
- Group related small changes when they share a theme
