Set oShell = CreateObject("WScript.Shell")

' Sleep 5 seconds to let WTQ start and set the quake terminal's title
WScript.Sleep 5000

' Start Komorebi
oShell.Run """C:\Program Files\komorebi\bin\komorebic-no-console.exe"" start --ffm --bar", 0, False
