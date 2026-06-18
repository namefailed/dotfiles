param(
    [switch]$Fix
)

$rootDir = Join-Path $env:USERPROFILE 'basic-memory'

Write-Host "🧠 Running Basic Memory Brain Health Linter..." -ForegroundColor Cyan

$mdFiles = Get-ChildItem -Path $rootDir -Filter *.md -Recurse | Where-Object { $_.FullName -notmatch "\\.git\\" }

$errors = 0
$warnings = 0

foreach ($file in $mdFiles) {
    $content = Get-Content $file.FullName -Raw

    if ($file.DirectoryName -ne $rootDir -and $content -notmatch '(?s)^---.+?---') {
        Write-Host "[WARNING] Missing frontmatter: $($file.Name)" -ForegroundColor Yellow
        $warnings++
    }

    $links = [regex]::Matches($content, '\[\[(.*?)\]\]')
    foreach ($match in $links) {
        $linkTarget = $match.Groups[1].Value.Split('|')[0].Split('#')[0]
        $targetName = $linkTarget.Split('/')[-1]

        $escapedLink = [regex]::Escape($linkTarget)
        $targetExists = $mdFiles | Where-Object { 
            ($_.BaseName -eq $targetName) -or ($_.Name -eq $targetName) -or ($_.FullName -match "$escapedLink")
        }

        if (-not $targetExists) {
            Write-Host "[ERROR] Broken WikiLink in $($file.Name): [[$linkTarget]]" -ForegroundColor Red
            $errors++
        }
    }
}

if ($errors -eq 0 -and $warnings -eq 0) {
    Write-Host "✅ Brain is healthy! No broken links or missing frontmatter." -ForegroundColor Green
} else {
    Write-Host "⚠️ Found $errors broken links and $warnings warnings." -ForegroundColor Yellow
}
