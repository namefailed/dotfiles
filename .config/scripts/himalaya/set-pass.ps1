# Store Gmail app password in Windows PasswordVault (used by himalaya's get-pass.ps1)
param(
    [Parameter(Mandatory=$true)]
    [string]$Password
)

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Security.Credentials.PasswordVault, Windows.Security.Credentials, ContentType=WindowsRuntime]

$vault = New-Object Windows.Security.Credentials.PasswordVault
$cred = New-Object Windows.Security.Credentials.PasswordCredential("gmail", "***@***.***", $Password)
$vault.Add($cred)
Write-Output "Gmail credential stored in PasswordVault successfully."
