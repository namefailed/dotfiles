<#
.SYNOPSIS
  Generic tangle fallback when Emacs batch-mode org-babel-tangle produces 0 blocks.
  Extracts code blocks from a literate .org file by matching #+begin_src LANG :tangle TARGET
  patterns and writes each target file. Handles multiple targets per org file.
.PARAMETER OrgFile
  Path to the .org file to extract blocks from.
.PARAMETER ConfigRoot
  Root directory for resolving relative :tangle paths. Defaults to the org file's parent.
#>
param(
    [Parameter(Mandatory)][string]$OrgFile,
    [string]$ConfigRoot
)

if (-not $ConfigRoot) {
    $ConfigRoot = Split-Path $OrgFile -Parent
}

$lines = Get-Content $OrgFile -Encoding utf8

$targets = @{}
$currentTarget = $null
$inBlock = $false

foreach ($line in $lines) {
    if ($line -match '^#\+begin_src\s+\w+\s+:tangle\s+(\S+)') {
        $currentTarget = $Matches[1]
        if (-not [System.IO.Path]::IsPathRooted($currentTarget)) {
            $currentTarget = Join-Path $ConfigRoot $currentTarget
        }
        $inBlock = $true
        if (-not $targets.ContainsKey($currentTarget)) {
            $targets[$currentTarget] = @()
        }
    } elseif ($line -match '^#\+end_src') {
        $inBlock = $false
        $currentTarget = $null
    } elseif ($inBlock -and $currentTarget) {
        $targets[$currentTarget] += $line
    }
}

$totalLines = 0
foreach ($target in $targets.Keys) {
    $content = $targets[$target]
    $content | Set-Content $target -Encoding utf8
    $totalLines += $content.Count
    Write-Host "  $target ($($content.Count) lines)" -ForegroundColor Green
}
Write-Host "Fallback tangle: $($targets.Keys.Count) file(s), $totalLines total lines" -ForegroundColor Cyan
