# setup-remote-access.ps1 — One-time admin setup for SSH + Tailscale
# Run this from an ELEVATED PowerShell prompt (right-click → Run as Administrator)

Write-Host "=== Installing OpenSSH Server ===" -ForegroundColor Cyan
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd
New-NetFirewallRule -Name sshd -DisplayName "OpenSSH Server" `
  -Protocol TCP -LocalPort 22 -Action Allow -ErrorAction SilentlyContinue

Write-Host "=== Configuring SSH key auth ===" -ForegroundColor Cyan
# Ensure administrators_authorized_keys exists
$sshDir = "$env:ProgramData\ssh"
if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force }
$authKeysAdmin = "$sshDir\administrators_authorized_keys"
if (-not (Test-Path $authKeysAdmin)) {
  New-Item -ItemType File -Path $authKeysAdmin -Force | Out-Null
}
# Copy user's authorized_keys to the admin location if it exists
$userAuthKeys = "$env:USERPROFILE\.ssh\authorized_keys"
if (Test-Path $userAuthKeys) {
  $content = Get-Content $userAuthKeys
  Set-Content -Path $authKeysAdmin -Value $content
  # Fix ACL: sshd needs this file to not have inherited permissions
  icacls $authKeysAdmin /inheritance:r /grant "SYSTEM:(R)" /grant "BUILTIN\Administrators:(R)" 2>&1 | Out-Null
}

Write-Host ""
Write-Host "=== Installing Tailscale ===" -ForegroundColor Cyan
winget install Tailscale.Tailscale

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "  1. Run: tailscale up  (authenticate in browser)"
Write-Host "  2. Install Tailscale on your phone (same account)"
Write-Host "  3. Generate SSH key on your phone, add pubkey to:"
Write-Host "     $env:ProgramData\ssh\administrators_authorized_keys"
Write-Host "  4. Test connection: ssh $env:USERNAME@<tailscale-ip>"
Write-Host ""
Write-Host "=== ttyd firewall (if using web terminal) ===" -ForegroundColor Cyan
Write-Host "If you also installed ttyd, create a proper firewall rule:"
Write-Host "   .\enable-ttyd-firewall.ps1"
Write-Host "IMPORTANT: Use -Profile Any (not Public-only) — Tailscale uses Private profile."
