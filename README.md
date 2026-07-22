<!-- AI_SUGGESTION_MARKER_20260204100611 -->
# Trigent Claude Code Plugins

A collection of plugins that extend [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview)'s capabilities for development workflows, project planning, and AI-assisted coding. Claude Code is Anthropic's agentic coding tool that helps developers write, understand, and improve code through AI assistance. These plugins add specialized capabilities for structured planning, issue tracking, code quality, and more.

## Why Use These Plugins?

- **Structured Planning** — Create detailed project plans with AI-DLC methodology, from Intent documents through to Jira tickets
- **Issue Management** — Streamline Jira issue creation, GitLab MRs, and release notes generation
- **Code Quality** — Run Rubocop with intelligent auto-fixing and violation handling
- **Backlog Health** — Find and improve poorly written Jira issues using quality rubrics
- **Flaky Test Triage** — Record new flaky tests on the hub, then convert untriaged entries into structured TLINE Jira Bug tickets
- **Second Opinions** — Get feedback from multiple AI providers (Grok, ChatGPT, Gemini) on your code
- **Evidence-Based Reasoning** — Enforce `[FACT]`/`[INFERRED]`/`[ASSUMED]` labeling for rigorous analysis
- **Behavioral Diff** - Detect logic inversions and behavioral changes in code diffs
- **.NET Migration** — Automate trunk-based development migration for .NET API services with Kustomize and GitLab CI/CD
- **Security Scanning** — vulnerability scanning, secrets detection, SAST analysis checking against OWASP Top 10 and CWE Top 25
- **GitLab CI Standards** — Pipeline best practices for job ordering, `needs` vs `dependencies`, and stage-based gates

## Usage Examples

**Start a new project initiative:**
```
/aidlc-intent
Create an intent for adding user authentication with OAuth2 support
```

**Improve Jira backlog quality:**
```
/jira-improve:jira-improve PROJ
```
Analyzes issues in the PROJ project, scores them against a quality rubric, and helps rewrite poorly written tickets.

**Get a second opinion on your code:**
```
Review this authentication implementation with Grok and Gemini
```
The pair-programming skill auto-triggers and queries multiple AI providers.

**Create a GitLab MR for your current branch:**
```
/issues:create-mr
```

**Run Rubocop with intelligent fixes:**
```
/ruby:rubocop app/models/user.rb
```

**Check for behavioral logic inversions:**
```
/behavioral-diff:review
```

**Migrate a .NET service to trunk-based development:**
```
/dotnet:trunk-discover
/dotnet:trunk-plan
/dotnet:trunk-migrate
```

**Get GitLab CI pipeline standards:**
```
/gitlab-ci:standards-view
/gitlab-ci:standards-load job-ordering
/gitlab-ci:standards-audit
```
Or just ask about pipeline editing—the skill auto-triggers on phrases like "add a new job" or "update the pipeline".

## Quick Start

Add this marketplace to Claude Code:

```bash
claude plugin marketplace add Trigent-Software-Pvt-Ltd/trigen-aidlc
```

Or from within Claude Code:

```
/plugin marketplace add Trigent-Software-Pvt-Ltd/trigen-aidlc
```

Then install individual plugins:

```
/plugin install aidlc
/plugin install issues
```

## Available Plugins

### AIDLC (`/aidlc-*`)

AI-DLC (AI-Driven Development Lifecycle) workflow for structured project planning with human-in-the-loop validation.

| Command | Triggers | Description |
|---------|----------|-------------|
| `/aidlc-intent` | `create intent`, `intent document`, `new initiative`, `draft intent`, `aidlc plan` | Create Intent documentation in Confluence |
| `/aidlc-elaborate` | `decompose intent`, `break down intent`, `create units`, `mob elaboration` | Break Intent into Units via Mob Elaboration. Produces user-centric unit documents (problem statement, target users, scope, ACs, indicative tasks) and proposes Bolt groupings. |
| `/aidlc-design` | `domain design`, `logical design`, `create ADR`, `architecture decision`, `aidlc design` | Domain Design, Logical Design, ADRs, and Task Specification generation. Task Specs replace indicative tasks with fully-elaborated implementation-ready work items. |
| `/aidlc-verify` | `verify docs`, `check readiness`, `transfer to jira`, `confidence check` | Verify docs, refine Bolts, transfer to Jira (Project → Intent → Unit → Bolt → Task) |
| `/aidlc-bolt` | `bolt`, `implement bolt`, `start bolt`, `bolt implementation`, `new bolt` | Guide implementation of a Bolt with TDD emphasis |
| `/aidlc-help` | `aidlc help`, `what is aidlc`, `explain aidlc`, `planning help` | Explain AI-DLC methodology and available skills |

**Workflow:** Intent → Units (elaborate) → Design (domain model, ADRs, Task Specs) → Verify → Jira (Project → Intent → Unit → Bolt → Task) → Bolt Implementation

**Requires:** Atlassian MCP (Confluence + Jira)

---

### Issues (`/issues:*`)

Issue tracking and code review integrations.

| Command | Description |
|---------|-------------|
| `/issues:create-jira-issue` | Create a Jira issue from context or description |
| `/issues:create-mr` | Create a GitLab merge request for current branch |
| `/issues:release-notes` | Generate release notes from commits, MRs, and Jira tickets |

**Requires:** Atlassian MCP, GitLab MCP

---

### Flaky Test Triage (`/flaky-test-triage:*`)

Two-skill workflow around the [CPOMS StudentSafe Flaky Tests Hub](https://trigent1.atlassian.net/wiki/spaces/trigentepd/pages/2378039297/CPOMS+StudentSafe+Flaky+Tests+Hub): record new flaky tests when you find them, then triage them into TLINE Jira Bug tickets.

| Command | Description |
|---------|-------------|
| `/flaky-test-triage:add-flaky-test-to-hub` | Add a new entry to the Flaky Tests Hub given a test file path/line and a CI job URL |
| `/flaky-test-triage:triage-flaky-tests` | Triage untriaged rows from the Flaky Tests Hub into TLINE Bug tickets |

**Add a new flaky test to the hub:**
```
/flaky-test-triage:add-flaky-test-to-hub
```
Prompts for the test path:line (e.g. `spec/system/incidents/jsh_spec.rb:46`) and a CI job URL. Reads the spec file, fetches the CI failure output, composes a Notes cell, constructs the 11-column storage-format row, shows it for approval, then appends it to the Confluence page.

**Triage existing hub entries into Jira:**
```
/flaky-test-triage:triage-flaky-tests
```

**Requires:**
- `jira-cli` CLI tool — preferred for ticket creation (falls back to Atlassian MCP)
- `confluence-cli` CLI tool — preferred for Confluence read/update (falls back to Atlassian MCP)
- Atlassian MCP — fallback for both Jira and Confluence operations
- `JIRA_API_TOKEN` environment variable

#### Setting up `jira-cli`

**1. Install** (macOS):
```bash
brew tap ankitpokhrel/jira-cli
brew install jira-cli
```
Other platforms: [github.com/ankitpokhrel/jira-cli/wiki/Installation](https://github.com/ankitpokhrel/jira-cli/wiki/Installation)

**2. Set your Jira API token** in `~/.zshrc` (or `~/.bashrc`):
```bash
export JIRA_API_TOKEN="your-token-here"
```
Generate a token at [id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)

**3. Initialise** — when prompted, select the **TLINE** project and **TLINE board**:
```bash
jira init
```

#### Setting up `confluence-cli`

**1. Install** (macOS):
```bash
brew install confluence-cli
```
Or via npm: `npm install -g confluence-cli`

**2. Initialise** and answer the prompts as follows:
```
? Protocol: HTTPS (recommended)
? Confluence domain: https://trigent1.atlassian.net
? REST API path: /wiki/rest/api
? Authentication method: Basic (credentials)
? Email / Username: <your email>
? API token / password: <your Atlassian API token>
```
Generate a token at [id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)

Both CLI tools are optional — if either is missing the skill falls back to Atlassian MCP for that operation.

---

### Pair Programming (`/pair-programming:*`)

Get second opinions from multiple AI providers on your code, plans, or architecture decisions.

| Command | Triggers |
|---------|----------|
| `/pair-programming:ai-pair-programmer` | `review with grok`, `review with gemini`, `review with chatgpt`, `pair program`, `second opinion`, `ai review` |

```
"Review this implementation with Grok"
"Get ChatGPT's opinion on this approach"
"Ask all AIs to review my PR"
```

**Supported providers:** Grok (xAI), ChatGPT (OpenAI), Gemini (Google)

**Requires:** API keys for desired providers (`XAI_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`)

---

### Ruby (`/ruby:*`)

Run Rubocop on files with intelligent auto-fixing.

| Command | Description |
|---------|-------------|
| `/ruby:rubocop` | Run Rubocop on specified file and fix violations |

```
/ruby:rubocop app/models/user.rb
```

Automatically fixes violations where possible, adds disable comments only when the rule would be incorrect or dangerous.

**Requires:** Ruby project with Rubocop configured

---

### Context Init (`/context-init:*`)

Set up project context environments for non-developers (product owners, managers) with GitLab repos, CLAUDE.md generation, and Confluence/Jira integration.

| Command | Triggers |
|---------|----------|
| `/context-init:context-init` | `context init`, `project setup`, `workspace setup`, `initialize project`, `context setup` |

**Requires:** GitLab MCP, Atlassian MCP (optional)

---

### Jira Improve (`/jira-improve:*`)

Find and improve poorly written Jira issues using a quality rubric. Analyze a whole project, a single issue, or an Epic with all its children.

| Command | Triggers |
|---------|----------|
| `/jira-improve:jira-improve` | `jira improve`, `fix jira`, `improve issues`, `jira quality`, `backlog cleanup`, `improve epic` |

Features:
- Score issues against quality rubric (completeness, clarity, structure, context, testability)
- Gather context from codebase or user interviews
- Generate improved issue descriptions with previews
- Batch improve multiple issues

**Requires:** Atlassian MCP (or `acli` CLI tool)

---

### Behavioral Diff (`/behavioral-diff:*`)

Detect logic inversions, control flow changes, and semantic alterations that could break business logic. Uses a dual-analyzer architecture (control-flow + business-logic) with context-aware confidence scoring.

| Command | Triggers |
|---------|----------|
| `/behavioral-diff:review` | `review diff`, `check inversions`, `behavioral review`, `logic check` |

**Arguments:**

| Argument | Behavior |
|----------|----------|
| `--staged` (default) | Review staged changes |
| `--branch` | Review current branch vs main |
| `--commit` | Review last commit |
| `--strict` (default) | Maximum sensitivity, more false positives |
| `--normal` | Reduced sensitivity, fewer false positives |
| `file_path` | Limit review to specific file(s) |

**What Gets Flagged:**
- **CRITICAL:** Boolean inversions (`if (x)` → `if (!x)`), swapped if/else branches, equality inversions (`==` → `!=`)
- **HIGH:** Comparison operator changes, null check inversions, guard clause inversions, authorization/validation changes
- **MEDIUM:** Loop bound changes, LINQ semantic changes, ternary swaps, state machine modifications

```
/behavioral-diff:review --branch
/behavioral-diff:review src/Services/OrderService.cs
```

**Requires:** Git repository with staged changes or commits to analyze

---

### .NET (`/dotnet:*`)

Trunk-based development migration tools for .NET API services. Automates the migration from GitLab Flow to trunk-based development with Kustomize, shared pipeline templates, review apps, and production approval gates.

| Command | Triggers | Description |
|---------|----------|-------------|
| `/dotnet:trunk-help` | `trunk help`, `what is trunk migration`, `how to migrate` | Overview of the migration plugin and workflow |
| `/dotnet:trunk-discover` | `trunk discover`, `discover service`, `analyze repo` | Scan repo and generate migration config YAML |
| `/dotnet:trunk-plan` | `trunk plan`, `migration plan`, `show plan` | Preview migration execution plan |
| `/dotnet:trunk-migrate` | `trunk migrate`, `migrate to trunk`, `trunk-based migration` | Execute the full migration |
| `/dotnet:trunk-validate` | `trunk validate`, `validate migration`, `check migration` | Run 6 validation checks on the migration |
| `/dotnet:trunk-troubleshoot` | `trunk troubleshoot`, `trunk fix`, `migration issue` | Diagnose and fix common migration issues |
| `/dotnet:trunk-post-migrate` | `trunk post-migrate`, `post migration`, `cleanup migration` | Post-merge cleanup, monitoring, and hardening |

**Workflow:** Discover → Plan → Migrate → Validate → (MR merge) → Post-Migrate

**Requires:** .NET 8 project with GitLab CI/CD, `kustomize` CLI, `gitlab-ci` plugin (for pipeline standards)

---

### Security (`/security:*`)

Security audit tools for vulnerability scanning, secrets detection, and compliance checking.

| Command | Description |
|---------|-------------|
| `/security:scan` | Scan codebase for vulnerabilities using OWASP Top 10 and CWE Top 25 |
| `/security:secrets` | Detect hardcoded secrets, API keys, and credentials |

**Requires:** Git repository with code to scan

---

### GitLab CI (`/gitlab-ci:*`)

Pipeline standards, best practices, and guidelines for Trigent projects.

| Command | Triggers | Description |
|---------|----------|-------------|
| `/gitlab-ci:standards-list` | `list standards`, `available standards`, `what standards` | List available standards topics |
| `/gitlab-ci:standards-view` | `view standards`, `show standards` | Display standards summary to the user |
| `/gitlab-ci:standards-load` | `load standards`, `standards context` | Load full standards into Claude's context |
| `/gitlab-ci:standards-audit` | `audit pipeline`, `pipeline compliance` | Audit repo for standards violations |

**Auto-triggered skill:** The `pipeline-edit` skill automatically activates when you mention pipeline editing tasks:
- `update pipeline`, `modify pipeline`, `create pipeline`
- `update gitlab-ci`, `edit gitlab-ci`
- `add job`, `add stage`, `new job`, `new stage`

**Current standards topics:**
- `job-ordering` — Use stages for cross-stage ordering and `needs` only for intra-stage ordering

---

### AI SRE (`/ai-sre:*`)

AI-assisted Site Reliability Engineering tools for Trigent / PSW infrastructure across AWS ECS, Azure AKS, and GitLab CI/CD.

| Command | Triggers | Description |
|---------|----------|-------------|
| `/ai-sre:sre-incident` | `incident`, `outage`, `down`, `failing`, `sev1`, `sev2`, `declare incident` | Active incident triage — classify severity (SEV1–4), run parallel health checks, surface matching runbook, generate ranked hypotheses, coordinate response |
| `/ai-sre:sre-postmortem` | `postmortem`, `post-mortem`, `blameless review`, `root cause` | Blameless post-incident review — reconstruct timeline, apply 5-Whys, generate action items, publish to Confluence |
| `/ai-sre:sre-runbook` | `create runbook`, `write runbook`, `runbook for` | Generate structured operational runbooks and publish to MI space Confluence folder |
| `/ai-sre:sre-slo` | `slo`, `error budget`, `sli`, `burn rate` | Define SLOs, calculate error budgets, recommend burn rate alerts |
| `/ai-sre:sre-toil` | `toil`, `repetitive`, `automate`, `manual work` | Identify, quantify, and eliminate repetitive manual operational work |
| `/ai-sre:sre-refresh` | `refresh infra`, `sync infra docs` | Refresh plugin reference docs from live infrastructure |

**Supported stacks:** Emergency Management (Azure AKS), Training Platform (Azure AKS), PSW Canada (AWS ECS `ca-central-1`), Visitor Management, Volunteer Management, DismissalSafe, StaffSafe UK, SmartPass

**Requires:**
- `aws` CLI — PSW Canada triage (`brew install awscli`)
- `az` CLI — Azure AKS triage (`brew install azure-cli`)
- `kubectl` — AKS namespace health (`az aks install-cli`)
- `glab` — GitLab CI checks (`brew install glab`)
- Atlassian MCP — runbook lookup and creation (see MCP config below)

---

### Epistemic Reasoning (hook-based)

Enforces evidence-based reasoning by requiring `[FACT]`, `[INFERRED]`, and `[ASSUMED]` labels on all claims. Automatically enabled via `SessionStart` hook—no slash commands needed.

- `[FACT]` — Directly verified from code, files, or user statements
- `[INFERRED]` — Logical conclusion with reasoning shown
- `[ASSUMED]` — Cannot verify; must ask clarifying question before proceeding

## Installation

### Prerequisites

- **Claude Code CLI installed** - Download from [claude.ai/code](https://claude.ai/code)
- **Git CLI installed** - Required for plugin installation and Claude Desktop code mode
  - **Windows**: Download from [git-scm.com](https://git-scm.com/download/win)
  - **macOS**: Install via Homebrew (`brew install git`) or download from [git-scm.com](https://git-scm.com/download/mac)
  - **Linux**: Install via package manager (e.g., `sudo apt install git` or `sudo yum install git`)
  - Verify installation: Run `git --version` in terminal
- **Repository access** - Permission to access this GitHub repository

### Add the Marketplace

Choose the appropriate URL based on your Git configuration:

**Option 1: Shorthand** (recommended)

From command line:

```bash
claude plugin marketplace add Trigent-Software-Pvt-Ltd/trigen-aidlc
```

Or in Claude Code:

```
/plugin marketplace add Trigent-Software-Pvt-Ltd/trigen-aidlc
```

**Option 2: Full URL**

From command line:

```bash
claude plugin marketplace add https://github.com/Trigent-Software-Pvt-Ltd/trigen-aidlc.git
```

Or in Claude Code:

```
/plugin marketplace add https://github.com/Trigent-Software-Pvt-Ltd/trigen-aidlc.git
```

> **Note**: This is a private repository, so you may be prompted for GitHub credentials on first use. Ensure your GitHub account has access to the `Trigent-Software-Pvt-Ltd` organization.

### Install Plugins

```bash
# List available plugins
/plugin list

# Install specific plugins
/plugin install aidlc
/plugin install issues
/plugin install pair-programming
/plugin install ruby
/plugin install epistemic-reasoning
/plugin install context-init
/plugin install jira-improve
/plugin install behavioral-diff
/plugin install flaky-test-triage
/plugin install dotnet
/plugin install security
/plugin install gitlab-ci
/plugin install ai-sre

# Reload after changes
/plugin
```

### Configure MCP Servers

Some plugins require MCP servers. Add to your Claude Code settings:

**Atlassian MCP** (for aidlc, issues):
```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-atlassian"]
    }
  }
}
```

**GitLab MCP** (for issues):
```json
{
  "mcpServers": {
    "gitlab": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-gitlab"]
    }
  }
}
```

## Creating a New Plugin

### Plugin Structure

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json        # Plugin manifest
├── skills/                # Slash command definitions
│   └── <skill-name>/
│       └── SKILL.md
├── hooks/                 # Optional: lifecycle hooks
│   └── hooks.json
└── references/            # Optional: shared documentation
    └── shared.md
```

### Plugin Manifest (`plugin.json`)

```json
{
  "name": "my-plugin",
  "description": "What this plugin does",
  "version": "1.0.0",
  "author": { "name": "Your Name" },
  "license": "MIT",
  "keywords": ["relevant", "keywords"],
  "skills": "./skills/"
}
```

### Skill Definition (`SKILL.md`)

```yaml
---
name: my-skill
description: "Brief description for Claude to decide when to use this skill"
allowed-tools: [Read, Write, Bash]
argument-hint: "<file_path>"
---

# My Skill

Instructions for Claude when this skill is invoked...
```

**Important:**
- `name` must match the folder name (lowercase, hyphens only)
- `name` is required for slash command invocation
- Keep `description` under 1024 characters
- Every folder in `skills/` must contain a `SKILL.md`

### Register in Marketplace

Add your plugin to `.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./plugins/my-plugin",
      "description": "What it does",
      "version": "1.0.0",
      "author": { "name": "Your Name" }
    }
  ]
}
```

## Testing

Run the structural validation suite to catch plugin configuration errors before they reach production:

```bash
./tests/validate-plugins.sh
```

**Prerequisites:** [jq](https://jqlang.github.io/jq/) (`brew install jq` on macOS, `apt install jq` on Linux)

**What it validates:**

- **plugin.json** — exists, valid JSON, required fields, semver version, name matches directory
- **SKILL.md** — frontmatter present, `name`/`description` fields, kebab-case naming, name matches folder, description length
- **Marketplace consistency** — every plugin directory is registered, versions and names match across `marketplace.json` and `plugin.json`
- **hooks.json** — valid JSON structure with required `hooks` key

**When to run:** Before creating MRs, after adding or modifying plugins, and after version bumps.

## Troubleshooting

**Skill not appearing as slash command:**
- Ensure `name:` field exists in SKILL.md frontmatter
- Verify name matches folder name exactly
- Run `/plugin` to reload

**"Unknown skill" error:**
- Check for non-skill folders directly inside `skills/` (move them outside)
- Verify SKILL.md frontmatter syntax is valid YAML

**MCP tools not available:**
- Confirm MCP server is configured in Claude Code settings
- Check MCP server is running (`/mcp` to see status)

## License

MIT
