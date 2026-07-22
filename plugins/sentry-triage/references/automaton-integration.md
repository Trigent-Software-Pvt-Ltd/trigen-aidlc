# Automaton Integration

## What is Automaton?

Automaton is an AI coding agent triggered via Jira. When a comment containing `@automaton work on this` is posted on a Jira ticket, a webhook fires and Automaton picks up the task. Automaton reads the ticket's summary and description for context, then begins working on the issue.

## Trigger Format

The trigger is a Jira comment with exactly this text:

```
@automaton work on this
```

- The comment must be posted on an existing Jira ticket
- Only the trigger phrase is needed — Automaton reads the ticket itself for context
- Do not include additional context in the comment (Automaton ignores it)

## Requirements

- A Jira ticket must exist before triggering Automaton
- The ticket should have a clear summary and description so Automaton understands the task
- The user must have permission to comment on the Jira ticket

## Posting the Comment

The comment is posted using the same `jira_mode` pattern used throughout the sentry-triage plugin:

| jira_mode | Method |
|-----------|--------|
| `acli` | `acli jira issue add-comment --issue {key} --comment "@automaton work on this"` |
| `mcp` | `{jira_mcp_prefix}addCommentToJiraIssue` with the ticket key and comment text |
| `unavailable` | Present the comment text for the user to post manually |

## Error Handling

| Scenario | Action |
|----------|--------|
| No Jira ticket linked | Inform user, bounce back to action selection |
| Jira unavailable (`jira_mode: unavailable`) | Show manual instructions with the comment text to copy-paste |
| Comment post fails (auth, network) | Report the error, show manual instructions as fallback |
| Ticket exists but user lacks comment permission | Report the Jira permission error, suggest manual posting or asking a team member |

## After Triggering

After successfully posting the comment:
1. Confirm to the user with the ticket key, a link to the ticket, and the Sentry issue URL
2. Note that Automaton will pick up the task asynchronously — there is no immediate feedback
3. The user can monitor progress in the Jira ticket's activity feed
