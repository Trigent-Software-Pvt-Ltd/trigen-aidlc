---
name: tg-migrate-scaffold
description: "Phase 2: Generate full Terragrunt scaffold with placeholder values. Creates root.hcl, all env directories, _modules/ (single-file convention), _envcommon/ with dependency chains, and .gitlab-ci.yml. All values use __PLACEHOLDER__ format until Phase 3."
argument-hint: "<legacy_repo_path> <target_repo_path>"
---

# Phase 2: Scaffold Generation

You are the migration orchestration assistant performing Phase 2 scaffolding.

Arguments: `$1` = legacy repo path, `$2` = target repo path

## Prerequisites
- Phase 1 analysis must be complete — load state with `migration_get_state` using `target_path = "$2"`
- User has approved the migration plan

## Steps

1. **Load migration state** using `migration_get_state` with `target_path = "$2"`

2. **Generate scaffold** using `migration_scaffold`:
   - `target_path`: `$2`
   - `stack_name`: from migration state (repo name)
   - `project_id`: GitLab project ID from migration state
   - `services`: list from Phase 1 service decomposition
   - Creates: `root.hcl`, all env directories, per-service subdirectories with placeholder `terragrunt.hcl`

3. **Convert modules** using `migration_convert_modules`:
   - `repo_path`: `$1`
   - `target_path`: `$2`
   - `services`: map of service name → list of resource types
   - `reference_path`: `/mnt/cvb-data/cpoms/Projects/platform-shared-services/terragrunt-migration-module-reference`
   - Transforms legacy `.tf` code into single-file `_modules/` pattern
   - Each module: single `main.tf`, all vars with defaults, `is_secondary` where needed

4. **Generate envcommon** using `migration_generate_envcommon`:
   - `target_path`: `$2`
   - `repo_path`: `$1`
   - `services`: list of service names
   - `service_dependencies`: map of service → dependency list from Phase 1
   - Creates `_envcommon/*.hcl` with dependency chains and `mock_outputs`
   - Sets `mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "import", "show", "apply"]`

5. **Generate pipeline** using `migration_generate_pipeline`:
   - `target_path`: `$2`
   - Creates `.gitlab-ci.yml` covering all environments present in this repo

## Key Rules
- ALL environments get placeholder values — no real values yet
- Placeholder format: `__PLACEHOLDER_{variable_name}__`
- `_modules/` must follow the single-file convention (`main.tf` only, no `provider`/`backend`/`version` blocks)
- All variables MUST have defaults
- `is_secondary = true` pattern for DR regions (eastus2, ukwest) where applicable

## Checkpoint

After scaffolding, present:
- Directory tree overview
- List of generated `_modules/` with resource types
- List of `_envcommon/` with dependency chains
- Any warnings or issues

Then STOP and ask:
> "Scaffold generated. Please review the structure, `_modules/`, and `_envcommon/` files. Ready to proceed to Phase 3 (Populate) with the first environment?"

Mark Phase 2 complete using `migration_update_state` with `phase = "scaffold"`.
