# Trunk Migration Troubleshooting Guide

Common issues encountered during trunk-based development migration, with error patterns, root causes, and fixes.

---

## Issue 1: Kustomize Build Fails - "resource not found"

**Error pattern:**
```
error: unable to find one or more resources
```

**Root cause:** Resource referenced in `resources:` list doesn't exist at the specified path.

**Fix:**
1. Check file paths in `kustomization.yaml`
2. Verify all referenced files exist
3. Check for typos in filenames

```bash
# Verify file exists
ls k8s/base/deployment.yaml
```

**Prevention:** Run `kustomize build` locally for all region/env combos before committing.

---

## Issue 2: Port 8080 Migration - Health Checks Fail

**Error pattern:**
```
Readiness probe failed: connection refused
```

**Root cause:** Health checks still pointing to port 80 instead of 8080.

**Fix:**
1. Update all health probes to port 8080
2. Update `ASPNETCORE_URLS` to `http://+:8080`
3. Restart pods

```yaml
# All three probes must use port 8080
startupProbe:
  httpGet:
    port: 8080
readinessProbe:
  httpGet:
    port: 8080
livenessProbe:
  httpGet:
    port: 8080
```

**Prevention:** Always use port 8080 for non-root containers. Verify `ASPNETCORE_URLS` env var is set.

---

## Issue 3: IngressRoute Loses Backend Service

**Error pattern:** IngressRoute exists but traffic doesn't route to the service.

**Root cause:** Incomplete strategic merge patch — Kustomize replaces the entire `routes` array, dropping the `services` field if not included.

**Fix:** Include complete route definition with `match`, `kind`, AND `services`:

```yaml
# WRONG - loses services field
patches:
  - patch: |-
      spec:
        routes:
          - match: HostRegexp(`service.internal.domain`)

# CORRECT - includes all fields
patches:
  - patch: |-
      spec:
        routes:
          - match: HostRegexp(`service.internal.domain`)
            kind: Rule
            services:
              - name: service-service
                port: 80
```

**Prevention:** Always include all three fields (`match`, `kind`, `services`) in IngressRoute patches.

---

## Issue 4: APIM Creates Duplicate APIs

**Error pattern:** Multiple APIs with the same name appear in Azure API Management.

**Root cause:** No `API_ID` specified, so APIM creates a new API entry on each deployment.

**Fix:** Add the existing `API_ID` from Azure APIM for each region/environment/version combination:

```yaml
variables:
  API_ID: "f3ed360da6dd441db0b6777208cc8dfc"  # Existing value from Azure APIM
```

To find existing API_IDs, check the Azure Portal under API Management > APIs, or ask the team for the current values.

**Prevention:** Always collect and specify `API_ID` for APIM jobs. These are existing identifiers — do not generate new ones.

---

## Issue 5: APIM Backend Returns 500 Error

**Error pattern:** APIM returns HTTP 500 when calling the API backend.

**Root cause:** One of:
1. `SERVER_URL` using HTTPS (should be HTTP)
2. `SERVER_URL` missing version suffix
3. Backend service not yet ready

**Fix:**
```yaml
# WRONG
SERVER_URL: "https://service-api.internal.domain"

# CORRECT
SERVER_URL: "http://service-api.internal.domain/v1"
```

**Prevention:**
- Always use HTTP for `SERVER_URL` (IngressRoute handles SSL termination)
- Always include version suffix (`/v1`, `/v2`)
- `upload-api-*` is stage-scheduled — it starts after all previous-stage jobs complete, no `needs:` required

---

## Issue 6: Review App Environment Variables Not Substituted

**Error pattern:** Pod logs show `{{AZURE_APPCONFIG_ENDPOINT}}` as a literal string value.

**Root cause:** `valueFrom: null` not set in review overlay, so base deployment's `secretKeyRef` takes precedence.

**Fix:** Explicitly set `valueFrom: null` to override base secretKeyRef:

```yaml
env:
  - name: AZURE_APPCONFIG_ENDPOINT
    value: "{{AZURE_APPCONFIG_ENDPOINT}}"
    valueFrom: null  # REQUIRED to override secretKeyRef
```

**Prevention:** Always include `valueFrom: null` for every env var in review overlay patches.

---

## Issue 7: Auth0 Deploy Fails - "command not found: bash"

**Error pattern:**
```
/bin/sh: bash: not found
```

**Root cause:** Using Alpine image (`node:20-alpine`) which has `/bin/sh` but not `/bin/bash`. Bash-specific syntax like `${!var_name}` fails.

**Fix:** Use `printenv` instead of bash indirect expansion:

```bash
# WRONG - requires bash
inner_value="${!var_name}"

# CORRECT - POSIX compliant, works in sh
inner_value="$(printenv "$var_name")"
```

**Prevention:** Test scripts with `/bin/sh` instead of `/bin/bash`. Use POSIX-compliant constructs.

---

## Issue 8: Auth0 Deploy Fails - sed Parsing Error

**Error pattern:**
```
sed: bad flag in substitute command
```

**Root cause:** Secret value contains special characters (`&`, `/`, `|`, `\`) that break sed.

**Fix:** Escape special characters before sed substitution:

```bash
# Escape all special sed characters
escaped_value=$(printf '%s\n' "$secret_value" | sed 's/[&/|\\]/\\&/g')

# Then use pipe as delimiter (not /)
sed -i "s|##PLACEHOLDER##|${escaped_value}|g" file.json
```

**Prevention:** Always escape secrets before sed operations. Consider using `envsubst` or `jq` for JSON files.

---

## Issue 9: NuGet Jobs Run on Every MR

**Error pattern:** NuGet pack jobs run on merge request pipelines when they should only run on main.

**Root cause:** Template default rules trigger pack when `src/` files change, without branch constraint.

**Fix:** Add explicit rules to only run on main branch:

```yaml
nuget-pack-client:
  extends: .nuget-pack
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      changes:
        - src/**/*
```

**Prevention:** Always add `$CI_COMMIT_BRANCH == "main"` rule to NuGet pack jobs.

---

## Issue 10: Production Jobs Bypass Manual Gate

**Error pattern:** Production deployments start before manual approval completes.

**Root cause:** Jobs have explicit `needs:` that bypass stage ordering. GitLab CI `needs:` overrides stage-based DAG.

**Fix:** Add `manual-approval-prod` to `needs:` of ALL production jobs:

```yaml
deploy-prod-job:
  needs:
    - job: manual-approval-prod  # REQUIRED
    - job: push-docker-images-prod

push-docker-images-prod:
  needs:
    - job: manual-approval-prod  # REQUIRED
    - job: calculate-version
    - job: docker-build-job
```

**Prevention:** Every job in `deploy-prod` stage MUST include `manual-approval-prod` in its `needs:` list.

---

## Issue 11: Flaky Tests Block Pipeline

**Error pattern:** Test passes locally but fails in CI, often with timing-related errors.

**Root cause:** Fixed `Thread.Sleep()` or `Task.Delay()` times are insufficient in CI environment (slower runners, shared resources).

**Fix:** Skip test with clear documentation:

```csharp
[Fact(Skip = "Flaky test - async timing issue in CI. " +
             "Needs refactoring to use polling instead of fixed sleep. " +
             "TODO: Refactor post-migration.")]
public async Task FlakyTestName()
{
    // Test implementation
}
```

**Prevention:** After migration, refactor to use polling:

```csharp
// Replace fixed sleep
await Task.Delay(10000);

// With polling
var timeout = TimeSpan.FromSeconds(30);
var pollInterval = TimeSpan.FromSeconds(1);
var startTime = DateTime.UtcNow;

while (DateTime.UtcNow - startTime < timeout)
{
    var status = await GetOperationStatus();
    if (status == OperationStatus.Completed)
        break;
    await Task.Delay(pollInterval);
}
```

---

## Issue 12: Matrix Job Variable Collisions

**Error pattern:** Downstream matrix job uses wrong variable value from upstream matrix job.

**Root cause:** GitLab dotenv artifacts from all matrix instances are merged, causing variable name collisions.

**Fix:** Use unique variable names per matrix instance:

```yaml
# Upstream job creates unique variables
auth0-prepare-lower:
  script:
    - |
      cat << EOF > build-${REGION}-${STACK_ENVIRONMENT}.env
      AUTHENTICATION_API_KEY_${REGION}_${STACK_ENVIRONMENT}=$(az keyvault secret show ...)
      EOF

# Downstream job uses matching variable
auth0-deploy-lower:
  script:
    - |
      inner_var="AUTHENTICATION_API_KEY_${REGION}_${STACK_ENVIRONMENT}"
      inner_value="$(printenv "$inner_var")"
```

**Prevention:** Always suffix dotenv variable names with region/environment identifiers.

---

## Issue 13: Connection String Key Wrong

**Error pattern:** Database connection fails with null connection string.

**Root cause:** Using wrong key name when querying Azure App Configuration.

**Fix:** Check actual application code for the correct key:

```csharp
// In Startup.cs or Program.cs
services.AddDbContext<MyContext>(options =>
    options.UseSqlServer(Configuration.GetConnectionString("ClientsDB_Failover")));
    //                                                      ^^^^^^^^^^^^^^^^^^
    //                                                      This is the key to use
```

Then use that key in the pipeline:
```yaml
- export CONNECTION_STRING=$(az appconfig kv show \
    --name ${APPCONFIG_NAME} \
    --key "ConnectionStrings:ClientsDB_Failover" \
    --query value -o tsv)
```

**Prevention:** Always verify connection string key from application source code, not from documentation or assumptions.

---

## Issue 14: Review App Swagger Returns 404

**Error pattern:** Hitting `/swagger` or `/swagger/index.html` on the review app returns 404.

**Root cause:** `ForwardedHeadersOptions` not configured in `Startup.cs`. The review app runs behind a gateway that terminates TLS — the pod receives plain HTTP. Without forwarded headers configured, `UseHttpsRedirection` redirects or `UseOpenApi` generates incorrect `http://` URLs, breaking the swagger endpoint.

> Note: Setting `ASPNETCORE_FORWARDEDHEADERS_ENABLED: "true"` in the deployment env vars is not sufficient on its own — the app must also configure `ForwardedHeadersOptions` in `ConfigureServices` to trust the pod network CIDR, and call `UseForwardedHeaders()` early in the middleware pipeline.

**Fix:** Add to `Startup.cs`:

```csharp
// ConfigureServices — add at the end
services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Add(new Microsoft.AspNetCore.HttpOverrides.IPNetwork(IPAddress.Parse("100.0.0.0"), 8));
});

// Configure — add as first middleware call
app.UseForwardedHeaders();
```

Required usings:
```csharp
using System.Net;
using Microsoft.AspNetCore.HttpOverrides;
```

**Prevention:** Step 0 of `/dotnet:trunk-migrate` now checks for forwarded headers configuration before proceeding.

---

## Issue 15: Review App All Endpoints Return 404

**Error pattern:** Every endpoint on the review app URL returns 404, including `/v1/health`. The pod is running and healthy (readiness probe passes at pod level), but no traffic reaches it through the review domain.

**Root cause:** The HTTPRoute `parentRef` points to the wrong gateway. Services that use Traefik `IngressRoute` for production were incorrectly configured with `name: traefik-gateway, namespace: traefik` in review app HTTPRoutes. Traefik does not process Gateway API `HTTPRoute` resources — it only handles its own `IngressRoute` CRD. The Traefik gateway ignores the HTTPRoute, so no route is ever registered for the review domain.

**Fix:** Update all three review overlay files to use the Azure ALB Gateway:

```yaml
parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: gateway          # NOT traefik-gateway
    namespace: azure-alb   # NOT traefik
    sectionName: https-listener  # or http-listener for redirect
```

Files to update:
- `k8s/overlays/review/resources/https-route.yaml`
- `k8s/overlays/review/resources/http-to-https-redirect.yaml`
- `k8s/overlays/review/patch-https-route.yaml.template`

Also update `trunk-migration-config.yaml`:
```yaml
gateway:
  name: "gateway"
  namespace: "azure-alb"
```

**Prevention:** Discovery skill now explicitly defaults to `gateway`/`azure-alb` when a service uses Traefik IngressRoute for production, since these are entirely separate routing mechanisms.

---

## General Diagnostic Steps

If the issue doesn't match any of the above:

1. **Check kustomize build output:**
   ```bash
   kustomize build k8s/{region}/{env} > /tmp/debug.yaml
   cat /tmp/debug.yaml
   ```

2. **Check pod logs:**
   ```bash
   kubectl logs -n platform deploy/SERVICE_NAME --tail=100
   ```

3. **Check pod events:**
   ```bash
   kubectl describe pod -n platform -l app=SERVICE_NAME
   ```

4. **Check pipeline job logs** in GitLab CI/CD > Pipelines > Jobs

5. **Verify secrets exist:**
   ```bash
   kubectl get secret SERVICE_NAME-secrets -n platform
   kubectl describe secret SERVICE_NAME-secrets -n platform
   ```

6. **Check review app namespace:**
   ```bash
   kubectl get all -n APP_NAME-mr-{MR_ID}
   ```
