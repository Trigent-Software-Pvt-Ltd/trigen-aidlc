#!/usr/bin/env bash
# Publish gate on tracker writes. Requires an explicit user approval before a
# write reaches Jira / Confluence / GitLab (direct tool or tunnelled via Bash).
#
# Two modes of operation:
#   APPROVAL_BINDING=false (default, advisory governance) — LEGACY behaviour:
#     any non-expired approval token unlocks the write (time-boxed).
#   APPROVAL_BINDING=true (always under enforced governance) — ACTION-BOUND:
#     the approval must match THIS operation (backend + target + payload digest
#     when a manifest was recorded; backend/target hints otherwise), is single-use,
#     expires, and is consumed on use. Mismatch/expired/absent fails closed.
. "${CLAUDE_PLUGIN_ROOT}/hooks/common.sh"
protected_active || allow
MODE="$(effective_mode "${PUBLISH_GATE_MODE:-block}" yes)"   # publish is a protected gate
[ "$MODE" = "off" ] && allow

# ENH-003 fix #2: fail CLOSED on unparseable input under enforced governance — a
# protected write must not slip through just because its call could not be classified.
# Advisory keeps the previous non-blocking behaviour (safe for unrelated reads).
if ! input_is_json; then
  [ "$GOVERNANCE_MODE" = "enforced" ] && deny "AI-DLC publish gate: tool input could not be parsed under enforced governance — refusing a protected write. Fix the call and retry."
  allow
fi

# Only gate recognised tracker WRITES.
if [ "$TOOL_NAME" = "Bash" ]; then
  [ "${PUBLISH_GATE_INCLUDE_BASH:-true}" = "true" ] || allow
  CMD="$(jqget '.tool_input.command // ""')"
  # Base set (always gated): the CLI write forms this plugin emits.
  BASE='glab[[:space:]]+mr[[:space:]]+(create|merge|update|close|note|approve|revoke)|jira[[:space:]]+workitem[[:space:]]+(create|update|edit|delete|link|transition|assign|comment)|acli[[:space:]]+confluence[[:space:]].*(addPage|storePage)|--action[[:space:]]+(addPage|storePage)'
  # ENH-003 fix #3: extended set applied under ENFORCED only (keeps advisory compat)
  # so alternative command forms / other write-capable tools cannot bypass the gate:
  #   glab api/issue, gh writes, acli jira writes, git push, and curl/wget mutating
  #   HTTP (POST/PUT/PATCH/DELETE or a data body) to a tracker host.
  EXT='glab[[:space:]]+(api|issue)|gh[[:space:]]+(pr|issue|api|release|repo)[[:space:]]+(create|edit|merge|comment|close|delete|ready|review)|acli[[:space:]]+jira[[:space:]].*(create|update|edit|transition|comment|delete|link|assign)|git[[:space:]]+push|(curl|wget|http|https)[^|;&]*(-X[[:space:]]*|--request[[:space:]]*|--method=)?(POST|PUT|PATCH|DELETE)|(curl|wget)[^|;&]*(atlassian\.net|/rest/api/|gitlab|github\.com)[^|;&]*(-d[[:space:]]|--data)'
  PAT="$BASE"
  [ "$GOVERNANCE_MODE" = "enforced" ] && PAT="$BASE|$EXT"
  printf '%s' "$CMD" | grep -Eq "$PAT" || allow
else
  printf '%s' "$TOOL_NAME" | grep -Eq 'createJiraIssue|editJiraIssue|createConfluencePage|updateConfluencePage|createIssueLink|transitionJiraIssue|addCommentToJiraIssue|deleteConfluencePage|createConfluenceFooterComment|createConfluenceInlineComment' || allow
fi

NOW=$(date +%s)

# fail <reason>: deny under block, warn+allow under warn.
fail() {
  local m="AI-DLC publish gate: $1. Show the drafted change in chat and get an explicit, matching user approval, then retry. Running a phase is not consent to write."
  if [ "$MODE" = "warn" ]; then warn "$m"; allow; fi
  deny "$m"
}

# ---------- LEGACY path (binding off) : unchanged time-boxed behaviour ----------
if [ "${APPROVAL_BINDING}" != "true" ]; then
  if [ -f "$LEGACY_TOKEN" ]; then
    TS="$(head -1 "$LEGACY_TOKEN" 2>/dev/null)"; TS="${TS:-0}"
    if [ "$(( NOW - TS ))" -le "${PUBLISH_GATE_TTL:-600}" ]; then
      [ "${PUBLISH_GATE_SINGLE_USE:-false}" = "true" ] && rm -f "$LEGACY_TOKEN"
      allow
    fi
  fi
  fail "writing to the tracker ($TOOL_NAME) needs an explicit user go first"
fi

# ---------- ACTION-BOUND path (binding on) ----------
[ -f "$APPROVAL_JSON" ] || fail "no approval on record for this write ($TOOL_NAME)"

ATS="$(jq -r '.ts // 0' "$APPROVAL_JSON" 2>/dev/null)"; ATS="${ATS:-0}"
[ "$(jq -r '.consumed // false' "$APPROVAL_JSON" 2>/dev/null)" = "false" ] || fail "that approval was already used (single-use)"
[ "$(( NOW - ATS ))" -le "${PUBLISH_GATE_TTL:-600}" ] || fail "the approval has expired"

DESC="$(op_descriptor)"
BK="$(printf '%s' "$DESC" | cut -f1)"
TGT="$(printf '%s' "$DESC" | cut -f2)"
DIG="$(printf '%s' "$DESC" | cut -f3)"

ABK="$(jq -r '.backend // ""' "$APPROVAL_JSON" 2>/dev/null)"
ATGT="$(jq -r '.target // ""' "$APPROVAL_JSON" 2>/dev/null)"
ADIG="$(jq -r '.digest // ""' "$APPROVAL_JSON" 2>/dev/null)"

# ENH-003 fix #1: under ENFORCED, an approval MUST be manifest-bound (carry a
# payload digest). A generic "yes" with no pending manifest cannot authorise a write.
if [ "$GOVERNANCE_MODE" = "enforced" ] && [ -z "$ADIG" ]; then
  fail "enforced mode requires a manifest-bound approval for this write — record the exact operation first (hooks/propose.sh: op + backend + target + payload), then approve. A generic 'yes' cannot authorise an unspecified write"
fi

OK=0
if [ -n "$ADIG" ]; then
  # Manifest-bound: exact backend + target + payload digest.
  [ "$ABK" = "$BK" ] && [ "$ATGT" = "$TGT" ] && [ "$ADIG" = "$DIG" ] && OK=1
  [ "$OK" = 1 ] || fail "approval does not match this operation (approved ${ABK}/${ATGT}; attempted ${BK}/${TGT})"
else
  # Prompt-hint bound: if hints/backends were named, THIS op must match one.
  HINTS="$(jq -r '.hints[]?' "$APPROVAL_JSON" 2>/dev/null)"
  BACKENDS="$(jq -r '.backends[]?' "$APPROVAL_JSON" 2>/dev/null)"
  HOK=1; BOK=1
  if [ -n "$HINTS" ]; then
    HOK=0
    while IFS= read -r h; do [ -n "$h" ] || continue; printf '%s' "$TGT" | grep -qiF "$h" && { HOK=1; break; }; done <<EOF
$HINTS
EOF
  fi
  if [ -n "$BACKENDS" ]; then
    BOK=0
    while IFS= read -r b; do [ -n "$b" ] || continue; [ "$b" = "$BK" ] && { BOK=1; break; }; done <<EOF
$BACKENDS
EOF
  fi
  if [ "$HOK" = 1 ] && [ "$BOK" = 1 ]; then
    OK=1   # matched named hints, OR a bare "yes" (no hints/backends) → allow once
  else
    fail "approval named a different target/backend than this write (attempted ${BK}/${TGT})"
  fi
fi

# Consume (single-use is intrinsic to the bound model) and allow.
jq '.consumed=true' "$APPROVAL_JSON" > "$APPROVAL_JSON.tmp" 2>/dev/null && mv "$APPROVAL_JSON.tmp" "$APPROVAL_JSON" 2>/dev/null
allow
