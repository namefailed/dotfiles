# ttyd-toggle.ps1 — Start or stop the ttyd web terminal server.
# Usage: webterm [start|stop|status]  (alias in PowerShell profile)
#   start  — Launch ttyd in background on port 7681
#   stop   — Kill any running ttyd process
#   status — Show whether ttyd is running
#
# Shell: cmd.exe (pwsh.exe crashes ttyd within minutes — root cause unknown)
# Detach: uses WScript.Run via temp VBS to avoid job-object cleanup on parent exit
#
# Access in browser via: http://localhost:7681
# Or via Tailscale IP:   http://100.x.x.x:7681

param(
  [ValidateSet('start','stop','status')]
  [string]$Action = 'status'
)

. (Join-Path $env:USERPROFILE '.config\scripts\_lib\config-paths.ps1')

$ttydBin = Resolve-WinGetPackageExe -PackageIdPart 'tsl0922.ttyd' -ExeFileName 'ttyd.exe'
if (-not $ttydBin) {
    Write-Error 'ttyd.exe not found. Install with: winget install tsl0922.ttyd'
    exit 1
}
$port = 7681

switch ($Action) {
  'start' {
    $running = Get-Process -Name ttyd -ErrorAction SilentlyContinue
    if ($running) {
      Write-Host "ttyd already running (PID $($running.Id)) on port $port"
    } else {
      $vbsContent = @'
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run """#BIN#"" #ARGS#", 0, False
'@.Replace("#BIN#", $ttydBin).Replace("#ARGS#", "-p $port -W cmd.exe")
      $vbsFile = Join-Path $env:TEMP "start-ttyd.vbs"
      $vbsContent | Out-File -FilePath $vbsFile -Encoding ASCII -Force
      Start-Process wscript -ArgumentList "`"$vbsFile`"" -WindowStyle Hidden
      Start-Sleep 2
      $proc = Get-Process -Name ttyd -ErrorAction SilentlyContinue
      if ($proc) {
        Write-Host "ttyd started (PID $($proc.Id)) on http://localhost:$port"
        $tsIp = & "C:\Program Files\Tailscale\tailscale.exe" ip -4 2>$null
        if ($tsIp) { Write-Host "From Tailscale: http://${tsIp}:$port" }
      } else {
        Write-Host "ERROR: ttyd failed to start" -ForegroundColor Red
      }
    }
  }
  'stop' {
    $running = Get-Process -Name ttyd -ErrorAction SilentlyContinue
    if ($running) {
      $running | Stop-Process -Force
      Write-Host "ttyd stopped"
    } else {
      Write-Host "ttyd is not running"
    }
  }
  'status' {
    $running = Get-Process -Name ttyd -ErrorAction SilentlyContinue
    if ($running) {
      Write-Host "ttyd is RUNNING (PID $($running.Id)) on port $port"
      Write-Host "Local:  http://localhost:$port"
    } else {
      Write-Host "ttyd is STOPPED"
    }
  }
}
