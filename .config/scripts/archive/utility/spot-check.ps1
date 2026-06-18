# spot-check.ps1
$ErrorActionPreference = 'Continue'
$emacsExe = "C:\Program Files\Emacs\emacs-30.2\bin\emacs.exe"
$org = "C:/Users/Namef/.config/kanata/kanata.org"
$kbd = "C:/Users/Namef/.config/kanata/kanata.kbd"
$bak = Join-Path $env:TEMP "kkbd-bak-check"
Copy-Item $kbd $bak -Force
$fwdOrg = $org
$null = & $emacsExe --batch --eval '(require (quote org))' --eval '(require (quote ob-tangle))' --eval '(setq coding-system-for-write (quote utf-8-unix))' --eval '(setq org-confirm-babel-evaluate nil)' $fwdOrg --eval '(org-babel-tangle)' 2>&1
Write-Host "=== Matching lines with 'replace-regexp-in-string' ==="
Select-String -Path $kbd -Pattern 'replace-regexp-in-string' -SimpleMatch | Select-Object -First 5 | ForEach-Object { $l = $_.Line; $h = [System.BitConverter]::ToString([System.Text.Encoding]::UTF8.GetBytes($l)); Write-Host "LINE: $l"; Write-Host "HEX:  $h"; Write-Host "" }
Write-Host "=== Lines with 'config-scripts-fwd' ==="
Select-String -Path $kbd -Pattern 'config-scripts-fwd' -SimpleMatch | Select-Object -First 5 | ForEach-Object { Write-Host $_.Line }
Copy-Item $bak $kbd -Force; Remove-Item $bak -Force
