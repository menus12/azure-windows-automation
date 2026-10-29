# Experiment: deploy-time script failures

Checks how `terraform apply` reports a failing deploy-time script, and what a second `apply`
does afterwards. Findings: [docs/research/script-failure.md](../../docs/research/script-failure.md).

## Test matrix

One VM per case: a VM can carry only one Custom Script Extension.

| Case | Mechanism | Payload |
|------|-----------|---------|
| `cse-throw` | Custom Script Extension (payload via custom data) | [fail-throw.ps1](scripts/fail-throw.ps1): `$ErrorActionPreference = "Stop"`, download fails |
| `cse-soft` | Custom Script Extension (payload via custom data) | [fail-soft.ps1](scripts/fail-soft.ps1): PowerShell defaults, download and `msiexec` fail, script runs to the end |
| `rc-throw` | Managed Run Command | `fail-throw.ps1` |
| `rc-soft` | Managed Run Command | `fail-soft.ps1` |

[cse-wrapper.ps1](scripts/cse-wrapper.ps1) runs the payload in a separate `powershell.exe -File`
process, so the payload keeps PowerShell's default error handling, and returns its exit code.

## Run

From PowerShell, with the service principal variables (`ARM_*`) and the proxy set up as described
in [docs/runbooks/vdi-setup.md](../../docs/runbooks/vdi-setup.md). The backend file
`../<environment>.azurerm.tfbackend` is created from
[example.azurerm.tfbackend](../example.azurerm.tfbackend).

```powershell
# Windows Server 2022
terraform init -reconfigure -backend-config="../<environment>.azurerm.tfbackend" `
  -backend-config="key=awa-poc/script-failure/server.tfstate"
terraform apply

# Windows 11 (separate state)
terraform init -reconfigure -backend-config="../<environment>.azurerm.tfbackend" `
  -backend-config="key=awa-poc/script-failure/win11.tfstate"
terraform apply -var-file win11.tfvars
```

`apply` is expected to fail (exit code 1) on the `*-throw` cases. Check the VMs, then destroy with
the same variables as `apply`:

```powershell
$rg = "rg-awa-poc-scriptfail"        # Windows 11: rg-awa-poc-scriptfail-w11
foreach ($vm in "cse-throw", "cse-soft", "rc-throw", "rc-soft") {
  az vm run-command invoke -g $rg -n "vm-$vm" `
    --command-id RunPowerShellScript --scripts "@scripts/verify.ps1" `
    --query "value[0].message" -o tsv
}

terraform destroy                    # Windows 11: terraform destroy -var-file win11.tfvars
```
