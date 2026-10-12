# AI-DLC for AWS Kiro

This is the **Kiro port** of the AI-DLC plugin — the same Feature → Epic → Story → Task
lifecycle (Intent → Elaborate → Design → Verify → Sprint → Review), re-targeted onto Kiro's
native mechanisms. It is **generated** from the authoritative Claude Code plugin by
`../tools/build-kiro.py`; don't hand-edit files here — change the plugin and regenerate.

## Primary skill: `/aidlc-sprint` — Jira ticket → working code

`aidlc-sprint` is **authored natively for Kiro** (self-contained, MCP-first) rather than
mechanically converted. Point Kiro at a ticket — `work on PROJ-123` or `/aidlc-sprint PROJ-123`
— and it:

1. **Fetches the issue over the Atlassian MCP** (summary, description, acceptance criteria, child
   tasks, and any `## Test Scope` comment) — no `acli` needed.
2. Gathers codebase context and drafts a short **test-first plan**, then waits for your approval.
3. Creates a `feature/<KEY>-<slug>` branch and runs the **red → green → refactor** loop, capturing the
   failing and passing evidence for each acceptance criterion.
4. Runs a **verification gate** — nothing is "done" without executed, passing tests.
5. Opens a **PR with the evidence pack** and moves the ticket's status over MCP.

It's self-contained in `.kiro/skills/aidlc-sprint/` (SKILL.md + its own `references/`), so it works
even if you don't install the rest of the tree. It only needs the **Atlassian MCP** configured in
`.kiro/settings/mcp.json` and a known test command. Because it's bespoke, `build-kiro.py` **preserves**
it on regeneration (it is not overwritten from the Claude Code source).

## What maps to what

| AI-DLC concept (Claude Code)                 | Kiro mechanism                                   |
| -------------------------------------------- | ------------------------------------------------ |
| `skills/aidlc-*/SKILL.md` slash commands     | **Agent Skills** `.kiro/skills/aidlc-*/SKILL.md` (same format; appear as `/aidlc-*` and auto-activate on description match) |
| `.cursor/rules/aidlc-lifecycle-gate.mdc`     | **Steering** `.kiro/steering/aidlc-lifecycle-gate.md` (`inclusion: always`) |
| `hooks/` guardrails (PreToolUse deny)        | **Steering** `.kiro/steering/aidlc-guardrails.md` (advisory) + optional blocking hook |
| `references/**`                              | `.kiro/aidlc/references/**` (shared; skills open by path) |
| `agents/*.md` sub-agents                     | `.kiro/aidlc/agents/*.md` playbooks (referenced by skills; promotable to Kiro custom agents) |
| Jira / Confluence / GitLab backends          | **MCP** `.kiro/settings/mcp.json`                |
| `aidlc.config.example.yaml`                  | `.kiro/aidlc/aidlc.config.example.yaml`          |

## Install into a Kiro workspace

```bash
# from your project root (the repo you'll run Kiro in)
cp -r /path/to/plugins/aidlc/kiro-dist/.kiro  ./.kiro
# or merge into an existing .kiro/ you already have:
#   cp -r kiro-dist/.kiro/skills/*   .kiro/skills/
#   cp -r kiro-dist/.kiro/steering/* .kiro/steering/
#   cp -r kiro-dist/.kiro/aidlc      .kiro/
#   cp    kiro-dist/.kiro/settings/mcp.json .kiro/settings/mcp.json
#   cp    kiro-dist/.kiro/hooks/*     .kiro/hooks/
```

Then in Kiro:

1. **Reload** so steering, skills, and hooks are picked up.
2. Type `/` in chat — you'll see `/aidlc-init`, `/aidlc-intent`, … as slash commands.
   (You can also just describe the task; Kiro auto-activates the matching skill.)
3. Run `/aidlc-init` first to generate `aidlc.config.yaml` from the template.
4. Fill in `.kiro/settings/mcp.json` with your Atlassian / GitLab details (see below).

## MCP backends

`.kiro/settings/mcp.json` ships templates for **Atlassian** (Jira + Confluence) and
**GitLab**. Atlassian is enabled by default via the hosted remote MCP; GitLab is `disabled:
true` until you set `GITLAB_TOKEN`. Edit to match your org, remove servers you don't use, and
confirm the exact server package/URL against current Kiro + provider docs — MCP server names
and transports change. If a backend has no MCP server available, that backend's skills will
fall back to describing the writes for you to do by hand (the draft → approve → publish gate
still applies).

## Guardrails: advisory by default

The guardrail rules (**draft → approve → publish**, no secrets in artifacts, EARS acceptance
criteria, risk-based governance, verify-before-done) are carried as **always-on advisory
steering** in `.kiro/steering/aidlc-guardrails.md`. Kiro is instructed to self-enforce them
and stop for human approval — but nothing hard-blocks a tool call in this configuration.

Kiro **can** hard-block. To promote a rule to enforced, turn the advisory hook in
`.kiro/hooks/aidlc-secret-scan.json` into a blocking **command** hook:

```jsonc
{
  "version": "v1",
  "hooks": [{
    "name": "AI-DLC publish gate (enforced)",
    "trigger": "PreToolUse",
    "matcher": "@mcp",                      // or a specific tool id / category
    "action": { "type": "command", "command": ".kiro/aidlc/hooks/publish-gate.sh" },
    "timeout": 30
  }]
}
```

A `PreToolUse` command hook that exits non-zero **blocks** the tool call — the same effect as
the Claude Code `publish-gate`. The original enforced bash hooks live in the Claude Code
plugin under `plugins/aidlc/hooks/` if you want to port their logic across.

## Sub-agents

The nine AI-DLC sub-agents (task-creator, doc-quality-reviewer, sprint-plan-critic, …) are
shipped as playbooks under `.kiro/aidlc/agents/`. The skills reference them by name and will
follow the matching playbook inline. To run them as *real* isolated Kiro sub-agents, create
[custom agents](https://kiro.dev/docs/custom-agents/) whose `resources` include
`file://.kiro/aidlc/agents/<name>.md` and the steering glob.

## Keeping in sync

This whole tree is regenerated from the Claude Code plugin:

```bash
python3 plugins/aidlc/tools/build-kiro.py     # regenerate .kiro dist
bash    plugins/aidlc/tools/verify-kiro.sh     # integrity suite (frontmatter/refs/JSON)
```

So Claude, Cursor, and Kiro all stay driven by one source of truth: the plugin's
`skills/`, `references/`, `agents/`, and `.cursor/`.

## Known gaps vs the Claude Code plugin

- **Hard enforcement is opt-in**, not default (see Guardrails above).
- **Cross-plugin links**: a few `aidlc-design` / `aidlc-progress` references point at the
  separate `standards` plugin (`@plugins/standards/references/technical-guidance/*`). Those
  are left as-is; install the standards content separately if you rely on those profiles.
- **Sub-agents** run inline as playbooks unless you wire them as Kiro custom agents.
