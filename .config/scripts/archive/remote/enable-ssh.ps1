# Enable OpenSSH Server and configure for key-based auth.
# Run this ONCE from an elevated PowerShell prompt (alias: ssh-enable).

Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd

New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' `
  -Protocol TCP -LocalPort 22 -Action Allow

# Configure sshd to allow public-key auth only (recommended)
if (-not (Test-Path "$env:ProgramData\ssh\sshd_config")) {
  Write-Host "sshd_config not found — install completed but config needs review."
  Write-Host "Run: notepad $env:ProgramData\ssh\sshd_config"
  Write-Host "Ensure these lines are set:"
  Write-Host "  PubkeyAuthentication yes"
  Write-Host "  PasswordAuthentication no"
}

Write-Host "SSH server installed and running."
Write-Host "Your username: $env:USERNAME"
Write-Host "Your hostname: $env:COMPUTERNAME"
