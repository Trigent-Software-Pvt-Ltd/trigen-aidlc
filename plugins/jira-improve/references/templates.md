# Improvement Templates

Templates for improving Jira issues by type and team pattern.

---

## Bug Templates

### Description-Only Template (Pattern A)

```markdown
## Problem
[One sentence summary of the bug and its impact]

## Steps to Reproduce
1. [First step]
2. [Second step]
3. [Continue until bug manifests]

## Expected Behavior
[What should happen when following the steps above]

## Actual Behavior
[What actually happens - be specific about error messages, visual issues, etc.]

## Environment
- **Browser:** [e.g., Chrome 120]
- **OS:** [e.g., macOS 14.2]
- **App Version:** [e.g., v2.3.1]
- **Environment:** [Production/Staging/Local]

## Additional Context
[Screenshots, error logs, related issues, frequency, affected users]
```

### Custom Fields Template (Pattern B)

**Summary:** `[Component] Brief description of the bug`

**Steps to Reproduce field:**
```
1. [First step]
2. [Second step]
3. [Continue until bug manifests]
```

**Description:**
```markdown
## Problem
[Summary of the bug and its user impact]

## Expected vs Actual
- **Expected:** [What should happen]
- **Actual:** [What happens instead]

## Additional Context
[Screenshots, logs, related issues]
```

---

## Story Templates

### Description-Only Template (Pattern A)

```markdown
## User Story
As a [user type/persona],
I want [capability/feature],
so that [benefit/value].

## Background
[Context about why this is needed, any relevant business context]

## Acceptance Criteria

### Scenario 1: [Happy path name]
**Given** [initial context]
**When** [action taken]
**Then** [expected outcome]

### Scenario 2: [Alternative/edge case name]
**Given** [initial context]
**When** [action taken]
**Then** [expected outcome]

## Out of Scope
- [What this story explicitly does NOT include]

## Design/Mockups
[Link to designs or attach images]

## Notes
[Technical considerations, dependencies, related stories]
```

### Custom Fields Template (Pattern B)

**Summary:** `[User type] can [capability]`

**Acceptance Criteria field:**
```
Scenario 1: [Happy path]
Given [context]
When [action]
Then [outcome]

Scenario 2: [Edge case]
Given [context]
When [action]
Then [outcome]
```

**Description:**
```markdown
## User Story
As a [user type], I want [capability] so that [benefit].

## Background
[Why this is needed]

## Notes
[Technical considerations, out of scope items, dependencies]
```

---

## Task Templates

### Description-Only Template (Pattern A)

```markdown
## Objective
[Clear statement of what needs to be accomplished]

## Background
[Why this task is needed - technical debt, dependency, etc.]

## Scope

### In Scope
- [Specific item 1]
- [Specific item 2]

### Out of Scope
- [What is NOT included]

## Approach
[Optional: High-level technical approach if relevant]

## Done When
- [ ] [Specific, verifiable completion criterion]
- [ ] [Another completion criterion]
- [ ] Tests pass / No regressions

## Dependencies
[Other issues, teams, or systems this depends on]
```

### Custom Fields Template (Pattern B)

**Summary:** `[Action verb] [specific thing]`

**Description:**
```markdown
## Objective
[What needs to be done and why]

## Scope
- [Specific item 1]
- [Specific item 2]

## Done When
- [ ] [Completion criterion 1]
- [ ] [Completion criterion 2]
```

---

## Chore Templates

### Description-Only Template (Pattern A)

```markdown
## Rationale
[Why this maintenance work is needed]

## Scope

### Included
- [Specific work item 1]
- [Specific work item 2]

### Excluded
- [What is NOT part of this chore]

## Approach
[How the work will be done]

## Risks
[Potential issues and mitigation]

## Done When
- [ ] [Verification criterion]
- [ ] No regressions in affected areas
```

---

## Spike/Research Templates

### Description-Only Template (Pattern A)

```markdown
## Question
[The primary question(s) this spike aims to answer]

## Background
[Context and why this research is needed now]

## Timebox
[X] hours/days maximum

## Research Areas
- [Area 1 to investigate]
- [Area 2 to investigate]

## Expected Outputs
- [ ] [Deliverable 1 - e.g., "Decision document"]
- [ ] [Deliverable 2 - e.g., "Proof of concept"]
- [ ] [Deliverable 3 - e.g., "Follow-up stories created"]

## Success Criteria
[How we know the spike was successful]
```

---

## Summary Improvement Patterns

### General Rules for Summaries

1. **Start with component/area in brackets:** `[Auth]`, `[API]`, `[UI]`
2. **Use action verbs:** Fix, Add, Update, Remove, Implement
3. **Be specific:** Replace vague words with concrete details
4. **Keep under 80 characters** when possible

### Before → After Examples

| Before | After |
|--------|-------|
| "Fix bug" | "[Checkout] Fix payment form validation clearing on error" |
| "Update login" | "[Auth] Add password strength indicator to registration" |
| "Performance issue" | "[API] Reduce /users endpoint response time from 2s to 200ms" |
| "Users can't..." | "[Dashboard] Fix widget loading failure for users with 100+ items" |
| "Improve search" | "[Search] Add autocomplete suggestions to product search" |

---

## Common Improvements by Gap Type

### Missing Acceptance Criteria

**Add this section:**
```markdown
## Acceptance Criteria

### Scenario: [Main use case]
**Given** [starting state]
**When** [user action]
**Then** [expected result]
**And** [additional expectations if any]
```

### Vague Language

**Replace:**
- "improve performance" → "reduce p95 latency from Xms to Yms"
- "fix the bug" → "prevent [specific error] when [specific condition]"
- "users report" → "[X] users affected, [Y]% of sessions"
- "sometimes fails" → "fails when [condition], approximately [X]% of attempts"

### Missing Context

**Add:**
```markdown
## Related Issues
- Parent Epic: [PROJ-XXX]
- Related: [PROJ-YYY] - [brief description]
- Blocks: [PROJ-ZZZ]

## References
- [Design doc](link)
- [Technical spec](link)
- [Previous discussion](link)
```

### No Structure

**Transform wall of text to:**
```markdown
## Summary
[First 1-2 sentences as summary]

## Details
[Remaining content organized with bullets]
- Point 1
- Point 2

## Notes
[Any caveats or additional context]
```

---

## AI Comment Template

When improvements are applied, add this comment:

```
This issue was improved with AI assistance via `/jira-improve`.

Changes made:
- [Brief list of what was updated]

View previous version in issue history if needed.
```
