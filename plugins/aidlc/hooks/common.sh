#!/usr/bin/env bash
# Shared helpers for AI-DLC guardrail hooks. Sourced by each hook script.
# Never hard-fails the tool on its own bugs: unless a guardrail intentionally
# denies, scripts exit 0 (allow).

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
[ -f "$ROOT/hooks/guardrails.defaults.env" ] && . "$ROOT/hooks/guardrails.defaults.env"
PROJECT_ENV="${CLAUDE_PROJECT_DIR:-.}/.aidlc/guardrails.env"
[ -f "$PROJECT_ENV" ] && . "$PROJECT_ENV"

STATE_DIR="${CLAUDE_PROJECT_DIR:-$HOME}/.aidlc/guardrails"
mkdir -p "$STATE_DIR" 2>/dev/null || true

INPUT="$(cat)"
jqget() { printf '%s' "$INPUT" | jq -r "$1" 2>/dev/null; }
SESSION_ID="$(jqget '.session_id // "nosession"')"
TOOL_NAME="$(jqget '.tool_name // ""')"

allow() { exit 0; }
warn()  { printf 'aidlc-guardrails: %s\n' "$1" >&2; }
deny()  { jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'; exit 0; }
