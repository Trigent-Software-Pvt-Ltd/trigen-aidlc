# Evidence-led PR

The PR is where a reviewer sees *what changed, why, and that it works* — without re-running everything.
Write it so the proof is in the description, not implied.

## PR title
`<JIRA-KEY>: <concise imperative summary>`  — e.g. `PROJ-123: add rate limiting to login endpoint`.

## PR body structure
1. **What & why** — one short paragraph. Link the ticket (`PROJ-123`) and restate the goal.
2. **Acceptance criteria → tests** — a short table mapping each `AC-*` to the test that proves it.
   | AC | Test | Result |
   |----|------|--------|
   | AC-1 | `test_login_rate_limited` | PASS |
3. **Evidence** — the red→green capture for the key behaviours and the **green regression run**
   (command + summarized output). State the exact test command used.
4. **Scope of change** — the files touched and anything intentionally left out.
5. **Risk & rollback** — call out migrations, config/flag changes, or data effects. If there is a
   schema/data migration, give the **rollback plan** (how to revert safely).
6. **CI** — link the pipeline and its status once it runs; confirm it, don't assume it.

## Rules
- No secrets anywhere in the diff or description.
- Keep the PR to the ticket's scope; unrelated cleanups go in their own PR.
- Do not mark the PR ready / request merge until the verification checklist is COMPLETE.
