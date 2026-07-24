---
name: aidlc-init
description: Initialize AI-DLC configuration for a project — capture Jira, Confluence, GitLab, and Linear settings and write them to aidlc.config.yaml so no organisation details are hardcoded. Run this ONCE before /aidlc-intent. (Triggers - aidlc init, initialize aidlc, configure aidlc, set up aidlc, aidlc config, aidlc setup, configure jira confluence gitlab)
---

# AI-DLC Init

Set up the project's AI-DLC configuration. This skill collects the connection and
backend details that every other AIDLC skill needs (Jira, Confluence, GitLab, Linear)
and writes them to **`aidlc.config.yaml`** in the project root. All later skills read
this file instead of any hardcoded organisation values.

> **Run this first.** `/aidlc-init` should be run once per project, before `/aidlc-intent`.
> If `aidlc.config.yaml` already exists, this skill offers to review and update it.

## When to use

- Starting AI-DLC in a new repository for the first time.
- Onboarding a new team/organisation (different Jira site, Confluence space, or GitLab group).
- Changing the default documentation backend.
- Any AIDLC skill reports a missing config value (e.g. `<CONFLUENCE_SPACE_KEY>` unresolved).

## Config schema

The generated `aidlc.config.yaml` has this shape (see `aidlc.config.example.yaml` for the annotated version):

```yaml
backend:
  default: "gitlab"          # gitlab | linear | confluence
atlassian:
  cloudId: ""                # e.g. yourcompany.atlassian.net   -> <ATLASSIAN_CLOUD_ID>
confluence:
  spaceKey: ""               # e.g. ENG                          -> <CONFLUENCE_SPACE_KEY>
  featureIndexPageId: ""     # page id of the Features Index     -> <FEATURE_INDEX_PAGE_ID>
jira:
  projectKey: ""             # e.g. PROJ
  issueTypes:                # stock Jira types by default (no custom types needed)
    epic: "Epic"
    grouping: "Story"        # groups tasks (formerly the "Sprint" type)
    leaf: "Task"
  leafAttach: "link"         # Jira: Story+Task are same level, so link (not nest); leaf parented to Epic
  linkType: "Relates"
ado:
  project: ""                # ADO project name (only if work tracker is Azure DevOps)
  issueTypes:
    epic: "Epic"
    grouping: "User Story"
    leaf: "Task"
  leafAttach: "parent"       # ADO nests Task under User Story natively
gitlab:
  docsRepoUrl: ""            # https://gitlab.com/org/group/ai-dlc-docs -> <GITLAB_DOCS_REPO_URL>
  docsRepoSsh: ""            # git@gitlab.com:org/group/ai-dlc-docs.git -> <GITLAB_DOCS_REPO_SSH>
  docsPath: ""               # local checkout path
linear:
  teamKey: ""                # e.g. ENG
links:
  performanceStandards: ""   # optional reference URL            -> <PERFORMANCE_STANDARDS_URL>
```

These placeholder tokens (`<ATLASSIAN_CLOUD_ID>`, `<CONFLUENCE_SPACE_KEY>`,
`<FEATURE_INDEX_PAGE_ID>`, `<GITLAB_DOCS_REPO_URL>`, `<GITLAB_DOCS_REPO_SSH>`,
`<PERFORMANCE_STANDARDS_URL>`) appear throughout the other skills and reference docs.
Every skill resolves them by reading `aidlc.config.yaml`.

## Workflow

1. **Check for existing config**
   - Look for `aidlc.config.yaml` in the project root (and `$AIDLC_DOCS_PATH` if set).
   - If found: show the current values and ask whether to keep or update each section. Skip to step 4 for confirmation.
   - If not found: continue to step 2.

2. **Choose the documentation backend** (use AskUserQuestion)
   Ask which backend this project will use:
   - **GitLab** (recommended) — markdown files in a git repo with MR review
   - **Linear** — native Linear Initiatives/Projects/Issues (replaces docs AND Jira)
   - **Confluence** — Confluence pages with Jira integration

   Record as `backend.default`. Only prompt for the sections relevant to the chosen backend
   (but still allow the user to fill others if they want).

3. **Collect settings** (ask only what's relevant; one focused question at a time)

   **Atlassian / Jira / Confluence** (if backend is Confluence, or Jira work-tracking is wanted):
   - `atlassian.cloudId` — the Atlassian site host, e.g. `yourcompany.atlassian.net`
   - `confluence.spaceKey` — the Confluence space key, e.g. `ENG`
   - `confluence.featureIndexPageId` — leave blank on first run (the Features Index page is auto-created by `/aidlc-intent`)
   - `jira.projectKey` — default Jira project key, e.g. `PROJ`
   - `jira.issueTypes` / `jira.leafAttach` / `jira.linkType` — the issue types used at transfer. Defaults (Epic → Story → Task, `leafAttach: link`, `linkType: Relates`) work against a stock Jira project with no custom types. Only change these if your project uses different type names (e.g. a custom "Sprint" type: set `grouping: "Sprint"`, `leaf: "Task"`). Confirm the types exist via `getJiraProjectIssueTypesMetadata` before finalizing.
   - **Azure DevOps** (if the work tracker is ADO): `ado.project`, and `ado.issueTypes` (defaults Epic → User Story → Task with `leafAttach: parent`, since ADO nests Task under User Story natively).

   **GitLab** (if backend is GitLab):
   - `gitlab.docsRepoUrl` — HTTPS URL of the `ai-dlc-docs` repo
   - `gitlab.docsRepoSsh` — SSH URL of the same repo (optional)
   - `gitlab.docsPath` — local checkout path (optional; can also be set via `AIDLC_DOCS_PATH`)

   **Linear** (if backend is Linear):
   - `linear.teamKey` — Linear team key, e.g. `ENG`

   **Optional:**
   - `links.performanceStandards` — a reference URL surfaced in planning docs

   Do not invent values. Leave anything the user doesn't have as `""`.

4. **Confirm and write**
   - Show the assembled YAML for approval.
   - On approval, write it to `aidlc.config.yaml` in the project root.
   - Confirm the file path and remind the user this file may contain internal URLs/keys —
     add it to `.gitignore` if those are sensitive (offer to do so).

5. **Next step**
   - Tell the user they can now run `/aidlc-intent` to capture the first **Feature**.

## Reading config from other skills

Other skills should resolve placeholders like this:

1. Read `aidlc.config.yaml` from the project root (or `$AIDLC_DOCS_PATH`).
2. Substitute each `<TOKEN>` with the matching config value:
   - `<ATLASSIAN_CLOUD_ID>` ← `atlassian.cloudId`
   - `<CONFLUENCE_SPACE_KEY>` ← `confluence.spaceKey`
   - `<FEATURE_INDEX_PAGE_ID>` ← `confluence.featureIndexPageId`
   - `<GITLAB_DOCS_REPO_URL>` ← `gitlab.docsRepoUrl`
   - `<GITLAB_DOCS_REPO_SSH>` ← `gitlab.docsRepoSsh`
   - `<PERFORMANCE_STANDARDS_URL>` ← `links.performanceStandards`
3. If a required value is blank, stop and tell the user to run `/aidlc-init`.

## Definition of Done

- `aidlc.config.yaml` exists in the project root with the user-approved values.
- The chosen default backend is recorded.
- The user knows the next step is `/aidlc-intent`.
