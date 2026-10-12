---
name: aidlc-sprint
description: Implement a Jira ticket end-to-end in Kiro with TDD. Fetches the issue over the Atlassian MCP (summary, description, acceptance criteria, child tasks, Test Scope comment), gathers codebase context, plans test-first, writes failing tests then the minimum code to pass, refactors, runs the full suite, opens a PR with evidence, and moves the ticket's status. Use when asked to implement or work on a Jira issue — e.g. "work on PROJ-123", "implement TLINE-456", "start a sprint for ENG-789", "pick up this ticket".
---

# AI-DLC Sprint — Jira ticket → working code (Kiro)

Take one Jira ticket and implement it with test-first discipline, leaving an auditable trail.
The job is done when every acceptance criterion has a test that was shown to fail, then pass, the
full suite is green, and a PR carries the evidence — not before.

## Input
A Jira issue key (`PROJ-123`). If the user names a sprint/epic instead, list its child tickets and
ask which one to implement (one ticket per run).

## Prerequisites
- **Atlassian MCP** configured in `.kiro/settings/mcp.json` (this is how the ticket is read and its
  status moved — no `acli` needed). If no Atlassian MCP is available, ask the user to paste the
  ticket text and continue; status transitions then fall back to a reminder for the user to do by hand.
- A git repository with a known **test command** (from the project's `AGENTS.md`, README, or ask).
- Write access to open a branch/PR (GitLab/GitHub MCP or local `git` + `glab`/`gh`).

## Guardrails (always apply)
- **draft → approve → publish.** Show the plan and wait for an explicit "yes" before writing code.
  Never post a comment, change ticket status, push, or open a PR until the user approves *that* action.
- **No secrets** in code, tests, commits, comments, or PR text.
- **Never mark anything done without executed, passing tests.** An unrun test is `NOT RUN`, never a pass.

---

## Workflow

### 1. Fetch the ticket (Atlassian MCP)
Use the Atlassian MCP to read the issue — e.g. `getJiraIssue` for `PROJ-123`. Collect:
- **summary, description, issue type, status**, and **acceptance criteria** (look for `AC-*`, a
  "## Behaviour" Task-Spec block, or an "As a… I want… so that…" story).
- **child tasks** (if it's a parent) for scope context.
- **comments** — find one containing `## Test Scope` and extract its scenario table; this drives the
  test plan in step 3. If several exist, use the most recent and tell the user to clean up duplicates.
  If none exists, derive tests from the acceptance criteria alone.

Restate the ticket back to the user in two or three sentences so scope is agreed before any work.
If the acceptance criteria are vague or untestable, **stop and clarify** — do not guess.

### 2. Gather codebase context
Locate the files, existing patterns, and related tests this change touches (Kiro's search + file
reads). Note the integration points and the covering **test command**. Prefer the project's existing
conventions over introducing new ones.

### 3. Draft a TDD plan → get approval
Produce a short plan: the behaviours to build (mapped to each `AC-*`), the test cases (unit +
integration, including **negative / permission paths**), the test files to add or change, and the
implementation cycles (one behaviour per cycle). Keep it tight. **Present it and wait for approval.**

### 4. Create a feature branch
From an up-to-date default branch, create `feature/<JIRA-KEY>-<slug>`. Confirm the repo matches the
ticket before branching.

### 5. Implement test-first (the loop)
For **each** behaviour, run the red→green→refactor→regression loop in `references/tdd-loop.md`:
write a failing test, **capture the failing output**, implement the minimum to pass, **capture the
passing output**, refactor green, then run the relevant suite. Record the red/green evidence as you
go — step 6 cites it. One behaviour at a time; no scope creep.

### 6. Verify completion (gate)
Before declaring done, run the checklist in `references/verification.md` and report each item
`PASS` / `FAIL` / `NOT RUN` / `N/A` **with evidence**. Any `FAIL`, or an unjustified `NOT RUN` on an
applicable item, means **NOT COMPLETE** — return to the loop. Do not skip to the PR.

### 7. Open a PR with evidence
Build the PR per `references/evidence-pr.md`: what changed and why (ticket link), the AC→test map, the
red/green + regression evidence, and a rollback note if there are migrations. **Get approval**, then
open the PR (GitLab/GitHub MCP or `glab`/`gh`). Paste the PR URL and CI status back — confirmed, not
assumed.

### 8. Move the ticket status (Atlassian MCP)
With approval, transition the Jira issue (e.g. `getTransitionsForJiraIssue` then
`transitionJiraIssue`) to the project's in-review/done state, and optionally add a comment linking the
PR (`addCommentToJiraIssue`). If no MCP write access, tell the user the exact transition to make.

---

## Definition of Done
- Every targeted `AC-*` has a test shown **red then green**, with evidence recorded.
- The full relevant suite is **green** (actual run output, not "should pass").
- Negative/permission paths covered; no known P0/P1 defects in scope.
- PR opened with the evidence pack and link to `PROJ-123`; CI status confirmed.
- Ticket status transitioned (or the exact manual step handed to the user).

## References (loaded on demand)
- `references/tdd-loop.md` — the red→green→refactor loop + what evidence to capture.
- `references/verification.md` — the completion checklist and verdict rule.
- `references/evidence-pr.md` — PR body structure + rollback note.
