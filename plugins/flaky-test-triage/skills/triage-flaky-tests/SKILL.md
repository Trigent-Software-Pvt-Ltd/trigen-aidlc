---
name: triage-flaky-tests
description: "Create AI project Jira Bug tickets for untriaged flaky tests from the CPOMS StudentSafe Flaky Tests Hub Confluence page, then update the page with Jira links."
allowed-tools: [Bash, AskUserQuestion, Read, Glob, Grep, mcp__atlassian__getConfluencePage, mcp__atlassian__updateConfluencePage, mcp__atlassian__createJiraIssue]
---

You are triaging flaky tests from the CPOMS StudentSafe Flaky Tests Hub into Jira.

## Fixed defaults (do not prompt the user for these)

- **Atlassian cloud ID**: `trigent1.atlassian.net`
- **Jira project**: `AI`
- **Issue type**: `Bug`
- **Priority**: `P4`
- **Component**: `StudentSafe` (component ID `11683`)
- **Label**: `flaky-test`
- **Found By field** (`customfield_10331`): `{"id": "10733"}` (Engineering Team (Dev/QA))
- **Confluence page ID**: `2378039297` (CPOMS StudentSafe Flaky Tests Hub)
- **Jira server ID** (for storage-format smart links): `a77f5e5b-8553-3edd-a5a6-015dfb61cdab`

## Prerequisites

Check both CLI tools before proceeding. For each one that is missing, tell the user and
offer to continue with MCP instead — do not halt the skill unless the user asks to.

### jira-cli

```bash
which jira
```

If not found:

---
`jira-cli` is not installed. It is the preferred method for creating tickets (lower cost than MCP).

To install and set it up:

**1. Install** (macOS):
```bash
brew tap ankitpokhrel/jira-cli
brew install jira-cli
```
Other platforms: https://github.com/ankitpokhrel/jira-cli/wiki/Installation

**2. Set your Jira API token** in `~/.zshrc` (or `~/.bashrc`):
```bash
export JIRA_API_TOKEN="your-token-here"
```
Generate a token at: https://id.atlassian.com/manage-profile/security/api-tokens

**3. Initialise the CLI** — when prompted, select the **AI** project and **Kanban Space board**:
```bash
jira init
```

Once set up, restart your shell (or `source ~/.zshrc`) and re-run the skill.
Alternatively, continue now and MCP `createJiraIssue` will be used instead.

---

### confluence-cli

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

### 1. Fetch the Confluence page

**Primary — use `confluence-cli`:**

Run all of these now:

```bash
# For table parsing — hold this output in memory
confluence-cli read 2378039297 --format markdown

# Save storage HTML to a clean working file; capture version from stdout
confluence-cli edit 2378039297 -o /tmp/flaky-hub.html 2>&1 | tee /tmp/flaky-hub-meta.txt
grep -E '^Version:' /tmp/flaky-hub-meta.txt
```

> **Important:** The `-o` flag writes the storage HTML directly to the file with no metadata
> header. The working file `/tmp/flaky-hub.html` is the source of truth for all storage edits
> — do NOT hold storage HTML in memory.

Hold the markdown output and the version number in memory for the rest of the session.
Do not fetch the page again.

**Fallback — if `confluence-cli` is unavailable**, use MCP:

```
getConfluencePage: pageId=2378039297, contentFormat=markdown
getConfluencePage: pageId=2378039297, contentFormat=adf
```

Hold both results and the version number from the ADF response.

### 2. Identify untriaged rows

Identify untriaged rows from the storage HTML (`/tmp/flaky-hub.html`), **not** the markdown.

A row is **triaged** if its Jira issue `<td>` contains **either** of these patterns:

1. A Jira smart-link macro: `ac:name="jira"` (added by this skill or the Confluence editor)
2. A plain HTML anchor to an AI issue: `atlassian.net/browse/AI-` (added manually)

Use this check for each row's Jira cell:

```python
import re

def is_triaged(jira_td: str) -> bool:
    has_macro = 'ac:name="jira"' in jira_td
    has_anchor = bool(re.search(r'atlassian\.net/browse/AI-\d+', jira_td))
    return has_macro or has_anchor
```

A row is untriaged only if **neither** pattern is present.

> **Important:** The markdown output silently strips Jira smart-link macros — cells containing
> AI keys render as blank, causing already-triaged rows to appear untriaged. Use
> `/tmp/flaky-hub.html` as the source of truth for triage status. Use the markdown only for
> reading human-readable cell content (file paths, example names, notes).

### 3. For each untriaged row, draft and create a ticket

**Process one row at a time.** Do not read ahead, batch drafts, or ask about more than one
ticket simultaneously. Complete all of steps a–e for the current row before moving to the next.

For each untriaged row (one at a time):

a. **Read the spec file** from the repository at the path and line number given in the table.
   Read enough context (at least 40 lines either side) to understand what the test does.

b. **Draft the ticket** using the format below. Do NOT suggest a root cause or fix in the
   description — describe the test scenario and interactions objectively.

c. **Show the draft to the user and ask for approval** before creating anything.
   Present only this one ticket. Wait for explicit confirmation before proceeding.

d. On approval, **create the Jira issue**.

   **Primary — use `jira-cli` via Bash:**

   ```bash
   cat > /tmp/flaky-description.md << 'EOF'
   <description content>
   EOF

   zsh -c 'source ~/.zshrc && jira issue create \
     -pAI \
     -tBug \
     -s"Flaky spec: <exact failed example name>" \
     --template /tmp/flaky-description.md \
     -yP4 \
     -CStudentSafe \
     -lflaky-test \
     --custom "found-by?=Engineering Team (Dev/QA)" \
     --no-input \
     --raw'
   ```

   Parse the JSON output for the `key` field (e.g. `AI-123`).

   **Fallback — if `jira-cli` is unavailable**, use MCP `createJiraIssue`:
   ```
   cloudId: trigent1.atlassian.net
   projectKey: AI
   issueTypeName: Bug
   contentFormat: markdown
   additional_fields: {
     "priority": {"name": "P4"},
     "labels": ["flaky-test"],
     "components": [{"id": "11683"}],
     "customfield_10331": {"id": "10733"}
   }
   ```

e. Record the created Jira key. Update the page for this row's Jira issue column —
   the method depends on which Confluence path is active:

   **If using `confluence-cli` (storage format):**

   Make a targeted in-place replacement on the working file. Confluence storage tables include
   `ac:local-id` attributes on each `<td>` — use the target cell's `ac:local-id` (or another
   unique attribute on that row) to scope the pattern to exactly one cell.

   ```bash
   # 1. Verify the empty target cell is present and unambiguous before touching anything
   #    Replace <unique-marker> with the ac:local-id or other distinguishing attribute of
   #    the target row/cell found by inspecting /tmp/flaky-hub.html
   grep -c '<unique-marker>' /tmp/flaky-hub.html
   # Expected: exactly 1. If 0 or >1, stop and investigate before proceeding.

   # 2. Replace just the empty Jira cell with the Jira smart-link macro
   #    Scope the pattern tightly so only the correct empty cell is matched.
   sed -i '' 's|<empty-cell-pattern>|<p><ac:structured-macro ac:name="jira" ac:schema-version="1"><ac:parameter ac:name="key">AI-XXX</ac:parameter><ac:parameter ac:name="serverId">a77f5e5b-8553-3edd-a5a6-015dfb61cdab</ac:parameter><ac:parameter ac:name="server">System Jira</ac:parameter></ac:structured-macro> </p>|' /tmp/flaky-hub.html

   # 3. Verify the replacement landed
   grep -c 'AI-XXX' /tmp/flaky-hub.html
   # Expected: 1 (or cumulative count matching tickets created so far)
   ```

   Do not rewrite the whole file from memory — only the target cell changes.

   **If using MCP (ADF format):**
   ```json
   {
     "type": "paragraph",
     "content": [
       {
         "type": "inlineCard",
         "attrs": { "url": "https://trigent1.atlassian.net/browse/AI-XXX" }
       },
       { "type": "text", "text": " " }
     ]
   }
   ```

   Do not write to Confluence yet — continue to the next row.

f. **Only then**, move to the next untriaged row and repeat from step a.

### 4. Update the Confluence page (once, after all tickets are created)

**Primary — use `confluence-cli`:**

The working file `/tmp/flaky-hub.html` already contains all replacements from Step 3e.
Sanity-check it, then push:

```bash
# Confirm the file is non-empty and starts with valid storage HTML
head -c 200 /tmp/flaky-hub.html

# Push the update
confluence-cli update 2378039297 --file /tmp/flaky-hub.html --format storage
```

**Fallback — if `confluence-cli` is unavailable**, use MCP `updateConfluencePage` once with
the final in-memory ADF body, `contentFormat: adf`, and the version number from step 1.

---

## Description format

Use this exact structure for every ticket description.
All URLs must use explicit markdown link syntax `[text](url)` — never bare URLs.

```
*Spec file:* <path> (line <N>)
*Shared example:* <name and context line, if the test uses a shared example — omit if not>

*Failed example:*
<exact example name from the Confluence table>

*Flaky where:* <CI / Local / Both>

*Notes:* <objective notes only — see filtering rules below>

*Test scenario:*
<Numbered steps describing what the test does, derived from reading the spec.
Be objective — do not suggest causes or fixes.>

*Interactions involved:* <comma-separated list of relevant interactions, e.g. AJAX,
file upload, select2, JavaScript DOM manipulation, database record creation, etc.>

*Current behaviour:* Spec intermittently fails <in CI / locally / in CI and locally>.
*Expected behaviour:* Spec passes consistently on every run.

*Example pipeline failure:* [<url>](<url>)
```

Omit the `*Example pipeline failure:*` line entirely if none is available in the table.

---

## Notes field filtering rules

The Confluence Notes column is written informally by engineers and must be filtered before
inclusion in the ticket. Its purpose in the ticket is solely to record **factual context
about associated code changes** — nothing else.

**Include only:**
- References to specific commits, PRs, or merge requests (e.g. "Introduced around MR !1234")
- References to deploys or releases (e.g. "Started failing after deploy on 2024-03-15")
- References to specific code changes by file or feature (e.g. "Related to registry refactor in PR !567")

**Exclude entirely:**
- Editorial opinions or frustration (e.g. "Oh lord, not the damn registry again")
- Speculation or theories about causes (e.g. "probably a timing issue", "might be JS")
- Vague or uninformative notes (e.g. "still happening", "no idea")
- Any language that attributes blame or suggests a root cause

**If the notes contain no factual content after filtering**, use `"No associated code change."`

**If the notes contain a mix**, extract only the factual parts and discard the rest.
Do not paraphrase or editorialize — use the factual content verbatim or omit it.

---

## Summary format

```
Flaky spec: <exact failed example name from the Confluence table>
```
