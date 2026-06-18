# Deferred WTQ bootstrap: stop a running wtq, restart via Explorer, then prime
# Windows Terminal attachment so geometry from wtq.jsonc applies cleanly.
# Called from %USERPROFILE%\.config\scripts\wtq-startup.cmd (user startup).

$ErrorActionPreference = 'SilentlyContinue'

# Let Explorer, komorebi, and startup apps settle before touching WTQ.
Start-Sleep -Seconds 5

# Restart WTQ so it reads the latest wtq.jsonc config.
Get-Process wtq -ErrorAction SilentlyContinue | Stop-Process -Force

Start-Sleep -Milliseconds 700

$wtqPath = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\flyingpie.windows-terminal-quake_Microsoft.Winget.Source_8wekyb3d8bbwe\wtq.exe"
Start-Process -FilePath 'explorer.exe' -ArgumentList "`"$wtqPath`""

# WTQ initially attaches to Windows Terminal before applying its configured geometry.
Start-Sleep -Seconds 3

# Opening once primes the position and size from wtq.jsonc.
Start-Process -FilePath $wtqPath -ArgumentList 'apps open --app "Windows Terminal"' -Wait -WindowStyle Hidden

Start-Sleep -Milliseconds 500

if (-not (Get-Process wtq -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath 'explorer.exe' -ArgumentList "`"$wtqPath`""
}
