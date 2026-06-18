$rootDir = Join-Path $env:USERPROFILE 'basic-memory'
$graphPath = Join-Path $rootDir "logs\knowledge-graph.md"
$mdFiles = Get-ChildItem -Path $rootDir -Filter *.md -Recurse | Where-Object { $_.FullName -notmatch "\\.git\\" -and $_.Name -ne "knowledge-graph.md" }

$dateStr = Get-Date -Format "yyyy-MM-dd"
$content = @"
---
title: Knowledge Graph
type: log
tags: [graph, map]
date: $dateStr
---

# Knowledge Graph

> Auto-generated Mermaid diagram of the Basic Memory structure.

"@

$content += "`n" + '```mermaid' + "`n%%{init: {'flowchart': {'nodeSpacing': 80, 'rankSpacing': 150}}}%%`nflowchart LR;"

foreach ($file in $mdFiles) {
    if ($file.Name -match "daily-digest|ai-log") { continue }
    
    $sourceName = $file.BaseName
    $sourceNode = $sourceName -replace '[^a-zA-Z0-9]', ''
    $rawContent = Get-Content $file.FullName -Raw
    $links = [regex]::Matches($rawContent, '\[\[(.*?)\]\]')
    
    foreach ($match in $links) {
        $inner = $match.Groups[1].Value
        # Handle org-mode [[target][display]] links
        if ($inner -match '^(.*?)\]\[') {
            $target = $Matches[1]
        } else {
            $target = $inner.Split('|')[0].Split('#')[0]
        }
        
        $targetName = $target.Split('/')[-1] -replace '\.md$', ''
        $targetNode = $targetName -replace '[^a-zA-Z0-9]', ''
        if ($targetNode -ne "") {
            $content += "`n    $sourceNode[`"$sourceName`"] --> $targetNode[`"$targetName`"];"
        }
    }
}

$content += "`n" + '```'
Set-Content -Path $graphPath -Value $content -Encoding UTF8
Write-Host "SUCCESS: Knowledge graph generated at $graphPath" -ForegroundColor Green
