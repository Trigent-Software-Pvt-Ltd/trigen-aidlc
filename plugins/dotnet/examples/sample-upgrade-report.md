# Sample Upgrade Report

Example output from the `/dotnet:version-upgrade` skill for a Web API upgrading from `net8.0` to `net10.0`.

---

# .NET Upgrade Report

**Date:** 2026-05-04 10:30 UTC
**Repo:** `/repos/trigent/my-service`
**Target Framework:** `net10.0`
**Version Guidance:** ✅ Found — `net10.0.md`
**Mode:** upgrade applied

---

## Repo Summary

- Solution files (`.sln`): `Trigent.MyService.sln`
- Solution files (`.slnx`): none
- `global.json` SDK: `8.0.404`
- Central Package Management: ❌ not active
- `Directory.Build.props`: ✅ present
- TFM in `Directory.Build.props`: ❌ no (set per-project)

---

## Project Summary

| Project | Type | Current TFM | Changed |
|---------|------|-------------|---------|
| `Trigent.MyService.Api.csproj` | webapi | `net8.0` | ✅ → `net10.0` |
| `Trigent.MyService.Api.BusinessLogic.csproj` | library | `net8.0` | ✅ → `net10.0` |
| `Trigent.MyService.Api.Shared.csproj` | library | `net8.0` | ✅ → `net10.0` |
| `Trigent.MyService.Api.Client.csproj` | library | `net8.0;netstandard2.0` | ✅ → `net10.0;netstandard2.0` |
| `Trigent.MyService.Api.UnitTests.csproj` | test | `net8.0` | ✅ → `net10.0` |
| `Trigent.MyService.Api.IntegrationTests.csproj` | test | `net8.0` | ✅ → `net10.0` |

---

## Changes Applied

### TFM Updates

- `src/Trigent.MyService.Api/Trigent.MyService.Api.csproj`: `net8.0` → `net10.0`
- `src/Trigent.MyService.Api.BusinessLogic/Trigent.MyService.Api.BusinessLogic.csproj`: `net8.0` → `net10.0`
- `src/Trigent.MyService.Api.Shared/Trigent.MyService.Api.Shared.csproj`: `net8.0` → `net10.0`
- `src/Trigent.MyService.Api.Client/Trigent.MyService.Api.Client.csproj`: `net8.0;netstandard2.0` → `net10.0;netstandard2.0`
- `test/Trigent.MyService.Api.UnitTests/Trigent.MyService.Api.UnitTests.csproj`: `net8.0` → `net10.0`
- `test/Trigent.MyService.Api.IntegrationTests/Trigent.MyService.Api.IntegrationTests.csproj`: `net8.0` → `net10.0`

### SDK Changes

`global.json`:
- Before: `8.0.404` (rollForward: `latestMinor`)
- After: `10.0.100` (rollForward: `latestMinor`)

### Package Management

Central Package Management: not active. No package changes applied (use `--allow-cpm` to migrate).

### Package Changes

No packages were modified in this run. See Package Risks section below for required follow-up.

---

## Build Result

```
dotnet restore Trigent.MyService.sln   ✅ Succeeded
dotnet build Trigent.MyService.sln     ✅ Succeeded (3 warnings)
```

**Warnings (non-blocking):**
- `CS0618` in `Trigent.MyService.Api/Startup.cs:142` — `UseSwaggerUI` overload deprecated in Swashbuckle 7.x
- `CS8602` in `Trigent.MyService.Api.BusinessLogic/Managers/OrderManager.cs:67` — nullable dereference possible
- `CS8602` in `Trigent.MyService.Api.BusinessLogic/Handlers/CreateOrderHandler.cs:89` — nullable dereference possible

---

## Test Result

Tests not run (use `--run-tests` flag to run `dotnet test` after upgrade).

---

## Package Risks

### HIGH Risk Packages

| Package | Version | Reason |
|---------|---------|--------|
| `Npgsql.EntityFrameworkCore.PostgreSQL` | `8.0.2` | Must align with EF Core 10.x for net10.0. Npgsql 9.x has DateTime UTC enforcement changes. |
| `Microsoft.EntityFrameworkCore` | `8.0.2` | Must upgrade to 10.x for net10.0. EF Core major version must match runtime. |
| `Microsoft.EntityFrameworkCore.Design` | `8.0.2` | Must align with EF Core version. |
| `Swashbuckle.AspNetCore` | `6.9.0` | v6 not compatible with .NET 10. Must upgrade to v7.x or replace with Scalar. |

### MEDIUM Risk Packages

| Package | Version | Reason |
|---------|---------|--------|
| `Microsoft.AspNetCore.Authentication.JwtBearer` | `8.0.2` | Ships with runtime — remove Version pin; let SDK supply for net10.0. |
| `MassTransit` | `8.3.0` | v9 recommended for .NET 10 ecosystem. v8→v9 has breaking changes in consumer registration. |
| `MassTransit.RabbitMQ` | `8.3.0` | Must align with MassTransit version. |

### LOW Risk Packages

`Serilog`, `Serilog.AspNetCore`, `Serilog.Sinks.Console`, `FluentValidation`, `MediatR`, `AutoMapper`, `xunit`, `FluentAssertions`, `NSubstitute`, `Bogus`, `Coverlet.Collector`

---

## OpenAPI Tooling

Detected: `Swashbuckle.AspNetCore` (`6.9.0`)

**Action Required:** Swashbuckle 6.x is not compatible with .NET 10.

Options:
1. **Upgrade to Swashbuckle 7.x** — minimal code changes, maintains Swagger UI.
2. **Replace with Scalar** — uses built-in `Microsoft.AspNetCore.OpenApi`; recommended for .NET 10+ services.

Do NOT auto-replace. This requires an explicit decision. See `references/version-guidance/net10.0.md` for Scalar migration details.

---

## Azure Functions

No Azure Functions detected in this repository.

---

## GitLab CI

Found: `.gitlab-ci.yml`

**Docker images referenced:**
- `mcr.microsoft.com/dotnet/sdk:8.0`
- `mcr.microsoft.com/dotnet/aspnet:8.0`

**SDK/Version variables:**
- `DOTNET_VERSION: "8.0"`
- `SDK_VERSION: "8.0.404"`

**Manual action required:** Update image tags and version variables to match `net10.0`.

---

## Build & Test

Run after applying package changes:

```bash
dotnet --info
dotnet restore Trigent.MyService.sln
dotnet build Trigent.MyService.sln
dotnet test Trigent.MyService.sln
```

---

## Manual Follow-Up Checklist

- [ ] Upgrade `Microsoft.EntityFrameworkCore` and `Npgsql.EntityFrameworkCore.PostgreSQL` to `10.x` versions — test all DB operations and EF Core migrations
- [ ] Upgrade or replace `Swashbuckle.AspNetCore` — v6 is incompatible with .NET 10
- [ ] Remove explicit `Version` pin from `Microsoft.AspNetCore.Authentication.JwtBearer` — let SDK supply
- [ ] Evaluate `MassTransit` upgrade to v9 — separate MR recommended
- [ ] Fix 2 nullable reference warnings (`CS8602`) — add null checks or `!` operators where appropriate
- [ ] Run full test suite after package changes

---

## GitLab CI Follow-Up Items

- [ ] Update `.gitlab-ci.yml` build image: `mcr.microsoft.com/dotnet/sdk:8.0` → `mcr.microsoft.com/dotnet/sdk:10.0`
- [ ] Update `.gitlab-ci.yml` runtime image: `mcr.microsoft.com/dotnet/aspnet:8.0` → `mcr.microsoft.com/dotnet/aspnet:10.0`
- [ ] Update CI variable `DOTNET_VERSION: "8.0"` → `DOTNET_VERSION: "10.0"`
- [ ] Update CI variable `SDK_VERSION: "8.0.404"` → `SDK_VERSION: "10.0.100"`
- [ ] Update `Dockerfile` FROM lines from `sdk:8.0` / `aspnet:8.0` to `sdk:10.0` / `aspnet:10.0`

---

## Modernisation Opportunities (Not Applied)

| Opportunity | Why Not Applied | How to Activate |
|-------------|-----------------|-----------------|
| Central Package Management | Not requested | `--allow-cpm` flag |
| `.slnx` migration | Not requested | `--allow-slnx` flag |
| Scalar (replace Swashbuckle) | Requires explicit decision | `--allow-breaking-changes` + team approval |
| Centralise TFM in `Directory.Build.props` | Not requested | `--allow-dbprops` flag |

---

## GitLab MR Description

```markdown
## .NET Version Upgrade — `net10.0`

### Summary

Upgrades `Trigent.MyService` from `net8.0` to `net10.0`.

| | |
|---|---|
| **Current Framework** | `net8.0` |
| **Target Framework** | `net10.0` |
| **SDK Version** | `10.0.100` |
| **Risk Level** | 🟡 Medium |

---

### Changes

#### TFM Updates
- 6 project files updated from `net8.0` → `net10.0`
- `Trigent.MyService.Api.Client.csproj`: `net8.0;netstandard2.0` → `net10.0;netstandard2.0`
- `global.json`: SDK `8.0.404` → `10.0.100`

#### Package Changes
No packages modified in this MR (follow-up MRs required — see below).

#### GitLab CI / Docker
Not included in this MR — follow-up items listed below.

---

### What Was NOT Changed (Manual Follow-Up Required)

- [ ] EF Core and Npgsql package upgrades (HIGH risk — separate MR)
- [ ] Swashbuckle → must upgrade to v7.x or evaluate Scalar
- [ ] GitLab CI image tags
- [ ] Dockerfile base images
- [ ] MassTransit v8 → v9 evaluation
- [ ] Central Package Management migration

---

### High-Risk Packages — Manual Review Required

| Package | Current Version | Recommended | Risk | Action |
|---------|----------------|-------------|------|--------|
| `Microsoft.EntityFrameworkCore` | `8.0.2` | `10.0.x` | HIGH | Follow-up MR — run all DB integration tests |
| `Npgsql.EntityFrameworkCore.PostgreSQL` | `8.0.2` | `10.0.x` | HIGH | Follow-up MR — review DateTime UTC enforcement |
| `Swashbuckle.AspNetCore` | `6.9.0` | `7.x` or Scalar | HIGH | Required for .NET 10 — choose path before merging |

---

### Build & Test Results

```
dotnet restore:   ✅ Succeeded
dotnet build:     ✅ Succeeded (3 warnings)
dotnet test:      Not run in this MR
```

---

### Reviewer Checklist

- [ ] All projects build successfully
- [ ] EF Core packages NOT automatically upgraded (confirmed)
- [ ] Swashbuckle upgrade path agreed (7.x or Scalar)
- [ ] No auth/security behaviour changes
- [ ] Follow-up issues created for package upgrades and CI updates

/label ~dotnet-upgrade ~net10.0
/assign @wenhamdorsett
```
