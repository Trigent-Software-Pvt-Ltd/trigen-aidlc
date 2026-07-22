---
name: audit
description: "Audit a repository or set of changes for conformance to Trigent coding and architectural standards. Scans for DI, testing, mapping, project structure, and other conventions. Supports full repo audit and changes-only audit."
argument-hint: "[path] [--staged|--branch|--mr <id>]"
allowed-tools: [Read, Glob, Grep, Bash, Task, AskUserQuestion]
---

# Trigent Standards — Audit

Audit a repository or set of changes for conformance to Trigent organisational coding and architectural standards.

## Usage

### Full Repo Audit
- `/standards:audit` — audit the current working directory
- `/standards:audit C:\trigent\repos\user-service` — audit a specific repo

### Changes Audit
- `/standards:audit --staged` — audit staged changes only
- `/standards:audit --branch` — audit all changes on current branch vs base branch
- `/standards:audit --mr 57` — audit changes in a GitLab MR

## Argument Handling

Parse `$ARGUMENTS` for:
1. **Path** (optional) — a directory path to audit. If omitted, use current working directory.
2. **Mode flag** (optional):
   - `--staged` — scope to staged changes (`git diff --staged`)
   - `--branch` — scope to branch changes vs default branch (resolve with `git rev-parse --abbrev-ref origin/HEAD`, strip `origin/` prefix; fall back to `main` if unavailable)
   - `--mr <id>` — scope to MR changes (fetch diff from GitLab; resolve project from `git remote get-url origin`, or prompt user if not in a repo)
   - No flag — full repo audit

If both a path and a mode flag are provided, apply the mode to the specified repo.

Invalid arguments:
> Invalid argument: `[arg]`. Usage: `/standards:audit [path] [--staged|--branch|--mr <id>]`

---

## Shared Detection Logic

@${CLAUDE_PLUGIN_ROOT}/references/detection-logic.md

---

## Workflow

### Step 1: Resolve Repo, Detect Project Type, and Load Standards

Use the shared detection logic above to resolve the repo, detect project type, and load standards.

Verify the resolved path is a git repository. If not:
> This directory is not a git repository. Please provide a path to a repo or run this command from within one.

Load the matching standards files using the Read tool and present the detection:
> Detected **[project type]** project. Profile: **[profile or "none"]**.
> Auditing against: global + [project-type] + [profile].

### Step 2: Establish Baselines

Scan the existing codebase to discover current patterns. This establishes what the repo actually uses, independent of what standards say.

**For .NET repos, scan for:**

| Concern | Scan approach |
|---------|---------------|
| DI Container | Grep for `SimpleInjector`, `IServiceCollection`, `ContainerConfiguration` class signature |
| Mapping Library | Grep for `AutoMapper`, `Mapster`, manual `Map()` method patterns |
| Testing Framework | Check test `*.csproj` for `xunit`, `nunit`, `mstest` package references |
| Mocking Library | Check test `*.csproj` for `NSubstitute`, `Moq`, `FakeItEasy` package references |
| Assertions | Check test `*.csproj` for `FluentAssertions`, `Shouldly` package references |
| HTTP Client | Grep for `Refit`, `RestEase`, typed `HttpClient` patterns |
| CQRS | Grep for `IRequest`, `IRequestHandler`, MediatR usage |
| Project Structure | Check for `BusinessLogic`/`Shared` project, Controllers location |

**For Rails repos, scan for:**

| Concern | Scan approach |
|---------|---------------|
| Testing Framework | Check Gemfile for `rspec-rails`, `minitest` |
| API Pattern | Check for `graphql` gem, serializer gems (`jsonapi-serializer`, `active_model_serializers`) |
| Background Jobs | Check Gemfile for `sidekiq`, `good_job`, `delayed_job` |

**For IaC repos, scan for:**

| Concern | Scan approach |
|---------|---------------|
| Module Structure | Check directory layout against iac.md conventions |
| Naming | Sample resource names against iac.md naming patterns |

**For Vue repos, scan for:**

| Concern | Scan approach |
|---------|---------------|
| State Management | Check package.json for `pinia`, `vuex` |
| Router | Check package.json for `vue-router` |
| Testing Framework | Check package.json for `vitest`, `jest`, `cypress` |
| Component Library | Check package.json for `primevue`, `vuetify`, `element-plus` |

Use parallel sub-agents to scan different concern areas simultaneously for speed.

After scanning, present the discovered baselines:
> **Repo patterns discovered:**
> - DI: SimpleInjector
> - Mapping: Mapster
> - Testing: xUnit + Moq + FluentAssertions
> - HTTP: Refit

### Step 3: Determine Audit Scope

**Full repo audit (no mode flag):**
- Audit all concerns against both baselines
- No change scoping needed

**Changes audit (`--staged`, `--branch`, or `--mr`):**
- Determine the change set:
  - `--staged`: `git diff --staged --name-only`
  - `--branch`: resolve default branch via `git rev-parse --abbrev-ref origin/HEAD` (strip `origin/` prefix; fall back to `main`), then `git diff $(git merge-base HEAD <default-branch>)...HEAD --name-only`
  - `--mr <id>`: resolve GitLab project from `git remote get-url origin` (prompt user if unavailable), then fetch MR diff file list from GitLab API
- Identify which concerns are touched by the changed files:
  - Test files changed → audit testing, mocking, assertions concerns
  - Service/handler files changed → audit DI, mapping, CQRS concerns
  - Startup/configuration files changed → audit DI, project structure concerns
  - Infrastructure files changed → audit IaC concerns
- Only audit relevant concerns (skip untouched areas)

### Step 4: Run Audit

For each concern in scope, compare against baselines using this verdict logic:

**Brownfield repos (existing code detected):**

| Change matches repo pattern | Change matches org standard | Verdict | Note |
|---|---|---|---|
| Yes | Yes | Conformant | Ideal — repo and standard agree |
| Yes | No | Conformant | Repo pattern takes priority for brownfield |
| No | Yes | Deviation | Introduces inconsistency even though it matches standard |
| No | No | Deviation | Matches neither — likely unintentional |

**Greenfield repos (no existing patterns):**

| Change matches org standard | Verdict |
|---|---|
| Yes | Conformant |
| No | Deviation |

**Full repo audit** uses a simplified comparison — org standard vs repo actual, since there are no "changes" to evaluate:

| Repo matches org standard | Verdict | Note |
|---|---|---|
| Yes | Conformant | |
| No | Deviation | Note whether this is expected for brownfield |

### Step 5: Compile and Present Report

**Full repo audit report:**

```
Conformance Report: [repo-name]
Detected: [project type], [profile]

| Concern            | Org Standard        | Repo Actual         | Verdict     | Note                                    |
|--------------------|---------------------|---------------------|-------------|-----------------------------------------|
| [concern]          | [standard]          | [actual]            | [verdict]   | [context]                               |

Summary: X conformant, Y deviations
[Contextual note about brownfield/greenfield and whether deviations are expected]
```

**Changes audit report:**

```
Changes Audit: [repo-name] ([scope description])
Detected: [project type], [profile] (brownfield/greenfield)
Scope: N files changed, M concerns touched

| File                          | Concern  | Repo Pattern    | Org Standard     | Change Uses     | Verdict       | Note                              |
|-------------------------------|----------|-----------------|------------------|-----------------|---------------|-----------------------------------|
| [file]                        | [concern]| [repo pattern]  | [standard]       | [change]        | [verdict]     | [context]                         |

Summary: X conformant, Y deviations
[Recommendation based on findings]
```

---

## Sub-Agent Strategy

Use parallel sub-agents to scan concern areas simultaneously:

**Full repo audit:**
```
Main agent:
  1. Resolve repo, detect project type, load standards
  2. Spawn sub-agents:
     |- DI & project structure agent (Grep for container patterns, check folder layout)
     |- Testing & mocking agent (check test .csproj deps, scan test patterns)
     |- Mapping & HTTP client agent (Grep for mapper and client patterns)
     +- (additional agents per project type)
  3. Collect results, compile report
```

**Changes audit:**
```
Main agent:
  1. Resolve repo, detect project type, load standards
  2. Get change set (diff)
  3. Identify touched concerns
  4. Spawn sub-agents only for relevant concerns
  5. Collect results, compile report
```

---

## Related Commands

- `/standards:load` — Load standards into context for use during work
- `/standards:view` — View which standards apply to a repo, or browse standard details
- `/standards:list` — List available standards and example commands
