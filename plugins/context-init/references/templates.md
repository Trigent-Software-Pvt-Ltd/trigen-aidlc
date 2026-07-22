# Context Init Templates & Reference

This file contains templates and guides used by the `/context-init` skill.

---

## CLAUDE.md Template

Generate the project CLAUDE.md by following this structure. Include or exclude sections based on what was configured during setup.

```markdown
# CLAUDE.md

This file configures Claude Code for the **[PROJECT_NAME]** project.

## Project Overview

[PROJECT_DESCRIPTION - 2-3 sentences describing the project]

### Key Stakeholders

[STAKEHOLDERS - list of key team members/stakeholders]

---

## Repositories

[Include this section if repositories were cloned]

| Repository | Description | Path |
|------------|-------------|------|
| [repo-name] | [description] | `./[folder]` |

[If no repositories: "No repositories cloned. Clone repos with `glab repo clone <path>`."]

---

## Confluence Integration

[Include this section if Confluence was configured]

### Space: [SPACE_KEY]

**Cloud ID:** `[CLOUD_ID]`

Access project documentation using the Atlassian MCP tools.

**Key Pages:**
- **[Page Title]** (ID: [page-id])

### How to Use

Search for content:
- Ask Claude: "Search Confluence for [topic]"
- Claude will use `mcp__plugin_atlassian_atlassian__search`

Get a specific page:
- Ask Claude: "Get the [Page Title] page from Confluence"
- Claude will use `mcp__plugin_atlassian_atlassian__getConfluencePage` with pageId: [page-id]

List all pages in space:
- Ask Claude: "List pages in the [SPACE_KEY] space"

[If Confluence not configured:]
Confluence integration not configured. To set up:
1. Ensure Atlassian MCP is configured in Claude Code settings
2. Run `/context-init` to add Confluence space

---

## Jira Integration

[Include this section if Jira was configured]

### Project: [PROJECT_KEY]

**Cloud ID:** `[CLOUD_ID]`

Track and manage work using the Atlassian MCP tools.

**Useful Queries:**

| What | How to Ask Claude |
|------|-------------------|
| All open issues | "Show open issues in [PROJECT_KEY]" |
| My assigned issues | "Show my assigned issues in [PROJECT_KEY]" |
| Recent updates | "Show issues updated this week in [PROJECT_KEY]" |
| Specific epic | "Show issues in epic [EPIC_KEY]" |

### How to Use

- Ask Claude: "Create a story in [PROJECT_KEY] for [description]"
- Ask Claude: "What's the status of [PROJECT_KEY]-123?"
- Ask Claude: "Add a comment to [PROJECT_KEY]-456"

[If Jira not configured:]
Jira integration not configured. To set up:
1. Ensure Atlassian MCP is configured in Claude Code settings
2. Run `/context-init` to add Jira project

---

## AI-DLC Planning Skills

Use these skills to plan and document your initiative:

| Skill | When to Use |
|-------|-------------|
| `/planning:aidlc-plan` | Create Level 1 Intent documentation |
| `/planning:aidlc-decompose` | Break Intent into User Stories and Units |
| `/planning:aidlc-design` | Domain design and Architecture Decision Records |
| `/planning:aidlc-verify` | Verify documentation completeness before Jira transfer |
| `/planning:aidlc-help` | Get help with the AI-DLC methodology |

### Recommended Workflow

1. **Start with Intent**: Run `/planning:aidlc-plan` to create your Level 1 Intent document
2. **Decompose**: Once Intent is approved, run `/planning:aidlc-decompose` to create Units and Stories
3. **Design**: Use `/planning:aidlc-design` for technical design (usually with engineering)
4. **Verify**: Run `/planning:aidlc-verify` before transferring to Jira

---

## Working with Claude

### Context Loading

When starting a new conversation, Claude will automatically read this file. You can also:
- Share specific files: "Look at the README in [repo-name]"
- Reference Confluence: "Search Confluence for the requirements doc"
- Query Jira: "Show me open stories in [PROJECT_KEY]"

### Best Practices

1. **Be specific**: "Create a story for user login" vs "Add login"
2. **Provide context**: Reference relevant docs or decisions
3. **Review before committing**: Always review generated content before creating Jira issues or Confluence pages

---

## Additional Context

[Include this section if additional context was provided]

[ADDITIONAL_CONTEXT - any extra information the user provided]
```

---

## Installation Guides

### Git Installation

#### macOS

**Option 1: Xcode Command Line Tools (Recommended)**
```bash
xcode-select --install
```

**Option 2: Homebrew**
```bash
brew install git
```

#### Windows

**Option 1: winget (Windows 10/11)**
```bash
winget install Git.Git
```

**Option 2: Download installer**
Download from: https://git-scm.com/download/win

#### Linux (Debian/Ubuntu)
```bash
sudo apt update
sudo apt install git
```

#### Linux (Fedora/RHEL)
```bash
sudo dnf install git
```

**Verify installation:**
```bash
git --version
```

---

### glab CLI Installation

glab is the official GitLab CLI tool for working with GitLab from the command line.

#### macOS (Homebrew)
```bash
brew install glab
```

#### Windows (winget)
```bash
winget install GLab.GLab
```

#### Linux (Homebrew)
```bash
brew install glab
```

#### Alternative: Download binary
Download from: https://gitlab.com/gitlab-org/cli/-/releases

**Authentication:**
```bash
# Interactive login (opens browser)
glab auth login

# Or with token
glab auth login --token <your-token>
```

**Verify:**
```bash
glab --version
glab auth status
```

---

### Atlassian MCP Configuration

The Atlassian MCP (Model Context Protocol) server allows Claude Code to interact with Confluence and Jira.

#### Step 1: Get Atlassian API Token

1. Go to: https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Give it a name (e.g., "Claude Code")
4. Copy the token (you won't see it again)

#### Step 2: Configure Claude Code

Add to your Claude Code settings (`.claude/settings.json` or via UI):

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": ["-y", "@anthropic/claude-code-atlassian-mcp"],
      "env": {
        "ATLASSIAN_SITE_URL": "https://your-site.atlassian.net",
        "ATLASSIAN_USER_EMAIL": "your-email@example.com",
        "ATLASSIAN_API_TOKEN": "your-api-token"
      }
    }
  }
}
```

Replace:
- `your-site` with your Atlassian site name
- `your-email@example.com` with your Atlassian email
- `your-api-token` with the token from Step 1

#### Step 3: Verify

Restart Claude Code, then test:
- Ask Claude: "List my Confluence spaces"
- Or: "Show my Jira projects"

If it works, you'll see your spaces/projects listed.

---

## .context-init.json Schema

This marker file tracks the context initialization state for future updates.

**Schema:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | Schema version (e.g., "1.0.0") |
| `created` | string | Yes | ISO timestamp when first created |
| `updated` | string | Yes | ISO timestamp of last update |
| `projectName` | string | Yes | Human-readable project name |
| `workspacePath` | string | Yes | Absolute path to workspace directory |
| `atlassianCloudId` | string | No | Atlassian Cloud ID for API calls |
| `repositories` | array | No | List of cloned repositories |
| `confluence` | object | No | Confluence configuration |
| `jira` | object | No | Jira configuration |
| `additionalContext` | string | No | Any extra context provided |

**Repository object:**
- `name` (string): Repository name
- `url` (string): Clone URL
- `description` (string): Repository description
- `defaultBranch` (string): Default branch name

**Confluence object:**
- `spaceKey` (string): Space key (e.g., "PROJ")
- `spaceId` (string): Numeric space ID
- `keyPages` (array): List of `{id, title}` objects

**Jira object:**
- `projectKey` (string): Project key (e.g., "PROJ")
- `projectId` (string): Numeric project ID
- `epics` (array): List of `{key, name}` objects

**Example:**
```json
{
  "version": "1.0.0",
  "created": "2024-01-15T10:30:00Z",
  "updated": "2024-01-15T10:30:00Z",
  "projectName": "Customer Portal Redesign",
  "workspacePath": "/Users/jane/Projects/customer-portal",
  "atlassianCloudId": "a]1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "repositories": [
    {
      "name": "portal-frontend",
      "url": "https://gitlab.com/acme/portal-frontend",
      "description": "React frontend for customer portal",
      "defaultBranch": "main"
    },
    {
      "name": "portal-api",
      "url": "https://gitlab.com/acme/portal-api",
      "description": "Backend API services",
      "defaultBranch": "main"
    }
  ],
  "confluence": {
    "spaceKey": "CP",
    "spaceId": "12345",
    "keyPages": [
      { "id": "67890", "title": "Project Overview" },
      { "id": "67891", "title": "Requirements Document" }
    ]
  },
  "jira": {
    "projectKey": "CP",
    "projectId": "10001",
    "epics": [
      { "key": "CP-100", "name": "Phase 1: Authentication" }
    ]
  }
}
```

**Note:** Consider adding `.context-init.json` to `.gitignore` as it contains user-specific paths.
