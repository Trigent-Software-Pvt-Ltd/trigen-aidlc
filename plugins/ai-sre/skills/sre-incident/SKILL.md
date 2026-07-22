---
name: sre-incident
description: "AI-assisted active incident triage — evidence-driven reasoning engine with visible hypothesis scorecard. Collects parallel evidence, ranks hypotheses by signal score, contradiction-tests top candidates, confirms root cause with proof, and produces an exact remediation plan. Separates mitigation from root cause. Supports all Trigent products via product KB contracts. Usage: /ai-sre:sre-incident [product] SYMPTOM. (Triggers: incident, outage, down, broken, failing, api failing, service unavailable, sev1, sev2, sev3, sev4, declare incident, something is wrong, push notifications failing, incidents not processing)"
allowed-tools: [Bash, Read, Edit, Task, AskUserQuestion, mcp__gitlab__get_file_contents, mcp__gitlab__get_repository_tree, mcp__claude_ai_Atlassian__searchConfluenceUsingCql, mcp__claude_ai_Atlassian__getConfluencePage]
argument-hint: "[product] SYMPTOM"
---

# sre-incident v3.0.0 — Evidence-Driven Reasoning Engine

## Help

If `$ARGUMENTS` contains "help", read `@${CLAUDE_PLUGIN_ROOT}/references/sre-incident-help.md` and output its contents verbatim, then stop.

---

## Core Definitions

These definitions are global. Every phase references them. Never deviate.

### Evidence Levels

| Level | Definition | Example |
|-------|------------|---------|
| `VERIFIED` | Direct observation — command output directly shows the failure state | `redis-cli ping` → NOAUTH; SG rule absent from `aws ec2 describe-security-groups`; 0 ECS tasks running; pod in CrashLoopBackOff |
| `CORRELATED` | Temporal or causal correlation — same component changed within 15 min of error onset, OR metric spike begins at change timestamp | CloudTrail SG change at 14:03, errors begin 14:04 |
| `SUSPECTED` | Circumstantial — historical pattern, keyword match, runbook similarity, change >15 min before onset | Deployment 3 h before errors; similar symptom in past postmortem |
| `VERIFIED_NEGATIVE` | Explicitly disproven — command output shows healthy/normal when hypothesis predicts failure | Redis connections normal; Aurora query latency normal; all pods Running 1/1 |
| `UNRESOLVABLE` | Evidence track failed — auth error, no access, timeout, command not found | `kubectl` returns Unauthorized; CloudTrail returns AccessDenied |

**Rules:**
- `UNRESOLVABLE` does not count toward signal total and is not contradicting evidence
- `VERIFIED_NEGATIVE` is permanent — an `ELIMINATED` hypothesis cannot be reintroduced
- `CORRELATED` requires the same component as the hypothesis, not just the same time window
- Two signals from the same source about the same component = 1 independent signal

### Normalized Signal Schema

Every evidence track output must be normalized to this format before entering the scorecard:

```
signal:
  source:    [cloudtrail | kubectl | aws_ecs | cloudwatch | newrelic | azure_monitor |
              gitlab_ci | confluence | secretsmanager | azure_activity_log | ecs_logs |
              k8s_events | redis_cli | mysql | azure_sql | azure_functions | gcp_k8s]
  component: [name — e.g. redis_sg | ecs_service | auth0 | aurora | alb | ingress | deployment | cert]
  type:      [change_event | health_failure | health_ok | metric_spike | log_error | access_denied | config_change]
  level:     [VERIFIED | CORRELATED | SUSPECTED | VERIFIED_NEGATIVE | UNRESOLVABLE]
  timestamp: [UTC or relative — e.g. 14:03 UTC | T-17min]
  detail:    [one-line description of what was found]
```

### Canonical Scorecard Format

This is the **only source of truth** for hypothesis state. Output it after Phase 2, update it after Phase 3, and include its final state in Phase 6. Never reason from memory — always read and update the scorecard.

```
## Incident Evidence Scorecard

Product: [name]           SEV: [1–4 | PENDING]        Time: [UTC]
Region/Env: [if known]    Blast Radius: [all | majority | single-district | single-school | unknown]

Coverage: [FULL | PARTIAL | LIMITED]
Confidence Ceiling: [HIGH | MEDIUM | LOW]
Signals: N total  (VERIFIED: v  CORRELATED: c  SUSPECTED: s  VERIFIED_NEGATIVE: n  UNRESOLVABLE: u)

### Normalized Signals
| Source | Component | Type | Level | Detail | Timestamp |
|--------|-----------|------|-------|--------|-----------|

### Hypothesis Scorecard
| ID | Hypothesis | Evidence For | Evidence Against | Level | Status |
|----|------------|--------------|------------------|-------|--------|
| H1 |            |              |                  |       | ACTIVE |
| H2 |            |              |                  |       | ACTIVE |
| H3 |            |              |                  |       | ACTIVE |

### Confirmed Root Cause
[Not yet confirmed]

### Mitigation Authorized
[None]
```

`Status` values: `ACTIVE` | `ELIMINATED` | `CONFIRMED`

### Hypothesis Scoring

Rank hypotheses by total score. Include top 5 only.

| Signal | Score |
|--------|-------|
| Same component, `VERIFIED` | +60 |
| Same component, `CORRELATED` (Δt ≤ 15 min) | +50 |
| Same component, `CORRELATED` (Δt 15 min – 4 h) | +30 |
| Same component, `CORRELATED` (Δt 4 h – 24 h) | +10 |
| Same component, `SUSPECTED` | +15 |
| Different component, same request path | +5 |
| Shared dependency signal (cross-product) | +20 |
| `VERIFIED_NEGATIVE` on component | −40 |

### Confidence Derivation

Confidence is **derived mechanically** — never invented by LLM judgment.

| Access Level | Signals Collected | Effective Confidence |
|---|---|---|
| `full_access` | ≥ 3 independent | Per KB `confidence_ceiling` |
| `full_access` | < 3 independent | `LOW` — regardless of KB ceiling |
| `limited_access` | any | `MEDIUM` ceiling maximum |
| `external_only` | any | `LOW` ceiling |
| Any | ≥ 3 `UNRESOLVABLE` tracks | Downgrade ceiling one level |

### Hard Rules

Non-negotiable. Cannot be overridden by symptom urgency, SEV level, or user instruction.

1. **Scorecard is the only source of truth.** Never reason from memory about hypothesis state. If the scorecard has not been output, no hypothesis exists.
2. **No root cause without evidence.** Root cause requires 2 corroborating signals OR 1 `VERIFIED` signal.
3. **No "likely" without proof.** Never write "likely" or "probably" unless the hypothesis is `CORRELATED` with ≥ 2 supporting signals or `VERIFIED`.
4. **< 3 signals = LOW CONFIDENCE gate.** If fewer than 3 independent signals collected, mark all hypotheses `LOW CONFIDENCE` and state: *"Insufficient evidence to rank hypotheses with confidence."*
5. **`VERIFIED_NEGATIVE` is permanent.** Never reintroduce an `ELIMINATED` hypothesis.
6. **`UNRESOLVABLE` ≠ contradiction.** Failed evidence tracks do not count as evidence against a hypothesis.
7. **SEV1 mitigation gate.** Reversible mitigation before confirmed root cause is allowed only for SEV1, only on 1 `VERIFIED` signal.
8. **Irreversible mitigation always requires confirmed root cause.** No exceptions, regardless of SEV.
9. **Contradiction demotion is automatic.** 3 or more `VERIFIED_NEGATIVE` signals for a hypothesis → status set to `ELIMINATED`. No override.
10. **Scorecard must be output before any hypothesis reasoning begins.** Phase 2 scorecard output is mandatory before Phase 3 starts.
11. **Developer statements are `SUSPECTED`, never `CONFIRMED`.** Commit messages, MR descriptions, and Jira comments cap at `SUSPECTED` regardless of specificity. When a developer's own statement is the only signal elevating a hypothesis above `SUSPECTED`, the mechanism is unconfirmed — output the gap and the exact command needed to verify. Never stop investigating because a developer explained it. Independently verify via: (1) full stack trace query from telemetry (not just the error message — the throwing class is a `VERIFIED` signal), or (2) internal package source if a new package was introduced in the implicated commit.
12. **Always query for full stack traces, not just error messages.** When any error message appears in a telemetry track, immediately query for the complete stack trace (`error.stackTrace`, `error.class` in NR; exception details in CloudWatch/Azure Monitor). The error message alone is `SUSPECTED`. The stack trace identifying the throwing class is `VERIFIED`.

---

## Product Routing

Normalise the slug from `$ARGUMENTS`:

| Input | Slug |
|-------|------|
| `em`, `emergency` | `em` |
| `training` | `training` |
| `psw`, `psw-us` | `psw-us` |
| `psw-ca`, `psw canada` | `psw-ca` |
| `vm`, `visitor` | `vm` |
| `volunteer`, `vol`, `volunteersafe` | `volunteer` |
| `dismissal`, `dis` | `dismissal` |
| `cpoms-studentsafe`, `studentsafe` | `cpoms-studentsafe` |
| `cpoms-staffsafe`, `staffsafe` | `cpoms-staffsafe` |
| `smartpass` | `smartpass` |
| `schoolpass` | `schoolpass` |
| `eventsafe`, `es` | `eventsafe` |
| `badge`, `badge-alert` | `badge-alert` |
| `platform`, `plt`, `shared-services` | `platform` |
| `integrations`, `int`, `webhooks`, `trigent-connect`, `trigentlink` | `integrations` |
| `trigent-safe`, `trigentsafe`, `trigent safe` | `trigent-safe` |

Follow `KB-RESOLVER.md` for all products. The resolver reads `products.yaml` from `kb-shared` to determine KB-managed vs legacy-local routing automatically — do not hardcode product routing here.

If slug cannot be resolved from `$ARGUMENTS`, stop and ask:
> Which product are you triaging? (em · training · psw · vm · volunteer · dismissal · cpoms-studentsafe · cpoms-staffsafe · smartpass · schoolpass · eventsafe · badge-alert · platform · integrations · trigent-safe)

Wait for answer, then continue.

---

## Phase 0: Intake

**Goal:** Establish product, symptom, blast radius, initial SEV, region (PSW only).

1. State the active product immediately:
   ```
   Product: [Full Product Name]
   ```

2. If symptom is empty, ask:
   > What is happening? When did it start (approximate UTC)? Who reported it?

3. Capture blast radius. Ask if not stated in the symptom:
   > How many customers are affected? (all · majority · single district · single school · unknown)

   Record as `BLAST_RADIUS: [all | majority | single-district | single-school | unknown]`

4. **PSW only — region detection:**

   | Symptom contains | Active region | Resources |
   |-----------------|---------------|-----------|
   | "us", "united states" | US — us-east-1 | `PSW-PROD` cluster |
   | "canada", "ca", "canadian" | Canada — ca-central-1 | `PSW-CA-PROD` cluster |
   | Ambiguous | Ask: *Is this affecting US or Canada customers?* | — |

5. **Pre-classify SEV** (initial — revised after evidence):

   | SEV | Condition |
   |-----|-----------|
   | 1 | All customers affected OR core platform down OR complete data loss risk |
   | 2 | Majority affected OR critical feature broken for a subset |
   | 3 | Single district/school OR degraded performance |
   | 4 | Single user OR cosmetic / non-critical |

   Output: `Initial SEV: [1–4] — subject to revision after evidence`

6. **SEV1 announcement:**
   ```
   SEV1 FAST PATH ACTIVE — all evidence tracks launch immediately in parallel.
   Topology resolution will not delay evidence collection.
   ```

---

## Phase 1: Parallel Evidence Collection

**Goal:** Collect all available evidence in parallel. Normalize to signal format. Count independent signals.

### Step 1 — Load KB

Follow `KB-RESOLVER.md` to load all product knowledge for the active slug. The resolver handles KB-managed vs local reference automatically — no product-specific branching needed here.

From the loaded content, read and record:
- `access_level` → sets confidence ceiling. If absent: infer from content — products with full kubectl/AWS/Azure CLI access = `full_access`; products with only external telemetry = `limited_access`; no infra access = `external_only`
- `confidence_ceiling` → caps all confidence outputs this session. If absent: derive from `access_level` (full → HIGH, limited → MEDIUM, external → LOW)
- `known_shared_dependencies` → shared services that could cause multi-product failures. If absent: derive from the shared-layer KB content loaded via the resolver — for US products this includes the Blast Radius Summary in `trigent-legacy-r6.md` (R6 monolith, legacy service buses, APIM, notification functions) loaded from `kb-shared` per KB-RESOLVER Step C

### Step 2 — Launch Evidence Tracks in Parallel

**For SEV1 and SEV2+:** Launch all 5 tracks simultaneously using `Task`. Do not run tracks sequentially.

For each track, identify the best available commands from the loaded product knowledge that serve the track's purpose. Do not invent commands — every command must be grounded in the loaded product content.

**Scope each Task's prompt.** Before launching, extract only the KB sections relevant to that track's purpose — do not paste the full merged KB content into every subagent's prompt. Track 1 needs change-history/CI/deployment sections; Track 2 needs health-check/service sections; Track 3 needs topology/networking sections; Track 4 needs telemetry/metrics sections; Track 5 needs the runbook index. This keeps each Task scoped to what it needs instead of duplicating the entire KB five times over.

**Track 1 — `recent_changes`** (scope: T-4 h primary, T-24 h secondary)
Target: deployments, SG/firewall rule changes, secret rotations, config changes, certificate updates.
Sources: CloudTrail (AWS), Azure Activity Log (AKS), GitLab CI pipeline history, ECS task definition history, kubectl rollout history.

**Track 2 — `service_health`**
Target: task/pod counts, health check status, error rates, stopped or crashed containers.
Sources: `aws ecs describe-services`, `kubectl get pods -n {namespace}`, ALB target group health, Azure Container Apps status.

**Track 3 — `topology`**
Target: request path for the affected endpoint, dependency chain, SG/network rules.
Sources: `aws ec2 describe-security-groups`, `kubectl get ingress/svc -n {namespace}`, ALB listener rules, ECS service discovery.
For SEV1: runs in parallel with all other tracks — do not block on it.

**Track 4 — `telemetry`**
Target: error rate spikes, latency P95, metric anomalies correlating with symptom onset.
Sources: New Relic NerdGraph (if `NEW_RELIC_API_KEY` set), CloudWatch metrics, Azure Monitor, ECS CloudWatch Logs.

**Track 5 — `knowledge_base`**
Target: runbook matching the symptom in Confluence MI space (parent page `2427486270`).
Use `mcp__claude_ai_Atlassian__searchConfluenceUsingCql` with terms from the symptom. A matching runbook = 1 `SUSPECTED` signal.

### Step 3 — Normalize Outputs

For each track result, produce one or more normalized signals using the schema in Core Definitions.

| Result type | Normalization |
|-------------|---------------|
| Finding (non-empty, actionable) | One signal per distinct finding |
| Empty / null from working command | Zero signals — not `VERIFIED_NEGATIVE` |
| Failed command (auth error, timeout) | One `UNRESOLVABLE` signal |
| Two findings from same source, same component | Count as 1 independent signal |

### Step 4 — Cross-Product Correlation Check

If any signal implicates a `known_shared_dependency` at level `CORRELATED` or higher:

1. Run a 30-second spot check on 1–2 other products that share that dependency.
2. If 2+ products show correlated degradation through the same dependency, add signal:
   ```
   source: cross_product_check
   component: [shared dependency name]
   type: health_failure
   level: CORRELATED
   detail: "Multi-product degradation detected — [product A] and [product B] both affected"
   ```
3. This signal surfaces as `H1: Shared Platform Failure — [dependency]` in Phase 2, regardless of score.

### Step 5 — Determine Coverage and Signal Count

Count independent signals (UNRESOLVABLE = 0, same-source same-component duplicates = 1).

| Condition | Coverage |
|-----------|----------|
| All 5 tracks returned ≥ 1 non-UNRESOLVABLE result | FULL |
| 3–4 tracks returned results | PARTIAL |
| ≤ 2 tracks returned results, OR `access_level` = `limited_access` / `external_only` | LIMITED |

State before Phase 2:
```
Evidence collection complete.
Coverage: [FULL | PARTIAL | LIMITED]
Signals: N  (VERIFIED: v  CORRELATED: c  SUSPECTED: s  VERIFIED_NEGATIVE: n  UNRESOLVABLE: u)
```

---

## Phase 2: Hypothesis Scorecard

**Goal:** Generate top 5 hypotheses from normalized signals. Initialize and output the scorecard. This output is mandatory before Phase 3.

### Step 1 — LOW CONFIDENCE Gate

If independent signals < 3:
```
⚠ LOW CONFIDENCE — fewer than 3 independent signals collected.
All hypotheses below are LOW CONFIDENCE and cannot be presented as likely root cause.
Cause: [evidence track failures | limited product access | service fully down]
Confidence Ceiling: LOW
Recommended action: escalate to [escalation owner from KB, or product on-call] or check external telemetry before proceeding.
```

Continue to scorecard initialization — do not stop. Mark all hypothesis rows with `[LOW CONFIDENCE]` appended to the Level column.

### Step 2 — Generate Hypotheses

Score each candidate hypothesis using the Hypothesis Scoring table in Core Definitions.
Select top 5 by score.

**Override:** If a cross-product correlation signal exists → assign `H1: Shared Platform Failure — [dependency]` regardless of score ranking.

For each hypothesis, populate:
- **Evidence For:** normalized signals that support it — list source, detail, level, timestamp
- **Evidence Against:** normalized signals that contradict it — list `VERIFIED_NEGATIVE` entries
- **Level:** highest evidence level of supporting evidence (`VERIFIED` > `CORRELATED` > `SUSPECTED`)

### Step 3 — Output Scorecard

Output the full Canonical Scorecard. This output is mandatory before Phase 3 begins.

---

## Phase 3: Contradiction Testing

**Goal:** Actively disprove the top 3 hypotheses. Update the scorecard. Apply the demotion rule.

For each of **H1, H2, H3** (ACTIVE only — skip ELIMINATED):

**1. Identify the hypothesized component.**

**2. Determine 2 checks that would disprove it.**

Ask internally: *If this hypothesis is wrong, what would the evidence show?*

Examples:
- H: "Redis SG removed" → disproof checks: `redis-cli ping` succeeds; other Redis consumers healthy
- H: "Bad deploy" → disproof checks: errors predate deploy timestamp; other endpoints unaffected
- H: "Aurora outage" → disproof checks: connection count normal; query latency normal

Use commands from the product KB where available. If the specific contradiction check is not in the KB, use the most direct available CLI tool for the component — contradiction checks are targeted probes designed to disprove a specific hypothesis, and are a designed exception to Phase 1's "grounded in loaded content" rule. The goal is disproof, not discovery.

**3. Run both checks.**

**4. Normalize outputs** to signal format.

**5. Update the scorecard:**
- Add new signals to the Normalized Signals table
- Add to the **Evidence Against** column for the relevant hypothesis
- Assign `VERIFIED_NEGATIVE` if the check directly contradicts the hypothesis

**6. Apply the demotion rule (automatic, no override):**
> If a hypothesis has **3 or more `VERIFIED_NEGATIVE` signals** in Evidence Against → set Status to `ELIMINATED`.

**7. Differential diagnosis check** (run after all H1–H3 contradiction tests):
- Identify the top two remaining ACTIVE hypotheses
- Ask: *What single check would definitively distinguish H1 from H2?*
- Run that check. Normalize. Update scorecard.

**8. Re-output the full updated scorecard.** Every phase must leave a current scorecard visible.

---

## Phase 4: Root Cause vs Mitigation
## Phase 5: Remediation Plan
## Phase 6: Timeline / Postmortem Output

Once Phase 3 contradiction testing is complete, read `@${CLAUDE_PLUGIN_ROOT}/references/sre-incident-phases-4-6.md` in full and follow it exactly — it contains the root cause confirmation thresholds, the mitigation authorization matrix, the remediation plan template, and the timeline/handoff templates for these three phases. All Hard Rules and Core Definitions above still apply; this content is only deferred, not optional. Loaded on demand because most SEV3/4 incidents never need it.

---

## References

- @${CLAUDE_PLUGIN_ROOT}/references/KB-RESOLVER.md
- @${CLAUDE_PLUGIN_ROOT}/references/sre-incident-help.md (Help block — read only if `$ARGUMENTS` contains "help")
- @${CLAUDE_PLUGIN_ROOT}/references/sre-incident-phases-4-6.md (Phases 4–6 — read only once Phase 3 is complete)

`sre-principles.md` (SLO/error-budget philosophy) is intentionally not referenced here — no phase in this skill consults it; it belongs to `sre-slo`.

Per-product infrastructure and severity files are loaded dynamically via KB-RESOLVER.md — do not load any per-product reference file directly.
