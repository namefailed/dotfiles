# config-paths.ps1 — portable path helpers (no hardcoded Windows account names).
# Dot-source only; does not modify the caller's ErrorActionPreference.

$script:ConfigRoot      = Join-Path $env:USERPROFILE '.config'
$script:OrgRoot          = Join-Path $env:USERPROFILE 'Documents\org'
$script:BasicMemoryRoot  = Join-Path $env:USERPROFILE 'basic-memory'
$script:EmacsInitDir     = Join-Path $script:ConfigRoot 'emacs'
$script:KanataDir        = Join-Path $script:ConfigRoot 'kanata'
$script:ConfigScriptsRoot = Join-Path $script:ConfigRoot 'scripts'

function Get-EmacsExecutable {
    param(
        [ValidateSet('emacs', 'emacsclient', 'emacsclientw', 'runemacs')]
        [string]$Name = 'emacs'
    )

    $candidates = @(
        "C:\Program Files\Emacs\emacs-30.2\bin\$Name.exe",
        "C:\Program Files\Emacs\emacs-30.1\bin\$Name.exe",
        (Join-Path 'C:\tools\emacs\bin' "$Name.exe"),
        (Join-Path (Join-Path $env:ProgramData 'chocolatey\bin') "$Name.exe")
    )

    foreach ($path in $candidates) {
        if (Test-Path -LiteralPath $path) { return $path }
    }

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    return $null
}

function Resolve-WinGetPackageExe {
    param(
        [Parameter(Mandatory)]
        [string]$PackageIdPart,

        [Parameter(Mandatory)]
        [string]$ExeFileName
    )

    $base = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (-not (Test-Path -LiteralPath $base)) { return $null }

    foreach ($pkg in Get-ChildItem -LiteralPath $base -Directory -ErrorAction SilentlyContinue) {
        if ($pkg.Name -notlike "*$PackageIdPart*") { continue }

        $direct = Join-Path $pkg.FullName $ExeFileName
        if (Test-Path -LiteralPath $direct) { return $direct }

        foreach ($sub in Get-ChildItem -LiteralPath $pkg.FullName -Directory -ErrorAction SilentlyContinue) {
            $nested = Join-Path $sub.FullName $ExeFileName
            if (Test-Path -LiteralPath $nested) { return $nested }
        }
    }

    $cmd = Get-Command $ExeFileName -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    return $null
}

function Repair-KanataTangledFiles {
    param(
        [string]$KanataDir = $script:KanataDir
    )

    if (-not $KanataDir) {
        $KanataDir = Join-Path $env:USERPROFILE '.config\kanata'
    }

    $scriptsFwd = (Join-Path $env:USERPROFILE '.config\scripts') -replace '\\', '/'
    $olkFwd = (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\olk.exe') -replace '\\', '/'
    $brokenScripts = '(replace-regexp-in-string "\\\\" "/" (expand-file-name "~/.config/scripts"))'

    foreach ($kbdName in @('kanata.kbd', 'kanata-plain.kbd', 'external.kbd')) {
        $kbdPath = Join-Path $KanataDir $kbdName
        if (-not (Test-Path -LiteralPath $kbdPath)) { continue }

        $kbdText = Get-Content -LiteralPath $kbdPath -Raw
        $kbdText = $kbdText.Replace('<<config-scripts-fwd>>', $scriptsFwd).Replace($brokenScripts, $scriptsFwd)
        $kbdText = $kbdText.Replace('<<local-windowsapps-olk>>', $olkFwd)
        if ($kbdText -match 'expand-file-name "~/AppData/Local/Microsoft/WindowsApps/olk') {
            $kbdText = [regex]::Replace(
                $kbdText,
                '\(replace-regexp-in-string "\\\\" "/" \(expand-file-name "~/AppData/Local/Microsoft/WindowsApps/olk\.exe"\)\)',
                $olkFwd)
        }
        Set-Content -LiteralPath $kbdPath -Value $kbdText -NoNewline
    }
}

function Get-OrgPreexecuteNowebElPath {
    Join-Path $script:ConfigScriptsRoot 'utility\org-preexecute-noweb-blocks.el'
}

function Test-OrgUsesNoweb {
    param([Parameter(Mandatory)][string]$OrgPath)
    $raw = Get-Content -LiteralPath $OrgPath -Raw -ErrorAction SilentlyContinue
    return ($raw -match '(?m):noweb\s+yes')
}

function Get-ConfigOrgDriftMap {
    [ordered]@{
        'komorebi\komorebi.org'                 = @('komorebi\komorebi.json', 'komorebi\komorebi.bar.json')
        'kanata\kanata.org'                     = @('kanata\kanata.kbd', 'kanata\kanata-plain.kbd')
        'doom\init.org'                         = @('doom\init.el', 'doom\packages.el')
        'doom\config.org'                       = @('doom\config.el')
        'wtq\wtq.org'                           = @('wtq\wtq.jsonc')
        'starship\starship.org'                 = @('starship\starship.toml')
        'git\git.org'                           = @('git\config')
        'espanso\espanso.org'                   = @('espanso\config\default.yml', 'espanso\match\base.yml')
        'vscode\vscode.org'                     = @('vscode\settings.json', 'vscode\keybindings.json')
        'windsurf\windsurf.org'                 = @('windsurf\settings.json', 'windsurf\keybindings.json')
        'wezterm\wezterm.org'                   = @('wezterm\wezterm.lua')
        'tridactyl\tridactyl.org'               = @('tridactyl\.tridactylrc', 'tridactyl\native\tridactyl.json')
        'everything\everything.org'             = @('everything\Everything.ini')
        'windows-terminal\windows-terminal.org' = @('windows-terminal\settings.json')
        'powershell\powershell.org'             = @('powershell\Microsoft.PowerShell_profile.ps1')
        'flowlauncher\flowlauncher.org'         = @('flowlauncher\settings\Settings.json')
        'hermes\hermes.org'                     = @('hermes\config.yaml', 'hermes\.gitignore')
        'scripts\scripts.org'                 = @(
            'scripts\_lib\config-paths.ps1'
            'scripts\utility\tangle-configs.ps1'
            'scripts\utility\verify-org-tangle-sync.ps1'
        )
    }
}

function Invoke-EmacsOrgTangle {
    param(
        [Parameter(Mandatory)][string]$EmacsExe,
        [Parameter(Mandatory)][string]$OrgPath
    )

    $fwd = $OrgPath -replace '\\', '/'
    $emacsArgs = @(
        '--batch'
        '--eval', '(require ''org)'
        '--eval', '(require ''ob-tangle)'
        '--eval', '(require ''ob-python nil t)'
        '--eval', '(setq coding-system-for-write ''utf-8-unix)'
        '--eval', '(setq org-confirm-babel-evaluate nil)'
    )

    if ((Test-OrgUsesNoweb -OrgPath $OrgPath) -and (Test-Path -LiteralPath (Get-OrgPreexecuteNowebElPath))) {
        $nowebEl = (Get-OrgPreexecuteNowebElPath) -replace '\\', '/'
        $emacsArgs += '--load', $nowebEl
        $emacsArgs += '--eval', '(my/org-preexecute-noweb-blocks)'
    }

    $emacsArgs += $fwd
    $emacsArgs += '--eval', '(org-babel-tangle)'

    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $out = & $EmacsExe @emacsArgs 2>&1
    $ErrorActionPreference = $old
    return ($out -join "`n")
}
