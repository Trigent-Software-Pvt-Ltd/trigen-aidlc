#!/usr/bin/env bash
# Record the operation the agent is ABOUT to ask the user to approve, so the
# approval can be bound to it (ENH-001). Optional but recommended: run this right
# before showing the drafted change and asking "publish?". When present, the
# publish gate requires the actual write to match backend + target + payload digest
# exactly. Without it, a bare approval still works but is single-use only.
#
# Usage:
#   bash hooks/propose.sh --op <toolName> --backend <jira|confluence|gitlab|ado> \
#        --target "<issue key / page id / title>" [--payload-file <f>]
#   # or pipe the payload on stdin:
#   printf '%s' "$BODY" | bash hooks/propose.sh --op createConfluencePage --backend confluence --target "My Page"
AIDLC_SKIP_STDIN=1    # do not let common.sh consume our stdin
export AIDLC_SKIP_STDIN
. "${CLAUDE_PLUGIN_ROOT}/hooks/common.sh"

op=""; backend=""; target=""; pfile=""
while [ $# -gt 0 ]; do
  case "$1" in
    --op) op="$2"; shift 2 ;;
    --backend) backend="$2"; shift 2 ;;
    --target) target="$2"; shift 2 ;;
    --payload-file) pfile="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -n "$pfile" ] && [ -f "$pfile" ]; then
  payload="$(cat "$pfile")"
else
  payload="$(cat 2>/dev/null || true)"
fi
digest="$(printf '%s' "$payload" | sha256)"

mkdir -p "$STATE_DIR" 2>/dev/null || true
jq -n --arg op "$op" --arg backend "$backend" --arg target "$target" --arg digest "$digest" \
  '{op:$op, backend:$backend, target:$target, digest:$digest}' > "$PENDING_JSON" 2>/dev/null \
  && printf 'aidlc: recorded pending %s on %s (%s)\n' "${op:-?}" "${backend:-?}" "${target:-?}" >&2
exit 0
