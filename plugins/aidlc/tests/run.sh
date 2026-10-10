#!/usr/bin/env bash
# AI-DLC guardrail-hook test suite (ENH-003).
# Pure bash; no live writes. Each case runs a hook with crafted stdin JSON in an
# isolated temp project dir and asserts the exit behaviour (deny JSON vs allow)
# and side effects. Run:  bash plugins/aidlc/tests/run.sh
set -u
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
HOOKS="$PLUGIN_ROOT/hooks"
PASS=0; FAIL=0
RED=$'\033[31m'; GRN=$'\033[32m'; NC=$'\033[0m'

command -v jq >/dev/null 2>&1 || { echo "jq is required to run these tests"; exit 2; }

# sha256 mirror of common.sh (to craft matching digests in manifest tests)
_sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum|awk '{print $1}';
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256|awk '{print $1}';
  elif command -v openssl >/dev/null 2>&1; then openssl dgst -sha256 2>/dev/null|awk '{print $NF}';
  else cksum|awk '{print "cksum-"$1"-"$2}'; fi; }

newproj() { CLAUDE_PROJECT_DIR="$(mktemp -d)"; export CLAUDE_PROJECT_DIR; mkdir -p "$CLAUDE_PROJECT_DIR/.aidlc/guardrails"; STATE="$CLAUDE_PROJECT_DIR/.aidlc/guardrails"; }
projenv() { printf '%s\n' "$@" > "$CLAUDE_PROJECT_DIR/.aidlc/guardrails.env"; }

# run <hook> <json>  -> sets OUT (stdout) and RC
run() { OUT="$(printf '%s' "$2" | bash "$HOOKS/$1" 2>/dev/null)"; RC=$?; }

is_deny() { printf '%s' "$OUT" | grep -q '"permissionDecision": *"deny"'; }

ok()   { PASS=$((PASS+1)); printf '  %sPASS%s %s\n' "$GRN" "$NC" "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  %sFAIL%s %s\n'  "$RED" "$NC" "$1"; [ -n "${2:-}" ] && printf '       %s\n' "$2"; }
assert_deny()  { if is_deny; then ok "$1"; else bad "$1" "expected DENY, got allow (rc=$RC)"; fi; }
assert_allow() { if is_deny; then bad "$1" "expected ALLOW, got deny"; else ok "$1"; fi; }
assert_file()  { if [ -f "$1" ]; then ok "$2"; else bad "$2" "missing $1"; fi; }
assert_nofile(){ if [ -f "$1" ]; then bad "$2" "unexpected $1"; else ok "$2"; fi; }

NOW=$(date +%s)
mkappr() { # write approval-<session>.json  args: session field=val...
  local sess="$1"; shift; printf '%s' "$1" > "$STATE/approval-$sess.json"; }

echo "== publish-gate: legacy (advisory, binding off) =="
newproj
run publish-gate.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"projectKey":"QI","issueTypeName":"Story","summary":"X"}}'
assert_deny "no token -> deny"
newproj; date +%s > "$STATE/approval-s1.token"
run publish-gate.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"summary":"X"}}'
assert_allow "fresh legacy token -> allow"
newproj; echo $((NOW-9999)) > "$STATE/approval-s1.token"
run publish-gate.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"summary":"X"}}'
assert_deny "expired legacy token -> deny"
newproj
run publish-gate.sh '{"session_id":"s1","tool_name":"Write","tool_input":{"file_path":"a.txt"}}'
assert_allow "local Write never publish-gated"

echo "== publish-gate: enforced + action-bound =="
newproj; projenv "GOVERNANCE_MODE=enforced"
run publish-gate.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"summary":"X"}}'
assert_deny "enforced, no approval -> deny"

# manifest-bound exact match -> allow
newproj; projenv "GOVERNANCE_MODE=enforced"
PAYLOAD='Create Workspace|Body here'; DIG="$(printf '%s' "$PAYLOAD" | _sha)"
jq -n --argjson ts "$NOW" --arg d "$DIG" '{ts:$ts,consumed:false,backend:"jira",target:"QI:Story:Create Workspace",digest:$d,hints:[],backends:[]}' > "$STATE/approval-s1.json"
run publish-gate.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"projectKey":"QI","issueTypeName":"Story","summary":"Create Workspace","description":"Body here"}}'
assert_allow "manifest-bound exact match -> allow"

# cross-target (approve QI-137, attempt QI-138) -> deny
newproj; projenv "GOVERNANCE_MODE=enforced"
jq -n --argjson ts "$NOW" '{ts:$ts,consumed:false,backend:"",target:"",digest:"",hints:["QI-137"],backends:[]}' > "$STATE/approval-s1.json"
run publish-gate.sh '{"session_id":"s1","tool_name":"editJiraIssue","tool_input":{"issueIdOrKey":"QI-138","fields":{}}}'
assert_deny "approve QI-137 cannot authorize QI-138"

# matching hint -> allow, then consumed -> second deny
newproj; projenv "GOVERNANCE_MODE=enforced"
jq -n --argjson ts "$NOW" '{ts:$ts,consumed:false,backend:"",target:"",digest:"",hints:["QI-137"],backends:[]}' > "$STATE/approval-s1.json"
run publish-gate.sh '{"session_id":"s1","tool_name":"editJiraIssue","tool_input":{"issueIdOrKey":"QI-137","fields":{}}}'
assert_allow "matching hint QI-137 -> allow"
run publish-gate.sh '{"session_id":"s1","tool_name":"editJiraIssue","tool_input":{"issueIdOrKey":"QI-137","fields":{}}}'
assert_deny "single-use: second write -> deny"

# cross-backend (approve jira, attempt confluence) -> deny
newproj; projenv "GOVERNANCE_MODE=enforced"
jq -n --argjson ts "$NOW" '{ts:$ts,consumed:false,backend:"",target:"",digest:"",hints:[],backends:["jira"]}' > "$STATE/approval-s1.json"
run publish-gate.sh '{"session_id":"s1","tool_name":"createConfluencePage","tool_input":{"title":"P","body":"B"}}'
assert_deny "jira approval cannot authorize a Confluence write"

# bare approval -> first allow, second deny (single-use)
newproj; projenv "GOVERNANCE_MODE=enforced"
jq -n --argjson ts "$NOW" '{ts:$ts,consumed:false,backend:"",target:"",digest:"",hints:[],backends:[]}' > "$STATE/approval-s1.json"
run publish-gate.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"summary":"A"}}'
assert_allow "bare approval -> first write allow"
run publish-gate.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"summary":"B"}}'
assert_deny "bare approval is single-use -> second deny"

# expired bound approval -> deny
newproj; projenv "GOVERNANCE_MODE=enforced"
jq -n --argjson ts "$((NOW-9999))" '{ts:$ts,consumed:false,backend:"",target:"",digest:"",hints:[],backends:[]}' > "$STATE/approval-s1.json"
run publish-gate.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"summary":"A"}}'
assert_deny "expired bound approval -> deny"

echo "== ENH-002: no silent downgrade =="
newproj; projenv "GOVERNANCE_MODE=enforced" "GUARDRAILS_ENABLED=false" "PUBLISH_GATE_MODE=off"
run publish-gate.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"summary":"X"}}'
assert_deny "enforced: GUARDRAILS_ENABLED=false + mode=off cannot downgrade publish gate"
newproj; projenv "GOVERNANCE_MODE=advisory" "PUBLISH_GATE_MODE=warn"
run publish-gate.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"summary":"X"}}'
assert_allow "advisory warn: absent approval -> allow (reports only)"

echo "== secret-scan =="
newproj
run secret-scan.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"description":"token ghp_abcdefghijklmnopqrstuvwxyz0123"}}'
assert_deny "secret in payload -> deny (default block)"
newproj; projenv "GOVERNANCE_MODE=enforced" "SECRET_SCAN_MODE=off"
run secret-scan.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"description":"token ghp_abcdefghijklmnopqrstuvwxyz0123"}}'
assert_deny "enforced: secret scan cannot be downgraded to off"
newproj
run secret-scan.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"description":"nothing secret here"}}'
assert_allow "clean payload -> allow"

echo "== robustness =="
newproj
run publish-gate.sh 'this is not json'
assert_allow "malformed JSON -> does not block (fail-open on own error)"
newproj; projenv "GOVERNANCE_MODE=enforced"
run publish-gate.sh '{"session_id":"s1","tool_name":"getJiraIssue","tool_input":{"issueIdOrKey":"QI-1"}}'
assert_allow "read tool (getJiraIssue) never gated"

echo "== approval-capture binding =="
newproj; projenv "APPROVAL_BINDING=true"
run approval-capture.sh '{"session_id":"s1","prompt":"go ahead"}'
assert_file "$STATE/approval-s1.json" "go ahead -> bound approval written"
assert_file "$STATE/approval-s1.token" "go ahead -> legacy token also written"
newproj; projenv "APPROVAL_BINDING=true"
run approval-capture.sh '{"session_id":"s1","prompt":"please could you clean up and refactor the whole createWorkspace area when you get a chance"}'
assert_nofile "$STATE/approval-s1.json" "long prose with no go-phrase -> no approval"
newproj; projenv "APPROVAL_BINDING=true"
printf '%s' "$PAYLOAD" > /dev/null
jq -n --arg d "$DIG" '{op:"createJiraIssue",backend:"jira",target:"QI:Story:Create Workspace",digest:$d}' > "$STATE/pending.json"
run approval-capture.sh '{"session_id":"s1","prompt":"yes"}'
if [ -f "$STATE/approval-s1.json" ] && [ "$(jq -r '.source' "$STATE/approval-s1.json")" = "manifest" ] && [ ! -f "$STATE/pending.json" ]; then ok "pending manifest promoted to bound approval"; else bad "pending manifest promoted to bound approval"; fi

echo
echo "Total: $((PASS+FAIL)) | ${GRN}PASS $PASS${NC} | ${RED}FAIL $FAIL${NC}"
[ "$FAIL" -eq 0 ]
