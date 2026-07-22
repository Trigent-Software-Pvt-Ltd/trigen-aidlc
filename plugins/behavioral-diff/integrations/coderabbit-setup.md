# CodeRabbit Integration for Behavioral Diff Detection

This guide configures CodeRabbit to automatically detect logic inversions and behavioral changes when merge requests are created.

## Why CodeRabbit for MR Reviews?

| Stage | Tool | Cost |
|-------|------|------|
| Local development | Claude (`/behavioral-diff:review`) | Developer's Claude tokens |
| Merge Request | CodeRabbit | CodeRabbit subscription (already in use) |

Benefits:
- **Zero additional cost** - CodeRabbit already reviews all MRs
- **Automatic** - No manual invocation required
- **Consistent** - Every MR gets reviewed for inversions
- **Non-blocking** - Alerts developers without blocking merge

## Quick Setup

### Option 1: Repository Configuration File

Create `.coderabbit.yaml` in your repository root:

```yaml
# .coderabbit.yaml
reviews:
  high_level_summary: true
  poem: false
  review_status: true
  collapse_walkthrough: false
  path_instructions:
    - path: "**/*.cs"
      instructions: |
        CRITICAL: Detect behavioral inversions and logic changes that could break business logic.

        ## Inversion Patterns to Flag

        ### CRITICAL - Always Flag
        1. **Boolean Inversions**
           - `if (x)` → `if (!x)` or vice versa
           - Negation added or removed from conditions
           - Example: `if (order.IsValid)` → `if (!order.IsValid)`

        2. **Equality Inversions**
           - `==` changed to `!=` or vice versa
           - Example: `if (status == Active)` → `if (status != Active)`

        3. **AND/OR Swaps**
           - `&&` changed to `||` or vice versa
           - Example: `if (a && b)` → `if (a || b)`

        4. **If/Else Branch Swaps**
           - Code in if block moved to else block or vice versa

        ### HIGH - Flag for Review
        5. **Comparison Direction Changes**
           - `<` → `>` or `<=` → `>=`
           - Off-by-one: `<` → `<=` or `>` → `>=`
           - Example: `if (age >= 18)` → `if (age > 18)`

        6. **Null Check Inversions**
           - `!= null` → `== null` or vice versa
           - `?.` (null conditional) removed
           - `??` (null coalescing) removed or changed
           - Example: `if (user != null)` → `if (user == null)`

        7. **Guard Clause Inversions**
           - Early return condition flipped
           - Example: `if (x == null) return;` → `if (x != null) return;`

        8. **Return Value Inversions**
           - `return true` → `return false` or vice versa
           - `return success` → `return !success`

        ### MEDIUM - Verify Intent
        9. **LINQ Semantic Changes**
           - `.Any()` → `.All()` or vice versa
           - `.First()` → `.FirstOrDefault()` or vice versa
           - `.Where(x => condition)` predicate inverted
           - `.Take(n)` → `.Skip(n)`
           - `.OrderBy()` → `.OrderByDescending()`

        10. **Ternary Operator Swaps**
            - `condition ? a : b` → `condition ? b : a`
            - `condition ? a : b` → `!condition ? a : b`

        11. **Loop Bound Changes**
            - `i < n` → `i <= n` (off-by-one)
            - `i < n` → `i < n-1` (misses last element)
            - Loop direction reversed

        ### Business Logic Patterns
        12. **Validation Inversions**
            - Methods named `Validate*`, `IsValid*`, `Check*`
            - Throwing on valid instead of invalid

        13. **Authorization Inversions**
            - `IsAdmin`, `HasPermission`, `CanAccess` checks inverted
            - `[Authorize]` conditions changed

        14. **State Machine Changes**
            - Transition conditions inverted
            - Status/State enum comparisons changed

        ## Response Format

        For each potential inversion found:

        ⚠️ **POTENTIAL INVERSION DETECTED**

        **Pattern:** [Pattern name from above]
        **Severity:** [CRITICAL/HIGH/MEDIUM]
        **File:** [filename:line]

        **Before:**
        ```csharp
        [original code]
        ```

        **After:**
        ```csharp
        [changed code]
        ```

        **Impact:** [Explain what behavior changed]

        **Question:** Was this change intentional? If yes, consider adding a comment explaining why.

        ## Intentional Changes (Lower Priority)

        Reduce severity if you see these indicators:
        - Test file changes that validate the new behavior
        - Explanatory comment added with the change
        - Guard clause refactoring pattern (nested → early returns)
        - De Morgan's law simplification (logically equivalent)
        - Feature flag wrapping the change

    - path: "**/*.fs"
      instructions: |
        Apply the same inversion detection patterns as C# files.
        Additionally watch for:
        - Pattern matching inversions
        - Option/Result type handling changes
        - Pipe operator logic changes

    - path: "**/*.xaml"
      instructions: |
        Check for binding expression inversions:
        - `Visibility` bindings with inverted converters
        - `IsEnabled` bindings inverted
        - `Command` CanExecute conditions changed

chat:
  auto_reply: true
```

### Option 2: CodeRabbit Web UI Configuration

If you prefer configuring via the CodeRabbit dashboard:

1. Go to **CodeRabbit Dashboard** → **Repository Settings**
2. Navigate to **Review Instructions**
3. Add the following custom instructions:

```
For all C# files, detect behavioral inversions:

CRITICAL patterns (always flag):
- Boolean inversions: if(x) → if(!x)
- Equality inversions: == → !=
- AND/OR swaps: && → ||
- If/else branch swaps

HIGH patterns (flag for review):
- Comparison changes: < → >, <= → >=
- Null check inversions: != null → == null
- Guard clause inversions
- Return value inversions: return true → return false

MEDIUM patterns (verify intent):
- LINQ changes: .Any() → .All(), .First() → .FirstOrDefault()
- Ternary swaps: a ? b : c → a ? c : b
- Loop bound changes

For each finding, show before/after code and ask if intentional.
```

## Example CodeRabbit Output

When CodeRabbit detects an inversion in an MR, it will comment:

---

### ⚠️ Potential Logic Inversion Detected

**Pattern:** Boolean Inversion
**Severity:** 🔴 CRITICAL
**File:** `src/Services/OrderService.cs:142`

**Before:**
```csharp
if (order.IsValid && order.HasStock)
{
    ProcessOrder(order);
}
```

**After:**
```csharp
if (!order.IsValid || !order.HasStock)
{
    ProcessOrder(order);
}
```

**Impact:** The condition has been completely inverted. Previously, orders were processed when valid AND in stock. Now orders are processed when invalid OR out of stock.

❓ **Was this change intentional?** If yes, please add a comment explaining the new business logic.

---

## Customization Options

### Adjusting Sensitivity

To reduce false positives, you can modify the instructions:

```yaml
# Add to path_instructions
instructions: |
  # ... existing patterns ...

  ## Reduced Sensitivity Settings

  Only flag inversions when:
  - The change is in non-test code
  - No explanatory comment accompanies the change
  - The method name suggests the change contradicts intent

  Do NOT flag:
  - Changes in test files (*Tests.cs, *Test.cs)
  - Guard clause refactoring (nested → early returns)
  - Obvious De Morgan simplifications
```

### File Type Exclusions

To skip certain files:

```yaml
reviews:
  path_filters:
    - "!**/*Tests.cs"
    - "!**/*Test.cs"
    - "!**/TestHelpers/**"
    - "!**/*.Designer.cs"
    - "!**/*.generated.cs"
```

### Severity Customization

To adjust what gets flagged:

```yaml
# Only flag CRITICAL patterns
instructions: |
  Only flag these patterns as potential issues:
  - Boolean inversions (if(x) → if(!x))
  - Equality inversions (== → !=)
  - AND/OR swaps (&& → ||)

  For all other patterns, note them but don't flag as issues.
```

## Integration with Local Review

### Recommended Workflow

```
Developer Flow:
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Write Code     │ ──▶ │ /behavioral-    │ ──▶ │  Create MR      │
│                 │     │  diff:review    │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                              │                        │
                              ▼                        ▼
                        ┌─────────────────┐     ┌─────────────────┐
                        │ Fix inversions  │     │ CodeRabbit      │
                        │ before commit   │     │ auto-reviews    │
                        └─────────────────┘     └─────────────────┘
                                                       │
                                                       ▼
                                                ┌─────────────────┐
                                                │ Developer       │
                                                │ addresses       │
                                                │ comments        │
                                                └─────────────────┘
```

1. **Before committing:** Run `/behavioral-diff:review` locally
2. **On MR creation:** CodeRabbit automatically reviews
3. **Address findings:** Fix or explain each flagged inversion
4. **Merge with confidence:** Both local and MR-level checks passed

### Combining with Branch Protection

For maximum safety, combine CodeRabbit with branch protection:

```yaml
# GitLab .gitlab-ci.yml or GitHub branch protection
# Require CodeRabbit approval before merge
# This ensures inversions are addressed before code reaches main
```

## Troubleshooting

### CodeRabbit Not Detecting Inversions

1. **Check file patterns**: Ensure `**/*.cs` matches your file paths
2. **Verify instructions**: Instructions may be too long; try shortening
3. **Check exclusions**: Files might be filtered out

### Too Many False Positives

1. **Add test file exclusions**: `!**/*Tests.cs`
2. **Reduce pattern scope**: Only flag CRITICAL patterns
3. **Add context requirements**: Require multiple indicators

### Missing Inversions

1. **Expand file patterns**: Add `.fs`, `.vb`, `.xaml`
2. **Add more patterns**: Review `references/inversion-patterns.md`
3. **Lower thresholds**: Flag MEDIUM patterns too

## Monitoring & Metrics

Track effectiveness over time:

1. **False Positive Rate**: How often are flagged changes intentional?
2. **Catch Rate**: Are real inversions being caught?
3. **Response Time**: How quickly do developers address findings?

Use these metrics to tune your configuration.

## Related Documentation

- [Inversion Patterns Reference](../references/inversion-patterns.md) - Comprehensive pattern catalog
- [control-flow-analyzer](../agents/control-flow-analyzer.md) - Local syntactic detection
- [business-logic-analyzer](../agents/business-logic-analyzer.md) - Local semantic detection

---

*Configuration effective for CodeRabbit as of January 2026. Check CodeRabbit documentation for any syntax changes.*
