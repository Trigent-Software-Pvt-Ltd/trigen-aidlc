---
target-framework: netXX.0          # REPLACE: e.g. net12.0
lts: true
eol: REPLACE_EOL                   # e.g. November 2030
sdk-version: XX.0.100              # REPLACE: e.g. 12.0.100
last-reviewed: REPLACE_DATE        # e.g. 2028-01-01
---

# Version Guidance: netXX.0

> **Template for future LTS releases.** Copy this file to `references/version-guidance/net12.0.md`
> (or the appropriate version), fill in all `REPLACE_*` placeholders, and remove this notice.

This file provides version-specific guidance for upgrading to `netXX.0`.
The `version-upgrade` skill will load this file when `netXX.0` is the target framework.

---

## How to Complete This Template

When a new LTS is released:

1. Copy this file to `references/version-guidance/net{version}.0.md`.
2. Fill in the SDK version, EOL date, and package expectations.
3. Review the [Microsoft .NET release notes](https://github.com/dotnet/core/tree/main/release-notes) for breaking changes.
4. Review the [EF Core release notes](https://learn.microsoft.com/en-us/ef/core/what-is-new/) for the matching major version.
5. Review [Npgsql release notes](https://github.com/npgsql/npgsql/releases) for the matching major version.
6. Review [MassTransit release notes](https://masstransit.io/releases) for the matching major version.
7. Update `references/approved-package-versions.md` with vetted versions.
8. Remove this "How to Complete" section.

---

## SDK Expectations

```json
{
  "sdk": {
    "version": "XX.0.100",
    "rollForward": "latestMinor"
  }
}
```

**Notes:**
- REPLACE: Describe any SDK tooling changes in this version.
- REPLACE: Note if C# language version changed (e.g., C# 15 ships with .NET 12).

### Docker

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:XX.0 AS build
FROM mcr.microsoft.com/dotnet/aspnet:XX.0 AS runtime       # Web API
FROM mcr.microsoft.com/dotnet/runtime:XX.0 AS runtime      # Console / Functions
```

---

## Package Expectations

### EF Core

REPLACE: Specify the EF Core major version that aligns with this runtime.

```xml
<PackageVersion Include="Microsoft.EntityFrameworkCore" Version="XX.0.x" />
```

### Npgsql

REPLACE: Specify the Npgsql major version. Note any breaking changes.

### Microsoft.Extensions.* and Microsoft.AspNetCore.*

Do NOT pin these separately — the SDK supplies the correct versions.

### Azure Functions (if applicable)

REPLACE: Specify whether in-process or isolated worker model changes apply in this version.

### OpenAPI Tooling

REPLACE: Note whether built-in OpenAPI support changed, and whether Swashbuckle/Scalar recommendations changed.

### Other Key Packages

REPLACE: Add any packages with major version changes for this runtime.

### Internal Trigent Packages

REPLACE: List the minimum versions of internal Trigent platform packages that target this .NET version. Derive stable versions by dropping any `-RC-*` or `-preview-*` suffix from the prerelease builds that shipped with the LTS candidate.

#### Trigent.Platform.Core.* (`trigent1/trigent/platform/platform-core`)

| Package | Minimum Version |
|---------|----------------|
| `Trigent.Platform.Core.BusinessLogic` | REPLACE |
| `Trigent.Platform.Core.Client` | REPLACE |
| `Trigent.Platform.Core.Data` | REPLACE |
| `Trigent.Platform.Core.EventBus` | REPLACE |
| `Trigent.Platform.Core.EventBus.ServiceBus` | REPLACE |
| `Trigent.Platform.Core.Services` | REPLACE |
| `Trigent.Platform.Core.Web.Server` | REPLACE |
| `Trigent.Platform.Core.Pagination` | REPLACE |
| `Trigent.Platform.Core.Pagination.CosmosDb` | REPLACE |

#### Trigent.Platform.SharedServices.* (`trigent1/trigent/platform/shared-services/shared-libraries`)

Not used by all services — only upgrade packages the service already references.

| Package | Minimum Version |
|---------|----------------|
| `Trigent.Platform.SharedServices.Constants` | REPLACE |
| `Trigent.Platform.SharedServices.AzureServices` | REPLACE |
| `Trigent.Platform.SharedServices.SFTP` | REPLACE |
| `Trigent.Platform.SharedServices.R6DataFacade` | REPLACE |
| `Trigent.Platform.SharedServices.Core` | REPLACE |
| `Trigent.Platform.SharedServices.EmailServices` | REPLACE |
| `Trigent.Platform.SharedServices.UnitTests` | REPLACE |
| `Trigent.Platform.SharedServices.Northpass` | REPLACE |
| `Trigent.Platform.SharedServices.SendGrid` | REPLACE |
| `Trigent.Platform.SharedServices.Import` | REPLACE |
| `Trigent.Platform.SharedServices.BuildingsImport` | REPLACE |
| `Trigent.Platform.SharedServices.UserContactsImport` | REPLACE |

---

## Common Upgrade Risks for netXX.0

### From the Previous LTS

| Area | Risk | Action |
|------|------|--------|
| REPLACE_PACKAGE | HIGH/MEDIUM/LOW | REPLACE_ACTION |

### From Two LTS Versions Back

REPLACE: Document cumulative risks when skipping a version.

---

## CI / Runtime Considerations

### GitLab CI

```yaml
variables:
  DOTNET_VERSION: "XX.0"
  SDK_VERSION: "XX.0.100"

build:
  image: mcr.microsoft.com/dotnet/sdk:XX.0
  script:
    - dotnet restore
    - dotnet build --no-restore --configuration Release
    - dotnet test --no-build --configuration Release
```

### Kubernetes / Docker

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:XX.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish src/Api -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:XX.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "YourApp.dll"]
```

---

## API / OpenAPI Notes

REPLACE: Describe OpenAPI tooling status for this version.

- Is `Microsoft.AspNetCore.OpenApi` built-in?
- What is the recommended Swashbuckle version?
- Is Scalar the preferred solution?
- Did any OpenAPI-related APIs change?

---

## Azure Functions Notes

REPLACE: Describe Azure Functions runtime compatibility for this version.

- Is in-process model supported?
- What is the required worker SDK version?
- Any trigger attribute changes?
- Any breaking changes in extension packages?

---

## Breaking Changes Summary

REPLACE: List the key breaking changes relevant to Trigent services. Reference the official Microsoft migration guide for this version.

| Area | Change | Action Required |
|------|--------|-----------------|
| REPLACE | REPLACE | REPLACE |

Official migration guide: REPLACE_URL

---

## Modernisation Opportunities (Optional, Not Auto-Applied)

REPLACE: List modernisation opportunities introduced in this version.

| Opportunity | Effort | Benefit | Required Approval |
|-------------|--------|---------|------------------|
| REPLACE | Low/Medium/High | REPLACE | Explicit request |

---

## Notes for Skill Maintainers

When adding a future LTS guidance file:

1. Update `references/approved-package-versions.md` with the new target framework section.
2. Update `references/dotnet-upgrade-policy.md` LTS version table.
3. Test the `version-upgrade` skill against a sample repo targeting the new framework.
4. Remove all `REPLACE_*` placeholders from this file before committing.
