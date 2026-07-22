---
name: sentry-triage
description: "Triage a Sentry issue: fetch full details, gather Slack context, then chain to deep analysis. Entry point for the 3-skill triage workflow. Use this whenever the user wants to triage, assess, or investigate a Sentry issue — even if they just paste a Sentry URL without saying 'triage'. (Triggers: triage, sentry triage, triage sentry, sentry issue, investigate sentry, assess sentry, oncall triage, sentry url)"
allowed-tools: [Bash, Read, Grep, Glob, mcp__claude_ai_Sentry__get_issue_details, mcp__claude_ai_Sentry__search_issues, mcp__claude_ai_Sentry__get_issue_tag_values, mcp__claude_ai_Sentry__search_issue_events, mcp__claude_ai_Sentry__search_events, mcp__claude_ai_Sentry__get_trace_details, mcp__claude_ai_Sentry__find_projects, mcp__claude_ai_Sentry__find_organizations, mcp__claude_ai_Sentry__whoami, mcp__sentry__get_issue_details, mcp__sentry__search_issues, mcp__sentry__get_issue_tag_values, mcp__sentry__search_issue_events, mcp__sentry__search_events, mcp__sentry__get_trace_details, mcp__sentry__find_projects, mcp__sentry__find_organizations, mcp__sentry__whoami, mcp__claude_ai_Slack__slack_search_channels, mcp__claude_ai_Slack__slack_search_public_and_private, mcp__claude_ai_Slack__slack_read_channel, mcp__claude_ai_Slack__slack_read_thread, AskUserQuestion]
argument-hint: "<sentry-issue-url-or-id>"
---

# Sentry Triage — Step 1: Gather Context

This is the entry point of a 3-skill triage workflow:
1. **`/sentry-triage`** (you are here) — Gather data from Sentry and Slack
2. **`/sentry-analyze`** — Deep analysis, severity classification, action selection
3. **`/sentry-action`** — Execute the chosen action

Given the Sentry issue: `$ARGUMENTS`

If `$ARGUMENTS` is empty or missing, ask the user before proceeding:

**Required** — present via `AskUserQuestion`. Do not attempt to proceed without a Sentry issue URL or ID.

```
AskUserQuestion(
  question: "Which Sentry issue do you want to triage?",
  header: "Sentry Issue Required",
  options: [
    { label: "I'll paste the URL", description: "Provide a Sentry issue URL (e.g., https://sentry.io/organizations/.../issues/...)" },
    { label: "I'll provide an ID", description: "Provide a Sentry issue ID (e.g., PROJECT-123)" }
  ]
)
```

Wait for the user's response before continuing to Phase 0.

## MCP Tool Note

Tool names vary by how MCP servers were registered. This skill references `mcp__claude_ai_Sentry__*` and `mcp__claude_ai_Slack__*` (built-in integrations). If those fail, try `mcp__sentry__*` or `mcp__slack__*` variants — the operations are the same.

## Interaction Policy

@${CLAUDE_PLUGIN_ROOT}/references/interaction-policy.md

---

## Phase 0: Check MCP Availability

### Sentry (Required)

Call `mcp__claude_ai_Sentry__whoami` or `mcp__claude_ai_Sentry__find_organizations` to verify the Sentry MCP is connected.

**If it fails — STOP.** Display this to the user:

> Sentry MCP is not connected. This skill requires it.
>
> Install with: `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp`
>
> Then restart Claude Code and try again.

Do not proceed without Sentry.

### Slack (Optional)

Call `mcp__claude_ai_Slack__slack_search_channels` with `query: "general"` as a lightweight connectivity check. Discard the result — this is only to verify Slack is reachable. If it fails, set a mental note that **Slack is unavailable** — note this in the context you pass forward but continue without it. Slack enriches triage but is not required.

---

## Phase 1: Fetch Sentry Issue

If `$ARGUMENTS` is a full Sentry URL (e.g., `https://sentry.io/organizations/.../issues/...`), pass it directly to the `issueUrl` parameter — the Sentry MCP tools handle URL parsing internally. If it is a short-form issue ID (e.g., `PROJECT-123`), you will also need the `organizationSlug` — call `mcp__claude_ai_Sentry__find_organizations` first to obtain it.

### 1.1 Get Issue Details

Call `mcp__claude_ai_Sentry__get_issue_details` with the URL or ID and extract:

- **Error type** — the exception class (e.g., `RuntimeError`, `ActiveRecord::RecordNotUnique`)
- **Error message** — the full description
- **Project** — name and slug (the slug is needed downstream for `sentry-cli` calls)
- **Platform** — language/framework
- **First seen** / **Last seen** — timestamps
- **Occurrences** — total event count
- **Users affected** — unique user count
- **Status** — unresolved, resolved, ignored
- **Assigned to** — team member or unassigned
- **Tags** — all key-value pairs (environment, release, server, browser, etc.)
- **Sentry numeric ID** — the numeric `id` field (not the short ID like `PROJECT-123`). Required for `sentry-cli` / REST API calls in `/sentry-action`. Read it from the `get_issue_details` response body; as a fallback when the response doesn't include it, parse the trailing numeric segment from the issue URL (`…/issues/{numeric_id}/`).
- **Sentry org slug** — the organization slug (e.g., `cpoms`). Required for the REST API base path in `/sentry-action`. Extract it from the issue URL path (`/organizations/{slug}/issues/…`). For short-form IDs where no URL is available, use the org slug obtained from `find_organizations` in Phase 0.

### 1.2 Get Tag Distributions

Run these in parallel to understand scope:

- `mcp__claude_ai_Sentry__get_issue_tag_values` with `tagKey: environment` — which environments are affected
- `mcp__claude_ai_Sentry__get_issue_tag_values` with `tagKey: release` — which releases contain this error

### 1.3 Get Latest Event with Stacktrace

Call `mcp__claude_ai_Sentry__search_issue_events` to fetch the most recent event. Extract the full stacktrace — this is critical for the analysis phase.

### 1.4 Get Trace Context (if available)

If the latest event includes a `trace_id` in its tags or context, call `mcp__claude_ai_Sentry__get_trace_details` to capture the distributed trace. This reveals upstream/downstream service interactions that may be relevant to root cause analysis. Skip if no trace ID is present.

---

## Phase 1.5: Local Repository Context (Auto-detected)

This phase runs silently and automatically. If any condition is not met, skip the entire phase without user-facing messages and set `repo_context.available: false`.

### Step 1: Check if CWD is a Git Repository

Run via Bash:
```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

If this does not output `true`, skip Phase 1.5 entirely and set `repo_context.available: false`.

### Step 2: Extract File Paths from Stacktrace

Parse the stacktrace fetched in Phase 1.3 to extract application-level file paths and line numbers. Read @${CLAUDE_PLUGIN_ROOT}/references/stacktrace-parsing.md for per-platform extraction rules and regex patterns.

Extract up to 10 application-level frames. Skip vendor/library frames (paths containing `vendor/`, `node_modules/`, `site-packages/`, `gems/`, `.rubies/`, etc. — see the reference for the full skip list).

### Step 3: Check if Files Exist Locally

Get the repo root:
```bash
git rev-parse --show-toplevel
```

For each extracted path, check if it exists relative to the repo root. Use `Read` on `{repo_root}/{stacktrace_path}` — if it returns an error, skip that file. If zero files are found locally, skip the rest of Phase 1.5 and set `repo_context.available: false`.

### Step 4: Read Source Context

For each file that exists locally (up to 5 files, prioritizing the top of the stacktrace), use `Read` with offset and limit to capture approximately 15 lines before and 10 lines after the error line number.

### Step 5: Git History for Affected Files

For up to 3 of the most relevant files (prioritize the file at the top of the stacktrace), run via Bash:

**Recent commits:**
```bash
git log --oneline -5 -- {file_path}
```

**Blame around the error line:**
```bash
git blame -L {line-5},{line+5} -- {file_path}
```

### Step 6: Compile repo_context

Assemble findings into the `repo_context` structure for the YAML output. Omit sub-fields that produced no useful output rather than including empty values.

---

## Phase 2: Gather Slack Context

Skip this phase if Slack is unavailable. Note "Slack context: unavailable" in the output.

If Slack is available, use `mcp__claude_ai_Slack__slack_search_public_and_private` to search for existing team discussion about this issue. Most Sentry issues are discussed in **#eng-cpoms-oncall** — prioritize searching there. Run these searches — skip any that are not applicable (e.g., skip #3 if no release tag was found):

1. **Search for the Sentry URL** — paste the full issue URL as the search query
2. **Search for the error message** — use key terms from the error (not the full message, just distinctive parts)
3. **Search for recent deployments** — if a release tag was found, search for it to find deployment messages

For each result found, read the thread to capture the full discussion context.

If no results are found, note "Slack context: no discussion found."

---

## Phase 3: Chain to Analysis

After gathering is complete, present a brief summary to the user showing what was collected:

```
## Gathered Context

- **Issue**: {title} ({url})
- **Error**: {type}: {message}
- **Project**: {project_name}
- **Occurrences**: {count} | **Users**: {user_count}
- **Status**: {status} | **Assigned**: {assignee}
- **Environments**: {list}
- **Releases**: {list}
- **Slack**: {summary of findings or "No discussion found" or "Unavailable"}
- **Local Repo**: {X of Y stacktrace files found locally, with git history} or "Not in a git repository" or "No stacktrace files matched local files"

Proceeding to analysis...
```

Then invoke `/sentry-analyze` and pass all gathered context as a YAML block with these fields:

```yaml
issue_url: "https://..."
sentry_numeric_id: "6602946670"        # numeric ID — required for sentry-cli / REST API in /sentry-action
sentry_org_slug: "cpoms"               # required for REST API base path in /sentry-action
issue_title: "..."
error_type: "RuntimeError"
error_message: "..."
project: "project-slug"                # used as the --project arg for sentry-cli
platform: "ruby"
first_seen: "2026-03-15T10:00:00Z"
last_seen: "2026-03-20T14:30:00Z"
occurrences: 1234
users_affected: 56
status: "unresolved"
assignee: "Jane Doe" # or "unassigned"
tags:
  environment: "production"
  release: "v2.3.1"
  server_name: "web-01"
  # ... all other tags
environments: ["production", "staging"]
releases: ["v2.3.1", "v2.3.0"]
stacktrace: |
  ... full stacktrace from latest event ...
trace_context: "... distributed trace summary ..." # or "none" if no trace_id
repo_context:
  available: true # or false — if false, no other fields are present
  source_context: # only when available is true
    - file: "app/models/user.rb"
      line: 45
      snippet: |
        ... source lines around the error ...
      recent_commits:
        - "a1b2c3d Fix validation edge case (2 days ago)"
        - "e4f5g6h Add model constraints (1 week ago)"
      blame_excerpt: |
        ... git blame output for lines around the error ...
    # ... up to 5 files
slack_available: true # or false
slack_findings: "... summary of threads/deployment messages ..." # or "none" or "unavailable"
```

This context block is the contract between skills. The next skill should parse it from `$ARGUMENTS` and work from it without re-fetching.
