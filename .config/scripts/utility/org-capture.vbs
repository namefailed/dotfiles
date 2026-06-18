' org-capture.vbs — Bridge between qutebrowser and Emacs org-protocol.
' Uses wscript (16ms startup) for near-instant captures.
' Called from qutebrowser as:
'   wscript //B "...\org-capture.vbs" l "{url}" "{title}"
'
' Basic URL encoding handles the common cases (&, #, %, space)
' that would break the org-protocol query string.

Dim args, action, url, title, actionMap, protocol
Dim encodedUrl, encodedTitle, uri, handler, cmd, shell

Set args = WScript.Arguments
If args.Count < 2 Then WScript.Quit 1

action = args(0)
url    = args(1)
title  = ""
If args.Count >= 3 Then title = args(2)

actionMap = CreateObject("Scripting.Dictionary")
actionMap.Add "l", "journal-log"
actionMap.Add "t", "journal-task"
actionMap.Add "a", "journal-article"
actionMap.Add "d", "denote-link"
actionMap.Add "o", "org-link"

If Not actionMap.Exists(action) Then WScript.Quit 1
protocol = actionMap(action)

Function UrlEncode(s)
    Dim result
    result = s
    result = Replace(result, "%", "%25")
    result = Replace(result, "&", "%26")
    result = Replace(result, "#", "%23")
    result = Replace(result, " ", "%20")
    result = Replace(result, "+", "%2B")
    result = Replace(result, "=", "%3D")
    UrlEncode = result
End Function

encodedUrl   = UrlEncode(url)
encodedTitle = UrlEncode(title)
uri = "org-protocol://" & protocol & "?url=" & encodedUrl & "&title=" & encodedTitle

Set shell = CreateObject("WScript.Shell")

On Error Resume Next
handler = shell.RegRead("HKCR\org-protocol\shell\open\command\")
On Error Goto 0

If handler <> "" Then
    cmd = Replace(handler, "%1", uri)
    shell.Run cmd, 0, False
Else
    shell.Run """emacsclientw.exe"" -a emacs """ & uri & """", 0, False
End If
