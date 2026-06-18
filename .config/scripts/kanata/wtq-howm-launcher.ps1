# Launch the dedicated Howm scratch frame for WTQ.
# Bound to LWin + s in WTQ (not Kanata).

$ErrorActionPreference = 'SilentlyContinue'
. (Join-Path $env:USERPROFILE '.config\scripts\_lib\config-paths.ps1')

$emacsClientW = Get-EmacsExecutable -Name emacsclientw
if (-not $emacsClientW) {
    Write-Error 'emacsclientw.exe not found (checked Program Files Emacs installs and PATH)'
    exit 1
}

$existingWindow = Get-Process | Where-Object {
    $_.MainWindowTitle -eq 'Howm Scratch'
} | Select-Object -First 1

if ($existingWindow) {
    exit 0
}

Start-Process -FilePath $emacsClientW `
    -ArgumentList '--alternate-editor= -c -n -F "((name . \"Howm Scratch\") (title . \"Howm Scratch\"))" --eval "(run-with-timer 0 nil (lambda () (my/wtq-howm-frame-setup)))"' `
    -WorkingDirectory $env:USERPROFILE
