# VCS Provider Detection

This document defines how to detect and work with the VCS provider (GitHub vs GitLab) in AIDLC workflows. VCS provider is **independent of the documentation backend** — a team can use Linear + GitHub, GitLab + GitLab, or Confluence + GitHub.

> **When to use this reference**: Any skill that creates PRs/MRs, posts review comments, discovers linked PRs, or transitions MR/PR states should detect the VCS provider using this logic.

## Detection Logic

Detect the VCS provider from the current repository's git remote:

```bash
VCS_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")

# Extract the host portion to avoid false positives from repo names containing
# "github" or "gitlab" (e.g., git@github.com:org/gitlab-tools.git)
# Handles both HTTPS (https://github.com/...) and SSH (git@github.com:...) formats
VCS_HOST=$(echo "$VCS_REMOTE" | sed -E 's|https?://([^/]+)/.*|\1|; s|git@([^:]+):.*|\1|')

if echo "$VCS_HOST" | grep -qi "github\.com"; then
  VCS_PROVIDER="github"
elif echo "$VCS_HOST" | grep -qi "gitlab"; then
  VCS_PROVIDER="gitlab"
else
  VCS_PROVIDER="unknown"
fi
```

**If `VCS_PROVIDER` is `"unknown"`**: Ask the user:
```
I couldn't detect whether this repository is hosted on GitHub or GitLab.
Which VCS provider are you using?
1. GitHub
2. GitLab
3. Other (I'll use git commands only)
```

**Note**: If the skill is operating on the `ai-dlc-docs` documentation repository (GitLab backend), the VCS provider for that repo will always be GitLab. VCS detection applies to the **source code repository** being implemented, not the docs repo.

## Command Equivalence Table

| Operation | GitLab (`glab`) | GitHub (`gh`) |
|-----------|-----------------|---------------|
| Check CLI installed | `which glab` | `which gh` |
| Check auth | `glab auth status` | `gh auth status` |
| Create draft PR/MR | `glab mr create --draft --title "..." --source-branch "<branch>"` | `gh pr create --draft --title "..." --head "<branch>"` |
| View PR/MR | `glab mr view <ID>` | `gh pr view <NUMBER>` |
| View PR/MR diff | `glab mr diff <ID>` | `gh pr diff <NUMBER>` |
| View PR/MR with comments | `glab mr view <ID> --comments` | `gh pr view <NUMBER> --comments` |
| List PRs/MRs by branch | `glab mr list --source-branch "<branch>"` | `gh pr list --head "<branch>"` |
| List PRs/MRs (all open) | `glab mr list` | `gh pr list` |
| Mark PR/MR ready | `glab mr update <ID> --ready` | `gh pr ready <NUMBER>` |
| Add comment | `glab mr note <ID> --message "..."` | `gh pr comment <NUMBER> --body "..."` |
| Post review (comment mode) | `glab mr note <ID> --message "..."` | `gh pr review <NUMBER> --comment --body "..."` |
| Merge PR/MR | `glab mr merge <ID>` | `gh pr merge <NUMBER>` |

## Inline Review Comments (GitHub)

For posting inline comments on specific file lines in a GitHub PR, use the GitHub API via `gh api`:

```bash
COMMIT_ID=$(gh pr view <NUMBER> --json headRefOid -q .headRefOid)
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  --method POST \
  --input - <<EOF
  {"body":"<summary>","event":"COMMENT","commit_id":"$COMMIT_ID","comments":[{"path":"<file>","line":<line>,"body":"<comment>"}]}
EOF
```

For GitLab, use `glab mr note`:
```bash
glab mr note <MR_ID> --message "<comment>"
```

## CLI Fallback Strategy

If the VCS CLI is unavailable:

1. **GitHub (`gh` not installed)**: Log a warning. Ask the user to paste the PR URL and diff, or use GitHub MCP tools if configured.
2. **GitLab (`glab` not installed)**: Log a warning. Fall back to GitLab MCP tools (`mcp__gitlab__*`) or ask the user to provide content manually.
3. **No git remote**: Skip all VCS operations. Report metrics from work tracking (Jira/Linear) and local files only.

## Integration with BackendContext

When a skill resolves the VCS provider, store it in the BackendContext:

```typescript
BackendContext.vcsProvider = "github" | "gitlab";
BackendContext.prUrl = "<PR/MR URL after creation>";  // set after PR/MR created
```

This allows downstream phases (review, progress) to use the correct CLI without re-detecting.
