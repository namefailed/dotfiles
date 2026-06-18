# Toggle komorebi-bar and restart komorebi so the WM recalculates the work area.

$ErrorActionPreference = 'Stop'

$barName = 'komorebi-bar'
$wmName  = 'komorebi'

function Restart-Komorebi {
    $wm = Get-Process -Name $wmName -ErrorAction SilentlyContinue
    if (-not $wm) {
        Write-Warning "Process '$wmName' not running - skipping WM restart."
        return
    }

    Stop-Process -Id $wm.Id -Force
    Start-Sleep -Milliseconds 600

    $wmExe = (Get-Command 'komorebi.exe' -ErrorAction SilentlyContinue).Source
    if (-not $wmExe) {
        Write-Error 'komorebi.exe not found on PATH.'
        exit 2
    }

    Start-Process -FilePath $wmExe -WindowStyle Hidden
}

$running = [bool](Get-Process -Name $barName -ErrorAction SilentlyContinue)

if ($running) {
    Stop-Process -Name $barName -Force
} else {
    $barExe = (Get-Command 'komorebi-bar.exe' -ErrorAction SilentlyContinue).Source
    if (-not $barExe) {
        Write-Error 'komorebi-bar.exe not found on PATH.'
        exit 1
    }
    Start-Process -FilePath $barExe -WindowStyle Hidden
}

Start-Sleep -Milliseconds 250
Restart-Komorebi
