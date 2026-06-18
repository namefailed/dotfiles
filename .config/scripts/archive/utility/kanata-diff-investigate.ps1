# kanata-diff-investigate.ps1
# Compare on-disk kanata.kbd with freshly tangled version
$ErrorActionPreference = 'Continue'
$ConfigDir = "$env:USERPROFILE\.config"
$emacsExe = "C:\Program Files\Emacs\emacs-30.2\bin\emacs.exe"
$orgPath = Join-Path $ConfigDir "kanata\kanata.org"
$kbdPath = Join-Path $ConfigDir "kanata\kanata.kbd"
$plainPath = Join-Path $ConfigDir "kanata\kanata-plain.kbd"

function Get-Hash($p) {
    $s = [System.IO.File]::OpenRead($p)
    try { return -join ([System.Security.Cryptography.SHA256]::Create().ComputeHash($s) | ForEach-Object { $_.ToString('x2') }) }
    finally { $s.Close() }
}

Write-Host "=== On-disk hashes ==="
Write-Host ("  kanata.kbd: " + (Get-Hash $kbdPath))
Write-Host ("  kanata-plain.kbd: " + (Get-Hash $plainPath))

# Backup
$bak1 = Join-Path $env:TEMP "kanata-kbd-bak"
$bak2 = Join-Path $env:TEMP "kanata-plain-kbd-bak"
Copy-Item $kbdPath $bak1 -Force
Copy-Item $plainPath $bak2 -Force

# Tangle
$fwdOrg = $orgPath -replace '\\', '/'
Write-Host "`nTangling kanata.org..."
$raw = & $emacsExe --batch --eval '(require (quote org))' --eval '(require (quote ob-tangle))' --eval '(setq coding-system-for-write (quote utf-8-unix))' --eval '(setq org-confirm-babel-evaluate nil)' $fwdOrg --eval '(org-babel-tangle)' 2>&1
Write-Host ("  " + ($raw | Out-String).Trim())

# Kanata post-fix
$sf = (Join-Path $ConfigDir "scripts") -replace '\\', '/'
foreach ($kp in @($kbdPath, $plainPath)) {
    $txt = Get-Content $kp -Raw
    $txt = $txt.Replace('<<config-scripts-fwd>>', $sf)
    $txt = $txt.Replace('(replace-regexp-in-string "\\" "/" (expand-file-name "~/.config/scripts"))', $sf)
    Set-Content $kp -Value $txt -NoNewline
}

Write-Host "`n=== Tangled hashes (after post-fix) ==="
Write-Host ("  kanata.kbd: " + (Get-Hash $kbdPath))
Write-Host ("  kanata-plain.kbd: " + (Get-Hash $plainPath))

# Show differences
Write-Host "`n=== Diff kanata.kbd (old vs new) ==="
$oldLines = Get-Content $bak1
$newLines = Get-Content $kbdPath
if ($oldLines.Count -ne $newLines.Count) {
    Write-Host ("Line count mismatch: old=$($oldLines.Count) new=$($newLines.Count)")
}
$diffs = [System.Collections.ArrayList]@()
for ($i = 0; $i -lt [Math]::Max($oldLines.Count, $newLines.Count); $i++) {
    $ol = if ($i -lt $oldLines.Count) { $oldLines[$i] } else { $null }
    $nl = if ($i -lt $newLines.Count) { $newLines[$i] } else { $null }
    if ($ol -ne $nl) {
        [void]$diffs.Add("Line $($i+1):")
        [void]$diffs.Add("  OLD: $ol")
        [void]$diffs.Add("  NEW: $nl")
    }
}
$showCount = [Math]::Min($diffs.Count, 30)
for ($i = 0; $i -lt $showCount; $i++) {
    Write-Host ("  " + $diffs[$i])
}
if ($diffs.Count -gt 30) {
    Write-Host ("  ... ($($diffs.Count - 30) more diff lines)")
}

# Restore originals
Copy-Item $bak1 $kbdPath -Force
Copy-Item $bak2 $plainPath -Force
Remove-Item $bak1 -Force
Remove-Item $bak2 -Force
