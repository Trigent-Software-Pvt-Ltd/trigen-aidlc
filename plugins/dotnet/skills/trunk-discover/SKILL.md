---
name: trunk-discover
description: "Scan the current .NET repo to auto-detect service configuration and generate trunk-migration-config.yaml. Triggers: trunk discover, discover service, analyze repo, scan for migration"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Write
  - AskUserQuestion
  - Task
---

# Trunk Migration Discovery

You are the discovery skill for trunk-based migration. Your job is to scan the current repository, detect its configuration, ask the user for any missing information, and produce a complete `trunk-migration-config.yaml` file.

Reference the config schema at: @${CLAUDE_PLUGIN_ROOT}/references/config-schema.md

## Phase 1: Auto-Scan

Scan the repository to detect as much configuration as possible. Use Glob, Grep, and Read tools to find:

### 1.1 Service Information

- **Solution file**: Glob for `*.sln` or `*.slnx` in repo root
- **Projects**: Glob for `src/**/*.csproj` — inspect all project files
- **DLL name**: Read each `.csproj` to find `<AssemblyName>` or infer from project name
- **Dockerfiles**: Glob for `**/Dockerfile` — read each to find `ENTRYPOINT` (reveals DLL path and service identity)
- **Service name**: Read from existing K8s manifests (`metadata.name` in deployment YAMLs) — use this as canonical; it must be preserved exactly to avoid orphan deployments

**Multi-service detection**: If there are multiple Dockerfiles under separate `src/` subdirectories, or if `.gitlab-ci.yml` defines a parallel matrix with multiple `IMAGE_NAME` entries, this is a multi-service repo. Use the `services:` list schema instead of `service:`.

**Azure Functions detection**: If any Dockerfile `ENTRYPOINT` contains `dotnet Trigent.*.Functions*.dll` or if any `.csproj` contains `<AzureFunctionsVersion>`, classify the service type:
- `functions-http` — project name contains `Http` or `Inbound` or `Api` with Functions in the name, AND the `.gitlab-ci.yml` includes an APIM template (`functions_apim_net8.gitlab-ci.yml`)
- `functions-worker` — triggered by Service Bus, CosmosDB, Blob, Queue, or Event Hub (check for `ServiceBusTrigger`, `CosmosDBTrigger`, `BlobTrigger` in `.cs` files)
- For standard .NET APIs: `webapi` (default)

### 1.2 Current CI/CD Configuration

- **Read `.gitlab-ci.yml`**: Identify current stages, variables, includes, and job definitions
- **Pipeline template version**: Check `ref:` values in include blocks (e.g., `functions_net8.gitlab-ci.yml`, `functions_apim_net8.gitlab-ci.yml`)
- **Existing variables**: Extract `APP_NAME`, `SERVICE_NAME`, `PROJECT_PATH`, `IMAGE_NAME`, `KV_NAME` per environment
- **Key Vault names**: Extract `KV_NAME` or equivalent variables for dev, staging, and prod — these populate `key_vault:` in `region_config`
- **Multi-service matrix**: If `docker-build-job` has a parallel `matrix:` with `IMAGE_NAME` entries, record each as a separate service

### 1.3 Kubernetes Manifests

- **Glob for `k8s/**/*.yaml`**: Read all existing manifests
- **Extract namespace**: Read `metadata.namespace` from deployments — critical for kustomize and secret creation
- **Extract from deployments**:
  - Environment variables (full list)
  - Secret references (`secretKeyRef`)
  - Resource limits/requests
  - Health check endpoints (readiness/liveness probes) — if no probe exists, set `health_check_path: ""`
  - Container ports — record the actual port in the manifest
  - Node selectors
  - `NEW_RELIC_APP_NAME` values — **extract the exact live value** for each service/region/env combination (see 1.6)
- **KEDA ScaledObjects**: Grep for `kind: ScaledObject` — read the full spec including `triggers:` list. Record each trigger verbatim (type, metadata fields) — these map directly to `functions.keda.triggers`
- **Identify regions**: Check for `k8s/dev/`, `k8s/stag/`, `k8s/prod/` patterns or region variables in CI

### 1.4 Decision Tree Detection

- **Auth0**: Check if `auth0/` directory exists with `Glob("auth0/**/*")`
- **NuGet packages**: Check for `.Client`, `.Shared`, `.Maps` project directories with `Glob("src/**/*.csproj")`
- **EF Migrations**: Check for `DataMigrations` project with `Glob("src/**/*DataMigrations*/*.csproj")`
- **API versions**: Check for `[ApiVersion]` attributes or versioned controllers with `Grep("ApiVersion|\\[Route.*v[0-9]")`
- **UI regression tests**: Check if existing `.gitlab-ci.yml` contains a `test-ui-staging` or `test-ui-prod` job, or references a QA automation trigger project. If found, set `decisions.ui_tests.enabled: true` and extract the `trigger.project` path and `SCHEDULE_NAME` variable values if present (staging and prod may have different schedule names).

### 1.5 Database Configuration

- **DbContext name**: Grep for `DbContext` class definitions
- **Connection string key**: Grep for `GetConnectionString` or `ConnectionStrings:` references
- **Data project path**: Found during NuGet/EF detection

### 1.6 New Relic App Name Extraction

**Always extract actual live New Relic app names** — do not generate them from `display_name` patterns.

Look for `NEW_RELIC_APP_NAME` in:
1. K8s deployment manifests (env vars or region-specific overlays)
2. `.gitlab-ci.yml` variables (per-region/env sections)
3. Azure DevOps YAML if present (note: `#{system.teamProject}#` tokens are Azure DevOps syntax — the actual live name in GitLab deployments will differ; ask the user to confirm)

Map extracted values to the `new_relic.app_names` structure using keys `us-dev`, `us-staging`, `us-prod`, `uk-dev`, `uk-staging`, `uk-prod` (only for regions in use).

If any value contains `#{}#` tokens (Azure DevOps variable syntax) or is otherwise ambiguous, **flag it** and ask the user to confirm the actual live name deployed in each environment.

### 1.7 Functions-Specific Configuration

When Azure Functions are detected (see 1.1):

- **Secret name**: The K8s secret created at deploy time — typically `{service-name}-secrets`. Confirm from existing CI variables or scripts.
- **Service Bus secret**: Grep for `AzureWebJobsServiceBus` in manifests — if present, find the Key Vault secret name it reads from (check pipeline scripts or `secretKeyRef.key` values). Leave empty if not Service Bus.
- **KEDA triggers**: From the ScaledObjects found in 1.3, record each trigger verbatim. The `connectionFromEnv` field must match the env var name in the deployment.
- **`AzureFunctionsJobHost__functions__*` env vars**: Extract the list from current manifests — these allowlist which functions run. Record in `existing.env_vars`.
- **Port**: The trunk-based pattern sets `containerPort: 8080` and adds `ASPNETCORE_URLS: http://+:8080` as an environment variable in the kustomize overlay. No application code changes are needed — the ASP.NET Core host underlying the Functions isolated worker respects this environment variable. The existing manifest port is extracted and recorded, but the generated base deployment will use 8080.

### 1.8 Gateway Configuration

- **Detect gateway controller**: Search existing HTTPRoute manifests for `parentRefs` to identify the gateway controller in use
  - Look in `k8s/**/*.yaml` and `k8s/overlays/review/**/*.yaml` for `kind: HTTPRoute` with `parentRefs`
  - Extract `name` and `namespace` from the parentRef (e.g., `name: gateway`, `namespace: azure-alb` for Azure ALB Gateway)
  - If no HTTPRoute exists (service uses Traefik `IngressRoute` for production): **do NOT infer Traefik as the gateway**. IngressRoute is a production-only CRD and has no bearing on Gateway API HTTPRoutes used in review apps. Default to Azure ALB Gateway (`name: gateway`, `namespace: azure-alb`).
- If no gateway is detected, ask the user which gateway controller the cluster uses. If they confirm platform defaults, use Azure ALB Gateway (`name: gateway`, `namespace: azure-alb`)

> **Important**: Traefik IngressRoute (production) and Gateway API HTTPRoute (review apps) are completely separate routing mechanisms. A service that uses Traefik IngressRoute in production still uses Azure ALB Gateway for review app HTTPRoutes.

### 1.9 Existing Resource Configuration

- **Resource limits**: Extract from current deployment manifests
- **Health check paths**: Extract from current readiness/liveness probes — if no probe exists, record as empty string
- **Ports**: Extract from container port definitions
- **Environment variables**: Extract full list from current deployments
- **Files to delete**: Note existing K8s manifests, old CI files that will be replaced

## Phase 2: Interactive Gap-Fill

After scanning, identify what could NOT be auto-detected. Use `AskUserQuestion` to gather missing information. Common gaps include:

### Required Information (always ask if not found)

1. **ACR registry names** for each region/environment (up to 6 values for us/uk x dev/staging/prod)
2. **AKS cluster names** for each region/environment
3. **AKS cluster resource groups** for each region/environment
4. **Azure App Config names** for each region/environment (leave empty if fetched from Key Vault)
5. **Key Vault names** for each region/environment — if not found in CI variables
6. **Jira ticket ID** for the migration work
7. **Connection string key** (if EF migrations detected but key not found in code)
8. **APIM API_IDs** for each region/environment/version combination (existing values from Azure APIM — do NOT generate, ask the user)
9. **New Relic app names** — if extracted values contain Azure DevOps tokens (`#{}#` syntax) or are ambiguous, ask the user to confirm the actual live name for each service/region/env
10. **UI regression tests** — ALWAYS ask the user: "Does this service have UI regression tests that should run after staging deployment? And after production deployment?" If yes for either (or if auto-detected from `.gitlab-ci.yml`), set `decisions.ui_tests.enabled: true` and ask for:
    - `trigger_project` — the GitLab project path for the QA automation framework (e.g., `trigent1/trigent/quality-assurance/qa-automation/web-ui-framework-2-platform`)
    - `schedule_name` — staging schedule name (e.g., "CICD - Client Building Service - P0,P1 - Staging"), leave empty if no staging UI tests
    - `schedule_name_prod` — prod schedule name (e.g., "CICD - Client Building Service - P0,P1 - Prod"), leave empty if no prod UI tests
11. **Functions secret name** (if Azure Functions detected and not found in CI) — the K8s secret name created at deploy time

### Validation Questions

Present detected values to the user for confirmation:

**Single-service example:**
```
I detected the following configuration:
- Service name: clientbuilding-api (type: webapi)
- App name: clientbuilding
- Kubernetes namespace: platform
- Gateway: gateway (namespace: azure-alb)
- API versions: v1, v2
- Auth0: enabled
- NuGet packages: Client, Shared, Maps
- UI Tests: enabled (staging: "CICD - Client Building Service - P0,P1 - Staging", prod: "CICD - Client Building Service - P0,P1 - Prod")
- EF Migrations: enabled (ClientsDBContext)

Is this correct? What needs to be changed?
```

**Multi-service (Azure Functions) example:**
```
I detected a multi-service Azure Functions repo with 2 services:
  1. webhooks-incident (type: functions-worker)
     - KEDA triggers: azure-service-bus (emergenciestopic), azure-service-bus (teamassiststopic)
     - New Relic: [could not determine live name — found Azure DevOps token]
  2. webhooks-inbound-api (type: functions-http)
     - APIM enabled, no health check probe
     - New Relic: [could not determine live name — found Azure DevOps token]

- Kubernetes namespace: integrations
- Regions: us only
- Key Vaults: dev=trigent-intg-kv-dev-dr, stag=trigent-intg-kv-stag-dr, prod=trigent-int-kv-prod

Please confirm the actual live NEW_RELIC_APP_NAME values for each service/environment, and provide the APIM API_IDs for webhooks-inbound-api.
```

## Phase 3: Generate Config

After collecting all information, write the complete `trunk-migration-config.yaml` to the repository root.

Use the schema from @${CLAUDE_PLUGIN_ROOT}/references/config-schema.md as the template.

### Multi-service repos

Use the `services:` list structure. All top-level fields (`jira`, `regions`, `region_config`, `kubernetes`, `gateway`, `review`, `decisions`, `pipeline`) are shared across services.

Each service entry in `services:` must carry its own `functions:` block if it is an Azure Functions service. The `name:` field must exactly match the existing `metadata.name` of the Kubernetes Deployment — this prevents orphan deployments when `kubectl apply` runs against the new manifests.

### Output

Write the file and inform the user:

```
Created trunk-migration-config.yaml with:
- Services: {list of service names and types}
- Regions: {regions}
- Decision trees: Auth0={yes/no}, NuGet={yes/no}, EF={yes/no}, Multi-version API={yes/no}
- Environments: dev, staging, prod
- Functions: KEDA={yes/no}, triggers={count}

Next step: Run /dotnet:trunk-plan to preview the migration execution plan.
```

## Error Handling

- If the repository doesn't appear to be a .NET project (no `.sln` or `.csproj`), inform the user this plugin is for .NET API services
- If no existing K8s manifests are found, note this is a greenfield migration and more information will be needed
- If `.gitlab-ci.yml` doesn't exist, warn that CI/CD will be created from scratch
- If Azure DevOps variable tokens (`#{}#`) are found in New Relic names or other fields, flag them explicitly — do not pass them through to the config

## Config File Argument

If `$ARGUMENTS` contains a path to an existing config file, read it and validate against the schema instead of running discovery. Report any missing required fields.
