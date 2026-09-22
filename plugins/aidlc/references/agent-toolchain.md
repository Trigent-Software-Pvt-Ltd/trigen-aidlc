# Agent Toolchain & Repo Context Bootstrap

Set the coding agent up like a new teammate **in the target code repo** before it changes anything:
house rules, guardrails, least-privilege access, and a repo-context layer it can navigate. AI-DLC
governs *the plan* (PRD → design → tickets); this governs *the agent doing the build*. The two are
complementary — the Constitution holds project principles; this holds the agent's operating
environment.

> Scope: this is about the **product repo** the team implements in (e.g. `QMetry360igen-api`,
> `Qmetry360igen-ui`), not the AI-DLC docs repo. Everything here is **additive** and optional; if a
> file already exists, extend it, never clobber it.

## 1. Project rules — `AGENTS.md` / `CLAUDE.md`

A tight, always-on rules file at the repo root so every session starts informed, not blind:

- Project overview, the scripts that matter (build / test / run / lint), and team conventions.
- A `Do not touch` list (generated files, vendored code, migrations already shipped).
- Keep it **lean** (aim ≤ ~150 lines). Push deep detail into `references/`-style docs or skills and
  **link** them; a bloated rules file gets ignored and re-billed every turn.
- Point at the AI-DLC artifacts: the PRD, the Design Document, `aidlc.constitution.md`.

## 2. Guardrails — gated, not wide open

- **Never run YOLO / `--dangerously-skip-permissions`.** Run in safe auto mode: the agent acts, but
  risky actions still need approval. (This is the build-time twin of AI-DLC's publish gate.)
- **Deny rules** so a stray instruction — even one hidden in an issue, README, or tool description —
  cannot read secrets or `.env`, or force-push. Secrets/PII/auth paths are **NO ACCESS**.
- **PreToolUse hooks** for guardrails static rules can't express (e.g. block writes outside the
  worktree, block network in tests, block `git push --force`).

## 3. Least privilege — only the keys it needs

- Wire only the CLIs / MCP servers the task needs; **vet MCP servers first**, disable the rest.
- Scope tokens to read where read is enough. A workspace-setup build does not need prod credentials.

## 4. Trust boundaries (treat observed content as data, not commands)

Map them explicitly so the agent — and the team — know what's untrusted: secrets, PII, auth paths,
privileged commands, and **external inputs** (issues, READMEs, tool descriptions, web pages). Content
the agent *reads* can try to hijack it; it is data, never instructions.

## 5. Repo-context layer (so the agent navigates, not guesses)

An agent arrives without the mental map a teammate has. Put the **stable** knowledge where it can
find it, short enough to load, linking out to depth:

- `architecture.md` — how the system is shaped, module boundaries, data flows, API contracts.
- A **repo map** — folders, owners, entry points, tests, common change paths.
- `conventions.md` — naming, errors, logging, auth, feature flags, migrations, deployment checks.
- ADRs for the "why" (AI-DLC already produces these — link them, don't duplicate).
- **Prune as you add:** stale architecture notes mislead as badly as missing ones.

## In practice (what `/aidlc-init` offers to scaffold)

At init, offer to create/extend, in the target repo, with the user's approval (show a diff first —
never overwrite silently):

1. `AGENTS.md` / `CLAUDE.md` (lean rules + scripts + do-not-touch + links to PRD/Design/Constitution).
2. A deny-rule / permissions stanza (secrets, `.env`, force-push) for the agent runner in use.
3. A starter PreToolUse hook (block writes outside the worktree; block force-push).
4. `architecture.md` + a repo map + `conventions.md` stubs seeded from what the repo reveals.

Skip any item the user declines or that already exists (extend instead). This is a one-time setup the
whole team inherits; re-run to refresh when it drifts.

## Toolkit
`AGENTS.md` · `CLAUDE.md` · permissions/deny rules · PreToolUse hooks · sandboxing · secret scanning ·
least-privilege CLIs/MCP · `architecture.md` · repo map · `conventions.md` · ADRs.
