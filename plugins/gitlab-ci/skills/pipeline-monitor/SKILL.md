---
name: pipeline-monitor
description: "Monitor a GitLab CI/CD pipeline, auto-diagnose failures, suggest fixes, and re-push. Triggers: monitor pipeline, watch pipeline, watch this pipeline, check pipeline, track pipeline, pipeline status, follow pipeline, fix pipeline, pipeline monitor, ci monitor, watch ci, is the pipeline done, pipeline passing, pipeline failing, why did the pipeline fail, debug pipeline, pipeline logs"
argument-hint: "[pipeline-url | pipeline-id | branch] (optional, defaults to current branch)"
allowed-tools: [Bash, Read, Glob, Grep, Edit, Write, Task]
---

# GitLab CI/CD Pipeline Monitor

Monitor a pipeline to completion, diagnose failures using sub-agents, propose fixes, and iterate until green — all in one command.

## Prerequisites

This skill requires the **glab CLI** (GitLab CLI) to be installed and authenticated.

### glab CLI

**Installation:**
- **macOS:** `brew install glab`
- **Windows:** `winget install --id GitLab.Glab` (or `scoop install glab` / `choco install glab`)
- **Linux:** See https://gitlab.com/gitlab-org/cli#installation

**Authentication:**
```bash
glab auth login
```
Select your GitLab instance, choose your preferred auth method, and follow the prompts.

### Dependency Check

Before starting any monitoring, verify glab is available:
```bash
glab --version
```

If `glab` is missing or not authenticated:
1. Show the user the installation instructions above
2. Use `AskUserQuestion` to prompt them to install/authenticate
3. Do not proceed until `glab --version` succeeds

## Configuration Defaults

| Setting | Default |
|---------|---------|
| Poll interval | 30 seconds |
| Max fix iterations | 5 |
| Max poll duration | 30 minutes |

If the user specifies overrides (e.g., "monitor pipeline with 60s interval, max 3 iterations"), use those values instead.

## Phase 0: Resolve Pipeline Target

Parse `$ARGUMENTS` to determine what to monitor:

1. **Pipeline URL** (contains `/pipelines/`): Extract the pipeline ID and project path. Use `glab ci get -p <id> -R <project-path> -F json -d`.
2. **Numeric pipeline ID**: Use `glab ci get -p <id> -F json -d`.
3. **Branch name** (non-numeric string): Use `glab ci get -b <branch> -F json -d`.
4. **No argument**: Detect the current branch via `git rev-parse --abbrev-ref HEAD`, then use `glab ci get -b <branch> -F json -d`.

**Validation**: Run the initial `glab ci get` command. If it fails or returns no pipeline, report the error clearly and ask the user to verify their input. Do NOT suggest triggering a new pipeline — the user specified a target and we should respect that.

Store the resolved `BRANCH`, `PIPELINE_ID`, and optionally `REPO_FLAG` (the `-R` flag value) for use in subsequent phases.

## Phase 1: Poll Loop

Use the polling script to wait for the pipeline to reach a terminal state. This collapses the entire wait into a single tool call, saving context window.

**Choose the script based on the platform** (check the `$PLATFORM` environment info):

- **Windows** (`win32`):
  ```powershell
  powershell -ExecutionPolicy Bypass -File "{{SKILL_DIR}}/../../../scripts/poll-pipeline.ps1" -PipelineId <id> -Branch <branch> -Interval <interval> -Timeout <timeout> -Repo <repo>
  ```
- **Linux/macOS**:
  ```bash
  bash "{{SKILL_DIR}}/../../../scripts/poll-pipeline.sh" -b <branch> -p <pipeline-id> -i <interval> -t <timeout> -R <repo>
  ```

Both scripts have identical behavior: poll `glab ci get -F json -d`, print status updates to stderr/host, print final JSON to stdout, and use the same exit codes.

**Interpret exit codes:**
| Code | Meaning | Action |
|------|---------|--------|
| 0 | Pipeline succeeded | Report success → go to Final Summary |
| 1 | Pipeline failed | Diagnose → Phase 2 |
| 2 | Canceled or skipped | Report and stop |
| 3 | Timeout | Report timeout, ask user if they want to continue waiting |
| 4 | Error (glab failed) | Report error, ask user to troubleshoot |

**Iteration tracking:**
```
iteration = 0
while iteration < MAX_ITERATIONS:
    run poll-pipeline.sh
    parse exit code and stdout JSON
    if success → final summary, stop
    if failed  → Phase 2 (diagnose) → Phase 3 (fix) → Phase 4 (detect new pipeline) → increment iteration, continue
    if canceled/skipped → report, stop
    if timeout → ask user
    if only manual jobs blocking → report, ask user if they want to trigger them
```

## Phase 2: Diagnose Failures (Sub-Agents)

Parse the JSON output from the poll script. Identify all failed jobs where `allow_failure` is NOT true.

For **each** failed job, launch a **Task sub-agent** (subagent_type: `Bash`) in parallel. Each sub-agent should:

1. Fetch the job log: `glab api "projects/:id/jobs/<job_id>/trace"` (pipe through `tail -200` to limit size)
2. Search for error patterns: exit codes, stack traces, assertion failures, lint errors, compilation errors
3. Classify the failure into one of these categories:
   - **Lint/Style** — fixable locally
   - **Compilation/Build** — fixable locally
   - **Test failure** — fixable locally
   - **YAML syntax** — fixable locally
   - **Dependency issue** — fixable locally
   - **Infrastructure** (runner, docker, timeout) — NOT fixable, report only
   - **Permission/auth** — NOT fixable, report only
   - **Flaky/intermittent** — suggest `glab ci retry <job-id>` instead of code fix
4. Return a compact summary: job name, job ID, error category, root cause description, relevant file paths, whether it's fixable locally

**Important**: Launch all failed-job sub-agents in parallel using multiple Task tool calls in a single message. The main context should only receive the digested summaries, not raw logs.

After collecting all summaries:
- If ALL failures are infrastructure/permission → report as unfixable, stop
- If ALL failures are `allow_failure: true` → report as effective pass, stop
- If any failures are flaky → offer retry via `glab ci retry <job-id>` before attempting code fixes
- Otherwise → proceed to Phase 3

## Phase 3: Fix, Lint, and Push (Safety Gates)

### 3a. Propose Fixes

Present a summary of proposed fixes to the user:
```
## Proposed Fixes

1. **lint-check** (Lint/Style): Fix rubocop offenses in `app/models/user.rb`
2. **unit-tests** (Test failure): Update assertion in `spec/models/user_spec.rb:42` — expected value changed
```

Present the summary, then proceed to apply fixes. The user's Claude Code permission settings will control whether they are prompted for each edit.

### 3b. Apply Fixes

Use Edit/Write tools to apply the fixes. Read files before editing them.

### 3c. Lint CI Config (if modified)

If `.gitlab-ci.yml` was modified, validate it:
```bash
glab ci lint .gitlab-ci.yml
```
If lint fails, fix the YAML issues before proceeding.

### 3d. Commit

Stage only the specific files that were changed:
```bash
git add <file1> <file2> ...
git commit -m "fix(<scope>): <description of fixes>"
```
Use conventional commit format. The commit message should reference what pipeline failures were addressed.

### 3e. Push

Show the user what will be pushed, then push. The user's Claude Code permission settings will control whether they are prompted.

```bash
git push origin <branch>
```

If the push is rejected (protected branch, etc.), offer to create a new branch and MR instead.

## Phase 4: Detect New Pipeline

After a successful push:

1. Wait for GitLab to create the new pipeline: `sleep 10`
2. Check for a new pipeline: `glab ci get -b <branch> -F json`
3. Compare the pipeline ID with the previous one
4. If a new pipeline ID is found → resume Phase 1
5. If the same pipeline ID persists after 30 seconds of retries → warn the user, ask whether to retry or stop

## Termination Conditions

| Condition | Action |
|-----------|--------|
| All jobs pass | Report success, show final summary |
| Max iterations (default 5) reached | Stop, report remaining failures |
| Poll timeout exceeded | Stop, note pipeline is still running |
| User declines a fix | Stop |
| User declines a push | Stop |
| Pipeline canceled externally | Stop |
| Only infrastructure/permission failures remain | Stop, report as unfixable locally |
| All failures have `allow_failure: true` | Report as effective pass |

## Final Summary

Always display a summary at the end, regardless of outcome:

```
## Pipeline Monitor Summary
Branch: <branch> | Iterations: <n>/<max> | Duration: <elapsed>

Iteration 1: Pipeline #12345 — FAILED
  Failed: unit-tests, lint-check
  Fix: fixed rubocop offenses, updated test assertion → commit abc1234

Iteration 2: Pipeline #12346 — PASSED
```

Include:
- Branch name
- Number of iterations used / max
- Approximate wall-clock duration
- Per-iteration: pipeline ID, result, failed jobs, fixes applied, commit hash

## Edge Cases

- **Manual jobs blocking progress**: Report them and ask the user if they want to trigger them via `glab ci trigger <job-id>` or `glab ci play <job-id>`
- **`allow_failure` jobs**: Warn about them but do not count them as blocking failures
- **Protected branch push rejected**: Offer to create a new branch and open an MR
- **Fix introduces new failures**: The next iteration will catch them automatically
- **Flaky tests**: Offer retry via `glab ci retry <job-id>` before attempting a code fix
