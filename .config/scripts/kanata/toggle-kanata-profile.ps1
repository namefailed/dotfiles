# Toggle between Kanata main and plain profiles.
# Intended trigger: Ctrl+Shift+NumLock from either profile.

$ErrorActionPreference = "Stop"

$kanataDir = Join-Path $env:USERPROFILE '.config\kanata'
$mainConfig = Join-Path $kanataDir "kanata.kbd"
$extConfig = Join-Path $kanataDir "external.kbd"
$plainConfig = Join-Path $kanataDir "kanata-plain.kbd"
$guiExe = Join-Path $kanataDir "kanata_windows_gui_wintercept_cmd_allowed_x64.exe"
$ttyExe = Join-Path $kanataDir "kanata_windows_tty_wintercept_cmd_allowed_x64.exe"

function Show-ProfileNotification {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  if (Get-Command -Name New-BurntToastNotification -ErrorAction SilentlyContinue) {
    New-BurntToastNotification -Text "Keyboard Profile", $Message | Out-Null
    return
  }

  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing

  $notify = New-Object System.Windows.Forms.NotifyIcon
  $notify.Icon = [System.Drawing.SystemIcons]::Information
  $notify.BalloonTipTitle = "Keyboard Profile"
  $notify.BalloonTipText = $Message
  $notify.Visible = $true
  $notify.ShowBalloonTip(2000)
  Start-Sleep -Milliseconds 2200
  $notify.Dispose()
}

$exeToUse = if (Test-Path -LiteralPath $guiExe) { $guiExe } else { $ttyExe }
if (-not (Test-Path -LiteralPath $exeToUse)) {
  throw "No Kanata executable found in $kanataDir"
}

$running = Get-CimInstance Win32_Process -Filter "Name LIKE 'kanata%exe'" -ErrorAction SilentlyContinue
$commandLines = @($running | ForEach-Object { $_.CommandLine }) -join "`n"

# Detect active profile by checking the first -c argument.
$isPlainActive = ($commandLines -match '\.exe" -c\s+kanata-plain\.kbd') -or
                 ($commandLines -match '\.exe -c\s+kanata-plain\.kbd')

$targetConfig = if ($isPlainActive) { $mainConfig } else { $plainConfig }
$profileLabel = if ($targetConfig -eq $mainConfig) { "Kanata ON" } else { "Kanata OFF" }

# Build arg list: target config first (active profile), others follow (for tray).
$otherConfigs = @($mainConfig, $extConfig, $plainConfig) | Where-Object { $_ -ne $targetConfig }
$allArgs = @("-c", $targetConfig)
foreach ($cfg in $otherConfigs) {
  $allArgs += @("-c", $cfg)
}

# Stop all current Kanata instances first.
if ($running) {
  $running | ForEach-Object {
    try {
      Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop
    } catch {
      # If one process exits between enumeration and stop, continue.
    }
  }

  Start-Sleep -Milliseconds 250
}

Start-Process -FilePath $exeToUse `
  -ArgumentList $allArgs `
  -WorkingDirectory $kanataDir `
  -WindowStyle Hidden

Show-ProfileNotification -Message $profileLabel
