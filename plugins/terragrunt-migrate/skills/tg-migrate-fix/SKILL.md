---
name: tg-migrate-fix
description: "Utility: Apply bulk changes across all populated environments. Always dry-runs first and shows exact before/after diffs before applying. Supports find/replace, input value updates, and adding new inputs. Use when a correction must be propagated to all terragrunt.hcl files."
argument-hint: "<target_repo_path> <description>"
---

# Bulk Fix Utility

You are the migration orchestration assistant performing a bulk fix across all populated environments.

## Purpose
This addresses the key pain point: when a correction is needed, it must be applied to ALL terragrunt.hcl files. This automates that.

## Input
Parse `$ARGUMENTS` as: `<target_path> <description>`

The description should explain what needs to change. Examples:
- "Replace mock_outputs_allowed_terraform_commands list with canonical version"
- "Add new input 'sku_name' with value 'standard' to all keyvault services"
- "Change provider version from ~> 3.0 to ~> 4.0"

## Steps

1. **Understand the change** from the description
2. **Choose the right tool**:
   - Simple find/replace: `migration_bulk_replace`
   - Update a specific input value: `migration_bulk_update_input`
   - Add a new input: `migration_bulk_add_input`
3. **Run in dry-run mode first** — always (`dry_run: true`)
4. **Present the dry-run results**:
   - Files that would be modified
   - Before/after values
   - Total count
5. **Get explicit approval** before applying (`dry_run: false`)

## Safety

- ALWAYS dry-run first
- Show exact changes before applying
- Confirm count of files to be modified
- Offer to exclude specific environments if needed

## Example Patterns

### Replace a string everywhere
```
migration_bulk_replace:
  search: 'mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]'
  replace: 'mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "import", "show", "apply"]'
  dry_run: true
```

### Update an input across services
```
migration_bulk_update_input:
  input_key: "sku_name"
  new_value: '"standard"'
  services: ["keyvault"]
  dry_run: true
```

### Add a new input
```
migration_bulk_add_input:
  input_key: "new_setting"
  value: '"value"'
  services: ["storage"]
  dry_run: true
```

After applying, report the total changes made.
