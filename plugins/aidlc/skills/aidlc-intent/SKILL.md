---
name: aidlc-intent
description: Create and iteratively refine AI-DLC Feature documentation with human-in-the-loop validation, risk surfacing, NFRs, and measurement criteria. Supports GitLab (recommended), Linear, or Confluence backends. Use when asked to draft or update a Feature or initiative doc. (Triggers - create feature, feature document, new initiative, draft feature, planning doc, feature brief, aidlc plan)
---

# AI-DLC Plan Feature

Produce the Feature documentation as the single source of truth for the project idea. Supports multiple backends: **GitLab** (markdown files with MR review), **Linear** (native Initiatives), or **Confluence** (pages with Jira). Emphasize iteration, human approval, and risk visibility.

> **IMPORTANT: Keep Feature Docs Lightweight**
>
> Feature documents capture WHAT needs to be achieved, not HOW to break it down.
> - Do NOT include detailed epic decomposition or Task breakdowns
> - Do NOT create work tracking artifacts at this stage (Jira/Linear Issues)
> - Epic breakdown happens later in `/aidlc-elaborate` (Mob Elaboration)
> - You may include "Proposed Epics (hypotheses only)" as rough scope indicators

## Backend Selection

At the start of this skill, prompt the user to select a documentation backend using the guidance in @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md.

**Quick reference:**
- **GitLab** (recommended): Markdown files in git repo with MR-based review
- **Linear**: Native Linear Initiatives (replaces BOTH docs AND Jira)
- **Confluence**: Confluence pages with Jira integration (legacy)

## Completion Checklist

> **IMPORTANT**: Create tasks for each step at the start using `TodoWrite`. Mark tasks complete as you go using `TodoWrite`. Each task description should reference the corresponding Workflow step.

| # | Task | Depends On | Workflow Reference | Exit Criteria |
|---|------|------------|-------------------|---------------|
| 0 | Select backend | — | Backend Selection | User selects GitLab, Linear, or Confluence |
| 1 | Gather context | 0 | Workflow > Step 1 | All required fields collected (name, users, pathway, scope, NFRs, risks) |
| 2 | Gather repo context | 1 | Workflow > Step 2 | Repo README and key files read, or N/A confirmed |
| 3 | Confirm understanding | 1, 2 | Workflow > Step 3 | User confirms 5-8 bullet summary is correct |
| 4 | Draft Level 1 doc | 3 | Workflow > Step 4 | Draft follows template, all sections populated |
| 5 | Review and iterate (PUBLISH GATE) | 4 | Workflow > Step 5 | HARD STOP. User gives explicit publish approval ("publish" / "approved" / "go ahead"). Answering clarifying questions does NOT count as approval. |
| 6 | Create Feature artifact | 5 | Workflow > Step 6 | GitLab: MR created / Linear: Initiative created / Confluence: Page created |
| 7 | Update document index | 6 | Workflow > Step 7 | Features Index updated with this Feature's entry |
| 8 | Get explicit approval | 7 | Workflow > Step 8 | User explicitly approves the Feature |
| 9 | Update workflow status | 8 | Workflow > Step 9 | Status shows "Feature: ✅ Approved" |
| 10 | Create work tracking project (optional) | 9 | Workflow > Step 10 | GitLab/Confluence: Jira Project created / Linear: N/A (built-in) |

## Task Tracking

When this skill is invoked:

1. **Create tasks** for the current phase's checklist items using `TodoWrite`
   - Include a reference to the workflow step in the task description (content field)
   - Set activeForm appropriately (e.g., "Gathering context" for content "Gather context (See Workflow > Step 1)")
   - Example: `"Gather context (See Workflow > Step 1)"`
2. **Mark task as in_progress** when starting each step using `TodoWrite` (update status)
3. **Mark task complete** when the exit criteria are met using `TodoWrite` (update status)
4. **Verify all tasks complete** before finishing the skill

This ensures visibility into progress and prevents incomplete execution.

## AI-Drives-Conversation Pattern

This skill follows the AI-DLC principle where AI initiates and directs the conversation:

1. **AI proposes** — Present options, recommendations, and trade-offs
2. **Human approves** — Validate, select, or adjust
3. **AI elaborates** — Expand on approved direction
4. **Human confirms** — Final approval before artifact creation

At each step, AI should:
- Ask clarifying questions proactively
- Propose multiple options where applicable
- Surface risks and trade-offs upfront
- Request explicit approval before proceeding

## Example Invocations

- "Create a Feature doc for the new authentication system"
- "Draft an feature document for adding dark mode"
- "Help me create a Confluence feature brief for the billing overhaul"
- "Start a new initiative doc for the API migration"

## References

- @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md - Templates, prompts, and tool names
- @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md - Backend selection flow and detection
- @${CLAUDE_PLUGIN_ROOT}/references/backends/gitlab.md - GitLab-specific operations
- @${CLAUDE_PLUGIN_ROOT}/references/backends/linear.md - Linear-specific operations
- @${CLAUDE_PLUGIN_ROOT}/references/backends/confluence.md - Confluence-specific operations
- @${CLAUDE_PLUGIN_ROOT}/references/aidlc-index.md - AIDLC Document Index location and table structure

## Optional Artifacts

### PRFAQ (Press Release / FAQ)
If requested, generate a PRFAQ to communicate the Feature's value proposition:
- **Press Release**: What is being built and why it matters
- **FAQ**: Anticipated questions from stakeholders

Include in Confluence doc as a collapsible section or separate child page. See PRFAQ Template in @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md.

## Workflow

1. **Gather context**
   Ask only for what is missing:
   - Feature name and short description
   - Target users and business outcomes
   - Pathway type (green-field, brown-field, modernization, defect fix)
   - Scope boundaries (in/out)
   - NFRs (performance, reliability, security, compliance, privacy)
   - Measurement criteria (KPIs/OKRs/SLIs + baseline if known)
   - Known dependencies and assumptions
   - Known risks (use Organizational Risk Taxonomy in shared ref; prioritize Data & Privacy and Security Posture)
   - Testing strategy preferences (see Testing Strategy Guidance in shared ref)
   - Repositories/services in scope (local paths or remote URLs)
   - **Service inventory** — for each service/repository involved, capture:

     | Service | Pathway | Repo Link |
     |---------|---------|-----------|
     | e.g., Camera Detection Service | Green-field | (new) |
     | e.g., Dismissal Stack API | Brown-field | https://gitlab.com/... |

     If the user provides a loose list of repos, reshape into this table. Ask if pathway type is unclear.
   - Whether to generate a PRFAQ (optional)

   **Backend-specific context:**
   - **GitLab**: Project name (for directory structure)
   - **Linear**: Team name (use `list_teams` to find)
   - **Confluence**: Space key (default `<CONFLUENCE_SPACE_KEY>` — from `aidlc.config.yaml`; run `/aidlc-init`), existing pages to reference

2. **Gather repo context (if applicable)**
   When the Feature involves code changes, follow the Repo Context Gathering guidance in @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md to understand the technical landscape.

3. **Confirm understanding**
   Summarize in 5-8 bullets and ask for corrections before drafting.

4. **Draft Feature documentation**
   Use the template in @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md. Keep it concise and scannable.

5. **Review and iterate (HARD STOP — publish gate)**
   Share the FULL draft with the user. Then STOP and ask an explicit, blocking confirmation before any artifact is created:

   > "Here is the complete Feature draft. Is everything captured and correct? Reply **'publish'** and I'll create the [Confluence page / GitLab MR / Linear Initiative]. I will not create or update anything until you confirm."

   - Do NOT proceed to Step 6 until the user replies with explicit approval ("publish", "approved", "go ahead").
   - Answering clarifying questions is NOT approval. Scope answers, edits, or extra context do not count as consent to publish.
   - If the user requests changes, revise and re-ask the same confirmation. Loop until explicit approval is given in this session.

6. **Create Feature artifact** (backend-specific)

   > **Pre-condition (do not skip):** Only begin this step if Step 5's explicit publish approval was received in this session. If not, return to Step 5.

   **GitLab** (see @${CLAUDE_PLUGIN_ROOT}/references/backends/gitlab.md):
   1. Ensure repo cloned: `cd "$AIDLC_DOCS_PATH" && git pull origin main` (set AIDLC_DOCS_PATH env var or prompt user)
   2. Create branch: `git checkout -b "intent/<project-slug>/<intent-slug>"`
   3. Create directory: `mkdir -p "Projects/<Project>/Feature <N> - <Title>"`
   4. Write `intent.md` with frontmatter using template
   5. Commit and push: `git add . && git commit -m "feat(feature): ..." && git push -u origin <branch>`
   6. Create draft MR: `glab mr create --draft --title "[Feature <N>] <Title>" ...`

   **Linear** (see @${CLAUDE_PLUGIN_ROOT}/references/backends/linear.md):
   1. Create Initiative via `save_initiative`:
      - `name`: "Feature: <Title>"
      - `description`: Feature markdown content
      - `status`: "Planned"
      - `owner`: current user or "me"
   2. Store Initiative ID and URL for subsequent phases

   **Confluence** (see @${CLAUDE_PLUGIN_ROOT}/references/backends/confluence.md):
   1. Use Atlassian MCP to create page in chosen space
   2. If parent page needed, ask where to place it
   3. Include Workflow Status table from planning-shared.md

7. **Update Features Index**

   After the Feature artifact is created, register it in the Features Index — a single Confluence page that provides a human-readable overview of all active Features across all backends. See @${CLAUDE_PLUGIN_ROOT}/references/aidlc-index.md for the index location, table structure, and initial page content.

   1. Fetch the index page directly by ID:
      ```
      getConfluencePage(
        cloudId: "<ATLASSIAN_CLOUD_ID>",
        pageId: "<FEATURE_INDEX_PAGE_ID>"
      )
      ```
   2. **If found**: Fetch the page content, append a new row for this Feature, then update the page using `updateConfluencePage`
   3. **If not found**: Create the page under page ID `<FEATURE_INDEX_PAGE_ID>` in space `<CONFLUENCE_SPACE_KEY>` using `createConfluencePage` with the initial content from the reference, then add the first row

   Populate the new row with values gathered during this workflow:

   | Column | Value |
   |--------|-------|
   | Feature | Feature name, hyperlinked to its document (GitLab: MR URL / Linear: Initiative URL / Confluence: Page URL) |
   | Product / Project | From Step 1 context |
   | Backend | GitLab / Linear / Confluence (whichever was selected in Step 0) |
   | Location | GitLab: MR URL; Linear: Initiative URL; Confluence: Page URL |
   | Phase | Feature |
   | Team | Owning team from Step 1 context |
   | Created | Today's date |

8. **Approval gate**
   Explicitly ask whether the Feature documentation is approved.

9. **Update workflow status** (backend-specific)

   **GitLab**:
   - Update `intent.md` frontmatter: `status: approved`
   - Update Workflow Status table in file
   - Commit and push changes

   **Linear**:
   - Update Initiative status via `save_initiative(id: "<id>", status: "Active")`
   - Optionally add status update via `save_status_update`

   **Confluence**:
   - Update page status table: Set "Feature" row to "✅ Approved" with today's date

10. **Create work tracking project (optional, backend-specific)**

   **GitLab / Confluence** - Offer to create Jira Project:
   > "Would you like to create a Jira Project to track this Feature? (recommended for portfolio visibility)"

   If user agrees:
   1. Create Project issue:
      ```bash
      acli jira workitem create --project "PROJ" --type "Project" \
        --summary "<Project Name>" \
        --description "Project for: <Feature Name>\n\nIntent URL: <URL>" \
        --label "aidlc:project" \
        --json
      ```
   2. Store Project key in doc (GitLab: update frontmatter / Confluence: add to Workflow Status table)
   3. Update status: "Project: ✅ Created" with Jira key

   If user declines:
   - Continue without Project
   - Note: Project can be created later in `/aidlc-verify`

   **Linear** - Skip this step:
   - Linear IS the work tracker (replaces Jira)
   - Work tracking happens natively via Projects and Issues in Linear
   - No separate Jira integration needed

11. **Chain to Decompose**
    If approved and the user wants to proceed, invoke `/aidlc-elaborate` with the Feature reference:

    **GitLab**: Pass the MR URL and branch name
    **Linear**: Pass the Initiative ID and URL
    **Confluence**: Pass the Confluence page link

    Also pass along the Feature name, Project key (if created for GitLab/Confluence), and any context gathered. Note: For GitLab/Confluence, Jira artifacts are created later in `/aidlc-verify`. For Linear, work tracking is already native.

## Workflow Chain

- **This is the first step** in the AI-DLC planning workflow
- **Next**: `/aidlc-elaborate` (Mob Elaboration - Epic and Task decomposition)

## Definition of Done

- Feature artifact exists and is approved:
  - **GitLab**: `intent.md` committed, MR created, frontmatter `status: approved`
  - **Linear**: Initiative created with status "Active"
  - **Confluence**: Feature page exists with "✅ Approved" status
- Risks, NFRs, measurement criteria, and testing strategy are explicitly documented.
- Features Index updated with this Feature's entry (registered at creation, before approval).
- Work tracking setup complete (GitLab/Confluence: Jira Project created or declined; Linear: N/A - native).
- Approval to proceed to elaboration is explicitly confirmed.

## Troubleshooting

### GitLab
- **Repo not cloned**: Set AIDLC_DOCS_PATH env var or run `git clone <repo-url> <path>` and set the path
- **glab not installed**: Install via `brew install glab` or see [glab docs](https://gitlab.com/gitlab-org/cli)
- **Authentication failed**: Run `glab auth login`
- **Branch conflict**: Check if branch already exists with `git branch -a | grep <branch>`

### Linear
- **Team not found**: Use `list_teams` to see available teams
- **Initiative creation failed**: Verify Linear MCP is configured and authenticated
- **Permission denied**: Check team membership and access rights

### Confluence
- **Space not found**: Confirm the space key and permissions.
- **Parent page missing**: Ask for the correct parent or create at space root.
- **Conflicting docs**: Ask whether to update or create a new page.

### VCS Note
- When using **Linear** or **Confluence** backends, the Feature skill does not interact with VCS — no `glab` or `gh` commands are used.
- When using **GitLab** backend, `glab` is used for the `ai-dlc-docs` documentation repo (not the source code repo).
- For source code VCS operations (GitHub vs GitLab), see `/aidlc-sprint` and `/aidlc-review` skills and @${CLAUDE_PLUGIN_ROOT}/references/vcs-detection.md.
