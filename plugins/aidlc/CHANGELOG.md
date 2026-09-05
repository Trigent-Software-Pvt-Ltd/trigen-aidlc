# Changelog — aidlc

Notable changes. Versions follow SemVer; bump `plugin.json` **and** the root `marketplace.json`.

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
