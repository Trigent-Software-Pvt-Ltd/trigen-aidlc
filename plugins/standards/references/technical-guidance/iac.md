---
owner: DevSecOps Chapter
last-reviewed: 2026-02-19
scope: Infrastructure as Code projects (Terraform + Terragrunt)
detection-markers:
  - root.hcl
  - terragrunt.hcl
  - "*.hcl"
  - "*.tf"
---

# IaC Project-Type Technical Guidance

Architectural standards for Infrastructure as Code projects using Terraform and Terragrunt targeting Azure. These extend the Global Technical Guidance.

## How to Use This Guidance

- Applies when a project contains IaC markers (`root.hcl`, `terragrunt.hcl`, `.tf` files)
- Extends Global Guidance; does not replace it
- Project-level guidance in the Intent doc may override specific standards
- Deviations require an ADR documenting the rationale

---

## Tool Versions

| Tool | New Projects | Existing Projects (minimum) |
|------|-------------|----------------------------|
| Terraform | 1.9+ | 1.5+ |
| Terragrunt | 0.67+ | 0.50+ |
| AzureRM provider | 4.x | 3.x |
| Azure CLI | Latest stable | — |

### Version Pinning

Pin the AzureRM provider in every module's generated `provider.tf` (via `root.hcl` `generate` block). Never use floating provider constraints:

```hcl
# root.hcl — generated provider.tf
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
EOF
}
```

---

## Project Structure

### Standard Directory Layout

Both repo types (shared platform infra and application stacks) share the same directory hierarchy:

```
root.hcl                        # Provider, remote state, common tags, shared inputs
azure/
  _modules/                     # Local native azurerm wrapper modules (see Module Strategy)
    <resource-type>/
      main.tf                   # Variables + Resources + Outputs in one file
  _azure/                       # Shared Terragrunt config templates (app-stack pattern)
    <resource-type>.hcl         # Reusable dependency + source declarations
  <region>/                     # e.g. uk, us
    region.hcl                  # region = "uk"
    <location>/                 # e.g. uksouth, eastus2
      location.hcl              # location = "uksouth"
      <env>/                    # e.g. dev, staging, prod
        env.hcl                 # environment, tfstate backend config
        <resource>/
          terragrunt.hcl        # Module inputs; inherits root + hierarchy HCL files
docs/
  adr/                          # Architecture Decision Records
```

### Configuration Hierarchy Files

| File | Defines | Scope |
|------|---------|-------|
| `root.hcl` | Provider, remote state backend template, common tags, shared `inputs` merge | Entire repo |
| `region.hcl` | `region` local (e.g. `"uk"`) | All locations within a region |
| `location.hcl` | `location` local (e.g. `"uksouth"`) | All envs within a location |
| `env.hcl` | `environment`, `tfstate_storage_account`, `tfstate_resource_group` | All modules within an environment |
| `terragrunt.hcl` | Module source, dependencies, resource-specific inputs | Single module instance |

### Input Variable Priority

Variables are merged in `root.hcl` using `inputs = merge(...)`. Later values override earlier ones:

```
1. Inline defaults in root.hcl (suffix, tags)   ← lowest priority
2. region.hcl locals
3. location.hcl locals
4. env.hcl locals                                ← highest priority
```

---

## Module Strategy

Two patterns are valid. The choice is driven by whether the resource already exists in Azure with a name that conflicts with the remote module's naming convention.

### Decision Table

| Situation | Pattern to Use |
|-----------|---------------|
| New resource, module exists in `terraform-modules` | Remote (preferred) |
| New resource, no module in `terraform-modules` | Native azurerm wrapper |
| Importing existing state where module naming would force destroy/recreate | Native azurerm wrapper |
| Resource name must exactly match an existing Azure resource | Native azurerm wrapper |

Document the choice in an ADR when using native azurerm wrappers.

---

### Pattern A — Preferred: DevSecOps Reusable Modules (Remote)

Source modules from the central `terraform-modules` repository. Version is controlled by the `module_version` local in an `azure.hcl` file.

**Available modules:**

| Module | Path |
|--------|------|
| App Service | `azure/app_service` |
| App Configuration | `azure/app_configuration` |
| App Configuration Key | `azure/app_configuration_key` |
| App Configuration Key Map | `azure/app_configuration_key_map` |
| AKS | `azure/aks` |
| API Management API | `azure/api_management_api` |
| Application Insights | `azure/application_insights` |
| Cosmos DB | `azure/cosmos_db` |
| Data Factory | `azure/data_factory` |
| Event Hub | `azure/event_hub` |
| Front Door CDN | `azure/front-door-cdn` |
| Key Vault | `azure/keyvault` |
| Key Vault Secret | `azure/keyvault-secret` |
| Key Vault Secret Map | `azure/keyvault-secret-map` |
| Key Vault Certificate | `azure/key-vault-certificate` |
| Private DNS Zone | `azure/private_dns_zone` |
| Private Endpoint | `azure/private_endpoint` |
| Public DNS Zone | `azure/public_dns_zone` |
| Redis | `azure/redis` (via `_azure/redis.hcl`) |
| Service Bus | `azure/servicebus` (via `_azure/servicebus.hcl`) |
| SignalR | `azure/signalr` (via `_azure/signalr.hcl`) |
| SQL Server | `azure/sql-server` (via `_azure/sql-server.hcl`) |
| Storage Account | `azure/storage-account` (via `_azure/storage-account.hcl`) |

**Important: Naming behaviour.** Remote modules generate resource names automatically using the `Azure/naming/azurerm` naming module combined with a random suffix (e.g. `app-dev-uksouth-x3k2`). This means:

- You cannot predict or control the exact resource name
- Importing an existing resource with a different name will cause Terraform to plan a destroy/recreate
- If exact name control is required, use the native azurerm wrapper instead

**Shared config template pattern (`_azure/<resource>.hcl`):**

```hcl
# azure/_azure/app-service.hcl
dependency "resource_group" {
  config_path = "${get_terragrunt_dir()}/../resource-group"
  mock_outputs = {
    name = "mock-rg"
  }
}

dependency "service_plan" {
  config_path = "${get_terragrunt_dir()}/../service-plan"
  mock_outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Web/serverFarms/mock-serviceplan"
  }
}

locals {
  azure_vars = read_terragrunt_config(find_in_parent_folders("azure.hcl"))
}

terraform {
  # git::https://gitlab.com/trigent1/devsecops/terraform-modules.git//azure/app_service?ref=v${local.azure_vars.locals.module_version}
  source = "tfr://gitlab.com/trigent1/devsecops/terraform-modules//azure/app_service?version=${local.azure_vars.locals.module_version}"
}

inputs = {
  resource_group_name      = dependency.resource_group.outputs.name
  service_plan_resource_id = dependency.service_plan.outputs.resource_id
  # Resource-specific inputs defined in child terragrunt.hcl
}
```

**Child module override (`<env>/<resource>/terragrunt.hcl`):**

```hcl
# azure/uk/uksouth/dev/my-app-service/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "azure" {
  path   = find_in_parent_folders("_azure/app-service.hcl")
  expose = true
}

inputs = {
  os_type     = "Windows"
  kind        = "webapp"
  app_settings = {
    "MY_SETTING" = "value"
  }
}
```

**Version pinning (`azure.hcl`):**

```hcl
# azure.hcl — at the azure/ directory level
locals {
  module_version = "1.2.3"   # Bare SemVer — no 'v' prefix; required by tfr:// ?version= parameter. Never use "main" or "latest"
}
```

---

### Pattern B — Native azurerm Wrapper Modules (Local)

Used when importing existing state or when the resource type is not available in `terraform-modules`. Each module is a single `main.tf` containing variables, resources, and outputs separated by comment banners.

**Module structure (`azure/_modules/<resource-type>/main.tf`):**

```hcl
# <Resource Type> Module
# Brief description of what this module manages
# Inherits: location, environment, tags from root.hcl

# ---------------------------------------------------------------------------------------------------------------------
# VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "location" {
  description = "Azure location (inherited from root/env)"
  type        = string
}

variable "environment" {
  description = "Environment name (inherited from root/env)"
  type        = string
}

variable "tags" {
  description = "Common tags (inherited from root)"
  type        = map(string)
  default     = {}
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "my_resources" {
  description = "Map of resources to create"
  type = map(object({
    name     = string
    sku_name = optional(string, "Standard")
    tags     = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# RESOURCES
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_example" "this" {
  for_each            = var.my_resources
  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = each.value.sku_name
  tags                = merge(var.tags, each.value.tags)
}

# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "ids" {
  description = "Map of resource IDs"
  value       = { for k, v in azurerm_example.this : k => v.id }
}

output "names" {
  description = "Map of resource names"
  value       = { for k, v in azurerm_example.this : k => v.name }
}
```

**Terragrunt consumer (`<env>/<resource>/terragrunt.hcl`):**

```hcl
# <Resource> - <Environment> (<location>)
# Inherits: location, environment, tags from root.hcl

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/azure/_modules/<resource-type>"
}

dependency "resource_groups" {
  config_path = "../resource-groups"
  mock_outputs = {
    names = { main = "mock-rg" }
  }
}

inputs = {
  resource_group_name = dependency.resource_groups.outputs.names["main"]
  # Resource-specific inputs only — location, environment, tags are inherited
}
```

---

## Module Design Standards

### Variables

| Standard | Requirement |
|----------|-------------|
| Inherited variables | Always declare `location`, `environment`, `tags` (passed from `root.hcl`) |
| Descriptions | Required on every variable |
| Optional fields | Use `optional()` with defaults in object types |
| Sensitive values | Mark with `sensitive = true`; never assign defaults |

### Resources

| Standard | Requirement |
|----------|-------------|
| Multi-resource | Use `for_each` with maps; avoid `count` for named resources |
| Name control | Use exact `each.value.name` for native modules; never interpolate names inside modules |
| Tag merging | `merge(var.tags, each.value.tags)` at every resource |
| `lifecycle` | Document all `ignore_changes` entries with an inline comment explaining why |

### `for_each` vs `count`

```hcl
# BAD: count creates index-based addressing (resource.example[0])
resource "azurerm_resource_group" "this" {
  count    = length(var.names)
  name     = var.names[count.index]
  location = var.location
}

# GOOD: for_each creates stable key-based addressing (resource.example["main"])
resource "azurerm_resource_group" "this" {
  for_each = var.resource_groups
  name     = each.value.name
  location = coalesce(each.value.location, var.location)
  tags     = merge(var.tags, each.value.tags)
}
```

### Outputs

| Standard | Requirement |
|----------|-------------|
| IDs | Always output; use `for k, v in resource : k => v.id` pattern |
| Names | Always output; used by dependent modules |
| Sensitive outputs | `sensitive = true` on connection strings, credentials, keys |
| Description | Required on every output |

---

## Tag Strategy

### Required Tags

All resources must carry the following tags (enforced by OPA policy in CI):

| Tag | Source | Example |
|-----|--------|---------|
| `Project` | `root.hcl` | `"devopsinfra"` |
| `Environment` | `root.hcl` (from `env.hcl`) | `"dev"` |
| `Region` | `root.hcl` (from `region.hcl`) | `"uk"` |
| `ManagedBy` | `root.hcl` | `"terragrunt"` |
| `rt-product` | `root.hcl` | `"infr"` |
| `rt-stage` | `root.hcl` (from `env.hcl`) | `"dev"` |
| `rt-deployed` | `root.hcl` | `"terraform"` |
| `rt-owner` | `root.hcl` | team identifier |

### Tag Merge Pattern

Tags flow from `root.hcl` down and are merged at each resource:

```
root.hcl common_tags (Project, Environment, Region, ManagedBy, rt-*)
    ↓ merge() in root.hcl inputs
terragrunt.hcl resource-level tags
    ↓ merge() inside module
final resource tags
```

```hcl
# In module main.tf — always merge, never assign directly
tags = merge(var.tags, each.value.tags)
```

Resource-specific tags (e.g. `nodepoolMode`, `workload`) are added at the `terragrunt.hcl` level and must not override the required common tags.

---

## State Management

### Backend Configuration

| Standard | Requirement |
|----------|-------------|
| Backend | Azure Storage Account (`azurerm`) |
| Isolation | One state file per `terragrunt.hcl` (per module instance) |
| Key pattern | `${path_relative_to_include()}/<project>.tfstate` |
| Backend config | Referenced from `env.hcl` locals; never hardcoded in `root.hcl` |
| Container | `<project>-tfstate` |

### State Key Example

```
azure/uk/uksouth/dev/aks/devopsinfra.tfstate
azure/uk/uksouth/dev/networking/devopsinfra.tfstate
```

### Backend Generation in `root.hcl`

```hcl
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    resource_group_name  = local.tfstate_resource_group
    storage_account_name = local.tfstate_storage_account
    container_name       = "${local.project}-tfstate"
    key                  = "${path_relative_to_include()}/${local.project}.tfstate"
  }
}
```

### Environment State Accounts

Document the state storage accounts in the repository README:

| Environment | Storage Account | Resource Group | Container |
|-------------|----------------|----------------|-----------|
| (example) dev | `tfstatedev...` | `dev-tfstate-rg` | `<project>-tfstate` |
| (example) staging | `tfstatestage...` | `tfstate-stage-rg` | `<project>-tfstate` |
| (example) prod | `tfstateprod...` | `prod-tfstate-rg` | `<project>-tfstate` |

---

## Dependency Management

### Dependency Blocks

| Standard | Requirement |
|----------|-------------|
| Cross-module references | Always use `dependency {}` blocks; never hardcode resource IDs |
| `mock_outputs` | Required on every dependency; enables plan/validate without live state |
| `config_path` | Relative path to sibling module directory |
| Dependency order | Document in README and `docs/` diagrams |

### Dependency Pattern

```hcl
dependency "networking" {
  config_path = "../networking"

  # mock_outputs must reflect realistic values for validate/plan to succeed
  mock_outputs = {
    subnet_ids = {
      aks_nodepool_system = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-subnet"
    }
  }
}

inputs = {
  vnet_subnet_id = dependency.networking.outputs.subnet_ids["aks_nodepool_system"]
}
```

### Missing `mock_outputs`

Without `mock_outputs`, `terragrunt validate` and `terragrunt plan` will fail when the dependency has not yet been applied. This breaks CI on feature branches and new environment bootstraps.

---

## Secrets

| Standard | Requirement |
|----------|-------------|
| Secret values | Never in `.hcl`, `.tf`, or state keys; provision via Key Vault |
| Key Vault secrets | Use the `keyvault-secret` module; supply value via CI variable at apply time |
| Sensitive outputs | Mark with `sensitive = true` on all outputs containing credentials or connection strings |
| State exposure | Sensitive values still appear in state — restrict storage account access via RBAC |
| Environment variables | Never log `ARM_CLIENT_SECRET` or similar in CI scripts |

```hcl
# BAD: secret value in terragrunt input
inputs = {
  secret_value = "my-actual-password"
}

# GOOD: secret value sourced from CI environment variable
inputs = {
  secret_value = get_env("MY_SECRET_VALUE", "")
}
```

```hcl
# Module output — mark sensitive
output "connection_string" {
  description = "Database connection string"
  value       = azurerm_sql_server.this["primary"].connection_string
  sensitive   = true
}
```

---

## CI/CD Pipeline

### Pipeline Architecture

The shared pipeline is defined in `trigent1/devsecops/terraform-modules` and included by every IaC repo:

```yaml
# .gitlab-ci.yml
stages:
  - generate
  - validate
  - plan
  - apply

include:
  - project: trigent1/devsecops/terraform-modules
    ref: ${DEVSECOPS_PIPELINE_VERSION}   # Always a pinned tag
    file:
      - terragrunt.gitlab-ci.yml

  - local: .gitlab-ci/terragrunt.gitlab-ci.yml
    inputs:
      stack_environment: dev
      region: uksouth
      environment_path: azure/uk/uksouth/dev
```

### Pipeline Stages

| Stage | Trigger | Behaviour |
|-------|---------|-----------|
| `generate` | MR file changes | Scans `ENV_PATH` for `terragrunt.hcl` files; generates per-resource child pipeline |
| `validate` | Every pipeline | `terragrunt hcl validate --inputs` + `terragrunt validate` per resource |
| `plan` | Every pipeline | `terragrunt plan`; OPA tag policy evaluated; Infracost diff posted to MR |
| `apply` | Manual trigger | `terragrunt apply -auto-approve`; requires plan to have passed |

### Pipeline Standards

| Standard | Requirement |
|----------|-------------|
| `DEVSECOPS_PIPELINE_VERSION` | Always pinned to a git tag; set as CI/CD variable; never use `main` |
| `apply` | Always `when: manual`; no auto-apply to any environment |
| Environments | Each `environment_path` mapped to a GitLab Environment for protection rules |
| Production | Protected environment; manual apply requires approver |
| OPA tag policy | Enforced at `plan` stage; pipeline fails if required tags are missing |
| Infracost | Runs on every MR; cost diff posted as MR comment |

### OPA Tag Validation

The plan stage evaluates every resource in the Terraform plan against the tag policy:

```bash
opa eval --data /OPA-policy/tag-validation-policy.rego \
         --input plan.json \
         "data.terraform.azure.tags.has_violations" \
         --fail-defined   # exits non-zero if any required tag is missing
```

Fix tag violations by ensuring `root.hcl` `common_tags` is propagated to all resources via `merge(var.tags, ...)` in the module.

### `.gitlab-ci/terragrunt.gitlab-ci.yml` Local Template

Each repo maintains a local template that binds the shared pipeline jobs to specific environments:

```yaml
spec:
  inputs:
    stack_environment:
      options: ["dev", "staging", "prod"]
    region:
      options: ["uksouth", "ukwest", "southcentralus", "eastus2"]
    environment_path:
      description: "Full path to the environment (e.g., azure/uk/uksouth/dev)"
---
"$[[ inputs.stack_environment ]]-$[[ inputs.region ]]-validate-env":
  extends: .validate_env
  variables:
    ENV_PATH: "$[[ inputs.environment_path ]]"
  environment:
    name: "$[[ inputs.environment_path ]]"

"$[[ inputs.stack_environment ]]-$[[ inputs.region ]]-plan-env":
  extends: .plan_env
  variables:
    ENV_PATH: "$[[ inputs.environment_path ]]"
  needs:
    - job: "$[[ inputs.stack_environment ]]-$[[ inputs.region ]]-validate-env"

"$[[ inputs.stack_environment ]]-$[[ inputs.region ]]-apply-env":
  extends: .apply_env
  variables:
    ENV_PATH: "$[[ inputs.environment_path ]]"
  needs:
    - job: "$[[ inputs.stack_environment ]]-$[[ inputs.region ]]-plan-env"
```

---

## Testing & Validation

| Standard | Requirement |
|----------|-------------|
| `hcl validate` | `terragrunt hcl validate --inputs` on every MR — validates variable types against declared inputs |
| `terraform validate` | `terragrunt validate` on every MR — checks HCL syntax and provider schema |
| Plan review | Plan output reviewed and approved before manual apply; post plan as MR artefact |
| Import plans | First plan after state import is expected to show tag-only diffs — document this in the MR description |
| No auto-apply | All environments require manual apply trigger; production requires approval |
| `run-all` caution | `terragrunt run-all plan` on default branch only; individual resource plans on MR branches |

### Local Validation Commands

```bash
# Validate a single module
cd azure/uk/uksouth/dev/aks
terragrunt hcl validate --inputs
terragrunt validate

# Plan a single module
terragrunt plan

# Plan all modules in an environment (default branch / post-merge)
cd azure/uk/uksouth/dev
terragrunt run-all plan

# Format HCL files
terragrunt hcl fmt
```

---

## Importing Existing Resources

When bringing an existing Azure resource under Terraform management:

| Step | Action |
|------|--------|
| 1 | Create the module and `terragrunt.hcl` matching the existing resource configuration exactly |
| 2 | Run `terragrunt init` |
| 3 | Run `terragrunt import <resource_address> <azure_resource_id>` |
| 4 | Run `terragrunt plan` — should show no changes (or tag-only diffs) |
| 5 | Apply tag-only diffs; document in MR description |
| 6 | Document import commands in an `import.sh` script in the module directory |

**Native azurerm wrapper is required for imports** when the existing resource name does not match what the remote module's naming convention would generate. Using the remote module would cause Terraform to plan a `destroy` of the existing resource followed by `create` of a new one with the generated name.

```bash
# import.sh — committed alongside terragrunt.hcl
#!/bin/bash
terragrunt import \
  'azurerm_kubernetes_cluster.this["cluster_re1"]' \
  '/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.ContainerService/managedClusters/<name>'
```

---

## Documentation

### Required Documentation

| Artifact | When Required |
|----------|---------------|
| `README.md` | All repositories |
| `docs/adr/` | Significant architectural decisions (see below) |
| Architecture diagrams | All production environments |
| `import.sh` | Every module where resources were imported from existing state |

### README Requirements

A repository README must include:

- Architecture overview with directory structure
- Environment table (environment, location, subscription, status)
- Module dependency order (diagram or ordered list)
- State storage account table
- Quick-start commands (`init`, `plan`, `apply`, `run-all`)
- Configuration inheritance explanation

### Required ADRs

| Decision | ADR Required |
|----------|-------------|
| Using native azurerm wrapper instead of remote module | Yes — explain naming conflict or missing module |
| Provider version pin | Yes for major version bumps |
| Deviating from standard directory layout | Yes |
| Multi-region state sharing (e.g. RE1/RE2 sharing one backend) | Yes |

### Architecture Diagrams

Production environments should maintain architecture diagrams in `docs/`:

- Graphviz `.dot` files for detailed resource diagrams
- Mermaid or `.md` for human-readable architecture overviews
- Keep diagrams synchronised when infrastructure configuration changes (AKS versions, node pool counts, network topology, service tiers)
- Generate dependency graph: `terragrunt dag graph | dot -Tpng -o docs/diagram.png`

---

## Anti-Patterns to Avoid

### Hardcoding Resource IDs

```hcl
# BAD: hardcoded resource ID — breaks across environments and subscriptions
inputs = {
  subnet_id = "/subscriptions/e2e3692b-c01f-41eb-87bb-e71a6ee6363e/resourceGroups/devuk-rg/providers/..."
}

# GOOD: reference via dependency output
inputs = {
  subnet_id = dependency.networking.outputs.subnet_ids["aks_nodepool_system"]
}
```

### Floating Module Versions

```hcl
# BAD: git:: with floating ref — unpredictable, breaks on upstream changes
terraform {
  source = "git::https://gitlab.com/trigent1/devsecops/terraform-modules.git//azure/app_service?ref=main"
}

# BAD: git:: with pinned ref — valid but legacy; prefer tfr://
terraform {
  source = "git::https://gitlab.com/trigent1/devsecops/terraform-modules.git//azure/app_service?ref=v1.2.3"
}

# GOOD: tfr:// with pinned SemVer — no 'v' prefix, uses GitLab Terraform Registry
terraform {
  # git::https://gitlab.com/trigent1/devsecops/terraform-modules.git//azure/app_service?ref=v1.2.3
  source = "tfr://gitlab.com/trigent1/devsecops/terraform-modules//azure/app_service?version=1.2.3"
}
```

### Missing `mock_outputs`

```hcl
# BAD: dependency without mock_outputs — CI validate/plan fails on new branches
dependency "networking" {
  config_path = "../networking"
}

# GOOD: mock_outputs allow validate/plan without live state
dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    subnet_ids = {
      aks_nodepool_system = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-subnet"
    }
  }
}
```

### Using `count` for Named Resources

```hcl
# BAD: count-based addressing is fragile — removing item 0 shifts all indices
resource "azurerm_key_vault" "this" {
  count    = length(var.vaults)
  name     = var.vaults[count.index].name
}

# GOOD: for_each with stable map keys
resource "azurerm_key_vault" "this" {
  for_each = var.vaults
  name     = each.value.name
}
```

### Secrets in Inputs

```hcl
# BAD: secret value committed to source control
inputs = {
  secret_value = "SuperSecretPassword123!"
}

# GOOD: sourced from CI environment variable; never committed
inputs = {
  secret_value = get_env("DB_PASSWORD", "")
}
```

### Missing `sensitive = true` on Credential Outputs

```hcl
# BAD: connection string exposed in plan output
output "connection_string" {
  value = azurerm_sql_server.this["primary"].connection_string
}

# GOOD: marked sensitive — redacted in plan and apply output
output "connection_string" {
  description = "Primary SQL Server connection string"
  value       = azurerm_sql_server.this["primary"].connection_string
  sensitive   = true
}
```

### `run-all apply` Without Plan Review

```bash
# BAD: applying all modules without reviewing what will change
cd azure/uk/uksouth/prod
terragrunt run-all apply

# GOOD: plan first, review output, then apply manually per module or with approval
cd azure/uk/uksouth/prod
terragrunt run-all plan
# Review plan output, then trigger apply via CI manual job
```
