---
name: add-flaky-test-to-hub
description: "Add a new flaky test entry to the CPOMS StudentSafe Flaky Tests Hub Confluence page, given a test file path/line and a CI job URL."
allowed-tools: [Bash, AskUserQuestion, Read, mcp__gitlab__get_pipeline_job_output, mcp__atlassian__getConfluencePage, mcp__atlassian__updateConfluencePage]
---

You are adding a new flaky test entry to the CPOMS StudentSafe Flaky Tests Hub on Confluence.

## Fixed defaults (do not prompt the user for these)

- **Confluence page ID**: `2378039297` (CPOMS StudentSafe Flaky Tests Hub)
- **GitLab project**: `trigent1/trigent/cpoms/cpoms`
- **Atlassian domain**: `trigent1.atlassian.net`

## Prerequisites

Check `confluence-cli` before proceeding. If missing, tell the user and offer to continue with MCP instead — do not halt unless the user asks to.

```bash
which confluence-cli
```

If not found:

---
`confluence-cli` is not installed. It is the preferred method for reading and updating the
Confluence hub page (lower cost than MCP).

To install and set it up:

**1. Install** (macOS):
```bash
brew install confluence-cli
```
Or via npm: `npm install -g confluence-cli`

**2. Initialise** and answer the prompts as follows:
```
? Protocol: HTTPS (recommended)
? Confluence domain: https://trigent1.atlassian.net
? REST API path: /wiki/rest/api
? Authentication method: Basic (credentials)
? Email / Username: <your email>
? API token / password: <your Atlassian API token>
```
Generate a token at: https://id.atlassian.com/manage-profile/security/api-tokens

Once set up, re-run the skill.
Alternatively, continue now and the Atlassian MCP will be used for Confluence operations instead.

---

## Steps

### 1. Resolve the user's Atlassian account ID

Run this once at the start of the session and hold the result in memory. This ID is used in the "Added by" cell.

```bash
CONFIG=~/.confluence-cli/config.json
EMAIL=$(python3 -c "import json,os; c=json.load(open(os.path.expanduser('$CONFIG'))); print(c['profiles']['default']['email'])")
TOKEN=$(python3 -c "import json,os; c=json.load(open(os.path.expanduser('$CONFIG'))); print(c['profiles']['default']['token'])")
DOMAIN=$(python3 -c "import json,os; c=json.load(open(os.path.expanduser('$CONFIG'))); print(c['profiles']['default']['domain'])")

ACCOUNT_ID=$(curl -s -u "$EMAIL:$TOKEN" "https://$DOMAIN/rest/api/3/myself" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['accountId'])")

echo $ACCOUNT_ID
```

If `confluence-cli` is unavailable and you are using MCP, ask the user to provide their Atlassian account ID manually.

### 2. Gather inputs

Prompt the user for:

1. **Test file path and line number** — e.g. `test/acceptance/reports_acceptance_test.rb:892` or `spec/system/incidents/jsh_spec.rb:46`
2. **CI job URL** — e.g. `https://gitlab.com/trigent1/trigent/cpoms/cpoms/-/jobs/14164288388`. If unavailable, they can enter `none` and the pipeline cell will be left empty.
3. **Flaky where?** — `CI`, `Local`, or `Both` (default: `CI`)

### 3. Read the test

Split the input on `:` to get the file path and line number. Read the file around that line to extract:

- The exact example/test name (the full `it "..."` / `describe "..."` chain, or `def test_xxx` method name, or the RSpec example description)
- What the test does (to inform the Notes cell)

```
Read <file_path>, offset = <line_number - 5>, limit = 35
```

### 4. Fetch the CI failure output

Extract the numeric job ID from the URL (the trailing number). Then call:

```
mcp__gitlab__get_pipeline_job_output(
  project_id: "trigent1/trigent/cpoms/cpoms",
  job_id: "<JOB_ID>",
  limit: 100
)
```

Look for the `Failure:` block. Pay attention to requeue/retry failures — the retry error often reveals more about root cause. For example:
- Initial: `Expected content "Total incidents:" not found on page` → timeout
- Retry: `Capybara::ElementNotFound: Unable to find visible xpath "/html"` → page never rendered

The pattern `Unable to find visible xpath "/html"` on retry is a strong signal of a CI resource/timing issue rather than a test logic bug.

If the CI job URL was `none`, skip this step.

### 5. Compose the Notes cell content

Apply the same filtering rules as the `triage-flaky-tests` skill. The Notes cell purpose is to record **factual context from the CI failure** — nothing else.

**Include only:**
- Verbatim failure messages from the `Failure:` block, quoted in `<code>` tags with HTML entities
- Retry failure message if present and meaningfully different
- References to specific commits, PRs, or code changes if the user mentions them

**Exclude entirely:**
- Speculation or theories about causes (e.g. "probably a timing issue")
- Editorial opinions or frustration
- Vague notes (e.g. "still happening", "no idea")

Use HTML entities in the composed content:
- `&ldquo;` / `&rdquo;` for curly double quotes (")
- `&mdash;` for em dash (—)
- `&quot;` for straight double quotes inside attribute values
- Encode `<` and `>` as `&lt;` and `&gt;` if they appear in literal text (not as tags)

**If no factual content is available** after filtering (e.g. no CI URL given), use an empty `<p ... />` tag for the Notes cell.

### 6. Fetch the hub page

**Primary — use `confluence-cli`:**

```bash
# Fetch the storage HTML to a clean file (no header stripping needed with -o)
confluence-cli edit 2378039297 -o /tmp/flaky-hub.html 2>&1 | tee /tmp/flaky-hub-meta.txt

# Capture the version number
grep -E '^Version:' /tmp/flaky-hub-meta.txt
```

The `-o` flag writes storage HTML directly to the file; the `Page Information:` header only appears on stdout. Hold the version number in memory.

**Fallback — if `confluence-cli` is unavailable**, use MCP:

```
mcp__atlassian__getConfluencePage: pageId=2378039297, contentFormat=storage
```

Hold the full storage body and the version number in memory.

### 7. Build the new table row

Generate 25 unique UUIDs (one per `ac:local-id` and `local-id` attribute) using Python:

```bash
python3 -c "import uuid; [print(str(uuid.uuid4())) for _ in range(25)]"
```

Assign them in order: `ID_ROW`, `ID_TD1`, `ID_P1`, `ID_TD2`, `ID_P2`, ... through to `ID_TD11`, `ID_P11`.

Use today's date in `YYYY-MM-DD` format:

```bash
date +%Y-%m-%d
```

Build the row using this 11-column template. Substitute actual values for the placeholders:

```html
<tr ac:local-id="ID_ROW">
  <td ac:local-id="ID_TD1"><p local-id="ID_P1"><code>FILE_PATH</code></p></td>
  <td ac:local-id="ID_TD2"><p local-id="ID_P2">LINE_NUMBER</p></td>
  <td ac:local-id="ID_TD3"><p local-id="ID_P3"><code>EXAMPLE_NAME</code></p></td>
  <td ac:local-id="ID_TD4"><p local-id="ID_P4">FLAKY_WHERE</p></td>
  <td ac:local-id="ID_TD5"><p local-id="ID_P5">NOTES_CONTENT</p></td>
  <td ac:local-id="ID_TD6"><p local-id="ID_P6">PIPELINE_CONTENT</p></td>
  <td ac:local-id="ID_TD7"><p local-id="ID_P7" /></td>
  <td ac:local-id="ID_TD8"><p local-id="ID_P8" /></td>
  <td ac:local-id="ID_TD9"><p local-id="ID_P9"><time datetime="TODAY_DATE" local-id="ID_P10" /></p></td>
  <td ac:local-id="ID_TD10"><p local-id="ID_P11"><ac:link><ri:user ri:account-id="ACCOUNT_ID" ri:local-id="ID_UUID_EXTRA" /></ac:link></p></td>
  <td ac:local-id="ID_TD11"><p local-id="ID_P12">Reported</p></td>
</tr>
```

**Column substitution rules:**

| Column | Placeholder | Value |
|--------|-------------|-------|
| 1 — File path | `FILE_PATH` | Path only (no line number) inside `<code>` |
| 2 — Line number | `LINE_NUMBER` | Numeric line number |
| 3 — Failed example | `EXAMPLE_NAME` | Exact example name from reading the spec; inside `<code>` |
| 4 — Flaky where | `FLAKY_WHERE` | `CI`, `Local`, or `Both` |
| 5 — Notes | `NOTES_CONTENT` | Composed in Step 5; can be a mix of text and `<code>` elements. If empty: `<p local-id="ID_P5" />` instead |
| 6 — Pipeline | `PIPELINE_CONTENT` | `<a href="CI_URL">CI_URL</a>` if URL given; `<p local-id="ID_P6" />` if `none` |
| 7 — Jira issue | (empty) | Always `<p local-id="ID_P7" />` |
| 8 — MR | (empty) | Always `<p local-id="ID_P8" />` |
| 9 — Date added | `TODAY_DATE` | YYYY-MM-DD from `date +%Y-%m-%d` |
| 10 — Added by | `ACCOUNT_ID` | From Step 1 |
| 11 — Status | (fixed) | Always `Reported` |

> **Note:** The `ri:local-id` on the `<ri:user>` element needs its own unique UUID — include it as one of the 25 generated above.

### 8. Show the row to the user for approval

Display a human-readable summary of what will be written:

```
About to add a new row to the Flaky Tests Hub:

- File: <path>:<line>
- Example: <example name>
- Flaky where: <CI/Local/Both>
- Notes: <composed notes or "(none)">
- Pipeline: <URL or "(none)">
- Date: <today>
- Status: Reported

Shall I proceed?
```

Wait for explicit confirmation before writing anything.

### 9. Insert the row into the page

Write a Python script that inserts the new `<tr>` immediately before the closing `</tbody></table>` tag. Use a heredoc to pass the row HTML safely.

```bash
python3 - <<'PYEOF'
new_row = """<NEW_TR_HTML>"""

with open('/tmp/flaky-hub.html', 'r') as f:
    content = f.read()

marker = '</tbody></table>'
count = content.count(marker)
if count != 1:
    raise ValueError(f"Expected exactly 1 occurrence of marker, found {count}")

updated = content.replace(marker, new_row + marker, 1)

with open('/tmp/flaky-hub.html', 'w') as f:
    f.write(updated)

print("Row inserted successfully")
PYEOF
```

Verify the insertion by checking for a unique attribute from your new row:

```bash
grep -c "ID_ROW" /tmp/flaky-hub.html
# Expected: 1
```

### 10. Push the update

**Primary — use `confluence-cli`:**

```bash
# Sanity check: file is non-empty and starts with valid storage HTML
head -c 200 /tmp/flaky-hub.html

# Push the update
confluence-cli update 2378039297 -f /tmp/flaky-hub.html --format storage
```

Report the new version number to the user and confirm the row was added.

**Fallback — if `confluence-cli` is unavailable**, construct the full updated storage body in memory (with the new `<tr>` appended before `</tbody></table>`), then:

```
mcp__atlassian__updateConfluencePage(
  pageId: "2378039297",
  title: "CPOMS StudentSafe Flaky Tests Hub",
  contentFormat: "storage",
  content: "<updated storage body>",
  version: <version_from_step_6 + 1>
)
```

---

## Important notes

- Always use `--format storage` on `confluence-cli update` — the page uses Confluence storage format (XHTML), not markdown.
- Never hold the full storage HTML in memory when using `confluence-cli` — always read from and write to `/tmp/flaky-hub.html`.
- Leave Jira issue and MR cells **empty** on initial entry. They get filled in later by the `triage-flaky-tests` skill.
- The `Status` column is always `Reported` on first entry.
- If the user provides multiple flaky tests in one conversation, run all steps for the first test completely before asking about the next. The file `/tmp/flaky-hub.html` will already contain the previous row — just append another row in a subsequent run of Steps 7–10.
