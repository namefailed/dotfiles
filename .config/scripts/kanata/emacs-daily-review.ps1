# Open the Emacs daily review (agenda + plan side-by-side).
# Bound in the Kanata lmet-launcher layer to LWin + Shift + J.

$ErrorActionPreference = 'SilentlyContinue'
. (Join-Path $env:USERPROFILE '.config\scripts\_lib\config-paths.ps1')
. (Join-Path $PSScriptRoot 'emacs-window-focus.ps1')

$emacsClient  = Get-EmacsExecutable -Name emacsclient
$emacsClientW = Get-EmacsExecutable -Name emacsclientw
if (-not $emacsClientW) {
    Write-Error 'emacsclientw.exe not found (checked Program Files Emacs installs and PATH)'
    exit 1
}

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class WinFocus {
    [DllImport("user32.dll")] public static extern bool   AllowSetForegroundWindow(int dwProcessId);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint   GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
}
'@

$status = & $emacsClient --eval '(my/notes-frame-status)' 2>$null

if ($status -notmatch '"(?:selected|exists)"') {
    Start-Process -FilePath $emacsClientW `
        -ArgumentList '--alternate-editor= -c -n --eval "(run-with-timer 0 nil (lambda () (my/notes-daily-review)))"' `
        -WorkingDirectory $env:USERPROFILE
    exit
}

$emacsProc = Get-Process -Name emacs | Select-Object -First 1
$fg        = [WinFocus]::GetForegroundWindow()
[uint32]$fgPid = 0
[WinFocus]::GetWindowThreadProcessId($fg, [ref]$fgPid) | Out-Null

if ($emacsProc) { [WinFocus]::AllowSetForegroundWindow($emacsProc.Id) | Out-Null }
& $emacsClient --eval '(progn (my/notes-raise) (my/notes-daily-review))' 2>$null
Set-EmacsFrameForeground -TitleContains 'journal.org'
