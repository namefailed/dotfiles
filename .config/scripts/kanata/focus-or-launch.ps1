# Focus the oldest window of -ProcessName if one exists, or launch -LaunchPath.
# Pressing the hotkey while already focused on the app minimizes it (toggle).
# Invoked from Kanata (via run-powershell-silent.vbs) with -ProcessName, -LaunchPath, and optional -Arguments.

param(
    [Parameter(Mandatory = $true)]
    [string]$ProcessName,

    [Parameter(Mandatory = $true)]
    [string]$LaunchPath,

    [Parameter(Mandatory = $false)]
    [string]$Arguments = ''
)

$ErrorActionPreference = 'SilentlyContinue'

Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class WindowFocus {
    [DllImport("user32.dll")] public static extern bool   ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool   SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint   GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
}
'@

$windows = @(
    Get-Process -Name $ProcessName |
    Where-Object  { $_.MainWindowHandle -ne [IntPtr]::Zero } |
    Sort-Object StartTime
)

if ($windows.Count -eq 0) {
    # No existing window — launch the app.
    if ($Arguments) {
        Start-Process -FilePath $LaunchPath -ArgumentList $Arguments
    } else {
        Start-Process -FilePath $LaunchPath
    }
    exit
}

$foregroundHandle = [WindowFocus]::GetForegroundWindow()
[uint32]$foregroundPid = 0
[WindowFocus]::GetWindowThreadProcessId($foregroundHandle, [ref]$foregroundPid) | Out-Null

$focusedWindow = $windows | Where-Object { $_.Id -eq $foregroundPid } | Select-Object -First 1

if ($focusedWindow) {
    # Already focused — minimize to toggle it away (SW_MINIMIZE = 6).
    [WindowFocus]::ShowWindowAsync($focusedWindow.MainWindowHandle, 6) | Out-Null
} else {
    # Not focused — restore and bring the oldest window to the foreground (SW_RESTORE = 9).
    $window = $windows | Select-Object -First 1
    [WindowFocus]::ShowWindowAsync($window.MainWindowHandle, 9)      | Out-Null
    [WindowFocus]::SetForegroundWindow($window.MainWindowHandle)     | Out-Null
}
