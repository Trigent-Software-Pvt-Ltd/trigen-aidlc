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
| HP-1 | `UserPromptSubmit` | **Approval capture** — records a short-lived token when the user says an explicit go-word | on |
| HP-2 | `PreToolUse` (tracker writes + `glab`/`acli`/`jira` via Bash) | **Publish gate** — blocks the write unless a fresh approval token exists | **block** |
| HP-3 | `PreToolUse` (Confluence AC-catalogue publish) | **EARS validation** — flags acceptance-criteria lines that lack an EARS keyword | warn |
| HP-4 | `PreToolUse` (write tools + Bash + Write/Edit) | **Secret scan** — blocks tool args containing a credential pattern | block |
| HP-5 | `PreToolUse` (`createJiraIssue` leaves) | **Transfer sentinel** — flags a leaf missing labels / estimate / AC reference | off |
| HP-6 | `SessionStart` | **Status banner** — injects a one-line note that guardrails are active | on |

## How the publish gate works

Hooks are stateless, so approval is a token file at
`<project>/.aidlc/guardrails/approval-<session>.token` holding an epoch timestamp.

1. **HP-1** inspects each user message. **Strong** go-phrases (`go ahead`, `approved`, `publish it`,
   `create the tickets`, `proceed with the transfer`, a leading `yes/ok`) approve at any length;
   **weak** imperatives (`publish`, `create`, `transfer`, `proceed`, `go`, `do it`) approve only in
   a short message (≤ 10 words), so long prose that merely contains "create" does **not** silently
   unlock a write.
2. **HP-2** fires before a tracker write. If a token exists and is younger than
   `PUBLISH_GATE_TTL` (default 600s — long enough to cover a batch like a 5-story transfer), the
   write proceeds; otherwise it is **denied** with a message telling the agent to show the draft and
   get an explicit go. Set `PUBLISH_GATE_SINGLE_USE=true` to consume the token on the first write.

The gate fails **closed**: when in doubt it blocks, which is the safe direction.

## Configuration

Shipped defaults live in `hooks/guardrails.defaults.env`. To override per project, create
`<project>/.aidlc/guardrails.env` with the same keys (this is the env form of the `guardrails:`
block in `aidlc.config.yaml`; `/aidlc-init` can generate it). Every guardrail takes
`block` / `warn` / `off`.

```
GUARDRAILS_ENABLED=true
PUBLISH_GATE_MODE=block     PUBLISH_GATE_TTL=600    PUBLISH_GATE_SINGLE_USE=false
PUBLISH_GATE_INCLUDE_BASH=true
EARS_MODE=warn
SECRET_SCAN_MODE=block
SENTINEL_ENABLED=false      SENTINEL_MODE=warn
```

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

## Testing a change

```
export CLAUDE_PLUGIN_ROOT=plugins/aidlc CLAUDE_PROJECT_DIR=/tmp/t
echo '{"session_id":"s","tool_name":"mcp__x__createJiraIssue","tool_input":{}}' | bash plugins/aidlc/hooks/publish-gate.sh   # -> deny
echo '{"session_id":"s","prompt":"create"}' | bash plugins/aidlc/hooks/approval-capture.sh                                    # -> writes token
```
