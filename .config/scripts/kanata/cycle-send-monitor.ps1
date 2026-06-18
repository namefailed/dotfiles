# Send focused window to the other monitor and follow it.
# Used by Kanata LAlt+Space for up/down toggle between monitors.

$ErrorActionPreference = 'SilentlyContinue'

Start-Process -Wait -WindowStyle Hidden -FilePath komorebic -ArgumentList "cycle-send-to-monitor", "next"
Start-Process -WindowStyle Hidden -FilePath komorebic -ArgumentList "cycle-monitor", "next"
