---
name: aidlc-sprint
description: Guide implementation of a sprint (rapid iteration cycle) with TDD emphasis. Gathers context from Jira or Linear, creates a TDD-focused plan, stores it locally, and creates a feature branch for implementation. Supports Jira (GitLab/Confluence backends) and Linear backends. (Triggers - sprint, implement sprint, start sprint, sprint implementation, new sprint, work on PROJ-123, work on ENG-456, pick up sprint, next sprint, begin work on, sprint for issue)
---

# AI-DLC Sprint Implementation

Guide the implementation of a sprint (rapid iteration cycle) with emphasis on Test-Driven Development (TDD). This skill helps developers execute focused, testable increments of work.

> **What is a Sprint?**
>
> A Sprint is the smallest iteration cycle in AI-DLC, typically lasting hours to days.
> It delivers a testable increment of functionality and follows the TDD rhythm:
> Red (write failing test) → Green (make it pass) → Refactor (improve code quality).

## AI-Drives-Conversation Pattern

This skill follows the AI-DLC principle where AI initiates and directs the conversation:

1. **AI gathers** — Collect context from work tracker (Jira or Linear) and repository
2. **AI plans** — Create TDD-focused implementation plan
3. **AI reviews** — Architect + critic consensus review of the plan
4. **Human approves** — Review and approve the plan
5. **AI executes** — Create branch and begin implementation with progress tracking

## Example Invocations

- "Start a sprint for PROJ-123" (Jira)
- "Start a sprint for ENG-456" (Linear)
- "Implement the authentication story"
- "Begin a sprint for the API endpoint task"
- "New sprint for the database migration"

## References

- @${CLAUDE_PLUGIN_ROOT}/references/planning-shared.md — Sprint guidance and templates
- @${CLAUDE_PLUGIN_ROOT}/references/vcs-detection.md — VCS provider detection and PR/MR commands
- @${CLAUDE_PLUGIN_ROOT}/references/review-criteria.md — Implementation review rubric ("Finding Severity Levels" and "Implementation Review Rubric" sections); used for plan quality checks and Step 13.5 self-review
- @plugins/standards/references/technical-guidance/global.md — Universal standards (always load)
- @plugins/standards/references/technical-guidance/dotnet.md — For .NET projects
- @plugins/standards/references/technical-guidance/rails.md — For Rails projects
- @plugins/standards/references/technical-guidance/vue.md — For Vue projects
- @plugins/standards/references/technical-guidance/iac.md — For IaC projects
- @plugins/standards/references/technical-guidance/application-profiles/README.md — For .NET: profile detection markers and selection logic; load the matching profile file after detection

## CodeRabbit Review Handler

This section defines the reusable CodeRabbit review pattern. It is called from Step 13. The `triage_mode` is captured at the Step 13 opt-in prompt and passed to the handler.

### Detect Runtime (cache for the session)

On the **first review attempt** in the session, determine how to invoke the CodeRabbit CLI. The probe depends on the host platform:

1. **Detect platform:** Use `$env:OS` equalling `"Windows_NT"` as the primary Windows signal (PowerShell-only; reliable). As a secondary check on non-PowerShell shells, confirm with `uname -s` — if it returns `Linux` or `Darwin`, the host is Unix-like regardless of whether a `wsl` binary exists on PATH (some Linux distros ship a WSL shim that makes `wsl --status` return 0, which would otherwise falsely trigger Windows detection).

2. **Unix-like host:** Probe for the CLI:
   ```bash
   which coderabbit 2>/dev/null || find "$HOME/.local/bin" /usr/local/bin -name coderabbit -maxdepth 1 2>/dev/null | head -1
   ```
   If a path is found, set `coderabbit_runtime = native` and use `coderabbit ...` for all subsequent calls.

3. **Windows host:** Skip the native probe entirely — CodeRabbit has no official Windows build and probing for a native binary risks picking up unofficial third-party ports. Instead, locate the binary inside WSL using its absolute path (narrow search to avoid slow `/home` traversal):
   ```bash
   wsl which coderabbit 2>/dev/null || wsl bash -c 'find /usr/local/bin "$HOME/.local/bin" -name coderabbit -maxdepth 2 -type f 2>/dev/null | head -1'
   ```
   If a path is returned (e.g. `/home/djuba/.local/bin/coderabbit`), cache it as `coderabbit_wsl_path` and set `coderabbit_runtime = wsl`. All subsequent invocations use `wsl <coderabbit_wsl_path> ...` — this bypasses PATH expansion issues caused by Windows paths with parentheses (e.g. `Program Files (x86)`) being inherited by WSL non-interactive shells.

   > **Environment note:** CodeRabbit must be installed in the same environment where `git` commands are executed. If `git` runs on the Windows host but CodeRabbit is only available inside WSL (the normal setup), use the `wsl <path>` invocation above. Running `git` inside WSL while CodeRabbit is on the Windows host (or vice versa) will produce path mismatches and incorrect review scope.

4. If the platform-appropriate probe fails, proceed to the Prereq Check's missing-CLI branch.

Cache `coderabbit_runtime` and `coderabbit_wsl_path` (or the explicit "missing" state) for the session. Subsequent review attempts skip detection and reuse the cached values.

### Prereq Check (cache for the session)

After Detect Runtime, verify auth for the detected runtime:

```bash
# Unix-like (native runtime):
coderabbit auth status 2>&1

# Windows (wsl runtime):
wsl <coderabbit_wsl_path> auth status 2>&1
```

**If CLI is missing or unauthenticated**, present a blocking choice to the user using AskUserQuestion. The install instructions in option 1 vary by detected platform:

1. **Install now** — Display install + auth commands for the detected platform. Wait for the user to confirm they've run them, then re-run Detect Runtime (the WSL `find` probe on Windows, or the native `coderabbit --version` probe on Unix). If still failing, repeat.

   **macOS / Linux:**
   ```bash
   curl -fsSL https://cli.coderabbit.ai/install.sh | sh
   # or: brew install coderabbit
   coderabbit auth login
   ```

   **Windows (PowerShell / cmd):**
   ```
   CodeRabbit doesn't publish a native Windows build.
   The official supported path on Windows is WSL.

   Setup guide: https://docs.coderabbit.ai/cli/wsl-windows

   Once WSL is set up with a Linux distro, open a WSL terminal and run:
     curl -fsSL https://cli.coderabbit.ai/install.sh | sh
     coderabbit auth login
   ```

2. **Continue without CodeRabbit reviews** — Explicit, deliberate skip. Append a prominent block to `sprint-plan.md`:
   ```
   ## CodeRabbit Reviews — Disabled for this Sprint (user chose to skip install)
   ```
   Cache "skipped" for the rest of the session — do not re-prompt on subsequent review attempts.
3. **Cancel Sprint** — Exit the skill cleanly with no commits, no status transitions.

If the user already cached "skipped" earlier in the session, return "skipped" without re-prompting.

### Run and Parse

Run the review using the cached `coderabbit_runtime` with scope `--base <default_branch>` (where `<default_branch>` is the value resolved in Step 13). The `--agent` flag switches to output optimised for AI consumption — structured findings with file paths, line numbers, and severity, rather than interactive terminal output. Capture stdout:

```bash
# Unix-like (native runtime):
coderabbit review --agent --base <default_branch>

# Windows (wsl runtime) — uses absolute path to avoid PATH expansion issues:
wsl <coderabbit_wsl_path> review --agent --base <default_branch>
```

Parse the `--agent` output and extract findings into three severity buckets:
- **Critical** — security vulnerabilities, data loss risks, crashes
- **Warning** — bugs, performance issues, anti-patterns
- **Info** — style suggestions, minor improvements

For each Critical/Warning finding, extract: file path, line number, severity, and a one-line description.

### Path Normalization (WSL runtime only)

When `coderabbit_runtime = wsl`, file paths in the review output use WSL form (e.g. `/mnt/c/trigent/repos/claude-plugins/foo.md`). Before passing paths to Read/Edit tools or displaying them to the user, translate:

- `/mnt/<letter>/<rest>` → `<LETTER>:\<rest with / replaced by \>`
- Example: `/mnt/c/trigent/repos/claude-plugins/src/Foo.cs` → `C:\trigent\repos\claude-plugins\src\Foo.cs`

If a finding's path doesn't start with `/mnt/<letter>/`, leave it as-is.

### Triage Each Finding (Critical/Warning only)

For every Critical/Warning finding, Claude independently:

1. Reads the relevant file(s) and surrounding context
2. Judges whether the finding is valid given the codebase's conventions and the Task's intent
3. Classifies as one of:
   - `valid-must-fix` — real issue that should be fixed before MR
   - `valid-optional` — real issue in scope of this file/area but not required for the Task's acceptance criteria (e.g. cosmetic, nice-to-have)
   - `invalid-false-positive` — CodeRabbit flag does not reflect an actual issue
   - `invalid-out-of-scope` — finding concerns a part of the codebase unrelated to this Sprint entirely
4. Records a one-sentence rationale for the classification

Info-level findings are acknowledged-only — no triage, no auto-fix in any mode.

### Apply Triage Mode

**`triage_mode = interactive` (default):**

Present each finding in severity order (Critical first) with:
- Severity + file:line
- CodeRabbit's description
- Claude's classification + rationale
- Proposed diff (if applicable)

Use AskUserQuestion with choices: **Apply fix** / **Defer** / **Modify** / **Skip (mark invalid)**

**`triage_mode = semi-auto`:**

Auto-apply `valid-must-fix` findings where Claude has high confidence. Present `valid-optional` and any ambiguous findings (confidence < high) for user decision. Log `invalid-*` silently.

**`triage_mode = automated`:**

Apply all `valid-must-fix` findings without prompting. Log everything else to plan file.

### Persist Findings to Sprint Plan

Append to `sprint-plan.md` under `## CodeRabbit Reviews`. Entries are **append-only** — each run adds a new block. Re-running the review (e.g. after a rebase) will produce a new entry rather than updating an existing one; this is expected and provides a full audit trail.

```markdown
### Review — pre-mr — <ISO timestamp>
- Scope: --base <default_branch>
- Iteration: <n of max 2>
- Triage mode: <interactive | semi-auto | automated>
- Findings:
  - [valid-must-fix] src/Auth.cs:42 — Null check missing — APPLIED (commit abc1234)
  - [invalid-false-positive] src/Auth.cs:88 — Suggested rename to camelCase — SKIPPED (codebase uses PascalCase per convention)
  - [valid-optional] src/Auth.cs:120 — Could extract helper — DEFERRED (cosmetic, out of Task scope)
  - [info] src/Auth.cs:5 — Consider adding XML doc — ACKNOWLEDGED
- Status: <clean | info-only | requires-fix>
```

### Commit Applied Fixes

After each fix-loop iteration where at least one fix was applied, create a separate commit:

```
fix(<JIRA-KEY>): address CodeRabbit findings (iteration <n>)

- src/File.cs:42 — Null check missing
- ...

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Fix Loop

1. **Iteration 1:** Triage + apply fixes per `triage_mode`. Commit (if fixes applied). Re-run review.
2. **Iteration 2:** Triage remaining findings. Apply + commit (if fixes applied). Re-run.
3. **After iteration 2:** If `valid-must-fix` findings remain, **stop the loop** — surface the unresolved items and ask the user whether to proceed to MR anyway (override) or stop.

If `triage_mode = interactive`, after the fix loop optionally ask using AskUserQuestion: "Address Info-level findings too? (1. Yes / 2. No, skip them)"

### Error Handling

**Rate-limit / network errors:** If `coderabbit review` exits non-zero due to an API failure (not findings), log a warning to `sprint-plan.md` and continue the workflow without blocking:

```
## CodeRabbit Reviews — API error at <phase> (<timestamp>). Review skipped for this phase.
```

---

## Workflow

### Work Item Status Management Utility

Throughout the Sprint workflow, use `transition_status(item_id, target_status, item_type, backend)` to transition Jira or Linear statuses. See @${CLAUDE_PLUGIN_ROOT}/references/status-management.md for backend-specific strategies, error handling, and return format.

### Phase 1: Context Gathering

#### Step 1: Gather Work Item Context

Ask for the work context — the Sprint identifier depends on the work tracking backend:

```
What Sprint should I work on?

Please provide one of:
- Jira issue key (e.g., PROJ-123)
- Linear Issue URL or ID (e.g., https://linear.app/team/issue/ENG-456 or ENG-456)
```

**Detect backend** from the provided identifier:
- Jira key format (`PROJ-123`) → Jira backend
- Linear URL or short ID (`ENG-456`, `linear.app` URL) → Linear backend

#### Jira Backend (GitLab/Confluence documentation):

Fetch the Jira issue using the `acli` CLI (preferred for lower token usage):
```bash
# First check acli is installed
which acli || echo "acli not installed - see: https://developer.atlassian.com/cloud/acli/"

# Fetch the Sprint with relevant fields
acli jira workitem view PROJ-123 --fields summary,description,status,issuetype --json

# Fetch child Tasks for context
acli jira workitem children PROJ-123 --json
```

Extract acceptance criteria, description, and dependencies from the response. Note the Tasks that are part of this Sprint.

**Fetch test scope comment:**
```bash
acli jira workitem comments PROJ-123 --json
```
Look for a comment containing `## Test Scope`. Extract and store the scenario table — this will be used in Step 4 to guide the TDD plan. There should only be one such comment per ticket; if more than one exists, use the most recent and note it to the user so they can clean up the duplicates. If no matching comment is found, the test plan will be derived from acceptance criteria only.

**Detect task format for each Task:**
- **Task Spec** (AIDLC 3.9+): description contains `## Behaviour` → use `## Behaviour` items as acceptance criteria, `## Rules` as hard constraints
- **User story** (legacy): description contains "As a..." → use existing acceptance criteria extraction

For Task Spec format, the `files` section lists files to create, modify, and reference. If absent, apply the fallback chain in Step 2a.

#### Linear Backend:

Fetch the Linear Issue and related Issues:
```typescript
// Fetch the Sprint Issue
get_issue({ query: "<issue-id>" })

// List sibling Issues in the same Project with the same Sprint label
list_issues({ project: "<project-id>", labels: ["<sprint-label>"] })
```

Extract acceptance criteria from the Issue description. Note the sibling Issues (Tasks) that share the same Sprint label.

Apply the same format detection as the Jira backend above: `## Behaviour` → Task Spec; "As a..." → user story.

**Fetch test scope comment:**
```typescript
get_issue_comments({ issueId: "<sprint-issue-id>" })
```
Look for a comment containing `## Test Scope`. Extract and store the scenario table — this will be used in Step 4 to guide the TDD plan. There should only be one such comment per ticket; if more than one exists, use the most recent and note it to the user so they can clean up the duplicates. If no matching comment is found, the test plan will be derived from acceptance criteria only.

#### Resolve Current User Identity (both backends, once per session):

Before the Smart Status Sync, resolve the current user's identity for ticket assignment. Cache the result for the session — do not re-probe on subsequent sprints.

```bash
git config user.email
```

**Jira backend:** Pass the email to `lookupJiraAccountId`. Cache the returned account ID as `current_user_account_id`.

**Linear backend:** Use the Linear MCP to look up the user by email. Cache as `current_user_linear_id`.

**If resolution fails** (no git email configured, or email returns no match in Jira/Linear):
- Log inline: `ℹ Could not resolve Jira/Linear account from git email (<email or "not set">). Tickets will be left unassigned.`
- Set `current_user_account_id = null` / `current_user_linear_id = null`.
- Continue — assignment is non-blocking.

#### Smart Status Sync (both backends):

After fetching context, analyze current statuses and offer to transition to "In Progress":

1. **Parse current statuses** from response:
   - Sprint status (e.g., "To Do"/"Backlog", "In Progress"/"Started", "In Review", "Done")
   - Each Task status
   - Current assignee for each item

2. **Identify items to transition:**
   - Sprint: "To Do"/"Backlog" → "In Progress"/"Started" (skip if already active or done)
   - Tasks: "To Do"/"Backlog" → "In Progress"/"Started" (only items not yet started)

3. **Display summary to user:**

   If `current_user_account_id` resolved:
   ```
   Ready to start Sprint <ID> with N Tasks.

   Status transitions needed:
   - Sprint <ID>: "To Do" → "In Progress"
   - Task <ID>: "To Do" → "In Progress"
   - Task <ID>: Already "In Progress" (resuming)

   Assigning all items to: <git config user.name or email>
   ⚠ Task <ID> is currently assigned to <existing-assignee> — reassign to you? (y/n)

   Proceed? (y/n)
   ```

   If `current_user_account_id = null`:
   ```
   Ready to start Sprint <ID> with N Tasks.

   Status transitions needed:
   - Sprint <ID>: "To Do" → "In Progress"
   - Task <ID>: "To Do" → "In Progress"

   ⚠ Could not resolve your account — tickets will be left unassigned.

   Proceed with status updates only? (y/n)
   ```

4. **If user confirms:**
   - Execute transitions using `transition_status()` for each item
   - If `current_user_account_id` resolved, assign each item immediately after its transition:
     - **Jira (acli preferred):**
       ```bash
       acli jira workitem edit <issue-key> --field "Assignee" --value "<account-id>"
       ```
       Fall back to MCP `editJiraIssue({ assignee: { accountId: "<id>" } })` if acli fails.
     - **Linear:**
       ```typescript
       save_issue({ id: "<issue-id>", assigneeId: "<linear-user-id>" })
       ```
   - For items already assigned to someone else: only reassign if user confirmed "y" at the per-ticket prompt in step 3. Skip otherwise.
   - Display results with [ok]/[!]/[fail] indicators:
     ```
     [ok] Sprint <ID>: "To Do" → "In Progress", assigned to <name>
     [ok] Task <ID>: "To Do" → "In Progress", assigned to <name>
     [!] Task <ID>: assignment failed — assign manually in Jira/Linear
     ```
   - Log any items that are already in the correct state.
   - Assignment failures are non-blocking — log and continue.

5. **If user declines:**
   - Log: "Skipping status updates. Please update manually if needed."
   - Continue workflow

6. **Status Inconsistency Detection:**
   - If Sprint is "In Review" but Tasks are not all "Done", warn:
     ```
     [!] Warning: Status mismatch detected
     Sprint <ID> is "In Review" but <TASK-ID> is "In Progress"

     This may indicate incomplete work. Continue anyway? (y/n)
     ```

#### Step 2: Validate Repository Context

Confirm the user is in the correct repository context:
1. Check current working directory
2. Verify the repository is relevant to the Jira artifact
3. If multiple repositories are needed, confirm they are cloned locally

Ask if needed:
```
I see you're in [current repo]. Is this the correct repository for this work?
If this sprint spans multiple services, please list the local paths to all repositories.
```

#### Step 2a: Discover Implementation Patterns

Load the relevant standards references for this project type (see References above). The standards document what patterns to look for and what the organisational baseline is. For .NET projects, also load `application-profiles/README.md` to identify the application profile using its detection markers, then load the matching profile file.

**For brownfield repos**, use the loaded standards and application profile as a detection guide — scan the codebase to identify which patterns are actually in use (DI container, mocking library, mapping approach, test framework, HTTP client). The application profile documents the detection markers for each variant.

> **Critical guardrail:** Match whatever patterns are already in the codebase. Do NOT suggest migrating DI containers, swapping mocking libraries, or changing mapping approaches unless the Task explicitly calls for it. The goal is code that feels native to the existing repo and reduces cognitive load during MR review.

**For greenfield repos**, the standards are the baseline. Check that the repo was initialised from the Trigent template project for this stack (see the "New Project Setup" section in `dotnet.md` or `rails.md`). If it was not, recommend doing so before writing any code — the templates scaffold the correct structure and tooling. Then apply the conventions from the loaded standards and application profile.

**Task Spec `files` fallback chain:**

If a Task uses Task Spec format but has no `files` field, infer relevant files in this order:

1. **Grep for symbols**: Search the codebase for class or method names from the Task title
   ```bash
   grep -r "<TaskTitleKeywords>" src/ app/ lib/ --include="*.cs" --include="*.ts" --include="*.rb" -l
   ```

2. **Repo scan for domain area**: Look for files in directories matching the Epic's domain area
   - e.g., `src/<epic-slug>/`, `app/models/<epic-slug>*`, `lib/<epic-domain>/`
   - Match by naming convention: `*Controller*`, `*Service*`, `*Repository*`, `*Handler*`

3. **Pattern matching from context**: If steps 1 and 2 return nothing, infer from:
   - Files touched in completed sprints from the same Epic
   - Files referenced in the design phase domain model or ADRs
   - Implementation patterns discovered in this step (standards scan)

Present the inferred files to the user for confirmation before planning.

#### Step 2.5: Determine Sub-agent Strategy

Based on the Sprint's Tasks, decide whether to use parallel sub-agents:

**Single Task:** Proceed with single-agent exploration (Step 3).

**Multiple Tasks:** Spawn parallel Task Context Agents to explore in parallel.

Ask:
```
This Sprint has [N] Tasks. Should I explore the codebase for each Task in parallel?
(Recommended for efficiency - each Task gets focused exploration)

1. Yes, explore in parallel (recommended)
2. No, explore sequentially
```

#### Step 3: Explore Codebase (Parallel or Sequential)

**Before exploring, check the current branch against the remote default:**

```bash
git branch --show-current
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

The second command resolves the remote's default branch (e.g. `main`, `develop`, or whatever the team uses). If that command returns nothing (remote HEAD not set), fall back to:

```bash
git remote show origin | grep 'HEAD branch' | awk '{print $NF}'
```

Store the current branch name as `detected_current_branch` and the resolved default branch name as `detected_default_branch`.

If the current branch is **not** the remote default branch, warn the user before reading any code:

```
[!] Warning: the repository is currently on branch '[branch-name]'.
The remote default branch is '[default-branch]'.

Exploring a non-default branch may give a misleading picture of patterns and conventions —
the branch could contain incomplete or experimental changes not yet in the stable codebase.

Do you want me to continue exploring on '[branch-name]', or should I switch to '[default-branch]' first?

1. Continue on '[branch-name]' (I understand it may not reflect the stable codebase)
2. Switch to '[default-branch]' first, then explore
```

Do NOT proceed with codebase exploration until explicit approval is received.

**If single Task or user declines parallel:**

Understand the implementation area:
- Identify relevant files and modules
- Understand existing patterns and conventions
- Note any related tests that exist
- Identify integration points

**If multiple Tasks and parallel approved:**

1. Spawn one **Task Context Agent** per Task using the Task tool
2. Use `subagent_type: "general-purpose"`
3. Pass Task content + repo context to each agent
4. Use the **Task Context Subagent** template from `planning-shared.md`
5. Spawn all agents in a single message (parallel execution)

**After agents return:**
1. Parse JSON results from each agent
2. Merge relevant files lists (dedupe by path)
3. Combine existing patterns discovered
4. Surface any conflicting approaches
5. Present unified context summary:

```
## Codebase Context (Consolidated)

### Relevant Files
- [file1] - relates to [Task A, Task B]
- [file2] - relates to [Task C]

### Existing Patterns
- [pattern 1]
- [pattern 2]

### Related Tests
- [test file 1] - covers [related functionality]

### Integration Points
- [API/service/database]
```

---

#### Step 3.5: Select Execution Mode

Present this prompt only after all Task Context Agents have returned and the consolidated summary has been displayed.

Ask the user how they want to proceed during implementation:

```
Codebase exploration is complete. Before I start planning, how would you like to handle implementation?

**Option 1: Manual approval per cycle** (Careful)
- I pause after each TDD cycle and wait for your approval before continuing
- You control the pace; best for critical or uncertain areas

**Option 2: Autonomous execution** (Efficient)
- I proceed through all cycles after plan approval without pausing
- I update the sprint plan file after each completed step and report a summary when done
- Best for well-understood, straightforward tasks

Which mode? (1 = manual / 2 = autonomous)
```

Store the selection as `execution_mode`. This carries forward into Phase 7.

---

### Phase 2: TDD-Focused Planning

#### Step 4: Plan Test Cases First

**If a test scope was fetched in Step 1**, use it as the primary source for the test plan — these are the scenarios agreed during `/aidlc-design` that this sprint is expected to satisfy. Map each scenario to a concrete test case, respecting the layer (Unit/API/UI/E2E) and `requires_browser` flag.

**If no test scope was found**, derive the test plan from acceptance criteria following TDD principles:

1. **Unit Tests**
   - What functions/methods need tests?
   - What edge cases should be covered?
   - What mocks/stubs are needed?

2. **Integration Tests** (if applicable)
   - What API endpoints need testing?
   - What database interactions need verification?
   - What external service interactions need mocking?

3. **Acceptance Tests** (if applicable)
   - How will acceptance criteria be verified?
   - What end-to-end scenarios should be tested?

Present the test plan:
```
## Proposed Test Cases

### Unit Tests
1. [Test description] - verifies [acceptance criterion]
2. [Test description] - handles [edge case]

### Integration Tests
1. [Test description] - verifies [integration point]

### Test Files to Create/Modify
- tests/unit/test_[feature].py
- tests/integration/test_[feature]_api.py
```

#### Step 4.5: Parallel Test Planning (Multi-Task Sprints)

**If Sprint has multiple Tasks:**

1. Spawn one **Task Test Planning Agent** per Task using the Task tool
2. Use `subagent_type: "general-purpose"`
3. Pass Task content + context from Phase 1 to each agent
4. Use the **Task Test Planning Subagent** template from `planning-shared.md`
5. Spawn all agents in a single message (parallel execution)

**Consolidation:**
1. Merge test plans into unified structure
2. Identify shared test fixtures/utilities
3. Resolve any conflicting approaches
4. Present combined test plan for approval

**Optional: Expert Perspectives**

For high-risk Tasks (security-sensitive, performance-critical, complex domain logic):

Ask:
```
This Sprint includes [security-sensitive/performance-critical/complex] Tasks.
Would you like expert perspectives on:
1. Security (OWASP, auth, input validation)
2. Performance (latency, memory, scalability)
3. Domain (business rules, edge cases)
4. All of the above
5. Skip expert review
```

If yes, spawn Expert Perspective Agents in parallel using templates from `planning-shared.md`, then integrate their recommendations into the test plan.

#### Step 5: Plan Implementation Steps

Create a detailed implementation plan structured as TDD cycles:

```
## Implementation Plan

### Cycle 1: [Feature slice]
1. RED: Write failing test for [specific behavior]
2. GREEN: Implement [minimal code to pass]
3. REFACTOR: [Specific improvements]

### Cycle 2: [Next feature slice]
1. RED: Write failing test for [specific behavior]
2. GREEN: Implement [minimal code to pass]
3. REFACTOR: [Specific improvements]

...
```

After drafting the cycles, build the **AC-to-Test Mapping** table. For every AC item, assign at least one named test (file :: method) and describe its assertion. Every row must be filled before Step 6 — TBD rows are blockers on plan approval.

---

### Phase 3: Plan Consensus Review

Plans reviewed only by the authoring agent tend to have blind spots — missing edge cases, optimistic dependency ordering, or untested acceptance criteria. A structured second-opinion pass catches these before the user commits to the plan, reducing rework during implementation.

Before running the consensus review, ask:

```
Run automated consensus review on this plan? (y/n, default y)
Skip only for trivial sprints — single-task config changes, doc fixes, or re-runs of an already-reviewed plan.
```

If y (or enter): proceed with Steps 5a and 5b.
If n: skip Phase 3 and go directly to Phase 4 (Plan Approval).

See @${CLAUDE_PLUGIN_ROOT}/references/sprint-plan-review.md for review criteria, verdict definitions, and context schema.

#### Step 5a: Architect Review

Spawn the sprint-plan-architect agent to review the plan for architectural soundness:

1. Use the Task tool with `subagent_type: "sprint-plan-architect"` (runs as opus — set in agent frontmatter)
2. Pass the full context payload:
   - Work item summary from Phase 1 (key, title, acceptance criteria)
   - Codebase context from Phase 1 (relevant files, patterns, tech stack)
   - Test plan from Step 4 (epic, integration, acceptance tests)
   - Expert perspectives from Step 4.5 (if generated)
   - Implementation plan from Step 5 (TDD cycles)
3. **Await completion before proceeding to Step 5b**

**On APPROVE:** Proceed to Step 5b (Critic Review).
**On ITERATE:** Revise the plan based on architect findings (targeted edits), then re-submit to Step 5a (maximum 2 architect-only iterations; if still ITERATE after 2, proceed to Step 5b with unresolved architect findings noted in the context payload).

#### Step 5b: Critic Review

After the architect returns APPROVE, spawn the sprint-plan-critic agent as the final quality gate:

1. Use the Task tool with `subagent_type: "sprint-plan-critic"` (runs as opus — set in agent frontmatter)
2. Pass the same context payload as Step 5a, plus:
   - Architect review findings and verdict
3. **Run only after Step 5a completes with APPROVE**

**On APPROVE:** Proceed to Phase 4 (Plan Approval).
**On ITERATE or REJECT:** Enter the re-review loop (Step 5c).

#### Step 5c: Re-review Loop

If the critic does not APPROVE, enter the re-review loop (max 3 iterations):

1. Record a scratch note before revising: `Iteration N: [changes made] — Architect: [verdict] — Critic: [verdict] — Unresolved: [CRITICAL+MAJOR count]`. This log is kept in context so the exhaustion branch can identify the iteration with fewest findings.
2. Collect architect + critic feedback from the current iteration
3. Revise the plan with targeted edits (the plan lives in LLM context at this stage — the plan file is not created until Phase 5)
4. Re-submit to the architect (Step 5a) with:
   - Revised plan
   - Summary of all prior feedback from previous iterations
   - List of changes made and outstanding issues
5. After architect APPROVE, re-submit to the critic (Step 5b)
6. Repeat until critic returns APPROVE or 3 iterations are exhausted

**Fast-fail rule:** If the same CRITICAL or MAJOR finding (same dimension and description) appears in two consecutive iterations without change, exit the loop immediately — targeted edits cannot resolve it. Surface all findings to the user with a note that automated review could not converge, and let the user decide whether to proceed.

**On iteration exhaustion (3 iterations without APPROVE):**
1. Using the per-iteration scratch notes, select the plan version with the fewest CRITICAL + MAJOR findings
2. Annotate remaining issues as "known limitations reviewed by automated consensus"
3. Present to the user in Phase 4 with a note that automated review did not fully converge
4. The user makes the final call on whether to proceed

> Run Steps 5a and 5b sequentially — the critic needs the architect's findings as input, so await the architect result before spawning the critic.

---

### Phase 4: Plan Approval

#### Step 6: Present Plan for Approval

Present the complete plan to the user:
- Summary of the work item (Jira or Linear)
- Test cases to be written
- Implementation cycles (Red → Green → Refactor)
- Estimated files to be created/modified
- Any risks or dependencies identified
- AC-to-Test Mapping table — **verify no TBD rows exist before presenting; TBD rows block approval**

**Ask explicitly:**
```
Does this plan look correct? Please approve or suggest changes before I proceed.
```

Do NOT proceed until explicit approval is received.

**If execution mode was not set at Step 3.5**, also ask now:

```
One more thing: should I proceed through all TDD cycles autonomously after this approval,
or pause for your approval after each cycle?

1. Manual — pause and wait for your approval after each cycle
2. Autonomous — proceed through the full plan, update the plan file as I go
```

Regardless of execution mode, the sprint plan file **must be updated after every completed step**.

---

### Phase 5: Local Plan Storage

#### Step 7: Prompt for Plan File Location

Ask where to store the plan:
```
Where should I save the implementation plan?

Suggested locations:
1. ./sprint-plan.md (current directory)
2. ./docs/sprints/[issue-key].md
3. Custom path

Please specify or press enter for the default (./sprint-plan.md).
```

#### Step 8: Save Plan to Local File

Create the plan file with:
- Work item context and link (Jira or Linear)
- Full implementation plan
- Progress tracking checklist
- Test cases with checkboxes
- For **Task Spec format**: populate **Acceptance Criteria** from `## Behaviour` items; add a **Constraints** section from `## Rules` items
- For **user story format**: populate **Acceptance Criteria** from the existing checklist

Use @${CLAUDE_PLUGIN_ROOT}/references/sprint-plan-template.md for the file structure.

---

### Phase 6: Feature Branch Creation

#### Step 9: Prompt for Base Branch

Ask which branch to use as the base:
```
Which branch should I create the feature branch from?

1. [detected_default_branch] (detected default — recommended)
2. [detected_current_branch] (current branch)
3. Other (please specify)
```

Default to `detected_default_branch` if user presses enter.

#### Step 10: Create Feature Branch

Create the feature branch with naming convention:

**Jira backend:** `<jira-key>-<description>` (e.g., `PROJ-123-add-user-authentication`)
**Linear backend:** `<team-prefix>-<issue-number>-<description>` (e.g., `ENG-456-add-user-authentication`)

```bash
git checkout [base-branch]
git pull origin [base-branch]
git checkout -b [issue-key]-[short-description]
```

Report branch creation:
```
Created feature branch: <issue-key>-<short-description>
Based on: main

Ready to begin implementation. The plan is saved at [plan-file-path].
```

---

### Phase 7: Begin Implementation

#### Step 10.5: Determine Implementation Strategy

**If single Task:** Proceed with sequential TDD cycles (Step 11).

**If multiple Tasks:**

1. Analyze Task dependencies from Phase 1 context
2. Identify which Tasks are independent (no shared file modifications, no sequential dependencies)
3. Offer parallel implementation for independent Tasks

Ask:
```
Based on the context gathered:

**Independent Tasks** (can run in parallel):
- [Task A] - touches [files]
- [Task B] - touches [files]

**Dependent Tasks** (must run sequentially):
- [Task C] depends on [Task A]

Should I implement the independent Tasks in parallel using separate agents?
(Recommended for efficiency - each Task gets focused TDD cycles)

1. Yes, implement in parallel (recommended)
2. No, implement sequentially
```

**Important Constraints:**
- Only parallelize Tasks with no shared file modifications
- Each agent owns its TDD cycles (Red → Green → Refactor)
- Main agent coordinates merging and resolves conflicts
- Parallel sub-agents always execute autonomously regardless of `execution_mode`. The `execution_mode` setting (manual/autonomous) applies only to the sequential path in Steps 11–12.

#### Step 11: Execute TDD Cycles (Parallel or Sequential)

**Sequential (single Task or dependent Tasks):**

Begin with the first test case:
1. Create the test file if it doesn't exist
2. Write the first failing test
3. Run the test to confirm it fails (RED)
4. If `execution_mode = autonomous`: **immediately update the sprint plan file** — change `- [ ] RED:` to `- [x] RED:` for this step, then continue to GREEN
5. If `execution_mode = manual`: report status and await explicit approval; once approved, update the sprint plan file — change `- [ ] RED:` to `- [x] RED:` — then continue

**Mandatory rule: update the sprint plan file after every completed RED / GREEN / REFACTOR step, before moving to the next step.** Use the Edit tool to change `- [ ] RED:` to `- [x] RED:`, `- [ ] GREEN:` to `- [x] GREEN:`, and `- [ ] REFACTOR:` to `- [x] REFACTOR:` — do not match other checkbox patterns (e.g. acceptance criteria, test plan items).

**Parallel (independent Tasks):**

1. Spawn one **Task Implementation Agent** per independent Task using the Task tool
2. Use `subagent_type: "general-purpose"`
3. Pass Task content + test plan + context to each agent
4. Use the **Task Implementation Subagent** template from `planning-shared.md`
5. Spawn all agents in a single message (parallel execution)
6. Agents commit independently with meaningful messages

**After parallel agents complete:**
1. Parse JSON results from each agent
2. Verify no file conflicts between agents
3. Merge any overlapping changes (rare if dependencies analyzed correctly)
4. Run full test suite to verify integration
5. **Transition Task statuses to "Done":**
   - For each completed agent's Task:
     ```
     transition_status(<task-id>, "Done", "Task", <backend>)
     ```
   - Display results: "[ok] Task <ID>: 'In Progress' → 'Done'"
6. **Update plan file** — check off all completed cycles for each Task (change `- [ ]` to `- [x]`)
7. Report completion status for all Tasks:

```
## Implementation Progress

### Task A: [Title] [done]
- Cycles completed: 3
- Files modified: [list]
- Tests passing: Yes
- Status: [ok] Done

### Task B: [Title] [done]
- Cycles completed: 2
- Files modified: [list]
- Tests passing: Yes
- Status: [ok] Done

### Integration Verification
- Full test suite: [ok] Passing
- Conflicts resolved: None
```

#### Step 12: Continue TDD Cycles (Sequential Mode)

For each cycle (when running sequentially):
1. Write failing test (RED) — run to confirm failure
2. Implement minimal code (GREEN) — run to confirm pass
3. REFACTOR — apply this checklist before marking the step complete:
   - [ ] Every AC in the plan's AC-to-Test Mapping table that this cycle covers has a passing test that asserts it (not tangentially related)
   - [ ] Apply the Common Sprint-Time Findings checklist from `review-criteria.md` Appendix A
   - Run full test suite to confirm still passing
4. After each step, update the plan file per the mandatory rule in Step 11
5. Commit with meaningful message
6. If `execution_mode = manual`: report cycle summary and await approval before starting the next cycle
7. If `execution_mode = autonomous`: proceed immediately to the next cycle

**When Task complete (all TDD cycles for a Task done):**
1. Verify all tests for this Task pass
2. Transition Task to "Done":
   ```
   transition_status(<task-id>, "Done", "Task", <backend>)
   ```
3. Display result: "[ok] Task <ID>: 'In Progress' → 'Done'"
4. Continue to next Task or proceed to Sprint completion check

Commit message format:
```
[ISSUE-KEY] [type]: [description]

- [detail 1]
- [detail 2]

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

#### Step 13: Sprint Completion Check

After all Tasks complete, verify Sprint readiness for review:

1. **Verify Prerequisites (backend-specific):**

   **Jira backend:**
   ```bash
   acli jira workitem children PROJ-123 --json | jq '.[] | {key, status}'
   ```

   **Linear backend:**
   ```typescript
   list_issues({ project: "<project-id>", labels: ["<sprint-label>"] })
   // Check all Issues have state "Done"
   ```

   **Both backends:** Run full test suite:
   ```bash
   [test command for project, e.g., pytest, npm test, dotnet test]
   ```

2. **If both prerequisites met:**

   **1a. Detect default branch** (used as CodeRabbit review scope):
   ```bash
   git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
   # fallback if above returns empty:
   git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}'
   ```
   If detection fails, default to `main`. Cache as `default_branch` for the session.

   **1b. Offer Pre-MR CodeRabbit Review** using AskUserQuestion:

   ```
   Before creating the MR, I can run a local CodeRabbit review to catch issues
   before they appear as MR comments.

   Scope: coderabbit review --agent --base <default_branch>
   Triage: I'll judge each finding (valid/invalid + rationale) before any fix is applied.

   1. Yes, run review now (recommended)
   2. Skip for this Sprint
   ```

   **If "Skip":** Continue to the completion summary. Do not cache this choice — the opt-in will be offered again on the next Sprint.

   **If "Yes":** Ask triage mode inline using AskUserQuestion:

   ```
   How would you like me to handle CodeRabbit's findings?

   1. Interactive (recommended) — I'll show my verdict on each finding and ask you to approve/defer/skip
   2. Semi-auto — I'll auto-fix high-confidence valid findings, prompt you on the ambiguous ones
   3. Automated — I'll judge and apply all valid-must-fix findings, log the rest without prompting
   ```

   Then run the **CodeRabbit Review Handler** with scope `--base <default_branch>` and the selected `triage_mode`. The handler's prereq check handles the missing-CLI case (Install / Continue without / Cancel).

   If `valid-must-fix` findings remain after the fix loop's max 2 iterations, ask the user using AskUserQuestion:
   ```
   ⚠ CodeRabbit found unresolved issues after 2 fix iterations:

   - [valid-must-fix] src/File.cs:42 — Null check missing
   - ...

   1. Stop — address these manually before creating the MR
   2. Override — proceed to MR anyway (findings will likely appear as MR comments)
   3. Cancel — exit the skill
   ```

3. **If both prerequisites met (and CodeRabbit review complete or skipped):**
   - Display completion summary then ask using AskUserQuestion:
     ```
     Sprint <ID> complete!

     [ok] All N Tasks marked Done
     [ok] Full test suite passing (X tests, 0 failures)

     Prerequisites passed — continuing to rubric self-review (Step 13.5) before transitioning.
     ```
   - Continue immediately to Step 13.5.

4. **If prerequisites NOT met:**
   - List incomplete items:
     ```
     [!] Cannot transition to "In Review" yet:

     Incomplete Tasks:
     - <TASK-ID>: Still "In Progress"

     Test failures:
     - test_authentication_flow: AssertionError
     - test_user_validation: ConnectionError

     Please complete remaining work before transitioning to "In Review".
     ```

#### Step 13.5: Rubric Self-Review

Before marking the sprint "In Review" or suggesting MR creation, perform an inline self-review against the Implementation Review Rubric (`review-criteria.md`, "Implementation Review Rubric" section). This step is mandatory — do not skip it. (Step 13.5 is the author's own gate; `/aidlc-review` is an independent peer review — use point 7 below if you want an external score instead of or in addition to self-scoring.)

1. **Score each dimension** using the band tables from the "Implementation Review Rubric" section. Think as if you were a reviewer, not the author:

   | Dimension | Weight | Your Score (0-100) | Reasoning |
   |-----------|--------|-------------------|-----------|
   | Requirements Fit | 30% | | |
   | Code Quality | 25% | | |
   | Testing Adequacy | 25% | | |
   | Security & Reliability | 20% | | |

2. **List any findings** you would raise if reviewing someone else's MR. Use the "Finding Severity Levels" severity labels:
   - `blocking` — must fix before merge (correctness, security, data safety)
   - `high` — should fix before merge (quality or reliability concern)
   - `medium` — improve in this MR or follow-up
   - `low` — nice-to-have

3. **Apply the Common Sprint-Time Findings checklist** (`review-criteria.md` Appendix A) — work through each pattern explicitly as listed there.

4. **Gate:** If any Blocking or High finding remains open, or any dimension scores below 80, **fix before proceeding**. Do not transition the sprint to "In Review" or suggest an MR until all Blocking/High issues are resolved.

5. **Write the self-review scores and findings to the plan file** (append under a `## Self-Review` heading).

6. **Once the gate passes**, verify parent-child sync, offer MR creation, then transition the sprint:
   - Confirm all Tasks are "Done" in the work tracker (not just complete in local code); no Tasks remain "To Do"/"Backlog" or "In Progress"/"Started". If a mismatch is detected:
     ```
     [!] Warning: Status mismatch detected
     Sprint <ID> will be "In Review" but <TASK-ID> is "In Progress"

     Options:
     1. Wait - fix <TASK-ID> first (recommended)
     2. Force transition - manual cleanup later
     3. Cancel

     Choice (1/2/3):
     ```
   - **Offer MR creation** using AskUserQuestion:
     ```
     Would you like to create an MR for <SPRINT-ID>?

     1. Create with /issues:create-mr — I'll invoke the issues skill, which
        interviews you for title/description and creates the MR.
     2. Create with CLI now — I'll detect your VCS provider and run
        `glab mr create` (GitLab) or `gh pr create` (GitHub) with a title
        and description built from the Sprint's Tasks and AC. You'll see the
        command before I run it.
     3. I'll create the MR myself — pause here; paste the MR URL back when
        ready (or type "skip" to continue without one).
     4. Skip MR creation for now.
     ```
     - **Option 1 (`/issues:create-mr`):** Invoke the skill. On success, record the MR URL. On failure or cancellation, re-show this prompt.
     - **Option 2 (CLI):** Detect VCS provider and default branch (see @${CLAUDE_PLUGIN_ROOT}/references/vcs-detection.md). Then:
       - **GitLab:** Construct `glab mr create --remove-source-branch --target-branch <default> --title "[<ISSUE-KEY>] <Sprint summary>" --description <generated from Tasks and AC>`.
       - **GitHub:** Construct `gh pr create --draft --base <default> --title "[<ISSUE-KEY>] <Sprint summary>" --body <generated from Tasks and AC>`.
       Show the full command to the user and run it after confirmation. Capture the MR/PR URL from stdout. On non-zero exit, surface the error and re-show this prompt.
     - **Option 3 (manual):** Output `Paste the MR/PR URL when ready (or type "skip" to continue without one):` and wait. Validate the URL matches `/-/merge_requests/\d+` (GitLab) or `/pull/\d+` (GitHub). Record URL. If user types "skip", treat as option 4.
     - **Option 4 (skip):** Proceed with no MR URL recorded.
   - Ask: "Ready to transition Sprint to 'In Review'? (y/n)"
   - If confirmed:
     - Transition the sprint:
       ```
       transition_status(<sprint-id>, "In Review", "Sprint", <backend>)
       ```
     - Display result: "[ok] Sprint <ID>: 'In Progress' → 'In Review'"
     - Show next steps tailored to whether an MR was created:
       ```
       # If MR was created:
       Next steps:
       - Request reviewers on <URL>
       - After MR merged, manually transition <SPRINT-ID> to "Done" in your work tracker

       # If MR was skipped:
       Next steps:
       - Create the MR when ready (/issues:create-mr or glab mr create)
       - After MR merged, manually transition <SPRINT-ID> to "Done" in your work tracker
       ```

7. **Independent review option:** If you want an independent score instead of self-scoring inline, spawn `/aidlc-review` as a sub-agent against the WIP branch. If it returns any Blocking or High findings, fix them and re-evaluate the gate (point 4) before proceeding to point 6.

---

## Workflow Chain

- **Previous**: Sprint with Tasks from `/aidlc-verify` (Jira or Linear)
- **Next**: MR review and merge (MR creation is offered during Step 13)

## Definition of Done

- Work item context gathered and understood (from Jira or Linear)
- **Sprint and Tasks transitioned to "In Progress"/"Started" (with user confirmation)**
- TDD-focused plan created with test cases first
- Plan reviewed by automated architect + critic consensus
- Plan approved by user
- Plan saved to local file with progress tracking
- Feature branch created from specified base
- Implementation proceeds with TDD rhythm
- **Each Task transitioned to "Done" upon completion**
- Plan file updated as progress is made
- **All Tasks marked "Done" in work tracker (Jira or Linear)**
- **Full test suite passing**
- **MR creation offered (created or skipped per user choice)**
- **Sprint transitioned to "In Review" (with user confirmation)**
- **AC-to-Test mapping table complete — every AC row resolves to a passing, named test**
- **Rubric self-review recorded in plan file — score ≥ 80 in all four dimensions, zero Blocking/High findings open**
- **Testability design review resolved — no deferred "cannot be mocked" items**

## Troubleshooting

- **No Jira access**: Allow manual entry of acceptance criteria and description; or try Linear MCP if team uses Linear
- **No Linear access**: Allow manual entry of acceptance criteria and description; or try Jira acli if team uses Jira
- **Multiple repositories**: Confirm which repo to work in first; can switch later
- **Existing branch**: Ask whether to use existing or create new
- **Tests failing unexpectedly**: Investigate before proceeding; may indicate design issue
- **Plan file location conflict**: Offer alternative paths or append timestamp
- **Backend detection ambiguous**: Ask user to confirm whether the Sprint is tracked in Jira or Linear
