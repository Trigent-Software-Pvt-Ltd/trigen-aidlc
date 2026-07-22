# Sprint Plan Consensus Review

Shared review criteria, verdict format, context schema, and loop protocol for the automated architect + critic consensus review of sprint implementation plans. Used by `sprint-plan-architect` and `sprint-plan-critic` agents during Phase 3 of the `/aidlc-sprint` workflow.

---

## Part 1: Review Context Schema

The following context is assembled from Phases 1-2 and passed to both review agents.

### 1.1 Context Payload

| Field | Source | Description |
|-------|--------|-------------|
| `work_item` | Phase 1, Step 1 | Work item summary: key, title, description, acceptance criteria (from Jira or Linear) |
| `codebase_context` | Phase 1, Steps 2-3 | Relevant files discovered, existing patterns, tech stack, test framework |
| `test_plan` | Phase 2, Step 4 | Unit tests, integration tests, acceptance tests with descriptions |
| `expert_perspectives` | Phase 2, Step 4.5 | Expert recommendations (if generated for multi-task or high-risk sprints) |
| `implementation_plan` | Phase 2, Step 5 | TDD cycles (Red → Green → Refactor) with feature slices |
| `iteration_context` | Step 5c (re-review only) | Latest revision + summary of prior feedback + outstanding issues |

### 1.2 Iteration Context (Re-review Only)

On re-review iterations, agents also receive:

| Field | Description |
|-------|-------------|
| `revision_number` | Current iteration (1-3) |
| `prior_feedback_summary` | Condensed architect + critic findings from all prior iterations |
| `changes_made` | What was revised and why |
| `outstanding_issues` | Issues acknowledged but not yet addressed |

---

## Part 2: Review Dimensions

### 2.1 Architect Review Dimensions

The sprint-plan-architect evaluates the plan against these dimensions:

| Dimension | What to check | Red flags |
|-----------|--------------|-----------|
| **TDD Cycle Structure** | Each cycle has a clear Red/Green/Refactor step. Feature slices are appropriately sized. Cycles build incrementally. | Cycles without clear test targets. Giant cycles that try to do too much. Refactor steps with no specifics. |
| **Dependency Ordering** | Cycles are ordered so earlier work unblocks later work. Shared utilities built before consumers. | Cycle N depends on output from Cycle N+2. Circular dependencies between cycles. |
| **Test Strategy Adequacy** | Test plan covers all acceptance criteria. Edge cases identified. Integration points tested. Mocks/stubs are justified. | Acceptance criteria without corresponding tests. Missing edge cases for error paths. Over-mocking that hides integration issues. |
| **File/Module Organization** | Files to create/modify are identified. Changes are scoped appropriately. No unnecessary coupling introduced. | Vague file references ("update the auth module"). Changes scattered across unrelated modules. Missing files that will need modification. |
| **Risk Identification** | Dependencies, blockers, and technical risks called out. Mitigation strategies present for high risks. | No risks identified (every plan has at least one). Risks without mitigations. Missing external dependency risks. |

### 2.2 Critic Review Dimensions

The sprint-plan-critic evaluates the plan against these dimensions:

| Dimension | What to check | Red flags |
|-----------|--------------|-----------|
| **Testability of Acceptance Criteria** | Every AC maps to at least one test. Tests are specific enough to write without interpretation. | AC like "should work correctly". Tests described as "verify it works". No Given/When/Then or equivalent. |
| **Gap Analysis** | What's missing from the plan? Unhandled edge cases? Unstated assumptions? | No error handling strategy. Missing rollback/recovery plan. Implicit assumptions about data state. |
| **TDD Cycle Completeness** | Each cycle has all three phases (Red/Green/Refactor). Green phase is minimal (not gold-plated). Refactor has specific targets. | Missing refactor steps. Green phases that include "also add logging, metrics, and caching". |
| **Risk Coverage** | Identified risks have mitigations. No obvious risks are missing. | Security-sensitive changes with no security consideration. DB changes with no migration plan. |
| **Implementation Feasibility** | Each step can be executed with available context. No implicit knowledge required. | Steps that assume access/tools not available. References to APIs/services not in the codebase context. |

---

## Part 3: Verdict and Severity Definitions

Each agent defines its own output format (see the agent files for templates). The shared definitions below apply to both agents.

### 3.1 Verdict Definitions

| Verdict | Meaning | Who can issue | Triggers |
|---------|---------|---------------|----------|
| **APPROVE** | Plan is ready for user approval | Architect, Critic | No CRITICAL findings. MAJOR findings are negligible or absent. |
| **ITERATE** | Plan needs targeted revisions | Architect, Critic | 1+ MAJOR findings. No fundamental design flaws. Fixable with targeted edits. |
| **REJECT** | Plan has fundamental issues | Critic only | 1+ CRITICAL findings OR systemic pattern of MAJOR findings. May need substantial rework. |

### 3.2 Severity Definitions

| Severity | Definition | Example |
|----------|-----------|---------|
| **CRITICAL** | Blocks execution. Plan cannot be implemented as written. | Missing TDD cycle for a core acceptance criterion. Circular dependency between cycles. |
| **MAJOR** | Causes significant rework if not addressed. | Test plan missing edge cases for error paths. Vague file references that need clarification. |
| **MINOR** | Suboptimal but plan can be implemented. | Refactor step could be more specific. Minor ordering preference. |

---

## Part 4: Loop Protocol

### 4.1 Sequential Execution

The review runs sequentially — architect completes before critic starts:

```
Step 5a: Architect Review
  ├── APPROVE → proceed to Step 5b
  └── ITERATE → main agent revises, re-submit to Step 5a

Step 5b: Critic Review (only after architect APPROVE)
  ├── APPROVE → proceed to Phase 4 (Plan Approval)
  ├── ITERATE → enter re-review loop (Step 5c)
  └── REJECT  → enter re-review loop (Step 5c)

Step 5c: Re-review Loop (max 3 iterations)
  1. Collect architect + critic feedback
  2. Main agent revises plan (targeted edits in LLM context)
  3. Re-submit to architect (Step 5a)
  4. If architect APPROVE, re-submit to critic (Step 5b)
  5. Repeat until critic APPROVE or 3 iterations exhausted
```

### 4.2 Revision Mechanics

- **Who revises:** The main sprint agent (not a sub-agent)
- **What is revised:** Targeted edits to the plan based on feedback. Not a full re-plan of Phase 2.
- **Where the plan lives:** In LLM context (the plan file is not created until Phase 5). Revisions produce an updated plan block.
- **Context carried forward:** Each iteration receives the latest plan revision + condensed summary of all prior feedback + list of outstanding issues

### 4.3 Iteration Exhaustion

If 3 iterations complete without a critic APPROVE:

1. Using the per-iteration scratch notes, select the plan version with the fewest CRITICAL + MAJOR findings. This is best-effort: scratch notes carry finding counts per iteration, not plan snapshots. If counts are tied or context is ambiguous, default to the most recent revision.
2. Annotate remaining issues as "known limitations reviewed by automated consensus"
3. Present to the user in Phase 4 (Plan Approval) with a note that automated review did not fully converge
4. The user makes the final call on whether to proceed

### 4.4 Agent Invocation

Both agents are spawned via the Task tool:

```
Task tool parameters:
  subagent_type: "sprint-plan-architect" (or "sprint-plan-critic")
  prompt: [context payload from Section 1.1 + agent-specific instructions]
```

The model is set via `model: opus` in each agent's frontmatter — no per-call model parameter is needed.

Agents are registered in `plugin.json` and defined in the `agents/` directory.

### 4.5 Architect-Only Re-submission Cap

The architect review in Step 5a allows targeted re-submissions before the critic is involved:

- **On ITERATE:** Revise the plan based on architect findings (targeted edits), then re-submit to Step 5a.
- **Maximum 2 architect-only iterations.** If the architect still returns ITERATE after 2 re-submissions, proceed to Step 5b (Critic Review) regardless — carry the unresolved architect findings in the context payload so the critic is aware of them.

This cap prevents infinite architect loops on borderline plans and ensures the critic always gets to evaluate.

### 4.6 Fast-Fail Rule

During the re-review loop (Step 5c), if the same CRITICAL or MAJOR finding (matched by dimension and description) appears in two consecutive iterations without change, exit the loop immediately.

Targeted edits cannot resolve a finding that has survived two revision cycles unchanged. When fast-fail triggers:

1. Halt the re-review loop
2. Surface all outstanding findings to the user
3. Note that automated review could not converge on this finding
4. Let the user decide whether to proceed or rework the plan manually
