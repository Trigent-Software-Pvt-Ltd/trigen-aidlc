---
name: aidlc-verify-completion
description: Verify that implementation work is actually DONE before declaring it complete — acceptance criteria met, tests executed and passed (incl. negative/permission), security/quality checks passed, no blocking defects, reviewed to risk, docs updated, PR/merge status confirmed, approvals recorded. Reports each item PASS/FAIL/NOT RUN/N-A with evidence. Distinct from /aidlc-verify (spec readiness). (Triggers - verify completion, is this done, done check, completion check, ready to merge, definition of done, pre-merge verification)
---

# AI-DLC Verify Completion

The gate between "I think it's done" and "it's done." Runs **after** implementation, **before** anyone
declares the work complete or merges it. This is **not** `/aidlc-verify` (which checks *specification*
readiness before the build); this checks the *implementation*.

> **Never treat an unexecuted test as passed. Never claim a merge, deployment, or integration update
> without confirming the actual result.** If it wasn't run, it is `NOT RUN`, not `PASS`.

## When to use
At the end of a sprint/task, before marking a ticket done or opening/merging a PR; and whenever someone
asks "is this done / ready to merge?".

## Preconditions
The story's acceptance criteria (`AC-*`), the implementation plan's verification commands, and the
build output / PR to inspect.

## Workflow
1. Load the AC, the plan's **verification commands**, and the risk classification.
2. Run through `@${CLAUDE_PLUGIN_ROOT}/references/verification-checklist.md`, **executing** the
   verification commands rather than assuming — capture real output.
3. Mark each item `PASS` / `FAIL` / `NOT RUN` / `N/A`, each with **evidence** (command+result, link,
   file:line, screenshot).
4. Produce the verdict: **COMPLETE** only if every applicable item is `PASS` (or justified `N/A`).
5. Any `FAIL` or unjustified `NOT RUN` ⇒ **NOT COMPLETE** → hand back to the fix loop
   (`execution-rigor.md` §4); do **not** report done.

## Required outputs
The completed checklist (PASS/FAIL/NOT RUN/N-A + evidence per item) and a single COMPLETE / NOT
COMPLETE verdict. Record it with the task so review and `/aidlc-progress` can cite it.

## Human gate
A COMPLETE verdict informs, it does not self-approve a merge: the required human approval
(`guardrails` publish/merge gate) still applies. Reviewer/verification agents never impersonate the
human approver.

## Exit criteria
Verdict issued with evidence; if NOT COMPLETE, the open items are listed and routed to the fix loop.

## References
- @${CLAUDE_PLUGIN_ROOT}/references/verification-checklist.md — the item list + report format.
- @${CLAUDE_PLUGIN_ROOT}/references/evidence-led-pr.md — the PR evidence pack this confirms.
- @${CLAUDE_PLUGIN_ROOT}/references/execution-rigor.md — the fix loop NOT-COMPLETE routes to.
