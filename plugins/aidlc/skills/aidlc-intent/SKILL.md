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

> **IMPORTANT: Source-derived Intents follow the full standard**
>
> If the Feature derives from an existing requirement document (BRD/PRD/discovery brief),
> the Intent is a **delivery contract, not a second copy of the requirements**. Follow
> @${CLAUDE_PLUGIN_ROOT}/references/intent-doc-standard.md (full section order incl. source
> traceability, review outcomes, validation record, MVP slice) and
> @${CLAUDE_PLUGIN_ROOT}/references/intent-validation-workflow.md (how to validate & record).
> If there is NO source doc (pure green-field), the lightweight template below is enough and
> the source-traceability/validation sections are optional.

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
| 1a | Ingest source requirement (if any) | 1 | Workflow > Step 1a | Source doc read; version/date recorded; actors/phases/scope/NFRs extracted. Skip if no source doc. |
| 2 | Gather repo context | 1 | Workflow > Step 2 | Repo README and key files read, or N/A confirmed |
| 3 | Confirm understanding | 1, 1a, 2 | Workflow > Step 3 | User confirms 5-8 bullet summary is correct |
| 4 | Draft doc + source traceability | 3 | Workflow > Step 4 | Draft follows template; if source doc exists, §9.3 traceability matrix populated and MVP slice (§9.4) proposed |
| 5 | Review round + record validation (PUBLISH GATE) | 4 | Workflow > Step 5 | HARD STOP. Feedback dispositioned into decisions (R#)/pending (P#); validation record (§9.1) + checklist (§9.2) updated; version bumped. User gives explicit publish approval. |
| 6 | Create Feature artifact | 5 | Workflow > Step 6 | GitLab: MR created / Linear: Initiative created / Confluence: Page created |
| 7 | Update document index | 6 | Workflow > Step 7 | Features Index updated with this Feature's entry |
| 8 | Get explicit approval | 7 | Workflow > Step 8 | User explicitly approves the Feature |
| 9 | Update workflow status | 8 | Workflow > Step 9 | Status shows "Feature: ✅ Approved" |
| 10 | Create work tracking project (optional) | 9 | Workflow > Step 10 | GitLab/Confluence: Jira Project created / Linear: N/A (built-in) |
| 12 | Resolve post-publish review comments (optional) | 8 | Workflow > Step 12 | On request only: comments fetched, triaged (edit vs clarify), confirmed edits applied (versioned), threads replied/resolved, Workflow Status noted |

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
- "Create an Intent from this BRD: <link>"  ← source-derived; uses full standard
- "Help me create a Confluence feature brief for the billing overhaul"
- "Start a new initiative doc for the API migration"

## References

- @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md - Templates, prompts, and tool names
- @${CLAUDE_PLUGIN_ROOT}/references/intent-doc-standard.md - Full source-derived Intent structure (§0–§9)
- @${CLAUDE_PLUGIN_ROOT}/references/intent-validation-workflow.md - Validation rounds & recording
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
   - **Source requirement** — is there an existing BRD/PRD/discovery doc this derives from? If yes, capture the link (drives Step 1a).
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

1a. **Ingest source requirement (only if a source doc exists)**
   Follow @${CLAUDE_PLUGIN_ROOT}/references/intent-validation-workflow.md Step 1:
   - Fetch/read the source document (Confluence page, file, or URL).
   - Record its **version and date** in the Intent metadata header.
   - Extract actors, delivery phases, in/out scope, NFRs, data/PII, integrations.
   - Note candidate out-of-scope / deferred items to confirm during review.
   - This unlocks §0 (relationship to source), §9.3 (traceability), and §9.4 (MVP slice).

   If there is **no** source doc, skip this step and use the lightweight template.

2. **Gather repo context (if applicable)**
   When the Feature involves code changes, follow the Repo Context Gathering guidance in @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md to understand the technical landscape.

3. **Confirm understanding**
   Summarize in 5-8 bullets and ask for corrections before drafting. If a source doc was
   ingested, explicitly state what will be summarized-and-linked vs deferred to Design.

4. **Draft Feature documentation**
   - **No source doc:** use the lightweight Feature template in @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md.
   - **Source-derived:** use the full structure in @${CLAUDE_PLUGIN_ROOT}/references/intent-doc-standard.md. As you draft, populate the **§9.3 source traceability matrix** (every source area → FI section → Covered / Deferred to Design / Out of scope) and propose the **§9.4 MVP / first delivery slice** (marked "proposal — requires validation"). Keep §4 at summary depth; link to the source for field-level detail.

5. **Review round + record validation (HARD STOP — publish gate)**
   Share the FULL draft with the user. Then STOP and ask an explicit, blocking confirmation before any artifact is created:

   > "Here is the complete Feature draft. Is everything captured and correct? Reply **'publish'** and I'll create the [Confluence page / GitLab MR / Linear Initiative]. I will not create or update anything until you confirm."

   Before/while iterating, when the Feature is source-derived, run the validation round from
   @${CLAUDE_PLUGIN_ROOT}/references/intent-validation-workflow.md:
   - Disposition each piece of feedback → **Confirmed decisions (§8.1, `R#`)** or **Open/pending (§8.2, `P#`)** with an owner.
   - Update affected sections (scope, NFRs, edge cases) to match confirmed decisions.
   - Record the round in the **validation record (§9.1)** and tick the **validation checklist (§9.2)**.
   - Bump the document **Version** and add a "last updated" note + Version History row.

   Approval rules (all backends):
   - Do NOT proceed to Step 6 until the user replies with explicit approval ("publish", "approved", "go ahead").
   - Answering clarifying questions is NOT approval. Scope answers, edits, or extra context do not count as consent to publish.
   - If the user requests changes, revise and re-ask the same confirmation. Loop until explicit approval is given in this session.
   - For source-derived Intents, do not set **Status: Approved** while a **blocking** `P#` item remains open.

6. **Create Feature artifact** (backend-specific)

   > **Pre-condition (do not skip):** Only begin this step if Step 5's explicit publish approval was received in this session. If not, return to Step 5.

   **GitLab** (see @${CLAUDE_PLUGIN_ROOT}/references/backends/gitlab.md):
   1. Ensure repo cloned: `cd "$AIDLC_DOCS_PATH" && git pull origin main` (set AIDLC_DOCS_PATH env var or prompt user)
   2. Create branch: `git checkout -b "intent/<project-slug>/<intent-slug>"`
   3. Create directory: `mkdir -p "Projects/<Project>/Feature <N> - <Title>"`
   4. Write `intent.md` with frontmatter using template (include `document_id`, `version`, `source_requirement` when source-derived)
   5. Commit and push: `git add . && git commit -m "feat(feature): ..." && git push -u origin <branch>`
   6. Create draft MR: `glab mr create --draft --title "[Feature <N>] <Title>" ...`

   **Linear** (see @${CLAUDE_PLUGIN_ROOT}/references/backends/linear.md):
   1. Create Initiative via `save_initiative`:
      - `name`: "Feature: <Title>"
      - `description`: Feature markdown content
      - `status`: "Planned"
      - `owner`: current user or "me"
   2. Store Initiative ID and URL for subsequent phases
   3. If source-derived, track each `P#` pending item as a sub-issue.

   **Confluence** (see @${CLAUDE_PLUGIN_ROOT}/references/backends/confluence.md):
   1. Use Atlassian MCP to create page in chosen space
   2. If parent page needed, ask where to place it
   3. Include Workflow Status table from planning-shared.md
   4. If source-derived, render §0–§9 numbered sections and resolve merged inline comment threads.

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

12. **Resolve post-publish review comments (optional — on request, may be a later session)**

    The pre-publish gate (Step 5) only captures feedback discussed live. Reviewers usually
    comment **asynchronously on the published artifact** — the moment otherwise unsupported.
    When the user asks to process review comments on an already-published Feature, run this
    lightweight loop.

    > **Scope note:** This is NOT `/aidlc-elaborate`'s comment resolution. Elaborate operates
    > on the Epic artifacts it created, never on the Feature/Intent document — so comments left
    > on the Feature page are not picked up anywhere downstream. This step closes that gap.
    > Keep it proportionate: the Intent is one document, so no parallel/phase-gated review
    > machinery is needed.

    **Confluence** (tools in @${CLAUDE_PLUGIN_ROOT}/references/backends/confluence.md):
    1. Fetch comments: `getConfluencePageInlineComments` + `getConfluencePageFooterComments`
       for the Feature page.
    2. Triage each comment: **edit** (changes the doc — scope/NFR/risk/decision) vs
       **clarify** (reply only, no doc change).
    3. Present the triage to the user and get confirmation. **HARD STOP** — apply no edits
       until the user confirms (inherits the publish-gate discipline).
    4. Apply confirmed edits via `updateConfluencePage` (creates a new version). Reflect any
       material decisions in §8 (R#/P#) and bump the doc Version + Version History row.
    5. Reply to and/or resolve each thread (`createConfluenceFooterComment` /
       `createConfluenceInlineComment`).
    6. Note the round in the Workflow Status table (and §9.1 validation record if source-derived).

    **GitLab:** process discussion threads on the Feature MR; apply edits to `intent.md`,
    commit and push, then resolve the threads.
    **Linear:** process comments on the Initiative; edit the description and reply to each.

## Workflow Chain

- **This is the first step** in the AI-DLC planning workflow
- **Next**: `/aidlc-elaborate` (Mob Elaboration - Epic and Task decomposition)

## Definition of Done

- Feature artifact exists and is approved:
  - **GitLab**: `intent.md` committed, MR created, frontmatter `status: approved`
  - **Linear**: Initiative created with status "Active"
  - **Confluence**: Feature page exists with "✅ Approved" status
- Risks, NFRs, measurement criteria, and testing strategy are explicitly documented.
- **If source-derived:** source traceability matrix (§9.3) complete, validation record (§9.1) + checklist (§9.2) present, review outcomes (§8) logged, MVP slice (§9.4) proposed, no blocking `P#` items open.
- Features Index updated with this Feature's entry (registered at creation, before approval).
- Work tracking setup complete (GitLab/Confluence: Jira Project created or declined; Linear: N/A - native).
- Approval to proceed to elaboration is explicitly confirmed.
- **Post-publish comments (if any were raised and the user asked to process them):** triaged, confirmed edits applied (versioned), and threads replied/resolved per Step 12.

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

### Source-derived Intent
- **No source doc provided but expected**: Ask for the BRD/PRD link, or proceed with the lightweight template and note "no source doc" in §0.
- **§4 growing too large**: You are copying the source — summarize and link instead; push field-level detail to Design.
- **Pending items unresolved**: Keep as `P#` with an owner; block approval only on blocking items.

### VCS Note
- When using **Linear** or **Confluence** backends, the Feature skill does not interact with VCS — no `glab` or `gh` commands are used.
- When using **GitLab** backend, `glab` is used for the `ai-dlc-docs` documentation repo (not the source code repo).
- For source code VCS operations (GitHub vs GitLab), see `/aidlc-sprint` and `/aidlc-review` skills and @${CLAUDE_PLUGIN_ROOT}/references/vcs-detection.md.
