# tangle-check-cron.ps1 — SHA256 drift check using .NET (no Get-FileHash dependency).
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File "%~f0"
param()

$ErrorActionPreference = 'Stop'

function Get-Hash($p) {
    $s = [System.IO.File]::OpenRead($p)
    try {
        $b = [System.Security.Cryptography.SHA256]::Create().ComputeHash($s)
        return -join ($b | ForEach-Object { $_.ToString('x2') })
    } finally { $s.Close() }
}

# Dot-source config paths for Get-ConfigOrgDriftMap, Invoke-EmacsOrgTangle, Repair-KanataTangledFiles
. "$env:USERPROFILE\.config\scripts\powershell\_lib\config-paths.ps1"

$emacsExe = Get-EmacsExecutable -Name emacs
if (-not $emacsExe) { Write-Error 'Emacs not found.'; exit 1 }

Write-Host "Emacs: $emacsExe"
Write-Host ''

$orgOutputs = Get-ConfigOrgDriftMap
$driftAll = @()
$skipped = @()

foreach ($orgRel in $orgOutputs.Keys) {
    $orgPath = Join-Path $env:USERPROFILE '.config' $orgRel
    if (-not (Test-Path -LiteralPath $orgPath)) {
        Write-Host "SKIP  $orgRel (org source missing)" -ForegroundColor DarkYellow
        $skipped += "$orgRel (org source not found)"
        continue
    }

    # Check that expected outputs exist — if none exist, something is wrong
    $expectedOutputs = $orgOutputs[$orgRel]
    $existingBefore = @($expectedOutputs | Where-Object { Test-Path (Join-Path $env:USERPROFILE '.config' $_) })
    
    if ($existingBefore.Count -eq 0) {
        Write-Host "SKIP  $orgRel (no outputs exist — drift-map targets may be wrong)" -ForegroundColor DarkYellow
        $skipped += "$orgRel (no output files found)"
        continue
    }

    $before = @{}
    $backups = [System.Collections.Generic.List[object]]::new()
    $backupRoot = Join-Path $env:TEMP ("config-drift-check-$([guid]::NewGuid().ToString('N'))")
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

    foreach ($out in $expectedOutputs) {
        $full = Join-Path $env:USERPROFILE '.config' $out
        if (Test-Path -LiteralPath $full) {
            $before[$out] = Get-Hash $full
            $bak = Join-Path $backupRoot $out
            $bakDir = Split-Path -Parent $bak
            if ($bakDir) { New-Item -ItemType Directory -Path $bakDir -Force | Out-Null }
            Copy-Item -LiteralPath $full -Destination $bak -Force
            $backups.Add([pscustomobject]@{ Dest = $full; Backup = $bak; Existed = $true })
        } else {
            $backups.Add([pscustomobject]@{ Dest = $full; Backup = $null; Existed = $false })
        }
    }

    try {
        Write-Host "Check $orgRel ... " -NoNewline
        $text = Invoke-EmacsOrgTangle -EmacsExe $emacsExe -OrgPath $orgPath
        if ($text -notmatch 'Tangled \d+ code block') {
            Write-Host 'FAIL (tangle error or 0 blocks)' -ForegroundColor Red
            $driftAll += "$orgRel -> tangle FAILED"
            continue
        }

        # Kanata post-processing
        if ($orgRel -eq 'kanata\kanata.org') {
            Repair-KanataTangledFiles -KanataDir (Join-Path $env:USERPROFILE '.config\kanata')
        }

        $drifted = @()
        foreach ($out in $expectedOutputs) {
            $full = Join-Path $env:USERPROFILE '.config' $out
            if (-not (Test-Path -LiteralPath $full)) { continue }
            $after = Get-Hash $full
            if ($null -ne $before[$out] -and $before[$out] -ne $after) {
                $drifted += $out
            }
        }

        if ($drifted.Count) {
            Write-Host 'DRIFT' -ForegroundColor Yellow
            foreach ($d in $drifted) { $driftAll += "$orgRel -> $d" }
        } else {
            Write-Host 'OK' -ForegroundColor Green
        }
    } finally {
        # Restore originals
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

Write-Host ''
if ($skipped.Count) {
    Write-Host "Skipped ($($skipped.Count)):" -ForegroundColor DarkYellow
    $skipped | ForEach-Object { Write-Host "  $_" }
}
if ($driftAll.Count) {
    Write-Host "DRIFT DETECTED ($($driftAll.Count) file(s)):" -ForegroundColor Yellow
    $driftAll | ForEach-Object { Write-Host "  $_" }
    Write-Host 'Fix: edit the .org source, then re-tangle with: tangle-configs.ps1' -ForegroundColor DarkYellow
    exit 1
}
if ($skipped.Count -eq 0 -and $driftAll.Count -eq 0) {
    Write-Host 'All configs match their .org sources.' -ForegroundColor Green
    exit 0
} else {
    # If some were skipped but no drift, still non-zero
    exit 2
}
