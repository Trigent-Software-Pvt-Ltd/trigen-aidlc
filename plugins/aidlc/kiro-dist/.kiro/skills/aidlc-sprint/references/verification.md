# Verification-before-completion checklist

Run this before declaring the ticket done. It verifies the *implementation* is actually complete and
safe to merge — distinct from spec readiness.

> **Hard rule:** never treat an unexecuted test as passed, and never claim a merge, deployment, or
> status change without confirming the actual result. If you did not run it, it is `NOT RUN`.

## Report format
Report **each** item as `PASS` / `FAIL` / `NOT RUN` / `N/A`, each with **evidence** (a command + its
result, a link, a file:line). No bare assertions.

| # | Item | Evidence required |
|---|------|-------------------|
| 1 | Acceptance criteria satisfied | each `AC-*` → the test/result that demonstrates it |
| 2 | Relevant tests executed and passed | the command(s) run + pass output (not "should pass") |
| 3 | Negative & permission paths covered | the failing-input / unauthorized tests and their results |
| 4 | Security & quality checks passed | secret scan / lint / SAST results |
| 5 | No unresolved blocking defects | open P0/P1 list for this scope (ideally empty) |
| 6 | Code self-reviewed to risk | diff reviewed; risky areas called out |
| 7 | Docs updated where needed | the doc/README/ADR change, or `N/A` with reason |
| 8 | PR / CI status verified | the actual PR state + CI result — confirmed, not assumed |
| 9 | Ticket status moved (or handed off) | the transition done over MCP, or the exact manual step given |

## Verdict
- **COMPLETE** only when every applicable item is `PASS` (or justified `N/A`).
- Any `FAIL`, or an unjustified `NOT RUN` on an applicable item ⇒ **NOT COMPLETE**: return to the TDD
  loop. Do not report done or open the PR as final.

## Scaling
Small change: items 1–3 + 8. Standard: 1–9.
