# Read Gmail app password from Windows Credential Manager
$cred = cmdkey /list:gmail 2>$null | Select-String "gmail"
if (-not $cred) {
    Write-Error "No credential found. Run set-pass.ps1 to store the Gmail app password first."
    exit 1
}
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$vault = [Windows.Security.Credentials.PasswordVault, Windows.Security.Credentials, ContentType=WindowsRuntime]
$credential = (New-Object Windows.Security.Credentials.PasswordVault).Retrieve("gmail", "***@***.***")
$credential.RetrievePassword()
Write-Output $credential.Password
