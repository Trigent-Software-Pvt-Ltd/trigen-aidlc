---
name: mr-review-companion
description: "Build a single self-contained HTML review companion for a GitLab merge request. Exactly three tabs: a plain-language Summary for a non-technical reader, with a rollback plan when the MR has migrations; a Diff tab with individually collapsible per-file changes and a 'what changed and why' note naming each change's blast radius; and a QA tab written in plain user-action language (no code identifiers, no spec names) giving each changed area an automated-coverage verdict and checkbox checklists so QA only chases what the automated suite misses. One HTML file, all CSS and JS inline, no CDN, opens via file://. Use this skill whenever the user wants to build or share an HTML page for reviewing a merge request, QA-ing an MR, or briefing a non-technical reader on one. Triggers: /mr-review-companion, 'review companion', 'MR review HTML', 'review page for this MR', 'QA companion', 'explain this MR to my PM', or a GitLab MR URL paired with 'html', 'review', or 'QA'."
allowed-tools: [Bash, Read, Grep, Glob, Write, Edit, AskUserQuestion, ToolSearch, mcp__gitlab__get_merge_request, mcp__gitlab__get_merge_request_diffs, mcp__gitlab__mr_discussions, mcp__plugin_atlassian_atlassian__getAccessibleAtlassianResources, mcp__plugin_atlassian_atlassian__getJiraIssue]
argument-hint: "<GitLab MR URL>"
---

# mr-review-companion

Build a single self-contained HTML page that helps a reviewer, a non-technical stakeholder, and a QA engineer all use the same artifact to understand one GitLab merge request.

The page has three tabs and only three tabs. Each tab serves a different audience.

## References at a glance

| File | Purpose |
|------|---------|
| `references/gitlab-fetch.md` | MCP and `glab` call shapes; Jira enrichment; abort criteria |
| `references/html-template.md` | HTML skeleton, palette, inline-JS contract, shell-dangerous placeholder rule |
| `references/qa-coverage-discovery.md` | Partition rules, three coverage passes, verdict pills, degraded-mode behaviour |
| `references/summary-tone.md` | Audience definition, banned phrases, worked examples for Summary tab prose |

Invocation forms: `/mr-review-companion:mr-review-companion` (canonical, namespaced) or `/mr-review-companion` (short form; works because the skill name matches the plugin name).

| Tab | Audience | What it answers |
|-----|----------|-----------------|
| Summary | Non-technical reader | What does this change do? Why does it matter? What changes for users? |
| Diff | Reviewer / developer | What lines changed in each file, and why? |
| QA | QA engineer | Which changes are already covered by automated tests, and which are not? Where should manual testing concentrate? |

The QA tab is the load-bearing differentiator. It is written entirely in plain user-action language - no code identifiers, no spec file names, no unit-test jargon. Under the hood it works out, for each changed area, whether the automated suite already exercises it and gives each one a verdict (automated / partly automated / not automated / unknown), but the reader only ever sees what to click and what to look for. The reviewer can then say: "the automated suite already covers X, so QA only needs to look at Y."

## When to use this skill

- The user pastes a GitLab MR URL and asks for an HTML, review page, companion, or QA page
- The user types `/mr-review-companion`
- The user is preparing to brief a non-technical reader on an MR
- The user wants to hand a QA engineer a focused list of "test these, don't test those"

Do not use this skill for: writing the actual code review opinion in chat, summarising the MR verbally, fetching code review comments alone, or non-GitLab providers (GitHub PRs, Bitbucket pull requests, Azure DevOps PRs).

## Inputs

The only input is a GitLab merge request URL of the form `https://<gitlab-host>/<group>/<project>/-/merge_requests/<IID>`. If the user types a bang-prefixed IID (for example `!4830`) without a URL, ask for the full URL because IIDs alone are ambiguous across forks and groups.

If the user runs the skill from inside a clone of the MR's project, the QA tab is enriched by reading local test files. If they are not, the skill still works; the QA tab degrades to "no local repo, test discovery skipped" with an explanation.

## End-to-end flow

Execute these steps in order.

### Step 1: Get the MR URL and verify host

If the user already pasted a URL, use it. Otherwise ask for it. Do not auto-detect from the current branch because implicit input leads to the wrong MR being rendered when the user has multiple in flight.

If the URL host is not GitLab (for example github.com, bitbucket.org, dev.azure.com), decline politely and stop:

> "This skill only handles GitLab merge requests. For GitHub PRs or Bitbucket pull requests, that needs a different tool; let me know and we can plan a separate approach."

Heuristic for "is this GitLab": the path contains `/-/merge_requests/`. GitHub PRs use `/pull/<n>`, Bitbucket uses `/pull-requests/<n>`, Azure DevOps uses `/_git/<repo>/pullrequest/<n>`. Reject all of those.

### Step 2: Detect whether the local cwd matches the MR's project

Run `git remote get-url origin` and `git rev-parse --show-toplevel`. Parse the project path from the remote (strip a trailing `.git`, strip leading `git@host:` or `https://host/`, strip a trailing slash). Lower-case both sides and compare as exact strings. If the user's clone is a fork (origin in their personal namespace), also try `git remote get-url upstream` before declaring a mismatch.

- **Match:** record `local_repo_available = true` and remember the toplevel path. The QA tab will read local test files.
- **Mismatch or not in a git repo:** record `local_repo_available = false`. Do NOT abort. The page still renders; the QA tab shows a banner explaining that test discovery was skipped because the cwd is not the MR's project.

The Summary and Diff tabs do not need local files, so a cwd mismatch is never a reason to abort. Only the QA tab depends on the local repo, and it degrades cleanly. See `{{SKILL_DIR}}/../../references/qa-coverage-discovery.md` "Short-circuit: local repo not available" for the canonical degraded-mode behaviour.

### Step 3: Fetch the MR

Read `{{SKILL_DIR}}/../../references/gitlab-fetch.md` for exact call shapes. The primary path is the GitLab MCP server; the fallback is the `glab` CLI. Fetch:

- MR metadata (title, description, branches, author, pipeline status, approvals, stats, coverage if present)
- Per-file unified diffs
- Discussion threads (optional, only used on the Summary tab as a one-line "review state" pill; the page is not a thread viewer)
- Jira tickets referenced in the title or description (graceful degrade if Atlassian unavailable)

Cache the fetched payload in working memory. Later regenerate-tab loops should reuse this cache rather than re-fetch unless the user explicitly asks to refetch.

Abort only when one of these is true; name the attempted sources verbatim in the abort message:

- Both GitLab MCP and `glab` fail or are unavailable
- The MR returns 404 / access-denied from both sources
- The MR exists but has zero diff entries (nothing to render)

For any other transient failure, degrade gracefully with a banner pill (see Failure modes section).

### Step 4: Build the Summary tab content

Read `{{SKILL_DIR}}/../../references/summary-tone.md` before writing a single word of summary prose. The Summary tab is written for a reader who does not read code, a PM, a stakeholder, a manager who wants to know what is shipping. Jargon and identifier names break this audience.

The Summary tab contains:

1. A two-to-four sentence lede that names the change in plain English. Lead with what users will notice (or "no user-visible change" if it is internal). Mention the area of the product, not class names.
2. A short bullet list of "what this change does" in user-facing terms.
3. A short bullet list of "what this change does not do". The negatives matter because non-technical readers often imagine more change than is actually shipping. Examples: "Does not change pricing", "Does not migrate any data", "Does not affect existing users".
4. A small KPI strip with files-changed / lines-added / lines-removed / pipeline status / approvals. These are factual, not jargon, and useful for stakeholders. Coverage is a sixth KPI but only when GitLab returns a non-null value (see html-template reference for the conditional rendering rule).
5. The MR's linked Jira tickets and pipeline link as plain clickable links.

Tone rules live in the summary-tone reference. The key one: never use a code identifier inside the Summary tab. If you cannot say it without using a class or method name, it belongs in the Diff tab.

**Conditional rollback block (migrations only).** If the MR diff includes any migration files (paths matching `db/migrate/`, `Migrations/`, `migrations/`, or `*.sql` under `schema/` or `migrations/`), add a **Rollback** section to the Summary tab. The rollback section lists the concrete steps to revert: revert the MR commit, roll back the migration, and any data backfill, feature-flag flip, or cross-service coordination needed. If a revert is clean and requires no extra steps, say so explicitly. This section is for developers, not QA - keep it brief and factual. It is the one place the Summary tab may name a concrete command (for example `rails db:rollback` inside a `<code>` span); the summary-tone "No identifier in the prose" rule has an explicit carve-out for it. Every other part of the Summary tab stays identifier-free. Omit this section entirely when the MR has no migration files. See `{{SKILL_DIR}}/../../references/html-template.md` for the exact HTML shape.

### Step 5: Build the Diff tab content

The Diff tab has one card per changed file. Each card has:

- The full file path as the heading
- A short "what changed and why" paragraph that names specific identifiers (functions, constants, methods). This is the opposite tone from the Summary tab. Where the changed identifier is used by other code in the same file or called from elsewhere, note that in the WHY block - help the reviewer understand the blast radius, not just what one line does in isolation.
- The raw unified diff coloured for adds, deletes, hunk markers, and context

Read `{{SKILL_DIR}}/../../references/html-template.md` for the exact HTML shape, palette, and inline-JS contract for rendering diffs.

Two sizing rules from that reference are worth surfacing here so they are not missed:

- **Binary files.** GitLab returns binary file diffs as a single line, for example `Binary files a/foo.png and b/foo.png differ`. Detect these and render a placeholder card (file path heading, a one-line "binary file, no inline diff available, view in GitLab" note linking to the file in GitLab) instead of feeding the inline JS renderer. The html-template reference shows the placeholder pattern.
- **Very large diffs.** If a single file's unified diff exceeds 2000 lines, truncate it. Embed the first 1500 lines and the last 200 lines in the JS payload, separated by a `... <N lines elided, view full file in GitLab> ...` marker. Avoid bloating the HTML for one giant generated file.

The cards must be grouped sensibly: production code first, tests next, then config / migrations / data files / docs / generated files. Within each group, sort by depth (top-level files before deep paths) so the eye lands on the most important change first. Use `<h2>` group headings inside the Diff tab. The page still has only three top-level tabs.

Every group is wrapped in a `<details>` accordion so the user can collapse noisy sections. Default `open` state by file count:

- 30 or fewer total changed files: every group opens by default (`<details open>`).
- More than 30 total changed files: only the first group (Production code) opens by default; the rest start collapsed so the page is scrollable.

### Step 6: Build the QA tab content

This is the differentiator. The QA tab is written for a QA engineer who clicks through the product - it must contain zero code identifiers, zero spec file names, and zero unit-test language. Every item must read as a user action: what to click, what to look for.

Read `{{SKILL_DIR}}/../../references/qa-coverage-discovery.md` for the full algorithm. The high-level shape:

1. Partition the changed files into `production` (runtime code) and `non-production` (tests, fixtures, migrations, settings data, docs, lockfiles, generated). The reference has the exact rules. Note that `config/application.rb`, `config/environments/*.rb`, and `config/routes.rb` are `production` because they hold runtime behaviour.
2. For each `production` file, run three passes in order and stop at the first positive verdict (see the reference for details):
   - **Same-MR diff check:** scan the MR's own diff for a test file that references the changed identifiers. Runs even without a local repo.
   - **Path-mirror lookup (requires local repo):** find candidate test files by language-specific path conventions.
   - **Symbol grep (requires local repo):** grep the wider test directory for the changed identifier.
3. Decide a verdict: **Automated** (positive pass found), **Partly automated** (a test file exists but does not reference the changed code path), **Not automated** (nothing references it), **Unknown** (no same-MR test AND `local_repo_available = false`).
4. Render a three-column table: `What changed (in plain terms) | Automated coverage | What QA still needs to verify`.
   - "What changed" describes the user-visible area or action - no file paths, no class names, no Ruby identifiers. Example: "The page that lets admins revoke staff access in bulk."
   - "Automated coverage" is the verdict pill.
   - "What QA still needs to verify" is blank for Automated rows; a user-action sentence for Partly automated / Not automated rows; "Verify this area manually - automated coverage could not be determined." for Unknown rows.
5. Below the table, render two checklist sections (HTML checkboxes, not plain bullets - see html-template reference):
   - **What you need to check** - one checkbox per non-blank "what to verify" entry from the table, verbatim.
   - **Manual QA focus** - deduplicated, thematic version of the above.
6. Render a single **Risk** sentence: the most likely regression in user-visible terms. No rollback statement in the QA tab (when the MR has migrations, rollback belongs in the Summary tab - see Step 4).

When `local_repo_available = false`, the table still has real verdicts for any production file the same-MR diff check covers; only the remaining files fall back to `unknown`. The qa-coverage-discovery reference describes the degraded banner text and how the checklists render in this mode.

The verdicts use coloured pills: green for Automated, amber for Partly automated, red for Not automated, grey for Unknown. Pills are defined in the html-template reference.

### Step 7: Write the HTML file

Use the Write tool to save the file at:

- If `local_repo_available`: `<git toplevel>/mr-<IID>-review.html` (the path from `git rev-parse --show-toplevel` in Step 2)
- Otherwise: `~/mr-<IID>-review.html`

Do not write to `/tmp` because these files often get shared and need a stable home. No Python, no shell scripts, no template engines. Write the HTML directly. All CSS in one `<style>` block in `<head>`. All JS in one `<script>` block at the end of `<body>`. No external resources whatsoever. The self-contained checklist in the html-template reference lists every forbidden pattern.

### Step 7.5: Verify the written file

After writing, use the `Read` and `Grep` tools (read-only; no shell scripts, no `node`) to verify the file is structurally sound. Fail loudly if any check fails - do not proceed to Step 8. Instead, identify the specific problem, fix it with `Edit` (or regenerate the affected section), then re-run all checks.

What this step does and does not guarantee: because it is Read/Grep only (no `node` by design), it detects HTML breakout sequences and unresolved placeholders - the failure modes that silently break tab switching and diff rendering. It does **not** parse the embedded JavaScript, so it cannot guarantee the inline script is syntactically valid. A hand-encoding slip that produces a syntactically broken-but-non-breakout script (for example a dropped backslash leaving an unterminated string literal) will pass these checks. Treat the checks as a breakout-and-placeholder gate, not a JS validator.

Checks to run:

1. **Exactly one outer `<script>` block.** Use `Grep` (content mode, not line-count) to find every `<script` and `</script>` occurrence and confirm there is exactly one opening and one closing tag. Note that line-based counting under-reports when two tags share a line (for example `</script><script`), so Check 2 below is the authoritative breakout detector; this check is a fast sanity pass. If the tags are not balanced 1:1, the diff payload contains unescaped angle brackets - fix the inline script by ensuring every `<` in the embedded strings is encoded as `\x3c`.
2. **No stray `</script` or `<script` inside the script payload (authoritative).** After confirming the single outer block, scan every embedded string value for literal `</script` or `<script` substrings - these indicate the `\x3c` encoding was not applied. This is the check that actually catches a `</script>` breakout, including the share-a-line case Check 1 misses. Fix by re-encoding those strings.
3. **No unresolved placeholders.** Use `Grep` to search the file for each of these exact placeholder tokens: `{{SKILL_DIR}}`, `<IID>`, `<N>`, `<additions>`, `<deletions>`, `<add>`, `<del>`, `<short title>`, `<author.name>`, `<source>`, `<target>`, `<mr.web_url>`, `<coverage>`, `<jira.url>`, `<JIRA-KEY>`. This is the complete set the template uses (see html-template.md); keep it in sync if the template gains a placeholder. If any match, replace with the real value. Do **not** try to catch placeholders with a generalized `<word>` pattern: an angle-bracket token is syntactically indistinguishable from a real HTML tag, so a generalized pattern matches every bare opening tag in the static markup (`<head>`, `<title>`, `<section>`, `<details>`, `<summary>`, ...) and fails on every page. The literal-token list is the only approach that catches uppercase, hyphenated, and spaced tokens (`<IID>`, `<JIRA-KEY>`, `<short title>`) without false-positiving on real tags. The tokens cannot collide with diff content because every `<` inside the inline `<script>` is already encoded as `\x3c`.
4. **Self-contained checklist passes.** Use `Grep` to confirm none of these appear in the file: `<script src`, `<link rel="stylesheet"`, `@import url(`, `url(http`, `url(//`. If any match, remove the offending line.

Only proceed to Step 8 after all four checks pass cleanly.

### Step 8: Open in browser, then loop on feedback

After the verification checks pass, offer to open the file in the browser so the user can see the page before giving feedback. Use `open <path>` on macOS, `xdg-open <path>` on Linux, `start <path>` on Windows. Do this proactively - do not wait for the user to ask. Tell the user the file path and that you have opened it (or that they can open it manually).

Then ask the user via AskUserQuestion. Each option works from the cached MR payload from Step 3 unless noted:

- "Looks good, done."
- "Regenerate one tab from cached MR data." (re-renders the chosen tab; no GitLab refetch)
- "Edit a specific section." (uses the Edit tool on the file)
- "Adjust the QA verdicts manually." (uses the Edit tool on the verdicts table)
- "Refetch from GitLab and rebuild." (use this only if the MR has changed since Step 3, for example a fresh push)

Apply edits with the Edit tool. After any edit, re-run the Step 7.5 verification checks before showing the updated result. Repeat until the user picks done.

### Step 9: Confirm file location

Once the user signals done, ask via AskUserQuestion where the file should live. Offer these options:

- "Leave it in the repo root." (already there if `local_repo_available`)
- "Move it to `docs/`." - offer this option **only** when a `docs/` directory exists at the repo top level (check with `test -d <toplevel>/docs`)
- "Save to a path I'll type."

When the user picks a destination, first check whether a file already exists there (`test -f <dest>`). If it does, and it is not the file you just wrote, name the existing file and ask the user to confirm the overwrite before proceeding - do not clobber it silently. Once clear, **move** the file there (do not copy and leave a duplicate at the original path). A move preserves the exact bytes Step 7.5 already verified, so no re-verification is needed after relocating. Never write to `/tmp`. (If you instead edit the file as part of relocating it, re-run the Step 7.5 checks afterwards.)

## Failure modes

**Hard abort, name both attempted sources verbatim:**

- GitLab MCP and `glab` both fail or both return errors for this MR
- The MR is 404 or access-denied from both sources
- The MR has zero diffs

**Polite refusal (no error tone), do not proceed:**

- The URL is not a GitLab MR URL (see Step 1)

**Graceful degrade, render a pill and continue:**

- cwd does not match the MR's project, render the QA tab with the "no local repo" banner and continue
- Atlassian MCP and `acli` both fail, render the Jira keys as bare spans with an amber `jira-unavailable` pill in the banner (see gitlab-fetch reference for the exact rendering)
- A specific test file is unreadable, log the file path inline in the QA verdict and continue
- GitLab returns `coverage: null`, omit the Coverage KPI card from the Summary tab (see html-template reference for the conditional rendering rule)

## Anti-patterns, do not do these

- Do not write a Python or shell render script. The model writes the HTML directly because that is fast, debuggable, and the only way to keep the file truly self-contained.
- Do not add a fourth tab. If something does not fit in Summary, Diff, or QA, it belongs in the Diff tab as a file card or in the QA tab as a risk row.
- Do not use code identifiers in the Summary tab. If the Summary names a class, scope, or method, the audience is wrong.
- Do not use emojis as status markers. Use the coloured pill components defined in the html-template reference. Emojis render inconsistently across font stacks and break the dark theme.
- Do not load any external CSS, JS, fonts, or images. The page must open over `file://` on a plane with no network.
- Do not write backtick-wrapped spans whose contents would expand under a shell. The canonical rule and substitutes live in the html-template reference under "Shell-dangerous placeholder rule".

## Example

A reviewer is about to brief their product manager on MR !4830 in `acme/cpoms/cpoms`. They run `/mr-review-companion`, paste the URL. The skill detects the cwd matches, fetches the MR, finds 14 changed files (9 production, 5 test). The Summary tab opens with: "This change lets head teachers see which staff still have access to the legacy tray view, and lets admins revoke that access in bulk. No data migration. No change to who can sign in." The Diff tab lists the 14 files in two groups with WHY prose naming `TRAY_ACCESS_DESCRIPTIONS`, `tray_access?`, and `IncidentTrayController#index`. The QA tab is the punchline, and it never names a file or a method. Its coverage map has one row per changed area in plain terms: most rows read "automated" with a blank "what to verify" cell, one reads "partly automated" because the tests only touch part of that behaviour, and one (the new bulk-revoke action) reads "not automated". The "what you need to check" and "Manual QA focus" checklists at the bottom carry just the user-actions QA still owns: "Open the admin area, select multiple staff, and use the bulk-revoke action - confirm only the selected records change" and "Verify the legacy tray view no longer renders for staff whose access was revoked". The reviewer drops the HTML in Slack, the PM reads the Summary tab, the QA engineer reads only the QA tab.
