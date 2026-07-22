---
name: aidlc-help
description: Explain AI-DLC methodology, available skills, and how to use this plugin. Use when users ask "what is AI-DLC", "how do I use planning", "what skills are available", or need guidance on the workflow. (Triggers - aidlc help, what is aidlc, explain aidlc, planning help, how to plan, ai-dlc)
---

# AI-DLC Help

Explain the AI-DLC methodology and guide users through the planning plugin.

## References

- Use @${CLAUDE_PLUGIN_ROOT}/references/aidlc-methodology.md for detailed methodology documentation
- Use @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md for templates and operational guidance

## What is AI-DLC?

AI-DLC (AI-Driven Development Lifecycle) is a methodology that puts AI at the center of the development process. It was developed by AWS as an AI-native approach to software engineering.

### Core Idea

**Traditional methods:** Human initiates, AI assists
**AI-DLC:** AI proposes, human approves

This reversal allows developers to focus on high-value decision-making while AI handles planning, task decomposition, and execution.

### Key Principles

1. **Reimagine Rather Than Retrofit** - Don't force AI into old methods; design for AI capabilities
2. **Reverse the Conversation Direction** - AI drives workflows, humans validate and approve
3. **Integration of Design Techniques** - DDD, BDD, TDD are core, not optional add-ons
4. **Align with AI Capability** - Balance AI strengths with human oversight
5. **Build Complex Systems** - Designed for architectural complexity, not simple scripts
6. **Retain Human Symbiosis** - Keep artifacts that enable validation and risk mitigation
7. **Facilitate Transition** - Familiar concepts with modernized terminology
8. **Streamline Responsibilities** - Developers transcend traditional silos
9. **Minimize Stages, Maximize Flow** - Continuous iteration with strategic checkpoints
10. **No Opinionated Workflows** - AI recommends approach based on context

### Core Artifacts

| Artifact | Description | Analogy |
|----------|-------------|---------|
| **Project** | Portfolio container for a Feature | Program / Portfolio item |
| **Feature** | High-level statement of purpose | Product vision / Epic description |
| **Epic** | Cohesive, self-contained work element | DDD Subdomain / Scrum Epic |
| **Sprint** | Smallest iteration cycle (hours/days) | Sprint (but much shorter) |
| **Task** | Individual work item within a Sprint | User story task |
| **Domain Design** | Business logic model | DDD tactical patterns |
| **Logical Design** | Domain + NFRs + patterns | Architecture design |
| **Deployment Unit** | Packaged executable + config | Deployable artifact |

## Available Skills

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `/aidlc-intent` | Create Feature docs in Confluence | Starting a new initiative |
| `/aidlc-elaborate` | Break Feature into Epics, propose initial Sprint groupings | After Feature is approved |
| `/aidlc-design` | Domain Design, ADRs, Task Specification generation, and Sprint Plan finalisation | After Epics are created |
| `/aidlc-verify` | Verify docs, refine Sprints & transfer to Jira | After design, before implementation |
| `/aidlc-sprint` | Guide Sprint implementation with TDD | During implementation |
| `/aidlc-help` | This help guide | When you need guidance |

## Workflow Order

```
1. /aidlc-intent
   |
   v (Feature approved in Confluence, optional Project created in Jira)
2. /aidlc-elaborate
   |  (gathers per-cluster context: repo scan, reference patterns, or none)
   v (Epics created in Confluence, Sprint groupings proposed, reviewed, reorganized)
3. /aidlc-design
   |  (analyzes project patterns, produces deviation analysis)
   v (Domain model, ADRs, and Task Specifications generated, Sprint Plan finalised)
4. /aidlc-verify
   |
   v (Documentation verified, Sprints refined, transferred to Jira as Epic, Sprint, Task)
5. /aidlc-sprint
   |
   v (Sprint implementation with TDD)
```

### Jira Hierarchy

```
Project (optional) ← Created in /aidlc-intent
└── Feature
    └── Epic
        └── Story
            └── Task
```

**Sprint** groups Stories/Tasks for scheduling (it is not a hierarchy level).

### Phase 1: Feature Documentation (`/aidlc-intent`)

Creates a Feature document in Confluence containing:
- Problem/Opportunity statement
- Target users and outcomes
- Scope (in/out)
- Technical considerations
- NFRs and measurement criteria
- Risks and assumptions
- Proposed Epics (hypotheses)

**Output:** Approved Confluence document with workflow status tracking, optional Jira Project

### Phase 2: Decomposition (`/aidlc-elaborate`)

Breaks the Feature into Epics using Mob Elaboration:
1. Theme clusters identified and tagged (brown-field or green-field) using the service inventory
2. **Per-repo structural scan** (each brown-field repo scanned once, persisted to Confluence as "Service Context" pages)
3. Theme clusters analysed in parallel; Epic scopes and indicative work items proposed
4. Sprint groupings proposed for each Epic
5. Epic documentation created (GitLab: epic files / Linear: Projects / Confluence: Epic pages) — **no task files created here**
6. Team reviews and comments
7. Comments resolved, Epics refined and reorganized

**Output:** Epic documentation with preliminary Sprint groupings. Task Specifications are generated in the next phase.

> **Backward compatibility:** Projects from AIDLC 3.8 and earlier may have task files created in this phase. Those projects continue to work — `/aidlc-design` handles both.

### Phase 3: Design (`/aidlc-design`)

Creates design artifacts and Task Specifications:
1. **Analyze existing project patterns** (brown-field: reverse-engineer current architecture)
2. Assess context sufficiency (confidence check)
3. Domain models (aggregates, entities, value objects) — informed by existing patterns
4. Logical design (patterns, NFR solutions)
5. **Deviation analysis** (compare proposed vs. existing project patterns)
6. Architecture Decision Records (ADRs) — including deviation ADRs
7. **Task Specifications generated** (one per task, using domain model and ADR context)
8. Sprint Plan finalised with task-level detail

**Output:** Design documentation and Task Specifications in Confluence, finalised Sprint Plan

### Phase 4: Verification (`/aidlc-verify`)

Verifies documentation completeness and transfers to Jira:
1. Check for existing Project (created in `/aidlc-intent`), offer to create if missing
2. Spawn parallel sub-agents to assess each Epic
3. Calculate confidence score across all documentation
4. Identify gaps and provide remediation suggestions
5. Refine Sprint groupings based on assessment
6. If confidence ≥80%, transfer to Jira:
   - Feature (linked to Project if exists)
   - Epics
   - Sprints (with `sprint-type:backend/frontend/fullstack` label)
   - Tasks (with test scope scenarios posted as comments on each Sprint)
7. Clean up Confluence decomposition pages

**Output:** Jira artifacts (Feature → Epics → Sprints → Tasks) with test scenarios as Sprint comments, linked to Project

## Quick Start Guide

### Starting Fresh?

> "I want to plan a new feature for user authentication"
> Use `/aidlc-intent`

This will:
1. Gather requirements through clarifying questions
2. Draft a Feature document
3. Create the Confluence page for team review
4. Optionally create a Jira Project (Initiative) for portfolio tracking

### Have an Approved Feature?

> "Break down the authentication feature into Epics"
> Use `/aidlc-elaborate`

This will:
1. Validate the Feature is approved
2. Identify theme clusters
3. Spawn parallel agents to analyse clusters and propose Epic scopes
4. Create Epic documentation (epic files, projects, or pages — depending on backend)
5. Propose Sprint groupings for each Epic
6. Guide you through review and reorganization

> **Note:** Task Specifications are created in `/aidlc-design`, not here. Jira transfer happens in `/aidlc-verify`.

### Ready to Design?

> "Create the domain model for the auth epic"
> Use `/aidlc-design`

This will:
1. Validate Epics exist in Confluence
2. Assess context sufficiency (confidence check)
3. Create domain models using DDD principles
4. Document logical design decisions
5. Create ADRs for architectural choices

### Ready to Transfer to Jira?

> "Verify documentation and transfer to Jira"
> Use `/aidlc-verify`

This will:
1. Check for existing Project (or offer to create one)
2. Spawn sub-agents to assess each Epic's documentation
3. Calculate confidence score (needs ≥80% to proceed)
4. Identify gaps and suggest fixes
5. Refine Sprint groupings for each Epic
6. Transfer to Jira: Feature, Epics, Sprints, Tasks
7. Link Feature to Project (if exists)
8. Clean up Confluence decomposition pages

## Key Concepts Explained

### Project

| Aspect | Description |
|--------|-------------|
| Purpose | Portfolio container for a Feature |
| Created in | `/aidlc-intent` (optional) |
| Jira Label | `aidlc:project` |
| Contains | Features |

### Feature

| Aspect | Description |
|--------|-------------|
| Purpose | High-level statement of purpose (WHAT and WHY) |
| Created in | Confluence first, then Jira during `/aidlc-verify` |
| Jira Label | `aidlc:feature` |
| Contains | Epics |

### Epic

| Aspect | Description |
|--------|-------------|
| Purpose | Cohesive work grouping (like DDD Subdomain) |
| Created in | Confluence during `/aidlc-elaborate`, Jira during `/aidlc-verify` |
| Jira Label | `aidlc:epic` |
| Contains | Sprints |

### Task

| Aspect | Description |
|--------|-------------|
| Purpose | Individual work item with behaviour, rules, files, dependencies |
| Created in | Confluence/GitLab/Linear during `/aidlc-design`, Jira during `/aidlc-verify` |
| Grouped under | Sprint |

### Sprint (AIDLC) vs Sprint (Scrum)

| Sprint (AIDLC term) | Sprint (Scrum) |
|-------------------|----------------|
| Hours to days | 2-4 weeks |
| Intense focus | Planned capacity |
| Testable increment | Shippable increment |
| Multiple per Epic | One at a time |
| Created in Jira with label `aidlc:sprint` | N/A |
| Groups related Tasks | Tracks work items |

### Project Context Grounding

The AI gathers structural context before generating proposals, driven by the service inventory from Feature:
- **Brown-field services**: Each repository is scanned once (per the service inventory), and findings are persisted to Confluence as "Service Context" pages under the Epics Overview. Relevant slices of each scan are provided to elaboration sub-agents.
- **Green-field services**: Teams can provide a reference project, template, or starter pattern. If none, the service is unconstrained (only the technical guidance hierarchy applies)
- **Mixed initiatives**: Each cluster is tagged independently based on the service inventory — brown-field clusters get repo context, green-field clusters get reference context
- **During design**: The AI conducts its own implementation-pattern analysis (distinct from Elaborate's structural scan) and compares proposed patterns against existing codebase patterns, presenting deviations for team decision

This ensures the AI's proposals are grounded in established patterns rather than proposing approaches in a vacuum.

### Mob Elaboration

A collaborative ritual where AI and humans work together:
- Single room (physical or virtual) with shared screen
- AI proposes breakdown of Feature into Tasks, Epics, and Sprint groupings
- Team reviews, challenges, and refines
- Condenses weeks of work into hours

## Response Behavior

When this skill is invoked:

1. **Greet the user** and acknowledge their question
2. **Determine their need**:
   - General methodology questions -> Reference `aidlc-methodology.md`
   - Specific skill usage -> Provide targeted guidance
   - Workflow questions -> Explain the process flow
   - Getting started -> Suggest the appropriate skill
3. **Provide clear, concise guidance**
4. **Suggest next steps** based on their context

### Example Interactions

**User:** "What is AI-DLC?"
**Response:** Explain the core concept, key principles, and how it differs from traditional methods.

**User:** "How do I start planning a new feature?"
**Response:** Recommend `/aidlc-intent`, explain what it does, and what they'll need (project context, stakeholder info).

**User:** "What is an Epic in AI-DLC?"
**Response:** Explain that Epics are cohesive work elements that group related Sprints. Epics are created in Jira with the `aidlc:epic` label and represent a bounded context of work.

**User:** "Explain Mob Elaboration"
**Response:** Describe the collaborative ritual, its participants, AI's role, and the outputs.

## Troubleshooting

### "I don't have a Confluence doc yet"

Start with `/aidlc-intent` to create the Feature document and optionally a Jira Project.

### "I have a Confluence doc but it's not approved"

Review the Workflow Status table in the doc. If "Feature" is not "Approved", gather stakeholder approval before proceeding to decomposition.

### "I want to skip the Confluence phase"

While possible with explicit override, Confluence-first is recommended for:
- Team collaboration and review
- Comment resolution before Jira creation
- Traceability between artifacts

### "The skill said my prerequisites are incomplete"

Check that prior phases are complete:
- For `/aidlc-elaborate`: Need approved Feature in Confluence
- For `/aidlc-design`: Need Epics created in Confluence (from elaborate phase)
- For `/aidlc-verify`: Need design documentation and Sprint groupings complete

## Further Reading

For detailed methodology documentation, ask about specific topics:
- "Tell me about the 10 key principles"
- "Explain the Construction Phase"
- "What are Domain Design artifacts?"
- "How does AI-DLC handle brown-field development?"

The methodology reference contains the complete AWS AI-DLC method definition with examples and prompts.
