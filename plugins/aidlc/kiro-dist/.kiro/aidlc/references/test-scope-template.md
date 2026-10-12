# Test Scope — the test documentation template

The Test Scope page is a **test document a QA engineer or reviewer can actually use**, not a list of
terse phrases. Each scenario must be a complete, understandable statement of what is tested, under
what conditions, and what the expected result is — so that a person who did not write it can execute
or review it without guessing. This reference defines the structure and the quality bar. It builds on
the layer-classification rules in `test-classification.md` (Unit / API / UI / E2E / Integration and
the no-gap / no-overlap rules) and the prose standard in `writing-style.md`.

## Structure of the page

Write the page in this order. Keep the narrative parts as short prose; use tables for the cases.

1. **Overview & approach** *(1–2 short paragraphs)* — what this plan covers, the testing strategy
   (the pyramid: mostly unit, fewer integration, least E2E — reserve E2E for journeys a user would
   notice breaking), and how coverage is assured (every acceptance criterion maps to at least one
   case).
2. **Scope** — what is in and out of test scope for this epic, in a sentence or two plus a short
   list if helpful.
3. **Test environment & data** — where tests run (local Docker services, mocked third parties,
   seeded fixtures), what data is needed, and which boundaries are mocked so tests are deterministic
   (never mock the thing under test).
4. **Test cases, grouped by sprint/area** — the heart of the document; see the case format below.
5. **Coverage matrix** — a table mapping each acceptance criterion (by id) to the case id(s) that
   cover it, so no-gap is visible at a glance.
6. **Exit criteria** — the conditions that mean testing is complete and the epic can ship (e.g. all
   High-priority cases pass, every AC covered, no open P0/P1 defects, mutation check passed on the
   key logic).

## Test-case format (complete, not cryptic)

Give **every case an id and write it as a readable row** with these columns. A reviewer should be
able to read one row and know exactly what to do and what to look for.

| Column | What goes in it |
|--------|-----------------|
| **ID** | Stable id, e.g. `TC-CYCLE-01`, grouped by area |
| **Title** | A plain-language sentence naming the behaviour under test |
| **Type** | Unit / API / UI / E2E / Integration (per `test-classification.md`) |
| **Priority** | High / Medium / Low (High = core happy path, security, or data integrity) |
| **Preconditions** | The state/data that must exist before the test runs |
| **Steps** | The action(s) performed — a short imperative sentence or a few numbered steps |
| **Expected result** | The observable outcome, with **concrete values** (status code, number, message, state) — not "works correctly" |
| **Covers** | The acceptance-criterion id(s) this case verifies (for the coverage matrix) |

For UI and E2E cases, name the user-visible action and what the user should see, in plain language
(no CSS selectors or internal identifiers). For API cases, give the request and the expected
response/status. Mark browser-requiring E2E cases explicitly (`requires_browser: true/false`).

### Worked example of one good case

| ID | Title | Type | Priority | Preconditions | Steps | Expected result | Covers |
|----|-------|------|----------|---------------|-------|-----------------|--------|
| TC-RHI-03 | Release Health Index excludes not-applicable metrics from the score | Unit | High | A release with 4 measured metrics (3 in band) and 2 marked not-applicable | Compute the index for the release | Score = 75 (3 of 4 measured in band); the 2 N/A metrics are excluded from numerator and denominator; coverage shows 4 of 6 expected | AC-RHI-002 |

Contrast that with the cryptic form to avoid — *"RHI excludes N/A; coverage shown"* — which tells a
reader neither the setup, the action, nor the number to expect.

## Quality bar (what a reviewer checks)

- **Every acceptance criterion is covered** by at least one case (no-gap), shown in the coverage
  matrix; and **no case is duplicated across layers** (no-overlap) — put each at the lowest layer
  that can test it reliably.
- **Every expected result is concrete and observable** — a value, a status, a state, a message — so
  pass/fail is mechanical.
- **Negative, edge and permission paths are present**, not just the happy path (invalid input,
  not-found, expiry, conflict, empty/zero state, unauthorised).
- **Cases read in plain language** a QA engineer can execute without the author present.
- **Determinism** — flaky boundaries (third-party APIs, the clock, payments) are mocked; role-based
  locators and auto-waiting are used for UI; see `test-reliability.md`.

## Backend note

Store this as a single **Test Scope** page per epic (see `artifact-consolidation.md`). If the project
uses a dedicated test-management tool (QMetry, Xray, Zephyr, qTest), this page is the human-readable
source these cases are mirrored into; keep the ids stable so the mirror is traceable.
