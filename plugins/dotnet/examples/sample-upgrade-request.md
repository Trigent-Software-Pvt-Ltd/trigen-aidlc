# Sample Upgrade Requests

Example prompts for the `/dotnet:version-upgrade` skill.

---

## Example 1: Safe Changes Only — .NET 8 to .NET 10

```
Upgrade this repo to net10.0. Make safe changes only — update TargetFramework and global.json.
Do not touch packages, CI, or Dockerfiles. Report everything else for manual review.
```

**What this triggers:**
- Scans repo structure and detects current TFMs
- Updates `TargetFramework`/`TargetFrameworks` in all `.csproj` files
- Updates `global.json` SDK version to `10.0.100`
- Flags all risky packages for manual review
- Flags GitLab CI and Dockerfile image versions for manual follow-up
- Generates upgrade report with full manual checklist
- Does NOT modify packages, CI, or Dockerfiles

**Flags used:** `--target-framework net10.0` (default: modify mode, no package changes)

---

## Example 2: Read-Only Assessment — Upgrade Readiness for net12.0

```
Assess this repo for net12.0 readiness but do not modify any files.
I want to understand what work is involved before we plan the upgrade.
```

**What this triggers:**
- Scans repo structure, frameworks, packages, CI, and Dockerfiles
- Reports current state and all items that would need to change
- Flags risky packages and their risk levels
- Notes that no version-specific guidance exists for `net12.0` (if true)
- Produces a full readiness report with effort estimates per area
- Does NOT modify any files

**Flags used:** `--target-framework net12.0 --report-only`

---

## Example 3: Upgrade TFMs, Review CI, Generate an MR

```
Upgrade target frameworks to net10.0, review and recommend GitLab CI image updates,
and generate an MR description I can paste into GitLab. Don't touch packages.
```

**What this triggers:**
- Scans repo fully
- Updates `TargetFramework`/`TargetFrameworks` in all project files
- Updates `global.json` SDK version
- Reviews `.gitlab-ci.yml` and Dockerfiles for image tag updates — recommends changes but only applies safe variable/image updates
- Runs `dotnet restore` and `dotnet build` to validate
- Generates complete upgrade report
- Generates a ready-to-paste GitLab MR description

**Flags used:** `--target-framework net10.0`

---

## Example 4: Full Upgrade with Package Updates

```
Upgrade this repo to net10.0. Update packages where safe to do so,
but flag anything risky for manual review. Run tests. Generate an MR.
```

**What this triggers:**
- Full scan and TFM upgrade
- Package analysis for all projects
- Updates non-risky packages to recommended versions for `net10.0`
- Flags HIGH and MEDIUM risk packages with recommended versions but does NOT auto-upgrade them
- Runs `dotnet restore`, `dotnet build`, and `dotnet test`
- Generates report with package summary and MR description

**Flags used:** `--target-framework net10.0 --allow-packages --run-tests`

---

## Example 5: Modernise Package Management During Upgrade

```
Upgrade to net10.0 and also migrate to Central Package Management.
I want Directory.Packages.props set up.
```

**What this triggers:**
- Full TFM upgrade
- Creates `Directory.Packages.props` with all current package versions
- Removes `Version` attributes from all `PackageReference` entries in `.csproj` files
- Adds `<ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>` to `Directory.Build.props`
- Validates build after CPM migration

**Flags used:** `--target-framework net10.0 --allow-cpm`

---

## Example 6: Conservative Upgrade of a Class Library

```
This repo has a class library that multi-targets net6.0 and netstandard2.0.
Upgrade the net6.0 target to net8.0 and preserve the netstandard2.0 target.
Do not touch any packages.
```

**What this triggers:**
- Detects multi-targeting: `net6.0;netstandard2.0`
- Updates only the `net6.0` portion: `net8.0;netstandard2.0`
- Preserves `netstandard2.0` target (default behaviour)
- Validates build for both targets

**Flags used:** `--target-framework net8.0 --preserve-netstandard`

---

## Example 7: Upgrade with Directory.Build.props Centralisation

```
Upgrade to net10.0. I also want to centralise the TargetFramework in
Directory.Build.props so individual projects don't each set it.
```

**What this triggers:**
- Scans for common properties across projects
- Creates or updates `Directory.Build.props` with `<TargetFramework>net10.0</TargetFramework>`
- Removes `<TargetFramework>` from individual `.csproj` files where it matches
- Validates build passes after centralisation

**Flags used:** `--target-framework net10.0 --allow-dbprops`

---

## Common Short-Form Prompts

These shorter prompts are also valid — the skill will ask for clarification on ambiguous flags:

```
Upgrade this repo to .NET 10
```

```
Migrate from .NET 8 to .NET 10, run tests, generate an MR description
```

```
Assess upgrade readiness for .NET 12 — report only, no changes
```

```
What would it take to upgrade to net10.0? Don't make any changes.
```

```
Update TargetFramework to net10.0 in all project files
```
