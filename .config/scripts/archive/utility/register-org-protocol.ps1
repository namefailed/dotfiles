# Archived — register org-protocol:// for Emacs org-protocol capture.
# Idempotent; safe to re-run after Emacs upgrades.

$ErrorActionPreference = 'Stop'

. (Join-Path $env:USERPROFILE '.config\scripts\_lib\config-paths.ps1')

$EmacsClient = Get-EmacsExecutable -Name emacsclientw
if (-not $EmacsClient) {
    Write-Error 'emacsclientw.exe not found. Install Emacs or ensure it is on PATH.'
}

$command = "`"$EmacsClient`" -a emacs `"%1`""
$root = 'HKCU:\Software\Classes\org-protocol'

New-Item -Path $root -Force | Out-Null
Set-ItemProperty -Path $root -Name '(default)' -Value 'URL:org-protocol'
New-ItemProperty -Path $root -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
New-Item -Path "$root\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$root\shell\open\command" -Name '(default)' -Value $command

Write-Host "Registered org-protocol -> $command" -ForegroundColor Green
Write-Host 'Test: emacs daemon must be running, then run:'
Write-Host '  emacsclientw -a emacs "org-protocol://capture?template=l&url=https%3A%2F%2Fexample.com&title=Test"'
