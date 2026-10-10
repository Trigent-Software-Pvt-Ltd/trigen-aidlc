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

_sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum|awk '{print $1}';
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256|awk '{print $1}';
  elif command -v openssl >/dev/null 2>&1; then openssl dgst -sha256 2>/dev/null|awk '{print $NF}';
  else cksum|awk '{print "cksum-"$1"-"$2}'; fi; }

newproj() { CLAUDE_PROJECT_DIR="$(mktemp -d)"; export CLAUDE_PROJECT_DIR; mkdir -p "$CLAUDE_PROJECT_DIR/.aidlc/guardrails"; STATE="$CLAUDE_PROJECT_DIR/.aidlc/guardrails"; }
projenv() { printf '%s\n' "$@" > "$CLAUDE_PROJECT_DIR/.aidlc/guardrails.env"; }
run() { OUT="$(printf '%s' "$2" | bash "$HOOKS/$1" 2>/dev/null)"; RC=$?; }
is_deny() { printf '%s' "$OUT" | grep -q '"permissionDecision": *"deny"'; }
ok()   { PASS=$((PASS+1)); printf '  %sPASS%s %s\n' "$GRN" "$NC" "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  %sFAIL%s %s\n'  "$RED" "$NC" "$1"; [ -n "${2:-}" ] && printf '       %s\n' "$2"; }
assert_deny()  { if is_deny; then ok "$1"; else bad "$1" "expected DENY, got allow (rc=$RC)"; fi; }
assert_allow() { if is_deny; then bad "$1" "expected ALLOW, got deny"; else ok "$1"; fi; }
assert_file()  { if [ -f "$1" ]; then ok "$2"; else bad "$2" "missing $1"; fi; }
assert_nofile(){ if [ -f "$1" ]; then bad "$2" "unexpected $1"; else ok "$2"; fi; }

NOW=$(date +%s)
WRITE='{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"projectKey":"QI","issueTypeName":"Story","summary":"Create Workspace","description":"Body here"}}'
DIG_OK="$(printf '%s' 'Create Workspace|Body here' | _sha)"
appr() { jq -n --argjson ts "$1" --arg bk "$2" --arg tg "$3" --arg dg "$4" \
  '{ts:$ts,consumed:false,backend:$bk,target:$tg,digest:$dg,hints:[],backends:[]}' > "$STATE/approval-s1.json"; }
apprhint() { jq -n --argjson ts "$NOW" --arg h "$1" --arg b "$2" \
  '{ts:$ts,consumed:false,backend:"",target:"",digest:"",hints:(($h|split(" ")|map(select(length>0)))),backends:(($b|split(" ")|map(select(length>0))))}' > "$STATE/approval-s1.json"; }

echo "== publish-gate: legacy (advisory, binding off) =="
newproj
run publish-gate.sh "$WRITE"; assert_deny "no token -> deny"
newproj; date +%s > "$STATE/approval-s1.token"
run publish-gate.sh "$WRITE"; assert_allow "fresh legacy token -> allow"
newproj; echo $((NOW-9999)) > "$STATE/approval-s1.token"
run publish-gate.sh "$WRITE"; assert_deny "expired legacy token -> deny"
newproj
run publish-gate.sh '{"session_id":"s1","tool_name":"Write","tool_input":{"file_path":"a.txt"}}'; assert_allow "local Write never publish-gated"

echo "== publish-gate: ENFORCED (manifest mandatory) =="
newproj; projenv "GOVERNANCE_MODE=enforced"
run publish-gate.sh "$WRITE"; assert_deny "enforced, no approval -> deny"
newproj; projenv "GOVERNANCE_MODE=enforced"; appr "$NOW" jira "QI:Story:Create Workspace" "$DIG_OK"
run publish-gate.sh "$WRITE"; assert_allow "manifest exact match -> allow"
run publish-gate.sh "$WRITE"; assert_deny "manifest single-use: second write -> deny"
newproj; projenv "GOVERNANCE_MODE=enforced"; appr "$NOW" jira "QI:Story:Create Workspace" "deadbeef"
run publish-gate.sh "$WRITE"; assert_deny "manifest wrong digest -> deny"
newproj; projenv "GOVERNANCE_MODE=enforced"; appr "$NOW" jira "QI:Story:Other" "$DIG_OK"
run publish-gate.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"projectKey":"QI","issueTypeName":"Story","summary":"Other","description":"x"}}'
assert_deny "manifest cross-target -> deny"
newproj; projenv "GOVERNANCE_MODE=enforced"; appr "$((NOW-9999))" jira "QI:Story:Create Workspace" "$DIG_OK"
run publish-gate.sh "$WRITE"; assert_deny "manifest expired -> deny"
# ENH-003 fix #1: enforced forbids UNBOUND approvals (no digest), even matching hints
newproj; projenv "GOVERNANCE_MODE=enforced"; apprhint "QI-137" ""
run publish-gate.sh '{"session_id":"s1","tool_name":"editJiraIssue","tool_input":{"issueIdOrKey":"QI-137","fields":{}}}'
assert_deny "enforced: hint-only approval (no manifest) -> deny"
newproj; projenv "GOVERNANCE_MODE=enforced"; apprhint "" ""
run publish-gate.sh "$WRITE"; assert_deny "enforced: bare 'yes' approval (no manifest) -> deny"

echo "== publish-gate: ADVISORY + binding (lenient tier) =="
newproj; projenv "GOVERNANCE_MODE=advisory" "APPROVAL_BINDING=true" "PUBLISH_GATE_MODE=block"; apprhint "QI-137" ""
run publish-gate.sh '{"session_id":"s1","tool_name":"editJiraIssue","tool_input":{"issueIdOrKey":"QI-137","fields":{}}}'
assert_allow "advisory+binding: matching hint -> allow"
run publish-gate.sh '{"session_id":"s1","tool_name":"editJiraIssue","tool_input":{"issueIdOrKey":"QI-137","fields":{}}}'
assert_deny "advisory+binding: single-use second -> deny"
newproj; projenv "GOVERNANCE_MODE=advisory" "APPROVAL_BINDING=true" "PUBLISH_GATE_MODE=block"; apprhint "QI-137" ""
run publish-gate.sh '{"session_id":"s1","tool_name":"editJiraIssue","tool_input":{"issueIdOrKey":"QI-138","fields":{}}}'
assert_deny "advisory+binding: approve QI-137 cannot authorise QI-138"
newproj; projenv "GOVERNANCE_MODE=advisory" "APPROVAL_BINDING=true" "PUBLISH_GATE_MODE=block"; apprhint "" "jira"
run publish-gate.sh '{"session_id":"s1","tool_name":"createConfluencePage","tool_input":{"title":"P","body":"B"}}'
assert_deny "advisory+binding: jira approval cannot authorise Confluence"

echo "== ENH-002: no silent downgrade =="
newproj; projenv "GOVERNANCE_MODE=enforced" "GUARDRAILS_ENABLED=false" "PUBLISH_GATE_MODE=off"
run publish-gate.sh "$WRITE"; assert_deny "enforced: GUARDRAILS_ENABLED=false + mode=off cannot downgrade publish gate"
newproj; projenv "GOVERNANCE_MODE=advisory" "PUBLISH_GATE_MODE=warn"
run publish-gate.sh "$WRITE"; assert_allow "advisory warn: absent approval -> allow (reports only)"

echo "== fix #2: malformed input =="
newproj
run publish-gate.sh 'this is not json'; assert_allow "advisory: malformed input -> allow (non-blocking)"
newproj; projenv "GOVERNANCE_MODE=enforced"
run publish-gate.sh 'this is not json'; assert_deny "enforced: malformed input -> deny (fail closed)"
newproj; projenv "GOVERNANCE_MODE=enforced"
run publish-gate.sh '{"session_id":"s1","tool_name":"getJiraIssue","tool_input":{"issueIdOrKey":"QI-1"}}'
assert_allow "enforced: read tool (valid JSON) never gated"

echo "== fix #3: Bash publishing coverage (enforced, no approval -> deny) =="
newproj; projenv "GOVERNANCE_MODE=enforced"
run publish-gate.sh '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"glab mr create -t x"}}'; assert_deny "base: glab mr create"
newproj; projenv "GOVERNANCE_MODE=enforced"
run publish-gate.sh '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"glab api projects/1/issues -X POST -f title=x"}}'; assert_deny "ext: glab api POST"
newproj; projenv "GOVERNANCE_MODE=enforced"
run publish-gate.sh '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"gh pr create --title x"}}'; assert_deny "ext: gh pr create"
newproj; projenv "GOVERNANCE_MODE=enforced"
run publish-gate.sh '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"git push origin HEAD"}}'; assert_deny "ext: git push"
newproj; projenv "GOVERNANCE_MODE=enforced"
run publish-gate.sh '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"curl -X POST https://x.atlassian.net/rest/api/3/issue -d @b.json"}}'; assert_deny "ext: curl POST to atlassian"
newproj; projenv "GOVERNANCE_MODE=enforced"
run publish-gate.sh '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"ls -la"}}'; assert_allow "enforced: benign bash (ls) -> allow"
newproj; projenv "GOVERNANCE_MODE=advisory"
run publish-gate.sh '{"session_id":"s1","tool_name":"Bash","tool_input":{"command":"gh pr create --title x"}}'; assert_allow "advisory: extended form not newly blocked (compat)"

echo "== secret-scan =="
newproj
run secret-scan.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"description":"token ghp_abcdefghijklmnopqrstuvwxyz0123"}}'; assert_deny "secret in payload -> deny (default block)"
newproj; projenv "GOVERNANCE_MODE=enforced" "SECRET_SCAN_MODE=off"
run secret-scan.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"description":"token ghp_abcdefghijklmnopqrstuvwxyz0123"}}'; assert_deny "enforced: secret scan cannot be downgraded to off"
newproj
run secret-scan.sh '{"session_id":"s1","tool_name":"createJiraIssue","tool_input":{"description":"nothing secret here"}}'; assert_allow "clean payload -> allow"
newproj; projenv "GOVERNANCE_MODE=enforced"
run secret-scan.sh 'not json'; assert_deny "enforced: malformed input to secret scan -> deny"
newproj
run secret-scan.sh 'not json'; assert_allow "advisory: malformed input to secret scan -> allow"

echo "== approval-capture binding =="
newproj; projenv "APPROVAL_BINDING=true"
run approval-capture.sh '{"session_id":"s1","prompt":"go ahead"}'
assert_file "$STATE/approval-s1.json" "go ahead -> bound approval written"
assert_file "$STATE/approval-s1.token" "go ahead -> legacy token also written"
newproj; projenv "APPROVAL_BINDING=true"
run approval-capture.sh '{"session_id":"s1","prompt":"please could you clean up and refactor the whole createWorkspace area when you get a chance"}'
assert_nofile "$STATE/approval-s1.json" "long prose with no go-phrase -> no approval"
newproj; projenv "APPROVAL_BINDING=true"
jq -n --arg d "$DIG_OK" '{op:"createJiraIssue",backend:"jira",target:"QI:Story:Create Workspace",digest:$d}' > "$STATE/pending.json"
run approval-capture.sh '{"session_id":"s1","prompt":"yes"}'
if [ -f "$STATE/approval-s1.json" ] && [ "$(jq -r '.source' "$STATE/approval-s1.json")" = "manifest" ] && [ ! -f "$STATE/pending.json" ]; then ok "pending manifest promoted to bound approval"; else bad "pending manifest promoted to bound approval"; fi
# End-to-end: manifest promoted by a bare 'yes' then the matching write passes under enforced
newproj; projenv "GOVERNANCE_MODE=enforced"
jq -n --arg d "$DIG_OK" '{op:"createJiraIssue",backend:"jira",target:"QI:Story:Create Workspace",digest:$d}' > "$STATE/pending.json"
printf '%s' '{"session_id":"s1","prompt":"yes"}' | bash "$HOOKS/approval-capture.sh" >/dev/null 2>&1
run publish-gate.sh "$WRITE"; assert_allow "enforced e2e: manifest + 'yes' authorises the exact write"

echo "== qmetry-emit (ENH-013) — local default, no live calls =="
newproj
bash "$HOOKS/qmetry-emit.sh" --event design.approved --project QI --story QI-137 >/dev/null 2>&1
if [ -f "$STATE/qmetry-events.jsonl" ] && [ "$(jq -r '.event' "$STATE/qmetry-events.jsonl" | head -1)" = "design.approved" ]; then ok "local: event recorded as JSONL"; else bad "local: event recorded as JSONL"; fi
newproj; projenv "QMETRY_EMIT_MODE=off"
bash "$HOOKS/qmetry-emit.sh" --event x --project QI >/dev/null 2>&1
assert_nofile "$STATE/qmetry-events.jsonl" "off mode: nothing recorded"
newproj
bash "$HOOKS/qmetry-emit.sh" --project QI >/dev/null 2>&1; rc=$?
if [ "$rc" = 2 ]; then ok "missing --event -> error (rc 2)"; else bad "missing --event -> error (rc 2)" "rc=$rc"; fi
newproj
bash "$HOOKS/qmetry-emit.sh" --event tests.executed --data 'not json' >/dev/null 2>&1
if [ -f "$STATE/qmetry-events.jsonl" ] && [ "$(jq -rc '.data' "$STATE/qmetry-events.jsonl" | head -1)" = "{}" ]; then ok "non-JSON data coerced to {} (no injection)"; else bad "non-JSON data coerced to {}"; fi

echo
echo "Total: $((PASS+FAIL)) | ${GRN}PASS $PASS${NC} | ${RED}FAIL $FAIL${NC}"
[ "$FAIL" -eq 0 ]
