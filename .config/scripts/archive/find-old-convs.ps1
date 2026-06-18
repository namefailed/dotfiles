# Find any old antigravity data locations
# Searches binary DB file for path strings, and scans common old locations

# 1. Read the globalStorage DB as binary and extract readable strings (paths)
$dbPath = "$env:APPDATA\antigravity\User\globalStorage\state.vscdb"
Write-Host "=== Scanning $dbPath for path strings ==="
$bytes = [System.IO.File]::ReadAllBytes($dbPath)
$ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
# Extract long readable substrings (paths tend to be long)
$ascii -split '[^\x20-\x7E]' | Where-Object { $_.Length -gt 20 -and ($_ -match 'Namef|gemini|antigravity|conversation|appData|brain') } | Sort-Object -Unique | ForEach-Object { Write-Host $_ }

Write-Host "`n=== Checking common old data locations ==="
$candidates = @(
    "$env:USERPROFILE\.gemini-old",
    "$env:USERPROFILE\.gemini_backup",
    "$env:LOCALAPPDATA\antigravity",
    "$env:LOCALAPPDATA\gemini",
    "$env:USERPROFILE\.config\gemini-backup",
    "$env:USERPROFILE\.config\gemini.bak",
    "$env:USERPROFILE\Documents\antigravity",
    "C:\antigravity"
)
foreach ($c in $candidates) {
    if (Test-Path $c) {
        Write-Host "FOUND: $c"
        Get-ChildItem $c -Recurse -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime | Format-Table
    }
}

Write-Host "`n=== yadm stash / git history for gemini paths ==="
$yadmRepo = "$env:USERPROFILE\.local\share\yadm\repo.git"
if (Test-Path $yadmRepo) {
    Write-Host "yadm repo found at $yadmRepo"
    $log = git --git-dir="$yadmRepo" log --oneline --all -- "*gemini*" 2>&1 | Select-Object -First 20
    $log | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "No yadm repo found at expected location"
}

Write-Host "`n=== Recycling Bin scan ==="
$shell = New-Object -ComObject Shell.Application
$bin = $shell.Namespace(0xA)
$bin.Items() | Where-Object { $_.Name -like "*gemini*" -or $_.Name -like "*antigravity*" -or $_.Name -like "*.db" } | ForEach-Object {
    Write-Host "RECYCLE: $($_.Path) -> $($_.Name)"
}
