---
name: tg-migrate-pipeline
description: "Phase 6: Generate CI/CD pipeline configuration and optionally ci-local-vars for gitlab-ci-local testing. Covers all 13 standard environments. Final phase before the migrated repo is ready to commit."
argument-hint: "<target_repo_path> [project_id]"
---

# Phase 6: Pipeline Cutover

You are the migration orchestration assistant performing Phase 6 pipeline setup.

## Input
Parse `$ARGUMENTS` as: `<target_path> [project_id]`

`project_id` is the GitLab numeric project ID — required for `migration_generate_ci_local_vars`. If not provided, ask the user.

## Steps

1. **Generate .gitlab-ci.yml** using `migration_generate_pipeline`:
   - Creates pipeline configuration for all 13 environments
   - References the shared Terragrunt pipeline template from devsecops/terraform-modules
2. **Optionally generate ci-local-vars** using `migration_generate_ci_local_vars`:
   - Ask the user if they want local CI testing support
   - If yes, generates `ci-local-vars/` directory with `global.yml` + per-env YAML files
   - Uses GitLab CI/CD variables fetched in Phase 1

## CI Local Vars Structure
```
ci-local-vars/
├── global.yml           # ARM credentials, simulated CI vars, global-scope vars
├── us-centralus-dev.yml # per-environment vars
├── us-centralus-staging.yml
├── ...
└── uk-uksouth-prod.yml
```

## Usage with gitlab-ci-local
```bash
gitlab-ci-local \
  --variables-file ci-local-vars/global.yml \
  --variables-file ci-local-vars/us-centralus-dev.yml \
  --ignore-predefined-vars CI_COMMIT_BRANCH,CI_DEFAULT_BRANCH,...
```

## Checkpoint

Present:
- Generated .gitlab-ci.yml contents
- ci-local-vars summary (if generated)

Then STOP and ask:
> "Pipeline configuration generated. Review the .gitlab-ci.yml and ci-local-vars (if applicable). Ready to commit?"

Update migration state using `migration_update_state` with `phase: "pipeline"`.
