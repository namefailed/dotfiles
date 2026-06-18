' komorebic-wrapper.vbs - Silent komorebic dispatcher for Kanata bindings.
' Usage: wscript.exe //B komorebic-wrapper.vbs <komorebic-args>
' Forwards all arguments to komorebic.exe silently.

Set oShell = CreateObject("WScript.Shell")

Dim cmd
cmd = "komorebic.exe"

Dim i
Dim arg
For i = 0 To WScript.Arguments.Count - 1
    arg = WScript.Arguments(i)
    If InStr(arg, " ") > 0 Then
        cmd = cmd & " """ & arg & """"
    Else
        cmd = cmd & " " & arg
    End If
Next

oShell.Run cmd, 0, False
