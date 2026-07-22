---
name: standards-load
description: "Load GitLab CI pipeline standards into context for Claude to apply during work."
argument-hint: "[topic ...] (optional)"
disable-model-invocation: true
---

# GitLab CI Standards - Load Context

Load comprehensive standards into Claude's context for applying during pipeline editing or review.

## Usage

- `/gitlab-ci:standards-load` — Load all standards into context
- `/gitlab-ci:standards-load job-ordering` — Load job ordering standards only
- `/gitlab-ci:standards-load topic1 topic2` — Load multiple specific topics

## Available Topics

- `job-ordering` — Pipeline job ordering with `needs` vs `dependencies`

## Argument Handling

**Valid topics:** `job-ordering`

- If arguments are provided in `$ARGUMENTS`, validate each one against the valid topics list above
- For any invalid topic, respond with:
  > Invalid topic: `[topic]`. Valid topics: `job-ordering`. Run `/gitlab-ci:standards-list` to see all available topics.
- If all provided topics are valid, load only those topics
- If no arguments are provided, load all topics

## Related Commands

- `/gitlab-ci:standards-list` — List available standards topics
- `/gitlab-ci:standards-view` — Display standards summary to the user
- `/gitlab-ci:standards-audit` — Analyze repo for standards violations

## References

Load the standards for each requested topic (or all if no arguments provided):

### Job Ordering

@${CLAUDE_PLUGIN_ROOT}/references/standards/job-ordering.md

<!-- Future standards will be added here -->
<!-- ### Variable Naming -->
<!-- @${CLAUDE_PLUGIN_ROOT}/references/standards/variable-naming.md -->
