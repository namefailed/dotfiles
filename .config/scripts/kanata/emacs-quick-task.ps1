# Org quick-task capture menu. Bound in Kanata lmet-launcher to LWin + T.

$ErrorActionPreference = 'SilentlyContinue'
. (Join-Path $env:USERPROFILE '.config\scripts\_lib\config-paths.ps1')

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

$null = & $emacsClient --eval 't' 2>$null
if (-not $?) {
    Start-Process -FilePath $emacsClientW `
        -ArgumentList '--alternate-editor= -c -n -F "((name . \"Emacs Quick Task\") (title . \"Emacs Quick Task\"))" --eval "(run-with-timer 0 nil (lambda () (my/mark-launcher-frame) (my/org-quick-task-capture)))"' `
        -WorkingDirectory $env:USERPROFILE
    exit
}

$emacsProc = Get-Process -Name emacs | Select-Object -First 1
if ($emacsProc) { [WinFocus]::AllowSetForegroundWindow($emacsProc.Id) | Out-Null }
& $emacsClient --eval '(progn (select-frame-set-input-focus (selected-frame)) (my/org-quick-task-capture))' 2>$null
