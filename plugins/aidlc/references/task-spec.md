# Task Specification Schema

**Schema version:** 1.0  
**Introduced in:** AIDLC 3.9.0

Task Specifications are the primary task artefact in AIDLC. They replace user stories and are generated during the design phase, after ADRs and domain/logical design are complete. The format is optimised for AI agent consumption while remaining scannable by humans.

All agents and skills that create, validate, or consume tasks MUST reference this file as the canonical contract.

---

## Field Reference

### Frontmatter (YAML)

Structured fields consumed programmatically by agents and tooling.

| Field | Required | Type | Constraints |
|-------|----------|------|-------------|
| `id` | Yes | string | Format: `U\d{2}-T\d{2}` (e.g. `U01-T03`) |
| `title` | Yes | string | Max 80 characters |
| `sprint` | Yes | integer | Must reference an existing sprint id in the sprint plan |
| `size` | Yes | integer | Fibonacci: `1`, `2`, `3`, `5`, `8`, or `13` |
| `files` | No (recommended) | object | See `files` sub-fields below |
| `dependencies` | No | array | See `dependencies` sub-fields below |

#### `files` sub-fields

At least one sub-field must be present if `files` is included.

| Sub-field | Type | Meaning |
|-----------|------|---------|
| `modify` | list of paths | Existing files the task changes |
| `create` | list of paths | New files the task introduces |
| `reference` | list of paths | Files to read for patterns/context but not change |

#### `dependencies` sub-fields

Each dependency entry must include all three fields.

| Sub-field | Required | Type | Constraints |
|-----------|----------|------|-------------|
| `on` | Yes | string | Description of what is depended on |
| `type` | Yes | string | `blocking` or `non-blocking` |
| `environment` | No | string | When the dependency applies (e.g. `deploy`, `test`, `local`) |
| `rationale` | Yes | string | Why this dependency exists and how it's handled |

### Body (Markdown)

Human-readable sections consumed by agents as natural language. Agents read these as the specification text, not as structured data.

| Section | Required | Purpose |
|---------|----------|---------|
| `## Behaviour` | Yes | Observable outcomes - the acceptance test list, what "done" looks like. At least one bullet point required. |
| `## Acceptance Criteria` | **Yes** (unless size 1) | Given/When/Then scenarios with **concrete values**, not paraphrase. Each observable behaviour maps to at least one scenario. Include the happy path plus the error/edge scenarios from the Errors table. Example: "Given `{tier:"Standard"}` When `POST /x` Then `201` with `{id,token}`, TTL 30 min". |
| `## Data Contract` | **Yes if** the task exposes/consumes an API, message, or persists data | Request and response shapes with **field names + types**, status codes, and which values are server-authoritative. Omit only for tasks with no data surface (pure UI layout, config). |
| `## Errors & Edge Cases` | **Yes if** the task has inputs, external calls, or state | Table of condition → result: validation failures (with status codes), not-found, expiry, conflict/duplicate, rate limits, empty/zero states, timeouts. No "handle errors gracefully" hand-waving — enumerate them. |
| `## UI States` | **Yes if** the task renders UI | The states the surface must handle: loading, empty, error, success, disabled/permission. |
| `## NFRs` | **Yes if** a measurable target applies | Per-task non-functional targets with numbers (latency, rate limit, payload size, retention), traceable to the design/Intent NFRs. |
| `## Rules` | No | Hard constraints that bound the solution. Include when constraints would not be obvious from Behaviour alone. |
| `## Assumptions` | **Yes if** any detail was assumed | `[ASSUMED]`-labelled items filled with a default because the input did not specify (e.g. `[ASSUMED] session TTL = 30 min — confirm`). Never leave a silent placeholder; either the value is specified upstream or it appears here for confirmation. |
| `## Risks` | No | One-liner per risk with mitigation. Escalates from Epic-level risks that affect this specific task. |
| `## Not in Scope` | No | Explicit boundaries. Include when scope could be misread or is non-obvious. |

---

## Validation Rules

1. `id` must match `U\d{2}-T\d{2}` exactly.
2. `title` must not exceed 80 characters.
3. `sprint` must reference a sprint id that exists in the active sprint plan for this project.
4. `size` must be one of: `1`, `2`, `3`, `5`, `8`, `13`.
5. If `files` is present, at least one of `modify`, `create`, or `reference` must be non-empty.
6. If `dependencies` is present, each entry must have `on`, `type`, and `rationale`.
7. `type` in each dependency must be `blocking` or `non-blocking`.
8. `## Behaviour` must be present and contain at least one bullet point.
9. No other frontmatter fields are permitted (unknown fields cause a validation warning).
10. **Sufficiency (depth) rules** — a spec fails validation (not just a warning) when:
    - `size` ≥ 2 and `## Acceptance Criteria` is missing, or its scenarios are paraphrase without concrete values.
    - the task has a data/API surface but no `## Data Contract` with typed fields and status codes.
    - the task has inputs/external calls/state but no `## Errors & Edge Cases` table.
    - the task renders UI but has no `## UI States`.
    - a measurable NFR applies but no `## NFRs` numbers are given.
11. **No silent placeholders.** Any value that was not specified upstream must appear as an `[ASSUMED]` item under `## Assumptions` (with a proposed default to confirm), or be resolved via a clarify question during `/aidlc-design`. Vague fillers ("appropriate", "as needed", "handle gracefully", "etc.") in Behaviour/AC/Rules fail validation.

---

## Format Detection

Skills detect task format by content inspection:

- **Task Spec:** presence of `## Behaviour` section, or `behaviour`/`rules` in YAML frontmatter
- **User story (legacy):** presence of "As a..." phrasing or "Given/When/Then" structure

Detection is logged by each skill so users can see which format is active.

---

## `sprint` Mutability

`sprint` represents the sprint assignment at generation time. Tasks can be rebalanced during `aidlc-verify`. When rebalancing occurs:

- `sprint` is updated in the Task Spec markdown file (GitLab)
- The Jira/Linear ticket is moved to the correct sprint
- The Confluence task page is updated
- A diff of all sprint changes is shown to the user for confirmation before Jira transfer

`aidlc-sprint` treats `sprint` as a soft hint: if a task's sprint value does not match the sprint currently being implemented, the agent warns rather than refusing.

---

## `files` Fallback (for `aidlc-sprint`)

When `files` is absent or incomplete, `aidlc-sprint` falls back in order:

1. Grep for symbols referenced in `behaviour`/`rules` text
2. Repo scan for files matching task title keywords
3. Pattern matching against known conventions (e.g. controller/service/test file triads)

The fallback used is noted in the implementation log. If no files can be resolved, the agent asks the user to confirm the working set before proceeding.

---

## Sizing Guide

Sizes follow the Fibonacci scale. The sweet spot for a single task is 3-5.

| Size | Meaning |
|------|---------|
| `1` | Trivial change, single file, no logic |
| `2` | Small, 1-2 files, straightforward logic |
| `3` | Standard task, up to 3 files, moderate complexity |
| `5` | Larger task, several files or non-trivial logic |
| `8` | Complex task - consider splitting |
| `13` | Should be split. Only acceptable when splitting would create artificial dependencies |

See `references/task-sizing.md` for the full sizing rubric.

---

## Worked Example

```markdown
---
id: U01-T03
title: Rate-limit failed login attempts
sprint: 2
size: 5
files:
  modify:
    - src/Api/Auth/LoginController.cs
    - src/Api/Auth/RateLimitMiddleware.cs
  create:
    - tests/Api/Auth/RateLimitMiddlewareTests.cs
  reference:
    - src/Api/Middleware/BaseMiddleware.cs
dependencies:
  - on: Persistent state store availability
    type: non-blocking
    environment: deploy
    rationale: Can use in-memory store for local dev; persistent store required for production
---

## Behaviour

- Repeated failed logins from the same origin are throttled after a configurable threshold
- Successful login clears the throttle state for that origin
- Throttled requests receive a clear signal to retry later (not a generic error)
- Throttle state persists across application restarts

## Rules

- Threshold and window duration must be configurable via app settings
- Must not affect legitimate users during normal usage patterns
- Must operate independently of any gateway-level controls

## Risks

- Shared infrastructure for state persistence - mitigate with in-memory fallback for local dev

## Not in Scope

- Account lockout policy (separate task)
- IP allowlisting
- Admin UI for managing throttle state
```

---

## Rationale

Each field earns its place by being something an AI agent actively uses during implementation:

| Field | Why the agent needs it |
|-------|------------------------|
| `id` | Cross-referencing between tasks, sprints, and epics |
| `title` | Branch naming, commit messages, PR titles |
| `sprint` | Knows which group of tasks it's working within |
| `size` | Internal sizing for scheduling |
| `behaviour` | The acceptance test list - what "done" looks like |
| `rules` | Hard constraints that bound the solution; prevents over-engineering |
| `files` | Exactly where to work, which patterns to follow, what to create |
| `dependencies` | Whether to mock something or wait for it |
| `risks` | What to watch out for during implementation |
| `not_in_scope` | What NOT to build; prevents scope creep |

**What's deliberately absent:**

- "As a... I want... So that..." - captured at Epic level; repeating it per task adds words without information
- Given/When/Then - replaced by `Behaviour` (observable outcomes) and `Rules` (constraints); more concise
- Context/background narrative - the design documents (ADRs, domain model) provide this
- Risk impact/likelihood matrix - overkill at task level; Epics carry the detailed risk table
- Test notes - replaced by sprint-level test scopes generated during design
