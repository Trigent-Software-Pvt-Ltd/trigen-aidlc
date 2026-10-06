#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT}/hooks/common.sh"
[ "${GUARDRAILS_ENABLED:-true}" = "true" ] || allow
MODE="${EARS_MODE:-warn}"; [ "$MODE" = "off" ] && allow
printf '%s' "$TOOL_NAME" | grep -Eq 'ConfluencePage' || allow
TITLE="$(jqget '.tool_input.title // ""')"
BODY="$(jqget '.tool_input.body // ""')"
# Only act on the acceptance-criteria catalogue
printf '%s %s' "$TITLE" "$BODY" | grep -Eq 'Acceptance Criteria|AC-[A-Z]{2,4}-[0-9]' || allow
# An AC line that states a criterion must carry an EARS keyword. Lines that merely
# reference ids (registers, matrices) are allowed. Heuristic: flag lines beginning
# with an AC id + an em/dash definition that lack EARS keywords.
BAD="$(printf '%s' "$BODY" | grep -oE '(\*\*)?AC-[A-Z]{2,4}-[0-9]+(\*\*)?[[:space:]]*[—:-][^|]*' \
  | grep -viE 'WHEN|IF |THEN|SHALL|WHILE|WHERE|UBIQUITOUS' \
  | grep -oE 'AC-[A-Z]{2,4}-[0-9]+' | sort -u | tr '\n' ' ')"
[ -z "$BAD" ] && allow
MSG="EARS check: these acceptance-criteria lines look like definitions but lack an EARS keyword (WHEN / IF…THEN / SHALL / WHILE / WHERE): ${BAD}. Write them in EARS, or if a line is only an id reference in a register/matrix, ignore this."
if [ "$MODE" = "block" ]; then deny "$MSG"; fi
warn "$MSG"; allow
