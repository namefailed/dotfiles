$rootDir = Join-Path $env:USERPROFILE 'basic-memory'

Set-Location $rootDir
$status = git status --porcelain

if ($status) {
    git add .
    git commit -m "Auto-snapshot: Daily maintenance and brain updates"
    git push origin main
    Write-Host "SUCCESS: Auto-commit pushed to remote." -ForegroundColor Green
} else {
    Write-Host "SUCCESS: No changes to commit." -ForegroundColor Green
}
