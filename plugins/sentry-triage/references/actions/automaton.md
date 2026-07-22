# Action: Send to Automaton

Trigger Automaton to work on the Jira ticket associated with this Sentry issue. Read @${CLAUDE_PLUGIN_ROOT}/references/automaton-integration.md for details on the Automaton trigger format and requirements.

## Step 1: Verify Jira Ticket Exists

Check `existing_jira_ticket` from the YAML context.

**If `existing_jira_ticket` is "none":**

Inform the user and bounce back to action selection:

> There is no Jira ticket linked to this Sentry issue. Automaton requires a Jira ticket to work on. Please create or link a ticket first, then try Send to Automaton again.

**Required** user choice — present via `AskUserQuestion`. Do not silently fall back to Archive or any other default; the user picked Automaton for a reason and needs to decide what to do instead.

Re-present the action options. Build the options dynamically using the same availability conditions from sentry-analyze Phase 5, minus "Send to Automaton":

```
AskUserQuestion(
  question: "No Jira ticket found. Choose a different action:",
  header: "Action Required",
  options: [
    // Always include:
    { label: "Archive", description: "Archive this issue — safe to ignore." },
    { label: "Need More Context", description: "Get diagnostic suggestions before deciding." },
    // Include if jira_mode is not "unavailable":
    { label: "Create Jira Ticket", description: "Create a new Jira ticket with the triage analysis." },
    // Include if Slack is available:
    { label: "Escalate to Slack", description: "Draft an escalation message to a Slack channel." }
    // Do NOT include "Link Existing Jira" — we already know existing_jira_ticket is "none"
  ]
)
```

Execute the chosen action by reading the corresponding file in this directory. If the user creates or links a Jira ticket and then wants to send to Automaton, they can re-run `/sentry-triage` or select Automaton in a future triage session.

**If `existing_jira_ticket` has a value:** proceed to Step 2.

## Step 2: Post Automaton Trigger Comment

Post the trigger comment on the Jira ticket:

- **If `jira_mode: acli`**: Run via Bash:
  ```bash
  acli jira issue add-comment --issue {existing_jira_ticket} --comment "@automaton work on this"
  ```

- **If `jira_mode: mcp`**: Call `{jira_mcp_prefix}addCommentToJiraIssue` with:
  - `issueIdOrKey`: the ticket key from `existing_jira_ticket`
  - `comment`: `@automaton work on this`

- **If `jira_mode: unavailable`**: Present manual instructions:
  > Jira is not available from this session. To trigger Automaton manually, add this comment to **{existing_jira_ticket}**:
  >
  > `@automaton work on this`

## Step 3: Confirm

Report success:

```markdown
Automaton triggered on **{existing_jira_ticket}**.

- **Comment posted**: `@automaton work on this`
- **Ticket**: {existing_jira_ticket}{if existing_jira_summary is present: " — {existing_jira_summary}"}
- **Sentry Issue**: {issue_url}

Automaton will pick up the task asynchronously. Monitor progress in the Jira ticket.
```
