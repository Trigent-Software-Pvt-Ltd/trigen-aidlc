#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT}/hooks/common.sh"
[ "${GUARDRAILS_ENABLED:-true}" = "true" ] || allow
MODE="${SECRET_SCAN_MODE:-block}"; [ "$MODE" = "off" ] && allow
BLOB="$(printf '%s' "$INPUT" | jq -c '.tool_input // {}' 2>/dev/null)"
PAT='ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|AIza[0-9A-Za-z_-]{30,}|(^|[^A-Za-z0-9])sk-[A-Za-z0-9]{20,}|xoxp-[A-Za-z0-9-]{10,}'
HIT="$(printf '%s' "$BLOB" | grep -oE "$PAT" | head -1)"
[ -z "$HIT" ] && allow
PREVIEW="$(printf '%s' "$HIT" | cut -c1-6)"
MSG="Secret scan: the tool arguments contain what looks like a live credential (begins '${PREVIEW}…'). Remove the secret and use a reference or placeholder, then retry. Never publish credentials to a tracker or file."
if [ "$MODE" = "block" ]; then deny "$MSG"; fi
warn "$MSG"; allow
