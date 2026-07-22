---
name: sentry-diagnose
description: Diagnose a Sentry issue, analyze root cause using the project's codebase, and recommend scripts with cascading diagnostic workflows. (Triggers - diagnose, sentry, recommend script, debug, issue, error, exception)
allowed-tools: [Bash, Read, Grep, Glob, Task, AskUserQuestion, mcp__sentry__get_issue_details, mcp__sentry__get_issue_tag_values, mcp__sentry__search_issue_events, mcp__atlassian__getConfluencePage]
argument-hint: "<sentry-issue-url>"
---

# Diagnose Sentry Issue

Given the Sentry issue URL: `$ARGUMENTS`

## Overview

This skill performs intelligent diagnosis of Sentry errors by:
1. Fetching and analyzing the Sentry issue
2. Determining the **target project** (CPOMS or StaffSafe) from the Sentry issue's project field
3. Fetching available scripts from the target project's GitLab repository
4. Exploring the codebase to understand root cause
5. Recommending a **diagnostic workflow** (logging scripts first, then destructive scripts) — or clearly stating when no script applies

## Target Project

The Sentry issue's **projectID** field (from `mcp__sentry__get_issue_details`) determines which GitLab repository to use for scripts and codebase analysis. Only load the relevant project — do not load both.

| Sentry Project ID | Project | GitLab Project Path (URL-encoded) |
|--------------------|---------|-----------------------------------|
| `152386` | CPOMS | `trigent1%2Ftrigent%2Fcpoms%2Fcpoms` |
| `1271707` | StaffSafe | `trigent1%2Ftrigent%2Fcpoms%2Fcpoms-scr` |

Use the matching GitLab project for all `glab` commands throughout the diagnosis.

## Important Context

**Scripts are workarounds, not fixes.** They resolve data issues caused by underlying bugs or defects, allowing customers to continue using the system while the root cause is investigated. If the root cause of an issue is unknown, recommend that the user investigates further - the script just unblocks the customer.

**Not every issue needs a script.** Some Sentry errors are code defects, configuration problems, or external service failures that no script can resolve. When this is the case, make it explicitly clear to the user — do not try to force-fit a script recommendation.

## Script Categories

There are two types of scripts:

| Type | Purpose | Examples |
|------|---------|----------|
| **Logging** | Output data only - useful for debugging or revealing internal IDs needed by other scripts | `log_*`, `find_*`, `print_*`, `show_*` |
| **Destructive** | Modify data (destroy, update, create) | `dedupe_*`, `destroy_*`, `fix_*`, `bulk_*` |

**Important**: Logging scripts often reveal IDs or state needed to run destructive scripts correctly. Always recommend the diagnostic workflow.

## Script Documentation

Scripts are maintained in the GitLab repository. The Confluence page provides additional context gathered from experience, including gotchas, tips, and known edge cases. Use GitLab as the primary source for available scripts, and consult Confluence for practical guidance on using them.

## Script Execution

Scripts are executed from within **Manage** (not the terminal). When recommending scripts, provide:
- Script name
- Customer identifier (subdomain from Sentry tags)
- Required arguments
- Whether to enable dry-run

---

## Prerequisites

**Note:** This skill checks for `glab` and `jq` when invoked. MCP servers (Sentry/Atlassian) will be validated when their tools are first called - if missing, you'll receive installation instructions.

This skill requires the following tools to be configured before use:

### 1. MCP Servers

Configure these MCP servers for Claude Code:

| Server | Purpose | Installation |
|--------|---------|--------------|
| **sentry** | Fetches Sentry issue details, stacktrace, tags, and event data | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` |
| **atlassian** | Fetches Confluence script documentation and gotchas | `claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/mcp` |

After installation, the MCP servers will prompt for authentication when first used. Follow the prompts to add your authentication credentials (auth tokens, OAuth, or API tokens).

### 2. glab CLI (GitLab CLI)

Required to fetch scripts and codebase files from GitLab repositories.

**Installation:**

- **macOS:** `brew install glab`
- **Windows:** `winget install --id GitLab.Glab` (or `scoop install glab` / `choco install glab`)
- **Linux:** See https://gitlab.com/gitlab-org/cli#installation

**Authentication:**

After installing, authenticate with GitLab:

```bash
glab auth login
```

Select `gitlab.com`, choose your preferred authentication method (browser or token), and follow the prompts.

**Verify access:**

```bash
glab api "projects/trigent1%2Ftrigent%2Fcpoms%2Fcpoms/repository/tree?path=app/services/scripts&per_page=1"
```

If this returns a JSON array, glab is configured correctly. If it returns a 403/404 error, ensure your GitLab account has access to the CPOMS repositories.

### 3. jq (JSON processor)

Required for parsing glab API responses.

**Installation:**

- **macOS:** `brew install jq`
- **Linux:** `apt install jq` (Debian/Ubuntu) or `yum install jq` (RHEL/CentOS)
- **Windows:** `choco install jq`

---

## Phase 0: Check Dependencies

Before starting diagnosis, verify that all required dependencies are available.

### Step 1: Check CLI Tools

Verify that `glab` (GitLab CLI) and `jq` (JSON processor) are available:

```bash
glab --version && jq --version
```

**If either tool is missing:**

1. Refer the user to the **Prerequisites** section above for installation instructions
2. Use `AskUserQuestion` to prompt them to install missing dependencies
3. Wait for confirmation before proceeding

**Do not proceed until both glab and jq are installed and glab is authenticated.**

### Step 2: MCP Server Errors

**Note:** MCP servers (Sentry and Atlassian) are checked implicitly when you first call their tools. If a tool call fails with an error about a missing server, guide the user to install it:

```bash
# For Sentry
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp

# For Atlassian
claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/mcp
```

After installation, retry the failed tool call. The server will prompt for authentication on first use.

---

## Phase 1: Gather Context (Run in Parallel)

### 1.1 Fetch Sentry Issue

Use `mcp__sentry__get_issue_details` with the provided URL to extract:
- **Error type**: The exception class (e.g., `RuntimeError`, `ActiveRecord::RecordNotUnique`)
- **Error message**: The full error description
- **Model name**: If the error involves a specific model (extract from message)
- **Tenant**: From the `subdomain` tag
- **Location**: The file and line where the error originated
- **Stacktrace**: Full call stack for code analysis

### 1.2 Assess Issue Scale

After fetching issue details, use `mcp__sentry__get_issue_tag_values` with `tagKey: subdomain` to understand how many tenants are affected.

- If **only one tenant** is affected: likely a customer-specific data or configuration issue — a script may resolve it.
- If **many tenants** are affected: likely a systemic code defect or external service issue — the user's customer can still be unblocked with a script if one exists, but **flag the scale prominently** and recommend root cause investigation.

Include the scale in the output summary (e.g., "This issue affects 1,730 schools — root cause investigation is strongly recommended").

### 1.3 Fetch Script Context from Confluence

Use `mcp__atlassian__getConfluencePage` to fetch additional script context:
- **cloudId**: `trigent1.atlassian.net`
- **pageId**: `258444595`
- **contentFormat**: `markdown`

This page provides team knowledge gathered from experience:
- Use cases and descriptions
- Script-specific gotchas and tips
- Known edge cases and warnings
- Cascading relationships (e.g., "run X first, then Y")

**Use this as supplementary context** when making recommendations. This information enhances your understanding but the GitLab repository is the authoritative source for available scripts.

### 1.4 List All Available Scripts

Fetch scripts from the **target project's** GitLab repository (determined in Phase 1.1). Use `per_page=100` and paginate if needed — CPOMS has 120+ scripts so requires at least 2 pages; StaffSafe has ~26 and fits in one.

**Important: Use `jq` to parse glab JSON output.** Do not pipe `glab` output to `python3 -c` — shell escaping of special characters (exclamation marks, equals signs, quotes) in inline python is unreliable and causes `SyntaxError`. Always use `jq` for filtering:

```bash
glab api 'projects/<GITLAB_PROJECT>/repository/tree?path=app/services/scripts&ref=main&per_page=100' | jq -r '.[] | select(.name | endswith(".rb")) | select(.name != "base.rb") | .name'
```

The script names are descriptive — use them to match against the error pattern (e.g., `dedupe_medical_conditions.rb` for duplicate medical condition errors).

---

## Phase 2: CPOMS Codebase Analysis

**This is critical for intelligent diagnosis.** Use the Explore agent to understand the error's root cause.

The codebase is on GitLab, not local. When launching the Explore agent, instruct it to fetch files from the **target project** using `glab`:

```bash
glab api 'projects/<GITLAB_PROJECT>/repository/files/<URL_ENCODED_PATH>/raw?ref=main'
```

Where `<GITLAB_PROJECT>` is the URL-encoded project path from the Target Project table, and `<URL_ENCODED_PATH>` has `/` replaced with `%2F` (e.g., `lib/import/xod_import.rb` becomes `lib%2Fimport%2Fxod_import.rb`).

Direct the Explore agent to investigate:

1. **The error location**: Read the file/method where the error was raised
2. **The data flow**: Trace how data gets to that point (especially for imports)
3. **The model involved**: Understand the model's relationships and constraints
4. **Known issues**: Search for related JIRA issues or TODOs in the codebase

Example exploration prompts:
- "Read lib/import/sync/importer.rb around line 1077 to understand why it raises on multiple instances"
- "Find how Sen records are created and what constraints exist"
- "Search for known issues with duplicate {model} records"

---

## Phase 3: Script Matching & Workflow

### 3.1 Match Scripts to Error

Based on the error analysis and the full GitLab script list:

1. **Identify the error pattern** from the Sentry issue
2. **Search the GitLab script list** by name for keywords related to the error (e.g., model name, error type, operation like `dedupe_`, `destroy_`, `fix_`)
3. **Consult the Confluence page** for additional context on matched scripts — gotchas, tips, and known edge cases
4. **Check for cascading relationships** — some scripts should be run before others (Confluence may document these)
5. **Note any logging scripts** that should be run first to gather information
6. **If no script matches** — proceed directly to Phase 4 using the "No Script Applies" template

### 3.2 Fetch Script Details

For each relevant script identified in 3.1, use `glab` to fetch the full source code from the **target project**:

```bash
glab api 'projects/<GITLAB_PROJECT>/repository/files/app%2Fservices%2Fscripts%2F<script_name>.rb/raw?ref=main'
```

**Script structure:** All scripts inherit from `Scripts::Base` (or `Scripts::DryRun` for dry-run support) and share a common pattern, but CPOMS and StaffSafe declare arguments differently:

**CPOMS scripts** use `ActiveModel::Attributes` — arguments are declared as class-level `attribute` statements:

```ruby
class Scripts::DestroyTransfers < Scripts::DryRun
  attribute :match_values, :array, default: ""
  attribute :other_establishment, :string, default: ""
  attribute :destroy_if_unpaired, :boolean, default: false

  def self.description
    <<-DESC
    Destroy transfer records
      match_values, Array: csv list of ulns or upns, required
      ...
      dry_run, Bool: Leave blank for false
    DESC
  end

  def run
    # script logic
  end
end
```

**StaffSafe scripts** use keyword arguments in `initialize`:

```ruby
class Scripts::BulkMergeStaff < Scripts::DryRun
  def initialize(matcher_attributes:, prioritise_base_role:, **args)
    super
    @matcher_attributes = matcher_attributes.empty? ? %w[...] : matcher_attributes.split(",").map(&:strip)
  end

  def self.description
    "Bulk merge staff based on chosen attributes"
  end

  def run
    # script logic
  end
end
```

From the source code, extract:
- **Description**: from `def self.description`
- **Options/arguments**: from `attribute` declarations (CPOMS) or `initialize` keyword arguments (StaffSafe) — these map to fields in Manage
- **Dry-run support**: inherits from `Scripts::DryRun` (check the superclass, not just the arguments)
- Any script-specific logic that affects recommendations (e.g., conditional behaviour, validation checks)

---

## Phase 4: Present Diagnostic Workflow

Structure the output based on whether scripts are applicable or not.

### Template A: Script Workflow Available

Use this when one or more scripts can help resolve or diagnose the customer's issue:

```markdown
## Issue Summary
- **Error**: <error message>
- **Tenant**: <subdomain>
- **Occurrences**: <count>
- **Scale**: <number of affected tenants — flag if widespread>
- **Location**: <file:line>

## Root Cause Analysis
<explanation based on codebase analysis>

If the root cause is **unknown or unclear**, state this explicitly and recommend investigation:
> The root cause of this issue is not yet determined. The recommended script will unblock the customer,
> but further investigation is needed to identify and fix the underlying bug.

## Diagnostic Workflow

### Step 1: Gather Information (Logging Scripts)
> Run these first in Manage to understand the current state and gather IDs if needed

| Field | Value |
|-------|-------|
| **Script** | `<logging_script_name>` |
| **Customer** | `<subdomain>` |
| **Purpose** | <what information it reveals> |
| **Arguments** | <any required arguments> |
| **Permitted** | Yes (2nd line) / No (liaise with 3rd line) |

### Step 2: Apply Fix (Destructive Scripts)
> Run in Manage after reviewing Step 1 output. Always dry-run first if supported.

| Field | Value |
|-------|-------|
| **Script** | `<destructive_script_name>` |
| **Customer** | `<subdomain>` |
| **Purpose** | <what it fixes> |
| **Dry Run** | `true` (run first to verify) |
| **Arguments** | <any required arguments> |
| **Permitted** | Yes (2nd line) / No (liaise with 3rd line) |

After verifying dry-run output, run again with Dry Run disabled.

### Gotchas & Tips
- <script-specific warnings from Confluence page>
- <tips from Confluence page>

### Follow-up Investigation
If root cause is unknown or issue is widespread:
- <suggested areas to investigate>
- <potential JIRA ticket to create>
```

### Template B: No Script Applies

Use this when the issue **cannot be resolved or diagnosed with any available script**. This must be stated clearly and unambiguously so the user does not waste time searching for a script that doesn't exist.

```markdown
## Issue Summary
- **Error**: <error message>
- **Tenant**: <subdomain>
- **Occurrences**: <count>
- **Scale**: <number of affected tenants — flag if widespread>
- **Location**: <file:line>

## Root Cause Analysis
<explanation based on codebase analysis>

## No Applicable Script

**There is no script that can resolve this issue.** This is because:
- <clear reason, e.g. "the error is a code defect in the XOD import pipeline — no customer data is corrupted or duplicated">
- <why scripts don't help, e.g. "the failure occurs before any data is written, so there is nothing to clean up">

## Recommended Actions

### For the customer (<subdomain>)
- <immediate workaround if any, e.g. "verify MIS integration is active", "retry sync", etc.>
- <escalation path, e.g. "escalate to 3rd line / engineering">

### For the root cause
- <what code fix is needed>
- <suggested JIRA ticket(s) to create>
- <areas to investigate>
```

---

## Important Notes

1. **Always recommend dry-run first** for destructive scripts (unless the script doesn't support it)
2. **Never search for customer by name** in Manage - use LA/DfE or exact CPOMS URL
3. **If no matching script exists**, use Template B — be explicit that no script applies and explain why
4. **If multiple scripts could apply**, list all options with explanations
5. **Include the tenant name** from Sentry tags so the engineer can target the right school
6. **For cascading workflows**, clearly indicate the dependency between scripts
7. **Consult the Confluence page** for gotchas and practical tips when recommending scripts
8. **Scripts are workarounds** — always consider whether the root cause needs investigation
9. **Script permissions** — note in recommendations whether scripts are documented on Confluence (commonly used) or not (may require additional approval)
10. **Scale matters** — always report how many tenants are affected, and flag when root cause investigation is needed
