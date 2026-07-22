---
name: standards-audit
description: "Audit a repository's GitLab CI pipeline against standards. Reports violations with line numbers and recommendations."
argument-hint: "[topic ...] (optional)"
disable-model-invocation: true
---

# GitLab CI Standards Audit

Analyze a repository's `.gitlab-ci.yml` for compliance with GitLab CI standards.

## Usage

- `/gitlab-ci:standards-audit` — Audit against all standards
- `/gitlab-ci:standards-audit job-ordering` — Audit job ordering only
- `/gitlab-ci:standards-audit topic1 topic2` — Audit multiple specific topics

## Available Topics

- `job-ordering` — Pipeline job ordering with `needs` vs `dependencies`

## Argument Handling

**Valid topics:** `job-ordering`

- If arguments are provided in `$ARGUMENTS`, validate each one against the valid topics list above
- For any invalid topic, respond with:
  > Invalid topic: `[topic]`. Valid topics: `job-ordering`. Run `/gitlab-ci:standards-list` to see all available topics.
- If all provided topics are valid, audit only those topics
- If no arguments are provided, audit all topics

## Related Commands

- `/gitlab-ci:standards-list` — List available standards topics
- `/gitlab-ci:standards-view` — Display standards summary to the user
- `/gitlab-ci:standards-load` — Load full standards into context

## References

@${CLAUDE_PLUGIN_ROOT}/references/core-rules.md

## Audit Process

1. **Find the pipeline file**: Search for `.gitlab-ci.yml` in the repository root
2. **Validate arguments**: Check that requested topics are valid (see Argument Handling above)
3. **Load relevant standards**: Based on validated topics or all standards if none specified
4. **Analyze the pipeline**: Check each job against the standards
5. **Report findings**:

### Report Format

```
## Standards Audit Report

### Summary
- **Compliant**: X patterns
- **Violations**: Y issues found
- **Recommendations**: Z suggestions

### Violations

#### [VIOLATION] Cross-stage `needs` detected
- **File**: .gitlab-ci.yml
- **Line**: 45
- **Job**: `push-docker-images-prod`
- **Issue**: Job has `needs: [manual-approval-prod]` which is in a different stage (prod-gate)
- **Impact**: Job will bypass stage gate and may run before all prod-gate jobs complete
- **Fix**: Remove the `needs` entry and use `dependencies` if artifacts are required

### Compliant Patterns

- `deploy-prod-job` correctly uses intra-stage `needs` for `push-docker-images-prod`
- Entry-point jobs in `deploy-lower` have no cross-stage `needs`

### Recommendations

- Consider adding `optional: true` to migration job dependencies
```

## Job Ordering Audit Checks

When auditing `job-ordering`, check for:

1. **Cross-stage `needs`**: Any job with `needs` pointing to a job in a different stage
2. **Entry-point jobs with `needs`**: First jobs in each stage should have no `needs`
3. **Missing `optional: true`**: Jobs that `need` conditional jobs (like migrations)
4. **Incorrect artifact handling**: Using `needs` when `dependencies` would suffice

For each violation, provide:
- Exact line number
- The problematic configuration
- Why it violates the standard
- Specific fix with corrected YAML
