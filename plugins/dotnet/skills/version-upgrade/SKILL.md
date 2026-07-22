---
name: version-upgrade
description: "Upgrade .NET repositories from their current version to a requested target version. Supports Web APIs, Azure Functions, class libraries, and test projects. Scans repo structure, detects frameworks/packages/CI dependencies, applies safe mechanical upgrade changes, and produces a GitLab MR-ready report. Trigger on: upgrade .NET, migrate from .NET 6/7/8/9, update TargetFramework, modernize .NET repo, prepare .NET upgrade MR, assess .NET upgrade readiness."
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
argument-hint: "[target-framework] [--report-only] [--allow-packages] [--allow-cpm] [--allow-dbprops] [--allow-slnx] [--allow-breaking-changes] [--run-tests]"
---

# .NET Version Upgrader

You are performing a structured .NET version upgrade workflow for an engineering team using GitLab.com, GitLab CI, and GitLab Merge Requests. Follow each phase in order.

---

## Phase 0: Understand the Request

Parse arguments or ask the user for the following, using [FACT]/[INFERRED]/[ASSUMED] labels where appropriate:

| Parameter | Default | Flag |
|-----------|---------|------|
| Target framework | current approved LTS (`net10.0`) | positional arg or `--target` |
| Modify files or report only | modify | `--report-only` |
| Allow package version upgrades | no | `--allow-packages` |
| Allow Central Package Management migration | no | `--allow-cpm` |
| Allow Directory.Build.props creation/refactor | no | `--allow-dbprops` |
| Allow .slnx migration | no | `--allow-slnx` |
| Allow breaking-change fixes | no | `--allow-breaking-changes` |
| Run tests after upgrade | no | `--run-tests` |

**Target framework validation:**

The target framework must match one of these valid patterns:
- `net8.0`, `net9.0`, `net10.0`, `net12.0`, `net14.0` (or any `netX.0` where X >= 6)
- `netstandard2.0`, `netstandard2.1`
- `net48`, `net472` (only for library multi-targeting, never as a migration target)

If the user provides a version number (e.g., "10", ".NET 10", "10.0"), normalise to the correct TFM (e.g., `net10.0`).

If no target is specified, default to `net10.0` (current team LTS) and tell the user.

**Check for version-specific guidance:**
After determining the target, use the **Read** tool to read:
`{{SKILL_DIR}}/../../references/version-upgrade/version-guidance/{target-framework}.md`

If Read succeeds, guidance is available — note it for Phase 4. If Read returns an error or file-not-found, try the Bash fallback:
```bash
find "$HOME/.claude/plugins" -name "{target-framework}.md" -path "*/version-guidance/*" 2>/dev/null | head -1
```
Then Read from the returned path. Report whether guidance was found — this controls whether modernisation recommendations are available.

---

## Phase 1: Scan the Repository

Run the scan script if available, otherwise perform manual scanning. Present a summary before making any changes.

### Files to Scan

**Solution and project files:**
- `*.sln` — Visual Studio solution files
- `*.slnx` — Modern XML solution files
- `*.csproj` — C# project files (recurse)
- `*.fsproj` — F# project files (recurse)

**Build configuration:**
- `global.json` — SDK version pin
- `Directory.Build.props` — Shared MSBuild properties
- `Directory.Build.targets` — Shared MSBuild targets
- `Directory.Packages.props` — Central Package Management

**Package management:**
- `NuGet.config`

**Container and CI/CD:**
- `Dockerfile` (all, recurse)
- `.gitlab-ci.yml`
- GitLab CI include templates (follow `include:` references where local)

**Azure Functions:**
- `host.json` (all, recurse)
- `local.settings.json` (all, recurse)
- `*.csproj` files with Functions SDK references

**Configuration:**
- `appsettings.json`, `appsettings.*.json`

### What to Detect

**Framework detection:**
- Current `<TargetFramework>` or `<TargetFrameworks>` in each project file
- SDK version from `global.json`
- Whether `TargetFramework` is set in `Directory.Build.props` (centralised)

**Application type (per project):**
- **ASP.NET Core Web API:** has `Microsoft.AspNetCore.*` packages or `<Project Sdk="Microsoft.NET.Sdk.Web">`
- **Azure Function (in-process):** has `Microsoft.NET.Sdk.Functions` package, `[FunctionName]` attribute usage, `FunctionsStartup` class
- **Azure Function (isolated worker):** has `Microsoft.Azure.Functions.Worker` package, `[Function]` attribute, `ConfigureFunctionsWorkerDefaults()`
- **Class library:** `<Project Sdk="Microsoft.NET.Sdk">` without web/functions markers
- **Test project:** contains `xunit`, `NUnit`, `MSTest` package references

**Package management:**
- Central Package Management: `Directory.Packages.props` exists AND `<ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>`
- Packages with inline `Version` attributes (non-CPM pattern)
- PackageVersion entries in Directory.Packages.props

**Risky packages** (flag for manual review — see `references/risky-packages.md`):
- Entity Framework Core packages
- Npgsql
- Microsoft.Extensions.*
- Microsoft.AspNetCore.*
- Azure Functions worker and extensions packages
- Newtonsoft.Json / System.Text.Json
- OpenTelemetry.*
- MassTransit.*
- RabbitMQ.Client
- Serilog.*
- Swashbuckle.AspNetCore
- NSwag.*
- Scalar.*
- FluentValidation
- MediatR

**OpenAPI/Swagger detection:**
- Swashbuckle.AspNetCore usage
- NSwag usage
- Scalar usage (if already modernised)
- Registration in Program.cs / Startup.cs

**GitLab CI detection:**
- Docker image tags containing SDK/runtime versions (`mcr.microsoft.com/dotnet/sdk:X.X`, `mcr.microsoft.com/dotnet/aspnet:X.X`)
- `DOTNET_VERSION`, `SDK_VERSION`, `DOTNET_SDK_VERSION` variables
- Build, test, publish, deploy stages
- Test report artifact paths
- Coverage job configuration
- `include: project:` references to `trigent1/pipeline-templates` — if present, extract the `ref:` (template version/branch) and any `inputs:` overrides for SDK/version variables. The template owns SDK defaults; individual services override via `inputs:`.

**Solution file detection:**
- Whether only `.sln` exists (recommend `.slnx`)
- Whether `.slnx` already exists (modern)
- Whether both exist (prefer `.slnx` for validation)

---

## Phase 2: Present Pre-Upgrade Summary

Before making any changes, present:

```
## Pre-Upgrade Scan Summary

**Repo:** {path}
**Target framework:** {target-framework}
**Version guidance available:** yes/no

### Projects Found
| Project | Type | Current TFM | Multi-target |
|---------|------|-------------|--------------|

### Package Management
- Central Package Management: yes/no
- Directory.Build.props: yes/no
- Directory.Build.targets: yes/no

### Risky Packages Detected
{list packages requiring care}

### GitLab CI
{findings}

### Flags for This Run
{list all flags and their values}

### What Will Change
{itemised list of planned changes}

### What Will NOT Change (requires explicit flags)
{itemised list of optional changes not activated}
```

Ask for confirmation before proceeding if in interactive mode, unless `--report-only` was passed.

---

## Phase 3: Apply Upgrade Changes

Apply changes in this order. Only apply steps that are safe and in scope.

### Step 3.1: Update TargetFramework / TargetFrameworks

**Safe mechanical change — always apply (unless `--report-only`).**

For each `.csproj` and `.fsproj`:

1. If `TargetFramework` is set in the project file:
   - Replace with the target TFM.
   - Exception: preserve `netstandard2.0` / `netstandard2.1` targets by default unless `--allow-breaking-changes` is passed.

2. If `TargetFrameworks` (multi-target) is set:
   - Replace the non-netstandard TFM only.
   - Preserve all `netstandard*` targets.
   - Example: `net8.0;netstandard2.0` → `net10.0;netstandard2.0`

3. If `TargetFramework` is defined in `Directory.Build.props`:
   - Update there instead. Note this in the report.
   - Do not also update individual project files unless they override it.

### Step 3.2: Update global.json

**Safe mechanical change — always apply (unless `--report-only`).**

When a `global.json` exists, update the SDK version to match the target framework if version-specific guidance specifies the expected SDK. For `net10.0`, the expected SDK is `10.0.100` with `rollForward: latestMinor`.

If no version-specific guidance exists for the target, note that `global.json` should be reviewed manually and leave it unchanged.

### Step 3.3: Update Package References (requires `--allow-packages`)

Only when `--allow-packages` is passed:

- For packages with a known major-version alignment to the target framework (e.g., `Microsoft.Extensions.*`, `Microsoft.AspNetCore.*`, `Microsoft.EntityFrameworkCore.*`), suggest aligned versions.
- Do NOT automatically update risky packages. Flag each one for manual review.
- Do NOT update packages where the appropriate target version is unknown.
- Prefer updating `PackageVersion` entries in `Directory.Packages.props` over inline `Version` attributes when CPM is active.

### Step 3.4: Central Package Management Migration (requires `--allow-cpm`)

Only when `--allow-cpm` is passed AND `Directory.Packages.props` does not already exist:

1. Create `Directory.Packages.props` at repo root.
2. Move all `Version` attributes from `PackageReference` entries to `PackageVersion` entries in the new file.
3. Remove `Version` attributes from `PackageReference` entries in `.csproj` files.
4. Add `<ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>` to `Directory.Build.props` (or create it).

### Step 3.5: Directory.Build.props Creation/Refactor (requires `--allow-dbprops`)

Only when `--allow-dbprops` is passed:

- If `Directory.Build.props` is absent and common properties are repeated across projects:
  - Create `Directory.Build.props` with common `TargetFramework`, `Nullable`, `ImplicitUsings`, `TreatWarningsAsErrors`.
  - Remove those properties from individual project files.
- If `Directory.Build.props` exists but lacks the target framework property, recommend adding it (but only update if explicitly requested).

### Step 3.6: .slnx Migration (requires `--allow-slnx`)

Only when `--allow-slnx` is passed AND no `.slnx` exists:

- Generate a `.slnx` file equivalent to the existing `.sln`.
- Do NOT remove the `.sln` unless explicitly requested with a separate confirmation.
- Note: `.slnx` is the recommended modern solution format.

---

## Phase 4: Target-Version Specific Guidance

After mechanical changes, apply target-version guidance if available.

**Load the version guidance file:**
Use the **Read** tool to read:
`{{SKILL_DIR}}/../../references/version-upgrade/version-guidance/{target-framework}.md`

If Read fails, use the Bash fallback to locate the file:
```bash
find "$HOME/.claude/plugins" -name "{target-framework}.md" -path "*/version-guidance/*" 2>/dev/null | head -1
```
Then Read from the returned path.

- If the file loads successfully: apply its recommendations where in scope.
- If the file cannot be loaded (does NOT exist):
  - State explicitly: "No version-specific guidance exists for `{target-framework}`. Only safe mechanical upgrade changes have been applied."
  - Do not make speculative modernisation recommendations.
  - Do not recommend version-specific packages or patterns.

### Web API Modernisation (if version guidance recommends it)

For Web APIs, when version guidance recommends OpenAPI modernisation:

- Flag `Swashbuckle.AspNetCore` as a modernisation candidate.
- Recommend evaluating Scalar for OpenAPI UI.
- Do NOT automatically replace Swashbuckle with Scalar.
- Note migration considerations: Scalar uses `app.MapOpenApi()` (built-in .NET OpenAPI) vs Swashbuckle's generator.
- Require explicit `--allow-breaking-changes` and user confirmation before any OpenAPI tooling replacement.

### Azure Functions Modernisation (if version guidance recommends it)

For Azure Functions detected as **in-process model**:

- Flag as HIGH RISK modernisation candidate.
- Note that the in-process model is not supported in .NET 10+; isolated worker model is required.
- Provide a summary of in-process vs isolated worker differences:
  - `[FunctionName]` → `[Function]`
  - `FunctionsStartup` → `HostBuilder`
  - `IFunctionsHostBuilder` → `IServiceCollection` directly
  - Package changes: `Microsoft.NET.Sdk.Functions` → `Microsoft.Azure.Functions.Worker` + extensions
- Do NOT automatically migrate the execution model. Require explicit `--allow-breaking-changes` and user confirmation.

### GitLab CI Updates

When CI findings exist:

- Recommend updating Docker image tags for build/runtime stages to match the target framework.
- Recommend updating `DOTNET_VERSION` / `SDK_VERSION` variables.
- Only apply these changes when `--allow-packages` or if no risk is involved (e.g., variable-only changes).
- Do NOT rewrite CI structure. Preserve existing stage/job organisation.

**When `trigent1/pipeline-templates` is detected via `include: project:`:**

- Flag that the SDK version default is **owned by the shared template**, not this service repo.
- Updating a local image tag or variable will have no effect unless the service overrides the template default via `inputs:`.
- Report the template `ref:` being used (branch/tag). If it is `main` or unversioned, the service tracks the latest template, which may or may not support the target .NET version.
- Manual follow-up required: verify that the pipeline template version in use supports the target SDK, or add a service-level `inputs:` override:

```yaml
include:
  - project: trigent1/pipeline-templates
    ref: main
    file: /path/to/template.yml
    inputs:
      dotnet_version: "10.0"   # override template default
```

- Do NOT modify the `include:` block automatically. Always report findings and let the engineer decide.

---

## Phase 5: Validation

Run when tools are available. Prefer solution-level commands over individual projects.

```bash
dotnet --info
dotnet restore {solution-file}
dotnet build {solution-file}
dotnet test {solution-file}   # only when --run-tests is passed
```

**Solution file selection priority:**
1. `.slnx` if it exists (or was just created)
2. `.sln` if a single one exists
3. If multiple `.sln` exist, identify them all and ask the user to confirm which to use

**On build or restore failure:**
- Do NOT hide the failure.
- Report the full error output.
- Propose targeted fixes only for errors directly related to the TFM upgrade.
- Do NOT attempt to fix unrelated pre-existing build errors.

---

## Phase 6: Generate Upgrade Report

Always produce the following report at the end, regardless of `--report-only` mode.

```markdown
# .NET Upgrade Report

**Date:** {date}
**Repo:** {path}
**Current Framework(s):** {list}
**Target Framework:** {target-framework}
**Version Guidance Available:** yes/no
**Mode:** report-only | upgrade applied

---

## Summary of Changes

### Files Modified
{list each file and what changed}

### SDK Changes
{global.json before/after}

### Package Management
{CPM status, any package changes}

### Package Changes
{packages updated, flagged, or skipped — with reasons}

---

## Build Result
{dotnet build output summary or "not run"}

## Test Result
{dotnet test output summary or "not run" or "skipped (--run-tests not passed)"}

---

## Risks

### HIGH
{list}

### MEDIUM
{list}

### LOW
{list}

---

## Manual Follow-Up Items

- [ ] {item}

---

## GitLab CI Follow-Up Items

- [ ] {item}

---

## Modernisation Opportunities (Not Applied)

{list with reasons why not auto-applied}

---

## GitLab MR Description

{MR description ready to paste — see references/mr-template.md}
```

---

## Safety Rules

**Never:**
- Delete projects or solution files
- Remove package references unless a build confirms they are truly unused
- Remove `.sln` unless explicitly asked with confirmation
- Change authentication or security behaviour
- Auto-migrate Azure Functions execution model (in-process → isolated worker)
- Auto-replace Swashbuckle with Scalar
- Hide build failures or suppress errors
- Make speculative recommendations when no version-specific guidance exists

**Extra caution required for these packages** — flag each one, do not silently upgrade:
- Entity Framework Core (`Microsoft.EntityFrameworkCore.*`)
- Npgsql and Npgsql EF Core provider
- `Microsoft.Extensions.*` (major version alignment with runtime)
- `Microsoft.AspNetCore.*` (ships with runtime, do not pin separately)
- Azure Functions worker packages (`Microsoft.Azure.Functions.Worker.*`)
- `Microsoft.NET.Sdk.Functions` (in-process — requires careful versioning)
- `Newtonsoft.Json` vs `System.Text.Json` (different serialisation behaviour)
- `OpenTelemetry.*` (breaking changes between major versions)
- `MassTransit.*` (major version upgrades are breaking)
- `RabbitMQ.Client` (v7+ has breaking changes)
- `Serilog.*` (sink compatibility)
- `Swashbuckle.AspNetCore` (OpenAPI UI replacement candidate)
- `NSwag.*` (code generation — changes affect generated clients)
- `Scalar.*` (if already present — may conflict with Swashbuckle)

---

## References

Skill references are in the `references/version-upgrade/` directory of the dotnet plugin. To locate it, run:
```bash
find ~/.claude/plugins -type d -name "version-upgrade" -path "*/dotnet/references/*" 2>/dev/null | head -1
```
Files available:

| File | Purpose |
|------|---------|
| `dotnet-upgrade-policy.md` | Team upgrade policy and LTS preferences |
| `approved-package-versions.md` | Approved package versions template |
| `risky-packages.md` | Packages requiring manual care |
| `common-breaking-changes.md` | Checklist of common breaking-change areas |
| `mr-template.md` | GitLab MR description template |
| `version-guidance/net8.0.md` | net8.0-specific guidance |
| `version-guidance/net10.0.md` | net10.0-specific guidance |
| `version-guidance/future-lts-template.md` | Template for future LTS guidance files |

Scripts are in the `scripts/` directory of the dotnet plugin. To locate it, run:
```bash
find ~/.claude/plugins -type d -name "scripts" -path "*/dotnet/*" 2>/dev/null | head -1
```
Files available:

| Script | Purpose |
|--------|---------|
| `scan-dotnet-repo.sh` | Bash repo scanner — outputs JSON |
| `scan-dotnet-repo.ps1` | PowerShell repo scanner — outputs JSON |
| `update-target-framework.py` | Update TFM in project files |
| `analyze-packages.py` | Analyse package risks |
| `generate-upgrade-report.py` | Generate markdown upgrade report |

Standards references in the `standards` plugin:
- `references/technical-guidance/dotnet.md`
- `references/technical-guidance/application-profiles/dotnet-webapi-profile.md`
- `references/technical-guidance/application-profiles/dotnet-webapi-v10-profile.md`
- `references/technical-guidance/application-profiles/dotnet-function-app-profile.md`
- `references/technical-guidance/application-profiles/dotnet-function-v10-profile.md`
- `references/technical-guidance/application-profiles/dotnet-mixed-solution-profile.md`
