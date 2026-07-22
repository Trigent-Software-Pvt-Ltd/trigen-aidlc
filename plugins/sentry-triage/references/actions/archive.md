# Action: Archive

The user has decided this issue is safe to ignore. Your job is to clearly document **why** so the decision is defensible later.

## Step 1: Present Archival Rationale

Write a clear explanation of why this issue is safe to archive. Base it on the analysis:

```markdown
## Archive Rationale

**Issue**: {title} ({sentry_url})
**Severity**: {severity}

**Why archive:**
- {reason 1 — e.g., "Already resolved in release v2.3.1"}
- {reason 2 — e.g., "Affects only development environment"}
- {reason 3 — e.g., "Expected behavior during scheduled maintenance window"}

**Risk of archiving**: {Low — no user impact / Medium — monitor for recurrence / etc.}
```

## Step 2: Offer Slack Note (if Slack available)

**Required** user choice — present via `AskUserQuestion`. Do not skip this and silently decide whether to post.

```
AskUserQuestion(
  question: "Want to post a note about this archival decision to Slack?",
  header: "Slack Note",
  options: [
    { label: "Yes, draft a note", description: "I'll draft a message and send it as a draft for your review." },
    { label: "No, skip", description: "Just archive it, no need to notify anyone." }
  ]
)
```

If yes: draft a concise Slack message summarizing the issue and archival rationale. Use `mcp__claude_ai_Slack__slack_send_message_draft` so the user can review before it sends. Default to **#eng-cpoms-oncall** unless the user specifies a different channel.

If Slack is unavailable: present the note as markdown the user can copy-paste manually.

## Step 3: Choose Archive Trigger

**Required** user choice — present via `AskUserQuestion`. The trigger shape is the whole point of this step. Do not pick a default silently; the user owns this decision.

Sentry calls this the "reopen trigger" — conditions that should reopen the issue after archival.

```
AskUserQuestion(
  question: "How should this archive behave?",
  header: "Archive Trigger",
  options: [
    { label: "Forever",               description: "Archive until manually reopened. The issue stops appearing in default views." },
    { label: "Until events or users", description: "Reopen after N more occurrences or N more affected users, optionally within a time window." },
    { label: "Until time",            description: "Auto-reopen after N hours or at a specific date/time you choose." },
    { label: "Skip — manual",         description: "Don't archive via the CLI. The skill will print Sentry UI steps instead." }
  ]
)
```

**If "Until events or users"**: ask a follow-up to determine the exact trigger:

```
AskUserQuestion(
  question: "Which event-based trigger?",
  header: "Event Trigger",
  options: [
    { label: "N more events",           description: "Reopen after the issue fires N more times." },
    { label: "N events within H hours", description: "Reopen only if N events occur within a rolling time window." },
    { label: "N new affected users",    description: "Reopen after N more unique users hit this error." }
  ]
)
```

Then ask for the value (N for events/users; both N and H for the windowed variant).

**If "Until time"**: ask a follow-up:

```
AskUserQuestion(
  question: "Reopen when?",
  header: "Time Trigger",
  options: [
    { label: "After N hours",      description: "Auto-reopen after a fixed duration, e.g. after a maintenance window closes." },
    { label: "At a specific date", description: "Reopen at a date/time you specify (ISO 8601, e.g. 2026-06-01T00:00:00Z)." }
  ]
)
```

Then ask for the hours or ISO timestamp.

## Step 4: Execute Archive

Read @${CLAUDE_PLUGIN_ROOT}/references/sentry-cli-integration.md for the canonical recipes (token guard, exit-code handling for `sentry-cli mute`, HTTP status-code handling for curl, response shapes).

**If `sentry_cli_mode: unavailable` or the user chose "Skip — manual":** go to Step 5 (manual fallback).

**If `sentry_cli_mode: available`:**

- **Forever** → use the reference's **Unconditional archive (CLI)** recipe with `{project}` and `{sentry_numeric_id}` substituted.
- **Until events or users**, **Until time** → use the reference's **Conditional archive (REST API)** recipe with `{sentry_org_slug}` and `{sentry_numeric_id}` substituted, and build `{status_details_body}` from the user's sub-choice using the reference's **Common trigger patterns** table.

Handle the response per the reference's **Inspecting HTTP responses** section. If the REST call returns any non-2xx status (401, 403, 404, or the wildcard branch) or the CLI exits non-zero, fall through to Step 5's manual fallback.

## Step 5: Confirm or Fall Back

**If the CLI/REST call succeeded:** confirm to the user with the chosen trigger and the Sentry issue URL.

```markdown
Archived **{title}** ({sentry_url}) — {trigger description, e.g. "until 10 more events", "for 24 hours", "until 2026-05-15"}.
```

**Manual fallback** — used when `sentry_cli_mode: unavailable`, when the user chose "Skip — manual", or when the automated call fell back. Open with the matching opening line:

| Condition | Opening line |
|---|---|
| `sentry_cli_mode: unavailable` | "Sentry CLI is not available in this session. To archive manually:" |
| User chose "Skip — manual" | "You chose to archive manually. Steps:" |
| Automated call returned a non-success response | "The automated archive did not complete. Archive manually instead:" |

Then the shared UI steps:

```markdown
1. Open the issue: {sentry_url}
2. Click the **Archive** button in the issue header.
3. Pick the matching archive option:
   - Forever → "Archive forever"
   - Until N more events / N events within H hours → "Archive until it occurs N more times"
   - Until N new affected users → "Archive until it affects N more users"
   - Until time / Until specific date → "Archive for a duration" or "Archive until a date"
```

## Step 6: Offer Follow-Up

**Required** — build options dynamically based on Slack availability. If `slack_available: false`, skip this question and present the summary directly.

```
AskUserQuestion(
  question: "Archive complete. What next?",
  header: "Follow-Up",
  options: [
    // Include only if slack_available is true:
    { label: "Escalate to Slack", description: "Draft an escalation message to a channel for broader team awareness." },
    // Always include:
    { label: "Done", description: "End triage." }
  ]
)
```

**If "Escalate to Slack"**: read @${CLAUDE_PLUGIN_ROOT}/references/actions/escalate.md and execute that action.

**If "Done"** or Slack unavailable: present the triage summary:

```markdown
## Triage Complete

| Field | Value |
|-------|-------|
| **Sentry Issue** | {issue_title} ({sentry_url}) |
| **Severity** | {severity} |
| **Action** | Archived — {trigger description, e.g. "until 10 more events", "forever", "for 24 hours"} |
| **Error** | `{error_type}: {error_message}` |
| **Root Cause** | {root_cause_hypothesis} |
| **Trend** | {trend} |
```
