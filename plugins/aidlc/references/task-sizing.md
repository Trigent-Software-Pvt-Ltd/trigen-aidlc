# Task Sizing Guidance (Internal Quality Control)

After generating Task Specifications, apply **internal sizing** to ensure right-sized work items. This is for quality control only — **do not present estimates to the user**.

> **Purpose**: Shake off trivial tasks, force splitting of big ones, keep tasks in a human-relatable range.

## Fibonacci Scale

Use effort + risk + uncertainty, not time:

| Size | Meaning | Action |
|------|---------|--------|
| **1** | Trivial. Obvious solution, no risk, no dependencies. "Half-asleep work." | ⚠️ Too small — combine with related tasks or drop |
| **2** | Still small. One clear approach, maybe a tiny edge case. | ⚠️ Consider combining if several 2s cluster together |
| **3** | Small but real work. A few moving parts, might need a test tweak. | ✅ Good size |
| **5** | Medium. Multiple steps/components, some uncertainty, needs thought. | ✅ Ideal size |
| **8** | Large. Unclear bits, integration/coordination risk. "Could bite us." | ✅ Acceptable, watch for splitting opportunity |
| **13** | Very large. High uncertainty, needs discovery or splitting. | ⚠️ Should be split — if it stays 13, something's wrong |
| **21+** | Too big. You don't understand it yet. | 🛑 Must split — this is a planning failure |

## Why Fibonacci

- Gaps get bigger on purpose
- As work grows, uncertainty grows **non-linearly**
- Forces admission: "We don't know enough to be precise"
- You CAN reliably tell 3 vs 5
- You CANNOT reliably tell 8 vs 9 vs 10 → hence no 4, 6, 7

### Rough Mental Mapping (internal only)

Not time, but useful internally:

| Size | Rough Effort |
|------|--------------|
| 1–2 | Hours |
| 3 | Half day |
| 5 | Day or two |
| 8 | Several days |
| 13 | Week-ish (if nothing explodes) |
| 21+ | Planning failure |

## Sweet Spot

**Target range: 3–8**

- Below 3: Too granular, combine or drop
- Above 8: Too uncertain, split or spike

## Sizing Actions

### For 1s (trivial)

- Combine multiple 1s into a single task
- Or absorb into a related larger task
- Or drop if it's just noise (e.g., "change button color")

### For 2s

- If clustered, combine into one 3-5
- If standalone, keep if genuinely distinct

### For 13s

- Identify the uncertainty: what don't we know?
- Split by: component, layer, scenario, or happy-path vs edge-cases
- Consider: does this need a spike/discovery task first?

### For 21+

- This is not a task, it's an Epic
- Break into multiple tasks
- If can't break down → missing understanding → needs discovery

## Splitting Patterns

When a task is too big, split by:

| Pattern | Example |
|---------|---------|
| **By layer** | "Build feature" → "API endpoint" + "UI component" + "Data layer" |
| **By scenario** | "Handle payments" → "Happy path" + "Decline handling" + "Refunds" |
| **By component** | "Dashboard" → "Charts widget" + "Stats widget" + "Activity feed" |
| **Happy path first** | "Full flow" → "Basic flow" + "Edge cases" + "Error handling" |
| **Spike + implement** | "Complex feature" → "Spike: research approach" + "Implement solution" |

## Internal Sizing Workflow

During Task Specification generation (design phase):

1. **Size each task internally** (don't tell user)
2. **Flag outliers:**
   - 1s: "These look trivial, combining..."
   - 13+: "This is too large, splitting..."
3. **Combine/split as needed**
4. **Re-check sizing after changes**
5. **Write `size:` into Task Spec frontmatter** (Fibonacci value)

## Example Cleanup

```
Before (raw task generation):
- "Change submit button color" (1) ← trivial
- "Update button hover state" (1) ← trivial
- "Add loading spinner to button" (2) ← small
- "Implement full payment flow with retry, refund, and webhook handling" (21) ← way too big

After (right-sized):
- "Polish submit button UX" (3) ← combined 1s and 2
- "Implement payment happy path" (5)
- "Add payment retry logic" (5)
- "Handle refunds" (5)
- "Integrate payment webhooks" (5)
```

## Using Size in Task Specs and Jira

During `/aidlc-design`: Sizing is internal quality control and is written into Task Spec frontmatter
- ✅ Use internally to right-size tasks (combine 1-2s, split 13+)
- ✅ Write final `size:` value into Task Spec frontmatter
- ❌ Don't narrate the sizing process to the user

During `/aidlc-verify`: Size maps directly to Jira Story Points
- ✅ Read `size:` from Task Spec frontmatter
- ✅ Write to Jira Story Points field (if configured)
- ✅ Flag large tasks (13+) in verification report
- ❌ Don't show individual scores during scoring step (report aggregate only)

## Golden Rule

If you find yourself arguing:

- **About the number** → you're doing it wrong
- **About what could go wrong** → you're doing it right
