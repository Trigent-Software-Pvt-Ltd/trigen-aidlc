# Komodo Monitor — Deployment Gate: Verified Technical Reference

> **Source of truth**: `trigent1/devsecops/gitlab-monitor@main`, verified against
> `src/services/deploymentGate.ts` (enforcement) and `src/services/deploymentGateService.ts`
> (config defaults). The published Komodo docs (`docs/DEPLOYMENT_GATE_WORKFLOW.md`,
> `docs/DEPLOYMENT_GATE_CONFIGURATION.md`) contain inaccuracies noted below. **Always prefer this
> document over the Confluence/GitLab docs when they conflict.**

---

## What the deployment gate does

Komodo Monitor (formerly "GitLab Monitor") is a webhook-driven service that receives GitLab pipeline
and job events and enforces a change-management approval policy before production deployments proceed.

It does **not** use GitLab pipeline rules to block jobs. It uses GitLab **commit status checks**:
- It posts a status against the commit SHA on the branch.
- GitLab protected-branch settings require that status to pass before the pipeline can continue.

---

## GitLab commit status name (⚠️ doc inaccuracy)

The live enforcement code posts statuses under the name:

```
Change Management - Deployment Gate
```

The published config docs refer to `deployment-gate/blocked` and `deployment-gate/approved` as the
required protected-branch status-check context names. **These strings do not appear in the
enforcement code.** Anyone configuring required status checks must use
`Change Management - Deployment Gate`, not the strings from the config doc.

The helper service (`deploymentGateService`) uses `name: 'deployment-gate'` for a separate status
utility — this is not the per-pipeline enforcement path.

### Status states emitted by the enforcement path

| State | Meaning | Example description |
|-------|---------|---------------------|
| `success` | Deployment allowed | "Approved - Pre-approved project - Deployment allowed" / "Approved - Urgent change - Deployment allowed" |
| `running` | Grace period active, or awaiting Jira approval | "Awaiting approval - Pending change management review" |
| `failed` | Blocked / Rejected | "Blocked - Major change requires approval" / "Rejected - Change denied or approval timed out" |
| `canceled` | Deployment cancelled by system | |

---

## Approval hierarchy (first match wins)

### 1. Pre-approved project

The system maintains an in-memory set of pre-approved GitLab **project IDs** (integer), synced
periodically (default every 5 minutes) into Komodo's `pre_approved_projects` DB table from a
configurable CSV URL stored as `preapprove_csv_url` in Komodo's `app_settings` table.

**Canonical CSV location** (the source of truth for the pre-approved list):
```
trigent1/trigent/change-management  →  change_form/pre_approved_projects.csv
```
URL: `https://gitlab.com/trigent1/trigent/change-management/-/blob/main/change_form/pre_approved_projects.csv`

CSV columns: `project_id,project_name,approver_id,approver_user_name,comment`

Komodo fetches this file via the GitLab API (converting blob URLs to raw API URLs), authenticating
with the `gitlab_personal_token` from `app_settings`. The sync interval and CSV URL are both
runtime-configurable via Komodo's Settings UI or `PUT /api/settings`.

Other pre-approval mechanisms:
- Time-limited **temp-approved projects** (DB table `temp_approved_projects`, field `expires_at`)
  — an **undocumented standing bypass** not mentioned in the Komodo workflow docs. Added via the
  `/api/temp-approved` endpoint or the Komodo "temp-approved" UI.

If the project ID is in the set → commit status set to `success`, deployment proceeds.

### 2. Urgent change bypass

Two independent mechanisms; either triggers the bypass:

**a) Pipeline variable (case-insensitive key match)**

| Field | Value |
|-------|-------|
| Variable key | `isUrgentChange` (matched as `v.key.toLowerCase() === 'isurgentchange'`) — case-insensitive; `ISURGENTCHANGE`, `IsUrgentChange` etc. all work |
| Variable value | `true`, `1`, or `yes` (lowercased before matching) |

Set in GitLab via CI/CD → Pipelines → Run Pipeline → Variables, or in the `.gitlab-ci.yml`
`variables:` block for the pipeline/job.

⚠️ The DB config field `urgent_variable_name` is declared but **never read** by the enforcement
code — the key `isurgentchange` is hardcoded and is not configurable in practice.

**b) Branch naming (case-insensitive substring match)**

Default branch-pattern words (DB config `urgent_branch_patterns`): `urgent`, `hotfix`, `emergency`

Matching: a branch name is an urgent bypass if it **contains** any of these words as a
case-insensitive substring.

⚠️ **Doc inaccuracy**: the workflow doc states `hotfix/*` and `emergency/*` as glob patterns. The
code uses substring match, not globs. This means:
- `hotfix/my-fix` ✅ (contains "hotfix")
- `my-hotfix` ✅ (contains "hotfix")
- `EMERGENCY-123` ✅ (contains "emergency")
- A branch starting with `^` or containing `*` is treated as a regex (configurable).

**Outcome of urgent bypass**: commit status set to `success`, description "Approved - Urgent change
- Deployment allowed", previously blocked jobs are automatically retried.

### 3. Major-change detection (the common block path)

If neither pre-approval nor urgent bypass applies, the system proceeds through major-change analysis:

1. **Grace period** (default **2 minutes**, configurable via DB `grace_period_minutes`, polled every
   10 seconds). During this period the commit status is `running` / "Analysis in progress". This
   window allows developers to intervene (e.g. re-trigger with `isUrgentChange` variable) if the
   pipeline was flagged incorrectly for a critical fix.

2. **AI analysis** after grace period determines if the change is a major change.
   Alternatively, a `isMajorChange` pipeline variable (case-insensitive, same mechanism as
   `isUrgentChange`) forces the major-change path immediately.

3. **If major change detected**:
   - A Jira ticket is automatically created in the configured change-management project.
   - Affected jobs are **cancelled**.
   - Commit status set to `running` / "Pending Approval — Awaiting Jira ticket approval".

4. **Jira polling**: the system continuously monitors the Jira ticket status.
   - Ticket **approved** → commit status set to `success`, cancelled jobs are **automatically retried**.
   - Ticket **denied** or **timed out** → commit status set to `failed` / "Rejected".

5. **Approved-SHA auto-approve**: if a commit SHA was previously approved as `change_type='major'`,
   future deployments of that exact SHA are auto-approved without re-analysis (urgent-change approvals
   are deliberately excluded from this shortcut).

**Jira ticket project key**: the ticket-match regex is `^<jira_project_key>-\d+$` (case-insensitive).
The code-default key is `TSCM`. The Trigent org change-management project is **CM**
(`trigent1.atlassian.net/jira/servicedesk/projects/CM`) — so the deployed configuration likely
sets this to `CM`, but it is config-driven. Use the Komodo gate configuration (`/api/settings`) to
resolve the active key at runtime rather than hardcoding either value.

---

## Job-level gate skip logic

Not every job in a pipeline is evaluated by the gate. A job is **skipped** (gate bypassed for that
job) if:

- `environment.action` is one of: `prepare`, `verify`, `access`
- The job name matches any pattern in `excluded_job_name_patterns` (DB config, CSV of regex patterns,
  default empty)

A job is **forced into the gate** (even if environment name doesn't look like production) if the
job name matches `deploy_override_patterns` (DB config, default: `deploy`, `release`, `publish`).

This is why some jobs in a pipeline appear blocked while others proceed — they are evaluated
individually against the skip/force rules and the project's production-environment classification.

---

## Initial filtering (who gets gated at all)

Before the approval hierarchy runs, a pipeline/job must pass all of:

1. **Project scope check** — the project is configured to be monitored (in the Komodo project list).
2. **Protected branch check** — the pipeline is running on a configured protected branch
   (e.g. `main`, `master`, `release/*`).
3. **Production environment check** (job webhooks only) — the job's target environment is classified
   as `production`. Only production-targeted jobs proceed through the gate.

---

## Pre-approval eligibility (how a project gets onto the pre-approved list)

Teams submit a **Pre-Approval Eligibility Request** via JSM portal:
- Request type **473** in the change-management service-desk project.
- A Jira Automation rule detects the new ticket and calls Komodo's `POST /api/pre-approval/evaluate`.
- Komodo evaluates three criteria (all must pass):
  1. Code coverage in the project's latest coverage summary: **> 75%**
  2. At least one prior **approved major change** in Komodo's `approval_requests` for this project
  3. At least one **successful pipeline run** recorded in Komodo's `gitlab_pipelines`
- If approved: project added to `change_form/pre_approved_projects.csv` in the `trigent1/trigent/change-management` repo, pre-approved list synced.
- If rejected: comment posted listing every failed criterion.

---

## What to check when a pipeline looks "stuck"

Genuine pending-approval block:
- Commit status `Change Management - Deployment Gate` = `running`
- A CM-NNN (or TSCMn-NNN) Jira ticket exists, is open / pending approval

Likely system bug (no genuine block):
- Status `running` for **> 2 minutes** with **no Jira ticket** created
- Status `failed` but team believes the change was approved / no denial comment
- Jobs approved via Jira but **not retried** automatically
- Project should be pre-approved (in `change_form/pre_approved_projects.csv` in the change-management repo) but status check still fires — may be a sync failure or stale cache
- Coverage-check failures when coverage tooling has changed
- Komodo Monitor service unreachable or returning errors
- Jira Automation rule not firing on new CM tickets (webhook/rule disabled)
- Webhook not delivered from GitLab (check GitLab project Settings → Integrations → Webhooks logs)

---

## Useful references

- Komodo Monitor repo: `trigent1/devsecops/gitlab-monitor`
- Komodo docs (partially inaccurate — prefer this file): `docs/DEPLOYMENT_GATE_WORKFLOW.md`
- Pre-approval automation setup: `docs/pre-approval-jira-automation.md`
- Confluence: https://trigent1.atlassian.net/wiki/spaces/trigentepd/pages/2020442148/GitLab+Monitor
