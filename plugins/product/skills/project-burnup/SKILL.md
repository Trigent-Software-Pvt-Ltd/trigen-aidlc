---
name: project-burnup
description: Update a burn-up chart for any Jira project. Reads config from docs/burnup-config.yml, queries Jira Units and Bolts, cross-references git and GitLab MRs, and writes a burnup JSON + HTML file. Run from the root of the target project.
---

# Project Burn-Up Chart

This skill updates the burn-up chart for a Jira-tracked project. It tracks progress at the **Bolt** level, grouped by **Unit**.

## Prerequisites

- Run from the **root of the target project**
- Atlassian MCP server must be connected (`/mcp` to verify)
- `glab` CLI must be installed and authenticated (`glab auth login`)

> The skill verifies both connections automatically on startup and will stop with a clear message if either is missing.

---

## Step 0: Verify Prerequisites

Before doing anything else, run both checks in **parallel**:

```bash
glab auth status
```

```
getAccessibleAtlassianResources()
```

**If `glab auth status` fails or returns "not logged in":**
```
❌ GitLab CLI is not authenticated.
   Run: glab auth login
   Then re-run this skill.
```
Stop immediately.

**If `getAccessibleAtlassianResources` returns an error or empty list:**
```
❌ Atlassian MCP server is not connected.
   Run /mcp in Claude Code to check your MCP connections.
   Then re-run this skill.
```
Stop immediately.

**If both pass**, print:
```
✔ GitLab CLI authenticated
✔ Atlassian MCP connected
```
Then continue.

---

## Step 0b: Read Config

Read `docs/burnup-config.yml` from the current working directory.

**If the file does not exist:** run the interactive onboarding below.

**If the file exists:** parse it, then validate that all required fields are present and correctly typed. Required fields: `project.name`, `project.description`, `project.cloudId`, `project.jiraBaseUrl`, `project.primaryProjectKey`, `project.trackingProjectKey`, `project.rootIntent`. If any are missing or the wrong type, stop immediately and report the exact field:

```
❌ Config error: Missing required field 'project.cloudId' in docs/burnup-config.yml
   Fix the field and re-run the skill.
```

If validation passes, show the user what it is configured for and ask:

```
This project is already configured for:
  Intent: <project.rootIntent> — <project.description> (<project.name>)

What would you like to do?
  1. Update — refresh the burn-up chart using the existing config
  2. New Intent — run onboarding to configure a new intent (overwrites existing config)
```

- If **Update** → proceed directly to Step 1.
- If **New Intent** → run the interactive onboarding below, then overwrite `docs/burnup-config.yml`.

---

### Onboarding (first run only)

Tell the user:
```
No config found at docs/burnup-config.yml. Let's set one up now.
I'll ask you a few questions, then query Jira to discover your Units and Bolts automatically.
```

**Phase 1 — Project identity**

Ask these three questions, one at a time, waiting for each answer:

```
1. What is this project called?
   e.g. "Chatham"

2. What feature or initiative does it cover?
   e.g. "Staff Concerns"

3. What is the Intent work type key for this Project?
   e.g. "CHAT-6"
```

**Phase 2 — Jira connection**

Ask:
```
4. What is your Atlassian instance URL?
   e.g. "https://trigent1.atlassian.net"
```

Then call `getAccessibleAtlassianResources` to retrieve the Cloud ID automatically. Match the result to the instance URL provided. If multiple tenants are returned, show the list and ask the user to confirm which one. Do not ask the user for the Cloud ID directly.

**Phase 3 — Git / MR connection**

Ask:
```
5. What project key is used for git branches and GitLab MRs?
   e.g. "CHAT"  (usually the prefix on your Jira ticket keys)

6. Were tickets migrated to a different Jira project key for status tracking?
   Enter the tracking key, or press Enter to skip if it's the same as above.
   e.g. "UKE"

7. Are there additional GitLab repos where MRs for this project may live?
   Enter repo paths separated by commas, or press Enter to skip.
   e.g. "trigent1/trigent/cpoms/studentsafe-ui, trigent1/trigent/cpoms/other-repo"
```

**Phase 4 — Auto-discover Units and Bolts**

Query children of the root Intent ticket in parallel:

```
searchJiraIssuesUsingJql(
  cloudId: "<discovered cloudId>",
  jql: "parent = <answer to question 3> ORDER BY key ASC"
)
```

Show the user the Units found:
```
Found X Units:
  Unit 1: <key> — <summary>
  Unit 2: <key> — <summary>
  ...

Are these correct? (yes / list any that should be excluded)
```

Then query children of each Unit in parallel to discover Bolts. Show the full bolt list:
```
Found X Bolts across all Units:
  Bolt 1.1: <key> — <summary>  (Unit 1)
  ...

Any bolts that are cancelled or not yet created (TBD)?
Enter keys separated by commas, or press Enter to continue.
```

**Phase 5 — Scope baseline**

Ask:
```
8. What date was the initial scope agreed?
   e.g. "2026-01-20"
```

**Write config and continue**

Write the fully populated `docs/burnup-config.yml` using the template at `{{SKILL_DIR}}/../../templates/burnup-config.yml` as a base, filled with all discovered and confirmed values. Mark any user-flagged bolts as cancelled (`jiraKey: "—"`) or TBD.

Print:
```
Config written to docs/burnup-config.yml
Continuing with burn-up update…
```

Then proceed to Step 1 using the values just collected.

---

## Step 1: Query Jira Units

Run all Unit queries **in parallel**, one per unit defined in config:

```
searchJiraIssuesUsingJql(
  cloudId: "<config.project.cloudId>",
  jql: "parent = <unit.jiraKey> ORDER BY key ASC"
)
```

Extract per Bolt: `key`, `fields.summary`, `fields.status.name`, `fields.assignee.displayName`

---

## Step 2: Map Jira Bolts to Config Bolts

1. Match bolts with known `jiraKey` directly.
2. For `TBD` bolts, match against Unit query results using **case-insensitive substring**:
   - A bolt matches a ticket if the bolt's `name` is a substring of the Jira summary (case-insensitive)
   - If multiple bolts match the same ticket → print all matches and ask the user to choose
   - If one bolt matches multiple tickets → print all candidates and ask the user to choose
   - If exactly one match → print: `Resolved TBD: Bolt {id} → {key}`
3. Fetch any `relatedJiraKeys` not returned by Unit queries:
   ```
   searchJiraIssuesUsingJql(cloudId: "...", jql: "key in (<KEY1>, <KEY2>, ...)")
   ```
4. Unresolved TBDs: set `jiraKey: null`, `jiraStatus: "unknown"`, print:
   `Warning: No Jira Bolt found for Bolt {id} ({name})`

---

## Step 2b: Query Jira Bugs

Query all bugs that are children of any Unit in **parallel**, one per unit:

```
searchJiraIssuesUsingJql(
  cloudId: "<config.project.cloudId>",
  jql: "parent in (<unit1.jiraKey>, <unit2.jiraKey>, ...) AND issuetype = Bug ORDER BY key ASC"
)
```

> Bugs sit at the same level as Bolts — they are children of Units, not the root Intent.

For each bug returned, extract:
- `key`, `fields.summary`, `fields.status.name`, `fields.assignee.displayName`, `fields.reporter.displayName`
- `fields.created` → take the date portion (`YYYY-MM-DD`) as `createdDate`
- `fields.parent.key` → use to determine `relatedUnit`

**Determine `relatedUnit`:** match `fields.parent.key` to a unit's `jiraKey` in config → use that unit's `id`. If unmatched, set `null`.

**Determine `relatedBolt`:** check `fields.issuelinks` for links to any known bolt `jiraKey` → use that bolt's `id`. If none found, set `null`.

Build a partial bugs array (MR/git data added in Steps 4 and 5):

```json
{
  "key": "UKE-999",
  "summary": "...",
  "status": "In Progress",
  "assignee": "...",
  "reporter": "...",
  "createdDate": "YYYY-MM-DD",
  "relatedUnit": 2,
  "relatedBolt": "1.2"
}
```

If no bugs found, set `bugs: []` and print: `No bugs found for this project.`

---

## Step 3: Check Git Status

Run in **parallel**:

```bash
git fetch origin main
git log main --oneline --all --grep="<config.project.primaryProjectKey>-" | head -100
git branch -r --list "origin/<config.project.primaryProjectKey>-*"
```

Then per bolt:

```bash
git log main --oneline --format="%H %ai %s" --grep="<bolt.branchKey>" | head -5
```

---

## Step 4: Query GitLab MR Data

Per bolt, search the **primary repo and all `additionalRepos`** in **parallel**:

```bash
# Primary repo — match by exact source branch name
glab mr list --source-branch "<bolt.branchKey>" --per-page 5 --output json

# Primary repo — fallback if empty: search by bolt ID, then filter title for exact match
glab mr list --search "Bolt <bolt.id>" --per-page 5 --output json | \
  jq '[.[] | select(.title | test("Bolt <bolt.id>(\\b|$)"; "i"))]'

# Additional repos — same pattern with --repo flag
glab mr list --repo <additionalRepo> --source-branch "<bolt.branchKey>" --per-page 5 --output json
glab mr list --repo <additionalRepo> --search "Bolt <bolt.id>" --per-page 5 --output json | \
  jq '[.[] | select(.title | test("Bolt <bolt.id>(\\b|$)"; "i"))]'
```

Merge results across all repos before applying composite bolt rules.

Extract:
- `created_at` — MR opened timestamp
- `merged_at` — MR merged timestamp (if merged)

**Composite bolt rules (applied across all repos combined):**
- `mrOpenedAt` → earliest `created_at` across all tickets and all repos
- `mrMergedAt` → latest `merged_at` only if ALL tickets across ALL repos are merged; otherwise `null`

**Also search MR data for each bug** (run in parallel with bolt searches):

```bash
# Primary repo — search by bug Jira key
glab mr list --search <bug.key> --per-page 5 --output json

# Additional repos
glab mr list --repo <additionalRepo> --search <bug.key> --per-page 5 --output json
```

Apply the same composite timestamp rules. Set `mrOpenedAt` / `mrMergedAt` on each bug entry.

---

## Step 5: Resolve Status

Git reality overrides Jira status.

**For bolts:**

| Condition | resolvedStatus |
|-----------|---------------|
| Merge commit on main for ALL related tickets | `merged` |
| Remote branch exists, not yet merged | `on-branch` |
| Jira Bolt status In Progress / In Review, no branch | `in-progress` |
| Bolt marked cancelled in config | `cancelled` |
| Everything else | `todo` |

**For bugs** — resolve `gitStatus`:

| Condition | gitStatus |
|-----------|-----------|
| Merge commit on main for bug key | `merged` |
| Remote branch exists, not merged | `on-branch` |
| Jira In Progress / In Review, no branch | `in-progress` |
| Bug Closed / Done, no MR evidence | `none` |
| Everything else | `todo` |

**Discrepancy detection:**

| Type | Condition |
|------|-----------|
| `jira-behind` | Git shows merged, Jira Bolt status ≠ "Done" |
| `jira-ahead` | Jira Bolt status = "Done", no merge commit on main |
| `no-branch` | Jira Bolt active, no remote branch |

---

## Step 6: Write JSON Data File

Write to `<config.project.outputJsonFile>`:

```json
{
  "generatedAt": "<ISO8601>",
  "project": {
    "name": "<project.name>",
    "description": "<project.description>",
    "primaryKey": "<project.primaryProjectKey>",
    "trackingKey": "<project.trackingProjectKey>",
    "rootIntent": "<project.rootIntent>",
    "jiraBaseUrl": "<project.jiraBaseUrl>"
  },
  "bolts": [
    {
      "id": "1.1",
      "name": "...",
      "unit": 1,
      "jiraKey": "...",
      "branchKey": "...",
      "jiraStatus": "Done",
      "gitStatus": "merged",
      "resolvedStatus": "merged",
      "completedDate": "YYYY-MM-DD",
      "assignee": "...",
      "discrepancy": null,
      "relatedTickets": [],
      "mrOpenedAt": "<ISO8601 or null>",
      "mrMergedAt": "<ISO8601 or null>"
    }
  ],
  "bugs": [
    {
      "key": "...",
      "summary": "...",
      "status": "In Progress",
      "assignee": "...",
      "reporter": "...",
      "createdDate": "YYYY-MM-DD",
      "relatedUnit": 1,
      "relatedBolt": "1.2",
      "gitStatus": "on-branch",
      "mrOpenedAt": "<ISO8601 or null>",
      "mrMergedAt": null
    }
  ],
  "scopeEvents": [
    { "date": "YYYY-MM-DD", "totalBolts": 0, "note": "Initial scope" }
  ],
  "discrepancies": [],
  "units": [
    { "id": 1, "name": "...", "jiraKey": "..." }
  ]
}
```

---

## Step 7: Update HTML File

Check if `<config.project.outputHtmlFile>` exists.

**If not:** Copy `{{SKILL_DIR}}/../../templates/burnup.html` to that path.

Then update **two blocks** inside the `<script>` tag:

**`PROJECT_CONFIG`:**
```javascript
const PROJECT_CONFIG = {
  name:        "<project.name>",
  description: "<project.description>",
  jiraBaseUrl: "<project.jiraBaseUrl>",
  dataFile:    "<outputJsonFile basename>",
};
```

**`FALLBACK_DATA`:** Replace with the full JSON object written in Step 6.

Both updates must succeed. If either fails, report the error and leave the file unchanged.

---

## Step 8: Update TBD Mappings

If any TBD bolts were resolved in Step 2, use Edit to update the `jiraKey` values in `docs/burnup-config.yml`. This prevents re-discovery on subsequent runs.

---

## Step 9: Print Summary

```
Burn-up data updated (<date>) — <project.name>

Merged:      {count}  ({bolt IDs})
On Branch:   {count}  ({bolt IDs})
In Progress: {count}  ({bolt IDs})
To Do:       {count}  ({bolt IDs})
Cancelled:   {count}  ({bolt IDs})

Discrepancies:
  - Bolt {id}: {message}

TBD mappings resolved: {count}  (or "None")

Data written to <outputJsonFile>
HTML updated: <outputHtmlFile>
```

No discrepancies → print `No discrepancies found.`

---

## Error Handling

| Failure | Behaviour |
|---------|-----------|
| Config file missing | Run interactive onboarding to auto-populate config |
| Jira MCP unavailable | Git-only resolution, warn user |
| Git command fails | Jira-only data, warn user |
| Partial data | Write JSON with `null` for missing fields |
| Unresolvable bolt | Set `resolvedStatus: "unknown"`, never drop |
| HTML update fails | Report error, leave unchanged; JSON is still valid |
