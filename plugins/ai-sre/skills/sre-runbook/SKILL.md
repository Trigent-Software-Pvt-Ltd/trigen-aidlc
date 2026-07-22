---
name: sre-runbook
description: "AI-generated operational runbooks — create or update structured troubleshooting guides in Confluence. Supports any Trigent product registered in the sre-kb GitLab group. Usage: /ai-sre:sre-runbook [product] FAILURE-SCENARIO. (Triggers: runbook, operational guide, troubleshooting guide, playbook, how do I fix, write runbook, create runbook, document how to)"
allowed-tools: [Bash, Task, AskUserQuestion, mcp__gitlab__get_file_contents, mcp__gitlab__get_repository_tree, mcp__claude_ai_Atlassian__createConfluencePage, mcp__claude_ai_Atlassian__updateConfluencePage, mcp__claude_ai_Atlassian__getConfluenceSpaces, mcp__claude_ai_Atlassian__getConfluencePage, mcp__claude_ai_Atlassian__getPagesInConfluenceSpace, mcp__claude_ai_Atlassian__getAccessibleAtlassianResources]
argument-hint: "[product] FAILURE-SCENARIO"
---

# AI-Generated Operational Runbook

## Help

If `$ARGUMENTS` contains "help", output the following and stop:

```
/ai-sre:sre-runbook [product] FAILURE-SCENARIO

Generate a structured operational runbook for a specific failure scenario.

Arguments:
  em                               Emergency Management (AKS namespace: emergency)
  training                         Training Platform (AKS namespace: training)
  psw                              PSW Canada — staging (AKS namespace: psw-ca)
  vm                               Visitor Management (AKS namespace: visitor)
  volunteer                        Volunteer Management (AKS namespace: volunteer)
  dismissal                        DismissalSafe (AKS namespace: dismissal)
  cpoms-studentsafe / studentsafe  CPOMS StudentSafe (US + UK)
  cpoms-staffsafe / staffsafe      CPOMS StaffSafe (UK only, AKS namespace: staffsafe)
  smartpass                        SmartPass (own cluster, GCP+Azure)
  schoolpass                       SchoolPass Legacy / SchoolPass (mobile apps + BusAPI)
  <failure scenario>               Service name or failure description

Examples:
  /ai-sre:sre-runbook em push notifications failing            → ANH delivery runbook
  /ai-sre:sre-runbook em incidents-proxy KEDA                  → KEDA scale-to-zero runbook
  /ai-sre:sre-runbook training cdc pipeline stopped            → Debezium/EventHub runbook
  /ai-sre:sre-runbook vm screening-service timeout             → VM screening API timeout runbook
  /ai-sre:sre-runbook cpoms-studentsafe mysql slow query       → StudentSafe MySQL runbook
  /ai-sre:sre-runbook cpoms-staffsafe pod OOMKilled            → StaffSafe pod memory runbook
  /ai-sre:sre-runbook smartpass sql connection pool exhausted  → SmartPass Cloud SQL runbook
  /ai-sre:sre-runbook schoolpass busapi 500s                   → SchoolPass Legacy BusAPI runbook

Output:
  • Confluence page published to MI space (folder: /wiki/spaces/MI/folder/2427486270)
  • Title: Runbook: {Failure Scenario} ({em|training})
  • Sections: overview, prerequisites, symptoms, diagnosis, remediation, escalation, prevention
  • Real kubectl / az CLI commands pre-filled with EM or Training resource names

Related: /ai-sre:sre-incident (active triage) · /ai-sre:sre-postmortem (after resolution)
```

---


Create or update a structured runbook in Confluence for a specific failure scenario.

## References
- @${CLAUDE_PLUGIN_ROOT}/references/KB-RESOLVER.md
- @${CLAUDE_PLUGIN_ROOT}/references/sre-principles.md

---

## Product Routing

Normalise the slug from `$ARGUMENTS` per KB-RESOLVER.md §1. Then follow KB-RESOLVER.md §3 to discover and fetch infrastructure content for that product. Use the infrastructure content for pre-filled namespace names, cluster names, and resource names in the runbook commands.

If `$ARGUMENTS` is empty or the slug cannot be resolved, stop and ask:
> Which product? (em · training · psw · vm · volunteer · dismissal · cpoms-studentsafe · cpoms-staffsafe · smartpass · schoolpass · eventsafe · badge)

Wait for the user's answer, then use it as the product before continuing.

State the active product at the start.

---

## Step 1: Identify the Scenario

Use remaining `$ARGUMENTS` as the scenario. If vague, ask:

**Emergency Management scenarios:**
- `emergency-management-api` high error rate or pods crashlooping
- Push notifications not delivering (ANH failure)
- `incidents-proxy` KEDA scale-to-zero / Service Bus backlog
- AKS pod OOMKilled in `emergency` namespace
- Azure SQL `trigent-alert-db-prod` migration failure
- Azure Key Vault `trigent-alert-kv-prod` secret expired

**Training Platform scenarios:**
- `trigent-training-api` high error rate or pods crashlooping
- CDC pipeline stopped (Debezium / EventHub consumer lag)
- Service Bus DLQ growing — notifications not delivering
- AKS pod OOMKilled in `training` namespace
- Azure Key Vault secret expired (training stack)

**EventSafe scenarios:**
- `event-management-service` high error rate or pods crashlooping (AKS `event-management` namespace)
- `marketplace-service` unavailable — marketplace browsing and purchasing blocked
- `redemption-service` or `redemption-processor` failing — attendee entry affected
- Service Bus dead-letter queues growing — event or marketplace processing stalled
- Cosmos DB (`trigent-marketplace-cosmos-prod`) unavailable — marketplace features down
- Azure SQL (`trigent-evt-sql-prod-1`) high latency or unavailable
- Azure Key Vault (`trigent-evt-kv-prod`) secret expired or unreachable

**Badge Alert scenarios:**
> Note: Badge Alert is an Azure Function — there are no AKS pods. Confirmed badge hardware failures → escalate to EM on-call.
- `badge-alert-monitoring` Function App failing — badge health data not being collected
- All badge scanners for a district reporting offline (escalate to EM on-call immediately)
- Azure Monitor anomaly alert sustained — function failure rate elevated
- Storage account (`badgealertmonitorinb439`) throttling — function execution delayed
- Azure Key Vault connection string missing or expired

---

## Step 2: Gather Knowledge (parallel)

**Task A — Current pod state:**
```bash
source ~/.bashrc 2>/dev/null
kubectl get pods -n {NAMESPACE} 2>/dev/null | head -20
kubectl get events -n {NAMESPACE} --sort-by='.lastTimestamp' 2>/dev/null | tail -15
```

**Task B — Recent incidents:**
Search `searchJiraIssuesUsingJql`:
`project = SE AND labels = {LABEL} AND labels = incident AND created >= -90d ORDER BY created DESC`

**Task C — Existing runbook check:**
Call `getPagesInConfluenceSpace` on `MI` (ID: `100073472`), scoped to parent `2427486270`. If one exists for this scenario, offer to update instead of create.

---

## Step 3: Generate the Runbook

```markdown
# Runbook: {Failure Scenario Title}

**Service:** {component name}
**Stack:** {emergency-management-stack | training-stack}
**Last Updated:** {date}
**Author:** David Park
**Reviewed By:** (pending)

---

## Overview

**When to use:** {specific trigger conditions}
**Estimated resolution time:** {5 min / 30 min / requires deployment}
**Severity:** Typically SEV{N}

---

## Prerequisites

- [ ] Azure CLI logged in (`az account show`) — subscription: fa03b1fe-6a88-4841-8d25-c3e6f1fd00ca
- [ ] kubectl configured for {prod cluster}
- [ ] GitLab token set (`glab api "user"`)
- [ ] Access to New Relic and Azure Monitor
- [ ] Jira access (SE project)

---

## Symptoms

| Symptom | Where Observed | Severity Signal |
|---------|---------------|-----------------|
| {symptom} | {New Relic / kubectl / Azure Monitor} | {High / Critical} |

---

## Diagnosis

### Step 1: Confirm Failure Scope
```bash
kubectl get pods -n {NAMESPACE}
```
Expected: All Running, 0 restarts
Failure: CrashLoopBackOff, OOMKilled, Pending

### Step 2: Check {Component}
```bash
{specific command}
```
→ If {X} → go to Remediation A
→ If {Y} → continue to Step 3

### Step 3: Check Logs
```bash
kubectl logs -n {NAMESPACE} -l app={service} --tail=100 | grep -i "error\|fatal\|exception"
```

---

## Remediation

### Option A — {Most Common Fix}
**When:** {condition} | **Risk:** Low/Medium/High | **Reversible:** Yes/No
```bash
{exact command}
```
**Verify:**
```bash
kubectl get pods -n {NAMESPACE}
# Expected: All Running, restart count stable
```

### Option B — Rollback Last Deployment
**When:** Failure started immediately after a deploy
```bash
# Find last successful pipeline
glab api "projects/{API_PROJECT_ID}/pipelines?status=success&per_page=5" | \
  python3 -c "import json,sys; [print(f\"{p['id']}: {p.get('sha','')[:8]} {p['ref']} {p.get('created_at','')[:16]}\") for p in json.load(sys.stdin)[:3]]"

# Rolling restart (config issue, not code)
kubectl rollout restart deployment/{service} -n {NAMESPACE}
kubectl rollout status deployment/{service} -n {NAMESPACE}
```

---

## Escalation

If unresolved after 15–30 minutes:

| Step | Contact | Method |
|------|---------|--------|
| 1 | Engineering on-call | Slack DM / PagerDuty |
| 2 | Engineering lead | Slack `#incidents` |
| 3 | Azure Support | Infrastructure-level issue |

Run: `/ai-sre:sre-incident {em|training} {symptom}`

---

## Prevention

- [ ] Alert fires early enough? If not, add to New Relic or Azure Monitor.
- [ ] Runbook gap slowed resolution? Update this doc.
- [ ] Recurring issue? Automate or fix architecturally.
- [ ] Run `/ai-sre:sre-postmortem {em|training}` if SEV1 or SEV2.
```

---

## Step 4: Publish to Confluence

Target: `MI` space (ID: `100073472`) — parent page ID: `2427486270` (Runbooks)
(https://trigent1.atlassian.net/wiki/spaces/MI/folder/2427486270)

When calling `createConfluencePage`:
- `spaceId`: `100073472`
- `parentId`: `2427486270`

**Title format:** `Runbook: {Failure Scenario} ({em|training|psw|vm|volunteer|dismissal|staffsafe|sp})`

---

## Step 5: Validate

Ask: Are component names/namespaces correct? Missing diagnosis steps? Are remediation commands safe to run as written?
