# Switch workspace N on both monitors simultaneously.
# Used by Kanata LAlt+1..7 to keep mirrored workspaces in sync.

param([int]$Workspace)

$ErrorActionPreference = 'SilentlyContinue'

# Switch the other monitor first so focus stays on the current one.
Start-Process -Wait -WindowStyle Hidden -FilePath komorebic -ArgumentList "focus-monitor-workspace", "1", $Workspace
Start-Process -WindowStyle Hidden -FilePath komorebic -ArgumentList "focus-monitor-workspace", "0", $Workspace
