# Runbook: operator setup on the corporate VDI

How to prepare the corporate VDI to run the experiments with Terraform against the PoC
subscription. Nothing here needs administrator rights.

## Environment

| Item | Where it is set |
|------|-----------------|
| Subscription, tenant, service principal client ID | User environment variables `ARM_*` (step 3) |
| Service principal secret | DPAPI-encrypted file loaded by the PowerShell profile (step 3) |
| Terraform state (resource group, storage account, container) | `experiments/<environment>.azurerm.tfbackend`, git-ignored (step 5) |
| Corporate proxy | User environment variables `HTTPS_PROXY`, `HTTP_PROXY` (step 2) |

The PoC subscription is in `westeurope`. The service principal has Owner on the subscription and
Storage Blob Data Owner on the state container. The VDI reaches Azure only through the corporate
proxy; direct connections to Azure time out.

This repository is public, so environment-specific names and IDs stay in those local settings and
are not written here.

## 1. Azure CLI without administrator rights

The MSI installer needs elevation. The ZIP package (preview) does not:

```powershell
$dest = "$env:LOCALAPPDATA\Programs\AzureCLI"
$zip  = "$env:TEMP\azure-cli.zip"

$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri "https://aka.ms/installazurecliwindowszipx64" -OutFile $zip
Expand-Archive -Path $zip -DestinationPath $dest -Force
Remove-Item $zip

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$dest\bin*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$dest\bin", "User")
}
```

To pin a version, download `https://azcliprod.blob.core.windows.net/zip/azure-cli-<version>-x64.zip`
instead. `az upgrade` does not work for the ZIP package: replace the folder with a newer one.

Azure CLI is only needed for checks (`az vm run-command invoke`); Terraform itself authenticates
from the `ARM_*` variables.

## 2. Proxy

Windows applies the corporate proxy to the browser and to PowerShell's `Invoke-WebRequest`, but
not to Azure CLI or Terraform. Without these variables `az login` times out on
`management.azure.com`:

```powershell
[Environment]::SetEnvironmentVariable("HTTPS_PROXY", "http://<proxy>:<port>", "User")
[Environment]::SetEnvironmentVariable("HTTP_PROXY",  "http://<proxy>:<port>", "User")
[Environment]::SetEnvironmentVariable("NO_PROXY",    "localhost,127.0.0.1", "User")
```

To find the proxy on another machine:
`([System.Net.WebRequest]::GetSystemWebProxy()).GetProxy("https://management.azure.com")`.

## 3. Service principal

Non-secret values as user environment variables:

```powershell
[Environment]::SetEnvironmentVariable("ARM_CLIENT_ID",       "<application (client) id>", "User")
[Environment]::SetEnvironmentVariable("ARM_TENANT_ID",       "<tenant id>",               "User")
[Environment]::SetEnvironmentVariable("ARM_SUBSCRIPTION_ID", "<subscription id>",         "User")
```

The client secret is **not** stored as an environment variable (those are plain text in the
registry). It is encrypted with Windows DPAPI — only the same user on the same machine can decrypt
it — and loaded into each new PowerShell session by the profile:

```powershell
Read-Host "Client secret" -AsSecureString | ConvertFrom-SecureString |
    Set-Content "$HOME\.arm_client_secret"

$profileLines = @'
$armSecretFile = Join-Path $HOME ".arm_client_secret"
if (Test-Path $armSecretFile) {
    $s = Get-Content $armSecretFile | ConvertTo-SecureString
    $env:ARM_CLIENT_SECRET = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
}
'@

# Windows PowerShell 5.1 and PowerShell 7, all hosts including VS Code
foreach ($p in "$HOME\Documents\WindowsPowerShell\profile.ps1", "$HOME\Documents\PowerShell\profile.ps1") {
    New-Item -ItemType Directory -Force -Path (Split-Path $p) | Out-Null
    if (-not (Test-Path $p) -or -not (Select-String -Path $p -Pattern "arm_client_secret" -Quiet)) {
        Add-Content -Path $p -Value $profileLines
    }
}

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

If Documents is redirected, use the path from `$PROFILE.CurrentUserAllHosts` instead.

## 4. Apply the changes

Applications read user environment variables when they start. **Close all VS Code windows** and
open it again, then check in its terminal:

```powershell
Get-Command az | Select-Object Source
$env:HTTPS_PROXY
$env:ARM_SUBSCRIPTION_ID
[bool]$env:ARM_CLIENT_SECRET   # True; never print the value
az login --service-principal -u $env:ARM_CLIENT_ID -p $env:ARM_CLIENT_SECRET --tenant $env:ARM_TENANT_ID --output none
az account show --query name -o tsv
```

Variables set in a shell with `$env:` and local PowerShell variables (`$azBin`, …) exist only in
that shell.

## 5. Terraform backend

Create `experiments/<environment>.azurerm.tfbackend` from
[example.azurerm.tfbackend](../../experiments/example.azurerm.tfbackend) (`*.tfbackend` files are
git-ignored). Leave the `key` out of the file and pass it on `init`, so every experiment and
variant has its own state:

```powershell
terraform init -reconfigure -backend-config="../<environment>.azurerm.tfbackend" `
  -backend-config="key=awa-poc/<experiment>/<variant>.tfstate"
```

`use_azuread_auth = true` makes the backend use the service principal's Storage Blob Data Owner
role instead of storage account keys.
