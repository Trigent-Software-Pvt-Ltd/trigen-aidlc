---
name: trunk-migrate
description: "Execute the full trunk-based development migration for a .NET API service. Creates Kustomize manifests, updates CI/CD, and prepares MR. Triggers: trunk migrate, migrate to trunk, trunk-based migration, execute migration"
argument-hint: "<config.yaml path>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
  - Task
  - TodoWrite
---

# Trunk Migration Execution

You are the migration execution skill. You perform the actual migration of a .NET API service from GitLab Flow to trunk-based development.

**IMPORTANT**: This skill modifies the repository. Ensure the user has reviewed the plan via `/dotnet:trunk-plan` first.

## Prerequisites

**Required plugin:** This skill depends on the `gitlab-ci` plugin for pipeline standards.

Before proceeding, check if the gitlab-ci plugin is installed by attempting to verify the `/gitlab-ci:standards-load` command is available. If not installed, tell the user:

> The `gitlab-ci` plugin is required for this migration. Please install it first:
> ```
> /plugin install gitlab-ci
> ```
> Then run `/dotnet:trunk-migrate` again.

Do not proceed with the migration until the gitlab-ci plugin is confirmed available.

## References

Reference templates at: @${CLAUDE_PLUGIN_ROOT}/references/migration-templates.md
Reference config schema at: @${CLAUDE_PLUGIN_ROOT}/references/config-schema.md

## Input

`$ARGUMENTS` may contain a path to `trunk-migration-config.yaml`. If not provided:
1. Check for `trunk-migration-config.yaml` in the repository root
2. If not found, prompt the user to run `/dotnet:trunk-discover` first
3. If found, read and parse the config

## Detect Migration Mode

After reading the config, determine the migration mode:

- **Single-service**: config has `service:` block → standard migration
- **Multi-service**: config has `services:` list → multi-service migration
- **Functions**: any service has `type: "functions-worker"` or `type: "functions-http"` → use Functions templates

These modes can overlap: a multi-service repo may also be a Functions repo.

## Execution Steps

Create a TodoWrite list to track all migration steps. Mark each step as completed as you go.

### Step 0: Preparation

1. **Read existing configuration**: Read `.gitlab-ci.yml`, existing K8s manifests, and any auth0 configs to understand current values
2. **Create migration branch** (if not already on one):
   - Branch name must include the Jira ticket key: `migrate/{jira_ticket}-trunk-based-development` (e.g., `migrate/PLT-2763-trunk-based-development`)
   - Before creating, check if the branch already exists locally or on remote:
     ```bash
     BRANCH="migrate/${JIRA_TICKET}-trunk-based-development"
     if git show-ref --verify --quiet refs/heads/$BRANCH || git ls-remote --heads origin $BRANCH | grep -q .; then
       BRANCH="${BRANCH}-$(date +%s | tail -c 5)"
     fi
     git checkout -b $BRANCH
     ```
3. **Validate config**: Ensure all required fields are populated
4. **Check `Startup.cs` for forwarded headers** (webapi and functions-http only): Read `src/*Api*/Startup.cs` (or `Program.cs`). Verify that `ForwardedHeadersOptions` is configured and `UseForwardedHeaders()` is called. If missing, add them per the template in @${CLAUDE_PLUGIN_ROOT}/references/migration-templates.md. This is required for review apps to work correctly behind the gateway.

### Step 1: Create Kustomize Base Manifests

Create the `k8s/base/` directory. Use the templates from @${CLAUDE_PLUGIN_ROOT}/references/migration-templates.md.

#### Standard `webapi` (single-service)

6 files in `k8s/base/`:
- `k8s/base/deployment.yaml`
- `k8s/base/service.yaml`
- `k8s/base/ingressroute.yaml`
- `k8s/base/hpa.yaml`
- `k8s/base/namespace.yaml`
- `k8s/base/kustomization.yaml`

#### Azure Functions (`functions-worker` or `functions-http`, single or multi-service)

Files per service in `k8s/base/`:
- `k8s/base/{service-name}-deployment.yaml` — use the Functions Worker Deployment template; env vars use **placeholder string values** (NOT secretKeyRef — these are patched in the env overlay)
- `k8s/base/{service-name}-scaledobject.yaml` — **only for `functions-worker`**; copy triggers verbatim from existing KEDA ScaledObject
- `k8s/base/{service-name}-service.yaml` — **only for `functions-http`** (workers have no HTTP service in base)
- `k8s/base/{service-name}-hpa.yaml` — for `functions-http` only (workers are scaled by KEDA)
- `k8s/base/namespace.yaml`
- `k8s/base/kustomization.yaml` — multi-service base lists ALL deployments, scaledobjects, and services

**SECURITY REQUIREMENTS** (all service types):
- `runAsNonRoot: true`, `runAsUser: 1000`, `runAsGroup: 1000`, `fsGroup: 1000`
- `allowPrivilegeEscalation: false`
- Container port `8080` (non-privileged)
- `ASPNETCORE_URLS: "http://+:8080"`

**Container/deployment name preservation**: The `name:` in each base deployment MUST exactly match the existing `metadata.name` from the current K8s manifest. This ensures `kubectl apply` overwrites the existing deployment rather than creating a new one, preventing orphaned workloads.

**New Relic app name**: Use `FULL_SERVICE_NAME-placeholder-env` in base deployments. Region kustomizations patch the real name per region/env from `new_relic.app_names` in config.

### Step 2: Create Environment Overlays

#### Standard `webapi`

Create overlay kustomizations for each environment tier:
- `k8s/overlays/dev/kustomization.yaml` — HPA: min/max from config
- `k8s/overlays/staging/kustomization.yaml` — HPA: min/max from config
- `k8s/overlays/prod/kustomization.yaml` — references hpa-patch.yaml
- `k8s/overlays/prod/hpa-patch.yaml` — prod HPA min/max from config

#### Azure Functions

For each environment (dev, staging, prod), create:
- `k8s/overlays/{env}/kustomization.yaml` — references base + applies env patches
- `k8s/overlays/{env}/patch-{service-name}-env.yaml` — uses `$patch: replace` to replace the entire env block with secretKeyRef entries pointing to `{service-name}-secrets`

The `$patch: replace` pattern is critical: it replaces ALL placeholder values in the base with real secretKeyRef entries in one patch. See the "Environment Overlay — `$patch: replace` Pattern" section in @${CLAUDE_PLUGIN_ROOT}/references/migration-templates.md.

**Important**: Do NOT include `NEW_RELIC_APP_NAME` in the env overlay — it is set in the region kustomization with the correct per-region/env value.

For `functions-worker` services, also add an HPA patch if the service uses HPA (most workers use KEDA instead). For `functions-http` services, include HPA patches as for webapi.

### Step 3: Create Region-Specific Kustomizations

For each region/environment combination from `regions` × `environments`, create a kustomization file.

#### Standard `webapi`

```
k8s/{region}/{env}/kustomization.yaml
```

Each region kustomization MUST include:
1. Reference to the environment overlay (`../../overlays/{env}`)
2. Image replacement with region-specific ACR
3. Complete IngressRoute patch with `match`, `kind`, AND `services`
4. `NEW_RELIC_APP_NAME` deployment patch with exact value from `new_relic.app_names` map in config

#### Azure Functions

```
k8s/{region}/{env}/kustomization.yaml
k8s/{region}/{env}/patch-{service-name}-app-name.yaml   (one per service)
```

- Reference env overlay (`../../overlays/{env}`)
- Image replacement per service
- `NEW_RELIC_APP_NAME` patch per service using the exact value from `new_relic.app_names.{service-name}.{region}-{env}` in config — NOT generated from display_name pattern
- No IngressRoute patch for `functions-worker` (no IngressRoute)

**New Relic name lookup**: Always use `new_relic.app_names` from config. If it is empty or the value for a particular region/env is missing, ask the user to confirm the live name before proceeding.

**Region/Environment suffix convention** (for reference only — always prefer explicit `app_names` values):
| Region | Env | Suffix |
|--------|-----|--------|
| US | dev | `-dev` |
| US | staging | `-stag` |
| US | prod | `-prod` |
| UK | dev | `-devuk` |
| UK | staging | `-staguk` |
| UK | prod | `-produk` |

### Step 4: Create Review Overlay

Create the review overlay with `.template` files.

#### Standard `webapi`

- `k8s/overlays/review/kustomization.yaml.template`
- `k8s/overlays/review/add-nodeselector.patch.yaml.template`
- `k8s/overlays/review/patch-api-deployment.yaml.template`
- `k8s/overlays/review/patch-api-service.yaml.template`
- `k8s/overlays/review/patch-api-hpa.yaml.template`
- `k8s/overlays/review/patch-https-route.yaml.template`
- `k8s/overlays/review/resources/https-route.yaml`
- `k8s/overlays/review/resources/http-to-https-redirect.yaml`

#### Azure Functions

- `k8s/overlays/review/kustomization.yaml.template` — includes `$patch: delete` on each ScaledObject + `replicas: 1` on each worker Deployment; NO `$patch: delete` on IngressRoute for workers
- `k8s/overlays/review/add-nodeselector.patch.yaml.template`
- `k8s/overlays/review/patch-{service-name}-deployment.yaml.template` — per service; AzureWebJobsServiceBus set to disabled dummy value; `valueFrom: null` on all env vars
- `k8s/overlays/review/patch-https-route.yaml.template`
- `k8s/overlays/review/resources/https-route.yaml`
- `k8s/overlays/review/resources/http-to-https-redirect.yaml`
- `k8s/overlays/review/resources/{service-name}-service.yaml` — for `functions-worker` services only (not in base; needed for review app health check)

**CRITICAL for patch-{service}-deployment.yaml.template (Functions):**
- Include `valueFrom: null` for EVERY env var to override base placeholder values
- `AzureWebJobsServiceBus` must use the disabled dummy: `Endpoint=sb://review-disabled.servicebus.windows.net/;SharedAccessKeyName=disabled;SharedAccessKey=disabled`
- `CORECLR_ENABLE_PROFILING: "0"` to disable New Relic profiling in review
- `ASPNETCORE_FORWARDEDHEADERS_ENABLED: "true"` for correct URL scheme behind gateway

### Step 5: Delete Old Files

Delete files that are replaced by the new structure:

```bash
rm -rf k8s/dev/ k8s/stag/ k8s/prod/    # Old per-environment manifests
rm -rf .gitlab-ci/                       # Old CI includes
rm -f package.json package-lock.json     # No longer needed with v5 semantic-release
rm -f release.config.js                  # No longer needed
```

Also delete any old flat K8s manifest files listed in `existing.files_to_delete` in the config.

**Only delete files that actually exist.** Check before deleting.

### Step 6: Create .gitlab-ci.yml

This is the most complex step. Create the complete `.gitlab-ci.yml` using templates from @${CLAUDE_PLUGIN_ROOT}/references/migration-templates.md.

#### Single-service `webapi`

Build conditionally based on decision trees (same as before). Key sections:
- Workflow rules, YAML anchors, stages, variables
- Core template includes
- Docker build job (single service)
- Test and coverage jobs
- Kustomize deploy jobs with `NAMESPACE: platform` as job-level variable
- Review app include (single `image-names`, single `deployment-names`)
- Production gate and deploy jobs

#### Azure Functions repos

**Variables block**: Use Functions-specific variables (see "Variables Block — Functions Repos" in templates):
- `APP_NAME`, `SECRET_NAME` (shared secret for all services), `ACR_URL`
- `SERVICEBUS_CONNECTION_STRING_SECRET_NAME` — Key Vault secret name for Service Bus connection

**Docker build job**: Use parallel matrix with one row per service (see "Docker Build Job — Multi-Service Matrix").

**No swagger/APIM jobs** for `functions-worker` services. For `functions-http` services with APIM, include APIM deploy jobs.

**Review app include**: Use `deployment-names` input (comma-separated, matches `image-names`) so the health check waits for all services.

**Push docker images**: Parallel matrix with one row per service per region/environment.

**Kustomize deploy** (`deploy-k8s-lower`, `deploy-prod-job`): Use the Functions deployment template that fetches Service Bus connection string from Key Vault and creates the shared secret. Include `WAIT_FOR_DEPLOYMENTS: "SERVICE_NAME_1 SERVICE_NAME_2"` (space-separated, all services).

**Review app deploy/cleanup**: Use Functions review app jobs that create a review-time Service Bus secret.

**CRITICAL CI/CD RULES**:
- Use `needs` ONLY for intra-stage ordering (jobs within the same stage). NEVER add cross-stage `needs`.
- Entry-point jobs in each stage (e.g., `push-docker-images-prod`) must have NO `needs` — they are stage-scheduled.
- Use `dependencies` (not `needs`) when a job needs artifacts from an earlier stage.
- `NAMESPACE` must be job-level variable (NOT global) to avoid conflicts with review-app template.
- Use `v5` for all template refs.

#### Always include (all repo types):
- Workflow rules
- YAML anchors for regions and lower-environments
- Stages
- Variables block
- Core template includes (verify-staging, prod-gate, semantic-release, docker/build, coverage)
- Test job
- Coverage job
- Review app jobs
- Production docker push with manual-approval-prod gate

#### Conditional on `decisions.api_versioning.multi_version`:
- **true**: Multi-version swagger (parallel matrix), multi-version APIM deployment
- **false**: Single swagger, simple APIM (or none for pure workers)

#### Conditional on `decisions.auth0.enabled`:
- **true**: Auth0 deploy lower + prod jobs

#### Conditional on `decisions.nuget.enabled`:
- **true**: NuGet pack jobs for each package

#### Conditional on `decisions.ui_tests.enabled`:
- **true**: `test-ui-staging` in prod-gate stage, `test-ui-prod` in post-deploy stage

#### Conditional on `decisions.ef_migrations.enabled`:
- **true**: Migration validation job, deploy-migrations-lower, deploy-migrations-prod

### Step 7: Create EF Migrations Assets (Conditional)

**Only if `decisions.ef_migrations.enabled: true`:**

1. Create `.config/dotnet-tools.json` with dotnet-ef and swashbuckle tools
2. Generate `migration.sql`

### Step 8: Validate Kustomize Builds

Run kustomize build for all region/environment combinations present in `regions` × `environments`:

```bash
for region in {regions_from_config}; do
  for env in dev staging prod; do
    echo "Testing $region/$env..."
    kustomize build k8s/$region/$env > /dev/null && echo "✓ $region/$env" || echo "✗ $region/$env FAILED"
  done
done
```

If any build fails, diagnose and fix before proceeding. Reference @${CLAUDE_PLUGIN_ROOT}/references/troubleshooting-guide.md for common issues.

### Step 9: User Review and Commit

**STOP and ask the user to review changes before committing.**

Present a summary:
```
Migration complete. Changes summary:

Files created: {count}
- k8s/base/* ({count} files)
- k8s/overlays/**/* ({count} files)
- k8s/{regions}/**/* ({count} files)
- [conditional files]

Files modified:
- .gitlab-ci.yml (complete rewrite)

Files deleted:
- [list deleted files]

Kustomize validation: {pass/fail for each region/env}

Would you like me to commit and push these changes?
```

### Step 10: Commit and Push

After user approval:

```bash
git add .
git commit -m "feat: migrate to trunk-based development with Kustomize

- Migrate K8s manifests to Kustomize structure (base + overlays)
- Update CI/CD pipeline to trunk-based workflow with v5.x templates
- Add semantic release for automated versioning
- Add review apps support
- Configure production manual approval gates
{conditional lines based on decision trees}

Security improvements:
- Run containers as non-root (UID 1000)
- Use non-privileged port 8080
- Disable privilege escalation
- Implement proper health probe strategy
- Manage secrets via Kubernetes secretKeyRef

Resolves {jira_ticket}"

git push -u origin HEAD
```

### Step 11: Create Merge Request

Use glab CLI to create the MR:

```bash
glab mr create \
  --title "feat: migrate to trunk-based development with Kustomize" \
  --description "## Changes
- Migrated K8s manifests to Kustomize structure (base + overlays)
- Updated CI/CD pipeline to trunk-based workflow with v5.x templates
- Added semantic release for automated versioning
- Added review apps for MR testing
{conditional lines}

## Security Improvements
- Containers run as non-root (UID 1000)
- Using non-privileged port 8080
- Privilege escalation disabled
- Secrets managed via Kubernetes secretKeyRef

## Resolves
- {jira_ticket}

## Verification
- [x] Kustomize builds work for all regions/environments
- [ ] MR pipeline runs successfully
- [ ] Review app deploys correctly
- [ ] All tests pass (or flaky tests documented)
- [ ] Production manual approval gate works
{conditional checkboxes}" \
  --target-branch main \
  --squash-before-merge \
  --remove-source-branch
```

Inform the user of the MR URL and suggest running `/dotnet:trunk-validate` after the pipeline completes.
