# enforce-windows-settings.ps1 — re-apply XMouse + disable Aero Snap.
# Idempotent; safe to run on every logon or mid-session after explorer restart.

$ErrorActionPreference = 'Stop'

# ── Registry persistence ──────────────────────────────────────────────────────

# Disable Aero Snap (window auto-arrange on edge)
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'WindowArrangementActive' -Value '0' -Type String

# ── Apply immediately via WIN32 API ───────────────────────────────────────────

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class Win32Settings {
    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SystemParametersInfo(
        uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);

    public const uint SPI_SETACTIVEWINDOWTRACKING = 0x1001;
    public const uint SPI_SETACTIVEWNDTRKTIMEOUT  = 0x2002;
    public const uint SPI_SETWINARRANGING         = 0x0083;
    public const uint SPIF_UPDATEINIFILE          = 0x01;
    public const uint SPIF_SENDCHANGE             = 0x02;
}
'@

$flags = [Win32Settings]::SPIF_UPDATEINIFILE -bor [Win32Settings]::SPIF_SENDCHANGE

# 1. Enable active window tracking (hover to activate)
[void][Win32Settings]::SystemParametersInfo(
    [Win32Settings]::SPI_SETACTIVEWINDOWTRACKING, 1,
    [IntPtr]::Zero, $flags)

# 2. Set hover delay to 500 ms (default)
[void][Win32Settings]::SystemParametersInfo(
    [Win32Settings]::SPI_SETACTIVEWNDTRKTIMEOUT, 500,
    [IntPtr]::Zero, $flags)

# 3. Disable window auto-arrange / Aero Snap
[void][Win32Settings]::SystemParametersInfo(
    [Win32Settings]::SPI_SETWINARRANGING, 0,
    [IntPtr]::Zero, $flags)
