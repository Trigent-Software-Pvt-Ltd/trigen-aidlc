#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT}/hooks/common.sh"
[ "${GUARDRAILS_ENABLED:-true}" = "true" ] || allow
[ "${SENTINEL_ENABLED:-false}" = "true" ] || allow
printf '%s' "$TOOL_NAME" | grep -Eq 'createJiraIssue' || allow
TYPE="$(jqget '.tool_input.issueTypeName // ""')"
printf '%s' "$TYPE" | grep -Eiq 'story|task|bolt' || allow
LABELS="$(printf '%s' "$INPUT" | jq -r '.tool_input.additional_fields.labels // [] | join(",")' 2>/dev/null)"
DESC="$(jqget '.tool_input.description // ""')"
MISS=""
printf '%s' "$LABELS" | grep -q 'aidlc' || MISS="$MISS labels(aidlc)"
printf '%s' "$INPUT" | jq -e '(.tool_input.additional_fields.timetracking.originalEstimate // .tool_input.additional_fields.customfield_10016) != null' >/dev/null 2>&1 || MISS="$MISS estimate"
printf '%s' "$DESC" | grep -Eq 'AC-[A-Z]{2,4}-[0-9]|Acceptance' || MISS="$MISS acceptance-criteria"
[ -z "$MISS" ] && allow
MSG="Transfer sentinel: this leaf looks incomplete —$MISS. Add before creating (work-item template)."
if [ "${SENTINEL_MODE:-warn}" = "block" ]; then deny "$MSG"; fi
warn "$MSG"; allow
