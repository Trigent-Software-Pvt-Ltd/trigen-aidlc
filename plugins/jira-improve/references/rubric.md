# Quality Rubric for Jira Issues

This rubric defines how to score and evaluate Jira issue quality across five dimensions.

## Scoring Dimensions

| Dimension | Weight | Description |
|-----------|--------|-------------|
| **Completeness** | 25% | All required fields filled appropriately |
| **Clarity** | 25% | Specific, actionable language without ambiguity |
| **Structure** | 20% | Well-formatted with clear sections and bullets |
| **Context** | 15% | Sufficient links, references, and background |
| **Testability** | 15% | Clear acceptance criteria that can be verified |

## Scoring Scale

### Completeness (25%)

| Score | Description |
|-------|-------------|
| 0-25 | Missing most required fields for issue type |
| 26-50 | Missing 2+ required fields |
| 51-75 | Missing 1 required field or field is minimal |
| 76-100 | All required fields filled with appropriate detail |

### Clarity (25%)

| Score | Description |
|-------|-------------|
| 0-25 | Vague, ambiguous language throughout; unclear what needs to be done |
| 26-50 | Multiple unclear terms or statements; requires significant interpretation |
| 51-75 | Some unclear terms but overall intent is understandable |
| 76-100 | Specific, actionable language; clear what success looks like |

**Red Flag Words** (lower clarity score when present without specifics):
- "improve", "enhance", "optimize" (without metrics)
- "fix", "broken" (without specifics)
- "sometimes", "occasionally", "randomly"
- "fast", "slow", "better", "worse" (without measurements)
- "users", "customers" (without personas or segments)
- "should work", "needs to work"
- "ASAP", "urgent" (without context)

### Structure (20%)

| Score | Description |
|-------|-------------|
| 0-25 | Wall of text, no formatting |
| 26-50 | Poor formatting, hard to scan |
| 51-75 | Basic formatting with some sections or bullets |
| 76-100 | Clear sections, appropriate use of headers, bullets, and formatting |

### Context (15%)

| Score | Description |
|-------|-------------|
| 0-25 | No links, references, or background information |
| 26-50 | Minimal context; missing obvious links |
| 51-75 | Some links or references; adequate context |
| 76-100 | Rich context with relevant links, screenshots, related issues |

**Good context includes:**
- Links to related issues (parent Epic, related Stories)
- Links to documentation or specs
- Screenshots or mockups (for UI work)
- Error logs or stack traces (for bugs)
- Links to relevant code/PRs

### Testability (15%)

| Score | Description |
|-------|-------------|
| 0-25 | No acceptance criteria or criteria are unverifiable |
| 26-50 | Vague acceptance criteria |
| 51-75 | Partial acceptance criteria; some gaps |
| 76-100 | Clear, verifiable acceptance criteria; Given/When/Then preferred |

---

## Issue-Type Specific Requirements

### Bug

**Required fields:**
- Summary: Clear, specific description of the bug
- Steps to Reproduce: Numbered steps to trigger the bug
- Expected Behavior: What should happen
- Actual Behavior: What actually happens
- Environment: Browser, OS, version, etc.

**Bonus (increases score):**
- Screenshots or screen recordings
- Error logs or stack traces
- Severity assessment
- Affected users/frequency
- Workaround if known

**Scoring adjustments:**
- No repro steps: -30 from Completeness
- No expected/actual: -20 from Completeness
- No environment: -10 from Completeness

### Story

**Required fields:**
- Summary: User-focused title
- Description: User story format (As a... I want... So that...) OR clear value statement
- Acceptance Criteria: Specific, testable criteria (Given/When/Then preferred)

**Bonus (increases score):**
- Edge cases documented
- Non-functional requirements (performance, security)
- Mockups or design links
- Dependencies noted

**Scoring adjustments:**
- No acceptance criteria: -40 from Testability, -20 from Completeness
- Vague user value: -20 from Clarity

### Task

**Required fields:**
- Summary: Clear action-oriented title
- Description: Clear scope and objective
- Definition of Done: What completion looks like

**Bonus (increases score):**
- Technical approach outlined
- Affected areas/components listed
- Dependencies documented
- Estimated complexity

**Scoring adjustments:**
- Unbounded scope: -30 from Clarity
- No done criteria: -25 from Testability

### Chore

**Required fields:**
- Summary: Clear title describing the maintenance work
- Description: Rationale for the work
- Scope: Boundaries of what's included/excluded

**Bonus (increases score):**
- Impact assessment
- Rollback plan
- Testing approach

### Spike/Research

**Required fields:**
- Summary: Question to be answered
- Description: Context and why this research is needed
- Timebox: How much time to spend
- Expected Outputs: What deliverables are expected

**Scoring adjustments:**
- No timebox: -20 from Completeness
- No expected outputs: -30 from Testability

---

## Team Patterns

### Pattern A: Description-only Teams

Some teams put all content in the Description field using structured sections.

**What to look for:**
- `## Problem` or `## Summary`
- `## Steps to Reproduce`
- `## Expected Behavior` / `## Actual Behavior`
- `## Acceptance Criteria` or `## AC`
- `## Notes` or `## Context`

**Scoring:**
- Evaluate structure WITHIN the Description
- Look for markdown headers (##, ###)
- Check for numbered lists and bullets

### Pattern B: Custom Fields Teams

Some teams use dedicated Jira custom fields for specific content.

**Common custom fields:**
- Acceptance Criteria
- Steps to Reproduce
- Environment
- Story Points
- Business Value

**Scoring:**
- Score each field independently
- Check for empty custom fields that should be filled
- Consider if content is in wrong field (e.g., AC in Description when AC field exists)

---

## Overall Score Calculation

```
Overall Score = (Completeness × 0.25) + (Clarity × 0.25) + (Structure × 0.20) + (Context × 0.15) + (Testability × 0.15)
```

### Quality Categories

| Score Range | Category | Recommendation |
|-------------|----------|----------------|
| 0-30 | Critical | Needs immediate improvement before work begins |
| 31-50 | Poor | Significant improvement needed |
| 51-70 | Adequate | Could benefit from improvement |
| 71-85 | Good | Minor refinements optional |
| 86-100 | Excellent | Ready for implementation |

---

## Example Evaluations

### Poor Bug (Score: 28)

**Summary:** "Login broken"
**Description:** "Users can't login. Please fix."

| Dimension | Score | Reason |
|-----------|-------|--------|
| Completeness | 15 | Missing repro steps, environment, expected/actual |
| Clarity | 25 | Vague - which users? What error? |
| Structure | 40 | Short but no structure needed for length |
| Context | 20 | No links, logs, or screenshots |
| Testability | 20 | No way to verify the fix |
| **Overall** | **23** | |

### Good Bug (Score: 85)

**Summary:** "[Auth] Session expires during active use causing unexpected logout"
**Description:**
```
## Problem
Users are being logged out while actively using the application, losing unsaved work.

## Steps to Reproduce
1. Log in as any user
2. Navigate to the editor
3. Begin typing (keep session active)
4. Wait 15 minutes while continuing to type
5. Observe logout occurs mid-typing

## Expected Behavior
Session should remain active while user is actively interacting with the page.

## Actual Behavior
User is logged out after 15 minutes regardless of activity.

## Environment
- Browser: Chrome 120, Firefox 121
- OS: macOS 14.2, Windows 11
- Affects: Production

## Logs
[Link to error log sample]
```

| Dimension | Score | Reason |
|-----------|-------|--------|
| Completeness | 90 | All required fields present |
| Clarity | 85 | Specific timing, clear behavior |
| Structure | 90 | Well-formatted sections |
| Context | 75 | Has logs, could add related issues |
| Testability | 85 | Clear steps to verify fix |
| **Overall** | **86** | |
