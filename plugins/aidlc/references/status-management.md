# Work Item Status Management

Utility pattern for transitioning Jira and Linear work item statuses throughout the Sprint workflow.

## Function: `transition_status(item_id, target_status, item_type, backend)`

### Jira Backend (GitLab/Confluence documentation)

**Strategy:**
1. Check if `acli` is available: `which acli`
2. If available, use acli:
   ```bash
   acli jira workitem transition PROJ-123 --transition "In Progress"
   ```
3. If acli fails or unavailable, fall back to MCP tools:
   ```
   - Call getTransitionsForJiraIssue(PROJ-123)
   - Find transition ID matching target_status name
   - Call transitionJiraIssue(PROJ-123, {id: "21"})
   ```

### Linear Backend

**Strategy:**
Use Linear MCP tools to update Issue state:
```typescript
save_issue({
  id: "<issue-id>",
  state: "<target-state>"  // e.g., "Started", "Done", "Cancelled"
})
```

**Linear state mapping:**
| AIDLC Status | Linear State |
|-------------|--------------|
| To Do | Backlog or Todo |
| In Progress | Started (or In Progress) |
| In Review | In Review |
| Done | Done |
| Blocked | Blocked (custom state) |

### Common Error Handling

- Status already set → Log info, treat as success
- Invalid transition → Log warning, ask user to verify manually
- Network/auth failure → Log error, continue workflow (non-blocking)
- acli not installed → Silent fallback to MCP tools (Jira only)
- Linear MCP unavailable → Log error, ask user to update manually

**Return Format:**
```json
{
  "success": true,
  "method": "acli|linear-mcp",
  "message": "Transitioned SPRINT-123 to In Progress",
  "previous_status": "To Do",
  "new_status": "In Progress"
}
```

Display results with indicators:
- Success
- Warning (already in target state)
- Failed (manual intervention needed)
