#!/usr/bin/env bash
# Emit an AI-DLC lifecycle event for QMetry360 (ENH-013). Optional, dependency-light.
# Default records locally (JSONL); a live POST runs only when explicitly configured
# against a VERIFIED contract — no endpoint or auth is shipped. See
# references/qmetry360-events.md.
#
# Usage:
#   bash hooks/qmetry-emit.sh --event design.approved --project QI --feature FI-0001 \
#        --epic QI-136 --story QI-137 --artifact <url> --correlation WSS --risk med [--actor x] [--data '{...}']
#
# Modes (QMETRY_EMIT_MODE): off | local (default) | live
#   live also POSTs to $QMETRY_API_URL with the token in the env var named by
#   $QMETRY_TOKEN_ENV. If curl is missing or the URL is unset, it degrades to local.
AIDLC_SKIP_STDIN=1; export AIDLC_SKIP_STDIN
. "${CLAUDE_PLUGIN_ROOT}/hooks/common.sh"

MODE="${QMETRY_EMIT_MODE:-local}"
[ "$MODE" = "off" ] && exit 0

event=""; project=""; feature=""; epic=""; story=""; artifact=""; correlation=""; risk=""; actor="${USER:-agent}"; data="{}"
while [ $# -gt 0 ]; do case "$1" in
  --event) event="$2"; shift 2;; --project) project="$2"; shift 2;;
  --feature) feature="$2"; shift 2;; --epic) epic="$2"; shift 2;;
  --story) story="$2"; shift 2;; --artifact) artifact="$2"; shift 2;;
  --correlation) correlation="$2"; shift 2;; --risk) risk="$2"; shift 2;;
  --actor) actor="$2"; shift 2;; --data) data="$2"; shift 2;; *) shift;; esac; done

[ -n "$event" ] || { printf 'qmetry-emit: --event is required\n' >&2; exit 2; }
printf '%s' "$data" | jq -e . >/dev/null 2>&1 || data="{}"   # reject non-JSON data; never embed secrets
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

EVENT_JSON="$(jq -nc --arg v "1" --arg e "$event" --arg ts "$TS" --arg p "$project" \
  --arg f "$feature" --arg ep "$epic" --arg s "$story" --arg a "$artifact" \
  --arg c "$correlation" --arg r "$risk" --arg ac "$actor" --argjson d "$data" \
  '{schemaVersion:$v,event:$e,ts:$ts,project:$p,featureId:$f,epicId:$ep,storyId:$s,
    artifact:$a,correlationId:$c,risk:$r,actor:$ac,data:$d}
   | with_entries(select(.value != "" and .value != null))')"

# Local record (always, unless off) — git-ignored JSONL under the project state dir.
FILE="${QMETRY_EVENTS_FILE:-$STATE_DIR/qmetry-events.jsonl}"
mkdir -p "$(dirname "$FILE")" 2>/dev/null || true
printf '%s\n' "$EVENT_JSON" >> "$FILE" 2>/dev/null || true

# Live POST — only against a configured, verified contract; degrade to local otherwise.
if [ "$MODE" = "live" ]; then
  if command -v curl >/dev/null 2>&1 && [ -n "${QMETRY_API_URL:-}" ]; then
    TOKEN=""; [ -n "${QMETRY_TOKEN_ENV:-}" ] && TOKEN="$(printf '%s' "${!QMETRY_TOKEN_ENV}")"
    curl -fsS -X POST "$QMETRY_API_URL" \
      -H 'Content-Type: application/json' \
      ${TOKEN:+-H "Authorization: Bearer $TOKEN"} \
      -d "$EVENT_JSON" >/dev/null 2>&1 \
      || printf 'qmetry-emit: live POST failed; event recorded locally in %s\n' "$FILE" >&2
  else
    printf 'qmetry-emit: live mode but QMETRY_API_URL unset or curl missing — recorded locally only\n' >&2
  fi
fi
exit 0
