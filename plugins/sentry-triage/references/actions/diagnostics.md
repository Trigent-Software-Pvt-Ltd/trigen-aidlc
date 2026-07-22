# Action: Need More Context

The user wants more data before making a decision.

## Step 1: Suggest Diagnostics

Based on the error pattern identified in the analysis, suggest specific diagnostic steps:

| Pattern | Suggested Diagnostics |
|---------|----------------------|
| Missing tenant / config | Check tenant configuration, verify environment variables and feature flags |
| Timeout / network | Check APM traces for the slow endpoint, review infrastructure metrics |
| Data integrity | Query affected records to understand data state, check recent migrations |
| Auth / permission | Review user session/token state, check auth provider status |
| Null reference | Trace the nil value through the call chain, check for missing data |
| External API | Check third-party status page, review API response logs |
| Resource exhaustion | Check memory/CPU metrics, review connection pool settings |
| Rate limiting | Check rate limit configuration, review request volume trends |

If `repo_context.available` is `true`, also suggest:
- Reviewing the specific source files identified in the repo context, especially around the error lines
- Running the test suite for the affected files to check for regressions
- Checking if the recent commits in the blame data correlate with the error's `first_seen` timestamp

## Step 2: Offer Re-triage

**Required** user choice — present via `AskUserQuestion`. Do not auto-restart analysis or auto-end the workflow.

After presenting diagnostics, ask:

```
AskUserQuestion(
  question: "What would you like to do next?",
  header: "Next Step",
  options: [
    { label: "Re-analyze", description: "Run /sentry-analyze again with additional context factored in." },
    { label: "Done for now", description: "End the triage workflow. You can come back later." }
  ]
)
```

If "Re-analyze": invoke `/sentry-analyze` again, passing all original context plus any new findings.

If "Done for now": summarize what was found and end the workflow.
