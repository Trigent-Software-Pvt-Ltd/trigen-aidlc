---
name: sentry-action
description: "Execute a triage action for a Sentry issue: archive with rationale and configurable reopen trigger, create Jira ticket, link existing Jira ticket (with bidirectional Sentry-Jira linking), escalate to Slack, send to Automaton, or get diagnostic suggestions. This skill is chained from /sentry-analyze — do not invoke it directly. (Triggers: sentry-action)"
allowed-tools: [Bash, mcp__claude_ai_Slack__slack_send_message_draft, mcp__claude_ai_Slack__slack_search_channels, mcp__claude_ai_Slack__slack_search_users, mcp__claude_ai_Slack__slack_read_user_profile, mcp__atlassian__createJiraIssue, mcp__atlassian__getVisibleJiraProjects, mcp__atlassian__getJiraProjectIssueTypesMetadata, mcp__atlassian__addCommentToJiraIssue, mcp__atlassian__getJiraIssue, mcp__claude_ai_Atlassian__createJiraIssue, mcp__claude_ai_Atlassian__getVisibleJiraProjects, mcp__claude_ai_Atlassian__getJiraProjectIssueTypesMetadata, mcp__claude_ai_Atlassian__addCommentToJiraIssue, mcp__claude_ai_Atlassian__getJiraIssue, AskUserQuestion]
argument-hint: "(chained from /sentry-analyze with context and selected action)"
---

# Sentry Triage — Step 3: Execute Action

This is the final skill in the triage chain:
1. **`/sentry-triage`** — Gather data from Sentry and Slack
2. **`/sentry-analyze`** — Deep analysis, severity classification, action selection
3. **`/sentry-action`** (you are here) — Execute the chosen action

Parse the YAML context block from `$ARGUMENTS` which includes: selected_action, full issue details (including `sentry_numeric_id`, `sentry_org_slug`, and `project` slug), analysis results (severity, hypothesis, pattern, trend, infrastructure), jira_mode, jira_mcp_prefix, existing_jira_ticket, sentry_cli_mode, repo_context, slack_available, and slack_findings. Work from this context without re-fetching. Use `jira_mode` to determine how to interact with Jira: `acli` (preferred CLI), `mcp` (use the prefix in `jira_mcp_prefix`), or `unavailable` (present manual instructions). Use `sentry_cli_mode` to determine whether archive and Sentry-side Jira links can be automated: `available` (use the CLI / REST recipes in @${CLAUDE_PLUGIN_ROOT}/references/sentry-cli-integration.md) or `unavailable` (fall back to manual instructions). If `sentry_cli_mode` is absent from the YAML (e.g., the skill was invoked directly without going through `/sentry-analyze`), treat it as `unavailable`.

## MCP Tool Note

Tool names vary by installation. This skill references `mcp__claude_ai_Slack__*` and `mcp__atlassian__*` / `mcp__claude_ai_Atlassian__*` (both Atlassian prefixes are listed in allowed-tools). If an Atlassian call fails with "unknown tool", try the other prefix.

## Interaction Policy

@${CLAUDE_PLUGIN_ROOT}/references/interaction-policy.md

---

## Dispatch

Read `selected_action` from the YAML context and load the corresponding action file. Follow its instructions exactly.

| `selected_action` | Action file |
|---|---|
| Archive | @${CLAUDE_PLUGIN_ROOT}/references/actions/archive.md |
| Create Jira Ticket | @${CLAUDE_PLUGIN_ROOT}/references/actions/create-jira.md |
| Link Existing Jira | @${CLAUDE_PLUGIN_ROOT}/references/actions/link-jira.md |
| Escalate to Slack | @${CLAUDE_PLUGIN_ROOT}/references/actions/escalate.md |
| Send to Automaton | @${CLAUDE_PLUGIN_ROOT}/references/actions/automaton.md |
| Need More Context | @${CLAUDE_PLUGIN_ROOT}/references/actions/diagnostics.md |
