# Backend Selection

This document defines how to prompt users for backend selection at the start of each AIDLC skill that creates or modifies documentation.

## When to Prompt

Prompt for backend selection at the **start** of these skills:
- `/aidlc-intent` - Creating new Feature
- `/aidlc-elaborate` - Creating Epics and Tasks (if not continuing from Feature)
- `/aidlc-design` - Creating design documents (if not continuing from Feature)

**Do NOT prompt** for these skills (detect backend from existing artifacts):
- `/aidlc-verify` - Reads existing docs, detects backend automatically
- `/aidlc-review` - Reads existing docs, detects backend automatically
- `/aidlc-progress` - Reads existing docs, detects backend automatically
- `/aidlc-sprint` - Uses Jira/Linear, not documentation backend

## Selection Prompt

Use AskUserQuestion with these options:

```
Which document backend would you like to use?

1. **GitLab** (recommended) - Markdown files in git repo with MR-based review
2. **Linear** - Native Linear Initiatives/Projects/Issues (replaces both docs AND Jira)
3. **Confluence** - Confluence pages with Jira integration
```

## Backend Detection

When continuing work on an existing Feature/Project, detect the backend from existing artifacts:

### GitLab Detection

Check for `.md` files with YAML frontmatter containing `backend: gitlab`:

```yaml
---
backend: gitlab
type: feature
project: "Project Name"
...
---
```

Or check if the working directory is the ai-dlc-docs repo:
```bash
git remote get-url origin | grep -q "ai-dlc-docs"
```

### Linear Detection

Check for Linear Initiative/Project IDs in context or if user provides Linear URLs:
- Initiative URL: `https://linear.app/team/initiative/...`
- Project URL: `https://linear.app/team/project/...`

Or frontmatter with `backend: linear`:
```yaml
---
backend: linear
initiative_id: "abc123"
...
---
```

### Confluence Detection

Check for Confluence page URLs or IDs:
- Page URL: `https://xxx.atlassian.net/wiki/spaces/.../pages/...`
- Page ID in context

Or frontmatter with `backend: confluence`:
```yaml
---
backend: confluence
page_id: "123456789"
...
---
```

## BackendContext Interface

When a backend is selected, create a BackendContext object to pass between phases:

```typescript
interface BackendContext {
  backend: 'gitlab' | 'linear' | 'confluence';
  vcsProvider?: 'github' | 'gitlab';  // Auto-detected from git remote (see vcs-detection.md)

  // Common fields
  projectName: string;
  featureTitle: string;
  featureNumber: number;

  // GitLab-specific
  gitBranch?: string;           // e.g., "intent/my-project/auth-overhaul"
  gitRepoPath?: string;         // e.g., "$AIDLC_DOCS_PATH" (set via env var)
  mrUrl?: string;               // e.g., "https://gitlab.com/.../merge_requests/123"
  featureFilePath?: string;      // e.g., "Projects/My Project/Feature 1 - Auth/intent.md"

  // Linear-specific
  teamId?: string;              // Linear team ID
  teamKey?: string;             // Linear team key (e.g., "ENG")
  initiativeId?: string;        // Linear Initiative ID
  initiativeUrl?: string;       // Linear Initiative URL

  // Confluence-specific
  spaceKey?: string;            // Confluence space key
  featurePageId?: string;        // Confluence Feature page ID
  epicsOverviewPageId?: string; // Confluence Epics Overview page ID
  jiraProjectKey?: string;      // Associated Jira project key

  // VCS-specific (set after PR/MR creation)
  prUrl?: string;               // e.g., "https://github.com/.../pull/123" or "https://gitlab.com/.../merge_requests/123"
}
```

## VCS Provider Detection

When a skill needs to interact with PRs/MRs (creating, reviewing, listing), detect the VCS provider from the current source code repository's git remote. See @${CLAUDE_PLUGIN_ROOT}/references/vcs-detection.md for detection logic and command equivalences.

This is **independent of the documentation backend**:
- **Linear + GitHub**: Docs in Linear, PRs via `gh` CLI
- **GitLab + GitLab**: Docs in git repo, MRs via `glab` CLI
- **Confluence + GitHub**: Docs in Confluence, PRs via `gh` CLI

> **Note**: When using the GitLab documentation backend, the `ai-dlc-docs` repo always uses `glab`. VCS detection applies to the **source code repo** being implemented.

## Slugging Rules

For GitLab branch and directory names, apply these slugging rules:

```
1. Convert to lowercase
2. Replace spaces with hyphens
3. Remove special characters except hyphens
4. Collapse multiple hyphens to single
5. Trim leading/trailing hyphens
```

Examples:
- "My Project" → "my-project"
- "Auth & Permissions Overhaul" → "auth-permissions-overhaul"
- "Feature 1: Authentication" → "feature-1-authentication"

## Backend Comparison

| Feature | GitLab | Linear | Confluence |
|---------|--------|--------|------------|
| Document storage | .md files in repo | Native objects | Confluence pages |
| Hierarchy | Directories | Initiative → Project → Issue | Pages/child pages |
| Review workflow | MR comments | Linear comments | Page comments |
| Work tracking | Jira (via `/aidlc-verify`) | Linear (built-in) | Jira (via `/aidlc-verify`) |
| MCP tools | Bash (glab CLI) | Linear MCP | Atlassian MCP |
| Offline support | Yes (git) | No | No |
| Version history | Git commits | Linear history | Page versions |
| VCS provider | GitLab (built-in) | Auto-detected from repo remote | Auto-detected from repo remote |

## Backend-Specific References

For detailed operations, see:
- [GitLab Backend](./backends/gitlab.md)
- [Linear Backend](./backends/linear.md)
- [Confluence Backend](./backends/confluence.md)
