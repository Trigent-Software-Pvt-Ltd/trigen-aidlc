#!/usr/bin/env bash
# Records an approval token when the user's message is an explicit go-ahead.
# STRONG phrases approve at any length; WEAK imperatives approve only in a short
# message (<= 10 words) so long prose that merely contains "create"/"publish"
# does not silently unlock a tracker write.
. "${CLAUDE_PLUGIN_ROOT}/hooks/common.sh"
[ "${GUARDRAILS_ENABLED:-true}" = "true" ] || exit 0
PROMPT="$(jqget '.prompt // ""')"
[ -z "$PROMPT" ] && exit 0
WC=$(printf '%s' "$PROMPT" | wc -w | tr -d ' ')

STRONG='go ahead|^[[:space:]]*(yes|ok|okay|yep|sure)([[:space:]]|$|,|\.)|approved|publish it|ship it|create (it|them|these|the (tickets|stories|issues|epic|pages?))|transfer now|proceed with (the )?(transfer|creation|publish|tickets|jira)'
WEAK='(^|[^a-z])(publish|create|transfer|proceed|approve[d]?|go|do it|make it)([^a-z]|$)'

APPROVE=0
if printf '%s' "$PROMPT" | grep -Eiq "$STRONG"; then
  APPROVE=1
elif [ "${WC:-99}" -le 10 ] && printf '%s' "$PROMPT" | grep -Eiq "$WEAK"; then
  APPROVE=1
fi
[ "$APPROVE" = "1" ] && { date +%s > "$STATE_DIR/approval-$SESSION_ID.token" 2>/dev/null || true; }
exit 0
