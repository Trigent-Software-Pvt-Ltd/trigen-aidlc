# Approved Package Versions

Template for tracking approved NuGet package versions per target framework.

> **Usage:** This file is a team-maintained template. Update it when versions are approved during upgrade reviews.
> It is used by the `version-upgrade` skill to inform package upgrade recommendations.

---

## How to Use This File

- Versions listed here are the **minimum approved versions** for each target framework.
- Packages not listed should be treated as unvetted — upgrade with manual review.
- When a version is approved during an upgrade review, add it here and include the approver/date.
- Prefer exact versions (`8.0.0`) over ranges for production workloads.

---

## net10.0 Approved Versions

### Microsoft.Extensions.*

> These packages ship with the .NET runtime. **Do not pin these** in most cases — remove Version attributes and let the SDK supply them. Only pin when a specific bugfix requires it.

| Package | Approved Version | Notes |
|---------|-----------------|-------|
| Microsoft.Extensions.DependencyInjection | (runtime-supplied) | Do not pin |
| Microsoft.Extensions.Logging | (runtime-supplied) | Do not pin |
| Microsoft.Extensions.Configuration | (runtime-supplied) | Do not pin |
| Microsoft.Extensions.Http | (runtime-supplied) | Do not pin |
| Microsoft.Extensions.Options | (runtime-supplied) | Do not pin |
| Microsoft.Extensions.Hosting | (runtime-supplied) | Do not pin |

### Microsoft.AspNetCore.*

> These packages ship with the ASP.NET Core runtime. **Do not pin these** — they must match the installed runtime.

| Package | Approved Version | Notes |
|---------|-----------------|-------|
| Microsoft.AspNetCore.Authentication.JwtBearer | (runtime-supplied) | Must match target framework version |
| Microsoft.AspNetCore.OpenApi | (runtime-supplied) | Built-in for .NET 9+; prefer this over Swashbuckle for new services |

### Microsoft.EntityFrameworkCore.*

| Package | Approved Version | Notes |
|---------|-----------------|-------|
| Microsoft.EntityFrameworkCore | TBD | Must match major target version (10.x for .NET 10) |
| Microsoft.EntityFrameworkCore.Design | TBD | Must align with EF Core version |
| Microsoft.EntityFrameworkCore.SqlServer | TBD | Must align with EF Core version |

### Npgsql

| Package | Approved Version | Notes |
|---------|-----------------|-------|
| Npgsql | TBD | v9.x for .NET 10. Review DateTime/nullable behaviour changes from v8+. |
| Npgsql.EntityFrameworkCore.PostgreSQL | TBD | Must align with both Npgsql and EF Core versions |

### Azure Functions Packages

| Package | Approved Version | Notes |
|---------|-----------------|-------|
| Microsoft.Azure.Functions.Worker | TBD | Required for isolated worker model |
| Microsoft.Azure.Functions.Worker.Sdk | TBD | Must align with Worker version |
| Microsoft.Azure.Functions.Worker.Extensions.Http | TBD | Extension alignment required |
| Microsoft.Azure.Functions.Worker.Extensions.ServiceBus | TBD | Extension alignment required |
| Microsoft.Azure.Functions.Worker.Extensions.Timer | TBD | Extension alignment required |
| Microsoft.Azure.Functions.Worker.Extensions.DurableTask | TBD | Extension alignment required |

> **Note:** `Microsoft.NET.Sdk.Functions` (in-process) is NOT supported on .NET 10+.

### Serilog

| Package | Approved Version | Notes |
|---------|-----------------|-------|
| Serilog | 4.x | Stable across .NET 10 |
| Serilog.AspNetCore | 8.x+ | Must support .NET 10 |
| Serilog.Extensions.Hosting | 8.x+ | |
| Serilog.Sinks.Console | 6.x | |
| Serilog.Enrichers.Environment | 3.x | |
| Serilog.Enrichers.Thread | 4.x | |

### OpenTelemetry

| Package | Approved Version | Notes |
|---------|-----------------|-------|
| OpenTelemetry | 1.x (latest stable) | Check exporter compatibility |
| OpenTelemetry.Extensions.Hosting | 1.x (latest stable) | |
| OpenTelemetry.Instrumentation.AspNetCore | 1.x (latest stable) | |
| OpenTelemetry.Instrumentation.Http | 1.x (latest stable) | |

### MassTransit

| Package | Approved Version | Notes |
|---------|-----------------|-------|
| MassTransit | TBD | v9.x for .NET 10. Major upgrade from v8 contains breaking changes. |
| MassTransit.RabbitMQ | TBD | Must align with MassTransit version |
| RabbitMQ.Client | TBD | v7+ has breaking changes. Review before upgrading. |

### OpenAPI / Swagger

| Package | Approved Version | Notes |
|---------|-----------------|-------|
| Swashbuckle.AspNetCore | 7.x (for .NET 9 compat) | Evaluate Scalar for new .NET 10 services |
| Scalar.AspNetCore | 2.x | Preferred for new .NET 10 services |
| NSwag.AspNetCore | TBD | Keep for existing code-gen pipelines; do not silently upgrade |

### Test Packages

| Package | Approved Version | Notes |
|---------|-----------------|-------|
| xunit | 2.x | Stable |
| xunit.runner.visualstudio | 2.x | |
| Microsoft.NET.Test.Sdk | 17.x | |
| FluentAssertions | 6.x | Review v7 breaking changes before upgrading |
| NSubstitute | 5.x | |
| Bogus | 35.x | |
| Coverlet.Collector | 6.x | |
| Respawn | 6.x | |
| AutoFixture | 4.x | |
| PactNet | 4.x | |

---

## net8.0 Approved Versions

### Microsoft.EntityFrameworkCore.*

| Package | Approved Version | Notes |
|---------|-----------------|-------|
| Microsoft.EntityFrameworkCore | 8.x | Must match major version |
| Microsoft.EntityFrameworkCore.Design | 8.x | |
| Microsoft.EntityFrameworkCore.SqlServer | 8.x | |

### Npgsql

| Package | Approved Version | Notes |
|---------|-----------------|-------|
| Npgsql | 8.x | Breaking changes from v7. Review DateTime behaviour. |
| Npgsql.EntityFrameworkCore.PostgreSQL | 8.x | Must align with EF Core 8 |

### Azure Functions

| Package | Approved Version | Notes |
|---------|-----------------|-------|
| Microsoft.NET.Sdk.Functions | 4.x | In-process; supported on .NET 8 but deprecated path |
| Microsoft.Azure.Functions.Worker | 1.x or 2.x | Isolated worker; preferred |

### OpenAPI / Swagger

| Package | Approved Version | Notes |
|---------|-----------------|-------|
| Swashbuckle.AspNetCore | 6.x | Supported for .NET 8 |
| NSwag.AspNetCore | 14.x | Supported for .NET 8 |

---

## Maintenance Notes

- Review this file quarterly and after each major .NET release.
- When approving a package version in a PR review, update this file in the same MR.
- "TBD" entries indicate packages that have not yet been vetted for that target framework.
