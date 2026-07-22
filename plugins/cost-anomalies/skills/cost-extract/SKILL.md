---
name: cost-extract
description: "Extract Azure cost anomaly data from Outlook email alerts and/or Jira tickets and append to GitLab trigent1/devsecops/cost-anomalies CSVs. By default extracts from both sources simultaneously; --email for email only, --jira for Jira only. (Triggers: cost extract, collect cost alerts, sync cost emails, import cost anomalies, cost jira, extract cost from jira, jira cost analysis, monthly cost, weekly cost jira, daily cost jira, cost anomalies jira)"
allowed-tools: [Bash, AskUserQuestion, mcp__claude_ai_Microsoft_365__outlook_email_search, mcp__claude_ai_Microsoft_365__read_resource, mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql, mcp__claude_ai_Atlassian__getJiraIssue, mcp__claude_ai_Atlassian__atlassianUserInfo]
argument-hint: "[--email] [--jira] ['last week'|'last month'|'last Monday'|--since <date>] [--until <date>] [--subscription <name>] [--ticket <DEVSECOPS-NNNN>] [--daily-only] [--weekly-only] [--monthly-only] [--read-attachments] [--reprocess]"
---

# Cost Anomaly Extractor

Extract Azure cost anomaly data from Outlook email alerts and/or Jira tickets, publishing each finding to the GitLab cost-anomalies repository.

## Repository

- **GitLab project**: `trigent1/devsecops/cost-anomalies`
- **Project ID** (URL-encoded): `trigent1%2Fdevsecops%2Fcost-anomalies`
- **Branch**: `main`

## Help

If `$ARGUMENTS` contains "help", print:

```
/cost-anomalies:cost-extract [--email] [--jira] [options]

Extracts Azure cost anomaly data from email alerts and/or Jira tickets.

Sources:
  (default)               Extract from BOTH email alerts and Jira tickets
  --email                 Extract from Outlook email alerts only
  --jira                  Extract from Jira tickets only

Shared options:
  last week               Since last Monday (e.g. 2026-06-15)
  last month              Since the 1st of last month (e.g. 2026-05-01)
  last <weekday>          Since that specific day (e.g. "last Monday" → 2026-06-16)
  --since <date>          Since an explicit date (YYYY-MM-DD)
                          Email default: 30 days ago
                          Jira default: 3 months ago
  --until <date>          Stop at this date inclusive (YYYY-MM-DD). Default: today.
                          Also accepted as a natural date range: "June 1 - June 19"
                          or "June 1 to June 19" resolves to --since/--until automatically.
  --subscription <name>   Filter to a specific subscription (default: all).
                          Useful to pick up new comments/replies on already-extracted rows.
                          NOTE: the global cursor (email_covered/jira_covered) will NOT
                          advance — partial runs never mask unextracted subscriptions.

Jira-only options:
  --ticket <key>          Process a specific Jira ticket (e.g. DEVSECOPS-3910)
  --daily-only            Only process "Daily Cost Anomalies for DATE" tickets
  --weekly-only           Only process "Cost Anomalies for DATE - DATE" tickets
  --monthly-only          Only process "Azure Cost Analysis" Unit tickets + children
  --read-attachments      Download and read PDF/image attachments to enrich notes (off by default)
  --reprocess             Re-collect all emails/tickets even when data has already been
                          extracted (reverts to default 30-day/3-month window)

Examples:
  /cost-anomalies:cost-extract
  /cost-anomalies:cost-extract --since 2026-05-01
  /cost-anomalies:cost-extract --email --since 2026-06-01 --until 2026-06-19 --subscription Production
  /cost-anomalies:cost-extract June 1 - June 19
  /cost-anomalies:cost-extract --jira --monthly-only
  /cost-anomalies:cost-extract --jira --ticket DEVSECOPS-3911 --read-attachments
```

---

## CSV Schemas

**Email schema** — path: `Azure/<Subscription>/<resource-group-name>/<resource-group-name>.csv`

```
date,observed_at,period_type,subscription_anomaly_type,subscription_delta_pct,baseline_usd,comparison_usd,change_usd,delta_pct,percent_of_total,notes
2026-06-12,2026-06-12T10:29:33Z,daily,decrease,-1.22,,,,-34.84,3.23,
2026-06-08,2026-06-08T20:03:24Z,daily,increase,10.88,,,,86.39,4.19,Expected — TrigentLink v3 deployment MR !63 (Viacheslav)
```

| Column | Description |
|---|---|
| `date` | ISO date the anomaly was detected (YYYY-MM-DD) |
| `observed_at` | ISO datetime the alert email was sent (UTC) |
| `period_type` | Always `daily` for email alerts |
| `subscription_anomaly_type` | Subscription-level alert direction: `increase` or `decrease` |
| `subscription_delta_pct` | Signed float — subscription-level delta vs expected range |
| `baseline_usd` | RG daily cost on anomaly_date − 1 day. Empty at extract time; populated by `cost-investigate` when it fetches azure-cost data. |
| `comparison_usd` | RG daily cost on the anomaly date. Empty at extract time; populated by `cost-investigate`. |
| `change_usd` | `comparison_usd − baseline_usd`. Empty at extract time; populated by `cost-investigate`. |
| `delta_pct` | Signed float — this RG's own cost change percentage |
| `percent_of_total` | Float — this RG's share of total subscription spend on the anomaly date |
| `notes` | Human note from reply email. Max 200 chars, commas replaced with semicolons. |

**Jira schema** — path: `Azure/<Subscription>/<resource_group>/<resource_name>.csv`

```
date,observed_at,source_key,period_type,resource_type,baseline_usd,comparison_usd,change_usd,delta_pct,notes
2026-06-14,2026-06-15T08:24:45Z,DEVSECOPS-3910,daily,microsoft.compute/virtualmachinescalesets,,,48.38,569.0,Weekend cost 9.7x higher than weekend avg
2026-05,2026-06-02T08:28:15Z,DEVSECOPS-3878,monthly,microsoft.cdn/profiles,7201.52,42896.63,35695.12,495.7,
```

| Column | Description |
|---|---|
| `date` | Anomaly date `YYYY-MM-DD` (daily/weekly) or month `YYYY-MM` (monthly) |
| `observed_at` | Ticket creation datetime (ISO 8601 UTC) |
| `source_key` | Jira ticket key (e.g. `DEVSECOPS-3910`) |
| `period_type` | `daily`, `weekly`, or `monthly` |
| `resource_type` | Azure resource type (lowercase) |
| `baseline_usd` | Prior period cost — populated for monthly; empty for daily/weekly |
| `comparison_usd` | Current period cost — populated for monthly; empty for daily/weekly |
| `change_usd` | Absolute cost difference in USD |
| `delta_pct` | Percentage change |
| `notes` | Short human summary from ticket comments/attachments; falls back to analysis text. Max 200 chars. |

---

## Step 1 — Parse arguments and detect mode

### Flag detection

From `$ARGUMENTS`:
- `--email` flag present (and no `--jira`) → **Email-only mode**
- `--jira` flag present (and no `--email`) → **Jira-only mode**
- Both flags present or neither → **Both mode** (run email extraction then Jira extraction)
- `--subscription <name>` → filter by subscription (applied in both sources)
- `--ticket <key>` → Jira only: process a single ticket; skip all searches
- `--daily-only` / `--weekly-only` / `--monthly-only` → Jira only: restrict ticket type
- `--read-attachments` → Jira only: download and read attachments
- `--reprocess` → ignore cursor and coverage checks; use original defaults (30 days for email, 3 months for Jira)

### Period resolution

After stripping flags, interpret the remaining argument text as a time period — **any natural format**. Resolve it to an explicit `period_start` and `period_end` (both `YYYY-MM-DD`):

- A range always has both a start and an end.
- A single date means that one day only (`period_start = period_end`).
- A month name means the full month (`period_start = first day`, `period_end = last day of month or today if current month`).
- A week keyword means Mon–Sun of that week (or Mon–today for the current week).
- No date argument at all → `period_start` and `period_end` are left **unset** (cursor-driven, resolved in Step 1b).

Examples (today = 2026-06-22, cursor = 2026-06-19):

| Argument | `period_start` | `period_end` |
|---|---|---|
| *(none)* | unset | unset |
| `June` | 2026-06-01 | 2026-06-22 (today, month in progress) |
| `May` | 2026-05-01 | 2026-05-31 |
| `June 22` | 2026-06-22 | 2026-06-22 |
| `June 1 - June 19` | 2026-06-01 | 2026-06-19 |
| `last week` | 2026-06-15 | 2026-06-21 |
| `last month` | 2026-05-01 | 2026-05-31 |
| `2026-06` | 2026-06-01 | 2026-06-22 |
| `--since 2026-06-01 --until 2026-06-19` | 2026-06-01 | 2026-06-19 |

---

## Step 1b — Coverage advisory

Fetch `_index.json` now (reused by Steps A0 and B0 — do not fetch again):

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/_index.json?ref=main" 2>/dev/null \
  | python3 -c "
import sys,json,base64
d=json.load(sys.stdin)
idx=json.loads(base64.b64decode(d['content']).decode()) if 'content' in d else {}
import json; print(json.dumps(idx))
" 2>/dev/null
```

**If `--subscription <name>` was provided**, print before proceeding:

```
⚡ Partial-subscription run — only "<subscription>" will be extracted.
   The global coverage cursor (email_covered / jira_covered) will NOT advance.
   Useful for picking up new comments or replies on already-extracted rows.
   Run without --subscription to advance the cursor and cover all subscriptions.
```

Let `cursor_until = email_covered.until` (or `jira_covered.until` for Jira-only mode; use the earlier of the two for Both mode).

**If `period_start`/`period_end` are unset** (no date argument): set `period_start = cursor_until + 1 day`, `period_end = today`. No advisory needed — proceed silently.

**If `period_start`/`period_end` are set**, compare to `cursor_until`:

Compute the **overlap** (already covered) and **new** (not yet covered) sub-ranges:
- `covered_portion` = intersection of `[period_start, period_end]` with `[cursor_since, cursor_until]`
- `new_portion` = portion of `[period_start, period_end]` that is **after** `cursor_until`
- `gap` = if `period_start > cursor_until + 1 day`, the uncovered dates between them

Then show a single pre-flight summary **before any API calls**:

```
📅 Coverage check  (index: {cursor_since} → {cursor_until})

  Requested : {period_start} → {period_end}
  Already extracted : {covered_portion or "none"}
  New to extract    : {new_portion or "none"}
  Gap               : {gap or "none"}
```

Then apply the following rules:

| Situation | Action |
|---|---|
| Entire period already covered (`covered_portion = full period`, no new, no gap) | Inform user: "✅ This period is fully covered. No new rows will be written. Comment re-check will still run for Jira tickets." Proceed to comment re-check only (skip email/Jira row search). |
| Partial overlap — some new data after cursor, no gap | Proceed. Extract only the `new_portion`. Cursor advances to `period_end`. |
| Gap detected (`period_start > cursor_until + 1 day`) | Ask: **"⚠️ A gap exists ({gap}). Proceed anyway (cursor will NOT advance) or cancel to fill the gap first?"** — If cancel → stop. If proceed → run extraction for full requested range but hold the cursor. |
| No overlap at all, no gap (period entirely in future) | Proceed normally. |
| `period_end < cursor_since` (entirely before any known data) | Inform: "⚠️ This period predates the earliest extraction ({cursor_since}). Proceeding as a historical backfill — cursor will NOT advance." |

**Comment re-check exception**: regardless of overlap, the Jira comment-enrichment step (Step B3) and email reply-enrichment step (Step A5) always run for any ticket/email whose `date` falls within `[period_start, period_end]`, even if that row already exists in the KB. New comments or replies written after the original extraction may contain explanations not yet captured in `notes`. Existing rows with a non-empty `notes` field are updated only if the new note is more informative (longer or contains new keywords like "resolved", "fixed", "confirmed").

---

## PART A — Email Extraction

*Run when mode is Email-only or Both. Skip entirely for Jira-only mode.*

### Step A0 — Determine effective since date for emails

Skip this step if `--since` was explicitly provided, a natural date keyword was found in arguments, or `--reprocess` is set. In those cases use the resolved date as-is or fall back to 30 days ago.

Otherwise fetch `_index.json` to find the last covered email period:

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/_index.json?ref=main" 2>/dev/null \
  | python3 -c "
import sys,json,base64
d=json.load(sys.stdin)
idx=json.loads(base64.b64decode(d['content']).decode()) if 'content' in d else {}
cov=idx.get('email_covered',{})
print(cov.get('until',''))
" 2>/dev/null
```

- **`email_covered.until` is present**: use it as the effective `--since` date. Log one line:
  `📅 Email: resuming from last covered period (since <until-date>, previously covered <since-date> → <until-date>). Use --reprocess to collect from scratch.`
- **Absent or empty** (first run, or field not yet set): use the default (30 days ago). No log needed.

Store the `_index.json` content in memory — Step B0 will reuse it without a second fetch.

### Step A1 — Fetch cost anomaly emails

Search Outlook for cost anomaly emails:

```
mcp__claude_ai_Microsoft_365__outlook_email_search(
  query: "Cost anomaly detected",
  afterDateTime: <since or 30 days ago>,
  limit: 25
)
```

Page through results using `nextOffset` until all pages are exhausted.

If zero emails found (and Jira-only is not also running), output:
```
No cost anomaly emails found since <date>.
```

### Step A2 — Search for reply emails

```
mcp__claude_ai_Microsoft_365__outlook_email_search(
  query: "Re: Cost anomaly detected",
  afterDateTime: <since or 30 days ago>,
  limit: 25
)
```

Page through results using `nextOffset` until all pages are exhausted.

For each result:
- **Skip** if sender is `microsoft-noreply@microsoft.com`
- **Keep** if sender is a team member (non-Microsoft domain)
- Extract subscription name from subject: `Re: [EXTERNAL]Cost anomaly detected in <Subscription Name>` → apply same normalisation as Step A4
- Read full body using `mcp__claude_ai_Microsoft_365__read_resource`

Build a **reply index** keyed by normalised subscription name:
```
reply_index["Staging - UK"] = [
  { "sender": "Viacheslav Frolov", "sentDateTime": "...", "body_text": "..." },
]
```

### Step A3 — Read each email body

For each alert email returned in Step A1:

```
mcp__claude_ai_Microsoft_365__read_resource(
  uri: "mail:///messages/<messageId>"
)
```

### Step A4 — Parse each email

From the subject line `Cost anomaly detected in <Subscription Name>`, extract:
- **subscription_raw** — everything after "Cost anomaly detected in " (trim trailing whitespace)
- **subscription** — normalise for use as a folder name:
  - Replace em-dash (–, U+2013) and en-dash (‐, U+2012) with ` - `
  - Remove or replace characters not safe in GitLab paths: `( ) : * ? " < > |`
  - Collapse multiple spaces to one, trim leading/trailing spaces

From the email `sentDateTime` field:
- **observed_at** — convert to ISO 8601 UTC string (e.g. `2026-06-12T10:29:33Z`)

From the email body, extract:
- **anomaly_date** — the date mentioned in the opening sentence → normalise to ISO `YYYY-MM-DD`
- **subscription_anomaly_type** — `decrease` if body contains "cost decrease", `increase` if "cost increase" or "cost spike"
- **subscription_delta_pct** — signed float from "Delta compared to expected range" table row
- **resource_group_rows** — the table under "Most significant changes in resource group(s)":
  - Each row: `name`, `cost_change_%`, `percent_of_total`
  - Parse `cost_change_%` as a signed float (strip `%` and any `+`)
  - Parse `percent_of_total` as a float

If the subject does not match the expected pattern, skip and log:
```
⚠️  Skipping email "<subject>" — subject does not match expected format
```

Apply `--until` filter: skip emails where `sentDateTime` (date part) > `until_date`.

Apply `--subscription` filter if provided: skip emails where `subscription_raw` does not match (case-insensitive).

### Step A5 — Enrich notes from reply emails

For each parsed alert email, look up replies in the reply index using the normalised subscription name.

**Tokenise each RG name**: split on `-` and `_`, lowercase, discard tokens shorter than 4 chars (except: `aks`, `adf`, `cdn`, `sql`, `rl`, `uk`) and pure hex/random suffixes.

**Score each RG against the reply body**: count how many meaningful tokens appear in the normalised reply text. Score = matched_tokens / total_tokens.
- Score ≥ 0.5 → matched set
- Non-empty matched set → apply note only to those RGs
- Empty matched set → apply note to **all RGs** (general subscription comment)

**Generating the note** (max 200 chars, no newlines):
1. Explanation — WHY the cost changed (look for "expected", "caused by", MR links, deployment mentions)
2. Investigation result — root cause confirmed, action taken
3. Attachment mentioned → `"See attached screenshot (Name)"`
4. No usable content → leave `notes` empty

Format rules: Replace commas with semicolons; strip HTML and markdown; shorten MR URLs (`merge_requests/63` → `MR !63`); include sender first name if space allows. If multiple replies, synthesise the most informative one.

Notes are only applied to **new rows being written** in this run. If a row already has a note and a newer reply exists, update it.

### Step A6 — Deduplicate email rows against existing CSVs

For each unique `(subscription, rg_name)` pair, fetch the existing CSV:

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "Azure/<Subscription>/<rg-name>/<rg-name>.csv")?ref=main" 2>/dev/null
```

Dedup key: `(date, observed_at)` — skip rows where both match an existing row.

### Step A7 — Schema migration for email CSVs

Email CSV files may exist in older layouts. When updating, detect the column count from the header and migrate to the current 11-column format:

| Existing header ends with | Col count | Migration |
|---|---|---|
| `percent_of_total` | 7 | Insert 3 empty USD fields after col 5 (`subscription_delta_pct`) and append `,` for `notes` — `fields[:5] + ['','',''] + fields[5:] + ['']` |
| `notes` (after `percent_of_total`) | 8 | Insert 3 empty USD fields after col 5 — `fields[:5] + ['','',''] + fields[5:]` |
| `change_usd` (current format) | 11 | Already current — leave existing rows unchanged |

New header: `date,observed_at,period_type,subscription_anomaly_type,subscription_delta_pct,baseline_usd,comparison_usd,change_usd,delta_pct,percent_of_total,notes`

---

## PART B — Jira Extraction

*Run when mode is Jira-only or Both. Skip entirely for Email-only mode.*

### Step B0 — Determine effective since date for Jira tickets

Skip this step if `--since` was explicitly provided, a natural date keyword was found, `--ticket` was provided, or `--reprocess` is set.

Otherwise reuse the `_index.json` already fetched in Step A0 (if email extraction ran), or fetch it now:

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/_index.json?ref=main" 2>/dev/null \
  | python3 -c "
import sys,json,base64
d=json.load(sys.stdin)
idx=json.loads(base64.b64decode(d['content']).decode()) if 'content' in d else {}
cov=idx.get('jira_covered',{})
print(cov.get('until',''))
" 2>/dev/null
```

- **`jira_covered.until` is present**: use it as the effective `--since` date. Log one line:
  `📅 Jira: resuming from last covered period (since <until-date>, previously covered <since-date> → <until-date>). Use --reprocess to collect from scratch.`
- **Absent or empty**: use the default (3 months ago). No log needed.

### Step B1 — Find tickets

If `--ticket` was provided, fetch that single ticket directly (detect its type from the summary) and go to Step B2.

Otherwise run the applicable searches:

**Daily** (unless `--weekly-only` or `--monthly-only`):
```
mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql(
  cloudId: "trigent1.atlassian.net",
  jql: 'summary ~ "Daily Cost Anomalies for" AND issuetype = "Bolt" AND project = DEVSECOPS ORDER BY created ASC',
  fields: ["summary", "description", "created", "comment", "attachment"],
  maxResults: 100
)
```

**Weekly** (unless `--daily-only` or `--monthly-only`):
```
mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql(
  cloudId: "trigent1.atlassian.net",
  jql: 'summary ~ "Cost Anomalies for" AND summary !~ "Daily" AND issuetype = "Bolt" AND project = DEVSECOPS ORDER BY created ASC',
  fields: ["summary", "description", "created"],
  maxResults: 50
)
```

**Monthly** (unless `--daily-only` or `--weekly-only`):
```
mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql(
  cloudId: "trigent1.atlassian.net",
  jql: 'summary ~ "Azure Cost Analysis" AND issuetype = "Unit" AND project = DEVSECOPS ORDER BY created ASC',
  fields: ["summary", "description", "created"],
  maxResults: 20
)
```
Then for each Unit ticket, fetch its child Bolts:
```
mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql(
  jql: 'parent = <UNIT-KEY> ORDER BY created ASC',
  fields: ["summary", "description", "created"],
  maxResults: 20
)
```

Filter all results to tickets created after `--since` date and (if `--until` was provided) on or before `--until` date. Append `AND created <= "<until_date>"` to each JQL query when `--until` is set. Deduplicate by key.

### Step B2 — Parse tickets

#### Daily tickets — `Daily Cost Anomalies for YYYY-MM-DD`

- **date** = date from title
- **observed_at** = ticket `created` datetime → ISO 8601 UTC
- **source_key** = ticket key
- **period_type** = `daily`

Parse anomaly tables in description.
`Change` column format: `+$48.38 (+569%)` → `change_usd = 48.38`, `delta_pct = 569.0`

**Derive baseline/comparison USD for daily rows** — when both `change_usd` and `delta_pct` are non-empty and `delta_pct != 0`:
```python
baseline_usd  = round(change_usd / (delta_pct / 100), 2)
comparison_usd = round(baseline_usd + change_usd, 2)
```
This avoids an azure-cost API call at extract time. Leave both empty if either input is missing or zero.

#### Weekly tickets — `Cost Anomalies for YYYY-MM-DD - YYYY-MM-DD`

- **date** = `week_start` (first date)
- **observed_at** = ticket `created` datetime → ISO 8601 UTC
- **source_key** = ticket key
- **period_type** = `weekly`

`Cost Difference` column format: `$24.06` → `change_usd = 24.06`, `delta_pct` empty for weekly.

#### Monthly tickets — child Bolts of `Azure Cost Analysis - <Month> <Year>`

- **date** = month as `YYYY-MM` (from parent Unit ticket summary)
- **observed_at** = child Bolt `created` datetime → ISO 8601 UTC
- **source_key** = child Bolt ticket key
- **period_type** = `monthly`

Child Bolt summary pattern: `[<Subscription>] Azure Cost Increase/Decrease (+$X)`

Parse Cost Drivers table: `Resource Group | Resource Type | Resource Name | Baseline | Comparison | Change | Change %`
- `baseline_usd`, `comparison_usd` → strip `$`, commas, parse float
- `change_usd` = `comparison_usd - baseline_usd`
- `delta_pct` → strip `%`, parse float; set empty for `New`/`inf`
- `notes` = `New resource` if resource has 🆕 marker or appears in New Resources table

### Anomaly table parsing rules (daily & weekly)

Sections per subscription (`## Production`, `## Development – UK`, etc.).

**Normalise subscription name**: em-dash → ` - `, strip parentheses content, trim.

Skip sections containing "No anomalies detected."

**Stop parsing** any block as soon as you encounter `**Daily Cost Breakdown` — everything after is a day-by-day sub-table. **Skip** "Cost drivers on DATE" tables entirely.

For each anomaly table row:
- `anomaly_date` = Date column → ISO YYYY-MM-DD
- `change_usd` = Cost Difference or Change amount (strip `$`, `+`)
- `delta_pct` = percentage from `(+569%)` format if present; empty for weekly
- `resource_name` = Resource Name column (strip 🆕 markers)
- `resource_group` = Resource Group Name column
- `resource_type` = Type column (lowercase)
- `notes` = Analysis column (truncate 300 chars; replace commas with semicolons)

**Validate each row — skip if:**
- `resource_group` matches `YYYY-MM-DD`
- `resource_group` or `resource_name` starts with `**` or `_20`
- `resource_group` is a known table header (`**Date**`, `**Change**`, etc.)
- `resource_name` is empty or `---`

Parse all three anomaly sections:
- `### ✓ Real Anomalies` → `notes` = analysis text
- `### ⚠ Weekend/Weekday Pattern` → `notes` = analysis text
- `### ↔ Redistribution` → `notes` = `"Cost shifted within resource group (delta: " + Delta + ")"`

### Step B3 — Enrich notes from comments and attachments

After extracting rows from descriptions, check each ticket's comments and attachments.

When searching or fetching tickets, include `"comment"` and `"attachment"` in the `fields` list.

For **daily and weekly Bolt tickets**: comments contain human responses (explanations, confirmations).
For **monthly child Bolt tickets**: also fetch parent Unit ticket comments.

**Skip auto-generated comments**: before processing any comment, check its body for the marker `Investigated automatically via cost-investigate`. If present, skip the comment entirely — it was written by the cost-investigate skill and does not represent a human explanation. Only manually written comments are used to enrich `notes`.

**Attachments:**

Default (no `--read-attachments`): skip attachment content. If `fields.attachment` is non-empty, note filenames only (priority 3 below).

With `--read-attachments`: download and read each attachment.

Resolve credentials once at run start:
1. Email — call `mcp__claude_ai_Atlassian__atlassianUserInfo()` → use `email` field as `_jira_email`
2. Token — check `$JIRA_API_TOKEN`:
   - Set → use as `_jira_token`
   - Not set → ask once via `AskUserQuestion`: `"Provide your Jira API token to read attachments, or skip."` Options: `["Enter token", "Skip"]`. If provided, persist to `~/.claude/settings.json`:
   ```bash
   python3 -c "
   import json, sys
   path = '/Users/viacheslav.frolov/.claude/settings.json'
   with open(path) as f: s = json.load(f)
   s.setdefault('env', {})['JIRA_API_TOKEN'] = sys.argv[1]
   with open(path, 'w') as f: json.dump(s, f, indent=2)
   " "$_jira_token"
   ```

Download and read each attachment:
```bash
curl -s -u "$_jira_email:$_jira_token" "<attachment.content URL>" -o /tmp/jira-attachment-<id>.<ext>
```
- **PDF** → extract text (root causes, action items, cost figures)
- **Image** (`.png`, `.jpg`, `.jpeg`, `.gif`) → visual description
- **CSV** → raw content
- **Other** → skip, note filename only

Clean up: `rm -f /tmp/jira-attachment-*`

**Generate the summary** (max 200 chars, no newlines, commas → semicolons):
1. Explanation — WHY the cost changed (look for "expected", "caused by", MR links, deployment mentions)
2. Investigation result — root cause confirmed or resolved: "confirmed", "fixed", "resolved", "no action needed"
3. Attachment mention (no `--read-attachments`): `"See attached: report.pdf; image.png"`
4. No comments → keep original analysis text from description (truncated to 200 chars)

Override vs append:
- Clear explanation from comments → **replace** description analysis
- Partial context only → **prepend**: `"Expected; <original analysis>"`
- Only noise (status updates, auto-generated) → keep original

### Step B4 — Deduplicate Jira rows against existing CSVs

For each `(subscription, resource_group, resource_name)`, fetch existing file:

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "Azure/<Sub>/<rg>/<resource>.csv")?ref=main" 2>/dev/null
```

Dedup key: `(date, source_key)` — skip rows where both match an existing row.

---

## Step 2 — Build GitLab commit actions

Collect all new rows from Parts A and B. Group by target file path.

For each file:
- **Does not exist**: `action = "create"`, content = correct schema header + rows
- **Exists (email schema)**: `action = "update"` — apply schema migration if needed (7→11 cols or 8→11 cols; see Step A7), then append new rows
- **Exists (Jira schema)**: `action = "update"` — append new rows only

Sort rows within each file by `(date, observed_at)` ascending before writing.

Commit message:
- Email-only: `cost: add email anomaly alerts for <date-range> (<N> RGs across <M> subscriptions)`
- Jira-only: `cost: add Jira anomaly data <date-range> (<N> tickets; <R> rows)`
- Both: `cost: add email alerts + Jira anomaly data <date-range>`

---

## Step 3 — Update freshness index

Append a `_index.json` action to the commit payload.

**Fetch the current index:**

```bash
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/_index.json?ref=main" 2>/dev/null \
  | python3 -c "
import sys,json,base64
d=json.load(sys.stdin)
print(base64.b64decode(d['content']).decode() if 'content' in d else '{\"files\":{}}')
" 2>/dev/null || echo '{"files":{}}'
```

Record whether the file existed — determines `"action": "update"` vs `"create"`.

For each CSV in this run's commit actions, derive from its full merged content (existing rows + new rows):
- `last_date` — max value in the `date` column across all data rows (excluding header)
- `row_count` — total data row count (excluding header)
- `last_extracted` — current UTC datetime, ISO 8601 (e.g. `2026-06-22T09:15:00Z`)

**Merge**: take fetched `files` dict; overwrite only keys for CSV files touched in this commit. Leave all other entries unchanged.

**Also update top-level coverage fields** — these are read by Step A0/B0 on the next run to avoid redundant re-collection.

Two fields track the full coverage window:
- `email_covered.since` — the **earliest** date ever extracted. Set on the first run; afterwards only moves earlier (never later). Use `min(current_since, resolved_since)`.
- `email_covered.until` — the **latest** date extracted so far. Always advances: use `max(current_until, resolved_until)`.
- Same rules for `jira_covered`.

Example: first run April–May sets `since=2026-04-01, until=2026-05-31`. Second run June 1–19 keeps `since=2026-04-01`, advances `until=2026-06-19`.

**Resolved `--until`** (in order of precedence):
- `--until <date>` flag → that date
- Natural date range (`June 1 - June 19`, `last week`, `last month`, `this week`) → the range's end date (e.g. `last week` on a Sunday → preceding Saturday; `June 1 - June 19` → `2026-06-19`)
- No `--until` and no natural range → today's date

**Resolved `--since`** → whichever source was used: explicit `--since`, natural range start, A0/B0 cursor value, or 30-day/3-month default.

| Scenario | `email_covered` | `jira_covered` |
|---|---|---|
| Any email run (any `--since` source, any `--until` source) | Update: `since` = min(current `since`, resolved `--since`), `until` = max(current `until`, resolved `--until`) | *(unchanged unless jira also ran)* |
| Any jira run (any `--since` source, any `--until` source) | *(unchanged unless email also ran)* | Update: `since` = min(current `since`, resolved `--since`), `until` = max(current `until`, resolved `--until`) |
| `--email` only | Update `email_covered` | **Do not update** |
| `--jira` only | **Do not update** | Update `jira_covered` |
| `--ticket` only | **Do not update** | **Do not update** |
| `--subscription <name>` | **Do not update** | **Do not update** |

Append one action to the commit payload:

```json
{
  "action": "update",
  "file_path": "_index.json",
  "content": "{\n  \"email_covered\": {\"since\": \"2026-05-23\", \"until\": \"2026-06-22\"},\n  \"generated\": \"2026-06-22T09:15:00Z\",\n  \"jira_covered\": {\"since\": \"2026-03-22\", \"until\": \"2026-06-22\"},\n  \"files\": {\n    \"Azure/Production - UK/cpomsuk-prod-rg/cpomsuk-prod-rg.csv\": {\n      \"last_date\": \"2026-06-15\",\n      \"last_extracted\": \"2026-06-22T09:15:00Z\",\n      \"row_count\": 12\n    }\n  }\n}"
}
```

Use `"action": "create"` if `_index.json` did not exist. Serialize as 2-space-indented JSON with top-level key order: `email_covered`, `jira_covered`, `generated`, `files` (metadata before the large files block). Within each coverage object: `since` before `until`. Within each file entry: `last_date`, `last_extracted`, `row_count`. The `files` dict keys are sorted alphabetically by path. Omit `email_covered` / `jira_covered` if the corresponding source has never run and did not run this invocation.

---

## Step 4 — Commit to GitLab

```bash
cat << 'PAYLOAD' | glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/commits" -X POST -H "Content-Type: application/json" --input -
<commit JSON from Step 2 + Step 3>
PAYLOAD
```

If nothing new to commit (all rows deduplicated): output `Nothing new to import` and stop.

---

## Step 5 — Auto-budget new RGs

After the commit, identify any **newly created** RG files from Step 2 (all `action = "create"` for `Azure/<Sub>/<rg>/…` paths). Collect unique new RG folders. For each new RG folder, check whether `_budget.json` already exists:

```bash
# GitLab returns valid JSON even on 404 — must check for 'content' key
glab api "projects/trigent1%2Fdevsecops%2Fcost-anomalies/repository/files/<encoded-path>?ref=main" 2>/dev/null \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('EXISTS' if 'content' in d else 'NOT_FOUND')" 2>/dev/null \
  || echo "NOT_FOUND"
```

For each new RG without a budget:

1. Fetch 6-month costs using `azure-cost dailyCosts --dimension ResourceGroupName`
2. Filter to the new RG, aggregate daily → monthly totals
3. Apply eligibility criteria:
   - ≥ 3 complete months of data
   - Median monthly spend ≥ $50
4. **If eligible** → calculate median-based budget (×1.2) and commit `_budget.json`
5. **If not eligible** → log and skip:
   - `"<rg>: < $50/month median — no budget needed"`
   - `"<rg>: < 3 months of history — will be picked up by next cost-budget generate"`

Commit all new budget files in a single additional commit:
```
budget: auto-generate budgets for <N> new RGs discovered via cost-extract
```

---

## Step 6 — Output

```
✅ Cost anomaly data extracted

Sources         : <Email / Jira / Both>
```

**If email ran:**
```
Emails processed: <N> alerts + <P> replies
Email RGs       : <M> across <K> subscriptions
Email rows      : <R> new / <D> skipped (dupes)
Notes enriched  : <E> rows (from <P> replies)
```

**If Jira ran:**
```
Tickets processed: <N> daily / <W> weekly / <M> monthly
Dates covered    : <range>
Jira rows        : <R> new across <F> files / <D> skipped (dupes)
```

**Always:**
```
Auto-budgets    : <N> created / <M> skipped (below threshold or insufficient history)

GitLab: https://gitlab.com/trigent1/devsecops/cost-anomalies
```

**Budget staleness advisory** — skip if `--subscription` was provided (partial run):

Compute `latest_complete_month` from today's date (last full calendar month, e.g. `"2026-05"` on June 22).
Read `budget_covered.until` from the `_index.json` already in memory.

| Situation | Output |
|---|---|
| `budget_covered` absent (never generated) | `💰 No budget data found — run /cost-anomalies:cost-budget generate to set RG spending baselines.` |
| `budget_until < latest_complete_month` | `💰 Budget data last generated: {budget_until}. {latest_complete_month} is now complete — run /cost-anomalies:cost-budget generate to refresh.` |
| `budget_until >= latest_complete_month` | *(no output — budgets are current)* |

---

## Error handling

| Situation | Action |
|---|---|
| Email body has no RG table | Skip email, log warning |
| Subscription name missing from email subject | Skip email, log warning |
| Reply email has no usable content | Leave `notes` empty for those rows |
| Daily/weekly Jira ticket summary doesn't match expected pattern | Skip, log warning |
| Monthly child Bolt summary doesn't match `[Sub] Azure Cost Increase/Decrease` | Skip that child |
| `change_usd` unparseable | Set to `0.0`, still write row |
| All rows already exist | Output: "Nothing new to import" |
| azure-cost unavailable for Step 5 | Skip auto-budget silently; user can run `cost-budget generate` manually |
| GitLab 401/403 | Stop: "Check `glab auth status`" |
| GitLab 404 on project | Stop: "Repository not found" |
