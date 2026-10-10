# Task handoff summary (context-rot prevention)

Long sessions and subagent handoffs accumulate stale context that gets re-read (and re-billed) every
turn and slowly buries the rules that matter. A **handoff summary** is the compact, current state a new
session or subagent needs — instead of replaying the whole conversation or reloading every lifecycle
document. It complements the sprint **recovery ledger** (`execution-rigor.md` §2): the ledger is the
machine recovery map; the handoff is the human-readable "where we are".

## Before implementation — read, don't paste
An agent must read the applicable project instructions and architecture context before changing code:
`AGENTS.md`/`CLAUDE.md`, the Constitution, the PRD/Design sections for *this* story (see
`agent-toolchain.md`). Read the files; do not paste their entire contents into the prompt.

## Handoff summary — the fields
Keep it short (fits on a screen). Write it to a working file (e.g. `.aidlc/sprint/<id>/handoff.md`) at
session end or before a subagent dispatch:

- **Current story** — key + one-line intent.
- **Approved scope** — what was agreed in; what's explicitly out.
- **Completed** — what's done and merged (with commit/PR refs), per the ledger.
- **Remaining** — the next concrete steps.
- **Known risks / open questions** — and any parked findings or ADR escalations.
- **Verification status** — which items of `verification-checklist.md` are PASS / NOT RUN.
- **Key files** — the handful of paths this work touches.

## Hygiene
- One task per session where practical; **compact early**; resume an old thread from this summary, not
  the raw history (`token-economics.md`).
- **Prune as you add** — drop stale architecture notes and dead conventions; they mislead as badly as
  missing ones.
- A subagent dispatch carries a task **brief**, not the session's history (`execution-rigor.md` §3).
