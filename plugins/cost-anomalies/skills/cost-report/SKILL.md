---
name: cost-report
description: "Aggregate digest report generator — never writes to KB or Jira. Two modes: (1) monthly digest — all anomalies for a month with top findings, action items, and savings estimates; (2) weekly digest — same structure for a week range, suited for the weekly cost meeting. Auto-prompts to publish to Confluence if no page exists yet; --publish forces overwrite. For single-resource deep investigation, use cost-investigate instead. (Triggers: cost report, monthly cost report, weekly cost report, cost summary, generate report, cost digest, cost findings, weekly meeting report)"
allowed-tools: [Bash, AskUserQuestion, mcp__claude_ai_Atlassian__createConfluencePage, mcp__claude_ai_Atlassian__updateConfluencePage, mcp__claude_ai_Atlassian__getConfluenceSpaces, mcp__claude_ai_Atlassian__getPagesInConfluenceSpace, mcp__gitlab__get_repository_tree, mcp__gitlab__get_file_contents]
argument-hint: "<month|'last week'|YYYY-MM-DD to YYYY-MM-DD> [--subscription <name>] [--publish]"
---

# Azure Cost Report Generator

Two modes: **monthly digest** for a time period, or **deep investigation** for a specific resource/RG.

## Repository

- **Cost KB**: `trigent1/devsecops/cost-anomalies`
- **Confluence space**: `PTD` (Product Team – DevSecOps)
- **Confluence parent**: FinOps section (search for "DevSecOps Project - FinOps" or ID `1927315478`)

## Help

If `$ARGUMENTS` contains "help", print:

```
/cost-anomalies:cost-report <month> [--subscription <name>] [--publish]
/cost-anomalies:cost-report <week> [--subscription <name>] [--publish]

For single-resource deep investigation, use: /cost-anomalies:cost-investigate

MODE 1 — Monthly digest
  Summarises all anomalies for a month: top findings; investigated vs pending;
  action items with savings estimates; recurring patterns; new resources.
  After generating, prompts to publish to Confluence if no page exists yet.
  --publish forces overwrite even if the page already exists.

  Arguments:
    <month>                   e.g. "June", "May 2026", "2026-06"
    --subscription <name>     Filter to one subscription (default: all)
    --publish                 Overwrite existing Confluence page (default: prompt if new)

  Examples:
    /cost-anomalies:cost-report June
    /cost-anomalies:cost-report May 2026 --subscription Production
    /cost-anomalies:cost-report June --publish

MODE 1W — Weekly digest
  Same structure as monthly but scoped to a week. Designed for the weekly cost
  meeting. Skips the Jira subscription summary (no weekly Unit ticket).
  After generating, prompts to publish to Confluence if no page exists yet.
  --publish forces overwrite even if the page already exists.

  Arguments:
    <week>                    "last week", "this week", or "YYYY-MM-DD to YYYY-MM-DD"
    --subscription <name>     Filter to one subscription (default: all)
    --publish                 Overwrite existing Confluence page (default: prompt if new)

  Examples:
    /cost-anomalies:cost-report last week
    /cost-anomalies:cost-report last week --publish
    /cost-anomalies:cost-report 2026-06-15 to 2026-06-21 --publish

```

---

## Step 1 — Detect mode

From `$ARGUMENTS`:

- If argument contains ` in ` → redirect: "For single-resource investigation use `/cost-anomalies:cost-investigate <resource> in <subscription>`."
- If argument matches a week reference (`last week`, `this week`, `YYYY-MM-DD to YYYY-MM-DD`) → **Mode 1W** (weekly digest).
  - `last week` → Monday–Sunday of the previous week (e.g. today 2026-06-22 → 2026-06-15 to 2026-06-21).
  - `this week` → Monday to today.
  - `YYYY-MM-DD to YYYY-MM-DD` → use dates literally.
- If argument looks like a month/date (`June`, `May 2026`, `2026-06`) → **Mode 1** (monthly digest).
- `--publish` flag (digest modes only) → overwrite Confluence page even if it already exists.
- `--subscription <name>` → filter to one subscription (digest modes only).

---

## MODE 1 — Monthly Digest

### Step 2a — Scan the Cost KB

**Step 1 — Try the freshness index first:**

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/_index.json?ref=main" 2>/dev/null \
  | python3 -c "
import sys,json,base64
d=json.load(sys.stdin)
print(base64.b64decode(d['content']).decode() if 'content' in d else '')
" 2>/dev/null
```

Determine the **target period start date** from the argument:
- `June` / `May 2026` / `2026-06` → `YYYY-MM-01` (first of that month)
- `last week` or a date range → first date of the range (e.g. `2026-06-15`)

**If the index exists:**
- Keep only files where `last_date >= target_period_start`. Files with an earlier `last_date` cannot contain any rows for the target period — skip them entirely.
- Build a **staleness map** keyed by subscription: for each subscription directory, record whether any of its files have `last_date >= target_period_start`. Subscriptions with no recent files are stale — note them for the Data Coverage section.
- Fetch only the pre-filtered CSV files (typically a small fraction of all 181).

**If the index does not exist** (not yet generated — fallback to full scan):
- Iterate per subscription directory to avoid the 200-item API limit:

```bash
for sub in "Development - UK" "Development" "Management" "POC" "Production - UK" "Production" \
           "Trigent Internal Tools" "Trigent Technologies(Converted to EA)" "Trigent Technologies" \
           "Staging - UK" "Staging"; do
  encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote('Azure/'+sys.argv[1], safe=''))" "$sub")
  glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/tree?ref=main&path=${encoded}&recursive=true&per_page=200" \
    2>/dev/null | python3 -c "import json,sys; [print(x['path']) for x in json.load(sys.stdin) if x['type']=='blob' and x['path'].endswith('.csv')]"
done
```

**Step 2 — Parse each fetched CSV**, collecting rows where `date` falls within the target period. Handle both schemas:
- **Email schema** (`subscription_anomaly_type` header): `date, observed_at, period_type, sub_type, sub_delta_pct, baseline_usd, comparison_usd, change_usd, delta_pct, pct_of_total, notes` (USD columns are empty until `cost-investigate` has run for that row)
- **Jira schema** (`source_key` header): `date, observed_at, source_key, period_type, resource_type, baseline_usd, comparison_usd, change_usd, delta_pct, notes`

Extract from each row's `notes` field:
- **Action items**: lines containing `confirm with`, `saves ~$`, `escalate`, `review trigger`, `urgent`, `action needed`, `action required`
- **Owner**: email addresses (`@trigent.com`, `@cpoms.co.uk`) or names in parentheses at end of notes
- **Estimated savings**: `~$NNN` or `~$N,NNN` pattern

### Step 2b — Fetch Jira monthly Unit ticket (subscription summary)

Find the `Azure Cost Analysis - <Month> <Year>` Unit ticket in DEVSECOPS for the subscription-level cost table:

```
mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql(
  cloudId: "trigent1.atlassian.net",
  jql: 'summary ~ "Azure Cost Analysis - <Month> <Year>" AND issuetype = "Unit" AND project = DEVSECOPS',
  fields: ["summary", "description"],
  maxResults: 1
)
```

Extract the Subscription Cost Summary table from the description (Baseline / Comparison / Change % per subscription).

If no Unit ticket found → skip subscription summary section.

### Step 2c — Fetch advisor data from KB

For each subscription in scope (all, or the filtered one), fetch:

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "Azure/<Sub>/advisor_usage_optimization.csv")?ref=main" 2>/dev/null \
  | python3 -c "
import sys, json, base64, csv, io
d = json.load(sys.stdin)
if 'content' not in d: print('NOT_FOUND'); exit()
rows = list(csv.DictReader(io.StringIO(base64.b64decode(d['content']).decode())))
print(json.dumps(rows))
" 2>/dev/null
```

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "Azure/<Sub>/advisor_rate_optimization.csv")?ref=main" 2>/dev/null \
  | python3 -c "
import sys, json, base64, csv, io
d = json.load(sys.stdin)
if 'content' not in d: print('NOT_FOUND'); exit()
rows = list(csv.DictReader(io.StringIO(base64.b64decode(d['content']).decode())))
print(json.dumps(rows))
" 2>/dev/null
```

Read `advisor_covered.until` from `_index.json` (already fetched in Step 2a). If the key is absent, advisor data has never been generated.

Collect into `advisor_usage_rows` and `advisor_rate_rows` keyed by subscription.

### Step 3a — Build monthly digest report

```markdown
# Azure Cost Anomaly Report — <Month> <Year>

**Generated:** <date>  **KB entries:** <N> rows  **Subscriptions:** <list>

---

## Subscription Summary
<from Jira Unit ticket description — baseline/comparison/change% table>

---

## Data Coverage

Show per-subscription freshness from the index (or from the max date seen across fetched CSVs if the index was absent). Mark subscriptions where the most recent data predates the target period.

| Subscription | Latest data | Status |
|---|---|---|
| Production | 2026-06-11 | ⚠️ stale — run cost-extract |
| Staging | 2026-06-12 | ⚠️ stale — run cost-extract |
| Trigent Internal Tools | 2026-06-16 | ✅ current |
...

Status rules:
- **✅ current** — has data within the target period
- **⚠️ stale** — latest data predates the target period start; anomalies may be missing
- **❌ no data** — no CSV files found for this subscription

If all subscriptions are current, omit this section entirely.

---

## Top Anomalies This Month

For each anomaly row, check `Azure/<Sub>/<RG>/_budget.json` to get the RG's monthly budget and compute the anomaly's share. This turns a raw dollar figure into a priority signal — a $500 spike on a $600/month RG is more critical than a $5,000 spike on a $50,000/month RG.

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/<encoded>?ref=main" \
  2>/dev/null | python3 -c "import sys,json,base64; b=json.loads(base64.b64decode(json.load(sys.stdin)['content'])); print(b['monthly_budget_usd'])"
```

| Resource | RG | Subscription | Type | Change | % of RG Budget | Notes |
|---|---|---|---|---|---|---|
| trigent-legacy-cdn-prod | legacy-r6 | Production | monthly | +$35,695 (+496%) | 71% 🔴 | HWS release May 2026 → CDN egress spike ... |
| trigent-r8-plan-prod | emergencymanagement | Production | weekly | +$2,487 | 44% ⚠️ | Manually scaled 1→6 instances Apr 28 ... |
...
(top 10 by absolute change_usd, sorted descending)

Budget column rules:
- **🔴** ≥ 50% of monthly budget
- **⚠️** 20–50%
- **🟡** 5–20%
- **✅** < 5%
- **(no budget)** if `_budget.json` missing for that RG

---

## Investigations Completed (<N> resources)

Resources with substantive notes (non-empty, not just "New resource"):
| Resource | Date | Notes |
...

---

## Action Items Outstanding

Resources where notes contain action keywords — pending owner confirmation:

| Resource | Subscription | Est. savings/month | Action | Owner |
|---|---|---|---|---|
| trigentlink SQL 400 DTU | Development | ~$200 | Confirm downgrade with dbash | dbash@trigent.com |
| compy-pool-1 | Development | ~$197 | Confirm with payments team | — |
| adf-rl-staging / LogToNewRelic | Staging | ~$200 | Review trigger frequency | — |
...

**Total estimated savings if all actioned: ~$XXX/month**

---

## Recurring Anomalies

Resources that appeared in both this month and the prior month:
| Resource | This month | Prior month | Pattern |
...

---

## New Resources

Resources with `baseline_usd = 0` or notes = "New resource" — first-time billing:
| Resource | RG | Subscription | Monthly cost | Notes |
...

---

## Uninvestigated

Rows with empty notes (no explanation yet):
<N> rows across <M> resources — run `/cost-anomalies:cost-investigate <period>` to investigate

---

## Optimization Opportunities

_(Azure Advisor — as of <advisor_covered.until> · <N days old> · refresh: `/cost-anomalies:cost-advisor`)_

If `advisor_covered` is absent from `_index.json`:
```
_Advisor data not yet generated — run `/cost-anomalies:cost-advisor` to populate._
```

If `advisor_covered.until` is more than 30 days before report period end → prefix section with:
```
⚠️ Advisor data is N days old — consider refreshing with `/cost-anomalies:cost-advisor`.
```

**Usage optimization: <R> right-sizing · <O> hints across <M> subscriptions**

Show right-sizing candidates only (omit optimization-hint rows — too noisy for the report). Top 10 by `annual_savings_usd` descending; include rows with empty savings at the end, sorted by impact (High → Medium → Low):

| Resource | RG | Subscription | Impact | Action | CPU P95 | Mem P95 | Savings/yr |
|---|---|---|---|---|---|---|---|
| trigent-r8-plan-prod | emergencymanagement | Production | High | right-size PremiumV3 P2v3 | 0.2% | 21.9% | — |
| gl-runner-win-shell-vm | gitlab-dev-rg | Development | High | right-size → Standard_D2as_v4 | 18% | 29% | $1,740 |
| cpomsleg-vm-bastionhost | cpomsleg-rg-re1 | Production-UK | High | ⛔ Shutdown | 3% | 61% | $96 |

Omit Subscription column when `--subscription` filter is active.
Omit the table entirely if no right-sizing candidates exist; keep the section header with: `_No right-sizing candidates found._`

Also show the count of optimization hints (but not the full list): `_+ <O> optimization hints (VPA; autoscaler; Spot nodes; etc.) — run `/cost-anomalies:cost-advisor` for the full list._`

**Rate optimization (1-year term · 30-day lookback):**

Aggregate `annual_savings_usd` from rate rows by category and subcategory type. Present as a summary table:

| Category | Savings Plan/yr | Reservations/yr |
|---|---|---|
| Compute | $69,368 | $52,347 |
| Database | $55,091 | $71,950 |
| Other | — | $24,147 |

_(Savings Plan and Reservations cover the same workloads — act on one per resource, not both)_

Then list the **top savings candidates** — individual rows sorted by `annual_savings_usd` descending, top 10. Savings Plan rows appear once per subscription; reservation rows appear once per SKU/region/subscription combination:

| Subscription | Type | Recommendation | SKU | Savings/yr |
|---|---|---|---|---|
| Production | Compute Savings Plan | Compute Savings Plan | — | $22,233 |
| Development | Compute Savings Plan | Compute Savings Plan | — | $18,686 |
| Production | Reservation | App Service reserved instances | P2v3 eastus Shared ×6 | $8,340 |
| Production | Reservation | Virtual Machine reserved instances | Standard_D8as_v4 eastus Shared ×3 | $4,680 |
| ... | | | | |

Column rules:
- **Type** — `Compute Savings Plan`, `Database Savings Plan`, or `Reservation`
- **SKU** — for reservations: `<sku> <region> <scope> ×<qty>` (omit empty parts); for savings plans: `—`
- **Savings/yr** — `annual_savings_usd`; omit rows where savings = 0

If `advisor_rate_rows` is empty for all subscriptions in scope → omit the Rate optimization block entirely.

---

*Source: trigent1/devsecops/cost-anomalies · Jira: DEVSECOPS-<Unit ticket>*
```

---

## Step 4 — Confluence publishing

After displaying the report, check whether a Confluence page already exists for this title:

```
mcp__claude_ai_Atlassian__getPagesInConfluenceSpace(
  cloudId: "trigent1.atlassian.net",
  spaceKey: "PTD"
)
```

Page titles:
- **Monthly**: `Azure Cost Anomaly Report — <Month> <Year>`
- **Weekly**: `Azure Cost Weekly Report — <YYYY-MM-DD> to <YYYY-MM-DD>`

**Decision logic:**

| Scenario | Action |
|---|---|
| Page does not exist | Ask user: "No Confluence page exists for this report yet. Publish it? (yes/no)" → create if yes |
| Page exists, no `--publish` flag | Show link to existing page. Do not overwrite. |
| Page exists, `--publish` flag | Overwrite immediately — `updateConfluencePage`. |

Create: `createConfluencePage` with parent `1927315478` (FinOps page).

> **Weekly note:** Mode 1W skips Step 2b (Jira Unit ticket lookup) — there is no weekly subscription-summary Unit ticket. The Subscription Summary section is omitted from weekly reports.

---

## Error handling

| Situation | Action |
|---|---|
| `_index.json` missing | Fall back to full per-subscription tree scan; note "Index not yet built — run cost-extract to generate it" |
| No KB data for month | "No anomaly data for <month>. Run cost-extract first." |
| No Jira Unit ticket for month | Skip subscription summary section; note it in report |
| azure-cost CLI unavailable | Skip meter breakdown; note "Azure CLI session may be expired — run az login" |
| No Activity Log data | Skip Activity Log section |
| `--publish` without Confluence access | Print report to terminal; show publish command to retry |
