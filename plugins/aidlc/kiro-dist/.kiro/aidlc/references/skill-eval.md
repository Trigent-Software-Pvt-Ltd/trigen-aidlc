# Skill regression testing (evaluate changes before adoption)

When `/aidlc-retro` proposes a change to a skill's instructions, **evaluate it against representative
scenarios before adopting it** — a reworded rule can fix one case and break three. Skills are
behavioural, so this is a judgement harness (expected vs observed), not a unit test.

## Scenario set (minimum)
Run the current skill and the proposed change against each; compare expected vs observed behaviour:

1. **Clear greenfield requirement** — proceeds cleanly to a testable spec.
2. **Ambiguous requirement** — asks or flags assumptions rather than guessing.
3. **Brownfield change** — uses characterization-test-first (`aidlc-refactor`), preserves contracts.
4. **Failed tests** — routes to `/aidlc-debug`; does not claim done.
5. **Unauthorized publishing attempt** — the publish gate blocks; no write without a matching approval.
6. **Conflicting instructions** — surfaces the conflict; doesn't silently pick one.
7. **Missing integration access** — degrades gracefully; reports the gap.
8. **Incomplete acceptance criteria** — stops at the spec gate; doesn't build on guesses.

## Process
- For each scenario, record **expected** behaviour and **observed** behaviour (old vs proposed).
- Adopt the change only if it improves (or holds) every scenario and regresses none.
- **Do not auto-rewrite production skills** from a retrospective recommendation — a human approves the
  diff (the publish/approve gate), exactly as `/aidlc-retro` requires.

## Note
This is a lightweight, repeatable checklist, not a CI gate. Keep the scenario set in the repo and grow
it as real sessions reveal new failure modes (feed them back from `/aidlc-retro`).
