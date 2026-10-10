# Guardrails (enforced hooks)

> **Why this exists.** AI-DLC's discipline — *draft → approve → publish*, EARS acceptance
> criteria, no secrets in artifacts — has until now lived as prose the agent is *trusted* to
> follow. This layer makes the load-bearing parts **enforced code**: `hooks.json` command hooks
> that gate tool calls, so a rule violation is blocked, not merely discouraged. It is the
> plugin-owned equivalent of the "mods/Sentinel" pattern (an action supervisor that reviews every
> outbound action before it lands).

Hooks live in `plugins/aidlc/hooks/` and are auto-discovered from `hooks/hooks.json`. Each hook is
a small, dependency-light bash script (needs only `bash` + `jq`). A hook **never hard-fails a tool
on its own bug** — unless a guardrail intentionally denies, it exits 0 (allow).

## The hook points

| ID | Event | Guardrail | Default |
|----|-------|-----------|---------|
| HP-1 | `UserPromptSubmit` | **Approval capture** — records an approval on an explicit go-word; under binding it also binds to the pending operation / prompt hints | on |
| HP-2 | `PreToolUse` (tracker writes + `glab`/`acli`/`jira` via Bash) | **Publish gate** — blocks the write unless a valid approval exists; action-bound under `enforced` | **block** |
| HP-3 | `PreToolUse` (Confluence AC-catalogue publish) | **EARS validation** — flags acceptance-criteria lines that lack an EARS keyword | warn |
| HP-4 | `PreToolUse` (write tools + Bash + Write/Edit) | **Secret scan** — blocks tool args containing a credential pattern | block |
| HP-5 | `PreToolUse` (`createJiraIssue` leaves) | **Transfer sentinel** — flags a leaf missing labels / estimate / AC reference | off |
| HP-6 | `SessionStart` | **Status banner** — injects a one-line note that guardrails are active | on |

## Governance mode (ENH-002)

`GOVERNANCE_MODE` sets how strongly gates apply:

- **`advisory`** (default) — per-gate modes (`block`/`warn`/`off`) apply as configured, and
  `GUARDRAILS_ENABLED=false` disables gates. Use this to evaluate without blocking teams.
- **`enforced`** — the **protected** gates (the publish gate and the secret scan) are forced to
  **block** and **cannot be silently downgraded** by a per-gate `off`/`warn` or by
  `GUARDRAILS_ENABLED=false`; and approvals become **action-bound** (`APPROVAL_BINDING` is forced
  true). Advisory-only gates (EARS, sentinel) still honour their own mode.

This is the "a readiness score can't override a failed mandatory gate" guarantee in config form: an
enforced protected gate is not downgradable.

## How the publish gate works

Hooks are stateless, so approval state lives under `<project>/.aidlc/guardrails/`.

1. **HP-1 (approval capture).** Inspects each user message. **Strong** go-phrases (`go ahead`,
   `approved`, `publish it`, `create the tickets`, `proceed with the transfer`, a leading `yes/ok`)
   approve at any length; **weak** imperatives approve only in a short message (≤ 10 words), so long
   prose that merely contains "create" does **not** silently unlock a write.
2. **HP-2 (publish gate).** Fires before a tracker write and behaves per mode:

   - **Legacy / advisory (`APPROVAL_BINDING=false`, default):** a timestamp token
     (`approval-<session>.token`) younger than `PUBLISH_GATE_TTL` (default 600s) unlocks the write;
     `PUBLISH_GATE_SINGLE_USE=true` consumes it. Unchanged from previous releases.
   - **Action-bound (`APPROVAL_BINDING=true`, always under `enforced`):** the approval
     (`approval-<session>.json`) must **match this operation**. When the skill recorded a manifest
     via `hooks/propose.sh`, the match is exact on **backend + target + payload digest**. Otherwise
     the approval carries **target/backend hints** parsed from the prompt (e.g. `QI-137`, `jira`) and
     the write's target/backend must match them. A bare "yes" with no hints authorises exactly **one**
     write. Approvals are **single-use** (consumed on use) and **expire** (`PUBLISH_GATE_TTL`).
     Mismatch / expired / reused / missing → **fail closed** (deny).

So, under `enforced`: approving one Jira story cannot authorise another, a Confluence approval cannot
authorise a GitLab write, and a reused or stale approval is rejected.

**Enforced mode is strict by design:**
- A **manifest is mandatory** — a bare "yes" or a prompt-hint-only approval does **not** authorise any
  write; the skill must record the exact operation (via `propose.sh`) and the write must match its
  payload digest. (The lenient hint/bare tier exists only when `approvalBinding:true` is set under
  *advisory* governance.)
- **Malformed / unparseable input** to a protected gate (publish gate, secret scan) **fails closed**
  (deny) — a write is never let through just because its call could not be classified. Valid read-only
  tool calls are unaffected.
- **Extended Bash coverage** — beyond the plugin's own CLI write forms, enforced also gates
  `glab api`, `gh` writes, `git push`, and `curl`/`wget` mutating HTTP (POST/PUT/PATCH/DELETE or a
  data body) to a tracker host, so alternative command forms can't bypass the gate. Advisory keeps the
  narrower base set for backward-compatibility.

### Binding a write (for skill authors)

Right before showing a drafted change and asking "publish?", record the pending operation so the
approval can be bound to it exactly:

```
printf '%s' "$BODY" | bash "${CLAUDE_PLUGIN_ROOT}/hooks/propose.sh" \
  --op createConfluencePage --backend confluence --target "Workspace Setup — PRD"
```

This is optional: without it, a bare approval still works but is single-use only.

## Configuration

Shipped defaults live in `hooks/guardrails.defaults.env`. To override per project, create
`<project>/.aidlc/guardrails.env` with the same keys (the env form of the `guardrails:` block in
`aidlc.config.yaml`; `/aidlc-init` can generate it).

```
GUARDRAILS_ENABLED=true
GOVERNANCE_MODE=advisory        # advisory | enforced
APPROVAL_BINDING=false          # forced true under enforced
PUBLISH_GATE_MODE=block     PUBLISH_GATE_TTL=600    PUBLISH_GATE_SINGLE_USE=false
PUBLISH_GATE_INCLUDE_BASH=true
EARS_MODE=warn
SECRET_SCAN_MODE=block
SENTINEL_ENABLED=false      SENTINEL_MODE=warn
```

**Migration:** both new keys default to the previous behaviour (`advisory` + binding off), so existing
projects are unchanged. To adopt the hardened model, set `governanceMode: enforced` in
`aidlc.config.yaml` (or `GOVERNANCE_MODE=enforced` in `.aidlc/guardrails.env`) and re-run
`/aidlc-init`. No repo churn: `.aidlc/` is git-ignored state.

## Known limitations (deliberate, documented)

- **Heuristic matchers.** Which tools count as "writes", and which Confluence page is "the AC
  catalogue", are pattern matches — a renamed tool or page slips through until the pattern is
  updated. Tool matcher is in `hooks.json`; the AC-page test is `title/body contains "Acceptance
  Criteria" or an `AC-xxx-nn` id`.
- **Approval is phrase-based** (HP-1). A creatively-worded approval may not register — in which case
  the gate blocks and the agent re-asks (fails closed).
- **Block, not scrub.** Classic command hooks can reject a tool call but cannot rewrite its
  arguments, so HP-4 **blocks** on a secret rather than redacting it in place. True in-place
  redaction needs the TypeScript *mods* surface; when that is adopted these same checks port over
  and can scrub instead of block.
- **Bash-tunnelled writes** (`glab`, `acli`) are matched by sniffing the command string, which is
  weaker than typed-tool matching.

## Testing

A full automated suite lives at `plugins/aidlc/tests/run.sh` (pure bash, no live writes). It covers
the legacy and action-bound publish paths, the enforced no-downgrade guarantee, secret-scan
protection, malformed-input robustness, and approval binding/replay:

```
bash plugins/aidlc/tests/run.sh      # 24 cases; exits non-zero on any failure
```

Ad-hoc check of one hook:

```
export CLAUDE_PLUGIN_ROOT=plugins/aidlc CLAUDE_PROJECT_DIR=/tmp/t
echo '{"session_id":"s","tool_name":"createJiraIssue","tool_input":{}}' | bash plugins/aidlc/hooks/publish-gate.sh   # -> deny
echo '{"session_id":"s","prompt":"go ahead"}' | bash plugins/aidlc/hooks/approval-capture.sh                          # -> writes approval
```
