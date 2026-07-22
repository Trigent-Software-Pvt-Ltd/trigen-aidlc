---
target-framework: net8.0
lts: true
eol: November 2026
sdk-version: 8.0.x (latest patch)
last-reviewed: 2026-05-01
---

# Version Guidance: net8.0

Guidance for upgrading to or maintaining .NET 8 LTS. Use this file when the target framework is `net8.0`.

---

## SDK Expectations

```json
{
  "sdk": {
    "version": "8.0.100",
    "rollForward": "latestMinor"
  }
}
```

- Use the latest `8.0.x` patch release.
- `rollForward: latestMinor` allows the SDK to use newer patch versions automatically.
- Do not pin to `8.0.100` specifically — use `latestMinor` rollforward or the latest available 8.x patch.

### Docker

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime       # Web API
FROM mcr.microsoft.com/dotnet/runtime:8.0 AS runtime      # Console / Functions isolated
```

---

## Package Expectations

### EF Core

Use `Microsoft.EntityFrameworkCore` **8.x** packages.

```xml
<PackageVersion Include="Microsoft.EntityFrameworkCore" Version="8.0.x" />
<PackageVersion Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.x" />
```

### Npgsql

Use Npgsql **8.x**. Key breaking changes from v7:

- `DateTime` values must be UTC. Local/Unspecified kinds will throw at write time.
- Nullable column mapping requires nullable C# types.

### Azure Functions

- In-process model (`Microsoft.NET.Sdk.Functions` 4.x) is supported on .NET 8 but **deprecated**.
- Isolated worker model is strongly recommended for any new work.
- Plan migration to isolated worker before targeting .NET 10.

### Swashbuckle

Use `Swashbuckle.AspNetCore` **6.x** for .NET 8. Version 7.x is not required for .NET 8 but is compatible.

### OpenAPI

.NET 8 does not include built-in OpenAPI document generation. Use Swashbuckle or NSwag.

---

## Common Upgrade Risks for net8.0

### From net6.0 or net7.0

| Area | Risk | Action |
|------|------|--------|
| EF Core 6/7 → 8 | MEDIUM | Review migration compatibility; check owned entity changes |
| Npgsql 6/7 → 8 | HIGH | DateTime UTC enforcement, nullable column mapping |
| MassTransit | HIGH | v7→v8 has breaking consumer registration changes |
| Nullable reference types | MEDIUM | Enable `<Nullable>enable</Nullable>` and fix warnings |
| `Startup.cs` pattern | LOW | Still supported in .NET 8; not required to migrate to minimal API |
| `IHostBuilder` → `WebApplication` | LOW | Optional modernisation; not a breaking change |

### Nullable Reference Types

.NET 8 enforces nullable analysis when `<Nullable>enable</Nullable>` is set. With `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`, nullability violations will break the build.

**Action:** Enable nullable analysis and fix all warnings before enabling `TreatWarningsAsErrors`, or suppress with `#pragma warning disable CS8602` only when justified.

---

## CI / Runtime Considerations

### GitLab CI

```yaml
variables:
  DOTNET_VERSION: "8.0"

build:
  image: mcr.microsoft.com/dotnet/sdk:8.0
  script:
    - dotnet restore
    - dotnet build --no-restore
    - dotnet test --no-build
```

### Kubernetes / Docker

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app
COPY . .
RUN dotnet publish -c Release -o /out

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /out .
ENTRYPOINT ["dotnet", "YourApp.dll"]
```

---

## API / OpenAPI Notes

- **Swashbuckle 6.x** is the supported version for .NET 8.
- **NSwag** is supported on .NET 8.
- .NET 8 does not include `Microsoft.AspNetCore.OpenApi` (that arrives as a proper built-in in .NET 9).
- No action required for OpenAPI tooling as part of a .NET 8 upgrade unless upgrading from a very old Swashbuckle version.

---

## Azure Functions Notes

### In-Process (.NET 8)

In-process functions continue to work on .NET 8 with `Microsoft.NET.Sdk.Functions` 4.x.

> **Warning:** In-process model support ends with .NET 8. .NET 10 requires isolated worker model.

### Isolated Worker (.NET 8)

Isolated worker functions require:

```xml
<PackageReference Include="Microsoft.Azure.Functions.Worker" Version="1.x or 2.x" />
<PackageReference Include="Microsoft.Azure.Functions.Worker.Sdk" Version="1.x" />
```

**Use `[Function]` attribute, not `[FunctionName]`.**

---

## Modernisation Opportunities (Optional)

These are available on .NET 8 but not required as part of a TFM upgrade:

| Opportunity | Effort | Benefit |
|-------------|--------|---------|
| Migrate `Startup.cs` to minimal API pattern | Medium | Reduced boilerplate |
| Enable primary constructors (C# 12) | Low | Cleaner DI constructor syntax |
| Enable collection expressions (C# 12) | Low | Cleaner collection initialisation |
| Add `Directory.Build.props` | Low | Centralised properties |
| Migrate to Central Package Management | Medium | Version consistency |
| Migrate in-process Functions to isolated worker | High | Required before .NET 10 |
