# Research: deploy-time script failures

**Question.** When a configuration script fails during deployment, does `terraform apply` fail,
and can the deployment be retried?

**Short answer.** `apply` fails only when the script **exits non-zero**. A script written with
PowerShell defaults keeps going after errors, exits 0, and `apply` reports success. After a real
failure, the failed extension or run command **stays in Azure but not in Terraform state**, so a
plain second `apply` fails with "already exists - needs to be imported".

The Custom Script Extension and Managed Run Command behave the same way in every case below, on
both Windows Server 2022 and Windows 11.

## Experiment

Terraform configuration and scripts: [experiments/script-failure](../../experiments/script-failure/).

- **Date:** 2026-10-26
- **Image:** Windows Server 2022 Datacenter (`2022-datacenter-smalldisk-g2`, latest)
- **Size / region:** `Standard_B2s`, `westeurope`
- **Tooling:** Terraform 1.17.0, `azurerm` provider 4.x
- **Failure:** the payload downloads a release asset that does not exist. On the VM this surfaced
  as `Invoke-WebRequest : The request was aborted: The connection was closed unexpectedly`
  (not a clean 404), which is a failed download either way.

### First apply

| Case | Script outcome on the VM | Resource in Azure | `terraform apply` |
|------|--------------------------|-------------------|-------------------|
| `cse-throw` | Stopped at the download, exit 1 | Extension `Failed` | **Error** after 2 min 46 s. The message includes the script's stderr |
| `cse-soft` | Download failed, `msiexec` returned 1619, script reached the end, exit 0 | Extension `Provisioning succeeded` | **Success.** The errors are only visible in the extension's substatus (stderr) |
| `rc-throw` | Not run: the API call itself failed (`connection may have been reset`) | Not created | **Error**, unrelated to the script — a transient network failure between the client and Azure, repeated below |
| `rc-soft` | Same as `cse-soft`, exit 0 | Run command `Succeeded` | **Success.** The errors are only visible in `instance_view.error` |

`apply` exits 1 overall, but the succeeded resources from the same run are saved in state.

### Second apply (no changes)

| Case | Result |
|------|--------|
| `cse-throw` | **Error**: `a resource with the ID ".../extensions/run-customdata" already exists - to be managed via Terraform this resource needs to be imported into the State`. The failed extension is in Azure, not in state |
| `rc-throw` | Run command created and failed: `exitCode 1`, `apply` **error** with the script's error stream. The run command stays in Azure as `Failed`, not in state — the same situation as `cse-throw` |

## Windows 11

Repeated with [`win11.tfvars`](../../experiments/script-failure/win11.tfvars) (Windows 11
Enterprise 25H2, Trusted Launch). Same results, and this time `rc-throw` ran cleanly on the first
apply:

| Case | First apply | Second apply |
|------|-------------|--------------|
| `cse-throw` | **Error**, exit code 1 with the script's stderr | **Error**: extension already exists, needs import |
| `cse-soft` | **Success** (`msiexec` 1619 hidden in substatus) | No change |
| `rc-throw` | **Error**, `exitCode 1` with the script's error stream | **Error**: run command already exists, needs import |
| `rc-soft` | **Success** (`msiexec` 1619 hidden in `instance_view.error`) | No change |

## Conclusions

1. **Scripts must fail loudly.** Every payload needs `$ErrorActionPreference = "Stop"`, an exit
   code check after every native command (`msiexec`, installers), and a non-zero exit on failure.
   Otherwise Azure and Terraform report success for a VM that is not configured.
2. **A failed run is not retryable by itself.** Before a retry, the failed extension or run command
   has to be deleted (`az vm extension delete`, `az vm run-command delete`) or imported into state.
   For ephemeral test VMs the simpler recovery is to destroy and recreate the VM.
3. **Failures surface quickly.** The failing extension reported within minutes, not at the
   90-minute timeout.
4. **The error reaches the operator.** In both mechanisms the script's error output ends up in the
   `apply` error message, so a CI log shows why the configuration failed.
