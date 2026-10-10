# Sprint 0 readiness

Before the first delivery sprint, confirm the project is actually ready — and record it. This extends
`/aidlc-init` (not a new lifecycle stage): once config + Constitution + agent toolchain exist, run the
readiness pass and write an **auditable report** to `.aidlc/readiness-report.md`.

## Checklist (report each: READY / GAP / N-A + a note)

1. **Project type** — greenfield or brownfield (changes how design/refactor apply).
2. **Repository & architecture context** — repo(s) identified; `architecture.md` / repo map present
   (see `agent-toolchain.md`); for brownfield, the behaviour-net stance is known (`aidlc-refactor`).
3. **Project instructions** — `context.md` / `AGENTS.md` / `CLAUDE.md` present where applicable.
4. **Roles & approval ownership** — who approves intent, design, and publishing/merge (the human gates).
5. **Integration readiness** — backend reachable (Jira/Confluence/GitLab/Linear); auth present;
   issue-type mapping valid (`aidlc.config.yaml`).
6. **Baseline engineering & delivery metrics** — what "normal" looks like today (cycle time, test pass
   rate, coverage) so improvement is measurable; where QMetry360 events will land (`qmetry360-events.md`).
7. **Quality & release gates** — guardrail governance mode (advisory/enforced), required checks, the
   definition of done (`verification-checklist.md`).
8. **Initial sprint readiness** — at least one feature has a PRD/brief with testable AC ready to elaborate.

## Output
`.aidlc/readiness-report.md` listing each item with status + evidence, a summary verdict
(READY / READY-WITH-GAPS / NOT-READY), and the gaps to close. It informs; it does not auto-start a
sprint. Re-run when the project materially changes.

## Note
Prefer enforcing these through existing `/aidlc-init` rather than adding a redundant stage. If a GAP is
a **mandatory** security/compliance item, treat it per `risk-governance.md` — a high readiness score
does not override a failed mandatory gate.
