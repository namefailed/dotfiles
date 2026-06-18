# Win32 foreground helper for multi-frame Emacs (used by emacs-home/notes/howm.ps1).
# Emacs has one process but several top-level windows; Get-Process MainWindowHandle
# is not the frame we want. Match by window title instead.

function Set-EmacsFrameForeground {
    param(
        [string]$TitleEquals,
        [string]$TitleContains
    )

    if (-not $TitleEquals -and -not $TitleContains) { return }

    $emacsProc = Get-Process -Name emacs -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $emacsProc) { return }

    Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class EmacsWindowFocus {
    public static IntPtr Match = IntPtr.Zero;
    public static uint TargetPid;
    public static string TitleEquals;
    public static string TitleContains;

    public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumProc proc, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int maxCount);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    public static bool EnumCallback(IntPtr hWnd, IntPtr lParam) {
        uint pid = 0;
        GetWindowThreadProcessId(hWnd, out pid);
        if (pid != TargetPid || !IsWindowVisible(hWnd)) return true;

        var sb = new StringBuilder(512);
        if (GetWindowText(hWnd, sb, sb.Capacity) <= 0) return true;
        string title = sb.ToString();
        if (title.Length == 0) return true;

        bool ok = false;
        if (!string.IsNullOrEmpty(TitleEquals))
            ok = string.Equals(title, TitleEquals, StringComparison.Ordinal);
        else if (!string.IsNullOrEmpty(TitleContains))
            ok = title.IndexOf(TitleContains, StringComparison.OrdinalIgnoreCase) >= 0;

        if (!ok) return true;
        Match = hWnd;
        return false;
    }
}
"@ -ErrorAction SilentlyContinue | Out-Null

    [EmacsWindowFocus]::Match = [IntPtr]::Zero
    [EmacsWindowFocus]::TargetPid = [uint32]$emacsProc.Id
    [EmacsWindowFocus]::TitleEquals = $TitleEquals
    [EmacsWindowFocus]::TitleContains = $TitleContains
    $callback = [EmacsWindowFocus+EnumProc] { param($h, $l) [EmacsWindowFocus]::EnumCallback($h, $l) }
    [EmacsWindowFocus]::EnumWindows($callback, [IntPtr]::Zero) | Out-Null

    if ([EmacsWindowFocus]::Match -ne [IntPtr]::Zero) {
        [EmacsWindowFocus]::ShowWindowAsync([EmacsWindowFocus]::Match, 9) | Out-Null
        [EmacsWindowFocus]::SetForegroundWindow([EmacsWindowFocus]::Match) | Out-Null
    }
}
