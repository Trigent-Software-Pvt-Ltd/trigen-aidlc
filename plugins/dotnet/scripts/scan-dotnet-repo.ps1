# scan-dotnet-repo.ps1 — Scans a .NET repository and outputs a JSON summary.
# Usage: .\scan-dotnet-repo.ps1 [-RepoRoot <path>]
# Output: JSON to stdout, progress to Write-Host (stderr equivalent).
# Requires: PowerShell 7+

param(
    [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path $RepoRoot | Select-Object -ExpandProperty Path

function Log { param([string]$Msg); Write-Host "[scan] $Msg" -ForegroundColor Cyan }
function EscapeJson { param([string]$s); $s -replace '\\','\\' -replace '"','\"' }
function FileContains { param([string]$Path,[string]$Pattern); (Select-String -Path $Path -Pattern $Pattern -Quiet -ErrorAction SilentlyContinue) -eq $true }
function ExtractXmlValue { param([string]$Path,[string]$Tag); $m = Select-String -Path $Path -Pattern "<$Tag>([^<]+)</$Tag>" -ErrorAction SilentlyContinue; if ($m) { $m.Matches[0].Groups[1].Value } else { "" } }

# ── solution files ────────────────────────────────────────────────────────────

Log "Scanning solution files..."
$slnFiles  = Get-ChildItem -Path $RepoRoot -Recurse -Filter "*.sln"  -Depth 3 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName | Sort-Object
$slnxFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter "*.slnx" -Depth 3 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName | Sort-Object

$slnJson  = "[" + (($slnFiles  | ForEach-Object { """$(EscapeJson ($_.Replace($RepoRoot + [IO.Path]::DirectorySeparatorChar, '')))""" }) -join ",") + "]"
$slnxJson = "[" + (($slnxFiles | ForEach-Object { """$(EscapeJson ($_.Replace($RepoRoot + [IO.Path]::DirectorySeparatorChar, '')))""" }) -join ",") + "]"

# ── project files ─────────────────────────────────────────────────────────────

Log "Scanning project files..."
$projFiles = Get-ChildItem -Path $RepoRoot -Recurse -Include "*.csproj","*.fsproj" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } | Sort-Object FullName

$projectsJson = "[" + (($projFiles | ForEach-Object {
    $proj     = $_.FullName
    $rel      = $proj.Replace($RepoRoot + [IO.Path]::DirectorySeparatorChar, '')
    $name     = $_.Name
    $lang     = if ($_.Extension -eq ".fsproj") { "fsharp" } else { "csharp" }
    $content  = Get-Content $proj -Raw -ErrorAction SilentlyContinue

    $tf  = ExtractXmlValue -Path $proj -Tag "TargetFramework"
    $tfs = ExtractXmlValue -Path $proj -Tag "TargetFrameworks"
    $sdk = if ($content -match 'Sdk="([^"]+)"') { $Matches[1] } else { "" }

    $projType = "library"
    if ($content -match "Microsoft\.NET\.Sdk\.Web|Microsoft\.AspNetCore\.") { $projType = "webapi" }
    if ($content -match "Microsoft\.NET\.Sdk\.Functions") { $projType = "functions-inprocess" }
    elseif ($content -match "Microsoft\.Azure\.Functions\.Worker") { $projType = "functions-isolated" }
    if ($content -match "xunit|nunit|mstest" -and $projType -eq "library") { $projType = "test" }

    $pkgs = [regex]::Matches($content, 'PackageReference Include="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object | Select-Object -Unique
    $pkgList = $pkgs -join ","

    $pkgVersions = [regex]::Matches($content, 'PackageReference Include="([^"]+)"\s+Version="([^"]+)"') | ForEach-Object { "$($_.Groups[1].Value):$($_.Groups[2].Value)" } | Sort-Object
    $pkgVersionList = $pkgVersions -join ","

    $hasSwashbuckle  = ($content -match "Swashbuckle").ToString().ToLower()
    $hasNSwag        = ($content -match "NSwag").ToString().ToLower()
    $hasScalar       = ($content -match "Scalar").ToString().ToLower()
    $hasEf           = ($content -match "EntityFrameworkCore").ToString().ToLower()
    $hasNpgsql       = ($content -match "Npgsql").ToString().ToLower()
    $hasMassTransit  = ($content -match "MassTransit").ToString().ToLower()
    $hasOtel         = ($content -match "OpenTelemetry").ToString().ToLower()
    $hasSerilog      = ($content -match "Serilog").ToString().ToLower()

    "{""path"":""$(EscapeJson $rel)"",""name"":""$(EscapeJson $name)"",""language"":""$lang"",""sdk"":""$(EscapeJson $sdk)"",""targetFramework"":""$(EscapeJson $tf)"",""targetFrameworks"":""$(EscapeJson $tfs)"",""type"":""$projType"",""packages"":""$(EscapeJson $pkgList)"",""packageVersions"":""$(EscapeJson $pkgVersionList)"",""hasSwashbuckle"":$hasSwashbuckle,""hasNSwag"":$hasNSwag,""hasScalar"":$hasScalar,""hasEfCore"":$hasEf,""hasNpgsql"":$hasNpgsql,""hasMassTransit"":$hasMassTransit,""hasOpenTelemetry"":$hasOtel,""hasSerilog"":$hasSerilog}"
}) -join ",") + "]"

# ── global.json ───────────────────────────────────────────────────────────────

Log "Scanning global.json..."
$globalJsonPath = Join-Path $RepoRoot "global.json"
$globalExists   = Test-Path $globalJsonPath
$globalSdk      = ""
$globalRollFwd  = ""
if ($globalExists) {
    $gj = Get-Content $globalJsonPath -Raw
    if ($gj -match '"version"\s*:\s*"([^"]+)"') { $globalSdk = $Matches[1] }
    if ($gj -match '"rollForward"\s*:\s*"([^"]+)"') { $globalRollFwd = $Matches[1] }
}

# ── central package management ────────────────────────────────────────────────

Log "Scanning package management..."
$cpmPath     = Join-Path $RepoRoot "Directory.Packages.props"
$hasCpm      = "false"
$cpmFile     = ""
$dbPropsPath = Join-Path $RepoRoot "Directory.Build.props"
$dbTargPath  = Join-Path $RepoRoot "Directory.Build.targets"
$hasDbProps  = (Test-Path $dbPropsPath).ToString().ToLower()
$hasDbTarg   = (Test-Path $dbTargPath).ToString().ToLower()
$tfInDbProps = "false"
if (Test-Path $cpmPath) {
    $cpmFile = "Directory.Packages.props"
    if ((Get-Content $cpmPath -Raw) -match "ManagePackageVersionsCentrally.*true") { $hasCpm = "true" }
}
if (Test-Path $dbPropsPath) {
    if ((Get-Content $dbPropsPath -Raw) -match "<TargetFramework") { $tfInDbProps = "true" }
}

# ── dockerfiles ───────────────────────────────────────────────────────────────

Log "Scanning Dockerfiles..."
$dockerfiles = Get-ChildItem -Path $RepoRoot -Recurse -Include "Dockerfile","Dockerfile.*" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } | Sort-Object FullName
$dockerfilesJson = "[" + (($dockerfiles | ForEach-Object {
    $rel = $_.FullName.Replace($RepoRoot + [IO.Path]::DirectorySeparatorChar, '')
    $images = [regex]::Matches((Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue), 'FROM\s+(mcr\.microsoft\.com/dotnet/[^:\s]+:[^\s]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    "{""path"":""$(EscapeJson $rel)"",""dotnetImages"":""$(EscapeJson ($images -join '|'))""}"
}) -join ",") + "]"

# ── gitlab ci ─────────────────────────────────────────────────────────────────

Log "Scanning GitLab CI..."
$ciPath    = Join-Path $RepoRoot ".gitlab-ci.yml"
$ciFile    = ""
$ciImages  = ""
$ciVars    = ""
if (Test-Path $ciPath) {
    $ciFile   = ".gitlab-ci.yml"
    $ciRaw    = Get-Content $ciPath -Raw -ErrorAction SilentlyContinue
    $ciImages = ([regex]::Matches($ciRaw, 'mcr\.microsoft\.com/dotnet/[^:\s"]+:[^\s"]+') | ForEach-Object { $_.Value } | Sort-Object -Unique) -join ","
    $ciVars   = ([regex]::Matches($ciRaw, '(DOTNET_VERSION|SDK_VERSION|DOTNET_SDK_VERSION)\s*:\s*([^\n]+)') | ForEach-Object { "$($_.Groups[1].Value):$($_.Groups[2].Value.Trim())" }) -join ","
}

# ── azure functions ───────────────────────────────────────────────────────────

Log "Scanning Azure Functions..."
$hostJsons = Get-ChildItem -Path $RepoRoot -Recurse -Filter "host.json" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } | Sort-Object FullName
$hostJsonsJson = "[" + (($hostJsons | ForEach-Object {
    $rel = $_.FullName.Replace($RepoRoot + [IO.Path]::DirectorySeparatorChar, '')
    $ver = ""
    $raw = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($raw -match '"version"\s*:\s*"([^"]+)"') { $ver = $Matches[1] }
    "{""path"":""$(EscapeJson $rel)"",""version"":""$(EscapeJson $ver)""}"
}) -join ",") + "]"

# ── output ────────────────────────────────────────────────────────────────────

Log "Scan complete."

@"
{
  "repoRoot": "$(EscapeJson $RepoRoot)",
  "scannedAt": "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" -AsUTC)",
  "solutionFiles": $slnJson,
  "slnxFiles": $slnxJson,
  "projects": $projectsJson,
  "globalJson": {
    "exists": $($globalExists.ToString().ToLower()),
    "sdkVersion": "$(EscapeJson $globalSdk)",
    "rollForward": "$(EscapeJson $globalRollFwd)"
  },
  "packageManagement": {
    "centralPackageManagement": $hasCpm,
    "directoryPackagesProps": "$(EscapeJson $cpmFile)",
    "directoryBuildProps": $hasDbProps,
    "directoryBuildTargets": $hasDbTarg,
    "targetFrameworkInBuildProps": $tfInDbProps
  },
  "dockerfiles": $dockerfilesJson,
  "gitlabCi": {
    "file": "$(EscapeJson $ciFile)",
    "dotnetImages": "$(EscapeJson $ciImages)",
    "dotnetVariables": "$(EscapeJson $ciVars)"
  },
  "azureFunctions": {
    "hostJsonFiles": $hostJsonsJson
  }
}
"@
