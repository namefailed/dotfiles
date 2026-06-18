# Generate SSH key and configure for remote access.
# Run this once from a normal (non-admin) prompt (alias: ssh-keys).

$keyPath = "$env:USERPROFILE\.ssh\id_ed25519"
if (-not (Test-Path $keyPath)) {
  ssh-keygen -t ed25519 -f $keyPath -N '""'
  Write-Host "SSH key generated at $keyPath"
} else {
  Write-Host "SSH key already exists at $keyPath"
}

# Authorize yourself
$pubKey = Get-Content "$keyPath.pub"
$authorizedKeys = "$env:USERPROFILE\.ssh\authorized_keys"
Set-Content -Path $authorizedKeys -Value $pubKey
Write-Host "Public key authorized for local login."

Write-Host ""
Write-Host "=== TO ADD YOUR PHONE ==="
Write-Host "1. On your phone (Termius/JuiceSSH), generate an SSH key pair"
Write-Host "2. Copy the public key and paste it into this file:"
Write-Host "   $env:ProgramData\ssh\administrators_authorized_keys"
Write-Host "   (must be run as admin, no trailing newline issues)"
Write-Host ""
Write-Host "=== TYPICAL LOGIN ==="
Write-Host "ssh $env:USERNAME@$env:COMPUTERNAME"
Write-Host "(or use the Tailscale IP after installing Tailscale)"
