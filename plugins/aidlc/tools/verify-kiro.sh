#!/usr/bin/env bash
# Integrity suite for the generated Kiro port (plugins/aidlc/kiro-dist/.kiro).
# Mirrors tests/skills.sh for the Kiro surface: frontmatter, description limits,
# aidlc-internal reference resolution, steering frontmatter, valid JSON for hooks/mcp.
#   bash plugins/aidlc/tools/verify-kiro.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"           # plugins/aidlc
K="$ROOT/kiro-dist/.kiro"
SK="$K/skills"; ST="$K/steering"; REF="$K/aidlc/references"
PASS=0; FAIL=0
RED=$'\033[31m'; GRN=$'\033[32m'; NC=$'\033[0m'
ok(){ PASS=$((PASS+1)); printf '  %sPASS%s %s\n' "$GRN" "$NC" "$1"; }
bad(){ FAIL=$((FAIL+1)); printf '  %sFAIL%s %s\n' "$RED" "$NC" "$1"; [ -n "${2:-}" ] && printf '       %s\n' "$2"; }

[ -d "$K" ] || { echo "No .kiro dist found — run: python3 tools/build-kiro.py"; exit 1; }

echo "== Kiro Agent Skills: SKILL.md present, name==folder, description <=1024 =="
for d in "$SK"/*/; do
  s="$(basename "$d")"; f="$d/SKILL.md"
  [ -f "$f" ] || { bad "$s has SKILL.md"; continue; }
  n="$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -1)"
  [ "$n" = "$s" ] && ok "$s: name matches folder" || bad "$s: name matches folder" "name='$n'"
  desc="$(sed -n 's/^description:[[:space:]]*//p' "$f" | head -1)"
  [ -n "$desc" ] && ok "$s: description present" || bad "$s: description present"
  dlen=${#desc}
  [ "$dlen" -le 1024 ] && ok "$s: description <=1024 ($dlen)" || bad "$s: description <=1024" "len=$dlen"
  # name rules: lowercase/digits/hyphen, <=64
  echo "$n" | grep -qE '^[a-z0-9-]{1,64}$' && ok "$s: name charset/length ok" || bad "$s: name charset/length"
done

echo "== no Claude-only placeholders leaked into skills =="
if grep -rlE '\$\{CLAUDE_PLUGIN_ROOT\}|\{\{SKILL_DIR\}\}|@plugins/aidlc/' "$SK" >/dev/null 2>&1; then
  bad "placeholder leak in skills"; grep -rlE '\$\{CLAUDE_PLUGIN_ROOT\}|\{\{SKILL_DIR\}\}|@plugins/aidlc/' "$SK" | sed 's/^/       /'
else ok "no unrewritten placeholders in skills"; fi

echo "== aidlc-internal reference links resolve (.kiro/aidlc/references/*) =="
dangling=0
for f in $(grep -rlE '\.kiro/aidlc/references/' "$SK" "$ST" "$REF" 2>/dev/null); do
  while IFS= read -r rp; do
    [ -n "$rp" ] || continue
    tgt="$K/${rp#.kiro/}"
    [ -f "$tgt" ] || { bad "dangling ref in ${f#$K/}: $rp"; dangling=$((dangling+1)); }
  done < <(grep -oE '\.kiro/aidlc/references/[A-Za-z0-9/_-]+\.md' "$f" | sort -u)
done
[ "$dangling" = 0 ] && ok "all aidlc-internal reference links resolve"

echo "== skill-local references resolve (references/*.md inside a skill) =="
locald=0
for f in "$SK"/*/SKILL.md; do
  d="$(dirname "$f")"
  while IFS= read -r rp; do
    [ -n "$rp" ] || continue
    [ -f "$d/$rp" ] || { bad "dangling local ref in $(basename "$d"): $rp"; locald=$((locald+1)); }
  done < <(sed -E 's#[A-Za-z0-9._-]+/references/#__PREFIXED__#g' "$f" | grep -oE 'references/[A-Za-z0-9/_-]+\.md' | sort -u)
done
[ "$locald" = 0 ] && ok "all skill-local reference links resolve"

echo "== steering files: frontmatter first line, inclusion present =="
for f in "$ST"/*.md; do
  s="$(basename "$f")"
  head -1 "$f" | grep -qx -- '---' && ok "$s: frontmatter starts at line 1" || bad "$s: frontmatter must be first content"
  grep -qE '^inclusion:[[:space:]]*(always|fileMatch|manual|auto)$' "$f" && ok "$s: valid inclusion mode" || bad "$s: valid inclusion mode"
done

echo "== JSON validity: hooks + mcp =="
for j in "$K"/hooks/*.json "$K"/settings/mcp.json; do
  [ -f "$j" ] || continue
  if python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$j" >/dev/null 2>&1; then
    ok "valid JSON: ${j#$K/}"
  else bad "invalid JSON: ${j#$K/}"; fi
done

echo "== hook schema: version v1 + trigger + action.type =="
for j in "$K"/hooks/*.json; do
  [ -f "$j" ] || continue
  python3 - "$j" <<'PY' && ok "hook schema ok: $(basename "$j")" || bad "hook schema: $(basename "$j")"
import json,sys
d=json.load(open(sys.argv[1]))
assert d.get("version")=="v1"
for h in d["hooks"]:
    assert h.get("name") and h.get("trigger") and h["action"]["type"] in ("command","agent")
PY
done

echo
echo "Total: $((PASS+FAIL)) | ${GRN}PASS $PASS${NC} | ${RED}FAIL $FAIL${NC}"
[ "$FAIL" -eq 0 ]
