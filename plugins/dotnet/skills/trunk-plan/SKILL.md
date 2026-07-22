---
name: trunk-plan
description: "Preview the trunk-based migration execution plan before making changes. Shows files to create, modify, and delete. Triggers: trunk plan, migration plan, show plan, preview migration"
argument-hint: "<config.yaml path>"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Trunk Migration Plan

You are the planning skill for trunk-based migration. Your job is to read the migration config, evaluate decision trees, and present a detailed execution plan for user review BEFORE any changes are made.

**This skill does NOT modify any files.** It only reads and reports.

## Input

`$ARGUMENTS` may contain a path to `trunk-migration-config.yaml`. If not provided:
1. Check for `trunk-migration-config.yaml` in the repository root
2. If not found, prompt the user to run `/dotnet:trunk-discover` first

Read the config file and validate it against the schema at @${CLAUDE_PLUGIN_ROOT}/references/config-schema.md

## Detect Migration Mode

After reading the config, determine the mode:
- **Single-service**: `service:` block present → standard migration
- **Multi-service**: `services:` list present → multi-service migration
- **Functions**: any service has `type: "functions-worker"` or `type: "functions-http"` → Functions migration

These can overlap.

## Step 1: Evaluate Decision Trees

Based on the config, evaluate all 5 decision trees:

### Decision Tree 1: API Versioning
```
multi_version: {true/false}
→ {Single version: 1 swagger job, simple APIM | Multi-version: matrix swagger, matrix APIM with per-version API_IDs (existing values from Azure APIM, provided by user)}
Note: functions-worker services have no swagger/APIM jobs
```

### Decision Tree 2: Auth0
```
auth0.enabled: {true/false}
→ {Enabled: auth0-deploy-lower + auth0-deploy-prod jobs | Disabled: no Auth0 jobs}
```

### Decision Tree 3: NuGet
```
nuget.enabled: {true/false}
→ {Enabled: nuget-pack jobs for each package | Disabled: no NuGet jobs, remove publish-packages stage}
```

### Decision Tree 4: UI Regression Tests
```
ui_tests.enabled: {true/false}
→ {Enabled: test-ui-staging job in prod-gate stage and/or test-ui-prod job in post-deploy stage | Disabled: no UI test jobs}
```

### Decision Tree 5: EF Migrations
```
ef_migrations.enabled: {true/false}
→ {Enabled: migration validation + deploy jobs, dotnet-tools.json, migration.sql | Disabled: no migration jobs}
```

## Step 2: Calculate File Changes

Present a clear summary of ALL file operations, adapted to the migration mode:

### Standard `webapi` (single-service)

**Files to Create:**
```
k8s/base/
  deployment.yaml
  service.yaml
  ingressroute.yaml
  hpa.yaml
  namespace.yaml
  kustomization.yaml

k8s/overlays/dev/kustomization.yaml
k8s/overlays/staging/kustomization.yaml
k8s/overlays/prod/kustomization.yaml
k8s/overlays/prod/hpa-patch.yaml

k8s/overlays/review/
  kustomization.yaml.template
  add-nodeselector.patch.yaml.template
  patch-api-deployment.yaml.template
  patch-api-service.yaml.template
  patch-api-hpa.yaml.template
  patch-https-route.yaml.template
  resources/https-route.yaml
  resources/http-to-https-redirect.yaml

k8s/{region}/{environment}/kustomization.yaml  (one per region × env combination)
```

Conditional:
- `.config/dotnet-tools.json` (if EF migrations enabled)
- `{data_project_path}/migration.sql` (if EF migrations enabled)

### Azure Functions (single or multi-service)

**Files to Create:**

```
k8s/base/
  namespace.yaml
  {service-name}-deployment.yaml         (one per service)
  {service-name}-scaledobject.yaml       (one per functions-worker service)
  {service-name}-service.yaml            (one per functions-http service)
  {service-name}-hpa.yaml                (one per functions-http service, if HPA used)
  kustomization.yaml

k8s/overlays/dev/
  kustomization.yaml
  patch-{service-name}-env.yaml          (one per service — $patch: replace)
k8s/overlays/staging/
  kustomization.yaml
  patch-{service-name}-env.yaml
k8s/overlays/prod/
  kustomization.yaml
  patch-{service-name}-env.yaml

k8s/overlays/review/
  kustomization.yaml.template            (includes $patch: delete for each ScaledObject)
  add-nodeselector.patch.yaml.template
  patch-{service-name}-deployment.yaml.template   (one per service)
  patch-https-route.yaml.template
  resources/https-route.yaml
  resources/http-to-https-redirect.yaml
  resources/{service-name}-service.yaml  (one per functions-worker — not in base)

k8s/{region}/{environment}/kustomization.yaml           (one per region × env)
k8s/{region}/{environment}/patch-{service-name}-app-name.yaml  (one per service per region × env)
```

### Files to Modify

- `.gitlab-ci.yml` — Complete rewrite to trunk-based workflow

### Files to Delete

Scan for and list:
- `k8s/dev/*.yaml` (old manifests)
- `k8s/stag/*.yaml` (old manifests)
- `k8s/prod/*.yaml` (old manifests)
- Files listed in `existing.files_to_delete` in config
- `.gitlab-ci/` directory (old CI includes)
- `package.json`, `package-lock.json`, `release.config.js` (no longer needed)

## Step 3: Pipeline Structure Preview

Show the planned CI/CD stages and jobs, adapted to migration mode:

### Standard `webapi`

```
Stages:
  1. build-artifacts
     - docker-build-job (matrix: api)
     - test-job
     - generate-swagger-job {single/matrix}
     - validate-migration-script-job {if EF enabled}
     - calculate-version

  2. publish-packages {if NuGet enabled}
     - nuget-pack-{package}

  3. review
     - deploy-review-app-job (MR only)
     - cleanup-review-app-job (MR close)

  4. deploy-lower (main branch only)
     - push-docker-images-lower (matrix: regions × lower-envs)
     - deploy-migrations-lower {if EF enabled}
     - auth0-deploy-lower {if Auth0 enabled}
     - deploy-k8s-lower (matrix: regions × lower-envs)
     - upload-api-lower (matrix: regions × lower-envs × versions)

  5. prod-gate
     - verify-staging-no-op
     - test-ui-staging {if UI tests enabled}
     - manual-approval-prod

  6. deploy-prod
     - push-docker-images-prod (matrix: regions)
     - deploy-migrations-prod {if EF enabled}
     - auth0-deploy-prod {if Auth0 enabled}
     - deploy-prod-job (matrix: regions)
     - upload-api-prod (matrix: regions × versions)

  7. post-deploy
     - test-ui-prod {if UI tests enabled}
```

### Azure Functions (multi-service example)

```
Stages:
  1. build-artifacts
     - docker-build-job (matrix: one row per service)
     - test-job
     - generate-swagger-job {only for functions-http with APIM}
     - calculate-version

  2. publish-packages {if NuGet enabled}

  3. review
     - deploy-review-app-job (creates Service Bus secret + deploys all services)
     - cleanup-review-app-job

  4. deploy-lower (main branch only)
     - push-docker-images-lower (matrix: regions × lower-envs × services)
     - deploy-k8s-lower (matrix: regions × lower-envs, creates shared secret, waits for all deployments)
     - upload-api-lower {only for functions-http services with APIM}

  5. prod-gate
     - verify-staging-no-op
     - test-ui-staging {if UI tests enabled}
     - manual-approval-prod

  6. deploy-prod
     - push-docker-images-prod (matrix: regions × services)
     - deploy-prod-job (matrix: regions, creates shared secret, waits for all deployments)
     - upload-api-prod {only for functions-http services with APIM}

  7. post-deploy
     - test-ui-prod {if UI tests enabled}
```

## Step 4: New Relic Name Validation

If the config has `new_relic.app_names` populated, list the exact names that will be used per service/region/env. If any entry is missing, flag it:

```
New Relic app names (from config):
  {service-name}:
    us-dev:     "Exact.Name-dev"    ✓
    us-staging: "Exact.Name-stag"  ✓
    us-prod:    "Exact.Name-prod"  ✓
    uk-dev:     [MISSING — will need user confirmation]
```

## Step 5: Summary Statistics

Present:
- Migration mode: {single-service webapi | multi-service Functions | ...}
- Services: {count and names}
- Total files to create: {count}
- Total files to modify: {count}
- Total files to delete: {count}
- Pipeline jobs on MR: {count}
- Pipeline jobs on main: {count}
- APIM matrix size: {count} (region × env × version combinations, or N/A for pure workers)
- Region/environment combinations: {count}
- KEDA triggers: {count across all services} (if Functions)

## Step 6: Approval Gate

Ask the user:

```
The migration plan is ready for review. Key highlights:
- {migration mode}: {service list}
- {count} new Kustomize manifests
- Complete .gitlab-ci.yml rewrite
- {conditional features summary}
- New Relic names: {confirmed from app_names map | needs confirmation}

Would you like to proceed with the migration?
- Run /dotnet:trunk-migrate to execute this plan
- Run /dotnet:trunk-discover to update the configuration
- Or ask me any questions about the plan
```

Do NOT proceed to migration automatically. The user must explicitly invoke `/dotnet:trunk-migrate`.
