---
name: pipeline-edit
description: "Lightweight GitLab CI pipeline editing guidelines. Triggers: update pipeline, modify pipeline, create pipeline, update gitlab-ci, modify gitlab-ci, edit gitlab-ci, add job, add stage, new job, new stage, pipeline job, pipeline stage"
user-invocable: false
---

# GitLab CI Pipeline Editing Guidelines

When editing `.gitlab-ci.yml` files, follow the core rules below.

## References

@${CLAUDE_PLUGIN_ROOT}/references/core-rules.md

## Quick Guidance

**Before adding `needs` to a job, ask:** Is the dependency in the same stage?
- **Yes** → Use `needs`
- **No** → Do NOT use `needs`. Use `dependencies` if you need artifacts.

For comprehensive documentation with detailed examples and checklists, run `/gitlab-ci:standards-load`.
