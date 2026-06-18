# fix-gemini-junction.ps1
# Collapses the double-hop junction chain into a single clean junction.
# Before: ~/.gemini -> ~/.local/state/gemini -> ~/.config/gemini (real)
# After:  ~/.gemini -> ~/.config/gemini (real)

$gemini     = "$env:USERPROFILE\.gemini"
$localState = "$env:USERPROFILE\.local\state\gemini"
$configGemini = "$env:USERPROFILE\.config\gemini"

# 1. Remove the middleman junction (.local/state/gemini) if it still exists
if (Test-Path $localState) {
    $item = Get-Item $localState -Force -ErrorAction SilentlyContinue
    if ($item.LinkType) {
        cmd /c "rmdir `"$localState`""
        Write-Host "Removed middleman junction: $localState"
    }
}

# 2. Remove the old .gemini junction
if (Test-Path $gemini) {
    $item = Get-Item $gemini -Force -ErrorAction SilentlyContinue
    if ($item.LinkType) {
        cmd /c "rmdir `"$gemini`""
        Write-Host "Removed old junction: $gemini"
    } elseif ($item.PSIsContainer) {
        Write-Host "WARNING: $gemini is a real directory, not touching it."
        exit 1
    }
}

# 3. Create the clean direct junction: ~/.gemini -> ~/.config/gemini
cmd /c "mklink /J `"$gemini`" `"$configGemini`""
Write-Host "Created: $gemini -> $configGemini"

# 4. Fix WHKD_CONFIG_HOME: create the dir so komorebic check doesn't panic
$whkdDir = "$env:USERPROFILE\.config\whkd"
if (-not (Test-Path $whkdDir)) {
    New-Item -ItemType Directory -Path $whkdDir -Force | Out-Null
    Write-Host "Created: $whkdDir"
} else {
    Write-Host "Already exists: $whkdDir"
}

# 5. Verify
Write-Host "`n--- Verification ---"
cmd /c "dir /al $env:USERPROFILE 2>&1" | Select-String "gemini"
cmd /c "dir /al $env:USERPROFILE\.local\state 2>&1" | Select-String "gemini"
Write-Host "`nData check:"
Get-ChildItem "$gemini\antigravity\conversations" -ErrorAction SilentlyContinue | Select-Object Name,Length
