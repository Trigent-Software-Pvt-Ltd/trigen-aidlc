#!/usr/bin/env bash
#
# check-version-bumped.sh - Fail if a plugin has changes but no version bump
#
# For every plugin whose files changed vs the merge target, verifies that:
#   - plugins/<name>/.claude-plugin/plugin.json#version was bumped vs base
#   - .claude-plugin/marketplace.json plugin entry's version was bumped vs base
#   - the two values agree
#
# Repo-root files (CONTRIBUTING.md, README.md, .gitlab-ci.yml, etc.) are
# exempt and do not require a version bump.
#
# Usage:
#   bash tests/check-version-bumped.sh
# Exit codes: 0 = pass, 1 = bumps missing, 2 = setup error.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

if ! command -v jq >/dev/null 2>&1; then
  printf "${RED}jq is required.${RESET}\n" >&2
  exit 2
fi

# Resolve base ref. In a GitLab MR pipeline,
# CI_MERGE_REQUEST_TARGET_BRANCH_NAME is set; locally fall back to main.
TARGET="${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-main}"

BASE_REF=""
for candidate in "origin/${TARGET}" "${TARGET}"; do
  if git rev-parse --verify --quiet "$candidate" >/dev/null 2>&1; then
    BASE_REF="$candidate"
    break
  fi
done

if [ -z "$BASE_REF" ]; then
  printf "${RED}Cannot resolve base ref (tried origin/%s and %s).${RESET}\n" "$TARGET" "$TARGET" >&2
  exit 2
fi

CHANGED=$(git diff --name-only "${BASE_REF}...HEAD" || true)
TOUCHED=$(printf '%s\n' "$CHANGED" | awk -F/ '/^plugins\// && NF>=2 { print $2 }' | sort -u)

if [ -z "$TOUCHED" ]; then
  printf "${GREEN}No plugin paths changed - version-bump check skipped.${RESET}\n"
  exit 0
fi

FAILED=0
for plugin in $TOUCHED; do
  pj="plugins/${plugin}/.claude-plugin/plugin.json"

  if [ ! -f "$pj" ]; then
    printf "${YELLOW}  [%s] plugin removed in this MR - skipping.${RESET}\n" "$plugin"
    continue
  fi

  current_pj_version=$(jq -r '.version // empty' "$pj")
  base_pj_version=$(git show "${BASE_REF}:${pj}" 2>/dev/null | jq -r '.version // empty' 2>/dev/null || true)

  if [ -z "$base_pj_version" ]; then
    printf "${GREEN}  [%s] new plugin (version %s) - OK${RESET}\n" "$plugin" "$current_pj_version"
    continue
  fi

  if [ "$current_pj_version" = "$base_pj_version" ]; then
    printf "${RED}  [%s] plugin.json#version not bumped (still %s)${RESET}\n" "$plugin" "$current_pj_version"
    FAILED=1
  else
    printf "${GREEN}  [%s] plugin.json: %s -> %s${RESET}\n" "$plugin" "$base_pj_version" "$current_pj_version"
  fi

  current_mp_version=$(jq -r --arg p "$plugin" '.plugins[] | select(.name==$p) | .version // empty' .claude-plugin/marketplace.json)
  base_mp_version=$(git show "${BASE_REF}:.claude-plugin/marketplace.json" 2>/dev/null | jq -r --arg p "$plugin" '.plugins[] | select(.name==$p) | .version // empty' 2>/dev/null || true)

  if [ -z "$base_mp_version" ]; then
    printf "${GREEN}  [%s] marketplace entry is new - OK${RESET}\n" "$plugin"
    continue
  fi

  if [ "$current_mp_version" = "$base_mp_version" ]; then
    printf "${RED}  [%s] marketplace.json entry not bumped (still %s)${RESET}\n" "$plugin" "$current_mp_version"
    FAILED=1
  fi

  if [ -n "$current_pj_version" ] && [ "$current_mp_version" != "$current_pj_version" ]; then
    printf "${RED}  [%s] marketplace.json (%s) and plugin.json (%s) versions disagree${RESET}\n" "$plugin" "$current_mp_version" "$current_pj_version"
    FAILED=1
  fi
done

if [ "$FAILED" -ne 0 ]; then
  printf "\n${RED}Version-bump check failed.${RESET}\n"
  printf "Every plugin you touched needs a matching version bump in both plugin.json and marketplace.json.\n"
  exit 1
fi

printf "\n${GREEN}Version-bump check passed.${RESET}\n"
exit 0
