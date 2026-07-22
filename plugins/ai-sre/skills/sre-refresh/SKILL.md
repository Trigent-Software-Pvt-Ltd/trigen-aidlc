---
name: sre-refresh
description: "Refresh ai-sre plugin GitLab KB projects from live infrastructure — triggers a GitLab discovery pipeline in the KB project for the specified product. All products are KB-managed: em, cpoms-studentsafe, cpoms-staffsafe, training, vm, volunteer, dismissal, eventsafe, smartpass, schoolpass, badge-alert, psw-us, psw-ca, trigent-safe. Run after infrastructure changes or before/after an incident. Usage: /ai-sre:sre-refresh [product] [--diff-only]. (Triggers: refresh plugin, update infrastructure, sync reference docs, new cluster, cluster changed, new service added, update sre config)"
allowed-tools: [Bash, Read, Edit, Task, mcp__gitlab__get_file_contents, mcp__gitlab__get_repository_tree, mcp__gitlab__list_group_projects, mcp__gitlab__create_pipeline]
argument-hint: "[product]  (omit = all)  [--diff-only]"
---

# SRE Plugin Reference Refresh

## Help

If `$ARGUMENTS` contains "help", output the following and stop:

```
/ai-sre:sre-refresh [product]  [--diff-only]

Refresh infrastructure documentation from live state.

All products are KB-managed — triggers the discovery pipeline in the GitLab KB project.
The pipeline probes live infrastructure and commits any drift directly, or opens an MR
for structural changes. No local plugin edits are made.
With --diff-only: lists which KB pipelines would be triggered without actually triggering them.

Arguments:
  em                 Emergency Management
  training           Training Platform
  psw                PSW — both US and CA regions
  vm                 Visitor Management
  volunteer          Volunteer Management
  dismissal          DismissalSafe
  cpoms-studentsafe  CPOMS StudentSafe
  cpoms-staffsafe    CPOMS StaffSafe
  smartpass          SmartPass
  eventsafe          EventSafe
  schoolpass         SchoolPass Legacy
  badge-alert        Badge Alert
  trigent-safe        Trigent Safe (mobile Passport check-in)
  all                All products (default when omitted)

  --diff-only        Show what would be triggered without running any pipelines

What it does NOT change (any path):
  • SEV thresholds or severity logic
  • Subscription IDs or tenant IDs
  • Manually curated content (symptom maps, hypothesis patterns)

Examples:
  /ai-sre:sre-refresh                        → refresh all products
  /ai-sre:sre-refresh em                     → refresh EM only
  /ai-sre:sre-refresh training               → trigger KB pipeline for Training
  /ai-sre:sre-refresh all --diff-only        → preview what would be triggered

Related: /ai-sre:sre-incident (uses the refreshed data immediately)
```

---

Discover live infrastructure state and patch or trigger refresh for all product documentation.

## References
- @${CLAUDE_PLUGIN_ROOT}/references/KB-RESOLVER.md

---

## Phase 0: Registry Load and Routing Validation

**Step 1 — Fetch product registry:**

```
mcp__gitlab__get_file_contents(
  project = "trigent1/devsecops/sre-kb/kb-shared",
  ref     = "main",
  path    = "products.yaml"
)
```

Cache this for the invocation. If the fetch fails, fall back to the hardcoded registry:
- KB-managed: `em`, `cpoms-studentsafe`, `cpoms-staffsafe`, `training`, `psw-us`, `psw-ca`, `vm`, `volunteer`, `dismissal`, `eventsafe`, `smartpass`, `schoolpass`, `badge-alert`, `trigent-safe`
- Legacy-local: (none — all products migrated to KB in v3.4.0)

**Step 2 — Detect flags:**

If `$ARGUMENTS` contains `--diff-only`, set `DIFF_ONLY=true`. Strip the flag before slug resolution.

**Step 3 — Normalise and scope:**

Normalise `$ARGUMENTS` per KB-RESOLVER.md §1. Bare `cpoms` is rejected — ask for disambiguation.

| `$ARGUMENTS` | Scope |
|---|---|
| empty or `all` | All products from registry |
| recognised slug | That product only |

**Step 4 — Validate routing invariants** (abort loudly on failure, do not proceed):

> All products are currently KB-managed (`legacy_local: true` is not used). If a future product introduces `legacy_local: true`, add a row to the KB-RESOLVER.md Step D table and create a local reference file before running sre-refresh.

For each slug in scope:
- Assert the KB project tree is reachable via `mcp__gitlab__get_repository_tree(project=<project>, ref=main, recursive=false)`. If 404, stop:
  > ⚠️  Routing error: `<slug>` has no KB project at `<project>`.
  > Either provision the KB project or add `legacy_local: true` to products.yaml.

---

## Phase 1: KB-Managed Products — Trigger Discovery Pipeline

For each slug in `KB_MANAGED` scope:

**If `DIFF_ONLY=true`:**

```
📋 DIFF-ONLY: Would trigger pipeline for <display-name>
   Project: <project>
   Pipeline ref: main
   Variables: REASON=sre-refresh, TRIGGERED_BY=<user>
   No pipeline triggered.
```

**Otherwise — trigger the pipeline:**

```bash
source ~/.bashrc 2>/dev/null
glab ci run \
  -R <project> \
  -b main \
  --variables "REASON:sre-refresh,TRIGGERED_BY:${USER:-sre-refresh-skill}" \
  2>/dev/null
```

If `glab` is unavailable or returns an error, fall back to:
```
mcp__gitlab__create_pipeline(
  project   = "<project>",
  ref       = "main",
  variables = [
    { key = "REASON",       value = "sre-refresh" },
    { key = "TRIGGERED_BY", value = "<user>" }
  ]
)
```

Report:
```
✅ Pipeline triggered for <display-name>
   Project: <project>
   Pipeline URL: <url from response>
   The pipeline will probe live Azure infrastructure and commit any routine
   drift directly to main. Structural changes open an MR for review.
   Monitor progress at the URL above.
```

Note: If the KB project does not yet have a `.gitlab-ci.yml`, the pipeline will fail immediately with "No stages / jobs for this pipeline". This is expected until MRs B/C are merged into the KB repos. The trigger is still valid — the pipeline will start succeeding once CI is in place.

---

## Phase 2: Legacy-Local Products — Live Discovery

If `LEGACY_LOCAL` scope is empty, skip to Phase 5.

> **All products are KB-managed as of v3.4.0.** This phase is always skipped for normal invocations. It is preserved here as a template for any future product added with `legacy_local: true`.

---

## Phase 3: Diff Against Current Reference Docs

If `LEGACY_LOCAL` scope is empty (all products KB-managed), skip to Phase 5.

If there are legacy-local products in scope: read their local reference docs, compare to discovered live state, and report a diff table with `UPDATE / OK / ADD` actions per field.

If `DIFF_ONLY=true`: print the diff table and stop here. Do not proceed to Phase 4.

---

## Phase 4: Patch Reference Docs

For each UPDATE or ADD item in the diff:

1. Show the exact change before applying it
2. Apply the edit to the relevant reference file using Edit
3. Mark TBD placeholders as resolved when live resources are confirmed

**Safety rule:** Never remove documented services or resources — only add or update. If a resource disappeared from live discovery, flag it for manual review rather than auto-deleting.

---

## Phase 5: Summary Report

```
=== REFRESH COMPLETE — {YYYY-MM-DD HH:MM} ===

KB-managed pipelines triggered:
  • <product>: <pipeline URL>  (or "skipped — --diff-only")
  (one line per product in scope; omit if no KB-managed products triggered)

No action needed:
  • {products that were skipped or had no pipeline to trigger — count only}

Run `/ai-sre:sre-incident` — KB content is now current.
```
