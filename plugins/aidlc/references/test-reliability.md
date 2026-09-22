# Test Reliability

Agents write tests in seconds; the risk is **cheap tests that are bad tests** — flaky, tied to brittle
selectors, or asserting details users never see. A green suite that never fails when it should is
worse than none: it trains the team to ignore red. This reference is *how* to make agent-generated
tests trustworthy. It complements TDD in `/aidlc-sprint` and the Test Scope in `/aidlc-design` /
`/aidlc-verify`.

## The pyramid (what to test where)

- **Unit** — fast behavior checks on business logic (short-code algorithm, `scopeSignature`, validation).
- **Integration** — service contracts (endpoint ↔ DB, grant-filter predicate, save + transition).
- **End-to-end** — critical user journeys only (create workspace → add sources → select scope).

Put most weight low; reserve E2E for journeys a user would notice breaking.

## Reliability rules (the craft)

- **Test behavior users notice, not implementation details.** If a refactor that preserves behavior
  breaks the test, the test was wrong.
- **Role-based locators, not brittle CSS/XPath** — the single biggest fix for UI flakiness.
- **Auto-waiting assertions** that retry until the UI is ready; **never fixed `sleep` timers.**
- **Independent tests** — no shared mutable state; they must pass in parallel without ordering.
- **Mock the flaky boundaries** — third-party APIs, payments, the clock — so tests are deterministic;
  **never mock away the thing under test.**
- **Record then refine** — capture a flow with codegen, then harden it (locators, assertions).
- **Permission & negative paths are tests too** — assert the `403`/out-of-grant/`409`/zero-item cases
  from the work item's AC, not just the happy path.

## Prove the coverage is real

- Map each **AC → at least one test** (the work item's Verification steps are the script).
- **Mutation testing** on the key flows: inject defects; the suite must catch them. "All green" only
  means something if the suite fails when behavior breaks.
- For refactoring work, characterization tests are the contract — see the refactoring lane.

## What mastery looks like
Tests fail for real regressions, not timing; the suite stays green across repeated CI runs; you would
trust it enough to refactor behind it.

## Toolkit
Playwright / Testing Library · role locators · auto-wait assertions · API mocks · fixtures ·
trace viewer · mutation testing.
