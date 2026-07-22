---
owner: Architecture Guild
last-reviewed: 2026-02-05
scope: .NET Application Profiles (Trigent-specific patterns)
---

# Application Profiles

Application Profiles provide Trigent-specific implementation patterns that sit between generic project-type guidance (dotnet.md) and project-level guidance (Intent doc).

## Guidance Hierarchy

```
Global (global.md)
    ↓
Project-Type (dotnet.md / rails.md)
    ↓
Application Profile (this tier)
    ↓
Project-Level (Intent doc)
```

## Available Profiles

### Legacy Framework Profiles (.NET Framework 4.x)

For **legacy monolithic applications** on .NET Framework 4.6.1-4.7.2:

| Profile | Detection Markers | Key Patterns |
|---------|-------------------|--------------|
| [.NET Framework MVC](dotnet-framework-mvc-profile.md) | `TargetFrameworkVersion` v4.x, `Global.asax.cs`, `ContainerConfig.cs`, Areas/ | SimpleInjector, EF6+Dapper, Manual translators, OWIN |

### Legacy Profiles (.NET 6-9)

For **existing applications** on .NET 6, 7, 8, or 9:

| Profile | Detection Markers | Key Patterns |
|---------|-------------------|--------------|
| [Web API (Legacy)](dotnet-webapi-profile.md) | SimpleInjector, `container.Register<>()`, .NET 6-9 | SimpleInjector DI, Mapster, in-API BusinessLogic |
| [Function App (Legacy)](dotnet-function-app-profile.md) | `FunctionsStartup`, `[FunctionName]`, .NET 6-9 | In-process model, FunctionsStartup |

### Modern Profiles (.NET 10+)

For **new applications** created from the `dotnet` template repository:

| Profile | Detection Markers | Key Patterns |
|---------|-------------------|--------------|
| [Web API v10](dotnet-webapi-v10-profile.md) | .NET 10+, no Functions | Microsoft DI, AutoMapper, shared ContainerConfiguration |
| [Function App v10](dotnet-function-v10-profile.md) | .NET 10+, `[Function]`, `HostBuilder`, no Controllers | Isolated worker, Microsoft DI, shared ContainerConfiguration |
| [Mixed Solution](dotnet-mixed-solution-profile.md) | .NET 10+, both Controllers + Functions | Both entry points, shared business logic |

## Detection Logic

### Step 1: Confirm .NET Project
Check for `.csproj`, `.sln`, `.slnx`, `*.cs` files (from dotnet.md detection).

### Step 2: Determine .NET Version

Check `global.json` or `*.csproj` for target framework:

```xml
<!-- SDK-style .csproj (.NET Core / .NET 5+) -->
<TargetFramework>net10.0</TargetFramework>

<!-- Legacy .csproj (.NET Framework) -->
<TargetFrameworkVersion>v4.7.2</TargetFrameworkVersion>

<!-- Or in global.json -->
{
  "sdk": { "version": "10.0.100" }
}
```

| Version | Profile Set |
|---------|-------------|
| v4.6.1, v4.7, v4.7.2 (TargetFrameworkVersion) | Legacy Framework profiles |
| net6.0, net7.0, net8.0, net9.0 | Legacy profiles |
| net10.0+ | Modern (v10) profiles |

### Step 3: Detect Application Type

**For .NET Framework 4.x:**

```
IF Global.asax.cs exists AND ContainerConfig.cs exists:
    → .NET Framework MVC Profile
ELSE:
    → No specific profile (use dotnet.md only)
```

**For .NET 6-9 (Legacy):**

```
IF host.json exists AND [FunctionName] attribute found:
    → Function App (Legacy) Profile
ELSE IF Controllers/ folder exists:
    → Web API (Legacy) Profile
ELSE:
    → No specific profile (use dotnet.md only)
```

**For .NET 10+ (Modern):**

```
IF has Controllers/ AND has host.json/[Function]:
    → Mixed Solution Profile
ELSE IF has host.json AND [Function] attribute:
    → Function App v10 Profile
ELSE IF has Controllers/:
    → Web API v10 Profile
ELSE:
    → No specific profile (use dotnet.md only)
```

### Detailed Detection Markers

**.NET Framework MVC - .NET Framework 4.6.1-4.7.2:**
- `TargetFrameworkVersion` is v4.6.1, v4.7, or v4.7.2 (in legacy .csproj format)
- `Global.asax.cs` exists with `Container.Init()` call
- `ContainerConfig.cs` exists with SimpleInjector configuration
- `Areas/` directory exists (MVC Areas pattern)
- `web.config` file (not appsettings.json)
- `App_Code/Startup.cs` with OWIN middleware (app.Use)
- No SDK-style .csproj (uses legacy XML format)

**Web API (Legacy) - .NET 6-9:**
- `TargetFramework` is net6.0, net7.0, net8.0, or net9.0
- `Controllers/` directory exists
- `ContainerConfiguration` returns `Container` (SimpleInjector)
- `container.Register<>()` or `container.RegisterInstance()` syntax
- `Startup.cs` with SimpleInjector configuration
- No `host.json`

**Function App (Legacy) - .NET 6-9:**
- `TargetFramework` is net6.0, net7.0, net8.0, or net9.0
- `host.json` file exists
- `[FunctionName(...)]` attribute (in-process)
- `FunctionsStartup` class
- No `Controllers/` directory

**Web API v10 - .NET 10+:**
- `TargetFramework` is net10.0 or higher
- `Controllers/` directory exists
- `ContainerConfiguration` extends `IServiceCollection` (Microsoft DI)
- `services.AddSingleton<>()` syntax
- No `host.json` or `[Function]` attributes

**Function App v10 - .NET 10+:**
- `TargetFramework` is net10.0 or higher
- `host.json` file exists
- `[Function(...)]` attribute (isolated worker)
- `HostBuilder` with `ConfigureFunctionsWorkerDefaults()`
- `ContainerConfiguration` extends `IServiceCollection` (Microsoft DI)
- No `Controllers/` directory

**Mixed Solution - .NET 10+:**
- `TargetFramework` is net10.0 or higher
- Both `Controllers/` AND `host.json`/`[Function]` attributes
- `ContainerConfiguration` extends `IServiceCollection` (Microsoft DI)
- `Trigent.{Service}.Api/` AND `Trigent.{Service}.Functions/` projects

## Key Differences Between Profile Sets

| Aspect | Framework (.NET 4.x) | Legacy (.NET 6-9) | Modern (.NET 10+) |
|--------|----------------------|-------------------|-------------------|
| Runtime | .NET Framework | .NET Core / .NET 5-9 | .NET 10+ |
| Web Framework | ASP.NET MVC 5 + OWIN | ASP.NET Core | ASP.NET Core |
| Configuration | web.config | appsettings.json | appsettings.json |
| Project Structure | Areas-based monolith | In entry point project | Separate BusinessLogic project |
| Startup | `Global.asax.cs` | `Startup.cs` / `FunctionsStartup` | `Program.cs` / `HostBuilder` |
| Functions Model | N/A | In-process (`[FunctionName]`) | Isolated worker (`[Function]`) |

## How to Apply Profiles

1. **Detect the .NET version** from global.json or csproj
2. **Detect the application type** using markers above
3. **Confirm with user** before applying
4. **Load profile guidance** in addition to dotnet.md
5. **Apply in precedence order**: Global → dotnet.md → Application Profile → Project-level

## When Profiles Conflict with dotnet.md

Application profiles may specify patterns that differ from generic dotnet.md guidance. For example:

| dotnet.md | Application Profile | Resolution |
|-----------|---------------------|------------|
| "Prefer scoped lifetime" | Legacy Web API: "Use SimpleInjector with AsyncScopedLifestyle" | Follow Application Profile |
| "AutoMapper or Mapster" | Legacy Web API: "Mapster" / v10: "AutoMapper" | Follow Application Profile |

When conflicts occur:
1. Application Profile takes precedence over dotnet.md
2. Document the deviation if significant
3. Project-level guidance can still override Application Profile
