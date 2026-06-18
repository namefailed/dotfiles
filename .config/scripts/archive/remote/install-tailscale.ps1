# Install Tailscale and authenticate.
# Run this from an elevated prompt.

winget install Tailscale.Tailscale

Write-Host ""
Write-Host "=== NEXT STEPS ==="
Write-Host "1. On your phone, install the Tailscale app from App Store / Play Store"
Write-Host "2. Sign into the same account on both devices (Google/Microsoft/Apple)"
Write-Host "3. On the laptop, run: tailscale up"
Write-Host "   (this opens a browser to authenticate)"
Write-Host "4. Once both devices show in the Tailscale admin console,"
Write-Host "   you can reach this laptop at: ssh $env:USERNAME@$(hostname)"
Write-Host "   or by its Tailscale IP (shown in tailscale status)"
