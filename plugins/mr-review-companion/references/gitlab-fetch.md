# GitLab fetch, primary, fallback, and Jira enrichment

This reference is loaded by `mr-review-companion` during Step 3. It lists the exact tool calls and shell commands used to gather everything the HTML page needs. Read it once at the start of fetching; do not re-read on every call.

## What to fetch

For a single MR URL `https://<host>/<group>/<project>/-/merge_requests/<IID>`:

1. MR metadata, title, description, branches, author, reviewers, pipeline status, approvals, stat counters, coverage (may be null)
2. Per-file unified diffs, old_path, new_path, raw diff string, flags for new / renamed / deleted / binary
3. Discussion threads, only used to derive a "review state" pill on the Summary banner (open / changes requested / approved). Skip the full thread view; the page is not a thread renderer.
4. Jira keys referenced in the MR title or description, regex `[A-Z][A-Z0-9_]+-[0-9]+`

## Primary path, GitLab MCP

The GitLab MCP server is the preferred source because its responses are structured JSON and you can request only the fields you need.

Use ToolSearch first to load the schemas you need (the MCP tools are deferred):

```
ToolSearch query="select:mcp__gitlab__get_merge_request,mcp__gitlab__get_merge_request_diffs,mcp__gitlab__mr_discussions"
```

Then call:

```
mcp__gitlab__get_merge_request
  project_id:        URL-encoded "group/subgroup/repo" (for example "acme%2Fcpoms%2Fcpoms")
                     OR the numeric project ID if you have it
  merge_request_iid: the IID integer (the trailing number from the URL)
```

Returns: title, description, source_branch, target_branch, author, assignees, reviewers, state, merged_at, pipeline (status, coverage), approvals.approved_by[], web_url, diff_stats.

```
mcp__gitlab__get_merge_request_diffs
  project_id, merge_request_iid
```

Returns an array. Each entry has:

- `old_path` / `new_path`
- `diff`, the raw unified-diff string. Embed this verbatim in the inline JS `diffs` object (subject to the binary-file and size-cap rules in html-template.md).
- `new_file` / `renamed_file` / `deleted_file` (booleans)
- `a_mode` / `b_mode`

A diff string that starts with `Binary files ` is GitLab's binary marker. Do not feed it to the inline renderer; the html-template reference's "Binary file card" pattern handles it.

```
mcp__gitlab__mr_discussions
  project_id, merge_request_iid
```

Returns thread objects with `notes[]`. Each note has `author.name`, `body`, `resolved`, `system`. To derive a single review-state pill:

- All threads resolved AND at least one approval -> green "approved"
- Any unresolved thread -> amber "changes requested"
- Otherwise -> grey "open"

System notes are state-change records; skip them when reasoning about review state.

### Encoding the project_id

If the URL is `https://gitlab.com/acme/cpoms/cpoms/-/merge_requests/4830`:

- Path segment: `acme/cpoms/cpoms`
- URL-encoded form: `acme%2Fcpoms%2Fcpoms`

Both forms are accepted by the MCP server. Use the encoded form to avoid path-collapsing bugs on some MCP versions.

## Fallback path, glab CLI

If the GitLab MCP server is unavailable, fall back to `glab`. Check `which glab` first; if it is missing, the user needs to install it (`brew install glab` on macOS); surface that as the abort message.

```bash
# MR metadata as JSON
glab mr view <IID> --output json

# Raw unified diffs (multi-file)
glab mr diff <IID>

# Discussion notes (flat list, no thread structure)
glab mr view <IID> --comments

# Cross-repo invocation when cwd is not the MR's project
glab mr view <IID> -R <group>/<project> --output json
glab mr diff <IID> -R <group>/<project>
```

The output of `glab mr diff` is a raw multi-file unified diff. Split on `^diff --git a/(.+) b/(.+)$` header lines to get per-file diffs. Reconstruct the `old_path` / `new_path` from the header. The `Binary files ... differ` marker still applies; treat such files as binary.

The `glab mr view --output json` payload maps cleanly to the MCP fields: `pipeline.status`, `pipeline.coverage` (often `null`), `approvals.approved_by`, `diff_stats.additions`, `diff_stats.deletions`. When `coverage` is null or missing, omit the Coverage KPI card from the Summary tab as the html-template reference describes.

## Jira enrichment, best effort

Detect Jira keys in the MR title and description with the regex `[A-Z][A-Z0-9_]+-[0-9]+`. Jira instance keys are usually 2-6 uppercase letters but allow more for projects with longer prefixes.

For each unique key:

1. Try the Atlassian MCP. Load with `ToolSearch query="select:mcp__plugin_atlassian_atlassian__getAccessibleAtlassianResources,mcp__plugin_atlassian_atlassian__getJiraIssue"`. Get the `cloudId` once via `mcp__plugin_atlassian_atlassian__getAccessibleAtlassianResources`, then call `mcp__plugin_atlassian_atlassian__getJiraIssue({ cloudId, issueIdOrKey: "ABC-123" })`. Returns `fields.summary`, `fields.status.name`, `fields.priority.name`, `fields.assignee.displayName`. Also returns the Jira host (`self` field) which you can reuse to build the user-facing link.
2. If MCP unavailable, try `acli jira issue view <KEY> --json`.
3. If both fail AND the Jira host is unknown, do NOT render an `<a>` element. Render the key as a plain span with the same `ext-link` class for visual parity, then add the amber `jira-unavailable` pill once in the banner. The exact markup is:

   ```html
   <span class="ext-link no-href">JIRA-KEY</span>
   ```

   And once in the banner (only if any key failed):

   ```html
   <span class="pill amber" title="Jira lookup failed; keys shown as plain text">jira-unavailable</span>
   ```

4. If both fail but the Jira host IS known (for example from a previous link in the description, or from earlier session context), render the link as a real `<a>` to `https://<host>/browse/<KEY>` and still add the `jira-unavailable` pill so the reader knows ticket metadata is missing.

The Jira host is usually inferable from a previous link in the MR description, or from the user's prior context. If unknown, prefer the no-href span above; never emit `<a href="">` or a relative URL because both behave unpredictably on file:// pages.

## Branch auto-detect, do not use

Never auto-pick an MR from the current source branch. A branch can have multiple open MRs (after a rebase and force-push, after a fork, after a chain of stacked MRs), and the wrong-MR failure mode is silent: the page renders, looks plausible, and only the IID in the banner gives the mistake away. Always require the user to paste a URL.

## Abort criteria

Abort the run, naming both sources verbatim, only when:

- GitLab MCP is unreachable AND `glab` is missing or returns non-zero
- The MR returns 404 or 401/403 from both sources
- The MR exists but has zero diff entries (empty MR, nothing to render)

For any other failure, degrade gracefully with a pill in the banner.
