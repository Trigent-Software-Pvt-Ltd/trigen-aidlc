# Action: Create Jira Ticket

Draft and create a structured Jira ticket with the full triage analysis as context.

## Step 1: Select Project

**Required** user choice — present via `AskUserQuestion`. Do not assume AI/AR/TLINE from prior triages or from the issue's project slug.

```
AskUserQuestion(
  question: "Which Jira project should this ticket go in?",
  header: "Jira Project",
  options: [
    { label: "AI (StudentSafe)", description: "Default for Sentry triage." },
    { label: "AR", description: "AR project." },
    { label: "TLINE", description: "TLINE project." },
    { label: "Other", description: "I'll type a project key." }
  ]
)
```

- If **AI**, **AR**, or **TLINE**: use that key directly — no need to fetch the project list.
- If **Other**: ask the user to type a project key, then validate it exists:
  - **If `jira_mode: acli`**: Run `acli jira project list --output json` via Bash and confirm the key is in the list.
  - **If `jira_mode: mcp`**: Call `{jira_mcp_prefix}getVisibleJiraProjects` and confirm the key is in the list.
  - If the key is not found, inform the user and re-ask.

## Step 2: Get Issue Types

- **If `jira_mode: acli`**: Run `acli jira issue-type list --project {key} --output json` via Bash.
- **If `jira_mode: mcp`**: Call `{jira_mcp_prefix}getJiraProjectIssueTypesMetadata` for the selected project.

Default to "Bug" for errors, but let the user override if needed.

## Step 3: Draft the Ticket

Compose a well-structured ticket:

**Summary**: Concise title derived from the Sentry error (under 255 characters). Format: `[Sentry] {error_type} in {location} — {brief description}`

**Description** (structured markdown):

```markdown
## Sentry Issue
- **Link**: {sentry_url}
- **Severity**: {severity}
- **First Seen**: {date} | **Last Seen**: {date}
- **Occurrences**: {count} | **Users Affected**: {user_count}

## Error
`{error_type}: {error_message}`

## Root Cause Hypothesis
{from analysis — what we think is happening and why}

## Stacktrace (excerpt)
{key frames from the stacktrace — not the full trace, just the relevant application frames}

## Impact
- **Trigger**: {trigger source}
- **Pattern**: {error pattern classification}
- **Trend**: {increasing/stable/decreasing}
- **Environments**: {affected environments}
- **Release Correlation**: {if applicable}

## Slack Discussion
{summary of any team discussion found, or "None found"}

## Considerations
> Do not suggest a fix. Help the reader understand the code's intent so they can reason about the problem independently.

- **Intent of the code**: {what the affected code is trying to accomplish — its purpose, not just what it does}
- **Surrounding logic**: {what depends on or is affected by this area — callers, downstream consumers, side effects}
- **Assumptions and invariants**: {what the code relies on being true — e.g., non-null inputs, specific ordering, feature flags}
- **Consequences of change**: {what could break or stop happening if this area is modified — guard clauses that suppress other paths, error handling that masks state}

## Local Code Context
> Only include this section if repo_context.available is true in the YAML context.

{For each file in repo_context.source_context:}
- `{file}` line {line} — last modified by {blame_author} in `{commit_hash}` ({timeframe}): "{commit_message}"
```

**Labels**: `sentry-triage`, `severity-{level}`

## Step 4: User Approval

**Required** user choice — present via `AskUserQuestion`. Never create a Jira ticket without explicit approval; the draft is text, the create call is the side effect.

```
AskUserQuestion(
  question: "Here's the Jira ticket draft. Ready to create it?",
  header: "Jira Ticket",
  options: [
    { label: "Create it", description: "Create the ticket as drafted." },
    { label: "Let me edit first", description: "I'll adjust the draft based on your feedback." },
    { label: "Cancel", description: "Don't create a ticket." }
  ]
)
```

If "Let me edit first": ask what to change, revise, and re-present.

## Step 5: Create

When creating Bug issues, include these required custom fields with their defaults (no need to ask the user):

- **Found By?** (`customfield_10331`): "Engineering Team (Dev/QA)" — id `10733`
- **Investment Type** (`customfield_10378`): "Defect" — id `10725`

**If `jira_mode: acli`**: Run via Bash:
```bash
acli jira issue create --project {key} --type Bug --summary "{summary}" --description "{description}" --labels "sentry-triage,severity-{level}" --custom "customfield_10331:10733" --custom "customfield_10378:10725" --output json
```

**If `jira_mode: mcp`**: Call `{jira_mcp_prefix}createJiraIssue` with `additional_fields`:
```json
{
  "labels": ["sentry-triage", "severity-{level}"],
  "customfield_10331": {"id": "10733"},
  "customfield_10378": {"id": "10725"}
}
```

Report the created ticket key and URL.

## Step 6: Link Sentry → New Jira Ticket

Mirror the link-existing pattern so the newly created ticket also appears in the Sentry issue's "Linked Issues" sidebar.

**If `sentry_cli_mode: unavailable`:** skip this step. The Step 7 summary will tell the user to add the Sentry-side link manually via the "Link Issue" button on the Sentry issue page.

**If `sentry_cli_mode: available`:** run the **Discover the org's Jira integration ID** and **Link a Jira ticket** recipes from @${CLAUDE_PLUGIN_ROOT}/references/sentry-cli-integration.md, substituting `{sentry_org_slug}`, `{sentry_numeric_id}`, and `{ticket_key}` = the key of the ticket just created in Step 5. Handle the response per the reference's status-code branches.

Read the **Sentry-side link outcome summary** table from @${CLAUDE_PLUGIN_ROOT}/references/sentry-cli-integration.md for the exact summary line to use in Step 7. The Jira ticket exists regardless; only the Sentry-side back-link may need manual follow-up.

## Step 7: Offer Follow-Up Actions

**Required** user choice — present via `AskUserQuestion`. Do not chain into Automaton/Escalate/Done without asking.

Now that a Jira ticket exists, offer follow-up options. Build the options dynamically:

```
AskUserQuestion(
  question: "Ticket {TICKET-KEY} created. What next?",
  header: "Follow-Up",
  options: [
    // Always include — Jira is confirmed working since we just created the ticket:
    { label: "Send to Automaton", description: "Trigger Automaton to work on this ticket." },
    // Include only if slack_available is true:
    { label: "Escalate to Slack", description: "Draft an escalation message to a Slack channel." },
    // Always include:
    { label: "Done", description: "Finish triage." }
  ]
)
```

**If "Send to Automaton"**: read @${CLAUDE_PLUGIN_ROOT}/references/actions/automaton.md, but skip its Step 1 (verify ticket exists) and use the **newly created ticket key** from Step 5 — not `existing_jira_ticket` from the original YAML context. Proceed directly to its Step 2 (Post Automaton Trigger Comment).

**If "Escalate to Slack"**: read @${CLAUDE_PLUGIN_ROOT}/references/actions/escalate.md and execute that action.

**If "Done"**: Present a triage summary and end the workflow. Include a **Sentry-side link** row using the matching summary line from the Step 6 outcomes table:

```markdown
## Triage Complete

| Field | Value |
|-------|-------|
| **Sentry Issue** | {issue_title} ({issue_url}) |
| **Severity** | {severity} |
| **Jira Ticket** | {TICKET-KEY} ({ticket_url}) |
| **Sentry-side link** | {one of the Step 6 outcomes — e.g. "linked via Sentry integration"} |
| **Error** | `{error_type}: {error_message}` |
| **Root Cause** | {root_cause_hypothesis} |
| **Trend** | {trend} |
```

## Jira Unavailable Fallback

If `jira_mode` is `unavailable` (both acli and MCP were attempted and failed), present the full ticket draft as markdown so the user can create it manually. Include all fields (summary, description, type, labels).
