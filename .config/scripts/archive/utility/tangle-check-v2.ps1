# tangle-check-v2.ps1 — detect drift between .org sources and tangled outputs
$ErrorActionPreference = 'Stop'
$ConfigDir = "$env:USERPROFILE\.config"
$emacsExe = "C:\Program Files\Emacs\emacs-30.2\bin\emacs.exe"

$driftMap = @{}
$driftMap['komorebi\komorebi.org'] = @('komorebi\komorebi.json','komorebi\komorebi.bar.json')
$driftMap['kanata\kanata.org'] = @('kanata\kanata.kbd','kanata\kanata-plain.kbd')
$driftMap['doom\config.org'] = @('doom\config.el')
$driftMap['wtq\wtq.org'] = @('wtq\wtq.jsonc')
$driftMap['starship\starship.org'] = @('starship\starship.toml')
$driftMap['git\git.org'] = @('git\gitconfig')
$driftMap['espanso\espanso.org'] = @('espanso\config\default.yml','espanso\match\base.yml')
$driftMap['vscode\vscode.org'] = @('vscode\settings.json','vscode\keybindings.json')
$driftMap['cursor\cursor.org'] = @('cursor\settings.json','cursor\keybindings.json')
$driftMap['windsurf\windsurf.org'] = @('windsurf\settings.json','windsurf\keybindings.json')
$driftMap['tridactyl\tridactyl.org'] = @('tridactyl\.tridactylrc','tridactyl\native\tridactyl.json')
$driftMap['everything\everything.org'] = @('everything\Everything.ini')
$driftMap['windows-terminal\windows-terminal.org'] = @('windows-terminal\settings.json')
$driftMap['powershell\powershell.org'] = @('powershell\Microsoft.PowerShell_profile.ps1')
$driftMap['flowlauncher\flowlauncher.org'] = @('flowlauncher\settings\Settings.json')
$driftMap['hermes\hermes.org'] = @('hermes\config.yaml','hermes\.gitignore')
$driftMap['scripts\scripts.org'] = @('scripts\powershell\_lib\config-paths.ps1','scripts\powershell\utility\tangle-configs.ps1','scripts\powershell\utility\verify-org-tangle-sync.ps1')

function Get-Hash {
    param([string]$Path)
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($stream)
        return -join ($hashBytes | ForEach-Object { $_.ToString('x2') })
    } finally {
        $stream.Close()
    }
}

$drifted = @()
$errors = @()
$ok = 0

foreach ($k in $driftMap.Keys) {
    $orgPath = Join-Path $ConfigDir $k
    if (-not (Test-Path $orgPath)) { continue }

    $before = @{}
    $existing = @()
    foreach ($t in $driftMap[$k]) {
        $f = Join-Path $ConfigDir $t
        if (Test-Path $f) {
            $before[$t] = Get-Hash $f
            $existing += $f
        }
    }

    $backupRoot = Join-Path $env:TEMP ('tc-' + [guid]::NewGuid().ToString('N'))
    $backups = @()
    foreach ($f in $existing) {
        $rel = $f.Substring($ConfigDir.Length + 1)
        $bak = Join-Path $backupRoot $rel
        $bakDir = Split-Path $bak -Parent
        if ($bakDir -and -not (Test-Path $bakDir)) { New-Item -ItemType Directory -Path $bakDir -Force | Out-Null }
        Copy-Item $f $bak -Force
        $backups += @{ Dest = $f; Bak = $bak }
    }

    Write-Host ('  ' + $k + '... ') -NoNewline
    try {
        $fwdOrg = $orgPath -replace '\\', '/'
        $oldEA = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $raw = & $emacsExe --batch --eval '(require (quote org))' --eval '(require (quote ob-tangle))' --eval '(setq coding-system-for-write (quote utf-8-unix))' --eval '(setq org-confirm-babel-evaluate nil)' $fwdOrg --eval '(org-babel-tangle)' 2>&1
        $ErrorActionPreference = $oldEA
        $out = $raw | Out-String

        if ($out -match 'Tangled \d+ code') {
            # Kanata post-processing
            if ($k -match 'kanata') {
                $sf = ($ConfigDir + '\scripts') -replace '\\', '/'
                foreach ($kn in @('kanata\kanata.kbd', 'kanata\kanata-plain.kbd')) {
                    $kp = Join-Path $ConfigDir $kn
                    if (Test-Path $kp) {
                        $txt = Get-Content $kp -Raw
                        $txt = $txt.Replace('<<config-scripts-fwd>>', $sf)
                        Set-Content $kp -Value $txt -NoNewline
                    }
                }
            }

            $fileDrift = @()
            foreach ($t in $driftMap[$k]) {
                $f = Join-Path $ConfigDir $t
                if ((Test-Path $f) -and $before.ContainsKey($t) -and ($before[$t] -ne (Get-Hash $f))) {
                    $fileDrift += $t
                    $drifted += "$k -> $t"
                }
            }

            if ($fileDrift.Count -gt 0) {
                Write-Host 'DRIFT' -ForegroundColor Yellow
                foreach ($d in $fileDrift) { Write-Host ('    -> ' + $d) -ForegroundColor Yellow }
            } else {
                Write-Host 'OK' -ForegroundColor Green
                $ok++
            }
        } elseif ($out -match 'Tangled 0') {
            Write-Host '0 blocks' -ForegroundColor DarkYellow
            $ok++
        } else {
            Write-Host 'ERR' -ForegroundColor Red
            $errors += $k
        }
    } finally {
        # Restore originals (read-only check)
        foreach ($e in $backups) { Copy-Item $e.Bak $e.Dest -Force }
        if (Test-Path $backupRoot) { Remove-Item $backupRoot -Recurse -Force }
    }
}

Write-Host ''
if ($errors.Count -gt 0) {
    Write-Host ('TANGLE ERRORS: ' + $errors.Count) -ForegroundColor Red
    foreach ($e in $errors) { Write-Host ('  ' + $e) }
}
if ($drifted.Count -gt 0) {
    Write-Host ('DRIFT DETECTED: ' + $drifted.Count + ' file(s)') -ForegroundColor Yellow
    foreach ($d in $drifted) { Write-Host ('  ' + $d) }
} else {
    Write-Host 'All configs match their .org sources.' -ForegroundColor Green
}
Write-Host ('Passed: ' + $ok + ' Errors: ' + $errors.Count + ' Drifted: ' + $drifted.Count)

if ($drifted.Count -gt 0 -or $errors.Count -gt 0) { exit 1 }
