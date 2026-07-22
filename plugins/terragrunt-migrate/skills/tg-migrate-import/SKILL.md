---
name: tg-migrate-import
description: "Phase 4: Generate and execute import scripts to bring existing Azure resources under Terragrunt state management. Creates per-environment import.sh scripts, requires human approval before execution. Only modifies Terraform state after explicit confirmation."
argument-hint: "<target_repo_path> <env_key>"
---

# Phase 4: State Import

You are the migration orchestration assistant performing Phase 4 state import.

Arguments: `$1` = target repo path, `$2` = env_key (e.g. `us-centralus-dev`)

## Steps

1. **Check migration state** using `migration_get_state` with `target_path = "$1"`:
   - Ensure this environment is marked as populated before proceeding

2. **Identify resources to import**:
   - For each service in this environment, determine the Azure resource IDs
   - Cross-reference legacy `environment.auto.tfvars` and Azure portal as needed
   - Map each resource to its Terragrunt resource address (e.g. `azurerm_key_vault.this`)

3. **Generate import script** using `migration_generate_import`:
   - `target_path`: `$1`
   - `env_key`: `$2`
   - `imports`: map of service → list of `{address, id}` pairs
   - Creates `import-scripts/<env_key>.sh` with `cd` + `terragrunt import` commands per service

4. **Present the script** for human review

## Import Address Convention

```hcl
# Primary resources
azurerm_resource_type.this → /subscriptions/.../resourceGroups/.../providers/...

# Count-indexed resources (is_secondary pattern)
azurerm_resource_type.this[0] → same ID
```

## Checkpoint

Present the generated import script and STOP:
> "Import script generated for `$2`. Please review the resource mappings. Authenticate to Azure (`~/.secrets/azlogin.sh <sub>`) then run the script?"

**Only execute after explicit user approval.** The import modifies Terraform state.

After execution, report:
- Success/failure per resource
- Any resources that failed to import (with error messages)

Mark env as imported using `migration_update_state` with `env_key = "$2"` and `env_action = "imported"`.
