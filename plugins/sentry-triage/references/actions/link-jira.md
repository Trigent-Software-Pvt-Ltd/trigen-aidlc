# Action: Link Existing Jira

The analysis found an existing Jira ticket that matches this Sentry issue. Add the triage context as a comment.

## Step 1: Confirm the Match

**Required** user choice — present via `AskUserQuestion`. Do not assume the JQL match from `/sentry-analyze` is correct; the user must confirm before we comment on the ticket.

Show the existing ticket details (key, summary, status, assignee) and confirm with the user:

```
AskUserQuestion(
  question: "Is this the right ticket to link the Sentry issue to?\n\n**{TICKET-KEY}**: {summary}\nStatus: {status} | Assignee: {assignee}",
  header: "Confirm Jira Match",
  options: [
    { label: "Yes, add comment", description: "Add the triage analysis as a comment on this ticket." },
    { label: "Wrong ticket", description: "This isn't the right match — skip linking." },
    { label: "Cancel", description: "Don't link to any ticket." }
  ]
)
```

If "Wrong ticket" or "Cancel": end this action. The user can re-run triage or manually link later.

## Step 2: Add Comment

- **If `jira_mode: acli`**: Run `acli jira issue add-comment --issue {key} --comment "{comment}"` via Bash.
- **If `jira_mode: mcp`**: Call `{jira_mcp_prefix}addCommentToJiraIssue`.

Add a structured comment:

```markdown
## Sentry Triage Update

A related Sentry issue was triaged and linked to this ticket.

- **Sentry Link**: {url}
- **Severity**: {severity}
- **Occurrences**: {count} | **Users**: {user_count}
- **Error**: `{type}: {message}`
- **Root Cause Hypothesis**: {hypothesis}
- **Trend**: {increasing/stable/decreasing}

Triaged on {date}.
```

## Step 3: Create Sentry-side Link

The Jira comment added in Step 2 is a human-readable record on the ticket; it is not a structured link. To make the Sentry issue page show the Jira ticket under "Linked Issues" (and keep both sides in sync), use Sentry's REST integration API. Per the reference's "After acting" note, a successful link also adds a Sentry mention to the Jira ticket's activity feed via the integration — no separate Jira-side action is needed.

**If `sentry_cli_mode: unavailable`:** skip this step. Step 4 will report that the Sentry-side link must be added manually via Sentry's UI ("Link Issue" button on the Sentry issue page).

**If `sentry_cli_mode: available`:** run the **Discover the org's Jira integration ID** and **Link a Jira ticket** recipes from @${CLAUDE_PLUGIN_ROOT}/references/sentry-cli-integration.md, substituting `{sentry_org_slug}`, `{sentry_numeric_id}`, and `{ticket_key}` from `existing_jira_ticket`. Handle the response per the reference's status-code branches.

Read the **Sentry-side link outcome summary** table from @${CLAUDE_PLUGIN_ROOT}/references/sentry-cli-integration.md for the exact summary line to use in Step 4.

## Step 4: Report

Confirm both directions and show the ticket URL. Use the matching summary line for **Sentry-side** from the Step 3 outcomes table:

```markdown
Linked Sentry issue ↔ Jira ticket.

- **Sentry issue**: {sentry_url}
- **Jira ticket**: {ticket_url} ({TICKET-KEY})
- **Jira-side**: comment added with triage analysis
- **Sentry-side**: {Step 3 outcome — e.g. "linked via Sentry integration (visible under Linked Issues)"}
```

## Step 5: Offer Follow-Up

**Required** — build options dynamically based on Slack availability. If `slack_available: false`, skip this question and end the workflow.

```
AskUserQuestion(
  question: "Linking complete. What next?",
  header: "Follow-Up",
  options: [
    // Include only if slack_available is true:
    { label: "Escalate to Slack", description: "Draft an escalation message to a channel for team attention." },
    // Always include:
    { label: "Done", description: "End triage." }
  ]
)
```

**If "Escalate to Slack"**: read @${CLAUDE_PLUGIN_ROOT}/references/actions/escalate.md and execute that action.

**If "Done"** or Slack unavailable: end the workflow.
