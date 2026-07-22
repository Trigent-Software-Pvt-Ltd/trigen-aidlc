---
name: trunk-validate
description: "Run 6 validation checks on a trunk-based migration. Verifies kustomize builds, pipeline components, review apps, secrets, and production gates. Triggers: trunk validate, validate migration, check migration, verify migration"
argument-hint: "<config.yaml path>"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
  - Task
---

# Trunk Migration Validation

You are the validation skill for trunk-based migration. Run 6 comprehensive checks to verify the migration is correct before and after MR creation.

Reference config schema at: @${CLAUDE_PLUGIN_ROOT}/references/config-schema.md

## Input

`$ARGUMENTS` may contain a path to `trunk-migration-config.yaml`. If not provided, check for `trunk-migration-config.yaml` in the repository root.

## Validation 1: Kustomize Build Test

Test all region/environment combinations build correctly:

```bash
for region in us uk; do
  for env in dev staging prod; do
    echo "Testing $region/$env..."
    kustomize build k8s/$region/$env > /tmp/test-$region-$env.yaml

    # Verify output contains expected resources
    if grep -q "kind: Deployment" /tmp/test-$region-$env.yaml && \
       grep -q "kind: Service" /tmp/test-$region-$env.yaml && \
       grep -q "kind: IngressRoute" /tmp/test-$region-$env.yaml; then
      echo "PASS: $region/$env builds correctly"
    else
      echo "FAIL: $region/$env missing resources"
    fi
  done
done
```

Additionally verify:
- Each build output contains the correct ACR registry for that region/environment
- Each build output has the correct domain in IngressRoute
- Each build output has the correct `NEW_RELIC_APP_NAME` suffix
- Security context is present (`runAsNonRoot: true`)
- Port is `8080` in all probes
- `allowPrivilegeEscalation: false` is set

## Validation 2: MR Pipeline Component Verification

Read `.gitlab-ci.yml` and verify all expected components are present:

**Required for ALL migrations:**
- [ ] Workflow rules target `main` branch
- [ ] YAML anchors for regions and lower-environments
- [ ] All required stages present
- [ ] Core template includes with correct versions
- [ ] `docker-build-job` present
- [ ] `test-job` present
- [ ] `coverage-job` present (extends `.coverage` from `dotnet/coverage.yml`)
- [ ] `deploy-k8s-lower` with correct needs
- [ ] `deploy-prod-job` with `manual-approval-prod` in needs
- [ ] `push-docker-images-prod` with `manual-approval-prod` in needs
- [ ] Review app jobs (deploy + cleanup)
- [ ] `NAMESPACE: platform` is job-level (NOT global)

**Conditional checks (based on config decision trees):**

If `api_versioning.multi_version`:
- [ ] Swagger generation uses parallel matrix
- [ ] APIM deployment has per-version matrix entries
- [ ] Each version has unique `API_ID`

If `auth0.enabled`:
- [ ] `auth0-deploy-lower` job exists
- [ ] `auth0-deploy-prod` job exists with `manual-approval-prod` in needs
- [ ] Uses `node:20-alpine` image
- [ ] Secure secret injection with printenv and sed escaping
- [ ] Replacement verification (`grep -q "##PLACEHOLDER##"`)

If `nuget.enabled`:
- [ ] NuGet pack jobs exist for each package
- [ ] Rules restrict to `main` branch only

If `ui_tests.enabled`:
- [ ] `test-ui-staging` job exists in `prod-gate` stage
- [ ] `test-ui-staging` has no `needs` (stage-scheduled, waits for all `deploy-lower` jobs)
- [ ] `SCHEDULE_NAME` variable matches config value
- [ ] Triggers `web-ui-framework-2-platform` project

If `ef_migrations.enabled`:
- [ ] `validate-migration-script-job` present
- [ ] `deploy-migrations-lower` present
- [ ] `deploy-migrations-prod` present with `manual-approval-prod`
- [ ] `.config/dotnet-tools.json` exists
- [ ] `migration.sql` file exists

## Validation 3: Review App Deployment Check

Verify review overlay structure:
- [ ] `k8s/overlays/review/kustomization.yaml.template` exists
- [ ] `k8s/overlays/review/add-nodeselector.patch.yaml.template` exists
- [ ] `k8s/overlays/review/patch-api-deployment.yaml.template` exists
- [ ] `k8s/overlays/review/patch-api-service.yaml.template` exists
- [ ] `k8s/overlays/review/patch-api-hpa.yaml.template` exists
- [ ] `k8s/overlays/review/patch-https-route.yaml.template` exists
- [ ] `k8s/overlays/review/resources/https-route.yaml` exists
- [ ] `k8s/overlays/review/resources/http-to-https-redirect.yaml` exists

In all patch templates (deployment, service, hpa, https-route):
- [ ] `namespace:` field present in metadata (must match base namespace for kustomize strategic merge patch matching)

In HTTPRoute resources and patches:
- [ ] `parentRefs` uses correct gateway controller (check `gateway.name` and `gateway.namespace` from config)
- [ ] `parentRefs` includes `group: gateway.networking.k8s.io` and `kind: Gateway`
- [ ] `sectionName` is `https-listener` for HTTPS route, `http-listener` for redirect
- [ ] `backendRefs` uses full spec (`group`, `kind`, `weight`, `matches`)

In `patch-api-deployment.yaml.template`:
- [ ] `valueFrom: null` present for every env var (prevents secretKeyRef override)
- [ ] `ASPNETCORE_FORWARDEDHEADERS_ENABLED: "true"` present (required for HTTPS behind gateway)
- [ ] Resource limits are review-appropriate (300Mi/200m)
- [ ] Uses spot node pool (`reviewspotnp`)
- [ ] HPA max is 1 replica

## Validation 4: Secrets Configuration Verification

Verify secrets are correctly referenced:

In `k8s/base/deployment.yaml`:
- [ ] All env vars use `secretKeyRef` to `SERVICE_NAME-secrets`
- [ ] Secret keys match expected names (azure-appconfig-endpoint, azure-client-id, etc.)

In `.gitlab-ci.yml` deploy jobs:
- [ ] `SECRET_NAME` variable matches deployment secretKeyRef name
- [ ] Secret creation `before_script` fetches all required values from Key Vault
- [ ] `kubectl create secret generic` includes all keys from deployment

## Validation 5: Main Branch Pipeline Checklist

After MR merges and first main pipeline runs, verify:

- [ ] Semantic release calculates version correctly
- [ ] Git tag created
- [ ] Docker images tagged with version
- [ ] Deployments to dev succeed (all regions)
- [ ] Deployments to staging succeed (all regions)
- [ ] NuGet packages published (if applicable)
- [ ] Auth0 configs deployed (if applicable)
- [ ] Migrations applied (if applicable)
- [ ] APIM APIs updated (not duplicated)

**Note:** This check requires the pipeline to have run. If checking before merge, report these as pending items.

## Validation 6: Production Gate Workflow Check

Verify the production approval workflow:

In `.gitlab-ci.yml`:
- [ ] `manual-approval-prod` job exists (from `prod-gate-manual-approval.yml` template)
- [ ] ALL production-stage jobs have `manual-approval-prod` in `needs:`
  - `push-docker-images-prod`
  - `deploy-prod-job`
  - `deploy-migrations-prod` (if applicable)
  - `auth0-deploy-prod` (if applicable)
  - `upload-api-prod`

Execution order after approval:
1. Docker push + Auth0 + Migrations (parallel)
2. K8s deployment (waits for Docker + Migrations)
3. APIM upload (waits for K8s deployment)

## Output

Present results as a checklist with PASS/FAIL/PENDING status:

```
Trunk Migration Validation Results
===================================

1. Kustomize Build Test
   ✓ us/dev      ✓ us/staging    ✓ us/prod
   ✓ uk/dev      ✓ uk/staging    ✓ uk/prod

2. Pipeline Components
   ✓ Core templates    ✓ Build jobs    ✓ Deploy jobs
   ✓ Review apps       ✓ Auth0         ✓ NuGet
   ✗ APIM API_IDs missing for uk/staging

3. Review App Structure
   ✓ All 8 template files present
   ✓ valueFrom: null on all env vars

4. Secrets Configuration
   ✓ secretKeyRef matches secret creation

5. Main Branch Pipeline
   ⏳ Pending (run after MR merge)

6. Production Gate
   ✓ All prod jobs require manual-approval-prod

Overall: 5/6 PASS, 1 PENDING
Issues found: 1 (APIM API_IDs)
```

If issues are found, suggest running `/dotnet:trunk-troubleshoot` with a description of the problem.
