---
name: consider
description: "Present multiple solution options before implementing. Use when the user asks how to approach something, design a system, choose between approaches, fix a bug, or implement a feature. Forces structured comparison of viable options with pros/cons before any code is written. Prevents jumping to the easiest solution. Use this skill whenever the user is weighing tradeoffs, asking 'should I use X or Y?', saying 'what's the best way to...', 'help me decide', 'what are the tradeoffs', or any variation of needing to choose between approaches — even if they don't explicitly say 'consider'. (Triggers: consider, weigh options, what approach, how should I, compare approaches, what are my options, best way to, help me decide, what's the tradeoff, should I use, which is better)"
allowed-tools: [Read, Grep, Glob, AskUserQuestion, EnterPlanMode]
argument-hint: "<problem or task description>"
---

# Consider: Structured Decision-Making

Force a structured comparison of viable approaches before implementing anything. Never jump to a single solution.

## Workflow

### Phase 1: Understand the Problem

Grounding in reality prevents options that sound good on paper but don't fit the codebase or constraints.

1. Read the user's problem/task description from the arguments.
2. **If the problem involves code:** explore the codebase to ground options in reality.
   - Use Glob/Grep to find relevant files, patterns, and existing conventions.
   - Read key files to understand current architecture, constraints, and dependencies.
   - Note existing patterns that options should respect.
3. **If the problem is abstract/architectural:** reason from the description and any referenced context.
4. Keep codebase exploration minimal and targeted to what you need to distinguish options. Avoid scanning large portions of the repo unnecessarily.

### Phase 2: Generate Options

Present **2-4 genuinely viable options**. The detail sections let the user understand each option deeply; the comparison grid lets them scan across options at a glance.

Rules:
- Only include options that could realistically work. If only 2 are viable, present 2. Never pad with bad options to meet a minimum.
- If only 1 option is viable, present it with its tradeoffs, explain why alternatives were ruled out, and confirm with the user before entering Phase 4. Skip the comparison grid — a single column offers no comparison value.
- Each option must be meaningfully different from the others (not variations of the same idea).
- Be honest about tradeoffs. Do not sugarcoat cons or inflate pros.

Present detail sections for each option, followed by a comparison grid:

```markdown
## Options

### Option 1: {name}

**How it works:** {1-3 sentences}

**Pros:**
- {pro}
- {pro}

**Cons:**
- {con}
- {con}

{repeat for each option}

## Comparison Grid

| Criteria     | Option 1: {name} | Option 2: {name} | Option 3: {name} |
|--------------|-------------------|-------------------|-------------------|
| Effort       | Low               | Medium            | High              |
| Risk         | Low               | Medium            | Low               |
| {criteria 3} | ...               | ...               | ...               |
| {criteria N} | ...               | ...               | ...               |

**Key insight:** {one sentence highlighting the most important differentiator between the options}

**Blockers:** {any critical unknowns that must be resolved before committing to an approach, or "None identified"}
```

If codebase exploration was done, reference specific files/patterns that support or constrain each option in the detail sections.

**Comparison grid guidelines:**
- Pick 5-8 criteria relevant to the specific decision (e.g., effort, risk, alignment with existing patterns, readiness, tech debt impact, delivery dependency, reversibility, best when).
- Use short values: Yes/No, Low/Med/High, or brief phrases.
- Adjust columns to match the number of options presented.
- End with a **Key insight** highlighting the most important differentiator, and flag any critical unknowns as **Blockers** to resolve before committing.

After presenting the grid, you may indicate which option you'd lean toward given the user's constraints and why, while still letting them choose.

### Phase 3: Interview the User

The user needs to own the decision — presenting options without asking creates the illusion of choice. This step ensures commitment to the chosen path.

Use `AskUserQuestion` to let the user choose. Structure the question so each option label matches the detail sections, and the description summarizes the key tradeoff.

Example:
```
AskUserQuestion(
  question: "Which approach do you want to go with?",
  header: "Approach",
  options: [
    { label: "Option 1: {name}", description: "{key tradeoff summary}" },
    { label: "Option 2: {name}", description: "{key tradeoff summary}" },
    { label: "Option 3: {name}", description: "{key tradeoff summary}" }
  ],
  multiSelect: false
)
```

Note: Claude Code automatically adds an "Other" option allowing free-text input. If the user picks "Other" and provides custom input, incorporate their feedback:
- If they want a hybrid of options, synthesize and confirm.
- If they raise a new approach, regenerate the options with the new approach included and re-ask via AskUserQuestion.

### Phase 4: Plan the Chosen Approach

Once the user has chosen, call `EnterPlanMode` to plan the implementation of the selected approach.

In planning mode:
- Reference the chosen option's detail section and comparison grid data as context — the user chose with that information in mind, so the plan should honour the tradeoffs they accepted.
- Carry forward any **Blockers** from the grid and address them early in the plan.
- Use the **Key insight** to prioritise what matters most in the implementation.
- Explore any additional files needed for implementation.
- Produce a concrete, step-by-step implementation plan.
- Call out risks identified in Phase 2 and how the plan mitigates them.
