# hermes-gateway-healthcheck-daemon.ps1
# Persistent daemon that runs the gateway health check on a 2-minute loop.
# Replaces the scheduled-task approach (which caused CMD window flashes on each run).
# Launched once at boot by startup-orchestrator.ps1 (Group 4).
#
# If the daemon dies between reboots, the gateway still runs fine — it just won't
# be automatically resurrected if it silently fails. The orchestrator re-launches
# at next boot.

param(
    [int]$SilenceThresholdMinutes = 30,
    [int]$CheckIntervalSeconds = 120
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$healthCheckPs1 = Join-Path $scriptDir "hermes-gateway-healthcheck.ps1"
$daemonLog = "$env:USERPROFILE\.local\share\hermes\logs\healthcheck-daemon.log"

# Redirect ALL output to the daemon log so nothing leaks to a console
Start-Transcript -Path $daemonLog -Append | Out-Null

Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Health check daemon starting (interval=${CheckIntervalSeconds}s, silence=${SilenceThresholdMinutes}m)"

while ($true) {
    try {
        & $healthCheckPs1 -SilenceThresholdMinutes $SilenceThresholdMinutes 2>&1 | ForEach-Object {
            Write-Output "[$(Get-Date -Format 'HH:mm:ss')] $_"
        }
    } catch {
        Write-Output "[$(Get-Date -Format 'HH:mm:ss')] ERROR in health check: $_"
    }
    Start-Sleep -Seconds $CheckIntervalSeconds
}

# Never reached
Stop-Transcript | Out-Null
