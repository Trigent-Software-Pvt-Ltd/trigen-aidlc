---
name: create-mr
description: "Create a GitLab merge request for the current branch"
allowed-tools: [mcp__gitlab__create_merge_request, mcp__gitlab__get_merge_request, mcp__gitlab__list_commits, mcp__gitlab__get_branch_diffs, mcp__gitlab__get_project, Bash, AskUserQuestion]
argument-hint: "[target_branch]"
---

Create a GitLab merge request for the current branch. Follow these steps:

1. **Get Current Branch**: Run `git branch --show-current` to get the current branch name.

2. **Check for Existing MR**: Use `get_merge_request` with the source branch to check if an MR already exists. If it does, report the existing MR URL and ask if the user wants to update it.

3. **Determine Target Branch**:
   - If $ARGUMENTS specifies a target branch, use that
   - Otherwise, default to the repository's main branch (usually `main` or `dev`)

4. **Gather Commit Information**: Use `list_commits` to get the commits on this branch that will be included in the MR.

5. **Get Diff Summary**: Use `get_branch_diffs` to understand the scope of changes.

6. **Prepare MR Details**:
   - **Title**: Generate from the branch name or first commit message
   - **Description**: Create a summary including:
     - Overview of changes
     - List of key commits
     - Any relevant context

7. **Create the MR**: Use `create_merge_request` with:
   - `source_branch`: Current branch
   - `target_branch`: From step 3
   - `title`: Concise, descriptive title
   - `description`: Formatted description with summary

8. **Report Success**: Display the MR URL and key details.

## Description Format

```markdown
## Summary
[Brief description of changes]

## Changes
- [Key change 1]
- [Key change 2]

## Test plan
- [ ] [Testing step 1]
- [ ] [Testing step 2]
```

## Guidelines

- Keep titles under 72 characters
- Use imperative mood in titles ("Add feature" not "Added feature")
- Include relevant ticket references if branch name contains them (e.g., PROJ-123)
- Don't mark as draft unless explicitly requested
