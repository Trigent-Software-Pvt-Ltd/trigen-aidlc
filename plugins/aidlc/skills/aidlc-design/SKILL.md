---
name: aidlc-design
description: Guide the Construction Phase with Domain Design, Logical Design, and Architecture Decision Records (ADRs). Supports GitLab (markdown files), Linear (design doc issues), or Confluence (pages). Use after Epics and Sprints are created to bridge planning to implementation. (Triggers - domain design, logical design, create ADR, architecture decision, aidlc design, construction phase, model domain)
---

# AI-DLC Design

Bridge from planning to implementation by creating Domain Designs, Logical Designs, and ADRs for approved Epics. Supports multiple backends: **GitLab** (markdown files in `design/` and `adrs/` directories), **Linear** (design doc Issues with "Design Doc" label), or **Confluence** (child pages).

## Completion Checklist

> **IMPORTANT**: Create tasks for each step at the start using `TodoWrite`. Mark tasks complete as you go using `TodoWrite`. Each task description should reference the corresponding Workflow step.

| # | Task | Depends On | Workflow Reference | Exit Criteria |
|---|------|------------|-------------------|---------------|
| 1 | Validate prerequisites | — | Prerequisites section | Epics exist, "Epic Decomposition: ✅ Complete" |
| 2 | Gather Epic context | 1 | Workflow > Step 1 | Epic, NFRs, constraints collected |
| 2b | Analyze project patterns | 2 | Workflow > Step 2b | Patterns documented (existing repo, reference project, or none) |
| 3 | Assess confidence | 2b | Workflow > Step 3 | Score ≥60%, or questions asked if below |
| 4 | Create Domain Design | 3 | Workflow > Step 4 | Aggregates, entities, value objects, events defined (informed by existing patterns) |
| 5 | Create Logical Design | 4 | Workflow > Step 5 | Patterns selected, NFR solutions documented |
| 5b | Produce Deviation Analysis | 4, 5 | Workflow > Step 5b | Deviations from existing patterns documented, user decisions recorded |
| 5c | Assemble design doc per template | 4, 5, 5b | Workflow > Step 5c | §1 MVP alignment + codebase decision, §2 architecture summary + Mermaid diagram, §10 Carried-from-Intent open items, §11 design AC checklist present (optional §4/§5/§8 when warranted) |
| 6 | Create ADRs | 5b | Workflow > Step 6 | ADR created for each significant decision (including deviations) |
| 7 | Get approval on designs | 4, 5, 5b, 5c, 6 | Workflow > Step 7 | User approves domain model and patterns |
| 8 | Store design artifacts as "In Review" (PUBLISH GATE) | 7 | Workflow > Step 8 | HARD STOP before creating anything. User gives explicit publish approval. Artifacts stored in **"In Review"** state (Confluence: page published, Status field = In Review). |
| 9 | Update workflow status → In Review | 8 | Workflow > Step 9 | Status shows "Domain Design: 🟡 In Review" |
| 9a | Team review & comment resolution | 9 | Workflow > Step 9a | On request: comments fetched, triaged, confirmed edits applied (versioned), threads resolved; loop until no blocking comments |
| 10 | **[Hard Gate] Final design approval → Approved** | 7, 8, 9, 9a | Workflow > Step 10 | User explicitly approves; status flips to "Domain Design: ✅ Approved". REQUIRED before task generation. |
| 11 | Generate Task Specifications | 10 | Workflow > Step 11 | Specs generated at required depth (AC with concrete values, data contracts, error/edge tables, UI states, NFRs); clarify_questions returned |
| 11a | **[Hard Gate] Detail sufficiency & clarify** | 11 | Workflow > Step 11a | All clarify questions / `[ASSUMED]` items resolved with the user or explicitly accepted as labelled assumptions — no silent placeholders |
| 12 | Validate Task Spec schema | 11a | Workflow > Step 12 | All specs pass validation against references/task-spec.md (incl. depth/sufficiency rules) |
| 13 | Propose Sprint groupings | 11 | Workflow > Step 13 | Sprint plan produced; every task assigned to a sprint |
| 14 | Spawn test scope sub-agents | 11, 13 | Workflow > Step 14 | One sub-agent per sprint + one per epic launched in parallel |
| 14a | Consolidate and validate test scopes | 14 | Workflow > Step 14a | No-gap and overlap checks pass; summary table approved by user |
| 14b | Write test scopes to epic artifact | 14a | Workflow > Step 14b | `## Test Scope` written to each epic artifact with sprint subsections and integration scenarios |
| 15 | Refine team size recommendation | 13 | Workflow > Step 15 | Estimate updated with sprint data; >30% delta confirmed by user |
| 16 | Store Task Specs as "In Review" (PUBLISH GATE) | 12, 13, 14b | Workflow > Step 16 | HARD STOP before creating anything. User gives explicit publish approval. Tasks stored in **"In Review"** state (Confluence: pages published, Status = In Review). |
| 17 | Update workflow status → In Review | 16 | Workflow > Step 17 | Status shows "Task Specification: 🟡 In Review" |
| 17a | Team review & comment resolution (task specs) | 17 | Workflow > Step 17a | On request: comments fetched, triaged, confirmed edits applied (versioned), threads resolved; loop until no blocking comments |
| 17b | **[Hard Gate] Final task-spec approval → Approved** | 17a | Workflow > Step 17b | User explicitly approves; status flips to "Task Specification: ✅ Approved". REQUIRED before offering /aidlc-verify. |

## Task Tracking

When this skill is invoked:

1. **Create tasks** for each checklist item using `TodoWrite`
   - Include a reference to the workflow step in the task description (content field)
   - Set activeForm appropriately (e.g., "Validating prerequisites" for content "Validate prerequisites")
   - Example: `"Validate prerequisites (See Prerequisites section)"`
2. **Mark task as in_progress** when starting each step using `TodoWrite` (update status)
3. **Mark task complete** when the exit criteria are met using `TodoWrite` (update status)
4. **Verify all tasks complete** before finishing the skill

This ensures visibility into progress and prevents incomplete execution.

## AI-Drives-Conversation Pattern

This skill follows the AI-DLC principle where AI initiates and directs the conversation:

1. **AI proposes** — Present domain models, patterns, and trade-offs
2. **Human approves** — Validate, select, or adjust
3. **AI elaborates** — Expand designs based on feedback
4. **Human confirms** — Final approval before documentation

## Merit-Based Evaluation Principle

When the user proposes an alternative approach during any interactive step (Steps 4, 5, 5b, 7), evaluate the alternative on its merits rather than defaulting to accommodation:

1. **Do not reflexively agree** — "great point, I'll update it" without analysis undermines the AI's role as an independent analyst
2. **Produce a structured comparison** when alternatives arise:

   > **Approach Comparison**
   >
   > | Factor | Current Proposal | Alternative |
   > |--------|-----------------|-------------|
   > | Alignment with codebase patterns (Step 2b) | ... | ... |
   > | Alignment with standards (Step 2) | ... | ... |
   > | Complexity / effort | ... | ... |
   > | Risk profile | ... | ... |
   >
   > **Recommendation:** [Current / Alternative / Hybrid] — [rationale]

3. **Present the comparison** and let the user decide
4. If the user's alternative is clearly better, say so directly and explain why
5. If the current proposal has clear advantages the alternative doesn't address, say so directly and explain why — honest analysis is the goal; the user makes the final call

## Example Invocations

- "Create the domain model for the authentication epic"
- "Design the logical architecture for the billing service"
- "Generate ADRs for the API migration"
- "Help me model the recommendation engine domain"
- "What architectural patterns should we use for this epic?"

## Backend Detection

This skill detects the backend from existing Feature artifacts (it does NOT prompt for backend selection).

Use @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md to detect the backend from the Feature's frontmatter or metadata. The backend determines where design artifacts are stored:

- **GitLab**: `design/domain-model.md`, `design/architecture.md` at Feature level; `epics/<epic-name>/adrs/adr-001-*.md` per-epic ADRs in the Feature branch
- **Linear**: Design Doc Issues (label: "Design Doc") under the Epic's Project, ADR Issues (title: "ADR-NNN: ...")
- **Confluence**: Child pages of the Feature document (existing workflow)

## References

### Always Load
- @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md - DDD guidance, ADR templates, task templates, tool names
- @${CLAUDE_PLUGIN_ROOT}/references/task-spec.md - Task Specification schema contract (required for steps 11-12)
- @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md - Backend detection logic
- @${CLAUDE_PLUGIN_ROOT}/references/test-classification.md - Test layer classification rules, sprint type → layer mapping, scenario format (required for steps 14-14b)
- @plugins/standards/references/technical-guidance/global.md - Universal architectural standards
- @plugins/standards/references/detection-logic.md - Project type and application profile detection

### Load Based on Backend
- @${CLAUDE_PLUGIN_ROOT}/references/backends/gitlab.md - For GitLab backend
- @${CLAUDE_PLUGIN_ROOT}/references/backends/linear.md - For Linear backend
- @${CLAUDE_PLUGIN_ROOT}/references/backends/confluence.md - For Confluence backend

### Load Based on Project Type (detection via detection-logic.md above)
- @plugins/standards/references/technical-guidance/dotnet.md - For .NET projects
- @plugins/standards/references/technical-guidance/rails.md - For Rails projects
- @plugins/standards/references/technical-guidance/vue.md - For Vue projects
- @plugins/standards/references/technical-guidance/iac.md - For IaC projects (Terraform + Terragrunt)

## Prerequisites

Before starting, validate:

1. **Detect backend** from existing Feature artifact (see Backend Detection section above)

2. **Required artifacts** (varies by backend)

   | Backend | Required Artifacts | Optional (old-flow projects) | How to Verify |
   |---------|-------------------|------------------------------|---------------|
   | GitLab | `intent.md` + `epics/epic-NN-*/epic.md` files in Feature branch | `tasks/task-*.md` files (created here if absent) | `ls` the Feature directory in `"$AIDLC_DOCS_PATH"` |
   | Linear | Initiative + Projects (Epics) | Issues under Projects (created here if absent) | Fetch via Linear MCP `get_initiative` |
   | Confluence | Feature page + Epics Overview with Epic child pages | Task child pages (created here if absent) | Fetch via Atlassian MCP |

   > **Old-flow projects (pre-3.9):** Task files/issues/pages may already exist from the elaborate phase. Step 11 detects existing tasks and offers to regenerate them as Task Specifications. Both formats are valid through AIDLC 3.9.x.

3. **Required status**
   - Verify "Epic Decomposition" shows "✅ Complete" in the workflow status

4. **If prerequisites incomplete**
   - Offer to run `/aidlc-elaborate` first (or `/aidlc-intent` if Feature missing)
   - Or allow override with explicit confirmation (see Override Pattern in @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md)

5. **Resume detection (half-done design)**
   Check the Feature status for this epic:
   - **"Domain Design: ✅ Approved" but "Task Specification" not ✅** → the previous run stopped
     at the Step 10 half-way point. **Skip the design half and resume at Step 11 (Generate Task
     Specifications).** Tell the user: "Domain Design is already approved for this epic —
     resuming at Task Specification generation."
   - **Neither approved** → start from Step 1 (full run).
   - **Both approved** → design is complete; point the user to `/aidlc-verify`.

## Workflow

1. **Gather context**
   Ask only for what is missing:
   - Epic to design (GitLab: from epic `.md` files / Linear: from Projects / Confluence: from Epics Overview page)
   - Tasks within the Epic (GitLab: from `tasks/` directory / Linear: from Project Issues / Confluence: from child pages)
   - Relevant NFRs (performance, security, scalability, etc.)
   - **Service inventory** from the Feature document — identifies which repos are in scope and their pathway types (brown-field vs. green-field)
   - **Elaborate's structural findings** (if available) — look for "Service Context: \<name\>" child pages under the Epics Overview. These provide structural orientation (directory layout, naming conventions, module inventory) from the elaborate phase. Use for orientation only — Design conducts its own implementation-pattern analysis in Step 2b.
   - Project-level technical guidance (from Feature doc "Technical Guidance" section)
   - **Intent MVP slice** — read the Feature/Intent doc's MVP / first-delivery slice (Intent §9.4 if the Intent was source-derived). The design **implements this MVP**, explicitly deferring the rest. If no MVP slice exists, treat the full approved scope as the build.
   - **Intent open items** — read the Intent's open/pending items (§8.2 `P#`). Each is carried into the design with a concrete design action (see the "Carried from Intent" section of the Design Document Template).

2. **Detect and confirm project type**

   > **Step 2 establishes the "what should be"** — organizational standards and stack-specific guidance. This is the normative baseline: what patterns the codebase SHOULD follow.

   Use the detection logic from `detection-logic.md` (loaded above) to scan the repository for project-type markers and determine the project type. For .NET projects, also run Application Profile Detection to identify the specific profile.

   Present the detected type and applicable guidance, then ask for confirmation:

   > Based on the repository, this appears to be a **[.NET / Rails / IaC / Other]** project[**, [profile name] profile**].
   >
   > Applicable technical guidance (in precedence order):
   > 1. Global standards (all projects)
   > 2. [Stack] standards ← if detected
   > 3. [Application profile] ← if detected (.NET only)
   > 4. Project-level guidance (from Feature doc)
   >
   > Is this correct?

2b. **Analyze project patterns**

   > **Step 2b discovers the "what is"** — actual patterns, conventions, and implementation approaches in the existing codebase. This is the empirical baseline: what the codebase ACTUALLY does today.
   >
   > If "Service Context" pages exist from `/aidlc-elaborate`, use them as a starting point for orientation (directory layout, module inventory). However, Design asks DIFFERENT questions than Elaborate — implementation patterns (DI wiring, handler patterns, data access approaches, test strategies), not just structural awareness.
   >
   > The deviation analysis in Step 5b compares the PROPOSED design against Step 2b's empirical baseline.

   Establish a pattern baseline before proposing designs. The approach depends on whether this Epic modifies existing code or creates something new.

   **For brown-field Epics** (modifying existing code), spawn an Explore sub-agent for each repo. **Spawn all repo sub-agents in a single message** for parallel execution.

   ```
   Task tool call:
     subagent_type: "Explore"
     description: "Analyze <repo-name> implementation patterns"
     prompt: |
       Perform a very thorough implementation-pattern analysis of the repository at <repo-path>.

       <If Service Context pages exist from /aidlc-elaborate, include their content here as orientation context — directory layout, module inventory, and structural observations. This avoids re-scanning structure and lets you focus on implementation patterns.>

       Analyze and return findings in this exact format:

       ## Static & Dynamic Models
       - **Static**: Components, responsibilities, relationships
       - **Dynamic**: How components interact for key use cases

       ## Current Patterns

       | Aspect | Current Pattern | Notes |
       |--------|----------------|-------|
       | Architecture | (e.g., layered, CQRS, hexagonal) | |
       | DI Container | (e.g., SimpleInjector, Microsoft DI) | |
       | Handler/Controller | (e.g., MediatR, custom BaseHandler) | |
       | Data Access | (e.g., EF Core, Dapper, raw ADO.NET) | |
       | Folder Structure | (e.g., feature folders, layer folders) | |
       | Naming Conventions | (e.g., `{Entity}Handler.cs`, `I{Service}`) | |
       | Test Organization | (e.g., test project per source, integration vs epic) | |

       ## Extension Points
       Where does the existing architecture expect new features to be added?
       (e.g., new handler classes, new service registrations, new migration files)

       ## Anti-Corruption Layer Needs
       If new domain models will coexist with legacy models, describe:
       - Translation needs between legacy and new domain models
       - Isolation boundaries for the new domain
       - Gradual migration approach

       Do NOT return raw file contents or grep output — summarize findings into architectural observations.
   ```

   The main agent receives only the structured summary from each sub-agent — raw file reads and grep output stay inside the sub-agent context.

   **Iterative exploration**: If the initial sub-agent analysis is insufficient for a specific aspect (e.g., unclear DI wiring, ambiguous handler patterns, complex inheritance chains), spawn a second focused Explore sub-agent targeting that specific area rather than reading files directly in the main context. For example: "Investigate the DI registration pattern in <repo-path>/src/Startup.cs and related composition roots. How are handlers registered? Is there auto-discovery or explicit registration?"

   **For green-field Epics** (net-new component or service):

   1. **Ask for reference context**: "This Epic is green-field. Is there a reference project, organizational template, or existing service whose patterns should inform this design?"

   2. **If reference provided** — spawn an Explore sub-agent for the reference project (same pattern as brown-field above). Include in the sub-agent prompt: "This is a reference project being analyzed as a model for a new green-field Epic. Focus on implementation patterns that should transfer: DI approach, handler patterns, data access, and test organization."

   3. **If no reference** — note that the design is unconstrained by existing patterns. The technical guidance hierarchy (global/stack/profile) still applies as the baseline.

   **For mixed Epics** (both brown-field and green-field work):

   Spawn brown-field Explore sub-agents for existing codebases AND ask about reference patterns for the new components. Both can run in parallel. The deviation analysis in Step 5b will distinguish between changes to existing code and net-new additions.

   **This analysis informs the Domain Design (Step 4) and feeds the Deviation Analysis (Step 5b).**

3. **Assess confidence**
   Before proceeding to Domain Design, assess whether you have sufficient context.

   ### Required Context Checklist

   For the Epic being designed, verify:
   - [ ] Epic scope is bounded (no "and more", "etc.", open-ended language)
   - [ ] At least 2 Tasks exist with acceptance criteria
   - [ ] NFRs have measurable targets (not just "fast" or "secure")
   - [ ] Integration points are identified (APIs, services, databases)
   - [ ] **Implementation detail is resolvable** — data contracts (field names/types), concrete values (TTLs, thresholds, enum/entitlement lists), and error/edge cases are either specified upstream or can be turned into explicit clarify questions. Vague ACs and undefined contracts are gaps, not "documented."
   - [ ] For brownfield: existing code patterns are understood

   ### Confidence Scoring

   Rate each factor 0-20 points. **Score for depth, not just presence** — a section that exists but is vague (e.g. an "API surface" with only method/path and no schemas, or ACs without concrete values) scores in the lower half, not full marks.

   | Factor | Score | Notes |
   |--------|-------|-------|
   | Epic scope clarity | /20 | Clear boundaries, defined outcomes |
   | Task quality | /20 | Testable acceptance criteria **with concrete values**, not paraphrase |
   | Detail sufficiency | /20 | Data contracts (typed fields, status codes) and error/edge cases specified or clarifiable — **not** hand-waved |
   | NFR specificity | /20 | Measurable targets with baselines |
   | Technical context | /20 | Integration points, dependencies, architectural constraints known |
   | **Total** | /100 | |

   ### Confidence Thresholds

   - **≥60%**: Proceed with design, noting any gaps in the design documentation
   - **<60%**: STOP - ask targeted questions before continuing

   If confidence is low, ask specific questions like:
   - "What is the expected response time for this API?"
   - "Which existing services will this Epic integrate with?"
   - "Are there security requirements beyond standard authentication?"
   - "What data storage approach is preferred (SQL, NoSQL, etc.)?"

4. **Domain Design** (DDD)
   AI proposes domain model using DDD principles:
   - Identify Bounded Context boundaries
   - Define Aggregates and Aggregate Roots
   - Model Entities and Value Objects
   - Identify Domain Events
   - Define Repositories and Factories
   - Apply Ubiquitous Language from the Feature

   Present the model and ask for validation before proceeding.

5. **Logical Design**
   Incorporate technical guidance (in precedence order):

   | Tier | Source | Precedence |
   |------|--------|------------|
   | Global | `@plugins/standards/references/technical-guidance/global.md` | Baseline (all projects) |
   | Project-Type | `dotnet.md`, `rails.md`, `vue.md`, or `iac.md` from standards plugin | Extends global |
   | Project-Level | Feature doc "Technical Guidance" section | Highest precedence |

   **Guidance application:**
   - Apply global guidance as the baseline
   - Layer project-type guidance (dotnet.md / rails.md / vue.md / iac.md) over the global baseline
   - Apply project-level overrides from the Feature doc
   - When guidance conflicts: project-level > project-type > global

   **Conflict detection:**
   When project-level guidance contradicts a global or project-type standard:
   1. Surface the conflict explicitly:
      > **Guidance Conflict Detected**
      >
      > - **[Global / Project-Type] standard:** [the standard]
      > - **Project-level guidance:** [conflicting guidance]
      >
      > This deviation will require an ADR. Proceed with the project-level guidance?
   2. If confirmed, flag for ADR creation in step 6

   **Design recommendations:**
   Using the merged guidance, extend the domain model for NFRs:
   - Recommend architectural patterns (CQRS, Event Sourcing, Saga, etc.)
   - Propose integration patterns (API Gateway, Circuit Breaker, etc.)
   - Suggest data storage approach aligned with guidance
   - Address security architecture per guidance standards
   - Consider observability requirements from guidance

   Present trade-offs and ask for decisions.

5b. **Produce Deviation Analysis**

   After completing the domain design and logical design, compare the proposed approach against the pattern baseline documented in Step 2b (existing codebase patterns, reference/template patterns, or both). Produce a structured deviation analysis:

   > **Deviation Analysis: Proposed Design vs. Existing Patterns**
   >
   > | Aspect | Existing Pattern | Proposed Pattern | Rationale for Deviation | Recommendation |
   > |--------|-----------------|-----------------|------------------------|----------------|
   > | DI Container | SimpleInjector | Microsoft DI | .NET 10 migration; SimpleInjector no longer maintained | Adopt proposed |
   > | Handler Pattern | Custom BaseHandler<T,R> | MediatR IRequestHandler | Standard pattern; reduces custom code | Discuss with team |
   > | Folder Structure | Feature folders | Layer folders | Better separation for this Epic's scope | Keep existing |
   >
   > For each deviation, would you like to (a) adopt the proposed approach, (b) keep the existing pattern, or (c) discuss further?

   **Present the deviation analysis to the user for review.** Do not proceed to ADR creation until the team has decided on each deviation. Accepted deviations should be documented as ADRs in Step 6.

   **Record the full deviation analysis table** (with a "Decision" column added) in the design documentation stored in Confluence (Step 8). This provides traceability — the team can see what was proposed, what existed, and what was decided.

   **If no pattern baseline exists** (green-field with no reference): Skip this step. The design is evaluated only against the technical guidance hierarchy.

5c. **Assemble the design document per the Design Document Template**

   Structure the design output using the **Design Document Template** in
   @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md. Beyond the domain/logical model
   already produced, ensure these sections are present:

   - **§1 Design scope & MVP alignment** — restate the Intent MVP slice (from Step 1) as an
     **In-MVP-vs-Deferred** table, and state the **codebase decision** (green-field vs
     brown-field; for green-field, the target repo/module layout).
   - **§2 Architecture summary** — architecture style + a **system architecture diagram as a
     Mermaid ```mermaid flowchart```** (renders in GitHub and Confluence) + a layer/component
     responsibilities table + external integrations.
   - **§10 Carried from Intent (open in Design)** — a table of the Intent open items (`P#`
     from Step 1), each with a concrete **design action** (resolve now with ADR / defer to
     Tasks / config-driven / no code impact).
   - **§11 Design acceptance criteria (phase gate)** — a checkbox list proving the design
     phase is complete (MVP boundary reflected, domain model supports required behaviour, NFR
     targets traceable to Intent/BRD, ADRs recorded, open items dispositioned).

   Include the optional sections (§4 State machines, §5 Functional design by area, §8 API
   surface) **when the domain warrants them** — e.g. entities with non-trivial lifecycles,
   or a design that defines service endpoints.

6. **Create ADRs**
   For each significant decision, create an ADR:
   - Context: What prompted this decision?
   - Decision: What was decided?
   - Consequences: Trade-offs and implications
   - Alternatives considered

   **Guidance deviation ADRs:**
   For each conflict flagged in step 5 and each accepted deviation from step 5b, create an ADR with:
   - **Context:** Reference the specific standard being deviated from (tier, section)
   - **Decision:** The project-level choice and why it takes precedence
   - **Consequences:** Include risks of deviating from organizational standards
   - **Alternatives:** Document "follow the standard" as a rejected alternative with rationale

   Example title: "ADR-NNN: Use GraphQL instead of REST (deviation from Global API Standards)"

   Use the ADR Template in @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md.

7. **Confirm understanding**
   Summarize:
   - Domain model components
   - Architectural patterns selected
   - Technical guidance applied (with tiers noted)
   - Any guidance deviations and their ADRs
   - Key ADRs
   Ask for approval before storing artifacts.

   If the user proposes changes during approval, apply the **Merit-Based Evaluation Principle** (above) rather than accepting all changes uncritically.

8. **Store artifacts** (backend-specific)

   > **HARD STOP — publish gate.** Do not create/commit/push any design artifact until the user gives explicit approval. Ask a blocking confirmation:
   >
   > > "Here are the finalized design artifacts (domain model, logical design, ADRs). Reply **'publish'** and I'll store them **as \"In Review\"** in the [GitLab design/+adrs/ files / Linear Design Doc issues / Confluence child pages] so the team can review and comment. This is **not** final sign-off — I'll ask for that in Step 10 after comments are resolved. I will not create or update anything until you confirm."
   >
   > - Answering clarifying questions is NOT approval. Only "publish" / "approved" / "go ahead" proceeds.
   > - If the user requests changes, revise, re-present, and re-ask. Loop until explicit approval is given in this session.

   > **Draft → Review → Approve lifecycle.** Publishing here does NOT mark the design approved.
   > It stores the artifacts in an **"In Review"** state so the team can comment. A true
   > *unpublished* Confluence draft is invisible to reviewers and can't be commented on, so we
   > publish the page and use a **Status field/label of "In Review"** instead. Final approval
   > (Step 10) flips the status to "✅ Approved" after comments are resolved (Step 9a).

   **GitLab** (see @${CLAUDE_PLUGIN_ROOT}/references/backends/gitlab.md):
   1. Ensure on the Feature branch: `git checkout <intent-branch>`
   2. Create design files:
      - `design/domain-model.md` — Domain model with frontmatter (`type: design`, `design_type: domain-model`)
      - `design/architecture.md` — Logical design with frontmatter (`type: design`, `design_type: architecture`)
      - `epics/<epic-name>/adrs/adr-NNN-<slug>.md` — ADRs with frontmatter (`type: adr`, `adr_number: N`)
   3. Commit and push: `git add . && git commit -m "feat(design): Add domain model and ADRs for <Epic>" && git push`
   4. Update epic `.md` file with links to design docs

   **Linear** (see @${CLAUDE_PLUGIN_ROOT}/references/backends/linear.md):
   1. Create Design Doc Issues under the Epic's Project:
      - Title: "Design: Domain Model" / "Design: Logical Design"
      - Description: Full markdown content
      - Labels: `["Design Doc"]`
      - Use `save_issue` with project ID
   2. Create ADR Issues:
      - Title: "ADR-NNN: <Decision Title>"
      - Description: Full ADR content
      - Labels: `["Design Doc", "ADR"]`
   3. Link design docs to related Task Issues

   **Confluence** (existing workflow):
   - Domain model: Confluence child page of Feature doc
   - ADRs: Confluence pages or repo `docs/adr/` folder
   - Guidance deviation ADRs: Include reference to the standard being deviated from
   - Link back to Epic page in Confluence
   - Update Epic page with design doc links
   - **Publish in review state:** the page is published (visible to reviewers) but its
     **Status field is set to "In Review"**, not "Approved". Do NOT create an unpublished
     Confluence draft — reviewers cannot see or comment on it.

9. **Update workflow status** (backend-specific)

   Set the design status to **In Review** (published for team review, not yet approved):

   | Backend | Action |
   |---------|--------|
   | GitLab | Update `intent.md` frontmatter: set design phase status to "🟡 In Review" |
   | Linear | Update Initiative description: set "Domain Design" to "🟡 In Review" |
   | Confluence | Update Confluence page status table: set "Domain Design" to "🟡 In Review" |

   > Status flips to "✅ Approved" in Step 10, after the comment round in Step 9a.

9a. **Team review & comment resolution (before final approval)**

    The design is now published "In Review." Reviewers comment asynchronously on the artifact.
    When the user asks to process review comments (or before requesting final approval), run
    this lightweight loop — the same pattern as `/aidlc-intent` Step 12.

    **Confluence** (tools in @${CLAUDE_PLUGIN_ROOT}/references/backends/confluence.md):
    1. Fetch comments: `getConfluencePageInlineComments` + `getConfluencePageFooterComments`
       on each design/ADR page.
    2. Triage each comment: **edit** (changes the design — model/pattern/ADR decision) vs
       **clarify** (reply only, no change).
    3. Present the triage and get confirmation. **HARD STOP** — apply no edits until confirmed.
    4. Apply confirmed edits via `updateConfluencePage` (creates a new version). If an ADR
       decision changes, update/supersede the ADR accordingly.
    5. Reply to and/or resolve each thread (`createConfluenceFooterComment` /
       `createConfluenceInlineComment`).
    6. Note the round on the Epic/design page.

    **GitLab:** process discussion threads on the design MR; apply edits to `design/`+`adrs/`,
    commit and push, then resolve the threads.
    **Linear:** process comments on the Design Doc issues; edit the description and reply.

    Loop review rounds until no blocking comments remain, then proceed to Step 10.

10. **Hard gate: Await explicit design approval before task generation**

    Present a summary of the completed design artefacts and explicitly pause:

    > **Design Phase Complete — Review Required**
    >
    > The following design artefacts have been created and stored:
    > - Domain Model: [link or summary]
    > - Logical Design: [link or summary]
    > - ADRs: [list titles]
    > - Deviation Analysis: [summary of decisions]
    >
    > Before generating Task Specifications, please confirm:
    > 1. Team review comments have been resolved (Step 9a)
    > 2. The domain model accurately reflects the intended scope
    > 3. The architectural patterns are acceptable
    > 4. ADRs have been reviewed and decisions are recorded
    >
    > **Reply "approved" or "yes" to finalize the design and proceed to task generation, or provide feedback to revise.**

    On explicit approval, **flip the design status from "🟡 In Review" to "✅ Approved"** in the
    backend (GitLab frontmatter / Linear description / Confluence status table) before continuing.
    At the same time, ensure the status table shows the **two distinct design outcomes** so it is
    obvious the phase is only half done:

    | Phase | Status |
    |-------|--------|
    | Domain Design | ✅ Approved |
    | Task Specification | ⬜ Not started |

    > **⚠️ HALF-WAY SIGNPOST — the design phase is NOT finished after this approval.**
    > `/aidlc-design` has two halves in one run: **(1) Domain Design** (just approved) and
    > **(2) Task Specifications** (steps 11–17b, not yet generated). If you continue now, proceed
    > straight to Step 11. **If the run stops here (session ends / you step away), the epic is only
    > half designed** — you must invoke `/aidlc-design` again for this epic to generate and approve
    > the Task Specs. When pausing here, print this banner verbatim to the user:
    >
    > > ✅ **Domain Design approved for <Epic>.** Task Specifications are **NOT yet generated**.
    > > This epic is **not ready for `/aidlc-verify`** until its Task Specifications are also
    > > approved. To continue, run **`/aidlc-design`** again for this epic (it resumes at task
    > > generation). Feature status now shows: **Domain Design ✅ / Task Specification ⬜**.

    Do not proceed to step 11 until explicit approval is received. If the user provides feedback, return to the relevant design step (or Step 9a for comment items), revise, re-store, and re-present.

11. **Generate Task Specifications**

    Use the `task-spec-generator` subagent. Spawn one subagent per Epic in parallel (single message). Each subagent receives:
    - Epic definition (scope, acceptance criteria, dependencies, risks)
    - Domain model (aggregates, entities, value objects, events relevant to this Epic)
    - Logical design (patterns selected, NFR solutions, integration approach)
    - ADRs (decisions that affect task scope or implementation)
    - NFRs specific to this Epic
    - Feature context (scope boundaries, out-of-scope items)
    - Existing Task Spec ids from other Epics (for id sequencing)
    - Project pattern baseline from Step 2b (full pattern table: architecture style, DI container, handler/controller patterns, data access approach, folder structure, naming conventions) — passed as routing heuristics for file path discovery, not as ground truth. Omit if no baseline exists (unconstrained green-field).

    Reference `@${CLAUDE_PLUGIN_ROOT}/references/task-spec.md` for the schema contract.

    The `files` section should be populated from the design output:
    - Domain model → aggregates/entities map to source files
    - Logical design → patterns/services map to file paths
    - Use module-level hints (e.g. `src/Api/Auth/`) when design is high-level rather than omitting `files`

    If the project has existing user story tasks (detected by "As a..." or "Given/When/Then" content), offer to regenerate them as Task Specs. The user can decline and keep the old format — both are supported through AIDLC 3.9.x.

    Each generator produces specs at the depth in `@${CLAUDE_PLUGIN_ROOT}/references/task-spec.md` (acceptance criteria with concrete values, data contracts, error/edge tables, UI states, per-task NFRs) and returns a `clarify_questions` array for any value it had to assume.

11a. **[Hard Gate] Detail sufficiency & clarify — no silent placeholders**

    Before validating and publishing specs, consolidate the `clarify_questions` returned by all
    `task-spec-generator` agents (plus any `[ASSUMED]` items in the specs). Then:

    1. If there are **no** open questions, continue to Step 12.
    2. If there are open questions, **STOP and ask the user** — present each as a concrete
       question with the proposed default, using `AskUserQuestion` where possible. For example:
       > "A few details weren't specified upstream. I've filled sensible defaults — confirm or correct:
       > • Session TTL — proposed **30 min**
       > • Rate limit — proposed **20 req/min/IP**
       > • Standard vs Enterprise feature list — proposed **[…]**"
    3. Apply the user's answers to the affected specs. For any item the user chooses to leave as
       a default, keep it under `## Assumptions` labelled `[ASSUMED]` so it stays visible.

    **Do not proceed to Step 12 with unresolved, unlabelled gaps.** The goal: every spec is either
    grounded in a confirmed value or carries an explicit, user-acknowledged assumption — never a
    silent placeholder or vague filler. This is the sufficiency gate that keeps the downstream
    Jira stories unambiguous.

12. **Validate Task Spec schema**

    For each generated Task Spec, validate against `@${CLAUDE_PLUGIN_ROOT}/references/task-spec.md`:
    - `id` matches `U\d{2}-T\d{2}`
    - `title` is ≤80 characters
    - `sprint` references a sprint id (confirmed in step 13)
    - `size` is a valid Fibonacci value (1, 2, 3, 5, 8, 13)
    - `## Behaviour` is present with at least one bullet
    - If `dependencies` is present, each entry has `on`, `type`, and `rationale`
    - No unknown frontmatter fields

    Fix validation failures before proceeding. Surface any size-13 tasks for splitting consideration.

13. **Propose Sprint groupings**

    Review the preliminary `sprint` values from the subagents and produce the confirmed sprint plan:
    - Group tasks with high coupling and similar scope into the same sprint
    - Identify phase dependencies (what must be built before what)
    - Assign lane if tasks can run in parallel within a phase
    - Produce a Sprint Plan table: Sprint ID, Epic, Phase, Lane, Tasks, Dependencies, Estimated duration

    Present the sprint plan for user review before proceeding. Update `sprint` field on each Task Spec if assignments change.

14. **Spawn test scope sub-agents**

    Determine the **sprint type** for each sprint by inspecting its tasks:
    - Tasks touching controllers, services, repositories, or data layers → `backend`
    - Tasks touching components, views, templates, or client-side logic → `frontend`
    - Tasks spanning both server-side and client-side concerns → `fullstack` (prefer this when in doubt)

    **Spawn all sub-agents in a single message** for parallel execution:

    **For each Sprint**, spawn one sub-agent:

    ```
    Task tool call:
      subagent_type: "general-purpose"
      description: "Generate test scenarios for <sprint_name>"
      prompt: |
        Generate layered test scenarios for the following Sprint.
        Use the test layer classification rules from @plugins/aidlc/references/test-classification.md.

        Sprint: <sprint_name>
        Sprint Type: <sprint_type>  (backend | frontend | fullstack)
        Tasks and Acceptance Criteria: <task list with AC from Task Specs>

        Return a markdown table: Scenario | Layer | Priority | Notes
        - Layer must be one of: Unit, API, UI, E2E
        - For E2E rows, include "requires_browser: true/false" in Notes
        - Apply no-gap rule: every AC must map to at least one scenario
        - Apply no-overlap rule: each scenario belongs to exactly one layer
    ```

    **For each Epic**, spawn one additional sub-agent for integration scenarios:

    ```
    Task tool call:
      subagent_type: "general-purpose"
      description: "Generate epic-level integration scenarios for <epic_name>"
      prompt: |
        Generate cross-sprint integration test scenarios for the following Epic.
        Focus on interactions between Sprints — intra-sprint scenarios are covered per-Sprint above.

        Epic: <epic_name>
        Sprints and their objectives: <list of sprints with summaries>

        Return a markdown table: Scenario | Layer | Priority | Notes
        Use "Integration" as the Layer value for all rows.
    ```

14a. **Consolidate and validate test scopes**

    After all sub-agents return:

    1. **Cross-level overlap check**: Flag any scenario that appears in more than one sprint's table for the same Epic — duplicates create maintenance burden without adding coverage
    2. **No-gap check**: For each sprint, verify every Acceptance Criterion in the sprint's Task Specs maps to at least one scenario. Flag any uncovered ACs.
    3. **Present summary table** to user:

    ```
    ## Test Scope Summary

    | Epic | Sprint | Type | Unit | API | UI | E2E | Integration |
    |------|------|------|------|-----|----|-----|-------------|
    | Auth | Sprint 1.1: Login | backend | 4 | 3 | — | 2 | — |
    | Auth | Sprint 1.2: SSO | fullstack | 3 | 2 | 2 | 3 | — |
    | Auth | (epic-level) | — | — | — | — | — | 2 |
    ```

    4. **Ask for approval**: "Test scenarios generated for all Sprints. Does this look complete, or are there scenarios to add or remove before I write these to the documentation?"

    Do not proceed to Step 14b until the user explicitly approves. If gaps or overlaps were flagged, resolve them before re-presenting.

14b. **Write test scopes to epic artifact**

    After user approval in Step 14a, write the complete `## Test Scope` section to each epic's artifact. This is the section `/aidlc-verify` checks for confidence scoring and the exact structure `task-creator` parses when posting test scope comments to Jira.

    **Required structure** (must match exactly for `task-creator` to parse correctly):

    ```markdown
    ## Test Scope

    > _Generated by AI-DLC Design | <date>_

    ### <Sprint Name>
    | Scenario | Layer | Priority | Notes |
    |----------|-------|----------|-------|
    | <scenario> | Unit | High | |
    | <scenario> | API | Medium | |
    | <scenario> | E2E | High | requires_browser: false |

    ### <Next Sprint Name>
    | Scenario | Layer | Priority | Notes |
    |----------|-------|----------|-------|
    | ... | | | |

    ### Epic-Level Integration Scenarios
    | Scenario | Layer | Priority | Notes |
    |----------|-------|----------|-------|
    | <cross-sprint flow> | Integration | High | |
    ```

    Use the sprint's **exact name** as the `### <Sprint Name>` heading — `task-creator` matches on this string to post the right scenarios to the right Jira Sprint ticket.

    **Backend-specific write:**

    | Backend | Action |
    |---------|--------|
    | GitLab | Append `## Test Scope` section to `epics/<epic-name>/epic.md` and commit |
    | Linear | Post the full test scope as a comment on the Project (Epic) |
    | Confluence | Add or update `## Test Scope` section on the Epic page |

15. **Refine team size recommendation**

    Compare the preliminary team size estimate (from elaborate) against the actual sprint plan:
    - Count lanes (parallel streams)
    - Count phases (sequential dependencies)
    - Identify specialist requirements (e.g. infrastructure, security, frontend)
    - Estimate person-weeks based on total task sizes and lane structure

    If the revised estimate differs from the elaborate estimate by more than 30% in person-weeks, surface the discrepancy before proceeding:

    > **Team Size Update**
    >
    > Elaborate estimate: X person-weeks
    > Design estimate: Y person-weeks (Z% difference)
    >
    > Reason: [what the sprint structure reveals]
    >
    > Confirm the updated estimate to continue.

16. **Store Task Specification artefacts** (backend-specific)

    > **HARD STOP — publish gate.** Present the full set of Task Specifications and Sprint groupings, then STOP and ask a blocking confirmation before creating anything:
    >
    > > "Here are the Task Specifications and Sprint plan. Reply **'publish'** and I'll create the [GitLab task files / Linear Issues / Confluence Task pages] **as \"In Review\"** so the team can review and comment. This is **not** final sign-off — I'll ask for that in Step 17b after comments are resolved. I will not create or update anything until you confirm."
    >
    > - Answering clarifying questions is NOT approval. Only "publish" / "approved" / "go ahead" proceeds.
    > - If the user requests changes, revise, re-present, and re-ask. Loop until explicit approval is given in this session.

    > **Draft → Review → Approve lifecycle.** As with the design artifacts, publishing stores
    > the Task Specs in an **"In Review"** state (Confluence: page published with Status field
    > "In Review", never an unpublished draft). Final approval (Step 17b) flips to "✅ Approved".

    Spawn creator subagents in parallel — one per Epic. Pass the validated Task Specs for that Epic.

    **GitLab**: Create `epics/<epic-name>/tasks/task-U0N-T0N-<slug>.md` in the Feature branch for each task. Use Task Spec frontmatter + body format from `references/task-spec.md`. Commit and push.

    **Linear**: Create Issues under the appropriate Epic Project. Map `behaviour` → "## Behaviour" section in description; `rules` → "## Rules"; `files` and `dependencies` → body sections. See `@${CLAUDE_PLUGIN_ROOT}/references/backends/linear.md`.

    **Confluence**: Create Task child pages under each Epic page using the Task Page Template from `references/planning-shared.md`. See `@${CLAUDE_PLUGIN_ROOT}/references/backends/confluence.md`.

17. **Update workflow status → In Review** (backend-specific)

    Set the task-spec status to **In Review** (published for team review, not yet approved):

    | Backend | Action |
    |---------|--------|
    | GitLab | Update `intent.md` frontmatter: set task spec status to "🟡 In Review" |
    | Linear | Update Initiative description: set "Task Specification" to "🟡 In Review" |
    | Confluence | Update Confluence page status table: set "Task Specification" to "🟡 In Review" |

17a. **Team review & comment resolution (task specs)**

    Task Specs are now published "In Review." When the user asks to process review comments
    (or before requesting final approval), run the same lightweight loop as Step 9a:
    - **Confluence:** `getConfluencePageInlineComments` + `getConfluencePageFooterComments` on
      each Task page → triage edit vs clarify → confirm (HARD STOP, no edits until confirmed) →
      `updateConfluencePage` (versioned) → reply/resolve threads.
    - **GitLab:** MR discussion threads on the task files; edit, commit/push, resolve.
    - **Linear:** comments on the Task Issues; edit descriptions and reply.

    Loop until no blocking comments remain, then proceed to Step 17b.

17b. **Final approval → Approved** (hard gate)

    Present the resolved Task Specs and ask a blocking confirmation:

    > **Task Specifications — Review complete.** Comments have been resolved. Reply
    > **"approved"** to finalize the Task Specifications, or provide feedback to revise.

    On explicit approval, **flip the task-spec status from "🟡 In Review" to "✅ Approved"**
    (GitLab frontmatter / Linear description / Confluence status table). Do not offer
    `/aidlc-verify` until this approval is received.

    Then provide links to all created artefacts and offer to run `/aidlc-verify`:
    - **GitLab/Confluence**: Jira transfer
    - **Linear**: Status update (no Jira transfer needed)

## Workflow Chain

- **Previous**: `/aidlc-elaborate` (Epic creation)
- **Next**: `/aidlc-verify` (Verification and Jira transfer / Linear status update)

## Definition of Done

**Design phase (steps 1-9):**
- Backend detected from existing Feature artifact
- Project type detected (.NET, Rails, IaC, or other) and confirmed
- Technical guidance loaded (global → project-type → project-level)
- Project patterns analyzed and documented (existing repo, reference project, or N/A for unconstrained green-field)
- Confidence assessment completed (≥60% to proceed)
- Domain model documented and approved (informed by pattern baseline where available)
- Logical design with architectural patterns documented
- Deviation analysis produced comparing proposed vs. pattern baseline (if baseline exists)
- Deviation decisions recorded and accepted deviations documented as ADRs
- Guidance conflicts surfaced and confirmed
- ADRs created for key decisions
- Deviation ADRs created for any guidance conflicts with Global standards
- Design artifacts stored in correct backend (GitLab: files committed / Linear: Issues created / Confluence: pages created)
- Artifacts linked to Epic (GitLab: epic .md updated / Linear: Issues linked / Confluence: page links)
- Brown-field ACL designed (if applicable)
- Design document assembled per the Design Document Template: **§1 MVP alignment** (In-MVP-vs-Deferred + codebase decision), **§2 architecture summary with a Mermaid diagram**, **§10 Carried-from-Intent** open items (each with a design action), and **§11 design acceptance-criteria** checklist (optional §4 state machines / §5 functional-by-area / §8 API surface where warranted)
- Design published in **"In Review"** state; team review comments resolved (Step 9a)
- Workflow status updated: "Domain Design: ✅ Approved" (flipped from In Review at Step 10 after final approval)

**Task specification phase (steps 10-17b):**
- Explicit design approval received from user (hard gate)
- Task Specifications generated for all Epics (using `task-spec-generator` subagents) at required depth — acceptance criteria with concrete values, data contracts, error/edge tables, UI states, and per-task NFRs where applicable
- Detail-sufficiency gate cleared (Step 11a): every clarify question / `[ASSUMED]` item resolved with the user or explicitly accepted as a labelled assumption — no silent placeholders
- All Task Specs validated against `references/task-spec.md` schema
- Sprint plan produced with all tasks assigned to a sprint
- Test scope sub-agents spawned in parallel (one per sprint + one per epic)
- No-gap check passed: every AC in every sprint maps to at least one scenario
- No-overlap check passed: no scenario duplicated across sprints
- Test scope summary table presented and approved by user
- Complete `## Test Scope` written to each epic artifact (GitLab: `epic.md` / Linear: Project comment / Confluence: Epic page) with per-sprint subsections and `### Epic-Level Integration Scenarios`
- Team size recommendation refined with sprint data; >30% delta confirmed by user
- Task Specification artefacts stored in correct backend in **"In Review"** state
- Team review comments on task specs resolved (Step 17a)
- Final task-spec approval received (Step 17b); workflow status updated: "Task Specification: ✅ Approved"

## Troubleshooting

- **Complex domain**: Break into smaller Bounded Contexts; consider multiple Epics
- **Conflicting NFRs**: Surface trade-offs explicitly; create ADR for resolution
- **Legacy integration**: Step 2b handles ACL design before domain modeling begins
- **Missing context**: Gather more repo context or request architecture diagrams
- **Many deviations**: If the deviation analysis shows extensive departures from existing patterns, discuss whether a broader refactoring approach is warranted before continuing
