---
name: verify-claim
description: "Deeply verify a user-supplied claim against codebase, documentation, and the web. Delegates to a dedicated opus investigator agent and returns a sourced verdict with rubric-based confidence. Use when the user asks to verify, fact-check, confirm, disprove, or source-check a claim. (Triggers: verify claim, verify-claim, fact check, fact-check, is this true, can you confirm, prove this, disprove this, source check)"
allowed-tools: [Task]
argument-hint: "<the claim to verify>"
---

# Verify Claim

Deeply verify a user-supplied claim and return a sourced verdict with a confidence score.

## Invocation

```
/verify-claim:verify-claim <any claim in natural language>
```

The claim text is in `$ARGUMENTS`.

## Examples

**Verified:**
> `/verify-claim:verify-claim Claude Code's allowed-tools frontmatter restricts which tools a skill can invoke`
Returns: Verdict: Verified, Confidence: 95/100

**Hallucination / unverifiable:**
> `/verify-claim:verify-claim The claude CLI supports a --mind-meld flag for sharing context between sessions`
Returns: Verdict: Hallucination / unverifiable, Confidence: 5/100. Possible source of confusion: the `--resume` / `--continue` flags restore previous sessions but are unrelated.

**Unclear:**
> `/verify-claim:verify-claim GitLab CI needs: and dependencies: keywords are interchangeable`
Returns: Verdict: Unclear, Confidence: 52/100 - conflicting evidence across CI versions.

## Workflow

### Step 1 - Capture the claim

Read `$ARGUMENTS` verbatim as the claim under investigation. Do not paraphrase or split it. If `$ARGUMENTS` is empty, ask the user for the claim and stop.

### Step 2 - Delegate to the investigator

Spawn the dedicated investigator agent using the **Task tool**:

- `subagent_type`: `"claim-verifier"` (bare agent name - not namespaced)
- `description`: short (3-5 word) summary of the claim
- `prompt`: pass the full claim text plus any relevant context the user has already shared in this session (e.g. files the user mentioned, technologies in use). The prompt must instruct the agent to return the exact output format defined in its agent file.

Do **not** perform the investigation yourself in the main context. The investigator runs in an isolated window so its evidence-gathering does not pollute the main thread. This is also why the skill's own `allowed-tools` is just `[Task]` - the main agent has no business running Grep or WebFetch directly for this workflow.

### Step 3 - Relay the verdict

When the agent returns:

1. Present the agent's verdict block to the user **verbatim** (it is already formatted).
2. Do not add commentary, summaries, or reinterpretations unless the user asks a follow-up.
3. If any of the six required headers (`## Verdict`, `## Confidence`, `## Claim`, `## Evidence for`, `## Evidence against`, `## Gaps`) are absent, re-invoke the agent once with: "Your previous output was missing `## X`. Re-emit the complete block per the output contract."
4. If the second invocation is still malformed, surface the raw agent output to the user with a one-line note: "Structured contract failed - raw output below." Do not silently swallow it.

## Output Contract

The investigator agent returns a markdown block in this shape (mirrors claim-verifier.md exactly):

```markdown
## Verdict
<Verified | Likely true | Unclear | Likely false | Hallucination / unverifiable>

## Confidence
<N> / 100 - <band label>

## Claim
> <the claim verbatim>

## Evidence for
- <finding in plain English> - <citation: file:line | URL | command output>
- ...

## Evidence against
- <finding in plain English> - <citation>
- ...

## Gaps
- <what you could not check and why>
- ...

## Possible source of confusion
(only present when verdict is "Likely false" or "Hallucination / unverifiable")
```

### Confidence bands (defined fully in the agent file)

| Band | Range |
|------|-------|
| Verified | 90-100 |
| Likely true | 70-89 |
| Unclear | 40-69 |
| Likely false | 15-39 |
| Hallucination / unverifiable | 0-14 |

## Rules

- Never fabricate evidence to fill sections - an invented citation looks identical to a real one to the user, so the cost of a bad citation is unbounded. Empty sections are acceptable; invented citations are not.
- Never downgrade or upgrade the agent's confidence score - this skill is a relay, not an evaluator; the rubric is owned by the investigator agent.
- The epistemic labels (`[FACT]`, `[INFERRED]`, `[ASSUMED]`) used elsewhere in this repo are **not** part of this skill's vocabulary. The output uses the rubric bands defined by the investigator.
