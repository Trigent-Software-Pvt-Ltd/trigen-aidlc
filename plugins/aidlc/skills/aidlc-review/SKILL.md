---
name: aidlc-review
description: Peer-review implementation work (GitLab merge requests) for a Sprint, or review AI-DLC documents (GitLab markdown files, Linear artifacts, or Confluence/Jira artifacts). Acts as a senior engineer reviewer with confidence scoring. (Triggers - review AI-DLC docs, check the feature, review sprint implementation, peer review MR, validate Jira story, aidlc review)
---

# AI-DLC Review

Review AI-DLC documentation or implementation work with thorough, sub-agent-driven analysis and confidence scoring. Supports multiple documentation backends: **GitLab** (markdown files), **Linear** (Initiatives/Projects/Issues), or **Confluence** (pages).

## AI-Drives-Conversation Pattern

This skill follows the AI-DLC principle where AI initiates and directs the conversation:

1. **AI asks** — Which review type (documentation or implementation)?
2. **AI gathers** — Collect minimal required inputs for the selected path
3. **AI reviews** — Spawn sub-agents to perform thorough analysis
4. **AI reports** — Present findings with confidence scores
5. **Human decides** — User acts on findings; optionally posts them back to source systems

## Example Invocations

- "Review the AI-DLC documentation"
- "Check the feature and epics for completeness"
- "Peer review this sprint implementation"
- "Review the MR for PROJ-123"
- "Validate the Jira story against the docs"

## Completion Checklist

> **IMPORTANT**: Create tasks for each step at the start using `TodoWrite`. Mark tasks complete as you go using `TodoWrite`. Each task description should reference the corresponding Workflow step.

### Path A: Documentation Review

| # | Task | Depends On | Workflow Reference | Exit Criteria |
|---|------|------------|-------------------|---------------|
| A1 | Determine review scope | — | Step A1 | Epics confirmed with user |
| A2 | Fetch documentation | A1 | Step A2 | Epic and Task pages retrieved |
| A3 | Spawn documentation review sub-agents | A2 | Step A3 | One doc-verifier per Epic launched |
| A4 | Consolidate review results | A3 | Step A4 | Scores calculated, gaps merged |
| A5 | Present review report | A4 | Step A5 | Report displayed to user |
| A6 | Handle feedback loop | A5 | Step A6 | User confirms next action |

### Path B: Implementation Review

| # | Task | Depends On | Workflow Reference | Exit Criteria |
|---|------|------------|-------------------|---------------|
| B1 | Determine review scope | — | Step B1 | Sprints confirmed with user |
| B2 | Fetch MR diffs and context | B1 | Step B2 | MR diffs retrieved |
| B3 | Spawn implementation review sub-agents | B2 | Step B3 | One sub-agent per Sprint launched |
| B4 | Consolidate review results | B3 | Step B4 | Scores calculated, risks merged |
| B5 | Present review report | B4 | Step B5 | Report displayed to user |
| B6 | Handle feedback loop | B5 | Step B6 | User confirms next action |

## Task Tracking

When this skill is invoked:
1. **Detect path** (A or B) and create tasks for that path's checklist using `TodoWrite`
2. **Mark task as in_progress** when starting each step
3. **Mark task complete** when exit criteria met
4. **Verify all tasks complete** before finishing

This ensures visibility into progress and prevents incomplete execution.

## Backend Detection

This skill detects the backend automatically from existing artifacts (it does NOT prompt for backend selection). Use @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md for detection logic.

The backend determines where to fetch documentation from:
- **GitLab**: Read `.md` files from the Feature branch in `"$AIDLC_DOCS_PATH"`
- **Linear**: Fetch Initiatives, Projects, and Issues via Linear MCP
- **Confluence**: Fetch pages via Atlassian MCP or `acli`

## References

- @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md - Jira/Confluence tool guidance and templates
- @${CLAUDE_PLUGIN_ROOT}/references/backend-selection.md - Backend detection logic
- @${CLAUDE_PLUGIN_ROOT}/references/review-criteria.md - Scoring rubrics and checklists
- @${CLAUDE_PLUGIN_ROOT}/references/backends/gitlab.md - GitLab operations (if GitLab backend)
- @${CLAUDE_PLUGIN_ROOT}/references/backends/linear.md - Linear operations (if Linear backend)
- @${CLAUDE_PLUGIN_ROOT}/references/backends/confluence.md - Confluence operations (if Confluence backend)
- @${CLAUDE_PLUGIN_ROOT}/references/vcs-detection.md - VCS provider detection and PR/MR commands

## Tool Preference

- **CLI-first**: Prefer `glab` (GitLab CLI), `gh` (GitHub CLI), and `acli` (Atlassian CLI) as they use fewer tokens.
- **MCP fallback**: Use Atlassian, GitLab, and Linear MCP servers when CLI is unavailable or insufficient.

## Workflow

### Step 0: Choose Review Type

Ask the user:

```
What type of review do you need?

1. Documentation review — Review AI-DLC docs (GitLab .md files, Linear artifacts, or Confluence pages/Jira)
2. Implementation review — Peer-review GitLab merge request(s) for a Sprint
```

Then follow the appropriate path below.

---

## Path A: Documentation Review

### Step A1: Gather Inputs and Detect Backend

First, detect the backend from what the user provides (see Backend Detection section).

Then ask only for what is needed, adapting to the backend:

**GitLab** — Accept:
- Feature branch name or path to Feature directory
- Specific `.md` files to review

**Linear** — Accept:
- Initiative URL or ID
- Project/Issue URLs or IDs

**Confluence** — Accept:
- Confluence page links or IDs (Feature, Epics, Design, Tasks)
- Jira issue keys (Epics, Sprints, Tasks)

Prompt:
```
Please provide the documentation to review. I accept:

- GitLab: Feature branch name or path (e.g., "intent/my-project/auth-overhaul")
- Linear: Initiative or Project URL/ID
- Confluence: Page links or IDs / Jira issue keys

Provide what you have and I'll fetch the content.
```

If the user provides a single reference (e.g., an Feature), offer to discover related artifacts:

| Backend | Discovery |
|---------|-----------|
| GitLab | Read all `.md` files in the Feature directory tree |
| Linear | Fetch all Projects and Issues under the Initiative |
| Confluence | Fetch child pages and linked Jira issues |

### Step A2: Fetch Content

Fetch all provided artifacts based on the detected backend:

**GitLab backend:**
```bash
cd ~/Projects/ai-dlc-docs
git checkout <intent-branch>
# Read intent.md, epics/*.md, tasks/*.md, design/*.md, adrs/*.md
```
Normalize each `.md` file into a `VerificationInput` object (see doc-verifier agent for format).

**Linear backend:**
- Fetch Initiative via `get_initiative` (include Projects)
- For each Project, fetch Issues via `list_issues`
- Convert descriptions to `VerificationInput` format

**Confluence backend** — use Atlassian MCP or `acli`:

Before reading a Confluence page, ask:
> "Should I include inline and footer comments, or just the page content?"

- Page content only: `getConfluencePage`
- With comments: Also fetch `getConfluencePageInlineComments` and `getConfluencePageFooterComments`

**For Jira issues** (GitLab/Confluence backends) — prefer `acli`:
```bash
acli jira workitem view PROJ-123 --fields summary,description,status,issuetype,labels --json
acli jira workitem children PROJ-123 --json
```

### Step A3: Spawn Documentation Review Sub-agents

Spawn one sub-agent per document (or per Epic if reviewing a full set) using the Task tool with `subagent_type: "general-purpose"`.

Spawn all sub-agents in a single message for parallel execution.

**When constructing the sub-agent prompt:** Read review-criteria.md and inject the Documentation Review Rubric (Part 3.1) and Shared Quality Checklists (Part 2) into the Review Criteria section below.

**Sub-agent Prompt Template:**

```markdown
You are reviewing AI-DLC documentation as a senior engineer. Be thorough, constructive, and rigorous.

## Document to Review

<document type and content>

## Related Context (if available)

<Feature summary, related docs, Jira content>

## Review Criteria

Score each dimension 0-100:

1. **Completeness** (weight: 25%) — All required sections present for the document type, thorough coverage
2. **Quality** (weight: 25%) — Content is clear, specific, and actionable; no vague language
3. **Accuracy** (weight: 25%) — Internally consistent, aligns with Feature, no contradictions
4. **Ambiguity Risk** (weight: 15%) — Lower ambiguity = higher score; boundaries and terms clear
5. **Open Questions** (weight: 10%) — Fewer unresolved questions = higher score

[Inject: Documentation Review Rubric (Part 3.1) and Shared Quality Checklists (Part 2) from review-criteria.md]

## Return Format

Return your assessment as JSON:

{
  "document": "<document identifier>",
  "document_type": "<feature|epic|design|task|sprint>",
  "scores": {
    "completeness": <0-100>,
    "quality": <0-100>,
    "accuracy": <0-100>,
    "ambiguity_risk": <0-100>,
    "open_questions": <0-100>
  },
  "findings": [
    {
      "severity": "<blocking|high|medium|low>",
      "dimension": "<completeness|quality|accuracy|ambiguity|open_questions>",
      "issue": "<specific issue description>",
      "location": "<section or field where issue was found>",
      "suggestion": "<how to fix>"
    }
  ],
  "inconsistencies": [
    {
      "description": "<what contradicts what>",
      "locations": ["<doc/section 1>", "<doc/section 2>"]
    }
  ],
  "ambiguities": [
    {
      "statement": "<the ambiguous text>",
      "location": "<where it appears>",
      "interpretations": ["<interpretation A>", "<interpretation B>"],
      "clarifying_question": "<question to resolve ambiguity>"
    }
  ],
  "open_questions": [
    {
      "question": "<the question>",
      "context": "<why this matters>",
      "proposed_answer": "<suggested answer if possible, or null>"
    }
  ],
  "strengths": [
    "<well-documented aspect>"
  ]
}
```

### Step A4: Consolidate Results

After all sub-agents return:

1. **Parse JSON results** from each sub-agent
2. **Calculate weighted scores** per document and overall:
   - Completeness: 25%
   - Quality: 25%
   - Accuracy: 25%
   - Ambiguity risk: 15%
   - Open questions: 10%
3. **Merge findings** across all documents, deduplicate
4. **Identify cross-document inconsistencies**
5. **Rank findings by severity** (blocking first)

### Step A5: Present Assessment

Present the documentation review report:

```markdown
## Documentation Review Report

### Overall Confidence: XX/100

| Document | Completeness | Quality | Accuracy | Ambiguity | Open Qs | Score |
|----------|-------------|---------|----------|-----------|---------|-------|
| Feature   | 85          | 90      | 80       | 75        | 70      | 82    |
| Epic 1   | 70          | 65      | 75       | 60        | 50      | 66    |
| ...      |             |         |          |           |         |       |
| **Overall** |          |         |          |           |         | **XX** |

### Score Interpretation

- **80-100**: High confidence — documentation is solid, minor issues only
- **60-79**: Concerns to address — notable gaps or ambiguities to resolve
- **Below 60**: Significant issues — documentation needs substantial rework

### Findings

**Blocking:**
1. [Document] Issue description
   - Suggestion: how to fix

**High:**
2. [Document] Issue description
   - Suggestion: how to fix

**Medium / Low:**
3. ...

### Inconsistencies

1. [Doc A] says X, but [Doc B] says Y
   - Suggestion: resolve by...

### Ambiguities

1. "[ambiguous statement]" in [location]
   - Could mean: A or B
   - Clarifying question: ...

### Open Questions

1. [Question] — [context]
   - Proposed answer: ...

### Strengths

- ...
```

### Step A6: Optional Write-back

After presenting the report, offer to post findings (options vary by backend):

**GitLab:**
```
Would you like me to post these findings to:
1. GitLab MR comments (on the Feature's draft MR)
2. Let's discuss the findings first
3. No, terminal report is sufficient
```

**Linear:**
```
Would you like me to post these findings to:
1. Linear comments (on the Initiative/Projects/Issues)
2. Let's discuss the findings first
3. No, terminal report is sufficient
```

**Confluence:**
```
Would you like me to post these findings to:
1. Confluence page comments (on the reviewed pages)
2. Jira ticket comments (on the reviewed issues)
3. Both
4. Let's discuss the findings first
5. No, terminal report is sufficient
```

If the user opts in, post a summarised version of the findings to the relevant system.

---

## Path B: Implementation Review (Sprint Peer Review)

### Reviewer Persona

Act as a **constructive but rigorous senior engineer**. Tone is direct, professional, and actionable — flag issues clearly, explain why they matter, and suggest alternatives. Assume the author is a competent engineer; do not over-explain fundamentals.

### Step B1: Detect Backend and Gather Inputs

First, detect the work tracking backend. Ask the user for context — the backend determines how to fetch Sprint/Task data:

**Jira backend** (GitLab/Confluence documentation):

Ask for:
- **Required:** Jira Sprint (story key, e.g., PROJ-123)
- **Required:** GitLab MR link(s) implementing the Sprint
- **Optional:** Related design/feature documentation

```
Please provide:

1. The Jira Sprint (story) key (e.g., PROJ-123)
2. The GitLab MR link(s) for this Sprint

Optionally, also provide:
- Design document links
- Feature document link
```

**Linear backend:**

Ask for:
- **Required:** Linear Issue URL or identifier (the Sprint issue)
- **Required:** MR/PR link(s) implementing the Sprint
- **Optional:** Related design documentation (Linear Issue links or external docs)

```
Please provide:

1. The Linear Issue URL or ID for this Sprint (e.g., https://linear.app/team/issue/ENG-123)
2. The MR/PR link(s) for this Sprint

Optionally, also provide:
- Design document links (Linear Issues with "Design Doc" label, or external docs)
```

### Step B2: Fetch Context

#### Work tracking context

**Jira backend** — fetch the Sprint and its Tasks:
```bash
# Fetch the Sprint
acli jira workitem view PROJ-123 --fields summary,description,status,issuetype,labels --json

# Fetch child Tasks
acli jira workitem children PROJ-123 --json
```

Extract:
- Acceptance criteria (AC) from the Sprint description
- Task descriptions and AC from child Tasks
- Any linked design documentation

**Linear backend** — fetch the Sprint Issue and related Issues:
```typescript
// Fetch the Sprint Issue
get_issue({ query: "<issue-id>" })

// List related Issues in the same Project (sibling tasks in the Sprint)
list_issues({ project: "<project-id>", labels: ["<sprint-label>"] })
```

Extract:
- Acceptance criteria from the Issue description
- Related Issue descriptions and AC (sibling tasks with same Sprint label)
- Linked design documentation (Issues with "Design Doc" label)

#### MR/PR context — detect VCS provider and fetch accordingly:

Detect the VCS provider from the repo remote (see @${CLAUDE_PLUGIN_ROOT}/references/vcs-detection.md), then use the appropriate CLI:

```bash
# GitLab VCS
glab mr view <MR_ID> --repo <project>
glab mr diff <MR_ID> --repo <project>

# GitHub VCS
gh pr view <PR_NUMBER> --repo <owner/repo>
gh pr diff <PR_NUMBER> --repo <owner/repo>
```

If CLI tools are unavailable, use MCP tools or ask the user to paste the diff.

#### Standards discovery — scan the reviewed repo for project conventions:
- `CLAUDE.md` — project-specific instructions
- Linter configs: `.rubocop.yml`, `.eslintrc`, `biome.json`, `.prettierrc`, `.editorconfig`
- Test conventions: spec directory structure, test naming patterns
- `CONTRIBUTING.md`, `DEVELOPMENT.md`

Use these to contextualise code quality and best-practice feedback.

### Step B3: Spawn Implementation Review Sub-agents

Spawn sub-agents in parallel using the Task tool with `subagent_type: "general-purpose"`:

**One sub-agent per MR** — analyzes code quality, security, and testing.

**When constructing the sub-agent prompt:** Read review-criteria.md and inject the Implementation Review Rubric (Part 3.2) into the Review Dimensions section below.

```markdown
You are a senior engineer performing a rigorous peer review of a merge request.
Be direct, constructive, and actionable. Assume the author is competent.

## MR Context

**MR Title:** <title>
**MR Description:** <description>
**Target Branch:** <branch>

## Diff

<full MR diff>

## Project Conventions

<discovered standards from CLAUDE.md, linter configs, etc.>

## Work Item Context

**Sprint:** <sprint summary and AC> (from Jira or Linear)
**Tasks:** <task summaries and AC> (from Jira Tasks or Linear sibling Issues)

## Review Dimensions

Score each dimension 0-100:

1. **Requirements Fit** (weight: 30%) — AC addressed, appropriate scope, edge cases handled
2. **Code Quality** (weight: 25%) — Clean, maintainable, follows project conventions
3. **Testing Adequacy** (weight: 25%) — AC tested, edge cases covered, negative tests present
4. **Security & Reliability** (weight: 20%) — Input validated, auth checked, errors handled, no data leaks

[Inject: Implementation Review Rubric (Part 3.2) from review-criteria.md]

## AC-to-Test Mapping

For each acceptance criterion from the Sprint (Jira or Linear):
1. Identify the specific test file and test method that covers it
2. If an AC has no corresponding test, flag it as a gap
3. Beyond the AC, identify missing edge cases, negative tests, and boundary conditions implied by the code

## Return Format

Return your assessment as JSON:

{
  "mr_id": "<MR identifier>",
  "scores": {
    "requirements_fit": <0-100>,
    "code_quality": <0-100>,
    "testing_adequacy": <0-100>,
    "security_reliability": <0-100>
  },
  "ac_coverage": [
    {
      "ac_item": "<acceptance criterion text>",
      "status": "<covered|partial|missing>",
      "evidence": "<test file:method or code location that covers this>",
      "notes": "<any caveats>"
    }
  ],
  "test_gaps": [
    {
      "type": "<missing_ac_test|missing_edge_case|missing_negative_test|missing_boundary_test>",
      "description": "<what is missing>",
      "suggestion": "<what test to add>"
    }
  ],
  "findings": [
    {
      "severity": "<blocking|high|medium|low>",
      "dimension": "<requirements_fit|code_quality|testing|security_reliability>",
      "file": "<file path>",
      "line": "<line number or range>",
      "issue": "<specific issue>",
      "suggestion": "<how to fix>",
      "rationale": "<why this matters>"
    }
  ],
  "strengths": [
    "<well-implemented aspect>"
  ]
}
```

**One sub-agent for AC mapping** (when Sprint has detailed AC and multiple MRs):

```markdown
You are mapping acceptance criteria to implementation evidence across multiple MRs.

## Acceptance Criteria

<all AC from Sprint and Tasks>

## MR Summaries

<summary of each MR's changes>

## Instructions

1. For each AC item, identify which MR(s) and which code/test files address it
2. Flag any AC that is not addressed by any MR
3. Flag any MR changes that don't map to any AC (scope creep)
4. Identify cross-MR dependencies (e.g., API contract between frontend and backend)

## Return Format

Return your assessment as JSON:

{
  "coverage_matrix": [
    {
      "ac_item": "<criterion>",
      "source": "<sprint|task key>",
      "covered_by": ["<MR id: file/test>"],
      "status": "<fully_covered|partially_covered|not_covered>",
      "notes": "<any concerns>"
    }
  ],
  "scope_creep": [
    {
      "mr_id": "<MR>",
      "change": "<what was changed>",
      "concern": "<why this may be out of scope>"
    }
  ],
  "cross_mr_issues": [
    {
      "description": "<consistency concern>",
      "affected_mrs": ["<MR ids>"],
      "suggestion": "<how to align>"
    }
  ]
}
```

### Step B4: Consolidate Results

After all sub-agents return:

1. **Parse JSON results** from each sub-agent
2. **Calculate weighted scores** per MR and overall:
   - Requirements fit: 30%
   - Code quality: 25%
   - Testing adequacy: 25%
   - Security/reliability: 20%
3. **Merge AC coverage** across MRs into a unified coverage matrix
4. **Compile test gap analysis** — missing AC tests + missing edge/negative/boundary tests
5. **For multi-MR Sprints** — produce both individual MR reports and an aggregate summary

### Step B5: Present Assessment

**For single-MR Sprints:**

```markdown
## Implementation Review Report

### Sprint: PROJ-123 — <Summary>
### MR: !456 — <MR Title>

### Overall Confidence: XX/100

| Dimension | Score |
|-----------|-------|
| Requirements Fit | XX |
| Code Quality | XX |
| Testing Adequacy | XX |
| Security & Reliability | XX |
| **Weighted Overall** | **XX** |

### Score Interpretation

- **80-100**: High confidence — implementation is solid
- **60-79**: Concerns to address — issues to resolve before merge
- **Below 60**: Significant issues — implementation needs substantial rework

### AC Coverage Map

| Acceptance Criterion | Status | Evidence |
|---------------------|--------|----------|
| AC 1: ... | Covered | test_file.rb:test_method |
| AC 2: ... | Missing | No test found |

### Test Gap Analysis

**Missing AC tests:**
1. AC 2 has no corresponding test — suggest adding...

**Missing edge cases / negative tests:**
1. No test for invalid input on... — suggest adding...

### Findings

**Blocking:**
1. [file:line] Issue — Suggestion — Rationale

**High:**
2. ...

**Medium / Low:**
3. ...

### Strengths

- ...
```

**For multi-MR Sprints** — present individual MR reports followed by:

```markdown
## Aggregate Summary (Cross-MR)

### Overall AC Coverage: X of Y criteria covered

### Cross-MR Consistency
1. [Issue] between MR !123 and MR !456 — Suggestion

### Scope Check
- All changes map to AC: Yes/No
- Out-of-scope changes: [list if any]
```

### Step B6: Optional Write-back

After presenting the report, offer to post findings (options vary by work tracking backend):

**Jira backend (GitLab/Confluence documentation):**
```
Would you like me to post these findings to:
1. MR/PR comments (inline where possible, general for overall findings)
2. Jira Sprint comment (summary of findings)
3. Both
4. Let's discuss the findings first
5. No, terminal report is sufficient
```

**Linear backend:**
```
Would you like me to post these findings to:
1. MR/PR comments (inline where possible, general for overall findings)
2. Linear Issue comment (summary of findings on the Sprint Issue)
3. Both
4. Let's discuss the findings first
5. No, terminal report is sufficient
```

If the user opts in to MR/PR comments:

Detect the VCS provider (see @${CLAUDE_PLUGIN_ROOT}/references/vcs-detection.md), then post using the appropriate commands:

**GitLab VCS:**
- Post inline comments on specific lines for blocking/high findings:
  ```bash
  glab mr note <MR_ID> --message "<inline finding: file:line — issue>"
  ```
- Post a general MR comment with the overall report summary:
  ```bash
  glab mr note <MR_ID> --message "<overall report summary>"
  ```

**GitHub VCS:**
- Post a review with the overall summary:
  ```bash
  gh pr review <PR_NUMBER> --comment --body "<overall report summary>"
  ```
- Post inline comments on specific files/lines for blocking/high findings:
  ```bash
  gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
    --method POST \
    --field body="<overall summary>" \
    --field event="COMMENT" \
    --field "comments[][path]"="<file-path>" \
    --field "comments[][line]"=<line-number> \
    --field "comments[][body]"="<finding description and suggestion>"
  ```

If the user opts in to work tracker comments:
- **Jira**: Post a comment on the Sprint (story) with the confidence score, AC coverage summary, and key findings.
- **Linear**: Post a comment on the Sprint Issue using `create_comment({ issueId, body })` with the confidence score, AC coverage summary, and key findings.

If the user chooses "Let's discuss the findings first", enter a conversational mode: answer questions about the findings, explain rationale, discuss trade-offs, and help the user understand the implications of individual issues. The user may also disagree with findings — if so, engage openly: listen to their reasoning, revise or retract findings where their argument is sound, and update the severity or status of findings accordingly. Once the user signals they are ready, re-present the write-back options (without the discuss option), reflecting any findings that were revised or dismissed during the discussion.

---

## Workflow Chain

- **Previous**: Any AI-DLC skill output (docs from `/aidlc-intent`, `/aidlc-elaborate`, `/aidlc-design`, `/aidlc-verify`) or implementation from `/aidlc-sprint`
- **Next**: Address findings, then proceed with implementation or merge

## Definition of Done

### Documentation Review Complete
- Backend detected from artifacts (GitLab / Linear / Confluence)
- All provided documents assessed by review sub-agents
- Per-dimension and overall confidence scores calculated
- Findings categorised by severity
- Inconsistencies and ambiguities surfaced
- Open questions listed with proposed answers where possible
- Report presented to user
- Optional: findings posted to source system (GitLab MR / Linear comments / Confluence/Jira)

### Implementation Review Complete
- All MRs analysed by review sub-agents
- AC-to-test coverage matrix produced with gap analysis
- Per-dimension and overall confidence scores calculated
- Findings categorised by severity with file/line references
- Cross-MR consistency checked (for multi-MR Sprints)
- Report presented to user
- Optional: findings posted to GitLab MR and/or Jira

## Troubleshooting

- **No `glab` or `acli`**: Fall back to MCP tools. If neither available, ask user to paste content or export diffs.
- **No `gh`**: Fall back to GitHub MCP tools if configured, or ask user to paste the PR diff.
- **MR too large for context**: Ask user to specify which files or components to focus on. Split into multiple review passes if needed.
- **No Jira access**: Allow manual entry of acceptance criteria and sprint description.
- **Missing acceptance criteria**: Flag as a blocking finding — cannot assess requirements fit without AC.
- **Multiple MRs with conflicts**: Report conflicts in the aggregate summary; do not attempt to resolve.
- **Standards config not found**: Review against general best practices; note that project-specific conventions could not be discovered.
- **Sub-agent failure**: Report which review failed and offer to retry or assess manually.
