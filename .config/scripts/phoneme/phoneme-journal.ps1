# Appends a Phoneme voice note to today's **** Log section in journal.org.
# Uses emacsclient --eval as the primary path (safe with daemon open buffers).
# Falls back to direct file I/O when Emacs daemon is unavailable.
#
# Hook command (paste into Phoneme Settings -> Destination & Integrations):
#   powershell -ExecutionPolicy Bypass -NoProfile -File "%USERPROFILE%\.config\scripts\phoneme\phoneme-journal.ps1"

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\_lib\config-paths.ps1')

# ── read Phoneme JSON from stdin ───────────────────────────────────────────
$json = [Console]::In.ReadToEnd()
if (-not $json.Trim()) { exit 0 }
$data       = $json | ConvertFrom-Json
$transcript = ($data.transcript -replace '[\r\n]+', ' ').Trim()
if (-not $transcript) { exit 0 }

# ── try Emacs daemon path first (preferred) ────────────────────────────────
$emacsClient = Get-EmacsExecutable -Name emacsclient
if ($emacsClient) {
    # Escape transcript for Elisp string (backslash + double-quote)
    $escaped = $transcript -replace '\\', '\\\' -replace '"', '\"'
    $code = "(my/phoneme-insert-transcript ""$escaped"")"
    $result = & $emacsClient -a "" --eval $code 2>&1
    if ($LASTEXITCODE -eq 0) { exit 0 }
    # Fall through to direct I/O if daemon didn't respond
}

# ── direct file I/O fallback (daemon unavailable) ──────────────────────────
. (Join-Path $PSScriptRoot '..\_lib\config-paths.ps1')
$journalFile = Join-Path $script:OrgRoot 'journal.org'
$now  = Get-Date
$ci   = [System.Globalization.CultureInfo]::InvariantCulture
$date    = $now.ToString('yyyy-MM-dd', $ci)
$day     = $now.ToString('dddd', $ci)
$dayAbbr = $now.ToString('ddd', $ci)
$ts      = "[$date $dayAbbr $($now.ToString('HH:mm', $ci))]"
$entry   = "- $ts $transcript"
$heading = "*** $date $day"

if (-not (Test-Path $journalFile)) {
    New-Item -ItemType File -Path $journalFile -Force | Out-Null
}
$raw = [System.IO.File]::ReadAllText($journalFile, [System.Text.Encoding]::UTF8)
$lines = [System.Collections.Generic.List[string]]::new()
$lines.AddRange([string[]]($raw -replace "`r`n", "`n" -replace "`r", "`n" -split "`n"))

$hi = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -eq $heading) { $hi = $i; break }
}

if ($hi -lt 0) {
    while ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') {
        $lines.RemoveAt($lines.Count - 1)
    }
    foreach ($l in ('', $heading, '', '**** Log', $entry)) { $lines.Add($l) }
} else {
    $sectionEnd = $lines.Count
    $li = -1
    for ($i = $hi + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\*{3} ')      { $sectionEnd = $i; break }
        if ($lines[$i] -match '^\*{4} Log\b') { $li = $i }
    }
    if ($li -lt 0) {
        $at = $sectionEnd
        while ($at -gt $hi + 1 -and $lines[$at - 1] -eq '') { $at-- }
        $lines.Insert($at, $entry)
        $lines.Insert($at, '**** Log')
        $lines.Insert($at, '')
    } else {
        $at = $li + 1
        for ($i = $li + 1; $i -lt $sectionEnd; $i++) {
            if   ($lines[$i] -match '^- \[')  { $at = $i + 1 }
            elseif ($lines[$i] -match '^\*+') { break }
        }
        $lines.Insert($at, $entry)
    }
}

$out = ($lines -join "`n").TrimEnd() + "`n"
[System.IO.File]::WriteAllText($journalFile, $out, [System.Text.UTF8Encoding]::new($false))
