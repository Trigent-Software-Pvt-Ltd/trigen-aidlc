---
name: aidlc-refactor
description: Test-first agentic refactoring / tech-debt cleanup. Before the agent changes old code, it pins current behavior with characterization tests, gets a green baseline, then refactors in small reversible steps that keep the suite green and preserve external contracts. Use for brownfield cleanup, not new features. (Triggers - refactor, clean up this module, tech debt, characterization tests, safe refactor, refactor without breaking, agentic refactoring, brownfield cleanup)
---

# AI-DLC Agentic Refactoring

Before the agent cleans up old code, make it **prove the behavior stays the same.** A clean-looking
rewrite that changes behavior is still a bug. The move is test-first: characterize, get green,
refactor in small steps, stay green. This is the brownfield counterpart to `/aidlc-sprint` (which
builds new behavior); use it when the goal is *change structure, preserve behavior*.

> Use this for tech-debt cleanup and restructuring. If the goal is new/changed behavior, that's a
> normal feature — run it through intent → design → sprint instead.

## The loop: Characterize → Change → Verify → Commit (repeat, each pass green)

1. **Characterize** — the agent reads the target code and writes a **behavior spec** of what it
   observably does today (inputs, outputs, side effects, error behavior, external contracts). Then it
   generates **characterization tests** that pin that behavior.
2. **Green baseline** — the characterization tests must **pass against the current code first**. No
   refactor starts until the net is green. (If a test can't pass against current code, it's asserting
   an assumption, not the real behavior — fix the test.)
3. **Mark each behavior** — `must-preserve`, `intentionally-changing`, or `actually-a-bug`. Only
   `intentionally-changing`/`actually-a-bug` may alter behavior, and those should be raised as their
   own tickets, not smuggled into the cleanup.
4. **Change in small, reversible steps** — isolate I/O, split validation from side effects, retire one
   branch of a conditional at a time. **Never "rewrite this module" in one shot.**
5. **Verify** — re-run the safety net after every step; **never carry red into the next step.**
6. **Commit** — small green commits; each is independently reviewable and revertible.

## Preserve the contract
External contracts stay identical unless a ticket says otherwise: **APIs, schemas, logs, outputs,
screenshots, events.** Characterization tests freeze the *observable* behavior; change internals only
while that contract stays green. **Do not patch a test just to make the refactor pass** — that
discards the safety net.

## Guardrails & fit with AI-DLC
- Runs under the same execution rigor as a sprint: recovery ledger, task briefs/context hygiene, and
  the two-stage review + fix-loop (`references/execution-rigor.md`).
- Test craft (reliable locators, deterministic mocks, mutation checks to prove the net is real):
  `references/test-reliability.md`.
- Isolate large refactors in their own worktree/branch (`execution-rigor.md` §5).
- Ceremony-scaled: **Quick** for a small, well-covered module; **Standard** for a typical module;
  **Deep** (behavior spec + broad characterization + phased strangler) for a high-blast-radius core.
- For a legacy replacement, prefer the **Strangler pattern** — route new behavior around the old,
  retire it incrementally behind the green net, rather than a big-bang rewrite.

## Common mistake to avoid
A clean-looking rewrite that changes behavior is still a bug. Do not refactor without a green
behavior net first.

## What mastery looks like
A green baseline exists before a line moves; every chunk leaves the suite green; behavior is identical
and only the structure improved.

## References
- @${CLAUDE_PLUGIN_ROOT}/references/test-reliability.md — characterization + mutation testing.
- @${CLAUDE_PLUGIN_ROOT}/references/execution-rigor.md — ledger, review, worktrees.
- @${CLAUDE_PLUGIN_ROOT}/references/evidence-led-pr.md — put the green baseline + diff in the PR.
