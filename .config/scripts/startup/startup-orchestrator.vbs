' startup-orchestrator.vbs — Master startup script.
' Replaces all individual shortcuts in the ProgramData Startup folder.
' User paths use %USERPROFILE% / %LOCALAPPDATA% (not a hardcoded account name).

Function FindFirstExistingFile(candidates)
  Dim fso, i
  Set fso = CreateObject("Scripting.FileSystemObject")
  For i = 0 To UBound(candidates)
    If fso.FileExists(candidates(i)) Then
      FindFirstExistingFile = candidates(i)
      Exit Function
    End If
  Next
End Function

Function FindWinGetExe(packageIdPart, exeFileName)
  Dim sh, fso, base, pkg, direct, subfolder
  Set sh = CreateObject("WScript.Shell")
  Set fso = CreateObject("Scripting.FileSystemObject")
  base = sh.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\WinGet\Packages"
  If Not fso.FolderExists(base) Then Exit Function
  For Each pkg In fso.GetFolder(base).SubFolders
    If InStr(1, pkg.Name, packageIdPart, vbTextCompare) > 0 Then
      direct = pkg.Path & "\" & exeFileName
      If fso.FileExists(direct) Then
        FindWinGetExe = direct
        Exit Function
      End If
      For Each subfolder In fso.GetFolder(pkg.Path).SubFolders
        direct = subfolder.Path & "\" & exeFileName
        If fso.FileExists(direct) Then
          FindWinGetExe = direct
          Exit Function
        End If
      Next
    End If
  Next
End Function

Set oShell = CreateObject("WScript.Shell")
Dim profile, configRoot, kanataDir, emacsRun, espansoExe, kanataExe, wtqExe

profile = oShell.ExpandEnvironmentStrings("%USERPROFILE%")
configRoot = profile & "\.config"
kanataDir = configRoot & "\kanata"

emacsRun = FindFirstExistingFile(Array( _
  "C:\Program Files\Emacs\emacs-30.2\bin\runemacs.exe", _
  "C:\Program Files\Emacs\emacs-30.1\bin\runemacs.exe" _
))
espansoExe = oShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Programs\Espanso\espansod.exe"
kanataExe = kanataDir & "\kanata_windows_gui_wintercept_cmd_allowed_x64.exe"
wtqExe = FindWinGetExe("flyingpie.windows-terminal-quake", "wtq.exe")

' ===== Group 1: Background services (no dependencies) =====
' Tailscale VPN
oShell.Run """C:\Program Files\Tailscale\tailscale-ipn.exe""", 0, False

' Ollama (local LLM server)
Dim ollamaExe
ollamaExe = oShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Programs\Ollama\ollama.exe"
If CreateObject("Scripting.FileSystemObject").FileExists(ollamaExe) Then
  oShell.Run """" & ollamaExe & """ serve", 0, False
End If

' Basic Memory MCP server
Dim ps1, pwsh
ps1  = profile & "\.config\scripts\basic-memory\start-basic-memory-server.ps1"
pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"
oShell.Run """" & pwsh & """ -ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File """ & ps1 & """", 0, False

' Emacs daemon (background, no window)
If emacsRun <> "" Then
  oShell.Run """" & emacsRun & """ --init-directory """ & configRoot & "\emacs"" --daemon --chdir """ & profile & """", 0, False
End If

WScript.Sleep 5000

' ===== Group 2: Lightweight user apps =====
' Espanso (text expander daemon)
If espansoExe <> "" And CreateObject("Scripting.FileSystemObject").FileExists(espansoExe) Then
  oShell.Run """" & espansoExe & """ launcher", 0, False
End If

' Kanata (keyboard remapper) — needs working dir for .kbd config and DLLs
' Pass all 3 configs so the tray icon shows switchable profiles.
Dim kanataCfg1, kanataCfg2, kanataCfg3
kanataCfg1 = kanataDir & "\kanata.kbd"
kanataCfg2 = kanataDir & "\external.kbd"
kanataCfg3 = kanataDir & "\kanata-plain.kbd"
If kanataExe <> "" And CreateObject("Scripting.FileSystemObject").FileExists(kanataExe) Then
  oShell.CurrentDirectory = kanataDir
  oShell.Run """" & kanataExe & """ -c """ & kanataCfg1 & """ -c """ & kanataCfg2 & """ -c """ & kanataCfg3 & """", 0, False
End If

WScript.Sleep 5000

' ===== Group 3: WTQ → Komorebi (critical order) =====
' WTQ — creates quake terminal window and overrides its title to "Quake"
If wtqExe <> "" Then
  oShell.Run """" & wtqExe & """", 0, False
End If

' Wait for WTQ to attach and set the window title
WScript.Sleep 7000

' Komorebi — starts after quake title is set, so the Title:Quake ignore rule
' matches on first evaluation (no flash, no permanent management).
oShell.Run """C:\Program Files\komorebi\bin\komorebic-no-console.exe"" start --ffm --bar", 0, False

' ===== Group 4: AI services (after BM + Ollama) =====
WScript.Sleep 5000

' Hermes Telegram gateway — needs Ollama + BM running first
Dim hermesExe
hermesExe = oShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\hermes\hermes-agent\venv\Scripts\hermes.exe"
If CreateObject("Scripting.FileSystemObject").FileExists(hermesExe) Then
  oShell.CurrentDirectory = profile
  oShell.Run """" & pwsh & """ -WindowStyle Hidden -Command ""& '" & hermesExe & "' gateway run --replace""", 0, False
End If
