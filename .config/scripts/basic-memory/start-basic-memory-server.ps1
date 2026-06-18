# Start Basic Memory MCP server in HTTP mode if not already running.
# Idempotent: exits immediately if port 8765 is already bound.
# Called by startup-orchestrator.vbs at user logon.
#
# NOTE: Do NOT use basic-memory.exe or uvx here — both are uv trampolines that
# fail with "uv trampoline failed to canonicalize script path" in non-interactive
# sessions (login scripts, Task Scheduler).  Use the venv Python directly instead.

$port   = 8765
$python = "$env:APPDATA\uv\tools\basic-memory\Scripts\python.exe"
$code   = 'from basic_memory.cli.main import app; app(standalone_mode=False)'

$running = Get-NetTCPConnection -LocalPort $port -State Listen -EA 0
if ($running) { exit 0 }

if (-not (Test-Path $python)) {
    Write-Warning "basic-memory venv Python not found at $python. Run: uv tool install basic-memory"
    exit 1
}

Start-Process -FilePath $python `
    -ArgumentList '-c', "`"$code`"", 'mcp', '--transport', 'streamable-http', '--host', '127.0.0.1', '--port', '8765' `
    -WindowStyle Hidden
