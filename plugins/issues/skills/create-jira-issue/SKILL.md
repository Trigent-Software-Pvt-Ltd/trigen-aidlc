---
name: create-jira-issue
description: "Create a new Jira issue from the current context or description"
allowed-tools: [mcp__atlassian__createJiraIssue, mcp__atlassian__getVisibleJiraProjects, mcp__atlassian__getJiraProjectIssueTypesMetadata, mcp__atlassian__getAccessibleAtlassianResources, mcp__atlassian__lookupJiraAccountId, AskUserQuestion]
argument-hint: "<description or context>"
---

Create a new Jira issue based on the provided context. Follow these steps:

1. **Gather Context**: Use the provided arguments ($ARGUMENTS) to understand what issue needs to be created. If the context is unclear, ask for clarification.

2. **Get Atlassian Resources**: Use `getAccessibleAtlassianResources` to get the cloud ID for the Jira instance.

3. **Find the Project**: Use `getVisibleJiraProjects` to list available projects. If the user hasn't specified a project, ask them to select one.

4. **Get Issue Types**: Use `getJiraProjectIssueTypesMetadata` to get available issue types for the selected project.

5. **Prepare Issue Details**:
   - **Summary**: Create a concise, descriptive title (max 255 chars)
   - **Description**: Format the description in Markdown with clear sections
   - **Issue Type**: Default to "Task" unless the context suggests otherwise (Bug, Story, etc.)

6. **Create the Issue**: Use `createJiraIssue` with:
   - `cloudId`: From step 2
   - `projectKey`: From selected project
   - `issueTypeName`: Appropriate type
   - `summary`: Concise title
   - `description`: Detailed description in Markdown

7. **Report Success**: Display the created issue key and URL to the user.

## Guidelines

- Keep summaries action-oriented and specific
- Include relevant code references in the description when applicable
- Ask for missing required information rather than guessing
- If creating from a code context, include file paths and line numbers
- Use appropriate issue types: Bug (defects), Story (features), Task (work items)
