param(
    [Parameter(Mandatory)][string]$Action,
    [Parameter(Mandatory)][string]$Url,
    [string]$Title = ""
)

$actionMap = @{ l = 'journal-log'; t = 'journal-task'; a = 'journal-article'; o = 'org-link' }
$protocolPath = $actionMap[$Action]
if (-not $protocolPath) { Write-Error "Unknown action: $Action"; exit 1 }

$encodedUrl   = [System.Uri]::EscapeDataString($Url)
$encodedTitle = [System.Uri]::EscapeDataString($Title)
$orgUrl = "org-protocol://$protocolPath`?url=$encodedUrl&title=$encodedTitle"
& "emacsclientw.exe" -a "emacs" "$orgUrl"
