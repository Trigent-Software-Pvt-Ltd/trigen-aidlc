---
name: trunk-help
description: "Explain trunk-based migration methodology and available skills. Triggers: trunk help, what is trunk migration, how to migrate, trunk commands, migration guide"
---

# Trunk-Based Migration Help

You are the help skill for the **dotnet trunk-based migration plugin**. When invoked, provide the user with a clear overview of the plugin, its workflow, and available commands.

## Overview

This plugin automates the migration of .NET API services from **GitLab Flow** (develop/staging/main branches) to **trunk-based development** (single `main` branch) with:

- **Kustomize-based Kubernetes manifests** (base + overlays pattern)
- **Shared pipeline templates** (v5.x)
- **Automated semantic versioning**
- **Review apps** for MR validation
- **Production manual approval gates**
- **Multi-region deployments** (US + UK)

## Available Commands

Present this table to the user:

| Command | Description |
|---------|-------------|
| `/dotnet:trunk-help` | This help page — overview, workflow, and commands |
| `/dotnet:trunk-discover` | Scan the current repo to build migration config YAML |
| `/dotnet:trunk-plan` | Preview what the migration will do before executing |
| `/dotnet:trunk-migrate` | Execute the full migration (create manifests, update CI/CD) |
| `/dotnet:trunk-validate` | Run 6 validation checks on the migrated repo |
| `/dotnet:trunk-troubleshoot` | Diagnose and fix common migration issues |
| `/dotnet:trunk-post-migrate` | Post-merge cleanup, security hardening, and monitoring |

## Recommended Workflow

```
1. /dotnet:trunk-discover    → Scan repo, answer questions, generate config YAML
                                ↓
2. /dotnet:trunk-plan        → Review what will change before executing
                                ↓
3. /dotnet:trunk-migrate     → Execute migration steps, create MR
                                ↓
4. /dotnet:trunk-validate    → Verify kustomize builds, pipeline, review apps
                                ↓
5. (MR review + merge)       → Team reviews and merges to main
                                ↓
6. /dotnet:trunk-post-migrate → Monitor deployment, cleanup, harden
```

## Key Technologies

- **.NET 8** ASP.NET Core Web API
- **GitLab CI/CD** with shared pipeline templates
- **Kubernetes** with **Kustomize** (base + overlays)
- **Azure Container Registry (ACR)**
- **Azure Kubernetes Service (AKS)**
- **Azure API Management (APIM)**
- **Azure App Configuration**
- **Entity Framework Core** (optional)
- **Auth0** (optional)

## Decision Trees

The migration adapts based on 5 decision trees:

1. **API Versioning** — Single version (v1) or multi-version (v1 + v2) affects APIM and swagger jobs
2. **Auth0 Integration** — If `auth0/` directory exists, Auth0 deployment jobs are added
3. **NuGet Packages** — If `.Client`/`.Shared`/`.Maps` projects exist, NuGet publishing is configured
4. **UI Regression Tests** — If `decisions.ui_tests` is enabled, a `test-ui-staging` job is added to prod-gate and/or a `test-ui-prod` job is added to post-deploy
5. **EF Migrations** — If DataMigrations project exists, database migration jobs are added

## Configuration

The plugin uses a **hybrid configuration approach**:

- **Config file provided**: Reads all values from `trunk-migration-config.yaml`
- **No config file**: Interactively prompts for all required information
- **Partial config**: Reads available fields, prompts for missing ones

Run `/dotnet:trunk-discover` to auto-generate the config file.

## Reference Implementation

The Client Building Service was the first service migrated using these instructions:
- GitLab project: `trigent1/trigent/platform/shared-services/client-building-service`
- Branch: `migrate/trunk-based-development`

## Getting More Help

- **Troubleshooting**: Run `/dotnet:trunk-troubleshoot` with a description of the issue
- **Pipeline templates**: See `trigent1/pipeline-templates` (v5.x branch)
- **Kustomize docs**: https://kustomize.io/
