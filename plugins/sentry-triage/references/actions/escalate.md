# Action: Escalate to Slack

Draft an escalation message for team attention.

## Step 1: Select Channel

**Required** user choice — present via `AskUserQuestion`. The channel decides who gets paged; do not pick it silently.

If Slack is available, default to **#eng-cpoms-oncall** — this is the primary oncall channel where most Sentry issues are discussed. Confirm the channel with the user via `AskUserQuestion`, offering #eng-cpoms-oncall as the default and a "Different channel" option. If they choose a different channel, search using `mcp__claude_ai_Slack__slack_search_channels` with keywords from the Sentry project name and present results to pick from.

## Step 2: Draft Message

Compose a clear escalation message using Slack mrkdwn formatting:

```
:rotating_light: *Sentry Issue Escalation*

*Issue*: {title}
*Severity*: {severity}
*Link*: {sentry_url}

*Impact*: {occurrences} occurrences, {users} users affected ({trend})
*Error*: `{error_type}: {error_message}`
*Trigger*: {trigger source}
*Hypothesis*: {root cause hypothesis}

*Action Needed*: {what the team should investigate or do next}

_Triaged via /sentry-triage_
```

## Step 3: Send as Draft

Use `mcp__claude_ai_Slack__slack_send_message_draft` so the user can review the message before it actually sends.

## Slack Unavailable Fallback

If Slack MCP is not connected, present the escalation message as formatted text the user can copy-paste into Slack manually.
