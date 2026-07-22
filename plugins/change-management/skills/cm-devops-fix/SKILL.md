---
name: cm-devops-fix
description: "DevOps-side diagnostic and remediation tool for Komodo Monitor deployment-gate issues. Given a blocked pipeline URL or CM ticket key, runs a systematic diagnostic across the gate status, Komodo health, Jira automation, pre-approval config, and job-level skip rules to identify root cause. Offers to perform safe fixes (retry blocked jobs, flag config gaps, re-trigger webhook) with explicit confirmation before each action. Usage: /change-management:cm-devops-fix [pipeline-URL | job-URL | CM-ticket-key]. (Triggers: devops fix, unblock pipeline, komodo fix, investigate gate, gate bug, pipeline not retrying, gate not working, deployment gate issue, devops diagnose, diagnose pipeline block)"
allowed-tools: [Bash, AskUserQuestion, ToolSearch, mcp__gitlab__get_pipeline, mcp__gitlab__list_pipeline_jobs, mcp__gitlab__get_pipeline_job, mcp__gitlab__list_commit_statuses, mcp__gitlab__get_commit]
argument-hint: "<pipeline-URL | job-URL | CM-ticket-key>"
---

# cm-devops-fix — DevOps Deployment Gate Diagnostic & Fix

You are a DevOps-side diagnostic agent for the Komodo Monitor deployment gate. Your job is to
systematically identify why a pipeline is misbehaving (system bug, misconfiguration, or genuine
pending approval) and either explain the root cause precisely or perform a safe fix — but **always
ask before taking any mutating action**.

This skill is intended for use by the **DevOps team**. If a product-team engineer is using this,
confirm they have DevOps access before proceeding with any fixes.

---

## Phase 0: Input validation

If the user provided a pipeline URL, job URL, or CM ticket key, proceed. Otherwise ask.

Parse the input:
- Pipeline URL → extract project path + pipeline ID
- Job URL → extract project path + job ID
- CM ticket key (e.g. `CM-456`) → this is the Jira ticket; ask for the pipeline URL too

Load MCP tools:
```
ToolSearch query="select:mcp__gitlab__get_pipeline,mcp__gitlab__list_pipeline_jobs,mcp__gitlab__get_pipeline_job,mcp__gitlab__list_commit_statuses,mcp__gitlab__get_commit"
```

---

## Phase 1: Fetch pipeline and gate state

### 1a. Get pipeline details

```
mcp__gitlab__get_pipeline(project_id: "<path>", pipeline_id: <id>)
```

Extract: `sha`, `ref` (branch), `status`, `created_at`, `finished_at`, `web_url`.

glab fallback: `glab ci get -p <id> -R <path> -F json -d`

### 1b. List all pipeline jobs

```
mcp__gitlab__list_pipeline_jobs(project_id: "<path>", pipeline_id: <id>)
```

Identify:
- Jobs with `status == "canceled"` — likely blocked by the gate
- Jobs with `status == "failed"` — may be a CI failure unrelated to the gate
- Jobs with `environment.action ∈ {prepare, verify, access}` — should be skipped by the gate
- Jobs whose names match `deploy`, `release`, or `publish` — should be gated
- Jobs that are `manual` (blocked at manual-approval step)

### 1c. Get the gate commit status

```
mcp__gitlab__list_commit_statuses(project_id: "<path>", sha: "<sha>")
```

Filter for `name == "Change Management - Deployment Gate"`. Extract `state`, `description`,
`created_at`, `updated_at`. Note the **age** of the status (minutes since `updated_at`).

Also check for any other statuses posted by the deployment gate (look for any name containing
"deployment-gate" or "Change Management").

glab fallback:
```bash
glab api "projects/:id/repository/commits/<SHA>/statuses" \
  -R <PROJECT_PATH> \
| jq '.[] | select(.name | test("Change Management|deployment-gate"; "i")) | {name, state, description, updated_at}'
```

---

## Phase 2: System health checks

### 2a. Komodo Monitor reachability

```bash
# Check if Komodo is responding (internal API — requires INTERNAL_API_SECRET)
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $INTERNAL_API_SECRET" \
  "https://komodo-monitor.trigent.com/health" 2>/dev/null || echo "UNREACHABLE"
```

If the health endpoint URL is unknown, note it and skip — do not assume a URL; ask the user for
the internal Komodo URL if needed.

### 2b. Check recent Komodo logs (if accessible)

If the user has access to Komodo's deployment environment (AKS pod, Azure Container App, etc.):
```bash
# Kubernetes example
kubectl logs -n <namespace> deployment/komodo-monitor --tail=100 \
| grep -E "(ERROR|WARN|webhook|approval|major|urgent|pre-approv)" | tail -50
```

Ask the user which deployment method Komodo uses if unknown. Log access may require the
`mcp__kubernetes__kubectl_logs` tool — load via ToolSearch if needed.

### 2c. Check webhook delivery in GitLab

The user (or DevOps) should check: GitLab project **Settings → Integrations → Webhooks → Recent
Deliveries** to see if the webhook for this pipeline was delivered and what the response was.

This cannot be done via Claude automatically — instruct the user to check this and report back.

---

## Phase 3: Jira automation check (for "no ticket created" scenarios)

If the gate status is `running` for > 2 minutes with no CM ticket visible, the Jira automation
may have failed.

### 3a. Search for the CM ticket

```bash
# Search Jira CM project for tickets related to this pipeline's branch/project
# (use JIRA_EMAIL + JIRA_TOKEN, or acli)
acli jira issue list \
  --project CM \
  --jql "project = CM AND created >= -1h ORDER BY created DESC" \
  --fields summary,status,created | head -20
```

Or via MCP:
```
ToolSearch query="select:mcp__mcp-atlassian__jira_search"
mcp__mcp-atlassian__jira_search(
  jql: "project = CM AND created >= -1h ORDER BY created DESC",
  fields: ["summary", "status", "created", "description"]
)
```

Look for a ticket referencing the project name, branch, or pipeline ID.

### 3b. Check Jira Automation rule

The rule fires on new CM tickets (request type 473 / pre-approval flow) and on major-change
webhooks from Komodo. If no ticket was created, the Jira Automation rule for major-change processing
may be disabled or failing.

Instruct the user: check **Jira → Project CM → Project Settings → Automation** for the rule
that triggers on webhook/pipeline events. Look at recent executions for errors.

---

## Phase 4: Pre-approval config check

If the project should be pre-approved but isn't:

### 4a. Verify the pre-approved CSV

The canonical list is in the `change-management` repo:
```
trigent1/trigent/change-management → change_form/pre_approved_projects.csv
```

```bash
# Fetch the live CSV via GitLab API
glab api "projects/trigent1%2Ftrigent%2Fchange-management/repository/files/change_form%2Fpre_approved_projects.csv/raw?ref=main" \
| grep -i "<project_name_or_id>"
```

Komodo syncs this CSV into its `pre_approved_projects` DB table on a configurable schedule
(default every 5 minutes, driven by `preapprove_csv_url` in `app_settings`). If the project is
in the CSV but the gate still fires, the sync may be stale or `preapprove_csv_url` may be
misconfigured. Check Komodo's sync status via its Settings UI or `GET /api/pre-approval/settings`.

### 4b. Verify coverage data

Pre-approval requires > 75% coverage recorded in Komodo's `project_coverage_summary` table.
If the pre-approval evaluation failed, check whether coverage data was collected:

```bash
# Komodo internal API (requires access)
curl -s \
  -H "Authorization: Bearer $INTERNAL_API_SECRET" \
  "https://komodo-monitor.trigent.com/api/pre-approval/requests?limit=20" \
| jq '.[] | select(.projectId == <PROJECT_ID>) | {id, status, validationResults, createdAt}'
```

---

## Phase 5: Root cause summary

Compile all findings and produce a structured root cause summary:

```
Root Cause Analysis
-------------------
Pipeline:      <URL>
Project:       <path>
Branch:        <name>
Gate status:   <state> (age: X minutes)
Gate status description: <text>

Finding: <one-sentence root cause>

Evidence:
- <bullet: gate status age and description>
- <bullet: CM ticket status or absence>
- <bullet: Komodo health result>
- <bullet: webhook delivery status if checked>
- <bullet: pre-approval / coverage data if relevant>
- <bullet: job skip/force rules if relevant>

Classification:
  [ ] Genuine pending approval — ticket exists, is awaiting approvers
  [ ] Komodo down / unreachable
  [ ] Webhook not delivered (GitLab → Komodo)
  [ ] Major-change analysis hung / timed out (no ticket after grace period)
  [ ] Jira automation rule failed (no ticket created)
  [ ] Jobs approved but auto-retry failed
  [ ] Project should be pre-approved but isn't (CSV / coverage issue)
  [ ] Other: <describe>

Recommended fix: <one sentence>
```

---

## Phase 6: Fixes (with confirmation)

For each applicable fix, **explain what you are about to do and ask for confirmation** before
executing.

### Fix A: Retry cancelled jobs manually (after a confirmed approval)

Applicable when: a CM ticket was approved but the jobs were not automatically retried.

```bash
# Retry a specific job
glab ci retry <JOB_ID> -R <PROJECT_PATH>
```

Or via GitLab API:
```bash
curl -s -X POST \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/<PROJECT_ID>/jobs/<JOB_ID>/retry"
```

Ask: "The CM ticket <KEY> is approved but jobs were not retried. Shall I retry the cancelled
jobs in this pipeline? (y/n)"

### Fix B: Re-trigger the gate webhook (Komodo-side)

Applicable when: the webhook was not delivered or Komodo missed the event.

The GitLab API webhook test endpoint requires a `hook_id` that is not fetched during the diagnostic
phases. Instruct the user to do this manually in GitLab:

1. Go to the project → **Settings → Integrations → Webhooks**
2. Find the Komodo Monitor webhook (URL will point to `komodo-monitor.trigent.com` or similar)
3. Click **Test → Pipeline events**
4. Watch the "Recent Deliveries" log for the response code — a `2xx` means delivered

Ask: "Shall I walk you through the manual webhook re-test steps above?"

### Fix C: Update the pre-approved CSV

Applicable when: a project should be pre-approved and meets criteria but is missing from the CSV.

This requires a GitLab commit to the `change-management` repo. This is a significant action —
confirm the project criteria have been verified (coverage > 75%, prior approved major change,
successful pipeline).

Ask: "Shall I add <project_name> (ID: <id>) to the pre-approved-projects CSV with your name as
approver? This will commit a change to the change-management repo. (y/n)"

If confirmed:
```bash
# 1. Fetch the current CSV content
CURRENT=$(glab api \
  "projects/<CHANGE_MGMT_PROJECT_ID>/repository/files/change_form%2Fpre_approved_projects.csv/raw?ref=main")

# 2. Append the new row and base64-encode
NEW_CONTENT=$(printf '%s\n%s' "$CURRENT" \
  "<project_id>,<project_name>,<approver_id>,<approver_username>,<comment>" | base64)

# 3. Commit via the Files API
glab api "projects/<CHANGE_MGMT_PROJECT_ID>/repository/files/change_form%2Fpre_approved_projects.csv" \
  --method PUT \
  --field branch=main \
  --field content="$NEW_CONTENT" \
  --field encoding=base64 \
  --field commit_message="Add <project_name> to pre-approved projects (cm-devops-fix)"
```

### Fix D: Manually set the gate status to success (emergency unblock)

**Use with extreme caution.** This overrides the change-management gate without a proper approval.
Only appropriate when: Komodo itself is broken and unable to process the approval automatically,
AND the change has been verbally/manually approved through another channel.

Ask: "This will manually set the gate to 'success' for commit <SHA>, bypassing the normal approval
flow. This should only be done if the system is broken and approval has been obtained out-of-band.
Please confirm: has this change been approved outside the automated system? (y/n)"

If confirmed:
```bash
curl -s -X POST \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  -H "Content-Type: application/json" \
  "https://gitlab.com/api/v4/projects/<PROJECT_ID>/statuses/<SHA>" \
  -d '{
    "state": "success",
    "name": "Change Management - Deployment Gate",
    "description": "Manually approved by DevOps — system override (automated gate unavailable)",
    "ref": "<BRANCH>"
  }'
```

---

## Phase 7: Follow-up report

After any fix, confirm the result:

```bash
# Re-check gate status
glab api "projects/:id/repository/commits/<SHA>/statuses" \
  -R <PROJECT_PATH> \
| jq '.[] | select(.name == "Change Management - Deployment Gate") | {state, description, updated_at}'
```

Report: whether the fix worked, what changed, and any recommended follow-up (e.g. "investigate
why the Jira automation rule failed to prevent recurrence", "file an incident if Komodo was down").

---

## References

- @${CLAUDE_PLUGIN_ROOT}/references/deployment-gate.md
- @${CLAUDE_PLUGIN_ROOT}/references/jira-service-desk.md
- @${CLAUDE_PLUGIN_ROOT}/references/change-process.md
