#!/bin/bash
# poll-pipeline.sh — Poll a GitLab CI pipeline until it reaches a terminal state.
#
# Usage: poll-pipeline.sh -b <branch> [-p <pipeline-id>] [-i <interval>] [-t <timeout>] [-R <repo>]
#
# Options:
#   -b <branch>       Branch name to monitor (required unless -p is given)
#   -p <pipeline-id>  Specific pipeline ID to monitor
#   -i <interval>     Poll interval in seconds (default: 30)
#   -t <timeout>      Max wait time in seconds (default: 1800 = 30 minutes)
#   -R <repo>         GitLab project path (e.g., group/project) for -R flag
#   -h, --help        Show this help message
#
# Output:
#   stderr: Human-readable status updates during polling
#   stdout: Final pipeline JSON (only on terminal state)
#
# Exit codes:
#   0 = success (all jobs passed)
#   1 = failed (one or more jobs failed)
#   2 = canceled or skipped
#   3 = timeout (pipeline still running)
#   4 = error (glab command failed or invalid arguments)

set -euo pipefail

BRANCH=""
PIPELINE_ID=""
INTERVAL=30
TIMEOUT=1800
REPO=""

usage() {
  echo "poll-pipeline.sh - Poll a GitLab CI pipeline until it reaches a terminal state."
  echo ""
  echo "Usage: poll-pipeline.sh -b <branch> [-p <pipeline-id>] [-i <interval>] [-t <timeout>] [-R <repo>]"
  echo ""
  echo "Options:"
  echo "  -b <branch>       Branch name to monitor (required unless -p is given)"
  echo "  -p <pipeline-id>  Specific pipeline ID to monitor"
  echo "  -i <interval>     Poll interval in seconds (default: 30)"
  echo "  -t <timeout>      Max wait time in seconds (default: 1800 = 30 minutes)"
  echo "  -R <repo>         GitLab project path (e.g., group/project) for -R flag"
  echo "  -h, --help        Show this help message"
  echo ""
  echo "Exit codes: 0=success, 1=failed, 2=canceled/skipped, 3=timeout, 4=error"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -b) BRANCH="$2"; shift 2 ;;
    -p) PIPELINE_ID="$2"; shift 2 ;;
    -i) INTERVAL="$2"; shift 2 ;;
    -t) TIMEOUT="$2"; shift 2 ;;
    -R) REPO="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; exit 4 ;;
  esac
done

if [[ -z "$BRANCH" && -z "$PIPELINE_ID" ]]; then
  echo "Error: either -b <branch> or -p <pipeline-id> is required." >&2
  exit 4
fi

# Build the glab command
build_glab_cmd() {
  local cmd="glab ci get -F json -d"
  if [[ -n "$PIPELINE_ID" ]]; then
    cmd="$cmd -p $PIPELINE_ID"
  elif [[ -n "$BRANCH" ]]; then
    cmd="$cmd -b $BRANCH"
  fi
  if [[ -n "$REPO" ]]; then
    cmd="$cmd -R $REPO"
  fi
  echo "$cmd"
}

GLAB_CMD=$(build_glab_cmd)
START_TIME=$(date +%s)

# Extract a field from JSON (portable: try jq, then python3, then python, then grep)
extract_json_field() {
  local json="$1" field="$2" fallback="$3"
  if command -v jq &>/dev/null; then
    echo "$json" | jq -r ".$field // \"$fallback\"" 2>/dev/null && return
  fi
  for py in python3 python; do
    if command -v "$py" &>/dev/null; then
      echo "$json" | "$py" -c "
import sys,json
try:
    d=json.load(sys.stdin); print(d.get('$field','$fallback'))
except:
    print('$fallback')
" 2>/dev/null && return
    fi
  done
  # Fallback: basic grep extraction for simple JSON
  echo "$json" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | grep -o '"[^"]*"$' | tr -d '"' || echo "$fallback"
}

echo "Polling pipeline (interval: ${INTERVAL}s, timeout: ${TIMEOUT}s)..." >&2
echo "Command: $GLAB_CMD" >&2
echo "" >&2

while true; do
  ELAPSED=$(( $(date +%s) - START_TIME ))

  if [[ $ELAPSED -ge $TIMEOUT ]]; then
    echo "Timeout reached after ${ELAPSED}s. Pipeline is still running." >&2
    # Try to get the latest state for the output
    JSON=$($GLAB_CMD 2>/dev/null) || true
    if [[ -n "$JSON" ]]; then
      echo "$JSON"
    fi
    exit 3
  fi

  # Fetch pipeline status
  if ! JSON=$($GLAB_CMD 2>/dev/null); then
    echo "Error: glab command failed." >&2
    exit 4
  fi

  STATUS=$(extract_json_field "$JSON" "status" "unknown")
  PID=$(extract_json_field "$JSON" "id" "?")

  ELAPSED_DISPLAY=$(printf '%dm %ds' $((ELAPSED / 60)) $((ELAPSED % 60)))
  echo "[${ELAPSED_DISPLAY}] Pipeline #${PID}: ${STATUS}" >&2

  case "$STATUS" in
    success)
      echo "$JSON"
      exit 0
      ;;
    failed)
      echo "$JSON"
      exit 1
      ;;
    canceled|skipped)
      echo "$JSON"
      exit 2
      ;;
    created|waiting_for_resource|preparing|pending|running|scheduled)
      # Still in progress, keep polling
      ;;
    manual)
      # Pipeline is waiting on manual action
      echo "Pipeline is waiting on a manual job." >&2
      echo "$JSON"
      exit 2
      ;;
    unknown)
      echo "Warning: could not parse pipeline status." >&2
      ;;
    *)
      echo "Warning: unexpected status '${STATUS}'." >&2
      ;;
  esac

  sleep "$INTERVAL"
done
