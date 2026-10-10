#!/usr/bin/env bash
# AI-DLC skill & reference integrity suite (ENH-011 safety net + ENH-015 static eval).
# Pure bash; read-only. Guards against: broken frontmatter, a skill losing a
# load-bearing requirement (anchor phrases), dangling @references, and missing
# Cursor parity. Run after any skill edit — especially a slimming pass.
#   bash plugins/aidlc/tests/skills.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SK="$ROOT/skills"; RULES="$ROOT/.cursor/rules"; REF="$ROOT/references"
PASS=0; FAIL=0
RED=$'\033[31m'; GRN=$'\033[32m'; NC=$'\033[0m'
ok(){ PASS=$((PASS+1)); printf '  %sPASS%s %s\n' "$GRN" "$NC" "$1"; }
bad(){ FAIL=$((FAIL+1)); printf '  %sFAIL%s %s\n' "$RED" "$NC" "$1"; [ -n "${2:-}" ] && printf '       %s\n' "$2"; }
has(){ grep -qiE "$2" "$1"; }

echo "== frontmatter: name == folder, description present =="
for d in "$SK"/*/; do
  s="$(basename "$d")"; f="$d/SKILL.md"
  [ -f "$f" ] || { bad "$s has SKILL.md"; continue; }
  n="$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -1)"
  [ "$n" = "$s" ] && ok "$s: name matches folder" || bad "$s: name matches folder" "name='$n'"
  desc="$(sed -n 's/^description:[[:space:]]*//p' "$f" | head -1)"
  [ -n "$desc" ] && ok "$s: description present" || bad "$s: description present"
done

echo "== Cursor parity: each skill has a .mdc rule =="
for d in "$SK"/*/; do s="$(basename "$d")"; [ -f "$RULES/$s.mdc" ] && ok "$s.mdc exists" || bad "$s.mdc exists"; done

echo "== reference links resolve (aidlc-internal @refs only) =="
# Only validate links that are explicitly aidlc-internal:
#   ${CLAUDE_PLUGIN_ROOT}/references/...  or  @plugins/aidlc/references/...
# Cross-plugin links (e.g. @plugins/standards/references/technical-guidance/*) are
# out of scope for this plugin's integrity check.
dangling=0
for f in "$SK"/*/SKILL.md "$REF"/*.md; do
  while IFS= read -r rp; do
    [ -n "$rp" ] || continue
    [ -f "$ROOT/$rp" ] || { bad "dangling ref in $(basename "$(dirname "$f")")/$(basename "$f"): $rp"; dangling=$((dangling+1)); }
  done < <(grep -oE '(\$\{CLAUDE_PLUGIN_ROOT\}|@plugins/aidlc)/references/[A-Za-z0-9/_-]+\.md' "$f" \
             | sed -E 's#^(\$\{CLAUDE_PLUGIN_ROOT\}|@plugins/aidlc)/##' | sort -u)
done
[ "$dangling" = 0 ] && ok "all aidlc-internal reference links resolve"

echo "== referenced hooks exist =="
for h in propose.sh qmetry-emit.sh publish-gate.sh approval-capture.sh; do
  grep -rqlE "hooks/$h" "$SK" "$REF" >/dev/null 2>&1 && { [ -f "$ROOT/hooks/$h" ] && ok "hook $h referenced & present" || bad "hook $h referenced but missing"; }
done

echo "== required requirement anchors (a slim must not drop these) =="
chk(){ # chk <skill> <regex> <label>
  has "$SK/$1/SKILL.md" "$2" && ok "$1: $3" || bad "$1: $3" "missing /$2/"; }
chk aidlc-tdd 'failing test' 'red-stage requirement'
chk aidlc-tdd 'evidence' 'evidence capture'
chk aidlc-tdd 'regression' 'regression run'
chk aidlc-debug 'reproduce' 'reproduce step'
chk aidlc-debug 'root cause' 'root-cause focus'
chk aidlc-debug 'regression test' 'regression test'
chk aidlc-verify-completion 'NOT RUN' 'NOT RUN state'
chk aidlc-verify-completion 'never.*(unexecuted|merge)' 'no-false-pass rule'
chk aidlc-verify-completion 'distinct' 'distinct from /aidlc-verify'
chk aidlc-review 'Stage 1' 'stage 1 spec compliance'
chk aidlc-review 'Stage 2' 'stage 2 engineering quality'
chk aidlc-review 'human approver' 'reviewer != human approver'
chk aidlc-sprint 'aidlc-tdd' 'TDD companion wired'
chk aidlc-sprint 'verify-completion' 'completion companion wired'
chk aidlc-refactor 'characterization' 'characterization tests'
chk aidlc-refactor 'contract' 'preserve external contracts'
chk aidlc-retro 'skill-eval' 'skill-eval harness wired'
chk aidlc-retro '(never.*rewrit|human.*(owns|approve))' 'human-approval guard'
chk aidlc-verify 'coherence' 'coherence check'
chk aidlc-verify 'work-item template' 'rich ticket template'
chk aidlc-design 'Design Document' 'design document output'
chk aidlc-design 'ADR' 'ADR capture'
chk aidlc-intent 'PRD' 'PRD output'
chk aidlc-elaborate '[Ee]pic' 'epic decomposition'
chk aidlc-init 'aidlc.config.yaml' 'writes config'
chk aidlc-init '(readiness|sprint0)' 'sprint 0 readiness'
chk aidlc-progress 'traceab' 'traceability report'

echo
echo "Total: $((PASS+FAIL)) | ${GRN}PASS $PASS${NC} | ${RED}FAIL $FAIL${NC}"
[ "$FAIL" -eq 0 ]
