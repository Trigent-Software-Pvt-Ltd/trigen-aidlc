# HTML template, three-tab dark theme, fully self-contained

This reference defines the shape, palette, and inline-JS contract for the HTML page that `mr-review-companion` writes. The skill produces one HTML file with no external resources; everything below is inline.

## A note on placeholders in this reference

Angle-bracket tokens like `<N>`, `<IID>`, `<additions>`, `<author.name>`, `<source>`, `<target>`, and `<mr.web_url>` in the examples below are placeholders to be substituted at render time. They are not literal output. Replace each one with the corresponding value before writing the HTML file, and make sure none survives into the saved file.

## File skeleton

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>MR !<IID> - <short title></title>
  <style>/* the entire palette + components, no @import, no url(http) */</style>
</head>
<body>
  <header class="banner">...</header>
  <nav class="tabs" aria-label="Sections">
    <button class="tab-btn active" data-tab="summary">Summary</button>
    <button class="tab-btn" data-tab="diff">Diff <span class="count"><N></span></button>
    <button class="tab-btn" data-tab="qa">QA <span class="count"><N></span></button>
  </nav>
  <main>
    <section id="tab-summary" class="tab-panel active">...</section>
    <section id="tab-diff" class="tab-panel">...</section>
    <section id="tab-qa" class="tab-panel">...</section>
  </main>
  <script>/* tab switching + diff colourisation, no external scripts */</script>
</body>
</html>
```

There are exactly three tab buttons. Do not add a fourth. The Diff count chip shows the number of file cards rendered (including binary-file placeholders); the QA count chip shows the number of production files in the verdict table.

## Self-contained checklist

Before saving, verify the page contains none of these:

- No `<script src=...>`
- No `<link rel="stylesheet">`
- No `<link rel="icon" href="http...">` (a `data:` URI icon is fine)
- No `@import url(...)` in CSS
- No `url(http...)` or `url(//...)` in CSS
- No remote font loads (no `@font-face` pointing at the network)
- No inline `style="..."` attributes anywhere; every style is a class in the `<style>` block
- All tables use `class="std-table"`; no hand-styled tables
- No `<a href="">` and no `<a>` with a relative href; if no real URL exists, use a `<span class="ext-link no-href">` instead

The page must open over `file://` with the browser offline and look identical.

## Banner

```html
<header class="banner">
  <h1>MR title text <span class="iid">- !<IID></span></h1>
  <div class="meta">
    <span class="label">Branch</span>
    <code class="chip"><source></code> -> <code class="chip"><target></code>
    <span class="label">Author</span> <span><author.name></span>
    <span class="label">Pipeline</span>
    <span class="pill green">passed</span>  <!-- or red "failed", amber "running", grey "none" -->
    <span class="label">Stats</span>
    <span class="pill blue"><N> files</span>
    <span class="add-stat">+<additions></span> <span class="del-stat">-<deletions></span>
    <span class="label">Review</span>
    <span class="pill green">approved</span>  <!-- or amber "changes requested", grey "open" -->
    <!-- Optional, render only when any Jira lookup failed: -->
    <span class="pill amber" title="Jira lookup failed; keys shown as plain text">jira-unavailable</span>
  </div>
  <div class="ext-line">
    <a href="<mr.web_url>" class="ext-link">GitLab MR !<IID></a>
    <!-- One element per Jira key: <a> when the host is known, <span class="ext-link no-href"> otherwise -->
    <a href="<jira.url>" class="ext-link"><JIRA-KEY></a>
  </div>
</header>
```

## Tab bar behaviour

- The tab bar is `position: sticky; top: 0;` so it stays visible while the user scrolls within a tab.
- The tab buttons are visually prominent: large hit area, readable font, and an unmistakable active state (filled background tint plus a thick accent underline). A user glancing at the page must be able to tell at a glance which tab is active.
- The active button has `.active` and the active panel has `.active`. Inactive panels are `display: none`.
- The count chips must reflect actual rendered counts. Never hardcode.

## Summary tab structure

```html
<section id="tab-summary" class="tab-panel active">
  <p class="lede">Two-to-four sentences in plain English. No identifiers. Names the area of
  the product and what users will notice.</p>

  <div class="kpi-grid">
    <div class="kpi-card"><div class="kpi-value"><N></div><div class="kpi-label">Files</div></div>
    <div class="kpi-card"><div class="kpi-value">+<add></div><div class="kpi-label">Added</div></div>
    <div class="kpi-card"><div class="kpi-value">-<del></div><div class="kpi-label">Removed</div></div>
    <!-- Coverage card is rendered only when GitLab returned a non-null pipeline.coverage value: -->
    <div class="kpi-card"><div class="kpi-value"><coverage>%</div><div class="kpi-label">Coverage</div></div>
  </div>

  <h2>What this change does</h2>
  <ul class="tight"><li>User-facing bullet</li>...</ul>

  <h2>What this change does not do</h2>
  <ul class="tight"><li>Negative bullet, the absence of change matters to non-technical readers</li>...</ul>

  <h2>Linked tickets</h2>
  <ul class="tight">
    <li><a href="<jira.url>" class="ext-link"><JIRA-KEY></a> - ticket summary, status pill</li>
  </ul>

  <!-- Only render this block when the MR diff includes migration files
       (paths matching db/migrate/, Migrations/, migrations/, or *.sql under schema/ or migrations/).
       Omit entirely when there are no migration files. -->
  <h2>Rollback</h2>
  <p><strong>This MR includes a database migration.</strong> Steps to revert if needed:</p>
  <ol class="tight">
    <li>Revert the MR commit.</li>
    <li>Roll back the migration (for example <code>rails db:rollback</code>).</li>
    <!-- Add extra steps if the diff shows a data backfill, feature-flag flip,
         or cross-service coordination is needed. If a revert is clean, say so. -->
  </ol>
</section>
```

Tone is enforced by `references/summary-tone.md`. Do not skip reading it.

### Coverage KPI, conditional rendering

The Coverage card renders only when GitLab returns a non-null coverage value:

- `pipeline.coverage` is a number (for example `87.4`): render the card with `<coverage>%`, rounded to one decimal.
- `pipeline.coverage` is `null`, `undefined`, missing from the payload, or the project does not produce coverage: omit the card entirely. The KPI grid is `repeat(auto-fill, minmax(130px, 1fr))` so it reflows cleanly.

Never render `null%` or `undefined%`.

## Diff tab structure

```html
<section id="tab-diff" class="tab-panel">
  <h2 class="group-heading">Production code <span class="count"><N></span></h2>

  <details open>
    <details class="file-card" open>
      <summary>app/models/permission.rb</summary>
      <article data-key="app-models-permission-rb">
        <div class="why">
          <span class="tag">WHY</span>
          New constant <code>TRAY_ACCESS_DESCRIPTIONS</code>, single source of truth so the
          controller, model scope, and API v2 service all reference the same list. The
          controller, the API v2 service, and the admin scope query all read this constant -
          all three now derive labels from one place.
        </div>
        <pre class="diff"></pre>  <!-- populated by inline JS from the diffs object -->
      </article>
    </details>
    ...
  </details>

  <h2 class="group-heading">Tests <span class="count"><N></span></h2>
  <details>
    <details class="file-card" open>
      <summary>spec/models/permission_spec.rb</summary>
      <article data-key="spec-models-permission-spec-rb">...</article>
    </details>
  </details>

  <h2 class="group-heading">Config / migrations / docs <span class="count"><N></span></h2>
  <details>
    <details class="file-card" open>
      <summary>config/routes.rb</summary>
      <article data-key="config-routes-rb">...</article>
    </details>
  </details>
</section>
```

- `data-key` goes on the `<article>`, never on the `<pre>`. The inline JS (`querySelectorAll('article[data-key]')`) finds articles nested inside `<details class="file-card">` - collapsing the file card hides the article visually but does not remove it from the DOM, so the JS populates it correctly.
- The file path is the `<summary>` of the wrapping `<details class="file-card">`, not an `<h3>` inside the article. Do not add a separate `<h3>` for the file path.
- The `data-key` is a slug of the full file path: replace `/` and `.` with `-`. Keep it deterministic, that is how the JS finds the diff string.
- WHY prose names at least one specific identifier from the diff. If you cannot name one, re-read the diff. Banned phrases live in the why-prose section below.
- Group headings use `<h2 class="group-heading">`. Group order: Production, Tests, Config/migrations/docs/generated. Each group is its own `<details>` so the page collapses cleanly for large MRs.

### Binary file card

GitLab marks binary diffs with a single payload line like `Binary files a/foo.png and b/foo.png differ`. Detect this before slugging and produce a placeholder card instead of feeding the JS renderer:

```html
<details class="file-card" open>
  <summary>assets/logo.png</summary>
  <article class="binary">
    <div class="why">
      <span class="tag">WHY</span>
      Binary file. No inline diff available.
      <a href="<mr.web_url>#diff" class="ext-link">View in GitLab</a>
    </div>
  </article>
</details>
```

No `<pre class="diff">` element. No entry in the `diffs` JS object. The card still counts toward the Diff tab count chip.

### Very large diff truncation

If a single file's unified diff exceeds 2000 lines, embed the first 1500 lines and the last 200 lines, separated by a marker line:

```
... <N lines elided, view full file in GitLab> ...
```

Make the marker visually distinct via the `.line.meta` class so it does not look like a real diff line. This protects against generated-file MRs that would otherwise inflate the HTML to tens of MBs.

## QA tab structure

```html
<section id="tab-qa" class="tab-panel">
  <!-- Only show this banner when local_repo_available is false: -->
  <div class="anchor-note">
    <strong>Running without the local codebase.</strong> Only test files added or changed
    in this MR were checked. Items already covered by those tests are marked
    <span class="pill green">automated</span>; everything else is marked
    <span class="pill grey">unknown</span> and needs manual verification. For a more
    complete picture, run the skill again from inside a checkout of this project.
  </div>

  <h2>Coverage map</h2>
  <table class="std-table">
    <thead>
      <tr><th>What changed (in plain terms)</th><th>Automated coverage</th><th>What QA still needs to verify</th></tr>
    </thead>
    <tbody>
      <tr>
        <td>The labels shown for each type of tray access (for example "View only")</td>
        <td><span class="pill green">automated</span></td>
        <td></td>
      </tr>
      <tr>
        <td>The admin page that lets admins revoke staff access in bulk</td>
        <td><span class="pill red">not automated</span></td>
        <td>Open the admin area, select multiple staff members, and use the bulk-revoke action. Confirm only the selected records change and the page shows updated access levels.</td>
      </tr>
    </tbody>
  </table>

  <h2>What you need to check</h2>
  <ul class="checklist">
    <li><label><input type="checkbox"> Open the admin area, select multiple staff members, and use the bulk-revoke action. Confirm only the selected records change and the page shows updated access levels.</label></li>
    <li><label><input type="checkbox"> Verify the legacy tray view no longer renders for staff whose access has been revoked.</label></li>
  </ul>

  <h2>Manual QA focus</h2>
  <ul class="checklist">
    <li><label><input type="checkbox"> Smoke-test the admin bulk-revoke action in staging with a real admin session.</label></li>
    <li><label><input type="checkbox"> Verify the legacy tray view no longer renders for revoked staff.</label></li>
  </ul>

  <h2>Risk</h2>
  <p><strong>What could regress:</strong> the legacy tray view is shared with two other reports. If the new scope leaks, those reports will silently drop rows.</p>
</section>
```

## Diffs inline-JS contract

All raw unified-diff strings are embedded in one inline `<script>` at the very end of `<body>`. Binary files do not appear in this object; truncated diffs include the elision marker as part of the string.

```html
<script>
(function () {
  const diffs = {
    "app-models-permission-rb": "--- a/app/models/permission.rb\n+++ b/app/models/permission.rb\n@@ -1,5 +1,8 @@\n ...",
    "app-controllers-admin-access-controller-rb": "..."
  };

  function escapeHtml(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function renderDiff(pre, raw) {
    pre.innerHTML = raw.split('\n').map(function (line) {
      var cls = line.startsWith('+++') || line.startsWith('---') ? 'meta'
              : line.startsWith('@@')  ? 'hunk'
              : line.startsWith('...') ? 'meta'
              : line.startsWith('+')   ? 'add'
              : line.startsWith('-')   ? 'del'
              : 'context';
      return '<span class="line ' + cls + '">' + escapeHtml(line) + '</span>';
    }).join('\n');
  }

  document.querySelectorAll('article[data-key]').forEach(function (article) {
    var key = article.dataset.key;
    var pre = article.querySelector('pre.diff');
    if (diffs[key] && pre) renderDiff(pre, diffs[key]);
  });

  document.querySelectorAll('.tab-btn').forEach(function (btn) {
    btn.addEventListener('click', function () {
      document.querySelectorAll('.tab-btn').forEach(function (b) { b.classList.remove('active'); });
      document.querySelectorAll('.tab-panel').forEach(function (p) { p.classList.remove('active'); });
      btn.classList.add('active');
      document.getElementById('tab-' + btn.dataset.tab).classList.add('active');
      window.scrollTo(0, 0);
    });
  });
}());
</script>
```

Escape rules, applied in this exact order:

1. **JSON-encode each string first.** This produces a valid JS string literal with quotes, backslashes, and newlines escaped.
2. **Then replace every `<` in the resulting JSON string with `\x3c`.** This neutralises `</script>`, `<script`, and `<!--` - HTML parser sequences that would cause the browser to close the inline `<script>` block early if a diff legitimately contains them (for example a diff of an HTML-escaping test). At runtime the JS evaluates `\x3c` back to `<`, so the existing `escapeHtml` call in `renderDiff` still renders the diff correctly.
3. **Then neutralise the two raw line-terminator characters JSON leaves in place:** replace U+2028 (line separator) with the six-character escape text backslash-u-2-0-2-8 and U+2029 (paragraph separator) with backslash-u-2-0-2-9. These terminate a string literal on pre-ES2019 JS engines; harmless on modern browsers but cheap to neutralise.

The order is load-bearing. If step 2 runs before step 1, the JSON pass then doubles the backslash in `\x3c` and every `<` renders as the literal text `\x3c` on the page - a silent failure with no breakout and no error. Always JSON-encode first.

Apply this rule to **every** string value embedded in the inline `<script>`, not just diff payloads.

## Why-prose tone, Diff tab only

This applies inside `<div class="why">` blocks. The Summary tab has different rules in the summary-tone reference.

1. **Name a specific identifier.** Every WHY block names at least one function, constant, method, scope, fixture, or path from the diff. If you cannot name one, the WHY is filler and the user will spot it.
2. **One idea per sentence.** Short sentences read faster than long ones during a code review.
3. **State before and after when behaviour inverts.** Bad: "The permission check was updated." Good: "The old check called `permission?(\"Manage System\")`, a string that does not exist in the permission table. The fix uses `permission?(\"Manage system\")` (lowercase s)."
4. **Bullets only for genuine sub-points.** Two to four bullets max. If the bullet would be shorter than one sentence, use a sentence instead.

5. **Note knock-on effects where relevant.** If the changed constant, method, or scope is used by other code in the same file or called from elsewhere, say so. The goal is to help the reviewer understand blast radius, not just what the changed line does in isolation.

   Bad: "Adds `tray_access?` helper to the model."
   Good: "Adds `tray_access?` helper to the model - the controller, the admin scope query, and the API v2 serialiser all call it, so all three now go through the same gate."

Banned phrases, emit none of these:

- "improves consistency"
- "as part of this change"
- "makes the code cleaner" / "cleaner code"
- "various improvements"
- "code quality" / "improves quality"
- "robustness" / "more robust"
- "This change ..." (meta-commentary opener)
- "It was decided ..." (passive deflection)
- "In order to ...", use "To ..." or state the effect directly

## Palette and CSS

Paste this into the `<style>` block. The palette is GitHub-dark-derived for low eye strain on long review sessions.

```css
:root {
  --bg: #0d1117;
  --panel: #161b22;
  --panel-2: #1f2630;
  --border: #30363d;
  --text: #e6edf3;
  --muted: #9ca3af;
  --accent: #58a6ff;
  --add-bg: rgba(46, 160, 67, .15);
  --add-fg: #aff5b4;
  --del-bg: rgba(248, 81, 73, .15);
  --del-fg: #ffdcd7;
  --hunk-bg: #1e2533;
  --hunk-fg: #79c0ff;
  --green: #3fb950;
  --red: #f85149;
  --amber: #d29922;
  --blue: #58a6ff;
  --purple: #bc8cff;
  --grey: #9ca3af;
}

*, *::before, *::after { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--text);
       font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", sans-serif;
       font-size: 14px; line-height: 1.6; }
pre, code { font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
            font-size: 12.5px; line-height: 1.5; }

/* Banner */
.banner { padding: 1.25rem 2rem;
          background: linear-gradient(135deg, var(--panel) 0%, var(--panel-2) 100%);
          border-bottom: 1px solid var(--border); }
.banner h1 { margin: 0 0 .5rem; font-size: 1.25rem; }
.banner .iid { color: var(--muted); font-weight: 400; }
.meta { display: flex; flex-wrap: wrap; gap: .5rem 1rem; align-items: center;
        font-size: .85rem; margin-bottom: .5rem; }
.label { color: var(--muted); }
.ext-line { display: flex; gap: 1rem; flex-wrap: wrap; font-size: .85rem; }
.ext-link { color: var(--accent); text-decoration: none; }
.ext-link:hover { text-decoration: underline; }
.ext-link.no-href { cursor: default; }
.ext-link.no-href:hover { text-decoration: none; }

/* Pills + chips */
.pill { display: inline-block; padding: .1em .5em; border-radius: 2em;
        font-size: .75rem; font-weight: 600; }
.pill.green { background: rgba(63,185,80,.15); color: var(--green); }
.pill.red   { background: rgba(248,81,73,.15); color: var(--red); }
.pill.amber { background: rgba(210,153,34,.15); color: var(--amber); }
.pill.blue  { background: rgba(88,166,255,.15); color: var(--blue); }
.pill.grey  { background: rgba(156,163,175,.15); color: var(--grey); }
.chip { background: var(--panel-2); border: 1px solid var(--border);
        padding: .1em .4em; border-radius: 4px; font-size: .8rem; }
.add-stat { color: var(--green); font-weight: 600; }
.del-stat { color: var(--red); font-weight: 600; }

/* Tabs */
.tabs { position: sticky; top: 0; z-index: 10; display: flex; flex-wrap: wrap;
        background: var(--panel-2); border-bottom: 1px solid var(--border);
        padding: 0 1rem; }
.tab-btn { background: none; border: none; color: var(--muted);
           padding: .9rem 1.4rem; cursor: pointer; font-size: 1rem; font-weight: 500;
           border-bottom: 3px solid transparent;
           transition: color .15s, border-color .15s, background .15s; }
.tab-btn:hover { color: var(--text); background: rgba(255,255,255,.04); }
.tab-btn.active { color: var(--accent); border-bottom-color: var(--accent);
                  background: rgba(88,166,255,.08); }
.count { font-size: .7rem; background: var(--panel); border: 1px solid var(--border);
         border-radius: 2em; padding: .05em .4em; margin-left: .25em; }

/* Panels */
main { padding: 1.5rem 2rem; max-width: 1100px; margin: 0 auto; }
.tab-panel { display: none; }
.tab-panel.active { display: block; }

/* Cards */
article { background: var(--panel); border: 1px solid var(--border);
          border-radius: 8px; padding: 1.25rem; margin-bottom: 1.25rem; }
article h3 { margin: 0 0 .75rem; font-size: .95rem; color: var(--accent); }
article.binary { background: var(--panel-2); }

/* Why prose */
.why { margin-bottom: .75rem; font-size: .9rem; line-height: 1.6; }
.tag { display: inline-block; font-size: .65rem; font-weight: 700; letter-spacing: .05em;
       text-transform: uppercase; background: var(--panel-2);
       border: 1px solid var(--border); padding: .1em .4em; border-radius: 3px;
       margin-right: .4em; vertical-align: middle; }

/* Diffs */
pre.diff { background: var(--panel-2); border: 1px solid var(--border);
           border-radius: 4px; padding: .75rem; overflow-x: auto;
           max-height: 70vh; font-size: 12px; line-height: 1.5; margin: 0;
           white-space: pre; }
.line { display: block; }
.line.add     { background: var(--add-bg); color: var(--add-fg); }
.line.del     { background: var(--del-bg); color: var(--del-fg); }
.line.hunk    { background: var(--hunk-bg); color: var(--hunk-fg); }
.line.meta    { color: var(--muted); }
.line.context { color: var(--text); }

/* Summary */
.lede { font-size: 1rem; line-height: 1.65; margin: 0 0 1.5rem; }
.kpi-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
            gap: .75rem; margin-bottom: 1.5rem; }
.kpi-card { background: var(--panel); border: 1px solid var(--border);
            border-radius: 6px; padding: .75rem 1rem; text-align: center; }
.kpi-value { font-size: 1.5rem; font-weight: 700; color: var(--accent); }
.kpi-label { font-size: .75rem; color: var(--muted); margin-top: .15rem; }

/* QA */
.anchor-note { background: rgba(210,153,34,.1); border: 1px solid var(--amber);
               border-radius: 6px; padding: .75rem 1rem;
               margin-bottom: 1rem; font-size: .9rem; }

/* Tables */
.std-table { border-collapse: collapse; width: 100%; font-size: .875rem; }
.std-table th, .std-table td { padding: .5rem .75rem;
                                border: 1px solid var(--border); text-align: left;
                                vertical-align: top; }
.std-table th { background: var(--panel-2); color: var(--muted); font-weight: 600; }
.std-table tr:nth-child(even) td { background: rgba(255,255,255,.02); }
.std-table code { font-size: .8rem; }

/* Misc */
.muted { color: var(--muted); }
ul.tight { margin: 0 0 1.25rem; padding-left: 1.4rem; }
ul.tight li { margin-bottom: .25rem; }
h2.group-heading { font-size: 1.05rem; color: var(--muted); font-weight: 600;
                   margin: 1.5rem 0 .75rem; padding-bottom: .25rem;
                   border-bottom: 1px solid var(--border); }
details { margin-bottom: .75rem; }
details > summary { cursor: pointer; color: var(--accent); font-size: .85rem;
                    padding: .25rem 0; }
details.file-card { margin-bottom: .5rem; }
details.file-card > summary { font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
                               font-size: .85rem; color: var(--accent); padding: .4rem .6rem;
                               cursor: pointer; border-radius: 4px; list-style: none; }
details.file-card > summary:hover { background: var(--panel-2); }
details.file-card > summary::-webkit-details-marker { display: none; }
.checklist { list-style: none; padding-left: 0; margin: 0 0 1.25rem; }
.checklist li { margin-bottom: .4rem; }
.checklist label { display: flex; align-items: flex-start; gap: .5rem; cursor: pointer;
                   line-height: 1.5; }
.checklist input[type="checkbox"] { margin-top: .25rem; accent-color: var(--accent);
                                    flex-shrink: 0; }
```

## Shell-dangerous placeholder rule

This is the canonical home for the rule. SKILL.md anti-patterns link back here rather than duplicating.

Never write a backtick-wrapped span whose rendered text contains `<`, `>`, `?`, `*`, `$`, or `|`. When the model is asked to copy a backtick-wrapped placeholder into a follow-up shell command, the shell may glob-expand or word-split the contents and produce an incorrect command. Use prose substitutes:

- Not: `` `<IID>` ``, write "the IID" instead
- Not: `` `<head SHA>` ``, write "the head SHA" instead
- Not: `` `<project path>` ``, write "the project path" instead
- Not: `` `<issue key>` ``, write "the issue key" instead

The same rule applies to the WHY prose: name identifiers without wrapping them in `<...>` if the identifier already starts with an angle bracket.
