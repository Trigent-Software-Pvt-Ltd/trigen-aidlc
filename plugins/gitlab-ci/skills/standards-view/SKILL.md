---
name: standards-view
description: "Display GitLab CI pipeline standards summary to the user."
argument-hint: "[topic ...] (optional)"
disable-model-invocation: true
---

# GitLab CI Standards - View

Display a human-readable summary of GitLab CI standards to the user.

## Usage

- `/gitlab-ci:standards-view` — Show summary of all standards
- `/gitlab-ci:standards-view job-ordering` — Show job ordering standards
- `/gitlab-ci:standards-view topic1 topic2` — Show multiple specific topics

## Available Topics

- `job-ordering` — Pipeline job ordering with `needs` vs `dependencies`

## Argument Handling

**Valid topics:** `job-ordering`

- If arguments are provided in `$ARGUMENTS`, validate each one against the valid topics list above
- For any invalid topic, respond with:
  > Invalid topic: `[topic]`. Valid topics: `job-ordering`. Run `/gitlab-ci:standards-list` to see all available topics.
- If all provided topics are valid, display only those topics
- If no arguments are provided, display all topics

## Related Commands

- `/gitlab-ci:standards-list` — List available standards topics
- `/gitlab-ci:standards-load` — Load full standards into context
- `/gitlab-ci:standards-audit` — Analyze repo for standards violations

## Instructions

When this skill is invoked, output a concise summary of the requested standards for the user to read.

### Job Ordering Summary

**Core Rule:** Use stages for cross-stage ordering and `needs` only for intra-stage ordering.

| Keyword | Use When |
|---------|----------|
| `needs` | Ordering jobs within the **same stage** |
| `dependencies` | Getting artifacts from **earlier stages** (no ordering effect) |
| No `needs` | Entry-point jobs that should wait for **all** previous stage jobs |

**Why it matters:** If a job has `needs` pointing to an earlier stage, it bypasses stage gates entirely. This can cause production deployments to start before staging tests complete.

**Quick check:** Before adding `needs` to a job, ask: Is the dependency in the same stage?
- **Yes** → Use `needs`
- **No** → Don't use `needs`. Use `dependencies` if you need artifacts.

**Example:**
```yaml
# CORRECT: Entry-point job with no needs
push-docker-images-prod:
  stage: deploy-prod
  dependencies:
    - calculate-version  # Artifacts only

# CORRECT: Intra-stage needs
deploy-prod-job:
  stage: deploy-prod
  needs:
    - job: push-docker-images-prod  # Same stage - OK
```

For full documentation with anti-patterns and checklists, run `/gitlab-ci:standards-load`.
