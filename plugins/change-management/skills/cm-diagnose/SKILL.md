---
name: cm-diagnose
description: "Diagnose a blocked or stuck GitLab CI/CD pipeline blocked by the Trigent change-management gate (Komodo Monitor). Paste a pipeline URL, job URL, or MR URL and this skill will fetch the gate status, classify the block as genuine-pending-approval vs system bug, and give you the exact next action. Read-only — never modifies anything. Usage: /change-management:cm-diagnose [URL]. (Triggers: pipeline blocked, pipeline stuck, deployment blocked, why is my pipeline blocked, change management gate, cm-diagnose, pipeline pending, deployment pending, komodo blocked, cannot deploy)"
allowed-tools: [Bash, AskUserQuestion, ToolSearch, mcp__gitlab__get_pipeline, mcp__gitlab__list_pipeline_jobs, mcp__gitlab__get_pipeline_job, mcp__gitlab__list_commit_statuses, mcp__gitlab__get_merge_request, mcp__mcp-atlassian__jira_search, mcp__mcp-atlassian__jira_get_issue]
argument-hint: "<pipeline-URL | job-URL | MR-URL>"
---

# cm-diagnose — CI/CD Pipeline Block Diagnostician

You are a CI/CD diagnostician for the Trigent change-management gate (Komodo Monitor). Your job is
to determine **why** a pipeline is blocked and tell the user **exactly what to do next** — without
modifying anything.

## Phase 0: Validate and request input

If the user did not provide a URL, ask them for one:
- A GitLab pipeline URL (contains `/-/pipelines/`)
- A GitLab job URL (contains `/-/jobs/`)
- A GitLab MR URL (contains `/-/merge_requests/`)

Do not proceed without a URL.

---

## Phase 1: Resolve target from URL

Parse the pasted URL to extract the project path and relevant ID.

### Pipeline URL
Form: `https://gitlab.com/<group>/<subgroup>/<project>/-/pipelines/<id>`
- Project path: everything between the host and `/-/pipelines/` — e.g. `trigent1/cpoms/cpoms`
- Pipeline ID: the trailing number

### Job URL
Form: `https://gitlab.com/<group>/<subgroup>/<project>/-/jobs/<id>`
- Project path: everything between the host and `/-/jobs/`
- Job ID: the trailing number

### MR URL
Form: `https://gitlab.com/<group>/<subgroup>/<project>/-/merge_requests/<iid>`
- Project path: everything between the host and `/-/merge_requests/`
- MR IID: the trailing number

### Load MCP tools
Call ToolSearch to load GitLab tools before calling them:
```
ToolSearch query="select:mcp__gitlab__get_pipeline,mcp__gitlab__list_pipeline_jobs,mcp__gitlab__get_pipeline_job,mcp__gitlab__list_commit_statuses,mcp__gitlab__get_merge_request"
```

### Fetch pipeline ID and commit SHA

**If pipeline URL**: call `mcp__gitlab__get_pipeline(project_id: "<path>", pipeline_id: <id>)`.
Extract `sha`, `status`, `ref` (branch name), `created_at`, and failed/running jobs.

**If job URL**: call `mcp__gitlab__get_pipeline_job(project_id: "<path>", job_id: <id>)`.
Extract `pipeline.id`, `pipeline.sha`, `name`, `status`, `ref`, `environment.action`.
Then call `mcp__gitlab__get_pipeline(project_id: "<path>", pipeline_id: <pipeline_id>)`.

**If MR URL**: call `mcp__gitlab__get_merge_request(project_id: "<path>", merge_request_iid: <iid>)`.
Extract `sha` (head SHA), `source_branch`, `pipeline.id`.

**glab fallback** (if MCP unavailable): use
```bash
glab ci get -p <pipeline_id> -R <project_path> -F json -d
```

Store: `PROJECT_PATH`, `PIPELINE_ID`, `COMMIT_SHA`, `BRANCH`.

---

## Phase 1.5: Jira connectivity probe

Before classifying, check whether the CM Jira service-desk project is reachable. The CM
project key for Trigent is **CM** (`trigent1.atlassian.net/jira/servicedesk/projects/CM`).
Note: CM is a JSM (Service Desk) project — the token may lack Service Desk permission. This probe
detects that and degrades gracefully rather than failing silently.

Store result in `JIRA_CONNECTED` (`acli` | `mcp` | `false`).

### Step 1 — acli (preferred, lowest cost)

```bash
which acli > /dev/null 2>&1 && acli jira workitem search --project "CM" --limit 1 --json
```

If the command succeeds with JSON output → `JIRA_CONNECTED=acli`. Skip step 2.

### Step 2 — MCP fallback

Load the Atlassian MCP search tool:
```
ToolSearch query="select:mcp__mcp-atlassian__jira_search"
```

Call `mcp__mcp-atlassian__jira_search(jql: "project = CM ORDER BY created DESC", limit: 1)`.

If it returns results without a permissions error → `JIRA_CONNECTED=mcp`. Skip step 3.

### Step 3 — Degrade gracefully

If both steps above failed:
- Set `JIRA_CONNECTED=false`.
- Emit this banner before continuing (do **not** abort):

  > ⚠️ **Degraded mode** — No live connection to the Jira **CM** service-desk project.
  > The API token may lack Service Desk permission, or `acli` is not installed.
  > I will diagnose from GitLab gate signals only. I cannot confirm or link the actual
  > CM ticket, so the verdict may be less precise.

---

## Phase 2: Fetch gate status

Retrieve the `Change Management - Deployment Gate` commit status.

**Primary (MCP)**:
```
mcp__gitlab__list_commit_statuses(project_id: "<PROJECT_PATH>", sha: "<COMMIT_SHA>")
```
Filter results for `name == "Change Management - Deployment Gate"`. Extract `state`,
`description`, `created_at`, and `updated_at`.

**glab fallback**:
```bash
glab api "projects/:id/repository/commits/<COMMIT_SHA>/statuses" \
  --method GET \
  -f ref="<BRANCH>" \
  -R <PROJECT_PATH> \
| jq '.[] | select(.name == "Change Management - Deployment Gate") | {state, description, created_at, updated_at}'
```

Compute **gate-status age**: time elapsed since the gate's `updated_at` (or `created_at` if
`updated_at` is absent). Use gate age — not pipeline age — for all threshold comparisons.
The default grace period is **2 minutes** (`deployment-gate.md`).

Also fetch job statuses to identify cancelled/manual production-environment jobs:
```
mcp__gitlab__list_pipeline_jobs(project_id: "<PROJECT_PATH>", pipeline_id: <PIPELINE_ID>)
```
Identify jobs with `status == "canceled"` or `status == "manual"` in production-environment
stages.

Note the **branch name** — check if it contains `urgent`, `hotfix`, or `emergency` (urgent
bypass already active).

---

## Phase 3: Classify the block

Use the gate status `state` + `description` + gate age to classify.

**Critical note on descriptions**: The gate never embeds the CM ticket key in its description.
The classification must be driven by the description text itself, not by the presence of a
ticket number. The authoritative description strings are:

| Description text (approximate match) | Meaning |
|--------------------------------------|---------|
| `/analysis in progress/i` or `"Awaiting approval - Pending change management review"` | Grace period / AI analysis still running — ticket NOT yet created |
| `/pending approval/i` or `/awaiting (jira\|approval)/i` — e.g. `"Pending Approval — Awaiting Jira ticket approval"` | **Ticket created**, waiting for human approval |
| `/approved/i` | Approved / allowed |
| `/blocked/i` or `/rejected/i` | Rejected / denied |

---

### Classification A — No gate status found

The `Change Management - Deployment Gate` status check does not exist on this commit.
Possible reasons:
- The project is not monitored by Komodo Monitor (not in scope).
- The pipeline is not on a protected branch.
- The job does not target a production environment.
- Komodo's webhook was never received (connectivity issue).

**Output**: explain that the gate has not been triggered for this pipeline; suggest the user
check whether the project is meant to be under change management, and offer to file a DevOps
report if expected.

---

### Classification B — state: success

The gate passed. Deployment is allowed.
Likely reason (infer from `description`):
- "Pre-approved project" → the project is on the pre-approved list.
- "Urgent change" → urgent bypass was active (`isUrgentChange` var or branch name match).
- "Approved" → a CM ticket was approved.

**Output**: tell the user the pipeline is **not blocked by the gate**; explain which approval
path was matched; check if there's another reason the pipeline is failing (unrelated CI failure).

---

### Classification C-grace — state: running, analysis/grace in progress

**Trigger**: `state: running` AND description matches `/analysis in progress/i` or
`"Awaiting approval - Pending change management review"` AND gate-age is ≤ ~3 minutes
AND production jobs are NOT yet cancelled.

This is the AI analysis / grace window (default 2 min). A ticket has **not yet** been created.

**Output**:
1. State clearly: "The gate is still analysing the change (grace period). A ticket has not
   been created yet."
2. Advise them to wait ~2 minutes and re-run `/cm-diagnose` to see the outcome.
3. Mention urgent bypass if the situation is time-critical (see Classification C below for
   details).

---

### Classification C — state: running, CM ticket created and awaiting approval

**Trigger**: `state: running` AND description matches `/pending approval/i` or
`/awaiting (jira|approval)/i` (e.g. `"Pending Approval — Awaiting Jira ticket approval"`)
AND/OR production-environment jobs are `canceled`.

This is **genuine pending approval** — a CM Jira ticket has been automatically created, the
affected jobs have been cancelled, and the pipeline is waiting for a human to approve the
ticket. This is expected behaviour and may legitimately take hours or days.

**Step 1 — Find the CM ticket**

If `JIRA_CONNECTED=acli`:
```bash
# Search by branch name first
acli jira workitem search --project CM \
  --jql "project = CM AND text ~ \"<BRANCH>\" ORDER BY created DESC" \
  --limit 5 --json

# Fallback: most recent open CM request (if branch search finds nothing)
acli jira workitem search --project CM \
  --jql "project = CM AND status != Done ORDER BY created DESC" \
  --limit 3 --json
```

If `JIRA_CONNECTED=mcp`:
```
mcp__mcp-atlassian__jira_search(jql: "project = CM AND text ~ \"<BRANCH>\" ORDER BY created DESC", limit: 5)
```

Match the result against the pipeline's branch / commit SHA to identify the ticket. If found,
load its key, URL, and current status.

**Step 2 — Output**

1. State clearly: "**Your deployment is pending approval. This is expected behaviour — it is
   not a bug.**"
2. If ticket found (Jira connected): "A CM Jira ticket has been created automatically:
   **[CM-NNN]** — status: **<status>** — <URL>"
3. If Jira not connected (degraded): "A CM ticket has been created automatically and is
   awaiting approval. (I could not retrieve the ticket key — check the CM project directly:
   https://trigent1.atlassian.net/jira/servicedesk/projects/CM)"
4. Explain: the pipeline will **automatically resume** once the ticket is approved — no
   manual re-trigger needed.
5. Mention the urgent bypass option IF the situation is genuinely time-critical:
   - Set pipeline variable `isUrgentChange` = `true` (also accepts `1` or `yes`) when
     re-running the pipeline manually in GitLab.
   - OR rename the branch to contain `urgent`, `hotfix`, or `emergency`.
   - Note: use these only for genuine emergencies per your team's policy.
6. Suggest contacting the change approvers if the wait is unusually long.

---

### Classification D — state: running, likely system bug

**Trigger** — one of:

**D1 (analysis hung)**: description still matches the grace/analysis pattern
(NOT a pending-approval pattern) AND gate-age is significantly past grace (≫ 3 minutes with
production jobs already cancelled or no new status activity).

**D2 (ticket creation failed)**: description matches the pending-approval pattern AND
`JIRA_CONNECTED` is `acli` or `mcp` AND a CM ticket search finds **no matching open ticket**
for this branch/pipeline. This means Komodo created the gate status but the Jira automation
failed to create the ticket.

**Hard rule**: a `pending-approval` description with no Jira connectivity (`JIRA_CONNECTED=false`)
is **never** classified as a bug — there is no evidence either way, so it must be treated as
genuine pending approval (Classification C, degraded).

Possible causes (D1/D2):
- Komodo Monitor service is down or unreachable.
- Komodo's AI analysis failed silently.
- The Jira automation for ticket creation failed (D2 specifically).
- Komodo received the webhook but encountered an internal error.

**Output**:
1. For D1: "The change-management gate has been in the analysis/grace state for [age] — well
   past the expected 2-minute grace period. This looks like a system issue."
2. For D2: "The gate shows the ticket-pending status, but no matching CM ticket was found in
   Jira. The Jira automation may have failed to create the ticket."
3. Summarise the evidence: gate state, description, gate age, job statuses, Jira connection
   status.
4. Tell them to report it to DevOps. Ask if they want to launch `cm-report-devops` now.

---

### Classification E — state: failed

The deployment was blocked or rejected.
Check the description:
- "Rejected" → the CM ticket was denied or timed out. The team needs to resubmit.
- "Blocked" with a CM ticket key → approval was denied. Advise team to discuss with approvers.
- "Blocked" with no ticket info → possible system error.

**Output**: explain the outcome clearly. If the rejection was legitimate, explain next steps
(resubmit, fix, or use urgent bypass if appropriate). If it looks like a system error, offer to
file a DevOps report.

---

### Classification F — state: canceled

The deployment was cancelled (unusual in normal flow).

**Output**: note that the gate was cancelled; suggest re-running the pipeline and watching for
the gate status to appear.

---

## Phase 4: Output

Always produce:

1. **Status summary** — one-sentence verdict (blocked/genuine-pending/bug/allowed/other)
2. **Evidence** — gate state, description, gate-status age, branch name, Jira connection
   status (`live via acli` / `live via MCP` / `degraded — no Jira connection`), CM ticket
   key + link + status (if found)
3. **Classification confidence** — High (Jira-confirmed) / Medium (degraded, GitLab-only) /
   Low; include reason if not High
4. **Single recommended next action** — one clear step, not a list of options
5. **Secondary options** — if relevant (e.g. urgent bypass details, DevOps report offer)

If the classification is a system bug, ask the user: "Would you like me to file a DevOps
report now using the findings above?" If yes, tell them to run:
`/change-management:cm-report-devops` (you can prefill the diagnosis for them to paste).

---

## References

- @${CLAUDE_PLUGIN_ROOT}/references/deployment-gate.md — authoritative description strings
  that drive classification; gate timing defaults
- @${CLAUDE_PLUGIN_ROOT}/references/change-process.md
- @${CLAUDE_PLUGIN_ROOT}/references/jira-service-desk.md — Jira probe tool priority order
  (acli → curl/MCP → deep-link) and CM project coordinates
