# Inversion Patterns Reference

A comprehensive catalog of logic inversion patterns that can cause production bugs. Use this reference for:
- Manual code review
- Configuring automated tools (CodeRabbit, linters)
- Training new developers
- Understanding behavioral diff findings

## Quick Reference Table

| Pattern | Example | Severity | Detection Difficulty |
|---------|---------|----------|---------------------|
| Direct boolean inversion | `if(x)` → `if(!x)` | CRITICAL | Easy |
| Equality inversion | `==` → `!=` | CRITICAL | Easy |
| AND/OR swap | `&&` → `\|\|` | CRITICAL | Easy |
| Comparison direction | `<` → `>` | HIGH | Easy |
| Null check inversion | `!= null` → `== null` | HIGH | Easy |
| Guard clause inversion | Early return flipped | HIGH | Medium |
| Return value inversion | `return true` → `return false` | HIGH | Medium |
| If/else swap | Branches exchanged | CRITICAL | Medium |
| Ternary swap | `a ? b : c` → `a ? c : b` | HIGH | Medium |
| LINQ semantic change | `.Any()` → `.All()` | HIGH | Hard |
| Loop bound change | `<` → `<=` | MEDIUM | Medium |
| Boundary off-by-one | `i < n` → `i < n-1` | MEDIUM | Hard |

---

## Pattern Catalog

### 1. Direct Boolean Inversions

**Severity: CRITICAL**

The most dangerous and common inversion pattern.

#### 1.1 Negation Added

```csharp
// BEFORE (correct)
if (order.IsValid)
{
    ProcessOrder(order);
}

// AFTER (BROKEN!)
if (!order.IsValid)  // Added negation
{
    ProcessOrder(order);  // Now processes INVALID orders
}
```

#### 1.2 Negation Removed

```csharp
// BEFORE (correct)
if (!user.IsDeleted)
{
    ShowUserProfile(user);
}

// AFTER (BROKEN!)
if (user.IsDeleted)  // Removed negation
{
    ShowUserProfile(user);  // Now shows DELETED users
}
```

#### 1.3 Double Negation Issues

```csharp
// BEFORE
if (!string.IsNullOrEmpty(input))

// AFTER - Someone "fixed" the double negative
if (string.IsNullOrEmpty(input))  // WRONG! Inverted the logic
```

---

### 2. Comparison Operator Inversions

**Severity: HIGH to CRITICAL**

#### 2.1 Equality Inversions

```csharp
// BEFORE
if (status == Status.Active)

// AFTER (INVERTED!)
if (status != Status.Active)
```

```csharp
// BEFORE
if (count != 0)  // Continue if there are items

// AFTER (INVERTED!)
if (count == 0)  // Now continues only when EMPTY
```

#### 2.2 Relational Operator Direction Changes

```csharp
// BEFORE - Discount for orders over $100
if (order.Total > 100)
    ApplyDiscount();

// AFTER (INVERTED!) - Discount for orders UNDER $100
if (order.Total < 100)
    ApplyDiscount();
```

#### 2.3 Boundary Changes (Off-by-One)

```csharp
// BEFORE - Includes the boundary
if (age >= 18)  // 18+ allowed

// AFTER (CHANGED!) - Excludes the boundary
if (age > 18)   // Only 19+ allowed now
```

```csharp
// BEFORE
if (index < array.Length)  // Valid index check

// AFTER (CHANGED!)
if (index <= array.Length)  // Off-by-one error!
```

---

### 3. Boolean Expression Changes

**Severity: CRITICAL**

#### 3.1 AND to OR (More Permissive)

```csharp
// BEFORE - Must be BOTH admin AND active
if (user.IsAdmin && user.IsActive)
    GrantAccess();

// AFTER (MUCH MORE PERMISSIVE!)
if (user.IsAdmin || user.IsActive)  // Either one is enough now
    GrantAccess();
```

#### 3.2 OR to AND (More Restrictive)

```csharp
// BEFORE - Either condition triggers alert
if (temperature > 100 || pressure > 50)
    TriggerAlert();

// AFTER (MISSES ALERTS!)
if (temperature > 100 && pressure > 50)  // Both required now
    TriggerAlert();
```

#### 3.3 De Morgan Violations

```csharp
// BEFORE
if (!(a && b))  // NOT (a AND b) = (!a OR !b)

// AFTER - Incorrect De Morgan application
if (!a && !b)   // WRONG! This is (!a AND !b)
```

---

### 4. Null Check Inversions

**Severity: HIGH**

#### 4.1 Null Equality Inversion

```csharp
// BEFORE - Null guard
if (user == null)
    return;
ProcessUser(user);

// AFTER (INVERTED!)
if (user != null)  // Now returns when user EXISTS
    return;
ProcessUser(user);  // NullReferenceException!
```

#### 4.2 Null Conditional Removal

```csharp
// BEFORE - Safe navigation
user?.Profile?.Settings?.Theme

// AFTER (UNSAFE!)
user.Profile.Settings.Theme  // NullReferenceException risk
```

#### 4.3 Null Coalescing Changes

```csharp
// BEFORE - Default fallback
var name = user?.Name ?? "Guest";

// AFTER (NO FALLBACK!)
var name = user?.Name;  // Can be null now
```

#### 4.4 Pattern Matching Inversions

```csharp
// BEFORE
if (obj is string text)

// AFTER (INVERTED!)
if (obj is not string)
```

---

### 5. Control Flow Inversions

**Severity: HIGH**

#### 5.1 If/Else Branch Swap

```csharp
// BEFORE
if (isSuccess)
{
    SaveToDatabase();
}
else
{
    LogError();
}

// AFTER (SWAPPED!)
if (isSuccess)
{
    LogError();        // Now logs on SUCCESS
}
else
{
    SaveToDatabase();  // Now saves on FAILURE
}
```

#### 5.2 Guard Clause Inversions

```csharp
// BEFORE - Returns early on invalid
if (input == null)
    return;
Process(input);

// AFTER (INVERTED!)
if (input != null)    // Returns when VALID
    return;
Process(input);       // Processes NULL!
```

#### 5.3 Return Value Inversions

```csharp
// BEFORE
public bool IsValid()
{
    if (HasErrors)
        return false;
    return true;
}

// AFTER (INVERTED!)
public bool IsValid()
{
    if (HasErrors)
        return true;   // Returns true when INVALID!
    return false;
}
```

---

### 6. Loop Inversions

**Severity: MEDIUM to HIGH**

#### 6.1 Loop Bound Changes

```csharp
// BEFORE - Process all items
for (int i = 0; i < items.Length; i++)

// AFTER (MISSES LAST!)
for (int i = 0; i < items.Length - 1; i++)
```

#### 6.2 Loop Direction Changes

```csharp
// BEFORE - Forward iteration
for (int i = 0; i < n; i++)
    Process(items[i]);

// AFTER (REVERSED!)
for (int i = n - 1; i >= 0; i--)
    Process(items[i]);  // Order may matter!
```

#### 6.3 While Condition Changes

```csharp
// BEFORE
while (queue.Count > 0)
    ProcessNext();

// AFTER (INVERTED!)
while (queue.Count == 0)  // Only runs when EMPTY
    ProcessNext();
```

---

### 7. LINQ Inversions

**Severity: MEDIUM to HIGH**

#### 7.1 Predicate Inversions

```csharp
// BEFORE
items.Where(x => x.IsActive)

// AFTER (INVERTED!)
items.Where(x => !x.IsActive)  // Returns INACTIVE items
```

#### 7.2 Any/All Swaps

```csharp
// BEFORE - True if any item has error
if (items.Any(x => x.HasError))

// AFTER (DIFFERENT LOGIC!)
if (items.All(x => x.HasError))  // True only if ALL have errors
```

#### 7.3 First/FirstOrDefault Changes

```csharp
// BEFORE - Returns null if empty
items.FirstOrDefault()

// AFTER (CAN THROW!)
items.First()  // Throws if empty
```

#### 7.4 Take/Skip Swaps

```csharp
// BEFORE - Get first 10
items.Take(10)

// AFTER (COMPLETELY DIFFERENT!)
items.Skip(10)  // Get all EXCEPT first 10
```

#### 7.5 OrderBy Direction Changes

```csharp
// BEFORE - Oldest first
items.OrderBy(x => x.Date)

// AFTER (REVERSED!)
items.OrderByDescending(x => x.Date)  // Newest first
```

---

### 8. Ternary Operator Inversions

**Severity: HIGH**

#### 8.1 Operand Swap

```csharp
// BEFORE
var result = isSuccess ? "OK" : "Error";

// AFTER (SWAPPED!)
var result = isSuccess ? "Error" : "OK";  // Messages reversed
```

#### 8.2 Condition Inversion

```csharp
// BEFORE
var price = isPremium ? discountedPrice : fullPrice;

// AFTER (INVERTED!)
var price = !isPremium ? discountedPrice : fullPrice;  // Non-premium gets discount
```

---

### 9. Exception Handling Inversions

**Severity: MEDIUM to HIGH**

#### 9.1 Throw Condition Inversion

```csharp
// BEFORE - Throws on invalid
if (!isValid)
    throw new ValidationException();

// AFTER (INVERTED!)
if (isValid)  // Throws on VALID
    throw new ValidationException();
```

#### 9.2 Swallowed Exceptions

```csharp
// BEFORE
catch (Exception ex)
{
    _logger.LogError(ex, "Operation failed");
    throw;  // Re-throws
}

// AFTER (SWALLOWED!)
catch (Exception ex)
{
    _logger.LogError(ex, "Operation failed");
    // throw removed - exception swallowed
}
```

---

### 10. String Comparison Inversions

**Severity: LOW to MEDIUM**

#### 10.1 Contains/Not Contains

```csharp
// BEFORE
if (email.Contains("@"))

// AFTER (INVERTED!)
if (!email.Contains("@"))
```

#### 10.2 StartsWith/EndsWith Swap

```csharp
// BEFORE
if (filename.EndsWith(".pdf"))

// AFTER (WRONG CHECK!)
if (filename.StartsWith(".pdf"))
```

#### 10.3 Empty String Checks

```csharp
// BEFORE
if (string.IsNullOrEmpty(input))

// AFTER (DIFFERENT BEHAVIOR!)
if (string.IsNullOrWhiteSpace(input))  // Also catches whitespace
```

---

## Language-Specific Patterns

### C# Specific

#### Async/Await Changes

```csharp
// BEFORE - Captures context
await task.ConfigureAwait(true);

// AFTER - Different threading behavior
await task.ConfigureAwait(false);
```

#### Nullable Reference Type Changes

```csharp
// BEFORE - Nullable
string? name = null;

// AFTER - Non-nullable (can cause warnings/errors)
string name = null;  // Warning/error if nullable enabled
```

#### Null-Forgiving Operator

```csharp
// BEFORE - Asserts not null
user!.Name

// AFTER - No assertion
user.Name  // May be null
```

---

## Detection Strategies

### For Code Review

1. **Search for changed operators**: `git diff | grep -E '[-+].*(==|!=|<|>|&&|\|\|)'`
2. **Look for negation changes**: `git diff | grep -E '[-+].*!.*\('`
3. **Check boolean method calls**: Changes to `Is*`, `Has*`, `Can*` methods
4. **Review conditional logic**: Any `if`, `while`, `for`, `?:` changes

### For Automated Tools

Configure your linter/analyzer to flag:
- Boolean parameter changes in conditionals
- Operator modifications in comparisons
- LINQ method swaps
- Null check modifications

### For CodeRabbit

Add to `.coderabbit.yaml`:

```yaml
reviews:
  instructions: |
    CRITICAL: Flag any of these inversion patterns:
    - Boolean inversions: if(x) → if(!x)
    - Operator swaps: == → !=, < → >, && → ||
    - Null check changes: != null → == null
    - Guard clause inversions
    - Return value inversions: return true → return false
    - LINQ predicate inversions
    - Ternary operand swaps

    For each potential inversion found:
    1. Show the before/after code
    2. Explain the behavioral impact
    3. Ask if the change was intentional
```

---

## False Positive Patterns

These look like inversions but are often intentional:

### 1. Guard Clause Refactoring

```csharp
// BEFORE
if (x != null) {
    DoSomething(x);
}

// AFTER - Intentional refactor to guard clause
if (x == null) return;
DoSomething(x);
```

### 2. Validation Consolidation

```csharp
// BEFORE
if (isValid) Process();

// AFTER - Intentional validation-first pattern
if (!isValid) throw new ValidationException();
Process();
```

### 3. Feature Flag Changes

```csharp
// Changes controlled by feature flags are often intentional A/B tests
if (featureFlags.NewBehavior && condition)
```

### 4. Test-Driven Changes

```csharp
// When test expectations change alongside code, the change is likely intentional
```

---

## Checklist for Reviewers

Before approving code with condition changes:

- [ ] Is the inversion intentional? (Ask the author)
- [ ] Do tests validate the new behavior?
- [ ] Is there a comment explaining why?
- [ ] Does the method/variable name still make sense?
- [ ] Are related conditions also updated consistently?
- [ ] Is this a known refactoring pattern (guard clause, etc.)?

---

*This document is part of the behavioral-diff plugin. Report issues or suggest patterns at the plugin repository.*
