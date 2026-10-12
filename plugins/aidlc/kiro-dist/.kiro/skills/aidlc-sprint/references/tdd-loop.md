# TDD loop — red → green → refactor (with evidence)

Build one behaviour test-first. The point is not ceremony: it is that the test demonstrably **failed
for the right reason** before the code existed, and demonstrably **passes** after. Do not claim TDD
compliance without the failing-stage and passing-stage evidence.

## Preconditions
- An acceptance criterion (`AC-*`) for the behaviour. If it's vague, stop — clarify first.
- The covering **test command** (from the project's `AGENTS.md` / README, or ask the user).

## The loop (one behaviour at a time)
1. **Read** the AC and the behaviour to build — include negative and edge cases.
2. **Red — write a failing test** encoding the behaviour. Use reliable locators, deterministic mocks,
   and auto-waiting assertions so the test isn't flaky.
3. **Run it and capture the failure** — record the exact command and the failing output. A test that
   passes before any code exists, or errors for the wrong reason (compile/import), is **not a valid
   red** — fix the test first.
4. **Green — implement the minimum** to make it pass. No extra scope.
5. **Run it and capture the pass** — record the command and the passing output.
6. **Refactor** — improve structure while the test stays green; never change expected behaviour here.
7. **Regression** — run the relevant suite; keep it green before the next behaviour.

Repeat per behaviour.

## Evidence to record (for the verification gate + PR)
- The **failing-stage** evidence: command + failing output.
- The **passing-stage** evidence: command + passing output.
- The test(s), each **mapped to the `AC-*`** it proves.
- A **green regression** run.

## Reliable tests (avoid flakes)
- Assert on stable, meaningful locators/values — not incidental markup or ordering.
- Mock external systems deterministically; no real network/time/randomness in unit tests.
- Cover the **negative and permission paths**, not just the happy path.
- If coverage looks thin, add the missing case rather than loosening the assertion.

## Exceptions (logged, not silent)
For docs-only changes, generated code, or genuinely untestable glue, a TDD exception may be taken **if
project policy allows** — record *why* in the task notes. An exception is a logged decision, never a
quiet skip.

## Exit criteria
Every targeted AC has a test shown red then green; the regression suite is green; evidence is recorded.
