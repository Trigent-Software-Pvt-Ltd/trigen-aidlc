#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT}/hooks/common.sh"
[ "${GUARDRAILS_ENABLED:-true}" = "true" ] || exit 0
SENT="off"; [ "${SENTINEL_ENABLED:-false}" = "true" ] && SENT="${SENTINEL_MODE:-warn}"
TEXT="AI-DLC guardrails active — publish-gate=${PUBLISH_GATE_MODE:-block} (tracker writes require an explicit user 'go' within ${PUBLISH_GATE_TTL:-600}s), ears=${EARS_MODE:-warn}, secret-scan=${SECRET_SCAN_MODE:-block}, sentinel=${SENT}. A blocked write means: show the draft, get approval, retry."
jq -n --arg t "$TEXT" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$t}}'
exit 0
