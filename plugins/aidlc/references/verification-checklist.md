# Verification-before-completion checklist

The gate `aidlc-verify-completion` runs before implementation work is declared done. It is **distinct
from `/aidlc-verify`** (which assesses *specification* readiness before build); this verifies the
*implementation* is actually complete and safe to merge.

> **Hard rule:** never treat an unexecuted test as passed, and never claim a merge, deployment, or
> integration update without confirming the actual result. If you did not run it, it is `NOT RUN`.

## Report format

Report **each** item as one of `PASS` / `FAIL` / `NOT RUN` / `N/A`, each with **evidence** (a command
+ its result, a link, a file:line, a screenshot). No bare assertions.

| # | Item | Evidence required |
|---|------|-------------------|
| 1 | **Acceptance criteria satisfied** | each `AC-*` → the test/result that demonstrates it |
| 2 | **Relevant tests executed and passed** | the command(s) run + pass output (not "should pass") |
| 3 | **Negative & permission paths covered** | the failing-input / unauthorized tests and their results |
| 4 | **Security & quality checks passed** | SAST / secret scan / lint results (links) |
| 5 | **No unresolved blocking defects** | open P0/P1 list for this scope (ideally empty) |
| 6 | **Code reviewed to risk** | two-stage review verdicts (`execution-rigor.md` §4); specialist passes for HIGH risk |
| 7 | **Docs updated where needed** | the doc/ADR/README change, or `N/A` with reason |
| 8 | **PR / merge status verified** | the actual PR state + CI result — confirmed, not assumed |
| 9 | **Required human approvals recorded** | the approval(s); for tracker writes, the bound approval |
| 10 | **Evidence pack present on the PR** | per `evidence-led-pr.md` |

## Verdict

- **COMPLETE** only when every applicable item is `PASS` (or justified `N/A`).
- Any `FAIL` or an unjustified `NOT RUN` on an applicable item ⇒ **NOT COMPLETE**; return to the fix
  loop (`execution-rigor.md` §4), do not report done.

## Scaling
Quick: items 1–3 + 8. Standard: 1–9. Deep: all, with specialist security/a11y/perf evidence (item 6)
and release/rollback notes.
