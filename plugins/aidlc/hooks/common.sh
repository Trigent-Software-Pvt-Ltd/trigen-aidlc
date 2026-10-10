#!/usr/bin/env bash
# Shared helpers for AI-DLC guardrail hooks. Sourced by each hook script.
# Never hard-fails the tool on its own bugs: unless a guardrail intentionally
# denies, scripts exit 0 (allow).

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
[ -f "$ROOT/hooks/guardrails.defaults.env" ] && . "$ROOT/hooks/guardrails.defaults.env"
PROJECT_ENV="${CLAUDE_PROJECT_DIR:-.}/.aidlc/guardrails.env"
[ -f "$PROJECT_ENV" ] && . "$PROJECT_ENV"

STATE_DIR="${CLAUDE_PROJECT_DIR:-$PWD}/.aidlc/guardrails"
mkdir -p "$STATE_DIR" 2>/dev/null || true

# Hooks read the tool-call JSON on stdin. Non-hook callers (e.g. propose.sh) set
# AIDLC_SKIP_STDIN=1 so sourcing this file does not block on / swallow their stdin.
if [ -z "${AIDLC_SKIP_STDIN:-}" ]; then INPUT="$(cat)"; else INPUT="${AIDLC_INPUT:-}"; fi
jqget() { printf '%s' "$INPUT" | jq -r "$1" 2>/dev/null; }
# input_is_json: 0 when INPUT parses as JSON; used to fail closed on malformed
# input under enforced governance for protected gates.
input_is_json() { printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1; }
SESSION_ID="$(jqget '.session_id // "nosession"')"
TOOL_NAME="$(jqget '.tool_name // ""')"

allow() { exit 0; }
warn()  { printf 'aidlc-guardrails: %s\n' "$1" >&2; }
deny()  { jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'; exit 0; }

# ---- Release A: governance mode + action-bound approvals (ENH-001/002) ----
# GOVERNANCE_MODE: advisory (report, per-gate modes apply) | enforced (protected
# gates forced to block; cannot be silently downgraded). Enforced implies binding.
GOVERNANCE_MODE="${GOVERNANCE_MODE:-advisory}"
if [ "$GOVERNANCE_MODE" = "enforced" ]; then APPROVAL_BINDING=true; fi
APPROVAL_BINDING="${APPROVAL_BINDING:-false}"

APPROVAL_JSON="$STATE_DIR/approval-$SESSION_ID.json"
# Pending manifest is session-agnostic: propose.sh (a Bash call) cannot see the
# hook's session_id, so both sides share one file under the project state dir.
PENDING_JSON="$STATE_DIR/pending.json"
LEGACY_TOKEN="$STATE_DIR/approval-$SESSION_ID.token"

# effective_mode <configured_mode> <protected:yes|no> -> prints the mode to apply.
# A protected gate is forced to "block" under enforced governance (no downgrade).
effective_mode() {
  if [ "$GOVERNANCE_MODE" = "enforced" ] && [ "${2:-no}" = "yes" ]; then printf 'block'; return; fi
  printf '%s' "$1"
}

# protected_active -> 0 if a protected gate must run. GUARDRAILS_ENABLED=false
# disables gates ONLY in advisory governance; enforced keeps protected gates on.
protected_active() {
  [ "$GOVERNANCE_MODE" = "enforced" ] && return 0
  [ "${GUARDRAILS_ENABLED:-true}" = "true" ]
}

# sha256 <stdin> -> hex digest; degrades gracefully if no sha tool is present.
sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}';
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print $1}';
  elif command -v openssl >/dev/null 2>&1; then openssl dgst -sha256 2>/dev/null | awk '{print $NF}';
  else cksum | awk '{print "cksum-"$1"-"$2}'; fi
}

# bash_backend / bash_target: best-effort classification of a tracker write
# tunnelled through Bash (glab / jira / acli).
bash_backend() {
  local c; c="$(jqget '.tool_input.command // ""')"
  case "$c" in
    *glab*) printf 'gitlab' ;;
    *"jira workitem"*) printf 'jira' ;;
    *"acli confluence"*|*addPage*|*storePage*) printf 'confluence' ;;
    *) printf 'shell' ;;
  esac
}
bash_target() { printf '%s' "$(jqget '.tool_input.command // ""')" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1; }

# op_descriptor -> "BACKEND<TAB>TARGET<TAB>DIGEST" for the current tool INPUT.
op_descriptor() {
  local backend='' target='' payload=''
  case "$TOOL_NAME" in
    createJiraIssue)
      backend=jira
      target="$(jqget '.tool_input.projectKey // ""'):$(jqget '.tool_input.issueTypeName // ""'):$(jqget '.tool_input.summary // ""')"
      payload="$(jqget '.tool_input.summary // ""')|$(jqget '.tool_input.description // ""')" ;;
    editJiraIssue|transitionJiraIssue|addCommentToJiraIssue|createIssueLink)
      backend=jira
      target="$(jqget '.tool_input.issueIdOrKey // .tool_input.inwardIssue // ""')"
      payload="$(printf '%s' "$INPUT" | jq -c '.tool_input // {}' 2>/dev/null)" ;;
    createConfluencePage|updateConfluencePage|createConfluenceFooterComment|createConfluenceInlineComment|deleteConfluencePage)
      backend=confluence
      target="$(jqget '.tool_input.pageId // .tool_input.title // ""')"
      payload="$(jqget '.tool_input.body // ""')" ;;
    Bash)
      backend="$(bash_backend)"; target="$(bash_target)"
      payload="$(jqget '.tool_input.command // ""')" ;;
    *)
      backend=other; target="$TOOL_NAME"
      payload="$(printf '%s' "$INPUT" | jq -c '.tool_input // {}' 2>/dev/null)" ;;
  esac
  printf '%s\t%s\t%s' "$backend" "$target" "$(printf '%s' "$payload" | sha256)"
}
