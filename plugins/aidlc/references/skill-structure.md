# Skill structure convention (ENH-011)

Primary skills should stay lean so a session loads orchestration, not an encyclopedia. A large
`SKILL.md` re-bills tokens every turn and buries the load-bearing steps. Each primary skill should
focus on:

1. **When to activate** (triggers / preconditions).
2. **Preconditions** — what must already exist.
3. **Workflow orchestration** — the ordered steps and their gates.
4. **Required outputs** — the artifacts it must produce.
5. **Human gates** — where approval is required.
6. **Exit criteria** — when the skill is done.
7. **References** — links to the supporting detail.

Move **detailed templates, examples, backend-specific procedures, and rubrics into `references/`** and
link them. The skill says *what and when*; the reference holds *the full how*.

> **Safety rule for any slimming pass:** preserve functionality and terminology. **Do not shorten a
> skill by deleting a requirement** — only *relocate* detail into a reference and link it, verifying the
> requirement is still reachable. If in doubt, leave it in place.

## Status / rollout

New skills in this plugin (`aidlc-tdd`, `aidlc-debug`, `aidlc-verify-completion`, `aidlc-refactor`,
`aidlc-retro`) are authored to this shape from the start. The larger legacy skills (`aidlc-design`,
`aidlc-verify`) already push much detail into `references/` (task-spec, planning-shared, review-criteria,
test-classification, work-item-template, …); further slimming is done **incrementally and
behaviour-preservingly**, one reference extraction at a time with the full suite run after each, rather
than in a single large rewrite — to avoid dropping a requirement. Treat this file as the standard new
skills must meet and existing skills converge toward.
