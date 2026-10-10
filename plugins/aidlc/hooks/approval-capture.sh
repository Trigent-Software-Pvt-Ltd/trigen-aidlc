#!/usr/bin/env bash
# Records an approval when the user's message is an explicit go-ahead.
# STRONG phrases approve at any length; WEAK imperatives approve only in a short
# message (<= 10 words) so long prose that merely contains "create"/"publish"
# does not silently unlock a tracker write.
#
# When APPROVAL_BINDING=true (always on under enforced governance), the approval is
# bound to a specific operation: it promotes the pending manifest written by
# propose.sh (authoritative: backend+target+payload digest) or, absent a manifest,
# captures target/backend hints from the prompt. publish-gate then requires the
# actual write to match. A legacy timestamp token is ALSO written so advisory mode
# and callers that never bound keep behaving exactly as before.
. "${CLAUDE_PLUGIN_ROOT}/hooks/common.sh"
[ "${GUARDRAILS_ENABLED:-true}" = "true" ] || [ "$GOVERNANCE_MODE" = "enforced" ] || exit 0
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
[ "$APPROVE" = "1" ] || exit 0

# Legacy token (advisory fallback / unchanged behaviour when binding is off).
date +%s > "$LEGACY_TOKEN" 2>/dev/null || true

if [ "${APPROVAL_BINDING}" = "true" ]; then
  NOW="$(date +%s)"
  HINTS="$(printf '%s' "$PROMPT" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | sort -u | tr '\n' ' ')"
  BKS="$(printf '%s' "$PROMPT" | grep -oiE 'jira|confluence|gitlab' | tr 'A-Z' 'a-z' | sort -u | tr '\n' ' ')"
  if [ -f "$PENDING_JSON" ]; then
    # Promote the authoritative manifest; stamp approval metadata.
    jq --argjson ts "$NOW" --arg hints "$HINTS" \
       '. + {ts:$ts, consumed:false, approver:"user", source:"manifest",
             hints:($hints|split(" ")|map(select(length>0)))}' \
       "$PENDING_JSON" > "$APPROVAL_JSON" 2>/dev/null && rm -f "$PENDING_JSON"
  else
    jq -n --argjson ts "$NOW" --arg hints "$HINTS" --arg bks "$BKS" \
       '{ts:$ts, consumed:false, approver:"user", source:"prompt",
         backend:"", target:"", digest:"",
         hints:($hints|split(" ")|map(select(length>0))),
         backends:($bks|split(" ")|map(select(length>0)))}' \
       > "$APPROVAL_JSON" 2>/dev/null
  fi
fi
exit 0
