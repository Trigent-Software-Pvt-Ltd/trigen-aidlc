---
name: cost-investigate
description: "Investigate Azure cost anomalies from the knowledge base. Two modes: (1) find the latest anomaly for a specific resource and show its trend, or (2) scan all resources with anomalies in a given time period. Cross-references GitLab deployments and Azure activity to diagnose root causes, then writes findings back to the CSV knowledge base. Prompts for az login if Azure CLI session is expired before drill-down. (Triggers: investigate cost, why did cost spike, explain cost increase, cost root cause, diagnose anomaly, cost investigation, what caused the cost)"
allowed-tools: [Bash, AskUserQuestion, mcp__gitlab__get_repository_tree, mcp__gitlab__get_file_contents, mcp__claude_ai_Atlassian__addCommentToJiraIssue, mcp__claude_ai_Atlassian__getJiraIssue, mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql, mcp__claude_ai_Microsoft_365__outlook_email_search, mcp__claude_ai_Microsoft_365__read_resource]
argument-hint: "<resource> [in <subscription>] | <month/period>"
---

# Cost Anomaly Investigator

Investigate cost anomalies from the knowledge base and write root cause findings back to CSV.

## Repository

- **GitLab project**: `trigent1/devsecops/cost-anomalies`
- **Project path**: `trigent1/devsecops/cost-anomalies`
- **Project ID** (URL-encoded): `trigent1%2Fdevsecops%2Fcost-anomalies`

## Help

If `$ARGUMENTS` contains "help", print:

```
/cost-anomalies:cost-investigate <resource> [in <subscription>]
/cost-anomalies:cost-investigate <period>

Two modes:

MODE 1 — Resource investigation
  Find the latest anomaly for a specific resource and show its trend.
  Arguments:
    <resource>              Resource or RG name (partial/fuzzy match)
    in <subscription>       Optional subscription filter

  Examples:
    /cost-anomalies:cost-investigate trigent-legacy-cdn-prod in Production
    /cost-anomalies:cost-investigate aks-app2np prod
    /cost-anomalies:cost-investigate legacy-r6

MODE 2 — Time period scan
  Find all resources with anomalies in a given period.
  Arguments:
    <month>                 e.g. "June", "May 2026"
    --since <YYYY-MM-DD>    Start date
    --until <YYYY-MM-DD>    End date (default: today)
    --unannotated           Only rows with empty notes

  Examples:
    /cost-anomalies:cost-investigate June
    /cost-anomalies:cost-investigate --since 2026-06-01
    /cost-anomalies:cost-investigate --since 2026-06-01 --unannotated
```

---

## Step 1 — Detect mode and parse arguments

From `$ARGUMENTS`, determine which mode to run:

**Mode 1 — Resource** (default when a resource name is provided):
- If argument contains ` in ` → split: everything before = `resource_query`, everything after = `subscription_filter`
- Otherwise treat whole argument as `resource_query`; `subscription_filter` is empty
- Normalise both: lowercase, strip non-alphanumeric → compact form

**Mode 2 — Time period** (when argument looks like a date/period):
- Month name or year-month → parse to `since_date` (first day of month) and `until_date` (last day of month)
- `--since <date>` / `--until <date>` → explicit range
- `--unannotated` flag → only process rows where `notes` is empty

**Ambiguous input** (e.g. just "June" could be a resource OR a period):
- If no matching resource is found in the KB for the query → fall back to Mode 2

---

## Step 1b — Check extraction coverage

Fetch `_index.json` from the KB:

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/_index.json?ref=main" 2>/dev/null \
  | python3 -c "
import sys,json,base64
d=json.load(sys.stdin)
idx=json.loads(base64.b64decode(d['content']).decode()) if 'content' in d else {}
print(json.dumps({'email_covered': idx.get('email_covered',{}), 'jira_covered': idx.get('jira_covered',{})}, indent=2))
" 2>/dev/null
```

If `_index.json` is missing, skip this step and note "No extraction index found — data may be incomplete."

Let `email_until`, `jira_until`, `email_since`, `jira_since` be the values from the index.

### Mode 2 — time period

Compute the missing portion:
- `email_gap` = portion of `[since_date, until_date]` that is **after** `email_until` (empty if fully covered)
- `jira_gap`  = portion of `[since_date, until_date]` that is **after** `jira_until` (empty if fully covered)

**If both gaps are empty** — period is fully covered. Print:
```
✅ Period fully covered (email {email_since}→{email_until} · jira {jira_since}→{jira_until})
```
Then continue to Step 2.

**If any gap exists** — ask before continuing:

```
AskUserQuestion:
  "📦 Extraction coverage
     Email : {email_since} → {email_until}
     Jira  : {jira_since}  → {jira_until}

   ⚠️  Your requested period ({since_date} → {until_date}) extends beyond extracted data.
   Missing: {email_gap or jira_gap — whichever is larger}

   Extract missing data now before investigating?"

  Options:
    "Yes — extract {missing_range} then investigate"
    "No — investigate with available data only"
    "Cancel"
```

- **Yes** → run the full cost-extract steps (Parts A and B from the cost-extract skill) for `period_start = start of gap`, `period_end = until_date`. Use the same GitLab commit and index-update logic. After extraction completes, continue to Step 2 with fresh KB data.
- **No** → continue to Step 2. Print: `⚠️ Investigating with data up to {min(email_until, jira_until)} — results may be incomplete.`
- **Cancel** → stop.

### Mode 1 — single resource

Run this check **after** Step 2 finds the target row (the row's date is known then).

| Situation | Action |
|---|---|
| Row date within both cursors | Silent — no notice needed. |
| `jira_until < today - 2 days` (Jira-schema row) | Ask: **"💡 Jira last extracted {jira_until}. New comments may exist. Re-extract {jira_until+1}→today before investigating?"** Options: `"Yes — extract then investigate"` / `"No — continue"`. |
| `row_date > email_until` (email-schema row) | Ask: **"⚠️ Email extraction only covers to {email_until}. This row ({row_date}) is beyond the cursor. Extract {email_until+1}→{row_date} first?"** Options: `"Yes"` / `"No — continue anyway"`. |

For "Yes" in Mode 1: run cost-extract for the indicated range (email-only or jira-only as appropriate), then re-read the target row before continuing.

---

## Step 2 — Find anomalies in the knowledge base

### Mode 1: Latest anomaly for a resource

Get the repository tree and filter CSV files:

```
mcp__gitlab__get_repository_tree(
  project: "trigent1/devsecops/cost-anomalies",
  ref: "main",
  recursive: true
)
```

Match files using fuzzy logic:
- Normalise `resource_query` and match against path components
- Apply `subscription_filter` if provided

For each matched file, read its content:
```
mcp__gitlab__get_file_contents(
  project: "trigent1/devsecops/cost-anomalies",
  ref: "main",
  path: "<matched_path>"
)
```

Parse all rows. **Target row** = the most recent row (latest `date`).

**Trend** = all rows in the file, sorted chronologically — shown as context.

If zero files match:
```
No data found for "<resource_query>". Has it been imported yet?
Run /cost-anomalies:cost-extract first.
```

### Mode 2: All anomalies in a time period

Read all CSV files in the repo. For each file, collect rows where `date` falls within `[since_date, until_date]`.

If `--unannotated` flag is set, keep only rows where `notes` is empty or whitespace.

Group results by file path. Skip files with zero matching rows.

If no rows found:
```
No anomalies found in the period <since_date> to <until_date>.
```

---

## Step 3 — Display anomaly and trend

### Mode 1 output

```
📍 Resource: <resource_name>
   Path: Azure/<Sub>/<RG>/<resource>.csv
   Schema: email | jira

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 LATEST ANOMALY
   Date     : <date>
   Period   : <period_type>
   Change   : <change_usd or delta_pct>
   Notes    : <existing notes or "(none)">
   Source   : <source_key if jira / observed_at if email>

📈 TREND (<N> prior events)

Date        Period    Change      Notes (truncated)
──────────  ────────  ──────────  ─────────────────────────────────────
2026-04-05  weekly    +$50.70     AKS weekend spike; autoscaler min=10 (Syed)
2026-04-12  weekly    +$50.69     Confirmed 3rd consecutive weekend AKS spike (Syed)
2026-04-19  weekly    +$50.68     AKS node image upgrade Apr 19 (Syed)
2026-05-03  weekly    +$50.70     Autoscaler burst nodes at 07:00 UTC (Syed)
...

Pattern detected: Same resource spiked <N> times — recurring anomaly
```

### Mode 2 output

```
📅 Anomalies: <since_date> → <until_date>

Found <R> anomalies across <F> resources in <S> subscriptions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Subscription: Production
  legacy-r6 / trigent-legacy-cdn-prod   2026-06-09  weekly   +$544.24  (no notes)
  legacy-r6 / trigent-legacy-cdn-prod   2026-06-11  daily    +$416.41  (no notes)
  emergencymanagement / trigent-r8-plan-prod  2026-06-04  daily  +$48.38  (no notes)

Subscription: Staging
  rg-rl-staging-eastus2-1fz0 / adf-rl-staging-eastus2-q5r6  2026-06-05  increase  (no notes)

...

→ Investigating <R> anomalies...
```

---

## Step 4 — Investigate each anomaly

For each anomaly identified (latest in Mode 1, or each row in Mode 2), perform the investigation. In Mode 2 with many rows, process the top 5 by absolute change first, then offer to continue.

### 4a — Baseline comparison

From the CSV file history (rows before the anomaly date):
- Compute **median** and **standard deviation** of `change_usd` / `delta_pct` for the same `period_type`
- Express the anomaly as: `Xσ above median` or `X× typical value`
- Flag as **recurring** if the same resource has ≥ 3 prior rows with similar magnitude

### 4b — Pattern recognition

Match the anomaly against known patterns:

| Pattern | Signals |
|---|---|
| **Deployment-driven** | Spike aligns with a GitLab deployment; cost normalises after 1–3 days |
| **Autoscaler burst** | Resource is a VMSS or AKS node pool; spike is on weekend/Sunday morning |
| **New resource** | `notes` contains "New resource"; `baseline_usd = 0` in monthly schema |
| **Config change** | Spike is sustained month-over-month; prior notes mention a manual change |
| **Data/storage growth** | Incremental monthly increase; resource is SQL/Cosmos/Storage |
| **One-time event** | Single spike with no recurrence; often pipeline overrun or batch job |
| **Recurring known** | Same resource, similar magnitude, already has notes on prior rows |

If prior rows already have explanatory notes → use that as strong evidence for the same pattern.

### Azure CLI pre-check (before Steps 4c-aks, 4c–4e)

**Trigger:** Run once before Step 4c-aks / 4c when either condition is true:
- Anomaly row is email-schema (RG-level), OR
- Anomaly row is Jira-schema with `resource_type = microsoft.compute/virtualmachinescalesets` (AKS node count check also requires CLI)

Skip for all other Jira-schema rows.

```bash
az account get-access-token --output none 2>/dev/null && echo AUTH_OK || echo AUTH_EXPIRED
```

If **AUTH_EXPIRED**:

```
AskUserQuestion:
  "⚠️ Azure CLI session expired
   Steps 4c-aks (node count verification), 4c (resource drill-down), 4d (Azure tags), and 4e (Activity Log) require an active session.

   Run in your terminal:
     ! az login --tenant e7c09548-124d-4328-bb11-60cb1d314be1

   Then select 'I've logged in' to continue."

  Options:
    "I've logged in — continue with full drill-down"
    "Skip Azure CLI steps for this investigation"
    "Cancel"
```

- **I've logged in**: Re-run the check. If still expired → tell user to run `! az login` in the terminal and try again. If OK → proceed.
- **Skip Azure CLI steps**: Proceed without Steps 4c-aks, 4c, 4d (az parts), and 4e. Still run 4b, 4f, 4g, and 4h — note "Azure CLI skipped by user" in the diagnosis.
- **Cancel**: Stop.

If **AUTH_OK** → proceed to Step 4c-aks / Step 4c silently.

---

### 4c-aks — AKS node count verification (VMSS anomalies only)

**Trigger:** Run when the anomaly row has `resource_type = microsoft.compute/virtualmachinescalesets` (Jira schema). This fires for AKS node pool VMSS resources — the most common false-positive pattern in the KB. Skip for all other resource types.

**Purpose:** Distinguish a real autoscaler scaling event from a billing detection glitch. Azure's anomaly algorithm compares against a historical baseline. If the baseline was built when the pool cost was near zero, even a stable $2/day shows as a daily anomaly indefinitely. Node count is the ground truth: no count change = no real event.

Find the AKS cluster whose `nodeResourceGroup` matches the VMSS RG, then pull the `kube_node_status_allocatable_cpu_cores` metric. This is the single best signal: historical, one command, directly reflects whether any pool scaled. Nodepool dimension filter is not supported by this metric — it returns total cluster cores, which is sufficient: any scaling event in any pool moves the cluster total.

```bash
# Step 1 — find the AKS cluster
az aks list \
  --subscription <subscription-id> \
  --query "[?nodeResourceGroup=='<rg-name>'].{name:name,rg:resourceGroup}" \
  --output json 2>/dev/null

# Step 2 — pull cluster node count (±14 days around anomaly)
AKS_ID="/subscriptions/<sub-id>/resourceGroups/<cluster-rg>/providers/Microsoft.ContainerService/managedClusters/<cluster-name>"

az monitor metrics list \
  --resource "$AKS_ID" \
  --metric "kube_node_status_allocatable_cpu_cores" \
  --start-time <anomaly_date-14d>T00:00:00Z \
  --end-time <anomaly_date+3d>T00:00:00Z \
  --interval PT6H \
  --aggregation average \
  --output json 2>/dev/null | python3 -c "
import json, sys, collections
d = json.load(sys.stdin)
for m in d.get('value', []):
    for ts in m.get('timeseries', []):
        daily = collections.defaultdict(list)
        for p in ts.get('data', []):
            if p.get('average') is not None:
                daily[p['timeStamp'][:10]].append(p['average'])
        prev = None
        for day in sorted(daily):
            cores = sum(daily[day]) / len(daily[day])
            changed = '  <- NODE COUNT CHANGED' if prev is not None and abs(cores - prev) > 4 else ''
            print(f'{day}  cores={cores:.0f}{changed}')
            prev = cores
"
```

**Interpret:** Use `az vmss show --query sku` (already run above) to get the pool SKU vCPU count. `total_cores / pool_vcpu = total_nodes`. A flat line = no scaling anywhere in the cluster. A jump of ≥ `pool_vcpu` = at least one node added or removed.

API constraints confirmed by testing:
- P1D interval → rejected; **use PT6H**
- nodepool dimension filter → rejected; metric is cluster-total only
- ~30 days of data available in practice

**Classify:**

| Result | Verdict |
|---|---|
| Cluster cores flat on anomaly date AND cost spike is ≤ 2 days | **BILLING GLITCH** (Confirmed) |
| Cluster cores increased by ≥ 1 node on or just before anomaly date AND cost stays elevated | **REAL SCALE-OUT** (Confirmed) |
| Cluster cores flat AND ≥ 3 sibling VMSS pools spiked on the same date | **BILLING ARTIFACT** (Confirmed — billing queue flush) |

**Output:**

```
🔍 AKS node count verification: <vmss-name>
   Cluster cores: 216 flat May 24–Jun 23 (no change ≥ 4 cores)
   Implied nodes: 27 constant  (216 ÷ 8 vCPU per Standard_D8as_v4)
   Anomaly date : Jun 23 — cores still 216 → no scaling event

   Verdict: BILLING GLITCH — cluster node count unchanged on anomaly date
```

This verdict feeds directly into Step 4g. A BILLING GLITCH or BILLING ARTIFACT verdict overrides Step 4b with:
- **Pattern**: Billing detection glitch
- **Confidence**: Confirmed

---

### 4c — Azure resource drill-down (RG-level anomalies only)

**Trigger condition:** Run this step only when the anomaly file is RG-level — detected by either:
- File path pattern: `Azure/<Sub>/<rg>/<rg>.csv` (same name for folder and file), OR
- CSV header starts with `date,observed_at,period_type,subscription_anomaly_type` (email schema)

Email alerts report at the resource group level, so the spike is known but the individual resource causing it is not. Use `azure-cost` to drill down.

**Subscription ID lookup**

Subscription IDs are in `/Users/viacheslav.frolov/Desktop/GitLab/azure-cost/config/subscriptions.json`. Look up by `name` field:

| Subscription name | Subscription ID |
|---|---|
| Production | `6bbffd39-0d26-4cfd-9286-ce5eaf4dd1c7` |
| Development | `fa03b1fe-6a88-4841-8d25-c3e6f1fd00ca` |
| Staging | `839f609a-30ab-4cb2-8319-d608c1c62eb5` |
| Production – UK | `a0f8cdc1-5b7c-4068-928c-843e68dbb083` |
| Staging – UK | `81ee276e-a1a7-4132-b357-caa3509dd48b` |
| Development – UK | `e2e3692b-c01f-41eb-87bb-e71a6ee6363e` |
| Management | `8acc360a-757b-43c8-9ce1-8ab9253b18e0` |
| POC | `35e4a71d-5444-488e-a689-519e818f9072` |
| Trigent Technologies(Converted to EA) | `47269030-d635-4a50-85a6-88c1c9d8dccd` |
| Trigent Internal Tools | `53d2cf59-dea7-4fa8-b3c4-e4fa3369f0a9` |

**Time window**

Use a **30-day lookback** for all anomaly types:

- **From**: `anomaly_date - 30 days`
- **To**: `anomaly_date + 1 day`

This matches the `--recent-activity-days` detection sensitivity window used by the azure-cost pipeline scripts. Note: the `change_usd` already stored in KB rows is **day-over-day** (anomaly_day_cost − previous_day_cost), not a rolling average against this window. The 30-day history here is for identifying the spike pattern, not for recomputing the delta.

**Query resource-level costs for the subscription:**

The `azure-cost` CLI has no resource group filter flag — fetch all resources for the subscription, then filter by RG name in the output.

```bash
azure-cost dailyCosts \
  -s <subscription_id> \
  --dimension ResourceId \
  --from <from_date> \
  --to <to_date> \
  -t Custom \
  -o json 2>/dev/null
```

**Filter and rank by resource group:**

Parse the JSON output and filter to the target RG:

```python
import json, subprocess

result = subprocess.run(
    ["azure-cost", "dailyCosts", "-s", sub_id,
     "--dimension", "ResourceId",
     "--from", from_date, "--to", to_date,
     "-t", "Custom", "-o", "json"],
    capture_output=True, text=True, timeout=300
)

data = json.loads(result.stdout)

# Aggregate cost per ResourceId, filtered by ResourceGroupName
costs = {}
for entry in (data if isinstance(data, list) else []):
    for item in entry.get("Items", []):
        rid = item.get("Name", "")   # azure-cost uses "Name" for the resource path
        # Extract resource group from resource path
        parts = rid.lower().split("/")
        rg = parts[parts.index("resourcegroups") + 1] if "resourcegroups" in parts else ""
        if rg != target_rg.lower():
            continue
        resource_name = parts[-1]
        cost = float(item.get("Cost", 0))   # azure-cost uses "Cost" directly
        costs[resource_name] = costs.get(resource_name, 0) + cost

# Sort by cost descending — top drivers first
top = sorted(costs.items(), key=lambda x: x[1], reverse=True)[:5]
```

**Interpret the results and drill into the top resource by meter:**

From the ResourceId query, identify the top cost driver. Then run a second query scoped to that resource with `--dimension Meter` to get the cost breakdown by billing meter (vCPU, Memory, Data Transfer Out, etc.):

```bash
# Get full ResourceId of the top resource from the first query output
# e.g. /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.ContainerInstance/containerGroups/<name>
TOP_RESOURCE_ID="<full-resource-id-from-prior-output>"

~/.dotnet/tools/azure-cost dailyCosts \
  -s <subscription_id> \
  --dimension Meter \
  --filter "ResourceId=$TOP_RESOURCE_ID" \
  --from <from_date> \
  --to <to_date> \
  -t Custom \
  -o json 2>/dev/null | python3 -c "
import json, sys, collections

data = json.loads(sys.stdin.read())
anomaly_date = '<anomaly_date>'

meter_on_day = collections.defaultdict(float)
meter_baseline = collections.defaultdict(list)

for entry in (data if isinstance(data, list) else []):
    date_str = str(entry.get('Date',''))[:10]
    for item in entry.get('Items', []):
        meter = item.get('Name', 'unknown')
        cost = float(item.get('Cost', 0))
        if date_str == anomaly_date:
            meter_on_day[meter] += cost
        else:
            meter_baseline[meter].append(cost)

print(f'Meter breakdown on {anomaly_date}:')
print(f'{\"Meter\":<45} {\"Anomaly day\":>12}  {\"Baseline avg\":>13}  {\"Increase\":>10}')
print('-' * 85)
for meter, day_cost in sorted(meter_on_day.items(), key=lambda x: x[1], reverse=True):
    baseline = meter_baseline.get(meter, [])
    avg = sum(baseline) / len(baseline) if baseline else 0
    inc = day_cost - avg
    print(f'{meter:<45} \${day_cost:>11,.2f}  \${avg:>12,.2f}  \${inc:>+9,.2f}')
"
```

This matches the breakdown in Syed's investigation reports (e.g. `Standard vCPU Duration: $424.57` + `Standard Memory Duration: $93.13`).

```
Resource drill-down: <rg-name> on <anomaly-date>

ResourceId                                          Cost (anomaly day)  vs prior avg
─────────────────────────────────────────────────── ──────────────────  ────────────
/.../<rg-name>/providers/.../trigent-legacy-cdn-prod  $1,432.56          +496% ← TOP
/.../<rg-name>/providers/.../longtermretentionbackups  $289.45           +12%
...
```

**Cross-reference with Cost KB:**

For each top resource found, check whether a Jira-schema file already exists in the KB:
```
Azure/<Sub>/<rg-name>/<resource-name>.csv
```

If it exists → read it. It may already have investigation notes from a Jira ticket that explains the spike.
If it does not exist → the resource has only been seen at RG level so far. Note it as a new finding.

**Output the drill-down finding** — carry it into the diagnosis step:
```
🔍 Azure drill-down: top cost driver in <rg-name>
   Resource : <resource-name>
   Type     : <resource-type>
   Cost     : $X on <date> vs $Y baseline (+Z%)
   In KB    : yes (Azure/<Sub>/<rg>/<resource>.csv) | no (new)
```

If azure-cost returns empty data despite a valid session → note "No resource-level cost data available for this date range" in the diagnosis and skip the meter breakdown.

### 4d — GitLab deployment cross-reference

Search for pipeline activity around the anomaly date (±3 days).

**Use the SRE KB as the primary source** for GitLab project IDs and infrastructure context. Fall back to name-based search only when the KB doesn't cover the subscription.

#### Step 0 — Check Azure resource tags (`rt-*` schema)

Before consulting the SRE KB, check if the resource or resource group has `rt-*` tags. These are the standard Trigent tagging convention and are the most reliable source when present.

**Get tags on the resource group:**
```bash
az group show \
  --name <rg-name> \
  --subscription <subscription-id> \
  --query tags \
  --output json 2>/dev/null
```

**If azure-cost drill-down identified a specific resource, also get its tags:**
```bash
az resource show \
  --ids "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/<resource-type>/<resource-name>" \
  --query tags \
  --output json 2>/dev/null
```

**Trigent `rt-*` tag schema:**

| Tag key | Example value | Action |
|---|---|---|
| `rt-product` | `camera-detection`, `trigent-link`, `emergency-management` | Map to SRE KB slug (see table below) |
| `rt-owner` | `dismissal-automation`, `trigentlink-team` | Use as GitLab project search keyword |
| `rt-stage` | `prod`, `staging`, `dev` | Confirms environment — context only |
| `rt-deployed` | `terraform`, `bicep` | Deployment method — context only |

**`rt-product` → SRE KB slug mapping:**

| `rt-product` value | SRE KB slug |
|---|---|
| `camera-detection`, `dismissal*` | `dismissal` |
| `trigent-link*`, `trigentlink*`, `integrations*` | `integrations` |
| `emergency-management*`, `em-*` | `em` |
| `training*` | `training` |
| `visitor-management*`, `visitorsafe*` | `vm` |
| `volunteer*` | `volunteer` |
| `cpoms*`, `studentsafe*` | `cpoms-studentsafe` |
| `staffsafe*` | `cpoms-staffsafe` |
| `smartpass*` | `smartpass` |
| `schoolpass*` | `schoolpass` |
| `eventsafe*` | `eventsafe` |

If `rt-product` resolves to a slug → **skip Step 1 and go directly to Step 2** (fetch infrastructure.md from that slug's KB project).

If `rt-owner` is present but `rt-product` is missing → use `rt-owner` value as the search keyword in Step 3 (name-based fallback).

**If no `rt-*` tags found** → proceed to Step 1 (SRE KB slug resolution by RG name pattern).

Output the tag findings:
```
🏷️  Azure tags on <rg-name>:
   rt-product  : camera-detection  → slug: dismissal  ✅
   rt-owner    : dismissal-automation
   rt-stage    : prod
   rt-deployed : terraform
```
or:
```
🏷️  Azure tags on <rg-name>: no rt-* tags found → falling back to SRE KB name lookup
```

#### Step 1 — Resolve product slug via KB-RESOLVER

Map the resource group name and subscription to a product slug using KB-RESOLVER.md §1 patterns:

| RG name pattern | Subscription | Slug |
|---|---|---|
| `rg-rl-*`, `trigentlink-*`, `TrigentLink` | any | `integrations` |
| `prod-rg-re1-pe`, `prod-rg-aks-*` | Production | `integrations` (APIM) or check RG contents |
| `emergencymanagement`, `em-*` | Production | `em` |
| `training-*`, `rg-trng-*` | Staging | `training` |
| `visitormanagement*` | Production | `vm` |
| `cpomsuk-prod-rg`, `produk-rg-*` | Production – UK | `cpoms-staffsafe` |
| `legacy-r6`, `legacy-ssk` | Production | legacy — no KB entry; use name-based search |
| `trigent-corporate`, `trigent-migrated` | Trigent Technologies EA | no KB entry; skip GitLab check |
| `rg-eastus2-netdata`, `it-security` | Management / Internal | no KB entry; skip GitLab check |

If no slug resolves → skip to Step 3 (name-based fallback).

#### Step 2 — Fetch GitLab context from SRE KB

For the resolved slug, fetch the product's `infrastructure.md` from the SRE KB:

```bash
# Step A: Get product KB project path from products.yaml
glab api "projects/trigent1%2Fdevsecops%2Fsre-kb%2Fkb-shared/repository/files/products.yaml?ref=main" \
  2>/dev/null | python3 -c "
import sys,json,base64,re
d=json.load(sys.stdin)
content=base64.b64decode(d['content']).decode()
# Parse YAML minimally — find the project field for the slug
for line in content.split('\n'):
    if 'project:' in line: print(line.strip())
" 2>/dev/null | grep <slug>

# Step B: Fetch infrastructure.md from the product KB
glab api "projects/<kb-project-url-encoded>/repository/files/resources%2Finfrastructure.md?ref=main" \
  2>/dev/null | python3 -c "import sys,json,base64; d=json.load(sys.stdin); print(base64.b64decode(d['content']).decode())" 2>/dev/null
```

From `infrastructure.md`, extract:
- **GitLab stack project ID** — look for lines like `Stack: ... (ID \`NNNNN\`)` or table rows with `GitLab Repo ID`
- **GitLab group ID** — look for `group ID: NNNNN`
- **Production resource groups** — for Production and Production – UK subscriptions, the KB lists known RGs and their contents
- **Known services in the anomalous RG** — e.g. for `rg-rl-*`: ADF, SQL, Service Bus, Key Vault

**SRE KB coverage:**
- ✅ Production and Production – UK subscriptions: GitLab project IDs, resource group contents, service names
- ⚠️ Staging / Development: KB documents production only; staging RGs are not listed
- ❌ `legacy-r6`, `trigent-corporate`, Management, Internal: no KB entry

#### Step 3 — Name-based fallback (when KB has no entry)

If no slug was found, or the KB doesn't cover the subscription, infer the project from the resource group name:

```bash
# Extract meaningful keyword from RG name and search
glab api "projects?search=<keyword>&per_page=10" 2>/dev/null | \
  python3 -c "import json,sys; [print(p['id'], p['path_with_namespace']) for p in json.load(sys.stdin)]" 2>/dev/null
```

Keywords by RG prefix: `rg-rl-*` → `trigent-link-stack`, `adf-*` → `trigent-link`, `emergencymanagement` → `emergency-management`, `visitormanagement` → `visitor`.

#### Step 4 — Check pipelines

With the resolved project ID(s), query pipelines ±3 days around the anomaly date:

```bash
glab api "projects/<PROJECT_ID>/pipelines?updated_after=<date-3d>&updated_before=<date+3d>&per_page=20" 2>/dev/null | \
  python3 -c "
import json,sys
for p in json.load(sys.stdin):
    print(f\"{p.get('created_at','')[:16]}  [{p.get('status','')}]  {p.get('ref','')}  pipeline/{p.get('id')}\")
" 2>/dev/null
```

**Output:**
```
🔗 GitLab context (from SRE KB: integrations)
   Group      : trigent1/trigent/integrations (85254509)
   Stack repo : trigent-link-stack (75716434)
   Pipelines ±3d around <anomaly-date>:
     2026-06-10T21:23  [success]  refs/merge-requests/64/head  pipeline/2592463314
     2026-06-09T20:53  [failed]   feature/PLT-3311-apple-pass  pipeline/2589287837
```

Only run this step if the pattern is not already **Recurring known** — avoid redundant work.

### 4e — Azure Activity Log check

**When to run:** Only if Step 4d (GitLab) did **not** produce a pipeline that explains the spike. Terraform deployments show up as GitLab pipelines — if one was found and matches the anomaly timing, skip this step. Run it to catch **manual Portal/CLI changes** that exist outside of version control.

This is the single source of truth for changes made directly in the Azure Portal, via the Azure CLI outside of Terraform, by autoscalers, and by Azure's own platform operations.

```bash
az monitor activity-log list \
  --resource-group <rg-name> \
  --subscription <subscription-id> \
  --start-time <anomaly-date-3d> \
  --end-time <anomaly-date+1d> \
  --query "[?status.value == 'Succeeded'].{time:eventTimestamp,caller:caller,op:operationName.value}" \
  --output table 2>/dev/null
```

**Focus on write/action operations** — filter out read-only noise:
```bash
az monitor activity-log list \
  --resource-group <rg-name> \
  --subscription <subscription-id> \
  --start-time <anomaly-date-3d> \
  --end-time <anomaly-date+1d> \
  --query "[?contains(operationName.value, 'write') || contains(operationName.value, 'action')].{time:eventTimestamp,caller:caller,op:operationName.value}" \
  --output table 2>/dev/null
```

**Interpret the `caller` field:**

| Caller pattern | What it means |
|---|---|
| `someone@trigent.com` | Manual change in Azure Portal or `az` CLI by a human |
| `infrastructure-gitlab-deployment` | Terraform/ARM pipeline (not GitLab project based — check service-stacks) |
| `Microsoft.Compute` or `AKSNodeGroup*` | Azure autoscaler or platform-triggered operation |
| `Microsoft.Web` or `AzureContainerService` | Azure-internal platform event (not human-triggered) |
| `eventsafe-arm-connection`, `platform-arm-*` | ARM deployment pipeline from another GitLab project |

**Key operations to flag:**

| Operation | Resource type | Significance |
|---|---|---|
| `Microsoft.Web/serverfarms/write` | App Service Plan | SKU or instance count change |
| `Microsoft.Compute/virtualMachineScaleSets/write` | VMSS/AKS | Node pool resize or config change |
| `Microsoft.DataFactory/factories/pipelines/createRun/action` | ADF | Pipeline triggered (human or automation) |
| `Microsoft.Fabric/capacities/write` | Fabric | Capacity resumed/resized |
| `Microsoft.Sql/servers/elasticPools/write` | SQL | Elastic pool tier or eDTU change |
| `Microsoft.Cache/Redis/write` | Redis | SKU or capacity change |

**Output:**
```
🗒️  Activity Log: <rg-name> ±3 days around <anomaly-date>

Time              Caller                          Operation
────────────────  ──────────────────────────────  ─────────────────────────────────
2026-06-10T14:32  dbash@trigent.com            Microsoft.Sql/servers/write ← human change
2026-06-11T07:44  AKSNodeGroup/autoscaler         Microsoft.Compute/virtualMachineScaleSets/write
```

If no write operations found → the cost increase is usage-driven (workload, traffic, data growth), not a configuration change. No action log evidence — note it in the diagnosis.

### 4f — Read budget from KB

Before synthesising, check whether the RG has a `_budget.json` in the KB:

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/<encoded-Azure-Sub-RG-_budget.json>?ref=main" \
  2>/dev/null | python3 -c "
import sys, json, base64
d = json.load(sys.stdin)
b = json.loads(base64.b64decode(d['content']).decode())
print(f\"budget={b['monthly_budget_usd']} basis={b['basis_usd']} variance={b['variance']}\")
" 2>/dev/null
```

If found, calculate the anomaly's share of the monthly budget:

```python
change_usd = <from row>               # absolute cost change from the anomaly row
budget     = b['monthly_budget_usd']  # from _budget.json
pct        = abs(change_usd) / budget * 100 if budget else None

if   pct is None:       priority = 'unknown'
elif pct >= 50:         priority = '🔴 HIGH — > 50% of monthly budget'
elif pct >= 20:         priority = '⚠️  MEDIUM — 20–50% of monthly budget'
elif pct >= 5:          priority = '🟡 LOW — 5–20% of monthly budget'
else:                   priority = '✅ NEGLIGIBLE — < 5% of monthly budget'
```

If no `_budget.json` exists → skip this step silently (budget not yet generated).

### 4f-advisor — Read advisor recommendations from KB

Derive the subscription name from the anomaly file path (`Azure/<Sub>/...`). Fetch the usage optimization advisor CSV for that subscription:

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "Azure/<Sub>/advisor_usage_optimization.csv")?ref=main" 2>/dev/null \
  | python3 -c "
import sys, json, base64, csv, io
d = json.load(sys.stdin)
if 'content' not in d:
    print('NOT_FOUND'); exit()
rows = list(csv.DictReader(io.StringIO(base64.b64decode(d['content']).decode())))
print(json.dumps(rows))
" 2>/dev/null
```

If the file doesn't exist → skip silently (advisor not yet run).

Filter rows to those where `resource_group` matches the anomaly's RG **or** `resource` matches the anomaly's resource name (case-insensitive substring match).

If no matching rows → skip silently.

**Staleness check:** read `advisor_covered.until` from `_index.json` (already in memory from Step 1b). If the date is more than 30 days before today → append to output: `⚠️ Advisor data is N days old — run /cost-anomalies:cost-advisor to refresh`.

**Output when matching rows exist:**

```
💡 Advisor recommendations  (as of <advisor_covered.until>)
   <resource> [<RG>]: <category> — <recommendation>  [<impact>]
     SKU: <current_sku> → <target_sku>   CPU: <cpu_p95>  Mem: <mem_p95>  Savings: $<annual_savings_usd>/yr
```

Prefix with `⛔` when `category = shutdown`. Omit empty fields.

Carry matching rows into Step 4g — a right-size or shutdown recommendation for the anomalous resource is supporting evidence. Include in the Evidence list:

```
- Azure Advisor: <category> recommended for <resource> — <recommendation> [<impact>]
```

### 4g — Synthesise diagnosis

Combine all signals into a short diagnosis, including budget context when available:

```
Diagnosis : <pattern name>
Confidence: Confirmed | Likely | Unclear
Evidence  :
  - <signal 1>
  - <signal 2>
  - <signal 3>
Budget    : $<change_usd> = <pct>% of $<budget>/month RG budget  [<priority>]
Action    : <recommended action or "No action needed">
```

**Confidence rules:**
- **Confirmed** — 2+ corroborating signals (e.g. prior note + GitLab pipeline + recurring pattern)
- **Likely** — 1 strong signal (e.g. deployment found in window, or clear recurring pattern)
- **Unclear** — no matching pattern, no deployment found, no prior context

**Priority escalation from budget context:**
- If `pct >= 50` and confidence is Likely → upgrade to **Confirmed** (budget impact is itself strong evidence)
- If `pct >= 50` → always include in the Jira comment (Step 7), regardless of confidence level

### 4h — Render investigation report

After the diagnosis is complete, render a structured report to the terminal. This is the human-readable output of the investigation — all findings from Steps 4a–4g assembled into one document.

```markdown
# Azure Cost Investigation
**<Subscription> | <Resource Group>**
**Date:** <today>

---

## 1. Background

<Anomaly context from KB: period type, cost delta, first seen date, any existing notes>

---

## 2. Affected Resources

| Resource | Provisioning state | First anomaly | Cost change | Subscription |
|---|---|---|---|---|
| <resource-name> | <from az resource show> | <first date in KB> | <change_usd or delta_pct> | <sub> |

---

## 3. Root Cause

**Pattern:** <diagnosis pattern name> — <Confirmed | Likely | Unclear>

**Evidence:**
- <signal 1 — e.g. Activity Log entry>
- <signal 2 — e.g. recurring pattern in prior rows>
- <signal 3 — e.g. GitLab pipeline match>

**Meter breakdown** (top drivers vs 7-day baseline):

| Meter | Baseline avg/day | Anomaly period | Increase |
|---|---|---|---|
| <meter name> | $X | $Y | +$Z |
| ... | | | |

*(Omit table if azure-cost drill-down was unavailable)*

---

## 4. Cost Impact

| Resource | Period | Change | % of RG Budget | Priority |
|---|---|---|---|---|
| <name> | <date-range> | <change_usd> | <pct>% | <🔴 / ⚠️ / 🟡 / ✅> |

**RG budget:** $<monthly_budget_usd>/month  *(omit line if no _budget.json)*

---

## 5. Additional Observations

<Cross-environment findings, GitLab project context, SRE KB notes — or "None" if nothing notable>

---

## 6. Recommended Actions

1. <Action derived from diagnosis — e.g. "Scale down instance count", "Monitor next billing cycle", "No action needed">
2. <Second action if applicable>

---

*Source: trigent1/devsecops/cost-anomalies*
```

---

## Step 5 — Generate notes

From the diagnosis, generate a `notes` string (max 200 chars, no commas):

- **Confirmed/Likely deployment**: `"Expected — <pipeline/project> deployment on <date> (auto-detected)"`
- **Autoscaler/AKS**: `"Recurring: AKS autoscaler burst; minCount too high — see prior rows"`
- **Config change**: `"Config change confirmed in prior investigation — same pattern"`
- **Data growth**: `"Organic storage/data growth — expected; monitor monthly"`
- **RG-level with drill-down**: `"Top driver: <resource-name> (+X%); <pattern> (azure-cost)"`
- **RG-level without drill-down**: `"RG-level alert; drill down with azure-cost show --resource-group <rg>"`
- **Unclear**: leave notes empty, flag for manual review

If notes already exist on the row → do not overwrite unless the existing note is just "New resource" (can enrich it).

---

## Step 6 — Confirm and commit

Show a summary of proposed changes before writing:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Proposed notes updates

  Azure/Production/legacy-r6/trigent-legacy-cdn-prod.csv
    Row 2026-06-09 weekly  →  "Recurring: CDN weekday spike after low weekend; traffic-based billing"
    Row 2026-06-11 daily   →  "Recurring: CDN weekday spike after low weekend; traffic-based billing"

  Azure/Staging/rg-rl-staging-eastus2-1fz0/adf-rl-staging-eastus2-q5r6.csv
    Row 2026-06-05 increase →  "Expected — TrigentLink staging deployment (auto-detected)"

Write these notes to the knowledge base? [y/n/edit]
```

**Email-schema rows — also write USD columns:**

If azure-cost drill-down data was fetched in Step 4c for an email-schema row (identified by `subscription_anomaly_type` header), extract the RG-level daily costs and populate the three USD columns:

```python
# From the azure-cost dailyCosts output already in memory:
comparison_usd = rg_costs.get(anomaly_date, None)        # RG cost on anomaly_date
baseline_usd   = rg_costs.get(anomaly_date_minus_1, None) # RG cost on day before
if comparison_usd is not None and baseline_usd is not None:
    change_usd = round(comparison_usd - baseline_usd, 2)
    baseline_usd   = round(baseline_usd, 2)
    comparison_usd = round(comparison_usd, 2)
```

Write these values into the matching row's `baseline_usd`, `comparison_usd`, `change_usd` columns. Leave them empty if azure-cost returned no data for either date.

On confirmation, commit using the GitLab Commits API:

```bash
cat << 'PAYLOAD' | glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/commits" \
  -X POST -H "Content-Type: application/json" --input -
{
  "branch": "main",
  "commit_message": "cost: auto-investigate anomalies <date-range> (<N> notes written)",
  "actions": [...]
}
PAYLOAD
```

Output on success:

```
✅ Investigation complete

Anomalies investigated : <N>
Notes written          : <W>
Unclear (need review)  : <U>
Skipped (had notes)    : <S>

GitLab: https://gitlab.com/trigent1/devsecops/cost-anomalies
```

---

## Step 7 — Post Jira comment (Jira-sourced rows only)

**Trigger:** Run this step only when anomaly rows have a `source_key` (Jira schema — `date,observed_at,source_key,...`). Email-schema rows have no Jira ticket to comment on.

After the KB commit, post investigation findings to Jira **automatically** — no prompt required — based on confidence:

| Confidence | Action |
|---|---|
| **Confirmed** | Post comment automatically (no prompt) |
| **Likely** | Post comment automatically (no prompt) |
| **Unclear** | Skip — do not post; output "Jira comment skipped (Unclear confidence)" |

Only ask `[y/n]` when something genuinely unusual warrants manual review (edge case with conflicting signals). Standard runs post without asking.

### Mode 2 — aggregate by source_key

In Mode 2 (time period scan), multiple rows from different resources often share the same `source_key` (e.g. all weekly anomaly rows for the same Jira Bolt ticket). **Post one combined comment per unique `source_key`**, not one comment per row.

Grouping logic:
1. After all rows in the period are investigated, group findings by `source_key`
2. For each `source_key` group, collect all `(resource_name, rg, confidence, diagnosis)` tuples
3. Build one combined comment listing all resources and their findings
4. Post the single combined comment to the ticket once

If a `source_key` group contains a mix of Confirmed/Likely and Unclear rows → still post (the Confirmed/Likely findings justify the comment; include the Unclear rows in the table with "Review needed" in the Action column).

### Fetch the ticket

```
mcp__claude_ai_Atlassian__getJiraIssue(
  cloudId: "trigent1.atlassian.net",
  issueIdOrKey: "<source_key>",
  fields: ["summary", "status", "comment"]
)
```

If the ticket is already **Closed** → still post (investigation notes are valuable even on closed tickets).

### Format the comment

**Mode 1 (single resource) or Mode 2 group with exactly 1 resource:**

```
**Cost Anomaly Investigation — <resource-name> (<date>)**

**Root Cause:** <pattern name>
**Confidence:** Confirmed | Likely

**Evidence:**
- <signal 1>
- <signal 2>
- <signal 3>

**Cost impact:** $<change_usd> (<delta_pct>% change) on <date>
**Budget context:** $<change_usd> = <pct>% of $<budget>/mo RG budget — <🔴 HIGH | ⚠️ MEDIUM | 🟡 LOW | ✅ NEGLIGIBLE>
_(Budget source: Azure/Sub/RG/_budget.json — 6-month median × 1.2)_

**Action:** <recommended action or "No action needed">

_Investigated automatically via cost-investigate | <date>_
```

**Mode 2 (multiple resources sharing one source_key):**

```
**Cost Anomaly Investigation — <N> resources (<ticket-period>)**

| Resource | RG | Confidence | Root Cause | Cost Change | Action |
|---|---|---|---|---|---|
| <resource-1> | <rg-1> | Confirmed | <pattern> | $X (+Y%) | No action needed |
| <resource-2> | <rg-2> | Likely | <pattern> | $A (+B%) | Monitor |
| <resource-3> | <rg-3> | Unclear | — | $C (+D%) | Review needed |

**Summary:** <N> resources investigated — <C> confirmed/likely (no action or monitor), <U> unclear (manual review)

_Investigated automatically via cost-investigate | <date>_
```

Strip any field that's empty. Keep it concise — aim for the same length as Syed's comments (5–10 lines for Mode 1; table format for Mode 2 with > 1 resource).

### Post the comment

```
mcp__claude_ai_Atlassian__addCommentToJiraIssue(
  cloudId: "trigent1.atlassian.net",
  issueIdOrKey: "<source_key>",
  body: "<formatted comment>"
)
```

Output on success:

```
💬 Comment posted to DEVSECOPS-XXXX
   https://trigent1.atlassian.net/browse/DEVSECOPS-XXXX
```

**Skip Jira comment if:**
- Row has no `source_key` (email schema)
- `source_key` does not match pattern `DEVSECOPS-NNNN`
- All rows for this `source_key` have Unclear confidence (entire group has no actionable finding)

---

## Error handling

| Situation | Action |
|---|---|
| Resource not found in KB | Suggest running `cost-extract` first |
| GitLab group lookup fails | Skip deployment check, proceed without it |
| All anomalies already have notes | Output: "All anomalies in this period are already annotated" |
| Mode 2 returns > 20 rows | Process top 5 by absolute change, offer to continue |
| GitLab 401/403 | Stop: "Check `glab auth status`" |
