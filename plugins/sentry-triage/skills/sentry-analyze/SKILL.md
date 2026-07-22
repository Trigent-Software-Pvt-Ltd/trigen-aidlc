---
name: sentry-analyze
description: "Analyze a Sentry issue across five dimensions (trigger source, impact, error patterns, infrastructure, related issues), check Jira for existing tickets, classify severity, and present triage action options. Chained from /sentry-triage, or invoke directly with issue context. (Triggers: analyze sentry, sentry analyze, sentry severity, classify sentry, sentry assessment)"
allowed-tools: [Bash, mcp__claude_ai_Sentry__search_issues, mcp__claude_ai_Sentry__get_issue_tag_values, mcp__claude_ai_Sentry__get_issue_details, mcp__claude_ai_Sentry__get_trace_details, mcp__claude_ai_Sentry__find_releases, mcp__claude_ai_Sentry__search_issue_events, mcp__sentry__search_issues, mcp__sentry__get_issue_tag_values, mcp__sentry__get_issue_details, mcp__sentry__get_trace_details, mcp__sentry__find_releases, mcp__sentry__search_issue_events, mcp__atlassian__searchJiraIssuesUsingJql, mcp__atlassian__getJiraIssue, mcp__atlassian__getVisibleJiraProjects, mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql, mcp__claude_ai_Atlassian__getJiraIssue, mcp__claude_ai_Atlassian__getVisibleJiraProjects, AskUserQuestion]
argument-hint: "(chained from /sentry-triage with context)"
---

# Sentry Triage — Step 2: Analyze & Classify

This is the second skill in the triage chain:
1. **`/sentry-triage`** — Gather data from Sentry and Slack
2. **`/sentry-analyze`** (you are here) — Deep analysis, severity classification, action selection
3. **`/sentry-action`** — Execute the chosen action

Use the YAML context block passed from `/sentry-triage` (or provided manually via `$ARGUMENTS`). Parse it from `$ARGUMENTS` to extract: issue_url, sentry_numeric_id, sentry_org_slug, issue_title, error_type, error_message, project, platform, timestamps, occurrences, users_affected, status, assignee, tags, environments, releases, stacktrace, trace_context, repo_context, slack_available, and slack_findings. Do not re-fetch data that was already gathered — work from the context block. Note: Jira availability was not checked in Step 1; check it now in Phase 2. Sentry CLI availability is also probed in Phase 2 so the action skill knows whether it can archive and link automatically.

## MCP Tool Note

Tool names vary by installation. This skill references `mcp__claude_ai_Sentry__*` (built-in) and `mcp__atlassian__*` / `mcp__claude_ai_Atlassian__*` (Atlassian MCP — both prefixes are listed in allowed-tools). If a Sentry call fails with "unknown tool", try `mcp__sentry__*` as an alternative prefix.

## Interaction Policy

@${CLAUDE_PLUGIN_ROOT}/references/interaction-policy.md

---

## Phase 1: Deep Analysis

Analyze the issue across five dimensions using the gathered context. You may make additional Sentry API calls where the gathered data is insufficient.

### 1a. Trigger Source

Determine what triggered the error from the stacktrace and tags:

| Source | Signals |
|--------|---------|
| Web request | Controller/view in stacktrace, HTTP method/path in tags |
| Background job | Job/worker class in stacktrace, queue name in tags |
| Console session | Rails console or REPL in stacktrace |
| Cron / scheduled task | Scheduler or clock process, periodic pattern in timestamps |
| Message consumer | Queue/topic consumer in stacktrace, messaging tags |

Extract the specific route, endpoint, job class, or task name where applicable.

### 1b. Impact Assessment

Evaluate using gathered data:

- **Occurrence trend** — Is the count increasing, stable, or decreasing? For a rough estimate, compare first_seen vs last_seen relative to occurrence count. For higher-fidelity trend data (especially when occurrences >50), use `mcp__claude_ai_Sentry__search_issue_events` to compare recent event density (e.g., last 24 hours) against the overall average rate.
- **User scope** — How many unique users are affected? Is it concentrated on one user/tenant or spread across many?
- **Timeframe** — How long has this been happening? Hours, days, weeks?
- **Exception handling** — Is this a handled exception (caught and logged) or unhandled (crashed the request/job)?
- **Environment spread** — Production only, or also staging/development? Production-only suggests a data or config issue; multi-environment suggests a code issue.

### 1c. Error Pattern Recognition

Classify the error against known patterns:

| Pattern | Indicators |
|---------|-----------|
| Missing tenant / config | KeyError, config lookups, tenant-specific data |
| Timeout / network | Timeout, connection refused, DNS resolution, gateway errors |
| Auth / permission | 401/403, token expired, permission denied, unauthorized |
| Data integrity / constraint | Unique violation, foreign key, nil where not expected, duplicate |
| Memory / resource exhaustion | OOM, too many open files, connection pool exhausted |
| Null reference | NoMethodError on nil, NullPointerException, undefined is not a function |
| External API failure | Third-party API errors, unexpected response format, rate limiting |
| Rate limiting | 429 responses, throttle messages |

Note confidence level: high (clear match), medium (partial signals), low (ambiguous).

### 1d. Infrastructure Context

Extract from tags:
- Server / hostname
- Runtime version (Ruby, Python, Node, etc.)
- OS and browser (if web)
- SDK version
- Release tag — does the issue correlate with a specific deployment?

If a release is identified, call `mcp__claude_ai_Sentry__find_releases` to get the release date and details. Compare the issue's first_seen timestamp with the release date — if they align closely, this strongly indicates a regression introduced by that release.

If trace_context in the YAML is "none" and a `trace_id` is present in the event tags, call `mcp__claude_ai_Sentry__get_trace_details` (or `mcp__sentry__get_trace_details` as fallback) to capture the distributed trace. Otherwise, use the trace_context value from the YAML and review it here for upstream failures, slow spans, or cross-service error propagation.

If `repo_context.available` is `true` in the YAML, incorporate the local repository findings into this analysis:

- **Recent changes**: Review `recent_commits` and `blame_excerpt` for each file in `source_context`. If the error line was recently modified (within the last few commits), note this as a strong regression signal — it may point directly to the commit that introduced the bug.
- **Code context**: Use the `snippet` fields to deepen the root cause hypothesis. The actual source code around the error line can reveal logic issues, missing nil checks, incorrect conditionals, or incomplete error handling that the stacktrace alone cannot show.
- **Author attribution**: The blame data identifies who last touched the error site — useful for the report and for routing follow-up.

If `repo_context.available` is `false` or not present, skip this — do not mention local repository context in the analysis.

### 1e. Related Issues

Call `mcp__claude_ai_Sentry__search_issues` with the error type or distinctive parts of the error message to find similar issues in the same project.

Look for:
- **Previously resolved** instances of the same error — indicates a regression
- **Open duplicates** — the same root cause manifesting differently
- **Similar patterns** in other parts of the codebase

---

## Phase 2: Jira Check and CLI Probe

### Check Jira Availability

Check Jira availability in this order:

1. **Preferred — acli**: Run `acli jira project list --output json` via Bash. If this succeeds, set `jira_mode: acli`.
2. **Fallback — MCP**: Try `mcp__atlassian__getVisibleJiraProjects`. If that fails, try `mcp__claude_ai_Atlassian__getVisibleJiraProjects`. If either succeeds, set `jira_mode: mcp` and note which prefix worked.
3. **Unavailable**: If all fail, set `jira_mode: unavailable`. Skip the duplicate search but continue with everything else. Note "Jira: unavailable (both acli and MCP failed)" in the findings.

Use `jira_mode` throughout — all subsequent Jira calls in this skill and in `/sentry-action` should follow the same path (acli or MCP) that succeeded here.

### Search for Existing Tickets

If `jira_mode` is not `unavailable`, search for existing tickets related to this issue.

**If `jira_mode: acli`**: Run JQL searches via Bash:
```bash
acli jira issue list --jql 'text ~ "{sentry-issue-id}" OR text ~ "{distinctive error keywords}" ORDER BY created DESC' --output json
```

**If `jira_mode: mcp`**: Use the MCP prefix that succeeded in the availability check (either `mcp__atlassian__searchJiraIssuesUsingJql` or `mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql`).

JQL pattern — try 2-3 variations:
1. The numeric Sentry issue ID (not the full URL — URLs contain special characters that break JQL text search)
2. Key alphanumeric terms from the error message (strip special characters)
3. The error class name

For any matches, fetch details (`acli jira issue view {key} --output json` if acli, or `mcp__atlassian__getJiraIssue` / `mcp__claude_ai_Atlassian__getJiraIssue` if MCP) and record:
- Ticket key and summary
- Status (Open, In Progress, Resolved, etc.)
- Assignee
- When it was created

Note whether a match was found — this determines whether "Link Existing Jira" appears as an action option.

### Check Sentry CLI Availability

`/sentry-action` can automate archiving and Jira linking when `sentry-cli` is installed and authenticated. Run the **Availability check** probe from @${CLAUDE_PLUGIN_ROOT}/references/sentry-cli-integration.md and set `sentry_cli_mode` to its output (`available` or `unavailable`).

The reference's **Fallback behaviour** table covers what `unavailable` means in practice: missing CLI, missing config file, or failing auth all collapse to the same state. Do not fail the whole skill — note "Sentry CLI: unavailable" in the findings and forward `sentry_cli_mode: unavailable` so `/sentry-action` degrades cleanly to manual instructions.

---

## Phase 3: Severity Classification

Classify using this rubric:

| Severity | Criteria |
|----------|----------|
| **CRITICAL** | Unhandled exception in production affecting >100 users, OR data loss/corruption, OR security-related, OR complete feature failure |
| **HIGH** | Unhandled exception affecting 10-100 users, OR significant feature degradation, OR regression from a recent release |
| **MEDIUM** | Unhandled exception affecting <10 users, OR handled exception with moderate impact, OR non-critical feature affected |
| **LOW** | Cosmetic/logging error, development environment only, already resolved, or negligible user impact |

When multiple criteria apply at different levels, use the highest applicable severity. Unhandled exceptions should always be at least MEDIUM regardless of user count. State which criteria drove the classification.

---

## Phase 4: Present Findings

Present the full analysis as a structured report:

```markdown
## Sentry Triage Report

### Summary
| Field | Value |
|-------|-------|
| **Issue** | {title} |
| **Sentry Link** | {url} |
| **Severity** | {CRITICAL / HIGH / MEDIUM / LOW} |
| **Error** | `{type}: {message}` |
| **Trigger** | {web request to /path / background job ClassName / etc.} |
| **Impact** | {X occurrences, Y users, over Z timeframe} |
| **Trend** | {increasing / stable / decreasing} |

### Analysis
- **Error Pattern**: {classified pattern} (confidence: {high/medium/low})
- **Root Cause Hypothesis**: {your best assessment based on stacktrace and pattern}
- **Infrastructure**: {release, environment, runtime details}
- **Release Correlation**: {correlated with release X / no correlation found}
- **Local Code Context**: {if repo_context available: "Source reviewed — error site in `{file}` last modified by {author} in commit `{hash}`: {message}" / if not available: omit this line entirely}
- **Related Sentry Issues**: {similar issues found, or "none"}
- **Existing Jira Tickets**: {matched tickets with status, or "none found", or "Jira unavailable"}
- **Slack Discussion**: {summary of team discussion, or "none found", or "unavailable"}

### Recommendation
{1-2 sentences on what you'd recommend based on severity and analysis}
```

---

## Phase 5: Action Selection

**Required** user choice — present via `AskUserQuestion`. Do not pick an action on the user's behalf and chain straight to `/sentry-action`; the whole point of this phase is to surface the choice. See **Interaction Policy** at the top of this file.

Use two questions to stay within the 4-option limit on `AskUserQuestion`.

### Question 1 — Primary action

Build the options dynamically:

```
AskUserQuestion(
  question: "What action do you want to take for this issue?",
  header: "Triage Action",
  options: [
    // Always include:
    { label: "Archive",           description: "Safe to ignore — low impact, already resolved, or expected. Presents rationale and configurable reopen trigger." },
    // Include if jira_mode is not "unavailable":
    { label: "Jira",              description: "Create a ticket, link to an existing one, or trigger Automaton. Options shown next." },
    // Include if Slack is available:
    { label: "Escalate to Slack", description: "Draft an escalation message to a Slack channel for team attention." },
    // Always include:
    { label: "Need More Context", description: "Get diagnostic suggestions and investigation steps before deciding." }
  ]
)
```

If Slack is unavailable, update its description to: "Generate an escalation message you can post to Slack manually."

If `jira_mode` is `unavailable`, omit "Jira" — the question has 3 or fewer options.

**If "Archive"**, **"Escalate to Slack"**, or **"Need More Context"**: chain directly to Phase 6 with `selected_action` set to that action name.

**If "Jira"**: proceed to Question 2.

### Question 2 — Jira action (only when user chose "Jira")

If `existing_jira_ticket` is "none", skip this question and chain to Phase 6 with `selected_action: "Create Jira Ticket"`.

Otherwise, build the sub-options dynamically:

```
AskUserQuestion(
  question: "Which Jira action?",
  header: "Jira Action",
  options: [
    // Always include (Jira is confirmed available):
    { label: "Create Jira Ticket", description: "Draft a structured bug ticket with the full analysis as context. You approve before it's created." },
    // Include if existing_jira_ticket is not "none":
    { label: "Link Existing Jira", description: "Add this analysis as a comment on {TICKET-KEY}: {ticket summary}." },
    // Include if existing_jira_ticket is not "none":
    { label: "Send to Automaton",  description: "Trigger Automaton on {TICKET-KEY} by posting @automaton work on this." }
  ]
)
```

Chain to Phase 6 with `selected_action` set to the chosen label.

---

## Phase 6: Chain to Action

After the user selects an action, invoke `/sentry-action` and pass a YAML context block:

```yaml
selected_action: "Archive" # or "Create Jira Ticket", "Link Existing Jira", "Escalate to Slack", "Send to Automaton", "Need More Context"
# Full triage context (forwarded from Step 1):
issue_url: "..."
sentry_numeric_id: "..."               # numeric Sentry issue ID, e.g. "6602946670"
sentry_org_slug: "..."                 # Sentry organization slug, e.g. "cpoms"
issue_title: "..."
error_type: "..."
error_message: "..."
project: "..."                         # Sentry project slug — used as --project for sentry-cli
platform: "..."
first_seen: "..."
last_seen: "..."
occurrences: 1234
users_affected: 56
status: "..."
assignee: "..."
tags:
  environment: "production"
  release: "v2.3.1"
  # ... all tags from Step 1
environments: ["production", "staging"]
releases: ["v2.3.1", "v2.3.0"]
stacktrace: |
  ...
# Analysis results (from this step):
severity: "HIGH"
severity_criteria: "Unhandled exception affecting 45 users"
error_pattern: "Timeout / network"
pattern_confidence: "high"
root_cause_hypothesis: "..."
trigger_source: "Web request to /api/v1/users"
trend: "increasing"
infrastructure:
  release: "v2.3.1"
  environment: "production"
  runtime: "Ruby 3.2.0"
release_correlation: "Started with v2.3.1"
related_issues: "..." # or "none"
# Jira context:
jira_mode: "acli" # or "mcp" or "unavailable"
jira_mcp_prefix: "mcp__atlassian__" # or "mcp__claude_ai_Atlassian__" — only set when jira_mode is "mcp"
existing_jira_ticket: "PROJ-456" # or "none"
existing_jira_summary: "..." # if ticket found
# Sentry CLI context (from Phase 2 probe):
sentry_cli_mode: "available" # or "unavailable" — drives whether /sentry-action automates archive/link or falls back to manual
# Repo context (forwarded from Step 1):
repo_context:
  available: true # or false — pass through exactly as received from sentry-triage
  source_context: # ... same structure as received
# Slack context (forwarded from Step 1):
slack_available: true
slack_findings: "..."
```

This context block is the contract between skills. `/sentry-action` should parse it from `$ARGUMENTS` and execute without re-fetching.
