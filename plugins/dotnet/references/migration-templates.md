# Migration Templates Reference

Templates used by trunk-migration skills during the migration process. All templates use placeholder values that must be substituted with service-specific configuration.

## Placeholder Conventions

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `SERVICE_NAME` | Kubernetes service name | `clientbuilding-api` |
| `APP_NAME` | Application short name | `clientbuilding` |
| `FULL_SERVICE_NAME` | Display name for New Relic | `Trigent.Platform.ClientBuildingService.Api` |
| `REGISTRY_PLACEHOLDER` | Base ACR placeholder | `REGISTRY_PLACEHOLDER` |
| `TAG_PLACEHOLDER` | Image tag placeholder | `TAG_PLACEHOLDER` |
| `DOMAIN_PLACEHOLDER` | Base domain placeholder | `trigent.com` |
| `CONNECTION_STRING_KEY` | Azure App Config key | `ClientsDB_Failover` |
| `UI_TESTS_TRIGGER_PROJECT` | GitLab QA automation project path | `trigent1/trigent/.../web-ui-framework-2-platform` |
| `{{placeholder}}` | Review app runtime substitution | `{{MR_ID}}`, `{{REVIEW_HOST}}` |
| `{{IMAGE-NAME_REGISTRY_NAME}}` | Review app ACR registry per image (hyphens preserved from image name) | `{{WEBHOOKS-INCIDENT_REGISTRY_NAME}}` |

---

## Startup.cs Modifications

Services running behind a reverse proxy (Kubernetes ingress/gateway) must configure forwarded headers so ASP.NET Core correctly reads `X-Forwarded-For` and `X-Forwarded-Proto`. Without this, `UseHttpsRedirection` and Swagger generate incorrect `http://` URLs, causing 404s and mixed-content errors in review apps.

### Required changes

**In `ConfigureServices`** — add after existing service registrations:

```csharp
// Configure forwarded headers for running behind reverse proxy/ingress
services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Add(new Microsoft.AspNetCore.HttpOverrides.IPNetwork(IPAddress.Parse("100.0.0.0"), 8));
});
```

**In `Configure`** — add `app.UseForwardedHeaders()` as the first middleware call:

```csharp
public void Configure(IApplicationBuilder app, IWebHostEnvironment env, ...)
{
    app.UseForwardedHeaders();  // MUST be first
    // ... rest of middleware
}
```

**Required usings:**

```csharp
using System.Net;
using Microsoft.AspNetCore.HttpOverrides;
```

> **Note on IPNetwork ambiguity:** In .NET 8+, `IPNetwork` exists in both `System.Net` and `Microsoft.AspNetCore.HttpOverrides`. Always use the fully qualified `Microsoft.AspNetCore.HttpOverrides.IPNetwork` to avoid `CS0104` ambiguous reference errors.

> **Why `100.0.0.0/8`?** This is the pod network CIDR in the Trigent AKS clusters. The gateway forwards requests from pod IPs in this range, so they must be in `KnownNetworks` for ASP.NET Core to trust the forwarded headers.

---

## Kustomize Base Manifests

### deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: SERVICE_NAME
  namespace: platform
spec:
  selector:
    matchLabels:
      app: SERVICE_NAME
  template:
    metadata:
      labels:
        app: SERVICE_NAME
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      nodeSelector:
        agentpool: app2np
      containers:
        - name: SERVICE_NAME
          image: REGISTRY_PLACEHOLDER.azurecr.io/SERVICE_NAME:TAG_PLACEHOLDER
          securityContext:
            allowPrivilegeEscalation: false
          resources:
            limits:
              memory: "1Gi"
              cpu: "600m"
            requests:
              memory: "800Mi"
              cpu: "450m"
          startupProbe:
            httpGet:
              path: /v1/health
              port: 8080
            failureThreshold: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /v1/health
              port: 8080
            initialDelaySeconds: 10
            failureThreshold: 3
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /v1/health
              port: 8080
            initialDelaySeconds: 60
            failureThreshold: 3
            periodSeconds: 10
          ports:
            - containerPort: 8080
          env:
            - name: ASPNETCORE_URLS
              value: "http://+:8080"
            - name: AZURE_APPCONFIG_ENDPOINT
              valueFrom:
                secretKeyRef:
                  name: SERVICE_NAME-secrets
                  key: azure-appconfig-endpoint
            - name: AZURE_CLIENT_ID
              valueFrom:
                secretKeyRef:
                  name: SERVICE_NAME-secrets
                  key: azure-client-id
            - name: AZURE_TENANT_ID
              valueFrom:
                secretKeyRef:
                  name: SERVICE_NAME-secrets
                  key: azure-tenant-id
            - name: AZURE_CLIENT_SECRET
              valueFrom:
                secretKeyRef:
                  name: SERVICE_NAME-secrets
                  key: azure-client-secret
            - name: NEW_RELIC_LICENSE_KEY
              valueFrom:
                secretKeyRef:
                  name: SERVICE_NAME-secrets
                  key: new-relic-license-key
```

**Customization notes:**
- Replace `SERVICE_NAME` with actual service name
- Adjust health check path if different from `/v1/health`
- Adjust resource limits based on current usage
- Add any additional environment variables from existing manifests

### service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: SERVICE_NAME-service
  namespace: platform
spec:
  selector:
    app: SERVICE_NAME
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
```

### ingressroute.yaml

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: SERVICE_NAME-ingress
  namespace: platform
spec:
  routes:
    - match: HostRegexp(`SERVICE_NAME.internal.DOMAIN_PLACEHOLDER`)
      kind: Rule
      services:
        - name: SERVICE_NAME-service
          port: 80
```

### hpa.yaml

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: SERVICE_NAME-hpa
  namespace: platform
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: SERVICE_NAME
  minReplicas: 1
  maxReplicas: 4
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

### namespace.yaml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: platform
```

### kustomization.yaml (base)

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
  - ingressroute.yaml
  - hpa.yaml
```

---

## Environment Overlay Templates

### overlays/dev/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patches:
  - patch: |-
      apiVersion: autoscaling/v2
      kind: HorizontalPodAutoscaler
      metadata:
        name: SERVICE_NAME-hpa
      spec:
        minReplicas: 1
        maxReplicas: 4
    target:
      kind: HorizontalPodAutoscaler
      name: SERVICE_NAME-hpa
```

### overlays/staging/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patches:
  - patch: |-
      apiVersion: autoscaling/v2
      kind: HorizontalPodAutoscaler
      metadata:
        name: SERVICE_NAME-hpa
      spec:
        minReplicas: 1
        maxReplicas: 4
    target:
      kind: HorizontalPodAutoscaler
      name: SERVICE_NAME-hpa
```

### overlays/prod/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base
  - hpa-patch.yaml
```

### overlays/prod/hpa-patch.yaml

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: SERVICE_NAME-hpa
  namespace: platform
spec:
  minReplicas: 4
  maxReplicas: 100
```

---

## Region Kustomization Template

Each region/environment combination gets a kustomization file following this pattern:

### {region}/{environment}/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../overlays/{ENVIRONMENT}

images:
  - name: REGISTRY_PLACEHOLDER.azurecr.io/SERVICE_NAME
    newName: {REGION_ACR}.azurecr.io/SERVICE_NAME
    newTag: TAG_PLACEHOLDER

patches:
  - patch: |-
      apiVersion: traefik.containo.us/v1alpha1
      kind: IngressRoute
      metadata:
        name: SERVICE_NAME-ingress
      spec:
        routes:
          - match: HostRegexp(`SERVICE_NAME.internal.{DOMAIN}`)
            kind: Rule
            services:
              - name: SERVICE_NAME-service
                port: 80
    target:
      kind: IngressRoute
      name: SERVICE_NAME-ingress
  - patch: |-
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: SERVICE_NAME
      spec:
        template:
          spec:
            containers:
              - name: SERVICE_NAME
                env:
                  - name: NEW_RELIC_APP_NAME
                    value: "FULL_SERVICE_NAME-{ENV_SUFFIX}"
    target:
      kind: Deployment
      name: SERVICE_NAME
```

**CRITICAL**: Each region overlay MUST include:
1. Complete IngressRoute patch with `match`, `kind`, AND `services`
2. ACR URL replacement
3. Domain replacement
4. `NEW_RELIC_APP_NAME` patch

**Region/Environment naming convention for New Relic**:
- US dev: `ServiceName-dev`
- US staging: `ServiceName-stag`
- US prod: `ServiceName-prod`
- UK dev: `ServiceName-devuk`
- UK staging: `ServiceName-staguk`
- UK prod: `ServiceName-produk`

---

## Review Overlay Templates

All review overlay files use `.template` extension with `{{placeholder}}` syntax that the review-app pipeline template will substitute at runtime.

**CRITICAL namespace requirement:** All patch templates MUST include `namespace: NAMESPACE` (the base namespace, typically `platform`) in their metadata. Kustomize strategic merge patches match resources by apiVersion/kind/name/namespace — without the namespace, patches fail to match base resources. The kustomization.yaml.template `namespace:` field overrides all namespaces to `APP_NAME-mr-{{MR_ID}}` *after* patches are applied.

### overlays/review/kustomization.yaml.template

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base
  - resources/https-route.yaml
  - resources/http-to-https-redirect.yaml

namePrefix: ""
nameSuffix: -mr-{{MR_ID}}
namespace: APP_NAME-mr-{{MR_ID}}

images:
  - name: REGISTRY_PLACEHOLDER.azurecr.io/SERVICE_NAME
    newName: "{{API_REGISTRY_NAME}}"
    newTag: "api-{{IMAGE_TAG}}"

patches:
  - path: add-nodeselector.patch.yaml
    target:
      kind: Deployment

  - patch: |
      apiVersion: gateway.networking.k8s.io/v1
      kind: HTTPRoute
      metadata:
        name: http-to-https-redirect
      spec:
        hostnames:
          - "{{REVIEW_HOST}}"
    target:
      kind: HTTPRoute
      name: http-to-https-redirect

  - patch: |
      apiVersion: traefik.containo.us/v1alpha1
      kind: IngressRoute
      metadata:
        name: SERVICE_NAME-ingress
      $patch: delete
    target:
      kind: IngressRoute
      name: SERVICE_NAME-ingress

  - path: patch-api-deployment.yaml
  - path: patch-api-service.yaml
  - path: patch-api-hpa.yaml
  - path: patch-https-route.yaml

labels:
  - pairs:
      review-app: "mr-{{MR_ID}}"
      merge-request-id: "{{MR_ID}}"
```

### overlays/review/add-nodeselector.patch.yaml.template

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: SERVICE_NAME
  namespace: NAMESPACE
spec:
  template:
    spec:
      nodeSelector:
        agentpool: reviewspotnp
      tolerations:
        - key: "kubernetes.azure.com/scalesetpriority"
          operator: "Equal"
          value: "spot"
          effect: "NoSchedule"
```

### overlays/review/patch-api-deployment.yaml.template

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: SERVICE_NAME
  namespace: NAMESPACE
spec:
  template:
    spec:
      imagePullSecrets:
        - name: {{IMAGE_PULL_SECRET}}
      containers:
        - name: SERVICE_NAME
          resources:
            limits:
              memory: "300Mi"
              cpu: "200m"
            requests:
              memory: "100Mi"
              cpu: "50m"
          startupProbe:
            httpGet:
              path: /v1/health
              port: 8080
            failureThreshold: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /v1/health
              port: 8080
            initialDelaySeconds: 5
            failureThreshold: 3
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /v1/health
              port: 8080
            initialDelaySeconds: 30
            failureThreshold: 3
            periodSeconds: 10
          env:
            - name: ASPNETCORE_URLS
              value: "http://+:8080"
              valueFrom: null
            - name: ASPNETCORE_FORWARDEDHEADERS_ENABLED
              value: "true"
            - name: AZURE_APPCONFIG_ENDPOINT
              value: "{{AZURE_APPCONFIG_ENDPOINT}}"
              valueFrom: null
            - name: AZURE_CLIENT_ID
              value: "{{AZURE_CLIENT_ID}}"
              valueFrom: null
            - name: AZURE_TENANT_ID
              value: "{{AZURE_TENANT_ID}}"
              valueFrom: null
            - name: AZURE_CLIENT_SECRET
              value: "{{AZURE_CLIENT_SECRET}}"
              valueFrom: null
            - name: NEW_RELIC_LICENSE_KEY
              value: "{{NEW_RELIC_LICENSE_KEY}}"
              valueFrom: null
            - name: NEW_RELIC_APP_NAME
              value: "FULL_SERVICE_NAME-mr-{{MR_ID}}"
              valueFrom: null
```

**CRITICAL**: `valueFrom: null` is required to override the `secretKeyRef` from base deployment.

**CRITICAL**: `ASPNETCORE_FORWARDEDHEADERS_ENABLED: "true"` is required because review apps are served over HTTPS via the Gateway (ALB/Envoy), but TLS terminates at the gateway — the pod receives plain HTTP. Without forwarded headers, ASP.NET Core reports `httpReq.Scheme` as `http`, causing Swagger and other middleware to generate `http://` URLs that trigger mixed-content errors in the browser.

### overlays/review/patch-api-service.yaml.template

```yaml
apiVersion: v1
kind: Service
metadata:
  name: SERVICE_NAME-service
  namespace: NAMESPACE
spec:
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
```

### overlays/review/patch-api-hpa.yaml.template

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: SERVICE_NAME-hpa
  namespace: NAMESPACE
spec:
  minReplicas: 1
  maxReplicas: 1
```

### overlays/review/patch-https-route.yaml.template

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: https-route
  namespace: NAMESPACE
spec:
  hostnames:
    - "{{REVIEW_HOST}}"
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: GATEWAY_NAME
      namespace: GATEWAY_NAMESPACE
      sectionName: https-listener
  rules:
    - backendRefs:
        - group: ''
          kind: Service
          name: "SERVICE_NAME-service-mr-{{MR_ID}}"
          port: 80
          weight: 1
      matches:
        - path:
            type: PathPrefix
            value: /
```

### overlays/review/resources/https-route.yaml

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: https-route
  namespace: NAMESPACE
spec:
  hostnames:
    - "{{REVIEW_HOST}}"
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: GATEWAY_NAME
      namespace: GATEWAY_NAMESPACE
      sectionName: https-listener
  rules:
    - backendRefs:
        - group: ''
          kind: Service
          name: SERVICE_NAME-service-mr-{{MR_ID}}
          port: 80
          weight: 1
      matches:
        - path:
            type: PathPrefix
            value: /
```

### overlays/review/resources/http-to-https-redirect.yaml

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-to-https-redirect
  namespace: NAMESPACE
spec:
  hostnames:
    - "{{REVIEW_HOST}}"
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: GATEWAY_NAME
      namespace: GATEWAY_NAMESPACE
      sectionName: http-listener
  rules:
    - filters:
        - type: RequestRedirect
          requestRedirect:
            scheme: https
            statusCode: 301
```

---

## GitLab CI/CD Templates

### Workflow Rules

```yaml
workflow:
  auto_cancel:
    on_new_commit: interruptible
  rules:
    - if: $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == 'main'
    - if: $CI_COMMIT_BRANCH == 'main' && $CI_PIPELINE_SOURCE == 'web'
    - if: $CI_COMMIT_BRANCH == 'main'
```

### YAML Anchors

```yaml
.regions: &regions [us, uk]
.lower-environments: &lower-environments [dev, staging]
```

### Stages

```yaml
stages:
  - build-artifacts
  - publish-packages
  - review
  - deploy-lower
  - prod-gate
  - deploy-prod
  - post-deploy
```

### Variables

```yaml
variables:
  APP_NAME: "APP_NAME"
  PROJECT_PATH: "PROJECT_PATH"
  SERVICE_NAME: "SERVICE_NAME"
  ACR_URL: "${AZURE_CONTAINER_REGISTRY}"
  OUTPUT_PATH: "out"
  DLL_PATH: "DLL_PATH"
```

### Include Block

```yaml
include:
  # Core templates
  - project: trigent1/pipeline-templates
    ref: v5
    file: verify-staging-no-op.yml
  - project: trigent1/pipeline-templates
    ref: v5
    file: prod-gate-manual-approval.yml
  - project: trigent1/pipeline-templates
    ref: v5
    file: version/semantic-release.yml
  - project: trigent1/pipeline-templates
    ref: v5
    file: docker/build.yml
  - project: trigent1/pipeline-templates
    ref: v5
    file: dotnet/coverage.yml
    inputs:
      test-job-name: test-job

  # [CONDITIONAL] NuGet packages
  - project: trigent1/pipeline-templates
    ref: v5
    file: dotnet/nuget.yml
    inputs:
      project-path: PROJECT_PATH.Client.csproj
      pack-job-name: nuget-pack-client

  # [CONDITIONAL] Swagger — include ONCE, use parallel:matrix in job for multi-version
  - project: trigent1/pipeline-templates
    ref: v5
    file: dotnet/swagger.yml
    inputs:
      api-project-path: PROJECT_PATH.csproj
      api-dll-name: DLL_PATH
      swagger-version: v1  # Default, overridden by parallel:matrix in job

  # [CONDITIONAL] APIM deployment — include ONCE, use parallel:matrix in job for multi-version
  - project: trigent1/pipeline-templates
    ref: v5
    file: azure/apim-deploy.yml
    inputs:
      api-name: SERVICE_NAME
      api-version: v1  # Default, overridden by parallel:matrix in job
      openapi-file-path: out/swagger/swagger_v1.json  # Default, overridden by parallel:matrix in job

  # [CONDITIONAL] EF Migrations
  - project: trigent1/pipeline-templates
    ref: v5
    file: dotnet/ef-migrations.yml
    inputs:
      migrations-path: DATA_MIGRATIONS_DIR/Migrations
      data-project-path: DATA_MIGRATIONS_CSPROJ_PATH
      startup-project-path: PROJECT_PATH.csproj
  - project: trigent1/pipeline-templates
    ref: v5
    file: sql/sql-script-deploy.yml
    inputs:
      script-path: DATA_MIGRATIONS_DIR/migration.sql

  # Deployment templates
  - project: trigent1/pipeline-templates
    ref: v5
    file: azure/push-docker-images.yml
  - project: trigent1/pipeline-templates
    ref: v5
    file: kubernetes/kustomize-deploy.yml

  # Review apps
  - project: trigent1/pipeline-templates
    ref: v5
    file: kubernetes/review-app.yml
    inputs:
      app-name: APP_NAME
      review-domain: review.trigent.com
      kustomize-base-path: k8s/overlays/review
      key-vault-name: "${KV_NAME}"
      cluster-resource-group: CLUSTER_RG
      cluster-name: CLUSTER_NAME
      image-names: api
```

### Docker Build Job

```yaml
docker-build-job:
  extends: .build-docker-image
  parallel:
    matrix:
      - IMAGE_NAME: api
        DOCKERFILE: PROJECT_PATH/Dockerfile
        BUILD_ARGS: "GITLAB_PACKAGE_REGISTRY_USERNAME=$CI_REGISTRY_USER GITLAB_PACKAGE_REGISTRY_PASSWORD=$CI_REGISTRY_PASSWORD"
```

### Test Job

```yaml
test-job:
  stage: build-artifacts
  image: mcr.microsoft.com/dotnet/sdk:8.0-bookworm-slim
  tags:
    - docker
  before_script:
    - export GITLAB_PACKAGE_REGISTRY_USERNAME=$CI_REGISTRY_USER
    - export GITLAB_PACKAGE_REGISTRY_PASSWORD=$CI_REGISTRY_PASSWORD
  script:
    - dotnet test --collect:"XPlat Code Coverage" --results-directory TestResults --logger "trx"
  artifacts:
    when: always
    paths:
      - TestResults/
    reports:
      junit: TestResults/*.trx
      coverage_report:
        coverage_format: cobertura
        path: TestResults/*/coverage.cobertura.xml
  coverage: '/Total\s+\|\s+(\d+(?:\.\d+)?%)/'
```

### Coverage Job

The `dotnet/coverage.yml` include provides a hidden `.coverage` job. It must be instantiated explicitly:

```yaml
coverage-job:
  extends: .coverage
```

This job reads the coverage artifacts from `test-job` (configured via `inputs.test-job-name` in the include) and reports the coverage percentage to GitLab.

### NuGet Pack Jobs (Conditional)

Create one pack job per NuGet package listed in `decisions.nuget.packages`. Each requires a matching include with the correct `project-path` and `pack-job-name` inputs.

```yaml
nuget-pack-PACKAGE_SUFFIX:
  extends: .nuget-pack
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      changes:
        - src/**/*
```

### NuGet Publish Jobs (Conditional)

```yaml
nuget-publish-pre-release:
  extends: .nuget-publish-prerelease

nuget-publish-main:
  extends: .nuget-publish-production
  dependencies:
    - nuget-pack-PACKAGE_SUFFIX  # List ALL nuget-pack jobs from above
    - calculate-version
```

**Note:** `nuget-publish-main` must list ALL nuget-pack jobs in `dependencies:` to download their artifacts. `nuget-publish-pre-release` publishes pre-release packages on MR branches. Both are provided by the `dotnet/nuget.yml` template.

### Swagger Generation - Single Version

```yaml
generate-swagger-job:
  extends: .generate-swagger
  needs:
    - job: docker-build-job
  before_script:
    - !reference [.generate-swagger, before_script]
    - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    - az login --service-principal --username ${ARM_CLIENT_ID} --password=${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID}
    - az account set --subscription ${ARM_SUBSCRIPTION_ID}
    - export AZURE_APPCONFIG_ENDPOINT=$(az keyvault secret show --name azure-appconfig-endpoint --vault-name ${KV_NAME} --query value -o tsv)
  variables:
    AZURE_CLIENT_ID: ${ARM_CLIENT_ID}
    AZURE_CLIENT_SECRET: ${ARM_CLIENT_SECRET}
    AZURE_TENANT_ID: ${ARM_TENANT_ID}
    ConnectionStrings__DefaultConnection: "Server=localhost;Database=swagger;Integrated Security=true;"
  environment:
    name: "azure/us/dev/build"
```

### Swagger Generation - Multi-Version

```yaml
generate-swagger-job:
  extends: .generate-swagger
  parallel:
    matrix:
      - SWAGGER_VERSION: v1
        FINAL_FILENAME: swagger_v1.json
      - SWAGGER_VERSION: v2
        FINAL_FILENAME: swagger_v2.json
  needs:
    - job: docker-build-job
  before_script:
    - !reference [.generate-swagger, before_script]
    - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    - az login --service-principal --username ${ARM_CLIENT_ID} --password=${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID}
    - az account set --subscription ${ARM_SUBSCRIPTION_ID}
    - export AZURE_APPCONFIG_ENDPOINT=$(az keyvault secret show --name azure-appconfig-endpoint --vault-name ${KV_NAME} --query value -o tsv)
  variables:
    AZURE_CLIENT_ID: ${ARM_CLIENT_ID}
    AZURE_CLIENT_SECRET: ${ARM_CLIENT_SECRET}
    AZURE_TENANT_ID: ${ARM_TENANT_ID}
    ConnectionStrings__DefaultConnection: "Server=localhost;Database=swagger;Integrated Security=true;"
  environment:
    name: "azure/us/dev/build"
```

### EF Migration Validation Job (Conditional)

```yaml
validate-migration-script-job:
  extends: .validate-migration-script
  variables:
    DB_CONTEXT_NAME: DB_CONTEXT_NAME
    DATA_PROJECT_PATH: DATA_MIGRATIONS_CSPROJ_PATH  # Full .csproj path (e.g., src/.../DataMigrations.csproj)
    STARTUP_PROJECT_PATH: PROJECT_PATH.csproj
    AZURE_CLIENT_ID: ${ARM_CLIENT_ID}
    AZURE_CLIENT_SECRET: ${ARM_CLIENT_SECRET}
    AZURE_TENANT_ID: ${ARM_TENANT_ID}
    ConnectionStrings__DefaultConnection: "Server=localhost;Database=migrations;Integrated Security=true;"
  before_script:
    - !reference [.validate-migration-script, before_script]
    # NuGet auth for private package registry (required if project references private packages)
    - export GITLAB_PACKAGE_REGISTRY_USERNAME=$CI_REGISTRY_USER
    - export GITLAB_PACKAGE_REGISTRY_PASSWORD=$CI_REGISTRY_PASSWORD
    - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    - az login --service-principal --username ${ARM_CLIENT_ID} --password=${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID}
    - az account set --subscription ${ARM_SUBSCRIPTION_ID}
    - export AZURE_APPCONFIG_ENDPOINT=$(az keyvault secret show --name azure-appconfig-endpoint --vault-name ${KV_NAME} --query value -o tsv)
  environment:
    name: "azure/us/dev/build"
```

### EF Migration Deployment - Lower Environments

```yaml
deploy-migrations-lower:
  extends: .deploy-sql-script
  stage: deploy-lower
  # No needs — stage-scheduled, waits for ALL build-artifacts jobs
  dependencies:
    - validate-migration-script-job  # Artifacts only (cross-stage)
  parallel:
    matrix:
      - REGION: *regions
        STACK_ENVIRONMENT: *lower-environments
  before_script:
    - !reference [.deploy-sql-script, before_script]
    - apt-get update && apt-get install -y curl
    - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    - az login --service-principal --username ${ARM_CLIENT_ID} --password=${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID}
    - az account set --subscription ${ARM_SUBSCRIPTION_ID}
    - |
      if [ "$REGION" = "us" ]; then
        if [ "$STACK_ENVIRONMENT" = "dev" ]; then
          export APPCONFIG_NAME="trigent-plt-app-config-dev-dr"
        elif [ "$STACK_ENVIRONMENT" = "staging" ]; then
          export APPCONFIG_NAME="trigent-plt-app-config-stag-dr"
        fi
      elif [ "$REGION" = "uk" ]; then
        if [ "$STACK_ENVIRONMENT" = "dev" ]; then
          export APPCONFIG_NAME="trigentuk-plt-app-config-dev"
        elif [ "$STACK_ENVIRONMENT" = "staging" ]; then
          export APPCONFIG_NAME="trigentuk-plt-app-config-stag"
        fi
      fi
    - export CONNECTION_STRING=$(az appconfig kv show --name ${APPCONFIG_NAME} --key "ConnectionStrings:CONNECTION_STRING_KEY" --query value -o tsv)
  variables:
    SQL_SCRIPT_PATH: "DATA_MIGRATIONS_PATH/migration.sql"
  environment:
    name: "azure/$REGION/$STACK_ENVIRONMENT/database"
```

### EF Migration Deployment - Production

```yaml
deploy-migrations-prod:
  extends: deploy-migrations-lower
  stage: deploy-prod
  # No needs — stage-scheduled, waits for ALL prod-gate jobs
  parallel:
    matrix:
      - REGION: *regions
  variables:
    STACK_ENVIRONMENT: prod
    SQL_SCRIPT_PATH: "DATA_MIGRATIONS_PATH/migration.sql"
  before_script:
    - !reference [deploy-migrations-lower, before_script]
    - |
      if [ "$REGION" = "us" ]; then
        export APPCONFIG_NAME="trigent-plt-app-config-prod-dr"
      elif [ "$REGION" = "uk" ]; then
        export APPCONFIG_NAME="trigentuk-plt-app-config-prod"
      fi
    - export CONNECTION_STRING=$(az appconfig kv show --name ${APPCONFIG_NAME} --key "ConnectionStrings:CONNECTION_STRING_KEY" --query value -o tsv)
  environment:
    name: "azure/$REGION/prod/database"
    deployment_tier: production
```

### Auth0 Deployment - Lower Environments (Conditional)

```yaml
auth0-deploy-lower:
  stage: deploy-lower
  tags:
    - docker
  image:
    name: node:20-alpine
  parallel:
    matrix:
      - REGION: *regions
        STACK_ENVIRONMENT: *lower-environments
  variables:
    AUTH0_CONFIG_FILE: "./auth0/config/${REGION}/config-${STACK_ENVIRONMENT}.json"
  before_script:
    - npm install -g auth0-deploy-cli
    - apk add --no-cache bash azure-cli
    - az login --service-principal --username ${ARM_CLIENT_ID} --password=${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID}
    - az account set --subscription ${ARM_SUBSCRIPTION_ID}
    - export AUTHENTICATION_API_KEY=$(az keyvault secret show --name APIKeys--authenticationPrimaryKey --vault-name ${KV_NAME} --query value -o tsv)
  script:
    - |
      # Securely inject API key
      inner_auth_api_key_value="$(printenv "AUTHENTICATION_API_KEY")"

      if [ -z "$inner_auth_api_key_value" ]; then
        echo "ERROR: AUTHENTICATION_API_KEY is empty or not set"
        exit 1
      fi

      # Escape special characters for sed
      escaped_value=$(printf '%s\n' "$inner_auth_api_key_value" | sed 's/[&/|\\]/\\&/g')

      # Replace placeholder
      sed -i "s|##AUTHENTICATION_API_KEY##|${escaped_value}|g" "$AUTH0_CONFIG_FILE"

      # Verify replacement succeeded
      if grep -q "##AUTHENTICATION_API_KEY##" "$AUTH0_CONFIG_FILE"; then
        echo "ERROR: Placeholder replacement failed"
        exit 1
      fi
    - |
      cp -R ./auth0 ./auth0-${REGION}
      a0deploy import -c=$AUTH0_CONFIG_FILE --input_file=./auth0-${REGION}
  environment:
    name: "azure/$REGION/$STACK_ENVIRONMENT/auth0"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      changes:
        - auth0/**/*
```

### Auth0 Deployment - Production (Conditional)

```yaml
auth0-deploy-prod:
  extends: auth0-deploy-lower
  stage: deploy-prod
  # No needs — stage-scheduled, waits for ALL prod-gate jobs
  parallel:
    matrix:
      - REGION: *regions
  variables:
    STACK_ENVIRONMENT: prod
    AUTH0_CONFIG_FILE: "./auth0/config/${REGION}/config-prod.json"
  environment:
    name: "azure/$REGION/prod/auth0"
    deployment_tier: production
```

### APIM Deployment - Single Version

```yaml
upload-api-lower:
  extends: .deploy-apim
  stage: deploy-lower
  # No needs — stage-scheduled, waits for ALL build-artifacts jobs (including generate-swagger-job)
  dependencies:
    - generate-swagger-job            # Artifacts only (cross-stage)
  parallel:
    matrix:
      - STACK_ENVIRONMENT: *lower-environments
        REGION: *regions
  variables:
    STACK_NAME: "APP_NAME"
    PRODUCT_NAME: "Unlimited"
    SERVER_URL: "http://SERVICE_NAME.internal.DOMAIN/v1"
    API_ID: "<existing-api-id-from-azure-apim>"  # USER-PROVIDED: get from Azure Portal > APIM > APIs
  environment:
    name: "azure/$REGION/$STACK_ENVIRONMENT/deploy"

upload-api-prod:
  extends: .deploy-apim
  stage: deploy-prod
  # No needs — stage-scheduled, waits for ALL prod-gate jobs (including manual-approval-prod)
  dependencies:
    - generate-swagger-job            # Artifacts only (cross-stage)
  parallel:
    matrix:
      - REGION: *regions
  variables:
    STACK_ENVIRONMENT: "prod"
    STACK_NAME: "APP_NAME"
    PRODUCT_NAME: "Unlimited"
    SERVER_URL: "http://SERVICE_NAME.internal.DOMAIN/v1"
    API_ID: "<existing-api-id-from-azure-apim>"  # USER-PROVIDED: get from Azure Portal > APIM > APIs
  environment:
    name: "azure/$REGION/prod/deploy"
    deployment_tier: production
```

**CRITICAL APIM configuration notes:**
- `STACK_NAME` is the API path (e.g., `clientbuilding` NOT `clientbuilding-api`)
- `SERVER_URL` must be HTTP (not HTTPS) - IngressRoute handles SSL
- `SERVER_URL` must include version suffix (`/v1`, `/v2`)
- Each region/environment/version needs its existing `API_ID` from Azure APIM
- These are existing identifiers — ask the user to provide them, do NOT generate new ones

### APIM Deployment - Multi-Version

```yaml
upload-api-lower:
  extends: .deploy-apim
  stage: deploy-lower
  # No needs — stage-scheduled, waits for ALL build-artifacts jobs (including generate-swagger-job)
  dependencies:
    - generate-swagger-job            # Artifacts only (cross-stage)
  parallel:
    matrix:
      # US Dev — API_IDs are USER-PROVIDED existing values from Azure APIM
      - STACK_ENVIRONMENT: dev
        REGION: us
        API_VERSION: v1
        API_ID: "<us-dev-v1-api-id>"              # Get from Azure Portal > APIM > APIs
        OPENAPI_FILE_PATH: out/swagger/swagger_v1.json
        SERVER_URL: "http://SERVICE_NAME.internal.trigent.com/v1"
      - STACK_ENVIRONMENT: dev
        REGION: us
        API_VERSION: v2
        API_ID: "<us-dev-v2-api-id>"              # Get from Azure Portal > APIM > APIs
        OPENAPI_FILE_PATH: out/swagger/swagger_v2.json
        SERVER_URL: "http://SERVICE_NAME.internal.trigent.com/v2"
      # UK Dev
      - STACK_ENVIRONMENT: dev
        REGION: uk
        API_VERSION: v1
        API_ID: "<uk-dev-v1-api-id>"              # Get from Azure Portal > APIM > APIs
        OPENAPI_FILE_PATH: out/swagger/swagger_v1.json
        SERVER_URL: "http://SERVICE_NAME.internal.cpoms.net/v1"
      - STACK_ENVIRONMENT: dev
        REGION: uk
        API_VERSION: v2
        API_ID: "<uk-dev-v2-api-id>"              # Get from Azure Portal > APIM > APIs
        OPENAPI_FILE_PATH: out/swagger/swagger_v2.json
        SERVER_URL: "http://SERVICE_NAME.internal.cpoms.net/v2"
      # Repeat for staging environments...
  variables:
    STACK_NAME: "APP_NAME"
    PRODUCT_NAME: "Unlimited"
  environment:
    name: "azure/$REGION/$STACK_ENVIRONMENT/deploy"
```

### Docker Push - Lower Environments

```yaml
push-docker-images-lower:
  extends: .push-docker-image
  stage: deploy-lower
  dependencies:
    - calculate-version
    - docker-build-job
  parallel:
    matrix:
      - REGION: *regions
        STACK_ENVIRONMENT: *lower-environments
        IMAGE_NAME: api
        SERVICE_NAME: SERVICE_NAME
  environment:
    name: "azure/$REGION/$STACK_ENVIRONMENT/docker"
```

### Kustomize Deployment - Lower Environments

```yaml
deploy-k8s-lower:
  extends: .deploy-kustomize
  stage: deploy-lower
  needs:
    - job: push-docker-images-lower
    - job: deploy-migrations-lower  # If using migrations
      optional: true
  parallel:
    matrix:
      - REGION: *regions
        STACK_ENVIRONMENT: *lower-environments
  variables:
    NAMESPACE: platform
    KUSTOMIZE_PATH: "k8s/${REGION}/${STACK_ENVIRONMENT}"
    SECRET_NAME: SERVICE_NAME-secrets
    WAIT_FOR_DEPLOYMENTS: "SERVICE_NAME"
  before_script:
    - !reference [.deploy-kustomize, before_script]
    - kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    - export AZURE_APPCONFIG_ENDPOINT=$(az keyvault secret show --name azure-appconfig-endpoint --vault-name ${KV_NAME} --query value -o tsv)
    - export NEW_RELIC_LICENSE_KEY=$(az keyvault secret show --name ExternalKeys--sharedserviceNewRelicApiKey --vault-name ${KV_NAME} --query value -o tsv)
    - |
      kubectl create secret generic ${SECRET_NAME} \
        --from-literal=azure-appconfig-endpoint="${AZURE_APPCONFIG_ENDPOINT}" \
        --from-literal=azure-client-id="${ARM_CLIENT_ID}" \
        --from-literal=azure-tenant-id="${ARM_TENANT_ID}" \
        --from-literal=azure-client-secret="${ARM_CLIENT_SECRET}" \
        --from-literal=new-relic-license-key="${NEW_RELIC_LICENSE_KEY}" \
        --namespace="${NAMESPACE}" \
        --dry-run=client -o yaml | kubectl apply -f -
  environment:
    name: "azure/$REGION/$STACK_ENVIRONMENT/deploy"
```

### Kustomize Deployment - Production

```yaml
deploy-prod-job:
  extends: .deploy-kustomize
  stage: deploy-prod
  needs:
    - job: push-docker-images-prod    # Same stage — intra-stage ordering
    - job: deploy-migrations-prod     # Same stage — intra-stage ordering
      optional: true
  parallel:
    matrix:
      - REGION: *regions
        STACK_ENVIRONMENT: prod
  variables:
    NAMESPACE: platform
    KUSTOMIZE_PATH: "k8s/${REGION}/${STACK_ENVIRONMENT}"
    SECRET_NAME: SERVICE_NAME-secrets
    WAIT_FOR_DEPLOYMENTS: "SERVICE_NAME"
  before_script:
    - !reference [.deploy-kustomize, before_script]
    - kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    - export AZURE_APPCONFIG_ENDPOINT=$(az keyvault secret show --name azure-appconfig-endpoint --vault-name ${KV_NAME} --query value -o tsv)
    - export NEW_RELIC_LICENSE_KEY=$(az keyvault secret show --name ExternalKeys--sharedserviceNewRelicApiKey --vault-name ${KV_NAME} --query value -o tsv)
    - |
      kubectl create secret generic ${SECRET_NAME} \
        --from-literal=azure-appconfig-endpoint="${AZURE_APPCONFIG_ENDPOINT}" \
        --from-literal=azure-client-id="${ARM_CLIENT_ID}" \
        --from-literal=azure-tenant-id="${ARM_TENANT_ID}" \
        --from-literal=azure-client-secret="${ARM_CLIENT_SECRET}" \
        --from-literal=new-relic-license-key="${NEW_RELIC_LICENSE_KEY}" \
        --namespace="${NAMESPACE}" \
        --dry-run=client -o yaml | kubectl apply -f -
  environment:
    name: "azure/$REGION/prod/deploy"
    deployment_tier: production
```

**CRITICAL deployment notes:**
- `NAMESPACE: platform` is job-specific (NOT global variable) so review-app template can use its own namespace
- `WAIT_FOR_DEPLOYMENTS` limits validation to this service only
- Use `v5` of `kustomize-deploy.yml` for `WAIT_FOR_DEPLOYMENTS` support
- Secrets are created before deployment via `--dry-run=client -o yaml | kubectl apply -f -`
- **Pipeline ordering**: Entry-point jobs in each stage (e.g., `push-docker-images-prod`, `deploy-migrations-prod`) have NO `needs` — they are stage-scheduled and wait for ALL previous stage jobs. Use `needs` ONLY for intra-stage ordering. Use `dependencies` for cross-stage artifact downloading. See `gitlab-ci-standards.md` for full rationale.

### Review App Jobs

```yaml
deploy-review-app-job:
  extends: .deploy-review-app
  variables:
    ARM_SUBSCRIPTION_ID: $ARM_SUBSCRIPTION_ID_DEV
  environment:
    on_stop: cleanup-review-app-job

cleanup-review-app-job:
  extends: .cleanup-review-app
  variables:
    ARM_SUBSCRIPTION_ID: $ARM_SUBSCRIPTION_ID_DEV
```

### Production Docker Push

```yaml
push-docker-images-prod:
  extends: .push-docker-image
  stage: deploy-prod
  # No needs — stage-scheduled, waits for ALL prod-gate jobs (including test-ui-staging + manual-approval-prod)
  dependencies:
    - calculate-version    # Artifacts only
    - docker-build-job     # Artifacts only
  parallel:
    matrix:
      - REGION: *regions
        IMAGE_NAME: api
        SERVICE_NAME: SERVICE_NAME
  environment:
    name: "azure/$REGION/prod/docker"
    deployment_tier: production
```

### UI Regression Tests (Optional)

```yaml
test-ui-staging:
  stage: prod-gate
  # No needs — stage-scheduled, waits for ALL deploy-lower jobs (deploy-k8s-lower, upload-api-lower, etc.)
  trigger:
    project: 'UI_TESTS_TRIGGER_PROJECT'
    branch: main
    strategy: depend
    forward:
      pipeline_variables: false
  variables:
    SCHEDULE_NAME: "CICD - SERVICE_DISPLAY_NAME - P0,P1 - Staging"
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
```

### UI Regression Tests - Production (Optional)

```yaml
test-ui-prod:
  stage: post-deploy
  # No needs — stage-scheduled, waits for ALL deploy-prod jobs (deploy-prod-job, upload-api-prod, etc.)
  trigger:
    project: 'UI_TESTS_TRIGGER_PROJECT'
    branch: main
    strategy: depend
    forward:
      pipeline_variables: false
  variables:
    SCHEDULE_NAME: "CICD - SERVICE_DISPLAY_NAME - P0,P1 - Prod"
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
```

---

## EF Migrations Assets

### .config/dotnet-tools.json

```json
{
  "version": 1,
  "isRoot": true,
  "tools": {
    "dotnet-ef": {
      "version": "8.0.11",
      "commands": ["dotnet-ef"]
    },
    "swashbuckle.aspnetcore.cli": {
      "version": "6.7.3",
      "commands": ["swagger"]
    }
  }
}
```

### Generate migration.sql

```bash
dotnet tool restore
dotnet ef migrations script --idempotent \
  --output DATA_MIGRATIONS_PATH/migration.sql \
  --project DATA_MIGRATIONS_PATH \
  --startup-project PROJECT_PATH
```

---

## Azure Functions Templates

These templates apply when one or more services in the config have `type: "functions-worker"` or `type: "functions-http"`. They replace or supplement the standard webapi templates.

### Additional Placeholders

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `FUNCTIONS_SECRET_NAME` | K8s secret name for this service | `webhooks-processor-secrets` |
| `SERVICE_BUS_SECRET_KEY` | Key Vault secret name for Service Bus connection string | `ConnectionStrings--webhooksServiceBusManageKey` |
| `SERVICEBUS_ENV_VAR_NAME` | Env var name for the Service Bus connection | `AzureWebJobsServiceBus` |
| `FUNCTIONS_RUNTIME` | Functions worker runtime value | `dotnet-isolated` |
| `FUNCTION_ALLOWLIST_N` | `AzureFunctionsJobHost__functions__N` values | `WebhookProcessorFunction` |

---

### Functions Worker Base Deployment (`functions-worker`)

Used for Service Bus, CosmosDB, blob, or other trigger-based workers. Differs from the webapi template:
- Health probe path is `/` (the Functions host built-in endpoint)
- Env vars use **placeholder string values** in the base — real values are injected via `$patch: replace` in the environment overlay (see below)
- Includes `FUNCTIONS_WORKER_RUNTIME`, `AzureFunctionsJobHost__functions__N`, `AzureWebJobsServiceBus`, and New Relic profiler vars
- No `service.yaml` in base — workers have no HTTP service for normal traffic

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: SERVICE_NAME
  namespace: NAMESPACE
  labels:
    app: SERVICE_NAME
    namespace: NAMESPACE
spec:
  selector:
    matchLabels:
      app: SERVICE_NAME
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: SERVICE_NAME
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      nodeSelector:
        agentpool: app2np
      containers:
        - name: SERVICE_NAME
          image: placeholder.azurecr.io/SERVICE_NAME
          imagePullPolicy: Always
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
            readOnlyRootFilesystem: false
          resources:
            requests:
              memory: "150Mi"
              cpu: "100m"
            limits:
              memory: "500Mi"
              cpu: "500m"
          ports:
            - containerPort: 8080
          startupProbe:
            httpGet:
              path: /
              port: 8080
            failureThreshold: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 10
            failureThreshold: 3
            periodSeconds: 10
            timeoutSeconds: 240
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 60
            failureThreshold: 3
            periodSeconds: 10
          env:
            - name: ASPNETCORE_URLS
              value: "http://+:8080"
            - name: AzureFunctionsJobHost__functions__0
              value: FUNCTION_ALLOWLIST_0
            # Add AzureFunctionsJobHost__functions__N for each allowlisted function
            - name: AZURE_APPCONFIG_ENDPOINT
              value: "placeholder-azure-appconfig-endpoint"
            - name: AzureWebJobsServiceBus
              value: "placeholder-servicebus-connection-string"
            - name: FUNCTIONS_WORKER_RUNTIME
              value: dotnet-isolated
            - name: AZURE_CLIENT_ID
              value: "placeholder-azure-client-id"
            - name: AZURE_TENANT_ID
              value: "placeholder-azure-tenant-id"
            - name: AZURE_CLIENT_SECRET
              value: "placeholder-azure-client-secret"
            - name: NEW_RELIC_LICENSE_KEY
              value: "placeholder-new-relic-license-key"
            - name: CORECLR_ENABLE_PROFILING
              value: "1"
            - name: CORECLR_PROFILER
              value: "{36032161-FFC0-4B61-B559-F6C5D41BAE5A}"
            - name: CORECLR_NEWRELIC_HOME
              value: "/usr/local/newrelic-dotnet-agent"
            - name: CORECLR_PROFILER_PATH
              value: "/usr/local/newrelic-dotnet-agent/libNewRelicProfiler.so"
            - name: NEW_RELIC_APP_NAME
              value: "FULL_SERVICE_NAME-placeholder-env"
            - name: NEW_RELIC_APPLICATION_LOGGING_ENABLED
              value: "true"
            - name: NEW_RELIC_APPLICATION_LOGGING_FORWARDING_ENABLED
              value: "true"
            - name: NEW_RELIC_APPLICATION_LOGGING_FORWARDING_MAX_SAMPLES_STORED
              value: "10000"
            - name: NEW_RELIC_APPLICATION_LOGGING_LOCAL_DECORATING_ENABLED
              value: "false"
```

**Customization notes:**
- Replace `SERVICE_NAME`, `NAMESPACE`, `FULL_SERVICE_NAME` with actual values
- Add all `AzureFunctionsJobHost__functions__N` entries from existing manifest
- Add any additional env vars from existing deployment (e.g., CosmosDB connection string vars)
- Adjust resource limits based on existing manifest values

---

### KEDA ScaledObject

Include in base for `functions-worker` services. Triggers are copied verbatim from the existing manifest — any KEDA trigger type is valid.

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: SERVICE_NAME
  namespace: NAMESPACE
  labels:
    app: SERVICE_NAME
    namespace: NAMESPACE
spec:
  scaleTargetRef:
    name: SERVICE_NAME
  minReplicaCount: 1
  triggers:
    # Copy triggers verbatim from existing ScaledObject.
    # Supported types: azure-servicebus, azure-cosmosdb, azure-blob, azure-queue, azure-eventhub, etc.
    # Example (Service Bus topic):
    - type: azure-servicebus
      metadata:
        topicName: TOPIC_NAME
        subscriptionName: SUBSCRIPTION_NAME
        connectionFromEnv: AzureWebJobsServiceBus
```

---

### Functions Base kustomization.yaml

Single-service worker (no service.yaml — workers have no HTTP service for normal traffic):

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - SERVICE_NAME-deployment.yaml
  - SERVICE_NAME-scaledobject.yaml

images:
  - name: placeholder.azurecr.io/SERVICE_NAME
    newName: placeholder.azurecr.io/SERVICE_NAME
    newTag: v1.0.0-placeholder
```

Multi-service base kustomization (list all deployments and scaledobjects):

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - SERVICE_NAME_1-deployment.yaml
  - SERVICE_NAME_1-scaledobject.yaml    # Only if type: functions-worker
  - SERVICE_NAME_2-deployment.yaml
  # Add service.yaml for each functions-http service
  - SERVICE_NAME_2-service.yaml         # Only if type: functions-http

images:
  - name: placeholder.azurecr.io/SERVICE_NAME_1
    newName: placeholder.azurecr.io/SERVICE_NAME_1
    newTag: v1.0.0-placeholder
  - name: placeholder.azurecr.io/SERVICE_NAME_2
    newName: placeholder.azurecr.io/SERVICE_NAME_2
    newTag: v1.0.0-placeholder
```

---

### Environment Overlay — `$patch: replace` Pattern

Functions use placeholder values in the base and replace the entire env block in each environment overlay. This avoids `secretKeyRef` in the base (which would fail kustomize build without the secret present).

#### `overlays/{env}/patch-SERVICE_NAME-env.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: SERVICE_NAME
  namespace: NAMESPACE
spec:
  template:
    spec:
      containers:
        - name: SERVICE_NAME
          env:
            - $patch: replace
            - name: ASPNETCORE_URLS
              value: "http://+:8080"
            - name: AzureFunctionsJobHost__functions__0
              value: FUNCTION_ALLOWLIST_0
            # Add all AzureFunctionsJobHost__functions__N entries
            - name: AZURE_APPCONFIG_ENDPOINT
              valueFrom:
                secretKeyRef:
                  name: FUNCTIONS_SECRET_NAME
                  key: azure-appconfig-endpoint
            - name: AzureWebJobsServiceBus
              valueFrom:
                secretKeyRef:
                  name: FUNCTIONS_SECRET_NAME
                  key: servicebus-connection-string
            - name: FUNCTIONS_WORKER_RUNTIME
              value: dotnet-isolated
            - name: AZURE_CLIENT_ID
              valueFrom:
                secretKeyRef:
                  name: FUNCTIONS_SECRET_NAME
                  key: azure-client-id
            - name: AZURE_TENANT_ID
              valueFrom:
                secretKeyRef:
                  name: FUNCTIONS_SECRET_NAME
                  key: azure-tenant-id
            - name: AZURE_CLIENT_SECRET
              valueFrom:
                secretKeyRef:
                  name: FUNCTIONS_SECRET_NAME
                  key: azure-client-secret
            - name: NEW_RELIC_LICENSE_KEY
              valueFrom:
                secretKeyRef:
                  name: FUNCTIONS_SECRET_NAME
                  key: new-relic-license-key
            - name: CORECLR_ENABLE_PROFILING
              value: "1"
            - name: CORECLR_PROFILER
              value: "{36032161-FFC0-4B61-B559-F6C5D41BAE5A}"
            - name: CORECLR_NEWRELIC_HOME
              value: "/usr/local/newrelic-dotnet-agent"
            - name: CORECLR_PROFILER_PATH
              value: "/usr/local/newrelic-dotnet-agent/libNewRelicProfiler.so"
            - name: NEW_RELIC_APPLICATION_LOGGING_ENABLED
              value: "true"
            - name: NEW_RELIC_APPLICATION_LOGGING_FORWARDING_ENABLED
              value: "true"
            - name: NEW_RELIC_APPLICATION_LOGGING_FORWARDING_MAX_SAMPLES_STORED
              value: "10000"
            - name: NEW_RELIC_APPLICATION_LOGGING_LOCAL_DECORATING_ENABLED
              value: "false"
```

#### `overlays/{env}/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patches:
  - path: patch-SERVICE_NAME-env.yaml
    target:
      kind: Deployment
      name: SERVICE_NAME
  # Repeat for each service in multi-service repos
```

**Note:** `NEW_RELIC_APP_NAME` is NOT included in the env overlay patch — it is set per region/environment in the region kustomization (see below), keeping it separate and correct for each region.

---

### Region Kustomization — Functions Pattern

Functions region kustomizations reference the env overlay and patch only `NEW_RELIC_APP_NAME` per region. The env overlay already handles secretKeyRef injection.

#### `{region}/{env}/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../overlays/{ENVIRONMENT}

images:
  - name: placeholder.azurecr.io/SERVICE_NAME
    newName: {REGION_ACR}.azurecr.io/SERVICE_NAME

patches:
  - path: patch-SERVICE_NAME-app-name.yaml
    target:
      kind: Deployment
      name: SERVICE_NAME
  # Repeat for each service in multi-service repos
```

#### `{region}/{env}/patch-SERVICE_NAME-app-name.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: SERVICE_NAME
spec:
  template:
    spec:
      containers:
        - name: SERVICE_NAME
          env:
            - name: NEW_RELIC_APP_NAME
              value: "FULL_SERVICE_NAME-{ENV_SUFFIX}"
```

**Note:** No `namespace:` in these patches — namespace is already set in the base deployment. Adding `namespace:` here would require it to match exactly, making the patches region-specific.

---

### Review Overlay — Functions Worker (`functions-worker`)

Key differences from the webapi review overlay:
- `$patch: delete` on KEDA ScaledObject — prevents the review app from consuming real messages
- `replicas: 1` patch on Deployment — locks scale since ScaledObject is deleted
- No `$patch: delete` on IngressRoute — workers have none
- Adds a service resource (`resources/SERVICE_NAME-service.yaml`) so the review app health check can reach the pod

#### `overlays/review/kustomization.yaml.template`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base
  - resources/SERVICE_NAME-service.yaml
  - resources/https-route.yaml
  - resources/http-to-https-redirect.yaml

namePrefix: ""
nameSuffix: -mr-{{MR_ID}}
namespace: APP_NAME-mr-{{MR_ID}}

images:
  - name: placeholder.azurecr.io/SERVICE_NAME
    newName: "{{IMAGE-NAME_REGISTRY_NAME}}"
    newTag: "image-name-{{IMAGE_TAG}}"

patches:
  - path: add-nodeselector.patch.yaml
    target:
      kind: Deployment

  - patch: |
      apiVersion: gateway.networking.k8s.io/v1
      kind: HTTPRoute
      metadata:
        name: http-to-https-redirect
      spec:
        hostnames:
          - "{{REVIEW_HOST}}"
    target:
      kind: HTTPRoute
      name: http-to-https-redirect

  # Remove KEDA ScaledObject — review app runs at replicas: 1 with no real trigger connection
  - patch: |
      apiVersion: keda.sh/v1alpha1
      kind: ScaledObject
      metadata:
        name: SERVICE_NAME
      $patch: delete
    target:
      kind: ScaledObject
      name: SERVICE_NAME

  # Lock to 1 replica (ScaledObject deleted above)
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: SERVICE_NAME
      spec:
        replicas: 1
    target:
      kind: Deployment
      name: SERVICE_NAME

  - path: patch-api-deployment.yaml
  - path: patch-https-route.yaml

labels:
  - pairs:
      review-app: "mr-{{MR_ID}}"
      merge-request-id: "{{MR_ID}}"
```

> **Image registry variable naming**: `review-app.yml` generates registry variable names by uppercasing the image name with `tr '[:lower:]' '[:upper:]'` — hyphens are preserved, NOT converted to underscores. So `webhooks-incident` → `{{WEBHOOKS-INCIDENT_REGISTRY_NAME}}` (not `{{WEBHOOKS_INCIDENT_REGISTRY_NAME}}`). Always quote these values in YAML to prevent parse errors if substitution is skipped.

**Multi-service review overlay**: If the repo has multiple services, add one `images:` entry per service, add `$patch: delete` for each ScaledObject, and add one `patch-{service}-deployment.yaml` path per service.

#### `overlays/review/patch-api-deployment.yaml.template` (functions-worker)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: SERVICE_NAME
  namespace: NAMESPACE
spec:
  template:
    spec:
      imagePullSecrets:
        - name: {{IMAGE_PULL_SECRET}}
      containers:
        - name: SERVICE_NAME
          resources:
            limits:
              memory: "300Mi"
              cpu: "200m"
            requests:
              memory: "100Mi"
              cpu: "50m"
          startupProbe:
            httpGet:
              path: /
              port: 8080
            failureThreshold: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 5
            failureThreshold: 3
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 30
            failureThreshold: 3
            periodSeconds: 10
          env:
            - name: ASPNETCORE_URLS
              value: "http://+:8080"
              valueFrom: null
            - name: ASPNETCORE_FORWARDEDHEADERS_ENABLED
              value: "true"
            - name: AzureFunctionsJobHost__functions__0
              value: FUNCTION_ALLOWLIST_0
              valueFrom: null
            # Repeat for each AzureFunctionsJobHost__functions__N
            - name: AZURE_APPCONFIG_ENDPOINT
              value: "{{AZURE_APPCONFIG_ENDPOINT}}"
              valueFrom: null
            # AzureWebJobsServiceBus: set to a disabled dummy — review app must NOT consume real messages
            - name: AzureWebJobsServiceBus
              value: "Endpoint=sb://review-disabled.servicebus.windows.net/;SharedAccessKeyName=disabled;SharedAccessKey=disabled"
              valueFrom: null
            - name: FUNCTIONS_WORKER_RUNTIME
              value: dotnet-isolated
              valueFrom: null
            - name: AZURE_CLIENT_ID
              value: "{{AZURE_CLIENT_ID}}"
              valueFrom: null
            - name: AZURE_TENANT_ID
              value: "{{AZURE_TENANT_ID}}"
              valueFrom: null
            - name: AZURE_CLIENT_SECRET
              value: "{{AZURE_CLIENT_SECRET}}"
              valueFrom: null
            - name: NEW_RELIC_LICENSE_KEY
              value: "{{NEW_RELIC_LICENSE_KEY}}"
              valueFrom: null
            - name: NEW_RELIC_APP_NAME
              value: "FULL_SERVICE_NAME-mr-{{MR_ID}}"
              valueFrom: null
            - name: CORECLR_ENABLE_PROFILING
              value: "0"
              valueFrom: null
            - name: CORECLR_PROFILER
              value: "{36032161-FFC0-4B61-B559-F6C5D41BAE5A}"
              valueFrom: null
            - name: CORECLR_NEWRELIC_HOME
              value: "/usr/local/newrelic-dotnet-agent"
              valueFrom: null
            - name: CORECLR_PROFILER_PATH
              value: "/usr/local/newrelic-dotnet-agent/libNewRelicProfiler.so"
              valueFrom: null
            - name: NEW_RELIC_APPLICATION_LOGGING_ENABLED
              value: "true"
              valueFrom: null
            - name: NEW_RELIC_APPLICATION_LOGGING_FORWARDING_ENABLED
              value: "true"
              valueFrom: null
            - name: NEW_RELIC_APPLICATION_LOGGING_FORWARDING_MAX_SAMPLES_STORED
              value: "10000"
              valueFrom: null
            - name: NEW_RELIC_APPLICATION_LOGGING_LOCAL_DECORATING_ENABLED
              value: "false"
              valueFrom: null
```

**CRITICAL:** `CORECLR_ENABLE_PROFILING: "0"` disables New Relic profiling in review apps (no license key needed, lower overhead). `AzureWebJobsServiceBus` must use the disabled dummy value — never a real Service Bus connection string in review.

---

## Multi-Service Pipeline Templates

For repos with a `services:` list in the config. Reference: `email-function` (multi-service) and `webhooks-processor` (single Functions worker).

### Docker Build Job — Multi-Service Matrix

One matrix row per service:

```yaml
docker-build-job:
  extends: .build-docker-image
  parallel:
    matrix:
      - IMAGE_NAME: SERVICE_NAME_1
        DOCKERFILE: src/PROJECT_PATH_1/Dockerfile
        BUILD_ARGS: "GITLAB_PACKAGE_REGISTRY_USERNAME=$CI_REGISTRY_USER GITLAB_PACKAGE_REGISTRY_PASSWORD=$CI_REGISTRY_PASSWORD"
      - IMAGE_NAME: SERVICE_NAME_2
        DOCKERFILE: src/PROJECT_PATH_2/Dockerfile
        BUILD_ARGS: "GITLAB_PACKAGE_REGISTRY_USERNAME=$CI_REGISTRY_USER GITLAB_PACKAGE_REGISTRY_PASSWORD=$CI_REGISTRY_PASSWORD"
      # Add one row per service
```

### Review App Include — Multi-Service (`deployment-names`)

The `deployment-names` input (available in v5) tells the review-app template which deployments to watch for rollout. Required for multi-service repos so the health check waits for all services.

```yaml
include:
  - project: trigent1/pipeline-templates
    ref: v5
    file: kubernetes/review-app.yml
    inputs:
      app-name: APP_NAME
      review-domain: review.trigent.com
      kustomize-base-path: k8s/overlays/review
      key-vault-name: "${KV_NAME}"
      cluster-resource-group: CLUSTER_RG
      cluster-name: CLUSTER_NAME
      image-names: SERVICE_NAME_1,SERVICE_NAME_2    # comma-separated, no spaces
      deployment-names: SERVICE_NAME_1,SERVICE_NAME_2  # comma-separated, matches image-names
      url-path: "/"
```

**Note:** For `functions-http` services that expose a Swagger UI, set `url-path: "/swagger/ui"` or the appropriate health/status path.

### Push Docker Images — Multi-Service Matrix

One row per service (lower environments):

```yaml
push-docker-images-lower:
  extends: .push-docker-image
  stage: deploy-lower
  dependencies:
    - calculate-version
    - docker-build-job
  parallel:
    matrix:
      - REGION: *regions
        STACK_ENVIRONMENT: *lower-environments
        IMAGE_NAME: SERVICE_NAME_1
        SERVICE_NAME: SERVICE_NAME_1
      - REGION: *regions
        STACK_ENVIRONMENT: *lower-environments
        IMAGE_NAME: SERVICE_NAME_2
        SERVICE_NAME: SERVICE_NAME_2
  environment:
    name: "azure/$REGION/$STACK_ENVIRONMENT/docker"
```

Production (no `STACK_ENVIRONMENT` in matrix — it's fixed to prod):

```yaml
push-docker-images-prod:
  extends: .push-docker-image
  stage: deploy-prod
  # No needs — stage-scheduled, waits for ALL prod-gate jobs
  dependencies:
    - calculate-version
    - docker-build-job
  parallel:
    matrix:
      - REGION: *regions
        IMAGE_NAME: SERVICE_NAME_1
        SERVICE_NAME: SERVICE_NAME_1
      - REGION: *regions
        IMAGE_NAME: SERVICE_NAME_2
        SERVICE_NAME: SERVICE_NAME_2
  environment:
    name: "azure/$REGION/prod/docker"
    deployment_tier: production
```

### Kustomize Deployment — Functions (with Service Bus Secret)

Functions repos need the Service Bus connection string fetched from Key Vault and stored in the shared K8s secret. A single `deploy-k8s-lower` job covers all services via the shared kustomize path.

```yaml
deploy-k8s-lower:
  extends: .deploy-kustomize
  stage: deploy-lower
  needs:
    - job: push-docker-images-lower
  parallel:
    matrix:
      - REGION: *regions
        STACK_ENVIRONMENT: *lower-environments
  variables:
    KUSTOMIZE_PATH: "k8s/${REGION}/${STACK_ENVIRONMENT}"
    NAMESPACE: NAMESPACE
    # WAIT_FOR_DEPLOYMENTS: space-separated list of all deployment names
    WAIT_FOR_DEPLOYMENTS: "SERVICE_NAME_1 SERVICE_NAME_2"
  before_script:
    - !reference [.deploy-kustomize, before_script]
    - |
      if [ -z "${KV_NAME}" ]; then
        echo "Error: KV_NAME is not set."
        exit 1
      fi
    - kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    - |
      AZURE_APPCONFIG_ENDPOINT=$(az keyvault secret show --name azure-appconfig-endpoint --vault-name ${KV_NAME} --query value -o tsv) \
        || { echo "❌ Failed to fetch azure-appconfig-endpoint"; exit 1; }
      [ -n "${AZURE_APPCONFIG_ENDPOINT}" ] \
        || { echo "❌ azure-appconfig-endpoint is empty"; exit 1; }
      SERVICEBUS_CONNECTION_STRING=$(az keyvault secret show --name ${SERVICEBUS_CONNECTION_STRING_SECRET_NAME} --vault-name ${KV_NAME} --query value -o tsv) \
        || { echo "❌ Failed to fetch ${SERVICEBUS_CONNECTION_STRING_SECRET_NAME}"; exit 1; }
      [ -n "${SERVICEBUS_CONNECTION_STRING}" ] \
        || { echo "❌ ${SERVICEBUS_CONNECTION_STRING_SECRET_NAME} is empty"; exit 1; }
      kubectl create secret generic ${SECRET_NAME} \
        --from-literal=azure-appconfig-endpoint="${AZURE_APPCONFIG_ENDPOINT}" \
        --from-literal=azure-client-id="${ARM_CLIENT_ID}" \
        --from-literal=azure-tenant-id="${ARM_TENANT_ID}" \
        --from-literal=azure-client-secret="${ARM_CLIENT_SECRET}" \
        --from-literal=new-relic-license-key="${NEW_RELIC_API_KEY}" \
        --from-literal=servicebus-connection-string="${SERVICEBUS_CONNECTION_STRING}" \
        --namespace="${NAMESPACE}" \
        --dry-run=client -o yaml | kubectl apply -f -
  environment:
    name: "azure/$REGION/$STACK_ENVIRONMENT/deploy"
```

**Notes:**
- `NAMESPACE` is job-level (NOT global variable) so review-app template can use its own namespace
- `WAIT_FOR_DEPLOYMENTS` lists all services space-separated — the kustomize-deploy template waits for each
- `SECRET_NAME` is the shared secret used by all services in the repo (from global `variables:`)
- `SERVICEBUS_CONNECTION_STRING_SECRET_NAME` is the Key Vault secret name — set in global `variables:`

### Review App Deploy Job — Functions

Functions review apps need a Service Bus connection string fetched and stored as a separate secret (the real secret is used only for warmup; the pod's `AzureWebJobsServiceBus` env var is set to a disabled dummy in the review deployment patch).

```yaml
deploy-review-app-job:
  extends: .deploy-review-app
  variables:
    ARM_SUBSCRIPTION_ID: $ARM_SUBSCRIPTION_ID_DEV
    NAMESPACE: "APP_NAME-mr-${CI_MERGE_REQUEST_IID}"
  before_script:
    - !reference [.review-app-common, before_script]
    - |
      SERVICEBUS_CS=$(az keyvault secret show --name ${SERVICEBUS_CONNECTION_STRING_SECRET_NAME} --vault-name ${KV_NAME} --query value -o tsv)
      kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
      kubectl create secret generic review-servicebus-secret \
        --from-literal=servicebus-connection-string="${SERVICEBUS_CS}" \
        --namespace="${NAMESPACE}" \
        --dry-run=client -o yaml | kubectl apply -f -
  environment:
    on_stop: cleanup-review-app-job

cleanup-review-app-job:
  extends: .cleanup-review-app
  variables:
    ARM_SUBSCRIPTION_ID: $ARM_SUBSCRIPTION_ID_DEV
    NAMESPACE: "APP_NAME-mr-${CI_MERGE_REQUEST_IID}"
```

### Variables Block — Functions Repos

```yaml
variables:
  APP_NAME: "APP_NAME"
  SECRET_NAME: "APP_NAME-secrets"          # Shared K8s secret for all services
  ACR_URL: "${AZURE_CONTAINER_REGISTRY}"
  deploymentTrigger: "branch"
  OUTPUT_PATH: "out"
  # Key Vault secret name for the primary Service Bus connection string (if used)
  SERVICEBUS_CONNECTION_STRING_SECRET_NAME: "SERVICE_BUS_SECRET_KEY"
```

**Note:** Functions repos do NOT include `PROJECT_PATH`, `DLL_PATH`, or `SERVICE_NAME` as global variables — these are per-service and defined in the `docker-build-job` matrix rows instead.
