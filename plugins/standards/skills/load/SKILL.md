---
name: load
description: "Activate standards-aware mode. Detects project type and loads relevant Trigent coding and architectural standards when working in any repository. Use when starting work in a repo to ensure code follows organisational conventions."
argument-hint: "[dotnet|rails|iac|vue] [profile] (optional, auto-detects if omitted)"
allowed-tools: [Read, Glob, Grep, Bash, Task, AskUserQuestion]
---

# Trigent Standards — Load

Activate standards-aware mode for the current session. When invoked, this skill primes Claude with detection logic and behavioral rules so that the correct Trigent coding standards are loaded dynamically whenever work begins in a repository.

## Usage

- `/standards:load` — Auto-detect project type when work begins (recommended)
- `/standards:load dotnet` — Skip detection, load Global + .NET standards
- `/standards:load dotnet webapi-v10` — Skip detection, load Global + .NET + Web API v10 profile
- `/standards:load rails` — Skip detection, load Global + Rails standards
- `/standards:load iac` — Skip detection, load Global + IaC standards
- `/standards:load vue` — Skip detection, load Global + Vue standards

## Argument Handling

**Valid project types:** `dotnet`, `rails`, `iac`, `vue`

**Valid .NET profiles:** `framework-mvc`, `webapi`, `function-app`, `webapi-v10`, `function-v10`, `mixed-solution`

If `$ARGUMENTS` are provided:
1. Validate the project type against the valid list above
2. If a profile is also provided, validate it against the valid profiles for that project type
3. For any invalid argument, respond with:
   > Invalid argument: `[arg]`. Valid project types: `dotnet`, `rails`, `iac`, `vue`. For .NET profiles, see `/standards:list`.
4. Load the specified standards files directly (skip detection)
5. Present what was loaded and proceed

If no arguments are provided, load the detection instructions below for dynamic use throughout the session.

---

## Shared Detection Logic

Repo resolution, project type detection, .NET application profile detection, and standards file locations are shared with the `standards:audit` and `standards:view` skills.

@${CLAUDE_PLUGIN_ROOT}/references/detection-logic.md

---

## Behavioral Rules

These rules govern the **loading mechanics** — how standards get into context. Guidance precedence, conflict resolution, and brownfield/greenfield handling are documented in the reference files themselves (`application-profiles/README.md`, `global.md`, etc.). Once loaded into context, Claude applies these rules automatically — developers should not need to make decisions about when or how standards apply.

When this skill is active, follow these rules for the remainder of the session:

1. **Before loading standards**, resolve which repository to scan (see Repo Resolution above)
2. **Scan the resolved repo** for project-type markers using Glob and Grep
3. **For .NET repos**, also run Application Profile detection to identify the specific profile
4. **Load the matching standards files** using the Read tool — read global.md plus the detected project-type file plus the detected application profile (if any)
5. **Present a brief detection summary** to the user:
   > Detected **[.NET 10 Web API v10 / Rails / IaC / Vue / Other]** project.
   > Loaded: global.md + [project-type file] + [profile if applicable].
6. **If the work context shifts to a different repo** (user names a different path, references a different service's ticket, or switches working directory), repeat detection for the new repo
7. **Cache detection results** — if a repo was already detected in this session, reuse the result without re-scanning or re-confirming

---

## Pre-Load Mode (with arguments)

When arguments are provided, skip dynamic detection and load files directly.

### `/standards:load dotnet`

Always load:
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/global.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/dotnet.md

### `/standards:load dotnet framework-mvc`

Always load:
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/global.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/dotnet.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/application-profiles/dotnet-framework-mvc-profile.md

### `/standards:load dotnet webapi`

Always load:
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/global.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/dotnet.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/application-profiles/dotnet-webapi-profile.md

### `/standards:load dotnet function-app`

Always load:
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/global.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/dotnet.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/application-profiles/dotnet-function-app-profile.md

### `/standards:load dotnet webapi-v10`

Always load:
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/global.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/dotnet.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/application-profiles/dotnet-webapi-v10-profile.md

### `/standards:load dotnet function-v10`

Always load:
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/global.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/dotnet.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/application-profiles/dotnet-function-v10-profile.md

### `/standards:load dotnet mixed-solution`

Always load:
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/global.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/dotnet.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/application-profiles/dotnet-mixed-solution-profile.md

### `/standards:load rails`

Always load:
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/global.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/rails.md

### `/standards:load iac`

Always load:
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/global.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/iac.md

### `/standards:load vue`

Always load:
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/global.md
@${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/vue.md

---

## Related Commands

- `/standards:audit` — Audit repo or changes for conformance to standards
- `/standards:view` — View which standards apply to a repo, or browse standard details
- `/standards:list` — List available standards and example commands
