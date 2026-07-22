# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Claude Code plugin marketplace repository containing custom plugins that extend Claude Code's capabilities. Plugins provide skills (slash commands), hooks (session lifecycle events), and integrations with external tools.

## Architecture

### Plugin Structure

Each plugin lives in `plugins/<plugin-name>/` with this structure:

```
plugins/<plugin-name>/
  .claude-plugin/
    plugin.json          # Plugin manifest (name, description, skills path)
  skills/                # Optional: skill definitions
    <skill-name>/
      SKILL.md           # Skill definition with frontmatter
  hooks/                 # Optional: lifecycle hooks
    hooks.json
  references/            # Optional: shared docs (MUST be outside skills/)
```

### Marketplace Registry

`.claude-plugin/marketplace.json` at the repo root registers all plugins for distribution.

### Current Plugins

| Plugin | Purpose |
|--------|---------|
| `aidlc` | AI-DLC workflow: Project → Intent → Units → Bolts → Tasks |
| `issues` | Jira issue creation, GitLab MRs, release notes |
| `pair-programming` | Get second opinions from Grok/ChatGPT/Gemini |
| `epistemic-reasoning` | Enforces [FACT]/[INFERRED]/[ASSUMED] labeling |
| `ruby` | Rubocop linting with auto-fix |
| `context-init` | Project setup for non-developers with repo cloning and MCP config |
| `jira-improve` | Find and improve poorly written Jira issues using quality rubric |
| `behavioral-diff` | Detect logic inversions and behavioral changes in code diffs |
| `dotnet` | Trunk-based migration and .NET version upgrader for Trigent platform services |
| `standards` | Organisational coding and architectural standards for .NET, Rails, IaC, Vue, and global — with skills to view, load, and audit |
| `security` | Vulnerability scanning, secrets detection, SAST analysis |
| `gitlab-ci` | Pipeline standards: needs vs dependencies, stage-based gates |
| `consider` | Structured decision-making: options table with pros/cons, user interview, then planning |
| `flaky-test-triage` | Add flaky tests to the Flaky Tests Hub and triage them into TLINE Jira Bug tickets |
| `memory-doctor` | Audit and consolidate Claude Code auto-memory storage; reports token savings with keep/undo decision |
| `verify-claim` | On-demand deep verification of a claim against codebase, docs, and web. Returns a sourced verdict with rubric-based confidence via an opus investigator agent |
| `mr-review-companion` | Build a self-contained HTML review page for a GitLab MR: plain-language Summary (with rollback plan when the MR has migrations), Diff with individually collapsible files and cross-impact WHY prose, QA tab written in plain user-action language with checkbox checklists |

### Plugin Skills Reference

#### AIDLC (`/aidlc-*`)

| Command | Triggers | Description |
|---------|----------|-------------|
| `/aidlc-intent` | `create intent`, `intent document`, `new initiative`, `draft intent`, `aidlc plan` | Create Intent documentation in Confluence |
| `/aidlc-elaborate` | `decompose intent`, `break down intent`, `create units`, `mob elaboration` | Break Intent into Units via Mob Elaboration, propose Bolt groupings — units only, no task files |
| `/aidlc-design` | `domain design`, `logical design`, `create ADR`, `architecture decision`, `aidlc design` | Domain/Logical Design and Architecture Decision Records |
| `/aidlc-verify` | `verify docs`, `check readiness`, `transfer to jira`, `aidlc verify`, `confidence check` | Verify docs, refine Bolts, transfer to Jira: Intent → Unit → Bolt → Task |
| `/aidlc-bolt` | `bolt`, `implement bolt`, `start bolt`, `bolt implementation`, `new bolt` | Guide implementation of a bolt with TDD emphasis |
| `/aidlc-review` | `review AI-DLC docs`, `peer review MR`, `validate Jira story`, `aidlc review` | Peer-review documentation or MRs with confidence scoring |
| `/aidlc-progress` | `check progress`, `project status`, `how are we doing`, `project health`, `aidlc progress` | Generate confidence, risk, and progress dashboard for a Project |
| `/aidlc-help` | `aidlc help`, `what is aidlc`, `explain aidlc`, `planning help`, `how to plan` | Explain AI-DLC methodology and available skills |

#### Issues (`/issues:*`)

| Command | Description |
|---------|-------------|
| `/issues:create-jira-issue` | Create a Jira issue from current context or description |
| `/issues:create-mr` | Create a GitLab merge request for the current branch |
| `/issues:release-notes` | Generate release notes from commits, MRs, and Jira tickets |

#### Pair Programming (`/pair-programming:*`)

| Command | Triggers | Description |
|---------|----------|-------------|
| `/pair-programming:ai-pair-programmer` | `review with grok`, `review with gemini`, `review with chatgpt`, `pair program`, `second opinion`, `ai review` | Get second opinions from AI providers on code or architecture |

#### Ruby (`/ruby:*`)

| Command | Description |
|---------|-------------|
| `/ruby:rubocop` | Run Rubocop on specified file and fix violations |

#### Context Init (`/context-init:*`)

| Command | Triggers | Description |
|---------|----------|-------------|
| `/context-init:context-init` | `context init`, `project setup`, `workspace setup`, `initialize project` | Set up project context for non-developers |

#### Jira Improve (`/jira-improve:*`)

| Command | Triggers | Description |
|---------|----------|-------------|
| `/jira-improve:jira-improve` | `jira improve`, `fix jira`, `improve issues`, `jira quality`, `backlog cleanup`, `improve epic` | Find and improve poorly written Jira issues using quality rubric |

#### Behavioral Diff (`/behavioral-diff:*`)

| Command | Triggers | Description |
|---------|----------|-------------|
| `/behavioral-diff:review` | `review diff`, `check inversions`, `behavioral review`, `logic check` | Analyze code diffs for logic inversions, control flow changes, and behavioral alterations |

**Arguments:** `[--staged|--branch|--commit] [--strict|--normal] [file_path]`

Uses dual-analyzer architecture (control-flow-analyzer + business-logic-analyzer) with context-aware confidence scoring. Flags CRITICAL (boolean inversions), HIGH (comparison/null check changes), and MEDIUM (loop bounds, LINQ changes) issues.

#### GitLab CI (`/gitlab-ci:*`)

| Command | Triggers | Description |
|---------|----------|-------------|
| `/gitlab-ci:standards-list` | `list standards`, `available standards` | List available topics |
| `/gitlab-ci:standards-view` | `view standards`, `show standards` | Display standards summary |
| `/gitlab-ci:standards-load` | `load standards`, `standards context` | Load full standards into context |
| `/gitlab-ci:standards-audit` | `audit pipeline`, `standards audit` | Audit repo for violations |

**Auto-triggered skill:** `pipeline-edit` activates on phrases like `update pipeline`, `add job`, `new stage`, etc. Provides lightweight guidance from core rules.

#### Consider (`/consider:*`)

| Command | Triggers | Description |
|---------|----------|-------------|
| `/consider:consider` | `consider`, `weigh options`, `what approach`, `how should I`, `compare approaches`, `what are my options`, `best way to` | Present 2-4 viable approaches with pros/cons table, interview user for choice, then enter planning mode |

**Arguments:** `<problem or task description>`

Workflow: Explore codebase (if relevant) -> Generate options table with effort/risk -> AskUserQuestion for selection -> EnterPlanMode for chosen approach.

#### Flaky Test Triage (`/flaky-test-triage:*`)

| Command | Triggers | Description |
|---------|----------|-------------|
| `/flaky-test-triage:add-flaky-test-to-hub` | `add flaky test`, `record flaky test`, `flaky hub add` | Add a new entry to the CPOMS StudentSafe Flaky Tests Hub given a test file path/line and a CI job URL |
| `/flaky-test-triage:triage-flaky-tests` | `triage flaky`, `flaky tests`, `flaky test hub` | Triage untriaged rows from the Flaky Tests Hub Confluence page into TLINE Jira Bug tickets, then update the page with linked keys |

Reads each untriaged row, reads the spec file for context, drafts a ticket for user approval, creates it in TLINE via `acli` (with MCP fallback), then updates the hub page with Jira links.

#### Memory Doctor (`/memory-doctor:*`)

| Command | Triggers | Description |
|---------|----------|-------------|
| `/memory-doctor:memory-doctor` | `memory consolidation`, `MEMORY.md cleanup`, `auto-memory bloat`, `compact my memory`, `audit my memory`, `clean up MEMORY.md`, `trim memory files`, `doctor my memory` | Single-pass audit + consolidation of Claude Code auto-memory: shrinks the preloaded MEMORY.md index, trims memory file bodies, reports token savings, prompts a single keep/undo decision |

#### Standards (`/standards:*`)

| Command | Triggers | Description |
|---------|----------|-------------|
| `/standards:list` | `list standards`, `available standards` | List all standards, profiles, and example commands |
| `/standards:view` | `view standards`, `show standards`, `what standards apply` | View standards for a repo or browse a specific standard's full content |
| `/standards:load` | `load standards`, `standards context`, `standards-aware mode` | Load relevant standards into context for the current repo |
| `/standards:audit` | `audit standards`, `standards audit`, `conformance check` | Audit a repo or changeset for standards conformance |

`/standards:view` supports two modes: repo overview (detects and summarises what applies) and standard detail (displays full document verbatim). `/standards:load` auto-detects project type when invoked without arguments.

#### MR Review Companion (`/mr-review-companion:*`)

| Command | Triggers | Description |
|---------|----------|-------------|
| `/mr-review-companion:mr-review-companion` | `mr-review-companion`, `review companion`, `MR review HTML`, `review page for MR`, `companion doc for this MR`, `QA companion`, `explain this MR to my PM`, GitLab MR URL paired with "html"/"page"/"review"/"QA" | Build a single self-contained HTML for one GitLab MR. Three tabs: Summary (plain-language, non-technical; includes a rollback plan when the MR has migrations), Diff (per-file collapsible cards with cross-impact WHY prose), QA (the load-bearing differentiator: written in plain user-action language with no code identifiers, checkbox checklists, automated/partly automated/not automated/unknown coverage verdicts so QA only chases what the automated suite misses) |

**Arguments:** `<GitLab MR URL>`

Requires a full MR URL; bang-prefixed IIDs alone are rejected because they are ambiguous across groups and forks. Non-GitLab URLs (GitHub PRs, Bitbucket pull requests, Azure DevOps PRs) are politely refused. When run inside a clone of the MR's project, the QA tab derives richer coverage verdicts (automated / partly automated / not automated) from mirror-path and symbol-grep passes; otherwise it degrades gracefully using only the MR's own diff and marks unknown verdicts on files it could not assess.

#### Dotnet (`/dotnet:*`)

| Command | Triggers | Description |
|---------|----------|-------------|
| `/dotnet:trunk-help` | `dotnet help`, `trunk help`, `migration help` | Get guidance on trunk-based migration approach and available commands |
| `/dotnet:trunk-discover` | `trunk discover`, `assess migration`, `migration readiness` | Assess a .NET service's readiness for trunk-based migration |
| `/dotnet:trunk-plan` | `trunk plan`, `migration plan`, `plan trunk migration` | Create a phased trunk-based migration plan |
| `/dotnet:trunk-migrate` | `trunk migrate`, `run migration`, `start migration` | Execute a trunk-based migration phase |
| `/dotnet:trunk-validate` | `trunk validate`, `validate migration`, `check migration` | Validate migration state and branch health |
| `/dotnet:trunk-troubleshoot` | `trunk troubleshoot`, `fix migration`, `migration error` | Troubleshoot common trunk migration issues |
| `/dotnet:trunk-post-migrate` | `trunk post-migrate`, `post migration`, `migration cleanup` | Run post-migration cleanup and finalisation |
| `/dotnet:version-upgrade` | `upgrade .NET`, `migrate from .NET`, `update TargetFramework`, `modernize .NET repo`, `prepare .NET upgrade MR`, `assess .NET upgrade readiness` | Upgrade .NET repositories to a target framework version. Supports Web APIs, Azure Functions, class libraries, and test projects. Scans repo, applies safe mechanical changes, flags risks, and produces a GitLab MR-ready report. |

**Arguments for `/dotnet:version-upgrade`:** `[target-framework] [--report-only] [--allow-packages] [--allow-cpm] [--allow-dbprops] [--allow-slnx] [--allow-breaking-changes] [--run-tests]`

#### Epistemic Reasoning (hook-based)

No slash commands. Automatically activates via `SessionStart` hook to enforce `[FACT]`, `[INFERRED]`, `[ASSUMED]` labeling.

#### Verify Claim (`/verify-claim:*`)

| Command | Triggers | Description |
|---------|----------|-------------|
| `/verify-claim:verify-claim` | `verify claim`, `fact check`, `is this true`, `can you confirm`, `prove this`, `disprove this`, `source check` | Deeply verify a user-supplied claim against codebase, docs, and web. Returns a sourced verdict with rubric-based confidence (Verified / Likely true / Unclear / Likely false / Hallucination). |

**Arguments:** `<the claim to verify>`

Delegates to a read-only opus subagent (`claim-verifier`) that investigates the claim across Read/Grep/Glob/Bash/WebSearch/WebFetch, separates evidence from inference, hunts for counter-evidence, and returns a structured markdown verdict. Every evidence bullet must cite a source (file:line, URL, or command output).

## Skill File Format (SKILL.md)

```yaml
---
name: skill-name              # REQUIRED for slash command invocation
description: "What it does"   # REQUIRED, max 1024 chars
allowed-tools: [Tool1, Tool2] # Optional: tools allowed without permission
argument-hint: "<args>"       # Optional: hint shown in UI
---

# Skill Title

Instructions for Claude when skill is invoked...
```

**Critical rules:**
- `name:` field is required for the skill to appear as a slash command
- Name must match folder name, use lowercase/hyphens only
- Every direct child folder of `skills/` must contain a SKILL.md (non-skill folders like `references/` break the loader)

## Hook Format (hooks.json)

```json
{
  "hooks": {
    "SessionStart": [{ "hooks": [{ "type": "command", "command": "..." }] }],
    "Stop": [{ "hooks": [{ "type": "command", "command": "..." }] }]
  }
}
```

Use `${CLAUDE_PLUGIN_ROOT}` to reference files relative to the plugin directory.

## Template Variables

- `{{SKILL_DIR}}` - Path to the skill's folder (use in SKILL.md for relative paths)
- `${CLAUDE_PLUGIN_ROOT}` - Plugin root directory (use in hooks.json)

## Versioning

**IMPORTANT**: Bump the plugin version for every plugin update in **both** locations:

1. `plugins/<plugin-name>/.claude-plugin/plugin.json`
2. `.claude-plugin/marketplace.json` (root marketplace registry)

Use [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`
- **PATCH** (1.0.0 → 1.0.1): Bug fixes, typo corrections
- **MINOR** (1.0.1 → 1.1.0): New features, new skills, workflow changes
- **MAJOR** (1.1.0 → 2.0.0): Breaking changes, major restructuring

## Testing Changes

After modifying plugins:
1. Run `/plugin` in Claude Code to reload plugins
2. Type `/` to verify skills appear in autocomplete
3. Invoke the skill to test functionality
