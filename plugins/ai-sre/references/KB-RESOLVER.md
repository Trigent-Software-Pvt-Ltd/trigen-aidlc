# KB Resolver — Product Knowledge Lookup Convention

Every ai-sre skill uses this convention to find product-specific knowledge. Follow these rules for every reference lookup.

---

## 1. Slug Normalisation

Derive the canonical slug from `$ARGUMENTS`:

| Input pattern | Canonical slug |
|---|---|
| `cpoms-studentsafe`, `studentsafe`, `cpoms.net`, `cpoms uk`, `trigent.com/studentsafe` | `cpoms-studentsafe` |
| `cpoms-staffsafe`, `staffsafe`, `staff` | `cpoms-staffsafe` |
| `cpoms` (bare, no qualifier) | **REJECT** — stop and ask: *"Did you mean cpoms-studentsafe (cpoms.net / trigent.com/studentsafe) or cpoms-staffsafe?"* |
| `em`, `emergency`, `emergency-management` | `em` |
| `training`, `train` | `training` |
| `psw-us` | `psw-us` |
| `psw`, `psw-ca`, `publicschoolworks` | `psw-ca` |
| `vm`, `visitor`, `visitor-management`, `visitorsafe` | `vm` |
| `volunteer`, `vol`, `volunteersafe` | `volunteer` |
| `dismissal`, `dis`, `dismissalsafe` | `dismissal` |
| `smartpass`, `sp` | `smartpass` |
| `schoolpass`, `school-pass` | `schoolpass` |
| `eventsafe`, `es` | `eventsafe` |
| `badge`, `badge-alert` | `badge-alert` |
| `platform`, `plt`, `shared-services` | `platform` |
| `integrations`, `int`, `webhooks`, `trigent-connect`, `trigentlink` | `integrations` |

---

## 2. Region Inference

Many products deploy to multiple regions. Region drives file selection when region-specific variants exist (e.g. `dashboards/service-level-objectives-uk.md` when SLI GUIDs differ by region).

1. If `$ARGUMENTS` contains `--region us` or `--region uk`, use that.
2. Otherwise infer from alert/URL context:
   - `cpoms.net`, `staffsafe.cpoms.net`, `produk-`, `staffuk-` → `uk`
   - `trigent.com/studentsafe`, `cpomsus-`, `prod-aks-akscluster-re1-001-ls` → `us`
   - PSW-specific: keyword `us`/`united states` → `us`; keyword `canada`/`ca` → `ca`
3. If region cannot be determined and the product declares multiple regions:
   - **Default:** ask the user to confirm the region (e.g. *"Which region — US or UK?"*) before fetching, and fetch only the confirmed variant. A one-line question is far cheaper than doubling KB fetch volume, and none of the non-`sre-incident` skills are time-critical enough to justify fetching both blind.
   - **Exception — `sre-incident` SEV1 only:** do not block evidence collection. Fetch both regional variants where they exist and note the ambiguity in the output. This preserves the SEV1 fast-path guarantee (evidence collection must never wait on a question).

---

## 3. Lookup Order

For each `(slug, topic)` pair the skill needs, follow steps A → E in order.

### Step A — Fetch product registry

Fetch `products.yaml` (`project: trigent1/devsecops/sre-kb/kb-shared`, `ref: main`) using the caching convention in §5 — except `sre-refresh`, which always fetches this live (§5, point 6).

Parse YAML to resolve for this slug:
- `project` — KB project path (e.g. `trigent1/devsecops/sre-kb/kb-cpoms-studentsafe`)
- `regions` — list of deployed regions
- `inherits` — ordered list of shared layer slugs (e.g. `[trigent-platform-shared, trigent-azure-shared]`)
- `legacy_local` — if `true`, skip Steps B and C, go directly to Step D

Cache this parsed YAML in context for the entire skill invocation regardless of source (disk cache or live fetch). Do not re-fetch it mid-run.

### Step B — Discover and fetch from product KB

First, enumerate what files exist in the product's KB project:

```
mcp__gitlab__get_repository_tree(
  project = <product.project>,
  ref     = "main",
  recursive = true
)
```

Apply the caching convention in §5 to this tree call.

Use the tree listing to find the most relevant files for the topics the skill needs. **There is no mandatory file layout** — KB project authors structure their content however makes sense for their product. Use judgment to identify:

| What the skill needs | What to look for in the tree |
|---|---|
| Product overview, environments, app identifiers | Root-level `main.md`, `README.md`, `overview.md`, or equivalent |
| Infrastructure (clusters, databases, networking) | Any file mentioning AKS, ECS, RDS, cluster, namespace, resource group |
| Severity thresholds / alert policies | Any file mentioning SEV, severity, alert, SLO, SLI, error budget |
| Runbooks | Files under a `runbooks/` directory, or any file named `runbook-*.md` |

After identifying the relevant files, fetch their content using `mcp__gitlab__get_file_contents` (`project` from Step A, `ref: main`), applying the caching convention in §5 to each fetch.

**Region-specific files:** when the tree contains both a base file and a region-suffixed variant (e.g. `metrics.md` and `metrics-uk.md`), prefer the region-specific variant when the active region is known.

If the project is not found (404/project-not-found): skip to Step D.

Fetch all content the skill needs, then proceed to Step C.

### Step C — Fetch inherited shared layers

For each entry in `inherits` (in order: `trigent-platform-shared` first, then `trigent-azure-shared`), fetch the same topic from the shared layer's KB project. Merge content **additively** — shared layers provide cross-product context that supplements, not replaces, the product-specific content.

| Shared layer slug | KB project |
|---|---|
| `trigent-platform-shared` | `trigent1/devsecops/sre-kb/kb-trigent-platform-shared` |
| `trigent-azure-shared` | `trigent1/devsecops/sre-kb/kb-trigent-azure-shared` |
| `trigent-integrations-shared` | `trigent1/devsecops/sre-kb/kb-trigent-integrations-shared` |

Shared layer content covers:
- **trigent-platform-shared**: central-api, SSO/Auth0, spotlight, shared notification services, platform SLOs common to all Trigent products
- **trigent-azure-shared**: AKS clusters (US cluster `prod-aks-akscluster-re1-001-ls`, UK cluster `produk-aks-akscluster-re1-001`), MySQL Flexible Servers, Key Vaults, resource groups, subscriptions, Azure subscriptions. Source-of-truth is GitLab project `78213961`; the KB contains a hand-curated summary.
- **trigent-integrations-shared**: outbound webhooks, audit trail, TrigentLink V3 SIS roster sync, sex offender registry (SOR), staff sync, and tardy writeback. AKS namespaces `integrations` + `trigent-trigentlink-v3` (US + UK).

Use `mcp__gitlab__get_repository_tree` on each shared layer project to discover available files (caching convention in §5 applies), then fetch those relevant to the topics the skill needs (caching convention in §5 applies to each fetch). If a shared layer has no content relevant to the current topic, skip it — not an error.

Shared-layer content is identical across every product that inherits it — this is the highest-value target for the §5 cache, since two incidents on different products in the same session otherwise re-fetch these bytes twice for no reason.

**R6 legacy shared layer (US only):** After fetching the declared `inherits` layers, if the active region is `us` OR the product's `regions` list includes `us` and region is unresolved, also fetch (caching convention in §5 applies — this file is unconditional for the large majority of products, making it the single most-repeated fetch across incidents):

```
mcp__gitlab__get_file_contents(
  project = "trigent1/devsecops/sre-kb/kb-shared",
  ref     = "main",
  path    = "trigent-legacy-r6.md"
)
```

This file covers cross-product US infrastructure not owned by any single product: R6 monolith App Service (`trigent-r6-app-prod`), sharded SQL (`trigent-psql-2`), legacy event buses (UserContactRole, ClientBuilding, R6 internal), Container Instances, APIM (`prod-apim-api-oz`), and notification functions (push, SMS, voice, web). It is US-only — do not load for UK-only products (e.g. `cpoms-staffsafe`).

### Step D — Legacy local fallback

The product has `legacy_local: true` or its GitLab KB project does not yet exist. Read the plugin-local files using the `Read` tool:

| Slug | `infrastructure` fallback | `severity` fallback | `product-overview` fallback (sre-incident only) |
|---|---|---|---|

> **All products migrated to KB (v3.4.0)** — this table is intentionally empty. If a new product is added with `legacy_local: true`, add a row here pointing to its local reference files.

### Step E — Both missing

Output and stop:

```
⚠️  No KB content found for product: <slug>
    GitLab KB project to create: trigent1/devsecops/sre-kb/kb-<slug>
    Minimum content needed (structure is up to the author):
      - A product overview file (environments, app names, identifiers, component map)
      - An infrastructure reference file (clusters, databases, namespaces, resource groups)
      - A severity/alert thresholds file
      - Runbooks as appropriate
    Also add one entry to: trigent1/devsecops/sre-kb/kb-shared/products.yaml
    Example of a well-structured KB: trigent1/aidevops/sleuth/docs/cpoms
```

---

## 4. Topics Per Skill

What each skill needs to find in the KB tree:

| Skill | Look for |
|---|---|
| `sre-incident` | Product overview (environments, identifiers, component map), infrastructure, severity/alert thresholds, SLO targets |
| `sre-postmortem` | Infrastructure topology, severity thresholds |
| `sre-slo` | Infrastructure, SLO/SLI definitions and targets |
| `sre-runbook` | Infrastructure, list of available runbooks |
| `sre-toil` | Infrastructure topology |
| `sre-refresh` | Enumerate products from `products.yaml`; for KB-managed products fetch the product overview file |

For `sre-incident`: the product overview file from the KB replaces the local `product-<slug>.md` file for Phase 1.5 live sync commands, Phase 2A sequences, and Phase 2B health checks. Use whatever file the KB tree reveals as the product overview.

---

## 5. Caching Convention

Two layers apply to every `mcp__gitlab__get_file_contents` / `mcp__gitlab__get_repository_tree` call in Steps A–C:

**1. Within-invocation:** Do not fetch the same `(project, path)` pair more than once per skill run. If already in context, reuse it.

**2. Cross-invocation (60-minute TTL disk cache):** Shared-layer content and product-KB content rarely change between incidents, but without this, every separate skill invocation re-fetches identical bytes from GitLab from scratch. Use a local disk cache via `Bash`:

1. **Cache key:** replace `/` with `_` in `project` and `path`, join with `__`. For tree listings use the literal path segment `__tree__`. Example: `trigent-legacy-r6.md` in `kb-shared` → `trigent1_devsecops_sre-kb_kb-shared__trigent-legacy-r6.md`.
2. **Before fetching**, check freshness:
   ```
   find /tmp/ai-sre-kb-cache -name '<cache-key>' -mmin -60 2>/dev/null
   ```
   If this returns a path, `cat` it and use that content instead of calling the MCP tool.
3. **On a cache miss** (no output, or the file is older than 60 minutes), call the MCP tool as normal, then persist the result:
   ```
   mkdir -p /tmp/ai-sre-kb-cache && cat > /tmp/ai-sre-kb-cache/<cache-key> <<'KB_CACHE_EOF'
   <content>
   KB_CACHE_EOF
   ```
4. **Never cache a Step E "not found" outcome.** Always re-resolve missing KB projects live — the whole point of Step E is surfacing a KB gap for someone to fix, and a cached miss would hide that a project now exists.
5. **The cache is advisory, not authoritative.** If cached KB narrative ever contradicts a live command's output (e.g. `sre-incident` Phase 1 evidence tracks, or a `sre-refresh` discovery result), trust the live evidence and refresh the cache entry immediately. Live evidence always outranks cached reference content — this changes nothing about how hard evidence rules (e.g. `sre-incident`'s evidence levels) already work.
6. **`sre-refresh` bypasses this cache entirely for all of Steps A–C.** Its entire purpose is detecting drift against live infrastructure, so it must always read `products.yaml` and any content it inspects directly, live, uncached.

---

## 6. Registry Lookup (sre-refresh)

To enumerate all known products, use the `products.yaml` fetched in Step A. Iterate:
- Products **without** `legacy_local` → KB-managed; fetch `main.md` for the refresh audit
- Products with `legacy_local: true` → not yet migrated to GitLab; patch local reference files as usual using the legacy fallback paths in Step D
- Entries under `shared_layers:` → skip direct invocation; they are not products
