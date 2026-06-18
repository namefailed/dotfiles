# Verify PKM system integrity.
# Usage:
#   .\verify-pkm-integrity.ps1

$ErrorActionPreference = 'Continue'
$orgDir = "$env:USERPROFILE\Documents\org"
$exitCode = 0

Write-Host '=== PKM Integrity Check ===' -ForegroundColor Cyan
Write-Host ''

# ── 1. Root files exist ───────────────────────────────────────────────────────
Write-Host '[1/4] Root files...' -NoNewline
$required = @('tasks.org', 'journal.org', 'notes.org')
$missing = @()
foreach ($f in $required) {
    if (-not (Test-Path "$orgDir\$f")) { $missing += $f }
}
if ($missing.Count -eq 0) {
    Write-Host ' OK' -ForegroundColor Green
} else {
    Write-Host " MISSING: $($missing -join ', ')" -ForegroundColor Red
    $exitCode = 1
}

# ── 2. Broken denote links ────────────────────────────────────────────────────
Write-Host '[2/4] Denote link integrity...' -NoNewline
$allIds = Get-ChildItem -Path "$orgDir\notes" -Recurse -Filter '*.org' -ErrorAction SilentlyContinue |
    ForEach-Object { if ($_.BaseName -match '^(\d{8}T\d{6})') { $matches[1] } }
$idSet = @{}; $allIds | ForEach-Object { $idSet[$_] = $true }

$brokenLinks = Select-String -Path "$orgDir\*.org", "$orgDir\notes\**\*.org" `
    -Pattern '\[\[denote:(\d{8}T\d{6})\]' -ErrorAction SilentlyContinue |
    ForEach-Object {
        $foundId = $_.Matches[0].Groups[1].Value
        if (-not $idSet.ContainsKey($foundId)) {
            [PSCustomObject]@{ File = $_.Path; Line = $_.LineNumber; Id = $foundId }
        }
    } | Sort-Object Id -Unique

$brokenCount = @($brokenLinks).Count
if ($brokenCount -eq 0) {
    Write-Host ' OK' -ForegroundColor Green
} else {
    Write-Host " $brokenCount broken link(s)" -ForegroundColor Red
    $brokenLinks | ForEach-Object { Write-Host "  $($_.Id) in $($_.File):$($_.Line)" }
    $exitCode = 1
}

# ── 3. Git remote reachable ───────────────────────────────────────────────────
Write-Host '[3/4] Git remote...' -NoNewline
$gitResult = & git -C "$orgDir" remote -v 2>&1 | Select-String 'github.com'
if ($gitResult) {
    $remoteCheck = & git -C "$orgDir" ls-remote --exit-code origin HEAD 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host ' OK' -ForegroundColor Green
    } else {
        Write-Host ' UNREACHABLE (offline?)' -ForegroundColor Yellow
    }
} else {
    Write-Host ' NO REMOTE CONFIGURED' -ForegroundColor Red
    $exitCode = 1
}

# ── 4. Uncommitted changes ────────────────────────────────────────────────────
Write-Host '[4/4] Git status...' -NoNewline
$status = & git -C "$orgDir" status --porcelain 2>&1
if ($LASTEXITCODE -eq 0 -and -not $status) {
    Write-Host ' Clean' -ForegroundColor Green
} else {
    $changeCount = @($status).Count
    Write-Host " $changeCount uncommitted file(s)" -ForegroundColor Yellow
    $status | ForEach-Object { Write-Host "  $_" }
}

Write-Host ''
if ($exitCode -eq 0) {
    Write-Host '=== All checks passed ===' -ForegroundColor Green
} else {
    Write-Host '=== Issues found ===' -ForegroundColor Red
}
exit $exitCode
