# investigate-drift.ps1
$ErrorActionPreference = 'Continue'
$ConfigDir = "$env:USERPROFILE\.config"
$libPath = Join-Path $ConfigDir "scripts\powershell\_lib\config-paths.ps1"
. $libPath
$emacsExe = Get-EmacsExecutable -Name emacs

function Get-Hash($p) {
    $s = [System.IO.File]::OpenRead($p)
    try { return -join ([System.Security.Cryptography.SHA256]::Create().ComputeHash($s) | ForEach-Object { $_.ToString('x2') }) }
    finally { $s.Close() }
}

function Diff-After-Tangle($orgRel, $outRel) {
    $orgPath = Join-Path $ConfigDir $orgRel
    $outPath = Join-Path $ConfigDir $outRel

    $bak = Join-Path $env:TEMP "drift-diff-$([guid]::NewGuid().ToString('N')).bak"
    Copy-Item $outPath $bak -Force

    $fwd = $orgPath -replace '\\', '/'
    $oldEA = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $text = Invoke-EmacsOrgTangle -EmacsExe $emacsExe -OrgPath $orgPath
    $ErrorActionPreference = $oldEA

    if ($orgRel -match 'kanata') {
        Repair-KanataTangledFiles -KanataDir (Join-Path $ConfigDir 'kanata')
    }

    $oldHash = Get-Hash $bak
    $newHash = Get-Hash $outPath

    Write-Host "=== $orgRel -> $outRel ==="
    Write-Host "Old hash: $oldHash"
    Write-Host "New hash: $newHash"

    if ($oldHash -ne $newHash) {
        $oldLines = Get-Content $bak
        $newLines = Get-Content $outPath
        $diffs = [System.Collections.ArrayList]@()
        $maxLen = [Math]::Max($oldLines.Count, $newLines.Count)
        for ($i = 0; $i -lt $maxLen; $i++) {
            $ol = if ($i -lt $oldLines.Count) { $oldLines[$i] } else { $null }
            $nl = if ($i -lt $newLines.Count) { $newLines[$i] } else { $null }
            if ($ol -ne $nl) {
                [void]$diffs.Add("Line $($i+1):")
                [void]$diffs.Add("  OLD: $ol")
                [void]$diffs.Add("  NEW: $nl")
                if ($diffs.Count -ge 30) { break }
            }
        }
        if ($diffs.Count -ge 30) { Write-Host "  ... ($diffs total differences, showing first 30)" }
        foreach ($d in $diffs) { Write-Host $d }
    }

    # Restore
    Copy-Item $bak $outPath -Force
    Remove-Item $bak -Force
}

Diff-After-Tangle "kanata\kanata.org" "kanata\kanata-plain.kbd"
Write-Host ""
Diff-After-Tangle "scripts\scripts.org" "scripts\powershell\_lib\config-paths.ps1"
