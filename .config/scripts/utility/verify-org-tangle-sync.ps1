# Re-tangle curated .org sources and report hash drift.
# Usage:
#   .\verify-org-tangle-sync.ps1 -ReadOnly         # compare only; restore disk files (default)
#   .\verify-org-tangle-sync.ps1 -ReadOnly:$false  # re-tangle in place (fix drift on disk)
#   .\verify-org-tangle-sync.ps1 -ConfigDir $env:USERPROFILE\.config

param(
    [string]$ConfigDir = "$env:USERPROFILE\.config",

    # Hash on-disk files vs what .org would produce, then restore originals.
    [switch]$ReadOnly = $true
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\_lib\config-paths.ps1')

$emacsExe = Get-EmacsExecutable -Name emacs
if (-not $emacsExe) { Write-Error 'Emacs not found.'; exit 1 }

if ($ReadOnly) {
    Write-Host 'Read-only drift check (on-disk files will be restored after compare).' -ForegroundColor Cyan
}

$orgOutputs = Get-ConfigOrgDriftMap
$driftAll = @()

foreach ($orgRel in $orgOutputs.Keys) {
    $orgPath = Join-Path $ConfigDir $orgRel
    if (-not (Test-Path -LiteralPath $orgPath)) { continue }

    $before = @{}
    $backups = [System.Collections.Generic.List[object]]::new()
    $backupRoot = $null

    if ($ReadOnly) {
        $backupRoot = Join-Path $env:TEMP ("config-drift-check-$([guid]::NewGuid().ToString('N'))")
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    }

    foreach ($out in $orgOutputs[$orgRel]) {
        $full = Join-Path $ConfigDir $out
        if (Test-Path -LiteralPath $full) {
            $before[$out] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
            if ($ReadOnly) {
                $bak = Join-Path $backupRoot $out
                $bakDir = Split-Path -Parent $bak
                if ($bakDir) { New-Item -ItemType Directory -Path $bakDir -Force | Out-Null }
                Copy-Item -LiteralPath $full -Destination $bak -Force
                $backups.Add([pscustomobject]@{ Dest = $full; Backup = $bak; Existed = $true })
            }
        } elseif ($ReadOnly) {
            $backups.Add([pscustomobject]@{ Dest = $full; Backup = $null; Existed = $false })
        }
    }

    try {
        Write-Host "Checking $orgRel..." -NoNewline
        $text = Invoke-EmacsOrgTangle -EmacsExe $emacsExe -OrgPath $orgPath
        if ($text -notmatch 'Tangled \d+ code block') {
            Write-Host ' FAIL (tangle)' -ForegroundColor Red
            continue
        }

        if ($orgRel -eq 'kanata\kanata.org') {
            Repair-KanataTangledFiles -KanataDir (Join-Path $ConfigDir 'kanata')
        }

        $drifted = @()
        foreach ($out in $orgOutputs[$orgRel]) {
            $full = Join-Path $ConfigDir $out
            if (-not (Test-Path -LiteralPath $full)) { continue }
            $after = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
            if ($null -ne $before[$out] -and $before[$out] -ne $after) { $drifted += $out }
        }

        if ($drifted.Count) {
            Write-Host ' DRIFT' -ForegroundColor Yellow
            foreach ($d in $drifted) { $driftAll += "$orgRel -> $d" }
        } else {
            Write-Host ' OK' -ForegroundColor Green
        }
    } finally {
        if ($ReadOnly) {
            foreach ($entry in $backups) {
                if ($entry.Existed) {
                    Copy-Item -LiteralPath $entry.Backup -Destination $entry.Dest -Force
                } elseif (Test-Path -LiteralPath $entry.Dest) {
                    Remove-Item -LiteralPath $entry.Dest -Force
                }
            }
            if ($backupRoot -and (Test-Path -LiteralPath $backupRoot)) {
                Remove-Item -LiteralPath $backupRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Write-Host ''
if ($driftAll.Count) {
    if ($ReadOnly) {
        Write-Host 'Drift detected (disk differs from .org; files were restored):' -ForegroundColor Yellow
    } else {
        Write-Host 'Out of sync — outputs re-tangled on disk. Reload affected apps if needed.' -ForegroundColor Yellow
    }
    $driftAll | ForEach-Object { Write-Host "  $_" }
    if ($ReadOnly) {
        Write-Host 'Fix: edit .org then run  tangle all  (or tangle <stem>)' -ForegroundColor DarkYellow
    }
    exit 1
}

Write-Host 'All checked configs match their .org sources.' -ForegroundColor Green
exit 0
