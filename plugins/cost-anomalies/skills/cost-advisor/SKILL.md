---
name: cost-advisor
description: "Pull Azure Advisor UsageOptimization cost recommendations across all subscriptions. Groups by recommendation type; highlights right-sizing candidates (any resource with a current→target SKU or shutdown action) vs other optimisation hints. Also shows Rate Optimization recommendations (reserved instances and savings plans, 1-year term, 30-day lookback). Saves results to the cost-anomalies KB as advisor_usage_optimization.csv and advisor_rate_optimization.csv per subscription for use by cost-investigate and cost-report. (Triggers: cost advisor, azure advisor recommendations, right-size, rightsizing, right sizing, usage optimization, underutilized, advisor cost, reserved instances, savings plan, reservations)"
allowed-tools: [Bash, AskUserQuestion]
argument-hint: "[--subscription <name>] [--right-size-only] [--rate-only] [--save-only]"
---

# Azure Cost Advisor

Pull Azure Advisor UsageOptimization recommendations across all subscriptions, group by recommendation type, and display the results.

## Subscription reference

| Name | ID |
|---|---|
| Production | `6bbffd39-0d26-4cfd-9286-ce5eaf4dd1c7` |
| Production-UK | `a0f8cdc1-5b7c-4068-928c-843e68dbb083` |
| Staging | `839f609a-30ab-4cb2-8319-d608c1c62eb5` |
| Staging-UK | `81ee276e-a1a7-4132-b357-caa3509dd48b` |
| Development | `fa03b1fe-6a88-4841-8d25-c3e6f1fd00ca` |
| Trigent Internal Tools | `53d2cf59-dea7-4fa8-b3c4-e4fa3369f0a9` |

---

## Step 1 — Parse arguments

From `$ARGUMENTS`:

- `--subscription <name>` → filter to that subscription only (case-insensitive). **Cursor will NOT advance** — partial runs never mask unextracted subscriptions.
- `--right-size-only` → show only right-sizing candidates; suppress optimisation hints and rate optimization
- `--rate-only` → show only rate optimization recommendations; suppress right-sizing candidates and optimisation hints
- `--save-only` → skip display entirely; fetch recommendations and save to KB only (useful for scheduled refreshes)

---

## Step 2 — Check Azure CLI auth

```bash
az account get-access-token --output none 2>/dev/null && echo AUTH_OK || echo AUTH_EXPIRED
```

If **AUTH_EXPIRED**:

```
AskUserQuestion:
  "⚠️ Azure CLI session expired.
   Run in your terminal:
     ! az login --tenant e7c09548-124d-4328-bb11-60cb1d314be1
   Then select 'I've logged in' to continue."

  Options:
    "I've logged in — continue"
    "Cancel"
```

Re-run the check after login. If still expired → ask user to retry `! az login`. If OK → continue.

---

## Step 3 — Fetch recommendations

For each subscription in scope:

```bash
az advisor recommendation list \
  --subscription <sub_id> \
  --category Cost \
  --output json 2>/dev/null
```

For each record, extract a normalised row:

```python
ep = rec.get("extendedProperties") or {}

row = {
    "subscription":      sub_name,
    "rec_name":          rec["shortDescription"]["solution"],
    "resource":          rec.get("impactedValue", "?"),
    "resource_group":    rec.get("resourceGroup", "?"),
    "resource_type":     rec.get("impactedField", "?"),
    "impact":            rec.get("impact", "?"),
    "last_updated":      (rec.get("lastUpdated") or "")[:10],
    "subcategory":       ep.get("recommendationSubCategory", ""),
    # present for right-sizing recs (any resource type)
    "current_sku":       ep.get("currentSku", ""),
    "target_sku":        ep.get("targetSku", ""),
    "rec_type":          ep.get("recommendationType", ""),   # "SkuChange" | "Shutdown" | ""
    "current_tier":      ep.get("siteSku", ep.get("currentTier", "")),
    "target_tier":       ep.get("targetSku", ep.get("targetTier", "")),
    # utilisation signals (populated for some rec types, empty for others)
    "max_cpu_p95":       ep.get("MaxCpuP95", ""),
    "max_mem_p95":       ep.get("MaxMemoryP95", ""),
    "max_cpu_plan":      ep.get("maxCpuServicePlan", ""),   # App Service plan CPU %
    # savings
    "annual_savings":    float(ep.get("annualSavingsAmount") or ep.get("savingsAmount") or 0),
    "currency":          ep.get("savingsCurrency", "USD"),
    "region":            ep.get("regionId", ep.get("region", "")),
}
```

Keep only rows where `subcategory.lower() == "usageoptimization"` for the usage optimisation pipeline (Steps 4–6).

Preserve the full raw recommendation records from each subscription for Step 3b.

---

## Step 3b — Extract rate optimization rows

From the raw recommendation records already fetched in Step 3 (do not re-run the CLI), extract rate optimization rows.

For each record across all subscriptions:

```python
ep = rec.get("extendedProperties") or {}
subcategory = ep.get("recommendationSubCategory", "").lower()

# Keep reservation and savings plan recommendations only
# Actual subcategory values from Azure Advisor API: "Reservations" and "SavingsPlan"
RATE_SUBCATEGORIES = {"reservations", "savingsplan"}
if subcategory not in RATE_SUBCATEGORIES:
    continue

# Filter: 1-year term only (skip P3Y)
term = ep.get("term", "")
if term and term != "P1Y":
    continue

# Filter: 30-day lookback only (skip "60" and "90")
# Azure Advisor returns lookbackPeriod as a plain number string: "30", "60", "90"
lookback = str(ep.get("lookbackPeriod", ""))
if lookback and lookback not in {"30", "30days", "last30days"}:
    continue

rate_row = {
    "subscription":   sub_name,
    "rec_name":       rec["shortDescription"]["solution"],
    "resource":       rec.get("impactedValue", "?"),
    "resource_group": rec.get("resourceGroup", "?"),
    "resource_type":  rec.get("impactedField", "?"),
    "impact":         rec.get("impact", "?"),
    "subcategory":    ep.get("recommendationSubCategory", ""),  # "Reservations" | "SavingsPlan"
    "term":           term,                                      # "P1Y"
    "lookback":       lookback,                                  # "30"
    "scope":          ep.get("scope", ""),                       # "Single" | "Shared"
    "region":         ep.get("region", ep.get("regionId", "")),
    # Azure Advisor uses "displaySKU" for the human-readable SKU name, "sku" as fallback
    "sku":            ep.get("displaySKU", ep.get("sku", "")),
    # "displayQty" is the normalised quantity; "qty" is the raw quantity
    "quantity":       float(ep.get("displayQty", ep.get("qty", 0)) or 0),
    "annual_savings": float(ep.get("annualSavingsAmount") or ep.get("savingsAmount") or 0),
    "currency":       ep.get("savingsCurrency", "USD"),
}

# Assign category for display grouping
sku_lower = (rate_row["sku"] or "").lower()
rec_lower = rate_row["rec_name"].lower()

if rate_row["subcategory"].lower() == "savingsplan":
    rate_row["category"] = "compute" if "compute" in sku_lower else "database" if "database" in sku_lower else "other"
elif any(k in rec_lower for k in ["virtual machine", "app service", "functions", "container instance", "dedicated host", "container app", "spring app"]):
    # Compute Savings Plan covers: VMs, App Service, Functions Premium, Container Instances,
    # Dedicated Host, Container Apps, Spring Apps for Enterprise
    rate_row["category"] = "compute"
elif any(k in rec_lower for k in ["sql", "mysql", "cosmos", "documentdb", "postgresql", "mariadb", "database migration"]):
    # Database Savings Plan covers: SQL DB/MI/Hyperscale/serverless, PostgreSQL, MySQL,
    # Cosmos DB, DocumentDB, Database Migration Service, SQL Server on VMs (hourly licenses)
    # NOTE: Redis (Azure Cache for Redis) is NOT covered by Database Savings Plan → Other
    rate_row["category"] = "database"
else:
    # Other: Redis reservations, Managed Disks (storage), Data Explorer (analytics),
    # Fabric, and any service not covered by either savings plan
    rate_row["category"] = "other"
```

Collect all qualifying entries into `rate_optimization_rows`.

---

## Step 4 — Classify each row


A row is a **right-sizing candidate** when any of the following is true:
- `current_sku` is non-empty (Advisor knows what it is running on and suggests a change)
- `rec_type` is `"Shutdown"` (Advisor recommends deleting/stopping the resource)
- `max_cpu_plan` is non-empty (Advisor measured plan-level CPU and suggests right-sizing)

All other rows are **optimisation hints** (configuration advice, feature enablement, etc.).

This classification is derived purely from the data — no resource type is hardcoded.

---

## Step 4b — Enrich App Service Plan rows

For every right-sizing row where `max_cpu_plan` is non-empty (i.e. Advisor supplied a plan-level CPU reading), fetch three additional data points **in parallel** per resource:

### 4b-i — ARM plan details

```bash
az appservice plan show \
  --name <resource> \
  --resource-group <resource_group> \
  --subscription <sub_id> \
  --output json 2>/dev/null
```

Extract:
```python
sku   = plan["sku"]
props = plan["properties"]
enrich = {
    "sku_display":    f"{sku['tier']} {sku['name']}",           # e.g. "PremiumV3 P2v3"
    "scale_mode":     "Automatic" if props.get("elasticScaleEnabled") else "Manual",
    "min_instances":  sku.get("capacity", 1),
    "max_burst":      props.get("maximumElasticWorkerCount", "-"),
}
```

### 4b-ii — 30-day CPU and memory averages

```bash
az monitor metrics list \
  --resource "/subscriptions/<sub_id>/resourceGroups/<rg>/providers/Microsoft.Web/serverfarms/<name>" \
  --metric CpuPercentage MemoryPercentage \
  --start-time <30 days ago>T00:00:00Z \
  --end-time <today>T00:00:00Z \
  --interval P1D \
  --aggregation Average \
  --output json 2>/dev/null
```

Compute `cpu_avg_30d` and `mem_avg_30d` as the mean of all daily average values. Format as `"X.X%"`. Use `"-"` if no data returned.

### 4b-iii — Cost per instance (from recent billing)

```bash
~/.dotnet/tools/azure-cost dailyCosts \
  -s <sub_id> \
  --dimension ResourceId \
  --from <7 days ago> --to <yesterday> \
  -t Custom -o json 2>/dev/null
```

Filter items where the `Name` field contains `serverfarms/<plan_name>` (case-insensitive). Sum cost across all 7 days, divide by 7 to get `avg_daily_cost`. Then:

```python
cost_per_instance_day = avg_daily_cost / enrich["min_instances"]
cost_per_instance_mo  = round(cost_per_instance_day * 30, 2)
cost_total_min_mo     = round(cost_per_instance_mo * enrich["min_instances"], 2)
```

Format as `"$N,NNN.NN/mo"`. If cost data is unavailable, use `"-"`.

Prefix `cost_per_instance_mo` with `~` when derived from billing (not from a published price sheet), since billing includes minor surcharges beyond the base instance price.

---

## Step 5 — Group by recommendation name

Within each classification bucket, group rows by `rec_name`.

**Usage optimisation rows** (`usage_opt_rows`):
1. Right-sizing groups first, then optimisation hint groups
2. Within each classification, sort by total `annual_savings` descending (groups with savings come first)

**Rate optimization rows** (`rate_optimization_rows`):
- Group by `rec_name`
- Within each group sort by `annual_savings` descending, then by `subscription` alphabetically

---

## Step 6 — Display

### Header

```
Azure Advisor — UsageOptimization Recommendations
Subscriptions : <list, or "all">
As of         : <today YYYY-MM-DD>
Total         : <N> recommendations  (<R> right-sizing · <O> optimisation hints · <P> rate optimization)
```

---

### Right-sizing candidates

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Right-sizing candidates  (<R> recommendations)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

For each group under this heading, print a sub-header with the recommendation name and impact:

```
[High]  Right-size or shutdown underutilized virtual machines  (2)
```

Then a table. Columns are determined by which fields are **actually populated** across the records in this group — only show a column when at least one record in the group has a non-empty value for it:

| Column | Field | When to show |
|---|---|---|
| Resource | `resource` | Always |
| Resource Group | `resource_group` | Always |
| Subscription | `subscription` | Always (or omit if `--subscription` filter is active) |
| Current | `current_sku` or `current_tier` | When any record has it |
| Action | derived (see below) | When any record has `current_sku`, `target_sku`, or `rec_type` |
| CPU P95 | `max_cpu_p95` | When any record has it |
| Mem P95 | `max_mem_p95` | When any record has it |
| Max CPU (plan) | `max_cpu_plan` | When any record has it |
| Savings | `annual_savings` | Always — render as `$N/yr` if > 0, otherwise `-` |

**Action column derivation:**
- `rec_type == "SkuChange"` → `→ <target_sku>`
- `rec_type == "Shutdown"` → `Shutdown`
- `target_sku` non-empty, `rec_type` empty → `→ <target_sku>`
- Nothing → `-`

Sort rows within a group by `annual_savings` descending, then by `resource` alphabetically.

Example output for a VM group:

```
[High]  Right-size or shutdown underutilized virtual machines  (2)

  Resource                   RG                   Subscription    Current SKU       Action               CPU P95   Mem P95   Savings
  ─────────────────────────  ───────────────────  ──────────────  ────────────────  ───────────────────  ───────   ───────   ──────────
  gl-runner-win-shell-vm     gitlab-dev-rg        Development     Standard_D4as_v4  → Standard_D2as_v4   18%       29%       $1,740/yr
  cpomsleg-vm-bastionhost    cpomsleg-rg-re1      Production-UK   Standard_B1s      Shutdown             3%        61%       $96/yr
```

Example output for an App Service group — uses the enriched columns from Step 4b:

```
[Medium]  Right-size underutilized App Service plans  (4)

  Plan                       RG                    Subscription    SKU              Scale mode    Min   Max   Cost/instance   Cost/total (min)   CPU avg   Mem avg
  ─────────────────────────  ────────────────────  ──────────────  ───────────────  ────────────  ────  ────  ──────────────  ─────────────────  ───────   ───────
  trigent-r8-plan-prod        emergencymanagement   Production      PremiumV3 P2v3   ✅ Automatic  6     30    ~$481.80/mo     $2,890.80/mo       0.2%      21.9%
  trigent-alert-plan-prod     emergencymanagement   Production      PremiumV3 P2v3   ✅ Automatic  10    30    ~$481.80/mo     $4,818/mo          0.5%      23.4%
  trigentuk-vmr6-plan-prod    visitormanagement     Production-UK   PremiumV3 P2v3   ✅ Automatic  1     30    ~$481.80/mo     ~$481.80/mo        0.3%      20.6%
  trigentuk-vmr6-plan-stag    visitormanagement     Staging-UK      PremiumV2 P2v2   ✅ Automatic  1     10    ~$180/mo        ~$180/mo           0.1%      34.5%
```

Column rules for App Service Plan groups:
- **Plan** — the server farm name (replaces the generic "Resource" label for this group)
- **SKU** — `sku_display` from 4b-i
- **Scale mode** — `✅ Automatic` or `Manual` from 4b-i
- **Min** — `min_instances` from 4b-i; bold when > 1
- **Max** — `max_burst` from 4b-i
- **Cost/instance** — from 4b-iii; prefix `~` (billing-derived)
- **Cost/total (min)** — `cost_per_instance_mo × min_instances`; bold when > $1,000/mo
- **CPU avg** — 30-day average from 4b-ii
- **Mem avg** — 30-day average from 4b-ii
- **Savings** column — omit for App Service groups (Advisor provides no estimate); note instead: `ℹ️ Advisor does not estimate savings for App Service plan right-sizing.`

If Advisor adds a new resource type in future (e.g. SQL elastic pool, Cosmos DB, managed disk), it will appear in its own recommendation group with whatever columns Advisor populates — no code change needed.

---

### Optimisation hints

Omitted when `--right-size-only` is passed.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Optimisation hints  (<O> recommendations)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

For each group, one compact block — no per-column table, just impact, name, count, and a resource list:

```
[Medium]  Enable Vertical Pod Autoscaler recommendation mode      5 resources
          prod-aks-akscluster-re1-001-ls · produk-aks-akscluster-re1-001 · produk-aks-akscluster-re2-001
          stage-aks-akscluster-re3-001-pe · stageuk-aks-akscluster-re1-001

[Medium]  Fine-tune cluster autoscaler for rapid scale-down       5 resources
          <same>

[Medium]  Consider Spot nodes for interruptible workloads         2 resources
          prod-aks-akscluster-re1-001-ls · produk-aks-akscluster-re1-001

[Medium]  Review unattached disks                                 2 resources
          pvc-5199a789-570f-447f-918e-516a5f5b844a (produk-rg-aks-nodes-re1, Production-UK)
          cpomsleg-dsk-build_02_re1-os (cpomsleg-rg-re1, Production-UK)

[Low]     Disable health probes (single-origin Front Door)        74 resources
          prod-trigent-rg1 ×22 · stage-trigent-rg1 ×23 · dev-trigent-rg1 ×28 · trigent-legacy-cdn-* ×1
```

For groups with > 5 distinct resources: list first 5 then `+N more`. For groups where many records share the same `resource` name, collapse to `<resource> ×N`.

---

### Rate Optimization

Omitted when `--right-size-only` is passed.

Display rows grouped into three **category sections**: Compute, Database, Other. Within each section, show the savings plan first (if present), then reservations grouped by `rec_name` sorted by total `annual_savings` descending.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rate Optimization  (<P> recommendations · 1-year term · 30-day lookback)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Category classification** (derived from `category` field set in Step 3b):
- `compute` — Compute_Savings_Plan; VM, App Service, Functions, Container Instances, Dedicated Host, Container Apps reservations
- `database` — Database_Savings_Plan; SQL (all tiers), MySQL, PostgreSQL, Cosmos DB, DocumentDB reservations
- `other` — Redis (no savings plan equivalent), Managed Disks, Data Explorer, Fabric, and anything else

**Section header** (omit section entirely if no rows in that category):
```
── Compute ─────────────────────────────── $NNN,NNN/yr  (N recs)
```

**Savings plan sub-group** — Qty column omitted (savings plans are hourly spend commitments, not unit quantities). Show what the plan covers as a parenthetical in the header:

```
[High]  Compute Savings Plan  (5 subscriptions · covers VMs, App Service, Functions, Container Instances, Dedicated Host, Container Apps, Spring Apps)

  Subscription            Savings/yr
  ──────────────────────  ──────────
  Production               $22,233/yr
  ...
  ─────────────────────────────────
  Subtotal                 $69,368/yr
```

**Reservation sub-groups** — adaptive columns; only show columns with at least one non-empty value:

| Column | Field | When to show |
|---|---|---|
| Subscription | `subscription` | Always (omit if `--subscription` filter active) |
| SKU | `sku` | When any record has it |
| Region | `region` | When non-empty across the group |
| Scope | `scope` | When any record has it |
| Qty | `quantity` | When any record has `quantity > 0` |
| Savings/yr | `annual_savings` | Always — `$N/yr` if > 0, else `-` |

Sort rows within a sub-group by `annual_savings` descending. Include a subtotal row at the end of each section.

Full example:

```
── Compute ────────────────────────────────────────────── $121,715/yr  (23 recs)

[High]  Compute Savings Plan  (5 subscriptions · covers VMs, App Service, Functions, Container Instances, Dedicated Host, Container Apps, Spring Apps)
  Subscription            Savings/yr
  ──────────────────────  ──────────
  Production               $22,233/yr
  Development              $18,686/yr
  Staging                  $17,200/yr
  Production-UK             $7,323/yr
  Staging-UK                $3,926/yr
  ──────────────────────────────────
  Subtotal                 $69,368/yr

[High]  App Service reserved instances  (6)
  Subscription    SKU                                              Region         Scope   Qty   Savings/yr
  ...

[High]  Virtual Machine reserved instances  (11)
  ...

[High]  Azure Managed Disk + Data Explorer reserved instances  (2)
  ...
  ─────────────────────────────────────────────────────────────────────────────
  Compute reservations subtotal                                    $52,347/yr

── Database ───────────────────────────────────────────── $127,041/yr  (20 recs)

[High]  Database Savings Plan  (5 subscriptions · covers SQL, MySQL, Cosmos DB, Redis)
  ...

[High]  SQL PaaS DB reserved instances  (5)
  ...
  ...
  ─────────────────────────────────────────────────────────────────────────────
  Database reservations subtotal                                   $71,950/yr

── Other ──────────────────────────────────────────────── $24,147/yr  (3 recs)

[High]  Microsoft Fabric reservations  (3)
  ...
```

If `rate_optimization_rows` is empty: print `No rate optimization recommendations found (30-day lookback · 1-year term).`

---

### Footer

**Rate optimization summary table** — always shown when `rate_optimization_rows` is non-empty. Savings Plan and Reservations are alternatives for the same workloads — do NOT sum them. Show each independently so the reader can choose which mechanism to act on. The "Other" category has no savings plan equivalent, so its SP cell is `—`.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Confirmed savings
  Right-sizing      : $<sum>/yr  (<M> of <R> recs have estimates)

  Rate Optimization  (1-year term · 30-day lookback · <P> recs)
  ⓘ Savings Plan and Reservations are alternatives — act on one per resource, not both.
  ┌──────────────────────────────────┬───────────────┬───────────────┐
  │ Category                         │ Savings Plan  │ Reservations  │
  ├──────────────────────────────────┼───────────────┼───────────────┤
  │ Compute                          │ $XX,XXX/yr    │ $XX,XXX/yr    │
  │ Database                         │ $XX,XXX/yr    │ $XX,XXX/yr    │
  │ Other (Redis + Fabric + Disk + ADX) │ —          │ $XX,XXX/yr    │
  └──────────────────────────────────┴───────────────┴───────────────┘

Right-sizing       : <R> recommendations across <X> resources
Optimisation hints : <O> recommendations  (suppress with --right-size-only)
Rate optimization  : <P> recommendations  (suppress with --right-size-only)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Populate the table cells:
- **Savings Plan** column: sum of `annual_savings` for all `subcategory == "SavingsPlan"` rows in that category. If none → `—`.
- **Reservations** column: sum of `annual_savings` for all `subcategory == "Reservations"` rows in that category. If none → `—`.
- No Total column. No Grand total row. These are alternatives, not an additive budget.

---

---

## Step 7 — Save to KB

**Skip this step** when `--subscription <name>` was provided (partial run — the global `advisor_covered` cursor must not advance).

After display (or immediately when `--save-only` is set), commit the advisor data to the GitLab cost-anomalies KB.

### 7a — Generate CSV content per subscription

**`advisor_usage_optimization.csv`** — one file per subscription; always a full overwrite (no append):

```
date,resource_group,resource,resource_type,category,impact,recommendation,current_sku,target_sku,target_min_instances,cpu_p95,annual_savings_usd,scale_mode,min_instances,max_burst,cost_per_instance,cost_total_min,cpu_avg,mem_avg
```

| Column | Source | Notes |
|---|---|---|
| `date` | today (YYYY-MM-DD) | Same for all rows in this run |
| `resource_group` | `resource_group` field | Empty string if `?` |
| `resource` | `resource` field | |
| `resource_type` | `resource_type` field | Lowercase |
| `category` | derived | `right-size` (SkuChange), `shutdown` (rec_type=Shutdown), `optimization-hint` |
| `impact` | `impact` | High / Medium / Low |
| `recommendation` | `rec_name` | Max 120 chars; commas → semicolons |
| `current_sku` | VMs: `ep.currentSku`; App Service plans: from `az appservice plan show` → `"{tier} {name}"` (e.g. `PremiumV3 P2v3`) | Empty if unavailable |
| `target_sku` | VMs: `ep.targetSku`; App Service (min=1): lower tier e.g. `PremiumV3 P1v3`; App Service (min>1, Automatic): empty (action is min reduction) | Empty if no SKU change recommended |
| `target_min_instances` | App Service (min>1, Automatic): proposed minimum = `ceil(min × max(cpu_avg,mem_avg) / 60)` | Empty for non-ASP rows or when SKU downgrade is the recommendation |
| `cpu_p95` | VMs: `ep.MaxCpuP95` (append `%`); App Service plans: `ep.maxCpuServicePlan` as `"N%"` | Empty if unavailable |
| `annual_savings_usd` | VMs: from Advisor; App Service (min reduction): `(current_min − target_min) × cost_per_instance × 12`; App Service (SKU downgrade): `cost_per_instance × 0.5 × 12` (P1 ≈ 50% of P2) | Empty when not calculable |
| `scale_mode` | App Service only: `Automatic` or `Manual` from `az appservice plan show` | Empty for non-ASP rows |
| `min_instances` | App Service only: `sku.capacity` from ARM | Empty for non-ASP rows |
| `max_burst` | App Service only: `maximumElasticWorkerCount` from ARM | Empty for non-ASP rows |
| `cost_per_instance` | App Service only: 7-day avg daily cost ÷ min_instances × 30, prefixed `~$` | Empty for non-ASP rows |
| `cost_total_min` | App Service only: `cost_per_instance × min_instances`, prefixed `~$` | Empty for non-ASP rows |
| `cpu_avg` | App Service only: 30-day `CpuPercentage` average from `az monitor metrics list` | Empty for non-ASP rows |
| `mem_avg` | App Service only: 30-day `MemoryPercentage` average from `az monitor metrics list` | Empty for non-ASP rows |

**App Service recommendation logic:**
- **`min_instances > 1` AND `scale_mode = Automatic`**: Elastic scaling covers demand spikes; the fix is reducing the always-on minimum. Proposed min = `ceil(current_min × max(cpu_avg%, mem_avg%) / 60)` (target ≤ 60% utilisation). `target_sku` is left empty.
- **`min_instances = 1`**: Only path to savings is a SKU downgrade. `target_sku = P{N-1}vX`. Savings ≈ 50% of `cost_per_instance` (each tier halves in size and price).

**App Service enrichment** (Step 4b) runs for every `right-size` row where `ep.maxCpuServicePlan` is non-empty. It calls `az appservice plan show`, `az monitor metrics list`, and `azure-cost dailyCosts` to populate the enrichment columns. These calls happen during save regardless of whether `--save-only` is passed.

**Deduplication for optimization hints:** Azure Advisor emits one recommendation per sub-resource (e.g. one entry per Front Door origin group, one per disk). For `category = optimization-hint` rows, deduplicate by `(resource_group, resource, recommendation)` — keep only the first occurrence. Right-sizing and shutdown rows are never deduplicated (each is a distinct resource action).

**`advisor_rate_optimization.csv`** — one file per subscription; always a full overwrite:

```
date,category,impact,recommendation,sku,region,scope,quantity,annual_savings_usd
```

| Column | Source | Notes |
|---|---|---|
| `date` | today (YYYY-MM-DD) | |
| `category` | derived | `compute-sp` (SavingsPlan+compute), `database-sp` (SavingsPlan+database), `reservation` |
| `impact` | `impact` | |
| `recommendation` | `rec_name` | Max 120 chars; commas → semicolons |
| `sku` | `sku` | Empty for savings plans |
| `region` | `region` | Empty for savings plans or when subscription-wide |
| `scope` | `scope` | Shared / Single; empty for savings plans |
| `quantity` | `quantity` | Float if > 0, else empty |
| `annual_savings_usd` | `annual_savings` | |

### 7b — Check existence and commit

For each subscription in scope, check whether each file already exists:

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "Azure/<Sub>/advisor_usage_optimization.csv")?ref=main" 2>/dev/null \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('EXISTS' if 'content' in d else 'NOT_FOUND')" 2>/dev/null \
  || echo "NOT_FOUND"
```

Use `"action": "update"` if the file exists, `"action": "create"` if not. Group all subscription file actions into a **single commit**:

```
cost: update advisor recommendations <N> subscriptions (as of <today>)
```

### 7c — Update `_index.json`

Fetch the current `_index.json`, set `advisor_covered.until = today` (YYYY-MM-DD), and include it as an action in the same commit.

Top-level key order: `email_covered`, `jira_covered`, `advisor_covered`, `budget_covered`, `generated`, `files`. The `advisor_covered` object has only one field: `until`.

### 7d — Output

```
💾 Saved to KB

  Usage optimization : <N> rows across <M> subscriptions
  Rate optimization  : <P> rows across <M> subscriptions
  advisor_covered.until: <today>

  GitLab: https://gitlab.com/trigent1/devsecops/cost-anomalies/-/tree/main/Azure
```

---

## Error handling

| Situation | Action |
|---|---|
| No UsageOptimization recs for a subscription | Skip silently |
| All subscriptions return zero recs | `No UsageOptimization recommendations found.` |
| `az advisor` fails for a subscription | Print `⚠️ <sub>: query failed — skipped` and continue |
| `annualSavingsAmount` missing or zero | Render savings as `-`, not `$0/yr` |
| KB commit fails | Print error; display output was already shown — user can retry with `--save-only` |
