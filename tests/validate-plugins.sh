#!/usr/bin/env bash
#
# validate-plugins.sh — Structural validation for Claude Code plugins
#
# Checks plugin.json, SKILL.md, marketplace.json, and hooks.json
# against the rules defined in CLAUDE.md and Anthropic's skill guide.
#
# Usage: ./tests/validate-plugins.sh
# Exit codes: 0 = all pass, 1 = failures found, 2 = missing dependency

set -euo pipefail

# ---------------------------------------------------------------------------
# Colors & formatting
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ---------------------------------------------------------------------------
# Counters & collection arrays
# ---------------------------------------------------------------------------
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
SKIP_COUNT=0
FAILURES=()
WARNINGS=()
SKIPS=()
LABEL_PAD="  " # 2-space indent for dot lines
DOT_COL=0
DOT_MAX=70

wrap_if_needed() {
  if [ "$DOT_COL" -ge "$DOT_MAX" ]; then
    printf "\n%s" "$LABEL_PAD"
    DOT_COL=0
  fi
}

dot_pass() {
  wrap_if_needed
  printf "${GREEN}.${RESET}"
  PASS_COUNT=$((PASS_COUNT + 1))
  DOT_COL=$((DOT_COL + 1))
}

dot_fail() {
  wrap_if_needed
  printf "${RED}F${RESET}"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  FAILURES+=("$1")
  DOT_COL=$((DOT_COL + 1))
}

dot_warn() {
  wrap_if_needed
  printf "${YELLOW}W${RESET}"
  WARN_COUNT=$((WARN_COUNT + 1))
  WARNINGS+=("$1")
  DOT_COL=$((DOT_COL + 1))
}

dot_skip() {
  wrap_if_needed
  printf "${CYAN}*${RESET}"
  SKIP_COUNT=$((SKIP_COUNT + 1))
  if [ -n "${1:-}" ]; then SKIPS+=("$1"); fi
  DOT_COL=$((DOT_COL + 1))
}

newline_if_needed() {
  if [ "$DOT_COL" -gt 0 ]; then printf "\n"; DOT_COL=0; fi
}

# ---------------------------------------------------------------------------
# Resolve repo root (script lives in tests/)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGINS_DIR="$REPO_ROOT/plugins"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
if ! command -v jq &>/dev/null; then
  printf "${RED}Error: jq is required but not installed.${RESET}\n"
  printf "Install with: brew install jq (macOS) or apt install jq (Linux)\n"
  exit 2
fi

printf "${BOLD}Plugin Structural Validation${RESET}\n\n"

# ---------------------------------------------------------------------------
# Helper: extract YAML frontmatter value from SKILL.md
# Extracts only text between the first pair of --- delimiters, then greps
# for the key. This prevents false matches from code blocks in the body.
# ---------------------------------------------------------------------------
extract_frontmatter() {
  local file="$1"
  awk 'BEGIN{found=0} {gsub(/\r/,"")} /^---[[:space:]]*$/{found++; next} found==1{print} found>=2{exit}' "$file"
}

get_frontmatter_value() {
  local file="$1"
  local key="$2"
  extract_frontmatter "$file" | grep -E "^${key}:" | head -1 | sed -E "s/^${key}:[[:space:]]*//; s/^[\"'](.*)[\"']$/\1/"
}

# ===========================================================================
# A. plugin.json Validation
# ===========================================================================
printf "${CYAN}plugin.json — Plugin manifests${RESET}\n${LABEL_PAD}"

for plugin_dir in "$PLUGINS_DIR"/*/; do
  plugin_name="$(basename "$plugin_dir")"
  plugin_json="$plugin_dir/.claude-plugin/plugin.json"

  # P01: plugin.json exists
  if [ ! -f "$plugin_json" ]; then
    dot_fail "P01 [$plugin_name]: .claude-plugin/plugin.json missing"
    continue
  fi
  dot_pass

  # P02: Valid JSON
  if ! jq empty "$plugin_json" 2>/dev/null; then
    dot_fail "P02 [$plugin_name]: plugin.json is not valid JSON"
    continue
  fi
  dot_pass

  # P03: Has name field
  pj_name="$(jq -r '.name // empty' "$plugin_json")"
  if [ -z "$pj_name" ]; then
    dot_fail "P03 [$plugin_name]: Missing 'name' field"
  else
    dot_pass
  fi

  # P04: Has description field
  pj_desc="$(jq -r '.description // empty' "$plugin_json")"
  if [ -z "$pj_desc" ]; then
    dot_fail "P04 [$plugin_name]: Missing 'description' field"
  else
    dot_pass
  fi

  # P05: Has version field
  pj_version="$(jq -r '.version // empty' "$plugin_json")"
  if [ -z "$pj_version" ]; then
    dot_fail "P05 [$plugin_name]: Missing 'version' field"
  else
    dot_pass
  fi

  # P06: Version is valid semver (X.Y.Z)
  if [ -n "$pj_version" ]; then
    if echo "$pj_version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      dot_pass
    else
      dot_fail "P06 [$plugin_name]: Version '$pj_version' is not valid semver (expected X.Y.Z)"
    fi
  fi

  # P07: Name matches directory name
  if [ -n "$pj_name" ]; then
    if [ "$pj_name" = "$plugin_name" ]; then
      dot_pass
    else
      dot_fail "P07 [$plugin_name]: Name '$pj_name' does not match directory '$plugin_name'"
    fi
  fi

  # P08: Name is kebab-case
  if [ -n "$pj_name" ]; then
    if echo "$pj_name" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
      dot_pass
    else
      dot_fail "P08 [$plugin_name]: Name '$pj_name' is not kebab-case"
    fi
  fi

  # P09: .claude-plugin/ directory contains only plugin.json
  extra_files="$(ls "$plugin_dir/.claude-plugin/" 2>/dev/null | grep -v '^plugin.json$' || true)"
  if [ -n "$extra_files" ]; then
    dot_warn "P09 [$plugin_name]: .claude-plugin/ contains extra files: $extra_files"
  else
    dot_pass
  fi
done

# ===========================================================================
# B. SKILL.md Validation
# ===========================================================================
newline_if_needed
printf "${CYAN}SKILL.md — Skill definitions & frontmatter${RESET}\n${LABEL_PAD}"

for plugin_dir in "$PLUGINS_DIR"/*/; do
  plugin_name="$(basename "$plugin_dir")"
  skills_dir="$plugin_dir/skills"

  # Skip plugins with no skills directory
  if [ ! -d "$skills_dir" ]; then
    if [ -d "$plugin_dir/commands" ]; then
      dot_warn "$plugin_name: Uses 'commands/' instead of 'skills/' (non-standard)"
    else
      dot_skip "$plugin_name: No skills/ directory (hooks-only plugin)"
    fi
    continue
  fi

  # S11: Every direct child of skills/ has a SKILL.md
  for skill_folder in "$skills_dir"/*/; do
    [ -d "$skill_folder" ] || continue
    skill_name="$(basename "$skill_folder")"
    skill_file="$skill_folder/SKILL.md"

    # S01: SKILL.md exists (exact case)
    if [ ! -f "$skill_file" ]; then
      dot_fail "S01 [$plugin_name/$skill_name]: SKILL.md missing"
      # Check for case-insensitive match
      alt="$(find "$skill_folder" -maxdepth 1 -iname 'skill.md' 2>/dev/null | head -1)"
      if [ -n "$alt" ]; then
        dot_fail "S01 [$plugin_name/$skill_name]: Found '$(basename "$alt")' — must be exactly 'SKILL.md'"
      fi
      continue
    fi
    dot_pass

    # S02: Has YAML frontmatter (--- delimiters)
    first_line="$(awk 'NR==1{gsub(/\r/,""); gsub(/[[:space:]]*$/,""); print; exit}' "$skill_file")"
    if [ "$first_line" != "---" ]; then
      dot_fail "S02 [$plugin_name/$skill_name]: Missing YAML frontmatter (first line must be '---')"
      continue
    fi
    closing="$(awk '{gsub(/\r/,"")} NR>1 && /^---[[:space:]]*$/{print NR; exit}' "$skill_file")"
    if [ -z "$closing" ]; then
      dot_fail "S02 [$plugin_name/$skill_name]: Missing closing '---' delimiter"
      continue
    fi
    dot_pass

    # S03: name field present
    sk_name="$(get_frontmatter_value "$skill_file" "name")"
    if [ -z "$sk_name" ]; then
      dot_fail "S03 [$plugin_name/$skill_name]: Missing 'name' field in frontmatter"
    else
      dot_pass
    fi

    # S04: name is kebab-case
    if [ -n "$sk_name" ]; then
      if echo "$sk_name" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
        dot_pass
      else
        dot_fail "S04 [$plugin_name/$skill_name]: Name '$sk_name' is not kebab-case"
      fi
    fi

    # S05: name matches parent folder name
    if [ -n "$sk_name" ]; then
      if [ "$sk_name" = "$skill_name" ]; then
        dot_pass
      else
        dot_fail "S05 [$plugin_name/$skill_name]: Name '$sk_name' does not match folder '$skill_name'"
      fi
    fi

    # S06: description field present
    sk_desc="$(get_frontmatter_value "$skill_file" "description")"
    if [ -z "$sk_desc" ]; then
      dot_fail "S06 [$plugin_name/$skill_name]: Missing 'description' in frontmatter"
    else
      dot_pass
    fi

    # S06b: description is not a YAML multiline indicator
    if [ -n "$sk_desc" ]; then
      if [ "$sk_desc" = ">" ] || [ "$sk_desc" = "|" ] || [ "$sk_desc" = ">-" ] || [ "$sk_desc" = "|-" ]; then
        dot_warn "S06b [$plugin_name/$skill_name]: Description uses YAML multiline syntax ('$sk_desc') — parser may not capture full text"
      fi
    fi

    # S07: description under 1024 chars
    if [ -n "$sk_desc" ]; then
      desc_len="${#sk_desc}"
      if [ "$desc_len" -le 1024 ]; then
        dot_pass
      else
        dot_fail "S07 [$plugin_name/$skill_name]: Description too long ($desc_len chars, max 1024)"
      fi
    fi

    # S08: description has no XML angle brackets
    if [ -n "$sk_desc" ]; then
      if echo "$sk_desc" | grep -qE '[<>]'; then
        dot_fail "S08 [$plugin_name/$skill_name]: Description contains angle brackets (<>)"
      else
        dot_pass
      fi
    fi

    # S09: No README.md in skill folder
    if [ -f "$skill_folder/README.md" ]; then
      dot_fail "S09 [$plugin_name/$skill_name]: README.md found in skill folder (not allowed)"
    else
      dot_pass
    fi

    # S10: name doesn't contain "claude" or "anthropic"
    if [ -n "$sk_name" ]; then
      sk_name_lower="$(echo "$sk_name" | tr '[:upper:]' '[:lower:]')"
      if echo "$sk_name_lower" | grep -qE '(claude|anthropic)'; then
        dot_fail "S10 [$plugin_name/$skill_name]: Name contains reserved word 'claude' or 'anthropic'"
      else
        dot_pass
      fi
    fi

    # S13: allowed-tools format check (warning)
    at_line="$(extract_frontmatter "$skill_file" | grep -E '^allowed-tools:' | head -1 || true)"
    if [ -n "$at_line" ]; then
      at_value="$(echo "$at_line" | sed 's/^allowed-tools:[[:space:]]*//')"
      # Non-empty inline value should start with [ (YAML list form has empty value)
      if [ -n "$at_value" ] && ! echo "$at_value" | grep -qE '^\['; then
        dot_warn "S13 [$plugin_name/$skill_name]: allowed-tools value does not look like a YAML array"
      else
        dot_pass
      fi
    fi

  done
done

# ===========================================================================
# B2. Cross-plugin skill name uniqueness
# ===========================================================================
newline_if_needed
printf "${CYAN}skill names — Cross-plugin uniqueness${RESET}\n${LABEL_PAD}"

all_sk_names=()
all_sk_owners=()
for plugin_dir in "$PLUGINS_DIR"/*/; do
  plugin_name="$(basename "$plugin_dir")"
  skills_dir="$plugin_dir/skills"
  [ -d "$skills_dir" ] || continue
  for skill_folder in "$skills_dir"/*/; do
    [ -d "$skill_folder" ] || continue
    skill_file="$skill_folder/SKILL.md"
    [ -f "$skill_file" ] || continue
    sk_name="$(get_frontmatter_value "$skill_file" "name")"
    [ -z "$sk_name" ] && sk_name="$(basename "$skill_folder")"
    dup_found=""
    for seen in ${all_sk_names[@]+"${all_sk_names[@]}"}; do
      if [ "$seen" = "$sk_name" ]; then
        # Find which plugin owns the first occurrence
        i=0
        for sn in "${all_sk_names[@]}"; do
          if [ "$sn" = "$sk_name" ]; then break; fi
          i=$((i + 1))
        done
        dot_fail "S12: Duplicate skill name '$sk_name' in '$plugin_name' (also in '${all_sk_owners[$i]}')"
        dup_found=1
        break
      fi
    done
    if [ -z "$dup_found" ]; then
      all_sk_names+=("$sk_name")
      all_sk_owners+=("$plugin_name")
      dot_pass
    fi
  done
done

# ===========================================================================
# C. Marketplace Consistency
# ===========================================================================
newline_if_needed
printf "${CYAN}marketplace — Registry consistency${RESET}\n${LABEL_PAD}"

if [ ! -f "$MARKETPLACE" ]; then
  dot_fail "M01: marketplace.json not found at .claude-plugin/marketplace.json"
else
  if ! jq empty "$MARKETPLACE" 2>/dev/null; then
    dot_fail "M01: marketplace.json is not valid JSON"
  else
    dot_pass

    # M07: Top-level 'name' field
    mp_top_name="$(jq -r '.name // empty' "$MARKETPLACE")"
    if [ -z "$mp_top_name" ]; then
      dot_fail "M07: marketplace.json missing top-level 'name' field"
    else
      dot_pass
    fi

    # M08: Top-level 'owner.name' field
    mp_owner_name="$(jq -r '.owner.name // empty' "$MARKETPLACE")"
    if [ -z "$mp_owner_name" ]; then
      dot_fail "M08: marketplace.json missing 'owner.name' field"
    else
      dot_pass
    fi

    # Build arrays for comparison
    mp_names=()
    while IFS= read -r name; do
      mp_names+=("$name")
    done < <(jq -r '.plugins[].name' "$MARKETPLACE")

    dir_names=()
    for d in "$PLUGINS_DIR"/*/; do
      dir_names+=("$(basename "$d")")
    done

    # M06: No duplicate names in marketplace
    if [ "${#mp_names[@]}" -gt 0 ]; then
      seen_names=()
      for mp_name in "${mp_names[@]}"; do
        for seen in ${seen_names[@]+"${seen_names[@]}"}; do
          if [ "$seen" = "$mp_name" ]; then
            dot_fail "M06: Duplicate marketplace entry '$mp_name'"
            mp_name=""
            break
          fi
        done
        if [ -n "$mp_name" ]; then
          seen_names+=("$mp_name")
          dot_pass
        fi
      done
    fi

    # M02: Every plugins/*/ directory listed in marketplace
    for dir_name in ${dir_names[@]+"${dir_names[@]}"}; do
      found=0
      for mp_name in ${mp_names[@]+"${mp_names[@]}"}; do
        if [ "$mp_name" = "$dir_name" ]; then
          found=1
          break
        fi
      done
      if [ "$found" -eq 1 ]; then
        dot_pass
      else
        dot_fail "M02: Directory '$dir_name' not found in marketplace.json"
      fi
    done

    # M03/M04/M05: Directory exists, versions match, names match
    for mp_name in ${mp_names[@]+"${mp_names[@]}"}; do
      if [ ! -d "$PLUGINS_DIR/$mp_name" ]; then
        dot_fail "M03: Marketplace entry '$mp_name' has no plugins/$mp_name/ directory"
        continue
      fi
      dot_pass

      pj_file="$PLUGINS_DIR/$mp_name/.claude-plugin/plugin.json"
      if [ ! -f "$pj_file" ]; then
        dot_skip "M04: No plugin.json for '$mp_name'"
        continue
      fi

      mp_version="$(jq -r --arg n "$mp_name" '.plugins[] | select(.name == $n) | .version' "$MARKETPLACE")"
      pj_version="$(jq -r '.version // empty' "$pj_file")"
      if [ "$mp_version" = "$pj_version" ]; then
        dot_pass
      else
        dot_fail "M04: Version mismatch for '$mp_name': marketplace=$mp_version, plugin.json=$pj_version"
      fi

      pj_name="$(jq -r '.name // empty' "$pj_file")"
      if [ "$mp_name" = "$pj_name" ]; then
        dot_pass
      else
        dot_fail "M05: Name mismatch for '$mp_name': marketplace='$mp_name', plugin.json='$pj_name'"
      fi

      # M09: Plugin entry has 'source' field
      mp_source="$(jq -r --arg n "$mp_name" '.plugins[] | select(.name == $n) | .source // empty' "$MARKETPLACE")"
      if [ -z "$mp_source" ]; then
        dot_fail "M09: Marketplace entry '$mp_name' missing 'source' field"
      else
        dot_pass
      fi
    done
  fi
fi

# ===========================================================================
# D. hooks.json Validation
# ===========================================================================
newline_if_needed
printf "${CYAN}hooks.json — Hook definitions & event names${RESET}\n${LABEL_PAD}"

hooks_found=0
KNOWN_EVENTS="SessionStart|InstructionsLoaded|UserPromptSubmit|PreToolUse|PermissionRequest|PostToolUse|PostToolUseFailure|Notification|SubagentStart|SubagentStop|Stop|StopFailure|TeammateIdle|TaskCompleted|ConfigChange|WorktreeCreate|WorktreeRemove|PreCompact|PostCompact|Elicitation|ElicitationResult|SessionEnd"
for plugin_dir in "$PLUGINS_DIR"/*/; do
  plugin_name="$(basename "$plugin_dir")"
  hooks_file="$plugin_dir/hooks/hooks.json"

  [ -f "$hooks_file" ] || continue
  hooks_found=$((hooks_found + 1))

  # H01: Valid JSON
  if ! jq empty "$hooks_file" 2>/dev/null; then
    dot_fail "H01 [$plugin_name]: hooks.json is not valid JSON"
    continue
  fi
  dot_pass

  # H02: Has hooks top-level key
  has_hooks="$(jq 'has("hooks")' "$hooks_file")"
  if [ "$has_hooks" = "true" ]; then
    dot_pass
  else
    dot_fail "H02 [$plugin_name]: Missing 'hooks' top-level key"
    continue
  fi

  # H03: Hook event names are valid
  while IFS= read -r event_name; do
    if echo "$event_name" | grep -qE "^($KNOWN_EVENTS)$"; then
      dot_pass
    else
      dot_fail "H03 [$plugin_name]: Unknown hook event '$event_name' (expected: $KNOWN_EVENTS)"
    fi
  done < <(jq -r '.hooks | keys[]' "$hooks_file")

  # H04: Each hook handler has a valid 'type' field
  KNOWN_TYPES="command|http|prompt|agent"
  while IFS= read -r event_name; do
    handler_count=$(jq -r --arg e "$event_name" '.hooks[$e] | length' "$hooks_file")
    for ((gi=0; gi<handler_count; gi++)); do
      inner_count=$(jq -r --arg e "$event_name" --argjson i "$gi" '.hooks[$e][$i].hooks | length' "$hooks_file")
      for ((hi=0; hi<inner_count; hi++)); do
        hook_type=$(jq -r --arg e "$event_name" --argjson i "$gi" --argjson j "$hi" \
          '.hooks[$e][$i].hooks[$j].type // empty' "$hooks_file")
        if [ -z "$hook_type" ]; then
          dot_fail "H04 [$plugin_name]: Hook handler in '$event_name'[$gi][$hi] missing 'type' field"
        elif echo "$hook_type" | grep -qE "^($KNOWN_TYPES)$"; then
          dot_pass
        else
          dot_fail "H04 [$plugin_name]: Hook handler in '$event_name' has unknown type '$hook_type' (expected: command, http, prompt, agent)"
        fi
      done
    done
  done < <(jq -r '.hooks | keys[]' "$hooks_file")
done

if [ "$hooks_found" -eq 0 ]; then
  dot_skip "No hooks.json files found"
fi

# ===========================================================================
# Failures & Warnings
# ===========================================================================
newline_if_needed

print_section() {
  local color="$1" title="$2"
  shift 2
  if [ "$#" -gt 0 ]; then
    printf "\n${color}${BOLD}${title}:${RESET}\n"
    local i=1
    for item in "$@"; do
      printf "  ${color}%d)${RESET} %s\n" "$i" "$item"
      i=$((i + 1))
    done
  fi
}

print_section "$RED" "Failures" ${FAILURES[@]+"${FAILURES[@]}"}
print_section "$YELLOW" "Warnings" ${WARNINGS[@]+"${WARNINGS[@]}"}
print_section "$CYAN" "Skipped" ${SKIPS[@]+"${SKIPS[@]}"}

# ===========================================================================
# Summary
# ===========================================================================
total=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT + SKIP_COUNT))
printf "\n%d checks: ${GREEN}%d passed${RESET}" "$total" "$PASS_COUNT"
if [ "$FAIL_COUNT" -gt 0 ]; then printf ", ${RED}%d failed${RESET}" "$FAIL_COUNT"; fi
if [ "$WARN_COUNT" -gt 0 ]; then printf ", ${YELLOW}%d warnings${RESET}" "$WARN_COUNT"; fi
if [ "$SKIP_COUNT" -gt 0 ]; then printf ", ${CYAN}%d skipped${RESET}" "$SKIP_COUNT"; fi
printf "\n"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
else
  exit 0
fi
