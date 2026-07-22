---
name: sre-toil
description: "AI-driven toil analysis — identify, quantify, and eliminate repetitive manual operational work. Supports any Trigent product registered in the sre-kb GitLab group. Usage: /ai-sre:sre-toil [product] [pipelines|runners|ecs|azure|all]. (Triggers: toil, repetitive work, manual work, automate, keep doing this manually, same thing every week, waste of time, recurring issue, pipeline keeps failing, always have to)"
allowed-tools: [Bash, Read, Edit, Task, AskUserQuestion, mcp__gitlab__get_file_contents, mcp__gitlab__get_repository_tree, mcp__claude_ai_Atlassian__createJiraIssue, mcp__claude_ai_Atlassian__getAccessibleAtlassianResources, mcp__claude_ai_Atlassian__getVisibleJiraProjects, mcp__claude_ai_Atlassian__createConfluencePage, mcp__claude_ai_Atlassian__getConfluenceSpaces, mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql]
argument-hint: "[product] [pipelines|runners|aks|azure|all]"
---

# AI-Driven Toil Analysis

## Help

If `$ARGUMENTS` contains "help", output the following and stop:

```
/ai-sre:sre-toil [product] [pipelines|runners|aks|azure|all]

Identify, quantify, and eliminate repetitive manual operational work.

Arguments:
  em                               Emergency Management (AKS namespace: emergency)
  training                         Training Platform (AKS namespace: training)
  psw                              PSW (AWS ECS — region inferred from symptom: us-east-1 or ca-central-1)
  vm                               Visitor Management (AKS namespace: visitor)
  volunteer                        Volunteer Management (AKS namespace: volunteer)
  dismissal                        DismissalSafe (AKS namespace: dismissal)
  cpoms-studentsafe / studentsafe  CPOMS StudentSafe (US + UK)
  cpoms-staffsafe / staffsafe      CPOMS StaffSafe (UK only, AKS namespace: staffsafe)
  smartpass                        SmartPass (own cluster, GCP+Azure)
  schoolpass                       SchoolPass Legacy / SchoolPass (mobile apps + BusAPI)
  pipelines  GitLab CI failure patterns only
  runners    GitLab runner reliability only
  aks        AKS pod restarts and OOMKilled events only
  ecs        ECS task restarts and OOM events (PSW products only)
  azure      Terraform / Terragrunt drift signals only
  all        All checks (default when area is omitted)

Examples:
  /ai-sre:sre-toil                          → prompted for product, then area
  /ai-sre:sre-toil em all                   → full EM toil analysis
  /ai-sre:sre-toil training all             → full Training toil analysis
  /ai-sre:sre-toil psw us all             → full PSW US prod toil analysis
  /ai-sre:sre-toil psw canada all         → full PSW Canada toil analysis
  /ai-sre:sre-toil em aks                   → AKS namespace restarts only
  /ai-sre:sre-toil training pipelines       → CI failure patterns only
  /ai-sre:sre-toil vm all                   → full Visitor Management toil analysis
  /ai-sre:sre-toil volunteer aks            → Volunteer AKS restarts only
  /ai-sre:sre-toil dismissal all            → full DismissalSafe toil analysis
  /ai-sre:sre-toil staffsafe all            → full StaffSafe UK toil analysis
  /ai-sre:sre-toil smartpass all            → full SmartPass toil analysis
  /ai-sre:sre-toil schoolpass all          → full SchoolPass Legacy toil analysis

Output:
  • Toil inventory table (frequency, time/occurrence, hrs/month, priority)
  • Automation playbook per P1 item (root cause, exact steps, effort, monthly savings)
  • Optional: Jira Story + sub-tasks (labels: toil, sre, automation, {product})
  • Optional: Confluence toil register page (SRE Toil Register — {Product} — YYYY-MM)

Baselines: EM ~9.8 hrs/month · Training ~10.4 hrs/month · PSW ~6.5h avg (US ~7.2h · CA ~5.8h) · VM ~6.7h · Volunteer ~4.6h · Dismissal ~5.0h · CPOMS (fetched from KB) · SmartPass ~4.1h · SchoolPass ~3.2h

Related: /ai-sre:sre-slo (error budget impact) · /ai-sre:sre-runbook (document recurring fixes)
```

---


Identify, quantify, and eliminate toil — manual, repetitive, automatable work that scales with service growth.

## References
- @${CLAUDE_PLUGIN_ROOT}/references/KB-RESOLVER.md
- @${CLAUDE_PLUGIN_ROOT}/references/sre-principles.md

**Immediately after determining the product slug (per KB-RESOLVER.md §1), follow KB-RESOLVER.md §3 to discover and fetch infrastructure content for that slug. Do NOT load any other product's files.**

---

## Product Routing

Normalise the slug from `$ARGUMENTS` per KB-RESOLVER.md §1, then follow §3 to discover and fetch infrastructure content. Infrastructure constants (namespace, cluster, RG) come from the fetched files.

| Slug | Jira Label |
|---|---|
| `em` | `emergency-management` |
| `training` | `training` |
| `psw-ca` | `psw` |
| `vm` | `visitor-management` |
| `volunteer` | `volunteer` |
| `dismissal` | `dismissal` |
| `cpoms-studentsafe` | `cpoms-studentsafe` |
| `cpoms-staffsafe` | `cpoms-staffsafe` |
| `smartpass` | `smartpass` |
| `schoolpass` | `schoolpass` |
| `eventsafe` | `eventsafe` |
| `badge-alert` | `badge-alert` |

If `$ARGUMENTS` is empty or the slug cannot be resolved, stop and ask:
> Which product? (em · training · psw · vm · volunteer · dismissal · cpoms-studentsafe · cpoms-staffsafe · smartpass · schoolpass · eventsafe · badge)

Wait for the user's answer, then use it as the product before continuing.

**PSW region detection (when product = psw):** Read `$ARGUMENTS` for region keywords:

| $ARGUMENTS contains | Active region | ECS cluster / resources |
|---------------------|---------------|-------------------------|
| "us", "united states", "u.s." | **US** | `PSW-PROD` / us-east-1 / `psw-prod-db` |
| "canada", "ca", "canadian" | **Canada** | `PSW-CA-PROD` / ca-central-1 / `psw-ca-prod` |
| Ambiguous / neither | **Ask** | `> Is this affecting US or Canada customers?` |

State the active product and region, then proceed.

---

## Phase 1: Scope

```
Which areas to analyze for toil?
1. GitLab CI/CD pipelines (failed jobs, flaky runners, slow builds)
2. GitLab runners (manual restarts, capacity issues)
3. AKS {NAMESPACE} namespace (pod restarts, OOMKilled, manual interventions)
4. Azure infrastructure (Terraform/Terragrunt drift, Key Vault rotation)
5. {EM: Push notifications (ANH failures, manual retries) | Training: CDC pipeline (EventHub lag, Debezium restarts) | PSW: ECS task OOM, Aurora connection pool, SQS DLQ manual replay}
6. All of the above
```

---

## Phase 1.5: Live Infrastructure Sync

Run this in parallel with Phase 2 startup. Discover the current state of the active product's infrastructure, compare to the reference doc, and patch any drift before the toil inventory is built. New services found here should be flagged as `[NEW — not in ref doc]` in the Phase 3 inventory.

**Safety rule:** Never remove documented services — only add or update.

### AKS-based products (EM, Training, VM, Volunteer, DismissalSafe, StaffSafe)

```bash
source ~/.bashrc 2>/dev/null
echo "=== Live pods in {NAMESPACE} namespace ==="
kubectl get pods -n {NAMESPACE} --no-headers 2>/dev/null | awk '{print $1}' | \
  sed 's/-[a-z0-9]\{8,10\}-[a-z0-9]\{5\}$//' | sort -u

echo ""
echo "=== GitLab projects in product group ==="
glab api "groups/{GROUP_ID}/projects?per_page=30&include_subgroups=true" 2>/dev/null | \
  python3 -c "import json,sys; [print(f\"{p['id']}: {p['path_with_namespace']}\") for p in json.load(sys.stdin)]" 2>/dev/null
```

Use these GROUP_IDs per product:
- EM: `85254511`
- Training: search `trigent1/trigent/psw/training`
- VM: `85254508`
- Volunteer: `85254520`
- DismissalSafe: `85254567`
- StaffSafe: `85254522`

### PSW (ECS — us-east-1 or ca-central-1)

*If US (us-east-1):*
```bash
source ~/.bashrc 2>/dev/null
echo "=== Live ECS services (PSW-PROD) ==="
aws ecs list-services --cluster PSW-PROD --region us-east-1 --output json 2>/dev/null | \
  python3 -c "import json,sys; [print('  '+a.split('/')[-1]) for a in json.load(sys.stdin).get('serviceArns',[])]"

echo ""
echo "=== Live ECS services (PSW-PROD-Scripts) ==="
aws ecs list-services --cluster PSW-PROD-Scripts --region us-east-1 --output json 2>/dev/null | \
  python3 -c "import json,sys; [print('  '+a.split('/')[-1]) for a in json.load(sys.stdin).get('serviceArns',[])]"

echo ""
echo "=== ECS task stopped reasons (PSW-PROD, last 10) ==="
aws ecs list-tasks --cluster PSW-PROD --desired-status STOPPED --region us-east-1 \
  --query 'taskArns[:10]' --output text 2>/dev/null | tr '\t' '\n' | while read arn; do
  aws ecs describe-tasks --cluster PSW-PROD --tasks "$arn" --region us-east-1 \
    --query "tasks[0].{stopped:stoppedReason,container:containers[0].reason}" --output table 2>/dev/null
done
```

*If Canada (ca-central-1):*
```bash
source ~/.bashrc 2>/dev/null
echo "=== Live ECS services (PSW-CA-NonProd) ==="
aws ecs list-services --cluster PSW-CA-NonProd --region ca-central-1 --output json 2>/dev/null | \
  python3 -c "import json,sys; [print('  '+a.split('/')[-1]) for a in json.load(sys.stdin).get('serviceArns',[])]"

echo ""
echo "=== Live ECS services (PSW-CA-PROD) ==="
aws ecs list-services --cluster PSW-CA-PROD --region ca-central-1 --output json 2>/dev/null | \
  python3 -c "import json,sys; [print('  '+a.split('/')[-1]) for a in json.load(sys.stdin).get('serviceArns',[])]"

echo ""
echo "=== ECS task stopped reasons (PSW-CA-PROD, last 10) ==="
aws ecs list-tasks --cluster PSW-CA-PROD --desired-status STOPPED --region ca-central-1 \
  --query 'taskArns[:10]' --output text 2>/dev/null | tr '\t' '\n' | while read arn; do
  aws ecs describe-tasks --cluster PSW-CA-PROD --tasks "$arn" --region ca-central-1 \
    --query "tasks[0].{stopped:stoppedReason,container:containers[0].reason}" --output table 2>/dev/null
done
```

### SmartPass (own cluster)

```bash
source ~/.bashrc 2>/dev/null
echo "=== SmartPass live pods ==="
kubectl get pods --no-headers 2>/dev/null | awk '{print $1}' | \
  sed 's/-[a-z0-9]\{5,10\}-[a-z0-9]\{5\}$//' | sort -u || echo "(set kubectl context to smartpass cluster first)"
```

### SchoolPass Legacy (SchoolPass)

```bash
source ~/.bashrc 2>/dev/null
echo "=== LIVE SYNC: BusAPI HTTP health ==="
curl -s -o /dev/null -w "busapi-central: %{http_code} (%{time_total}s)\n" \
  --max-time 10 "https://busapi-central.us-pnlb01.school-pass.net/" 2>/dev/null

echo ""
echo "=== LIVE SYNC: SchoolPass GitLab mobile repos (group 118908809) ==="
glab api "groups/118908809/projects?per_page=50&include_subgroups=true&order_by=last_activity_at&sort=desc" 2>/dev/null | \
  python3 -c "
import json,sys
known={76151499,56581076,56581080}
ps=json.load(sys.stdin)
if not isinstance(ps,list): exit()
for p in ps:
    tag=' [NEW — not in ref doc]' if p['id'] not in known else ''
    print(f\"  {p['id']:8d} | {p.get('last_activity_at','')[:10]} | {p['path']}{tag}\")
" 2>/dev/null
```

**After sync:** Read the active product's reference doc. Compare live pod/service names to documented services. For any new name found:
1. Note it as `[NEW — not in ref doc]` when it appears in the Phase 3 toil inventory
2. Add it to the reference doc using Edit with a `(detected YYYY-MM-DD)` note
3. Report it in the Phase 3 summary alongside the toil inventory

---

## Phase 2: Automated Toil Detection (parallel Tasks)

### Task A — GitLab CI Failure Patterns
```bash
source ~/.bashrc 2>/dev/null
glab api "projects/{API_PROJECT_ID}/jobs?scope=failed&per_page=100" 2>/dev/null | \
  python3 -c "
import json, sys, collections
jobs = json.load(sys.stdin)
by_name = collections.Counter(j['name'] for j in (jobs if isinstance(jobs, list) else []))
by_runner = collections.Counter(
  j.get('runner', {}).get('description', 'unknown')
  for j in (jobs if isinstance(jobs, list) else []) if j.get('runner')
)
print('=== Top Failing Job Names ===')
for name, count in by_name.most_common(10):
    print(f'  {count:3d}x {name}')
print()
print('=== Failures by Runner ===')
for runner, count in by_runner.most_common(5):
    print(f'  {count:3d}x {runner}')
" 2>/dev/null || echo "glab token needed"
```

### Task B — GitLab Runner Reliability
```bash
source ~/.bashrc 2>/dev/null
glab api "groups/85254498/runners?per_page=50" 2>/dev/null | \
  python3 -c "
import json, sys
runners = json.load(sys.stdin)
for r in (runners if isinstance(runners, list) else []):
    tags = ','.join(r.get('tag_list', []))
    print(f\"{r['id']:8d} | {r.get('description','')[:35]:35s} | [{tags}] | {r.get('status')}\")
" 2>/dev/null
```

### Task C — AKS Namespace Pod Restarts
```bash
source ~/.bashrc 2>/dev/null
echo "=== Pod restart counts ({NAMESPACE} namespace) ==="
kubectl get pods -n {NAMESPACE} --sort-by='.status.containerStatuses[0].restartCount' 2>/dev/null
echo ""
echo "=== Recent OOMKilled events ==="
kubectl get events -n {NAMESPACE} --field-selector reason=OOMKilling 2>/dev/null | tail -10
echo ""
echo "=== CrashLoopBackOff events ==="
kubectl get events -n {NAMESPACE} --field-selector reason=BackOff 2>/dev/null | tail -10
```

### Task D — Infrastructure Drift

**Emergency Management (Terraform):**
```bash
source ~/.bashrc 2>/dev/null
glab api "projects/56585053/pipelines?status=failed&per_page=20" 2>/dev/null | \
  python3 -c "
import json, sys
pipes = json.load(sys.stdin)
for p in (pipes if isinstance(pipes, list) else [])[:10]:
    print(f\"{p.get('created_at','')[:16]}: [{p.get('status')}] {p.get('ref')} — pipeline {p.get('id')}\")
" 2>/dev/null
```

**Training Platform (Terragrunt):**
```bash
source ~/.bashrc 2>/dev/null
glab api "projects/74187670/pipelines?status=failed&per_page=20" 2>/dev/null | \
  python3 -c "
import json, sys
pipes = json.load(sys.stdin)
for p in (pipes if isinstance(pipes, list) else [])[:10]:
    print(f\"{p.get('created_at','')[:16]}: [{p.get('status')}] {p.get('ref')} — pipeline {p.get('id')}\")
" 2>/dev/null
```

**PSW (ECS stopped tasks & pipeline failures — US us-east-1 and CA ca-central-1):**
```bash
source ~/.bashrc 2>/dev/null
echo "=== PSW US: ECS tasks stopped in last 24h (PSW-PROD) ==="
aws ecs list-tasks --cluster PSW-PROD --desired-status STOPPED --region us-east-1 \
  --query 'taskArns[:5]' --output text 2>/dev/null | tr '\t' '\n' | while read arn; do
  [ -z "$arn" ] && continue
  aws ecs describe-tasks --cluster PSW-PROD --tasks "$arn" --region us-east-1 \
    --query "tasks[0].{stopped:stoppedReason}" --output text 2>/dev/null
done

echo ""
echo "=== PSW CA: ECS tasks stopped (PSW-CA-PROD) ==="
aws ecs list-tasks --cluster PSW-CA-PROD --desired-status STOPPED --region ca-central-1 \
  --query 'taskArns[:5]' --output text 2>/dev/null | tr '\t' '\n' | while read arn; do
  [ -z "$arn" ] && continue
  aws ecs describe-tasks --cluster PSW-CA-PROD --tasks "$arn" --region ca-central-1 \
    --query "tasks[0].{stopped:stoppedReason}" --output text 2>/dev/null
done

echo ""
echo "=== PSW psw-infra pipeline failures ==="
glab api "projects/62883972/pipelines?status=failed&per_page=10" 2>/dev/null | \
  python3 -c "
import json, sys
pipes = json.load(sys.stdin)
for p in (pipes if isinstance(pipes, list) else [])[:10]:
    print(f\"{p.get('created_at','')[:16]}: [{p.get('status')}] {p.get('ref')} — pipeline {p.get('id')}\")
" 2>/dev/null
```

### Task E — Jira Toil Tickets
Search `searchJiraIssuesUsingJql`:
`project = SE AND labels = {LABEL} AND created >= -90d ORDER BY summary ASC`

---

## Phase 3: Toil Inventory

**Emergency Management baseline:**

| Toil Item | Frequency | Time/Occurrence | Hrs/Month | Automatable | Priority |
|-----------|-----------|-----------------|-----------|-------------|----------|
| Push notification ANH delivery failure investigation | 2×/week | 25 min | 3.3h | Yes | P1 |
| AKS pod OOMKilled — manual memory limit tuning | 1×/week | 30 min | 2.0h | Partial | P1 |
| incidents-proxy KEDA scale-to-zero investigation | 1×/week | 20 min | 1.3h | Yes | P1 |
| Azure SQL migration retry after prod failure | Per deploy | 30 min | 1.0h | Partial | P1 |
| Azure Key Vault secret rotation (`trigent-alert-kv-prod`) | Monthly | 30 min | 0.5h | Yes | P2 |
| GitLab runner restart (spot node eviction) | 1×/week | 10 min | 0.7h | Yes | P2 |
| Terraform drift detection and manual fix | Per MR | 20 min | 1.0h | Partial | P2 |

**Training Platform baseline:**

| Toil Item | Frequency | Time/Occurrence | Hrs/Month | Automatable | Priority |
|-----------|-----------|-----------------|-----------|-------------|----------|
| Debezium CDC restart after pod eviction | 2×/week | 20 min | 2.7h | Yes | P1 |
| AKS pod OOMKilled — manual memory limit tuning | 1×/week | 30 min | 2.0h | Partial | P1 |
| Service Bus DLQ investigation and replay | 2×/week | 15 min | 2.0h | Yes | P1 |
| Terragrunt plan failures — manual drift fix | Per MR | 20 min | 1.5h | Partial | P1 |
| Azure Key Vault secret rotation | Monthly | 30 min | 0.5h | Yes | P2 |
| GitLab runner restart (spot node eviction) | 1×/week | 10 min | 0.7h | Yes | P2 |
| EventHub consumer lag investigation | Ad hoc | 25 min | 1.0h | Yes | P2 |

**Visitor Management baseline:**

| Toil Item | Frequency | Time/Occurrence | Hrs/Month | Automatable | Priority |
|-----------|-----------|-----------------|-----------|-------------|----------|
| AKS pod OOMKilled — memory limit tuning | 1×/week | 30 min | 2.0h | Partial | P1 |
| screening-service third-party API timeout investigation | 2×/week | 15 min | 2.0h | Yes | P1 |
| Auth0 tenant misconfiguration for new district | Per onboard | 20 min | 1.0h | Partial | P2 |
| hardware-service-v2 device reconnect | 1×/week | 15 min | 1.0h | Yes | P2 |
| GitLab runner restart (spot node eviction) | 1×/week | 10 min | 0.7h | Yes | P2 |

**Volunteer Management baseline:**

| Toil Item | Frequency | Time/Occurrence | Hrs/Month | Automatable | Priority |
|-----------|-----------|-----------------|-----------|-------------|----------|
| volunteer-expiration-service cron drift investigation | 2×/month | 30 min | 1.0h | Yes | P1 |
| AKS pod OOMKilled | 1×/week | 30 min | 2.0h | Partial | P1 |
| volunteer-application-service background check timeout | 1×/week | 20 min | 1.3h | Partial | P1 |
| Redis connection stale after Key Vault rotation | Monthly | 20 min | 0.3h | Yes | P2 |

**DismissalSafe baseline:**

| Toil Item | Frequency | Time/Occurrence | Hrs/Month | Automatable | Priority |
|-----------|-----------|-----------------|-----------|-------------|----------|
| camera-detection OOMKilled — memory tuning | 1×/week | 30 min | 2.0h | Partial | P1 |
| dismissal-api pod restart after K8s node eviction | 1×/week | 15 min | 1.0h | Yes | P1 |
| attendance-service SIS feed timeout | 2×/week | 15 min | 2.0h | Yes | P1 |

**StaffSafe baseline (UK):**

| Toil Item | Frequency | Time/Occurrence | Hrs/Month | Automatable | Priority |
|-----------|-----------|-----------------|-----------|-------------|----------|
| MySQL slow query investigation | 2×/month | 30 min | 1.0h | Yes | P1 |
| AKS pod OOMKilled — CPOMS memory pressure | 1×/week | 30 min | 2.0h | Partial | P1 |
| Redis eviction causing session drops | 1×/month | 25 min | 0.4h | Yes | P2 |
| Key Vault secret rotation (UK) | Monthly | 20 min | 0.3h | Yes | P2 |

**SmartPass baseline:**

| Toil Item | Frequency | Time/Occurrence | Hrs/Month | Automatable | Priority |
|-----------|-----------|-----------------|-----------|-------------|----------|
| Google Cloud SQL connection pool exhausted | 1×/week | 20 min | 1.3h | Yes | P1 |
| sp-asb-consumer Service Bus reconnect | 2×/week | 15 min | 2.0h | Yes | P1 |
| Clever/Google/ClassLink OAuth token renewal | Monthly | 30 min | 0.5h | Yes | P2 |
| Azure Web PubSub certificate renewal | Quarterly | 45 min | 0.25h | Yes | P2 |

**SchoolPass Legacy (SchoolPass) baseline (~3.2 hrs/month):**

| Toil Item | Frequency | Time/Occurrence | Hrs/Month | Automatable | Priority |
|-----------|-----------|-----------------|-----------|-------------|----------|
| BusAPI 5xx investigation — pass request endpoint returning null/500 | 1×/week | 20 min | 1.3h | Yes | P1 |
| Mobile app build failure investigation (Azure DevOps) | 1×/week | 15 min | 1.0h | Partial | P1 |
| QuickPin broken globally — BusAPI config investigation | Ad hoc | 30 min | 0.5h | Partial | P2 |
| GitLab pipeline failure for schoolpass-app / mobile repos | Per deploy | 10 min | 0.4h | Yes | P2 |

**PSW baseline (~6.5 hrs/month avg — US ~7.2h · CA ~5.8h):**

*US (us-east-1 prod):*

| Toil Item | Frequency | Time/Occurrence | Hrs/Month | Automatable | Priority |
|-----------|-----------|-----------------|-----------|-------------|----------|
| ECS task OOM — `psw-us-prod-fargate` manual memory limit increase | 1×/week | 30 min | 2.0h | Partial | P1 |
| Aurora `psw-prod-db` connection pool exhaustion investigation | 1×/week | 20 min | 1.3h | Yes | P1 |
| SQS DLQ `psw-us-prod-passwd-hashing.fifo` manual replay | 1×/week | 25 min | 1.7h | Yes | P1 |
| ADFS `redirectUri` mismatch — manual district config fix | Per onboard | 20 min | 1.0h | Partial | P2 |
| ECR image pull failure — pipeline re-trigger | Per deploy | 10 min | 0.5h | Yes | P2 |
| psw-infra GitLab pipeline failure investigation | 1×/week | 10 min | 0.7h | Yes | P2 |

*Canada (ca-central-1 prod + staging):*

| Toil Item | Frequency | Time/Occurrence | Hrs/Month | Automatable | Priority |
|-----------|-----------|-----------------|-----------|-------------|----------|
| ECS task OOM — `psw-ca-prod-fargate` manual memory limit increase | 2×/month | 30 min | 1.0h | Partial | P1 |
| Aurora `psw-ca-prod` connection pool exhaustion investigation | 2×/month | 20 min | 0.7h | Yes | P1 |
| SQS DLQ `ca-prod-passwd-hashing.fifo` manual replay | 1×/week | 25 min | 1.7h | Yes | P1 |
| Redis session drops — ElastiCache endpoint stale | Monthly | 20 min | 0.3h | Yes | P2 |
| ADFS `redirectUri` mismatch — manual district config fix | Per onboard | 20 min | 1.0h | Partial | P2 |
| psw-infra GitLab pipeline failure investigation | 1×/week | 10 min | 0.7h | Yes | P2 |
| Staging ECS task failure debugging (`psw-ca-staging`) | Ad hoc | 15 min | 0.3h | Yes | P2 |

---

## Phase 4: Automation Recommendations

For each P1 item, provide a specific plan with root cause, automation steps, effort estimate, and monthly savings.

**Key automation patterns by product:**

*Emergency Management P1s:*
- incidents-proxy: set KEDA `minReplicaCount: 1`; add Service Bus queue depth alert
- ANH failures: Azure Monitor alert on PNS error rate > 5%; expose delivery rate as New Relic custom event
- OOMKilled: Enable AKS VPA for `emergency` namespace (`emergency-management-function`: 800Mi limit)

*Training Platform P1s:*
- CDC restart: Add liveness probe checking EventHub consumer lag; configure AKS pod disruption budget
- DLQ replay: Add Azure Monitor alert DLQ > 0; write replay script; add structured NRules logging
- OOMKilled: Enable AKS VPA for `training` namespace

*PSW P1s (apply to detected region):*
- ECS task OOM: Add CloudWatch alarm on task `MemoryUtilization` > 80%; update task definition memory limit; enable ECS service auto-scaling. US: target `psw-us-prod-fargate`; CA: target `psw-ca-prod-fargate`
- Aurora connection pool: Add CloudWatch alarm on `DatabaseConnections` > threshold; enable RDS Proxy to pool connections. US: `psw-prod-db`; CA: `psw-ca-prod`
- SQS DLQ replay: Add CloudWatch alarm on `ApproximateNumberOfMessagesNotVisible` > 0 in DLQ; write replay Lambda or ECS scheduled task. US: `psw-us-prod-passwd-hashing.fifo`; CA: `ca-prod-passwd-hashing.fifo`

---

## Phase 5: Create Jira Toil Reduction Tasks

Ask: "Shall I create Jira items for these automation tasks?"

If yes:
1. `getAccessibleAtlassianResources` for cloudId
2. `getVisibleJiraProjects` → SE project
3. Story: `[TOIL] SRE Toil Reduction — {product} — {month}`
4. Sub-tasks per P1/P2 item

Labels: `toil`, `sre`, `automation`, `{LABEL}`

---

## Phase 6: Toil Tracking Dashboard

Create Confluence page in `PublicScho`:
**Title:** `SRE Toil Register — {Product} — {YYYY-MM}`

Include: inventory table, total hours/month, automation backlog, month-over-month trend.
