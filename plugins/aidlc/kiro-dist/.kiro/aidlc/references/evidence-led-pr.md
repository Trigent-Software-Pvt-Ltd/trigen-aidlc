# Evidence-led PRs

Don't ask a reviewer to trust agent-written code. **Put the proof in the PR.** Merge confidence comes
from visible, reproducible evidence — not a green checkmark and "trust me." This is the build-time
complement to `/aidlc-review`: the PR carries the evidence, review makes the judgment call.

## The evidence ladder (each rung produces proof, cheapest first)

1. **Pre-commit** — format · lint · unit tests on changed files.
2. **Before push** — the changed paths' tests run; fast integration where relevant.
3. **Pull request** — intent stated, risk noted, evidence attached (below).
4. **CI/CD** — build + scans clean (SAST, secrets, dependency/look-alike-package check).
5. **Release** — owner + rollback plan (required when the change has migrations).

**Climb it in order.** Let CI produce the evidence pack automatically; leave humans the judgment
calls, not the evidence gathering.

## What a PR must show (the pack)

- **Intent** — what changed and *why*, so the reviewer understands before reading the diff. Link the
  work item (QI-xxx), the PRD FR ids, the Design Document, and any ADR it touches.
- **Test matrix** — which ACs are covered by which tests; unit/integration/E2E as applicable.
- **Results** — test output, coverage, screenshots/recordings for UI, profiles where perf matters.
- **Scans** — SAST / secret-scan / dependency results (link, not paste).
- **Boundaries confirmed** — no secrets/PII in code, logs, URLs; feature flags wired; permission
  checks server-side (per the feature's ADRs); rollback documented if migrations are present.
- **Residual risk** — what's still risky and what was deliberately deferred.
- **Reproducibility** — the exact command / seed / fixture so a reviewer can re-run any of it.

## Rules

- **Quality gates are deliverables**, not afterthoughts — the Definition of Done in
  `work-item-template.md` already asks for evidence; this makes it a first-class PR gate.
- Pass **diffs and issue lists** into review, not whole files (keeps review focused and cheap).
- A green check with no visible evidence still makes the reviewer do your work — **show the proof.**
- Ceremony-scaled: **Quick** = pre-commit + unit + a one-line intent; **Standard** = the full pack
  minus release-only items; **Deep** = the full ladder including release owner + rollback.

## Handoff to `/aidlc-review`

`/aidlc-review` (implementation path) checks the diff against the spec and the code quality; it should
**require the evidence pack to be present** and treat a missing/played-down pack as a finding, not
wave it through. Reviewers then approve-or-redirect instead of reconstructing intent and coverage.

## Toolkit
`gh`/`glab` CLI · CI artifacts · PR template · coverage report · Playwright traces · SAST/secret scan.
