---
name: cost-budget
description: "Generate per-resource-group budgets by analysing 3 months of actual Azure spend and storing _budget.json in each RG folder of the cost-anomalies KB. Also shows current burn rates vs stored budgets. Prompts for az login if Azure CLI session is expired. (Triggers: cost budget, budget analysis, rg budget, resource group budget, generate budgets, budget status, spending budget, how much budget)"
allowed-tools: [Bash, AskUserQuestion]
argument-hint: "generate [<subscription>] | status [<subscription>] | set <rg> in <subscription> <amount>"
---

# Cost Budget Generator

Analyse 3 months of actual Azure spend per resource group and store budgets in the cost-anomalies KB alongside the anomaly data.

## Repository

- **Cost KB**: `trigent1/devsecops/cost-anomalies`
- **Project ID** (URL-encoded): `trigent1%2Fdevsecops%2Fcost-anomalies`
- **Budget file per RG**: `Azure/<Subscription>/<rg-name>/_budget.json`
- **Subscription config**: `/Users/viacheslav.frolov/Desktop/GitLab/azure-cost/config/subscriptions.json`

## Help

If `$ARGUMENTS` contains "help", print:

```
/cost-anomalies:cost-budget generate [<subscription>] [--fill-gaps]
/cost-anomalies:cost-budget status [<subscription>]
/cost-anomalies:cost-budget set <rg> in <subscription> <amount>

Commands:
  generate          Fetch 6 months of spend, calculate per-RG budgets,
                    write _budget.json to each RG folder in the KB.
  generate --fill-gaps   Only process RG folders that are missing _budget.json.
                    Skips RGs that already have a budget (no recalculation).
                    Use after extraction runs to catch any RGs the auto-budget
                    step missed (e.g. azure-cost was unavailable at the time).
  status            Show current month burn rate for all RGs with defined budgets.
  set               Manually override a budget for a specific RG.

Options:
  <subscription>    Filter to one subscription (default: all)

Examples:
  /cost-anomalies:cost-budget generate
  /cost-anomalies:cost-budget generate Production
  /cost-anomalies:cost-budget generate --fill-gaps
  /cost-anomalies:cost-budget generate Production --fill-gaps
  /cost-anomalies:cost-budget status
  /cost-anomalies:cost-budget status Staging
  /cost-anomalies:cost-budget set legacy-r6 in Production 9000
```

---

## Step 1 — Parse arguments

From `$ARGUMENTS`:
- First word = command: `generate`, `status`, or `set`
- Optional subscription name filter
- For `set`: `<rg-name> in <subscription> <amount>`

Default command when no argument given: `status`.

---

## Step 1b — Check Azure CLI auth

Before making any Azure API calls, verify the session is active:

```bash
az account get-access-token --output none 2>/dev/null && echo AUTH_OK || echo AUTH_EXPIRED
```

If **AUTH_EXPIRED**:

```
AskUserQuestion:
  "⚠️ Azure CLI session expired
   Budget generation and status require access to Azure Cost Management.

   Run in your terminal:
     ! az login --tenant e7c09548-124d-4328-bb11-60cb1d314be1

   Then select 'I've logged in' to continue."

  Options:
    "I've logged in — continue"
    "Cancel"
```

- **I've logged in**: Re-run the check. If still expired → tell user to run `! az login` in the terminal and try again. If OK → proceed.
- **Cancel**: Stop.

If **AUTH_OK** → continue silently to the next step.

---

## GENERATE command

### --fill-gaps mode

If `--fill-gaps` is present in `$ARGUMENTS`:

1. Get the KB tree and collect all RG folders that have CSV data but **no `_budget.json`**:
```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/tree?ref=main&recursive=true&per_page=500" \
  2>/dev/null | python3 -c "
import json, sys, collections
items = json.load(sys.stdin)
rg_folders = set()
budget_rgs  = set()
for x in items:
    parts = x['path'].split('/')
    if len(parts) >= 3:
        key = f\"{parts[1]}/{parts[2]}\"
        if x['type'] == 'blob':
            if x['name'] == '_budget.json': budget_rgs.add(key)
            elif x['name'].endswith('.csv'): rg_folders.add(key)
for k in sorted(rg_folders - budget_rgs):
    print(k)
"
```

2. Group missing RGs by subscription. For each subscription that has missing RGs, run one `azure-cost dailyCosts` call (Step 3 below) — reuse the same call for all missing RGs in that subscription.

3. Only write `_budget.json` for RGs that are missing one. Skip RGs that already have a budget entirely — no recalculation, no update.

4. Apply the same eligibility criteria (≥ 3 complete months, median ≥ $50/month).

Output:
```
🔍 Fill-gaps mode: found 35 RG folders without _budget.json
   Eligible (≥$50/mo, ≥3 months): <N>
   Skipped (below threshold)     : <M>
   Budgets written               : <N>
```

---

### Step 2 — Load subscription IDs

Read `/Users/viacheslav.frolov/Desktop/GitLab/azure-cost/config/subscriptions.json`:

```bash
python3 -c "
import json
with open('/Users/viacheslav.frolov/Desktop/GitLab/azure-cost/config/subscriptions.json') as f:
    d = json.load(f)
for s in d['subscriptions']:
    print(s['name'], s['subscriptionId'])
"
```

Filter to the specified subscription if provided. Skip `Trigent Technologies(Converted to EA)` and `Trigent Internal Tools` unless explicitly requested (low spend, limited RG data).

### Step 3 — Fetch 3 months of monthly costs per RG

Run **one** `az costmanagement query` call per subscription with monthly granularity grouped by ResourceGroupName. This returns 3 monthly totals per RG directly — no daily data, no aggregation needed.

```bash
FROM_DATE=$(date -v-180d +%Y-%m-01 2>/dev/null || date -d "$(date +%Y-%m-01) -180 days" +%Y-%m-01)
TO_DATE=$(date +%Y-%m-%d)

az costmanagement query \
  --type Usage \
  --scope "/subscriptions/<subscription_id>" \
  --timeframe Custom \
  --time-period from="${FROM_DATE}T00:00:00Z" to="${TO_DATE}T23:59:59Z" \
  --dataset-granularity Monthly \
  --dataset-aggregation '{"totalCost":{"name":"PreTaxCost","function":"Sum"}}' \
  --dataset-grouping '[{"type":"Dimension","name":"ResourceGroupName"}]' \
  --output json 2>/dev/null
```

### Step 4 — Parse monthly totals per RG

The response contains columns and rows — parse directly into `{rg: {month: cost}}`:

```python
import json, sys, collections, statistics
from datetime import datetime

data = json.loads(sys.stdin.read())

# Find column positions
cols = data.get('columns', [])
cost_idx = next(i for i, c in enumerate(cols) if c['name'] == 'PreTaxCost')
date_idx = next(i for i, c in enumerate(cols) if c['name'] == 'BillingMonth' or 'Date' in c['name'])
rg_idx   = next(i for i, c in enumerate(cols) if c['name'] == 'ResourceGroupName')

rg_data = collections.defaultdict(dict)
for row in data.get('rows', []):
    rg    = str(row[rg_idx]).lower()
    month = str(row[date_idx])[:7]   # YYYY-MM
    cost  = float(row[cost_idx])
    rg_data[rg][month] = round(cost, 2)
```

### Step 5 — Calculate budget per RG

For each RG with at least 2 months of data:

```python
for rg, monthly_totals in rg_data.items():
    months = sorted(monthly_totals.keys())

    # Use only complete months (exclude current partial month)
    current_month = datetime.now().strftime('%Y-%m')
    complete_months = {m: v for m, v in monthly_totals.items() if m != current_month}

    if len(complete_months) < 3:
        continue  # require at least 3 complete months for a reliable median

    values = list(complete_months.values())

    # Median avoids spike months inflating the budget
    basis = statistics.median(values)
    budget = round(basis * 1.2, 0)   # 20% headroom

    # Variance flag — high if any month > 2x median
    variance = 'high' if max(values) > basis * 2 else 'normal'

    budget_data = {
        'monthly_budget_usd': budget,
        'basis_usd': round(basis, 2),
        'buffer_pct': 20,
        'months': complete_months,
        'median_usd': round(basis, 2),
        'variance': variance,
        'generated': datetime.now().strftime('%Y-%m-%d'),
        'notes': ''
    }
```

Skip RGs with total spend under **$50/month** median — not worth tracking.

### Step 6 — Write _budget.json to KB

For each RG with a calculated budget, find the matching KB path:

```
Azure/<Subscription-name>/<rg-name>/_budget.json
```

Map subscription ID back to name using `subscriptions.json`. Check the KB tree to confirm the RG folder exists before writing (only write budgets for RGs that already have anomaly data in the KB).

Check if `_budget.json` already exists:
```bash
# GitLab returns valid JSON even on 404 — must check for 'content' key, not just parse success
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "Azure/<Sub>/<rg>/_budget.json")?ref=main" 2>/dev/null \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('EXISTS' if 'content' in d else 'NOT_FOUND')" 2>/dev/null \
  || echo "NOT_FOUND"
```

- **Exists** (`EXISTS`): update if ANY of these is true:
  - `monthly_budget_usd` changed by > 10% (budget meaningfully different)
  - `len(new_months) > len(existing_months)` (months history grew — always enrich)
  - `variance` changed (risk profile changed)
  Otherwise skip (avoids noisy commits for unchanged data).
- **Does not exist**: create.

### Step 7 — Commit to KB

Group all new/updated budget files into a single commit. Also update `_index.json` with the latest complete month budgets were generated through.

**Compute `latest_complete_month`** — the last full calendar month (excludes the current partial month):

```python
from datetime import datetime
today = datetime.utcnow()
if today.month == 1:
    latest_complete = f"{today.year - 1}-12"
else:
    latest_complete = f"{today.year}-{today.month - 1:02d}"
# e.g. on 2026-06-22 → "2026-05"
```

**Fetch current `_index.json`** to merge into (reuse if already in memory from `--fill-gaps` tree scan):

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/_index.json?ref=main" 2>/dev/null \
  | python3 -c "
import sys,json,base64
d=json.load(sys.stdin)
print(base64.b64decode(d['content']).decode() if 'content' in d else '{\"files\":{}}')
" 2>/dev/null || echo '{"files":{}}'
```

Set `idx["budget_covered"] = {"until": latest_complete}` and include as an action in the commit:

```bash
cat << 'PAYLOAD' | glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/commits" \
  -X POST -H "Content-Type: application/json" --input -
{
  "branch": "main",
  "commit_message": "budget: generate RG budgets from 3-month spend analysis (<N> RGs across <M> subscriptions)",
  "actions": [
    {"action": "create|update", "file_path": "Azure/<Sub>/<rg>/_budget.json", "content": "<json>"},
    ...,
    {"action": "update", "file_path": "_index.json", "content": "<merged idx with budget_covered>"}
  ]
}
PAYLOAD
```

Serialize `_index.json` with 2-space indent. Top-level key order: `email_covered`, `jira_covered`, `budget_covered`, `generated`, `files`. The `budget_covered` object has only one field: `until` (YYYY-MM).

Output on success:

```
✅ Budgets generated

Subscriptions scanned : <N>
RGs analysed          : <T> (total with data)
Budgets written       : <W> new / <U> updated / <S> skipped (unchanged)
RGs below threshold   : <X> (< $50/month, skipped)
High-variance RGs     : <H> (max month > 2× median — worth investigating)

High-variance RGs:
  Azure/Production/legacy-r6          median $9,200/mo  max $42,897 (May 2026)
  Azure/Staging/rg-rl-staging-eastus2-1fz0  median $640/mo  max $1,850 (May 2026)
  ...

GitLab: https://gitlab.com/trigent1/devsecops/cost-anomalies
```

---

## STATUS command

### Step 2s — Read all _budget.json files from KB

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/tree?ref=main&recursive=true&per_page=200" \
  2>/dev/null | python3 -c "
import json, sys
items = json.load(sys.stdin)
for x in items:
    if x.get('name') == '_budget.json':
        print(x['path'])
"
```

Read each `_budget.json` file found. Filter by subscription if `--subscription` was provided.

### Step 3s — Get current month spend per RG

Run one `az costmanagement query` call per subscription for the current month-to-date with monthly granularity:

```bash
MONTH_START=$(date +%Y-%m-01)
TODAY=$(date +%Y-%m-%d)

az costmanagement query \
  --type Usage \
  --scope "/subscriptions/<subscription_id>" \
  --timeframe Custom \
  --time-period from="${MONTH_START}T00:00:00Z" to="${TODAY}T23:59:59Z" \
  --dataset-granularity Monthly \
  --dataset-aggregation '{"totalCost":{"name":"PreTaxCost","function":"Sum"}}' \
  --dataset-grouping '[{"type":"Dimension","name":"ResourceGroupName"}]' \
  --output json 2>/dev/null
```

Parse using the same column-index logic as Step 4 to get `{rg: current_month_spend}`.

### Step 4s — Calculate burn rates and display

```python
days_elapsed = int(TODAY.split('-')[2])
days_in_month = 30  # approximate

for rg_path, budget_data in budgets.items():
    budget = budget_data['monthly_budget_usd']
    actual = rg_actual_spend.get(rg, 0)

    expected = budget * (days_elapsed / days_in_month)
    burn_rate = actual / expected if expected > 0 else 0
    projected = (actual / days_elapsed * days_in_month) if days_elapsed > 0 else 0
    over_under = projected - budget

    status = (
        '✅ On track'  if burn_rate < 1.0 else
        '🟡 Elevated'  if burn_rate < 1.5 else
        '⚠️  WARN'     if burn_rate < 2.0 else
        '🔴 ALERT'
    )
```

Output:

```
📊 Budget Status — June 2026  (day 17/30 = 57% elapsed)

RG                                  Sub           Budget     Spent    Burn   Projected   Status
──────────────────────────────────  ────────────  ───────    ─────    ─────  ─────────   ──────
legacy-r6                           Production    $10,800    $9,200   1.49×  $16,200     ⚠️  WARN  (+$5,400)
emergencymanagement                 Production     $6,200    $3,100   0.88×   $5,500     ✅ On track
rg-rl-staging-eastus2-1fz0          Staging          $770      $520   1.25×     $920     🟡 Elevated
cpomsuk-prod-rg                     Prod - UK     $26,400   $18,200   1.28×  $32,100     ⚠️  WARN  (+$5,700)
...

Subscriptions without budgets: Trigent Internal Tools (run 'cost-budget generate' first)
```

---

## SET command

Manually override or create a budget for a specific RG:

```bash
# Read existing _budget.json if present, update monthly_budget_usd
# Write back with notes = "manually set"
```

Output:
```
✅ Budget set: Azure/<Sub>/<rg>/_budget.json → $<amount>/month (manually set)
```

---

## Integration with cost-investigate

When `cost-investigate` runs on a resource, it checks for `_budget.json` in the parent RG folder and adds budget context to the diagnosis:

```
💰 Budget context: <rg-name> (<subscription>)
   Monthly budget  : $<budget> (median $<basis> × 1.2)
   This anomaly    : $<change_usd> = <pct>% of monthly budget
   Variance        : <high|normal>
   → <high: escalate | normal: monitor>
```

A spike representing > 50% of monthly budget → flag as high priority in the diagnosis.

---

## Error handling

| Situation | Action |
|---|---|
| RG has < 2 complete months of data | Skip — not enough history |
| RG spend < $50/month median | Skip — below threshold |
| _budget.json exists, change < 10% | Skip update — no meaningful change |
| Subscription not in config | Warn and skip |
