# Start Phoneme dev stack: daemon (foreground) + Vite HMR + cargo tauri dev.
# Prefers WezTerm (wezterm start); falls back to Start-Process pwsh.
# Usage:
#   dev-phoneme
#   dev-phoneme -KillStaleDaemon
#   $env:PHONEME_ROOT = 'D:\src\phoneme'; dev-phoneme

param(
    [string]$Root = $(if ($env:PHONEME_ROOT) { $env:PHONEME_ROOT } else { Join-Path $HOME 'Projects\dev\phoneme' }),
    [switch]$KillStaleDaemon
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-WezTermExe {
    $cmd = Get-Command wezterm -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($p in @(
        "$env:LOCALAPPDATA\Programs\WezTerm\wezterm.exe",
        "$env:ProgramFiles\WezTerm\wezterm.exe"
    )) {
        if (Test-Path -LiteralPath $p) { return $p }
    }
    return $null
}

function Start-PhonemeDevTerminal {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$Command
    )
    $wez = Resolve-WezTermExe
    if ($wez) {
        Start-Process -FilePath $wez -ArgumentList @(
            'start',
            '--cwd', $WorkingDirectory,
            '--title', $Title,
            '--', 'pwsh', '-NoExit', '-Command', $Command
        )
    } else {
        $wrapper = "Set-Location '$WorkingDirectory'; $Command"
        Start-Process pwsh -ArgumentList @('-NoExit', '-Command', $wrapper)
    }
}

if (-not (Test-Path -LiteralPath $Root)) {
    throw "Phoneme repo not found: $Root (set `$env:PHONEME_ROOT or pass -Root)"
}

$frontend = Join-Path $Root 'frontend'
if (-not (Test-Path -LiteralPath $frontend)) {
    throw "Missing frontend/: $frontend"
}

if ($KillStaleDaemon) {
    Stop-Process -Name phoneme-daemon -Force -ErrorAction SilentlyContinue
}

$termLabel = if (Resolve-WezTermExe) { 'WezTerm' } else { 'pwsh (default terminal)' }
Write-Host "Phoneme dev stack → $Root" -ForegroundColor Cyan
Write-Host "Terminal launcher: $termLabel" -ForegroundColor DarkCyan

$daemonCmd = @"
Write-Host '=== phoneme-daemon ===' -ForegroundColor Cyan
`$env:RUST_LOG = 'info'
cargo run -p phoneme-daemon -- --foreground
"@

$viteCmd = @"
Write-Host '=== Vite HMR ===' -ForegroundColor Green
pnpm dev
"@

$tauriCmd = @"
Write-Host '=== cargo tauri dev ===' -ForegroundColor Yellow
cargo tauri dev
"@

Start-PhonemeDevTerminal -Title 'phoneme-daemon' -WorkingDirectory $Root -Command $daemonCmd
Start-PhonemeDevTerminal -Title 'phoneme-vite' -WorkingDirectory $frontend -Command $viteCmd

Write-Host 'Waiting for http://localhost:5173 ...'
do {
    Start-Sleep -Milliseconds 400
    $up = $false
    try {
        $up = (Invoke-WebRequest -Uri 'http://localhost:5173' -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200
    } catch {}
} until ($up)

Start-PhonemeDevTerminal -Title 'phoneme-tauri' -WorkingDirectory $Root -Command $tauriCmd

Write-Host 'All three processes started in separate windows.' -ForegroundColor Green
