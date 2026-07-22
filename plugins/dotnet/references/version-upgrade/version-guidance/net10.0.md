---
target-framework: net10.0
lts: true
eol: November 2027
sdk-version: 10.0.100
last-reviewed: 2026-05-01
---

# Version Guidance: net10.0

Guidance for upgrading to .NET 10 LTS. This is the current team-recommended target for new and upgraded projects.

---

## SDK Expectations

```json
{
  "sdk": {
    "version": "10.0.100",
    "rollForward": "latestMinor"
  }
}
```

- .NET 10 is LTS (support until November 2027).
- Use the latest `10.0.x` patch release.
- This is the **team default target** when no specific version is requested.

### Docker

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:10.0-noble AS build
FROM mcr.microsoft.com/dotnet/aspnet:10.0-noble AS runtime       # Web API
FROM mcr.microsoft.com/dotnet/runtime:10.0-noble AS runtime      # Console / Functions isolated
```

> **Note:** `bookworm-slim` is NOT available for .NET 10. Use `10.0-noble` (Ubuntu 24.04 LTS) or the untagged `10.0` (defaults to noble). Do not carry over `8.0-bookworm-slim` tags — they will fail.

---

## Package Expectations

### EF Core

Use `Microsoft.EntityFrameworkCore` **10.x** packages.

```xml
<PackageVersion Include="Microsoft.EntityFrameworkCore" Version="10.0.x" />
<PackageVersion Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.x" />
```

### Npgsql

Use Npgsql **9.x** (aligned with .NET 10 ecosystem). All `DateTime` values must be UTC.

### Microsoft.Extensions.* and Microsoft.AspNetCore.*

Do NOT pin these separately. The SDK provides the correct versions. Remove explicit `Version` attributes if present.

### Swashbuckle (if upgrading from .NET 8)

Swashbuckle 6.x is NOT compatible with .NET 10. **The team-standard path for net10.0 is Scalar** — do not upgrade to Swashbuckle 7.x for new or upgraded net10 services.

Migration to Scalar is required when upgrading from net8.0 to net10.0. It is not auto-applied — pass `--allow-breaking-changes` to have the skill perform the migration. See the Scalar Migration section in API / OpenAPI Notes for the changeset.

### Azure Functions

**In-process model is NOT supported on .NET 10.** Migration to isolated worker is required before targeting net10.0.

Isolated worker packages:

```xml
<PackageVersion Include="Microsoft.Azure.Functions.Worker" Version="2.x" />
<PackageVersion Include="Microsoft.Azure.Functions.Worker.Sdk" Version="2.x" />
<PackageVersion Include="Microsoft.Azure.Functions.Worker.Extensions.ServiceBus" Version="5.x+" />
```

### Internal Trigent Packages

For any Trigent platform packages referenced by the service, ensure the installed version meets the minimums below. Upgrade as part of the .NET 10 migration if not. Check the internal GitLab NuGet feed for the latest stable release in each series.

#### Trigent.Platform.Core.* (`trigent1/trigent/platform/platform-core`)

Used by most services.

| Package | Minimum Version |
|---------|----------------|
| `Trigent.Platform.Core.BusinessLogic` | 4.0.0 |
| `Trigent.Platform.Core.Client` | 7.0.0 |
| `Trigent.Platform.Core.Data` | 4.0.0 |
| `Trigent.Platform.Core.EventBus` | 5.0.0 |
| `Trigent.Platform.Core.EventBus.ServiceBus` | 6.0.0 |
| `Trigent.Platform.Core.Services` | 10.0.1 |
| `Trigent.Platform.Core.Web.Server` | 2.0.0 |
| `Trigent.Platform.Core.Pagination` | 5.0.0 |
| `Trigent.Platform.Core.Pagination.CosmosDb` | 6.0.0 |

#### Trigent.Platform.SharedServices.* (`trigent1/trigent/platform/shared-services/shared-libraries`)

Not used by all services — only upgrade packages the service already references.

| Package | Minimum Version |
|---------|----------------|
| `Trigent.Platform.SharedServices.Constants` | 3.0.0 |
| `Trigent.Platform.SharedServices.AzureServices` | 3.0.0 |
| `Trigent.Platform.SharedServices.SFTP` | 3.0.0 |
| `Trigent.Platform.SharedServices.R6DataFacade` | 3.0.0 |
| `Trigent.Platform.SharedServices.Core` | 3.0.0 |
| `Trigent.Platform.SharedServices.EmailServices` | 3.0.0 |
| `Trigent.Platform.SharedServices.UnitTests` | 3.0.0 |
| `Trigent.Platform.SharedServices.Northpass` | 5.0.0 |
| `Trigent.Platform.SharedServices.SendGrid` | 3.0.0 |
| `Trigent.Platform.SharedServices.Import` | 4.0.0 |
| `Trigent.Platform.SharedServices.BuildingsImport` | 4.0.0 |
| `Trigent.Platform.SharedServices.UserContactsImport` | 7.0.0 |

---

## Common Upgrade Risks for net10.0

### From net8.0

| Area | Risk | Action |
|------|------|--------|
| EF Core 8 → 10 | MEDIUM | Review EF Core 9 and 10 migration guides (two major versions) |
| Npgsql 8 → 9 | HIGH | Review release notes; validate integration tests |
| Azure Functions in-process | HIGH | **Cannot run on .NET 10** — migrate to isolated worker first |
| Swashbuckle 6.x | HIGH | Must upgrade to 7.x or replace with Scalar |
| MassTransit | HIGH | If on v8, upgrade to v9; review breaking changes |
| `Microsoft.Extensions.*` pinned versions | MEDIUM | Remove Version pins; let SDK supply |

### From net6.0 or net7.0

All risks from net8.0 apply, plus:

| Area | Risk | Action |
|------|------|--------|
| Npgsql 6/7 → 9 | HIGH | Two+ major version jumps; test all database operations |
| EF Core 6/7 → 10 | HIGH | Three+ major version jumps; verify all migrations and queries |
| MassTransit v7 → v9 | HIGH | Two major version jumps; full regression testing required |
| SimpleInjector (legacy Web APIs) | MEDIUM | Still supported on .NET 10; no change required if not modernising DI |

---

## CI / Runtime Considerations

### GitLab CI

```yaml
variables:
  DOTNET_VERSION: "10.0"
  SDK_VERSION: "10.0.100"

build:
  image: mcr.microsoft.com/dotnet/sdk:10.0-noble
  script:
    - dotnet restore
    - dotnet build --no-restore --configuration Release
    - dotnet test --no-build --configuration Release

publish:
  image: mcr.microsoft.com/dotnet/sdk:10.0-noble
  script:
    - dotnet publish src/Api -c Release -o publish/
```

### Kubernetes / Docker

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:10.0-noble AS build
WORKDIR /src
COPY . .
RUN dotnet publish src/Api -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0-noble AS runtime
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Trigent.MyService.Api.dll"]
```

---

## API / OpenAPI Notes

### Built-in OpenAPI (Recommended for new services)

.NET 9+ ships `Microsoft.AspNetCore.OpenApi` as a built-in package. This is the foundation for Scalar on .NET 10.

```csharp
// Program.cs
builder.Services.AddOpenApi();

app.MapOpenApi();
app.MapScalarApiReference();  // requires Scalar.AspNetCore
```

### Scalar Migration (Required for net10.0)

Scalar is the team-standard OpenAPI UI for .NET 10. Swashbuckle must be replaced as part of the net10.0 upgrade (pass `--allow-breaking-changes`).

| Before (Swashbuckle) | After (Scalar) |
|---------------------|----------------|
| `builder.Services.AddSwaggerGen()` | `builder.Services.AddOpenApi()` |
| `app.UseSwagger()` | `app.MapOpenApi()` |
| `app.UseSwaggerUI()` | `app.MapScalarApiReference()` |
| Packages: `Swashbuckle.AspNetCore` | Packages: `Microsoft.AspNetCore.OpenApi` + `Scalar.AspNetCore` |

Remove `Swashbuckle.AspNetCore` from `Directory.Packages.props` entirely — do not leave it pinned alongside Scalar.

---

## Azure Functions Notes

### In-Process — NOT SUPPORTED on .NET 10

If the repository contains in-process Azure Functions (detected by `Microsoft.NET.Sdk.Functions` or `[FunctionName]` attributes):

1. **Do not upgrade the TFM to net10.0 yet.**
2. Create a separate work item for isolated worker migration.
3. Refer to the [Microsoft in-process to isolated worker migration guide](https://learn.microsoft.com/en-us/azure/azure-functions/migrate-dotnet-to-isolated-model).

Key migration changes:

| In-Process | Isolated Worker |
|-----------|----------------|
| `[FunctionName("Name")]` | `[Function("Name")]` |
| `FunctionsStartup` class | `HostBuilder` with `ConfigureFunctionsWorkerDefaults()` |
| `IFunctionsHostBuilder` | `IServiceCollection` |
| `Microsoft.Azure.WebJobs.*` triggers | `Microsoft.Azure.Functions.Worker.*` triggers |
| `Message` (ServiceBus) | `ServiceBusReceivedMessage` |
| Shared process with host | Separate process (better isolation) |

### Isolated Worker — Fully Supported on .NET 10

Trigent application profile: [Function App v10 Profile](standards:technical-guidance/application-profiles/dotnet-function-v10-profile.md)

Program.cs pattern:

```csharp
var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((context, services) =>
    {
        ContainerConfiguration.Configure(services, context.Configuration);
    })
    .Build();

host.Run();
```

---

## Scala Modernisation Notes

For new .NET 10 Web API services, the Trigent architecture standard (see [dotnet-webapi-v10-profile](standards)) uses:

- **Microsoft DI** (not SimpleInjector)
- **AutoMapper** (not Mapster for new projects)
- **Separate BusinessLogic project**
- **`ContainerConfiguration.cs` in Shared project**

When upgrading an existing legacy Web API to net10.0, you do NOT need to adopt these patterns. Adopt them only if explicitly requested as part of a broader modernisation effort.

---

## Modernisation Opportunities (Optional, Not Auto-Applied)

| Opportunity | Effort | Benefit | Required Approval |
|-------------|--------|---------|------------------|
| Replace Swashbuckle with Scalar | Medium | Required for net10.0 (team standard) | `--allow-breaking-changes` |
| Migrate in-process Functions to isolated worker | High | .NET 10 compatibility | Explicit request |
| Enable Central Package Management | Low-Medium | Version consistency | `--allow-cpm` flag |
| Add `Directory.Build.props` | Low | Centralised properties | `--allow-dbprops` flag |
| Migrate `.sln` to `.slnx` | Low | Modern solution format | `--allow-slnx` flag |
| Migrate SimpleInjector → Microsoft DI | High | Align with v10 template | Explicit request |
| Enable primary constructors (C# 13) | Low | Cleaner syntax | Optional |
