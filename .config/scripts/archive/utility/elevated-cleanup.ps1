# Archived — elevated one-off cleanup. Run as Administrator.

Write-Host 'Elevated cleanup...'

if (Test-Path 'C:\$SysReset') {
    takeown /F 'C:\$SysReset' /R /D Y 2>$null
    icacls 'C:\$SysReset' /grant Administrators:F /T 2>$null
    Remove-Item 'C:\$SysReset' -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host '  [OK] C:\$SysReset'
}

if (Test-Path 'C:\Program Files\Microsoft Office 15') {
    Remove-Item 'C:\Program Files\Microsoft Office 15' -Recurse -Force
    Write-Host '  [OK] Microsoft Office 15'
}

if (Test-Path 'C:\Program Files (x86)\GnuWin32') {
    Remove-Item 'C:\Program Files (x86)\GnuWin32' -Recurse -Force
    Write-Host '  [OK] GnuWin32'
}

$empty = @(
    'C:\Program Files\Uninstall Information',
    'C:\Program Files\Windows Sidebar',
    'C:\Program Files (x86)\Windows Sidebar'
)
foreach ($d in $empty) {
    if (Test-Path $d) { Remove-Item $d -Force; Write-Host "  [OK] $d" }
}

$stubs = @(
    'C:\Program Files (x86)\Diablo IV',
    'C:\Program Files (x86)\Diablo II Resurrected'
)
foreach ($d in $stubs) {
    if (Test-Path $d) { Remove-Item $d -Recurse -Force; Write-Host "  [OK] $d" }
}

Write-Host 'All done!'
