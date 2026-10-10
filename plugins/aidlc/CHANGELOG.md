# Changelog — aidlc

Notable changes. Versions follow SemVer; bump `plugin.json` **and** the root `marketplace.json`.

## 4.31.0 — Deferred items: skill-integrity harness + first ENH-011 slim

Closes the two deferred items from the ENH-001…016 programme. Behaviour-preserving.

- **Skill/reference integrity suite** — `tests/skills.sh` (pure bash, read-only). Checks
  frontmatter `name == folder` + description, Cursor `.mdc` parity per skill, aidlc-internal
  `@references/*.md` link resolution (cross-plugin `standards` links out of scope), referenced
  hooks exist, and **required requirement anchors** per skill so a slimming pass can never silently
  drop a load-bearing instruction. **74/74 pass.** This is the ENH-011 safety net.
- **ENH-011 first slim** — relocated the `/aidlc-verify` Troubleshooting appendix (self-contained,
  no requirement anchor) to `references/verify-troubleshooting.md` and linked it; skill body
  1385 → 1340 lines, zero behaviour change (verified green by both suites). Core workflows left
  intact — further slimming is incremental, anchor-guarded, never bulk.
- **Fix** — repaired a pre-existing dangling link in `aidlc-progress` (`references/sprint-conventions.md`,
  a file that never existed) → repointed to the real `sprint-plan-template.md` + `story-sizing.md`
  + `task-sizing.md`. Surfaced by the new harness.

Hook suite unchanged at 42/42. Cursor README reference list updated.

## 4.30.0 — Release C: enterprise delivery (ENH-012…016)

Additive; optional capabilities, default-safe (QMetry local-only, risk/traceability are reports).

- **ENH-012 Sprint 0 readiness** — `references/sprint0-readiness.md`; `/aidlc-init` writes an auditable
  `.aidlc/readiness-report.md` (project type, repo/arch context, roles & approval ownership, integration
  readiness, baseline metrics, quality/release gates, first-sprint readiness). No redundant stage.
- **ENH-013 QMetry360 integration** — `hooks/qmetry-emit.sh` (dependency-light) + `references/qmetry360-events.md`
  (stable event schema + correlation ids). **Local JSONL by default; live POST only against a configured,
  verified contract — no endpoint/auth shipped, none invented.** `qmetry360` config block +
  `QMETRY_*` env; emit points documented per skill. Tested (local record / off / missing-event / non-JSON
  data coercion), no live calls in tests.
- **ENH-014 Risk-based governance** — `references/risk-governance.md`: one risk taxonomy across
  design/impl/review/release; HIGH-risk → specialist review + ADR; **a readiness/confidence score never
  overrides a failed mandatory security/compliance gate** (ties to enforced gates). Referenced from
  design/verify/review.
- **ENH-015 Skill regression testing** — `references/skill-eval.md`; `/aidlc-retro` evaluates a proposed
  skill-instruction change against a scenario set before adoption; never auto-rewrites a production skill.
- **ENH-016 Traceability** — `references/traceability.md`; `/aidlc-progress` emits a traceability report
  (Intent→Requirement→Unit→Story→Design/ADR→Test→PR→Build→Release) flagging missing links, unverified
  requirements, and ungated changes. Report only.

Cursor rules (init/progress/retro) + README references updated. Test suite 38 → 42 (adds qmetry-emit);
all pass.

## 4.29.0 — Release B: execution engineering (ENH-004…011)

Adds execution discipline as reusable capabilities. All additive; existing skills and advisory-mode
behaviour unchanged.

- **ENH-004 TDD** — new skill `/aidlc-tdd`: red (failing test + captured evidence) → green (captured
  pass) → refactor → regression; policy-logged exceptions. Wired into `/aidlc-sprint` and
  `/aidlc-refactor`. Claims require the red/green evidence.
- **ENH-005 Systematic debugging** — new skill `/aidlc-debug`: reproduce → evidence → localize →
  test a root-cause hypothesis → smallest fix → regression test → verify + no collateral; stuck-rule
  escalation. Covers app bugs, failing/flaky tests, integration and CI/CD failures.
- **ENH-006 Implementation planning** — `references/implementation-plan.md`: per-story plan fields
  (files, changes, tests, dependencies, risk class, verification commands, completion criteria); wired
  into the Sprint Plan. No new approval gate for trivial work.
- **ENH-007 Verify-before-completion** — new skill `/aidlc-verify-completion` + `references/verification-checklist.md`:
  PASS/FAIL/NOT-RUN/N-A with evidence; **never** treats an unexecuted test as passed or claims an
  unconfirmed merge. Distinct from `/aidlc-verify` (spec readiness).
- **ENH-008 Two-stage review** — `/aidlc-review` now runs explicit **Stage 1 spec compliance** then
  **Stage 2 engineering quality**, with fresh-model/specialist reviewers and an explicit
  "reviewer never replaces the human approver" rule.
- **ENH-009 Context isolation** — reinforced via the companion-skill split + execution-rigor §3/§5
  (briefs, worktrees).
- **ENH-010 Context-rot prevention** — `references/task-handoff.md`: read context before coding; keep a
  compact handoff summary; prune as you add. Wired into `/aidlc-sprint`.
- **ENH-011 Skill structure** — `references/skill-structure.md` sets the lean-skill convention; new
  skills follow it; legacy skills converge incrementally (no requirement deleted).

New Cursor rules: `aidlc-tdd.mdc`, `aidlc-debug.mdc`, `aidlc-verify-completion.mdc`; lifecycle-gate
command table, sprint/review rules, and README references list updated. Guardrail hook suite unchanged
(still 38/38).

## 4.28.1 — Release A hardening follow-ups (review findings)

Closes three enforced-mode gaps found in review; advisory behaviour unchanged.

- **No unbound approvals under enforced.** A manifest-bound approval (payload digest via
  `propose.sh`) is now **mandatory** in enforced mode — a bare "yes" or prompt-hint-only approval no
  longer authorises any write (that lenient tier remains only under advisory + `approvalBinding`).
- **Fail closed on malformed input.** `publish-gate.sh` and `secret-scan.sh` now **deny** unparseable
  tool input under enforced governance (via `input_is_json` in `common.sh`); advisory stays
  non-blocking; valid read-only calls are unaffected.
- **Extended Bash publishing coverage.** Under enforced, the gate also catches `glab api`, `gh`
  writes, `git push`, and `curl`/`wget` mutating HTTP to tracker hosts; advisory keeps the base set.
- Tests grew **24 → 38** cases (new: manifest wrong-digest/cross-target/expired, enforced
  unbound-deny, malformed fail-closed, Bash alternative forms, advisory compat, enforced e2e). All pass.

## 4.28.0 — Release A: governance & security hardening (ENH-001/002/003)

Hardens the existing guardrail-hook layer. **Fully backward-compatible:** new behaviour is off by
default (`governanceMode: advisory`, `approvalBinding: false`) — existing projects are unchanged until
they opt into `enforced`.

- **ENH-001 Action-specific approval.** Approvals can now bind to a single operation instead of a
  generic time-boxed token. `hooks/approval-capture.sh` records a bound, single-use, expiring approval
  (from a `propose.sh` manifest — backend + target + payload digest — or from prompt target/backend
  hints); `hooks/publish-gate.sh` requires the actual write to match and consumes it on use; new
  `hooks/propose.sh` records the pending operation. Approving one Jira story can't authorise another;
  a Confluence approval can't authorise a GitLab write; expired/reused/mismatched/missing → fail
  closed. Legacy token path retained for advisory mode.
- **ENH-002 Governance modes.** New `GOVERNANCE_MODE` (`advisory | enforced`). Under `enforced`, the
  **protected** gates (publish gate, secret scan) are forced to block and **cannot be downgraded** by
  a per-gate `off`/`warn` or `GUARDRAILS_ENABLED=false`; approvals become action-bound. Helpers
  `effective_mode` / `protected_active` in `common.sh`.
- **ENH-003 Hook tests.** New `plugins/aidlc/tests/run.sh` — 24 pure-bash cases (no live writes):
  legacy + action-bound publish paths, cross-target/cross-backend denial, expiry/replay/single-use,
  the enforced no-downgrade guarantee, secret-scan protection, malformed-input robustness, read-tool
  pass-through, and approval binding/manifest promotion. **All 24 pass.**
- Config: `guardrails.governanceMode` + `guardrails.approvalBinding` added to
  `aidlc.config.example.yaml`, `guardrails.defaults.env`, and `/aidlc-init`'s env generation;
  `references/guardrails.md` documents the model + migration.

## 4.27.0

**Added — Guardrails (enforced hooks).** Converts load-bearing AI-DLC rules from prose into
`hooks.json` command hooks under `plugins/aidlc/hooks/` (auto-discovered; need only bash + jq).
See `references/guardrails.md`.

- **Publish gate (HP-2, block):** `PreToolUse` blocks tracker writes (Jira/Confluence MCP tools and
  `glab`/`acli`/`jira` via Bash) unless the user gave an explicit go. Approval is captured by HP-1
  (`UserPromptSubmit`) as a short-lived token (`PUBLISH_GATE_TTL`, default 600s; strong phrases
  approve at any length, weak imperatives only in a short message). Fails closed.
- **EARS validation (HP-3, warn):** flags acceptance-criteria lines on an AC-catalogue publish that
  lack an EARS keyword (WHEN/IF-THEN/SHALL/WHILE/WHERE).
- **Secret scan (HP-4, block):** blocks tool arguments containing a credential pattern
  (GitHub/Slack/AWS/Google/OpenAI tokens, private keys). Block-not-scrub under classic hooks.
- **Transfer sentinel (HP-5, off by default):** flags a Jira leaf missing labels / estimate / AC ref.
- **Status banner (HP-6):** SessionStart note that guardrails are active and in which mode.
- **Config:** `guardrails:` block in `aidlc.config.example.yaml`, mirrored to
  `<project>/.aidlc/guardrails.env` (the env file the scripts read). Every guardrail is block/warn/off.
- **`/aidlc-init` wiring:** the init skill now captures the `guardrails:` block and writes
  `<project>/.aidlc/guardrails.env` from it, so new projects get the hooks configured on setup
  (falls back to shipped defaults when the block is absent).


## 4.22.0

**Added — agentic-engineering competencies (bridges the CodeWalnut "12 competencies" gaps).** All
additive; no existing behavior removed.

- **Agent toolchain & repo-context bootstrap** (`references/agent-toolchain.md`, wired into
  `/aidlc-init`): scaffold the target repo's `AGENTS.md`/`CLAUDE.md`, deny rules, PreToolUse hooks,
  least-privilege CLI/MCP, and `architecture.md`/repo-map/`conventions.md` — diff-and-approve, never
  overwrite. (Comp 1 + 3)
- **Evidence-led PRs** (`references/evidence-led-pr.md`): the evidence ladder + PR evidence pack;
  `/aidlc-review` now requires the pack and treats a missing one as a finding. (Comp 8)
- **Test reliability** (`references/test-reliability.md`): reliable locators, auto-wait, deterministic
  mocks, permission/negative-path coverage, mutation testing; wired into `/aidlc-sprint`,
  `/aidlc-design`, `/aidlc-verify`. (Comp 4)
- **Token economics** (`references/token-economics.md`): per-role model dispatch, context hygiene,
  pointers-not-payloads; wired into `/aidlc-sprint`. (Comp 10)
- **execution-rigor §5 (git-worktree parallel isolation)** and **§6 (review depth: fresh-agent/
  different-model reviewer, security/a11y/perf specialist subagents, review memory)**. (Comp 6 + 9)
- **New skill `/aidlc-refactor`** — test-first characterization refactoring for brownfield/tech-debt
  (Characterize → Change → Verify → Commit; preserve external contracts; Strangler for legacy). (Comp 11)
- **New skill `/aidlc-retro`** — session/sprint retrospective that drafts rule/skill/hook/constitution
  fixes for human approval (capture → analyze → draft → approve → prune). (Comp 12 + Skill-Packaging)

Mirrored across Claude skills/references and Cursor `.mdc` rules (+ two new rules, lifecycle-gate
command table, README references list).

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
