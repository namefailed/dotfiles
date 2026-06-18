' komorebic-dual-wrapper.vbs - Focus workspace N on both monitors.
' Usage: wscript.exe //B komorebic-dual-wrapper.vbs <workspace-index>
' Calls focus-monitor-workspace on monitor 1 first (with wait) then monitor 0.

Set oShell = CreateObject("WScript.Shell")

Dim wsIndex
wsIndex = WScript.Arguments(0)

' Switch the other monitor first so focus stays on the current one.
oShell.Run "komorebic.exe focus-monitor-workspace 1 " & wsIndex, 0, True
oShell.Run "komorebic.exe focus-monitor-workspace 0 " & wsIndex, 0, False
