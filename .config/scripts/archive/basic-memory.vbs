' basic-memory.vbs — Start Basic Memory MCP HTTP server at logon (all-users Startup).
' Deploy: copy this file to ProgramData Startup (see powershell snippet below).

Set oShell = CreateObject("WScript.Shell")
Dim ps1, pwsh
ps1  = oShell.ExpandEnvironmentStrings("%USERPROFILE%") & "\.config\scripts\powershell\basic-memory\start-server.ps1"
pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"
oShell.Run """" & pwsh & """ -NonInteractive -WindowStyle Hidden -File """ & ps1 & """", 0, False
