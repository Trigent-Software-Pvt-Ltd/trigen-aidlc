---
name: tg-migrate-populate
description: "Phase 3: Populate one environment with real values, replacing __PLACEHOLDER__ entries. Sources values from legacy environment.auto.tfvars, backend.hcl, and secrets.tfvars.tmpl. Run once per environment across all 13 standard envs."
argument-hint: "<target_repo_path> <env_key>"
---

# Phase 3: Populate Environment

You are the migration orchestration assistant performing Phase 3 population for a single environment.

Arguments: `$1` = target repo path, `$2` = env_key (e.g. `us-centralus-dev`, `uk-uksouth-prod`)

## Steps

1. **Check migration state** using `migration_get_state` with `target_path = "$1"`:
   - Ensure scaffold (Phase 2) is complete before proceeding

2. **Gather real values** for this environment:
   - Read the legacy `envs/<region>/<location>/<env>/environment.auto.tfvars` from the source repo
   - Read the legacy `envs/<region>/<location>/<env>/backend.hcl`
   - Read the legacy `envs/<region>/<location>/<env>/secrets.tfvars.tmpl` for `get_env()` mappings
   - Look up actual Azure resource names if needed

3. **Populate the environment** using `migration_populate_env`:
   - `target_path`: `$1`
   - `env_key`: `$2`
   - `values`: map of service → dict of placeholder_name → real_value
   - Replaces `__PLACEHOLDER__` values with real resource names, IDs, and configurations

4. **Check for remaining placeholders** — search the populated env dirs for any `__PLACEHOLDER__` strings still present and report them

## Value Sources

| Placeholder type | Source |
|-----------------|--------|
| Resource names | Legacy `environment.auto.tfvars`, or Azure portal |
| Resource group names | Legacy config |
| tfstate config | Legacy `backend.hcl` |
| Secrets | `secrets.tfvars.tmpl` → `get_env("ENV_VAR", "")` |
| `is_secondary` | `true` for eastus2 and ukwest; `false` otherwise |

## Checkpoint

After populating, present:
- Summary of replacements made per service
- Any remaining `__PLACEHOLDER__` values that need manual input
- Key file diffs

Then STOP and ask:
> "Environment `$2` populated. Review the `terragrunt.hcl` files. Ready to proceed to the next environment, or need adjustments?"

Mark env as populated using `migration_update_state` with `env_key = "$2"` and `env_action = "populated"`.
