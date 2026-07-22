---
name: cm-request-change
description: "Request a major or urgent manual change that does not go through the standard GitLab CI/CD pipeline — e.g. a manual infrastructure change, a manual config update, or an emergency change. Submits a change request form via the Jira service desk (portal 3). Attempts API submission; falls back to a pre-filled portal deep-link. Usage: /change-management:cm-request-change [description]. (Triggers: request manual change, request major change, request urgent change, manual change request, emergency change request, cm request change, change request form, raise a change)"
allowed-tools: [Bash, AskUserQuestion, ToolSearch]
argument-hint: "[brief description of the change]"
---

# cm-request-change — Request a Manual Major or Urgent Change

You are helping the user submit a formal change request for a **manual or non-pipeline** change
to a Trigent production system.

Use this skill for:
- Infrastructure changes applied directly (not via GitLab CI/CD)
- Configuration changes that bypass the automated deployment gate
- Emergency/urgent changes that cannot wait for the standard change-approval cycle

Do **not** use this for a pipeline that is blocked by the Komodo Monitor gate — for that, use
`/change-management:cm-diagnose`. This skill is for changes that do not go through GitLab at all.

---

## Phase 1: Gather change details

Ask the user the following questions (or confirm details they already provided):

1. **Change title** — a short one-line description (e.g. "Emergency: restart Redis cluster in prod-us-aks")
2. **Change type** — Major (planned significant change) or Urgent/Emergency (critical fix needed now)?
3. **What is the change?** — Clear description of exactly what will be changed.
4. **Why is this change needed?** — Business justification or incident reference.
5. **Which system / environment?** — e.g. "PSW US production AKS", "CPOMS UK Azure SQL"
6. **When is this planned?** — Proposed date/time (and whether it's time-critical).
7. **Rollback plan** — How would you undo this change if something goes wrong?
8. **Risk assessment** — What could go wrong? How will you validate success?

For an **urgent/emergency** change, also ask:
- What production impact is occurring right now (if any)?
- What is the severity / incident reference?

Confirm the complete details with the user before submitting.

---

## Phase 2: Build the request payload

Compose the form content:

```
Summary: [<MAJOR|URGENT>] <change title>

Change Description:
<What is being changed and why>

System / Environment:
<Which system and environment>

Planned Date / Time:
<When (or "ASAP — emergency">

Justification:
<Business reason / incident reference>

Rollback Plan:
<How to undo the change>

Risk Assessment:
<What could go wrong and how success will be validated>

[If urgent] Current Impact:
<Severity, user impact, incident reference>
```

---

## Phase 3: Attempt automated submission

> **Note on acli servicedesk:** `acli` (v1.3.x) has **no `servicedesk` subcommand**. Portal 3 (CM
> project) requires a true JSM portal request with a specific Request Type — this is only achievable
> via the `servicedeskapi` REST endpoint. `acli jira workitem create` is not available for portal 3
> requests. Prefer curl or MCP; fall back to the deep-link.

### Step 1: Check acli authentication and discover portal-3 request types

```bash
acli jira auth status 2>&1
```

**If NOT authenticated**, do NOT attempt to log in automatically. Tell the user:

> acli is not authenticated. To use it for other Jira operations, run:
> ```
> ! acli jira auth login --web
> ```
> For this change request, continue with curl (Step 2) or the portal deep-link (Phase 4).

Check credentials for the REST API path:
```bash
echo "JIRA_EMAIL=${JIRA_EMAIL:-NOT_SET}" && echo "JIRA_TOKEN=${JIRA_TOKEN:-NOT_SET}"
```

If `JIRA_EMAIL` and `JIRA_TOKEN` are set, discover the correct request type ID for "manual change":
```bash
curl -s \
  -u "$JIRA_EMAIL:$JIRA_TOKEN" \
  -H "Accept: application/json" \
  "https://trigent1.atlassian.net/rest/servicedeskapi/servicedesk/3/requesttype" \
| jq '.values[] | {id, name, description}'
```

Pick the most appropriate request type ID for a major/urgent manual change. If none is obvious,
use the portal deep-link (Phase 4) and let the user select the right form type on the portal.

### Step 2: Submit via curl (if JIRA_EMAIL + JIRA_TOKEN set)

```bash
curl -s -o /tmp/cm-change-response.json -w "%{http_code}" -X POST \
  -u "$JIRA_EMAIL:$JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  "https://trigent1.atlassian.net/rest/servicedeskapi/request" \
  -d '{
    "serviceDeskId": "3",
    "requestTypeId": "<DISCOVERED_ID>",
    "requestFieldValues": {
      "summary": "<SUMMARY>",
      "description": "<DESCRIPTION>"
    }
  }'
cat /tmp/cm-change-response.json | jq '{issueKey: .issueKey, _links: ._links.web}'
```

If successful (HTTP 200/201), report the issue key and link to the user.

### Step 3: MCP fallback

If curl is unavailable or credentials are not set, call:
```
ToolSearch query="select:mcp__mcp-atlassian__jira_create_issue"
```
Then:
```
mcp__mcp-atlassian__jira_create_issue(
  project_key: "CM",
  summary: "<SUMMARY>",
  issue_type: "Service Request",
  description: "<DESCRIPTION>"
)
```

---

## Phase 4: Deep-link fallback (always provide)

Always produce the portal link and pre-filled content, regardless of API success:

```
Change request portal:
https://trigent1.atlassian.net/servicedesk/customer/portal/3

--- Copy this into the form ---
Summary: [<MAJOR|URGENT>] <change title>

<Full description as composed above>
-------------------------------

⚠️  If the form shows a required "Investment Type" field — select "Technical Roadmap".
```

For urgent changes, emphasise: "Once submitted, follow up with the change approvers or the DevOps
team immediately to expedite approval."

---

## Phase 5: Confirm and close

Tell the user:
- The ticket was auto-created (with key + link), or they need to submit via the portal link.
- If it is an urgent/emergency change: recommend notifying the change approvers directly (TODO in
  the process doc — advise the user to contact DevOps if unsure who to notify).
- Remind them that once a CM ticket is approved, any blocked GitLab pipeline targeting the same
  commit will resume automatically.

---

## References

- @${CLAUDE_PLUGIN_ROOT}/references/change-process.md
- @${CLAUDE_PLUGIN_ROOT}/references/jira-service-desk.md
