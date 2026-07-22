# .NET Upgrade Policy

Internal policy for engineering teams upgrading .NET repositories on the Trigent platform.

---

## Default Target Version

| Scenario | Recommendation |
|----------|---------------|
| New projects | .NET 10 (`net10.0`) — current team LTS |
| Existing projects (greenfield upgrade) | Target `net10.0` |
| Existing projects (conservative upgrade) | Target `net8.0` at minimum |
| Multi-targeting libraries | Keep `netstandard2.0` or `netstandard2.1`; upgrade the `netX.0` target |

**Never target a non-LTS release for production workloads** unless there is a specific technical requirement and an approved ADR.

---

## LTS Policy

| Version | Status | EOL |
|---------|--------|-----|
| .NET 6 | End of Life | November 2024 — **must upgrade** |
| .NET 7 | End of Life | May 2024 — **must upgrade** |
| .NET 8 | LTS — Active | November 2026 |
| .NET 9 | Non-LTS — Active | May 2026 |
| .NET 10 | LTS — Active | November 2027 |
| .NET 11 (future) | Non-LTS | ~May 2028 |
| .NET 12 (future) | LTS | ~November 2028 |

**Prefer LTS releases.** Skip non-LTS versions unless a specific feature is required.

---

## How to Choose the Target Version

1. **Is the current version End of Life?** → Upgrade to the latest LTS immediately.
2. **Are you on .NET 8 LTS?** → You may stay until November 2026; plan .NET 10 upgrade for 2025/2026.
3. **Starting a new project?** → Always start on .NET 10+.
4. **Is your application an Azure Function (in-process)?** → Migration to isolated worker is required before targeting .NET 10. Plan this as a separate work item.
5. **Are you upgrading a library?** → Keep `netstandard2.0` multi-targeting unless you are certain all consumers have been upgraded.

---

## Multi-Targeting Guidance

| Use Case | Guidance |
|----------|---------|
| Internal application (Web API, Functions) | Single TFM preferred; no multi-targeting |
| Shared library consumed by older internal repos | `net10.0;netstandard2.0` or `net10.0;net8.0` |
| NuGet package for external consumers | Broad multi-targeting as required by consumer matrix |
| Test projects | Single TFM matching the project under test |

- **Do not add multi-targeting to applications.** Only libraries that need to support multiple consumers benefit from it.
- **Preserve existing `netstandard` targets** unless all consuming repos have been upgraded.
- When adding a new TFM, validate the build passes for each target before merging.

---

## Central Package Management

**Recommended for all repositories with more than one project file.**

### When to Migrate

Migrate to Central Package Management (`Directory.Packages.props`) when:
- You have 2+ projects and version consistency is important
- You are doing a major upgrade (a natural time to consolidate versions)
- You are creating a new repo from the Trigent .NET template (already configured)

### When Not to Migrate

Do NOT migrate CPM during the same MR as a TFM upgrade unless the repo is small and low-risk. Separate concerns into separate MRs.

### CPM Pattern

```xml
<!-- Directory.Packages.props at repo root -->
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="Serilog" Version="4.0.0" />
    <PackageVersion Include="MediatR" Version="12.4.1" />
  </ItemGroup>
</Project>
```

Remove `Version` attributes from individual `.csproj` `PackageReference` elements when CPM is active.

---

## Directory.Build.props Guidance

**Recommended for all multi-project repositories.**

Centralise these properties in `Directory.Build.props`:

```xml
<Project>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <LangVersion>latest</LangVersion>
  </PropertyGroup>
</Project>
```

- Do not centralise the TFM if projects legitimately differ (e.g., a library multi-targets but an app does not).
- Individual project files can override properties from `Directory.Build.props`.

---

## .sln vs .slnx

| Format | Status | Recommendation |
|--------|--------|----------------|
| `.sln` | Legacy binary format | Keep for compatibility; do not remove |
| `.slnx` | Modern XML format | Add when modernising; prefer for new repos |

**Recommendation:** Add `.slnx` alongside `.sln` when upgrading. Do not remove `.sln` unless all tooling in use supports `.slnx`.

---

## Package Upgrade Guidance

- **Upgrade risky packages separately** from the TFM upgrade MR where possible.
- **Do not pin `Microsoft.Extensions.*` or `Microsoft.AspNetCore.*`** packages to a version separate from the runtime — remove explicit version pins and let the SDK supply them.
- **EF Core major version** must match the target runtime major version (e.g., EF Core 10.x for .NET 10).
- **Npgsql** major version upgrades require explicit testing — DateTime behaviour and nullable handling changed in v8+.
- **MassTransit** major version upgrades (v7→v8→v9) contain configuration breaking changes. Review the MassTransit changelog before upgrading.

---

## GitLab CI Guidance

When upgrading the TFM, also update:

1. Docker image tags in build/test/publish stages:
   ```yaml
   image: mcr.microsoft.com/dotnet/sdk:10.0
   ```

2. Runtime images in Dockerfiles:
   ```dockerfile
   FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
   FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
   ```

3. `DOTNET_VERSION` / `SDK_VERSION` CI variables.

**Prefer pinning to a specific SDK patch version** in `global.json` (`10.0.100`) rather than using `:latest` Docker tags.

---

## Docker Guidance

- Always pin to a specific version tag, never `:latest`.
- Prefer distroless or Alpine variants for runtime images to minimise attack surface.
- Build stage: `mcr.microsoft.com/dotnet/sdk:10.0`
- Runtime stage (Web API): `mcr.microsoft.com/dotnet/aspnet:10.0`
- Runtime stage (Console/Functions): `mcr.microsoft.com/dotnet/runtime:10.0`

---

## Azure Functions Guidance

| Scenario | Action |
|----------|--------|
| In-process model on .NET 6/7/8 | Plan migration to isolated worker before targeting .NET 10 |
| Isolated worker on .NET 6/7/8 | Can upgrade TFM directly; verify package versions |
| New Functions project | Use isolated worker model only |

**In-process Azure Functions are not supported on .NET 10+.** This is a Microsoft hard requirement, not a team preference. Migration must happen before the .NET 10 upgrade.

---

## Scalar vs Swashbuckle Guidance

| Tool | Status | Recommendation |
|------|--------|---------------|
| Swashbuckle.AspNetCore | Widely used in existing Trigent services | Keep on .NET 8; evaluate Scalar for .NET 10 |
| NSwag | Used for code generation in some services | Keep unless explicitly migrating |
| Scalar | Modern OpenAPI UI using built-in .NET OpenAPI | Preferred for new .NET 10 services |

**Do not automatically replace Swashbuckle.** This is a conscious modernisation decision requiring:
- Evaluation of Scalar's feature set vs current Swashbuckle usage
- Updating client code that depends on Swashbuckle-specific behaviour
- Team agreement on the UI/DX change

For .NET 10, `Microsoft.AspNetCore.OpenApi` is built-in and Scalar sits on top of it.

---

## Review Checklist

Before merging a .NET upgrade MR:

- [ ] All projects build without errors
- [ ] All tests pass (unit, integration, functional)
- [ ] No new build warnings suppressed without reason
- [ ] `global.json` updated to match target SDK
- [ ] Dockerfile base images updated
- [ ] GitLab CI image tags updated
- [ ] HIGH-risk packages reviewed and versions confirmed
- [ ] EF Core migrations validated (if applicable)
- [ ] Azure Functions execution model verified (if applicable)
- [ ] No authentication/security behaviour changes
- [ ] Breaking changes documented in MR description
