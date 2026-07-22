---
name: context-init
description: Set up a project context environment for non-developers (product owners, managers). Creates a workspace with cloned repos, generates CLAUDE.md, and configures Confluence/Jira integration. (Triggers - context init, project setup, workspace setup, initialize project, context setup)
allowed-tools: [Bash, Read, mcp__plugin_atlassian_atlassian__search, mcp__plugin_atlassian_atlassian__getConfluenceSpaces, mcp__plugin_atlassian_atlassian__getConfluencePage, mcp__plugin_atlassian_atlassian__getVisibleJiraProjects, mcp__plugin_atlassian_atlassian__getAccessibleAtlassianResources, AskUserQuestion]
argument-hint: "[project-name or folder-path]"
---

# Context Initialization Skill

You are helping a **non-developer** (product owner, manager, or similar role) set up a project context environment. Your goal is to create a workspace where they can effectively use Claude Code for planning, documentation, and project management tasks.

## Interaction Style

- **AI-Drives-Conversation**: You propose actions, user approves, then you execute
- **Phase gates**: Get explicit user approval before major operations
- **Graceful degradation**: If tools are missing, offer alternatives or skip gracefully
- **Non-technical language**: Avoid jargon, explain what each step accomplishes

## Workflow Phases

### Phase 1: Prerequisites Check

Check for required tools. Present results in a summary table:

| Tool | Status | Purpose |
|------|--------|---------|
| Git | ✅/❌ | Version control (required) |
| glab CLI | ✅/❌ | GitLab authentication & cloning (strongly recommended) |
| Atlassian MCP | ✅/❌ | Confluence & Jira access |

**Why glab is strongly recommended:** The glab CLI handles GitLab authentication automatically via browser login. This eliminates the need for SSH key setup, which is a significant barrier for non-technical users.

**Check commands:**
```bash
# Git
git --version

# glab CLI
glab --version

# glab authentication
glab auth status
```

**For Atlassian MCP**, attempt to call `mcp__plugin_atlassian_atlassian__getAccessibleAtlassianResources`. If it fails, MCP is not configured.

**If tools are missing**, consult `{{SKILL_DIR}}/../references/templates.md` for installation guides and present platform-appropriate instructions.

**Flow:**
- Git missing → Show install guide, cannot proceed without Git
- glab missing → Strongly recommend installation: (1) Install glab (recommended), (2) Skip (will require manual credential handling)
- glab not authenticated → Guide through `glab auth login` (opens browser for easy login)
- Atlassian MCP missing → Offer: (1) Show setup guide, (2) Skip Confluence/Jira features

### Phase 2: Workspace Setup

**Determine workspace location first:**

1. If user provided a path argument: Use that path
2. If user is already in a project directory (has `.git`, `README`, etc.): Ask if they want to use current directory
3. Otherwise: Ask for project name and propose `~/Projects/<project-name>`

**Quick Setup Detection:**
Check if there's an existing `.context-init.json` in the target directory:

```bash
# Check target directory (use absolute path)
ls -la /absolute/path/to/workspace/.context-init.json 2>/dev/null || echo "Not found"
```

If found:
1. Read existing config and present current state
2. Ask user: "I found an existing context configuration. Would you like to: (1) Update it, (2) Replace it completely, (3) View current config?"

**New Setup:**
1. Confirm the workspace path with user
2. Create the folder if it doesn't exist:

```bash
mkdir -p "/absolute/path/to/workspace"
```

3. Store the absolute workspace path for use in all subsequent phases

**IMPORTANT:** Always use absolute paths in all bash commands. Do NOT use `cd` as directory changes don't persist between command executions. Instead, prefix all file operations with the full workspace path.

4. Confirm workspace created and display the absolute path

### Phase 3: Repository Cloning

**Goal:** Clone relevant GitLab repositories into the workspace.

**First, ask if user wants to clone repositories:**
- "Would you like to clone GitLab repositories into this workspace?"
- Options: (1) Yes, clone repos (2) Skip - I already have repos cloned (3) Skip - no repos needed

**If user chooses to skip:** Proceed to Phase 4. Note in `.context-init.json` that no repos were cloned.

**IMPORTANT:** Always use `glab repo clone` instead of `git clone`. The glab CLI handles GitLab authentication automatically, which means non-technical users don't need to set up SSH keys or manage credentials. This is essential for the target audience of this skill.

1. Ask user: "What GitLab repositories should I clone? You can provide:
   - Full URLs (e.g., https://gitlab.com/group/project)
   - Project paths (e.g., group/project)
   - Or say 'search' to find repos by name"

2. For each repository, clone into the workspace using absolute paths:
```bash
# Clone by project path (preferred) - specify target directory
glab repo clone group/project "/absolute/path/to/workspace/project"

# Clone by URL
glab repo clone https://gitlab.com/group/project "/absolute/path/to/workspace/project"
```

3. If user wants to search for repos:
```bash
glab repo list --search "<query>" --mine
# or for group repos:
glab repo list --group "<group-name>"
```

4. **Get repository description** using `glab repo view`:
```bash
# Get repo details including description
glab repo view group/project --output json
```
Extract the `description` field from the JSON output.

5. Build repository inventory for CLAUDE.md:

| Repository | Description | Default Branch |
|------------|-------------|----------------|
| repo-name | Description from glab repo view | main |

**Fallback:** If glab is not available and user chose to skip installation, use `git clone` with HTTPS URLs. Warn the user they may be prompted for credentials. Description will need to be asked from user manually.

### Phase 4: Generate CLAUDE.md

**Goal:** Create a project configuration file that helps Claude Code understand the context.

1. Gather information:
   - Project name (from Phase 2)
   - Cloned repositories (from Phase 3)
   - Ask: "In 2-3 sentences, what is this project about?"
   - Ask: "Who are the main stakeholders or team members I should know about?"

2. Use the template from `{{SKILL_DIR}}/../references/templates.md` to generate CLAUDE.md

3. Write to `<workspace>/CLAUDE.md`

4. Show user the generated content and ask for any corrections

### Phase 5: Confluence Integration

**Skip if Atlassian MCP is not available.**

1. **Get Atlassian Cloud ID first** (if not already captured):
   - Call `mcp__plugin_atlassian_atlassian__getAccessibleAtlassianResources`
   - Extract and store the `id` field (this is the cloudId)
   - Store in `.context-init.json` as `atlassianCloudId` for future use

2. List accessible Confluence spaces:
   - Use `mcp__plugin_atlassian_atlassian__getConfluenceSpaces` with the cloudId

3. Ask user: "Which Confluence space contains your project documentation?"
   - Present list of available spaces with their keys
   - User selects one or provides space key

4. Once space is selected, ask: "What are the key pages I should reference? Common examples:
   - Project overview/wiki home
   - Architecture decisions
   - Requirements documents
   - Meeting notes location"

5. For each key page:
   - Use `mcp__plugin_atlassian_atlassian__search` or get page ID
   - Verify page exists
   - Add to CLAUDE.md with page title and ID

6. Update CLAUDE.md with Confluence section including:
   - Cloud ID (for reference)
   - Space key
   - Key page references with IDs
   - Natural language examples of how to ask Claude for help

### Phase 6: Jira Integration

**Skip if Atlassian MCP is not available.**

1. **Ensure Cloud ID is captured** (should already be done in Phase 5, but verify):
   - If not already captured, call `mcp__plugin_atlassian_atlassian__getAccessibleAtlassianResources`
   - Use the same cloudId for Jira as Confluence (they share the same Atlassian instance)

2. List accessible Jira projects:
   - Use `mcp__plugin_atlassian_atlassian__getVisibleJiraProjects` with the cloudId

3. Ask user: "Which Jira project tracks work for this initiative?"
   - Present list of available projects with keys
   - User selects one or provides project key

4. Once project selected, gather useful queries:
   - Ask: "What are common labels or components used in this project?"
   - Ask: "Are there specific epic(s) I should track?"

5. Update CLAUDE.md with Jira section including:
   - Cloud ID (for reference)
   - Project key
   - Natural language examples of how to ask Claude for help
   - Epic references if provided

### Phase 7: Additional Context

Ask user: "Is there any additional context I should know about?
- Meeting notes or recordings to review?
- External documentation links?
- Key decisions already made?
- Constraints or guidelines to follow?"

Add any additional context to CLAUDE.md.

### Phase 8: Finalization

1. Generate `.context-init.json` marker file (use absolute path):
```json
{
  "version": "1.0.0",
  "created": "<ISO timestamp>",
  "updated": "<ISO timestamp>",
  "projectName": "<name>",
  "workspacePath": "/absolute/path/to/workspace",
  "atlassianCloudId": "<cloud-id or null if not configured>",
  "repositories": [
    {
      "name": "<repo-name>",
      "url": "<clone-url>",
      "description": "<description>",
      "defaultBranch": "<branch>"
    }
  ],
  "confluence": {
    "spaceKey": "<space-key>",
    "spaceId": "<space-id>",
    "keyPages": [{"id": "<page-id>", "title": "<title>"}]
  },
  "jira": {
    "projectKey": "<project-key>",
    "projectId": "<project-id>",
    "epics": [{"key": "<epic-key>", "name": "<epic-name>"}]
  }
}
```

Write to: `<workspace-path>/.context-init.json`

2. Write CLAUDE.md to: `<workspace-path>/CLAUDE.md`

3. Present summary:

```
## Context Setup Complete

**Workspace:** /absolute/path/to/workspace
**Repositories cloned:** <count> (or "Skipped")
**Confluence space:** <space-key> (or "Not configured")
**Jira project:** <project-key> (or "Not configured")

### Files Created
- CLAUDE.md - Project configuration for Claude Code
- .context-init.json - Configuration marker (for future updates)

### Next Steps
1. Open this folder in your terminal: `cd /absolute/path/to/workspace`
2. Or open directly in Claude Code (if installed as app)
3. Start planning with: `/planning:aidlc-plan`
4. Review project docs in Confluence using the examples in CLAUDE.md
```

**Note:** Suggest adding `.context-init.json` to `.gitignore` if the workspace will be a git repository, as it contains user-specific paths.

## Error Handling

### Clone Failures
- Verify the repository URL or path is correct
- Check network connectivity
- If using glab: run `glab auth status` to verify authentication
- If glab auth expired: run `glab auth login` to re-authenticate

### glab Authentication Issues
- Guide user through `glab auth login` (opens browser for easy OAuth login)
- If browser login fails, offer `glab auth login --token` as alternative
- Last resort: fall back to `git clone` with HTTPS (user will need to enter credentials)

### Atlassian MCP Failures
- Verify MCP is configured in Claude Code settings
- Check authentication status
- Offer to proceed without Confluence/Jira features

## Templates Reference

All templates and installation guides are in: `{{SKILL_DIR}}/../references/templates.md`
