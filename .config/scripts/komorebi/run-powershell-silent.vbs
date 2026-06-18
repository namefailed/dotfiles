' run-powershell-silent.vbs - Invoke a PowerShell script with hidden window.
' Usage: wscript.exe //B run-powershell-silent.vbs <script.ps1> [-Key Value ...]
' All arguments after the script path are forwarded verbatim.
' Quotes are added around any argument that contains spaces.

Set oShell = CreateObject("WScript.Shell")

Dim cmd
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File"

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
