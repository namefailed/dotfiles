# diagnose-tangle-errors.ps1
$ErrorActionPreference = 'Continue'
$ConfigDir = "$env:USERPROFILE\.config"
$libPath = Join-Path $ConfigDir "scripts\powershell\_lib\config-paths.ps1"
. $libPath
$emacsExe = Get-EmacsExecutable -Name emacs

function Test-Tangle($orgRel) {
    $orgPath = Join-Path $ConfigDir $orgRel
    $fwd = $orgPath -replace '\\', '/'
    Write-Host "=== $orgRel ==="
    $oldEA = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = Invoke-EmacsOrgTangle -EmacsExe $emacsExe -OrgPath $orgPath
    $ErrorActionPreference = $oldEA
    Write-Host $output
    Write-Host ""
}

Test-Tangle "kanata\kanata.org"
Test-Tangle "scripts\scripts.org"
