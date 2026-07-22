---
name: cost-actions
description: "After a weekly or monthly cost review meeting, reads the published Confluence report page and its comments, extracts action items, and creates DEVSECOPS Jira tickets. Designed to run immediately after the meeting call. (Triggers: cost actions, action items from cost meeting, cost meeting jira, create cost tickets, cost meeting follow-up, post-meeting cost actions)"
allowed-tools: [Bash, AskUserQuestion, mcp__claude_ai_Atlassian__getConfluencePage, mcp__claude_ai_Atlassian__getConfluencePageFooterComments, mcp__claude_ai_Atlassian__getConfluencePageInlineComments, mcp__claude_ai_Atlassian__createJiraIssue, mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql, mcp__claude_ai_Atlassian__getPagesInConfluenceSpace]
argument-hint: "<month|'last week'|YYYY-MM-DD to YYYY-MM-DD> [--dry-run]"
---

# Cost Meeting Action Items

Reads the published Confluence cost report, extracts action items from the report and meeting comments, and creates Jira tickets in DEVSECOPS.

## Repository / Space

- **Confluence space**: `PTD`
- **FinOps parent**: ID `1927315478`
- **Jira project**: `DEVSECOPS`

---

## Step 1 — Resolve the report period

From `$ARGUMENTS`:

- `last week` → previous Monday–Sunday (e.g. 2026-06-15 to 2026-06-21)
- `this week` → Monday to today
- `YYYY-MM-DD to YYYY-MM-DD` → use dates literally
- `June` / `May 2026` / `2026-06` → monthly digest
- `--dry-run` → show proposed tickets without creating them

Derive the **Confluence page title**:
- Weekly: `Azure Cost Weekly Report — <YYYY-MM-DD> to <YYYY-MM-DD>`
- Monthly: `Azure Cost Anomaly Report — <Month> <Year>`

---

## Step 2 — Find the Confluence page

Search PTD space for the page by title:

```
mcp__claude_ai_Atlassian__getPagesInConfluenceSpace(
  cloudId: "trigent1.atlassian.net",
  spaceKey: "PTD",
  title: "<page title>"
)
```

If no page found:
```
❌ No Confluence page found for "<title>".
   Run: /cost-anomalies:cost-report <period> --publish
   Then re-run this skill after the meeting.
```

---

## Step 3 — Read report content and comments

Fetch the page body and both comment types in parallel:

```
mcp__claude_ai_Atlassian__getConfluencePage(
  cloudId: "trigent1.atlassian.net",
  pageId: "<id>",
  contentFormat: "markdown"
)

mcp__claude_ai_Atlassian__getConfluencePageFooterComments(
  cloudId: "trigent1.atlassian.net",
  pageId: "<id>"
)

mcp__claude_ai_Atlassian__getConfluencePageInlineComments(
  cloudId: "trigent1.atlassian.net",
  pageId: "<id>"
)
```

---

## Step 4 — Extract action items

Collect action items from two sources:

### Source A — Report "Action Items Outstanding" section

Parse the `## Action Items Outstanding` table from the page body. Each row is a candidate action item:
- Resource, Subscription, Est. savings, Action text, Owner

### Source B — Meeting comments

Scan every footer and inline comment for action signals:
- Sentences containing: `action`, `should`, `need to`, `follow up`, `create ticket`, `investigate`, `reduce`, `disable`, `scale`, `fix`, `confirm`, `check with`, `escalate`, `@mention`
- Inline comments are anchored to a specific section — use that section heading as context (e.g. comment on "Top Anomalies" section → related to those resources)

### Merge and deduplicate

Build a unified action list. For each item record:
- `resource` — resource or RG name (from report row or comment context)
- `subscription` — subscription name
- `action` — the action to take (1 sentence)
- `owner` — @mention or name if present, otherwise blank
- `savings_est` — `~$NNN/month` if mentioned, otherwise blank
- `source` — `report` | `comment` | `both`
- `commenter` — Confluence user who left the comment (for `comment` source)

If the same resource appears in both the report and a comment, merge into one item (`source: both`) and prefer the comment's wording as it reflects the meeting discussion.

---

## Step 5 — Check for existing Jira tickets

For each action item, search DEVSECOPS to avoid creating duplicates:

```
mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql(
  cloudId: "trigent1.atlassian.net",
  jql: 'project = DEVSECOPS AND summary ~ "<resource>" AND labels = "cost-optimization" AND created >= -30d',
  fields: ["summary", "status", "assignee"],
  maxResults: 3
)
```

Mark items where a recent open ticket already exists — show them in the preview but skip creation unless the user overrides.

---

## Step 6 — Preview and confirm

Display proposed tickets before creating:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 ACTION ITEMS — <period>
Source: <Confluence page title>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1] ✅ CREATE  trigent-r8-plan-prod (Production)
    Action : Reduce App Service Plan minimum from 6 to 2 instances
    Owner  : yadewale@trigent.com
    Savings: ~$2,500/month
    Source : both (report + comment by Viacheslav)

[2] ✅ CREATE  adf-rl-staging-eastus2-q5r6 (Staging)
    Action : Review ADF trigger frequency — possible over-scheduling
    Owner  : (unassigned)
    Savings: ~$200/month
    Source : comment (dbash)

[3] ⏭️  SKIP   legacy-r6 (Production)
    Action : Investigate CDN egress spike
    Reason : DEVSECOPS-3900 already open (In Progress)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2 tickets to create · 1 skipped (existing ticket)

Create these tickets? [y/n/edit]
```

If `--dry-run` → stop here, do not create.

---

## Step 7 — Create Jira tickets

For each confirmed item, create a DEVSECOPS task:

```
mcp__claude_ai_Atlassian__createJiraIssue(
  cloudId: "trigent1.atlassian.net",
  projectKey: "DEVSECOPS",
  summary: "Cost optimisation: <action> — <resource> (<subscription>)",
  description: "<structured description — see template below>",
  issuetype: "Task",
  labels: ["cost-optimization", "finops"],
  assignee: "<accountId if owner email resolved, otherwise unassigned>"
)
```

**Description template:**

```
## Context

*From:* <Confluence page link>
*Period:* <week/month>
*Resource:* Azure/<Subscription>/<RG>/<resource>

## Action Required

<action text>

## Cost Impact

Estimated savings: <savings_est or "unknown">
Priority: <🔴 HIGH / ⚠️ MEDIUM / 🟡 LOW based on savings>

## Notes from Meeting

<verbatim comment text if source = comment>
```

---

## Step 8 — Output

```
✅ Action items created

Tickets created : <N>
Skipped (exist) : <S>

<for each created ticket>
  DEVSECOPS-XXXX  Cost optimisation: <action> — <resource>
                  <link>
```

---

## Error handling

| Situation | Action |
|---|---|
| Confluence page not found | Prompt to publish report first; show exact command |
| No action items found | "No action items found in report or comments. If the meeting hasn't happened yet, re-run after comments are added." |
| No comments, only report items | Create from report items; note "No meeting comments found — tickets based on report Action Items section only" |
| Owner email not in Jira | Leave unassigned; note in ticket description |
| Duplicate detected | Skip by default; list it in output with existing ticket link |
