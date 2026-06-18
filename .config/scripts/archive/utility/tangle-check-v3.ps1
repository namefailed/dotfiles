# tangle-check-v3.ps1 — accurate tangle check using the established pipeline
# Uses Invoke-EmacsOrgTangle from config-paths.ps1 which includes noweb pre-execution
$ErrorActionPreference = 'Stop'
$ConfigDir = "$env:USERPROFILE\.config"
$libPath = Join-Path $ConfigDir "scripts\powershell\_lib\config-paths.ps1"
. $libPath

$emacsExe = Get-EmacsExecutable -Name emacs
if (-not $emacsExe) { Write-Error "Emacs not found."; exit 1 }

$orgOutputs = Get-ConfigOrgDriftMap

function Get-Hash($p) {
    $s = [System.IO.File]::OpenRead($p)
    try { return -join ([System.Security.Cryptography.SHA256]::Create().ComputeHash($s) | ForEach-Object { $_.ToString('x2') }) }
    finally { $s.Close() }
}

$drifted = @()
$errors = @()
$ok = 0

foreach ($orgRel in $orgOutputs.Keys) {
    $orgPath = Join-Path $ConfigDir $orgRel
    if (-not (Test-Path -LiteralPath $orgPath)) {
        Write-Host "  SKIP: $orgRel  (not found)" -ForegroundColor DarkYellow
        continue
    }

    $before = @{}
    $backups = @()
    foreach ($out in $orgOutputs[$orgRel]) {
        $full = Join-Path $ConfigDir $out
        if (Test-Path -LiteralPath $full) {
            $before[$out] = Get-Hash $full
            $bakDir = Join-Path $env:TEMP "tangle-check-$([guid]::NewGuid().ToString('N'))"
            $bak = Join-Path $bakDir $out
            $p = Split-Path $bak -Parent
            if ($p -and -not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
            Copy-Item $full $bak -Force
            $backups += @{ Dest = $full; Bak = $bak; BakDir = $bakDir }
        }
    }

    Write-Host "  $orgRel... " -NoNewline
    try {
        $oldEA = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $text = Invoke-EmacsOrgTangle -EmacsExe $emacsExe -OrgPath $orgPath
        $ErrorActionPreference = $oldEA

        if ($text -notmatch 'Tangled \d+ code block') {
            if ($text -match 'Tangled 0 code') {
                Write-Host '0 blocks' -ForegroundColor DarkYellow
                $ok++
                continue
            }
            Write-Host 'ERR' -ForegroundColor Red
            $errors += $orgRel
            continue
        }

        # Kanata post-process
        if ($orgRel -eq 'kanata\kanata.org') {
            Repair-KanataTangledFiles -KanataDir (Join-Path $ConfigDir 'kanata')
        }

        $fileDrift = @()
        foreach ($out in $orgOutputs[$orgRel]) {
            $full = Join-Path $ConfigDir $out
            if (-not (Test-Path -LiteralPath $full)) { continue }
            $after = Get-Hash $full
            if ($null -ne $before[$out] -and $before[$out] -ne $after) {
                $fileDrift += $out
                $drifted += "$orgRel -> $out"
            }
        }

        if ($fileDrift.Count -gt 0) {
            Write-Host 'DRIFT' -ForegroundColor Yellow
            foreach ($d in $fileDrift) { Write-Host "    -> $d" -ForegroundColor Yellow }
        } else {
            Write-Host 'OK' -ForegroundColor Green
            $ok++
        }
    } finally {
        foreach ($e in $backups) {
            if ($e.Bak -and (Test-Path $e.Bak)) { Copy-Item $e.Bak $e.Dest -Force }
            if ($e.BakDir -and (Test-Path $e.BakDir)) { Remove-Item $e.BakDir -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
}

Write-Host ''
if ($errors.Count -gt 0) {
    Write-Host "TANGLE ERRORS ($($errors.Count)):" -ForegroundColor Red
    foreach ($e in $errors) { Write-Host "  $e" }
    Write-Host ''
}
if ($drifted.Count -gt 0) {
    Write-Host "DRIFT DETECTED ($($drifted.Count) file(s) out of sync):" -ForegroundColor Yellow
    foreach ($d in $drifted) { Write-Host "  $d" }
    Write-Host ''
    Write-Host "Fix: edit the .org source, then run 'tangle all' or 'tangle <stem>'." -ForegroundColor DarkYellow
} else {
    Write-Host 'All configs match their .org sources.' -ForegroundColor Green
}
Write-Host "Passed: $ok  Errors: $($errors.Count)  Drifted: $($drifted.Count)" -ForegroundColor Cyan

if ($drifted.Count -gt 0 -or $errors.Count -gt 0) { exit 1 }
