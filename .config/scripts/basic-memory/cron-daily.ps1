$rootDir = Join-Path $env:USERPROFILE 'basic-memory'
$digestPath = Join-Path $rootDir "logs\daily-digest.md"

$dateStr = Get-Date -Format "yyyy-MM-dd"
$7DaysAgo = (Get-Date).AddDays(-7)
$24HoursAgo = (Get-Date).AddHours(-24)

$mdFiles = Get-ChildItem -Path $rootDir -Filter *.md -Recurse | Where-Object { $_.FullName -notmatch "\\.git\\" }

$staleNotes = $mdFiles | Where-Object { $_.DirectoryName -match "notes" -and $_.LastWriteTime -lt $7DaysAgo }
$recentNotes = $mdFiles | Where-Object { $_.LastWriteTime -gt $24HoursAgo -and $_.Name -ne "daily-digest.md" }

$content = @"
---
title: Daily Digest - $dateStr
type: log
tags: [digest, cron]
author: system
date: $dateStr
---

# Daily Digest ($dateStr)

> Automated daily scan of Basic Memory health and activity.

## What Changed in the Last 24 Hours
"@

if ($recentNotes.Count -gt 0) {
    foreach ($note in $recentNotes) {
        $relPath = $note.FullName.Substring($rootDir.Length + 1)
        $content += "`n- [[$relPath]] (Modified: $($note.LastWriteTime.ToString('HH:mm')))"
    }
} else {
    $content += "`n- No files modified in the last 24 hours."
}

$content += @"


## Stale Notes (Older than 7 days)
> Notes in the `"notes/`" directory should be ephemeral. Either curate these into permanent `"reference/`" notes, or delete them.
"@

if ($staleNotes.Count -gt 0) {
    foreach ($note in $staleNotes) {
        $relPath = $note.FullName.Substring($rootDir.Length + 1)
        $content += "`n- [[$relPath]] (Last updated: $($note.LastWriteTime.ToString('yyyy-MM-dd')))"
    }
} else {
    $content += "`n- No stale notes found! Good job."
}

Set-Content -Path $digestPath -Value $content -Encoding UTF8
Write-Host "Daily digest written to $digestPath" -ForegroundColor Green

# --- Chain Execution of Maintenance Scripts ---
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
$injectScript = Join-Path $scriptDir 'inject-backlinks.ps1'
$graphScript = Join-Path $scriptDir 'generate-knowledge-graph.ps1'
$commitScript = Join-Path $scriptDir 'auto-commit-memory.ps1'

if (Test-Path $injectScript) { & $injectScript }
if (Test-Path $graphScript) { & $graphScript }
if (Test-Path $commitScript) { & $commitScript }
