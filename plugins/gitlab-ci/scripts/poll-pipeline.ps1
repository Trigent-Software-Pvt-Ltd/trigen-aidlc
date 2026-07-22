#Requires -Version 5.1
<#
.SYNOPSIS
    Poll a GitLab CI pipeline until it reaches a terminal state.

.DESCRIPTION
    Polls glab ci get at a configurable interval until the pipeline succeeds, fails,
    is canceled, or the timeout is reached. Prints status updates to stderr and
    final JSON to stdout.

.PARAMETER Branch
    Branch name to monitor.

.PARAMETER PipelineId
    Specific pipeline ID to monitor.

.PARAMETER Interval
    Poll interval in seconds (default: 30).

.PARAMETER Timeout
    Max wait time in seconds (default: 1800 = 30 minutes).

.PARAMETER Repo
    GitLab project path (e.g., group/project) for -R flag.

.EXAMPLE
    .\poll-pipeline.ps1 -Branch main -Interval 15 -Timeout 120
    .\poll-pipeline.ps1 -PipelineId 12345 -Repo "group/project"

.NOTES
    Exit codes: 0=success, 1=failed, 2=canceled/skipped, 3=timeout, 4=error
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Branch,

    [Parameter()]
    [string]$PipelineId,

    [Parameter()]
    [int]$Interval = 30,

    [Parameter()]
    [int]$Timeout = 1800,

    [Parameter()]
    [string]$Repo
)

$ErrorActionPreference = "Stop"

if (-not $Branch -and -not $PipelineId) {
    Write-Error "Either -Branch or -PipelineId is required."
    exit 4
}

function Build-GlabArgs {
    $args = @("ci", "get", "-F", "json", "-d")
    if ($PipelineId) {
        $args += @("-p", $PipelineId)
    } elseif ($Branch) {
        $args += @("-b", $Branch)
    }
    if ($Repo) {
        $args += @("-R", $Repo)
    }
    return $args
}

$glabArgs = Build-GlabArgs
$startTime = Get-Date

Write-Host "Polling pipeline (interval: ${Interval}s, timeout: ${Timeout}s)..." -ForegroundColor Cyan
Write-Host "Command: glab $($glabArgs -join ' ')" -ForegroundColor DarkGray
Write-Host ""

while ($true) {
    $elapsed = [int]((Get-Date) - $startTime).TotalSeconds

    if ($elapsed -ge $Timeout) {
        Write-Host "Timeout reached after ${elapsed}s. Pipeline is still running." -ForegroundColor Yellow
        try {
            $json = & glab @glabArgs 2>$null
            if ($json) { Write-Output ($json -join "`n") }
        } catch {}
        exit 3
    }

    # Fetch pipeline status
    try {
        $jsonLines = & glab @glabArgs 2>$null
        if ($LASTEXITCODE -ne 0) { throw "glab exited with code $LASTEXITCODE" }
        $json = $jsonLines -join "`n"
    } catch {
        Write-Host "Error: glab command failed. $_" -ForegroundColor Red
        exit 4
    }

    # Parse JSON
    try {
        $pipeline = $json | ConvertFrom-Json
        $status = $pipeline.status
        $pid_val = $pipeline.id
    } catch {
        $status = "unknown"
        $pid_val = "?"
    }

    $minutes = [math]::Floor($elapsed / 60)
    $seconds = $elapsed % 60
    $elapsedDisplay = "{0}m {1}s" -f $minutes, $seconds

    $color = switch ($status) {
        "success"  { "Green" }
        "failed"   { "Red" }
        "running"  { "Cyan" }
        "canceled" { "Yellow" }
        "manual"   { "Yellow" }
        default    { "Gray" }
    }
    Write-Host "[$elapsedDisplay] Pipeline #${pid_val}: $status" -ForegroundColor $color

    switch ($status) {
        "success" {
            Write-Output $json
            exit 0
        }
        "failed" {
            Write-Output $json
            exit 1
        }
        { $_ -in @("canceled", "skipped") } {
            Write-Output $json
            exit 2
        }
        "manual" {
            Write-Host "Pipeline is waiting on a manual job." -ForegroundColor Yellow
            Write-Output $json
            exit 2
        }
        { $_ -in @("created", "waiting_for_resource", "preparing", "pending", "running", "scheduled") } {
            # Still in progress, keep polling
        }
        "unknown" {
            Write-Host "Warning: could not parse pipeline status." -ForegroundColor Yellow
        }
        default {
            Write-Host "Warning: unexpected status '$status'." -ForegroundColor Yellow
        }
    }

    Start-Sleep -Seconds $Interval
}
