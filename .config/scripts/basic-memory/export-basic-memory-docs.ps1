# Export Denote note-taking-workflow.org -> Basic Memory bootstrap markdown.
# Usage:
#   .\export-basic-memory-docs.ps1

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\_lib\config-paths.ps1')

$emacsExe = Get-EmacsExecutable -Name emacs
if (-not $emacsExe) { Write-Error 'Emacs not found'; exit 1 }

$orgFile = Get-ChildItem -Path (Join-Path $env:USERPROFILE 'Documents\org\notes\personal') `
    -Filter '*note*taking*workflow*.org' | Select-Object -First 1
if (-not $orgFile) { Write-Error 'note-taking-workflow.org not found'; exit 1 }

$outPath = Join-Path $env:USERPROFILE 'basic-memory\bootstrap\note-taking-workflow.md'
$orgFwd = ($orgFile.FullName -replace '\\', '/') -replace '"', '\"'
$outFwd = ($outPath -replace '\\', '/') -replace '"', '\"'

Write-Host "Exporting: $($orgFile.FullName)" -ForegroundColor Cyan

$elispPath = Join-Path $env:TEMP 'export-note-taking-workflow.el'
@(
    '(require ''ox-md)'
    '(setq coding-system-for-write ''utf-8-unix)'
    "(find-file `"$orgFwd`")"
    "(org-export-to-file 'md `"$outFwd`")"
    '(kill-emacs 0)'
) | Set-Content -Path $elispPath -Encoding utf8

& $emacsExe --batch -l $elispPath 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $outPath)) {
    Write-Host "Exported: $outPath" -ForegroundColor Green
} else {
    Write-Error 'Export failed'
    exit 1
}
