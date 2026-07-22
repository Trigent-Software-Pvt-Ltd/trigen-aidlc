# Jira Service Desk — Change Management Portals

## Atlassian instance

- Host: `trigent1.atlassian.net`
- Change management project key: **CM**
- Project URL: https://trigent1.atlassian.net/jira/servicedesk/projects/CM

---

## Portal 3 — Manual / urgent change requests

Use when a team needs to request a major or urgent **manual change** that does not go through a
GitLab pipeline (e.g. a manual infrastructure change, a config change applied by hand, or an
emergency change that cannot wait for the automated gate).

- Portal URL: https://trigent1.atlassian.net/servicedesk/customer/portal/3
- Portal ID: **3**

### Submitting via API (`/rest/servicedeskapi/request`)

```bash
# Discover request types available on portal 3
curl -s \
  -u "$JIRA_EMAIL:$JIRA_TOKEN" \
  -H "Accept: application/json" \
  "https://trigent1.atlassian.net/rest/servicedeskapi/servicedesk/3/requesttype" \
| jq '.values[] | {id, name}'
```

```bash
# Create a manual change request (substitute actual requestTypeId and field values)
curl -s -X POST \
  -u "$JIRA_EMAIL:$JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  "https://trigent1.atlassian.net/rest/servicedeskapi/request" \
  -d '{
    "serviceDeskId": "3",
    "requestTypeId": "<DISCOVER_AT_RUNTIME>",
    "requestFieldValues": {
      "summary": "<change title>",
      "description": "<change description, justification, rollback plan>"
    }
  }'
```

> **Note**: The exact `requestTypeId` values for portal 3 must be discovered via the `/requesttype`
> endpoint above. The request field names (`summary`, `description`, plus any required custom fields)
> also depend on the form configuration. Run the discovery call first and map the fields before
> submitting.

### Deep-link fallback

If the API path is unavailable or field discovery is incomplete, provide the user with the portal
URL so they can fill and submit the form manually:

```
https://trigent1.atlassian.net/servicedesk/customer/portal/3
```

---

## Portal 4, Group 9, Request type 126 — Submit a request or incident to the DevSecOps team

Use when a team has investigated a pipeline block and believes it is a **system bug** rather than
a genuine pending approval (e.g. Komodo Monitor down, status check stuck, Jira automation not
firing, jobs not retried after approval).

- Project: **DE** (DevSecOps Escalated)
- Portal 4, group 9: https://trigent1.atlassian.net/servicedesk/customer/portal/4/group/9
- Create form (request type 126): https://trigent1.atlassian.net/servicedesk/customer/portal/4/group/9/create/126
- Portal ID: **4** | Service desk ID: **4** | Request type ID: **126**
- Issue type: **"Submit a request or incident"**

### Required fields

| Field | Type | Value to use |
|-------|------|-------------|
| `summary` | text | One-line description of the pipeline issue |
| `description` | text | Pipeline/job URL, expected vs observed, steps tried |
| `customfield_10378` | single-select | `{ "value": "Technical Roadmap" }` |

> **Investment Type (`customfield_10378`)** is required. Always set it to **"Technical Roadmap"**
> in automated submissions. When using the portal manually, select "Technical Roadmap" from the
> dropdown.

### Submitting via API

```bash
# Discover fields for request type 126 (optional — run to verify field IDs if a 400 occurs)
curl -s \
  -u "$JIRA_EMAIL:$JIRA_TOKEN" \
  -H "Accept: application/json" \
  "https://trigent1.atlassian.net/rest/servicedeskapi/servicedesk/4/requesttype/126/field" \
| jq '.requestTypeFields[] | {fieldId, name, required}'
```

```bash
# Create a DevOps CI/CD-process report (Investment Type hardcoded to Technical Roadmap)
curl -s -X POST \
  -u "$JIRA_EMAIL:$JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  "https://trigent1.atlassian.net/rest/servicedeskapi/request" \
  -d '{
    "serviceDeskId": "4",
    "requestTypeId": "126",
    "requestFieldValues": {
      "summary": "<one-line description of the pipeline issue>",
      "description": "<pipeline/job URL, what was expected vs observed, steps already tried>",
      "customfield_10378": { "value": "Technical Roadmap" }
    }
  }'
```

### Deep-link fallback

If API submission fails or credentials are unavailable, provide the direct create URL:

```
https://trigent1.atlassian.net/servicedesk/customer/portal/4/group/9/create/126
```

Tell the user: **select "Technical Roadmap" for the required "Investment Type" field.**

---

## Environment variables expected by these commands

| Variable | Description |
|----------|-------------|
| `JIRA_EMAIL` | Atlassian account email (usually the user's org email) |
| `JIRA_TOKEN` | Atlassian API token (from https://id.atlassian.com/manage-profile/security/api-tokens) |

Check if already set: `echo $JIRA_EMAIL && echo $JIRA_TOKEN`

If not set, the skill must prompt the user or fall back to the portal deep-link.

---

## acli — workitem create for DE (verified working)

`acli` (Atlassian CLI v1.3.x) has **no `servicedesk` subcommand**. `acli jira servicedesk …` is
not a valid command.

`acli jira workitem create` **does work** for project DE (confirmed via live test). It creates a
plain Jira issue in the DevSecOps Escalated queue — not a JSM portal customer request (no portal
SLA clock, `customfield_10010` / Request Type remains null), but the DevSecOps team will see and
action it.

### Authentication check — always do this first; never auto-login

```bash
acli jira auth status 2>&1
```

- **If authenticated** (`✓ Authenticated`): proceed with `acli jira workitem create` below.
- **If NOT authenticated**: do **not** attempt to log in automatically, do not read token files or
  keyrings. Tell the user:

  > acli is not authenticated. To authenticate, run this in your terminal:
  > ```
  > ! acli jira auth login --web
  > ```
  > Or continue with MCP or the deep-link instead.

### Creating the issue (description must be ADF)

> ⚠️ The `description` field **must be in Atlassian Document Format (ADF)**. A plain string will
> be rejected with `✗ Error: json: 'description' field must be in Atlassian Document Format (ADF)`.

```bash
cat > /tmp/de_workitem.json << 'EOF'
{
  "projectKey": "DE",
  "type": "Submit a request or incident",
  "summary": "<summary>",
  "description": {
    "type": "doc",
    "version": 1,
    "content": [
      {
        "type": "paragraph",
        "content": [{ "type": "text", "text": "<description plain text>" }]
      }
    ]
  },
  "additionalAttributes": {
    "customfield_10378": { "value": "Technical Roadmap" }
  }
}
EOF
acli jira workitem create --from-json /tmp/de_workitem.json --json 2>&1 \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('Created:', d.get('key'), d.get('self',''))" \
  2>/dev/null || acli jira workitem create --from-json /tmp/de_workitem.json
```

> This creates a plain DE Jira issue, not a portal customer request — no Request Type / SLA clock.
> The DevSecOps team will still see and action it. Prefer the `servicedeskapi` curl path when
> `JIRA_EMAIL`+`JIRA_TOKEN` are set, as it creates a true portal request.

---

## Submission priority order (for portal 4 / DE reports)

1. **acli** `jira workitem create --from-json` (if `acli jira auth status` shows authenticated) —
   uses OAuth, no token env vars needed; creates a plain DE issue
2. **curl** against `/rest/servicedeskapi/request` (if `JIRA_EMAIL`+`JIRA_TOKEN` are set) — creates
   a true portal customer request with Request Type and SLA
3. **MCP** `mcp__mcp-atlassian__jira_create_issue` (project `DE`, type
   `Submit a request or incident`, `customfield_10378 = Technical Roadmap`) — creates a Jira issue
4. **Deep-link** — guaranteed fallback; always produce this URL so the user can submit manually.
   Remind them to select **"Technical Roadmap"** for the required Investment Type field.

When falling back to the deep-link, always include a pre-filled summary of the content so the user
can paste it into the form quickly.
