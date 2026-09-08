# Changelog — aidlc

Notable changes. Versions follow SemVer; bump `plugin.json` **and** the root `marketplace.json`.

## 4.21.0

**Fixed — grouping/Story tickets were one-line stubs.** `task-creator` Step 2 built the grouping
(Story) description as a thin "Scope / Execution Details / Tasks list" stub while only the leaf Tasks
used `work-item-template.md`. Now **both** the grouping and the leaves are built from the template:
the grouping carries the **feature-level user story** (persona + capability + outcome, feature ACs
referencing FR ids, business rules), sourced from the brief/PRD slice — never a bare "sprint grouping
for X". "Sprint" is a label (`aidlc:sprint`, `sprint-<n>`), not the content. `work-item-template.md`
and `/aidlc-verify` updated to state this explicitly (Claude + Cursor).

## 4.20.0

**Added — Design Document as the solution spec.** New `references/design-doc-template.md`: a
15-section, depth-scaled Design Document (Overview → Impact & dependencies) that is a **shared
artifact** — plain-language solution/flow/rules/security sections a BA/PO can validate, plus
engineering detail (architecture, data model, API/contract, error handling, algorithms, test
strategy) and `FR/AC → task → test` traceability. `/aidlc-design` at Standard now produces this full
document, **not the old two-line note**; Quick folds it into the brief, Deep adds a formal domain
model / alternatives / sequence diagrams. Guardrail: a design is HOW (the PRD is WHAT) — link the
PRD, don't restate it; cross-cutting/shared-contract decisions become ADRs.

## 4.19.0

**Added — AI-DLC PRD as the source specification.** New `references/prd-template.md`: a 21-section,
depth-scaled, product-facing PRD (Document Context → Definition of Ready) that the pipeline
decomposes (Intent → **PRD** → Design → Epics/Stories+AC → Code → Test). Requirements are
machine-readable `FR-<AREA>-<NNN>` blocks (priority/actor/risk/depends-on) with `AC-*`/`BR-*` ids for
end-to-end traceability. **Mandatory in every PRD and Feature Brief:** Acceptance Criteria (positive +
negative + permission), Business Rules, Roles/Permissions, State Lifecycle, Data/Integration behavior,
Edge/Failure cases — a requirement without AC is not ready. Two guardrails: *scale depth, not
structure* (same sections at every gear), and *a PRD is not a design* (no API/schema/tests). Wired
into `/aidlc-intent`; the Feature Brief upgraded to a Quick/Standard PRD that carries these layers.

## 4.18.0

**Added — Constitution.** One-page `aidlc.constitution.md` (principles, constraints, conventions,
governance) created at `/aidlc-init` and honored by intent/design/verify. Links the `standards`
plugin instead of restating it. A constraint breach now requires an ADR, not a silent exception.
*(borrowed from GitHub Spec Kit `/constitution`)*

**Added — Coherence check.** A pass in `/aidlc-verify`, before any ticket is created: brief ↔ design
↔ tasks ↔ constitution must agree. Flags untraceable ACs, schema/contract mismatches, constraint
violations, and unresolved assumptions. Distinct from the readiness/confidence check (detail vs.
agreement). Ceremony-scaled: Quick skips, Standard = single-feature, Deep = across Epics.
*(borrowed from GitHub Spec Kit `/analyze`)*

## 4.17.0

**Changed — Lifecycle-wide ceremony gears.** New `references/ceremony-scaling.md` defines
**quick / standard / deep**; `ceremony.default` replaces `featureBrief.enabled`. Every phase now
sizes its output to the gear while keeping the step. **Standard** runs all phases light but keeps the
full **Feature → Epic → Sprint → Story/Task** hierarchy; a feature is sized to ~one two-week sprint /
one Epic. `feature-brief.md` reframed as the light Intent output.

**Added — Publish gate.** Show draft → get approval → publish, enforced at every phase and gear. No
write to Confluence/GitLab/Linear/Jira until the drafted content is approved in chat.

**Added — Attach-or-create Epic.** Related features share one Epic (a new Sprint per feature) instead
of each spawning its own; `/aidlc-verify` reuses the Epic on transfer.

All changes mirrored across Claude skills/references and the Cursor `.mdc` rules.

## 4.16.0 and earlier

Execution rigor (recovery ledger, task briefs/context hygiene, 3-round fix-loop + adjudication,
two-stage review), rich 12-section Jira work-item template with per-ticket labels and estimation,
configurable issue types (Epic → Story → Task), and the AI-DLC lifecycle skills. See git history.
