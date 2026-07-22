---
name: sre-postmortem
description: "AI-driven blameless post-incident review — reconstruct timeline from logs and Jira, apply 5-Whys root cause analysis, identify contributing factors, create Confluence postmortem page, generate Jira action items. Supports any Trigent product registered in the sre-kb GitLab group. Usage: /ai-sre:sre-postmortem [product] JIRA-TICKET-KEY. (Triggers: postmortem, post-mortem, post incident review, PIR, what went wrong, incident retrospective, blameless review, root cause analysis, RCA)"
allowed-tools: [Bash, Task, AskUserQuestion, mcp__gitlab__get_file_contents, mcp__gitlab__get_repository_tree, mcp__claude_ai_Atlassian__createConfluencePage, mcp__claude_ai_Atlassian__getConfluenceSpaces, mcp__claude_ai_Atlassian__getAccessibleAtlassianResources, mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql, mcp__claude_ai_Atlassian__createJiraIssue, mcp__claude_ai_Atlassian__editJiraIssue, mcp__claude_ai_Atlassian__addCommentToJiraIssue]
argument-hint: "[product] JIRA-TICKET-KEY"
---

# AI-Driven Blameless Post-Incident Review

## Help

If `$ARGUMENTS` contains "help", output the following and stop:

```
/ai-sre:sre-postmortem [product] JIRA-TICKET-KEY

Blameless 5-Whys root cause analysis, timeline reconstruction, Confluence postmortem page, and Jira action items.

Arguments:
  em                               Emergency Management
  training                         Training Platform
  vm / visitor                     Visitor Management
  volunteer / vol                  Volunteer Management
  dismissal / dis                  DismissalSafe
  cpoms-studentsafe / studentsafe  CPOMS StudentSafe (US + UK)
  cpoms-staffsafe / staffsafe      CPOMS StaffSafe (UK only)
  smartpass                        SmartPass (own cluster, GCP+Azure)
  schoolpass                       SchoolPass Legacy / SchoolPass (mobile apps + BusAPI)
  psw-ca                           PSW Canada (staging)
  <jira-ticket-key>                SE project incident ticket key (e.g. SE-1234)

Examples:
  /ai-sre:sre-postmortem SE-1234                        → EM postmortem from Jira ticket
  /ai-sre:sre-postmortem em SE-1234                     → EM — explicit
  /ai-sre:sre-postmortem training SE-5678               → Training postmortem
  /ai-sre:sre-postmortem cpoms-studentsafe SE-9012      → CPOMS StudentSafe postmortem
  /ai-sre:sre-postmortem cpoms-staffsafe SE-9013        → CPOMS StaffSafe postmortem
  /ai-sre:sre-postmortem schoolpass SE-1934             → SchoolPass Legacy postmortem

Output:
  • Confluence postmortem page (PublicScho space)
  • 5-Whys root cause chain
  • SMART action items as Jira sub-tasks
  • Comment added to original incident ticket with Confluence URL

Related: /ai-sre:sre-incident (triage) · /ai-sre:sre-runbook (document the fix)
```

---


Conduct a structured, blameless postmortem. The goal is to understand the system — not to assign blame.

## References
- @${CLAUDE_PLUGIN_ROOT}/references/KB-RESOLVER.md
- @${CLAUDE_PLUGIN_ROOT}/references/sre-principles.md

---

## Product Routing

Normalise the slug from `$ARGUMENTS` per KB-RESOLVER.md §1. Then immediately follow KB-RESOLVER.md §3 to discover and fetch infrastructure and severity content for that product (GitLab KB tree discovery → shared-layer merge → local fallback).

| Slug | AKS Namespace | API Project ID | Infra Project ID | Jira Label | Stack name |
|---|---|---|---|---|---|
| `em` | `emergency` | `70910037` | `70910037` | `emergency-management` | `emergency-management-api / emergency-management-stack` |
| `training` | `training` | `74177860` | `74177860` | `training` | `training-service / training-stack` |
| `psw-ca` | `psw-ca` | `62883976` | `62883976` | `psw-ca` | `PSW_MAIN / psw-infra` |
| `vm` | `visitor` | `71164741` | `56581929` | `visitor-management` | `visitor-management-api / visitor-management-stack` |
| `volunteer` | `volunteer` | `70302736` | `56581852` | `volunteer` | `volunteer-service / volunteer-stack` |
| `dismissal` | `dismissal` | `56581088` | `56581092` | `dismissal` | `dismissal-api / dismissal-stack` |
| `cpoms-studentsafe` | `cpoms` | *(from KB)* | *(from KB)* | `cpoms-studentsafe` | *(from KB)* |
| `cpoms-staffsafe` | `staffsafe` | *(from KB)* | *(from KB)* | `cpoms-staffsafe` | *(from KB)* |
| `smartpass` | `smartpass` | `71284288` | `71284288` | `smartpass` | `smartpass-server` |
| `schoolpass` | `schoolpass` | `76151499` | `76151499` | `schoolpass` | `schoolpass-app / BusAPI (GitHub)` |
| `eventsafe` | `event-management` | `60974304` | `60422294` | `eventsafe` | `event-management-api / event-management-stack` |
| `badge-alert` | *(Azure Functions)* | `75089702` | *(N/A)* | `badge-alert` | `badge-alert-monitoring` |

If `$ARGUMENTS` is empty or the slug cannot be resolved, stop and ask:
> Which product? (em · training · psw · vm · volunteer · dismissal · cpoms-studentsafe · cpoms-staffsafe · smartpass · schoolpass · eventsafe · badge)

State the active product at the start.

---

## Phase 1: Gather Incident Context

If `$ARGUMENTS` contains a Jira key, fetch via `searchJiraIssuesUsingJql` with `key = {ticket_key}`.

If no ticket, ask: start/end time, user-facing impact, components involved, fix/resolution, Jira ticket to link.

Then pull context in parallel:

**Task A — GitLab pipeline history:**
```bash
source ~/.bashrc 2>/dev/null
# EM: project 70910037 | Training: project 74177860
glab api "projects/{API_PROJECT_ID}/pipelines?per_page=20" 2>/dev/null | \
  python3 -c "
import json, sys
pipes = json.load(sys.stdin)
for p in (pipes if isinstance(pipes, list) else [])[:15]:
    print(f\"{p.get('created_at','')[:16]}: [{p.get('status')}] {p.get('ref')} — pipeline {p.get('id')}\")
"
```

**Task B — AKS pod events:**
```bash
source ~/.bashrc 2>/dev/null
kubectl get events -n {NAMESPACE} --sort-by='.lastTimestamp' 2>/dev/null | tail -30
kubectl get pods -n {NAMESPACE} --sort-by='.status.containerStatuses[0].restartCount' 2>/dev/null
```

**Task C — Recent Jira SE incidents:**
Search `searchJiraIssuesUsingJql`:
`project = SE AND labels = {LABEL} AND created >= -90d ORDER BY created DESC`

---

## Phase 2: AI-Constructed Timeline

```
## Incident Timeline (UTC)

| Time    | Event | Source |
|---------|-------|--------|
| {HH:MM} | {first symptom / alert fired} | {New Relic / Azure Monitor / user report} |
| {HH:MM} | {investigation started} | {IC name} |
| {HH:MM} | {key finding} | {kubectl / Azure Monitor} |
| {HH:MM} | {mitigation attempt} | {IC name} |
| {HH:MM} | {all-clear declared} | {IC name} |

Duration: {X} | Detection lag: {X min} | MTTR: {X min}
```

---

## Phase 3: 5-Whys Root Cause Analysis

**Emergency Management example chains:**

*Push notification failure:*
```
Why did emergency alerts not reach mobile devices?
→ trigent-alert-push-notification-service-v2 could not connect to ANH
Why? → ANH connection string secret had expired in Key Vault
Why? → No expiry alert configured → ROOT CAUSE
```

*incidents-proxy stopped:*
```
Why were incident events not processed?
→ incidents-proxy KEDA scaled to zero
Why? → Service Bus trigger returned 0 due to transient ARM API error
Why? → KEDA min replica count was 0 → ROOT CAUSE
```

**Training Platform example chains:**

*CDC pipeline failure:*
```
Why did enrollments stop processing?
→ Debezium CDC IngestFunction stopped consuming from EventHub
Why? → EventHub consumer group offset reset after pod restart
Why? → OOMKilled — memory limit set too low
Why? → Limit set at initial deploy, not updated as MySQL binlog volume grew
Why? → No EventHub throughput monitoring or memory headroom alert → ROOT CAUSE
```

---

## Phase 4: Contributing Factors

```
| Factor | Category | Impact |
|--------|----------|--------|
| {e.g., No Key Vault expiry alert} | Monitoring gap | Delayed detection |
| {e.g., No runbook for this failure} | Documentation gap | Response slowed |
| {e.g., KEDA min replicas = 0} | Configuration gap | Silent failure |
```

Categories: Monitoring gap, Documentation gap, Process gap, Configuration gap, Testing gap, Communication gap

---

## Phase 5: Create Confluence Postmortem Page

Target: `MI` space (ID: `100073472`) — parent page ID: `100073575` (Postmortems)
(https://trigent1.atlassian.net/wiki/spaces/MI/pages/100073575/Postmortems)

**Title:** `Postmortem: SEV{N} — {product-slug}: {description} ({YYYY-MM-DD})`

Include: summary table, impact, timeline, 5-Whys, contributing factors, what went well, what could improve, action items (populated in Phase 6).

Blameless reminder footer required.

Display Confluence URL.

---

## Phase 6: Generate Action Items

```
| # | Action | Owner | Priority | Due | Jira |
|---|--------|-------|----------|-----|------|
| 1 | {specific, measurable action} | SRE | P1 | 2 weeks | |
```

Ask: "Shall I create Jira sub-tasks for these action items?"

If yes, create via `createJiraIssue`:
- Summary: `[POSTMORTEM ACTION] {action}`
- Labels: `postmortem`, `sre`, `{LABEL}`

Then add comment to incident ticket with Confluence URL and Jira action item keys.
