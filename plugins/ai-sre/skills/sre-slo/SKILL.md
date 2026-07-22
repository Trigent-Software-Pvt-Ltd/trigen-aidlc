---
name: sre-slo
description: "AI-assisted SLO/SLI management — define service level objectives, calculate error budgets, recommend burn-rate alerting thresholds, and review current reliability posture. Supports any Trigent product registered in the sre-kb GitLab group. Usage: /ai-sre:sre-slo [product] [define|review|budget]. (Triggers: SLO, SLI, SLA, error budget, service level, reliability target, how reliable is, define objectives, alerting thresholds)"
allowed-tools: [Bash, Task, AskUserQuestion, mcp__gitlab__get_file_contents, mcp__gitlab__get_repository_tree, mcp__claude_ai_Atlassian__createConfluencePage, mcp__claude_ai_Atlassian__getConfluenceSpaces, mcp__claude_ai_Atlassian__getAccessibleAtlassianResources]
argument-hint: "[product] [define|review|budget]"
---

# AI-Assisted SLO Management

## Help

If `$ARGUMENTS` contains "help", output the following and stop:

```
/ai-sre:sre-slo [product] [define|review|budget]

Define SLIs/SLOs, calculate error budgets, and configure multi-window burn-rate alerts.

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
  psw-ca                           PSW Canada (Azure staging — migration demo)
  define                           Create SLOs for a service (interactive)
  review                           Audit current SLO compliance against live metrics
  budget                           Calculate remaining error budget for the current window

Examples:
  /ai-sre:sre-slo em define               → define SLOs for EM services
  /ai-sre:sre-slo training define         → define SLOs for Training services
  /ai-sre:sre-slo em review               → review current EM SLO compliance
  /ai-sre:sre-slo training budget         → calculate Training error budget

Output:
  • SLI definitions with New Relic NRQL / Azure Monitor queries
  • SLO targets with error budget (minutes/month)
  • 3-tier burn-rate alert thresholds
  • Error budget policy (release gate rules)
  • Optional: Confluence SLO page (PublicScho space)

SLO targets (EM): emergency-management-api 99.9% · push-notification-service-v2 99% · incidents-proxy 99.5%
SLO targets (Training): trigent-training-api 99.5% · CDC IngestFunction 99%
SLO targets (PSW CA staging): psw-ca-webapp 99% · MySQL Flexible Server 99.5% · Service Bus processing 99%
SLO targets (Visitor Management): visitor-service 99.9% · screening-service 99.5% · P95 latency < 2s · Error budget: 43.8 min/month
SLO targets (Volunteer Management): portal-service 99.5% · volunteer-application-service 99% · Error budget: 3.65 hr/month
SLO targets (DismissalSafe): dismissal-api 99.9% (school hours) · camera-detection 99% · Error budget: 43.8 min/month
SLO targets (CPOMS StudentSafe/StaffSafe): fetched from KB `dashboards/service-level-objectives.md`
SLO targets (SmartPass): sp-server 99.9% · Cloud SQL 99.95% · sp-asb-consumer lag < 30s · Error budget: 43.8 min/month
SchoolPass baseline: BusAPI 99.5% availability · p95 < 2s · QuickPin success rate > 99%

Related: /ai-sre:sre-toil (when budget is low) · /ai-sre:sre-incident (when budget is exhausted)
```

---


Define SLOs, SLIs, and error budgets using Google SRE principles.

## References
- @${CLAUDE_PLUGIN_ROOT}/references/KB-RESOLVER.md
- @${CLAUDE_PLUGIN_ROOT}/references/sre-principles.md

---

## Product Routing

Normalise the slug from `$ARGUMENTS` per KB-RESOLVER.md §1. Then follow KB-RESOLVER.md §3 to discover and fetch infrastructure and SLO content for that product. Use the infrastructure content for service-map details and NR/Azure query targets.

If `$ARGUMENTS` is empty or the slug cannot be resolved, stop and ask:
> Which product? (em · training · psw · vm · volunteer · dismissal · cpoms-studentsafe · cpoms-staffsafe · smartpass · schoolpass · eventsafe · badge)

Wait for the user's answer, then use it as the product before continuing.

Also determine mode:
- "define" or no existing SLO → **Define Mode**
- "review" → **Review Mode**
- "budget" → **Error Budget Mode**

Ask if unclear:
```
1. Define SLOs for a {product} service (new)
2. Review existing SLOs and current compliance
3. Calculate remaining error budget
```

---

## Define Mode

### Service Map

**Emergency Management:**

| Service | Component | Infra |
|---------|-----------|-------|
| Emergency Management API | `emergency-management-api` | AKS `emergency`, southcentralus |
| Emergency Management Function | `emergency-management-function` | AKS `emergency` |
| Incidents Proxy | `incidents-proxy` | AKS, KEDA (Service Bus trigger) |
| Drill Manager API | `drill-manager-api` | AKS `emergency` |
| Push Notification Service v2 | `trigent-alert-push-notification-service-v2` | Azure Durable Functions, ANH |

**Training Platform:**

| Service | Component | Infra |
|---------|-----------|-------|
| Training API | `trigent-training-api` | AKS `training`, southcentralus |
| Training Functions | `trigent-training-functions` | AKS `training`, Service Bus + NRules |
| CDC IngestFunction | `trigent-training-ingest-function` | AKS `training`, EventHub trigger |
| Notification Functions | `trigent-training-functions` (SB trigger) | AKS `training`, Service Bus |

---

### Recommended SLIs

**Emergency Management:**
```
emergency-management-api:
  Availability: (total_requests - 5xx) / total_requests
    Source: New Relic — WHERE appName LIKE 'Emergency.Management.Api%'
  Latency: % requests P95 < 800ms | Source: New Relic
  Error rate: < 1% 5xx | Source: New Relic APM

incidents-proxy:
  Message processing: % Service Bus messages processed without DLQ
    Source: Azure Monitor — Service Bus DLQ count
  Processing latency: P95 < 30s | Source: Azure Monitor — SB message age

push-notification-service-v2:
  ANH delivery success: (dispatched - ANH failures) / dispatched
    Source: Azure Notification Hub delivery metrics
  Delivery latency: P95 < 60s | Source: ANH + Durable Function logs
  ⚠️ Life-safety feature — SLO breaches are SEV1/SEV2
```

**Training Platform:**
```
trigent-training-api:
  Availability: (total_requests - 5xx) / total_requests
    Source: New Relic — Transaction WHERE appName = 'trigent-training-api'
  Latency: % requests P95 < 800ms | Source: New Relic
  Error rate: < 0.5% 5xx | Source: New Relic APM

trigent-training-ingest-function (CDC):
  Event processing: % EventHub messages consumed without DLQ
    Source: Azure Monitor — EventHub IncomingMessages vs OutgoingMessages
  Processing lag: % time consumer lag < 5 min | Source: Azure Monitor

Notification Functions:
  Delivery success: (processed - DLQ) / processed
    Source: Azure Monitor — Service Bus DLQ count
  Processing latency: P95 < 2 min | Source: Azure Monitor — SB message age
```

---

### Recommended SLO Targets

**Emergency Management:**

| Service | SLI | SLO | Rationale |
|---------|-----|-----|-----------|
| `emergency-management-api` | Availability | **99.9%** | Life-safety system; ~40 min/month budget |
| `emergency-management-api` | P95 < 800ms | 95% | Allows occasional slow responses |
| `incidents-proxy` | Message processing | **99.5%** | Near-real-time incident initiation |
| `push-notification-service-v2` | ANH delivery | **99%** | External APNs/FCM dependencies |
| `push-notification-service-v2` | Delivery P95 < 60s | 95% | Emergency alert urgency |
| `drill-manager-api` | Availability | 99.5% | Non-emergency feature |

**Training Platform:**

| Service | SLI | SLO | Rationale |
|---------|-----|-----|-----------|
| `trigent-training-api` | Availability | 99.5% | ~202 min/month; training workload |
| `trigent-training-api` | P95 < 800ms | 95% | Allows occasional slow responses |
| CDC IngestFunction | Event processing | 99% | Async pipeline; some lag tolerable |
| Notification Functions | Delivery success | 99% | Near-real-time but not life-safety |

**Visitor Management:**

| Service | SLI | SLO | Rationale |
|---------|-----|-----|-----------|
| `visitor-service` | Availability | **99.9%** | Core check-in flow; 43.8 min/month budget |
| `visitor-service` | P95 < 2s | 95% | Front-desk visitor check-in latency |
| `screening-service` | Availability | 99.5% | Sex-offender screening; some async tolerance |

**Volunteer Management:**

| Service | SLI | SLO | Rationale |
|---------|-----|-----|-----------|
| `portal-service` | Availability | 99.5% | ~3.65 hr/month; volunteer portal |
| `volunteer-application-service` | Availability | 99% | Async application processing |

**DismissalSafe:**

| Service | SLI | SLO | Rationale |
|---------|-----|-----|-----------|
| `dismissal-api` | Availability | **99.9%** | During school hours; 43.8 min/month budget |
| `camera-detection` | Availability | 99% | Vision pipeline; some transient failures tolerable |

**StaffSafe (UK):**

| Service | SLI | SLO | Rationale |
|---------|-----|-----|-----------|
| `cpoms` API | Availability | **99.9%** | Staff safeguarding records; 43.8 min/month budget |
| MySQL Flexible Server | Availability | **99.99%** | Managed Azure DB — near-zero tolerance |

**SmartPass:**

| Service | SLI | SLO | Rationale |
|---------|-----|-----|-----------|
| `sp-server` | Availability | **99.9%** | Hall-pass issuance; 43.8 min/month budget |
| Google Cloud SQL | Availability | 99.95% | Managed GCP DB |
| `sp-asb-consumer` | Processing lag < 30s | 95% | Azure Service Bus consumer pipeline |

---

### Error Budget Calculation

```
Error budget = (1 - SLO) × 28 × 24 × 60 minutes/month

Examples:
  99.9% → 40.3 min/month
  99.5% → 201.6 min/month (~3h 21min)
  99.0% → 403.2 min/month (~6h 43min)
```

**Error Budget Policy:**

| Budget Remaining | Action |
|-----------------|--------|
| > 50% | Normal release cadence, experiments allowed |
| 25–50% | Increase test coverage before deployments |
| < 25% | Freeze non-critical releases; escalate monitoring |
| Exhausted | Full release freeze until budget resets |

---

### Multi-Window Burn Rate Alerts

```
Alert 1 — Page (SEV2):
  Condition: 1-hour burn rate > 14.4 AND 5-minute burn rate > 14.4
  Meaning: 100% of monthly budget consumed in 2 hours

Alert 2 — Ticket (SEV3):
  Condition: 6-hour burn rate > 6 AND 30-minute burn rate > 6
  Meaning: Budget consumed in 5 days

Alert 3 — Warning (SEV4):
  Condition: 24-hour burn rate > 3
  Meaning: Budget consumed in ~10 days
```

**New Relic NRQL:**
```sql
-- Emergency Management API
SELECT percentage(count(*), WHERE httpResponseCode >= 500) AS error_rate
FROM Transaction
WHERE appName LIKE 'Emergency.Management.Api%'
SINCE 1 hour ago

-- Training API
SELECT percentage(count(*), WHERE httpResponseCode >= 500) AS error_rate
FROM Transaction
WHERE appName = 'trigent-training-api'
SINCE 1 hour ago
```

---

### Document in Confluence

Create page in `PublicScho` space:
**Title:** `SLO: {Service Name} — Service Level Objectives ({Product})`

---

## Review Mode

**Emergency Management — Service Bus DLQ check:**
```bash
source ~/.bashrc 2>/dev/null
az servicebus namespace list \
  --resource-group EmergencyManagement \
  --subscription fa03b1fe-6a88-4841-8d25-c3e6f1fd00ca \
  --query "[].name" --output tsv 2>/dev/null
```

**Training Platform — Service Bus DLQ check:**
```bash
source ~/.bashrc 2>/dev/null
az servicebus namespace list \
  --resource-group rg-trng-prod-southcentralus-mzsv \
  --subscription fa03b1fe-6a88-4841-8d25-c3e6f1fd00ca \
  --query "[].name" --output tsv 2>/dev/null
```

Report current compliance, error budget consumed, and budget status.
