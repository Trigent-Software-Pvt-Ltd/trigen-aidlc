---
name: view
description: "View which Trigent coding and architectural standards apply to a repository, or browse the contents of a specific standard. Use to understand what conventions apply before starting work."
argument-hint: "[path|standard] [profile] (optional)"
allowed-tools: [Read, Glob, Grep, Bash, Task, AskUserQuestion]
---

# Trigent Standards — View

View which standards apply to a repository, or browse the detailed contents of a specific standard.

## Usage

### Repo Overview
- `/standards:view` — show what applies to the current working directory
- `/standards:view C:\trigent\repos\user-service` — show what applies to a specific repo

### Standard Detail
- `/standards:view global` — detailed summary of global standards
- `/standards:view dotnet` — detailed summary of .NET standards
- `/standards:view dotnet webapi-v10` — detailed summary of a specific application profile
- `/standards:view rails` — detailed summary of Rails standards
- `/standards:view iac` — detailed summary of IaC standards
- `/standards:view vue` — detailed summary of Vue standards

### Multi-Standard Detail
- `/standards:view global dotnet` — detailed summary of both standards

## Argument Handling

**Valid standard names:** `global`, `dotnet`, `rails`, `iac`, `vue`
**Valid .NET profiles:** `framework-mvc`, `webapi`, `function-app`, `webapi-v10`, `function-v10`, `mixed-solution`

Parse `$ARGUMENTS`:
1. If first argument matches a valid standard name → Standard Detail mode (Mode 2/3)
   - Remaining arguments: additional standard names or a profile for the first standard
   - Invalid names: respond with available options
2. If first argument is a filesystem path that exists → Repo Overview mode (Mode 1) for that path
3. If no arguments → Repo Overview mode (Mode 1) for current working directory
4. Otherwise → show usage help

---

## Mode 1: Repo Overview

### Step 1: Resolve Repo and Detect Standards

Read the shared detection logic file using the Read tool:
`${CLAUDE_PLUGIN_ROOT}/references/detection-logic.md`

Use the detection logic to resolve the repo and detect which standards apply.

Present the detection:
> Standards Profile: **[repo-name]**
> Detected: **[project type]**, **[profile or "none"]** (**brownfield** / **greenfield**)

### Step 2: Scan for Existing Patterns (brownfield only)

If the repo has existing code, scan for current patterns to populate the "Repo Uses" column.

**For .NET repos, scan for:**

| Concern | Scan approach |
|---------|---------------|
| DI Container | Grep for `SimpleInjector`, `IServiceCollection`, `ContainerConfiguration` class signature |
| Mapping Library | Grep for `AutoMapper`, `Mapster`, manual `Map()` method patterns |
| Testing Framework | Check test `*.csproj` for `xunit`, `nunit`, `mstest` package references |
| Mocking Library | Check test `*.csproj` for `NSubstitute`, `Moq`, `FakeItEasy` package references |
| Assertions | Check test `*.csproj` for `FluentAssertions`, `Shouldly` package references |
| HTTP Client | Grep for `Refit`, `RestEase`, typed `HttpClient` patterns |

**For Rails repos, scan for:**

| Concern | Scan approach |
|---------|---------------|
| Testing Framework | Check Gemfile for `rspec-rails`, `minitest` |
| API Pattern | Check for `graphql` gem, serializer gems |
| Background Jobs | Check Gemfile for `sidekiq`, `good_job`, `delayed_job` |

**For Vue repos, scan for:**

| Concern | Scan approach |
|---------|---------------|
| State Management | Check package.json for `pinia`, `vuex` |
| Router | Check package.json for `vue-router` |
| Testing Framework | Check package.json for `vitest`, `jest`, `cypress` |
| Component Library | Check package.json for `primevue`, `vuetify`, `element-plus` |

Skip this step for greenfield repos.

### Step 3: Present Overview

**For brownfield repos, present two tables:**

**Table 1: Applicable Standards**

| Standard | Scope | View Detail | Load into Context |
|----------|-------|-------------|-------------------|
| [standard name] | [brief scope description] | [view command] | [load command] |

**Table 2: Repo vs Standard Comparison**

| Concern | Org Standard | Repo Uses |
|---------|-------------|-----------|
| [concern] | [what standard says] | [what repo uses] |

**For greenfield repos, present Table 1 only** (no existing patterns to compare).

**Footer:**

```
Ownership: [Standard] — [Owner] | ...

/standards:load — load all applicable standards into context
/standards:view [standard] — detailed summary of a specific standard
/standards:audit — audit this repo for conformance
```

---

## Mode 2/3: Standard Detail

### Step 1: Resolve Which Standards to Display

Map arguments to reference files:

| Argument | File to read |
|----------|-------------|
| `global` | `${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/global.md` |
| `dotnet` | `${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/dotnet.md` |
| `rails` | `${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/rails.md` |
| `iac` | `${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/iac.md` |
| `vue` | `${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/vue.md` |
| `dotnet framework-mvc` | Above + `${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/application-profiles/dotnet-framework-mvc-profile.md` |
| `dotnet webapi` | Above + `${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/application-profiles/dotnet-webapi-profile.md` |
| `dotnet function-app` | Above + `${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/application-profiles/dotnet-function-app-profile.md` |
| `dotnet webapi-v10` | Above + `${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/application-profiles/dotnet-webapi-v10-profile.md` |
| `dotnet function-v10` | Above + `${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/application-profiles/dotnet-function-v10-profile.md` |
| `dotnet mixed-solution` | Above + `${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/application-profiles/dotnet-mixed-solution-profile.md` |

### Step 2: Read and Display

For each requested standard:
1. Read the reference file using the Read tool
2. Present the document content verbatim to the user — do not summarize, reformat, or omit sections
3. After the document content, append a footer:

```
---
To load this standard into context for Claude to apply during work: /standards:load [args]
```

The reference documents are already well-structured with clear sections, tables, and conventions. Displaying them directly preserves all detail and structure without lossy summarization.

For Mode 3 (multiple standards), present each document sequentially with a separator between them.

---

## Related Commands

- `/standards:load` — Load standards into context for use during work
- `/standards:audit` — Audit repo or changes for conformance to standards
- `/standards:list` — List available standards and example commands
