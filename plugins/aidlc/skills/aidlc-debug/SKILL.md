---
name: aidlc-debug
description: Systematic debugging — reproduce, gather evidence, localize the failure, form and test root-cause hypotheses, make the smallest justified fix, add a regression test, and confirm the issue is resolved without breaking related behaviour. Avoids speculative edit sprees. Use for bugs, failing tests, integration failures, and CI/CD issues. (Triggers - debug, fix the bug, why is this failing, root cause, failing test, flaky, ci failure, integration failure, stack trace)
---

# AI-DLC Systematic Debugging

Find the cause before changing code. A sequence of speculative edits usually hides the bug rather than
fixing it. Work the evidence; make the smallest correction the evidence justifies; prove it.

## When to use
Application bugs, failing/flaky tests, integration failures, and CI/CD pipeline issues.

## The workflow
1. **Reproduce** — get a reliable, minimal repro (exact inputs, environment, command). If you can't
   reproduce it, say so and gather more evidence before changing anything.
2. **Gather evidence** — logs, stack traces, error messages, failing assertion, recent diffs, the data
   at the failure point. Read; don't guess.
3. **Localize** — narrow to the failure boundary (which layer/module/function). Bisect (code, commits,
   or inputs) to shrink the search space.
4. **Hypothesize & test** — state the most likely root cause as a falsifiable hypothesis, then test it
   (a probe, a log, a unit test) **before** fixing. Confirm or discard; don't stack guesses.
5. **Smallest fix** — implement the minimal change the confirmed cause justifies. Avoid opportunistic
   refactors in the same change (raise them separately).
6. **Regression test** — add a test that fails on the old code and passes on the fix, so the bug can't
   return (`references/test-reliability.md`).
7. **Verify the original issue** — re-run the repro; confirm it's gone.
8. **Confirm no collateral** — run the relevant suite; confirm related behaviour is unaffected.

## Stuck rule
After repeated unsuccessful attempts, **stop and reassess the root cause** — the hypothesis is probably
wrong. Widen evidence, question assumptions, and escalate to a human with the repro, the evidence, and
what's been ruled out. Do not keep editing hopefully.

## Required outputs
- The repro, the confirmed root cause (with the evidence that confirmed it), the minimal fix, the
  regression test (red→green), and the clean suite run.

## Exit criteria
Original issue reproduced then resolved; a regression test guards it; the suite is green; root cause is
recorded (feed a recurring pattern to `/aidlc-retro`).

## References
- @${CLAUDE_PLUGIN_ROOT}/references/test-reliability.md — the regression test must be reliable.
- @${CLAUDE_PLUGIN_ROOT}/references/execution-rigor.md — context hygiene, review of the fix.
- @${CLAUDE_PLUGIN_ROOT}/references/verification-checklist.md — confirm-before-done.
