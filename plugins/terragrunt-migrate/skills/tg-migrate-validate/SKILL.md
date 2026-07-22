---
name: tg-migrate-validate
description: "Phase 5: Run terragrunt plan and enforce the zero-destruction gate. Validates HCL syntax, runs plans across all services, and gates on zero destroyed resources. Any destroy = FAIL — fix import before retrying."
argument-hint: "<target_repo_path> <env_key>"
---

# Phase 5: Validate

You are the migration orchestration assistant performing Phase 5 validation.

## Input
Parse `$ARGUMENTS` as: `<target_path> <env_key>`

## Steps

1. **Check migration state** using `migration_get_state` — ensure this environment has been imported (Phase 4)
2. **Run HCL validation** using `migration_validate_hcl`:
   - Syntax check all generated files
   - Structural integrity checks
3. **Run terragrunt plan** using `migration_run_plan`:
   - Plans all services in the environment
   - Captures add/change/destroy counts
4. **Enforce zero-destruction gate** using `migration_check_zero_destruction`:
   - **PASS**: No resources destroyed. Additions and changes are reviewed.
   - **FAIL**: Resources would be destroyed — import issue needs fixing.

## Gate Criteria

| Result | Action |
|--------|--------|
| 0 add, 0 change, 0 destroy | Perfect — state matches exactly |
| N add, 0 destroy | Acceptable — new Terragrunt-managed resources |
| N change, 0 destroy | Review — likely tag updates or drift |
| Any destroy | **FAIL** — fix import before proceeding |

## If Gate Fails

Report:
- Which services have destructive changes
- Specific resources that would be destroyed
- Suggested fix (re-import, adjust config)

Do NOT proceed. Ask the user to fix and re-run.

## If Gate Passes

Report:
- Per-service plan summary
- Any additions or changes to review
- Confirmation that zero-destruction gate passed

Update migration state using `migration_update_state` with `env_action: "validated"` and `plan_clean: true`.
