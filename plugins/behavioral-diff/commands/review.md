---
description: "Analyze code changes for logic inversions, control flow alterations, and behavioral changes that could break business logic"
argument-hint: "[--staged|--branch|--commit] [--strict|--normal] [file_path]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Task"]
---

# Behavioral Diff Review

Analyze code changes to detect **logic inversions** and **behavioral alterations** that could break business logic. This tool catches subtle bugs like inverted if-clauses that compile successfully but completely change program behavior.

**Arguments:** "$ARGUMENTS"

## Why This Exists

A simple change like `if (isValid)` to `if (!isValid)` can:
- Pass code review (the change looks small)
- Compile without errors
- Pass incomplete test suites
- **Break production**

This command is your safety net to catch these semantic changes before they cause outages.

## Review Workflow

### 1. Parse Arguments

Determine the diff scope based on arguments:

| Argument | Behavior |
|----------|----------|
| `--staged` (default) | Review staged changes (`git diff --cached`) |
| `--branch` | Review current branch vs main (`git diff main...HEAD`) |
| `--commit` | Review last commit (`git diff HEAD~1..HEAD`) |
| `--strict` (default) | Maximum sensitivity, more false positives |
| `--normal` | Reduced sensitivity, fewer false positives |
| `file_path` | Limit review to specific file(s) |

**Default behavior:** If no arguments provided, review staged changes in strict mode.

### 2. Get the Diff

Based on the scope argument, run the appropriate git command:

**For staged changes (default):**
```bash
git diff --cached --unified=5
```

**For branch comparison:**
```bash
# First, determine the base branch (main or master)
git branch -l main master 2>/dev/null | head -1 | tr -d '* '
# Then get the diff
git diff <base_branch>...HEAD --unified=5
```

**For last commit:**
```bash
git diff HEAD~1..HEAD --unified=5
```

**If a file path is specified, append it:**
```bash
git diff --cached --unified=5 -- path/to/file.cs
```

### 3. Identify Changed Files

From the diff output:
- Extract file paths that were modified
- Filter for relevant file types:
  - `.cs` - C# source files (primary focus)
  - `.fs` - F# source files
  - `.vb` - VB.NET source files
  - `.xaml` - XAML files (for binding expressions)
  - `.razor` - Blazor components

If no relevant files are found in the diff, report that and exit.

### 4. Analyze Changes

For each changed file, invoke **two specialized analyzers** in parallel:

#### 4a. Control Flow Analyzer

Invoke the **control-flow-analyzer** agent for syntactic pattern detection:

```
Analyze the following diff for logic inversions and control flow changes:

**File:** {file_path}

**Diff:**
```diff
{diff_content}
```

**Mode:** {STRICT or NORMAL}

**Focus Areas:**
1. Conditional inversions (if/else swapped, negation added/removed)
2. Comparison operator changes (==, !=, <, >, <=, >=)
3. Boolean expression changes (AND/OR swapped)
4. Null check inversions
5. Loop condition changes
6. Guard clause inversions
7. Return value inversions
8. LINQ query semantic changes
9. Ternary operator swaps

**Context-Aware Analysis:**
- Check for test file changes in the diff
- Look for intentional refactoring patterns (guard clauses, validation consolidation)
- Adjust confidence based on context indicators

**For each finding, provide:**
- Severity (CRITICAL, HIGH, MEDIUM, LOW)
- Confidence percentage (with context adjustments)
- Before/after code comparison
- Analysis of behavioral impact
- Test coverage status
- Intentionality assessment
- Recommendation
```

#### 4b. Business Logic Analyzer

Invoke the **business-logic-analyzer** agent for semantic understanding:

```
Analyze the following diff for business logic and semantic changes:

**File:** {file_path}

**Diff:**
```diff
{diff_content}
```

**Mode:** {STRICT or NORMAL}

**Focus Areas:**
1. Validation logic inversions
2. Authorization/security check changes
3. State machine transition modifications
4. Data transformation inversions
5. Business rule changes
6. Error handling modifications

**Semantic Analysis:**
- Understand the business purpose of the changed code
- Identify domain-specific implications
- Assess whether changes align with method/class naming
- Look for indicators of intentional vs accidental changes

**For each finding, provide:**
- Severity (CRITICAL, HIGH, MEDIUM, LOW)
- Business category (Validation, Authorization, State Machine, etc.)
- Confidence percentage
- Business context explanation
- Semantic impact analysis
- Intentionality indicators
- Recommendation
```

Use the Task tool to invoke both agents **in parallel** for each file with changes.

### 4c. Mode-Specific Behavior

**STRICT mode (default):**
- Control-flow-analyzer: Reports findings at 45%+ confidence
- Business-logic-analyzer: Reports all potential semantic changes
- Include LOW severity findings
- Flag uncertain inversions for review

**NORMAL mode:**
- Control-flow-analyzer: Reports findings at 65%+ confidence only
- Business-logic-analyzer: Reports only high-confidence semantic issues
- Exclude LOW severity findings
- Require multiple indicators before flagging

### 5. Aggregate and Present Results

After both analyzers complete, merge and deduplicate their findings:

#### 5a. Merge Findings

- Combine findings from control-flow-analyzer and business-logic-analyzer
- Deduplicate: If both analyzers flag the same code, merge into a single finding
- For merged findings, use the higher severity and include both analyses
- Group by file, then by severity

#### 5b. Summary Header

```markdown
## Behavioral Diff Analysis Results

**Scope:** [Staged Changes | Branch: feature-x vs main | Last Commit: abc1234]
**Mode:** STRICT | NORMAL
**Files Analyzed:** 5
**Analyzers Used:** control-flow-analyzer, business-logic-analyzer

### Summary
| Severity | Count | Confidence Range |
|----------|-------|------------------|
| CRITICAL | 1 | 90-95% |
| HIGH | 2 | 75-85% |
| MEDIUM | 1 | 65-70% |
| LOW | 0 | N/A |

**Total Issues:** 4 (1 Critical, 2 High, 1 Medium)
**Test Coverage Warnings:** 2 files have no test updates
```

#### 5c. Group by Severity

```markdown
### 🚨 Critical Issues (1)
[List critical findings - require immediate attention before commit]

Each finding includes:
- File and line number
- Pattern type (Control Flow or Business Logic)
- Before/after code diff
- Behavioral impact analysis
- Confidence score with context factors
- Test coverage status
- Intentionality assessment

### ⚠️ High Priority Issues (2)
[List high priority findings - should be reviewed carefully]

### 📋 Medium Priority Issues (1)
[List medium priority findings - verify intent]

### ℹ️ Low Priority Issues (0)
[List low priority findings - informational, STRICT mode only]
```

#### 5d. Test Coverage Summary

```markdown
## Test Coverage Analysis

| File | Test File | Tests Updated | Status |
|------|-----------|---------------|--------|
| src/Services/OrderService.cs | tests/.../OrderServiceTests.cs | ❌ No | ⚠️ Warning |
| src/Models/User.cs | tests/.../UserTests.cs | ✅ Yes | ✅ OK |
| src/Utils/Validator.cs | (not found) | N/A | 🚨 Missing |
```

#### 5e. Intentional Change Summary

```markdown
## Likely Intentional Changes (Review Anyway)

These changes show indicators of intentional refactoring:
- **OrderService.cs:45** - Guard clause refactoring pattern detected
- **UserValidator.cs:102** - Test changes validate new behavior

Still verify these changes were intended.
```

#### 5f. Recommendations Section

```markdown
## Recommended Actions

1. **🚨 Critical Issues** - Stop and fix before committing
   - These are almost certainly bugs (90%+ confidence)
   - If intentional, add a comment explaining why

2. **⚠️ High Priority** - Review carefully before committing
   - Check if tests cover the new behavior
   - Verify business logic implications

3. **📋 Medium Priority** - Verify intent
   - These may be intentional refactoring
   - Confirm with the original author if unclear

4. **📝 Test Coverage** - Add tests for flagged code
   - {count} files have behavioral changes without test updates
   - Consider adding tests to verify the new behavior

5. **💬 Documentation** - For intentional behavioral changes
   - Add code comments explaining why the change was made
   - Update any affected documentation
```

### 6. Exit Status (for CI Integration)

When running with `--ci` flag (future enhancement):
- Exit 0: No critical issues found
- Exit 1: Critical issues found (should block merge)
- Exit 2: High priority issues found (warning)

## Usage Examples

### Default: Review Staged Changes (Strict Mode)
```bash
/behavioral-diff:review
```

### Review Current Branch vs Main
```bash
/behavioral-diff:review --branch
```

### Review Last Commit
```bash
/behavioral-diff:review --commit
```

### Review Specific File
```bash
/behavioral-diff:review src/Services/OrderService.cs
```

### Review with Normal Sensitivity
```bash
/behavioral-diff:review --normal
```

### Combined Options
```bash
/behavioral-diff:review --branch --normal src/Services/
```

## What Gets Flagged

**CRITICAL (Always Flag):**
- Direct boolean inversions: `if (x)` → `if (!x)`
- Swapped if/else branches
- Equality inversions: `==` → `!=`
- AND/OR swaps: `&&` → `||`

**HIGH (Always Flag):**
- Comparison operator changes: `<` → `>`
- Null check inversions
- Guard clause inversions
- Return value inversions

**MEDIUM (Flag in Strict Mode):**
- Loop bound changes (off-by-one potential)
- LINQ semantic changes
- Ternary operand swaps
- Exception handling changes

**LOW (Flag in Strict Mode Only):**
- String comparison method changes
- Potential but uncertain inversions
- Related code that might indicate inversion

## What Does NOT Get Flagged

- Whitespace/formatting changes
- Comment changes
- Variable renames (without logic change)
- Pure additions (new code paths)
- Refactoring that preserves behavior
- Type annotation changes

## Implementation Notes

**For the orchestrator (you):**

1. **Parse arguments** - Determine scope (staged/branch/commit) and mode (strict/normal)
2. **Get the diff** - Run appropriate `git diff` command using Bash
3. **Handle empty diff** - If no diff output, report "No changes to analyze" and exit
4. **Identify files** - Parse diff to find changed .cs, .fs, .vb, .xaml, .razor files
5. **Check for test files** - Note which files have corresponding test files in the diff
6. **Invoke analyzers in parallel** - For each file, launch both agents simultaneously:
   - `control-flow-analyzer` - Syntactic pattern detection
   - `business-logic-analyzer` - Semantic understanding
7. **Merge findings** - Deduplicate and combine results from both analyzers
8. **Apply mode filter** - In NORMAL mode, filter out low-confidence findings
9. **Generate report** - Present consolidated findings grouped by severity
10. **Summarize** - Include counts, test coverage warnings, intentionality assessment
11. **Recommend actions** - Provide specific, actionable next steps

**Parallel Execution Strategy:**

```
For each file in changed_files:
    Task 1: control-flow-analyzer(file, diff, mode)
    Task 2: business-logic-analyzer(file, diff, mode)
    [Run Task 1 and Task 2 in parallel]

Merge all results
Apply mode-specific filtering
Generate unified report
```

**Important:**
- Always show the full diff context for each finding
- Include line numbers for easy navigation
- Be specific about what changed and why it matters
- Respect developer intent - flag issues but don't assume malice
- In NORMAL mode, only surface high-confidence findings
- Deduplicate when both analyzers flag the same issue
- Prioritize actionability - developers should know exactly what to do

## Best Practices for Developers

After running this review:

1. **For each CRITICAL finding:**
   - Stop and verify the change is intentional
   - If intentional, add a comment explaining why
   - If unintentional, fix immediately

2. **For HIGH/MEDIUM findings:**
   - Review the surrounding context
   - Check if tests cover the changed behavior
   - Add tests if coverage is missing

3. **Run before every commit:**
   - Make this part of your pre-commit routine
   - Catch inversions early, before code review
