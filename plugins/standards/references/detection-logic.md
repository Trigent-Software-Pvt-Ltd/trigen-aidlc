# Standards Detection Logic

Shared detection logic for the standards plugin. Used by `standards-load`, `standards-audit`, and `standards-view` to determine which standards apply to a given repository.

## Repo Resolution

Before running project-type detection, determine which repository to scan.

| User prompt pattern | How to resolve | Example |
|---------------------|----------------|---------|
| Explicit path provided | Use the path | "Plan work in C:\trigent\repos\user-service" |
| Working in a repo (most common) | Use current working directory | "Update this method", "Fix the failing test" |
| Jira ticket reference | Fetch ticket, infer repo from service/component, confirm if ambiguous | "Review PLT-1234 and implement a solution" |
| MR reference | Fetch MR details from GitLab, identify the source repo | "/standards:audit --mr 57" |
| Multiple repos named | Detect each independently | "Update user-service and api-gateway" |
| Ambiguous / no repo context | Ask the user before proceeding | "Implement the auth changes" (no CWD repo, no ticket) |

Default to the current working directory when no repo is specified.

## Standards File Locations

All paths relative to the plugin root (`references/technical-guidance/`):

| File | Scope |
|------|-------|
| `global.md` | All projects — security, observability, API design, testing pyramid, resilience |
| `dotnet.md` | .NET / C# — project structure, CQRS/MediatR, preferred packages, testing |
| `rails.md` | Ruby on Rails — project structure, REST/GraphQL, preferred gems, RSpec |
| `iac.md` | Terraform + Terragrunt — module structure, naming, state management, Azure |
| `vue.md` | Vue 3 — component architecture, state management, routing, testing |
| `application-profiles/README.md` | .NET only — detection logic and profile index |
| `application-profiles/dotnet-framework-mvc-profile.md` | .NET Framework 4.x MVC — SimpleInjector, EF6+Dapper, OWIN |
| `application-profiles/dotnet-webapi-profile.md` | .NET 6-9 Web API — SimpleInjector, Mapster |
| `application-profiles/dotnet-function-app-profile.md` | .NET 6-9 Function App — in-process, FunctionsStartup |
| `application-profiles/dotnet-webapi-v10-profile.md` | .NET 10+ Web API — Microsoft DI, AutoMapper |
| `application-profiles/dotnet-function-v10-profile.md` | .NET 10+ Function App — isolated worker, HostBuilder |
| `application-profiles/dotnet-mixed-solution-profile.md` | .NET 10+ Mixed — both API + Functions entry points |

## Project Type Detection

Scan the resolved repository root for these markers:

| Markers to scan for | Project Type | Standards to load |
|---------------------|-------------|-------------------|
| `*.csproj`, `*.sln`, `*.slnx`, `*.cs`, `global.json` | .NET | global.md + dotnet.md + detected application profile |
| `Gemfile`, `config/routes.rb`, `bin/rails`, `config/application.rb` | Rails | global.md + rails.md |
| `root.hcl`, `terragrunt.hcl`, `*.hcl`, `*.tf` | IaC | global.md + iac.md |
| `package.json` with `vue` dependency, `*.vue` files, `vite.config.ts`/`vite.config.js` | Vue | global.md + vue.md |
| None of the above | Other | global.md only |

Use the Glob tool to check for these markers. Stop at the first match — project types are mutually exclusive in Trigent repos.

**Vue detection note:** Many non-Vue projects have a `package.json`. Only classify as Vue if `*.vue` files exist OR `package.json` contains a `vue` dependency. Check for `.vue` files first as the fastest indicator.

## .NET Application Profile Detection

If the project type is .NET, determine the specific application profile. This provides Trigent-specific implementation patterns (DI container, mapping library, project structure) beyond the generic dotnet.md guidance.

### Step 1: Determine .NET Version

Check `global.json` for `sdk.version`, or scan `*.csproj` files for `<TargetFramework>` or `<TargetFrameworkVersion>`:

| Version found | Version set |
|---------------|-------------|
| `TargetFrameworkVersion` v4.x (e.g., v4.7.2) | Legacy Framework |
| `TargetFramework` net6.0 through net9.0 | Legacy |
| `TargetFramework` net10.0 or higher | Modern (v10) |

### Step 2: Detect Application Type

**For Legacy Framework (.NET 4.x):**

| Markers | Profile | File to load |
|---------|---------|-------------|
| `Global.asax.cs` + `ContainerConfig.cs` + `Areas/` | .NET Framework MVC | `dotnet-framework-mvc-profile.md` |
| No match | No profile | Use dotnet.md only |

**For Legacy (.NET 6-9):**

| Markers | Profile | File to load |
|---------|---------|-------------|
| `host.json` + `[FunctionName]` attribute | Function App (Legacy) | `dotnet-function-app-profile.md` |
| `Controllers/` folder + `ContainerConfiguration` returns `Container` | Web API (Legacy) | `dotnet-webapi-profile.md` |
| No match | No profile | Use dotnet.md only |

**For Modern (.NET 10+):**

| Markers | Profile | File to load |
|---------|---------|-------------|
| Both `Controllers/` AND `host.json`/`[Function]` | Mixed Solution | `dotnet-mixed-solution-profile.md` |
| `host.json` + `[Function]` attribute + `HostBuilder` | Function App v10 | `dotnet-function-v10-profile.md` |
| `Controllers/` + `ContainerConfiguration` extends `IServiceCollection` | Web API v10 | `dotnet-webapi-v10-profile.md` |
| No match | No profile | Use dotnet.md only |

Use Grep to scan for these markers. Check for Mixed Solution first (it matches both API and Functions markers).
