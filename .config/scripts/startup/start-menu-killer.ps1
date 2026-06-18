# Watchdog: kill StartMenuExperienceHost + SearchHost on a 1s cycle.
# Launched at logon by startup-orchestrator.ps1.
# See scripts.org → "start-menu-killer.ps1" for rationale and disable steps.

$ErrorActionPreference = 'SilentlyContinue'
$targets = @('StartMenuExperienceHost', 'SearchHost')

while ($true) {
    Get-Process -Name $targets -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}
