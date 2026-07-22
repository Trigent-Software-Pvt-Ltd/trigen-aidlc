---
name: tg-migrate-help
description: "Show Terraform-to-Terragrunt migration tool usage, phase overview, available commands, environment matrix, and MCP server configuration. Use when starting a migration or needing a refresher on the workflow."
---

# Terraform → Terragrunt Migration Tool Help

You are the migration orchestration assistant. Explain the full migration workflow, available commands, and the MCP server tools.

## Migration Phases

The migration follows 6 phases with human checkpoints. Each phase has a dedicated slash command:

### Phase 1: Analyse (`/tg-migrate-analyse <legacy_repo_path>`)
**Purpose**: Parse the legacy Terraform repo and produce a migration plan.
**MCP Tools**: `migration_analyse_repo`, `migration_analyse_modules`, `migration_extract_variables`, `migration_analyse_cross_stack`, `migration_fetch_gitlab_vars`
**Output**: Structured analysis — modules, resources, variables, cross-stack deps, services
**Checkpoint**: Human reviews plan before proceeding

### Phase 2: Scaffold (`/tg-migrate-scaffold <legacy_repo_path> <target_repo_path>`)
**Purpose**: Generate the complete Terragrunt directory structure for all environments with `__PLACEHOLDER__` values.
**MCP Tools**: `migration_scaffold`, `migration_convert_modules`, `migration_generate_envcommon`, `migration_generate_pipeline`
**Output**: Full directory tree — `root.hcl`, `_modules/`, `_envcommon/`, env dirs, `.gitlab-ci.yml`
**Checkpoint**: Human reviews scaffold structure and module conversions

### Phase 3: Populate Environment (`/tg-migrate-populate <target_path> <env_key>`)
**Purpose**: Replace placeholder values with real values for ONE environment at a time.
**MCP Tools**: `migration_populate_env`
**Output**: Updated `terragrunt.hcl` files with real resource names, IDs, and configurations
**Checkpoint**: Human reviews the populated environment
**Repeat for each env in order**:
  1. us-centralus-dev → us-eastus2-dev → uk-uksouth-dev → uk-ukwest-dev
  2. us-centralus-staging → us-eastus2-staging → uk-uksouth-staging → uk-ukwest-staging
  3. us-centralus-prod → us-eastus2-prod → us-southcentralus-prod → uk-uksouth-prod → uk-ukwest-prod

### Phase 4: Import (`/tg-migrate-import <target_path> <env_key>`)
**Purpose**: Generate per-environment import scripts to bring existing Azure resources under Terragrunt management.
**MCP Tools**: `migration_generate_import`
**Output**: `import.sh` script in the environment directory
**Checkpoint**: Human approves script before execution

### Phase 5: Validate (`/tg-migrate-validate <target_path> <env_key>`)
**Purpose**: Run `terragrunt plan` and enforce the zero-destruction gate.
**MCP Tools**: `migration_validate_hcl`, `migration_run_plan`, `migration_check_zero_destruction`
**Output**: Plan results — PASS (0 destroy) or FAIL (resources would be destroyed)
**Gate**: Any destroy = FAIL. Fix import before retrying.

### Phase 6: Pipeline (`/tg-migrate-pipeline <target_path>`)
**Purpose**: Final pipeline cutover — generate `.gitlab-ci.yml` and optionally `ci-local-vars/`.
**MCP Tools**: `migration_generate_pipeline`, `migration_generate_ci_local_vars`
**Output**: `.gitlab-ci.yml` + optionally `ci-local-vars/` directory
**Checkpoint**: Human reviews pipeline configuration

## Utility Commands

### `/tg-migrate-fix <target_path> <description>`
Apply bulk changes across ALL populated environments. Always dry-runs first, then applies after approval.
**MCP Tools**: `migration_bulk_replace`, `migration_bulk_update_input`, `migration_bulk_add_input`

### `/tg-migrate-status <target_path>`
Check migration progress — which phases are complete, which environments are populated/imported/validated.
**MCP Tools**: `migration_get_state`

## MCP Server

The tools are served via `terragrunt-migration-server` (FastMCP), registered in `~/.config/opencode/opencode.jsonc`:

```jsonc
"terragrunt-migration": {
  "type": "local",
  "command": [
    "/path/to/.venv/bin/fastmcp",
    "run",
    "/path/to/mcp-server/terragrunt-migration-server/server.py"
  ]
}
```

## Environment Matrix (13 environments)

| Geo | Location | Tiers | Secondary? |
|-----|----------|-------|------------|
| us | centralus | dev, staging, prod | No (primary) |
| us | eastus2 | dev, staging, prod | Yes (DR for centralus) |
| us | southcentralus | prod only | No (standalone legacy) |
| uk | uksouth | dev, staging, prod | No (primary) |
| uk | ukwest | dev, staging, prod | Yes (DR for uksouth) |

## Quick Start

```
/tg-migrate-analyse /path/to/legacy-repo
/tg-migrate-scaffold /path/to/legacy-repo /path/to/new-repo
/tg-migrate-populate /path/to/new-repo us-centralus-dev
/tg-migrate-import /path/to/new-repo us-centralus-dev
/tg-migrate-validate /path/to/new-repo us-centralus-dev
# repeat populate/import/validate for all 13 envs
/tg-migrate-pipeline /path/to/new-repo
```

Present this information clearly. Offer to explain any specific phase in more detail.
