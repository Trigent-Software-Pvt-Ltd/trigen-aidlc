#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT}/hooks/common.sh"
[ "${GUARDRAILS_ENABLED:-true}" = "true" ] || allow
[ "${PUBLISH_GATE_MODE:-block}" = "off" ] && allow

if [ "$TOOL_NAME" = "Bash" ]; then
  [ "${PUBLISH_GATE_INCLUDE_BASH:-true}" = "true" ] || allow
  CMD="$(jqget '.tool_input.command // ""')"
  printf '%s' "$CMD" | grep -Eq 'glab[[:space:]]+mr[[:space:]]+(create|merge|update|close|note|approve|revoke)|jira[[:space:]]+workitem[[:space:]]+(create|update|edit|delete|link|transition|assign|comment)|acli[[:space:]]+confluence[[:space:]].*(addPage|storePage)|--action[[:space:]]+(addPage|storePage)' || allow
fi

# Defense in depth: for non-Bash tools, only gate recognised tracker-WRITE tools.
# (hooks.json already routes only these here, but this guarantees a read tool is
# never blocked even if the matcher is widened by mistake.)
if [ "$TOOL_NAME" != "Bash" ]; then
  printf '%s' "$TOOL_NAME" | grep -Eq 'createJiraIssue|editJiraIssue|createConfluencePage|updateConfluencePage|createIssueLink|transitionJiraIssue|addCommentToJiraIssue|deleteConfluencePage|createConfluenceFooterComment|createConfluenceInlineComment' || allow
fi

TOKEN="$STATE_DIR/approval-$SESSION_ID.token"
NOW=$(date +%s)
if [ -f "$TOKEN" ]; then
  TS="$(head -1 "$TOKEN" 2>/dev/null)"; TS="${TS:-0}"
  AGE=$(( NOW - TS ))
  if [ "$AGE" -le "${PUBLISH_GATE_TTL:-600}" ]; then
    [ "${PUBLISH_GATE_SINGLE_USE:-false}" = "true" ] && rm -f "$TOKEN"
    allow
  fi
fi

MSG="AI-DLC publish gate: writing to the tracker ($TOOL_NAME) needs an explicit user go first. Show the drafted change in chat and wait for the user to approve (e.g. 'publish' / 'create' / 'go ahead'), then retry. Running a phase is not consent to write."
if [ "${PUBLISH_GATE_MODE:-block}" = "warn" ]; then warn "$MSG"; allow; fi
deny "$MSG"
