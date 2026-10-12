#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build-kiro.py — generate an AWS Kiro port of the AI-DLC plugin from the
authoritative Claude Code sources (skills/, references/, agents/, .cursor/, hooks/).

Source of truth stays the Claude Code plugin. Re-run this after any plugin change to
regenerate the Kiro distribution, keeping all three surfaces (Claude / Cursor / Kiro)
in sync from one place.

Output tree (under plugins/aidlc/kiro-dist/):
  .kiro/
    skills/aidlc-<cmd>/SKILL.md        <- Kiro Agent Skills (slash commands + auto-activate)
    steering/aidlc-lifecycle-gate.md   <- always-on terminology + phase order + command map
    steering/aidlc-guardrails.md       <- advisory guardrails (draft->approve->publish, EARS, no-secrets)
    aidlc/references/**/*.md           <- shared references (path-rewritten)
    aidlc/agents/*.md                  <- sub-agent playbooks (referenced by skills)
    aidlc/aidlc.config.example.yaml    <- config template
    settings/mcp.json                  <- Atlassian/GitLab MCP template
    hooks/aidlc-secret-scan.json       <- advisory PreToolUse hook (warns, does NOT block)

Design notes
------------
* Kiro Agent Skills use the SAME SKILL.md shape as Claude Code (name + description
  frontmatter). We keep only those two keys (Kiro also allows license/compatibility/
  metadata; Claude-only keys like allowed-tools/argument-hint are dropped).
* Claude placeholders are rewritten to fixed workspace paths the Kiro agent can open:
      ${CLAUDE_PLUGIN_ROOT}/references/  -> .kiro/aidlc/references/
      @plugins/aidlc/references/         -> .kiro/aidlc/references/
      ${CLAUDE_PLUGIN_ROOT}/             -> .kiro/aidlc/
      {{SKILL_DIR}}                      -> .kiro/skills/<skill-name>
  Cross-plugin @plugins/standards/... links are left as-is (they belong to a separate
  plugin) and reported.
* Guardrails are carried as ADVISORY steering (per the chosen scope). Kiro *can* hard-block
  via PreToolUse command hooks; we ship one advisory agent-action hook as a template and
  explain how to promote it to blocking in the README.
"""
import os, re, sys, json, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
PLUGIN = os.path.dirname(HERE)                       # plugins/aidlc
OUT = os.path.join(PLUGIN, "kiro-dist")
KIRO = os.path.join(OUT, ".kiro")

SKILLS_SRC = os.path.join(PLUGIN, "skills")
REFS_SRC   = os.path.join(PLUGIN, "references")
AGENTS_SRC = os.path.join(PLUGIN, "agents")
CURSOR_SRC = os.path.join(PLUGIN, ".cursor", "rules")
CONFIG_SRC = os.path.join(PLUGIN, "aidlc.config.example.yaml")

report = {"skills": 0, "references": 0, "agents": 0, "steering": 0,
          "cross_plugin_links": set(), "warnings": []}


def rewrite_paths(text, skill_name=None):
    """Rewrite Claude Code path placeholders to Kiro workspace paths."""
    # record cross-plugin links before touching anything
    for m in re.findall(r'@plugins/standards/[^\s)`\]]+', text):
        report["cross_plugin_links"].add(m)
    text = text.replace("${CLAUDE_PLUGIN_ROOT}/references/", ".kiro/aidlc/references/")
    text = text.replace("@plugins/aidlc/references/", ".kiro/aidlc/references/")
    text = text.replace("${CLAUDE_PLUGIN_ROOT}/", ".kiro/aidlc/")
    # Drop the Cursor/Claude "@<path>" load-prefix; Kiro reads workspace paths directly.
    text = text.replace("@.kiro/aidlc/", ".kiro/aidlc/")
    # Bare prose mentions ("see references/foo.md") also mean the shared tree. Rewrite
    # them, but only when not already part of a path (negative lookbehind for a path/word
    # char) so an already-qualified .kiro/aidlc/references/ is never double-prefixed.
    # (technical-guidance/* belongs to the separate standards plugin — leave it alone.)
    text = re.sub(r'(?<![\w./-])references/(?!technical-guidance/)', '.kiro/aidlc/references/', text)
    if skill_name:
        text = text.replace("{{SKILL_DIR}}", ".kiro/skills/" + skill_name)
    else:
        text = text.replace("{{SKILL_DIR}}", ".kiro/aidlc")
    return text


def split_frontmatter(text):
    """Return (dict_of_simple_keys, body). Only parses top-level 'key: value' lines."""
    if not text.startswith("---"):
        return {}, text
    end = text.find("\n---", 3)
    if end == -1:
        return {}, text
    fm_block = text[3:end].strip("\n")
    body = text[end + 4:]
    if body.startswith("\n"):
        body = body[1:]
    fm = {}
    for line in fm_block.splitlines():
        m = re.match(r'^([A-Za-z0-9_-]+):\s?(.*)$', line)
        if m:
            fm[m.group(1)] = m.group(2)
    return fm, body


def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


# Skills authored natively for Kiro (self-contained, MCP-first) — do NOT regenerate
# them from the Claude Code source, which would clobber the bespoke Kiro version.
BESPOKE_SKILLS = {"aidlc-sprint"}


def build_skills():
    dst_root = os.path.join(KIRO, "skills")
    for name in sorted(os.listdir(SKILLS_SRC)):
        if name in BESPOKE_SKILLS:
            report["warnings"].append(f"{name}: preserved bespoke Kiro skill (not regenerated)")
            continue
        src = os.path.join(SKILLS_SRC, name, "SKILL.md")
        if not os.path.isfile(src):
            continue
        raw = open(src, encoding="utf-8").read()
        fm, body = split_frontmatter(raw)
        n = fm.get("name", name).strip()
        desc = fm.get("description", "").strip()
        if len(desc) > 1024:
            report["warnings"].append(f"{name}: description >1024 chars ({len(desc)}) — truncated")
            desc = desc[:1021] + "..."
        body = rewrite_paths(body, skill_name=n)
        out = f"---\nname: {n}\ndescription: {desc}\n---\n\n{body.lstrip()}"
        write(os.path.join(dst_root, n, "SKILL.md"), out)
        report["skills"] += 1


def copy_tree_rewritten(src_root, dst_root, kind):
    for dirpath, _dirs, files in os.walk(src_root):
        for fn in files:
            if not fn.endswith(".md"):
                continue
            src = os.path.join(dirpath, fn)
            rel = os.path.relpath(src, src_root)
            raw = open(src, encoding="utf-8").read()
            write(os.path.join(dst_root, rel), rewrite_paths(raw))
            report[kind] += 1


def build_steering():
    dst = os.path.join(KIRO, "steering")

    # 1) Lifecycle gate — always-on. Derived from the Cursor mdc (closest always-on source).
    gate_src = os.path.join(CURSOR_SRC, "aidlc-lifecycle-gate.mdc")
    _fm, body = split_frontmatter(open(gate_src, encoding="utf-8").read())
    body = rewrite_paths(body)
    body = body.replace("Cursor rules layer", "Kiro steering layer") \
               .replace("(Cursor)", "(Kiro)") \
               .replace("mirrors the Claude skills in\n`../../skills/`.",
                        "mirrors the Kiro Agent Skills in `.kiro/skills/`.") \
               .replace("a matching rule in this folder", "a matching skill in `.kiro/skills/`")
    header = ("---\ninclusion: always\n---\n\n"
              "> **Kiro steering — AI-DLC lifecycle gate.** Always loaded. This is the "
              "persistent terminology, phase order, and command map. Each `/aidlc-*` command "
              "is a Kiro Agent Skill under `.kiro/skills/`; type `/` in chat to run one, or "
              "describe the task and Kiro auto-activates the matching skill.\n\n")
    write(os.path.join(dst, "aidlc-lifecycle-gate.md"), header + body.lstrip())
    report["steering"] += 1

    # 2) Guardrails — advisory. Derived from references/guardrails.md, reframed for Kiro.
    graw = open(os.path.join(REFS_SRC, "guardrails.md"), encoding="utf-8").read()
    graw = rewrite_paths(graw)
    advisory = (
        "---\ninclusion: always\n---\n\n"
        "# AI-DLC Guardrails (advisory in Kiro)\n\n"
        "> **How these apply in Kiro.** In the Claude Code plugin these guardrails run as "
        "`PreToolUse` command hooks that can *block* a tool call. This Kiro port carries them "
        "as **advisory steering**: Kiro should treat every item below as a hard rule and refuse "
        "to proceed when one would be violated, but there is no automatic block unless you add a "
        "blocking hook. Kiro *does* support blocking via `PreToolUse` command hooks "
        "(`.kiro/hooks/*.json`, action `type: command` that denies) — see the port README to "
        "promote any rule to enforced. The advisory rules are:\n\n"
        "## Load-bearing rules Kiro must self-enforce\n\n"
        "1. **draft → approve → publish.** Never write to a shared system (Jira, Confluence, "
        "GitLab, Linear) until the human has explicitly approved *that specific* artifact. State "
        "what will be written and to where, then wait for a clear yes.\n"
        "2. **No secrets in artifacts.** Never put tokens, passwords, API keys, or credentials "
        "into any doc, ticket, commit, or page.\n"
        "3. **EARS acceptance criteria.** Acceptance criteria use EARS phrasing "
        "(WHEN/IF/WHILE … THE SYSTEM SHALL …); flag vague, untestable criteria.\n"
        "4. **Risk-based governance.** HIGH-risk changes require specialist review + an ADR; a "
        "readiness/confidence score never overrides a failed mandatory security/compliance gate.\n"
        "5. **Verify before done.** Do not declare work complete until tests were actually "
        "executed and passed — an unexecuted test is NOT RUN, never a pass.\n\n"
        "---\n\n"
        "## Reference: the original enforced-hook design (for context)\n\n"
        + graw
    )
    write(os.path.join(dst, "aidlc-guardrails.md"), advisory)
    report["steering"] += 1


def build_mcp():
    mcp = {
        "mcpServers": {
            "atlassian": {
                "command": "npx",
                "args": ["-y", "mcp-remote", "https://mcp.atlassian.com/v1/sse"],
                "env": {},
                "disabled": False,
                "autoApprove": []
            },
            "gitlab": {
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-gitlab"],
                "env": {
                    "GITLAB_PERSONAL_ACCESS_TOKEN": "${GITLAB_TOKEN}",
                    "GITLAB_API_URL": "https://gitlab.com/api/v4"
                },
                "disabled": True,
                "autoApprove": []
            }
        }
    }
    write(os.path.join(KIRO, "settings", "mcp.json"), json.dumps(mcp, indent=2) + "\n")


def build_hooks():
    hook = {
        "version": "v1",
        "hooks": [
            {
                "name": "AI-DLC secret scan (advisory)",
                "description": ("Advisory guardrail: before a write/publish tool runs, remind "
                                "Kiro to confirm no secrets/credentials are in the payload and "
                                "that the human approved THIS artifact. Injects a prompt; does "
                                "not block. To make it blocking, change action.type to 'command' "
                                "and exit non-zero on a violation."),
                "trigger": "PreToolUse",
                "matcher": "*",
                "action": {
                    "type": "agent",
                    "prompt": ("AI-DLC guardrail check before this action: (1) Confirm the "
                               "payload contains no tokens, passwords, API keys, or credentials. "
                               "(2) Confirm the human explicitly approved writing THIS specific "
                               "artifact to THIS destination (draft -> approve -> publish). If "
                               "either is not satisfied, stop and ask the human before "
                               "proceeding.")
                },
                "enabled": True
            }
        ]
    }
    write(os.path.join(KIRO, "hooks", "aidlc-secret-scan.json"), json.dumps(hook, indent=2) + "\n")


def main():
    # Targeted clean: remove only the auto-generated parts, never the bespoke Kiro
    # skills (which are not regenerated from the Claude source). Best-effort — some
    # mounted filesystems deny rmtree's fd-based unlink; write() then overwrites in
    # place, which is safe because filenames are stable.
    def _rm(p):
        try:
            if os.path.isdir(p):
                shutil.rmtree(p)
            elif os.path.isfile(p):
                os.remove(p)
        except (PermissionError, OSError) as e:
            print(f"  note: could not clean {p} ({e}); overwriting in place")

    _rm(os.path.join(KIRO, "aidlc"))
    _rm(os.path.join(KIRO, "steering"))
    _rm(os.path.join(KIRO, "settings"))
    _rm(os.path.join(KIRO, "hooks"))
    skills_dir = os.path.join(KIRO, "skills")
    if os.path.isdir(skills_dir):
        for name in os.listdir(skills_dir):
            if name not in BESPOKE_SKILLS:
                _rm(os.path.join(skills_dir, name))
    build_skills()
    copy_tree_rewritten(REFS_SRC, os.path.join(KIRO, "aidlc", "references"), "references")
    copy_tree_rewritten(AGENTS_SRC, os.path.join(KIRO, "aidlc", "agents"), "agents")
    if os.path.isfile(CONFIG_SRC):
        shutil.copyfile(CONFIG_SRC, os.path.join(KIRO, "aidlc", "aidlc.config.example.yaml"))
    build_steering()
    build_mcp()
    build_hooks()

    print("Kiro port generated at:", OUT)
    print(f"  skills:     {report['skills']}")
    print(f"  references: {report['references']}")
    print(f"  agents:     {report['agents']}")
    print(f"  steering:   {report['steering']}")
    if report["cross_plugin_links"]:
        print(f"  cross-plugin links left as-is: {len(report['cross_plugin_links'])}")
        for l in sorted(report["cross_plugin_links"]):
            print("    -", l)
    for w in report["warnings"]:
        print("  WARN:", w)


if __name__ == "__main__":
    main()
