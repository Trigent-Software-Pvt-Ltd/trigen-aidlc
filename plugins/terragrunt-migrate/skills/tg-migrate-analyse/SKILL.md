---
name: tg-migrate-analyse
description: "Phase 1: Analyse a legacy Terraform repo and produce a migration plan. Parses repo structure, modules, variables, cross-stack dependencies, and GitLab CI/CD variables. Outputs a structured plan with service decomposition, environment scope, and risk assessment."
argument-hint: "<legacy_repo_path>"
---

# Phase 1: Analyse Legacy Repo

You are the migration orchestration assistant performing Phase 1 analysis.

The legacy repo path is: `$ARGUMENTS`

## Steps

1. **Initialise migration state** using `migration_init_state`:
   - `repo_name`: derived from the repo directory name
   - `source_path`: the legacy repo path (`$ARGUMENTS`)
   - `target_path`: ask the user if not provided, or derive as a sibling directory ending in `-terragrunt`

2. **Parse the legacy repo** using `migration_analyse_repo` with `repo_path = "$ARGUMENTS"`:
   - Runs all four analysers in one call (structure, modules, variables, cross-stack)
   - Returns combined analysis

3. **Fetch GitLab CI/CD variables** using `migration_fetch_gitlab_vars`:
   - `project_id`: from the GitLab project (search GitLab if needed)
   - Include group and subgroup IDs for inherited variables

## Output Format

Present the analysis as a structured migration plan:

### Repo Summary
- Repo name, standard layout (yes/no), number of .tf files
- Resource types found, module calls, data sources

### Proposed Service Decomposition
- Map legacy modules/resources to Terragrunt service directories
- Show the suggested `_modules/` and `_envcommon/` structure

### Environment Scope
- Which of the 13 standard environments are present in this repo
- Any environments that are NOT present (not all repos use all 13)

### Variable Analysis
- Environment-specific vs constant variables
- Secret mappings (tfvar template name ← CI/CD env var name)

### Cross-Stack Dependencies
- Remote state references to other stacks
- Required dependency blocks for `_envcommon`

### CI/CD Variables
- Variables fetched from GitLab (grouped by project/subgroup/group scope)
- Which will become `get_env()` calls in Terragrunt

### Risk Assessment
- `southcentralus/prod` special cases (if applicable)
- `is_secondary` pattern requirements (if applicable)
- Any non-standard patterns detected

## Checkpoint

After presenting the plan, STOP and ask the user:
> "Please review the migration plan above. Do you want to proceed to Phase 2 (Scaffold), or would you like to adjust the service decomposition or dependencies?"

Mark Phase 1 complete using `migration_update_state`.
