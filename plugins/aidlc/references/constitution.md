# Project Constitution (template)

A **short, versioned** statement of the principles every AI-DLC artifact for this project must
honor — the fixed points that specs, designs and tickets are checked *against*. Written once at
`/aidlc-init`, stored as `aidlc.constitution.md` at the project root, and read by `/aidlc-intent`,
`/aidlc-design` and `/aidlc-verify`.

**Keep it to one page.** It is *principles and constraints*, not a design or a standards manual.
Where an org standard already covers something, **link the `standards` plugin, don't restate it**.

---

## How AI-DLC uses it

- `/aidlc-intent` — the brief/Intent must not contradict a principle; note any tension as an open
  question.
- `/aidlc-design` — a decision that breaks a constraint requires an **ADR** (and usually the Deep
  gear), not a silent exception.
- `/aidlc-verify` — the **coherence check** flags any Task Spec or design choice that violates the
  constitution before tickets are created.

A constitution is a living document: amend it deliberately (bump the version + date), don't drift.

---

## Template (`aidlc.constitution.md`)

```markdown
# <Project> — Constitution
Version: 1.0 · Updated: <date> · Owner: <name>

## Principles (non-negotiable)
- <e.g. TDD: a failing test precedes implementation.>
- <e.g. Every user-facing change meets WCAG 2.1 AA.>
- <e.g. No PII in logs, URLs or analytics.>

## Constraints (the box we build in)
- Stack: <languages, frameworks, datastores>
- Data & tenancy: <e.g. every row scoped by tenant_id; data residency = ...>
- Security posture: <authN/authZ model, secrets handling> — see standards: <link>

## Conventions (how we keep things consistent)
- API style, naming, error shape: see standards: <link> (restate only project-specific deltas)
- Branching / MR / review: <one line or a standards link>

## Governance (the gates)
- Human approval per phase; show draft → approve → publish before any shared-system write.
- Definition of done: <tests green, review passed, docs/tickets updated>.
```

Sections with nothing project-specific to say should just **point to the `standards` plugin** and
move on — a good constitution is mostly links plus a handful of genuinely local rules.
