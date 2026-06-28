# startup-orchestrator.ps1 — Master startup script.
# Replaces all individual shortcuts in the ProgramData Startup folder.

function Wait-ForProcess {
    param($Name, $TimeoutSecs = 10)
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while (-not (Get-Process -Name $Name -ErrorAction SilentlyContinue)) {
        if ($sw.Elapsed.TotalSeconds -gt $TimeoutSecs) { return $false }
        Start-Sleep -Milliseconds 250
    }
    return $true
}

$profile = $env:USERPROFILE
$configRoot = "$profile\.config"
$kanataDir = "$configRoot\kanata"

. (Join-Path $profile '.config\scripts\_lib\config-paths.ps1')

# ===== Group 0: Enforce Windows settings before anything else =====
$enforceScript = "$profile\.config\scripts\komorebi\enforce-windows-settings.ps1"
if (Test-Path $enforceScript) {
    Start-Process "pwsh.exe" -ArgumentList "-ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File `"$enforceScript`"" -WindowStyle Hidden
}

$emacsRun = Get-EmacsExecutable -Name runemacs
$espansoExe = "$env:LOCALAPPDATA\Programs\Espanso\espansod.exe"
$kanataExe = "$kanataDir\kanata_windows_gui_wintercept_cmd_allowed_x64.exe"

# ===== Group 1: Background services =====
$tailscaleExe = (Get-Command 'tailscale-ipn.exe' -ErrorAction SilentlyContinue).Source
if (-not $tailscaleExe) { $tailscaleExe = "C:\Program Files\Tailscale\tailscale-ipn.exe" }
if (Test-Path $tailscaleExe) { Start-Process $tailscaleExe -WindowStyle Hidden -ErrorAction SilentlyContinue }

if (Test-Path "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe") {
    Start-Process "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe" -ArgumentList "serve" -WindowStyle Hidden -ErrorAction SilentlyContinue
}
$ps1 = "$profile\.config\scripts\basic-memory\start-basic-memory-server.ps1"
if (Test-Path $ps1) {
    Start-Process "pwsh.exe" -ArgumentList "-ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File `"$ps1`"" -WindowStyle Hidden
}

if ($emacsRun) {
    Start-Process $emacsRun -ArgumentList "--init-directory `"$configRoot\emacs`" --daemon --chdir `"$profile`"" -WindowStyle Hidden
}

# Start menu killer — kills StartMenuExperienceHost + SearchHost on a 1s cycle
# so the Win11 Start menu and taskbar search dropdown cannot render. IFEO does
# not work on Win11 25H2 (UWP packages bypass it); a persistent watchdog is
# the only reliable mechanism.
$smkPs1 = "$profile\.config\scripts\startup\start-menu-killer.ps1"
if (Test-Path $smkPs1) {
    Start-Process "pwsh.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$smkPs1`"" -WindowStyle Hidden
}

Start-Sleep -Seconds 2

# ===== Group 2: Lightweight user apps =====
if (Test-Path $espansoExe) { Start-Process $espansoExe -ArgumentList "launcher" -WindowStyle Hidden }
if (Test-Path $kanataExe) {
  # Pass all 3 configs so the tray icon shows switchable profiles.
  $allArgs = @("-c", "$kanataDir\kanata.kbd", "-c", "$kanataDir\external.kbd", "-c", "$kanataDir\kanata-plain.kbd")
  Start-Process $kanataExe -ArgumentList $allArgs -WorkingDirectory $kanataDir -WindowStyle Hidden
}

Start-Sleep -Seconds 2

# ===== Group 3: WTQ → Komorebi =====
# ORDERING: WTQ starts WezTerm with the --class QuakeTerm argument.
# Because WezTerm is a native Win32 app, the class is applied at process birth.
# Komorebi's ignore_rules match this class instantly, so the race conditions
# that plagued Windows Terminal are permanently solved.
$wtqExe = Resolve-WinGetPackageExe -PackageIdPart 'flyingpie.windows-terminal-quake' -ExeFileName 'wtq.exe'
if ($wtqExe) { Start-Process $wtqExe -WindowStyle Hidden }

# Wait for WTQ to initialize its WezTerm instance before launching Komorebi.
Wait-ForProcess -Name "wtq" -TimeoutSecs 10 | Out-Null
Start-Sleep -Seconds 5

$komorebicExe = (Get-Command 'komorebic-no-console.exe' -ErrorAction SilentlyContinue).Source
if (-not $komorebicExe) { $komorebicExe = "C:\Program Files\komorebi\bin\komorebic-no-console.exe" }
if (Test-Path $komorebicExe) {
    Start-Process $komorebicExe -ArgumentList "start --ffm --config `"$profile\.config\komorebi\komorebi.json`"" -WindowStyle Hidden
}

# Wait for komorebi daemon to fully start before launching bars
Wait-ForProcess -Name "komorebi" -TimeoutSecs 10 | Out-Null
Start-Sleep -Seconds 3

# Start standalone bar instances for dual monitors
$barConfigs = @(
    "$env:USERPROFILE\.config\komorebi\komorebi.bar.json",
    "$env:USERPROFILE\.config\komorebi\komorebi.bar.top.json"
)
$barExe = (Get-Command 'komorebi-bar.exe' -ErrorAction SilentlyContinue).Source
if (-not $barExe) { $barExe = "C:\Program Files\komorebi\bin\komorebi-bar.exe" }
if (Test-Path $barExe) {
    foreach ($config in $barConfigs) {
        if (Test-Path $config) {
            Start-Process -FilePath $barExe -ArgumentList '--config', $config -WindowStyle Hidden -ErrorAction SilentlyContinue
        }
    }
}
# ===== Group 4: AI services =====
Start-Sleep -Seconds 2
$hermesExe = "$env:LOCALAPPDATA\hermes\hermes-agent\venv\Scripts\hermes.exe"
if (Test-Path $hermesExe) {
    Start-Process "pwsh.exe" -ArgumentList "-WindowStyle Hidden -Command `"& '$hermesExe' gateway run --replace`"" -WorkingDirectory $profile -WindowStyle Hidden
}
# Gateway health watchdog — persistent daemon (loop, not scheduled task)
$daemonPs1 = "$profile\.config\scripts\hermes\hermes-gateway-healthcheck-daemon.ps1"
if (Test-Path $daemonPs1) {
    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$daemonPs1`"" -WindowStyle Hidden
}
