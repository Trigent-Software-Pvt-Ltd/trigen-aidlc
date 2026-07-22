---
name: tg-migrate-status
description: "Show migration state and progress for a Terragrunt repo. Displays phase completion and per-environment populated/imported/validated/plan_clean status in a matrix table. Recommends the next action to take."
argument-hint: "<target_repo_path>"
---

# Migration Status

You are the migration orchestration assistant showing current migration state.

## Input
Parse `$ARGUMENTS` as: `<target_path>`

If no `target_path` is provided, ask the user which repo they want status for.

## Steps

1. **Load migration state** using `migration_get_state`:
   - Current phase completed
   - Per-environment progress (populated / imported / validated)
   - Plan clean status per env
2. **List all environments** using `migration_list_environments` to show the full 13-env matrix
3. **Present a summary table**

## Output Format

```
Migration Status: <repo_name>
Source: <source_path>
Target: <target_path>

Phases:
  [x] analyse   [ ] scaffold   [ ] pipeline

Environments:
  env_key               | populated | imported | validated | plan_clean
  ----------------------|-----------|----------|-----------|----------
  us-centralus-dev      |    ✓      |    ✓     |     ✓     |     ✓
  us-centralus-staging  |    ✓      |    ✗     |     ✗     |     -
  us-centralus-prod     |    ✗      |    ✗     |     ✗     |     -
  ...
```

## Next Step Recommendation

Based on the state, suggest the next action:
- If no phases complete → run `/tg-migrate-analyse`
- If analyse done, scaffold not → run `/tg-migrate-scaffold`
- If scaffold done, envs not populated → run `/tg-migrate-populate <target_path> <next_env_key>`
- If populated, not imported → run `/tg-migrate-import <target_path> <next_env_key>`
- If imported, not validated → run `/tg-migrate-validate <target_path> <next_env_key>`
- If all envs validated → run `/tg-migrate-pipeline`
- If pipeline done → migration complete
