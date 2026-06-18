# hermes-gateway-healthcheck.ps1
# Watches the Hermes gateway for silent failure (connected but not processing messages).
# Restarts the gateway if no message activity logged in the last 30 minutes.
#
# Called every 2 minutes by hermes-gateway-healthcheck-daemon.ps1 (persistent loop).

param(
    [int]$SilenceThresholdMinutes = 30,
    [string]$GatewayLog = "$env:USERPROFILE\.local\share\hermes\logs\gateway.log"
)

$hermesExe = "$env:LOCALAPPDATA\hermes\hermes-agent\venv\Scripts\hermes.exe"

# Check if gateway process is running
# NOTE: Get-Process -Name "hermes" returns ALL hermes.exe instances including
# CLI sessions (hermes chat). We must filter to only the gateway process
# (launched with "gateway run" args) to avoid killing the CLI session.
$allHermes = Get-Process -Name "hermes" -ErrorAction SilentlyContinue
$gatewayProc = $null
foreach ($proc in $allHermes) {
    $cmd = (Get-WmiObject Win32_Process -Filter "ProcessId=$($proc.Id)").CommandLine
    if ($cmd -match 'gateway\s+(run|start)') {
        $gatewayProc = $proc
        break
    }
}
# Fallback: if no gateway found by command line but only one hermes process exists, use it
if (-not $gatewayProc -and $allHermes.Count -eq 1) {
    $gatewayProc = $allHermes[0]
}
if (-not $gatewayProc) {
    Write-Output "[$(Get-Date -Format 'HH:mm:ss')] Gateway process not found - starting it."
    Start-Process $hermesExe -ArgumentList "gateway", "run", "--replace" -WindowStyle Hidden
    exit
}

# Check if log exists
if (-not (Test-Path $GatewayLog)) {
    Write-Output "[$(Get-Date -Format 'HH:mm:ss')] gateway.log not found yet — gateway probably still starting."
    exit
}

# Read last 200 lines, find lines with message activity, parse timestamps
# Resolve the log path to avoid $env expansion surprises
$resolvedLog = $ExecutionContext.InvokeCommand.ExpandString($GatewayLog)
$lines = Get-Content $resolvedLog -Tail 200 -ErrorAction SilentlyContinue
$lastActivity = $null
$lastTimestamp = $null

foreach ($line in $lines) {
    if ($line -match "(inbound message|response ready|Flushing text batch)") {
        # Extract timestamp from log line: "2026-06-02 06:23:57,489 INFO ..."
        if ($line.Length -ge 19) {
            $ts = $line.Substring(0, 19)
            $parsed = $false
            $dt = $null
            try {
                $dt = [datetime]::ParseExact($ts, 'yyyy-MM-dd HH:mm:ss', [cultureinfo]::InvariantCulture)
                $parsed = $true
            } catch {
                # skip unparseable
            }
            if ($parsed) {
                if (-not $lastActivity -or $dt -gt $lastActivity) {
                    $lastActivity = $dt
                    $lastTimestamp = $ts
                }
            }
        }
    }
}

if (-not $lastActivity) {
    Write-Output "[$(Get-Date -Format 'HH:mm:ss')] No message activity found in gateway log - restarting."
    Stop-Process -Id $gatewayProc.Id -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process $hermesExe -ArgumentList "gateway", "run", "--replace" -WindowStyle Hidden
    exit
}

$cutoff = (Get-Date).AddMinutes(-$SilenceThresholdMinutes)
if ($lastActivity -lt $cutoff) {
    Write-Output "[$(Get-Date -Format 'HH:mm:ss')] Last activity at $lastTimestamp — over ${SilenceThresholdMinutes}m ago. Restarting gateway (silent failure)."
    Stop-Process -Id $gatewayProc.Id -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process $hermesExe -ArgumentList "gateway", "run", "--replace" -WindowStyle Hidden
    exit
}

Write-Output "[$(Get-Date -Format 'HH:mm:ss')] Health check OK - last activity: $lastTimestamp"
