# tangle-check-run.ps1 — standalone tangle verification
# Detects drift between .org sources and tangled outputs in ~/.config
# Does NOT modify files — originals are restored after comparison.

$ErrorActionPreference = 'Stop'
$ConfigDir = "$env:USERPROFILE\.config"

# Drift map: .org source -> output file(s)
$driftMap = [ordered]@{
    'komorebi\komorebi.org'                 = @('komorebi\komorebi.json', 'komorebi\komorebi.bar.json')
    'kanata\kanata.org'                     = @('kanata\kanata.kbd', 'kanata\kanata-plain.kbd')
    'doom\config.org'                       = @('doom\config.el')
    'wtq\wtq.org'                           = @('wtq\wtq.jsonc')
    'starship\starship.org'                 = @('starship\starship.toml')
    'git\git.org'                           = @('git\gitconfig')
    'espanso\espanso.org'                   = @('espanso\config\default.yml', 'espanso\match\base.yml')
    'vscode\vscode.org'                     = @('vscode\settings.json', 'vscode\keybindings.json')
    'cursor\cursor.org'                     = @('cursor\settings.json', 'cursor\keybindings.json')
    'windsurf\windsurf.org'                 = @('windsurf\settings.json', 'windsurf\keybindings.json')
    'tridactyl\tridactyl.org'               = @('tridactyl\.tridactylrc', 'tridactyl\native\tridactyl.json')
    'everything\everything.org'             = @('everything\Everything.ini')
    'windows-terminal\windows-terminal.org' = @('windows-terminal\settings.json')
    'powershell\powershell.org'             = @('powershell\Microsoft.PowerShell_profile.ps1')
    'flowlauncher\flowlauncher.org'         = @('flowlauncher\settings\Settings.json')
    'hermes\hermes.org'                     = @('hermes\config.yaml', 'hermes\.gitignore')
    'scripts\scripts.org'                   = @('scripts\powershell\_lib\config-paths.ps1',
                                                  'scripts\powershell\utility\tangle-configs.ps1',
                                                  'scripts\powershell\utility\verify-org-tangle-sync.ps1')
}

$emacsExe = "C:\Program Files\Emacs\emacs-30.2\bin\emacs.exe"
if (-not (Test-Path -LiteralPath $emacsExe)) {
    Write-Error "Emacs not found at $emacsExe"
    exit 1
}

# SHA256 via .NET (Get-FileHash not available)
function Get-Sha256Hash {
    param([string]$Path)
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($stream)
        return -join ($hashBytes | ForEach-Object { $_.ToString('x2') })
    } finally {
        $stream.Close()
    }
}

function Repair-KanataFiles {
    param([string]$KanataDir)
    $scriptsFwd = (Join-Path $ConfigDir 'scripts') -replace '\\', '/'
    $olkFwd = (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\olk.exe') -replace '\\', '/'
    foreach ($kbdName in @('kanata.kbd', 'kanata-plain.kbd')) {
        $kbdPath = Join-Path $KanataDir $kbdName
        if (-not (Test-Path -LiteralPath $kbdPath)) { continue }
        $kbdText = Get-Content -LiteralPath $kbdPath -Raw
        $kbdText = $kbdText.Replace('<<config-scripts-fwd>>', $scriptsFwd)
        $kbdText = $kbdText.Replace('(replace-regexp-in-string "\\" "/" (expand-file-name "~/.config/scripts"))', $scriptsFwd)
        $kbdText = $kbdText.Replace('<<local-windowsapps-olk>>', $olkFwd)
        Set-Content -LiteralPath $kbdPath -Value $kbdText -NoNewline -Encoding utf8NoBOM
    }
}

function Invoke-OrgTangle {
    param([string]$OrgPath)
    $fwdOrg = $OrgPath -replace '\\', '/'
    # Build careful command-line args as an array to avoid quoting issues
    $args = @(
        '--batch'
        '--eval', '(require (quote org))'
        '--eval', '(require (quote ob-tangle))'
        '--eval', '(setq coding-system-for-write (quote utf-8-unix))'
        '--eval', '(setq org-confirm-babel-evaluate nil)'
        $fwdOrg
        '--eval', '(org-babel-tangle)'
    )
    $oldEA = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & $emacsExe $args 2>&1
    $ErrorActionPreference = $oldEA
    return ($output | Out-String)
}

$drifted = @()
$errors = @()
$okCount = 0
$skipCount = 0

foreach ($orgRel in $driftMap.Keys) {
    $orgPath = Join-Path $ConfigDir $orgRel
    if (-not (Test-Path -LiteralPath $orgPath)) {
        Write-Host "  SKIP: $orgRel  (not found)"
        $skipCount++
        continue
    }

    $outputs = $driftMap[$orgRel]

    # Hash existing outputs BEFORE tangle
    $before = @{}
    $existing = @()
    foreach ($out in $outputs) {
        $full = Join-Path $ConfigDir $out
        if (Test-Path -LiteralPath $full) {
            $before[$out] = Get-Sha256Hash -Path $full
            $existing += $full
        }
    }

    # Backup existing outputs
    $backupRoot = Join-Path $env:TEMP "tangle-check-$([guid]::NewGuid().ToString('N'))"
    $backups = @()
    foreach ($full in $existing) {
        $rel = $full.Substring($ConfigDir.Length + 1)
        $bak = Join-Path $backupRoot $rel
        $bakDir = Split-Path $bak -Parent
        if ($bakDir -and -not (Test-Path -LiteralPath $bakDir)) { New-Item -ItemType Directory -Path $bakDir -Force | Out-Null }
        Copy-Item -LiteralPath $full -Destination $bak -Force
        $backups += @{ Dest = $full; Backup = $bak }
    }

    Write-Host "  Checking $orgRel... " -NoNewline

    try {
        $outputStr = Invoke-OrgTangle -OrgPath $orgPath
        $hasSuccess = $outputStr -match "Tangled \d+ code"

        if (-not $hasSuccess) {
            if ($outputStr -match "Tangled 0 code") {
                Write-Host "0 blocks" -ForegroundColor DarkYellow
                $okCount++
                continue
            } else {
                # Look for actual errors
                $errLines = $outputStr -split "`n" | Where-Object { $_ -match '^Error:' -or $_ -match 'error:' -or $_ -match 'wrong-type' }
                Write-Host "TANGLE ERR" -ForegroundColor Red
                if ($errLines) {
                    $errLines | Select-Object -First 2 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkRed }
                } else {
                    Write-Host "    (no error message in output)" -ForegroundColor DarkRed
                }
                $errors += $orgRel
                continue
            }
        }

        # Kanata post-processing
        if ($orgRel -eq 'kanata\kanata.org') {
            Repair-KanataFiles -KanataDir (Join-Path $ConfigDir 'kanata')
        }

        # Hash outputs AFTER tangle and compare
        $fileDrift = @()
        foreach ($out in $outputs) {
            $full = Join-Path $ConfigDir $out
            if (-not (Test-Path -LiteralPath $full)) { continue }
            $after = Get-Sha256Hash -Path $full
            if ($before.ContainsKey($out) -and $before[$out] -ne $after) {
                $fileDrift += $out
                $drifted += "$orgRel -> $out"
            }
        }

        if ($fileDrift.Count) {
            Write-Host "DRIFT" -ForegroundColor Yellow
            foreach ($d in $fileDrift) { Write-Host "    -> $d" -ForegroundColor Yellow }
        } else {
            Write-Host "OK" -ForegroundColor Green
            $okCount++
        }
    } finally {
        # Restore originals (read-only)
        foreach ($entry in $backups) {
            Copy-Item -LiteralPath $entry.Backup -Destination $entry.Dest -Force
        }
        if ($backupRoot -and (Test-Path -LiteralPath $backupRoot)) {
            Remove-Item -LiteralPath $backupRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host ""
if ($errors.Count) {
    Write-Host "TANGLE ERRORS ($($errors.Count)):" -ForegroundColor Red
    foreach ($e in $errors) { Write-Host "  $e" }
    Write-Host ""
}
if ($drifted.Count) {
    Write-Host "DRIFT DETECTED ($($drifted.Count) file(s) out of sync):" -ForegroundColor Yellow
    foreach ($d in $drifted) { Write-Host "  $d" }
    Write-Host ""
    Write-Host "Fix: edit the .org source, then run 'tangle all' or 'tangle <stem>'." -ForegroundColor DarkYellow
} else {
    Write-Host "All configs match their .org sources. ✓" -ForegroundColor Green
}
Write-Host ""
Write-Host "Summary: $okCount OK, $($errors.Count) errors, $($drifted.Count) drifted, $skipCount skipped." -ForegroundColor Cyan

if ($drifted.Count -gt 0 -or $errors.Count -gt 0) { exit 1 }
exit 0
