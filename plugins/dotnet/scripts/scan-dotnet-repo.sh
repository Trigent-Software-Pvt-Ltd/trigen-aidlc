#!/usr/bin/env bash
# scan-dotnet-repo.sh — Scans a .NET repository and outputs a JSON summary.
# Usage: ./scan-dotnet-repo.sh [--repo-root PATH]
# Output: JSON to stdout, progress/errors to stderr.

set -euo pipefail

REPO_ROOT="${1:-.}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"

log() { echo "[scan] $*" >&2; }

# ── helpers ───────────────────────────────────────────────────────────────────

extract_xml_value() {
  local file="$1" tag="$2"
  grep -oP "(?<=<${tag}>)[^<]+" "$file" 2>/dev/null | head -1 || true
}

file_contains() {
  local file="$1" pattern="$2"
  grep -qE "$pattern" "$file" 2>/dev/null && echo "true" || echo "false"
}

to_json_string() {
  # Escape for JSON
  echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# ── solution files ────────────────────────────────────────────────────────────

log "Scanning solution files..."
SLN_FILES=()
SLNX_FILES=()
while IFS= read -r f; do SLN_FILES+=("$f"); done < <(find "$REPO_ROOT" -maxdepth 3 -name "*.sln" ! -path "*/node_modules/*" 2>/dev/null | sort)
while IFS= read -r f; do SLNX_FILES+=("$f"); done < <(find "$REPO_ROOT" -maxdepth 3 -name "*.slnx" ! -path "*/node_modules/*" 2>/dev/null | sort)

sln_json="["
for f in "${SLN_FILES[@]:-}"; do
  [[ -z "$f" ]] && continue
  rel="${f#$REPO_ROOT/}"
  sln_json+="\"$(to_json_string "$rel")\","
done
sln_json="${sln_json%,}]"

slnx_json="["
for f in "${SLNX_FILES[@]:-}"; do
  [[ -z "$f" ]] && continue
  rel="${f#$REPO_ROOT/}"
  slnx_json+="\"$(to_json_string "$rel")\","
done
slnx_json="${slnx_json%,}]"

# ── project files ─────────────────────────────────────────────────────────────

log "Scanning project files..."
PROJ_FILES=()
while IFS= read -r f; do PROJ_FILES+=("$f"); done < <(find "$REPO_ROOT" \( -name "*.csproj" -o -name "*.fsproj" \) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | sort)

projects_json="["
for proj in "${PROJ_FILES[@]:-}"; do
  [[ -z "$proj" ]] && continue
  rel="${proj#$REPO_ROOT/}"
  name="$(basename "$proj")"
  lang="csharp"
  [[ "$proj" == *.fsproj ]] && lang="fsharp"

  tf=$(extract_xml_value "$proj" "TargetFramework")
  tfs=$(extract_xml_value "$proj" "TargetFrameworks")
  sdk=$(grep -oP 'Sdk="\K[^"]+' "$proj" 2>/dev/null | head -1 || true)

  # Detect type
  proj_type="library"
  if grep -qE "Microsoft\.NET\.Sdk\.Web|Microsoft\.AspNetCore\." "$proj" 2>/dev/null; then
    proj_type="webapi"
  fi
  if grep -qE "Microsoft\.NET\.Sdk\.Functions|Microsoft\.Azure\.Functions\.Worker" "$proj" 2>/dev/null; then
    proj_type="functions"
    if grep -q "Microsoft.NET.Sdk.Functions" "$proj" 2>/dev/null; then
      proj_type="functions-inprocess"
    else
      proj_type="functions-isolated"
    fi
  fi
  if grep -qiE "xunit|nunit|mstest|Xunit|NUnit|MSTest" "$proj" 2>/dev/null; then
    proj_type="test"
  fi

  # Packages
  pkg_list=$(grep -oP '(?<=PackageReference Include=")[^"]+' "$proj" 2>/dev/null | sort | tr '\n' ',' | sed 's/,$//' || true)
  pkg_versions=$(grep -oP 'PackageReference Include="[^"]+" Version="[^"]+"' "$proj" 2>/dev/null | sed 's/PackageReference Include="\([^"]*\)" Version="\([^"]*\)"/\1:\2/' | sort | tr '\n' ',' | sed 's/,$//' || true)

  has_swashbuckle=$(file_contains "$proj" "Swashbuckle")
  has_nswag=$(file_contains "$proj" "NSwag")
  has_scalar=$(file_contains "$proj" "Scalar")
  has_ef=$(file_contains "$proj" "EntityFrameworkCore")
  has_npgsql=$(file_contains "$proj" "Npgsql")
  has_masstransit=$(file_contains "$proj" "MassTransit")
  has_otel=$(file_contains "$proj" "OpenTelemetry")
  has_serilog=$(file_contains "$proj" "Serilog")

  projects_json+="{\"path\":\"$(to_json_string "$rel")\",\"name\":\"$(to_json_string "$name")\",\"language\":\"$lang\",\"sdk\":\"$(to_json_string "$sdk")\",\"targetFramework\":\"$(to_json_string "$tf")\",\"targetFrameworks\":\"$(to_json_string "$tfs")\",\"type\":\"$proj_type\",\"packages\":\"$(to_json_string "$pkg_list")\",\"packageVersions\":\"$(to_json_string "$pkg_versions")\",\"hasSwashbuckle\":$has_swashbuckle,\"hasNSwag\":$has_nswag,\"hasScalar\":$has_scalar,\"hasEfCore\":$has_ef,\"hasNpgsql\":$has_npgsql,\"hasMassTransit\":$has_masstransit,\"hasOpenTelemetry\":$has_otel,\"hasSerilog\":$has_serilog},"
done
projects_json="${projects_json%,}]"

# ── global.json ───────────────────────────────────────────────────────────────

log "Scanning global.json..."
GLOBAL_JSON=""
GLOBAL_JSON_SDK=""
GLOBAL_JSON_ROLL_FORWARD=""
if [[ -f "$REPO_ROOT/global.json" ]]; then
  GLOBAL_JSON="$(cat "$REPO_ROOT/global.json")"
  GLOBAL_JSON_SDK=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$REPO_ROOT/global.json" 2>/dev/null | head -1 || true)
  GLOBAL_JSON_ROLL_FORWARD=$(grep -oP '"rollForward"\s*:\s*"\K[^"]+' "$REPO_ROOT/global.json" 2>/dev/null | head -1 || true)
fi

# ── central package management ────────────────────────────────────────────────

log "Scanning package management..."
HAS_CPM="false"
CPM_FILE=""
if [[ -f "$REPO_ROOT/Directory.Packages.props" ]]; then
  CPM_FILE="Directory.Packages.props"
  if grep -qiE "ManagePackageVersionsCentrally.*true" "$REPO_ROOT/Directory.Packages.props" 2>/dev/null; then
    HAS_CPM="true"
  fi
fi

HAS_DBPROPS="false"
if [[ -f "$REPO_ROOT/Directory.Build.props" ]]; then HAS_DBPROPS="true"; fi

HAS_DBTARGETS="false"
if [[ -f "$REPO_ROOT/Directory.Build.targets" ]]; then HAS_DBTARGETS="true"; fi

TF_IN_DBPROPS="false"
if [[ "$HAS_DBPROPS" == "true" ]]; then
  TF_IN_DBPROPS=$(file_contains "$REPO_ROOT/Directory.Build.props" "<TargetFramework")
fi

# ── dockerfiles ───────────────────────────────────────────────────────────────

log "Scanning Dockerfiles..."
dockerfiles_json="["
while IFS= read -r df; do
  [[ -z "$df" ]] && continue
  rel="${df#$REPO_ROOT/}"
  dotnet_images=$(grep -oP 'FROM\s+mcr\.microsoft\.com/dotnet/[^:\s]+:[^\s]+' "$df" 2>/dev/null | sort | tr '\n' '|' | sed 's/|$//' || true)
  dockerfiles_json+="{\"path\":\"$(to_json_string "$rel")\",\"dotnetImages\":\"$(to_json_string "$dotnet_images")\"},"
done < <(find "$REPO_ROOT" -name "Dockerfile" -o -name "Dockerfile.*" 2>/dev/null | sort)
dockerfiles_json="${dockerfiles_json%,}]"

# ── gitlab ci ─────────────────────────────────────────────────────────────────

log "Scanning GitLab CI..."
CI_FILE=""
CI_DOTNET_IMAGES=""
CI_DOTNET_VARS=""
if [[ -f "$REPO_ROOT/.gitlab-ci.yml" ]]; then
  CI_FILE=".gitlab-ci.yml"
  CI_DOTNET_IMAGES=$(grep -oP 'mcr\.microsoft\.com/dotnet/[^:\s"]+:[^\s"]+' "$REPO_ROOT/.gitlab-ci.yml" 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//' || true)
  CI_DOTNET_VARS=$(grep -oP '(DOTNET_VERSION|SDK_VERSION|DOTNET_SDK_VERSION)\s*:\s*\K[^\n]+' "$REPO_ROOT/.gitlab-ci.yml" 2>/dev/null | tr '\n' ',' | sed 's/,$//' || true)
fi

# ── azure functions ───────────────────────────────────────────────────────────

log "Scanning Azure Functions..."
host_jsons_json="["
while IFS= read -r hj; do
  [[ -z "$hj" ]] && continue
  rel="${hj#$REPO_ROOT/}"
  version=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$hj" 2>/dev/null | head -1 || true)
  host_jsons_json+="{\"path\":\"$(to_json_string "$rel")\",\"version\":\"$(to_json_string "$version")\"},"
done < <(find "$REPO_ROOT" -name "host.json" ! -path "*/.git/*" 2>/dev/null | sort)
host_jsons_json="${host_jsons_json%,}]"

# ── output ────────────────────────────────────────────────────────────────────

log "Scan complete."

cat <<EOF
{
  "repoRoot": "$(to_json_string "$REPO_ROOT")",
  "scannedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "solutionFiles": $sln_json,
  "slnxFiles": $slnx_json,
  "projects": $projects_json,
  "globalJson": {
    "exists": $([ -f "$REPO_ROOT/global.json" ] && echo "true" || echo "false"),
    "sdkVersion": "$(to_json_string "$GLOBAL_JSON_SDK")",
    "rollForward": "$(to_json_string "$GLOBAL_JSON_ROLL_FORWARD")"
  },
  "packageManagement": {
    "centralPackageManagement": $HAS_CPM,
    "directoryPackagesProps": "$(to_json_string "$CPM_FILE")",
    "directoryBuildProps": $HAS_DBPROPS,
    "directoryBuildTargets": $HAS_DBTARGETS,
    "targetFrameworkInBuildProps": $TF_IN_DBPROPS
  },
  "dockerfiles": $dockerfiles_json,
  "gitlabCi": {
    "file": "$(to_json_string "$CI_FILE")",
    "dotnetImages": "$(to_json_string "$CI_DOTNET_IMAGES")",
    "dotnetVariables": "$(to_json_string "$CI_DOTNET_VARS")"
  },
  "azureFunctions": {
    "hostJsonFiles": $host_jsons_json
  }
}
EOF
