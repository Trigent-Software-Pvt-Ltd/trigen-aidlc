# AI-DLC — Cursor rules layer

This folder makes the AI-DLC plugin usable in **Cursor**, alongside the Claude skills in
`../skills/`. Cursor reads rule files (`.mdc`) from a workspace's `.cursor/rules/` folder;
it does not read Claude `SKILL.md` files or `plugin.json`.

## What's here

- `rules/aidlc-lifecycle-gate.mdc` — always-on rule with terminology, command list, and phase order.
- `rules/aidlc-<command>.mdc` — one rule per command, mirroring the matching `skills/<command>/SKILL.md`.

Each command rule points to its authoritative `SKILL.md` and carries a concise workflow summary,
so Claude and Cursor stay in sync from a single source.

## Install in a project

Copy the rules into your project's Cursor rules folder:

```bash
# from your project root
mkdir -p .cursor/rules
cp -r /path/to/plugins/aidlc/.cursor/rules/* .cursor/rules/
# copy the shared references so the deeper standards resolve
# (e.g. references/intent-doc-standard.md, references/intent-validation-workflow.md)
mkdir -p references
cp -r /path/to/plugins/aidlc/references/* references/
# also copy the config template
cp /path/to/plugins/aidlc/aidlc.config.example.yaml ./aidlc.config.example.yaml
```

Then reload Cursor. The lifecycle gate applies automatically; invoke a command rule by
referencing it (e.g. "run aidlc-intent") or by attaching the rule in Cursor's UI.

> **Note:** The `.mdc` rule summaries are self-contained, so Cursor works even without the
> `references/` folder. Copying `references/` gives Cursor users the full standards
> (e.g. the §0–§9 source-derived Intent standard and validation workflow) that the summaries
> point to. If you skip it, the paths in the rules simply won't resolve — the workflow still
> runs from the summary.

## Configuration

Run the init flow first (in Cursor, reference `aidlc-init`) to generate `aidlc.config.yaml`.
All organisation-specific values are read from that file — nothing is hardcoded.

## Keeping in sync

The `.mdc` rules intentionally reference `skills/<command>/SKILL.md` as the source of truth.
When you change a skill, update the corresponding rule's summary if the high-level steps change.
