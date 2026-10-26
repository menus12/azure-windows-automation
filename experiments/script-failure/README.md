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

```bash
terraform init
terraform apply -var subscription_id=<SUBSCRIPTION_ID>                       # Windows Server 2022
terraform apply -var subscription_id=<SUBSCRIPTION_ID> -var-file win11.tfvars # Windows 11

for vm in cse-throw cse-soft rc-throw rc-soft; do
  az vm run-command invoke -g rg-<name_prefix> -n vm-$vm \
    --command-id RunPowerShellScript --scripts @scripts/verify.ps1 \
    --query "value[0].message" -o tsv
done

terraform destroy -var subscription_id=<SUBSCRIPTION_ID> [-var-file win11.tfvars]
```

`apply` is expected to fail (exit code 1) on the `*-throw` cases.
