# Ensure the window-manager stack runs without WHKD/AHK conflicts.
# - Stops whkd if it was launched by another startup entry.
# - Restarts komorebi in no-console mode without the --whkd flag.

$ErrorActionPreference = 'SilentlyContinue'

$komorebi = 'C:\Program Files\komorebi\bin\komorebic-no-console.exe'
if (-not (Test-Path $komorebi)) {
    $komorebi = (Get-Command 'komorebic-no-console.exe' -ErrorAction SilentlyContinue).Source
}
if (-not $komorebi) {
    exit 1
}

Get-Process -Name 'whkd' -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name 'komorebi' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

Start-Process -FilePath $komorebi -ArgumentList @('start','--ffm','--bar') -WindowStyle Hidden