# Register BasicMemoryMCP to run basic-memory.exe directly at user logon.
# The task IS the server process — no Start-Process wrapper needed.
# Run once: .\register-task.ps1

$uvxExe  = "$env:LOCALAPPDATA\Microsoft\WinGet\Links\uvx.exe"
$logFile = "$env:USERPROFILE\.config\basic-memory\server.log"
$action  = New-ScheduledTaskAction `
               -Execute          'pwsh.exe' `
               -Argument         "-NonInteractive -Command `"& '$uvxExe' basic-memory mcp --transport streamable-http --host 127.0.0.1 --port 8765 *> '$logFile'`"" `
               -WorkingDirectory $env:USERPROFILE
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

$settings = New-ScheduledTaskSettingsSet `
                -ExecutionTimeLimit     ([TimeSpan]::Zero) `
                -MultipleInstances      IgnoreNew `
                -RestartCount           3 `
                -RestartInterval        ([TimeSpan]::FromMinutes(1))

Register-ScheduledTask `
    -TaskName    'BasicMemoryMCP' `
    -Action      $action `
    -Trigger     $trigger `
    -Settings    $settings `
    -RunLevel    Limited `
    -Description 'Starts the Basic Memory MCP HTTP server at login.' `
    -Force | Out-Null
Write-Host 'Registered: BasicMemoryMCP scheduled task.' -ForegroundColor Green
