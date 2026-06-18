# Creates a Denote note from a Phoneme voice transcript.
# No journal entry — pure Denote capture via emacsclient --eval.
#
# Hook command (paste into Phoneme Settings -> Destination & Integrations):
#   powershell -ExecutionPolicy Bypass -NoProfile -File "%USERPROFILE%\.config\scripts\phoneme\phoneme-denote.ps1"

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\_lib\config-paths.ps1')

# ── read Phoneme JSON from stdin ───────────────────────────────────────────
$json = [Console]::In.ReadToEnd()
if (-not $json.Trim()) { exit 0 }
$data       = $json | ConvertFrom-Json
$transcript = ($data.transcript -replace '[\r\n]+', ' ').Trim()
if (-not $transcript) { exit 0 }

# ── call Emacs daemon to create the Denote note ───────────────────────────
$emacsClient = Get-EmacsExecutable -Name emacsclient
if (-not $emacsClient) { exit 1 }

$escaped = $transcript -replace '\\', '\\\' -replace '"', '\"'
$code = "(my/phoneme-insert-denote ""$escaped"")"
& $emacsClient -a "" --eval $code
exit $LASTEXITCODE
