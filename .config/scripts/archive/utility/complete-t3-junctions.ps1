# Archived — finish T3/XDG junctions for cursor and vscode-shared.
# Run AFTER closing Cursor and VS Code / Windsurf.

$ErrorActionPreference = 'Stop'

function Complete-Junction {
    param(
        [string]$Name,
        [string]$LockedSubpath
    )

    $src  = "$env:USERPROFILE\.$Name"
    $dst  = "$env:USERPROFILE\.config\$Name"
    $lock = Join-Path $src $LockedSubpath

    Write-Host "`n=== $Name ===" -ForegroundColor Cyan

    $item = Get-Item $src -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -eq 'Junction') {
        Write-Host "  Already a junction -> $($item.Target)" -ForegroundColor Green
        return
    }

    if (Test-Path $lock) {
        try {
            $fs = [System.IO.File]::Open($lock, 'Open', 'Read', 'None')
            $fs.Close()
            Write-Host '  Lock released — proceeding.' -ForegroundColor Green
        } catch {
            Write-Warning "  $lock is still locked. Close $Name and try again."
            return
        }
    }

    Write-Host "  Moving remaining files from $src -> $dst"
    robocopy $src $dst /E /MOVE /NFL /NDL /NJH /NJS | Out-Null

    if (Test-Path $src) {
        Remove-Item $src -Recurse -Force
    }

    cmd.exe /c "mklink /J `"$src`" `"$dst`"" | Out-Null
    $j = Get-Item $src
    if ($j.LinkType -eq 'Junction') {
        Write-Host "  Junction created: $src <<===>> $dst" -ForegroundColor Green
    } else {
        Write-Error "  Junction creation failed for $Name"
    }
}

Complete-Junction -Name 'cursor'       -LockedSubpath 'ai-tracking\ai-code-tracking.db'
Complete-Junction -Name 'vscode-shared' -LockedSubpath 'sharedStorage\state.vscdb'

Write-Host "`nDone. Verify with: Get-Item ~/.cursor, ~/.vscode-shared" -ForegroundColor Cyan
