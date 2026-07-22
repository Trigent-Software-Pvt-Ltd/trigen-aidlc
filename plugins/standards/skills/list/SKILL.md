---
name: list
description: "Enumerate all available Trigent standards and application profiles with ready-to-run commands for viewing and loading each one. Use when you need a command reference or want to know exactly which standards and profiles exist."
allowed-tools: [Glob, Read]
---

# Trigent Standards — List

Discover and display all available standards and application profiles by scanning the reference files directory.

## Step 1: Discover Standards

Glob for project-type standard files:
`${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/*.md`

From the results, exclude any path containing `application-profiles` and any file named `detection-logic.md`. Each remaining file is a standard.

For each standard file, read the frontmatter (first 15 lines) to extract:
- `owner` field
- `scope` field
- Derive the **arg name** from the filename by stripping the `.md` extension (e.g. `dotnet.md` → `dotnet`)

## Step 2: Discover Application Profiles

Glob for application profile files:
`${CLAUDE_PLUGIN_ROOT}/references/technical-guidance/application-profiles/*.md`

From the results, exclude any file named `README.md`. Each remaining file is a profile.

For each profile file, read the frontmatter (first 15 lines) to extract:
- `owner` field
- `scope` field
- `version-range` field (if present)
- Derive the **parent standard** and **profile arg name** from the filename:
  - The filename format is `{parent}-{profile-name}-profile.md`
  - Strip the `-profile.md` suffix and the leading `{parent}-` prefix
  - Example: `dotnet-webapi-v10-profile.md` → parent `dotnet`, profile arg `webapi-v10`

## Step 3: Build and Display Output

Present the following output verbatim in structure, with the discovered data filled in.

### Standards

Build a table with one row per discovered standard:

| Standard | Scope | Owner | View | Load |
|----------|-------|-------|------|------|
| `{arg}` | `{scope}` | `{owner}` | `/standards:view {arg}` | `/standards:load {arg}` |

### Application Profiles

Build a table with one row per discovered profile, grouped by parent standard:

| Profile | Scope | Owner | View | Load |
|---------|-------|-------|------|------|
| `{parent} {profile-arg}` | `{scope}` | `{owner}` | `/standards:view {parent} {profile-arg}` | `/standards:load {parent} {profile-arg}` |

### Repo Commands

```
/standards:view                   — repo overview: detect which standards apply
/standards:load                   — auto-detect and load standards for current repo
/standards:audit                  — audit current repo for conformance
/standards:audit --staged         — audit staged changes only
/standards:audit --branch         — audit current branch changes
/standards:audit --mr <id>        — audit a GitLab MR
```
