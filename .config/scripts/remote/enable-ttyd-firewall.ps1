# ttyd Firewall Rule — run once as admin after installing ttyd.
# IMPORTANT: specify -Profile Any; Tailscale uses Private profile.

. (Join-Path $env:USERPROFILE '.config\scripts\_lib\config-paths.ps1')

$ttydBin = Resolve-WinGetPackageExe -PackageIdPart 'tsl0922.ttyd' -ExeFileName 'ttyd.exe'
if (-not $ttydBin) {
    Write-Error 'ttyd.exe not found. Install with: winget install tsl0922.ttyd'
    exit 1
}

# Remove any existing rules (including auto-created "Query User" rules)
Get-NetFirewallRule | Where-Object { $_.DisplayName -eq "ttyd.exe" } | Remove-NetFirewallRule

New-NetFirewallRule -DisplayName "ttyd (7681)" -Direction Inbound -Protocol TCP -LocalPort 7681 -Program $ttydBin -Action Allow -Profile Any -Enabled True

Write-Host "ttyd firewall rule created (Profile: Any)."
