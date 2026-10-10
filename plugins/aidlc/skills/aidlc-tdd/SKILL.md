---
name: aidlc-tdd
description: Test-Driven Development loop for a story or task — write a failing test first, capture the failure, implement the minimum to pass, capture the pass, refactor green, run regression. Produces evidence of the red and green stages. Used inside /aidlc-sprint and /aidlc-refactor; invoke directly to build one behaviour test-first. (Triggers - tdd, test driven, write the test first, red green refactor, test-first, failing test first)
---

# AI-DLC TDD

Build one behaviour test-first, with **evidence** of each stage. The point is not ceremony — it is that
the test demonstrably failed for the right reason before the code existed, and demonstrably passes
after. **Do not claim TDD compliance without the failing-stage and passing-stage evidence.**

## When to use
- Inside `/aidlc-sprint` for each implementation task, and inside `/aidlc-refactor` (characterization
  tests are the refactor's safety net).
- Directly, to add one behaviour to existing code test-first.

## Preconditions
- An approved story/task with acceptance criteria (`AC-*`). If the AC is vague, stop — spec first.
- Know the covering test command (from the implementation plan / project `AGENTS.md`).

## The loop (one behaviour at a time)
1. **Read** the AC and the behaviour to build, incl. negative and edge cases.
2. **Red — write a failing test** that encodes the behaviour (reliable locators, deterministic mocks,
   web-first/auto-wait assertions — see `references/test-reliability.md`).
3. **Run it and capture the failure** — record the command and the failing output. A test that passes
   before any code, or errors for the wrong reason (compile/import), is not a valid red; fix the test.
4. **Green — implement the minimum** to make it pass. No extra scope.
5. **Run it and capture the pass** — record the command and the passing output.
6. **Refactor** — improve structure with the test green; never change expected behaviour here.
7. **Regression** — run the relevant suite; keep it green before moving on.

Repeat per behaviour. Record red/green evidence in the task's report file / ledger so
`aidlc-verify-completion` can cite it.

## Exceptions (documented, policy-approved)
For documentation-only changes, generated code, or genuinely untestable glue, a TDD exception may be
taken **if project policy allows** — record *why* in the task notes. An exception is a logged decision,
not a silent skip.

## Required outputs
- The failing-stage evidence (command + output) and the passing-stage evidence.
- The test(s), mapped to the AC they prove.
- A green regression run.

## Exit criteria
Every targeted AC has a test that was shown red then green; the regression suite is green; evidence is
recorded for `aidlc-verify-completion`.

## References
- @${CLAUDE_PLUGIN_ROOT}/references/test-reliability.md — reliable, non-flaky tests + mutation testing.
- @${CLAUDE_PLUGIN_ROOT}/references/execution-rigor.md — fix-loop + review that consume this evidence.
- @${CLAUDE_PLUGIN_ROOT}/references/verification-checklist.md — where the red/green evidence is cited.
