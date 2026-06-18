$rootDir = Join-Path $env:USERPROFILE 'basic-memory'
$mdFiles = Get-ChildItem -Path $rootDir -Filter *.md -Recurse | Where-Object { $_.FullName -notmatch "\\.git\\" }

$linksDict = @{}

# Parse all files to build the backlinks dictionary
foreach ($file in $mdFiles) {
    $content = Get-Content $file.FullName -Raw
    $links = [regex]::Matches($content, '\[\[(.*?)\]\]')
    
    foreach ($match in $links) {
        $target = $match.Groups[1].Value.Split('|')[0].Split('#')[0]
        $targetBasename = $target.Split('/')[-1]
        
        if (-not $linksDict.ContainsKey($targetBasename)) {
            $linksDict[$targetBasename] = @()
        }
        
        $sourceRelPath = $file.FullName.Substring($rootDir.Length + 1).Replace('\', '/')
        if ($sourceRelPath -notmatch "logs/daily-digest.md" -and $sourceRelPath -notin $linksDict[$targetBasename]) {
            $linksDict[$targetBasename] += $sourceRelPath
        }
    }
}

# Inject backlinks into target files
foreach ($file in $mdFiles) {
    $basename = $file.Name
    if ($linksDict.ContainsKey($basename) -and $linksDict[$basename].Count -gt 0) {
        $content = Get-Content $file.FullName -Raw
        $lines = $content -split "`n"
        
        # Strip existing backlinks section if it exists
        $newLines = @()
        $inBacklinks = $false
        foreach ($line in $lines) {
            if ($line -match "^## Backlinks$") { $inBacklinks = $true }
            if (-not $inBacklinks) { $newLines += $line }
        }
        
        $cleanContent = ($newLines -join "`n").TrimEnd()
        
        # Append new backlinks
        $cleanContent += "`n`n## Backlinks`n"
        foreach ($source in $linksDict[$basename]) {
            $cleanContent += "- [[$source]]`n"
        }
        
        Set-Content -Path $file.FullName -Value $cleanContent -Encoding UTF8
    }
}
Write-Host "SUCCESS: Backlinks injected successfully." -ForegroundColor Green
