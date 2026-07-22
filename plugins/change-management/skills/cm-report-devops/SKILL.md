---
name: cm-report-devops
description: "File a CI/CD-process issue report with the DevOps team via the Jira service desk (project DE 'DevSecOps Escalated', portal 4, request type 126). Use when a pipeline is stuck due to a suspected system bug with Komodo Monitor — e.g. no approval ticket created, approved jobs not retried, gate status stuck. Attempts automated submission via acli or MCP; falls back to a pre-filled portal deep-link. Usage: /change-management:cm-report-devops [pipeline-URL or description]. (Triggers: report to devops, report devops issue, file devops ticket, komodo bug, pipeline stuck report, raise issue devops, devops report)"
allowed-tools: [Bash, AskUserQuestion, ToolSearch]
argument-hint: "[pipeline-URL or issue description]"
---

# cm-report-devops — File a DevOps CI/CD Issue Report

You are filing a CI/CD-process issue report with the DevOps team via the Jira service desk.

DevOps is responsible for operating Komodo Monitor and unblocking pipeline issues that are caused
by system bugs. They **cannot** approve or deny change requests — they investigate and fix
automation issues only.

---

## Phase 1: Gather issue details

If the user has already run `cm-diagnose`, use the findings from that session. Otherwise ask:

1. **Pipeline / job URL** — the blocked pipeline or job URL (e.g. `https://gitlab.com/.../-/pipelines/123`).
2. **What happened** — brief description of the issue (e.g. "pipeline stuck on pending for 30 minutes", "jobs approved but not retried", "gate status never appeared").
3. **What you expected** — what should have happened.
4. **Anything you already tried** — e.g. "re-ran the pipeline", "checked the CM ticket".
5. **CM ticket key** (if one exists) — e.g. `CM-456`.

Confirm the details with the user before submitting.

---

## Phase 2: Attempt automated submission

Build the request payload:

```
Summary: [CM gate issue] <one-line description> — <pipeline URL or project name>
Description (plain text):
Pipeline/job URL: <url>
Issue observed: <what happened>
Expected behaviour: <what should have happened>
Steps tried: <anything already attempted>
CM ticket (if any): <key or "none">
Reported by: <user name or email if known>
```

### Step 1: Check acli authentication

> **Note:** `acli` (v1.3.x) has **no `servicedesk` subcommand**. Use `acli jira workitem create`
> instead — this creates a plain DE work item (not a JSM portal customer request, so no portal SLA
> clock, but it lands in the DevSecOps Escalated queue). The description **must be in ADF format**.

```bash
acli jira auth status 2>&1
```

**If authenticated** (`✓ Authenticated`), proceed to the acli submission below.

**If NOT authenticated**, do NOT attempt to log in automatically. Tell the user:

> acli is not authenticated. To use it, run this in your terminal:
> ```
> ! acli jira auth login --web
> ```
> Or continue with MCP (Step 2) or the portal link (Phase 3) instead.

If the user prefers to skip acli, go straight to Step 2.

#### acli submission (when authenticated)

Write the ADF payload to a temp file and create the issue:

```bash
cat > /tmp/cm-report-payload.json << 'EOF'
{
  "projectKey": "DE",
  "type": "Submit a request or incident",
  "summary": "<SUMMARY>",
  "description": {
    "type": "doc",
    "version": 1,
    "content": [
      {
        "type": "paragraph",
        "content": [{ "type": "text", "text": "<DESCRIPTION_PLAIN_TEXT>" }]
      }
    ]
  },
  "additionalAttributes": {
    "customfield_10378": { "value": "Technical Roadmap" }
  }
}
EOF
acli jira workitem create --from-json /tmp/cm-report-payload.json --json 2>&1 \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('Created:', d.get('key'), d.get('self',''))" \
  2>/dev/null || acli jira workitem create --from-json /tmp/cm-report-payload.json 2>&1
```

If successful, report the issue key and URL to the user and skip Step 2.

> ⚠️ This creates a plain DE Jira issue, not a portal request — it does not carry a Request Type
> or JSM SLA clock. The DevSecOps team will still see and action it.

### Step 2: MCP fallback

If acli is unavailable or unauthenticated and the user prefers MCP, call
`ToolSearch query="select:mcp__mcp-atlassian__jira_create_issue"` to load the MCP tool, then create
a work item in project DE:

```
mcp__mcp-atlassian__jira_create_issue(
  project_key: "DE",
  summary: "<SUMMARY>",
  issue_type: "Submit a request or incident",
  description: "<DESCRIPTION>",
  additional_fields: {"customfield_10378": {"value": "Technical Roadmap"}}
)
```

If the MCP tool call succeeds, report the issue key and URL to the user.

---

## Phase 3: Deep-link fallback (always provide this)

Regardless of whether the automated submission succeeded, produce the pre-filled deep-link and the
content the user should paste into the form:

```
Direct link to the DevOps report form:
https://trigent1.atlassian.net/servicedesk/customer/portal/4/group/9/create/126

--- Copy this into the form ---
Summary: [CM gate issue] <one-line description>

Description:
Pipeline/job URL: <url>
Issue observed: <what happened>
Expected behaviour: <what should have happened>
Steps tried: <anything already attempted>
CM ticket (if any): <key or "none">
-------------------------------

⚠️  The form has a required "Investment Type" field — select "Technical Roadmap".
```

This ensures the user can always complete the report even if the automated path fails.

---

## Phase 4: Confirm and close

Tell the user:
- Whether the ticket was auto-submitted (and the issue key if so), or whether they need to submit manually via the link.
- That DevOps will investigate and reach out.
- That they can also use `/change-management:cm-devops-fix` if they are on the DevOps team and want to run a deeper diagnostic.

---

## References

- @${CLAUDE_PLUGIN_ROOT}/references/deployment-gate.md
- @${CLAUDE_PLUGIN_ROOT}/references/jira-service-desk.md
